/**
  * @author       : Fuqi Tan
  * @date         : 2014-07-25
  * @description  : This test class is for AccountTrigger - Test coverage  87%
--------------------------------------- History --------------------------------------------------                      
01.06.2016  Andrew Judd (Salesforce.com)    Added Licence duplicate verification methods
                                            Added setting of Network.Org_Unit_Type__c and Facility.Licence_Type__c to LPO for filter
11/07/2016  Eugene Jandusay                 Created New Test Class to accomodate existing testing scenarios and perform code cleanup
26.08.2016  Kalpita T                       Added references to new trigger class and removed static references to old test classes
14.08.2019  Disha Kariya                    Added 2 new methods for LPO changes in AccountTriggerUtility class
02.03.2021  Alvin Zhou                      Added test methods for the change for Account Team create, update and delete
24.01.2024  Swati Mogadala 		            Added a test method for delete/merge of account records-testdeleteRReconDelete()
**/
@isTest
private class AccountTriggerUtility_Test {
    private static RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
    private static RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
    private static RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');
    private static RecordType otherRecType = RecordTypes.getRecordTypeByName('Other', 'Network__c');
    //Setup Method
    @testsetup
    private  static void setup(){
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

        LICENCE_APPROVAL_STATUSES__c set1 = new LICENCE_APPROVAL_STATUSES__c(name = 'Approved');
        insert set1;
        LICENCE_ACTIVE_STATUSES__c set2 = new LICENCE_ACTIVE_STATUSES__c(name = 'Active');
        insert set2;
        LICENCE_INACTIVE_STATUSES__c set3 = new LICENCE_INACTIVE_STATUSES__c(name = 'Cease');
        insert set3;
        ACCOUNT_LICENCE_RECORDTYPES__c set4 = new ACCOUNT_LICENCE_RECORDTYPES__c(name = 'Licence');
        insert set4;

        //Insert parent Organisation
        Account parentAccount = new Account(
                name = 'Test0',
                phone = '123',
                ABN__c = '85412369587',
                RecordTypeId = organizationRecType.id);
        insert parentAccount;

        //Insert nominated contact
        Contact testContact1 = new Contact(
                FirstName = 'First',
                LastName = 'Last',
                MailingCity = 'Melbourne',
                MailingState = 'VIC',
                MailingStreet = '673 bourke street',
                MailingPostalCode = '3000',
                AccountId = parentAccount.Id,
                Email = 'example@email.com');
        insert testContact1;

        //Insert nominated contact
        Contact testContact2 = new Contact(
                FirstName = 'Jame',
                LastName = 'Jimmy',
                MailingCity = 'Melbourne',
                MailingState = 'VIC',
                MailingStreet = '673 bourke street',
                MailingPostalCode = '3000',
                AccountId = parentAccount.Id,
                Email = 'example1@email.com');
        insert testContact2;

        //Add contact on Parent Org as Nominated Contact
        parentAccount.Nominated_Partner_Contact_Incent_User__c = testContact1.Id;
        update parentAccount;

        //Insert Parent Network
        network__c parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId(), State__c='Vic', RecordTypeId = otherRecType.Id);
        insert parentNetwork;

        //Insert Network
        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO');
        insert network;

        Account licenceAcc2 = new Account(
                name='test2',
                phone='124',
                recordtypeid=licenceRecType.id,
                //Facility__c =facilityAcc1.id,
                Licence_Status__c= 'Active',
                ABN__c = '85412369585',
                Assignment_Effective_From_Date__c = System.today(),
                ParentId = parentAccount.id );
        insert licenceAcc2;

        //Create Facility based Network created above
        Account facilityAcc1 = new Account(
                name='test1',
                phone='123',
                recordtypeid=facitlityRecType.id,
                Is_a_facility__c = true,
                Network_Facility__c = network.id,
                Licence_Type__c = 'LPO',
                ABN__c = '85412369583',
                Post_Office_Assigned__c= network.Id,
                Subjected_To_GST__c = false,
                ParentId = licenceAcc2.Id );
        insert facilityAcc1;

        Account licenceAcc1 = new Account(
                name='test2',
                phone='124',
                recordtypeid=licenceRecType.id,
                Facility__c =facilityAcc1.id,
                Licence_Status__c= 'Draft',
                ABN__c = '85412369582',
                Assignment_Effective_From_Date__c = System.today(),
                ParentId = parentAccount.id );
        insert licenceAcc1;

        //Insert Social Account
        string accountName = system.label.socialAccountName;
        Account socialAccount = new Account(
                name = accountName,
                phone = '123',
                ABN__c = '85412369581',
                RecordTypeId = organizationRecType.id);
        insert socialAccount;

        Contact testContact3 = new Contact(
                FirstName = 'Jame1',
                LastName = 'Test',
                MailingCity = 'Melbourne',
                MailingState = 'VIC',
                MailingStreet = '673 bourke street',
                MailingPostalCode = '3000',
                AccountId = parentAccount.Id,
                Email = 'example2@email.com');
        insert testContact3;
        Profile p = [SELECT Id FROM Profile WHERE Name='LPO Partner Community User'];
        User u1 = new User(Alias = 'tpo2x', Email='testlpo1x@auspost.com.au.test234', 
            EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id, isActive = true, ContactId = testContact3.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='testlpo1x@auspost.com.au.test234');
        insert u1;
        User u2 = new User(Alias = 'tpo2x', Email='testlpo2x@auspost.com.au', 
            EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id, isActive = true, ContactId = testContact1.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='testlpo22x@auspost.com.au.test222');
        insert u2;
    }
    
    private static void runTriggerMethods(){
        AccountTriggerUtility.RUN_TRIGGER_BEFORE_INSERT = true;
        AccountTriggerUtility.RUN_TRIGGER_AFTER_INSERT = true;
        AccountTriggerUtility.RUN_TRIGGER_BEFORE_UPDATE = true;
        AccountTriggerUtility.RUN_TRIGGER_AFTER_UPDATE = true;
        AccountTriggerUtility.RUN_TRIGGER_BEFORE_DELETE = true;
        AccountTriggerUtility.RUN_TRIGGER_AFTER_DELETE = true;
        AccountTriggerUtility.RUN_TRIGGER_ISUNDELETE = true;
    }
    /**
      * @description       test Method deleteRReconDelete 
      * @return            NA
      * @throws            NA
      */ 
	  private static testMethod void testdeleteRReconDelete(){
        Account testAccount = new Account(
                name = 'testAccount1',
                phone = '123',
                ABN__c = '85412369589',
                RecordTypeId = organizationRecType.id);
        insert testAccount;
        
        Budget_and_Revenue__c CustomerRev = new Budget_and_Revenue__c(Organisation__c=testAccount.id, Financial_Year__c='2024');
        insert CustomerRev;
        Revenue_by_Billing_Account__c RevBA = new Revenue_by_Billing_Account__c(Customer__c=testAccount.id, Financial_Year__c='20204');
        insert RevBA;
         test.startTest();
            
            delete testAccount;
            
        test.stopTest();
     	System.assertEquals(0,[Select count() from Budget_and_Revenue__c WHERE Id =: CustomerRev.Id ]);
        System.assertEquals(0,[Select count() from Revenue_by_Billing_Account__c WHERE Id =: RevBA.Id ]);
        
    }
    
    /**
      * @description       test Method 1 for customer role testing                       
      * @param             NA 
      * @return            NA
      * @throws            NA
      */      
    private static testMethod void testCustomerRole(){
                
        RecordType orgrectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
                
        //Insert Conveyancer_Number__c custom settings
        insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
       //create account
        Account bacct = new Account(name='test org', recordtypeid=orgrectype.Id, phone='11111111', email__c='test@test.com', abn__c='12345678901', Website='www.google.com');
        
        test.startTest();
            
            insert bacct;
            
        test.stopTest();
        system.assertEquals('Prospect', [SELECT Role_Type__c FROM Organisation_Role__c WHERE Organisation__c=:bacct.id limit 1].Role_Type__c);
    }
    
    /**
      * @description       test Method for covering accountUtility Methods based on scenarios                      
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testAccountUtil(){
        //Insert Conveyancer_Number__c custom settings
        insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
        // create hub catchment
        Hub_Catchment_Reference__c hcr = new Hub_Catchment_Reference__c(
            Post_Code__c='2000',
            Hub_Catchment__c='Two Thousand' 
        );   
        insert hcr;                 

        Sales_Segment_Reference__c ssr = new Sales_Segment_Reference__c(Sales_Segment__c='Telecoms');
        insert ssr;    
                   
        RecordType orgrectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        test.startTest();
            //create account
            Account bacct = new Account(name='test org', recordtypeid=orgrectype.Id, type='Small Business',  
                        phone='11111111', email__c='test@test.com', abn__c='12345678901', 
                        Website='www.google.com',Sales_Segment__c=ssr.Id);
            insert bacct;           
            runTriggerMethods();
            bacct.ShippingPostalCode = '9981';
            update bacct;
            
            Account bacct2 = new Account(name='test org2', recordtypeid=orgrectype.Id, type='Enterprise', 
                        Industry='Communications', Industry_Sub_Sector__c='Media',  phone='111111112', 
                        email__c='test2@test.com', abn__c='12345678902', Website='www.yahoo.com');
            runTriggerMethods();
            insert bacct2;
        
        test.stopTest();
        //system.assertEquals('Telecommunication', [SELECT Sales_Segment__c FROM Account WHERE Id=:bacct.Id].Sales_Segment__c);
        
    }

    // LW - removed 2/01/2014
    /**
      * @description       test Method for testing sales director assigment for an account
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testAssignSalesDirector(){
        //Insert Conveyancer_Number__c custom settings
        insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
        RecordType orgrectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];                
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User ux = new User(Alias = 'testx', Email='testx@auspost.com.au.test123',
                        EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='testx@auspost.com.au.test123');                                                
        insert ux;
        
        Sales_Segment_Reference__c ssr = new Sales_Segment_Reference__c(Sales_Segment__c='Telecommunications',  Sales_Director__c=ux.id);
        insert ssr;    

        Account bacct2 = new Account(name='test org2', recordtypeid=orgrectype.Id, type='Enterprise', 
                        industry='Communications', industry_sub_sector__c='Media',  phone='111111112', email__c='test2@test.com', abn__c='12345678902', 
                        website='www.yahoo.com', billingpostalcode= '9921');            
        insert bacct2;
        
        Account acctTest= new Account(name='xTest', recordtypeid=orgrectype.Id, phone='9111111', email__c='xtest@test.com', abn__c='12345678901', 
                        website='www.google.com', type='Enterprises', industry='Utilities');
                
        test.startTest();       
             runTriggerMethods();  
            bacct2.Sales_Segment__c='Telecommunications';
            update bacct2;
            runTriggerMethods();
            insert acctTest;
        test.stopTest();
        
        System.assertEquals('Utilities', [Select Industry from Account where Name='xTest' ].Industry);
        System.assertEquals('Telecommunications', [Select Sales_Segment__c FROM Account where Name='test org2'].Sales_Segment__c);
        //System.assertEquals(ux.id, [Select Sales_Director__c from Account where Id=:bacct2.Id].Sales_Director__c);
        
    }  
    
    /**
      * @description       test Method for testing root account Id for scenarios where there is a parent and not a parent account
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testPopulateAccountRootID() {
        Test.startTest();
            //Insert Conveyancer_Number__c custom settings
            insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
            List <Account> accList =new List <Account>();
            RecordType orgRecType = [Select ID from RecordType where IsActive= true and SObjectType='Account' and Name='Organisation' LIMIT 1];
            Account acc = new Account ();
            Account tmp;    
                acc.Name='Kenny Rogers'; 
                acc.RecordTypeId = orgRecType.ID;
                insert acc; 
            
            Integer x=0;
            for (x=0;x<5;x++){                            
                    tmp=new Account ();
                    tmp.Name='KFC' + x;
                    tmp.RecordTypeId= orgRecType.ID;
                    tmp.ParentId= acc.Id;               
                    accList.add (tmp);
            }
            runTriggerMethods();
            insert accList;
            
        Test.stopTest();
            
        System.AssertEquals(acc.Name , 'Kenny Rogers');
        System.AssertEquals(acc.RecordTypeId, orgRecType.ID);
        System.AssertEquals(acc.Id ,tmp.ParentId);
    }
    
    /**
      * @description       test Method for testing root account Id for scenarios where there is a parent and not a parent account
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testPopulateAccountRootID2() {
        Test.startTest();
            //Insert Conveyancer_Number__c custom settings
            insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
            List <Account> accList =new List <Account>();
            RecordType orgRecType = [Select ID from RecordType where IsActive= true and SObjectType='Account' and Name='Organisation' LIMIT 1];
            Account acc = new Account ();
            Account tmp;    
                acc.Name='Kenny Rogers'; 
                acc.RecordTypeId = orgRecType.ID;
                insert acc; 
            
            Integer x=0;
            for (x=0;x<5;x++){                            
                    tmp=new Account ();
                    tmp.Name='KFC' + x;
                    tmp.RecordTypeId= orgRecType.ID;
                    tmp.ParentId= acc.Id;               
                    accList.add (tmp);
            }
            runTriggerMethods();
            insert accList;
            
        Test.stopTest();
            
        System.AssertEquals(acc.Name , 'Kenny Rogers');
        System.AssertEquals(acc.RecordTypeId, orgRecType.ID);
        System.AssertEquals(acc.Id ,tmp.ParentId);
    }
    
    
    /**
      * @description       test Method for testing scenario where the owner's email is updated.
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public static testmethod void testUpdateOwnersEmail(){
        test.startTest();
            //Insert Conveyancer_Number__c custom settings
            insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
            RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User u1 = new User(Alias = 'testname', Email='test@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='xTesting', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='auTestX0001@auspost.com.au.test111');                                                
            insert u1;
            
            User u2 = new User(firstname='eXotic', lastName='User', Alias = 'testREc', Email='test@xyYauspost.com.au',                
                        EmailEncodingKey='UTF-8',  LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='auTestY@auspost.com.au.test223332');                                                
            insert u2;
                    
            Account acct = new Account (name='Microsoft Inc', phone='123', email__c='test@test.com', recordtypeid=orgrectype.Id  , ownerId=u1.Id);
            insert acct;
            runTriggerMethods();
            try {
            acct.OwnerId = u2.id;
            update acct;
            }
            catch(Exception exp) {}
        test.stopTest();
    }
    
    /**
      * @description       test Method for testing generation of conveyancer number
      * @param             NA 
      * @return            NA
      * @throws            NA
      */  
    private static testMethod void testgenerateConveyancerNumber(){
        Test.startTest();//determine recordtype of account
            RecordType orgRecType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
             //Insert Conveyancer_Number__c custom settings
            insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
            // create 20 test accounts
            List<Account> accListCon = new List<Account>();
            List<Account> accListUpdate = new List<Account>();
            Account acc;
            integer x = 0;
            for(x=1;x<20;x++){
                acc = new Account();
                acc.RecordTypeId = orgRecType.Id;
                acc.Name = 'Conveyancer Organisation';
                accListCon.add(acc);
            }
            insert accListCon;
           
            // retrieve and then update the 20 newly created test accounts to set them as a conveyancer
            List<Account> accAll = [Select Id, Name, Conveyancer_Is_a__c, Conveyancer_Number__c from Account Where Id IN:accListCon];
            for (Account accUpdate : accAll) {
                accUpdate.Conveyancer_Is_a__c = true;
                accListUpdate.add(accUpdate);
            }
            runTriggerMethods();
            update accListUpdate;
            
            // retrieve and assert each account now has a conveyancer number
            
            List<Account> accAllCon = [Select Name, Conveyancer_Is_a__c, Conveyancer_Number__c from Account Where Id IN:accListUpdate];
            for (Account acctCon : accAllCon){
                System.assertEquals(acctCon.Name,'Conveyancer Organisation');
                System.assertEquals(acctCon.Conveyancer_Is_a__c, true);
                System.assert(acctCon.Conveyancer_Number__c != null);
            }
        
        Test.stopTest();

    }
    
    /**
      * @description       test Method for testing generation of conveyancer number
      * @param             NA 
      * @return            NA
      * @throws            NA
      */  
    private static testMethod void testRevPhone(){
         RecordType accountRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
        
        Account testPersonAccount = new Account(RecordTypeId = accountRecordType.Id, FirstName='Derek', LastName='James', Phone='0454545434');
        insert testPersonAccount ;
    }
        
    /**
      * @description       test Method for testing lock verified data
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    
    public static testMethod void testLockVerifiedData(){
        RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND DeveloperName = 'PersonAccount' limit 1];
        Account bacct = new Account(FirstName='test',LastName='org', recordtypeid=orgrectype.Id, phone='0454545434',LevelOfAssurance__pc = 3.1, PersonEmail='test@test.com', abn__c='12345678901', Website='www.google.com');
        insert bacct;
        
        LOA_Settings__c loa = new LOA_Settings__c(Name = 'Email',LOA_Value__c = 2.3 , Locked_Field_API__c='PersonEmail');
        insert loa;
        
        runTriggerMethods();
        test.startTest();
        bacct.Preferred_Name__pc = '';
        update bacct;
        try{
        bacct.PersonEmail = 'test@test2.com';
        update bacct;
        }
        catch(Exception e){
        System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
        test.stopTest();
        
    }
    public static testMethod void testLockVerifiedDataTest2(){
        RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND DeveloperName = 'PersonAccount' limit 1];
        Account bacct = new Account(FirstName='test',LastName='org',Preferred_Name__pc = 'test',LegalFirstName__pc = '',LegalLastName__pc = '', recordtypeid=orgrectype.Id, phone='0454545434',LevelOfAssurance__pc = 0.0, PersonEmail='test@test.com', abn__c='12345678901', Website='www.google.com');
        insert bacct;
        
        LOA_Settings__c Loa = new LOA_Settings__c(Name = 'Email',LOA_Value__c = 2.3 , Locked_Field_API__c='PersonEmail');
        insert Loa;
        
        runTriggerMethods();
        test.startTest();
        //bacct.LegalFirstName__pc = '';
        //bacct.LegalLastName__pc = '';
            
        bacct.Preferred_Name__pc = '';
        update bacct;
        System.assertEquals('test',[select Id,Preferred_Name__pc from Account where Id =:bacct.Id].Preferred_Name__pc);
    }
    
    /**
      * @description       test Method for testing generation of conveyancer number
      * @param             NA 
      * @return            NA
      * @throws            NA
        
    private static testMethod void testlicence(){
        Test.startTest();//determine recordtype of account
            ACCOUNT_LICENCE_RECORDTYPES__c accLic = new ACCOUNT_LICENCE_RECORDTYPES__c(Name='Licence');
            insert accLic;
           set<string> ACCOUNT_LICENCE_RECORDTYPES = new Set<String>{'Licence'};
           Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,'Account'));
            //Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
            Id recId ;
            for(Id rec : licenceRTs.keySet()) {
            recId =rec ;
            }
            //RecordType orgRecType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = ACCOUNT_LICENCE_RECORDTYPEs limit 1];
             //Insert Conveyancer_Number__c custom settings
            insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
             //insert network
            Account acct2 = new Account ( name='Microsoft Inc', phone='123', 
                            email__c='test@test.com', recordtypeid=recId );
            insert acct2;
            // create 20 test accounts
            List<Account> accListCon = new List<Account>();
            List<Account> accListUpdate = new List<Account>();
            Account acc;
            integer x = 0;
            for(x=1;x<20;x++){
                acc = new Account();
                acc.RecordTypeId = recId ;
                acc.Facility__c = acct2.Id;
                acc.Name = 'Conveyancer Organisation';
                accListCon.add(acc);
            }
            insert accListCon;
           
            // retrieve and then update the 20 newly created test accounts to set them as a conveyancer
            List<Account> accAll = [Select Id, Name, Conveyancer_Is_a__c, Conveyancer_Number__c from Account Where Id IN:accListCon];
            for (Account accUpdate : accAll) {
                accUpdate.Conveyancer_Is_a__c = true;
                accListUpdate.add(accUpdate);
            }
            update accListUpdate;
            
            // retrieve and assert each account now has a conveyancer number
            
            List<Account> accAllCon = [Select Name, Conveyancer_Is_a__c, Conveyancer_Number__c from Account Where Id IN:accListUpdate];
            for (Account acctCon : accAllCon){
                System.assertEquals(acctCon.Name,'Conveyancer Organisation');
                System.assertEquals(acctCon.Conveyancer_Is_a__c, true);
                System.assert(acctCon.Conveyancer_Number__c != null);
            }
        
        Test.stopTest();

    }
    */
    
    /**
      * @description       test Method for testing scenario where the owner's email is updated.
      * @param             NA 
      * @return            NA
      * @throws            NA
      
    public static testmethod void testUpdate(){
        ACCOUNT_LICENCE_RECORDTYPES__c accLic = new ACCOUNT_LICENCE_RECORDTYPES__c(Name='Licence');
            insert accLic;
           set<string> ACCOUNT_LICENCE_RECORDTYPES = new Set<String>{'Licence'};
           Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,'Account'));
            //Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
            Id recId;
            for(Id rec : licenceRTs.keySet()) {
            recId =rec ;
            }
        test.startTest();
            //Insert Conveyancer_Number__c custom settings
            insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
            RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User u1 = new User(Alias = 'testname', Email='test@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='xTesting', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='auTestX0001@auspost.com.au');                                                
            insert u1;
            
            User u2 = new User(firstname='eXotic', lastName='User', Alias = 'testREc', Email='test@xyYauspost.com.au',                
                        EmailEncodingKey='UTF-8',  LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='auTestY@auspost.com.au');                                                
            insert u2;
            
            Account acct2 = new Account (name='Microsoft Inc', phone='123', 
                            email__c='test@test.com', recordtypeid=recId   , ownerId=u1.Id);
            insert acct2;
            Account acct3 = new Account (name='Microsoft Inc', phone='123', 
                            email__c='test@test.com', recordtypeid=recId   , ownerId=u1.Id);
            insert acct3;
            Account acct = new Account (Facility__c = acct2.Id, name='Microsoft Inc', phone='123', 
                            email__c='test@test.com', recordtypeid=recId   , ownerId=u1.Id);
            insert acct;
            
            //acct.OwnerId = u2.id;
            //acct.Facility__c = acct3.Id;
            //update acct;
            
            
            delete acct;
            
            undelete acct;
        test.stopTest();
    }
    */
    //kalpita
    /**
      * @description       test Method for testing scenario where the owner's email is updated.
      * @param             NA 
      * @return            NA
      * @throws            NA
      
    public static testmethod void testUpdate(){
        ACCOUNT_LICENCE_RECORDTYPES__c accLic = new ACCOUNT_LICENCE_RECORDTYPES__c(Name='Licence');
            insert accLic;
           set<string> ACCOUNT_LICENCE_RECORDTYPES = new Set<String>{'Licence'};
           Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,'Account'));
            //Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
            Id recId = '';
            for(Id rec : licenceRTs.keySet()) {
            recId =rec ;
            }
        test.startTest();
            //Insert Conveyancer_Number__c custom settings
            insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
            RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User u1 = new User(Alias = 'testname', Email='test@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='xTesting', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='auTestX0001@auspost.com.au');                                                
            insert u1;
            
            User u2 = new User(firstname='eXotic', lastName='User', Alias = 'testREc', Email='test@xyYauspost.com.au',                
                        EmailEncodingKey='UTF-8',  LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='auTestY@auspost.com.au');                                                
            insert u2;
            
            //insert network
            Network__c nw = TestDataProvider.createTestNetwork();
            nw.Email__c = 'top@top.com';
            nw.Name = 'test network';
            nw.Post_Code__c = '3000';
            nw.Geolocation__Latitude__s = 31;
            nw.Geolocation__Longitude__s = 121;
            insert nw;
            
            //insert network
            Network__c nw2 = TestDataProvider.createTestNetwork();
            nw2.Email__c = 'top@top.com';
            nw2.Name = 'test network 2';
            nw2.Post_Code__c = '3000';
            nw2.Geolocation__Latitude__s = 31;
            nw2.Geolocation__Longitude__s = 121;
            insert nw;
                    
            Account acct = new Account (Facility__c = nw.Id, name='Microsoft Inc', phone='123', 
                            email__c='test@test.com', recordtypeid=recId   , ownerId=u1.Id);
            insert acct;
            
            acct.OwnerId = u2.id;
            acct.Facility__c = nw2.Id;
            update acct;
        test.stopTest();
    }
    */

    /**
      * @description       test Method for testing Licence Insert.
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public static testmethod void licenceInsert(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole r = [select id from UserRole where developername='PartnerInfo_National_RNP_Manager' limit 1];
        User ux = new User(Alias = 'testx', Email='testx@auspost.com.au.test123',
                EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id, isActive = true, UserRoleId=r.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testx@auspost.com.au.test123');
        system.runAs(ux) {
            Account parentAccount = [SELECT id from account where recordtypeid = :organizationRecType.id limit 1];
            Account facilityAcc1 = [SELECT id, Network_Facility__r.Parent_Network__r.Network_Manager__c from account where recordtypeId = :facitlityRecType.id limit 1];

            // Add a licence to this facility
            Account licenceAcc1 = new Account(
                    name = 'test2',
                    phone = '124',
                    recordtypeid = licenceRecType.id,
                    Facility__c = facilityAcc1.id,
                    Licence_Status__c = 'Draft',
                    Assignment_Effective_From_Date__c = System.today(),
                    ParentId = parentAccount.id);
            Test.startTest();
            insert licenceAcc1;
            //Get the resulted Licence
            Account result = [SELECT id, Network_Manager__c, Email__c from account where Id = :licenceAcc1.id limit 1];
            System.debug('result.Network_Manager__c--->' + result.Network_Manager__c);
            //Confirm Changes for Network manager and State Admin(Email__c) is populated.
            System.assertEquals(facilityAcc1.Network_Facility__r.Parent_Network__r.Network_Manager__c, result.Network_Manager__c);
            System.assertNotEquals(null, result.Email__c);
            Test.stopTest();
        }
    }

    /**
      * @description       test Method for testing Licence Activation.
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public static testmethod void licenceActivate(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole r = [select id from UserRole where developername='PartnerInfo_National_RNP_Manager' limit 1];
        User ux = new User(Alias = 'testx', Email='testx@auspost.com.au.test123',
                EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id, isActive = true, UserRoleId=r.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testx@auspost.com.au.test123');
        system.runAs(ux) {
            Test.startTest();
            Account licenceAcc1 = [SELECT id, Facility__r.ParentId from account where recordtypeId = :licenceRecType.id AND Licence_Status__c = 'Draft' limit 1];
            //licenceAcc1.Nominated_Partner_Contact_Incent_User__c = nominatedContact.Id;
            licenceAcc1.Licence_Status__c = 'Active';
            update licenceAcc1;
            Account parentOrg = [SELECT id, Nominated_Partner_Contact_Incent_User__c from Account where Nominated_Partner_Contact_Incent_User__c != null limit 1];
            Contact nominatedContact = [SELECT id from contact where id != :parentOrg.Nominated_Partner_Contact_Incent_User__c limit 1];
            parentOrg.Nominated_Partner_Contact_Incent_User__c = nominatedContact.Id;
            update parentOrg;
            //Get the resulted Licence
            Account result = [SELECT id, Facility__r.ParentId from account where Id = :licenceAcc1.id limit 1];
            //Check if the Facility is assigned to the new Licence
            System.assertEquals(result.Id, result.Facility__r.ParentId);
            Test.stopTest();
        }
    }
    /**
      * @description  Test the scenario for one account has been added with the Post Assigned Office 
      *               which will cause the account team to be created .
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public static testMethod void testInsertAccountTeam(){
        network__c parentNetwork = [Select Id from Network__c where Org_ID__c = '2346'];
        Account facilityAcc1 = [Select Id from Account where ABN__c = '85412369583' limit 1];
        Account parentAccount = [Select Id from Account where ABN__c = '85412369587' limit 1];
        Account accountRecord = new Account(
                name='test2',
                phone='124',
                recordtypeid=licenceRecType.id,
                Facility__c =facilityAcc1.id,
                Licence_Status__c= 'Draft',
                ABN__c = '85412369582',
                Post_Office_Assigned__c = parentNetwork.Id,
                Assignment_Effective_From_Date__c = System.today(),
                ParentId = parentAccount.id );
        Test.startTest();
        insert accountRecord;        
        
        Test.stopTest();
        List<AccountTeamMember> resultATMs = [SELECT Id, UserId, AccountId From AccountTeamMember ]; 
        System.assert(resultATMs.size() > 0);
    }
    /**
      * @description  Test the scenario for multiple accounts have been added with the Post Assigned Office 
      *               which will cause the account teams to be created
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public static testMethod void testInsertMultipleAccountTeams(){
        network__c parentNetwork = [Select Id from Network__c where Org_ID__c = '2346'];
        Account facilityAcc1 = [Select Id from Account where ABN__c = '85412369583' limit 1];
        Account parentAccount = [Select Id from Account where ABN__c = '85412369587' limit 1];
        Account accountRecord1 = new Account(
                name='test2',
                phone='124',
                recordtypeid=licenceRecType.id,
                Facility__c =facilityAcc1.id,
                Licence_Status__c= 'Draft',
                ABN__c = '85412369552',
                Post_Office_Assigned__c = parentNetwork.Id,
                Assignment_Effective_From_Date__c = System.today(),
                ParentId = parentAccount.id );
        Account accountRecord2 = new Account(
                name='test2',
                phone='124',
                recordtypeid=licenceRecType.id,
                Facility__c =facilityAcc1.id,
                Licence_Status__c= 'Draft',
                ABN__c = '85412369553',
                Post_Office_Assigned__c = parentNetwork.Id,
                Assignment_Effective_From_Date__c = System.today(),
                ParentId = parentAccount.id );
        Test.startTest();
        List<Account> records = new List<Account>();
        records.add(accountRecord2);
        records.add(accountRecord1);
        insert records;        
    
        Test.stopTest();
        List<AccountTeamMember> resultATMs = [SELECT Id, UserId, AccountId From AccountTeamMember ]; 
        System.assert(resultATMs.size() > 0); 
    }
    /**
      * @description  Test the scenario for one account has been updated with the Post Assigned Office value from null
      *               which will cause the account teams to be created
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public static testMethod void testUpdateAccountTeam(){
        User u1 = [Select Id, AccountId from User where UserName = 'testlpo1x@auspost.com.au.test234'];
        network__c parentNetwork = [Select Id from Network__c where Org_ID__c = '2346'];
        Account accRec = [SELECT Id, Post_Office_Assigned__c from Account where Id =: u1.AccountId limit 1];
        
        Test.startTest();
        accRec.Post_Office_Assigned__c = parentNetwork.Id;
        update accRec;
        Test.stopTest();

        List<AccountTeamMember> resultATMs = [SELECT Id, UserId, AccountId From AccountTeamMember ]; 
        System.assert(resultATMs.size() > 0); 
    }
    /**
      * @description  Test the scenario for multiple account has been updated with the Post Assigned Office value from null
      *               which will cause the account teams to be created
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public static testMethod void testUpdateMultipleAccountTeams(){
        network__c parentNetwork = [Select Id from Network__c where Org_ID__c = '2346'];
        List<Account> accRecs = [SELECT Id, Post_Office_Assigned__c from Account];
        Test.startTest();
        for(Account acc: accRecs) {
           acc.Post_Office_Assigned__c = parentNetwork.Id;
        }
        update accRecs;
        Test.stopTest();
        List<AccountTeamMember> resultATMs = [SELECT Id, UserId, AccountId From AccountTeamMember ]; 
        System.assert(resultATMs.size() >  0);
    }
    /**
      * @description  Test the scenario for chaning the post office assigned ot be empty
      *               which will cause the account teams to be deleted
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public static testMethod void testRemoveAccountTeam(){
        network__c parentNetwork = [Select Id from Network__c where Org_ID__c = '2346'];
        Account facilityAcc1 = [Select Id from Account where ABN__c = '85412369583' limit 1];
        Account parentAccount = [Select Id from Account where ABN__c = '85412369587' limit 1];
        Account accountRecord = new Account(
                name='test3Existing',
                phone='124',
                recordtypeid=licenceRecType.id,
                Facility__c =facilityAcc1.id,
                Licence_Status__c= 'Draft',
                ABN__c = '23423423422',
                Post_Office_Assigned__c = parentNetwork.Id,
                Assignment_Effective_From_Date__c = System.today(),
                ParentId = parentAccount.id );
        
        insert accountRecord;        
        Test.startTest();
        AccountTriggerUtility.RUN_TRIGGER_BEFORE_UPDATE = true;
        AccountTriggerUtility.RUN_TRIGGER_AFTER_UPDATE = true;
        List<Account> records = [Select Id, Post_Office_Assigned__c from Account where Post_Office_Assigned__c != null];
        for(Account record: records) {
            record.Post_Office_Assigned__c = null;
        }
        
        update records;
        
        Test.stopTest();

        List<AccountTeamMember> resultATMs = [SELECT Id, UserId, AccountId From AccountTeamMember ]; 
        System.assert(resultATMs.isEmpty());
    }

    @IsTest
    public static void testUpdateBAOnDelete(){
        Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert accountRecord;
        accountRecord.LEGACY_ID__c = '60000000';
        update accountRecord;
        System.assertNotEquals(null, accountRecord.Id, 'Expected an Account record to be created');

        Billing_Account__c billingAccountRecord = ApplicationTestDataFactory.getBillingAccounts(1, accountRecord.Id, 'SAP ERP', false)[0];
        insert billingAccountRecord;
        System.assertNotEquals(null, billingAccountRecord.Id, 'Expected a Billing Account record to be created');

        Revenue_by_Organisation__c rboToInsert = new Revenue_by_Organisation__c();
        rboToInsert.Organisation__c = accountRecord.Id;
        insert rboToInsert;
        System.assertNotEquals(null, rboToInsert.Id, 'Expected a Revenue by Organisation record to be created');

        Billing_Account__c ba = [SELECT Id,Organisation__c FROM Billing_Account__c WHERE Id = :billingAccountRecord.Id];
        System.assertEquals(accountRecord.Id, ba.Organisation__c, 'Expected the Billing Account created is associated with the Account');

        Revenue_by_Organisation__c rbo = [SELECT Id,Organisation__c FROM Revenue_by_Organisation__c WHERE Id = :rboToInsert.Id];
        System.assertEquals(accountRecord.Id, rbo.Organisation__c, 'Expected the Revenue by Organisation created is associated with the Account');

        Test.startTest();
        delete accountRecord;
        Test.stopTest();

        List<Billing_Account__c> bas = [SELECT Id,Organisation__c FROM Billing_Account__c WHERE Id = :billingAccountRecord.Id];
        System.assert(bas.isEmpty(), 'Expected the Billing Account to be deleted by the deletion of the Account record');

        List<Revenue_by_Organisation__c> rbos = [SELECT Id,Organisation__c FROM Revenue_by_Organisation__c WHERE Id = :rboToInsert.Id];
        System.assert(rbos.isEmpty(), 'Expected the Revenue by Organisation to be deleted by the deletion of the Account record');
    }
}