/**
 * @description
 * Handles some of the case routing capabilities for SSSW cases
 *
 * @author Nathan Franklin
 * @date 2022-10-30
 * @group Domain
 * @domain SSSW
 * @changelog
 *
 */
public inherited sharing class MyCustomerCaseRoutingModule extends ApplicationDomain.Module {

	public static MyCustomerCaseRoutingModule newInstance() {
		return (MyCustomerCaseRoutingModule)Application.Utilities.newInstance(MyCustomerCaseRoutingModule.class);
	}

	// Setup which triggers this module should respond to
	public MyCustomerCaseRoutingModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			// check whether the queue has changed to an omni skills based queue that we are monitoring to manually create a PSR record
			// we do this since skills mappings are custom maintained and we have custom priority logic (oldest case created take priority over other cases in the same priority)
			maybeTriggerOmniAssignment((List<Case>)records, null);

		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, MyCustomerCaseRoutingModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			// check whether the queue has changed to an omni skills based queue that we are monitoring to manually create a PSR record
			// we do this since skills mappings are custom maintained and we have custom priority logic (oldest case created take priority over other cases in the same priority)
			maybeTriggerOmniAssignment((List<Case>)records, (Map<Id, Case>)existingRecords);

		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, MyCustomerCaseRoutingModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	Id serviceChannelId {
		get{
			if(serviceChannelId == null) {
				serviceChannelId = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'Case_Channel'].Id;
			}
			return serviceChannelId;
		}
		set;
	}

	Map<Id, QueueRoutingConfig> omniQueueIdsVsRoutingConfig {
		get{
			if(omniQueueIdsVsRoutingConfig == null) {
				omniQueueIdsVsRoutingConfig = new Map<Id, QueueRoutingConfig>();

				Map<String, String> omniQueueDeveloperNamesVsRoutingConfigDeveloperNames = new Map<String, String> {
					'SSSW_Consumer_Back_Office_High_Priority' => 'AP_SSSW_Consumer_BOH_High_Priority',
					'SSSW_Consumer_Back_Office_Low_Priority' => 'AP_SSSW_Consumer_BOH_Low_Priority'
				};

				Map<String, QueueRoutingConfig> developerNameVsRoutingConfigs = new Map<String, QueueRoutingConfig>();
				for(QueueRoutingConfig rc: [SELECT CapacityPercentage, CapacityWeight, DropAdditionalSkillsTimeout, IsAttributeBased, OverflowAssigneeId, PushTimeout, RoutingModel, RoutingPriority,DeveloperName
														FROM QueueRoutingConfig 
														WHERE DeveloperName In :omniQueueDeveloperNamesVsRoutingConfigDeveloperNames.values() AND IsAttributeBased = true]) // NOTE: IsAttributeBased denotes skills based routing
				{
					developerNameVsRoutingConfigs.put(rc.DeveloperName, rc);
				}

				for(Group queue: [SELECT DeveloperName FROM Group WHERE DeveloperName IN :omniQueueDeveloperNamesVsRoutingConfigDeveloperNames.keySet()]) {
					omniQueueIdsVsRoutingConfig.put(queue.Id, developerNameVsRoutingConfigs.get(omniQueueDeveloperNamesVsRoutingConfigDeveloperNames.get(queue.DeveloperName)));
				}
			}
			return omniQueueIdsVsRoutingConfig;
		}
		set;
	}

	public static final Map<SObjectField, Map<String, Id>> caseFieldSkillMappings = new Map<SObjectField, Map<String, Id>>{
		Case.CustomerQueueType__c => new Map<String, Id>{
			'Consumer' => '0C56D00000002B2SAI'
		}, 
		Case.Status => new Map<String, Id>{
			'ACL Compensation Assessment' => '0C56D00000002B7SAI'
		}, 
		Case.ProductCategory__c => new Map<String, Id>{
			'Money & Insurance' => '0C56D00000002BRSAY',
			'Travel & ID' => '0C56D00000002BRSAY',
			'Web & Apps' => '0C56D00000002BRSAY',
			'Post Office & Business Hub Services' => '0C56D00000002BRSAY'
		}, 
		Case.ProductSubCategory__c => new Map<String, Id>{
			'Mail Redirection' => '0C56D00000002BCSAY',
			'Mail Hold' => '0C56D00000002BCSAY',
			'My Post ID card' => '0C56D00000002BHSAY',
			'MyPost Concession Card' => '0C56D00000002BHSAY',
			'MyPost Deliveries' => '0C56D00000002BHSAY',
			'Express Post' => '0C56D00000002BRSAY',
			'Express' => '0C56D00000002BRSAY',
			'eParcel- Express' => '0C56D00000002BRSAY',
			'Registered Post' => '0C56D00000002BRSAY',
			'Express Platinum' => '0C56D00000002BRSAY',
			'Premium Express Parcel' => '0C56D00000002BRSAY'
		}, 
		Case.EnquirySubType__c => new Map<String, Id>{
			'Delivery Complaint' => '0C56D00000002BRSAY',
			'Item Transfer' => '0C56D00000002BRSAY',
			'Redirection Failure' => '0C56D00000002BCSAY',
			'Disputed delivery scan' => '0C56D00000002BRSAY',
			'All Other' => '0C56D00000002BRSAY'
		},
		Case.CustomerQueueType__c => new Map<String, Id>{
			'TRUE' => '0C56D00000002BMSAY'
		}
	};

	/**
	 * Check a bunch of use cases to determine whether a case should be routed to a servicable queue or not
	 * NOTE: These use cases were a port from Workflows
	 */
	public void maybeTriggerOmniAssignment(List<Case> cases, Map<Id, Case> oldCases) {

		Map<Id, Case> processable = new Map<Id, Case>();
		Set<Id> routingConfigurationIds = new Set<Id>();

		for(Case caseRecord : cases) {
			Case oldCase = oldCases?.get(caseRecord.Id);

			if(omniQueueIdsVsRoutingConfig.containsKey(caseRecord.OwnerId) == true 
				&& omniQueueIdsVsRoutingConfig.get(caseRecord.OwnerId) != null // only deal with this case if there is a matching config for it
				&& (oldCase == null || caseRecord.OwnerId != oldCase.OwnerId)) {
				processable.put(caseRecord.Id, caseRecord);
			}
		}

		if(processable.isEmpty() == false) {

			Map<Id, PendingServiceRouting> casePsrRecords = new Map<Id, PendingServiceRouting>();
			List<SkillRequirement> skillRequirementRecords = new List<SkillRequirement>();
			
			List<PendingServiceRouting> deletablePsrRecords = new List<PendingServiceRouting>();
			Set<Id> excludedManualPsrCreation = new Set<Id>();

			List<SkillRequirement> creatableSkillRequirements = new List<SkillRequirement>();

			List<PendingServiceRouting> psrRecords = [Select Id, WorkItemId, IsPushed, IsPushAttempted From PendingServiceRouting Where WorkItemId In : processable.keySet()];

			// check which psr records can actually deleted
			// we only want to do that if it hasn't already been pushed.
			// if it has been pushed then it's too late for us to do anything about and we need to let Omni do it's thing
			// we also exclude these from manual record creation
			for(PendingServiceRouting psrRecord : psrRecords) {
				if(!psrRecord.IsPushed && !psrRecord.IsPushAttempted) {
					deletablePsrRecords.add(psrRecord);
				} else {
					excludedManualPsrCreation.add(psrRecord.WorkItemId);
				}
			}

			for(Case caseRecord : processable.values()) {
				if(excludedManualPsrCreation.contains(caseRecord.Id) == false) {
					// the routing configuration was found so we can use this to create a PSR record

					QueueRoutingConfig routingConfiguration = omniQueueIdsVsRoutingConfig.get(caseRecord.OwnerId);

					//IsPushAttempted, IsPushed, SecondaryRoutingPriority
					casePsrRecords.put(caseRecord.Id, new PendingServiceRouting(
						CapacityPercentage = routingConfiguration.CapacityPercentage, 
						CapacityWeight = routingConfiguration.CapacityWeight, 
						DropAdditionalSkillsTimeout = routingConfiguration.DropAdditionalSkillsTimeout,
						PushTimeout = routingConfiguration.PushTimeout, 
						RoutingModel = routingConfiguration.RoutingModel, 
						RoutingPriority = routingConfiguration.RoutingPriority, 
						CustomRequestedDateTime = caseRecord.CreatedDate, 
						WorkItemId = caseRecord.Id,
						IsReadyForRouting = false,
						RoutingType = 'SkillsBased', 
						ServiceChannelId = serviceChannelId
					));
				}
			}

			// remove all existing psr records for the work items here since we are creating new ones
			if(!deletablePsrRecords.isEmpty()) {
				ApplicationDatabase.getInstance().dmlDelete(deletablePsrRecords);
			}

			if(!casePsrRecords.isEmpty()) {
				// start the pending routing record process off
				ApplicationDatabase.getInstance().dmlInsert(casePsrRecords.values());

				List<PendingServiceRouting> finalPsrRecordUpdates = new List<PendingServiceRouting>();
				for(PendingServiceRouting casePsrRecord : casePsrRecords.values()) {

					// add skill requirements for the created psr records
					creatableSkillRequirements.addAll(mapSkillsToCases(processable.get(casePsrRecord.WorkItemId), casePsrRecord.Id));

					// mark the psr record as ready for routing
					finalPsrRecordUpdates.add(new PendingServiceRouting(Id = casePsrRecord.Id, IsReadyForRouting = true));
				}

				if(!creatableSkillRequirements.isEmpty()) {
					ApplicationDatabase.getInstance().dmlInsert(creatableSkillRequirements);
				}

				ApplicationDatabase.getInstance().dmlUpdate(finalPsrRecordUpdates);
			}

		}
	}

	private List<SkillRequirement> mapSkillsToCases(Case caseRecord, Id psrRecordId) {
		List<SkillRequirement> skillRequirements = new List<SkillRequirement>();
		for(SObjectField field : caseFieldSkillMappings.keySet()) {
			if(caseRecord.get(field) != null) {
				for(String fieldValue : caseFieldSkillMappings.get(field).keySet()) {
					if(fieldValue.equalsIgnoreCase((String)caseRecord.get(field))) {
						skillRequirements.add(new SkillRequirement(SkillId = caseFieldSkillMappings.get(field).get(fieldValue), RelatedRecordId = psrRecordId));
					}
				}
			}
		}

		return skillRequirements;
	}

}