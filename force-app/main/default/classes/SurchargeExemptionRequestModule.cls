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
		Map<Id, RecordType> recordTypeMap = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{'Surcharge_Exemption_Request'});

		Id surchargeExemptionRT = recordTypeMap.values()[0].Id;

		List<Deal_Support_Request__c> validDSRs = new List<Deal_Support_Request__c>();

		Set<Id> accountIDs = new Set<Id>();

		for (Deal_Support_Request__c dsr: records) {
			Deal_Support_Request__c oldDSR = (existingRecords != null) ? existingRecords.get(dsr.Id) : null;
			
			if ((dsr.RecordTypeId == surchargeExemptionRT) && (oldDSR == null || dsr.Organisation__c != oldDSR.Organisation__c)) {
				accountIDs.add(dsr.Organisation__c);
				validDSRs.add(dsr);
			}
		}

		System.debug('AccountIDs: ' + accountIDs);
		System.debug('validDSRs: ' + validDSRs);

		if (!accountIDs.isEmpty()) {
			Map<Id, String> accountSalesTeamMap = new Map<Id, String>();

			Map<Id, Account> accountMap = AccountsSelector.newInstance(0, new Set<SObjectField>{Account.Sales_Segment__c}).selectById(accountIDs);

			for (Account acc: accountMap.values()) {
				accountSalesTeamMap.put(acc.Id, acc.Sales_Segment__c);
			}

			Set<String> salesTeamNames = new Set<String>();

			salesTeamNames.addAll(accountSalesTeamMap.values());

			System.debug('Sales Teams: ' + salesTeamNames);

			List<Sales_Segment_Reference__c> salesTeams = SalesSegmentReferenceSelector.newInstance().selectByName(salesTeamNames);

			Map<String, Sales_Segment_Reference__c> salesTeamMap = new Map<String, Sales_Segment_Reference__c>();

			for (Sales_Segment_Reference__c team: salesTeams) {
				salesTeamMap.put(team.Sales_Segment__c, team);
			}

			System.debug('Sales Team map: ' + salesTeamMap);

			for (Deal_Support_Request__c dsr: validDSRs) {
				System.debug('Org: ' + dsr.Organisation__c);

				String salesTeamName = accountSalesTeamMap.get(dsr.Organisation__c);

				System.debug('salesTeamName: ' + salesTeamName);

				Sales_Segment_Reference__c team = salesTeamMap.get(salesTeamName);

				if (team != null) {
					dsr.Sales_Director__c = team.SalesDirectorApprover__c;
					dsr.SalesTeamGeneralManager__c = team.GeneralManager__c;
				}
			}
		}
	}
}