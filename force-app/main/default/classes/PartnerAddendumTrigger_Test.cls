/**************************************************
Type:       Test Class for Partner Addendum Trigger and Util
Purpose:    
Used By:    
History:
--------------------------------------------------
04.08.2015  Ritika Dhandia(Salesforce.com)      Created
01.16.2016  Andrew Judd (Salesforce.com)        Added setting of Network.Org_Unit_Type__c and Facility.Licence_Type__c to LPO for filter
**************************************************/
@isTest 
private class PartnerAddendumTrigger_Test{
    private static Network__c parentNetwork;
    private static Account licenceAcc1;
    private static Account facilityAcc1;
    @testSetup
    private static void setup(){
        // Insert Partner Info Custom Setting
        Partner_Info_Settings__c setting = new Partner_Info_Settings__c(
                Email_List_Vic__c = 'test@test.com',
                Email_List_NSW__c = 'test@test.com',
                First_Reminder_Days__c = 63,
                Second_Reminder_Days__c = 25,
                Third_Reminder_Days__c = 7,
                Level_3_Approval_Amount__c = 10000
        );

        insert setting;

        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');

        Account parentAccount = new Account(
                name = 'Test0',
                phone = '123',
                RecordTypeId = organizationRecType.id
        );

        insert parentAccount;

        parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId(), State__c='Vic');
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO');
        insert network;

        facilityAcc1 = new Account(
                                            name='test1', 
                                            phone='123', 
                                            recordtypeid=facitlityRecType.id,
                                            Is_a_facility__c = true,
                                            Network_Facility__c = network.id,
                                            Licence_Type__c = 'LPO',
                                            Subjected_To_GST__c = false   );
        insert facilityAcc1;
        
        // Add a licence to this facility
        licenceAcc1 = new Account(
                                            name='test2', 
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Licence_Status__c= 'Draft',
                                            ParentId = parentAccount.id );
        insert licenceAcc1;
    }

    private static testMethod void testPartnerAddedndumExisting(){
        
//        setup();
        Account facilityAcc1 = [SELECT id from Account where RecordType.name='Facility' limit 1];

        RecordType insuranceRT = RecordTypes.getRecordTypeByName('Insurance', 'Partner_Addendum__c');
        
        Partner_Addendum__c addendum1 = new Partner_Addendum__c(
                                                                    Facility__c = facilityAcc1.id,
                                                                    Status__c = 'Ceased',
                                                                    Sub_Type__c = 'Ad-hoc',
                                                                    Start_Date__c = Date.today().addDays(2),
                                                                    End_Date__c = Date.today().addDays(4),
                                                                    RecordTypeId = insuranceRT.Id
                                                                );
        
        insert addendum1;
        
        // Insert another similar Parnter Addendum Record, Same Facility
        Partner_Addendum__c addendum2 = new Partner_Addendum__c(
                                                                    Facility__c = facilityAcc1.id,
                                                                    Status__c = 'Draft',
                                                                    Sub_Type__c = 'Ad-hoc',
                                                                    Start_Date__c = Date.today().addDays(2),
                                                                    End_Date__c = Date.today().addDays(4),
                                                                    RecordTypeId = insuranceRT.Id
                                                                );
        
        // Now insert should be successful
        insert addendum2;
        
        // Test on Update, Update the First Addendum
        addendum1.Status__c = 'Draft';
        addendum1.Start_Date__c = Date.today().addDays(-5);
        addendum1.End_Date__c = Date.today().addDays(-3);
        try{
            update addendum1;
            system.assert(false);
        }
        catch(DMLException ex){
            system.assertEquals(PartnerAddendumUtil.ERROR_PARTNER_ADDENDUM, ex.getDMLMessage(0));
        }
        
        
    }
    
    private static testMethod void testExistingBulk(){
        
//        setup();
        
        RecordType insuranceRT = RecordTypes.getRecordTypeByName('Insurance', 'Partner_Addendum__c');
        Account licenceAcc1 = [SELECT id from Account where RecordType.name='Licence' limit 1];
        
        Partner_Addendum__c addendum1 = new Partner_Addendum__c(
                                                                    Licence__c = licenceAcc1.id,
                                                                    Status__c = 'Draft',
                                                                    Sub_Type__c = 'Ad-hoc',
                                                                    Start_Date__c = Date.today().addDays(2),
                                                                    End_Date__c = Date.today().addDays(200),
                                                                    RecordTypeId = insuranceRT.Id
                                                                );
        
        insert addendum1;
        
        list<Partner_Addendum__c> partnerAddendums = new list<Partner_Addendum__c>();
        for(integer i=0; i<100; i++){
            partnerAddendums.add(    
                                    new Partner_Addendum__c(
                                                                Licence__c = licenceAcc1.id,
                                                                Status__c = 'Draft',
                                                                Sub_Type__c = 'Ad-hoc',
                                                                Start_Date__c = Date.today().addDays(i),
                                                                End_Date__c = Date.today().addDays(i+4),
                                                                RecordTypeId = insuranceRT.Id
                                                            ));
        }
        
        list<Database.SaveResult> result = Database.insert(partnerAddendums, false);
        for(Database.SaveResult sResult : result){
            system.assert(!sResult.isSuccess());
            system.assertEquals(PartnerAddendumUtil.ERROR_PARTNER_ADDENDUM, sResult.getErrors()[0].getMessage());
        }
    }
    
    private static testMethod void testBulkSelf(){
        
//        setup();
        Account licenceAcc1 = [SELECT id from Account where RecordType.name='Licence' limit 1];
        RecordType insuranceRT = RecordTypes.getRecordTypeByName('Insurance', 'Partner_Addendum__c');
       
        list<Partner_Addendum__c> partnerAddendums = new list<Partner_Addendum__c>();
        for(integer i=0; i<5; i++){
            partnerAddendums.add(    
                                    new Partner_Addendum__c(
                                                                Licence__c = licenceAcc1.id,
                                                                Status__c = 'Draft',
                                                                Sub_Type__c = 'Ad-hoc',
                                                                Start_Date__c = Date.today().addDays(i),
                                                                End_Date__c = Date.today().addDays(i+4),
                                                                RecordTypeId = insuranceRT.Id
                                                            ));
        }
        
        list<Database.SaveResult> result = Database.insert(partnerAddendums, false);
        integer i=0;
        for(Database.SaveResult sResult : result){
            if(i != result.size()-1){
                system.assert(!sResult.isSuccess());
                system.assertEquals(PartnerAddendumUtil.ERROR_PARTNER_ADDENDUM, sResult.getErrors()[0].getMessage());
            }
            else{
                system.assert(sResult.isSuccess());
            }
            i++;
        }
    }

    private static testMethod void testUpdateNetworkManager(){

//        setup();
        Account facilityAcc1 = [SELECT id from Account where RecordType.name='Facility' limit 1];
        Network__c parentNetwork = [SELECT id from Network__c WHERE State__c='Vic' limit 1];
        RecordType insuranceRT = RecordTypes.getRecordTypeByName('Insurance', 'Partner_Addendum__c');
        
        Partner_Addendum__c addendum1 = new Partner_Addendum__c(
                                                                    Facility__c = facilityAcc1.id,
                                                                    Status__c = 'Draft',
                                                                    Sub_Type__c = 'Ad-hoc',
                                                                    Start_Date__c = Date.today().addDays(2),
                                                                    End_Date__c = Date.today().addDays(4),
                                                                    RecordTypeId = insuranceRT.Id
                                                                );
        
        insert addendum1;

        // Verify the Network Manager got assigned
        system.assertEquals(UserInfo.getUserId(), [
                                                        SELECT id, Network_Manager__c
                                                        FROM Partner_Addendum__c
                                                        WHERE id =: addendum1.id
                                                  ].Network_Manager__c);                 

        // Meanwhile, remove the network manager from Parent Network and update the Addendum
        // Verify that the update will not be allowed

        parentNetwork.Network_Manager__c = null;
        update parentNetwork;

        addendum1.Approval_Status__c = 'Pending';

        try{
            update addendum1;
            system.assert(false);
        }
        catch(DmlException ex){
            system.assertEquals(PartnerAddendumUtil.ERROR_NETWORK_MANAGER, ex.getDMLMessage(0));
        }

    }

    private static testMethod void testUpdateMinApprovalLevel(){

//        setup();
        Account licenceAcc1 = [SELECT id from Account where RecordType.name='Licence' limit 1];

        // Test Amount
        RecordType insuranceRT = RecordTypes.getRecordTypeByName('Insurance', 'Partner_Addendum__c');
        Partner_Addendum__c addendum1 = new Partner_Addendum__c(
                                                                    Licence__c = licenceAcc1.id,
                                                                    Status__c = 'Draft',
                                                                    Sub_Type__c = 'Ad-hoc',
                                                                    Start_Date__c = Date.today().addDays(2),
                                                                    End_Date__c = Date.today().addDays(4),
                                                                    RecordTypeId = insuranceRT.Id,
                                                                    Amount__c = 12000
                                                                );
        
        insert addendum1;

        // Verify Licence Account Got Updated

        system.assertEquals(3, [
                                    SELECT Minimum_Approval_Level__c
                                    FROM Account
                                    WHERE id =: licenceAcc1.id
                                ].Minimum_Approval_Level__c);
    }
}