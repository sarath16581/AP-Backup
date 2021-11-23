/**************************************************
@ModifiedBy: Meet Desai
@ModifiedOn: 6 March, 2020
@Description: Updated Merge Documents logic to refer Files/ Content Documents instead of Attachments
**************************************************/
@isTest
private class APTS_MergeDocumentstoPDFControllerTest { 

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
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        
        ID TestRecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        
        sysProp.Name = 'System Properties';
        sysProp.Apttus__InstanceUrl__c = System.URL.getSalesforceBaseUrl().toExternalForm();
        insert sysProp;
        
        TemplateCS1.Name = 'TestTemplateCS1';
        TemplateCS1.Compare_against_IPL__c = False;
        TemplateCS1.Sequence_No__c = 1;
        TemplateCS1.Template_ID__c = 'TestTemplateID1';
        TemplateCS1.Record_Type_API__c = 'APT_MSA_Service_Schedule';
        TemplateCS1.Subtype__c = 'TestSubType';
        TemplateCS1.Settings_Type__c = 'Template';
        TemplateCSs.add(TemplateCS1);
        
        TemplateCS2.Name = 'TestTemplateCS2';
        TemplateCS2.Compare_against_IPL__c = True;
        TemplateCS2.Sequence_No__c = 2;
        TemplateCS2.Template_ID__c = 'TestTemplateID2';
        TemplateCS2.Record_Type_API__c = 'APT_MSA_Service_Schedule';
        TemplateCS2.Subtype__c = 'TestSubType';
        TemplateCS2.Template_Product_Name__c = 'TestProductName';
        TemplateCS2.Settings_Type__c = 'Template';
        TemplateCSs.add(TemplateCS2);
        
        TemplateCS3.Name = 'TestTemplateCS3';
        TemplateCS3.Compare_against_IPL__c = True;
        TemplateCS3.Sequence_No__c = 3;
        TemplateCS3.Template_ID__c = 'TestTemplateID3';
        TemplateCS3.Record_Type_API__c = 'APT_MSA_Service_Schedule';
        TemplateCS3.Subtype__c = 'TestSubType';
        TemplateCS3.Template_Product_Name__c = 'WrongProductName';
        TemplateCS3.Settings_Type__c = 'Template';
        TemplateCSs.add(TemplateCS3);
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

        /* Start: Meet Desai: Created Content Version Records */
        ContentVersion contentVersionMergedDoc = new ContentVersion();
		contentVersionMergedDoc.Title = 'testMergedDocument';
        contentVersionMergedDoc.PathOnClient = 'testMergedDocument.pdf';
    	contentVersionMergedDoc.VersionData = Blob.valueOf('Test Merged Content');
        contentVersionMergedDoc.IsMajorVersion = true;
       	contentVersionList.add(contentVersionMergedDoc);
      
        ContentVersion contentVersion1 = new ContentVersion();
        contentVersion1.Title = 'testDocument1';
        contentVersion1.PathOnClient = 'testDocument1.pdf';
    	contentVersion1.VersionData = Blob.valueOf('Test Content 1');
        contentVersion1.IsMajorVersion = true;
       	contentVersionList.add(contentVersion1);
        
        ContentVersion contentVersion2 = new ContentVersion();       
        contentVersion2.Title = 'testDocument2';
        contentVersion2.PathOnClient = 'testDocument2.pdf';
    	contentVersion2.VersionData = Blob.valueOf('Test Content 2');
        contentVersion2.IsMajorVersion = true;
       	contentVersionList.add(contentVersion2);
        insert contentVersionList;
        /* End: Meet Desai: Created Content Version Records */
        
        Agreement.Name = 'UnitTestAgreementUniqueXAWEGP';
        Agreement.Apttus__Subtype__c = 'TestSubType';
        Agreement.Included_Product_Lines__c = 'TestProductName';
        Agreement.RecordTypeID = TestRecordTypeID;
        insert Agreement;
        
        PageReference pref = Page.APTS_CombineDocs;
        pref.getParameters().put('id', Agreement.id);
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController stdControllerNoFiles = new ApexPages.StandardController(Agreement);
        APTS_MergeDocumentstoPDFController myControllerNoFiles = new APTS_MergeDocumentstoPDFController(stdControllerNoFiles);
        
        /* Start: Meet Desai: Created Content Document Link Records */
        List<ContentDocument> contentDocumentList = [select Id, Title, FileExtension from ContentDocument];
        for (ContentDocument contentDocument : contentDocumentList){
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.LinkedEntityId = Agreement.Id;
            contentDocumentLink.ContentDocumentId = contentDocument.Id;
            contentDocumentLinkList.Add(contentDocumentLink);
        }
        insert contentDocumentLinkList;
        /* End: Meet Desai: Created Content Document Link Records */
        
        Agreement.Document_Generated_by_Merge__c = [select Id from ContentDocument where Title =: 'testMergedDocument'].Id;
        update Agreement;
        
        PageReference pref2 = Page.APTS_CombineDocs;
        pref2.getParameters().put('id', Agreement.id);
        Test.setCurrentPage(pref2);
        
        ApexPages.StandardController stdControllerWithFiles = new ApexPages.StandardController(Agreement);
        APTS_MergeDocumentstoPDFController myControllerWithFiles = new APTS_MergeDocumentstoPDFController(stdControllerWithFiles);
        
        myControllerWithFiles.fileID = myControllerWithFiles.lstWrapper[1].contentDoc.Id;
        myControllerWithFiles.upAction();
        myControllerWithFiles.fileID = myControllerWithFiles.lstWrapper[0].contentDoc.Id;
        myControllerWithFiles.upAction();
        
        myControllerWithFiles.fileID = myControllerWithFiles.lstWrapper[1].contentDoc.Id;
        myControllerWithFiles.downAction();
        myControllerWithFiles.fileID = myControllerWithFiles.lstWrapper[0].contentDoc.Id;
        myControllerWithFiles.downAction();
        
        myControllerWithFiles.lstWrapper[0].selected = true;
        
        myControllerWithFiles.Cancel();
        myControllerWithFiles.MergeInitialization();
        myControllerWithFiles.MergeDocument();
    }
}