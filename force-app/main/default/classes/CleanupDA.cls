global class CleanupDA implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id FROM CEPARC__DataArchiva_Purge_Cache__c');
    }
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        Database.delete(scope,false);
    }
    public void finish(Database.BatchableContext context)
    {
        
    }
}