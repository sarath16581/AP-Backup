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
23.03.2022  Naveen Rajanna                  Removed Test methods and added it to a separate test class, commented debug statements and updated api version to 52
**************************************************/
public class BillingAccountUtil {
    
    // Constants
    public static final String ADMIN_PROFILE = 'System Administrator';
    
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
            // system.debug('***baList: ' + baList);
            for (Billing_Account__c ba : baList) {
                ba.Organisation__c = baIdorgIdMap.get(ba.PAYER_ACCOUNT_ID__c);
                // system.debug('***ba.Organisation__c: ' + ba.Organisation__c);
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
        
        // system.debug('***subbalist : '+subbalist);
        List<Billing_Account__c> balist = [SELECT Id, Payer_Account_Id__c, Payer_Account_Id__r.Organisation__c
                                                FROM Billing_Account__c
                                                WHERE Id in :subbalist];
        List<Billing_Account__c> updatebalist = new List<Billing_Account__c>();                                     
        
        for (Billing_Account__c subba : balist){
            if (subba.Payer_Account_Id__r.Organisation__c!=tempacct.Id)
                //if Payer is attached to an actual Customer, set the Sub to the same Customer value
                // system.debug('*** Payer Customer: '+subba.Payer_Account_Id__r.Organisation__c+'***');                
                subba.Organisation__c = subba.Payer_Account_Id__r.Organisation__c;
                updatebalist.add(subba);
        }
        
        // system.debug('***updatebalist : '+updatebalist);
        
        if(!updatebalist.IsEmpty())
            update(updatebalist);
    }
    
}