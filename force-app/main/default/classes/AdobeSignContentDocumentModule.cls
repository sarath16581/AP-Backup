/**************************************************
Description:   Module Adobe Sign Content Document
History:
--------------------------------------------------
2024-02-12 - H Liyanage - Created
2024-03-04 - H Liyanage added preventDeletionOfSignedDocusignDocuments()
2024-03-28 - H Liyanage added preventDeletionDocuments()
**************************************************/

public inherited sharing class AdobeSignContentDocumentModule extends ApplicationModule {
	@TestVisible private static String ADOBE_COMPLETED_CONTRACT_SUFFIX = '- Signed.pdf';
	@TestVisible private static String DOCUSIGN_COMPLETED_CONTRACT_SUFFIX_APT = '__signed.pdf';
	@TestVisible private static String DOCUSIGN_COMPLETED_CONTRACT_SUFFIX_VOI = '_completed.pdf';
	@TestVisible private static String MSG_DELETE_CONTRACT_VALIDATION = 'Cannot delete ContentDocument with a link to a signed Agreement';

	/**
	 * @deprecated
	 */
	public static AdobeSignContentDocumentModule newInstance() {
		return (AdobeSignContentDocumentModule) Application.Utilities.newInstance(AdobeSignContentDocumentModule.class);
	}

	// Setup which triggers this module should respond to
	public AdobeSignContentDocumentModule() {
		getTriggerEvents().enableBeforeDelete();
	}


	/**
	* Called before a Delete
	* Performs below operations
	* 1. Prevent deletion of Content document for Adobe sign signed agreements
	*/
	public override void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			preventDeletionDocuments(records, uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'ADOBE SIGN', AdobeSignContentDocumentModule.class.getName(), 'onAfterInsert', 'CONTENT DOCUMENT TRIGGER', LoggingLevel.ERROR);
		}
	}

	/**
	 * Prevent deletion of signed document records according to the permissions given on Adobe and docusign signed documents
	 * @param records ContentDocuments
	 * @param uow Unit of work
	 */
	public void preventDeletionDocuments(List<SObject> records, ApplicationUnitOfWork uow) {
		// Collect the Ids of ContentDocuments being deleted
		List<ContentDocument> adobeContentDocumentRecords = new List<ContentDocument>();
		List<ContentDocument> docusignContentDocumentRecords = new List<ContentDocument>();

		for (ContentDocument cd : (List<ContentDocument>)records) {
			if(cd.Title.endsWithIgnoreCase(ADOBE_COMPLETED_CONTRACT_SUFFIX)) {
				adobeContentDocumentRecords.add(cd);
			}
			if(cd.Title.endsWithIgnoreCase(DOCUSIGN_COMPLETED_CONTRACT_SUFFIX_VOI) || cd.Title.endsWithIgnoreCase(DOCUSIGN_COMPLETED_CONTRACT_SUFFIX_APT)){
				docusignContentDocumentRecords.add(cd);
			}
		}
		if(!adobeContentDocumentRecords.isEmpty()) {
			preventDeletionOfSignedDocuments(adobeContentDocumentRecords, uow);
		}
		if(!docusignContentDocumentRecords.isEmpty()) {
			preventDeletionOfSignedDocusignDocuments(docusignContentDocumentRecords, uow);
		}
	}

	/**
	 * Prevent deletion of documents links to other objects which are originally created for echosign_dev1__SIGN_Agreement__c object.
	 * echosign_dev1__SIGN_Agreement__c object hold the evidence of the sign document and this should not be deleted
	 * @param records ContentDocuments
	 */
	public void preventDeletionOfSignedDocuments(List<ContentDocument> records, ApplicationUnitOfWork uow) {

		// Prevent deletion of adobesign signed documnts
		Boolean hasCustomPermission = FeatureManagement.checkPermission('AllowDeleteOnAdobeSignContracts');

		// if the user has privilege to delete, do not need further checks
		if(hasCustomPermission) {
			return;
		}

		// Collect the Ids of ContentDocuments being deleted
		Set<Id> contentDocumentIds = new Set<Id>();
		for (ContentDocument cd : records) {
			contentDocumentIds.add(cd.Id);
		}

		// prepare a map of content document link Ids to look for entity IDs
		Map<Id, List<Id>> contentDocumentLinksMap = new Map<Id, List<Id>>();


		Map<Id, ContentDocumentLink> adobeAgreementContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(
				new Map<String, Object>{ 'documentIds' => contentDocumentIds},true);
		for (ContentDocumentLink cdl : adobeAgreementContentDocumentLinks.values()) {
			if (!contentDocumentLinksMap.containsKey(cdl.ContentDocumentId)) {
				contentDocumentLinksMap.put(cdl.ContentDocumentId, new List<Id>());
			}
			contentDocumentLinksMap.get(cdl.ContentDocumentId).add(cdl.LinkedEntityId);
		}

		// perform the check and add the error
		for (ContentDocument cd : records) {
			if (contentDocumentLinksMap.containsKey(cd.Id)) {
				for (Id linkedEntityId : contentDocumentLinksMap.get(cd.Id)) {
					if (!hasCustomPermission && linkedEntityId.getSObjectType() == echosign_dev1__SIGN_Agreement__c.SObjectType && cd.Title.endsWithIgnoreCase(ADOBE_COMPLETED_CONTRACT_SUFFIX)) {
						cd.addError(MSG_DELETE_CONTRACT_VALIDATION);
					}
				}
			}
		}
	}

	/**
	 * Prevents the deletion of completed documents from DocuSign.
	 * This method shares similarities with preventDeletionOfSignedDocuments(),
	 * but it's introduced separately due to the upcoming decommissioning of DocuSign.
	 * Separating this logic ensures easy decommissioning without impacting AdobeSign operations.
	 * @param records list of ContentDocuments
	 * @param uow unit of work context
	 */
	public void preventDeletionOfSignedDocusignDocuments(List<ContentDocument> records, ApplicationUnitOfWork uow) {
		// Prevent deletion of adobesign signed documnts
		Boolean hasCustomPermission = FeatureManagement.checkPermission('AllowDeleteOnDocuSignContracts');

		// if the user has privilege to delete, do not need further checks
		if(hasCustomPermission) {
			return;
		}

		// Collect the Ids of ContentDocuments being deleted
		Set<Id> contentDocumentIds = new Set<Id>();
		for (ContentDocument cd : records) {
			contentDocumentIds.add(cd.Id);

		}

		// prepare a map of content document link Ids to look for entity IDs
		Map<Id, List<Id>> contentDocumentLinksMap = new Map<Id, List<Id>>();


		Map<Id, ContentDocumentLink> adobeAgreementContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(
				new Map<String, Object>{ 'documentIds' => contentDocumentIds},true);
		for (ContentDocumentLink cdl : adobeAgreementContentDocumentLinks.values()) {
			if (!contentDocumentLinksMap.containsKey(cdl.ContentDocumentId)) {
				contentDocumentLinksMap.put(cdl.ContentDocumentId, new List<Id>());
			}
			contentDocumentLinksMap.get(cdl.ContentDocumentId).add(cdl.LinkedEntityId);
		}

		// perform the check and add the error
		for (ContentDocument cd : records) {
			if (contentDocumentLinksMap.containsKey(cd.Id)) {
				for (Id linkedEntityId : contentDocumentLinksMap.get(cd.Id)) {
					// when organisation signed contracts are saved with suffix '- completed' or
					// when apttus contract '__Signed'
					if (!hasCustomPermission &&
							((linkedEntityId.getSObjectType() == Account.SObjectType ) ||
									(linkedEntityId.getSObjectType() == Apttus__APTS_Agreement__c.SObjectType ))) {
						cd.addError(MSG_DELETE_CONTRACT_VALIDATION);
					}
				}
			}
		}
	}
}