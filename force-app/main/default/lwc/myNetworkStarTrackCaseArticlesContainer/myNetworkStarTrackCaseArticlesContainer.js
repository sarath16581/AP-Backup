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
    hasPassedThroughAPNetwork = false; //flag to determine the articles passed through AP Network scans
    isLoading = false; //flag to show/hide the spinner on server call
    selectedRecords = []; //selected records to save 
    currentPage = 1; //default page number on load
    totalPages; //total pages
    recordsPerPage = 5; //records displayed per page
    totalRecords; //total records
    @track articleDetailsToDisplay = []; //articles to display

    // expose custom labels
	label = {
		consignmentErrorMessage: CONSTANTS.LABEL_CONSIGNMENT_ERROR_MESSAGE,
		caseInvestigationSuccessMessage: CONSTANTS.LABEL_CASE_INVESTIGATION_SUCCESS_MESSAGE,
        invalidCaseInvestigationErrorMessage: CONSTANTS.LABEL_INVALID_CASE_INVESTIGATION_ERROR_MESSAGE
	};

    connectedCallback() {
        this.loadArticles();
    }

    //load the articles related to case
    loadArticles() {
        this.isLoading = true;
        //get articles related to case
        getArticles(this.recordId)
            .then(response => {
                this.hasPassedThroughAPNetwork = response.hasPassedThroughAPNetwork;
                if (this.hasPassedThroughAPNetwork) {
                    this.articleDetails = response.articleDetails;
                    this.totalRecords = response.articleDetails.length;
                    this.totalPages = Math.ceil(this.totalRecords / this.recordsPerPage);
                    this.setRecordsToDisplay();
                    //this.articleDetails = response.articleDetails;
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                console.error('getArticles call failed: ' + error);
            })
    }

    setRecordsToDisplay() {
        this.articleDetailsToDisplay = [];
        for (let index = (this.currentPage - 1) * this.recordsPerPage; index < this.currentPage * this.recordsPerPage; index++) {
            if (index === this.totalRecords) {
                break;
            }
            this.articleDetailsToDisplay.push(this.articleDetails[index]);
        }
    }

    handlePageClick(event) {
        this.currentPage = event.detail.pageNumber;
        this.setRecordsToDisplay();
    }

    //handler for rowselect event from the child
    handleRowSelect(event) {
        this.selectedRecords = event.detail.selectedRows;
    }

    resetPageDetails() {
        this.selectedRecords = [];
    }

    //submit the case investigation records
    handleSubmitClick(event) {
        if (this.selectedRecords.length > 0) {
            this.isLoading = true;
            let recordsToSave = [];
            this.selectedRecords.forEach(rec => {
                rec.networkIds.forEach(network => {
                    let caseInvestigationRec = {
                        Article__c: rec.articleId,
                        Case__c: this.recordId,
                        Network__c: network,
                        sobjectType: 'CaseInvestigation__c'
                    }
                    recordsToSave.push(caseInvestigationRec);
                })
            });

            //save the case investigations
            submitCaseInvestigations(recordsToSave)
                .then(response => {
                    if (response.status === 'SUCCESSFUL') {
                        LightningAlert.open({
                            message: this.label.caseInvestigationSuccessMessage,
                            theme: 'success', // a green theme intended for success states
                            label: 'Success', // this is the header text
                        });
                        this.loadArticles();
                    } else {
                        LightningAlert.open({
                            message: response.errorMessage,
                            theme: 'error', // a red theme intended for error states
                            label: 'Error', // this is the header text
                        });
                    }
                    this.resetPageDetails();
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
        } else {
            LightningAlert.open({
                message: this.label.invalidCaseInvestigationErrorMessage,
                theme: 'error', // a red theme intended for error states
                label: 'Error', // this is the header text
            });
        }
    }
}