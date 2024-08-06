/**
 * @description Consignment Tracking ID Search LWC used in BSP Community
 * @changelog:
 * 2023-12-14 - thang.nguyen231@auspost.com.au - added adobe analytics details
 * 2024-08-02 - Seth Heang - added safedrop image download async functionality
 */
import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { checkAllValidity, valueMissingErrorMsg, topGenericErrorMessage } from 'c/bspCommonJS';
import search from '@salesforce/apexContinuation/BSPConsignmentSearchUplift.search';
import getCurrentStateOfSafeDropImageRequiredForDownload from '@salesforce/apex/BSPConsignmentSearchUplift.getCurrentStateOfSafeDropImageRequiredForDownload';
import getSafeDropImageForPOD from '@salesforce/apexContinuation/BSPConsignmentSearchUplift.getSafeDropImageForPOD';

//adobe analytics
import { analyticsTrackPageLoad } from 'c/adobeAnalyticsUtils';

export default class BSPConsignmentSearch extends NavigationMixin(LightningElement) {

	@track consignmentSearchResultsWrapper;
	@track headerEvent;
	@track errorMessages = [];
	isLoading;
	requiredValMissingErrorMsg = valueMissingErrorMsg;
	consignmentNumber;
	_safeDropDownloadLoading;

	//analytics variables
	pageName = 'auspost:bsp:searchconsignment';

	handleTrackingNumberSerach(event) {
		this.consignmentNumber = event.detail;
		if (this.consignmentNumber) {
			this.handleSearch();
		}
	}

	/**
	 * call consinment number search
	 */
	handleSearch = () => {
		this.isLoading = true;
		this.consignmentSearchResultsWrapper = null;
		this.errorMessages = [];
		search({
			consignNumber: this.consignmentNumber.trim()
		}).then(result => {
			this.consignmentSearchResultsWrapper = result;
			if (this.consignmentSearchResultsWrapper.errorMessages.length > 0) {
				this.errorMessages = this.consignmentSearchResultsWrapper.errorMessages;
			}
			this.isLoading = false;
			this.downloadSafeDropImage(this.consignmentNumber);
		}).catch(error => {
			// 2020/10/01 - catching IO exceptions here
			let sErrorBody = error.body.message;
			if(sErrorBody)
			{
				if(sErrorBody.toLowerCase().includes('time out'))
				{
					this.errorMessages.push('Search Consignment Timeout.');
				}
				else if(sErrorBody.toLowerCase().includes('failed to get next element'))
				{
					this.errorMessages.push('Error authenticating access to external system.');
				}
				else if(sErrorBody.toLowerCase().includes('policy falsified'))
				{
					this.errorMessages.push('Invalid client cert.');
				}
			}
			else
			{
				this.errorMessages.push('An error has occurred.');
			}

			this.isLoading = false;
		});
	}

	get consignNum() {
		this.consignmentNumber ? this.consignmentNumber : '';
	}


	get isShowConList() {
		return this.consignmentSearchResultsWrapper ? this.consignmentSearchResultsWrapper.showConList : false;
	}

	get isShowConDetail() {
		return this.consignmentSearchResultsWrapper ? this.consignmentSearchResultsWrapper.showConDetail : false;
	}

	get isConsignmentSerchIsAPType() {
		return this.consignmentSearchResultsWrapper ?
				(this.consignmentSearchResultsWrapper.selectedConsignmentSearchType == 'AusPost' ? true : false)
				: false;
	}

	get isConsignmentSerchIsSTType() {
		return this.consignmentSearchResultsWrapper ?
				(this.consignmentSearchResultsWrapper.selectedConsignmentSearchType == 'StarTrack' ? true : false)
				: false;
	}

	get isSTPODExists() {
		return this.consignmentSearchResultsWrapper.relatedPODs ?
				(this.consignmentSearchResultsWrapper.relatedPODs.length > 0 ? true : false) :
				false;
	}

	get isShowHeaderEventSection() {
		var isShow = false;
		if (this.consignmentSearchResultsWrapper) {
			if (this.consignmentSearchResultsWrapper.consignmentEvents) {
				if (this.consignmentSearchResultsWrapper.consignmentEvents.length > 0) {
					isShow = true;
					this.headerEvent = this.consignmentSearchResultsWrapper.consignmentEvents[0];
				} else if (this.consignmentSearchResultsWrapper.selectedConsignmentSearchType == 'AusPost' &&
						this.consignmentSearchResultsWrapper.labelEvents.length == 1 && //-- means single Article
						this.consignmentSearchResultsWrapper.articleEvents.length > 0) { // AP Consignment single Article
					isShow = true;
					this.headerEvent = this.consignmentSearchResultsWrapper.articleEvents[0];
				}
			}
		}
		return isShow;
	}

	get isShowLabelEvents() {
		var isShow = false;

		if (this.consignmentSearchResultsWrapper.selectedConsignmentSearchType == 'StarTrack' ||
				(this.consignmentSearchResultsWrapper.selectedConsignmentSearchType == 'AusPost' &&
						this.consignmentSearchResultsWrapper.singleCon.RecordType.Name == 'Consignment' && this.isLabelEventsExists)) {
			isShow = true;
		}

		return isShow;
	}

	get isLabelEventsExists() {
		return this.consignmentSearchResultsWrapper ?
				(this.consignmentSearchResultsWrapper.labelEvents ?
						(this.consignmentSearchResultsWrapper.labelEvents.length > 0 ? true : false) :
						false) :
				false;
	}

	get isShowArticleEvents() {
		var isShow = false;
		if (this.consignmentSearchResultsWrapper) { // [Jansi; this check not needed in all js methods]
			if (this.consignmentSearchResultsWrapper.articleEvents) {
				if (this.consignmentSearchResultsWrapper.articleEvents.length > 0) {
					isShow = true;
				}
			}
		}
		return isShow;
	}

	get isShowCreateEnquirySection() {
		return this.consignmentSearchResultsWrapper ?
				(this.consignmentSearchResultsWrapper.showCreateCaseButton ?
						this.consignmentSearchResultsWrapper.showCreateCaseButton : false) :
				false;
	}

	get isShowconsignmentEvents() {
		var isShow = false;
		if (this.consignmentSearchResultsWrapper.selectedConsignmentSearchType == 'StarTrack' ||
				(this.consignmentSearchResultsWrapper.selectedConsignmentSearchType == 'AusPost' &&
						this.consignmentSearchResultsWrapper.singleCon.RecordType.Name == 'Article')) {
			isShow = true;
		}
		return isShow;
	}

	onChangeOfSelectedEvent(event) {
		this.consignmentSearchResultsWrapper.selectedEventArticle = event.detail;
		if (this.consignmentSearchResultsWrapper.selectedEventArticle != '') {
			//-- get selected Article events
			var selectedArticleEventsMap = this.consignmentSearchResultsWrapper.
					articleEventsMap[this.consignmentSearchResultsWrapper.selectedEventArticle];
			this.consignmentSearchResultsWrapper.articleEvents = Object.values(selectedArticleEventsMap);
		} else {
			this.consignmentSearchResultsWrapper.articleEvents = null;
		}
	}

	get isConsigmentEventsExists() {
		return this.consignmentSearchResultsWrapper.consignmentEvents
				? (this.consignmentSearchResultsWrapper.consignmentEvents.length > 0 ? true : false)
				: false;
	}

	handleLoading(event) {
		if (event.detail)
			this.isLoading = true;
		else
			this.isLoading = false;
	}

	handleSelectedConsignmentResults(event){
		//handle event to set the selected consignment results
		this.consignmentSearchResultsWrapper = event.detail;
	}

	onSelectedConsignmentError(event) {
		if (event.detail)
			this.errorMessages.push(event.detail);
		else
			this.errorMessages = [];
	}

	connectedCallback() {
		this.pushPageAnalyticsOnLoad();
	}

	pushPageAnalyticsOnLoad(){
		const pageData = {
			sitePrefix: 'auspost:bsp',
			pageAbort: 'true',
			pageName: this.pageName
		};
		analyticsTrackPageLoad(pageData);
	}

	get safeDropDownloadLoading(){
		return this._safeDropDownloadLoading;
	}

	/**
	 * @description Check the SafeDrop Image State of all articles given the provided trackingId and download the all images if not exists in Salesforce
	 * @param trackingIds
	 * @returns {Promise<void>}
	 */
	downloadSafeDropImage = async (trackingIds) => {
		this._safeDropDownloadLoading = true;
        // notify child components that safe drop images are loading
		this.notifyChildrenOfSafeDropImageLoadingState(true);
		
		// retrieve the current state of safe drop images caches in Salesforce
		const safeDropImageState = await getCurrentStateOfSafeDropImageRequiredForDownload({
			trackingId: trackingIds
		});
        
		// download safe drop images as required if they do not exist in Salesforce
		await this.processSafeDropImagesDownloading(safeDropImageState);
		
		this._safeDropDownloadLoading = false;
		// notify child components that safe drop images have completed loading
		this.notifyChildrenOfSafeDropImageLoadingState(false);
	}

	/**
	 * @description Download SafeDropImage in bulk by looping through the SafeDropState array object and split callout in multiple transactions.
	 *				This is in order to bypass the hard limit of 3 Max Continuation Callout per Single Transaction in Salesforce.
	 * @param {Array} safeDropImageState - The array of objects containing guidId and requireDownload
	 * @returns {Promise<void>}
	 */
	processSafeDropImagesDownloading = async (safeDropImageState) => {
		for (let i = 0; i < safeDropImageState.length; i++) {
			if (safeDropImageState[i].requireDownload) {
				try {
					const result = await getSafeDropImageForPOD({
						guidId: safeDropImageState[i].guidID,
						eventMessageId: safeDropImageState[i].eventMessageId
					});
					if (!result.isError) {
						safeDropImageState[i].requireDownload = false;
					}
				} catch (error) {
					console.error("Failed to download image for guidId:", safeDropImageState[i].guidID, error);
				}
			}
		}
    }


	renderedCallback() {
		// if the component rerenders and safedrop images haven't completed loading, notify child components
		if (this._safeDropDownloadLoading) {
			this.notifyChildrenOfSafeDropImageLoadingState(true);
		}
	}

	/**
	 * Notifies child components of the loading state of safe drop images
	 * 
	 * @param {boolean} isLoading 
	 */
	notifyChildrenOfSafeDropImageLoadingState(isLoading) {
		this.template.querySelectorAll("c-bsp-consignment-label-events").forEach((item) => {
			item.setSafeDropDownloadLoading(isLoading);
		});
		
		this.template.querySelectorAll("c-bsp-article-events").forEach((item) => {
			item.setSafeDropDownloadLoading(isLoading);
		});
	}
}