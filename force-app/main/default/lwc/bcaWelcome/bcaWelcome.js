/*
* @author avula.jansirani@auspost.com.au
* @date 2021-02-05
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Welcome step in Credit Application Form which will display the welcome text from a Knowledge Article
* @changelog
* 2021-02-05 avula.jansirani@auspost.com.au  Created
*
*/
import { LightningElement, api } from 'lwc';
import bcaStepBase from "c/bcaStepBase";
//import getWelcomeMessage from '@salesforce/apex/BCAFormBase.getWelcomeMessage';

export default class BcaWelcome extends bcaStepBase {

    //header;
    @api body;

   /* @wire(getWelcomeMessage)
    wiredWelcomeMessage({ error, data }) {
        if (data) {
           // this.header = data.Header__c;
            this.body = data.Message__c;
        } 
    }*/
}