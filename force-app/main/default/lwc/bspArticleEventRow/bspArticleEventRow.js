/**
 * @description LWC for displaying each article row in article's tracking Id search result table for BSP
 * @changelog
 * 2022-09-12 - naveen.rajanna@auspost.com.au - Removed /bsp in url as part of CHG0176934
 * 2024-08-02 - Seth Heang - update hyperlink call to POD_Redirect to account for SafeDropDownload loading state from parent cmp as pre-condition
 */
import { LightningElement, api } from 'lwc';
import { convertToFormattedDateStr } from 'c/bspCommonJS';


export default class BspArticleEventRow extends LightningElement {
	@api evnt;
	@api isConsignmentAuthenticated;
	@api isCEAttachmentsExists;
	@api reqFrom;
	@api emScanTypes;
	@api isConsignmentSerchIsAPType;
	@api isConsignmentSerchIsSTType;
	@api isSafeDropDownloadLoading;

	_viewPODClicked;

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


	get isCEAttachmentsExists() {
		return this.evnt.NotesAndAttachments ?
				(this.evnt.NotesAndAttachments.length > 0 ? true : false) : false;
	}


	get isArticleEventAttachmentsExists() {

		return (this.emScanTypes &&
				this.emScanTypes.includes(this.evnt.EventType__c) &&
				( (this.evnt.NotesAndAttachments && this.evnt.NotesAndAttachments.length > 0) ||
						(this.evnt.Safe_Drop_GUID__c != '' && this.evnt.Safe_Drop_GUID__c != undefined)
				)
		) ? true : false;

		/*return this.evnt.NotesAndAttachments && this.emScanTypes
		  ? (((this.evnt.NotesAndAttachments.length > 0 || this.evnt.Safe_Drop_GUID__c != '') &&
			this.emScanTypes.includes(this.evnt.EventType__c)) ? true : false)
		  : false;*/
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
	 *				when the `Click to view` hyperlink is clicked on HTML and SafeDrop Downloading is completed
	 * @returns {string}
	 */
    redirectToPOD() {
        if (this.diplayPOD) {
            window.open('/POD_Redirect?id=' + this.evnt.Id, '_blank');
		}
	}

    get diplayPOD() {
		return !this.isSafeDropDownloadLoading && this._viewPODClicked;
	}

    get isLoading() {
		return this.isSafeDropDownloadLoading && this._viewPODClicked;
	}

    get formattedActualDateStr() {
		return this.evnt.ActualDateTime_TimeStamp__c ? convertToFormattedDateStr(this.evnt.ActualDateTime_TimeStamp__c) : '';
	}
}