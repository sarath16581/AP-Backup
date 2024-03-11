/**************************************************
Type:       Account Extension Controller
Purpose:    Apex Controller extension that serves as a powerful tool for querying data and managing the navigation flow between distinct agreement types,
			such as Vendor of Interest (VOI) and Apptus agreements.
History:
--------------------------------------------------
22/01/2024 hasantha.liyanage@auspost.com.au Created
24/01/2024 boris.bachovski2@austpost.com.au Added support for Apttus Agreement
26/02/2024 boris.bachovski2@austpost.com.au Refactor to use Aura URL addressable components instead of VF pages
**************************************************/

public with sharing class AdobeSignCustomController {
	public Id masterId {get; set;}
	@TestVisible private static String APTTUS_CONTRACT_VIEW_PAGE = '/lightning/r/' + Apttus__APTS_Agreement__c.SObjectType + '/';
	@TestVisible private static String ADOBE_SIGN_AGREEMENT_VIEW_PAGE = '/lightning/r/' + echosign_dev1__SIGN_Agreement__c.SObjectType + '/';
	@TestVisible private static String TEMPLATE_VOI_PROPERTY = 'VOI_Property';
	@TestVisible private static String TEMPLATE_APTTUS = 'Apttus';
	@TestVisible private static String MSG_ERROR_ORG_MISSING_CONTACT = 'The Organisation is missing a primary contact';
	@TestVisible private static String MSG_ERROR_PAGE_NOT_SUPPORTED = 'Page not supported';
	@TestVisible private static String MSG_ERROR_PAGE_GENERIC = 'Something went wrong please try again later';
	@TestVisible private static String MSG_ERROR_APT_CONTRACT_EXPIRED = 'Cannot Send eSignature for an expired Contract. Please Create a new contract to continue.';
	@TestVisible private static String MSG_ERROR_APT_MISSING_CONTRACT = 'No contract found with the provided Id';

	/**
	 * @param referenceComponent the name of the Aura component calling this method
	 * @param masterId the Id of the parent record (Account or Apttus Contract currently supported)
	 * @return Generic Object
	 */
	@AuraEnabled
	public static Object autoRedirect(String referenceComponent, String masterId, String attachmentIds){
		try {
			switch on referenceComponent {
				when 'AdobeSignVOI' {
					return navigateToVOI((Id)masterId);
				}
				when 'AdobeSignApttus' {
					return navigateToApttus((Id)masterId, attachmentIds?.split(',') ?? new List <Id> ());
				}
				when 'AdobeSignApttusCancel' {
					return cancelApttusAgreement((Id)masterId);
				}
				when else {
					AuraHandledException ae = new AuraHandledException(MSG_ERROR_PAGE_NOT_SUPPORTED);
					ae.setMessage(MSG_ERROR_PAGE_NOT_SUPPORTED);
					throw ae;
				}
			}
		} catch (Exception ex){
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Adobe Sign', AdobeSignCustomController.class.getName(), 'autoRedirect', 'N/A', LoggingLevel.ERROR);
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * @param masterId the Id of the parent record (Account or Apttus Contract currently supported)
	 * @return RedirectResponse inner class instance containing the pageRef that the aura component should auto redirect to
	 */
	@TestVisible
	private static RedirectResponse navigateToVOI(Id masterId) {
		List<contact> primaryContacts = ContactsSelector.newInstance().selectPrimaryContactByAccount(new Set<Id>{ masterId });

		if (primaryContacts != null && primaryContacts.size() > 0) {
			// Get Adobe Sign Template Settings
			AdobeSignTemplateSettings__c voiPropertySetting = getTemplateSetting(TEMPLATE_VOI_PROPERTY);

			// Additional adobe template runtime variables (template specific)
			Map <String, echosign_dev1.AgreementTemplateVariable> vars = new Map <String, echosign_dev1.AgreementTemplateVariable> ();
			vars.put('contactId', new echosign_dev1.AgreementTemplateVariable('contactId', primaryContacts[0].Id));

			// Generate an agreement based on specified template Id and parent record (master Id), as well as any additional template variables, specified above (Adobe Sign Envelope)
			// This is documented in the Adobe Sign Salesforce Developer Guide: https://helpx.adobe.com/sign/integrations/salesforce-developer-guide.html
			Id agreementId = null;
			if(!Test.isRunningTest()){
				agreementId = echosign_dev1.AgreementTemplateService.load(voiPropertySetting.TemplateId__c, masterId, vars);
			}
			return new RedirectResponse(ADOBE_SIGN_AGREEMENT_VIEW_PAGE + agreementId + '/view');
		} else {
			// No primary contact found
			AuraHandledException ae = new AuraHandledException(MSG_ERROR_ORG_MISSING_CONTACT);
			ae.setMessage(MSG_ERROR_ORG_MISSING_CONTACT);
			throw ae;
		}
	}

	/**
	 * @param masterId the Id of the parent record (Account or Apttus Contract currently supported)
	 * @param attachmentIds the Ids of the documents to attach to the agreement
	 * @return RedirectResponse inner class instance containing the pageRef that the aura component should auto redirect to
	 */
	private static RedirectResponse navigateToApttus(Id masterId, List <Id> attachmentIds) {
		Map <Id, Apttus__APTS_Agreement__c> contracts = ApttusContractsSelector.newInstance(
																				1, 
																				new Map<SObjectType, Set<SObjectField>> { 
																						Apttus__APTS_Agreement__c.SObjectType => new Set<SObjectField> { Apttus__APTS_Agreement__c.DaysUntilContractExpires__c }
																				}).selectById(
																					new Set<Id> { masterId }, 
																					new Set<Object>{ ApttusContractsSelector.Options.WITH_OPPORTUNITY
																				});
		if (contracts.keySet().size() == 1) {
			Apttus__APTS_Agreement__c contract = contracts.get(masterId);

			// Throw UI exception message when the contract has expired
			if (contract.DaysUntilContractExpires__c <= 0) {
				AuraHandledException ae = new AuraHandledException(MSG_ERROR_APT_CONTRACT_EXPIRED);
				ae.setMessage(MSG_ERROR_APT_CONTRACT_EXPIRED);
				throw ae;
			}

			try {
				AdobeSignTemplateSettings__c apptusSetting = getTemplateSetting(TEMPLATE_APTTUS);

				// Additional adobe template runtime variables (template specific)
				Map <String, echosign_dev1.AgreementTemplateVariable> vars = new Map <String, echosign_dev1.AgreementTemplateVariable> ();
				vars.put('keyContact', new echosign_dev1.AgreementTemplateVariable('keyContact', contract.Apttus__Related_Opportunity__r.KeyContact__c));
				vars.put('ownerId', new echosign_dev1.AgreementTemplateVariable('ownerId', contract.Apttus__Related_Opportunity__r.OwnerId));

				// Generate an agreement based on specified template Id and parent record (master Id), as well as any additional template variables, specified above (Adobe Sign Envelope)
				// This is documented in the Adobe Sign Salesforce Developer Guide: https://helpx.adobe.com/sign/integrations/salesforce-developer-guide.html
				Id agreementId = null;
				if(!Test.isRunningTest()){
					agreementId = echosign_dev1.AgreementTemplateService.load(apptusSetting.TemplateId__c, masterId, vars);
				}

				if (attachmentIds != null && !attachmentIds.isEmpty()) {
					createNewContentVersionsForSelectedDocuments(agreementId, attachmentIds);
				}

				return new RedirectResponse(ADOBE_SIGN_AGREEMENT_VIEW_PAGE + agreementId + '/view');	
			} catch (Exception e) {
				throw new AuraHandledException(e.getMessage());
			}
		}
		else {
			// No primary contact found
			AuraHandledException ae = new AuraHandledException(MSG_ERROR_APT_MISSING_CONTRACT);
			ae.setMessage(MSG_ERROR_APT_MISSING_CONTRACT);
			throw ae;
		}
	}

	
	
	/**
	 * @description Cancel an Apttus Agreement that's in the "Out for Signatures" or "Waiting for Counter Signature" status
	 * @param masterId the Id of the parent record (Account or Apttus Contract currently supported)
	 * @return RedirectResponse inner class instance containing the pageRef that the aura component should auto redirect to
	 */
	private static RedirectResponse cancelApttusAgreement(String masterId) {
		// Query the Adobe Agreement based on parent Apttus Contract Id
		// There should only be a single "Out for Signatures" or "Waiting for Counter Signature" document for a given Apttus Contract
		List <echosign_dev1__SIGN_Agreement__c> envelopes = AdobeSignAgreementSelector.newInstance(1).selectOutForSignatureByApttusContractId(new Set <Id> { masterId }, new Set<Object>());

		if (envelopes != null && envelopes.size() == 1) {
			Id agreementId = envelopes[0].Id;
			echosign_dev1.EchoSignApiService.cancelDocument(agreementId);
			
			return new RedirectResponse(APTTUS_CONTRACT_VIEW_PAGE + masterId + '/view');
		}
		else {
			// No primary contact, or multiple contracts found
			AuraHandledException ae = new AuraHandledException(MSG_ERROR_APT_MISSING_CONTRACT);
			ae.setMessage(MSG_ERROR_APT_MISSING_CONTRACT);
			throw ae;
		}
	}

	// --------------
	// Helper Methods
	// --------------

	/**
	 * @param templateName get the template custom setting by the name
	 *
	 * @return AdobeSignTemplateSettings__c
	 */
	private static AdobeSignTemplateSettings__c getTemplateSetting(String templateName) {
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
	 * @description Create new ContentVersion records for the selected documents and associate them with the agreement
	 * @param agreementId the Id of the agreement record to attach the documents to
	 * @param contentDocumentIds the Ids of the documents to attach to the agreement
	 * @return void
	 */
	@TestVisible
	private static void createNewContentVersionsForSelectedDocuments(Id agreementId, List <Id> contentDocumentIds) {
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


	// -------------
	// Inner Classes
	// -------------
	@TestVisible
	private class RedirectResponse {
		@AuraEnabled
		public String pageRef;

		public RedirectResponse(String pageRef){
			this.pageRef = pageRef;
		}
	}
}