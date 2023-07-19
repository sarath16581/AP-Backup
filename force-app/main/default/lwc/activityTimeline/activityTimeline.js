import { LightningElement,api } from 'lwc';
import getAllActivities from '@salesforce/apex/ActivityTimelineController.getAllActivities';

export default class ActivityTimeline extends LightningElement {
    @api recordId;
    @api sObjectName;
    @api recordLimit;

    offset = 0;
    sectionClassPrefix = 'slds-timeline__item_expandable slds-timeline__item_task ';
    allActivities = [];
    loading= false;

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        this.loading = true;
        getAllActivities({
            recordId: this.recordId,
            sObjectName: this.sObjectName,
            recordLimit: this.recordLimit,
            offsetLimit: this.offset
        }).then(result => {
            this.allActivities = [...this.allActivities, ...result];
            this.loading = false;
        }).catch(error => {
            this.loading = false;
        }).finally(() => {
            this.loading = false;
        });
    }

    loadMoreData() {
        this.offset = this.offset + this.recordLimit;
        this.loadData();
    }

    expandAll() {
        let allSections = this.template.querySelectorAll('.slds-timeline__item_expandable');
        for (let section of allSections) {
            section.className = this.sectionClassPrefix + 'slds-section slds-is-open';
        }
    }

    collapseAll() {
        let allSections = this.template.querySelectorAll('.slds-timeline__item_expandable');
        for (let section of allSections) {
            section.className = this.sectionClassPrefix + 'slds-section slds-is-close';
        }
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