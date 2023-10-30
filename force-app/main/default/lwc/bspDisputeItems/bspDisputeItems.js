import { LightningElement, api, track } from 'lwc';

import {checkAllValidity, checkCustomValidity} from 'c/bspCommonJS';

export default class bspDisputeItems extends LightningElement {
	@track disputeItemList = [];
	@api accountHeldWith = '';

	
	connectedCallback() {
		this.addRow();
	}	

	addRow() {
		const newDisputeItem = {
			Id: Date.now().toString(36) + Math.random().toString(36).substring(2),
			Invoice_Number__c: '',
			Transaction_ID__c: '',
			Connote__c: '',
			Amount_Claimed__c: null,
			Amount__c: null
		};
		this.disputeItemList.push(newDisputeItem);
		
	}

	deleteRow(event) {
		const { id } = event.target.dataset;
		this.disputeItemList = this.disputeItemList.filter(disputeItem => disputeItem.Id !== id);
	}

	onChangeField(event) {
		const { id, field } = event.target.dataset;
		const value = event.target.value;
		const disputeItemToUpdate = this.disputeItemList.find(disputeItem => disputeItem.Id === id);
		if (disputeItemToUpdate) {
			disputeItemToUpdate[field] = value;
		}
	}

	handleFocus(event) {
		const inputCmp = this.template.querySelectorAll('[data-id="' + event.target.dataset.id + '"]');
		inputCmp[1].setCustomValidity('');
	}

	handleFocusOut(event) {
		this.checkValidationOfField(event.target.dataset.id);
	}

	checkValidationOfField(datasetId) {
		const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
		//--Checking the custom validation on change of a field value
		if (inputCmp !== undefined && inputCmp.length > 0) {
			checkCustomValidity(inputCmp[1], inputCmp[1].messageWhenValueMissing);
		}
	}

	get showTransactionId(){
		if (this.accountHeldWith === 'Australia Post'){
			return true;
		}
		
		return false;		
	}

	get showConnote(){
		if (this.accountHeldWith === 'StarTrack'){
			return true;
		}
		
		return false;		
	}

	@api
	checkAllValidity(){
		const inputComponents = this.template.querySelectorAll('lightning-input');
		return checkAllValidity(inputComponents);

	}

	@api
	getDisputedItems(){
		let disputeItems = [];
		if (this.disputeItemList) {
			this.disputeItemList.forEach(dItem =>{
					let disputeItem = {...dItem};
					disputeItem.Id = null;
					if (this.accountHeldWith === 'Australia Post'){
						disputeItem.Connote__c = null;
					}					
					if (this.accountHeldWith === 'StarTrack'){
						disputeItem.Transaction_ID__c = null;
					}					
					disputeItems.push(disputeItem);
				}
			)
		}
		return disputeItems;
	}


}