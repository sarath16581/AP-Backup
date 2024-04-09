/**
 * @description       : This is a helper class for Connected Customer Email Payload
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-13-2022
 * @last modified by  : Sreenish Krishnan
 * @changelog
 * 2024-04-09 - Mahesh Parvathaneni - Fixed an exception for duplicate values in the list
 **/
public inherited sharing class CustomerDataSyncEventCPEmailHelper {
	//CPE variables
	private static final String CPE_UPSERT = 'CPE_UPSERT';
	private static final String CPE_DELETE = 'CPE_DELETE';
	private Set<String> emailsSet = new Set<String>();
	private Set<ID> custIds = new Set<ID>();

	//map for upsert and delete of cp emails
	private Map<String, List<Object>> cpEmailMap = new Map<String, List<Object>>{
		CPE_UPSERT => new List<ContactPointEmail>(),
		CPE_DELETE => new List<ContactPointEmail>()
	};

	List<SObject> cpeUpsertList = new List<SObject>();
	List<SObject> cpeDeleteList = new List<SObject>();

	//logic to deserialise the email payload
	public List<EmailPayloadWrapper> deserialisePayload(CustomerDataSync__e event) {
		List<EmailPayloadWrapper> result = new List<EmailPayloadWrapper>();
		if (!String.isBlank(event.emails__c)) {
			result = (List<EmailPayloadWrapper>) System.JSON.deserialize(event.emails__c, List<EmailPayloadWrapper>.class);
		}
		return result;
	}

	/**
	 * @description :Core logic to deal with the contact point emails called from the event handler
	 * @author Sreenish Krishnan | 06-22-2022
	 * @param eventCpEmailWrapper
	 * @param resultCustomerMap
	 **/
	public void syncContactPointEmail(
		Map<String, List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>> input,
		Map<String, List<ContactPointEmail>> existing,
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> customers
	) {
		try {
			contactPointEmailLogic(input, customers, existing);

			cpeUpsertList = (List<SObject>) cpEmailMap.get(CPE_UPSERT);
			cpeDeleteList = (List<SObject>) cpEmailMap.get(CPE_DELETE);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'CustomerDataSyncEventCPEmailHelper',
				CustomerDataSyncEventCPEmailHelper.class.getName(),
				'createContactPointEmail',
				'CustomerDataSyncEventCPEmailHelper',
				LoggingLevel.ERROR
			);
		}
	}

	/** 
	 * @description core logic to pass input wrapper, upserted customers and the queried existing emails and 
	 * generate the email records that needs to be updated
	 * @author Sreenish Krishnan | 07-13-2022 
	 * @param input 
	 * @param upsertedCustomers 
	 * @param existingEmails 
	 **/
	private void contactPointEmailLogic(
		Map<String, List<EmailPayloadWrapper>> input,
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> upsertedCustomers,
		Map<String, List<ContactPointEmail>> existingEmails
	) {
		List<ContactPointEmail> cpEmail = new List<ContactPointEmail>();
		for (String apcn : upsertedCustomers.keySet()) {
			List<EmailPayloadWrapper> emails = new List<EmailPayloadWrapper>();
			CustomerDataSyncEventCustomerHelper.CustomerUpsertResult customers = new CustomerDataSyncEventCustomerHelper.CustomerUpsertResult();
			List<ContactPointEmail> existing = new List<ContactPointEmail>();

			if (upsertedCustomers.containsKey(apcn)) {
				customers = upsertedCustomers.get(apcn);
			}
			if (existingEmails.containsKey(apcn)) {
				existing = existingEmails.get(apcn);
			}
			//get input emails
			if (input.containsKey(apcn)) {
				emails = input.get(apcn);
			}

			compareEmailRecords(emails, customers, existing);
		}
	}

	//get the emails list to upsert
	public List<SObject> getCPEmailsUpsertList() {
		//convert to map to remove duplicates
		Map<Id, SObject> cpeUpsertMap = new Map<Id, SObject>();
		if (!cpeUpsertList.isEmpty()) {
			cpeUpsertMap.putAll(cpeUpsertList);
			cpeUpsertList = cpeUpsertMap.values();
		}
		return cpeUpsertList;
	}

	//get the emails list to delete
	public List<SObject> getCPEmailsDeleteList() {
		//convert to map to remove duplicates
		Map<Id, SObject> cpeDeleteMap = new Map<Id, SObject>();
		if (!cpeDeleteList.isEmpty()) {
			cpeDeleteMap.putAll(cpeDeleteList);
			cpeDeleteList = cpeDeleteMap.values();
		}
		return cpeDeleteList;
	}

	//map Contact Point Emails
	private ContactPointEmail mapContactPointEmail(ContactPointEmail cpe, EmailPayloadWrapper input) {
		//ContactPointEmail cpe= new ContactPointEmail();
		cpe.EmailAddress = input.emailAddress;
		cpe.Preferred__c = Boolean.valueOf(input.isPrimary); //need to be checked
		cpe.Verified__c = Boolean.valueOf(input.isVerified);
		cpe.IsCredential__c = Boolean.valueOf(input.isCredentialEmail);
		cpe.AuthenticationEmail__c = Boolean.valueOf(input.isCredentialEmail);
		return cpe;
	}

	//compare emails in the payload with the existing emails
	private void compareEmailRecords(
		List<EmailPayloadWrapper> emailsInput,
		CustomerDataSyncEventCustomerHelper.CustomerUpsertResult customers,
		List<ContactPointEmail> existing
	) {
		List<String> emailAddressChckList = new List<String>();
		List<ContactPointEmail> updateResult = new List<ContactPointEmail>();
		List<ContactPointEmail> insertResult = new List<ContactPointEmail>();
		List<ContactPointEmail> deleteResult = new List<ContactPointEmail>();

		List<String> emailsExistingChk = genEmailsListFromCPE(existing);

		for (EmailPayloadWrapper input : emailsInput) {
			emailAddressChckList.add(input.emailAddress);
			//if its an existing record, then update else insert
			Integer index1 = emailsExistingChk.indexOf(input.emailAddress);

			ContactPointEmail cpe1 = new ContactPointEmail();
			if (index1 >= 0) {
				cpe1.Id = existing[index1].Id;
				updateResult.add(mapContactPointEmail(cpe1, input));
			} else {
				cpe1.ParentId = customers.recId;
				cpe1.Contact__c = customers.PersonContactId;
				insertResult.add(mapContactPointEmail(cpe1, input));
			}
		}

		//check for deletes
		if (!existing.isEmpty()) {
			for (ContactPointEmail cpe2 : existing) {
				Integer index2 = emailAddressChckList.indexOf(cpe2.EmailAddress);
				if (index2 < 0) {
					deleteResult.add(cpe2);
				}
			}
		}

		if (!updateResult.isEmpty()) {
			cpEmailMap.get('CPE_UPSERT').addAll(updateResult);
		}
		if (!insertResult.isEmpty()) {
			cpEmailMap.get('CPE_UPSERT').addAll(insertResult);
		}
		if (!deleteResult.isEmpty()) {
			cpEmailMap.get('CPE_DELETE').addAll(deleteResult);
		}
	}

	//method to get Emails from ContactPointEmail Object
	private Set<String> getEmails(List<Object> emails) {
		for (Object o : emails) {
			String email = ((EmailPayloadWrapper) o).emailAddress;
			if (!emailsSet.contains(email)) {
				emailsSet.add(email);
			}
		}
		return emailsSet;
	}

	//generate list of emails from Contact Point Email deserialized value
	private List<String> genEmailsListFromCPE(List<ContactPointEmail> emails) {
		List<String> emailsList = new List<String>();
		for (ContactPointEmail email : emails) {
			emailsList.add(email.EmailAddress);
		}
		return emailsList;
	}

	@testVisible
	public class EmailPayloadWrapper {
		public String emailAddress { get; set; }
		public String isVerified { get; set; }
		public String isPrimary { get; set; }
		public String isCredentialEmail { get; set; }
	}
}