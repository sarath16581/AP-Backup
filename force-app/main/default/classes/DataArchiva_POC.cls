public class DataArchiva_POC {
    public void intiateDataArchiva_POC_PurgerFilesBatch(){
        
        Map<String,DataArchiva_POC_PurgerFilesBatch.PurgingJobInfo> purgingJobInfoMap = getpurgingJobInfo();
        boolean processedValue = false;
        Database.executeBatch(new DataArchiva_POC_PurgerFilesBatch(purgingJobInfoMap, processedValue), integer.valueOf(CEPARC__DataArchiva_App_Setting__c.getOrgDefaults().CEPARC__Purge_Files_Batch_Size__c));
    }
    
    private Map<String,DataArchiva_POC_PurgerFilesBatch.PurgingJobInfo> getpurgingJobInfo(){
        // String namespace = new ArchivaUtil().getNamespace();
        // namespace = namespace == null ? '' : namespace+'__';
        Map<String,DataArchiva_POC_PurgerFilesBatch.PurgingJobInfo> purgingJobInfoMap = new Map<String,DataArchiva_POC_PurgerFilesBatch.PurgingJobInfo>();
        Map<String,Id> objNameVSDAConfigIdMap = new Map<String,Id>();
        Map<String,String> objNameVsPrefixMap = new Map<String,String>();
        integer remainingQueriesCount;
        
        for(AggregateResult ar :[SELECT COUNT(Id), CEPARC__Object_Name__c FROM CEPARC__DataArchiva_Purge_Cache__c GROUP BY CEPARC__Object_Name__c LIMIT 50000]) {
            DataArchiva_POC_PurgerFilesBatch.PurgingJobInfo purgingJobInfo = new DataArchiva_POC_PurgerFilesBatch.PurgingJobInfo();
            purgingJobInfo.eligibleRecCount = integer.valueOf(ar.get('expr0'));
            purgingJobInfoMap.put(String.valueOf(ar.get('CEPARC__Object_Name__c')), purgingJobInfo);
        }
        
        // object name versus da config id map
        for(CEPARC__Archiva_Configuration__c daConfig :[SELECT Id, CEPARC__Object_Name__c FROM CEPARC__Archiva_Configuration__c WHERE CEPARC__Object_Name__c IN :purgingJobInfoMap.keySet()]){
            objNameVSDAConfigIdMap.put(daConfig.CEPARC__Object_Name__c, daConfig.id);
        }
        
        // getting object key prefix
        for(Schema.DescribeSobjectResult objDesc :Schema.describeSObjects(new List<String>(purgingJobInfoMap.keySet()))) {
            objNameVsPrefixMap.put(objDesc.getName(), objDesc.getKeyPrefix());
        }
        
        // filtering
        remainingQueriesCount = getRemainingQueriesCount();
        for(String objName :purgingJobInfoMap.keySet()) {
            
            if(remainingQueriesCount > 0){
                // check for files
                Id daConfgiId = objNameVSDAConfigIdMap.get(objName);
                if(Database.countQuery('SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :daConfgiId LIMIT 1') == 0){
                    purgingJobInfoMap.get(objName).hasFiles = false;
                }else if(Database.countQuery('SELECT COUNT() FROM Attachment WHERE ParentId = :daConfgiId LIMIT 1') == 0){ //TODO: change the query for attachments
                    purgingJobInfoMap.get(objName).hasAttachments = false;
                } 
                remainingQueriesCount--;
                
            } else {	break;	}
            
            if(remainingQueriesCount > 0){
                // check for fht records
                if([SELECT CEPARC__Object_Name_Prefix__c FROM CEPARC__Archiva_History_Tracking__b WHERE CEPARC__Object_Name_Prefix__c = :objNameVsPrefixMap.get(objName) LIMIT 1].size() == 0){
                    purgingJobInfoMap.get(objName).hasFHT = false;
                }
                remainingQueriesCount--;
                
            } else {	break;	}
            
            if(remainingQueriesCount > 0){
                // check for share records
                if([SELECT CEPARC__Object_Name_Prefix__c FROM CEPARC__Archiva_Share__b WHERE CEPARC__Object_Name_Prefix__c = :objNameVsPrefixMap.get(objName) LIMIT 1].size() == 0){
                    purgingJobInfoMap.get(objName).hasShare = false;
                }
                remainingQueriesCount--;
                
            } else {	break;	}
        }
        
        System.debug('[DataArchivaPurgeQueueable.getpurgingJobInfo] purgingJobInfoMap : '+JSON.serialize(purgingJobInfoMap));
        return purgingJobInfoMap;
    }
    
    private integer getRemainingQueriesCount(){
        integer count;
        count = Limits.getLimitQueries() - Limits.getQueries();
        return count;
    }
    
}