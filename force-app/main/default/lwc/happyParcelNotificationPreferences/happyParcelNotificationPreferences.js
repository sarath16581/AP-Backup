/**
 * @description Happy Parcel Notification Preferences
 * @author Disha Kariya
 * @group Tracking
 * @changelog
 */
import { LightningElement, api, track } from "lwc";
import { CONSTANTS, get, getPreferences, setPreferences } from 'c/happyParcelService'
import HappyParcelBase from "c/happyParcelBase";

export default class HappyParcelNotificationPreferences extends LightningElement {

	@api loading = false;
	@api searchString = {};
	@api apcnFound;

	@track higherPrefs = [];
	@track higherPrefsString;
    @track lowerPrefs = [];
    @track lowerPrefsString;
	@track loadingNotificationPreferences = false;
	@track NotificationPreferenceStatusMessage;
	@track isDisabled = false;
	@track messageType;
	@track showToastBar = false;
	//Help Text for APCN values
	@track higherHelpText;
	@track lowerHelpText;
	blueBoxText = CONSTANTS.LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESBLUEBOXTEXT;

	connectedCallback() {
		this.doGetNotificationPreferences();
    }

	doGetNotificationPreferences = async () => {
        if(this.higherPrefs.length === 0 && this.lowerPrefs.length === 0){
            this.loadingNotificationPreferences = true;
        }
        // perform the actual callout to the api
        const result = await getPreferences(this.searchString);
		if(result.preferences){
		    var tempEmailPrefs = [];
		    var tempPhonePrefs = [];
	        result.preferences.forEach((item) => {
	            if(item.email){
	                tempEmailPrefs = [...tempEmailPrefs, {searchString: item.email,optedIn: !item.optedOut, foundByAPCN: item.foundByAPCN}];
	            }else{
	                tempPhonePrefs = [...tempPhonePrefs, {searchString: item.mobile,optedIn: !item.optedOut, foundByAPCN: item.foundByAPCN}];
	            }
	        });
	        //Decide which table to be displayed first.
            this.higherPrefsString = tempPhonePrefs.length >= tempEmailPrefs.length ? 'Phone' : 'Email';
            this.higherHelpText = this.higherPrefsString === 'Phone' ? CONSTANTS.LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNPHONEHELPTEXT : CONSTANTS.LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNEMAILHELPTEXT;
            this.higherPrefs = tempPhonePrefs.length >= tempEmailPrefs.length ? [...tempPhonePrefs] : [...tempEmailPrefs];
            this.lowerPrefsString = tempPhonePrefs.length < tempEmailPrefs.length ? 'Phone' : 'Email';
            this.lowerHelpText = this.lowerPrefsString === 'Phone' ? CONSTANTS.LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNPHONEHELPTEXT : CONSTANTS.LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNEMAILHELPTEXT;
            this.lowerPrefs =   tempPhonePrefs.length < tempEmailPrefs.length ? [...tempPhonePrefs] : [...tempEmailPrefs];

		}
		if(result.error){
			console.log('result.error>>>',result.error);
			this.loadingNotificationPreferences = false;
        }
        this.loadingNotificationPreferences = false;
    }

   	get waiting() {
        return this.loading || this.loadingNotificationPreferences;
    }

    handleToggleChange(event){
        const setUnset = event.target.checked;
        const searchId = event.currentTarget.dataset.searchid;
        this.doSetNotificationPreference(searchId, setUnset);
    }

    async doSetNotificationPreference(searchId, setUnset) {
        this.isDisabled = true;
        const message = await setPreferences(searchId, !setUnset);
        if(message.indexOf('Error') >= 0 ){
            this.setNotificationPreferenceStatusMessage(message, 'error');
			this.template.querySelectorAll('[data-searchid="'+searchId+'"]')
                        .forEach(element => { element.checked = !setUnset; });
        } else {
	        this.setNotificationPreferenceStatusMessage(message, 'success');
        }
        await this.doGetNotificationPreferences();
        this.isDisabled = false;
        setTimeout(() => {
            this.closeModel();
        }, 2000);
    }

    setNotificationPreferenceStatusMessage(message, type) {
        this.messageType = type;
        this.NotificationPreferenceStatusMessage = message;
        this.showToast(this.messageType, this.NotificationPreferenceStatusMessage);
    }

    get innerClass() {
        return 'slds-icon_container slds-icon-utility-' + this.messageType + ' slds-icon-utility-success slds-m-right_small slds-no-flex slds-align-top';
    }

    get outerClass() {
        return 'slds-notify slds-notify_toast slds-m-top_none slds-p-vertical_xx-small slds-p-horizontal_xx-small slds-theme_' + this.messageType;
    }

    get getIconName() {
        return 'utility:' + this.messageType;
    }

	showToast(type, message) {
	    this.type = type;
	    this.message = message;
	    this.showToastBar = true;
	}

	closeModel() {
	    this.showToastBar = false;
	    this.messageType = '';
	    this.NotificationPreferenceStatusMessage = '';
	}

	get hasPreferences() {
        return this.hasHigherPreferences || this.hasLowerPreferences;
    }

    get hasHigherPreferences() {
        return this.higherPrefs && this.higherPrefs.length>0;
    }

    get hasLowerPreferences() {
        return this.lowerPrefs && this.lowerPrefs.length>0;
    }

    get divClass() {
        return this.hasHigherPreferences && this.hasLowerPreferences ? 'slds-col slds-size_1-of-1 slds-small-size_1-of-2 slds-has-flexi-truncate' :'slds-col slds-size_1-of-1 slds-has-flexi-truncate';
    }

    get tableClass(){
        return this.lowerPrefs.length !== this.higherPrefs.length ? 'slds-table slds-table_bordered slds-table_striped bottom_bordered' : 'slds-table slds-table_bordered slds-table_striped no_border';
    }
}