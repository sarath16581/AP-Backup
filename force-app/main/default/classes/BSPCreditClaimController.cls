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
			//set case contact id
			caseRecord.ContactId = bspBaseUplift.loginContactId;
			//set case account id
			caseRecord.AccountId = bspBaseUplift.loginAccountId;
			Billing_Account__c billingAccount = getBillingAccountRecord(caseRecord);
			//if no billing account found user is not allowed to proceed,
			//this validation to be removed when the auto select dropdown is implemented which allows the user to select a billing accounts which the user has access to
			if(billingAccount == null) {
				Set<SObjectField> fields = new Set<SObjectField>{BSPErrorMessages__c.Message__c};
				CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(BSPErrorMessages__c.SObjectType, fields);
				Set<String> settingNames = new Set<String> {'Invalid Billing Account Credit Claim'};
				Map<String, SObject> bspMessagesSettings = (Map<String, SObject>) settingsSelector.selectByNames(settingNames);
				BSPErrorMessages__c networkFilterSetting = (BSPErrorMessages__c) bspMessagesSettings.get('Invalid Billing Account Credit Claim');
				throw new bspCreditClaimControllerException(networkFilterSetting.Message__c);
			}
			//assign the billing account record to case
			caseRecord.Related_Billing_Account__c = billingAccount.Id;

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
			Database.SaveResult[] srFiles = context.insertRecords(new List<Case> {caseRecord});
			if(srFiles[0].isSuccess()){
				//get the new case number
				Map<Id,Case> cse = context.getCasesById(new Set<Id> {caseRecord.Id});
				Case newCase = cse.get(caseRecord.Id);
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
			} else {
				for(Database.Error err : srFiles[0].getErrors()) {
					enquiryWrapper.status = STATUS_ERROR;
					enquiryWrapper.message = err.getStatusCode() + ': ' + err.getMessage();
				}
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
		private List<Database.SaveResult> insertRecords(List<sObject> recordList) {
			return ApplicationDatabase.getInstance().dmlInsert(recordList);
		}

		/**
		 * Returns cases by ids
		 * @param Set<Id>
		 */
		private List<AssignmentRule> getCaseAssignmentRules() {
			return AssignmentRulesSelector.newInstance(1).selectActiveRulesBySObjectType('Case').values();
		}

		/**
		 * get cases
		 * @param ids
		 *
		 * @return cases by ids
		 */
		private Map<Id, Case> getCasesById(Set<Id> ids) {
			return CasesSelector.newInstance().selectById(ids);
		}
	}

	/**
	 * @param caseRecord
	 * get the case record details before save
	 */
	public static Billing_Account__c getBillingAccountRecord(Case caseRecord){
		Map<Id,Billing_Account__c> billingAccountsByIds =  BillingAccountsSelector.newInstance().selectByOrgId(new Set<Id>{caseRecord.AccountId});
		if(billingAccountsByIds != null && !billingAccountsByIds.isEmpty()) {
			return getBillingAccountFromMap(caseRecord.Billing_Number__c , billingAccountsByIds);
		}
		return null;
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
	public static Billing_Account__c getBillingAccountFromMap(String billingAcctNo, Map<Id,Billing_Account__c> billingAccountsByIds) {
		Map<String, Billing_Account__c> billingAccountByLegacyId = getBillingAccountByLegacyId(billingAccountsByIds);
		Billing_Account__c billAcct = null;
		if (billingAccountByLegacyId.get('P' + billingAcctNo) != null) {
			billAcct = billingAccountByLegacyId.get('P' + billingAcctNo);
		} else if (billingAccountByLegacyId.get('T' + billingAcctNo) != null) {
			billAcct = billingAccountByLegacyId.get('T' + billingAcctNo);
		} else if (billingAccountByLegacyId.get(billingAcctNo) != null) {
			billAcct = billingAccountByLegacyId.get(billingAcctNo);
		}
		return billAcct;
	}

	public class bspCreditClaimControllerException extends Exception {}

}