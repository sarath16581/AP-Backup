import { LightningElement,api } from 'lwc';

export default class ActivityTimelineItem extends LightningElement {
    @api activity;


    get isTask() {
        return this.activity.subType === 'Task';
    }

    get isCall() {
        return this.activity.subType === 'Call';
    }

    get isEmail() {
        return this.activity.subType === 'Email';
    }

    get isEvent() {
        return this.activity.subType === 'Event';
    }
}