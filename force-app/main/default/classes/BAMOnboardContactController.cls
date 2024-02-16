/***
 * @description
 * Methods to support the sending of the provisioning request from Salesforce to Camunda
 * Inputs: ContactId
 * Output: Map with up to two payload strings - one for Provision, another for Deprovision
 *
 * @author Victor Cheng
 * @date 2019-06-27
 * @group Merchant Portal
 * @changelog
 * 2019-01-30 - gdevasurendra@auspost.com.au - Capability to update Primary Billing Account (REQ2044525)
 * 2020-05-24 - Nathan Franklin - Fixed a few small bugs where pending deletes = true were preventing subsequent selection
 * 2021-01-11 - Swati Mogadala - REQ2279110 Filter out Peoplesoft accounts from list of billing accounts
 * 2023-07-05 - Mahesh Parvathaneni - Updated the logic to include billing account filter at app level
 * 2024-02-16 - Jacob.Isaac@auspost.com.au - Added Consignment Searching option in Merchant Portal - REQ2982613
 */
public without sharing class BAMOnboardContactController {

    public class BAMInternalException extends Exception{}

    public static String FIELD_MESSAGE = 'message';
    public static String MSG_NO_ACCESS = 'You do not have permission to edit these records, no changes have been saved';
    public static String FIELD_CONTACT = 'contact';
    public static String FIELD_APPLICATIONS = 'applications';
    public static String FIELD_BILLING_ACCOUNTS = 'billingAccounts';
    public static String FIELD_CONTACT_APPLICATIONS = 'contactApplications';
    public static String FIELD_CONTACT_ROLES_PER_APPLICATION = 'contactRolesPerApplication';
	public static String FIELD_BILLING_ACCOUNTS_BY_APPLICATION = 'billingAccountsByApplication';
    public static List<String> INVALID_BILLING_ACCOUNT_TYPES = new List<String>{
            'SBBA', 'CASH'
    };
    public static String FIELD_APPLICATION_ROLE = 'ApplicationRole__c';
    public static String FIELD_APPLICATION = 'Application__c';


    public static String FIELD_ID = 'Id';
    public static String FIELD_UPSERT = 'upsert';
    public static String FIELD_DESTRUCTIVE = 'destructive';
    public static String FIELD_SELECTED_ENTITIES = 'selectedEntities';
    public static String FIELD_STATUS = 'status';
    public static String STATUS_OK = 'OK';
    public static String STATUS_ERROR = 'Error';

    public static String STATUS_ACTIVE = 'Active';
    public static String STATUS_PENDING = 'Pending';


    private static UserRecordAccess getRecordAccess(Id recordId)
    {
        Id userId = UserInfo.getUserId();

        List<UserRecordAccess> listUserRecordAccesses = [
                SELECT RecordId, HasEditAccess, HasReadAccess, HasDeleteAccess
                FROM UserRecordAccess
                WHERE UserId = :userId
                AND RecordId = :recordId
        ];
        //System.debug('USR = ' + listUserRecordAccesses);

        return listUserRecordAccesses[0];
    }

    private static List<BAMApplication__c> loadAllApplications(Id accountId)
    {
        // Get all provisioned Applications by using Product + Asset
        List<Product2> listProducts = [
                SELECT Id, Name,
                (
                        SELECT Id, Name
                        FROM BAM_Applications__r
                ),
                (
                        SELECT Id, Name, AccountId
                        FROM Assets
                        WHERE AccountId =: accountId
                        AND Status != 'Inactive'
                )
                FROM Product2
                WHERE Id IN (
                        SELECT Product__c
                        FROM BAMApplication__c
                )
                ORDER BY Name
        ];

        // collect all the BAMApplication Ids which have an active asset
        List<Id> appIds = new List<Id>();
        for(Product2 product:listProducts)
        {
            if(product.Assets.size() > 0)
            {
                // assume 1:1 Product:BAMApplication
                appIds.add(product.BAM_Applications__r[0].Id);
            }
        }

        // get all Applications, which is our STATIC DATA
        List<BAMApplication__c> allApplications = [
                SELECT Id, Name, Status__c, Product__c, BillingAccountFilter__c,
                (
                        SELECT Id, Name, Role__c, Application__c, ShowBillingAccount__c, ShowGroup__c
                        FROM ApplicationRoles__r
                        WHERE Status__c =: STATUS_ACTIVE
                        ORDER BY OrderPriority__c ASC
                )
                FROM BAMApplication__c
                WHERE Status__c =: STATUS_ACTIVE
                AND Id IN: appIds
                ORDER BY Name
        ];
        //System.debug('!@#$ appIds = ' + appIds);
        //System.debug('!@#$ allApplications = ' + allApplications);
        return allApplications;
    }
	
    //REQ2279110 added filter criteria to remove Peoplesoft accounts 
    private static List<Billing_Account__c> loadBillingAccounts(Id accountId, List<BAMApplication__c> allApps)
    {
        List<Billing_Account__c> output = new List<Billing_Account__c>();
		if (accountId != null) {
			Map<Id, BAMApplication__c> bamApplicationMap = new Map<Id, BAMApplication__c>(allApps);
			//get fieldoverrides for billing accounts - this includes basic fiels plus any fields defined in BillingAccountFilter__c field
			Set<SObjectField> fieldOverrides = BAMUserUtility.getBillingAccountFieldOverridesWithFilterFields(bamApplicationMap);
			output =  BillingAccountsSelector.newInstance('Name', 'Asc', fieldOverrides).selectByOrgId(new Set<Id>{accountId}, 
								new Set<Object>{BillingAccountsSelector.Options.FILTER_ACTIVE, BillingAccountsSelector.Options.FILTER_TYPE_NOT_IN_SBBA_CASH, BillingAccountsSelector.Options.FILTER_SOURCE_SYSTEM_NOT_IN_PEOPLE_SOFT}).values();
		}
        return output;
    }


    /**
     * Get the latest request for each Application, used for determining whether it should be locked or not
     *
     * @param contactId
     *
     * @return
     */
    private static Map<String, BAMContactApplication__c> loadContactApplications(Id contactId)
    {
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        // get the latest request per contact-application
        List<BAMContactApplication__c> listApps  = [
                SELECT Id, Application__c, Status__c,BSPCanViewAllConsignments__c,
                (
                        SELECT Id, Name, Status__c, Contact_Application__c, Contact_Application__r.Application__c,Error__c, Type__c,
                                CSSOStartedDateTime__c, CSSOFulfilledDateTime__c, Request_Date__c, StartedResponseReceived__c,
                                SuccessResponseReceived__c, ErrorResponseReceived__c, CreatedBy.Name, CreatedBy.UserType
                        FROM BAM_External_Onboarding_Requests__r
                        WHERE RecordTypeId =: bamExtObRTId
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                )

                FROM BAMContactApplication__c
                WHERE Contact__c =: contactId
        ];

        Map<String, BAMContactApplication__c> mapApplicationRequest = new Map<String , BAMContactApplication__c>();
        for(BAMContactApplication__c app:listApps)
        {
            mapApplicationRequest.put(app.Application__c, app);
        }
        return mapApplicationRequest;
    }


    private static Map<String, BAMContactRole__c> loadContactRolePerApplication(Id contactId)
    {
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
                //AND Pending_Delete__c = false
                ORDER BY ContactApplication__c, CreatedDate DESC
        ];

        Map<String, BAMContactRole__c> mapApplicationRoles = new Map<String, BAMContactRole__c>();
        for(BAMContactRole__c role: listRoles)
        {
            if(null == mapApplicationRoles.get(role.ContactApplication__r.Application__c))
            {
                mapApplicationRoles.put(role.ContactApplication__r.Application__c, role);
            }
        }
        return mapApplicationRoles;
    }

	@AuraEnabled
	public static Map<String, Object> loadInitialState(Id contactId)
	{
		Map<String, Object> mapResults = new Map<String, Object> ();

		// check user access for the contact
		UserRecordAccess readContact = getRecordAccess(contactId);
		//field overrides 
		Map<SObjectType,Set<SObjectField>> fieldOverrides = new Map<SObjectType,Set<SObjectField>> {
			Contact.SObjectType => new Set<SObjectField> {
				Contact.Id, Contact.AccountId, Contact.Name, Contact.Phone, Contact.Email, Contact.OID_ID__c, Contact.Status__c, Contact.CRMCSSOID__c, Contact.BillingAccount__c,
				Contact.BAMCSSOErrorMessage__c, Contact.BAMCSSOError__c, Contact.BAMInviteAcceptedDate__c, Contact.BAMInviteRequestDate__c
			},
			Billing_Account__c.SObjectType => new Set<SObjectField> {
				Billing_Account__c.Name
			}
		};
		// get the contact record
		List<Contact> contacts = ContactsSelector.newInstance(0, fieldOverrides).selectById(new Set<Id>{contactId}, new Set<Object>{ContactsSelector.Options.WITH_BILLING_ACCOUNT}).values();

		if(contacts.size() == 1)
		{
			Contact currContact = contacts[0];
			mapResults.put(FIELD_CONTACT, currContact);

			// load static data

			//1. Applications and Roles
			List<BAMApplication__c> allApplications = loadAllApplications(currContact.AccountId);
			mapResults.put(FIELD_APPLICATIONS, allApplications);

			//2. Billing Accounts
			List<Billing_Account__c> billingAccounts = loadBillingAccounts(currContact.AccountId, allApplications);

			// load contact data
			// 1. Latest External request, this determines if we show error or pending
			Map<String, BAMContactApplication__c> externalRequestsByApp = loadContactApplications(contactId);
			mapResults.put(FIELD_CONTACT_APPLICATIONS, externalRequestsByApp);

			// 2. Contact Roles per Application
			Map<String, BAMContactRole__c> rolesPerApp = loadContactRolePerApplication(contactId);
			mapResults.put(FIELD_CONTACT_ROLES_PER_APPLICATION, rolesPerApp);

			//3. Filter Billing Accounts per application
			Map<Id, Set<Id>> existingBillingAccountsKeyedByAppId = BAMUserUtility.getBillingAccountIdsKeyedByAppId(rolesPerApp);
			List<BAMUserUtility.ApplicationBillingAccountDataWrapper> billingAccountsByApp = BAMUserUtility.getAppBillingAccountDataWrapper(allApplications, billingAccounts, existingBillingAccountsKeyedByAppId);
			mapResults.put(FIELD_BILLING_ACCOUNTS_BY_APPLICATION, billingAccountsByApp);

		}

		return mapResults;

	}

    @AuraEnabled
    public static Map<String, Object> saveProvisionRequests(Id contactId, List<Map<String, Object>> pageState, Id primaryBillingAccount) {

        UserRecordAccess contactAccess = getRecordAccess(contactId);

//        if(contactAccess.HasEditAccess == false)
//        {
//            Map<String, Object> mapNoContactAccess = new Map<String, Object>();
//            mapNoContactAccess.put(FIELD_MESSAGE, MSG_NO_ACCESS);
//            mapNoContactAccess.put(FIELD_STATUS, STATUS_ERROR);
//            return mapNoContactAccess;
//        }
        Contact contactRecord = [
                SELECT Id, AccountId, OID_ID__c, Email, FirstName, LastName
                FROM Contact
                WHERE Id =: contactId
        ];
        Id orgId = contactRecord.AccountId;
        Boolean userExists = doesUserExist(contactId);
		Boolean BSPCanViewAllConsignments = false;

        // loop through the updates for each application
        List<Id> upsertApplicationIds = new List<Id>();
        List<Map<Object, Object>> upsertApplicationRoles = new List<Map<Object, Object>>();
		Map<Id, List<Map<Object, Object>>> applicationRolesKeyedByAppId = new Map<Id, List<Map<Object, Object>>>();

        // for delete/deactivation
        List<Map<Object, Object>> deleteApplicationRoles = new List<Map<Object, Object>>();

        for (Map<String, Object> mapAppState : pageState) {
            //System.debug('app :: ' + mapAppState);
            Id appId = (Id) mapAppState.get(FIELD_ID);
			if(mapAppState.containsKey('BSPCanViewAllConsignments__c')){
				BSPCanViewAllConsignments = (Boolean) mapAppState.get('BSPCanViewAllConsignments__c');
			}
            // Contact Roles to upsert for this application
            List<Object> upserts = (List<Object>) mapAppState.get(FIELD_UPSERT);
            //System.debug('upsert ---- ' + upserts);
            if (upserts.size() > 0) {
                upsertApplicationIds.add(appId);

				if (applicationRolesKeyedByAppId.get(appId) == null) {
					applicationRolesKeyedByAppId.put(appId, new List<Map<Object, Object>>());
				}

                // loop through and add the application-role Ids to upsert
                for (Object objAppRole : upserts) {
                    Map<Object, Object> mapApplicationRole = (Map<Object, Object>) objAppRole;
                    upsertApplicationRoles.add(mapApplicationRole);
					applicationRolesKeyedByAppId.get(appId).add(mapApplicationRole);
                }
            }

            // contact roles to Deactivate for this application
            List<Object> destructive = (List<Object>) mapAppState.get(FIELD_DESTRUCTIVE);
            //System.debug('destructive ---- ' + destructive);
            if (destructive.size() > 0) {
                for (Object objAppRole : destructive) {
                    Map<Object, Object> mapApplicationRole = (Map<Object, Object>) objAppRole;
                    deleteApplicationRoles.add(mapApplicationRole);
                }
            }
        }

        System.debug('upsertApplicationIds: ' + upsertApplicationIds.size());
        System.debug('deleteApplicationRoles: ' + deleteApplicationRoles.size());

        if(upsertApplicationIds.size() > 0) {
            // if user record does not exist for the contact perform duplicate check
            // we only do this if the user is provisioning a role
            if(String.isEmpty(contactRecord.OID_ID__c)) {
                // LDAP check
                if(BAMValidationService.checkIfDulicateCnumberExistsInOrg(orgId, contactRecord.Email)) {
                    throw new AuraHandledException('Email address has already been registered in this Organisation by another contact.' + (String.isNotEmpty(BAMValidationService.lastFoundCNumber) ? ' - Id: ' + BAMValidationService.lastFoundCNumber : ''));
                }
            }
        }

		validateBillingAccountsByApp(contactId, applicationRolesKeyedByAppId);

        try
        {

            // clear any CSSO error messages on the contact
            List<Contact> contacts = [SELECT Id, BAMCSSOError__c, BAMCSSOErrorMessage__c, BillingAccount__c FROM Contact WHERE Id=:contactId];
            Contact currContact = contacts[0];
            if((currContact.BAMCSSOError__c != null && currContact.BAMCSSOError__c != true)
                    || (currContact.BAMCSSOErrorMessage__c != null && currContact.BAMCSSOErrorMessage__c!= '')) {

                currContact.BAMCSSOErrorMessage__c = null;
                currContact.BAMCSSOError__c = false;

                // If the billing account has been changed by the UI, then update it
                if (primaryBillingAccount != null && currContact.BillingAccount__c != primaryBillingAccount){
                    System.debug('Billing Account updated to ' + primaryBillingAccount);
                    currContact.BillingAccount__c = primaryBillingAccount;
                }

                update currContact;

            }

            // upsert by hierarchy
            upsertContactApplications(contactId, upsertApplicationIds,BSPCanViewAllConsignments);
            upsertContactRoles(contactId, upsertApplicationRoles);
            upsertLinkedEntities(contactId, upsertApplicationRoles);

            // delete any contact roles
            deleteContactRoles(contactId, deleteApplicationRoles);

            // clean up and Contact-Applications without active contact roles
            deleteContactApplications(contactId);


            // return a message for alert
            String sMessage = '';
            sMessage += 'Updated ' + upsertApplicationRoles.size() + ' roles.';
            sMessage += ' Removed ' + deleteApplicationRoles.size() + ' roles.';

            // reload details (in case page does not reload)
            Map<String, Object> mapResults = loadInitialState(contactId);
            mapResults.put('message', sMessage);

            // check to upsert User
            if(!userExists) {
                String flowError = createUserUsingFlow(contactId);
                if(null != flowError)
                {
                    mapResults.put(FIELD_MESSAGE, flowError);
                    mapResults.put(FIELD_STATUS, STATUS_ERROR);
                    // early out, don't send the callout
                    return mapResults;
                }
            }

            // do the actual send
            Map<String, String> mapProvision = BAMProvision.provision(contactId);
            String sProvision = (String) mapProvision.get(BAMProvision.FIELD_PROVISION);
            String sDeprovision = (String) mapProvision.get(BAMProvision.FIELD_DEPROVISION);
            System.debug('BAMOnboardContact:: provision = ' + sProvision);
            System.debug('BAMOnboardContact:: deprovision = ' + sDeprovision);


            if((sProvision != null && sProvision != '')
                    || (sDeprovision != null && sDeprovision != ''))
            {
                BAMProvisionCallout.processRequest(contactId, mapProvision);
            }
            mapResults.put(FIELD_STATUS, STATUS_OK);
            return mapResults;
        }
        catch(Exception ex)
        {

            System.debug('BAMOnboardContactController::SaveProvision Error:' + ex.getMessage());

            Map<String, Object> mapResults = new Map<String, Object>();

            mapResults.put(FIELD_MESSAGE, ex.getMessage());
            mapResults.put(FIELD_STATUS, STATUS_ERROR);

            return mapResults;
        }
    }

	/**
	 * @description This method validates the selected billing accounts are as per the filter defined at application level
	 * It ignores the validation on already existing billing accounts for the contact that are deviated to filter
	 * @param  contactId 
	 * @param  applicationRolesKeyedByAppId 
	 */
	private static void validateBillingAccountsByApp(Id contactId, Map<Id, List<Map<Object, Object>>> applicationRolesKeyedByAppId) {
        Set<Id> appIds = new Set<Id>();
        Set<Id> selectedBillingAccountIds = new Set<Id>();
		Map<Id, List<Billing_Account__c>> billingAccountsKeyedByAppId = new Map<Id, List<Billing_Account__c>>();
        Map<Id, Billing_Account__c> billingAccountMap = new Map<Id, Billing_Account__c>();
        Map<Id,BAMApplication__c> appMap = new Map<Id,BAMApplication__c>();

		//get the existing contact roles with linked entities if any
		Map<String, BAMContactRole__c> contactRolesKeyedByAppId = BAMUserUtility.loadContactRolePerApplication(contactId);
		Map<Id, Set<Id>> existingBillingAccountsKeyedByAppId = BAMUserUtility.getBillingAccountIdsKeyedByAppId(contactRolesKeyedByAppId);

		//get all the selected billing account ids from the appRoles pageState
		//get the appIds that have billing accounts selected
        for(Id appId : applicationRolesKeyedByAppId.keySet()) {
            List<Map<Object, Object>> appRoles = applicationRolesKeyedByAppId.get(appId);
            for(Map<Object, Object> objAppRole : appRoles) {
                List<Object> listLinkedEntities = (List<Object>) objAppRole.get(FIELD_SELECTED_ENTITIES);
                if(!listLinkedEntities.isEmpty()) {
                    appIds.add(appId);
                    for(Object leId : listLinkedEntities) {
                        selectedBillingAccountIds.add((Id)leId);
                    }
                }
            }
        }

		//get the applications
        if(!appIds.isEmpty()){
            appMap = new Map<Id,BAMApplication__c>([SELECT Id, Name, Status__c, Product__c, BillingAccountFilter__c FROM BAMApplication__c WHERE Status__c='Active' AND ID IN:appIds]);
        }

        if (!selectedBillingAccountIds.isEmpty()) {
			//get fieldoverrides for billing accounts - this includes basic fiels plus any fields defined in BillingAccountFilter__c field
			Set<SObjectField> fieldOverrides = BAMUserUtility.getBillingAccountFieldOverridesWithFilterFields(appMap);
            //get the billing accounts
			billingAccountMap = BillingAccountsSelector.newInstance(0, fieldOverrides).selectById(selectedBillingAccountIds, 
				new Set<Object>{BillingAccountsSelector.Options.FILTER_ACTIVE, BillingAccountsSelector.Options.FILTER_TYPE_NOT_IN_SBBA_CASH, BillingAccountsSelector.Options.FILTER_SOURCE_SYSTEM_NOT_IN_PEOPLE_SOFT});
        }

		//create a map of billing accounts keyedby App Id
        for(Id appId : appMap.keySet()) {
            if (billingAccountsKeyedByAppId.get(appId) == null) {
				billingAccountsKeyedByAppId.put(appId, new List<Billing_Account__c>());
			}
            List<Map<Object, Object>> appRoles = applicationRolesKeyedByAppId.get(appId);
            for(Map<Object, Object> objAppRole : appRoles) {
                List<Object> listLinkedEntities = (List<Object>) objAppRole.get(FIELD_SELECTED_ENTITIES);
                for(Object leId : listLinkedEntities) {
                    if (billingAccountMap.containsKey((Id)leId)) {
                        billingAccountsKeyedByAppId.get(appId).add(billingAccountMap.get((Id)leId));
                    }
                }
            }
        }

		for (Id appId : billingAccountsKeyedByAppId.keySet()) {
			Set<Id> existingBillingAccountIds = new Set<Id>();
			if (existingBillingAccountsKeyedByAppId.containsKey(appId)) {
				existingBillingAccountIds = existingBillingAccountsKeyedByAppId.get(appId);
			}
			//check if any billing account filter defined at application level
			if (String.isNotBlank(appMap.get(appId).BillingAccountFilter__c)) {
				//deserialise the json filter
				Map<String, Object> billingAccountFilterMap = (Map<String, Object>)JSON.deserializeUntyped(appMap.get(appId).BillingAccountFilter__c);
				//validate the billing accounts selected are satisfied with the  conditions set at application level
				List<Billing_Account__c> filteredAccounts = BAMUserUtility.getBillingAccountsByAppFilter(billingAccountsKeyedByAppId.get(appId), billingAccountFilterMap, existingBillingAccountIds);
				//throw an exception if filtered accounts not matched with the selected billing accounts
				if (filteredAccounts.size() != billingAccountsKeyedByAppId.get(appId).size()) {
					throw new AuraHandledException('Billing accounts selected are not valid as per the filter at application level');
				}
			}
		}
    }

    /**
     * Cancel any inflight pending requests for the selected contact
     */

    @AuraEnabled
    public static Map<String, Object> submitContactCancellationRequest(Id contactId) {
        System.debug('submitContactCancellationRequest');
        Map<String, Object> mapResults = new Map<String, Object>();

        try {
            // throws exceptions
            BAMIntegrationUtility.cancelExternalRequest(contactId);

            mapResults.put(FIELD_MESSAGE, 'The request to cancel was submitted successfully.');
            mapResults.put(FIELD_STATUS, STATUS_OK);
        } catch(Exception ex) {
            mapResults.put(FIELD_MESSAGE, 'An error occurred: ' + ex.getMessage());
            mapResults.put(FIELD_STATUS, STATUS_ERROR);
        }

        return mapResults;
    }

    private static String createUserUsingFlow(Id contactId) {
        // Calling user creation flow
        Object createdUserId;
        Object flowError;
        System.debug('--- PRE call create contact flow ---');

        Flow.Interview.BAM_Create_User createUserFlow;
        Map<String, Object> myMap = new Map<String, Object>();
        myMap.put('varContactId',contactId);
        createUserFlow = new Flow.Interview.BAM_Create_User(myMap);
        createUserFlow.start();
        System.debug('--- POST call create contact flow ---');

        createdUserId = createUserFlow.getVariableValue('varUserId');
        System.debug('--- User Id = ' + createdUserId);
        flowError = createUserFlow.getVariableValue('varError');
        System.debug('--- Error = ' + flowError);
        if(flowError != null && !String.isBlank((String) flowError)) {
            System.debug('***FLow Error');
            return (String) flowError;
        }

        return null;
        //return (Id) createdUserId;
    }

    private static Boolean doesUserExist(Id contactId)
    {
        // check user
        List<User> users = [SELECT Id FROM User where ContactId=:contactId];
        if(users.size() > 0) {
            return true;
        }
        return false;
    }



    @AuraEnabled
    public static Map<String, Object> deprovisionApplication(Id contactId, Id applicationId)
    {
        System.debug('BAM_onboardingCmpCC::deprovisioning application ' + applicationId + ' for contact ' + contactId);

        // get the Contact Application
        List<BAMContactApplication__c> listConApps = [
                SELECT Id, Status__c
                FROM BAMContactApplication__c
                WHERE Application__c =: applicationId
                AND Contact__c =: contactId
                LIMIT 1
        ];

        Map<String, Object> mapNoChange = new Map<String, Object>();

        if(listConApps.size() == 1)
        {
            BAMContactApplication__c conApp = listConApps[0];

            // security check
            UserRecordAccess contactAccess = getRecordAccess(contactId);
            UserRecordAccess conAppAccess = getRecordAccess(conApp.Id);

//            if(contactAccess == null || conAppAccess == null
//                || contactAccess.HasReadAccess == false || conAppAccess.HasEditAccess == false)
//            {
//                // EARLY OUT - security issue
//                mapNoChange.put(FIELD_MESSAGE, MSG_NO_ACCESS);
//                return mapNoChange;
//            }

            conApp.Pending_Delete__c = true;
            upsert conApp;

            // send to camunda
            Map<String, String> mapPayload = BAMProvision.provision(contactId);
            String sProvision = (String) mapPayload.get(BAMProvision.FIELD_DEPROVISION);
            if(sProvision != null && sProvision != '')
            {
                BAMProvisionCallout.processRequest(contactId, mapPayload);
            }

            // reload details (in case page does not reload)
            Map<String, Object> mapResults = loadInitialState(contactId);
            return mapResults;
        }
        else
        {
            mapNoChange.put(FIELD_MESSAGE, MSG_NO_ACCESS);
            return mapNoChange;
        }
    }

    private static void deleteContactApplications(Id contactId)
    {
        List<BAMContactApplication__c> contactApplications = [
                SELECT Id, Status__c,
                (
                        SELECT Id, Status__c, Pending_Delete__c
                        FROM ContactRoles__r
                )
                FROM BAMContactApplication__c
                WHERE Contact__c =: contactId
        ];

        List<BAMContactApplication__c> toDeleteContactApplications = new List<BAMContactApplication__c>();
        List<BAMContactApplication__c> toUpdateContactApplications = new List<BAMContactApplication__c>();

        // loop through to mark the ones which have only pending delete roles
        for(BAMContactApplication__c conApp:contactApplications)
        {
            if(conApp.Status__c == STATUS_PENDING)
            {
                // pending means there has been nothing provisioned yet
                if(conApp.ContactRoles__r.size() == 0)
                    toDeleteContactApplications.add(conApp);
            }
            else
            {
                Boolean hasActiveRole = false;
                for(BAMContactRole__c contactRole: conApp.ContactRoles__r)
                {
                    // if anything is NOT pending delete (ie, could be pending or active), keep this
                    if(!contactRole.Pending_Delete__c)
                        hasActiveRole = true;
                }

                if(!hasActiveRole)
                {
                    System.debug('BAMOnboardContact:: contact application for delete: ' + conApp);
                    conApp.Pending_Delete__c = true;
                    toUpdateContactApplications.add(conApp);
                }
            }
        }

        if(toUpdateContactApplications.size() > 0)
            update toUpdateContactApplications;
        if(toDeleteContactApplications.size() > 0)
            delete toDeleteContactApplications;

    }

    private static void deleteContactRoles(Id contactId, List<Map<Object, Object>> applicationRoles)
    {
        List<Id> toDelAppIds = new List<Id>();
        List<Id> toDelAppRoleIds = new List<Id>();
        for(Map<Object, Object> objAppRole: applicationRoles)
        {
            toDelAppIds.add((Id) objAppRole.get(FIELD_APPLICATION));
            toDelAppRoleIds.add((Id) objAppRole.get(FIELD_APPLICATION_ROLE));
        }

        if(toDelAppIds.size() > 0)
        {
            List <BAMContactRole__c> toDelContactRoles = [
                    SELECT Id, Pending_Delete__c, Status__c,
                            ContactApplication__r.Application__c, ApplicationRole__c, ContactApplication__r.Contact__c,
                    (
                            SELECT Id, Pending_Delete__c
                            FROM LinkedEntities__r
                    )
                    FROM BAMContactRole__c
                    WHERE ContactApplication__r.Contact__c =: contactId
                    AND ContactApplication__r.Application__c IN: toDelAppIds
                    AND ApplicationRole__c IN: toDelAppRoleIds
            ];

            // if not pending delete, it's a hard delete
            List<BAMContactRole__c> hardDeleteRoles = new List<BAMContactRole__c>();
            List<BAMContactRole__c> pendingDeleteRoles = new List<BAMContactRole__c>();
            for(BAMContactRole__c conRole:toDelContactRoles)
            {
                if(conRole.Status__c != STATUS_ACTIVE) {
                    hardDeleteRoles.add(conRole);
                }
                else
                {
                    conRole.Pending_Delete__c = true;
                    pendingDeleteRoles.add(conRole);
                }
            }
            if(hardDeleteRoles.size() > 0)
                delete hardDeleteRoles;
            if(pendingDeleteRoles.size() > 0)
                update pendingDeleteRoles;

            System.debug('hardDelete::' + hardDeleteRoles);
            System.debug('pendingDelete::' + pendingDeleteRoles);
        }

    }


    private static void upsertLinkedEntities(Id contactId, List<Map<Object, Object>> applicationRoles)
    {
        // we can only search by Application Role Ids, not Contact Id
        List<Id> appRoleIds = new List<Id>();
        for(Map<Object, Object> objAppRole:applicationRoles)
        {
            appRoleIds.add((Id) objAppRole.get(FIELD_APPLICATION_ROLE));
        }

        // get all ACTIVE contact roles, in case there are pending deletes
        List<BAMContactRole__c> contactRoles = [
                SELECT Id, ApplicationRole__c, Status__c, Pending_Delete__c,
                (
                        SELECT Id, BillingAccount__c
                        FROM LinkedEntities__r
                )
                FROM BAMContactRole__c
                WHERE ContactApplication__r.Contact__c =: contactId
                AND Pending_Delete__c = false
        ];


        System.debug('existing CRs:' + contactRoles.size());
        System.debug(contactRoles);
        // format the roles into a map, we assume that the previous function would have created all the necessary Contact-Roles
        Map<Id, Map<String, Object>> mapApplicationRoleIdsToContactRoleData = new Map<Id, Map<String, Object>>();
        for(BAMContactRole__c cr:contactRoles)
        {
            Map<String, Object> mapCRData = new Map<String, Object>();

            // extract the linked entity Ids for comparison
            Map<Id, Id> linkedEntityIdMappings = new Map<Id, Id>();
            for(BAMLinkedEntity__c le : cr.LinkedEntities__r)
            {
                linkedEntityIdMappings.put(le.BillingAccount__c, le.Id);
            }
            mapCRData.put('LinkedEntityMappings', linkedEntityIdMappings);
            mapCRData.put('ContactRole', cr);
            mapApplicationRoleIdsToContactRoleData.put(cr.ApplicationRole__c, mapCRData);
        }

        // loop through the entities to see which ones need to be created/deleted
        List<BAMLinkedEntity__c> toUpsertLinkedEntities = new List<BAMLinkedEntity__c>();
        List<BAMLinkedEntity__c> toDeleteEntities = new List<BAMLinkedEntity__c>();
        for(Map<Object, Object> objAppRole:applicationRoles)
        {
            Id appRoleId = (Id)objAppRole.get(FIELD_APPLICATION_ROLE);

            // cast the list of Billing Account/Linked Entity Ids from UI
            List<Object> listLinkedEntities = (List<Object>) objAppRole.get(FIELD_SELECTED_ENTITIES);

            // format it as a SET to use the set functions
            Set<Id> setLinkedEntityIds = new Set<Id>();
            for(Object leId : listLinkedEntities)
            {
                setLinkedEntityIds.add((Id) leId);
            }

            // find the existing contact role data
            Map<String, Object> mapCRData = mapApplicationRoleIdsToContactRoleData.get(appRoleId);
            BAMContactRole__c existingContactRole = (BAMContactRole__c) mapCRData.get('ContactRole');
            Id existingCRId = existingContactRole.Id;

            Map<Id, Id> existingLinkedIdMappings = (Map<Id, Id>)mapCRData.get('LinkedEntityMappings');

            // upsert the linked entities that are being set
            // make sure that if any of them are pending delete that we remove pending delete
            for(Id linkedEntityEntityId : setLinkedEntityIds) {
                BAMLinkedEntity__c linkedEntity = new BAMLinkedEntity__c();
                if(existingLinkedIdMappings.get(linkedEntityEntityId) != null) {
                    linkedEntity.Id = existingLinkedIdMappings.get(linkedEntityEntityId);
                } else {
                    linkedEntity.ContactRole__c = existingCRId;
                }
                linkedEntity.BillingAccount__c = (Id)linkedEntityEntityId;
                linkedEntity.Pending_Delete__c = false;
                toUpsertLinkedEntities.add(linkedEntity);
            }

            // the missing ones are the ones to delete
            Set<Id> toDelIds = existingLinkedIdMappings.keySet().clone();
            toDelIds.removeAll(setLinkedEntityIds);
            if(toDelIds.size() > 0) {
                List<BAMLinkedEntity__c> toDelLEs = [
                        SELECT Id
                        FROM BAMLinkedEntity__c
                        WHERE ContactRole__c =: existingCRId
                        AND BillingAccount__c IN:toDelIds
                ];

                //System.debug('DEL query :' + existingCRId + ', ' + toDelIds);
                //System.debug('toDelLEs:' + toDelLEs);

                for(BAMLinkedEntity__c delLE:toDelLEs) {
                    delLE.Pending_Delete__c = true;
                }

                toDeleteEntities.addAll(toDelLEs);
            }
        }

        //System.debug('new linked entities:' + toCreateLinkedEntities);
        if(toUpsertLinkedEntities.size() > 0)
        {
            upsert toUpsertLinkedEntities;
            System.debug('UPSERTED Linked Entities = ' + toUpsertLinkedEntities);
        }

        if(toDeleteEntities.size() > 0)
        {
            update toDeleteEntities;
            System.debug('DELETED Linked Entities = ' + toDeleteEntities);
        }
    }

    private static void upsertContactRoles(Id contactId, List<Map<Object, Object>> applicationRoles)
    {
        System.debug('Application roles = ' + applicationRoles);

        // extract the ids
        List<Id> appRoleIds = new List<Id>();
        for(Map<Object, Object> objAppRole:applicationRoles)
        {
            appRoleIds.add((Id) objAppRole.get(FIELD_APPLICATION_ROLE));
        }

        // get the existing ones, so as not to duplicate
        List<BAMContactRole__c> existingContactRoles = [
                SELECT Id, ApplicationRole__c, Pending_Delete__c
                FROM BAMContactRole__c
                WHERE ContactApplication__r.Contact__c =: contactId
        ];
        //AND Pending_Delete__c = false

        // store only the existing ids of the APPLICATION ROLE for comparison
        Map<Id, BAMContactRole__c> existingContactRolesByAppRole = new Map<Id, BAMContactRole__c>();
        for(BAMContactRole__c existingCR : existingContactRoles) {
            existingContactRolesByAppRole.put(existingCR.ApplicationRole__c, existingCR);
        }
        System.debug('Existing CRs:' + existingContactRoles);
        System.debug('Existing existingContactRolesByAppRole:' + existingContactRolesByAppRole);

        // get all the Contact Applications, assume they have already been created
        List<BAMContactApplication__c> contactApplications = [
                SELECT Id, Application__c
                FROM BAMContactApplication__c
                WHERE Contact__c =: contactId
        ];

        // find the set to create
        List<BAMContactRole__c> toUpsertContactRoles = new List<BAMContactRole__c>();
        for(Map<Object, Object> objAppRole: applicationRoles) {
            Id appRoleId = (Id) objAppRole.get(FIELD_APPLICATION_ROLE);
            if(!existingContactRolesByAppRole.keySet().contains(appRoleId)) {
                BAMContactRole__c contactRole = new BAMContactRole__c();
                contactRole.ApplicationRole__c = appRoleId;
                contactRole.Status__c = STATUS_PENDING;

                // find the contact application
                Id applicationId = (Id) objAppRole.get(FIELD_APPLICATION);
                BAMContactApplication__c contactApplication = findContactApplicationByApplicationId(contactApplications, applicationId);

                System.debug('upsert contact role: role id = ' + appRoleId + ', appId = ' + applicationId);
                if(contactApplication != null) {
                    contactRole.ContactApplication__c = contactApplication.Id;
                    toUpsertContactRoles.add(contactRole);
                }
            } else if(existingContactRolesByAppRole.get(appRoleId).Pending_Delete__c) {
                BAMContactRole__c contactRole = new BAMContactRole__c();
                contactRole.Id = existingContactRolesByAppRole.get(appRoleId).Id;
                contactRole.Pending_Delete__c = false;
                toUpsertContactRoles.add(contactRole);
            }
        }

        if(toUpsertContactRoles.size() > 0)
        {
            upsert toUpsertContactRoles;
            System.debug('INSERTED Contact Roles = ' + toUpsertContactRoles);
        }

    }


    private static BAMContactApplication__c findContactApplicationByApplicationId(List<BAMContactApplication__c> contactApplications, Id applicationId)
    {
        for(BAMContactApplication__c ca: contactApplications)
        {
            if(ca.Application__c == applicationId)
                return ca;
        }
        return null;
    }

    private static void upsertContactApplications(Id contactId, List<Id> applicationIds,Boolean BSPCanViewAllConsignments)
    {
        System.debug('Application Ids = ' + applicationIds);

        // get all the existing Contact Applications
        List<BAMContactApplication__c> existingContactApplications = [
                SELECT Id, Application__c
                FROM BAMContactApplication__c
                WHERE Contact__c =: contactId
        ];
        // store the ids for comparison
        List<Id> existingIds = new List<Id>();
        for(BAMContactApplication__c existingApp: existingContactApplications)
        {
            existingIds.add(existingApp.Application__c);
        }
        System.debug('existing CA Ids = ' + existingIds);

        // find the set of contact-applications which need to be created.
        List<BAMContactApplication__c> toCreateContactApplications = new List<BAMContactApplication__c>();
        for(Id requiredId:applicationIds)
        {
            if(existingIds.indexOf(requiredId) < 0)
            {
                BAMContactApplication__c contactApplication = new BAMContactApplication__c();
                contactApplication.Application__c = requiredId;
                contactApplication.Contact__c = contactId;
                contactApplication.Status__c = STATUS_PENDING;
				contactApplication.BSPCanViewAllConsignments__c = BSPCanViewAllConsignments;
                toCreateContactApplications.add(contactApplication);

                System.debug('Inserting new CA: ' + contactApplication);
            }
        }
        if(toCreateContactApplications.size() > 0)
        {
            insert toCreateContactApplications;
            System.debug('INSERTED Contact Applications= ' + toCreateContactApplications);
        }

    }

}