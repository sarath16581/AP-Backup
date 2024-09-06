/**
 * @description Module that wraps all of the Event Message legacy code which hasn't been uplifted yet. Legacy code in this module
 *			  were previously placed in EventMessageTrigger.
 * @test EventMessageUtil_Test
 * @author Ranjeewa Silva
 * @date 2024-08-19
 * @changelog
 */
public inherited sharing class EventMessageLegacyAutomationModule extends ApplicationModule {

	public EventMessageLegacyAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		EventMessageUtil.linkToNetworkFacility(records);
		// Added a Method to capture Machine details name on event message insert as a part of MyNetwork Uplift
		EventMessageUtil.populateMachineDetails(records);
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		EventMessageUtil.updateCases(records);
		EventMessageUtil.createSignatureAttachments(records);
		EventMessageUtil.updateArticles(records);
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		EventMessageUtil.populateMachineDetails(records);
	}
}