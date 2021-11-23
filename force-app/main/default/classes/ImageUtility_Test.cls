/**************************************************
Description:    Test class to test ImageUtility class

History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/
@IsTest
private class ImageUtility_Test {

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

    @isTest static void TestDisputedconNotes() {

        List<Case> newCases = [select id from Case where subject = 'Test Case 0' ];
        list<Disputed_Item__c> ddlst = ImageUtility.getDisputedconNotesFromCaseId(newCases[0].id);

        system.assert(ddlst.size() > 0, 'No disputed item found for Case');
    }

    @isTest static void testCreateFilesAndGetDoc(){
        ImageUtility.ImageAttachment imgObj = new ImageUtility.ImageAttachment();
        string sBase64 = EncodingUtil.Base64Encode( Blob.valueOf( 'this is test' ) );
        List<Case> newCases = [select id from Case where subject = 'Test Case 0' ];
        imgObj.name = 'test attachment';
        imgObj.caseID = newCases[0].id;
        imgObj.base64Str = sBase64;
        imgObj.guid =  'ImageGuid0.jpg';

        string strObj = JSON.serialize(imgObj);
        test.startTest();
        string rtn = ImageUtility.createCaseAttachments(strObj);
        test.stopTest();

        system.assert(rtn != 'Image empty Noting To Save', 'Image not created' );

        list<ContentVersion> fileObj =  ImageUtility.getDocumentIdForSelFiles(newCases[0].id);
        system.assert(fileObj.size() > 0, 'Cannot get File');

        list<ImageUtility.displayData>  rtn2 = ImageUtility.getDataforDispForSelAttachofCase(newCases[0].id);
        

        string sFile = ImageUtility.getSelFiles(fileObj[0].id);
        system.assert(!string.isBlank(sFile)  , 'Could not retrieve file');

    }


    @isTest static void testGetDataforDisplayFromEvents(){
        List<Case> newCases = [select id from Case where subject = 'Test Case 0' ];
        list<string> ignoreSelectedEventMsgsAttach = new list<string>();
        list<string> conNoteLst = new list<string>();
        conNoteLst.add('connote1');
        list<ImageUtility.displayData>  rtn = ImageUtility.getDataforDisplayFromEvents(newCases[0].id,conNoteLst , ignoreSelectedEventMsgsAttach );
        system.assert(rtn.size() > 0, 'Noting to display fomr Events');
    }
}