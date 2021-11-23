import { LightningElement, api, track } from 'lwc';
import forgotPassword from '@salesforce/apex/bspLogin.forgotPassword';
import { NavigationMixin } from 'lightning/navigation';
import { checkAllValidity, checkCustomValidity } from 'c/bspCommonJS';

export default class BspForgotPassword extends NavigationMixin(LightningElement) {
    showResetPWDSuccess = false;
    email;

    @track errorMessage;
    
    handleChange(event) {
        const field = event.target.dataset.id;
        if (field === 'email') {
            this.email = event.target.value;
        }
        //--Checking the custom validation on change of a field value
        this.checkValidationOfField(field);
    }

    handleResetPWD(event) {
        this.errorMessage = null;
        const inputComponents = this.template.querySelectorAll('[data-validate="doValidate"]');
        const allValid = checkAllValidity(inputComponents);
        if (allValid) {
            forgotPassword({
                    userName: this.email
                })
                .then((result) => {
                    this.showResetPWDSuccess = true;
                })
                .catch((error) => {
                    this.errorMessage = error.body.message;
                    this.loginButtonClicked = false;
                });
        }

    }

    handleCancel(event) {
        //dispatch event to parent to show login section
        const evt = new CustomEvent('hanldlesecdisplay', {
            detail: {
                showLoginSec: true
            }
        });
        this.dispatchEvent(evt);
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