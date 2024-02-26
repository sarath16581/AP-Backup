/**
 * @author Hasantha Liyanage
 * @date 2024-02-19
 * @group Module
 * @tag Module
 * @tag AdobeSign
 * @domain Core
 * @description Adobe Sign Agreement Module class
 * @changelog
 */

public inherited sharing class AdobeSignAgreementModule extends ApplicationModule {
	private static String LOG_APP_NAME = 'ADOBE SIGN';
	private static String LOG_TRIGGER_NAME = 'CONTENT DOCUMENT TRIGGER';
	public static AdobeSignAgreementModule newInstance() {
		return (AdobeSignAgreementModule) Application.Utilities.newInstance(AdobeSignAgreementModule.class);
	}

	// Setup which triggers this module should respond to
	public AdobeSignAgreementModule() {
		getTriggerEvents().enableAfterUpdate().enableBeforeDelete();
	}


	/**
	* Called before a Delete
	* Performs below operations
	* 1. Delete content documents except which are not signed documents, this is to minimise the duplication of docs and save space.
	*/
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			deleteContentDocuments(records, existingRecords, uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), LOG_APP_NAME, AdobeSignContentDocumentModule.class.getName(), 'onAfterInsert', LOG_TRIGGER_NAME, LoggingLevel.ERROR);
		}
	}

	/**
	* Called before a Delete
	* Performs below operations
	* 1. Delete content documents except which are not signed documents, this is to minimise the duplication of docs and save space.
	*/
	public override void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			preventDeletionOfSignedAgreements(records, uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), LOG_APP_NAME, AdobeSignContentDocumentModule.class.getName(), 'onBeforeDelete', LOG_TRIGGER_NAME, LoggingLevel.ERROR);
		}
	}

	/**
	 * before delete trigger logic to check on permission to delete signed adobe sign agreement and throw error
	 * @param records record to be deleted
	 * @param uow unit of work context
	 */
	public void preventDeletionOfSignedAgreements(List<SObject> records, ApplicationUnitOfWork uow) {
		// Prevent deletion of adobe agreements
		Boolean hasCustomPermission = FeatureManagement.checkPermission('AllowDeleteOnAdobeSignAgreements');

		// if the agreement is signed and has the permission to perform deletion
		for (echosign_dev1__SIGN_Agreement__c agreement : (List<echosign_dev1__SIGN_Agreement__c>)records) {
			if (!hasCustomPermission && agreement.echosign_dev1__Status__c == 'Signed') {
				agreement.addError('You are not allowed to delete signed agreements');
			}
		}
	}

	/**
	 * after update trigger logic to delete ContentDocuments which are not having '- Signed' in the Title
	 * @param records new records
	 * @param uow unit of work context
	 */
	public void deleteContentDocuments(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {

		Set<Id> agreementIds = new Set<Id>();
		Map<Id, List<ContentDocument>> agreementIdToContentDocumentsMap = new Map<Id, List<ContentDocument>>();

		// Collecting Agreement Ids if the status has been changed to Signed
		for (echosign_dev1__SIGN_Agreement__c agreement : (List<echosign_dev1__SIGN_Agreement__c>)records) {
			echosign_dev1__SIGN_Agreement__c existingRecord = (echosign_dev1__SIGN_Agreement__c)existingRecords.get(agreement.Id);
			if (existingRecord != null && agreement.echosign_dev1__Status__c == 'Signed' && existingRecord.echosign_dev1__Status__c != 'Signed') {
				agreementIds.add(agreement.Id);
			}
		}

		// if no eligible agreement with status signed found ignore deletion.
		if (agreementIds.isEmpty()) {
			return;
		}

		Map<Id, ContentDocumentLink> agreementContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(
				new Map<String, Object>{ 'entityIds' => agreementIds},
				new Set<Object>{
						ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
				},true);

		// Querying Related Content Documents
		for (ContentDocumentLink link : agreementContentDocumentLinks.values()) {
			if (!agreementIdToContentDocumentsMap.containsKey(link.LinkedEntityId)) {
				agreementIdToContentDocumentsMap.put(link.LinkedEntityId, new List<ContentDocument>());
			}
			agreementIdToContentDocumentsMap.get(link.LinkedEntityId).add(link.ContentDocument);
		}

		List<ContentDocument> contentDocumentsToDelete = new List<ContentDocument>();
		// Finding Content Documents without Title containing '- Signed'
		for (Id agreementId : agreementIdToContentDocumentsMap.keySet()) {
			for (ContentDocument document : agreementIdToContentDocumentsMap.get(agreementId)) {
				if (document != null && !document.Title.containsIgnoreCase('- Signed')) {
					contentDocumentsToDelete.add(document);
				}
			}
		}

		// Deleting Content Documents
		if (!contentDocumentsToDelete.isEmpty()) {
			uow.registerDeleted(contentDocumentsToDelete);
		}
	}
}