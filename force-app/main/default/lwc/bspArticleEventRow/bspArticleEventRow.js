import { LightningElement, api } from 'lwc';
import { convertToFormattedDateStr } from 'c/bspCommonJS';

export default class BspArticleEventRow extends LightningElement {
    @api evnt;
    @api isConsignmentAuthenticated;
    @api isCEAttachmentsExists;
    @api reqFrom;
    @api emScanTypes;
    @api isConsignmentSerchIsAPType;
    @api isConsignmentSerchIsSTType;

    get isCEAttachmentsExists() {
        return this.evnt.NotesAndAttachments ?
            (this.evnt.NotesAndAttachments.length > 0 ? true : false) : false;
    }


    get isArticleEventAttachmentsExists() {
      
      return (this.emScanTypes && 
              this.emScanTypes.includes(this.evnt.EventType__c) && 
                ( (this.evnt.NotesAndAttachments && this.evnt.NotesAndAttachments.length > 0) || 
                  (this.evnt.Safe_Drop_GUID__c != '' && this.evnt.Safe_Drop_GUID__c != undefined)
                )
              ) ? true : false;
      
      /*return this.evnt.NotesAndAttachments && this.emScanTypes
        ? (((this.evnt.NotesAndAttachments.length > 0 || this.evnt.Safe_Drop_GUID__c != '') &&
          this.emScanTypes.includes(this.evnt.EventType__c)) ? true : false)
        : false;*/
    }

    get podHref(){
      return '/bsp/POD_Redirect?id=' + this.evnt.Id;
    }

    get formattedActualDateStr(){
      return this.evnt.ActualDateTime_TimeStamp__c ? convertToFormattedDateStr(this.evnt.ActualDateTime_TimeStamp__c) : '';
    }
}