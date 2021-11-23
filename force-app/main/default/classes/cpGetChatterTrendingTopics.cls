//Class to retrieve chatter trending topics used by component in customer community.
public without sharing class cpGetChatterTrendingTopics {
        
    // retrieve trending topics  
    @AuraEnabled
    //Get chatter trending topics
    public static list<cpTrendingTopicWrapper> getTrendingChatterTopics(Integer noOfRecordsToFetch) { 
        try{
            //Fetch  user’s current community
            String communityId = Network.getNetworkId();
            
            //The default is 5. Value must be greater than 0 and less than or equal to 25.
            Integer maxResults = 25;
            Integer recordCountToFetch = 12;
            if(Integer.valueOf(noOfRecordsToFetch) > 0 && Integer.valueOf(noOfRecordsToFetch) < 13){
               recordCountToFetch = Integer.valueOf(noOfRecordsToFetch);
            }
            
            
            //List of wrapped items to be displayed on UI 
            list<cpTrendingTopicWrapper> wrappedTrendingTopics = new list<cpTrendingTopicWrapper>();
            
            if(string.isNotBlank(communityId) || test.isRunningTest()){
                ConnectApi.TopicPage trendingTopic;
                if(test.isRunningTest())
                    trendingTopic = ConnectApi.Topics.getTrendingTopics(null,  10);
                else
                    trendingTopic = ConnectApi.Topics.getTrendingTopics(communityId, maxResults);
                List<ConnectApi.Topic> topicList = new List<ConnectApi.Topic>();
                if(trendingTopic != null){
                     topicList = trendingTopic.topics;
                }
                //System.debug('topicList size==>'+topicList);
                
                if(topicList.size() > 0){
                    for(ConnectApi.Topic topik: topicList){
                        String topicId = topik.id;
                        //system.debug('topicId==>'+topicId);
                        Integer talkingAboutCount = topik.talkingAbout;
                        //system.debug('talkingAboutCount==>'+talkingAboutCount);
                        String topicName = topik.Name;
                        //system.debug('topicName==>'+topicName);
                        //adding topics to list of wrapper class
                        wrappedTrendingTopics.add(new cpTrendingTopicWrapper(topicId, topicName, talkingAboutCount)); 
                        
                        Integer wrappSize = wrappedTrendingTopics.size();
                        if(recordCountToFetch == wrappSize){
                            break;
                        }
                    }
                }
                
            } else {
                throw (new AUPostCustomException('No community found')); 
            }
            return wrappedTrendingTopics;
        }catch(exception ex){
            return null;
        }
    } 

	public without sharing class AUPostCustomException extends Exception {}    
}