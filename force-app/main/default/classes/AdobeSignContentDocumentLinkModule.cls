/**************************************************
Description:  Handle adobe sign content document links.
History:
--------------------------------------------------
2024-02-12 - H Liyanage - Created
**************************************************/

public inherited sharing class  AdobeSignContentDocumentLinkModule extends ApplicationModule {
	/**
	 * @deprecated
	 */
	public static AdobeSignContentDocumentLinkModule newInstance() {
		return (AdobeSignContentDocumentLinkModule) Application.Utilities.newInstance(AdobeSignContentDocumentLinkModule.class);
	}

	// Setup which triggers this module should respond to
	public AdobeSignContentDocumentLinkModule() {
		getTriggerEvents().enableAfterInsert();
	}


	/**
	* Called after a case is inserted.
	* Performs below operations
	* 1. Relink files created under Adobe Sign Envelope/contract
	*/
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			if (!System.isBatch() && !System.isScheduled()) {
				linkSignedDocumentsToMasterRecord(records, uow);
			}
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'ADOBE SIGN', AdobeSignContentDocumentLinkModule.class.getName(), 'onAfterInsert', 'CONTENT DOCUMENT LINK TRIGGER', LoggingLevel.ERROR);
		}
	}

	/**
	 * @description : Once the agreement is finalised, (approved or Signed) the final document should be linked back to the master record
	 * ie: Apptus contract or Organisation record
	 * @Document: If you need to know when the agreement is fully signed, implement an Apex trigger on the echosign_dev1__SIGN_Agreement__c object,
	 * after or before update (depending on the use case and requirements).
	 * When the echosign_dev1__Status__c field changes to Signed or Approved or other final statuses, the agreement is completed.
	 * @DocumentSource: https://helpx.adobe.com/au/sign/integrations/salesforce-developer-guide.html
	 *
	 * @param records records passed from trigger
	 * @param uow unit of work
	 */
	public void linkSignedDocumentsToMasterRecord(List<SObject> records, ApplicationUnitOfWork uow) {
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
			uow.registerNew(linksToInsert);
		}
	}
}