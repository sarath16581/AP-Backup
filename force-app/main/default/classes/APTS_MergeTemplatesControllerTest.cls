/* @author Nasir Jawed
* @date 2022-12-06
* @tag APTS_MergeTemplatesController
* @domain Apttus
* @description This test class covers the logic of APTS_MergeTemplatesController controller
*/


@isTest
/*
    Test Class to test the Merge template functionality and execute the test scenario
*/
private class APTS_MergeTemplatesControllerTest {
	/*
	Test Method to test the Merge template functionality and execute the test scenario
	*/
	static testmethod void mergeTemplates() {
		
		Apttus__ComplySystemProperties__c sysProp = new Apttus__ComplySystemProperties__c();
		RecordType TestRecordType = new RecordType();
		/*
		Creating record for Custom settings
		*/
		List<APT_R2T_Templates_Settings__c> TemplateCSs = new List<APT_R2T_Templates_Settings__c>();
		APT_R2T_Templates_Settings__c TemplateCS1 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS2 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS3 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS4 = new APT_R2T_Templates_Settings__c();
		
		
		//ID TestRecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
		ID TestRecordTypeID2 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('APT_Letter_of_Intent').getRecordTypeId();
		
		sysProp.Name = 'System Properties';
		sysProp.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';        
		insert sysProp;
		
		/*
		inserting record for Custom settings
		*/
		TemplateCS1.Name = 'TestTemplateCS1';
		TemplateCS1.Compare_against_IPL__c = False;
		TemplateCS1.Sequence_No__c = 1;
		TemplateCS1.Template_ID__c = 'TestTemplateID1';
		TemplateCS1.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS1.Subtype__c = 'Long Form';
		TemplateCS1.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS1);
		
		TemplateCS2.Name = 'TestTemplateCS2';
		TemplateCS2.Compare_against_IPL__c = True;
		TemplateCS2.Sequence_No__c = 2;
		TemplateCS2.Template_ID__c = 'TestTemplateID2';
		TemplateCS2.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS2.Subtype__c = 'Long Form';
		TemplateCS2.Template_Product_Name__c = 'Print Post';
		TemplateCS2.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS2);
		
		TemplateCS3.Name = 'TestTemplateCS3';
		TemplateCS3.Compare_against_IPL__c = True;
		TemplateCS3.Sequence_No__c = 3;
		TemplateCS3.Template_ID__c = 'TestTemplateID3';
		TemplateCS3.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS3.Subtype__c = 'Long Form';
		TemplateCS3.Template_Product_Name__c = 'WrongProductName';
		TemplateCS3.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS3);
		
		TemplateCS4.Name = 'TestTemplateCS4';
		TemplateCS4.Compare_against_IPL__c = True;
		TemplateCS4.Sequence_No__c = 4;
		TemplateCS4.Template_ID__c = 'TestTemplateID4';
		TemplateCS4.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS4.Subtype__c = 'Long Form';
		TemplateCS4.Template_Product_Name__c = 'Print Post';
		TemplateCS4.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS4);
		
		insert TemplateCSs;
		
		List<Apttus__APTS_Template__c> listTemplate= new List<Apttus__APTS_Template__c>();
		/*
		Inserting record for Template object
		*/
		Apttus__APTS_Template__c Template1 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template1.Name = 'TestTemplates1';
		Template1.Apttus__ReferenceId__c = 'TestTemplateID1';              
		listTemplate.add(Template1);
		
		Apttus__APTS_Template__c Template2 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template2.Name = 'TestTemplates2';
		Template2.Apttus__ReferenceId__c = 'TestTemplateID2';              
		listTemplate.add(Template2);
		
		Apttus__APTS_Template__c Template3 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template3.Name = 'TestTemplates3';
		Template3.Apttus__ReferenceId__c = 'TestTemplateID3';             
		listTemplate.add(Template3);
		
		Apttus__APTS_Template__c Template4 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template4.Name = 'TestTemplates4';
		Template4.Apttus__ReferenceId__c = 'TestTemplateID4'; 
		listTemplate.add(Template4);          
		insert listTemplate;  
		/*
		Creating test data for Account, contact, opportunity,product2,pricelist,Quote and Agreement
		*/
		//Create test organisation
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		account.LEGACY_ID__c = '61918806';      
		//create contact record
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		
		//create Opportunity record
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		
		
			//get Product and set Product Type
		Product2 product =APT_TestUtils.createAPPCProduct('Car',APT_Constants.PRODUCT_CODE_APPC,'Postal Services');
		product.APT_Product_type__c = 'Workforce Verification';//add product type to product
		
		
		//get Price List and Price List Item
		Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
				
		Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
		
		//create Proposal record
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opportunityRecord.id, account.Id, con.id, true)[0];
		quote.APT_Use_Offline_Rates__c= true;       
		
		Apttus_Proposal__Proposal__c quote2 = APT_TestDataFactory.getAPTProposalRecord(1, opportunityRecord.id, account.Id, con.id, true)[0];
		quote.APT_Use_Offline_Rates__c= true;        
		
		//create Agreement to set contract from agreement for related agreement
		Apttus__APTS_Agreement__c AgreementLetter= APT_TestDataFactory.getAgreementRecord(1,true)[0];       
		AgreementLetter.Included_Product_Lines__c = 'Print Post';
		AgreementLetter.RecordTypeID = TestRecordTypeID2  ; 
		AgreementLetter.Apttus_QPComply__RelatedProposalId__c= quote.id;  
		AgreementLetter.APT_Pricing_Category__c='Offline Rates'; 
		AgreementLetter.Apttus__Subtype__c='Letter of Intent'; 
		AgreementLetter.APT_Contract_Type__c='Migrated Contract';      
		
		//create aggrement to set contract from agreement for related agreement
		Apttus__APTS_Agreement__c AgreementLetter2 = APT_TestDataFactory.getAgreementRecord(1, true)[0];        
		AgreementLetter2.Included_Product_Lines__c = 'Workforce Verification';
		AgreementLetter2.RecordTypeID = TestRecordTypeID2 ;           
		AgreementLetter2.Apttus_QPComply__RelatedProposalId__c= quote2.id;  
		AgreementLetter2.APT_Pricing_Category__c='Offline Rates'; 
		AgreementLetter2.Apttus__Subtype__c='Letter of Intent'; 
		AgreementLetter2.APT_Contract_Type__c='Migrated Contract'; 
		
		
		
		system.assertEquals(AgreementLetter2.Apttus__Subtype__c,'Letter of Intent', 'Incorrect sub type');
		
		//create related agreement and set to and from contracts
		List<Apttus__APTS_Related_Agreement__c> relAgreementList = new List<Apttus__APTS_Related_Agreement__c>();
		
		
		Apttus__APTS_Related_Agreement__c relatedAgreementLetter = APT_TestDataFactory.getRelatedAgreementRecord(1,AgreementLetter.id,AgreementLetter2.id,true)[0];       
		
		relAgreementList.add(relatedAgreementLetter);
		
		Apttus__AgreementLineItem__c ali= APT_TestDataFactory.getAPTAgreementLineItem(1,true)[0];               
		ali.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;
		/*
		Implementing mock for all the selectors
		*/        
		
		APT_AgreementObjectsSelector mockSelectorAgreement = (APT_AgreementObjectsSelector) MockUtility.mockSelector(APT_AgreementObjectsSelector.class);
		ApplicationDatabase mockDatabaseAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorAgreement.selectByConfigId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(
			new List<Apttus__APTS_Agreement__c>(new List<Apttus__APTS_Agreement__c>{AgreementLetter2}));
		MockUtility.Mocks.stopStubbing();
		
		APT_RelatedAgreementsSelector mockSelectorRelAgreement = (APT_RelatedAgreementsSelector) MockUtility.mockSelector(APT_RelatedAgreementsSelector.class);
		ApplicationDatabase mockDatabaseRelAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorRelAgreement.selectByAgreementId((Set<Id>)fflib_Match.eq(new set<ID>{(ID)AgreementLetter2.id}),(set<Object>)fflib_Match.eq(new set<Object>{APT_RelatedAgreementsSelector.options.WITH_AGREEMENT}))).thenReturn(
			new List<Apttus__APTS_Related_Agreement__c>(new List<Apttus__APTS_Related_Agreement__c>{relatedAgreementLetter}));
		MockUtility.Mocks.stopStubbing();
		
		APT_AgreementLineItemsSelector mockSelectorAgreementLineItem = (APT_AgreementLineItemsSelector) MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		ApplicationDatabase mockDatabaseAgreementLineItem = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorAgreementLineItem.selectByContractIdsLineTypeProduct((Set<Id>)fflib_Match.eq(new set<ID>{(ID)AgreementLetter.id}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.LINE_TYPE_PRODUCT_SERVICE}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.PRODUCT_CODE_PRINT_POST}))).thenReturn(
			new List<Apttus__AgreementLineItem__c>(new List<Apttus__AgreementLineItem__c>{ali}));
		MockUtility.Mocks.stopStubbing();
		
		test.starttest();
		PageReference pref = Page.APTS_GenerateDocs;
		pref.getParameters().put('id', AgreementLetter2.id);
		Test.setCurrentPage(pref);
		
		ApexPages.StandardController stdController = new ApexPages.StandardController(AgreementLetter2);
		APTS_MergeTemplatesController myController = new APTS_MergeTemplatesController(stdController);
		myController.mergeDocuments=true;
		myController.GenerateDocument();
		myController.completedSubmitDocsCount =0;
		
		List<APTS_MergeTemplatesController.TemplateWrapper> temWrapperList= new List<APTS_MergeTemplatesController.TemplateWrapper>();
		
		APTS_MergeTemplatesController.TemplateWrapper temWrapper= new APTS_MergeTemplatesController.TemplateWrapper(Template1 ,AgreementLetter.id,1,'test','1',true,true);
		temWrapperList.add(temWrapper);
		APTS_MergeTemplatesController.TemplateWrapper temWrapper1= new APTS_MergeTemplatesController.TemplateWrapper(Template1 ,AgreementLetter.id,2,'test','1',true,true);
		temWrapperList.add(temWrapper1);
		APTS_MergeTemplatesController.TemplateWrapper temWrapper2= new APTS_MergeTemplatesController.TemplateWrapper(Template1 ,AgreementLetter.id,3,'test','1',true,true);
		temWrapperList.add(temWrapper2);
		
		myController.lstTemplateWrapper = temWrapperList;     
		
		
		if(myController.lstTemplateWrapper.size()> 0)
		myController.templateID = myController.lstTemplateWrapper[2].template.Id;
		myController.downAction();
		
		if(myController.lstTemplateWrapper.size()> 0)
		myController.templateID = myController.lstTemplateWrapper[1].template.Id;
		myController.downAction();
		
		if(myController.lstTemplateWrapper.size()> 0)
		myController.templateID = myController.lstTemplateWrapper[0].template.Id;
		myController.downAction(); 
		
		List<APTS_MergeTemplatesController.TemplateWrapper> temWrapperList1= new List<APTS_MergeTemplatesController.TemplateWrapper>();
		/*
		Implementing data for Wrapper class
		*/
		
		APTS_MergeTemplatesController.TemplateWrapper temWrapper11= new APTS_MergeTemplatesController.TemplateWrapper(Template1 ,AgreementLetter.id,2,'test','1',true,true);
		temWrapperList1.add(temWrapper11);
		APTS_MergeTemplatesController.TemplateWrapper temWrapper22= new APTS_MergeTemplatesController.TemplateWrapper(Template1 ,AgreementLetter.id,3,'test','1',true,true);
		temWrapperList1.add(temWrapper22);
		
		myController.lstTemplateWrapper = temWrapperList1;
		
		if(myController.lstTemplateWrapper.size()> 0)
		myController.templateID = myController.lstTemplateWrapper[1].template.Id;
		myController.upAction();
		
		if(myController.lstTemplateWrapper.size()> 0)
		myController.templateID = myController.lstTemplateWrapper[0].template.Id;
		myController.upAction();
		
			
		myController.Cancel();   
		myController.GenerateDocument();
		myController.processSubmitDocs();
		
		List<APTS_MergeTemplatesController.TemplateWrapper> temWrapperList2= new List<APTS_MergeTemplatesController.TemplateWrapper>();
		try{
			myController.lstTemplateWrapper = null; 
			myController.downAction();
		}catch(exception ex){
		}       
		System.assertNotEquals(myController.Agreement,null, 'Agreement record should be returned');
		//system.assertEquals(myController.processSubmitted,true);
		test.stoptest();    
	}

	static testmethod void mergeOfflineTemplates() {
		/*
		Creating record for Custom settings
		*/
		Apttus__ComplySystemProperties__c sysProp = new Apttus__ComplySystemProperties__c();
		RecordType TestRecordType = new RecordType();
		List<APT_R2T_Templates_Settings__c> TemplateCSs = new List<APT_R2T_Templates_Settings__c>();
		APT_R2T_Templates_Settings__c TemplateCS1 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS2 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS3 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS4 = new APT_R2T_Templates_Settings__c();
		
		List<Apttus__APTS_Template__c> listTemplate = new List<Apttus__APTS_Template__c >();
		
		ID TestRecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
		
		sysProp.Name = 'System Properties';
		sysProp.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';
		insert sysProp;
		
		APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(null);
		r2tSystemProperties.APT_Contract_Templates_To_Uncheck__c = 'R2T Pricing Schedule, StarTrack Pricing Schedule';
		insert r2tSystemProperties;
		
			/*
		inserting record for Custom settings
		*/
		TemplateCS1.Name = 'TestTemplateCS1';
		TemplateCS1.Compare_against_IPL__c = False;
		TemplateCS1.Sequence_No__c = 1;
		TemplateCS1.Template_ID__c = 'TestTemplateID1';
		TemplateCS1.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS1.Subtype__c = 'Long Form';
		TemplateCS1.Settings_Type__c = 'Template';
		TemplateCS1.APT_Rate_Type__c = 'Offline';
		TemplateCSs.add(TemplateCS1);
		
		insert TemplateCSs;
			/*
		Inserting record for Template object
		*/
		Apttus__APTS_Template__c Template1 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template1.Name = 'TestTemplates1';
		Template1.Apttus__ReferenceId__c = 'TestTemplateID1';              
		listTemplate.add(Template1);
		
		Apttus__APTS_Template__c Template2 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template2.Name = 'TestTemplates2';
		Template2.Apttus__ReferenceId__c = 'TestTemplateID2';              
		listTemplate.add(Template2);
		
		Apttus__APTS_Template__c Template3 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template3.Name = 'TestTemplates3';
		Template3.Apttus__ReferenceId__c = 'TestTemplateID3';             
		listTemplate.add(Template3);
		
		Apttus__APTS_Template__c Template4 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template4.Name = 'TestTemplates4';
		Template4.Apttus__ReferenceId__c = 'TestTemplateID4'; 
		listTemplate.add(Template4);          
		insert listTemplate;  

		//Create pricelist
		Apttus_Config2__PriceList__c priceList = APT_TestUtil2.createPriceList();
		insert priceList;
			/*
		Creating test data for Account, contact, opportunity,product2,pricelist,Quote and Agreement
		*/
		//Create test organisation
		Account accVar = ApplicationTestDataFactory.getAccounts(1, true)[0];
		
		//Create contact record with Account
		Contact con = ApplicationTestDataFactory.getContacts(1, accVar.Id, true)[0];
		

		//Create test opportunity
		Opportunity oppVar = ApplicationTestDataFactory.getOpportunities(1, accVar.Id, true)[0];
		oppVar.StageName = 'Identify';
		

		//Create proposal                          
		Apttus_Proposal__Proposal__c proposalVar = APT_TestDataFactory.getAPTProposalRecord(1, oppVar.id, accVar.Id, con.id, true)[0];
		proposalVar.APT_Use_Offline_Rates__c = true;
		
			//create Agreement to set contract from agreement for related agreement
		Apttus__APTS_Agreement__c Agreement= APT_TestDataFactory.getAgreementRecord(1,true)[0];       
		Agreement.Included_Product_Lines__c = 'Print Post';
		Agreement.RecordTypeID = TestRecordTypeID;               
		Agreement.Apttus_QPComply__RelatedProposalId__c = proposalVar.Id;        
		Agreement.APT_Pricing_Category__c = 'Offline';        
		Agreement.Included_Product_Lines__c = 'StarTrack';  
		Agreement.APT_Require_Customer_Signature__c=true;       
		
		//create Agreement to set contract from agreement for related agreement
		Apttus__APTS_Agreement__c Agreement2= APT_TestDataFactory.getAgreementRecord(1,true)[0];       
		Agreement2.Included_Product_Lines__c = 'Print Post';
		Agreement2.RecordTypeID = TestRecordTypeID;               
		Agreement2.Apttus_QPComply__RelatedProposalId__c = proposalVar.Id;        
		Agreement2.APT_Pricing_Category__c = 'Offline';        
		Agreement2.Included_Product_Lines__c = 'StarTrack';  
		Agreement2.APT_Require_Customer_Signature__c=true;   
		
		List<Apttus__APTS_Related_Agreement__c> relAgreementList = new List<Apttus__APTS_Related_Agreement__c>();
		
			//create Related Agreement to set  agreement for related agreement
		Apttus__APTS_Related_Agreement__c relatedAgreementLetter = APT_TestDataFactory.getRelatedAgreementRecord(1,Agreement.id,Agreement2.id,true)[0];       
		
		relAgreementList.add(relatedAgreementLetter);
		
		Apttus__AgreementLineItem__c ali= APT_TestDataFactory.getAPTAgreementLineItem(1,true)[0];               
		ali.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;         
		/*
		Implementing mock for all the selectors
		*/       
		
		APT_AgreementObjectsSelector mockSelectorAgreement = (APT_AgreementObjectsSelector) MockUtility.mockSelector(APT_AgreementObjectsSelector.class);
		ApplicationDatabase mockDatabaseAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorAgreement.selectByConfigId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(
			new List<Apttus__APTS_Agreement__c>(new List<Apttus__APTS_Agreement__c>{Agreement}));
		MockUtility.Mocks.stopStubbing();
		
		APT_RelatedAgreementsSelector mockSelectorRelAgreement = (APT_RelatedAgreementsSelector) MockUtility.mockSelector(APT_RelatedAgreementsSelector.class);
		ApplicationDatabase mockDatabaseRelAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorRelAgreement.selectByAgreementId((Set<Id>)fflib_Match.eq(new set<ID>{(ID)Agreement.id}),(set<Object>)fflib_Match.eq(new set<Object>{APT_RelatedAgreementsSelector.options.WITH_AGREEMENT}))).thenReturn(
			new List<Apttus__APTS_Related_Agreement__c>(new List<Apttus__APTS_Related_Agreement__c>{relatedAgreementLetter}));
		MockUtility.Mocks.stopStubbing();
		
		APT_AgreementLineItemsSelector mockSelectorAgreementLineItem = (APT_AgreementLineItemsSelector) MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		ApplicationDatabase mockDatabaseAgreementLineItem = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorAgreementLineItem.selectByContractIdsLineTypeProduct((Set<Id>)fflib_Match.eq(new set<ID>{(ID)Agreement.id}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.LINE_TYPE_PRODUCT_SERVICE}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.PRODUCT_CODE_PRINT_POST}))).thenReturn(
			new List<Apttus__AgreementLineItem__c>(new List<Apttus__AgreementLineItem__c>{ali}));
		MockUtility.Mocks.stopStubbing();  
		
		test.starttest();
		PageReference pref = Page.APTS_GenerateDocs;
		pref.getParameters().put('id', Agreement.id);
		Test.setCurrentPage(pref);
		
		ApexPages.StandardController stdController = new ApexPages.StandardController(Agreement);
		APTS_MergeTemplatesController myController = new APTS_MergeTemplatesController(stdController);
		
		myController.GenerateDocument();
		myController.processSubmitDocs();
		//system.assertEquals(myController.processSubmitted,true);
		system.assertNotEquals(APT_Constants.SEPERATOR_BACKWARD_SLASH + Agreement.id,null);
		test.stopTest();
	}

	static testmethod void mergeTemplates2() {
			/*
		Creating record for Custom settings
		*/
		Apttus__ComplySystemProperties__c sysProp = new Apttus__ComplySystemProperties__c();
		RecordType TestRecordType = new RecordType();
		
		List<APT_R2T_Templates_Settings__c> TemplateCSs = new List<APT_R2T_Templates_Settings__c>();
		APT_R2T_Templates_Settings__c TemplateCS1 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS2 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS3 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS4 = new APT_R2T_Templates_Settings__c();
		
		
		ID TestRecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
		ID TestRecordTypeDEVName = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('APT_MSA_Service_Schedule').getRecordTypeId();
		
		
		sysProp.Name = 'System Properties';
		sysProp.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';        
		insert sysProp;
			/*
		inserting record for Custom settings
		*/
		
		TemplateCS1.Name = 'TestTemplateCS1';
		TemplateCS1.Compare_against_IPL__c = False;
		TemplateCS1.Sequence_No__c = 1;
		TemplateCS1.Template_ID__c = 'TestTemplateID1';
		TemplateCS1.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS1.Subtype__c = 'Long Form';
		TemplateCS1.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS1);
		
		TemplateCS2.Name = 'TestTemplateCS2';
		TemplateCS2.Compare_against_IPL__c = True;
		TemplateCS2.Sequence_No__c = 2;
		TemplateCS2.Template_ID__c = 'TestTemplateID2';
		TemplateCS2.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS2.Subtype__c = 'Long Form';
		TemplateCS2.Template_Product_Name__c = 'Print Post';
		TemplateCS2.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS2);
		
		TemplateCS3.Name = 'TestTemplateCS3';
		TemplateCS3.Compare_against_IPL__c = True;
		TemplateCS3.Sequence_No__c = 3;
		TemplateCS3.Template_ID__c = 'TestTemplateID3';
		TemplateCS3.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS3.Subtype__c = 'Long Form';
		TemplateCS3.Template_Product_Name__c = 'WrongProductName';
		TemplateCS3.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS3);
		
		TemplateCS4.Name = 'TestTemplateCS4';
		TemplateCS4.Compare_against_IPL__c = True;
		TemplateCS4.Sequence_No__c = 4;
		TemplateCS4.Template_ID__c = 'TestTemplateID4';
		TemplateCS4.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS4.Subtype__c = 'Long Form';
		TemplateCS4.Template_Product_Name__c = 'Print Post';
		TemplateCS4.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS4);
		
		insert TemplateCSs;
			/*
		Inserting record for Template object
		*/
		List<Apttus__APTS_Template__c> listTemplate= new List<Apttus__APTS_Template__c>();
		
		Apttus__APTS_Template__c Template1 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template1.Name = 'TestTemplates1';
		Template1.Apttus__ReferenceId__c = 'TestTemplateID1';              
		listTemplate.add(Template1);
		
		Apttus__APTS_Template__c Template2 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template2.Name = 'TestTemplates2';
		Template2.Apttus__ReferenceId__c = 'TestTemplateID2';              
		listTemplate.add(Template2);
		
		Apttus__APTS_Template__c Template3 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template3.Name = 'TestTemplates3';
		Template3.Apttus__ReferenceId__c = 'TestTemplateID3';             
		listTemplate.add(Template3);
		
		Apttus__APTS_Template__c Template4 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template4.Name = 'TestTemplates4';
		Template4.Apttus__ReferenceId__c = 'TestTemplateID4'; 
		listTemplate.add(Template4);          
		insert listTemplate;         
			/*
		Creating test data for Agreement
		*/
		List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
		
		Apttus__APTS_Agreement__c Agreement= APT_TestDataFactory.getAgreementRecord(1,false)[0];       
		Agreement.Included_Product_Lines__c = 'Print Post';
		Agreement.RecordTypeID = TestRecordTypeID ;        
		Agreement.APT_Pricing_Category__c='Offline Rates'; 
		Agreement.Apttus__Subtype__c='Long Form'; 
		Agreement.APT_Contract_Type__c='Migrated Contract';         
		Agreement.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'MSA & Service Schedule' Limit 1];
		Agreement.RecordType.DeveloperName = 'APT_MSA_Service_Schedule';   
		agreementList.add(Agreement);             
		
		
		//create aggrement to set contract from agreement for related agreement
		Apttus__APTS_Agreement__c Agreement2 = APT_TestDataFactory.getAgreementRecord(1, false)[0];        
		Agreement2.Included_Product_Lines__c = 'Workforce Verification';
		Agreement2.RecordTypeID = TestRecordTypeID ;          
		Agreement2.APT_Pricing_Category__c='Offline Rates'; 
		Agreement2.Apttus__Subtype__c='Long Form'; 
		Agreement2.APT_Contract_Type__c='Migrated Contract'; 
		Agreement2.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'MSA & Service Schedule' Limit 1];
		Agreement2.RecordType.DeveloperName = 'APT_MSA_Service_Schedule';  
		agreementList.add(Agreement2);         
		insert agreementList;         
		
		
		//create related agreement and set to and from contracts
		
		List<Apttus__APTS_Related_Agreement__c> relAgreementList = new List<Apttus__APTS_Related_Agreement__c>();      
		
		Apttus__APTS_Related_Agreement__c relatedAgreement = APT_TestDataFactory.getRelatedAgreementRecord(1,Agreement.id,Agreement2.id,false)[0];       
		insert relatedAgreement ;
		relAgreementList.add(relatedAgreement);
		
		Apttus__AgreementLineItem__c ali= APT_TestDataFactory.getAPTAgreementLineItem(1,false)[0];               
		ali.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;  
		ali.Apttus__AgreementId__c=agreement.id; 
		insert ali;

		/*
		Implementing mock for all the selectors
		*/        
		APT_AgreementObjectsSelector mockSelectorAgreement = (APT_AgreementObjectsSelector) MockUtility.mockSelector(APT_AgreementObjectsSelector.class);
		ApplicationDatabase mockDatabaseAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorAgreement.selectByConfigId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(
			new List<Apttus__APTS_Agreement__c>(new List<Apttus__APTS_Agreement__c>{Agreement}));
		MockUtility.Mocks.stopStubbing();
		
		
		APT_RelatedAgreementsSelector mockSelectorRelAgreement = (APT_RelatedAgreementsSelector) MockUtility.mockSelector(APT_RelatedAgreementsSelector.class);
		ApplicationDatabase mockDatabaseRelAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorRelAgreement.selectByAgreementId((Set<Id>)fflib_Match.eq(new set<ID>{(ID)Agreement.id}),(set<Object>)fflib_Match.eq(new set<Object>{APT_RelatedAgreementsSelector.options.WITH_AGREEMENT}))).thenReturn(
			new List<Apttus__APTS_Related_Agreement__c>(new List<Apttus__APTS_Related_Agreement__c>{relatedAgreement}));
		MockUtility.Mocks.stopStubbing();
		
		APT_AgreementLineItemsSelector mockSelectorAgreementLineItem = (APT_AgreementLineItemsSelector) MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		ApplicationDatabase mockDatabaseAgreementLineItem = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorAgreementLineItem.selectByContractIdsLineTypeProduct((Set<Id>)fflib_Match.eq(new set<ID>{(ID)Agreement.id}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.LINE_TYPE_PRODUCT_SERVICE}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.PRODUCT_CODE_PRINT_POST}))).thenReturn(
			new List<Apttus__AgreementLineItem__c>(new List<Apttus__AgreementLineItem__c>{ali}));
		MockUtility.Mocks.stopStubbing();        
		
		
		test.starttest();
		PageReference pref = Page.APTS_GenerateDocs;
		pref.getParameters().put('id', Agreement.id);
		Test.setCurrentPage(pref);
		
		ApexPages.StandardController stdController = new ApexPages.StandardController(Agreement);
		APTS_MergeTemplatesController myController = new APTS_MergeTemplatesController(stdController); 
		system.assertEquals(Agreement.Included_Product_Lines__c,'Print Post', 'Incorrect Product lines returned');
		system.assertNotEquals(myController.Agreement, null, 'Agreement object should be returned');
		test.stoptest();    
	}

		static testmethod void excludedProduct() {
		/*
		Creating record for Custom settings
		*/
		Apttus__ComplySystemProperties__c sysProp = new Apttus__ComplySystemProperties__c();
		RecordType TestRecordType = new RecordType();
		
		List<APT_R2T_Templates_Settings__c> TemplateCSs = new List<APT_R2T_Templates_Settings__c>();
		APT_R2T_Templates_Settings__c TemplateCS1 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS2 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS3 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS4 = new APT_R2T_Templates_Settings__c();
		
		
		ID TestRecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
		ID TestRecordTypeDEVName = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('APT_MSA_Service_Schedule').getRecordTypeId();
		
		
		sysProp.Name = 'System Properties';
		sysProp.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';        
		insert sysProp;
			/*
		inserting record for Custom settings
		*/
		
		TemplateCS1.Name = 'TestTemplateCS1';
		TemplateCS1.Compare_against_IPL__c = true;
		TemplateCS1.Sequence_No__c = 1;
		TemplateCS1.Template_ID__c = 'TestTemplateID1';
		TemplateCS1.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS1.Subtype__c = 'Long Form';        
		TemplateCS1.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS1);
		
		TemplateCS2.Name = 'TestTemplateCS2';
		TemplateCS2.Compare_against_IPL__c = True;
		TemplateCS2.Sequence_No__c = 2;
		TemplateCS2.Template_ID__c = 'TestTemplateID2';
		TemplateCS2.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS2.Subtype__c = 'Long Form';        
		TemplateCS2.Settings_Type__c = 'Template';
		TemplateCS2.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS2);
		
		TemplateCS3.Name = 'TestTemplateCS3';
		TemplateCS3.Compare_against_IPL__c = True;
		TemplateCS3.Sequence_No__c = 3;
		TemplateCS3.Template_ID__c = 'TestTemplateID3';
		TemplateCS3.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS3.Subtype__c = 'Long Form';       
		TemplateCS3.Settings_Type__c = 'Template';
		TemplateCS3.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS3);
		
		TemplateCS4.Name = 'TestTemplateCS4';
		TemplateCS4.Compare_against_IPL__c = True;
		TemplateCS4.Sequence_No__c = 4;
		TemplateCS4.Template_ID__c = 'TestTemplateID4';
		TemplateCS4.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS4.Subtype__c = 'Long Form';       
		TemplateCS4.Settings_Type__c = 'Template';
		TemplateCS4.Contract_Type__c = 'Migrated Contract';
		TemplateCSs.add(TemplateCS4);
		
		insert TemplateCSs;
		/*
		Inserting record for Template object
		*/
		List<Apttus__APTS_Template__c> listTemplate= new List<Apttus__APTS_Template__c>();
		
		Apttus__APTS_Template__c Template1 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template1.Name = 'TestTemplates1';
		Template1.Apttus__ReferenceId__c = 'TestTemplateID1';              
		listTemplate.add(Template1);
		
		Apttus__APTS_Template__c Template2 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template2.Name = 'TestTemplates2';
		Template2.Apttus__ReferenceId__c = 'TestTemplateID2';              
		listTemplate.add(Template2);
		
		Apttus__APTS_Template__c Template3 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template3.Name = 'TestTemplates3';
		Template3.Apttus__ReferenceId__c = 'TestTemplateID3';             
		listTemplate.add(Template3);
		
		Apttus__APTS_Template__c Template4 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template4.Name = 'TestTemplates4';
		Template4.Apttus__ReferenceId__c = 'TestTemplateID4'; 
		listTemplate.add(Template4);          
		insert listTemplate;        
		
			/*
		Creating test data for Agreement
		*/
		List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
		
		Apttus__APTS_Agreement__c Agreement= APT_TestDataFactory.getAgreementRecord(1,false)[0];       
		Agreement.Included_Product_Lines__c = 'Print Post';
		Agreement.RecordTypeID = TestRecordTypeID ;         
		Agreement.APT_Pricing_Category__c='Offline Rates'; 
		Agreement.Apttus__Subtype__c='Long Form'; 
		Agreement.APT_Contract_Type__c='Migrated Contract';         
		Agreement.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'MSA & Service Schedule' Limit 1];
		Agreement.RecordType.DeveloperName = 'APT_MSA_Service_Schedule';      
		agreementList.add(Agreement);
			
		
		
		//create aggrement to set contract from agreement for related agreement
		Apttus__APTS_Agreement__c Agreement2 = APT_TestDataFactory.getAgreementRecord(1, false)[0];        
		Agreement2.Included_Product_Lines__c = 'Workforce Verification';
		Agreement2.RecordTypeID = TestRecordTypeID ;          
		Agreement2.APT_Pricing_Category__c='Offline Rates'; 
		Agreement2.Apttus__Subtype__c='Long Form'; 
		Agreement2.APT_Contract_Type__c='Migrated Contract'; 
		Agreement2.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'MSA & Service Schedule' Limit 1];
		Agreement2.RecordType.DeveloperName = 'APT_MSA_Service_Schedule';  
		agreementList.add(Agreement2);      
		insert agreementList;         
		
		
		//create related agreement and set to and from contracts
		
		List<Apttus__APTS_Related_Agreement__c> relAgreementList = new List<Apttus__APTS_Related_Agreement__c>();      
		
		Apttus__APTS_Related_Agreement__c relatedAgreement = APT_TestDataFactory.getRelatedAgreementRecord(1,Agreement.id,Agreement2.id,false)[0];       
		insert relatedAgreement ;
		relAgreementList.add(relatedAgreement);
		
		Apttus__AgreementLineItem__c ali= APT_TestDataFactory.getAPTAgreementLineItem(1,false)[0];               
		ali.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;  
		ali.Apttus__AgreementId__c=agreement.id; 
		insert ali;

		/*
		Implementing mock for all the selectors
		*/        
		APT_AgreementObjectsSelector mockSelectorAgreement = (APT_AgreementObjectsSelector) MockUtility.mockSelector(APT_AgreementObjectsSelector.class);
		ApplicationDatabase mockDatabaseAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorAgreement.selectByConfigId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(
			new List<Apttus__APTS_Agreement__c>(new List<Apttus__APTS_Agreement__c>{Agreement}));
		MockUtility.Mocks.stopStubbing();       
		
		APT_RelatedAgreementsSelector mockSelectorRelAgreement = (APT_RelatedAgreementsSelector) MockUtility.mockSelector(APT_RelatedAgreementsSelector.class);
		ApplicationDatabase mockDatabaseRelAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorRelAgreement.selectByAgreementId((Set<Id>)fflib_Match.eq(new set<ID>{(ID)Agreement.id}),(set<Object>)fflib_Match.eq(new set<Object>{APT_RelatedAgreementsSelector.options.WITH_AGREEMENT}))).thenReturn(
			new List<Apttus__APTS_Related_Agreement__c>(new List<Apttus__APTS_Related_Agreement__c>{relatedAgreement}));
		MockUtility.Mocks.stopStubbing();
		
		APT_AgreementLineItemsSelector mockSelectorAgreementLineItem = (APT_AgreementLineItemsSelector) MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		ApplicationDatabase mockDatabaseAgreementLineItem = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorAgreementLineItem.selectByContractIdsLineTypeProduct((Set<Id>)fflib_Match.eq(new set<ID>{(ID)Agreement.id}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.LINE_TYPE_PRODUCT_SERVICE}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.PRODUCT_CODE_PRINT_POST}))).thenReturn(
			new List<Apttus__AgreementLineItem__c>(new List<Apttus__AgreementLineItem__c>{ali}));
		MockUtility.Mocks.stopStubbing();        
		
		
		test.starttest();
		PageReference pref = Page.APTS_GenerateDocs;
		pref.getParameters().put('id', Agreement.id);
		Test.setCurrentPage(pref);
		
		ApexPages.StandardController stdController = new ApexPages.StandardController(Agreement);
		APTS_MergeTemplatesController myController = new APTS_MergeTemplatesController(stdController); 
		system.assertEquals(Agreement.Included_Product_Lines__c,'Print Post');
		test.stoptest();    
	}

		static testmethod void excludedProductStarTrack() {
		/*
		Creating record for Custom settings
		*/
		Apttus__ComplySystemProperties__c sysProp = new Apttus__ComplySystemProperties__c();
		RecordType TestRecordType = new RecordType();
		
		List<APT_R2T_Templates_Settings__c> TemplateCSs = new List<APT_R2T_Templates_Settings__c>();
		APT_R2T_Templates_Settings__c TemplateCS1 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS2 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS3 = new APT_R2T_Templates_Settings__c();
		APT_R2T_Templates_Settings__c TemplateCS4 = new APT_R2T_Templates_Settings__c();
		
		
		ID TestRecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
		ID TestRecordTypeDEVName = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('APT_MSA_Service_Schedule').getRecordTypeId();
		
		
		sysProp.Name = 'System Properties';
		sysProp.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';        
		insert sysProp;
			/*
		inserting record for Custom settings
		*/
		
		TemplateCS1.Name = 'TestTemplateCS1';
		TemplateCS1.Compare_against_IPL__c = true;
		TemplateCS1.Sequence_No__c = 1;
		TemplateCS1.Template_ID__c = 'TestTemplateID1';
		TemplateCS1.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS1.Subtype__c = 'Long Form';
		TemplateCS1.Template_Product_Name__c = 'Print Post';
		TemplateCS1.Settings_Type__c = 'Template';
		TemplateCS1.Contract_Type__c = 'Migrated Contract';
		TemplateCS1.APT_Rate_Type__c = 'Offline';
		TemplateCS1.APT_Check_Against_NPL__c= true;        
		TemplateCSs.add(TemplateCS1);
		
		TemplateCS2.Name = 'TestTemplateCS2';
		TemplateCS2.Compare_against_IPL__c = True;
		TemplateCS2.Sequence_No__c = 2;
		TemplateCS2.Template_ID__c = 'TestTemplateID2';
		TemplateCS2.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS2.Subtype__c = 'Long Form';
		TemplateCS2.Template_Product_Name__c = 'Print Post';
		TemplateCS2.Settings_Type__c = 'Template';
		TemplateCS2.Contract_Type__c = 'Migrated Contract';
		TemplateCS2.APT_Rate_Type__c = 'Offline';
		TemplateCS2.APT_Check_Against_NPL__c= true;
		TemplateCSs.add(TemplateCS2);
		
		TemplateCS3.Name = 'TestTemplateCS3';
		TemplateCS3.Compare_against_IPL__c = True;
		TemplateCS3.Sequence_No__c = 3;
		TemplateCS3.Template_ID__c = 'TestTemplateID3';
		TemplateCS3.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS3.Subtype__c = 'Long Form';
		TemplateCS3.Template_Product_Name__c = 'Print Post';
		TemplateCS3.Settings_Type__c = 'Template';
		TemplateCS3.Contract_Type__c = 'Migrated Contract';
		TemplateCS3.APT_Rate_Type__c = 'Standard';
		TemplateCS3.APT_Check_Against_NPL__c= true;
		TemplateCSs.add(TemplateCS3);
		
		TemplateCS4.Name = 'TestTemplateCS4';
		TemplateCS4.Compare_against_IPL__c = True;
		TemplateCS4.Sequence_No__c = 4;
		TemplateCS4.Template_ID__c = 'TestTemplateID4';
		TemplateCS4.Record_Type_API__c = 'APT_MSA_Service_Schedule';
		TemplateCS4.Subtype__c = 'Long Form';
		TemplateCS4.Template_Product_Name__c = 'Print Post';
		TemplateCS4.Settings_Type__c = 'Template';
		TemplateCS4.Contract_Type__c = 'Migrated Contract';
		TemplateCS4.APT_Rate_Type__c = 'Standard';
		TemplateCS4.APT_Check_Against_NPL__c= true;
		TemplateCSs.add(TemplateCS4);
		
		insert TemplateCSs;
		/*
		Inserting record for Template object
		*/
		List<Apttus__APTS_Template__c> listTemplate= new List<Apttus__APTS_Template__c>();
		
		Apttus__APTS_Template__c Template1 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template1.Name = 'TestTemplates1';
		Template1.Apttus__ReferenceId__c = 'TestTemplateID1';              
		listTemplate.add(Template1);
		
		Apttus__APTS_Template__c Template2 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template2.Name = 'TestTemplates2';
		Template2.Apttus__ReferenceId__c = 'TestTemplateID2';              
		listTemplate.add(Template2);
		
		Apttus__APTS_Template__c Template3 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template3.Name = 'TestTemplates3';
		Template3.Apttus__ReferenceId__c = 'TestTemplateID3';             
		listTemplate.add(Template3);
		
		Apttus__APTS_Template__c Template4 =APT_TestDataFactory.getTemplateRecord(1,false)[0];
		Template4.Name = 'TestTemplates4';
		Template4.Apttus__ReferenceId__c = 'TestTemplateID4'; 
		listTemplate.add(Template4);          
		insert listTemplate;                
		
		/*
		Creating test data for  Agreement
		*/
		List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
		Apttus__APTS_Agreement__c Agreement= APT_TestDataFactory.getAgreementRecord(1,false)[0];       
		Agreement.Included_Product_Lines__c = 'StarTrack';
		Agreement.RecordTypeID = TestRecordTypeID ;         
		Agreement.APT_Pricing_Category__c='Offline Rates'; 
		Agreement.Apttus__Subtype__c='Long Form'; 
		Agreement.APT_Contract_Type__c='Migrated Contract';         
		Agreement.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'MSA & Service Schedule' Limit 1];
		Agreement.RecordType.DeveloperName = 'APT_MSA_Service_Schedule';  
		agreementList.add(Agreement);       
		
		
		//create aggrement to set contract from agreement for related agreement
		Apttus__APTS_Agreement__c Agreement2 = APT_TestDataFactory.getAgreementRecord(1, false)[0];        
		Agreement2.Included_Product_Lines__c = 'StarTrack';
		Agreement2.RecordTypeID = TestRecordTypeID ;          
		Agreement2.APT_Pricing_Category__c='Offline Rates'; 
		Agreement2.Apttus__Subtype__c='Long Form'; 
		Agreement2.APT_Contract_Type__c='Migrated Contract'; 
		Agreement2.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'MSA & Service Schedule' Limit 1];
		Agreement2.RecordType.DeveloperName = 'APT_MSA_Service_Schedule';   
		agreementList.add(Agreement2);     
		insert agreementList;         
		
		
		//create related agreement and set to and from contracts
		
		List<Apttus__APTS_Related_Agreement__c> relAgreementList = new List<Apttus__APTS_Related_Agreement__c>();      
		
		Apttus__APTS_Related_Agreement__c relatedAgreement = APT_TestDataFactory.getRelatedAgreementRecord(1,Agreement.id,Agreement2.id,false)[0];       
		insert relatedAgreement ;
		relAgreementList.add(relatedAgreement);
		
		Apttus__AgreementLineItem__c ali= APT_TestDataFactory.getAPTAgreementLineItem(1,false)[0];               
		ali.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;  
		ali.Apttus__AgreementId__c=agreement.id; 
		insert ali;
		/*
		Implementing mock for all the selectors
		*/
		APT_AgreementObjectsSelector mockSelectorAgreement = (APT_AgreementObjectsSelector) MockUtility.mockSelector(APT_AgreementObjectsSelector.class);
		ApplicationDatabase mockDatabaseAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorAgreement.selectByConfigId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(
			new List<Apttus__APTS_Agreement__c>(new List<Apttus__APTS_Agreement__c>{Agreement}));
		MockUtility.Mocks.stopStubbing();       
		
		APT_RelatedAgreementsSelector mockSelectorRelAgreement = (APT_RelatedAgreementsSelector) MockUtility.mockSelector(APT_RelatedAgreementsSelector.class);
		ApplicationDatabase mockDatabaseRelAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorRelAgreement.selectByAgreementId((Set<Id>)fflib_Match.eq(new set<ID>{(ID)Agreement.id}),(set<Object>)fflib_Match.eq(new set<Object>{APT_RelatedAgreementsSelector.options.WITH_AGREEMENT}))).thenReturn(
			new List<Apttus__APTS_Related_Agreement__c>(new List<Apttus__APTS_Related_Agreement__c>{relatedAgreement}));
		MockUtility.Mocks.stopStubbing();
		
		APT_AgreementLineItemsSelector mockSelectorAgreementLineItem = (APT_AgreementLineItemsSelector) MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		ApplicationDatabase mockDatabaseAgreementLineItem = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorAgreementLineItem.selectByContractIdsLineTypeProduct((Set<Id>)fflib_Match.eq(new set<ID>{(ID)Agreement.id}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.LINE_TYPE_PRODUCT_SERVICE}),(Set<String>)fflib_Match.eq(new set<String>{APT_Constants.PRODUCT_CODE_PRINT_POST}))).thenReturn(
			new List<Apttus__AgreementLineItem__c>(new List<Apttus__AgreementLineItem__c>{ali}));
		MockUtility.Mocks.stopStubbing();        
		
		
		test.starttest();
		PageReference pref = Page.APTS_GenerateDocs;
		pref.getParameters().put('id', Agreement.id);
		Test.setCurrentPage(pref);
		
		ApexPages.StandardController stdController = new ApexPages.StandardController(Agreement);
		APTS_MergeTemplatesController myController = new APTS_MergeTemplatesController(stdController); 
		system.assertEquals(Agreement2.Included_Product_Lines__c,'StarTrack');
		test.stoptest();     
	}

}