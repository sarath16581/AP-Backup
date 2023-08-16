/**
 * @author Thang Nguyen
 * @date 2023-08-11
 * @group Controller
 * @domain BSP
 * @description Controller apex for the BSP Credit Claim component
 * @changelog
 * 2023-08-11 - Thang Nguyen - Created
 * 2023-08-16 - Hasantha Liyanage - Added validate case functionality.
 */
public with sharing class BSPCreditClaimController {

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

			validateCase(newCase);
			
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

	/**
	 * @param caseRecord
	 * Validate the case record details before save
	 */
	public static void validateCase(Case caseRecord){
		Map<Id,Billing_Account__c> billingAccountsByIds =  BillingAccountsSelector.newInstance().selectByOrgId(new Set<Id>{caseRecord.AccountId});
		if(billingAccountsByIds == null || billingAccountsByIds.isEmpty() || getBillingAccountFromMap(caseRecord.Billing_Number__c , billingAccountsByIds) == null) {
			throw new bspCreditClaimControllerException(BSPErrorMessages__c.getValues('Invalid Billing Account Credit Claim').Message__c);
		}
	}

	/**
	 * get a map of billing accounts by legacy Id
	 *
	 * @param billingAccountsByIds
	 *
	 * @return map of billing accounts by Legacy Id
	 */
	public static Map<String, Billing_Account__c> getBillingAccountByLegacyId(Map<Id,Billing_Account__c> billingAccountsByIds) {
		Map<String, Billing_Account__c> billingAccountByLegacyId = new Map<String, Billing_Account__c>();
		for (Billing_Account__c account : billingAccountsByIds.values()) {
			billingAccountByLegacyId.put(account.Legacy_ID__c, account);
		}

		return billingAccountByLegacyId;
	}

	/**
	 * Check on Billing account number existence without the prefix
	 * @param billingAcctNo
	 * @param billingAccountsByIds
	 *
	 * @return Id of the billing account if exists
	 */
	public static Id getBillingAccountFromMap(String billingAcctNo, Map<Id,Billing_Account__c> billingAccountsByIds) {
		Map<String, Billing_Account__c> billingAccountByLegacyId = getBillingAccountByLegacyId(billingAccountsByIds);
		Id billAcct = null;
		if (billingAccountByLegacyId.get('P' + billingAcctNo) != null) {
			billAcct = billingAccountByLegacyId.get('P' + billingAcctNo).Id;
		} else if (billingAccountByLegacyId.get('T' + billingAcctNo) != null) {
			billAcct = billingAccountByLegacyId.get('T' + billingAcctNo).Id;
		} else if (billingAccountByLegacyId.get(billingAcctNo) != null) {
			billAcct = billingAccountByLegacyId.get(billingAcctNo).Id;
		}
		return billAcct;
	}

	public class bspCreditClaimControllerException extends Exception {}

}