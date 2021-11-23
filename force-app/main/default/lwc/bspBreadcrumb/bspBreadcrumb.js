/*
  * @author       : Ankur Gandhi. ankur.gandhi@auspost.com.au
  * @date         : 23/08/2020
  * @description  : Component for bread crumb navigation.
--------------------------------------- History --------------------------------------------------
23.08.2020    Ankur Gandhi                         Created.
25-11-2020    avula.jansirani@auspost.com.au       commented console.log lines
*/
import { LightningElement, api } from 'lwc';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';

export default class BspBreadcrumb extends LightningElement {
    
    @api breadCrumbText = '';
    commURLPrefix = '';

    async connectedCallback() {
        try {
            this.commURLPrefix = await retrieveBspCommunityURL();
        } catch (er) {
            //console.error(er)
        }
    }
}