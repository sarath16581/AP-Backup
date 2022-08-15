/**
 * @description       : This is the method called from the Customer Data Sync Platform Event Trigger
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 08-13-2022
 * @last modified by  : Sreenish Krishnan
 **/

public inherited sharing class CustomerDataSyncEventHandler {
	public class CustomerDataSyncException extends Exception {
	}
	//key class variables
	private static final String APCN = 'APCN';
	private static final String SFID = 'SFID';
	Set<String> apcns = new Set<String>();
	Set<ID> sfIds = new Set<ID>();

	//these are the helper variables to process email, phone and address
	CustomerDataSyncEventCPEmailHelper cpEmailHelper = new CustomerDataSyncEventCPEmailHelper();
	CustomerDataSyncEventCPPhoneHelper cpPhoneHelper = new CustomerDataSyncEventCPPhoneHelper();
	CustomerDataSyncEventCPAddressHelper cpAddressHelper = new CustomerDataSyncEventCPAddressHelper();

	//these are the wrapper variables
	Map<String, List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>> apcnVsEmails = new Map<String, List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>>();
	Map<String, List<CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper>> apcnVsAddresses = new Map<String, List<CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper>>();
	Map<String, List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>> apcnVsPhones = new Map<String, List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>>();

	//events filtered based on integration mod time stamp
	Map<String, CustomerDataSync__e> filteredEvents = new Map<String, CustomerDataSync__e>();

	//variables to be used for query filter
	Set<Id> contactIds = new Set<Id>();
	Set<Id> customerIds = new Set<Id>();
	Set<String> emailAdresses = new Set<String>();
	Set<String> phoneNumbers = new Set<String>();

	//variables to be used for DML
	List<ContactPointAddress> cpAddressToInsert = new List<ContactPointAddress>();
	List<ContactPointEmail> cpEmailsToDelete = new List<ContactPointEmail>();
	List<ContactPointEmail> cpEmailsToUpsert = new List<ContactPointEmail>();
	List<ContactPointPhone> cpPhonesToDelete = new List<ContactPointPhone>();
	List<ContactPointPhone> cpPhonesToUpsert = new List<ContactPointPhone>();

	/**
	 * @description :Create a new instance. Used for dependency injection for mocking
	 * @author Sreenish Krishnan | 05-31-2022
	 * @return CustomerDataSyncEventHandler
	 **/
	public static CustomerDataSyncEventHandler getInstance() {
		return (CustomerDataSyncEventHandler) Application.Utilities.getInstance(CustomerDataSyncEventHandler.class);
	}

	/**
	 * @description :Process events from TIBCO to create Contact Point Records
	 * @author Sreenish Krishnan | 05-31-2022
	 * @param events
	 **/
	public void processCustomerDataSyncEvent(List<CustomerDataSync__e> events) {
		System.debug('events are ' + events);

		//this helper class is to process the root of the payload which is customer with APCN as the primary key
		CustomerDataSyncEventCustomerHelper customerHelper = new CustomerDataSyncEventCustomerHelper();

		try {
			//**STEP 1: Filter the events so that only latest apcn is picked
			//**STEP 2: Generate the customer refernece map after querying Account
			//**STEP 3: Upsert Customer Data
			//**STEP 4: Prep Query filter variables to for #5
			//**STEP 5: Query existing CPEmail, CPPhone, CPAddress object
			//**STEP 6: Core Sync logic for CPEmails
			//**STEP 7: Core Sync logic for CPPhones
			//**STEP 8: Core Sync logic for CPAddress
			//**STEP 9: Process DML's for CPEmails,CPPhones and CPAddresses

			//STEP 1
			filterWithParsing(events);

			//STEP 2
			Map<String, Map<String, Object>> existingCustMap = new Map<String, Map<String, Object>>(genCustomerRefMap(apcns, sfIds));
			Map<String, List<ContactPointEmail>> existingEmailsMap = new Map<String, List<ContactPointEmail>>();
			Map<String, List<ContactPointPhone>> existingPhonesMap = new Map<String, List<ContactPointPhone>>();

			//STEP 3
			Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> upsertedCustomerMap = customerHelper.upsertCustomerData(
				filteredEvents.values(),
				existingCustMap
			);

			//STEP 4
			for (String apcn : upsertedCustomerMap.keySet()) {
				CustomerDataSyncEventCustomerHelper.CustomerUpsertResult upsertResult = upsertedCustomerMap.get(apcn);
				if (upsertResult.isSuccess) {
					contactIds.add(upsertResult.personContactId);
					customerIds.add(upsertResult.recId);

					emailAdresses.addAll(getEmails(apcnVsEmails.containsKey(apcn) == true ? apcnVsEmails.get(apcn) : new List<Object>{}));
					phoneNumbers.addAll(getPhones(apcnVsPhones.containsKey(apcn) == true ? apcnVsPhones.get(apcn) : new List<Object>{}));

					cpAddressToInsert.addAll(cpAddressHelper.getContactPointAddress(upsertResult, apcnVsAddresses.get(apcn)));
				}
			}

			//STEP 5
			existingEmailsMap = queryContactPointEmails(customerIds, emailAdresses);
			existingPhonesMap = queryContactPointPhones(customerIds);

			//STEP 6
			cpEmailHelper.syncContactPointEmail(
				apcnVsEmails,
				(Map<String, List<ContactPointEmail>>) existingEmailsMap,
				(Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>) upsertedCustomerMap
			);

			cpPhoneHelper.syncContactPointPhone(
				apcnVsPhones,
				(Map<String, List<ContactPointPhone>>) existingPhonesMap,
				(Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>) upsertedCustomerMap
			);

			//STEP 7
			performContactPointDMLs();
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'CustomerDataSyncEventHandler',
				CustomerDataSyncEventHandler.class.getName(),
				'processCustomerDataSyncEvent',
				'CustomerDataSyncEventHandler',
				LoggingLevel.ERROR
			);
		}
	}

	//method called to perform DML
	private void performContactPointDMLs() {
		List<SObject> cpeUpsertList = new List<SObject>();
		List<SObject> cpeDeleteList = new List<SObject>();
		List<SObject> cppUpsertList = new List<SObject>();
		List<SObject> cppDeleteList = new List<SObject>();
		List<Database.DeleteResult> resultCPEDelete = new List<Database.DeleteResult>();
		List<Database.UpsertResult> resultCPEUpsert = new List<Database.UpsertResult>();
		List<Database.DeleteResult> resultCPPDelete = new List<Database.DeleteResult>();
		List<Database.UpsertResult> resultCPPUpsert = new List<Database.UpsertResult>();
		List<Database.DeleteResult> resultCPADelete = new List<Database.DeleteResult>();
		List<Database.SaveResult> resultCPAInsert = new List<Database.SaveResult>();
		List<ContactPointAddress> existingCPAddresses = new List<ContactPointAddress>();

		//fetch the emails list
		cpeDeleteList = cpEmailHelper.getCPEmailsDeleteList();
		cpeUpsertList = cpEmailHelper.getCPEmailsUpsertList();
		//fetch the phones list
		cppDeleteList = cpPhoneHelper.getCPPhonesDeleteList();
		cppUpsertList = cpPhoneHelper.getCPPhonesUpsertList();

		try {
			if (cpeDeleteList.size() > 0) {
				resultCPEDelete = ApplicationDatabase.getInstance().dmlDelete(cpeDeleteList, false);
			}
			if (cpeUpsertList.size() > 0) {
				resultCPEUpsert = ApplicationDatabase.getInstance().dmlUpsert(cpeUpsertList, ContactPointEmail.Id, false);
			}
			if (cppDeleteList.size() > 0) {
				resultCPPDelete = ApplicationDatabase.getInstance().dmlDelete(cppDeleteList, false);
			}
			if (cppUpsertList.size() > 0) {
				resultCPPUpsert = ApplicationDatabase.getInstance().dmlUpsert(cppUpsertList, ContactPointPhone.Id, false);
			}

			if (!contactIds.isEmpty()) {
				existingCPAddresses = ContactPointAddressSelector.newInstance().selectByContactWithOtherOrMailingAddressType(contactIds);
			}

			if (existingCPAddresses.size() > 0) {
				resultCPADelete = ApplicationDatabase.getInstance().dmlDelete(existingCPAddresses);
			}
			if (cpAddressToInsert.size() > 0) {
				resultCPAInsert = ApplicationDatabase.getInstance().dmlInsert(cpAddressToInsert);
			}


			//throw exception if there are any failures in the results
			logSaveAndDeleteResultsException(null,resultCPEDelete);
			logSaveAndDeleteResultsException(null,resultCPPDelete);
			logSaveAndDeleteResultsException(resultCPAInsert,null);

			logUpsertResultsException(resultCPEUpsert);
			logUpsertResultsException(resultCPPUpsert);



		} catch (Exception e) {
			throw new CustomerDataSyncException(
				'DML failed for CP records with exception>>' +
				e +
				'\n' +
				'Records of CPEmailsDelete' +
				cpeDeleteList +
				'\n' +
				'Results of DML resultCPEDelete' +
				resultCPEDelete +
				'\n' +
				'Records of cpeUpsertList' +
				cpeUpsertList +
				'\n' +
				'Results of DML resultCPEUpsert' +
				resultCPEUpsert +
				'\n' +
				'Records of cppDeleteList' +
				cppDeleteList +
				'\n' +
				'Results of DML resultCPPDelete' +
				resultCPPDelete +
				'\n' +
				'Records of cppUpsertList' +
				cppUpsertList +
				'\n'+
				'Results of DML cppUpsertList' +
				resultCPPUpsert +
				'\n' +
				'Records of existingCPAddresses' +
				existingCPAddresses +
				'\n'+
				'Results of DML resultCPADelete' +
				resultCPADelete +
				'\n' +
				'Records of cpAddressToInsert' +
				cpAddressToInsert +
				'\n'+
				'Results of DML resultCPAInsert' +
				resultCPAInsert
			);
		}
	}

	//filter and parse
	private void filterWithParsing(List<CustomerDataSync__e> events) {
		//collect all apcn's from the event list

		for (CustomerDataSync__e e : events) {
			try {
				//process
				genContactPointWrapper(e);
				filterEvents(e);
				genCustSet(e);
			} catch (Exception ex) {
				System.debug('>>>>>>>>>>>>>>>>>>>> Exception: ' + ex + '>>>>>>>>>>>>>>>>>>>> Filtered Events:' + filteredEvents);
				UTIL_LoggingService.logHandledException(
					ex,
					UserInfo.getOrganizationId(),
					'CustomerDataSyncEventHandler',
					CustomerDataSyncEventHandler.class.getName(),
					'filterWithParsing',
					'CustomerDataSyncEventHandler',
					LoggingLevel.ERROR
				);
			}
		}
	}

	//method to get Emails from Email Wrapper
	private Set<String> getEmails(List<Object> emails) {
		Set<String> emailsSet = new Set<String>();
		for (Object o : emails) {
			String email = ((CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper) o).emailAddress;
			if (!emailsSet.contains(email)) {
				emailsSet.add(email);
			}
		}
		return emailsSet;
	}

	//method to get phones from Phones Wrapper
	private Set<String> getPhones(List<Object> phones) {
		Set<String> phonesSet = new Set<String>();
		for (Object o : phones) {
			String phone = ((CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper) o).phone;
			if (!phonesSet.contains(phone)) {
				phonesSet.add(phone);
			}
		}
		return phonesSet;
	}

	//generate contact point wrappers
	private void genContactPointWrapper(CustomerDataSync__e e) {
		try {
			apcnVsEmails.put(e.apcn__c, cpEmailHelper.deserialisePayload(e));
			apcnVsPhones.put(e.apcn__c, cpPhoneHelper.deserialisePayload(e));
			apcnVsAddresses.put(e.apcn__c, cpAddressHelper.deserialisePayload(e));
		} catch (Exception ex) {
			throw new CustomerDataSyncException(
				'This event ' +
				e +
				' has been discarded as it has parsing issues for this apcn ' +
				e.apcn__c,
				ex
			);
		}
	}

	//method to create the set with APCN and SFID for querying Account later
	private void genCustSet(CustomerDataSync__e e) {
		apcns.add(e.apcn__c);
		if (String.isNotEmpty(e.salesforceRecordID__c)) {
			sfIds.add(e.salesforceRecordID__c);
		}
	}

	//this method filters evenst  based on the intergration mod timesamp
	private void filterEvents(CustomerDataSync__e e) {
		if (filteredEvents.containsKey(e.apcn__c)) {
			if (e.integrationServiceModDate__c > (filteredEvents.get(e.apcn__c)).integrationServiceModDate__c) {
				filteredEvents.put(e.apcn__c, e);
			} else {
				throw new CustomerDataSyncException('This event ' + e + ' has been discarded as the integration timestamp is older for the apcn '+e.apcn__c);
			}
		} else {
			filteredEvents.put(e.apcn__c, e);
		}

		System.debug('filteredEvents are' + filteredEvents);
	}

	//this method queries Account and generates Customer Refernce Map
	private Map<String, Map<String, Object>> genCustomerRefMap(Set<String> apcns, Set<ID> ids) {
		Map<String, Map<String, Object>> custMap = new Map<String, Map<String, Object>>{
			APCN => new Map<String, Datetime>(),
			SFID => new Map<String, Account>()
		};

		Map<String, Object> searchParams = new Map<String, Object>{ 'apcn' => apcns, 'accId' => ids, 'isPersonAccount' => true };
		String searchConditions = '(1 OR 2) AND 3';
		Schema.SObjectField orderByField = Account.Integration_Service_Mod_Date__c;

		//note that this is limited to 200 as the platform event batch size is 200
		for (
			Account a : AccountsSelector.newInstance(200, getFieldOverridesCustomer())
				.selectByAPCNAndIdAndPersonAccount(searchParams, searchConditions, orderByField)
		) {
			//pick only the latest as its ordered by Integration_Service_Mod_Date__c
			if (!custMap.get(APCN).containsKey(a.apcn__pc)) {
				if (apcns.contains(a.apcn__pc) && a.Integration_Service_Mod_Date__c != null) {
					custMap.get(APCN).put(a.apcn__pc, a.Integration_Service_Mod_Date__c);
				} else {
					System.debug('****THIS APCN IS NOT IN THE Event OR Integration_Service_Mod_Date__c IS NULL****' + a.apcn__pc);
				}
			} else {
				System.debug('****DUPLICATES FOUND FOR THIS APCN IN SALESFORCE****' + a.apcn__pc);
			}
			if (ids.contains(a.Id)) {
				custMap.get(SFID).put(a.Id, a);
			}
		}
		return custMap;
	}

	//generate a map of APCN and ContactPointEmail record
	private Map<String, List<ContactPointEmail>> queryContactPointEmails(Set<ID> parentIds, Set<String> emails) {
		Map<String, List<ContactPointEmail>> queryMap = new Map<String, List<ContactPointEmail>>();

		for (
			ContactPointEmail cpe : ContactPointEmailSelector.newInstance()
				.selectByParentId(parentIds, new Set<Object>{ ContactPointEmailSelector.Options.WITH_CONTACT })
		) {
			if (!queryMap.containsKey(cpe.Contact__r.APCN__c)) {
				List<ContactPointEmail> l = new List<ContactPointEmail>();
				l.add(cpe);
				queryMap.put(cpe.Contact__r.APCN__c, l);
			} else {
				queryMap.get(cpe.Contact__r.APCN__c).add(cpe);
			}
		}
		return queryMap;
	}

	//query the contact point phones passing parent id
	private Map<String, List<ContactPointPhone>> queryContactPointPhones(Set<ID> parentIds) {
		Map<String, List<ContactPointPhone>> queryMap = new Map<String, List<ContactPointPhone>>();

		for (
			ContactPointPhone cpp : ContactPointPhoneSelector.newInstance()
				.selectByParentId(parentIds, new Set<Object>{ ContactPointPhoneSelector.Options.WITH_CONTACT })
		) {
			if (!queryMap.containsKey(cpp.Contact__r.APCN__c)) {
				List<ContactPointPhone> l = new List<ContactPointPhone>();
				l.add(cpp);
				queryMap.put(cpp.Contact__r.APCN__c, l);
			} else {
				queryMap.get(cpp.Contact__r.APCN__c).add(cpp);
			}
		}

		return queryMap;
	}
	//which fields need to be queried in customer
	private Set<SObjectField> getFieldOverridesCustomer() {
		return new Set<SObjectField>{ Account.apcn__pc, Account.PersonContactId, Account.Id, Account.Integration_Service_Mod_Date__c };
	}

	//log delete result
	private void logSaveAndDeleteResultsException(List<Database.SaveResult> saveResult, List<Database.DeleteResult> deleteResults) {
		UTIL_LoggingService.logDmlResults(
			saveResult,
			deleteResults,
			null,
			'CustomerDataSyncEventHandler',
			CustomerDataSyncEventHandler.class.getName(),
			'performContactPointDMLs',
			null,
			LoggingLevel.ERROR
		);
	}

	//log exception for upsert result failures as the upsert result 
	private void logUpsertResultsException(List<Database.UpsertResult> upsertResults) {
		UTIL_LoggingService.createExceptionForUpsertResults(
			upsertResults,
			null,
			'CustomerDataSyncEventHandler',
			CustomerDataSyncEventHandler.class.getName(),
			'performContactPointDMLs',
			null,
			LoggingLevel.ERROR
		);
	}
}