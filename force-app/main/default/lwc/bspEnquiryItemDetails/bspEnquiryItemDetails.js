import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { navigation } from 'c/bspNavigationUtils';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';
import {getObjectInfo, getPicklistValues} from 'lightning/uiObjectInfoApi';

// case object
import CASE_OBJECT from '@salesforce/schema/Case';
import ENQUIRY_TYPE_FIELD from '@salesforce/schema/Case.Enquiry_Type__c';
import REASON_CREDIT_CLAIM_FIELD from '@salesforce/schema/Case.ReasonforCreditClaim__c';

export default class BspEnquiryItemDetails extends NavigationMixin(LightningElement) {

	@api caseDetailWrapper;
	commUrlPrefix;
	navigate;
	formattedReasonForCreditClaim;
	reasonsForCreditClaim;
	formattedEnquiryType;
	enquiryTypes;
	recordTypeId;

	@wire(getObjectInfo, { objectApiName: CASE_OBJECT })
	wiredObjectInfo({data, error}) {
		if (error) {
			console.error(error);
		} else if (data) {
			const rtis = data.recordTypeInfos;
			this.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Enterprise Credit Dispute Claim');
		}
	}

	@wire(getPicklistValues, {recordTypeId: "$recordTypeId", fieldApiName: ENQUIRY_TYPE_FIELD })
	enquiryTypeInfo({data, error}) {
		if (error) {
			console.error(error);
		} else if (data) {
			if (this.recordTypeId){
				this.enquiryTypes = data;	
				this.getEnquiryTypeLabels();						
			}
		}
	}

	@wire(getPicklistValues, {recordTypeId: "$recordTypeId", fieldApiName: REASON_CREDIT_CLAIM_FIELD })
	reasonClaimInfo({data, error}) {
		if (error) {
			console.error(error);
		} else if (data) {
			if (this.recordTypeId){
				this.reasonsForCreditClaim = data;
				this.getReasonCreditClaimLabels();
			}
		}
	}

	connectedCallback() {
		try {
			retrieveBspCommunityURL().then(result => {
				this.commURLPrefix = result;
				this.navigate = navigation(this.commURLPrefix);
			});
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
	getEnquiryTypeLabels() {
		if (this.enquiryTypes){
			let formattedEnquiryTypeValues = this.enquiryTypes.values.filter(opt => opt.value.includes(this.caseDetailWrapper.enq.Enquiry_Type__c));	
			if (formattedEnquiryTypeValues.length > 0)  this.formattedEnquiryType = formattedEnquiryTypeValues[0].label;
		}
	}

	getReasonCreditClaimLabels() {
		if (this.reasonsForCreditClaim){
			let formattedReasonForCreditClaimValues = this.reasonsForCreditClaim.values.filter(opt => opt.value.includes(this.caseDetailWrapper.enq.ReasonforCreditClaim__c));
			if (formattedReasonForCreditClaimValues.length > 0) this.formattedReasonForCreditClaim = formattedReasonForCreditClaimValues[0].label;
		}
	}	

}