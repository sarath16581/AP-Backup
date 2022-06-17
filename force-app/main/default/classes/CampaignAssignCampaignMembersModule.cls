/**
 * @description
 * Domain Module to create/update task related to the account manager of the campaign
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 *
 * @author Ashapriya Gadi
 * @date 2021-12-15
 * @group Domain
 * @domain CampaignContactAssignmentsDomain
 * @changelog
 * 2021-12-21 - Mathew Jose - Added the saveCampaignMembers method for after insert and after update events
 * 2022-02-17 - Mathew Jose - Updated the saveCampaignMembers to faciliate the description to be set on Campaign Member record getting created.
 * 2022-02-17 - Mathew Jose - Updated the createTask to use dmlOptions so that task email notification is fired.
 * 2022-05-16 - Prerna Rahangdale - Modified the code to assign the task to the CCA Contact Owner field if present.

 */
public inherited sharing class CampaignAssignCampaignMembersModule extends ApplicationDomain.Module {
	public static CampaignAssignCampaignMembersModule newInstance() {
		return (CampaignAssignCampaignMembersModule)Application.Utilities.newInstance(CampaignAssignCampaignMembersModule.class);
	}
	
	// Setup which triggers this module should respond to
	public CampaignAssignCampaignMembersModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {

			// ensures that account managers are assigned a task when there is work for them to do
			// additionally will update an existing task to In Progress if needed
			createTask(records, null,  uow);

			// ensure that CampaignMember records are created/updated when Contact changes on Contact Assignment records
			saveCampaignMembers((List<CampaignContactAssignment__c>) records, null, uow);

		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), CampaignContactAssignmentConstants.APP_NAME, CampaignAssignCampaignMembersModule.class.getName(), 'onAfterInsert', CampaignContactAssignmentConstants.TRIGGER_NAME, LoggingLevel.ERROR);
		}
	}


	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {

			// ensures that account managers are assigned a task when there is work for them to do
			// additionally will update an existing task to In Progress if needed
			createTask(records, existingRecords, uow);

			// ensure that CampaignMember records are created/updated when Contact changes on Contact Assignment records
			saveCampaignMembers((List<CampaignContactAssignment__c>) records,(Map<Id,CampaignContactAssignment__c>)existingRecords, uow);

		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), CampaignContactAssignmentConstants.APP_NAME, CampaignAssignCampaignMembersModule.class.getName(), 'onAfterUpdate', CampaignContactAssignmentConstants.TRIGGER_NAME, LoggingLevel.ERROR);
		}
	}
	/**
	 * Method to create tasks for Account Managers if their Organisations are assigned to a Campaign
	 * Account Managers that have a task Not Started where a contact is assigned, then the task should be updated to in progress
	 * Account Managers that do not have a task, then the task should be created as either In Progress or Not Started (depending on whether a contact is assigned to the record)
	 */
	public void createTask(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){

		List<CampaignContactAssignment__c> processable = new List<CampaignContactAssignment__c>();
		// Set to store the owner Ids of the CCA record custom field
		Map<Id,Id> ccaOtherOwner = new Map<Id,Id>();

		//To capture records where contact was updated
		Map<Id, Set<SObjectField>> changedRecords = new Map<Id, Set<SObjectField>>();

		Boolean isInsert = false;
		if(existingRecords == null || existingRecords.isEmpty()) {
			isInsert = true;
		} else {
			changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{CampaignContactAssignment__c.Organisation__c,
					CampaignContactAssignment__c.Contact__c,CampaignContactAssignment__c.Campaign_Contact_Owner__c});
		}

		// ensure that we can actually action the records passed on
		for(CampaignContactAssignment__c campaignContactAssignmentRecord : (List<CampaignContactAssignment__c>) records){
			if(CampaignContactAssignment__c.Organisation__c != null && (isInsert || (changedRecords.get(campaignContactAssignmentRecord.Id) != null && (changedRecords.get(campaignContactAssignmentRecord.Id).contains(CampaignContactAssignment__c.Organisation__c)
					|| changedRecords.get(campaignContactAssignmentRecord.Id).contains(CampaignContactAssignment__c.Contact__c) || changedRecords.get(campaignContactAssignmentRecord.Id).contains(CampaignContactAssignment__c.Campaign_Contact_Owner__c))))) {
				processable.add(campaignContactAssignmentRecord);
			}
			if(campaignContactAssignmentRecord.Campaign_Contact_Owner__c  != null && (isInsert ||  (changedRecords.get(campaignContactAssignmentRecord.Id) != null
					&& changedRecords.get(campaignContactAssignmentRecord.Id).contains(CampaignContactAssignment__c.Campaign_Contact_Owner__c)
					|| changedRecords.get(campaignContactAssignmentRecord.Id).contains(CampaignContactAssignment__c.Contact__c)))){
				ccaOtherOwner.put(campaignContactAssignmentRecord.Organisation__c,campaignContactAssignmentRecord.Campaign_Contact_Owner__c);
			}
		}
		
		//Initialising dml options to be used to trigger task assignment email.
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.EmailHeader.triggerUserEmail = true;		

		if(!processable.isEmpty()) {

			List<Task> tasksUpdateable = new List<Task>();
			List<Task> tasksInsertable = new List<Task>();

			Set<Id> accountIds = new Set<Id>();
			Map<Id, Id> accountOwnersMap = new Map<Id, Id>();
			Map<Id, Map<Id, Boolean>> campaignAccounts = new Map<Id, Map<Id, Boolean>>();

			for(CampaignContactAssignment__c campaignContactAssignmentRecord : processable) {

				// store a list of the account associated to the campaigns in the current transaction
				// this would usually only ever be a single campaign, but could be more in bulk data operations
				// NOTE: We also store the status in which the task should be created/update to
				//		  A BOOLEAN - true = Task should be marked In Progress
				//					- false = Task should be marked Not Started
				Boolean shouldAccountManagersTaskBeInProgress = campaignContactAssignmentRecord.Contact__c != null && (isInsert || changedRecords.get(campaignContactAssignmentRecord.Id)?.contains(CampaignContactAssignment__c.Contact__c));

				if(campaignAccounts.get(campaignContactAssignmentRecord.Campaign__c) == null) {
					campaignAccounts.put(campaignContactAssignmentRecord.Campaign__c, new Map<Id, Boolean>());
				}
				campaignAccounts.get(campaignContactAssignmentRecord.Campaign__c).put(campaignContactAssignmentRecord.Organisation__c, shouldAccountManagersTaskBeInProgress);

				accountIds.add(campaignContactAssignmentRecord.Organisation__c);

			}

			//fetch the owners(account managers) of all the organizations(setOfAccountIds) from above records
			// this is so we can compare which account managers have tasks already linked to the campaign
			Map<Id, Account> accountsMap = AccountsSelector.newInstance(0, new Set<SObjectField>{Account.Id, Account.OwnerId}).selectById(accountIds);
			for(Account acc : accountsMap.values()) {
				accountOwnersMap.put(acc.Id, acc.OwnerId);
			}



			// grab a list of all the non complete tasks so that we can 'synchronise' the state and map the tasks based on owner
			// NOTE: This logic assumes only 1 'open' task exists for a user.
			// multiple tasks for a single user against the campaign
			Map<String, Object> searchParams = new Map<String, Object>();

			Set<Id> taskOwnerIds = new Set<Id>();
			taskOwnerIds.addAll(accountOwnersMap.values());
			taskOwnerIds.addAll(ccaOtherOwner.values());
			// Check existing task record for the campaign with either accountowner or, CCA.CCA owner field.
			searchParams.put('ownerIds', taskOwnerIds);
			searchParams.put('whatIds', campaignAccounts.keySet());
			searchParams.put('isClosed', false);
			searchParams.put('subjects', new Set<String>{CampaignContactAssignmentConstants.TASK_SUBJECT});
			Map<Id, Map<Id, Task>> campaignTaskOwnerMappings = new Map<Id, Map<Id, Task>>();
			for(Task taskRecord : TasksSelector.newInstance().search(searchParams, new Set<Object>{}, true).values()) {
				Id campaignId = taskRecord.WhatId;

				if(campaignTaskOwnerMappings.get(campaignId) == null) {
					campaignTaskOwnerMappings.put(campaignId, new Map<Id, Task>());
				}

				// assign the owners task (if any) per campaign record
				// this is for bulkification where we might be processing multiple records
				campaignTaskOwnerMappings.get(campaignId).put(taskRecord.OwnerId, taskRecord);
			}

			// iterate through each campaign and it's associated account assignments (in the transaction) in order to work our whether to create tasks or not
			for(Id campaignId : campaignAccounts.keySet()) {
				// a list of all the account ids associated to the campaign
				Set<Id> campaignAccountIds = campaignAccounts.get(campaignId).keySet();

				// only process tasks specific to the unique account manager
				// NOTE: Multiple accounts might belong to the same account manager
				// So we need to base our logic around the unique account manager
				Map<Id, Boolean> ownerTaskWithStatusMappings = new Map<Id, Boolean>();
				for(Id accountId : accountOwnersMap.keySet()) {
					// check if the account id is in the list of accounts for the campaign in question
					// this means there should be a task for the account owner linked to the campaign
					// if it's not in the list when we skip it for this campaign


					if(campaignAccountIds.contains(accountId)) {
						Id ownerId  = ccaOtherOwner.get(accountId) != null ? ccaOtherOwner.get(accountId) : accountOwnersMap.get(accountId);

						if(ownerTaskWithStatusMappings.get(ownerId) == null || ownerTaskWithStatusMappings.get(ownerId) != true) {
							// the owner has not already been added to the list to be processed
							// OR they have been added with an indication the task should be marked 'Not Started'
							// We do another pass to see if the next Contact Assign record has a contact id assigned already which means the task status should actually be set to 'In Progress'
							Boolean accountOwnersTaskShouldBeInProgress = campaignAccounts.get(campaignId).get(accountId);
							ownerTaskWithStatusMappings.put(ownerId, accountOwnersTaskShouldBeInProgress);
						}
					}
				}
				
				for(Id ownerId : ownerTaskWithStatusMappings.keySet()) {
					Boolean accountOwnersTaskShouldBeInProgress = ownerTaskWithStatusMappings.get(ownerId);

					// check if there is already an existing task for the owner against the current campaign being processed
					if(campaignTaskOwnerMappings.get(campaignId)?.get(ownerId) != null) {
						Task existingTask = campaignTaskOwnerMappings.get(campaignId)?.get(ownerId);

						// an open task already exists for the account manager against the current campaign
						// check whether we need to change the status
						// the status of this task depends on whether the Contact__c field is populated and whether the record was inserted OR Contact__c was changed

						if(accountOwnersTaskShouldBeInProgress && !CampaignContactAssignmentConstants.TASK_INPROGRESS.equalsIgnoreCase(existingTask.Status)){
							tasksUpdateable.add(new Task(Id = existingTask.Id, Status = CampaignContactAssignmentConstants.TASK_INPROGRESS));
						}
					} else {
						// no 'open' task exists for this user so a new task record will need to be created
						// the status of this task depends on whether the Contact__c field is populated and whether the record was inserted OR Contact__c was changed
						// Trigger task assignment email notification leveraging dml options.
						Task tNew = new Task(OwnerId = ownerId, WhatId = campaignId, Subject = CampaignContactAssignmentConstants.TASK_SUBJECT, Status = (accountOwnersTaskShouldBeInProgress ? CampaignContactAssignmentConstants.TASK_INPROGRESS : CampaignContactAssignmentConstants.TASK_NOTSTARTED), Description = label.CampaignAssignContactTaskContent);
						tNew.setOptions(dmo);
						tasksInsertable.add(tNew);
					}

				}
			}

			if(!tasksInsertable.isEmpty()) {
				//register the tasks to insert with the UOW and the work will be committed in ApplicationDomainTriggerHandler
				uow.registerNew(tasksInsertable);
			}
			if(!tasksUpdateable.isEmpty()) {
				//register the tasks to update with the UOW and the work will be committed in ApplicationDomainTriggerHandler
				uow.registerDirty(tasksUpdateable);
			}
		}
	}
	
	/**
	 * Upsert or Delete Campaign Members based on Campaign Contact Assignments
	 *
	 * @param records  list of new records.
	 * @param existingRecords  Trigger.oldMap.
	 */
	public void saveCampaignMembers(List<CampaignContactAssignment__c> records, Map<Id, CampaignContactAssignment__c> existingRecords, ApplicationUnitOfWork uow) {
		System.debug('Entered: saveCampaignMembers');

		Boolean isInsert = false;
		Map<Id, Set<SObjectField>> changedRecords = new Map<Id, Set<SObjectField>>();
		if(existingRecords == null || existingRecords.isEmpty()) {
			isInsert = true;
		} else {
			changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{CampaignContactAssignment__c.Contact__c});
		}

		Map<Id, Set<Id>> campaignContactsMap = new Map<Id, Set<Id>>();
		//Updating the set to a map of contact Id and assignment to facilitate description update on campaign member record.
		//Set<Id> contactIds = new Set<Id>();
		Map<Id,CampaignContactAssignment__c> contactIdAssignmentMap = new Map<Id,CampaignContactAssignment__c>(); 
		// grab a list of all the eligible records passed in
		// We only want to process record if we absolutely need to
		for (CampaignContactAssignment__c record : records) {
			Set<SObjectField> changed = changedRecords.get(record.Id);
			if(changed == null) changed = new Set<SObjectField>();

			//Create campaign members if Contact lookup is populated on CCA.
			if (record.Contact__c != null && (isInsert || changed.contains(CampaignContactAssignment__c.Contact__c))) {
				if(campaignContactsMap.get(record.Campaign__c) == null) campaignContactsMap.put(record.Campaign__c, new Set<Id>());
				campaignContactsMap.get(record.Campaign__c).add(record.Contact__c);
				//contactIds.add(record.Contact__c);
				contactIdAssignmentMap.put(record.Contact__c,record);
				
			}
		}

		if(!campaignContactsMap.isEmpty()) {
			List<CampaignMember> insertableCampaignMembers = new List<CampaignMember>();
			List<CampaignMember> updateableCampaignMembers = new List<CampaignMember>();
			Map<Id, Map<Id, CampaignMember>> existingCampaignMembers = new Map<Id, Map<Id, CampaignMember>>();
			Map<Id, Campaign>campaignsMap = new Map<Id, Campaign>(CampaignsSelector.newInstance().selectById(campaignContactsMap.keySet()));

			// grab a list of the existing campaign member records for the passed in contact ids/ campaign ids
			Map<String, Object> searchParams = new Map<String, Object>();
			searchParams.put('campaignIds', campaignContactsMap.keySet());
			//searchParams.put('contactIds', contactIds);
			searchParams.put('contactIds', contactIdAssignmentMap.keySet());
			System.debug('searchParams: ' + searchParams);
			for(CampaignMember campaignMemberRecord : CampaignMembersSelector.newInstance().search(searchParams, new Set<Object>(), true)) {
				if(existingCampaignMembers.get(campaignMemberRecord.CampaignId) == null) existingCampaignMembers.put(campaignMemberRecord.CampaignId, new Map<Id, CampaignMember>());
				existingCampaignMembers.get(campaignMemberRecord.CampaignId).put(campaignMemberRecord.ContactId, campaignMemberRecord);
			}

			// compare whats existing to what is supplied in the trigger transaction
			for(Id campaignId : campaignContactsMap.keySet()) {
				// grab the existing Contacts for this campaign (if there any that match the contacts on the record passed in)
				if(existingCampaignMembers.get(campaignId) == null) existingCampaignMembers.put(campaignId, new Map<Id, CampaignMember>());
				Set<Id> existingContactIds = existingCampaignMembers.get(campaignId).keySet();

				// loop through each of the contacts in the records passed in and compare them against what is already existing for a particular campaign
				// if a contact already exists and the status is CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED then we need to update the status back to the default at the campaign level
				// if a contact already exists and the status is NOT as above, then do nothing
				// if a contact does not exist then we create
				for(Id contactId : campaignContactsMap.get(campaignId)) {
					if(existingContactIds.contains(contactId) && CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED.equalsIgnoreCase(existingCampaignMembers.get(campaignId).get(contactId).Status)) {
						// contact exists with a 'cancelled' state, so we need to update the status of the record back to the default status and reinstate the new CCA records.
						updateableCampaignMembers.add(new CampaignMember(Id = existingCampaignMembers.get(campaignId).get(contactId).Id, Status = campaignsMap.get(campaignId)?.ContactAssignmentDefaultStatus__c
								,Campaign_Contact_Assignment__c = contactIdAssignmentMap.get(contactId).Id));
					} else if(!existingContactIds.contains(contactId)) {
						// the campaign member record does not exist yet so we create it
						// ensure description is copied from the CCA description field
						// storing the value of campaign contact assignment field value which created the Campaign member record.
						insertableCampaignMembers.add(new CampaignMember(CampaignId = campaignId, ContactId = contactId, Status = campaignsMap.get(campaignId)?.ContactAssignmentDefaultStatus__c,
								Campaign_Member_Notes__c=contactIdAssignmentMap.get(contactId).Description__c,Campaign_Contact_Assignment__c=contactIdAssignmentMap.get(contactId).Id));
					}
				}
			}

			if(!insertableCampaignMembers.isEmpty()) {
				uow.registerNew(insertableCampaignMembers);
			}
			if(!updateableCampaignMembers.isEmpty()) {
				uow.registerDirty(updateableCampaignMembers);
			}


		}
	
	}
	
	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) CampaignAssignCampaignMembersModule.newInstance();
		}
	}
}