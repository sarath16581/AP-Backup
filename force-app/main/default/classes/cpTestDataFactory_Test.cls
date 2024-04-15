/*
--------------------------------------- History --------------------------------------------------
24.04.2020    Hara Sahoo    Modified Added Case comment creation
*/

//Test Class for Test Data Factory for Customer Community (Conversation Hub)project.
@isTest
private class cpTestDataFactory_Test {
    
    private static User adminUser = new User();
    
    /* Prepare Test data*/
    private static void loadTestData(){
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
    }

      //Prepare test data Account/Contact/User/Case records
      static testmethod void testcpTestDataFactoryMethods() {
          list<User> users = new list<User>();
          loadTestData();
          System.runAs(adminUser){
              cpTestDataFactory testData = new cpTestDataFactory();
              
              //create Account
              Account acc = testData.getAccount();
              Database.insert(acc);
              
              //create contact
              Contact con = testData.getContact(acc.Id);
              Database.insert(con);
              
              Profile p = [select Id, Name from Profile where name = 'DDC Consumer Community User' limit 1];
              Profile p1 = [select Id, Name from Profile where name = 'System Administrator' limit 1];
              
              //create users
              String testemail = 'puser000@mailinator.com';
              String cmtyNickName = 'testCommunityUser';
              User pusr = testData.getCommunityUser(p.Id,con.Id,testemail,cmtyNickName);
              users.add(pusr);
              
              String testemail1 = 'puser001@mailinator.com';
              String cmtyNickName1 = 'testCommunityUser1';
              User internalUsr = testData.getUser(p1.Id,testemail1);
              users.add(internalUsr);
              
              Database.insert(users);
              
              //query for case record type
              String caseRecordTYpeId = testData.getRecordType('Case','ACIC_Request');
			  //REQ3448199 replacing AMLCTF_Assurance_audit RT with ACIC Request
              
              //retrieve case
              Case caseRec = testData.getCase(caseRecordTYpeId, acc.Id);
              //retrieve casecomment
              Casecomment comment = testData.getCaseComment('new comment', caseRec.Id);
        }
    }
}