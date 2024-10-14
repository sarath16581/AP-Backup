/**
 * @description Application Module to handle the milestone of Unified cases. The filtering of Unified cases is done at the Trigger handler level
 * @author George Nguyen
 * @date 2024-10-09
 * @test CaseUnifiedMilestoneModuleTest
 * @changelog
 * 2024-10-09 - George Nguyen - Created.
 */
public inherited sharing class CaseUnifiedMilestoneModule extends ApplicationModule {

	// Unifield Entitlement to be linked with case
	@TestVisible
	private Id unifiedEntitlementId {
		get {
			if(unifiedEntitlementId == null) {
				List<Entitlement> entitlements = EntitlementsSelector.newInstance().selectByNameAndAccountName(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}, new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS});
				if(entitlements.isEmpty() == false) {
					unifiedEntitlementId = entitlements[0].Id;
				}
			}
			return unifiedEntitlementId;
		}
		private set;
	}

	public static CaseUnifiedMilestoneModule newInstance() {
		return (CaseUnifiedMilestoneModule) Application.Utilities.newInstance(CaseUnifiedMilestoneModule.class);
	}

	public CaseUnifiedMilestoneModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	/**
	 * Sets the EntitlementId on the Case which will insert the Milestones automatically by SF. 
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			insertMilestones((List<Case>) records, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseUnifiedMilestoneModule.class.getName(), 'onAfterInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Updates the Milestones related to the case; such as start/stop and remainder
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			updateMilestones((List<Case>) records, (Map<Id, Case>) existingRecords, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseUnifiedMilestoneModule.class.getName(), 'onAfterUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * This method sets the EntitlementId on the Case when the Case.Type = Investigation. This will trigger the Milestone creation automatically be SF. 
	 * Note: we are not checking for record type = Unified as it will be filtered at the trigger handler level. 
	 */
	void insertMilestones(List<Case> records, ApplicationUnitOfWork uow) {
		if(unifiedEntitlementId != null) {
			for(Case c: records) {
				if(c.Type == SSSWConstants.CASE_TYPE_INVESTIGATION) {
					c.EntitlementId = unifiedEntitlementId; 
				}
			}
		}
	}

	/**
	 * This method sets Stop/Start on milestones whenever a unified case is Closed/Opens. 
	 * It also checks if the Case.Type has changed from Unified General Enquiry to Unified Investigation and sets the EntitlementId to start the milestones.
	 */
	void updateMilestones(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow) {
		if(unifiedEntitlementId != null) {
			// for AfterUpdate Scenario, check for changed state
			String context = CaseUnifiedMilestoneModule.class.getName();
			Set<SObjectField> monitoredFields = new Set<SObjectField>{ Case.Type, Case.Status };
			List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, records, existingRecords, monitoredFields);
			Set<String> closedStatus = Utility.getCaseClosedStatus();   // set of closed case statuses
			
			List<Case> milestoneStoppedCases = new List<Case>();
			List<Case> milestoneResumedCases = new List<Case>();
			Set<Id> caseIdToUpdateMilestones = new Set<Id>(); 

			// Eligibility Check on changed state
			for (ApplicationRecursion.RecordState recordState : changedRecords) {
				Case csRec = (Case)recordState.record;
				Set<SObjectField> changedFields = recordState.changedFields;
				Map<String, Object> previousState = recordState.previousState;
				
				// check if the Type has changed from General Enquiry to Investigation then set the EntitlementId on the case to start the milestones
				if(changedFields.contains(Case.Type) == true) {
					if(String.valueOf(previousState.get('Type')) == SSSWConstants.CASE_TYPE_GENERAL_ENQUIRY && csRec.Type == SSSWConstants.CASE_TYPE_INVESTIGATION) {
						csRec.EntitlementId = unifiedEntitlementId;
						caseIdToUpdateMilestones.add(csRec.Id); // this is required because the milestones will be created upon setting the Case.EntitlementId. 
					}
				}

				/** 
				 * If the Case.Status has changed to a Closed status then we need to flag it as Stopped = True and we also need to Stop the Milestones. 
				 * If the Case.Status has change to a Not Closed status then we need to flag it as Stopped = False and we also need to Start the milestones.
				 */
				if(changedFields.contains(Case.Status) == true) {
					String oldCaseStatus = String.valueOf(previousState.get('Status'));
					if(closedStatus.contains(oldCaseStatus) == false && closedStatus.contains(csRec.Status) == true) {
						csRec.IsStopped = true;
						milestoneStoppedCases.add(csRec);
					} else if(closedStatus.contains(oldCaseStatus) == true && closedStatus.contains(csRec.Status) == false) {
						csRec.IsStopped = false;
						milestoneResumedCases.add(csRec);
					}
				}
			}

			if(milestoneStoppedCases.isEmpty() == false) {
				setMilestoneCompletionDates(milestoneStoppedCases, Datetime.now(), uow); // this will set the Completion Date and IsCompleted will be come True
			}

			if(milestoneResumedCases.isEmpty() == false) {
				setMilestoneCompletionDates(milestoneResumedCases, null, uow); // this will resume the milestone
			}

			if (caseIdToUpdateMilestones.isEmpty() == false) {
				Map<String, Object> params = new Map<String, Object>{ 'caseIds' => caseIdToUpdateMilestones };
				uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(AsyncUpdateCaseMilestoneWorker.class, params));
			}
		}
	}

	
	/*
		Ths method will scan for all non-violated milestones and set them to Completed
	*/
	private void setMilestoneCompletionDates(List<Case> cases, Datetime completionDate, ApplicationUnitOfWork uow){
		List<CaseMilestone> milestonesToUpdate = new List<CaseMilestone>();
		Map<Id, Case> casesMap = new Map<Id, Case>(cases);
		Set<Object> filterOptions = new Set<Object>{CaseMilestonesSelector.Options.FILTER_NOT_VIOLATED};
		// if the completion date is specified then only update the ones that have IsCompleted = False, or else update only those with IsComplete = True (ie. setting it to null)
		if(completionDate != null) {
			filterOptions.add(CaseMilestonesSelector.Options.FILTER_NOT_COMPLETED);
		} else {
			filterOptions.add(CaseMilestonesSelector.Options.FILTER_COMPLETED);
		}
		for(CaseMilestone cm: CaseMilestonesSelector.newInstance().selectByCase(casesMap.keySet(), filterOptions).values()) {
			cm.CompletionDate = completionDate;
			milestonesToUpdate.add(cm);
		}
		
		if(milestonesToUpdate.isEmpty() == false) {
			uow.registerDirty(milestonesToUpdate);
		}
	} 
	
	/**
	 * Inner class to register a New Async Worker to update the Start Date on the related Case Milestone records
	 */
	public without sharing class AsyncUpdateCaseMilestoneWorker extends ApplicationUnitOfWork.AsyncWorker {
		@TestVisible
		Set<Id> caseIds = new Set<Id>();
		@TestVisible
		Datetime milestoneStartDate = Datetime.now();

		public override Type getClassType() {
			return AsyncUpdateCaseMilestoneWorker.class;
		}

		/**
		 * The primary object that will be manipulated with this Async Worker.
		 * @return  `SObjectType`
		 */
		public override SObjectType getSObjectTypeGroup() {
			return Case.SObjectType;
		}

		/**
		 * To populate the Object params variable
		 * @param serialisedParams
		 */
		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				Map<String, Set<Id>> params = (Map<String, Set<Id>>) JSON.deserialize(serialisedParams, Map<String, Set<Id>>.class);
				caseIds = params.get('caseIds');
			}
		}

		/**
		 * Perform contact updates for the chosen contactIds passed via params
		 * @param uow
		 */
		public override void execute(ApplicationUnitOfWork uow) {
			List<CaseMilestone> milestonesToUpdate = new List<CaseMilestone>();
			Set<Object> filterOptions = new Set<Object>{CaseMilestonesSelector.Options.FILTER_NOT_COMPLETED};

			for(CaseMilestone cm: CaseMilestonesSelector.newInstance().selectByCase(caseIds, filterOptions).values()) {
				cm.StartDate = milestoneStartDate;
				milestonesToUpdate.add(cm);
			}
			
			if(milestonesToUpdate.isEmpty() == false) {
				uow.registerDirty(
					milestonesToUpdate,
					false, // do not throw exception on error as it is async. It will be logged
					CaseUnifiedMilestoneModule.class.getName() +
					'.' +
					AsyncUpdateCaseMilestoneWorker.class.getName()
				);
			}
		}
	}
}