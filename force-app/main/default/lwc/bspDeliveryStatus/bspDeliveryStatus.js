import { LightningElement, api } from 'lwc';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';
import { convertToFormattedDateStr } from 'c/bspCommonJS';
export default class BspDeliveryStatus extends LightningElement {

    @api consignmentType;
    @api stExpectedDeliveryDateStr;
    @api apExpectedDeliveryDate;
    @api latestEvent;
    @api consignmentNumber;
    @api articleRecordType;
    @api consignmentWithMultipleArticles;

    clickToViewDetailsLink;
    communityURL = '';
    //noEventsMsg = 'Currently there are no events for this consignment. Please try again later.';
    noEventMsg = 'Currently there are no events for this {0}. Please try again later.';

    async connectedCallback() {
        try {
            this.communityURL = await retrieveBspCommunityURL();
        } catch (er) {
            console.error(er)
        }
    }

    /*get displayMsg(){
        return this.stEventMessage || this.noEventsMsg ? true : false;
    }*/

    get stEventMessage() {
        var latestEventMsg;
        this.clickToViewDetailsLink = '';
        if (this.consignmentType== 'Startrack' && this.latestEvent) {
            if (this.latestEvent.ExternalDescription__c || this.latestEvent.ActualDateTime_Timestamp__c) {
                this.clickToViewDetailsLink = '<a href="' + this.communityURL + '/s/SearchConsignment?trackingNumber=' + this.consignmentNumber + '" class="underline-dec" target="_blank" >Click here for details. </a>';
                latestEventMsg = ' The latest event is <b>' + this.latestEvent.ExternalDescription__c + '</b> on <b>'
                    + convertToFormattedDateStr(this.latestEvent.ActualDateTime_TimeStamp__c) + '</b>. ';
            }

            if(this.stExpectedDeliveryDateStr){
                latestEventMsg += this.estimatedDeliveryDateMessage + '<b>' + convertToFormattedDateStr(this.stExpectedDeliveryDateStr) + '</b>';
            }
        }
        return latestEventMsg;
    }

    get apEventMessage() {
        var latestEventMsg;
        this.clickToViewDetailsLink = '';
        if (this.consignmentType== 'AP' && this.latestEvent) {
            if (this.latestEvent.ExternalDescription__c || this.latestEvent.ActualDateTime__c) {
                this.clickToViewDetailsLink = '<a href="' + this.communityURL + '/s/SearchConsignment?trackingNumber=' + this.consignmentNumber + '" class="underline-dec" target="_blank" >Click here for details. </a>';
                latestEventMsg = ' The latest event is <b>' + this.latestEvent.ExternalDescription__c + ' </b> on ';
            }
        }
        return latestEventMsg;
    }

    get apMultipleArticlesMessage() {
        var multipleArticlesMsg;
        var viewLinkHref;
        this.clickToViewDetailsLink = '';
        if (this.consignmentType== 'AP' && this.consignmentWithMultipleArticles) {
            viewLinkHref = '<a href="' + this.communityURL + '/s/SearchConsignment?trackingNumber=' + this.consignmentNumber + '" class="underline-dec" target="_blank" >click here to view </a>';
            multipleArticlesMsg = 'This consignment has multiple articles, please ' + viewLinkHref +  'the recent updates for this consignment.';
        }
        return multipleArticlesMsg;
    }

    get estimatedDeliveryDateMessage(){
        var estDeliverDateMsg;
        if (this.apExpectedDeliveryDate || this.stExpectedDeliveryDateStr) {
            estDeliverDateMsg = 'Estimated Delivery Date is ';
        }
        return estDeliverDateMsg;
    }

    get noEventMessageFormatted(){
        this.clickToViewDetailsLink = '';
        if(this.articleRecordType == 'Article'){
            return this.noEventMsg.replace('{0}', 'article');
        }else{
            return this.noEventMsg.replace('{0}', 'consignment');
        }
    }

    get viewLink(){
        return this.clickToViewDetailsLink ? this.clickToViewDetailsLink : '' ;
    }

    get isSTConsignment(){
        return this.consignmentType == 'Startrack' ? true : false;
    }

    get isAPConsignment(){
        return this.consignmentType == 'AP' ? true : false;
    }

}