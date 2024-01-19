/**
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @tag Controller
 * @tag CSP
 * @description Service Controller class for follower offspring request for TEAM.
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
public with sharing class FollowerOffspringRequestController {
	/**
	 * @description Get follower account type sub accounts and billing accounts by given leader account Id
	 * @param leaderAccountId leader Id for either billing account or charge account
	 * @param isBillingAccount if leader Id is billing account type
	 * @return matching follower accounts wrapper
	 */
	@AuraEnabled
	public static FollowerAccount getFollowers(String leaderAccountId, Boolean isBillingAccount) {
		List<APT_Sub_Account__c> subAccounts;
		List<Billing_Account__c> billingAccounts;
		if (isBillingAccount) {
			subAccounts = SubAccountRequestsSelector.newInstance().selectByBillingAccountId(new Set<Id>{leaderAccountId}, new Set<Object>{SubAccountRequestsSelector.Options.FILTER_UNPROVISIONED_FOLLOWER_ONLY});
			billingAccounts = BillingAccountsSelector.newInstance().selectByLeaderAccountId(new Set<Id>{leaderAccountId}, new Set<Object>{BillingAccountsSelector.Options.FILTER_ACTIVE, BillingAccountsSelector.Options.FILTER_TYPE_FOLLOWER});
		} else {
			subAccounts = SubAccountRequestsSelector.newInstance().selectByChargeAccountId(new Set<Id>{leaderAccountId}, new Set<Object>{SubAccountRequestsSelector.Options.FILTER_UNPROVISIONED_FOLLOWER_ONLY});
		}
		return new FollowerAccount(subAccounts, billingAccounts);
	}

	/**
	 * @description Get sub accounts by given leader billing account Id
	 * @param leaderAccountId leader Id for billing account
	 * @param isBillingAccount if leader Id is billing account type
	 * @return matching billing accounts
	 */
	@AuraEnabled(cacheable=true)
	//For DSR, Select Sub Account Requests by charge Id which are in draft , error or finalised state
	//For Billing Account Flow, Select Sub Account Requests by Leader Billing Account in Draft or Error stage
	public static List<APT_Sub_Account__c> getSubAccounts(String leaderAccountId, Boolean isBillingAccount) {
		if (isBillingAccount) {
			return SubAccountRequestsSelector.newInstance().selectByBillingAccountId(new Set<Id>{leaderAccountId}, new Set<Object>{SubAccountRequestsSelector.Options.FILTER_DRAFT_ERROR_SUBMITTED});
		}
		return SubAccountRequestsSelector.newInstance().selectByChargeAccountId(new Set<Id>{leaderAccountId}, new Set<Object>{SubAccountRequestsSelector.Options.FILTER_DRAFT_ERROR_PENDING});
	}

	/**
	 * @description Get datatable columns for sub account list view from field set Sub_Accounts_in_Follower_Offspring_List
	 * @return list of datatable column wrapper
	 */
	@AuraEnabled(cacheable=true)
	public static List<DataTableColumn> retrieveListViewColumns() {
		try {
			List<DataTableColumn> dataTableColumnList = new List<DataTableColumn>();

			for (Schema.FieldSetMember fs: SObjectType.APT_Sub_Account__c.fieldSets.Sub_Accounts_in_Follower_Offspring_List.getFields()) {
				DataTableColumn datatableColumn = new DataTableColumn(fs.getLabel(), fs.getFieldPath(), String.valueOf(fs.getType()));
				dataTableColumnList.add(datatableColumn);
			}
			return dataTableColumnList;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @description finalise sub accounts - updating sub account status to 'Pending Charge Account'
	 * @param subAccounts list of sub accounts to be finalised
	 */
	@AuraEnabled
	public static void finaliseSubAccounts(List<APT_Sub_Account__c> subAccounts) {
		try {
			ApplicationDatabase.getInstance().dmlUpdate(subAccounts);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
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
		public Boolean sortable {get;set;}

		public DataTableColumn(String label, String fieldName, String type)
		{
			this.label = label;
			this.fieldName = fieldName;
			if (fieldName == 'CreatedDate') {
				this.type = 'date';
			} else {
				this.type = type;
			}
			this.sortable = true;
		}
	}

	public class FollowerAccount {
		@AuraEnabled
		public List<APT_Sub_Account__c> subAccountFollowers {get; set;}
		@AuraEnabled
		public List<Billing_Account__c> billingAccountFollowers {get; set;}

		public FollowerAccount(List<APT_Sub_Account__c> subAccountFollowers, List<Billing_Account__c> billingAccountFollowers) {
			if (subAccountFollowers == null) {
				this.subAccountFollowers = new List<APT_Sub_Account__c>();
			} else {
				this.subAccountFollowers = subAccountFollowers;
			}
			if (billingAccountFollowers == null) {
				this.billingAccountFollowers = new List<Billing_Account__c>();
			} else {
				this.billingAccountFollowers = billingAccountFollowers;
			}
		}
	}
}