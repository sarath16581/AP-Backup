/**
 * @author Naveen Rajanna
 * @date 2022-03-23
 * @group Tests
 * @description 
 * @changelog
 */
@IsTest
private class BillingAccountUtil_Test {

  /**
    /* Nandan : Updated Test Method to fix Too Many SOQL
    */
  @IsTest
    public static void testReparentSubAccount() {
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: BillingAccountUtil.ADMIN_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Admin',adminProf.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            List<Account> accList = new List<Account>();
            
            Account accWayne= TestUtility.createBusinessAccount('Wayne Enterprises',
                                                                accRecTypeMap.get('Organisation').getRecordTypeId());
            accWayne.LEGACY_ID__c = '12345';
            accWayne.abn__c = '';       // 11/25/2019 - duplicate_detected error fix: removed ABN value
            accWayne.billingstreet = 'street';
            accWayne.billingcity = 'city';
            accWayne.billingstate = 'state';
            accWayne.billingpostalcode = '3000';
            accWayne.billingcountry = 'AU';
            accWayne.shippingstreet = 'street';
            accWayne.shippingcity = 'city';
            accWayne.shippingstate = 'state';
            accWayne.shippingpostalcode = '3000';
            accWayne.shippingcountry = 'AU';
            
            Account accBruce = accWayne.clone(false,false,false,false);
            
            accList.add(accWayne);
            accList.add(accBruce);
            
            // START OF UPDATE DY 27.10.2016 MPB - Add temporary account
            Account tempAccount = TestUtility.createBusinessAccount('Temporary Account',
                                                   accRecTypeMap.get('Organisation').getRecordTypeId());
           
            accList.add(tempAccount);
            
            Database.insert(accList);
            
            Account tempUpdateAccount = [Select id, LEGACY_ID__c from Account where id =: tempAccount.id];
            tempUpdateAccount.LEGACY_ID__c = '60000000'; 
            update tempUpdateAccount;
            // End OF UPDATE DY 27.10.2016 MPB - Add temporary account
          
            
            Billing_Account__c  billAcc = TestUtility.createBillingAccount('Bill Acc',accWayne.Id);
            Database.insert(billAcc);
            
         
            
            List<Billing_Account__c> subAccounts = new List<Billing_Account__c>();
            
            Billing_Account__c  subAcc1 = TestUtility.createBillingAccount('Bill Acc',accWayne.Id);
            subAcc1.PAYER_ACCOUNT_ID__c = billAcc.Id;
            Billing_Account__c  subAcc2 = TestUtility.createBillingAccount('Bill Acc',accWayne.Id);
            subAcc2.PAYER_ACCOUNT_ID__c = billAcc.Id;
            
            subAccounts.add(subAcc1);
            subAccounts.add(subAcc2);
            
            Database.insert(subAccounts);
            
            Test.startTest();
                billAcc.Organisation__c = accBruce.Id;
                Database.update(billAcc);
            Test.stopTest();
            
            System.assertEquals(accBruce.Id, [select Organisation__c from Billing_Account__c where id =:subAcc1.Id].Organisation__c); 
            System.assertEquals(accBruce.Id, [select Organisation__c from Billing_Account__c where id =:subAcc2.Id].Organisation__c);
        }
    }
    
    @IsTest
    public static void testInsertSubAccount(){
        test.startTest();
        
        
        RecordType rectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        // START OF UPDATE DY 27.10.2016 MPB - Add temporary account
        Account tempAccount = TestUtility.createBusinessAccount('Temporary Account',
                                             rectype.id);
        insert tempAccount ;   
        
        Account tempUpdateAccount = [Select id, LEGACY_ID__c from Account where id =: tempAccount.id];
        tempUpdateAccount.LEGACY_ID__c = '60000000'; 
        update tempUpdateAccount;
        // End OF UPDATE DY 27.10.2016 MPB - Add temporary account
        
        //create account
        // 11/25/2019 - duplicate_detected error fix: removed ABN value
        Account acct = new Account                
            (name='test1', recordtypeid=rectype.Id, phone='11111111', email__c='test@test.com', abn__c='', website='www.test1.com',                 
                billingstreet='street', billingcity='city', billingstate='state', billingpostalcode='3000', billingcountry='AU',                
                shippingstreet='street', shippingcity='city', shippingstate='state', shippingpostalcode='3000', shippingcountry='AU');        
        insert acct;
        
        
        
        Billing_Account__c payerba = new Billing_Account__c(name='payer', organisation__c=acct.id);
        insert payerba;
        
        //Temporary Customer
        Account tempacct = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000' limit 1];
        
        Billing_Account__c subba = new Billing_Account__c(name='sub', organisation__c=tempacct.id, PAYER_ACCOUNT_ID__c=payerba.Id);
        insert subba;
        
        //Sub BA reassigned to Payer BA's Customer upon creation
        system.assertEquals(acct.Id, [select Organisation__c from Billing_Account__c where id =:subba.Id].Organisation__c);
        
        test.stopTest();
    }    
    
    @IsTest
    public static void testUpdateCustomerType(){
        test.startTest();
        
        RecordType rectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        // START OF UPDATE DY 27.10.2016 MPB - Add temporary account
        List<Account> acctList = new List<Account>();
        
        //create account
        // 11/25/2019 - duplicate_detected error fix: removed ABN value
        Account acct = new Account
            (name='test acct', recordtypeid=rectype.Id, phone='11111111', email__c='test@test.com', abn__c='', website='www.testacct.com',                 
                billingstreet='street', billingcity='city', billingstate='state', billingpostalcode='3000', billingcountry='AU',                
                shippingstreet='street', shippingcity='city', shippingstate='state', shippingpostalcode='3000', shippingcountry='AU');        
       
       
        Account tempAccount = TestUtility.createBusinessAccount('Temporary Account',
                                               rectype.id);
        acctList.add(acct);
        acctList.add(tempAccount);
        insert acctList;
        
        
        Account tempUpdateAccount = [Select id, LEGACY_ID__c from Account where name = 'Temporary Account'];
        tempUpdateAccount.LEGACY_ID__c = '60000000'; 
        update tempUpdateAccount;
        
        
        Account newAcct = [Select id from account where name='test acct'];
        
        //create billing account
        Billing_Account__c ba = new Billing_Account__c(name='1111111', organisation__c=newAcct.id);
        insert ba;
        
        //assert
        system.assertEquals('Customer', [select Role_Type__c from Organisation_Role__c where organisation__c=:newAcct.id].Role_Type__c);
        // End OF UPDATE DY 27.10.2016 MPB - Add temporary account
        test.stopTest();
    } 
}