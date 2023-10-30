import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { navigation } from 'c/bspNavigationUtils';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';
const CASE_RECORD_TYPE_ENTERPRISE_CREDIT_DISPUTE_DEV_NAME = 'Enterprise_Credit_Dispute_Claim';
export default class BspEnquiryRow extends NavigationMixin(LightningElement) {
	@api caseWrapper;
	commUrlPrefix;
	navigate;

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

	get showCheckBox() {
		if (this.caseWrapper.RecordType != CASE_RECORD_TYPE_ENTERPRISE_CREDIT_DISPUTE_DEV_NAME){
			if (this.caseWrapper.caseObj.Status != 'Closed') {
				return true;
			} else {
				return false;
			}	
		}else{
			return false;
		}
	}

	get isActionRequiredClass() {
		// if(( (this.caseWrapper.caseObj.Status).toLowerCase() == 'awaiting customer response') ||
		//((this.caseWrapper.caseObj.Status).toLowerCase() == 'waiting on customer')){
		if (this.caseWrapper.caseUIStatus == 'Action Required') {
			return 'boldRow';
		} else {
			return '';
		}
	}

	handleChange(event) {
		var tempCaseWrapper ={...this.caseWrapper};
		tempCaseWrapper.isSelected = event.target.checked;
		const changeEvent = new CustomEvent('changeselection', {
			detail: {
				caseWrapper: tempCaseWrapper
				//isSelected: event.target.checked
			}
		});
		this.dispatchEvent(changeEvent);
	}

	onClickHandler(event) {
		event.preventDefault();
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'EnquiryDetail'
			},
			state: {
				'enquiryNumber': this.caseWrapper.caseObj.CaseNumber
				//'Id':this.caseWrapper.caseObj.Id
			}
		});
	}

	get trackingNumber() {
		if(this.caseWrapper.RecordType === CASE_RECORD_TYPE_ENTERPRISE_CREDIT_DISPUTE_DEV_NAME) {
			return this.caseWrapper.BillingNumber;
		} else {
			return this.caseWrapper.caseObj.ArticleTest__r ? this.caseWrapper.caseObj.ArticleTest__r.Name : '';
		}
	}

	get service() {
		return (this.caseWrapper.isST) ? 'StarTrack' : 'AP';
	}

	get enquiryDetailHyperLink(){
		return (this.navigate) ? this.navigate.enquiryDetailURL + '?enquiryNumber=' + this.caseWrapper.caseObj.CaseNumber : '';
	}
}