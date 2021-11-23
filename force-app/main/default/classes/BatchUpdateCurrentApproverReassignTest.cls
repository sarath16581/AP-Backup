/**
 * Date             Version          Owner              Desription
 * 01-Aug-17         1.0            Bharat P        Test class for BatchUpdateCurrentApproverReassignment
 */
@isTest
public class BatchUpdateCurrentApproverReassignTest{
	public static Credit_Approval__c creditApproval;
    public static Account tempTestAccount;
    public static Billing_Account__c testBillingAcc;
    public static Case cs;
    
    /* Creating Test Data*/
    private static void createTestData(){
		try{
        	RecordType recTypeAcc = [SELECT Id, name FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' 
                                     AND Name = 'Organisation' LIMIT 1];
        	Account testAcc = TestUtility.createBusinessAccount('TestAccountTest', recTypeAcc.Id);            
            insert testAcc;            
            tempTestAccount = [Select id, LEGACY_ID__c from Account where id =: testAcc.id];
            tempTestAccount.LEGACY_ID__c = '60000000';
            tempTestAccount.billingstreet = 'street';
            tempTestAccount.billingcity = 'city';
            tempTestAccount.billingstate = 'state';
            tempTestAccount.billingpostalcode = '3000';
            tempTestAccount.billingcountry = 'AU';
            tempTestAccount.shippingstreet = 'street';
            tempTestAccount.shippingcity = 'city';
            tempTestAccount.shippingstate = 'state';
            tempTestAccount.shippingpostalcode = '3000';
            tempTestAccount.shippingcountry = 'AU';
            //tempTestAccount.Sales_Segment__c = 'Test Sales Team';

            update tempTestAccount; 
            testBillingAcc = TestUtility.createBillingAccount('TestBillingAccTest', tempTestAccount.Id);
            //testBillingAcc.Legacy_Id__c = '60000000';
            insert testBillingAcc;
        	cs = I2CTestDataBuilder.createCase();
            cs.AccountId = tempTestAccount.Id;
            cs.Related_Billing_Account__c = testBillingAcc.Id;
            cs.ownerId = UserInfo.getUserId();
			insert cs;    
        }catch(Exception e){
            e.getMessage();    
        }
    }
    
    /* Creating Credit Approval Test Data*/
    private static void createCreditApprovalTestData(){
		try{
            createTestData();
			creditApproval = new Credit_Approval__c(Case__c = cs.Id, Status__c = 'Pending Approval Decision', Ready_For_Approval__c=true, CreditAmountExclusiveGST__c = 1100,
													CreditAmountInclusiveGST__c = 1210, Product_Family__c='Parcels',
													BillingAccountNumber__c = '12345', Billing_Account__c=testBillingAcc.Id, 
													Organisation__c=tempTestAccount.Id, Account_Manager__c=UserInfo.getUserId());
			insert creditApproval;			
        }catch(Exception e){
            e.getMessage();    
        }
    }
    
    /* Test Method for Batch Reassigning Current Approver */
    public static testMethod void testBatchApproverReassignment(){
        try{
            createCreditApprovalTestData();
            Test.startTest();
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(creditApproval.Id);
            //req1.setNextApprover(UserInfo.getUserId());
            // Submit on behalf of a specific submitter
            req1.setSubmitterId(UserInfo.getUserId()); 
            
            // Submit the record to specific process and skip the criteria evaluation
            req1.setProcessDefinitionNameOrId('Enterprise_Credit_Disputesv1_3');
            req1.setSkipEntryCriteria(true);
            
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
            //List<Id> newWorkItemIds = result.getNewWorkitemIds();
            
            List<ProcessInstanceWorkItem> workItemList = [Select p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId,
                                                          p.ProcessInstanceId,p.OriginalActorId,p.Id,p.ActorId From 
                                                          ProcessInstanceWorkitem p where p.ProcessInstance.TargetObjectId = :creditApproval.Id]; 
            workItemList.get(0).ActorId  = UserInfo.getUserId(); 
            update workItemList;            
            Database.executeBatch(new BatchUpdateCurrentApproverReassignment());
            Test.stopTest();
            // Verify the result
			System.assert(result.isSuccess());			
			System.assertEquals('Pending', result.getInstanceStatus(), 
								'Instance Status'+result.getInstanceStatus());            
        }catch(Exception e){
            e.getMessage();    
        }
    }   
}