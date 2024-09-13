/**
  * @author : Seth Heang
  * @date   : 2024-09-04
  * @description  : Trigger on ImpactedArticle__c Object
  * @changelog
  * 2024-09-04 - Seth Heang - Created
  */
trigger ImpactedArticleTrigger on ImpactedArticle__c(before insert,before update,before delete,
		after insert,after update,after delete,after undelete){
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(ImpactedArticle__c.sObjectType))){
		System.debug('SETH prior to dispatch ImpactedArticleTriggerHandler');
		(new ImpactedArticleTriggerHandler()).dispatch();

	}
}