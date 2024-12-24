import { LightningElement, wire } from 'lwc';
import identifyCustomer from '@salesforce/apex/CustomerLinkingController.identifyCustomer';
import customerLinkingFormSubmit from '@salesforce/apex/CustomerLinkingController.customerLinkingFormSubmit';
import {getRecord} from 'lightning/uiRecordApi'
import USER_ID from '@salesforce/user/Id';
import ACCOUNT_ID from '@salesforce/schema/User.AccountId';
import privacyStatement from '@salesforce/label/c.Privacy_Statement_LPO';
import ToastContainer from 'lightning/toastContainer';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomerLinking extends LightningElement {
	expandprivacystatement=false;
	expandcustomerfields=false;
	isSearchDisabled=true;
	isICConfirmDisabled=true;
	isSubmitDisabled=true;
	searchKey;
	accounts;
	accountswrap;
	errorMessage;
	selectedAccountId;
	selectedAccount;
	activeSectionName="A";
	privacyStatement=privacyStatement;
	physicaladdress;
	phone;
	website;
	isvalidphysicaladdress=false;

	@wire(getRecord, {
        recordId: USER_ID,
        fields: [ACCOUNT_ID] /* include all the fields needed from loggedinuser */
    })
    userDetailHandler({data, error}){
        if(data){
            console.log('data.fields.AccountId.value');
        }
		if(error){
			console.log('>>error in wire'+error);
		}
    }

	connectedCallback(){
        //set the toast instance
        const toastContainer = ToastContainer.instance();
        toastContainer.maxShown = 5; //number of toast shown at once
        toastContainer.toastPosition = 'top-center'; //alignment of toast
    }

	handlesearchinput(event){
		this.searchKey = event.target.value.toLowerCase();

		if(this.searchKey.length>=3){ //later update this length to correct validation length 
			this.isSearchDisabled = false;
		}else{
			this.isSearchDisabled = true;
		}
	}

	handleSearch(){
		identifyCustomer({searchkey: this.searchKey})
        .then((result) => {
            // handle result
            if(result){
                if(Object.hasOwn(result, 'accwrapList') && result.accwrapList && result.accwrapList.length > 0){
                    this.accountswrap = result.accwrapList;
					console.log('<this.accountswrap'+this.accountswrap);
					this.errorMessage = '';
                }else if(Object.hasOwn(result, 'noAccountFound') && result.noAccountFound){
                    // handle display error
					this.errorMessage = 'No Account found with the entered input';
                }
            }
        })
        .catch((error) => {
            console.log('<<errror in identify customer'+error);
			this.errorMessage = error;
        }).finally(()=>{
            // if something has to be done
        })
	}

	handleTileSelection(event){
		console.log('<<came to handleTileSelection');
		// Get the ID of the selected account
		console.log(event.target.dataset.id);
		const selectedId = event.target.dataset.id;
        this.selectedAccountId = selectedId;
		console.log('selectedId'+selectedId);
		if(selectedId){
			console.log('<<came to confirm');
			this.isICConfirmDisabled = false;
		}
		const selectedAccount = this.accountswrap.find(account => account.accrec.Id === this.selectedAccountId);
        this.selectedAccount = selectedAccount;
		console.log('selectedAccount'+JSON.stringify(selectedAccount));
		let accwraplist = this.accountswrap;
		let updatedaccwraplist = [];
		console.log('accwraplist'+JSON.stringify(accwraplist));
		for(let i = 0; i<accwraplist.length; i++){
			console.log('accountswrap[i].accrec.Id'+accwraplist[i]);
			if(accwraplist[i].accrec.Id === this.selectedAccountId){
				accwraplist[i].classname = 'tile selectedtile';
				console.log('accountswrap[i].classname inside if'+accwraplist[i].classname);
			}else{
				accwraplist[i].classname = 'tile nonselectedtile';
				console.log('accountswrap[i].classname inside else'+accwraplist[i].classname);
			}
			updatedaccwraplist.push(accwraplist[i]);
			console.log('accwraplist length'+accwraplist.length);
		}
		this.accountswrap = updatedaccwraplist;
		console.log('this.accountswra'+JSON.stringify(this.accountswrap));
	}

	handleICConfirm(){
		this.expandprivacystatement = true;
		this.activeSectionName="B";
	}

	handlePSAccept(){
		this.expandcustomerfields = true;
		this.activeSectionName="C";
	}

	handleaddressinput(event){
		this.physicaladdress = event.target.value;
		this.isvalidphysicaladdress = true; // later this should be changed dynamically.. as per the validation status from c-ame-address-validation2
		this.handleenablesubmit();
	}

	handlephoneinput(event){
		this.phone = event.target.value;
		this.handleenablesubmit();
	}

	handlewebsiteinput(event){
		this.website = event.target.value;
	}

	handleFormSubmit(){
		if(this.isvalidphysicaladdress){
			this.dispatchSuccess('Your request is successfully submitted, we will get back to you with results shortly');
			this.callApexOnSubmit(true);
		}else{
			this.dispatchError('Your request is not submitted, as Physical Address is not valid');
			this.callApexOnSubmit(false);
		}
	}

	callApexOnSubmit(isAllValidated){
		customerLinkingFormSubmit({physicalAddress: this.physicaladdress,
			website: this.website,
			phone: this.phone,
			customer: this.selectedAccount,
			userId: USER_ID,
			isAllValidated: isAllValidated
		})
        .then((result) => {
            // handle result
            if(result){
                if(Object.hasOwn(result, 'dsrcreated') && result.dsrcreated){
                    // pass the DSR number and modify the success message
					// this.dispatchSuccess('Your request is successfully submitted, we will get back to you with results shortly');
                }
				this.isSubmitDisabled=true;
            }
        })
        .catch((error) => {
            console.log('<<errror in callApexOnSubmit'+JSON.stringify(error));
			this.errorMessage = error;
			this.isSubmitDisabled=true;
        }).finally(()=>{
            // if something has to be done
        })
	}

	handleenablesubmit(){
		const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            if(this.phone && this.physicaladdress && this.phone.length<=10){
				this.isSubmitDisabled=false;
			}
        }else{
            this.isSubmitDisabled=true;
        }
		/*if(this.phone && this.physicaladdress && this.phone.length<=10){
			
		}else{
			
		}*/
	}

	dispatchError(message){
        const evt = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        });
        this.dispatchEvent(evt);
    }

	dispatchSuccess(message){
        const evt = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

}