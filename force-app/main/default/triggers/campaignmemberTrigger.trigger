/**
 * @description
 * Add a task to the related Lead record for campaign activity visibility for the Customer Acquisition Campaigns
 * Project Manager: Trevor Price
 * @author Colin Johnson, Aprika Business Solutions (colin.johnson@aprika.com.au) - Green Shoots Project
 * @date
 * @group 
 * @domain 
 * @changelog
 * 2022-01-21 - Mathew Jose - Added the logic to remove contact assignments corresponding to campaign members and also implemented domain / modue uplift
 */

trigger campaignmemberTrigger on CampaignMember (after insert, after update,before update) {
	//Using the domain/module pattern for the changes added as part of campaign feedback replacement.
	if (!TriggerHelper.isTriggerDisabled(String.valueOf(CampaignMember.SObjectType))) {     // verify if triggers are disabled
		// New domain based trigger dispatch
		(new CampaignMemberTriggerHandler()).dispatch();
	}
	//Wrapping the old code in the below statement
	if(Trigger.isAfter && Trigger.isUpdate){
		
		//Declare variables
		Task[] tNew = new Task[]{
		}; //List of new Tasks to be created
		Map<String, EmailTemplate> emailTemplateIdByDeveloperNameMap = new Map<String, EmailTemplate>();
		list<Id> formSignedLeadIdList = new list<Id>();
		map<id, Attachment> attachemtByLeadIdMap = new map<id, Attachment>();


		//Create map of emailTemplates for Green_Shoots_Iternal
		for (EmailTemplate et : [select id, DeveloperName, Body,HtmlValue, Subject from EmailTemplate where DeveloperName like 'Green_Shoots_Internal%']) {
			emailTemplateIdByDeveloperNameMap.put(et.DeveloperName, et);
		}


		set<String> useCaseStatuses = new set<string>();
		for (GsUseCase uc : GsUseCaseSetup.useCases.values()) {
			useCaseStatuses.add(uc.cmsvAfterProceedAccept);
		}


		//Loop through all Campaign Member records to establish if they are related to a Lead
		//If they are, add the Lead ID to a list for processing
		For (CampaignMember cm : [
				SELECT Id,
						LeadId,
						Campaign.Name,
						Status
				FROM CampaignMember
				WHERE Id in:trigger.New
		]) {
			//Check to make sure the Campaign Member record is related to a Lead
			If (cm.LeadId != null) {
				If (trigger.newMap.get(cm.Id).Status != trigger.oldMap.get(cm.Id).Status) {
					Task t = new Task(Subject = 'Status within ' + cm.Campaign.Name + ' changed from ' + trigger.oldMap.get(cm.Id).Status + ' to ' + trigger.newMap.get(cm.Id).Status, Status = 'Completed', ActivityDate = date.today(), WhoId = cm.LeadId);
					tNew.add(t);

					System.debug('### cm.Status:' + cm.Status);
					if (useCaseStatuses.contains(cm.Status)) {
						formSignedLeadIdList.add(cm.LeadId);
					}

				}
			}
		}

		System.debug('### formSignedLeadIdList:' + formSignedLeadIdList);

		//Insert the new Task records
		insert tNew;


		//Get attachment
		for (Attachment att : [
				SELECT Id, Name, body, ParentId
				FROM Attachment
				WHERE ParentId In :formSignedLeadIdList AND
				Name = 'Application Form.pdf'
				ORDER BY CreatedDate Desc
				Limit 1
		]) {
			attachemtByLeadIdMap.put(att.ParentId, att);
			system.debug('### att.id : ' + att.id);
		}


		list<Lead> leads = [
				SELECT id,
						JSONApplicationFormData__c,
						Send_Business_Credit_Account_Info__c,
						State,
						Hub_Catchment__c,
						Existing_Business_Credit_Account__c,
						Account_No__c,
						Company
				from Lead
				where id IN :formSignedLeadIdList
		];


		list<Task> tasksHistory = new list<task>();

		for (Lead lead : leads) {
			Attachment att = attachemtByLeadIdMap.containsKey(lead.id) ? attachemtByLeadIdMap.get(lead.id) : null;
			GsCallToAction callToAction = new GsCallToAction(lead, att, emailTemplateIdByDeveloperNameMap);
			calltoAction.sendCallToActionEmail();
			Task t = new Task(ActivityDate = datetime.now().date(), Subject = 'Call to action email sent', Type = 'Other', Description = 'Call to action email sent', Status = 'Completed', WhoId = lead.Id);
			tasksHistory.add(t);
		}

		if (tasksHistory.size() > 0) {
			insert tasksHistory;
		}		
		
	}

}