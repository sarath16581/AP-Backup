/*
* @author       : Arjun Singh. arjun.singh@auspost.com.au
* @date         : 05/04/2021
* @description  : This lWC component is used in Sub Account Request creation from Proposal and Billing Account flow. It has following features
*                 1. It contains logic for adding/removing multiple lodgement points to Sub Account Requests.
*********************************History*******************************************************************
05.04.2021    Arjun Singh   Created
*/
import { LightningElement,api,track,wire } from 'lwc';
import getResults from '@salesforce/apex/addMultipleLodgementPoints1Controller.getResults';
import onLoadLPdata from '@salesforce/apex/addMultipleLodgementPoints1Controller.onLoadLPdata';
import getIconName from '@salesforce/apex/addMultipleLodgementPoints1Controller.getIconName';

export default class AddLodgementPointArjun extends LightningElement {
    @api Label;
    @track searchRecords = [];
    @track selectedRecords = [];
    @api required = false;
    @api LoadingText = false;
    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track messageFlag = false;
    @api recordId;
    @track iconName;

    /**
     * @description On first page load, call Apex Controller(onLoadLPdata) to query and return the lodgement point data
     *              Save the returned lodgement point data into a list of selected records, and used for display in the html section
     *              Dispatch event and send the lodgement point data back to the parent aura component for table display
     *  */ 
    @api
    connectedCallback(event){
        console.log('Record Id in Parent Lodgement Comp:::::',this.recordId);
        onLoadLPdata({ recordId: this.recordId})
        .then(result => {
            this.selectedRecords = result;
            // send selectedRecords to the aura component via a custom event for table display
            let selRecords = this.selectedRecords;
          const selectedEvent = new CustomEvent('selected', {detail: {selRecords} });
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);
        })
        .catch(error => {
            console.log('Error is: '+error);
        });
        //let selRecords = event.detail.selRecords;
    }

    /**
     * @description Call apex controller and retrieve the Network custom object icon from the Salesforce Custom Tab
     *              Icon to be displayed as part of the selected records and dropdown search result
     *  */
    @wire(getIconName, { sObjectName: 'Network__c' })
    gettingNetworkIcon({ error, data }) {
        if (data) {
            let objectInformation = data;
            this.iconName = objectInformation;
        }
        else if (error) {
            console.log('Error is: ' + JSON.stringify(error));
        }

    }

    /**
     * @description Call apex controller to query and retrieve the Network records based on the search input entered in the Search Box
     *              Records found are added to the 'searchRecords' list variable and display in dropdown list of the Search Box
     *  */
    searchField(event) {
        // currentText is the Searched String in the Search Box
        var currentText = event.target.value;
        var selectRecId = [];
        // save already selected Network records into a list
        for(let i = 0; i < this.selectedRecords.length; i++){
            selectRecId.push(this.selectedRecords[i].recId);
        }
        this.LoadingText = true;
        // call apex controller to query the search string, passing the text input and the already selected Network records
        getResults({ value: currentText, selectedRecId : selectRecId })
        .then(result => {
            console.log('resultVal>>>>',result);
            this.searchRecords= result;
            this.LoadingText = false;
            
            this.txtclassname =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            if(currentText.length > 0 && result.length == 0) {
                this.messageFlag = true;
            }
            else {
                this.messageFlag = false;
            }

            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }
        })
        .catch(error => {
            console.log('Error is:'+error);
            console.log(error);
        });
        
    }
    /**
     * @description On Click of the search result's entry, this method will added the records to a list of selected record 'setSelectedRecord' variable
     *              These selected records will be displayed underneath the search box
     *  */
    setSelectedRecord(event) {
       // retrieve attributes of the selected record
        var recId = event.currentTarget.dataset.id;
        var selectName = event.currentTarget.dataset.name;
        var recWCC = event.currentTarget.dataset.wcc;
        var postCode = event.currentTarget.dataset.postcode;

        console.log('postCode>>>>',postCode);
        // create a custom object with attributes above and save to the class variable
        let newsObject = { 'recId' : recId ,'recName' : selectName, 'recWCC' : recWCC, 'postCode' : postCode };
        this.selectedRecords.push(newsObject);

        this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        // send selectedRecords to the aura component via a custom event
        var selRecords = this.selectedRecords;
		this.template.querySelectorAll('lightning-input').forEach(each => {
            each.value = '';
        });
        console.log('selRecords>>>>>>',selRecords);
        console.log('selRecords>>>>>>',this.selectedRecords);
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords} });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        //this.dispatchEvent(new CustomEvent("selected", { detail : selRecords}));
    }

    /**
     * @description On Click of 'x' button of the selected records which are displayed underneath the Search Box,
     *              will remove the corresponding record off the list of selected record
     *              Removed record, will be able to be searched again in the Search Box
     *  */
    removeRecord (event){
        let selectRecId = [];
        // get remaining selected records which did not get delete, and save into a list
        for(let i = 0; i < this.selectedRecords.length; i++){
            if(event.detail.name !== this.selectedRecords[i].recId)
                selectRecId.push(this.selectedRecords[i]);
        }
        // reassign the remaining list excluding the deleted record
        this.selectedRecords = [...selectRecId];
        // send selectedRecords to the aura component via a custom event
        let selRecords = this.selectedRecords;
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}