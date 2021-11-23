/**
  * @author       : 
  * @date         : 
  * @description  : Test class for testing account utility methods for hubcatchment and salesdirector
--------------------------------------- History --------------------------------------------------                      
L.Lavapie   05.05.2016          Moved from AccountUtil Class
Kalpita T   26.08.2016          Added references to new trigger class and removed static references to old test classes 
**/
@isTest
private class AccountUtil_Test {
   
    /**
      * @description       Method to set the static constants to run trigger methods.
      * @param             NA 
      * @return            Void
      * @throws            NA
      */    
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
      * @description       Method to test the customer role creation for every organization
      * @param             NA 
      * @return            Void
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
        insert bacct;
        
        
        test.startTest();
        //assert
        system.assertEquals('Prospect', [SELECT Role_Type__c FROM Organisation_Role__c WHERE Organisation__c=:bacct.id limit 1].Role_Type__c);
        
        test.stopTest();
    } 

    /**
      * @description       Method to test the setting on conveyancer number
      * @param             NA 
      * @return            Void
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
        
        //create account
        Account bacct = new Account(name='test org', recordtypeid=orgrectype.Id, type='Small Business',  phone='11111111', email__c='test@test.com', abn__c='12345678901', Website='www.google.com');
        insert bacct;           
        runTriggerMethods();
        bacct.ShippingPostalCode = '9981';
        update bacct;
        runTriggerMethods();
        Account bacct2 = new Account(name='test org2', recordtypeid=orgrectype.Id, type='Enterprise', Industry='Communications', Industry_Sub_Sector__c='Media',  phone='111111112', email__c='test2@test.com', abn__c='12345678902', Website='www.yahoo.com');
        insert bacct2;
                
        test.startTest();
        test.stopTest();
        //system.assertEquals('Telecommunication', [SELECT Sales_Segment__c FROM Account WHERE Id=:bacct.Id].Sales_Segment__c);
        
    }

    // private static testMethod void testUpdateIndividualScore(){}
    // LW - removed 2/01/2014
    /**
      * @description       Method to test assignment of sales director to an account
      * @param             NA 
      * @return            Void
      * @throws            NA
      */ 
    private static testMethod void testAssignSalesDirector(){
        //Insert Conveyancer_Number__c custom settings
        insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
        RecordType orgrectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];                
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User ux = new User(Alias = 'testx', Email='testx@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='testx@auspost.com.au');                                                
        insert ux;
        
        Sales_Segment_Reference__c ssr = new Sales_Segment_Reference__c(Sales_Segment__c='Telecommunications',  Sales_Director__c=ux.id);
        insert ssr;    

        Account bacct2 = new Account(name='test org2', recordtypeid=orgrectype.Id, type='Enterprise', 
                        industry='Communications', industry_sub_sector__c='Media',  phone='111111112', email__c='test2@test.com', abn__c='12345678902', 
                        website='www.yahoo.com', billingpostalcode= '9921');            
        insert bacct2;
        runTriggerMethods();
        Account acctTest= new Account(name='xTest', recordtypeid=orgrectype.Id, phone='9111111', email__c='xtest@test.com', abn__c='12345678901', 
                        website='www.google.com', type='Enterprises', industry='Utilities');
                
        test.startTest();       
        AccountTriggerUtility.RUN_TRIGGER_BEFORE_UPDATE = true; 
        runTriggerMethods();      
        bacct2.Sales_Segment__c='Telecommunications';
        update bacct2;
        runTriggerMethods();
        insert acctTest;
        test.stopTest();
        
        System.assertEquals('Utilities', [Select Industry from Account where Name='xTest' ].Industry);
        System.assertEquals('Telecommunications', [Select Sales_Segment__c FROM Account where Name='test org2'].Sales_Segment__c);
        System.assertEquals(ux.id, [Select Sales_Director__c from Account where Id=:bacct2.Id].Sales_Director__c);
        
    }  
    
    /**
      * @description       Method to test population of root account for every account inserted/updated/deleted
      * @param             NA 
      * @return            Void
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
        AccountTriggerUtility.RUN_TRIGGER_AFTER_INSERT = true;
        insert accList;
            
        Test.stopTest();
            
        System.AssertEquals(acc.Name , 'Kenny Rogers');
        System.AssertEquals(acc.RecordTypeId, orgRecType.ID);
        System.AssertEquals(acc.Id ,tmp.ParentId);
    } 
    
    /**
      * @description       Method to set the owners email on an account
      * @param             NA 
      * @return            Void
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
                        TimeZoneSidKey='America/Los_Angeles', UserName='auTestX0001@auspost.com.au');                                                
            insert u1;
            
            User u2 = new User(firstname='eXotic', lastName='User', Alias = 'testREc', Email='test@xyYauspost.com.au',                
                        EmailEncodingKey='UTF-8',  LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='auTestY@auspost.com.au');                                                
            insert u2;
                    
        Account acct = new Account (name='Microsoft Inc', phone='123', email__c='test@test.com', recordtypeid=orgrectype.Id  , ownerId=u1.Id);
            insert acct;
            runTriggerMethods();
            AccountTriggerUtility.RUN_TRIGGER_AFTER_UPDATE = true;
            acct.OwnerId = u2.id;
           // update acct;
            test.stopTest();
    }
    
      
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
    
}