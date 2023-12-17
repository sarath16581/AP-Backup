/**
* @description	   : A class for bcaForm LWC component
* @author			: Victor Cheng
* @group			 : 
* @last modified on  : 06-09-2021
* @last modified by  : ankur.gandhi@auspost.com.au
* Modifications Log 
* Ver   Date		 Author							   Modification
* -------------------------------------------------------------------------
* 1.0   10-12-2020  Victor Cheng   Initial Version
* 1.0   14-04-2021  Victor Cheng   Changes after Unit Test class
* 2023-05-05	Naveen Rajanna	REQ3184691	Modified getDigitalIdClientId to return a wrapper
**/

public without sharing class BCAFormController {

	@AuraEnabled(Cacheable=true)
	public static Boolean skipValidationSetting() {
		//List<AusPostSettings__c> skipValidationSetting = [SELECT Id, Name, IsActive__c FROM AusPostSettings__c WHERE Name =: BCAFormConstants.BCA_SKIP_VALIDATION LIMIT 1];
		Set<SObjectField> fields = new Set<SObjectField> {AusPostSettings__c.Id
				, AusPostSettings__c.Name, AusPostSettings__c.IsActive__c};
		CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(AusPostSettings__c.SObjectType, fields);

		List<AusPostSettings__c> skipValidationSetting = settingsSelector.selectByNames(new Set<String> {BCAFormConstants.BCA_SKIP_VALIDATION}).values();
		if(skipValidationSetting.size() == 1){
			return skipValidationSetting[0].IsActive__c;
		}
		
		return false;
	}

	@AuraEnabled(continuation=true)
	public static Object queryABN(String abn, String acn){
		APT_ServicePartyCustomerService service = new APT_ServicePartyCustomerService();
		APT_ServicePartyCustomerService.ABNServices_v1HTTPEndpoint1 endPoint = new APT_ServicePartyCustomerService.ABNServices_v1HTTPEndpoint1();

		endPoint.inputHttpHeaders_x  = APT_WebServiceUtility.getinputHttpHeaders() ;
		endPoint.Header = APT_WebServiceUtility.getOrgIDInterfaceHeader(APT_WebServiceUtility.INTERFACE_NAME_QUERYABN);
		endpoint.timeout_x = APT_WebServiceUtility.DEFAULT_WEBSERVICE_TIMEOUT;

		APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
		if(r2tSystemProperty != null && r2tSystemProperty.APT_Org_Id_Service_End_Point_URL__c != null) {
			endPoint.endpoint_x = r2tSystemProperty.APT_Org_Id_Service_End_Point_URL__c;
		}

		APT_SchemaPartyCustomerService.queryABNResponseType responseService;
		APT_SchemaPartyCustomerService.BusinessRegistrationNumber_element businessRegistrationNumber= null;
		String bureauReference = null;
		//showSearchResults = true;

		String abnTrimmed = (abn != null) ? abn.replace(' ', '') : null;
		String acnTrimmed = (acn != null) ? acn.replace(' ', '') : null;
		responseService = endPoint.queryABN_v1(acnTrimmed, abnTrimmed, null, businessRegistrationNumber, bureauReference);
		//system.debug('***** response service:'+responseService);

		abnSearchWrapper result = new abnSearchWrapper();

		try{

			if(responseService.Error != null){
				// error occurred
				result.status = BCAFormConstants.ERROR;
				result.message = 'Error Type:' + responseService.Error.ErrorType + ', description:' + responseService.Error.ErrorDescription;
			}
			else{
				List<abnSearchResultWrapper> searchResults = new List<abnSearchResultWrapper>();
				abnSearchResultWrapper searchResultWrapper = new abnSearchResultWrapper(responseService.OrgIdResult[0]);
				searchResults.add(searchResultWrapper);

				storeAbnDetailsToCache(responseService.OrgIdResult[0]);

				if(searchResults.size() > 0){
					result.status = BCAFormConstants.OK;
					result.searchResults = searchResults;
				}
				else{
					result.status = BCAFormConstants.NO_RESULTS;
				}
			}
		}
		catch(Exception ex){
			result.status = BCAFormConstants.ERROR;
			result.message = 'Exception:' + ex.getMessage();
		}

		return result;
	}

	public class ABNReportsCached
	{
		public APT_SchemaPartyCustomerService.ASICReport_element ASICReport;
		public APT_SchemaPartyCustomerService.AustralianBusinessRegisterReport_element ABRReport;
	}

	@TestVisible
	private static void storeAbnDetailsToCache(APT_SchemaPartyCustomerService.OrgIdResult_element orgIdResultElement)
	{
		ABNReportsCached abnReports = new ABNReportsCached();
		abnReports.ASICReport = orgIdResultElement.ASICReport;
		abnReports.ABRReport = orgIdResultElement.AustralianBusinessRegisterReport;

		CacheManager.put(BCAFormConstants.BCA_ABN_DETAILS_KEY, abnReports);
		System.debug('storeAbnDetailsToCache='+ CacheManager.get(BCAFormConstants.BCA_ABN_DETAILS_KEY));
	}

	private static Map<String, ABN_Entity_Type_Mapping__mdt> abnEntityTypeMap;
	private static Map<String, ABN_Entity_Type_Mapping__mdt> abnEntityTypeMappings{
		get {
			
			if(null == abnEntityTypeMap){
				abnEntityTypeMap = new Map<String, ABN_Entity_Type_Mapping__mdt>();
				for(ABN_Entity_Type_Mapping__mdt mdt: [SELECT
						Entity_Type_Group__c, Entity_Type_Text__c, Entity_Type_Master_Label__c
				FROM ABN_Entity_Type_Mapping__mdt]){
					abnEntityTypeMap.put(mdt.Entity_Type_Text__c.toLowerCase(), mdt);
				}
			}
			
			return abnEntityTypeMap;
		}
	}
	/**
	 * wrapping the other entity elements
	 */
	public class entityWrapper{
		@AuraEnabled public String entityName;
		@AuraEnabled public String entityType;
		public entityWrapper(APT_SchemaPartyCustomerService.OtherEntity_element elem){
			this.entityName = elem.OtherEntityName;
			this.entityType = elem.OtherEntityType;
		}
	}

	public class abnSearchWrapper{
		@AuraEnabled public List<abnSearchResultWrapper> searchResults;
		@AuraEnabled public String status;
		@AuraEnabled public String message;
	}

	public class abnSearchResultWrapper{
		@AuraEnabled public String MatchName;
		@AuraEnabled public String OrganisationNumber;
		@AuraEnabled public APT_SchemaPartyCustomerService.OrganisationType_element OrganisationType;
		@AuraEnabled public String ABN;
		@AuraEnabled public String ACN;
		@AuraEnabled public String formattedABN;
		@AuraEnabled public String OrganisationNumberHeading;
		@AuraEnabled public String State;

		@AuraEnabled public String ABNStatus;
		@AuraEnabled public Date ABNStatusFromDate;
		@AuraEnabled public String EntityTypeText;
		@AuraEnabled public String EntityTypeGroup;
		@AuraEnabled public String EntityTypeMasterLabel;
		@AuraEnabled public String TradingNameStr;

		@AuraEnabled public String LegalEntityName;


		@AuraEnabled public entityWrapper[] entities;

		public abnSearchResultWrapper(APT_SchemaPartyCustomerService.OrgIdResult_element org){
			this.MatchName = org.MatchName;
			this.OrganisationNumber = org.OrganisationNumber;
			this.OrganisationNumberHeading = org.OrganisationNumberHeading;
			this.ABN = org.AustralianBusinessNumber;

			this.State = org.State;

			//this.State2 = orgIdResultElement.AustralianBusinessRegisterReport.BusinessAddressState;

			this.ABNStatus = org.AustralianBusinessRegisterReport.ABNStatus;
			this.ABNStatusFromDate = org.AustralianBusinessRegisterReport.ABNStatusFromDate;
			this.EntityTypeText = org.AustralianBusinessRegisterReport.EntityTypeText;
			this.EntityTypeGroup = abnEntityTypeMappings.get(EntityTypeText.toLowerCase()).Entity_Type_Group__c;
			this.EntityTypeMasterLabel = abnEntityTypeMappings.get(EntityTypeText.toLowerCase()).Entity_Type_Master_Label__c;

			// entity names
			this.entities = new List<entityWrapper>();
			if(org.AustralianBusinessRegisterReport != null) {
				// Name/Legal Name/Entity Name
				LegalEntityName = String.isBlank(org.AustralianBusinessRegisterReport.NonIndividualName) ? org.MatchName : org.AustralianBusinessRegisterReport.NonIndividualName;

				// ACN
				ACN = org.AustralianBusinessRegisterReport.ASICNumber;
				// check default trading name
				this.TradingNameStr = org.AustralianBusinessRegisterReport.TradingName;

				// add other entities
				if(org.AustralianBusinessRegisterReport.OtherEntity != null) {
					for (APT_SchemaPartyCustomerService.OtherEntity_element elem : org.AustralianBusinessRegisterReport.OtherEntity) {
						this.entities.add(new entityWrapper(elem));
					}
				}
			}
		}
	}



	/**
	* Get List of the countries for address LWC
	* */
	@AuraEnabled(cacheable = true)
	public static List<SelectOptionCustom> getCountries() {
		// this function generates picklist values
		List<SelectOptionCustom> options = new List<SelectOptionCustom>();
		Map<String, CountryCodes__c> countries = CountryCodes__c.getAll();
		List<String> countryCodes = new List<String>();
		countryCodes.addAll(countries.keySet());
		countryCodes.sort();
		for( String countryCode : countryCodes){
			CountryCodes__c country = countries.get(countryCode);
			options.add(new SelectOptionCustom(country.Name,country.Name));
		}
		return options;
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

		@AuraEnabled public String label { get;set; }
		@AuraEnabled public String value { get;set; }
		@AuraEnabled public Boolean disabled { get;set; }
		@AuraEnabled public Boolean escapeItem { get;set; }

	}


	@AuraEnabled
	public static BCAFormHelper.SaveFileResult uploadFile(Map<String, Object> file){
		return BCAFormHelper.createContentDocument(file);
	}

	@AuraEnabled
	public static BCAFormHelper.SaveFileResult deleteUploadedFile(String contentDocumentId){
		return BCAFormHelper.deleteContentDocument(contentDocumentId);
	}

	public class postalOutletWrapper {
		@AuraEnabled public Id id;
		@AuraEnabled public String name;
		@AuraEnabled public Decimal distance;
		@AuraEnabled public String networkAddress;
		@AuraEnabled public String addressLine1;
		@AuraEnabled public String addressLine2;
		@AuraEnabled public String suburb;
		@AuraEnabled public String state;
		@AuraEnabled public String postcode;
		@AuraEnabled public Decimal latitude;
		@AuraEnabled public Decimal longitude;
		@AuraEnabled public String orgId;

		public postalOutletWrapper(Network__c networkObject){
			id = networkObject.Id;
			name = networkObject.Name;
			networkAddress = networkObject.Network_Address__c;
			latitude = networkObject.Geolocation__Latitude__s;
			longitude = networkObject.Geolocation__Longitude__s;
			orgId = networkObject.Org_ID__c;

			addressLine1 = networkObject.ORG_UNIT_ADDR_1__c;
			addressLine2 = networkObject.ORG_UNIT_ADDR_2__c;
			suburb = networkObject.ORG_UNIT_ADDR_3__c;
			state = networkObject.State__c;
			postcode = networkObject.Post_Code__c;

			if(!Test.isRunningTest())
				distance = (Decimal) networkObject.get('dist');
		}
	}

	@AuraEnabled
	public static List<postalOutletWrapper> searchNetworks(Decimal latitude, Decimal longitude){
		System.debug('search location:' + latitude + ', ' + longitude);
		Set<SObjectField> fields = new Set<SObjectField>{BCA_Settings__c.Name, BCA_Settings__c.Text_Value__c};
		Set<String> settingNames = new Set<String> {BCAFormConstants.NETWORK_FILTER};

		CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(BCA_Settings__c.SObjectType, fields);
		Map<String, SObject> bcaSettings = (Map<String, SObject>) settingsSelector.selectByNames(settingNames);

		BCA_Settings__c networkFilterSetting = (BCA_Settings__c) bcaSettings.get(BCAFormConstants.NETWORK_FILTER);
		String networkFilter = networkFilterSetting != null? networkFilterSetting.Text_Value__c : '';
		
		List<Network__c> searchResults = NetworksSelector.newInstance('','').selectByMaxDistance(50, latitude, longitude, networkFilter);
		List<postalOutletWrapper> outlets = new List<postalOutletWrapper>();
		for(Network__c networkObj: searchResults)
		{
			postalOutletWrapper outlet = new postalOutletWrapper(networkObj);
			outlets.add(outlet);
		}
		return outlets;
	}

	/**
	 * [Jansi:] The method to be called on click of 'Submit' button on BCA Form
	 * */
	@AuraEnabled 
	public static BCAFormHelper.SaveAssessmentWrapper saveAssessment(String creditAssessmentStr){
		return BCAFormHelper.createCreditAssessment(creditAssessmentStr);
	}
	

   
	/**
	* Continuation method to do equifax validations
	* */
	@AuraEnabled(continuation=true )
	public static Continuation doEquifaxValidations(String caId) {
		try{
			
			equiReq = BCAFormHelper.buildEquifaxRequest(caId);
			
			// Create continuation. Argument is timeout in seconds.
			Continuation con = new Continuation(BCAFormConstants.EQUIFAX_TIME_OUT_IN_SECONDS);
			// Set callback method
			con.continuationMethod='processResponse';
			equiReq.reqLabel = con.addHttpRequest(equiReq.req);		   
			equiReq.req = null;  // before store in state nullifieng the request data
			con.state = equiReq;
			
			// Return the continuation
			return con;
		}catch (CalloutException e) {
			if(e.getMessage().contains('Time out')){ //TIMEOUT
				System.debug('Timeout');
			}else{
				System.debug('Continuation Exception ==='+e.getMessage());
			}
		}
		return null;
	}
	
	// Callback method
	@AuraEnabled
	public static Object processResponse( List<String> labels, Object state)  {
		System.debug('processResponse.....START');
		// Get the response by using the unique label
		HttpResponse response = Continuation.getResponse(labels[0]);
		// Set the result variable
		String result = response.getBody();
		System.debug('result=='+result);
		BCAFormHelper.EquifaxRequest stInfo = (BCAFormHelper.EquifaxRequest)State;
		System.debug('caId=='+stInfo.caId);
		System.debug('reqType=='+stInfo.reqType);
		return BCAFormHelper.parseResponse(response, stInfo);
		
	}
	
	// needed for test code coverage
	// Static Continuation Methods require a state object, but Test.invokeContinuation cannot pass in arguments,
	// therefore, store the state to pass in when testing.
	// The following methods are used for test injection.
	// Callback method
	public static BCAFormHelper.EquifaxRequest equiReq;
	public static Object processResponse() {
		return processResponse(new List<String>{equiReq.reqLabel},equiReq);
	}
	
	@AuraEnabled
	public static void createPDFSummary( String caId)  {
		BCAFormHelper.generatePDF(caId);
	}

	public class DigitalIdToken {
		@AuraEnabled public String transaction_id {get;set;}
		@AuraEnabled public String sub {get;set;}
		@AuraEnabled public String birthdate {get;set;}
		@AuraEnabled public String iss {get;set;}
		@AuraEnabled public String given_name {get;set;}
		@AuraEnabled public String family_name {get;set;}
		@AuraEnabled public String middle_name {get;set;}
		@AuraEnabled public String exp {get;set;}
		@AuraEnabled public String rawString {get; set;}
	}

	public class DigitalIdBody {
		public String id_token {get;set;}
	}

	public class RequestWrapper {
		@AuraEnabled public String clientId {get;set;}
		@AuraEnabled public Boolean isProduction {get;set;}
		public RequestWrapper(String clientId, Boolean isProduction) {
			this.clientId = clientId;
			this.isProduction = isProduction;
		}
	}

	@AuraEnabled
	public static RequestWrapper getDigitalIdClientId()
	{
		Set<SObjectField> fields = new Set<SObjectField>{BCA_Settings__c.Name, BCA_Settings__c.Text_Value__c, BCA_Settings__c.Boolean_Value__c};
		CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(BCA_Settings__c.SObjectType, fields);

		Set<String> settingNames = new Set<String> {BCAFormConstants.DIGITAL_ID_CLIENT_ID, BCAFormConstants.DIGITAL_ID_IS_PRODUCTION};

		Map<String, SObject> bcaSettings = (Map<String, SObject>) settingsSelector.selectByNames(settingNames);
		String clientId = ((BCA_Settings__c) bcaSettings.get(BCAFormConstants.DIGITAL_ID_CLIENT_ID)).Text_Value__c;
		Boolean isProduction = ((BCA_Settings__c) bcaSettings.get(BCAFormConstants.DIGITAL_ID_IS_PRODUCTION)).Boolean_Value__c;
		
		return new RequestWrapper(clientId, isProduction);
	}

	@AuraEnabled
	public static DigitalIdToken queryDigitalId(String grantCode)
	{
		Set<SObjectField> fields = new Set<SObjectField>{BCA_Settings__c.Name, BCA_Settings__c.Text_Value__c};
		CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(BCA_Settings__c.SObjectType, fields);

		Set<String> settingNames = new Set<String> {BCAFormConstants.DIGITAL_ID_URL
		, BCAFormConstants.DIGITAL_ID_CLIENT_ID, BCAFormConstants.DIGITAL_ID_CLIENT_SECRET};

		Map<String, SObject> bcaSettings = (Map<String, SObject>) settingsSelector.selectByNames(settingNames);
		String clientId = ((BCA_Settings__c) bcaSettings.get(BCAFormConstants.DIGITAL_ID_CLIENT_ID)).Text_Value__c;
		String clientSecret = ((BCA_Settings__c) bcaSettings.get(BCAFormConstants.DIGITAL_ID_CLIENT_SECRET)).Text_Value__c;
		String baseUrl = ((BCA_Settings__c) bcaSettings.get(BCAFormConstants.DIGITAL_ID_URL)).Text_Value__c;

		String idSecret = clientId + ':' + clientSecret;
		String idSecretEnc = EncodingUtil.base64Encode(Blob.valueOf(idSecret));

		HttpRequest req = new HttpRequest();
		req.setEndpoint(baseUrl + grantCode);
		req.setHeader('Authorization', 'Basic ' + idSecretEnc);
		req.setMethod('POST');

		System.debug(req);

		Http http = new Http();
		HttpResponse res = http.send(req);
		System.debug(res.getBody());

		String strBody = res.getBody();
		DigitalIdBody jwtBody = (DigitalIdBody) JSON.deserialize(strBody, DigitalIdBody.class);

		//String strEncoded = (String) resBody.get('id_token');
		List<String> tokenSplit = jwtBody.id_token.split('\\.');
		Blob blobPayload = EncodingUtil.base64Decode(tokenSplit[1]);

		String sPayload = blobPayload.toString();
		System.debug(sPayload);

		DigitalIdToken payload = (DigitalIdToken) JSON.deserialize(sPayload, DigitalIdToken.class);
		payload.rawString = sPayload;
		return payload;
	}

	public class MockHttpDigitalIdResponder implements HttpCalloutMock {
		public String sBody {get; set;}

		// Implement this interface method
		public HTTPResponse respond(HTTPRequest req) {

			// Create a fake response
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(sBody);
			res.setStatusCode(200);
			return res;
		}
	}

	/**
	 * Verify the entities on the Credit Assessment record against the Suspect Register
	 * @return True if referred or False if not matched /w threshold
	 * @exception AuraHandledException upon insufficient record access
	 */
	@AuraEnabled
	public static Boolean performSuspectRegisterCheck(Id creditAssessmentId) {
		try {
			// Without Sharing class -> Perform Record Access Check
			if (!UserRecordAccessSelector.newInstance().selectById(creditAssessmentId).HasReadAccess) {
				throw new NoAccessException();
			}

			return !BCAFormHelper.performSuspectRegisterCheck(creditAssessmentId).isEmpty();
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}