//Class to retrieve featured content related topic for customer community 
public without sharing class cpGetRelatedTopics {

    @AuraEnabled
    public static list<Topic> getrelatedTopics(String articleId , Integer noOfRecordsTofetch){
        try{
            //Fetch  user’s current community
            String communityId = Network.getNetworkId();
            //system.debug('==communityId==>'+communityId);
            if(test.isRunningTest()){
                communityId =null;
            }
            
            //no of records to fetch from Query to display on UI
            Integer recordCount = 3;
    
            if(Integer.valueOf(noOfRecordsTofetch) > 0){
                recordCount = Integer.valueOf(noOfRecordsTofetch);
            }
    
            //system.debug('recordCount=from MoreArticles==>'+recordCount);
    
            //Create List to topics to return to component
            list<Topic> topics = new list<Topic>();
            if(string.isNotBlank(communityId) || test.isRunningTest()){
                topics = [Select Id, Name From topic Where id in
                              (select topicId From TopicAssignment Where EntityId =: articleId)
                              And NetworkId =: communityId
                              Limit : recordCount];
        
                if(topics.size() > 0){
                    return topics;
                } else
                    return null;
            }else {
                throw (new AUPostCustomException('No community found'));
            }  
        }catch(exception ex){
            return null;
        }
    }

    public without sharing class AUPostCustomException extends Exception {}
    
}