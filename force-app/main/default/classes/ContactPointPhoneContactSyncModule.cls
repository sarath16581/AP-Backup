/**
 * @description
 * Domain Module to handle ContactPointPhone object functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain ContactPointPhone
 * @changelog
 * 2022-05-22 - George Nguyen - Created.
 * 2023-08-21 - Boris Bachovski - Temporary bugfix for an issue when removing a contact point phone record (avoid registering dirty field when not required - Contact.Unique_Mobile__c)
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
			List<SObject> recordsToUpdate = (List<SObject>) ContactService.getInstance().syncContactPointPhoneToContacts((List<ContactPointPhone>) records, null, null);
			ContactUtility.generateReversePhoneFields((List<Contact>)recordsToUpdate);

			uowRegisterDirty(recordsToUpdate, uow);
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
			List<SObject> recordsToUpdate = ContactService.getInstance().syncContactPointPhoneToContacts((List<ContactPointPhone>) records, null, (Map<Id, ContactPointPhone>) existingRecords);
			ContactUtility.generateReversePhoneFields((List<Contact>)recordsToUpdate);

			uowRegisterDirty(recordsToUpdate, uow);
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
			List<SObject> recordsToUpdate = ContactService.getInstance().syncContactPointPhoneToContacts(null, (List<ContactPointPhone>) records, null);
			ContactUtility.generateReversePhoneFields((List<Contact>)recordsToUpdate);

			uowRegisterDirty(recordsToUpdate, uow);
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

	// IMPORTANT NOTE: This is a temporary fix and will be addressed as part of a broader refactoring excecise of the customer data sync process.
	// Description:
	// Sometimes the contact sObject in memory does not have Unique Mobile populated (if it doesn't need updating)
	// During update, this field is getting registered dirty as part of the unit of work, which can cause an issue if `null` value is specified:
	// INVALID_TYPE_ON_FIELD_IN_RECORD Unique Mobile: value not of required type
	// In these scenarios, records which don't need updating of Unique Mobile are registered separately without registering this as a dirty field
	private void uowRegisterDirty(List<SObject> recordsToUpdate, ApplicationUnitOfWork uow) {
		List <SObject> recordsWithUniqueMobile = new List <SObject> ();
		List <SObject> recordsWithoutUniqueMobile = new List <SObject> ();

		for (SObject contact : recordsToUpdate) {
			if (contact.get('Unique_Mobile__c') == null) {
				recordsWithoutUniqueMobile.add(contact);
			} else {
				recordsWithUniqueMobile.add(contact);
			}
		}

		List <SObjectField> dirtyFieldsNoUniqueMobile = getFieldstoRegDirtyContact();
		dirtyFieldsNoUniqueMobile.remove(dirtyFieldsNoUniqueMobile.indexOf(Contact.Unique_Mobile__c));

		uow.registerDirty(recordsWithUniqueMobile, getFieldstoRegDirtyContact(), ContactPointPhoneContactSyncModule.class.getName());
		uow.registerDirty(recordsWithoutUniqueMobile, dirtyFieldsNoUniqueMobile, ContactPointPhoneContactSyncModule.class.getName());
	}

	//which fields to be registered dirty in contact  when updating from CPPhone
	private List<SObjectField> getFieldstoRegDirtyContact() {
		return new List<SObjectField>{ 
			Contact.MobilePhone, 
			Contact.VerifiedMobile__c, 
			Contact.Unique_Mobile__c, 
			Contact.HomePhone,
			Contact.ReversePhoneFields__c
		};
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