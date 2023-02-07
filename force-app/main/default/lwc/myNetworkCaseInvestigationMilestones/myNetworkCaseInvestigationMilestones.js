import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import FIELD_NETWORK_MILESTONES_VIOLATED from '@salesforce/schema/CaseInvestigation__c.NetworkMilestonesViolated__c';
import FIELD_NETWORK_MILESTONE_NEXT_VIOLATION_DATETIME from '@salesforce/schema/CaseInvestigation__c.NetworkMilestoneNextViolationDatetime__c';
import FIELD_NETWORK_MILESTONE_LAST_VIOLATION_DATETIME from '@salesforce/schema/CaseInvestigation__c.NetworkMilestoneLastViolationDatetime__c';
import FIELD_MILESTONE_START_DATETIME from '@salesforce/schema/CaseInvestigation__c.MilestoneTimeStartDateTime__c';

const OPEN_VIOLATION = 'Open Violation';
const REMAINING = 'Remaining';
export default class MyNetworkCaseInvestigationMilestones extends LightningElement {
	@api recordId; //case investigation record id
	error; // error returned from the wire service
	caseInvestigation; //details of the case investigation based on the record id
	hasMilestonesViolated; //flag to check the milestones violated or not
	isLoading = false; //flag to show/hide the spinner
	milestoneDetails = {}; //milestone details
	openViolation = 'Open Violation';

	//get CI record details. 
	@wire(getRecord, {
		recordId: '$recordId',
		fields: [FIELD_NETWORK_MILESTONES_VIOLATED, FIELD_NETWORK_MILESTONE_NEXT_VIOLATION_DATETIME,
			FIELD_NETWORK_MILESTONE_LAST_VIOLATION_DATETIME, FIELD_MILESTONE_START_DATETIME
		]
	})
	caseInvestigationWiredRecord({
		error,
		data
	}) {
		if (error) {
			this.error = 'Error getting milestones';
			if (Array.isArray(error.body)) {
				this.error = error.body.map(e => e.message).join(', ');
			} else if (typeof error.body.message === 'string') {
				this.error = error.body.message;
			}
			console.error('Error getting milestones: ' + this.error);
		} else if (data) {
			// populate the case investigation record from the values received from wire adapter.
			this.caseInvestigation = {};
			this.caseInvestigation[FIELD_NETWORK_MILESTONES_VIOLATED.fieldApiName] = getFieldValue(data, FIELD_NETWORK_MILESTONES_VIOLATED);
			this.caseInvestigation[FIELD_NETWORK_MILESTONE_NEXT_VIOLATION_DATETIME.fieldApiName] = getFieldValue(data, FIELD_NETWORK_MILESTONE_NEXT_VIOLATION_DATETIME);
			this.caseInvestigation[FIELD_NETWORK_MILESTONE_LAST_VIOLATION_DATETIME.fieldApiName] = getFieldValue(data, FIELD_NETWORK_MILESTONE_LAST_VIOLATION_DATETIME);
			this.caseInvestigation[FIELD_MILESTONE_START_DATETIME.fieldApiName] = getFieldValue(data, FIELD_MILESTONE_START_DATETIME);

			//load the milestones
			this.loadMilestones();
		}
	}

	loadMilestones() {
		if (this.caseInvestigation.NetworkMilestonesViolated__c !== null && this.caseInvestigation.NetworkMilestonesViolated__c !== undefined) {
			this.hasMilestonesViolated = true;
			this.getMilestoneDetails();
		} else {
			this.hasMilestonesViolated = false;
		}
	}

	getMinutesToTimeString(timeInMins) {
		let days = Math.floor(timeInMins / 1440);
		let hours = Math.floor((timeInMins % 1440) / 60);
		let minutes = Math.floor((timeInMins % 1440) % 60);
		let timeString = '';
		if (days > 0) timeString += days + " d ";
		if (hours > 0) timeString += hours + " h ";
		if (minutes >= 0) timeString += minutes + " m ";
		return timeString;
	}

	getMilestoneDetails() {
		if (this.caseInvestigation.NetworkMilestonesViolated__c <= 2) {
			this.milestoneDetails.tierName = 'Network Tier ' + `${this.caseInvestigation.NetworkMilestonesViolated__c}`;
			this.milestoneDetails.status = REMAINING;
			this.milestoneDetails.timeRemainingOrCompleted = this.getMilestoneTimeRemaining();
			this.milestoneDetails.percentCompleted = this.getPercentCompleted();
			this.milestoneDetails.progressBarClass = 'progress-bar ' + this.getProgressBarClass(this.milestoneDetails.percentCompleted);
			this.milestoneDetails.iconName = 'glyphicon ' + this.getIconByMilestoneStatus(this.milestoneDetails.percentCompleted);
		} else {
			//default to tier 2 as we've only 2 network tiers for case investigations
			this.milestoneDetails.tierName = 'Network Tier 2';
			this.milestoneDetails.status = OPEN_VIOLATION;
			this.milestoneDetails.timeRemainingOrCompleted = this.getMilestoneTimeCompleted();
			this.percentCompleted = 100;
			this.milestoneDetails.progressBarClass = 'progress-bar progress-bar-danger';
			this.milestoneDetails.iconName = 'glyphicon glyphicon-thumbs-down';
		}
	}

	getMilestoneTimeRemaining() {
		let todaysDate = new Date();
		let nextViolationDate = new Date(this.caseInvestigation.NetworkMilestoneNextViolationDatetime__c);
		let diffInMins = Math.abs(nextViolationDate - todaysDate) / (1000 * 60);
		return this.getMinutesToTimeString(diffInMins);
	}

	getMilestoneTimeCompleted() {
		let todaysDate = new Date();
		let lastViolationDate = new Date(this.caseInvestigation.NetworkMilestoneLastViolationDatetime__c);
		let diffInMins = Math.abs(lastViolationDate - todaysDate) / (1000 * 60);
		return this.getMinutesToTimeString(diffInMins);
	}

	getPercentCompleted() {
		let startDate;
		let todaysDate = new Date();
		let endDate = new Date(this.caseInvestigation.NetworkMilestoneNextViolationDatetime__c);
		if (this.caseInvestigation.NetworkMilestonesViolated__c === 1) {
			startDate = new Date(this.caseInvestigation.MilestoneTimeStartDatetime__c);
		} else {
			startDate = new Date(this.caseInvestigation.NetworkMilestoneLastViolationDatetime__c);
		}
		return Math.round(((todaysDate - startDate) / (endDate - startDate)) * 100);
	}

	getProgressBarClass(percent) {
		let bgClass = 'progress-bar-success';
		if ((percent >= 60 && percent < 80)) {
			bgClass = 'progress-bar-warning';
		} else if ((percent >= 80)) {
			bgClass = 'progress-bar-danger';
		}
		return bgClass;
	}

	getIconByMilestoneStatus(percent) {
		let iconName = '';
		if (percent >= 60 && percent() < 80) {
			iconName = 'glyphicon-eye-open';
		} else if (percent >= 80) {
			iconName = 'glyphicon-fire';
		} else {
			iconName = 'glyphicon-time';
		}
		return iconName;
	}
}