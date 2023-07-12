/***
 * @author Darshan Chauhan
 * @date 2021-05-31
 * @group 
 * @description Test class consisting of methods to test the methods in the APT_PricingAdjustmentController class.
 * @changelog
 * 2021-05-31 - Darshan Chauhan - Created
 2022-05-15 Nasir Jawed changed Tier
Ken McGuire 2023.04.19 Proposal field migration to opportunity
*/

@isTest
public with sharing class APT_PricingAdjustmentController_Test {
	/**
	 * Creating test data
	 */
	@TestSetup
	static void createTestData(){
		//Startrack Product
		Product2 product = APT_TestUtils.createStarTrackProduct('Road Express Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'T01', 'EXP', 'Startrack');
		product.APT_Domestic_Pricing__c = true;
		insert product;

		Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
		insert priceList;

		// List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();
		Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
		// priceListItemList.add(priceListItem);
		insert priceListItem;

		APT_Post_Code_Mapping__c postCodeMapping = APT_TestUtils.createPostCodeMapping('0200', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC3');
		insert postCodeMapping;

		Account acc = APT_TestUtils.createOrganisation();
		insert acc;

		Opportunity oppty = APT_TestUtils.createOpportunity(acc.Id);
		oppty.IsStartrackProposal__c = 'Yes';
		oppty.APTMinimumMonthlySpend__c = 1200;
		oppty.APTPostcodeSuburb__c = postCodeMapping.Id;
		insert oppty;

		Apttus_Proposal__Proposal__c proposalObj = APT_TestUtils.getQuoteProposal(acc.Id, oppty.Id, 'Proposal', 'Test', priceList.Id);
		proposalObj.APT_Tier_Adjustment_Type__c = '1 Tier Up';
		proposalObj.Apttus_Proposal__Primary__c = true;
		proposalObj.APT_Pricing_Request_Type__c = 'New Business';
		proposalObj.APT_Tier_Adjustment_Justification__c = 'Test';
		proposalObj.APT_Customer_Background__c = 'Test';
		proposalObj.APT_Conversation__c = 'Test';
		proposalObj.APT_competitor__c = 'Test';
		insert proposalObj;

		Apttus_Config2__ProductConfiguration__c propConfig = APT_TestUtils.getProductConfiguration('Test',1,proposalObj.Id,'Proposal','Product',priceList.Id,null,'New',date.today(),date.today().addDays(30),true);
		propConfig.Apttus_QPConfig__Proposald__c = proposalObj.Id;
		insert propConfig;

		Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(propConfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
				1, 'Product/Service', product.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
				null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable
				'Each', 1, priceList.id, priceListItem.id,//Uom, term, priceList, Pli,
				'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
				true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
				5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
		bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
		bundleLine.Apttus_Config2__NetPrice__c = 5225;
		bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
		bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
		bundleLine.Apttus_Config2__IsPrimaryLine__c = true;
		bundleLine.Apttus_CQApprov__Approval_Status__c = 'Approval Required';

		insert bundleLine;
	}
	/**
	 * this test method is for onApply method of APT_PricingAdjustmentController
	 */
	@isTest
	static void onApplyTest(){
		Id configId = [select Id from Apttus_Config2__ProductConfiguration__c limit 1].Id;
		Id businessObjectId = [select Id from Apttus_Proposal__Proposal__c limit 1].Id;
		test.startTest();
		APT_PricingAdjustmentController.onApply(configId, businessObjectId, 'New Quote', null);
		test.stopTest();
		System.assertEquals(1,([select Id from Apttus_Proposal__Proposal__c]).size());
	}

	@isTest
	static void onApplyRevenueBillingAccTest(){
		Id configId = [select Id from Apttus_Config2__ProductConfiguration__c limit 1].Id;
		Id businessObjectId = [select Id from Apttus_Proposal__Proposal__c limit 1].Id;
		Id accId = [Select Id from Account Limit 1].Id;
		Id prodId = [Select Id from Product2 Limit 1].Id;
		Revenue_by_Billing_Account__c rvba = new Revenue_by_Billing_Account__c();
		rvba.Name = 'Test';
		rvba.Customer__c = accId;
		rvba.Product__c = prodId;
		rvba.Dec_Revenue_Amount__c  = 1000;
		rvba.Financial_Year__c = String.valueOf((system.today()).year());
		insert rvba;
		test.startTest();
		APT_PricingAdjustmentController.onApply(configId, businessObjectId, 'New Quote', null);
		test.stopTest();
		System.assertEquals(1,([select Id from Apttus_Proposal__Proposal__c]).size());
	}

	@isTest
	static void onApplyRevenueBillingAccWihtoutProdTest(){
		Id configId = [select Id from Apttus_Config2__ProductConfiguration__c limit 1].Id;
		Id businessObjectId = [select Id from Apttus_Proposal__Proposal__c limit 1].Id;
		Id accId = [Select Id from Account Limit 1].Id;
		Id prodId = [Select Id from Product2 Limit 1].Id;
		Revenue_by_Billing_Account__c rvba = new Revenue_by_Billing_Account__c();
		rvba.Name = 'Test';
		rvba.Customer__c = accId;
		// rvba.Product__c = '';
		insert rvba;
		test.startTest();
		APT_PricingAdjustmentController.onApply(configId, businessObjectId, 'New Quote', null);
		test.stopTest();
		System.assertEquals(1,([select Id from Apttus_Proposal__Proposal__c]).size());
	}


	@isTest
	static void onApplyTestNonStarTrack(){
		Id configId = [select Id from Apttus_Config2__ProductConfiguration__c limit 1].Id;
		Apttus_Proposal__Proposal__c businessObject = [select Id,Apttus_Proposal__Opportunity__c from Apttus_Proposal__Proposal__c limit 1];
		Opportunity oppy = [SELECT Id, IsStartrackProposal__c  FROM Opportunity WHERE Id = :businessObject.Apttus_Proposal__Opportunity__c limit 1];
		oppy.IsStartrackProposal__c = APT_Constants.OPTION_NO;
		update oppy;
		test.startTest();
		APT_PricingAdjustmentController.onApply(configId, businessObject.Id, 'New Quote', null);
		test.stopTest();
		System.assertEquals(1,([select Id from Apttus_Proposal__Proposal__c]).size());
	}

	/**
	 * this test method is for onReset method of APT_PricingAdjustmentController
	 */
	@isTest static void onResetTest(){
		Id configId = [select Id from Apttus_Config2__ProductConfiguration__c limit 1].Id;
		Id businessObjectId = [select Id from Apttus_Proposal__Proposal__c limit 1].Id;
		test.startTest();
		APT_PricingAdjustmentController.onReset(configId, businessObjectId, 'New Quote', null);
		test.stopTest();
		System.assertEquals(1,([select Id from Apttus_Proposal__Proposal__c]).size());
	}
	/**
	 * this test method is for getOppty method of APT_PricingAdjustmentController
	 */
	@isTest static void getOpptyTypeTest(){
		Id businessObjectId = [select Id from Apttus_Proposal__Proposal__c limit 1].Id;
		test.startTest();
		APT_PricingAdjustmentController.getOpptyType(businessObjectId);
		test.stopTest();
		System.assertEquals(1,([select Id from Apttus_Proposal__Proposal__c]).size());
	}
	/**
	 * this test method is for callReprice method of APT_PricingAdjustmentController
	 */
	@isTest static void callRePriceTest(){
		Id configId = [select Id from Apttus_Config2__ProductConfiguration__c limit 1].Id;
		test.startTest();
		APT_PricingAdjustmentController.callRePrice(configId);
		test.stopTest();
		System.assertEquals(1,([select Id from Apttus_Config2__ProductConfiguration__c]).size());
	}
	/**
	 * this test method is for onCancel method of APT_PricingAdjustmentController
	 */
	@isTest static void onCancelTest(){
		Id configId = [select Id from Apttus_Config2__ProductConfiguration__c limit 1].Id;
		test.startTest();
		APT_PricingAdjustmentController.onCancel(configId);
		test.stopTest();
		System.assertEquals(1,([select Id from Apttus_Config2__ProductConfiguration__c]).size());
	}
}