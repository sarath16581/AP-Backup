@isTest
//Test Class for retrieve and populate Banned Words into Platform Cache
private class cpSetBannedWordsCacheToOrg_Test {
    
    private static List<User> loadTestData(){
        
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        List<User> userList = new List<User>();
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        User adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
        userList.add(adminUser);

        return userList;
    }

	@isTest
  //Execute Test Class for retrieve and populate Banned Words into Platform Cache
	static void testSetOrgCache() {
		 String day = string.valueOf(system.now().day());
	     String month = string.valueOf(system.now().month());
	     String hour = string.valueOf(system.now().hour());
	     String minute = string.valueOf(system.now().minute() + 1);
	     String second = string.valueOf(system.now().second());
	     String year = string.valueOf(system.now().year());
	     String strJobName = 'TestcpSetBannedWordsCacheToOrg' + System.Now().Format();
	     String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year; 
         List<User> userList1 = loadTestData();
         System.runAs(userList1[0]){
            Test.startTest();
	     	System.schedule(strJobName, strSchedule, new cpSetBannedWordsCacheToOrg(userInfo.getSessionId()));
		 	Test.stopTest();
        }
         
    }

}