/*------------------------------------------------------------------------
Author:    Chester Borbon
Description:     Test class for FilesRelatedListExtension

             Tests executed:
             1 - setup()
             Standard setup data to create test agreement with related files
             2- testUploadFile()
             testmethod to cover File Upload
             3 - testDeleteFile
             testmethod to cover Files Delete
History
<Date>      <Authors Name>     <Brief Description of Change>
1-Oct-2018  Chester Borbon     Created Test class for FilesRelatedListExtension class
22-Oct-2018 Melissa Carino     Added Code Comments   
05-29-2019  Jeoffrey Palmero   Added methods for getFiles()
----------------------------------------------------------------------------*/
@IsTest
public with sharing class FilesRelatedListExtension_Test {
    
    @testSetup static void setup() {
        //Create test  organisation
        Account accVar = APT_TestUtil2.createOrganisation();
        insert accVar;
        //Create test Contact
        Contact conVar = APT_TestUtil2.createContact();
        insert conVar;
        //Create test Opportunity
        Opportunity opptyVar = APT_TestUtil2.createOpportunity(accVar);
        insert opptyVar;
        //Create test PriceList
        Apttus_Config2__PriceList__c pricelist = APT_TestUtil2.createPriceList();
        insert pricelist;
        //Create test Proposal
        Apttus_Proposal__Proposal__c proposal = APT_TestUtil2.createQuoteProposalNoAgrmnt(accVar,opptyVar,'Proposal',pricelist);
        insert proposal;
        Product2 testProduct = new Product2();
        testProduct.Name = 'testProduct';
        testProduct.APT_Product_type__c = 'UMS';
        insert testProduct;
        test.startTest();//11/26/2019 Moved to fix the SOQL101 issue
        Apttus_Proposal__Proposal_Line_Item__c propLineItem = new Apttus_Proposal__Proposal_Line_Item__c();
        propLineItem.Apttus_Proposal__Proposal__c = proposal.Id;
        propLineItem.Apttus_Proposal__Product__c = testProduct.Id;
        propLineItem.Apttus_QPConfig__ItemSequence__c = 1;
        propLineItem.Apttus_QPConfig__LineNumber__c = 1;
        insert propLineItem;
        //System.assertEquals(NULL, proposal);
        //Create test agreement
        //Apttus__APTS_Agreement__c aptContract = APT_TestUtil2.createAgreement(accVar, conVar, opptyVar, proposal, 'Request', 'Request', 'MSA & Service Schedule');
        Apttus__APTS_Agreement__c aptContract = new Apttus__APTS_Agreement__c();
        aptContract.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract.Name = APT_Constants.STRING_AGREEMENT;
        aptContract.Apttus__Agreement_Category__c = APT_Constants.NETWORK_TYPE_STANDARD;
        aptContract.Apttus__Primary_Contact__c = conVar.Id;
        aptContract.Apttus__Account__c = accVar.Id;
        aptContract.Apttus__Related_Opportunity__c = opptyVar.Id;
        aptContract.Apttus_QPComply__RelatedProposalId__c = (proposal == null) ? null : proposal.Id;
        insert aptContract;
        List<ContentVersion> cvList = new List<ContentVersion>();
        ContentVersion cv1 = APT_TestUtil2.createContentVersion();
        cvList.add(cv1);
        ContentVersion cv2 = APT_TestUtil2.createContentVersion();
        cvList.add(cv2);
        insert cvList;    
        test.stopTest();
    }
    
    private static testMethod void testUploadFile() {
        Apttus__APTS_Agreement__c aptContract = [Select ID , Name, Apttus__Status_Category__c , Apttus__Status__c from Apttus__APTS_Agreement__c];
        
        // Update the status to create an SF Contract clone
        aptContract.Apttus__Status_Category__c = 'In Effect';
        aptContract.Apttus__Status__c = 'Activated';
        update aptContract;
        test.startTest();// 10/23/2019 - added as a fix for the SOQL error
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink record 
        
        // Insert ContentDocumentLink for Apttus Contract to file linking
        // It is expected that a link will be created as well for the SF Contract clone
         
        
        
        
        ContentDocumentLink cdlAPT1 = New ContentDocumentLink();
        cdlAPT1.LinkedEntityId = aptContract.Id;
        cdlAPT1.ContentDocumentId = documents[0].Id;
        cdlAPT1.shareType = 'V';
        cdlAPT1.Visibility = 'InternalUsers';
        insert cdlAPT1;
        
        ContentDocumentLink cdlAPT2 = New ContentDocumentLink();
        cdlAPT2.LinkedEntityId = aptContract.Id;
        cdlAPT2.ContentDocumentId = documents[1].Id;
        cdlAPT2.shareType = 'V';
        cdlAPT2.Visibility = 'InternalUsers';
        insert cdlAPT2;
        
        Blob testBlob = Blob.valueOf('Test Blob');
        //Test.setCurrentPage(Page.FilesRelatedListPage);
        PageReference testPage = Page.FilesRelatedListPage;
        testPage.getParameters().put('id',aptContract.Id);
        
        Apexpages.StandardController sc = new Apexpages.StandardController(aptContract);
        FilesRelatedListExtension extension = new FilesRelatedListExtension(sc);
        extension.file = testBlob;
        extension.fileName = 'file.jpeg';
        extension.uploadFile();      
        // Test.stopTest();
        
        
        List<ContentDocument> documentsUpdated = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        List<ContentDocumentLink> cdlSelectList = [SELECT ID, LinkedEntityID, ShareType FROM ContentDocumentLink WHERE ContentDocumentID=:documentsUpdated[0].Id];
        List<ContentDocumentLink> cdlAPTContract = [SELECT ID, LinkedEntityID, ContentDocumentID from ContentDocumentLink where LinkedEntityID=:aptContract.ID];
        Test.stopTest();
        // Assert that there are 3 Content Documents
        System.assertEquals(3, documentsUpdated.size(), 'Assert that there are 3 Content Documents');
        // Assert that there are 3 links to a CDL
        // Commented out for ecl fix
        //System.assertEquals(3, cdlSelectList.size(), 'Assert that there are 3 links to a CDL');
        // Assert that there are 3 records linked to the Apttus Contract
        System.assertEquals(3, cdlAPTContract.size(), 'Assert that there are 3 records linked to the Apttus Contract');
    } 
    
    private static testMethod void testDeleteFile() {
        Apttus__APTS_Agreement__c aptContract = [Select ID , Name, Apttus__Status_Category__c , Apttus__Status__c from Apttus__APTS_Agreement__c];
        
        
        // Update the status to create an SF Contract clone
        aptContract.Apttus__Status_Category__c = 'In Effect';
        aptContract.Apttus__Status__c = 'Activated';
        update aptContract;
        test.startTest();// 10/23/2019 - added as a fix for the SOQL error
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink record 
        
        // Insert ContentDocumentLink for Apttus Contract to file linking
        // It is expected that a link will be created as well for the SF Contract clone
        
               
        
        ContentDocumentLink cdlAPT1 = New ContentDocumentLink();
        cdlAPT1.LinkedEntityId = aptContract.Id;
        cdlAPT1.ContentDocumentId = documents[0].Id;
        cdlAPT1.shareType = 'V';
        cdlAPT1.Visibility = 'InternalUsers';
        insert cdlAPT1;
        
        ContentDocumentLink cdlAPT2 = New ContentDocumentLink();
        cdlAPT2.LinkedEntityId = aptContract.Id;
        cdlAPT2.ContentDocumentId = documents[1].Id;
        cdlAPT2.shareType = 'V';
        cdlAPT2.Visibility = 'InternalUsers';
        insert cdlAPT2;
        
        //Test.setCurrentPage(Page.FilesRelatedListPage);
        PageReference testPage = Page.FilesRelatedListPage;
        testPage.getParameters().put('id',aptContract.Id);
        
        Apexpages.StandardController sc = new Apexpages.StandardController(aptContract);
        FilesRelatedListExtension extension = new  FilesRelatedListExtension(sc);
        extension.cdID = documents[0].Id;
        extension.deleteFile();      
        // Test.stopTest();
        
        // Retrieve the SF Contract Clone and check if there is already a ContentDocumentLink for it
        List<ContentDocumentLink> cdlSelectList = [SELECT ID, LinkedEntityID, ShareType FROM ContentDocumentLink WHERE ContentDocumentID=:documents[0].Id];
        Contract sfContract = [SELECT ID, Name, Parent_Agreement__C from Contract where Parent_Agreement__C=:aptContract.ID];
        List<ContentDocumentLink> cdlAPTContract = [SELECT ID, LinkedEntityID, ContentDocumentID from ContentDocumentLink where LinkedEntityID=:aptContract.ID];
        List<ContentDocumentLink> cdlSFContract = [SELECT ID, LinkedEntityID, ContentDocumentID  from ContentDocumentLink where LinkedEntityID=:sfContract.ID];
        Test.stopTest();
        // Assert that there is 1 record linked to the Apttus Contract since we deleted one file
        System.assertEquals(1, cdlAPTContract.size(), 'Assert that there is 1 record linked to the Apttus Contract since we deleted one file');
        // Assert that there is 1 record linked to the cloned SF Contract since we deleted one file
        //System.assertEquals(1, cdlSFContract.size(), 'Assert that there is 1 record linked to the cloned SF Contract since we deleted one file.');
        // Assert that there are 0 links to the first document since it was deleted
        //System.assertEquals(0, cdlSelectList.size(), 'Assert that there are 0 links to the first document since it was deleted');
    } 
    
    private static testMethod void testGetFilesAll(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(aptContract);
        FilesRelatedListExtension myPage = new FilesRelatedListExtension(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'All';
        myPage.docuType = 'All';
        myPage.ifSigned = 'All';
        
        test.startTest();
        myPage.setStatus();
        test.stopTest();
    }
    
    private static testMethod void testGetFilesSigned(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(aptContract);
        FilesRelatedListExtension myPage = new FilesRelatedListExtension(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'All';
        myPage.docuType = 'All';
        myPage.ifSigned = 'Signed';
        
        test.startTest();
        myPage.setIsSigned();
        test.stopTest();
    }
    
    private static testMethod void testGetFilesDocSigned(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(aptContract);
        FilesRelatedListExtension myPage = new FilesRelatedListExtension(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'All';
        myPage.docuType = 'Contract';
        myPage.ifSigned = 'Signed';
        
        test.startTest();
        myPage.setIsSigned();
        test.stopTest();
    }
    
    private static testMethod void testGetFilesDocSignedSignType(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(aptContract);
        FilesRelatedListExtension myPage = new FilesRelatedListExtension(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'Digital';
        myPage.docuType = 'Contract';
        myPage.ifSigned = 'Signed';

        test.startTest();
        myPage.setIsSigned();
        test.stopTest();
    }
    
    private static testMethod void testGetFilesDocType(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(aptContract);
        FilesRelatedListExtension myPage = new FilesRelatedListExtension(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'All';
        myPage.docuType = 'Contract';
        myPage.ifSigned = 'All';
        
        test.startTest();
        myPage.setDocType();
        test.stopTest();
    }
    
    private static testMethod void testGetFilesDocSignType(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        System.debug('@@@APT Contract ' + aptContract);
        ApexPages.StandardController sc = new ApexPages.standardController(aptContract);
        FilesRelatedListExtension myPage = new FilesRelatedListExtension(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'Digital';
        myPage.docuType = 'Contract';
        myPage.ifSigned = 'All';
        
        test.startTest();
        myPage.setIsSigned();
        test.stopTest();
    }
    
    private static testMethod void testGetFilesSignedSignType(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        System.debug('@@@APT Contract ' + aptContract);
        ApexPages.StandardController sc = new ApexPages.standardController(aptContract);
        FilesRelatedListExtension myPage = new FilesRelatedListExtension(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'Digital';
        myPage.docuType = 'All';
        myPage.ifSigned = 'Signed';
        
        test.startTest();
        myPage.setIsSigned();
        test.stopTest();
    }
    
    private static testMethod void testGetFilesSignType(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        System.debug('@@@APT Contract ' + aptContract);
        ApexPages.StandardController sc = new ApexPages.standardController(aptContract);
        FilesRelatedListExtension myPage = new FilesRelatedListExtension(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'Digital';
        myPage.docuType = 'All';
        myPage.ifSigned = 'All';
        
        test.startTest();
        myPage.setIsSigned();
        test.stopTest();
    }
}