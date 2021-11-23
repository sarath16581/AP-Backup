import { LightningElement, api, track } from 'lwc';
import { convertToFormattedDateStr } from 'c/bspCommonJS';

export default class BspSTConsignmentDetails extends LightningElement {
    @api selectedConsignmentSearchType;
    @api singleCon;
    @api destination;
    @api isConsignmentAuthenticated;
    @api consignmentNumber;

    get dispatchedFormattedDateStr(){
        return this.singleCon.Dispatch_Date_Str__c ? convertToFormattedDateStr(this.singleCon.Dispatch_Date_Str__c) : '';
    }

    get expectedDeliveryFormattedDateStr(){
        return this.singleCon.ExpectedDeliveryDate_Str__c ? convertToFormattedDateStr(this.singleCon.ExpectedDeliveryDate_Str__c) : '';
    }

    get formattedReceiverAddress(){
        return this.singleCon.ReceiverAddress__c ? this.singleCon.ReceiverAddress__c.replace(/,/g,', ') : '';
    }

    get formattedSenderAddress(){
        return this.singleCon.SenderAddress__c ? this.singleCon.SenderAddress__c.replace(/,/g,', ') : '';
    }
}