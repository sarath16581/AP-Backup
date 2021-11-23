/**
 * Created by vcheng on 4/03/2021.
 */

import {LightningElement, track, wire, api} from 'lwc';
import bcaStepBase from "c/bcaStepBase";

export default class BcaStepReferenceList extends bcaStepBase {

    @api pagePrefix;

    get references() {
        if(this.creditAssessment.businessRefs)
            return this.creditAssessment.businessRefs;
        return [];
    }

    editReference = (event) => {
        let index = event.currentTarget.dataset.id ? event.currentTarget.dataset.id : event.target.dataset.id;

        this.jumpToStep(this.pagePrefix + index);

    }

}