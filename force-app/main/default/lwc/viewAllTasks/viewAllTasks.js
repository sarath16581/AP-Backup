/**
 * @description Read only version of activity timeline that runs 
 *              without sharing to expose tasks to LBP Community Users
 * @author Steve W
 * @date 2021-03-09
 */
import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TaskCall from '@salesforce/apex/ViewAllTasksController.getTasks';
import strUserId from '@salesforce/user/Id';
import basePath from '@salesforce/community/basePath';

export default class LightningExampleAccordionMultiple extends LightningElement {
    @api recordId;
    @api isLoaded = false;
    @api openSectionLoading = false;
    @api closedSectionLoading = false;

    @track openTasks = [];
    @track closedTasks = [];
    @track openTasksSection = 'slds-section slds-is-open';
    @track closedTasksSection = 'slds-section';
    @track showViewMoreOpen;
    @track showViewMoreClosed;

    totalOpen;
    totalClosed;
    showViewMoreOpenButton
    showViewMoreClosedButton;

    connectedCallback() {
        this.getTasks('open');
        this.getTasks('closed');
    }

    getTasks(taskTypeToGet){
        const offsetToUse = (taskTypeToGet === 'open' ? this.openTasks.length : this.closedTasks.length)
        if(taskTypeToGet === 'open' && this.totalOpen > 0){
            this.openSectionLoading = true;
        } else if(taskTypeToGet === 'closed' && this.totalClosed > 0){
            this.closedSectionLoading = true;
        }

        //Server Side Call
        TaskCall({recordId: this.recordId, openOrClosed: taskTypeToGet, offSet: offsetToUse})
        .then((result) => {
            if (result) {
                if(taskTypeToGet === 'open' && !this.totalOpen){
                    this.totalOpen = result.total;
                }else if(taskTypeToGet === 'closed' && !this.totalClosed) {
                    this.totalClosed = result.total;
                }

                //create custom array of task info
                this.processData(result.tasks);
            }
        })
        .then(() => {
            //using the custom array of task info, set the showMore button to be visible or not
            this.checkShowHideViewMore();
            this.openSectionLoading = false;
            this.closedSectionLoading = false;

            //disable loading
            this.isLoaded = true;
        })
        .catch((err) => {
            this.showNotification('Error', 'There was an error retrieving all tasks', 'error')
        })
    }

    handelOpenCloseSection(event) {
        let sectionToUpdate = event.currentTarget.dataset.section;

        if(sectionToUpdate === 'open'){
            if(this.openTasksSection.includes('slds-is-open')){
                this.openTasksSection = 'slds-section';
            }else{
                this.openTasksSection = 'slds-section slds-is-open';
            }
        } else if(sectionToUpdate === 'closed'){
            if(this.closedTasksSection.includes('slds-is-open')){
                this.closedTasksSection = 'slds-section';
            }else{
                this.closedTasksSection = 'slds-section slds-is-open';
            }
        }

        this.checkShowHideViewMore();
    }

    processData(data){

        data.map(item => {
            let tempObj = {
                id: item.Id,
                subject: item.Subject,
                dueDate: this.getDueDate(item.ActivityDate),
                subHeading: this.getSubHeading(item),
                description: item.Description,
                category: item.Category__c,
                type: item.Type,
                expandableSectionId:  item.Id+'-detailsSection',
                expandClass: 'slds-timeline__item_expandable slds-timeline__item_task slds-section',
                taskSectionIcon: 'utility:chevronright',
                dueDateStyle: ''
            }

            if(new Date(item.ActivityDate) < new Date() && tempObj.dueDate !== 'Today' && item.Status !== 'Completed'){
                tempObj.dueDateStyle = 'overdue'
            }
                
            if(item.Status === 'Completed'){
                this.closedTasks.push(tempObj);
            } else{
                this.openTasks.push(tempObj);
            }
        })
    }

    getDueDate(date){
        let dateCast;
        try{
            dateCast = new Date(date);
        } catch(err){
            this.showNotification('Error', 'There was error when trying to displaying tasks. Please contact your Administrator', 'error')
        }
        
        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "June",
            "July", "Aug", "Sept", "Oct", "Nov", "Dec"];
        let returnVal = '';
        let today = new Date();
       
        let tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        
        let yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
    
        if(!date){
            returnVal = 'No due date'
        }
        else if(today.toDateString() === dateCast.toDateString()){
            returnVal = 'Today'
        } else if(tomorrow.toDateString() === dateCast.toDateString()){
            returnVal = 'Tomorrow'
        } else if(yesterday.toDateString() === dateCast.toDateString()){
            returnVal = 'Yesterday'
        } else{
            returnVal = dateCast.getDate() + ' ' + monthNames[dateCast.getMonth()]
        }

        return returnVal
    }

    getSubHeading(item){
        let user;
        let pastOrPresent;
        let returnString;
        let communityUrl = window.location.origin

        if(item.OwnerId === strUserId){
            user = 'You '
        } else{
            const userLink = communityUrl+ basePath + '/profile/' + item.OwnerId
            user = '<a href=' + userLink + '>'+ item.Owner.Name + '</a> '
        }

        if(item.Status !== 'Completed'){
            if(user === 'You '){
                pastOrPresent = 'have an upcoming task'
            } else{
                pastOrPresent = 'has an upcoming task'
            }
        } else{
            pastOrPresent = 'had a task'
        }

        if(item.Who && item.Who.Name){
            const contactLink = communityUrl + basePath + '/detail/' + item.WhoId
            returnString = user + pastOrPresent + ' with <a href=' + contactLink + '>' + item.Who.Name + '</a>';
        } else{
            returnString = user + pastOrPresent
        }

        return returnString
    }

    handleViewMore(event){
        this.getTasks(event.currentTarget.dataset.section)
    }

    checkShowHideViewMore(){
        this.showViewMoreOpen = (this.openTasksSection.includes('slds-is-open'))
        this.showViewMoreOpenButton = (this.openTasks.length < this.totalOpen && this.totalOpen > 0)
        this.showViewMoreClosed = (this.closedTasksSection.includes('slds-is-open'))
        this.showViewMoreClosedButton = (this.closedTasks.length < this.totalClosed && this.totalClosed > 0);
    }

    showNotification(header, msg, type) {
        const evt = new ShowToastEvent({
            title: header,
            message: msg,
            variant: type,
        });
        
        dispatchEvent(evt);
    }
}