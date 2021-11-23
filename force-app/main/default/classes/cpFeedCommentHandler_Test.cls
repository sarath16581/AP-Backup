@isTest
//Test class for feed comment handler used by Customer Community case mgmt
private class cpFeedCommentHandler_Test {
    private static User adminUser = new User();
    //Get comment
    private static list<FeedComment> feedComments = new list<FeedComment>();
    //Prepare test data
    private static void loadTestData(){
        
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
        
        //Create feed Item Record 
        FeedItem fItem = new FeedItem();
        fItem.ParentId = caseRec.Id;
        fItem.body = 'test';
        Database.insert(fItem);
        
        //Create feedComment Records
        for(Integer index = 0; index < 4; index++){
            FeedComment fcomment = new FeedComment();
            fcomment.CommentBody = 'FeedComment test '+ index;
            fcomment.FeedItemId = fItem.Id;
            feedComments.add(fcomment);
        }
        
        Database.insert(feedComments);
    }
    //Execute testing
    public static testMethod void testFeedCommentHandlerMethods(){
        loadTestData();
        System.runAs(adminUser){
            cpFeedCommentHandler commentHandler = new cpFeedCommentHandler();
            commentHandler.updateCaseStatus(feedComments);
        }
    }
        
}