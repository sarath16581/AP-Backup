/**
 * @description Renders the current network milestone violation in MyNetwork portal
 * @author Mahesh Parvathaneni
 * @date 2023-02-07
 * @changelog
 */

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import FIELD_NETWORK_MILESTONES_VIOLATED from '@salesforce/schema/CaseInvestigation__c.NetworkMilestonesViolated__c';
import FIELD_NETWORK_MILESTONE_NEXT_VIOLATION_DATETIME from '@salesforce/schema/CaseInvestigation__c.NetworkMilestoneNextViolationDatetime__c';
import FIELD_NETWORK_MILESTONE_LAST_VIOLATION_DATETIME from '@salesforce/schema/CaseInvestigation__c.NetworkMilestoneLastViolationDatetime__c';
import FIELD_MILESTONE_START_DATETIME from '@salesforce/schema/CaseInvestigation__c.MilestoneTimeStartDateTime__c';
import FIELD_NETWORK_MILESTONE_CURRENT_TIER from '@salesforce/schema/CaseInvestigation__c.NetworkMilestoneCurrentTier__c';

//constants
const OPEN_VIOLATION = 'Open Violation';
const REMAINING = 'Remaining';
export default class MyNetworkCaseInvestigationMilestones extends LightningElement {
	@api recordId; //case investigation record id
	error; // error returned from the wire service
	caseInvestigation; //details of the case investigation based on the record id
	hasMilestonesViolated; //flag to check the milestones violated or not
	isLoading = false; //flag to show/hide the spinner
	milestoneDetails = {}; //milestone details

	//get CI record details. 
	@wire(getRecord, {
		recordId: '$recordId',
		fields: [FIELD_NETWORK_MILESTONES_VIOLATED, FIELD_NETWORK_MILESTONE_NEXT_VIOLATION_DATETIME,
			FIELD_NETWORK_MILESTONE_LAST_VIOLATION_DATETIME, FIELD_MILESTONE_START_DATETIME, FIELD_NETWORK_MILESTONE_CURRENT_TIER
		]
	})
	caseInvestigationWiredRecord({
		error,
		data
	}) {
		if (error) {
			//set the error message
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
			this.caseInvestigation[FIELD_NETWORK_MILESTONE_CURRENT_TIER.fieldApiName] = getFieldValue(data, FIELD_NETWORK_MILESTONE_CURRENT_TIER);

			//load the milestones
			this.loadMilestones();
		}
	}

	renderedCallback() {
		//set the progress bar width
		if (this.template.querySelector('div.progress-bar') !== null) {
			this.template.querySelector('div.progress-bar').style.width = this.milestoneDetails.percentCompleted + '%';
		}
	}

	//load the milestone details of the case investigation
	loadMilestones() {
		if (this.caseInvestigation.NetworkMilestoneCurrentTier__c !== null && this.caseInvestigation.NetworkMilestoneCurrentTier__c !== undefined) {
			this.hasMilestonesViolated = true;
			this.getMilestoneDetails();
		} else {
			this.hasMilestonesViolated = false;
		}
	}

	//function to convert the mins to string to display it in the UI (ex: 1530 => 1d 1h 30m )
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

	//function to sest the case investigation milestone to render on UI
	getMilestoneDetails() {
		if (this.caseInvestigation.NetworkMilestoneCurrentTier__c <= 2) {
			this.milestoneDetails.tierName = 'Network Tier ' + `${this.caseInvestigation.NetworkMilestoneCurrentTier__c}`;
			this.milestoneDetails.timeRemainingOrCompleted = this.getMilestoneTimeRemaining();
			this.milestoneDetails.percentCompleted = this.getPercentCompleted();
			this.milestoneDetails.status = this.milestoneDetails.percentCompleted > 100 ? OPEN_VIOLATION : REMAINING;
			this.milestoneDetails.progressBarClass = 'progress-bar ' + this.getProgressBarClass(this.milestoneDetails.percentCompleted);
			this.milestoneDetails.iconName = 'glyphicon ' + this.getIconByMilestoneStatus(this.milestoneDetails.percentCompleted);
		} else {
			// if milestones violated greater than 2 default to tier 2 as we've only 2 network tiers for case investigations
			this.milestoneDetails.tierName = 'Network Tier 2';
			this.milestoneDetails.timeRemainingOrCompleted = this.getMilestoneTimeCompleted();
			this.milestoneDetails.percentCompleted = 100;
			this.milestoneDetails.status = OPEN_VIOLATION;
			this.milestoneDetails.progressBarClass = 'progress-bar progress-bar-danger';
			this.milestoneDetails.iconName = 'glyphicon glyphicon-thumbs-down';
		}
	}

	//function to get the milestone time remaining for the tier
	//calculates the remaining time from now to record next violation date time
	getMilestoneTimeRemaining() {
		let todaysDate = new Date();
		let nextViolationDate = new Date(this.caseInvestigation.NetworkMilestoneNextViolationDatetime__c);
		let diffInMins = Math.abs(nextViolationDate - todaysDate) / (1000 * 60);
		return this.getMinutesToTimeString(diffInMins);
	}

	//function to get the milestone time completed for the tier
	//calculates the time completed from record last violation date time to now 
	getMilestoneTimeCompleted() {
		let todaysDate = new Date();
		let lastViolationDate = new Date(this.caseInvestigation.NetworkMilestoneLastViolationDatetime__c);
		let diffInMins = Math.abs(lastViolationDate - todaysDate) / (1000 * 60);
		return this.getMinutesToTimeString(diffInMins);
	}

	//function to get the percent of time completed to render for the progress bar
	getPercentCompleted() {
		let startDate;
		let todaysDate = new Date();
		let endDate = new Date(this.caseInvestigation.NetworkMilestoneNextViolationDatetime__c);
		if (this.caseInvestigation.NetworkMilestoneCurrentTier__c === 1) {
			startDate = new Date(this.caseInvestigation.MilestoneTimeStartDatetime__c);
		} else {
			//for network tier 2
			startDate = new Date(this.caseInvestigation.NetworkMilestoneLastViolationDatetime__c);
		}
		return Math.round(((todaysDate - startDate) / (endDate - startDate)) * 100);
	}

	//function to get the progress bar class for UI based on the percent of time completed
	getProgressBarClass(percent) {
		let bgClass = 'progress-bar-success';
		if ((percent >= 60 && percent < 80)) {
			bgClass = 'progress-bar-warning';
		} else if ((percent >= 80)) {
			bgClass = 'progress-bar-danger';
		}
		return bgClass;
	}

	//function to get the icon name for UI based on the percent of time completed
	getIconByMilestoneStatus(percent) {
		let iconName = '';
		if (percent >= 60 && percent < 80) {
			iconName = 'glyphicon-eye-open';
		} else if (percent >= 80 && percent < 100) {
			iconName = 'glyphicon-fire';
		} else if (percent > 100) {
			iconName = 'glyphicon-thumbs-down';
		} else {
			iconName = 'glyphicon-time';
		}
		return iconName;
	}
}