/**
 * Created by vcheng on 4/03/2021.
 */

import {LightningElement, track, wire, api} from 'lwc';
import bcaStepBase from "c/bcaStepBase";

export default class BcaStepPersonList extends bcaStepBase {

    @api pagePrefix;

    get directors() {
        if(this.creditAssessment.directors)
            return this.creditAssessment.directors;

        return [];
    }

    editPerson = (event) => {
        let index = event.currentTarget.dataset.id ? event.currentTarget.dataset.id : event.target.dataset.id;

        this.jumpToStep(this.pagePrefix + index);

    }

}