/**
 * @description
 * Documents API for creating Files and Documents against a particular Organisation
 * See https://australiapost.jira.com/wiki/spaces/SF/pages/1269171196/Entity+Documents+API+v1
 *
 * @author Lija Jawahar
 * @date 2020-09-23
 * @group API
 * @changelog
 * 2020-10-06 - Nathan Franklin - Modified
 * 2020-10-16 - Nathan Franklin - Changed API to Entity Documents API
 */
@RestResource(UrlMapping='/1.0/documents/*')
global with sharing class ResourceDocumentsV1 {

	private static final Set<SObjectType> VALID_ENTITY_TYPES = new Set<SObjectType>{Billing_Account__c.SObjectType, Account.SObjectType, Case.SObjectType};

	@HttpPut
	global static void put(){

		//Catch the Errors
		List<String> validationErrors = new List<String>();

		try {
			//endpoint : /services/apexrest/1.0/documents/60000000
			//			?entity_type=Account&record_type=report&filename=f1&document_type=DIFOT&document_interval=weekly
			//			&document_date=22&community_access=true
			//			It has file attached to request body as binary
			RestRequest request = RestContext.request;

			//get all the query string parameters
			Map<String, String> params = request.params;

			System.debug('request.requestURI: ' + request.requestURI);
			System.debug('params: ' + params);

			// validate the request to make sure all the values entered are correct
			validationErrors = validateRequest('PUT', params);

			// grab the entity id based on the number that was pass in
			// will throw an exception if the URL is not in the correct format
			Id entityId = getEntityId(request.requestURI, params.get('entity_type'), ('true'.equalsIgnoreCase(params.get('attach_to_parent')) ? true : false));
			if(entityId == null) {
				validationErrors.add('Entity Id not found');
			}

			if(validationErrors.isEmpty()) {

				// determines whether or not this file should be exposed to a community or not
				String accessLevel = 'InternalUsers';
				if ('true'.equalsIgnoreCase(params.get('community_access'))) {
					accessLevel = 'AllUsers';
				}

				String documentType = params.get('document_type');
				String documentInterval = params.get('document_interval');
				String documentDateStr = params.get('document_date');
				Date documentDate = (!String.isEmpty(documentDateStr) ? Date.valueOf(documentDateStr) : null);
				String title = params.get('filename').substringBeforeLast('.'); // always have a value since it's validated in validateRequest
				Id recordTypeId = contentVersionRecordTypeMappings.get(params.get('record_type').toLowerCase()).Id; // this will always exist since it's validated in validateRequest

				// given this method is HttpPut, we search for an existing contentdocument so we can upload a new version rather than a new file
				// this allows a document to periodically updated if needed
				// this will only ever find documents connected to the current organisation
				ContentDocumentLink existingContentDocumentLink = searchExistingFiles(entityId, title, recordTypeId, documentDate, documentType, documentInterval);
				System.debug('existingContentDocumentLink: ' + existingContentDocumentLink);

				// insert the file and set the access settings
				ContentVersion documentVersionRecord = new ContentVersion();
				documentVersionRecord.RecordTypeId = recordTypeId;
				documentVersionRecord.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
				documentVersionRecord.PathOnClient = '/' + params.get('filename'); // The files name, extension is very important here which will help the file in preview.
				documentVersionRecord.Title = title; // Display name of the files
				documentVersionRecord.VersionData = request.requestBody; // converting your binary string to Blob
				documentVersionRecord.Document_Type__c = params.get('document_type');
				documentVersionRecord.Document_Interval__c = params.get('document_interval');
				documentVersionRecord.Document_Date__c = documentDate;
				if(existingContentDocumentLink != null) {
					documentVersionRecord.ContentDocumentId = existingContentDocumentLink.ContentDocumentId;
				}

				// insert contentVersion
				ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{documentVersionRecord});
				System.debug(documentVersionRecord);

				// Grab the content document record that was automatically created with the ContentVersion record
				ContentVersion contentVersionRecord = ContentVersionsSelector.newInstance().selectById(new Set<Id>{documentVersionRecord.Id}).values()[0];
				System.debug(contentVersionRecord);

				// we only need to set up links if they previously were not already setup
				if(existingContentDocumentLink == null) {
					// Create content document link
					ContentDocumentLink documentLinkRecord = new ContentDocumentLink();
					documentLinkRecord.LinkedEntityId = entityId;
					documentLinkRecord.ContentDocumentId = contentVersionRecord.ContentDocumentId;
					documentLinkRecord.ShareType = 'I';
					documentLinkRecord.Visibility = accessLevel;

					// insert the sharing record to the organisation and maybe community too (if community_access was true)
					ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{documentLinkRecord});
					System.debug(documentLinkRecord);

				} else if(!accessLevel.equalsIgnoreCase(existingContentDocumentLink.Visibility)) {

					// the current sharing setting does not match what was passed into the upsert
					// we need to update the existing sharing so it matches the latest request
					ContentDocumentLink documentLinkRecord = new ContentDocumentLink(Id = existingContentDocumentLink.Id, Visibility = accessLevel);
					ApplicationDatabase.getInstance().dmlUpdate(new List<ContentDocumentLink>{documentLinkRecord});

				}

				//Success response message
				JSONResponse responseObj = new JSONResponse(true, contentVersionRecord, null);

				//Serialising successful response message
				writeSerialisedOutput(responseObj, 200);
			} else {
				// A validation error occurred
				JSONResponse responseObj = new  JSONResponse(false, null, validationErrors);

				//Serialising response message
				writeSerialisedOutput(responseObj, 500);
			}

		} catch(Exception e){
			System.debug(e);

			//Error message -catch the thrown exception
			validationErrors.add(e.getMessage());
			JSONResponse responseObj = new  JSONResponse(false, null, validationErrors);

			//Serialising response message
			writeSerialisedOutput(responseObj,500);
		}

	}

	/**
	 * Make sure the request is valid before creating a new file
	 */
	@TestVisible
	private static List<String> validateRequest(String httpMethod, Map<String, String> params) {
		List<String> errorOutput = new List<String>();

		String recordType = params.get('record_type');
		String filename = params.get('filename');
		String documentType = params.get('document_type');
		String documentInterval = params.get('document_interval');
		String communityAccess = params.get('community_access');
		Date documentDate = null;
		String documentDateStr = params.get('document_date');
		String entityType = params.get('entity_type');
		String attachToParent = params.get('attach_to_parent');

		Set<String> validBooleans = new Set<String>{'true', 'false'};

		// if there is a date then try and convert it to a date to ensure the value is valid
		// it should be in YYYY-mm-dd format
		if(!String.isEmpty(documentDateStr)) {
			try {
				documentDate = Date.valueOf(documentDateStr);
			} catch(Exception ex) {
				errorOutput.add('Document date is not valid');
			}
		}

		if(!String.isEmpty(communityAccess) && !validBooleans.contains(communityAccess.toLowerCase())) {
			errorOutput.add('Community Access is not valid');
		}

		if('Report'.equalsIgnoreCase(recordType)) {
			if(String.isEmpty(documentDateStr)) {
				errorOutput.add('Document date is required');
			}
			if(String.isEmpty(documentInterval)) {
				errorOutput.add('Document interval is required');
			}
			if(String.isEmpty(documentType)) {
				errorOutput.add('Document type is required');
			}
		}

		// make sure the request is valid before creating the file
		if(!contentVersionRecordTypeMappings.containsKey((String.isEmpty(recordType) ? '' : recordType.toLowerCase()))) {
			errorOutput.add('Record type is not valid');
		}

		// make sure it's a valid SObject and the sobject is in the list of allowed entities
		// this keeps the documents api scope tight and locked down for security
		try {
			SObjectType sObjectEntityType = getSObjectTypeFromString(entityType);

			if(!VALID_ENTITY_TYPES.contains(sObjectEntityType)) {
				errorOutput.add('Entity Type is not valid');
			}
		} catch(Exception ex) {
			errorOutput.add('Entity Type is not valid');
		}

		if(String.isBlank(filename)){
			errorOutput.add('File name is not valid');
		}

		if(!String.isEmpty(attachToParent) && !validBooleans.contains(attachToParent.toLowerCase())) {
			errorOutput.add('Attach to parent is not valid');
		}

		return errorOutput;
	}

	private static Map<String, RecordType> contentVersionRecordTypeMappings {
		get {
			if(contentVersionRecordTypeMappings == null) {
				List<RecordType> recordTypes = RecordTypesSelector.newInstance().selectBySObject('ContentVersion').values();
				Map<String, RecordType> recordTypeDeveloperNameMappings = new Map<String, RecordType>();
				for(RecordType rt : recordTypes) {
					recordTypeDeveloperNameMappings.put(rt.DeveloperName.toLowerCase(), rt);
				}

				contentVersionRecordTypeMappings = recordTypeDeveloperNameMappings;
			}

			return contentVersionRecordTypeMappings;
		}
		set;
	}

	/**
	 * Grab a record id based on the entity number from the uri.
	 * This also allows a parent to be selected (if the entity supports it) if the attach_to_parent attribute has been passed in
	 */
	@TestVisible
	private static Id getEntityId(String uri, String entityType, Boolean useParent) {
		uri = uri.split('\\?')[0];
		System.debug(uri);

		Pattern regexPattern = Pattern.compile('(?i).*?\\/\\d{1,2}\\.\\d{1,2}\\/documents\\/([T|P]?\\d{0,9})[\\/]?$');
		Matcher uriMatcher = regexPattern.matcher(uri);
		if(!uriMatcher.matches()) {
			throw new ApiException('Entity ID is not valid');
		}

		// grab the entity id from the reg ex
		SObjectType entitySObjectType = getSObjectTypeFromString(entityType);
		String entityNumber = uriMatcher.group(1);
		if(entitySObjectType == null || String.isEmpty(entityNumber)) {
			throw new ApiException('Entity ID is not valid');
		}
		System.debug('Found Entity Id: ' + entityNumber);

		SObjectField fieldName = null;
		List<SObject> entities = new List<SObject>();

		if (entitySObjectType == Account.SObjectType) {
			fieldName = Account.Id;
			entities = AccountsSelector.newInstance(0, new Set<SObjectField>{fieldName}).selectByAccountNumber(new Set<String>{entityNumber}).values();
		} else if (entitySObjectType == Case.SObjectType) {
			fieldName = Case.Id;
			entities = CasesSelector.newInstance(0, new Set<SObjectField>{fieldName}).selectByCaseNumber(new Set<String>{entityNumber}).values();
		} else if (entitySObjectType == Billing_Account__c.SObjectType) {
			fieldName = (useParent ? Billing_Account__c.Organisation__c : Billing_Account__c.Id);
			entities = BillingAccountsSelector.newInstance(0, new Set<SObjectField>{fieldName}).selectByAccountNumber(new Set<String>{entityNumber}).values();
		}

		if(!entities.isEmpty()) {
			Id entityId = (Id)entities[0].get(fieldName);
			System.debug(entityId);
			return entityId;
		} else {
			return null;
		}
	}

	private static SObjectType getSObjectTypeFromString(String sObjectType) {
		try {
			return ((SObject) Type.forName(sObjectType).newInstance()).getSObjectType();
		} catch(Exception ex) {
			return null;
		}
	}

	/**
	 * Search for an existing file as a part of an upsert operation
	 *
	 * @param organisationId Id Used to search LinkedEntity
	 * @param documentTitle Used to match against ContentDocument
	 * @param recordTypeId Used to match against ContentDocument.LatestPublishedVersion
	 * @param documentDate Used to match against ContentDocument.LatestPublishedVersion
	 * @param documentType Used to match against ContentDocument.LatestPublishedVersion
	 * @param documentInterval Used to match against ContentDocument.LatestPublishedVersion
	 *
	 * @return ContentDocumentLink
	 */
	@TestVisible
	private static ContentDocumentLink searchExistingFiles(Id entityId, String documentTitle, Id recordTypeId, Date documentDate, String documentType, String documentInterval) {
		Map<String, Object> upsertSearchParams = new Map<String, Object>{
				'contentVersionRecordTypeId' => recordTypeId,
				'entityIds' => entityId,
				'titles' => new Set<String>{documentTitle}
		};

		// populate optional values even if they are null, this will force a match only if all the values match
		upsertSearchParams.put('contentVersionDocumentDates', new Set<Date>{documentDate});
		upsertSearchParams.put('contentVersionDocumentTypes', new Set<String>{documentType});
		upsertSearchParams.put('contentVersionDocumentIntervals', new Set<String>{documentInterval});

		// given this method is a HttpPut
		// check if we need to upload a new version rather than create a new document
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				ContentVersion.SObjectType => new Set<SObjectField>{ContentVersion.Id},
				ContentDocumentLink.SObjectType => new Set<SObjectField>{ContentDocumentLink.ContentDocumentId, ContentDocumentLink.Visibility, ContentDocumentLink.LinkedEntityId, ContentDocumentLink.ShareType}
		};

		List<ContentDocumentLink> documentLinks = ContentDocumentLinksSelector.newInstance(1, fieldOverrides).search(upsertSearchParams, true).values();
		if(documentLinks.isEmpty()) {
			return null;
		} else {
			// as an added security measure, force a check to make sure the returned entity based on the entity mapped in this API call
			// this protects us from any potential changes to the search method
			// We would rather an unhandled error be thrown if the returned record does not match then allow the flow to continue where a document could be connected to the wrong record
			System.assertEquals(entityId, documentLinks[0].LinkedEntityId);

			return documentLinks[0];
		}
	}

	/**
	* Serialization of the json response message
	*/
	private static void writeSerialisedOutput(Object responseObj, Integer statusCode){
		//Retrieving the response from the REST API context
		RestResponse res = RestContext.response;
		if (res == null){
			res = new RestResponse();
			RestContext.response = res;
		}

		res.addHeader('Content-Type', 'application/json');
		res.statusCode = statusCode;

		//Blob value of the serialised response
		res.responseBody = Blob.valueOf(JSON.serializePretty(responseObj, true));
	}

	/**
	* To set up the response for the calls, which will pass the Id or error message
	*/
	global class JSONResponse {

		//Whether response received is success or failure
		public Boolean success;
		public Id id;
		public String versionNumber;
		public List<String> errors;

		//Constructor for providing the success or failure response
		public JSONResponse(Boolean success, ContentVersion contentVersionRecord, List<String> errors){
			this.success = success;
			this.errors = errors;

			if(contentVersionRecord != null) {
				this.id = contentVersionRecord.ContentDocumentId;
				this.versionNumber = contentVersionRecord.VersionNumber;
			}
		}
	}

	public class ApiException extends Exception {}
}