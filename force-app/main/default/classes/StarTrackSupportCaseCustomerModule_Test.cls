/**
 * @description
 * Test class for StarTrackSupportCaseCustomerModule
 * @author Snehil Jaiswal
 * @date 2021-06-30
 * @group Tests
 * @domain Startrack
 * @changelog
 */

@IsTest
private class StarTrackSupportCaseCustomerModule_Test {
    /**
     * Test: BeforeInsert
     * When startrack case is inserted, populate the billing details on case based on 
     * article's billing account details or billing account details.
     */
    @IsTest
    private static void testEnsureBeforeInsertPopulatesBillingAccountDetailsOnCase() {
        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(1, true);
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        List<Billing_Account__c> billingAccountList = ApplicationTestDataFactory.getBillingAccounts(1,accountList[0].Id,'TEAM', true);
        List<Case> caseList = ApplicationTestDataFactory.getCases(2, false);
        
        // set billing account on article
        articles[0].Billing_Account__c = billingAccountList[0].Id;
        
        // set article, recordTypeId, RelatedBillingAccount on case
        caseList[0].ArticleTest__c = articles[0].Id;
        caseList[0].RecordTypeId = caseList[1].RecordTypeId = ApplicationTestDataFactory.casestarTrackCreditDisputeRecordType;
        caseList[1].Related_Billing_Account__c = billingAccountList[0].Id;
        
        // =====================================
        // Stubbing
        // =====================================
        ArticlesSelector mockArticleSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
        BillingAccountsSelector mockBillingAccountSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);
        
        // set up responses
        MockUtility.Mocks.startStubbing();
        
        MockUtility.Mocks.when(mockArticleSelector.selectById(new Set<Id>{ articles[0].Id }))
            .thenReturn(new Map<Id, Article__c>(articles));
        
        MockUtility.Mocks.when(mockBillingAccountSelector.selectById(new Set<Id>{ billingAccountList[0].Id }))
            .thenReturn(new Map<Id, Billing_Account__c>(billingAccountList));
        MockUtility.Mocks.stopStubbing();

    
        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        StarTrackSupportCaseCustomerModule module = StarTrackSupportCaseCustomerModule.newInstance();

        module.onBeforeInsert(caseList, uow);

        Test.stopTest();
        
        // make sure the method behaved
        ((ArticlesSelector) MockUtility.Mocks.verify(mockArticleSelector, 1)).selectById(new Set<Id>{ articles[0].Id });
        ((BillingAccountsSelector) MockUtility.Mocks.verify(mockBillingAccountSelector, 1)).selectById(new Set<Id>{billingAccountList[0].Id} );
        
        // ensure details are populated correctly
        System.assertEquals(
            accountList[0].Id,
            caseList[0].Billing_Account_Parent_Id__c,
            'Ensure Billing Account is updated with billing account organisation id'
        );
    }

    /**
     * Test:
     * When startrack case is updated, populate/clear the billing details on case.
     */
    @IsTest
    private static void testEnsureBeforeUpdatePopulatesBillingAccountDetailsOnCase() {
        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
        Set<Id> accId = new Set<Id>();
        List<User> userList = ApplicationTestDataFactory.getUsers(1, true);
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(1, true);
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        List<Billing_Account__c> billingAccountList = ApplicationTestDataFactory.getBillingAccounts(1,accountList[0].Id,'TEAM', true);
        List<Case> oldCaseList = ApplicationTestDataFactory.getCases(4, true);
        List<Case> caseList = new List<Case>();
        
        // set the required fields on Account
        for(Account acc : accountList) {
            accId.add(acc.Id);
            acc.LEGACY_ID__c = '60000000';
            acc.Business_Solutions_Customer__c = true;
            acc.Exclude_Subscription_Automation__c = false;
            acc.Exclude_Notification_Automation__c = false;
            acc = (Account)ApplicationTestDataFactory.setUnwritableFields(acc, new Map<String, Object>{'Owner' => userList[0]});
        }
        
        // set billing account id and record type on case
        for(Case c : oldCaseList) {
            c.RecordTypeId = ApplicationTestDataFactory.casestarTrackCreditDisputeRecordType;
            c.Related_Billing_Account__c = billingAccountList[0].Id;
            caseList.add(c.clone(true));
        }
        
        // set billing account id on article
        articles[0].Billing_Account__c = billingAccountList[0].Id;
        
        // set article, account, related billing account on case
        oldCaseList[0].ArticleTest__c = articles[0].Id;
        oldCaseList[0].AccountId = accountList[0].Id;
        oldCaseList[1].AccountId = accountList[0].Id;
        oldCaseList[1].Related_Billing_Account__c = billingAccountList[0].Id;

        // change article, account on case
        caseList[0].ArticleTest__c = articles[0].Id;
        caseList[2].AccountId = accountList[0].Id;
        caseList[1].AccountId = null;
        
        // =====================================
        // Stubbing
        // =====================================
        ArticlesSelector mockArticleSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
        AccountsSelector mockAccountSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
        BillingAccountsSelector mockBillingAccountSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);
        
        // set up responses
        MockUtility.Mocks.startStubbing();
        
        MockUtility.Mocks.when(mockArticleSelector.selectById(new Set<Id>{ articles[0].Id }))
            .thenReturn(new Map<Id, Article__c>(articles));
        
        MockUtility.Mocks.when(mockAccountSelector.selectById(accId, new Set<Object>{ AccountsSelector.Options.WITH_OWNER }))
            .thenReturn(new Map<Id, Account>(accountList));
       
        MockUtility.Mocks.when(mockBillingAccountSelector.selectById(new Set<Id>{ billingAccountList[0].Id }))
            .thenReturn(new Map<Id, Billing_Account__c>(billingAccountList));
        
        MockUtility.Mocks.stopStubbing();
    
        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        StarTrackSupportCaseCustomerModule module = StarTrackSupportCaseCustomerModule.newInstance();

        module.onBeforeUpdate(caseList, new Map<Id, Case>(oldCaseList), uow);

        Test.stopTest();
        
        // make sure the method behaved
        ((ArticlesSelector) MockUtility.Mocks.verify(mockArticleSelector, 1)).selectById(new Set<Id>{ articles[0].Id });
        ((BillingAccountsSelector) MockUtility.Mocks.verify(mockBillingAccountSelector, 2)).selectById(new Set<Id>{billingAccountList[0].Id} );
        ((AccountsSelector) MockUtility.Mocks.verify(mockAccountSelector, 1)).selectById(accId,new Set<Object>{ AccountsSelector.Options.WITH_OWNER });
        
        // Ensures details are populated correctly
        System.assertEquals(
            accountList[0].Id,
            caseList[0].Billing_Account_Parent_Id__c,
            'Ensure Billing Account is updated with billing account organisation id'
        );
        System.assertEquals(
            billingAccountList[0].LEGACY_ID__c,
            caseList[1].Billing_Number__c,
            'Ensure Billing number is updated with billingaccount legacy id'
        );
     }

    /**
     * Test: Integration Scenario
     * Inserts case, account, billing account, articles and link them, which will update the billing details on case.
     *
     */
    @IsTest
    private static void testEnsureBillingAccountDetailsPopulatedOnCaseIntegration() {
        // =====================================
        // Data Preparation
        // =====================================

        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, false);
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
        List<Billing_Account__c> billingAccountList = ApplicationTestDataFactory.getBillingAccounts(1,null,'TEAM', false);
        List<Case> caseList = ApplicationTestDataFactory.getCases(4, false);
        
        // =====================================
        // Testing
        // =====================================
        test.startTest();

         // set the required fields on Account
        for(Account acc : accountList){
            acc.Business_Solutions_Customer__c = true;
            acc.Exclude_Notification_Automation__c = false;
            acc.Exclude_Subscription_Automation__c = false;
            acc.OwnerId = UserInfo.getUserId();
        }
        
        insert accountList;

        // Update legacy id on account because it has been used in billingaccounttrigger
        accountList[0].Legacy_Id__c = '60000000';
        update accountList[0]; 

        //set generated account id on billing account
        billingAccountList[0].Organisation__c = accountList[0].Id;
        insert billingAccountList;
        
        //set generated billing account id on article
        articles[0].Billing_Account__c = billingAccountList[0].Id;
        insert articles;
        
        //set recordtype id on case
        for(Case c : caseList) {
            c.RecordTypeId = ApplicationTestDataFactory.casestarTrackCreditDisputeRecordType;
        }
        
        //set article, account and billing account on case
        caseList[0].ArticleTest__c = articles[0].Id;
        caseList[0].AccountId = accountList[0].Id;
        caseList[1].AccountId = accountList[0].Id;
        caseList[1].Related_Billing_Account__c = billingAccountList[0].Id;
        insert caseList;
        
        //update article, account and billing account on case
        caseList[0].ArticleTest__c = articles[0].Id;
        caseList[2].AccountId = accountList[0].Id;
        caseList[3].Related_Billing_Account__c = billingAccountList[0].Id;
        caseList[1].AccountId = null;
        caseList[1].Related_Billing_Account__c =null;
        
        update caseList;
        // Get updated case to ensure fields are popolated correctly
        List<Case> cases = [Select Id , Billing_Account_Parent_Id__c From Case where Id =:caseList[0].Id];
        
        test.stopTest();
        
        // Ensures details are populated correctly
        System.assertEquals(
            accountList[0].Id,
            cases[0].Billing_Account_Parent_Id__c,
            'Ensure Billing Account is updated with billing account organisation id');
    }
}