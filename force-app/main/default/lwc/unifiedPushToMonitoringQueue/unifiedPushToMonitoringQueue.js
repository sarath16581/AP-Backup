/**
 * @description Modal Popup on Quick Action that will push the Case to Unified Customer Service Monitoring Queue
 * @author Seth Heang
 * @date 2024-07-10
 * @changelog
 * 2024-07-10 - Seth Heang - Created
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import getUnifiedMonitoringQueueId from '@salesforce/apex/UnifiedPushToMonitoringQueueController.getUnifiedCustomerServiceMonitoringQueueId';
import CASE_ID_FIELD from '@salesforce/schema/Case.Id';
import CASE_OWNER_ID_FIELD from '@salesforce/schema/Case.OwnerId';
import { CloseActionScreenEvent } from 'lightning/actions';

const CASE_ALREADY_IN_MONITORING_QUEUE_ERROR_MSG = 'Case is already in the monitoring queue.';

export default class UnifiedPushToMonitoringQueue extends LightningElement {
	@api recordId;
	_isLoading;
	_errorMessages = [];
	_caseOwnerId;
	_unifiedMonitoringQueueId;

	/**
	 * @description wire and retrieve the case ownerId field and then push the case to monitoring queue upon initial loading
	 * @param error
	 * @param data
	 */
	@wire(getRecord, { recordId: '$recordId', fields: [ CASE_OWNER_ID_FIELD ] })
	caseDetails({ error, data }) {
		this._isLoading = true;
		if (data) {
			if(!this._caseOwnerId){
				this._caseOwnerId = getFieldValue(data, CASE_OWNER_ID_FIELD);
				this.handlePushCaseToMonitoringQueue();
			}
		} else if (error) {
			this._errorMessages.push(error.body.message);
		}
	}

	/**
	 * @description fetch the unified monitoring queue from controller and validate against current case's owner
	 *				if it's the same, then throw an error message and don't proceed with dml update
	 * @returns {Promise<void>}
	 */
	async fetchAndValidateUnifiedMonitoringQueue(){
		this._unifiedMonitoringQueueId = await getUnifiedMonitoringQueueId();
		if(this._unifiedMonitoringQueueId === this._caseOwnerId){
			this._errorMessages.push(
				CASE_ALREADY_IN_MONITORING_QUEUE_ERROR_MSG
			);
		}
	}

	/**
	 * @description update the case owner to the unified monitoring queue and handle any error back from controller
	 * @returns {Promise<void>}
	 */
	async handlePushCaseToMonitoringQueue() {
		// fetch and validate the current case owner against the unified monitoring queue
		await this.fetchAndValidateUnifiedMonitoringQueue();
		if(this._errorMessages.length > 0){
			this._isLoading = false;
			return;
		}

		const fields = {};
		fields[CASE_ID_FIELD.fieldApiName] = this.recordId;
		fields[CASE_OWNER_ID_FIELD.fieldApiName] = this._unifiedMonitoringQueueId;
		const recordInput = { fields };
		updateRecord(recordInput)
			.then().catch((error) => {
				const errors = error.body.output.errors;
				this._errorMessages = errors.map((err) => err.message);
			})
			.finally(()=>{
				this._isLoading = false;
			});
	}

	/**
	 * handle close the modal popup
	 * @param event
	 */
	handleClose(event) {
		this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
	}

	// getter for error messages
	get errorMessages() {
		return this._errorMessages;
	}

	// getter for loading flag
	get isLoading() {
		return this._isLoading;
	}

}