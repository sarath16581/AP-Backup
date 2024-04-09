/**
 * @description       : This is a helper class for Connected Customer Phone Payload
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-29-2022
 * @last modified by  : Sreenish Krishnan
 * @changelog
 * 2024-04-09 - Mahesh Parvathaneni - Fixed an exception for duplicate values in the list
 **/
public inherited sharing class CustomerDataSyncEventCPPhoneHelper {
	//CPE variables
	private static final String CPP_UPSERT = 'CPP_UPSERT';
	private static final String CPP_DELETE = 'CPP_DELETE';
	private Set<String> phonesSet = new Set<String>();
	private Set<ID> custIds = new Set<ID>();

	//map to capture the final CP phone records to upsert and delete
	private Map<String, List<Object>> cpPhoneMap = new Map<String, List<Object>>{
		CPP_UPSERT => new List<ContactPointPhone>(),
		CPP_DELETE => new List<ContactPointPhone>()
	};

	List<SObject> cppUpsertList = new List<SObject>();
	List<SObject> cppDeleteList = new List<SObject>();

	//deserialise the phone payload
	public List<PhonePayloadWrapper> deserialisePayload(CustomerDataSync__e event) {
		List<PhonePayloadWrapper> result = new List<PhonePayloadWrapper>();
		if (!String.isBlank(event.phones__c)) {
			result = (List<PhonePayloadWrapper>) System.JSON.deserialize(event.phones__c, List<PhonePayloadWrapper>.class);
		}
		return result;
	}

	/**
	 * @description : logic called from the event handler class
	 * @author Sreenish Krishnan | 07-13-2022 
	 * @param input 
	 * @param existing 
	 * @param customers 
	**/
	public void syncContactPointPhone(
		Map<String, List<PhonePayloadWrapper>> input,
		Map<String, List<ContactPointPhone>> existing,
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> customers
	) {
		try {
			contactPointPhoneLogic(input, customers, existing);

			cppUpsertList = (List<SObject>) cpPhoneMap.get(CPP_UPSERT);
			cppDeleteList = (List<SObject>) cpPhoneMap.get(CPP_DELETE);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'CustomerDataSyncEventCPPhoneHelper',
				CustomerDataSyncEventCPEmailHelper.class.getName(),
				'syncContactPointPhone',
				'CustomerDataSyncEventCPPhoneHelper',
				LoggingLevel.ERROR
			);
		}
	}

	//get the phones list to upsert
	public List<SObject> getCPPhonesUpsertList() {
		//convert to map to remove duplicates
		Map<Id, SObject> cppUpsertMap = new Map<Id, SObject>();
		if (!cppUpsertList.isEmpty()) {
			cppUpsertMap.putAll(cppUpsertList);
			cppUpsertList = cppUpsertMap.values();
		}
		return cppUpsertList;
	}

	//get the phones list to delete
	public List<SObject> getCPPhonesDeleteList() {
		//convert to map to remove duplicates
		Map<Id, SObject> cppDeleteMap = new Map<Id, SObject>();
		if (!cppDeleteList.isEmpty()) {
			cppDeleteMap.putAll(cppDeleteList);
			cppDeleteList = cppDeleteMap.values();
		}
		return cppDeleteList;
	}

	/**
	 * @description : core logic to pass inputwrapper, usperted customers and existing CP phone records and generate
	 * final output
	 * @author Sreenish Krishnan | 07-13-2022 
	 * @param input 
	 * @param upsertedCustomers 
	 * @param existingPhones 
	**/
	private void contactPointPhoneLogic(
		Map<String, List<PhonePayloadWrapper>> input,
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> upsertedCustomers,
		Map<String, List<ContactPointPhone>> existingPhones
	) {
		List<ContactPointPhone> cpPhone = new List<ContactPointPhone>();
		for (String apcn : upsertedCustomers.keySet()) {
			List<PhonePayloadWrapper> phones = new List<PhonePayloadWrapper>();
			CustomerDataSyncEventCustomerHelper.CustomerUpsertResult customers = new CustomerDataSyncEventCustomerHelper.CustomerUpsertResult();
			List<ContactPointPhone> existing = new List<ContactPointPhone>();

			if (upsertedCustomers.containsKey(apcn)) {
				customers = upsertedCustomers.get(apcn);
			}
			if (existingPhones.containsKey(apcn)) {
				existing = existingPhones.get(apcn);
			}
			//get input emails
			if (input.containsKey(apcn)) {
				phones = input.get(apcn);
			}

			comparePhoneRecords(phones, customers, existing);
		}
	}

	//generate list of phones from Contact Point Phones deserialized value
	private void comparePhoneRecords(
		List<PhonePayloadWrapper> phonesInput,
		CustomerDataSyncEventCustomerHelper.CustomerUpsertResult customers,
		List<ContactPointPhone> existing
	) {
		List<String> phoneNumbersChckList = new List<String>();
		List<ContactPointPhone> updateResult = new List<ContactPointPhone>();
		List<ContactPointPhone> insertResult = new List<ContactPointPhone>();
		List<ContactPointPhone> deleteResult = new List<ContactPointPhone>();
		List<String> phonesExistingChk = genPhonesListFromCPP(existing);

		for (PhonePayloadWrapper input : phonesInput) {
			phoneNumbersChckList.add(input.type.toUppercase() + '-' + input.phone);
			Integer index1 = phonesExistingChk.indexOf(input.type.toUppercase() + '-' + input.phone);

			ContactPointPhone cpp1 = new ContactPointPhone();
			if (index1 >= 0) {
				cpp1.Id = existing[index1].Id;
				updateResult.add(mapContactPointPhone(cpp1, input));
			} else {
				cpp1.ParentId = customers.recId;
				cpp1.Contact__c = customers.PersonContactId;
				insertResult.add(mapContactPointPhone(cpp1, input));
			}
		}

		//check for deletes
		if (!existing.isEmpty()) {
			for (ContactPointPhone cpe2 : existing) {
				Integer index2 = phoneNumbersChckList.indexOf(cpe2.PhoneType.toUppercase() + '-' + cpe2.TelephoneNumber);
				if (index2 < 0) {
					deleteResult.add(cpe2);
				}
			}
		}

		if (!updateResult.isEmpty()) {
			cpPhoneMap.get('CPP_UPSERT').addAll(updateResult);
		}
		if (!insertResult.isEmpty()) {
			cpPhoneMap.get('CPP_UPSERT').addAll(insertResult);
		}
		if (!deleteResult.isEmpty()) {
			cpPhoneMap.get('CPP_DELETE').addAll(deleteResult);
		}
	}

	//map Contact Point Phones
	private ContactPointPhone mapContactPointPhone(ContactPointPhone cpp, PhonePayloadWrapper input) {
		cpp.Preferred__c = Boolean.valueOf(input.isPrimary); 
		cpp.Verified__c = Boolean.valueOf(input.isVerified);
		cpp.UniqueMobile__c = Boolean.valueOf(input.isUnique);
		cpp.PhoneType = input.type;
		cpp.TelephoneNumber = input.phone;

		return cpp;
	}

	//generate list of emails from Contact Point Email deserialized value
	private List<String> genPhonesListFromCPP(List<ContactPointPhone> phones) {
		List<String> phonesList = new List<String>();
		for (ContactPointPhone phone : phones) {
			phonesList.add(phone.PhoneType.toUppercase() + '-' + phone.TelephoneNumber);
		}
		return phonesList;
	}

	@testVisible
	public class PhonePayloadWrapper {
		public String phone { get; set; }
		public String type { get; set; }
		public String isVerified { get; set; }
		public String isUnique { get; set; }
		public String isPrimary { get; set; }
	}
}