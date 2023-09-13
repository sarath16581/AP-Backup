/**
 * @description Application Module to handle sales pipeline related automation on an opportunity.
 * @author Ranjeewa Silva
 * @date 2023-08-07
 * @test OpportunitySalesPipelineModule_Test
 * @changelog
 * 2023-08-07 - Ranjeewa Silva - Created.
 */
public inherited sharing class OpportunitySalesPipelineModule extends ApplicationModule {

	@TestVisible private static final Set<String> OPPORTUNITY_STAGES_VALIDATE_COMPETITORS = new Set<String>{'Propose', 'Negotiate', 'Closed Won'};
	@TestVisible private static final Set<String> OPPORTUNITY_STAGES_VALIDATE_NO_OPEN_DSR = new Set<String>{'Closed Won'};
	@TestVisible private static final Set<String> OPPORTUNITY_STAGES_VALIDATE_NO_ACTIVE_CONTRACT = new Set<String>{'Closed Lost', 'Closed Disqualified', 'Closed Duplicate'};

	private static Set<String> MONITORED_OPPORTUNITY_STAGES {
		get {
			if (MONITORED_OPPORTUNITY_STAGES == null) {
				Set<String> monitored = new Set<String>();
				monitored.addAll(OPPORTUNITY_STAGES_VALIDATE_COMPETITORS);
				monitored.addAll(OPPORTUNITY_STAGES_VALIDATE_NO_OPEN_DSR);
				monitored.addAll(OPPORTUNITY_STAGES_VALIDATE_NO_ACTIVE_CONTRACT);
				MONITORED_OPPORTUNITY_STAGES = monitored;
			}
			return MONITORED_OPPORTUNITY_STAGES;
		}
		set;
	}

	public OpportunitySalesPipelineModule() {
		getTriggerEvents().enableBeforeUpdate();
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {

		try {
			// monitor opportunities changing stage. leverage ApplicationRecursion class to retrieve processable records
			// where the stage has been changed since the last execution of this module in a recursive update scenario.
			List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('OpportunitySalesPipelineModule', records, existingRecords, new Set<SObjectField>{
					Opportunity.StageName
			});

			// from the opportunities changing stage, collect opportunities moving to a stage where additional validations
			// are to be performed by this module.
			Map<Id, Opportunity> verifiableOpportunities = new Map<Id, Opportunity>();

			for (ApplicationRecursion.RecordState recordState : changedRecords) {
				Opportunity opportunityRecord = (Opportunity) recordState.record;

				if (MONITORED_OPPORTUNITY_STAGES.contains(opportunityRecord.StageName)) {
					verifiableOpportunities.put(opportunityRecord.Id, opportunityRecord);
				}
			}

			if (!verifiableOpportunities.isEmpty()) {
				// validate opportunities and add errors to records
				validateRelatedRecordsMeetEntryCriteriaOnStageChange(verifiableOpportunities);
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', OpportunitySalesPipelineModule.class.getName(),
					'onBeforeUpdate', String.valueOf(Opportunity.SObjectType), ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Check opportunities meet entry criteria for moving into target stage. Only complex validations that cannot
	 * be achieved efficiently through custom validation rules are performed in apex code.
	 *
	 * Custom validation rules are the preferred option for validations supported by custom validation rules when it doesn't
	 * adversely impacting overall transaction performance.
	 *
	 * @param records opportunity records to be validated
	 */
	private void validateRelatedRecordsMeetEntryCriteriaOnStageChange(Map<Id, Opportunity> records) {

		// query opportunities with related records so required validations can be performed.
		// use field overrides to query only the fields necessary for validations.
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Opportunity.SObjectType => new Set<SObjectField>{Opportunity.Id, Opportunity.StageName},
				Competitor__c.SObjectType => new Set<SObjectField>{Competitor__c.Id},
				Deal_Support_Request__c.SObjectType => new Set<SObjectField>{Deal_Support_Request__c.Id, Deal_Support_Request__c.Stage__c},
				Apttus__APTS_Agreement__c.SObjectType => new Set<SObjectField>{Apttus__APTS_Agreement__c.Id, Apttus__APTS_Agreement__c.Apttus__Status__c}
		};

		Map<Id, Opportunity> opportunitiesWithChildRecords = ((OpportunitiesSelector) OpportunitiesSelector.newInstance()
				.setFieldOverrides(fieldOverrides))
				.selectById(records.keySet(), new Set<Object>{
					OpportunitiesSelector.Options.WITH_COMPETITORS,
					OpportunitiesSelector.Options.WITH_DEAL_SUPPORT_REQUESTS,
					OpportunitiesSelector.Options.WITH_APTTUS_CONTRACTS,
					DealSupportRequestsSelector.Options.WITH_RECORDTYPE,
					ApttusContractsSelector.Options.WITH_RECORDTYPE
				});

		for (Opportunity record: records.values()) {

			Opportunity opportunityWithChildRecords = opportunitiesWithChildRecords.get(record.Id);

			// check competitors are recorded on opportunity before progressing stage
			if (OPPORTUNITY_STAGES_VALIDATE_COMPETITORS.contains(record.StageName)
					&& opportunityWithChildRecords.Competitors__r.isEmpty()) {

				record.addError(Label.CompetitorsRequiredBeforeMovingOpportunityStageErrorMessage);
			}

			// check child DSRs are closed before progressing opportunity stage
			if (OPPORTUNITY_STAGES_VALIDATE_NO_OPEN_DSR.contains(record.StageName)
					&& !opportunityWithChildRecords.Deal_Support_Request__r.isEmpty()) {

				validateDSRsAreClosed(record, opportunityWithChildRecords.Deal_Support_Request__r);
			}

			// check no Active Apttus Contracts on Closed Lost/Disqualified or Duplicate opportunity
			if (OPPORTUNITY_STAGES_VALIDATE_NO_ACTIVE_CONTRACT.contains(record.StageName)
					&& !opportunityWithChildRecords.Apttus__R00N50000001Xl0FEAS__r.isEmpty()) {

				for (Apttus__APTS_Agreement__c apttusContract: opportunityWithChildRecords.Apttus__R00N50000001Xl0FEAS__r) {
					if (apttusContract.Apttus__Status__c == 'Activated' || apttusContract.Apttus__Status__c == 'Fully Signed' || apttusContract.Apttus__Status__c == 'SFDC DSR Created') {
						record.addError(Label.OpportunityWithActiveApttusContractCannotBeClosedLostErrorMessage);
						break;
					}
				}
			}
		}
	}

	/**
	 * Validate child DSRs are closed.
	 *
	 * @param record opportunity record going through DML operation.
	 * @param relatedDSRs related DSR records
	 */
	private void validateDSRsAreClosed(Opportunity record, List<Deal_Support_Request__c> relatedDSRs) {
		Map<String, List<Deal_Support_Request__c>> openDSRsByRecordType = new Map<String, List<Deal_Support_Request__c>>();
		for (Deal_Support_Request__c dsr: relatedDSRs) {
			if (dsr.RecordType.DeveloperName != 'Deal_Enablement_Centre' && dsr.Stage__c != 'Completed' && dsr.Stage__c != 'Closed') {
				List<Deal_Support_Request__c> openDSRs = openDSRsByRecordType.get(dsr.RecordType.Name);
				if (openDSRs == null) {
					openDSRs = new List<Deal_Support_Request__c>();
					openDSRsByRecordType.put(dsr.RecordType.Name, openDSRs);
				}
				openDSRs.add(dsr);
			}
		}

		if (!openDSRsByRecordType.isEmpty()) {
			String errorMessage = Label.DSRsMustbeClosedBeforeCloseWinOpportunityErrorMessage + '. Open support requests - ';

			for (String recordType: openDSRsByRecordType.keySet()) {
				errorMessage += (recordType + '(' + openDSRsByRecordType.get(recordType).size() + '), ');
			}

			record.addError((errorMessage.removeEnd(', ') + '.'));
		}
	}
}