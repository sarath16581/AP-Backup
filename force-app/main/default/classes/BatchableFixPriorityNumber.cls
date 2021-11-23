global class BatchableFixPriorityNumber implements Database.Batchable<sObject> {
  
  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator('Select id from Case where PriorityNumber__c = null AND recordtype.developername like \'SSSW%\'');
  }
  
  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    List<Case> list_cases2update = (List<Case>)scope;
    
    for (Case c : list_cases2update)
    {
        c.Bypass_Data_enforcement__c = true;
    }
    
    // will fire Contact before/after update trigger.
    // as currently the trigger logic creteria not matched, the fired trigger won't do anything
    //update list_contact2update;
    Database.update(list_cases2update , false);
  }
  
  global void finish(Database.BatchableContext BC) { }
}