import { LightningElement,api } from 'lwc';
 
export default class MyNetworkRelatedSortingEventMessage extends LightningElement {
    @api sortingEventMessageFound;
    @api sortingEventMessages;
}