/**
 * @author Harry Wang
 * @date 2024-08-08
 * @tag ABN Change
 * @tag CSP
 * @description Parent generator class to generate DSR for ABN Change. Inherited by sub generators to meet different business requirements
 * @changelog
 * 2024-08-08 - Harry Wang - Created
 */
public abstract with sharing class ABNChangeDSRGenerator {
	public static final List<String> CLOSE_ALL_BA_CSV_HEADERS = new List<String>{'LEGACY_ID__c', 'Credit_Representative_Email__c'};
	public static List<String> allProductTypes;
	public Id organisationId;
	public Id atRiskBusinessId;
	public String productType;

	public ABNChangeDSRGenerator(Id organisationId, Id atRiskBusinessId) {
		this(organisationId, atRiskBusinessId, null);
	}

	public ABNChangeDSRGenerator(Id organisationId, Id atRiskBusinessId, String productType) {
		this.organisationId = organisationId;
		this.atRiskBusinessId = atRiskBusinessId;
		this.productType = productType;
	}

	/**
	 * This method is used to generate generic DSR record based on the parent's attributes
	 *
	 * @return generated DSR record
	 */
	public virtual Deal_Support_Request__c toDsrRecord() {
		Deal_Support_Request__c dsr = new Deal_Support_Request__c();
		dsr.Requestor_Name__c = UserInfo.getName();
		dsr.Billing_Number__c = 'TBA';
		dsr.Stage__c = 'New';
		dsr.Priority__c = 'Medium';
		dsr.Status__c = 'Draft';
		dsr.Business_At_Risk__c = this.atRiskBusinessId;
		dsr.Requestor__c = UserInfo.getUserId();
		dsr.Organisation__c = this.organisationId;
		dsr.Product__c = getProducts(productType);
		// Map common fields here

		return dsr;
	}

	/**
	 * Abstract method to return DSR record type Id for the current generator
	 *
	 * @return record type Id
	 */
	public abstract String getRecordTypeId();

	/**
	 * Abstract method to compute DSR's description for the current generator
	 *
	 * @return record type Id
	 */
	public abstract String getDescription();

	/**
	 *  Sub class - ProposalContractDSR inherited from ABNChangeDSRGenerator
	 */
	public class ProposalContractDSR extends ABNChangeDSRGenerator {
		public Boolean isProposal;
		public Id opportunityId;
		public Id keyContactId;
		public String isStandardPricing;
		public List<String> pricingDSRNames;

		public ProposalContractDSR(Boolean isProposal, Id organisationId, String opportunityId, String productType, Id keyContactId, Id atRiskBusinessId, String isStandardPricing, List<String> pricingDSRNames) {
			super(organisationId, atRiskBusinessId, productType);

			this.isProposal = isProposal;
			this.keyContactId = keyContactId;
			this.opportunityId = opportunityId;
			this.isStandardPricing = isStandardPricing;
			this.pricingDSRNames = pricingDSRNames;
		}

		/**
		* This method is used to generate Proposal Contract DSR record based on the attributes
		*
		* @return generated DSR record
		*/
		public override Deal_Support_Request__c toDsrRecord() {
			Deal_Support_Request__c dsr = super.toDsrRecord();
			// Map other fields specifically for proposal dsr below and return
			dsr.Work_Type__c = this.isProposal ? 'New Proposal' : 'New Agreement';
			dsr.Support_Work_Type__c = 'Deal Enablement Support';
			dsr.Description__c = getDescription();
			dsr.Opportunity__c = this.opportunityId;
			dsr.CustomerContact1__c = this.keyContactId;
			dsr.RecordTypeId = getRecordTypeId();
			return dsr;
		}

		/**
		* Overriding method to return DSR record type Id for Proposal Contract DSR
		*
		* @return record type Id
		*/
		public override String getRecordTypeId() {
			return Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Deal_Enablement_Centre').getRecordTypeId();
		}

		/**
		* Overriding method to compute description for Proposal Contract DSR
		*
		* @return record type Id
		*/
		public override String getDescription() {
			String text = 'Customer has changed ABN.\nReason: ABN Change - Same Owners.\nWill standard Apttus pricing be utilized: ' + this.isStandardPricing;
			if (this.isStandardPricing == 'No') {
				text = text + '\nPricing Request DSR: ' + String.join(this.pricingDSRNames, ', ');
			}
			return text;
		}
	}

	/**
	 *  Sub class - TerminateDSR inherited from ABNChangeDSRGenerator
	 */
	public class TerminateDSR extends ABNChangeDSRGenerator {
		public String organisationABN;
		public TerminateDSR(Id organisationId, String productType, Id atRiskBusinessId, String organisationABN) {
			super(organisationId, atRiskBusinessId, productType);
			this.organisationABN = organisationABN;
		}

		/**
		* This method is used to generate Terminate DSR record based on the attributes
		*
		* @return generated DSR record
		*/
		public override Deal_Support_Request__c toDsrRecord() {
			Deal_Support_Request__c dsr = super.toDsrRecord();
			// Map other fields specifically for proposal dsr below and return
			dsr.Sub_Accounts__c = 'See all Sub-Accounts';
			dsr.Work_Type__c = productType == 'ST' ? 'Termination of all ST Contract(s) - ABN Change' : 'Termination of all AP Contract(s) - ABN Change';
			dsr.Support_Work_Type__c = 'Deal Processing';
			dsr.Description__c = getDescription();
			dsr.RecordTypeId = getRecordTypeId();
			return dsr;
		}

		/**
		* Overriding method to return DSR record type Id for Terminate DSR
		*
		* @return record type Id
		*/
		public override String getRecordTypeId() {
			return Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Deal_Enablement_Centre').getRecordTypeId();
		}

		/**
		* Overriding method to compute description for Terminate DSR
		*
		* @return record type Id
		*/
		public override String getDescription() {
			return 'Customer has changed ABN.\nReason: ABN Change - Same Owners.\nCancel all contracts associated to this ABN: ' + this.organisationABN;
		}
	}

	/**
	 *  Sub class - TerminateSTBAs inherited from ABNChangeDSRGenerator
	 */
	public class TerminateSTBAs extends ABNChangeDSRGenerator {
		public Id relatedOpportunityId;
		public String organisationABN;

		public TerminateSTBAs(Id organisationId, Id atRiskBusinessId, Id opportunityId, String organisationABN) {
			super(organisationId, atRiskBusinessId, 'ST');
			this.relatedOpportunityId = opportunityId;
			this.organisationABN = organisationABN;
		}

		/**
		* This method is used to generate Terminate ST Billing Accounts DSR record based on the attributes
		*
		* @return generated DSR record
		*/
		public override Deal_Support_Request__c toDsrRecord() {
			Deal_Support_Request__c dsr = super.toDsrRecord();
			// Map other fields specifically for proposal dsr below and return
			dsr.Sub_Accounts__c = 'See all Sub-Accounts';
			dsr.Work_Type__c = 'Close all ST Billing Account(s) - ABN Change';
			dsr.Support_Work_Type__c = 'Deal Processing';
			dsr.Description__c = getDescription();
			dsr.RecordTypeId = getRecordTypeId();
			dsr.Opportunity__c = relatedOpportunityId;
			return dsr;
		}

		/**
		* Overriding method to return DSR record type Id for Terminate ST Billing Accounts DSR
		*
		* @return record type Id
		*/
		public override String getRecordTypeId() {
			return Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Deal_Enablement_Centre').getRecordTypeId();
		}

		/**
		* Overriding method to compute description for Terminate ST Billing Accounts DSR
		*
		* @return record type Id
		*/
		public override String getDescription() {
			return 'Customer has changed ABN.\nReason: ABN Change - Same Owners.\nClose all ST Billing Accounts associated to this ABN: ' + this.organisationABN;
		}
	}

	/**
	 *  Sub class - CloseAllBAs inherited from ABNChangeDSRGenerator
	 */
	public class CloseAllBAs extends ABNChangeDSRGenerator {
		public List<Billing_Account__c> billingAccounts;
		public Date estimatedClosureDate;
		public List<String> billingAccountNumbers = new List<String>();
		public Set<String> creditOfficerEmails = new Set<String>();
		public Integer countOfParent = 0;

		public CloseAllBAs(Id organisationId, Id atRiskBusinessId, List<Billing_Account__c> billingAccounts, Date estimatedClosureDate) {
			super(organisationId, atRiskBusinessId);
			this.billingAccounts = billingAccounts;
			this.estimatedClosureDate = estimatedClosureDate;
		}

		/**
		* This method is used to generate Close All Billing Accounts DSR record based on the attributes
		*
		* @return generated DSR record
		*/
		public override Deal_Support_Request__c toDsrRecord() {
			Deal_Support_Request__c dsr = super.toDsrRecord();
			String parentCreditPersonName;
			String parentCreditPersonEmail;
			String ParentCreditPersonCode;
			String parentBillingAccountId;
			String parentBillingNumber;
			Boolean parentFound = false;

			// compute parent billing account fields
			for (Billing_Account__c ba: this.billingAccounts) {
				this.billingAccountNumbers.add(ba.LEGACY_ID__c);
				this.creditOfficerEmails.add(ba.Credit_Representative_Email__c);
				// populate credit management fields if parent billing account is found
				if (ba.PAYER_ACCOUNT_ID__c == null) {
					this.countOfParent++;
					parentFound = true;
					parentCreditPersonName = ba.Credit_Person__c;
					parentCreditPersonEmail = ba.Credit_Representative_Email__c;
					ParentCreditPersonCode = ba.Credit_Person_Code__c;
					parentBillingAccountId = ba.Id;
					parentBillingNumber = ba.LEGACY_ID__c;
				}
			}
			dsr.Credit_Work_Type__c = 'Close All Billing Accounts - ABN Change';
			dsr.Pay_Account_Type__c = 'Billing Account';
			dsr.Request_type__c = 'Billing Account';
			dsr.Origin__c = 'Salesforce';
			dsr.Customer_Request_Attached__c = 'No';
			dsr.Reason_for_Account_Closure__c = getDescription();
			dsr.Credit_Representative_Email__c = parentFound ? parentCreditPersonEmail : this.billingAccounts[0].Credit_Representative_Email__c;
			dsr.Credit_Representative__c = parentFound ? parentCreditPersonName : this.billingAccounts[0].Credit_Person__c;
			dsr.Credit_Person_Code__c = parentFound ? ParentCreditPersonCode : this.billingAccounts[0].Credit_Person_Code__c;
			dsr.Billing_Account__c = parentFound ? parentBillingAccountId : this.billingAccounts[0].Id;
			dsr.Billing_Number__c = parentFound ? parentBillingNumber : this.billingAccounts[0].LEGACY_ID__c;
			dsr.EstimatedAccountClosureDate__c = this.estimatedClosureDate;
			dsr.RecordTypeId = getRecordTypeId();
			dsr.Customer_Request_Attached__c = 'Yes';

			return dsr;
		}

		/**
		* Overriding method to return DSR record type Id for Close All Billing Accounts DSR
		*
		* @return record type Id
		*/
		public override String getRecordTypeId() {
			return Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Credit_Management_Request').getRecordTypeId();
		}

		/**
		* Overriding method to compute description for Close All Billing Accounts DSR
		*
		* @return record type Id
		*/
		public override String getDescription() {
			//list all billing account numbers if less than 6, otherwise give count of parent and sub-account  types billing accounts
			String text =  'Customer has changed ABN.\nReason: ABN Change - Same Owners.';
			if (this.billingAccounts.size() <= 5) {
				text += '\nBilling Account Number(s): ' + String.join(this.billingAccountNumbers, ', ');
			} else {
				text += '\nCount of Parent Accounts: ' + this.countOfParent + ' and Count of Sub-Accounts: ' + (this.billingAccounts.size() - this.countOfParent) + '\nRefer to CSV for all billing/sub accounts'
						+ (this.creditOfficerEmails.size() > 1 ? '\nThere are more than 1 credit officers linked to the billing accounts under this ABN' : '');
			}
			return text;
		}

		/**
		* Generate CSV for Close All Billing Accounts DSR when more than 5 billing accounts associated
		*
		* @return Content Version record for the CSV document
		*/
		public ContentVersion generateCloseAllBACsv() {
			String headerRow = String.join(CLOSE_ALL_BA_CSV_HEADERS, ',') + '\n';
			List<String> rowVals = new List<String>();
			for (Billing_Account__c ba: this.billingAccounts) {
				List<String> fieldVals = new List<String>();
				for (String field: CLOSE_ALL_BA_CSV_HEADERS) {
					String fieldVal = ba.get(field) != null ? (String)ba.get(field) : '';
					fieldVals.add(fieldVal);
				}
				rowVals.add(String.join(fieldVals, ','));
			}
			String bodyStr = headerRow + String.join(rowVals, '\n');
			ContentVersion cv  = new ContentVersion();
			cv.ContentLocation = 'S';
			cv.PathOnClient = 'close_all_ba.csv';
			cv.Title = 'close_all_ba';
			cv.VersionData = Blob.valueOf(bodyStr);
			return cv;
		}
	}

	/**
	* Compute selectable products for DSR based on the product type
	* Return 'StartTrack' if product type ='ST'; Return all other products excluding 'StarTrack' if  product type = 'AP'
	* @param productType product type in String - either 'AP' or 'ST
	* @return products in String joined with semicolon
	*/
	public String getProducts(String productType) {
		if (productType == null) {
			return null;
		}
		if (productType == 'ST') {
			return 'StarTrack';
		}
		List<String> newProducts = allProductTypes.clone();
		Integer index = newProducts.indexOf('StarTrack');
		newProducts.remove(index);
		return String.join(newProducts, ';');
	}
}