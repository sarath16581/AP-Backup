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
import getColumns from '@salesforce/apex/ABNChangeController.retrieveColumns';
import cloneContacts from '@salesforce/apex/ABNChangeController.cloneContacts';
import LightningConfirm from 'lightning/confirm';
import LightningAlert from 'lightning/alert';
import { refreshApex } from "@salesforce/apex";
import { CloseActionScreenEvent } from 'lightning/actions';
import LABEL_CONTACT_CLONING from "@salesforce/label/c.ABNChangeContactCloningLabel";
import LABEL_CONTACT_CLONING_CONFIRMATION from "@salesforce/label/c.ABNChangeContactCloningConfirmation";
import LABEL_CONTACT_LIMIT_INFO from "@salesforce/label/c.ABNChangeContactCloningLimitInfo";
import LABEL_CONTACT_NO_CONTACTS_ERROR from "@salesforce/label/c.ABNChangeContactCloningNoContactsError";
import LABEL_CONTACT_INFO from "@salesforce/label/c.ABNChangeContactCloningInfo";

const SEARCHABLE_FIELDS = ['Name', 'Title', 'Email', 'Phone', 'Has_Online_Credential'];
const ROW_LIMIT = 50;
const CLONE_LIMIT = 100;
export default class AbnChangeContactCloningWrapper extends LightningElement {
	@api recordId;
	atRiskBusiness;
	errorMessage;
	isLoading = true;
	_wiredContacts;
	contacts = [];
	searchTerm;
	_filteredContacts;
	columns;
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

	/**
	 *  Retrieve deduplicated contacts and related At Risk Business from server controller
	 *  Retrieve table columns from server controller
	 */
	@wire(getDeduplicatedContactsAndBaR, {businessAtRiskId: "$recordId"})
	wiredData(result) {
		const {data, error} = result;
		this._wiredContacts = result;
		if (error) {
			this.errorMessage = error;
			this.isLoading = false;
			return;
		}
		if (data) {
			if (data.contacts.length > 0) {
				// map contact name url
				let nameUrl;
				this.contacts = data.contacts.map(row => {
					nameUrl = `/${row.Id}`;
					return {...row , nameUrl}
				});
				// Retrieve columns
				getColumns({objectName: 'Contact', fieldSetName: 'ABNChangeContactColumn'}).then(c => {
					this.columns = c.map(item => {
						return {...item};
					});
					// insert name at index 0
					this.columns.splice(0, 0, { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}});
					console.log(JSON.stringify(this.columns));
				}).catch(columnError => {
					console.error(columnError);
					LightningAlert.open({
						message: 'Something went wrong while retrieving the columns. Please try again',
						theme: 'error',
						label: LABEL_CONTACT_CLONING
					});
				});

				this.atRiskBusiness = data.businessAtRisk;
				this.errorMessage = null;
			} else {
				this.errorMessage = LABEL_CONTACT_NO_CONTACTS_ERROR;
			}
			this.isLoading = false;
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

	/**
	 * Increment row offset when user scroll to the bottom of the table for infinite loading
	 */
	handleLoadData(event) {
		// Disable infinite loading if filtered contacts have been loaded fully
		if (this.filteredContacts.length < this.rowOffset) {
			event.target.enableInfiniteLoading = false;
		} else {
			this.rowOffset = this.rowOffset + ROW_LIMIT;
			this._filteredContacts = null;
		}
	}

	/**
	 * Update selected rows when user select table rows
	 * Support select all and deselect all
	 */
	handleSelectedRows(event) {
		switch (event.detail.config.action) {
			case 'selectAllRows': {
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
			}
			case 'deselectAllRows': {
				this.selectedRows = [];
				break;
			}
			case 'rowSelect': {
				if (this.selectedRows.length < CLONE_LIMIT) {
					this.selectedRows.push(...this.contacts.filter(c => c.Id === event.detail.config.value));
				}
				break;
			}
			case 'rowDeselect': {
				const deselectedIndex = this.selectedRows.findIndex(c => c.Id === event.detail.config.value);
				if (deselectedIndex !== -1) {
					this.selectedRows.splice(deselectedIndex, 1);
				}
				break;
			}
			default: {
				break;
			}
		}
	}

	/**
	 * Count of selected contacts
	 */
	get selectedCountText() {
		return this.selectedRows.length + ' selected';
	}

	/**
	 * Count of filtered contacts
	 */
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

	get limitInfo() {
		return LABEL_CONTACT_LIMIT_INFO;
	}

	get headerInfo() {
		return LABEL_CONTACT_INFO;
	}

	/**
	 * Call apex controller to clone selected contacts to new organisation (related organisation)
	 * Show error if any of contacts are failed.
	 */
	async handleClone() {
		const confirmed = await LightningConfirm.open({
			message: this.selectedRows.length + ' are selected under ' + this.atRiskBusiness.Legal_Entity_Name__r.Name + ' to be cloned under ' + this.atRiskBusiness.Related_Organisation__r.Name + '. Do you want to proceed?',
			variant: 'headerless',
			label: 'Contact Cloning'
		});
		if (confirmed) {
			this.isLoading = true;
			this.selectedIds = this.selectedRows.map(e => e.Id);
			cloneContacts({newOrganisationId: this.atRiskBusiness.Related_Organisation__c, oldContactIds: this.selectedIds}).then(() => {
				LightningAlert.open({
					message: LABEL_CONTACT_CLONING_CONFIRMATION,
					theme: 'success',
					label: LABEL_CONTACT_CLONING
				});
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