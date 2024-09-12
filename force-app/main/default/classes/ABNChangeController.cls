/**
 * @author Harry Wang
 * @date 2024-05-17
 * @group Controller
 * @tag Controller
 * @tag CSP
 * @description Service Controller class for ABN Update
 * @changelog
 * 2024-05-17 - Harry Wang - Created
 */
public with sharing class ABNChangeController {

	/**
	 * Field Overrides when selecting At Risk Business
	 */
	private static final Map<SObjectType,Set<SObjectField>> AT_RISK_BUSINESS_FIELD_OVERRIDES = new Map<SObjectType,Set<SObjectField>> {
			At_Risk_Business__c.SObjectType => new Set<SObjectField> {
					At_Risk_Business__c.Id, At_Risk_Business__c.Related_Organisation__c, At_Risk_Business__c.Legal_Entity_Name__c, At_Risk_Business__c.Related_Opportunity__c, At_Risk_Business__c.Reason__c
			},
			Account.SObjectType => new Set<SObjectField> {
					Account.Name, Account.ABN__c
			}
	};

	/**
	 * Field Overrides when selecting old and new contacts
	 */
	private static final Set<SObjectField> CONTACT_FIELD_OVERRIDES = new Set<SObjectField>{Contact.FirstName, Contact.LastName, Contact.Name, Contact.Title, Contact.Email, Contact.Phone, Contact.Has_Online_Credential__c};

	/**
	* Field Overrides when selecting DSRs
	*/
	private static final Set<SObjectField> DSR_FIELD_OVERRIDES = new Set<SObjectField>{Deal_Support_Request__c.Name, Deal_Support_Request__c.Stage__c, Deal_Support_Request__c.Status__c, Deal_Support_Request__c.Work_Type__c, Deal_Support_Request__c.Credit_Work_Type__c, Deal_Support_Request__c.Request_type__c};

	/**
	 * Field Overrides when selecting Opportunities
	 */
	private static final Set<SObjectField> OPPORTUNITY_FIELD_OVERRIDES = new Set<SObjectField>{Opportunity.Id, Opportunity.Name, Opportunity.AccountId, Opportunity.KeyContact__c, Opportunity.Amount, Opportunity.CloseDate, Opportunity.StageName, Opportunity.IsClosed, Opportunity.IsStartrackProposal__c};

	/**
	 * Field Overrides when selecting Opportunities
	 */
	private static final Set<SObjectField> BILLING_ACCOUNT_FIELD_OVERRIDES = new Set<SObjectField>{Billing_Account__c.Id, Billing_Account__c.Name, Billing_Account__c.Credit_Person__c, Billing_Account__c.Credit_Representative_Email__c, Billing_Account__c.Credit_Person_Code__c, Billing_Account__c.LEGACY_ID__c, Billing_Account__c.PAYER_ACCOUNT_ID__c};

	/**
	 * This method is used to get deduplicated contacts and related At Risk Business between contacts from old organisation (legal entity) and new organisation (related organisation)
	 * Datacloud.FindDuplicates.findDuplicates is used to deduplicate contacts
	 * @param businessAtRiskId  At Risk Business Id
	 *
	 * @return Map of 'businessAtRisk' => At Risk Business, 'contacts' => list of deduplicated contacts
	 */
	@AuraEnabled(Cacheable=true)
	public static Map<String, Object> getDeduplicatedContactsAndBaR(String businessAtRiskId) {
		At_Risk_Business__c atRiskBusiness = AtRiskBusinessSelector.newInstance(AT_RISK_BUSINESS_FIELD_OVERRIDES).selectById(new Set<Id>{businessAtRiskId}, new Set<Object>{AtRiskBusinessSelector.options.WITH_RELATED_ORGANISATION})[0];
		List<Contact> oldContacts = ContactsSelector.newInstance(0, CONTACT_FIELD_OVERRIDES).selectCloneableContactsByAccount(atRiskBusiness.Legal_Entity_Name__c);

		Set<Id> duplicatedIds = new Set<Id>();
		List<Contact> uniqueContacts = new List<Contact>();

		// Assign new org on old contacts
		for (Contact c: oldContacts) {
			c.AccountId = atRiskBusiness.Related_Organisation__c;
		}

		List<Datacloud.FindDuplicatesResult> fdResults = new List<Datacloud.FindDuplicatesResult>();

		// The input array of Datacloud.FindDuplicates.findDuplicates method is limited to 50 elements. Split the list to sub lists accordingly
		List<List<Contact>> contactsList = (List<List<Contact>>)splitContacts(oldContacts, 50);
		for (List<Contact> contacts: contactsList) {
			fdResults = Datacloud.FindDuplicates.findDuplicates(contacts);
			for (Integer i = 0; i < fdResults.size(); i++) {
				for (Datacloud.DuplicateResult duplicateResult :fdResults[i].getDuplicateResults()) {
					for (Datacloud.MatchResult matchResult :duplicateResult.getMatchResults()) {
						// Collect matched Ids
						if (!duplicateResult.allowSave && matchResult.size > 0) {
							duplicatedIds.add(contacts[i].Id);
						}
					}
				}
			}
		}

		for (Integer i = 0; i < oldContacts.size(); i++) {
			if (!duplicatedIds.contains(oldContacts[i].Id)) {
				uniqueContacts.add(oldContacts[i]);
			}
		}

		return new Map<String, Object>{
				'businessAtRisk' => atRiskBusiness,
				'contacts' => uniqueContacts
		};
	}

	/**
	 * @description Get datatable columns from given field set
	 * @param objectName Object API name for the field set
	 * @param fieldSetName Name of the field set to be used to map columns
	 * @return list of datatable column wrapper
	 */
	@AuraEnabled(Cacheable=true)
	public static List<DataTableColumn> retrieveColumns(String objectName, String fieldSetName) {
		try {
			List<DataTableColumn> dataTableColumnList = new List<DataTableColumn>();
			for (Schema.FieldSetMember fs: Schema.getGlobalDescribe().get(objectName).getDescribe().fieldSets.getMap().get(fieldSetName).getFields()) {
				DataTableColumn datatableColumn = new DataTableColumn(fs.getLabel(), fs.getFieldPath(), String.valueOf(fs.getType()));
				dataTableColumnList.add(datatableColumn);
			}
			return dataTableColumnList;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Clone contacts to the new organisation with fields retrieved from ABNChangeContactCloning field set
	 * Support partial success and log dml failures on Exception Log
	 * DML option used to bypass alert type duplicate rule
	 * Unexpected exception will be logged as well
	 * @param newOrganisationId Id of new organisation where the contacts will be cloned to
	 * @param oldContactIds list of old contact Ids
	 */
	@AuraEnabled
	public static void cloneContacts(String newOrganisationId, List<Id> oldContactIds) {
		try {
			// Select old contacts by Ids with fields from ABNChangeContactCloning field set
			Set<SObjectField> contactCloningFields = new Set<SObjectField>();
			Set<String> contactCloningFieldNames = new Set<String>();
			Schema.FieldSet fieldSet = Schema.SObjectType.Contact.fieldSets.getMap().get('ABNChangeContactCloning');
			for (Schema.FieldSetMember fieldSetMember: fieldSet.getFields()) {
				contactCloningFields.add(fieldSetMember.getSObjectField());
				contactCloningFieldNames.add(fieldSetMember.getFieldPath());
			}
			List<Contact> oldContacts = ContactsSelector.newInstance(0, contactCloningFields).selectById(new Set<Id>(oldContactIds)).values();

			// Extract fields from old contacts and map to new contacts to be inserted
			// Bypass duplicate alert
			Database.DMLOptions opt = new Database.DMLOptions();
			opt.duplicateRuleHeader.allowSave = true;
			opt.optAllOrNone = false;

			List<Contact> newContacts = new List<Contact>();
			for (Contact oldContact: oldContacts) {
				Contact c = new Contact();
				c.AccountId = newOrganisationId;
				for (String fieldName: contactCloningFieldNames) {
					c.put(fieldName, oldContact.get(fieldName));
				}
				newContacts.add(c);
			}

			if (newContacts.size() > 0) {
				// Create new contacts asynchronously and log failed old contacts
				System.enqueueJob(new ABNChangeContactCloningQueueable(oldContacts, newContacts));
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'ABNChange', ABNChangeController.class.getName(), 'cloneContacts', null, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * This method is used to get DSRs from related organisation given at risk business record Id
	 * @param businessAtRiskId  At Risk Business Id
	 * @return Map of 'businessAtRisk' => At Risk Business, 'dsrList' => list of DSRs
	 */
	@AuraEnabled(Cacheable=true)
	public static Map<String, Object> getDSRsAndBaR(String businessAtRiskId) {
		At_Risk_Business__c atRiskBusiness = AtRiskBusinessSelector.newInstance(AT_RISK_BUSINESS_FIELD_OVERRIDES).selectById(new Set<Id>{businessAtRiskId}, new Set<Object>{AtRiskBusinessSelector.options.WITH_RELATED_ORGANISATION})[0];
		List<Deal_Support_Request__c> dsrList = DealSupportRequestsSelector.newInstance(0, DSR_FIELD_OVERRIDES).selectByAtRiskBusinessId(new Set<Id>{businessAtRiskId}, new Set<Object>{DealSupportRequestsSelector.Options.WITH_RECORDTYPE, DealSupportRequestsSelector.Options.WITH_OWNER});
		return new Map<String, Object>{
				'businessAtRisk' => atRiskBusiness,
				'dsrList' => dsrList
		};
	}

	/**
	 * This method is used to get opportunities given parent account Id
	 * @param accountId  parent account Id
	 * @return list of opportunities with owner and key contacts
	 */
	@AuraEnabled(Cacheable=true)
	public static List<Opportunity> getOpportunities(String accountId) {
		return OpportunitiesSelector.newInstance(0, OPPORTUNITY_FIELD_OVERRIDES).selectByAccountId(new Set<Id>{accountId}, new Set<Object>{OpportunitiesSelector.Options.WITH_OWNER, OpportunitiesSelector.Options.WITH_KEY_CONTACT});

	}

	/**
	 * This method is used to get DSRs given parent account Id
	 * @param accountId  parent account Id
	 * @return list of DSRs with record type and owner details
	 */
	@AuraEnabled(Cacheable=true)
	public static List<Deal_Support_Request__c> getDSRsByAccountId(String accountId) {
		return 	DealSupportRequestsSelector.newInstance(0, DSR_FIELD_OVERRIDES).selectByAccountId(new Set<Id>{accountId}, new Set<Object>{DealSupportRequestsSelector.Options.WITH_RECORDTYPE, DealSupportRequestsSelector.Options.WITH_OWNER});
	}

	public class DataTableColumn {
		@AuraEnabled
		public String label {get;set;}
		@AuraEnabled
		public String fieldName {get;set;}
		@AuraEnabled
		public String type {get;set;}

		public DataTableColumn(String label, String fieldName, String type)
		{
			this.label = label;
			this.fieldName = fieldName;
			if (fieldName == 'Phone') {
				this.type = 'phone';
			} else {
				this.type = type.toLowerCase();
			}
		}
	}

	public static List<List<Contact>> splitContacts(List<Contact> source, Integer size) {
		List<List<Contact>> ret = new List<List<Contact>>();
		if (source == null || source.size() == 0) {
			return ret;
		}

		// If the source size is equal to or smaller than our partition size, just return it
		if (source.size() <= size) {
			ret.add(source);
			return ret;
		}

		// Initialize the partitions
		Integer partition = 0;
		ret.add(new List<Contact>());

		for (Contact obj : source) {
			// Create a new partition when we fill one up
			if (ret[partition].size() == size) {
				partition++;
				ret.add(new List<Contact>());
			}
			// Add object to current partition
			ret[partition].add(obj);
		}

		return ret;
	}

	/**
	 * This method is used to create DSRs based on the request wrapper passed from frontend.
	 * After creation is successful, generate content document CSV and link to the Close All BA DSR
	 * @param request DSR generation request wrapper passed from frontend.
	 * @return list of failed DSR types
	 */
	@AuraEnabled
	public static List<String> createDSRs(DSRRequestWrapper request) {
		try {
			ABNChangeDSRGenerator.allProductTypes = request.allProductTypes;

			// generate DSR based on DSR types
			Map<String, Object> result = generateDsrAndGetDsrTypes(request);

			List<Deal_Support_Request__c> newDSRs = (List<Deal_Support_Request__c>)result.get('newDSRs');
			List<String> dsrTypes = (List<String>)result.get('dsrTypes');
			ABNChangeDSRGenerator.CloseAllBAs closeAllBAs = (ABNChangeDSRGenerator.CloseAllBAs)result.get('closeAllBAs');
			Boolean csvRequired = (Boolean)result.get('csvRequired');

			List<String> failedDSRTypes = new List<String>();
			List<Database.SaveResult> failedResults = new List<Database.SaveResult>();

			// insert computed DSRs
			List<Database.SaveResult> results = ApplicationDatabase.getInstance().dmlInsert(newDSRs, false);
			for (Integer i = 0; i < results.size(); i++) {
				if (results[i].isSuccess()) {
					if (dsrTypes[i] == 'Close All Billing Accounts DSR') {
						// generate CSV if required and close all BA DSR has been created
						if (csvRequired) {
							Database.SaveResult csvSaveResult = ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{closeAllBAs.generateCloseAllBACsv()})[0];
							if (csvSaveResult.isSuccess()) {
								Id docId = ContentVersionsSelector.newInstance().selectById(new Set<Id>{csvSaveResult.getId()}).values()[0].ContentDocumentId;
								Database.SaveResult docSaveResult = LinkContentDocument.generateContentDocumentLink(new List<Id>{docId}, newDSRs[i].Id)[0];
								if (!docSaveResult.isSuccess()) {
									throw new AuraHandledException('CSV generation failed while generating Close All Billing Account DSR: ' + docSaveResult.getErrors());
								}
							} else {
								throw new AuraHandledException('CSV generation failed while generating Close All Billing Account DSR: ' + csvSaveResult.getErrors());
							}
						}
						// attach customer request documents on the DSR
						LinkContentDocument.generateContentDocumentLink(request.customerRequestDocumentIds, newDSRs[i].Id);
					}
				} else {
					failedDSRTypes.add(dsrTypes[i]);
					failedResults.add(results[i]);
				}
			}
			ApplicationLogger.getInstance().logFailedDatabaseResults(failedResults, 'ABNChange', ABNChangeController.class.getName(), 'createDSRs', null, ApplicationLogger.LoggingLevel.ERROR);
			return failedDSRTypes;
		} catch (Exception e) {
			throw new AuraHandledException('Error occurred while generating DSRs: ' + e.getMessage());
		}
	}

	/**
	 * This method is used to generate DSRs based on the request wrapper.
	 * Within the wrapper it has the information about what types of DSR (captured in dsrTypes attribute) need to be created
	 * and field values required for the creation.
	 * Individual DSR is computed and generated based on sub class generator within ABNChangeDSRGenerator.
	 * @param request DSR generation request wrapper passed from frontend.
	 * @return result that contains generated DSR list, DSR types, and CSV creation flag
	 */
	private static Map<String, Object> generateDsrAndGetDsrTypes(DSRRequestWrapper request){
		Map<String, Object> result = new Map<String, Object>();
		List<Deal_Support_Request__c> newDSRs = new List<Deal_Support_Request__c>();
		List<String> dsrTypes = new List<String>();
		ABNChangeDSRGenerator.CloseAllBAs closeAllBAs;

		for (String type: request.dsrTypes) {
			switch on type {
				when 'proposalGeneration' {
					for (DSRRequestOpportunityWrapper wrapper: request.opportunityWrappers) {
						Deal_Support_Request__c dsr = new ABNChangeDSRGenerator.ProposalContractDSR(true, request.organisationId, wrapper.opportunityId, request.reason, wrapper.productType, wrapper.keyContactId, request.atRiskBusinessId, request.isStandardPricing, request.pricingDSRNames).toDsrRecord();
						newDSRs.add(dsr);
						dsrTypes.add('New Proposal for ' + wrapper.productType + ' Opportunity DSR');
					}

				}
				when 'contractGeneration' {
					for (DSRRequestOpportunityWrapper wrapper: request.opportunityWrappers) {
						Deal_Support_Request__c dsr = new ABNChangeDSRGenerator.ProposalContractDSR(false, request.organisationId, wrapper.opportunityId, request.reason, wrapper.productType, wrapper.keyContactId, request.atRiskBusinessId, request.isStandardPricing, request.pricingDSRNames).toDsrRecord();
						newDSRs.add(dsr);
						dsrTypes.add('New Contract for ' + wrapper.productType + ' Opportunity DSR');
					}

				}
				when 'terminateContracts' {
					Set<String> productTypes = new Set<String>();
					for (DSRRequestOpportunityWrapper wrapper: request.opportunityWrappers) {
						productTypes.add(wrapper.productType);
					}
					for (String productType: productTypes) {
						Deal_Support_Request__c dsr = new ABNChangeDSRGenerator.TerminateDSR(request.organisationId, request.reason, productType, request.atRiskBusinessId, request.organisationABN).toDsrRecord();
						newDSRs.add(dsr);
						dsrTypes.add('Terminate ' + productType + ' Contracts DSR');
					}
				}
				when 'terminateSTBAs' {
					Deal_Support_Request__c dsr = new ABNChangeDSRGenerator.TerminateSTBAs(request.organisationId, request.atRiskBusinessId, request.relatedOpportunity, request.organisationABN, request.reason).toDsrRecord();
					newDSRs.add(dsr);
					dsrTypes.add('Terminate ST Billing Accounts DSR');
				}
				when 'closeAllBAs' {
					List<Billing_Account__c> billingAccounts = BillingAccountsSelector.newInstance(0, BILLING_ACCOUNT_FIELD_OVERRIDES).selectByOrganisationABN(new Set<String> {request.organisationABN}, new Set<Object>{BillingAccountsSelector.Options.FILTER_ACTIVE, BillingAccountsSelector.Options.FILTER_SOURCE_SYSTEM_SAP_ERP});
					result.put('csvRequired', billingAccounts.size() > 5);
					if (billingAccounts.size() > 0) {
						closeAllBAs = new ABNChangeDSRGenerator.CloseAllBAs(request.organisationId, request.atRiskBusinessId, request.reason, billingAccounts, request.estimatedClosureDate);
						Deal_Support_Request__c dsr = closeAllBAs.toDsrRecord();
						newDSRs.add(dsr);
						dsrTypes.add('Close All Billing Accounts DSR');
					}
				}
			}
		}

		result.put('dsrTypes', dsrTypes);
		result.put('newDSRs', newDSRs);
		result.put('closeAllBAs', closeAllBAs);

		return result;
	}

	public class DSRRequestWrapper {
		@AuraEnabled
		public List<String> dsrTypes {get; set;} // proposalGeneration, contractGeneration, terminateContracts, closeAllBAs, terminateSTBAs
		@AuraEnabled
		public String atRiskBusinessId {get; set;}
		@AuraEnabled
		public String organisationId {get; set;} //BaR -> legal entity
		@AuraEnabled
		public String organisationABN {get; set;} //BaR -> legal entity -> ABN
		@AuraEnabled
		public String reason {get; set;}
		@AuraEnabled
		public List<DSRRequestOpportunityWrapper> opportunityWrappers {get; set;} // user-selected opportunities
		@AuraEnabled
		public String relatedOpportunity {get; set;} // only for terminated DSR
		@AuraEnabled
		public List<String> allProductTypes {get; set;}
		@AuraEnabled
		public String isStandardPricing {get; set;} // Yes or No
		@AuraEnabled
		public List<String> pricingDSRNames {get; set;} // if no standard pricing
		@AuraEnabled
		public Date estimatedClosureDate {get; set;} // Yes or No
		@AuraEnabled
		public List<String> customerRequestDocumentIds {get; set;} // if DSR has more than 5 billing accounts associated
	}

	public class DSRRequestOpportunityWrapper {
		@AuraEnabled
		public String opportunityId {get; set;}
		@AuraEnabled
		public String productType {get; set;} // either AP or ST
		@AuraEnabled
		public String keyContactId {get; set;}
	}
}