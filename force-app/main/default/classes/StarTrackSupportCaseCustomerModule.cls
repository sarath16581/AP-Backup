/**
 * Domain Modules should NEVER be called directly. Domain modules should only ever be called from a domain class
 *
 * This has been a port of parts of the StarTrack Case Automation process builder. It deals with the following nodes:
 * 1. Consignment Billing Account : If related article billing account is not blank use this information to
 * update case related billing account and update case credit dispute details
 * 2. Case Related Billing Account : If related article billing account is  blank use case related billing account information to
 * update case related billing account and update case credit dispute details
 * 3. Case Customer Changed : If related billing account changes use Account information to
 * update case related billing account and update case credit dispute details
 * 4. Clear Customer/Related Account Details : If related account or account is null then clear the details
 *
 * @author Snehil Jaiswal
 * @date 2021-06-20
 * @channel Domain
 * @domain StartracK
 * @changelog
 * 2023-06-14 - Nathan Franklin - uplift to domainless architecture
 */

public inherited sharing class StarTrackSupportCaseCustomerModule extends ApplicationModule {

	/**
	 * @deprecated
	 */
	public static StarTrackSupportCaseCustomerModule newInstance() {
		return (StarTrackSupportCaseCustomerModule) Application.Utilities.newInstance(
			StarTrackSupportCaseCustomerModule.class
		);
	}

	// Setup which triggers this module should respond to
	public StarTrackSupportCaseCustomerModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override List<SObject> filter(List<SObject> records) {
		return CaseAutomationTriggerHandler.filterStarTrackCases(records);
	}

	// Grab the credit claim dispute record type to determine which cases should be updated with the correct default values
	public static Id creditClaimRecordTypeId {
		get {
			if (creditClaimRecordTypeId == null) {
				creditClaimRecordTypeId = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'StarTrack_Credit_Dispute_Claim').values()[0].Id;
			}
			return creditClaimRecordTypeId;
		}
		private set;
	}

	/**
	 * Called when a new Case is being inserted. Filter the cases and process them to update the billing account and credit dispute details
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			Set<Id> articleIds = new Set<Id>();
			Set<Id> billingAccountIds = new Set<Id>();
			List<Case> casesToProcess = new List<Case>();

			// loop through our records to figure out what actions need to be taken
			for (Case c : (List<Case>) records) {
				if (c.ArticleTest__c != null) {
					// StarTrack Case Automation: Consignment Billing Account (Decision node)
					articleIds.add(c.ArticleTest__c);
					casesToProcess.add(c);
				} else if (c.Related_Billing_Account__c != null) {
					// StarTrack Case Automation: Case Related Billing Account (Decision node)
					billingAccountIds.add(c.Related_Billing_Account__c);
					casesToProcess.add(c);
				}
			}

			if (!casesToProcess.isEmpty()) {
				// set the default values based
				setCaseBillingValues(casesToProcess, articleIds, billingAccountIds);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCaseCustomerModule.class.getName(), 'onBeforeInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * @Description : Filter the case article/related billing account changes on case and update the related billing account details
	 * @param : records list of cases which has been updated.
	 * @param : records list of cases which has been updated with old values.
	 * @return : null
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			Set<Id> articleIds = new Set<Id>();
			Set<Id> billingAccountIds = new Set<Id>();
			List<Case> casesToProcess = new List<Case>();

			List<Case> casesCustomerChanged = new List<Case>();
			Set<Id> caseCustomerIds = new Set<Id>();
			Set<Id> caseCustomerBillingAccountIds = new Set<Id>();

			// loop through our records to figure out what actions need to be taken
			for (Case c : (List<Case>) records) {
				Case oldCase = (Case) existingRecords.get(c.Id);
				Boolean isAccountChanged = oldCase.AccountId != c.AccountId;
				Boolean isRelatedBillingChanged = oldCase.Related_Billing_Account__c != c.Related_Billing_Account__c;

				if (c.ArticleTest__c != null && (c.ArticleTest__c != oldCase.ArticleTest__c || isAccountChanged || isRelatedBillingChanged)) {
					/**
					 * If article is not null and article or account or related billing account is changed
					 * use this information to update case related billing account and update case credit dispute details
					 */
					articleIds.add(c.ArticleTest__c);
					casesToProcess.add(c);
				} else if (c.Related_Billing_Account__c != null && (isRelatedBillingChanged || (isAccountChanged && c.AccountId == null))) {
					// StarTrack Case Automation: Case Related Billing Account (Decision node)
					/**
					 * If related billing account is not null and account is changed to null or related billing account is changed
					 * use this information to update case related billing account and update case credit dispute details
					 */

					billingAccountIds.add(c.Related_Billing_Account__c);
					casesToProcess.add(c);
				} else if (c.AccountId != null && isAccountChanged) {
					// StarTrack Case Automation: Case Customer Changed (Decision node)
					/**
					 * If account is not null and account is changed
					 * use this information to update case related billing account and update case credit dispute details
					 */
					casesCustomerChanged.add(c);
					caseCustomerIds.add(c.AccountId);
					if (c.Related_Billing_Account__c != null) {
						caseCustomerBillingAccountIds.add(c.Related_Billing_Account__c);
					}
				} else if ((c.AccountId == null || c.Related_Billing_Account__c == null) && (isAccountChanged || isRelatedBillingChanged)) {
					/**
					 * If account, related billing account and article is  null then clear related billing infomation
					 */
					if (c.Related_Billing_Account__c == null) {
						c.Billing_Account_Parent_Id__c = null;
						c.Billing_Number__c = null;
						c.Credit_Person_Code__c = null;
					}
					if (c.AccountId == null && c.Related_Billing_Account__c == null) {
						c.Account_Manager__c = null;
						c.Business_Solutions_Customer__c = false;
						c.Exclude_Notification_Automation__c = false;
						c.Exclude_Subscription_Automation__c = false;
					}
				}
			}

			// StarTrack Case Automation: Consignment Billing Account (Decision node)
			// StarTrack Case Automation: Case Related Billing Account (Decision node)
			if (!casesToProcess.isEmpty()) {
				// Synchronise the billing account details based on either the article or related billing account
				setCaseBillingValues(casesToProcess, articleIds, billingAccountIds);
			}

			// StarTrack Case Automation: Case Customer Changed (Decision node)
			// Update the billing account details if the account has changed values
			// This will only occur if the ACCOUNTID has changed value and there is no article on the Case
			if (!casesCustomerChanged.isEmpty()) {
				Map<Id, Account> accounts = caseCustomerIds.isEmpty()
					? new Map<Id, Account>()
					: AccountsSelector.newInstance().selectById(caseCustomerIds, new Set<Object>{ AccountsSelector.Options.WITH_OWNER });
				Map<Id, Billing_Account__c> billingAccounts = caseCustomerBillingAccountIds.isEmpty()
					? new Map<Id, Billing_Account__c>()
					: BillingAccountsSelector.newInstance().selectById(caseCustomerBillingAccountIds);

				for (Case c : casesCustomerChanged) {
					if (c.Related_Billing_Account__c == null || (c.Related_Billing_Account__c != null && billingAccounts.get(c.Related_Billing_Account__c).Organisation__c != c.AccountId)) {
						// The account on the case is not in sync with the billing account on the case
						// Since the account field was the changed field and it's the most uptodate, we proceed to reset the values on the case
						Account acc = accounts.get(c.AccountId);

						c.Related_Billing_Account__c = null;
						c.Billing_Account_Parent_Id__c = null;
						c.Business_Solutions_Customer__c = acc.Business_Solutions_Customer__c;
						c.Exclude_Notification_Automation__c = acc.Exclude_Notification_Automation__c;
						c.Exclude_Subscription_Automation__c = acc.Exclude_Subscription_Automation__c;
						// update the credit claim case details if case is credit claim type
						if (c.RecordTypeId == creditClaimRecordTypeId) {
							c.Account_Manager__c = 'Holding User'.equalsIgnoreCase(acc.Owner.FirstName + ' ' + acc.Owner.LastName)
								? acc.Sales_Director__c
								: acc.OwnerId;
							c.Billing_Number__c = null;
							c.CreditRepresentative__c = null;
							c.Credit_Person_Code__c = null;
						}
					}
				}
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCaseCustomerModule.class.getName(), 'onBeforeUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * @Description : update the record from article and related billing account details
	 * @param : casesToProcess filtered list of cases
	 * @param : articleIds list of article id.
	 * @param : billingAccountIds list of related billing account ids
	 * @return : null
	 */
	private void setCaseBillingValues(List<Case> casesToProcess, Set<Id> articleIds, Set<Id> billingAccountIds) {
		Map<Id, Article__c> articles = new Map<Id, Article__c>();
		if (!articleIds.isEmpty()) {
			// Grab the articles so we can set the default values on the case
			articles = ArticlesSelector.newInstance().selectById(articleIds);
			for (Article__c article : articles.values()) {
				if (article.Billing_Account__c != null) {
					billingAccountIds.add(article.Billing_Account__c);
				}
			}
		}

		// grab the billing accounts out so we can grab the default values from them
		Map<Id, Billing_Account__c> billingAccounts = billingAccountIds?.isEmpty()
			? new Map<Id, Billing_Account__c>()
			: BillingAccountsSelector.newInstance().selectById(billingAccountIds);
		if (!billingAccounts.isEmpty()) {
			for (Case c : casesToProcess) {
				Billing_Account__c billingAccount;
				/**
				 * Check if billing account is populated on case's article test
				 * update case billing account details withe article test's billing account detail
				 */
				if (c.ArticleTest__c != null && articles.get(c.ArticleTest__c)?.Billing_Account__c != null) {
					// StarTrack Case Automation: Consignment Billing Account (Decision node)
					billingAccount = billingAccounts.get(articles.get(c.ArticleTest__c).Billing_Account__c);
					c.Related_Billing_Account__c = billingAccount.Id;
				} else if (c.Related_Billing_Account__c != null) {
					// StarTrack Case Automation: Case Related Billing Account (Decision node)
					// since the article id is empty or there is no billing account attached then we try and utilise the default values on the Related Billing Account of the case
					billingAccount = billingAccounts.get(c.Related_Billing_Account__c);
				}

				// Update the case from related billing account
				if (billingAccount != null) {
					if (billingAccount.Organisation__c != null) {
						c.AccountId = c.Billing_Account_Parent_Id__c = billingAccount.Organisation__c;
					}
					c.Business_Solutions_Customer__c = billingAccount.BSC__c;
					c.Exclude_Notification_Automation__c = c.Exclude_Subscription_Automation__c = billingAccount.Calc_Exclude_Notification_Automation__c;

					// Check whether we also need to add the default values for credit claim disputes
					if (c.RecordTypeId == creditClaimRecordTypeId) {
						c.Account_Manager__c = billingAccount.StarTrack_Account_Manager__c;
						c.Billing_Number__c = billingAccount.LEGACY_ID__c;
						c.CreditRepresentative__c = billingAccount.Credit_Person__c;
						c.Credit_Person_Code__c = billingAccount.Credit_Person_Code__c;
					}
				}
			}
		}
	}
}