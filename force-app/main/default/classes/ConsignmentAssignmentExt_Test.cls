/**************************************************
Description:    Test class to test ConsignmentAssignmentExt class

History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/

@IsTest
private class ConsignmentAssignmentExt_Test {

    @TestSetup static void testSetup(){

        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        INSERT testNetwork;


        ID consignmentRecID = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId();
        ID articleRecID = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Article').getRecordTypeId();
        Article__c consignment = TestDataProvider.createTestArticle();
        consignment.name = 'connote1';
        consignment.recordtypeid =  consignmentRecID;
        Insert consignment;

        List<Article__c> articles = TestDataProvider.createArticle('My Articel', 1, null);
        articles[0].name =  'connote1Art';
        articles[0].recordtypeid =  articleRecID;
        articles[0].TrackingID__c = '1234567890';
        articles[0].consignment__c = consignment.id;
        insert articles[0];

        List<EventMessage__c> messages = TestDataProvider.createEventMessages(1, articles[0], 'DD-ER15');

        insert messages[0];


        List<Event_Message_Attachment__c> emAtts = TestDataProvider.createEventMessageAttachments(1,messages[0].id);

        insert emAtts;


        Id creditClaim = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Credit Dispute Claim').getRecordTypeId();
        List<Case> newCases = new List<Case>();
        for(Integer i=0; i<5; i++){
            Case newCase = new Case(Subject = 'Test Case ' + i, Origin = 'Phone', RecordTypeId = creditClaim, Network__c = testNetwork.Id, ArticleTest__c = articles[0].Id);
            newCases.add(newCase);
        }
        INSERT newCases;

        list<Disputed_Item__c> dispItemLst  = TestDataProvider.createDisputedItem(1,newCases[0].id);
        for(Disputed_Item__c di : dispItemLst ){
            di.Connote__c = 'connote1';
        }
        insert dispItemLst;
    }

    static testMethod void testPgCaseConsignmentAttachment() {

        List<Case> newCases = [select id,caseNumber, articletest__c from Case where subject = 'Test Case 0' ];

        PageReference pageRef = Page.CaseConsignmentAttachment;
        pageRef.getParameters().put('id', newCases[0].id);


        ApexPages.StandardController sc = new ApexPages.StandardController(newCases[0]);
        ConsignmentAssignmentExt cont = new ConsignmentAssignmentExt(sc);

        Test.setCurrentPage(pageRef);

        system.assert(newCases[0].id == cont.caseID, 'Case not populated in controller'  );

    }

    static testMethod void testPgConsignmentAttachmentCaseMode() {

        List<Case> newCases = [select id,caseNumber, articletest__c from Case where subject = 'Test Case 0' ];

        PageReference pageRef = Page.ConsignmentAttachment;
        pageRef.getParameters().put('id', newCases[0].id);


        ApexPages.StandardController sc = new ApexPages.StandardController(newCases[0]);
        ConsignmentAssignmentExt cont = new ConsignmentAssignmentExt(sc);

        Test.setCurrentPage(pageRef);

        system.assert(newCases[0].id == cont.caseID, 'Case not populated in controller'  );

    }

    static testMethod void testPgConsignmentAttachmentNonCaseMode() {

        case caseObj = new case();

        PageReference pageRef = Page.ConsignmentAttachment;
        pageRef.getParameters().put('connote', 'connote1');

        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sc = new ApexPages.StandardController(caseObj);
        ConsignmentAssignmentExt cont = new ConsignmentAssignmentExt(sc);

        system.assert(cont.conNote == 'connote1', 'Connote not populated'  );
    }
}