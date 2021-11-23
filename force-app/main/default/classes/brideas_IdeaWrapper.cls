public with sharing class brideas_IdeaWrapper {
    @AuraEnabled
    public Idea item;

    @AuraEnabled
    public String statusColor;

    @AuraEnabled
    public Integer NumComments = 0;

    @AuraEnabled
    public String voteStatus = '';

    @AuraEnabled
    public Integer votesNum = 0;

    @AuraEnabled
    public Boolean flagged = false;

    public brideas_IdeaWrapper() { }
}