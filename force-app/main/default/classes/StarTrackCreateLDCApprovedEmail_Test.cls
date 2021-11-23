/*------------------------------------------------------------
Author:        David Catindoy
Company:       Cloud Sherpas
Description:   Test Class for StarTrackCreateLDCApprovedEmail
History
May 16, 2016 - David Catindoy - Created
------------------------------------------------------------*/

@isTest
private class StarTrackCreateLDCApprovedEmail_Test {
@testSetup
    static void testSetup(){
        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.ExpectedDeliveryDate__c = Date.today();
        INSERT testArticle;
    }

    @isTest static void testcreateLDCApprovedEmail() {
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
            StarTrackCreateLDCApprovedEmail.createLDCApprovedEmail(new List<Id>{testCase.Id});
        Test.stopTest();
        List<Workflow_Email__c> workflowRec = [SELECT Id, Case__c, Status__c, To_Address__c, Task_Subject__c, Consignment_Number__c FROM Workflow_Email__c];
        System.assert(workflowRec.size()>0);
        for(Workflow_Email__c testRec : workflowRec){
            System.assertEquals(testCase.Id, testRec.Case__c);
            System.assertEquals('Open', testRec.Status__c);
            System.assertEquals(testCase.SuppliedEmail, testRec.To_Address__c);
            System.assertEquals(testCase.ArticleTest__c, testRec.Consignment_Number__c);
        }
    }
}