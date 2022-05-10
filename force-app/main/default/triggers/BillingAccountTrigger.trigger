/**************************************************
Type:       Trigger for Billing Account Object
Purpose:    After a Billing Account is linked to the Customer record,
            change the Customer Type from 'Prospect' to 'Customer'
History:
--------------------------------------------------
22.09.2011  Richard Enojas(Salesforce.com)  Created
17.10.2011  Richard Enojas(Salesforce.com)  Added check for custom setting
02.10.2012  M. Isidro (Cloud Sherpas)       Added functionality for reparenting sub-accounts
31.10.2012  Richard Enojas(Salesforce.com)  Added After Insert logic to set the Customer on an incoming Sub BA
19.04.2013  Haider Raza(Post)               Commented if (ba.Organisation__c != tempacct.Id) so that Date_Parent_Changed is updated for new BA created
01.02.2017  davey.yu@auspost.com.au         Updated: INC0880835 Validate if billing account is "ZBIL" then dont update customer type
31.03.2017  Disha.Kariya@auspost.com.au     Updated: REQ1104500 Renamed ZBIL to SBBA
23.03.2022  Naveen Rajanna                  Updated api version to 52 and commented debug statements
**************************************************/
trigger BillingAccountTrigger on Billing_Account__c (after insert, after update, before insert) {
    if (!SystemSettings__c.getInstance().Disable_Billing_Account_Trigger__c) {
        
        if (trigger.isAfter){
            if (trigger.isInsert || trigger.isUpdate){
        
                Account tempacct = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000' limit 1];
                List<Id> OrgIds = new List<Id>();
                List<Id> subBAList = new List<Id>();
                                
                for (Billing_Account__c ba : trigger.new){
                    if (trigger.isInsert || (trigger.isUpdate && ba.Organisation__c!=trigger.oldMap.get(ba.Id).Organisation__c)){
                        // system.debug('***** type'+ba.Type__c);
                        if(ba.Type__c != 'SBBA') // Added by DYU 01-FEB-2017 - INC0880835 Exclude ZBIL billing account when updating org customer type // Updated by Disha 31-MAR-2017 - REQ1104500 Renamed ZBIL to SBBA  
                            OrgIds.add(ba.Organisation__c);
                    }
                    
                    //Caters for scenario wherein an incoming Sub is attached to Temporary Customer
                    //even if the existing Payer it belongs to is already linked to an actual Customer
                    if (trigger.isInsert && ba.Organisation__c == tempacct.Id && ba.PAYER_ACCOUNT_ID__c != null){
                        subBAList.add(ba.Id);
                    }
                    
                }
                if(!OrgIds.isEmpty())
                    BillingAccountUtil.setCustomerType(OrgIds); 
            
                if(!subBAList.IsEmpty())
                    BillingAccountUtil.setCustomerOnSub(subBAList,tempacct);
            }
        }
            
        if (trigger.isAfter && trigger.isUpdate) {
            List<Id> baIds = new List<Id>();
            Map<String, String> baIdorgIdMap = new Map<String, String>(); 
            for (Billing_Account__c ba : trigger.new) {
                // system.debug('***ba.Organisation__c: ' + ba.Organisation__c);
                // system.debug('***trigger.oldMap.get(ba.Id).Organisation__c: ' + trigger.oldMap.get(ba.Id).Organisation__c);
                if (ba.Organisation__c != trigger.oldMap.get(ba.Id).Organisation__c) {
                    baIds.add(ba.Id);       
                    baIdorgIdMap.put(ba.Id, ba.Organisation__c);                        
                }
            }
            if (baIds.size() > 0) {
                BillingAccountUtil.reparentSubAccount(baIds, baIdorgIdMap);         
            } 
        }   
        
        if (trigger.isBefore && trigger.isInsert) {
            //List<Account> acctList = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000' limit 1];
            Account tempacct = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000' limit 1];
            if (tempacct <> null) {
                for (Billing_Account__c ba : trigger.new) {
                    //Commented so that the Date_Parent_Changed gets updated for all BA created            
                    //if (ba.Organisation__c != tempacct.Id) {
                        //Caters for the scenario wherein the incoming Sub is already associated to the Customer of the Payer
                        //SAP ERP prepopulates this based on 1a.1/1a.2 data coming down from Salesforce 
                        ba.Date_Parent_Changed__c = datetime.now();
                    //}
                }           
            }
        }
    }
}