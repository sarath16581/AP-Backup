/***
 * @author Naveen Rajanna
 * @date 2023-05-01
 * @group Controller
 * @description Custom Controller for buildHierarchyView VF page displaying Account Hierarchy, it's Billing Account and more.
 * @changelog
 *	2020.18.11 Change made by @madhuri.awasthi@auspost.com.au Added an extra column Type__ field in the Excel and Query
 *	2021.18.02 Change made by @madhuri.awasthi@auspost.com.au Changed the Test method
 *	2021.24.06 Change made by @Suman.gunaganti@auspost.com.au Added new columns in org and billing account sections
 *	2021.28.09 Change made by seth.heang@auspost.com.au uplift the SF API version to 52
 *	2023.05.01 Naveen Rajanna - REQ2916371 - Refactor Controller code to avoid Timeout Exception and reduce the number of SOQLs invoked
*/
public class accountStructureController {
	private Id currentId; // acountId passed from visualforce page
	private Map<Id, Integer> accountIdWithLevel; // accountId and the level it belongs in hierarchy
	// 0 - rootId, 1 - children, 2 - grand children and so on

 	/**
  	* Get the wrapper list containing Accounts and related Billing Accounts to display on VF
  	* @return  `List<AccountWrapper>`
  	*/	
	public List<AccountWrapper> getInfo() {
		currentId = ApexPages.currentPage().getParameters().get('aId');
		accountIdWithLevel = new Map<Id, Integer>();
		
		// SOQL - retrieve rootId (TopLevel AccountId) from the current Id
		Id rootId = getTopLevelAccountId(currentId);
		accountIdWithLevel.put(rootId, 0); // add TopLevel AccountId at level 0

		// SOQL - update collection by retrieving all child accountIds in hierarchy by passing rootId (TopLevel AccountId) and root level
		getChildAccountsWithParent5Levels(new Set<Id>{rootId}, 0);
		
		// SOQL - retrieve all account records with relationship records
		Map<Id, Account> accountMap = new Map<Id, Account>([
			SELECT Id, Name, ParentId, Parent.Name, Organisation_Trading_Name__c, AccountNumber, Owner.Name, 
			ABN__c, ACN__c, Holding_Role_Reference__r.Name, Sales_Director__r.Name,
			(
				SELECT Id, Name, Payer_Account_Legacy_Id__c, Type__c, SAP_marked_for_deletion__c, 
				ABN__c, ACN__c, LEGACY_ID__c, Payer_Account_ID__r.Name, Organisation__r.Name
				FROM Billing_Accounts__r ORDER BY Name ASC NULLS LAST
			)
			FROM Account WHERE Id IN :accountIdWithLevel.keySet()
		]);
	
		Set<Id> billingAccountIdWithAuthRuleSet = new Set<Id>(); // BillingAccountIds which has Authorization Rules
		Map<Id, Set<String>> billingAccountIdBAMAppKeyMap = new Map<Id, Set<String>>(); // BillingAccountIds with BAMContact AppKey Set
		Map<Id, Set<String>> accountIdBAMAppKeyMap = new Map<Id, Set<String>>(); // AccountIds with BAMContact AppKey Set

		// SOQL - retrieve BillingAccountIds from Authorization Rules for all the account records in hierarchy 
		for (Authorization_Rule__c ar : [SELECT Billing_Account__c FROM Authorization_Rule__c 
											WHERE Billing_Account__r.Organisation__c IN :accountMap.keySet()]) {
			billingAccountIdWithAuthRuleSet.add(ar.Billing_Account__c);
		}

		// SOQL - retrieve AppKeys from BAMContactRole for all the account records in hierarchy
		for(BAMContactRole__c bc : [SELECT ContactApplication__r.Contact__r.AccountId, ContactApplication__r.AppKey__c 
										FROM BAMContactRole__c WHERE ContactApplication__r.Status__c = 'Active' AND 
										ContactApplication__r.Contact__r.Status__c = 'Active' AND ApplicationRole__r.Role__c = 'Super Admin' AND 
										ApplicationRole__r.ShowOrganisation__c = TRUE AND ContactApplication__r.AppKey__c != null AND 
										ContactApplication__r.Contact__r.AccountId IN :accountMap.keySet()]) {
			Id key = bc.ContactApplication__r.Contact__r.AccountId;
			Set<String> appKeySet = accountIdBAMAppKeyMap.containsKey(key) ? accountIdBAMAppKeyMap.get(key) : new Set<String>();
			appKeySet.add(bc.ContactApplication__r.AppKey__c);
			accountIdBAMAppKeyMap.put(key, appKeySet);
		}

		// SOQL - retrieve AppKeys from BAMLinkedEntity for all the account records in hierarchy
		for(BAMLinkedEntity__c bl : [SELECT BillingAccount__c, ContactRole__r.ApplicationRole__r.Application__r.AppKey__c FROM BAMLinkedEntity__c 
										WHERE Status__c = 'Active' AND ContactRole__r.Status__c = 'Active' AND 
										ContactRole__r.ContactApplication__r.Status__c = 'Active' AND 
										ContactRole__r.ContactApplication__r.Contact__r.Status__c = 'Active' AND 
										BillingAccount__c != null AND ContactRole__r.ApplicationRole__r.Application__r.AppKey__c != null AND 
										ContactRole__r.ContactApplication__r.Contact__r.AccountId IN :accountMap.keySet()]) {
			Id key = bl.BillingAccount__c;
			Set<String> appKeySet = billingAccountIdBAMAppKeyMap.containsKey(key) ? billingAccountIdBAMAppKeyMap.get(key) : new Set<String>();
			appKeySet.add(bl.ContactRole__r.ApplicationRole__r.Application__r.AppKey__c);
			billingAccountIdBAMAppKeyMap.put(key, appKeySet);
		}

		// Iterate through each account and add to accountWrapperList
		List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
		for (Id accId : accountIdWithLevel.keySet()) {
			Account acc = accountMap.get(accId);
			List<BillingAccountWrapper> billingAccountWrapperList = new List<BillingAccountWrapper>();
			for (Billing_Account__c ba : acc.getSObjects('Billing_Accounts__r')) {
				billingAccountWrapperList.add(
					new BillingAccountWrapper(
						ba,
						billingAccountIdWithAuthRuleSet.contains(ba.Id),
						billingAccountIdBAMAppKeyMap.containsKey(ba.Id) ? billingAccountIdBAMAppKeyMap.get(ba.Id) : new Set<String>()
					)
				);
			}
			accountWrapperList.add(
				new AccountWrapper(
					accountIdWithLevel.get(acc.Id),
					acc,
					accountIdBAMAppKeyMap.containsKey(acc.Id) ? accountIdBAMAppKeyMap.get(acc.Id) : new Set<String>(),
					billingAccountWrapperList
				)
			);
		}
		accountWrapperList.sort(); // sort based on level

		return accountWrapperList;
	}

	/**
	* Get the top level AccountId from the passed AccountId
	* @param currentId 
	* @return  `Id`
	*/	
	private Id getTopLevelAccountId(Id currentId) {
		// Option WITH_PARENT_5LEVELS will fetch ParentIds up to 5 levels
		Map<Id, Account> accountMap = AccountsSelector.newInstance(1, new Set<SObjectField>{Account.Id, Account.ParentId})
			.selectById(new Set<Id>{currentId}, new Set<Object>{AccountsSelector.Options.WITH_PARENT_5LEVELS});
		
		// if no rows, return currentId as that is the top level accountId
		if(accountMap.isEmpty()) {
			return currentId;
		}

		// identify the top level Parent, if more than 5 Parent levels, invoke same method passing the latest parentId
		Account acc = accountMap.values()[0];
		return acc.Parent == null ? acc.Id
			: acc.Parent.Parent == null ? acc.Parent.Id
			: acc.Parent.Parent.Parent == null ? acc.Parent.Parent.Id
			: acc.Parent.Parent.Parent.Parent == null ? acc.Parent.Parent.Parent.Id
			: acc.Parent.Parent.Parent.Parent.Parent == null ? acc.Parent.Parent.Parent.Parent.Id 
			: getTopLevelAccountId(acc.Parent.Parent.Parent.Parent.Parent.Id);
	}

	/**
 	* Get all the child accountIds and ParentIds upto 5 levels, if there are more than 5 levels invoke another method
	* Updates collection accountIdWithLevel - accountId and the level it belongs in hierarchy
	* @param parentIdSet
	* @param parentLevel
	*/
	private void getChildAccountsWithParent5Levels(Set<Id> parentIdSet, Integer parentLevel) {
		Set<Id> loopSet = new Set<Id>(); // accountIds which needs to be re-queried
		List<Account> accountList = AccountsSelector.newInstance(
			0, new Set<SObjectField>{ Account.Id, Account.ParentId }
		).search(
			new Map<String, Object>{
				'parentIds' => parentIdSet, 'parentIdsLevel2' => parentIdSet, 'parentIdsLevel3' => parentIdSet,
				'parentIdsLevel4' => parentIdSet, 'parentIdsLevel5' => parentIdSet, 'parentIdsLevel6' => parentIdSet
			},
			new Set<Object>{AccountsSelector.Options.WITH_PARENT_5LEVELS}, '1 OR 2 OR 3 OR 4 OR 5 OR 6', Account.Name, 'ASC'
		);

		for (Account acc : accountList) {
			// get HierarchyLevel based on the Parent levels
			Integer level = parentIdSet.contains(acc.ParentId) ? parentlevel+1 :
			parentIdSet.contains(acc.Parent.ParentId) ? parentlevel+2 :
			parentIdSet.contains(acc.Parent.Parent.ParentId) ? parentlevel+3 :
			parentIdSet.contains(acc.Parent.Parent.Parent.ParentId) ? parentlevel+4 :
			parentIdSet.contains(acc.Parent.Parent.Parent.Parent.ParentId) ? parentlevel+5 : -1;
			
			// if level is -1 then there are parentIds more than 5 levels - store parentIds, invoke another soql later
			if(level == -1) {
				loopSet.add(acc.ParentId);
			} else {
				accountIdWithLevel.put(acc.Id, level);
			}
		}

		// check if method needs to be called again based on the loopSet i.e. if parentId levels are more than 5 levels
		if(!loopSet.isEmpty()) {
			getChildAccountsWithParent5Levels(loopSet, parentLevel + 5);
		}
	}

	public class AccountWrapper implements Comparable {
		public Integer Level {get; set;}
		public String Name {get; set;}
		public String ParentName {get; set;}
		public String OrganisationTradingName {get; set;}
		public String AccountNumber {get; set;}
		public String ABN {get; set;}
		public String ACN {get; set;}
		public String OwnerName {get; set;}
		public String HoldingRoleReferenceName {get; set;}
		public String SalesDirectorName {get; set;}
		public String SuperAdminTo {get; set;}
		public List<BillingAccountWrapper> BAList {get; set;}

		public AccountWrapper(Integer level, Account acc, Set<String> superAdminSet, List<BillingAccountWrapper> billingAccountWrapperList) {
			this.Level = level;
			this.Name = acc.Name;
			this.ParentName = acc.Parent.Name;
			this.OrganisationTradingName = acc.Organisation_Trading_Name__c;
			this.AccountNumber = acc.AccountNumber;
			this.ABN = acc.ABN__c;
			this.ACN = acc.ACN__c;
			this.OwnerName = acc.owner.Name;
			this.HoldingRoleReferenceName = acc.Holding_Role_Reference__r.name;
			this.SalesDirectorName = acc.Sales_Director__r.Name;
			this.SuperAdminTo = superAdminSet.size() > 0 ? new List<String>(superAdminSet).toString() : null;
			this.BAList = billingAccountWrapperList;
		}
		
		public Integer compareTo(Object other) {
			AccountWrapper otherWrapper = (AccountWrapper) other;
			return this.Level - otherWrapper.Level;
		}
	}

	public class BillingAccountWrapper {
		public String Name {get; set;}
		public String LegacyId {get; set;}
		public String Type {get; set;}
		public Boolean SapMarkedfordeletion {get; set;}
		public String ABN {get; set;}
		public String ACN {get; set;}
		public String PayerAccountLegacyId {get; set;}
		public Boolean HasAuthorisationRule {get; set;}
		public Boolean HasBAMRole {get; set;}
		public String BAMApplications {get; set;}

		public BillingAccountWrapper(Billing_Account__c ba, Boolean hasAuthorisationRule, Set<String> bamApps) {
			this.Name = ba.name;
			this.LegacyId = ba.LEGACY_ID__c;
			this.Type = ba.type__c;
			this.Sapmarkedfordeletion = ba.SAP_marked_for_deletion__c;
			this.ABN = ba.ABN__c;
			this.ACN = ba.ACN__c;
			this.PayerAccountLegacyId = ba.Payer_Account_Legacy_Id__c;
			this.HasAuthorisationRule = hasAuthorisationRule;
			this.HasBAMRole = bamApps.size() > 0 ? true : false;
			this.BAMApplications = bamApps.size() > 0 ? new List<String>(bamApps).toString() : null;
		}
	}
}