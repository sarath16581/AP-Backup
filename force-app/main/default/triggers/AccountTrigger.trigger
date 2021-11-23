/**************************************************
Type:       Trigger for Account Object
Purpose:    Create a default Party Role with Type='Customer'
History:
--------------------------------------------------
05.10.2011    Richard Enojas(Salesforce.com)    Created
17.10.2011    Richard Enojas(Salesforce.com)    Added checking for custom setting
05.15.2011    M. Isidro (Cloud Sherpas)         Added after delete and after undelete
06.06.2012    M. Isidro (Cloud Sherpas)         Added updateSalesSegment
02.08.2012    Richard Enojas (Salesforce.com)   Commented out updateSalesSegment based on CR 23
19.09.2013    Matthew Watson (Salesforce.com)   Added check for "Is Conveyancer" checkbox
02.01.2014    Louis Wang (Bluewolf)             Removed concept of Partner / Individual, such that standard Account-Contact is reestablished
12.05.2014  Mohaemd Atheek (Bluewolf)           Added a method to ignore out of sync updates from SAP CRM based off Integration_Service_Mod_Date__c
02.09.2015  Ashutosh Srivastava (Salesforce.com) Added Partner INFO related methods for Licence Record Type objects
17.03.2016  David Lai (Australia Post) Added Suppress_Default_Role__c for MyPost Business API 
26.04.2016  L. Lavapie(Cloud Sherpas)           Commented out checkPrimaryContact
05.05.2016  L. Lavapie(Cloud Sherpas)           Added checkLegalEntityNPCIU, checkNominatedContactEmail,checkLEUpdate
15.05.2016  Andrew Judd(Salesforce.com)         Renamed checkLegalEntityNPCIU to checkLicenceInsert
11.06.2016  Kenny Liew (Salesforce.com)             Logic added for After Insert to cater for MyPost Business' Lead Conversion against Person Accounts
12.08.2016  Davey Yu (Accenture)                    MPB - Exclude process on UpdateHubcatchment for MPB Accounts and during insert operation only
**************************************************/ 
trigger AccountTrigger on Account (before insert, after insert, after update, after delete, after undelete, before delete, before update) {

    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        
        if(trigger.isInsert){
            if(trigger.isBefore){               
                system.debug('####################################### isInsert & isBefore #####################################');
                
                AccountUtil.generateReversePhoneFields(trigger.new);
                
                if(AccountUtil.RUN_TRIGGER_BEFORE_INSERT){
                    AccountUtil.verifyDuplicateLicence(trigger.new, null);

                    AccountUtil.updateNetworkManager(trigger.new, null);
   // Uncommented the following as preparation for prod go live of LIPOMS 

                    //AccountUtil.checkPrimaryContact(trigger.new, null);  
                    AccountUtil.checkLicenceInsert(trigger.new);
                    AccountUtil.RUN_TRIGGER_BEFORE_INSERT = false;
                }
            }
            
            if(trigger.isAfter){
                system.debug('####################################### isInsert & isAfter #####################################');

                /* START MPB Lead Enhancment 25-07-2016 */
        if(!System.isFuture()) {

                    // Loop through the map, and only run this function if the CampaignMemberId field is not null on any of the records.
                    Set<Id> targetedAccountIds = new Set<Id>();
                    
                    for (Account accountRec : Trigger.New) {
                        if (accountRec.IsPersonAccount && accountRec.MPB_Campaign_Member_Id__pc != null && accountRec.MPB_Campaign_Member_Id__pc != '') {
                            targetedAccountIds.add(accountRec.Id);
                        }
                    }

                    MyPostBusinessLeadConvert.convertLeadPersonAccount(targetedAccountIds);
                }
                /* START MPB Lead Enhancment 250-7-2016 */
            }
            
        }

        if(trigger.isUpdate){           
          
            if(trigger.isBefore){
                system.debug('####################################### isUpdate & isBefore #####################################');
                
                AccountUtil.generateReversePhoneFields(trigger.newMap, trigger.oldMap);
                
                if(AccountUtil.RUN_TRIGGER_BEFORE_UPDATE){
                    AccountUtil.verifyDuplicateLicence(trigger.new,trigger.oldMap);

                    AccountUtil.updateNetworkManager(trigger.new, trigger.oldMap);

                    AccountUtil.checkNominatedContactEmail(trigger.new,trigger.oldMap);
                    AccountUtil.checkLEUpdate(trigger.new,trigger.oldMap);
                    AccountUtil.RUN_TRIGGER_BEFORE_UPDATE = false;
                }
            }
            
            if(trigger.isAfter){
                system.debug('####################################### isUpdate & isAfter #####################################');
                
                if(AccountUtil.RUN_TRIGGER_AFTER_UPDATE){
                    AccountUtil.activateLicence(trigger.newMap, trigger.oldMap);

                    AccountUtil.RUN_TRIGGER_AFTER_UPDATE = false; 
                }
            }
            
        } 


// ============= ALL OF THE BELOW WILL NEED TO BE MOVED INTO UTILITY CLASSES INSTEAD OF ADDING THEM HERE ========== //
// ============= AND THEN ADD THEM TO THE ABOVE IF STATEMENTS ===================================================== //

// ============= ALL OF THE BELOW WILL NEED TO BE MOVED INTO UTILITY CLASSES INSTEAD OF ADDING THEM HERE ========== //
// ============= AND THEN ADD THEM TO THE ABOVE IF STATEMENTS ===================================================== //

// ============= ALL OF THE BELOW WILL NEED TO BE MOVED INTO UTILITY CLASSES INSTEAD OF ADDING THEM HERE ========== //
// ============= AND THEN ADD THEM TO THE ABOVE IF STATEMENTS ===================================================== //

// ============= ALL OF THE BELOW WILL NEED TO BE MOVED INTO UTILITY CLASSES INSTEAD OF ADDING THEM HERE ========== //
// ============= AND THEN ADD THEM TO THE ABOVE IF STATEMENTS ===================================================== //


        if (trigger.isAfter && trigger.isInsert){
        
            List<Id> OrgIds = new List<Id>();

            for (Account org : trigger.new){
                if (trigger.isInsert && org.IsPersonAccount ==false && org.Suppress_Default_Role__c!=true ){
                    OrgIds.add(org.Id);                                                    
                }   
                // insert personal account create partnership
                // LW - removed 2/01/2014
            }
            
            if(!OrgIds.isEmpty())
                AccountUtil.createCustomerRole(OrgIds);
        }

        if ( (trigger.isAfter && trigger.isInsert) || (trigger.isBefore && trigger.isUpdate) ){
              /*** START OF UPDATE DYU MPB 12-AUG-2016 -  Validate if MPB Account  ***/ 
            List<Account> accountList = new List<Account>();
            accountList = AccountUtil.mpbFilter(trigger.new, trigger.isInsert);
            if(accountList.size() > 0)
                AccountUtil.PopulateAccountRootID(accountList, trigger.isInsert); 
            /*** END OF UPDATE DYU MPB 12-AUG-2016 ***/
        }

        if (trigger.isBefore && trigger.isDelete){
            
            List<Account> delAcctList = new List<Account>();
            
            for (Account acct : trigger.old){
                if (acct.IsPersonAccount <> true)
                    delAcctList.add(acct);
            }
            
            if (!delAcctList.isEmpty()){
                DeletedRecordUtil.createDeletedRecord(delAcctList, 'Account');  
                DeletedRecordUtil.resetRootId(delAcctList);
            }
        }
        
        if (trigger.isAfter && trigger.isUnDelete){
            
            List<Account> undelAcctList = new List<Account>();
            
            for (Account acct : trigger.new){
                if (acct.IsPersonAccount <> true)
                    undelAcctList.add(acct);
            }
            
            if (!undelAcctList.isEmpty()){
                DeletedRecordUtil.undeleteDeletedRecord(undelAcctList); 
            }
        }     
        
        if (trigger.isAfter && trigger.isUpdate){
            DeletedRecordUtil.deactivateActivateAccount(trigger.newMap, trigger.oldMap, trigger.new);
            AccountUtil.ignoreOutOfSyncUpdates(trigger.newMap, trigger.oldMap);            
        }     
        
        if (trigger.isBefore &&  trigger.isUpdate){
            List <Account> oldList = new List<Account>();           
            List <Account> newList = new List <Account>();          
            List <Id> acctPrevOwner = new List <Id>();          
            
            for (Account acct: trigger.old){
                System.debug('### NewMap :' + Trigger.newMap.get(acct.id).OwnerId + '; ### OldMap :' + Trigger.oldMap.get(acct.Id).OwnerId);
                if (Trigger.newMap.get(acct.id).OwnerId != Trigger.oldMap.get(acct.Id).OwnerId ){
                    oldList.add (acct);
                    newList.add (Trigger.newMap.get(acct.id));
                    acctPrevOwner.add (Trigger.oldMap.get(acct.Id).OwnerId);
                }
            }
            AccountUtil.updateAccountOwnerEmail(newList, oldList, acctPrevOwner);
        
            // Sept 2013: Check for 'Is Conveyancer?' checkbox and call utility method
            List <Account> acctCon = new List<Account>();
            for (Account acctChanged: trigger.new) {
                if(acctChanged.Conveyancer_Is_a__c == true && acctChanged.Conveyancer_Number__c == null) {
                    acctCon.add(acctChanged);
                }       
            }
            if( !acctCon.isEmpty() ) AccountUtil.generateConveyancerNumber(acctCon);
        }
        
        if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            /*** START OF UPDATE DYU MPB 12-AUG-2016 -  Validate if MPB Account  ***/ 
            List<Account> accountList = new List<Account>();
            accountList = AccountUtil.mpbFilter(trigger.new, trigger.isInsert);
            if(accountList.size() > 0){
                SegmentationUtil.updateHubCatchment(accountList);   
                AccountUtil.assignSalesDirector(accountList);  
            } 
            /*** END OF UPDATE DYU MPB 12-AUG-2016 ***/

            //SegmentationUtil.updateSalesSegment(trigger.new); *****Commenting out based on CR 23*****
                       
        }        

        //Used for updating non-formula score field for Individual
        // LW - removed 2/01/2014
        //      The functionality is now implemented through workflow on Contact object.
    }
}