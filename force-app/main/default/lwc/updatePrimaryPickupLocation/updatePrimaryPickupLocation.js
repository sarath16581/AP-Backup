/*
* @author
* @date 2021-03-026
* @group Billing Accounts
* @tag Billing Account
* @description: Update Primary Pickup Location modal popup . Used for showing the validation message if any other Primary Pickup Location exists
*               for that Opportunity and buttons to cancel and override the current primary pickup location with new one.
* @changelog
* 2021-03-26 dheeraj.mandavilli@auspost.com.au Created
* 2021-05-24 dheeraj.mandavilli@auspost.com.au Removed Primary Pickup Location field from the modal popup as part of STP-5775
*
*/

import {LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getPrimaryLocDetails from '@salesforce/apex/CSQ_PickupLocationUtility.getPrimaryPickupLocationDetails';
import getOpptyId from '@salesforce/apex/CSQ_PickupLocationUtility.getOppId';
import overridePrimary from '@salesforce/apex/CSQ_PickupLocationUtility.updatePickupLocation';

//const fields=[OPP_FIELD];

export default class UpdatePrimaryPickupLocation extends  NavigationMixin(LightningElement) {
@api recordId;
@api objectApiName;
@track oppvalue = '';
@track areDetailsVisible = false;
@track errorMessage = 'Another Pick Up Location associated to this Opportunity is already marked as primary.<br/>' +
                      'Would you like to override the previous record to mark this record as the primary Pick Up Location?<br/><br/>';
@track noteForPrimary = 'Note: If marked as ‘primary’, this Pick Up Location Address will be reflected as the physical address in the StarTrack Leader Account<br/>';


    connectedCallback() {
        //alert('Inside Connected Call Back::');
        this.loadPickupLocationRecord();
    }

    async loadPickupLocationRecord() {
        this.pickupLocId = this.recordId;
        // force waiting before the interface loads
        let opp = await getOpptyId({pickupLocId: this.recordId})
        this.opptyId = opp;
        let pickupLocation = await getPrimaryLocDetails({opptyId:opp})
        if (pickupLocation === true) {
            this.areDetailsVisible = true;
        }
      }

    async overridePrimary(){
        this.locRecId = this.recordId;
        this.oppId = this.opptyId ;
        let updateLocationRec = await overridePrimary({locRecId: this.recordId, oppId : this.opptyId })
        if(updateLocationRec === true){
            window.location.reload();
        }
    }

    cancel(){
        this.dispatchEvent(new CustomEvent('close'));
    }

}