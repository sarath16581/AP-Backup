import { api, LightningElement } from 'lwc';

export default class MyNetworkStarTrackCaseArticlesDatatable extends LightningElement {

    @api articles; //articles received from parent

    columns = [
        {label: 'Article', fieldName: 'articleNumber', editable:false, sortedColumn: false, fieldType: 'url', headerCssClass : 'slds-th__action slds-text-link_reset', dataCssClass : 'slds-cell-wrap'},
        {label: 'Last Event Description', fieldName: 'EventDescription__c', editable:false, sortedColumn: false, fieldType: 'text', headerCssClass : 'slds-th__action slds-text-link_reset', dataCssClass : 'slds-cell-wrap'},
        {label: 'Last Scan Date', fieldName: 'ActualDateTime__c', editable:false, sortedColumn: false, fieldType: 'text', headerCssClass : 'slds-th__action slds-text-link_reset', dataCssClass : 'slds-cell-wrap'},
         {label: 'Last AP Network Scan', fieldName: 'Facility__c', editable:false, sortedColumn: false, fieldType: 'text', headerCssClass : 'slds-th__action slds-text-link_reset', dataCssClass : 'slds-cell-wrap'}
    ];
}