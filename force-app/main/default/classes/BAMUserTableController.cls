/**************************************************
Description: Utility class the handle various processes for BAM (Business Access Management)
History:
--------------------------------------------------
2019-04-11  vcheng@salesforce.com,sameed.khan@auspost.com.au  Created
2019-08-12  ajudd@salesforce.com Added BAM Record Type Id conditions
2020-11-09  saiswetha.pingali@auspost.com.au INC1688693- Fix for issues reported with critical update ' Use with sharing for @AuraEnabled Apex Controllers with Implicit Sharing
**************************************************/
public without sharing class BAMUserTableController {
    public static String ACCESS_MANAGEMENT = 'Access Management';
    public static String ACCESS_MANAGEMENT_APP_KEY = 'BAM';
    public static String FIELD_IS_BAM_USER = 'isBAMUser';
    public static String FIELD_ORG_ID = 'orgId';
    public static String FIELD_CONTACT_ID = 'contactId';

    public static String FIELD_TOTAL_RESULTS = 'totalResults';
    public static String FIELD_SEARCH_RESULTS = 'searchResults';
    public static String FIELD_CONTACT_APPLICATIONS = 'contactApplications';
    public static String FIELD_CONTACT = 'contact';
    public static String STATUS_INACTIVE = 'Inactive';
    public static String STATUS_ACTIVE = 'Active';
    public static String STATUS_PENDING = 'Pending';

    public static String RESULT_OK = 'ok';
    public static String RESULT_ERROR = 'error';
    public static String FIELD_RESULT = 'result';
    public static String FIELD_MESSAGE = 'message';
    public static String MESSAGE_NO_ACCESS = 'You do not have permission to edit this Contact';
    public static String MESSAGE_DEACTIVATED = ' has been deactivated';
    public static String MESSAGE_REINVITED = ' has been reactivated';


    @AuraEnabled
    public static Map<String, Object> retrieveUserDetails()
    {
        Map<String, Object> mapResults = new Map<String, Object>();
        mapResults.put(FIELD_IS_BAM_USER, false);

        // get user details
        Id userId  = UserInfo.getUserId();
        User user = [SELECT Id, Name, ContactId, AccountId FROM User WHERE Id =: userId];
        Id contactId = user.contactId;

        // get application access
        if(null != contactId && null != user.AccountId)
        {
            Boolean isBamUser = isCurrentUserBamUser();

            if(isBamUser)
            {
                // only return anything if they have access
                mapResults.put(FIELD_ORG_ID, user.AccountId);
                mapResults.put(FIELD_CONTACT_ID, user.ContactId);
                mapResults.put(FIELD_IS_BAM_USER, true);
            }
        }
        return mapResults;
    }

    private static Boolean isCurrentUserBamUser()
    {
        // get user details
        Id userId  = UserInfo.getUserId();
        User user = [SELECT Id, Name, ContactId, AccountId FROM User WHERE Id =: userId];
        Id contactId = user.contactId;

        List<BAMContactApplication__c> contactApplications = [
                SELECT Id, Status__c,
                (
                        SELECT Id FROM ContactRoles__r WHERE Status__c=:STATUS_ACTIVE
                )
                FROM BAMContactApplication__c
                WHERE Contact__c =: contactId
                AND Application__r.AppKey__c =: ACCESS_MANAGEMENT_APP_KEY
                AND Status__c =: STATUS_ACTIVE
        ];

        if(contactApplications.size() > 0 && contactApplications[0].ContactRoles__r.size() > 0)
        {
            return true;
        }
        return false;
    }


    private static UserRecordAccess getRecordAccess(Id recordId)
    {
        Id userId = UserInfo.getUserId();
        List<UserRecordAccess> listUserRecordAccesses = [
                SELECT RecordId, HasEditAccess, HasReadAccess, HasDeleteAccess
                FROM UserRecordAccess
                WHERE UserId = :userId
                AND RecordId = :recordId
        ];
        return listUserRecordAccesses[0];
    }

    private static Boolean isContactEditable(Id contactId)
    {
        // check that the org Ids match
        List<Contact> contacts = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Id =: contactId
        ];
        if(contacts.size() != 1)
        {
            return false;
        }

        Id myOrgId = (Id) retrieveOrgId();
        if(contacts[0].AccountId != myOrgId)
        {
            return false;
        }

        UserRecordAccess ura = getRecordAccess(contactId);
        if(ura == null || !ura.HasEditAccess)
        {
            return false;
        }

        // all good
        return true;

    }

    //@AuraEnabled
    /*
    public static string retrieveCurrentUserContactId(){
        try {
            Id userId  = UserInfo.getUserId();
            User user = [SELECT Id, Name, ContactId FROM User WHERE Id =: userId];
            Id contactId = user.contactId;
            return contactId;
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }
     */

    //@AuraEnabled
    public static string retrieveOrgId(){
        try {
            Id userId  = UserInfo.getUserId();
            User user = [SELECT Id, Name, Contact.AccountId FROM User WHERE Id =: userId];
            Id orgId = user.Contact.AccountId;
            return orgId;
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }

    private static String makeNameWhereClause(String searchString)
    {
        String sQuery = '';
        if(searchString != '' && searchString != NULL)
        {
            String sClean = String.escapeSingleQuotes(searchString);
            sQuery += ' AND (';
            sQuery += ' Name LIKE \'%' + sClean + '%\'';
            sQuery += ' OR Email LIKE \'%' + sClean + '%\'';
            sQuery += ' )';
        }
        return sQuery;
    }

    private static String makeActiveWhereClause(Boolean includeDeactivated)
    {
        String sQuery = '';
        if(includeDeactivated == null || !includeDeactivated)
            sQuery += ' AND Status__c = \'Active\'';
        return sQuery;
    }


    /**
     *
     *
     * @param orgId - account Id
     * @param pageSize - the number records per page
     * @param pageNumber - the current page number 1-based
     * @param searchString - and search parameters for name/email fields
     * @param includeDeactivated - whether or not to include deactivated contacts
     *
     * @return a map with the following structure
     *
     *  totalResults: 10, -- the total number of results possible (search results is only a page of them)
     *  searchResults:[{
     *      "contact": {the Contact fields},
     *      "contactApplications: [
     *                              {BAMContactApplication__c fields,
     *                                  "BAM_External_Onboarding_Requests__r" : [list of BAM external Requests],
     *                                  "ContactRoles__r" : [list of BAM Contact Roles]
     *                              ]
     *  }]
     */
    @AuraEnabled
    public static Map<String, Object> searchContactApplicationData(Id orgId, Integer pageSize, Integer pageNumber,
            String searchString, Boolean includeDeactivated)
    {
        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;
        
        // 1. get the contacts' data first using dynamic SOQL
        String sQuery = 'SELECT Id, AccountId, Name, FirstName, LastName, Phone, Email, OID_ID__c, Status__c, BillingAccount__c';
        sQuery += ', BAMCSSOLastInvite__c, BAMCSSOError__c, BAMCSSOErrorMessage__c, CreatedDate';
        sQuery += ' FROM Contact';
        sQuery += ' WHERE AccountId = \'' + orgId + '\'';
        sQuery += makeNameWhereClause(searchString);
        sQuery += makeActiveWhereClause(includeDeactivated);
        sQuery += ' ORDER By Name';
        sQuery += ' LIMIT ' + pageSize;

        Integer iOffset = (pageNumber - 1) * pageSize;
        sQuery += ' OFFSET ' + iOffset;
        System.debug('BAMUserTableController:: query = ' + sQuery);

        String sTotalQuery = 'SELECT Id FROM Contact';
        sTotalQuery += ' WHERE AccountId = \'' + orgId + '\'';
        sTotalQuery += makeNameWhereClause(searchString);
        sTotalQuery += makeActiveWhereClause(includeDeactivated);

        List<Contact> totalContacts = Database.query(sTotalQuery);

        List<Contact> listContacts = Database.query(sQuery);
        System.debug('BAMUserTableController:: results = ' + listContacts);


        // then setup the structure
        Map<String, Object> mapByContactId = new Map<String, Object>();
        for(Contact contact:listContacts)
        {
            Map<String, Object> objContactData = new Map<String, Object>();
            objContactData.put(FIELD_CONTACT, contact);
            objContactData.put(FIELD_CONTACT_APPLICATIONS, new List<BAMContactApplication__c> ());
            mapByContactId.put(contact.Id, objContactData);
        }
        Set<String> contactIds = mapByContactId.keySet();

        // 2. get the Contact Roles and map against the Contact Ids
        List<BAMContactApplication__c> listContactApplications = [
                SELECT Id, Application__c, Application__r.Name,
                        Contact__c
                        , (
                        SELECT Id, Status__c, Error__c, Request_Date__c, Type__c
                        FROM BAM_External_Onboarding_Requests__r 
                        WHERE RecordTypeId = :bamExtObRTId 
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                ),
                (
                        SELECT Id, Status__c, ApplicationRole__r.Role__c
                        FROM ContactRoles__r
                        WHERE Pending_Delete__c = FALSE
                        ORDER BY LastModifiedDate DESC
                )
                FROM BAMContactApplication__c
                WHERE Contact__r.AccountId = :orgId
                AND Contact__c IN: contactIds
                ORDER BY Contact__c, Application__r.Name
        ];
        // map against the contact Id
        for(BAMContactApplication__c contactApplication:listContactApplications)
        {
            Map<String, Object> objContactData = (Map<String, Object>) mapByContactId.get(contactApplication.Contact__c);

            List<BAMContactApplication__c> listAppsForContact = (List<BAMContactApplication__c>) objContactData.get(FIELD_CONTACT_APPLICATIONS);
            listAppsForContact.add(contactApplication);
        }

        // return the values only as a List
        List<Map<String, Object>> listContactData = new List<Map<String, Object>>();
        for(Object objContactData: mapByContactId.values())
        {
            listContactData.add((Map<String, Object>) objContactData);
        }

        // package as a map
        Map<String, Object> mapResults = new Map<String, Object> ();
        //mapResults.put('query', sQuery);
        mapResults.put(FIELD_SEARCH_RESULTS, listContactData);
        mapResults.put(FIELD_TOTAL_RESULTS, totalContacts.size());

        return mapResults;
    }

    /**
     * Cancel any inflight pending requests for the selected contact
     */
    @AuraEnabled
    public static Map<String, Object> cancelContactRequest(Id contactId) {
        System.debug('cancelContactRequest');
        Map<String, Object> mapResults = new Map<String, Object>();

        try {
            // security check
            if (false == isContactEditable(contactId) || false == isCurrentUserBamUser()) {
                // log an error?
                mapResults.put(FIELD_RESULT, RESULT_ERROR);
                mapResults.put(FIELD_MESSAGE, MESSAGE_NO_ACCESS);
            } else {
	            // throws exceptions
	            BAMIntegrationUtility.cancelExternalRequest(contactId);

	            mapResults.put(FIELD_MESSAGE, 'The request to cancel was submitted successfully.');
	            mapResults.put(FIELD_RESULT, RESULT_OK);
            }
        } catch(Exception ex) {
            mapResults.put(FIELD_MESSAGE, 'An error occurred: ' + ex.getMessage());
            mapResults.put(FIELD_RESULT, RESULT_ERROR);
        }

        System.debug('mapResults: ' + mapResults);

        return mapResults;
    }

    /**
     * Deactivate a contact
     *
     * @param contactId
     *
     * @return
     */
    @AuraEnabled
    public static Map<String, Object> deactivateContact(Id contactId)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        // security check
        if(false == isContactEditable(contactId) || false == isCurrentUserBamUser())
        {
            // log an error?
            mapResults.put(FIELD_RESULT, RESULT_ERROR);
            mapResults.put(FIELD_MESSAGE, MESSAGE_NO_ACCESS);
        }
        else
        {
            try{
                // get the contact
                Contact contact = [SELECT Id, Status__c, Name
                                    FROM Contact
                                    WHERE Id=:contactId];
                // set to inactive
                contact.Status__c = STATUS_INACTIVE;
                update contact;

                // the return message
                String sMsg = contact.Name + MESSAGE_DEACTIVATED;

                // set all Contact Applications to Pending Deactivation
                List<BAMContactApplication__c> listContactApplications = [
                        SELECT Id, Pending_Deactivation__c
                        FROM BAMContactApplication__c
                        WHERE Contact__c =: contactId
                ];
                for(BAMContactApplication__c contactApplication:listContactApplications)
                {
                    contactApplication.Pending_Deactivation__c = true;
                }
                if(listContactApplications.size() > 0)
                {
                    update listContactApplications;

                    if(listContactApplications.size() == 1) {
                        sMsg += '. 1 application deprovisioned.';
                    }
                    else
                    {
                        sMsg += '. ' + listContactApplications.size() + ' applications deprovisioned.';
                    }

                    // if there is anything to send requests for
                    Map<String, String> mapProvisionStrings = BAMProvision.provision(contactId);
                    String sDeprov = mapProvisionStrings.get(BAMProvision.FIELD_DEPROVISION);
                    if(sDeprov != null && sDeprov != '')
                    {
                        BAMProvisionCallout.processRequest(contactId, mapProvisionStrings);
                    }
                }
                mapResults.put(FIELD_MESSAGE, sMsg);
                mapResults.put(FIELD_RESULT, RESULT_OK);
            }
            catch(Exception ex)
            {
                // TODO
            }
        }


        return mapResults;
    }


    /**
     * Reactivate/reinvite a contact
     *
     * @param contactId
     *
     * @return
     */
    @AuraEnabled
    public static Map<String, Object> reactivateContact(Id contactId)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        // security check
        if(false == isContactEditable(contactId) || false == isCurrentUserBamUser())
        {
            // log an error?
            mapResults.put(FIELD_RESULT, RESULT_ERROR);
            mapResults.put(FIELD_MESSAGE, MESSAGE_NO_ACCESS);
        }
        else
        {
            // get the contact
            Contact contact = [SELECT Id, Status__c, Name
            FROM Contact
            WHERE Id=:contactId];

            // set all Contact Applications to Pending
            List<BAMContactApplication__c> listContactApplications = [
                    SELECT Id, Pending_Deactivation__c, Status__c
                    FROM BAMContactApplication__c
                    WHERE Contact__c =: contactId
            ];

            for(BAMContactApplication__c contactApplication:listContactApplications)
            {
                /*
                if(contactApplication.Pending_Deactivation__c = true)
                    contactApplication.Pending_Deactivation__c = false;
                 */
                contactApplication.Status__c = STATUS_PENDING;
            }

            if(listContactApplications.size() > 0)
            {
                update listContactApplications;
                // if there is anything to send requests for
                Map<String, String> mapProvisionStrings = BAMProvision.provision(contactId);
                BAMProvisionCallout.processRequest(contactId, mapProvisionStrings);
            }

            // set the contact status LAST, to allow the trigger
            contact.Status__c = STATUS_ACTIVE;
            update contact;

            String sMsg = contact.Name + MESSAGE_REINVITED;
            mapResults.put(FIELD_MESSAGE, sMsg);

            mapResults.put(FIELD_RESULT, RESULT_OK);
        }
        return mapResults;
    }



    // makes callout to resend invitation email
    private static Boolean resendInviteEmail(Id contactId, String email) {
        HttpRequest req = new HttpRequest();
        HTTPResponse res = BAMIntegrationUtility.postRequest('ResendInviteEmail', '{ "contactId": "' + contactId + '", "email": "' + email + '" }');
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        if (res.getStatusCode() == 204) {
            return true;
        }
        return false;
    }

    @AuraEnabled
    public static Map<String, Object> reinviteContact(Id contactId)
    {

        Map<String, Object> mapResults = new Map<String, Object>();

        // security check
        if(false == isContactEditable(contactId) || false == isCurrentUserBamUser())
        {
            // log an error?
            mapResults.put(FIELD_RESULT, RESULT_ERROR);
            mapResults.put(FIELD_MESSAGE, MESSAGE_NO_ACCESS);
        }
        else
        {
            // get the contact
            Contact contact = [SELECT Id, Email, BAMCSSOLastInvite__c
            FROM Contact
            WHERE Id=:contactId];

            // default as error
            mapResults.put(FIELD_RESULT, RESULT_ERROR);
            Boolean resendInviteSuccess = resendInviteEmail(contactId, contact.Email);
            System.debug('BAMUserTableController:: resendInviteSuccess' + resendInviteSuccess);
            if(resendInviteSuccess) {
                contact.BAMCSSOLastInvite__c = Datetime.now();
                System.debug('BAMUserTableController:: contact:' + contact);
                update contact;
                mapResults.put(FIELD_RESULT, RESULT_OK);
            }
        }
        return mapResults;
    }


}