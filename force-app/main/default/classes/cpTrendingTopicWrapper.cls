//Class for trending topics wrapper used by Customer Community
public without sharing class cpTrendingTopicWrapper {
        
    @AuraEnabled
    public String topicId {get; set;}
    @AuraEnabled
    public String topicName {get; set;}
    @AuraEnabled
    public Integer talkingAboutCount {get; set;}
    //Trending Topic Wrapper
    public cpTrendingTopicWrapper(String topicId, String topicName, Integer talkingAboutCount) {
        this.topicId = topicId;
        this.topicName = topicName;
        this.talkingAboutCount = talkingAboutCount;
    }
}