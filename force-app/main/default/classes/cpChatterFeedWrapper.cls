//Class for chatter feed wrapper used by customer community
public class cpChatterFeedWrapper {
        
    @AuraEnabled
    public String feedElementId {get; set;}
    @AuraEnabled
    public String questionTitle {get; set;}
    @AuraEnabled
    public String relativeCreatedDate {get; set;}
    @AuraEnabled
    public String imageIconUrl {get; set;}
    @AuraEnabled
    public String actorId {get; set;}
    @AuraEnabled
    public String actorNickName {get; set;}
    @AuraEnabled
    public Long toalViewCommentAndLikeCount {get; set;}
    @AuraEnabled
    public Long commentCount {get; set;}
    @AuraEnabled
    public String bestAnswerId {get; set;}
    
    //Chatter feed wrapper
    public cpChatterFeedWrapper(String feedElementId, String questionTitle, String imageIconUrl, String actorId, String actorNickName, String relativeCreatedDate, Long toalViewCommentAndLikeCount, Long commentCount, String bestAnswerId) {
        this.feedElementId = feedElementId;
        this.questionTitle = questionTitle;
        this.imageIconUrl = imageIconUrl;
        this.actorId = actorId;
        this.actorNickName = actorNickName;
        this.relativeCreatedDate = relativeCreatedDate;
        this.toalViewCommentAndLikeCount = toalViewCommentAndLikeCount;
        this.commentCount = commentCount;
        this.bestAnswerId = bestAnswerId;
    }
}