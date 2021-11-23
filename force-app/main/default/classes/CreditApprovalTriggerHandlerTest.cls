/**
 * Date             Version          Owner              Desription
 * 06-Jun-17         1.0            Bharat P        Test class for CreditApprovalTriggerHandler
 */
@isTest
public class CreditApprovalTriggerHandlerTest{
    
//    public static Credit_Approval__c creditApproval;
//	public static Credit_Approval_Process_Setting__c credAppProcSetting;
//	public static Approval_Steps__c approvalStep1, approvalStep2, approvalStep3, approvalStep4, approvalStep5, approvalStep6;
//    public static Approval_Steps__c approvalStep7, approvalStep8, approvalStep9, approvalStep10, approvalStep11;
//	public static Approval_Submission__c appSubmission;
//	public static Workflow_Criteria__c workflowCriteria;
//    public static Account tempTestAccount;
//    public static Billing_Account__c testBillingAcc;
//    public static Case cs;
//    public static Sales_Segment_Reference__c salesTeam;
//	public static List<CreditApprovalMatrix__c> lstCAM;
//    public static List<Sales_Segment_Reference__c> listSalesTeam;
//    public static Approval_Workflow__c appWorkflow1, appWorkflow2, appWorkflow3;
//
//    /* Creating Test Data*/
//    private static void createTestData(){
//		try{
//        	RecordType recTypeAcc = [SELECT Id, name FROM RecordType WHERE IsActive = true AND SobjectType = 'Account'
//                                     AND Name = 'Organisation' LIMIT 1];
//        	Account testAcc = TestUtility.createBusinessAccount('TestAccountTest', recTypeAcc.Id);
//            insert testAcc;
//            tempTestAccount = [Select id, LEGACY_ID__c from Account where id =: testAcc.id];
//            tempTestAccount.LEGACY_ID__c = '60000000';
//            tempTestAccount.billingstreet = 'street';
//            tempTestAccount.billingcity = 'city';
//            tempTestAccount.billingstate = 'state';
//            tempTestAccount.billingpostalcode = '3000';
//            tempTestAccount.billingcountry = 'AU';
//            tempTestAccount.shippingstreet = 'street';
//            tempTestAccount.shippingcity = 'city';
//            tempTestAccount.shippingstate = 'state';
//            tempTestAccount.shippingpostalcode = '3000';
//            tempTestAccount.shippingcountry = 'AU';
//            update tempTestAccount;
//            system.debug('Temp Test Acc--'+tempTestAccount);
//            testBillingAcc = TestUtility.createBillingAccount('TestBillingAccTest', tempTestAccount.Id);
//            insert testBillingAcc;
//            system.debug('Temp Test Billing Acc--'+testBillingAcc);
//        	cs = I2CTestDataBuilder.createCase();
//            cs.AccountId = tempTestAccount.Id;
//            cs.Related_Billing_Account__c = testBillingAcc.Id;
//            cs.ownerId = UserInfo.getUserId();
//			insert cs;
//        }catch(Exception e){
//            e.getMessage();
//        }
//    }
//    /* Creating Credit Approval Test Data */
//    private static void createCreditApprovalTestData(){
//		try{
//            createTestData();
//            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' Limit 1];
//            User usr1 = new User(Alias = 'standt1', Email='test1@testorg.com',
//            EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
//            LocaleSidKey='en_AU', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney',
//            UserName='testuser1@testorg.com');
//            insert usr1;
//            User usr2 = new User(Alias = 'standt2', Email='test2@testorg.com',
//            EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US',
//            LocaleSidKey='en_AU', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney',
//            UserName='testuser2@testorg.com', ManagerId = usr1.Id);
//            insert usr2;
//            User usr3 = new User(Alias = 'standt3', Email='test3@testorg.com',
//            EmailEncodingKey='UTF-8', LastName='Testing3', LanguageLocaleKey='en_US',
//            LocaleSidKey='en_AU', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney',
//            UserName='testuser3@testorg.com', ManagerId = usr2.Id);
//            insert usr3;
//
//            lstCAM = new List<CreditApprovalMatrix__c>();
//            CreditApprovalMatrix__c cam = new CreditApprovalMatrix__c();
//            cam.Product_Family__c = 'Parcels';
//            cam.Product_Sub_Category__c = 'Financial Services';
//            lstCAM.add(cam);
//            CreditApprovalMatrix__c cam1 = new CreditApprovalMatrix__c();
//            cam1.Product_Family__c = 'default';
//            cam1.Product_Sub_Category__c = 'default';
//            lstCAM.add(cam1);
//            system.assertEquals(2, lstCAM.size());
//
//            listSalesTeam = new List<Sales_Segment_Reference__c>();
//            salesTeam = new Sales_Segment_Reference__c();
//            salesTeam.Sales_Segment__c = 'Test Sales Team';
//            salesTeam.Sales_Director__c = usr3.Id;
//            salesTeam.Sales_Team_Owner_Type__c = 'Sales Manager';
//            listSalesTeam.add(salesTeam);
//            insert listSalesTeam;
//
//            for(Sales_Segment_Reference__c sTeam : listSalesTeam){
//            	String salesTeamOwnerTyp = sTeam.Sales_Team_Owner_Type__c;
//                system.assertEquals('Sales Manager', salesTeamOwnerTyp);
//            }
//            insert lstCAM;
//            credAppProcSetting = new Credit_Approval_Process_Setting__c(Active__c=true, Approval_Process_Name__c='Enterprise Credit Disputesv1.3',
//										DefaultSetting__c = true, Object__c='Credit_Approval__c', Name__c='Amount Including GST = 1,650.00');
//			insert credAppProcSetting;
//            List<Workflow_Criteria__c> lstWFC = new List<Workflow_Criteria__c>();
//            Workflow_Criteria__c wfc = new Workflow_Criteria__c(Credit_Approval_Process__c = credAppProcSetting.Id, Field_Name__c = 'CreditAmountExclusiveGST__c',
//                                                                Operator__c = 'greater than', Value__c = '1000');
//            lstWFC.add(wfc);
//			Workflow_Criteria__c wfc1 = new Workflow_Criteria__c(Credit_Approval_Process__c = credAppProcSetting.Id, Field_Name__c = 'Product_Family__c',
//                                                                Operator__c = 'equal to', Value__c = 'Parcels');
//            lstWFC.add(wfc1);
//            insert lstWFC;
//
//            List<Approval_Steps__c> lstApprovalSteps = new List<Approval_Steps__c>();
//            approvalStep1 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=1, Step_Name__c='Customer Resolutions Manager');
//            approvalStep2 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=2, Step_Name__c='Sales Director');
//            //approvalStep3 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=3, Step_Name__c='GM of Sales');
//            //approvalStep4 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=4, Step_Name__c='Head Of Product');
//            //approvalStep5 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=5, Step_Name__c='GM of Product');
//            approvalStep6 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=6, Step_Name__c='Head Of Finance');
//            /*approvalStep7 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=7, Step_Name__c='GM Of Finance');
//            approvalStep8 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=8, Step_Name__c='Parcels COO');
//            approvalStep9 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=9, Step_Name__c='Executive General Manager');
//            approvalStep10 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=10, Step_Name__c='Group CFO');
//            approvalStep11 = new Approval_Steps__c(Credit_Approval_Process__c=credAppProcSetting.Id, Sequence__c=11, Step_Name__c='CEO');*/
//            lstApprovalSteps.add(approvalStep1);
//            lstApprovalSteps.add(approvalStep2);
//            //lstApprovalSteps.add(approvalStep3);
//            //lstApprovalSteps.add(approvalStep4);
//            //lstApprovalSteps.add(approvalStep5);
//            lstApprovalSteps.add(approvalStep6);
//            /*lstApprovalSteps.add(approvalStep7);
//            lstApprovalSteps.add(approvalStep8);
//            lstApprovalSteps.add(approvalStep9);
//            lstApprovalSteps.add(approvalStep10);
//            lstApprovalSteps.add(approvalStep11);*/
//            insert lstApprovalSteps;
//
//			creditApproval = new Credit_Approval__c(Case__c = cs.Id, Status__c = 'New', Ready_For_Approval__c=true, CreditAmountExclusiveGST__c = 1100,
//													CreditAmountInclusiveGST__c = 1210, RejectionFinal__c = false, Product_Family__c='Parcels', Sales_Team__c = 'Test Sales Team',
//													BillingAccountNumber__c = '12345', Billing_Account__c=testBillingAcc.Id,
//													Organisation__c=tempTestAccount.Id, Account_Manager__c=UserInfo.getUserId());
//			insert creditApproval;
//            appSubmission = new Approval_Submission__c(Credit_Approval__c=creditApproval.Id, Status__c='Pending');
//            insert appSubmission;
//			List<Approval_Workflow__c> lstAppWrkFlow = new List<Approval_Workflow__c>();
//			appWorkflow1 = new Approval_Workflow__c(Submission_Group__c=appSubmission.Id, Step_Name__c='Customer Resolutions Manager', Sequence__c=1);
//        	appWorkflow2 = new Approval_Workflow__c(Submission_Group__c=appSubmission.Id, Step_Name__c='Sales Director', Sequence__c=2);
//        	appWorkflow3 = new Approval_Workflow__c(Submission_Group__c=appSubmission.Id, Step_Name__c='Head Of Finance', Sequence__c=3);
//            lstAppWrkFlow.add(appWorkflow1);
//            lstAppWrkFlow.add(appWorkflow2);
//            lstAppWrkFlow.add(appWorkflow3);
//            insert lstAppWrkFlow;
//        }catch(Exception e){
//            e.getMessage();
//        }
//    }
//
//    /* Test Method for Credit Approval Matrix Population */
//    public static testMethod void testCreditApprovalMatrix(){
//        try{
//        	createCreditApprovalTestData();
//			List<Disputed_Item__c> diListWithoutCA = I2CTestDataBuilder.createDisputeItem(cs);
//			List<Disputed_Item__c> diTempListWithoutCA = new List<Disputed_Item__c>();
//            for(Disputed_Item__c diItem : diListWithoutCA){
//            	if(diItem.Product__c == 'Parcels'){
//                	diItem.ERP_ID__c = 'SAP ERP';
//                    diItem.Product_Sub_Category__c = 'Financial Services';
//                    diItem.Resolution_Code__c = 'Ok';
//                    diItem.Proposed_Credit__c = 1100;
//                    diItem.Credit_Amount_Exclusive_GST__c = 1100;
//                    diItem.Status__c = 'Verified Claim';
//                    diItem.Reason__c = 'Delivery Error';
//                    diItem.Reason_Category__c = 'Delivery Issue';
//                    diItem.AP_Profit_Centre_Code__c = '321';
//                    diItem.Product_Code__c = '122';
//                    diItem.Service_Type__c = 'ASK';
//                    diItem.ST_Destination__c = '33';
//                    diItem.ST_Origin__c = '22';
//                    diItem.ST_Revenue_Depot__c = '11';
//                    diItem.Credit_Approval__c = creditApproval.Id;
//                    diTempListWithoutCA.add(diItem);
//                }
//            }
//            Test.startTest();
//            system.debug('Before DI Insert--- '+diTempListWithoutCA);
//            insert diTempListWithoutCA;
//            Test.stopTest();
//            system.debug('After DI Insert--- '+diTempListWithoutCA);
//            system.assertEquals(1, diTempListWithoutCA.size());
//        }catch(Exception e){
//            e.getMessage();
//        }
//    }
//
//    /* Test Method for Credit Approval Step Population */
//    public static testMethod void testCreditApprovalProcessSteps(){
//        try{
//            createCreditApprovalTestData();
//            Test.startTest();
//            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
//            req1.setComments('Submitting request for approval.');
//            req1.setObjectId(creditApproval.Id);
//			req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
//            // Submit on behalf of a specific submitter
//            req1.setSubmitterId(UserInfo.getUserId());
//            // Submit the record to specific process and skip the criteria evaluation
//            req1.setProcessDefinitionNameOrId('Enterprise_Credit_Disputesv1_3');
//            req1.setSkipEntryCriteria(true);
//            // Submit the approval request for the account
//            Approval.ProcessResult result = Approval.process(req1);
//            Test.stopTest();
//            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
//            List<Id> newWorkItemIds = result.getNewWorkitemIds();
//	        req.setComments('Approving request.');
//	        req.setAction('Approve');
//	        req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
//	        req.setWorkitemId(newWorkItemIds.get(0));
//            Approval.ProcessResult result2 =  Approval.process(req);
//
//            // Verify the result
//			System.assert(result.isSuccess());
//			System.assertEquals('Pending', result.getInstanceStatus(),
//								'Instance Status'+result.getInstanceStatus());
//        }catch(Exception e){
//            e.getMessage();
//        }
//    }
//
//    /* Test Method for Bulk Steps*/
//    public static testMethod void bulkStepsTest(){
//    	//CreditApprovalTriggerHandler.bulkSteps();
//  	}
}