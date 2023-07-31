import { LightningElement, api, track } from 'lwc';

import {checkAllValidity, checkCustomValidity, topGenericErrorMessage, scrollToHeight} from 'c/bspCommonJS';

export default class bspDisputeItems extends LightningElement {
    @track disputeItemList = [];
	@api accountHeldWith = '';


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
//		const inputCmp = this.template.querySelectorAll('[data-id="' + event.target.dataset.id + '"]');
//		inputCmp[0].setCustomValidity('');
	}

	get showTransactionId(){
		if (this.accountHeldWith === 'Australia Post'){
			return true;
		}else{
			return false;
		}
	}

	get showConnote(){
		if (this.accountHeldWith === 'StarTrack'){
			return true;
		}else{
			return false;
		}
	}
	
	@api
	checkAllValidity(){
		const inputComponents = this.template.querySelectorAll('lightning-input');
		return checkAllValidity(inputComponents);

	}

	@api
	getDisputedItems(){
		return this.disputeItemList;

	}


}
