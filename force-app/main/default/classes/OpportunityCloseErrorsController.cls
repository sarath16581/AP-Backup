/* @author Victor Chang
 * @date 2020-04-10
 * @domain Core
 * @description Attempts a DML update on the record passed in and returns system validation errors encountered
 *				during update operation. All DML operations are rolled back at the end to ensure no changes are made
 *				to the record. Error messages returned are surfaced on the user interface to inform users of potential
 *				data quality issues.
 *				Visualforce context is required so that all errors added in apex code (via SObject.addError) can be retrieved
 *				via the Database.SaveResult. For any other request contexts only a subset of errors added via SObject.addError is
 *				returned in Database.SaveResult (Please refer for more information:
 *				https://salesforce.stackexchange.com/questions/237042/adderror-on-an-object-in-a-trigger-is-only-displaying-one-of-the-errors-in-objec)
 *
 * @changelog
 * 2020-08-14 - Victor Chang - Created
 * 2020-08-16 - arjun.singh@auspost.com.au - Modified to use mocking framework for dml operations
 * 2023-08-17 - Ranjeewa Silva - Refactored the component as part of exposing opportunity validation errors on user interface
 *								 for all opportunity stages.
 */
global without sharing class OpportunityCloseErrorsController {
	/*
		Class is implemented using without sharing , since Component needs to perform dummy opportunity update
		to get all the possible validation errors and it needs to be done for all the user who are able to go to
		opportunity detail page regardless they have read access or write access.
	*/

	// record id from standard controller
	public Id recordId {get; set;}
	// base url for lightning experience. used to check origin of messages received in visualforce page.
	public String lightningExperienceBaseURL {get;set;}

	public OpportunityCloseErrorsController(ApexPages.StandardController stdController) {
		recordId = (Id)stdController.getId();
		lightningExperienceBaseURL = 'https://' + DomainCreator.getLightningHostname();
	}

	/**
	 * Remote action invoked by visualforce page to retrieve validation errors.
	 *
	 * @param record record to perform DML update
	 * @param targetStage
	 *
	 * @return validation results
	 */
	@RemoteAction
	global static ValidationResults getValidationResults(SObject record) {
		ValidationResults results = new ValidationResults();
		results.recordId = record.Id;

		// set savepoint for rollback
		Savepoint sp = ApplicationDatabase.getInstance().dmlSetSavePoint();

		try {

			// attempt dml update and get any errors encountered
			Set<String> validationResults = updateRecord(record);
			// rollback to ensure no changes are made
			ApplicationDatabase.getInstance().dmlRollback(sp);

			if (!validationResults.isEmpty()) {
				// we have encountered some errors. now attempt the update again with triggers disabled.
				// this is to get all the possible validation messages including standard validation rules.
				SystemSettings__c.getInstance().Disable_Triggers__c = true;
				SystemSwitch__c.getInstance().DisableTriggers__c = true;
				SystemSwitch__c.getInstance().ObjectTriggersToBeDisabled__c = String.valueOf(record.getSObjectType());
				validationResults.addAll(updateRecord(record));

				results.validationMessages.addAll(validationResults);
			}
		} catch(Exception e) {
			// unexpected exception. return the error message.
			results.errorMessage = e.getMessage();
		}

		// ensure everything is rolled back
		ApplicationDatabase.getInstance().dmlRollback(sp);

		return results;
	}

	private static Set<String> updateRecord(SObject updatable) {
		Set<String> results = new Set<String>();

		// mimic the save
		List<Database.SaveResult> saveResults = ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{updatable}, false);

		List<ApexPages.Message> pageMessages = ApexPageMessagesSelector.newInstance().getPageMessages();
		if (pageMessages != null) {
			for (ApexPages.Message pageMessage: pageMessages){
				results.add(pageMessage.getDetail().unescapeHtml4());
			}
		}

		for(Database.SaveResult saveResult: saveResults) {
			if (!saveResult.isSuccess()) {
				// loop through to collate error messages
				for (Database.Error err: saveResult.getErrors()) {
					results.add(((err.getMessage()).unescapeHtml4()));
				}
			}
		}

		return results;
	}

	/**
	 * Return runtime configuration for lightning component used on user interface.
	 * @return runtime configuration
	 */
	@AuraEnabled(Cacheable=true)
	public static Map<String, Object> loadConfig() {
		return new Map<String, Object> {
				'lightningHostname' => DomainCreator.getLightningHostname(),
				'visualforceHostname' => DomainCreator.getVisualforceHostname(null)
		};
	}

	/**
	 * Validation results returned to visualforce layer.
	 */
	global class ValidationResults {
		// id of the record to which the validation results are applicable to
		global Id recordId {get;set;}
		// validation messages collected for the record
		global List<String> validationMessages {get; set;}
		// error message in case of an unexpected technical failure
		global String errorMessage {get; set;}
		global ValidationResults() {
			this.validationMessages = new List<String>();
		}
	}
}