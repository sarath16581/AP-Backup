/***
 * @description Controller class for BAMUserPage LWC component
 * @author Sameed Khan
 * @date 2019-04-11
 * @group Merchant Portal
 * @changelog
 * 2019-10-21  hasantha.liyanage@auspost.com.au : added retrieveSuperAdmins method
 * 2020-05-25 - Nathan Franklin - added additional fields to soql
 * 2021-01-11 - Swati Mogadala - REQ2279110 Filter out Peoplesoft accounts from list of billing accounts
 */
public with sharing class BAMUserController {
    static Integer AUTO_INCREMENT_ID = 0;
    public static String NO_ACCESS_IDENTIFIER_STRING = '_no-access';

    private static Integer getAutoIncId() {
        return AUTO_INCREMENT_ID++;
    }

    public static List<String> INVALID_BILLING_ACCOUNT_TYPES = new List<String>{
        'SBBA', 'CASH'
    };

    public class BAMUserException extends Exception{}

    @AuraEnabled
    public static String retrieveMerchantPortalCommunityURL(){
        try {
            String communityId = Network.getNetworkId();
            String myCommunityUrl = ConnectApi.Communities.getCommunity(communityId).siteUrl;
            return myCommunityUrl;
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

    @AuraEnabled
    public static string retrieveContactData(String contactId){
        try {
            return JSON.serialize(getContact((Id)contactId));
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

    @AuraEnabled
    public static string retrieveExistingAccessAndRolesWithLinkedEntitiesForContact(String contactId){
        try {
            return JSON.serialize(getExistingAccessAndRolesWithLinkedEntitiesForContact((Id)contactId));
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

    @AuraEnabled
    public static string retrieveActiveAccessAndRolesWithLinkedEntitiesForContact(String contactId){
        try {
            return JSON.serialize(getActiveAccessAndRolesWithLinkedEntitiesForContact((Id)contactId));
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

    @AuraEnabled
    public static string retrieveUserInformation(){
        try {
            return JSON.serialize(getUserInformation());
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

    @AuraEnabled
    public static string retrieveContactApplicationsWithLatestExternalOnboardingRequests(String contactId){
        try {
            return JSON.serialize(getContactApplicationsWithLatestExternalOnboardingRequests(contactId));
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

    /*
        wrapper for results of nested queries to be returned to the client when there are too many records in the result of the nested query
        currently this is only used by "getActiveAccessAndRolesWithLinkedEntitiesForContact" and "getExistingAccessAndRolesWithLinkedEntitiesForContact"
        methods becuase of of the possible large number of linked entity records than can exist for a role. However the wrapper is made generic enough so 
        that it can be used for other parent child query relations.
     */
    public class BAMDataWrapper {
        public Object record;
        public List<Object> childList = new List<Object>();
    }

    @AuraEnabled
    public static string retrieveActiveContactApplicationsWithLatestExternalOnboardingRequests(String contactId){
        try {
            return JSON.serialize(getActiveContactApplicationsWithLatestExternalOnboardingRequests(contactId));
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

	@AuraEnabled
	public static string retrieveAplicationData(Id orgId){
		try {
			ApplicationDataWrapper appData = new ApplicationDataWrapper();
			List<BAMApplication__c> appWithRoles = BAMUserUtility.getApplicationRolesForAccount(orgId);
			//get all the billing accounts for the organisation
			List<Billing_Account__c> billingAccounts = getBillingAccountsByOrgId(orgId);
			appData.applicationsWithRoles = appWithRoles;
			appData.billingAccounts = billingAccounts;
			appData.appBillingAccountDataWrapper = BAMUserUtility.getAppBillingAccountDataWrapper(appWithRoles, billingAccounts);
			return JSON.serialize(appData);
		} catch (Exception er) {
			throw new AuraHandledException(er.getMessage());
		}
	}

    /**
     * help to list super admins section on the my access page
     *
     * @param orgId
     *
     * @return
     */
    @AuraEnabled
    public static string retrieveSuperAdmins(Id orgId){
        try {
            List<AdminDataWrapper> superAdmins = new List<AdminDataWrapper>();
            for(BAMContactRole__c bamContactRole : getSuperAdminsByOrgId(orgId)) {
                AdminDataWrapper admin = new AdminDataWrapper();
                admin.bamContactRole = bamContactRole;
                admin.isCurrentUser = bamContactRole.ContactApplication__r.Contact__c == getUserInformation().loggedInUserContactId;
                superAdmins.add(admin);
            }

            return JSON.serialize(superAdmins);
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

    @TestVisible
    private class ApplicationDataWrapper {
        @TestVisible
        List<BAMApplication__c> applicationsWithRoles {get; set;}
		@TestVisible
        List<Billing_Account__c> billingAccounts {get; set;}
		@TestVisible
		List<BAMUserUtility.ApplicationBillingAccountDataWrapper> appBillingAccountDataWrapper {get; set;}
    }

    @testVisible
    private class AdminDataWrapper {
        @testVisible
        BAMContactRole__c bamContactRole {get; set;}
        @testVisible
        Boolean isCurrentUser {get; set;}
    }

    @AuraEnabled
    public static Boolean savePrimaryBillingAccount(String primaryBillingAccountId, String contactId) {
        try {
            Contact con = [SELECT Id, BillingAccount__c FROM Contact WHERE ID =: contactId];
            con.BillingAccount__c = primaryBillingAccountId;
            update con;
            return true;
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }
    
    @testVisible
    private class ContactDataWrapper {
        @testVisible
        String Id {get;set;}
        @testVisible
        String FirstName {get; set;}
        @testVisible
        String LastName {get; set;}
        @testVisible
        String Email {get; set;}
        @testVisible
        String orgId {get; set;}
        @testVisible
        String primaryBillingAccountId {get; set;}
    }

    @AuraEnabled
    public static String saveAccessChanges(String contactDataJSON, List<Map<String, Object>> pageState){

        try {
            /*  The following validations are performed in this method

                - check that the logged in user has access to bam
                - check that the email is editable (i.e there is no c number and there are no pending external onboarding requests)
                - check that the contact exists within the logged in users organization
                - check that the contact being edited belongs to the right org
                - check that the contact they are editing has an 'Active' Status__c 
            */

            // CREATE CONTACT RECORD FOR NEWLY CREATED USER
            Id userId  = UserInfo.getUserId();
            User loggedInUser = [SELECT Id, Name, ContactId, Contact.OwnerId, Contact.AccountId FROM User WHERE Id =: userId];

            // The owner of a newly created contact must be an active internal user
            // This user must also be a member of the community and visible to the currently logged in user
            Id owner = getContactOwnerId();

            Id orgId = loggedInUser.Contact.AccountId;
            ContactDataWrapper conData = (ContactDataWrapper)JSON.deserialize(contactDataJSON, ContactDataWrapper.class);
            
            // set up app map used for validation later
            Map<Id,BAMApplication__c> appMap = new Map<Id,BAMApplication__c>(BAMUserUtility.getApplicationRolesForAccount(orgId));
            // set up app role map for validation later
            Map<String, BAMApplicationRole__c> appRoleMapKeyedByAppIdandAppRoleId = new  Map<String, BAMApplicationRole__c>();

            for (BAMApplication__c app : BAMUserUtility.getApplicationRolesForAccount(orgId)) {
                for (BAMApplicationRole__c appRole: app.ApplicationRoles__r) {
                    String key = app.Id + '_' + appRole.Id;
                    appRoleMapKeyedByAppIdandAppRoleId.put(key, appRole);
                }
            }

            String contactId = conData.Id;
            Contact contactRecord;

            // check that the logged in user has access to bam
            List<BAMContactRole__c> bamConRoleList = [
                SELECT Id, ContactApplication__c, ContactApplication__r.Status__c, ContactApplication__r.Contact__c, ContactApplication__r.Application__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Status__c, Status__c 
                FROM BAMContactRole__c
                WHERE ContactApplication__r.Application__r.AppKey__c = 'BAM'
                AND ContactApplication__r.Contact__c = :loggedInUser.contactId
                AND ContactApplication__r.Application__r.Status__c = 'Active'
                AND ContactApplication__r.Status__c = 'Active'
                AND Status__c = 'Active'
            ];
            Boolean isBAMUser = bamConRoleList.size() > 0;
            Boolean hasPendingChanges = false;
            String bamConAppId;
            if (!isBAMUser) {
                throw new BAMUserException('You do not have access to Access Management');
            } else {
                // populate bamConAppId which will be used later to check that the logged in user is not trying to remove their own access to bam
                bamConAppId = bamConRoleList[0].ContactApplication__c;
            }

            // If the Id is not populated then a contact record must be created as this new contact is being invited to have access
            Boolean isNewContact = String.isBlank(conData.Id);
            if(isNewContact) { // create the new contact record for the new user being created
            // perform validations for newly created contact
                Boolean isAddingBSPAccess = false;
                Boolean hasAtLeastOneRoleSelected = false;
                for (Map<String,Object> appState: pageState) {
                    String appIdStr = (String)appState.get('Id');
                    Id appId = (Id) appIdStr;
                    String selectedAppRoleId = (String)appState.get('selectedAppRoleId');
                    if (selectedAppRoleId != NO_ACCESS_IDENTIFIER_STRING) hasAtLeastOneRoleSelected = true;
                    if (appMap.get(appId).AppKey__c == 'BSP' && selectedAppRoleId != NO_ACCESS_IDENTIFIER_STRING) isAddingBSPAccess = true;
                }
                if (!hasAtLeastOneRoleSelected) {
                    throw new BAMUserException('Select application for the new use'); // a contact that is being newly created must have at least one role selected
                }
                if(conData.FirstName == null || conData.LastName == null || conData.Email == null || (isAddingBSPAccess == true && conData.primaryBillingAccountId == null)) {
                    throw new BAMUserException('Complete all required fields'); // a contact that is being newly created must have all these fields populated
                }
                // validations have passed hence create a contact record
                contactRecord = new Contact(
                    AccountId=orgId,
                    FirstName=conData.FirstName,
                    LastName=conData.LastName,
                    Email=conData.Email,
                    OwnerId=owner,
                    BillingAccount__c=conData.primaryBillingAccountId,
                    OID_ID__c=null,
                    Record_Maintainer__c='BAM'
                ); 
            } else {
                contactRecord = getContact(contactId);
                // validate that the contact exists within the logged in users organization 
                if (contactRecord == null) {
                    throw new BAMUserException('The contact you are editing could not be found within your organization.');
                }
                // validate that the contact being edited belongs to the right org
                if (contactRecord.accountId != orgId) {
                    throw new BAMUserException('You do not have access to the user you are trying to edit.');
                } 
                // validate that the contact they are editing has an 'Active' Status__c 
                if (contactRecord.Status__c != 'Active') {
                    throw new BAMUserException('The user you are trying to edit has been deactivated.');
                }
                // if they are tring to edit the email address check that the email is editable(i.e no c-num and no pending external requests)
                hasPendingChanges = hasPendingRequests(contactId);
            }
    
            // Perform duplicate checks
            if(contactRecord.OID_ID__c == null && !hasPendingChanges) {// no cnum and no pending external requests
                // LDAP check
                if(BAMValidationService.checkIfDulicateCnumberExistsInOrg(orgId, conData.Email)) {
                    throw new BAMUserException('Email address has already been registered');
                }
                // Check for Duplicates
                if(BAMValidationService.checkIfDuplicateContactExistsInOrg(orgId, conData.FirstName, conData.LastName, conData.Email, contactId)) {
                    throw new BAMUserException('User\'s details have already been registered');
                }
            }

            // We perform the DML operations here since the LDAP check makes a callout
            if(isNewContact) { // If a new user is being created, it's contact record must be inserted
                insert contactRecord;
                // assign the newly created users id to the contactId variable as this ithe the contact who'se context will be used to generate and query all subsequent records
                contactId = contactRecord.Id;  
            } else { // If its an existing user whose email has been changed we update their email address if it's changed
                if (contactRecord.Email != conData.Email) { // if email has been updated in UI
                    if (contactRecord.OID_ID__c == null && !hasPendingChanges) { // and there is no c-number for the contact and no pending changes, they are allowed to update the email
                        contactRecord.Email = conData.Email;
                        update contactRecord;
                    } else {// otherwise we throw an error to inform them that they can't update the email adress
                        throw new BAMUserException('You cannot update the email address of an user who currently has pending requests or a c-number.');
                    }
                }
            }

            // CREATE USER RECORD FOR NEWLY CREATED OR EXISTING CONTACT(IF USER DOESN'T EXIST FOR EXITING CONTACT)
            // check if user exists for contact being created or edited
            List<User> contextContactUserList = [SELECT Id, Name, ContactId FROM User WHERE ContactId =: contactId];
            // if the contact doesn't have a user we need to call the user creation flow to create it
            if (contextContactUserList.size() == 0) {
                Id createdUserId = createUserUsingFlow(contactId);
            }

            // CREATE/UPDATE RECORDS THAT DEFINE THE USER'S LEVEL OF ACCESS
            upsertUsersAccess(loggedInUser, contactRecord, appMap, appRoleMapKeyedByAppIdandAppRoleId, pageState);
            
            // create provisioning and deprovisiong pay loads and call the provisioning callout with it
            Map<String, String> mapPayload = BAMProvision.provision(contactId);
            BAMProvisionCallout.processRequest(contactId, mapPayload);
            
            String deprovisionPayload = mapPayload.get(BAMProvision.FIELD_DEPROVISION);
            String provisionPayload = mapPayload.get(BAMprovision.FIELD_PROVISION);

            Boolean isActionRequired = !(deprovisionPayload == null && provisionPayload == null);
            String returnMessage;

            // reset CSSO Error fields if another porvisioning request is being sent
            if (isActionRequired)  {
                contactRecord.BAMCSSOError__c = false;
                contactRecord.BAMCSSOErrorMessage__c = '';
                update contactRecord;
            }

            // assign appropriate message to the return value for successful execution
            // if the contact does not have a c-number and no new provision or deprovision request was submitted we say 'Request submitted' otherwise we say 'changes saved'
            if (contactRecord.OID_ID__c == null) {
                returnMessage  = 'Request submitted';
            } else { 
                if(isActionRequired) {
                    returnMessage = 'Request submitted';
                } else {
                    returnMessage = 'Changes saved';
                }
            }

            AccessChangeResultsWrapper accessSaveResult = new AccessChangeResultsWrapper();
            accessSaveResult.success = true;
            accessSaveResult.contactId = contactId;
            accessSaveResult.message = returnMessage;
            return JSON.serialize(accessSaveResult);

        } catch (Exception er) {
            System.debug(er);
            AuraHandledException auraError = new AuraHandledException(er.getMessage());
            auraError.setMessage(er.getMessage());
            throw auraError;
        }
    }


    // This method iterates through the pageState List and determines which junction recoreds (BAMContactApplication__c, BAMContactRole__c, BAMLinkedEntity__c)  need to be inserted, updated, and deleted
    private static void upsertUsersAccess(User loggedInUser, Contact contactData, Map<Id,BAMApplication__c> appMap, Map<String, BAMApplicationRole__c> appRoleMapKeyedByAppIdandAppRoleId, List<Map<String,Object>> pageState) {
        /*
        the pageState contains the data about the applications belonging to the organisation, and the level of access the user has to eache app(their role, selected billing accouts, etc.)
        Each element of the list is a Map with the following keys:

        {
            // KEYS THAT ARE PRESENT IN DATA THAT COMES BACK FROM CLIENT

            ... application, // properties of the BAMApplication__c sobject record
            isPending, // boolean that is set to "true" pending provisioning or deprovisiong request for this app
            hasError, // boolean that is set to "true" if the last provisioning or deprovisiong request came back with an error
            errorMessage, // error message from recently unsuccessful provisioning or deprovisiong request
            rolePickerOptions, // the options for the role picker for this application. This is basically, The child Application role records for the application with the _no-access option appended at the end
            selectedAppRole, // currently seleceted Applicaiton role fore the application
            selectedAppRoleId, // Id of the selected Application role record, if no role is selected, it defaults to "_no-access"
            isRoleSelected, // boolean that is true if a role is currently selected for  the application
            showBillingAccount, // boolean that is set to true if the currently selected application role allows billing accounts to be selected
            selectedRoleOption, // the role option that is currently selected (this is for rendeirng purposes as the roleOptions property is waht is used to render the role selection button group)
            selectedBillingAccountIds, // currently selected billing account Ids
            selectedBillingAccounts, // the currently selected billing account options (used to render the seleceted billing account list in the juicy cart box)
            allowBSPConsignmentSearch, // value for the "BSP Allow Consignment Serarch" checkbox
            isBSPWithAccess, // boolean set to true if the application is BSP and its access has a role selected

            // KEYS THAT WE INSERT DURING THE COURSE OF THIS FUNCTION

            hasAccessChanges, // boolean to indicate if changes were made to records that indicate that the access to that application has changed in this transaction. This is used later to ensure that no changes are made to applications that already have pending changes from another transaction
            conRoleId, // the Id of the Contact Role record that for the Contact Application relating to this application. This Contact Role Id is later used to create/update Linked Entity records
            newConRoleIdentifier, // an auto-increment identifier number generated locally to identify the newly created contact role records. This is used later to retrieve the Id in database after the role records are inserted to database.
        } 
        */

        // Set up maps of records that we wil later use to look up data relating to the user's current level of access 
        Map<String, BAMContactApplication__c> conAppMapByAppId = new Map<String, BAMContactApplication__c>();
        Map<String, List<BAMContactRole__c>> conRoleMapByConAppId = new Map<String, List<BAMContactRole__c>>();
        Map<String, BAMLinkedEntity__c> linkedEntityMapByConRoleAndBillingAccId = new Map<String, BAMLinkedEntity__c>();
        Map<Id, Set<Id>> billingAccountsMapKeyedByConRoleId = new Map<Id, Set<Id>>();
        
        // query the contact applications with their letest external onboarding request records and populate the conAppMapByAppId
        // we get the letest external onboarding request records as we later need to determine which application has pending changes
        for(BAMContactApplication__c conApp: getContactApplicationsWithLatestExternalOnboardingRequests(contactData.Id)) {
            conAppMapByAppId.put(conApp.Application__c, conApp);
        }
        
        // set up lists for bulk updates and inserts later
        List<BAMContactApplication__c> conAppsToUpdate = new List<BAMContactApplication__c>();
        List<BAMContactApplication__c> newConApps = new List<BAMContactApplication__c>();

        // first pass to to determine which contact aps need to be added or removed
        // In the first fass through the pageState list, we iterate through each app and determine whether the app requires new access or it needs the current access removed or if there are no changes needed
        // If an app requires new access we need to create a new Contact Applicagtion record created that links the Contact to the Application that they are being granted access for.
        // if an app needs its access removed, we mark the Pending_Delete__c flag on the relevant ontact application record.
        for (Map<String,Object> appState: pageState) {

            String appIdStr = (String)appState.get('Id');
            Id appId = (Id) appIdStr;
            String selectedAppRoleId = (String)appState.get('selectedAppRoleId');

            // look up the extiting contact application record for this application 
            BAMContactApplication__c existingConApp = conAppMapByAppId.get(appIdStr);
            
            // check if page has no access but an contact application exists for the app. If so, it's a deprovision request 
            if (selectedAppRoleId == NO_ACCESS_IDENTIFIER_STRING && existingConApp != null) {
                //validate logged in user isn't trying to remove their own access to BAM
                if (loggedInUser.ContactId == contactData.Id && appMap.get(appId).AppKey__c == 'BAM') {
                    throw new BAMUserException('You can\'t remove your own access');
                }
                // If the existingConApp is not marked for deletion, set the Pending_Delete__c to true.
                if (existingConApp.Pending_Delete__c != true) {
                    existingConApp.Pending_Delete__c = true;
                    conAppsToUpdate.add(existingConApp);
                    appState.put('hasAccessChanges', true); // flag the application has changes to it's junction records in this transaction
                }
            } else if (selectedAppRoleId != NO_ACCESS_IDENTIFIER_STRING && existingConApp == null) { // check if page has app access and existing access is null, if so a new contact application needs to be created
                Boolean allowBSPConsignmentSearch = (Boolean) appState.get('allowBSPConsignmentSearch');
                if (appMap.get(appId).AppKey__c == 'BSP') { // If BSP, add contact application with BSPCanViewAllConsignments__c flag, otherwise, this flag is not needed
                    newConApps.add(new BAMContactApplication__c(Contact__c=contactData.Id, Application__c = appId, BSPCanViewAllConsignments__c=allowBSPConsignmentSearch));
                } else {
                    newConApps.add(new BAMContactApplication__c(Contact__c=contactData.Id, Application__c = appId));
                }
                appState.put('hasAccessChanges', true); // flag the application has changes to it's junction records in this transaction
            }
            // check if BSP, if so update the BSPCanViewAllConsignments__c if necessary
            if(existingConApp != null && appMap.get(appId).AppKey__c == 'BSP'){
                Boolean allowBSPConsignmentSearch = (Boolean) appState.get('allowBSPConsignmentSearch');
                if (existingConApp.BSPCanViewAllConsignments__c != allowBSPConsignmentSearch) {
                    existingConApp.BSPCanViewAllConsignments__c = allowBSPConsignmentSearch;
                    conAppsToUpdate.add(existingConApp);
                    appState.put('hasAccessChanges', true); // flag the application has changes to it's junction records in this transaction
                }
            }
        }

        // dml operations for contact application records
        update conAppsToUpdate;
        insert newConApps;

        // query contact application records again since the contact application records were recently updated 
        for(BAMContactApplication__c conApp: getContactApplicationsWithLatestExternalOnboardingRequests(contactData.Id)) {
            conAppMapByAppId.put(conApp.Application__c, conApp);
        }

        // set up a set of all the relevant contact roles for this contact which will later be used to query the relevant linked entity records
        Set<Id> conRoleIdSet = new Set<Id>();

        // set up contact role map for reconciling changes to contact role records
        for(BAMContactRole__c conRole: getAllContactRolesForContact(contactData.Id)) {
            conRoleIdSet.add(conRole.Id);
            // set up conRoleMapByConAppId
            String conRoleMapKey = conRole.ContactApplication__c;
            if (conRoleMapByConAppId.get(conRoleMapKey) == null) conRoleMapByConAppId.put(conRoleMapKey, new List<BAMContactRole__c>());
            List<BAMContactRole__c> conRoleList = conRoleMapByConAppId.get(conRoleMapKey);
            conRoleList.add(conRole);
            // since it's possible to have multiple contact role records for each contact application record, we store a list of contact role records keyed by the con app id
            conRoleMapByConAppId.put(conRoleMapKey, conRoleList);
        }

        // set up lists and for bulk updates, deletes and inserts later
        List<BAMContactRole__c> conRolesToUpdate = new List<BAMContactRole__c>();
        List<BAMContactRole__c> conRolesToDelete = new List<BAMContactRole__c>();
        Map<Integer,BAMContactRole__c> newConRolesMap = new Map<Integer,BAMContactRole__c>(); // we use a map for the insertionas since we later need to insert child linked entity records and we need to relate the local identifires to the salesfroce Ids later
        

        // second pass to to determine which contact roles need to be added or removed
        // In this iteration we determine which apps need new role records created, deleted or updated. the following are considerations for when we have exisint role records  for the relevant contact applications
        // 1. When switching roles, if a pending record already exists, use that record and update the role to the new requested role
        // 2. When switching roles, if an Active role already exists for the same role name, rather than creating a new pending record or update an existing pending record, the Active role record should be used instead of a new one (Overcome the duplicate role error).. Any pending role records should be removed in this scenario.
        for (Map<String,Object> appState: pageState) {
            String selectedAppRoleId = (String)appState.get('selectedAppRoleId');
            // look up the extiting contact application record for this application 
            BAMContactApplication__c existingConApp = conAppMapByAppId.get((String)appState.get('Id'));
            
            if (existingConApp == null) continue; // no contact application record hence no role can be added
            
            List<BAMContactRole__c> existingConRoleList = conRoleMapByConAppId.get(existingConApp.Id);
            if (selectedAppRoleId != NO_ACCESS_IDENTIFIER_STRING) { // there is a selected role in page state (If the selected app role in page state is NO_ACCESS_IDENTIFIER_STRING and there are existing roles in state, it doesnt matter as the first pass through the page state will have marked the contact application as pending delete)
                if (existingConRoleList == null) { // no role record exist in db hence, a new role needs to be added
                    Integer newConRoleIdentifier = getAutoIncId();
                    newConRolesMap.put(newConRoleIdentifier, new BAMContactRole__c(ContactApplication__c = existingConApp.Id, ApplicationRole__c=(Id)selectedAppRoleId, Status__c = 'Pending'));
                    appState.put('newConRoleIdentifier', newConRoleIdentifier); // A new contact role record was created so we store its local identifier on the app state so that when creating its children linked entity records, we can retriece its salesforce Id from the newConRolesMap.
                    appState.put('hasAccessChanges', true); // flag the application has changes to it's junction records in this transaction
                } else { // role record exists already
                    List<BAMContactRole__c> activeConRoles = filterContactRolesByStatus(existingConRoleList, 'Active');
                    List<BAMContactRole__c> pendingConRoles = filterContactRolesByStatus(existingConRoleList, 'Pending');

                    BAMContactRole__c existingActiveContactRole;
                    BAMContactRole__c latestPendingContactRole;

                    if (!pendingConRoles.isEmpty()) {
                        latestPendingContactRole = pendingConRoles[0]; // we order the contact roles by created date in the query so the first one is the latest
                        // if more than one pending contact role exists we delete all but the lates since they are invalid data
                        if (pendingConRoles.size() > 1) {
                            for (Integer i = 1; i < pendingConRoles.size(); i++) {
                                conRolesToDelete.add(pendingConRoles[i]);
                            }
                        }
                    }
                    if (!activeConRoles.isEmpty()) existingActiveContactRole = activeConRoles[0];

                    /*
                        Check if an the existing active role matches the selectedAppRoleId
                            If so 
                                - reset pending delete flag if needed
                                - delete any remaining pending con role record
                        Otherwise, check if the latest existing Pending Contact Role record matches the selectedAppRoleId
                            If so 
                                - reset pending delete flag if needed
                        Otherwise, no existing role record (neither Active nor Pending) matches the selectedAppRoleId
                            - mark the current Active role for deletion if exists
                            - check if there is an existing pending role record
                            If so
                                - update the app role lookup field to point to the selectedAppRoleId 
                            If not (the following logic is necessary since the look up fields on an Active role record can't be changed as it is used by the API)
                                - create new con role record that points to correct app role record
                     */

                    //if role sent from UI is same as the existing Active role
                    if (existingActiveContactRole != null && existingActiveContactRole.ApplicationRole__c == selectedAppRoleId) {
                        // check if active role is pending delete if so remove the flag
                        if (existingActiveContactRole.Pending_Delete__c) {
                            existingActiveContactRole.Pending_Delete__c = false;
                            conRolesToUpdate.add(existingActiveContactRole);
                            appState.put('hasAccessChanges', true); // flag the application has changes to it's junction records in this transaction
                            // remove latest pending roles in this case
                            if(latestPendingContactRole != null) conRolesToDelete.add(latestPendingContactRole);
                        }
                        appState.put('conRoleId', existingActiveContactRole.Id); // we store the contact role Id on the app state so that it can later be used to create/remove linked entity records for that role
                    // if role sent from UI is same as an existing latest Pending role
                    } else if (latestPendingContactRole != null && latestPendingContactRole.ApplicationRole__c == selectedAppRoleId) {
                        if (latestPendingContactRole.Pending_Delete__c) {
                            latestPendingContactRole.Pending_Delete__c = false;
                            conRolesToUpdate.add(latestPendingContactRole);
                            appState.put('hasAccessChanges', true); // flag the application has changes to it's junction records in this transaction
                        }
                        appState.put('conRoleId', latestPendingContactRole.Id); // we store the contact role Id on the app state so that it can later be used to create/remove linked entity records for that role
                    } else { // this branch is when neither the latestPendingContactRole or existingActiveContactRole are the selected app role
                        // in this scenario we mark pending delete on the active record and remove any existing pending record and start the linked entity population over again.
                        if(existingActiveContactRole != null) { //mark the existing active role as pending delete
                            existingActiveContactRole.Pending_Delete__c = true;
                            conRolesToUpdate.add(existingActiveContactRole);
                        }
                        if(latestPendingContactRole != null) { //delete the latest pending role
                            conRolesToDelete.add(latestPendingContactRole);
                        }

                        //if(latestPendingContactRole != null) { // if a pending role exists in db, reuse it by pointing it to a new app role record
                        //    latestPendingContactRole.Pending_Delete__c = false; // reset pending delete flag
                        //    // update the app role lookup field to point to the selectedAppRoleId
                        //    latestPendingContactRole.ApplicationRole__c = selectedAppRoleId;
                        //    conRolesToUpdate.add(latestPendingContactRole);
                        //    appState.put('conRoleId', latestPendingContactRole.Id);
                        //} else { // if a pending role doesnt exists in db create a new role record

                        Integer newConRoleIdentifier = getAutoIncId();
                        newConRolesMap.put(newConRoleIdentifier, new BAMContactRole__c(ContactApplication__c = existingConApp.Id, ApplicationRole__c=(Id)selectedAppRoleId));
                        appState.put('newConRoleIdentifier', newConRoleIdentifier); // A new contact role record was created so we store its local identifier on the app state so that when creating its children linked entity records, we can retriece its salesforce Id from the newConRolesMap.

                        //}
                        appState.put('hasAccessChanges', true); // flag the application has changes to it's junction records in this transaction
                    }
                }
            }
        }

        // dml operations for contact role records
        delete conRolesToDelete;
        System.debug('*** conRolesToDelete' + conRolesToDelete);
        update conRolesToUpdate;
        insert newConRolesMap.values();

        for (BAMLinkedEntity__c le: getLinkedEntitiesForContactRoles(conRoleIdSet)) {
            linkedEntityMapByConRoleAndBillingAccId.put(le.ContactRole__c + '_' + le.BillingAccount__c, le);
            if (billingAccountsMapKeyedByConRoleId.get(le.ContactRole__c) == null) {
                billingAccountsMapKeyedByConRoleId.put(le.ContactRole__c, new Set<Id>());
            }
            Set<Id> baSet = billingAccountsMapKeyedByConRoleId.get(le.ContactRole__c);
            baSet.add(le.BillingAccount__c);
            billingAccountsMapKeyedByConRoleId.put(le.ContactRole__c, baSet);
        }

        List<BAMLinkedEntity__c> addedLinkedEntites = new List<BAMLinkedEntity__c>();
        List<BAMLinkedEntity__c> updatedLinkedEntities = new List<BAMLinkedEntity__c>();

        // third pass to to determine which linked entities need to be added or removed
        for (Map<String,Object> appState: pageState) {
            String selectedAppRoleId = (String)appState.get('selectedAppRoleId');
            String appId = (String)appState.get('Id');

            // if not role is selected in page state no linked entity records need to be created or removed
            if (selectedAppRoleId == NO_ACCESS_IDENTIFIER_STRING) continue;

            // if the selected app role does not have show billing account then we do not need to process any linked entities that may have come back fro the page state
            if (appRoleMapKeyedByAppIdandAppRoleId.get(appId + '_' + selectedAppRoleId).ShowBillingAccount__c != true) continue;

            List<Id> selectedBillingAccountIds = new List<Id>();
            for (Object unTypedId : (List<Object>) appState.get('selectedBillingAccountIds')) {
                selectedBillingAccountIds.add((Id)unTypedId);
            }
            if (selectedBillingAccountIds.isEmpty()) {
                throw new BAMUserException('Complete all required fields'); // billing accounts must be selected
            }
            if (appState.get('newConRoleIdentifier') != null) { // there was a contact role added in the last pass to this app new linked entity records need to be created
                // We do not need to do a diff to determine which linked entities were added or rmoved. Since a new role record was created, all its linked entity records need to be created anew.
                BAMContactRole__c insertedContactRoleRecord = newConRolesMap.get((Integer) appState.get('newConRoleIdentifier'));
                for (Id baId: selectedBillingAccountIds){
                    addedLinkedEntites.add(new BAMLinkedEntity__c(BillingAccount__c = baId, ContactRole__c = insertedContactRoleRecord.Id));
                    appState.put('hasAccessChanges', true);
                }
            }
            if (appState.get('conRoleId') != null) { // there was contact role that was identified in the last pass for which we need to do a billing account diff and add or remove the appropriate billing accounts by creating new linked entity records or by marking them for deletion
                Id conRoleId = (Id)appState.get('conRoleId');
                Set<Id> currentlySelectedBillingAccounts = new Set<Id>(selectedBillingAccountIds);
                Set<Id> initiallySelectedBillingAccounts = billingAccountsMapKeyedByConRoleId.get((Id)appState.get('conRoleId'));
                if (billingAccountsMapKeyedByConRoleId.get((Id)appState.get('conRoleId')) == null) initiallySelectedBillingAccounts =  new Set<Id>();
                List<Id> removedBillingAccounts = onlyInFirstSet(initiallySelectedBillingAccounts, currentlySelectedBillingAccounts);
                List<Id> addedBillingAccounts = onlyInFirstSet(currentlySelectedBillingAccounts, initiallySelectedBillingAccounts);
                Set<Id> unchangedBillingAccounts = inBothSets(currentlySelectedBillingAccounts, initiallySelectedBillingAccounts);

                // records that only exist in the target state from the UI that don't already exists in the database
                for (Id baId: addedBillingAccounts) {
                    addedLinkedEntites.add(new BAMLinkedEntity__c(BillingAccount__c = baId, ContactRole__c = conRoleId, Status__c = 'Pending'));
                    appState.put('hasAccessChanges', true);
                }

                // records that only exist in the initial state (database state) and not in the state from the UI
                for (Id baId: removedBillingAccounts) {
                    BAMLinkedEntity__c updatedLinkedEntity = linkedEntityMapByConRoleAndBillingAccId.get(conRoleId + '_' + baId);

	                // only mark a record as pending delete if it isn't already.
	                if(!updatedLinkedEntity.Pending_Delete__c) {
		                updatedLinkedEntity.Pending_Delete__c = true;
		                updatedLinkedEntities.add(updatedLinkedEntity);
		                appState.put('hasAccessChanges', true);
	                }
                }

                // records that exist in both initial state and target state (ui and database)
                // check the existing records (that aren't changing) if they have a Pending delete flag on them and remove the flag if needed
                // this records would not have appeared in addedBillingAccounts or removedBillingAccounts
                for(Id baId : unchangedBillingAccounts) {
                    BAMLinkedEntity__c updatedLinkedEntity = linkedEntityMapByConRoleAndBillingAccId.get(conRoleId + '_' + baId);
                    if(updatedLinkedEntity.Pending_Delete__c) {
                        updatedLinkedEntities.add(new BAMLinkedEntity__c(Id = updatedLinkedEntity.Id, Pending_Delete__c = false));
                        appState.put('hasAccessChanges', true);
                    }
                }

            }
        }
        insert addedLinkedEntites;
        update updatedLinkedEntities;

        // fourth pass to validate that no changes are committed for applicataions that already have pending changes
        for (Map<String,Object> appState: pageState) {
            BAMContactApplication__c conApp = conAppMapByAppId.get((String)appState.get('Id'));
            if (conApp == null) continue; // if there is no contact application for the record it can't have existing pending changes
            Boolean changesMade = ((Boolean) appState.get('hasAccessChanges') == true);
            Boolean hasPendingRequest = false;
            for (BAMExternalOnboardingRequest__c eor : conApp.BAM_External_Onboarding_Requests__r) {
                if(eor.Status__c == 'Pending') {
                    hasPendingRequest = true;
                }
            }
            if (hasPendingRequest && changesMade) { // changes were made to app with pending external request, throw exceptoin to revert changes
                System.debug(appState.get('Name'));
	            System.debug(updatedLinkedEntities);
	            System.debug(addedLinkedEntites);
                throw new BAMUserException('One or more of the Applications you have made changes to already have pending changes. Please refresh the page');
            }
        }
    }

    private static List<Id> onlyInFirstSet(Set<Id> set1, Set<Id> set2) {
        List<Id> retVal = new List<Id>();
        for(Id s1Id: set1) {
            if (!set2.contains(s1Id)) retVal.add(s1Id);
        }
        return retVal;
    }
    private static Set<Id> inBothSets(Set<Id> set1, Set<Id> set2) {
        Set<Id> retVal = new Set<Id>();
        for(Id s1Id: set1) {
            if (set2.contains(s1Id)) retVal.add(s1Id);
        }
        for(Id s2Id: set2) {
            if (set1.contains(s2Id)) retVal.add(s2Id);
        }
        return retVal;
    }

    private static List<BAMContactRole__c> filterContactRolesByStatus(List<BAMContactRole__c> conRoleList, String status) {
        // We return the first active role since there should only ever be one role
        List<BAMContactRole__c> retVal = new List<BAMContactRole__c>();
        for (BAMContactRole__c conRole: conRoleList) {
            if (conRole.Status__c == status) retVal.add(conRole);
        }
        return retVal;
    }

    @testVisible
    private class AccessChangeResultsWrapper {
        @testVisible
        Boolean success {get; set;}
        @testVisible
        String contactId {get; set;}
        @testVisible
        String message {get;set;}
    }


    @testVisible
    private static Id createUserUsingFlow(Id contactId) {
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
            throw new BAMUserException('User creation flow error: '+ flowError);
        }
        return (Id) createdUserId;
    }
	
    //REQ2279110 added filter criteria to remove Peoplesoft accounts
    private static List<Billing_Account__c> getBillingAccountsByOrgId(Id accountId) {
        List<Billing_Account__c> billingAccounts = [
                SELECT Id, Name, Organisation__c, SAP_marked_for_deletion__c, LEGACY_ID__c, MLID__c, Type__c, State__c, Suburb__c
                FROM Billing_Account__c
                WHERE Organisation__c = :accountId
                AND SAP_marked_for_deletion__c = false
                AND Type__c NOT IN:INVALID_BILLING_ACCOUNT_TYPES
            	AND Source_System__c !='PeopleSoft'
                ORDER BY Name
        ];

        return billingAccounts;
    }

    /**
     * Retrieve all the super users related to user's organisation, exept for the logged in user
     * this is used to display the super admins section on the my access page
     *
     * @param accountId : organisation ID of the logged in user as per the current usage
     *
     * @return List<BAMContactRole__c>
     */
    private static List<BAMContactRole__c> getSuperAdminsByOrgId(Id accountId) {
        List<BAMContactRole__c> bamContatRoles = [
                SELECT  Id, ContactApplication__r.Contact__c,ContactApplication__r.Contact__r.Name, ContactApplication__r.Contact__r.Email
                FROM BAMContactRole__c
                WHERE ContactApplication__r.Contact__r.AccountId = :accountId
                AND ContactApplication__r.Application__r.AppKey__c = :BAMUserUtility.ACCESS_MANAGEMENT_APP_KEY
                AND ApplicationRole__r.Role__c = :BAMUserUtility.ACCESS_MANAGEMENT_SUPER_ADMIN
                AND Status__c = 'Active'
                AND ContactApplication__r.Status__c = 'Active'
                AND ContactApplication__r.Contact__r.Status__c = 'Active'
        ];

        return bamContatRoles;
    }

    @testVisible
    private class UserDataWrapper {
        @testVisible
        String orgId {get; set;}
        @testVisible
        String loggedInUserContactId {get; set;}
        @testVisible
        Boolean isBAMUser {get; set;}
    }

    public static UserDataWrapper getUserInformation() {
        Id userId  = UserInfo.getUserId();
        User user = [SELECT Id, Name, Contact.AccountId, ContactId FROM User WHERE Id =: userId];
        Id orgId = user.Contact.AccountId;
        Id loggedInUserContactId = user.ContactId;
        Boolean isBAMUser = isBAMUser(loggedInUserContactId);

        UserDataWrapper retVal = new UserDataWrapper();
        retVal.orgId = orgId;
        retVal.loggedInUserContactId = loggedInUserContactId;
        retVal.isBAMUser = isBAMUser;

        return retVal;
    }

    public static Boolean isBAMUser(String contactId) {
        List<BAMContactRole__c> bamConRoleList = [
            SELECT Id, ContactApplication__c, ContactApplication__r.Status__c, ContactApplication__r.Contact__c, ContactApplication__r.Application__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Status__c, Status__c 
            FROM BAMContactRole__c
            WHERE ContactApplication__r.Application__r.AppKey__c = 'BAM'
            AND ContactApplication__r.Contact__c = :contactId
            AND ContactApplication__r.Application__r.Status__c = 'Active'
            AND ContactApplication__r.Status__c = 'Active'
            AND Status__c = 'Active'
        ];
        Boolean isBAMUser = bamConRoleList.size() > 0;
        return isBAMUser;
    }


    public static Contact getContact(Id contactId) {
        // get the contact record
        List<Contact> contacts = [
                SELECT Id, AccountId, Name, FirstName, LastName, Phone, Email, OID_ID__c, Status__c, BillingAccount__c, BAMCSSOLastInvite__c, BAMCSSOError__c, BAMCSSOErrorMessage__c, CreatedDate
                FROM Contact
                WHERE id = :contactId
        ];

        return contacts.size() > 0 ? contacts[0] : null;
    }

    /**
     * When a new contact is created in the community we can not use the current logged in user as the owner of the contact because the user doesn't have a role (Customer COmmunity only license)
     * We need to be able to set the owner of the contact to be someone with a Role (most likely a full license user)
     * IMPORTANT: In addition to this, this owner has to also be a part of the community so the current user can access the id
     */
    private static Id getContactOwnerId() {
        String userName = MerchantPortalSettings__c.getInstance().ContactOwnerUsername__c + '%';
        return [Select Id From User Where Username LIKE :userName].Id;
    }

    private static Boolean hasPendingRequests(Id contactId){
        List<BAMContactApplication__c> listContactApplications = getContactApplicationsWithLatestExternalOnboardingRequests(contactId);
        for (BAMContactApplication__c conApp : listContactApplications) {
            if(conApp.BAM_External_Onboarding_Requests__r != null && conApp.BAM_External_Onboarding_Requests__r.size() > 0){
                for (BAMExternalOnboardingRequest__c eor : conApp.BAM_External_Onboarding_Requests__r) {
                    if(eor.Status__c == 'Pending') {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
     * Helper function
     *
     * @param contactId
     *
     * @return
     */

    private static List<BAMContactApplication__c> getContactApplicationsWithLatestExternalOnboardingRequests(Id contactId) {
        List<BAMContactApplication__c> listContactApplications = [
                SELECT Id, Application__c, Application__r.Name, Pending_Delete__c,
                        Contact__c, BSPCanViewAllConsignments__c, Status__c,
                        (
                            SELECT Id, Status__c, Error__c
                            FROM BAM_External_Onboarding_Requests__r
                            WHERE RecordTypeId =: BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID
                            ORDER BY CreatedDate DESC
                            LIMIT 1
                        )
                FROM BAMContactApplication__c
                WHERE Contact__c =: contactId
        ];
        return listContactApplications;
    }

    private static List<BAMContactApplication__c> getActiveContactApplicationsWithLatestExternalOnboardingRequests(Id contactId) {
        List<BAMContactApplication__c> listContactApplications = [
                SELECT Id, Application__c, Application__r.Name, Status__c,
                        Contact__c, BSPCanViewAllConsignments__c, Pending_Delete__c,
                        (
                            SELECT Id, Status__c, Error__c
                            FROM BAM_External_Onboarding_Requests__r
                            WHERE RecordTypeId =: BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID
                            ORDER BY CreatedDate DESC
                            LIMIT 1
                        )
                FROM BAMContactApplication__c
                WHERE Contact__c =: contactId
                AND Status__c = 'Active'
        ];
        return listContactApplications;
    }

    @TestVisible
    private static List<BAMContactRole__c> getAllContactRolesForContact(Id contactId) {
        List<BAMContactRole__c> conRoles = [
                SELECT 
                    Id,
                    ContactApplication__c, 
                    ContactApplication__r.Application__c, ContactApplication__r.Status__c, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ContactApplication__r.Application__r.Status__c, ContactApplication__r.Pending_Delete__c, ContactApplication__r.BSPCanViewAllConsignments__c,
                    ApplicationName__c, 
                    ApplicationRole__c,
                    ApplicationRole__r.Role__c, ApplicationRole__r.Status__c,ApplicationRole__r.ShowBillingAccount__c, ApplicationRole__r.ShowGroup__c, ApplicationRole__r.ShowOrganisation__c, ApplicationRole__r.RoleDescription__c, ApplicationRole__r.Application__c, ApplicationRole__r.Application__r.AppKey__c,
                    LastModifiedDate,
                    CreatedDate,
                    Pending_Delete__c,
                    Status__c 
                FROM BAMContactRole__c 
                WHERE ContactApplication__r.Contact__c =: contactId
                ORDER BY ApplicationRole__r.OrderPriority__c, CreatedDate DESC
            ];
        return conRoles;
    }


    @TestVisible
    private static List<BAMContactRole__c> getContactRolesForContact(Id contactId) {
        List<BAMContactRole__c> conRoles = [
                SELECT 
                    Id,
                    ContactApplication__c, 
                    ContactApplication__r.Application__c, ContactApplication__r.Status__c, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ContactApplication__r.Application__r.Status__c, ContactApplication__r.Pending_Delete__c, ContactApplication__r.BSPCanViewAllConsignments__c,
                    ApplicationName__c, 
                    ApplicationRole__c,
                    ApplicationRole__r.Role__c, ApplicationRole__r.Status__c,ApplicationRole__r.ShowBillingAccount__c, ApplicationRole__r.ShowGroup__c, ApplicationRole__r.ShowOrganisation__c, ApplicationRole__r.RoleDescription__c, ApplicationRole__r.Application__c, ApplicationRole__r.Application__r.AppKey__c,
                    LastModifiedDate,
                    CreatedDate,
                    Pending_Delete__c,
                    Status__c 
                FROM BAMContactRole__c 
                WHERE ContactApplication__r.Contact__c =: contactId
                AND Pending_Delete__c != true
                ORDER BY ApplicationRole__r.OrderPriority__c, CreatedDate DESC
            ];
        return conRoles;
    }

    @TestVisible
    private static List<BAMLinkedEntity__c> getLinkedEntitiesForContactRoles(Set<Id> conRoleIds) {
        List<BAMLinkedEntity__c> linkedEntities = [
                SELECT 
                    Id, 
                    Name, 
                    BillingAccount__c, BillingAccount__r.Name, BillingAccount__r.MLID__c, BillingAccount__r.LEGACY_ID__c,
                    Group__c, Group__r.Name, 
                    Organisation__c, Organisation__r.Name, 
                    LastModifiedDate, 
                    ContactRole__c,
                    Pending_Delete__c,
                    IsDeleted 
                FROM BAMLinkedEntity__c
                Where Group__c = null
                AND Organisation__c = null
                AND ContactRole__c IN:conRoleIds
            ];
        return linkedEntities;
    }


    /* this method returns the contact roles keyed by their IDs along with the relevant child Linked Entity records. this is doen with a wrapper rather than with a nested query of sobjects because of the following two reasons
        - when the nested query has too many records, on ptest it throws a error that says too many rows in aggregate query for assignment. this is probably becuase of query optimiser
        - when over a 1000 records are sent to the client they seem to get paginated and a next url for salesforce' REST api is returnde to enable the client to access the records in the next page
    */
    @TestVisible
    private static Map<Id,BAMDataWrapper> getExistingAccessAndRolesWithLinkedEntitiesForContact(String contactId){
        try {
            Map<Id,BAMDataWrapper> outputMap = new Map<Id,BAMDataWrapper>();
            
            List<BAMContactRole__c> conRoles = [
                SELECT 
                    Id,
                    ContactApplication__c, 
                    ContactApplication__r.Application__c, ContactApplication__r.Status__c, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ContactApplication__r.Application__r.Status__c, ContactApplication__r.Pending_Delete__c, ContactApplication__r.BSPCanViewAllConsignments__c,
                    ApplicationName__c, 
                    ApplicationRole__c,
                    ApplicationRole__r.Role__c, ApplicationRole__r.Status__c,ApplicationRole__r.ShowBillingAccount__c, ApplicationRole__r.ShowGroup__c, ApplicationRole__r.ShowOrganisation__c, ApplicationRole__r.RoleDescription__c, ApplicationRole__r.Application__c, ApplicationRole__r.Application__r.AppKey__c,
                    LastModifiedDate,
                    CreatedDate,
                    Status__c 
                FROM BAMContactRole__c 
                WHERE ContactApplication__r.Contact__c =: contactId
                AND Pending_Delete__c != true
                ORDER BY ApplicationRole__r.OrderPriority__c, CreatedDate DESC
            ];
            List<Id> conRoleIds  = new List<Id>();
            
            for (BAMContactRole__c conRole: conRoles) {
                BAMDataWrapper conRoleWrapper = new BAMDataWrapper();
                conRoleWrapper.record = conRole;
                conRoleIds.add(conRole.Id);
                outputMap.put(conRole.Id, conRoleWrapper);
            }

            List<BAMLinkedEntity__c> linkedEntities = [
                SELECT 
                    Id, 
                    Name, 
                    BillingAccount__c, BillingAccount__r.Name, BillingAccount__r.MLID__c, BillingAccount__r.LEGACY_ID__c,
                    Group__c, Group__r.Name, 
                    Organisation__c, Organisation__r.Name, 
                    LastModifiedDate, 
                    ContactRole__c,
                    IsDeleted 
                FROM BAMLinkedEntity__c
                WHERE Pending_Delete__c != true
                AND Group__c = null
                AND Organisation__c = null
                AND ContactRole__c IN:conRoleIds
            ];

            for (BAMLinkedEntity__c le: linkedEntities) {
                BAMDataWrapper conRoleWrapper = outputMap.get(le.ContactRole__c);
                conRoleWrapper.childList.add(le);
            }
            return outputMap;
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

    /* this method returns the contact roles keyed by their IDs along with the relevant child Linked Entity records. this is doen with a wrapper rather than with a nested query of sobjects because of the following two reasons
        - when the nested query has too many records, on ptest it throws a error that says too many rows in aggregate query for assignment. this is probably becuase of query optimiser
        - when over a 1000 records are sent to the client they seem to get paginated and a next url for salesforce' REST api is returnde to enable the client to access the records in the next page
    */
    @TestVisible
    private static Map<Id,BAMDataWrapper> getActiveAccessAndRolesWithLinkedEntitiesForContact(Id contactId){
        try {
            Map<Id,BAMDataWrapper> outputMap = new Map<Id,BAMDataWrapper>();
            
            List<BAMContactRole__c> conRoles = [
                SELECT 
                    Id,
                    ContactApplication__c, 
                    ContactApplication__r.Application__c, ContactApplication__r.Status__c, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ContactApplication__r.Application__r.Status__c, ContactApplication__r.Pending_Delete__c, ContactApplication__r.BSPCanViewAllConsignments__c,
                    ApplicationName__c, 
                    ApplicationRole__c,
                    ApplicationRole__r.Role__c, ApplicationRole__r.Status__c,ApplicationRole__r.ShowBillingAccount__c, ApplicationRole__r.ShowGroup__c, ApplicationRole__r.ShowOrganisation__c, ApplicationRole__r.RoleDescription__c, ApplicationRole__r.Application__c, ApplicationRole__r.Application__r.AppKey__c,
                    LastModifiedDate,
                    CreatedDate,
                    Status__c 
                FROM BAMContactRole__c 
                WHERE ContactApplication__r.Contact__c =: contactId
                AND Pending_Delete__c != true
                AND Status__c = 'Active'
                AND ContactApplication__r.Status__c = 'Active'
                AND ContactApplication__r.Application__r.Status__c = 'Active'
                ORDER BY ApplicationRole__r.OrderPriority__c, CreatedDate DESC
            ];
            List<Id> conRoleIds  = new List<Id>();
            
            for (BAMContactRole__c conRole: conRoles) {
                BAMDataWrapper conRoleWrapper = new BAMDataWrapper();
                conRoleWrapper.record = conRole;
                conRoleIds.add(conRole.Id);
                outputMap.put(conRole.Id, conRoleWrapper);
            }

            List<BAMLinkedEntity__c> linkedEntities = [
                SELECT 
                    Id, 
                    Name, 
                    BillingAccount__c, BillingAccount__r.Name, BillingAccount__r.MLID__c, BillingAccount__r.LEGACY_ID__c,
                    Group__c, Group__r.Name, 
                    Organisation__c, Organisation__r.Name, 
                    LastModifiedDate, 
                    ContactRole__c,
                    IsDeleted 
                FROM BAMLinkedEntity__c
                WHERE Pending_Delete__c != true
                AND Status__c = 'Active'
                AND Group__c = null
                AND Organisation__c = null
                AND ContactRole__c IN:conRoleIds
            ];

            for (BAMLinkedEntity__c le: linkedEntities) {
                BAMDataWrapper conRoleWrapper = outputMap.get(le.ContactRole__c);
                conRoleWrapper.childList.add(le);
            }
            return outputMap;
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }
}