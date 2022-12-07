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
    public static string postCaseInvestigationChatterFeed(String newtorkComments, String caseInvestigationId){
        try {
            
			//creating UnitOfWork explicitly to be able to commit DMLs
			ApplicationUnitOfWork uow = newUnitOfWork();

			if(String.isNotBlank(newtorkComments)){
				FeedItem post = new FeedItem();
				post.ParentId = caseInvestigationId;
				post.Body = newtorkComments;
				
				//create new records
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
