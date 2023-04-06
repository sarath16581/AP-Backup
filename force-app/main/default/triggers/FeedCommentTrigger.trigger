/**
* @author			: nandan.narasappa@auspost.com.au
* @date			: 03/07/2015
* @description	: Trigger on FeedComment  Object to call the Handler class to perform necessary action
* @change log
* 04/04/2023 - Mahesh Parvathaneni - Added domain based trigger framework.
*/
trigger FeedCommentTrigger on FeedComment(before insert,before update,before delete,
											after insert,after update,after delete,after undelete){
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(FeedComment.sObjectType))){	// verify if triggers are disabled
		FeedCommentTriggerHandler.execute();  // FeedComment  handler dispatches appropriate event

		//calling domain base trigger dispatch
		//All future implementation should use Domain based approach to call trigger handler and its logic.
		FeedCommentTriggerHandler2.newInstance().dispatch();
	}
												
	if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
		cpFeedCommentHandler commentHandler = new cpFeedCommentHandler();
		commentHandler.updateCaseStatus(trigger.new);
	}
}