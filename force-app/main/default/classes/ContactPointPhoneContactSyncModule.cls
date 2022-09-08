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
public inherited sharing class ContactPointPhoneContactSyncModule extends ApplicationDomain.Module {
	public static ContactPointPhoneContactSyncModule newInstance() {
		return (ContactPointPhoneContactSyncModule) Application.Utilities.newInstance(ContactPointPhoneContactSyncModule.class);
	}

	// Setup which trigger events this module should respond to
	public ContactPointPhoneContactSyncModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate().enableAfterInsert().enableAfterUpdate().enableAfterDelete();
	}


	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			List<SObject> recordsToUpdate = (List<SObject>) ContactService.getInstance()
				.syncContactPointPhoneToContacts((List<ContactPointPhone>) records, null, null);
			uow.registerDirty(recordsToUpdate, getFieldstoRegDirtyContact(), ContactPointPhoneContactSyncModule.class.getName());
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'ContactPointPhoneContactSyncModule',
				ContactPointPhoneContactSyncModule.class.getName(),
				'onAfterInsert',
				'ContactPointPhoneContactSyncModule',
				LoggingLevel.ERROR
			);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			List<SObject> recordsToUpdate = ContactService.getInstance()
				.syncContactPointPhoneToContacts((List<ContactPointPhone>) records, null, (Map<Id, ContactPointPhone>) existingRecords);
			uow.registerDirty(recordsToUpdate, getFieldstoRegDirtyContact(), ContactPointPhoneContactSyncModule.class.getName());
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'ContactPointPhoneContactSyncModule',
				ContactPointPhoneContactSyncModule.class.getName(),
				'onAfterUpdate',
				'ContactPointPhoneContactSyncModule',
				LoggingLevel.ERROR
			);
		}
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			List<SObject> recordsToUpdate = ContactService.getInstance()
				.syncContactPointPhoneToContacts(null, (List<ContactPointPhone>) records, null);
			uow.registerDirty(recordsToUpdate, getFieldstoRegDirtyContact(), ContactPointPhoneContactSyncModule.class.getName());
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'ContactPointPhoneContactSyncModule',
				ContactPointPhoneContactSyncModule.class.getName(),
				'onAfterDelete',
				'ContactPointPhoneContactSyncModule',
				LoggingLevel.ERROR
			);
		}
	}

	//which fields to be registered dirty in contact  when updating from CPPhone
	private List<SObjectField> getFieldstoRegDirtyContact() {
		return new List<SObjectField>{ Contact.MobilePhone, Contact.VerifiedMobile__c, Contact.Unique_Mobile__c, Contact.HomePhone };
	}
	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ContactPointPhoneContactSyncModule.newInstance();
		}
	}
}