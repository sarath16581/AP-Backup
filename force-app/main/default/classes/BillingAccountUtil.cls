/**************************************************
Type:       Utility Class for Billing Account Object
Purpose:    For setCustomerType, update Customer Type to 'Customer'
            upon linking of Billing Account(s)             
History:
--------------------------------------------------
22.09.2011  Richard Enojas(Salesforce.com)  Created
10.10.2011  Richard Enojas(Salesforce.com)  Updated logic to reflect decision to define Party Roles (child object of Account). 
                                            A 'Prospect' role will be updated to 'Customer'.
02.10.2012  M. Isidro (Cloud Sherpas)       Added functionality for reparenting sub-accounts and test coverage 
31.10.2012  Richard Enojas(Salesforce.com)  Added method that prepopulates the Customer on an incoming Sub BA                                               
03.03.2016  Nandan N                        Updated testReparentSubAccount method to fix Too Many SOQL error
22.09.2016  Davey Yu (Accenture)      Updated: MPB Known Acccount Management - Automatically set role from known to customer
27.10.2016  Davey Yu                        Updated: Update all test methods to create temporary account with legacy id 60000000
**************************************************/
public class BillingAccountUtil {
    
    // Constants
    private static final String ADMIN_PROFILE = 'System Administrator';
    
    public static void setCustomerType (List<Id> OrgIds){
        //List<Account> orgs = [SELECT Id, Type FROM Account WHERE Id in : OrgIds];
        List<Organisation_Role__c> orgroles = [SELECT Id, Role_Type__c
                                                FROM Organisation_Role__c
                                                WHERE Organisation__c in : OrgIds];
                                                
        List<Organisation_Role__c> orgrolesToUpdate = new List<Organisation_Role__c>();
        
        for (Organisation_Role__c orgrole : orgroles){
          // START OF UPDATE DY 22.09.2016 MPB - Include role type of known to automatically update it to customer
            if (orgrole.Role_Type__c=='Prospect' || orgrole.Role_Type__c == 'Known'){
                orgrole.Role_Type__c='Customer';
                orgrolesToUpdate.add(orgrole);
            }
            // END OF UPDATE DY 22.09.2016 MPB - Include role type of known to automatically update it to customer
        }
        
        try{
            update(orgrolesToUpdate);
        }catch(System.DMLException e){
            System.debug(e.getMessage());
        }
    }
    
    
    public static void reparentSubAccount(List<Id> baIds, Map<String, String> baIdorgIdMap) {
        for (List<Billing_Account__c> baList : [select Id, PAYER_ACCOUNT_ID__c from Billing_Account__c where PAYER_ACCOUNT_ID__c in :baIds]) {
            system.debug('***baList: ' + baList);
            for (Billing_Account__c ba : baList) {
                ba.Organisation__c = baIdorgIdMap.get(ba.PAYER_ACCOUNT_ID__c);
                system.debug('***ba.Organisation__c: ' + ba.Organisation__c);
            }
            update baList;
        }   
/*
        system.debug('***baIds: ' + baIds);
        system.debug('***baIdorgIdMap: ' + baIdorgIdMap);
        List<Billing_Account__c> baList = new List<Billing_Account__c>();
        baList = [select Id, Name, Organisation__c, PAYER_ACCOUNT_ID__c from Billing_Account__c where PAYER_ACCOUNT_ID__c in :baIds];
        for (Billing_Account__c ba : baList) {
            ba.Organisation__c = baIdorgIdMap.get(ba.PAYER_ACCOUNT_ID__c);
            system.debug('***ba.Organisation__c: ' + ba.Organisation__c);           
        }
        update baList;              
*/  
    }
    
    public static void setCustomerOnSub (List<Id> subbalist, Account tempacct){
        
        system.debug('***subbalist : '+subbalist);
        
        List<Billing_Account__c> balist = [SELECT Id, Payer_Account_Id__c, Payer_Account_Id__r.Organisation__c
                                                FROM Billing_Account__c
                                                WHERE Id in :subbalist];
                                                
        List<Billing_Account__c> updatebalist = new List<Billing_Account__c>();                                     
        
        system.debug('***updatebalist : '+balist);
        
        for (Billing_Account__c subba : balist){
            if (subba.Payer_Account_Id__r.Organisation__c!=tempacct.Id)
                //if Payer is attached to an actual Customer, set the Sub to the same Customer value
                system.debug('*** Payer Customer: '+subba.Payer_Account_Id__r.Organisation__c+'***');
                
                subba.Organisation__c = subba.Payer_Account_Id__r.Organisation__c;
                updatebalist.add(subba);
        }
        
        system.debug('***updatebalist : '+updatebalist);
        
        if(!updatebalist.IsEmpty())
            update(updatebalist);
    }
    
    /* Nandan : Updated Test Method to fix Too Many SOQL */
    static testMethod void testReparentSubAccount() {
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
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
    
    static testMethod void testInsertSubAccount(){
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
    
    static testMethod void testUpdateCustomerType(){
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