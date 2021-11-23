@isTest
private class SalesCoachApexSharingTest {
   // Test for the manualShareRead method
   static testMethod void testManualShareRead(){
      Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
      
       User managerVar = new User(Alias = 'standt', Email='standarduser2@testorg.com', 
                                 EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                 LocaleSidKey='en_US', ProfileId = p.Id, 
                                 TimeZoneSidKey='America/Los_Angeles', UserName='shareTest2@test.com');
      insert managerVar;
       
      User userVar = new User(Alias = 'standt', Email='standarduser1@testorg.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id, managerId = managerVar.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='shareTest1@test.com');
      
       insert userVar;
       
       User noManagerVar = new User(Alias = 'standt', Email='standarduser3@testorg.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id, 
                              TimeZoneSidKey='America/Los_Angeles', UserName='shareTest3@test.com');
      
       insert noManagerVar;
       
       test.startTest();
          // Create new coaching record.
          try{
              Sales_Coaching__c jfail = new Sales_Coaching__c();
              jfail.Description__c = 'Test record';
              jfail.OwnerId = managerVar.Id;
              jfail.CoachingReceiver__c = noManagerVar.Id;
              jfail.score__c = 25;
              insert jfail;   
          }catch(exception e){
              // Failure expected
          }
           
          // Create new coaching record.
          Sales_Coaching__c j = new Sales_Coaching__c();
          j.Description__c = 'Test record';
          j.OwnerId = managerVar.Id;
          j.CoachingReceiver__c = userVar.Id;
          j.score__c = 25;
          insert j;    
                    
          // Insert manual share for user who is not record owner.
          // System.assertEquals(j.manualShareRead(j.Id, user2Id), true);
       
          // Query coaching sharing records.
          List<Sales_Coaching__Share> jShrs = [SELECT Id, UserOrGroupId, AccessLevel, 
          RowCause FROM Sales_Coaching__Share WHERE ParentId = :j.Id AND UserOrGroupId= :userVar.Id];
          
          // Test for only one manual share on job.
          System.assertEquals(jShrs.size(), 1, 'Set the object\'s sharing model to Private.');
          
          // Test attributes of manual share.
          System.assertEquals('Read',jShrs[0].AccessLevel);
          System.assertEquals('ReceiverShr__c',jShrs[0].RowCause);
          System.assertEquals(userVar.Id, jShrs[0].UserOrGroupId);
          
          // Test invalid coaching Id.
          delete j;   
       
          // Insert manual share for deleted job id. 
          // To Fix      System.assertEquals(SalesCoachApexSharing.manualShareRead(j.Id, user2Id), false);
   	  test.stopTest();
   }  
}