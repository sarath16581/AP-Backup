/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test class for StarTrackProductMapping
History
May 16, 2015 - David Catindoy - Created
------------------------------------------------------------*/

@isTest
private class StarTrackProductMapping_Test {

    @isTest static void testProductMapping() {
    	//dummy test class
    	//apex class no longer used
    	List<Id> dummyIds = new List<Id>();
    	StarTrackProductMapping.serviceTypeCalculation(dummyIds);
    }
    /*@testSetup static void testSetup() {

        Network__c networkRec = TestDataProvider.createTestNetwork();
        networkRec.Facility__c = 'Next Flight';
        INSERT networkRec;

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.ReceiverPostcode__c = '1220';
        testArticle.Service_Type__c = 'Next Flight';
        testArticle.Receiver_Suburb__c = 'Cambridge';
        testArticle.Network__c = networkRec.Id;
        testArticle.ServiceCode__c = 'EXP';
        testArticle.Customer_Type__c = 'STE';
        INSERT testArticle;

        Id pudCaseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = pudCaseRecTypeId;
        testCase.Call_Purpose__c = 'Other';
        testCase.ArticleTest__c = testArticle.Id;
        INSERT testCase;
    }

    @isTest static void testServiceTypeCalculation() {
        
        Article__c queryConsignment = [ SELECT Id FROM Article__c LIMIT 1];

        Test.startTest();
            StarTrackProductMapping.serviceTypeCalculation(new List<Id>{queryConsignment.Id});
        Test.stopTest();
            
        queryConsignment = [SELECT Id, Product_Group__c, Service_Type__c, STServiceType__c
                            FROM Article__c
                            WHERE Id =: queryConsignment.Id];    
        System.assertEquals('Express', queryConsignment.Service_Type__c);
        System.assertEquals('Express', queryConsignment.Product_Group__c);
        System.assertEquals('ROAD EXPRESS', queryConsignment.STServiceType__c);
    }*/
}