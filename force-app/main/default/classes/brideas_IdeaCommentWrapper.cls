/**
 * Created by Sergen on 03.09.2017.
 */

public with sharing class brideas_IdeaCommentWrapper {

    @AuraEnabled
    public IdeaComment ideaComment;

    @AuraEnabled
    public Boolean Flagged = false;

    public brideas_IdeaCommentWrapper(){}

}