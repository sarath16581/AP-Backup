/**
 * @description Happy Parcel Edd
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-10-26 disha.kariya@auspost.com.au Added delivery ETA
 * 2021-10-01 - Nathan Franklin - Refactored usage of transient attributes + uplift to version 52
 * 2024-06-08 - Seth Heang - Add getter for isStarTrackEDD
 */
import { LightningElement, api, track } from "lwc";
import { get, CONSTANTS } from "c/happyParcelService";
import HappyParcelBase from "c/happyParcelBase";

export default class HappyParcelEdd extends HappyParcelBase {

	// passed down from the top level component which show whether the tracking api call is in progress or not
	@api loadingTrackingApi = false;

	// passed down from the top level component which show whether the analytics api call is in progress or not
	@api loadingAnalyticsApi = false;

	// if this is true then a this allows a 'calculate' button to be shown on the page where an EDD is not available from SAP.
	// this is only in the event that this component is embedded in another application and not standalone
	// this is passed down to the EDD component
	@api supportsExternalEdd = false;

	@api trackingApiResult;
	@api analyticsApiResult;

	helpText = CONSTANTS.LABEL_HAPPYPARCELEDDHELPTEXT;

	/**
	 * Used to trigger a call to the external EDD capability
	 * This simply fires an event to anything listening that is capable of catching it to activate some external EDD interface somewhere (currently in Service Console)
	 * NOTE: The button only displays in the UI
	 */
	handleEddCalculateClick(e) {
		const lodgementDate = (this.trackingLodgementDate ? (new Date(this.trackingLodgementDate)).toLocaleDateString('en-AU') : '');
		const data = { 'lodgementDate': lodgementDate, 'senderPostCode': this.trackingSenderPostCode, 'receiverPostCode': this.trackingReceiverPostCode };

		// use bubbles to propagate the event through the DOM
		// use composed to push the event through the 'shadow boundry'
		// https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.events_propagation for more
		this.dispatchEvent(new CustomEvent('externaledd', { detail: data, bubbles: true, composed: true }));
	}

	// /**
	//  * Carried over from the existing solution
	//  * TODO: Change icon to something a little nicer
	//  */
	// get eddImageSrc() {
	// 	return `/img/msg_icons/${this.eddImageIconName}`;
	// }
	// get eddImageIconName() {
	// 	return get(this.trackingApiResult, 'eddImageIconName', null);
	// }

	/**
	 * These are used as a part of the dom event trigger when there is an external EDD component outside of happy parcel
	 * Trigger only when supportsExternalEdd = true
	 */
	get trackingLodgementDate() {
		return get(this.trackingApiResult, 'article.ArticleLodgementDate__c', null);
	}

	/**
	 * These are used as a part of the dom event trigger when there is an external EDD component outside of happy parcel
	 * Trigger only when supportsExternalEdd = true
	 */
	get trackingSenderPostCode() {
		return get(this.trackingApiResult, 'article.SenderPostcode__c', null);
	}

	/**
	 * These are used as a part of the dom event trigger when there is an external EDD component outside of happy parcel
	 * Trigger only when supportsExternalEdd = true
	 */
	get trackingReceiverPostCode() {
		return get(this.trackingApiResult, 'article.ReceiverPostcode__c', null);
	}

	/**
	 * This is used to identify if the Expected Delivery Data is sourced from .NET API StarTrack Consignment
	 */
	get isDotNetEdd() {
		return get(this.trackingApiResult, "isDotNetEdd", null);
	}

	/**
	 * Does the Analytics date exist
	 */
	get hasAnalyticsEdd() {
		return (this.analyticsExpectedDeliveryDateLow || this.analyticsExpectedDeliveryDateHigh);
	}

	/**
	 * Does the Analytics date have a high and low date?
	 */
	get hasAnalyticsDualEdd() {
		return (this.analyticsExpectedDeliveryDateLow && this.analyticsExpectedDeliveryDateHigh);
	}
	get analyticsExpectedDeliveryDateLow() {
		return get(this.analyticsApiResult, 'hp_dedd_low', null);
	}
	get analyticsExpectedDeliveryDateHigh() {
		const date = get(this.analyticsApiResult, 'hp_dedd_high', null);
		return (this.analyticsExpectedDeliveryDateLow !== date ? date : null);
	}

	/**
	 * Does the SAP date exist. This accomodates SAP EDD being retrieved either from the analytics api or the tracking api
	 * NOTE: The analytics API SAP date is prioritised and will default back to the tracking api SAP value if the analytics api value does not exist
	 */
	get hasSAPEdd() {
		return (this.sapExpectedDeliveryDateLow || this.sapExpectedDeliveryDateHigh);
	}

	/**
	 * Does the SAP date have a high and low date?
	 */
	get hasSAPDualEdd() {
		return (this.sapExpectedDeliveryDateLow && this.sapExpectedDeliveryDateHigh);
	}
	/**
	 * Grab the SAP EDD
	 * This accomodates SAP EDD being retrieved either from the analytics api or the tracking api
	 * NOTE: The analytics API SAP date is prioritised and will default back to the tracking api SAP value if the analytics api value does not exist
	 */
	get sapExpectedDeliveryDateLow() {
		let sapEdd = get(this.analyticsApiResult, 'dedd_low', null);
		if(!sapEdd) {
			sapEdd = get(this.trackingApiResult, 'article.ExpectedDeliveryDate__c', null);
		}
		return sapEdd;
	}

	/**
	 * The analytics API may additionally have a low/high range date.
	 */
	get sapExpectedDeliveryDateHigh() {
		const date = get(this.analyticsApiResult, 'dedd_high', null);
		return (this.sapExpectedDeliveryDateLow !== date ? date : null);
	}

	/**
	 * Use this for showing the SAP date. We need to ensure both interface queries have concluded before we display the SAP date since we may display the one from the tracking api or analytics api depending on outputs.
	 */
	get loading() {
		return this.loadingAnalyticsApi || this.loadingTrackingApi;
	}

	get plots() {
		const plots = [];

		if(this.getValue('transientAttributes.initialPredictedWindowStart') && this.getValue('transientAttributes.initialPredictedWindowEnd')){
			const initialPlot = {};
			initialPlot.low = this.formatTime('transientAttributes.initialPredictedWindowStart');
			initialPlot.high = this.formatTime('transientAttributes.initialPredictedWindowEnd');
			initialPlot.cssClass = 'slds-badge';
			initialPlot.cssStyle = 'background-color: #fccf3e;';
			initialPlot.label = 'Initial Window(' + this.getValue('transientAttributes.initialPredictedWindowStart') + '-' + this.getValue('transientAttributes.initialPredictedWindowEnd') + ')';
			plots.push(initialPlot);
		}
		if(this.getValue('transientAttributes.predictedWindowStart') && this.getValue('transientAttributes.predictedWindowEnd')){
			const updatedPlot = {};
			updatedPlot.low = this.formatTime('transientAttributes.predictedWindowStart');
			updatedPlot.high = this.formatTime('transientAttributes.predictedWindowEnd');
			updatedPlot.cssClass = 'slds-badge';
			updatedPlot.cssStyle = 'background-color: #4bc076;';
			updatedPlot.label = 'Updated Window(' + this.getValue('transientAttributes.predictedWindowStart') + '-' + this.getValue('transientAttributes.predictedWindowEnd') + ')';
			plots.push(updatedPlot);
		}
		return plots;
	}

	/**
	 * Grab the Cognition ETA
	 * This accommodates ETA being retrieved from the tracking api
	 */
	get hasETAInformation() {
		return (this.getValue('transientAttributes.initialPredictedWindowStart') && this.getValue('transientAttributes.initialPredictedWindowEnd'));
	}

	/**
	 *@description : Returns the time in decimal format like 2:33 pm => 14.55.
	 */
	formatTime(timeField){
		var timeVar = this.getValue(timeField);
		let timeValue = [];
		var decimalValue;
		if(timeVar){
			if(timeVar.indexOf(':') > 0){
				timeValue = timeVar.split(':');
			} else if(timeVar.indexOf('.') > 0) {
				timeValue = timeVar.split('.');
			} else {
				timeValue.push(timeVar.substr(0, 2), timeVar.substr(2,2));
			}

			if(timeValue){
				//Get hour value
				let hourVar = parseInt(timeValue[0]);
				//Get minute
				let minuteVar = timeValue[1].toLowerCase();
				if(minuteVar.indexOf('am') > 0){
					minuteVar = minuteVar.replace('am','').trim();
				}else if(minuteVar.indexOf('pm') > 0){
					minuteVar = minuteVar.replace('pm','').trim();
					hourVar = hourVar<12 ? hourVar + 12 : hourVar;
				}
				//Convert into decimal value of minutes
				minuteVar = minuteVar / 60;
				decimalValue = parseFloat(hourVar+minuteVar);
				console.log('decimalValue>>'+decimalValue);
			}
		}
		return decimalValue;
	}

	/**
	 *@description : Returns the value for the valriable.
	 */
	 getValue(stringVar){
		 return get(this.trackingApiResult, stringVar, null);
	 }

}