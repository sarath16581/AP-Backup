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

	private Map<Id, QueueRoutingConfig> omniQueueIdsVsRoutingConfig {
		get{
			if(omniQueueIdsVsRoutingConfig == null) {
				omniQueueIdsVsRoutingConfig = new Map<Id, QueueRoutingConfig>();

				Map<String, String> omniQueueDeveloperNamesVsRoutingConfigDeveloperNames = new Map<String, String> {
					'SSSW_Consumer_Back_Office_High_Priority' => 'AP_SSSW_Consumer_BOH_High_Priority',
					'SSSW_Consumer_Back_Office_Low_Priority' => 'AP_SSSW_Consumer_BOH_Low_Priority'
				};

				Map<String, QueueRoutingConfig> developerNameVsRoutingConfigs = new Map<String, QueueRoutingConfig>();
				for(QueueRoutingConfig rc: QueueRoutingConfigSelector.newInstance().selectSkillBasedByDeveloperName(omniQueueDeveloperNamesVsRoutingConfigDeveloperNames.values(), new Set<Object>())) {
					developerNameVsRoutingConfigs.put(rc.DeveloperName, rc);
				}

				for(Group queue: GroupsSelector.newInstance().selectByDeveloperName(omniQueueDeveloperNamesVsRoutingConfigDeveloperNames.keySet()).values()) {
					omniQueueIdsVsRoutingConfig.put(queue.Id, developerNameVsRoutingConfigs.get(omniQueueDeveloperNamesVsRoutingConfigDeveloperNames.get(queue.DeveloperName)));
				}
			}
			return omniQueueIdsVsRoutingConfig;
		}
		set;
	}

	private final Map<SObjectField, Map<String, String>> caseFieldSkillMappings = new Map<SObjectField, Map<String, String>>{
		Case.CustomerQueueType__c => new Map<String, String>{
			'Consumer' => 'Consumer'
		}, 
		Case.Status => new Map<String, String>{
			'ACL Compensation Assessment' => 'Compensation_Assessment'
		}, 
		Case.ProductCategory__c => new Map<String, String>{
			'Money & Insurance' => 'BOH_Standard',
			'Travel & ID' => 'BOH_Standard',
			'Web & Apps' => 'BOH_Standard',
			'Post Office & Business Hub Services' => 'BOH_Standard'
		}, 
		Case.ProductSubCategory__c => new Map<String, String>{
			'Mail Redirection' => 'Special_Delivery',
			'Mail Hold' => 'Special_Delivery',
			'My Post ID card' => 'My_Post',
			'MyPost Concession Card' => 'My_Post',
			'MyPost Deliveries' => 'My_Post',
			'Express Post' => 'BOH_Standard',
			'Express' => 'BOH_Standard',
			'eParcel- Express' => 'BOH_Standard',
			'Registered Post' => 'BOH_Standard',
			'Express Platinum' => 'BOH_Standard',
			'Premium Express Parcel' => 'BOH_Standard'
		}, 
		Case.EnquirySubType__c => new Map<String, String>{
			'Delivery Complaint' => 'BOH_Standard',
			'Item Transfer' => 'BOH_Standard',
			'Redirection Failure' => 'Special_Delivery',
			'Disputed delivery scan' => 'BOH_Standard',
			'All Other' => 'BOH_Standard'
		},
		Case.HasExtraCover__c => new Map<String, String>{
			'TRUE' => 'Extra_Cover'
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

			List<PendingServiceRouting> psrRecords = PendingServiceRoutingSelector.newInstance().selectByWorkItemId(processable.keySet(), new Set<Object>());

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

			ServiceChannel sc = Application.Cache.serviceChannels.get('Case_Channel');

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
						ServiceChannelId = sc.Id
						// SecondaryRoutingPriority = 1000 //TODO:.... good luck! SF stores the mapping as value index on the selected field (e.g. picklist values)
					));
				}
			}

			// remove all existing psr records for the work items here since we are creating new ones
			if(!deletablePsrRecords.isEmpty()) {
				ApplicationDatabase.getInstance().dmlDelete(deletablePsrRecords);
			}

			if(casePsrRecords.isEmpty() == false) {
				// start the pending routing record process off
				ApplicationDatabase.getInstance().dmlInsert(casePsrRecords.values());

				List<PendingServiceRouting> finalPsrRecordUpdates = new List<PendingServiceRouting>();
				for(PendingServiceRouting casePsrRecord : casePsrRecords.values()) {

					// add skill requirements for the created psr records
					creatableSkillRequirements.addAll(mapSkillsToCases(processable.get(casePsrRecord.WorkItemId), casePsrRecord.Id));

					// mark the psr record as ready for routing
					finalPsrRecordUpdates.add(new PendingServiceRouting(Id = casePsrRecord.Id, IsReadyForRouting = true));
				}

				if(creatableSkillRequirements.isEmpty() == false) {
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
					if(fieldValue.equalsIgnoreCase(String.valueOf(caseRecord.get(field))) == true) {
						Id skillId = Application.Cache.skillDeveloperNameVsIds.get(caseFieldSkillMappings.get(field).get(fieldValue));
						if(skillId != null) {
							skillRequirements.add(new SkillRequirement(SkillId = skillId, RelatedRecordId = psrRecordId));
						}
					}
				}
			}
		}

		return skillRequirements;
	}

}