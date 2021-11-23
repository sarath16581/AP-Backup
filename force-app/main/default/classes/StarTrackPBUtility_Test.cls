/************************************
 * History
 * Sept-2015:  Paul Fayle  Created
 * **********************************/
//Test of the Invocable method to Update the Web Email for StarTrack cases called by Process Builder
@isTest
private class StarTrackPBUtility_Test{
    public static testmethod void testPBUtility(){
        List<sobject> ls = TestDataProvider.createStartrackErrorMessagesData();

        // Verify all custom settings are created
        System.assertEquals(ls.size(),[SELECT id FROM StarTrack_Error_Messages__c].size());

        List<Account> lst_account = TestDataProvider.createAccount('test', 1);
        INSERT lst_account;
        lst_account[0].Legacy_Id__c = '60000000';
        UPDATE lst_account;
        
        List<Billing_Account__c> lst_billingAccount = TestDataProvider.createBillingAccount('test', 1, lst_account);
        INSERT lst_billingAccount;
        
        List<Article__c> lst_article = TestDataProvider.createArticle('Subject', 1,lst_billingAccount);       
        INSERT lst_article;        
        
        Id CaseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General Enquiry').getRecordTypeId();
        List<case> lst_cases = TestDataProvider.createCases('Subject', 1,lst_article);
        INSERT lst_cases;
        lst_cases[0].Accountid = lst_account[0].id;
        lst_cases[0].Related_Billing_Account__c = lst_billingAccount[0].id; 
        lst_cases[0].Recent_Caller_Email__c = 'test@test.com';
        lst_cases[0].Origin = 'Phone';
        lst_cases[0].RecordTypeId = CaseRecTypeId;
        lst_cases[0].Number_of_Callers__c = 1;
        lst_cases[0].Callers_Data_Change__c = true;
        
        test.startTest();

        UPDATE lst_cases;
         

        Test.stopTest();
        for (Case c : [SELECT SuppliedEmail FROM Case WHERE ID = :lst_cases[0].Id]) {
            //System.assertEquals('test@test.com', c.SuppliedEmail); PB dependent
        }        
     }        
}