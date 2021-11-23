@isTest
/* Test Class for User trigger used by Community Cloud Project
* 23-10-2018 dilshan.egodawela@auspost.com.au modified to include to the test methods for populating federation ID
* */
private class cpUserTrigger_Test {


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
        acc1.Name = 'TEST1 ACCOUNT1'+ system.now();
        accList.add(acc1);

        Database.insert(accList);

        //Create contacts
        Contact cnt = dataFactory.getContact(acc.Id);
        cntList.add(cnt);

        Contact cnt1 = dataFactory.getContact(acc1.Id);
        cnt1.FirstName = 'firstname1'+ system.now();
        cnt1.LastName = 'lastname1'+ system.now();
        cnt1.Email = 'testUser134@Mailinator.com';
        cntList.add(cnt1);

        Database.insert(cntList);

        //Query for Profile
        Profile p = [select Id, Name from Profile where name = 'DDC Consumer Community User' limit 1];
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        //Create Users
        String testemail = 'puser0005@mailinator.com';
        String cmtyNickName = 'testAusPostCommunityUser';
        User pusr = dataFactory.getCommunityUser(p.Id,cnt.Id,testemail,cmtyNickName);
        userList.add(pusr);

        String testemail1 = 'puser0015@mailinator.com';
        String cmtyNickName1 = 'testAusPostCommunityUser1';
        User pusr1 = dataFactory.getCommunityUser(p.Id,cnt1.Id,testemail1,cmtyNickName1);
        userList.add(pusr1);

        String adminemail = 'sysadmin2@mailinator.com';
        User adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        userList.add(adminUser);

        Database.insert(userList);

        return userList;
    }

    @isTest
    /* Execute Test*/
    static void executeUserTrigger(){
        List<User> userListToUpdate = new List<User>();
        try{
            List<User> userList1 = loadTestData();
            User runningUser = [SELECT Id, IsPortalEnabled, Name, CommunityNickname, LastModifiedById, ProfileId FROM User Where Email = 'puser0005@mailinator.com'];
            System.runAs(runningUser){
                Test.startTest();

                for(User userInfo : [Select Id, Name, CommunityNickname FROM User Where Email = 'puser0005@mailinator.com']){
                    userInfo.CommunityNickname = 'testNickName'+ system.now().addMinutes(3);
                    userListToUpdate.add(userInfo);
                }
                database.update(userListToUpdate);

                Test.stopTest();
            }
        }catch (exception ex){

        }
    }
    /********************************************
	Scenario:
	Test populating federation ID field on DDC Consumer Community User Creation and Username update
	*********************************************/
    static testMethod void testPopulateFedIdInsertMethod() {

        cpTestDataFactory dataFactory = new cpTestDataFactory();
        //create Accounts
        Account acc = dataFactory.getAccount();
        insert acc;

        //Create contacts
        Contact cnt = dataFactory.getContact(acc.Id);
        insert cnt;

        //Query for Profile
        Profile p = [select Id, Name from Profile where name = 'DDC Consumer Community User' limit 1];

        //Create Users

        User pusr = new User(profileId = p.Id, username = 'puser0005@mailinator.com', email = 'puser0005@mailinator.com',
                emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                alias='cspu', lastname='lastname', CommunityNickname = 'testAPUser', contactId = cnt.Id);


        Test.startTest();

        //insert community user
        insert pusr;

        Test.stopTest();

        //get the inserted user record.
        User newUser = [select Id,Name,FederationIdentifier from User where email = 'puser0005@mailinator.com' limit 1];
        System.assertEquals('puser0005@mailinator.com', newUser.FederationIdentifier);

    }

    //future method to avoid MIXED DML OPERATION error.
    //this method will be called from the testPopulateFedIdUpdateMethod to update username.
    @future
    public static void UpdateUser() {
        //get the inserted user record.
        User newUser = [select Id,Username,FederationIdentifier from User where email = 'puser0005@mailinator.com' limit 1];
        newUser.Username = 'NewUserName@mailinator.com';
        update newUser;

    }

    /********************************************
	Scenario:
	Test populating federation ID field on DDC Consumer Community User Creation and Username update
	*********************************************/
    static testMethod void testPopulateFedIdUpdateMethod() {

        cpTestDataFactory dataFactory = new cpTestDataFactory();
        //create Accounts
        Account acc = dataFactory.getAccount();
        insert acc;

        //Create contacts
        Contact cnt = dataFactory.getContact(acc.Id);
        insert cnt;

        //Query for Profile
        Profile p = [select Id, Name from Profile where name = 'DDC Consumer Community User' limit 1];

        //Create Users

        User pusr = new User(profileId = p.Id, username = 'puser0005@mailinator.com', email = 'puser0005@mailinator.com',
                emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                alias='cspu', lastname='lastname', CommunityNickname = 'testAPUser', contactId = cnt.Id);

        //insert community user
        insert pusr;


        Test.startTest();

        UpdateUser();

        Test.stopTest();

        //get the updated user record.
        User newUser2 = [select Id,Name,FederationIdentifier from User where email = 'puser0005@mailinator.com' limit 1];
        System.assertEquals('NewUserName@mailinator.com', newUser2.FederationIdentifier);

    }
}