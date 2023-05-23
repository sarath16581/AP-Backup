/**
 * @changelog
 * 2023-03-02 - Mahesh Parvathaneni - Updated title to show Network name
 * 2023-03-06 - Mahesh Parvathaneni - SF-874 Used ActualDateTime_TimeStamp__c field
 * 2023-03-10 - Mahesh Parvathaneni - SF-889 Updated the logic to check the contact facility from the network
 * 2023-05-10 - Mahesh Parvathaneni - SF-946 Added network search functionality
 */
import {
	api,
	track,
	LightningElement
} from 'lwc';
import {
	CONSTANTS,
	getStarTrackFormattedDateTimeString,
	getPostcodeSuburbResults,
	getNetworksResults,
	getPostcodeResults,
	getNetworkResultsByName
} from 'c/myNetworkStarTrackCaseArticlesService';
import {
	checkUndefinedOrNull
} from 'c/utils';

export default class MyNetworkStarTrackNetworkScan extends LightningElement {
	@api eventMessagesNetworkWrapper; //event message with network details received from parent
	@api criticalIncidents; //critical incidents knowledge articles received from parent
	@api articleId; //article id recieved from parent
	@api receiverPostcode; //receiver post code on case
	@api receiverSuburb; //receiver suburb on case
	@track selectedRows = []; //selected rows
	@track searchResults; //search results returned for postcode/suburb
	@track networkResults; //network results returned for postcode/suburb/locality
	eventMessagesList = []; //event messages list to render
	showEventMessages = false; //flag to show/hide the event messages with network scans
	postcodeSuburb; //postcode/suburb user input value
	showSearchResults = false; //flag to show/hide the search results
	localityId; //selected locality id
	postcode; //selected postcode
	suburb; //selected suburb
	showNetworkResults = false; //flag to show/hide the network results
	isLoading = false; //flag to show/hide the spinner on server call
	showNetworkError = false; //flag to show/hide the error message when no network results
	facilityName; //MyNetwork facility to search

	connectedCallback() {
		this.loadEventMessages();
	}

	renderedCallback() {
		if (this.showEventMessages) {
			this.template.querySelector('[data-id="events_btn"]').variant = 'brand';
			this.template.querySelector('[data-id="network_btn"]').variant = null;
		} else {
			this.template.querySelector('[data-id="events_btn"]').variant = null;
			this.template.querySelector('[data-id="network_btn"]').variant = 'brand';
		}
	}

	//getter method to show select button
	get showSelectBtn() {
		return (this.showEventMessages && this.eventMessagesList.length > 0) || (!this.showEventMessages && !checkUndefinedOrNull(this.networkResults) && this.networkResults.length > 0);
	}

	//getter method to show error message when no AP scan
	get showNoApScanEventMessage() {
		return (this.eventMessagesList && this.eventMessagesList.length === 0);
	}

	//load the event messages to render
	loadEventMessages() {
		let eventMessages = this.eventMessagesNetworkWrapper.eventMessages;

		//iterate the event messages
		if (eventMessages) {
			for (let i = 0; i < eventMessages.length; i++) {
				let eventMessageScan = {
					...eventMessages[i]
				};
				let actualDatetime = getStarTrackFormattedDateTimeString(eventMessages[i].eventMessage.ActualDateTime_TimeStamp__c);
				let network = eventMessages[i].network?.Id;
				//set title
				let title;
				if (network) {
					title = eventMessages[i].network.Name + ' - ';
				}
				title += eventMessages[i].eventMessage.EventDescription__c;
				if (!checkUndefinedOrNull(actualDatetime)) {
					title += ' @ ' + actualDatetime;
				}
				eventMessageScan.title = title;
				if (network) {
					let contactMethod = eventMessages[i].network.Contact_Facility__c;
					//set disabled checkbox
					if (contactMethod !== undefined && contactMethod !== null && contactMethod === CONSTANTS.MY_NETWORK) {
						eventMessageScan.isDisabled = false;
					} else {
						eventMessageScan.isDisabled = true;
					}
					//set critical incidents knowledge articles
					eventMessageScan.criticalIncidents = [];
					if (this.criticalIncidents !== undefined && this.criticalIncidents !== null) {
						let incidentListWrapper = this.criticalIncidents.find(inc => inc.networkOrgId === eventMessages[i].eventMessage.Post_Office_Code__c);
						if (incidentListWrapper && incidentListWrapper.criticalIncidentList) {
							eventMessageScan.criticalIncidents = incidentListWrapper.criticalIncidentList;
						}
					}
				}
				this.eventMessagesList.push(eventMessageScan);
			}
			this.showEventMessages = true;
		} else {
			//show the network search to add the network
			this.showEventMessages = false;
		}
		this.populateSuburbPostcodeFromCase();
	}

	//handler for modal close button
	handleModalClose(event) {
		this.dispatchEvent(new CustomEvent('modalclose'));
	}

	//handler for checkbox change event
	handleCheckboxChange(event) {
		let networkId = event.target.dataset.networkId;
		let eventMessageId = event.target.dataset.eventMessageId;
		if (event.target.checked) {
			let eventMessageNetworkScan = this.eventMessagesList.find(em => em.eventMessage.Id === eventMessageId);
			let row = {
				eventMsgId: eventMessageNetworkScan.eventMessage.Id,
				articleId: eventMessageNetworkScan.eventMessage.Article__c,
				networkLabel: eventMessageNetworkScan.network.Name,
				network: eventMessageNetworkScan.network.Id,
				contactMethod: eventMessageNetworkScan.network.Contact_Facility__c
			}
			this.selectedRows.push(row);
			if (networkId) {
				this.setCheckedFlagForEventMessages(networkId, eventMessageId, true);
				this.setCheckedFlagForNetworkResults(networkId, true);
			}
		} else {
			let index = this.selectedRows.findIndex(row => row.eventMsgId === eventMessageId);
			if (index > -1) {
				this.selectedRows.splice(index, 1);
			}
			if (networkId) {
				this.setCheckedFlagForEventMessages(networkId, eventMessageId, false);
				this.setCheckedFlagForNetworkResults(networkId, false);
			}
		}
		this.selectedRows = [...this.selectedRows];
	}

	//handler for select button click
	handleSelectBtnClick(event) {
		//fire event to parent with selected networks
		this.dispatchEvent(new CustomEvent('rowselect', {
			detail: {
				selectedRows: this.selectedRows
			}
		}));
	}

	//handler for url click
	handleUrlClick(event) {
		let recordId = event.target.dataset.url;
		//dispatches event to the vf page to open record in the subtab
		this.dispatchEvent(new CustomEvent('subtab', {
			bubbles: true,
			composed: true,
			detail: {
				recordId: recordId
			}
		}));
	}

	//function to populate the suburb and postcode from case
	populateSuburbPostcodeFromCase() {
		//set the post code suburb in the search box
		if (!checkUndefinedOrNull(this.receiverPostcode)) {
			this.postcodeSuburb = this.receiverPostcode;
		}
		if (this.postcodeSuburb && !checkUndefinedOrNull(this.receiverSuburb)) {
			this.postcodeSuburb += ' - ' + this.receiverSuburb;
		} else if (!checkUndefinedOrNull(this.receiverSuburb)) {
			this.postcodeSuburb += this.receiverSuburb;
		}

		if (this.postcodeSuburb) {
			this.isLoading = true;
			//get postcode record
			getPostcodeResults(this.receiverPostcode, this.receiverSuburb)
				.then(response => {
					this.postcode = response.Name;
					this.suburb = response.Suburb__c;
					this.localityId = response.Locality_Postcode_ID__c;
					this.isLoading = false;
				})
				.catch(error => {
					this.isLoading = false;
					console.error('getPostcodeResults call failed: ' + error);
				})
		}
	}

	//handler for button click
	handleButtonClick(event) {
		const id = event.target.dataset.id;
		if (id === 'events_btn') {
			this.showEventMessages = true;
		} else {
			this.showEventMessages = false;
		}
	}

	//auto-populate postcode/suburb results
	populatePostcodeSuburb(event) {
		let searchTerm = event.target.value;
		if (searchTerm === null || searchTerm === undefined || searchTerm.length === 0) {
			//reset search results
			this.resetSearchResults();
		}

		if (searchTerm.length > 1) {
			this.searchResults = [];
			//get postcode/suburb auto results
			getPostcodeSuburbResults(null, searchTerm)
				.then(response => {
					response.forEach(rec => {
						this.searchResults.push(rec);
					});

					if (this.searchResults.length > 0) {
						this.showSearchResults = true;
					}
				})
				.catch(error => {
					console.error('getPostcodeSuburbResults call failed: ' + error);
				})
		}
	}

	//function to reset the search results
	resetSearchResults() {
		this.searchResults = [];
		this.showSearchResults = false;
		this.postcodeSuburb = null;
		this.localityId = null;
		this.postcode = null;
		this.suburb = null;
		this.networkResults = [];
		this.showNetworkResults = false;
		this.showNetworkError = false;
	}

	//handler for postcode select click
	handleSelectPostcodeSuburb(event) {
		this.postcode = event.currentTarget.dataset.postcode;
		this.suburb = event.currentTarget.dataset.suburb;
		this.localityId = event.currentTarget.dataset.localityId;
		this.postcodeSuburb = event.currentTarget.dataset.label;
		this.showSearchResults = false;
	}

	//handler for search by postcode/suburb button click
	handleSearchByPostcodeBtnClick(event) {
		this.networkResults = [];
		this.showNetworkError = false;
		if (!checkUndefinedOrNull(this.suburb) && !checkUndefinedOrNull(this.postcode) && !checkUndefinedOrNull(this.localityId)) {
			this.isLoading = true;
			//get networks relates to suburb, postcode and locality id
			getNetworksResults(this.suburb, this.postcode, this.localityId)
				.then(response => {
					this.populateNetworkWrapper(response);
					this.isLoading = false;
				})
				.catch(error => {
					this.isLoading = false;
					console.error('getNetworksResults call failed: ' + error);
				})
		}
	}

	//handler for network checkbox change
	handleNetworkCheckboxChange(event) {
		let networkId = event.target.dataset.networkId;
		if (event.target.checked) {
			let networkRec = this.networkResults.find(n => n.networkId === networkId).network;
			let row = {
				articleId: this.articleId,
				networkLabel: networkRec.Name,
				network: networkRec.Id,
				contactMethod: networkRec.Contact_Facility__c
			}
			this.selectedRows.push(row);
			this.setCheckedFlagForEventMessages(networkId, null, true);
			this.setCheckedFlagForNetworkResults(networkId, true);
		} else {
			let index = this.selectedRows.findIndex(row => row.network === networkId);
			if (index > -1) {
				this.selectedRows.splice(index, 1);
			}
			this.setCheckedFlagForEventMessages(networkId, null, false);
			this.setCheckedFlagForNetworkResults(networkId, false);
		}
		this.selectedRows = [...this.selectedRows];
	}

	//function to auto select the network from the event messages list
	setCheckedFlagForEventMessages(networkId, eventMessageId, isChecked) {
		if (this.eventMessagesList.length > 0) {
			let eventMessage;
			//get the event message based on the id
			if (eventMessageId) {
				eventMessage = this.eventMessagesList.find(em => em.eventMessage.Facility__c === networkId && em.eventMessage.Id === eventMessageId);
			} else {
				eventMessage = this.eventMessagesList.find(em => em.eventMessage.Facility__c === networkId);
			}
			if (eventMessage && isChecked) {
				this.eventMessagesList.find(em => em.eventMessage.Id === eventMessage.eventMessage.Id).isChecked = true;
			} else if (eventMessage && !isChecked) {
				this.eventMessagesList.find(em => em.eventMessage.Id === eventMessage.eventMessage.Id).isChecked = false;
				//this.eventMessagesList.find(em => em.eventMessage.Facility__c === networkId && em.eventMessage.Id === eventMessageId).isChecked = false;
			}
			this.eventMessagesList = [...this.eventMessagesList];
		}
	}

	//function to auto select the network from the network search
	setCheckedFlagForNetworkResults(networkId, isChecked) {
		if (this.networkResults && this.networkResults.length > 0) {
			const network = this.networkResults.find(n => n.networkId === networkId);
			if (network && isChecked) {
				this.networkResults.find(n => n.networkId === networkId).isChecked = true;
			} else if (network && !isChecked) {
				this.networkResults.find(n => n.networkId === networkId).isChecked = false;
			}
			this.networkResults = [...this.networkResults];
		}
	}

	//function to handle the change event for facility name
	handleFacilityNameChange(event) {
		this.facilityName = event.detail.value;
	}

	//handler for search by facility name button click
	handleSearchByNameBtnClick(event) {
		this.networkResults = [];
		this.showNetworkError = false;
		if (!checkUndefinedOrNull(this.facilityName) && this.facilityName.length > 2) {
			this.isLoading = true;
			//get network related to facility name
			getNetworkResultsByName(this.facilityName.trim())
				.then(response => {
					this.populateNetworkWrapper(response);
					this.isLoading = false;
				})
				.catch(error => {
					this.isLoading = false;
					console.error('getNetworkResultsByName call failed: ' + error);
				})
		}
	}

	//set the networkresults wrapper to render on UI
	populateNetworkWrapper(networkResponse) {
		networkResponse.forEach(networkWrapper => {
			networkWrapper.networkName = networkWrapper.isBypassNetwork ? networkWrapper.network.Name + ' (Bypass Network To)' : networkWrapper.network.Name;
			//set critical incidents knowledge articles
			networkWrapper.criticalIncidents = [];
			if (this.criticalIncidents !== undefined && this.criticalIncidents !== null) {
				let incidentListWrapper = this.criticalIncidents.find(inc => inc.networkOrgId === networkWrapper.network.Org_ID__c);
				if (incidentListWrapper && incidentListWrapper.criticalIncidentList) {
					networkWrapper.criticalIncidents = incidentListWrapper.criticalIncidentList;
				}
			}
			this.networkResults.push(networkWrapper);
		});

		if (this.networkResults.length > 0) {
			this.showNetworkResults = true;
		} else {
			this.showNetworkError = true;
		}
	}
}