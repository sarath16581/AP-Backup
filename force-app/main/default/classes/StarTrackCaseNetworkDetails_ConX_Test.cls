/*------------------------------------------------------------
Author:        David Catindoy
Company:       Cloud Sherpas
Description:   Test class for StarTrackCaseNetworkDetails_ControllerX
History
October 14, 2015 - David Catindoy - Created
------------------------------------------------------------*/

@isTest
private class StarTrackCaseNetworkDetails_ConX_Test {

    @testSetup static void testSetup() {
        
        List<sObject> ls = TestDataProvider.createStartrackErrorMessagesData();

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
        
        Map<Id, Set<Id>> depotMap = new Map<Id, Set<Id>>();
        
        Case queryCase = [  SELECT Id, Network__c,
                            ArticleTest__c
                            FROM Case
                            LIMIT 1];
                                        
        Test.startTest();
           
            ApexPages.StandardController sc = new ApexPages.StandardController(queryCase);
            StarTrackCaseNetworkDetails_ControllerX controller = new StarTrackCaseNetworkDetails_ControllerX(sc);
            
            PageReference pageRef = Page.StarTrackCaseNetworkDetails;
            pageRef.getParameters().put('Id', String.valueOf(queryCase.Id));
            Test.setCurrentPage(pageRef);
            
            depotMap = controller.depotMap;
        
        Test.stopTest();
                            
        System.assert(depotMap != null);
        System.assert(depotMap.get(queryCase.ArticleTest__c).size() == 1);
    }
    
     @isTest static void testDepotCalculationNegativePath() {
        
        Map<Id, Set<Id>> depotMap = new Map<Id, Set<Id>>();
        
        Case queryCase = [  SELECT Id, Network__c,
                            ArticleTest__c
                            FROM Case
                            LIMIT 1];
                                        
        Test.startTest();
           
            ApexPages.StandardController sc = new ApexPages.StandardController(queryCase);
            StarTrackCaseNetworkDetails_ControllerX controller = new StarTrackCaseNetworkDetails_ControllerX(sc);
            
            PageReference pageRef = Page.StarTrackCaseNetworkDetails;
            pageRef.getParameters().put('Id', String.valueOf(queryCase.Id));
            Test.setCurrentPage(pageRef);
            
            controller.selectedDepot = queryCase.Id;
            controller.saveDepot();
        
        Test.stopTest();
        Article__c con = [SELECT Id, Network__c FROM Article__c WHERE Id =: queryCase.ArticleTest__c];
                            
        System.assertNotEquals(queryCase.Id, con.Network__c);
    }
    
    @isTest static void testDepotCalculationMoreThanOneMappingFound() {
        
        Map<Id, Set<Id>> depotMap = new Map<Id, Set<Id>>();
        List<SelectOption> selectOptionResult = new List<SelectOption>();
        
        Case queryCase = [  SELECT Id, Network__c,
                            ArticleTest__c
                            FROM Case
                            LIMIT 1];
                                        
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
            
            ApexPages.StandardController sc = new ApexPages.StandardController(queryCase);
            StarTrackCaseNetworkDetails_ControllerX controller = new StarTrackCaseNetworkDetails_ControllerX(sc);
            
            PageReference pageRef = Page.StarTrackCaseNetworkDetails;
            pageRef.getParameters().put('Id', String.valueOf(queryCase.Id));
            Test.setCurrentPage(pageRef);
            
            depotMap = controller.depotMap;
            selectOptionResult = controller.getDepotValues();
            controller.selectedDepot = network2.Id;
            controller.saveDepot();
            
        Test.stopTest();
        
        Article__c queryConsignment = [ SELECT Id, Receiver_Suburb__c,
                                        ReceiverPostcode__c, Service_Type__c, Network__c
                                        FROM Article__c WHERE Id = :queryCase.ArticleTest__c];
    
        System.assert(depotMap != null);
        System.assert(depotMap.get(queryCase.ArticleTest__c).size() > 1);
        System.debug(queryConsignment.Network__c == network2.Id);
        
    }
}