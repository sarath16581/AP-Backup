/*
  * @author       : haraprasad.sahoo@auspost.com.au
  * @date         : 23/03/2020
  * @description  : Component for Case Print(Single)
--------------------------------------- History --------------------------------------------------
23.03.2020    Hara Sahoo    Created
*/
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class myNetworkPrintSingleCase extends NavigationMixin(LightningElement) {
   
    @api recordId;
    @track url;
    @track myDomainUrl;
    @track siteName;
    @track instanceName;
    
    
    connectedCallback() {
       var hostname = window.location.hostname;
       this.VFpage = {
        type: 'standard__webPage',
        attributes: {
        url : 'https://'+ hostname + '/myNetwork/apex/myNetworkCasePDFGenerator?selectedIds=' + encodeURI(this.recordId) }
    };
    } 
    handleClick(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        // Navigate to the Case print VF page.
        this[NavigationMixin.Navigate](this.VFpage);
    }

    
}