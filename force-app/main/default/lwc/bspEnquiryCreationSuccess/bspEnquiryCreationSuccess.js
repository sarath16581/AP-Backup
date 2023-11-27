import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSTEnquiryCreationSuccessBodyText from '@salesforce/apex/bspEnquiryUplift.getSTEnquiryCreationSuccessBodyText';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';
import getEDDPlusBusinessDays from '@salesforce/apex/bspEnquiryUplift.getEDDPlusBusinessDays';

export default class BspEnquiryCreationSuccess extends NavigationMixin(LightningElement) {
	@api enquiyType;
	@api caseNumber;
	@api edd;
	@api containsEssentialMedicine;
	@api hasSentimentalValue;
	@api pageType;
	dateDisplayOption = {weekday:'long',month:'long',day:'numeric'};
	currentDate = new Date().toJSON().slice(0, 10);
	stBodyText;
	communityURL = '';
	eddPlusBusinessDays;

	@wire(getSTEnquiryCreationSuccessBodyText) wiredSTSuccessText({ data, error }) {
		if (data) {
			this.stBodyText = data;
		}
	}

	async connectedCallback() {
		try {
			this.communityURL = await retrieveBspCommunityURL();
			this.eddPlusBusinessDays = await getEDDPlusBusinessDays({edd:this.edd});
		} catch (er) {
			console.error(er)
		}
	}

	get isAPType() {
		return this.enquiyType ? (this.enquiyType == 'Auspost' ? true : false) : false;
	}

	get isSType() {
		return this.enquiyType ? (this.enquiyType == 'Startrack' ? true : false) : false;
	}

	get apHeaderHeading() {
		if (this.isAPType) {
			if (this.displayEDDVariation) {
				return 'Thanks, we\'ve received your enquiry';
			} if (this.displayCreditClaimVariation) {
				return 'Thanks, we\'ve received your credit claim';
			} else {
				return 'Thank you, your enquiry has been sent.'
			}
		}
	}

	get apBodyHeading() {
		if (this.isAPType) {
			if (this.displayEDDVariation) {
				return 'What happens next';
			} if (this.displayCreditClaimVariation) {
				return 'What happens next';
			}
		}
	}

	get headerContent() {
		if (this.isAPType) {
			return this.aPHeaderContent();
		} else if (this.isSType) {
			return 'Thank you, your enquiry has been created.';
		} else {
			return '';
		}
	}

	get bodyContent() {
		if (this.isAPType) {
			return this.aPBodyContent();
		} else if (this.isSType) {
			return this.stBodyText ? this.stBodyText : '';
		} else {
			return '';
		}
	}

	get noteContent() {
		if (this.isAPType) {
			return this.aPNoteContent();
		} else if (this.isSType) {
			return 'You can check your enquiry here: ' +
					'<a href="' + this.communityURL + '/s/EnquiryDetail?enquiryNumber=' + this.caseNumber + '" target="_blank" ><b>' + this.caseNumber + '</b> </a>';
		} else {
			return '';
		}
	}

	get displayEDDVariation() {
		return this.edd && this.pageType?.toLowerCase() === 'missing item';
	}

	get displayCreditClaimVariation() {
		return this.pageType?.toLowerCase() === 'credit claim';
	}
	get parcelTense() {
		return this.edd < this.currentDate ? 'was' : 'is';
	}

	eddBasedAPContent(beforeEdd, beforeEddPlus, afterEddPlus, noEdd, creditClaim) {
		if (this.displayCreditClaimVariation) {
			return creditClaim;
		}
		if (!this.displayEDDVariation) { // no edd provided, or this is being passed from the BSP LOMI form
			return noEdd;
		}

		if (this.containsEssentialMedicine?.toLowerCase() === 'yes' || this.hasSentimentalValue?.toLowerCase() === 'yes') { // return the after edd+business days content regardless of edd if it contains essential medicine
			return afterEddPlus;
		}

		if (this.currentDate <= this.edd ) { // before edd
			return beforeEdd;
		} else if (this.currentDate <= this.eddPlusBusinessDays) { // before edd+business days
			return beforeEddPlus;
		} else if (this.currentDate > this.eddPlusBusinessDays) { // after edd+business days
			return afterEddPlus;
		}
	}

	aPHeaderContent() {
		let noEdd = 'Your reference number is ' +
					'<a href="' + this.communityURL + '/s/EnquiryDetail?enquiryNumber=' + this.caseNumber + '" target="_blank" ><b>' + this.caseNumber + ' </b></a>' +
					' and we’ve' +
					' emailed you a copy for your records.' +
					' A Business Customer Representative will be in touch shortly, usually within one to two business days.';

		let beforeEdd = '<p>Your enquiry reference number is: <b>'+ this.caseNumber + '</b>. We’ve sent you a confirmation email with your enquiry details.</p>' +
		'<br><p>This parcel ' + this.parcelTense + ' expected on <b>'+ new Date(this.edd).toLocaleDateString('en-AU', this.dateDisplayOption).replaceAll(',','') +'</b>.</p>';

			let beforeEddPlus = '<p>Your enquiry reference number is: <b>'+ this.caseNumber + '</b>. We’ve sent you a confirmation email with your enquiry details.</p>' +
			'<br><p>This parcel ' + this.parcelTense + ' expected on <b>'+ new Date(this.edd).toLocaleDateString('en-AU', this.dateDisplayOption).replaceAll(',','') +'</b>.</p>';

		let afterEddPlus = '<p>Your enquiry reference number is: <b>'+ this.caseNumber + '</b>. We’ve sent you a confirmation email with your enquiry details.</p>';
		let creditClaim = '<p>Your enquiry reference number is: <b>'+ this.caseNumber + '</b>. <br>We’ve sent you a confirmation email with your case details.</p></b>';

		return this.eddBasedAPContent(beforeEdd, beforeEddPlus, afterEddPlus, noEdd, creditClaim);
	}

	aPBodyContent() {
		let beforeEdd = '<h3>We’ll monitor this parcel until <b>'+ new Date(this.eddPlusBusinessDays).toLocaleDateString('en-AU', this.dateDisplayOption).replaceAll(',','') +'</b>.</h3>' +
				'<p>If it hasn’t been delivered by then, we’ll begin investigating. No need to submit another enquiry.</p>';

		let beforeEddPlus = '<h3>Most late parcels arrive within 5 business days of the expected delivery date.</h3>' +
				'<p>If this parcel is delivered, we’ll let you know and close your enquiry.</p>' + '<br>' +
				'<h3>To allow for delayed delivery, we’ll monitor this parcel until '+ new Date(this.eddPlusBusinessDays).toLocaleDateString('en-AU', this.dateDisplayOption).replaceAll(',','') +'.</h3>' +
				'<p>If it hasn’t been delivered by then, we’ll begin investigating. No need to submit another enquiry.</p>';

		let afterEddPlus = '<h3>We’ll review your enquiry</h3>' +
			'<p>As this parcel is delayed, our customer support team will review your enquiry.</p>' + '<br>' +
			'<h3>Our team will investigate</h3>' +
			'<p>We’ll review the tracking history, and try to locate the parcel.</p>' + '<br>' +
			'<h3>We’ll contact you with the outcome</h3>' +
			'<p>You’ll hear back from us soon - usually within 2 business days.</p>';

		let creditClaim =  '';

		return this.eddBasedAPContent(beforeEdd, beforeEddPlus, afterEddPlus, creditClaim);
	}

	aPNoteContent() {
		let noEdd = 'Please note: This excludes weekends and national public holidays.';
		let beforeEdd =  '<h1 class="slds-p-top_large">We\'ll keep you updated</h1>'+'<p>You’ll hear back from us after we review your enquiry on '+ new Date(this.eddPlusBusinessDays).toLocaleDateString('en-AU', this.dateDisplayOption).replaceAll(',','') +' - usually within 2 business days - or if this parcel is delivered.</p>';
		let beforeEddPlus = '<h1 class="slds-p-top_large">We\'ll keep you updated</h1>'+'<p>You’ll hear back from us after we review your enquiry on '+ new Date(this.eddPlusBusinessDays).toLocaleDateString('en-AU', this.dateDisplayOption).replaceAll(',','') +' - usually within 2 business days - or if this parcel is delivered.</p>';
		let afterEddPlus = '';
		let creditClaim = '<li class="slds-p-top--large">We\'ll review your credit claim</li>';
		creditClaim += '<li class="slds-p-top--large">Our team will investigate</li>';
		creditClaim += '<li class="slds-p-top_large slds-p-bottom--large" >You\'ll hear back from us soon</li>';

		return this.eddBasedAPContent(beforeEdd, beforeEddPlus, afterEddPlus, noEdd, creditClaim);
	}

	onClickCancel() {
		this.navigateHome();
	}

	//[To check, can move this to common JS]
	navigateHome() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: 'Home'
			}
		});
	}

}