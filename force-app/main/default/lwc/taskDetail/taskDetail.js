/**
 * @description Represents a single task item in the activity timeline
 * @author Steve W
 * @date 2021-03-09
 */
import { LightningElement, track, api } from 'lwc';

export default class TaskDetail extends LightningElement {

    @api task
    @api taskindex
    @track taskExpanded
    @track taskIcon

    connectedCallback() {
        if(this.task.expandClass){
            this.taskExpanded = this.task.expandClass
        }

        if(this.task.taskSectionIcon){
            this.taskIcon = this.task.taskSectionIcon;
        }
    }

    //Handles the opening/closing of task details
    handleTaskToggle(){
        if(this.taskExpanded.includes('slds-is-open')){
            this.taskExpanded = 'slds-timeline__item_expandable slds-timeline__item_task slds-section';
        }else{
            this.taskExpanded = 'slds-timeline__item_expandable slds-timeline__item_task slds-section slds-is-open';
        }
        if(this.taskIcon === 'utility:chevronright'){
            this.taskIcon = 'utility:switch';
        }else{
            this.taskIcon = 'utility:chevronright';
        }
    }
}