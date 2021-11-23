import { LightningElement, api } from 'lwc';

export default class BspConsignmentList extends LightningElement {
    @api conList;
    @api selectedArticle;

    handleLoading(event) {
         //fire event to display spinner
         this.dispatchEvent(new CustomEvent('togglespinner', {detail:event.detail}));
    }

    onSelectedConsignmentResults(event){
         //fire event to send the selected consignment results
         this.dispatchEvent(new CustomEvent('selectedconsignmentresults', {detail:event.detail}));
    }

    onSelectedConsignmentError(event){
           //fire event to send the selected consignment results
           this.dispatchEvent(new CustomEvent('selectedconsignmenterror', {detail:event.detail}));
    }

}