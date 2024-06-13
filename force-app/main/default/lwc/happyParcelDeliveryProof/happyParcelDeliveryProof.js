/**
 * @description Happy Parcel Delivery Proof including surfacing safe drop image and signature on delivery
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-09-11 - Ranjeewa Silva - Refactored to cater for the scenario where events setter is called before "connectedCallback" lifecycle hook.
 * 2020-09-27 - Nathan Franklin - Changed Safe Drop eligibility functions and added pubsub methods
 * 2020-10-05 - Disha Kariya - Allow safe drop attachment for case creation
 * 2021-10-06 - Nathan Franklin - Changed the logic behind attaching delivery proof to case + uplift to v52
 * 2024-06-13 - Seth Heang - Update the Proof Of Delivery PDF Download logic to perform consignment search and bulk retrieve safe drop images if applicable prior to downloading the PDF
 */
import { api, track, LightningElement } from "lwc";
import {
	getConfig,
	getSafeDropEligibilityStatus,
	addSafeDrop,
	deleteSafeDrop,
	getSafeDropImage,
	CONSTANTS,
	get,
	subscribe,
	unsubscribe,
	publish,
	downloadDeliveryProofPdf,
	getSafeDropImageStateForDownload,
	getSafeDropImageAndSaveForPOD,
	getTrackingApiResponse, getTrackingApiResponseForStarTrack
} from 'c/happyParcelService';
import HappyParcelBase from "c/happyParcelBase";

export default class HappyParcelDeliveryProof extends HappyParcelBase {

	// Used to register a call to retrigger fetching the safe drop status after a safe drop submission has been made
	_componentGuid = '';

	// the event types used for signature on delivery
	_signatureEventTypes = [];

	// events received from parent
	_events = [];

	// if this is true then this allows happyParcelDeliveryProof component to attach safe drop image on Case creation.
    // when the component is clicked, attachdeliveryproof event is generated and propagated up the DOM
	@api supportsDeliveryProofAttachment;

	@api loading = false;

	//if the article is selected this is valid when a consignment is searched for
	@api parentArticleSelected;

	// when we call to get the safe drop eligibility we set this var so we can continue to display the spinner until the article safe drop aspect is fully loaded
	@track loadingSafeDropEligibility = false;

	// if the signature image is available it will exist on a single event message in the SignatureXString field on EventMessage__c
	// we check this field for the list of predefined events that support this attachment as per the config we retrieve in connectedCallback()
	@track consignmentId;
	@track trackingId;
	@track base64SignatureImage;
	@track signatoryName = '';
	@track signatureRequired = false;
	@track safeDropGuid;

	// determines whether or not the Safe Drop Image model should be visible
	@track showSafeDropModel;

	// causes a spinner to be shown in the modal while a call is being made to retrieve the safe drop image from the server
	@track loadingSafeDropImage;

	// a base64 image populated when the user clicks to show safe drop image
	@track base64SafeDropImage;

	// used to display the error message when safe drop image fails to load
	@track safeDropImageErrorMessage;

	// this stores the result of checking for Safe drop eligibility
	@track safeDropEligibilityStatus;
	
	// when a safe drop preference is set or unset, this is the status message that displays the result
	// this is only displayed for x seconds before disappearing
	@track safeDropPreferenceStatusMessage;

	// when the download button is clicked, we block the ui until the download completes
	waitingDownload = false;

	/**
	 * Where supportsDeliveryProofAttachment is true, this stores the option whether to attach the delivery proof or not to the created case
	 */
	attachDeliveryProof = false;

	signatureHelpText = CONSTANTS.LABEL_HAPPYPARCELSIGNATUREHELPTEXT;
	deliveryProofHelpText = CONSTANTS.LABEL_HAPPYPARCELDELIVERYPROOFHELPTEXT;

	/**
	 * This occurs on the completion of an article search (in the parent)
	 * Simply grab out the data we need from article, store that and discard the rest
	 * This ensures optmial memory consumption
	 */
	@api
	get article() { return null; };
	set article(value) {
		if(value) {
			this.signatureRequired = value.SignatureRequiredFlag__c;
			this.trackingId = value.ArticleID__c;
			this.consignmentId = value.ConsignmentTrackingNumber__c;

			// trigger a search to get the safe drop eligibility status
			// not sure why the API needs articleId and trackingId ??
			this.doGetSafeDropEligibility();
		} else {
			this.signatureRequired = false;
			this.trackingId = '';
		}
	}

	/**
	 * This occurs on the completion of an article search (in the parent)
	 * Store the events and extract delivery proof details from the events received.
	 */
	@api
	get events() { return _events; }
	set events(value) {
		if(value) {
		    this._events = value;
		} else {
		    this._events = [];
		}
		this.setDeliveryProof(this._events);
	}

    /**
     * Extract signature on delivery and safe drop image details from the events passed in.
     */
	setDeliveryProof(events) {
	    if (events && events.length > 0) {
	        events.forEach(item => {
                if (this._signatureEventTypes.includes(item.event.EventType__c) && item.event.SignatureXString__c) {
                    this.base64SignatureImage = 'data:image/jpeg;base64,' + item.event.SignatureXString__c;
                    this.signatoryName = item.event.SignatoryName__c;
                }

                // check for SafeDropGUID (we don't check for specific event types since an 'attachment type' check is done when the article is queried from the tracking API
                if (item.event.Safe_Drop_GUID__c) {
                    this.safeDropGuid = item.event.Safe_Drop_GUID__c;
                }
            });
        } else {
            this.base64SignatureImage = '';
            this.signatoryName = '';
            this.safeDropGuid = '';
        }
    }

	connectedCallback() {
		// grab a list of event types to monitor for with signature for delivery
		getConfig().then(result => {
			this._signatureEventTypes = result.signatureEventTypes;

			// now that signature event types are known, check if event data is available.
			// if available, extract delivery proof details.
			if (this._events && this._events.length > 0) {
    			this.setDeliveryProof(this._events);
    		}
		});

		subscribe('SafedropEligibilityRefresh', this.doGetSafeDropEligibility);
	}

	disconnectedCallback() {
		unsubscribe('SafedropEligibilityRefresh', this.doGetSafeDropEligibility);
	}

	handleShowSafeDropClick() {
		this.showSafeDropModel = true;
		this.retrieveSafeDropImage();
	}

	closeSafeDropModal() {
		this.showSafeDropModel = false;
	}

	handleDeliveryProofCheckboxClicked(event){
		if(this.trackingId) {
			this.attachDeliveryProof = event.target.checked;

		    const detail = {trackingId : this.trackingId, selected : this.attachDeliveryProof};
			this.dispatchEvent(new CustomEvent('attachdeliveryproof', { detail: detail, bubbles: true, composed: true }));
  		}
 	}

	/**
	 * When the user clicks the camera icon to load the safe drop image
	 * This will call into the server to retrieve the image to display within the modal in Happy Parcel
	 */
	async retrieveSafeDropImage() {
		this.loadingSafeDropImage = true;

		// perform the callout to the api and grab the split details from the result
		const result = await getSafeDropImage(this.safeDropGuid);

		if(result.isError) {
			this.safeDropImageErrorMessage = result.errorMessage;
			this.base64SafeDropImage = null;
		} else {
			this.safeDropImageErrorMessage = '';
			this.base64SafeDropImage = 'data:image/jpeg;base64,' + result.imageBody;
		}

		this.loadingSafeDropImage = false;
	}

	/**
	 * When a new article is set in this component, we automatically trigger the search to check for safe drop eligibility of the article
	 * Not sure why the API needs articleId and trackingId ??
	 *
	 * this method is passed as callback in pubsub
	 */
	doGetSafeDropEligibility = async () => {
		this.loadingSafeDropEligibility = true;

		// perform the actual callout to the api
		this.safeDropEligibilityStatus = await getSafeDropEligibilityStatus(this.trackingId);

		this.loadingSafeDropEligibility = false;
	}

	/**
	 * If the article is eligible for safe drop this will request safe drop in Sap-Em
	 */
	async doSetSafeDropPreference() {
		// display the loading for the happy-parcel-card
		this.loadingSafeDropEligibility = true;

		// perform the actual callout to the api
		const result = await addSafeDrop((this.consignmentId ? this.consignmentId : this.trackingId));

		// show the result
		this.setSafeDropPreferenceStatusMessage(result);

		// refresh the safe drop status
		// incase we are viewing a consignment, we use a pubsub to notify all the components to refresh safe drop status
		publish('SafedropEligibilityRefresh', {});
	}

	/**
	 * Remove the safe drop preference if it has already been requested
	 */
	async doUnsetSafeDropPreference() {
		this.loadingSafeDropEligibility = true;

		// perform the actual callout to the api
		const result = await deleteSafeDrop((this.consignmentId ? this.consignmentId : this.trackingId));

		// show the result
		this.setSafeDropPreferenceStatusMessage(result);

		// refresh the safe drop status
		// incase we are viewing a consignment, we use a pubsub to notify all the components to refresh safe drop status
		publish('SafedropEligibilityRefresh', {});
	}

	/**
	 * When a result is fed back from set or unset safedrop preferences, this message is set and displayed for x seconds before disappearing
	 */
	setSafeDropPreferenceStatusMessage(message) {
		this.safeDropPreferenceStatusMessage = message;
		setTimeout(() => {
			this.safeDropPreferenceStatusMessage = '';
		}, 3000);
	}

	handleSetSafeDrop() {
		this.doSetSafeDropPreference();
	}

	handleUnsetSafeDrop() {
		this.doUnsetSafeDropPreference();
	}

	/**
	 * Triggers a download of DeliveryProof PDF
	 */
	async handleDownloadDeliveryProof() {
		this.waitingDownload = true;

		// wrap in try/catch to ensure waiting attribute is removed
		try {
			const sapResult = this.consignmentId  ? await getTrackingApiResponse(this.consignmentId, false)
				: await getTrackingApiResponse(this.trackingId, true)
			// execute a consignment search for StarTrack if required
			const requireAdditionalQueryForStarTrack = sapResult.requireAdditionalQueryForStarTrack;
			const consignment = { trackingId: sapResult.consignment.trackingId, trackingResult: sapResult.consignment};
			if(requireAdditionalQueryForStarTrack){
				// if this api timeout, then the download button needed to be clicked again to retry
				await getTrackingApiResponseForStarTrack(sapResult.consignment.trackingId, consignment);
			}

			// retrieve the current state of safe drop images caches in Salesforce
			const safeDropImageState = await getSafeDropImageStateForDownload(this.trackingId);
			// download safe drop images as required if they do not exist in Salesforce
			await this.processSafeDropImagesDownloading(safeDropImageState);

			// execute the VF pdf page generator logic in controller
			const pdfBase64 = await downloadDeliveryProofPdf(this.trackingId);

			const fileName = 'DeliveryProof-' + encodeURIComponent(this.trackingId) + '.pdf';

			// deal with IE
			if (navigator && navigator.msSaveBlob) { // IE10+
				return navigator.msSaveBlob(new Blob([pdfBase64], { type: '.pdf' }), fileName);
			}

			// now download the generated content
			const downloadElement = document.createElement('a');
			downloadElement.href = 'data:application/octet-stream;base64,' + encodeURIComponent(pdfBase64);
			downloadElement.target = '_self';
			downloadElement.download = fileName;
			document.body.appendChild(downloadElement);
			downloadElement.click();
		} catch(exception) {
			console.error(exception);
		}
		this.waitingDownload = false;
	}

	/**
	 * @description Download SafeDropImage in bulk by looping through the SafeDropState array object and split callout in multiple transactions
	 * @param {Array} safeDropImageState - The array of objects containing guidId and requireDownload
	 * @returns {Promise<void>}
	 */
	async processSafeDropImagesDownloading(safeDropImageState) {
		for (let i = 0; i < safeDropImageState.length; i++) {
			if (safeDropImageState[i].requireDownload) {
				try {
					const result = await getSafeDropImageAndSaveForPOD(safeDropImageState[i].guidId, safeDropImageState[i].eventMessageId);
					if (!result.isError) {
						safeDropImageState[i].requireDownload = false;
					}
				} catch (error) {
					console.error('Failed to download image for guidId:', safeDropImageState[i].guidId, error);
				}
			}
		}
	}

	get safeDropLoading() {
		return this.loading || this.loadingSafeDropEligibility || this.waitingDownload;
	}

	get signatureLoading() {
		return this.loading || this.waitingDownload;
	}

	get eligibilityStatusLabel() {
		return (!this.safeDropEligibilityStatus ? '' : (this.safeDropEligibilityStatus.success ? get(this.safeDropEligibilityStatus, 'status.eligibilityLabel', '') : get(this.safeDropEligibilityStatus, 'error', '')));
	}

	get eligibilityStatus() {
		return (!this.safeDropEligibilityStatus ? '' : (this.safeDropEligibilityStatus.success ? get(this.safeDropEligibilityStatus, 'status.statusValue', '') : 'Error'));
	}

	get canShowEligibilityStatus() {
		return (!this.safeDropEligibilityStatus ? false : get(this.safeDropEligibilityStatus, 'status.showStatus', false));
	}

	get canShowSetSafeDropOption() {
		return (!this.safeDropEligibilityStatus ? false : get(this.safeDropEligibilityStatus, 'status.isSafeDropSettable', false));
	}
	get canShowUnsetSafeDropOption() {
		return (!this.safeDropEligibilityStatus ? false : get(this.safeDropEligibilityStatus, 'status.isSafeDropUnsettable', false));
	}

	/**
	 * Returns the css class for the section where the ICON and status text is displayed
	 * This is just incase we need to factor in the camera icon (if the safe drop guid exists)
	 */
	get safeDropContentCssClass() {
		return 'slds-col slds-align_absolute-center slds-p-around_medium' + (this.safeDropGuid ? ' slds-medium-size_1-of-2' : '');
	}

	get canShowSafeDropAttach() {
		return this.supportsDeliveryProofAttachment && this.safeDropGuid;
	}

	get canShowSignatureAttach() {
		return this.supportsDeliveryProofAttachment && this.base64SignatureImage;
	}

	get canShowSafeDropDownload() {
		return !this.safeDropLoading && this.safeDropGuid;
	}

	get canShowSignatureDownload() {
		return !this.signatureLoading && this.base64SignatureImage;
	}

	get rightSignatureHeadingPadding() {
		return (this.canShowSignatureAttach ? "80" : "0");
	}

	get rightSafedropHeadingPadding() {
		return (this.canShowSafeDropAttach ? "80" : "0");
	}

	get safeDropDisabled() {
	    return !!this.parentArticleSelected;
    }

	get safeDropCardBodyCssClass() {
		return 'full-height-container animated pulse' + (this.safeDropGuid ? ' slds-p-bottom_medium' : '');
	}

	get signatureCardBodyCssClass() {
		return 'full-height-container animated pulse' + (this.base64SignatureImage ? ' slds-p-bottom_medium' : '');
	}

}