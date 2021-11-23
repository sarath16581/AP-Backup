/**
 * Created by MandavilD on 18/02/2020.
 */

import {LightningElement,api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JobDatePicker extends NavigationMixin(LightningElement) {
@api recordId;

 type='';

    get options() {
        return [
            { label: 'Print Perm Duties', value: 'Print Perm Duties' },
            { label: 'Print Adhoc and Perm Variations', value: 'Print Adhoc and Perm Variations'},
            { label: 'Print All Duties', value: 'Print All Duties' }
        ];
    }

    handleOnChange(event){
        this.value=event.target.value;
        console.log('Value Selected', this.value);
        if(this.value==='Print Adhoc and Perm Variations'){
            this.type ='Adhoc';
            console.log('Type',this.type);
        }
        else if(this.value==='Print Perm Duties'){
            this.type = 'Perm';
            console.log('Type',this.type);
        }
        else{
            this.type ='All';
            console.log('Type',this.type);
        }
    }


    handleDateChange(event){
        this.Date__c = event.target.value;
        console.log('Date chosen ::', this.Date__c);
        console.log('Record Id===',this.recordId);
    }

    navigateToWebPage() {
        // Navigate to a URL
        if(this.Date__c != null && this.type != null ) {
            this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/apex/PUD_FutureJobPrint?id=' + this.recordId + '&date=' + this.Date__c + '&type=' + this.type
                    }
                },
                true // Replaces the current page in your browser history with the URL
            );
        }else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Enter All Mandatory Details',
                        message: 'Please Enter Date and Print Type',
                        variant: 'error'
                    })
                );
        }
    }
}