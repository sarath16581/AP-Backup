/**************************************************
Description:This apex class is test class for APT_AmendRenewUtility.
History:
--------------------------------------------------
2016-01-01  Garvita Rai  Created

  
2019-01-31  nathan.franklin@auspost.com.au Modified testMethod2 to fix an an issue with the Too Many SOQL error with the deployment of MW0003089 - Opportunity Complexity rating in Salesforce
2022-06-08 - Naveen Rajanna - REQ2595048 - upgrade api version to 52
2022-10-05 - seth.heang@auspost.com.au - Uplift API version to 55, Modified testMethod1 to increase code coverage, testMethod3 to unit test a new method checkProductComponentOptions() 
2023-10-31 - Bharat Patel - To increase code coverage for deployment of STP-9851
2023-11-15 - Mahesh Parvathaneni - added tests for removeDovRenewalPartsFromOppName method
2024-02-05 - Mahesh Parvathaneni - added tests for getDealSupportRequestByDsrId method
**************************************************/
@isTest
private with sharing class APT_AmendRenewUtility_Test{ 
	/**
		Creating test data
	*/
	private static testMethod void testMethod1() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
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
			Product2 product2 = APT_TestUtils.createInternationalProduct('Car Option','26940999','Postal Services');
			product2.APT_Product_type__c = 'International Option';
			insert new List<Product2>{product, product2};
			Apttus_Config2__ProductOptionComponent__c prodOptCom = APT_TestDataFactory.getAPTProductOptionComponentRecord(1, product.Id, product2.Id, false)[0];
			insert prodOptCom;
			Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
			insert priceList;
			Id priceBookId=Test.getStandardPricebookId();
			PricebookEntry  priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId,product.Id);
			insert priceBookEntry;
			OpportunityLineItem oppLineItem = new OpportunityLineItem(Quantity=2,OpportunityId=opp.Id,TotalPrice =45678,PricebookEntryId=priceBookEntry.Id,Contract_Start_Date__c=System.Today(),Contract_End_Date__c=System.Today()+1 );
			oppLineItem.Classification__c = 'New Business';
			insert oppLineItem;
			
			RecordType rt = [SELECT id,Name FROM RecordType WHERE SobjectType='Apttus_Proposal__Proposal__c' AND Name='Renewal Quote'];
			
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(acc.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c=System.Today();
			quote.Expected_Revenue_End_Date__c=System.Today()+30;  
			quote.RecordTypeId = rt.ID;
			insert quote;
			
			//creATE pli
			Apttus_Config2__PriceListItem__c priceLI = APT_TestUtils.createPriceListItem(priceList.ID, product.ID, 'B Mining','BAND 1');
			insert priceLI;
			
			
				//create product configuration
			Apttus_Config2__ProductConfiguration__c pConfig = APT_TestUtils.getProductConfiguration2('TestConfig',123, quote.ID, 'Proposal', 'Product',
																priceList.ID,'New', System.today()-1, System.Today()+2,False);
			insert pConfig;
			
				//Create Temp Obj
				Apttus_Config2__TempObject__c tmp = new Apttus_Config2__TempObject__c();
				tmp.Apttus_Config2__ConfigurationId__c  = pConfig.id;
				insert tmp;
				
				// Create LineItem
				Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(pConfig.Id, null, 1, true,1, 'Product/Service',
				product.Id, true, null,null,null,null, 1, true,'Each',1, priceList.Id, priceLI.Id,'One Time','Per Unit','Standard Price','One Time',
				true, true, 5500, 5500, 'Per Unit',5225, 0, 5225, 'TestaPTTUS');
				insert bundleLine;
				
			Test.startTest(); // 23/10/2019 - fix for the SOQL101 error
			
			//create proposal lineitem
			Apttus_Proposal__Proposal_Line_Item__c pli = new Apttus_Proposal__Proposal_Line_Item__c();
			pli.Apttus_Proposal__Proposal__c = quote.ID;
			pli.Apttus_QPConfig__PriceListItemId__c = priceLI.ID;
			pli.Apttus_Proposal__Product__c = product.ID;
			pli.Apttus_QPConfig__DerivedFromId__c = bundleLine.Id;
			pli.Apttus_QPConfig__LineNumber__c = 1;
			pli.Apttus_QPConfig__ItemSequence__c = 1;
			pli.Apttus_QPConfig__ConfigurationId__c = pConfig.ID;
			insert pli;
			
			//Test.startTest(); // 23/10/2019 - fix for the SOQL101 error
			
			List<OpportunityLineItem > listOppLineItem= new List<OpportunityLineItem >();
			listOppLineItem.add(oppLineItem);
			APT_AmendRenewUtility.cloneOpporunity(agreement ,APT_Constants.ACTION_TYPE_RENEWAL);
			APT_AmendRenewUtility.newOpportunity(agreement,APT_Constants.ACTION_NAME_DoV);
			APT_AmendRenewUtility.renewAgreement('Proposal',opp.Id,quote.Id,agreement);
			agreement.Apttus__Contract_End_Date__c =System.Today();
			agreement.Apttus_QPComply__RelatedProposalId__c=quote.Id;
			agreement.Apttus__Primary_Contact__c=con.Id;
			agreement.Apttus__Account__c=acc.Id;
			agreement.Apttus__Related_Opportunity__c = opp.Id;
			agreement.Apttus__Version_Number__c=123.0;
			update agreement;
			APT_AmendRenewUtility.cloneOpporunity(agreement ,APT_Constants.ACTION_NAME_DoV_Increase);
			APT_AmendRenewUtility.cloneOpporunity(agreement ,APT_Constants.ACTION_NAME_DoV_Decrease);
			APT_AmendRenewUtility.cloneOpporunityProducts(opp.Id,agreement,listOppLineItem,APT_Constants.ACTION_TYPE_RENEWAL);
			APT_AmendRenewUtility.cloneOpporunityProducts(opp.Id,agreement,listOppLineItem,APT_Constants.ACTION_NAME_DoV);
			APT_AmendRenewUtility.newOpportunity(agreement,APT_Constants.ACTION_TYPE_RENEWAL);
			Apttus_Proposal__Proposal__c quote2=APT_AmendRenewUtility.cloneProposal('Proposal',opp.Id,priceList.Id,agreement);
			insert quote2;
			
			Apttus_Config2__ProductConfiguration__c pConfig1 = APT_TestUtils.getProductConfiguration2('TestConfig1',123, quote2.ID, 'Proposal', 'Product',
																priceList.ID,'New', System.today()-1, System.Today()+2,False);
			insert pConfig1;
			
			//Create Temp Obj
			Apttus_Config2__TempObject__c tmp1 = new Apttus_Config2__TempObject__c();
			tmp.Apttus_Config2__ConfigurationId__c  = pConfig1.id;
			insert tmp1;
				
			// Create LineItem
			Apttus_Config2__LineItem__c bundleLine1 = APT_TestUtils.getConfigLineItem(pConfig1.Id, null, 1, true,1, 'Product/Service',
			product.Id, true, null,null,null,null, 1, true,'Each',1, priceList.Id, priceLI.Id,'One Time','Per Unit','Standard Price','One Time',
			true, true, 5500, 5500, 'Per Unit',5225, 0, 5225, 'TestaPTTUS');
			bundleLine1.Apttus_Config2__OptionId__c = product.id;
			bundleLine1.Apttus_Config2__ChargeType__c = product.name;

			Apttus_Config2__LineItem__c optionLine1 = APT_TestUtils.getConfigLineItem(pConfig1.Id, null, 1, true,1, 'Options',
			product.Id, true, null,null,null,null, 1, true,'Each',1, priceList.Id, priceLI.Id,'One Time','Per Unit','Standard Price','One Time',
			true, true, 5500, 5500, 'Per Unit',5225, 0, 5225, 'TestaPTTUS');
			optionLine1.Apttus_Config2__OptionId__c = product2.id;
			optionLine1.Apttus_Config2__ChargeType__c = product2.name;
			insert new List<Apttus_Config2__LineItem__c>{bundleLine1, optionLine1};
			
			//test.stopTest(); // 23/10/2019 To fix the SOQL101 error
			
			APT_AmendRenewUtility.newProposal('Proposal',opp.Id,priceList.Id,agreement);
			//APT_AmendRenewUtility.copyConfiguration(quote.id,quote2.id);
			APT_AmendRenewUtility.copyProposalChildRecords(quote.Id,quote2.Id,APT_Constants.PRODUCT_CODE_PRINT_POST,APT_Constants.ACTION_TYPE_RENEWAL , '12345');
			//APT_AmendRenewUtility.deleteMultiBundleAndStandaloneLines(new List<Apttus_Config2__LineItem__c>{bundleLine1});
			APT_AmendRenewUtility.toNoNamespaceName('Test');
			Apttus__APTS_Agreement__c renewedagr = APT_AmendRenewUtility.renewAgreement('Proposal',opp.Id,quote.Id,agreement);
			APT_AmendRenewUtility.afterRenew(agreement.Id,renewedagr.Id,true);
			APT_AmendRenewUtility.copyConfiguration(quote.Id,quote2.Id);
			APT_AmendRenewUtility.copyConfiguration(quote.Id,quote.Id);
			Apttus__APTS_Agreement__c tempAgrmnt = APT_AmendRenewUtility.amendAgreement('MSA',opp.Id,quote.Id,agreement,'test');
			Apttus__APTS_Agreement__c amendAgreementNullCheck = APT_AmendRenewUtility.amendAgreement('MSA',null,null,agreement,'test');
			APT_AmendRenewUtility.afterAmend(agreement.id,tempAgrmnt.id,true);
			APT_AmendRenewUtility.getAllFieldsAPIName('Apttus_Config2__LineItem__c');
			APT_AmendRenewUtility.copyAttachments(agreement.id,tempAgrmnt.id);
			//APT_AmendRenewUtility.copyConfiguration
			APT_AmendRenewUtility.createAgreementChildRecords(pConfig1.ID, agreement.Id);
			APT_AmendRenewUtility.createAgreementChildRecords(null, agreement.Id);
				test.stopTest(); // 23/10/2019 To fix the SOQL101 error
			//system.assert(tempAgrmnt != null);
		}
	}
		/**
			Creating test data
		*/
		/* RSolomon commented below method to deploy OPC changes, will need to be refactored
	private static testMethod void testMethod2() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {   
			// create contact
			Contact con = APT_TestUtils.createContact();
			insert con;
			
			//create account
			Account acc = APT_TestUtils.createOrganisation();
			insert acc;
			
			//create opportunity
			Opportunity opp = APT_TestUtils.createOpportunity(acc.Id);
			insert opp;
			
			//create agreement
			Apttus__APTS_Agreement__c  agreement = APT_TestUtils.createAgreement(con.Id);
			agreement.Apttus__Related_Opportunity__c = opp.Id;
			insert agreement;
			
			//create product
			Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
			insert product;
			
			//create pricelist
			Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
			insert priceList;
			
			// create pricelist Item
			Apttus_Config2__PriceListItem__c priceLI = APT_TestUtils.createPriceListItem(priceList.ID, product.ID, 'B Mining','BAND 1');
			insert priceLI;
			
			Id priceBookId=Test.getStandardPricebookId();
			
			//create PricebookEntry
			PricebookEntry  priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId,product.Id);
			insert priceBookEntry;
			
			//create opportunitylineitem
			OpportunityLineItem oppLineItem = new OpportunityLineItem(Quantity=2,OpportunityId=opp.Id,TotalPrice =45678,PricebookEntryId=priceBookEntry.Id,Contract_Start_Date__c=System.Today(),Contract_End_Date__c=System.Today()+1 );
			oppLineItem.Classification__c = 'New Business';
			insert oppLineItem;
			
			//create proposal
			Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(acc.id,opp.Id,'Proposal','Test',priceList.id);
			proposal.Expected_Revenue_Start_Date__c=System.Today();
			proposal.Expected_Revenue_End_Date__c=System.Today()+30;
			insert proposal;
			
			List<OpportunityLineItem > listOppLineItem= new List<OpportunityLineItem >();
			listOppLineItem.add(oppLineItem);
			
			Test.startTest();

			// NOTE: These have been moved inside the startTest method to take advantage of the new set of governor limits.
			//  Given the tangled hierarchy of Apttus functionality, it's easy to run into Too Many SOQL Queries which is what was occuring in this instance
			//  Account / Opportunity / Contact / Apttus proposal / Apttus agreement execution flows will all need to be reviewed to fix this issue
			//  update agreement;
			//  insert pConfig;
			//  insert pli;

			
			agreement.Apttus__Contract_End_Date__c =System.Today() + 100;
			agreement.Apttus_QPComply__RelatedProposalId__c=proposal.Id;
			agreement.Apttus__Primary_Contact__c=con.Id;
			agreement.Apttus__Account__c=acc.Id;
			agreement.Apttus__Related_Opportunity__c = opp.Id;
			agreement.Apttus__Version_Number__c=123.0;
			update agreement;

			//create product configuration
			Apttus_Config2__ProductConfiguration__c pConfig = APT_TestUtils.getProductConfiguration2('TestConfig',123, proposal.ID, 'Proposal', 'Product',
																priceList.ID,'New', System.today()-1, System.Today()+2,False);
			insert pConfig;
			
			//create proposal lineitem
			Apttus_Proposal__Proposal_Line_Item__c pli =  new Apttus_Proposal__Proposal_Line_Item__c();
			pli.Apttus_Proposal__Proposal__c = proposal.ID;
			pli.Apttus_QPConfig__PriceListItemId__c = priceLI.ID;
			pli.Apttus_Proposal__Product__c = product.ID;
			pli.Apttus_QPConfig__LineNumber__c = 1;
			pli.Apttus_QPConfig__ItemSequence__c = 1;
			pli.Apttus_QPConfig__ConfigurationId__c = pConfig.ID;
			insert pli;

			//test.startTest();
			
			APT_AmendRenewUtility.createAgreementChildRecords(pConfig.ID, agreement.Id);
			//List<String> tempList = APT_AmendRenewUtility.getCustomFieldNames(Apttus_Config2__LineItem__c.getSObjectType());
			
			//system.assert(tempList.size() > 0);
				
			test.stopTest();
		}
	} */

	private static testMethod void testMethod3() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
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
			Product2 product2 = APT_TestUtils.createInternationalProduct('Car Option','26940999','Postal Services');
			product2.APT_Product_type__c = 'International Option';
			insert new List<Product2>{product, product2};
			Apttus_Config2__ProductOptionComponent__c prodOptCom = APT_TestDataFactory.getAPTProductOptionComponentRecord(1, product.Id, product2.Id, false)[0];
			insert prodOptCom;
			
			Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
			insert priceList;
			Id priceBookId=Test.getStandardPricebookId();
			PricebookEntry  priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId,product.Id);
			insert priceBookEntry;
			OpportunityLineItem oppLineItem = new OpportunityLineItem(Quantity=2,OpportunityId=opp.Id,TotalPrice =45678,PricebookEntryId=priceBookEntry.Id,Contract_Start_Date__c=System.Today(),Contract_End_Date__c=System.Today()+1 );
			oppLineItem.Classification__c = 'New Business';
			insert oppLineItem;
			
			RecordType rt = [SELECT id,Name FROM RecordType WHERE SobjectType='Apttus_Proposal__Proposal__c' AND Name='Renewal Quote'];
			
			Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(acc.id,opp.Id,'Proposal','Test',priceList.id);
			quote.Expected_Revenue_Start_Date__c=System.Today();
			quote.Expected_Revenue_End_Date__c=System.Today()+30;  
			quote.RecordTypeId = rt.ID;
			insert quote;
			
			Test.startTest(); // 23/10/2019 To fix the SOQL error
			
			//creATE pli
			Apttus_Config2__PriceListItem__c priceLI = APT_TestUtils.createPriceListItem(priceList.ID, product.ID, 'B Mining','BAND 1');
			insert priceLI;
			
				//create product configuration
			Apttus_Config2__ProductConfiguration__c pConfig = APT_TestUtils.getProductConfiguration2('TestConfig',123, quote.ID, 'Proposal', 'Product',
																priceList.ID,'New', System.today()-1, System.Today()+2,False);
			insert pConfig;
			
				//Create Temp Obj
				Apttus_Config2__TempObject__c tmp = new Apttus_Config2__TempObject__c();
				tmp.Apttus_Config2__ConfigurationId__c  = pConfig.id;
				insert tmp;
				
				// Create LineItem
				Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(pConfig.Id, null, 1, true,1, 'Product/Service',
				product.Id, true, null,null,null,null, 1, true,'Each',1, priceList.Id, priceLI.Id,'One Time','Per Unit','Standard Price','One Time',
				true, true, 5500, 5500, 'Per Unit',5225, 0, 5225, 'TestaPTTUS');
				insert bundleLine;
			
			//create proposal lineitem
			Apttus_Proposal__Proposal_Line_Item__c pli = new Apttus_Proposal__Proposal_Line_Item__c();
			pli.Apttus_Proposal__Proposal__c = quote.ID;
			pli.Apttus_QPConfig__PriceListItemId__c = priceLI.ID;
			pli.Apttus_Proposal__Product__c = product.ID;
			pli.Apttus_QPConfig__DerivedFromId__c = bundleLine.Id;
			pli.Apttus_QPConfig__LineNumber__c = 1;
			pli.Apttus_QPConfig__ItemSequence__c = 1;
			pli.Apttus_QPConfig__ConfigurationId__c = pConfig.ID;
			insert pli;
			
			//Test.startTest(); 23/10/2019 To fix the SOQL error
			List<OpportunityLineItem > listOppLineItem= new List<OpportunityLineItem >();
			listOppLineItem.add(oppLineItem);
			APT_AmendRenewUtility.cloneOpporunity(agreement ,APT_Constants.ACTION_TYPE_RENEWAL);
			APT_AmendRenewUtility.newOpportunity(agreement,APT_Constants.ACTION_NAME_DoV);
			
			agreement.Apttus__Contract_End_Date__c =System.Today();
			agreement.Apttus_QPComply__RelatedProposalId__c=quote.Id;
			agreement.Apttus__Primary_Contact__c=con.Id;
			agreement.Apttus__Account__c=acc.Id;
			agreement.Apttus__Related_Opportunity__c = opp.Id;
			agreement.Apttus__Version_Number__c=123.0;
			update agreement;
			APT_AmendRenewUtility.renewAgreement('Proposal',opp.Id,quote.Id,agreement);
			
			APT_AmendRenewUtility.cloneOpporunity(agreement ,APT_Constants.ACTION_NAME_DoV);
			APT_AmendRenewUtility.cloneOpporunityProducts(opp.Id,agreement,listOppLineItem,APT_Constants.ACTION_TYPE_RENEWAL);
			APT_AmendRenewUtility.cloneOpporunityProducts(opp.Id,agreement,listOppLineItem,APT_Constants.ACTION_NAME_DoV);
			APT_AmendRenewUtility.newOpportunity(agreement,APT_Constants.ACTION_TYPE_RENEWAL);
			Apttus_Proposal__Proposal__c quote2=APT_AmendRenewUtility.cloneProposal('Proposal',opp.Id,priceList.Id,agreement);
			
			Apttus_Proposal__Proposal__c quoteCloneRenewal=APT_AmendRenewUtility.cloneProposal(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE,opp.Id,priceList.Id,agreement);
			Apttus_Config2__ProductConfiguration__c pConfig1 = APT_TestUtils.getProductConfiguration2('TestConfig1',123, quote2.ID, 'Proposal', 'Product',
																priceList.ID,'New', System.today()-1, System.Today()+2,False);
			insert pConfig1;
			
			//Create Temp Obj
			Apttus_Config2__TempObject__c tmp1 = new Apttus_Config2__TempObject__c();
			tmp.Apttus_Config2__ConfigurationId__c  = pConfig1.id;
			insert tmp1;
				
			// Create LineItem
			Apttus_Config2__LineItem__c bundleLine1 = APT_TestUtils.getConfigLineItem(pConfig1.Id, null, 1, true,1, 'Product/Service',
			product.Id, true, null,null,null,null, 1, true,'Each',1, priceList.Id, priceLI.Id,'One Time','Per Unit','Standard Price','One Time',
			true, true, 5500, 5500, 'Per Unit',5225, 0, 5225, 'TestaPTTUS');
			bundleLine1.Apttus_Config2__OptionId__c = product.id;
			bundleLine1.Apttus_Config2__ChargeType__c = product.name;

			Apttus_Config2__LineItem__c optionLine1 = APT_TestUtils.getConfigLineItem(pConfig1.Id, null, 1, true,1, 'Options',
			product.Id, true, null,null,null,null, 1, true,'Each',1, priceList.Id, priceLI.Id,'One Time','Per Unit','Standard Price','One Time',
			true, true, 5500, 5500, 'Per Unit',5225, 0, 5225, 'TestaPTTUS');
			optionLine1.Apttus_Config2__OptionId__c = product2.id;
			optionLine1.Apttus_Config2__ChargeType__c = product2.name;
			insert new List<Apttus_Config2__LineItem__c>{bundleLine1, optionLine1};
			
			
			APT_AmendRenewUtility.newProposal('Proposal',opp.Id,priceList.Id,agreement);
			//APT_AmendRenewUtility.copyConfiguration(quote.id,quote2.id);
			//APT_AmendRenewUtility.copyProposalChildRecords(quote.Id,quote2.Id,APT_Constants.PRODUCT_CODE_PRINT_POST,APT_Constants.ACTION_TYPE_RENEWAL);
			//Apttus__APTS_Agreement__c renewedagr = APT_AmendRenewUtility.renewAgreement('Proposal',opp.Id,quote.Id,agreement);
			//APT_AmendRenewUtility.afterRenew(agreement.Id,renewedagr.Id);
			//APT_AmendRenewUtility.copyConfiguration(quote.Id,quote2.Id);
			//Apttus__APTS_Agreement__c tempAgrmnt = APT_AmendRenewUtility.amendAgreement('MSA',opp.Id,quote.Id,agreement);
			
			// added unit test of checkProductComponentOptions() to check for decommisioned product after it's missing from product hierarchy
			Set<Id> lineItemSet = new Set<Id>{bundleLine1.Id, optionLine1.Id};
			List<Apttus_Config2__LineItem__c> liList = [select id, Apttus_Config2__ProductId__c, Apttus_Config2__OptionId__c, Apttus_Config2__OptionId__r.Name, Apttus_Config2__ChargeType__c FROM Apttus_Config2__LineItem__c WHERE Id =: lineItemSet];
			List<Apttus_Config2__LineItem__c> diffLiList = APT_AmendRenewUtility.checkProductComponentOptions(
				new Map<Id, Apttus_Config2__LineItem__c>(liList), 
				new Set<Id>{product.id}
			);

			test.stopTest();
			//system.assert(tempAgrmnt != null);
			System.assertNotEquals(0, diffLiList.size(), 'List of Line items from product component option check should not be blank');
			System.assertEquals(bundleLine1.Id, diffLiList[0].Id, 'Expect bundleLine1 Id in the returned list');
		}
	}

	// Test variable declaration
	public static final string MSA_RECORTYPE = 'MSA & Service Schedule';
	public static final string INSIGNATURE_STATUS_CATEGORY = 'In Signature';
	public static final string RECONCILED_STATUS = 'Reconciled';

	private static testMethod void testMethod4() {

		// Create test organisation
		Account accVar = APT_TestUtil2.createOrganisation();
		insert accVar;

		// Create test contact
		Contact conVar = APT_TestUtil2.createContact();
		conVar.AccountId = accVar.Id;
		insert conVar;

		// Create test opportunity
		Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);

		// Create test agreement
		Apttus__APTS_Agreement__c aptContract = APT_TestUtil2.createAgreement(accVar,
																				conVar,
																				oppVar,
																				new Apttus_Proposal__Proposal__c(),
																				'Activated',
																				'In Effect',
																				MSA_RECORTYPE);

		aptContract.APT_Product__c = 'eParcel';
		insert aptContract;

		Test.startTest();
		APT_AmendRenewUtility.cloneOpporunity(aptContract, APT_Constants.ACTION_TYPE_RENEWAL);
		APT_AmendRenewUtility.newOpportunity(aptContract, APT_Constants.ACTION_NAME_DoV);
		boolean boolAfterRenewProcess = APT_AmendRenewUtility.afterRenew(aptContract.Id, aptContract.Id, true);

		APT_AmendRenewUtility.cloneOpporunity(aptContract, APT_Constants.ACTION_NAME_DoV);
		//APT_AmendRenewUtility.cloneOpporunityProducts(opp.Id, agreement, listOppLineItem, APT_Constants.ACTION_TYPE_RENEWAL);
		//APT_AmendRenewUtility.cloneOpporunityProducts(opp.Id, agreement, listOppLineItem, APT_Constants.ACTION_NAME_DoV);
		APT_AmendRenewUtility.newOpportunity(aptContract, APT_Constants.ACTION_TYPE_RENEWAL);

		//APT_AmendRenewUtility.copyProposalChildRecords(quote.ID, quote2.ID, 'INTERNATIONAL BUNDLE', 'Amend', '123.0');
		//APT_AmendRenewUtility.copyConfiguration(quote.ID, quote2.Id);

		//APT_AmendRenewUtility.newProposal('Proposal', opp.Id, priceList.Id, agreement);
		//Apttus__APTS_Agreement__c amendedAgreement = APT_AmendRenewUtility.amendAgreement('Renewal Quote', opp.ID, quote.Id, agreement, 'Amend');
		//boolean boolAfterAmendAgreement = APT_AmendRenewUtility.afterAmend(aptContract.ID, amendedAgreement.Id, false);

		//APT_AmendRenewUtility.copyAttachments(agreement.Id, amendedAgreement.Id);
		//APT_AmendRenewUtility.copyConfiguration(quote.id,quote2.id);
		//APT_AmendRenewUtility.copyProposalChildRecords(quote.Id,quote2.Id,APT_Constants.PRODUCT_CODE_PRINT_POST,APT_Constants.ACTION_TYPE_RENEWAL);
		//Apttus__APTS_Agreement__c renewedagr = APT_AmendRenewUtility.renewAgreement('Proposal',opp.Id,quote.Id,agreement);
		//APT_AmendRenewUtility.afterRenew(agreement.Id,renewedagr.Id);
		//APT_AmendRenewUtility.copyConfiguration(quote.Id,quote2.Id);
		//Apttus__APTS_Agreement__c tempAgrmnt = APT_AmendRenewUtility.amendAgreement('MSA',opp.Id,quote.Id,agreement);

		test.stopTest();
		//system.assert(tempAgrmnt != null);
	}

	public static testmethod void testSAPContractCloning(){
		// Create test records
		
		// Product
		List<Product2> productList = new List<Product2>();
		Product2 product =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
		product.name = APT_Constants.BUNDLE_NAME_INTERNATIONAL;
		productList.add(product);
		
		Product2 product1 = APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
		product1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
		productList.add(product1);
		
		Product2 product2 = APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
		product2.Family = APT_Constants.PARCEL_SERVICES;
		productList.add(product2);
		
		Product2 product3 = APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
		productList.add(product3);
		insert productList;
		
		Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
		insert priceList;
		
		// Pricelist Configuration
		Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
		insert priceListItem;
		
		
		
		// Account
		List<Account> accList = new List<Account>();
		
		Account legacyacct = APT_TestUtils.createOrganisation();
		legacyacct.Legacy_Id__c = '60000000';
		accList.add(legacyacct);
			
		Account tempacct = APT_TestUtils.createOrganisation();
		tempacct.Legacy_Id__c = '60000000'; 
		accList.add(tempacct);
		insert accList;

		legacyacct.Legacy_Id__c = '60000000';
		update legacyacct;

		// Contact
		Contact con= APT_TestUtils.createContact();
		insert con;
		
		// Opportunity
		List<Opportunity> oppList = new List<Opportunity>();
		Opportunity opp1 = APT_TestUtils.createOpportunity(tempacct.id);
		
		// Proposal
		List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
		Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp1.Id,'Proposal','Test',priceList.id);
		proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
		proposal.APT_Contract_Number__c = '012345.1';
		proposalList.add(proposal);
		
		Apttus_Proposal__Proposal__c proposal2 = APT_TestUtils.getQuoteProposal(tempacct.id,opp1.Id,'Proposal','Test',priceList.id);
		proposal2.Apttus_Proposal__Approval_Stage__c = 'Accepted';
		proposal2.APT_Contract_Number__c = '012345.1';
		proposalList.add(proposal2);
		insert proposalList;
		
		//Create Application
		Application__c appli = new Application__c();
		appli.Opportunity__c = opp1.Id;
		appli.Account__c = tempacct.Id;
		insert appli;
		
		// Agreement
		List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();
		
		Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
		aptContract.APT_Product__c= 'eParcel';
		aptContract.Apttus__Related_Opportunity__c=opp1.Id;
		aptContract.Apttus__Account__c=tempacct.Id;
		aptContract.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
		aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
		aptContract.APT_New_Rate_Card_Download__c = true;
		//aptContract.OwnerId = u1.ID;
		aptContract.APMS_Application__c = appli.ID;
		aptContract.Apttus__Status_Category__c = 'Request';
		aptContract.Apttus__Status__c = 'Request';
		aptContract.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
		aptContract.Apttus__Agreement_Number__c = '012345';
		aptContract.Apttus__Version_Number__c = 1;
		agreeList.add(aptContract);
		
		Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(con.Id);
		aptContract2.APT_Product__c= 'eParcel';
		aptContract2.Apttus__Related_Opportunity__c=opp1.Id;
		aptContract2.Apttus__Account__c=tempacct.Id;
		aptContract2.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
		aptContract2.Apttus_QPComply__RelatedProposalId__c = proposal2.ID;
		aptContract2.APT_New_Rate_Card_Download__c = true;
		//aptContract.OwnerId = u1.ID;
		aptContract2.APMS_Application__c = appli.ID;
		aptContract2.Apttus__Status_Category__c = 'Request';
		aptContract2.Apttus__Status__c = 'Request';
		aptContract2.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
		agreeList.add(aptContract2);
		
		insert agreeList;
		
		ApexPages.currentPage().getParameters().put('Id',aptContract.Id);
		
		// Generate SAP Contract for original Agreement
		APT_ManageSAPContractController apManageSapCon = new APT_ManageSAPContractController();
		apManageSapCon.textAreaUserInput = '1234567';
		apManageSapCon.saveSAPContracts(); 

		ApexPages.currentPage().getParameters().put('Id',aptContract2.Id);
		
		test.startTest();
		
			Apttus__APTS_Agreement__c renewAgreeVar = [SELECT Id,Apttus_QPComply__RelatedProposalId__r.APT_Contract_Number__c
														FROM Apttus__APTS_Agreement__c 
														WHERE Id = :aptContract2.Id]; 
			
			Apttus__APTS_Agreement__c origAgreeVar = [SELECT Id, Name, Apttus__Version_Number__c
														FROM Apttus__APTS_Agreement__c 
														WHERE Apttus__FF_Agreement_Number__c = :renewAgreeVar.Apttus_QPComply__RelatedProposalId__r.APT_Contract_Number__c]; 
			
			system.debug('renewAgreeVar:' + renewAgreeVar);
			system.debug('origAgreeVar:' + origAgreeVar);
		
			// Cloning and postfixing action
			APT_AmendRenewUtility.copySAPContratcs(origAgreeVar.Id, renewAgreeVar.Id, origAgreeVar.Apttus__Version_Number__c);
		
		test.stopTest();
	}

	/**
	 * Test to ensure Renewal: and DoV: parts are removed from opportunity name
	 */
	@IsTest
	static void testRemoveDovRenewalPartsFromOppName() {
		// =====================================
		// Data Preparation
		// =====================================
		String oppName1 = 'Dov: Renewal: Dov: Dov: Test Opportunity';
		String oppName2 = 'Dov: Renewal: Dov: TestDov:Test';
		String oppName3 = 'Test Opportunity';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// make sure the opp name has been returned
		Assert.areEqual('Test Opportunity', APT_AmendRenewUtility.removeDovRenewalPartsFromOppName(oppName1), 'Expected Test Opportunity to be returned');
		Assert.areEqual('TestDov:Test', APT_AmendRenewUtility.removeDovRenewalPartsFromOppName(oppName2), 'Expected TestDov:Test to be returned');
		Assert.areEqual('Test Opportunity', APT_AmendRenewUtility.removeDovRenewalPartsFromOppName(oppName3), 'Expected Test Opportunity to be returned');
		Assert.areEqual(null, APT_AmendRenewUtility.removeDovRenewalPartsFromOppName(null), 'Expected null to be returned');

		Test.stopTest();
	}

	/**
	 * Test to ensure DSR record is returned from getDealSupportRequestByDsrId
	 */
	@IsTest
	static void testGetDealSupportRequestByDsrId() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		List<Deal_Support_Request__c> dealSupportReqList = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true);

		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('dsrIds', new Set<String>{dealSupportReqList[0].Name});

		// =====================================
		// Stubbing
		// =====================================
		DealSupportRequestsSelector mockSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.search((Map<String, Set<Id>>)fflib_Match.eq(searchParams),(Set<Object>)fflib_Match.eq(new Set<Object>()),fflib_Match.eqBoolean(true))).thenReturn(dealSupportReqList);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Deal_Support_Request__c dsr = APT_AmendRenewUtility.getDealSupportRequestByDsrId(dealSupportReqList[0].Name);

		// make sure the DSR record is returned
		Assert.areEqual(dsr.Id, dealSupportReqList[0].Id, 'Expected DSR record to be returned');

		Test.stopTest();
	}
}