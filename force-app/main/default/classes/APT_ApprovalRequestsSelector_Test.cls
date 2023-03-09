/* @author Nasir Jawed
* @date 2022-12-5
* @group Selector
* @tag Selector
* @tag Apttus_Approval__Approval_Request__c
* @domain Apttus
* @description APT_ApprovalRequestsSelector to validate Approval Request
*/
@IsTest
public class APT_ApprovalRequestsSelector_Test {

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */  
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString(){     
		Test.startTest();
		APT_ApprovalRequestsSelector selector = APT_ApprovalRequestsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus_Approval__Approval_Request__c\\b').matcher(soql).find(), 'Resulting query does not select from Approval Request');
							
		Test.stopTest();                    
				
	}

	/**
	 * Test:
	 *  Ensures that the selectors method is returning the correct query result
	 */
	@IsTest
	private static void testEnsureSelectorMethodsReturnCorrectResult() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		
		User u= ApplicationTestDataFactory.getUsers(1,false)[0];
		insert u;
		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		account.LEGACY_ID__c = '61918806';
		insert account ;
		
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert con;
		
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];        
		insert opportunityRecord ;
		//get Product and set Product Type
		Product2 product =APT_TestDataFactory.getAppcProduct(1,false)[0];        
		insert product;
		
		//get Proposal/Quote and Product Configuration
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opportunityRecord.id, account.Id, con.id, false)[0];
		insert quote;
			
		Apttus_Config2__ProductConfiguration__c config = APT_TestDataFactory.getAPTProductConfig(1, account.Id, quote.id, false)[0];               
		config.Apttus_Config2__Status__c ='Rejected';    
		insert  config ; 
		
		//prepare Approval Request data
		Apttus_Approval__Approval_Request__c approval1= APT_TestDataFactory.getApprovalRecord(1,config.id,false)[0];
		approval1.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
		approval1.Apttus_QPApprov__ProposalId__c = quote.id;
		approval1.Apttus_Approval__Actual_Approver__c=u.id;
		insert approval1;
		
		//prepare Approval Request data
		Apttus_Approval__Approval_Request__c approval= APT_TestDataFactory.getApprovalRecord(1,config.id,false)[0];
		approval.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
		approval.Apttus_QPApprov__ProposalId__c = quote.id;
		approval.Apttus_Approval__ParentRequestId__c=approval1.id;
		insert approval;
		
		
		Test.startTest();
		APT_ApprovalRequestsSelector  selector = APT_ApprovalRequestsSelector.newInstance();
		List<Apttus_Approval__Approval_Request__c > results = selector.selectByProdConfigId(new Set<Id>{config.id},new Set<Object>{APT_ApprovalRequestsSelector.Options.WITH_USER,APT_ApprovalRequestsSelector.Options.FILTER_APPROVAL_REQUEST});
		
		System.assertEquals(approval1.id,approval.Apttus_Approval__ParentRequestId__c, 'Incorrect approval request Id');
		System.assertEquals(1, results.size(), 'Result count was wrong');   
		
		APT_ApprovalRequestsSelector  limitSelector = APT_ApprovalRequestsSelector.newInstance(1);
		List<Apttus_Approval__Approval_Request__c > resultsLimit = limitSelector.selectByProdConfigId(new Set<Id>{config.id});
		System.assertEquals(1, resultsLimit.size(), 'Result count was wrong'); 
		Test.stopTest();

	}
}