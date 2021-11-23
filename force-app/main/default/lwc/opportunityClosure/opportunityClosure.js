/* 
** Opportunity Closure Controller 
** Description: Controller used for the Opportunity Closure Component 
** Author: Lavanya Kavuri (lkavuri@salesforce.com)
****************************
** 05-03-2020 ---- Created ---- Lavanya Kavuri 
*/ 

import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord, updateOpptyRecord } from 'lightning/uiRecordApi';
import { objectInfo, getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//Opportunity Fields 
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
//Fields for getting the Piclist Values for Stage and Next Steps. 
import STAGENAME_FIELD from '@salesforce/schema/Opportunity.StageName';
import NEXTSTEP_FIELD from '@salesforce/schema/Opportunity.Next_Step__c';
import CLOSEREASON_FIELD from '@salesforce/schema/Opportunity.Closed_Reason__c';
import CLOSECOMMENTS_FIELD from '@salesforce/schema/Opportunity.Closed_Comments__c';

//Since we already have the information about the Opportunity, we can directly check the Complaince Field saving an Apex Call. 
import DATAINTEGRITY_FIELD from '@salesforce/schema/Opportunity.Data_Integrity_Compliance__c';
//Need this ID to Update the Data Check Field.
import OPPTYID_FIELD from '@salesforce/schema/Opportunity.Id';

//Fields required for the Opportunity Record Retrieve using the Standard getRecord API in LWC.
const OPPTYFIELDS = ['Opportunity.StageName', 'Opportunity.Data_Integrity_Compliance__c'];

//Methods from the Apex Class - OpportunityClosureController. 
import updateOpportunityStage from '@salesforce/apex/OpportunityClosureController.updateOpportunityStage';
import validateOpportunityStage from '@salesforce/apex/OpportunityClosureController.validateOpportunityStage';
import fetchOpenDSRRecords from '@salesforce/apex/OpportunityClosureController.getOpenDealSupportRequests';
import closeOpenDSRRecords from '@salesforce/apex/OpportunityClosureController.closeDealSupportRequests';

export default class OpportunityClosure extends LightningElement {

    //Columns for the DSR Records Lightning Data Table. 
    @track dsrColumns = [
        {
            label: 'Name',
            fieldName: 'Name',
            type: 'text',
            sortable: false
        },
        {
            label: 'Type',
            fieldName: 'Type',
            type: 'text',
            sortable: false
        },
        {
            label: 'Stage',
            fieldName: 'Stage',
            type: 'text',
            sortable: false
        },
        {
            label: 'Approval Status',
            fieldName: 'ApprovalStatus',
            type: 'text',
            sortable: false
        },

    ];
    /******** 
    * General Attributes for the LWC
    *********/ 
    @api recordId;
    @track opportunity;
    //Varialbe to store the current stage of the Opportunity 
    @track stageName;
    //Variable to show the Stage Name Picklist Values. 
    @track
    stageNameOptions = [
        { label: 'Closed Won', value: 'Closed Won' },
        { label: 'Closed Lost', value: 'Closed Lost' },
        { label: 'Closed Disqualified', value: 'Closed Disqualified' },
        { label: 'Closed Duplicate', value: 'Closed Duplicate' },
    ];

    //Varaialbe to show the Next Step Picklist Values.
    @track nextStepOptions;
    //Varaialbe to store the Selected Picklist value from the Stage Name Picklist
    @track selectedStageName;
    //Variable to store the Selected Next Step Value from the Next Step Picklist
    @track selectedNextStep;
    @track closeComments; 
    @track closeReason;
    @track closeReasonOptions;
    @track selectedCloseReason;
    
    //Vraiable to store the List of DSR Records from the Apex Controller method and to show the list on UI. 
    @track dsrRecordsList = [];
    //variable to show the Selected List of DSR Records in the UI for an update.
    @track selectedDSRRecords;
    @track errorMessage;
    //Lightning Progress indicator variables. 
    @track selectedStep = 'dataCheck';
    @track cssDisplay = '';
    @track dataCheckProgressBar = false; 
    @track dsrProgressBar = false;
    @track confirmationProgressBar = false;
    @track showValidateOptyButton = false;
    @track showCloseOptyButton = true;

    /******** 
    * Boolean Attributes that Toggle the UI 
    *********/ 
    //Toggles the Step1 to Proceed Opportunity Closure based on the Opportunity Stage 
    @track validStage = false;
    @track isOptyClose = false;
    //Toggles the Step1 to show the Stage and Next Steps Fields 
    @track showCloseFields = true;
    // Returns true if there are any Open Tasks for the Current Opportunity to Close.
    @track closureOpenTasks = false;
    // Returns true if the Data integrity Complaince Check is Completed. 
    @track isDataIntegrityCompleted = false;
    //Toggles the UI to show the Data Integrity Task 
    @track showDataCheck = false;
    // Returns true if there are any Open DSR Records. 
    @track isDSRClosed = true;
    //Toggles the UI to show the Open DSR Records. 
    @track showDSR = false;
    // Returns true if all tasks are completed and Opportunity is successfully closed.
    @track isAllDone = false;
    //Toggles the UI to show the Confiramtion Steps. 
    @track showConfirmation = false;

    @track showSpinner = false;

    //Button Disable Varaibles 
    @track disableValidateButton = true;
    @track disableDataCheckButton = true;
    @track disablePrevButton = true;

    @track errorString = [];
    @track tempErr;
    @track tempErr2;
    @track dataCheckSelection; 
    @track isDataChangeEvent = false; 
    
    //Get the Opportunity Details 
    @wire(getRecord, { recordId: '$recordId', fields: OPPTYFIELDS })
    wiredRecord({ error, data }) {
        this.showSpinner = true;
        if(error) {
            let message = 'Unknown Error';
            if(Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error in loading Opportunity Closure. Please try again later',
                    message,
                    variant: 'error',
                    mode: 'sticky'
                }),
            );
        } else if(data) {
            this.opportunity = data; 
            this.isDataIntegrityCompleted = this.opportunity.fields.Data_Integrity_Compliance__c.value;
            this.stageName = this.opportunity.fields.StageName.value;
            if(this.stageName === 'Propose' || this.stageName === 'Negotiate')
            {
                this.validStage = true;
            }
            if (this.stageName.match(/Close.*/))
            {
                this.isOptyClose = true; 
            }
            this.showSpinner = false;
        }
    }

    //Opportunity Object Information for getting the Picklist Values. 
    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opptyInfo;

    //Get the Next Step Picklist Values
    @wire(getPicklistValues, {
        recordTypeId: '$opptyInfo.data.defaultRecordTypeId',
        fieldApiName: NEXTSTEP_FIELD
    })
    nextStepFieldInfo({ data, error }){
        if(data) this.nextStepFieldData = data;
    }

    //Get the Close Reason Picklist values 
    @wire(getPicklistValues, {
        recordTypeId: '$opptyInfo.data.defaultRecordTypeId',
        fieldApiName: CLOSEREASON_FIELD
    })
    closeReasonFieldInfo({ data, error }){
        if(data) this.closeReasonOptions = data.values;
    }

    cancelClosure() {
        const closeComp = new CustomEvent('close');
        this.dispatchEvent(closeComp);
    }
    //Event when Close Reason Option is selected. 
    handleCloseReasonChange(event) {
        this.selectedCloseReason = event.detail.value;
    }
    //Even to get closed comments values 
    handleClosedComments(event)
    {
        this.closeComments = event.detail.value;
    }

    //Control the Picklist Dependencies for Next Step based on Stage Name 
    handleStageNameChange(event) {
        //Check for Valid Stage 
        this.nextStepOptions = '';
        this.selectedStageName = event.detail.value;

        //If Oppty Stage = Propose or Negotiate, we set validStage = true, then we close the opty as Closed Won 
        if(this.selectedStageName === 'Closed Won')
        {
            if(this.validStage)
            {
                let key = this.nextStepFieldData.controllerValues[event.target.value];
                this.nextStepOptions = this.nextStepFieldData.values.filter(opt => opt.validFor.includes(key));
                
                //this.disableValidateButton = false;
                //this.showValidateOptyButton = true;
                this.showCloseOptyButton = false;
            }
            else
            {
                this.showValidateOptyButton = false;
                this.showCloseOptyButton = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Invalid Selection',
                        message: 'Opportunity can be closed as won only when the Stage is Propose or Negotiate.',
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
            
        }
        else if(this.selectedStageName === 'Closed Lost' || this.selectedStageName === 'Closed Disqualified' || this.selectedStageName === 'Closed Duplicate')
        {
            let key = this.nextStepFieldData.controllerValues[event.target.value];
            this.nextStepOptions = this.nextStepFieldData.values.filter(opt => opt.validFor.includes(key));
            this.showCloseOptyButton = false;
           // this.showValidateOptyButton = false;
        }
        else
        {
           // this.showValidateOptyButton = false;
            this.showCloseOptyButton = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid Selection',
                    message: 'Please Select a Valid Stage',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }
    }
    //Event to get Next Step values 
    handleNextStepsChange(event) {
        this.selectedNextStep = event.detail.value;
    }
    //Event to toggle Next Button for Compliance Check
    handleDataCheckChange(event) {
        
        this.dataCheckSelection = event.target.checked;
        if(this.dataCheckSelection)
        {
            this.disableDataCheckButton = false; 
        }
        else
        {
            this.disableDataCheckButton = true;
        }
        this.isDataChangeEvent = true;
    }

    

    /*
    **** Function to ONLY Validate the Opporuntiy Closure. 
    ** 1. Checks for any Validation Errors, and throw them upfront before closing the Oppportunity.
    ** 2. This function does not save the Opportunity Records. 
    */ 
    validateOpportunity() {
        //Make sure they fill in all the required fields in the opportunity.
        if(this.selectedStageName == null || this.selectedNextStep == null || this.selectedCloseReason == null)
        {
            this.showConfirmation = true;
            this.isAllDone = false;
            this.isError = true;
            this.errorMessage = 'Please complete all the fields';

        }
        //Once we get all the required fields, we proceed... to validate..
        else 
        {
            this.showSpinner = true;
            validateOpportunityStage({            
                stageName: this.selectedStageName,
                nextSteps: this.selectedNextStep,
                closeComments: this.closeComments, 
                closeReason: this.selectedCloseReason,
                recordId: this.recordId
            })
            //All validations passed.. now proceed to check for Open Tasks
            .then(() => {

                this.checkOpenTasks();
            })
            .then(() => {
                this.showSpinner = false;

            })
            // Validations Failed.. Show whats the error...
            .catch((error) => {
                this.showSpinner = false;
                this.showCloseFields = true;
                this.selectedStep = 'confirmation';
                this.showConfirmation = true;
                this.isAllDone = false;
                this.isError = true;
                //this.errorMessage = error.body.message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            });
        }
    }

    /*
    **** Function to check for Opportunity Open Tasks before Closing. 
    ** 1. Checks if Compliance Check is required. 
    ** 2. Checks for any Open DSR Records are available to Close. 
    */ 
   checkOpenTasks() {
        this.showSpinner = true;
        //First Step is to check if there are any open DSR Records for this Opportunity.
        fetchOpenDSRRecords({ optyId: this.recordId})
        .then(result => {
            //No Results... Nothing to do with DSR. 
            if(result.length === 0)
            {
                this.isDSRClosed = true;
            }
            //Else, get the list into the Lightning Data Table to show it in the UI based on Stage Selction.
            else 
            {
                let currentData = [];
                result.forEach((row) => {
                    let rowData = {};
                    rowData.Id = row.Id;
                    rowData.Name = row.Name;
                    rowData.Stage = row.Stage;
                    rowData.Type = row.Type;
                    rowData.ApprovalStatus = row.ApprovalStatus; 
                    currentData.push(rowData);
                });
                this.dsrRecordsList = currentData;
                this.isDSRClosed = false;
            }
        })
        .then(() => {
            //Now, that we have the List, check for the Opportunity Stage Selected. 
            //If the Stage is Closed Won.... We show the Open Tasks. 
            this.showCloseFields = false;
            if(this.selectedStageName === 'Closed Won')
            {
                // Any one of the Open Tasks exist
                if(this.isDataIntegrityCompleted === false || this.isDSRClosed === false )
                {
                    //Set open tasks to true
                    this.closureOpenTasks = true;
                    //Check if both need to be shown....This is all UI Toggle stuff... 
                    if(this.isDataIntegrityCompleted === false && this.isDSRClosed === false)
                    {
                        this.showSpinner = false;
                        this.dataCheckProgressBar = true;
                        this.dsrProgressBar = true;
                        this.showDataCheck = true;
                        this.selectedStep = 'dataCheck';
                    }
                    //Only Compliance is required... 
                    else if(this.isDataIntegrityCompleted === false)
                    { 
                        this.showSpinner = false;
                        this.dataCheckProgressBar = true;
                        this.showDataCheck = true;
                        this.selectedStep = 'dataCheck';
                    }
                    //only DSR is required....
                    else if(this.isDSRClosed === false)
                    {
                        this.showSpinner = false;
                        this.showDSR = true;
                        this.dsrProgressBar = true;
                        this.selectedStep = 'dsrCheck';
                    }
                    this.confirmationProgressBar = true; 
                }
                //No Open Tasks.. Happy Days... Just Close the Opportunity
                else if(this.isDataIntegrityCompleted === true && this.isDSRClosed === true)
                {
                    this.showSpinner = false;
                    this.showConfirmation = true;
                    this.selectedStep = 'confirmation';
                    //We need to update the Opportunity and throw any validation errors 
                    this.closeOpportunity();
                }
            }
            //Stage is not Closed WON... so we dont need to worry about any open tasks.. just close the Opportunity
            else 
            {
                this.closureOpenTasks = true;
                if(this.isDSRClosed === false)
                {
                    this.showSpinner = false;
                    this.showDSR = true;
                    this.dsrProgressBar = true;
                    this.selectedStep = 'dsrCheck';
                    this.confirmationProgressBar = true; 
                }
                else
                {
                    this.showSpinner = false;
                    this.showConfirmation = true;
                    this.selectedStep = 'confirmation';
                    //Close it....
                    this.closeOpportunity();
                }
            }
            
        })
        .catch(error => {
            //this.errorMessage = error.body.message; 
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );           
        });
    }

    /*
    **** Function to Close the Opportunity. 
    ** 1. Checks for any Validation Errors, and throw them upfront before closing the Oppportunity.
    ** 2. This function does not save the Opportunity Records. 
    */ 

    closeOpportunity() {
        //Pretty simple method, get UI Fields, called the controller method, update Opportunity. 
        this.showSpinner = true;
        updateOpportunityStage({            
            stageName: this.selectedStageName,
            nextSteps: this.selectedNextStep,
            closeComments: this.closeComments, 
            closeReason: this.selectedCloseReason,
            recordId: this.recordId
        })
        .then(() => {
           this.showConfirmation = true;
            this.isAllDone = true;
            this.selectedStep = 'confirmation';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Opportunity Closed Successfully',
                    variant: 'success'
                })
            );
        })
        .then(() => {
            this.showSpinner = false;
            updateRecord({ fields: { Id: this.recordId } });
        })
        .catch((error) => {
            this.showSpinner = false;
            this.showCloseFields = true;
            this.selectedStep = 'confirmation';
            this.showConfirmation = true;
            this.isAllDone = false;
            this.isError = true;
            //this.errorMessage = error.body.message;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        });
    }

    /*
    **** Function to check for update the compliance check. 
    ** 1. Metod is triggered from the UI Button (Next) on the Data Check Step. 
    ** 2. Uses the standard UIRecordApi to update the opty record. 
    */ 
    updateDataCheck() {
        if(this.dataCheckSelection === true && this.isDataIntegrityCompleted === false )
            {
                //Do the update only if there is a Data Check Change
                this.showSpinner = true;
                const fields = {};
                fields[OPPTYID_FIELD.fieldApiName] = this.recordId;
                fields[DATAINTEGRITY_FIELD.fieldApiName] = this.dataCheckSelection;
                const recordInput = { fields };
                //Standard API Method to update record.
                updateRecord(recordInput)
                    //All done, show success
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Data Compliance Acknowledged',
                                variant: 'success'
                            })
                        );
                    })
                    .then(() => {
                        //Show next step, if there is a DSR Check 
                        if(this.isDSRClosed === false )
                        {
                            this.showDSR = true;
                            this.showDataCheck = false;
                            this.selectedStep = 'dsrCheck';
                        }
                        //If not, proceed to close opportunity
                        else 
                        {
                            this.selectedStep = 'confirmation';
                            this.showDataCheck = false;
                            this.closeOpportunity();
                        }
                    })
                    .catch(error => {
                        //Show errors if any..
                        this.showSpinner = false;                        
                        //this.errorMessage = error.body.message;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: this.errorMessage,
                                variant: 'error',
                                mode: 'sticky'
                            })
                        );
                        this.cssDisplay = 'hidemodel';
                    });
            }
           
    }

    /*
    **** Function to check for close the selected DSR Records. 
    ** 1. get the list of DSR Records selected. Send it to the Method in apex Controller.
    ** 2. close the DSR Records, and throw error if any.
    */ 

    updateDSRRecords() {
        this.showSpinner = true;
        //Selected records from the UI.
        var el = this.template.querySelector('lightning-datatable');
            var selected = el.getSelectedRows();
            var selectedJSONString = JSON.stringify(selected);
        //Calling the apex controller
        closeOpenDSRRecords({ dsrList: selected})
        .then(result => {
            //all good.. show successs
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Selected Deal Support Requests have been closed.',
                    variant: 'success'
                })
            );
        })
        .then(() => {
            this.showSpinner = false;
            this.showDSR = false;
            this.selectedStep = 'confirmation';
        })
        //dsr closed.. close the opportunity
        .then(() => {
            this.closeOpportunity();
        })
        //show errors if any
        .catch(error => {
            this.showSpinner = false;
            //this.errorMessage = error.body.message;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        });
    }

    handleFinish() {
        this.isAllDone = true;
    }

    datComplianceStep() {
        this.selectedStep = 'dataCheck';
    }
    dsrRecordsStep() {
        this.selectedStep = 'dsrCheck'; 
    }
    confirmationStep() {
        this.selectedStep = 'confirmation';
    }
    get isConfirmationStep() {
        return this.selectedStep === 'confirmation';
    }
}