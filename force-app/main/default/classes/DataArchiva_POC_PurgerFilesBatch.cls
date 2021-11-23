public class DataArchiva_POC_PurgerFilesBatch implements Database.Batchable<sObject>, Database.Stateful{
    private boolean processedValue;
    private Map<Id,String> daConfigIdVSObjNameMap = new Map<Id,String>();
    private Set<Id> daPurgeCacheIdSet = new Set<Id>();
    private String daConfigPrefix;
    private Set<Id> parentIdSet = new Set<Id>();
    
    public DataArchiva_POC_PurgerFilesBatch(){
        for(CEPARC__Archiva_Configuration__c daConfig :[SELECT Id, CEPARC__Object_Name__c FROM CEPARC__Archiva_Configuration__c LIMIT 1000]){
            daConfigIdVSObjNameMap.put(daConfig.Id, daConfig.CEPARC__Object_Name__c);
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> parentIdPatternSet = new Set<String>();
        daConfigPrefix = CEPARC__Archiva_Configuration__c.sobjecttype.getDescribe().getKeyPrefix();
        final integer QUERY_LIMIT = integer.valueOf(CEPARC__DataArchiva_App_Setting__c.getOrgDefaults().CEPARC__Purge_Cache_Query_Limit__c);
        String pickListParentIds='';
        
        for(CEPARC__DataArchiva_Purge_Cache__c daPurgeCache :Database.query('SELECT Id, CEPARC__Id_Indexed__c, CEPARC__Object_Name__c FROM CEPARC__DataArchiva_Purge_Cache__c'+ 
                                                                            ' WHERE CEPARC__Processed__c = false LIMIT '+QUERY_LIMIT))
        {
            parentIdSet.add(daPurgeCache.CEPARC__Id_Indexed__c);                  
            daPurgeCacheIdSet.add(daPurgeCache.Id);
            parentIdPatternSet.add('%'+daPurgeCache.CEPARC__Id_Indexed__c+'%');
        }
        
        return Database.getQueryLocator('SELECT Id,Description,CEPARC__ParentId__c,ContentDocumentId FROM ContentVersion' 
                                        +' WHERE CEPARC__Is_Attachment__c = false AND (CEPARC__ParentId__c IN: parentIdSet OR Description LIKE :parentIdPatternSet)');
        
        /*return Database.getQueryLocator('SELECT Id,Description,LatestPublishedVersion.ParentId__c,LatestPublishedVersionId FROM ContentDocument' 
                                        +' WHERE LatestPublishedVersion.Is_Attachment__c = false AND (LatestPublishedVersion.ParentId__c IN: parentIdSet OR Description LIKE :parentIdPatternSet)');*/
        
    }
    
    public void execute(Database.BatchableContext BC, List<ContentVersion> scope){
        System.debug('===='+scope.size());
    }
    
    public void finish(Database.BatchableContext BC){}
}