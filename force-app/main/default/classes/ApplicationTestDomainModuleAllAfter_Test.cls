/***
 * @description
 * This is an ApplicationDomain.Module for use in ApplicationDomain_Test and ApplicationDomainTriggerHandler_Test
 * This needed its own root class since it requires an inner type IConstructableModule
 *
 * @author Nathan Franklin
 * @date 2020-07-27
 * @group Core
 * @domain Core
 * @changelog
 */
@IsTest
public class ApplicationTestDomainModuleAllAfter_Test extends ApplicationDomain.Module {
	public ApplicationTestDomainModuleAllAfter_Test() {
		getTriggerEvents().enableAllAfter();
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

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return new ApplicationTestDomainModuleAllAfter_Test();
		}
	}
}