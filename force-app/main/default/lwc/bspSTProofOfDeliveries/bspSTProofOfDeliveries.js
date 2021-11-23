import { LightningElement, api } from 'lwc';

export default class BspSTProofOfDeliveries extends LightningElement {
    @api relatedPODs;
    @api singleConArticleId;
}