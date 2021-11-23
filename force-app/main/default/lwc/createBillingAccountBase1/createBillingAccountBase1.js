/* @author
 * @date 2021-03-10
 * @group Billing Accounts
 * @tag Billing Account
 * @description: Billing Account Creation modal popup . Used for showing the attributes/ validation message if exists
 *               and triggering the billing account creation request.
 * @changelog
 * 2021-03-10 dheeraj.mandavilli@auspost.com.au Created
 */


import {LightningElement,api,wire} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import PROPOSAL_FIELD from '@salesforce/schema/Deal_Support_Request__c.APT_Contract__r.Apttus_QPComply__RelatedProposalId__r.Is_Startrack_Proposal__c';

const fields = [PROPOSAL_FIELD];

export default class CreateBillingAccountBase extends LightningElement {
@api recordId;

@wire(getRecord, { recordId: '$recordId', fields })
    Deal_Support_Request__c;

    get proposal() {
        return getFieldValue(this.Deal_Support_Request__c.data, PROPOSAL_FIELD);
    }

    get isAusPost() {
        if (this.proposal === 'No' ) return true;
        return false;

    }
    get isStartrack() {
        if (this.proposal === 'Yes') return true;
        return false;

    }

    cancel(){
        this.dispatchEvent(new CustomEvent('close'));
    }
}