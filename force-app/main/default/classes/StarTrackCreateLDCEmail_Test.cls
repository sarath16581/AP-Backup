/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test Class for StarTrackCreateLDCEmail
History
May 13, 201 - David Catindoy - Created
------------------------------------------------------------*/

@isTest
private class StarTrackCreateLDCEmail_Test {

    @testSetup
    static void testSetup(){
        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.ExpectedDeliveryDate__c = Date.today();
        INSERT testArticle;
    }

    @isTest
    static void testcreateLDCEmail() {
        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = delEnquiryRecTypeId;
        testCase.Call_Purpose__c = 'Card Left';
        testCase.Enquiry_Type__c = 'Depot Collection';
        testCase.Claim_Date__c = Datetime.now() + 2;
        testCase.SuppliedEmail = 'te@st.test';
        testCase.ArticleTest__c = [SELECT Id FROM Article__c LIMIT 1].Id;
        INSERT testCase;

        Test.startTest();
            StarTrackCreateLDCEmail.createLDCEmail(new List<Id>{testCase.Id});
        Test.stopTest();
        System.assert(![SELECT Id FROM workflow_Email__c].isEmpty());
    }
}