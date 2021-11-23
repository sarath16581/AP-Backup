/**************************************************
Type:         Controller for visualforce components
                bspComponent
History:
--------------------------------------------------
2014-07-15 Yuanyuan Zhang <yuanyuan.zhang@bluewolf.com> - Created
2017-02-21 David Catindoy <david.e.catindoy@accenture.com> - Modified to increase code coverage.
2017-02-27 David Catindoy <david.e.catindoy@accenture.com> - Added testSetup method to setup test data.
2017-04-21 Andrew Judd <ajudd@salesforce.com>
2019-06-07 nathan.franklin@auspost.com.au Refactored
**************************************************/
@isTest
private class bspComponent_Test {
    
    @testSetup static void testSetup(){

        CCUSettings__c setting = new CCUSettings__c(
            // startrack
            Exclude_case_types__c = 'LDC',
            StarTrackAsyncWebServiceTimeout__c = 10,
            BSPSyncConsignmentSearchTimeout__c = 5,
            Exclude_Case_Purpose__c = 'Controlled Returns',

            // ap
            IncludedRecordTypes__c = 'SSSW%',
            EmailMsgKeyword__c = '%customerservice%',
            Max_Length_for_Consignment_Number__c = 40,
            Pickup_Booking_Ref_Number_Max_Length__c = 8,
            Pickup_Booking_Ref_Number_Min_Length__c = 7,
            APSyncWebServiceTimeout__c = 5,
            AusPostAsyncWebServiceTimeout__c = 10,
            UseContinuationforAPConsignSearch__c = true,
            DoNotShowFileNames__c = 'CN08-',
            APConsignmentSearchSourceSystemID__c = 'SFDC_BSP',

            // general
            MaxEnquiryRecords__c = 500,
            EnquiriesPerPage__c = 15,
            BSPCaseStatusList__c = 'In Progress,Action Required,Resolved,Closed',
            CCUCommunityUserProfileId__c = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id,
            AdminCaseSubject__c = 'Enterprise Contact Registration'
        );
        insert setting;
        
        mpbHspLiveChatBtnSettings__c mpbHsbSettings = new mpbHspLiveChatBtnSettings__c(LiveAgentButtonId__c='57390000000PQnI',
                LiveAgentDeploymentId__c='57290000000PQMn'
                ,LiveAgentInit__c='https://d.la1-c1cs-ukb.salesforceliveagent.com/chat',
                LiveAgentOrgId__c='00D0w0000000tsy',
                LiveAgentScriptSrc__c='https://c.la1-c1cs-ukb.salesforceliveagent.com/content/g/js/50.0/deployment.js'
                ,Live_Agent_SS_Endpoint__c='https://ap-mpb-ssce-ptest.smartspeak.ai');
        insert mpbHsbSettings;

        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        testAccount.Business_Solutions_Customer__c = true;
        testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You';
        testAccount.ServiceSLA__c = 'Enterprise';
        Database.insert(testAccount);

        testAccount.Legacy_Id__c = '60000000';
        update testAccount;

        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 4, new List<Account>{testAccount});
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P123456';
        Database.insert(testBillingAccList);

        Contact newCon = new Contact(FirstName = 'Nathan', LastName = 'Franklin', MobilePhone = '0400000000', Email = 'mytestemail@testingemails.com', BillingAccount__c = testBillingAccList[0].Id, AccountId = testAccount.Id, Status__c = 'Active');
        Database.insert(newCon);
    
    }

    /**
     * Test basic attributes of the component
     */
    public static testMethod void testBspComponent () {

        // BillingAccount__c is set to a TEAM billing account in @testSetup
        Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

        Network bspCommunity = [Select UrlPathPrefix From Network Where UrlPathPrefix = 'bsp'];

        User uAdmin = TestUtility.createUser('Testing6', [Select Id From Profile Where Name = 'System Administrator'].Id, null);
        System.debug('>> Sys Admin User: ' + uAdmin);

        User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

        // insert auth rule to test isCognitionUser

        Id cognitionRulesRecordTypeId = Schema.SObjectType.Authorization_Rule__c.getRecordTypeInfosByDeveloperName().get('Cognition_Rules').getRecordTypeId();
        Authorization_Rule__c rule = new Authorization_Rule__c(RecordTypeId = cognitionRulesRecordTypeId, Contact__c = con.Id, AccessRole__c = Label.Cognition_User, Status__c = 'Active');
        insert rule;

        Test.startTest();

        System.runAs(u) {
            bspComponent comp = new bspComponent();

            // to force the community to be BSP
            comp.currentNetworkId = bspCommunity.Id;

            System.assertNotEquals(null, comp.businessName);
            System.assertNotEquals(null, comp.businessNumber);
            System.assertEquals(true, comp.isCognitionUser);
             System.assertEquals('00D0w0000000tsy', comp.orgId);
            System.assertEquals('https://d.la1-c1cs-ukb.salesforceliveagent.com/chat', comp.chatInit);
            System.assertEquals('https://c.la1-c1cs-ukb.salesforceliveagent.com/content/g/js/50.0/deployment.js', comp.chatScriptSrc);
            System.assertEquals('57390000000PQnI', comp.buttonId);
            System.assertEquals('57290000000PQMn', comp.deploymentId);
            System.assertEquals('https://ap-mpb-ssce-ptest.smartspeak.ai', comp.endpoint);
            System.assertEquals('Enterprise', comp.serviceSLA);

        }

        System.runAs(uAdmin) {
            delete rule;
        }

        System.runAs(u) {
            bspComponent comp = new bspComponent();
            System.assertEquals(false, comp.isCognitionUser);

        }

        Test.stopTest();
    }
}