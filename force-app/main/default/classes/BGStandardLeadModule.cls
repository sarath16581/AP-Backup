/**
 * @description
 * Domain Module to handle BG Standard Lead object functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Pratyush Chalasani
 * @group Domain
 * @domain BGStandardLead
 * @changelog
 * 2020-07-27 - Pratyush Chalasani - Created
 *
 */
public inherited sharing class BGStandardLeadModule extends ApplicationDomain.Module {
	public static BGStandardLeadModule newInstance() {
		return (BGStandardLeadModule) Application.Utilities.newInstance(BGStandardLeadModule.class);
	}

	// Setup which trigger events this module should respond to
	public BGStandardLeadModule() {
		getTriggerEvents().enablebeforeUpdate();
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			preventLinkingOldOpportunities((List<Lead>)records, (Map<Id, Lead>)existingRecords);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'BGStandardLeadModule', BGStandardLeadModule.class.getName(), 'onBeforeUpdate', 'BGStandardLeadModule', LoggingLevel.ERROR);
		}
	}

	/*
	 * Filter for Lead records with Lead_Seeker__c ticket and ConvertedOpportunityId, query linked Opportunity records with CreatedDate,
	 * then add an error message for Leads where the Oppotunity CreatedDate is before the Lead CreatedDate
	 */
	@testVisible
	private void preventLinkingOldOpportunities(List<Lead> records, Map<Id, Lead> existingRecords) {
		// Filter only relevant Lead records
		List<Lead> filtered = new List<Lead>();

		// Linked opportunity record IDs
		Set<Id> opportunityIds = new Set<Id>();

		for (Lead lead: records) {
			Lead old = existingRecords.get(lead.Id);

			// Only process leads where the ConvertedOpportunityId has changed,
			// don't need to do this everytime something is updated.
			if (
				!lead.LeadSeekerConversionOverride__c && lead.Lead_Seeker__c == true &&
				lead.ConvertedOpportunityId != null && old.ConvertedOpportunityId != lead.ConvertedOpportunityId
			) {
				filtered.add(lead);
				opportunityIds.add(lead.ConvertedOpportunityId);
			}
		}

		if (!opportunityIds.isEmpty()) {
			Map<Id, Opportunity> opportunityMap = OpportunitiesSelector.newInstance(opportunityIds.size(), new Set<SObjectField>{ Opportunity.CreatedDate }).selectById(opportunityIds);

			for (Lead lead: filtered) {
				Opportunity opp = opportunityMap.get(lead.ConvertedOpportunityId);

				if (opp != null && opp.CreatedDate < lead.CreatedDate) {
					lead.addError(Label.leadSeakerIntoExistingOpportunity);
				}
			}
		}
	}
}