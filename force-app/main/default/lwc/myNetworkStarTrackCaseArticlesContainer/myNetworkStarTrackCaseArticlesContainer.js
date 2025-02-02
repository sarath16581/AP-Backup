/**
* @changelog
* 2023-03-16 - Mahesh Parvathaneni - SF-862 Added logic to refresh the primary tab after successful case investigation creation
* 2023-04-03 - Mahesh Parvathaneni - SF-948 Added validation for case type
*/
import {
	api,
	track,
	LightningElement
} from 'lwc';
import {
	CONSTANTS,
	getArticles,
	submitCaseInvestigations
} from 'c/myNetworkStarTrackCaseArticlesService';
import LightningAlert from 'lightning/alert';

export default class MyNetworkStarTrackCaseArticlesContainer extends LightningElement {

	@api recordId; //case id
	@track articleDetails; //articles related to case from apex
	@track articleDetailsToDisplay = []; //articles to display
	hasPassedThroughAPNetwork = false; //flag to determine the articles passed through AP Network scans
	isLoading = false; //flag to show/hide the spinner on server call
	selectedRecords = []; //selected records to save 
	currentPage = 1; //default page number on load
	totalPages; //total pages
	recordsPerPage = 5; //records displayed per page
	totalRecords; //total records
	comments; //chatter feed
	hasCaseTypeBlankOnCase; //flag to check the case type blank on startrack case
	receiverPostcode; //receiver post code on case
	receiverSuburb; //receiver suburb on case

	// expose custom labels
	label = {
		consignmentErrorMessage: CONSTANTS.LABEL_CONSIGNMENT_ERROR_MESSAGE,
		caseInvestigationSuccessMessage: CONSTANTS.LABEL_CASE_INVESTIGATION_SUCCESS_MESSAGE,
		invalidCaseInvestigationErrorMessage: CONSTANTS.LABEL_INVALID_CASE_INVESTIGATION_ERROR_MESSAGE,
		invalidNetworkErrorMessage: CONSTANTS.LABEL_INVALID_NETWORK_ERROR_MESSAGE,
		blankNetworkErrorMessage: CONSTANTS.LABEL_BLANK_NETWORK_ERROR_MESSAGE,
		blankCaseTypeErrorMessage: CONSTANTS.LABEL_BLANK_CASE_TYPE_ERROR_MESSAGE
	};

	connectedCallback() {
		this.loadArticles();
	}

	//load the articles related to case
	loadArticles() {
		this.resetPageDetails();
		this.isLoading = true;
		//get articles related to case
		getArticles(this.recordId)
			.then(response => {
				this.hasPassedThroughAPNetwork = response.hasPassedThroughAPNetwork;
				this.hasCaseTypeBlankOnCase = response.hasCaseTypeBlankOnCase;
				this.receiverPostcode = response.receiverPostcode;
				this.receiverSuburb = response.receiverSuburb;
				if (this.hasPassedThroughAPNetwork) {
					this.articleDetails = response.articleDetails;
					this.totalRecords = response.articleDetails.length;
					this.totalPages = Math.ceil(this.totalRecords / this.recordsPerPage);
					this.setRecordsToDisplay();
				}
				this.isLoading = false;
			})
			.catch(error => {
				this.isLoading = false;
				console.error('getArticles call failed: ' + error);
			})
	}

	//load the records for the table
	setRecordsToDisplay() {
		this.articleDetailsToDisplay = [];
		for (let index = (this.currentPage - 1) * this.recordsPerPage; index < this.currentPage * this.recordsPerPage; index++) {
			if (index === this.totalRecords) {
				break;
			}
			this.articleDetailsToDisplay.push(this.articleDetails[index]);
		}
	}

	//handler for pageclick event from the paginator component
	handlePageClick(event) {
		this.currentPage = event.detail.pageNumber;
		this.setRecordsToDisplay();
	}

	//handler for rowselect event from the child
	handleRowSelect(event) {
		this.selectedRecords = event.detail.selectedRows;
	}

	//reset the selected records, errors etc
	resetPageDetails() {
		this.selectedRecords = [];
	}

	//handler for comments
	handleCommentsChange(event) {
		this.comments = event.detail.value;
	}

	//validate the records
	isValidRecords() {
		let isValid = true;
		this.selectedRecords.forEach(rec => {
			if (rec.networks && rec.networks.length > 0) {
				rec.networks.forEach(network => {
					//throw error message when selected record network is not related to MyNetwork
					if (network.contactMethod !== CONSTANTS.MY_NETWORK) {
						isValid = false;
						LightningAlert.open({
							message: `${network.label} ` + this.label.invalidNetworkErrorMessage,
							theme: 'error', // a red theme intended for error states
							label: 'Error', // this is the header text
						});
					}
				})
			} else {
				isValid = false;
				LightningAlert.open({
					message: this.label.blankNetworkErrorMessage + ` ${rec.referenceId} `,
					theme: 'error', // a red theme intended for error states
					label: 'Error', // this is the header text
				});
			}
		});
		return isValid;
	}

	//submit the case investigation records
	handleSubmitClick(event) {
		if (this.selectedRecords.length > 0) {
			let recordsToSave = [];
			//validate records
			if (this.isValidRecords()) {
				this.isLoading = true;
				this.selectedRecords.forEach(rec => {
					rec.networks.forEach(network => {
						let caseInvestigationRec = {
							Case__c: this.recordId,
							Network__c: network.name,
							ReferenceID__c: rec.referenceId,
							sobjectType: 'CaseInvestigation__c'
						}
						recordsToSave.push(caseInvestigationRec);
					})
				});
				
				//save the case investigations
				submitCaseInvestigations(recordsToSave, this.comments)
					.then(response => {
						if (response.status === 'SUCCESSFUL') {
							LightningAlert.open({
								message: this.label.caseInvestigationSuccessMessage,
								theme: 'success', // a green theme intended for success states
								label: 'Success', // this is the header text
							}).then(() => {
								//dispatches event to the vf page to refresh the primary tab
								this.dispatchEvent(new CustomEvent('refreshprimarytab', {
									bubbles: true,
									composed: true
								}));
								this.isLoading = false;
							});
						} else {
							LightningAlert.open({
								message: response.errorMessage,
								theme: 'error', // a red theme intended for error states
								label: 'Error', // this is the header text
							});
							this.resetPageDetails();
							this.isLoading = false;
						}
					})
					.catch(error => {
						this.isLoading = false;
						console.error('submitCaseInvestigations call failed: ' + error);
						LightningAlert.open({
							message: error.body.message,
							theme: 'error', // a red theme intended for error states
							label: 'Error', // this is the header text
						});
					})
			}

		} else {
			LightningAlert.open({
				message: this.label.invalidCaseInvestigationErrorMessage,
				theme: 'error', // a red theme intended for error states
				label: 'Error', // this is the header text
			});
		}
	}
}