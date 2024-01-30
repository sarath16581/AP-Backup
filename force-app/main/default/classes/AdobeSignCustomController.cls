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
	private static String ADOBE_SIGN_TEMPLATE_PAGE = '/apex/echosign_dev1__AgreementTemplateProcess';
	@TestVisible private static String PAGE_ADOBESIGN_VOI = 'AdobeSignVOI';
	@TestVisible private static String PAGE_ADOBESIGN_APT = 'AdobeSignApttus';
	@TestVisible private static String TEMPLATE_VOI_PROPERTY = 'VOI_Property';
	@TestVisible private static String TEMPLATE_APTTUS = 'Apttus';
	@TestVisible private static String MSG_ERROR_ORG_MISSING_CONTACT = 'The Organisation has missing a primary contact';
	@TestVisible private static String MSG_ERROR_PAGE_NOT_SUPPORTED = 'Page not supported';
	@TestVisible private static String MSG_ERROR_PAGE_GENERIC = 'Something went wrong please try again later';
	@TestVisible private static String MSG_ERROR_APT_CONTRACT_EXPIRED = 'Cannot Send eSignature for an expired Contract. Please Create a new contract to continue.';
	@TestVisible private static String MSG_ERROR_APT_MISSING_CONTRACT = 'No contract found with the provided Id';

	/**
	 * Base on the page being called route to the requestedno agreement
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
		Pagereference pageRef = new Pagereference(ADOBE_SIGN_TEMPLATE_PAGE);
		
		Map <Id, Apttus__APTS_Agreement__c> contracts = ApttusContractsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>> {
														Apttus__APTS_Agreement__c.SObjectType => new Set<SObjectField>{Apttus__APTS_Agreement__c.DaysUntilContractExpires__c}
													}).selectById(new Set <Id> {
														masterId
													});
		if (contracts.keySet().size() == 1) {
			if (contracts.get(masterId).DaysUntilContractExpires__c <= 0) {
				// Throw UI exception message when the contract has expired
				ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ERROR_APT_CONTRACT_EXPIRED);
				ApexPages.addMessage(errorMsg);
				return null;
			}

			Map <String, String> params = ApexPages.currentPage().getParameters();
			
			// Pass through any parameters that were passed to this page
			for (String key : params.keySet()) {
				pageRef.getParameters().put(key, params.get(key));
			}

			pageRef.getParameters().put('masterId', masterId);
			// read the custom setting to get the template ID by the custom setting name
			AdobeSignTemplateSettings__c apptusSetting = getTemplateSetting(TEMPLATE_APTTUS);
			pageRef.getParameters().put('templateId', apptusSetting.TemplateId__c);
		}
		else {
			//throws UI exception message when there is no primary contact found
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ERROR_APT_MISSING_CONTRACT);
			ApexPages.addMessage(errorMsg);
			return null;
		}

		return pageRef;
	}

	public AdobeSignCustomController(ApexPages.StandardController stdController){
		masterId = (Id)stdController.getId();
	}
}