/**
 * @author Paul Perry
 * 
 * Consolidated Headless Quick Actions for Credut Suspect Register check
 * - Can be extended using different objects
 * - Currently supports:
 * 		- APT_Credit_Assessment__c (main applicant + contact)
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
// Required to obtain recordId as this doesn't always come along
import { CurrentPageReference } from 'lightning/navigation';
import { ASyncTask } from './utilities/generic';
import AptCreditAssessmentJs from './AptCreditAssessmentJs/main';

const BACKGROUND_TASK = {
	GetRecord : 'getRecord',
	IsDestroyed : 'isDestroyed'
};

const OBJ_INSTANCES = {
	APT_Credit_Assessment__c : AptCreditAssessmentJs
}

// Variables accessible by wired methods used as params
let objectApiName;
let objectInstance;

export default class QaCreditSuspectCheck extends LightningElement {
	// Don't use @api recordId as this oftenly fails/delays to populate for Quick Actions
	recordId;
	// Display spinner limiting UI input using spinner overlay
	isWorking;

	get instance() {
		if (!this._instance && typeof objectInstance === 'function') {
			this._instance = new objectInstance(this);
		}

		return this._instance;
	}

	get record() {
		if (this.backgroundTasks[BACKGROUND_TASK.GetRecord].status) {
			return this.backgroundTasks[BACKGROUND_TASK.GetRecord].result;
		}

		return null;
	}
	
	// Using currentPageReference to obtain recordId and objectApiName
	@wire(CurrentPageReference)
		getPageReferenceParameters(pageRef) {
		if (pageRef && !this.recordId) {
			// populate this first
			objectApiName = pageRef.attributes?.objectApiName;
			if (OBJ_INSTANCES[objectApiName]) {
				objectInstance = OBJ_INSTANCES[objectApiName];
			}

			// setting recordId will invoke wired getRecord operation
			this.recordId = pageRef.attributes?.recordId || null;
		}
	}

	@wire(getRecord, {
		recordId: '$recordId',
		fields: objectApiName ? [ `${objectApiName}.Id` ] : undefined,
		// Fetching fields as optional surpressing insufficient access exceptions
		optionalFields: objectInstance?.getRecordFields
	})
	getRecord({ data, error }) {
		if (error) {
			this.backgroundTasks[BACKGROUND_TASK.GetRecord].reject(error);
		} else if (data) {
			this.backgroundTasks[BACKGROUND_TASK.GetRecord].resolve(data);
		}
	}

	connectedCallback() {
		// Populate list for background tasks
		this.backgroundTasks = Object.values(BACKGROUND_TASK).reduce(
			(taskList, taskName) => Object.assign(
				taskList,
				{ [taskName] : new ASyncTask() }
			), { }
		);
	}

	disconnectedCallback() {
		// Set flag to stop any futher processing as this will cause issues within Console Apps
		this.backgroundTasks[BACKGROUND_TASK.IsDestroyed].resolve(true);
	}

	@api invoke() {
		console.log('Performing Credit Suspect Register check');
		
		if (!this.backgroundTasks[BACKGROUND_TASK.GetRecord].status) {
			// Ignoring multiple clicks on the QA Button while waiting for response
			if (!this.invokePending) {
				this.invokePending = true;

				this.backgroundTasks[BACKGROUND_TASK.GetRecord].promise.then(() => {
					delete this.invokePending;
					// Proceed once response is received
					this.instance.invoke();
				});
			}
		} else {
			// Got all we need, proceed
			this.instance.invoke();
		}
	}
}