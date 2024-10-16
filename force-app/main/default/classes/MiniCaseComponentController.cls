/**
 * This component is use to hold data so that the user can create a case if needed.
 *
 * @author George Nguyen
 * @date 2014
 * @changelog
 * Kalpita Talwadekar	updated to add  duplicate case check based on reference id and show warning message to user
 * 2017-09-21 nathan.franklin@auspost.com.au Refactored code
 * 2017-09-27 nathan.franklin@auspost.com.au Removed lodgement point setting when case is created.
 * 2018-11-05 nathan.franklin@auspost.com.au add a check for live agent user licence property
 * 2018-12-04 nathan.franklin@auspost.com.au removed leading wildcard search when using reference ID to search for cases.
 * 2020-04-10 nathan.franklin@auspost.com.au removed the duplicate case creation method and refactored the existing create case method, renamed it from checkDuplicate to createCase
 * 2020-04-12 nathan.franklin@auspost.com.au Added enterprise selector/database patterns
 * 2020-10-05 disha.kariya@auspost.com.au Added safe drop attachment asynchronous method on case creation
 * 2021-06-15 - Ranjeewa Silva - Renamed Event Message selector option 'FILTER_NOT_BLANK_GUID' to 'FILTER_SAFE_DROP_GUID'
 * 2021-09-09 seth.heang@auspost.com.au Uplift SF API version to 52
 * 2021-10-03 - Nathan Franklin - Changed the safe drop attachment queueable from attaching an image to attaching PDF
 * 2024-10-08 - George Nguyen - include Unified cases in the search result
 */
global with sharing class MiniCaseComponentController {

	//UNUSED
	//public String variableKeys { get; Set; }
	//public String variableKeysForPicklist { get; set; }
	//private static final String CASE_CLOSED_STATUS = 'Closed';

	private String innerId { get; set; }
	public Case proxyCase { get; set; }

	public List<ExistingCaseOrActivityDisplay> existingCaseOrActivities { get; set; }
	public String recordTypeId { get; set; }

	// determines what should be shown on the VF page
	public Boolean showEDD { get; set; }
	public Boolean showSAPEMComponent { get; set; }
	public Boolean showExistingCaseOrActivities { get; set; }

	// handles the TIBCODataVisualizerComponent (populated only after a search to SAPEM has been invoked)
	public TIBCOSearchResult searchResult { get; set; }

	private static final String EXC_CATEGRY = 'Unaddressed Mail';
	private static final String EXC_TYPE = 'General Enquiry';

	@TestVisible
	private static final String DUPLICATE = 'Duplicate';

	/**
	 * Determines whether or not the agent is an HLC agent or not
	 * This is used to enable the user to bypass the duplicate check on case creation
	 */
	@TestVisible
	public Boolean isHLCUser {
		get {
			if(isHLCUser == null) {
				isHLCUser = (GroupMembersSelector.newInstance().countByMyGroups(new List<String>{'SSSW High Level Complaints', 'SSSW Customer Recovery'}) > 0);
			}
			return isHLCUser;
		}
		private set;
	}

	// Used to determine what which Product Category values trigger a SAP EM search
	public String sapEMSearchTriggers {
		get {
			return JSON.serialize(new Set<String>{'Domestic Parcels', 'International Parcels', 'Domestic Letters', 'International Letters'});
		}
	}


	// pass whether or not this user is a live agent user
	// this is used when using contexts within mini case
	@TestVisible
	public Boolean currentUserIsLiveAgentUser {
		get {
			if(currentUserIsLiveAgentUser == null) {
				currentUserIsLiveAgentUser = UsersSelector.newInstance().selectById(new Set<Id>{UserInfo.getUserId()}).values()[0].UserPermissionsLiveAgentUser;
			}
			return currentUserIsLiveAgentUser;
		}
		private set;
	}

	// Used to determine when the estimated delivery widgit should be shown.
	public String eddTriggers {
		get {
			return JSON.serialize(new Set<String>{'Domestic Letters', 'Domestic Parcels'});
		}
	}

	public AusPostSettings__c trackingSettings {
		get {
			if(trackingSettings == null) {
				trackingSettings = AusPostSettings__c.getValues('AP Track');
			}
			return trackingSettings;
		}
		private set;
	}

	public String contactId {
		get {
			if (innerId == null) {
				innerId = '';
			}
			return innerId;
		}
		set {
			if (value != null && value != '') {
				if (CommonUtils.getObjectAPINameByRecordId(value) == 'Account') {
					List<Account> accounts = SSSWAccountsSelector.newInstance().selectById(new Set<Id>{value}).values();
					if (accounts != null && accounts.size() > 0) {
						innerId = accounts[0].PersonContactId;
					}
				} else if (CommonUtils.getObjectAPINameByRecordId(value) == 'Contact') {
					innerId = value;
				} else {
					innerId = '';
				}
			} else {
				innerId = '';
			}
		}
	}

	public MiniCaseComponentController() {
		proxyCase = new Case();
		proxyCase.RecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'SSSWGeneralEnquiry'}).values()[0].Id;
		showEDD = false;
		showSAPEMComponent = false;
	}

	public void loadRelatedCases() {
		System.debug('LoadExistingCaseOrActivities: ' + proxyCase.ReferenceID__c);

		showExistingCaseOrActivities = false;
		existingCaseOrActivities = new List<ExistingCaseOrActivityDisplay>();
		if(!String.isEmpty(proxyCase.ReferenceID__c)) {

			Map<String, Object> searchParams = new Map<String, Object> {
				'recordTypeDeveloperNames' => new Set<String>{
					SSSWConstants.CASE_RT_SSSW_DELIVERY,
					SSSWConstants.CASE_RT_SSSW_FAX,
					SSSWConstants.CASE_RT_SSSW_GENERAL_ENQUIRY,
					SSSWConstants.CASE_RT_SSSW_SERVICE,
					SSSWConstants.CASE_RT_SSSW_SOCIAL_RECORD_TYPE,
					SSSWConstants.CASE_RT_SSSW_NCCC_DIRECT_EMAIL,

					SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME,
					SSSWConstants.UNIFIED_GENERAL_ENQUIRY_DEVELOPER_NAME
				}
			};

			Set<Object> selectorOptions = new Set<Object>{
				CasesSelector.Options.WITH_CONTACT, 
				CasesSelector.Options.WITH_OWNER
			};

			Boolean matchAll = true;

			Set<SObjectField> fieldOverrides = new Set<SObjectField>{
				Case.Id,
				Case.CaseNumber,
				Case.ReferenceID__c,
				Case.Subject,
				Case.Description,
				Case.Status,
				Case.LastModifiedDate,
				Case.CaseOriginator__c
			};

			List<Case> existingCases = CasesSelector.newInstance(100, fieldOverrides).searchByReferenceIdPartial(
																			proxyCase.ReferenceID__c, 
																			searchParams,
																			selectorOptions,
																			matchAll																			
																		);

			for (Case c : existingCases) {
				existingCaseOrActivities.add(new ExistingCaseOrActivityDisplay(
					c.Id,
					c.CaseNumber,
					c.ReferenceID__c,
					c.Contact.Name,
					c.Subject,
					c.Description,
					c.Status,
					c.Owner.Name,
					c.LastModifiedDate,
					c.CaseOriginator__c
				));
			}
			showExistingCaseOrActivities = (existingCaseOrActivities.size() > 0);

			System.debug('Should Show Cases: ' + showExistingCaseOrActivities);
		}
	}

	public void loadSAPEM() {
		showSAPEMComponent = true;
		showEDD = true;
		searchResult = TIBCOArticleService.searchArticles(new String[] {proxyCase.ReferenceID__c}, true);
		System.debug('Tibco Search Result: ' + searchResult);
	}

	public void reloadPicklists() {
		System.debug('****************** case.RecordTypeId = ' + proxyCase.RecordTypeId);
		recordTypeId = proxyCase.RecordTypeId;
	}
	
	 /**
	  * @desciprion: method to check if case is a duplicate enquiry and show pop-up to user
	  * @param safeDropJSON This context of this variable is updated to mean delivery proof (safe drop + signatures)
	  */
	@RemoteAction
	global static String createCase(String chatKey, String variableKeys, Boolean closeEnquiry, String articlesJSON, Boolean ignoreDuplicateCheck, String safeDropJSON) {

		String result = '';
		//showPopup = false;
		System.debug('################ creating case #######################');
		System.debug(variableKeys);
		Map<String, Object> fieldsAndValues = new Map<String, Object>();

		Case tempCase = null;
		JSONParser parser = JSON.createParser(variableKeys.trim());

		//check if logged in user is part of SSSW High Level Complaints queue
		Set<String> allowedForDupCheck = new Set<String>{
			'Money & Insurance', 'Post Office & Business Hub Services', 'Travel & ID', 'Web & Apps'
		};

		if (variableKeys != null && variableKeys.trim() != '') {

			// in MiniCaseComponent, if the first attempt at case creation returns the result 'Duplicate', then an error message is displayed in a dialog saying case can't be created because its a duplicate
			// In this scenario, HLC agents are able to bypass this and still create a case. On that same dialog, a button 'Create New Case' will appear and an HLC agent can click that button.
			// This method will be called again and the 'ignoreDuplicateCheck' flag will be passed as true
			Boolean isDuplicate = false;
			while (parser.nextToken() != null) {
				if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
					tempCase = (Case) parser.readValueAs(Case.class);

					if(!ignoreDuplicateCheck) {
						// capture duplicate enquiries and send user a pop-up message
						if (!String.isBlank(tempCase.ReferenceID__c) &&
								!allowedForDupCheck.contains(tempCase.ProductCategory__c) &&
								!EXC_CATEGRY.equalsIgnoreCase(tempCase.ProductSubCategory__c) &&
								!EXC_TYPE.equalsIgnoreCase(tempCase.Type)) {

							Integer duplicateCaseCount = SSSWCasesSelector.newInstance().countOpenCasesByReferenceId(new Set<String>{tempCase.ReferenceID__c});
							if (duplicateCaseCount > 0) {
								isDuplicate = true;
							}
						}
					}
				}
			}

			if (tempCase != null && !isDuplicate) {
				parser = JSON.createParser(variableKeys.trim());
				while (parser.nextToken() != null) {
					if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
						String fieldName = parser.getText();
						if (!fieldsAndValues.containsKey(fieldName)) {
							System.debug('#################### case object field:' + fieldName + ' = ' + tempCase.get(fieldName));
							fieldsAndValues.put(fieldName, tempCase.get(fieldName));
						}
					}
				}

				Map<Id, Case> newCases = new Map<Id, Case>();
				try {
					Id ssswGeneralEnquiry = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'SSSWGeneralEnquiry'}).values()[0].Id;

					Case newCase = new Case();
					newCase.RecordTypeId = ssswGeneralEnquiry;
					updateFieldsWithValues(newCase, fieldsAndValues, false);
					System.debug('chatKey : '+chatKey);
					newCase.Origin = chatKey == '' ? 'Phone' : 'Chat';
					newCase.Bypass_Data_enforcement__c = true;

					if (closeEnquiry) {
						System.debug('######## closing enquiry');
						List<String> articleIDs = (List<String>) JSON.deserialize(articlesJSON, Type.forName('List<String>'));
						if (articleIDs.size() == 1) {
							newCase.ReferenceID__c = articleIDs[0];
						}

						// incase the record type was overwritten by updateFieldsWithValues
						newCase.RecordTypeId = ssswGeneralEnquiry;

						newCase.Status = 'Closed';
						newCase.Permanent_Close__c = true;
						newCase.Bypass_Data_enforcement__c = true;
						newCase.ResolutionCode__c = 'FCR';

						// insert a new record
						ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{newCase});

						result = newCase.Id;
						newCases.put(newCase.Id, newCase);
					} else {
						List<String> articleIDs = (List<String>) JSON.deserialize(articlesJSON, Type.forName('List<String>'));
						if (articleIDs.size() > 0) {
							if (articleIDs.size() == 1) {
								newCase.ReferenceID__c = articleIDs[0];

								// insert a new record
								ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{newCase});

								result = newCase.Id;
								newCases.put(newCase.Id, newCase);
							} else {
								List<Case> childCases = new List<Case>();
								Case childCase = null;

								// insert a new record
								ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{newCase});

								for (Integer i = 0; i < articleIDs.size(); i++) {
									childCase = new Case();
									childCase.RecordTypeId = newCase.RecordTypeId;
									updateFieldsWithValues(childCase, fieldsAndValues, false);
									childCase.ReferenceID__c = articleIDs[i];
									childCase.ParentId = newCase.Id;
									childCase.Bypass_Data_enforcement__c = true;
									childCases.add(childCase);
								}

								// insert child cases
								ApplicationDatabase.getInstance().dmlInsert(childCases);

								for (Case c : childCases) {
									newCases.put(c.Id, c);
								}
								result = newCase.Id;
							}
						} else {
							// insert a new record
							ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{newCase});

							result = newCase.Id;
							newCases.put(newCase.Id, newCase);
						}
					}
					//Attach delivery proof
					System.debug('safeDropJSON'+safeDropJSON.length());
					List<String> deliveryProofArticleIds = (List<String>) JSON.deserialize(safeDropJSON, Type.forName('List<String>'));
					if(deliveryProofArticleIds.size() > 0 && newCases.size() > 0) {

						// build a list of cases to attach a delivery proof too based on what the user has selected in the UI
						// best to not assume everything will already be in upper case
						Set<Id> casesForDeliveryProof = new Set<Id>();
						for(String deliveryProofArticleId : deliveryProofArticleIds) {
							deliveryProofArticleId = (!String.isEmpty(deliveryProofArticleId) ? deliveryProofArticleId : '').toUpperCase();
							for(Case c : newCases.values()) {
								String referenceId = (!String.isEmpty(c.ReferenceID__c) ? c.ReferenceID__c : '').toUpperCase();
								if(referenceId == deliveryProofArticleId) {
									casesForDeliveryProof.add(c.Id);
								}
							}
						}

						// attach the pdf delivery proof to the case in an async process
						if(!casesForDeliveryProof.isEmpty()) {
							DeliveryProofService.getInstance().enqueueAttachAPDeliveryProof(casesForDeliveryProof);
						}
					}
				} catch (Exception ex) {
					result = 'Error: ' + ex.getMessage();
				}
			} else if(isDuplicate) {
				result = DUPLICATE;
			}
		}
		return result;
	}

	private static void updateFieldsWithValues(Case newOrExistingCase, Map<String, Object> fieldsAndValues, Boolean ignoreEmptyValues) {
		Map<String, Schema.SObjectField> fieldNames = Schema.SObjectType.Case.fields.getMap();
		for (String key : fieldsAndValues.keySet()) {
			if (fieldNames.containsKey(key)) {
				System.debug('updating ' + key);
				System.debug('with value = ' + fieldsAndValues.get(key));
				if (ignoreEmptyValues) {
					if (fieldsAndValues.get(key) != null && fieldsAndValues.get(key) != '') {
						newOrExistingCase.put(key, fieldsAndValues.get(key));
					}
				} else {
					newOrExistingCase.put(key, fieldsAndValues.get(key));
				}
			}
		}
	}

	public class ExistingCaseOrActivityDisplay {
		public String id { get; set; }
		public String RecordType { get; set; }
		public String refID { get; set; }
		public String ContactName { get; set; }
		public String Subject { get; set; }
		public String Description { get; set; }
		public String Status { get; set; }
		public String Owner { get; set; }
		public Datetime LastModified { get; set; }
		public String CaseOriginator { get; set; }

		public ExistingCaseOrActivityDisplay(String id, String recordType, String refID, String contactName, String subject, String description, String status, String owner, Datetime lastModified, String caseOriginator) {
			this.id = id;
			this.RecordType = recordType;
			this.refID = refID;
			this.ContactName = contactName;
			this.Subject = subject;
			this.Description = description;
			this.Status = status;
			this.Owner = owner;
			this.LastModified = lastModified;
			this.CaseOriginator = caseOriginator;
		}
	}
}