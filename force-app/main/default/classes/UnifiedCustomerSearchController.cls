/**
 * @author Marcel HK
 * @date 2024-06-03
 * @description - Controller for the Lightning Web Component `UnifiedCustomerSearch`
 * @changelog
 * 2024-06-03 - Marcel HK - Created
 * 2024-07-02 - Marcel HK - Corrected form validation logic to align with associated LWC (CSLU-438)
 * 2024-07-08 - Marcel HK - Update too many results warning message
 * 2024-07-17 - Marcel HK - Add customer type parameters (CSLU-446) and refactor data transform into separate function
 * 2024-07-22 - Marcel HK - Added mailing address filters (CSLU-1072)
 * 2024-07-23 - Marcel HK - Removed 'Country' mailing address filters (CSLU-1072)
 * 2024-07-23 - Marcel HK - Added accountId and abn/acn properties (CSLU-447)
 * 2024-07-26 - Marcel HK - Add customer type (CSLU-449)
 * 2024-07-26 - Marcel HK - Add mailing address and related case count (CSLU-439)
 * 2024-08-05 - Marcel HK - Refactor to `CustomerSearchFormController` to `UnifiedCustomerSearchController`
 * 2024-08-05 - Marcel HK - Update error messaging (CSLU-444)
 */
public with sharing class UnifiedCustomerSearchController {
	// Query configuration constants
	@TestVisible
	private static final Integer MAX_RESULTS = 20;
	@TestVisible
	private static final Set<Object> CONTACT_SELECTOR_OPTIONS = new Set<Object>{
		ContactsSelector.Options.WITH_ACCOUNT,
		ContactsSelector.Options.WITH_RELATED_CASES
	};
	@TestVisible
	private static final Map<SObjectType, Set<SObjectField>> SELECTOR_FIELDS = new Map<SObjectType, Set<SObjectField>>{
		Contact.SObjectType => new Set<SObjectField>{
			Contact.Id,
			Contact.Name,
			Contact.FirstName,
			Contact.LastName,
			Contact.Preferred_Name__c,
			Contact.Email,
			Contact.VerifiedEmail__c,
			Contact.Phone,
			Contact.MobilePhone,
			Contact.VerifiedMobile__c,
			Contact.MailingStreet,
			Contact.MailingStreet2__c,
			Contact.MailingCity,
			Contact.MailingState,
			Contact.MailingPostalCode,
			Contact.MailingCountry
		},
		Account.SObjectType => new Set<SObjectField>{
			Account.Name,
			Account.IsPersonAccount,
			Account.Role_Type_Roll_Up__c,
			Account.ServiceSLA__c
		},
		Case.SObjectType => new Set<SObjectField>{ Case.Id, Case.IsClosed }
	};

	// Error and warning messages
	@TestVisible
	private static final String NOT_ENOUGH_PARAMS_ERROR_MSG = 'More information needed to search';
	@TestVisible
	private static final String INVALID_ABN_ACN_ERROR_MSG = 'Invalid ABN/ACN format';
	@TestVisible
	private static final String TOO_MANY_RESULTS_WARNING_MSG =
		'Your query returned more than ' +
		MAX_RESULTS +
		' results. We recommend refining your search criteria.';

	// Customer type segments
	private static final String CUSTOMER_TYPE_CONSUMER = 'Consumer';
	private static final String CUSTOMER_TYPE_SMB = 'SMB';
	private static final String CUSTOMER_TYPE_CONSUMER_SMB = 'Consumer SMB';
	private static final String CUSTOMER_TYPE_ENTERPRISE = 'Enterprise';

	/**
	 * @description Search method to be invoked by the Lightning Web Component. This method will perform basic
	 * validation of the search parameters, run the query and return the results.
	 *
	 * @param req - The request which contains search parameters
	 * @return Results object which contains a list of Contacts which matched the criteria
	 */
	@AuraEnabled(cacheable=true)
	public static SearchResponse search(SearchRequest req) {
		try {
			// Validate the search request, which will throw `SearchException` on any errors
			validateSearchRequest(req);

			ContactsSelector.CustomerSearchParameters params = transformSearchRequest(
				req
			);

			ContactsSelector cs = ContactsSelector.newInstance(
				MAX_RESULTS + 1,
				SELECTOR_FIELDS
			);

			Map<Id, Contact> contactsMap = cs.selectByCustomerSearchParams(
				params,
				CONTACT_SELECTOR_OPTIONS
			);
			SearchResponse res = createResponse(contactsMap.values());

			return res;
		} catch (Exception e) {
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			if (Test.isRunningTest()) {
				// Allow Apex to access the actual exception message instead
				// the default "Script-thrown exception" message.
				ex.setMessage(e.getMessage());
			}
			throw ex;
		}
	}

	/**
	 * @description Validates the search request parameters to ensure that invalid data is not used in the query.
	 * If any validation issue is detected, it will throw a `SearchException` with the reason. Note that single
	 * quotes will be escapted when passed into the selector class, so no need to sanitize them here.
	 *
	 * NOTE: These validations may also be performed on client-side. When modifying these rules, be sure to update
	 * related LWC to reflect the same to avoid a bad user experience.
	 *
	 * @param req - The search request parameters to validate.
	 */
	@TestVisible
	private static void validateSearchRequest(SearchRequest req) {
		// At least one of these fields must be provided
		if (
			req == null ||
			(String.isBlank(req.firstName) &&
			String.isBlank(req.lastName) &&
			String.isBlank(req.emailAddress) &&
			String.isBlank(req.phoneNumber))
		) {
			throw new SearchException(NOT_ENOUGH_PARAMS_ERROR_MSG);
		}

		// Check at least First AND Last Name, or Phone, or Email is entered
		Boolean hasFirstAndLast =
			String.isNotBlank(req.firstName) && String.isNotBlank(req.lastName);
		Boolean hasPhoneOrEmail =
			String.isNotBlank(req.phoneNumber) || String.isNotBlank(req.emailAddress);
		if (!(hasFirstAndLast || hasPhoneOrEmail)) {
			throw new SearchException(NOT_ENOUGH_PARAMS_ERROR_MSG);
		}

		if (
			String.isNotBlank(req.abnAcn) &&
			!Pattern.matches('^(\\d{9}|\\d{11})$', req.abnAcn)
		) {
			throw new SearchException(INVALID_ABN_ACN_ERROR_MSG);
		}
	}

	/**
	 * @description Transforms the `SearchRequest` object into the `CustomerSearchParameters` object.
	 *
	 * @param req - The search request object
	 * @return CustomerSearchParameters object
	 */
	@TestVisible
	private static ContactsSelector.CustomerSearchParameters transformSearchRequest(
		SearchRequest req
	) {
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();

		params.firstName = req.firstName;
		params.lastName = req.lastName;
		params.phoneNumber = req.phoneNumber;
		params.emailAddress = req.emailAddress;
		if (req.customerType != null) {
			params.customerType = ContactsSelector.CustomerSearchCustomerType.valueOf(
				req.customerType
			);
		}
		params.addressStreet1 = req.addressStreet1;
		params.addressStreet2 = req.addressStreet2;
		params.addressCity = req.addressCity;
		params.addressState = req.addressState;
		params.addressPostalCode = req.addressPostalCode;
		params.accountId = req.accountId;
		params.abnAcn = req.abnAcn;

		return params;
	}

	/**
	 * @description Identify the customer type based on the Account fields.
	 * This is currently used to display icons in the Customer Search Form Results.
	 *
	 * @param acc - Account object
	 * @return Customer type
	 */
	@TestVisible
	private static String getCustomerType(Account acc) {
		if (acc.IsPersonAccount == true) {
			return CUSTOMER_TYPE_CONSUMER;
		}

		if (acc.Role_Type_Roll_Up__c == 'Customer') {
			if (acc.ServiceSLA__c == 'Enterprise') {
				return CUSTOMER_TYPE_ENTERPRISE;
			} else {
				return CUSTOMER_TYPE_SMB;
			}
		}

		// Default type for everything else
		return CUSTOMER_TYPE_CONSUMER_SMB;
	}

	/**
	 * @description Processes a Map of Contact objects into the `SearchResponse` object.
	 * If the number of Contacts exceeds the MAX_RESULTS value, then a warning wil be appended to the response.
	 *
	 * @param contactsMap - Map of Contact objects
	 * @return SearchResponse object
	 */
	@TestVisible
	private static SearchResponse createResponse(List<Contact> contactsList) {
		// Create search response object from the list of Contacts
		SearchResponse res = new SearchResponse();

		// If no Contact objects, return empty response
		if (contactsList == null || contactsList.isEmpty()) {
			return res;
		}

		// Add warning if the number of Contacts exceeds the pre-defined MAX_RESULTS
		if (contactsList.size() > MAX_RESULTS) {
			res.warningMessage = TOO_MANY_RESULTS_WARNING_MSG;
		}

		// Add each Contact object up until the MAX_RESULTS limit reached
		for (Integer i = 0; i < (Math.min(contactsList.size(), MAX_RESULTS)); i++) {
			res.searchResults.add(new SearchResult(contactsList.get(i)));
		}

		return res;
	}

	/**
	 * @description A wrapper class used to pass parameters for the search query.
	 */
	public class SearchRequest {
		@AuraEnabled
		public String firstName { get; set; }

		@AuraEnabled
		public String lastName { get; set; }

		@AuraEnabled
		public String emailAddress { get; set; }

		@AuraEnabled
		public String phoneNumber { get; set; }

		@AuraEnabled
		public String customerType { get; set; }

		@AuraEnabled
		public String addressStreet1 { get; set; }

		@AuraEnabled
		public String addressStreet2 { get; set; }

		@AuraEnabled
		public String addressCity { get; set; }

		@AuraEnabled
		public String addressState { get; set; }

		@AuraEnabled
		public String addressPostalCode { get; set; }

		@AuraEnabled
		public Id accountId { get; set; }

		@AuraEnabled
		public String abnAcn { get; set; }
	}

	/**
	 * @description A wrapper class used to return search results.
	 */
	public class SearchResponse {
		@AuraEnabled
		public List<SearchResult> searchResults;

		@AuraEnabled
		public String warningMessage;

		public SearchResponse() {
			this.searchResults = new List<SearchResult>();
		}
	}

	/**
	 * @description An object to return individual search results to the Lightning Web Component.
	 */
	public class SearchResult {
		@AuraEnabled
		public String contactId;

		@AuraEnabled
		public String name;

		@AuraEnabled
		public String firstName;

		@AuraEnabled
		public String lastName;

		@AuraEnabled
		public String preferredName;

		@AuraEnabled
		public String emailAddress;

		@AuraEnabled
		public String verifiedEmailAddress;

		@AuraEnabled
		public String phone;

		@AuraEnabled
		public String mobilePhone;

		@AuraEnabled
		public String verifiedMobilePhone;

		@AuraEnabled
		public String customerType;

		@AuraEnabled
		public String mailingStreet;

		@AuraEnabled
		public String mailingStreet2;

		@AuraEnabled
		public String mailingCity;

		@AuraEnabled
		public String mailingState;

		@AuraEnabled
		public String mailingPostalCode;

		@AuraEnabled
		public String mailingCountry;

		@AuraEnabled
		public Integer openCasesCount;

		@AuraEnabled
		public Integer totalCasesCount;

		@AuraEnabled
		public String organisationName;

		/**
		 * @description Constructor used to initialize from a Contact object.
		 *
		 * @param con - The Contact object to populate values from.
		 */
		public SearchResult(Contact con) {
			this.contactId = con.Id;
			// Names
			this.name = con.Name;
			this.firstName = con.FirstName;
			this.lastName = con.LastName;
			this.preferredName = con.Preferred_Name__c;
			// Email addresses
			this.emailAddress = con.Email;
			this.verifiedEmailAddress = con.VerifiedEmail__c;
			// Phone numbers
			this.phone = con.Phone;
			this.mobilePhone = con.MobilePhone;
			this.verifiedMobilePhone = con.VerifiedMobile__c;
			// Mailing address
			this.mailingStreet = con.MailingStreet;
			this.mailingStreet2 = con.MailingStreet2__c;
			this.mailingCity = con.MailingCity;
			this.mailingState = con.MailingState;
			this.mailingPostalCode = con.MailingPostalCode;
			this.mailingCountry = con.MailingCountry;
			// Account info
			if (con.Account != null) {
				this.customerType = getCustomerType(con.Account);
				if (this.customerType != CUSTOMER_TYPE_CONSUMER) {
					this.organisationName = con.Account.Name;
				}
			}
			// Related cases count
			this.openCasesCount = 0;
			this.totalCasesCount = 0;
			// Note: Manually aggregating as cannot use aggregate functions in SOQL sub-query
			if (con.Cases != null && !con.Cases.isEmpty()) {
				for (Case c : con.Cases) {
					this.totalCasesCount++;
					if (c.IsClosed == false) {
						this.openCasesCount++;
					}
				}
			}
		}
	}

	/**
	 * @description An exception thrown when there was an error performing the search.
	 */
	public class SearchException extends Exception {
	}
}