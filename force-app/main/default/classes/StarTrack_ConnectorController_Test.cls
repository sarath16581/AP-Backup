/**************************************************
Description:    Test Class used for the CTI Integration for StarTrack
History:
--------------------------------------------------
2018-02-22  angelo.rivera@auspost.com.au  Created
2018-07-01  kalpita.talwadekar@auspost.com.au  Added test methods
**************************************************/
@isTest
public class StarTrack_ConnectorController_Test {

    /*****************************************************************
     * Scenario:
     *          Test method to find contact based on Name and Phone Number of calling customer
     *****************************************************************/
    @isTest
    static void findContactTest() {
        Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
        insert contact;
        Contact c = (Contact) StarTrack_ConnectorController.findContact('Phone', '1234');
        System.assert(c != null);

        c = (Contact) StarTrack_ConnectorController.getContact(c.Id, null);
        System.assert(c != null);

        /* multiple contacts */
        Contact contact2 = new Contact(FirstName = 'Foo', LastName = 'Bar', Phone = '1234');
        insert contact2;
        c = (Contact) StarTrack_ConnectorController.findContact('Phone', '1234');
        System.assert(c.Id == null);

        /* search unsuccessful */
        c = (Contact) StarTrack_ConnectorController.findContact('Phone', 'abcd');
        System.assert(c == null);
    }

    /*****************************************************************
     * Scenario:
     *          Test method for getting account details based on phone and number
     *****************************************************************/
    @isTest
    static void findAccountTest() {
        Account account = new Account(Name = 'Acme', Phone = '2345');
        insert account;
        Account c = (Account) StarTrack_ConnectorController.findContact('Phone', '2345');
        System.assert(c != null);

        c = (Account) StarTrack_ConnectorController.getContact(c.Id, null);
        System.assert(c != null);

        /* multiple leads */
        Account account2 = new Account(Name = 'Foo2', Phone = '2345');
        insert account2;
        c = (Account) StarTrack_ConnectorController.findContact('Phone', '2345');
        System.assert(c.Id == null);
    }

    /*****************************************************************
     * Scenario:
     *          Test method for getting find contact via on lead using phone number
     *****************************************************************/
    @isTest
    static void findLeadTest() {
        Lead lead = new Lead(Company = 'Lead Company', FirstName = 'firstname', LastName = 'lastname', Phone = '3456');
        insert lead;
        Lead c = (Lead) StarTrack_ConnectorController.findContact('Phone', '3456');
        System.assert(c != null);

        c = (Lead) StarTrack_ConnectorController.getContact(c.Id, null);
        System.assert(c != null);

        Lead lead2 = new Lead(Company = 'Lead Company', FirstName = 'firstname2', LastName = 'lastname2', Phone = '3456');
        insert lead2;
        c = (Lead) StarTrack_ConnectorController.findContact('Phone', '3456');
        System.assert(c.Id == null);
    }

    /*****************************************************************
     * Scenario:
     *          Test method for searching case based on case number
     *****************************************************************/
    @isTest
    static void findCase() {
        Case newCase = new Case(Subject = 'abc');
        insert newCase;

        Case myCase = [SELECT CaseNumber FROM Case WHERE Subject = :'abc'];
        Case c = StarTrack_ConnectorController.findCase(myCase.CaseNumber);
        System.assert(c != null);
    }

    /*****************************************************************
     * Scenario:
     *          Test method for creating task for the contact
     *****************************************************************/
    @isTest
    static void createTask() {
        Map<String, String> taskMap = new Map<String, String>();
        Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
        insert contact;
        Contact c = (Contact) StarTrack_ConnectorController.findContact('Phone', '1234');
        Task task = StarTrack_ConnectorController.closeTask(c.Id, null, c.AccountId, 'a subject', 'a comment', null, null, taskMap, 10);
        System.assert(task != null);

        task = StarTrack_ConnectorController.getContactByTask(task.Id);
        System.assert(task != null);

        Sobject record = StarTrack_ConnectorController.getRecord(task.Id, 'CallObject');
        System.assert(record != null);
    }

    /*****************************************************************
     * Scenario:
     *          test method for creating case
     *****************************************************************/
    @isTest
    static void createCase() {
        Map<String, String> caseMap = new Map<String, String>();
        Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
        insert contact;

        Case c = StarTrack_ConnectorController.createCase(contact.Id, contact.AccountId, 'interaction', 'a subject', null, caseMap);
        System.assert(c != null);
    }

    /*****************************************************************
     * Scenario:
     * Triggers a search for cases based on the consignment passed in.
     * In this method, no continuation will be invoked because we make sure articles always exist before calling the method
     *****************************************************************/
    @isTest
    static void findConsignment() {
        Id consignmentRecordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId();

        Article__c art = new Article__c(Name = '12345678', RecordTypeId = consignmentRecordTypeId);
        Article__c art2 = new Article__c(Name = '1234567', RecordTypeId = consignmentRecordTypeId);
        insert new List<Article__c>{art, art2};

        String deliveryRecordType = StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT;
        String recId = [Select Id from RecordType where DeveloperName = :deliveryRecordType limit 1].Id;
        insert new Case(Subject = 'abc123', ArticleTest__c = art.Id, RecordTypeId = recId);

        Case newCase = [Select Id, CaseNumber, Status From Case];
        Object result = StarTrack_ConnectorController.findConsignment('12345678');
        System.debug('result : ' + result);
        //System.assertEquals(String.valueOf(result), newCase.Id + '_' + newCase.CaseNumber + '_' + newCase.Status);

        insert new Case(Subject = 'abc345', ArticleTest__c = art.Id, RecordTypeId = recId);

        Boolean result1 = String.valueOf(StarTrack_ConnectorController.findConsignment('12345678')).contains('MultipleCase');
        System.debug('result1 : ' + result1);
        System.assertEquals(true, result1);
        
        Boolean result2 = String.valueOf(StarTrack_ConnectorController.findConsignment('1234567')).contains('NoCase');
        System.debug('result2 : ' + result2);
        System.assertEquals(true, result2);

    }

    /*****************************************************************
     * Scenario:
     * Attempts to do find consignment on an article that doesn't exist in salesforce yet.
     * A continuation will be invoked to queries .net webservice
     *****************************************************************/
    @isTest
    static void findConsignmentContinuation() {

        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = true,
                                            EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10,
                                            Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true,
                                            Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 2,
                                            StarTrack_ConSearch_Client_Cert__c = 'cert', Sync_Web_Service_Callout_Timeout__c = 5);

        Test.startTest();

        StarTrack_ConnectorController controller = new StarTrack_ConnectorController();

        Continuation conti = (Continuation) StarTrack_ConnectorController.findConsignment('2AT71923');

        // Perform mock callout
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_singleConsign());

        // Set the fake response for the continuation
        Map<String, HttpRequest> requests = conti.getRequests();
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        // note this will call the controller.processSearchRemoteConsignment() instance method
        //      the actual continuation call from the remote action calls the static processSearchRemoteConsignment(state) method
        Object result = Test.invokeContinuationMethod(controller, conti);
        System.debug(conti);

        Test.stopTest();

        // check to make sure that the article was created and the right NoCase_ response is returned.
        Article__c article = [Select Id From Article__c Where RecordType.DeveloperName = 'Consignment'];
        System.assertEquals(String.valueOf(result), 'NoCase_' + article.Id);

    }

    /*****************************************************************
     * Scenario:
     *
     *****************************************************************/
    @isTest
    static void checkRelatedContactOfCase() {
        Case newCase = new Case(Subject = 'abc');
        insert newCase;

        Case newCase1 = new Case(Subject = 'abc1');
        insert newCase1;

        AuthorisedContacts__c relatedCon = new AuthorisedContacts__c(First_Name__c = 'Test', Last_Name__c = 'Test', Contact_Email__c = 'tst@test.com',
            case__c = newCase.Id, Contact_Phone_Number__c = '0478738121');
        insert relatedCon;

        AuthorisedContacts__c res = StarTrack_ConnectorController.checkRelatedContactOfCase(newCase.Id, '0478738121');
        System.assert(res != null);

        AuthorisedContacts__c res1 = StarTrack_ConnectorController.checkRelatedContactOfCase(newCase1.Id, '0478738120');
        System.assert(res != null);
    }

    /*****************************************************************
     * Scenario:
     *
     *****************************************************************/
    @isTest
    static void updateCaseWithRecentCaller() {
        Case newCase = new Case(Subject = 'abc1');
        insert newCase;

        AuthorisedContacts__c relatedCon = new AuthorisedContacts__c(First_Name__c = 'Test', Last_Name__c = 'Test', Contact_Email__c = 'tst@test.com',
            case__c = newCase.Id, Contact_Phone_Number__c = '0478738121');
        insert relatedCon;

        AuthorisedContacts__c relCon = [
            Select Calc_Contact_Phone_Number__c, Calc_Contact_Mobile_Number__c
            from AuthorisedContacts__c
            where case__c = :newCase.Id
        ];

        Case c = StarTrack_ConnectorController.updateCaseWithRecentCaller(relCon, newCase.Id);
        System.assert(c != null);
    }

    /*****************************************************************
     * Scenario:
     *
     *****************************************************************/
    @isTest
    static void createCasewithConsignmentNumber() {
        Article__c art = new Article__c(Name = '12345678');
        insert art;

        Case c = StarTrack_ConnectorController.createCasewithConsignmentNumber(art.Id, '0478738120', true, 'Card Left', '', 'Sender');
        System.assert(c != null);
    }

    /*****************************************************************
     * Scenario:
     *
     *****************************************************************/
    @isTest
    static void createCallLog() {
        Case newCase = new Case(Subject = 'abc');
        insert newCase;

        String res = StarTrack_ConnectorController.createCallLog(newCase.Id);
    }
}