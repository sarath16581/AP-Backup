/**
 * @description       : This is a CP Email domain module that is called by the CP Email Trigger
 * @author            : Sreenish Krishnan
 * @domain            : connected customer
 * @last modified on  : 07-22-2022
 * @last modified by  : Sreenish Krishnan
 **/
public inherited sharing class ContactPointEmailDomainModule extends ApplicationDomain.Module {
	public static ContactPointEmailDomainModule newInstance() {
		return (ContactPointEmailDomainModule) Application.Utilities.newInstance(ContactPointEmailDomainModule.class);
	}

	// Setup which trigger events this module should respond to
	public ContactPointEmailDomainModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate().enableAfterDelete();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		List<SObject> recordsToUpdate = new List<SObject>();
		recordsToUpdate = ContactService.getInstance().syncContactPointEmailToContacts((List<ContactPointEmail>) records, null);
		
		uow.registerDirty(recordsToUpdate);
		uow.commitWork();

		createPortalUsers((List<ContactPointEmail>) records, null);
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		List<SObject> recordsToUpdate = new List<SObject>();
		recordsToUpdate = ContactService.getInstance().syncContactPointEmailToContacts((List<ContactPointEmail>) records, null);
		
		uow.registerDirty(recordsToUpdate);
		uow.commitWork();

		createPortalUsers((List<ContactPointEmail>) records, (Map<Id, ContactPointEmail>) existingRecords);
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		List<SObject> recordsToUpdate = new List<SObject>();
		recordsToUpdate = ContactService.getInstance().syncContactPointEmailToContacts(null, (List<ContactPointEmail>) records);
		
		uow.registerDirty(recordsToUpdate);
		uow.commitWork();
	}

	void createPortalUsers(List<ContactPointEmail> records, Map<Id, ContactPointEmail> existingRecords) {
		List<ContactPointEmail> validRecords = new List<ContactPointEmail>();
		Map<Id, Contact> contacts = new Map<Id, Contact>();
		if (existingRecords != null) {
			for (ContactPointEmail cpe : records) {
				if (cpe.IsCredential__c == true && cpe.IsCredential__c != existingRecords.get(cpe.Id).IsCredential__c) {
					validRecords.add(cpe);
					contacts.put(cpe.Contact__c, null);
				}
			}
		} else {
			for (ContactPointEmail cpe : records) {
				if (cpe.IsCredential__c == true) {
					validRecords.add(cpe);
					contacts.put(cpe.Contact__c, null);
				}
			}
		}

		contacts = ContactsSelector.newInstance().selectById(contacts.keySet());
		Map<Id, ContactPointPhone> contactIdVsMobiles = new Map<Id, ContactPointPhone>();
		for (
			ContactPointPhone cpp : ContactPointPhoneSelector.newInstance()
				.selectByContact(
					contacts.keySet(),
					new Set<Object>{
						ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE,
						ContactPointPhoneSelector.Options.FILTER_PREFERRED_TRUE
					}
				)
		) {
			contactIdVsMobiles.put(cpp.Contact__c, cpp);
		}

		Id portalUserProfileId = [SELECT Id FROM Profile WHERE Name = 'DDC Consumer Community User' LIMIT 1].Id;

		Set<Id> contactIdsWithPortalUsers = new Set<Id>();

		for (User u : UsersSelector.newInstance().selectByContactId(contacts.keySet()).values()) {
			contactIdsWithPortalUsers.add(u.ContactId);
		}

		List<User> newUsers = new List<User>();
		List<Contact> contactsToUpdate = new List<Contact>();

		for (ContactPointEmail cpe : validRecords) {
			if (contactIdsWithPortalUsers.contains(cpe.Contact__c) == false) {
				Contact ct = contacts.get(cpe.Contact__c);
				newUsers.add(
					new User(
						FirstName = ct.FirstName,
						LastName = ct.LastName,
						APCN__c = ct.APCN__c,
						ProfileId = portalUserProfileId,
						IsActive = false,
						Email = cpe.emailAddress,
						MobilePhone = contactIdVsMobiles.containsKey(ct.Id) == true ? contactIdVsMobiles.get(ct.Id).TelephoneNumber : '',
						Username = cpe.emailAddress + '.community',
						FederationIdentifier = cpe.emailAddress + '.community',
						OID_ID__c = ct.OID_ID__c,
						LanguageLocaleKey = 'en_US',
						Alias = 'Consumer',
						LocaleSidKey = 'en_AU',
						ContactId = ct.Id,
						EmailEncodingKey = 'UTF-8',
						TimeZoneSidKey = 'Australia/Sydney'
					)
				);

				contactsToUpdate.add(new Contact(Id = ct.Id, CRMCSSOID__c = cpe.emailAddress));
			}
		}
		ApplicationDatabase.getInstance().dmlInsert(newUsers);
		ApplicationDatabase.getInstance().dmlUpdate(contactsToUpdate);
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ContactPointEmailDomainModule.newInstance();
		}
	}
}