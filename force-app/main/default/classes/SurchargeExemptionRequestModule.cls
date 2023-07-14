/**
 * @author: Pratyush Chalasani
 * @date: 2023-07-12
 * @domain: DealSupportRequestGenericDomain
 * @test SurchargeExemptionRequestModule_Test
 * @description: Module class to poulate approval users on a Surcharge Exemption request
 * @change log:
 * 2023-07-12 - Pratyush Chalasani - created 
 */
public inherited sharing class SurchargeExemptionRequestModule extends ApplicationDomain.Module {
	private static final String recursionContext = 'SurchargeExemptionRequestModule';
	private static final Set<SObjectField> monitoredFields = new Set<SObjectField>{Deal_Support_Request__c.Organisation__c};

	public static SurchargeExemptionRequestModule newInstance() {
		return (SurchargeExemptionRequestModule)Application.Utilities.newInstance(SurchargeExemptionRequestModule.class);
	}
	
	// Setup which triggers this module should respond to
	public SurchargeExemptionRequestModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}
	
	public override void onBeforeInsert(List<SObject> records,  ApplicationUnitOfWork uow) {
		populateSalesDirectorAndGeneralManager((List<Deal_Support_Request__c>)records, null);
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		populateSalesDirectorAndGeneralManager((List<Deal_Support_Request__c>)records, (Map<Id,Deal_Support_Request__c>)existingRecords);
	}

	private static void populateSalesDirectorAndGeneralManager(List<Deal_Support_Request__c> records, Map<Id,Deal_Support_Request__c> existingRecords) {
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(recursionContext, records, existingRecords, monitoredFields);

		if (changedRecords.isEmpty()) {
			// Skip everything if there are no changed records to process
			return;
		}

		Map<Id, RecordType> recordTypeMap = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{'Surcharge_Exemption_Request'});

		Id surchargeExemptionRT = recordTypeMap.values()[0].Id;

		List<Deal_Support_Request__c> validDSRs = new List<Deal_Support_Request__c>();

		Set<Id> accountIDs = new Set<Id>();

		for (ApplicationRecursion.RecordState changed: changedRecords) {
			Deal_Support_Request__c dsr = (Deal_Support_Request__c)changed.record;

			Deal_Support_Request__c oldDSR = (existingRecords != null) ? existingRecords.get(dsr.Id) : null;
			
			if ((dsr.RecordTypeId == surchargeExemptionRT) && (oldDSR == null || dsr.Organisation__c != oldDSR.Organisation__c)) {
				accountIDs.add(dsr.Organisation__c);
				validDSRs.add(dsr);
			}
		}

		if (!accountIDs.isEmpty()) {
			Map<Id, String> accountSalesTeamMap = new Map<Id, String>();

			Map<Id, Account> accountMap = AccountsSelector.newInstance(0, new Set<SObjectField>{Account.Sales_Segment__c}).selectById(accountIDs);

			for (Account acc: accountMap.values()) {
				accountSalesTeamMap.put(acc.Id, acc.Sales_Segment__c);
			}

			Set<String> salesTeamNames = new Set<String>();

			salesTeamNames.addAll(accountSalesTeamMap.values());

			List<Sales_Segment_Reference__c> salesTeams = SalesSegmentReferenceSelector.newInstance().selectByName(salesTeamNames);

			Map<String, Sales_Segment_Reference__c> salesTeamMap = new Map<String, Sales_Segment_Reference__c>();

			for (Sales_Segment_Reference__c team: salesTeams) {
				salesTeamMap.put(team.Sales_Segment__c, team);
			}

			for (Deal_Support_Request__c dsr: validDSRs) {
				String salesTeamName = accountSalesTeamMap.get(dsr.Organisation__c);

				Sales_Segment_Reference__c team = salesTeamMap.get(salesTeamName);

				if (team != null) {
					dsr.Sales_Director__c = team.SalesDirectorApprover__c;
					dsr.SalesTeamGeneralManager__c = team.GeneralManager__c;
				}
			}
		}
	}
}