/**
 * 	@author Hasantha Liyanage
 * 	@date 2023-11-02
 * 	@group child component
 * 	@domain BSP
 * 	@description info text on bsp credit claim header
 * 	@changelog
 * 	2023-11-02 - Hasantha Liyanage  - Created
 */

import {api, LightningElement} from 'lwc';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';

export default class BspFormCreditIntroText extends LightningElement {

	commURLPrefix;
	@api billingAccountScope;
	enquiryForm;
	enquiryFormDelivery;
	enquiryFormStartrack;

	get isAp() {
		if (this.billingAccountScope.state.userBillingAccountScope === 'AP') {
			return true;
		} else {
			return false;
		}
	}

	get isSt() {
		if (this.billingAccountScope.state.userBillingAccountScope === 'ST') {
			return true;
		} else {
			return false;
		}
	}

	get isAll() {
		if (this.billingAccountScope.state.userBillingAccountScope === 'ALL') {
			return true;
		} else {
			return false;
		}
	}

	async connectedCallback() {
		// retrieve the base url to navigate to the forms mentioned with the links
		this.commURLPrefix = await retrieveBspCommunityURL()
		this.enquiryForm = this.commURLPrefix+'/s/EnquiryForm';
		this.enquiryFormDelivery = this.commURLPrefix+'/s/EnquiryForm?enquiryType=delivery';
		this.enquiryFormStartrack = this.commURLPrefix+'/s/StarTrackDeliveryEnquiry';
	}
}