/**
 * @description       : This module handles the network milestone violation related logic
 * @author            : Mahesh Parvathaneni
 * @domain            : Case Investigation
 * @changelog
 * 2022-01-25 - Mahesh Parvathaneni - created
 **/

public inherited sharing class STCINetworkMilestoneViolationModule extends ApplicationDomain.Module {

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
			//update the next violation datetime
			updateViolationDatetime((List<CaseInvestigation__c>) records, null, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'STCINetworkMilestoneViolationModule', STCINetworkMilestoneViolationModule.class.getName(), 'onAfterInsert', 'STCINetworkMilestoneViolationModule', LoggingLevel.ERROR);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			//update the next violation datetime
			updateViolationDatetime((List<CaseInvestigation__c>) records, (Map<Id, CaseInvestigation__c>) existingRecords, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'STCINetworkMilestoneViolationModule', STCINetworkMilestoneViolationModule.class.getName(), 'onAfterUpdate', 'STCINetworkMilestoneViolationModule', LoggingLevel.ERROR);
		}
	}

	//this method set the network milestone violation date time fields on case investigation records
	private void setNetworkMilestoneViolationFields(List<CaseInvestigation__c> records, Map<Id, CaseInvestigation__c> existingRecords, ApplicationUnitOfWork uow) {
		for(CaseInvestigation__c ci : records) {
			if (!ci.IsClosed__c && (existingRecords == null || ci.IsClosed__c != existingRecords.get(ci.Id).IsClosed__c)) {
				ci.MilestoneTimeStartDatetime__c = System.now();
			} else if(ci.IsClosed__c && (existingRecords == null || ci.IsClosed__c != existingRecords.get(ci.Id).IsClosed__c)) {
				ci.MilestoneTimeStartDatetime__c = null;
				ci.NetworkMilestoneNextViolationDatetime__c = null;
			}
		}
	}

	//this method update the network milestone next violation date time from the MilestoneService
	private void updateViolationDatetime(List<CaseInvestigation__c> records, Map<Id, CaseInvestigation__c> existingRecords, ApplicationUnitOfWork uow) {

		
	}
}