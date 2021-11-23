/**************************************************
Description: The base class for all BSP related functionality
History:
--------------------------------------------------
2019-04-13  nathan.franklin@auspost.com.au  Created
**************************************************/
public with sharing virtual class bspBase {

	public static final String CSSO_SAML_CONFIG = 'BSP_CSSO';

	// store the logged in user in a static context to minimise number of queries run in a single transaction
	private static User loggedInUser = null;


	public final CCUSettings__c configSetting {
		get {
			return CCUSettings__c.getInstance();
		}
	}

	/**
	 * Return the billing account scope of a user based on which side of the business the customer deals with (maybe both)
	 * Either ST/AP or ALL
	 */
	public transient String userBillingAccountScope {
		get {
			if(userBillingAccountScope == null) {
				Boolean hasAPBillingAccounts = false;
				Boolean hasSTBillingAccounts = false;

				for(Billing_Account__c billingAccount : accessibleBillingAccounts.values()) {
					if(isBillingAccountST(billingAccount)) {
						hasSTBillingAccounts = true;
					} else if(isBillingAccountAP(billingAccount)) {
						hasAPBillingAccounts = true;
					}

					// check if it's necessary to go any further or not
					// if we already have set both to true it isn't necessary to proceed anymore
					if(hasSTBillingAccounts && hasAPBillingAccounts) {
						break;
					}
				}

				if(hasAPBillingAccounts && hasSTBillingAccounts) {
					userBillingAccountScope = BspConstants.AUTH_SCOPE_ALL;
				} else if(hasAPBillingAccounts) {
					userBillingAccountScope = BspConstants.AUTH_SCOPE_AP;
				} else if(hasSTBillingAccounts) {
					userBillingAccountScope = BspConstants.AUTH_SCOPE_ST;
				}
			}
			return userBillingAccountScope;
		}
		private set;
	}

	/**
	 * Based on the access rules defined, we can determine whether this user has StarTrack billing accounts or not
	 */
	public transient Boolean hasSTBillingAccounts {
		get {
			return (userBillingAccountScope == BspConstants.AUTH_SCOPE_ALL || userBillingAccountScope == BspConstants.AUTH_SCOPE_ST);
		}
	}

	/**
	 * Based on the access rules defined, we can determine whether this user has AP billing accounts or not
	 */
	public transient Boolean hasAPBillingAccounts {
		get {
			return (userBillingAccountScope == BspConstants.AUTH_SCOPE_ALL || userBillingAccountScope == BspConstants.AUTH_SCOPE_AP);
		}
	}

	/**
	 * Grabs a list of all the available roles and rules. To ensure this does not take up view state we use session cache and persist it server side for faster access
	 * Currently BSP has 3 roles defined: Super Admin (org), Admin (billing account), User (billing account)
	 * In most circumstances, there should be only a single role, however, this will support a multiple role architecture in the event that multiple role capability is introduced
	 *
	 * Special Rules:
	 * 1. We only ever return billing accounts that belong the contacts current Organisation
	 * 2. Any 'Super' roles (configured at the org level) will only ever return the contacts linked to the current users Organisation irrespective of the configuration in Linked Entities (even if linked entities are defined the cross organisation, we supress them from being loaded to prevent any possible security implications)
	 * 3. The primary billing account will be added as a User role by default, it also can be overriden in BAM by explicity setting it to a higher level role.
	 * 4. Since we are supporting legacy and the ability to onboard to BSP outside of BAM, we do not check for Contact status or whether the Org has the BSP asset in order to surface Rules, this will be handled as the user logs into BSP via the CSSO Login Handler (BAMJitLoginHandler)
	 *      This is because these limitation should only be enforced in the Merchant Portal CSSO login context
	 *
	 * These rules are introduced to provide governance and to prevent any data accidently leaking
	 */
	@TestVisible
	public transient List<AccessRule> accessRules {
		get {
			if(accessRules == null) {
				accessRules = (List<AccessRule>)CacheManager.get('BSP_ACCESS_ROLES');
				if(accessRules == null) {
					Map<Id, AccessRule> accessRuleMap = new Map<Id, AccessRule>();

					// grab a list of all the roles and linked entities available for BSP for the current contact
					// Although this method supports multiple roles, the current limitation in the UI is to only support assigning a single role. BAM UI and BAM internal UI both support only a single role
					// NOTE: It's possible for this to return no records and the user can still have access to BSP (based on their primary billing account)
					List<BAMContactRole__c> contactRoles = [Select ContactApplication__r.Id, ApplicationRole__r.Role__c, ApplicationRole__r.ShowBillingAccount__c, ApplicationRole__r.ShowGroup__c, ApplicationRole__r.ShowOrganisation__c,
																	(Select BillingAccount__r.Name, BillingAccount__r.Id, BillingAccount__r.LEGACY_ID__c, BillingAccount__r.Organisation__c, BillingAccount__r.MLID__c, BillingAccount__r.Source_System__c, Organisation__r.LEGACY_ID__c, Organisation__r.Name, Organisation__r.Id, Group__c
																		From LinkedEntities__r
																		Where Status__c = 'Active')

																From BAMContactRole__c
																Where ContactApplication__r.Application__r.AppKey__c = 'BSP'
																And ContactApplication__r.Contact__c = :loginContactId
																And ContactApplication__r.Status__c = 'Active'
																And Status__c = 'Active'];

					String currentPrimaryBillingAccountRole = 'User';
					
					// by default add the primary billing account into the list of access rules with the role of User... this will later get overridden if needed based on BAMContactApplication, BAMContactRole configs
					if(primaryBillingAccount != null) {
						accessRuleMap.put(primaryBillingAccount.Id, new AccessRule(currentPrimaryBillingAccountRole, primaryBillingAccount));
					}

					System.debug('>> BSP Contact Roles: ' + contactRoles);
					for(BAMContactRole__c rr : contactRoles) {
						System.debug('>> BSP Contact Role Linked Entities: ' + rr.LinkedEntities__r);

						// make sure the primary billing account is added to the access rules with the current Role that has been set in BAMContactRole__c
						// if, for whatever reason??, there are multiple roles, then the highest role will win out (since we call the 'getMaxRole')
						if(primaryBillingAccount != null) {
							currentPrimaryBillingAccountRole = getMaxRole(currentPrimaryBillingAccountRole, rr.ApplicationRole__r.Role__c);
							accessRuleMap.put(primaryBillingAccount.Id, new AccessRule(currentPrimaryBillingAccountRole, primaryBillingAccount));
						}

					}

					// we need to expand groups out into a list of billing accounts
					// it's possible that a group may be associated to more than 1 role (although it shouldn't happen since BAM UI is a single role architecture)
					// we need to ensure that the billing accounts linked in a group will always be linked to the most open role
					// example, group1 exists in a role of User and a role of Admin.... all the billing accounts should have a role of Admin and not User
					Map<Id, String> groupRoles = new Map<Id, String>();

					// loop through each of the roles to grab the linked entities
					for(BAMContactRole__c contactRole : contactRoles) {
						if(contactRole.ApplicationRole__r.ShowOrganisation__c) {
							// for organisation level roles, whenever they are set in BSP, it ALWAYS implies a role is connected the logged in contacts organisation
							// this is a fail safe to ensure that a user will only gain access to their current org.
							// if multiple roles happen to exist then only the highest level role will be retained
							// NOTE: these roles might include Super Admin and Super User
							if (accessRuleMap.get(loginAccountId) != null) {
								// this entity already exists so we need to ensure that it is linked to the most open role
								accessRuleMap.get(loginAccountId).roleName = getMaxRole(accessRuleMap.get(loginAccountId).roleName, contactRole.ApplicationRole__r.Role__c);
							} else {
								accessRuleMap.put(loginAccountId, new AccessRule(contactRole.ApplicationRole__r.Role__c, loginAccount));
							}
						} else {
							if(contactRole.LinkedEntities__r != null) {
								// loop through each of the linked entities for each role and only include it in the results if it matches allowed configuration in the Application Roles table
								for (BAMLinkedEntity__c linkedEntity : contactRole.LinkedEntities__r) {
									if (contactRole.ApplicationRole__r.ShowGroup__c && linkedEntity.Group__c != null) {
										// check if the group has already been associated to a role
										// if it is, we compare the 2 roles and set the role as the higher role
										// we use this when we retrieve the billing accounts so we can ensure the billing account is assigned to the correct role
										if (groupRoles.get(linkedEntity.Group__c) != null) {
											// this group already exists so we need to ensure that it is linked to the most open role
											groupRoles.put(linkedEntity.Group__c, getMaxRole(groupRoles.get(linkedEntity.Group__c), contactRole.ApplicationRole__r.Role__c));
										} else {
											// the group has not been previously assigned so we add to our group map
											groupRoles.put(linkedEntity.Group__c, contactRole.ApplicationRole__r.Role__c);
										}
									} else if (contactRole.ApplicationRole__r.ShowBillingAccount__c && linkedEntity.BillingAccount__r != null) {

										// IMPORTANT!!
										// Add a failsafe to ensure we only return billing accounts that are related to the current logged in users Organisation
										// This protects us in the event when dodgy configurations occur or when a contact is reparented to a new org... either of these scenarios shouldn't happen but we add this code just in case
										if(linkedEntity.BillingAccount__r.Organisation__c != loginAccountId)
											continue;

										if (accessRuleMap.get(linkedEntity.BillingAccount__r.Id) != null) {
											// this entity already exists so we need to ensure that it is linked to the most open role
											accessRuleMap.get(linkedEntity.BillingAccount__r.Id).roleName = getMaxRole(accessRuleMap.get(linkedEntity.BillingAccount__r.Id).roleName, contactRole.ApplicationRole__r.Role__c);
										} else {
											// add the entity to the access rules since it doesn't already exist
											accessRuleMap.put(linkedEntity.BillingAccount__r.Id, new AccessRule(contactRole.ApplicationRole__r.Role__c, linkedEntity.BillingAccount__r));
										}
									}
								}
							}
						}
					}

					// retrieve the groups and the connected billing accounts
					// when we are adding the access rules, we need to ensure the billing account is added to most open role based on it's config
					// issues may arise where billing accounts exist in multiple groups with different access roles
					// checking billing accounts here ensures any billing accounts linked in multiple groups will still inherit the most open role
					if(!groupRoles.isEmpty()) {
						Map<Id, BAMGroup__c> groups = BAMUserUtility.getGroups(groupRoles.keySet(), loginAccountId);
						for (BAMGroup__c grp : groups.values()) {
							if (grp.GroupBillingAccounts__r != null) {
								for (BAMGroupBillingAccount__c groupBillingAccount : grp.GroupBillingAccounts__r) {
									// IMPORTANT!!
									// Add a failsafe to ensure we only return billing accounts that are related to the current logged in users Organisation
									// This protects us in the event when dodgy configurations occur or when a contact is reparented to a new org... either of these scenarios shouldn't happen but we add this code just in case
									if (groupBillingAccount.BillingAccount__r.Organisation__c != loginAccountId)
										continue;

									if (accessRuleMap.get(groupBillingAccount.BillingAccount__r.Id) != null) {
										// this entity already exists so we need to ensure that it is linked to the most open role
										accessRuleMap.get(groupBillingAccount.BillingAccount__r.Id).roleName = getMaxRole(accessRuleMap.get(groupBillingAccount.BillingAccount__r.Id).roleName, groupRoles.get(grp.Id));
									} else {
										// add the billing account to the access rules since it doesn't already exist
										accessRuleMap.put(groupBillingAccount.BillingAccount__r.Id, new AccessRule(groupRoles.get(grp.Id), groupBillingAccount.BillingAccount__r));
									}
								}
							}
						}
					}

					// the end result here is that we now have a list of billing accounts and organisations that the current contact has access to
					// the above also ensures that for each billing account the most open was applied
					accessRules = accessRuleMap.values();

					System.debug('>> accessRules: ' + accessRules);

					CacheManager.put('BSP_ACCESS_ROLES', accessRules);
				}
			}

			return accessRules;
		}
		private set;
	}

	/**
     * This will return a list of all the billing accounts that the logged in user has access to
     * This is irrespective of the role linked to each of these billing accounts
     * Scenarios:
     *  Super Admin or Super User... where an Org is specified (NOTE: We force here that a user may only have access to their own org which is currently enforced in accessRules property)
     *  Admin or User... where access is determined by individual billing accounts
     *
     */
	public transient Map<Id, Billing_Account__c> accessibleBillingAccounts {
		get {
			if(accessibleBillingAccounts == null) {
				accessibleBillingAccounts = (Map<Id, Billing_Account__c>)CacheManager.get('BSP_ACCESSIBLE_BILLING');
				if(accessibleBillingAccounts == null) {

					accessibleBillingAccounts = new Map<Id, Billing_Account__c>();

					Set<Id> accountIds = new Set<Id>();
					Set<Id> billingAccounts = new Set<Id>();

					// loop through the access rules to retrieve a list of billing account
					for (AccessRule rule : accessRules) {
						if ('Account'.equalsIgnoreCase(rule.entityType) && rule.entity.Id == loginAccountId) {
							// currently, the only account that should be surfaced here is the current logged in account.
							// this is to protect against any leaking of data where a contact has been reparented or the rules have been tempered with in any way
							accountIds.add(rule.entity.Id);
						} else if ('Billing_Account__c'.equalsIgnoreCase(rule.entityType)) {
							// only the billing accounts that belong to the users current org are surfaced
							// this rule is enforced in the accessRules property
							billingAccounts.add(rule.entity.Id);
						}
					}

					if (!accountIds.isEmpty()) {
						accessibleBillingAccounts.putAll(new Map<Id, Billing_Account__c>([
								Select Id, Name, LEGACY_ID__c, Source_System__c, MLID__c
								From Billing_Account__c
								Where Organisation__c in :accountIds
						]));
					}

					// if we retrieve billing accounts for an entire org, we may have all the billing accounts we need.
					// To ensure we aren't retrieving the same billing accounts again, we simply remove the billing accounts we have already retrieved
					billingAccounts.removeAll(accessibleBillingAccounts.keySet());

					if (!billingAccounts.isEmpty()) {
						accessibleBillingAccounts.putAll(new Map<Id, Billing_Account__c>([
								Select Id, Name, LEGACY_ID__c, Source_System__c, MLID__c
								From Billing_Account__c
								Where Id In :billingAccounts
						]));
					}

					CacheManager.put('BSP_ACCESSIBLE_BILLING', accessibleBillingAccounts);
				}

			}

			return accessibleBillingAccounts;
		}
		private set;
	}

	/**
	 * Grabs a list of billing accounts numbers accessible to the current logged in user
	 * These are based of the access rules defined in accessRule property
	 */
	public transient Map<String, Id> accessibleBillingAccNumbers {
		get {
			if(accessibleBillingAccNumbers == null) {
				accessibleBillingAccNumbers = new Map<String, Id>();
				for(Billing_Account__c billingAccount : accessibleBillingAccounts.values()) {
					accessibleBillingAccNumbers.put(billingAccount.LEGACY_ID__c, billingAccount.Id);
				}
			}

			return accessibleBillingAccNumbers;
		}
		private set;
	}

	/**
	 * Determines whether the logged in user is allowed full access to Searching All Consignments. This is a setting that has been exposed via BAM and is controlled by Customer Admin
	 * NOTE: this is not transient meaning this will be set for the life cycle of the page
	 *
	 * NOTE: if a user has access to AP & ST billing accounts, then canSearchAllConsignments means ALL consignments are searchable
	 * NOTE: if a user only has access to AP billing accounts, then canSearchAllConsignments means ALL SAP-EM consignments are searchable
	 * NOTE: if a user only has access to ST billing accounts, then canSearchAllConsignments means ALL .NET consignments are searchable
	 */
	public Boolean canSearchAllConsignments {
		get {
			if(canSearchAllConsignments == null) {
				BAMContactApplication__c config = BAMUserUtility.getContactApplicationConfig(loginContactId, 'BSP');
				if(config == null) {
					canSearchAllConsignments = false;
				} else {
					canSearchAllConsignments = config.BSPCanViewAllConsignments__c;
				}
			}

			return canSearchAllConsignments;
		}
		private set;
	}

	@TestVisible
	public User loginUser {
		get {
			if(loginUser == null) {
				// Get Contact based on login User's ContactId (only applicable for Community User)
				// grab this from a static context since bspBase is used multiple times in a single transaction
				loginUser = getLoggedInUser();
			}

			return loginUser;
		}
		private set;
	}

	/**
	 * Used for test class to be able to override current network id for test verification of MPB vs. BSP capability
	 */
	@TestVisible
	public Id currentNetworkId {
		get {
			if(currentNetworkId == null) {
				currentNetworkId = Network.getNetworkId();
			}

			return currentNetworkId;
		}
		private set;
	}

	public Boolean isMpbHspFlag {
		get {
			if(isMpbHspFlag == null) {
				if(currentNetworkId == null) {
					// if we return null here we receive Null Pointer Exceptions
					// overriding and return false here prevents a null pointer exception
					isMpbHspFlag = null;
					return false;
				} else {
					isMpbHspFlag = ([Select UrlPathPrefix From Network Where Id = :currentNetworkId].UrlPathPrefix == 'MpbHelpAndSupport');
				}
			}

			return isMpbHspFlag;
		}
		private set;
	}

	/**
	 * Grab the contact Id associated to the user that is logged in
	 */
	public transient Id loginContactId {
		get {
			return loginUser.ContactId;
		}
	}

	/**
	 * Grab the user Id associated to the user that is logged in
	 */
	public transient Id loginUserId {
		get {
			return loginUser.Id;
		}
	}

	/**
	 * Grab the contact associated to the user that is logged in
	 */
	public transient Contact loginContact {
		get {
			return loginUser.Contact;
		}
	}

	/**
	 * Grab the id of the primary billing account linked to the users contact record
	 */
	public transient Id loginBillingAccountId {
		get {
			return (loginUser.Contact != null ? loginUser.Contact.BillingAccount__c : null);
		}
	}

	/**
	 * Grab the id of the primary billing account linked to the users contact record
	 */
	public transient Account loginAccount {
		get {
			return (loginUser.Contact != null && loginUser.Contact.Account != null ? loginUser.Contact.Account : null);
		}
	}

	/**
	 * Grab the organisation Id associated to the user that is logged in
	 */
	public transient Id loginAccountId {
		get {
			return (loginUser.Contact != null ? loginUser.Contact.AccountId : null);
		}
	}

	/**
	 * Return whether or not the customer is an 'enterprise' customer or not ???
	 */
	public transient Boolean isEnterprise {
		get {
			return (loginUser.Contact != null && loginUser.Contact.Account != null ? 'enterprise'.equalsIgnoreCase(loginUser.Contact.Account.ServiceSLA__c) : false);
		}
	}

	public transient Billing_Account__c primaryBillingAccount {
		get {
			return (loginUser.Contact != null ? loginUser.Contact.BillingAccount__r : null);
		}
	}

	public transient String primaryBillingAccountNumber {
		get {
			return (loginUser.Contact != null && loginUser.Contact.BillingAccount__r != null ? loginUser.Contact.BillingAccount__r.LEGACY_ID__c : null);
		}
	}

	public transient String primaryBillingAccountSource {
		get {
			return (loginUser.Contact != null && loginUser.Contact.BillingAccount__r != null ? loginUser.Contact.BillingAccount__r.Source_System__c : null);
		}
	}

	/**
	 * BSP has a concept of a user based in either the AP or ST camps.
	 * This is determined by what primary billing account is assigned to your contact record and will determine what level of functionality exposed to you and have new cases are routed
	 */
	public transient Boolean isAPUser {
		get {
			return (primaryBillingAccount != null ? BspConstants.SOURCE_SYSTEM_SAP_ERP.equalsIgnoreCase(primaryBillingAccount.Source_System__c) : false);
		}
	}

	/**
	 * BSP has a concept of a user based in either the AP or ST camps.
	 * This is determined by what primary billing account is assigned to your contact record and will determine what level of functionality exposed to you and have new cases are routed
	 */
	public transient Boolean isSTUser {
		get {
			return (primaryBillingAccount != null ? BspConstants.SOURCE_SYSTEM_TEAM.equalsIgnoreCase(primaryBillingAccount.Source_System__c) || BspConstants.SOURCE_SYSTEM_PEOPLESOFT.equalsIgnoreCase(primaryBillingAccount.Source_System__c) : false);
		}
	}


	/**
	 * Returns a list of the ST billing accounts available
	 */
	public transient List<AccessRule> stBillingAccountsAccessRules {
		get {
			if(stBillingAccountsAccessRules == null) {
				stBillingAccountsAccessRules = new List<AccessRule>();
				for(AccessRule accessRule : accessRules) {
					if('Billing_Account__c'.equalsIgnoreCase(accessRule.entityType) && accessRule.entity != null) {
						if(BspConstants.SOURCE_SYSTEM_TEAM.equalsIgnoreCase(String.valueOf(accessRule.entity.get('Source_System__c'))) || BspConstants.SOURCE_SYSTEM_PEOPLESOFT.equalsIgnoreCase(String.valueOf(accessRule.entity.get('Source_System__c')))) {
							stBillingAccountsAccessRules.add(accessRule);
						}
					}
				}
			}

			return stBillingAccountsAccessRules;
		}
		private set;
	}

	/**
	 * Returns a list of the ST billing accounts available
	 */
	public transient List<AccessRule> apBillingAccountsAccessRules {
		get {
			if(apBillingAccountsAccessRules == null) {
				apBillingAccountsAccessRules = new List<AccessRule>();
				for(AccessRule accessRule : accessRules) {
					if('Billing_Account__c'.equalsIgnoreCase(accessRule.entityType) && accessRule.entity != null) {
						if(BspConstants.SOURCE_SYSTEM_SAP_ERP.equalsIgnoreCase(String.valueOf(accessRule.entity.get('Source_System__c')))) {
							apBillingAccountsAccessRules.add(accessRule);
						}
					}
				}
			}

			return apBillingAccountsAccessRules;
		}
		private set;
	}

	/**
	 * Grab a list of the rules in a role map so we can can easily determine what entities are linked to which role
	 */
	public transient Map<String, Set<Id>> roleBasedAccessRules {
		get {
			if(roleBasedAccessRules == null) {
				Map<String, Set<Id>> output = new Map<String, Set<Id>>();
				for(AccessRule rule : accessRules) {
					if(output.get(rule.roleName) == null)
						output.put(rule.roleName, new Set<Id>());

					output.get(rule.roleName).add(rule.entity.Id);
				}

				roleBasedAccessRules = output;
			}

			return roleBasedAccessRules;
		}
		private set;
	}

	/**
	 * TODO: ?
	 */
	public transient String excludeSubject {
		get {
			return configSetting.AdminCaseSubject__c;
		}
	}

	/**
	 * TODO: ?
	 */
	public transient String onlyRecordTypes {
		get {
			return configSetting.IncludedRecordTypes__c;
		}
	}

	/**
	 * TODO: ?
	 */
	public transient String excludecaseTypes {
		get {
			return configSetting.Exclude_case_types__c;
		}
	}

	/**
	 * TODO: ?
	 */
	public transient List<String> excludecaseTypeslist {
		get {
			if(excludecaseTypeslist == null) {
				excludecaseTypeslist = excludecaseTypes.split(',');
			}
			return excludecaseTypeslist;
		}
		private set;
	}

	/**
	 * Exclude the cases based on the case purpose provided in 'BSPSettings'
	 */
	public transient String excludecasePurpose {
		get {
			return configSetting.Exclude_case_purpose__c;
		}
	}

	/**
	 * Exclude the cases based on the case purpose provided in 'BSPSettings'
	 */
	public transient List<String> excludecasePurposelist {
		get {
			if(excludecasePurposelist == null) {
				excludecasePurposelist = excludecasePurpose.split(',');
			}
			return excludecasePurposelist;
		}
		private set;
	}

	/**
	 * TODO: ?
	 */
	public transient String successMessage {
		get {
			return configSetting.BSPEnquiryCreationSuccessMsg__c;
		}
	}

	/**
	 * TODO: ?
	 */
	public transient Decimal fileSizeLimit {
		get {
			return (configSetting.AttachmentSizeLimit__c != null ? configSetting.AttachmentSizeLimit__c : 5);
		}
	}

	/**
	 * TODO: ?
	 */
	public transient Integer fileSizeLimitInteger {
		get {
			return fileSizeLimit.intValue();
		}
	}

	// only display EmailMessage if it has keyword matched in its FromAddress or ToAddress
	public transient String emailKeyword {
		get {
			return (configSetting.EmailMsgKeyword__c != null ? configSetting.EmailMsgKeyword__c : '%auspost%');
		}
	}

	/**
	 * TODO: ?
	 */
	public transient String doNotShowFile {
		get {
			return configSetting.DoNotShowFileNames__c;
		}
	}

	/**
	 * Determines whether an searched article is accessible based on the access rules defined for the current user.
	 */
	public Boolean isArticleAccessible(Article__c article) {
		return isArticleAccessible(article, true);
	}

	/**
	 * Determines whether an searched article is accessible based on the access rules defined for the current user.
	 * NOTE: canSearchAllConsignments gives the user access to all consignments
	 */
	public Boolean isArticleAccessible(Article__c article, Boolean includeUniversalSearchFlag) {
		if(includeUniversalSearchFlag) {
			return (article != null && ((article.Billing_Account__c != null && accessibleBillingAccounts.containsKey(article.Billing_Account__c)) ||
											(article.Billing_Account__r != null && article.Billing_Account__r.Organisation__c == loginAccountId && canSearchAllConsignments)));

		} else {
			return (article != null && (article.Billing_Account__c != null && accessibleBillingAccounts.containsKey(article.Billing_Account__c)));
		}
	}

	/**
	 * Determines whether or not the case can be accessed based on the current access rules
	 * NOTE: There are top level sharing sets in place that prevent the logged in user from viewing records outside their account, however, this provides the next level down
	 */
	public Boolean isCaseAccessible(Case c) {
		for(AccessRule rule : accessRules) {
			if('Super Admin'.equalsIgnoreCase(rule.roleName) && 'Account'.equalsIgnoreCase(rule.entityType) &&
					(rule.entity.Id == c.AccountId ||
							c.Related_Billing_Account__r != null && rule.entity.Id == c.Related_Billing_Account__r.Organisation__c)) {

				// if the user is a super user then we validate to ensure the organisation matches
				// this is probably not necessary because of existing sharing sets, however, it's in here for completeness and clarity
				return true;
			} else if('Admin'.equalsIgnoreCase(rule.roleName) && 'Billing_Account__c'.equalsIgnoreCase(rule.entityType)) {
				// check the related billing account on the case
				// NOTE: Updated 2019-07-29 - The billing account of the user raising the case will now be factored in as to whether a case should be shown to a current user.
				//                              This requirement has been identified as an AP only requirement so it has only been implemented when searching AP billing accounts
				//                              Example: if primary billing account of user creating case is 1234 and the article linked to that case is linked to billing account 5678
				//                                          the case will be accessible to admins of 1234 and also 5678
				if((rule.entity.Id == c.Related_Billing_Account__c) || (c.Contact != null && c.Contact.BillingAccount__c != null && rule.entity.Id == c.Contact.BillingAccount__c)) {
					return true;
				}
			}
		}

		// since there were no other rules matched above,
		//      give access to the case if it was created by the logged in user or if the contact matches
		if(c.ContactId == loginContactId || c.CreatedById == loginUserId) {
			return true;
		}

		return false;
	}

	/**
     * Grabs an error message for BSP stored in custom settings.
     */
	public static String getErrorMessage(String errorKey) {
		if(BSPErrorMessages__c.getValues(errorKey) == null) {
			return '';
		} else {
			return BSPErrorMessages__c.getValues(errorKey).Message__c;
		}
	}

	/**
     * Determines whether the user logged in via CSSO or not
     * Test classes are required to set this value manually
     */
	@TestVisible
	public Boolean isCSSOLogin {
		get {
			if(isCSSOLogin == null) {
				isCSSOLogin = false;

				if(!Test.isRunningTest()) {
					Map<String, String> attribs = Auth.SessionManagement.getCurrentSession();
					if (attribs.get('LoginHistoryId') != null) {
						List<LoginHistory> history = [Select AuthenticationServiceId From LoginHistory Where Id = :attribs.get('LoginHistoryId')];
						if (!history.isEmpty() && history[0].AuthenticationServiceId != null) {
							List<SamlSsoConfig> configs = [Select DeveloperName From SamlSsoConfig Where Id = :history[0].AuthenticationServiceId];
							if (!configs.isEmpty() && configs[0].DeveloperName == CSSO_SAML_CONFIG) {
								isCSSOLogin = true;
							}
						}
					}
				}
			}

			return isCSSOLogin;
		}
		private set;
	}

	/**
	 * We need to check how the user logged in. If the user has logged in with SSO credentials then we need to add an additional layer of verification.\
	 * SSO will only be activated for user that have been onboarded to Merchant Portal / BAM which means we need to honour the rules defined in BAM for the user logging in.
	 * NOTE: Users logging in directly with force.com credentials are excluded from this check.
	 *
	 * Allowing the user to first log in prior to verifying their configuration is not very clean, but other options such Jit Handler or Login Flow's could not be implemented
	 *
	 * Validation to check
	 * 1. Contact status = 'active'
	 * 2. Asset at the Organisation level
	 * 3. Active Contact Application record
	 */
	public PageReference preValidateBamBspAccess() {

		if(isCSSOLogin) {
			List<String> validationErrors = new List<String>();

			System.debug('Validating contact for BSP access');

			// make sure the org has the BSP product asset id
			Integer assetCount = [
					Select Count()
					From Asset
					Where AccountId = :loginAccountId
					And Product2Id In (Select Product__c From BAMApplication__c Where AppKey__c = 'BSP')
					And Status = 'Active'
			];
			if (assetCount == 0) {
				validationErrors.add(getErrorMessage('CSSO_ASSET_CONFIGURATION_INVALID')); //'The user does not have the appropriate configuration to login');
			}

			// verify the user has an active contact application of BSP, an active contact role and their contact status is active
			Integer ruleCount = [
					Select Count()
					From BAMContactRole__c
					Where ContactApplication__r.Application__r.AppKey__c = 'BSP'
					And ContactApplication__r.Contact__c = :loginContactId
					And ContactApplication__r.Contact__r.Status__c = 'Active'
					And ContactApplication__r.Status__c = 'Active'
					And Status__c = 'Active'
			];

			if (ruleCount == 0) {
				validationErrors.add(getErrorMessage('CSSO_RULE_CONFIGURATION_INVALID'));
			}

			if(!validationErrors.isEmpty()) {
				// force the user to go to the No Access page
				return Page.BSPNoAccess;
			}
		}

		return null;
	}

	/**
	 * Return a list of linked entities groups by role name
	 * This is used process what access rules are available for the user when selecting a list of cases
	 */
	public static Map<String, Set<Id>> getLinkedEntitiesByRole(List<AccessRule> rules) {
		Map<String, Set<Id>> output = new Map<String, Set<Id>>();
		for(AccessRule rule : rules) {
			if(output.get(rule.roleName) == null) {
				output.put(rule.roleName, new Set<Id>());
			}

			output.get(rule.roleName).add(rule.entity.Id);
		}

		return output;
	}

	/**
	 * Check the source of the billing account to confirm whether or not it's Star Track account
	 */
	public static Boolean isBillingAccountST(Billing_Account__c billingAccount) {
		return BspConstants.SOURCE_SYSTEM_TEAM.equalsIgnoreCase(billingAccount.Source_System__c) || BspConstants.SOURCE_SYSTEM_PEOPLESOFT.equalsIgnoreCase(billingAccount.Source_System__c);
	}

	/**
	 * Check the source of the billing account to confirm whether or not it's Aus Post account
	 */
	public static Boolean isBillingAccountAP(Billing_Account__c billingAccount) {
		return BspConstants.SOURCE_SYSTEM_SAP_ERP.equalsIgnoreCase(billingAccount.Source_System__c);
	}

	public AsyncAuspostTrackEventService.AsyncEventManagement_v1Endpoint1 getAsyncSAPEMRequest(String consignmentNumber) {
		AsyncAuspostTrackEventService.AsyncEventManagement_v1Endpoint1 service = new AsyncAuspostTrackEventService.AsyncEventManagement_v1Endpoint1();
		service.endpoint_x = AusPostSettings__c.getValues(BspConstants.TIBCO_ENDPOINTURL).URL__c;
		service.Header = new AuspostCommonSchema.InterfaceHeader();
		service.Header.InterfaceName = 'queryArticle';
		service.Header.InterfaceVersion = '1.0';
		service.Header.MessageType = 'Request';
		service.Header.SourceSystemID = configSetting.APConsignmentSearchSourceSystemID__c;
		service.Header.SourceInformation = '';
		service.Header.Timestamp = System.now();
		service.Header.BusinessReferenceID = consignmentNumber;
		Map<String, String> httpHeaders = new Map<String, String>();
		httpHeaders.put('Content-Type', 'application/soap+xml');
		httpHeaders.put('SOAPAction', '/Services/EventManagement_TrackEvent/EventManagement/querySalesforce_TrackEvents_v1');
		service.inputHttpHeaders_x = httpHeaders;

		return service;
	}

	/**
	 * Since we are storing roles against each entitiy, we only store the entity once.
	 * This means that if an entity appears in the rules more than once, we need to make sure the highest Role is associated to the entity
	 * An entity can be either an Organisation or a Billing Account
	 */
	private static String getMaxRole(String role1, String role2) {
		Map<String, Integer> allowedRoles = new Map<String, Integer>{
				'Super Admin' => 4,
				'Admin' => 3,
				'User' => 1
		};

		if(allowedRoles.containsKey(role1) && allowedRoles.containsKey(role2)) {
			return (allowedRoles.get(role1) > allowedRoles.get(role2) ? role1 : role2);
		} else {
			// return a default role since we can't compare them
			return role1;
		}
	}

	/**
	 * Since bspBase is used multiple times in the same transaction, this is used to minimise the number of SOQL's that are run in a single transaction.
	 */
	public static User getLoggedInUser() {
		if(loggedInUser == null) {
			loggedInUser = [SELECT Id, FirstName, LastName, Street, City, State, PostalCode, CompanyName, ContactId, DPID__c, Country,
					Contact.AccountId, Contact.Account.ServiceSLA__c, Contact.Account.LEGACY_ID__c, Contact.Account.Name, Contact.Account.Id,
					Contact.BillingAccount__c, Contact.FirstName, Contact.LastName, Contact.Email, Contact.MobilePhone, Contact.Phone, Contact.Pref_Method_of_Contact__c,
					Contact.BillingAccount__r.LEGACY_ID__c, Contact.BillingAccount__r.Source_System__c, Contact.BillingAccount__r.MLID__c, Contact.BillingAccount__r.Name,
					Contact.CCUAuthorisedAllOrgCases__c
			FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		}
		return loggedInUser;
	}

	public class AccessRule {
		public String roleName;
		public SObject entity;
		public String entityType { get; private set; }

		public AccessRule(String roleName, SObject entity) {
			this.roleName =  roleName;
			this.entity = entity;
			this.entityType = CommonUtils.getObjectAPINameByRecordId(entity.Id);
		}
	}

}