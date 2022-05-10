/**
 * @description The component used within Pickup Booking lightning application on network's lightning page layout.c/addLodgementPoint
 * 				It displays a section containing toggle button, that allows PUD user to enable the integrated job dispatch flag on network record
 * 				that bypass the record's sharing rule. 
 * @author Seth Heang
 * @date 2022-03-30
 * @changelog
 * 2022-03-30 - Seth Heang - Created
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import NETWORK_ID_FIELD from '@salesforce/schema/Network__c.Id';
import INTEGRATED_JOB_DISPATCH_FIELD from '@salesforce/schema/Network__c.Integrated_Job_Dispatch_Enabled__c';
import PUD_JOB_DISPATCH_PROMPT_LABEL from '@salesforce/label/c.PUDEnableIntegratedJobDispatchPrompt';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateNetwork from '@salesforce/apex/PUDPickupBookingController.updateDispatchJobIntegration';
 
export default class PudEnableDispatchIntegration extends LightningElement {
	// flag to determine the state of popup modal
	_isModalOpen = false;
	@api recordId;
	// prompt message when user click the toggle button
	_promptMessage;
	// flag to determine to state of job dispatch flag
	_integratedJobDispatchFlag;
 
	// wire method to retrieve the network record and job dispatch field, that is opened on network layout
	@wire(getRecord, { recordId: '$recordId', fields: [INTEGRATED_JOB_DISPATCH_FIELD] })
	wiredNetwork({error, data}){
		if(error){
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error loading integration job dispatch on Network',
					message: error.body.message,
					variant: 'error'
				})
			)
		} else if (data) {
			// load integration job dispatch flag on successful wire
			this._integratedJobDispatchFlag = getFieldValue(data, INTEGRATED_JOB_DISPATCH_FIELD);
		}
	}

	// getter for the integration job dispatch flag
	get integratedJobDispatchFlag() { return this._integratedJobDispatchFlag; }
	// getter for pop-up flag
	get isModalOpen() { return this._isModalOpen; }
	// getter for the prompt message flag
	get promptMessage() { return this._promptMessage; }

	/**
	 * handling the toggle action of the button and update the prompt message dynamically(enable/disable) based on flag state
	 */
	handleToggleJobDispatch(event){
		this._isModalOpen = true;
		this._integratedJobDispatchFlag = event.target.checked;
		if(this._integratedJobDispatchFlag === true){
			this._promptMessage = this.formatCustomLabel(PUD_JOB_DISPATCH_PROMPT_LABEL, ' enable ');
		}else{
			this._promptMessage = this.formatCustomLabel(PUD_JOB_DISPATCH_PROMPT_LABEL, ' disable ');
		}
	}
 
	/**
	 * handle the closing action of the pop-up modal and revert changes on UI.
	 */
	handleCloseModal(){
		this._isModalOpen = false;
		// revert back the flag
		this._integratedJobDispatchFlag = !this._integratedJobDispatchFlag;
	}
 
	/**
	 * handle the update operation of network's dispatch integration flag
	 */
	handleSaveDetails(){
		this._isModalOpen = false;
		const fields = {};
		fields[NETWORK_ID_FIELD.fieldApiName] = this.recordId;
		fields[INTEGRATED_JOB_DISPATCH_FIELD.fieldApiName] = this._integratedJobDispatchFlag;
		// make a callout to apex controller to perfrom update dml in without-sharing context
		updateNetwork({ network: fields })
			.then(() => {
				this.dispatchEvent( new ShowToastEvent({
					title: 'Success',
					message: 'Enable Integrated Job Dispatch is successfully updated',
					variant: 'success'
				}));
				// refresh the detail section on page layout
				getRecordNotifyChange([{recordId: this.recordId}]);
			}).catch((error) => {
				this.dispatchEvent(new ShowToastEvent({
					title: 'Error updating record',
					message: error.body.message,
					variant: 'error'}));
				this.handleCloseModal();
			});
	}
 
	/* 
	 * handle the dynamic population of the custom label where label contain '{digit number}' e.g. {123}
	 * @param require at least two parameters of string type with no max limit
	 *		E.g. string1, string2, string3, nextParam....etc.
	 *	string1: is the full custom label containing one or many substrings '{123}', where 123 is marked for dynamic substring replacement 
	 *		E.g. text {0} text {1} text {2}...etc
	 *	string2: replaces the first '{digit number}' in string1 with this value
	 *	string3: replaces the second '{digit number}' in string1 with this value
	 *	nextParam: replaces the next '{digit number} in string1 with this value
	 * Reason: There is no native support for dynamically populating the parameter of custom label in LWC,
	 * Solution code: https://salesforce.stackexchange.com/questions/188193/salesforce-lightning-custom-labels-with-parameters
	 */
	formatCustomLabel(param) { 
		var outerArguments = arguments; 
		return param.replace(
				/\{(\d+)\}/g, 
				function() { 
					return outerArguments[parseInt(arguments[1]) + 1]; 
			}
		);
	}
}