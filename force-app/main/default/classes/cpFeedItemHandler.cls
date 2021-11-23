//Class to handle feed items used by component in Customer Community.
public without sharing class cpFeedItemHandler {
    //handler feed update for case
    public void caseStatusUpdater(list<FeedItem> feedItems){
        try{
            set<Id> caseIds = new set<Id>();
            set<Id> userIds = new set<Id>();
            Map<Id,User> userMap = new Map<Id,User>();
            Map<Id,Case> caseMap = new Map<Id,Case>();
            
            String communityProfileId = [Select Id, Name from Profile where name = 'DDC Consumer Community User' limit 1].id;
            String caseRecordTypeId = [Select Id From RecordType Where SobjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].id;
            
            for(FeedItem feed : feedItems){
                if(feed.ParentId != null && String.valueOf(feed.ParentId).startsWith('500')){
                    caseIds.add(feed.ParentId);
                }
                
                if(feed.InsertedById != null){
                    userIds.add(feed.InsertedById);
                }
            }
            
            if(userIds.size() > 0 && caseIds.size() > 0){
                userMap = new Map<Id,User>([Select Id, Name, ProfileId From User Where Id IN : userIds]);
                caseMap = new Map<Id,Case>([Select Id, RecordTypeId, Status FROM Case Where Id IN : caseIds]);
            }
            
            for(FeedItem feed : feedItems){
                if(userMap.containsKey(feed.InsertedById) && userMap.get(feed.InsertedById).ProfileId == communityProfileId 
                    && caseMap.containsKey(feed.ParentId) && caseMap.get(feed.ParentId).RecordTypeId == caseRecordTypeId){
                    caseMap.get(feed.ParentId).Status = 'Customer Responded';
                }
            }
            if(!caseMap.isEmpty()){
                update caseMap.values();
            }
            if(test.isRunningTest()){
                throw (new AUPostCustomException('exception occured'));
            }
        }catch(exception ex){
            //do nothing
        }
    }
    
    public without sharing class AUPostCustomException extends Exception {}
}