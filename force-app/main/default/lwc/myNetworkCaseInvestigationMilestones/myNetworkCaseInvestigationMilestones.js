/**
 * @description Renders the current network milestone violation in MyNetwork portal
 * @author Mahesh Parvathaneni
 * @date 2023-02-07
 * @changelog
 * 2023-02-23 Mahesh Parvathaneni - updated logic to the server side
 */

import { LightningElement, api } from 'lwc';
import getCaseInvestigationNetworkMilestones from '@salesforce/apex/MyNetworkCIMilestoneController.getCaseInvestigationNetworkMilestones';

export default class MyNetworkCaseInvestigationMilestones extends LightningElement {
	@api recordId; //case investigation record id
	caseInvestigation; //details of the case investigation based on the record id
	hasMilestonesViolated; //flag to check the milestones violated or not
	isLoading = false; //flag to show/hide the spinner
	milestoneDetails = {}; //milestone details

	connectedCallback() {
		this.loadMilestones();
	}

	renderedCallback() {
		//set the progress bar width
		if (this.template.querySelector('div.progress-bar') !== null) {
			this.template.querySelector('div.progress-bar').style.width = this.milestoneDetails.percentCompleted + '%';
		}
	}

	//load the milestone details for case investigation
	loadMilestones() {
		this.isLoading = true;
		//get milestones
		getCaseInvestigationNetworkMilestones({
			caseInvestigationId: this.recordId
		})
		.then((response) => {
			this.hasMilestonesViolated = response.hasMilestonesViolated;
			if (this.hasMilestonesViolated === true) {
				this.getMilestoneDetails(response);
			}
			this.isLoading = false;
		})
		.catch((error) => {
			this.isLoading = false;
			//set the error message
			this.error = 'Error getting milestones';
			if (Array.isArray(error.body)) {
				this.error = error.body.map(e => e.message).join(', ');
			} else if (typeof error.body.message === 'string') {
				this.error = error.body.message;
			}
			console.error('Error getting milestones: ' + this.error);
		})
	}

	//function to sest the case investigation milestone to render on UI
	getMilestoneDetails(response) {
		this.milestoneDetails.tierName = response.networkTierName;
		this.milestoneDetails.timeRemainingOrCompleted = this.getMinutesToTimeString(response.timeRemainingOrCompleted);
		this.milestoneDetails.percentCompleted = response.percentTimeCompleted;
		this.milestoneDetails.status = response.status;
		this.milestoneDetails.progressBarClass = 'progress-bar ' + this.getProgressBarClass(this.milestoneDetails.percentCompleted);
		this.milestoneDetails.iconName = 'glyphicon ' + this.getIconByMilestoneStatus(this.milestoneDetails.percentCompleted, response);
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

	//function to get the icon name for UI based on the percent of time completed and business hours
	getIconByMilestoneStatus(percent, response) {
		let iconName = '';
		//if outside of business hours
		if(!response.isBusinessHours) {
			iconName = 'glyphicon-pause';
		}

		//if within business hours
		if (percent >= 60 && percent < 80) {
			iconName = 'glyphicon-eye-open';
		} else if (percent >= 80 && percent < 100) {
			iconName = 'glyphicon-fire';
		} else if (percent >= 100) {
			iconName = 'glyphicon-thumbs-down';
		} else {
			iconName = 'glyphicon-time';
		}
		return iconName;
	}
}