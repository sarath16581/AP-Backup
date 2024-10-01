/**
 * @description Webservice class to get the Customer Insights.
 * 	Called by Fullstop
 * @author Rejeesh Raghavan
 * @date 2024/09/05
 */
public with sharing class ResourceCustomerInsightsV1 extends ResourceAPIService.IApi{

	//--uri params are case-sensitive & hence in lower case
	private enum PARAM_NAMES {
		email,
		phone,
		case_type,
		interaction_type
	}

	//Maximum number of Contact records to be returned
	@TestVisible private final static Integer MAX_RECORD_COUNT = 20;

	/**
	 * @description Set of case record types for AP
	 */
	public final static Set<String> AP_CASE_RECORDTYPES = new Set<String>{
		'NCCCDirectEmail', 'Social_Record_Type','SSSWDelivery','SSSWFax'
		,'SSSWGeneralEnquiry','SSSWService'
	};

	/**
	 * @description Set of case record types for ST
	 */
	public final static Set<String> ST_CASE_RECORDTYPES = new Set<String>{
		'StarTrack_Credit_Dispute_Claim','StarTrack_PUD_Enquiry','StarTrack_General_Enquiry'
		,'StarTrack_Pickup_Booking_Enquiry','StarTrack_Sales_Enquiry', 'StarTrack_Transit_Warranty_Claim'
	};

	/**
	 * @description Set of case record types for Unified
	 */
	public final static Set<String> UNIFIED_CASE_RECORDTYPES = new Set<String>{
		'UnifiedGeneralEnquiry','UnifiedInvestigation'
	};

	/**
	 * @description Set of APCC team profile names
	 */
	public final static Set<String> AP_CC_PROFILES = new Set<String>{
		'SSSW - Service Agent','SSSW Security and Investigations'
	};

	/**
	 * @description Set of STCC team profile names
	 */
	public final static Set<String> ST_CC_PROFILES = new Set<String>{
		'StarTrack Support','StarTrack VOC'
	};

	/**
	 * @description Set of UCC team profile names
	 */
	public final static Set<String> U_CC_PROFILES = new Set<String>{
		'CustomerService'
	};

	//custom permission API used to validate access to this apex class
	@TestVisible private final static String PERMISSION_API_NAME='AccessRoutingInsightsAPI';
	
	@TestVisible private static String emailAddress;
	@TestVisible private static String phoneNumber;
	@TestVisible private static String caseType;
	@TestVisible private static String interactionType;

	/**
	 * @description Override query method to get Customer Insights
	 * @return  `ResourceAPIService.IResourceResponse`
	 */
	public override ResourceAPIService.IResourceResponse query() {
		Object response;
		try {
			//check for access
			if(!FeatureManagement.checkPermission(PERMISSION_API_NAME)){
				return new ResourceAPIService.ResourceResponse(403,'Forbidden');
			}
			Map<String,String> params = requestParams.queryStringParams;
			//validate uri email & phone
			if(!params.isEmpty() && validateUriParams(params)){
				String paramType = String.isNotBlank(emailAddress)?PARAM_NAMES.email.name():PARAM_NAMES.phone.name();
				response = transformOutput(getCustomerInsights(paramType));
			}else{
				return new ResourceAPIService.ResourceResponse(400,'Bad Request');
			}
		} catch (Exception ex) {
			return new ResourceAPIService.ResourceResponse(500,'', ex);
		}
		return new ResourceAPIService.ResourceResponse(200, response);
	}

	/**
	 * @description validate params
	 * if BOTH email & phone are provided => INVALID
	 * if NEITHER email NOR phone are provided => INVALID
	 * if EITHER valid email OR valid phone is provided => VALID
	 * Also used to populate class-level static variables to be easily accessed throughout the class.
	 * Also strips off the phone number of non-numeric characters
	 * @param params request params
	 * @return  `Boolean` are params valid
	 */
	static Boolean validateUriParams(Map<String,String> params){
		emailAddress = params.get(PARAM_NAMES.email.name());
		phoneNumber = params.get(PARAM_NAMES.phone.name());
		caseType = params.get(PARAM_NAMES.case_type.name());
		interactionType = params.get(PARAM_NAMES.interaction_type.name());

		//strip off any non-numeric characters from phone number
		//phoneNumber = String.isNotBlank(phoneNumber)?phoneNumber.replaceAll('[^0-9]',''):phoneNumber;
		phoneNumber = Util.reversePhoneString(phoneNumber);
		return (!(String.isNotBlank(emailAddress) && String.isNotBlank(phoneNumber))
			&& ((isValidEmail(emailAddress))
			|| (isValidPhone(phoneNumber))));
	}

	/**
	 * @description validate email address
	 * @param email 
	 * @return  `Boolean`
	 */
	static Boolean isValidEmail(String email){
		return String.isNotBlank(email);
	}

	/**
	 * @description validate phone number
	 * @param phone 
	 * @return  `Boolean`
	 */
	static Boolean isValidPhone(String phone){
		return String.isNotBlank(phone);
	}

	/**
	 * @description get contact, cases & interaction details based on request param type(email or phone)
	 * Also, derives caseType param to specify which all case record types should be queried
	 * Also, derives interactionType param to specify which all Interaction Teams should be queried
	 * @param paramType 
	 * @return  `List<SObject>`
	 */
	@TestVisible
	static List<SObject> getCustomerInsights(String paramType){
		//Contact fields to be queried
		Set<SObjectField> contactFields = new Set<SObjectField>{
			Contact.Id, Contact.APCN__c, Contact.Firstname, Contact.Lastname, Contact.Email
			, Contact.VerifiedEmail__c, Contact.Phone, Contact.MobilePhone, Contact.VerifiedMobile__c
		};

		//Account fields to be queried
		Set<SObjectField> accountFields = new Set<SObjectField>{
			Account.Id
		};
		
		// Case fields to be queried
		Set<SobjectField> caseFields = new Set<SObjectField>{
			Case.Id, Case.CaseNumber, Case.IsClosed, Case.ClosedDate, Case.Type
			, Case.Call_Purpose__c, Case.EnquirySubType__c, Case.Enquiry_Type__c, Case.Status};
		
		//Article fields to be queried
		Set<SobjectField> articleFields = new Set<SObjectField>{
			Article__c.Name, Article__c.ArticleId__c
		};

		//Task fields to be queried
		Set<SobjectField> taskFields = new Set<SObjectField>{
			Task.Id, Task.ActivityDate
		};

		//User fields to be queried
		Set<SobjectField> userFields = new Set<SObjectField>{
			User.Id
		};

		//Profile fields to be queried
		Set<SobjectField> profileFields = new Set<SObjectField>{
			Profile.Id, Profile.Name
		};

		//add fields to fieldOverrides map
		Map<SObjectType,Set<SObjectField>> fieldOverrides = new Map<SObjectType,Set<SObjectField>>();
		fieldOverrides.put(Contact.getSObjectType(), contactFields);
		fieldOverrides.put(Account.getSObjectType(), accountFields);
		fieldOverrides.put(Case.getSObjectType(), caseFields);
		fieldOverrides.put(Article__c.getSObjectType(), articleFields);
		fieldOverrides.put(Task.getSObjectType(), taskFields);
		fieldOverrides.put(User.getSObjectType(), userFields);
		fieldOverrides.put(Profile.getSObjectType(), profileFields);

		//instantiate the ContactsSelector
		ContactsSelector contactSelector = ContactsSelector.newInstance(MAX_RECORD_COUNT, fieldOverrides);

		List<Contact> contacts;
		Set<Object> complexOptions = new Set<Object>();
		Map<String, Object> bindMap = new Map<String, Object>();

		//use caseType param to filter case record types
		if(caseType== null || caseType.equalsIgnoreCase('allcontactcentre')){
			Set<String> caseRecordTypes = new Set<String>();
			caseRecordTypes.addAll(AP_CASE_RECORDTYPES);
			caseRecordTypes.addAll(ST_CASE_RECORDTYPES);
			caseRecordTypes.addAll(UNIFIED_CASE_RECORDTYPES);

			//add caseRecordTypes & closedCaseCutoffDate to bindMap to be used in SOQL
			bindMap.put('caseRecordTypes',caseRecordTypes);
			bindMap.put('closedCaseCutoffDate',Date.today().addDays(-30));

			//specify complexSearchOptions to include ALL Cases
			complexOptions.add(ContactsSelector.ComplexSubQueryOptions.WITH_RECENT_CASES);
		}

		//use interactionType param to filter Task, VoiceCall & LiveChatTranscript record teams
		if(interactionType== null || interactionType.equalsIgnoreCase('allcontactcentre')){
			Set<String> interactionProfiles = new Set<String>();
			interactionProfiles.addAll(AP_CC_PROFILES);
			interactionProfiles.addAll(ST_CC_PROFILES);
			interactionProfiles.addAll(U_CC_PROFILES);
			
			//add interactionProfiles & interactionCutoffDate to bindMap to be used in SOQL
			bindMap.put('interactionProfiles',interactionProfiles);
			bindMap.put('interactionCutoffDate',Date.today().addDays(-30));

			//specify complexSearchOptions to include ALL Interactions
			complexOptions.add(ContactsSelector.ComplexSubQueryOptions.WITH_ALL_RECENT_INTERACTIONS);
		}
		System.debug('emailAddress:'+ emailAddress);
		System.debug('bindMap:'+ JSON.serialize(bindMap));
		System.debug('complexOptions:'+ JSON.serialize(complexOptions));
		if(paramType==PARAM_NAMES.phone.name()){
			//get contacts by Reversed Phone Number
			contacts = contactSelector.selectWithCasesAndInteractionsByReversePhoneNumber(phoneNumber,bindMap, complexOptions);
		}else if(paramType==PARAM_NAMES.email.name()){
			//get contacts by EmailAddress
			contacts = contactSelector.selectWithCasesAndInteractionsByEmailAddress(emailAddress, bindMap, complexOptions);
		}
		return contacts;
	}
	/**
	 * @description Transform List of records to JSON structure for output.
	 * @TODO: Optimise method to improve reusability
	 * @param records 
	 * @return  `List<Map<String, Object>>`
	 */
	@TestVisible
	static List<Map<String, Object>> transformOutput(List<Contact> records){
		//Contact field mapping
		Map<String, String> contactMapping = new Map<String, String>{
			'sfid'=> 'Id',
			'apcn'=> 'APCN__c',
			'type'=> 'Account.RecordType.DeveloperName',
			'first_name'=> 'FirstName',
			'last_name'=> 'LastName',
			'email'=> 'Email',
			'email_verified'=> 'VerifiedEmail__c',
			'phone'=> 'Phone',
			'mobile'=> 'MobilePhone',
			'mobile_verified'=> 'VerifiedMobile__c',
			'cases'=>null,
			'interactions'=>null
		};
		List<Map<String, Object>> output = new List<Map<String, Object>>();
		List<Object> listCases = new List<Object>()
			, listInteractions = new List<Object>();
		Map<String, Object> mapRecord
			, mapCase  = new Map<String, Object>()
			, mapInteraction = new Map<String, Object>();
		//loop through the contact records
		for(Contact record : records) {
			mapRecord = new Map<String, Object>();
			for(String key : contactMapping.keySet()) {
				if(contactMapping.get(key)!=null){
					//value for 'type' key cannot be directly mapped, instead has to be mapped based on Account.RecordType
					if(key=='type'){				
						mapRecord.put(key, record.Account.RecordType.Developername=='PersonAccount'?
							'Consumer':
							record.Account.RecordType.Developername=='Business_Account'?
								'Business Contact':
								null);
					}//map key value with straight-forward field mappings
					else if(record.isSet(contactMapping.get(key))) {
						mapRecord.put(key, record.get(contactMapping.get(key)));
					}
				}
			}
			//loop through cases
			for(Case caseRecord: record.Cases){
				mapCase = getCaseMapping(caseRecord);
				listCases.add(mapCase);
			}
			
			mapRecord.put('cases',listCases);
			mapInteraction = new Map<String, Object>();
			//map all the Tasks, VoiceCall & LiveChatTranscript interactions
			for(Task taskRecord: record.Tasks){
				mapInteraction.put('type','Voice');
				mapInteraction.put('date',taskRecord.ActivityDate);
				mapInteraction.put('team', getInteractionTeam(taskRecord.CreatedBy.Profile.Name));
				listInteractions.add(mapInteraction);
			}
			for(VoiceCall voiceCallRecord: record.RelatedRecords){
				mapInteraction.put('type','Voice');
				mapInteraction.put('date',voiceCallRecord.CreatedDate);
				mapInteraction.put('team', getInteractionTeam(voiceCallRecord.CreatedBy.Profile.Name));
				listInteractions.add(mapInteraction);
			}
			for(LiveChatTranscript transcriptRecord: record.LiveChatTranscripts){
				mapInteraction.put('type','Chat');
				mapInteraction.put('date',transcriptRecord.CreatedDate);
				mapInteraction.put('team', getInteractionTeam(transcriptRecord.Owner.Profile.Name));
				listInteractions.add(mapInteraction);
			}
			mapRecord.put('interactions',listInteractions);
			output.add(mapRecord);
		}
        return output;
	}
	/**
	 * @description Transform a Case record to JSON mapping
	 * @param caseRecord Case record
	 * @return  `Map<String, Object>` JSON mapping
	 */
	public static Map<String, Object> getCaseMapping(Case caseRecord){
		//Case field mapping
		Map<String, String> caseMapping = new Map<String, String>{
			'sfid'=> 'Id',
			'case_number'=> 'CaseNumber',
			'status'=> 'Status',//Closed or Open
			'closed_date'=> 'ClosedDate',
			'enquiry_type'=> 'Enquiry_Type__c',
			'enquiry_subtype'=> 'EnquirySubType__c',
			'tracking_id'=> 'ArticleTest__r.ArticleId__c',//'ArticleTest__r.Name'
			'team'=> 'RecordType.DeveloperName'
		};
		Map<String, Object> mapCase = new Map<String, Object>();
		// @TODO: Refactor the below loop
		for(String key : caseMapping.keySet()) {
			if(caseMapping.get(key)!=null){
				//value for 'status' key cannot be directly mapped, instead has to be mapped based on Case.IsClosed
				if(key=='status'){
					mapCase.put(key, caseRecord.IsClosed?'Closed':'Open');
				}//value for 'enquiry_type' key cannot be directly mapped, instead has to be mapped based on caseRecord.RecordType
				else if(key=='enquiry_type'){
					mapCase.put(key, AP_CASE_RECORDTYPES.contains(caseRecord.RecordType.DeveloperName)?
						caseRecord.Type:
						ST_CASE_RECORDTYPES.contains(caseRecord.RecordType.DeveloperName)?
							caseRecord.Call_Purpose__c:
							null);
				}//value for 'enquiry_subtype' key cannot be directly mapped, instead has to be mapped based on caseRecord.RecordType
				else if(key=='enquiry_subtype'){
					mapCase.put(key, AP_CASE_RECORDTYPES.contains(caseRecord.RecordType.DeveloperName)?
						caseRecord.EnquirySubType__c:
						ST_CASE_RECORDTYPES.contains(caseRecord.RecordType.DeveloperName)?
							caseRecord.Enquiry_Type__c:
							null);
				}//value for 'tracking_id' key cannot be directly mapped, instead has to be mapped based on caseRecord.RecordType
				else if(key=='tracking_id'){
					mapCase.put(key, AP_CASE_RECORDTYPES.contains(caseRecord.RecordType.DeveloperName)?
						caseRecord.ArticleTest__r.ArticleId__c:
						ST_CASE_RECORDTYPES.contains(caseRecord.RecordType.DeveloperName)?
							caseRecord.ArticleTest__r.Name:
							null);
				}//value for 'team' key cannot be directly mapped, instead has to be mapped based on caseRecord.RecordType
				else if(key=='team'){
					mapCase.put(key, AP_CASE_RECORDTYPES.contains(caseRecord.RecordType.DeveloperName)?
						'APCC':
						ST_CASE_RECORDTYPES.contains(caseRecord.RecordType.DeveloperName)?
							'STCC':
							UNIFIED_CASE_RECORDTYPES.contains(caseRecord.RecordType.DeveloperName)?
							'UCC':
								null);
				}//map key value with straight-forward field mappings
				else if(caseRecord.isSet(caseMapping.get(key))) {
					mapCase.put(key, caseRecord.get(caseMapping.get(key)));
				}
			}
		}
		return mapCase;
	}
	/**
	 * @description Get Interaction Team name based on Owner/CreatedBy profile name
	 * @param profileName 
	 * @return  `String`
	 */
	static String getInteractionTeam(String profileName){
		return AP_CC_PROFILES.contains(profileName)?
					'APCC':
					ST_CC_PROFILES.contains(profileName)?
						'STCC':
						U_CC_PROFILES.contains(profileName)?
							'UCC':
							null;
	}
}