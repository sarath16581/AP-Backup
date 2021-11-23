import { LightningElement, api } from 'lwc';
import { convertToFormattedDateStr } from 'c/bspCommonJS';

export default class BspConsignmentHeaderSection extends LightningElement {
    @api headerEvent;
    @api APConsignmentExpDeliveryDate;
    @api STConsignmentArrivalDate;
    @api isConsignmentSerchIsAPType;

    get consignmentLocation() {
        let locationValue = '';
        locationValue = this.headerEvent.WorkCentreText__c ? this.headerEvent.WorkCentreText__c : this.headerEvent.Depot_Name__c;
        if(locationValue !== undefined && locationValue !== ''){
            locationValue = 'at ' + locationValue;
        }
        return locationValue;
    }

    get stConsignmentArrivalFormattedDate(){
        return this.STConsignmentArrivalDate ? convertToFormattedDateStr(this.STConsignmentArrivalDate) : '';
    }

    get stConsignmentLastUpdate(){
        return this.headerEvent.ActualDateTime_TimeStamp__c ? convertToFormattedDateStr(this.headerEvent.ActualDateTime_TimeStamp__c) :'';
    }

}