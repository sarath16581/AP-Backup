/**
 * @description 
 * @author Dattaraj Deshmukh
 * @date 2020-06-15
 * @group Tests
 * @tags mocking, apex mocks, tests, data factory, test data
 * @changelog
 * 2022-06-04 - Dattaraj Deshmukh - Created - getDealSupportRequestMilestones method for User story, SM-604
 * 2023-04-14 - Harry Wang - Created - added getOpportunityLineItems method
 * 2023-07-13 - Pratyush Chalasani - Added getSalesSegmentReferences
 * 2023-08-18 - Ranjeewa Silva - Added new method to return Competitors (Competitor__c)
 * 2023-10-26 - Mahesh Parvathaneni - Added method getPriceBookEntries
 */
@IsTest
public with sharing class ApplicationTestDataFactorySales {


	/**
	* @desc: Called from DealSupportRequstMilestoneSelector_Test, DealSpprtReqsMilestonesTrackModule_Test.
	* Creates Deal Support Request milestone record for a DSR
	*/
	public static List<DealSupportRequestMilestone__c> getDealSupportRequestMilestones(integer count, Id dealSupportRequestId, Boolean generateIds) {
		return (List<DealSupportRequestMilestone__c>) ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(DealSupportRequestMilestone__c.SObjectType, new Map<SObjectField, Object>{
				DealSupportRequestMilestone__c.DealSupportRequest__c => dealSupportRequestId
		}, count), generateIds);
	}

	/**
	 * @desc: Called from OpportunityLineItemSelector_Test
	 * Creates OpportunityLineItems
	 */
	public static List<OpportunityLineItem> getOpportunityLineItems(Integer count, Id opportunityId, Id priceBookEntryId, Boolean generateIds) {
		return (List<OpportunityLineItem>) ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(OpportunityLineItem.SObjectType, new Map<SObjectField, Object>{
				OpportunityLineItem.opportunityId => opportunityId,
				OpportunityLineItem.Quantity => 1,
				OpportunityLineItem.UnitPrice => 2,
				OpportunityLineItem.PricebookEntryId => priceBookEntryId
		}, count), generateIds);
	}

	public static List<Sales_Segment_Reference__c> getSalesSegmentReferences(Integer count, Boolean generateIds) {
		return (List<Sales_Segment_Reference__c>) ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Sales_Segment_Reference__c.SObjectType, new Map<SObjectField, Object>(), count), generateIds);
	}

	public static List<Competitor__c> getCompetitors(Integer count, Id opportunityId, Boolean generateIds) {
		return getCompetitors(count, new Set<Id>{opportunityId}, generateIds);
	}

	public static List<Competitor__c> getCompetitors(Integer count, Set<Id> opportunityIds, Boolean generateIds) {
		return (List<Competitor__c>) ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Competitor__c.SObjectType, new Map<SObjectField, Object>{
				Competitor__c.OpportunityId__c => opportunityIds,
				Competitor__c.Competitor_Name__c => 'Other',
				Competitor__c.Competitor_Type__c => 'Competitor'
		}, count), generateIds);
	}

	public static List<PricebookEntry> getPriceBookEntries(Integer count, Id pricebookId, Id productId, Boolean generateIds) {
		return (List<PricebookEntry>) ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PricebookEntry.SObjectType, new Map<SObjectField, Object>{
				PricebookEntry.Pricebook2Id => pricebookId,
				PricebookEntry.Product2Id => productId,
				PricebookEntry.UnitPrice => 10000,
				PricebookEntry.IsActive => true
		}, count), generateIds);
	}
}