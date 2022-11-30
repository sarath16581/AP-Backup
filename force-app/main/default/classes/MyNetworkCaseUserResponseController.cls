/**
* @author Dattaraj Deshmukh
* @date 2022-11-29
* @domain PUD
* @description Constants used across classes in PUD domain.
* @changelog
* 2022-11-29 - Dattaraj Deshmukh - Created.
*/
public without sharing class MyNetworkCaseUserResponseController {
    
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

	/**
	 * @desc:	Method returns list of feeditems available on record. 
	 * @param:  recordId, FeedItem.Type ('TextPost')
	 * @return  List<FeedItems>
	 */

	@AuraEnabled(cacheable=true)
    public static List<FeedItem> getNetworkComments(String recordId, String feedType){
        return [Select Id,ParentId, Body, CreatedBy.FirstName, CreatedBy.LastName, CreatedById, CreatedDate 
        FROM FeedItem WHERE ParentId =: recordId AND Type =: feedType];

    }

	/**
     * @desc: Method returns Boolean based on following Rules to show/hide component.
     *          1. If AP Case is accessed from Global Search or from home page list view, show component.
     *          2. If ST Case is accessed from home page list view, show component.
     *          3. If ST Case is accessed from global search, hide component.
     * @param  caseInvestigationRecordId
	 * @return Boolean
     */
    @AuraEnabled
    public static Boolean checkComponentVisibility(Id caseInvestigationRecordId) { 

        Boolean showComponent = false;
        if(caseInvestigationRecordId != null){
            CaseInvestigation__c caseInvestigationRecord = [Select Id, Case__r.RecordType.DeveloperName From CaseInvestigation__c Where Id =: caseInvestigationRecordId];

           
            if(MyNetworkConstants.STAR_TRACK_RECORD_TYPES.contains(caseInvestigationRecord.Case__r.RecordType.DeveloperName) && caseInvestigationRecordId != null) {
                showComponent = true;
            }
        }

        return showComponent;
    }
}
