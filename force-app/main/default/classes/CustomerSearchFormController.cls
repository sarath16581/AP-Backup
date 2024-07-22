/**
 * @author Marcel HK
 * @date 2024-06-03
 * @description - Controller for the Lightning Web Component `CustomerSearchForm`
 * @changelog
 * 2024-06-03 - Marcel HK - Created
 * 2024-07-02 - Marcel HK - Corrected form validation logic to align with associated LWC (CSLU-438)
 * 2024-07-08 - Marcel HK - Update too many results warning message
 * 2024-07-17 - Marcel HK - Add customer type parameters (CSLU-446) and refactor data transform into separate function
 * 2024-07-22 - Marcel HK - Added mailing address filters (CSLU-1072)
 */
public with sharing class CustomerSearchFormController {
	// Query configuration constants
	@TestVisible
	private static final Integer MAX_RESULTS = 20;
	@TestVisible
	private static final Set<Object> CONTACT_SELECTOR_OPTIONS = new Set<Object>{};
	@TestVisible
	private static final Set<SObjectField> CONTACT_FIELDS = new Set<SObjectField>{
		Contact.Id,
		Contact.Name,
		Contact.FirstName,
		Contact.LastName,
		Contact.Preferred_Name__c,
		Contact.Email,
		Contact.VerifiedEmail__c,
		Contact.Phone,
		Contact.MobilePhone,
		Contact.VerifiedMobile__c
	};

	// Error and warning messages
	@TestVisible
	private static final String NOT_ENOUGH_PARAMS_ERROR_MSG = 'Please enter at least First and Last Name, or Phone, or Email.';
	@TestVisible
	private static final String TOO_MANY_RESULTS_WARNING_MSG =
		'Your query returned more than ' +
		MAX_RESULTS +
		' results. We recommend refining your search criteria.';

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
				CONTACT_FIELDS
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
		params.addressCountry = req.addressCountry;

		return params;
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
		public String addressCountry { get; set; }
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

		/**
		 * @description Constructor used to initialize from a Contact object.
		 *
		 * @param con - The Contact object to populate values from.
		 */
		public SearchResult(Contact con) {
			this.contactId = con.Id;
			this.name = con.Name;
			this.firstName = con.FirstName;
			this.lastName = con.LastName;
			this.preferredName = con.Preferred_Name__c;
			this.emailAddress = con.Email;
			this.verifiedEmailAddress = con.VerifiedEmail__c;
			this.phone = con.Phone;
			this.mobilePhone = con.MobilePhone;
			this.verifiedMobilePhone = con.VerifiedMobile__c;
		}
	}

	/**
	 * @description An exception thrown when there was an error performing the search.
	 */
	public class SearchException extends Exception {
	}
}
