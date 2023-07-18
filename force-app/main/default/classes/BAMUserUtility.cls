/***
 * @description Utility class the handle various processes for BAM (Business Access Management)
 * @author Nathan Franklin
 * @date 2019-04-11
 * @group Merchant Portal
 * @changelog
 * 2019-07-04  nathan.franklin@auspost.com.au  Added additional API helper methods
 * 2020-04-22 - Nathan Franklin - Added additional fields to soql
 * 2023-07-05 - Mahesh Parvathaneni - Updated the logic to include billing account filter at app level
 */
public with sharing class BAMUserUtility {

    public static final String ACCESS_MANAGEMENT_SUPER_ADMIN = 'Super Admin';
    public static final String ACCESS_MANAGEMENT_APP_KEY = 'BAM';
    public static final String BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_NAME = 'BAM';
    public static final Integer ACCESS_MANAGEMENT_MAX_PER_ORG = 3;

    public static final String CONTACT_STATUS_ACTIVE = 'Active';
    public static final String MERCHANT_PORTAL_PROFILE_NAME = 'Merchant Portal Community User';
	public static final String KEY_NOT_CONTAINS = 'notContains';
	public static final String KEY_EQUALS = 'equals';

    /**
	 * Grab BAM Record Type Id for the External Onboarding record Sobject
	 */
    public static final Id BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID{
        get {
            return Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByName().get(BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_NAME).getRecordTypeId();
        }
        private set;
    }

    /**
	 * Grab the network Id based on the name of the community
	 */
    public static final Id MERCHANT_PORTAL_NETWORK_ID {
        get {
            if(MERCHANT_PORTAL_NETWORK_ID == null) {
                MERCHANT_PORTAL_NETWORK_ID = MerchantPortalSettings__c.getInstance().NetworkId__c;
            }
            return MERCHANT_PORTAL_NETWORK_ID;
        }
        private set;
    }

    public static final Set<String> PORTAL_PERSONA_USER_TYPES = new Set<String>{'CspLitePortal'};

    /**
     * Stores a User persona
     */
    public class UserPersona {
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String accountNumber { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String accountId { get; set; }
        @AuraEnabled public String contactId { get; set; }
        @AuraEnabled public String userId { get; set; }
        @AuraEnabled public String userProfile { get; set; }
        @AuraEnabled public Boolean isActive { get; set; }
        @AuraEnabled public Boolean userActive { get; set; }
        @AuraEnabled public Id primaryBillingAccount { get; set; }
    }

    /**
	 * Grab a list of all the billing accounts connected to BAM groups
	 * This is one of the methods we use to determine level of access for the current logged in user
	 * return details about the location is specifically related to Lodgement (Parcel Send) only
	 */
    public static Map<Id, BAMGroup__c> getGroups(Set<Id> groupIds, Id organisationId) {
        return getGroups(groupIds, organisationId, 'Active');
    }

    /**
	 * Grab a list of all the billing accounts connected to BAM groups
	 * This is one of the methods we use to determine level of access for the current logged in user
	 * return details about the location is specifically related to Lodgement (Parcel Send) only
	 */
    public static Map<Id, BAMGroup__c> getGroups(Set<Id> groupIds, Id organisationId, String status) {
        return new Map<Id, BAMGroup__c>([Select Id, Name, Organisation__c, (Select BillingAccount__r.Name, BillingAccount__r.Id, BillingAccount__r.LEGACY_ID__c, BillingAccount__r.Organisation__c, BillingAccount__r.MLID__c, BillingAccount__r.Source_System__c From GroupBillingAccounts__r)
                                            From BAMGroup__c
                                            Where Id In :groupIds
                                            And Organisation__c = :organisationId
                                            And Status__c = :status]);
    }

    /**
     * Retrieves a list of active and pending applications accessible to a contact.
     * IMPORTANT: This does not check the active status on the contact.
     * NOTE: This also returns PENDING too so these must be manually filtered out if they aren't required.
     * TODO: BSPCanViewAllConsignments__c should probably be dynamically selected
     */
    public static List<BAMContactApplication__c> getContactApplicationConfig(Id contactId) {
        List<BAMContactApplication__c> output = [Select Id, BSPCanViewAllConsignments__c,
                Application__c, Status__c, Application__r.AppKey__c, Application__r.Name, Application__r.Status__c, Application__r.SVGRefId__c,
                Application__r.AccessUrl__c, Application__r.LaunchApplicationInNewWindow__c, Application__r.Description__c, Application__r.ShortDescription__c
        From BAMContactApplication__c
        Where Application__r.Status__c = 'Active'
        And Status__c In ('Active', 'Pending')
        And Contact__c = :contactId];
        return output;
    }

    /**
     * Retrieves the application specific configuration for a particular contact
     * IMPORTANT: This does not check the active status on the contact
     * TODO: BSPCanViewAllConsignments__c should probably be dynamically selected
     */
    public static BAMContactApplication__c getContactApplicationConfig(Id contactId, String appKey) {
        List<BAMContactApplication__c> output = [Select Id, Contact__c, BSPCanViewAllConsignments__c
        From BAMContactApplication__c
        Where Application__r.AppKey__c = :appKey
        And Application__r.Status__c = 'Active'
        And Status__c = 'Active'
        And Contact__c = :contactId];
        if(output.isEmpty()) {
            return null;
        } else {
            return output[0];
        }
    }


    /**
     * Retrieves the contact details that are linked to the user passed in
     */
    public static Contact getUserContact(Id userId) {
        return [SELECT Id, Contact.AccountId, Contact.Id, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Status__c FROM User WHERE Id =: userId].Contact;
    }

    public static Boolean contactApplicationIsActive(BAMContactApplication__c contactApp) {
        return 'Active'.equalsIgnoreCase(contactApp.Status__c);
    }

    public static Boolean contactApplicationIsPendingProvision(BAMContactApplication__c contactApp) {
        return !'Active'.equalsIgnoreCase(contactApp.Status__c);
    }

    /**
     * Helper function to group and return all the application roles for onboarding
     */
    public static List<BAMApplication__c> getApplicationRolesForAccount(Id accountId) {
        // get all Applications
        List<BAMApplication__c> allApplications = [
                SELECT Id, Name, Status__c, Product__c, AppKey__c, BillingAccountFilter__c,
                (SELECT Id, Name, Role__c, Application__c, ShowBillingAccount__c, RoleDescription__c
                FROM ApplicationRoles__r WHERE Status__c = 'Active' Order By OrderPriority__c)
                FROM BAMApplication__c
                WHERE Status__c = 'Active'
                AND Product__c IN (Select Product2Id From Asset Where Status = 'Active' And AccountId = :accountId)
                ORDER BY Name
        ];

        return allApplications;
    }

    /**
	 * retrieve the user detail for requested contact
	 */
    public static User retrieveContactUserDetail(Id contactId){
        List<User> users = [
                SELECT Id,ContactId, Contact.IsPersonAccount, Contact.AccountId, UserType,
                        Contact.BillingAccount__c, Contact.BillingAccount__r.Organisation__c,
                        IsActive, Profile.Name, Contact.Status__c, BSPSignupMerchantPortal__c
                FROM User
                WHERE ContactId = :contactId
                AND Contact.IsPersonAccount = FALSE
        ];
        return (users.isEmpty() ? null : users[0]);
    }

    /**
     * Make sure the user has access to be able to call this API. Since this is a heavy query, we cache the result in Session cache
     */
    public static Boolean currentUserHasBAMApiAccess() {
        Boolean hasAccess = (Boolean)CacheManager.get('BAM_API_ACCESS');
        system.debug(hasAccess);
        if(hasAccess == null) {
            Integer count  = [
                    SELECT COUNT()
                    FROM PermissionSetAssignment
                    WHERE AssigneeId = :UserInfo.getUserId()
                    AND PermissionSetId IN (SELECT ID FROM PermissionSet WHERE Name = 'BAMIntegrationUserPermissionSet')
            ];
            hasAccess = (count > 0);

            CacheManager.put('BAM_API_ACCESS', hasAccess);
        }
        system.debug(hasAccess);
        return hasAccess;
    }

	/**
	 * @description This method returns the wrapper for Application and their related billing accounts based on the filter set at application level
	 * It can also include the billing accounts that don't match with the filter which were already selected by user if the filter is defined at later stage
	 * @param  appWithRoles						list of applicaitons with application roles
	 * @param  billingAccounts 					list of billing accounts for an orgnisation
	 * @param  billingAccountIdsKeyedByAppId 	map of existing billing accounts keyed by app id
	 * @return									wrapper of application to billing accounts based on BillingAccountFilter__c
	 */
	public static List<ApplicationBillingAccountDataWrapper> getAppBillingAccountDataWrapper(List<BAMApplication__c> appWithRoles, List<Billing_Account__c> billingAccounts, Map<Id, Set<Id>> billingAccountIdsKeyedByAppId) {
		List<ApplicationBillingAccountDataWrapper> wrapperList = new List<ApplicationBillingAccountDataWrapper>();
		Map<Id, BAMApplication__c> bamApplicationMap = new Map<Id, BAMApplication__c>(appWithRoles);

		//loop through the  applications and get the billing accounts based on billing account filter
		for (Id bamAppId : bamApplicationMap.keySet()) {
			Set<Id> selectedBillingAccountIds = new Set<Id>();
			if (billingAccountIdsKeyedByAppId != null && billingAccountIdsKeyedByAppId.containsKey(bamAppId)) {
				selectedBillingAccountIds = billingAccountIdsKeyedByAppId.get(bamAppId);
			}

			ApplicationBillingAccountDataWrapper wrapper = new ApplicationBillingAccountDataWrapper();
			wrapper.bamApplicationId = bamAppId;
			//get the billing account filter from the app level
			if (String.isNotBlank(bamApplicationMap.get(bamAppId).BillingAccountFilter__c)) {
				//deserialize the json filter
				Map<String, Object> billingAccountFilterMap;
				try {
					billingAccountFilterMap = (Map<String, Object>)JSON.deserializeUntyped(bamApplicationMap.get(bamAppId).BillingAccountFilter__c);
				} catch(Exception e) {
					//fail-safe if invalid json
					billingAccountFilterMap = new Map<String, Object>();
				}
				wrapper.billingAccounts = getBillingAccountsByAppFilter(billingAccounts, billingAccountFilterMap, selectedBillingAccountIds);
			} else {
				//add all the billing accounts if no filter at the app level
				wrapper.billingAccounts =  billingAccounts;
			}
			wrapperList.add(wrapper);
		}
		return wrapperList;
	}

	/**
	 * @description This method filters the billing accounts based on config from BillingAccountFilter__c
	 * @param  billingAccounts				list of billing accounts
	 * @param  billingAccountFilterMap		billing account filter configured for an app
	 * @param  selectedBillingAccountIds	selected billing accounts for the user
	 * @return								list of filtered billing accounts
	 */
	public static List<Billing_Account__c> getBillingAccountsByAppFilter(List<Billing_Account__c> billingAccounts, Map<String, Object> billingAccountFilterMap, Set<Id> selectedBillingAccountIds) {
		List<Billing_Account__c> filteredAccounts = new List<Billing_Account__c>();
		Set<String> keysToMatch = new Set<String>();
		Set<String> notContainsKeysToMatch = new Set<String>();

		//return if json object is empty
		if (billingAccountFilterMap.isEmpty()) {
			return billingAccounts;
		}

		try {
			//get the keys from the billing account filter defined at app level
			getKeysForComparison(billingAccountFilterMap, keysToMatch, notContainsKeysToMatch);

			//loop through billing account records and filter records that matches with the all the config that is set
			for (Billing_Account__c ba : billingAccounts) {
				Integer matchedKeys = 0;
				Integer notContainsMatchedKeys = 0;
				//check the record matched with our filter
				for (String key : billingAccountFilterMap.keySet()) {
					//check for field exists on the record
					if (!key.equalsIgnoreCase(KEY_NOT_CONTAINS) && ba.isSet(key)) {
						Object value = billingAccountFilterMap.get(key);
						//if values is array, loop through to find if any criteria matches
						if(value instanceof List<Object>) {
							if (isRecordMatched(ba, key, (List<Object>)value, KEY_EQUALS)) {
								matchedKeys++;
							}
						} else {
							//compare the SObject field value with the config value
							if (isRecordMatched(ba, key, new List<Object>{value}, KEY_EQUALS)) {
								matchedKeys++;
							}
						}
					} else if (key.equalsIgnoreCase(KEY_NOT_CONTAINS)) {
						Object notContainsValue = billingAccountFilterMap.get(key);
						if (notContainsValue instanceOf Map<String,Object> ) {
							Map<String,Object> notContainsValueMap = (Map<String,Object>)notContainsValue;
							for (String ncKey : notContainsValueMap.keySet()) {
								//check for field exists on the record
								if (ba.isSet(ncKey)) {
									Object value = notContainsValueMap.get(ncKey);
									//if values is array, loop through to find if any criteria matches
									if(value instanceof List<Object>) {
										if (isRecordMatched(ba, ncKey, (List<Object>)value, KEY_NOT_CONTAINS)) {
											notContainsMatchedKeys++;
										}
									} else {
										//compare the SObject field value with the config value
										if (isRecordMatched(ba, ncKey, new List<Object>{value}, KEY_NOT_CONTAINS)) {
											notContainsMatchedKeys++;
										}
									}
								}
							}
						}
					}
				}
				//if all the keys matched, add the billing account to the filtered list (or)
				//add the billing account if it's already in the selected list
				if((matchedKeys == keysToMatch.size() && notContainsMatchedKeys == notContainsKeysToMatch.size()) || (selectedBillingAccountIds != null && selectedBillingAccountIds.contains(ba.Id))) {
					filteredAccounts.add(ba);
				}
			}	
		} catch (Exception  ex) {
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'BAM', BAMUserUtility.class.getName(), 'getBillingAccountsByAppFilter', 'getAppBillingAccountDataWrapper', LoggingLevel.ERROR);
		}
		return filteredAccounts;
	}
	
	/**
	 * @description			This method checks the record based on equals/not contains operation with the key and value/values passed
	 * @param  ba			Billing_Account__c record
	 * @param  fieldName	Field to check on the record
	 * @param  value		Field value/values to check
	 * @param  compareKey	operator to check equals (or) notContains
	 * @return				returns boolean if record matched
	 */
	private static Boolean isRecordMatched(Billing_Account__c ba, String fieldName, List<Object> value, String compareKey) {
		Boolean isMatched = false;
		Integer notContainsKeyMatched = 0;
		for (Object obj : (List<Object>)value) {
			if (compareKey.equals(KEY_EQUALS) && ba.get(fieldName) == obj) {
				return true;
			} else if(compareKey.equals(KEY_NOT_CONTAINS)){
				String fieldVal = (String)ba.get(fieldName);
				if (!fieldVal.contains((String)obj)) {
					notContainsKeyMatched++;
				}
			}
		}
		if (compareKey.equals(KEY_NOT_CONTAINS)) {
			isMatched = notContainsKeyMatched == value.size();
		}
		return isMatched;
	}

	/**
	 * @description 					This method is used to collect all the keys (field API names) that is defined in the json filter 
	 * @param  billingAccountFilterMap 	key-value pair for the billing account filter
	 * @param  keysToMatch				fields to compare that has no other criteria set
	 * @param  notContainsKeysToMatch	fields to compare that defined in the notContains key in json filter
	 */
	private static void getKeysForComparison(Map<String, Object> billingAccountFilterMap, Set<String> keysToMatch, Set<String> notContainsKeysToMatch) {
		//loop through the json map to get the keys
		for (String key : billingAccountFilterMap.keySet()) {
			if (key.equalsIgnoreCase(KEY_NOT_CONTAINS)) {
				//get the keys from 'notContains' defined at filter
				//this is in the Map<String, Object> format again
				Object notContainsValue = billingAccountFilterMap.get(key);
				if (notContainsValue instanceOf Map<String,Object> ) {
					Map<String,Object> notContainsValueMap = (Map<String,Object>)notContainsValue;
					//add all the keys in notContains json object 
					notContainsKeysToMatch.addAll(notContainsValueMap.keySet());
				}
			} else {
				//add the keys
				keysToMatch.add(key);
			}
		}
	}

	public class ApplicationBillingAccountDataWrapper {
		@AuraEnabled
		public Id bamApplicationId {get; set;}
		@AuraEnabled
		public List<Billing_Account__c> billingAccounts {get; set;}
	}

	/**
	 * @description This method returns the map of application id to billing accounts from the contact role
	 * @param  appIdcontactRoleMap map of contact roles with linked entities keyed by app id
	 * @return                     return Map of billing accounts keyed by application id
	 */
	public static Map<Id, Set<Id>> getBillingAccountIdsKeyedByAppId(Map<String, BAMContactRole__c> appIdcontactRoleMap) {
		Map<Id, Set<Id>> billingAccountIdsKeyedByAppId = new Map<Id, Set<Id>>();

		//create map of app id to selected billing accounts for a contact if already exist
		for (String appId : appIdcontactRoleMap.keySet()) {
			if (billingAccountIdsKeyedByAppId.get(appId) == null) {
				billingAccountIdsKeyedByAppId.put(appId, new Set<Id>());
			}
			BAMContactRole__c contactRole = appIdcontactRoleMap.get(appId);
			for (BAMLinkedEntity__c le : contactRole.LinkedEntities__r) {
				billingAccountIdsKeyedByAppId.get(appId).add(le.BillingAccount__c);
			}
		}

		return billingAccountIdsKeyedByAppId;

	}

	/**
	 * //TODO: Refactor to use the selectors
	 * @description This function returns the contact role keyed by app id related to contact
	 * @param  contactId 
	 * @return Map of application id to contact role with linked entities		
	 */
	public static Map<String, BAMContactRole__c> loadContactRolePerApplication(Id contactId) {
		Map<String, BAMContactRole__c> mapApplicationRoles = new Map<String, BAMContactRole__c>();

		if (contactId != null) {
			List<BAMContactRole__c> listRoles = [
				SELECT Id, Name, Status__c, Pending_Delete__c
						, ContactApplication__c, ContactApplication__r.Application__c
						, ContactApplication__r.Pending_Delete__c
						, ApplicationRole__r.Name, ApplicationRole__r.Role__c
						, ApplicationRole__c
						, (
						SELECT Id, Name,
								Pending_Delete__c, BillingAccount__c, Organisation__c, Group__c
						FROM LinkedEntities__r
						WHERE Pending_Delete__c = false
				)
				FROM BAMContactRole__c
				WHERE ContactApplication__r.Contact__c = :contactId
				AND Pending_Delete__c != true
				ORDER BY ContactApplication__c, CreatedDate DESC
			];

			for(BAMContactRole__c role: listRoles)
			{
				if(null == mapApplicationRoles.get(role.ContactApplication__r.Application__c))
				{
					mapApplicationRoles.put(role.ContactApplication__r.Application__c, role);
				}
			}
		}
		return mapApplicationRoles;
	}

    /**
     * This service class helps with persona retrieval and switching to a new persona as necessary
     * This is in use in both the Customer Communities and also the JIT Login handler for CSSO login to BSP and Business Portal
     * This is a without sharing class to support the fact tha a community member only has access to their own Account. (Due to no Community Plus licenses allocations)
     */
    public without sharing class BAMPersonaSwitchUtility {

        // used to minimise the need to run additional soql's
        private Map<Id, String> cNumberUserMap = new Map<Id, String>();

        /**
         * Set by the setUserContext method. An instance can have only a CNumber or user Id.
         * A community user can only set their own user id which is translated to their own cnumber
         */
        private String userContextCNumber { get; set; }
        private Id networkId { get; set; }

        /**
         * Returns a list of user records with their corresponding personas based on the logged in user's cNumber if it exists
         * This is necessary since a Salesforce contact is a persona of an individual and a User record can only be related to a single contact
         * This returns persona's in the context of the community the user is accessing.
         *
         * RULES:
         * BusinessPortal:
         *  1. User is either someone with just Merchant Portal Community User (IsActive irrelevent because JIT will handle the activation) OR
         *  2.  The user has an active account for any non Merchant Portal Community User profile
         *
         * All other communities supported with personas:
         *  1. User account must be active
         *
         * Any user must have access to the community using NetworkMemberx
         */
        public Map<Id, UserPersona> personas {
            get {
                if(personas == null || personas.isEmpty()) {
                    personas = new Map<Id, UserPersona>();

                    if(String.isEmpty(userContextCNumber))
                        throw new InvalidPersonaException('User Context is Invalid');

                    personas = (Map<Id, UserPersona>)CacheManager.get('BAM_USER_PERSONA_CONTEXT', userContextCNumber + networkId);
                    if (personas != null && !personas.isEmpty())
                        return personas;

                    personas = new Map<Id, UserPersona>();

                    // grab a list of contacts/users that match the CNumber based on the rules defined in the comments of the property
                    String soql = 'Select Id, IsActive, ContactId, Contact.Id, Contact.AccountId, Contact.Account.Name, Contact.Account.LEGACY_ID__c, Contact.Name, Contact.Status__c, Contact.BillingAccount__c, Contact.Account.Id, ProfileId, Profile.Name ' +
                            'From User ' +
                            ' Where Contact.IsPersonAccount = false ' +
                            ' And UserType In :PORTAL_PERSONA_USER_TYPES ' +
                            ' And Contact.OID_ID__c = :userContextCNumber ' +
                            ' And Contact.Status__c = \'Active\' ' +
                            (MERCHANT_PORTAL_NETWORK_ID != networkId ? ' And IsActive = true ' : '') + // any non Merchant Portal profile must be active since it's most likely related to another org
                            (MERCHANT_PORTAL_NETWORK_ID == networkId ? ' And (Profile.Name = :MERCHANT_PORTAL_PROFILE_NAME Or IsActive = true) ' : ''); // if the user profile is merchant portal then it doesn't matter if it's active or not... The contact Status is used to ensure the persona is 'active'

                    System.debug('>> PERSONA SOQL: ' + soql);


                    Map<Id, User> queryResults = new Map<Id, User>((List<User>)Database.query(soql));
                    List<User> users = new List<User>();

                    // final check is to filter out any of the personas that do not have access to the specified community by checking the network member
                    for(NetworkMember member : [Select MemberId From NetworkMember Where MemberId In :queryResults.keySet() And NetworkId = :networkId]) {
                        users.add(queryResults.get(member.MemberId));
                    }

                    for (User u : users) {
                        if (u.Contact != null && u.Contact.Account != null) {
                            UserPersona persona = new UserPersona();
                            persona.accountName = u.Contact.Account.Name;
                            persona.accountNumber = u.Contact.Account.LEGACY_ID__c;
                            persona.contactName = u.Contact.Name;
                            persona.accountId = u.Contact.AccountId;
                            persona.contactId = u.ContactId;
                            persona.userId = u.Id;
                            persona.isActive = 'Active'.equalsIgnoreCase(u.Contact.Status__c);
                            persona.userActive = u.IsActive;
                            persona.userProfile = u.Profile.Name;
                            persona.primaryBillingAccount = u.Contact.BillingAccount__c;
                            personas.put(u.Id, persona);
                        }
                    }


                    CacheManager.put('BAM_USER_PERSONA_CONTEXT', userContextCNumber + networkId, personas);
                }

                System.debug('Matched Personas: ' + personas);

                return personas;
            }
            private set;
        }

        /**
         * New instance of the persona switch utility based on a user id
         * NOTE: this instance will always be in the context of a network or community
         */
        public BAMPersonaSwitchUtility(Id userId, Id networkId) {
            if((PORTAL_PERSONA_USER_TYPES.contains(UserInfo.getUserType()) && Id.valueOf(userId) != Id.valueOf(UserInfo.getUserId()))) {
                throw new InvalidPersonaException('Not authorised to change user context.');
            } else {
                this.userContextCNumber = [Select Contact.OID_ID__c From User Where Id = :userId].Contact.OID_ID__c;
                this.networkId = networkId;
            }
        }

        /**
         * New instance of the persona switch utility based on a cnumber
         * NOTE: this instance will always be in the context of a network or community
         */
        public BAMPersonaSwitchUtility(String cNumber, Id networkId) {
            if(PORTAL_PERSONA_USER_TYPES.contains(UserInfo.getUserType())) {
                throw new InvalidPersonaException('Not authorised to change user context.');
            } else {
                this.userContextCNumber = cNumber;
                this.networkId = networkId;
            }
        }

        /**
         * User has requested to switch to an alternative persona.
         * This process utilises a login JIT handler and the FederationIdentifier of a user record
         * JIT handlers force the usage the federation ID field as it's the way it maps the SAML assertion to a valid user in SF
         * The Switch Persona process involves removing the existing federation id from where it's set and set it on the desired persona the user has selected
         */
        public Boolean switchPersona(Id userId) {
            // only allow a user to swtich to an active persona
            if(personas.containsKey(userId)) {

                // grab all the valid persona's (including inactive ones) so we can remove the federation id if it's there
                // NOTE: This relies on the format of the BAM federation id to only be used by user records that BAM uses
                // If the BAM federation Id happens to be used on any other User record outside of the control of BAM,
                //      then this method could throw an error because we might not unset the fed id on that record since we only ever touch BAM controlled records
                Map<Id, User> users = new Map<Id, User>([Select Id, FederationIdentifier From User Where Id In: personas.keySet()]);
                for(User u : users.values()) {
                    if(String.isEmpty(u.FederationIdentifier)) {
                        // no need to update the record
                        users.remove(u.Id);
                    } else {
                        u.FederationIdentifier = '';
                    }
                }

                try {
                    // unset any accessible persona records that may have a fed id
                    if (!users.isEmpty()) {
                        update users.values();
                    }

                    // finally add the federation id of user record that is being switched to
                    User newPersona = new User(Id = userId, FederationIdentifier = getPersonaFormat());
                    update newPersona;

                    return true;
                } catch(Exception ex) {
                    // TODO: Proper exception handling
                    throw new InvalidPersonaException(ex.getMessage());
                }

            } else {
                throw new InvalidPersonaException('No authorisation to switch to this persona.');
            }
        }

        /**
         * TODO: Store format better and harden
         */
        public String getPersonaFormat() {
            return formatMerchantPortalCNumber(userContextCNumber);

        }

    }

    /**
     * TODO: Store format better and harden
     */
    public static String formatMerchantPortalCNumber(String cNumber) {
        return cNumber + '.merchant';
    }

    /**
     * Handles all persona related exceptions
     */
    public class InvalidPersonaException extends Exception { }

}