/**
* @author Dattaraj Deshmukh
* @date 2022-11-29
* @domain MyNetwork
* @description Controller to list feed items against case investigations
* @changelog
* 2022-11-29 - Dattaraj Deshmukh - Created.
			NOTE - Controller is marked as without sharing as all chatter feeds on the record needs to be queried irrespective of who created them.
								  
*/
public without sharing class MyNetworkCaseUserResponseController {
    
	/**
	 * @param: networkComments, caseInvestigationId
	 * @desc: Creates a chatter feed on case investigation record
	 * @return: success/exception message.
	 */
	@AuraEnabled
    public static string postCaseInvestigationChatterFeed(String newtorkComments, String caseInvestigationId, Id caseId){
        try {
            
			if(String.isNotBlank(newtorkComments)){
				FeedItem post = new FeedItem();
				post.ParentId = caseInvestigationId;
				post.Body = newtorkComments;

				//update case status to 'Network Responded'
				Case caseToUpdate = new Case(Id = caseId, Status = MyNetworkConstants.CASE_STATUS_NETWORK_RESPONDED);

				//create new feed item record and update case status
				ApplicationDatabase.getInstance().dmlUpsert(new List<SObject>{post, caseToUpdate}, Case.Id);
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
    public static List<FeedItem> getCaseInvestigationChatterFeeds(String recordId){
   		return FeedItemsSelector.newInstance().selectByTextPostParentIds(new Set<Id>{recordId}, new Set<Object>{FeedItemsSelector.Options.WITH_CREATEDBY}).values();
	}

}
