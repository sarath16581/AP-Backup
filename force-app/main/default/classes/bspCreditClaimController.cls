public with sharing class bspCreditClaimController{

	public static String STATUS_OK = 'ok';
	public static String STATUS_ERROR = 'error';

	@AuraEnabled
	public static CreditClaimResponseWrapper createCreditClaim(Case caseRecord, List<Map<String, String>> uploadedFiles, List<Disputed_Item__c> disputeItems) {				

		// return object
		CreditClaimResponseWrapper enquiryWrapper = new CreditClaimResponseWrapper();			

		try {
			ElevatedSharingContext context = new ElevatedSharingContext();

			/////////////////////////////////////////////////
			//TODO: validate Business Account Number and assign the billing account number to the case.
			/////////////////////////////////////////////////



			//set case contact id
			caseRecord.ContactId = bspBaseUplift.loginContactId;
			//set case account id
			caseRecord.AccountId = bspBaseUplift.loginAccountId;

			//Fetching the assignment rules on case
			List<AssignmentRule> assignmentRules = context.getCaseAssignmentRules();
			AssignmentRule assignRule; 
			if (assignmentRules.size() >= 1) {
				assignRule = assignmentRules[0];
			}	

			//Creating the DMLOptions for "Assign using active assignment rules" checkbox
			Database.DMLOptions dmlOptions = new Database.DMLOptions();
			dmlOptions.assignmentRuleHeader.assignmentRuleId = assignRule.Id;
			caseRecord.setOptions(dmlOptions);
			context.insertRecords(new List<Case> {caseRecord});

			//get the new case number
			Case newCase = CasesSelector.newInstance().selectById(new Set<Id> {caseRecord.Id}).get(caseRecord.Id);

			if(newCase != null){
				//Creating the dispute items
				if(disputeItems !=null && !disputeItems.isEmpty()){
					for(Disputed_Item__c diRecord :disputeItems){
						diRecord.Case__c = newCase.Id;
					}
					context.insertRecords(disputeItems);                       
				}				
				// link any files
				if(uploadedFiles !=null && !uploadedFiles.isEmpty()){
					bspBaseUplift.insertFiles(newCase.Id, uploadedFiles);
				}					
				enquiryWrapper.caseRecord = newCase;
				enquiryWrapper.status = STATUS_OK;
				enquiryWrapper.message = '';
			}
			
		} catch (Exception ex) {
			enquiryWrapper.status = STATUS_ERROR;
			enquiryWrapper.message = ex.getMessage();
		} 

		return enquiryWrapper;
	}

	public class CreditClaimResponseWrapper{
		@AuraEnabled public Case caseRecord {get;set;}
		@AuraEnabled public String status {get;set;}
		@AuraEnabled public String message {get;set;}
	}


	/**
	* Private inner class that elevates access/edit privileges of the current user to edit data without being limited by
	* sharing settings.
	*/
	private without sharing class ElevatedSharingContext {
		/**
		 * Insert a list of sObject records in system mode
		 * @param List<sObject>
		*/
		private void insertRecords(List<sObject> recordList) {
			ApplicationDatabase.getInstance().dmlInsert(recordList);
		}

		/**
		 * Returns cases by ids
		 * @param Set<Id>
		 */
		private List<AssignmentRule> getCaseAssignmentRules() {
			return AssignmentRulesSelector.newInstance(1).selectActiveRulesBySObjectType('Case').values();
		}
	}

}