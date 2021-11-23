/**
 * @description Displays a summary of the data captured for case creation.
 * @author Ranjeewa Silva
 * @date 2020-10-05
 * @changelog
 * 2020-10-05 - Ranjeewa Silva - Created
 */

import { LightningElement, api } from 'lwc';
import { get } from 'c/utils';
import { CONSTANTS } from "c/dtnCaseService";

export default class DtnCaseWizardSummaryStep extends LightningElement {

    @api enquiryInput;
    @api customerInput;
    @api articleInput;
    @api article;
    @api network;

    get senderAddress() {
        return get(this.customerInput, 'senderAddress.address', null);
    }

    get receiverAddress() {
        return get(this.customerInput, 'receiverAddress.address', null);
    }

}