/**
 * @domain Controller
 * @changelog
 * 2024-03-25 - Naveen Rajanna - INC2216801 - Workaround to fix H&S users getting insufficient access when they close or reopen closed case. 
 * 				From debug logs, it is not evident why insufficient access is being thrown. Awaiting RCA from SF support via SF Case# 46552063.
*/
public with sharing class ChasCustomCaseListAndDetailController {

	/**
	* Description: Fetch all the cases in des order of modified date for the given Case
	* */	
	@AuraEnabled
	public static CaseComment[] fetchCaseComments( String caseId){ 
		CaseComment[] caseComments = null;
		try{
			caseComments = [SELECT Id, CommentBody, CreatedBy.FirstName, LastModifiedDate from CaseComment where parentId=:caseId ORDER BY LastModifiedDate DESC];
		}catch(Exception ex){
			System.debug(LoggingLevel.ERROR, 'Error occoured while fetching Csae comments for the Case ->'+caseId+' , the error is ==>'+ex);
		}
		return caseComments;
		
	}
	
	/**
	* Description: Create/Insert the CaseComment under the given Case
	* */  
	@AuraEnabled
	public static CaseComment creatCaseComment( String caseId, String caseCommentBody){ 
		CaseComment caseComment = null;
		try{
			//String caseNumber = ChasUtil.createCaseComment(caseId, caseCommentBody);
			String caseCommentId = ChasUtil.createCaseCommentAndReturnId(caseId, caseCommentBody);
			if(caseCommentId !=null){
				caseComment = [SELECT Id, CommentBody, CreatedBy.FirstName, LastModifiedDate FROM CaseComment WHERE Id=:caseCommentId];// and ParentId=:caseId  ORDER BY LastModifiedDate DESC LIMIT 1];
							   //CommentBody=:caseCommentBody and ParentId=:caseId  ORDER BY LastModifiedDate DESC LIMIT 1];
			}
			
		}catch(Exception ex){
			System.debug(LoggingLevel.ERROR, 'Error occoured while fetching Csae comments for the Case ->'+caseId+' , the error is ==>'+ex);
		}
		return caseComment;
		
	}

	/**
	* Description: return current user name
	* */
	@AuraEnabled
	public static String getCurrentUserName(){
		//return UserInfo.getName();
		return UserInfo.getFirstName();
	}
	
	/**
	* Description: Get Case Status
	* */ 
	@AuraEnabled 
	public static String getCaseStatus(String caseId){
		String caseStatus = null;
		try{
			Case caseObj = [SELECT Id, Status FROM Case WHERE  Id=:caseId LIMIT 1];
			if(caseObj != null){
				caseStatus = caseObj.Status;
			}
		}catch(Exception ex){
			System.debug(LoggingLevel.ERROR,'Error occoured while updating Case Status ==>'+ex);
		}
		return caseStatus;
	}

	/**
	 * @return a list of Cases based on the UserId or User's Contact's APCN
	 * @description: Using the SSSWCasesSelector to soql the cases based on the UserId or User's Contact's APCN
	 */
	@AuraEnabled 
	public static List<Case> getLoggedInUserCaseList(){
		try {
			User runningUser = [SELECT Id,APCN__c,Contact.APCN__c,CreatedById FROM User WHERE Id = :UserInfo.getUserId()];

			return SSSWCasesSelector.newInstance(2000,new Set<SObjectField>{Case.Id,Case.CHASEnquiryType__c,Case.CaseNumber,Case.LastModifiedDate,Case.CreatedById, Case.Enquiry_Status__c})
					.selectCasesByCreatedByUserOrAPCN(UserInfo.getUserId(),runningUser.Contact.APCN__c, new Set<Object>{SSSWCasesSelector.Options.WITH_CONTACT}).values();

		} catch(Exception ex) {
			System.debug(LoggingLevel.ERROR,'Error occurred getLoggedInUserCaseList ==>'+ex);
			return null;
		}
	}

	/**
	* Description: INC2216801 - Updating Case using ElevatedSharingContext
	* It throws insufficient access error when you perform a DML and Case Trigger is changing OwnerId, so we need to perform DML in without sharing context.
	* */ 
	@AuraEnabled 
	public static void updateCase(Case caseToUpdate){
		try{
			ElevatedSharingContext context = new ElevatedSharingContext();
			context.updateRecords(new List<SObject>{caseToUpdate});
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	
	/**
	* INC2216801 - Private inner class that elevates access/edit privileges of the current user to edit data without being limited by sharing settings.
	*/
	private without sharing class ElevatedSharingContext {
		/**
		 * Insert a list of sObject records in system mode
		 * @param List<sObject>
		*/
		private List<Database.SaveResult> updateRecords(List<sObject> recordList) {
			return ApplicationDatabase.getInstance().dmlUpdate(recordList);
		}
	}
}