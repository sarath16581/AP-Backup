/* eslint-disable no-console */
//Create job. Called from global action Create Job
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import getBooking from '@salesforce/apex/pudCreateJobRecord.getBooking';
//import pudCreateJobRecord from '@salesforce/apex/pudCreateJobRecord.createJob';
import pudCreateBkgExp from '@salesforce/apex/PUDUtility.noPickupfromBookingLocation';
//import noPickupfromBookingLocation from '@salesforce/apex/PUDUtility.noPickupfromBookingLocation';
import { createRecord } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';
import { NavigationMixin } from 'lightning/navigation';
import EXCEPTION_OBJECT from '@salesforce/schema/PUD_Booking_Exception__c';
import STARTDATE_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.Start_Date__c';
import ENDDATE_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.End_Date__c';
import MONDAY_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.Monday__c';
import TUESDAY_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.Tuesday__c';
import WEDNESDAY_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.Wednesday__c';
import THURSDAY_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.Thursday__c';
import FRIDAY_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.Friday__c';
import SATURDAY_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.Saturday__c';
import SUNDAY_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.Sunday__c';
import BOOKING_FIELD from '@salesforce/schema/PUD_Booking_Exception__c.Booking__c';

export default class PudCreateBookingException extends NavigationMixin(LightningElement) {
    @api recordId;
    @track pudBooking = null;
    @track startdate;
    @track enddate;
    @track areDetailsVisible = false;
    @track error = false;
    @track errorMessage = null;

    //define local variables
    bookingid='';
    monday= true;
    tuesday= true;
    wednesday= true;
    thursday= true;
    friday= true;
    saturday= false;
    sunday= false;
    booklocId ='';
    expRec = false;


    connectedCallback() {
        this.loadBookingLocationRecord();
    }

    async loadBookingLocationRecord() {
            console.log("XXX record id", this.recordId);
            this.booklocId = this.recordId;
            // force waiting before the interface loads
            let pudBooking = await pudCreateBkgExp({bookingLocId: this.recordId})
            //pudBooking = JSON.parse(pudBooking);

            console.log("pud booking", pudBooking);
            if (pudBooking.length === 18) {
                this.bookingid = pudBooking;
                console.log("bookingid", this.bookingid);
                this.areDetailsVisible = true;
            } else {
                this.error = true;
                this.errorMessage = pudBooking;
            }
    } 
    
    handleStartDateChange(event) {
        this.startdate = event.target.value;
        console.log("StartDate",this.startdate);
    }
    handleEndDateChange(event) {
        this.enddate = event.target.value;
        console.log("EndDate",this.enddate);
    }
    handleMondayChange(event) {
        this.monday = event.target.value;
        console.log("mon",this.monday);
    }
    handleTuesdayChange(event) {
        this.tuesday = event.target.value;
    }
    handleWednesdayChange(event) {
        this.wednesday = event.target.value;
    }
    handleThursdayChange(event) {
        this.thursday = event.target.value;
    }
    handleFridayChange(event) {
        this.friday = event.target.value;
    }
    handleSaturdayChange(event) {
        this.saturday = event.target.value;
    }
    handleSundayChange(event) {
        this.sunday = event.target.value;
    }

    createBookingExp(){

        const fields = {};
        fields[BOOKING_FIELD.fieldApiName] = this.bookingid;
        fields[STARTDATE_FIELD.fieldApiName] = this.startdate;
        fields[ENDDATE_FIELD.fieldApiName] = this.enddate;
        fields[MONDAY_FIELD.fieldApiName] = this.monday;
        fields[TUESDAY_FIELD.fieldApiName] = this.tuesday;
        fields[WEDNESDAY_FIELD.fieldApiName] = this.wednesday;
        fields[THURSDAY_FIELD.fieldApiName] = this.thursday;
        fields[FRIDAY_FIELD.fieldApiName] = this.friday;
        fields[SATURDAY_FIELD.fieldApiName] = this.saturday;
        fields[SUNDAY_FIELD.fieldApiName] = this.sunday;
        console.log('ExpRec value before if:::',this.expRec);
        if(this.expRec === false){
        const recordInput = { apiName: EXCEPTION_OBJECT.objectApiName, fields };
        this.expRec = true;
        createRecord(recordInput)
            .then(PUD_Booking_Exception__c => {
            this.recordId = PUD_Booking_Exception__c.id;
            console.log('Record Id', this.recordId);

            console.log('ExpRec value after record creation:::',this.expRec);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'No Pickup created successfully',
                    variant: 'success'
                })
            )
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.booklocId,
                    objectApiName: 'PUD_Booking_Location__c', // objectApiName is optional
                    actionName: 'view'
                }
            });

    })
    .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: reduceErrors(error).join(', '),
                    variant: 'error'
                })
            );
    });
        }

    }
}