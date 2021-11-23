/**
 * This apex class is test class for apex class - APT_AsyncMergeCallTriggerHandler
 * Created By - Akshay Mewada
 * Created Date - 28th June, 2016
 */ 
 @isTest
private class APT_AsyncMergeCallTriggerHandlerTest {

    /*
        Test Method to Test Functionality and Generate data
    */
    public static testMethod void test_DML()
    {
        Apttus__ComplySystemProperties__c custSettings = new Apttus__ComplySystemProperties__c();
        custSettings.Name = 'System Properties';
        custSettings.Apttus__AllowPDFSelectionOverride__c = true;
        custSettings.Apttus__AllowPrivateSelectionOverride__c = true;
        custSettings.Apttus__AllowReconcileSelectionOverride__c = true;
        custSettings.Apttus__AutoEnablePDFForFinalDocs__c = true;
        custSettings.Apttus__BypassSharing__c = true;
        custSettings.Apttus__DefaultOpportunityAgreementOwner__c = 'Current User';
        custSettings.Apttus__EnableClauseApprovals__c = true;
        custSettings.Apttus__EnableSubmitMergeCall__c = true;
        custSettings.Apttus_CMDSign__AutoSelectAttachment__c = true;
        custSettings.Apttus_CMDSign__AutoSelectMultipleRecipients__c = true;
        custSettings.Apttus_CMDSign__EnableDocumentPreviewInDocuSign__c = true;
        custSettings.Apttus__DocumentStructureFX2ForImportedDocs__c = true;
        custSettings.Apttus__EnableDocumentVersioning__c = true;
        custSettings.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';
        custSettings.Apttus__MergeWebserviceEndpoint__c = 'https://mergews.apttus.net/cgi-bin/4.2.1.2/MergeServer/Bin/MMCGI.exe';
        custSettings.Apttus__MergeCallTimeoutMillis__c = 120;
        insert custSettings;

        Apttus__APTS_Agreement__c agrObj = new Apttus__APTS_Agreement__c();
        agrObj.APT_Merge_Documents__c = true;
        agrObj.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        insert agrObj;

        Attachment attachmentObj = new Attachment();
        attachmentObj.body = Blob.valueOf('Temp');
        attachmentObj.parentId = agrObj.ID;
        attachmentObj.Name = 'Temp attachment';
        insert attachmentObj;

        agrObj.APT_Generated_Doc_Ids__c = attachmentObj.Id;
        update agrObj;

        Apttus__APTS_Template__c templateObj = new Apttus__APTS_Template__c();
        templateObj.Name = 'Temp template';
        templateObj.Apttus__Type__c = APT_Constants.TYPE_AGR;
        templateObj.Apttus__Agreement_Types__c = APT_Constants.AGR_TYPE_MSA_SERVICE;
        templateObj.Apttus__Category__c = APT_Constants.CATG_SUBMIT;
        templateObj.Apttus__Subcategory__c = APT_Constants.SUBCATG_DEFAULT;
        templateObj.Apttus__Language__c = APT_Constants.LANG_ENG;
        templateObj.Apttus__Locale__c = APT_Constants.LOCALE_ENG;
        templateObj.Apttus__IsActive__c = true;
        insert templateObj;
        
        Test.startTest();
        Apttus__AsyncMergeCall__c asyncMergeObj = new Apttus__AsyncMergeCall__c();
        asyncMergeObj.Apttus__Agreement__c = agrObj.Id;
        asyncMergeObj.Apttus__Template__c = templateObj.Id;
        asyncMergeObj.Apttus__Status__c = APT_Constants.STATUS_FAILED;
        asyncMergeObj.Apttus__Action__c = APT_Constants.ASYNC_ACTION_GENERATE;
        asyncMergeObj.Apttus__StartTime__c = Datetime.now();
        asyncMergeObj.Apttus__EndTime__c = Datetime.now().addMinutes(10);
        asyncMergeObj.Apttus__CallType__c = APT_Constants.ASYNC_CALL_TYPE;
        asyncMergeObj.Apttus__DocumentFormat__c = APT_Constants.ASYNC_DOC_TYPE_PDF;
        asyncMergeObj.Apttus__ProtectionLevel__c = APT_Constants.ASYNC_PROTE_LEVEL_COMMENT_AND_TRACK_CHANGE;
        insert asyncMergeObj;

        asyncMergeObj = [SELECT ID, Apttus__Result__c, Apttus__Status__c FROM Apttus__AsyncMergeCall__c WHERE ID = :asyncMergeObj.Id];
        asyncMergeObj.Apttus__Result__c = attachmentObj.Id;
        asyncMergeObj.Apttus__Status__c = APT_Constants.STATUS_CATEGORY;
        update asyncMergeObj;
        Test.stopTest();
    }
     public static testMethod void test_DML1()
    {
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
             proposal.APT_Create_Proposal_Batch_Id__c = '';
             proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
             //proposal.APT_Method_of_Payment__c = 'Charge Account';
             insert Proposal;
        Apttus__ComplySystemProperties__c custSettings = new Apttus__ComplySystemProperties__c();
        custSettings.Name = 'System Properties';
        custSettings.Apttus__AllowPDFSelectionOverride__c = true;
        custSettings.Apttus__AllowPrivateSelectionOverride__c = true;
        custSettings.Apttus__AllowReconcileSelectionOverride__c = true;
        custSettings.Apttus__AutoEnablePDFForFinalDocs__c = true;
        custSettings.Apttus__BypassSharing__c = true;
        custSettings.Apttus__DefaultOpportunityAgreementOwner__c = 'Current User';
        custSettings.Apttus__EnableClauseApprovals__c = true;
        custSettings.Apttus__EnableSubmitMergeCall__c = true;
        custSettings.Apttus_CMDSign__AutoSelectAttachment__c = true;
        custSettings.Apttus_CMDSign__AutoSelectMultipleRecipients__c = true;
        custSettings.Apttus_CMDSign__EnableDocumentPreviewInDocuSign__c = true;
        custSettings.Apttus__DocumentStructureFX2ForImportedDocs__c = true;
        custSettings.Apttus__EnableDocumentVersioning__c = true;
        custSettings.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';
        custSettings.Apttus__MergeWebserviceEndpoint__c = 'https://mergews.apttus.net/cgi-bin/4.2.1.2/MergeServer/Bin/MMCGI.exe';
        custSettings.Apttus__MergeCallTimeoutMillis__c = 120;
        insert custSettings;

        Apttus__APTS_Agreement__c agrObj = new Apttus__APTS_Agreement__c();
        agrObj.APT_Merge_Documents__c = true;
        agrObj.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        insert agrObj;

        Attachment attachmentObj = new Attachment();
        attachmentObj.body = Blob.valueOf('Temp');
        attachmentObj.parentId = Proposal.ID;
        attachmentObj.Name = 'Temp attachment';
        insert attachmentObj;

        agrObj.APT_Generated_Doc_Ids__c = attachmentObj.Id;
        update agrObj;

        Apttus__APTS_Template__c templateObj = new Apttus__APTS_Template__c();
        templateObj.Name = 'Temp template';
        templateObj.Apttus__Type__c = 'Proposal';
        templateObj.Apttus__Agreement_Types__c = APT_Constants.AGR_TYPE_MSA_SERVICE;
        templateObj.Apttus__Category__c = APT_Constants.CATG_SUBMIT;
        templateObj.Apttus__Subcategory__c = APT_Constants.SUBCATG_DEFAULT;
        templateObj.Apttus__Language__c = APT_Constants.LANG_ENG;
        templateObj.Apttus__Locale__c = APT_Constants.LOCALE_ENG;
        templateObj.Apttus__IsActive__c = true;
        insert templateObj;
        
             
        Test.startTest();
        Apttus__AsyncMergeCall__c asyncMergeObj = new Apttus__AsyncMergeCall__c();
        //asyncMergeObj.Apttus__Agreement__c = agrObj.Id;
        asyncMergeObj.Apttus__Template__c = templateObj.Id;
        asyncMergeObj.Apttus__Status__c = APT_Constants.STATUS_FAILED;
        asyncMergeObj.Apttus__Action__c = APT_Constants.ASYNC_ACTION_GENERATE;
        asyncMergeObj.Apttus__StartTime__c = Datetime.now();
        asyncMergeObj.Apttus__EndTime__c = Datetime.now().addMinutes(10);
        asyncMergeObj.Apttus__CallType__c = APT_Constants.ASYNC_CALL_TYPE;
        asyncMergeObj.Apttus__DocumentFormat__c = APT_Constants.ASYNC_DOC_TYPE_PDF;
        asyncMergeObj.Apttus__ProtectionLevel__c = APT_Constants.ASYNC_PROTE_LEVEL_COMMENT_AND_TRACK_CHANGE;
        asyncMergeObj.Apttus_Proposal__QuoteProposalId__c = Proposal.ID;
        insert asyncMergeObj;

        asyncMergeObj = [SELECT ID, Apttus__Result__c, Apttus__Status__c FROM Apttus__AsyncMergeCall__c WHERE ID = :asyncMergeObj.Id];
        asyncMergeObj.Apttus__Result__c = attachmentObj.Id;
        asyncMergeObj.Apttus__Status__c = APT_Constants.STATUS_CATEGORY;
        try
        {
            update asyncMergeObj;
        }
        catch(Exception ex)
        {
            System.Debug(ex);
        }
        Test.stopTest();
    }

    /*
        Test Method to Test Functionality
    */
    public static testMethod void test_Catch()
    {
        Apttus__APTS_Agreement__c agrObj = new Apttus__APTS_Agreement__c();
        agrObj.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        insert agrObj;
        Test.startTest();
        Apttus__AsyncMergeCall__c asyncMergeObj = new Apttus__AsyncMergeCall__c();
        //asyncMergeObj.Apttus__Agreement__c = agrObj.Id;
        asyncMergeObj.Apttus__Status__c = APT_Constants.STATUS_FAILED;
        asyncMergeObj.Apttus__Result__c = 'Temp result';
        insert asyncMergeObj;
        
        asyncMergeObj.Apttus__Status__c = APT_Constants.STATUS_CATEGORY;
        update asyncMergeObj;
        Test.stopTest();
    }

}