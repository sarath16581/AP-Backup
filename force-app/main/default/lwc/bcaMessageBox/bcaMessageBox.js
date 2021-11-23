/*
  @description       : This component is to display alert messages for success, failure.
  @author            : ankur.gandhi@auspost.com.au
  @group             : BCA
  @last modified on  : 04-01-2021
  @last modified by  : ankur.gandhi@auspost.com.au
  Modifications Log 
  Ver   Date         Author                        Modification
  1.0   04-01-2021   ankur.gandhi@auspost.com.au   Initial Version
*/

import { LightningElement, api } from 'lwc';

export default class BcaMessageBox extends LightningElement {
    @api iconName;
    //@api iconText;
    @api header;
    @api richTextMsg;

    get isDisplayIcon(){
        return this.iconName != null ? true : false;
    }
}