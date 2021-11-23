/*@File Name		: ServiceNow_LookupListApexController
@Description 		: Apex class to test ServiceNow_LookupListApexController
@Author				: Ramtej Juloori
@Created			: 30/10/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/
@isTest
public class ServiceNow_LookupListApexControllerTest {
    
    /*******************************************************************************************************
     * @method name		: setupData
     * @description 		: method to setup the data required for test methods in this class
     * @parameters		: None
     * @returns 			: void
     */
	@testSetup
    public static void setUpData(){
        //Create Account
        Account acc1 = TestDataProvider.createBusinessAccount();
        insert acc1;
        //Insert Lodgment customer Migration record 
        Lodgement_Customer_Migration__c migrationRec = new Lodgement_Customer_Migration__c(Legal_Entity_Name__c = acc1.Id);
        insert migrationRec;
        Account acc0 = new Account(Name = 'Test Account123', Legacy_Id__c = '60000000');
        insert acc0;
        Account acc = new Account(Name = 'Test Account', Legacy_Id__c = '60000000', ParentId = acc0.Id);
        insert acc;
        //Insert Billing Account with acc as Organisation
        Billing_Account__c billingAcc = new Billing_Account__c(Name = 'TestName', Organisation__c = acc.Id);
        insert billingAcc;
    }
    /*******************************************************************************************************
     * @method name		: testGetLookupRecords
     * @description 		: method to test getRecordforAlllookups and getRecordsGeneric in single call
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testGetLookupRecords(){
        //test without searchObject without result
        List < SobjectUtilityWrapper.ObjectClass > objectWrapper = ServiceNow_LookupListApexController.getRecordforAlllookups('Service_Now_Case__x', 5, 'lcmxx', '');
        system.assertEquals(0, objectWrapper.size());
        //test without searchObject with result
        Id [] fixedSearchResults= new Id[1];
       fixedSearchResults[0] = [SELECT Id FROM Lodgement_Customer_Migration__c LIMIT 1].Id;
       Test.setFixedSearchResults(fixedSearchResults);
        List < SobjectUtilityWrapper.ObjectClass > objectWrapper1 = ServiceNow_LookupListApexController.getRecordforAlllookups('Service_Now_Case__x', 5, 'LCM', '');        
        system.assertEquals(1, objectWrapper1.size());
    }
}