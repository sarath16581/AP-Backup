import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import save from '@salesforce/apex/bspRegistrationUplift.save';
import { checkAllValidity,checkCustomValidity, topGenericErrorMessage, scrollToHeight } from 'c/bspCommonJS';

export default class BspRegistration extends NavigationMixin(LightningElement) {

    @track isRegSecVisible = true;
    @track saveButtonClicked = false;
    @track errorMessage;
    @track isLoading = false;

    contact = {
        FirstName: '',
        LastName: '',
        Email: '',
        Phone: '',
    };
    businessName = '';
    businessNumber = '';

    renderedCallback() {
        if(this.errorMessage && this.saveButtonClicked) {
            this.saveButtonClicked = false;
            scrollToHeight(this.template.querySelectorAll('[data-id="message"]'));
        }   
    }

    handleChange(event) {
        const field = event.target.dataset.id;
        if (field === 'firstName') {
            this.contact.FirstName = event.target.value;
        } else if (field === 'lastName') {
            this.contact.LastName = event.target.value;
        } else if (field === 'email') {
            this.contact.Email = event.target.value;
        } else if (field === 'phone') {
            this.contact.Phone = event.target.value;
        } else if (field === 'businessName') {
            this.businessName = event.target.value;
        } else if (field === 'businessNumber') {
            this.businessNumber = event.target.value;
        }
        //--Checking the custom validation on change of a field value
        this.checkValidationOfField(field);
    }

    mailingAddress = {
        line1: '',
        line2: '',
        city: '',
        state: '',
        postcode: '',
        dpid: '',
        country: '',
        countryName: ''
    };

    handleSave(event) {
        this.errorMessage = null;
        this.saveButtonClicked = true;
        const inputComponents = this.template.querySelectorAll('[data-validate="doValidate"]');
        const addressCmp = this.template.querySelectorAll('[data-validate="doAddressValidate"]');
        const allValid = checkAllValidity(inputComponents) & checkAllValidity(addressCmp, false);
        if (allValid) {
            this.isLoading = true;
            save({
                    mailingAddressInput: JSON.stringify(this.mailingAddress),
                    businessName: this.businessName,
                    businessNumber: this.businessNumber,
                    contactStr: JSON.stringify(this.contact)
                })
                .then(() => {
                    this.isRegSecVisible = false;
                    this.isLoading = false;
                })
                .catch((error) => {
                    this.errorMessage = error.body.message;
                    this.isLoading = false;
                });
        } else {
            this.errorMessage = topGenericErrorMessage;
        }
    }


    //new address entered
    handleAddressChange(event) {
        this.address = event.detail.address;
        this.mailingAddress.line1 = this.address.addressLine;
        this.mailingAddress.line2 = this.address.addressLine3;
        this.mailingAddress.city = this.address.locality;
        this.mailingAddress.postcode = this.address.postcode;
        this.mailingAddress.state = this.address.state;
        this.mailingAddress.latitude = this.address.latitude;
        this.mailingAddress.longitude = this.address.longitude;
        this.mailingAddress.dpid = this.address.dpid;
        //console.log(this.mailingAddress);
    }

    //new address entered manually
    handleManualChange(event) {
        this.address = event.detail.address;
        this.mailingAddress.line1 = this.address.addressLine1;
        this.mailingAddress.line2 = this.address.addressLine2;
        this.mailingAddress.city = this.address.city;
        this.mailingAddress.postcode = this.address.postcode;
        this.mailingAddress.state = this.address.state;
        this.mailingAddress.latitude = this.address.latitude;
        this.mailingAddress.longitude = this.address.longitude;
        this.mailingAddress.dpid = this.address.dpid;
        //console.log(this.mailingAddress);
    }

    handleCancel(event) {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'login'
            },
            replace: true
        });
    }

    handleFocusOut(event) {
        this.checkValidationOfField(event.target.dataset.id);
    }

    checkValidationOfField(datasetId) {
        const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
        //--Checking the custom validation on change of a field value
        if (inputCmp != undefined && inputCmp.length > 0) {
            checkCustomValidity(inputCmp[0]);
        }
    }

}