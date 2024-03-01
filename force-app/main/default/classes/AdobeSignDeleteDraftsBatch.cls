/**
* @author Boris Bachovski
* @date 2024-02-15
* @description Delete Adobe Agreements (envelopes) records that are in Draft status and are older than X days (configurable)

* @changelog
* 2024-02-15 - Boris B - Created
*/
public inherited sharing class AdobeSignDeleteDraftsBatch implements Database.Batchable <SObject>, Schedulable {
	public static final Integer DEFAULT_N_DAYS = 30; // Default value if the Custom Setting value is null
	public static final Integer DEFAULT_BATCH_SIZE = 50; // Default batch size if the Custom Setting value is null
	
	public final Integer nDaysAgo; 
	public final Integer batchSize;

	public AdobeSignAPSettings__c settings = AdobeSignAPSettings__c.getInstance();

	/* 
	* Constructor
	*/
	public AdobeSignDeleteDraftsBatch() {
		this.nDaysAgo = settings.DeleteDraftsOlderThan__c == null ? DEFAULT_N_DAYS : Integer.valueOf(settings.DeleteDraftsOlderThan__c);
		this.batchSize = settings.BatchSize__c == null ? DEFAULT_BATCH_SIZE : Integer.valueOf(settings.BatchSize__c);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		AdobeSignAgreementSelector selector = AdobeSignAgreementSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				echosign_dev1__SIGN_Agreement__c.SObjectType => new Set<SObjectField>{echosign_dev1__SIGN_Agreement__c.Id}
		});

		// Select Adobe Agreements that are in Draft status and are older than X days
		return selector.selectDraftAgreementsOlderThan(nDaysAgo, new Set<Object>{ AdobeSignAgreementSelector.Options.FILTER_DRAFT_STATUS });
	 }

	public void execute(SchedulableContext sc) {
		Database.executeBatch(this, batchSize);
	}

	public void execute(Database.BatchableContext BC, List <SObject> scope) { 
		try {
			// Create a new Unit of Work and set the order for deletion
			// First delete any files associated with the agreement records
			// Then delete the agreement records themselves
			ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(new List<SObjectType> {
				ContentDocument.SObjectType,
				echosign_dev1__SIGN_Agreement__c.SObjectType
			});

			Set <Id> agreementIds = new Set <Id>();
			for (echosign_dev1__SIGN_Agreement__c agreement : (List<echosign_dev1__SIGN_Agreement__c>)scope) {
				agreementIds.add(agreement.Id);
			}

			// Query ContentDocument records related to the Adobe Agreements
			Map <Id, ContentDocumentLink> caseContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(new Map<String, Object>{'entityIds' => agreementIds}, new Set<Object>{ ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT }, true);
			
			List <ContentDocument> contentDocuments = new List <ContentDocument>();

			for (ContentDocumentLink cdl : caseContentDocumentLinks.values()) {
				// Ensure this document is not linked to another library
				if (cdl.ContentDocument.ParentId == null || agreementIds.contains(cdl.ContentDocument.ParentId)) {
					// Add the ContentDocument to the list of documents to be deleted
					contentDocuments.add(cdl.ContentDocument);
				}
			}
			
			// Delete the Adobe Agreements and related ContentDocument records
			uow.registerDeleted(contentDocuments, true, 'AdobeSignDeleteDraftsBatch.contentDocuments');
			uow.registerDeleted(scope, true, 'AdobeSignDeleteDraftsBatch.agreements');
			uow.commitWork();
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'AdobeSignDeleteDraftsBatch', AdobeSignDeleteDraftsBatch.class.getName(), 'execute', 'AdobeSignDeleteDraftsBatch', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public void finish(Database.BatchableContext BC) { }
}