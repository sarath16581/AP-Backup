/**
 * @description LWC for displaying each article row in article's tracking Id search result table for BSP
 * @changelog
 * 2022-09-12 - naveen.rajanna@auspost.com.au - Removed /bsp in url as part of CHG0176934
 * 2024-08-02 - Seth Heang - update hyperlink call to POD_Redirect to account for SafeDropDownload loading state from parent cmp as pre-condition
 */
import { LightningElement, api } from "lwc";
import { convertToFormattedDateStr } from 'c/bspCommonJS';

export default class BspLabelEventRow extends LightningElement {
	@api le;
	@api isConsignmentAuthenticated;
	@api isCEAttachmentsExists;
	@api selectedEventArticle;
	@api isConsignmentSerchIsAPType;
	@api isSafeDropDownloadLoading;

	_viewPODClicked;

	get isCENotesAttachmentsExists() {
	return this.le.NotesAndAttachments ? this.le.NotesAndAttachments.length > 0 ? true : false : false;
	}

	get isCurrentAndSelectedArticleIsSame() {
	return this.le ? this.le.Article__c == this.selectedEventArticle ? true : false : false;
	}

	get articleLinkClass() {
	return this.isCurrentAndSelectedArticleIsSame ? "no-underline-dec brand-link-button" : "underline-dec brand-link-button";
	}

	/**
	 * Sets attribute that indicates whether safe drop image downloads have already completed. If set to false,
	 * PODs can be generated.
	 * 
	 * @param {boolean} isLoading 
	 */
	@api
	setSafeDropDownloadLoading(isLoading) {
		// flag that safedrop images have completed downloading 
		this.isSafeDropDownloadLoading = isLoading;
		// attempt to generate the POD if user has already clicked on the 'Click to view' hyperlink
		// and waiting for safe drop images to download. Note: this is subject to browser popup blockers.
		this.redirectToPOD();
	}

	selectEventArticle() {
	//event.preventDefault();
	this.selectedEventArticle = this.le.Article__c;
	this.dispatchAnEventWithSelectedArticle(this.selectedEventArticle);
	//return false;
	}

	dispatchAnEventWithSelectedArticle(selectedArticle) {
	const c = new CustomEvent("selectedarticlechange", { detail: selectedArticle });
	this.dispatchEvent(c);
	}

	/**
	 * @description set a viewPODClicked flag to true, when the 'Click to view' hyperlink is clicked
	 */
  	handlePodHref() {
		this._viewPODClicked = true;
		this.redirectToPOD();
	}

	/**
	 * @description Reactively redirect to POD_Redirect to render the PDF,
	 *			when the `Click to view` hyperlink is clicked on HTML and SafeDrop Downloading is completed
	 * @returns {string}
	 */
  	redirectToPOD() {
		if(this.diplayPOD) {
			window.open('/POD_Redirect?id=' + this.le.Id, '_blank');
		}
	}

  	get diplayPOD() {
		return !this.isSafeDropDownloadLoading && this._viewPODClicked;
	}

	get isLoading() {
		return this.isSafeDropDownloadLoading && this._viewPODClicked;
	}


	get stFormattedActualDateTimeStr(){
		return this.le.ActualDateTime_TimeStamp__c ? convertToFormattedDateStr(this.le.ActualDateTime_TimeStamp__c) : '';
	}
}