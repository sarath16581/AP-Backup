/***
 * @description
 * This is an ApplicationDomain.Module for use in ApplicationDomain_Test and ApplicationDomainTriggerHandler_Test
 *
 * @author Nathan Franklin
 * @date 2020-07-27
 * @group Core
 * @domain Core
 * @changelog
 * 2022-04-28 - Nathan Franklin - Remove IConstructable interfaces
 */
@IsTest
public class ApplicationTestDomainModuleNone_Test extends ApplicationDomain.Module {

	public ApplicationTestDomainModuleNone_Test() {
		getTriggerEvents().disableBeforeInsert().disableAfterInsert().disableBeforeUpdate().disableAfterUpdate().disableBeforeDelete().disableAfterDelete();
	}
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		ApplicationTestDomain1_Test.moduleOnBeforeInsertCalled++;
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		ApplicationTestDomain1_Test.moduleOnAfterInsertCalled++;
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		ApplicationTestDomain1_Test.moduleOnBeforeUpdateCalled++;
		ApplicationTestDomain1_Test.moduleBeforeUpdateChangedValues = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Name, Account.NumberOfEmployees});
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		ApplicationTestDomain1_Test.moduleOnAfterUpdateCalled++;
		ApplicationTestDomain1_Test.moduleAfterUpdateChangedValues = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Name, Account.NumberOfEmployees});
	}

	public override void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		ApplicationTestDomain1_Test.moduleOnBeforeDeleteCalled++;
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		ApplicationTestDomain1_Test.moduleOnAfterDeleteCalled++;
	}
}