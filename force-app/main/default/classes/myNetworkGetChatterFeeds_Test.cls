/*
  * @author       : haraprasad.sahoo@auspost.com.au
  * @date         : 24/04/2020
  * @description  : Test class controller for myNetworkChatterPublisher LWC component
--------------------------------------- History --------------------------------------------------
24.04.2020    Hara Sahoo    Created
03.03.2021    Naseer Abbasi Updated to have feed created by Mynetwork user
*/
@isTest 
private class myNetworkGetChatterFeeds_Test {    
    private static User adminUser = new User();
    private static User myNetworkUser = new User();
    
    //Prepare test data
    private static void loadTestData(){
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        Profile adminProf = [SELECT Id, Name FROM Profile WHERE name = 'System Administrator' limit 1];
        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
        
        String caseRecordType = dataFactory.getRecordType('Case', 'SSSWGeneralEnquiry');
        String accId = dataFactory.getAccount().Id;
        Case caseRec = dataFactory.getCase(caseRecordType, accId);
        caseRec.Type='General Enquiry';
        insert caseRec;
        
        FeedItem feed = new FeedItem(Body = 'test feed item',ParentId = caseRec.Id, Type='TextPost');
        insert feed;
       
    }

    @isTest
    static void testPostChatter() {
        loadTestData();
        Case caseRec = [SELECT Id FROM CASE LIMIT 1];
        Test.startTest();
        myNetworkGetChatterFeeds.postNotification(caseRec.Id, 'This is a new comment');
        Test.stopTest();
    }

    @isTest
    //Execute testing
    static void testChatterFeedMethods() {
        loadTestData();
        Case caseRec = [SELECT Id FROM CASE LIMIT 1];
        
        System.runAs(adminUser){
            Test.startTest();
            list<myNetworkGetChatterFeeds.feedItemListWrapper> wrapperList = myNetworkGetChatterFeeds.getFeedElements(2,caseRec.Id);
            Test.stopTest();
        }
    }

    //Prepare test data
    private static void loadTestDataForMyNetworkUser(){
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        Profile myNetworkProf = [SELECT Id, Name FROM Profile WHERE name = 'MyNetwork Portal' limit 1];
        String myNetworkemail = 'myNetworkUser@mailinator.com';
        myNetworkUser = dataFactory.getUser(myNetworkProf.Id, myNetworkemail);
        Database.insert(myNetworkUser);
        
        String caseRecordType = dataFactory.getRecordType('Case', 'SSSWGeneralEnquiry');
        String accId = dataFactory.getAccount().Id;
        Case caseRec = dataFactory.getCase(caseRecordType, accId);
        caseRec.Type='General Enquiry';
        insert caseRec;    
    }

    @isTest
    //Execute testing
    static void testFeedItemCreationForMyNetworkUser() {
        loadTestDataForMyNetworkUser();
        Case caseRec = [SELECT Id FROM CASE LIMIT 1];
        
        System.runAs(myNetworkUser){
            myNetworkGetChatterFeeds.postNotification(caseRec.Id, 'test feed item');

            Test.startTest();
                list<myNetworkGetChatterFeeds.feedItemListWrapper> wrapperList = myNetworkGetChatterFeeds.getFeedElements(2,caseRec.Id);
            Test.stopTest();
        }
    }
}