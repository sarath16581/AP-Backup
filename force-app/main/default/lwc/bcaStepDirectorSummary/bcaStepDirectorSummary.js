/*
* @author Victor.Cheng@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to to summary Director details
* @changelog
* 19/01/2021 Victor.Cheng@auspost.com.au  Created
*
*/

import {LightningElement, track, wire, api} from 'lwc';
import bcaStepBase from "c/bcaStepBase";

export default class BcaStepDirectorSummary extends bcaStepBase {

    @track _directors = [];
    @api get directors()
    {
        return this._directors;
    }
    set directors(arrDirectors)
    {
        this._directors = arrDirectors;
    }

}