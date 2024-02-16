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
		getTriggerEvents().enableBeforeDelete();
	}


	/**
	* Called after a case is inserted.
	* Performs below operations
	* 1. Relink files created under Adobe Sign Envelope/contract
	*/
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			System.debug('AdobeSignContentDocumentLinkModule:onAfterInsert');
			if (!System.isBatch() && !System.isScheduled()) {
				AdobeSignAgreementFilesUtil.processNewLinks(records);
			}
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'ADOBE SIGN', AdobeSignContentDocumentLinkModule.class.getName(), 'onAfterInsert', 'CONTENT DOCUMENT LINK TRIGGER', LoggingLevel.ERROR);
		}
	}
}