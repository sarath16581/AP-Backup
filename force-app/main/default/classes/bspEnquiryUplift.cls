/**************************************************
Type:		Controller for new LWC components for Enquiry Creation and Search Tracking Numbers. Components are bspFormAPEnquiry, bspFormAPGeneral, bspFormSTDeliveryEnquiry, bspFormSTPickupBookingEnquiry
History:
NOTE:		Need to use without sharing	:as Owner for the created case will be set to "Enterprise Inbound Queue"
NOTE:									: additional fields, objects won't be quieried successfully if without sharing is not used...
NOTE:									: also to implement duplicate case error requirements while creating enquiry for AP & ST.
TODO		^^ Refactor code to remove without sharing....Nathan Franklin - 2019-07
--------------------------------------------------
2020-08-02	Jansi Rani. avula.jansirani@auspost.com.au  Initial Code for community uplift project.
2020-10-29	Ankur Gandhi. ankur.gandhi@auspost.com.au Adding the enquiry type filter for AP and ST enquiries.
13/10/2021	prerna.rahangdale@auspost.com.au PARSIM Premium Express for creating Case out conditions on the products.
19/04/2023	hasantha.liyanage@auspost.com.au DDS-15568 FOHS -BSP - Holding Bay - Case held before EDD+10 day
04/05/2023	stephen.liu25@auspost.com.au DDS-15573 Modified the BSP Controller logic to incorporate the "Essential Medicine" and "Sentimental Value" questions
13/06/2023	SL DDS-16384 added logic to set the Type_and_Product__c field based on enq.Type
04/09/2023	hasantha.liyanage@auspost.com.au SB-120 added credit claim filtering for case listing and restructured the getSearchEnquiriesWhereClause method
29/09/2023	hasantha.liyanage@auspost.com.au SB-94 added Account Number type ahead dropdown and the other account number functionality
05/10/2023	hasantha.liyanage@auspost.com.au SB-121 added extra fields for downlaod all
23/10/2023	hasantha.liyanage@auspost.com.au added method buildReasonForClaimHelpText
**************************************************/
public without sharing class bspEnquiryUplift {

	public static Case enq {get;set;}
	public static Case dummyEnq1 {get;set;}
	public static String fromWhoRadio {get;set;}
	public static String indOrgEnquiryFlag {get;set;}
	public static Integer dynamicPageSize {get;set;}
	public static String lastKey {get;set;}
	public static String searchText {get;set;}
	public static String multipleCaseError {get;set;}
	public static String consignmentNumber {get;set;}
	//public static String billingAccountNumber { get; set; }
	//public static boolean notFound {get;set;}
	//public static boolean duplicate {get;set;}
	public static String caseRecStatus {get; set;}
	public static Set<String> selectedStatuses {get; set;}
	public static StarTrackConsignmentSearchUtil.ConsignmentWrapper searchedConsignment {get; set;}
	public static Map<String, Id> caseNumbers {get; set;}
	public static Article__c currentConsignment {get; set;}
	public static Case newCase {get; set;}
	public static Date startDate {get; set;}
	public static Date endDate {get; set;}
	public static String selectedEnquiryType {get; set;}
	public static List<CaseContainer> allCaseSearchRecords{get;set;}
	public static Integer dynamicPageNumber {get;set;}
	public static Integer totalSearchRecordCount {get;set;}
	public static Boolean isReqFromDownload {set;get;}

	// QAS
	public static AddressExtension toAddress {get;set;}
	public static AddressExtension fromAddress {get;set;}

	public static Set<Id> stRecordTypes = new Set<Id>();
	public static Set<Id> apRecordTypes = new Set<Id>();
	public static Set<Id> creditClaimRecordTypes = new Set<Id>();
	public static StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();

	public static Article__c articleFromConsignSearch;
	public static Set<Id> superAdminEntities;
	public static Set<Id> adminEntities;

	public static String sortByColumnApiName = 'CaseNumber';
	public static String sortByOrder = 'desc';
	public static String STATUS_OK = 'ok';
	public static String STATUS_ERROR = 'error';
	public static String ERROR_MESSAGE_CANNOT_CREATE = 'You do not have access to create an enquiry of this type';

	// Defines that the new case form should be displayed when a consignment id is passed from the consignment search page to this page
	//public static Boolean creationFromConsignSearch {get; set;}

	// Hasantha (30/01/2019) : holder for selected billing account
	public static String selectedBillingAccount {get; set;}

	// prepare and store data to be downloaded for user by clicking "Download All" link
	public static Object downloadCaseDetails {get; set;}

	// Stores a list of StarTrack product id's that may be surfaced from SAP EM
	// This is used to indicate that the consignment should be searched using the ST .net search
	/*public Map<String, StarTrackConsignmentProductIDs__c> startrackProdIDs {
		get {
			return StarTrackConsignmentProductIDs__c.getAll();
		}
	}*/

	/**
	 * static block
	* */
	static{
		dynamicPageSize = Integer.valueOf(bspBaseUplift.configSetting.EnquiriesPerPage__c);
		dummyEnq1 = new Case();
		dummyEnq1.End_Date__c = null;
		dummyEnq1.Start_Date__c = null;
	}

	/**
	* Retrieving startrack recordtypes
	* */
	public static void retrieveRecordTypes() {
		for (BSPStarTrackCaseTypes__c cType : [SELECT Id, Name, RecordTypeId__c FROM BSPStarTrackCaseTypes__c WHERE Name LIKE 'StarTrack%']) {
			stRecordTypes.add(cType.RecordTypeId__c);
		}
	}

	/**
	 * Grab the credit claim dispute record types
	 */
	public static void retrieveCreditClaimRecordTypes(){
		creditClaimRecordTypes = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String> {BspConstants.CASE_RECORD_TYPE_ENTERPRISE_CREDIT_DISPUTE_DEV_NAME}).keySet();
	}

	/**
	* Retrieving AP recordtypes
	* */
	public static void retrieveAPRecordTypes(){
		apRecordTypes = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Case', 'SSSW').keySet();
	}

	/**
	 * Setting default enquiry types based on access level
	 *
	private static void setDefaultEnquiryType() {
		if(bspBaseUplift.hasSTBillingAccounts) {
			selectedEnquiryType = BspConstants.ENQUIRY_TYPE_ST;
		} else {
			selectedEnquiryType = BspConstants.ENQUIRY_TYPE_AP;
		}
	}/

		/**
	 * init to load default enquiry types, recordtypes and caselist
	 * */
	public static void initialLoadSetup(){
		//setDefaultEnquiryType();
		retrieveRecordTypes();
		retrieveAPRecordTypes();
		retrieveCreditClaimRecordTypes();
		displayCaseList();
	}

		/**
	 * retrive the case list with offset
	 * */
	@AuraEnabled(cacheable=true)
	public static SerchResultsWrapper retrieveDisplayCaseList(EnquiryFilter enquiryFilter) {

		System.debug('Enquiry Filter >>>> ' +  enquiryFilter);

		isReqFromDownload = false;

		setFilterParams(enquiryFilter);
		initialLoadSetup();

		SerchResultsWrapper sWrapper = new SerchResultsWrapper();
		sWrapper.totalSearchCount = totalSearchRecordCount;
		sWrapper.paginatedSearchResults = allCaseSearchRecords;
		return  sWrapper;
	}

	/**
	 * get the cases to download  with the given column filters
	 * */
	@AuraEnabled(cacheable=true)
	public static DownloadResultsWrapper downloadCaseDetails(EnquiryFilter enquiryFilter) {

		isReqFromDownload = true;

		setFilterParams(enquiryFilter);
		initialLoadSetup();

		DownloadResultsWrapper dw = new DownloadResultsWrapper();
		dw.caseDetails = downloadCaseDetails;
		dw.isAPUser = bspBaseUplift.isAPUser;
		return dw;
	}

	/**
	 * Sets all the static variables for the filtering enquiries
	 * */
	private static void setFilterParams(EnquiryFilter ef){

		System.debug('EnquiryFilter >>> ' + ef);

		if(!String.isBlank(ef.pageNumber)){
			dynamicPageNumber = Integer.valueOf(ef.pageNumber);
		}

		if(!String.isBlank(ef.searchStr)){
			searchText = ef.searchStr;
		}
		if(!String.isBlank(ef.pageSize)){
			dynamicPageSize = Integer.valueOf(ef.pageSize);
		}
		if(!String.isBlank(ef.orgOption)){
			indOrgEnquiryFlag= ef.orgOption;
		}
		if(!String.isBlank(ef.billingAccOption)){
			selectedBillingAccount= ef.billingAccOption;
		}
		if(ef.fromDate != null){
			dummyEnq1.Start_Date__c= ef.fromDate;
		}
		if(ef.toDate != null ){
			dummyEnq1.End_Date__c= ef.toDate;
		}
		if(!String.isBlank(ef.status)){
			caseRecStatus= ef.status;
		}
		if(!String.isBlank(ef.sortByColumn)){
			bspEnquiryUplift.sortByColumnApiName= ef.sortByColumn;
		}
		if(!String.isBlank(ef.sortByOrder)){
			bspEnquiryUplift.sortByOrder= ef.sortByOrder;
		}
		if(!String.isBlank(ef.sortByOrder)){
			bspEnquiryUplift.sortByOrder= ef.sortByOrder;
		}
		if(!String.isBlank(ef.enquiryType)){
			selectedEnquiryType = ef.enquiryType;
		}else{
			selectedEnquiryType = getUserBillingAccountScope();
		}
	}

		/**
	 * get the cases to download  with the given column filters
	 * */
	@AuraEnabled(cacheable=true)
	public static String getUserBillingAccountScope(){
		return bspBaseUplift.userBillingAccountScope;
	}

	/**
	* Get the cases from CaseContainer and return the caselist
	* */
	public static  List<Case> retrieveSelectedCases(List<CaseContainer> caseContainerList) {
		List<Case> selectedCases = new List<Case>();
		for (CaseContainer cc : caseContainerList) {
			if (cc.isSelected && !BspConstants.CASE_STATUS_CLOSED.equals(cc.caseObj.Status)) {
				selectedCases.add(cc.caseObj);
			}
		}
		return selectedCases;
	}

	/**
	* Get the suucess message to display after successfull creation of starttrack delivey and pickup book enquiry
	* */
	@AuraEnabled(cacheable=true)
	public static String getSTEnquiryCreationSuccessBodyText(){
		return bspBaseUplift.successMessage;
	}

	/**
	* Get looged in user primary billing account number
	* */
	@AuraEnabled(cacheable=true)
	public static String getUserPrimaryBillingNumber(){
		if(!bspBaseUplift.isMpbHspFlag) {
			return  bspBaseUplift.getLoggedInUser().Contact.BillingAccount__r.LEGACY_ID__c;
		} else {
			return '';
		}
	}

	/**
	* build dropdown options for org field to serach for enquires in home page
	* */
	@AuraEnabled(cacheable=true)
	public static List<SelectOptionCustom> getIndOrgPicklist() {
		List<SelectOptionCustom> options = new list<SelectOptionCustom>();
		options.add(new SelectOptionCustom(BspConstants.SELECT_OPTION_VALUE_ALL_ORG_ENQ, BspConstants.SELECT_OPTION_LABEL_ALL_ORG_ENQ));
		options.add(new SelectOptionCustom(BspConstants.SELECT_OPTION_VALUE_MY_ENQ, BspConstants.SELECT_OPTION_LABEL_MY_ENQ));
		return options;
	}

	/**
	* Get constants
	* */
	@AuraEnabled(cacheable=true)
	public static BSPEnquiryConstants getAllConstants() {
		return new BSPEnquiryConstants();
	}

	/**
	* Get the page size options (to display in bsp community home page to select the page for displaying case list)
	* */
	@AuraEnabled(cacheable=true)
	public static List<SelectOptionCustom> getDynamicPageSizePicklist() {
		List<SelectOptionCustom> options = new list<SelectOptionCustom>();
		options.add(new SelectOptionCustom(BspConstants.SELECT_OPTION_VALUE_5_ENQ, BspConstants.SELECT_OPTION_LABEL_5_ENQ));
		options.add(new SelectOptionCustom(BspConstants.SELECT_OPTION_VALUE_10_ENQ, BspConstants.SELECT_OPTION_LABEL_10_ENQ));
		options.add(new SelectOptionCustom(BspConstants.SELECT_OPTION_VALUE_15_ENQ, BspConstants.SELECT_OPTION_LABEL_15_ENQ));
		options.add(new SelectOptionCustom(BspConstants.SELECT_OPTION_VALUE_20_ENQ, BspConstants.SELECT_OPTION_LABEL_20_ENQ));
		return options;
	}

	/**
	 * Get startrack delivery record type
	 * */
	@AuraEnabled(cacheable=true)
	public static Id getSTDeliveyEnquiryRecordType() {
		return Schema.SObjectType.Case.getRecordTypeInfosByName().get(BspConstants.CASE_RECORD_TYPE_DELIVERY_ENQUIRY).getRecordTypeId();
	}

		/**
	 * Get startrack pickupbook enquiry record type
	 * */
	@AuraEnabled(cacheable=true)
	public static Id getSTPickupBookingRefRecordType() {
		return Schema.SObjectType.Case.getRecordTypeInfosByName().get(BspConstants.CASE_RECORD_TYPE_PICKUP_BOOKING_ENQUIRY).getRecordTypeId();
	}

	//Added by David Catindoy (March 22, 2017) - Get all the list of BSP Case Status values and put it as an option in the filter.
	@AuraEnabled(cacheable=true)
	public static List<SelectOptionCustom> getStatusList() {
		List<SelectOptionCustom> options = new list<SelectOptionCustom>();
		options.add(new SelectOptionCustom('', BspConstants.PICKLIST_VALUE_DEFAULT_All_STATUS));
		if(String.isNotBlank(bspBaseUplift.configSetting.BSPCaseStatusList__c)){
			for(String caseStat : bspBaseUplift.configSetting.BSPCaseStatusList__c.split(',')){
				options.add(new SelectOptionCustom(caseStat, caseStat));
			}
		}
		return options;
	}

		/**
	 * Get all accessible Billing Accounts as picklist optios to display in LWC
	 * */
	@AuraEnabled(cacheable=true)
	public static List<SelectOptionCustom> getAllBillingAccounts() {
		List<SelectOptionCustom> options = new list<SelectOptionCustom>();
		options.add(new SelectOptionCustom('', BspConstants.SELECT_OPTION_LABEL_ALL_BILL_ACCOUNT));
		options.addAll(buildAllBillingAccountOptions());
		/*for (Integer i = 0; i < bspBaseUplift.accessibleBillingAccounts.values().size(); i++) {
			Billing_Account__c billingAccount = bspBaseUplift.accessibleBillingAccounts.values()[i];
			// assign the value with a separator, so that we can use the values for the SOQL (SF ID and Legacy ID)
			options.add(new SelectOptionCustom(billingAccount.id + '&' + billingAccount.LEGACY_ID__c, billingAccount.LEGACY_ID__c + ' (' + billingAccount.Name + ')'));
		}*/

		return options;
	}

		/**
	 * Get all accessible Billing Accounts for reporting
	 * */
	@AuraEnabled(cacheable=true)
	public static List<SelectOptionCustom> getAllBillingAccountsForReports() {
		List<SelectOptionCustom> options = new list<SelectOptionCustom>();
		options.add(new SelectOptionCustom( 'all', BspConstants.SELECT_OPTION_LABEL_ALL_BILL_ACCOUNT_REPORTS));
		options.addAll(buildAllBillingAccountOptions());
		return options;
	}

	private static List<SelectOptionCustom> buildAllBillingAccountOptions(){
			List<SelectOptionCustom> options = new list<SelectOptionCustom>();
			for (Integer i = 0; i < bspBaseUplift.accessibleBillingAccounts.values().size(); i++) {
			Billing_Account__c billingAccount = bspBaseUplift.accessibleBillingAccounts.values()[i];
			// assign the value with a separator, so that we can use the values for the SOQL (SF ID and Legacy ID)
			options.add(new SelectOptionCustom(billingAccount.id + '&' + billingAccount.LEGACY_ID__c, billingAccount.LEGACY_ID__c + ' (' + billingAccount.Name + ')'));
		}

		return options;
	}

	/**
	 * Build billing account options without the Prefix for legacy id (number only)
	 * @return
	 */
	@AuraEnabled(cacheable=true)
	public static List<SelectOptionCustom> buildBillingAccountOptions(){
		List<SelectOptionCustom> options = new list<SelectOptionCustom>();
		for (Integer i = 0; i < bspBaseUplift.accessibleBillingAccounts.values().size(); i++) {
			Billing_Account__c billingAccount = bspBaseUplift.accessibleBillingAccounts.values()[i];
			// assign the value with a separator, so that we can use the values for the SOQL (SF ID and Legacy ID)
			options.add(new SelectOptionCustom(billingAccount.id , billingAccount.LEGACY_ID__c.replaceAll('[a-zA-Z]', '') + ' - ' + billingAccount.Name, billingAccount.Source_System__c));
		}
		return options;
	}

	/**
	 * get the help text custom metadata by label
	 * @return help text custom metadata by label
	 */
	@AuraEnabled(cacheable=true)
	public static Map<String, Picklist_Entry_Helptext__mdt> buildReasonForClaimHelpText(){
		Map<String, Picklist_Entry_Helptext__mdt> reasonDescriptionMap = new Map<String, Picklist_Entry_Helptext__mdt>();
		for (Picklist_Entry_Helptext__mdt reason : bspBaseUplift.creditClaimReasonHelpTexts) {
			String key = reason.Label+'_'+reason.BusinessUnit__c;
			reasonDescriptionMap.put(key.replaceAll('\\s+', '').toLowerCase(), reason);
		}
		return reasonDescriptionMap;
	}

	/**
	 * Get Related To filter for AP vs StarTrack enquiries
	 * */
	//Added by David Catindoy (March 22, 2017) - StarTrack method that creates a Related To filter on the fly.
	@AuraEnabled(cacheable=true)
	public static List<SelectOptionCustom> getRelatedToList() {
		List<SelectOptionCustom> options = new list<SelectOptionCustom>();
		options.add(new SelectOptionCustom('', BspConstants.SELECT_OPTION_LABEL_ALL_TYPE_ENQ));
		options.add(new SelectOptionCustom(BspConstants.AUTH_SCOPE_ST, BspConstants.ACCOUNT_TYPE_STARTRACK));
		options.add(new SelectOptionCustom(BspConstants.AUTH_SCOPE_AP, BspConstants.ACCOUNT_TYPE_AUSPOST));
		return options;
	}

	/**
	 * In the Springboard project, we want to display the labels of picklist values in the UI instead of the picklist value API names.
	 * Rather than modifying the API names themselves, this method will retrieve and use the label values for display in the UI.
	 * @param fieldName picklist field API name
	 *
	 * @return map of API name to labels picklist values
	 */
	@AuraEnabled(cacheable=true)
	public static Map<String, String> getCasePicklistValuesByFieldName(String fieldName) {
		return getPicklistValues(Case.SObjectType, fieldName);
	}

	/**
	 * Read the pick list values using object and the field api names
	 * @param sObjectType object name to retrive the picklist values
	 * @param fieldName API name of the picklist field
	 *
	 * @return map of API name to labels picklist values
	 */
	public static Map<String, String> getPicklistValues(SObjectType sObjectType, String fieldName){
		Map<String, String> picklistValuesMap = new Map<String, String>();

		Schema.DescribeFieldResult fieldResult = sObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();

		if (fieldResult.getType() == Schema.DisplayType.PICKLIST) {
			List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

			for (Schema.PicklistEntry picklistEntry : picklistValues) {
				picklistValuesMap.put(picklistEntry.getValue(), picklistEntry.getLabel());
			}
		} else {
			// Handle if the field is not a picklist (optional)
			System.debug('Field ' + fieldName + ' is not a picklist.');
		}

		return picklistValuesMap;
	}

	/**
	 * What it is: method called by the bspFormAPEnquiry LWC to create a Case on submit
	 * What it does:
	 *  - Creates a Case record with the details passed in from the 'enq' parameter
	 *  - Relates the Files to the Case with ContentDocumentLinks
	 * Why: Create an AusPost Enquiry from the BSP community
	 * @param enq a Case object passed in from bspFormAPEnquiry lwc
	 * @param uploadedFiles a list of uploaded Files for this enquiry
	 *
	 * @return an enquiryWrapper with the newly created Case Id and Number. The LWC can then display a link to the
	 * Case Details.
	 */
	public static CreateEnquiryWrapper createEnquiryAusPost(Case enq, List<Map<String, String>> uploadedFiles) {
		return createEnquiryAusPost(enq, uploadedFiles, null);
	}

	/**
	 * What it is: method called by the bspFormAPEnquiry LWC to create a Case on submit
	 * What it does:
	 *  - Creates a Case record with the details passed in from the 'enq' parameter
	 *  - Relates the Files to the Case with ContentDocumentLinks
	 * Why: Create an AusPost Enquiry from the BSP community
	 * @param enq a Case object passed in from bspFormAPEnquiry lwc
	 * @param uploadedFiles a list of uploaded Files for this enquiry
	 * @param additionalData a wrapper object what contains containsEssentialMedicine and isSentimental value of 'yes' or 'no' passed from the bspFormAPEnquiry LWC
	 *
	 * @return an enquiryWrapper with the newly created Case Id and Number. The LWC can then display a link to the
	 * Case Details.
	 */
	@AuraEnabled
	public static CreateEnquiryWrapper createEnquiryAusPost(Case enq, List<Map<String, String>> uploadedFiles, BSPFormAdditionalData additionalData) {
		if (additionalData == null) {
			additionalData = new BSPFormAdditionalData();
			additionalData.containsEssentialMedicine = 'no';
			additionalData.isSentimental = 'no';
		}
		additionalData.containsEssentialMedicine = additionalData.containsEssentialMedicine == null ? 'no' : additionalData.containsEssentialMedicine;
		additionalData.isSentimental = additionalData.isSentimental == null ? 'no' : additionalData.isSentimental;

		// return object
		CreateEnquiryWrapper enquiryWrapper = new CreateEnquiryWrapper();

		// grab settings from Custom Setting
		String generalRecordTypeId = bspBaseUplift.configSetting.GeneralRecordTypeId__c;
		String deliveryRecordTypeId = bspBaseUplift.configSetting.DeliveryRecordTypeId__c;
		String enqType = (string.isNotBlank(enq.CCUEnquiryType__c) ? enq.CCUEnquiryType__c.toLowerCase():'');

		Map<String,BSPMappings__c> bspMappings = BSPMappings__c.getAll();

		// reinstating the permissions check here
		if(!bspBaseUplift.hasAPBillingAccounts && !bspBaseUplift.canSearchAllConsignments) {
			// early out
			enquiryWrapper.status = STATUS_ERROR;
			enquiryWrapper.message = ERROR_MESSAGE_CANNOT_CREATE;
			return enquiryWrapper;
		}

		if(enqType == BspConstants.ENQUIRY_TYPE_GENERAL_ENQUIRY || enqType == BspConstants.ENQUIRY_TYPE_BULK_UPLOAD || enqType == BspConstants.ENQUIRY_TYPE_MAIL_REDIRECTION_HOLD) {
			enq.RecordTypeId = generalRecordTypeId;
			enq.CCUServiceUsed__c = null;
			//Initializing the from block for General enquiry.
			initialiseFromBlock(enq);
		} else {
			enq.RecordTypeId = deliveryRecordTypeId;
		}

		if(!bspMappings.isEmpty()){
			enq.EnquirySubType__c = bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).CaseEnquirySubType__c;
			enq.Type = bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).CaseType__c;
			if (enq.Type.equalsIgnoreCase(BspConstants.ENQUIRY_TYPE_GENERAL_ENQUIRY)) { // set the Type_and_Product__c field according to the enq.Type
				enq.Type_and_Product__c = ChasConstants.GENERAL_ENQUIRY_PLUS_DOMESTIC_PARCELS_PLUS_METRO;
			} else if (enq.Type.equalsIgnoreCase(BspConstants.ENQUIRY_TYPE_FEEDBACK)) {
				enq.Type_and_Product__c = ChasConstants.FEEDBACK_AND_DOMESTIC_PARCELS_AND_METRO;
			} else if (enq.Type.equalsIgnoreCase(BspConstants.ENQUIRY_TYPE_INVESTIGATION)) {
				enq.Type_and_Product__c = ChasConstants.INVESTIGATION_AND_DOMESTIC_PARCELS_METRO;
			}

			if(enqType == BspConstants.ENQUIRY_TYPE_GENERAL_ENQUIRY || enqType == BspConstants.ENQUIRY_TYPE_BULK_UPLOAD || enqType == BspConstants.ENQUIRY_TYPE_MAIL_REDIRECTION_HOLD){
				enq.ProductCategory__c = bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).CaseProductCategory__c; // INC0609073 ref Product Category to custom setting
				enq.ProductSubCategory__c = bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).caseProductSubCategory__c; // INC0609073 ref Product Sub Category to custom setting
			}
		}

		enq.ContactId = bspBaseUplift.loginContactId;

		// If user searched for Consignment and tried to created General Enquiry, then null the Article and Type
		if(enqType == BspConstants.ENQUIRY_TYPE_GENERAL_ENQUIRY) {
			enq.ArticleType__c = null;
			enq.ArticleTest__c = null;
		}
		if(enq.ArticleType__c != null) {
			String serviceType = enq.ArticleType__c.toLowerCase();
			if(serviceType.contains(BspConstants.KEYWORD_PARCEL)) {
				if(enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_ECONOMY) || enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_INTERNATIONAL)||enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_ECI) ||enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_GLOBAL)) {
					enq.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_INT_PARCELS;
				} else {
					enq.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_DOM_PARCELS;
				}
			} else if(serviceType.contains(BspConstants.KEYWORD_LETTER)) {
				if(enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_INTERNATIONAL) || enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_ECI) || enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_GLOBAL)) {
					enq.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_INT_LETTERS;
				} else {
					enq.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_DOM_LETTERS;
				}
			}
		}
			Set<SObjectField> articleFields = new Set<SObjectField>{
				Article__c.TrackingID__c, Article__c.ProductCategory__c, Article__c.SubProduct__c
		};
		Map<Id, Article__c>  articles = ArticlesSelector.newInstance(1,articleFields).selectByTracking(new Set<String>{enq.ReferenceID__c},true);

		if(!String.isBlank(enq.CCUServiceUsed__c)){
			if(!bspMappings.isEmpty()){
				if(enq.CCUServiceUsed__c== BspConstants.NEXT_FLIGHT_PREM_EXPRESS) {
					enq.ProductSubCategory__c = BspConstants.NEXT_FLIGHT_PREM_EXPRESS;
				} else {
					enq.ProductSubCategory__c = bspMappings.get(enq.CCUServiceUsed__c.toLowerCase()).CaseProductSubcategory__c;
				}
			}
			if(articles != null){
				for(Article__c article:articles.values()) {
					if(article.SubProduct__c == BspConstants.BSP_PREMIUM_RETURN_EXPRESS ||
							article.SubProduct__c == BspConstants.BSP_PREMIUM_EXPRESS_RETURN_SIGNATURE ||
							article.SubProduct__c == BspConstants.BSP_PREMIUM_EXPRESS_SIGNATURE ||
							article.SubProduct__c == BspConstants.BSP_PREMIUM_EXPRESS_PARCEL
							) {

						enq.ProductSubCategory__c = bspMappings.get(article.SubProduct__c.toLowerCase()).CaseProductSubcategory__c;
					}
				}
			}
		}


		// this should be passed in
		//enq.DescriptionOfContents__c = descofcontents;
		enq.Origin = BspConstants.CASE_ORIGIN_BSP;
		enq.Subject = getUIMappedEnquiryType(enq.CCUEnquiryType__c);
		enq.CaseOriginator__c = 'Sender'; // REQ2048088: All new BSP cases to have Sender has Originator

		//Fill Primary Information.
		enq.PrimaryAccount__c = enq.BSP_Sender_Company__c;
		List<String> senderName = String.isNotBlank(enq.BSP_Sender_Name__c) ? enq.BSP_Sender_Name__c.split(' ') : new List<String>();
		if(!senderName.isEmpty()){
			enq.PrimaryContactFirstname__c = senderName[0];
			enq.PrimaryContactLastname__c = senderName.size() > 1 ? senderName[1] : '';
			enq.PrimaryContactName__c = enq.BSP_Sender_Name__c;
		}

		//Fill Secondary Information.
		enq.SecondaryAccount__c = enq.BSP_Addressee_Company__c;
		List<String> receiverName = String.isNotBlank(enq.BSP_Addressee_Name__c) ? enq.BSP_Addressee_Name__c.split(' ') : new List<String>();
		if(!receiverName.isEmpty()){
			enq.SecondaryContactFirstName__c = receiverName[0];
			enq.SecondaryContactLastName__c = receiverName.size() > 1 ? receiverName[1] : '';
			enq.SecondaryContactName__c = enq.BSP_Addressee_Name__c;
		}

		enq.DatePosted__c = enq.BSPLodgementDate__c;
		// Gunith: When a Case is created from BSP, the Case should always be routed if EDD+ business days rule is met
		enq.AllocateToQueue__c = true;
		if(enq.CCUEnquiryType__c == BspConstants.ENQUIRY_SUBTYPE_MISSING_ITEM
			&& enq.EstimatedDelivery__c != null 
			&& additionalData.containsEssentialMedicine.equalsIgnoreCase('no') && additionalData.isSentimental.equalsIgnoreCase('no')) {
			Map<Id, Article__c> savedArticles = ArticlesSelector.newInstance().selectByIdOrTracking(new Set<String>{enq.ReferenceID__c}, new Set<Id>{}, new Set<Object>{}, true);

			for(Article__c article : savedArticles.values()) {
				if(article.Articles__r != null && article.Articles__r.size() == 1) {
					enq.EstimatedDelivery__c = article.Articles__r[0].ExpectedDeliveryDate__c;
				}
			}
			setDirectRoutingValues(enq);
		}
		enq = createEnquiryAusPostFinalise(enq, enquiryWrapper, additionalData);
		if(enq != null){
			// link any files
			bspBaseUplift.insertFiles(enq.Id, uploadedFiles);
			enquiryWrapper.status = STATUS_OK;
			enquiryWrapper.enquiry = enq;
			enquiryWrapper.message = '';
		}

		return enquiryWrapper;
	}

	/**
	 * What it is: final steps in creating an AusPost enquiry.
	 *  This will be called direct from createEnquiryAusPost if no reference ID was entered when creating the
	 *  enquiry or after the SAP EM search concludes when a reference ID was passed in.
	 *  (Only if the search was successful and the user has access to create the enquiry
	 * What it does: Inserts a Case Comment using the Case Description
	 *  Adds a status and message to the enquiryWrapper
	 * Why: Separates the Case Comment insertion
	 * @param enq The created Case from BSP community
	 * @param enqWrapper the wrapper to store any status and messages
	 * @param containsEssentialMedicine a string value of 'yes' or 'no from the BSP LWC form'
	 *
	 * @return the Case passed in, or null if there was an error
	 */
	public static Case createEnquiryAusPostFinalise(Case enq, bspEnquiryUplift.CreateEnquiryWrapper enqWrapper, BSPFormAdditionalData additionalData) {
		SavePoint sp = Database.setSavepoint();
		Boolean isDmlError = false;

		try {
			insert enq;

			if(!String.isEmpty(enq.Description)) {
				String commentBody = '---Enquiry Details---' + SSSWConstants.NEW_LINE + enq.Description;
				if (additionalData.containsEssentialMedicine != null && additionalData.containsEssentialMedicine.deleteWhitespace() != '') {
					commentBody += SSSWConstants.NEW_LINE + 'Does the item contain essential medication : ' + additionalData.containsEssentialMedicine;
				}
				if (additionalData.isSentimental != null && additionalData.isSentimental.deleteWhitespace() != '') {
					commentBody += SSSWConstants.NEW_LINE + 'Is the item urgent, sentimental or high value? : ' + additionalData.isSentimental;
				}
				CaseComment myComment = new CaseComment(ParentId=enq.Id, CommentBody=commentBody,  IsPublished=true);
				insert myComment;
			}

			Case newCase = [SELECT Id, CaseNumber FROM Case WHERE Id =: enq.Id LIMIT 1];
			return newCase;
		} catch (System.DmlException ex) {
			enqWrapper.status = STATUS_ERROR;
			enqWrapper.message = ex.getDmlMessage(0);
			Database.rollback(sp);
		} catch(Exception ex) {
			enqWrapper.status = STATUS_ERROR;
			enqWrapper.message = ex.getMessage();
			System.debug('Exception >>> ' + ex);
			System.debug('xxx Exception caught - insert enq '+ex.getMessage()+' at line '+ex.getstacktraceString());
			Database.rollback(sp);
		}
		return null;
	}

	/**
	 *  This method returns the mapped UI values of missing item to missing parcel for Enquiry List Grid on home page.
	 */
	@TestVisible
	private static String getUIMappedEnquiryType(String enquiryType){
		switch on enquiryType.toLowerCase() {
			when 'missing item' {
				return 'Missing Parcel';
			}
			when else {
				return enquiryType;
			}
		}
	}

	/**
	 * After querying an article, we use this to retrieve the billing account that should be associated with the case that is being created
	 */
	@TestVisible
	private static List<String> matchBillingAccount(Article__c article) {
		if(article != null && article.Billing_Account__r != null && String.isNotEmpty(article.Billing_Account__r.Id) && String.isNotEmpty(article.Billing_Account__r.LEGACY_ID__c)) {
			return new List<String>{article.Billing_Account__r.Id, article.Billing_Account__r.LEGACY_ID__c};
		} else {
			return null;
		}
	}

	/**
	 * Initializing the from block for General enquiry
	 * */
	private static void initialiseFromBlock(Case enq) {
		// initialise from you flag
		fromWhoRadio = BspConstants.SELECT_OPTION_VALUE_YOU;


		if(bspBaseUplift.loginUser != null) {
			enq.PrimaryAccount__c = bspBaseUplift.loginUser.CompanyName;
			enq.PrimaryContactFirstname__c = bspBaseUplift.loginUser.Firstname;
			enq.PrimaryContactLastname__c = bspBaseUplift.loginUser.Lastname;

			// 15/04 (NM) - Fix for From Address for MyPost Business
			if (bspBaseUplift.isMpbHspFlag == false) {
				fromAddress = new AddressExtension(bspBaseUplift.loginUser.Street, '', bspBaseUplift.loginUser.City, bspBaseUplift.loginUser.State, bspBaseUplift.loginUser.PostalCode, bspBaseUplift.loginUser.DPID__c, bspBaseUplift.loginUser.Country);
			} else {
				fromAddress = new AddressExtension(null, null, null, null, null, null, 'Australia');
			}

			enq.BSP_Sender_Name__c = (enq.PrimaryContactFirstname__c != null ? enq.PrimaryContactFirstname__c + ' ' : '') + (enq.PrimaryContactLastName__c != null ? enq.PrimaryContactLastName__c : '');
			enq.BSP_Sender_Company__c = (enq.PrimaryAccount__c != null ? enq.PrimaryAccount__c : '');
		}
	}

	/*
	@TestVisible
	private void initialiseToBlock() {
		if(articleFromConsignSearch != null){
			toAddress = new AddressExtension(articleFromConsignSearch.ReceiverAddressLine1__c, articleFromConsignSearch.ReceiverAddressLine2__c, articleFromConsignSearch.ReceiverCity__c, articleFromConsignSearch.ReceiverState__c,
					articleFromConsignSearch.ReceiverPostcode__c, '', articleFromConsignSearch.ReceiverCountryName__c);
		} else{
			toAddress = new AddressExtension(null, null, null, null, null, null, 'Australia');
		}
	}*/

	/**
	 * Returns a list of cases for the logged in user based on the level of access they have
	 * This covers both MPB and BSP.
	 *
	 * Access Roles breakdown for BSP users
	 * 1. Role of Admin will gain visibility over billing accounts assigned to that Role
	 * 2. Role of Super Admin will gain visibility over all billing accounts
	 * 3. Role of User / Super User is not considered in case visibilitiy
	 *
	 * NOTE: it's important to note that the only roles we need to consider for case visibility for admin based roles
	 *  by default, when a user role is applied to BSP, it simply implies access to 'my cases' which is the default behaviour of a basic BSP user irrespective of role
	 */
	public static void displayCaseList() {
		Map<Id, Case> searchedCaseMap = new Map<Id, Case>();
		List<Case> searchedCaseList = new List<Case>();
		List<String> excludecaseTypes = bspBaseUplift.excludecaseTypeslist;
		List<String> excludecasePurpose = bspBaseUplift.excludecasePurposelist;

		if(bspBaseUplift.loginContactId != null) {
			Boolean soslHasError = false;

			List<String> queries = new List<String>();

			// use this to grab the accessible entities in their respective role
			// these are used to determine the cases that are returned in the query
			Map<String, Set<Id>> mappedEntities = bspBaseUplift.getLinkedEntitiesByRole(bspBaseUplift.accessRules);

			// Hasantha : 28/02/2019 this is to filter based on the billing account filter
			String billingAccountSelected = '';
			if(!String.isEmpty(selectedBillingAccount)) {
				String [] billingAccount = selectedBillingAccount.split('&');
				billingAccountSelected = ' Related_Billing_Account__c = \'' + billingAccount[0] + '\' ';
			}

			// Ankur G : 19/08/2020 - Moved where clause generation part to private static method.
			string queryWhere = getSearchEnquiriesWhereClause(mappedEntities, billingAccountSelected);

			List<String> fields = new List<String>{
					'Id', 'CaseNumber', 'CreatedDate', 'ArticleTest__r.Name', 'ArticleTest__r.ArticleID__c', 'RecordType.DeveloperName', 'Status',
					'CaseDetails__c', 'Subject', 'Permanent_Close__c', 'Secondary_Contact__c', 'Article_Receiver_Name__c', 'StarTrack_RecordType__c',
					'BSP_Addressee_Name__c', 'Contact.Account.Name', 'Billing_Number__c', 'Related_Billing_Account__c',
					'Related_Billing_Account__r.LEGACY_ID__c', 'Related_Billing_Account__r.Name', 'Business_Unit__c','LastModifiedDate','Enquiry_Status__c'
			};

			System.debug('searchText===' + searchText  + '>>');
			System.debug('queryWhere===' + queryWhere  + '>>');
			if(String.isNotEmpty(searchText)) {

				String queryToGetCount = 'Find \'' + String.escapeSingleQuotes(searchText) + '\' ' +
					'Returning Case (' + String.join(fields, ', ') + ' ' + queryWhere+')';
				try {
					List<Case> totatlCases = (List<Case>)Search.query(queryToGetCount)[0] ;
					if(totatlCases !=null) totalSearchRecordCount = totatlCases.size();
				}catch(Exception ex) {
					System.debug('ex=>'+ex);
				}

				String query = 'Find \'' + String.escapeSingleQuotes(searchText) + '\' ' +
					//'Returning Case (' + String.join(fields, ', ') + ' ' + whereQuery + ' Order By CaseNumber Desc)';
					'Returning Case (' + String.join(fields, ', ') + ' ' + queryWhere
					+ ' Order By '+sortByColumnApiName+' '+sortByOrder+' ' ;
				if(!isReqFromDownload) //[Jansi:Added OFFSET and LIMIT]
					query = query +'LIMIT '+dynamicPageSize+' OFFSET '+dynamicPageSize*(dynamicPageNumber-1);

				query= query+')';
				try {
					searchedCaseMap.putAll((List<Case>)Search.query(query)[0]);
				} catch(Exception ex) {
					// when entered less than 2 characters, SOSL will through error.
					soslHasError = true;
					System.debug('SOSL Error: ' + ex);
				}
			} else {
				String query = 'Select ' + String.join(fields, ', ') + ' ' +
						'From Case ' + queryWhere + ' Order By ' + sortByColumnApiName + ' ' + sortByOrder;
						//'Order By CaseNumber Desc LIMIT 400';
				if(!isReqFromDownload)//[Jansi:Added OFFSET and LIMIT]
					query = query+' LIMIT ' + dynamicPageSize + ' OFFSET ' + dynamicPageSize*(dynamicPageNumber-1);

				List<Case> retrievedCases = (List<Case>)Database.query(query);

				string recordCountsQuery = 'Select count() from Case '+ queryWhere;
				totalSearchRecordCount = Database.countQuery(recordCountsQuery);

				searchedCaseMap.putAll(retrievedCases);

			}

			searchedCaseList = searchedCaseMap.values();
			if(soslHasError) {
				// display no result whenever there is SOSL error
				searchedCaseList = new List<Case>();
			} else {
				searchedCaseList = populateStarTrackCaseFields(searchedCaseList);
			}

		}

		allCaseSearchRecords = putListToContainer(searchedCaseList);
		// below mapping is to provide more readability to the code, and
		// some fields needs to be determined based on AP/ST user, and
		// value displayed for some fields such as Status needs to be determined based on the actual values
		List<Object> caseDetailsrecords = new List<Object>();
		for(Case cse : searchedCaseList){
			CaseDetails caseDetail = new CaseDetails();
			// common fields to display/download for bot ST and AP users
			caseDetail.EnquiryNo = cse.CaseNumber;
			caseDetail.DateCreated = String.valueOf(cse.CreatedDate);
			caseDetail.Details = cse.Subject;
			caseDetail.SendingTo =  cse.BSP_Addressee_Name__c != null ? cse.BSP_Addressee_Name__c: cse.Secondary_Contact__c;
			caseDetail.Status = readStatus(cse);
			caseDetail.TrackingNo = cse.ArticleTest__r != null ? cse.ArticleTest__r.Name : '';
			// decide what to display based on the user type AP customers
			if(bspBaseUplift.isAPUser) {
				caseDetail.ArticleID = cse.ArticleTest__r != null ? cse.ArticleTest__r.ArticleID__c : '';
			}
			caseDetail.Updated = String.valueOf(cse.lastmodifiedDate);
			caseDetail.AccountNumber = cse.Related_Billing_Account__r.LEGACY_ID__c;
			caseDetail.AccountName = cse.Related_Billing_Account__r.Name;
			caseDetail.AccountHeldWith = cse.Business_Unit__c;
			caseDetailsrecords.add(caseDetail);
		}

		downloadCaseDetails = JSON.serialize(caseDetailsrecords);
	}

	//Method that generates the search enquiries query.
	private static string getSearchEnquiriesWhereClause(Map<String, Set<Id>> mappedEntities, String billingAccountSelected){
		// query all the ST cases based on the roles and access of the logged in user
		// always run this query since there may be instances where cases have been raised by the current logged in user outside of what their accessible billing account scope is
		/*
		// Changed code to combine ST and AP Queries into 1 query.
		*/
		// building common roles clause for ST and AP to use in where clause
		String roleWhere = getRoleWhere(mappedEntities);
		/*  Building common where clause for ST and AP
			2020-10-28 Adding the selecteEnquiryType filter for AP and ST enquiries filteration
		*/
		String queryWhere = '';

		// get inquiry filtering
		queryWhere += getEnquiryTypeWhere();
		// general conditions which are not in UI filter
		queryWhere += getGenericWhere(queryWhere, roleWhere, billingAccountSelected);
		// use the user filters down to their own Cases only
		queryWhere += getOrganisationWhere();
		//Added by David Catindoy (March 22, 2017) - Used to add additional query clause for Created Date From filter.
		queryWhere += getDatesWhere();
		//Added by David Catindoy (March 22, 2017) - Used to add additional query clause for Status filter.
		queryWhere += getStatusWhere();
		queryWhere = (String.isNotEmpty(queryWhere) ? ' WHERE ' : '') + queryWhere;

		return queryWhere;
	}

	/**
	 * Get the status query string based on the selected status filter
	 * @return String query string
	 */
	private static String getStatusWhere() {
		String queryWhere = '';
		selectedStatuses = new Set<String>();

		if (String.isNotBlank(caseRecStatus)) {
			if (BspConstants.CASE_STATUS_ACTION.equals(caseRecStatus)) { //Validate if the status selected is "Action Required".
				selectedStatuses.add('Waiting on customer');
				selectedStatuses.add('Awaiting Customer Response');
				selectedStatuses.add('Under investigation - Awaiting responses');
				queryWhere += ' AND (Status IN: selectedStatuses) ';
			} else if (BspConstants.CASE_STATUS_RESOLVED.equals(caseRecStatus)) { //Validate if the status selected is "Resolved".
				selectedStatuses.add('Closed');
				selectedStatuses.add('Invalid');
				queryWhere += ' AND Status IN: selectedStatuses AND Permanent_Close__c = false ';
			} else if (BspConstants.CASE_STATUS_CLOSED.equals(caseRecStatus)) { //Validate if the status selected is "Closed".
				selectedStatuses.add('Closed');
				queryWhere += ' AND ((Status IN: selectedStatuses AND Permanent_Close__c = true) OR Subject = \'Bulk Upload\') ';
			} else if (BspConstants.CASE_STATUS_INPROGRESS.equals(caseRecStatus)) { //Validate if the status selected is "In Progress".
				selectedStatuses.add('Closed');
				selectedStatuses.add('Waiting on customer');
				selectedStatuses.add('Awaiting Customer Response');
				queryWhere += ' AND (Status NOT IN: selectedStatuses) ';
			}
		}

		return queryWhere;
	}

	/**
	 * Get the Dates query string based on the selected date filters
	 * @return String query string
	 */
	private static String getDatesWhere() {
		String queryWhere = '';
		if (String.isNotBlank(String.valueOf(dummyEnq1.Start_Date__c))) {
			startDate = dummyEnq1.Start_Date__c;
			queryWhere += ' AND DAY_ONLY(convertTimezone(CreatedDate)) >= :startDate ';
		}

		//Added by David Catindoy (March 22, 2017) - Used to add additional query clause for Created Date To filter.
		if (String.isNotBlank(String.valueOf(dummyEnq1.End_Date__c))) {

			endDate = dummyEnq1.End_Date__c;
			queryWhere += ' AND DAY_ONLY(convertTimezone(CreatedDate)) <= :endDate ';
		}
		return queryWhere;
	}

	/**
	 * Get the Organisation query string based on the selected Organisation filter : My enquiries
	 * @return String query string
	 */
	private static String getOrganisationWhere() {
		String queryWhere = '';
		if (BspConstants.SELECT_OPTION_VALUE_MY_ENQ.equals(indOrgEnquiryFlag)) {
			queryWhere += ' AND ( CreatedById = \'' + bspBaseUplift.loginUserId + '\' OR ContactId = \'' + bspBaseUplift.loginContactId + '\') ';
		}

		return queryWhere;
	}

	/**
	 * Get the general query string which are not included in UI filter
	 * @return String query string
	 */
	private static String getGenericWhere(String query, String roleWhere, String billingAccountSelected) {
		String queryWhere = '';
		queryWhere += (String.isNotEmpty(roleWhere) ? ' AND ( ' + roleWhere + ' ) ' : '');// TODO refactor?
		queryWhere += (((String.isNotEmpty(queryWhere) || String.isNotEmpty(query)) && String.isNotEmpty(billingAccountSelected)) ? ' AND ' : '') + billingAccountSelected;
		queryWhere += (String.isNotEmpty(queryWhere) || String.isNotEmpty(query) ? ' AND ' : '') + 'AccountId = \'' + bspBaseUplift.loginAccountId + '\'';
		queryWhere += (String.isNotEmpty(queryWhere) || String.isNotEmpty(query) ? ' AND ' : '') + 'IsChildCase__c = false';
		queryWhere += (String.isNotEmpty(queryWhere) || String.isNotEmpty(query) ? ' AND ' : '') + 'Origin = \'BSP\'';
		return queryWhere;
	}


	/**
	 * Get the filtering based on Startrack or AP
	 * @return String query string
	 */
	private static String getEnquiryTypeWhere() {
		String queryWhere = '';
		switch on selectedEnquiryType {
			when 'ST' {
				queryWhere += ' ( ((RecordTypeId IN : stRecordTypes ) OR (Business_Unit__c = \'StarTrack\' AND RecordTypeId IN : creditClaimRecordTypes )) AND Enquiry_Type__c NOT IN :excludeCaseTypes AND call_purpose__c NOT IN :excludeCasePurpose )';
			}
			when 'AP' {
				queryWhere += ' ( Subject <> \'' + bspBaseUplift.excludeSubject + '\' AND ((RecordTypeId IN : apRecordTypes ) OR ( Business_Unit__c = \'Australia Post\' AND RecordTypeId IN : creditClaimRecordTypes)))';
			}
			when else {
				queryWhere += ' ( ( ((RecordTypeId IN : stRecordTypes ) OR (Business_Unit__c = \'StarTrack\' AND RecordTypeId IN : creditClaimRecordTypes )) AND Enquiry_Type__c NOT IN :excludeCaseTypes AND call_purpose__c NOT IN :excludeCasePurpose )';
				queryWhere += ' OR ';
				queryWhere += ' (Subject <> \'' + bspBaseUplift.excludeSubject + '\' AND ((RecordTypeId IN : apRecordTypes ) OR ( Business_Unit__c = \'Australia Post\' AND RecordTypeId IN : creditClaimRecordTypes)) ))';
			}
		}
	/*		queryWhere += selectedEnquiryType == 'ALL' ? ' ( ' : '';
		queryWhere += (selectedEnquiryType == 'ST' || selectedEnquiryType == 'ALL') ? ' ( ((RecordTypeId IN : stRecordTypes ) OR (Business_Unit__c = \'StarTrack\' AND RecordTypeId IN : creditClaimRecordTypes )) AND Enquiry_Type__c NOT IN :excludeCaseTypes AND call_purpose__c NOT IN :excludeCasePurpose )' : '';
		queryWhere += selectedEnquiryType == 'ALL' ? ' OR ' : '';
		queryWhere += (selectedEnquiryType == 'AP' || selectedEnquiryType == 'ALL') ? ' ( Subject <> \'' + bspBaseUplift.excludeSubject + '\' AND ((RecordTypeId IN : apRecordTypes ) OR ( Business_Unit__c = \'Australia Post\' AND RecordTypeId IN : creditClaimRecordTypes)))' : '';
		queryWhere += selectedEnquiryType == 'ALL' ? ' )' : '';*/

		return queryWhere;
	}

	/**
	 * Get the query string based on the billing accounts accessible
	 * @return String query string
	 */
	private static String getRoleWhere(Map<String, Set<Id>> mappedEntities) {
		String roleWhere = '';
		if (mappedEntities.get('Super Admin') != null) {
			superAdminEntities = mappedEntities.get('Super Admin');
			roleWhere += (String.isNotEmpty(roleWhere) ? ' OR ' : '') + ' ( AccountId in :superAdminEntities ) ';
		}

		if (mappedEntities.get('Admin') != null) {
			adminEntities = mappedEntities.get('Admin');
			roleWhere += (String.isNotEmpty(roleWhere) ? ' OR ' : '') + ' ( (Related_Billing_Account__c != null And Related_Billing_Account__c IN :adminEntities) ' +
					' Or (Contact.BillingAccount__c != null And Contact.BillingAccount__c In :adminEntities) ) ';
		}
		if (!BspConstants.SELECT_OPTION_VALUE_MY_ENQ.equals(indOrgEnquiryFlag)) {
			roleWhere += (String.isNotEmpty(roleWhere) ? ' OR ' : '') +' ( CreatedById = \'' + bspBaseUplift.loginUserId + '\' OR ContactId = \'' + bspBaseUplift.loginContactId + '\') ';
		}
		return roleWhere;
	}

	/**
	 * read the status based on the criterias for display purposes,
	 * this logic is on the bspEnquiry Visual Force page as-well
	 *
	 * @param Case c
	 */
	private static String readStatus(Case c){
		if ('awaiting customer response'.equalsIgnoreCase(c.Status) || 'waiting on customer'.equalsIgnoreCase(c.Status) || 'Under investigation - Awaiting responses'.equalsIgnoreCase(c.Status)) {
			return 'Action Required';
		} else if (('closed'.equalsIgnoreCase(c.Status) && c.Permanent_Close__c) || 'Bulk Upload'.equalsIgnoreCase(c.Status)) {
			return c.status;
		} else if (('closed'.equalsIgnoreCase(c.Status) || 'Invalid'.equalsIgnoreCase(c.Status)) && !c.Permanent_Close__c) {
			return  'Resolved';
		} else {
			return 'In Progress';
		}
	}


	/*------------------------------------------------------------
	Author:Jen Karen Tan
	Description:   StarTrack method that populates Case's Billing_Number__c if blank.
					Value is retrieved from Related_Billing_Account__r.LEGACY_ID__c
	Inputs:List<Case>
	Returns:   List<Case>
	History:
	November 23, 2016 - Jen Karen Tan - Created
	------------------------------------------------------------*/
	private static List<Case> populateStarTrackCaseFields(List<Case> caseList) {
		for (Case c : caseList) {
			if (String.isBlank(c.Billing_Number__c)
					&& c.Related_Billing_Account__c != null
					&& !String.isBlank(c.Related_Billing_Account__r.LEGACY_ID__c)) {
				c.Billing_Number__c = c.Related_Billing_Account__r.LEGACY_ID__c;
			}
			if (c.StarTrack_RecordType__c) {
				c.BSP_Addressee_Name__c = c.Article_Receiver_Name__c;
			}
		}
		return caseList;
	}

	/*------------------------------------------------------------
	Author:Jen Karen Tan
	Description:   StarTrack method that will put Case List retrieved to a CaseContainer list
	Inputs:List<Case>
	Returns:   List<CaseContainer>
	History:
	January 9, 2017 - Jen Karen Tan - Created
	------------------------------------------------------------*/
	public static List<CaseContainer> putListToContainer(List<Case> cases) {
		List<CaseContainer> caseContainerList = new List<CaseContainer>();

		for (Case c : cases) {
			caseContainerList.add(new CaseContainer(c));
		}
		return caseContainerList;
	}

	/*------------------------------------------------------------
	Author:Jen Karen Tan
	Description:   StarTrack method that creates Enquiry
	History:
	October 12, 2016 - Jen Karen Tan - Created
	------------------------------------------------------------*/
	//[Jansi:] Added additional params after making method as Static   //TO DO: check this method can separate ST Deliry and ST pick enquiry creations as separate
	@AuraEnabled
	public static String  createEnquiry(Article__c currentArticle, Case enq, String consignmentNumber, Boolean notFound, Boolean duplicate, List<Map<String, String>> uploadedFiles, String billingAccountNumber ) {
		newCase = new Case();
		newCase.Status = StarTrack_Constants.CASE_STATUS_NEW;
		newCase.Priority = StarTrack_Constants.PRIORITY_NORMAL;
		newCase.Origin = BspConstants.CASE_ORIGIN_BSP;
		newCase.Call_Purpose__c = enq.Call_Purpose__c;
		newCase.Description = enq.Description;
		newCase.Subject = enq.Subject;
		newCase.CCUEnquiryType__c = enq.CCUEnquiryType__c;

		//StarTrack Delivery Enquiry Case
		if (BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
				//[Jansi:] recordType getting from method to have in a single place code
			Id deliveryEnqRT = getSTDeliveyEnquiryRecordType();
			newCase.RecordTypeId = deliveryEnqRT;
			if (notFound) {
				newCase.Subject = enq.Subject + ' ' + consignmentNumber + ' ( NOT FOUND )';
			} else if (duplicate) {
				newCase.Subject = enq.Subject + ' ' + consignmentNumber + ' ( DUPLICATE FOUND )';
			}

			// an article is not passed in when the consignment is not found or if a duplicate is found
			List<String> matchedBillingAccount = matchBillingAccount(currentArticle);
			if (currentArticle != null) {
				newCase.Subject = enq.Subject + ' - ' + currentArticle.Name;

				// find correct billing account to attach to the case which determines case visibility within BSP for other users
				if(matchedBillingAccount != null) {
					newCase.Related_Billing_Account__c = matchedBillingAccount[0];
					newCase.Billing_Number__c = matchedBillingAccount[1];
				}

				newCase.Related_Billing_Account__c = currentArticle.Billing_Account__c;
				newCase.ArticleTest__c = currentArticle.Id;
				newCase.Consignment_Unique_External_ID__c = currentArticle.ArticleID__c;

				currentConsignment = null;
			}
		}
		else if (BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY.equals(enq.CCUEnquiryType__c)){
			//StarTrack Pickup Booking Enquiry Case
			newCase.Pickup_Booking_Reference__c = enq.Pickup_Booking_Reference__c;
			//[Jansi:] recordType getting from method to have in a single place code
			Id pickupBookingRT = getSTPickupBookingRefRecordType();
			newCase.RecordTypeId = pickupBookingRT;

			List<Group> pckupBookingGroup = new List<Group>([SELECT Id, Name FROM Group WHERE Name =: BspConstants.PICKUP_BOOKING_QUEUE_NAME AND Type =: BspConstants.TYPE_QUEUE]);
			if (!pckupBookingGroup.isEmpty()) {
				newCase.OwnerId = pckupBookingGroup[0].Id;
			}

			newCase.ContactId = bspBaseUplift.loginContactId;

			// grab the billing account id of the number that was entered
			// the billing account number is only found if the current user has access to it.
			Billing_Account__c matchedBillingAccount = bspBaseUplift.accessibleBillingAccounts.get(getBillingAccountFromMap(billingAccountNumber));
			if (matchedBillingAccount != null) {
				newCase.Related_Billing_Account__c = matchedBillingAccount.Id;
				newCase.Billing_Number__c = matchedBillingAccount.LEGACY_ID__c;
			}
		}

		newCase.Recent_Caller_Email__c = bspBaseUplift.loginContact.Email;
		newCase.Recent_Caller_First_Name__c = bspBaseUplift.loginContact.FirstName;
		newCase.Recent_Caller_Last_Name__c = bspBaseUplift.loginContact.LastName;
		newCase.Recent_Contact_Mobile_Number__c = bspBaseUplift.loginContact.MobilePhone;
		newCase.Recent_Caller_Phone_Number__c = bspBaseUplift.loginContact.Phone;
		newCase.Recent_Caller_Type__c = StarTrack_Constants.CASE_CONTACT_TYPE_SENDER;
		newCase.Recent_Caller_Pref_Method_of_Contact__c = bspBaseUplift.loginContact.Pref_Method_of_Contact__c;

		//set Assignment Rules for StarTrack Delivery Enquiry
		if (!BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
			//Fetching the assignment rules on case
			AssignmentRule ar = [SELECT Id from AssignmentRule where SobjectType =: BspConstants.OBJ_CASE and Active = true limit 1];

			Database.DMLOptions dmlOpts = new Database.DMLOptions();
			dmlOpts.assignmentRuleHeader.assignmentRuleId= ar.id;

			//Setting the DMLOption on Case instance
			newCase.setOptions(dmlOpts);
		}

		try {
			Database.insert(newCase);
			// WHY IS THIS HERE!??
			calculateTransferCaseRule(newCase);
			//-- [Jansi: added below]
			if(uploadedFiles !=null){
				bspBaseUplift.insertFiles(newCase.Id, uploadedFiles);
			}
		} catch (DmlException e) {
		}

		newCase = [SELECT Id, CaseNumber FROM Case WHERE Id =: newCase.Id LIMIT 1];
		return newCase.CaseNumber;
	}

	/**
	 * StarTrack method that gets Billing Account with prefix P, T, or none from the map
	 * When checking for accessible billing account we search in order of the prefix'd account numbers just incase of collision's with non-prefixed billing account numbers
	 */
	public static Id getBillingAccountFromMap(String billingAcctNo) {
		//System.debug('accessibleBillingAccNumbers >>'+bspBaseUplift.accessibleBillingAccNumbers);
		Id billAcct = null;
		if (bspBaseUplift.accessibleBillingAccNumbers.get('P' + billingAcctNo) != null) {
			billAcct = bspBaseUplift.accessibleBillingAccNumbers.get('P' + billingAcctNo);
		} else if (bspBaseUplift.accessibleBillingAccNumbers.get('T' + billingAcctNo) != null) {
			billAcct = bspBaseUplift.accessibleBillingAccNumbers.get('T' + billingAcctNo);
		} else if (bspBaseUplift.accessibleBillingAccNumbers.get(billingAcctNo) != null) {
			billAcct = bspBaseUplift.accessibleBillingAccNumbers.get(billingAcctNo);
		}
		return billAcct;
	}


		/**
	 * validate the given consignment number with special charactes(fom custom setting) and return error message if contains a special character
	 * */
	@AuraEnabled(cacheable=true)
	public static String validateConsignmentNumber(String consignmentNumber){
		String errorMessage;
			for(String s : (Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SPECIALCHARS).Field_Name__c).split(StarTrack_Constants.SPECIALCHARS)){
				if(consignmentNumber.contains(s)){
					errorMessage = BspConstants.CON_NO_INVALID_CHAR_ERR + Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SPECIALCHARS).Field_Name__c;
					break;
				}
			}
		return errorMessage;
	}


		/**
	 * The method to create startrack pickupbook enquiry case and returns the created case number
	 * */
	@AuraEnabled
	public static String createPickUpBookingEnquiryStarTrack(String billingAccountNumber, Case enqObj, List<Map<String, String>> uploadedFiles) {
		String caseNumber;
		//check required fields
		if (enqObj.CCUEnquiryType__c.startsWith('StarTrack')) {  //&& validateFields()
			if (BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY.equals(enqObj.CCUEnquiryType__c)) {
				// check to see if the billing account number that was entered is accessible to the current user
				// the expected input from the user is the billing account without the 'T' or 'P' however we still support a billing account entered with a 'T' or 'P'
				// when checking for accessible billing account we search in order of the prefix'd account numbers just incase of collision's with non-prefixed billing account numbers
				Billing_Account__c matchedBillingAccount = bspBaseUplift.accessibleBillingAccounts.get(getBillingAccountFromMap(billingAccountNumber));
				if (matchedBillingAccount != null) {
					// only allow startrack billing accounts to be connected to Pickup booking cases
					if(bspBaseUplift.isBillingAccountST(matchedBillingAccount)) {
						caseNumber = createEnquiry(null, enqObj, null, false, false, uploadedFiles, billingAccountNumber);
					} else {
						throw new ErrorException(BSPErrorMessages__c.getValues('Invalid Case Billing Account') != null ? BSPErrorMessages__c.getValues('Invalid Case Billing Account').Message__c :
													'The Billing Account entered is not applicable for this type of case.');
					}
				} else {
					// either the billing account doesn't exist or the user does not have access to it
					throw new ErrorException('Billing Account ' + billingAccountNumber + ' is not valid.');
				}
			}
		}
		return caseNumber;
	}

	/**
	* The method to create startrack delivery enquiry  case and returns the created case number
	* */
	@AuraEnabled(continuation=true)
	public static String createDeliveryEnquiryStarTrack(String consignNumber, Case enqObj, STDeliveryEnquiryResultsWapper stWrapper, List<Map<String, String>> uploadedFiles) {
		String caseNumber;

		//-- Single consignment and no open case use case
		if(stWrapper.article !=null){
			caseNumber= createEnquiry(stWrapper.article, enqObj, consignNumber, false , false, uploadedFiles, null );
		}
		else{
			caseNumber= createEnquiry(null, enqObj, consignNumber, stWrapper.notFound!=null?stWrapper.notFound:false , stWrapper.duplicate!=null?stWrapper.duplicate:false , uploadedFiles, null);
		}
		return caseNumber;
	}
	// needed for test code coverage
	// Static Continuation Methods require a state object, but Test.invokeContinuation cannot pass in arguments,
	// therefore, store the state to pass in when testing.
	// The following methods are used for test injection.
	private static StateInfo dummyContState;
	public static Object processDeliveryEnquiryCreation()
	{
		return processDeliveryEnquiryCreation(dummyContState);
	}

	/**
	* Continuation method to search the Consignment number
	* */
	@AuraEnabled(continuation=true)
	public static Continuation searchConsignmentStarTrack(String consignNumber, Case enqObj) {
		enq = enqObj;
		consignmentNumber = consignNumber;

		//check required fields
		if (enq.CCUEnquiryType__c.startsWith('StarTrack')) {

			if (BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
				try {
					wwwAuspostComAuSchemaCustomercarema.SearchRequest request = BSPConsignmentSearchUtil.generateSearchRequest(consignmentNumber, BspConstants.CON_SEARCH_TYPE_CONSIGNMENT, StarTrack_Constants.REQUEST_ACTION_FULL);
					AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = BSPConsignmentSearchUtil.generateAsyncStub();
					Continuation cont = new Continuation(Integer.valueOf(bspBaseUplift.configSetting.StarTrackAsyncWebServiceTimeout__c));

					cont.continuationMethod = BspConstants.METHOD_PROCESS_DELIVERY_ENQ;
					//added dummyContState logic to ensure code coverage of continuationmethod
					dummyContState = new StateInfo(emsAsyncStub.beginSearch_x(cont, request), consignmentNumber, enq);
					cont.state = dummyContState;
					return cont;
				} catch (CalloutException e) {
					if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_TIMEOUT)){
						throw new ErrorException(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SEARCHCONSIGNTIMEOUT).Field_Name__c);
					} else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM) || e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED)){
						throw new ErrorException(stSettings.StarTrack_ConSearch_Authentication_Error__c);
					} else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)){
						throw new ErrorException(stSettings.StarTrack_ConSearch_Client_Cert_Error__c);
					} else{
						throw new ErrorException(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH).Field_Name__c);
					}
				} catch (Exception ex){
					throw new ErrorException(ex.getMessage());
				}
			}
		}
		return null;
	}

	/*------------------------------------------------------------
	Author:Jen Karen Tan
	Description:   StarTrack method that process Case creation (Delivery Enquiry) after Consignment search
	January 13, 2017 - Jen Karen Tan - Created
	Sep 18, 2020 - Jansi - Uplift changes
	------------------------------------------------------------*/
	@AuraEnabled
	public static STDeliveryEnquiryResultsWapper processDeliveryEnquiryCreation(Object state) {
		STDeliveryEnquiryResultsWapper stWrapper;
		StateInfo stInfo = (StateInfo)State;
		AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse = stInfo.response;

		enq = stInfo.enqObj;
		consignmentNumber = stInfo.consignmentNumber;

		Map<String, BSPErrorMessages__c > errors = BSPErrorMessages__c.getAll();
		searchedConsignment = StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), false);

		String err = '';
		if (searchedConsignment != null) {
			stWrapper = new STDeliveryEnquiryResultsWapper();

			// if consignment number provided is valid but is not found or multiple consignment found,
			// provide error message and ask if user wants to proceed creating case
			if (articleNotFound(searchedConsignment)) {
				system.debug('ARTICLE NOT FOUND ' );
				stWrapper.confirmCreation = true;//confirmCreation = true;
				stWrapper.notFound = true;//notFound = true;
				stWrapper.errorMessage = errors.get(BspConstants.CREATE_ENQ_MSG_CON_NOT_FOUND).Message__c.replace(BspConstants.MSG_KEY_CON_NUM, stInfo.consignmentNumber.escapeHtml4());
			} else if (isMultipleConsignment(searchedConsignment)) {
				system.debug('MULTIPLE CONSIGNMENTS ' );
				stWrapper.confirmCreation = true;//confirmCreation = true;
				stWrapper.duplicate = true;//duplicate = true;
				stWrapper.errorMessage =errors.get(BspConstants.CREATE_ENQ_MSG_MULT_CON).Message__c.replace(BspConstants.MSG_KEY_CON_NUM, stInfo.consignmentNumber.escapeHtml4());
			} else {
				System.debug('SINGLE CONSIGNMENTS ');
				//if single consignment found
				// reselect the data out to include the billing account record to verify whether it's accessible to the current user
				List<Article__c> artList = [SELECT Id, Name, Billing_Account__c, Billing_Account__r.LEGACY_ID__c, Billing_Account__r.Id,
											Billing_Account__r.Organisation__c, ArticleID__c,ExpectedDeliveryDate_Str__c FROM Article__c WHERE Id =: searchedConsignment.articleList[0].Id];

				//validate if user is authorized on consignment's billing account
				// proceed creation if valid, return error if not
				if (isSingleConsignment(searchedConsignment) && !artList.isEmpty() && bspBaseUplift.isArticleAccessible(artList[0])) {
					system.debug('AUTHOIZED ' );
					//[Jansi: added 10-09-2020] Get latest Consignment Event
					stWrapper.expectedDeliveryDate= artList[0].ExpectedDeliveryDate_Str__c;
					stWrapper.latestEvent = getLatestEvent(artList[0].Id); //isArticleAccessible

					if(retrieveConCases(artList[0])){
						System.debug('MULTIPLE OPEN CASES ' );
						stWrapper.article=artList[0];
						stWrapper.multipleCaseError=multipleCaseError;
						stWrapper.lastKey=lastKey;
						stWrapper.notAllowedToCreateEnquiry = true; //[Jansi: added 08-0-2020 :: Not allowing the case creation if non closed cases exist]
						stWrapper.caseNumbersStrList = new List<String>(caseNumbers.keySet());
					}
					else{
						System.debug('NO OPEN CASES ' );
						stWrapper.article = artList[0];
					}
				} else {
					system.debug('NOT AUTHOIZED ' );
					stWrapper.errorMessage = errors.get(BspConstants.CREATE_ENQ_MSG_NOT_AUTH).Message__c.replace(BspConstants.MSG_KEY_CON_NUM, stInfo.consignmentNumber.escapeHtml4());
					stWrapper.notAllowedToCreateEnquiry = true;
				}
			}
		}
		return stWrapper;
	}

		/**
	 * get the latest event message of a given article
	 */
	private static EventMessage__c getLatestEvent(String articleId){
		EventMessage__c latestConsignmentEvent;
		try{
			Article__c singleCon = [SELECT Id,ExpectedDeliveryDate_Str__c,
									(SELECT Id, ActualDateTime_Timestamp__c,  WorkCentreText__c,  ExternalDescription__c
										FROM Event_Messages__r  WHERE ShowtoExternals__c = true ORDER BY ActualDateTime__c DESC LIMIT 1)
									FROM Article__c WHERE Id=:articleId LIMIT 1];
			if(singleCon != null && singleCon.Event_Messages__r != null && singleCon.Event_Messages__r.size() > 0){
				return singleCon.Event_Messages__r[0];
			}
		}catch(Exception ex){
			System.debug('ERROR while getting latest event');
		}
		return latestConsignmentEvent;
	}

	/*------------------------------------------------------------
	Author:Jen Karen Tan
	Description:   StarTrack method that will close bulk cases
	January 9, 2017 - Jen Karen Tan - Created
	04-08-2020 - Jansi updated to 'AuraEnabled'
	------------------------------------------------------------*/
	@AuraEnabled
	public static void bulkCloseCase(String casesJsonStr) {
		if(!String.isEmpty(casesJsonStr)){
			List<CaseContainer> cases = (List<CaseContainer>)JSON.deserialize(casesJsonStr,List<CaseContainer>.class);

			Map<Id, Case> casesToClose = new Map<Id, Case>(retrieveSelectedCases(cases));
			Map<Id, Boolean> inApproval = Approval.isLocked(new List<Id>(casesToClose.keySet()));
			List<CaseComment> caseComments = new List<CaseComment>();
			List<Id> casesToUnlock = new List<Id>();

			if (!casesToClose.isEmpty()) {
				for (Case c : casesToClose.values()) {
					if(inApproval.containsKey(c.Id) && inApproval.get(c.Id)){
						caseComments.add(new CaseComment(CommentBody = 'BSP User closed this case while still pending for approval process.', ParentId = c.Id));
						casesToUnlock.add(c.Id);
					}
					c.Status = BspConstants.CASE_STATUS_CLOSED;
					c.ResolutionCode__c = BspConstants.CASE_RESOLUTION_CODE_CUSTOMER_SELF_SERVICE;
				}

				try {
					Database.update(casesToClose.values());
					if(!caseComments.isEmpty()){
						Database.insert(caseComments);
						List<Approval.UnlockResult> results = Approval.unlock(casesToUnlock, false);
					}
				} catch(Exception ex) {
					throw new ErrorException(ex);
				}
			}
		}
	}

	/*------------------------------------------------------------
	Author:Jen Karen Tan
	Description:   The method that will update cases in bulk : add the bulk case comments, after adding the comments update case status in bulk
	January 10, 2017 - Jen Karen Tan - Created
	Sep 09, 2020 - Jansi - Uplift changes
	------------------------------------------------------------*/
	@AuraEnabled
	public static void bulkUpdateCases(String casesJsonStr, String caseCommentBulk) {

		if (caseCommentBulk.trim() != null && !String.isBlank(caseCommentBulk.trim())) {
			if(!String.isEmpty(casesJsonStr)){
				List<CaseContainer> cases = (List<CaseContainer>)JSON.deserialize(casesJsonStr,List<CaseContainer>.class);
				List<Case> casesToUpdateBulk = retrieveSelectedCases(cases);
				List<CaseComment> caseComments = new List<CaseComment>();
				CaseComment caseComment = null;
				for (Case c : casesToUpdateBulk) {
					caseComment = new CaseComment();
					caseComment.IsPublished = true;
					caseComment.ParentId = c.Id;
					caseComment.CommentBody = caseCommentBulk.trim();
					caseComments.add(caseComment);

					c.Case_Update__c = StarTrack_Constants.CASE_UPDATE_CUSTOMERRESP;
					c.Case_Update_Time__c = System.now();

					if (StarTrack_Constants.CASE_STATUS_WAITINGONCUSTOMER.equals(c.Status)) {
						c.Status = StarTrack_Constants.CASE_STATUS_INVESTIGATION;
					}
				}
				try {
					insert caseComments;
					caseCommentBulk = '';
					update casesToUpdateBulk;
				} catch(Exception ex) {
					throw new ErrorException(ex);
				}
			}
		}
	}


	/**
	 * This method retrieves the existing cases related to consignment or article.
	 * Because of this method, we have kept without sharing otherwise it will not get the duplicate cases.
	 */
	public static Boolean retrieveConCases(Article__c consignment){
		caseNumbers = new Map<String, Id>();
		lastKey = '';
		multipleCaseError = '';

		List<Case> listOfCases = new List<Case>([SELECT Id, CaseNumber FROM Case WHERE ArticleTest__r.Id = :consignment.Id AND RecordType.Name = :StarTrack_Constants.CASE_DELIVERY_RT AND IsClosed = false]);

		if(!listOfCases.isEmpty()){

			multipleCaseError = listOfCases.size() > 1 ? (BSPErrorMessages__c.getValues('Multiple Case Under Consignment') != null ? BSPErrorMessages__c.getValues('Multiple Case Under Consignment').Message__c : 'There are open enquiries associated to this consignment:') :
					(BSPErrorMessages__c.getValues('Single Case Under Consignment') != null ? BSPErrorMessages__c.getValues('Single Case Under Consignment').Message__c : 'There is an open enquiry associated to this consignment:');
			for(Case caseRec : listOfCases){
				caseNumbers.put(caseRec.CaseNumber, caseRec.Id);
			}

			lastKey = new List<String>(caseNumbers.keySet())[caseNumbers.size()-1];
			return true;
		}
		return false;
	}

		/**
	 * caluculate case rules after new startrack cases are created from bsp
	 * */
	public static void calculateTransferCaseRule(Case caseRecord){
		Case c = [SELECT Id, Call_Purpose__c, RecordTypeId, RecordType.Name, Enquiry_Type__c, Network__r.OwnerId, Business_Solutions_Customer__c, Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c, Network__r.Name, Initial_Caller_Type__c,
				Status, OwnerId, Article_Service_Type__c, ArticleTest__r.Product_Group__c, Account.StarTrack_Customer_Stream__c , Related_Billing_Account__r.StarTrack_Priority_Customer__c  FROM Case WHERE Id =: caseRecord.Id];

		List<StarTrack_Transfer_Case_Rule__c> tc_rules = [SELECT Id, Business_Solutions_Customer__c, Case_Purpose__c, Case_RecordType__c, Case_Type__c, Customer_Stream__c, Initial_Caller_Type__c, Order__c, Product_Group__c,BSP_Rule__c, Queue_Name__c, Priority_Customer__c
		FROM StarTrack_Transfer_Case_Rule__c ORDER BY Order__c];

		Boolean ruleSatisfied = false;
		Boolean caseOwnerChanged = false;
		for(StarTrack_Transfer_Case_Rule__c tc_rule : tc_rules){
			if((String.isNotBlank(tc_rule.Case_Purpose__c) ? tc_rule.Case_Purpose__c.equals(c.Call_Purpose__c) : true) && (String.isNotBlank(tc_rule.Case_RecordType__c) ? tc_rule.Case_RecordType__c.equals(c.RecordType.Name) : true) &&
					(String.isNotBlank(tc_rule.Case_Type__c) ? tc_rule.Case_Type__c.equals(c.Enquiry_Type__c) : true) && (String.isNotBlank(tc_rule.Customer_Stream__c) ? tc_rule.Customer_Stream__c.equals(c.Account.StarTrack_Customer_Stream__c) : true) &&
					(String.isNotBlank(tc_rule.Initial_Caller_Type__c) ? tc_rule.Initial_Caller_Type__c.equals(c.Initial_Caller_Type__c) : true) && (String.isNotBlank(tc_rule.Product_Group__c) ? tc_rule.Product_Group__c.equals(c.ArticleTest__r.Product_Group__c) : true) &&
					(tc_rule.Business_Solutions_Customer__c ? c.Business_Solutions_Customer__c == tc_rule.Business_Solutions_Customer__c : true) &&
					(tc_rule.Priority_Customer__c ? c.Related_Billing_Account__r.StarTrack_Priority_Customer__c == tc_rule.Priority_Customer__c : true) && String.isNotBlank(tc_rule.Queue_Name__c) && tc_rule.BSP_Rule__c){

				if(StarTrack_Constants.TRANSFER_QUEUE.equals(tc_rule.Queue_Name__c) && String.isNotBlank(c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c)){
					Id queueId = queryQueue(c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c);
					if(String.isNotBlank(queueId)){
						c.OwnerId = queueId;
						caseOwnerChanged = true;
					}
					ruleSatisfied = true;
					break;
				} else{
					Id queueId = queryQueue(tc_rule.Queue_Name__c);
					if(String.isNotBlank(queueId)){
						c.OwnerId = queueId;
						caseOwnerChanged = true;
					}
					ruleSatisfied = true;
					break;
				}
			}
		}

		if(!ruleSatisfied && String.isNotBlank(c.Network__r.OwnerId)){
			c.OwnerId = c.Network__r.OwnerId;
			caseOwnerChanged = true;
		} else if(!caseOwnerChanged && c.Business_Solutions_Customer__c && StarTrack_Constants.CASE_DELIVERY_RT.equals(c.RecordType.Name)){
			AssignmentRule ar = [SELECT Id FROM AssignmentRule WHERE SobjectType =: BspConstants.OBJ_CASE AND Active = true LIMIT 1];

			Database.DMLOptions dmlOpts = new Database.DMLOptions();
			dmlOpts.assignmentRuleHeader.assignmentRuleId= ar.Id;

			//Setting the DMLOption on Case instance
			c.setOptions(dmlOpts);
			caseOwnerChanged = true;
		}

		if(caseOwnerChanged){
			Database.update(c);
		}
	}

		/**
	 * get queue ow id for the given queue
	 * */
	public static Id queryQueue(String queueName){
		try{
			return [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :queueName].Id;
		}catch(QueryException e){
			return null;
		}
	}

	/**
	 * What it is: method called by LWC bspFormAPEnquiry onload
	 * What it does:
	 *  - Checks that the current user is allowed to create an enquiry for BSP and returns a status + message
	 *  - Returns picklist values as dropdown options
	 * Why: LWC requires permission checks and Case Field options
	 * @return an EnquiryFormInitWrapper object which contains the above
	 */
	@AuraEnabled
	public static Object initMissingItemForm()
	{
		EnquiryFormInitWrapper formInitWrapper = new EnquiryFormInitWrapper();
		formInitWrapper.status = STATUS_OK;

		// put the current user
		formInitWrapper.currentUser = bspBaseUplift.loginUser;

		if(!bspBaseUplift.hasAPBillingAccounts && !bspBaseUplift.canSearchAllConsignments) {
			// early out
			formInitWrapper.status = STATUS_ERROR;
			formInitWrapper.message = ERROR_MESSAGE_CANNOT_CREATE;
		}

		// get product category options
		DescribeFieldResult frArticleType = Case.ArticleType__c.getDescribe();
		formInitWrapper.articleTypes = getPickListValuesIntoList(frArticleType);

		DescribeFieldResult frServiceUsed = Case.CCUServiceUsed__c.getDescribe();
		formInitWrapper.serviceTypes = getPickListValuesIntoList(frServiceUsed);

		return formInitWrapper;
	}

	/**
	 * @param fieldResult the sObject field picklist list
	 * @return a list of label:value pairs
	 */
	public static List<Map<String,String>> getPickListValuesIntoList(DescribeFieldResult fieldResult){
		List<Map<String,String>> pickListValuesList= new List<Map<String,String>>();
		//Schema.DescribeFieldResult fieldResult = ObjectApiName.FieldApiName.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){

			Map<String, String> option = new Map<String, String>();

			option.put('label', pickListVal.getLabel());
			option.put('value', pickListVal.getValue());
			pickListValuesList.add(option);
		}
		return pickListValuesList;
	}

	/**
	 * @param fileId the Id of the file (ContentDocument) to delete
	 * What it is: method called by LWC bspFormAPEnquiry to delete an uploaded file
	 * What it does: tries to delete a File (ContentDocument) by Id.
	 * Why: BSP users can attach files to an enquiry, this gives them the option to remove a file.
	 * @return FormActionWrapper object with the status of the delete action.
	 */
	@AuraEnabled
	public static Object deleteAttachment(Id fileId)
	{
		FormActionWrapper actionWrapper = new FormActionWrapper();
		try{
			List<ContentDocument> files = [SELECT Id, Title  FROM ContentDocument WHERE Id =: fileId LIMIT 1];
			if(files.size() == 1){
				delete files;
				actionWrapper.status = STATUS_OK;
			}
			else {
				actionWrapper.status = STATUS_ERROR;
			}
		}  catch(Exception e) {
			actionWrapper.status = STATUS_ERROR;
		}
		return actionWrapper;
	}

	/**
	* check if startrack consignment search results contains single consignment or not
	* */
	public static boolean isSingleConsignment(StarTrackConsignmentSearchUtil.ConsignmentWrapper wrapper) {
		return StarTrack_Constants.ERR_CODE_0.equals(wrapper.errorCode) && wrapper.articleList.size() == 1 && wrapper.isConsignmentSaved;
	}

	/**
	* check if startrack consignment search results contains multiple consignments or not
	* */
	public static boolean isMultipleConsignment(StarTrackConsignmentSearchUtil.ConsignmentWrapper wrapper) {
		return StarTrack_Constants.ERR_CODE_0.equals(wrapper.errorCode) && wrapper.articleList.size() > 1;
	}

	/**
	* check if startrack consignment search results contains article or not
	* */
	public static boolean articleNotFound(StarTrackConsignmentSearchUtil.ConsignmentWrapper wrapper) {
		return wrapper != null && wrapper.articleList.isEmpty() && StarTrack_Constants.ERR_CODE_ART_NOT_FOUND.equals(wrapper.errorCode);
	}


	public with sharing class bspCaseQueryInner {
		public List<case> getCases(String query){
			return (List<Case>)Database.query(query);
		}

		public Integer getTotalCases(String query){
			return Database.countQuery(query);
		}
	}

	// return object for creating a case used in bspAPFormEnquiry and bspAPConsignmentDetails
	public class CreateEnquiryWrapper{
		@AuraEnabled public Case enquiry {get;set;}
		@AuraEnabled public String status {get;set;}
		@AuraEnabled public String message {get;set;}
	}

		/**
	 * Inner class to be returned  after searching of consignment number in startrack Delivery enquiry creation
	 * */
	public class STDeliveryEnquiryResultsWapper{
		@AuraEnabled public Boolean confirmCreation { get; set; }
		@AuraEnabled public Boolean duplicate { get; set; }
		@AuraEnabled public Boolean notFound { get; set; }
		@AuraEnabled public String errorMessage { get; set; }
		@AuraEnabled public Boolean notAllowedToCreateEnquiry { get; set; }
		@AuraEnabled public Article__c article { get; set; }
		@AuraEnabled public List<String> caseNumbersStrList { get; set; }
		@AuraEnabled public String lastKey { get; set; }
		@AuraEnabled public String multipleCaseError { get; set; }
		@AuraEnabled public String expectedDeliveryDate { get; set; }
		@AuraEnabled public EventMessage__c latestEvent { get; set; }
	}

	// return object for initMissingForm to be consumed by bspAPFormEnquiry LWC
	public class EnquiryFormInitWrapper{
		@AuraEnabled public List<Map<String,String>> articleTypes {get;set;}
		@AuraEnabled public List<Map<String,String>> serviceTypes {get;set;}
		@AuraEnabled public String status {get;set;}
		@AuraEnabled public String message {get;set;}
		@AuraEnabled public User currentUser {get;set;}
	}

	// return object for deleteAttachment and createEnquiryAusPost
	public class FormActionWrapper {
		@AuraEnabled public String status {get;set;}
		@AuraEnabled public Case enq {get;set;}
	}

		/**
	 * Custom select Option: Added this because standard SelectOption class is not supported by LWC
	 * */
	public class SelectOptionCustom {
		public SelectOptionCustom(String value, String label) {
			this.value = value;
			this.label = label;
			this.disabled = false;
			this.escapeItem = false;
		}

		public SelectOptionCustom(String value, String label, Boolean isDisabled) {
			this.value = value;
			this.label = label;
			this.disabled = isDisabled;
			this.escapeItem = false;
		}

		public SelectOptionCustom(String value, String label, String key) {
			this.value = value;
			this.label = label;
			this.disabled = false;
			this.escapeItem = false;
			this.key = key;
		}

		@AuraEnabled public String label { get;set; }
		@AuraEnabled public String value { get;set; }
		@AuraEnabled public String key { get;set; }
		@AuraEnabled public Boolean disabled { get;set; }
		@AuraEnabled public Boolean escapeItem { get;set; }

	}

	/**
	 * Data Transfer Object Model class to map download data
	 */
	public class CaseDetails {
		public String EnquiryNo;
		public String DateCreated;
		public String TrackingNo;
		public String Details;
		public String SendingTo;
		public String Status;
		public String ArticleID;
		public String Updated;
		public String AccountNumber;
		public String AccountName;
		public String AccountHeldWith;
	}

	/**
	 * Data Transfer Object Model class to search and sort filters
	 */
	public class EnquiryFilter {
		@AuraEnabled public String searchStr {get; set;}
		@AuraEnabled public String pageSize {get; set;}
		@AuraEnabled public String orgOption {get; set;}
		@AuraEnabled public String billingAccOption {get; set;}
		@AuraEnabled public String status {get; set;}
		@AuraEnabled public Date fromDate {get; set;}
		@AuraEnabled public Date toDate {get; set;}
		@AuraEnabled public String pageNumber {get; set;}
		@AuraEnabled public String sortByColumn {get; set;}
		@AuraEnabled public String sortByOrder {get; set;}
		@AuraEnabled public String enquiryType {get; set;}
	}


	/**
	* Case container for Case display list
	* [Jansi:Updated to @AuraEnabled  work with LWC Component]
	* */
	public class CaseContainer{
		@AuraEnabled public Boolean isSelected {get; set;}
		@AuraEnabled public Boolean isST {get; set;}
		@AuraEnabled public Case caseObj {get; set;}
		@AuraEnabled public String sendingTo {get; set;}
		@AuraEnabled public String caseUIStatus {get; set;}
		@AuraEnabled public String BillingNumber {get; set;}
		@AuraEnabled public String RecordType {get; set;}

		public CaseContainer(Case c) {
			this.caseObj = c;
			this.isSelected = false;
			this.isST = c.RecordType.DeveloperName.startsWith('StarTrack') ? true : false;
			this.sendingTo = String.isNotBlank(c.BSP_Addressee_Name__c) ? c.BSP_Addressee_Name__c : c.Secondary_Contact__c;
			this.caseUIStatus = readStatus(c);
			this.BillingNumber = c.Billing_Number__c != null ? c.Billing_Number__c : '';
			this.RecordType = c.RecordType.DeveloperName;
		}
	}

	/**
	* inner class to store searched results of cases list
	* */
	public class SerchResultsWrapper{
		@AuraEnabled public Integer totalSearchCount{set;get;}
		@AuraEnabled public List<CaseContainer> paginatedSearchResults{get;set;}
	}

	/**
	* inner class to store to download results of cases list
	* */
	public class DownloadResultsWrapper{
		@AuraEnabled public Object caseDetails{set;get;}
		@AuraEnabled public Boolean isAPUser{get;set;}
	}

	/**
	* inner class to store default page size and default org for case list search
	* */
	public class BSPEnquiryConstants{
		@AuraEnabled public final String DEFAULT_ORG_OPTION_VALUE =  BspConstants.SELECT_OPTION_VALUE_ALL_ORG_ENQ;
		@AuraEnabled public final String DEFAULT_PAGE_OPTION_VALUE = String.valueof(dynamicPageSize) ;//BspConstants.SELECT_OPTION_VALUE_15_ENQ;//--String.valueOf(bspBaseUplift.configSetting.EnquiriesPerPage__c);//
	}

	// Declare inner class to hold continuation state info
	private class StateInfo {
		String consignmentNumber { get; set; }
		Case enqObj { get; set; }
		AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture response  { get; set; }

		StateInfo( AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture response, String cNumber, Case enqObj) {
			this.response = response;
			this.consignmentNumber = cNumber;
			this.enqObj = enqObj;
		}
	}

	public class BSPFormAdditionalData {
		@AuraEnabled public String containsEssentialMedicine {get; set;}
		@AuraEnabled public String isSentimental {get; set;}

		public BSPFormAdditionalData() {
			this.containsEssentialMedicine = 'no';
			this.isSentimental = 'no';
		}
	}

	/**
	 * On hold the case when the case based on the EDD of the article and the configured holding period
	 * @param pCase the case SObject record that contains fields to determine routing
	 */
	public static void setDirectRoutingValues(Case pCase) {
		Date eddPlusBusinessDays = getEDDPlusBusinessDays(pCase.EstimatedDelivery__c);
		//if EDD (eddPlusBusinessDays) is a future date, case is eligible for on hold
		if (eddPlusBusinessDays > Date.today()) {
			Map<Id, Group> vGroups = GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{
					SSSWConstants.QUEUE_NAME_REOPEN_Q
			});
			if (!vGroups.isEmpty()) {
				pCase.OwnerId = vGroups.values()[0].Id;
				pCase.Status = SSSWConstants.CASE_STATUS_INPROGRESS;
				pCase.Case_Reopen_Date__c = eddPlusBusinessDays;
				pCase.HeldToOpenOn__c = eddPlusBusinessDays;
				pCase.ByPassRoutingRulesOnCreation__c = true;
				pCase.AllocateToQueue__c = false;
			}
		}
	}

	/**
	 * @param edd a Date value for Estimated Delivery Date
	 *
	 * @return the date value that is the EDD + the number of days defined in CCUSettings__c
	 */
	@AuraEnabled
	public static Date getEDDPlusBusinessDays (Date edd) {
		return edd == null ? null : BusinessHoursService.newInstance().calculateNextBusinessDay(edd, CCUSettings__c.getInstance().NextUpdateInForLateItems__c != null ? Integer.valueOf(CCUSettings__c.getInstance().NextUpdateInForLateItems__c) : 0);
	}


	/**
	* Custom Exception
	* */
	class ErrorException extends Exception{}
}