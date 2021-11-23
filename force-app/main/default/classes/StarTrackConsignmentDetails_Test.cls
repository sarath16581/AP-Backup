/**
 ** Description: Test Class for StarTrackConsignmentDetails_ControllerX class
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: JAN.7.2016
 ** History:--------------------------------------------
 **         JAN.7.2016 David Catindoy - Created
 **         JAN.7.2016 Patrick James Franco - Added test method for attachPODSignatureToCase
 **/
@isTest
private class StarTrackConsignmentDetails_Test {

    @testSetup static void testSetup(){
        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        INSERT testNetwork;

        Article__c testCon = TestDataProvider.createTestArticle();
        testCon.Network__c = testNetwork.Id;
        testCon.Date_Sent__c = System.today();
        testCon.ExpectedDeliveryDate__c = System.today()+1;
        INSERT testCon;

        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.Origin = 'Email';
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Transit Warranty Claim').getRecordTypeId();
        testCase.Network__c = testNetwork.Id;
        testCase.ArticleTest__c = testCon.Id;
        INSERT testCase;

        Id creditClaim = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Credit Dispute Claim').getRecordTypeId();
        List<Case> newCases = new List<Case>();
        for(Integer i=0; i<5; i++){
            Case newCase = new Case(Subject = 'Test Case ' + i, Origin = 'Phone', RecordTypeId = creditClaim, Network__c = testNetwork.Id, ArticleTest__c = testCon.Id);
            newCases.add(newCase);
        }
        INSERT newCases;

        Book_In_Note__c bookIn = new Book_In_Note__c(Name = 'Sample Book-In', Date_Entered__c = System.now(), By__c = 'David Catindoy', Notes__c = 'Sample Note', Consignment__c = testCon.Id);
        INSERT bookIn;

        Sub_Docket__c subDocket = new Sub_Docket__c(Name = 'Sample Subdocket', Date_Registered__c = System.now(), Delivery_Depot__c = 'Manila', Supervisor__c = 'Wayne Helena', Payer__c = 'Patrick Franco', Payer_Account_Number__c = '9663649086', Consignment__c = testCon.Id);
        INSERT subDocket;

        Proof_of_Delivery__c deliveryProof = new Proof_of_Delivery__c(Name = '93KDH87FH', Signed_by__c = 'David Catindoy', POD_Received_Date__c = System.now(), Delivery_Address__c = 'Sample Delivery Address', QC_Status__c = 'Verified', Consignment__c = testCon.Id);
        INSERT deliveryProof;

        Attachment attach = new Attachment(Name = 'Test Attachment', Body = Blob.valueOf('Unit Test Attachment Body'), ParentId = deliveryProof.Id);
        INSERT attach;
    }

    @isTest static void testRelatedRecords() {
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.Name, RecordType.Name FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackConsignmentDetails);

        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackConsignmentDetails_ControllerX ctrl = new StarTrackConsignmentDetails_ControllerX(sc);
        Test.stopTest();

        //test related records
        System.assertEquals(5, ctrl.relatedCases.size());
        System.assertEquals(1, ctrl.relatedNotes.size());
        System.assertEquals(1, ctrl.relatedSubdockets.size());
        System.assertEquals(1, ctrl.relatedPODs.size());
    }

    @isTest static void testAttachPODSignatureToCase() {
        Case caseRec = [SELECT Id, ArticleTest__c FROM Case WHERE Subject = 'Test Case'];

        Proof_of_Delivery__c testPOD = new Proof_of_Delivery__c();
        testPOD.Name = 'Test POD';
        testPOD.Consignment__c = caseRec.ArticleTest__c;
        testPOD.Signed_by__c = 'Tester';
        testPOD.SignatureXString__c = 'iVBORw0KGgoAAAANSUhEUgAAAPoAAABkAQMAAACVTr9NAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAGUExURQAAAP///6XZn90AAAAJcEhZcwAADsMAAA7DAcdvqGQAAAEnSURBVEjH7dMxTgMxEAXQ3CRHyRE4Qs5B5WOk5AgpU1CYG+QAKHJBsVVioUhYizMeZgxCCO3+X0C57lZ66/F8j1eK19NqAQtYwAJ+r8zADoGi2u4JGBsCVn/QgMEDBElbIGBUeIZoxyQgYxDsjAQEFQCa/46BYCB6ZcCirABUSwqCYkFgYDcBQZa+zTxIlYFCQDwqnuoYCQjB68yD1m8agbHXmQfSGwgAZAKql/+cuGlQIgO+uwBw6XUAODPw7B0UAA4M7L2DDMDWQZoHLTrYAOAv8yunSXDT76c7DcRBBaD6LAwAFAcJgMF73ABwtJRuCsBe9fUFga1FsQagxZ9fE0AYqIGAN/0rODNwYuCRgQMDdwS0SIAEAt6VgJGBKwOZgcSA/jv4AFz3QW6D/iIMAAAAAElFTkSuQmCC';
        INSERT testPOD;

        Attachment attach = [SELECT Id FROM Attachment WHERE Name = 'Test Attachment'];
        Test.setCurrentPage(Page.StarTrackConsignmentDetails);
        ApexPages.currentPage().getParameters().put('sPODId', testPOD.Id);
        ApexPages.currentPage().getParameters().put('attachmentId', attach.Id);

        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackConsignmentDetails_ControllerX ctrl = new StarTrackConsignmentDetails_ControllerX(sc);
            ctrl.attachPODSignatureToCase();
            //test if attachment is attached to the Case
            System.assert(![SELECT Id FROM Attachment WHERE ParentId = :caseRec.Id].isEmpty());
        Test.stopTest();

    }

    @isTest static void testAttachPODSignatureToCase_TrackNTrace() {
        Case caseRec = [SELECT Id, ArticleTest__c FROM Case WHERE Subject = 'Test Case'];
        Article__c artRec = [SELECT Id, Source_System__c FROM Article__c WHERE Id =: caseRec.ArticleTest__c];
        artRec.Source_System__c = 'TRACK & TRACE';
        UPDATE artRec;

        Proof_of_Delivery__c testPOD = new Proof_of_Delivery__c();
        testPOD.Name = 'Test POD';
        testPOD.Consignment__c = caseRec.ArticleTest__c;
        testPOD.Signed_by__c = 'Tester';
        testPOD.SignatureXString__c = 'iVBORw0KGgoAAAANSUhEUgAAAPoAAABkAQMAAACVTr9NAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAGUExURQAAAP///6XZn90AAAAJcEhZcwAADsMAAA7DAcdvqGQAAAEnSURBVEjH7dMxTgMxEAXQ3CRHyRE4Qs5B5WOk5AgpU1CYG+QAKHJBsVVioUhYizMeZgxCCO3+X0C57lZ66/F8j1eK19NqAQtYwAJ+r8zADoGi2u4JGBsCVn/QgMEDBElbIGBUeIZoxyQgYxDsjAQEFQCa/46BYCB6ZcCirABUSwqCYkFgYDcBQZa+zTxIlYFCQDwqnuoYCQjB68yD1m8agbHXmQfSGwgAZAKql/+cuGlQIgO+uwBw6XUAODPw7B0UAA4M7L2DDMDWQZoHLTrYAOAv8yunSXDT76c7DcRBBaD6LAwAFAcJgMF73ABwtJRuCsBe9fUFga1FsQagxZ9fE0AYqIGAN/0rODNwYuCRgQMDdwS0SIAEAt6VgJGBKwOZgcSA/jv4AFz3QW6D/iIMAAAAAElFTkSuQmCC';
        INSERT testPOD;

        Test.setCurrentPage(Page.StarTrackConsignmentDetails);
        ApexPages.currentPage().getParameters().put('sPODId', testPOD.Id);

        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackConsignmentDetails_ControllerX ctrl = new StarTrackConsignmentDetails_ControllerX(sc);
            ctrl.attachPODSignatureToCase();
            //test if attachment is attached to the Case
            System.assert(![SELECT Id FROM Attachment WHERE ParentId = :caseRec.Id].isEmpty());
        Test.stopTest();

    }

    @isTest
    public static void testConsignSearch_singleResponse() {

        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = true,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert__c = 'cert',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.Name FROM Case WHERE Subject = 'Test Case']; 
        //List<Article__c> testArticle = new List<Article__c>([SELECT Id FROM Article__c WHERE Id =: caseRec.ArticleTest__c]);

        ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
        StarTrackConsignmentDetails_ControllerX cont = new StarTrackConsignmentDetails_ControllerX(sc);

        Test.startTest();        
        // Invoke the continuation by calling the action method
        Continuation conti = cont.searchConsignment();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_singleConsign());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);
        
        cont.logTime();
        Test.stopTest();

        // result is the return value of the callback
        System.assertEquals(null, result);               
    }
}