/**************************************************
Description: Test class for APTS_CombineProposalDocsController
History:
18/06/2019 Ramtej Created 
**************************************************
@Modified By Aditya Shetty
@Modified On 11/03/2019
@Description To accomodated the functionality of merging all proposal docs which are stored as Salesforce Files (ConentDocument) instead of Attachments

**************************************************/

@isTest
public class APTS_CombineProposalDocsControllerTest {
@testsetup
    public static void loadTestData(){
        Contact con= APT_TestUtils.createContact();
        insert con;
        
        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000';
        insert tempacct;
        
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        insert opp;
        
        Product2 product =APT_TestUtils.createInternationalProduct('Car',APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES,'Postal Services');
        product.APT_Product_type__c = 'Workforce Verification';
        insert product;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
        insert priceListItem;
               
        Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);        
        insert quote;
        
        
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<ContentVersion> contentVersionMergedList = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLink = new List<ContentDocumentLink>();
        string documentstoMerge = '';
       
        /*Start Aditya Shetty:  Inserted Content Version records to check merged Documents */
        ContentVersion mergedDoc = new ContentVersion();
        mergedDoc.Title = 'testDocumenttoMerge';
        mergedDoc.PathOnClient = 'testDocumenttoMerge.pdf';
        mergedDoc.VersionData = Blob.valueOf('Test Content');
        mergedDoc.IsMajorVersion = true;
        insert mergedDoc;
        //contentVersionMergedList.add(mergedDoc);
      
        ContentVersion mergedDoc1 = new ContentVersion();
        mergedDoc1.Title = 'testDocumenttoMerge1';
        mergedDoc1.PathOnClient = 'testDocumenttoMerge1.pdf';
        mergedDoc1.VersionData = Blob.valueOf('Test Content');
        mergedDoc1.IsMajorVersion = true;
        contentVersionMergedList.add(mergedDoc1);
        
        ContentVersion mergedDoc2 = new ContentVersion();       
        mergedDoc2.Title = 'testDocumenttoMerge2';
        mergedDoc2.PathOnClient = 'testDocumenttoMerge2.pdf';
        mergedDoc2.VersionData = Blob.valueOf('Test Content');
        mergedDoc2.IsMajorVersion = true;
        contentVersionMergedList.add(mergedDoc2);
        insert contentVersionMergedList;
         /*END Aditya Shetty:  Inserted Content Version records to check merged Documents */
       
        
        List<Id> mergedDocumentsId = new List<Id>();
        List<ContentDocument> mergedDocuments = [SELECT Id, Title, LatestPublishedVersionId,FileExtension  FROM ContentDocument];
        for(ContentDocument document : mergedDocuments){ 
            documentstoMerge = documentstoMerge +  document.Id + ';';
            mergedDocumentsId.Add(document.Id);
        }
        
          
        /*Start Aditya Shetty:  Create ContentVersion: This will automatically create records in ContentDocument */
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'testDocument';
        contentVersion.PathOnClient = 'testDocument.pdf';
        contentVersion.VersionData = Blob.valueOf('Test Content');
        contentVersion.IsMajorVersion = true;
        contentVersionList.add(contentVersion);
        
        ContentVersion contentVersion1 = new ContentVersion();
        contentVersion1.Title = 'testDocument1';
        contentVersion1.PathOnClient = 'testDocument1.pdf';
        contentVersion1.VersionData = Blob.valueOf('Test Content');
        contentVersion1.IsMajorVersion = true;
        contentVersionList.add(contentVersion1);
        
        ContentVersion contentVersion2 = new ContentVersion();       
        contentVersion2.Title = 'testDocument2';
        contentVersion2.PathOnClient = 'testDocument2.pdf';
        contentVersion2.VersionData = Blob.valueOf('Test Content');
        contentVersion2.IsMajorVersion = true;
        contentVersionList.add(contentVersion2);
        
        insert contentVersionList;
        /*End Aditya Shetty:  Create ContentVersion: This will automatically create records in ContentDocument */
     
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,FileExtension  FROM ContentDocument 
                                          Where Id NOT IN :mergedDocumentsId];
        System.Debug('Debug Log :: Documents' + documents);
        
        /*Start Aditya Shetty: Create ContentDocumentLink corresponding to the ContentDocument Created linked with the inserted quote*/
        for(ContentDocument document : documents){              
            ContentDocumentLink contentDocLink = new ContentDocumentLink();
            contentDocLink.LinkedEntityId = quote.Id;
            contentDocLink.ContentDocumentId = document.Id;
            contentDocumentLink.Add(contentDocLink);
        }
       
         insert contentDocumentLink;
        /*End Aditya Shetty: Create ContentDocumentLink corresponding to the ContentDocument Created linked with the inserted quote*/
    }
    
    public testmethod static void testCombineQuoteDocs(){
      
    //create custom setting to access URL to call the apttus service to merge files
        Apttus__ComplySystemProperties__c systemProperties = new Apttus__ComplySystemProperties__c();
        systemProperties.Name = 'System Properties';
        systemProperties.Apttus__InstanceUrl__c = System.URL.getSalesforceBaseUrl().toExternalForm();
        insert systemProperties;
        
    //select an attachment to move it up and down
        Apttus_Proposal__Proposal__c proposal = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        Id attachId = [SELECT Id FROM ContentDocument WHERE Title = 'testDocument1'].Id;
        Id mergedDocument = [SELECT ID from ContentDocument Where Title = 'testDocumenttoMerge'].Id;
    //set current page context
        proposal.Document_Generated_by_Merge__c = attachId;
        update proposal;
        
        PageReference pref = Page.APTS_CombineProposalDocs;
        pref.getParameters().put('Id', proposal.id);
        Test.setCurrentPage(pref);
      
    //invoke controller with standard controller
        ApexPages.StandardController ctrl = new ApexPages.StandardController(proposal); 
        APTS_CombineProposalDocsController ext = new APTS_CombineProposalDocsController(ctrl);
        
        
        
        System.debug(ext.attachmentWrappers + 'Document List');
        ext.attachID = ext.attachmentWrappers[1].contentDoc.Id;
        ext.upAction();
        ext.attachID = ext.attachmentWrappers[0].contentDoc.Id;
        ext.upAction();
        
        ext.attachID = ext.attachmentWrappers[1].contentDoc.Id;
        ext.downAction();
        ext.attachID = ext.attachmentWrappers[0].contentDoc.Id;
        ext.downAction();
        
        ext.attachmentWrappers[0].selected = true;
        
        ext.Cancel();
        ext.MergeInitialization();
        ext.MergeDocument();
        ext.DocumentGeneratedbyMerge = mergedDocument;
        ext.MergeDocument();
        
}
}