/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 15/03/2015    
  * @description  : This Class is Batch class to monitor the customers being merged and 
                    to flag the loosing record and merge the loosing record details into the winning record
  */
/*******************************  History ************************************************
    Date                User                                        Comments
2023-10-02    Boris Bachovski    Refactor to use IsInactiveCustomer__c instead of is_Inactive_Customer__c
*******************************  History ************************************************/
global without sharing class MyPost_CustomerMerge_Batchable implements Database.Batchable<SObject> {

    private static final String CASE_SOBJ = 'Case';
    private static final String CLOSED_DATE = 'ClosedDate';
    private static final String CREATED_DATE = 'CreatedDate';
    private static final String CREATED_BY_ID = 'CreatedById';
    private static final String LAST_MOD_DATE = 'LastModifiedDate';
    private static final String LAST_MOD_ID = 'LastModifiedById';
    private static final String NAME = 'Name';
    private static final String COMMA_SEP = ',';

    /** 
      * @name: MyPost_CustomerMerge_Batchable()
      * @desciption: batch class constructor
      * @param: Database.BatchableContext
      * @return: Database.QueryLocator
      *
      */
    global MyPost_CustomerMerge_Batchable() { }
    
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
        String query = 'SELECT Id , ' + selects + ' FROM ' + ' Account' + ' WHERE ' + 
                       ' Winning_Master_Record__pc!=null and IsInactiveCustomer__pc = true ' +
                       ' and RecordType.Name = \'Consumer\' and IsCustomerPortal != true ';

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
       
           List<Account> loosingAccounts = (List<Account>)customersToMerge;
           Map<Account,List<Account>> winLooseAcctMap = new Map<Account,List<Account>>();
           Set<Id> accKeyId = new Set<Id>();
           Map<Id,List<Account>> winLoseIdMap = new Map<Id,List<Account>>();
           Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('Account'.toLowerCase()).getDescribe().Fields.getMap();
           list<string> selectFields = new list<string>();
           String selects = '';
          // Set<Id> lst = winLoseIdMap.keySet();
           
           //get the winning record for each loosing customer record 
           for(Account lsAct : loosingAccounts) {
               if(!winLoseIdMap.keySet().contains(lsAct.Winning_Master_Record__pc)) {
                   winLoseIdMap.put(lsAct.Winning_Master_Record__pc,new List<Account>());
               }
               winLoseIdMap.get(lsAct.Winning_Master_Record__pc).add(lsAct);
           }
           Set<Id> lst = winLoseIdMap.keySet();
           //get all parent/winning account records
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
                selects += s + COMMA_SEP;
                }
                if (selects.endsWith(COMMA_SEP)){selects = selects.substring(0,selects.lastIndexOf(COMMA_SEP));}
    
            }
            //create final query to get the winnig accounts
            String query = 'SELECT Id , ' + selects + ' FROM ' + ' Account' + ' WHERE ' + 
                           ' Id in :lst and  IsCustomerPortal != true ';
                     
            for (Account winAccounts : Database.query(query)) {
                system.debug('--here'+winAccounts);
                //loop through all winning accounts to create a map of winning account and list of loosing accounts
                if(!accKeyId.contains(winAccounts.Id)) {
                    accKeyId.add(winAccounts.Id);
                    winLooseAcctMap.put(winAccounts, winLoseIdMap.get(winAccounts.Id) ); 
                }
               // winLooseAcctMap.get(winAccounts) =  ;
                
            }
           
           //merge the records
           for(Account masterAcct : winLooseAcctMap.keySet()) {
               system.debug('--'+winLooseAcctMap);
               merge masterAcct winLooseAcctMap.get(masterAcct);
           }
           
       }
       catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 
                                                    'MyPost_CustomerMerge_Batchable', 'execute', 
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
    global void finish(Database.BatchableContext BC) { }   

    
}