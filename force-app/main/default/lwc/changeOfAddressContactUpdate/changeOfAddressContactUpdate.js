import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import fetchAllContactsFromDB from '@salesforce/apex/ChangeOfAddressController.fetchAllContactsFromDB';
import { debounce } from 'c/utils'
const SEARCHABLE_FIELDS = ['Name', 'Email', 'MobilePhone','mailingAddress','physicalAddress'];
const columns = [
	{ label: 'Name', fieldName: 'recordUrl', type: 'url',
		typeAttributes: {
			label: { fieldName: 'Name' },
			target: '_blank'
		}
	},
	{ label: 'Phone', fieldName: 'MobilePhone', type: 'phone'},
	{ label: 'Email', fieldName: 'Email', type: 'email'},
	{ label: 'Mailing Address', fieldName: 'mailingAddress', type: 'text'},
	{ label: 'Physical Address', fieldName: 'physicalAddress', type: 'text'},
	{ label: 'Has Online Credential', fieldName: 'Has_Online_Credential__c', type: 'Boolean'},
	{ label: 'Contact Maintained By', fieldName: 'Record_Maintainer__c', type: 'text'}
];


const ROW_LIMIT = 50;

export default class changeOfAddressContactUpdate extends NavigationMixin( LightningElement ) {
	columns = columns;
	data = [];
	error;
	errorMoreThan50;
	// variable to store the required details from container component
	@api orgRecord;
	@api orgId;
	@api isBillingAddressChanged;
	@api isPhysicalAddressChanged;
	@api newBillingAddress;
	@api newPhysicalAddress;
	@api cmpCalledFrom;
	// offSetCount to send to apex to get the subsequent result. 0 in offSetCount signifies for the initial load of records on component load.
	offSetCount = 0;
	loadMoreStatus;
	targetDatatable; // capture the loadmore event to fetch data and stop infinite loading
	initialRecords;
	searchKey;
	enableInfinteLoading=true;
	enableInfinteLoadingSelected=true;
	fulldataset = [];
	selecteddata =[];
	offSetCountSelected =0;
	searchedRecords = [];
	fulldataselected=[];

	connectedCallback() {
		//remove this when the container component pass the data to this component start
		this.isBillingAddressChanged = true;
		this.isPhysicalAddressChanged = true;
		//remove this when the container component pass the data to this component end
		this.offSetCount = ROW_LIMIT;
		this.offSetCountSelected = ROW_LIMIT;
		this.getAllRecords();
	}

	//get all the contacts
	getAllRecords() {
		fetchAllContactsFromDB({orgId: this.orgId})
			.then(result => {
				// Returned result if from sobject and can't be extended so objectifying the result to make it extensible
				var conlist = result.conlist;
				conlist = JSON.parse(JSON.stringify(conlist));
				conlist.forEach(record => {
					record.Id=record.contactRecord.Id;
					record.Name = record.contactRecord.Name;
					record.MobilePhone=record.contactRecord.MobilePhone;
					record.Email=record.contactRecord.Email;
					record.Has_Online_Credential__c=record.contactRecord.Has_Online_Credential__c;
					record.Record_Maintainer__c=record.contactRecord.Record_Maintainer__c;
				});
				this.fulldataset = [...this.fulldataset, ...conlist];
				this.setDatatableRecords();
			})
			.catch(error => {
				this.error = error;
				console.log('error : ' + JSON.stringify(this.error));
			});
	}

	// Event to handle onloadmore on lightning datatable markup
	handleLoadMore(event) {
		if (this.fulldataset.length < this.offSetCount) {
			this.enableInfinteLoading = false;
		} else {
			this.offSetCount = this.offSetCount + ROW_LIMIT;
			this.setDatatableRecords();
		}
	}

	

	handleRowSelection(event){
		var selectedRows=event.detail.selectedRows;
		var selectedaction = event.detail.config.action;
		switch (event.detail.config.action) {
			case 'selectAllRows':
				if (this.searchKey) {
					this.fulldataselected = this.fulldataselected.concat(this.searchedRecords);
				}else{
					this.fulldataselected = this.fulldataselected.concat(this.fulldataset);
				}
				break;
			case 'deselectAllRows':
				this.fulldataselected = [];
				this.selecteddata = [];
				break;
			case 'rowSelect':
				this.fulldataselected.push(...this.fulldataset.filter(c => c.Id === event.detail.config.value));
				break;
			case 'rowDeselect':
				const deselectedIndex = this.fulldataselected.findIndex(c => c.Id === event.detail.config.value);
				if (deselectedIndex !== -1) {
					this.fulldataselected.splice(deselectedIndex, 1);
				}
				break;
			default:
				break;
		}
		this.handleLoadMoreselected();

	}
	handleLoadMoreselected(){
		if(this.fulldataselected.length < this.offSetCountSelected){
			this.enableInfinteLoadingSelected = false;
		}else{
			this.enableInfinteLoadingSelected = true;
			this.offSetCountSelected = this.offSetCountSelected + ROW_LIMIT;	
		}
		this.selecteddata = this.fulldataselected.slice(0, this.offSetCountSelected);
	}
	
	setDatatableRecords(){
		this.data = this.fulldataset.slice(0, this.offSetCount);
		this.initialRecords = this.data;
	}

	handleSearchText(event){
		this.searchKey = event.target.value.toLowerCase();

		if(this.searchKey.length>=3){
			this.debouncedSearchHandler(this.searchKey);
		}
		if(!this.searchKey){
			this.data = this.initialRecords;
			this.error = '';
			this.errorMoreThan50='';
		}
	}
	debouncedSearchHandler = debounce(this.handleSearch, 200)
	handleSearch() {
		const searchKey = this.searchKey;

		if (searchKey) {
			this.enableInfinteLoading = false;
			if (this.fulldataset) {
				let searchRecords = [];
				searchRecords = this.fulldataset.filter(item => {
					for (const field of SEARCHABLE_FIELDS) {
						const fieldValueStr = item[field]?.toLowerCase();
						if (fieldValueStr?.includes(this.searchKey.toLowerCase())) {
							return true;
						}
					}
					return false;
				});
				this.searchedRecords = searchRecords;
				this.data = searchRecords;
				if(this.data.length>50){
					this.errorMoreThan50 = 'There are more than 50 records with this search term. Please refine the search';
					this.data = [];
				}else{
					this.errorMoreThan50 = '';
				}
			}
		}else {
			this.data = this.initialRecords;
			this.enableInfinteLoading = true;
		}
	}

	handleCancel(){
		const cancelEvent = new CustomEvent("handlecancel", {
			detail:{
				backScreen: this.cmpCalledFrom,
				cameFrom:'contactselection'
			}
		});
		// dispatch the event
		this.dispatchEvent(cancelEvent);
	}

	handleBack(){
		const backEvent = new CustomEvent("handleback", {
			detail:{
				backScreen: this.cmpCalledFrom,
				cameFrom:'contactselection'
			}
		});
		// dispatch the event
		this.dispatchEvent(backEvent);
	}

	handleNext(){
		const nextEvent = new CustomEvent("handlenext", {
			detail:{
				backScreen: this.cmpCalledFrom,
				cameFrom:'contactselection',
				selectedcontacts:this.fulldataselected
			}
		});
		// dispatch the event
		this.dispatchEvent(nextEvent);
	}
}