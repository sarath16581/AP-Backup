//Wrapper class for Trending Discussion (feed items)
public without sharing class cpTrendingDiscussionWrapper {

    @AuraEnabled
    public String feedElementId {get; set;}
    @AuraEnabled
    public String questionTitle {get; set;}
    @AuraEnabled
    public Long toalViewCommentAndLikeCount {get; set;}

    //Wrapper class for Trending Discussion (feed items)
    public cpTrendingDiscussionWrapper(String feedElementId, String questionTitle, Long toalViewCommentAndLikeCount) {
        this.feedElementId = feedElementId;
        this.questionTitle = questionTitle;
        this.toalViewCommentAndLikeCount = toalViewCommentAndLikeCount;
    }
}