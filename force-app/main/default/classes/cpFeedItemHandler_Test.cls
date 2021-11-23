@isTest
//Test class for Feed item handler used by Customer Community Case mgmt
private class cpFeedItemHandler_Test {
    private static User adminUser = new User();
    //Get Feed item
    private static list<FeedItem> feedItems = new list<FeedItem>();
    //Prepare test data
    private static void loadTestData(){
        list<FeedItem> tempFeedItems = new list<FeedItem>();
        
        //create running user
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
        
        //Get record type from Data Factory
        String caseRecordTypeId = dataFactory.getRecordType('Case', 'SSSWGeneralEnquiry');
        
        //Create Account Record
        Account acc = dataFactory.getAccount();
        Database.insert(acc);
        
        //Create case Record
        Case caseRec = dataFactory.getCase(caseRecordTypeId, acc.Id);
        caseRec.Type = 'General Enquiry';
        Database.insert(caseRec);
        
        //Create feed Item Records 
        for(Integer index = 1; index < 4; index++){
            FeedItem fItem = new FeedItem();
            fItem.ParentId = caseRec.Id;
            fItem.body = 'test '+index;
            fItem.Title = 'FileName '+index;
            tempFeedItems.add(fItem);
        }
         Database.insert(tempFeedItems);
        
        for(FeedItem feed : [Select Id, body, InsertedById, ParentId, Title from FeedItem Where ParentId =: caseRec.Id ]){
            feedItems.add(feed);
        }
    }
    
    @isTest
    //Execute testing
    static void testFeedItemHandlerMethods(){
        loadTestData();
        System.runAs(adminUser){
            cpFeedItemHandler feedHandler = new cpFeedItemHandler();
            feedHandler.caseStatusUpdater(feedItems);
        }
    }
}