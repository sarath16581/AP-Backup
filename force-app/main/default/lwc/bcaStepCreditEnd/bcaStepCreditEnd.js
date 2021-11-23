/*
* @author Victor.Cheng@auspost.com.au
* @date 5/02/2021
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Bca Step Credit End
* @changelog
* 5/02/2021 Victor.Cheng@auspost.com.au  Created
*
*/

import {LightningElement, track, wire, api} from 'lwc';
import bcaStepBase, {creditLimits} from "c/bcaStepBase";
import { checkAllValidity, checkCustomValidity } from 'c/bcaStepBase';

export default class BcaStepCreditEnd extends bcaStepBase {

    get contactEmail() {
        return this.creditAssessment.emailForCorrespondence.email;
    }

    get isUnder() {
        if(this.creditAssessment?.creditAmount?.recommendedAmount &&
            this.creditAssessment.creditAmount.recommendedAmount <= this.creditAssessment.lowerCreditLimitVal){
            this.updateNavButtons(this.creditAssessment.skipValidation, false);
            return true;
        }
        return false;
    }
}