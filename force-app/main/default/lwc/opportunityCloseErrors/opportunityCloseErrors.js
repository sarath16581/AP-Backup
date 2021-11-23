/*
/* @author 
 * @date 2020-07-28
 * @group Opportunities
 * @tag Opportunity
 * @description OpportunityValidationErrors js file used to parse the validation messages received by included vf page in iframe 
 *              and display it in UI on Opportunity detail page
 * @changelog
 * 2020-07--28 vcheng Created
 * 2020-08-16 - arjun.singh@auspost.com.au - Modified to include OpportunityValidationErros vf page which in turns pass all the possibe
 *                                           validation errors to lwc component
 *
 */  

import {LightningElement, track, api, wire} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
const STAGE_NAME_FIELD = 'Opportunity.StageName';
const OPPTYFIELDS = [STAGE_NAME_FIELD, 'Opportunity.Name'];

export default class OpportunityCloseErrors extends LightningElement {

    @api recordId;
    @track oppty;

    // loading spinner
    @track showSpinner = true;

    // if already closed
    @track opptyIsClosed = false;

    // overall status for progression
    @track validForProgress = false;
    @track progressErrors;
    @track progressErrs=[];

    @track opptyId = '';
    @track currentStage;
    @track nextStage;
    @track oppRecord;
    @track dynamicInstanceName;
    @track vfOrigin;
    @wire(getRecord, { recordId: '$recordId', fields: OPPTYFIELDS })
    getOpptyData({ data, error }) {
        // Pass the message to include vf page to refresh the component when opportunity record is edit/save
        // This will allow component to refresh it automatically on opportunity record edit/save
        if(this.progressErrors && this.vfOrigin){
            this.showSpinner = true;
            let message = 'Refresh';
            this.template.querySelector('iframe').contentWindow.postMessage(message, this.vfOrigin);
        }        
    }
    constructor() {
        super();
        this.constructVisualForcePageUrl();
    }
    connectedCallback(){
        this.opptyId = this.recordId;
        /* listener to capture validation message from include vf page as lwc can not capture all 
         the possibe validation messages using dml.update. Hence vf page apex.message() feature is used to 
         capture all the possible validation message and pass it back to component using postMessage   
         */
        window.addEventListener("message", (event)=>{
            let eventOriginStr = event.origin;
            // Handle the message
            if(event.data.currentStage == 'Negotiate'){
                this.vfOrigin = eventOriginStr ;
                this.getValidationMessage(event.data);
            }
            
        });
    }
    /**
     * @description capture the salesforce base instance used for postMessage communication between lwc and include vf page
     */
    constructVisualForcePageUrl(){
        this.dynamicInstanceName = window.location.origin;
    }
    /**
     * @Description : Generate the vf page url dynamically and used to load in iframe.
     */
    get fullUrl() {
        let instanceUrl = window.location.origin;
        this.constructVisualForcePageUrl();
        let pageUrl = this.dynamicInstanceName + '/apex/OpportunityValidationErrors?id=';
        pageUrl = pageUrl + this.recordId ;
        return pageUrl;
    }
    /**
     * @description : Parse all the validation message and store in an arrary to display in UI.     
     */
     getValidationMessage(result) {
         // store the oppty stage
         this.currentStage = result.currentStage;
         if(result.nextStage == '')
         {
             // oppty is closed, nothing to progress
             this.opptyIsClosed = true;
         }
         else
         {              
             // store the target stage
             this.nextStage = result.nextStage;

             // overall save result
             let resultStatus = result.status;
             if('error' == resultStatus)
             {
                 // display the errors
                 this.validForProgress = false;
                 this.progressErrors = result.errors;
                 this.progressErrs = [];
                 this.progressErrors.forEach((errMsg)=>{   
                    var eMsg = errMsg.replace(/&quot;/g,'\'');
                    var eMsgVar = eMsg.replace(/amp;/g,'');
                    this.progressErrs.push(eMsgVar);
                 })
             }
             else
             {
                 // no errors
                 console.log('no error');
                 this.validForProgress = true;
             }

             this.opptyIsClosed = false;
         }


         // early out
         this.showSpinner = false;
     }

     
}