/**************************************************
Type:		Trigger for ContractAssistanceForm__c Trigger
Purpose:	Custom Apex Sharing and custom validations
History:
--------------------------------------------------
14.11.2017	Boris Bachovski		Created
07.12.2017	Clint D'Silva		Added Validation function
**************************************************/
trigger ContractAssistanceForm on ContractAssistanceForm__c (before insert, before update,after insert, after update)
{
	if (!SystemSettings__c.getInstance().Disable_Triggers__c)
	{
		if (trigger.isAfter &&   trigger.isInsert)
		{
			ContractAssistanceFormHandler.shareContractAssistanceFormWithOpportunityOwner(trigger.new);
		}
		
		if (trigger.isAfter &&  trigger.isUpdate)
		{
			ContractAssistanceFormHandler.addContractAssistanceOwnerToOpportunityTeam(trigger.new, trigger.oldMap);
		}
        
        if(trigger.isBefore &&  (trigger.isUpdate || trigger.isInsert) ){
            ContractAssistanceFormHandler.Validate(trigger.new, trigger.oldMap);
        }
	}
}