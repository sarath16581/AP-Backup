public inherited sharing class CaseLegacyAutomationModule extends AutomationModule {
    
	// Setup which triggers this module should respond to
	public CaseLegacyAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableAfterInsert()
							.enableBeforeUpdate().enableAfterUpdate()
							.enableBeforeDelete().enableAfterDelete()
							.enableAfterUndelete();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		CaseTriggerHandler.execute();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		CaseTriggerHandler.execute();
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		CaseTriggerHandler.execute();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		CaseTriggerHandler.execute();
	}

	public override void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		CaseTriggerHandler.execute();
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		CaseTriggerHandler.execute();
	}

	public override void onAfterUndelete(List<SObject> records, ApplicationUnitOfWork uow) {
		CaseTriggerHandler.execute();
	}

}