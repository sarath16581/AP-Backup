import { LightningElement, api } from 'lwc';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';

export default class BspBreadcrumb extends LightningElement {
    
    @api breadCrumbText = '';
    commURLPrefix = '';

    async connectedCallback() {
        try {
            this.commURLPrefix = await retrieveBspCommunityURL();
        } catch (er) {
            console.error(er)
        }
    }
}