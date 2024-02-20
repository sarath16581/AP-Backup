/**************************************************
Type:       Account Extension Controller
Purpose:    Apex Controller extension that serves as a powerful tool for querying data and managing the navigation flow between distinct agreement types,
			such as Vendor of Interest (VOI) and Apptus agreements.
History:
--------------------------------------------------
22/01/2024 hasantha.liyanage@auspost.com.au Created
24/01/2024 boris.bachovski2@austpost.com.au Added support for Apttus Agreement
**************************************************/

public with sharing class AdobeSignCustomController {
	public Id masterId {get; set;}
	private static String APTTUS_CONTRACT_VIEW_PAGE = '/lightning/r/' + Apttus__APTS_Agreement__c.SObjectType + '/';
	private static String ADOBE_SIGN_TEMPLATE_PAGE = '/apex/echosign_dev1__AgreementTemplateProcess';
	private static String ADOBE_SIGN_AGREEMENT_VIEW_PAGE = '/lightning/r/' + echosign_dev1__SIGN_Agreement__c.SObjectType + '/';
	@TestVisible private static String PAGE_ADOBESIGN_VOI = 'AdobeSignVOI';
	@TestVisible private static String PAGE_ADOBESIGN_APT = 'AdobeSignApttus';
	@TestVisible private static String PAGE_ADOBESIGN_APT_CANCEL = 'AdobeSignApttusCancel';
	@TestVisible private static String TEMPLATE_VOI_PROPERTY = 'VOI_Property';
	@TestVisible private static String TEMPLATE_APTTUS = 'Apttus';
	@TestVisible private static String MSG_ERROR_ORG_MISSING_CONTACT = 'The Organisation is missing a primary contact';
	@TestVisible private static String MSG_ERROR_PAGE_NOT_SUPPORTED = 'Page not supported';
	@TestVisible private static String MSG_ERROR_PAGE_GENERIC = 'Something went wrong please try again later';
	@TestVisible private static String MSG_ERROR_APT_CONTRACT_EXPIRED = 'Cannot Send eSignature for an expired Contract. Please Create a new contract to continue.';
	@TestVisible private static String MSG_ERROR_APT_MISSING_CONTRACT = 'No contract found with the provided Id';

	/**
	 * Base on the page being called route to the requested agreement
	 * @return target PageReference
	 */
	public PageReference redirect(){
		Pagereference pageRef = ApexPages.currentPage();
		try {
			String strUrl = ApexPages.currentPage().getUrl();
			if (strUrl.containsIgnoreCase(PAGE_ADOBESIGN_VOI)) {
				pageRef = navigateToVOIAgreement();
			} else if (strUrl.containsIgnoreCase(PAGE_ADOBESIGN_APT)) {
				pageRef = navigateToApptusAgreement();
			} else {
				ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ERROR_PAGE_NOT_SUPPORTED);
				ApexPages.addMessage(errorMsg);
				return null;
			}
		} catch(Exception ex){
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,MSG_ERROR_PAGE_GENERIC);
			ApexPages.addMessage(errorMsg);
			return null;
		}

		return pageRef;
	}
	
	/**
	 * Navigate to VOI Agreement template process
	 * @return PageReference
	 */
	private PageReference navigateToVOIAgreement() {
		Pagereference pageRef = new Pagereference(ADOBE_SIGN_TEMPLATE_PAGE);
		// get the primary contact of the organisation based on the boolean value of ConveyancerContact__c
		// assumes that there will always be one primary contact per org
		List<contact> primaryContacts = ContactsSelector.newInstance().selectPrimaryContactByAccount(new Set<Id>{
			masterId
		});

		if (primaryContacts != null && primaryContacts.size() > 0) {
			Map <String, String> params = ApexPages.currentPage().getParameters();
			
			for (String key : params.keySet()) {
				pageRef.getParameters().put(key, params.get(key));
			}

			// setting the page reference params to be referenced in the template
			pageRef.getParameters().put('masterId', masterId);
			pageRef.getParameters().put('contactId', primaryContacts[0].Id);

			// read the custom setting to get the template ID by the custom setting name
			AdobeSignTemplateSettings__c voiPropertySetting = getTemplateSetting(TEMPLATE_VOI_PROPERTY);
			pageRef.getParameters().put('templateId', voiPropertySetting.TemplateId__c);
		} else {
			//throws UI exception message when there is no primary contact found
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ERROR_ORG_MISSING_CONTACT);
			ApexPages.addMessage(errorMsg);
			return null;
		}

		return pageRef;
	}

	/**
	 * @param templateName get the template custom setting by the name
	 *
	 * @return AdobeSignTemplateSettings__c
	 */
	private AdobeSignTemplateSettings__c getTemplateSetting(String templateName) {
		Set<SObjectField> fields = new Set<SObjectField>{
				AdobeSignTemplateSettings__c.TemplateId__c, AdobeSignTemplateSettings__c.Name
		};
		CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(AdobeSignTemplateSettings__c.SObjectType, fields);
		Set<String> settingNames = new Set<String>{
				templateName
		};
		Map<String, SObject> voiPropertySettings = (Map<String, SObject>) settingsSelector.selectByNames(settingNames);
		AdobeSignTemplateSettings__c voiPropertySetting = (AdobeSignTemplateSettings__c) voiPropertySettings.get(templateName);
		return voiPropertySetting;
	}

	/**
	 *	Navigate to Apptus Agreement Template Process
	 *	@return Page Reference
	 */
	private PageReference navigateToApptusAgreement() {
		Map <Id, Apttus__APTS_Agreement__c> contracts = ApttusContractsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>> { Apttus__APTS_Agreement__c.SObjectType => new Set<SObjectField>{Apttus__APTS_Agreement__c.DaysUntilContractExpires__c}})
																				.selectById(new Set<Id> {masterId}, new Set<Object>{ApttusContractsSelector.Options.WITH_OPPORTUNITY});

		if (contracts.keySet().size() == 1) {
			Apttus__APTS_Agreement__c contract = contracts.get(masterId);

			if (contract.DaysUntilContractExpires__c <= 0) {
				// Throw UI exception message when the contract has expired
				ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ERROR_APT_CONTRACT_EXPIRED);
				ApexPages.addMessage(errorMsg);
				return null;
			}

			try {
				AdobeSignTemplateSettings__c apptusSetting = getTemplateSetting(TEMPLATE_APTTUS);

				Map <String, String> params = ApexPages.currentPage().getParameters();
		
				// Additional adobe template runtime variables (template specific)
				Map <String, echosign_dev1.AgreementTemplateVariable> vars = new Map <String, echosign_dev1.AgreementTemplateVariable> ();
				
				vars.put('keyContact', new echosign_dev1.AgreementTemplateVariable('keyContact', contract.Apttus__Related_Opportunity__r.KeyContact__c));
				vars.put('ownerId', new echosign_dev1.AgreementTemplateVariable('ownerId', contract.Apttus__Related_Opportunity__r.OwnerId));

				// Generate an agreement based on specified template Id and parent record (master Id), as well as any additional template variables, specified above (Adobe Sign Envelope)
				// This is documented in the Adobe Sign Salesforce Developer Guide: https://helpx.adobe.com/sign/integrations/salesforce-developer-guide.html 
				Id agreementId = echosign_dev1.AgreementTemplateService.load(apptusSetting.TemplateId__c, masterId, vars);

				if (String.isNotEmpty(params.get('attachmentids'))) {
					createNewContentVersionsForSelectedDocuments(agreementId, params.get('attachmentids').split(','));
				}

				return new Pagereference(ADOBE_SIGN_AGREEMENT_VIEW_PAGE + agreementId + '/view');
	
			} catch (Exception e) {
				ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
				ApexPages.addMessage(errorMsg);
				return null;	
			}
		}
		else {
			//throws UI exception message when there is no primary contact found
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ERROR_APT_MISSING_CONTRACT);
			ApexPages.addMessage(errorMsg);
			return null;
		}
	}

	// Create new contenet version for the documents attached to the agreement
	// @param agreementId
	// @param contentDocumentIds
	// @return List<ContentVersion>
	private void createNewContentVersionsForSelectedDocuments(Id agreementId, List <Id> contentDocumentIds) {
		// Currently, Adobe Sign for Salesforce doesn't support the ability to attach multiple files (selected) to an agreement via the API or the UI
		// The only options available are either Latest Document or All Documents.
		// This is a workaround which creates new ContentVersion records for each attachment and then associates them with the agreement	
		Map <Id, ContentVersion> contentVersionByContentDocumentId = new Map <Id, ContentVersion> ();
		for (ContentVersion cv : ContentVersionsSelector.newInstance('CreatedDate', 'DESC').selectByContentDocumentId(new Set <Id> (contentDocumentIds), new set<Object> { ContentVersionsSelector.Options.IS_LATEST_VERSION }).values()) {
			contentVersionByContentDocumentId.put(cv.ContentDocumentId, cv);
		}
		
		List <ContentVersion> contentVersions = new List <ContentVersion> ();

		// Iterate this way to ensure the order of the attachments is preserved
		// Intended behaviour is to have the same order of attachments in the agreement as they were in the attachment list in the previous step (select attachments page)
		for (Id contentDocumentId : contentDocumentIds) {
			ContentVersion existingVersion = contentVersionByContentDocumentId.get(contentDocumentId);
			
			if (existingVersion != null) {
				ContentVersion newVersion = new ContentVersion();
				newVersion.Title  = existingVersion.Title;
				newVersion.PathOnClient  = existingVersion.PathOnClient;
				newVersion.VersionData = existingVersion.VersionData;
				newVersion.IsMajorVersion = true;
				newVersion.FirstPublishLocationId  = agreementId;
				contentVersions.add(newVersion);
			}
		}

		ApplicationDatabase.getInstance().dmlInsert(contentVersions);
	}

	/**
	 * Cancel an agreement
	 * @return target PageReference
	 */
	public PageReference cancelAgreement(){
		Pagereference pageRef = ApexPages.currentPage();
		try {
			String strUrl = ApexPages.currentPage().getUrl();
			if (strUrl.containsIgnoreCase(PAGE_ADOBESIGN_APT_CANCEL)) {
				pageRef = cancelApttusAgreement();
			} else {
				ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ERROR_PAGE_NOT_SUPPORTED);
				ApexPages.addMessage(errorMsg);
				return null;
			}
		} catch(Exception ex){
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ERROR_PAGE_GENERIC);
			ApexPages.addMessage(errorMsg);
			return null;
		}

		return pageRef;
	}
	
	/**
	 *	Navigate to Cancel Apttus Agreement Page
	 *	@return Page Reference
	 */
	private PageReference cancelApttusAgreement() {
		// Query the Adobe Agreement based on parent Apttus Contract Id
		// There should only be a single "Out for Signatures" document for a given Apttus Contract
		List <echosign_dev1__SIGN_Agreement__c> envelopes = AdobeSignAgreementSelector.newInstance(1).selectOutForSignatureByApttusContractId(new Set <Id> { masterId }, new Set<Object>());

		if (envelopes != null && envelopes.size() == 1) {
			Id agreementId = envelopes[0].Id;
			echosign_dev1.EchoSignApiService.cancelDocument(agreementId);
			return new Pagereference(APTTUS_CONTRACT_VIEW_PAGE + masterId + '/view');
		}
		else {
			//throws UI exception message when there is no primary contact found
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ERROR_APT_MISSING_CONTRACT);
			ApexPages.addMessage(errorMsg);
			return null;
		}
	}

	public AdobeSignCustomController(ApexPages.StandardController stdController){
		masterId = (Id)stdController.getId();
	}
}