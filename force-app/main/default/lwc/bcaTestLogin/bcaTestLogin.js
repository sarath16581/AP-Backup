import { LightningElement, track } from 'lwc';
import checkIsUserIsExistingUser from '@salesforce/apex/BCAFormBase.isUserHasBillingAccount';
import {NavigationMixin} from "lightning/navigation";

export default class BcaTestLogin extends NavigationMixin(LightningElement) {

    @track userId = '0055D000003meG8';
    isLoading = false;
    @track error;

    onChangeField(event) {
        this.userId = event.target.value;
    }

    loginHandler(event) {
        this.isLoading = true;
        checkIsUserIsExistingUser({
            loggedInUserId: this.userId.trim(),
        }).then(result => {
            //alert(result);
            if (result) {
                this.isLoading = false;
                //alert('navigate to bca home for existing user');
            } else {
                this.isLoading = false;
                //alert('navigate to bca home for new user');
            }

            //event.preventDefault();
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'bca_form__c'
                },
                state: {
                    isExistingCustomer: result == true? 'yes' :'no'
                    //'Id':this.caseWrapper.caseObj.Id
                }
            });


        }).catch(error => {
            //alert(JSON.stringify(error));
            this.isLoading = false;
            console.log('ERROR==>'+error.body.message);
            this.error = error.body.message;
        }
        );
    }

}