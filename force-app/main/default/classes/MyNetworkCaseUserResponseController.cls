/**
* @author Dattaraj Deshmukh
* @date 2022-11-29
* @domain PUD
* @description Constants used across classes in PUD domain.
* @changelog
* 2022-11-29 - Dattaraj Deshmukh - Created.
								 - Controller is marked as without sharing as all chatter feeds on the record needs to be queried irrespective of who created them.
								  
*/
public without sharing class MyNetworkCaseUserResponseController {
    
	/**
	 * @param: networkComments, caseInvestigationId
	 * @desc: Creates a chatter feed on case investigation record
	 * @return: success/exception message.
	 */
	@AuraEnabled
    public static string postCaseInvestigationChatterFeed(String newtorkComments, String caseInvestigationId){
        try {
            
			//creating UnitOfWork explicitly to be able to commit DMLs
			ApplicationUnitOfWork uow = newUnitOfWork();

			if(String.isNotBlank(newtorkComments)){
				FeedItem post = new FeedItem();
				post.ParentId = caseInvestigationId;
				post.Body = newtorkComments;
				
				uow.registerNew(post);
				uow.commitWork();
			}
			return 'success';
			

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

	/**
	 * @desc:	Method returns list of feeditems available on record. 
	 * @param:  recordId
	 * @return  List<FeedItems>
	 */

	@AuraEnabled(cacheable=true)
    public static List<FeedItem> getNetworkComments(String recordId){
   		return FeedItemsSelector.newInstance().selectByTextPostParentIds(new Set<Id>{recordId}, new Set<Object>{FeedItemsSelector.Options.WITH_CREATEDBY}).values();
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

			//todo: Query using selectors.
            CaseInvestigation__c caseInvestigationRecord = [Select Id, Case__r.RecordType.DeveloperName From CaseInvestigation__c Where Id =: caseInvestigationRecordId];
           
            if(MyNetworkConstants.STAR_TRACK_RECORD_TYPES.contains(caseInvestigationRecord.Case__r.RecordType.DeveloperName) && caseInvestigationRecordId != null) {
                showComponent = true;
            }
        }

        return showComponent;
    }

	/**
	 * Unit of work that encapsulates all the required objects for this Service.
	 * Note that this is a stopgap until the pattern for using Unit of Work for service operations are defined.
	 *
	 * @return unit or work instance
	 */
	private static ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(new List<SObjectType>{
				FeedItem.SObjectType
		});
	}
}
