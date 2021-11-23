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
        List<APT_R2T_Templates_Settings__c> TemplateCSs = new List<APT_R2T_Templates_Settings__c>();
        APT_R2T_Templates_Settings__c TemplateCS1 = new APT_R2T_Templates_Settings__c();
        APT_R2T_Templates_Settings__c TemplateCS2 = new APT_R2T_Templates_Settings__c();
        APT_R2T_Templates_Settings__c TemplateCS3 = new APT_R2T_Templates_Settings__c();
        APT_R2T_Templates_Settings__c TemplateCS4 = new APT_R2T_Templates_Settings__c();
        Apttus__APTS_Template__c Template1 = new Apttus__APTS_Template__c();
        Apttus__APTS_Template__c Template2 = new Apttus__APTS_Template__c();
        Apttus__APTS_Template__c Template3 = new Apttus__APTS_Template__c();
        Apttus__APTS_Template__c Template4 = new Apttus__APTS_Template__c();
        Apttus__APTS_Agreement__c Agreement = new Apttus__APTS_Agreement__c();
        Apttus__APTS_Agreement__c Agreement2 = new Apttus__APTS_Agreement__c();
        
        ID TestRecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        
        sysProp.Name = 'System Properties';
        sysProp.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';
        
        insert sysProp;
        
        
        TemplateCS1.Name = 'TestTemplateCS1';
        TemplateCS1.Compare_against_IPL__c = False;
        TemplateCS1.Sequence_No__c = 1;
        TemplateCS1.Template_ID__c = 'TestTemplateID1';
        TemplateCS1.Record_Type_API__c = 'APT_MSA_Service_Schedule';
        TemplateCS1.Subtype__c = 'Long Form';
        TemplateCS1.Settings_Type__c = 'Template';
        TemplateCSs.add(TemplateCS1);
        
        TemplateCS2.Name = 'TestTemplateCS2';
        TemplateCS2.Compare_against_IPL__c = True;
        TemplateCS2.Sequence_No__c = 2;
        TemplateCS2.Template_ID__c = 'TestTemplateID2';
        TemplateCS2.Record_Type_API__c = 'APT_MSA_Service_Schedule';
        TemplateCS2.Subtype__c = 'Long Form';
        TemplateCS2.Template_Product_Name__c = 'Print Post';
        TemplateCS2.Settings_Type__c = 'Template';
        TemplateCSs.add(TemplateCS2);
        
        TemplateCS3.Name = 'TestTemplateCS3';
        TemplateCS3.Compare_against_IPL__c = True;
        TemplateCS3.Sequence_No__c = 3;
        TemplateCS3.Template_ID__c = 'TestTemplateID3';
        TemplateCS3.Record_Type_API__c = 'APT_MSA_Service_Schedule';
        TemplateCS3.Subtype__c = 'Long Form';
        TemplateCS3.Template_Product_Name__c = 'WrongProductName';
        TemplateCS3.Settings_Type__c = 'Template';
        TemplateCSs.add(TemplateCS3);
        
        TemplateCS4.Name = 'TestTemplateCS4';
        TemplateCS4.Compare_against_IPL__c = True;
        TemplateCS4.Sequence_No__c = 4;
        TemplateCS4.Template_ID__c = 'TestTemplateID4';
        TemplateCS4.Record_Type_API__c = 'APT_MSA_Service_Schedule';
        TemplateCS4.Subtype__c = 'Long Form';
        TemplateCS4.Template_Product_Name__c = 'Print Post';
        TemplateCS4.Settings_Type__c = 'Template';
        TemplateCSs.add(TemplateCS4);
        
        insert TemplateCSs;
        
        Template1.Name = 'TestTemplates1';
        Template1.Apttus__ReferenceId__c = 'TestTemplateID1';
        Template1.Apttus__Agreement_Types__c = 'APT_MSA_Service_Schedule';
        
        insert Template1;
        
        Template2.Name = 'TestTemplates2';
        Template2.Apttus__ReferenceId__c = 'TestTemplateID2';
        Template2.Apttus__Agreement_Types__c = 'APT_MSA_Service_Schedule';
        
        insert Template2;
        
        Template3.Name = 'TestTemplates3';
        Template3.Apttus__ReferenceId__c = 'TestTemplateID3';
        Template3.Apttus__Agreement_Types__c = 'APT_MSA_Service_Schedule';
        
        insert Template3;
        
        Template4.Name = 'TestTemplates4';
        Template4.Apttus__ReferenceId__c = 'TestTemplateID4';
        Template4.Apttus__Agreement_Types__c = 'APT_MSA_Service_Schedule';
        
        insert Template4;
        
        Agreement.Name = 'Test';
        Agreement.Apttus__Subtype__c = 'TestSubType';
        Agreement.Included_Product_Lines__c = 'Print Post';
        Agreement.RecordTypeID = TestRecordTypeID;        
        insert Agreement;
        
	//create aggrement to set contract from agreement for related agreement
        Agreement2.Name = 'Test';
        Agreement2.Apttus__Subtype__c = 'TestSubType';
        Agreement2.Included_Product_Lines__c = 'Workforce Verification';
        Agreement2.RecordTypeID = TestRecordTypeID;        
        insert Agreement2;
        
	//create related agreement and set to and from contracts
        Apttus__APTS_Related_Agreement__c relatedAgreement = new Apttus__APTS_Related_Agreement__c();
        relatedAgreement.Apttus__APTS_Contract_To__c = Agreement.Id;
        relatedAgreement.Apttus__APTS_Contract_From__c = Agreement2.Id;
        insert relatedAgreement;
        
        PageReference pref = Page.APTS_GenerateDocs;
        pref.getParameters().put('id', Agreement.id);
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(Agreement);
        APTS_MergeTemplatesController myController = new APTS_MergeTemplatesController(stdController);
        
        myController.GenerateDocument();
        
        myController.templateID = myController.lstTemplateWrapper[2].template.Id;
        myController.upAction();
        myController.templateID = myController.lstTemplateWrapper[1].template.Id;
        myController.upAction();
        myController.templateID = myController.lstTemplateWrapper[0].template.Id;
        myController.upAction();
        
        myController.templateID = myController.lstTemplateWrapper[2].template.Id;
        myController.downAction();
        myController.templateID = myController.lstTemplateWrapper[1].template.Id;
        myController.downAction();
        myController.templateID = myController.lstTemplateWrapper[0].template.Id;
        myController.downAction();
        
        
        myController.Cancel();
        //myController.processDocs();
    }

    static testmethod void mergeOfflineTemplates() {
        
        Apttus__ComplySystemProperties__c sysProp = new Apttus__ComplySystemProperties__c();
        RecordType TestRecordType = new RecordType();
        List<APT_R2T_Templates_Settings__c> TemplateCSs = new List<APT_R2T_Templates_Settings__c>();
        APT_R2T_Templates_Settings__c TemplateCS1 = new APT_R2T_Templates_Settings__c();
        APT_R2T_Templates_Settings__c TemplateCS2 = new APT_R2T_Templates_Settings__c();
        APT_R2T_Templates_Settings__c TemplateCS3 = new APT_R2T_Templates_Settings__c();
        APT_R2T_Templates_Settings__c TemplateCS4 = new APT_R2T_Templates_Settings__c();
        Apttus__APTS_Template__c Template1 = new Apttus__APTS_Template__c();
        Apttus__APTS_Template__c Template2 = new Apttus__APTS_Template__c();
        Apttus__APTS_Template__c Template3 = new Apttus__APTS_Template__c();
        Apttus__APTS_Template__c Template4 = new Apttus__APTS_Template__c();
        Apttus__APTS_Agreement__c Agreement = new Apttus__APTS_Agreement__c();
        Apttus__APTS_Agreement__c Agreement2 = new Apttus__APTS_Agreement__c();
        
        ID TestRecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        
        sysProp.Name = 'System Properties';
        sysProp.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';
        insert sysProp;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(null);
        r2tSystemProperties.APT_Contract_Templates_To_Uncheck__c = 'R2T Pricing Schedule, StarTrack Pricing Schedule';
        insert r2tSystemProperties;
        
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
        
        Template1.Name = 'TestTemplates1';
        Template1.Apttus__ReferenceId__c = 'TestTemplateID1';
        Template1.Apttus__Agreement_Types__c = 'APT_MSA_Service_Schedule';
        
        insert Template1;
        
        Template2.Name = 'TestTemplates2';
        Template2.Apttus__ReferenceId__c = 'TestTemplateID2';
        Template2.Apttus__Agreement_Types__c = 'APT_MSA_Service_Schedule';
        
        insert Template2;
        
        Template3.Name = 'TestTemplates3';
        Template3.Apttus__ReferenceId__c = 'TestTemplateID3';
        Template3.Apttus__Agreement_Types__c = 'APT_MSA_Service_Schedule';
        
        insert Template3;
        
        Template4.Name = 'TestTemplates4';
        Template4.Apttus__ReferenceId__c = 'TestTemplateID4';
        Template4.Apttus__Agreement_Types__c = 'APT_MSA_Service_Schedule';
        
        insert Template4;

        //Create pricelist
        Apttus_Config2__PriceList__c priceList = APT_TestUtil2.createPriceList();
        insert priceList;

        //Create test organisation
        Account accVar = APT_TestUtil2.createOrganisation();
        insert accVar;

        //Create test opportunity
        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);
        oppVar.StageName = 'Identify';
        insert oppVar;

        //Create proposal
        Apttus_Proposal__Proposal__c proposalVar = APT_TestUtil2.createQuoteProposalNoAgrmnt(accVar, oppVar, APT_Constants.RECORD_TYPE_PROPOSAL, priceList);
        insert proposalVar;

        proposalVar.APT_Use_Offline_Rates__c = true;
        update proposalVar;
        
        Agreement.Name = 'Test';
        Agreement.Apttus__Subtype__c = 'TestSubType';
        Agreement.RecordTypeID = TestRecordTypeID;        
        Agreement.Apttus_QPComply__RelatedProposalId__c = proposalVar.Id;        
        Agreement.APT_Pricing_Category__c = 'Offline';        
        Agreement.Included_Product_Lines__c = 'StarTrack';        
        insert Agreement;
        
        PageReference pref = Page.APTS_GenerateDocs;
        pref.getParameters().put('id', Agreement.id);
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(Agreement);
        APTS_MergeTemplatesController myController = new APTS_MergeTemplatesController(stdController);
        
        myController.GenerateDocument();

        myController.processSubmitDocs();
    }
}