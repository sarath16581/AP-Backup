/**
 *@author		:Jansi Rani. jansi.rani@auspost.com.au
 *@date			:23/07/2020
 *@description	:Component for enquiries list on home page.
 --------------------------------------- History --------------------------------------------------
 23.07.2020	Jansi Rani			Created
 05.10.2023	Hasantha Liyanage	Modified download all added extra columns
**/

import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import {checkAllValidity, scrollToHeight} from 'c/bspCommonJS';
import retrieveCases from '@salesforce/apex/bspEnquiryUplift.retrieveDisplayCaseList';
import downloadCaseDetails from '@salesforce/apex/bspEnquiryUplift.downloadCaseDetails';
import bulkCloseCase from '@salesforce/apex/bspEnquiryUplift.bulkCloseCase';
import bulkUpdateCases from '@salesforce/apex/bspEnquiryUplift.bulkUpdateCases';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';

export default class BspEnquiriesList extends LightningElement {

	@api searchText;
	@api orgFilterOption;
	@api billingAccFilterOption;
	@api statusFilterOption;
	@api enquiryTypeFilterOption;
	@api pageSizeFilterOption;
	@api fromdataFilterOption;
	@api toDateFilterOption;

	@api handleResetPagination() {
		this.pageNumber = 1;
		this.isLastPage = false;
		this.resultsSize = 0
		this.showPrevButton = false;
		this.showNextButton = false;
		this.recordStart = 0;
		this.recordEnd = 0;
		this.setError(null); 
		this.setLoadingStatus(true);
		this.setShowModalstatus(false);
		this.setShowCommentSuccessMessageStatus(false);
	}

	@track searchReultsWrapper;

	sortByColumnApiName = 'CreatedDate';
	sortByOrder = 'desc';
	pageNumber = 1;
	isLastPage = false;
	resultsSize = 0
	showPrevButton = false;
	showNextButton = false;
	recordStart = 0;
	recordEnd = 0;
	error;
	showModal = false;
	showCommentSuccessMsg = false;
	mainCheckboxVal = false;
	isLoading = true;
	wiredData;
	isAsc = false;
	isDsc = true;
	isCaseNumberSort = false;
	isTrackingNumSort = false;
	isCreatedDateSort = true;
	isServiceSort = false;
	isDetailsSort = false;
	isReceiverSort = false;
	isStatusSort = false;
	isUpdatedSort = false;
	isShowNoResultsFoundMsg = false;
	commentErrormsg;
	communityURL = '';

	get enquiryFilter(){
		return {
			searchStr: this.searchText,
			pageSize: this.pageSizeFilterOption,
			orgOption: this.orgFilterOption,
			billingAccOption: this.billingAccFilterOption,
			status: this.statusFilterOption,
			fromDate: this.fromdataFilterOption,
			toDate: this.toDateFilterOption,
			enquiryType: this.enquiryTypeFilterOption,
			pageNumber: this.pageNumber,
			sortByColumn: this.sortByColumnApiName,
			sortByOrder: this.sortByOrder
		};
	}

	/**
	 * wired method to fetch case results
	 */
	@wire(retrieveCases, {
		enquiryFilter : '$enquiryFilter'
	}) wiredCases(value) {
		// Hold on to the provisioned value so we can refresh it later.
		this.wiredData = value;
		// Destructure the provisioned value 
		const {
			data,
			error
		} = value;
		this.setError(null);
		this.mainCheckboxVal = false;
		if (data) {
			this.searchReultsWrapper = data.paginatedSearchResults;
			if (data.paginatedSearchResults.length > 0)
				this.isShowNoResultsFoundMsg = false;
			else
				this.isShowNoResultsFoundMsg = true;

			if (data.paginatedSearchResults.length <
				(data.totalSearchCount - ((this.pageNumber - 1) * this.pageSizeFilterOption))) {
				this.isLastPage = false;
			} else {
				this.isLastPage = true;
			}
			this.resultsSize = data.totalSearchCount;
			this.enableDisableNextPrevButtons();
			this.setLoadingStatus(false);
		} else if (error) {
			if (Array.isArray(error.body)) {
				this.setError(error.body.map(e => e.message).join(', '));
			} else if (typeof error.body.message === 'string') {
				this.setError(error.body.message);
			}
			this.setLoadingStatus(false);
		}

	}

	renderedCallback() {
		if(this.error) {
			scrollToHeight(this.template.querySelectorAll('[data-id="error"]'));
		}   
	}

	/*
		*clicking on previous button this method will be called
		*/
	previousHandler() {
		this.pageNumber = this.pageNumber - 1;
		this.setLoadingStatus(true);
	}

	/*
		*clicking on next button this method will be called
		*/
	nextHandler() {
		this.pageNumber = this.pageNumber + 1;
		this.setLoadingStatus(true);
	}

	/*
		*updating page status and enabling/disabling the navigation buttons
		*/
	enableDisableNextPrevButtons() {
		if (this.isLastPage)
			this.showNextButton = false;
		else
			this.showNextButton = true;

		if (this.pageNumber == 1)
			this.showPrevButton = false;
		else
			this.showPrevButton = true;

		if (this.pageNumber == 1)
			this.recordStart = 1;
		else
			this.recordStart = (this.pageNumber - 1) * parseInt(this.pageSizeFilterOption) + 1;

		if (this.pageNumber == 1)
			this.recordEnd = this.searchReultsWrapper.length; // this.data.length;
		else
			this.recordEnd = (parseInt(this.pageSizeFilterOption) * (this.pageNumber - 1)) + parseInt(this.searchReultsWrapper.length); //this.data.length);
	}


	/*
		*Download csv file
		*/
	downloadCaseDetailsCSV() {
		this.setError(null);
		this.setLoadingStatus(true);
		downloadCaseDetails({
			enquiryFilter: {
				searchStr: this.searchText,
				pageSize: this.pageSizeFilterOption,
				orgOption: this.orgFilterOption,
				billingAccOption: this.billingAccFilterOption,
				status: this.statusFilterOption,
				fromDate: this.fromdataFilterOption,
				toDate: this.toDateFilterOption,
				pageNumber: this.pageNumber,
				enquiryType: this.enquiryTypeFilterOption
			}

		}).then(result => {
			this.setLoadingStatus(false);
			const isAPUser = result.isAPUser;
			const data = result.caseDetails;//.replace(/\'/g, '"');  //[Jansi: added 'replace' to fix single quote issue in parsing]
			var reportData = JSON.parse(data);

			// CSV coulumn headers
			var csvString = '';
			csvString += " Enquiry Number,";
			csvString += " Date Created,";
			csvString += " Tracking Number,";
			if (isAPUser) {
				csvString += "Article ID,";
			}
			//csvString += " Service,";
			csvString += " Details,";
			csvString += " Receiver,";
			csvString += " Status ,";
			csvString += " Updated ,";
			csvString += " Account number,";
			csvString += " Account name,";
			csvString += " Account held with,\n";

			// prepare row data for columns
			for (var i = 0; i < reportData.length; i++) {
				csvString += this.cleanseText(reportData[i].EnquiryNo) + ",";
				csvString += this.cleanseText(reportData[i].DateCreated) + ",";
				csvString += this.cleanseText(reportData[i].TrackingNo) + ",";
				if (isAPUser) {
					csvString += this.cleanseText(reportData[i].ArticleID) + ",";
				}
				//csvString += this.cleanseText(reportData[i].Service) + ",";
				csvString += this.cleanseText(reportData[i].Details) + ",";
				csvString += this.cleanseText(reportData[i].SendingTo) + ",";
				csvString += this.cleanseText(reportData[i].Status) + ",";
				csvString += this.cleanseText(reportData[i].Updated) + ",";
				csvString += this.cleanseText(reportData[i].AccountNumber) + ",";
				csvString += this.cleanseText(reportData[i].AccountName) + ",";
				csvString += this.cleanseText(reportData[i].AccountHeldWith) + ",\n";
			}

			var currTime = new Date();
			var tStamp = ((currTime.toString()).replace(/[\s:]/g, '')).substr(3, 13);

			if (navigator.msSaveBlob) { // IE10+
				return navigator.msSaveBlob(new Blob([csvString], { type: '.csv' }), 'Customer_Case_Summary_Report_' + tStamp + '.csv');
			}

			// prepare to download as a CSV file
			var downloadElement = document.createElement('a');
			downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
			downloadElement.target = '_self';

			downloadElement.download = 'Customer_Case_Summary_Report_' + tStamp + '.csv';
			document.body.appendChild(downloadElement);
			downloadElement.click();
		}).catch(error => {
			console.log('error=' + error);
			this.setLoadingStatus(false);
			this.setError(error);
		});
	}

	/**
	 * Adds escape quotes for strings that have comma and double quote
	 * @param inStr
	 * @returns {string}
	 */
	cleanseText(inStr) {
		if (typeof inStr === 'undefined' || inStr === null) {
			inStr = '-';
		}
		var txt = '' + inStr;
		// Drop the special characters which mess with encodeURI() method, such as #
		if (txt.search(/[#]/) != -1) {
			txt = txt.replace('#', '');
		}
		if (txt.search(/[,"]/) != -1) {
			return "\"" + txt + "\"";
		} else {
			return txt;
		}
	}

	/*
		*Resolve Enquiries methos
		*/
	handleResolveEnquiries() {
		this.setError(null);
		if (this.validateSelectedCases()) {
			this.setLoadingStatus(true);
			this.setError(null);
			bulkCloseCase({
					casesJsonStr: JSON.stringify(this.searchReultsWrapper)
				})
				.then(result => {
					refreshApex(this.wiredData);
					this.setLoadingStatus(false);
				})
				.catch(error => {
					this.setError(error.body.message);
					this.setLoadingStatus(false);
				});
		} else {
			this.setError('Please select enquiries to close.');
		}
	}

	/*
		*method to hanlde case selection/deselection
		*/
	handleChangeSelection(event) {
		this.setError(null);
		const cWrapper = event.detail.caseWrapper;
		const copyWrapper = [...this.searchReultsWrapper];
		const index = copyWrapper.findIndex(p => p.caseObj.Id === cWrapper.caseObj.Id);
		// cWrapper.isSelected = event.detail.isSelected;
		if (index === -1) {
			copyWrapper.push(cWrapper);
		} else {
			copyWrapper[index] = cWrapper;
		}
		this.searchReultsWrapper = copyWrapper;
		this.updateMainSelect();
	}

	/*
		*method to open popup for adding a comment
		*/
	handleAddComment() {
		this.setError(null);
		if (this.validateSelectedCases()) {
			this.setShowModalstatus(true);
		} else {
			this.setError('Please select enquiries to update.');
		}
	}

	/*
		*validation to checke wheather any case(s) are selected o not
		*/
	validateSelectedCases() {
		for (var cc = 0; cc < this.searchReultsWrapper.length; cc++) {
			if (this.searchReultsWrapper[cc].isSelected && this.searchReultsWrapper[cc].caseObj.Status != 'Closed') {
				return true;
			}
		}
		return false;
		/*return this.searchReultsWrapper.forEach(function (cc) {
			if (cc.isSelected && cc.caseObj.Status != 'Closed') {
				return true;
			}
		}, false)*/
	}

	/*
		*getter for mpdal popup
		*/
	get isModalOpen() {
		return this.showModal ? true : false;
	}

	/*
		*close method of mpdal popup
		*/
	closeModal() {
		this.commentErrormsg = null;
		this.setShowModalstatus(false);
		this.setShowCommentSuccessMessageStatus(false);
		this.refresh(); //-- No need this as we didnt change any data
	}

	/*
		*sumit  method of comments
		*/
	submitComments(event) {
		const inputCmp = this.template.querySelector('[data-id="comment"]');
		if (inputCmp != undefined) {
			if (inputCmp.checkValidity()) {
				this.setLoadingStatus(true);
				this.commentErrormsg = null;
				//-- submit comment
				bulkUpdateCases({
					casesJsonStr: JSON.stringify(this.searchReultsWrapper),
					caseCommentBulk: inputCmp.value
				}).then(result => {
					this.setShowCommentSuccessMessageStatus(true);
					this.setLoadingStatus(false);
				}).catch(error => {
					this.commentErrormsg = error.body.message;
					this.setLoadingStatus(false);
				});
			} else {
				inputCmp.reportValidity();
			}
		}
	}

	setLoadingStatus(isLoad) {
		this.isLoading = isLoad;
	}

	setShowCommentSuccessMessageStatus(status) {
		this.showCommentSuccessMsg = status;
	}

	refresh() {
		return refreshApex(this.wiredData);
	}

	setShowModalstatus(status) {
		this.showModal = status;
	}

	setError(errorMsg) {
		//const errorCmp = this.template.querySelectorAll('[data-id="error"]');
		this.error = errorMsg;
	}

	/*
		*handle the main select checkbox
		*/
	handleAllSelect(event) {
		let copyWrapper = [...this.searchReultsWrapper];
		copyWrapper.forEach((wrapper, index) => {
			var copy = Object.assign({}, wrapper);
			if (copy.caseObj.Status != 'Closed') // && !copy.isSelected
				copy.isSelected = event.target.checked;
			copyWrapper[index] = copy;
		});
		this.searchReultsWrapper = null;
		this.searchReultsWrapper = copyWrapper;
		this.mainCheckboxVal = event.target.checked;
	}

	/*
		*update the main select checkbox
		*/
	updateMainSelect() {
		let allChecked = true;
		this.searchReultsWrapper.forEach(function (wrapper, index) {
			if (wrapper.caseObj.Status != 'Closed' && !wrapper.isSelected) {
				allChecked = false;
			}
		});
		this.mainCheckboxVal = allChecked;

	}
	/*
		*sorting
		*/
	sortCaseNumber(event) {
		this.isCaseNumberSort = true;
		this.isTrackingNumSort = false;
		this.isCreatedDateSort = false;
		this.isServiceSort = false;
		this.isDetailsSort = false;
		this.isReceiverSort = false;
		this.isStatusSort = false;
		this.isUpdatedSort = false;
		this.sortData(event.currentTarget.dataset.id);
	}

	sortCreatedDate(event) {
		this.isCaseNumberSort = false;
		this.isTrackingNumSort = false;
		this.isCreatedDateSort = true;
		this.isServiceSort = false;
		this.isDetailsSort = false;
		this.isReceiverSort = false;
		this.isStatusSort = false;
		this.isUpdatedSort = false;
		this.sortData(event.currentTarget.dataset.id);
	}

	sortTrackingNumber(event) {
		this.isCaseNumberSort = false;
		this.isTrackingNumSort = true;
		this.isCreatedDateSort = false;
		this.isServiceSort = false;
		this.isDetailsSort = false;
		this.isReceiverSort = false;
		this.isStatusSort = false;
		this.isUpdatedSort = false;
		this.sortData(event.currentTarget.dataset.id);
	}

	sortService(event) {
		this.isCaseNumberSort = false;
		this.isTrackingNumSort = false;
		this.isCreatedDateSort = false;
		this.isServiceSort = true;
		this.isDetailsSort = false;
		this.isReceiverSort = false;
		this.isStatusSort = false;
		this.isUpdatedSort = false;
		this.sortData(event.currentTarget.dataset.id);
	}

	sortDetails(event) {
		this.isCaseNumberSort = false;
		this.isTrackingNumSort = false;
		this.isCreatedDateSort = false;
		this.isServiceSort = false;
		this.isDetailsSort = true;
		this.isReceiverSort = false;
		this.isStatusSort = false;
		this.isUpdatedSort = false;
		this.sortData(event.currentTarget.dataset.id);
	}

	sortReceiver(event) {
		this.isCaseNumberSort = false;
		this.isTrackingNumSort = false;
		this.isCreatedDateSort = false;
		this.isServiceSort = false;
		this.isDetailsSort = false;
		this.isReceiverSort = true;
		this.isStatusSort = false;
		this.isUpdatedSort = false;
		this.sortData(event.currentTarget.dataset.id);
	}
	sortStatus(event) {
		this.isCaseNumberSort = false;
		this.isTrackingNumSort = false;
		this.isCreatedDateSort = false;
		this.isServiceSort = false;
		this.isDetailsSort = false;
		this.isReceiverSort = false;
		this.isStatusSort = true;
		this.isUpdatedSort = false;
		this.sortData(event.currentTarget.dataset.id);
	}
	sortUpdated(event) {
		this.isCaseNumberSort = false;
		this.isTrackingNumSort = false;
		this.isCreatedDateSort = false;
		this.isServiceSort = false;
		this.isDetailsSort = false;
		this.isReceiverSort = false;
		this.isStatusSort = false;
		this.isUpdatedSort = true;
		this.sortData(event.currentTarget.dataset.id);
	}

	/*
		*Update the sort column and sort order
		*/
	sortData(sortColumnName) {
		//[Jansi: 20-08-2020] Added the below line to fix sort pagination message issue
		this.handleResetPagination();
		this.setLoadingStatus(true);
		// check previous column and direction
		if (this.sortByColumnApiName === sortColumnName) {
			this.sortByOrder = this.sortByOrder === 'asc' ? 'desc NULLS LAST' : 'asc';
		} else {
			this.sortByOrder = 'asc';
		}

		// check arrow direction
		if (this.sortByOrder === 'asc') {
			this.isAsc = true;
			this.isDsc = false;
		} else {
			this.isAsc = false;
			this.isDsc = true;
		}
		this.sortByColumnApiName = sortColumnName;
	}


}