/**
 * @description Application Module to handle sales pipeline related automation on an opportunity.
 * @author Ranjeewa Silva
 * @date 2023-08-07
 * @test OpportunitySalesPipelineModule_Test
 * @changelog
 * 2023-08-07 - Ranjeewa Silva - Created.
 * 2023-10-16 - Mahesh Parvathaneni - STP-9274 - Added validation when incorrect overlay type assigned to team members
 * 2023-10-25 - Mahesh Parvathaneni - STP-8264 - Added validation to make sure at least one of the opp products have quantity more than 1
 * 2024-01-22 - Mahesh Parvathaneni - STP-9169 - Added validation to make sure the related opp products have valid revenue start date (must be later or equal to close date)
 * 2024-01-25 - Mahesh Parvathaneni - STP-9712 - Added logic to bypass validations for CRM specialists based on custom permission
 * 2024-02-02 - Mahesh Parvathaneni - STP-10398 - Added logic to bypass opp products quantity validation based on custom permission
 * 2024-06-16 - Sarath Burra - ST-10723 - Added Logic to Update Account.IndirectCustomer__c field based on same field in Opportutniy in AfterInsert and AfterUpdate
 */
public inherited sharing class OpportunitySalesPipelineModule extends ApplicationModule {

	@TestVisible private static final Set<String> OPPORTUNITY_STAGES_VALIDATE_COMPETITORS = new Set<String>{'Propose', 'Negotiate', 'Closed Won'};
	@TestVisible private static final Set<String> OPPORTUNITY_STAGES_VALIDATE_NO_OPEN_DSR = new Set<String>{'Closed Won'};
	@TestVisible private static final Set<String> OPPORTUNITY_STAGES_VALIDATE_NO_ACTIVE_CONTRACT = new Set<String>{'Closed Lost', 'Closed Disqualified', 'Closed Duplicate'};
	@TestVisible private static final Set<String> OPPORTUNITY_STAGES_VALIDATE_OPP_SPLITS_OVERLAY_CONTRIBUTION = new Set<String>{'Qualify', 'Propose', 'Negotiate', 'Closed Won'};
	@TestVisible private static final Set<String> OPPORTUNITY_STAGES_VALIDATE_PRODUCTS_QUANTITY = new Set<String>{'Qualify', 'Propose', 'Negotiate', 'Closed Won'};
	@TestVisible private static final Set<String> OPPORTUNITY_STAGES_VALIDATE_PRODUCTS_REVENUE_START_DATE = new Set<String>{'Qualify', 'Propose', 'Negotiate', 'Closed Won'};
	@TestVisible private static final Set<String> CONTRACT_STAGES_ACTIVE_INFLIGHT_CONTRACT = new Set<String>{'In Signatures', 'In Effect', 'Amended', 'Renewed'};

	private static Set<String> MONITORED_OPPORTUNITY_STAGES {
		get {
			if (MONITORED_OPPORTUNITY_STAGES == null) {
				Set<String> monitored = new Set<String>();
				monitored.addAll(OPPORTUNITY_STAGES_VALIDATE_COMPETITORS);
				monitored.addAll(OPPORTUNITY_STAGES_VALIDATE_NO_OPEN_DSR);
				monitored.addAll(OPPORTUNITY_STAGES_VALIDATE_NO_ACTIVE_CONTRACT);
				monitored.addAll(OPPORTUNITY_STAGES_VALIDATE_OPP_SPLITS_OVERLAY_CONTRIBUTION);
				monitored.addAll(OPPORTUNITY_STAGES_VALIDATE_PRODUCTS_QUANTITY);
				monitored.addAll(OPPORTUNITY_STAGES_VALIDATE_PRODUCTS_REVENUE_START_DATE);
				MONITORED_OPPORTUNITY_STAGES = monitored;
			}
			return MONITORED_OPPORTUNITY_STAGES;
		}
		set;
	}

	//checks for the custom permission to bypass validations
	private static final Boolean hasByPassErrorsForOpportunityValidationsPermission {
		get {
			if (hasByPassErrorsForOpportunityValidationsPermission == null) {
				hasByPassErrorsForOpportunityValidationsPermission = FeatureManagement.checkPermission('ByPassErrorsForOpportunityValidations');
			}
			return hasByPassErrorsForOpportunityValidationsPermission;
		}
		private set;
	}

	//checks for the custom permission to bypass opportunity products quantity validation
	private static final Boolean hasByPassErrorForOpportunityLineItemQuantityValidationPermission {
		get {
			if (hasByPassErrorForOpportunityLineItemQuantityValidationPermission == null) {
				hasByPassErrorForOpportunityLineItemQuantityValidationPermission = FeatureManagement.checkPermission('ByPassErrorForOpportunityLineItemQuantityValidation');
			}
			return hasByPassErrorForOpportunityLineItemQuantityValidationPermission;
		}
		private set;
	}

	public OpportunitySalesPipelineModule() {
		getTriggerEvents().enableBeforeUpdate();
		getTriggerEvents().enableAfterInsert();
		getTriggerEvents().enableAfterUpdate();
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
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateAccountDetails(records,new Map<Id,SObject>(),uow);

		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', OpportunitySalesPipelineModule.class.getName(),
			'onAfterInsert', String.valueOf(Opportunity.SObjectType), ApplicationLogger.LoggingLevel.ERROR);
		}
	}
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			updateAccountDetails(records, existingRecords,  uow);

		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', OpportunitySalesPipelineModule.class.getName(),
			'onAfterUpdate', String.valueOf(Opportunity.SObjectType), ApplicationLogger.LoggingLevel.ERROR);
		}
	}
	private void updateAccountDetails(List<SObject> records,Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		Map<Id,String> accountIdToIndirectCustMap = new Map<Id,String>();
		List<Account> updatedAccounts = new List<Account> ();
		
		// monitor opportunities changing stage. leverage ApplicationRecursion class to retrieve processable records
			// where the IndirectCustomer__c has been changed since the last execution of this module in a recursive update scenario.
			List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('OpportunitySalesPipelineModule', records, existingRecords, new Set<SObjectField>{
				Opportunity.IndirectCustomer__c
		});

				
		//Update Indirect Customer field on Account based on Indirect Customer Field on Opportunity for Insert and Update scenarios
		for(ApplicationRecursion.RecordState  crec : changedRecords){
			Opportunity opp =(Opportunity)crec.record;
			if(null!=opp.AccountId && !string.isEmpty(opp.IndirectCustomer__c)){
				accountIdToIndirectCustMap.put(opp.AccountId,opp.IndirectCustomer__c);
			}
		}
		if(!accountIdToIndirectCustMap.isEmpty()){	
			Map<Id, Account> accMap =AccountsSelector.newInstance(1, new Set<SObjectField>{Account.Id, Account.IndirectCustomer__c}).selectById(accountIdToIndirectCustMap.keySet());
			for(Id accId :accMap.keySet()){
				Account acc= accMap.get(accId);
				acc.IndirectCustomer__c=accountIdToIndirectCustMap.get(accId);
				updatedAccounts.add(acc);
				break;	
			}	
		}	
		if (!updatedAccounts.isEmpty()) {
			uow.registerDirty(updatedAccounts);
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
				Apttus__APTS_Agreement__c.SObjectType => new Set<SObjectField>{Apttus__APTS_Agreement__c.Id, Apttus__APTS_Agreement__c.Apttus__Status_Category__c},
				OpportunitySplit.SObjectType => new Set<SObjectField>{OpportunitySplit.Id, OpportunitySplit.Overlay_Type__c, OpportunitySplit.SplitOwnerId},
				OpportunityLineItem.SObjectType => new Set<SObjectField>{OpportunityLineItem.Id, OpportunityLineItem.Quantity, OpportunityLineItem.Contract_Start_Date__c}
		};

		Map<Id, Opportunity> opportunitiesWithChildRecords = ((OpportunitiesSelector) OpportunitiesSelector.newInstance()
				.setFieldOverrides(fieldOverrides))
				.selectById(records.keySet(), new Set<Object>{
					OpportunitiesSelector.Options.WITH_COMPETITORS,
					OpportunitiesSelector.Options.WITH_DEAL_SUPPORT_REQUESTS,
					OpportunitiesSelector.Options.WITH_APTTUS_CONTRACTS,
					DealSupportRequestsSelector.Options.WITH_RECORDTYPE,
					ApttusContractsSelector.Options.WITH_RECORDTYPE,
					OpportunitiesSelector.Options.WITH_OVERLAY_SPLITS,
					OpportunitiesSelector.Options.WITH_OPPORTUNITY_LINE_ITEMS
				});

		//get the allowed overlay contribution types for the opp splits team members based on the custom 
		//metadata SalesOverlayTypeMapping__mdt configuration and public group membership check from OpportunitySplitUtility.getEligibleOverlayContributionTypes method
		//Set<String> -- {'Sales Specialist', 'Product Specialist'}
		//Map<Id, Set<String>> -- {'0051v00000i5Bx6AAE' => {'Sales Specialist', 'Product Specialist'},'0051z00000i5Bx6AAE' => {'Sales Specialist'}}
		Map<Id, Set<String>> eligibleOverlayTypesAssignedBySplitMemberIdMap = getOverlaySplitEligibilityBySplitOwners(opportunitiesWithChildRecords);

		for (Opportunity record: records.values()) {

			Opportunity opportunityWithChildRecords = opportunitiesWithChildRecords.get(record.Id);

			// check competitors are recorded on opportunity before progressing stage
			// bypass the validation for the user with custom permission ByPassErrorsForOpportunityValidations
			if (OPPORTUNITY_STAGES_VALIDATE_COMPETITORS.contains(record.StageName)
					&& opportunityWithChildRecords.Competitors__r.isEmpty() && !hasByPassErrorsForOpportunityValidationsPermission) {

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
					if (CONTRACT_STAGES_ACTIVE_INFLIGHT_CONTRACT.contains(apttusContract.Apttus__Status_Category__c)) {
						record.addError(Label.OpportunityWithActiveApttusContractCannotBeClosedLostErrorMessage);
						break;
					}
				}
			}

			// check opportunity splits in overlay contribution are correctly assigned to correct role of team members 
			// before progressing opportunity stage
			if (OPPORTUNITY_STAGES_VALIDATE_OPP_SPLITS_OVERLAY_CONTRIBUTION.contains(record.StageName)
					&& !opportunityWithChildRecords.OpportunitySplits.isEmpty()) {

					validateOverlayOpportunitySplitAssignmentForSpecialistUsers(record, opportunityWithChildRecords.OpportunitySplits, eligibleOverlayTypesAssignedBySplitMemberIdMap);
			}

			//check at least one of the related opportunity line items have quantity more than 1 before progressing opportunity stage
			//bypass the validation for the user with custom permission ByPassErrorsForOpportunityValidations
			if (OPPORTUNITY_STAGES_VALIDATE_PRODUCTS_QUANTITY.contains(record.StageName) 
					&& !opportunityWithChildRecords.OpportunityLineItems.isEmpty() && !hasByPassErrorsForOpportunityValidationsPermission 
					&& !hasByPassErrorForOpportunityLineItemQuantityValidationPermission) {
				
					validateQuantityOnOpportunityLineItems(record, opportunityWithChildRecords.OpportunityLineItems);
			}

			//check the related opportunity line items have valid revenue start date
			//validate for an opportunity not with pre-entry scenario
			if (OPPORTUNITY_STAGES_VALIDATE_PRODUCTS_REVENUE_START_DATE.contains(record.StageName) 
					&& !record.Pre_Entry__c && !opportunityWithChildRecords.OpportunityLineItems.isEmpty()) {
				
					validateRevenueStartDateOnOpportunityLineItems(record, opportunityWithChildRecords.OpportunityLineItems);
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

	/**
	 * @description function to get the allowed overlay split contribution types for split owner ids from the custom metadata
	 * SalesOverlayTypeMapping__mdt configuration and public group membership check
	 * @param  opportunitiesWithChildRecords map of opportunity records with child opportunity splits
	 * @return Map<Id, Set<String>> map of user ids to eligible overlay contribution types
	 * {'0051v00000i5Bx6AAE' => {'Sales Specialist', 'Product Specialist'},'0051z00000i5Bx6AAE' => {'Sales Specialist'}}
	 */
	private Map<Id, Set<String>> getOverlaySplitEligibilityBySplitOwners(Map<Id, Opportunity> opportunitiesWithChildRecords) {
		Map<Id, Set<String>> overlaySplitEligibilityBySplitOwnerIdMap = new Map<Id, Set<String>>();
		Set<Id> splitOwnerIds = new Set<Id>();

		// loop through the opportunities for opp splits if any and get the split owner ids to 
		// check the group membership
		for (Opportunity opp: opportunitiesWithChildRecords.values()) {
			if (!opp.OpportunitySplits.isEmpty()) {
				for (OpportunitySplit split : opp.OpportunitySplits) {
					splitOwnerIds.add(split.SplitOwnerId);
				}
			}
		}

		//get the eligible overlay contribution types for split owners from the utility method
		//This utility method checks the public group membership of passed user ids and returns the eligibile overlay types 
		//from the SalesOverlayTypeMapping__mdt metadata.
		if (!splitOwnerIds.isEmpty()) {
			overlaySplitEligibilityBySplitOwnerIdMap = OpportunitySplitUtility.getInstance().getEligibleOverlayContributionTypes(splitOwnerIds, null);
		}

		return overlaySplitEligibilityBySplitOwnerIdMap;
	}

	/**
	 * @description validate opp splits are assigned to correct role for the team member
	 * @param  Opportunity record opportunity record going through DML operation.
	 * @param  List<OpportunitySplit> oppSplits overlay contribution opportunity splits
	 * @param  Map<Id,Set<String>> overlaySplitEligibilityBySplitOwnerIdMap map of user ids to eligible overlay types
	 */
	private void validateOverlayOpportunitySplitAssignmentForSpecialistUsers(Opportunity record, List<OpportunitySplit>  oppSplits, Map<Id, Set<String>> overlaySplitEligibilityBySplitOwnerIdMap) {
		List<OpportunitySplit> incorrectOverlaySplits = new List<OpportunitySplit>();

		//loop through splits and validate the overlay type and user role
		for(OpportunitySplit split : oppSplits) {
			if(overlaySplitEligibilityBySplitOwnerIdMap.containsKey(split.SplitOwnerId)) {
				//user found in specialist group, check if the overlay type is allowed to user specialist group
				if (!overlaySplitEligibilityBySplitOwnerIdMap.get(split.SplitOwnerId).contains(split.Overlay_Type__c)) {
					//user is incorrectly assigned to overlay type
					incorrectOverlaySplits.add(split);
				}
			} else {
				//user doesn't belong to any specialist group
				incorrectOverlaySplits.add(split);
			}
		}

		//if any incorrect overlay splits assigned, add it to the record
		if(!incorrectOverlaySplits.isEmpty()) {
			List<String> errorMsgs = new List<String>();

			for (OpportunitySplit incorrectOppSplit : incorrectOverlaySplits) {
				errorMsgs.add(String.format(Label.OpportunityWithIncorrectOverlayTypeSplitsAssignments, new List<String>{incorrectOppSplit.Overlay_Type__c}));
			}

			//added the new line delimiter to show the errors in UI
			String errorMessage = errorMsgs.size() > 1 ? String.join(errorMsgs, '\n') : errorMsgs.get(0);
			record.addError(errorMessage);

		}
	}

	/**
	 * @description validate at least one of the related opportunity line items has quantity more than 1
	 * @param  Opportunity record opportunity record going through DML operation.
	 * @param  List<OpportunityLineItem> relatedOppLineItems related products/opportunity line items
	 */
	private void validateQuantityOnOpportunityLineItems(Opportunity record, List<OpportunityLineItem>  relatedOppLineItems) {
		Set<Id> validQuantityOppLineItemIds = new Set<Id>();
		//loop through related opp line items and check at least one opp line item has quantity more than 1
		for (OpportunityLineItem oli : relatedOppLineItems) {
			if (oli.quantity != null && oli.quantity.round(System.RoundingMode.DOWN) > 1) {
				//add to the valid record list
				validQuantityOppLineItemIds.add(oli.Id);
			}
		}

		//add error to the record if no related opportunity line item found with quantity more than 1.
		if (validQuantityOppLineItemIds.isEmpty()) { 
			record.addError(Label.OpportunityWithInvalidQuantityOnProducts);
		}
	}

	/**
	 * @description function to check the related opportunity line items have valid revenue start date
	 * Revenue start date must be later than or equal to close date
	 * @param  Opportunity record opportunity record going through DML operation.
	 * @param  List<OpportunityLineItem> relatedOppLineItems related products/opportunity line items
	 */
	private void validateRevenueStartDateOnOpportunityLineItems(Opportunity record, List<OpportunityLineItem>  relatedOppLineItems) {
		Set<Id> oppLineItemIdsStartDateLessThanCloseDate = new Set<Id>();
		//loop through related opp line items and check revenue start date greater than today
		for (OpportunityLineItem oli : relatedOppLineItems) {			
			if (oli.Contract_Start_Date__c < record.CloseDate) {
				//revenue start date is less than opportunity close date
				//add to the invalid record list
				oppLineItemIdsStartDateLessThanCloseDate.add(oli.Id);
			}
		}

		//add error to the record if related opportunity line item found with revenue start date less than opportunity close date.
		if (!oppLineItemIdsStartDateLessThanCloseDate.isEmpty()) { 
			record.addError(Label.Opportunity_Confirm_Pre_Entry_Scenario);
		}
	}
}