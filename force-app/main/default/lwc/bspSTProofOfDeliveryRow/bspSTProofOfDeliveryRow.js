/*
2022-09-12 naveen.rajanna@auspost.com.au Removed /bsp in url as part of CHG0176934
*/
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
            return '/BSPStarTrackPOD?id=' + this.pod.NotesAndAttachments[0].Id; //CHG0176934
        }

        if(this.isTR){
            return '/StarTrackProofOfDeliveryMerge?id=' + this.pod.Id; //CHG0176934
        }
    }

    get formattedPODDateStr(){
        return this.pod.POD_Received_Date_Str__c ? convertToFormattedDateStr(this.pod.POD_Received_Date_Str__c) : '';
    }
}