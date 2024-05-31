/**
*This apex class is test class for APT_AmendRenewController
*@changelog:
*2022-10-05	seth.heang@auspost.com.au	uplift API version to 55
*2023-06-08 nasir.jawed2@auspost.com.au added a new method testDovUpdateOnOpportunity to test
*2024-02-06 mahesh.parvathaneni@auspost.com.au Added test methods testInvalidDSRErrorForDovIncreaseAndRenewal and testOppDSRErrorForDovIncreaseAndRenewal
*/
@isTest
private class APT_AmendRenewController_Test{
	/*
	This method will Create agreements.
	it will also creates temporary data of contact,account,opportunity, pricelist, proposal,configuration object.
	@params -
	action - Name of Action

	*/
	private static void testingData(String action){

			Contact con = APT_TestUtils.createContact();
			insert con;

			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;

			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			insert opp;

			Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
			insert product;

			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;

			Id priceBookId=Test.getStandardPricebookId();
			PricebookEntry priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId,product.Id);
			insert priceBookEntry;

			OpportunityLineItem oppLineItem = new OpportunityLineItem(Quantity=2,OpportunityId=opp.Id,TotalPrice =45678,PricebookEntryId=priceBookEntry.Id,Contract_Start_Date__c=System.Today(),Contract_End_Date__c=System.Today()+1 );
			oppLineItem.Classification__c = 'New Business';
			insert oppLineItem;

			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c = System.today() + 2;
			insert quote;

			APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
			insert sysProperties;

			Id renewalRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Renewal Quote').getRecordTypeId();

			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			aptContract.Apttus__Related_Opportunity__c =opp.id;
			aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;

			Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtil2.getProductConfiguration('Product Configuration', 1,
						quote.Id, 'Proposal','Ad Hoc',
						priceList.Id, null,'New',null,
						Datetime.now(), true);

				insert prodconfig;

			Apttus_Config2__PriceListItem__c pli2 = APT_TestUtil2.createPriceListItem(priceList.ID,product.ID,'C Manufacturing','BAND 2');
			insert pli2;

			// Eparcel Express Configuration Line Item
				Apttus_Config2__LineItem__c DomesticVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
						1, 'Product/Service', product.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
						null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
						'Each', 1, priceList.Id, pli2.Id,//Uom, term, priceList, Pli,
						'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
						true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
						5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc

			insert DomesticVarCLI;

			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',action);
			ApexPages.currentPage().getParameters().put('selectedCategory','Add new product to non-aligned contract');

	}
	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.

	*/
	@IsTest
	private static void testingAPT_AmendRenewController(){
		 // Setup test data
		// This code runs as the system admin test user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {

			testingData(APT_Constants.ACTION_NAME_RENEW);

			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=true,
																	APT_Create_Case__c=true,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_TYPE_RENEWAL,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;

			Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getTextmessage();
			amendRenew.textmessage();
			amendRenew.getCategories();
			amendRenew.doCancel();
			amendRenew.doRenew();
			amendRenew.doAmend();

			renewDoVProperties.APT_Create_Agrement__c=false;
			renewDoVProperties.APT_Create_Quote__c=false;
			update renewDoVProperties ;

			PageReference pgRef = amendRenew.doAmend();


			Test.stopTest();
			system.assert(pgRef == null);
		}
	}
	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.

	*/
	@IsTest
	private static void testActionAPT_AmendRenewController1(){
		 // Setup test data
		// This code runs as the system admin test user

		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);

		System.runAs(testuser) {

		testingData(APT_Constants.ACTION_NAME_DoV);
		APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample1',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=false,
																APT_Create_Case__c=false,APT_Create_Quote__c=false,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=false);
		insert renewDoVProperties ;
		Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getCategories();
			amendRenew.doCancel();
			amendRenew.doRenew();
			renewDoVProperties.APT_Create_Quote__c=false;
			renewDoVProperties.APT_Create_Case__c=false;
			renewDoVProperties.APT_Create_Agrement__c=true;
			update renewDoVProperties;
			amendRenew.DoVProperties = renewDoVProperties;
			amendRenew.doAmend();


			renewDoVProperties.APT_Create_Quote__c=true;
			renewDoVProperties.APT_Create_Agrement__c=true;
			renewDoVProperties.APT_Create_Case__c=false;
			update renewDoVProperties;
			amendRenew.DoVProperties = renewDoVProperties;
			amendRenew.doAmend();

			renewDoVProperties.APT_Create_Quote__c=false;
			renewDoVProperties.APT_Create_Agrement__c=true;
			renewDoVProperties.APT_Create_Case__c=true;
			update renewDoVProperties;
			amendRenew.DoVProperties = renewDoVProperties;
			amendRenew.doAmend();

			amendRenew.selectedCategory='Proposal and Contract Flow';
			amendRenew.selectedRevenue='None';
			amendRenew.doAmend();

			renewDoVProperties.APT_Create_Quote__c=false;
			renewDoVProperties.APT_Create_Agrement__c=false;
			renewDoVProperties.APT_Create_Case__c=false;
			renewDoVProperties.APT_Create_Opportunity__c=true;
			update renewDoVProperties;
			amendRenew.DoVProperties = renewDoVProperties;
			amendRenew.selectedRevenue='Decrease Revenue';
			amendRenew.doAmend();

			amendRenew.selectedCategory='';
			amendRenew.doRenew();
			//PageReference pgRef = amendRenew.doAmend();

			Apttus__APTS_Agreement__c contract2 = [Select id from Apttus__APTS_Agreement__c limit 1];
			//contract2.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
			delete contract2;
			//system.debug('>>> contract2.Apttus_QPComply__RelatedProposalId__c: ' + contract2.Apttus_QPComply__RelatedProposalId__c);
			PageReference pgRef =  amendRenew.doRenew();

			Test.stopTest();
			system.assertEquals(null,pgRef);
		}
	}

	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.

	*/
	@IsTest
	private static void testActionAPT_AmendRenewController3(){
		// Setup test data
		// This code runs as the system admin test user

		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);

		System.runAs(testuser) {

		testingData(APT_Constants.ACTION_NAME_DoV);
		APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample1',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=false,
																APT_Create_Case__c=true,APT_Create_Quote__c=false,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=false);
		insert renewDoVProperties ;
		Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getCategories();

			renewDoVProperties.APT_Create_Quote__c=false;
			update renewDoVProperties;
			amendRenew.doAmend();
			renewDoVProperties.APT_Create_Case__c=false;
			update renewDoVProperties;
			amendRenew.doAmend();

			renewDoVProperties.APT_Create_Quote__c=false;
			renewDoVProperties.APT_Create_Case__c=false;
			renewDoVProperties.APT_Create_Agrement__c=true;
			renewDoVProperties.APT_Create_Opportunity__c=false;
			update renewDoVProperties;
			amendRenew.DoVProperties = renewDoVProperties;
			amendRenew.doRenew();
			PageReference pgRef = amendRenew.doAmend();

			//PageReference pgRef = amendRenew.doAmend();


			Test.stopTest();
			system.assertEquals(null,pgRef);
	 }
	}

	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.
	*/
	@IsTest
	private static void testActionAPT_AmendRenewController2(){
		// Setup test data
		// This code runs as the system admin test user


		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);


		System.runAs(testuser) {

		testingData(APT_Constants.ACTION_NAME_DoV);
		APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample1',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=false,
																APT_Create_Case__c=true,APT_Create_Quote__c=false,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=false);
		insert renewDoVProperties ;
		Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getCategories();
			//amendRenew.doCancel();
			amendRenew.doRenew();
			renewDoVProperties.APT_Create_Case__c=true;
			renewDoVProperties.APT_Create_Agrement__c=false;
			update renewDoVProperties;
			amendRenew.doAmend();
			renewDoVProperties.APT_Create_Case__c=false;
			renewDoVProperties.APT_Create_Opportunity__c=true;
			renewDoVProperties.APT_Create_Quote__c=true;
			update renewDoVProperties;
			amendRenew.doAmend();
			renewDoVProperties.APT_Create_Quote__c=false;
			update renewDoVProperties;

			PageReference pgRef = amendRenew.doAmend();


			Test.stopTest();
			system.assertEquals(null,pgRef);
	 }
	}
	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.
	*/
	@IsTest
	private static void testnegativeAPT_AmendRenewController(){
		 // Setup test data
		// This code runs as the system admin test user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
	 System.runAs(testuser) {
			testingData(APT_Constants.ACTION_NAME_RENEW);
			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample2',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=false,
																	APT_Create_Case__c=true,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_TYPE_RENEWAL,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;
			Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getTextmessage();
			amendRenew.getCategories();
			amendRenew.doRenew();
			amendRenew.DoVProperties = renewDoVProperties;
			renewDoVProperties.APT_Create_Case__c=false;
			update renewDoVProperties;
			amendRenew.doRenew();
			renewDoVProperties.APT_Create_Quote__c=false;
			update renewDoVProperties;

			PageReference pgRef = amendRenew.doRenew();


			Test.stopTest();
			system.assertEquals(null,pgRef);
	 }
	}
	/*
	This method used for test of APT_AmendRenewController controller.
	*/
	@IsTest
	private static void testAction(){
		 // Setup test data
		// This code runs as the system admin test user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			testingData(APT_Constants.ACTION_NAME_DoV);
			Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.doAmend();
			amendRenew.selectedCategory='null';

			PageReference pgRef = amendRenew.doRenew();


			Test.stopTest();
			 system.assert(pgRef == null);
		}
	}
	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.
	*/
	@IsTest
	private static void testNullValue(){
		 // Setup test data
		// This code runs as the system admin test user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {

			testingData(APT_Constants.ACTION_NAME_DoV);
			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample1',APT_Category__c='Sample',APT_Create_Agrement__c=false,
																	APT_Create_Case__c=true,APT_Create_Quote__c=false,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=false);
			insert renewDoVProperties ;
			Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';

			String msgStr = amendRenew.getTextmessage();


			Test.stopTest();
			system.assert(msgStr != null);
		}
	}
	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.
	It will also insert temporary data of account, contact,opportunity, product,pricelist,proposal and configuration objects.
	*/
	@IsTest
	private static void doAmendsNoSysProperties(){
		 // Setup test data
		// This code runs as the system admin test user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Contact con = APT_TestUtils.createContact();
			insert con;
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			insert opp;
			Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
			insert product;
			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c = System.today() + 2;
			insert quote;
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			//aptContract.Apttus__Related_Opportunity__c =opp.id;
			aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_DoV);
			ApexPages.currentPage().getParameters().put('selectedCategory','Add new product to non-aligned contract');
			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Test',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;
			Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getTextmessage();

			PageReference pgRef = amendRenew.doAmend();


			Test.stopTest();
			system.assert(pgRef == null);
		}
	}
	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.
	It will also insert temporary data of account, contact,opportunity, product,pricelist,proposal and configuration objects.
	*/
	@IsTest
	private static void doRenewNoSysProperties(){
		 // Setup test data
		// This code runs as the system admin test user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Contact con = APT_TestUtils.createContact();
			insert con;
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;
		Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			insert opp;
			Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
			insert product;
			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c = System.today() + 2;
			insert quote;
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			//aptContract.Apttus__Related_Opportunity__c =opp.id;
			aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_RENEW);
			ApexPages.currentPage().getParameters().put('selectedCategory','Add new product to non-aligned contract');
			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Test',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_TYPE_RENEWAL,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;
			Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getTextmessage();

			PageReference pgRef = amendRenew.doRenew();


			Test.stopTest();
			system.assert(pgRef == null);
		}
	}
	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.
	It will also insert temporary data of account, contact,opportunity, product,pricelist,proposal and configuration objects.
	*/
	@IsTest
	private static void doAmendsNoRelatedQuote(){
		 // Setup test data
		// This code runs as the system admin test user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Contact con = APT_TestUtils.createContact();
			insert con;
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			insert opp;
			Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
			insert product;
			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;
			APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
			insert sysProperties;
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c = System.today() + 2;
			insert quote;
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			//aptContract.Apttus__Related_Opportunity__c =opp.id;
			//aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_DoV);
			ApexPages.currentPage().getParameters().put('selectedCategory','Add new product to non-aligned contract');
			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Test',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;
			Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getTextmessage();

			PageReference pgRef = amendRenew.doAmend();


			Test.stopTest();
			system.assert(pgRef != null);
		}
	}
	/*
	This method will insert record for custom setting 'R2T Renew DoV Properties'.
	It will also insert temporary data of account, contact,opportunity, product,pricelist,proposal and configuration objects.
	*/
	@IsTest
	private static void doRenewNoRelatedQuote(){
		 // Setup test data
		// This code runs as the system admin test user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {

			Contact con = APT_TestUtils.createContact();
			insert con;
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			insert opp;
			Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
			insert product;
			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c = System.today() + 2;
			insert quote;
			APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
			insert sysProperties;
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			//aptContract.Apttus__Related_Opportunity__c =opp.id;
			//aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_RENEW);
			ApexPages.currentPage().getParameters().put('selectedCategory','Add new product to non-aligned contract');
			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Test',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=true,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_TYPE_RENEWAL,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;

			Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getTextmessage();
			amendRenew.doRenew();
			renewDoVProperties.APT_Create_Quote__c=false;
			update renewDoVProperties;

			PageReference pgRef = amendRenew.doRenew();


			Test.stopTest();
			system.assertEquals(null,pgRef);
		}
	}
	@IsTest
	private static void testingNullAgreement(){

		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {

		testingData(APT_Constants.ACTION_NAME_RENEW);
		 ApexPages.currentPage().getParameters().put('agreementId','');
		APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample1',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=false,
																APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=false);
		insert renewDoVProperties ;
		Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getCategories();
			amendRenew.doCancel();
			amendRenew.doRenew();
		 // renewDoVProperties.APT_Create_Quote__c=true;
		 // renewDoVProperties.APT_Create_Agrement__c=false;
		 // update renewDoVProperties;
		 // amendRenew.doAmend();
			renewDoVProperties.APT_Create_Quote__c=false;
			update renewDoVProperties;
			amendRenew.doAmend();
			renewDoVProperties.APT_Create_Case__c=false;
			update renewDoVProperties;
			amendRenew.doAmend();
			renewDoVProperties.APT_Create_Case__c=true;
			renewDoVProperties.APT_Create_Agrement__c=false;
			update renewDoVProperties;
			amendRenew.doAmend();
			renewDoVProperties.APT_Create_Case__c=false;
			renewDoVProperties.APT_Create_Opportunity__c=true;
			renewDoVProperties.APT_Create_Quote__c=true;
			update renewDoVProperties;
			amendRenew.doAmend();
			renewDoVProperties.APT_Create_Quote__c=false;
			update renewDoVProperties;

			PageReference pgRef = amendRenew.doAmend();


			Test.stopTest();
			system.assertEquals(null,pgRef);
		}
	}
	@IsTest
	private static void testingOnlyQuote(){
		// Setup test data
		// This code runs as the system admin test user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {

			testingData(APT_Constants.ACTION_NAME_RENEW);

			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample',APT_Category__c='Add new product to non-aligned contract',APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_TYPE_RENEWAL,APT_Create_Opportunity__c=false);
			insert renewDoVProperties ;

			Test.startTest();

			APT_AmendRenewController amendRenew = new APT_AmendRenewController();
			amendRenew.selectedCategory='Add new product to non-aligned contract';
			amendRenew.getTextmessage();
			amendRenew.textmessage();
			amendRenew.getCategories();
			amendRenew.doCancel();
			amendRenew.doRenew();
		//amendRenew.doAmend();

		 // renewDoVProperties.APT_Create_Agrement__c=false;
		 // renewDoVProperties.APT_Create_Quote__c=false;
		 // update renewDoVProperties ;

			PageReference pgRef = amendRenew.doAmend();


			Test.stopTest();
			system.assert(pgRef == null);
	 }
	}

	/*
	 *Created By: conrad.c.v.borbon
	 *Created Date: 30/7/2018
	 *This test method will test changes for new contract Amendment flow
	 */
	@IsTest
	private static void AmendRenewControllerPropAndContr(){
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			// Setup test data
		try{
			testingData(APT_Constants.ACTION_NAME_DoV);

			// Create test custom setting for proposal and contract flow
			List<APT_R2T_Renew_DoV_Properties__c> r2tRenewDoVCSList = new List<APT_R2T_Renew_DoV_Properties__c>();
			APT_R2T_Renew_DoV_Properties__c aptFlow1 = new APT_R2T_Renew_DoV_Properties__c();
			aptFlow1.Name ='R2T Renew DoV Properties 1';
			aptFlow1.APT_Category__c = 'Proposal and Contract Flow';
			aptFlow1.APT_Create_Agrement__c = false;
			aptFlow1.APT_Create_Case__c = false;
			aptFlow1.APT_Create_Quote__c = true;
			aptFlow1.APT_Create_Opportunity__c = true;
			aptFlow1.APT_Type__c = APT_Constants.ACTION_NAME_DoV;
			aptFlow1.APT_Help_Text__c = 'Test help 1';
			r2tRenewDoVCSList.add(aptFlow1);

			APT_R2T_Renew_DoV_Properties__c aptFlow2 = new APT_R2T_Renew_DoV_Properties__c();
			aptFlow2.Name ='R2T Renew DoV Properties 2';
			aptFlow2.APT_Category__c = 'Direct to Contract Flow';
			aptFlow2.APT_Create_Agrement__c = true;
			aptFlow2.APT_Create_Case__c = false;
			aptFlow2.APT_Create_Quote__c = false;
			aptFlow2.APT_Create_Opportunity__c = false;
			aptFlow2.APT_Type__c = APT_Constants.ACTION_NAME_DoV;
			aptFlow2.APT_Help_Text__c = 'Test help 2';
			r2tRenewDoVCSList.add(aptFlow2);

			APT_R2T_Renew_DoV_Properties__c aptFlow3 = new APT_R2T_Renew_DoV_Properties__c();
			aptFlow3.Name ='R2T Renew DoV Properties 3';
			aptFlow3.APT_Category__c = 'Direct to Case Flow';
			aptFlow3.APT_Create_Agrement__c = false;
			aptFlow3.APT_Create_Case__c = true;
			aptFlow3.APT_Create_Quote__c = false;
			aptFlow3.APT_Create_Opportunity__c = false;
			aptFlow3.APT_Type__c = APT_Constants.ACTION_NAME_DoV;
			aptFlow3.APT_Help_Text__c = 'Test help 3';
			r2tRenewDoVCSList.add(aptFlow3);



			Test.startTest();
				insert r2tRenewDoVCSList;
				APT_AmendRenewController amendRenew = new APT_AmendRenewController();

				// Check that list amendment category is being pulled
				list<SelectOption> dovCatList = amendRenew.getCategories();

				for(SelectOption dovCatOpVar: dovCatList){
					if('Proposal and Contract Flow' == dovCatOpVar.getLabel()){
						system.assert( 'Proposal and Contract Flow' == dovCatOpVar.getValue());
					}else if('Direct to Contract Flow' == dovCatOpVar.getLabel()){
						system.assert( 'Direct to Contract Flow' == dovCatOpVar.getValue());
					}else if('Direct to Case Flow' == dovCatOpVar.getLabel()){
						system.assert( 'Direct to Case Flow' == dovCatOpVar.getValue());
					}
				}

				// Satisfy category required condition
				amendRenew.selectedCategory = '';
				amendRenew.doAmend();
				//system.assert(amendRenew.haserrorMessages); // Check boolean to determine if error message fired

				// Assert help text value dependent to selected category
				amendRenew.selectedCategory='Direct to Contract Flow';
				system.assert('Test help 2' == amendRenew.getTextmessage());

				amendRenew.selectedCategory='Direct to Case Flow';
				system.assert('Test help 3' == amendRenew.getTextmessage());

				amendRenew.selectedCategory='Proposal and Contract Flow';
				system.assert('Test help 1' == amendRenew.getTextmessage());

				// Check revenue type picklist value retrieve

				List<SelectOption>revenueTypeOpList = amendRenew.getRevenueType();
				for(SelectOption selecOpVar: revenueTypeOpList){
					if(APT_AmendRenewController.INCREASE_REVENUE == selecOpVar.getLabel()){
						system.assert( APT_AmendRenewController.INCREASE_REVENUE == selecOpVar.getValue());
					}else if(APT_AmendRenewController.DECREASE_REVENUE == selecOpVar.getLabel()){
						system.assert( APT_AmendRenewController.DECREASE_REVENUE == selecOpVar.getValue());
					}
				}

				// Test increase revenue scenario
				amendRenew.selectedRevenue = APT_AmendRenewController.INCREASE_REVENUE;

				// Check boolean to display Proposal and Contract Flow specific condition
				amendRenew.textmessage();
				system.assert(amendRenew.bDisplayRevenue);

				// Do Amend
				PageReference pgRef = amendRenew.doAmend();

				// Check that cloned quote is created with revenue type of increase revenue
				string quoteId = pgRef.getParameters().get(APT_Constants.PARAM_ID);
				system.assert(quoteId!=null && quoteId!='');
				Apttus_Proposal__Proposal__c clonePropVar = [Select Id, APT_Revenue_Type__c from Apttus_Proposal__Proposal__c where Id = :quoteId];
				system.assert( APT_AmendRenewController.INCREASE_REVENUE == clonePropVar.APT_Revenue_Type__c);

				// Check that view moved to agreement standard view
				system.assert(null!=amendRenew.doCancel());

				// The line below asserts that the Revenue Type picklist is not null
				system.assertNotEquals(null, amendRenew.revenueValues);
			Test.stopTest();
		 }
		 catch(exception ex){
			 system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
		 }

		}

	}
	@IsTest
	 private static void testAssociatingExistingOpportunity(){
		// Setup test data
		// This code runs as the Sales Admin User

		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser ) {

			// Creating the Custom Setting Data

			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample',APT_Category__c=APT_AmendRenewController.CATEGORY_DOV_PROPANDCONTR,APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;


			// Creating the Contact Test Data
			Contact con = APT_TestUtils.createContact();
			con.MailingCity = 'Melbourne';
			con.MailingState = 'VIC';
			con.MailingStreet = 'Flinders Street';
			con.MailingPostalCode = '3000';
			insert con;

			//Creating account test data
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;

			//Creating Opportunity Test Data
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			opp.IsStartrackProposal__c ='No';
			insert opp;

			//Creating Existing Opportunity to associate the dov Test Data
			Opportunity ExistingOpportunity = APT_TestUtils.createOpportunity(tempacct.id);
			ExistingOpportunity.IsStartrackProposal__c ='No';
			insert ExistingOpportunity ;

			//Creating Pricelist test data
			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;

			//Creating proposal test data
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c = System.today() + 2;
			insert quote;

			//creating product test data 1
			Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
			bundle1.Non_contracted__c = false;
			insert bundle1;

			//creating product test data 2
			Product2 bundle2 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST002','Postal Services');
			bundle2.APT_Sync_with_Opportunity__c = true;
			bundle2.Apttus_Config2__HasOptions__c = true;
			bundle2.Non_contracted__c = true;
			bundle2.Apttus_Config2__ConfigurationType__c = 'Bundle';
			insert bundle2;

			//Creating product configuration test data
			Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
			quote.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
			insert prodconfig;

			//Creating PLI test data
			Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
			insert pli;

			//Creating Line Item Test Data
			Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
			1, 'Product/Service', bundle2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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

			//Creating contract Test Data
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			aptContract.Apttus__Related_Opportunity__c =opp.id;
			aptContract.Apttus__Account__c = tempacct.id;
			aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;

			//Creating Default Price list id data
			APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
			insert sysProperties;

			//Setting the Current Page as DOV
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_DoV);

		 //Test starts
		 Test.startTest();
				APT_AmendRenewController amendRenew = new APT_AmendRenewController();
				amendRenew.selectedCategory=APT_AmendRenewController.CATEGORY_DOV_PROPANDCONTR;
				amendRenew.selectedRevenue='Increase Revenue';
				 /*Commented By Mansi Shah as DOV Reasons are removed from APT_AmendRenewPage*/
				//amendRenew.renderDovReasonPicklist();
				amendRenew.selectedReason='Update products/rates';
				amendRenew.lookupToOpportunity();
				amendRenew.oppId=ExistingOpportunity.id;
				amendRenew.oppName=ExistingOpportunity.name;
				amendRenew.doAmend();
			
			//Asserting whether the new proposal created is associated to an existing Opportunity
			List<Opportunity> oppList = [ Select id,ECLM_Original_Opportunity_No__c , (Select id from R00N70000001yUfDEAU__r) from Opportunity where id =: ExistingOpportunity.id];
			//Assert if the proposal is associated to the existing opportunity which user would have selected
			System.assert(oppList[0].R00N70000001yUfDEAU__r.size()>0);
			//Asserting the existing opportunity is looking up to the Original opportunity
			System.assertEquals(oppList[0].ECLM_Original_Opportunity_No__c , opp.id);
		//Test Stops
		Test.stopTest();
		}
	}

	/* Shashwat.Nath@Auspost.com.au has included this method on 10/09/2020 as part of STP- Release 2 changes to test functionality
		of creating a new opportunity on Revenue Decrease and superseding the original opportunity */
	@IsTest
	private static void testdecreaseRevenueSupersedeOriginalOpportunity(){
		// Setup test data
		// This code runs as the Sales Admin User
		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser ) {

			// Inserting the custom setting test data

			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample',APT_Category__c=APT_AmendRenewController.CATEGORY_DOV_PROPANDCONTR,APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;


			// Inserting the Contact test data
			Contact con = APT_TestUtils.createContact();
			con.MailingCity = 'Melbourne';
			con.MailingState = 'VIC';
			con.MailingStreet = 'Flinders Street';
			con.MailingPostalCode = '3000';
			insert con;

			//Inserting the Account test data
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;

			//Inserting the Opportunity Test data
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			opp.closedate = system.today();
			insert opp;

			//Inserting the Price List test data
			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;

			//Inserting the proposal test data
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c = System.today() + 2;
			insert quote;

			//Inserting the Product Test data set 1
			Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
			bundle1.Non_contracted__c = false;
			insert bundle1;

			//Inserting the product Test data set 2
			Product2 bundle2 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST002','Postal Services');
			bundle2.APT_Sync_with_Opportunity__c = true;
			bundle2.Apttus_Config2__HasOptions__c = true;
			bundle2.Non_contracted__c = true;
			bundle2.Apttus_Config2__ConfigurationType__c = 'Bundle';
			insert bundle2;

			//Inserting the Product Config test data
			Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
			quote.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
			insert prodconfig;

			//Inserting the PLI test data
			Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
			insert pli;

			//Inserting the Line Item Test data
			Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
			1, 'Product/Service', bundle2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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

			//Inserting the Contract Test data
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			aptContract.Apttus__Related_Opportunity__c =opp.id;
			aptContract.Apttus__Account__c = tempacct.id;
			aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;

			//Setting the default pricelist id
			APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
			insert sysProperties;

			//Setting the current Page to DOV
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_DoV);

			//Test Starts
			Test.startTest();
				APT_AmendRenewController amendRenew = new APT_AmendRenewController();
				amendRenew.selectedCategory=APT_AmendRenewController.CATEGORY_DOV_PROPANDCONTR;
				amendRenew.selectedRevenue='Decrease Revenue';
				 /*Commented By Mansi Shah as DOV Reasons are removed from APT_AmendRenewPage*/
				//amendRenew.renderDovReasonPicklist();
				amendRenew.selectedReason='Update products/rates';
				amendRenew.goback();
				amendRenew.doAmend();

			//Test Stops
			Test.stopTest();

			// Confirm no new Opportunity is created as part of Dov Decrease
			List<Opportunity> opportunityListNew = [Select id , DOV_Reason__c from Opportunity where ECLM_Original_Opportunity_No__c =:opp.id ] ;
			// Asserting that the new Opportunity has not been created
			System.assertEquals(0 , opportunityListNew.size());

			// Confirm new Proposal is associated to original Opportunity
			List<Apttus_Proposal__Proposal__c > proposalNewList = [Select id from Apttus_Proposal__Proposal__c where Apttus_Proposal__Opportunity__c=:opp.id];
			// Asserting that the new proposal is associated to original opportunity
			System.assert(proposalNewList.size()>0);
		}
	}

	 /* Shashwat.Nath@Auspost.com.au has included this method on 10/09/2020 as part of STP- Release 2 changes to test functionality
		of creating a new opportunity on Renewal and NOT superseding the original opportunity */
	@IsTest
	 private static void testdoNotSupersedeOriginalOpportunityForRenewal(){

		//Setup test data
		//This code runs as the Sales Admin User
		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser ) {

			// Inserting the Custom setting test data

			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample',APT_Category__c='Standard Apttus Renewal',APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_TYPE_RENEWAL,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;


			// Creating Contact Test data
			Contact con = APT_TestUtils.createContact();
			con.MailingCity = 'Melbourne';
			con.MailingState = 'VIC';
			con.MailingStreet = 'Flinders Street';
			con.MailingPostalCode = '3000';
			insert con;

			//Creating account Test Data
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;

			//Creating Opportunity Test Data
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			opp.closedate = system.today();
			opp.IsStartrackProposal__c ='No';
			insert opp;

			//Creating Price list Test Data
			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;

			//Creating quote Test data
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c = System.today() + 2;
			insert quote;

			//Creating Product Bundle set 1 test data
			Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
			bundle1.Non_contracted__c = false;
			insert bundle1;

			//Creating Product Bundle set 2 test data
			Product2 bundle2 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST002','Postal Services');
			bundle2.APT_Sync_with_Opportunity__c = true;
			bundle2.Apttus_Config2__HasOptions__c = true;
			bundle2.Non_contracted__c = true;
			bundle2.Apttus_Config2__ConfigurationType__c = 'Bundle';
			insert bundle2;

			//Creating Product Config Test data
			Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
			quote.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
			insert prodconfig;

			//Creating PriceListItem Test data
			Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
			insert pli;

			//Creating Line Item Test Data
			Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
			1, 'Product/Service', bundle2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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

			//Creating Apttus contract Test data
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			aptContract.Apttus__Related_Opportunity__c =opp.id;
			aptContract.Apttus__Account__c = tempacct.id;
			aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;

			//Setting the default price list ID
			APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
			insert sysProperties;

			//Setting the current page as Renewal Page
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_RENEW);

			//Test Starts
			Test.startTest();
				APT_AmendRenewController amendRenew = new APT_AmendRenewController();
				amendRenew.selectedCategory='Standard Apttus Renewal';
				amendRenew.doRenew();

			//Test Stops
			Test.stopTest();
			//Qerying the original opportunity
			List<Opportunity> OpportunityList = [Select id ,StageName from Opportunity where id =:opp.id ] ;
			// Querying the new Opportunity Created
			List<Opportunity> OpportunityListNew = [Select id , DOV_Reason__c from Opportunity where ECLM_Original_Opportunity_No__c =:opp.id ] ;
			//Asserting that New Opportunity has been created
			System.Assert(OpportunityListNew.size()>0);
		}
	}

	/* Shashwat.Nath@Auspost.com.au has included this method on 10/09/2020 as part of STP- Release 2 changes to test functionality
		of creating a new opportunity on Renewal and asserting that the new opropsal gets associated to the existing opportunity */
	@IsTest
	 private static void testAssociateExistingOppforRenewal(){

		//Setup test data
		//This code runs as the Sales Admin User
		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser ) {

			// Inserting the Custom setting test data

			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample',APT_Category__c='Standard Apttus Renewal',APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_TYPE_RENEWAL,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;


			// Creating Contact Test data
			Contact con = APT_TestUtils.createContact();
			con.MailingCity = 'Melbourne';
			con.MailingState = 'VIC';
			con.MailingStreet = 'Flinders Street';
			con.MailingPostalCode = '3000';
			insert con;

			//Creating account Test Data
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;

			//Creating Opportunity Test Data
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			opp.closedate = system.today();
			opp.IsStartrackProposal__c ='No';
			insert opp;

			//Creating Existing Opportunity to associate the dov Test Data
			Opportunity ExistingOpportunity = APT_TestUtils.createOpportunity(tempacct.id);
			ExistingOpportunity.IsStartrackProposal__c ='No';
			insert ExistingOpportunity ;

			//Creating Price list Test Data
			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;

			//Creating quote Test data
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c = System.today() + 2;
			insert quote;

			//Creating Product Bundle set 1 test data
			Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
			bundle1.Non_contracted__c = false;
			insert bundle1;

			//Creating Product Bundle set 2 test data
			Product2 bundle2 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST002','Postal Services');
			bundle2.APT_Sync_with_Opportunity__c = true;
			bundle2.Apttus_Config2__HasOptions__c = true;
			bundle2.Non_contracted__c = true;
			bundle2.Apttus_Config2__ConfigurationType__c = 'Bundle';
			insert bundle2;

			//Creating Product Config Test data
			Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
			quote.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
			insert prodconfig;

			//Creating PriceListItem Test data
			Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
			insert pli;

			//Creating Line Item Test Data
			Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
			1, 'Product/Service', bundle2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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

			//Creating Apttus contract Test data
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			aptContract.Apttus__Related_Opportunity__c =opp.id;
			aptContract.Apttus__Account__c = tempacct.id;
			aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;

			//Setting the default price list ID
			APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
			insert sysProperties;

			//Setting the current page as Renewal Page
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_RENEW);

			//Test Starts
			Test.startTest();
				APT_AmendRenewController amendRenew = new APT_AmendRenewController();
				amendRenew.selectedCategory='Standard Apttus Renewal';
				amendRenew.lookupToOpportunity();
				amendRenew.oppId=ExistingOpportunity.id;
				amendRenew.oppName=ExistingOpportunity.name;
				amendRenew.doRenew();

			//Asserting whether the new proposal created is associated to an existing Opportunity
			List<Opportunity> oppList = [ Select id,ECLM_Original_Opportunity_No__c , (Select id from R00N70000001yUfDEAU__r) from Opportunity where id =: ExistingOpportunity.id];
			//Assert if the proposal is associated to the existing opportunity which user would have selected
			System.assert(oppList[0].R00N70000001yUfDEAU__r.size()>0);
			//Asserting the existing opportunity is looking up to the Original opportunity
			System.assertEquals(oppList[0].ECLM_Original_Opportunity_No__c , opp.id);

			//Querying to find out if there is a new opportunity created
			List<Opportunity> oppListNewOpportunity = [ Select id , DOV_Reason__c from Opportunity where ECLM_Original_Opportunity_No__c =:opp.id AND ID!=:ExistingOpportunity.ID];
			//Asserting that there is no new opportunity created
			System.assert(oppListNewOpportunity.Size()==0);

			//Test Stops
			Test.stopTest();
		}
	}

	 /* Shashwat.Nath@Auspost.com.au has included this method on 26/10/2020 to test the selection of existing Opportunity
	 for Migrated Contract Renewal Scenario */
	
	@IsTest
	 private static void testAssociateExistingOppforRenewalMigratedContract(){

		//Setup test data
		//This code runs as the Sales Admin User
		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser ) {

			// Inserting the Custom setting test data

			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample',APT_Category__c='Standard Apttus Renewal',APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_TYPE_RENEWAL,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;


			// Creating Contact Test data
			Contact con = APT_TestUtils.createContact();
			con.MailingCity = 'Melbourne';
			con.MailingState = 'VIC';
			con.MailingStreet = 'Flinders Street';
			con.MailingPostalCode = '3000';
			insert con;

			//Creating account Test Data
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;

			//Creating Opportunity Test Data
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			opp.closedate = system.today();
			insert opp;

			//Creating Existing Opportunity to associate the dov Test Data
			Opportunity ExistingOpportunity = APT_TestUtils.createOpportunity(tempacct.id);
			insert ExistingOpportunity ;

			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;

			//Creating Apttus contract Test data
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			aptContract.Apttus__Account__c = tempacct.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;

			//Setting the default price list ID
			APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
			insert sysProperties;

			//Setting the current page as Renewal Page
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_RENEW);

			//Test Starts
			Test.startTest();
				APT_AmendRenewController amendRenew = new APT_AmendRenewController();
				amendRenew.selectedCategory='Standard Apttus Renewal';
				amendRenew.lookupToOpportunity();
				amendRenew.oppId=ExistingOpportunity.id;
				amendRenew.oppName=ExistingOpportunity.name;
				amendRenew.doRenew();

			//Test Stops
			Test.stopTest();
			//Asserting whether the new proposal created is associated to an existing Opportunity
			List<Opportunity> oppList = [ Select id,ECLM_Original_Opportunity_No__c , (Select id from R00N70000001yUfDEAU__r) from Opportunity where id =: ExistingOpportunity.id];
			//Assert if the proposal is associated to the existing opportunity which user would have selected
			System.assert(oppList[0].R00N70000001yUfDEAU__r.size()>0);
			//Asserting the existing opportunity is not looking up to any opportunity as Migrated contract does not have any Opportunity associated with it
			System.assertEquals( null , oppList[0].ECLM_Original_Opportunity_No__c );
		 }
	}

	/* Shashwat.Nath@Auspost.com.au has included this method on 26/10/2020 to test the selection of existing Opportunity
	 for Migrated Contract */
	@IsTest
	private static void testDovAssociateExistingOpportunity(){
		// Setup test data
		// This code runs as the Sales Admin User

		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser ) {

			// Creating the Custom Setting Data

			APT_R2T_Renew_DoV_Properties__c renewDoVProperties = new APT_R2T_Renew_DoV_Properties__c(Name ='Sample',APT_Category__c=APT_AmendRenewController.CATEGORY_DOV_PROPANDCONTR,APT_Create_Agrement__c=false,
																	APT_Create_Case__c=false,APT_Create_Quote__c=true,APT_Type__c=APT_Constants.ACTION_NAME_DoV,APT_Create_Opportunity__c=true);
			insert renewDoVProperties ;


			// Creating the Contact Test Data
			Contact con = APT_TestUtils.createContact();
			con.MailingCity = 'Melbourne';
			con.MailingState = 'VIC';
			con.MailingStreet = 'Flinders Street';
			con.MailingPostalCode = '3000';
			insert con;

			//Creating account test data
			Account tempacct = APT_TestUtils.createOrganisation();
			insert tempacct;

			//Creating Opportunity Test Data
			Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
			insert opp;

			//Creating Existing Opportunity to associate the dov Test Data
			Opportunity ExistingOpportunity = APT_TestUtils.createOpportunity(tempacct.id);
			insert ExistingOpportunity ;

			Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
			insert priceList;

			//Creating contract Test Data
			Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
			aptContract.Apttus__Account__c = tempacct.id;
			aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
			insert aptContract;

			//Creating Default Price list id data
			APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
			insert sysProperties;

			//Setting the Current Page as DOV
			ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
			ApexPages.currentPage().getParameters().put('actionName',APT_Constants.ACTION_NAME_DoV);

		 //Test starts
		 Test.startTest();
				APT_AmendRenewController amendRenew = new APT_AmendRenewController();
				amendRenew.selectedCategory=APT_AmendRenewController.CATEGORY_DOV_PROPANDCONTR;
				amendRenew.selectedRevenue='Increase Revenue';
				 /*Commented By Mansi Shah as DOV Reasons are removed from APT_AmendRenewPage*/
				//amendRenew.renderDovReasonPicklist();
				amendRenew.selectedReason='Update products/rates';
				amendRenew.lookupToOpportunity();
				amendRenew.oppId=ExistingOpportunity.id;
				amendRenew.oppName=ExistingOpportunity.name;
				amendRenew.doAmend();
			//Test Stops
			Test.stopTest();
			//Asserting whether the new proposal created is associated to an existing Opportunity
			List<Opportunity> oppList = [ Select id,ECLM_Original_Opportunity_No__c , (Select id from R00N70000001yUfDEAU__r) from Opportunity where id =: ExistingOpportunity.id];
			//Assert if the proposal is associated to the existing opportunity which user would have selected
			System.assert(oppList[0].R00N70000001yUfDEAU__r.size()>0);
			//Asserting the existing opportunity is not looking up to the any opportunity as Migrated Contract would not have any Opportunity Associated
			System.assertEquals( null , oppList[0].ECLM_Original_Opportunity_No__c );

		}
	}
	@IsTest
	private static void testDovUpdateOnOpportunity(){
		//Creating a user with Sales Admin profile
		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		try{
			System.runAs(testuser ) {
				Account account = ApplicationTestDataFactory.getAccounts(1, true)[0]; // Creating an Account
				Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0]; // Creating a contact
				Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];// Creating an Opportunity
				opp.IsStartrackProposal__c = '';
				opp.stagename = 'Identify';
				//Mock for opportunity selector
				OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
				ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
				MockUtility.Mocks.startStubbing();
				MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
					new map<Id,Opportunity>(new List<Opportunity>{opp}));
				MockUtility.Mocks.stopStubbing();

				Test.StartTest();
				APT_AmendRenewController dov = new APT_AmendRenewController();

				PageReference pageRef = Page.APT_AmendRenew; // Add your VF page Name here
				pageRef.getParameters().put('oppName', 'test opportunity %count%'); //Setting parameter
				pageRef.getParameters().put('oppId', opp.id); //Setting parameter
				Test.setCurrentPage(pageRef);
				dov.goBack();
				dov.goToOpportunity();
				Test.stopTest();
				opportunity o =[select id,IsStartrackProposal__c from opportunity where id=:opp.id];
				system.assertEquals(o.IsStartrackProposal__c,null);
			}
		}catch(Exception e){
			system.debug('Exception :'+ e);
		}

	}
	@IsTest
	private static void testDovUpdateOnRenewAmendN0(){
		//Creating a user with Sales Admin profile
		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		try{
			System.runAs(testuser ) {
				Account account = ApplicationTestDataFactory.getAccounts(1, true)[0]; // Creating an Account
				Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0]; // Creating a contact
				Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];// Creating an Opportunity
				opp.IsStartrackProposal__c = 'No';
				opp.APTPostcodeSuburb__c= null;
				opp.APTMinimumMonthlySpend__c = null;
				opp.stagename = 'Identify';
				//Mock for opportunity selector
				OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
				ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
				MockUtility.Mocks.startStubbing();
				MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
					new map<Id,Opportunity>(new List<Opportunity>{opp}));
				MockUtility.Mocks.stopStubbing();

				Test.StartTest();
				APT_AmendRenewController dov = new APT_AmendRenewController();

				PageReference pageRef = Page.APT_AmendRenew; // Add your VF page Name here
				pageRef.getParameters().put('oppName', 'test opportunity %count%'); //Setting parameter
				pageRef.getParameters().put('oppId', opp.id); //Setting parameter
				Test.setCurrentPage(pageRef);
				dov.goBack();
				dov.goToOpportunity();
				dov.doAmend();
				dov.doRenew();
				Test.stopTest();
				opportunity o =[select id,IsStartrackProposal__c from opportunity where id=:opp.id];
				system.assertEquals(o.IsStartrackProposal__c,null);
			}
		}catch(Exception e){
			system.debug('Exception :'+ e);
		}

	}
	@IsTest
	private static void testDovUpdateOnRenewAmendYes(){
		//Creating a user with Sales Admin profile
		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		try{
			System.runAs(testuser ) {
				Account account = ApplicationTestDataFactory.getAccounts(1, true)[0]; // Creating an Account
				Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0]; // Creating a contact
				APT_Post_Code_Mapping__c pcr = APT_TestDataFactory.getPostCodeMappingRecord(1,true)[0];
				Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];// Creating an Opportunity
				opp.IsStartrackProposal__c = 'Yes';
				opp.stagename = 'Identify';
				//Mock for opportunity selector
				OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
				ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
				MockUtility.Mocks.startStubbing();
				MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
					new map<Id,Opportunity>(new List<Opportunity>{opp}));
				MockUtility.Mocks.stopStubbing();

				Test.StartTest();
				APT_AmendRenewController dov = new APT_AmendRenewController();

				PageReference pageRef = Page.APT_AmendRenew; // Add your VF page Name here
				pageRef.getParameters().put('oppName', 'test opportunity %count%'); //Setting parameter
				pageRef.getParameters().put('oppId', opp.id); //Setting parameter
				Test.setCurrentPage(pageRef);
				dov.goBack();
				dov.goToOpportunity();
				dov.doAmend();
				dov.doRenew();
				dov.selectedRevenue ='Increase Revenue';
				dov.checkOpprtunityDisplay();
				Test.stopTest();
				opportunity o =[select id,IsStartrackProposal__c from opportunity where id=:opp.id];
				system.assertEquals(o.IsStartrackProposal__c,null);
			}
		}catch(Exception e){
			system.debug('Exception :'+ e);
		}

	}

	/**
	 * Test to ensure the error message is thrown when invalid DSR record is entered for Dov Increase and Renewal scenarios
	 */
	@IsTest
	static void testInvalidDSRErrorForDovIncreaseAndRenewal(){
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Deal_Support_Request__c dsr = ApplicationTestDataFactory.getDealSupportRequests(1, opp.Id, account.Id, true)[0];
		dsr = (Deal_Support_Request__c)ApplicationTestDataFactory.setUnwritableFields(dsr, new Map<String, Object>{'Name' => 'DS-0001213'});
		dsr.Requestor__c = UserInfo.getUserId();
		dsr.CustomerContact1__c = contact.Id; 

		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('dsrIds', new Set<String>{dsr.Name});

		// =====================================
		// Stubbing
		// =====================================
		DealSupportRequestsSelector mockDSRSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDSRSelector.search((Map<String, Set<Id>>)fflib_Match.eq(searchParams),(Set<Object>)fflib_Match.eq(new Set<Object>()),fflib_Match.eqBoolean(true))).thenReturn(new List<Deal_Support_Request__c>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.StartTest();

		APT_AmendRenewController dov = new APT_AmendRenewController();
		dov.selectedRevenue ='Increase Revenue';
		dov.selectedCategory = 'Add new product to non-aligned contract';
		dov.dsrId = dsr.Name;
		dov.dsr = dsr;
		PageReference pageRef = Page.APT_AmendRenew; // Add your VF page Name here
		pageRef.getParameters().put('dsrId', dsr.Name); //Setting parameter
		Test.setCurrentPage(pageRef);
		dov.setOpportunityFieldsFromDSR(opp);
		dov.doAmend();
		dov.doRenew();

		Test.stopTest();

		//verify error message are returned for VF page
		System.assertNotEquals(0, ApexPages.getMessages().size(), 'VF page should have error message');
		System.assertEquals(true, ApexPages.hasMessages(ApexPages.SEVERITY.ERROR), 'VF page should have error message');
	}

	/**
	 * Test to ensure the error message is thrown when both oppotunity and DSR record are entered for Dov Increase and Renewal scenarios
	 */
	@IsTest
	static void testOppDSRErrorForDovIncreaseAndRenewal(){
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Deal_Support_Request__c dsr = ApplicationTestDataFactory.getDealSupportRequests(1, opp.Id, account.Id, true)[0];
		dsr = (Deal_Support_Request__c)ApplicationTestDataFactory.setUnwritableFields(dsr, new Map<String, Object>{'Name' => 'DS-0001213'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.StartTest();

		APT_AmendRenewController dov = new APT_AmendRenewController();
		dov.selectedRevenue ='Increase Revenue';
		dov.selectedCategory = 'Add new product to non-aligned contract';
		dov.oppId = opp.Id;
		dov.dsrId = dsr.Name;
		PageReference pageRef = Page.APT_AmendRenew; // Add your VF page Name here
		pageRef.getParameters().put('dsrId', dsr.Name); //Setting parameter
		pageRef.getParameters().put('oppId', opp.Id);
		Test.setCurrentPage(pageRef);
		dov.doAmend();
		dov.doRenew();

		Test.stopTest();

		//verify error message are returned for VF page
		System.assertNotEquals(0, ApexPages.getMessages().size(), 'VF page should have error message');
		System.assertEquals(true, ApexPages.hasMessages(ApexPages.SEVERITY.ERROR), 'VF page should have error message');
	}


	/**
	 * Test to ensure for BG Base Profile User, set the user as cloned opportunity Owner
	 */
	@IsTest
	static void testSetOpportunityFieldsFromDSRBGBase(){
		//Creating a user with BG Base profile
		Profile p = [SELECT Id FROM Profile WHERE Name='BG Base'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		try{
			System.runAs(testuser ) {
			// =====================================
			// Data Preparation
			// =====================================
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
			Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
			Deal_Support_Request__c dsr = ApplicationTestDataFactory.getDealSupportRequests(1, opp.Id, account.Id, true)[0];
			dsr = (Deal_Support_Request__c)ApplicationTestDataFactory.setUnwritableFields(dsr, new Map<String, Object>{'Name' => 'DS-0001213'});
			dsr.Requestor__c = UserInfo.getUserId();
			dsr.CustomerContact1__c = contact.Id;

			Map<String, Object> searchParams = new Map<String, Object>();
			searchParams.put('dsrIds', new Set<String>{dsr.Name});

			// =====================================
			// Stubbing
			// =====================================
			DealSupportRequestsSelector mockDSRSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockDSRSelector.search((Map<String, Set<Id>>)fflib_Match.eq(searchParams),(Set<Object>)fflib_Match.eq(new Set<Object>()),fflib_Match.eqBoolean(true))).thenReturn(new List<Deal_Support_Request__c>());
			MockUtility.Mocks.stopStubbing();

			// =====================================
			// Testing
			// =====================================
			Test.StartTest();
			APT_AmendRenewController dov = new APT_AmendRenewController();
			dov.selectedRevenue ='Increase Revenue';
			dov.selectedCategory = 'Add new product to non-aligned contract';
			dov.dsrId = dsr.Name;
			dov.dsr = dsr;
			PageReference pageRef = Page.APT_AmendRenew; // Add your VF page Name here
			pageRef.getParameters().put('dsrId', dsr.Name); //Setting parameter
			Test.setCurrentPage(pageRef);
			dov.setOpportunityFieldsFromDSR(opp);
			Test.stopTest();
			System.assert(opp.OwnerId != null);
			}
		}
		catch(Exception e){
			system.debug('Exception :'+ e);
		}

	}

}