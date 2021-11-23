import { LightningElement, api } from 'lwc';

export default class BspSuccess extends LightningElement {
    @api successMessage;
    @api htmlFormat = false;
}