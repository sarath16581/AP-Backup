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

	public void applyPhoneNumberFormatting(List<ContactPointPhone> records, Map<Id, ContactPointPhone> existingRecords) {
		StringFormattingService service = StringFormattingService.getInstance();

		if (existingRecords != null && existingRecords.isEmpty() == false) {
			for (ContactPointPhone ctp : records) {
				if (ctp.TelephoneNumber != existingRecords.get(ctp.Id).TelephoneNumber) {
					ctp.TelephoneNumber = service.formatPhoneNumber(ctp.TelephoneNumber);
				}
			}
		} else {
			for (ContactPointPhone ctp : records) {
				if (String.isBlank(ctp.TelephoneNumber) == false) {
					ctp.TelephoneNumber = service.formatPhoneNumber(ctp.TelephoneNumber);
				}
			}
		}
	}

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

	public void applyPhoneNumberFormatting(List<Account> records, Map<Id, Account> existingRecords) {
		StringFormattingService service = StringFormattingService.getInstance();

		if (existingRecords != null && existingRecords.isEmpty() == false) {
			for (Account acc : records) {
				if (acc.isPersonAccount == true) {
					if (acc.Phone != existingRecords.get(acc.Id).Phone) {
						acc.Phone = service.formatPhoneNumber(acc.Phone);
					}
					if (acc.PersonMobilePhone != existingRecords.get(acc.Id).PersonMobilePhone) {
						acc.PersonMobilePhone = service.formatPhoneNumber(acc.PersonMobilePhone);
					}
					if (acc.VerifiedMobile__pc != existingRecords.get(acc.Id).VerifiedMobile__pc) {
						acc.VerifiedMobile__pc = service.formatPhoneNumber(acc.VerifiedMobile__pc);
					}
					if (acc.PersonHomePhone != existingRecords.get(acc.Id).PersonHomePhone) {
						acc.PersonHomePhone = service.formatPhoneNumber(acc.PersonHomePhone);
					}
				}
			}
		} else {
			for (Account acc : records) {
				if (acc.isPersonAccount == true) {
					if (String.isBlank(acc.Phone) == false) {
						acc.Phone = service.formatPhoneNumber(acc.Phone);
					}
					if (String.isBlank(acc.PersonMobilePhone) == false) {
						acc.PersonMobilePhone = service.formatPhoneNumber(acc.PersonMobilePhone);
					}
					if (String.isBlank(acc.VerifiedMobile__pc) == false) {
						acc.VerifiedMobile__pc = service.formatPhoneNumber(acc.VerifiedMobile__pc);
					}
					if (String.isBlank(acc.PersonHomePhone) == false) {
						acc.PersonHomePhone = service.formatPhoneNumber(acc.PersonHomePhone);
					}
				}
			}
		}
	}

	//method to sync CPEmail records with contact
	public List<Contact> syncContactPointEmailToContacts(List<ContactPointEmail> records, List<ContactPointEmail> existing) {
		Boolean handleDelete = false;
		handleDelete = (records != null ? false : (existing != null ? true : false));

		//get all the contacts that are associated to the contact point email
		Set<Id> contactIds = (handleDelete == true ? getContactIds(existing) : getContactIds(records));

		ContactsSelector selectorContacts = ContactsSelector.newInstance();
		Map<Id, Contact> contactExistingMap = new Map<Id, Contact>();
		Map<Id, Contact> contactsUpsertMap = new Map<Id, Contact>();
		List<Contact> contactList = new List<Contact>();

		//its for delete scenario
		if (handleDelete) {
			contactExistingMap = selectorContacts.selectById(contactIds);
		} else {
			contactsUpsertMap = handleUpsertsForCPESyncWithContact(contactIds);
		}

		contactList = dedupeContacts(contactsUpsertMap.values());

		//if contactsmap is empty and contactids are not empty, then create a contact list with contact ids and contact records and add to dmlupdate
		if (handleDelete) {
			for (Id cId : contactIds) {
				if (contactExistingMap.containsKey(cId)) {
					contactList.add(mapContactForNoCPERecords(cId, CPE_FLAGS.NO_RECORDS));
				}
			}
		}
		//this may need to b verified (temp comment)
		//ApplicationDatabase.getInstance().dmlUpdate(contactList);
		return contactList;
	}

	//method to sync CPPhone records with contact
	public List<Contact> syncContactPointPhoneToContacts(List<ContactPointPhone> records, List<ContactPointPhone> existing) {
		Boolean handleDelete = false;
		handleDelete = (records != null ? false : (existing != null ? true : false));

		//get all the contacts that are associated to the contact point email
		Set<Id> contactIds = (handleDelete == true ? getContactIds(existing) : getContactIds(records));

		ContactsSelector selectorContacts = ContactsSelector.newInstance();
		Map<Id, Contact> contactExistingMap = new Map<Id, Contact>();
		Map<Id, Contact> contactsUpsertMap = new Map<Id, Contact>();
		List<Contact> contactList = new List<Contact>();

		//its for delete scenario
		if (handleDelete) {
			contactExistingMap = selectorContacts.selectById(contactIds);
		} else {
			contactsUpsertMap = handleUpsertsForCPPSyncWithContact(contactIds);
		}

		contactList = dedupeContacts(contactsUpsertMap.values());
		//if contactsmap is empty and contactids are not empty, then create a contact list with contact ids and contact records and add to dmlupdate
		if (handleDelete) {
			for (Id cId : contactIds) {
				if (contactExistingMap.containsKey(cId)) {
					contactList.add(mapContactForNoCPPRecords(cId, CPP_FLAGS.NO_RECORDS));
				}
			}
		}
		//this may need to b verified
		//ApplicationDatabase.getInstance().dmlUpdate(contactList);
		return contactList;
	}

	//helper method to syncContactPointEmailToContacts to handle upserts for CPE
	private Map<Id, Contact> handleUpsertsForCPESyncWithContact(Set<Id> contactIds) {
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
		ContactPointEmailSelector selector = ContactPointEmailSelector.newInstance();

		//query all the contact point emails associated to the contacts's and do the logic
		List<ContactPointEmail> cpEmails = selector.selectByContact(contactIds, new Set<Object>());
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

			System.debug('contactsMap >>' + contactMap);
			contactMap = prepareContactMap(cpe, contactMap);
		}
		return contactMap;
	}

	//helper method to syncContactPointPhoneToContacts to handle upserts for CPP
	private Map<Id, Contact> handleUpsertsForCPPSyncWithContact(Set<Id> contactIds) {
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
		ContactPointPhoneSelector selector = ContactPointPhoneSelector.newInstance();

		List<ContactPointPhone> cpPhones = selector.selectByContact(contactIds, new Set<Object>());

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

			System.debug('contactMap>>>' + contactMap);
			contactMap = prepareContactMap(cpp, contactMap);
		}

		return contactMap;
	}

	//create the map for CPEmail
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

	//create the map for CPPhone
	private Map<Id, Contact> prepareContactMap(ContactPointPhone cpp, Map<Id, Contact> contactMap) {
		if ((cpp.PhoneType).equalsIgnoreCase(CPP_PHONE_TYPE.MOBILE.name())) {
			contactMap = getContactMapForMobileType(cpp, contactMap);
		} else if ((cpp.PhoneType).equalsIgnoreCase(CPP_PHONE_TYPE.HOME.name())) {
			contactMap = getContactMapForHomeType(cpp, contactMap);
		}
		return contactMap;
	}

	//logic for dealing with verified flag and prefferd flag in CPPhone fro Mobile
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

	//logic to deal with Home Type Phone
	private Map<Id, Contact> getContactMapForHomeType(ContactPointPhone cpp, Map<Id, Contact> contactMap) {
		Boolean hasEntryForHome = getEntry(cpp, contactMap, CPP_PHONE_TYPE.HOME);
		if (!hasEntryForHome) {
			contactMap.put(cpp.contact__c, mapContactFromContactPointPhone(cpp, contactMap, CPP_FLAGS.NONE, CPP_PHONE_TYPE.HOME));
		}

		return contactMap;
	}

	//return the entry in contact map relevant to the phone type
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

	//this method takes contacts and returns deduped list of contacts
	private List<Contact> dedupeContacts(List<Contact> contacts) {
		Set<Contact> temp = new Set<Contact>();
		List<Contact> contactList = new List<Contact>();
		if (!contacts.isEmpty()) {
			temp.addAll(contacts);
			contactList.addAll(temp);
		}
		return contactList;
	}

	//this method is to map when there are no contact point emails for contact
	private Contact mapContactForNoCPERecords(Id contactId, ContactService.CPE_FLAGS flag) {
		Contact ct = new Contact(Id = contactId);
		if (flag == CPE_FLAGS.NO_RECORDS) {
			ct.Email = null;
			ct.VerifiedEmail__c = null;
		}
		return ct;
	}
	//this method is to map when there are no contact point emails for contact
	private Contact mapContactForNoCPPRecords(Id contactId, ContactService.CPP_FLAGS flag) {
		Contact ct = new Contact(Id = contactId);
		if (flag == CPP_FLAGS.NO_RECORDS) {
			ct.MobilePhone = null;
			ct.VerifiedMobile__c = null;
			ct.HomePhone = null;
			ct.UniqueMobile__c = false;
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
	//this method is to map when there are contact point emails for contact that need to be upserted
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
			ct.UniqueMobile__c = cpp.UniqueMobile__c;

			if ((flag == CPP_FLAGS.MOBILE_VERIFIED) || (flag == CPP_FLAGS.MOBILE_VERIFIED_AND_PREFFERED)) {
				return ct;
			} else if (flag == CPP_FLAGS.MOBILE_UNVERIFIED) {
				//override VerifiedMobile__c and ct.UniqueMobile__c
				ct.MobilePhone = cpp.TelephoneNumber;
				ct.VerifiedMobile__c = null;
				ct.UniqueMobile__c = false;
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
			ct = new Contact(id = cpp.contact__c);
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
}