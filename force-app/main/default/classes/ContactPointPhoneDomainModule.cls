/**
 * @description
 * Domain Module to handle ContactPointPhone object functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain ContactPointPhone
 * @changelog
 * 2022-05-22 - George Nguyen - Created.
 *
 */
public inherited sharing class ContactPointPhoneDomainModule extends ApplicationDomain.Module {
	public static ContactPointPhoneDomainModule newInstance() {
		return (ContactPointPhoneDomainModule) Application.Utilities.newInstance(ContactPointPhoneDomainModule.class);
	}

	// Setup which trigger events this module should respond to
	public ContactPointPhoneDomainModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate().enableAfterInsert().enableAfterUpdate().enableAfterDelete();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		ContactService.getInstance().applyPhoneNumberFormatting((List<ContactPointPhone>) records, null);
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		ContactService.getInstance()
			.applyPhoneNumberFormatting((List<ContactPointPhone>) records, (Map<Id, ContactPointPhone>) existingRecords);
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		List<SObject> recordsToUpdate = new List<SObject>();
		recordsToUpdate = (List<SObject>) ContactService.getInstance()
			.syncContactPointPhoneToContacts((List<ContactPointPhone>) records, null);

		uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		uow.registerDirty(recordsToUpdate);
		uow.commitWork();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		List<SObject> recordsToUpdate = new List<SObject>();
		recordsToUpdate = ContactService.getInstance().syncContactPointPhoneToContacts((List<ContactPointPhone>) records, null);

		uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		uow.registerDirty(recordsToUpdate);
		uow.commitWork();
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		List<SObject> recordsToUpdate = new List<SObject>();
		recordsToUpdate = ContactService.getInstance().syncContactPointPhoneToContacts(null, (List<ContactPointPhone>) records);

		uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		uow.registerDirty(recordsToUpdate);
		uow.commitWork();
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ContactPointPhoneDomainModule.newInstance();
		}
	}
}