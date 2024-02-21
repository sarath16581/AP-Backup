/**
 * @description       : Helper Class to perform Customer related logic for Connected Customer
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 08-15-2022
 * @last modified by  : Sreenish Krishnan
 * 
 History:
--------------------------------------------------
2023-10-02    Boris Bachovski    Refactor to use IsInactiveCustomer__c instead of is_Inactive_Customer__c
 **/
public inherited sharing class CustomerDataSyncEventCustomerHelper {
	private static final String APCN = 'APCN';
	private static final String SFID = 'SFID';
	private static final Integer NO_LIMIT = 0;
	private ID personAccId;
	private Map<String, List<Account>> custMap = new Map<String, List<Account>>{ APCN => new List<Account>(), SFID => new List<Account>() };
	private Map<ID, Account> custSuccessMap = new Map<ID, Account>();

	/**
	* @description : This method is the core to upsert customer information from platform event. It takes events and returns a JSON Upsert Result 
                     with sucess and errors and successids and personccontactid
	* @author Sreenish Krishnan | 06-22-2022 
	* @param events 
	* @param refMaps 
	* @return Map<String, CustomerUpsertResult> 
	**/
	public Map<String, CustomerUpsertResult> upsertCustomerData(
		List<CustomerDataSync__e> events,
		Map<String, Map<String, Object>> refMaps
	) {
		personAccId = getRecordTypeID(Constants.RECORDTYPE_NAME_ACCOUNT_PERSONACCOUNT);

		//create map of APCN and Salesforce ID's for Query
		Map<String, Object> apcnMap;
		Map<String, Object> recIdMap;
		List<Database.UpsertResult> resultUpsertAPCN = new List<Database.UpsertResult>();
		List<Database.UpsertResult> resultUpsertSFID = new List<Database.UpsertResult>();
		List<CustomerUpsertResult> resAPCNmap = new List<CustomerUpsertResult>();
		String apcnNumbers = ''; 

		try {
			if (!refMaps.isEmpty()) {
				for (String s : refMaps.keySet()) {
					if (s.equalsIgnoreCase(APCN)) {
						apcnMap = new Map<String, Object>(refMaps.get(APCN));
					}
					if (s.equalsIgnoreCase(SFID)) {
						recIdMap = new Map<String, Object>(refMaps.get(SFID));
					}
				}

				//these are the records to upsert
				List<SObject> accupsertAPCNList = new List<SObject>();
				List<SObject> accupsertSFIDList = new List<SObject>();

				//customer logic
				apcnNumbers = customerLogic(apcnMap, recIdMap, events);
				accupsertAPCNList = (List<SObject>) custMap.get(APCN);
				accupsertSFIDList = (List<SObject>) custMap.get(SFID);

				if (accupsertAPCNList.size() > 0) {
					resultUpsertAPCN = ApplicationDatabase.getInstance().dmlUpsert(accupsertAPCNList, Account.apcn__c);
				}
				if (accupsertSFIDList.size() > 0) {
					resultUpsertSFID = ApplicationDatabase.getInstance().dmlUpsert(accupsertSFIDList, Account.Id);
				}

				custSuccessMap = genSuccessCustomerMap(genSuccessCustIds(resultUpsertAPCN, resultUpsertSFID));

				//query customer to get the contactid and create a map of salesforce id, person contactid
				resAPCNmap = genCustomerUpsertResult(
					(List<Account>) combineListsAccount(accupsertAPCNList, accupsertSFIDList),
					(List<Database.UpsertResult>) combineListsUpsertResult(resultUpsertAPCN, resultUpsertSFID)
				);

				if(!resultUpsertAPCN.isEmpty()){
					logUpsertResultsException(resultUpsertAPCN);
				}
				if(!resultUpsertSFID.isEmpty()){
					logUpsertResultsException(resultUpsertSFID);
				}

			}
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'CustomerDataSyncEventCustomerHelper',
				CustomerDataSyncEventCustomerHelper.class.getName(),
				'parseCustomerDataPayload',
				'CustomerDataSyncEventCustomerHelper',
				LoggingLevel.ERROR, 
				apcnNumbers
			);
		}

		return genAPCNMapFromUpsertResult(resAPCNmap);
	}

	//combine get ids from two different upsert results
	private Set<ID> genSuccessCustIds(List<Database.UpsertResult> result1, List<Database.UpsertResult> result2) {
		Set<ID> result = new Set<ID>();
		result.addAll(getIDs(result1));
		result.addAll(getIDs(result2));
		return result;
	}

	//helper to genSuccessCustIds to loop through the upsert result
	private Set<ID> getIDs(List<Database.UpsertResult> input) {
		Set<ID> result = new Set<ID>();
		if (!input.isEmpty()) {
			for (Database.UpsertResult r : input) {
				if (r.isSuccess()) {
					result.add(r.getId());
				}
			}
		}
		return result;
	}

	//upsert result wrapper JSON
	public class CustomerUpsertResult {
		public List<Database.Error> errors { get; set; }
		public ID recId { get; set; }
		public ID personContactId { get; set; }
		String apcn { get; set; }
		Boolean isCreated { get; set; }
		public Boolean isSuccess { get; set; }
	}

	//logic to check for different scenarios for customer
	private String customerLogic(Map<String, Object> apcnMap, Map<String, Object> recIdMap, List<CustomerDataSync__e> events) {
		String apcnNumbers = '';
		if (!events.isEmpty()) {
			for (CustomerDataSync__e e : events) {
				apcnNumbers += (String.isBlank(e.apcn__c) == false ? e.apcn__c : '') + ',';
				//if the salsforce record id is null then its a new consumer record
				if (String.isEmpty(e.salesforceRecordID__c)) {
					custMap.get(APCN).add(genNewCustomer(e));
				} else {
					checkExistingCustomer(apcnMap, recIdMap, e);
				}
			}
		}
		return apcnNumbers;
	}

	//create a map of apcn and the CustmerUpsertResult
	private Map<String, CustomerUpsertResult> genAPCNMapFromUpsertResult(List<CustomerUpsertResult> res) {
		Map<String, CustomerUpsertResult> apcnMap = new Map<String, CustomerUpsertResult>();

			for (CustomerUpsertResult r : res) {
				if (!apcnMap.containsKey(r.apcn)) {
					apcnMap.put(r.apcn, r);
				} else {
					System.debug('***THERE HAS BEEN DUPLICATE APCN ENTRY***** ' + apcnMap.get(r.apcn));
				}
			}
		return apcnMap;
	}

	//combine Accounts List used in upsert customer data logic
	private List<Account> combineListsAccount(List<Account> list1, List<Account> list2) {
		List<Account> combinedList = new List<Account>();
		combinedList.addAll(list1);
		combinedList.addAll(list2);
		return combinedList;
	}

	//combine Upsert Resullts used in the upsert customer logic
	private List<Database.UpsertResult> combineListsUpsertResult(List<Database.UpsertResult> list1, List<Database.UpsertResult> list2) {
		List<Database.UpsertResult> combinedList = new List<Database.UpsertResult>();
		combinedList.addAll(list1);
		combinedList.addAll(list2);
		return combinedList;
	}

	//query Customer after upsert to fetch the person contact ids
	private Map<ID, Account> genSuccessCustomerMap(Set<ID> accIds) {
		return AccountsSelector.newInstance(NO_LIMIT, getFieldOverridesUpsertCustomer()).selectById(accIds);
	}

	//map the person account fields
	private Account genNewCustomer(CustomerDataSync__e e) {
		Account acc = mapPersonAccountFields(e);
		acc.RecordTypeId = personAccId;
		return acc;
	}

	//logic for existing customer
	private void checkExistingCustomer(Map<String, Object> apcnMap, Map<String, Object> recIdMap, CustomerDataSync__e e) {
		List<Account> accList = new List<Account>();
		//if the salsforce record id is not null,then retrieve the person account
		Account acc = genCustomerWithAPCNKey(apcnMap, e);
		if (apcnMap.containsKey(e.apcn__c) && acc != null) {
			custMap.get(APCN).add(acc);
		} else {
			//if  salesforce id is not null, and no apcn is found, then search for the salesforce id
			if (recIdMap.containsKey(e.salesforceRecordID__c)) {
				custMap.get(SFID).add(genCustomerWithRecIdKey(recIdMap, e));
			} else {
				// Invalid SF id, need to create new Account by APCN
				custMap.get(APCN).add(mapPersonAccountFields(e));
			}
		}
	}

	//helper method to generate Customer List using the apcn Map and the event
	private Account genCustomerWithAPCNKey(Map<String, Object> apcnMap, CustomerDataSync__e e) {
		Account acc = null;
		if (apcnMap.keySet().size() > 0) {
			if (e.integrationServiceModDate__c >= (Datetime) apcnMap.get(e.apcn__c)) {
				acc = mapPersonAccountFields(e);
			} else {
				System.debug(
					LoggingLevel.ERROR,
					'****Discard the APCN ' +
					e.apcn__c +
					' as the record is stale. Timestamp of event >>' +
					e.integrationServiceModDate__c +
					' and Timestamp of Account Record found >>' +
					apcnMap.get(e.apcn__c)
				);
			}
		}
		return acc;
	}

	//helper logic to upsert customer for an existing record
	private Account genCustomerWithRecIdKey(Map<String, Object> recIdMap, CustomerDataSync__e e) {
		Account acc = (Account) recIdMap.get(e.salesforceRecordID__c);
		acc.apcn__pc = e.apcn__c;
		acc.apcn__c = e.apcn__c;

		return acc;
	}

	//this method will generate JSON with what has been successfully upserted vs what has been errors
	private List<CustomerUpsertResult> genCustomerUpsertResult(List<Account> input, List<Database.UpsertResult> result) {
		List<CustomerUpsertResult> output = new List<CustomerUpsertResult>();
		for (Integer index = 0, size = result.size(); index < size; index++) {
			CustomerUpsertResult r = new CustomerUpsertResult();
			r.errors = result[index].getErrors();
			r.apcn = input[index].apcn__pc;
			r.isCreated = result[index].isCreated();
			r.isSuccess = result[index].isSuccess();
			ID sfID = result[index].getId();
			r.recId = sfID;
			if (custSuccessMap.containsKey(sfID)) {
				r.personContactId = custSuccessMap.get(sfID).PersonContactId;
			}

			output.add(r);
		}
		return output;
	}

	//which fields need to be queried in customer after upsert
	private Set<SObjectField> getFieldOverridesUpsertCustomer() {
		return new Set<SObjectField>{ Account.Id, Account.PersonContactId, Account.apcn__pc };
	}

	//get the recordtypeId. does this need to be moved to the account util class?
	private ID getRecordTypeID(String developerName) {
		return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeID();
	}

	//log exception for upsert result failures as the upsert result 
	private void logUpsertResultsException(List<Database.UpsertResult> upsertResults) {
		UTIL_LoggingService.createExceptionForUpsertResults(
			upsertResults,
			null,
			'CustomerDataSyncEventCustomerHelper',
			CustomerDataSyncEventCustomerHelper.class.getName(),
			'upsertCustomerData',
			null,
			LoggingLevel.ERROR
		);
	}

	//map the fields from Person Account
	private Account mapPersonAccountFields(CustomerDataSync__e e) {
		Account acc = new Account();
		if (e.archivedDateTime__c != null) {
			acc.ArchivedDateTime__pc = e.archivedDateTime__c;
			return acc;
		}

		acc.APCN__pc = e.apcn__c;
		acc.APCN__c = e.apcn__c;
		acc.OID_ID__pc = e.OIDID__c;
		acc.FirstName = e.legalFirstName__c;
		acc.LastName = e.legalLastName__c;
		acc.LegalLastName__pc = e.legalLastName__c;
		acc.Preferred_Name__pc = e.preferredName__c;

		// Salesforce can accept dates between Jan 1, 1700 and December 31, 4000.
		acc.PersonBirthdate = e.birthDate__c != null && e.birthDate__c.year() > 1700 ? e.birthDate__c : null;

		acc.LevelOfAssurance__pc = e.loa__c;
		acc.Legal_Marketing_Opt_In__pc = e.legalMarketingOptIn__c;
		acc.Winning_Master_Record__pc = e.winningMasterAPCN__c;
		acc.Status__pc = e.isInactiveCustomer__c ? 'Inactive' : 'Active';
		acc.Integration_Service_Mod_Date__c = e.integrationServiceModDate__c;
		acc.ClosedDateTime__pc = e.closedDateTime__c;
		acc.ClosedReason__pc = e.closedReason__c;
		acc.ArchivedDateTime__pc = e.archivedDateTime__c;
		return acc;
	}
}