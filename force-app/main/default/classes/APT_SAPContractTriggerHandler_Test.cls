/***
 * @author Mausam Padhiyar
 * @date 2016-09-16
 * @group 
 * @description This class is test class for APT_SAPContractTriggerHandler.
 * @changelog
 * 2016-09-16 - Mausam Padhiyar - Created
 * 2021-11-17 - Mathew Jose - Fixing the test method failures created by the introduction of key contact lookup filter on Opportuntiy (CI-194)
 * 2022-02-11  REQ2723568: API version 52 upgrade
 * 2023-02-03 - Ranjeewa Silva - Additional test methods to improve code coverage on legacy code sitting in APT_SAPContractTrigger.
 * 2024-01-30 - Ranjeewa Silva - Updates to existing tests to ensure test data conforms to new validation rule in APT_Sub_Account__c.
*/

@isTest
private class APT_SAPContractTriggerHandler_Test{
	public static testMethod void testingData(){
		Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
			admin.Name = 'APTS_ContentRepositoryType';
			admin.Apttus__Value__c = 'Chatter';
			insert admin;
			
			APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
			customsetting1.Name = 'APT_MSA_Service_Schedule';
			insert customsetting1;
			
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;

			Contact con= APT_TestUtils.createContact();
			con.Email = 'temp@temp.com';
			//Applying the following change as key contact have look up filter introduced on Opportunity(CI-194).  
			con.AccountId = tempacct.Id;
			insert con;
			
			APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
			sub_Account.Name = 'test';
			sub_Account.APT_Organisation__c = tempacct.Id;
			sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
			insert sub_Account;
			
			APT_Sub_Account__c sub_Account2 = new APT_Sub_Account__c();
			sub_Account2.Name = 'test';
			sub_Account2.APT_Organisation__c = tempacct.Id;
			sub_Account2.APT_Sub_Account_Request_Status__c = 'Draft';
			insert sub_Account2;
			
			List<APT_Sub_Account__c> lstsubacc = new List<APT_Sub_Account__c>();
			lstsubacc.add(sub_Account);
			lstsubacc.add(sub_Account2);
			
			Map<String,list<APT_Sub_Account__c>> mapsubacc = new Map<String,list<APT_Sub_Account__c>>();
			mapsubacc.put(String.valueOf(tempacct.Id),lstsubacc); 
			
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			opp.KeyContact__c = con.Id;
			insert opp;
			
			User u = [SELECT Id,Name,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
			
			
			//Creating new Price List Item record
			
			Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
			insert product;
			
			Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
			insert priceList;
			
			Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
			insert priceListItem;
			
			Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
			
				//create international product
				 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
				 bundle1.APT_Sync_with_Opportunity__c=true;
				 bundle1.APT_Is_Charge_Account_Product__c = true;
				 bundle1.APT_Is_Cash_Account_Product__c = false;
				 insert bundle1;
				 
				 //Create Option product
				 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','eParcelPostReturn','Postal Services','CAT1', 'Standard');
				 option.Apttus_Config2__ConfigurationType__c='Option';
				 option.APT_Sync_with_Opportunity__c=true;
				 option.APT_International_Pricing__c = false;
				 insert option;
				 
				 //Create Option product 2
				 Product2 option2 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelIdentityonDeliveryService','Postal Services','CAT1', 'Standard');
				 option2.Apttus_Config2__ConfigurationType__c='Option';
				 option2.APT_Sync_with_Opportunity__c=true;
				 option2.APT_International_Pricing__c = false;
				 insert option2;
				 
				 //Create PriceBookEntry
				 Id pricebookId = Test.getStandardPricebookId();
				 PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);
				 insert standardPrice;
				 
				 //Create Price list Item
				 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
				 insert pli;
				 //Create Option PLI
				 Apttus_Config2__PriceListItem__c optpli= APT_TestUtils.createPriceListItem(priceList.ID,option.ID,'C Manufacturing','BAND 2');
				 insert optpli;
				 
				 //Create Option PLI 2
				 Apttus_Config2__PriceListItem__c optpli2= APT_TestUtils.createPriceListItem(priceList.ID,option2.ID,'C Manufacturing','BAND 2');
				 insert optpli2;
				 
				 //Create Proposal
				 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
				 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
				 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
				 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
				 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
				 insert Proposal;
				 
				 Apttus_Proposal__Proposal__c Proposal2= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
				 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
				 Proposal2.Expected_Revenue_Start_Date__c = System.Today() - 20;
				 Proposal2.Apttus_Proposal__Approval_Stage__c = 'Accepted';
				 Proposal2.Apttus_Proposal__Opportunity__c = opp.Id;
				 insert Proposal2;
				 
				 List<Apttus_Proposal__Proposal__c> lstprop = new List<Apttus_Proposal__Proposal__c>();
				 lstprop.add(Proposal);
				 
				 //Create Product Configuration
				 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
				 proposal.Id, 'Proposal',
				 'Ad Hoc',priceList.Id, null,
				 'Finalized',
				 null, Datetime.now(), true);
				 prodconfig.Apttus_Config2__Status__c = 'Finalized';
				 insert prodconfig;
				 
			  
			   
			// Create LineItem
			Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
			1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
			null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
			'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
			'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
			true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
			5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
			bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
			bundleLine.Apttus_Config2__NetPrice__c = 5225;
			bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
			bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
			insert bundleLine;
			Test.startTest();
			//Create Option Line Item
			Apttus_Config2__LineItem__c optLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 2, false,//Config id, grpid, LineNum, isPrimary
			2,'Option', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
			option.Id, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
			'Each', 1, priceList.id, optpli.id,//Uom, term, priceList, Pli,
			'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
			true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
			5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
			optLine.Apttus_Config2__AllowManualAdjustment__c = true;
			optLine.Apttus_Config2__NetPrice__c = 5225;
			optLine.Apttus_Config2__PrimaryLineNumber__c = 1;
			optLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
			insert optLine;
			
			//Create Option Line Item 2
			Apttus_Config2__LineItem__c optLine2 = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 3, false,//Config id, grpid, LineNum, isPrimary
			3,'Option', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
			option2.Id, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
			'Each', 1, priceList.id, optpli2.id,//Uom, term, priceList, Pli,
			'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
			true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
			5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
			optLine2.Apttus_Config2__AllowManualAdjustment__c = true;
			optLine2.Apttus_Config2__NetPrice__c = 5225;
			optLine2.Apttus_Config2__PrimaryLineNumber__c = 1;
			optLine2.Apttus_Config2__NetAdjustmentPercent__c = -10;
			insert optLine2;
			
			 //Create Product Attribute value
		   // Apttus_Config2__ProductAttributeValue__c prntpav = APT_TestUtils.GetAttributeValue(bundleLine.Id,'High',true,true,true,'5674','Industry',true,true);
			//prntpav.APT_Min_Transit_Cover_Amount_Per_Article__c = 45.4;
		   // insert prntpav;
			
			
		  
		   //Create Proposal Line Item
			Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
			proposalLT1.Apttus_QPConfig__Quantity2__c=3;
			proposalLT1.APT_Charge_Code_Formula__c = 'some';
			proposalLT1.Apttus_QPConfig__NetPrice__c=10;
			proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
			proposalLT1.Apttus_QPConfig__OptionId__c = null;
			proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
			//proposalLT1.Apttus_QPConfig__AttributeValueId__c= prntpav.Id;
			insert proposalLT1;
			
			List<Apttus_Proposal__Proposal_Line_Item__c> lstoptptLT = new List<Apttus_Proposal__Proposal_Line_Item__c>();
			
			
			//Create Option Proposal Line Item
			Apttus_Proposal__Proposal_Line_Item__c proposaloptLT1= APT_TestUtils.getProposalLineItem(Proposal.id,optLine.id,optpli.id,bundle1.id,option.id);
			proposaloptLT1.Apttus_QPConfig__Quantity2__c=3;
			proposaloptLT1.APT_Charge_Code_Formula__c = 'some';
			proposaloptLT1.Apttus_QPConfig__NetPrice__c=10;
			proposaloptLT1.Apttus_QPConfig__IsPrimaryLine__c = false;
			proposaloptLT1.Apttus_QPConfig__OptionId__c = option.id;
			proposaloptLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
			proposaloptLT1.Apttus_QPConfig__ChargeType__c = 'Parcel Post Call for Returns - Delivery Fee (per article)';
			lstoptptLT.add(proposaloptLT1);
			
			//Create Option Proposal Line Item 2
			Apttus_Proposal__Proposal_Line_Item__c proposaloptLT2= APT_TestUtils.getProposalLineItem(Proposal.id,optLine2.id,optpli2.id,bundle1.id,option2.id);
			proposaloptLT2.Apttus_QPConfig__Quantity2__c=3;
			proposaloptLT2.APT_Charge_Code_Formula__c = 'some';
			proposaloptLT2.Apttus_QPConfig__NetPrice__c=10;
			proposaloptLT2.Apttus_QPConfig__IsPrimaryLine__c = false;
			proposaloptLT2.Apttus_QPConfig__OptionId__c = option2.id;
			proposaloptLT2.Apttus_QPConfig__ParentBundleNumber__c = 1;
			proposaloptLT2.Apttus_QPConfig__ChargeType__c = 'Parcel Post Call for Returns - Pick-up Fee (per request)';
			lstoptptLT.add(proposaloptLT2);
			insert lstoptptLT;
			
			//APT_SAP_Group_Template__c
			APT_SAP_Group_Template__c sgt = new APT_SAP_Group_Template__c();
			sgt.Name = 'test';
			sgt.APT_Charge_Code__c = 'some';
			sgt.APT_Price_Value_Description__c = '100';
			sgt.APT_Price_Value__c = '100';
			insert sgt;
			
			APT_SAP_Group_Template__c sgt2 = new APT_SAP_Group_Template__c();
			sgt2.Name = 'test';
			sgt2.APT_Charge_Code__c = 'some';
			sgt2.APT_Price_Value_Description__c = '100';
			sgt2.APT_Price_Value__c = '100';
			insert sgt2;
			
			String sgtid = sgt.Id; 
			sgt = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
					APT_SAP_Group_Template__c where id =: sgtid];
					
			String sgt2id = sgt2.Id; 
			sgt2 = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
					APT_SAP_Group_Template__c where id =: sgt2id];
			
			//Create product Attribute value
			Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
			attribute1.APT_Min_Transit_Cover_Amount_Per_Article__c = 45.4;
			attribute1.APT_Domestic_Customer__c = 'No';
			attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
			attribute1.APT_Minimum_Quantity__c = 0;
			insert attribute1;
			
			proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.Id;
			update proposalLT1;
		   // proposalLT1.Apttus_QPConfig__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c = attribute1.APT_Min_Transit_Cover_Amount_Per_Article__c;
			//update proposalLT1;
			
			
			List<Apttus_Proposal__Proposal_Line_Item__c> lstoptpli = [Select Id,Apttus_QPConfig__ChargeType__c,Apttus_QPConfig__OptionId__r.ProductCode,Apttus_QPConfig__NetPrice__c from Apttus_Proposal__Proposal_Line_Item__c where Apttus_QPConfig__OptionId__c != null];
			
		   
			//Apttus_QPConfig__ProposalUsagePriceTier__c
			Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
			pupt.Apttus_QPConfig__Sequence__c = 1;
			pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
			pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
			pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
			pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
			pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
			insert pupt;
			
		   
		Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			aptContract.APT_Product__c= 'eParcel' ;
			aptContract.Apttus__Related_Opportunity__c=opp.Id;
			aptContract.Apttus__Account__c=tempacct.Id;
			aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
			aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
			aptContract.Ownerid=u.id;
			aptContract.Apttus__Status__c = 'Fully Signed';
			aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
			aptContract.APT_New_Rate_Card_Download__c = true;
			insert aptContract;
		APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
			asi.APT_Organisation__c = tempacct.Id;
			asi.APT_Contract__c = aptContract.ID;
			asi.Name = '1';
			
			insert asi;
		 Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
			pupt2.Apttus_QPConfig__Sequence__c = 1;
			pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
			pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
			pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
			pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
			pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
			insert pupt2;
		Test.stopTest();
	}
	
	public static testMethod void testSAPCon(){
		// Create test contact
		Contact con= APT_TestUtils.createContact();
		insert con;
		
		// Create test account
		Account tempacct = APT_TestUtils.createOrganisation();
		insert tempacct;
		
		// Create test opportunity
		List<Opportunity> oppList = new List<Opportunity>();
		Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
		oppList.add(opp);
		Opportunity opp2 = APT_TestUtils.createOpportunity(tempacct.id);
		oppList.add(opp2);
		insert oppList;
		
		// Create test agreement
		List<Apttus__APTS_Agreement__c> agList = new List<Apttus__APTS_Agreement__c>();
		Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
		aptContract.APT_Product__c= 'eParcel' ;
		aptContract.Apttus__Related_Opportunity__c=opp.Id;
		aptContract.Apttus__Account__c=tempacct.Id;
		agList.add(aptContract);
			
		Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(con.Id);
		aptContract2.APT_Product__c= 'eParcel' ;
		aptContract2.Apttus__Related_Opportunity__c=opp2.Id;
		aptContract2.Apttus__Account__c=tempacct.Id;
		agList.add(aptContract2);
		
		insert agList;
		
		APT_SAP_Contracts__c sapContract = new APT_SAP_Contracts__c();
		sapContract.APT_Apttus_Contract__c = aptContract.Id;
		sapContract.APT_SAP_Contract_Number__c = '1234567';
		
		test.startTest();
			// Create sap contract for before and after insert
			insert sapContract;
		
			// Update sap contract for before and after update
			sapContract.SAP_Contract_Status__c = 'Active';
			sapContract.APT_Apttus_Contract__c = aptContract2.Id;
			update sapContract;
		
			// Delete sap contract for before delete 
			delete sapContract;
		test.stopTest();
	}

	/**
	 * Asserts the behaviour when an exception is thrown from related Apttus Contract update when a SAP Contract is deleted.
	 * NOTE: This test is mainly to improve cde coverage on legacy code sitting in APT_SAPContractTrigger so the trigger is deployable.
	 *	   Legacy code in APT_SAPContractTrigger needs to be refactored when there is budget for regression testing !!!
	 */
	@IsTest
	static void testDeletingSAPContractWhenApttusContractUpdateThrowsException() {
		// =====================================
		// Data Preparation
		// =====================================

		// this test inserts a APT_SAP_Contracts__c record and attempts to verify behaviour of the  code currently
		// sitting in the APT_SAPContractTrigger (legacy code). we do not want the domain trigger code to be executed here
		// as that has been tested separately. disabling domain trigger handler below.
		SystemSwitch__c settings = new SystemSwitch__c(DisableTriggers__c = true, ObjectTriggersToBeDisabled__c= 'APT_SAP_Contracts__c');
		insert settings;

		Contact contact = APT_TestUtils.createContact();
		insert contact;

		Account account = APT_TestUtils.createOrganisation();
		insert account;

		// Create test opportunity
		Opportunity opportunity = APT_TestUtils.createOpportunity(account.id);
		insert opportunity;

		Apttus__APTS_Agreement__c apttusContract = APT_TestUtils.createAgreement(contact.Id);
		apttusContract.APT_Product__c = 'eParcel' ;
		apttusContract.Apttus__Related_Opportunity__c = opportunity.Id;
		apttusContract.Apttus__Account__c = account.Id;
		insert apttusContract;

		APT_SAP_Contracts__c sapContract = new APT_SAP_Contracts__c();
		sapContract.APT_Apttus_Contract__c = apttusContract.Id;
		sapContract.APT_SAP_Contract_Number__c = '1234567';
		insert sapContract;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenThrow(new MockException('mock exception message'));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Database.DeleteResult result = Database.delete(sapContract, false);

		Test.stopTest();

		System.assertEquals(false, result.isSuccess(), 'SAP Contract deletion is expected to fail when related apttus contract update throws exception');

	}

	/**
	 * Asserts the behaviour when an exception is thrown from related Apttus Contract update when a SAP Contract is deleted.
	 * NOTE: This test is mainly to improve cde coverage on legacy code sitting in APT_SAPContractTrigger so the trigger is deployable.
	 *	   Legacy code in APT_SAPContractTrigger needs to be refactored when there is budget for regression testing !!!
	 */
	@IsTest
	static void testInsertingSAPContractWhenApttusContractUpdateThrowsException() {
		// =====================================
		// Data Preparation
		// =====================================

		// this test inserts a APT_SAP_Contracts__c record and attempts to verify behaviour of the  code currently
		// sitting in the APT_SAPContractTrigger (legacy code). we do not want the domain trigger code to be executed here
		// as that has been tested separately. disabling domain trigger handler below.
		SystemSwitch__c settings = new SystemSwitch__c(DisableTriggers__c = true, ObjectTriggersToBeDisabled__c= 'APT_SAP_Contracts__c');
		insert settings;

		Contact contact = APT_TestUtils.createContact();
		insert contact;

		Account account = APT_TestUtils.createOrganisation();
		insert account;

		// Create test opportunity
		Opportunity opportunity = APT_TestUtils.createOpportunity(account.id);
		insert opportunity;

		Apttus__APTS_Agreement__c apttusContract = APT_TestUtils.createAgreement(contact.Id);
		apttusContract.APT_Product__c = 'eParcel' ;
		apttusContract.Apttus__Related_Opportunity__c = opportunity.Id;
		apttusContract.Apttus__Account__c = account.Id;
		insert apttusContract;

		APT_SAP_Contracts__c sapContract = new APT_SAP_Contracts__c();
		sapContract.APT_Apttus_Contract__c = apttusContract.Id;
		sapContract.APT_SAP_Contract_Number__c = '1234567';


		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenThrow(new MockException('mock exception message'));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Database.SaveResult result = Database.insert(sapContract, false);

		Test.stopTest();

		System.assertEquals(false, result.isSuccess(), 'SAP Contract insert is expected to fail when related apttus contract update throws exception');

	}

	private class MockException extends Exception{}
}