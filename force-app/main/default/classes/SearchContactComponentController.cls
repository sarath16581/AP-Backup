/**************************************************
Type:     Controller for SearchContactComponent component (My Customer search) 
Purpose:  Used by SearchContactComponent VF Component to search for Contacts/Person Accounts using the custom search criteria. 
History:
--------------------------------------------------
Sept-2014   Created Bluewolf SSSW 
22.10.2014  Carmelo Andronaco - Added "OtherPhone" to SOQL / SOSL Search fields. 
24.06.2015  Mohamed.Athek@bluewolf.com Added code comments
**************************************************//**
 * @description Controller for SearchContactComponent to search contacts based on search parameters
 * @author nandan.narasappa@auspost.com.au
 * @date 2015-09-09
 * @changelog
 * 2015-09-17  christopher.henschke@auspost.com.au   Updated SOQL to use Name instead of Firstname + Lastname for performance
 * 2015-09-24  christopher.henschke@auspost.com.au   Updated to run 2 SOQL - one for exact match on name and then one using wild cards so can sort
 *                                     final result with exact matches at the top followed by like matches.
 * 2016-10-26 - mark.townsend@coroma.com.au       Significant refactoring and removal of bloat https://en.wikipedia.org/wiki/Code_bloat#Common_causes
 * 2017-05-26 - dion.gunn@auspost.com.au        Added logic to handle duplicate DML errors with new Duplicate Checking rules.
 * 2017-07-03 - maumita.bandyopadhyay@auspost.com.au  Modified the logic of searching by customer address in MyCustomers.
 * 2017-08-10 - maumita.bandyopadhyay@auspost.com.au  Modified the logic of searching by customer address in MyCustomers.
 * 2017-08-18 - dilshan.egodawela@auspost.com.au    Method to get the minimun LOA value.
 * 2019-05-21 - ronnie.yang@sodastrategic.com.au    MW0003155 Using Database method to insert instead of DML to bypass new duplicate rules for now
 * 2019-08-27 - seth.p.heang@accenture.com        MW0003494 Added duplicate rule block message when duplicates detected for business contact under same organisation
 * 2020-07-20 - Swati.Mogadala@auspost.com.au       Add EmailNotAvailable checkbox for Contacts (REQ2065161)
 * 2021-05-10 - Madhuri.awasthi@auspost.com.au      Add a preferred name field in contact areas of Salesforce (REQ2476162)
 * 2021-09-08 - Nathan Franklin - Added a comment regarding the way search by phone number works to ensure CTI adapter is also updated if the logic in this page changes
 * 2022-10-26 - Dattaraj Deshmukh - Added a flag 'isLiveAgentUser' and 'isLiveAgent' method to identify if logged user is a LiveAgent.
 */
public with sharing class SearchContactComponentController {

	// Constants
  
	//private static final Integer ROW_LIMIT = 500;
	// 17 Sept 2015 CH Updated to 50
	public Integer ROW_LIMIT = 50;
  
	private static final String AND_SQL = ' AND ';
	private static final String OR_SQL = ' OR ';
	private static final String LIKE_SQL = 'LIKE';
  
	private static final String ANY_VAL = '- Any -';
	private static final String WHITE_SPACE = '';
	private static final String EMPTY_SPACE = ' ';
	private static final String OPEN_BRACE = '(';
	private static final String CLOSE_BRACE = ')';
	private static final String EQUALS = '=';
	private static final String COMMA_SPACE = ', ';
	private static final String QUOTE = '\'';
	private static final String QUOTE_PERCENT = '\'%';
	private static final String PERCENT_QUOTE = '%\'';
	private static final String PERCENT = '%';
	private static final String AND_BRACE = 'AND () ';
	private static final String OR_BRACE = 'OR () ';
  
	// 17 Sept 2015 CH Created
	private static final String NAME_FLD = 'Name';
	private static final String Preferred_Name = 'Preferred_Name__c';
	private static final String PERSON_ACCOUNT_FLD = 'Account.IsPersonAccount';
	private static final String APCN_FLD = 'APCN__c';
	private static final String ABN_FLD = 'Account.ABN__c';
	private static final String LEGACYID_FLD = 'BillingAccount__r.LEGACY_ID__c';
	private static final String ACCName_FLD = 'Account.Name';
	private static final String BILLACCNAME_FLD = 'BillingAccount__r.Name';
	private static final String EMAIL_FLD = 'Email';
	private static final String REV_PHONE_FLD = 'ReversePhoneFields__c';
	private static final String SOCIAL_KEY_FLD = 'SocialKeys__c';
	private static final String MAIL_STREET_FLD = 'MailingStreet';
	private static final String MAIL_STREET2_FLD = 'MailingStreet2__c';
	private static final String MAIL_CITY_FLD = 'MailingCity';
	private static final String MAIL_STATE_FLD = 'MailingState';
	private static final String MAIL_COUNTRY_FLD = 'MailingCountry';
	private static final String MAIL_ZIPCODE_FLD = 'MailingPostalCode';
	private static final String OTHER_STREET_FLD = 'OtherStreet';
	private static final String OTHER_STREET2_FLD = 'OtherStreet2__c';
	private static final String OTHER_CITY_FLD = 'OtherCity';
	private static final String OTHER_STATE_FLD = 'OtherState';
	private static final String OTHER_COUNTRY_FLD = 'OtherCountry';
	private static final String OTHER_ZIPCODE_FLD = 'OtherPostalCode';
	private static final String TRUE_VAL = 'true';
	private static final String FALSE_VAL = 'false';
	private static final String CONSUMER = 'Consumer';
	private static final String CTI_PHONE_KEY = 'ANI';
	private static final String CTI_REF_KEY = 'aId';
	private static final String STR_CONSUMER = 'Consumer';
	private static final String CONSUMER_BLOCK_DUPLICATE_RULE_DEVELOPER_NAME = 'Block_Dupe_Consumers_SSSW_Agents';
	private static final String CONTACT_BLOCK_DUPLICATE_RULE_DEVELOPER_NAME = 'Block_Match_Contact_within_same_Org';
  
	// Variables
	public String strCustomerType { get; set; }
	public String strEmail { get; set; }
	public Boolean ckbEmailNotAvailable { get; set; }
	public String strFirstName { get; set; }
	public String strLastName { get; set; }
	public String strPreferredName { get; set; }
	public String strPhone { get; set; }
	public String strAccountNumber { get; set; }
	public String strAccountName { get; set; }
	public Boolean ckbExcludePhoneFromSearch { get; set; }
	public String strSocialKeys { get; set; }
	public String strAddress { get; set; }
	//03/07/2017 Added by Maumita to resolve the address search issue in MyCustomers Starts
	public String strAddress_line { get; set; }
	public String strAddress_city { get; set; }
	public String strAddress_state { get; set; }
	public String strAddress_pc { get; set; }
	public String strAddress_country { get; set; }
	//03/07/2017 Added by Maumita to resolve the address search issue in MyCustomers Ends
	public AddressExtension proxyAddress { get; set; }
	public String referenceID { get; set; }
	public static List<sObject> duplicateRecords { get; set; }
  
	public Boolean expandAddress { get; set; }
  
	// Pagination variables
	public Integer totalPageNum { get; set; }
	public Integer totalRecordsNum { get; set; }
	public List<Integer> list_pageNo { get; set; }
	private Integer contactPageSize;
	public Integer currentPageNum { get; set; }
	public Boolean isNewSearch { get; set; }
	public Boolean showList { get; set; }
	public decimal minLOA {get;set;}
  
	@TestVisible private List<ContactListDisplay> contacts;
	public List<ContactListDisplay> contacts4Page { get; set; }
  
	private Boolean hasAccountNum;
	private Boolean hasAccountName;
	private Boolean hasContactFieldSearch;
	public  Boolean isLiveAgentUser{get; private set;}
  
	// Get Customer Type Picklist values from Account
	private static List<SelectOption> options = null;
	public List<SelectOption> getCustomerTypes() {
	  if (options == null) {
		options = new List<SelectOption>();
		options.add(new SelectOption(WHITE_SPACE, ANY_VAL));
		Map<String, Schema.SObjectField> fieldMap = Account.sObjectType.getDescribe().fields.getMap();
		// Schema describe for customer type picklist
		for (Schema.PicklistEntry pickEntry : fieldMap.get('CustomerType__c').getDescribe().getPickListValues()) {
		  options.add(new SelectOption(pickEntry.getValue(), pickEntry.getLabel()));
		}
	  }
	  return options;
	}
  
	/*
	  @constructor : initializes variable & loads contact for CTI
	 */
	public SearchContactComponentController() {
	  ckbExcludePhoneFromSearch = false;
	  setMinLOA();
	  initPage(); // initialize page
	  isLiveAgent(); // check if logged in user is a live agent.
  
	  if (ApexPages.currentPage() != null) {
		//If ANI & aId parameters are provided (by CTI) load the matching contacts.
		strPhone = ApexPages.currentPage().getParameters().get(CTI_PHONE_KEY);
		referenceID = ApexPages.currentPage().getParameters().get(CTI_REF_KEY);
		if (String.isNotBlank(strPhone)) {
		  loadContacts();
		}
	  }
	}
	public void setMinLOA(){
	  List<LOA_Settings__c> loas = LOA_Settings__c.getall().values();
	  List<decimal> b = new List<decimal>();
	  for(LOA_Settings__c a : loas){
		b.add(a.LOA_Value__c);
	  }
	  b.sort();
	  if(!b.isEmpty()){
		minLOA = b.get(0);
		System.debug('min : '+minLOA);
	  }   
	}
	/**
	  * @description     This method is invoked from constructor to initialize page variables
	  * @param       NA
	  * @return      Void
	  * @throws      NA
	  */
	public void initPage() {
	  contactPageSize = 100;
	  currentPageNum = 1;
	  isNewSearch = false;
	  showList = false;
  
	  proxyAddress = new AddressExtension();
	  expandAddress = false;
  
	  contacts = new List<ContactListDisplay>();
	  contacts4Page = new List<ContactListDisplay>();
	}
  
	/**
	  * @description     This method is invoked when expand button for address is clicked which displays additional fields for address
	  * @param       caseList - List<Case> , oldCaseMap - Map<Id,Case>
	  * @return      Void
	  * @throws      Method might throw exception which is handled by Try-Catch block
	  */
	public void expandCollapseAddress() {
	  expandAddress = !expandAddress;
	  //If collapsed, combine individual address fields into the single address field
	  if (!expandAddress) {
		String rightSide = proxyAddress.city + EMPTY_SPACE + proxyAddress.state + EMPTY_SPACE + proxyAddress.postcode;
		String leftSide = proxyAddress.line1 + EMPTY_SPACE + proxyAddress.line2;
		strAddress = leftSide.trim();
		strAddress += String.isNotBlank(rightSide.trim()) ?
			(String.isNotBlank(leftSide.trim()) ? COMMA_SPACE : WHITE_SPACE) + rightSide.trim() : WHITE_SPACE;
		strAddress = strAddress.trim();
	  }
	}
  
	/**
	  * @description     This method is invoked when Search button is clicked which displays contacts matching the search parameters
	  * @param       NA
	  * @return      Void
	  * @throws      NA
	  */
	public void searchForContact() {
	  initPage();
	  loadContacts();
	}
  
	/**
	  * @description     This method fetch contacts matching the search parameters
	  * @param       NA
	  * @return      void
	  * @throws      Method might throw exception which is handled by Try-Catch block
	  */
	private void loadContacts() {
	  // search for all contacts where there is an exact match on name
	  Map<Id, sObject> contactEqualsResultsMap = new Map<Id, sObject>(Database.query(buildSOQL(buildWhereClause(EQUALS))));
	  if (contactEqualsResultsMap.size() < ROW_LIMIT) {
		ROW_LIMIT = 50 - contactEqualsResultsMap.size();
		for (Contact con : Database.query(buildSOQL(buildWhereClause(LIKE_SQL))))
		  if ((!con.is_Inactive_Customer__c || (con.is_Inactive_Customer__c && con.Account.isCustomerPortal)) && (!contactEqualsResultsMap.containsKey(con.Id)))
			contactEqualsResultsMap.put(con.Id, con);
	  }
	  for (Sobject con: contactEqualsResultsMap.values())
		contacts.add(new ContactListDisplay((Contact) con));
  
	  makeupPaginationList(true);
	  system.debug(contacts);
	   
  
	  
	  /*
	  Map<Id, sObject> contactEqualsResultsMap = new Map<Id, sObject>();
	  Contact c = new Contact(      
		FirstName = strFirstName,
				  LastName = strLastName,
				  Phone = strPhone,
				  Email = strEmail,
				  MobilePhone = strPhone,
				  HomePhone = strPhone)
		;
	  
	  List<Contact> contactList = new List<Contact>();
	  contactList.add(c);
			System.debug('#############' + contactList);
		Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.FindDuplicates(contactList);
	  System.debug('#############' + results.size());
	  if (results.size() < ROW_LIMIT){
		ROW_LIMIT = 50 - results.size();
		for (Datacloud.FindDuplicatesResult findDupeResult : results) {
		  System.debug('1' + findDupeResult);
		  for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
			System.debug('2' + dupeResult);
			for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
			  System.debug('3' + matchResult.getSize());
			  for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
				System.debug('#############' + matchRecord.getRecord());
				Contact con = (Contact) matchRecord.getRecord();
				// if ((!con.is_Inactive_Customer__c || (con.is_Inactive_Customer__c && con.Account.isCustomerPortal)) && (!contactEqualsResultsMap.containsKey(con.Id)))
				contactEqualsResultsMap.put(con.Id, con);
			  }
			}
		  }
		}
	  }
	  
	  
	  for (Sobject con: contactEqualsResultsMap.values())
		contacts.add(new ContactListDisplay((Contact) con));
	  
	  
	  makeupPaginationList(true);
	  system.debug(contacts);
  **/
	}
  
	/**
	  * @description     This method is invoked when Next Page, Prev Page or page numbers clicked in the page
	  * @param       NA
	  * @return      void
	  * @throws      Method might throw exception which is handled by Try-Catch block
	  */
	public void doPagination() {
	  makeupPaginationList(false);
	}
  
	/**
	  * @description     This method is invoked when Clear button is clicked to clear variables
	  * @param       NA
	  * @return      void
	  * @throws      Method might throw exception which is handled by Try-Catch block
	  */
	public void clearSearch() {
	  initPage();
	}
  
	/**
	  * @description     This method buids SOQL for Contact with fields to be queried
	  * @param       queryFields - Set<String>
	  * @return      String
	  * @throws      Method might throw exception which is handled by calling method
	  */
  
	private String buildSOQL(String whereClause) {
	  return 'SELECT Id, VerifiedEmail__c, Name, Preferred_Name__c, OtherStreet, OtherStreet2__c, OtherCity, OtherState, OtherPostalCode, Is_Inactive_Customer__c, Account.isCustomerPortal, OtherCountry, OtherDPID__c, MailingDPID__c, SocialKeys__c, ReversePhoneFields__c, Salutation, CRMCSSOID__c, IsDuplicate__c, Phone, HomePhone, OtherPhone, MobilePhone,VerifiedMobile__c,LevelOfAssurance__c, Email, ServiceType__c, MailingStreet, MailingStreet2__c, MailingCity, MailingState, MailingCountry, MailingPostalCode, AccountId, Account.Name, Account.IsPersonAccount, Account.RecordTypeId, Account.RecordType.Name, Account.ABN__c,Account.Role_Type_Roll_Up__c, Account.ServiceSLA__c, Account.IsVIP__c, BillingAccount__r.Id, BillingAccount__r.Name, BillingAccount__r.LEGACY_ID__c, Unique_Mobile__c, (SELECT Id,IsClosed FROM Cases) FROM Contact' +
		  (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '') + ' ORDER BY Unique_Mobile__c DESC, Name LIMIT ' + ROW_LIMIT;
	}
  
	/**
	  * @description     This method buids WHERE Clause for SOQL based on search parameters
	  * @param       NA
	  * @return      String
	  * @throws      Method might throw exception which is handled by calling method
	  */
	private String buildWhereClause(String operator) {
	  String whereClause = WHITE_SPACE;
  
	  // 17 Sept 2015 CH Updated to use Name field instead of FirstName and LastName fields for performance
  
	  //whereClause = String.isNotBlank(strFirstName) ?
	  //        (whereClause + addCondition(FIRSTNAME_FLD,LIKE_SQL,strFirstName) + AND_SQL) : whereClause;
	  //whereClause = String.isNotBlank(strLastName) ?
	  //        (whereClause + addCondition(LASTNAME_FLD,LIKE_SQL,strLastName) + AND_SQL) : whereClause;
  
	  if (LIKE_SQL.equalsIgnoreCase(operator)) {
		whereClause = (String.isNotBlank(strFirstName) || String.isNotBlank(strLastName)) ?
			(whereClause + addConcatCondition(NAME_FLD, LIKE_SQL, strFirstName, strLastName) + AND_SQL) : whereClause;
	  } else if (EQUALS.equalsIgnoreCase(operator)) {
		whereClause = (String.isNotBlank(strFirstName) || String.isNotBlank(strLastName)) ?
			(whereClause + addConcatCondition(NAME_FLD, EQUALS, strFirstName, strLastName) + AND_SQL) : whereClause;
	  }
	  whereClause = String.isNotBlank(strPreferredName) ?
		 (whereClause + addCondition(Preferred_Name, LIKE_SQL, strPreferredName) + AND_SQL) : whereClause;
	  
		
	  if (String.isNotBlank(strCustomerType)) {
		if (CONSUMER.equalsIgnoreCase(strCustomerType)) {
		  whereClause += addCondition(PERSON_ACCOUNT_FLD, EQUALS, TRUE_VAL) + AND_SQL;
		} else {
		  whereClause += addCondition(PERSON_ACCOUNT_FLD, EQUALS, FALSE_VAL) + AND_SQL;
		}
	  }       
  
	  if (String.isNotBlank(strCustomerType) && CONSUMER.equalsIgnoreCase(strCustomerType)) {
		whereClause = (String.isNotBlank(strAccountNumber)) ?
			(whereClause + addCondition(APCN_FLD, LIKE_SQL, strAccountNumber) + AND_SQL) : whereClause;
	  } else {
		whereClause = (String.isNotBlank(strAccountNumber)) ?
			(whereClause + OPEN_BRACE + addCondition(APCN_FLD, LIKE_SQL, strAccountNumber) + OR_SQL +
				addCondition(ABN_FLD, LIKE_SQL, strAccountNumber) + OR_SQL +
				addCondition(LEGACYID_FLD, LIKE_SQL, strAccountNumber) + CLOSE_BRACE + AND_SQL) : whereClause;
		whereClause = (String.isNotBlank(strAccountName)) ?
			(whereClause + OPEN_BRACE + addCondition(ACCName_FLD, LIKE_SQL, strAccountName) + OR_SQL +
				addCondition(BILLACCNAME_FLD, LIKE_SQL, strAccountName) + CLOSE_BRACE + AND_SQL) : whereClause;
	  }
  
	  {
		whereClause += '(';
  
		whereClause = String.isNotBlank(strEmail) ?
			(whereClause + addCondition(EMAIL_FLD, LIKE_SQL, strEmail) + OR_SQL) : whereClause;        
		
	  
  
		if (!ckbExcludePhoneFromSearch && String.isNotBlank(strPhone)) {
		  // TODO: This search is not the best way to search for customer records.
		  // NOTE: This same way of searching for phone numbers has also been rolled out to AP_ConnectorController2 for the CTI adapter.
		  // If changes are made to how contacts are searched by phone number, it's important that AP_ConnectorController2 is also updated!
		  String reversePhone = Util.reversePhoneString(strPhone);
		  whereClause = String.isNotBlank(reversePhone) ?
			  (whereClause + addCondition(REV_PHONE_FLD, LIKE_SQL, reversePhone) + OR_SQL) : whereClause;
		}
  
		whereClause = String.isNotBlank(strSocialKeys) ?
			(whereClause + addCondition(SOCIAL_KEY_FLD, LIKE_SQL, strSocialKeys) + OR_SQL) : whereClause;
  
		if (proxyAddress != null && String.isNotBlank(proxyAddress.line1)) {
		  whereClause += OPEN_BRACE;
  
		  whereClause += addCondition(MAIL_STREET_FLD, LIKE_SQL, proxyAddress.line1) + AND_SQL;
		  whereClause = String.isNotBlank(proxyAddress.line2) ?
			  (whereClause + addCondition(MAIL_STREET2_FLD, LIKE_SQL, proxyAddress.line2) + AND_SQL) : whereClause;
		  whereClause = String.isNotBlank(proxyAddress.city) ?
			  (whereClause + addCondition(MAIL_CITY_FLD, LIKE_SQL, proxyAddress.city) + AND_SQL) : whereClause;
		  whereClause = String.isNotBlank(proxyAddress.state) ?
			  (whereClause + addCondition(MAIL_STATE_FLD, LIKE_SQL, proxyAddress.state) + AND_SQL) : whereClause;
		  whereClause = String.isNotBlank(proxyAddress.postcode) ?
			  (whereClause + addCondition(MAIL_ZIPCODE_FLD, LIKE_SQL, proxyAddress.postcode) + AND_SQL) : whereClause;
		  whereClause = String.isNotBlank(proxyAddress.country) ?
			  (whereClause + addCondition(MAIL_COUNTRY_FLD, LIKE_SQL, proxyAddress.country) + AND_SQL) : whereClause;
  
		  whereClause = (whereClause.endsWith(AND_SQL) || whereClause.endsWith(OR_SQL)) ?
			  whereClause.substring(0, whereClause.length() - 4) : whereClause;
  
		  whereClause += CLOSE_BRACE + OR_SQL;
  
		  whereClause += OPEN_BRACE;
		  whereClause += addCondition(OTHER_STREET_FLD, LIKE_SQL, proxyAddress.line1) + AND_SQL ;
		  whereClause = String.isNotBlank(proxyAddress.line2) ?
			  (whereClause + addCondition(OTHER_STREET2_FLD, LIKE_SQL, proxyAddress.line2) + AND_SQL) : whereClause;
		  whereClause = String.isNotBlank(proxyAddress.city) ?
			  (whereClause + addCondition(OTHER_CITY_FLD, LIKE_SQL, proxyAddress.city) + AND_SQL) : whereClause;
		  whereClause = String.isNotBlank(proxyAddress.state) ?
			  (whereClause + addCondition(OTHER_STATE_FLD, LIKE_SQL, proxyAddress.state) + AND_SQL) : whereClause;
		  whereClause = String.isNotBlank(proxyAddress.postcode) ?
			  (whereClause + addCondition(OTHER_ZIPCODE_FLD, LIKE_SQL, proxyAddress.postcode) + AND_SQL) : whereClause;
		  whereClause = String.isNotBlank(proxyAddress.country) ?
			  (whereClause + addCondition(OTHER_COUNTRY_FLD, LIKE_SQL, proxyAddress.country) + AND_SQL) : whereClause;
  
		  whereClause = (whereClause.endsWith(AND_SQL) || whereClause.endsWith(OR_SQL)) ?
			  whereClause.substring(0, whereClause.length() - 4) : whereClause;
		  whereClause += CLOSE_BRACE + OR_SQL;
		} else {
		  whereClause = String.isNotBlank(strAddress) ?
			  (whereClause + addCondition(MAIL_STREET_FLD, LIKE_SQL, strAddress) + OR_SQL +
				  addCondition(OTHER_STREET_FLD, LIKE_SQL, strAddress)) : whereClause;
		  //03/07/2017 Added by Maumita to resolve the address search issue in MyCustomers Starts
		  //10/08/2017 Added by Maumita to resolve the address search error Starts
		   whereClause = (String.isNotBlank(strAddress_line) || String.isNotBlank(strAddress_city) || String.isNotBlank(strAddress_state)|| String.isNotBlank(strAddress_pc)|| String.isNotBlank(strAddress_country)) ?
			 (whereClause + OPEN_BRACE ) : whereClause;
		  //10/08/2017 Added by Maumita to resolve the address search error ends
		  whereClause = String.isNotBlank(strAddress_line) ?
			  (whereClause + OPEN_BRACE + addCondition(MAIL_STREET_FLD, LIKE_SQL, strAddress_line) + OR_SQL +
				  addCondition(OTHER_STREET_FLD, LIKE_SQL, strAddress_line) + CLOSE_BRACE + AND_SQL) : whereClause;
		   whereClause = String.isNotBlank(strAddress_city) ?
			  (whereClause + OPEN_BRACE + addCondition(MAIL_CITY_FLD, LIKE_SQL, strAddress_city) + OR_SQL +
				  addCondition(OTHER_CITY_FLD, LIKE_SQL, strAddress_city)+ CLOSE_BRACE  + AND_SQL) : whereClause;
		  whereClause = String.isNotBlank(strAddress_state) ?
			  (whereClause + OPEN_BRACE + addCondition(MAIL_STATE_FLD, LIKE_SQL, strAddress_state) + OR_SQL +
				  addCondition(OTHER_STATE_FLD, LIKE_SQL, strAddress_state) + CLOSE_BRACE + AND_SQL) : whereClause;
		   whereClause = String.isNotBlank(strAddress_pc) ?
			  (whereClause + OPEN_BRACE + addCondition(MAIL_ZIPCODE_FLD, LIKE_SQL, strAddress_pc) + OR_SQL +
				  addCondition(OTHER_ZIPCODE_FLD, LIKE_SQL, strAddress_pc)+ CLOSE_BRACE  + AND_SQL) : whereClause;
		   whereClause = String.isNotBlank(strAddress_country) ?
			  (whereClause + OPEN_BRACE + addCondition(MAIL_COUNTRY_FLD, LIKE_SQL, strAddress_country) + OR_SQL +
				  addCondition(OTHER_COUNTRY_FLD, LIKE_SQL, strAddress_country)+ CLOSE_BRACE  + AND_SQL) : whereClause;
		   //10/08/2017 Added by Maumita to resolve the address search error Starts
		   whereClause = ((whereClause.endsWith(AND_SQL) || whereClause.endsWith(OR_SQL)) && (String.isNotBlank(strAddress_line) || String.isNotBlank(strAddress_city) || String.isNotBlank(strAddress_state)|| String.isNotBlank(strAddress_pc)|| String.isNotBlank(strAddress_country))) ?
			 (whereClause.substring(0, whereClause.length() - 4) + CLOSE_BRACE ) : whereClause;
		  //10/08/2017 Added by Maumita to resolve the address search error ends
		  //03/07/2017 Added by Maumita to resolve the address search issue in MyCustomers Ends
		}
  
		whereClause = (whereClause.endsWith(AND_SQL) || whereClause.endsWith(OR_SQL)) ?
			whereClause.substring(0, whereClause.length() - 4) : whereClause;
		whereClause += CLOSE_BRACE + AND_SQL;
	  }
  
  
	  whereClause = (whereClause.endsWith(AND_SQL) || whereClause.endsWith(OR_SQL)) ?
		  whereClause.substring(0, whereClause.length() - 4) : whereClause;
  
	  whereClause = whereClause.endsWith(AND_BRACE) || whereClause.endsWith(OR_BRACE) ?
		  whereClause.substring(0, whereClause.length() - 7) : whereClause;
  
	  System.debug('** whereClause ==>' + whereClause);
	  return whereClause;
	}
  
	/**
	  * @description     This method builds filters for SOQL
	  * @param       fieldName, operator, fieldVar
	  * @return      String
	  * @throws      NA
	  */
	private String addCondition(String fieldName, String operator, String fieldVar) {
	  String retCondtn ;
	  if (String.isNotBlank(fieldName) && String.isNotBlank(operator) && String.isNotBlank(fieldVar)) {
		if (LIKE_SQL.equalsIgnoreCase(operator)) {
		  retCondtn = EMPTY_SPACE + fieldName + EMPTY_SPACE + operator + EMPTY_SPACE + QUOTE +
			  String.escapeSingleQuotes(fieldVar) + PERCENT_QUOTE + EMPTY_SPACE;
		} else if (EQUALS.equalsIgnoreCase(operator)) {
		  retCondtn = EMPTY_SPACE + fieldName + EMPTY_SPACE + operator + EMPTY_SPACE + fieldVar + EMPTY_SPACE;
		}
	  }
	  return retCondtn;
	}
  
	/**
	  * @description     This method builds filters for SOQL based on 2 concatenated variables using a trailing wild card
	  * @param       fieldName, operator, fieldVar1, fieldVar2
	  * @return      String
	  * @throws      NA
	  */
	private String addConcatCondition(String fieldName, String operator, String fieldVar1, String fieldVar2) {
	  String retCondtn ;
	  System.debug('** fieldVar1 ==>' + fieldVar1);
	  System.debug('** fieldVar2 ==>' + fieldVar2);
	  if (String.isNotBlank(fieldName) && String.isNotBlank(operator) && (String.isNotBlank(fieldVar1) || String.isNotBlank(fieldVar2))) {
		if (LIKE_SQL.equalsIgnoreCase(operator)) {
		  retCondtn = EMPTY_SPACE + fieldName + EMPTY_SPACE + operator + EMPTY_SPACE + QUOTE +
			  String.escapeSingleQuotes(fieldVar1) + PERCENT + String.escapeSingleQuotes(fieldVar2) + PERCENT_QUOTE + EMPTY_SPACE;
		} else if (EQUALS.equalsIgnoreCase(operator)) {
		  retCondtn = EMPTY_SPACE + fieldName + EMPTY_SPACE + operator + EMPTY_SPACE + QUOTE + String.escapeSingleQuotes(fieldVar1) + EMPTY_SPACE
			  + String.escapeSingleQuotes(fieldVar2) + QUOTE + EMPTY_SPACE;
		}
	  }
	  System.debug('** retCondtn ==>' + retCondtn);
	  return retCondtn;
	}
  
	//Paginates the total contacts and populates the current list of contacts to be shown
	private void makeupPaginationList(boolean isNew) {
	  if (isNew) {
		totalRecordsNum = contacts.size();  // step 1, total records
		// step 2, total pages number
		//Math.ceil can't work as expected, example Math.ceil(201/100) expect 3 but result is 2,
		//so take our way.
		String s = '' + totalRecordsNum;
		Long l = long.valueOf(s);
		Long m = Math.mod(l, 100L);
		Double doubleVal;
		doubleVal = m > 0 ? Math.floor(l / 100L) + 1 : Math.floor(l / 100L);
		totalPageNum = doubleVal.intValue();
		//step 3, page number list
		list_pageNo = new List<Integer>();
		for (integer i = 1; i <= totalPageNum; i++) {
		  list_pageNo.add(i);
		}
		currentPageNum = 1; //step 4, if isNewSearch, current page must be 1
		showList = totalRecordsNum > 0 ? true : false;  //step 5, set value of showList
	  }
	  // make up the current list to render on page
	  contacts4Page = new List<ContactListDisplay>();
	  Integer minPos = (currentPageNum - 1) * contactPageSize;
	  Integer maxPos = currentPageNum * contactPageSize;
	  for (Integer j = 0; j < totalRecordsNum; j++) {
		if (j >= minPos && j < maxPos) {
		  contacts4Page.add(contacts.get(j));
		}
	  }
	}
  
	@RemoteAction
	public static List<ContactListDisplay> addCustomer(String strAccountName,
		String strAccountNumber,
		String strFirstName,
		String strLastName,
		String strPreferredName,
		String strFullAddress,
		String strEmail,
		String strPhone,
		String strSocialKeys,
		String strCustomerType,
		String strDPID,
		String strAddressLine1,
		String strAddressLine2,
		String strCity,
		String strState,
		String strPostcode,
		String strCountry,
		Boolean emailNotAvailable
		) {
	  List<ContactListDisplay> result = new List<ContactListDisplay>();
	  String accountId = '';
	  String billingAccountId = '';
  
	  //If Account Name and/or Account No. is provided, trying to find the matching Account or Billing Account using SOSL
	  if (strAccountNumber.trim() != '' || strAccountName.trim() != '') {
		String accountWhereClause = strAccountNumber.trim() != '' ? 'ABN__c = \'' + string.escapesinglequotes(strAccountNumber.trim()) + '\'' : '';
		String billingWhereClause = strAccountNumber.trim() != '' ? 'LEGACY_ID__c = \'' + string.escapesinglequotes(strAccountNumber.trim()) + '\'' : '';
		String findClause = strAccountNumber.trim() != '' ? '"' + string.escapesinglequotes(strAccountNumber.trim()) + '*"' : '';
		String acctFindClause = strAccountNumber.trim() != '' ? '"' + string.escapesinglequotes(strAccountNumber.trim()) + '*"' : '';
  
		if (strAccountName.trim() != '' && findClause != '') {
		  accountWhereClause += ' and ';
		  billingWhereClause += ' and ';
		  findClause += ' or ';
		  acctFindClause += ' or ';
		}
  
		accountWhereClause += strAccountName.trim() != '' ? 'Name = \'' + string.escapesinglequotes(strAccountName.trim()) + '\'' : '';
		billingWhereClause += strAccountName.trim() != '' ? 'Name = \'' + string.escapesinglequotes(strAccountName.trim()) + '\'' : '';
		findClause += strAccountName.trim() != '' ? '"' + string.escapesinglequotes(strAccountName.trim()) + '*"' : '';
		acctFindClause += strAccountName.trim() != '' ? '"' + string.escapesinglequotes(strAccountName.trim()) + '*"' : '';
  
		findClause = '\'' + findClause + '\'';
		acctFindClause = '\'' + acctFindClause + '\'';//modified by yuanyuan zhang 2014-08-13.
  
		String queryString = 'Find ' + acctFindClause + ' IN ALL FIELDS RETURNING ' +
			'Account(id where isPersonAccount = false and ' + accountWhereClause + '),' +
			'Billing_Account__c(id,Organisation__c where ' + billingWhereClause + ')';
  
  
		List<List<SObject>> queryResults = search.query(queryString);
		if (!queryResults.isEmpty()) {
		  if (!queryResults[0].isEmpty()) {
			accountId = queryResults[0][0].Id;
		  } else {
			List<Billing_Account__c> billingAccounts = queryResults[1];
			if (!billingAccounts.isEmpty()) {
			  billingAccountId = billingAccounts[0].Id;
			  accountId = billingAccounts[0].Organisation__c;
			}
		  }
		}
	  }
  
	  String addressLine = strAddressLine1.trim() + (strAddressLine2.trim() != '' ? ',' + strAddressLine2.trim() : '');
	  if (addressLine == '') {
		strAddressLine1 = strFullAddress.trim();
	  }
  
	  if (strCustomerType == STR_CONSUMER || (String.isEmpty(strAccountName.trim()) && String.isEmpty(strAccountNumber.trim()))) {
		//If Consumer customer type is selected, creating a person account
		Account newPersonAccount = new Account();
		newPersonAccount.FirstName = strFirstName.trim();
		newPersonAccount.LastName = strLastName.trim();
		newPersonAccount.Preferred_Name__pc = strPreferredName.trim();
  
  
		//Populating either mobile or home phone based on the starting digits
		if (strPhone.trim().replaceAll('[^0-9]', '').startsWith('04') ||
			strPhone.trim().replaceAll('[^0-9]', '').startsWith('614') ||
			strPhone.trim().replaceAll('[^0-9]', '').startsWith('6104')) {
		  newPersonAccount.PersonMobilePhone = strPhone.trim();
		} else {
		  newPersonAccount.PersonHomePhone = strPhone.trim();
		}
		newPersonAccount.PersonEmail = strEmail.trim();
		newPersonAccount.SocialKeys__pc = strSocialKeys.trim();
		newPersonACcount.CustomerType__c = strCustomerType.trim();
		newPersonAccount.EmailNotAvailable__pc = emailNotAvailable;
		//Modified on 13/08/2014 by Jack Li
		//to fixe bug QC596: do not save APCN when creating from Contact Search page; keep APCN in Description field as "Customer provided APCN: <Entered Value>"
		//newPersonAccount.APCN__pc = strAccountNumber.trim();
		if (strAccountNumber.trim() != '') {
		  newPersonAccount.Description = 'Customer provided APCN: ' + strAccountNumber.trim();
		}
  
		newPersonAccount.PersonMailingStreet = strAddressLine1;
		newPersonAccount.MailingStreet2__pc = strAddressLine2;
		newPersonAccount.PersonMailingCity = strCity;
		newPersonAccount.PersonMailingState = strState;
		newPersonAccount.PersonMailingPostalCode = strPostcode;
		newPersonAccount.PersonMailingCountry = strCountry;
		newPersonAccount.MailingDPID__pc = strDPID;
  
		newPersonAccount.RequiresOrganisation__c = true;
  
		//15-06-2017 Dion Gunn Changed the below to handle exceptions generated by Duplicate Checking
		Database.SaveResult srPersonAccount = Database.insert(newPersonAccount, false);
		ContactListDisplay noDupePersonResult = new ContactListDisplay();
		if (srPersonAccount.isSuccess()) {
		  noDupePersonResult.result = newPersonAccount.id;
		  result.add(noDupePersonResult);
		} else {
		  // Operation failed, so get all errors
		  for (Database.Error error : srPersonAccount.getErrors()) {
			//If the failure is because of duplicate rules, handle the results.
			if (error instanceof Database.DuplicateError) {
			  result = handleDuplicates(error);
			} else {
			  noDupePersonResult.result = 'Error: ' + error.getStatusCode() + ': ' + error.getMessage();
			  result.add(noDupePersonResult);
			}
		  }
		}
	  } else {
		try {
		  //If no Customer Type is selected or Organization Contact is selected, creating a contact
		  Contact newContact = new Contact();
		  newContact.FirstName = strFirstName.trim();
		  newContact.LastName = strLastName.trim();
		  newContact.Preferred_Name__c = strPreferredName.trim();
  
  
		  //Populating either mobile or home phone based on the starting digits
		  if (strPhone.trim().replaceAll('[^0-9]', '').startsWith('04') ||
			  strPhone.trim().replaceAll('[^0-9]', '').startsWith('614') ||
			  strPhone.trim().replaceAll('[^0-9]', '').startsWith('6104')) {
			newContact.MobilePhone = strPhone.trim();
		  } else {
			newContact.HomePhone = strPhone.trim();
		  }
  
		  newContact.Email = strEmail.trim();
		  newContact.EmailNotAvailable__c = emailNotAvailable;
		  newContact.SocialKeys__c = strSocialKeys;
		  if (accountId != '') {
			newContact.accountid = accountId;
		  } else {
			Account newAccount = new Account(Name = strAccountName.trim(), ABN__c = strAccountNumber.trim());
			insert newAccount;
			newContact.accountId = newAccount.id;
		  }
		  if (billingAccountId != '') {
			newContact.BillingAccount__c = billingAccountId;
		  }
		  newContact.MailingStreet = strAddressLine1;
		  newContact.MailingStreet2__c = strAddressLine2;
		  newContact.MailingCity = strCity;
		  newContact.MailingState = strState;
		  newContact.MailingPostalCode = strPostcode;
		  newContact.MailingCountry = strCountry;
		  newContact.MailingDPID__c = strDPID;
  
		  //15-06-2017 Dion Gunn Changed the below to return a ContactListDisplay list for better integration
		  //with the new Duplicate Checking rules.
		  //21-05-2019 MW0003155 Using Database method to insert instead of DML to bypass new duplicate rules for now
		  //insert newContact;
		  Database.DMLOptions dml = new Database.DMLOptions();
		  dml.DuplicateRuleHeader.AllowSave = true;
		  //Database.insert(newContact, dml);
		  
		  Database.SaveResult srBusinessContact = Database.insert(newContact, dml);
		  ContactListDisplay noDupeBusinessContactResult = new ContactListDisplay();
		  // if successful, redirect to new contact and save new contact into table for display
		  if (srBusinessContact.isSuccess()) {
			noDupeBusinessContactResult.result = newContact.id;
			result.add(noDupeBusinessContactResult);
		  } else {
			// Operation failed, so get all errors
			for (Database.Error error : srBusinessContact.getErrors()) {
			  //If error is due to duplicate rules, handle the results.
			  if (error instanceof Database.DuplicateError) {
				result = handleDuplicates(error);
			  } else {
				// Display error and any duplicates detected
				noDupeBusinessContactResult.result = 'Error: ' + error.getStatusCode() + ': ' + error.getMessage();
				result.add(noDupeBusinessContactResult);
			  }
			}
		  }
		} catch (DmlException ex) {
		  ContactListDisplay businessDMLErrorResult = new ContactListDisplay();
		  businessDMLErrorResult.result = 'Error: ' + ex.getDmlMessage(0);
		  result.add(businessDMLErrorResult);
		}
	  }
	  return result;
	}
  
	//15/06/2017 Dion Gunn - New method to manage exceptions generated by the SSSW Person Account duplicate checking rules.
	//21/10/2019 Seth Heang - factorise the class to perform duplicate check and display specific error message for Account or Contact object
	public static List<ContactListDisplay> handleDuplicates(Database.Error error) {
	  //Sort through the duplicates for return to view.
	  List<ContactListDisplay> dupeList = new List<ContactListDisplay>();
	  duplicateRecords = new List<sObject>();
	  Database.DuplicateError duplicateError = (Database.DuplicateError) error;
	  Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
	  Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
	  Datacloud.MatchResult matchResult = matchResults[0];
	  Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
  
	  // Get duplicate rule that's been triggered
	  String dupRule = duplicateResult.getDuplicateRule();
	  String result = '';
	  List<Contact> duplicates = new List<Contact>();
	  // Check if dup rule is blocking personAccount
	  if (dupRule.equals(CONSUMER_BLOCK_DUPLICATE_RULE_DEVELOPER_NAME)){
		result = 'Error: ' + error.getStatusCode() + ': ' +
		  'A consumer with the same first name, last name and email or phone number already exists. ' +
		  'Records identified as duplicates have been listed in the search results below.';
		// Add matched record to the duplicate records variable for display
		List<Account> duplicateAccs = new List<Account>();
		for (Datacloud.MatchRecord matchRecord : matchRecords) {
		  duplicateAccs.add((Account) matchRecord.getRecord());
		}
		//Grab all the other related fields we need to properly render the search results
		duplicates = new List<Contact>([
			SELECT Id, Name, Preferred_Name__c, OtherStreet, OtherStreet2__c, OtherCity, OtherState, OtherPostalCode, Is_Inactive_Customer__c, Account.isCustomerPortal, OtherCountry, OtherDPID__c, MailingDPID__c, SocialKeys__c, ReversePhoneFields__c,
				Salutation, CRMCSSOID__c, IsDuplicate__c, Phone, HomePhone, OtherPhone, MobilePhone, Email, ServiceType__c, MailingStreet, MailingStreet2__c, MailingCity, MailingState, MailingCountry, MailingPostalCode, AccountId, Account.Name,
				Account.IsPersonAccount, Account.RecordTypeId, Account.RecordType.Name, Account.ABN__c,Account.Role_Type_Roll_Up__c, Account.ServiceSLA__c, Account.IsVIP__c, BillingAccount__r.Id, BillingAccount__r.Name, BillingAccount__r.LEGACY_ID__c, Unique_Mobile__c, (SELECT Id,IsClosed FROM Cases)
			FROM Contact
			where AccountId in:duplicateAccs
		]);
	  // Check if dup rule is blocking business contact
	  }else if (dupRule.equals(CONTACT_BLOCK_DUPLICATE_RULE_DEVELOPER_NAME)){
		result = 'Error: ' + error.getStatusCode() + ': ' +
			'Business Contact under same Organisation is Blocked!';
		List<Contact> duplicateCons = new List<Contact>();
		// Add matched record to the duplicate records variable for display
		for (Datacloud.MatchRecord matchRecord : matchRecords) {
		  duplicateCons.add((Contact) matchRecord.getRecord());
		}
		//Grab all the other related fields we need to properly render the search results
		duplicates = new List<Contact>([
			SELECT Id, Name,Preferred_Name__c, OtherStreet, OtherStreet2__c, OtherCity, OtherState, OtherPostalCode, Is_Inactive_Customer__c, Account.isCustomerPortal, OtherCountry, OtherDPID__c, MailingDPID__c, SocialKeys__c, ReversePhoneFields__c,
				Salutation, CRMCSSOID__c, IsDuplicate__c, Phone, HomePhone, OtherPhone, MobilePhone, Email, ServiceType__c, MailingStreet, MailingStreet2__c, MailingCity, MailingState, MailingCountry, MailingPostalCode, AccountId, Account.Name,
				Account.IsPersonAccount, Account.RecordTypeId, Account.RecordType.Name, Account.ABN__c,Account.Role_Type_Roll_Up__c, Account.ServiceSLA__c, Account.IsVIP__c, BillingAccount__r.Id, BillingAccount__r.Name, BillingAccount__r.LEGACY_ID__c, Unique_Mobile__c, (SELECT Id,IsClosed FROM Cases)
			FROM Contact
			where Id in:duplicateCons
		]);
	  }
	  // Save results for display in table
	  for (Contact con : duplicates) {
		dupeList.add(new ContactListDisplay(result, con));
	  }
	  return dupeList;
	}

	//verify if the current logged in user is live agent user
	@TestVisible
	private void isLiveAgent(){
		isLiveAgentUser = UsersSelector.newInstance().selectById(new Set<Id>{UserInfo.getUserId()}).get(UserInfo.getUserId()).UserPermissionsLiveAgentUser;
	}
  
	@RemoteAction
	public static List<ContactListDisplay> searchCustomer(String strCustomerType,
		String strEmail,
		String strFirstName,
		String strLastName,
		String strPreferredName,
		String strPhone,
		String strAccountNumber,
		String strAccountName,
		String strSocialKeys,
		String strAddress,
		//03/07/2017 Added by Maumita to resolve the address search issue in MyCustomers Starts                        
		String strAddress_line,
		String strAddress_city, 
		String strAddress_state,
		String strAddress_pc,   
		String strAddress_country, 
		//03/07/2017 Added by Maumita to resolve the address search issue in MyCustomers Ends
		boolean ignorePhone) {
	  SearchContactComponentController ctrl = new SearchContactComponentController();
	  ctrl.strCustomerType = strCustomerType;
	  ctrl.strEmail = strEmail;
	  ctrl.strFirstName = strFirstName;
	  ctrl.strLastName = strLastName;
	  ctrl.strPreferredName = strPreferredName;
	  ctrl.strPhone = strPhone;
	  ctrl.strAccountNumber = strAccountNumber;
	  ctrl.strAccountName = strAccountName;
	  ctrl.strSocialKeys = strSocialKeys;
	  ctrl.strAddress = strAddress;
	  //03/07/2017 Added by Maumita to resolve the address search issue in MyCustomers Starts
	  ctrl.strAddress_line = strAddress_line;
	  ctrl.strAddress_city = strAddress_city;
	  ctrl.strAddress_state = strAddress_state;
	  ctrl.strAddress_pc = strAddress_pc;
	  ctrl.strAddress_country = strAddress_country;
	  //03/07/2017 Added by Maumita to resolve the address search issue in MyCustomers Starts
	  ctrl.ckbExcludePhoneFromSearch = ignorePhone;
  
	  ctrl.loadContacts();
	  return ctrl.contacts4Page;
	}
  
  //Wrapper class for the displayed contacts
	public class ContactListDisplay {
	  public Contact contact { get; set; }
	  public Integer numberOfOpenCases { get; set; }
	  public Integer numberOfClosedCases { get; set; }
	  //Result contains either the error, or the id of the record created.
	  public String result { get; set; }
  
	  public ContactListDisplay() {
		numberOfOpenCases = 0;
		numberOfClosedCases = 0;
	  }
	  //New constructor for returning duplicates.
	  public ContactListDisplay(String result, Contact con) {
		this(con);
		this.result = result;
	  }
  
	  public ContactListDisplay(Contact con) {
		this();
		this.contact = con;
		if (con.cases != null)
		  for (Case caseRec : con.cases)
			if (caseRec.IsClosed) numberOfClosedCases++; else numberOfOpenCases++;
	  }
	}
  }