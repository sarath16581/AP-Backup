/*------------------------------------------------------------------------
Author:        Adrian Recio
Company:       Accenture
Description:   Created Test class for AgreementToSFContractTriggerHandler class
               Tests executed:
               1 - setup()
               Standard setup data to create test agreement with related files
               2- triggerOnAfterUpdateAndBeforeDelete()
               Main testmethod to cover scenarios of trigger after update and before delete events
History
<Date>      <Authors Name>     <Brief Description of Change>
11-Sep-2018 Adrian Recio       Created Test class for AgreementToSFContractTriggerHandler class
02-04-2019  Ramtej Juloori     Added code to invoke method in APT_ContractFileShareScheduler to share
                               files to sf contract from apttus contract
----------------------------------------------------------------------------*/

@isTest 
public class AgreementToSFContractTriggerHandlerTest {
    // Test variable declaration
    public static final string MSA_RECORTYPE = 'MSA & Service Schedule';
    public static final string INAUTHOR_STATUS_CATEGORY = 'In Authoring';
    public static final string AUTHORCONTRACT_STATUS = 'Author Contract';
    
    public static final string TEST_PRODUCT_NAME = 'Test Product';
    public static final string TEST_PRODUCT_TYPE = 'StarTrack';
    public static final string DOCUSIGN_STATUS_COMPLETED = 'Completed';
    public static final string TEST_ATTACHMENT_BODY = 'Test Attachment Body';

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Setup data to create test Apttus contract with related files
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    22-Oct-2018  Adrian Recio      Created setup data initial version
    ------------------------------------------------------------*/
    @testSetup static void setup() {
        // Create test organisation
        Account accVar = APT_TestUtil2.createOrganisation();
        insert accVar;

        // Create test contact
        Contact conVar = APT_TestUtil2.createContact();
        conVar.AccountId = accVar.Id;
        insert conVar;

        // Create test opportunity
        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);
        oppVar.StageName ='Identify';
        insert oppVar;
        
        // Create test pricelist
        Apttus_Config2__Pricelist__c plVar = APT_TestUtil2.createPriceList();
        insert plVar;
        
        // Create quote proposal
        Apttus_Proposal__Proposal__c prVar = APT_TestUtil2.createQuoteProposalNoAgrmnt(accVar, oppVar, 'Proposal', plVar);
        insert prVar;

        // Create test product
        Product2 testProduct = new Product2();
        testProduct.Name = TEST_PRODUCT_NAME;
        testProduct.APT_Product_type__c = TEST_PRODUCT_TYPE;
        insert testProduct;
        
        // Create test proposal line item
        Apttus_Proposal__Proposal_Line_Item__c propLineItem = new Apttus_Proposal__Proposal_Line_Item__c();
        propLineItem.Apttus_Proposal__Proposal__c = prVar.Id;
        propLineItem.Apttus_Proposal__Product__c = testProduct.Id;
        propLineItem.Apttus_QPConfig__ItemSequence__c = 1;
        propLineItem.Apttus_QPConfig__LineNumber__c = 1;
        insert propLineItem;
        
        // Create test DocuSign Envelope
        Apttus_DocuApi__DocuSignEnvelope__c dsEnv = new Apttus_DocuApi__DocuSignEnvelope__c();
        dsEnv.Apttus_DocuApi__Status__c = DOCUSIGN_STATUS_COMPLETED;
        insert dsEnv;
        test.startTest();
        // Create test agreement
        Apttus__APTS_Agreement__c aptContract = APT_TestUtil2.createAgreement(accVar,
                                                                              conVar,
                                                                              oppVar,
                                                                              prVar,
                                                                              AUTHORCONTRACT_STATUS,
                                                                              INAUTHOR_STATUS_CATEGORY,
                                                                              MSA_RECORTYPE);

        aptContract.APT_Product__c = 'eParcel';
        // ---
        aptContract.Apttus_CMDSign__DocuSignEnvelopeId__c = dsEnv.Id;       
        aptContract.Is_Document_Signed__c = false;
        insert aptContract;
        
        // Create test attachments
        List<Attachment> testAttachments = new List<Attachment>();
        Attachment atc = new Attachment();
        atc = APT_TestUtil2.createAttachment(aptContract.Id);
        atc.Name += '__signed.pdf';         // append to file name
        atc.Body = EncodingUtil.base64Decode(TEST_ATTACHMENT_BODY);
        testAttachments.add(atc);
        
        Attachment atc2 = new Attachment();
        atc2 = APT_TestUtil2.createAttachment(aptContract.Id);
        atc2.Name += '__signed.pdf';            // append to file name
        atc2.Body = EncodingUtil.base64Decode(TEST_ATTACHMENT_BODY);
        testAttachments.add(atc2);
        insert testAttachments;
        
        // Create test content document
        ContentVersion contentVersion = APT_TestUtil2.createContentVersion();
        insert contentVersion;

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        // Create ContentDocumentLink  record
        ContentDocumentLink cdl =  APT_TestUtil2.createContentDocumentLink (aptContract.id, documents[0].Id);
        insert cdl;
        test.stopTest();
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Test method will test trigger handler after update and before delete events.
                    For after update scenario, expected outcome is a clone contract is generated if an apttus contract is updated to In-effect and Activated status
                    For before delete scenario, expected outcome is the clone contract is deleted if the parent Apttus contract is deleted.
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio       Initial version.
    ------------------------------------------------------------*/
    static testMethod void triggerOnAfterUpdateAndBeforeDelete() {
        // Query test agreement and assign value of In Effect - Activated
        Apttus__APTS_Agreement__c agreement = [Select id , Apttus__Status_Category__c , Apttus__Status__c from Apttus__APTS_Agreement__c];
        agreement.Apttus__Status_Category__c = 'In Effect';
        agreement.Apttus__Status__c = 'Activated';

        test.startTest();
        // Check that clone SF Contract doesn't exist before status update
        System.assertEquals(0 , [Select id , Status from contract].size(), 'Clone SF Contract should not exist.'); //Intitially No Contract
        // Execute contract update
        update agreement;
        // Check that clone SF Contract exist after update
        List<contract> sfCloneList = [Select id ,APT_Product__c, Status_Category__c, Parent_Agreement__c from contract where Parent_Agreement__c = :agreement.id];
                
        System.assertEquals(1 ,sfCloneList.size(),'Clone Sf Contract should exist' );
        System.assertEquals('eParcel' ,sfCloneList[0].APT_Product__c ,'Product should be eparcel for Clone Sf Contract');
        System.assertEquals('In Effect' ,sfCloneList[0].Status_Category__c , 'SF Contract status should be In Effect');

        // Test trigger delete event
        delete agreement;
        sfCloneList = [Select id ,APT_Product__c, Status_Category__c from contract where Parent_Agreement__c = :agreement.id];

        // Check that clone sf contract is also deleted
        System.assertEquals(0, sfCloneList.size() , 'Clone SF Contract should be deleted.');

        test.stopTest();
    }
    
    /*------------------------------------------------------------
        Method to test file sharing to sf contract when apttus contract
        is activated
    ------------------------------------------------------------*/
    static testMethod void triggerOnActivatingContract() {
        // Query test agreement and assign value of In Effect - Activated
        Apttus__APTS_Agreement__c agreement = [Select id , Apttus__Status_Category__c , Apttus__Status__c from Apttus__APTS_Agreement__c];
        
        agreement.Apttus__Status_Category__c = 'In Effect';
        agreement.Apttus__Status__c = 'Activated';
        
        test.startTest();
        // Check that clone SF Contract doesn't exist before status update
        System.assertEquals(0 , [Select id , Status from contract].size(), 'Clone SF Contract should not exist.'); //Intitially No Contract
        
        // Execute contract update       
        update agreement;
        
        // Check that clone SF Contract exist after update
        List<contract> sfCloneList = [Select id ,APT_Product__c, Status_Category__c, Parent_Agreement__c from contract where Parent_Agreement__c = :agreement.id];

        System.assertEquals(1 ,sfCloneList.size(),'Clone Sf Contract should exist' );
        
        test.stopTest();
    }
    
}