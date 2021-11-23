/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test class for StarTrack Depot Calculation Utility
History
May 16, 2015 - David Catindoy - Created
------------------------------------------------------------*/

@isTest
private class StarTrackDepotCalculationUtility_Test {

    @testSetup static void testSetup() {

        Network__c network = TestDataProvider.createTestNetwork();
        network.Facility__c = 'Next Flight';
        INSERT network;

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.ReceiverPostcode__c = '1220';
        testArticle.Service_Type__c = 'Next Flight';
        testArticle.Receiver_Suburb__c = 'Cambridge';
        INSERT testArticle;
        
        Postcode__c postCode = TestDataProvider.createTestPostCode();
        INSERT postCode;
        
        PostcodeMapping__c postCodeMap = TestDataProvider.createTestPostCodeMapping();
        postCodeMap.Postcode__c = postCode.Id;
        postCodeMap.Network__c = network.Id;
        INSERT postCodeMap;

        Id pudCaseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = pudCaseRecTypeId;
        testCase.Call_Purpose__c = 'Other';
        testCase.ArticleTest__c = testArticle.Id;
        INSERT testCase;
    }

    @isTest static void testDepotCalculationHappyPath() {
        
        Map<Id, Set<Id>> depotResult = new Map<Id, Set<Id>>();
        
        Article__c queryConsignment = [ SELECT Id, Receiver_Suburb__c,
                                        ReceiverPostcode__c, Service_Type__c, Network__c
                                        FROM Article__c LIMIT 1];

        Test.startTest();
            depotResult = StarTrackDepotCalculationUtility.queryPostCodeMapping(new List<Article__c>{queryConsignment});
        Test.stopTest();
                            
        System.assert(depotResult != null);
        System.assert(depotResult.get(queryConsignment.Id).size() == 1);
    }
    
    @isTest static void testDepotCalculationMoreThanOneMappingFound() {
        
        Map<Id, Set<Id>> depotResult = new Map<Id, Set<Id>>();
        
        Article__c queryConsignment = [ SELECT Id, Receiver_Suburb__c,
                                        ReceiverPostcode__c, Service_Type__c, Network__c
                                        FROM Article__c LIMIT 1];
                                        
        Postcode__c queryPostCodeMap = [SELECT Id, Name, Suburb__c 
                                        FROM Postcode__c
                                        WHERE Name = '1220'];
                                        
        Network__c network2 = TestDataProvider.createTestNetwork();
        network2.Name = 'Melbourne Metro';
        network2.Facility__c = 'Next Flight';
        INSERT network2;
        
        PostcodeMapping__c postCodeMap2 = TestDataProvider.createTestPostCodeMapping();
        postCodeMap2.Postcode__c = queryPostCodeMap.Id;
        postCodeMap2.Network__c = network2.Id;
        INSERT postCodeMap2;
        
        Test.startTest();
            depotResult = StarTrackDepotCalculationUtility.queryPostCodeMapping(new List<Article__c>{queryConsignment});
        Test.stopTest();
                            
        System.assert(depotResult != null);
        System.assert(depotResult.get(queryConsignment.Id).size() > 1);
        
    }
}