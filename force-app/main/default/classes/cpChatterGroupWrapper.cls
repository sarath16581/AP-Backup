//Class for chatter group wrapper used by customer community.
public class cpChatterGroupWrapper {
    
    @AuraEnabled
    public String groupId {get; set;}
    @AuraEnabled
    public Integer groupMemberCount {get; set;}
    @AuraEnabled
    public String groupName {get; set;}
    @AuraEnabled
    public String groupDescription {get; set;}
    @AuraEnabled
    public String smallPhotoUrl {get; set;}
    @AuraEnabled
    public String lastFeedElementPostDate {get; set;}
    //Get group
    public cpChatterGroupWrapper(String groupId, Integer groupMemberCount, String groupName, String groupDescription, String smallPhotoUrl, String lastFeedElementPostDate) {
        this.groupId = groupId;
        this.groupMemberCount = groupMemberCount;
        this.groupName = groupName;
        this.groupDescription = groupDescription;
        this.smallPhotoUrl = smallPhotoUrl;
        this.lastFeedElementPostDate = lastFeedElementPostDate;
    }
}