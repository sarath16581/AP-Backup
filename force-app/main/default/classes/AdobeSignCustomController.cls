/**************************************************
Type:       Account Extension Controller
Purpose:    Apex Controller extension that serves as a powerful tool for querying data and managing the navigation flow between distinct agreement types,
			such as Vendor of Interest (VOI) and Apptus agreements.
History:
--------------------------------------------------
22/01/2024 hasantha.liyanage@auspost.com.au Created
**************************************************/

public with sharing class AdobeSignCustomController {
	public Id masterId {get; set;}
	private static String PAGE_ADOBESIGN_VOI = 'AdobeSignVOI';
	private static String PAGE_ADOBESIGN_APT = 'AdobeSignApptus';

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
				//TODO : call redirect method to apptus
			}

		} catch(Exception ex){
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Something went wrong please try again later');
			ApexPages.addMessage(errorMsg);
		}
		return pageRef;
	}

	/**
	 * Navigate to
	 * @return
	 */
	private PageReference navigateToVOIAgreement() {
		PageReference pageRef;
		// get the primary contact of the organisation based on the boolean value of ConveyancerContact__c
		// assumes that there will always be one primary contact per org
		List<contact> primaryContacts = ContactsSelector.newInstance().selectPrimaryContactByAccount(new Set<Id>{
				masterId
		});

		if (primaryContacts.size() > 0) {
			Map <String, String> params = ApexPages.currentPage().getParameters();
			//TODO : should the templateIds stored in custom metadata? or query?
			pageRef = new Pagereference('/apex/echosign_dev1__AgreementTemplateProcess?masterId=' + masterId + '&templateId=aF21m0000008OgcCAE&contactId='+primaryContacts[0].Id);

			for (String key : params.keySet()) {
				pageRef.getParameters().put(key, params.get(key));
			}
		} else {
			//throws UI exception message when there is no primary contact found
			ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The Organisation has missing a primary contact');
			ApexPages.addMessage(errorMsg);
		}
		return pageRef;
	}

	public AdobeSignCustomController(ApexPages.StandardController stdController){
		masterId = (Id)stdController.getId();
	}
}
