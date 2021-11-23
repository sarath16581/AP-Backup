import { LightningElement, api } from 'lwc';

export default class BspError extends LightningElement {
    @api errorMessage;
    @api htmlFormat = false;
}