/**
 * @description Render details about customer
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2021-05-18 - Disha Kariya - Added a method to set a search string for notification preferences
 */
import {LightningElement, api, track, wire} from "lwc";
import { CONSTANTS, get, getPreferences } from "c/happyParcelService";
import HappyParcelBase from "c/happyParcelBase";

//const ALL_FIELDS = HappyParcelService.getCustomerArticleFields();

export default class HappyParcelCustomerDetails extends HappyParcelBase {

	@api loading;

	// whether to grab the Sender or Receiver details to display from the record
	@api detailType;

	// this is the contact that was mapped based on the APCN, name/email of either sender/receiver in record
	// this is passed in from the parent since the calculation is performed in bulk on the server
	@api contact;

	//this is to indicate if APCN is found for notification preference
	@track apcnFound = false;

	@track loadingNotificationPreferences = false;

	@track prefs = {};

	// TODO: These will need to be implemented at a later date
	// stores a link to the billing account /organisation
	// this is derived from fields 'record' attribute and is currently only applicable for the 'sender'
	// @track billingAccount;
	// @track organisation;

	// enables this component to be 'selectable'
	// when the component is clicked, an event is generated and propagated up the DOM
	@api supportsCustomerSelection;

	// marks this component as selected
	// this is only applicable where supportsCustomerSelection is true
	@api selected;

	//help text for red notification icon when opted out
	helpText = CONSTANTS.LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESOPTOUTHELPTEXT;

	@track _trackingApiResult;
	@api
	get trackingApiResult() { return this._trackingApiResult; };
	set trackingApiResult(value) {
		this._trackingApiResult = value;

		// after the customer details have been set we need to push these details up to the external caller to give them all the customer details on the article (for either sender or receiver)
		// each customer details component (either sender or receiver) will propagate its own event with its own set of details
		if(this.supportsCustomerSelection) {
			const detail = {
				...this.details,
				contactId: (this.contact ? this.contact.id : null),
				type: (this.detailType == CONSTANTS.CUSTOMER_DETAILS_SENDER ? 'sender' : 'receiver')
			};
			this.dispatchEvent(new CustomEvent('customerdetails', {detail: detail, bubbles: true, composed: true}));
		}
		//Get notification preferences only for receiver
		if(this.searchString && this.detailType == CONSTANTS.CUSTOMER_DETAILS_RECEIVER){
			this.doGetNotificationPreferences();
		}
	}
	
	doGetNotificationPreferences = async () => {
        this.loadingNotificationPreferences = true;
        // perform the actual callout to the api
        const result = await getPreferences(this.searchString);
        console.log('result.foundBasedOnAPCN>>>',result.foundBasedOnAPCN);
        if(result.preferences){
            result.preferences.forEach((item) => {
                //check if found by APCN and if email exists
				if(result.foundBasedOnAPCN && item.email && !this.prefs['emailString']) {
				    this.prefs['email'] = item.email ? !item.optedOut : null,
				    this.prefs['emailString'] = item.email ? item.email : null
				}
				// verify email returned is email on manifest.
				if(item.email === this.details.email){
				    this.prefs['manifestEmail'] = item.email ? !item.optedOut : null
                }
				//check if found by APCN and if mobile exists.
				if(result.foundBasedOnAPCN && item.mobile && !this.prefs['mobileString']) {
				    this.prefs['mobile'] = item.mobile ? !item.optedOut : null,
				    this.prefs['mobileString'] = item.mobile ? item.mobile : null
				}
				// verify mobile returned is mobile on manifest
				if(item.mobile === this.details.mobile){
				    this.prefs['manifestMobile'] = item.mobile ? !item.optedOut : null
			    }
				//check if mobile is returned and verify mobile returned is phone on manifest.
				if(item.mobile && item.mobile === this.details.phone) {
                    this.prefs['manifestPhone'] = item.mobile ? !item.optedOut : null
                }
            });
            console.log('this.prefs>>',this.prefs);
            //Set apcnFound if preferences are found
            this.apcnFound = result.foundBasedOnAPCN && Object.keys(this.prefs).length > 0;
        }
        if(result.error){
//            error handling
        }
        this.loadingNotificationPreferences = false;
    }

	/**
	 * When the customer card is selected.
	 * This will propagate all the way to the top and into any external wrapping apps.
	 * The parent component should also pick this up and set it's counterpart customer card to not selected
	 */
	handleCardSelected() {
		if(this.supportsCustomerSelection) {
			const detail = {type: (this.detailType == CONSTANTS.CUSTOMER_DETAILS_SENDER ? 'sender' : 'receiver')};
			this.dispatchEvent(new CustomEvent('customerselect', {detail: detail, bubbles: true, composed: true}));
		}
	}

	/**
	 * When the customer card is deselected
	 * This event can be used by any external wrapping components
	 */
	handleCardDeselected() {
		if(this.supportsCustomerSelection) {
			const detail = {type: (this.detailType == CONSTANTS.CUSTOMER_DETAILS_SENDER ? 'sender' : 'receiver')};
			this.dispatchEvent(new CustomEvent('customerdeselect', {detail: detail, bubbles: true, composed: true}));
		}
	}

	get heading() {
		return (this.detailType == CONSTANTS.CUSTOMER_DETAILS_RECEIVER ? 'Addressee Details' : (this.detailType == CONSTANTS.CUSTOMER_DETAILS_SENDER ? 'Sender Details' : ''));
	}

	get icon() {
		return (this.detailType == CONSTANTS.CUSTOMER_DETAILS_RECEIVER ? 'utility:user' : (this.detailType == CONSTANTS.CUSTOMER_DETAILS_SENDER ? 'utility:user' : ''));
	}

	get organisationUrl() {
		return (this.organisation ? `/${this.organisation.Id}` : null);
	}
	get contactUrl() {
		return (this.contact ? `/${this.contact.Id}` : null);
	}

	get detailsExist() {
		return this.details && (this.details.name || this.details.address || this.details.email || this.details.mlid);
	}

	get showHyphen() {
		return this.details.mobile && this.details.phone;
    }

    get mobileFound() {
        return this.details.mobile && this.prefs.manifestMobile !== undefined && !this.prefs.manifestMobile;
    }

    get phoneFound() {
        return this.details.phone && this.prefs.manifestPhone !== undefined && !this.prefs.manifestPhone;
    }

    get emailFound() {
        return this.details.email && this.prefs.manifestEmail !== undefined && !this.prefs.manifestEmail;
    }

	//Set search String for notification preference. APCN takes precedence.
	get searchString() {
		const searchMap = {};
	    if(this.details && this.detailType == CONSTANTS.CUSTOMER_DETAILS_RECEIVER){
	        if(this.details.apcn) {
				this.addValueToMap(searchMap,'apcn', this.details.apcn);
	        }
	        if(this.details.email) {
				this.addValueToMap(searchMap,'email',this.details.email);
			}
			if(this.details.phone) {
	            this.addValueToMap(searchMap,'phone',this.details.phone);
            }
            if(this.details.mobile) {
	            this.addValueToMap(searchMap,'phone',this.details.mobile);
	        }
	        console.log('searchMap>>>',searchMap);
        }
	    return Object.keys(searchMap).length > 0 ? searchMap : null;
    }

	addValueToMap(inputMap, key, value){
	    if(value){
			inputMap[key] = inputMap[key] || [];
			inputMap[key].push(value);
		}
    }

	get waiting() {
		return this.loading;
	}

	get iconClass() {
	    return this.apcnFound ? 'slds-m-top_x-small' : '';
    }

    get iconDivClass() {
        return this.apcnFound ? 'slds-align_absolute-center slds-m-top_x-small iconDiv' : 'slds-align_absolute-center slds-m-top_x-small';
    }

	get details() {
		const article = get(this.trackingApiResult, 'article', {});
		const output = {};
		//console.log(json.stringify(article));

		// TODO use 'import' on these fields to prevent the ability to delete theme without first removing them from here
		// the are the attributes we will send to the address details components from the article search results
		let attributeMappings = {};

		// NOTE: only 2 equals and not 3 since the data types are a mismatch
		if(this.detailType == CONSTANTS.CUSTOMER_DETAILS_SENDER) {
			attributeMappings = {
				'SenderAddress__c': 'address',
				'SenderCity__c': 'city',
				'Sender_Mobile__c': 'mobile',
				'SenderName__c': 'name',
				'SenderCompany__c': 'companyName',
				'Sender_Phone__c': 'phone',
				'SenderPostcode__c': 'postcode',
				'SenderState__c': 'state',
				'Sender_Suburb__c': 'suburb',
				'SenderCountry__c': 'country',
				'SenderCountryName__c': 'countryName',
				'SenderEmail__c': 'email',
				'Sender_APCN__c': 'apcn',
				'MLID__c': 'mlid'				
			};
		} else {
			attributeMappings = {
				'ReceiverAddress__c': 'address',
				'ReceiverCity__c': 'city',
				'Receiver_Mobile__c': 'mobile',
				'ReceiverName__c': 'name',
				'ReceiverCompany__c': 'companyName',
				'Receiver_Phone__c': 'phone',
				'ReceiverPostcode__c': 'postcode',
				'ReceiverState__c': 'state',
				'Receiver_Suburb__c': 'suburb',
				'ReceiverCountry__c': 'country',
				'ReceiverCountryName__c': 'countryName',
				'ReceiverEmail__c': 'email',
				'Receiver_APCN__c': 'apcn'
			};
			
		}

		// map all the details to a generic object based on what detailType we are displaying
		Object.keys(attributeMappings).forEach(key => output[attributeMappings[key]] = article[key]);

		return output;
	}

	handleContactClick() {
		// trigger a DOM event so anything upline can catch it.
		// this will be handled by 1 of 2 options
		// 1. if happyParcel -> supportsExternalLinkHandling!=true, happyParcel.js which will have NavigationMixin to navigate
		//															idclick event handler is stopped here.
		// 2. if happyParcel -> supportsExternalLinkHandling==true, the idclick event will propagate up to the external listener and the external listener will handle the event
		if(this.contact) {
			this.dispatchEvent(new CustomEvent('idclick', { detail: { id: this.contact.Id }, bubbles: true, composed: true} ));
		}
	}
}