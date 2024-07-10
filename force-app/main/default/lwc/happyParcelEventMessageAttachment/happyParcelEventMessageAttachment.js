/**
 * @description Retrieve the event message attachment image, by passing in the GUID, and display the image.
 * @author Ranjeewa Silva
 * @date 2021-05-07
 * @changelog
 * 2021-05-07 - Ranjeewa Silva - Created
 * 2024-06-25 - Raghav Ravipati - changes to retrieveAttachmentImage method which uses Deliveryrepository V2 API
 */

import { api, LightningElement } from 'lwc';
import { getConfig, getSafeDropImage } from 'c/happyParcelService';

export default class HappyParcelEventMessageAttachment extends LightningElement {

	// id of the event message with this attachment
	@api eventId;

	// type of the attachment as returned by SAP EM. e.g. NO_SIG_REQUIRED
	@api attachmentType;

	// attachment guid returned. pass this to TIBCO API to retrieve the image.
	@api guid;

	// error message received on retrieving the attachment
	attachmentErrorMessage;

	// base64 representation of the attachment image
	base64AttachmentImage;

	// indicates the image is being loaded
	loadingAttachmentImage = false;

	// attachment type definitions with display labels
	_attachmentTypeDefinitions;

	connectedCallback() {

		// grab the attachment type definitions
		getConfig().then(result => {
			if (result.eventMessageAttachmentTypeDefinitions) {
				this._attachmentTypeDefinitions = result.eventMessageAttachmentTypeDefinitions;
			}
		});

		if (this.guid) {
			// if the parent has passed in a GUID, retrieve the image
			this.retrieveAttachmentImage();
		}
	}

	get attachmentTitle() {
		if (this._attachmentTypeDefinitions && this._attachmentTypeDefinitions[this.attachmentType]) {
			return this._attachmentTypeDefinitions[this.attachmentType].Label;
		}
		return this.attachmentType;
	}


	/**
	 * This call into the server to retrieve the image to display within Happy Parcel
	 */
	async retrieveAttachmentImage() {
		this.loadingAttachmentImage = true;

		// perform the callout to the api and grab the split details from the result
		const result = await getSafeDropImage(this.guid, this.attachmentType);

		if(result.isError) {
			this.attachmentErrorMessage = result.errors[0];
			this.base64AttachmentImage = null;
		} else {
			this.attachmentErrorMessage = '';
			this.base64AttachmentImage;
			if( result.document && result.document.object_details){
				this.base64AttachmentImage = 'data:image/jpeg;base64,'+ result.document.object_details.object_content;
			}
		}

		this.loadingAttachmentImage = false;
	}

	closeAttachmentModal() {
		this.dispatchEvent(new CustomEvent('closeattachmentview', {detail: this.eventId}));
	}

}