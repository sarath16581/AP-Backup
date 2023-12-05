import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { navigation } from 'c/bspNavigationUtils';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';
export default class BspEnquiryItemDetails extends NavigationMixin(LightningElement) {

	@api caseDetailWrapper;
	commUrlPrefix;
	navigate;
	formattedEnquiryType;

	connectedCallback() {
		try {
			retrieveBspCommunityURL().then(result => {
				this.commURLPrefix = result;
				this.navigate = navigation(this.commURLPrefix);
			});
			// formatting the enq type to de-capitalize the rest of the words when found in a value
			this.formatEnquiryType();
		} catch (er) {
			console.error(er)
		}
	}

	get isSSSW() {
		if ((this.caseDetailWrapper.enq.RecordType.DeveloperName).startsWith('SSSW'))
			return true;
		else
			return false;
	}


	get isStarTrack() {
		if ((this.caseDetailWrapper.enq.RecordType.DeveloperName).startsWith('StarTrack'))
			return true;
		else
			return false;
	}

	get isCreditClaim() {
		if ((this.caseDetailWrapper.enq.RecordType.Name === 'Enterprise Credit Dispute Claim') && (this.caseDetailWrapper.enq.CCUEnquiryType__c === 'Credit Claim'))
			return true;
		else
			return false;
	}

	/* get authorized() {
			return this.caseDetailWrapper?this.caseDetailWrapper.authorised:false;
		}*/

	get consignmentOrPriceBookRefNumberLabel() {
		return this.caseDetailWrapper.enq.RecordType.Name == 'Pickup Booking Enquiry' ? 'Pickup Booking Reference Number' : 'Consignment Number';
	}
	get consignmentOrPriceBookRefNumberValue() {
		return this.caseDetailWrapper.enq.RecordType.Name == 'Pickup Booking Enquiry' ?
			this.caseDetailWrapper.enq.Pickup_Booking_Reference__c : (this.caseDetailWrapper.enq.ArticleTest__r ?
				this.caseDetailWrapper.enq.ArticleTest__r.Name : '');
	}

	get isDeliveryEnquiry() {
		return this.caseDetailWrapper.enq.RecordType.Name == 'Delivery Enquiry' ? true : false;
	}

	get ssswItemType() {
		return this.caseDetailWrapper.enq.ArticleType__c ? this.caseDetailWrapper.enq.ArticleType__c : this.caseDetailWrapper.enq.ProductCategory__c;
	}

	get ssswServiceUsed() {
		return this.caseDetailWrapper.enq.CCUServiceUsed__c ? this.caseDetailWrapper.enq.CCUServiceUsed__c : this.caseDetailWrapper.enq.ProductSubCategory__c;
	}
	//Jansi: commented beow duplicate getter 28-09-2020
	/*get ssswItemContents() {
		return this.caseDetailWrapper.enq.CCUServiceUsed__c ? this.caseDetailWrapper.enq.CCUServiceUsed__c : this.caseDetailWrapper.enq.ProductSubCategory__c;
	}*/

	get ssswItemContents() {
		return this.caseDetailWrapper.enq.CCUItemContents__c ? this.caseDetailWrapper.enq.CCUItemContents__c : this.caseDetailWrapper.enq.DescriptionofContents__c;
	}

	get stRelatedBillingAccName() {
		return this.caseDetailWrapper.enq.Related_Billing_Account__r ? this.caseDetailWrapper.enq.Related_Billing_Account__r.Name : '';
	}

	get trackingSearchPageLink(){
		return (this.navigate) ? this.navigate.trackingSearchPageURL + '?trackingNumber=' + this.caseDetailWrapper.enq.ReferenceID__c : '';
	}

	get stTrackingSearchPageLink(){
		return (this.navigate) ? this.navigate.trackingSearchPageURL + '?trackingNumber=' + this.consignmentOrPriceBookRefNumberValue : '';
	}

	get isPickupBookingEnquiry() {
		return this.caseDetailWrapper.enq.RecordType.Name == 'Pickup Booking Enquiry' ? true : false;
	}

	/**
	 * Format the picklist value to capitalize only the first letter of the displayed value, ensuring it reflects the label rather than the API name.
	 * This approach is implemented to avoid altering the API value, which could lead to potential issues in other areas in the system.
	 * eg: Billing Dispute to Billing dispute (see the 'D' in dispute)
	 */
	formatEnquiryType() {
		let currentEnquiryType = this.caseDetailWrapper.enq.Enquiry_Type__c;
		// Capitalize the first letter
		let capitalizedEnquiryType = currentEnquiryType.charAt(0).toUpperCase() + currentEnquiryType.slice(1).toLowerCase();
		// Assign it back
		this.formattedEnquiryType = capitalizedEnquiryType;
		console.log(this.formattedEnquiryType);
	}
}