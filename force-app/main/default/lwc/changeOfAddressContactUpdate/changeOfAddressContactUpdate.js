import { LightningElement, api,track,wire } from 'lwc';
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
	//errorMoreThan50;
	// variable to store the required details from container component
	@api orgRecord;
	@api accountId;
	@api currentBillingAddress;
	@api currentPhysicalAddress;
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
	@track fulldataselected=[];
	isLoading=true;
	@track selectedRowIds = [];

	get billingAddressDisplay() {
		return this.newBillingAddress?.address || '';
	}
	get physicalAddressDisplay() {
		return this.newPhysicalAddress?.address || '';
	}
	connectedCallback() {
		this.isLoading = true;
		console.log('in cc');
		this.offSetCount = ROW_LIMIT;
		this.offSetCountSelected = ROW_LIMIT;
		//this.getAllRecords();
	}

	//get all the contacts
	@wire(fetchAllContactsFromDB, {orgId: '$accountId'})
	wiredContacts({ error, data }) {
		if (data) {
			//this.isLoading = true;
			this.offSetCount = ROW_LIMIT;
			this.offSetCountSelected = ROW_LIMIT;
			console.log('came in here');
			let conlist = JSON.parse(JSON.stringify(data.conlist));
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
			this.isLoading = false;
		}
		else if(error){
			this.error = error;
			console.log('error : ' + JSON.stringify(this.error));
			this.isLoading = false;	
		}
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
			//this.errorMoreThan50='';
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
				/*if(this.data.length>50){
					this.errorMoreThan50 = 'There are more than 50 records with this search term. Please refine the search';
					this.data = [];
				}else{
					this.errorMoreThan50 = '';
				}*/
			}
		}else {
			this.data = this.initialRecords;
			this.enableInfinteLoading = true;
		}
	}
	@api
    async getUserSelectedData() {
		console.log('@@@fulldata' +this.fulldataselected);
		if(this.fulldataselected) {
			this.selectedRowIds = this.fulldataselected.map(row => row.Id);
			//this.selecteddata = this.fulldataselected.slice(0, this.offSetCountSelected);
		}
		return this.fulldataselected;	
	}
	@api
	async restoreState(data) {
		this.fulldataselected=data;
		this.selectedRowIds = this.fulldataselected.map(row => row.Id);
		this.selecteddata = this.fulldataselected.slice(0, this.offSetCountSelected);
        //console.log('@@@data' +JSON.stringify(this.selectedRowIds));
    }
	disconnectedCallback() {
		console.log('in Disconnect')
	}
}