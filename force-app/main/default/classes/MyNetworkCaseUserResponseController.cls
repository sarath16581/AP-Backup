/**
* @author Dattaraj Deshmukh
* @date 2022-11-29
* @domain PUD
* @description Constants used across classes in PUD domain.
* @changelog
* 2022-11-29 - Dattaraj Deshmukh - Created.
*/
public with sharing class MyNetworkCaseUserResponseController {
    
	@AuraEnabled
    public static string postCaseInvestigationChatterFeed(String newtorkComments, String caseInvestigationId){
        try {
            
            FeedItem post = new FeedItem();
            post.ParentId = caseInvestigationId;
            post.Body = newtorkComments;
            insert post;

            return 'success';

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
