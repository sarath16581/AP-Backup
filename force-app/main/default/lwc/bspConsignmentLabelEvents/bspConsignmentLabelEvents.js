import { LightningElement, api } from 'lwc';

export default class BspConsignmentLabelEvents extends LightningElement {
    @api labelEvents;
    @api selectedEventArticle;
    @api selectedConsignmentSearchType;
    @api isConsignmentAuthenticated;
    @api isConsignmentSerchIsAPType;

    onChangeOfSelectedEvent(event){
        const c = new CustomEvent('selectedarticlechange', {detail : event.detail});
        this.dispatchEvent(c);
    }
}