import { LightningElement, api } from 'lwc';

export default class BcaSectionSummary extends LightningElement {
    @api secData;
    @api sectionName;

    get sectionNameLabel(){
        return this.sectionName;
    }
    get secDataVal(){
        return this.secData;
    }

}