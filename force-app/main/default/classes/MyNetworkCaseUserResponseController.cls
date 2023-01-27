/**
* @author Dattaraj Deshmukh
* @date 2022-11-29
* @domain MyNetwork
* @description Controller to post feed items against case investigations
* @changelog
* 2022-11-29 - Dattaraj Deshmukh - Created.
*/
public with sharing class MyNetworkCaseUserResponseController {
	
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
				//ApplicationDatabase.getInstance().dmlUpsert(new List<SObject>{post, caseToUpdate}, FeedItem.Id);
				ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{post});
				ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{caseToUpdate});
			}
			return 'success';
			

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}
