/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 30/05/2016    
  * @description  : This Class is Batch class to monitor the portal customers 
                    linked to users and disable portal from user
  */
/*******************************  History ************************************************
2023-10-02    Boris Bachovski    Refactor to use IsInactiveCustomer__c instead of is_Inactive_Customer__c
*******************************  History ************************************************/
global class MyPost_PortalUserEdits implements Database.Batchable<sObject>{

    List<User> updateUsr = new List<User>();
    Set<id> portalContId = new Set<Id>();
    
    /** 
      * @name: start()
      * @desciption: method to query portal customers with inactive flag
      * @param: Database.BatchableContext
      * @return: Database.QueryLocator
      *
      */
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id , IsCustomerPortal, PersonContactId ' +
                       ' FROM Account WHERE ' + 
                       ' Winning_Master_Record__pc != null and IsInactiveCustomer__pc = true ' +
                       ' and IsCustomerPortal = true';
        return Database.getQueryLocator(query);
    }

    /** 
      * @name: execute()
      * @desciption: method to execute the query, grab the users and disable the portal flag
      * @param: Database.BatchableContext BC, List<sObject> scope
      * @return: NA
      *
      */
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        for(Account sobj: (List<Account>) scope) { portalContId.add(sObj.PersonContactId); }
        
        for(user usr: [Select Id from user where ContactId in :portalContId]) {
            usr.IsPortalEnabled = false; updateUsr.add(usr);
        }
        
        if(!updateUsr.isEmpty()) { database.update(updateUsr); }
    }

    /** 
      * @name: finish()
      * @desciption: method to perform after batch operations
      * @param: Database.BatchableContext
      * @return: NA
      *
      */
    global void finish(Database.BatchableContext BC){}

}