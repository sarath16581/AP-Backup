/**
  * @author       : eugene.jandusay@auspost.com.au
  * @date         : 26/07/2016
  * @description  : Handler Class for Account object trigger which includes context-specific methods 
                    that are automatically called when a trigger is executed
--------------------------------------- History --------------------------------------------------                      
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
26.04.2016  L. Lavapie(Cloud Sherpas)         Commented out checkPrimaryContact
05.05.2016  L. Lavapie(Cloud Sherpas)         Added checkLegalEntityNPCIU, checkNominatedContactEmail,checkLEUpdate
15.05.2016  Andrew Judd(Salesforce.com)       Renamed checkLegalEntityNPCIU to checkLicenceInsert
11.06.2016  Kenny Liew (Salesforce.com)       Logic added for After Insert to cater for MyPost Business' Lead Conversion against Person Accounts
12.08.2016  Davey Yu (Accenture)              MPB - Exclude process on UpdateHubcatchment for MPB Accounts and during insert operation only
11/07/2016  Eugene Jandusay                   Created New Class to make account trigger cleanup and follow the standards and improve the account trigger performance
26.08.2016    Kalpita Talwadekar              Updated method to add holding role reference methods and remove sync with SAP method as converted to validation rule.
04.07.2019    Disha Kariya                    Renamed method updateNetworkManager to updateNetworkManagerAndStateAdmin
04.08.2020   Swati Mogadala                    accUtil.activateLicence() moved outside if loop in afterHandler() isUpdate to handle PartialBulksave which is affecting licenses
                                              and not letting them cease as the method does not execute 
02.12.2020   SaiSwetha Pingali                 Fix for guest user access issues to avoid duplicate Holding Role references being created after the activation of CRUD "Secure Guest users Sharing settings and record access"
22.02.2021    L. Serafico (Mav3rik)           Added updateAccountTeamForLPO to add/update Team to allow Accounts to be visible to LPO
1/12.2023		K. McGuire				OPC Replacement - update incremental and retained reveue for line items of reparented accounts
**/

public with sharing class AccountTriggerHandler{

    // class Variables
    private static AccountTriggerUtility accUtil;    // Helper class variable to call methods based on scenario
    //spingali - Added a inner class to elevate sharing access to Guest users.
    private static AccountTriggerUtility.AccessHoldingRoleandUser accHoldRole ;

    /**
      * @description       This method is invoked from trigger which in-turn calls the handlers
                           for before and after event.
      * @param             NA 
      * @return            Void
      * @throws            NA
      */
    public static void execute(){

        accUtil = new AccountTriggerUtility();
        //spingali - Inner class AccessHoldingRoleandUser executes without sharing for guest users to be able to access data.
        accHoldRole = new AccountTriggerUtility.AccessHoldingRoleandUser();


        // Check for event type of trigger
        if(Trigger.isBefore){
            beforeHandler();        // invoke of before handler
        }
        else if(Trigger.isAfter){
            afterHandler();         // invoke of after handler
        }
    }

    /**
      * @description       This method is handler for before events invoked by execute method.
                           Method invokes the helper class methods based on the scenario.                       
      * @param             NA 
      * @return            Void
      * @throws            NA
      */
    private static void beforeHandler(){
        // Check for type of operation
        if(Trigger.isInsert){
            // Methods to be invoked for before insert event   
            if(AccountTriggerUtility.RUN_TRIGGER_BEFORE_INSERT){
                AccountTriggerUtility.RUN_TRIGGER_BEFORE_INSERT = false;
                accUtil.CopyNameonCreate(trigger.new);
                accUtil.generateReversePhoneFields(trigger.new);
                accUtil.verifyDuplicateLicence(trigger.new, null);
                accUtil.updateNetworkManagerAndStateAdmin(trigger.new, null);
                // Uncommented the following as preparation for prod go live of LIPOMS              
                accUtil.checkLicenceInsert(trigger.new);
                //method to insert holding role reference if does not exist
                accUtil.insertHoldingROleRef();
                /*** START OF UPDATE DYU MPB 12-AUG-2016 -  Validate if MPB Account  ***/
                List<Account> accountList = new List<Account>();
                accountList = AccountTriggerUtility.mpbFilter(trigger.new, trigger.isInsert);
                if(!accountList.isEmpty()){
                    //accUtil.PopulateAccountRootID(trigger.new, trigger.isInsert); 
                    SegmentationUtil.updateHubCatchment(accountList);
                    accUtil.assignSalesDirector(accountList);
                }

            }
        }
        else if(Trigger.isUpdate){
            // Methods to be invoked for before update event
            if(AccountTriggerUtility.RUN_TRIGGER_BEFORE_UPDATE){
                AccountTriggerUtility.RUN_TRIGGER_BEFORE_UPDATE = false;
                accUtil.lockVerifiedData(trigger.new,(Map<Id,Account>)trigger.oldMap);
                accUtil.generateReversePhoneFields((Map<Id,Account>)trigger.newMap, (Map<Id,Account>)trigger.oldMap);
                accUtil.verifyDuplicateLicence(trigger.new,(Map<Id,Account>)trigger.oldMap);
                accUtil.updateNetworkManagerAndStateAdmin(trigger.new, (Map<Id,Account>)trigger.oldMap);
                accUtil.checkNominatedContactEmail(trigger.new,(Map<Id,Account>)trigger.oldMap);
                accUtil.checkLEUpdate(trigger.new,(Map<Id,Account>)trigger.oldMap);
                accUtil.beforeUpdateAccOwnerEmail(trigger.old,(Map<Id,Account>)trigger.oldMap,(Map<Id,Account>)trigger.newMap);
                List<Account> accountList = new List<Account>();
                accountList = AccountTriggerUtility.mpbFilter(trigger.new, trigger.isInsert);
                if(!accountList.isEmpty()) {
                    accUtil.PopulateAccountRootID(accountList, trigger.isInsert);
                    SegmentationUtil.updateHubCatchment(accountList);
                    accUtil.assignSalesDirector(accountList);
                }
                accUtil.beforeGenerateConNumber(trigger.new);
                accUtil.updateAccountTeamForLPO(trigger.oldMap, trigger.newMap);
            }
        }
        else if(Trigger.isDelete){
            // Methods to be invoked for before delete event
            if(AccountTriggerUtility.RUN_TRIGGER_BEFORE_DELETE){
                accUtil.beforeResetRoodId(trigger.old);
                accUtil.updateBAondelete(trigger.old);
            }
        }
    }

    /**
      * @description       This method is handler for after events invoked by execute method.
                           Method invokes the helper class methods based on the scenario.                          
      * @param             NA 
      * @return            Void
      * @throws            NA
      */
    private static void afterHandler() {
        // Check for type of operation
        if(Trigger.isInsert){
            // Methods to be invoked for after insert event
            if(AccountTriggerUtility.RUN_TRIGGER_AFTER_INSERT){
                AccountTriggerUtility.RUN_TRIGGER_AFTER_INSERT = false;
                accUtil.beforeCreateCustomerRole(trigger.new);
                List<Account> accountList = new List<Account>();
                accountList = AccountTriggerUtility.mpbFilter(trigger.new, trigger.isInsert);
                if(!accountList.isEmpty()) {
                    accUtil.PopulateAccountRootID(accountList, trigger.isInsert);
                }
                //accutil.assignHoldingRoleAndAccMan(trigger.new);
                //spingali - Moved method 'assignHoldingRoleAndAccMan' to without sharing class for guest users access.
                accHoldRole.assignHoldingRoleAndAccMan(trigger.new);
                if(!System.isFuture()) {
                    accUtil.beforeConvLeadPersAcc(trigger.new);
                }
                accUtil.updateAccountTeamForLPO(trigger.oldMap, trigger.newMap);
                accUtil.updateLIneItemRevenues(trigger.new);
            }
        }
        else if(Trigger.isUpdate){
            // Methods to be invoked for after update event    
            if(AccountTriggerUtility.RUN_TRIGGER_AFTER_UPDATE){
                AccountTriggerUtility.RUN_TRIGGER_AFTER_UPDATE = false;
                //--kalpita moved to before update--  accUtil.checkLEUpdate(trigger.new,(Map<Id,Account>)trigger.oldMap);
                //--kalpita moved to before update-- accUtil.beforeUpdateAccOwnerEmail(trigger.old,(Map<Id,Account>)trigger.oldMap,(Map<Id,Account>)trigger.newMap);
                //accUtil.PopulateAccountRootID(trigger.new, trigger.isInsert);
                DeletedRecordUtil.deactivateActivateAccount((Map<Id,Account>)trigger.newMap, (Map<Id,Account>)trigger.oldMap, trigger.new);
                //accUtil.ignoreOutOfSyncUpdates((Map<Id,Account>)trigger.newMap, (Map<Id,Account>)trigger.oldMap);
            }
            accUtil.activateLicence((Map<Id,Account>)trigger.newMap, (Map<Id,Account>)trigger.oldMap);
            accUtil.updateLIneItemRevenues((List<Account>)trigger.new, (Map<Id,Account>)trigger.oldMap);
        }
        else if(Trigger.isDelete){
            // Methods to be invoked for after delete event
            if(AccountTriggerUtility.RUN_TRIGGER_AFTER_DELETE){
                AccountTriggerUtility.RUN_TRIGGER_AFTER_DELETE = false;
            }
        }
        else if(Trigger.isUndelete){
            // Methods to be invoked for after undelete event
            if(AccountTriggerUtility.RUN_TRIGGER_ISUNDELETE){
                AccountTriggerUtility.RUN_TRIGGER_ISUNDELETE = false;
                accUtil.beforeUndeleteDeletedRec(trigger.new);
            }
        }
    }
}