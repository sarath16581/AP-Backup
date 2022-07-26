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
public class ApplicationTestDomainModuleAllBeforeTest extends ApplicationDomain.Module {
	public ApplicationTestDomainModuleAllBeforeTest() {
		getTriggerEvents().enableAllBefore();
	}
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		ApplicationTestDomain2_Test.moduleOnBeforeInsertCalled++;
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		ApplicationTestDomain2_Test.moduleOnAfterInsertCalled++;
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		ApplicationTestDomain2_Test.moduleOnBeforeUpdateCalled++;
		ApplicationTestDomain2_Test.moduleBeforeUpdateChangedValues = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Name, Account.NumberOfEmployees});
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		ApplicationTestDomain2_Test.moduleOnAfterUpdateCalled++;
		ApplicationTestDomain2_Test.moduleAfterUpdateChangedValues = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Name, Account.NumberOfEmployees});
	}

	public override void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		ApplicationTestDomain2_Test.moduleOnBeforeDeleteCalled++;
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		ApplicationTestDomain2_Test.moduleOnAfterDeleteCalled++;
	}
}