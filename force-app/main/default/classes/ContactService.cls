/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description A very simple selector class that provides functionalities related to the Contact object
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
public inherited sharing class ContactService {
	static ContactService instance;
	enum CPE_FLAGS {
		NO_RECORDS,
		VERIFIED,
		VERIFIED_AND_PREFFERED,
		UNVERIFIED
	}
	enum CPP_FLAGS {
		NONE,
		NO_RECORDS,
		MOBILE_VERIFIED,
		MOBILE_VERIFIED_AND_PREFFERED,
		MOBILE_UNVERIFIED
	}
	enum CPP_PHONE_TYPE {
		MOBILE,
		HOME
	}
	public static ContactService getInstance() {
		if (instance == null) {
			instance = (ContactService) Application.Utilities.newInstance(ContactService.class);
		}
		return instance;
	}

	/*
	 * This method is used by the ContactPointPhone trigger.
	 * It will check if the TelephoneNumber is not blank (for Insert) or it has changed (for Update)
	 * If the Parent (master-detail) is Not a Person Account it will call the Service class to format the number
	 */
	public void applyPhoneNumberFormatting(List<ContactPointPhone> records, Map<Id, ContactPointPhone> existingRecords) {
		StringFormattingService service = StringFormattingService.getInstance();
		Map<Id, Account> parents = new Map<Id, Account>();

		if (existingRecords != null && existingRecords.isEmpty() == false) {
			for (ContactPointPhone ctp : records) {
				if (ctp.TelephoneNumber != existingRecords.get(ctp.Id).TelephoneNumber) {
					parents.put(ctp.ParentId, null);
				}
			}
		} else {
			for (ContactPointPhone ctp : records) {
				if (String.isBlank(ctp.TelephoneNumber) == false) {
					parents.put(ctp.ParentId, null);
				}
			}
		}

		if (parents.isEmpty() == false) {
			parents = AccountsSelector.newInstance().selectById(new Set<Id>(parents.keySet()));
			for (ContactPointPhone ctp : records) {
				if (parents.get(ctp.parentId).IsPersonAccount == false) {
					ctp.TelephoneNumber = service.formatPhoneNumber(ctp.TelephoneNumber);
				}
			}
		}
	}

	/*
	 * This method is used by the Contact trigger.
	 * It will check if the phone fields are not blank (for Insert) or they have changed (for Update)
	 */
	public void applyPhoneNumberFormatting(List<Contact> records, Map<Id, Contact> existingRecords) {
		StringFormattingService service = StringFormattingService.getInstance();

		if (existingRecords != null && existingRecords.isEmpty() == false) {
			for (Contact ct : records) {
				if (ct.Phone != existingRecords.get(ct.Id).Phone) {
					ct.Phone = service.formatPhoneNumber(ct.Phone);
				}
				if (ct.MobilePhone != existingRecords.get(ct.Id).MobilePhone) {
					ct.MobilePhone = service.formatPhoneNumber(ct.MobilePhone);
				}
				if (ct.VerifiedMobile__c != existingRecords.get(ct.Id).VerifiedMobile__c) {
					ct.VerifiedMobile__c = service.formatPhoneNumber(ct.VerifiedMobile__c);
				}
				if (ct.HomePhone != existingRecords.get(ct.Id).HomePhone) {
					ct.HomePhone = service.formatPhoneNumber(ct.HomePhone);
				}
			}
		} else {
			for (Contact ct : records) {
				if (String.isBlank(ct.Phone) == false) {
					ct.Phone = service.formatPhoneNumber(ct.Phone);
				}
				if (String.isBlank(ct.MobilePhone) == false) {
					ct.MobilePhone = service.formatPhoneNumber(ct.MobilePhone);
				}
				if (String.isBlank(ct.VerifiedMobile__c) == false) {
					ct.VerifiedMobile__c = service.formatPhoneNumber(ct.VerifiedMobile__c);
				}
				if (String.isBlank(ct.HomePhone) == false) {
					ct.HomePhone = service.formatPhoneNumber(ct.HomePhone);
				}
			}
		}
	}

	//Method to sync CPEmail records with contact. This is called from the CP email trigger.
	public List<Contact> syncContactPointEmailToContacts(
		List<ContactPointEmail> records,
		List<ContactPointEmail> existing,
		Map<Id, ContactPointEmail> existingMap
	) {
		Boolean handleDelete = false;
		Boolean handleInsert = false;
		Map<Id, Contact> cpEmailsDeleteMap = new Map<Id, Contact>();
		Map<Id, Contact> cpEmailsUpsertMap = new Map<Id, Contact>();
		List<Contact> contactList = new List<Contact>();
		List<ContactPointEmail> recordsInScope = new List<ContactPointEmail>();

		//if its new records, then its not delete. if its existing records, then handle delete
		handleDelete = (records != null ? false : (existing != null ? true : false));
		handleInsert = (existing != null ? false : (existingMap != null) ? false : true);

		if (handleInsert) {
			recordsInScope = records;
		} else if (handleDelete) {
			recordsInScope = existing;
		} else {
			if (records != null && existingMap != null) {
				recordsInScope = getChangedRecordsCPEmails(records, existingMap);
			}
		}
		//get all the contacts that are associated to the contact point email
		if (!recordsInScope.isEmpty()) {
			Set<Id> contactIds = getContactIds(recordsInScope);
			//its for delete scenario
			if (handleDelete) {
				cpEmailsDeleteMap = handleDeletesForCPESyncWithContact(contactIds);
			} else {
				cpEmailsUpsertMap = handleUpsertsForCPESyncWithContact(contactIds);
			}

			contactList = dedupeContacts(cpEmailsUpsertMap.values());

			//if contactsmap is empty and contactids are not empty, then create a contact list with contact ids and contact records and add to dmlupdate
			if (handleDelete) {
				contactList.addAll(dedupeContacts(cpEmailsDeleteMap.values()));
			}
		}
		return contactList;
	}

	//Method to sync CPPhone records with contact. This is called from the CP Phones Trigger
	public List<Contact> syncContactPointPhoneToContacts(
		List<ContactPointPhone> records,
		List<ContactPointPhone> existing,
		Map<Id, ContactPointPhone> existingMap
	) {
		Boolean handleDelete = false;
		Boolean handleInsert = false;
		Map<Id, Contact> cpPhonesDeleteMap = new Map<Id, Contact>();
		Map<Id, Contact> cpPhonesUpsertMap = new Map<Id, Contact>();
		List<Contact> contactList = new List<Contact>();
		List<ContactPointPhone> recordsInScope = new List<ContactPointPhone>();
		handleDelete = (records != null ? false : (existing != null ? true : false));
		handleInsert = (existing != null ? false : (existingMap != null) ? false : true);
		if (handleInsert) {
			recordsInScope = records;
		} else if (handleDelete) {
			recordsInScope = existing;
		} else {
			if (records != null && existingMap != null) {
				recordsInScope = getChangedRecordsCPPhones(records, existingMap);
			}
		}

		if (!recordsInScope.isEmpty()) {
			//get all the contacts that are associated to the contact point email
			Set<Id> contactIds = getContactIds(recordsInScope);
			//its for delete scenario
			if (handleDelete) {
				cpPhonesDeleteMap = handleDeletesForCPPSyncWithContact(contactIds);
			} else {
				cpPhonesUpsertMap = handleUpsertsForCPPSyncWithContact(contactIds);
			}

			contactList = dedupeContacts(cpPhonesUpsertMap.values());
			//if contactsmap is empty and contactids are not empty, then create a contact list with contact ids and contact records and add to dmlupdate
			if (handleDelete) {
				contactList.addAll(dedupeContacts(cpPhonesDeleteMap.values()));
			}
		}
		return contactList;
	}

	//Helper method to syncContactPointEmailToContacts to handle upserts for CPE.
	private Map<Id, Contact> handleUpsertsForCPESyncWithContact(Set<Id> contactIds) {
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
		ContactPointEmailSelector selector = ContactPointEmailSelector.newInstance();

		//query all the contact point emails associated to the contacts's and do the logic
		List<ContactPointEmail> cpEmails = new List<ContactPointEmail>();
		if (!contactIds.isEmpty()) {
			cpEmails = selector.selectByContact(contactIds, new Set<Object>());
		}
		for (ContactPointEmail cpe : cpEmails) {
			//if it is verified, then check if there are any records in the map for contact in scope
			//		if there are records then check if the current record is preffered
			//			if the current record is preffered, then put that in the map against the contact in scope
			//			if the current record is not prefferd then get the existing record and check if it is verified
			//				if it is verified, then do nothing assuming that it is a preffered one
			//				if it is not verified, then then put that in the map against the contact in scope
			//		if there are no records then add the current record in the map against the contact in scope
			//if it not verified, then check if there are any records in the map against the contact in scope
			//		if there are records then do nothing
			//		if there are no records, then insert a new entry with unverified flag in the map against the contact in scope

			contactMap = prepareContactMap(cpe, contactMap);
		}
		return contactMap;
	}

	//Helper method to handleDeletesForCPESyncWithContact to handle deletes for CPE
	private Map<Id, Contact> handleDeletesForCPESyncWithContact(Set<Id> contactIds) {
		Map<Id, Contact> contactExistingMap = new Map<Id, Contact>();
		Map<Id, List<ContactPointEmail>> cpEmailsExistingMap = new Map<Id, List<ContactPointEmail>>();
		Map<Id, Contact> contactMap = new Map<Id, Contact>();

		ContactsSelector selectorContacts = ContactsSelector.newInstance();
		ContactPointEmailSelector selectorEmails = ContactPointEmailSelector.newInstance();
		//query all contacts with the contactids
		if (!contactIds.isEmpty()) {
			contactExistingMap = selectorContacts.selectById(contactIds);

			//query CPEmails
			List<ContactPointEmail> cpEmails = selectorEmails.selectByContact(contactIds, new Set<Object>());
			if (!cpEmails.isEmpty()) {
				cpEmailsExistingMap = getContactMapFromCPEmails(cpEmails);
			}

			if (!contactExistingMap.isEmpty()) {
				for (Id cId : contactExistingMap.keySet()) {
					if (!cpEmailsExistingMap.containsKey(cId)) {
						contactMap.put(cId, mapContactForNoCPERecords(cId, CPE_FLAGS.NO_RECORDS));
					} else {
						for (ContactPointEmail cpe : cpEmailsExistingMap.get(cId)) {
							contactMap = prepareContactMap(cpe, contactMap);
						}
					}
				}
			}
		}
		return contactMap;
	}

	//Helper method to handleDeletesForCPPSyncWithContact to handle deletes for CPP
	private Map<Id, Contact> handleDeletesForCPPSyncWithContact(Set<Id> contactIds) {
		Map<Id, Contact> contactExistingMap = new Map<Id, Contact>();
		Map<Id, List<ContactPointPhone>> cpPhonesExistingMap = new Map<Id, List<ContactPointPhone>>();
		Map<Id, Contact> contactMap = new Map<Id, Contact>();

		ContactsSelector selectorContacts = ContactsSelector.newInstance();
		ContactPointPhoneSelector selectorPhones = ContactPointPhoneSelector.newInstance();
		//query all contacts with the contactids
		if (!contactIds.isEmpty()) {
			contactExistingMap = selectorContacts.selectById(contactIds);
			//query CPPhones
			List<ContactPointPhone> cpPhones = selectorPhones.selectByContact(contactIds, new Set<Object>());

			if (!cpPhones.isEmpty()) {
				cpPhonesExistingMap = getContactMapFromCPPhones(cpPhones);
			}

			if (!contactExistingMap.isEmpty()) {
				for (Id cId : contactExistingMap.keySet()) {
					if (!cpPhonesExistingMap.containsKey(cId)) {
						contactMap.put(cId, mapContactForNoCPPRecords(cId, CPP_FLAGS.NO_RECORDS));
					} else {
						for (ContactPointPhone cpp : cpPhonesExistingMap.get(cId)) {
							contactMap = prepareContactMap(cpp, contactMap);
						}
					}
				}
			}
		}
		return contactMap;
	}

	//Helper method to syncContactPointPhoneToContacts to handle upserts for CPP
	private Map<Id, Contact> handleUpsertsForCPPSyncWithContact(Set<Id> contactIds) {
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
		ContactPointPhoneSelector selector = ContactPointPhoneSelector.newInstance();
		List<ContactPointPhone> cpPhones = new List<ContactPointPhone>();
		if (!contactIds.isEmpty()) {
			cpPhones = selector.selectByContact(contactIds, new Set<Object>());
		}

		for (ContactPointPhone cpp : cpPhones) {
			//if the phone type is mobile
			//		if it is verified, then check if there are any records in the map for contact in scope
			//				if there are records, then check if the current record has preffered mobile as true
			//					if the current record is preferred and has preffered mobile as true as well, then put that in the map against the contact in scope
			//					if the current record is not prefferd, then get the existing record from the map and check if it is verified
			//						if it is verified, then do nothing assuming that the existing record in the map is already a prefferd one
			//						if it is not verified, then put that in the map against the contact in current scope
			//				if there are no records, then add the current record in the map against the contact in scope
			//		if it not verified, then check if there are any records in the map against the contact in scope
			//			if there are records, then do nothing
			//			if there are no records, then insert a new entry with unverified flag in the map agsinst the contact in scope
			//if the phone type is land line
			//		if there are records in the map for contact in scope
			//			if there are then, get the existing record from the map and check if the

			contactMap = prepareContactMap(cpp, contactMap);
		}

		return contactMap;
	}

	//Create the map for CPEmail
	private Map<Id, Contact> prepareContactMap(ContactPointEmail cpe, Map<Id, Contact> contactMap) {
		Boolean hasEntry = contactMap.containsKey(cpe.contact__c);
		if (cpe.Verified__c) {
			if (hasEntry) {
				if (cpe.Preferred__c) {
					contactMap.put(cpe.contact__c, mapContactFromContactPointEmail(cpe, CPE_FLAGS.VERIFIED_AND_PREFFERED));
				} else {
					if (String.isEmpty(contactMap.get(cpe.contact__c).VerifiedEmail__c)) {
						contactMap.put(cpe.contact__c, mapContactFromContactPointEmail(cpe, CPE_FLAGS.VERIFIED));
					}
				}
			} else {
				contactMap.put(cpe.contact__c, mapContactFromContactPointEmail(cpe, CPE_FLAGS.VERIFIED));
			}
		} else {
			if (!hasEntry) {
				contactMap.put(cpe.contact__c, mapContactFromContactPointEmail(cpe, CPE_FLAGS.UNVERIFIED));
			}
		}
		return contactMap;
	}

	//Create the map for CPPhone
	private Map<Id, Contact> prepareContactMap(ContactPointPhone cpp, Map<Id, Contact> contactMap) {
		if ((cpp.PhoneType).equalsIgnoreCase(CPP_PHONE_TYPE.MOBILE.name())) {
			contactMap = getContactMapForMobileType(cpp, contactMap);
		} else if ((cpp.PhoneType).equalsIgnoreCase(CPP_PHONE_TYPE.HOME.name())) {
			contactMap = getContactMapForHomeType(cpp, contactMap);
		}

		return contactMap;
	}

	//This method creates a map of existing contact point emails
	private Map<Id, List<ContactPointEmail>> getContactMapFromCPEmails(List<ContactPointEmail> existing) {
		Map<Id, List<ContactPointEmail>> contactIdVsCPEmails = new Map<Id, List<ContactPointEmail>>();
		if (!existing.isEmpty()) {
			for (ContactPointEmail cpe : existing) {
				if (contactIdVsCPEmails.containsKey(cpe.contact__c)) {
					contactIdVsCPEmails.get(cpe.contact__c).add(cpe);
				} else {
					List<ContactPointEmail> cpEmails = new List<ContactPointEmail>();
					cpEmails.add(cpe);
					contactIdVsCPEmails.put(cpe.contact__c, cpEmails);
				}
			}
		}
		return contactIdVsCPEmails;
	}

	//This method creates a map of existing contact point emails
	private Map<Id, List<ContactPointPhone>> getContactMapFromCPPhones(List<ContactPointPhone> existing) {
		Map<Id, List<ContactPointPhone>> contactIdVsCPPhones = new Map<Id, List<ContactPointPhone>>();
		if (!existing.isEmpty()) {
			for (ContactPointPhone cpe : existing) {
				if (contactIdVsCPPhones.containsKey(cpe.contact__c)) {
					contactIdVsCPPhones.get(cpe.contact__c).add(cpe);
				} else {
					List<ContactPointPhone> cpPhones = new List<ContactPointPhone>();
					cpPhones.add(cpe);
					contactIdVsCPPhones.put(cpe.contact__c, cpPhones);
				}
			}
		}
		return contactIdVsCPPhones;
	}

	//Logic for dealing with verified flag and prefferd flag in CPPhone fro Mobile
	private Map<Id, Contact> getContactMapForMobileType(ContactPointPhone cpp, Map<Id, Contact> contactMap) {
		Boolean hasEntryForMobile = getEntry(cpp, contactMap, CPP_PHONE_TYPE.MOBILE);

		if (cpp.Verified__c) {
			if (hasEntryForMobile) {
				if (cpp.Preferred__c) {
					contactMap.put(
						cpp.contact__c,
						mapContactFromContactPointPhone(cpp, contactMap, CPP_FLAGS.MOBILE_VERIFIED_AND_PREFFERED, CPP_PHONE_TYPE.MOBILE)
					);
				} else {
					if (String.isEmpty(contactMap.get(cpp.contact__c).VerifiedMobile__c)) {
						contactMap.put(
							cpp.contact__c,
							mapContactFromContactPointPhone(cpp, contactMap, CPP_FLAGS.MOBILE_VERIFIED, CPP_PHONE_TYPE.MOBILE)
						);
					}
				}
			} else {
				contactMap.put(
					cpp.contact__c,
					mapContactFromContactPointPhone(cpp, contactMap, CPP_FLAGS.MOBILE_VERIFIED, CPP_PHONE_TYPE.MOBILE)
				);
			}
		} else {
			if (!hasEntryForMobile) {
				contactMap.put(
					cpp.contact__c,
					mapContactFromContactPointPhone(cpp, contactMap, CPP_FLAGS.MOBILE_UNVERIFIED, CPP_PHONE_TYPE.MOBILE)
				);
			}
		}

		return contactMap;
	}

	//Logic to deal with Home Type Phone
	private Map<Id, Contact> getContactMapForHomeType(ContactPointPhone cpp, Map<Id, Contact> contactMap) {
		Boolean hasEntryForHome = getEntry(cpp, contactMap, CPP_PHONE_TYPE.HOME);
		if (!hasEntryForHome) {
			contactMap.put(cpp.contact__c, mapContactFromContactPointPhone(cpp, contactMap, CPP_FLAGS.NONE, CPP_PHONE_TYPE.HOME));
		}

		return contactMap;
	}

	//Return the entry in contact map relevant to the phone type
	private Boolean getEntry(ContactPointPhone cpp, Map<Id, Contact> contactMap, ContactService.CPP_PHONE_TYPE phoneType) {
		if (contactMap.containsKey(cpp.contact__c)) {
			if (phoneType == CPP_PHONE_TYPE.MOBILE) {
				if (!String.isEmpty(contactMap.get(cpp.contact__c).MobilePhone)) {
					return true;
				}
			} else if (phoneType == CPP_PHONE_TYPE.HOME) {
				if (!String.isEmpty(contactMap.get(cpp.contact__c).HomePhone)) {
					return true;
				}
			}
		}
		return false;
	}

	//This method takes contacts and returns deduped list of contacts
	private List<Contact> dedupeContacts(List<Contact> contacts) {
		Set<Contact> temp = new Set<Contact>();
		List<Contact> contactList = new List<Contact>();
		if (!contacts.isEmpty()) {
			temp.addAll(contacts);
			contactList.addAll(temp);
		}
		return contactList;
	}

	//This method is to map when there are no contact point emails for contact
	private Contact mapContactForNoCPERecords(Id contactId, ContactService.CPE_FLAGS flag) {
		Contact ct = new Contact(Id = contactId);
		if (flag == CPE_FLAGS.NO_RECORDS) {
			ct.Email = null;
			ct.VerifiedEmail__c = null;
		}
		return ct;
	}
	//This method is to map when there are no contact point emails for contact
	private Contact mapContactForNoCPPRecords(Id contactId, ContactService.CPP_FLAGS flag) {
		Contact ct = new Contact(Id = contactId);
		if (flag == CPP_FLAGS.NO_RECORDS) {
			ct.MobilePhone = null;
			ct.VerifiedMobile__c = null;
			ct.HomePhone = null;
			ct.Unique_Mobile__c = false;
		}
		return ct;
	}

	//this method is to map when there are contact point emails for contact that need to be upserted
	private Contact mapContactFromContactPointEmail(ContactPointEmail cpe, ContactService.CPE_FLAGS flag) {
		Contact ct = new Contact(Id = cpe.contact__c);
		ct.Email = cpe.EmailAddress;
		ct.VerifiedEmail__c = cpe.EmailAddress;
		if ((flag == CPE_FLAGS.VERIFIED) || (flag == CPE_FLAGS.VERIFIED_AND_PREFFERED)) {
			return ct;
		} else if (flag == CPE_FLAGS.UNVERIFIED) {
			//override VerifiedEmail__c
			ct.Email = cpe.EmailAddress;
			ct.VerifiedEmail__c = null;
		}

		return ct;
	}
	//this method is to map when there are contact point phones for contact that need to be upserted
	private Contact mapContactFromContactPointPhone(
		ContactPointPhone cpp,
		MAp<Id, Contact> contactMap,
		ContactService.CPP_FLAGS flag,
		ContactService.CPP_PHONE_TYPE phoneType
	) {
		Contact ct = getContactFromContactMap(cpp, contactMap);
		if (phoneType == CPP_PHONE_TYPE.MOBILE) {
			ct.MobilePhone = cpp.TelephoneNumber;
			ct.VerifiedMobile__c = cpp.TelephoneNumber;
			ct.Unique_Mobile__c = cpp.UniqueMobile__c;

			if ((flag == CPP_FLAGS.MOBILE_VERIFIED) || (flag == CPP_FLAGS.MOBILE_VERIFIED_AND_PREFFERED)) {
				return ct;
			} else if (flag == CPP_FLAGS.MOBILE_UNVERIFIED) {
				//override VerifiedMobile__c and ct.Unique_Mobile__c
				ct.MobilePhone = cpp.TelephoneNumber;
				ct.VerifiedMobile__c = null;
				ct.Unique_Mobile__c = false;
			}
		} else if (phoneType == CPP_PHONE_TYPE.HOME) {
			ct.HomePhone = cpp.TelephoneNumber;
		}

		return ct;
	}

	//this method is called to get contact from the contact map
	private Contact getContactFromContactMap(ContactPointPhone cpp, Map<Id, Contact> contactMap) {
		Contact ct;
		if (contactMap.containsKey(cpp.contact__c)) {
			ct = contactMap.get(cpp.contact__c);
		} else {
			ct = new Contact(Id = cpp.contact__c);
		}
		return ct;
	}

	//this method is for getting contact ids from contact point email records
	private Set<Id> getContactIds(List<ContactPointEmail> records) {
		Set<Id> ids = new Set<Id>();
		for (ContactPointEmail cpe : records) {
			ids.add(cpe.contact__c);
		}

		return ids;
	}
	//this method is for getting contact ids from contact point email records
	private Set<Id> getContactIds(List<ContactPointPhone> records) {
		Set<Id> ids = new Set<Id>();
		for (ContactPointPhone cpp : records) {
			ids.add(cpp.contact__c);
		}

		return ids;
	}

	//getter for runnuing integration user
	public static Id integrationUserId {
		get {
			if (integrationUserId == null) {
				integrationUserId = SystemSettings__c.getInstance().PrimaryIntegrationUser__c;
			}
			return integrationUserId;
		}
		private set;
	}

	//this method checks if the current running user is an integration user
	public Boolean checkCurrentUserIsIntegrationUser(String currentUserId) {
		if (Test.isRunningTest()) {
			return true;
		}
		if (integrationUserId == currentUserId) {
			return true;
		}
		return false;
	}

	//this method checks for changes on specific fields for Connected Customer
	private List<ContactPointEmail> getChangedRecordsCPEmails(List<ContactPointEmail> newRecords, Map<Id, ContactPointEmail> oldRecords) {
		List<ContactPointEmail> changedRecords = new List<ContactPointEmail>();
		for (ContactPointEmail cpeNew : newRecords) {
			ContactPointEmail cpeOld = oldRecords.get(cpeNew.Id);
			if (
				(cpeNew.IsPrimary != cpeOld.isPrimary) ||
				(cpeNew.EmailAddress != cpeOld.EmailAddress) ||
				(cpeNew.ParentId != cpeOld.ParentId) ||
				(cpeNew.Contact__c != cpeOld.Contact__c) ||
				(cpeNew.Preferred__c != cpeOld.Preferred__c) ||
				(cpeNew.Verified__c != cpeOld.Verified__c) ||
				(cpeNew.IsCredential__c != cpeOld.IsCredential__c) ||
				(cpeNew.AuthenticationEmail__c != cpeOld.AuthenticationEmail__c)
			) {
				changedRecords.add(cpeNew);
			}
		}
		return changedRecords;
	}

	//this method checks for changes on specific fields for Connected Customer
	private List<ContactPointPhone> getChangedRecordsCPPhones(List<ContactPointPhone> newRecords, Map<Id, ContactPointPhone> oldRecords) {
		List<ContactPointPhone> changedRecords = new List<ContactPointPhone>();
		for (ContactPointPhone cppNew : newRecords) {
			ContactPointPhone cppOld = oldRecords.get(cppNew.Id);
			if (
				(cppNew.ParentId != cppOld.ParentId) ||
				(cppNew.Contact__c != cppOld.Contact__c) ||
				(cppNew.TelephoneNumber != cppOld.TelephoneNumber) ||
				(cppNew.PhoneType != cppOld.PhoneType) ||
				(cppNew.Verified__c != cppOld.Verified__c) ||
				(cppNew.Preferred__c != cppOld.Preferred__c) ||
				(cppNew.UniqueMobile__c != cppOld.UniqueMobile__c)
			) {
				changedRecords.add(cppNew);
			}
		}
		return changedRecords;
	}
}