/**
 * @author Paul Perry
 * 
 * Consolidated LWC Quick Actions for CSQ that can be used to wire up any action as long as it's 
 * distinguishable based on record criteria.
 * 
 * This LWC addresses an issue with the Console where the component gets destructed while
 * async processes keep running.
 */
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
// Required to obtain recordId as this doesn't always come along
import { CurrentPageReference } from 'lightning/navigation';
import { ASyncTask } from './utilities/generic';
import CsqJs from './CustomerScopingQuestionnaire/main'

const BACKGROUND_TASK = {
	GetRecord : 'getRecord',
	IsDestroyed : 'isDestroyed'
};

// Variables accessible by wired methods used as params
let objectApiName;
let objectInstance = CsqJs;

export default class CsqCloneQA extends NavigationMixin(LightningElement) {
	// Don't use @api recordId as this oftenly fails/delays to populate for Quick Actions
	recordId;
	// Display spinner limiting UI input using spinner overlay
	isWorking;

	get instance() {
		if (!this._instance && typeof objectInstance === 'function') {
			const navToRecordId = (recordId) => this.navToRecordId(recordId);
			this._instance = new objectInstance({ thisArg : this, navToRecordId });
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
		if (!this.backgroundTasks[BACKGROUND_TASK.GetRecord].status) {
			// Ignoring multiple clicks on the QA Button while waiting for response
			if (!this.dialogPending) {
				this.dialogPending = true;

				this.backgroundTasks[BACKGROUND_TASK.GetRecord].promise.then(() => {
					delete this.dialogPending;
					// Show dialog once response is received
					this.instance.showModal();
				});
			}
		} else {
			// Got all we need, show Modal
			this.instance.showModal();
		}
	}

	@api navToRecordId(recordId) {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId,
				actionName: 'view'
			}
		});
	}
}