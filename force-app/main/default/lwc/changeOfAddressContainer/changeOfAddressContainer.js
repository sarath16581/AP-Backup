import { api, LightningElement, wire, track } from 'lwc';
import displayChangeAddress from '@salesforce/apex/ChangeOfAddressController.displayOldOrNewChangeAddress';
import LightningAlert from "lightning/alert";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from 'lightning/navigation';
import ACCOUNT_NAME from "@salesforce/schema/Account.Name";
import ACCOUNT_BILLING_STREET from "@salesforce/schema/Account.BillingStreet";
import ACCOUNT_BILLING_CITY from "@salesforce/schema/Account.BillingCity";
import ACCOUNT_BILLING_STATE from "@salesforce/schema/Account.BillingState";
import ACCOUNT_BILLING_POSTAL_CODE from "@salesforce/schema/Account.BillingPostalCode";
import ACCOUNT_PHYSICAL_STREET from "@salesforce/schema/Account.ShippingStreet";
import ACCOUNT_PHYSICAL_CITY from "@salesforce/schema/Account.ShippingCity";
import ACCOUNT_PHYSICAL_STATE from "@salesforce/schema/Account.ShippingState";
import ACCOUNT_PHYSICAL_POSTAL_CODE from "@salesforce/schema/Account.ShippingPostalCode";

const ACCOUNT_FIELDS = [
    ACCOUNT_NAME,
    ACCOUNT_BILLING_STREET,
    ACCOUNT_BILLING_CITY,
    ACCOUNT_BILLING_STATE,
    ACCOUNT_BILLING_POSTAL_CODE,
    ACCOUNT_PHYSICAL_STREET,
    ACCOUNT_PHYSICAL_CITY,
    ACCOUNT_PHYSICAL_STATE,
    ACCOUNT_PHYSICAL_POSTAL_CODE
];

export default class ChangeOfAddressContainer extends NavigationMixin(LightningElement) {
    // API properties for AddressLookupRecordWrapper
    @api addressType;
    @api cardTitle;
    @api addressType2;
    @api cardTitle2;
    @api addressType3;
    @api cardTitle3;
    @api recordId;
    @api altRecordId;
    @api noRefreshAfterSave;
    @api refreshAfterSave;
    @api refreshNotNavigate;
	@track isPreviousScreen=false;
	test;
    // Address data and UI flags
    currentBillingAddress;
    currentPhysicalAddress;
    newBillingAddress;
    newPhysicalAddress;
	productSelected=[];
	billingAccsSelectedST;
	billingAccsSelectedAP;
    showNewAddress = true;
    showBillingAccountSelection = false;
    isLoading = true;
    unavailableError = 'Address Search is unavailable for Organisations with Role other than Prospect or Known.';
    displayOld;
    displayNew;
	recordPageUrl;
    
    // Screen navigation tracking
    @track currentScreenName = 'addressScreen'; // Initial screen
    screenSequence = ['addressScreen', 'contactScreen', 'billingAccountScreen', 'serviceRequestScreen', 'confirmationScreen'];
    userSelectedData = {}; // Stores data for each screen
    recordData;
    @wire(displayChangeAddress, { orgId: '$recordId' })
    handleDisplayChangeAddress({ error, data }) {
        if (data) {
            this.displayOld = data === 'old';
            this.displayNew = data === 'new';
            this.isLoading = false;
        } else if (error) {
            LightningAlert.open({
                message: 'Something went wrong while retrieving old/new address display conditions: ' + error.body.message,
                theme: 'error',
                label: 'Change of Address'
            });
            this.isLoading = false;
        }
    }

    // Fetch account record and populate current addresses
    @wire(getRecord, { recordId: "$recordId", fields: ACCOUNT_FIELDS })
    handleAccountRecord({ error, data }) {
        if (data) {
            this.recordData = data;
            // Load current addresses if available
            if (getFieldValue(this.recordData, ACCOUNT_BILLING_STREET)) {
                this.currentBillingAddress = `${getFieldValue(this.recordData, ACCOUNT_BILLING_STREET)} ${getFieldValue(this.recordData, ACCOUNT_BILLING_CITY)} ${getFieldValue(this.recordData, ACCOUNT_BILLING_STATE)} ${getFieldValue(this.recordData, ACCOUNT_BILLING_POSTAL_CODE)}`;
            }

            if (getFieldValue(this.recordData, ACCOUNT_PHYSICAL_STREET)) {
                this.currentPhysicalAddress = `${getFieldValue(this.recordData, ACCOUNT_PHYSICAL_STREET)} ${getFieldValue(this.recordData, ACCOUNT_PHYSICAL_CITY)} ${getFieldValue(this.recordData, ACCOUNT_PHYSICAL_STATE)} ${getFieldValue(this.recordData, ACCOUNT_PHYSICAL_POSTAL_CODE)}`;
            }
        }
        if (error) {
            console.error('Error when loading current addresses: ' + error);
        }
    }

    // Conditional getters to determine which screen is active
    get isAddressScreen() {
        return this.currentScreenName === 'addressScreen';
    }

    get isContactScreen() {
        return this.currentScreenName === 'contactScreen';
    }

    get isBillingAccountScreen() {
        return this.currentScreenName === 'billingAccountScreen';
    }

    get isServiceRequestScreen() {
        return this.currentScreenName === 'serviceRequestScreen';
    }

    get isConfirmationScreen() {
        return this.currentScreenName === 'confirmationScreen';
    }

	get newBillingAddressConcat() {
		return [this.newBillingAddress?.addressLine1, this.newBillingAddress?.addressLine2, this.newBillingAddress?.city, this.newBillingAddress?.state, this.newBillingAddress?.postcode].filter(e => e != null).join(' ');
	}

	get newPhysicalAddressConcat() {
		return [this.newPhysicalAddress?.addressLine1, this.newPhysicalAddress?.addressLine2, this.newPhysicalAddress?.city, this.newPhysicalAddress?.state, this.newPhysicalAddress?.postcode].filter(e => e != null).join(' ');
	}

    // Handle 'Next' button click to move to the next screen
    async handleNext() {
		console.log('start time' +Date.now())
        const activeChildComponent = this.template.querySelector(`[data-screen-name="${this.currentScreenName}"]`);
        if (activeChildComponent) {
            const selectedData = await activeChildComponent.getUserSelectedData();
			// check if validation fails
			if (selectedData === -1) {
				return;
			}
            if (selectedData) {
                this.userSelectedData[this.currentScreenName] = selectedData;
				if(this.currentScreenName==='addressScreen'){
					this.newBillingAddress = selectedData.billingAddress || this.newBillingAddress;
					this.newPhysicalAddress = selectedData.physicalAddress || this.newPhysicalAddress;	
				}
				if(this.currentScreenName==='serviceRequestScreen'){
					this.productSelected = 'AP';
					this.billingAccsSelectedST ='';
					this.billingAccsSelectedAP='';
				}
			}
			// Navigate to the next screen in sequence
			const currentIndex = this.screenSequence.indexOf(this.currentScreenName);
			if (currentIndex < this.screenSequence.length - 1) {
				this.currentScreenName = this.screenSequence[currentIndex + 1];
				console.log('this.currentScreenName'+this.currentScreenName);
			} else {
				console.log("Final Screen");
			}
			console.log('end time' +Date.now())
            
        } else {
            console.error('Active child component not found.');
        }
    }

    // Handle 'Previous' button click to go back to the previous screen
    async handlePrevious() {
		this.isLoading=true;
		/*const activeChildComponent = this.template.querySelector(`[data-screen-name="${this.currentScreenName}"]`);
        if (activeChildComponent) {
            const selectedData = await activeChildComponent.getUserSelectedData();
            if (selectedData) {
                this.userSelectedData[this.currentScreenName] = selectedData;
				if(this.currentScreenName==='addressScreen'){
					this.newBillingAddress = selectedData.billingAddress || this.newBillingAddress;
					this.newPhysicalAddress = selectedData.physicalAddress || this.newPhysicalAddress;	
				}
			}
		}else {
            console.error('Active child component not found.');
        }*/
        const currentIndex = this.screenSequence.indexOf(this.currentScreenName);
        if (currentIndex > 0) {
			// Update the current screen name to the previous screen
			this.currentScreenName = this.screenSequence[currentIndex - 1];
			// Use setTimeout to ensure DOM is updated before querying the component
			setTimeout(() => {
				const activeChildComponent = this.template.querySelector(`[data-screen-name="${this.currentScreenName}"]`);
				const savedData = this.userSelectedData[this.currentScreenName];
				if (activeChildComponent && savedData) {
					activeChildComponent.restoreState(savedData); // Call restore method in child
				}
			}, 0);
		}
		this.isLoading=false;
    }

    // Handle cancellation of the address change flow
	handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
                objectApiName: 'Account'
            }
        });
    }
}