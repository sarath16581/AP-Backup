/**
 	Class to fetch BannedWords through callout via cpMetadataservice class
**/

public with sharing class cpBannedWordDetector {
    
    public static set<String> bannedWords = new set<String>();
    public static set<String> fetchBannedWords(String userSessionId){ 
        try{
            cpMetadataService.MetadataPort service = new cpMetadataService.MetadataPort();
            service.SessionHeader = new cpMetadataService.SessionHeader_element();
            service.SessionHeader.sessionId = userSessionId;
            Community_Settings__mdt communitySettingMetadata = [SELECT DeveloperName,Entity_Name__c,Entity_Value__c 
                                                                FROM Community_Settings__mdt 
                                                                WHERE DeveloperName = 'Banned_Keywords_List_Setting' LIMIT 1];
            String keywordListFullName = communitySettingMetadata.Entity_Value__c;
            
                if(String.isNotBlank(keywordListFullName)){
                    cpMetadataService.IReadResult results = service.readMetadata('KeywordList',new String[] {keywordListFullName});
                    cpMetadataService.Metadata[] records = results.getRecords();
                    //system.debug('==cpBannedWordDetector results records==>'+records);
                    for(cpMetadataService.Metadata keyList : records){
                        cpMetadataService.KeywordLists keys = (cpMetadataService.KeywordLists) keyList;
                        for(cpMetadataService.Keyword key : keys.keywords){
                            bannedWords.add(key.keyword);
                        }
                    }
                }
            //system.debug('==bannedWords==>'+bannedWords);
            return bannedWords;
        }catch (exception ex){
            return null;
        }
    }
}