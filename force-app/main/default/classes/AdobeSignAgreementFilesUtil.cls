/**************************************************
Description:  this class contains common methods for adobe sign related business logic
History:
--------------------------------------------------
2024-02-12 - H Liyanage - Created
**************************************************/
public inherited sharing class AdobeSignAgreementFilesUtil {

	public static AdobeSignAgreementFilesUtil getInstance() {
		return (AdobeSignAgreementFilesUtil) Application.Utilities.getInstance(AdobeSignAgreementFilesUtil.class);
	}

	/**
	 * @description : Once the agreement is finalised, (approved or Signed) the final document should be linked back to the master record
	 * ie: Apptus contract or Organisation record
	 * @Document: If you need to know when the agreement is fully signed, implement an Apex trigger on the echosign_dev1__SIGN_Agreement__c object,
	 * after or before update (depending on the use case and requirements).
	 * When the echosign_dev1__Status__c field changes to Signed or Approved or other final statuses, the agreement is completed.
	 * @DocumentSource: https://helpx.adobe.com/au/sign/integrations/salesforce-developer-guide.html
	 *
	 * @param records
	 */
	public static void processNewLinks(List<SObject> records) {

		//TODO: handover to queueable?
		//TODO: error handling to be added
		// Collect IDs of echosign_dev1__SIGN_Agreement__c records linked to ContentDocumentLinks
		Set<Id> agreementIds = new Set<Id>();
		Set<Id> contentDocumentIds = new Set<Id>();
		for (ContentDocumentLink link : (List<ContentDocumentLink>)records) {
			if (link.LinkedEntityId.getSObjectType() == echosign_dev1__SIGN_Agreement__c.SObjectType) {
				agreementIds.add(link.LinkedEntityId);
				contentDocumentIds.add(link.ContentDocumentId);
			}
		}

		Map<Id,ContentDocument> contentDocuments = ContentDocumentsSelector.newInstance().selectById(contentDocumentIds);

		// Query echosign_dev1__SIGN_Agreement__c records related to the collected IDs
		// signed documents are only available in signed envelopes
		List <echosign_dev1__SIGN_Agreement__c> envelopes = AdobeSignAgreementSelector.newInstance().selectById(agreementIds, new Set<Object>());

		// Populate the map with echosign_dev1__SIGN_Agreement__c records
		Map<Id, echosign_dev1__SIGN_Agreement__c> agreementsMap = new Map<Id, echosign_dev1__SIGN_Agreement__c>();
		for (echosign_dev1__SIGN_Agreement__c envelope : envelopes) {
			agreementsMap.put(envelope.Id, envelope);
		}

		// new links to be made with master records
		List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

		for (ContentDocumentLink link : (List<ContentDocumentLink>)records) {
			ContentDocument contentDocument = contentDocuments.get(link.ContentDocumentId);
			// if the document is not the signed one then do not need to re-link .
			if(contentDocument == null || !contentDocument.Title.containsIgnoreCase('- signed')) {
				continue;
			}
			if (link.LinkedEntityId.getSObjectType() == echosign_dev1__SIGN_Agreement__c.SObjectType) {
				echosign_dev1__SIGN_Agreement__c agreement = agreementsMap.get(link.LinkedEntityId);

				if (agreement != null) {
					if (agreement.ApttusContract__c != null) {
						// Create a new ContentDocumentLink record with LinkedEntityId set to ApttusContract__c Id
						ContentDocumentLink newLink = new ContentDocumentLink();
						newLink.ContentDocumentId = link.ContentDocumentId;
						newLink.LinkedEntityId = agreement.ApttusContract__c;
						newLink.ShareType = 'V';
						newLink.Visibility = 'AllUsers';
						linksToInsert.add(newLink);
					} else if (agreement.echosign_dev1__Account__c != null) {
						// Create a new ContentDocumentLink record with LinkedEntityId set to echosign_dev1__Account__c Id
						ContentDocumentLink newLink = new ContentDocumentLink();
						newLink.ContentDocumentId = link.ContentDocumentId;
						newLink.LinkedEntityId = agreement.echosign_dev1__Account__c;
						newLink.ShareType = 'V';
						newLink.Visibility = 'AllUsers';
						linksToInsert.add(newLink);
					}
				}
			}
		}

		if (!linksToInsert.isEmpty()) {
			insert linksToInsert;
		}

	}

	/**
	 * after update trigger logic to delete ContentDocuments which are not having '- Signed' in the Title
	 * @param records new records
	 * @param existingRecords old records
	 */
	public static void deleteContentDocuments(List<SObject> records, Map<Id, SObject> existingRecords) {
		Set<Id> agreementIds = new Set<Id>();
		Map<Id, List<ContentDocument>> agreementIdToContentDocumentsMap = new Map<Id, List<ContentDocument>>();

		// Collecting Agreement Ids if the status has been changed to Signed
		for (echosign_dev1__SIGN_Agreement__c agreement : (List<echosign_dev1__SIGN_Agreement__c>)records) {
			echosign_dev1__SIGN_Agreement__c existingRecord = (echosign_dev1__SIGN_Agreement__c)existingRecords.get(agreement.Id);
			if (existingRecord != null && agreement.echosign_dev1__Status__c == 'Signed' && existingRecord.echosign_dev1__Status__c != 'Signed') {
				agreementIds.add(agreement.Id);
			}
		}


		if (agreementIds.isEmpty()) {
			return;
		}

		Map<Id, ContentDocumentLink> agreementContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(
				new Map<String, Object>{ 'entityIds' => agreementIds},
				new Set<Object>{
						ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
				},true);
		system.debug('HASANTHA agreementContentDocumentLinks ----- '+agreementContentDocumentLinks);
		// Querying Related Content Documents
		for (ContentDocumentLink link : agreementContentDocumentLinks.values()) {
			if (!agreementIdToContentDocumentsMap.containsKey(link.LinkedEntityId)) {
				agreementIdToContentDocumentsMap.put(link.LinkedEntityId, new List<ContentDocument>());
			}
			agreementIdToContentDocumentsMap.get(link.LinkedEntityId).add(link.ContentDocument);
		}

		List<ContentDocument> contentDocumentsToDelete = new List<ContentDocument>();
		system.debug('HASANTHA agreementIdToContentDocumentsMap ----- '+agreementIdToContentDocumentsMap);
		// Finding Content Documents without Title containing '- Signed'
		for (Id agreementId : agreementIdToContentDocumentsMap.keySet()) {
			for (ContentDocument document : agreementIdToContentDocumentsMap.get(agreementId)) {
				if (document != null && !document.Title.containsIgnoreCase('- Signed')) {
					contentDocumentsToDelete.add(document);
				}
			}
		}
		system.debug('HASANTHA contentDocumentsToDelete ----- '+contentDocumentsToDelete);
		// Deleting Content Documents
		delete contentDocumentsToDelete;
	}

	/**
	 * Prevent deletion of documents links to other objects which are originally created for echosign_dev1__SIGN_Agreement__c object.
	 * echosign_dev1__SIGN_Agreement__c object hold the evidence of the sign document and this should not be deleted
	 * @param records ContentDocuments
	 */
	public static void preventDeletionOfSignedDocuments(List<SObject> records) {

		// Prevent deletion of adobesign signed documnts
		Boolean hasCustomPermission = FeatureManagement.checkPermission('AllowDeleteOnAdobeSignContracts');

		// Collect the Ids of ContentDocuments being deleted
		Set<Id> contentDocumentIds = new Set<Id>();
		for (ContentDocument cd : (List<ContentDocument>)records) {
			contentDocumentIds.add(cd.Id);
		}

		// prepare a map of content document link Ids to look for entity IDs
		Map<Id, List<Id>> contentDocumentLinksMap = new Map<Id, List<Id>>();


		Map<Id, ContentDocumentLink> caseContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(
				new Map<String, Object>{ 'documentIds' => contentDocumentIds},true);
		for (ContentDocumentLink cdl : caseContentDocumentLinks.values()) {
			if (!contentDocumentLinksMap.containsKey(cdl.ContentDocumentId)) {
				contentDocumentLinksMap.put(cdl.ContentDocumentId, new List<Id>());
			}
			contentDocumentLinksMap.get(cdl.ContentDocumentId).add(cdl.LinkedEntityId);
		}

		// perform the check and add the error
		for (ContentDocument cd : (List<ContentDocument>)records) {
			if (contentDocumentLinksMap.containsKey(cd.Id)) {
				for (Id linkedEntityId : contentDocumentLinksMap.get(cd.Id)) {
					if (!hasCustomPermission && linkedEntityId.getSObjectType() == echosign_dev1__SIGN_Agreement__c.SObjectType && cd.Title.containsIgnoreCase('- Signed')) {
						cd.addError('Cannot delete ContentDocument with a link to a signed Agreement');
					}
				}
			}
		}
	}
}