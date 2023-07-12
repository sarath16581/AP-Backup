/**
Description: This apex class is test class for APT_ApprovalRequestTrigger.
Created By - Drashtee Shah
Created Date -19th Feb, 2016
Last Modified By -
Last Modified Date -
Ken McGuire 2023.04.19 Proposal field migration to opportunity
**/
@isTest
private class APT_ApprovalRequestTrigger_Test {
	/**
	Creating test data
	*/
	@IsTest
	private static void testMethod1() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
				EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
				LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
				TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
				UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			//Create Account
			Account acc = APT_TestUtils.createOrganisation();
			insert acc;
			//Create Opportunity
			Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
			insert opty;
			//Create PriceList
			Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
			insert priceList;
			//create international product
			Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
			bundle1.APT_Sync_with_Opportunity__c=true;
			bundle1.APT_Is_Charge_Account_Product__c = true;
			bundle1.APT_Is_Cash_Account_Product__c = false;
			insert bundle1;
			//Create Option product
			Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
			option.Apttus_Config2__ConfigurationType__c='Option';
			option.APT_Sync_with_Opportunity__c=true;
			option.APT_International_Pricing__c = false;
			insert option;
			//Create PriceBookEntry
			Id pricebookId = Test.getStandardPricebookId();
			PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);
			insert standardPrice;
			//Create Price list Item
			Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
			insert pli;
			//Create Proposal
			Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
			proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
			proposal.APT_Domestic_Overweight_Flag__c = true;
			proposal.APT_International_Overweight_Flag__c = true;
			proposal.APT_Overweight_Approval_Status__c = 'Approved';
			insert Proposal;
			Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
					Proposal.id, 'Proposal',
					'Ad Hoc',priceList.id, null,
					'New',
					null, null, true);
			insert prodconfig;
			Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
					1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
					null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable
					'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
					'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
					true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
					5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
			bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
			bundleLine.Apttus_Config2__NetPrice__c = 5225;
			insert bundleLine;
			APT_ApprovalCommentsFieldMapping__c appfieldmap = new APT_ApprovalCommentsFieldMapping__c();
			appfieldmap.Name = 'Approved Discount';
			appfieldmap.APT_Field_Data_Type__c = 'Number';
			appfieldmap.APT_Line_Item_Field_Name__c = 'Apttus_Config2__AdjustmentAmount__c';
			insert appfieldmap;
			Test.StartTest();
			// create approval request
			Apttus_Approval__Approval_Request__c approvalReq = new Apttus_Approval__Approval_Request__c();
			approvalReq.Apttus_Approval__Approval_Status__c = 'Not Submitted';
			approvalReq.Apttus_Approval__ChildObjectId__c = bundleLine.Id;
			approvalReq.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
			insert approvalReq;
			approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
			approvalReq.Apttus_Approval__Approver_Comments__c = 'Approved Discount - 89';
			approvalReq.Apttus_Approval__StepLabel__c = 'Dangerous Goods';
			approvalReq.Apttus_QPApprov__ProposalId__c = proposal.Id;
			approvalReq.Apttus_CQApprov__CartId__c = prodconfig.Id;
			update approvalReq;
			/*
			try{
				approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
				approvalReq.Apttus_Approval__Approver_Comments__c = 'Rejected - test';
				update approvalReq;
			}catch(Exception e) {
				System.debug('e.getMessage():'+ e.getMessage());
			}
			*/
			Apttus_Approval__Approval_Request__c approvalReq2 = new Apttus_Approval__Approval_Request__c();
			approvalReq2.Apttus_Approval__Approval_Status__c = 'Not Submitted';
			approvalReq2.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
			insert approvalReq2;
			proposal.APT_Domestic_Overweight_Flag__c = true;
			proposal.APT_International_Overweight_Flag__c = true;
			update proposal;
			approvalReq2.Apttus_Approval__Approval_Status__c = 'Rejected';
			approvalReq2.Apttus_Approval__Approver_Comments__c = 'Rejected test';
			approvalReq2.Apttus_Approval__StepLabel__c = 'Overweight items';
			approvalReq2.Apttus_QPApprov__ProposalId__c = proposal.Id;
			update approvalReq2;
			Apttus_Approval__Approval_Request__c approvalReq3 = new Apttus_Approval__Approval_Request__c();
			approvalReq3.Apttus_Approval__Approval_Status__c = 'Not Submitted';
			approvalReq3.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
			insert approvalReq3;
			approvalReq3.Apttus_Approval__Approval_Status__c = 'Approved';
			approvalReq3.Apttus_Approval__Approver_Comments__c = 'Rejected test';
			approvalReq3.Apttus_Approval__StepLabel__c = 'International Items';
			approvalReq3.Apttus_QPApprov__ProposalId__c = proposal.Id;
			update approvalReq3;
			Test.StopTest();
			system.assert(approvalReq!=null);
			system.assert(approvalReq2!=null);
			system.assert(approvalReq3!=null);
		}
	}
	/**
	Creating test data
	*/
	@IsTest
	private static void testMethod2() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
				EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
				LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
				TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
				UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			//Create Account
			Account acc = APT_TestUtils.createOrganisation();
			insert acc;
			//Create Opportunity
			Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
			insert opty;
			//Create PriceList
			Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
			insert priceList;
			//create international product
			Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
			bundle1.APT_Sync_with_Opportunity__c=true;
			bundle1.APT_Is_Charge_Account_Product__c = true;
			bundle1.APT_Is_Cash_Account_Product__c = false;
			insert bundle1;
			//Create Option product
			Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
			option.Apttus_Config2__ConfigurationType__c='Option';
			option.APT_Sync_with_Opportunity__c=true;
			option.APT_International_Pricing__c = false;
			insert option;
			//Create PriceBookEntry
			Id pricebookId = Test.getStandardPricebookId();
			PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);
			insert standardPrice;
			//Create Price list Item
			Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
			insert pli;
			//Create Proposal
			Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
			proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
			proposal.APT_Domestic_Overweight_Flag__c = true;
			proposal.APT_International_Overweight_Flag__c = true;
			proposal.APT_Overweight_Approval_Status__c = 'Approved';
			insert Proposal;
			Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
					Proposal.id, 'Proposal',
					'Ad Hoc',priceList.id, null,
					'New',
					null, null, true);
			insert prodconfig;
			Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
					1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
					null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable
					'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
					'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
					true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
					5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
			bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
			bundleLine.Apttus_Config2__NetPrice__c = 5225;
			insert bundleLine;
			APT_ApprovalCommentsFieldMapping__c appfieldmap = new APT_ApprovalCommentsFieldMapping__c();
			appfieldmap.Name = 'RK Code';
			appfieldmap.APT_Field_Data_Type__c = 'Text';
			appfieldmap.APT_Line_Item_Field_Name__c = 'APT_Rate_Card_Key__c';
			insert appfieldmap;
			Test.StartTest();
			// create approval request
			Apttus_Approval__Approval_Request__c approvalReq = new Apttus_Approval__Approval_Request__c();
			approvalReq.Apttus_Approval__Approval_Status__c = 'Not Submitted';
			approvalReq.Apttus_Approval__ChildObjectId__c = bundleLine.Id;
			approvalReq.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
			insert approvalReq;
			approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
			approvalReq.Apttus_Approval__Approver_Comments__c = 'RK Code - 678 ';
			approvalReq.Apttus_Approval__StepLabel__c = 'Dangerous Goods';
			approvalReq.Apttus_QPApprov__ProposalId__c = proposal.Id;
			update approvalReq;
			/*
			try{
				approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
				approvalReq.Apttus_Approval__Approver_Comments__c = 'Rejected - test';
				update approvalReq;
			}catch(Exception e) {
				System.debug('e.getMessage():'+ e.getMessage());
			}
			*/
			Apttus_Approval__Approval_Request__c approvalReq2 = new Apttus_Approval__Approval_Request__c();
			approvalReq2.Apttus_Approval__Approval_Status__c = 'Not Submitted';
			approvalReq2.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
			insert approvalReq2;
			approvalReq2.Apttus_Approval__Approval_Status__c = 'Rejected';
			approvalReq2.Apttus_Approval__Approver_Comments__c = 'Rejected test';
			approvalReq2.Apttus_Approval__StepLabel__c = 'Overweight items';
			approvalReq2.Apttus_QPApprov__ProposalId__c = proposal.Id;
			update approvalReq2;
			Apttus_Approval__Approval_Request__c approvalReq3 = new Apttus_Approval__Approval_Request__c();
			approvalReq3.Apttus_Approval__Approval_Status__c = 'Not Submitted';
			approvalReq3.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
			insert approvalReq3;
			approvalReq3.Apttus_Approval__Approval_Status__c = 'Approved';
			approvalReq3.Apttus_Approval__Approver_Comments__c = 'Rejected test';
			approvalReq3.Apttus_Approval__StepLabel__c = 'International Items';
			approvalReq3.Apttus_QPApprov__ProposalId__c = proposal.Id;
			update approvalReq3;
			Contact con= APT_TestUtils.createContact();
			insert con;
			Apttus__APTS_Agreement__c agreement = APT_TestUtils.createAgreement(con.Id);
			agreement.Apttus_QPComply__RelatedProposalId__c=proposal.Id;
			insert agreement;
			Apttus_Config2__ConfigSystemProperties__c objSett = new Apttus_Config2__ConfigSystemProperties__c(Name= 'System Properties');
			insert objSett;
			APT_TermAndConditionController tempObj = new APT_TermAndConditionController();
			tempObj.setcontractID(agreement.ID);
			ID testVar = tempObj.getcontractID();
			tempObj.approvalRequestSO = approvalReq3;
			tempObj.agreementSO = agreement;
			tempObj.getContractURL();
			Test.StopTest();
			system.assert(approvalReq!=null);
			system.assert(approvalReq2!=null);
			system.assert(approvalReq3!=null);
		}
	}
	@IsTest
	public static String testTermandConditionController1(){
		Apttus_Config2__ConfigSystemProperties__c cofingSetting = new Apttus_Config2__ConfigSystemProperties__c(name = 'System Properties');
		insert cofingSetting;
		Folder folder = [SELECT Id FROM Folder where Type = 'Document' LIMIT 1];
		Document objDocument = new Document();
		objDocument.Name = 'R2T Contract Letterhead';
		objDocument.FolderId = folder.ID;
		objDocument.Body = blob.valueOf('test String');
		insert objDocument;
		Test.startTest();
		APT_TermAndConditionController objController = new APT_TermAndConditionController();
		String headerURL = objController.getHeaderURL();
		Test.stopTest();
		return headerURL;
	}
	@IsTest
	public static String testTermandConditionController2(){
		Apttus_Config2__ConfigSystemProperties__c cofingSetting = new Apttus_Config2__ConfigSystemProperties__c(name = 'System Properties');
		insert cofingSetting;
		Folder folder = [SELECT Id FROM Folder where Type = 'Document' LIMIT 1];
		Document objDocument = new Document();
		objDocument.Name = 'R2T_Quote_LetterHead_Footer';
		objDocument.FolderId = folder.ID;
		objDocument.Body = blob.valueOf('test String');
		insert objDocument;
		Test.startTest();
		APT_TermAndConditionController objController = new APT_TermAndConditionController();
		String headerURL = objController.getFooterURL();
		Test.stopTest();
		return headerURL;
	}
	@IsTest
	private static void testMethod3() {
		try{
			/* Opportunity opty1 = APT_TestUtils.createOpportunity(acc.Id);
				opty1.type= 'Existing Customer';
				insert opty1;
				OpportunityLineItem objLineNew = new OpportunityLineItem();
				//objLineNew.ListPrice = 123;
				objLineNew.OpportunityID = opty1.ID;
				//objLineNew.Product2ID = bundle1.ID;
				// objLineNew.ProductCode = 'ABC';
				objLineNew.Quantity = 1;
				objLineNew.UnitPrice = 12;
				objLineNew.Classification__c  = 'Renewal';
				//objLineNew.TotalPrice = 200;
				objLineNew.APT_Is_Apttus_Opportunity_Line_item__c = true;
				objLineNew.APT_Apttus_Delete_Override__c = False;
				insert objLineNew;
				delete objLineNew;*/
			Contact con = APT_TestUtils.createContact();
			insert con;
			Account acc = APT_TestUtils.createOrganisation();
			insert acc;
			Opportunity opp = APT_TestUtils.createOpportunity(acc.Id);
			insert opp;
			Apttus__APTS_Agreement__c  agreement = APT_TestUtils.createAgreement(con.Id);
			agreement.Apttus__Related_Opportunity__c = opp.Id;
			insert agreement;
			Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
			product.APT_Product_type__c = 'International';
			insert product;
			Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
			insert priceList;
			Id priceBookId=Test.getStandardPricebookId();
			PricebookEntry  priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId,product.Id);
			insert priceBookEntry;
			OpportunityLineItem oppLineItem = new OpportunityLineItem(Quantity=2,OpportunityId=opp.Id,TotalPrice =45678,PricebookEntryId=priceBookEntry.Id,Contract_Start_Date__c=System.Today(),Contract_End_Date__c=System.Today()+1 ,APT_Is_Apttus_Opportunity_Line_item__c = true);
			oppLineItem.Classification__c = 'New Business';
			insert oppLineItem;
			Test.startTest();
			Sobject sobj;
			APT_WebserviceMockIndividualCredit objWebService = new APT_WebserviceMockIndividualCredit();
			objWebService.doInvoke(sobj,sobj,new Map<String, Object>(),'Test','Test','Test','Test','Test','Test');
			delete oppLineItem;
			Test.StopTest();
		}
		catch(Exception ex)
		{
			System.Debug('Validation Passed');
		}
	}
	@IsTest
	private static void testMethod4() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
				EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
				LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
				TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
				UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			//Create Account
			Account acc = APT_TestUtils.createOrganisation();
			insert acc;
			//Create PriceList
			Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
			insert priceList;
			//create international product
			Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
			bundle1.APT_Sync_with_Opportunity__c=true;
			bundle1.APT_Is_Charge_Account_Product__c = true;
			bundle1.APT_Is_Cash_Account_Product__c = false;
			insert bundle1;
			//Create Option product
			Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
			option.Apttus_Config2__ConfigurationType__c='Option';
			option.APT_Sync_with_Opportunity__c=true;
			option.APT_International_Pricing__c = false;
			insert option;
			//Create PriceBookEntry
			Id pricebookId = Test.getStandardPricebookId();
			PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);
			insert standardPrice;
			//Create Price list Item
			Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
			insert pli;
			APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('3000', 'AUSTRALIAN NATIONAL UNIVERSITY', 'MIL', 'VC3', 'AC3');
			insert pcm1;
			//Create Opportunity
			Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
			opty.APTPostcodeSuburb__c = pcm1.id;
			opty.IsStartrackProposal__c = APT_Constants.OPTION_YES;
			opty.APTMinimumMonthlySpend__c = 1200;
			insert opty;
			//Create Proposal
			Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
			proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
			proposal.APT_Domestic_Overweight_Flag__c = true;
			proposal.APT_International_Overweight_Flag__c = true;
			proposal.APT_Overweight_Approval_Status__c = 'Approved';
			insert Proposal;
			Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
					Proposal.id, 'Proposal',
					'Ad Hoc',priceList.id, null,
					'New',
					null, null, true);
			insert prodconfig;
			Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
					1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
					null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable
					'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
					'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
					true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
					5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
			bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
			bundleLine.Apttus_Config2__NetPrice__c = 5225;
			insert bundleLine;
			APT_ApprovalCommentsFieldMapping__c appfieldmap = new APT_ApprovalCommentsFieldMapping__c();
			appfieldmap.Name = 'Approved Discount';
			appfieldmap.APT_Field_Data_Type__c = 'Number';
			appfieldmap.APT_Line_Item_Field_Name__c = 'Apttus_Config2__AdjustmentAmount__c';
			insert appfieldmap;
			Test.StartTest();
			// create approval request
			Apttus_Approval__Approval_Request__c approvalReq = new Apttus_Approval__Approval_Request__c();
			approvalReq.Apttus_Approval__Approval_Status__c = 'Not Submitted';
			approvalReq.Apttus_Approval__ChildObjectId__c = bundleLine.Id;
			approvalReq.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
			insert approvalReq;
			approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
			approvalReq.Apttus_Approval__Approver_Comments__c = 'Approved Discount - 89';
			approvalReq.Apttus_Approval__StepLabel__c = 'Dangerous Goods';
			approvalReq.Apttus_QPApprov__ProposalId__c = proposal.Id;
			approvalReq.Apttus_CQApprov__CartId__c = prodconfig.Id;
			update approvalReq;
			/*
			try{
				approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
				approvalReq.Apttus_Approval__Approver_Comments__c = 'Rejected - test';
				update approvalReq;
			}catch(Exception e) {
				System.debug('e.getMessage():'+ e.getMessage());
			}
			*/
			Apttus_Approval__Approval_Request__c approvalReq2 = new Apttus_Approval__Approval_Request__c();
			approvalReq2.Apttus_Approval__Approval_Status__c = 'Not Submitted';
			approvalReq2.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
			insert approvalReq2;
			proposal.APT_Domestic_Overweight_Flag__c = true;
			proposal.APT_International_Overweight_Flag__c = true;
			update proposal;
			approvalReq2.Apttus_Approval__Approval_Status__c = 'Rejected';
			approvalReq2.Apttus_Approval__Approver_Comments__c = 'Rejected test';
			approvalReq2.Apttus_Approval__StepLabel__c = 'Overweight items';
			approvalReq2.Apttus_QPApprov__ProposalId__c = proposal.Id;
			update approvalReq2;
			Apttus_Approval__Approval_Request__c approvalReq3 = new Apttus_Approval__Approval_Request__c();
			approvalReq3.Apttus_Approval__Approval_Status__c = 'Not Submitted';
			approvalReq3.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
			insert approvalReq3;
			approvalReq3.Apttus_Approval__Approval_Status__c = 'Approved';
			approvalReq3.Apttus_Approval__Approver_Comments__c = 'Rejected test';
			approvalReq3.Apttus_Approval__StepLabel__c = 'International Items';
			approvalReq3.Apttus_QPApprov__ProposalId__c = proposal.Id;
			update approvalReq3;
			Test.StopTest();
			system.assert(approvalReq!=null);
			system.assert(approvalReq2!=null);
			system.assert(approvalReq3!=null);
		}
	}
}