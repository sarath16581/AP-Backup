/**************************************************
Description:   Module Adobe Sign Content Document
History:
--------------------------------------------------
2024-02-12 - H Liyanage - Created
**************************************************/

public inherited sharing class AdobeSignContentDocumentModule extends ApplicationModule {
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
			AdobeSignAgreementFilesUtil.preventDeletionOfSignedDocuments(records);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'ADOBE SIGN', AdobeSignContentDocumentModule.class.getName(), 'onAfterInsert', 'CONTENT DOCUMENT TRIGGER', LoggingLevel.ERROR);
		}
	}
}