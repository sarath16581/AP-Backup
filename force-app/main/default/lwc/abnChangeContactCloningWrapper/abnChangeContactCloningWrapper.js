/**
 * @description Contact cloning screen action component. Triggered by Contact Cloning quick action button in At Risk Business
 * This component shows de-duplicated contacts from old organisation (legal entity) and support cloning to new organisation (related organisation).
 * @author Harry Wang
 * @date 2024-05-17
 * @group Controller
 * @changelog
 * 2024-05-17 - Harry Wang - Created
 */
import {api, LightningElement, track, wire} from 'lwc';
import getDeduplicatedContactsAndBaR from '@salesforce/apex/ABNChangeController.getDeduplicatedContactsAndBaR';
import cloneContacts from '@salesforce/apex/ABNChangeController.cloneContacts';
import LightningConfirm from 'lightning/confirm';
import LightningAlert from 'lightning/alert';
import { refreshApex } from "@salesforce/apex";
import { CloseActionScreenEvent } from 'lightning/actions';
import LABEL_CONTACT_CLONING from "@salesforce/label/c.ABNChangeContactCloningLabel";
import LABEL_CONTACT_CLONING_ERROR from "@salesforce/label/c.ABNChangeContactCloningErrorMessage";

const columns = [
	{ label: 'Name', fieldName: 'Name'},
	{ label: 'Job Title', fieldName: 'Title'},
	{ label: 'Email', fieldName: 'Email'},
	{ label: 'Phone', fieldName: 'Phone', type: 'phone'},
	{ label: 'Has Online Credential', fieldName: 'Has_Online_Credential__c', type: 'boolean'}
];

const SEARCHABLE_FIELDS = ['Name', 'Title', 'Email', 'Phone', 'Has_Online_Credential'];
const ROW_LIMIT = 50;
const CLONE_LIMIT = 200;
export default class AbnChangeContactCloningWrapper extends LightningElement {
	@api recordId;
	atRiskBusiness;
	errorMessage;
	isLoading = true;
	_wiredContacts;
	contacts = [];
	searchTerm;
	_filteredContacts;
	columns = columns;
	rowOffset = ROW_LIMIT;
	selectedIds = []; // use to render selection
	@track selectedRows = []; // selected contacts data

	/**
	 *  Max select limit align with the global clone limit
	 *  When user has put search term, the select limit needs to be calculated to not exceeding the global clone limit
	 */
	get selectLimit() {
		const filteredIdSet = this._filteredContacts?.map(c => c.Id);
		const filteredSelectedRows = this.selectedRows.filter(c => filteredIdSet?.includes(c.Id));
		return CLONE_LIMIT - this.selectedRows.length + filteredSelectedRows.length;
	}

	@wire(getDeduplicatedContactsAndBaR, {businessAtRiskId: "$recordId"})
	wiredData(result) {
		const {data, error} = result;
		this._wiredContacts = result;
		if (error) {
			console.error(error);
			this.errorMessage = error;
			return;
		}
		if (data?.contacts.length > 0) {
			this.contacts = data.contacts;
			this.atRiskBusiness = data.businessAtRisk;
			this.isLoading = false;
			this.errorMessage = null;
		} else if (data?.length === 0) {
			//TODO: Custom Labeling
			this.errorMessage = 'No active contacts available for cloning. Please verify the contacts under the old organisation if at least 1 contact that is Active and maintained by Account Manager.';
		}
	}

	get filteredContacts() {
		if (this._filteredContacts) {
			return this._filteredContacts;
		}

		if (!this._filteredContacts && this.contacts?.length > 0) {
			this._filteredContacts = this.contacts;
		}
		// filter records based on the search term
		if (this.searchTerm) {
			this._filteredContacts = this._filteredContacts.filter(item => {
				for (const field of SEARCHABLE_FIELDS) {
					const fieldValueStr = item[field]?.toLowerCase();
					if (fieldValueStr?.includes(this.searchTerm.toLowerCase())) {
						return true;
					}
				}
				return false;
			});
		}

		// filter records based on the row offset
		if (this._filteredContacts) {
			this._filteredContacts = this._filteredContacts.slice(0, this.rowOffset);
		}

		// this.selectedIds need to be re-assigned to get the selected-rows refreshed - push will not work
		this.selectedIds = this.selectedRows.map(c => c.Id);

		return this._filteredContacts;
	}

	/**
	 * Update filteredContacts based on search term
	 */
	handleSearchChange(event) {
		this.searchTerm = event.target.value;
		// invalidate the state/cache, so it can be rebuilt based on the search term
		this._filteredContacts = null;
		// Reset rowOffset
		this.rowOffset = ROW_LIMIT;
		const datatable = this.template.querySelector("c-abn-change-contact-list");
		datatable.enableInfiniteLoading = true;
		datatable.scrollToTop();
	}

	handleLoadData(event) {
		// event.target.enableInfiniteLoading = true;
		// Disable infinite loading if filtered contacts have been loaded fully
		if (this.filteredContacts.length < this.rowOffset) {
			event.target.enableInfiniteLoading = false;
		} else {
			this.rowOffset = this.rowOffset + ROW_LIMIT;
			this._filteredContacts = null;
		}
	}

	handleSelectedRows(event) {
		switch (event.detail.config.action) {
			case 'selectAllRows':
				// filter records based on the search term
				if (this.searchTerm) {
					const contactsCopy = this.contacts.filter(item => {
						for (const field of SEARCHABLE_FIELDS) {
							const fieldValueStr = item[field]?.toLowerCase();
							if (fieldValueStr?.includes(this.searchTerm.toLowerCase())) {
								return true;
							}
						}
						return false;
					});
					this.selectedRows = contactsCopy.slice(0, this.selectLimit);
				} else {
					this.selectedRows = this.contacts.slice(0, this.selectLimit);
				}
				break;
			case 'deselectAllRows':
				this.selectedRows = [];
				break;
			case 'rowSelect':
				if (this.selectedRows.length < CLONE_LIMIT) {
					this.selectedRows.push(...this.contacts.filter(c => c.Id === event.detail.config.value));
				}
				break;
			case 'rowDeselect':
				const deselectedIndex = this.selectedRows.findIndex(c => c.Id === event.detail.config.value);
				if (deselectedIndex !== -1) {
					this.selectedRows.splice(deselectedIndex, 1);
				}
				break;
			default:
				break;
		}
	}

	get selectedCountText() {
		return this.selectedRows.length + ' selected';
	}

	get searchCountText() {
		let filteredCount;
		if (this.searchTerm) {
			filteredCount = this.contacts.filter(item => {
				for (const field of SEARCHABLE_FIELDS) {
					const fieldValueStr = item[field]?.toLowerCase();
					if (fieldValueStr?.includes(this.searchTerm.toLowerCase())) {
						return true;
					}
				}
				return false;
			}).length;
		} else {
			filteredCount = this.contacts.length;
		}
		return filteredCount + ' of ' + this.contacts.length;
	}

	get hasReachSelectLimit() {
		return this.contacts?.length > this.selectLimit;
	}

	get isActionDisabled() {
		return this.selectedRows.length === 0;
	}

	async handleClone() {
		const confirmed = await LightningConfirm.open({
			message: 'By clicking "OK" ' + this.selectedRows.length + ' selected contacts will be cloned.',
			variant: 'headerless',
			label: 'Contact Cloning'
		});
		if (confirmed) {
			this.isLoading = true;
			this.selectedIds = this.selectedRows.map(e => e.Id);
			cloneContacts({newOrganisationId: this.atRiskBusiness.Related_Organisation__c, oldContactIds: this.selectedIds}).then((result) => {
				if (result.length === this.selectedIds.length) {
					LightningAlert.open({
						message: result.length + ' Contacts cloned successfully under ' + this.atRiskBusiness.Related_Organisation__r.Name + '.',
						theme: 'success',
						label: LABEL_CONTACT_CLONING
					});
				} else if (result.length < this.selectedIds.length) {
					LightningAlert.open({
						message: 'Error occurred while cloning contacts, only ' + result.length + ' out of ' + this.contacts.length + ' contacts cloned successfully. '
							+ LABEL_CONTACT_CLONING_ERROR,
						theme: 'error',
						label: LABEL_CONTACT_CLONING
					});
				}
			}).catch((error) => {
				const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
				if (errorMessages) {
					LightningAlert.open({
						message: errorMessages,
						theme: 'error',
						label: LABEL_CONTACT_CLONING
					});
				}
			}).finally(()=> {
				// Refresh wired contacts and close the modal
				refreshApex(this._wiredContacts).then(() => {
					this.isLoading = false;
					this.dispatchEvent(new CloseActionScreenEvent());
				});
			});
		}
	}
}