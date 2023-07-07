import { LightningElement,api } from 'lwc';
import getAllActivities from '@salesforce/apex/ActivityTimelineController.getAllActivities';

export default class ActivityTimeline extends LightningElement {
    @api recordId;

    sectionClassPrefix = 'slds-timeline__item_expandable slds-timeline__item_task';
    allActivities;

    connectedCallback() {
        getAllActivities({recordId: this.recordId}).then(result => {
            this.allActivities = result;
            console.log(this.allActivities)
        }).catch(error => {
            console.log(error);
        });
    }

    toggleSection(event) {
        let buttonid = event.currentTarget.dataset.buttonid;
        let currentSection = this.template.querySelector('[data-id="' + buttonid + '"]');
        if (currentSection.className.search('slds-is-open') == -1) {
            currentSection.className = this.sectionClassPrefix + 'slds-section slds-is-open';
        } else {
            currentSection.className = this.sectionClassPrefix + 'slds-section slds-is-close';
        }
    }
}