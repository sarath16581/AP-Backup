/**
 * @description Contact assignments screen for Account managers to facilitate campaign feedback survey
 * @author Mathew Jose
 * @date 2021-12-21
 * @group
 * @changelog
 * 2021-12-21 - Mathew Jose - Created.
 * 2022-05-16 - Prerna Rahangdale - Modified to only bring Active Contacts.
 */
import { LightningElement, track, api , wire} from 'lwc';
import loadData from '@salesforce/apex/CampaignAssignmentController.getCampaignContactAssignments';
import updateData from '@salesforce/apex/CampaignAssignmentController.updateCampaignContactAssignments';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CampaignContactAssignment extends LightningElement {
	//Id of the current record.
	@api recordId;

	//Store the data required for the datatable
	@track data;

	//Capture and show errors
	@track error;

	//Used to refresh apex after save operations
	@track wiredData;

	//Columns to be shown in the datatable.
	@track columns;

	//Used to track changes to rows in the datatable.
	@track draftValues = [];

	//Track saved data to facilitate cancel button
	lastSavedData = [];

	//To hide and show spinner.
	isSpinning = true;

	connectedCallback() {
		this.columns = [
			//{ label: 'Organisation', fieldName: 'accountName', editable: false },
			{
				label: 'Organisation',
				fieldName: 'accountUrl',
				type: 'url',
				typeAttributes:  {label: { fieldName: 'accountName' },
								target: '_blank'},
				sortable: true
			},
			{
				label: 'Contact', fieldName: 'campaignContactId', type: 'lookup', typeAttributes: {
					placeholder: 'Select Contact',
					uniqueId: { fieldName: 'assignmentId' }, //pass Id of current record to lookup for context
					object: "Contact",
					icon: "standard:contact",
					label: "Contact",
					displayFields: "FirstName, LastName",
					displayFormat: "FirstName LastName",
					filters: {fieldName: 'campaignContactFilter'},
					valueId: { fieldName: 'campaignContactId' },
					readOnly: { fieldName: 'campaignContactReadonly' },
					fieldsToSearch: "Name"
				}
			},

			{
				label: 'View Campaign Member',
				fieldName: 'campaignMemberUrl',
				type: 'url',
				typeAttributes: {label: 'View Campaign Member',
								target: '_blank'},
				sortable: true
			},

			{ label: 'Current Status', fieldName: 'campaignMemberStatus', editable: false },
			{ label: 'Description', fieldName: 'campaignContactDescription', editable: false, type: 'text', wrapText: true , initialWidth: 680}

		];

	}

	@wire(loadData, { campaignId: '$recordId' })
	wiredCampaignData(result) {
		this.wiredData = result;
		if (result.data) {
			this.data = this.pushColumnValue(result.data);
			//keep the last retrieved data
			this.lastSavedData = JSON.parse(JSON.stringify(this.data));
			this.error = undefined;
			this.isSpinning = false;
		} else if (result.error) {
			console.log('Error'+result.error.body.message);
		   //this.error = result.error;
			this.error = result.error.body.message;
			this.data = undefined;
			this.isSpinning = false;
		}
	}

	//Setting the specific column values which require logical calculation.
	pushColumnValue(items) {
		return items.map(item => {
			//generate a filter map with the filters to be used for contact lookup for each row.
			//Default the Id if the existing rows already have contact, and bring only Active contacts.
			let filterMap = item.campaignContactId ? {Id : `${item.campaignContactId}`, AccountId : `${item.accountId}`} : {AccountId : `${item.accountId}` ,Status__c : `Active`};
			const col = {...item,
							accountUrl: item.accountId ? `/${item.accountId }`: "",
							//campaignContactReadonly: item.campaignMemberStatus && item.campaignMemberStatus != 'Sent' ? true : false,
							//Lock contact selection as long as there is a campaign member associated with the contact.
							campaignContactReadonly: !!(item.campaignMemberStatus),
							//campaignContactFilter: `AccountId = '${item.accountId }'`,
							campaignContactFilter: filterMap,
							campaignMemberUrl: item.campaignMemberId ? `/${item.campaignMemberId}`: ""
						};
			return col;
		});

	};

	//Handles the selection of the look up values. This will update the data values and draft values.
	handleSelection(event) {
		event.stopPropagation();
		let dataRecieved = event.detail.data;
		let updatedItem = { assignmentId: dataRecieved.key, campaignContactId: dataRecieved.selectedId };
		this.updateDraftValues(updatedItem);
		this.updateDataValues(updatedItem);
	}

	//Update data values on lookup selection.
	updateDataValues(updateItem) {

		let copyData = JSON.parse(JSON.stringify(this.data));
		copyData.forEach(item => {
			if (item.assignmentId === updateItem.assignmentId) {
				for (let field in updateItem) {
					if(field != 'assignmentId' ){
						item[field] = updateItem[field] ? updateItem[field] : "";
					}
				}
				let filterMap = item.campaignContactId ? {Id : `${item.campaignContactId}`, AccountId : `${item.accountId}`} : {AccountId : `${item.accountId}`};
				console.log('filterMap:::'+filterMap);
				item.campaignContactFilter = filterMap;
				/*if(!item.campaignContactId){
					console.log('Update filter here');
					item.campaignContactFilter = {AccountId : `${item.accountId}`};
				}*/
			}
		});
		//write changes back to original data
		this.data = [...copyData];
	}

	//Update the draft values which will eventually be saved.
	updateDraftValues(updateItem) {
		let draftValueChanged = false;
		let copyDraftValues = [...this.draftValues];
		//store changed value to do operations
		//on save. This will enable inline editing &
		//show standard cancel & save button
		copyDraftValues.forEach(item => {
			if (item.assignmentId === updateItem.assignmentId) {
				for (let field in updateItem) {
					if(field != 'assignmentId'){
						//item[field] = updateItem[field];
						item[field] = updateItem[field] ? updateItem[field] : "";
					}
				}
				draftValueChanged = true;
			}
		});

		if (draftValueChanged) {
			this.draftValues = [...copyDraftValues];
		} else {
			this.draftValues = [...copyDraftValues, updateItem];
			console.log('Draft Values Final:'+this.draftValues);
		}
	}

	handleSave(event) {
		console.log('Updated items', this.draftValues);
		//save last saved copy
		this.lastSavedData = JSON.parse(JSON.stringify(this.data));
		//Start Spinner
		this.isSpinning = true;
		// Calling the imperative Apex method with the JSON
		// object as parameter.
		updateData({ assignments : this.draftValues})
			.then((result) => {
				console.log('Result'+result);
				this.message = result;
				this.error = undefined;
				//once data is updated, dispatch a toast
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: 'Campaign Contact Assignments Updated',
						variant: 'success'
					})
				);
				// Clear all draft values
				this.draftValues = [];
				// Refresh data in the datatable with below command
				//as the datatable is being loaded with wired function
				return refreshApex(this.wiredData);
			})
			.catch((error) => {
				this.message = undefined;
				//this.error = error;
				this.error = error.body.message;
				this.isSpinning = false;
			});

	}

	handleCancel(event) {
		//remove draftValues & revert data changes
		this.data = JSON.parse(JSON.stringify(this.lastSavedData));
		this.draftValues = [];
	}


}