/***
 * @author Ranjeewa Silva
 * @date 2021-03-09
 * @group Tests
 * @tag CreditDisputeClaims, Tests
 * @description Test Scenarios for retrieving documents via public url and attaching to credit dispute claims
 * @changelog
 * 2021-03-09 - Ranjeewa Silva - Created.
 */

@IsTest
private class RetrieveDisputedCreditDocsBatchable_Test {

    @IsTest
    static void testBatchStart() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> creditDisputeCases = ApplicationTestDataFactory.getCases(5, true);
        Set<Id> creditDisputeCaseIds = new Map<Id, Case>(creditDisputeCases).keySet();
        // =====================================
        // Stubbing
        // =====================================
        DisputedItemsSelector mockSelector = (DisputedItemsSelector) MockUtility.mockSelector(DisputedItemsSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByCaseIdQueryLocator((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(null);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        RetrieveDisputedCreditDocumentsBatchable batch = new RetrieveDisputedCreditDocumentsBatchable(new List<Id>(creditDisputeCaseIds), null, null, null);
        batch.start(null);

        Test.stopTest();

        fflib_ArgumentCaptor caseIdCaptor = fflib_ArgumentCaptor.forClass(Set<Id>.class);

        //verify that selector is called once with bulk load request id to get the query locator
        ((DisputedItemsSelector) MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByCaseIdQueryLocator((Set<Id>) caseIdCaptor.capture(), (Set<Object>) fflib_Match.anyObject());

        Set<Id> caseIds = (Set<Id>) caseIdCaptor.getValue();
        System.assertNotEquals(null, caseIds, 'Expected a set of case ids to be passed into the selector as an argument; but passed null.');
        System.assertEquals(false, caseIds.isEmpty(), 'Expected set of case ids to be passed into the selector as an argument; but was empty.');
        System.assertEquals(true, caseIds.containsAll(creditDisputeCaseIds), 'Expected all case ids to be passed into the selector; but some ids missing.');

    }

    @IsTest
    static void testBatchExecute() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(2, true);

        List<Disputed_Item__c> disputedItemsClaimOne = ApplicationTestDataFactory.getDisputedItems(3, cases[0].Id, true);
        // Case One has 3 DI lines. 2 of them have same supporting document URL specified
        disputedItemsClaimOne[0].SupportingDocumentDownloadURL__c = 'https://testcustomersite.com.au/docs/doc1.pdf';
        disputedItemsClaimOne[2].SupportingDocumentDownloadURL__c = 'https://testcustomersite.com.au/docs/doc1.pdf';

        List<Disputed_Item__c> disputedItemsClaimTwo = ApplicationTestDataFactory.getDisputedItems(4, cases[1].Id, true);
        // Case Two has 2 DI lines. Each one has a supporting document URL specified (different docs).
        disputedItemsClaimTwo[0].SupportingDocumentDownloadURL__c = 'https://testcustomersite.com.au/docs/doc3.pdf';
        disputedItemsClaimTwo[1].SupportingDocumentDownloadURL__c = 'https://testcustomersite.com.au/docs/doc4.pdf';
        disputedItemsClaimTwo[2].SupportingDocumentDownloadURL__c = 'https://testcustomersite.com.au/documentnotfound/doc5.pdf';
        disputedItemsClaimTwo[3].SupportingDocumentDownloadURL__c = 'https://testcustomersite.com.au/internalerror/doc6.pdf';

        // =====================================
        // Stubbing
        // =====================================

        ExternalDocumentHostHttpMock mockDocumentHost = new ExternalDocumentHostHttpMock();
        Test.setMock(HttpCalloutMock.class, mockDocumentHost);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        RetrieveDisputedCreditDocumentsBatchable batch = new RetrieveDisputedCreditDocumentsBatchable(new List<Id>{cases[0].Id, cases[1].Id}, 1, 5, false);
        List<Disputed_Item__c> disputedItems = new List<Disputed_Item__c>();
        disputedItems.addAll(disputedItemsClaimOne);
        disputedItems.addAll(disputedItemsClaimTwo);
        batch.execute(null, disputedItems);

        Test.stopTest();

        System.assertEquals(5, mockDocumentHost.documentUrls.size(), 'Expected each unique document to be retrieved once.');
        //System.assertEquals(3, mockDocumentHost.documentUrls.size(), 'Expected each unique document to be retrieved once.');
        System.assertEquals(true, mockDocumentHost.documentUrls.contains(disputedItemsClaimOne[0].SupportingDocumentDownloadURL__c), 'Expected to retrieve document via public url; but not attempted.');
        System.assertEquals(true, mockDocumentHost.documentUrls.contains(disputedItemsClaimTwo[0].SupportingDocumentDownloadURL__c), 'Expected to retrieve document via public url; but not attempted.');
        System.assertEquals(true, mockDocumentHost.documentUrls.contains(disputedItemsClaimTwo[1].SupportingDocumentDownloadURL__c), 'Expected to retrieve document via public url; but not attempted.');
        //following are failure cases - but still verifying if there was an attempt to retrieve the documents
        System.assertEquals(true, mockDocumentHost.documentUrls.contains(disputedItemsClaimTwo[2].SupportingDocumentDownloadURL__c), 'Expected to retrieve document via public url; but not attempted.');
        System.assertEquals(true, mockDocumentHost.documentUrls.contains(disputedItemsClaimTwo[3].SupportingDocumentDownloadURL__c), 'Expected to retrieve document via public url; but not attempted.');

        List<ContentVersion> contentVersions = [Select Id from ContentVersion];
        System.assertEquals(3, contentVersions.size(), 'Expected 3 content version records to be created');

    }

    public class ExternalDocumentHostHttpMock implements HttpCalloutMock {

        List<String> documentUrls = new List<String>();

        public HttpResponse respond(HttpRequest request) {

            String endPointUrl = request.getEndpoint();
            documentUrls.add(endPointUrl);
            HttpResponse res = new HttpResponse();
            if (endPointUrl.containsIgnoreCase('documentnotfound')) {
                res.setStatusCode(404);
                res.setStatus('Not Found');
            } else if (endPointUrl.containsIgnoreCase('internalerror')) {
                res.setStatusCode(500);
                res.setStatus('Internal Error');
            } else {
                res.setStatusCode(200);
                res.setHeader('Content-Disposition', 'attachment; filename="testdocument.pdf"');
                res.setBody('test document contents....');
            }
            return res;
        }
    }
}