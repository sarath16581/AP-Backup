/**
 * @description Component responsible for retrieving dispatch photos from digital repository and make them available
 *              on PUD Job record pages.
 * @author Ranjeewa Silva
 * @date 2022-04-07
 * @changelog
 * 2022-04-07 - Ranjeewa Silva - Created
 */

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getPUDJobPhoto from '@salesforce/apexContinuation/PUDPickupBookingController.getDispatchPhoto';
import FIELD_JOB_PHOTO_GUID from '@salesforce/schema/PUD_Job__c.Photo_GUID__c';
import FIELD_JOB_ID from '@salesforce/schema/PUD_Job__c.Id';

export default class PudJobDispatchPhotos extends LightningElement {

	// id of the Job record populated by Lightning framework
    @api recordId;

	// details of the job record based on the record id.
    job;

	// error message displayed to the user.
    errorMessage;

	// if true, display the button to view photo.
    showPhoto;

	// indicates the photo is being loaded from the backend.
    loadingPhoto = false;

    // a base64 image populated when the user clicks to show job photo image
    base64JobPhotoImage;

    @wire(getRecord, { recordId: '$recordId', fields: [FIELD_JOB_PHOTO_GUID] })
    wiredJob({ error, data }) {
        if (data) {
            // populate the job record from the values received from wire adapter.
            this.job = {};
            this.job[FIELD_JOB_ID.fieldApiName] = data.id;
            this.job[FIELD_JOB_PHOTO_GUID.fieldApiName] = getFieldValue(data, FIELD_JOB_PHOTO_GUID);
        } else if (error) {
            // received an error - display it to the user.
            this.errorMessage = error;
        }
    }

	get isViewPhotoDisabled() {
        return !(this.job && this.job[FIELD_JOB_PHOTO_GUID.fieldApiName]);
    }

    handleViewPhoto(event) {
        if (!this.showPhoto && this.job[FIELD_JOB_PHOTO_GUID.fieldApiName]) {
            this.showPhoto = true;
            if (!this.base64JobPhotoImage){
                this.retrievePhoto(this.job[FIELD_JOB_PHOTO_GUID.fieldApiName]);
            }
        }
    }

    handleClosePhoto() {
        this.showPhoto = false;
        this.errorMessage = null;
    }

    /**
     * This call into the server to retrieve the image to display
     */
    async retrievePhoto(guid) {
        this.loadingPhoto = true;

        // perform the callout to the api and grab the split details from the result
        const result = await getPUDJobPhoto({
            guidId : guid
        });

        if(result.isError) {
            this.errorMessage = result.errorMessage;
            this.base64JobPhotoImage = null;
        } else {
            this.errorMessage = '';
            this.base64JobPhotoImage = 'data:image/jpeg;base64,' + result.documentContent;
        }

        this.loadingPhoto = false;
    }
}