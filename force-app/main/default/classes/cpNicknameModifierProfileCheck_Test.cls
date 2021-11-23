@isTest
//Test class for Nickname validation class
private class cpNicknameModifierProfileCheck_Test{
	//Load Test Data
	private static List<User> loadTestData(){
		cpTestDataFactory dataFactory = new cpTestDataFactory();
		List<Account> accList = new List<Account>();
        List<Contact> cntList = new List<Contact>();
        List<User> userList = new List<User>();
        Account acc = dataFactory.getAccount();
        accList.add(acc);

        Account acc1 = dataFactory.getAccount();
        acc1.Name = 'TEST1 ACCOUNT1';
        accList.add(acc1);
        Database.insert(accList);

        Contact cnt = dataFactory.getContact(acc.Id);
        cntList.add(cnt);

        Contact cnt1 = dataFactory.getContact(acc1.Id);
        cnt1.FirstName = 'firstname1';
        cnt1.LastName = 'lastname1';
        cnt1.Email = 'testUser1@Mailinator.com';
        cntList.add(cnt1);
        
        Database.insert(cntList);

        Profile p = [select Id, Name from Profile where name = 'DDC Consumer Community User' limit 1];

        String testemail = 'puser000@mailinator.com';
        String cmtyNickName = 'testCommunityUser';
        User pusr = dataFactory.getCommunityUser(p.Id,cnt.Id,testemail,cmtyNickName);
        userList.add(pusr);

        String testemail1 = 'puser001@mailinator.com';
        String cmtyNickName1 = 'testCommunityUser1';
        User pusr1 = dataFactory.getCommunityUser(p.Id,cnt1.Id,testemail1,cmtyNickName1);
        userList.add(pusr1);
		
        Database.insert(userList);
        
        return userList;
	}

	@isTest
	static void testNicknameModifierCheck(){
		List<User> userList1 = loadTestData();
                Test.startTest();
                System.runAs(userList1[0]){
                    cpNicknameModifierProfileCheck usrHanlrObj = new cpNicknameModifierProfileCheck();
                    list<User> uers = usrHanlrObj.nicknameModifierCheck(userList1);
                }
                Test.stopTest();

	}
}