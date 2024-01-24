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
	private static String PAGE_ADOBESIGN_VOI = 'AdobeSignVOI';
	private static String PAGE_ADOBESIGN_APT = 'AdobeSignApttus';

	/**
	 * Base on the page being called route to the requested agreement
	 * @return
	 */
	public PageReference redirect(){
		Pagereference pageRef = ApexPages.currentPage();

		try {
			String strUrl = ApexPages.currentPage().getUrl();
			if (strUrl.contains(PAGE_ADOBESIGN_VOI)) {
				pageRef = navigateToVOIAgreement();
			} else if (strUrl.contains(PAGE_ADOBESIGN_APT)) {
				pageRef = navigateToApptusAgreement();
			} else {
				ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Object type not supported');
				ApexPages.addMessage(errorMsg);
				return null;
			}
		} catch(Exception ex){
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Something went wrong please try again later');
			ApexPages.addMessage(errorMsg);
			return null;
		}

		return pageRef;
	}
	
	/**
	 * Navigate to
	 * @return
	 */
	private PageReference navigateToVOIAgreement() {
		Pagereference pageRef = new Pagereference(ADOBE_SIGN_TEMPLATE_PAGE);

		// get the primary contact of the organisation based on the boolean value of ConveyancerContact__c
		// assumes that there will always be one primary contact per org
		List<contact> primaryContacts = ContactsSelector.newInstance().selectPrimaryContactByAccount(new Set<Id>{
			masterId
		});

		if (primaryContacts.size() > 0) {
			Map <String, String> params = ApexPages.currentPage().getParameters();
			
			for (String key : params.keySet()) {
				pageRef.getParameters().put(key, params.get(key));
			}

			pageRef.getParameters().put('masterId', masterId);
			pageRef.getParameters().put('contactId', primaryContacts[0].Id);
			// TODO - move this to a custom setting
			pageRef.getParameters().put('templateId', 'aF21m0000008OgcCAE');
		} else {
			//throws UI exception message when there is no primary contact found
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The Organisation has missing a primary contact');
			ApexPages.addMessage(errorMsg);
			return null;
		}

		return pageRef;
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
			if (contracts.get(masterId).DaysUntilContractExpires__c < 0) {
				// Throw UI exception message when the contract has expired
				ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The contract has expired');
				ApexPages.addMessage(errorMsg);
				return null;
			}

			Map <String, String> params = ApexPages.currentPage().getParameters();
			
			// Pass through any parameters that were passed to this page
			for (String key : params.keySet()) {
				pageRef.getParameters().put(key, params.get(key));
			}

			pageRef.getParameters().put('masterId', masterId);
			// TODO - move this to a custom setting
			pageRef.getParameters().put('templateId', 'aF21m0000008OgKCAU');
		}
		else {
			//throws UI exception message when there is no primary contact found
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No contract found with the provided Id');
			ApexPages.addMessage(errorMsg);
			return null;
		}

		return pageRef;
	}

	public AdobeSignCustomController(ApexPages.StandardController stdController){
		masterId = (Id)stdController.getId();
	}
}