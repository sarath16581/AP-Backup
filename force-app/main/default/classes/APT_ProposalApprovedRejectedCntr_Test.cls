/***
 * @author Jetha Ram
 * @date 2016-07-28
 * @group 
 * @description This class is test class for APT_ProposalApprovedRejectedController.
 * @changelog
 * 2016-07-28 - Jetha Ram- Created
 * 2021-11-17 - Mathew Jose - Fixing the test method failures created by the introduction of key contact lookup filter on Opportuntiy (CI-194)
 * 2022-12-2 - NAsir Jawed- Added data for selectors and created mock data by using APT_Testdatafactory
*/
@isTest
private class APT_ProposalApprovedRejectedCntr_Test{

	@IsTest
	public static void TestProposalApprovedRejected(){
		
		// =====================================
		// Data Preparation
		// =====================================
		Apttus_Config2__ConfigSystemProperties__c sysProp = new Apttus_Config2__ConfigSystemProperties__c();
		sysProp.Name = APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES;
		sysProp.Apttus_Config2__InstanceUrl__c = APT_Constants.PARAM_RETURN_URL ;
		insert sysProp;        
		
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		account.LEGACY_ID__c = '61918806';
		
		
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		
		
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];        
		
		//get Product and set Product Type
		Product2 product =APT_TestDataFactory.getAppcProduct(1,true)[0];        

		//get Proposal/Quote and Product Configuration
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opportunityRecord.id, account.Id, con.id, true)[0];
		
		Apttus_Config2__ProductConfiguration__c config = APT_TestDataFactory.getAPTProductConfig(1, account.Id, quote.id, true)[0];               
		config.Apttus_Config2__Status__c ='Rejected';       
		
		List<Apttus_Approval__Approval_Request__c> ApprovalList= new List<Apttus_Approval__Approval_Request__c>();
		Apttus_Approval__Approval_Request__c approval1= APT_TestDataFactory.getApprovalRecord(1,config.id,true)[0];
		approval1.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
		approval1.Apttus_QPApprov__ProposalId__c = quote.id;
		
		Apttus_Approval__Approval_Request__c approval= APT_TestDataFactory.getApprovalRecord(1,config.id,true)[0];
		approval.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
		approval.Apttus_QPApprov__ProposalId__c = quote.id;
		approval.Apttus_Approval__ParentRequestId__c=approval1.id;
		
		ApprovalList.add(approval);

		//get summary group, Product Option Component, Classification and Hierarchy
		Apttus_Config2__SummaryGroup__c summaryGroup = APT_TestDataFactory.getSummaryGroupRecord(1, config.Id, 78, 45, true)[0];
		
		Apttus_Config2__ProductOptionComponent__c prodOptionComponent = APT_TestDataFactory.getProductOptionComponentRecord(1, 2, true)[0];
		
		Apttus_Config2__ClassificationName__c category = APT_TestDataFactory.getClassificationNameRecord(1, 'Test', 'High', 'Offering', 'Sample', true)[0];
		
		Apttus_Config2__ClassificationHierarchy__c classHierarchy = APT_TestDataFactory.getClassificationHierarchyRecord(1, category.id, 'Sample', true)[0];      
		
		
		List<ID> lineItemIDList = new List<ID>();
		Map<ID,Apttus_Config2__LineItem__c> lineItemMap = new Map<ID,Apttus_Config2__LineItem__c> ();
		Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, config.Id, true)[0];
		//insert lineItem ;
		lineItemIDList.add(lineItem.id);
		lineItemMap.put(lineItem.id,lineItem);
		
		Set<String> picklist = new Set<String>();
		picklist.add('Finalized');
		picklist.add('Ready For Finalization');
		picklist.add('Rejected');
		
		ProductConfigurationSelector mockSelectorProdConfig = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorProdConfig.selectByProposalIdAndStatusWithOrder((set<ID>)fflib_Match.eq(new set<ID>{(ID)quote.Id}),(set<String>)fflib_Match.eq(picklist),(set<Object>)fflib_Match.eq(new set<Object>{ProductConfigurationSelector.options.WITH_ACCOUNT}))).thenReturn(
			new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{config}));
		MockUtility.Mocks.stopStubbing();
		
		APT_ApprovalRequestsSelector mockSelectorApprovalReq = (APT_ApprovalRequestsSelector) MockUtility.mockSelector(APT_ApprovalRequestsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorApprovalReq.selectByProdConfigId((Set<ID>)fflib_Match.eq(new Set<ID>{(ID)config.Id}),(Set<Object>)fflib_Match.anyObject())).thenReturn(
			new List<Apttus_Approval__Approval_Request__c>(new List<Apttus_Approval__Approval_Request__c>{approval}));
		MockUtility.Mocks.stopStubbing();
		
		test.starttest();
		APT_ProposalApprovedRejectedController  proposalApprovalContrl= new APT_ProposalApprovedRejectedController();
		proposalApprovalContrl.proposalSO = quote ;
		proposalApprovalContrl.productConfigSO = config ;
		proposalApprovalContrl.approvalRequestList = ApprovalList;
		proposalApprovalContrl.lineItemIDList = lineItemIDList;
		proposalApprovalContrl.lineItemMap = lineItemMap;
		proposalApprovalContrl.proposalID = quote.id;
		proposalApprovalContrl.APT_ProposalApprovedRejectedController();
		proposalApprovalContrl.getProposalURL();
		system.assertNotEquals(proposalApprovalContrl.productConfigSO,null, 'Product Config not returned');       
		test.stopTest();   
	}

}