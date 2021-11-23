/**************************************************************************************
Description:    Test class to cover PartnerInfoReminderBatch functionality
History:
---------------------------------------------------------------------------------------
2015-08-04  Ritika Dhandia(Salesforce.com)  Created
2015-10-30  nandan.narasappa@auspost.com.au  updated custom setting value for
            testBatchSecondReminder method
2016-16-01  Andrew Judd (Salesforce.com)  Added setting of Network.Org_Unit_Type__c and
            Facility.Licence_Type__c to LPO for filter
2018-06-28  TDO-98 : rahul.kapoor@coroma.com.au  Refactored comments and indentation,
            added assertEquals and assertNotEquals, added create test data setup method
            and created records in bulk for testing.
***************************************************************************************/
@isTest 
private class PartnerInfoReminderBatch_Test{
    /*********************************************************************************
   *  Scenario:
   *      Setup method to create test data.
   **********************************************************************************/
    @testSetup
    static void createTestData(){

        //Create a parent Network record.
        Network__c parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId());
        insert parentNetwork;

        //Create a Network record.
        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO');
        insert network;
        
        //Create Licence record.
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');

        //Create parent account.
        Account parentAccount = new Account(
                name = 'Test0',
                phone = '123',
                RecordTypeId = organizationRecType.id
        );

        insert parentAccount;

        //Create a Account.
        Account facilityAcc1 = new Account( name='test1',
                                            phone='123', 
                                            recordtypeid=facitlityRecType.id,
                                            Network_Facility__c = network.id,
                                            Licence_Type__c = 'LPO',
                                            Subjected_To_GST__c = false  );
        insert facilityAcc1;
                
        //Add a licence to this facility.
        Account licenceAcc1 = new Account(  name='test12',
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Licence_Status__c= 'Approved',
                                            Assignment_Effective_From_Date__c = Date.today().addMonths(1));
        insert licenceAcc1;

        //Add a licence to this facility.
        Account licenceAcc2 = new Account(  name='test22',
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Licence_Status__c= 'Approved',
                                            Assignment_Effective_From_Date__c = Date.today().addDays(2)
                                            );
        insert licenceAcc2;
    


        Date licence1Anniversary = Date.today().addMonths(1).addYears(1).addMonths(1).toStartOfMonth().addDays(-1);
        Date licence2Anniversary = Date.today().addDays(2).addYears(1).addMonths(1).toStartOfMonth().addDays(-1);

        //Add Partner Addendum Records.
        RecordType negPaymentRecType = RecordTypes.getRecordTypeByName('Negotiated Payment Type F1', 'Partner_Addendum__c');

        //List to hold the PPartner Addendum to insert.
        list<Partner_Addendum__c> testPAList = new list<Partner_Addendum__c>();
        //Create Partner_Addendum__c in bulk.
        for(Integer j=1;j<=20;j++) {
            Partner_Addendum__c addendum1 = new Partner_Addendum__c(
                    Licence__c = licenceAcc1.Id,
                    RecordTypeId = negPaymentRecType.Id,
                    End_Date__c = licence1Anniversary
            );
            testPAList.add(addendum1);
        }
        insert testPAList;

        //List to hold the Partner Addendum to insert.
        list<Partner_Addendum__c> testPAList2 = new list<Partner_Addendum__c>();
        //Create Partner_Addendum__c in bulk.
        for(Integer j=1;j<=20;j++) {
            Partner_Addendum__c addendum2 = new Partner_Addendum__c(
                    Licence__c = licenceAcc2.Id,
                    RecordTypeId = negPaymentRecType.Id,
                    End_Date__c = licence2Anniversary
            );
            testPAList2.add(addendum2);
        }
        insert testPAList2;

    }

    /**********************************************************************
     *  Scenario:
     *      Checking the case created message when cases are mass uploaded.
     **********************************************************************/
    private static testMethod void testBatchFirstReminder(){
        //Insert Partner Info Custom Setting
        Partner_Info_Settings__c setting = new Partner_Info_Settings__c(
                Email_List_2__c = 'test@test.com',
                Email_List_3__c = 'test@test.com',
                First_Reminder_Days__c = 430,
                Second_Reminder_Days__c = 50,
                Third_Reminder_Days__c = 0
        );
        insert setting;
        
        //Now run batch, the partner addendum should fall into one of the reminder brackets
        Test.startTest();
            
            PartnerInfoReminderBatch batch = new PartnerInfoReminderBatch();
            Database.executeBatch(batch);
            
        Test.stopTest();

        Account testAccount = [SELECT Id,Name FROM Account WHERE Name = 'Test12' LIMIT 1];

        Partner_Addendum__c addendum1 = [SELECT Renewal_Status__c, Licence__r.Approval_Status__c, Licence__r.Email__c
                                         FROM Partner_Addendum__c
                                         WHERE Licence__c=: testAccount.id LIMIT 1];
        
        system.assertEquals(PartnerInfoReminderBatch.STATUS_FIRST_REMINDER_SENT, addendum1.Renewal_Status__c,
                'PartnerInfoReminderBatch_Test_testBatchFirstReminder : First Reminder should be Sent.');

        system.assertEquals(PartnerInfoReminderBatch.STATUS_FIRST_REMINDER_SENT, addendum1.Licence__r.Approval_Status__c,
                'PartnerInfoReminderBatch_Test_testBatchFirstReminder : First Reminder should be Sent.');

        system.assertEquals('test@test.com', addendum1.Licence__r.Email__c,
                'PartnerInfoReminderBatch_Test_testBatchFirstReminder : Email list should be retrieved.');
        
    }

    /**********************************************************************
     *  Scenario:
     *      Checking the case created message when cases are mass uploaded.
     **********************************************************************/
    private static testMethod void testBatchSecondReminder(){
        //Insert Partner Info Custom Setting
        Partner_Info_Settings__c setting = new Partner_Info_Settings__c(
                Email_List_2__c = 'test@test.com',
                Email_List_3__c = 'test@test.com',
                First_Reminder_Days__c = 500,  // changed from 430 to 500
                Second_Reminder_Days__c = 436, // changed from 396 to 43
                Third_Reminder_Days__c = 0
        );
        insert setting;
        
        //Now run batch, the partner addendum should fall into one of the reminder brackets
        Test.startTest();
            
            PartnerInfoReminderBatch batch = new PartnerInfoReminderBatch();
            Database.executeBatch(batch);
            
        Test.stopTest();

        Account testAccount = [SELECT Id,Name FROM Account WHERE Name = 'Test22' LIMIT 1];

        Partner_Addendum__c addendum2 = [SELECT Renewal_Status__c, Licence__r.Approval_Status__c, Licence__r.Email__c, Licence__r.Licence_Anniversary__c
                                         FROM Partner_Addendum__c
                                         WHERE Licence__c=: testAccount.id LIMIT 1];
                    
        system.assertEquals('test@test.com', addendum2.Licence__r.Email__c,
                'PartnerInfoReminderBatch_Test_testBatchSecondReminder : Email list should be retrieved.');

        if(Date.today() != addendum2.Licence__r.Licence_Anniversary__c){
            system.assertEquals(PartnerInfoReminderBatch.STATUS_SECOND_REMINDER_SENT, addendum2.Renewal_Status__c,
                    'PartnerInfoReminderBatch_Test_testBatchSecondReminder : Second Reminder should be Sent.');

            system.assertEquals(PartnerInfoReminderBatch.STATUS_SECOND_REMINDER_SENT, addendum2.Licence__r.Approval_Status__c,
                    'PartnerInfoReminderBatch_Test_testBatchSecondReminder : Second Reminder should be Sent.');
        }
        else{
            system.assertEquals(PartnerInfoReminderBatch.STATUS_FINAL_REMINDER_SENT, addendum2.Renewal_Status__c,
                    'PartnerInfoReminderBatch_Test_testBatchSecondReminder :Final Reminder should be Sent.');

            system.assertEquals(PartnerInfoReminderBatch.STATUS_FINAL_REMINDER_SENT, addendum2.Licence__r.Approval_Status__c,
                    'PartnerInfoReminderBatch_Test_testBatchSecondReminder : Final Reminder should be Sent.');
        }
        
    }

    /**********************************************************************
     *  Scenario:
     *      Checking the case created message when cases are mass uploaded.
     **********************************************************************/
    private static testMethod void testSchedulerCall(){
        //Insert Partner Info Custom Setting
        Partner_Info_Settings__c setting = new Partner_Info_Settings__c(
                Email_List_2__c = 'test@test.com',
                Email_List_3__c = 'test@test.com',
                First_Reminder_Days__c = 63,
                Second_Reminder_Days__c = 25,
                Third_Reminder_Days__c = 7
        );
        insert setting;

        string cronExpression = '0 0 0 3 9 ? 2022';
        
        Test.startTest();
            
            PartnerInfoReminderSchedule scheduler = new PartnerInfoReminderSchedule();
            system.schedule('Partner Info Reminder', cronExpression, scheduler);              
            
        Test.stopTest();

    }
    
}