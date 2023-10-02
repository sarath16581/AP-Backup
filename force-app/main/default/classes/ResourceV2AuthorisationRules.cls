/***
 * @description Handles Authorisation API requests to get the List of all Applications enabled for a contact.
 *              Custom Metadatatype : 	ResourceAPI__mdt
 *              /api/2.0/authorisation/{cNumber}/{app}?orgNumber={orgNumber}&org={orgId}
 *              TODO: I think the the asset check should be done first shouldn't it? If no asset, no need to select any other data...?-
 *				This is to cater mutiple contact , in case of orgdetails are not provided
 *				If we need to do Asset query first, the query need to split upto a contact query first , like in the older version
 * @author Nathan Franklin
 * @date 2019-04-29
 * @changelog
 * 2019-04-29  	lija.jawahar@auspost.com.au  		Created
 * 2019-06-02  	nathan.franklin@auspost.com.au  	Added a more robust return response capability
 * 2019-06-04		lija.jawahar@auspost.com.au			Change URI parameter OrgId to Org
 * 2019-07-06		nathan.franklin@auspost.com.au		Added custom 404 response and a custom cache key identifier
 * 2019-09-05		nathan.franklin@auspost.com.au		Added location id and mlid to group location payloads
 * 2022-04-22 - Nathan Franklin - Added fields specific for Conveyancer's as a part of the Property VOI MP onboarding
 * 2022-12-19 - Nathan Franklin - Fixed cache bug and Organisation type mapping and a bug in the Assets check
 * 2023-10-02 - Mahesh Parvathaneni - Added isBlocked attribute for billing accounts and included BSP check for primary billing account
 */
public with sharing class ResourceV2AuthorisationRules extends ResourceAPIService.IApi {
	// Organisation Id (salesforce Id) - uri request parameter - optional
	public static String orgId = '';

	// Organisation Number  (Legacy Id) - uri request parameter -optional
	public static String orgNumber = '';

	// Contacts CNumber  (OID_Id__c ) - uri request parameter - required
	public static String cNumber = '';

	// Application key   uri  request parameter -required
	public static String appKey = '';

	//Application Specific fields from the custom setting , for JSON response mapping
	public static Map<String, String> contactApplicationdetail { get; set; }

	/**
	 * Incase the orgId or orgNumber params are passed, the cache key should be different to reflect that a different response will be returned.
	 *
	 * @return
	 */
	public override String getQueryCacheKeySuffix() {
		String orgId = requestParams.queryStringParams.get('orgId');
		String orgNumber = requestParams.queryStringParams.get('orgNumber');
		String cNumber = requestParams.dynamicUriParams[0];
		String appName = (requestParams.dynamicUriParams.size() > 1 ? requestParams.dynamicUriParams[1] : '');
		if (String.isEmpty(orgId)) {
            orgId = '';
        }
		if (String.isEmpty(orgNumber)) {
            orgNumber = '';
        }

		String output = requestParams.version + '/auth/' + cNumber + '/' + orgId + '/' + orgNumber + '/' + appName;
		System.debug(output);
		return output;
	}

	//Make sure all uri parameters are valid
	public ResourceAPIService.IResourceResponse validateQueryParams() {
		List<String> validationErrors = new List<String>();
		if (requestParams.dynamicUriParams.size() != 2 || !(requestParams.dynamicUriParams[0].startsWithIgnoreCase('C'))) {
			validationErrors.add('Parameter Mismatch');
		}

		if (validationErrors.isEmpty()) {
			return null;
		} else {
			ResourceAPIService.ResourceResponse response = new ResourceAPIService.ResourceResponse(500, '', String.join(validationErrors, '\n'));
			return (ResourceAPIService.IResourceResponse) response;
		}
	}

	// /api/2.0/authorisation/{cNumber}/{app}?orgNumber={orgNumber}&orgId={orgId}
	public override ResourceAPIService.IResourceResponse query() {

		ResourceAPIService.IResourceResponse isValid = validateQueryParams();
		if (isValid != null) {
			return isValid;
		}

		//Call the repsonsegenerator
		cNumber = requestParams.dynamicUriParams[0];
		appKey = requestParams.dynamicUriParams[1];
		orgId = requestParams.queryStringParams.get('orgId');
		orgNumber = requestParams.queryStringParams.get('orgNumber');
		System.debug('ResourceV2AuthorisationRules requestParams ==>' + cNumber + ' :: ' + orgId + ' :: ' + orgNumber + ' :: ' + appKey);

		// grab a list of app roles and rules for the CNUmber that has been passed in.
		Map<Id, List<BAMContactRole__c>> bamContactRoleMap = getMatchingContactRoleWithAPP();
		System.debug('query() bamContactRoleMap :: ' + bamContactRoleMap);

		ResourceAPIService.IResourceResponse response;
		try {
			//if the Organisation has application provisioned
			if (bamContactRoleMap.isEmpty()) {
				response = new Authorisation2NotFoundResponse();
			} else {
				AuthResult resBody = getResult(bamContactRoleMap);
				if (resBody.contact != null) {
					response = new ResourceAPIService.ResourceResponse(200, '', resBody);
				} else {
					response = new Authorisation2NotFoundResponse();
				}
			}
		} catch (Exception exp) {
			System.debug('Query() Exception :: ' + exp);
			response = new ResourceAPIService.ResourceResponse(500, '', exp);
		}

		return (ResourceAPIService.IResourceResponse) response;
	}

	//query Contacts with matching cNumber
	public static Map<Id, List<BAMContactRole__c>> getMatchingContactRoleWithAPP() {

		// return only validated contacts
		Map<Id, List<BAMContactRole__c>> validContactRoleMap = new Map<Id, List<BAMContactRole__c>>();

		Map<Id, List<BAMContactRole__c>> contactRoleMap = new Map<Id, List<BAMContactRole__c>>();
		List<BAMContactRole__c> conRoleList = new List<BAMContactRole__c>();

		// Application Specific fields from the custom setting , to be passed in dynamic query
		String fieldNames = ' ';

		//Application Specific fields from the custom setting , for JSON response mapping
		contactApplicationdetail = new Map<String, String>();

		// Get the application specific details from the Custom settings
		Map<String, BAMApplicationSpecificFields__c> fieldDetails = BAMApplicationSpecificFields__c.getAll();
		for (BAMApplicationSpecificFields__c fieldDetailRec : fieldDetails.values()) {
			if (appKey == fieldDetailRec.Name.substringBefore('_')) {
				String apiFieldName = fieldDetailRec.SObject__c + '.' + fieldDetailRec.API_Name__c;
				fieldNames = fieldNames + ' , ' + apiFieldName;
				contactApplicationdetail.put(fieldDetailRec.Label__c, fieldDetailRec.API_Name__c);
			}
		}

		String activeString = 'active';
		String sQuery = 'SELECT id '
				+ fieldNames
				+ ', Name,'
				+ 'Application_Role_Role__c,'
				+ 'ContactApplication__r.Application__r.Id,'
				+ 'ContactApplication__r.Application__r.AppKey__c,'
				+ 'ContactApplication__r.Application__r.Name,'
				+ 'ContactApplication__r.Contact__r.Id,'
				+ 'ContactApplication__r.Contact__r.AccountId,'
				+ 'ContactApplication__r.Contact__r.FirstName,'
				+ 'ContactApplication__r.Contact__r.LastName,'
				+ 'ContactApplication__r.Contact__r.OID_Id__c,'
				+ 'ContactApplication__r.Contact__r.Email,'
				+ 'ContactApplication__r.Contact__r.LEGACY_Id__c,'
				+ 'ContactApplication__r.Contact__r.APCN__c,'
				+ 'ContactApplication__r.Contact__r.Account.Id,'
				+ 'ContactApplication__r.Contact__r.Account.Name,'
				+ 'ContactApplication__r.Contact__r.Account.Role_Type_Roll_Up__c,'
				+ 'ContactApplication__r.Contact__r.Account.LEGACY_Id__c,'
				+ 'ContactApplication__r.Contact__r.Account.Organisation_Trading_Name__c,'
				+ 'ContactApplication__r.Contact__r.Account.Conveyancer_Number__c,'
				+ 'ContactApplication__r.Contact__r.Account.Registration_Type__c,'
				+ 'ContactApplication__r.Contact__r.Account.Conveyancer_Is_a__c,'
				+ 'ContactApplication__r.Contact__r.Account.BillingStreet,'
				+ 'ContactApplication__r.Contact__r.Account.BillingStreet2__c,'
				+ 'ContactApplication__r.Contact__r.Account.BillingCity,'
				+ 'ContactApplication__r.Contact__r.Account.BillingState,'
				+ 'ContactApplication__r.Contact__r.Account.BillingPostalCode,'
				+ 'ContactApplication__r.Contact__r.Account.BillingCountry,'
				+ 'ContactApplication__r.Contact__r.BillingAccount__r.Id,'
				+ 'ContactApplication__r.Contact__r.BillingAccount__r.Name,'
				+ 'ContactApplication__r.Contact__r.BillingAccount__r.LEGACY_Id__c,'
				+ 'ContactApplication__r.Contact__r.BillingAccount__r.Type__c,'
				+ 'ContactApplication__r.Contact__r.BillingAccount__r.Organisation__c,'
				+ 'ContactApplication__r.Contact__r.BillingAccount__r.Source_System__c,'
				+ 'ContactApplication__r.Contact__r.BillingAccount__r.Credit_Status__c,'
				+ 'ContactApplication__r.Contact__r.BillingAccount__c,'
				+ 'ApplicationRole__r.Application__r.Product__c,'
				+ 'ApplicationRole__r.Role__c,'
				+ 'ApplicationRole__r.ShowBillingAccount__c,'
				+ 'ApplicationRole__r.ShowGroup__c,'
				+ 'ApplicationRole__r.ShowOrganisation__c,'
				+ '('
				+ 'SELECT Id,'
				+ 'Status__c,'
				+ 'BillingAccount__r.Name,'
				+ 'BillingAccount__r.Id,'
				+ 'BillingAccount__r.LEGACY_Id__c,'
				+ 'BillingAccount__r.Type__c,'
				+ 'BillingAccount__r.Organisation__c,'
				+ 'BillingAccount__r.MLId__c,'
				+ 'BillingAccount__r.Source_System__c,'
				+ 'BillingAccount__r.Credit_Status__c,'
				+ 'Organisation__r.Name,'
				+ 'Organisation__r.Id,'
				+ 'Organisation__r.APCN__c,'
				+ 'Organisation__r.LEGACY_Id__c,'
				+ 'Organisation__r.Organisation_Trading_Name__c,'
				+ 'Organisation__r.Conveyancer_Number__c,'
				+ 'Organisation__r.Registration_Type__c,'
				+ 'Organisation__r.Conveyancer_Is_a__c,'
				+ 'Organisation__r.BillingStreet,'
				+ 'Organisation__r.BillingStreet2__c,'
				+ 'Organisation__r.BillingCity,'
				+ 'Organisation__r.BillingState,'
				+ 'Organisation__r.BillingPostalCode,'
				+ 'Organisation__r.BillingCountry,'
				+ 'Group__r.Id,'
				+ 'Group__r.Name,'
				+ 'Group__r.Organisation__c,'
				+ 'Group__r.Despatch_Location__c,'
				+ 'Group__r.Despatch_Location__r.Name,'
				+ 'Group__r.Despatch_Location__r.Location_ID__c,'
				+ 'Group__r.Despatch_Location__r.Id,'
				+ 'Group__r.Despatch_Location__r.Street__c,'
				+ 'Group__r.Despatch_Location__r.Despatch_Id__c,'
				+ 'Group__r.Despatch_Location__r.City__c,'
				+ 'Group__r.Despatch_Location__r.State__c,'
				+ 'Group__r.Despatch_Location__r.Post_Code__c'
				+ ' FROM LinkedEntities__r'
				+ ')'
				+ ' FROM BAMContactRole__c'
				+ ' WHERE Status__c = :activeString'
				+ ' AND ContactApplication__r.Application__r.AppKey__c = :appKey'
				+ ' AND ContactApplication__r.Contact__r.OID_Id__c = :cNumber'
				+ ' AND ContactApplication__r.Contact__r.IsPersonAccount=false'
				+ ' AND ContactApplication__r.Application__r.Status__c = :activeString'
				+ ' AND ContactApplication__r.Status__c = :activeString'
				+ ' AND ApplicationRole__r.Status__c = :activeString';

		// add dyanmic params
		if (!String.isBlank(orgId)) {
			sQuery += ' AND ContactApplication__r.Contact__r.Account.Id = :orgId ';
		}
		if (!String.isBlank(orgNumber)) {
			sQuery += ' AND ContactApplication__r.Contact__r.Account.LEGACY_Id__c = :orgNumber ';
		}


		System.debug('sQuery :: ' + sQuery);
		conRoleList = Database.query(sQuery);
		System.debug('conRoleList :: ' + conRoleList);

		Map<Id, Id> contactOrgMap = new Map<Id, Id>();
		Id proId ;
		for (BAMContactRole__c cr : conRoleList) {
			System.debug('productId :: ' + cr.ApplicationRole__r.Application__r.Product__c);
			proId = cr.ApplicationRole__r.Application__r.Product__c;

			// organisation
			contactOrgMap.put(cr.ContactApplication__r.Contact__r.Id, cr.ContactApplication__r.Contact__r.Account.Id);

			System.debug('ResourceV2AuthorisationRules con Id ==> ' + cr.ContactApplication__r.Contact__r.Id);
			List<BAMContactRole__c> currentConRoleList = contactRoleMap.get(cr.ContactApplication__r.Contact__r.Id);
			if (currentConRoleList == null) {
				currentConRoleList = new List<BAMContactRole__c>();
			}
			currentConRoleList.add(cr);
			contactRoleMap.put(cr.ContactApplication__r.Contact__r.Id, currentConRoleList);
		}
		System.debug('contactOrgMap:: ' + contactOrgMap.values());

		//validate the contacts org have App access
		Map<Id, Id> conAccMapWithAppAccessMap = validateOrgsAssetAccess(contactOrgMap);

		// return the contacts which have access to App
		for (Id conId : conAccMapWithAppAccessMap.keySet()) {
			System.debug(contactRoleMap.get(conId));
			List<BAMContactRole__c> cr = contactRoleMap.get(conId);
			validContactRoleMap.put(conId, cr);
		}

		System.debug(validContactRoleMap);
		return validContactRoleMap;
	}

	// checks whether the  contact's org has access to the requested Application
	public static Map<Id, Id> validateOrgsAssetAccess(Map<Id, Id> conAccMap) {

		Map<Id, Id> orgWithAPP = new Map<Id, Id>();

		// just incase (forwhatever reason) there are multiples of the same account,
		// we flip the contact/account map arround so it's easier to build our our accounts with valid assets
		Map<Id, Set<Id>> accountContactMappings = new Map<Id, Set<Id>>();
		for(Id contactId : conAccMap.keySet()) {
			if(accountContactMappings.get(conAccMap.get(contactId)) == null) {
				accountContactMappings.put(conAccMap.get(contactId), new Set<Id>());
			}
			accountContactMappings.get(conAccMap.get(contactId)).add(contactId);
		}
		

		//query assets linked to the Organisation for the specified app
		List<Asset> assetlist = [
				SELECT
						Id,
						Name,
						Product2Id,
						AccountId
				FROM Asset
				WHERE Status = 'Active'
				AND AccountId IN :accountContactMappings.keySet()
				AND Product2Id In (Select Product__c From BAMApplication__c Where AppKey__c = :appKey)
		];

		for (Asset orgAsset : assetlist) {
			for(Id contactId : accountContactMappings.get(orgAsset.AccountId)) {
				orgWithAPP.put(contactId, orgAsset.AccountId);
			}
		}
		System.debug(orgWithAPP);
		return orgWithAPP;
	}


	//List of Contacts with CNumber for  Org( if passed in URI)
	//get the application details
	//get all the Billing account, Groups and Linked Entities for the specific App
	public static AuthResult getResult(Map<Id, List<BAMContactRole__c>> contactRoleEntityMap) {

		// response for this API
		AuthResult result = new AuthResult();

		//Contact details based on CNumber
		Map<Id, AuthContact> authContactMap = new Map<Id, AuthContact>();

		Set<Id> contactIds = new Set<Id>();

		//Organisation details  mapped to contactId
		Map<Id, AuthOrganisation> authOrgMap = new Map<Id, AuthOrganisation>();

		// For BSP App, There is always a primary billing Account on the contcat with  default role - User.
		// if that user have advanced role for the primary billing account, It will be mentione din linked entity.
		Map<Id, AuthBillingAccount> primaryContactBillingAccountMap = new Map<Id, AuthBillingAccount>();

		//BillingAccounts mapped against contact
		Map<Id, Map<Id, AuthBillingAccount>> contactBillingAccountMap = new Map<Id, Map<Id, AuthBillingAccount>>();

		//Might Change - Linked entity to contact
		Map<Id, AuthLinkedEntity> linkedEntityMap = new Map<Id, AuthLinkedEntity>();

		Map<Id, AuthGroup> grpAuthGrpMap = new Map<Id, AuthGroup>();

		//To retreive the Billing Accounts  related to contact
		Map<Id, AuthBillingAccount> billingAccMap = new Map<Id, AuthBillingAccount>();

		////To retreive the groups  related to contact
		Map<Id, BAMGroup__c> groupMap = new Map<Id, BAMGroup__c>();

		try {

			for (Id contactId : contactRoleEntityMap.keySet()) {
				//Contact roles for each contact
				List<BAMContactRole__c> contactRoleList = contactRoleEntityMap.get(contactId);

				//In case Application has
				// specific fields need to be displayed
				Map<String, String> appSpecFieldValueMap = new Map<String, String>();
				if (contactApplicationdetail != null) {
					for (String field : contactApplicationdetail.keySet()) {
						appSpecFieldValueMap.put(field, String.valueOf(contactRoleList[0].ContactApplication__r.get(contactApplicationdetail.get(field))));
					}
				}

				for (BAMContactRole__c contactRole : contactRoleList) {

					//contact details
					AuthContact contactRec = new AuthContact();
					// default linked entity creation for BSP Appilication for contact's primary Billing Account
					if (contactRole.ContactApplication__r.Contact__r.BillingAccount__r.Id != null && appKey == 'BSP') {

						AuthBillingAccount authBA = new AuthBillingAccount();
						authBA.billingAccountId = contactRole.ContactApplication__r.Contact__r.BillingAccount__r.Id;
						authBA.name = contactRole.ContactApplication__r.Contact__r.BillingAccount__r.Name;
						authBA.organisation = contactRole.ContactApplication__r.Contact__r.BillingAccount__r.Organisation__c;
						authBA.accountNumber = contactRole.ContactApplication__r.Contact__r.BillingAccount__r.LEGACY_ID__c;
						authBA.sourceSystem = contactRole.ContactApplication__r.Contact__r.BillingAccount__r.Source_System__c;
						authBA.type = contactRole.ContactApplication__r.Contact__r.BillingAccount__r.Type__c;
						authBA.isBlocked = contactRole.ContactApplication__r.Contact__r.BillingAccount__r.Credit_Status__c;
						primaryContactBillingAccountMap.put(contactId, authBA);

					}

					contactRec.contactId = contactRole.ContactApplication__r.Contact__r.Id ;
					contactRec.primaryBillingAccount = contactRole.ContactApplication__r.Contact__r.BillingAccount__c;
					contactRec.organisation = contactRole.ContactApplication__r.Contact__r.Account.Id;
					contactRec.firstName = contactRole.ContactApplication__r.Contact__r.FirstName;
					contactRec.lastName = contactRole.ContactApplication__r.Contact__r.LastName;
					contactRec.emailAddress = contactRole.ContactApplication__r.Contact__r.Email;
					contactRec.cNumber = contactRole.ContactApplication__r.Contact__r.OID_ID__c;
					contactRec.apcn = contactRole.ContactApplication__r.Contact__r.APCN__c;
					contactRec.apbcn = contactRole.ContactApplication__r.Contact__r.Account.LEGACY_ID__c;
					contactRec.contactApplicationDetail = appSpecFieldValueMap;
					authContactMap.put(contactRec.contactId, contactRec);

					//Contact's Organisation
					AuthOrganisation acc = new AuthOrganisation();
					acc.organisationId = contactRole.ContactApplication__r.Contact__r.Account.Id;
					acc.name = contactRole.ContactApplication__r.Contact__r.Account.Name;
					acc.accountNumber = contactRole.ContactApplication__r.Contact__r.Account.LEGACY_ID__c;
					acc.type = contactRole.ContactApplication__r.Contact__r.Account.Role_Type_Roll_Up__c;
					acc.tradingName = contactRole.ContactApplication__r.Contact__r.Account.Organisation_Trading_Name__c;
					acc.billingAddress = new AuthAddress(contactRole.ContactApplication__r.Contact__r.Account.BillingStreet, contactRole.ContactApplication__r.Contact__r.Account.BillingStreet2__c,
															contactRole.ContactApplication__r.Contact__r.Account.BillingCity, contactRole.ContactApplication__r.Contact__r.Account.BillingState,
															contactRole.ContactApplication__r.Contact__r.Account.BillingPostalCode, contactRole.ContactApplication__r.Contact__r.Account.BillingCountry);
					acc.isConveyancer = contactRole.ContactApplication__r.Contact__r.Account.Conveyancer_Is_a__c;
					if(contactRole.ContactApplication__r.Contact__r.Account.Conveyancer_Is_a__c) {
						acc.conveyancer = new AuthConveyancer(String.valueOf(contactRole.ContactApplication__r.Contact__r.Account.Conveyancer_Number__c), contactRole.ContactApplication__r.Contact__r.Account.Registration_Type__c);
					}
					authOrgMap.put(contactId, acc);

					AuthLinkedEntity accessEntity = new AuthLinkedEntity();
					accessEntity.role = contactRole.Application_Role_Role__c;
					accessEntity.contactId = contactRole.ContactApplication__r.Contact__r.Id;
					Set<Id> orgroupIds = new Set<Id> ();
					Set<Id> baIds = new Set<Id> ();
					Set<Id> groupIds = new Set<Id> ();

					// if the role is Organisation based then we rely on the Org of the contact it's assigned to
					if (contactRole.ApplicationRole__r.ShowOrganisation__c) {
						orgroupIds.add(contactRole.ContactApplication__r.Contact__r.Account.Id);

						AuthOrganisation accAO = new AuthOrganisation();
						accAO.organisationId = contactRole.ContactApplication__r.Contact__r.Account.Id;
						accAO.name = contactRole.ContactApplication__r.Contact__r.Account.Name;
						accAO.accountNumber = contactRole.ContactApplication__r.Contact__r.Account.LEGACY_ID__c;
						accAO.type = contactRole.ContactApplication__r.Contact__r.Account.Role_Type_Roll_Up__c;
						accAO.tradingName = contactRole.ContactApplication__r.Contact__r.Account.Organisation_Trading_Name__c;
						accAO.billingAddress = new AuthAddress(contactRole.ContactApplication__r.Contact__r.Account.BillingStreet, contactRole.ContactApplication__r.Contact__r.Account.BillingStreet2__c,
																contactRole.ContactApplication__r.Contact__r.Account.BillingCity, contactRole.ContactApplication__r.Contact__r.Account.BillingState,
																contactRole.ContactApplication__r.Contact__r.Account.BillingPostalCode, contactRole.ContactApplication__r.Contact__r.Account.BillingCountry);
						accAO.isConveyancer = contactRole.ContactApplication__r.Contact__r.Account.Conveyancer_Is_a__c;
						if(contactRole.ContactApplication__r.Contact__r.Account.Conveyancer_Is_a__c) {
							accAO.conveyancer = new AuthConveyancer(String.valueOf(contactRole.ContactApplication__r.Contact__r.Account.Conveyancer_Number__c), contactRole.ContactApplication__r.Contact__r.Account.Registration_Type__c);
						}

						authOrgMap.put(contactId, accAO);
					}

					if (contactRole.LinkedEntities__r != null) {

						// TODO... super admin without any linked entities records

						for (BAMLinkedEntity__c linkedEntity : contactRole.LinkedEntities__r) {
							if (!'Active'.equalsIgnoreCase(linkedEntity.Status__c)) {
								continue;
							}

							if (contactRole.ApplicationRole__r.ShowBillingAccount__c && linkedEntity.BillingAccount__c != null) {

								baIds.add(linkedEntity.BillingAccount__r.Id);

								//create AuthBilling Record
								AuthBillingAccount ba = new AuthBillingAccount();
								ba.billingAccountId = linkedEntity.BillingAccount__r.Id;
								ba.name = linkedEntity.BillingAccount__r.Name;
								ba.organisation = linkedEntity.BillingAccount__r.Organisation__c;
								ba.accountNumber = linkedEntity.BillingAccount__r.LEGACY_ID__c;
								ba.sourceSystem = linkedEntity.BillingAccount__r.Source_System__c;
								ba.type = linkedEntity.BillingAccount__r.Type__c;
								ba.isBlocked = linkedEntity.BillingAccount__r.Credit_Status__c;

								billingAccMap.put(linkedEntity.BillingAccount__r.Id, ba);

							} else if (contactRole.ApplicationRole__r.ShowGroup__c && linkedEntity.Group__c != null) {
								groupIds.add(linkedEntity.Group__r.Id);
								groupMap.put(linkedEntity.Group__r.Id, linkedEntity.Group__r);
							}

						}
						// end of linked entity

						accessEntity.role = contactRole.Application_Role_Role__c;
						accessEntity.organisations = orgroupIds;
						accessEntity.billingAccounts = baIds;
						accessEntity.groups = groupIds;
						linkedEntityMap.put(contactRole.Id, accessEntity);
					}
				}
				// end of  role
			}
			// end of contact list

			//get Groups child records
			if (!groupMap.isEmpty()) {

				// get Groups related Billing Accounts
				Map<Id, List<BAMGroupBillingAccount__c>> grpBillingAccounts = getGroupBADetails(groupMap.keySet());

				//  parse through the groups to create auth Billing Accounts and auth location details
				grpAuthGrpMap = parseGroupRecs(groupMap);


				// Adding Billing accounts to billingAccMap
				for (Id aGroupId : grpAuthGrpMap.keySet()) {

					List<Id> billingAccountId = new List<Id>();
					for (BAMGroupBillingAccount__c gba : grpBillingAccounts.get(aGroupId)) {

						billingAccountId.add(gba.BillingAccount__r.Id);

						// If the billing account id not already in the billingaccount map
						if ((billingAccMap.get(gba.BillingAccount__r.Id)) == null) {

							AuthBillingAccount ba = new AuthBillingAccount();
							ba.billingAccountId = gba.BillingAccount__r.Id;
							ba.name = gba.BillingAccount__r.Name;
							ba.organisation = gba.BillingAccount__r.Organisation__c;
							ba.accountNumber = gba.BillingAccount__r.LEGACY_ID__c;
							ba.sourceSystem = gba.BillingAccount__r.Source_System__c;
							ba.type = gba.BillingAccount__r.Type__c;
							ba.isBlocked = gba.BillingAccount__r.Credit_Status__c;
							billingAccMap.put(ba.billingAccountId, ba) ;

						}
					} // end of grpBillingAccounts loop

					grpAuthGrpMap.get(aGroupId).billingAccountIds = billingAccountId;
				} //end of grpAuthGrpMap loop
			}


			// In case of contact have a primary billing account
			for (Id contactId : contactRoleEntityMap.keySet()) {
				if (primaryContactBillingAccountMap.get(contactId) != null) {
					// Adding primary Billing account to contacts  Billing accountMap, if it is not in Linked entities
					AuthBillingAccount primaryBA = primaryContactBillingAccountMap.get(contactId);
					AuthBillingAccount authBAMatch = billingAccMap.get(primaryBA.billingAccountId);
					if (authBAMatch == null) {
						billingAccMap.put(primaryBA.billingAccountId, primaryBA);
					}
				}
				System.debug('getResult billingAccMap :: ' + billingAccMap);
				contactBillingAccountMap.put(contactId, billingAccMap);
			}

			result.groups = grpAuthGrpMap.values();
			result.contact = authContactMap.values();
			result.rules = linkedEntityMap.values();
			result.organisation = authOrgMap.values();
			result.billingAccounts = billingAccMap.values();

		} catch (Exception exp) {
			System.debug('getResult Exception :: ' + exp);
		}
		return result;
	}


	// Get the Billing account details for each group
	public static Map<Id, List<BAMGroupBillingAccount__c>> getGroupBADetails(Set<Id> groupIds) {

		// Map group id against List of Billing Account group records
		Map<Id, List<BAMGroupBillingAccount__c>> gBAMap = new Map<Id, List<BAMGroupBillingAccount__c>>();

		List<BAMGroupBillingAccount__c> grpBAlist = [
				SELECT
						Id,
						Group__r.Id,
						BillingAccount__c,
						BillingAccount__r.Id,
						BillingAccount__r.Name,
						BillingAccount__r.LEGACY_ID__c,
						BillingAccount__r.Type__c,
						BillingAccount__r.Organisation__c,
						BillingAccount__r.Source_System__c,
						BillingAccount__r.Credit_Status__c
				FROM BAMGroupBillingAccount__c
				WHERE Group__r.Id IN :groupIds
		];

		for (Id groupId : groupIds) {
			List<BAMGroupBillingAccount__c> thisGBAList = new List<BAMGroupBillingAccount__c>();
			for (BAMGroupBillingAccount__c gBA : grpBAlist) {
				if (gBA.Group__r.Id == groupId) {
					thisGBAList.add(gBA);
				}
			}
			gBAMap.put(groupId, thisGBAList);
		}

		return gBAMap;
	}


	//Returns Authgroup without BillingAccount details
	public static Map<Id, AuthGroup> parseGroupRecs(Map<Id, BAMGroup__c> grpMap) {

		Map<Id, AuthGroup> groupDetailMap = new Map<Id, AuthGroup>();

		for (BAMGroup__c grpRec : grpMap.values()) {
			GroupLocation loc = null;

			if(grpRec.Despatch_Location__r != null) {
				loc = new GroupLocation();

				Map<String, String> addressMap = new Map<String, String>();
				addressMap.put('street', grpRec.Despatch_Location__r.Street__c);
				addressMap.put('city', grpRec.Despatch_Location__r.City__c);
				addressMap.put('state', grpRec.Despatch_Location__r.State__c);
				addressMap.put('postCode', grpRec.Despatch_Location__r.Post_Code__c);

				if (!String.isEmpty(grpRec.Despatch_Location__r.Name)) {
					loc.sfid = grpRec.Despatch_Location__c;
					loc.id = grpRec.Despatch_Location__r.Location_ID__c;
					loc.dispatchId = grpRec.Despatch_Location__r.Despatch_ID__c;
					loc.address = addressMap;
					loc.name = grpRec.Despatch_Location__r.Name;
				}
			}

			AuthGroup groupRec = new AuthGroup();
			groupRec.groupId = grpRec.Id;
			groupRec.groupName = grpRec.Name;
			groupRec.location = loc;
			groupRec.organisationId = grpRec.Organisation__c;
			groupDetailMap.put(grpRec.Id, groupRec);

		}
		System.debug('parseGroupRecs groupDetailMap :: ' + groupDetailMap);
		return groupDetailMap;
	}


	// Application details based on contact
	public class AuthContact {
		public String contactId { get; set; }
		public String organisation { get; set; }
		public String firstName { get; set; }
		public String lastName { get; set; }
		public String emailAddress { get; set; }
		public String cNumber { get; set; }
		public String apcn { get; set; }
		public String apbcn { get; set; }
		public String primaryBillingAccount { get; set; }
		public Map<String, String> contactApplicationDetail { get; set; }
	}

	public class AuthLinkedEntity {
		public String role { get; set; }
		public String contactId { get; set; }
		public Set<Id> organisations { get; set; }
		public Set<Id> billingAccounts { get; set; }
		public Set<Id> groups { get; set; }
	}

	public class AuthOrganisation {
		public String organisationId { get; set; }
		public String name { get; set; }
		public String accountNumber { get; set; }
		public String type { get; set; }
		public String tradingName { get; set; }
		public AuthAddress billingAddress { get; set; }
		public Boolean isConveyancer { get; set; }
		public AuthConveyancer conveyancer;
	}

	public class AuthConveyancer {
		public String registrationNumber { get; set; }
		public String registrationType { get; set; }

		public AuthConveyancer(String registrationNumber, String registrationType) {
			this.registrationNumber = registrationNumber;
			this.registrationType = registrationType;

		}
	}

	public class AuthAddress {
		public String street { get; set; }
		public String street2 { get; set; }
		public String city { get; set; }
		public String state { get; set; }
		public String postCode { get; set; }
		public String country { get; set; }

		public AuthAddress(String street, String street2, String city, String state, String postCode, String country) {
			this.street = street;
			this.street2 = street2;
			this.city = city;
			this.state = state;
			this.postCode = postCode;
			this.country = country;
		}
	}

	public class AuthBillingAccount {
		public String billingAccountId { get; set; }
		public String name { get; set; }
		public String organisation { get; set; }
		public String accountNumber { get; set; }
		public String sourceSystem { get; set; }
		public String type { get; set; }
		public Boolean isBlocked { get; set; }
	}

	public class AuthGroup {
		public String groupId { get; set; }
		public String groupName { get; set; }
		public String organisationId { get; set; }
		public String type { get; set; }
		public GroupLocation location { get; set; }
		public List<Id> billingAccountIds { get; set; }
	}

	public class GroupLocation {
		public String sfid { get; set; }
		public String id { get; set; }
		public String dispatchId { get; set; }
		public Map<String, String> address { get; set; }
		public String name { get; set; }
	}

	public class AuthResult {
		public List<AuthContact> contact;
		public List<AuthLinkedEntity> rules;
		public List<AuthOrganisation> organisation;
		public List<AuthBillingAccount> billingAccounts;
		public List<AuthGroup> groups;
	}

	public class Authorisation2NotFoundResponse extends ResourceAPIService.IResourceResponse {

		public override Integer getResponseCode() {
			return 404;
		}

		//Returns serialize result in JSON format
		public override String serialize() {
			return '';
		}
	}

}