/**
 * @description Lookup customer address in AME and populate booking location address. Also supports manual address override.
 * @author Dheeraj Mandavilli
 * @date 2019-10-07
 * @changelog
 * 2019-10-07 - Dheeraj Mandavilli - Created
 * 2021-08-27 - Ranjeewa Silva - Refactored and upgraded to use newer version of ame address lookup LWC - c-ame-address-validation2.
 */

import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { reduceErrors } from 'c/ldsUtils';
import { get } from 'c/utils';

import LABEL_INVALID_ADDRESS_ERROR_MESSAGE from '@salesforce/label/c.PUDInvalidBookingLocationAddressErrorMessage';
import FIELD_ID from '@salesforce/schema/PUD_Booking_Location__c.Id';
import FIELD_STREET from '@salesforce/schema/PUD_Booking_Location__c.Street__c';
import FIELD_CITY from '@salesforce/schema/PUD_Booking_Location__c.City__c';
import FIELD_STATE from '@salesforce/schema/PUD_Booking_Location__c.State__c';
import FIELD_POSTCODE from '@salesforce/schema/PUD_Booking_Location__c.Post_Code__c';
import FIELD_DPID from '@salesforce/schema/PUD_Booking_Location__c.DPID__c';
import FIELD_SIDE_OF_STREET from '@salesforce/schema/PUD_Booking_Location__c.Side_Of_Street_Code__c';

// lightning/uiRecordApi does not support geolocation compound fields imported via schema field imports.
// requires the constituent fields to be specified in string syntax
const FIELDNAME_GEO_LATITUDE = 'Geo__Latitude__s';
const FIELDNAME_GEO_LONGITUDE = 'Geo__Longitude__s';
const FIELDNAME_FRONTAGE_GEO_LATITUDE = 'Frontage_Geo__Latitude__s';
const FIELDNAME_FRONTAGE_GEO_LONGITUDE = 'Frontage_Geo__Longitude__s';

export default class PudBookingLocationAddressLookup2 extends NavigationMixin(LightningElement) {

    // booking location record id populated by LWC framework
    @api recordId;

    // new customer address details captured via AME lookup / manual override
    address;

    // indicates if the currently captured address satisfy on screen validations
    isAddressValid = false;

    // error message to be displayed on save
    errorMessage;

    // handler called when the address is manually entered/updated
    handleAddressUpdated(event) {
        if (event.detail) {
            this.errorMessage = null;
            this.address = event.detail;
            // check if currentl captured address satisfy all validations.
            this.isAddressValid = this.checkValidity();
        }
    }

    // handler called when the address is selected from AME search results
    handleAddressSelected(event) {
        if (event.detail) {
            this.errorMessage = null;
            this.address = event.detail;
            // check if currently captured address satisfy all validations.
            this.isAddressValid = this.checkValidity();
        }
    }

    // handler called when attempting to save the new address details onto booking location
    updateBookingLocationAddress() {

        // check if the currently captured address is valid
        if (this.isAddressValid && this.checkValidity()) {

            // address is valid - update address on booking location
            const fields = {};
            fields[FIELD_ID.fieldApiName] = this.recordId;
            fields[FIELD_STREET.fieldApiName] = (this.address.addressLine2 ? this.address.addressLine1 + ' ' + this.address.addressLine2 : this.address.addressLine1);
            fields[FIELD_CITY.fieldApiName] = this.address.city;
            fields[FIELD_STATE.fieldApiName] = this.address.state;
            fields[FIELD_POSTCODE.fieldApiName] = this.address.postcode;
            fields[FIELDNAME_GEO_LATITUDE] = get(this.address, 'latitude', null);
            fields[FIELDNAME_GEO_LONGITUDE] = get(this.address, 'longitude', null);
            fields[FIELD_DPID.fieldApiName] = get(this.address, 'dpid', null);
            fields[FIELD_SIDE_OF_STREET.fieldApiName] = get(this.address, 'deliveryData.sideOfStreetCode', null);

            // extract the frontage geo data if available
            const [frontageGeo] =  get(this.address, 'geoDataList', []).filter(item => {
                return (item.featureType === 'GNAF_FRONTAGE' && item.latitude && item.longitude);
            });
            fields[FIELDNAME_FRONTAGE_GEO_LATITUDE] = ((frontageGeo && frontageGeo.latitude) ? frontageGeo.latitude: null);
            fields[FIELDNAME_FRONTAGE_GEO_LONGITUDE] = ((frontageGeo && frontageGeo.longitude) ? frontageGeo.longitude: null);

            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Booking Location Updated Successfully',
                            variant: 'success'
                        })
                    );

                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,
                            objectApiName: 'PUD_Booking_Location__c',
                            actionName: 'view'
                        }
                    });

                }).catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error saving customer address',
                            message:reduceErrors(error).join(', '),
                            variant: 'error',
                        })
                    );
                });
        } else {
            this.errorMessage = LABEL_INVALID_ADDRESS_ERROR_MESSAGE;
        }
    }

    // validate input components, report validity on UI and returns true if valid.
    checkValidity() {
        const allValid = [...this.template.querySelectorAll('c-ame-address-validation2')]
            .reduce((validSoFar, ameAddressCmp) => {
                return validSoFar && ameAddressCmp.checkValidity();
            }, true);
        return allValid;
    }
}