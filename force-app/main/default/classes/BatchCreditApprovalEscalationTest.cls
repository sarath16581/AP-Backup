/**
* Author: 		Angelo Rivera
* Name: 		BatchCreditApprovalEscalationTest
* Description: 	Test Class for BatchCreditApprovalEscalation
* Revision History
* 07-12-2017 	1.0		AP.Rivera		Created
**/

@isTest
private class BatchCreditApprovalEscalationTest
{
	public static Credit_Approval__c creditApproval;
	public static Credit_Approval_Process_Setting__c credAppProcSetting;
	public static Approval_Steps__c approvalStep1, approvalStep2, approvalStep3;
	public static Approval_Submission__c appSubmission;
	public static Workflow_Criteria__c workflowCriteria;
	public static Approval_Workflow__c appWorkflow1, appWorkflow2, appWorkflow3;

	private static final String ECCF_PROFILE = 'System Administrator';

	public static void createTestData(){
		Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organisation').getRecordTypeId();
    	Account testAcc = TestUtility.createBusinessAccount('TestAccountTest', devRecordTypeId);            
        insert testAcc;            
        Account tempTestAccount = [Select id, LEGACY_ID__c from Account where id =: testAcc.id];
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
        update tempTestAccount; 
        
        Billing_Account__c testBillingAcc = new Billing_Account__c(Name = 'TestBillingAccTest',Organisation__c = tempTestAccount.Id, LEGACY_ID__c = '12345');
        insert testBillingAcc;

    	Case cs = I2CTestDataBuilder.createCase();
        cs.AccountId = tempTestAccount.Id;
        cs.Related_Billing_Account__c = testBillingAcc.Id;
        cs.ownerId = UserInfo.getUserId();
        cs.Billing_Number__c = '12345';
        insert cs;
        	 Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' Limit 1];
            User usr1 = new User(Alias = 'standt1b', Email='test1b@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing1b', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', 
            UserName='testuser1b@testorg.com');
            insert usr1;            
            User usr2 = new User(Alias = 'standt2b', Email='test2b@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing2b', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', 
            UserName='testuser2b@testorg.com', ManagerId = usr1.Id);
            insert usr2;            
            User usr3 = new User(Alias = 'standt3b', Email='test3b@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing3b', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', 
            UserName='testuser3b@testorg.com', ManagerId = usr2.Id);
            insert usr3;
        
        
		CreditApprovalMatrix__c cam1 = new CreditApprovalMatrix__c();
        cam1.Product_Family__c = 'default';
        cam1.Product_Sub_Category__c = 'default';
       	cam1.GMOfSales__c = usr1.Id;
        cam1.SalesDirector__c =     usr3.Id;
        insert cam1;
        credAppProcSetting = new Credit_Approval_Process_Setting__c(Active__c=true, Approval_Process_Name__c='Enterprise Credit Disputesv1.3',
									Escalate_Process__c=true, Escalation_Comment__c='Auto Approved through escalation process',
										EscalationTimeinBusinessDays__c = 1, Object__c='Credit_Approval__c', Name__c='Amount Including GST = 1,650.00');
		insert credAppProcSetting;
		List<Approval_Steps__c> lstApprovalSteps = new List<Approval_Steps__c>();
		approvalStep1 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Escalate__c=true, Sequence__c=1, Step_Name__c='Customer Resolutions Manager');
		approvalStep2 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Escalate__c=true, Sequence__c=2, Step_Name__c='Sales Director');
		approvalStep3 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Escalate__c=true, Sequence__c=3, Step_Name__c='Head Of Finance');
		lstApprovalSteps.add(approvalStep1);
		lstApprovalSteps.add(approvalStep2);
		lstApprovalSteps.add(approvalStep3);
		insert lstApprovalSteps;
        
		creditApproval = new Credit_Approval__c(Case__c = cs.Id, Status__c = 'New', Ready_For_Approval__c=true, CreditAmountExclusiveGST__c = 1500,
													Date_Submitted_to_Current_Approver__c = System.now(),
														CreditAmountInclusiveGST__c = 1650, Product_Family__c='Parcels',
															BillingAccountNumber__c = '12345', Billing_Account__c=testBillingAcc.Id, 
																Organisation__c=tempTestAccount.Id, Account_Manager__c=UserInfo.getUserId());
		insert creditApproval;
        
		appSubmission = new Approval_Submission__c(Credit_Approval__c=creditApproval.Id, Credit_Approval_Process_Setting__c=credAppProcSetting.Id, Status__c='Pending');
		insert appSubmission;
		List<Approval_Workflow__c> lstAppWrkFlow = new List<Approval_Workflow__c>();
		appWorkflow1 = new Approval_Workflow__c(Submission_Group__c=appSubmission.Id, Step_Name__c='Customer Resolutions Manager', Sequence__c=1);
        appWorkflow2 = new Approval_Workflow__c(Submission_Group__c=appSubmission.Id, Step_Name__c='Sales Director', Sequence__c=2);
        appWorkflow3 = new Approval_Workflow__c(Submission_Group__c=appSubmission.Id, Step_Name__c='Head Of Finance', Sequence__c=3);
        lstAppWrkFlow.add(appWorkflow1);
        lstAppWrkFlow.add(appWorkflow2);
        lstAppWrkFlow.add(appWorkflow3);
        insert lstAppWrkFlow;
	}

	@isTest
	static void autoApproveTest(){
		createTestData();
    	Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(creditApproval.Id);
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('Enterprise_Credit_Disputesv1_4');
        req1.setSkipEntryCriteria(true);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);

        Credit_Approval__c credApp = [Select Id, Date_Submitted_to_Current_Approver__c from Credit_Approval__c
        								where Id =: creditApproval.Id];
        credApp.Date_Submitted_to_Current_Approver__c = System.now()-4;
		update credApp;
	
		Test.startTest();
        BatchCreditApprovalEscalation batchClass= new BatchCreditApprovalEscalation();
        Database.executeBatch(batchClass);        
        Test.stopTest();
        Credit_Approval__c credApp1 = [Select Id, Status__c from Credit_Approval__c
        								where Id =: creditApproval.Id];
        System.assertEquals('Pending Approval Decision', credApp1.Status__c);
	}
}