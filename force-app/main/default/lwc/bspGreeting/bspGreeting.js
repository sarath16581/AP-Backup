import { LightningElement, wire, track } from 'lwc'
import { getRecord, getFieldValue } from 'lightning/uiRecordApi'
import USER_FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName'
import USER_LAST_NAME_FIELD from '@salesforce/schema/User.LastName'
import USER_BUSINESS_NAME from '@salesforce/schema/User.Contact.Account.Name'
import USER_ID from '@salesforce/user/Id'
import getUserPrimaryBillingNumber from '@salesforce/apex/bspEnquiryUplift.getUserPrimaryBillingNumber';
import isDIFOTFilesExistsForOrg from '@salesforce/apex/bspAccountReporting.isDIFOTFilesExists';
import { NavigationMixin } from 'lightning/navigation';
import VIDEOLINK from '@salesforce/label/c.BSPGreeting_YouTube_Link';

export default class BspGreeting extends NavigationMixin(LightningElement) {
    @track userId = USER_ID;
    primaryBillingAccNumber;
    isDIFOTFilesExists = false;
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @track isModalOpen = false;
    videoLink = VIDEOLINK;

    @wire(getRecord, {
        recordId: "$userId",
        fields: [USER_FIRST_NAME_FIELD, USER_LAST_NAME_FIELD, USER_BUSINESS_NAME]
    })
    user;

    @wire(getUserPrimaryBillingNumber) getPrimaryBillingNumber({
        error,
        data
    }) {
        if (data) {
            this.primaryBillingAccNumber = data;
        }
    }

    get userFirstName() {
        return getFieldValue(this.user.data, USER_FIRST_NAME_FIELD);
    }

    get userLastName() {
        return getFieldValue(this.user.data, USER_LAST_NAME_FIELD);
    }

    get businessName() {
        return getFieldValue(this.user.data, USER_BUSINESS_NAME);
    }

    get businessNumber() {
        //return getFieldValue(this.user.data, USER_PRIMARY_ACCOUNT_BILLING_NUMBER);
        const businessNumber = this.primaryBillingAccNumber;
        if (businessNumber != undefined) {
            if (businessNumber.startsWith("T") || businessNumber.startsWith("P"))
                return businessNumber.substring(1);
            else return businessNumber;
        }

    }

    @wire(isDIFOTFilesExistsForOrg) isDIFOTFilesExistsForOrg({error,data }) {
        if (data) 
            this.isDIFOTFilesExists = data;
    }

    navigateToAccountReport(event){
        event.preventDefault();
        this[NavigationMixin.GenerateUrl]({
            type: 'comm__namedPage',
            attributes: {
                name: 'BSP_Account_Reporting__c'
            }
        }).then(generatedUrl => {
            window.open(generatedUrl, "_blank");
        });
    }
    // Modal/YouTube popup related
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }
}