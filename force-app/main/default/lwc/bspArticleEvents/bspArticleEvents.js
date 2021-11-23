import { LightningElement, api } from 'lwc';

export default class BspArticleEvents extends LightningElement {
    @api isConsignmentAuthenticated;
    @api events;   
    @api reqFrom;
    @api emScanTypes;
    @api isConsignmentSerchIsAPType;
    @api isConsignmentSerchIsSTType;
}