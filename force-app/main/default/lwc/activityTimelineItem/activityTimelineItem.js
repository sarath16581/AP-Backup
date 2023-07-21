import { LightningElement,api } from 'lwc';

export default class ActivityTimelineItem extends LightningElement {
    @api activity;

    currentDate = new Date().toJSON().slice(0, 10);


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

    get dueDate(){
        return this.activity.dueDate ? this.activity.dueDate : 'No due date';
    }

    get dueDateStyle() {
        return this.activity.dueDate <  this.currentDate ? 'color:red' : '';
    }
}