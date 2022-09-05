/**
--------------------------------------- History --------------------------------------------------
01.03.2020    alex.volkov@auspost.com.au    Added setMailingAddress method
03.10.2021    naveen.rajanna@auspost.com.au REQ2620830 Changed setMailingAddress method to populate mailingDPID fields and changed api version to 52
**/

public without sharing class ContactUtility {
	public static final set<string> LICENCE_INACTIVE_STATUSES = new set<string>{
			'Ceased', 'Not Activated'
	};
	public static final string UNIQUE_EMAIL_ADDRESS = '"Nominated Partner Contact & Incent User" email address must be unique across all Legal entities with Licences in any status excluding "Ceased" or "Not Activated". The "Nominated Partner Contact & Incent User" for Organisation [ORG NAME] has the same email address as this contact.';

	/**
	  * @description       Exclude MPB sign-up/step-up process
	  * @param             contacts List of new contact records
	  * @param             tInsert Trigger timing
	  * @return            contactList List of contact records to process
	  * @throws            N/A
	*/
	public static List<Contact> mpbFilter(List<Contact> contacts, Boolean tIsInsert) {
		List<Contact> contactList = new List<Contact>();
		if (tIsInsert) {
			for (Contact c : contacts) {
				if (c.Account.AccountSource__c != SSSWConstants.MPB_ACCOUNT_SOURCE) {
					contactList.add(c);
				}
			}
		} else {
			contactList.addAll(contacts);
		}

		return contactList;
	}

	public static void onDeleteLockedSet(List<Contact> ConLst, Map<id, Contact> oldMapCon) {
		for (Contact con : ConLst) {
			Contact oldCon = oldMapCon != null ? oldMapCon.get(con.id) : null;
			if (con.IsPersonAccount == False && (oldCon == null || (con.delete_locked__c == True && oldMapCon.get(con.id).delete_locked__c == False))) {
				con.Locked_By__c = userinfo.getUserId();
				con.Locked_Date__c = date.today();
			}
			if (con.delete_locked__c == false) {
				con.Delete_Locked_Reason__c = '';
				con.Locked_By__c = null;
				con.Locked_Date__c = null;
			}
		}
	}

	public static void raiseErrorIfRestrictedDelete(List<Contact> ConLst) {
		for (Contact con : ConLst) {
			if (con.delete_locked__c == True && con.IsPersonAccount == False) {
				con.AddError(Label.DeleteRestrictionBusinessContact);
			}
		}
	}

	//BAM A.Judd 17-07-2019 Function called from ContactTrigger to delete the Contact Applications associated to the contact on delete of the contact
	//If contact is active and it has active contact apps, then throw an error to prevent delete of contact.
	//Else if contact is not active, or all contact apps are inactive, then delete all contact apps.
	public static void deleteConApps(List<Contact> ConLst, Map<Id, Contact> oldMapCon) {
		Set<Id> conSet = new Set<Id>();
		Set<Id> conActiveWithConAppActiveSet = new Set<Id>();
		List<Contact> conActiveList = new List<Contact>();
		List<BAMContactApplication__c> conappList = new List<BAMContactApplication__c>();

		//Store set of all contacts being deleted
		for (Contact con : ConLst) {
			conSet.add(con.Id);
		}

		//if contacts deleted
		if (conSet.size() > 0) {

			//Get all active contacts and any active contact app
			conActiveList = [
					SELECT Id, (SELECT Id FROM ContactApplications__r WHERE Status__c = 'Active' LIMIT 1)
					FROM Contact
					WHERE Id IN :conSet
					AND Status__c = 'Active'
			];

			//Loop thru list
			for (Contact con : conActiveList) {
				//If active contact has an active con app, set error on record, and store exclude from con app delete
				if (!con.ContactApplications__r.isEmpty()) {
					conActiveWithConAppActiveSet.add(con.Id);
					Contact conErr = oldMapCon.get(con.Id);
					conErr.AddError('This contact has active application access and can not be deleted. Please deprovision application access before deleting the contact.');
				}
			}

			//Get list of contact apps associated to non active contacts, and contacts without active contact apps
			conappList = [
					SELECT Id
					FROM BAMContactApplication__c
					WHERE Contact__c IN :conSet
					AND Contact__c NOT IN :conActiveWithConAppActiveSet
			];

			//If found, delete all
			if (conappList.size() > 0) {
				delete conappList;
			}
		}
	}

	public static void updateUserDetails(Map<id, Contact> newMap, Map<id, Contact> oldMap) {
		List<id> shortListedIds = new List<id>();
		for (Contact c : newMap.values()) {
			if (c.firstname != oldMap.get(c.id).firstname ||
					c.lastname != oldMap.get(c.id).lastname ||
					c.MailingStreet != oldMap.get(c.id).MailingStreet ||
					c.MailingCity != oldMap.get(c.id).MailingCity ||
					c.MailingState != oldMap.get(c.id).MailingState ||
					c.MailingPostalCode != oldMap.get(c.id).MailingPostalCode ||
					c.MailingCountry != oldMap.get(c.id).MailingCountry ||
					c.Mailing_DPID__c != oldMap.get(c.id).Mailing_DPID__c ||
					c.Phone != oldMap.get(c.id).Phone ||
					c.MobilePhone != oldMap.get(c.id).MobilePhone) {
				shortListedIds.add(c.id);
			}
		}

		if (!shortListedIds.isEmpty()) {
			List<User> users = [select FirstName, LastName, ContactId from User where isactive = true and isportalenabled = true and contactId in :shortListedIds];
			if (!users.isEmpty()) {
				for (User u : users) {
					u.FirstName = newMap.get(u.contactId).firstname;
					u.lastName = newMap.get(u.contactId).lastname;
					u.Street = newMap.get(u.contactId).MailingStreet + ' ' + newMap.get(u.contactId).MailingStreet2__c;
					u.City = newMap.get(u.contactId).MailingCity;
					u.State = newMap.get(u.contactId).MailingState;
					u.Postalcode = newMap.get(u.contactId).MailingPostalCode;
					u.Country = newMap.get(u.contactId).MailingCountry;
					u.DPID__c = newMap.get(u.contactId).Mailing_DPID__c;
					u.Phone = newMap.get(u.contactId).Phone;
					u.MobilePhone = newMap.get(u.contactId).MobilePhone;
				}
				update users;
			}
		}
	}

	public static void generateReversePhoneFields(List<Contact> contacts) {
		for (Contact c : contacts) {
			c.ReversePhoneFields__c = Util.reversePhoneString(c.Phone) + ' ';
			c.ReversePhoneFields__c += Util.reversePhoneString(c.HomePhone) + ' ';
			c.ReversePhoneFields__c += Util.reversePhoneString(c.MobilePhone) + ' ';
			c.ReversePhoneFields__c += Util.reversePhoneString(c.OtherPhone) + ' ';
		}
	}

	public static void generateReversePhoneFields(Map<id, Contact> newMap, Map<id, Contact> oldMap) {
		List<Contact> shortListed = new List<Contact>();
		for (Contact c : newMap.values()) {
			if (c.Phone != oldMap.get(c.id).Phone ||
					c.HomePhone != oldMap.get(c.id).HomePhone ||
					c.MobilePhone != oldMap.get(c.id).MobilePhone ||
					c.OtherPhone != oldMap.get(c.id).OtherPhone) {

				shortListed.add(c);
			}
		}
		generateReversePhoneFields(shortListed);
	}

	//On update of contact that is a Nominated Partner Contact, ensure that no other  Nominated Partner Contact has the same email address (scenario 3)
	public static void checkContactEmail(List<Contact> newList, Map<Id, Contact> oldMap) {
		Set<Id> updatedContact = new Set<Id>();
		Set<Id> nominatedContacts = new Set<Id>();
		for (Contact cont : newList) {
			Contact oldCont = oldMap.get(cont.Id);
			if (cont.Email != oldCont.Email) {
				updatedContact.add(cont.Id);
			}
		}
		if (!updatedContact.isEmpty()) {
			for (Account acc : [Select Id, Nominated_Partner_Contact_Incent_User__c From Account Where Nominated_Partner_Contact_Incent_User__c in :updatedContact]) {
				nominatedContacts.add(acc.Nominated_Partner_Contact_Incent_User__c);
			}
		}
		for (Contact cont : newList) {
			if (nominatedContacts.contains(cont.Id)) {
				Map<String, Object> params = new Map<String, Object>();
				params.put('EmailAddress', cont.Email);
				params.put('LegalEntityId', cont.AccountId);
				Flow.Interview.Partner_Info_Nominated_Contact_Check fl = new Flow.Interview.Partner_Info_Nominated_Contact_Check(params);
				fl.start();
				String returnValue = (String) fl.LegalEntityFoundName;
				if (returnValue != null) {
					cont.addError(UNIQUE_EMAIL_ADDRESS.replace('[ORG NAME]', returnValue));
				}
			}
		}
	}

	/**
	 * @description Sets mailing address (if not populated) on the contact to account billing address
	 * @param ConLst New records
	 */
	public static void setMailingAddress(List<Contact> ConLst) {
		/** Set of parent accounts for contacts that have no mailing address */
		Set<Id> orgSet = new Set<Id>();

		//Get set of all contacts being inserted that have had an Organisation assigned
		for (Contact con : ConLst) {
			if (con.AccountId != null) {
				orgSet.add(con.AccountId);
			}
		}

		/** If any accounts that can lend their data to contacts found */
		if (!orgSet.isEmpty()) {
			//Get Billing Address by account and store in map
			Map<Id, Account> orgMap = new Map<Id, Account>([
					SELECT BillingStreet, BillingStreet2__c, BillingCity, BillingPostalCode, BillingState, BillingCountry,
							BillingLatitude, BillingLongitude, Billing_DPID__c
					FROM Account
					WHERE Id IN :orgSet
			]);

			//Set Billing Address against Contacts that have Account set against and have not had address set
			for (Contact con : ConLst) {
				String billingDPID = orgMap.get(con.AccountId).Billing_DPID__c;
				if (con.AccountId != null && billingDPID != null) {
					/* con.MailingStreet = orgMap.get(con.AccountId).BillingStreet;
					con.MailingCity = orgMap.get(con.AccountId).BillingCity;
					con.MailingPostalCode = orgMap.get(con.AccountId).BillingPostalCode;
					con.MailingState = orgMap.get(con.AccountId).BillingState;
					con.MailingCountry = orgMap.get(con.AccountId).BillingCountry;
					con.MailingLatitude = orgMap.get(con.AccountId).BillingLatitude;
					con.MailingLongitude = orgMap.get(con.AccountId).BillingLongitude; */
					con.MailingStreet2__c = orgMap.get(con.AccountId).BillingStreet2__c;
					con.Mailing_DPID__c = billingDPID;
					con.MailingDPID__c = billingDPID;
				}
			}
		}
	}
}