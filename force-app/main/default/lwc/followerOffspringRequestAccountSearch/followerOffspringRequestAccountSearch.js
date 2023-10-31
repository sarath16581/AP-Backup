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
import getFollowerSubAccounts from '@salesforce/apex/FollowerOffspringRequestController.getFollowerSubAccounts';
import getFollowerBillingAccounts from '@salesforce/apex/FollowerOffspringRequestController.getFollowerBillingAccounts';

export default class FollowerOffspringRequestAccountSearch extends LightningElement {
	@api leaderId;
	@api isBillingAccount;
	followerSubAccounts = [];
	followerBillingAccounts = [];

	@track matchedFollowerSubAccounts = [];
	@track matchedFollowerBillingAccounts = [];
	selectedAccount;
	searchValue;
	noResults = 'No results';

	get followerAccounts() {
		return this.followerSubAccounts.concat(this.followerBillingAccounts);
	}

	connectedCallback() {
		getFollowerSubAccounts({leaderAccountId: this.leaderId, isBillingAccount: this.isBillingAccount}).then(results => {
			// this.followerSubAccounts = results;
			this.followerSubAccounts = results.map(item => {
				return {...item};
			});
			this.matchedFollowerSubAccounts = this.followerSubAccounts;
		});
		if (this.isBillingAccount === 'true') {
			getFollowerBillingAccounts({leaderAccountId: this.leaderId}).then(results => {
				this.followerBillingAccounts = results.map(item => {
					// item.url = '/'+item.Id;
					return {...item};
				});
				this.matchedFollowerBillingAccounts = this.followerBillingAccounts;
			});
		}
	}

	get selectedAccountPill() {
		const iconName = this.selectedAccount.LEGACY_ID__c ? 'custom:custom99' : 'standard:custom';
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

	handleSelectAccount(event) {
		// const input = event.target.dataset.id;
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

	handleClearSelectedAccount() {
		const event = {target: {name: this.selectedAccount.Id, checked: false}};
		this.handleSelectAccount(event);
	}

	@api validate() {
		if (!this.selectedAccount) {
			const searchInput = this.template.querySelector("[data-name='search-input']");
			searchInput.setCustomValidity("Selection is required.");
			return searchInput.reportValidity();
		}
		return true;
	}
}