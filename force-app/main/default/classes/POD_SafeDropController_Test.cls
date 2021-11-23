/**
 * @author       : kalpita.talwadekar@auspost.com.au
 * @date         : 13/11/2018
 * @description  : Test class for Testing scenarios on POD_SafeDrop hosted via BSP consignment search
 */
/*******************************  History ************************************************
 Date                User                                        Comments
 

 *******************************  History ************************************************/
@isTest
private class POD_SafeDropController_Test{

    // Constants
    private static final String BSP_PROFILE = 'BSP Community User';
    private static final Profile prof = [SELECT Id,Name 
                                        FROM 
                                            Profile 
                                        where 
                                            Name =: BSP_PROFILE 
                                        LIMIT 1];


    @testSetup
    static void setupTestData() {
    
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        Database.insert(testAccount);
        
        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);
        
        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 3, new List<Account>{testAccount});
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P1234567';
        insert testBillingAccList;
        
        //insert test article with Account's APCN
        Article__c testArticle1 = new Article__c();
        testArticle1.Name = 'testArticle1';
        testArticle1.ArticleID__c = 'testArticle1';
        testArticle1.ArticleLodgementDate__c = Date.today();
        testArticle1.SenderPostcode__c = '3000';
        testArticle1.ReceiverPostcode__c = '3006';
        testArticle1.ArticleType__c = 'Regular Parcel';
        testArticle1.Receiver_APCN__c = 'abcd1234';
        testArticle1.Billing_Account__c = testBillingAccList[0].Id;
        insert testArticle1;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User' limit 1]; 
        Contact newCon = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546325', Email = 'davidcatindoy@gmail.com', 
                                    BillingAccount__c = testBillingAccList[0].Id, AccountId = testAccount.Id, 
                                    Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE, 
                                    CCUAuthorisedAllOrgCases__c = true);
        Database.insert(newCon);
        
        User u = new User(Alias = 'bspUser', Email='user@testorg.a', ContactId = newCon.Id, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
                          
        Database.insert(u);        
        
        //insert EM scan for delivered scan with signature
        EventMessage__c em = new EventMessage__c(EventType__c='DD-ER15', Article__c=testArticle1.Id);
        insert em;
        //insert EM scan for delivered scan with Safe drop with existing image - not 1st time view of PDF     
        EventMessage__c em2 = new EventMessage__c(EventType__c='DD-ER38', Safe_Drop_GUID__c='12345', Article__c=testArticle1.Id);
        insert em2;
        //insert EM scan for delivered scan with safe drop no existing image 1st time view of PDF        
        EventMessage__c em3 = new EventMessage__c(EventType__c='DD-ER33', Safe_Drop_GUID__c='12345A', Article__c=testArticle1.Id);
        insert em3;
        //Delivered Signature file
        Attachment att1 = new Attachment (ContentType='image/jpeg', Body=EncodingUtil.base64Decode('This'), Name='Signature_Delivered',ParentId = em.Id);
        insert att1;
        // safe drop file
        Attachment att = new Attachment (ContentType='image/jpeg', Body=EncodingUtil.base64Decode('This'), Name='SAFE_DROP_POD',ParentId = em2.Id);
        insert att;
         
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for the POD signature display pdf
     **********************************************************************/
    private static testMethod void testPOD_Signature() {
        //query the scan event for delivered with signature
        EventMessage__c em = [Select Id from EventMessage__c where EventType__c = 'DD-ER15' limit 1];
        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
        
        System.runAs(bspUser) {
        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(em);
            POD_SafeDropController contr = new POD_SafeDropController(stdCon);
            //initialize the code
            contr.init();
            POD_SafeDropController.getArticleImage(em.Id);
            
        test.stopTest();
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *      Checking for the POD SafeDrop display pdf
     **********************************************************************/
    private static testMethod void testPOD_SafeDropExistingAttach() {
        //query the scan event for safe drop
        EventMessage__c em = [Select Id from EventMessage__c where EventType__c = 'DD-ER38' limit 1];
        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
        
        //insert authentication settings for callout
        SafeDropUtility_Test.insertAuthSettings();
        //run as BSP user
        System.runAs(bspUser) {
            test.startTest();
                //set standard page controller and initialize class constroller
                ApexPages.StandardController stdCon = new ApexPages.StandardController(em);
                POD_SafeDropController contr = new POD_SafeDropController(stdCon);
                //initialize the code
                contr.init();
                // Invoke the continuation
                Object continuation = POD_SafeDropController.getArticleImage(em.Id);
                //call to setup requestlable
                POD_SafeDropController.ContinuationState  requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel_ConState(continuation);
                //set other continuation state params
                requestLabel.safeDropGuid = '12345';
                requestLabel.eventMessageId = em.Id;
                //call to get response
                SafeDropUtility_Test.setSuccessContinuationResponse_ConState(requestLabel);
                //get the response from callback method
                String response = (String)POD_SafeDropController.callback(requestLabel);
            test.stopTest();
        }    
    }
    
    /**********************************************************************
     *  Scenario:
     *      Checking for the POD SafeDrop display pdf for 1st time 
     **********************************************************************/
    private static testMethod void testPOD_SafeDropNoAttach() {
        //query the scan event for safe drop
        EventMessage__c em = [Select Id from EventMessage__c where EventType__c = 'DD-ER33' limit 1];
        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
        
        //insert authentication settings for callout
        SafeDropUtility_Test.insertAuthSettings();
        //run as BSP user
        System.runAs(bspUser) {
            test.startTest();
                //set standard page controller and initialize class constroller
                ApexPages.StandardController stdCon = new ApexPages.StandardController(em);
                POD_SafeDropController contr = new POD_SafeDropController(stdCon);
                //initialize the code
                contr.init();
                 // Invoke the continuation
                Object continuation = POD_SafeDropController.getArticleImage(em.Id);
                //call to setup requestlable
                POD_SafeDropController.ContinuationState  requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel_ConState(continuation);
                //set other continuation state params
                requestLabel.safeDropGuid = '12345A';
                requestLabel.eventMessageId = em.Id;
                //call to get response
                SafeDropUtility_Test.setSuccessContinuationResponse_ConState(requestLabel);
                //get the response from callback method
                String response = (String)POD_SafeDropController.callback(requestLabel);
            test.stopTest();
        }    
    }
}