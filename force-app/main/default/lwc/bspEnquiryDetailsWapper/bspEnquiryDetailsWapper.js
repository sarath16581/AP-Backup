import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { reloadPage} from 'c/bspCommonJS';
import {refreshApex} from '@salesforce/apex';
import getEnquiryDetail from '@salesforce/apex/bspEnquiryDetailUplift.getEnquiryDetail';
import closeCase from '@salesforce/apex/bspEnquiryDetailUplift.closeCase';
import reopenCase from '@salesforce/apex/bspEnquiryDetailUplift.reopenCase';

export default class BspEnquiryDetailsWapper extends LightningElement {
	// enquiryId;
	enquiryNumber;
	@track caseDetailWrapper;
	isAuthorized;
	errorMessage;
	isLoading = true;
	enquiryButtonMessage = '';

	/**
	 *Geeting enquiry number from a URL
		*/
	@wire(CurrentPageReference)
	setCurrentPageReference(currentPageReference) {
		this.currentPageReference = currentPageReference;
		this.enquiryNumber = this.currentPageReference.state.enquiryNumber;
	}

	@wire(getEnquiryDetail, {
		enquiryNumber: '$enquiryNumber'
	}) getCaseDetails({
		error,
		data
	}) {
		if (data) {
			this.caseDetailWrapper = data;
			this.isAuthorized = this.caseDetailWrapper.authorised;
			this.isLoading = false;
			this.setEnquiryButtonsMessage();
		} else if (error) {
			//alert(error);
			this.errorMessage = error.body.message;
			this.isLoading = false;
		}
	}

	get authorized() {
		return (this.isAuthorized && this.caseDetailWrapper) ? this.isAuthorized : false;
	}

	get existingFiles() {
		let uploadFilesTemp = [];
		if (this.caseDetailWrapper) {
			if (this.caseDetailWrapper.existingFiles) {

				for (var key in this.caseDetailWrapper.existingFiles) {
					uploadFilesTemp.push({
						value: this.caseDetailWrapper.existingFiles[key],
						key: key
					});
				}
			}
		}
		return uploadFilesTemp;

	}

	setEnquiryButtonsMessage(){
		this.enquiryButtonMessage = 'This enquiry cannot be reopened or updated. If you need further assistance, please submit a new enquiry.';
		if(this.isVisibleResolveEnquiryBtn){
			this.enquiryButtonMessage = 'You can resolve this enquiry if no further investigation is needed.';
		}
		if(this.isVisibleReOpenEnquiryBtn){
			this.enquiryButtonMessage = 'You can re-open this enquiry if more information is needed. This option is only available for 30 days from the date the enquiry was resolved.';
		}
	}

	get isVisibleResolveEnquiryBtn() {
		return this.caseDetailWrapper ? (this.caseDetailWrapper.enq.Status.toLowerCase() != 'closed' ? true : false) : false;
	}

	get isVisibleReOpenEnquiryBtn() {
		//!IF(LOWER(enq.status)=='closed'&&NOT(enq.Permanent_Close__c)&&BEGINS(enq.RecordType.Developername, 'SSSW'),true,false)}"
		return this.caseDetailWrapper ?
			(this.caseDetailWrapper.enq.Status.toLowerCase() == 'closed' &&
				!this.caseDetailWrapper.enq.Permanent_Close__c &&
				this.caseDetailWrapper.enq.RecordType.DeveloperName.startsWith('SSSW') ? true : false) :
			false;
	}

	handleLoading(event) {
		this.isLoading = event.detail;
	}

	handlePrint() {
		window.print();
	}

	@api
	refresh() {
		return refreshApex(this.caseDetailWrapper); 
	}

	handleResolveEnquiry() {
		this.isLoading = true;
		closeCase({
			enqId: this.caseDetailWrapper.enq.Id
		}).then(result => {
			//refreshApex(this.caseDetailWrapper);
			reloadPage(false);
			this.isLoading = false; //not needed as we are reloading the page
		}).catch(error => {
			this.errorMessage = error.body.message;
		});

	}

	handleReOpenEnquiry() {
		this.isLoading = true;
		reopenCase({
			enqId: this.caseDetailWrapper.enq.Id
		}).then(result => {
			reloadPage(false);
			this.isLoading = false; //not needed as we are reloading the page
		}).catch(error => {
			this.errorMessage = error.body.message;
			this.isLoading = false;
		});
	}

	get isCreditClaim() {
		//return this.isSSW;
		if ((this.caseDetailWrapper.enq.RecordType.Name === 'Enterprise Credit Dispute Claim') && (this.caseDetailWrapper.enq.CCUEnquiryType__c === 'Credit Claim'))
			return true;
		else
			return false;
	}	

}