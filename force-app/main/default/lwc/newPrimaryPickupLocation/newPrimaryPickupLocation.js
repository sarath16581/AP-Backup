/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 26/05/2021
  * @description  : This lWC component is used in Sub Account Request creation from CSQ Quick Action. It has following features
  *                 1. It contains the pickup location creation input form.
*********************************History*******************************************************************
26.05.2021    Dheeraj Mandavilli   Created
*/

import {LightningElement,api,track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import createPickupLocations from '@salesforce/apex/CSQ_PickupLocationUtility.createPickupLocation';

export default class NewPrimaryPickupLocation extends NavigationMixin(LightningElement) {
@api recordId;
@track isRequired = true;
@track fieldList = [];
@track showValidationErr= false;
@track errField = '';
@track street= '';
@track city = '';
@track state = '';
@track postcode = '';
@track isSenderAddressRequired = true;
senderAddressVar;
@track csqId='';
@track locationDetails='';
@track locationStatus='';
@track freightOffering='';
@track locationType='';
@track siteInspection='';
@track inspectionStatus='';
@track inspectionCompleted = '';
@track inspectorName='';
@track notes= '';
@api isModalOpen = false;
@track locId ='';
@track dpId= '';
@track openModal = false;
@track pickupLocationRecord;
@track message= '';


    connectedCallback() {

        this.csqId=this.recordId;
        console.log('CSQ Id::',this.csqId);

    }

    onchangehandler(event){
        console.log('Coming here');
        this.showValidationErr = false;
        this.errfield = '';
        this.fieldList = [];
        this.fieldList.push(this.errField);
        if(event.target.name === "CSQ") {
            this.csqId = event.target.value;
            console.log('CSQ Id:::',this.csqId);
        }
        else if(event.target.name === "Location Details") {
            this.locationDetails = event.target.value;
            console.log('Location details:::',this.locationDetails);
        }else if(event.target.name === "Location Status"){
            this.locationStatus = event.target.value;
            console.log('locationStatus :::',this.locationStatus);
        } else if(event.target.name === "Freight Offering"){
            this.freightOffering = event.target.value;
            console.log('freightOffering :::',this.freightOffering);
        }else if(event.target.name === "Location Type"){
            this.locationType =event.target.value;
            console.log('locationType::',this.locationType);
        }else if(event.target.name === "Site Inspection"){
            this.siteInspection = event.target.value;
            console.log("siteInspection::",this.siteInspection);
        } else if(event.target.name === "Inspection Status"){
            this.inspectionStatus = event.target.value;
            console.log("inspectionStatus::",this.inspectionStatus);
        }else if(event.target.name === "Inspection Completed"){
            this.inspectionCompleted = event.target.value;
            console.log("inspectionCompleted::",this.inspectionCompleted);
        }
        else if(event.target.name === "Inspector Name"){
            this.inspectorName = event.target.value;
            console.log("inspectorName::",this.inspectorName);
        }else if(event.target.name === "Notes"){
            this.notes = event.target.value;
            console.log("notes::",this.notes);
        }
        else if(event.target.name === "State"){
            this.state = event.target.value;
            console.log("notes::",this.state);
        }

    }


    onsubmitHandler(event){
        console.log('inside onsubmitHandler>>>1');
        // let errField = '' ;
        this.showValidationErr = false;

        if(this.csqId === null || this.csqId === undefined || this.csqId === ''){
            console.log('subAccountName:::',this.subAccountName);
            this.errField = 'CSQ field cannot be Blank.Please Enter Value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.freightOffering === null || this.freightOffering === undefined || this.freightOffering === ''){
            this.errField = 'Freight Offering field cannot be Blank. Please Enter Value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.locationType === null || this.locationType === undefined || this.locationType === ''){
            this.errField = 'Location Type field cannot be Blank.Please Enter Value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.street === '' || this.street === null || this.street === undefined ){
            this.errField = 'Please input valid street value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.city === '' || this.city === null || this.city === undefined){
            this.errField = 'Please input valid city value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.state === '' || this.state === null || this.state === undefined ){
            this.errField = 'Please input valid state value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.postcode === '' || this.postcode === null || this.postcode === undefined){
            this.errField = 'Please input valid postcode value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(!this.showValidationErr){
            this.pickupLocationRecord = {
                CSQ__c:this.csqId,
                Pick_Up_location_Details__c: this.locationDetails,
                Pick_up_Location_Status__c:this.locationStatus,
                Freight_Offering__c : this.freightOffering,
                Location_Type__c : this.locationType,
                Required_Site_Inspection__c : this.siteInspection,
                Site_Inspection_Status__c :this.inspectionStatus,
                Site_Inspection_Completed__c : this.inspectionCompleted,
                Inspector_Name__c : this.inspectorName,
                Notes__c : this.notes,
                Address__c : this.street,
                Suburb__c : this.city,
                State__c : this.state,
                Postcode__c : this.postcode,
                DPID__c : this.dpId
            }

            createPickupLocations({ pickupLocRec: this.pickupLocationRecord})
                .then(result =>{
                console.log('Record Created>>',result);
                this.locId = result;

            if(result != null){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Pickup Location created Successfully',
                        variant: 'success'
                    })
                );
                //Navigate to List View after record creation
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.locId,
                        objectApiName: 'Pick_Up_Location__c',
                        actionName: 'view'
                    },
                });
            }

        })
        .catch(error =>{
                if (error.body.message) {
                this.message = error.body.message;
                if(this.message.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")){
                    this.message ='The selected Customer Scoping Questionnaire (CSQ) does not match the Freight Offering (CSQ). Please select a Freight Offering that is linked to the same CSQ as the associated Pickup Location.';
                    alert(this.message);
                }else{
                    alert(this.message);
                }
            }
        })

        }
    }

    cancel(){
        this.dispatchEvent(new CustomEvent('close'));
    }


    handleStreetValueChange(event) {

        this.showValidationErr = false;
        this.errfield = '';
        this.fieldList = [];
        this.fieldList.push(this.errField);

        this.address = event.detail;
        console.log('Address in booking location form ::',this.address);

        console.log('Address Line 2  ::',this.address.addressLine2);
        if(this.address.addressLine1 !== undefined && this.address.addressLine2 !== undefined){
            this.street = this.address.addressLine1+' '+this.address.addressLine2;
        }else{
            this.street = this.address.addressLine1;
        }
        console.log('Street Name  ::',this.street);

        this.city=this.address.city;
        console.log('City Name  ::',this.city);

        this.postcode=this.address.postcode;
        console.log('Post code ::',this.postcode);

        this.state=this.address.state;
        console.log('State Name ::',this.state);

        this.dpId = this.address.dpid;
        console.log('Dp Id ::',this.dpId);
    }


}