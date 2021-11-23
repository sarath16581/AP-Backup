@isTest
/* Test Class for Nickname update validation used by Community Cloud Project*/
private class cpUserNickNameHandler_Test{

    /* Prepare Test data*/
    private static List<User> loadTestData(){
        cpTestDataFactory dataFactory = new cpTestDataFactory();

        List<Account> accList = new List<Account>();
        List<User> userList = new List<User>();
        List<Contact> cntList = new List<Contact>();
        
        //create Accounts
        Account acc = dataFactory.getAccount();
        accList.add(acc);

        Account acc1 = dataFactory.getAccount();
        acc1.Name = 'TEST1 ACCOUNT1';
        accList.add(acc1);
        
        Database.insert(accList);
		
        //Create contacts
        Contact cnt = dataFactory.getContact(acc.Id);
        cntList.add(cnt);

        Contact cnt1 = dataFactory.getContact(acc1.Id);
        cnt1.FirstName = 'firstname1';
        cnt1.LastName = 'lastname1';
        cnt1.Email = 'testUser1@Mailinator.com';
        cntList.add(cnt1);
        
        Database.insert(cntList);
		
        //Query for Profile
        Profile p = [select Id, Name from Profile where name = 'DDC Consumer Community User' limit 1];
		Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];
        
        //Create Users
        String testemail = 'puser000@mailinator.com';
        String cmtyNickName = 'testCommunityUser';
        User pusr = dataFactory.getCommunityUser(p.Id,cnt.Id,testemail,cmtyNickName);
        userList.add(pusr);

        String testemail1 = 'puser001@mailinator.com';
        String cmtyNickName1 = 'testCommunityUser1';
        User pusr1 = dataFactory.getCommunityUser(p.Id,cnt1.Id,testemail1,cmtyNickName1);
        userList.add(pusr1);
        
        String adminemail = 'sysadmin@mailinator.com';
        User adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        userList.add(adminUser);
		
        Database.insert(userList);
        
        return userList;
    }

        @isTest
        /* Execute Test*/
        static void executeUserNickNameHandlerMethods(){
        List<User> userList1 = loadTestData();
            System.runAs(userList1[2]){
                Test.startTest();
        		cpUserNickNameHandler handler = new cpUserNickNameHandler();
       	 		handler.userNicknameProfanityCheck(userList1);
        		Test.stopTest();
            } 
	}
}