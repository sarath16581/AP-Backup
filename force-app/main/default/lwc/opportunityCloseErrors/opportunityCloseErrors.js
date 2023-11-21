/*
/* @author 
 * @date 2020-07-28
 * @group Opportunities
 * @tag Opportunity
 * @description LWC used in Opportunity record pages in Lightning to surface all applicable validation errors when attempting
 *				to progress to next stage in sales pipeline. Validation errors are displayed to users when viewing opportunity
 *				so any pending actions can be taken proactively to progress opportunity to next stage.
 *
 *				Visualforce page (OpportunityValidationErrors.page) embedded in an iframe is used to make a dummy update
 *				to the opportunity setting the stage to next stage in sales pipeline. This is to ensure all validation
 *				errors are captured including rules implemented as validation rules (config) and in apex code (triggers).
 *
 *				Visualforce context is required so that all errors added in apex code (via SObject.addError) can be retrieved
 *				via the Database.SaveResult. For any other request contexts only a subset of errors added via SObject.addError is
 *				returned in Database.SaveResult (Please refer for more information:
 *				https://salesforce.stackexchange.com/questions/237042/adderror-on-an-object-in-a-trigger-is-only-displaying-one-of-the-errors-in-objec)
 * @changelog
 * 2020-07--28 vcheng Created
 * 2020-08-16 - arjun.singh@auspost.com.au - Modified to include OpportunityValidationErros vf page which in turns pass all the possibe
 *										   validation errors to lwc component
 * 2023-08-18 - Ranjeewa Silva - Updated to display validation errors when moving to next stage for opportunities in any stage.
 * 2023-10-16 - Mahesh Parvathaneni - Updated populateValidationErrorResults to check for new line in the error message
 * 2023-10-20 - Mahesh Parvathaneni - Updated populateValidationErrorResults to unescape greater than symbol in html
 */

import {LightningElement, api, wire} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import FIELD_OPPORTUNITY_ISCLOSED from '@salesforce/schema/Opportunity.IsClosed';
import FIELD_OPPORTUNITY_STAGE from '@salesforce/schema/Opportunity.StageName';
import FIELD_OPPORTUNITY_ID from '@salesforce/schema/Opportunity.Id';
import FIELD_OPPORTUNITY_RECORDTYPEID from '@salesforce/schema/Opportunity.RecordTypeId';
import LABEL_OPPORTUNITYTRACKERTITLE from '@salesforce/label/c.SalesPipelineOpportunityTrackerTitle';
import getConfig from '@salesforce/apex/OpportunityCloseErrorsController.loadConfig';

export default class OpportunityCloseErrors extends LightningElement {

	// record id set by Lightning framework
	@api recordId;

	// opportunity record corresponding to the record id
	_opportunity;

	// opportunity record type id. used to retrieve picklist values for Opportunity.StageName
	_recordTypeId;

	// mapping of each opportunity stage to next stage (based on the picklist value ordering)
	_pathNextStageMapping;

	// title of the component
	headerTitle = LABEL_OPPORTUNITYTRACKERTITLE;

	// loading spinner
	showSpinner = true;

	// list of validation error messages received when attempting to progress opportunity stage
	progressErrs=[];

	// error message in case of an unexpected exception attempting to validate opportunity progress
	errorMessage;

	// visualforce origin to be used when embedding visualforce page in iframe
	vfOrigin;

	// indicates visualforce page is loaded and ready to accept messages from this LWC
	vfPageLoaded;

	@wire(getRecord, { recordId: '$recordId', fields: [FIELD_OPPORTUNITY_ID, FIELD_OPPORTUNITY_STAGE, FIELD_OPPORTUNITY_ISCLOSED, FIELD_OPPORTUNITY_RECORDTYPEID] })
	getOpptyData({ data, error }) {
		if (data) {
			this._opportunity = {};
			this._opportunity[FIELD_OPPORTUNITY_ID.fieldApiName] = data.id;
			this._opportunity[FIELD_OPPORTUNITY_ISCLOSED.fieldApiName] = getFieldValue(data, FIELD_OPPORTUNITY_ISCLOSED);
			this._opportunity[FIELD_OPPORTUNITY_STAGE.fieldApiName] = getFieldValue(data, FIELD_OPPORTUNITY_STAGE);
			this._opportunity[FIELD_OPPORTUNITY_RECORDTYPEID.fieldApiName] = getFieldValue(data, FIELD_OPPORTUNITY_RECORDTYPEID);

			// note that use of 'defaultRecordTypeId' returned by 'getObjectInfo' is not appropriate in this use case.
			// getObjectInfo returns the default record type configured on user's profile. 'master' record type id
			// (i.e. '012000000000000AAA') is returned only when no default record type is configured on profile.
			// in this particular scenario, user is viewing an opportunity where record type id is not set. we use
			// 'master' record type id to retrieve picklist values.
			this._recordTypeId = (this._opportunity[FIELD_OPPORTUNITY_RECORDTYPEID.fieldApiName]) ? (this._opportunity[FIELD_OPPORTUNITY_RECORDTYPEID.fieldApiName]) : '012000000000000AAA';

			// post message to vf page to get validation errors
			this.publishMessageToVFPage();
		} else if (error) {
			console.error(error);
		}
	}

	connectedCallback(){
		getConfig().then(result => {
			this.vfOrigin = 'https://' + result.visualforceHostname;
		});
		// add listener to receive messages from visualforce page
		window.addEventListener("message", this.receiveMessageListener);
	}

	disconnectedCallback() {
		//remove listener
		window.removeEventListener("message", this.receiveMessageListener);
	}

	/**
	 * Listener for incoming messages from visualforce page
	 */
	receiveMessageListener = (event) => {

		if (event.origin !== this.vfOrigin) {
			// Not the expected origin: reject message!
			return;
		}

		if (event.data.origin === 'page.OpportunityValidationErrors' && this.recordId === event.data.recordId) {
			if (event.data.type === 'loadComplete' && !this.vfPageLoaded) {
				this.vfPageLoaded = true;
				this.publishMessageToVFPage();
			} else if (event.data.type === 'validationResults') {
				this.populateValidationErrorResults(event.data.payload);
			}
		}
	}

	/**
	 * Generate the vf page url dynamically and used to load in iframe.
	 */
	get fullUrl() {
		if (this.recordId && this.vfOrigin) {
			return this.vfOrigin + '/apex/OpportunityValidationErrors?id=' + this.recordId;
		}
		return '';
	}

	/**
	 * Parse all the validation message and store in an array to display in UI.
	 */
	populateValidationErrorResults(result) {

		this.errorMessage = (result.errorMessage ? result.errorMessage : null);

		this.progressErrs = [];
		if(result.validationMessages) {
			result.validationMessages.forEach((errMsg)=>{
				errMsg = errMsg.replace(/&quot;/g,'\'');
				errMsg = errMsg.replace(/amp;/g,'');
				errMsg = errMsg.replace(/&gt;/g , ">");
				let eMsgArray = errMsg.split(/\n/);
				eMsgArray.forEach(eMsgVal => {
					this.progressErrs.push(eMsgVal);
				})
			});
		}

		this.showSpinner = false;
	}

	get headerIconStyleClass() {
		if (!this.isClosed && this.hasProgressErrors) {
			return 'path-red';
		}
		return 'path-green';
	}

	get isClosed() {
		return (this._opportunity && this._opportunity[FIELD_OPPORTUNITY_ISCLOSED.fieldApiName]);
	}

	get hasProgressErrors() {
		return (this.progressErrs && this.progressErrs.length > 0);
	}

	get currentStage() {
		return (this._opportunity ? this._opportunity[FIELD_OPPORTUNITY_STAGE.fieldApiName] : '');
	}

	get nextStage() {
		return (this._pathNextStageMapping && this._pathNextStageMapping[this.currentStage] ? this._pathNextStageMapping[this.currentStage] : '');
	}

	handleRefresh() {
		this.publishMessageToVFPage();
	}

	/**
	 * Publish message to visualforce page to refresh validation messages.
	 */
	publishMessageToVFPage() {
		if (this.isClosed) {
			this.showSpinner = false;
			return;
		}

		if (this.currentStage && this.nextStage && this.vfOrigin && this.vfPageLoaded) {
			this.showSpinner = true;
			const message = {
				name: 'refreshValidationErrors',
				id: this.recordId,
				nextStage: this.nextStage
			};
			this.template.querySelector('iframe').contentWindow.postMessage(message, this.vfOrigin);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$_recordTypeId', fieldApiName: 'Opportunity.StageName'})
	getPicklistValues({ error, data }) {
		if (data && data.values && !this._pathNextStageMapping) {
			const pathMapping = {};
			data.values.forEach((item, index) => {
				pathMapping[item.value] = (data.values.length > index+1 ? data.values[index+1].value : null);
			});
			this._pathNextStageMapping = pathMapping;
			this.publishMessageToVFPage();
		} else if (error) {
			console.error(error);
		}
	}
}