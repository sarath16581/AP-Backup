/**
 * @author Thang Nguyen
 * @date 2023-08-11
 * @group Controller
 * @domain BSP
 * @description Controller apex for the BSP Credit Claim component
 * @changelog
 * 2023-08-11 - Thang Nguyen - Created
 * 2023-08-16 - Hasantha Liyanage - Added validate case functionality.
 * 2023-08-23 - Hasantha Liyanage - Added accepted file formats to be passed to file upload custom component
 * 2023-09-27 - Hasantha Liyanage - Account Number and Other Account number functionality with type ahead component
 */
public with sharing class BSPCreditClaimController {
	public static String STATUS_OK = 'ok';
	public static String STATUS_ERROR = 'error';

	@AuraEnabled
	public static CreditClaimResponseWrapper createCreditClaim(Case caseRecord, List<Map<String, String>> uploadedFiles, List<Disputed_Item__c> disputeItems, Map<Object,String> formData) {
		// return object
		CreditClaimResponseWrapper enquiryWrapper = new CreditClaimResponseWrapper();			

		try {
			ElevatedSharingContext context = new ElevatedSharingContext();
			//set case contact id
			caseRecord.ContactId = bspBaseUplift.loginContactId;
			//set case account id
			caseRecord.AccountId = bspBaseUplift.loginAccountId;
			// if the billing account number manually entered validate the number
			if(String.isNotBlank(caseRecord.Billing_Number__c) && String.isBlank(caseRecord.Related_Billing_Account__c)) {
				isValidBillingAccount(caseRecord.Billing_Number__c);
			}

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
			Database.SaveResult[] saveResults = context.insertRecords(new List<Case> {caseRecord});

			if(saveResults[0].isSuccess()){
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
						bspBaseUplift.linkFiles(newCase.Id, uploadedFiles);
					}
					enquiryWrapper.caseRecord = newCase;
					enquiryWrapper.status = STATUS_OK;
					enquiryWrapper.message = '';

					//build case comments from form data
					createCaseComments(formData, caseRecord);
				}
			} else {
				for(Database.Error err : saveResults[0].getErrors()) {
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

	/**
	 * Get the super admin roles of the org to display when other account number option is selected
	 * this will allow the user to find the email address to send the access request
	 * @return
	 */
	@AuraEnabled(cacheable=true)
	public static List<RoleWrapper> getSuperAdminRoles(){
		List<BAMContactRole__c> roles = BAMContactRoleSelector.newInstance().selectRolesByRoleAndOrgId(
				new Set<String>{BAMUserUtility.ACCESS_MANAGEMENT_SUPER_ADMIN},
				new Set<Id>{bspBaseUplift.loginAccountId},
				new Set<Object>{BAMContactRoleSelector.Options.WITH_CONTACT_APPLICATION}
		);
		List<RoleWrapper> adminRoles = new List<RoleWrapper>();
		for(BAMContactRole__c role : roles) {
			// do not need to show the login contact's details if the logged in user is a super admin
			if(role?.ContactApplication__r?.Contact__c == bspBaseUplift.loginContactId) {
				continue;
			}
			RoleWrapper adminRole = new RoleWrapper();
			adminRole.contactId = role?.ContactApplication__r?.Contact__c;
			adminRole.name = role?.ContactApplication__r?.Contact__r?.Name;
			adminRole.firstName = role?.ContactApplication__r?.Contact__r?.FirstName;
			adminRole.email = role?.ContactApplication__r?.Contact__r?.Email;
			adminRoles.add(adminRole);
		}


		return adminRoles;
	}

	@AuraEnabled
	public static BillingAccountsWrapper isValidBillingAccount(String billingAccountValue) {
		Case caseRecord = new Case();
		caseRecord.AccountId = bspBaseUplift.loginAccountId;
		caseRecord.Billing_Number__c = String.escapeSingleQuotes(billingAccountValue);
		Billing_Account__c billingAccount = getBillingAccountRecord(caseRecord);
		BillingAccountsWrapper wrapper = new BillingAccountsWrapper();
		//if no billing account found user is not allowed to proceed
		if (billingAccount == null) {
			Set<SObjectField> fields = new Set<SObjectField>{
					BSPErrorMessages__c.Message__c, BSPErrorMessages__c.Name
			};
			CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(BSPErrorMessages__c.SObjectType, fields);
			Set<String> settingNames = new Set<String>{
					'Invalid Billing Account Credit Claim'
			};
			Map<String, SObject> bspMessagesSettings = (Map<String, SObject>) settingsSelector.selectByNames(settingNames);
			BSPErrorMessages__c networkFilterSetting = (BSPErrorMessages__c) bspMessagesSettings.get('Invalid Billing Account Credit Claim');
			String message = networkFilterSetting.Message__c;
			List<String> formattingArguments = new List<String>{ billingAccountValue, '\n'};

			wrapper.message = String.format(message, formattingArguments);
			wrapper.status = 'ERROR';
			return wrapper;
		} else {
			wrapper.billingAccount = billingAccount;
			wrapper.status = 'SUCCESS';
			return wrapper;
		}
	}

	public class CreditClaimResponseWrapper{
		@AuraEnabled public Case caseRecord {get;set;}
		@AuraEnabled public String status {get;set;}
		@AuraEnabled public String message {get;set;}
	}

	public class BillingAccountsWrapper{
		@AuraEnabled public Billing_Account__c billingAccount {get;set;}
		@AuraEnabled public String status {get;set;}
		@AuraEnabled public String message {get;set;}
	}

	public class RoleWrapper{
		@AuraEnabled public String contactId {get;set;}
		@AuraEnabled public String firstName {get;set;}
		@AuraEnabled public String name {get;set;}
		@AuraEnabled public String email {get;set;}
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

	/**
	 * Create case comments once the case is created
	 * @param formData form data to be passed to logically build the comment body
	 * @param caseRecord Case record related data to be accessed while building/creating comments
	 */
	@TestVisible
	private static void createCaseComments(Map<Object, String> formData, Case caseRecord) {
		ElevatedSharingContext context = new ElevatedSharingContext();
		String commentBody = '';
		CaseComment comment = new CaseComment();
		commentBody = buildBillingAccountCaseComments(commentBody, formData);
		comment.CommentBody = commentBody;
		comment.IsPublished = false;
		comment.ParentId = caseRecord.Id;
		//insert case comments
		context.insertRecords(new List<SObject>{
				comment
		});
	}

	/**
	 * Generate the comment body for authorised and un authorised billing account numbers
	 * @param commentBody built comment body
	 * @param formData form data to be passed to logically build the comment body
	 *
	 * @return built comment body
	 */
	@TestVisible
	private static String buildBillingAccountCaseComments(String commentBody, Map<Object,String> formData) {
		commentBody += '\n' + '---Enquiry Details---';
		String authorisedBillingAccount = 'N/A';
		String unAuthorisedBillingAccount = 'N/A';
		if(Boolean.valueOf(formData.get('isOther'))) {
			unAuthorisedBillingAccount = formData.get('businessAccountNumber');
		} else {
			authorisedBillingAccount = formData.get('businessAccountNumber');
		}
		commentBody += '\n' + 'Authorised Billing Account Number: '+authorisedBillingAccount;
		commentBody += '\n' + 'Other (Un-authorised) Billing Account Number: '+unAuthorisedBillingAccount ;
		return commentBody;
	}

	public class bspCreditClaimControllerException extends Exception {}

}