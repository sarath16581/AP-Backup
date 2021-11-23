import { LightningElement, api } from 'lwc';

export default class FieldData extends LightningElement {
    @api label
    @api value
}