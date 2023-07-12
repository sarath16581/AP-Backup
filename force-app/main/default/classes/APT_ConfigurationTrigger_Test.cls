//Ken McGuire 2023.04.19 Proposal field migration to opportunity
@isTest
private class APT_ConfigurationTrigger_Test {
	@isTest
	public static void APT_ConfigurationTrigger1() {

		//Create Account
		Account acc = APT_TestUtils.createOrganisation();
		insert acc;


		//Create PriceList
		Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
		insert priceList;

		//create international product
		Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','APOST001','Postal Services');
		insert bundle1;

		//Create Price list Item
		Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
		insert pli;

		APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('3000', 'AUSTRALIAN NATIONAL UNIVERSITY', 'MIL', 'VC3', 'AC3');
		insert pcm1;
		//Create Opportunity
		Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
		opty.Type = 'New Customer';
		opty.IsStartrackProposal__c = 'Yes';
		opty.APTMinimumMonthlySpend__c = 1200;
		opty.APTPostcodeSuburb__c = pcm1.id;
		insert opty;
		//Create Proposal
		Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);

		insert Proposal;

		//Create Product Configuration
		Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
				proposal.Id, 'Proposal',
				'Ad Hoc',priceList.Id, null,
				'Ready For Finalization',
				null, Datetime.now(), true);
		prodconfig.Apttus_CQApprov__Approval_Status__c = APT_Constants.PROPOSAL_APPROVAL_STATUS_PENDING_APPROVAL;
		insert prodconfig;

		// Create LineItem
		Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
				1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
				null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
				'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
				'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
				true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
				5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
		bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
		bundleLine.Apttus_Config2__NetPrice__c = 5225;
		bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
		bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
		insert bundleLine;

		// create APT_Opportunity_Product_Line_Item__c
		APT_Opportunity_Product_Line_Item__c opli = new APT_Opportunity_Product_Line_Item__c();
		opli.APT_Quote_Proposal__c = Proposal.ID;
		opli.APT_Product__c = bundle1.ID;
		opli.APT_Classification__c = 'New Business';
		opli.APT_Sub_Classification__c   = 'Product Penetration';
		opli.APT_Quantity__c = 2;
		opli.APT_Unit_Sales_Price__c = 100;
		opli.APT_Revenue_Start_Date__c = System.Today() + 1;
		opli.APT_Revenue_End_Date__c = System.Today() + 100;
		opli.APT_Contract_Product__c = 'Yes';
		insert opli;

		set<Id> setProdId = new set<Id>();
		for(Product2 prod : [SELECT Id from Product2]){
			setProdId.add(prod.Id);
		}

		Test.StartTest();
		prodconfig.Apttus_Config2__BusinessObjectType__c = 'Proposal';
		prodconfig.Apttus_Config2__Status__c = 'Saved';
		prodconfig.Apttus_CQApprov__Approval_Status__c = APT_Constants.APPROVAL_STATUS_PROCESSING_APPROVAL;
		update prodconfig;
		APT_ConfigurationTriggerHandler.managePriceBookEntry(setProdId);
		delete prodconfig;
		Test.StopTest();
		system.assert(prodconfig!=null);

	}
}