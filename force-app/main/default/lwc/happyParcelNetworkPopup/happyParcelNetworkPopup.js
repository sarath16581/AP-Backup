/**
 * @description Happy Parcel network Popup
 * @author Disha Kariya
 * @date 2020-09-09
 * @group Tracking
 * @changelog
 * 2020-09-18 - Disha Kariya - Added WCC for future use
 * 2020-10-12 - Ranjeewa Silva - Made event id optional so that the popup can be used to display network info when wcc is available
 */
import { LightningElement, api , track } from 'lwc';
import HappyParcelBase from "c/happyParcelBase";
import { get, getConfig, CONSTANTS, getNetworkDetails } from "c/happyParcelService";

export default class HappyParcelNetworkPopup extends HappyParcelBase {
    @api eventId;
    @api wcc;
    @api variant;
	@track network;
	@track loadingNetworkDetails = true;
	@track error;
	@track detailsWrapper;
	@track hoursWrapper;
	@track hasOpeningHours;
	@track hasLunchHours;
	@track hasHatchHours;
	@track hasHours;

	//Send close event to parent with event Id
    closePopup(){
        this.dispatchEvent(new CustomEvent('closepopup', {
		   detail: this.eventId
	   }));
    }

	async connectedCallback() {
	    this.loadingNetworkDetails = true;
		console.log('Inside network Popup');
		// perform the actual callout to the api
		if (this.wcc) {
			const result = await getNetworkDetails(this.wcc);
			const {error, network } = result;
			if(network){
				this.network = network;
				console.log('this.network>>'+this.network);
				console.log('before this.hasLunchHours>>'+this.hasLunchHours);
				if(this.network.Mon__c || this.network.Tue__c || this.network.Wed__c || this.network.Thu__c
				|| this.network.Fri__c || this.network.Sat__c || this.network.Sun__c){
				    this.hasOpeningHours = true;
    			}
    			if(this.network.CL_Mon__c || this.network.CL_Tue__c || this.network.CL_Wed__c || this.network.CL_Thu__c
				|| this.network.CL_Fri__c || this.network.CL_Sat__c || this.network.CL_Sun__c){
    			    this.hasLunchHours = true;
    			    console.log('this.hasLunchHours>>'+this.hasLunchHours);
		        }
		        if(this.network.Hatch_Mon__c || this.network.Hatch_Tue__c || this.network.Hatch_Wed__c || this.network.Hatch_Thu__c
				&& this.network.Hatch_Fri__c || this.network.Hatch_Sat__c || this.network.Hatch_Sun__c){
					this.hasHatchHours = true;
			    }
			    console.log('After this.hasLunchHours>>'+this.hasLunchHours);

       			if(this.hasOpeningHours && this.hasLunchHours && this.hasHatchHours){
       			    this.hasHours = true;
       			    this.detailsWrapper = "slds-col slds-size_1-of-1 slds-medium-size_2-of-5";
       			    this.hoursWrapper = "slds-col slds-size_1-of-1 slds-medium-size_3-of-5";
          		}else if(this.hasOpeningHours || this.hasLunchHours || this.hasHatchHours){
          		    this.hasHours = true;
					this.detailsWrapper = "slds-col slds-size_1-of-1 slds-medium-size_1-of-2";
					this.hoursWrapper = "slds-col slds-size_1-of-1 slds-medium-size_1-of-2";
            	} else {
          		    this.hasHours = false;
					this.detailsWrapper = "slds-col slds-size_1-of-1";
				}
			}

			if(error) {
				this.error = error;
			}
		}
		this.loadingNetworkDetails = false;
	}
}