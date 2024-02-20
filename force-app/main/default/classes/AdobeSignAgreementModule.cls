/**
 * Created by hasan on 19/02/2024.
 */

public inherited sharing class AdobeSignAgreementModule extends ApplicationModule {
	/**
		 * @deprecated
		 */
	public static AdobeSignAgreementModule newInstance() {
		return (AdobeSignAgreementModule) Application.Utilities.newInstance(AdobeSignAgreementModule.class);
	}

	// Setup which triggers this module should respond to
	public AdobeSignAgreementModule() {
		getTriggerEvents().enableAfterUpdate();
	}


	/**
	* Called before a Delete
	* Performs below operations
	* 1. Delete content documents except which are not signed documents, this is to minimise the duplication of docs and save space.
	*/
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			AdobeSignAgreementFilesUtil.deleteContentDocuments(records, existingRecords);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'ADOBE SIGN', AdobeSignContentDocumentModule.class.getName(), 'onAfterInsert', 'CONTENT DOCUMENT TRIGGER', LoggingLevel.ERROR);
		}
	}
}