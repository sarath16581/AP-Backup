import { LightningElement, track } from 'lwc';
 
export default class MyNetworkCaseAssignedToPopUp extends LightningElement {
    @track selectedUserId;
    closeModal(){
        console.log('ClodeModal popup');
        this.dispatchEvent(new CustomEvent('closemodalpopup')); 
    }
    saveModal(){
        this.dispatchEvent(new CustomEvent('assignuser', {detail: this.selectedUserId}));
        
    }
    searchResultSelectHandler = (record) => {
        console.log('selected record Id >>>',record.Id);
        this.selectedUserId = record.Id;
    }
}