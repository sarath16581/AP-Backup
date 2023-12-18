/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 30/05/2016    
  * @description  : This Class is Batch class to monitor the portal customers being merged and 
                    to flag the loosing record and merge the loosing record details into the winning record
  */
/*******************************  History ************************************************
2023-10-02    Boris Bachovski    Refactor to use IsInactiveCustomer__c instead of is_Inactive_Customer__c
*******************************  History ************************************************/
global without sharing class MyPost_PortalCustomerMerge_Batchable implements Database.Batchable<SObject>, Database.Stateful  {

    private static final String CASE_SOBJ = 'Case';
    private static final String CLOSED_DATE = 'ClosedDate';
    private static final String CREATED_DATE = 'CreatedDate';
    private static final String CREATED_BY_ID = 'CreatedById';
    private static final String LAST_MOD_DATE = 'LastModifiedDate';
    private static final String LAST_MOD_ID = 'LastModifiedById';
    private static final String NAME = 'Name';
    private static final String COMMA_SEP = ',';    
    private List<Sobject> relatedRecordsReparent = new List<SObject>();
    private List<Sobject> deleteLoosingRecords = new List<SObject>();
    private map<Id,List<Attachment>> insertAttList = new map<Id,List<Attachment>>();
    private List<Attachment> attInsert = new List<Attachment>();
            
    /** 
      * @name: MyPost_CustomerMerge_Batchable()
      * @desciption: batch class constructor
      * @param: Database.BatchableContext
      * @return: Database.QueryLocator
      *
      */
    global MyPost_PortalCustomerMerge_Batchable () { }
    
    /** 
      * @name: start()
      * @desciption: start method to run the query and get the results
      * @param: Database.BatchableContext
      * @return: Database.QueryLocator
      *
      */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('Account'.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
         String selects = '';
        //for case fields creating dynamic query to include all fields for cloning.
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                     if(!(CLOSED_DATE.equalsIgnoreCase(fd.getName()) || CREATED_DATE.equalsIgnoreCase(fd.getName()) || 
                        CREATED_BY_ID.equalsIgnoreCase(fd.getName()) || LAST_MOD_DATE.equalsIgnoreCase(fd.getName()) ||
                        LAST_MOD_ID.equalsIgnoreCase(fd.getName())) && !NAME.equalsIgnoreCase(fd.getName()))
                        selectFields.add(fd.getName());
                }
            }
        }
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + COMMA_SEP ;
            }
            if (selects.endsWith(COMMA_SEP)){selects = selects.substring(0,selects.lastIndexOf(COMMA_SEP));}

        }
        //create final query  
        String query = 'SELECT Id , IsCustomerPortal, PersonContactId, ' + selects + ', (Select Id, ContactId, AccountId from Cases), (Select Id from Contacts), ' + 
                       ' (Select Id, Name, Parentid FROM Attachments) ' +
                       ' FROM ' + ' Account' + ' WHERE ' + 
                       ' Winning_Master_Record__pc != null and IsInactiveCustomer__pc = true ' +
                       ' and RecordType.Name = \'Consumer\' ';

        return Database.getQueryLocator(query);
    }

    /** 
      * @name: execute()
      * @desciption: execution code lies in this method- here we get the winning and loosing accounts and perform the merge
      * @param: Database.BatchableContext BC, List<SObject> customersToMerge
      * @return: NA
      *
      */
    global void execute(Database.BatchableContext BC, List<SObject> customersToMerge) {
       try {
           Map<Id,List<Account>> portalLoosingAccMap = new Map<Id,List<Account>>();
           Map<String,String> accPersonContIdMap = new Map<String,String>();
           Map<String,List<NPSSurvey__c>> npsMap = new Map<String,List<NPSSurvey__c>>();
           Map<String,List<Compensation__c>> compMap = new Map<String,List<Compensation__c>>();
           Map<String,List<AuthorisedContacts__c>> relConMap = new Map<String,List<AuthorisedContacts__c>>();
           
           List<Account> loosingAccounts = (List<Account>)customersToMerge;
           Map<Account,List<Account>> winLooseAcctMap = new Map<Account,List<Account>>();
           Map<Account,List<Account>> portalWinLooseAcctMap = new Map<Account,List<Account>>();
           Set<Id> accKeyId = new Set<Id>();
           Map<Id,List<Account>> winLoseIdMap = new Map<Id,List<Account>>();
           Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('Account'.toLowerCase()).getDescribe().Fields.getMap();
           list<string> selectFields = new list<string>();
           String selects = '';
           Set<Id> lst = new Set<Id>();
           system.debug('--'+loosingAccounts);
           //get the winning record for each loosing customer record 
           for(Account lsAct : loosingAccounts) {   
               system.debug('case--'+lsAct.cases); 
               accPersonContIdMap.put(lsAct.Id,lsAct.PersonContactId);
               npsMap.put(lsAct.PersonContactId,new list<NPSSUrvey__c>());
               compMap.put(lsAct.PersonContactId,new list<Compensation__c>());
               relConMap.put(lsAct.PersonContactId,new list<AuthorisedContacts__c>());
               if(!lsAct.isCustomerPortal) {
                   if(!winLoseIdMap.keySet().contains(lsAct.Winning_Master_Record__pc)) {
                       winLoseIdMap.put(lsAct.Winning_Master_Record__pc,new List<Account>());
                   }
                   winLoseIdMap.get(lsAct.Winning_Master_Record__pc).add(lsAct);
                   lst.add(lsAct.Winning_Master_Record__pc);
               }
               else {
                    if(!portalLoosingAccMap.keySet().contains(lsAct.Winning_Master_Record__pc)) {
                       portalLoosingAccMap.put(lsAct.Winning_Master_Record__pc,new List<Account>());
                    }
                    portalLoosingAccMap.get(lsAct.Winning_Master_Record__pc).add(lsAct);
                    lst.add(lsAct.Winning_Master_Record__pc);
               }
               system.debug('--'+portalLoosingAccMap);
            }
             
            system.debug('--'+portalLoosingAccMap);
            system.debug('--'+lst);
            
            //get all parent/winning account records
            //for case fields creating dynamic query to include all fields for cloning.
            if (fMap != null) {
                for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    if (fd.isCreateable()){ // field is creatable
                        if(!(CLOSED_DATE.equalsIgnoreCase(fd.getName()) || CREATED_DATE.equalsIgnoreCase(fd.getName()) || 
                        CREATED_BY_ID.equalsIgnoreCase(fd.getName()) || LAST_MOD_DATE.equalsIgnoreCase(fd.getName()) ||
                        LAST_MOD_ID.equalsIgnoreCase(fd.getName())) && !NAME.equalsIgnoreCase(fd.getName()))
                            selectFields.add(fd.getName());
                    }
                }
            }
    
            if (!selectFields.isEmpty()){
                for (string s:selectFields){
                selects += s + COMMA_SEP;
                }
                if (selects.endsWith(COMMA_SEP)){selects = selects.substring(0,selects.lastIndexOf(COMMA_SEP));}
    
            }
            //create final query to get the winnig accounts
            String query = 'SELECT Id , IsCustomerPortal, PersonContactId,  ' + selects + ' FROM ' + ' Account' + ' WHERE ' + 
                           ' Id in :lst ';
            Map<String,List<Account>> map2 = new map<String,List<Account>>();         
            for (Account winAccounts : Database.query(query)) {
                system.debug(winAccounts.isCustomerPortal);
                system.debug(winAccounts);
                //loop through all winning accounts to create a map of winning account and list of loosing accounts
                if(!accKeyId.contains(winAccounts.Id) && !winAccounts.isCustomerPortal) {
                    if (portalLoosingAccMap.keyset().contains(winAccounts.Id)) {
                        portalWinLooseAcctMap.put(winAccounts, portalLoosingAccMap.get(winAccounts.Id) );
                        if(!map2.keySet().contains(winAccounts.Id)) map2.put(winAccounts.Id, portalLoosingAccMap.get(winAccounts.Id) );
                        else map2.get(winAccounts.Id).addAll(portalLoosingAccMap.get(winAccounts.Id) );
                        accKeyId.add(winAccounts.Id);
                    }
                }
                else if(!accKeyId.contains(winAccounts.Id) && winAccounts.isCustomerPortal) {
                    
                    if(winLoseIdMap.keyset().contains(winAccounts.Id)) {
                        portalWinLooseAcctMap.put(winAccounts, winLoseIdMap.get(winAccounts.Id) );
                        if(!map2.keySet().contains(winAccounts.Id)) map2.put(winAccounts.Id, winLoseIdMap.get(winAccounts.Id) );
                        else map2.get(winAccounts.Id).addAll(winLoseIdMap.get(winAccounts.Id) );
                        accKeyId.add(winAccounts.Id);
                    }
                    else if (portalLoosingAccMap.keyset().contains(winAccounts.Id)) {
                        portalWinLooseAcctMap.put(winAccounts, portalLoosingAccMap.get(winAccounts.Id) );
                        if(!map2.keySet().contains(winAccounts.Id)) map2.put(winAccounts.Id, portalLoosingAccMap.get(winAccounts.Id) );
                        else map2.get(winAccounts.Id).addAll(portalLoosingAccMap.get(winAccounts.Id) );
                        accKeyId.add(winAccounts.Id);
                    }
                }
                system.debug(portalWinLooseAcctMap);
            }
            
            Map<Id,Contact> loosingRecmap = new Map<Id,Contact>();
            //get all child records for the contact 
            for(Contact con: [Select Id, (Select Id, Contact__c from NPS_Surveys__r), (Select Id, Contact__c from Compensation__r), (Select Id, AuthorisingContact__c from AuthorisedContacts__r),
                              (Select Id, WhoId from Tasks),  (Select Id, ContactId from Cases), (Select Id, AuthorisedContact__c from Authorised_Contacts__r ), (Select Id, Related_Contact__c from Related_Contacts__r) 
                              from Contact where Id in :accPersonContIdMap.values() ]) {
                              system.debug('case--'+con.cases);
                loosingRecmap.put(con.Id,con);
            }
            
            
            
            for(Attachment att : [Select Id, Name, Body, Parentid  from Attachment where 
                                                        Parentid =:accPersonContIdMap.keySet()]) {
                if(!insertAttList.keySet().contains(att.Parentid)) {                                            
                    insertAttList.put(att.parentId,new List<Attachment>());
                }
                insertAttList.get(att.parentId).add(new Attachment(name = att.Name, body=att.body));
            }
            //merge portal based records
            Set<String> cId = new Set<String>();
            for(Account masterAcct : portalWinLooseAcctMap.keySet()) {
               //loop through all child records of loosing records
               system.debug('--'+portalWinLooseAcctMap);
               system.debug('--'+masterAcct);
               system.debug('--'+map2);        
                      
               for(Account loosingAcct : map2.get(masterAcct.Id) ) {
                   for(Case cse: loosingAcct.Cases ) {
                       if(!cId.contains(cse.Id)) {
                           cse.AccountId = masterAcct.Id;
                           cse.ContactId =  masterAcct.PersonContactId;
                           relatedRecordsReparent.add(cse);
                           cId.add(cse.Id);
                       }
                   }
                   for(Task tsk:  loosingRecmap.get(loosingAcct.PersonContactId).Tasks) {
                       if(loosingAcct.PersonContactId == tsk.WhoId) tsk.WhoId = masterAcct.PersonContactId;
                       else if(loosingAcct.PersonContactId == tsk.WhatId) tsk.WhatId = masterAcct.PersonContactId;
                       relatedRecordsReparent.add(tsk);
                   }
                   if(insertAttList!=null && !insertAttList.keySet().isEmpty() && insertAttList.get(loosingAcct.id)!=null) {
                       for(Attachment note: insertAttList.get(loosingAcct.id)) {
                           note.parentid = masterAcct.id;
                           attInsert.adD(note);
                           system.debug('--'+loosingAcct.id+'--'+attInsert);
                       }
                   }
                   for(NPSSurvey__c nps :loosingRecmap.get(loosingAcct.PersonContactId).NPS_Surveys__r) {
                       nps.Contact__c = masterAcct.PersonContactId;
                       relatedRecordsReparent.add(nps);
                   }
                   for(Compensation__c comp: loosingRecmap.get(loosingAcct.PersonContactId).Compensation__r) {
                       comp.Contact__c = masterAcct.PersonContactId;
                       relatedRecordsReparent.add(comp);
                   }
                   for(Case comp: loosingRecmap.get(loosingAcct.PersonContactId).Cases) {
                       if(!cId.contains(comp.Id)) {
                           comp.ContactId = masterAcct.PersonContactId;
                           relatedRecordsReparent.add(comp);
                           cId.add(comp.Id);
                       }
                   }
                   for(AuthorisedContacts__c relCont: loosingRecmap.get(loosingAcct.PersonContactId).AuthorisedContacts__r) {
                       relCont.AuthorisingContact__c = masterAcct.PersonContactId;
                       relatedRecordsReparent.add(relCont);
                   }
                   for(AuthorisedContacts__c relCont: loosingRecmap.get(loosingAcct.PersonContactId).Authorised_Contacts__r) {
                       relCont.AuthorisedContact__c = masterAcct.PersonContactId;
                       relatedRecordsReparent.add(relCont);
                   }
                   for(AuthorisedContacts__c relCont: loosingRecmap.get(loosingAcct.PersonContactId).Related_Contacts__r) {
                       relCont.Related_Contact__c = masterAcct.PersonContactId;
                       relatedRecordsReparent.add(relCont);
                   }
                   deleteLoosingRecords.add(loosingAcct );
               }
               //reparent the record
               
               //add to list of SObject to update
               if(!attInsert.isEmpty()) database.insert(attInsert); 
               //update SObject list for all child records               
               if(!relatedRecordsReparent.isEmpty()) { relatedRecordsReparent.sort(); database.update(relatedRecordsReparent); }
               //delete SObject list for loosing record
               if(!deleteLoosingRecords.isEmpty()) database.delete(deleteLoosingRecords,false);
              
               
           }
       }
       catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 
                                                    'MyPost_PortalCustomerMerge_Batchable', 'execute', 
                                                    null, LoggingLevel.ERROR);
        }
       
    }
    
    /** 
      * @name: finish()
      * @desciption: method to perform tasks once the batch is complete
      * @param: NA
      * @return: NA
      *
      */
    global void finish(Database.BatchableContext BC) { 
       
                     
    }   
    
}