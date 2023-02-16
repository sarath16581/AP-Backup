/**
 * @description       : This module handles the network milestone violation related logic
 * @author            : Mahesh Parvathaneni
 * @domain            : Case Investigation
 * @changelog
 * 2023-01-25 - Mahesh Parvathaneni - created
 **/

public inherited sharing class STCINetworkMilestoneViolationModule extends ApplicationDomain.Module {

	//constants
	@TestVisible
	private static final string ENTITLEMENT_RULE_CASE_INVESTIGATION = 'Case_Investigation';
	@TestVisible
	private static final string MILESTONE_TIER_TYPE_FACILITY = 'Facility_Tier';

	public static STCINetworkMilestoneViolationModule newInstance() {
		return (STCINetworkMilestoneViolationModule) Application.Utilities.newInstance(STCINetworkMilestoneViolationModule.class);
	}

	// Setup which trigger events this module should respond to
	public STCINetworkMilestoneViolationModule() {
		getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableBeforeUpdate().enableAfterUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			//set the network milestone violation fields
			setNetworkMilestoneViolationFields((List<CaseInvestigation__c>) records, null, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'STCINetworkMilestoneViolationModule', STCINetworkMilestoneViolationModule.class.getName(), 'onBeforeInsert', 'STCINetworkMilestoneViolationModule', LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			//set the network milestone violation fields
			setNetworkMilestoneViolationFields((List<CaseInvestigation__c>) records, (Map<Id, CaseInvestigation__c>) existingRecords, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'STCINetworkMilestoneViolationModule', STCINetworkMilestoneViolationModule.class.getName(), 'onBeforeUpdate', 'STCINetworkMilestoneViolationModule', LoggingLevel.ERROR);
		}
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			//calculates and update the violation datetime fields
			updateViolationDatetimeFields((List<CaseInvestigation__c>) records, null, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'STCINetworkMilestoneViolationModule', STCINetworkMilestoneViolationModule.class.getName(), 'onAfterInsert', 'STCINetworkMilestoneViolationModule', LoggingLevel.ERROR);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			//calculates and update the violation datetime fields
			updateViolationDatetimeFields((List<CaseInvestigation__c>) records, (Map<Id, CaseInvestigation__c>) existingRecords, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'STCINetworkMilestoneViolationModule', STCINetworkMilestoneViolationModule.class.getName(), 'onAfterUpdate', 'STCINetworkMilestoneViolationModule', LoggingLevel.ERROR);
		}
	}

	//this method set the network milestone violation date time fields on case investigation records
	private void setNetworkMilestoneViolationFields(List<CaseInvestigation__c> records, Map<Id, CaseInvestigation__c> existingRecords, ApplicationUnitOfWork uow) {
		for(CaseInvestigation__c ci : records) {
			if (!ci.IsClosed__c && (existingRecords == null || (existingRecords != null && ci.IsClosed__c != existingRecords.get(ci.Id).IsClosed__c))) {
				//if case investigation is not in any of the closed statuses, set the milestone start datetime to now
				//reset the violation date time fields
				ci.MilestoneTimeStartDatetime__c = System.now();
				ci.NetworkMilestoneNextViolationDatetime__c = null;
				ci.NetworkMilestoneLastViolationDatetime__c = null;
			} else if(ci.IsClosed__c && (existingRecords == null || (existingRecords != null && ci.IsClosed__c != existingRecords.get(ci.Id).IsClosed__c))) {
				//if case investigation is in any of the closed statuses, reset the milestone start datetime 
				//and next violation datetime
				ci.MilestoneTimeStartDatetime__c = null;
				ci.NetworkMilestoneNextViolationDatetime__c = null;
				ci.NetworkMilestoneCurrentViolatedTier__c = null;
				ci.NetworkMilestonesViolated__c = null;
				ci.NetworkTierEscalationEmail__c = null;
			}
		}
	}

	//this method update the network milestone next violation date time from the MilestoneService
	private void updateViolationDatetimeFields(List<CaseInvestigation__c> records, Map<Id, CaseInvestigation__c> existingRecords, ApplicationUnitOfWork uow) {
		Map<Id, CaseInvestigation__c> ciRecords = new Map<Id, CaseInvestigation__c>();

		for (CaseInvestigation__c ci : records) {
			//get the records on insert where milestone start datetime not null
			//get the records on update when milestone start datetime has changed or current violated tier has changed
			if (ci.MilestoneTimeStartDatetime__c != null && (existingRecords == null || 
					(existingRecords != null && (ci.MilestoneTimeStartDatetime__c != existingRecords.get(ci.Id).MilestoneTimeStartDatetime__c ||
					ci.NetworkMilestoneCurrentViolatedTier__c != existingRecords.get(ci.Id).NetworkMilestoneCurrentViolatedTier__c)))) {
				ciRecords.put(ci.Id, ci);
			}
		}

		if (ciRecords.size() > 0) {
			//call the milestone service to get the calcualted violation date time for the case investigation records
			Map<Id, Datetime> ciViolationDatetimeResultMap = MilestoneService.getInstance().calculateNextViolationDateForCaseInvestigation(ciRecords.keySet(), ENTITLEMENT_RULE_CASE_INVESTIGATION, MILESTONE_TIER_TYPE_FACILITY);

			List<CaseInvestigation__c> recsToUpdate = new List<CaseInvestigation__c>();
			//loop through case investigations to update the fields
			for (CaseInvestigation__c ci : ciRecords.values()) {
				if (ciViolationDatetimeResultMap.containsKey(ci.Id)) {
					//on insert scenario when the current violated tier is blank, update the next violation datetime
					if (ci.NetworkMilestoneCurrentViolatedTier__c == null) {
						recsToUpdate.add(new CaseInvestigation__c(Id = ci.Id, 
							NetworkMilestoneNextViolationDatetime__c = ciViolationDatetimeResultMap.get(ci.Id),
							NetworkMilestoneLastViolationDatetime__c = null));
					} else if (ci.NetworkMilestoneCurrentViolatedTier__c != null && ci.NetworkMilestoneNextViolationDatetime__c != null) {
						//on update scenario when the current violated tier and next violation datetime is not blank, 
						//update the next violation datetime and last violation datetime
						recsToUpdate.add(new CaseInvestigation__c(Id = ci.Id, 
							NetworkMilestoneNextViolationDatetime__c = ciViolationDatetimeResultMap.get(ci.Id),
							NetworkMilestoneLastViolationDatetime__c = ci.NetworkMilestoneNextViolationDatetime__c));
					}
				}
			}

			//update the case investigation records
			if (recsToUpdate.size() > 0) {
				ApplicationDatabase.getInstance().dmlUpdate(recsToUpdate, false);
			}
		}
		
	}
}