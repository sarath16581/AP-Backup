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
		List <echosign_dev1__SIGN_Agreement__c> envelopes = AdobeSignAgreementSelector.newInstance().selectById(agreementIds);

		// Populate the map with echosign_dev1__SIGN_Agreement__c records
		Map<Id, echosign_dev1__SIGN_Agreement__c> agreementsMap = new Map<Id, echosign_dev1__SIGN_Agreement__c>();
		for (echosign_dev1__SIGN_Agreement__c envelope : envelopes) {
			agreementsMap.put(envelope.Id, envelope);
		}

		List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

		for (ContentDocumentLink link : (List<ContentDocumentLink>)records) {
			ContentDocument contentDocument = contentDocuments.get(link.ContentDocumentId);
			if(!contentDocument.Title.containsIgnoreCase('- signed')) {
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
	 * Prevent deletion of documents links to other objects which are originally created for echosign_dev1__SIGN_Agreement__c object.
	 * echosign_dev1__SIGN_Agreement__c object hold the evidence of the sign document and this should not be deleted
	 * @param records ContentDocuments
	 */
	public static void preventDeletionOfSignedDocuments(List<SObject> records) {

		Boolean hasCustomPermission = FeatureManagement.checkPermission('AllowDeleteOnAdobeSignContracts');
		// Collect the Ids of ContentDocuments being deleted
		Set<Id> contentDocumentIds = new Set<Id>();
		for (ContentDocument cd : (List<ContentDocument>)records) {
			contentDocumentIds.add(cd.Id);
		}

		// prepare a map of content document link Ids to look for entity IDs
		Map<Id, List<Id>> contentDocumentLinksMap = new Map<Id, List<Id>>();


		Map<Id, ContentDocumentLink> caseContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(
				new Map<String, Object>{ 'entityIds' => contentDocumentIds},true);
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
					if (!hasCustomPermission && linkedEntityId.getSObjectType() == echosign_dev1__SIGN_Agreement__c.SObjectType) {
						cd.addError('Cannot delete ContentDocument with a link to echosign_dev1__SIGN_Agreement__c');
					}
				}
			}
		}
	}
}