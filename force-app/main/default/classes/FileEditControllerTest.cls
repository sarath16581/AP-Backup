/*------------------------------------------------------------------------
Author:         Chester Borbon
Description:     Test Class for the FileEditController VisualForce Page

               Test Executed: 
               1 - setup()
               Standard setup data to create test agreement with related files
               2-  testFileEditController()
               Main testmethod to cover File Edit on VF Page

History
<Date>         <Authors Name>     <Brief Description of Change>
25-Sept-2018   Chester Borbon     Created Test class for FileEditController VisualForce Page
22-Oct-2018    Melissa Carino     Added Code Comments for FileEditControllerTest
02-June-2020   Shashwat Nath      Updated the method testFileEditController to include Is_Document_Signed__c set to true
----------------------------------------------------------------------------*/
@IsTest
public with sharing class FileEditControllerTest {
    // Test variable declaration
    public static final string MSA_RECORTYPE = 'MSA & Service Schedule';
    public static final string INSIGNATURE_STATUS_CATEGORY = 'In Signature';
    public static final string RECONCILED_STATUS = 'Reconciled';

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

        // Create test agreement
        Apttus__APTS_Agreement__c aptContract = APT_TestUtil2.createAgreement(accVar,
                                                                                conVar,
                                                                                oppVar,
                                                                                new Apttus_Proposal__Proposal__c(),
                                                                                RECONCILED_STATUS,
                                                                                INSIGNATURE_STATUS_CATEGORY,
                                                                                MSA_RECORTYPE);
        aptContract.APT_Product__c = 'eParcel';
        insert aptContract;

        // Create test content version
        List<ContentVersion> cvList = new List<ContentVersion>();
        ContentVersion cv1 = APT_TestUtil2.createContentVersion();
        cvList.add(cv1);
        ContentVersion cv2 = APT_TestUtil2.createContentVersion();
        cvList.add(cv2);
        insert cvList;


    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Scenario: FileEditController will pull the related files based on Apttus Contract Id in the page parameter.
                            Maching files will have its values updated.
                    Outcome: On call of save method, document type updates should be commited to database.
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio       Initial version.
    ------------------------------------------------------------*/
    //Test method to cover FileEditController to support FileEditPage to edit the Document Type of uploaded Files
    private static testMethod void testFileEditController() {
        // Query content document
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        // Query parent agreement
        Apttus__APTS_Agreement__c aptContract = [Select ID , Is_Document_Signed__c, Name, Apttus__Status_Category__c , Apttus__Status__c from Apttus__APTS_Agreement__c];

        // Create ContentDocumentLink  record
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        ContentDocumentLink cdl1 =  APT_TestUtil2.createContentDocumentLink (aptContract.id, documents[0].Id);
        cdlList.add(cdl1);
        ContentDocumentLink cdl2 =  APT_TestUtil2.createContentDocumentLink (aptContract.id, documents[1].Id);
        cdlList.add(cdl2);
        insert cdlList;

        // Update the status to create an SF Contract clone
        aptContract.Apttus__Status_Category__c = 'In Effect';
        aptContract.Apttus__Status__c = 'Activated';
        aptContract.Is_Document_Signed__c = true;
        
        update aptContract;

        Test.startTest();

        // Set current page parameter for Id equal to test agreement Id
        Test.setCurrentPage(Page.FilesEditPage);
        ApexPages.currentPage().getParameters().put('id',aptContract.Id);
        FileEditController testFileEditController = new FileEditController();

        // Validate that the child content version is retrieved based on current page url parameter after controller instantation
        system.assertEquals(2, testFileEditController.mainCvList.size(), '2 child files should be retrieved on class instantation/constructor');

        // Assign new document types for content version list
        testFileEditController.mainCvList[0].Document_Type__c = 'Renewal';
        testFileEditController.mainCvList[1].Document_Type__c = 'Deed of Variation';

        // Save
        testFileEditController.saveRecords();
        Test.stopTest();
    } 
}