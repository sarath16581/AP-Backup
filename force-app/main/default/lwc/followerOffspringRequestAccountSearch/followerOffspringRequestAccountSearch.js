/**
 * @description Parent account search child component of FollowerOffspringRequestTEAMEditForm
 * User required to select one sub account/billing account to proceed
 * Support search on sub account and billing account
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
import {api, LightningElement, track} from 'lwc';
import getFollowers from '@salesforce/apex/FollowerOffspringRequestController.getFollowers';
import BILLING_ACCOUNT_NUMBER from "@salesforce/schema/Billing_Account__c.LEGACY_ID__c";

export default class FollowerOffspringRequestAccountSearch extends LightningElement {
	@api leaderId;
	@api isBillingAccount;
	@api defaultSelectedAccount;

	selectedAccount;
	followerSubAccounts = [];
	followerBillingAccounts = [];

	@track matchedFollowerSubAccounts = [];
	@track matchedFollowerBillingAccounts = [];

	searchValue;
	noResults = 'No results';

	/**
	 * In this connectedCallBack(), Retrieving related follower accounts and loading default selection if sub account is passed from list view
	 */
	connectedCallback() {
		// Load follower sub accounts and follower billing accounts
		getFollowers({leaderAccountId: this.leaderId, isBillingAccount: this.isBillingAccount}).then(results => {
			this.followerSubAccounts = results.subAccountFollowers?.map(item => {
				return {...item};
			});
			this.matchedFollowerSubAccounts = this.followerSubAccounts;
			this.followerBillingAccounts = results.billingAccountFollowers?.map(item => {
				return {...item};
			});
			this.matchedFollowerBillingAccounts = this.followerBillingAccounts;

			// load default selection
			if (this.defaultSelectedAccount) {
				this.matchedFollowerSubAccounts.concat(this.matchedFollowerBillingAccounts).forEach(acc => {
					if (acc.Id === this.defaultSelectedAccount) {
						acc.isSelected = true;
						this.selectedAccount = acc;
					} else {
						acc.isDisabled = true;
					}
				});
			}
		});
	}

	get selectedAccountPill() {
		const iconName = this.selectedAccount[BILLING_ACCOUNT_NUMBER.fieldApiName] ? 'custom:custom99' : 'standard:custom';
		return this.selectedAccount ? [{ type: 'icon', label: this.selectedAccount.Name, iconName: iconName}] : [];
	}

	get showExistingBillingAccount() {
		return this.isBillingAccount === 'true';
	}

	get hasMatchedSubAccounts() {
		return this.matchedFollowerSubAccounts.length > 0;
	}

	get hasMatchedBillingAccounts() {
		return this.matchedFollowerBillingAccounts.length > 0;
	}

	/**
	 * Filter matched follower accounts when user input search term
	 */
	handleAccountSearch(event) {
		const value = event.target.value;
		this.searchValue = value;
		this.matchedFollowerSubAccounts = this.followerSubAccounts.filter(acc => {
			return acc.Name?.toLowerCase().includes(value.toLowerCase());
		});
		this.matchedFollowerBillingAccounts = this.followerBillingAccounts.filter(acc => {
			return acc.Name?.toLowerCase().includes(value.toLowerCase()) || acc.LEGACY_ID__c?.toLowerCase().includes(value.toLowerCase());
		});
	}

	/**
	 * Set selected account and mark others disabled when user select one option from either sub accounts or billing accounts section
	 */
	handleSelectAccount(event) {
		if (event.target.name) {
			this.matchedFollowerSubAccounts.concat(this.matchedFollowerBillingAccounts).forEach(acc => {
				if (acc.Id === event.target.name) {
					acc.isSelected = event.target.checked;
					if (event.target.checked) {
						this.selectedAccount = acc;
						this.dispatchEvent(new CustomEvent('followerselected', {detail: acc}));
					} else {
						this.selectedAccount = null;
					}
				} else {
					acc.isDisabled = event.target.checked;
				}
			});
		}
	}

	/**
	 * Clear selection - mark all options enabled
	 */
	handleClearSelectedAccount() {
		const event = {target: {name: this.selectedAccount.Id, checked: false}};
		this.handleSelectAccount(event);
	}

	/**
	 * Exposed validating method that validates selection. Report validation errors, if any
	 */
	@api validate() {
		if (!this.selectedAccount) {
			const searchInput = this.template.querySelector("[data-name='search-input']");
			searchInput.setCustomValidity("Selection is required.");
			return searchInput.reportValidity();
		}
		return true;
	}
}