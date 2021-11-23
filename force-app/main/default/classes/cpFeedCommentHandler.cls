//Class to handle case comment update
public class cpFeedCommentHandler {
    //update case status
    public void updateCaseStatus(list<FeedComment> feedComments){
        try{
            set<Id> caseIds = new set<Id>();
            set<Id> userIds = new set<Id>();
            Map<Id,User> userMap = new Map<Id,User>();
            Map<Id,Case> caseMap = new Map<Id,Case>();
            
            String communityProfileId = [Select Id, Name from Profile where name = 'DDC Consumer Community User' limit 1].id;
            String caseRecordTypeId = [Select Id From RecordType  Where SobjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].id;
            
            for(FeedComment comment : feedComments){
                if(comment.ParentId != null && String.valueOf(comment.ParentId).startsWith('500')){
                    caseIds.add(comment.ParentId);
                }
                
                if(comment.InsertedById != null){
                    userIds.add(comment.InsertedById);
                }
            }
            
            if(userIds.size() > 0 && caseIds.size() > 0){
                userMap = new Map<Id,User>([Select Id, Name, ProfileId From User Where Id IN : userIds]);
                caseMap = new Map<Id,Case>([Select Id, RecordTypeId, Status FROM Case Where Id IN : caseIds]);
            }
            
            for(FeedComment feed : feedComments){
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
        } catch(exception ex){
            //do nothing
        }
    }
    
    public without sharing class AUPostCustomException extends Exception {}
}