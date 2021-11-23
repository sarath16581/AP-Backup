import { LightningElement, api } from 'lwc';
import searchSTConsignmentByUniqueExtId from '@salesforce/apexContinuation/BSPConsignmentSearchUplift.searchSTConsignmentByUniqueExtId';
import { convertToFormattedDateStr } from 'c/bspCommonJS';
export default class BspConsignmentRow extends LightningElement {
    @api con;

    get name() {
        return this.con.Name ? this.con.Name : '';
    }

    get expectedDeliveryDateStr() {
        return this.con.ExpectedDeliveryDate_Str__c ? this.con.ExpectedDeliveryDate_Str__c : '';
    }

    get seviceType() {
        return this.con.Service_Type__c ? this.con.Service_Type__c : '';
    }

    get consignSummayStatus() {
        return this.con.Consignment_Summary_Status__c ? this.con.Consignment_Summary_Status__c : '';
    }

    get receiverSubrub() {
        return this.con.Receiver_Suburb__c ? this.con.Receiver_Suburb__c : '';
    }

    get dispatchDate(){
        return this.con.Dispatch_Date_Str__c ? convertToFormattedDateStr(this.con.Dispatch_Date_Str__c) : '';
    }

    retriveConsignmentTracking(){
        const selectedArticle = this.con.ArticleID__c;
        if(selectedArticle){
            //fire event to display spinner
            this.dispatchEvent(new CustomEvent('togglespinner', {detail:true}));
            //-- clear existing error messages
            this.dispatchEvent(new CustomEvent('selectedconsignmenterror', {detail:null}));
            searchSTConsignmentByUniqueExtId({
                selectedArticle: selectedArticle
            }).then(result => {
                //alert(JSON.stringify(result));
                //fireevent with return results
                this.dispatchEvent(new CustomEvent('selectedconsignmentresults', {detail:result}));
                 //fire event to stop spinner
                 this.dispatchEvent(new CustomEvent('togglespinner', {detail:false}));
    
            }).catch(error => {
                //alert(JSON.stringify(error));
                this.dispatchEvent(new CustomEvent('selectedconsignmenterror', {detail:error.body.message}));
                //this.errorMessages.push(error.body.message);
                //fire event to stop spinner
                this.dispatchEvent(new CustomEvent('togglespinner', {detail:false}));
            });
        }
    }

    

}