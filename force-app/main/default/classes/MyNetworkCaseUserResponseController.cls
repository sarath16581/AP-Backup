/**
* @author Dattaraj Deshmukh
* @date 2022-11-29
* @domain MyNetwork
* @description Controller to post feed items against case investigations
* @changelog
* 2022-11-29 - Dattaraj Deshmukh - Created.
* NOTE: THIS CLASS IS SPECIFIED AS WITHOUT SHARING. 
* REASON: MyNetowork portal users have ONLY READ access to the case. In order to update CASE related to 
* case investigations, 'without sharing' mode is used. updateCase() method updates the case.
* 2023-03-16 - Mahesh Parvathaneni - Modified the method updateCase
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

				//create new feed item record
				ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{post});
				
			}

			return 'success';
			

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @param: caseToUpdate
	 * @desc: Update the case record
	 * @return: success/exception message.
	 */
	@AuraEnabled
	public static string updateCase(Case caseToUpdate) {
		try {
			ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{caseToUpdate});
			return 'success';
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	} 
}