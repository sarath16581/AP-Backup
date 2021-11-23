/*------------------------------------------------------------
Author:   :      Jeoffrey Palmero/Prince Encina
Date Created:    5/28/2019
Description:     Test class for FilesReatedListExtensionClone

History
<Date>           <Authors Name>     <Brief Description of Change>
05/28/2019        JPalmero/PEncina  Created
------------------------------------------------------------*/
@IsTest
public with sharing class FilesRelatedListPageCloneTest {
    
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
        testProduct.APT_Product_type__c = 'StarTrack';
        insert testProduct;
        Apttus_Proposal__Proposal_Line_Item__c propLineItem = new Apttus_Proposal__Proposal_Line_Item__c();
        propLineItem.Apttus_Proposal__Proposal__c = proposal.Id;
        propLineItem.Apttus_Proposal__Product__c = testProduct.Id;
        propLineItem.Apttus_QPConfig__ItemSequence__c = 1;
        propLineItem.Apttus_QPConfig__LineNumber__c = 1;
        insert propLineItem;
        //System.assertEquals(NULL, proposal);
        //Create test agreement
        //Apttus__APTS_Agreement__c aptContract = APT_TestUtil2.createAgreement(accVar, conVar, opptyVar, proposal, 'Request', 'Request', 'MSA & Service Schedule');
        test.startTest();
        Apttus__APTS_Agreement__c aptContract = new Apttus__APTS_Agreement__c();
        aptContract.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract.Name = APT_Constants.STRING_AGREEMENT;
        aptContract.Apttus__Agreement_Category__c = APT_Constants.NETWORK_TYPE_STANDARD;
        aptContract.Apttus__Primary_Contact__c = conVar.Id;
        aptContract.Apttus__Account__c = accVar.Id;
        aptContract.Apttus__Related_Opportunity__c = opptyVar.Id;
        aptContract.Apttus_QPComply__RelatedProposalId__c = (proposal == null) ? null : proposal.Id;
        insert aptContract;
        
        // Create test Contract linked to Apttus Agreement
        Contract contVar = new Contract();
        contVar.Name = 'Test Contract';
        contVar.AccountId = accVar.Id;
        contVar.Parent_Agreement__c = aptContract.Id;
        insert contVar;
        
        
        List<ContentVersion> cvList = new List<ContentVersion>();
        ContentVersion cv1 = APT_TestUtil2.createContentVersion();
        cv1.Is_Signed__c = TRUE;
        cv1.Signature_Type__c = 'Digital';
        cvList.add(cv1);
        ContentVersion cv2 = APT_TestUtil2.createContentVersion();
        cvList.add(cv2);
        cv2.Document_Type__c = 'Contract';
        insert cvList; 
        
        // Query populated content document from inserted content version
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        // Create ContentDocumentLink record
        ContentDocumentLink cdl =  APT_TestUtil2.createContentDocumentLink (aptContract.id, documents[0].Id);
        cdl.Visibility = 'InternalUsers';
        insert cdl;
           
        test.stopTest();
    }
    /**********************
     * Description: tests getFiles with no criteria
     * Author: JPalmero/PEncina
     * History:
     * 06/04/2019       Created
     **********************/
    private static testMethod void testGetFilesAll(){
        List<ContentVersion> cvListTest = new List<ContentVersion>();
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Contract sfContract = [SELECT Id FROM Contract WHERE Parent_Agreement__c = :aptContract.Id LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(sfContract);
        FilesRelatedListExtensionClone myPage = new FilesRelatedListExtensionClone(sc);
        myPage.selectedType = 'All';
        myPage.docuType = 'All';
        
        test.startTest();
        cvListTest = FilesRelatedListExtensionClone.getFiles(sfContract, 'All', 'All');
        test.stopTest();
        System.assertEquals(1, cvListTest.size());
    }
    /**********************
     * Description: tests getFiles with Document type filtered
     * Author: JPalmero/PEncina
     * History:
     * 06/04/2019       Created
     **********************/
    private static testMethod void testGetFilesDocuType(){
        List<ContentVersion> cvListTest = new List<ContentVersion>();
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Contract sfContract = [SELECT Id FROM Contract WHERE Parent_Agreement__c = :aptContract.Id LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(sfContract);
        FilesRelatedListExtensionClone myPage = new FilesRelatedListExtensionClone(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'All';
        myPage.docuType = 'Contract';
        
        test.startTest();
        cvListTest = FilesRelatedListExtensionClone.getFiles(sfContract, 'All', 'Contract');
        test.stopTest();
        System.assertEquals(1, cvListTest.size());
    }
    
    /**********************
     * Description: tests getFiles with Document Type and Signature Type filtered
     * Author: JPalmero/PEncina
     * History:
     * 06/04/2019       Created
     **********************/
    private static testMethod void testGetFilesDocuSignType(){
        List<ContentVersion> cvListTest = new List<ContentVersion>();
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Contract sfContract = [SELECT Id FROM Contract WHERE Parent_Agreement__c = :aptContract.Id LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(sfContract);
        FilesRelatedListExtensionClone myPage = new FilesRelatedListExtensionClone(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'Digital';
        myPage.docuType = 'Contract';
        
        test.startTest();
        cvListTest = FilesRelatedListExtensionClone.getFiles(sfContract, 'Digital', 'Contract');
        test.stopTest();
        System.assertEquals(1, cvListTest.size());
    }
    
    /**********************
     * Description: tests getFiles with signature type filtered
     * Author: JPalmero/PEncina
     * History:
     * 06/04/2019       Created
     **********************/
    private static testMethod void testGetFilesSignType(){
        List<ContentVersion> cvListTest = new List<ContentVersion>();
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Contract sfContract = [SELECT Id FROM Contract WHERE Parent_Agreement__c = :aptContract.Id LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(sfContract);
        FilesRelatedListExtensionClone myPage = new FilesRelatedListExtensionClone(sc);
        ContentVersion testCV = new ContentVersion();
        myPage.selectedType = 'Digital';
        myPage.docuType = 'All';
        
        test.startTest();
        cvListTest = FilesRelatedListExtensionClone.getFiles(sfContract, 'Digital', 'All');
        test.stopTest();
        System.assertEquals(1, cvListTest.size());
    }
    
    /**********************
     * Description: tests setDocType method
     * Author: JPalmero/PEncina
     * History:
     * 06/04/2019       Created
     **********************/
    private static testMethod void testsetDocType(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Contract sfContract = [SELECT Id FROM Contract WHERE Parent_Agreement__c = :aptContract.Id LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(sfContract);
        FilesRelatedListExtensionClone myPage = new FilesRelatedListExtensionClone(sc);
        myPage.selectedType = 'Digital';
        myPage.docuType = 'All';
        
        test.startTest();
        myPage.setDocType();
        test.stopTest();
    }
    
    /**********************
     * Description: tests setStatus method
     * Author: JPalmero/PEncina
     * History:
     * 06/04/2019       Created
     **********************/
    private static testMethod void testsetStatus(){
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Contract sfContract = [SELECT Id FROM Contract WHERE Parent_Agreement__c = :aptContract.Id LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.standardController(sfContract);
        FilesRelatedListExtensionClone myPage = new FilesRelatedListExtensionClone(sc);
        myPage.selectedType = 'Digital';
        myPage.docuType = 'All';
        
        test.startTest();
        myPage.setStatus();
        test.stopTest();
    }
}