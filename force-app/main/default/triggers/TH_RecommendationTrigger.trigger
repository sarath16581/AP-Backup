/**
 * @author alexvolkov
 * @date 23/1/20
 * @description 
 */
trigger TH_RecommendationTrigger on TH_Recommendation__c (before insert, before update)
{
	if (!SystemSettings__c.getInstance().Disable_Triggers__c)
	{
		if(Trigger.isBefore && Trigger.isInsert)
		{
			TH_RecommendationTriggerHandler.handleBeforeInsert(Trigger.new);
		}
		else if (Trigger.isBefore && Trigger.isUpdate)
		{
			TH_RecommendationTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
		}
	}
}