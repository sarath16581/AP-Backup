/**
 * @description Component which allows to pricing adjustment onto star track products.
 * @author Darshan Chauhan
 * @date 2021-05-20
 * @changelog
 */
 import { api, LightningElement, track } from 'lwc';
 import onApply from '@salesforce/apex/APT_PricingAdjustmentController.onApply';
 import onReset from '@salesforce/apex/APT_PricingAdjustmentController.onReset';
 import getOpptyType from '@salesforce/apex/APT_PricingAdjustmentController.getOpptyType';
 import onCancel from '@salesforce/apex/APT_PricingAdjustmentController.onCancel';
 
 export default class LwcCmp extends LightningElement {
     @api proposalId; // this is proposal record Id which is being passed over here from vf page pricingadjustment
     @api configId; // this is cart record Id which is being passed over here from vf page pricingadjustment
     @api flow; // this is cart type value i.e. (New Quote, Renewal quote,etc.) which is being passed over here from vf page pricingadjustment
     @api configRequestId; // this is temp Object record Id which is being passed over here from vf page pricingadjustment
     @track error;
     @track vaildationFailReason = '';
     @track showValidationError = false;
     @track opttyType = '';
     @track isLoadingSpinner = false;
     @track disableCancel = false;
 
     connectedCallback(){
         this.isLoadingSpinner = true;
         getOpptyType({
             businessObjectId : this.proposalId
         }).then(result => {
             if(result != ''){
                 this.opttyType = result;
             }
             this.isLoadingSpinner = false;
         }).catch(error => {
             this.error = error;
             this.isLoadingSpinner = false;
         });
        
     }
 
     handleSuccess(event) {
         this.isLoadingSpinner = true;
         onApply({
             configurationId : this.configId, 
             businessObjectId : this.proposalId,
             flow: this.flow,
             configRequestId : this.configRequestId
         })
         .then(result => {
             let outMap = result;
             if(outMap.isError === 'true'){
                 this.showValidationError = true;  
                 this.disableCancel = true;
                 this.vaildationFailReason = result.errorMsg;
                 this.isLoadingSpinner = false;
             } else{
                 this.showValidationError = false;
                 this.vaildationFailReason = '';
                 this.isLoadingSpinner = false;
                 // window.location = result.finalURL;
                 window.open(result.finalURL, "_parent");
             }
         })
         .catch(error => {
             this.error = error;
             this.isLoadingSpinner = false;
         });
         
     }
 
     handleSubmit(event) {
        this.isLoadingSpinner = true;
     }
 
     handleReset(event){
         this.isLoadingSpinner = true;
         onReset({
             configurationId : this.configId, 
             businessObjectId : this.proposalId,
             flow: this.flow,
             configRequestId : this.configRequestId
         })
         .then(result => {
             this.showValidationError = false;
             this.isLoadingSpinner = false;
             window.open(result.finalURL, "_parent");
             this.showValidationError = false;
             this.isLoadingSpinner = false;
         })
         .catch(error => {
             this.isLoadingSpinner = false;
             this.error = error;
         });
     }
 
     handleCancel(event){
         this.isLoadingSpinner = true;
         onCancel({
             configurationId : this.configId
         })
         .then(result => {
             this.showValidationError = false;
             this.isLoadingSpinner = false;
             history.back();
         })
         .catch(error => {
             this.isLoadingSpinner = false;
             this.error = error;
         });        
     }
 
     closeerror(){
         this.showValidationError = false;
         this.vaildationFailReason = '';
     }
 }