import { LightningElement, api } from 'lwc';
import { convertToFormattedDateStr } from 'c/bspCommonJS';

export default class BspSTProofOfDeliviryRow extends LightningElement {
    @api pod;
    @api singleConArticleId;

    get isTM(){
      return this.singleConArticleId ?(this.singleConArticleId.substring(0, 4) == 'TM2_' ? true : false) :false;
    }

    get isTR(){
        return this.singleConArticleId ?(this.singleConArticleId.substring(0, 4) == 'TR2_' ? true : false) :false;
    }

    get podHref(){
        if(this.isTM){
            return '/bsp/BSPStarTrackPOD?id=' + this.pod.NotesAndAttachments[0].Id;
        }

        if(this.isTR){
            return '/bsp/StarTrackProofOfDeliveryMerge?id=' + this.pod.Id;
        }
    }

    get formattedPODDateStr(){
        return this.pod.POD_Received_Date_Str__c ? convertToFormattedDateStr(this.pod.POD_Received_Date_Str__c) : '';
    }
}