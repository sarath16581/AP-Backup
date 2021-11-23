import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { checkAllValidity, checkCustomValidity, topGenericErrorMessage } from 'c/bspCommonJS';
import savePassword from '@salesforce/apex/bspLogin.savePassword';

export default class BspResetPassword extends NavigationMixin(LightningElement) {

    newPassword;
    verifyNewPassword;
    isTypedPWD = false;
    isPasswordMatch = false;
    @track errorMessage;
    @track myEmail;
    @track myUserId;
    @track saveButtonClicked = false;
    @track showSuccessSec = false;

    connectedCallback() {
        let locURL = new URL(window.location.href).searchParams;
        this.myUserId = locURL.get('myid');
        this.myEmail = locURL.get('myemail');
    }

    handleChange(event) {
        const field = event.target.dataset.id;
        if (field === 'newPassword') {
            this.newPassword = event.target.value;
        } else if (field === 'verifyNewPassword') {
            this.verifyNewPassword = event.target.value;
        }
        //--Checking the custom validation on change of a field value
        this.checkValidationOfField(field);
    }

    checkPasswordMatch(event) {
        this.isTypedPWD = true;
        if (this.newPassword == this.verifyNewPassword)
            this.isPasswordMatch = true;
        else
            this.isPasswordMatch = false;

    }

    navigateLogin(event) {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'login'
            }
        });
    }

    handleSave(vent) {
        this.errorMessage = null;
        const inputComponents = this.template.querySelectorAll('[data-validate="doValidate"]');
        const allValid = checkAllValidity(inputComponents) && this.isPasswordMatch;
        if (allValid) {
            this.saveButtonClicked = true;
            savePassword({
                    userId: this.myUserId,
                    password1: this.newPassword,
                    password2: this.verifyNewPassword,
                    emailId: this.myEmail
                })
                .then((result) => {
                    this.saveButtonClicked = false;
                    this.showSuccessSec = true;
                })
                .catch((error) => {
                    this.errorMessage = error.body.message;
                    this.saveButtonClicked = false;
                    this.showSuccessSec = false;
                });
        } else {
            this.errorMessage = topGenericErrorMessage;
        }
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