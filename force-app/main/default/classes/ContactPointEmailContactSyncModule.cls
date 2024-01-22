/**
 * @description       : This is a CP Email domain module that is called by the CP Email Trigger
 * @author            : Sreenish Krishnan
 * @domain            : connected customer
 * @last modified on  : 08-19-2022
 * @last modified by  : Sreenish Krishnan
 **/
public inherited sharing class ContactPointEmailContactSyncModule extends ApplicationDomain.Module {
	public static ContactPointEmailContactSyncModule newInstance() {
		return (ContactPointEmailContactSyncModule) Application.Utilities.newInstance(ContactPointEmailContactSyncModule.class);
	}

	// Setup which trigger events this module should respond to
	public ContactPointEmailContactSyncModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate().enableAfterDelete();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			List<SObject> recordsToUpdate = ContactService.getInstance()
				.syncContactPointEmailToContacts((List<ContactPointEmail>) records, null, null);
			uow.registerDirty(recordsToUpdate, getFieldstoRegDirtyContact(), ContactPointEmailContactSyncModule.class.getName());
			processPortalUsers((List<ContactPointEmail>) records, null, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'ContactPointEmailContactSyncModule',
				ContactPointEmailContactSyncModule.class.getName(),
				'onAfterInsert',
				'ContactPointEmailContactSyncModule',
				LoggingLevel.ERROR
			);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			List<SObject> recordsToUpdate = ContactService.getInstance()
				.syncContactPointEmailToContacts((List<ContactPointEmail>) records, null, (Map<Id, ContactPointEmail>) existingRecords);
			uow.registerDirty(recordsToUpdate, getFieldstoRegDirtyContact(), ContactPointEmailContactSyncModule.class.getName());

			processPortalUsers((List<ContactPointEmail>) records, (Map<Id, ContactPointEmail>) existingRecords, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'ContactPointEmailContactSyncModule',
				ContactPointEmailContactSyncModule.class.getName(),
				'onAfterUpdate',
				'ContactPointEmailContactSyncModule',
				LoggingLevel.ERROR
			);
		}
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			List<SObject> recordsToUpdate = ContactService.getInstance()
				.syncContactPointEmailToContacts(null, (List<ContactPointEmail>) records, null);
			uow.registerDirty(recordsToUpdate, getFieldstoRegDirtyContact(), ContactPointEmailContactSyncModule.class.getName());
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'ContactPointEmailContactSyncModule',
				ContactPointEmailContactSyncModule.class.getName(),
				'onAfterDelete',
				'ContactPointEmailContactSyncModule',
				LoggingLevel.ERROR
			);
		}
	}

	void processPortalUsers(List<ContactPointEmail> records, Map<Id, ContactPointEmail> existingRecords, ApplicationUnitOfWork uow) {
		List<ContactPointEmail> validRecords = new List<ContactPointEmail>();
		Map<Id, Contact> contacts = new Map<Id, Contact>();
		if (existingRecords != null) {
			for (ContactPointEmail cpe : records) {
				if (
					cpe.IsCredential__c == true &&
					(cpe.IsCredential__c != existingRecords.get(cpe.Id).IsCredential__c ||
					cpe.emailAddress != existingRecords.get(cpe.Id).emailAddress)
				) {
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

		if (contacts.isEmpty() == false) {
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

			Id portalUserProfileId = Application.Cache.profileIds.get(ChasConstants.CONSUMER_COMMUNITY_PROFILE_NAME);

			Map<Id, User> contactIdsWithPortalUsers = new Map<Id, User>();

			for (User u : UsersSelector.newInstance().selectByContactId(contacts.keySet()).values()) {
				contactIdsWithPortalUsers.put(u.ContactId, u);
			}

			List<User> newUsers = new List<User>();
			List<String> userIdsAndContactPointEmailIds = new List<String>();
			List<Contact> contactsToUpdate = new List<Contact>();
			String sandboxSuffix = Application.Cache.organizationInfo.isSandbox == true
				? '.' + Application.Cache.organizationInfo.sandboxName
				: '';

			for (ContactPointEmail cpe : validRecords) {
				User portalUser = contactIdsWithPortalUsers.get(cpe.Contact__c);
				if (portalUser != null) {
					if (portalUser.Email != cpe.emailAddress) {
						// capture both user id and cpe Id to future update.
						userIdsAndContactPointEmailIds.add(portalUser.Id + '-' + cpe.Id);
					}
				} else {
					Contact ct = contacts.get(cpe.Contact__c);
					newUsers.add(
						new User(
							FirstName = ct.FirstName,
							LastName = ct.LastName,
							APCN__c = ct.APCN__c,
							ProfileId = portalUserProfileId,
							IsActive = false,
							Email = cpe.emailAddress,
							MobilePhone = contactIdVsMobiles.containsKey(ct.Id) == true
								? contactIdVsMobiles.get(ct.Id).TelephoneNumber
								: '',
							Username = cpe.emailAddress + '.community' + sandboxSuffix,
							FederationIdentifier = cpe.emailAddress + '.community' + sandboxSuffix,
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

			uow.registerUpsert(newUsers);
			uow.registerUpsert(contactsToUpdate);

			// enqueue the worker to process the user records that will need to be updated
			// NOTE: this has to be done asynchronously because user object is a setup object which will cause mix DML
			if (userIdsAndContactPointEmailIds.isEmpty() == false) {
				uow.registerAsyncWork(
					new ApplicationUnitOfWork.AsyncStagingWorker(
						AsyncUpdateUserLoginDetailsWorker.class,
						new Map<String, Object>{ 'userIdsAndContactPointEmailIds' => userIdsAndContactPointEmailIds }
					)
				);
			}
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ContactPointEmailContactSyncModule.newInstance();
		}
	}

	//which fields to be registered dirty in contact when updating from CPEmail
	private List<SObjectField> getFieldstoRegDirtyContact() {
		return new List<SObjectField>{ Contact.Email, Contact.VerifiedEmail__c };
	}

	public without sharing class AsyncUpdateUserLoginDetailsWorker extends ApplicationUnitOfWork.AsyncWorker {
		@TestVisible
		Map<Id, Id> userIdsVsContactPointEmailIds;
		@TestVisible
		Set<Id> contactPointEmailIds;

		/*
		 * This method splits the ids from the params passed into the async worker
		 * then queries the corresponding ContactPointEmails and Users and updates the Email, Username and Fed Id of the user record
		 * sets the sandbox suffix to these usernames to make them unique to this sandbox, and to avoid duplicate usernames from prod or other orgs
		 */
		public override void execute(ApplicationUnitOfWork uow) {
			if (userIdsVsContactPointEmailIds != null && userIdsVsContactPointEmailIds.isEmpty() == false) {
				String sandboxSuffix = Application.Cache.organizationInfo.isSandbox == true
					? '.' + Application.Cache.organizationInfo.sandboxName
					: '';

				if (contactPointEmailIds != null && contactPointEmailIds.isEmpty() == false) {
					Map<Id, ContactPointEmail> cpes = new Map<Id, ContactPointEmail>(
						ContactPointEmailSelector.newInstance().selectById(contactPointEmailIds)
					);
					List<User> usersToUpdate = new List<User>();
					for (User portalUser : UsersSelector.newInstance().selectById(userIdsVsContactPointEmailIds.keySet()).values()) {
						ContactPointEmail cpe = cpes.get(userIdsVsContactPointEmailIds.get(portalUser.id));
						if (cpe.IsCredential__c == true) {
							// just in case it has changed since it was registered as async
							portalUser.Email = cpe.emailAddress;
							portalUser.Username = cpe.emailAddress + '.community' + sandboxSuffix;
							portalUser.FederationIdentifier = cpe.emailAddress + '.community' + sandboxSuffix;
							usersToUpdate.add(portalUser);
						}
					}

					uow.registerDirty(
						usersToUpdate,
						new List<SObjectField>{ User.Email, User.Username, User.FederationIdentifier },
						false, // do not throw exception on error as it is async. It will be logged
						ContactPointEmailContactSyncModule.class.getName() +
						'.' +
						AsyncUpdateUserLoginDetailsWorker.class.getName()
					);
				}
			}
		}

		public override Type getClassType() {
			return AsyncUpdateUserLoginDetailsWorker.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return User.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			AsyncUpdateUserLoginDetailsWorkerParameters params = (AsyncUpdateUserLoginDetailsWorkerParameters) JSON.deserialize(
				serialisedParams,
				AsyncUpdateUserLoginDetailsWorkerParameters.class
			);
			userIdsVsContactPointEmailIds = new Map<Id, Id>();
			contactPointEmailIds = new Set<Id>();
			for (String input : params.userIdsAndContactPointEmailIds) {
				List<String> ids = input.split('-');
				userIdsVsContactPointEmailIds.put(ids[0], ids[1]);
				contactPointEmailIds.add(ids[1]);
			}
		}
	}

	public class AsyncUpdateUserLoginDetailsWorkerParameters {
		@TestVisible
		List<String> userIdsAndContactPointEmailIds;
	}
}