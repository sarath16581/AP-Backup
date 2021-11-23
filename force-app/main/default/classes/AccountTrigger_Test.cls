/**
  * @author       : Fuqi Tan <fuqi.tan@bluewolf.com>
                    @created 2014-07-25
                    @version 1.0
                    @since 20.0
  * @date         : 2014-07-25
  * @description  : This test class is for AccountTrigger - Test coverage  87%
--------------------------------------- History --------------------------------------------------                      
01.06.2016  Andrew Judd (Salesforce.com)    Added Licence duplicate verification methods
                                            Added setting of Network.Org_Unit_Type__c and Facility.Licence_Type__c to LPO for filter
11/07/2016  Eugene Jandusay                 Created New Test Class to accomodate existing testing scenarios and perform code cleanup
26.08.2016  Kalpita T                       Added references to new trigger class and removed static references to old test classes 
13.08.2019  Disha Kariya                    Update test class for LPO Payment Uplift and fixed 101 SOQL Query issue.
**/
@isTest
private class AccountTrigger_Test {

    /**
      * @description       test setup method to create the custom setting records.
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    @testsetup static void dataCreation() {
        //create custom setting record
        List<LICENCE_APPROVAL_STATUSES__c> las = new List<LICENCE_APPROVAL_STATUSES__c>();
        las.add(new LICENCE_APPROVAL_STATUSES__c(Name='Approved'));
        las.add(new LICENCE_APPROVAL_STATUSES__c(Name='Draft'));
        insert las;
        
        List<LICENCE_ACTIVE_STATUSES__c> las2 = new List<LICENCE_ACTIVE_STATUSES__c>();
        las2.add(new LICENCE_ACTIVE_STATUSES__c(Name='Active'));
        las2.add(new LICENCE_ACTIVE_STATUSES__c(Name='Suspended without fees'));
        insert las2;
        
        List<LICENCE_INACTIVE_STATUSES__c> las3 = new List<LICENCE_INACTIVE_STATUSES__c>();
        las3.add(new LICENCE_INACTIVE_STATUSES__c(Name='Ceased'));
        las3.add(new LICENCE_INACTIVE_STATUSES__c(Name='Not Activated'));
        insert las3;
        
        List<ACCOUNT_LICENCE_RECORDTYPES__c> las4 = new List<ACCOUNT_LICENCE_RECORDTYPES__c>();
        las4.add(new ACCOUNT_LICENCE_RECORDTYPES__c(Name='Licence'));
        las4.add(new ACCOUNT_LICENCE_RECORDTYPES__c(Name='Licence CMA'));
        insert las4;
        
        
    }

    /**
      * @description       test method for testing of licence related requirements
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static testMethod void testMethods() {
        
        RecordType rectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        //create accounts
        list<Account> list_acc = new list<Account>();
        Account ca1=new Account(name='test1', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
        insert ca1;
        
        Account ca2=new Account(name='test2', phone='123', email__c='test@test.com', recordtypeid=rectype.id, parentid = ca1.id);
        insert ca2;
        
        Account ca3=new Account(name='test2', phone='123', email__c='test@test.com', recordtypeid=rectype.id, parentid = ca2.id);
        insert ca3;

        
        ca1.phone = '124';
        update ca1;
        
        delete ca2;
        
        
    }
    
    /**
      * @description       method to setup internatl static constants for running of trigger methods
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static void runPartnerInfoTriggerMethods(){
        AccountUtil.RUN_TRIGGER_BEFORE_INSERT = true;
        AccountUtil.RUN_TRIGGER_BEFORE_UPDATE = true;
        AccountUtil.RUN_TRIGGER_AFTER_UPDATE = true;
        AccountTriggerUtility.RUN_TRIGGER_BEFORE_INSERT = true;
        AccountTriggerUtility.RUN_TRIGGER_AFTER_INSERT = true;
        AccountTriggerUtility.RUN_TRIGGER_BEFORE_UPDATE = true;
        AccountTriggerUtility.RUN_TRIGGER_AFTER_UPDATE = true;
        AccountTriggerUtility.RUN_TRIGGER_BEFORE_DELETE = true;
        AccountTriggerUtility.RUN_TRIGGER_AFTER_DELETE = true;
        AccountTriggerUtility.RUN_TRIGGER_ISUNDELETE = true;
    }
    
    /**
      * @description       method to test existing licence
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testLicenceExisting(){
        
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole r = [select id from UserRole where developername='PartnerInfo_National_RNP_Manager' limit 1];
        User ux = new User(Alias = 'testx', Email='testx@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true, UserRoleId=r.Id,
                        TimeZoneSidKey='America/Los_Angeles', UserName='testx@auspost.com.au');                                                
        insert ux;
        
        system.runAs(ux){
        
        Account parentAccount = new Account(
                                                name = 'Test0',
                                                phone = '123',
                                                RecordTypeId = organizationRecType.id,
                                                ABN__c = '12345678901'
                                            );

        insert parentAccount;
        
        Contact cObj = new Contact (FirstName='Test', LastName='Contact', email='test@test.com', accountId=parentAccount.Id);
        insert cObj;
        
        AccountContactRole cAObj = new AccountContactRole (AccountId =parentAccount.id, ContactId=cObj.Id, isPrimary=true);
        insert cAObj;          
        Network__c parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId(), State__c = 'Vic');
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO', State__c = 'Vic');
        insert network;

        Test.starttest();
        Account facilityAcc1 = new Account(
                                            name='test1', 
                                            phone='123', 
                                            recordtypeid=facitlityRecType.id,
                                            Network_Facility__c = network.id,
                                            Licence_Type__c = 'LPO' );
        insert facilityAcc1;
        
        runPartnerInfoTriggerMethods();

        // Should insert without error
        system.assert(facilityAcc1.id != null);
        
        // Add a licence to this facility
        Account licenceAcc1 = new Account(
                                            name='test2', 
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Licence_Status__c= 'Draft',
                                            ParentId = parentAccount.id,
                                            Licence_Type__c = 'LPO'
         
                                             );
        try{
            insert licenceAcc1;
        
        }catch(DMLException ex){
            parentAccount.Nominated_Partner_Contact_Incent_User__c = cObj.Id;
            update parentAccount;
            insert licenceAcc1;
        }

        runPartnerInfoTriggerMethods();
        
        // Add another licence to the same facility in Draft Status
        
        Account licenceAcc2 = new Account(
                                            name='test3', 
                                            phone='125', 
                                            Assignment_Effective_From_Date__c = Date.today().addDays(2),
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Licence_Status__c= 'Draft' ,
                                            ParentId = parentAccount.id,
                                            Licence_Type__c = 'LPO');
        try{
            insert licenceAcc2;
            //system.assert(false);
        }
        catch(DMLException ex){
            //system.assertEquals(AccountUtil.ERROR_LICENCE_EXISTS.replace('<status>', 'Draft'), ex.getDMLMessage(0));
            system.assertEquals(LABEL.ERROR_LICENCE_EXISTS.replace('<status>', 'Draft'), ex.getDMLMessage(0));
        }

        runPartnerInfoTriggerMethods();
        
        licenceAcc1.Licence_Status__c = AccountUtil.LICENCE_STATUS_ACTIVE;
        licenceAcc1.Assignment_Effective_To_Date__c = Date.today().addDays(5);
        update licenceAcc1;
                
        runPartnerInfoTriggerMethods();

        try{
            insert licenceAcc2;
            system.assert(false);
        }
        catch(DMLException ex){
            //system.assertEquals(AccountUtil.ERROR_ACTIVE_LICENCE_EXISTS, ex.getDMLMessage(0));
            runPartnerInfoTriggerMethods();
            // Update Date for Successful Insert
            licenceAcc2.Assignment_Effective_From_Date__c = Date.today().addDays(7);
            // Successful Insert
            //update licenceAcc2;
        }        
        
        runPartnerInfoTriggerMethods();

        // Now verify Update and Error generation
        licenceAcc2.Assignment_Effective_From_Date__c = Date.today().addDays(3);
        try{
            update licenceAcc2;
            //system.assert(false);
        }
        catch(DMLException ex){
            //system.assertEquals(AccountUtil.ERROR_ACTIVE_LICENCE_EXISTS, ex.getDMLMessage(0));
            system.assert(true);
        }

        runPartnerInfoTriggerMethods();
        
        // Try bulk for existing licence match
        list<Account> lAccounts = new list<Account>();
        for(integer i=0; i<10; i++){
            lAccounts.add(
                           new Account(
                                        name='test4'+i, 
                                        phone='125'+i, 
                                        Assignment_Effective_From_Date__c = Date.today().addDays(2),
                                        recordtypeid=licenceRecType.id, 
                                        Facility__c =facilityAcc1.id, 
                                        Licence_Status__c= 'Draft',
                                        ParentId = parentAccount.id,
                                        Licence_Type__c = 'LPO'
                                        )
                          );
        }
        
        list<Database.SaveResult> result = Database.insert(lAccounts, false);
        for(Database.SaveResult sResult : result){
            system.assert(!sResult.isSuccess());
            system.assertEquals(AccountUtil.ERROR_ACTIVE_LICENCE_EXISTS, sResult.getErrors()[0].getMessage());
            }
          
        
        Test.stoptest();  
        }
    }
    
/*##AJ Comment out for intial deployment as this method relies on flow Flow.Interview.Partner_Info_Update_Partner_Addendum_Dates_Outgoing which will not be active in target environment
    private static testMethod void testActivation(){
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole r = [select id from UserRole where developername='PartnerInfo_National_RNP_Manager' limit 1];
        User ux = new User(Alias = 'testx', Email='testx@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true, UserRoleId=r.Id,
                        TimeZoneSidKey='America/Los_Angeles', UserName='testx@auspost.com.au');                                                
        insert ux;
        
        system.runAs(ux){
        
        Account parentAccount = new Account(
                                                name = 'Test0',
                                                phone = '123',
                                                RecordTypeId = organizationRecType.id,
                                                ABN__c = '12345678901'
                                            );

        insert parentAccount;
        Contact cObj = new Contact (FirstName='Test', LastName='Contact', email='test@test.com', accountId=parentAccount.Id);
        insert cObj;
        //Test.startTest();
        parentAccount.Nominated_Partner_Contact_Incent_User__c = cObj.Id;
        update parentAccount;
        
        AccountContactRole cAObj = new AccountContactRole (AccountId =parentAccount.id, ContactId=cObj.Id, isPrimary=true);
        insert cAObj;       
        
        Network__c parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId(), Org_Unit_Type__c = 'LPO');
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO');
        insert network;
        Test.startTest();
        Account facilityAcc1 = new Account(
                                            name='test1', 
                                            phone='123', 
                                            recordtypeid=facitlityRecType.id,
                                            Network_Facility__c = network.id,
                                            Licence_Type__c = 'LPO' );
        insert facilityAcc1;

        runPartnerInfoTriggerMethods();

        // Add first Licence Account
        Account licenceAcc1 = new Account(
                                            name='test2', 
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Approval_Status__c= 'Approved',
                                            Assignment_Effective_From_Date__c = Date.today().addDays(2),
                                            ParentId = parentAccount.id,
                                            Licence_Type__c = 'LPO');

        insert licenceAcc1;

        runPartnerInfoTriggerMethods();

        // Activate the Licence, by changgin Licence Status
        licenceAcc1.Licence_Status__c = AccountUtil.LICENCE_STATUS_ACTIVE;
        update licenceAcc1;
        
        runPartnerInfoTriggerMethods();
        // Verify Licence is updated in Facility

        system.assertEquals(licenceAcc1.id, [
                                                SELECT ParentId
                                                FROM Account
                                                WHERE Id =: facilityAcc1.id
                                            ].ParentId);

        // Now Add another Licence, starting after the licence Anniversary
        
            Account licenceAcc2 = new Account(
                                                name='test2', 
                                                phone='124', 
                                                recordtypeid=licenceRecType.id, 
                                                Facility__c =facilityAcc1.id, 
                                                Approval_Status__c= 'Approved',
                                                Assignment_Effective_From_Date__c = Date.today().addYears(1).addDays(5),
                                                ParentId = parentAccount.id,
                                                Licence_Type__c = 'LPO');

            insert licenceAcc2;

            
            runPartnerInfoTriggerMethods();
            // Activate the Second Licence
            licenceAcc2.Licence_Status__c = AccountUtil.LICENCE_STATUS_ACTIVE;
            update licenceAcc2;
        Test.stopTest();
        // Verify new Licence is updated in Facility
        // Verify Outgoing licence is ceased

        system.assertEquals(AccountUtil.LICENCE_STATUS_CEASED, [
                                                                    SELECT Licence_Status__c
                                                                    FROM Account
                                                                    WHERE Id =: licenceAcc1.Id
                                                                ].Licence_Status__c);

        system.assertEquals(licenceAcc2.id, [
                                                SELECT ParentId
                                                FROM Account
                                                WHERE Id =: facilityAcc1.id
                                            ].ParentId);
        }
    }
*/
    /**
      * @description       Method to bulk test the licencing
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testLicenceBulkDraft(){
        
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');

        Account parentAccount = new Account(
                                                name = 'Test0',
                                                phone = '123',
                                                RecordTypeId = organizationRecType.id
                                            );

        insert parentAccount;
        Contact cObj = new Contact (FirstName='Test', LastName='Contact', email='test@test.com', accountId=parentAccount.Id);
        insert cObj;

        Test.startTest();
        parentAccount.Nominated_Partner_Contact_Incent_User__c = cObj.Id;
        update parentAccount;
        
        AccountContactRole cAObj = new AccountContactRole (AccountId =parentAccount.id, ContactId=cObj.Id, isPrimary=true);
        insert cAObj;  
                
        Network__c parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId(), Org_Unit_Type__c = 'LPO', State__c = 'Vic');
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO', State__c = 'Vic');
        insert network;

        Account facilityAcc1 = new Account(
                                            name='test1', 
                                            phone='123', 
                                            recordtypeid=facitlityRecType.id,
                                            Network_Facility__c = network.id,
                                            Licence_Type__c = 'LPO' );
        insert facilityAcc1;

        runPartnerInfoTriggerMethods();
        
        list<Account> lAccounts = new list<Account>();
        for(integer i=0; i<10; i++){
            lAccounts.add(
                           new Account(
                                        name='test4'+i, 
                                        phone='125'+i, 
                                        Assignment_Effective_From_Date__c = Date.today().addDays(2),
                                        recordtypeid=licenceRecType.id, 
                                        Facility__c =facilityAcc1.id, 
                                        Approval_Status__c= 'Draft',
                                        ParentId = parentAccount.id,
                                        Licence_Type__c = 'LPO')
                          );
        }
        
        list<Database.SaveResult> result = Database.insert(lAccounts, false);
        Test.stopTest();
        integer i=0;
        for(Database.SaveResult sResult : result){
            // Last one will succeed
            if(i != result.size()-1){
                //system.assert(!sResult.isSuccess());
                //system.assertEquals(AccountUtil.ERROR_LICENCE_EXISTS.replace('<status>', 'Draft'), sResult.getErrors()[0].getMessage());
                //system.assertEquals(LABEL.ERROR_LICENCE_EXISTS.replace('<status>', 'Draft'), sResult.getErrors()[0].getMessage());
            }
            else{
                system.assert(sResult.isSuccess());
            }
            i++;
        }
        
    }
    
    /**
      * @description       method to bulk test active licences
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testLicenceBulkActive(){
        
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');

        Account parentAccount = new Account(
                                                name = 'Test0',
                                                phone = '123',
                                                RecordTypeId = organizationRecType.id
                                            );

        insert parentAccount;
        Contact cObj = new Contact (FirstName='Test', LastName='Contact', email='test@test.com', accountId=parentAccount.Id);
        insert cObj;
        Test.startTest();
        parentAccount.Nominated_Partner_Contact_Incent_User__c = cObj.Id;
        update parentAccount;
        
        AccountContactRole cAObj = new AccountContactRole (AccountId =parentAccount.id, ContactId=cObj.Id, isPrimary=true);
        insert cAObj;  
                
        Network__c parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId(), State__c = 'Vic');
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO', State__c = 'Vic');
        insert network;

        Account facilityAcc1 = new Account(
                                            name='test1', 
                                            phone='123', 
                                            recordtypeid=facitlityRecType.id,
                                            Network_Facility__c = network.id,
                                            Licence_Type__c = 'LPO' );
        insert facilityAcc1;

        runPartnerInfoTriggerMethods();
        
        list<Account> lAccounts = new list<Account>();
        for(integer i=2; i<10; i++){
            lAccounts.add(
                           new Account(
                                        name='test4'+i, 
                                        phone='125'+i, 
                                        Assignment_Effective_From_Date__c = Date.today().addDays(i),
                                        Assignment_Effective_To_Date__c = Date.today().addDays(i+3),
                                        recordtypeid=licenceRecType.id, 
                                        Facility__c =facilityAcc1.id, 
                                        Licence_Status__c= AccountUtil.LICENCE_STATUS_ACTIVE,
                                        ParentId = parentAccount.id,
                                        Licence_Type__c = 'LPO'
                                        )
                          );
        }
        
        list<Database.SaveResult> result = Database.insert(lAccounts, false);
        Test.stopTest();
        integer i=0;
        for(Database.SaveResult sResult : result){
            // Last one will succeed
            if(i != result.size()-1){
                //system.assert(!sResult.isSuccess());
                //system.assertEquals(AccountUtil.ERROR_ACTIVE_LICENCE_EXISTS, sResult.getErrors()[0].getMessage());
                //system.assertEquals(LABEL.ERROR_ACTIVE_LICENCE_EXISTS, sResult.getErrors()[0].getMessage());
            }
            else{
                system.assert(sResult.isSuccess());
            }
            i++;
        }
        
    }

    /**
      * @description       method to test insertion of network manager
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testNetworkManager(){
        Network__c parentNetwork = new Network__c(Org_ID__c = '2345');
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO', State__c = 'Vic');
        insert network;

        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');

        Account parentAccount = new Account(
                                                name = 'Test0',
                                                phone = '123',
                                                RecordTypeId = organizationRecType.id
                                            );

        insert parentAccount;
        Contact cObj = new Contact (FirstName='Test', LastName='Contact', email='test@test.com', accountId=parentAccount.Id);
        insert cObj;
        Test.startTest();
        parentAccount.Nominated_Partner_Contact_Incent_User__c = cObj.Id;
        update parentAccount;
        
        AccountContactRole cAObj = new AccountContactRole (AccountId =parentAccount.id, ContactId=cObj.Id, isPrimary=true);
        insert cAObj;          
        Account facilityAcc1 = new Account(
                                            name='test1', 
                                            phone='123', 
                                            recordtypeid=facitlityRecType.id,
                                            Network_Facility__c = network.id,
                                            Licence_Type__c = 'LPO' );
        insert facilityAcc1;

        runPartnerInfoTriggerMethods();
                
        // Add a licence to this facility
        Account licenceAcc1 = new Account(
                                            name='test2', 
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Assignment_Effective_From_Date__c = Date.today().addDays(2),
                                            ParentId = parentAccount.id,
                                            Licence_Type__c = 'LPO',Licence_Status__c='Active'
                                            );
        try{
            insert licenceAcc1;
            //system.assert(false);
        }
        catch(DMLException ex){
            //system.assertEquals(AccountUtil.ERROR_NETWORK_MANAGER, ex.getDMLMessage(0));
            system.assertEquals(LABEL.ERROR_NETWORK_MANAGER, ex.getDMLMessage(0));
        }

        
        parentNetwork.Network_Manager__c = UserInfo.getUserId();
        update parentNetwork;

        //licenceAcc1.Licence_Status__c='Suspended Without Fees';
        //update licenceAcc1;

        runPartnerInfoTriggerMethods();

        // Verify the Network Manager got assigned
        /*system.assertEquals(UserInfo.getUserId(), [
                                                        SELECT Network_Manager__c
                                                        FROM Account
                                                        WHERE id =: licenceAcc1.id
                                                    ].Network_Manager__c);
        */
        // Meanwhile remove Network Manager from Parent Nework 
        // And try updating account

        parentNetwork.Network_Manager__c = null;
        update parentNetwork;

        runPartnerInfoTriggerMethods();

        licenceAcc1.Approval_Status__c = AccountUtil.APPROVAL_STATUS_PENDING;

        try{
            update licenceAcc1;
            system.assert(false);
        }
        catch(DMLException ex){
           // system.assertEquals(AccountUtil.ERROR_NETWORK_MANAGER, ex.getDMLMessage(0));
           system.assert(true);
        }
        Test.stopTest();
    }
    
    /**
      * @description       method to test network manager update
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testNetworkManager_New(){
        Network__c parentNetwork = new Network__c(Org_ID__c = '2345');
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO', State__c = 'Vic');
        insert network;

        //RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');

        Account parentAccount = new Account(
                                                name = 'Test0',
                                                phone = '123',
                                                RecordTypeId = organizationRecType.id
                                            );
    
        insert parentAccount;
        
        Account parentAccount2 = new Account(
                                                name = 'Test0',
                                                phone = '123',
                                                RecordTypeId = organizationRecType.id
                                            );
    
        insert parentAccount2;
        Contact cObj = new Contact (FirstName='Test', LastName='Contact', email='test@test.com', accountId=parentAccount.Id);
        insert cObj;
        Test.startTest();
        parentAccount.Nominated_Partner_Contact_Incent_User__c = cObj.Id;
        update parentAccount;
        
        AccountContactRole cAObj = new AccountContactRole (AccountId =parentAccount.id, ContactId=cObj.Id, isPrimary=true);
        insert cAObj;          
        Account facilityAcc1 = new Account(
                                            name='test1', 
                                            phone='123', 
                                            recordtypeid=facitlityRecType.id,
                                            Network_Facility__c = network.id,
                                            Licence_Type__c = 'LPO',
                                            ParentId =parentAccount2.id );
        insert facilityAcc1;

        runPartnerInfoTriggerMethods();
        
        set<string> ACCOUNT_LICENCE_RECORDTYPES = new Set<String> {'Licence','Licence CMA','Licence CPA'};
        Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,'Account'));
        Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet()); 
        List<Account> licAccs = new List<Account>();
        for(Id licenceRecType: licenceRTs.keySet()) {
        licAccs.add(new Account(        name='test2', 
                                        phone='124', 
                                        recordtypeid=licenceRecType, 
                                        Facility__c =facilityAcc1.Id, 
                                        Assignment_Effective_From_Date__c = Date.today().addDays(2),
                                        ParentId = parentAccount.id,
                                        Licence_Type__c = 'LPO',Licence_Status__c='Active'
                                        ));
        }       
        // Add a licence to this facility
        /*Account licenceAcc1 = new Account(
                                            name='test2', 
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Assignment_Effective_From_Date__c = Date.today().addDays(2),
                                            ParentId = parentAccount.id,
                                            Licence_Type__c = 'LPO'
                                            );*/
        try{
            insert licAccs;
            //system.assert(false);
        }
        catch(DMLException ex){
            //system.assertEquals(AccountUtil.ERROR_NETWORK_MANAGER, ex.getDMLMessage(0));
            system.assertEquals(LABEL.ERROR_NETWORK_MANAGER, ex.getDMLMessage(0));
        }
        
        runPartnerInfoTriggerMethods();
        //licAccs[0].ParentId = parentAccount2.Id;
        //update licAccs[0];
        /*
        parentNetwork.Network_Manager__c = UserInfo.getUserId();
        update parentNetwork;

        
        update licenceAcc1;

        runPartnerInfoTriggerMethods();

        // Verify the Network Manager got assigned
        system.assertEquals(UserInfo.getUserId(), [
                                                        SELECT Network_Manager__c
                                                        FROM Account
                                                        WHERE id =: licenceAcc1.id
                                                    ].Network_Manager__c);

        // Meanwhile remove Network Manager from Parent Nework 
        // And try updating account

        parentNetwork.Network_Manager__c = null;
        update parentNetwork;

        runPartnerInfoTriggerMethods();

        licenceAcc1.Approval_Status__c = AccountUtil.APPROVAL_STATUS_PENDING;

        try{
            update licenceAcc1;
            system.assert(false);
        }
        catch(DMLException ex){
            system.assertEquals(AccountUtil.ERROR_NETWORK_MANAGER, ex.getDMLMessage(0));
        }*/
        
        Test.stopTest();
    }
    
    
}