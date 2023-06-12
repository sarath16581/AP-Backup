/**
 * @description Module that wraps all of the Case legacy code which hasn't been uplifted yet
 * @author Nathan Franklin
 * @date 2023-06-12
 * @changelog
 */
public inherited sharing class CaseLegacyAutomationModule extends ApplicationModule {
    
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