/**************************************************
Type:       Test Class for Partner Info Change Trigger and Util
Purpose:    
Used By:    
History:
--------------------------------------------------
06.08.2015  Ritika Dhandia(Salesforce.com)      Created
01.16.2016  Andrew Judd (Salesforce.com)        Added setting of Network.Org_Unit_Type__c and Facility.Licence_Type__c to LPO for filter
20.06.2016  Andrew Judd (Salesforce.com)        Updated testUpdateFacility as former field 'Equipment_Fee_Exemption_Reason_Code__c' has been removed from PICR
**************************************************/
@isTest 
private class PartnerInfoChangeTrigger_Test{
    
    private static Network__c parentNetwork;
    private static Account facilityAcc1;
    private static Account licenceAcc1;
    private static Account parentAccount;

    private static void setup(){
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');

        parentAccount = new Account(
                                                name = 'Test0',
                                                phone = '123',
                                                RecordTypeId = organizationRecType.id
                                            );

        insert parentAccount;

        parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId());
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
                                            Subjected_To_GST__c = false  );
        insert facilityAcc1;
        
        // Add a licence to this facility
        licenceAcc1 = new Account(
                                            name='test2', 
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Licence_Status__c= 'Active',
                                            ParentId = parentAccount.id );
        insert licenceAcc1;
    }

    private static testMethod void testDuplicate(){
        
        setup();
        
        // Insert new Partner Info Change record
        Partner_Info_Change__c change1 = new Partner_Info_Change__c(
                                                                       Facility__c = facilityAcc1.id,
                                                                       Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_PENDING
                                                                    );
        // Should insert without error
        insert change1;
        
        // Add another Change to same Facility
        Partner_Info_Change__c change2 = new Partner_Info_Change__c(
                                                                       Facility__c = facilityAcc1.id,
                                                                       Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_PENDING
                                                                    );
        try{
            insert change2;
        }
        catch(DMLException ex){
            system.assertEquals(PartnerInfoChangeUtil.ERROR_CHANGE_EXISTS, ex.getDMLMessage(0));
        }
        
        // Verify same for Licence Accounts
        
        // Insert new Partner Info Change record
        Partner_Info_Change__c change3 = new Partner_Info_Change__c(
                                                                       Licence__c = licenceAcc1.id,
                                                                       Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_PENDING
                                                                    );
        // Should insert without error
        insert change3;
        
        // Add another Change to same Licence
        Partner_Info_Change__c change4 = new Partner_Info_Change__c(
                                                                       Licence__c = licenceAcc1.id,
                                                                       Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_PENDING
                                                                    );
        try{
            insert change4;
        }
        catch(DMLException ex){
            system.assertEquals(PartnerInfoChangeUtil.ERROR_CHANGE_EXISTS, ex.getDMLMessage(0));
        }
    }
    
    
    private static testMethod void testUpdateLicenceCease(){
        
        setup();
        
        // Insert new Partner Info Change record, Change the Interruption Dates
        Partner_Info_Change__c change1 = new Partner_Info_Change__c(
                                                                       Licence__c = licenceAcc1.id,
                                                                       Assignment_Effective_To_Date__c = Date.today().addDays(2),
                                                                       Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_PENDING,
                                                                       Termination_Reason__c = 'Termination Reason' 
                                                                    );
        // Should insert without error
        insert change1;
        
        Test.startTest();
            // Approve the Change
            change1.Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_APPROVED;
            update change1;
        
        Test.stopTest();

        Account licence = [
                            SELECT Assignment_Effective_To_Date__c, Approval_Status__c
                            FROM Account
                            WHERE id=: licenceAcc1.id
                        ];

        // Update should reflect on parent Licence Account
        system.assertEquals(Date.today().addDays(2), licence.Assignment_Effective_To_Date__c);
        system.assertEquals(PartnerInfoChangeUtil.APPROVAL_STATUS_CEASE_APPROVED, licence.Approval_Status__c);
        
    }
    
    private static testMethod void testUpdateLicenceSuspend(){
        
        setup();
        
        // Insert new Partner Info Change record, Change the Interruption Dates
        Partner_Info_Change__c change1 = new Partner_Info_Change__c(
                                                                       Licence__c = licenceAcc1.id,
                                                                       Interrupted_Start_Date__c = Date.today().addDays(2),
                                                                       Licence_Status__c = PartnerInfoChangeUtil.PI_STATUS_SUSPEND_NO_FEES ,
                                                                       Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_PENDING
                                                                    );
        // Should insert without error
        insert change1;
        
        Test.startTest();
            // Approve the Change
            change1.Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_APPROVED;
            update change1;
        
        Test.stopTest();

        Account licence = [
                            SELECT Interrupted_Start_Date__c, Approval_Status__c, Interrupted_End_Date__c
                            FROM Account
                            WHERE id=: licenceAcc1.id
                        ];

        // Update should reflect on parent Licence Account
        system.assertEquals(Date.today().addDays(2), licence.Interrupted_Start_Date__c);
        system.assertEquals(PartnerInfoChangeUtil.APPROVAL_STATUS_SUSPEND_NO_FEES, licence.Approval_Status__c);
        system.assertEquals(null, licence.Interrupted_End_Date__c);
        
    }
    
    private static testMethod void testUpdateLicenceResume(){
        
        setup();
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        licenceAcc1   =  new Account(
                        name='test3', 
                        phone='124', 
                        recordtypeid=licenceRecType.id, 
                        Facility__c =facilityAcc1.id, 
                        Licence_Status__c= 'Suspended',
                        ParentId = parentAccount.id );
         insert   licenceAcc1;             
                                            
        // Insert new Partner Info Change record, Change the Interruption Dates
        Partner_Info_Change__c change1 = new Partner_Info_Change__c(
                                                                       Licence__c = licenceAcc1.id,
                                                                       Interrupted_End_Date__c = Date.today().addDays(2),
                                                                       Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_PENDING
                                                                    );
        // Should insert without error
        insert change1;
        
        Test.startTest();
            // Approve the Change
            change1.Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_APPROVED;
            update change1;
        
        Test.stopTest();

        Account licence = [
                            SELECT Interrupted_End_Date__c, Approval_Status__c
                            FROM Account
                            WHERE id=: licenceAcc1.id
                        ];

        // Update should reflect on parent Licence Account
        system.assertEquals(Date.today().addDays(2), licence.Interrupted_End_Date__c);
        system.assertEquals(PartnerInfoChangeUtil.APPROVAL_STATUS_RESUME_APPROVED, licence.Approval_Status__c);
        
    }


    private static testMethod void testUpdateFacility(){
        setup();
        // Verify Change getting populated to Facitlity Account, Change the Total Eq Private Delivery Points
        Partner_Info_Change__c change2 = new Partner_Info_Change__c(
                                                                       Facility__c = facilityAcc1.id,
                                                                       Total_Eq_Private_Delivery_Points__c = 1,
                                                                       Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_PENDING
                                                                    );
        // Should insert without error
        insert change2;
        
        // Approve the Change
        change2.Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_APPROVED;
        update change2;
        
        // Update should reflect on parent Facility Account
        system.assertEquals(1,    [
                                        SELECT Total_Eq_Private_Delivery_Points__c
                                        FROM Account
                                        WHERE id=: facilityAcc1.id
                                    ]. Total_Eq_Private_Delivery_Points__c);        
    }

    private static testMethod void testUpdateNetworkManager(){

        setup();
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        licenceAcc1   =  new Account(
                        name='test3', 
                        phone='124', 
                        recordtypeid=licenceRecType.id, 
                        Facility__c =facilityAcc1.id, 
                        Licence_Status__c= 'Suspended',
                        ParentId = parentAccount.id );  
        insert licenceAcc1;                      
        Partner_Info_Change__c change1 = new Partner_Info_Change__c(
                                                                       Licence__c = licenceAcc1.id,
                                                                       Interrupted_End_Date__c = Date.today().addDays(4)
                                                                    );
        // Should insert without error
        insert change1;

        // Verify the Network Manager got assigned
        system.assertEquals(UserInfo.getUserId(), [
                                                        SELECT id, Network_Manager__c
                                                        FROM Partner_Info_Change__c
                                                        WHERE id =: change1.id
                                                  ].Network_Manager__c);                 

        // Meanwhile, remove the network manager from Parent Network and update the Change Record
        // Verify that the update will not be allowed

        parentNetwork.Network_Manager__c = null;
        update parentNetwork;

        change1.Approval_Status__c = PartnerInfoChangeUtil.APPROVAL_STATUS_PENDING;

        try{
            update change1;
            system.assert(false);
        }
        catch(DmlException ex){
            system.assertEquals(PartnerInfoChangeUtil.ERROR_NETWORK_MANAGER, ex.getDMLMessage(0));
        }
    }
    
    
}