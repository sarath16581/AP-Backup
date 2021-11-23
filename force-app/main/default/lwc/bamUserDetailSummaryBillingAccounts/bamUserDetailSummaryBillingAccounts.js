import { LightningElement, api, track } from 'lwc';

export default class BamUserDetailSummaryBillingAccounts extends LightningElement {
    @api billingAccounts = []
    @track showAllBillingAccounts = false

    get showButton() {
        return this.billingAccounts && this.billingAccounts.length > 0
    }
    showAll() {
        this.showAllBillingAccounts = true
    }
    showLess() {
        this.showAllBillingAccounts = false
    }
}