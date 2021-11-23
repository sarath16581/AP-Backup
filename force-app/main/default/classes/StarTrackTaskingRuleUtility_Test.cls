/**
 ** Description: Test Class for StarTrackTaskingRuleUtility class
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: March 9, 2016
 ** History:--------------------------------------------
 **         March 9, 2016 David Catindoy - Created
 **/
@isTest
private class StarTrackTaskingRuleUtility_Test {

     @testSetup static void testSetup(){

        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        testNetwork.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId();
        INSERT testNetwork;

        Article__c testCon = TestDataProvider.createTestArticle();
        testCon.ReceiverName__c = 'David Catindoy';
        testCon.Network__c = testNetwork.Id;
        INSERT testCon;

        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.Origin = 'Email';
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        testCase.Network__c = testNetwork.Id;
        testCase.ArticleTest__c = testCon.Id;
        INSERT testCase;
        
        Postcode__c postcode = new Postcode__c(Name = 'Sample Postcode', State__c = 'Melbourne', Suburb__c = 'Makati');
        INSERT postcode;
        
        Book_In_Customer__c bookinRec = new Book_In_Customer__c(Name = 'David Catindoy', Book_In_Detail__c = 'Sample', Network__c = testNetwork.Id, Suburb_Postcode__c = postcode.Id);
        INSERT bookinRec;
        
        List<Depot_Area__c> depotAreas = new List<Depot_Area__c>();
        depotAreas.add(new Depot_Area__c(Name = 'Melbourne', Area__c = 'Operations', Depot__c = testNetwork.Id, Used_for_Tasking__c = true));
        depotAreas.add(new Depot_Area__c(Name = 'Melbourne', Area__c = 'Bulk', Depot__c = testNetwork.Id, Used_for_Tasking__c = true));
        depotAreas.add(new Depot_Area__c(Name = 'Melbourne', Area__c = 'Bookins/MCL', Depot__c = testNetwork.Id, Used_for_Tasking__c = true));
        depotAreas.add(new Depot_Area__c(Name = 'Melbourne', Area__c = 'Redelivery', Depot__c = testNetwork.Id, Used_for_Tasking__c = true));
        INSERT depotAreas;
        
        List<Depot_Area_User__c> depotAreaUsers = new List<Depot_Area_User__c>();
        depotAreaUsers.add(new Depot_Area_User__c(Name = 'David Catindoy', Depot_Role__c = depotAreas[0].Id, User__c = UserInfo.getUserId()));
        depotAreaUsers.add(new Depot_Area_User__c(Name = 'David Catindoy', Depot_Role__c = depotAreas[1].Id, User__c = UserInfo.getUserId()));
        depotAreaUsers.add(new Depot_Area_User__c(Name = 'David Catindoy', Depot_Role__c = depotAreas[2].Id, User__c = UserInfo.getUserId()));
        depotAreaUsers.add(new Depot_Area_User__c(Name = 'David Catindoy', Depot_Role__c = depotAreas[3].Id, User__c = UserInfo.getUserId()));
        INSERT depotAreaUsers;
        
        List<StarTrack_Tasking_Rules__c> taskingRuleList = new List<StarTrack_Tasking_Rules__c>();
        taskingRuleList.add(new StarTrack_Tasking_Rules__c(Book_In_Customer__c = true, Depot_Area__c = 'Bookins/MCL', Depot_RecordType__c = 'StarTrack_Metro_9', Order__c = 1));
        taskingRuleList.add(new StarTrack_Tasking_Rules__c(Depot_Area__c = 'Bulk', Depot_RecordType__c = 'StarTrack_Metro_9', Order__c = 2, Freight_Type__c = 'Pallet'));
        taskingRuleList.add(new StarTrack_Tasking_Rules__c(Depot_Area__c = 'Bulk', Depot_RecordType__c = 'StarTrack_Metro_9', Order__c = 3, Weight__c = 50));
        taskingRuleList.add(new StarTrack_Tasking_Rules__c(Depot_Area__c = 'Bulk', Depot_RecordType__c = 'StarTrack_Metro_9', Order__c = 4, Quantity__c = 50));
        taskingRuleList.add(new StarTrack_Tasking_Rules__c(Depot_Area__c = 'Redelivery', Depot_RecordType__c = 'StarTrack_Metro_9', Enquiry_Type__c = 'Redelivery', Order__c = 5));
        taskingRuleList.add(new StarTrack_Tasking_Rules__c(Depot_Area__c = 'Operations', Depot_RecordType__c = 'StarTrack_Metro_9', Order__c = 6));
        INSERT taskingRuleList;
    }

    @isTest static void firstScenario(){
        Case caseRec = [SELECT Id, Network__c, Network__r.Preferred_Method_of_Tasking__c, Network__r.Parent_Network__c, ArticleTest__c, ArticleTest__r.ReceiverName__c, Network__r.RecordType.DeveloperName, Network__r.RecordType.Name, ArticleTest__r.Unit_Type__c, ArticleTest__r.ActualWeight__c,
                        ArticleTest__r.Number_of_Items__c, Enquiry_Type__c FROM Case WHERE Subject = 'Test Case'];

        Map<Id, Depot_Area__c> depotAreaMap = new Map<Id, Depot_Area__c>();
        Test.startTest();
            depotAreaMap = StarTrackTaskingRuleUtility.taskingRule(new List<Case>{caseRec});
        Test.stopTest();
        System.assertEquals('Bookins/MCL', depotAreaMap.get(caseRec.Id).Area__c);
    }
    
    @isTest static void secondScenario(){
        
        Article__c conRec = [SELECT Id, Unit_Type__c, ActualWeight__c, Number_of_Items__c FROM Article__c LIMIT 1];
        conRec.ReceiverName__c = 'Wayne Helena';
        conRec.Unit_Type__c = 'Pallet';
        update conRec;
        
        Case caseRec = [SELECT Id, Network__c, Network__r.Preferred_Method_of_Tasking__c, Network__r.Parent_Network__c, ArticleTest__c, ArticleTest__r.ReceiverName__c, Network__r.RecordType.DeveloperName, Network__r.RecordType.Name, ArticleTest__r.Unit_Type__c, ArticleTest__r.ActualWeight__c,
                        ArticleTest__r.Number_of_Items__c, Enquiry_Type__c FROM Case WHERE Subject = 'Test Case'];
        
        Map<Id, Depot_Area__c> depotAreaMap = new Map<Id, Depot_Area__c>();
        Test.startTest();
            depotAreaMap = StarTrackTaskingRuleUtility.taskingRule(new List<Case>{caseRec});
        Test.stopTest();
        System.assertEquals('Bulk', depotAreaMap.get(caseRec.Id).Area__c);
    }
    
    @isTest static void thirdScenario(){
        Article__c conRec = [SELECT Id, Unit_Type__c, ActualWeight__c, Number_of_Items__c FROM Article__c LIMIT 1];
        conRec.ReceiverName__c = 'Wayne Helena';
        update conRec;
        
        Case caseRec = [SELECT Id, Network__c, Network__r.Preferred_Method_of_Tasking__c, Network__r.Parent_Network__c, ArticleTest__c, ArticleTest__r.ReceiverName__c, Network__r.RecordType.DeveloperName, Network__r.RecordType.Name, ArticleTest__r.Unit_Type__c, ArticleTest__r.ActualWeight__c,
                        ArticleTest__r.Number_of_Items__c, Enquiry_Type__c FROM Case WHERE Subject = 'Test Case'];
        
        Map<Id, Depot_Area__c> depotAreaMap = new Map<Id, Depot_Area__c>();
        Test.startTest();
            depotAreaMap = StarTrackTaskingRuleUtility.taskingRule(new List<Case>{caseRec});
        Test.stopTest();
        System.assertEquals('Operations', depotAreaMap.get(caseRec.Id).Area__c);
    }
    
    @isTest static void testParentNetwork(){
        Article__c conRec = [SELECT Id, Unit_Type__c, ActualWeight__c, Number_of_Items__c, Network__c FROM Article__c LIMIT 1];
        
        Network__c parentDepot = [SELECT Id, Preferred_Method_of_Tasking__c FROM Network__c WHERE Id =: conRec.Network__c];
        
        Network__c childDepot = TestDataProvider.createNetwork('Test Network', 1)[0];
        childDepot.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId();
        childDepot.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT;
        childDepot.Parent_Depot__c = true;
        childDepot.Parent_Network__c = parentDepot.Id;
        INSERT childDepot;
        
        conRec.ReceiverName__c = 'Wayne Helena';
        conRec.Network__c = childDepot.Id;
        update conRec;
        
        Case caseRec = [SELECT Id, Enquiry_Type__c, Network__c FROM Case WHERE Subject = 'Test Case'];
        caseRec.Enquiry_Type__c = 'Redelivery';
        caseRec.Network__c = childDepot.Id;
        update caseRec;
        caseRec = [SELECT Id, Network__c, Network__r.Preferred_Method_of_Tasking__c, Network__r.Parent_Network__c, ArticleTest__c, ArticleTest__r.ReceiverName__c, Network__r.RecordType.DeveloperName, Network__r.RecordType.Name, ArticleTest__r.Unit_Type__c, ArticleTest__r.ActualWeight__c,
                        ArticleTest__r.Number_of_Items__c, Enquiry_Type__c FROM Case WHERE Id =: caseRec.Id];
        
        Map<Id, Depot_Area__c> depotAreaMap = new Map<Id, Depot_Area__c>();
        Test.startTest();
            depotAreaMap = StarTrackTaskingRuleUtility.taskingRule(new List<Case>{caseRec});
        Test.stopTest();
        System.assertEquals('Redelivery', depotAreaMap.get(caseRec.Id).Area__c);
    }
}