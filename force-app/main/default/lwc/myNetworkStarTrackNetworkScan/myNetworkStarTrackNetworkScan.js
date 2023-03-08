/**
* @changelog
* 2023-03-02 - Mahesh Parvathaneni - Updated title to show Network name
* 2023-03-06 - Mahesh Parvathaneni - SF-874 Used ActualDateTime_TimeStamp__c field
*/ 
import {
    api,
    track,
    LightningElement
} from 'lwc';
import {
    CONSTANTS,
	getStarTrackFormattedDateTimeString
} from 'c/myNetworkStarTrackCaseArticlesService';

export default class MyNetworkStarTrackNetworkScan extends LightningElement {
    @api eventMessagesNetworkWrapper; //event message with network details received from parent
    @api criticalIncidents; //critical incidents knowledge articles received from parent
    @track selectedRows = []; //selected rows
    eventMessagesList = []; //event messages list to render

    connectedCallback() {
        this.loadEventMessages();
    }

    //load the event messages to render
    loadEventMessages() {
        let eventMessages = this.eventMessagesNetworkWrapper.eventMessages;

        //iterate the event messages
        for (let i = 0; i < eventMessages.length; i++) {
            let eventMessageScan = {
                ...eventMessages[i]
            };
            let actualDatetime = getStarTrackFormattedDateTimeString(eventMessages[i].ActualDateTime_TimeStamp__c);
			let network = eventMessages[i].Facility__c;
            //set title
			let title;
			if (network) {
				title = eventMessages[i].Facility__r.Name + ' - ';
			}
            title += eventMessages[i].EventDescription__c;
            if (actualDatetime !== null) {
                title += ' @ ' + actualDatetime;
            }
            eventMessageScan.title = title;
            if (network) {
                let contactMethod = eventMessages[i].Facility__r.Contact_Facility__c;
                //set disabled checkbox
                if (contactMethod !== undefined && contactMethod !== null && contactMethod === CONSTANTS.MY_NETWORK) {
                    eventMessageScan.isDisabled = false;
                } else {
                    eventMessageScan.isDisabled = true;
                }
                //set critical incidents knowledge articles
                eventMessageScan.criticalIncidents = [];
                if (this.criticalIncidents !== undefined && this.criticalIncidents !== null) {
                    let incidentListWrapper = this.criticalIncidents.find(inc => inc.networkOrgId === eventMessages[i].FacilityOrganisationID__c);
                    if (incidentListWrapper && incidentListWrapper.criticalIncidentList) {
                        eventMessageScan.criticalIncidents = incidentListWrapper.criticalIncidentList;
                    }
                }
            }
            this.eventMessagesList.push(eventMessageScan);
        }
    }

    //handler for modal close button
    handleModalClose(event) {
        this.dispatchEvent(new CustomEvent('modalclose'));
    }

    //handler for checkbox change event
    handleCheckboxChange(event) {
        if (event.target.checked) {
            let eventMessageId = event.target.dataset.eventMessageId;
            let eventMessage = this.eventMessagesList.find(em => em.Id === eventMessageId);
            let row = {
                eventMsgId: eventMessage.Id,
                articleId: eventMessage.Article__c,
                networkLabel: eventMessage.Facility__r.Name,
                network: eventMessage.Facility__c,
                contactMethod: eventMessage.Facility__r.Contact_Facility__c
            }
            this.selectedRows.push(row);
        } else {
            let index = this.selectedRows.findIndex(row => row.eventMsgId === event.target.dataset.eventMessageId);
            if (index > -1) {
                this.selectedRows.splice(index, 1);
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

}