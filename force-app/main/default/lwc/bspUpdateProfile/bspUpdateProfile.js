/*
* --------------------------------------- History --------------------------------------------------
* 07/12/2023		thang.nguyen231@auspost.com.au		added adobe analytics details
*/
import { LightningElement, wire, track } from 'lwc';
import { checkAllValidity, checkCustomValidity, topGenericErrorMessage, scrollToHeight } from 'c/bspCommonJS';
import { NavigationMixin } from 'lightning/navigation';
import getUserProfileDetails from '@salesforce/apex/bspProfileUplift.getUserProfileDetails';
import save from '@salesforce/apex/bspProfileUplift.save';

//adobe analytics
import { analyticsTrackPageLoad } from 'c/adobeAnalyticsUtils';

export default class BspUpdateProfile extends NavigationMixin(LightningElement) {

    //@track userProfile;// ={"mailingAddress":{},"user":{"FirstName":''}};

    businessName;
    businessCreditAccountNum = '';
    businessAddressSerachText = '';
    errorMessage;
    isLoading = true;
    showSuccessSection = false;
    submitClicked = false;
    
    @track user = {
        FirstName: '',
        LastName: '',
        Email: '',
        Phone: '',
        MobilePhone: ''
    };

    @track mailingAddress = {
        line1: '',
        line2: '',
        city: '',
        state: '',
        postcode: '',
        dpid: '',
        country: '',
        countryName: ''
    };

    //--this format is for existing address cmp - "bspaddresssearch"
    @track addCmpAddressFormat = {
        addressLine: '',
        addressLine3: '',
        city: '',
        state: '',
        postcode: '',
        country:'',
        countryName: ''
    };

	//analytics variables
	pageName = 'auspost:bsp:update details';

    renderedCallback() {
        if((this.errorMessage || this.showSuccessSection) && this.submitClicked) {
            this.submitClicked = false;
            scrollToHeight(this.template.querySelectorAll('[data-id="message"]'));
        }   
    }

    /**
     * wired method to get user profile details
     */

    @wire(getUserProfileDetails) userProfileDetails({
        error,
        data
    }) {
        if (data) {
            this.setFieldValues(data);
            this.isLoading = false;

        } else if (error) {
            console.log('error' + error);
            this.isLoading = false;
        }
    }

    /**
     * set the profile values
     */
    setFieldValues(data) {
        if (data.user)
            this.user = data.user
        if (data.businessName)
            this.businessName = data.businessName;
        if (data.businessNumber)
            this.businessCreditAccountNum = data.businessNumber;
        if (data.mailingAddress) {
            this.mailingAddress = data.mailingAddress;
            this.buildSearchAddress(this.mailingAddress);
            this.businessAddressSerachText = '';
            this.businessAddressSerachText = this.businessAddressSerachText.
            concat(this.mailingAddress.line1 ? this.mailingAddress.line1 + ', ' : '',
                this.mailingAddress.line2 ? this.mailingAddress.line2 + ', ' : '',
                this.mailingAddress.city, ' ',
                this.mailingAddress.state, ' ',
                this.mailingAddress.postcode, ' ',
                this.mailingAddress.countryName)  //Updated 'countryName' instead of 'country' 09.11.2020
        }
    }

    buildSearchAddress(address) {
        this.addCmpAddressFormat.addressLine = address.line1;
        this.addCmpAddressFormat.addressLine3 = address.line2;
        this.addCmpAddressFormat.city = address.city;;
        this.addCmpAddressFormat.postcode = address.postcode;
        this.addCmpAddressFormat.state = address.state;
        this.addCmpAddressFormat.country= address.country;   //Added 09.11.2020
        this.addCmpAddressFormat.countryName= address.countryName; //Added 09.11.2020
    }
    //new address entered
    handleAddressChange(event) {
        this.address = event.detail.address;
        let tempAdd = Object.assign({}, this.mailingAddress);
        tempAdd.line1 = this.address.addressLine;
        tempAdd.line2 = this.address.addressLine3;
        tempAdd.city = this.address.locality;
        tempAdd.postcode = this.address.postcode;
        tempAdd.state = this.address.state;
        tempAdd.latitude = this.address.latitude;
        tempAdd.longitude = this.address.longitude;
        tempAdd.dpid = this.address.dpid;
        tempAdd.countryName = this.address.countryName;
        this.mailingAddress = tempAdd;
    }

    //new address entered manually
    handleManualChange(event) {
        this.address = event.detail.address;
        let tempAdd = Object.assign({}, this.mailingAddress);
        tempAdd.line1 = this.address.addressLine1;
        tempAdd.line2 = this.address.addressLine2;
        tempAdd.city = this.address.city;
        tempAdd.postcode = this.address.postcode;
        tempAdd.state = this.address.state;
        tempAdd.latitude = this.address.latitude;
        tempAdd.longitude = this.address.longitude;
        tempAdd.dpid = this.address.dpid;
        tempAdd.countryName = this.address.countryName;
        this.mailingAddress = tempAdd;
    }


    handleSave(event) {
        event.preventDefault();
        this.showSuccessSection = false;
        this.submitClicked = true;
        this.errorMessage = null;
        const inputComponents = this.template.querySelectorAll('[data-validate="doValidate"]');
        const addressCmp = this.template.querySelectorAll('[data-validate="doAddressValidate"]');
        const allValid = checkAllValidity(inputComponents) & checkAllValidity(addressCmp, false);
        if (allValid) {
            this.isLoading = true;
            save({
                    mailingAddressInput: JSON.stringify(this.mailingAddress),
                    businessName: this.businessName,
                    businessNumber: this.businessCreditAccountNum,
                    userStr: JSON.stringify(this.user)
                })
                .then(() => {
                    this.isLoading = false;
                    this.showSuccessSection = true;
                    //this.navigateHome();
                })
                .catch((error) => {
                    this.isLoading = false;
                    this.errorMessage = error.body.message;
                });
        } else {
            this.errorMessage = topGenericErrorMessage;
        }

    }

    navigateHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }

    handleChange(event) {
        let tempUser = Object.assign({}, this.user);
        const field = event.target.dataset.id;
        if (field === 'firstName') {
            tempUser.FirstName = event.target.value;
        } else if (field === 'lastName') {
            tempUser.LastName = event.target.value;
        } else if (field === 'email') {
            tempUser.Email = event.target.value;
        } else if (field === 'phone') {
            tempUser.Phone = event.target.value;
        } else if (field === 'businessname') {
            this.businessName = event.target.value;
        } else if (field === 'businessNumber') {
            this.businessCreditAccountNum = event.target.value;
        } else if (field === 'Mobile') {
            tempUser.MobilePhone = event.target.value;
        }
        this.checkValidationOfField(field);
        this.user = tempUser;
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

	connectedCallback() {
		this.pushPageAnalyticsOnLoad();
	}

	pushPageAnalyticsOnLoad(){
		const pageData = {
			sitePrefix: 'auspost:bsp',
			pageAbort: 'true',
			pageName: this.pageName
		};
		analyticsTrackPageLoad(pageData);
	}		
}