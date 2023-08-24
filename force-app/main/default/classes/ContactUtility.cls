/**
--------------------------------------- History --------------------------------------------------
01.03.2020		alex.volkov@auspost.com.au    	Added setMailingAddress method
03.10.2021		naveen.rajanna@auspost.com.au 	REQ2620830 Changed setMailingAddress method to populate mailingDPID fields and changed api version to 52
15.08.2023		boris.bachovski2@auspost.com.au General formatting overhaul.
**/

public without sharing class ContactUtility {
	public static final set<string> LICENCE_INACTIVE_STATUSES = new set<string>{'Ceased', 'Not Activated'};
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

	public static void onDeleteLockedSet(List<Contact> ConLst, Map<Id,Contact> oldMapCon) {
		for (Contact con : ConLst) {
			Contact oldCon = oldMapCon != null ? oldMapCon.get(con.Id) : null;

			if (!con.IsPersonAccount && (oldCon == null || (con.delete_locked__c && !oldMapCon.get(con.Id).delete_locked__c))) {
				con.Locked_By__c = UserInfo.getUserId();
				con.Locked_Date__c = Date.today();
			}

			if (!con.delete_locked__c) {
				con.Delete_Locked_Reason__c = '';
				con.Locked_By__c = null;
				con.Locked_Date__c = null;
			}
		}
	}

	public static void raiseErrorIfRestrictedDelete(List<Contact> ConLst) {
		for (Contact con : ConLst) {
			if (con.delete_locked__c && !con.IsPersonAccount) {
				con.AddError(Label.DeleteRestrictionBusinessContact);
			}
		}
	}

	// BAM A.Judd 17-07-2019 Function called from ContactTrigger to delete the Contact Applications associated to the contact on delete of the contact
	// If contact is active and it has active contact apps, then throw an error to prevent delete of contact.
	// Else if contact is not active, or all contact apps are inactive, then delete all contact apps.
	public static void deleteConApps(List<Contact> ConLst, Map<Id,Contact> oldMapCon) {
		Set<Id> conSet = new Set<Id>();
		Set<Id> conActiveWithConAppActiveSet = new Set<Id>();
		List<Contact> conActiveList = new List<Contact>();
		List<BAMContactApplication__c> conappList = new List<BAMContactApplication__c>();

		// Store set of all contacts being deleted
		for (Contact con : ConLst) {
			conSet.add(con.Id);
		}

		// If contacts deleted
		if(!conSet.isEmpty()) {
			//Get all active contacts and any active contact app
			conActiveList = [SELECT Id, (SELECT Id FROM ContactApplications__r WHERE Status__c = 'Active' LIMIT 1)
								FROM Contact
								WHERE Id IN :conSet
								AND Status__c = 'Active'];

			// Loop through list
			for (Contact con : conActiveList) {
				// If an active contact has an active con app, set error on record, and store exclude from con app delete
				if (!con.ContactApplications__r.isEmpty()) {
					conActiveWithConAppActiveSet.add(con.Id);
					Contact conErr = oldMapCon.get(con.Id);
					conErr.AddError('This contact has active application access and can not be deleted. Please deprovision application access before deleting the contact.');
				}
			}

			// Get list of contact apps associated to non active contacts, and contacts without active contact apps
			conappList = [SELECT Id
						  FROM BAMContactApplication__c
						  WHERE Contact__c IN :conSet
						  AND Contact__c NOT IN :conActiveWithConAppActiveSet];

			//If found, delete all
			if (!conappList.isEmpty()) {
				delete conappList;
			}
		}
	}

	public static void updateUserDetails(Map<Id, Contact> newMap, Map<id, Contact> oldMap) {
		List<Id> shortListedIds = new List<Id>();

		for (Contact c : newMap.values()) {
			Contact oldContact = (Contact)oldMap.get(c.Id);

			if (c.FirstName != oldContact.FirstName ||
				c.LastName != oldContact.LastName ||
				c.MailingStreet != oldContact.MailingStreet ||
				c.MailingCity != oldContact.MailingCity ||
				c.MailingState != oldContact.MailingState ||
				c.MailingPostalCode != oldContact.MailingPostalCode ||
				c.MailingCountry != oldContact.MailingCountry ||
				c.Mailing_DPID__c != oldContact.Mailing_DPID__c ||
				c.Phone != oldContact.Phone ||
				c.MobilePhone != oldContact.MobilePhone) {
					shortListedIds.add(c.id);
			}
		}

		if (!shortListedIds.isEmpty()){
			List<User> users = [SELECT FirstName, LastName, ContactId FROM User WHERE IsActive = true AND IsPortalEnabled = true AND ContactId IN :shortListedIds];

			if (!users.isEmpty()) {
				for (User u : users) {
					Contact c = (Contact)newMap.get(u.contactId);

					u.FirstName = c.FirstName;
					u.LastName = c.LastName;
					u.Street = c.MailingStreet + ' ' + c.MailingStreet2__c;
					u.City = c.MailingCity;
					u.State = c.MailingState;
					u.Postalcode = c.MailingPostalCode;
					u.Country = c.MailingCountry;
					u.DPID__c = c.Mailing_DPID__c;
					u.Phone = c.Phone;
					u.MobilePhone = c.MobilePhone;
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

	public static void generateReversePhoneFields(Map<Id, Contact> newMap, Map<Id, Contact> oldMap) {
		List<Contact> shortListed = new List<Contact>();

		for (Contact c : newMap.values()) {
			Contact oldContact = (Contact)oldMap.get(c.Id);

			if (c.Phone != oldContact.Phone ||
				c.HomePhone != oldContact.HomePhone ||
				c.MobilePhone != oldContact.MobilePhone ||
				c.OtherPhone != oldContact.OtherPhone) {
					shortListed.add(c);
			}
		}

		generateReversePhoneFields(shortListed);
	}

	// On update of contact that is a Nominated Partner Contact, ensure that no other  Nominated Partner Contact has the same email address (scenario 3)
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
			for (Account acc : [SELECT Id, Nominated_Partner_Contact_Incent_User__c FROM Account WHERE Nominated_Partner_Contact_Incent_User__c IN: updatedContact]) {
				nominatedContacts.add(acc.Nominated_Partner_Contact_Incent_User__c);
			}
		}

		for (Contact cont : newList) {
			if(nominatedContacts.contains(cont.Id)) {
				Map<String, Object> params = new Map<String, Object>{
					'EmailAddress' => cont.Email,
					'LegalEntityId' => cont.AccountId
				};

				Flow.Interview.Partner_Info_Nominated_Contact_Check fl = new Flow.Interview.Partner_Info_Nominated_Contact_Check(params);
				fl.start();
				
				String returnValue = (String)fl.LegalEntityFoundName;

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
	public static void setMailingAddress(List<Contact> ConLst)
	{
		/** Set of parent accounts for contacts that have no mailing address */
		Set<Id> orgSet = new Set<Id>();

		// Get set of all contacts being inserted that have had an Organisation assigned
		for (Contact con : ConLst) {
			if (con.AccountId != null)
			{
				orgSet.add(con.AccountId);
			}
		}

		/** If any accounts that can lend their data to contacts found */
		if (!orgSet.isEmpty()) {
			// Get Billing Address by account and store in map
			Map<Id, Account> orgMap = new Map<Id, Account>([
					SELECT BillingStreet, BillingStreet2__c, BillingCity, BillingPostalCode, BillingState, BillingCountry, BillingLatitude, BillingLongitude, Billing_DPID__c
					FROM Account
					WHERE Id IN :orgSet
			]);

			// Set Billing Address against Contacts that have Account set against and have not had address set
			for (Contact con : ConLst)
			{
				String billingDPID = orgMap.get(con.AccountId).Billing_DPID__c;

				if (con.AccountId != null && billingDPID != null)
				{
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