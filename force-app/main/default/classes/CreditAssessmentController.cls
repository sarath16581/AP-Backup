/**
 * @author Harry Wang
 * @date 2023-02-05
 * @group Controller
 * @tag Controller
 * @tag CSP
 * @domain CreditAssessment
 * @description Service Controller class for Credit Assessment view on Opportunity.
 * @changelog
 * 2023-02-05 - Harry Wang - Created
 */
public with sharing class CreditAssessmentController {
	// Credit Assessment conditions on the opportunity
	private static final String OPPORTUNITY_CLOSED_NO_CA = 'OPPORTUNITY_CLOSED_NO_CA';
	private static final String OPPORTUNITY_PRIMARY_NOT_CHECKED = 'OPPORTUNITY_PRIMARY_NOT_CHECKED';
	private static final String OPPORTUNITY_INCOMPLETE_OPC = 'OPPORTUNITY_INCOMPLETE_OPC';
	private static final Map<SObjectType, Set<SObjectField>> OPPORTUNITY_FIELD_OVERRIDES = new Map<SObjectType, Set<SObjectField>>{
			Opportunity.SObjectType => new Set<SObjectField>{Opportunity.StageName, Opportunity.Count_of_Contract_Start_Dates__c, Opportunity.Count_of_Contract_End_Dates__c, Opportunity.Count_of_Opportunity_Line_Items__c},
			Apttus_Proposal__Proposal__c.SObjectType => new Set<SObjectField>{Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary__c, Apttus_Proposal__Proposal__c.Apttus_QPConfig__ConfigurationFinalizedDate__c}
	};

	/**
	 * This method is used to get credit assessments with required settings associated to the opportunity
	 * @param opportunityId ID of the opportunity
	 * @return wrapper of the credit assessments result
	 */
	@AuraEnabled(cacheable=true)
	public static CreditAssessmentResultWrapper getOpportunityCreditAssessment(String opportunityId) {
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Apttus_Proposal__Proposal__c.SObjectType => new Set<SObjectField>{Apttus_Proposal__Proposal__c.Id, Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary__c, Apttus_Proposal__Proposal__c.APT_Credit_Assessment_Status__c, Apttus_Proposal__Proposal__c.APT_Method_of_Payment__c, Apttus_Proposal__Proposal__c.APT_Credit_Assessment__c}
		};
		try {
			// Retrieve query fields from fieldset
			Set<SObjectField> caSObjectFields = new Set<SObjectField>();

			for (Schema.FieldSetMember fs: SObjectType.APT_Credit_Assessment__c.fieldSets.Credit_Assessment_View_in_Opportunity.getFields()) {
				caSObjectFields.add(fs.getSObjectField());
			}
			// Add additional required fields
			caSObjectFields.add(APT_Credit_Assessment__c.SObjectType.getDescribe().fields.getMap().get('APT_Charge_Account__c'));
			fieldOverrides.put(APT_Credit_Assessment__c.SObjectType, caSObjectFields);

			Opportunity opp = OpportunitySelector.newInstance(1, OPPORTUNITY_FIELD_OVERRIDES).selectById(new Set<Id>{opportunityId}, new Set<Object>{OpportunitySelector.Options.WITH_CHILD_PROPOSALS
			}).values()[0];
			List<APT_Credit_Assessment__c> cas = CreditsAssessmentSelector.newInstance(fieldOverrides).selectByProposalOpportunity(new Set<Id>{opportunityId}, new Set<Object>{CreditsAssessmentSelector.Options.WITH_PROPOSAL});

			// initiate message body map with custom labels
			Map<String, String> messageBodyMap = new Map<String, String>();
			messageBodyMap.put(OPPORTUNITY_CLOSED_NO_CA, System.Label.CreditAssessmentRequestClosedOpp);
			messageBodyMap.put(OPPORTUNITY_INCOMPLETE_OPC, System.Label.CreditAssessmentRequestIncompleteOPC);
			messageBodyMap.put(OPPORTUNITY_PRIMARY_NOT_CHECKED, System.Label.CreditAssessmentRequestPrimaryNotChecked);

			return new CreditAssessmentResultWrapper(opp, cas, messageBodyMap);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * This method is used to get datatable columns from fieldset used for the credit assessment view in opportunity
	 * @return list of datatable columns
	 */
	@AuraEnabled(cacheable=true)
	public static List<DataTableColumn> retrieveDatatableColumns() {
		try {
			List<DataTableColumn> dataTableColumnList = new List<DataTableColumn>();

			for (Schema.FieldSetMember fs: SObjectType.APT_Credit_Assessment__c.fieldSets.Credit_Assessment_View_in_Opportunity.getFields()) {
				DataTableColumn datatableColumn = new DataTableColumn(fs.getLabel(), fs.getFieldPath(), String.valueOf(fs.getType()));
				dataTableColumnList.add(datatableColumn);
			}

			return dataTableColumnList;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * This method is used to update credit assessment details
	 */
	@AuraEnabled
	public static void updateCreditAssessmentDetails(List<SObject> creditAssessmentDetails) {
		try {
			ApplicationDatabase.getInstance().dmlUpdate(creditAssessmentDetails);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class CreditAssessmentResultWrapper {
		@AuraEnabled
		public Opportunity opportunity { get; set; }

		@AuraEnabled
		public List<APT_Credit_Assessment__c> creditAssessments { get; set; }

		@AuraEnabled
		public Map<String, String> messageBodyMap { get; set; }

		private CreditAssessmentResultWrapper(Opportunity opportunity, List<APT_Credit_Assessment__c> creditAssessments, Map<String, String> messageBodyMap) {
			this.opportunity = opportunity;
			this.creditAssessments = creditAssessments;
			this.messageBodyMap = messageBodyMap;
		}
	}

	public class DataTableColumn {
		@AuraEnabled
		public String label {get;set;}
		@AuraEnabled
		public String fieldName {get;set;}
		@AuraEnabled
		public String type {get;set;}
		@AuraEnabled
		public TypeAttributes typeAttributes {get;set;}

		public DataTableColumn(String label, String fieldName, String type)
		{
			this.label = label;
			if (fieldName == 'Name') {
				LabelWrapper labelWrapper = new LabelWrapper(fieldName);
				TypeAttributes typeAttributes = new TypeAttributes(labelWrapper, '_blank');
				this.typeAttributes = typeAttributes;
				this.fieldName = 'caUrl';
				this.type = 'url';
			} else {
				this.fieldName = fieldName;
				if (fieldName == 'CreatedDate') {
					this.type = 'date';
				} else {
					this.type = type;
				}
			}
		}
	}

	public class TypeAttributes {
		@AuraEnabled
		public LabelWrapper label {get;set;}
		@AuraEnabled
		public String target {get;set;}

		public TypeAttributes(LabelWrapper label, String target) {
			this.label = label;
			this.target = target;
		}
	}

	public class LabelWrapper {
		@AuraEnabled
		public String fieldName {get;set;}

		public LabelWrapper(String fieldName) {
			this.fieldName = fieldName;
		}
	}
}