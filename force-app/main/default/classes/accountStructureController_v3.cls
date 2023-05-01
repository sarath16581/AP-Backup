/**
 *	2020.18.11 Change made by @madhuri.awasthi@auspost.com.au Added an extra column Type__ field in the Excel and Query
 *	2021.18.02 Change made by @madhuri.awasthi@auspost.com.au Changed the Test method
 *	2021.24.06 Change made by @Suman.gunaganti@auspost.com.au Added new columns in org and billing account sections
 *	2021.28.09 Change made by seth.heang@auspost.com.au uplift the SF API version to 52
 *	2023.04	Modified Controller to avoid Timeout Exception and to reduce the number of SOQLs called
*/

public class accountStructureController_v3 {
	private Id currentId;

	public List<AccountWrapper> getInfo() {
		currentId = ApexPages.currentPage().getParameters().get('aId');
		
		// SOQL - retrieve rootId (TopLevel AccountId) from the current Id
		Id rootId = getTopLevelAccountId(currentId);

		// SOQL - retrieve all account records in the hierarchy
		Map<Id, Integer> accountIdWithLevel = new Map<Id, Integer>();
		accountIdWithLevel.put(rootId, 0); // add rootId at level 0
		accountIdWithLevel.putAll(getChildAccountsInHierarchyWithLevel(rootId)); // retrieve all childAccountIds and their level
		
		// SOQL - retrieve all the account records
		// Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
		// 	Account.SObjectType => new Set<SObjectField>{ 
		// 		Account.Id, Account.Name, Parent.Name, Account.Organisation_Trading_Name__c, Account.AccountNumber, Owner.Name, ABN__c,
		// 		ACN__c, Holding_Role_Reference__r.Name, Sales_Director__r.Name, ParentId
		// 	},
		// 	Billing_Accounts__c.SObjectType =>  new Set<SObjectField>{ 
		// 		User.Id, User.Name 
		// 	},
		// 	User.SObjectType => new Set<SObjectField>{ User.Id, User.Name }
		// };
		// Map<Id, Account> accountMap = AccountsSelector.newInstance(0, fieldOverrides)
		// 	.selectById(
		// 		accountIdWithLevel.keySet(),
		// 		new Set<Object>{ 

		// 		}
		// 	);
		
		Map<Id, Account> accountMap = new Map<Id, Account>(
		[
			SELECT Id, Name, Parent.Name, Organisation_Trading_Name__c, AccountNumber, Owner.Name, ABN__c, 
			ACN__c, Holding_Role_Reference__r.Name, Sales_Director__r.Name, ParentId,
			(
				SELECT Id, Name, Payer_Account_Legacy_Id__c, Type__c, SAP_marked_for_deletion__c,
				ABN__c,  ACN__c, LEGACY_ID__c, Payer_Account_ID__r.Name, Organisation__r.Name
				FROM Billing_Accounts__r
				ORDER BY Name ASC NULLS LAST
			)
			FROM Account
			WHERE Id IN :accountIdWithLevel.keySet()
		]
		);
	
		Set<Id> billingAccountIdWithAuthRuleSet = new Set<Id>(); // BillingAccountIds which has Authorization Rules
		Map<Id, Set<String>> billingAccountIdBAMAppKeyMap = new Map<Id, Set<String>>(); // BillingAccountIds with BAMContact AppKey Set
		Map<Id, Set<String>> accountIdBAMAppKeyMap = new Map<Id, Set<String>>(); // AccountIds with BAMContact AppKey Set

		// SOQL - retrieve Billing Account Ids from Authorization Rules for all the account records in hierarchy 
		for (Authorization_Rule__c ar : [ SELECT Billing_Account__c FROM Authorization_Rule__c 
											WHERE Billing_Account__r.Organisation__c IN :accountMap.keySet()]) {
			billingAccountIdWithAuthRuleSet.add(ar.Billing_Account__c);
		}

		// SOQL - retrieve BAMContactRoles for all the account records in hierarchy
		List<BAMContactRole__c> bamContactRoleList = [
			SELECT ContactApplication__r.Contact__r.AccountId, ContactApplication__r.AppKey__c
			FROM BAMContactRole__c
			WHERE
				ContactApplication__r.Status__c = 'Active'
				AND ContactApplication__r.Contact__r.Status__c = 'Active'
				AND ApplicationRole__r.Role__c = 'Super Admin'
				AND ApplicationRole__r.ShowOrganisation__c = TRUE
				AND ContactApplication__r.AppKey__c != null
				AND ContactApplication__r.Contact__r.AccountId IN :accountMap.keySet()
		];
		for(BAMContactRole__c bc : bamContactRoleList) {
			Id key = bc.ContactApplication__r.Contact__r.AccountId;
			Set<String> appKeySet = accountIdBAMAppKeyMap.containsKey(key) ? accountIdBAMAppKeyMap.get(key) : new Set<String>();
			appKeySet.add(bc.ContactApplication__r.AppKey__c);
			accountIdBAMAppKeyMap.put(key, appKeySet);
		}

		// SOQL - retrieve BAMContactRoles for all the account records in hierarchy
		List<BAMLinkedEntity__c> bamLinkedEntityList = [
			SELECT BillingAccount__c, ContactRole__r.ApplicationRole__r.Application__r.AppKey__c
			FROM BAMLinkedEntity__c
			WHERE
				Status__c = 'Active'
				AND ContactRole__r.Status__c = 'Active'
				AND ContactRole__r.ContactApplication__r.Status__c = 'Active'
				AND ContactRole__r.ContactApplication__r.Contact__r.Status__c = 'Active'
				AND BillingAccount__c != null
				AND ContactRole__r.ApplicationRole__r.Application__r.AppKey__c != null
				AND ContactRole__r.ContactApplication__r.Contact__r.AccountId IN :accountMap.keySet()
		];
		for(BAMLinkedEntity__c bl : bamLinkedEntityList) {
			Id key = bl.BillingAccount__c;
			Set<String> appKeySet = billingAccountIdBAMAppKeyMap.containsKey(key) ? billingAccountIdBAMAppKeyMap.get(key) : new Set<String>();
			appKeySet.add(bl.ContactRole__r.ApplicationRole__r.Application__r.AppKey__c);
			billingAccountIdBAMAppKeyMap.put(key, appKeySet);
		}

		// Iterate through each account and update the wrapper
		List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
		for (Id accountId : accountIdWithLevel.keySet()) {
			Account acc = accountMap.get(accountId);
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
		return accountWrapperList;
	}

	/**
	* Get the top level AccountId from the current AccountId
	* @param currentId 
	* @return  `Id`
	*/	
	private Id getTopLevelAccountId(Id currentId) {
		Map<Id, Account> accountMap = AccountsSelector.newInstance(
			1,
			new Set<SObjectField>{ Account.Id, Account.Root_Id__c }
		).selectById(new Set<Id>{ currentId });
		
		return accountMap.isEmpty() ? currentId : accountMap.values()[0].Root_Id__c;
		/* Boolean isTopLevelAccount = false;
		while (!isTopLevelAccount) {
			Account a = [SELECT Id, ParentId FROM Account WHERE Id = :currentId LIMIT 1];
			if (a.ParentId != null) {
				currentId = a.ParentId;
			} else {
				isTopLevelAccount = true;
			}
		}
		return currentId; */
	}

	/**
 	* Get all the child Account Ids and their level (ex: 1=Child, 2=GrandChild and so on) from provided top level AccountId
	* @param rootId 
	* @return  `Map<Id, Integer>`
	*/
	private Map<Id, Integer> getChildAccountsInHierarchyWithLevel(Id rootId) {
		Integer level = 1; // set initial level to 1
		Set<Id> loopSet = new Set<Id>{ rootId }; // initialise with top level AccountId
        Map<Id, Account> accountMap = new Map<Id, Account>();
		Map<Id, Integer> childAccountMap = new Map<Id, Integer>();
		
		while (loopSet.size()>0) {
			accountMap = new Map<Id, Account>([SELECT Id, ParentId FROM Account WHERE ParentId IN :loopSet ORDER BY Name ASC]);
			if(accountMap.isEmpty()) {
				break; // if no more child accounts found then break
			}
			loopSet.clear(); // purge for a rebuild
            for(Account acc : accountMap.values()) {
				loopSet.add(acc.Id); // building for next hierachial while..do loop
				childAccountMap.put(acc.Id, level); // collection to store all childAccountIds
			}
			level++;
        }
		return childAccountMap;
	}

	public class AccountWrapper {
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