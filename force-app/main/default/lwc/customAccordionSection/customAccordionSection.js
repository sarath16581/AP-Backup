import { LightningElement, track, api } from 'lwc';

export default class CustomAccordionSection extends LightningElement {
    @api title
    @api defaultOpen = false

    @track isSectionOpen = false

    connectedCallback() {
        this.isSectionOpen = this.defaultOpen
    }

    get iconName() {
        return this.isSectionOpen ? 'utility:chevrondown' : 'utility:chevronright'
    }
    get isOpenClass() {
        return this.isSectionOpen ? 'slds-is-open' : ''
    }
    toggleSection() {
        this.isSectionOpen = !this.isSectionOpen
    }
}