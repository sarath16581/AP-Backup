/**
 * @description Happy Parcel Delivery Assessment
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 	2022-04-11 - Mahesh Parvathaneni - Changed the logic behind View in Maps and emotion icons
 */
 import { LightningElement, api } from "lwc";
 import { getConfig, get, CONSTANTS, getDistanceBetweenGeoCoordinates } from "c/happyParcelService";
 
 export default class HappyParcelDeliveryAssessment extends LightningElement {
 
	 @api loading = false;
 
	 helpText = CONSTANTS.LABEL_HAPPYPARCELDISTANCEHELPTEXT;
	 _events = []; // events received from parent
	 threshold; //threshold config for happy/sad emotions
	 _deliveredEventTypes = []; //delivered event message types
	 outsideDeliveryRadius; // outside delivery radius for the event from the TIBCO service
	 latestEventMessage; // latest event message of delivered type
	 distanceBetweenLocations = null; // distance between delivered and manifest locations if available
	 isDataLoading = false; // flag to show/hide the spinner
	 accuracy = null; // accuracy from the event message
	 _analyticsApiResult; // analytics api result from parent
 
	 connectedCallback() {
		 this.isDataLoading = true;
		 getConfig().then(result => {
			 this.threshold = result.manifestAssessmentHappyThreshold;
			 // grab a list of event types to monitor for with a category of 'Delivered'
			 this._deliveredEventTypes = get(result.eventMessageTypeDefinitions, 'Delivered', []).map(item => item.Label);
 
			 // now that event types are known, check if event data is available.
			 // if available, extract outside delivery radius from the latest event message.
			 if (this._events && this._events.length > 0) {
				 this.setLatestEventMessage(this._events);
			 } else {
				this.isDataLoading = false;
			 }
		 });
	 }
 
	 get isHappy() {
		 return !this.isSad;
	 }

	// If the distance calculated between manifest gps and delivered gps greater than or equal threshold (and)
	// latest delivered event message outside delivery raidus not available
	 get isSad() {
		 return this.distanceBetweenLocations !== null && this.distanceBetweenLocations * 1000 >= this.threshold && this.outsideDeliveryRadius === undefined;
	 }

	 /**
	  * Check if the manifest coordinates available from GCP (or)
	  * Check if the latest delivered event message returned from SAP
	  */
	 get isAvailable() {
		 return this.manifestGps.length === 2 || this.latestEventMessage != undefined;
	 }
 
	 get thresholdDisplay() {
		 return this.threshold / 1000 + 'km';
	 }
 
	 get manifestGps() {
		 const latitude = get(this._analyticsApiResult, 'latitude_dpid', false);
		 const longitude = get(this._analyticsApiResult, 'longitude_dpid', false);
		 return (!latitude || !longitude ? [] : [latitude, longitude]);
	 }

	 get deliveredGps() {
		 let deliveredCoordinates = [];
		 if(this.latestEventMessage !== undefined && this.latestEventMessage.EventGeoLocation__Latitude__s 
				&& this.latestEventMessage.EventGeoLocation__Longitude__s) {
			 deliveredCoordinates = [this.latestEventMessage.EventGeoLocation__Latitude__s, this.latestEventMessage.EventGeoLocation__Longitude__s];
		 }
		 return deliveredCoordinates;
	 }
 
	 // message to show based on output delivery radius
	 get deliveryMessage() {
		 if (this.outsideDeliveryRadius) {
			 return this.outsideDeliveryRadius === 'Yes' ? CONSTANTS.LABEL_HAPPYPARCELCORRECTDELIVERYHELPTEXT : CONSTANTS.LABEL_HAPPYPARCELACCEPTABLEDELIVERYHELPTEXT;
		 }
	 }
	 
	 get distanceCalculated() {
		 if (this.outsideDeliveryRadius && this.outsideDeliveryRadius === 'No') {
			 return CONSTANTS.LABEL_HAPPYPARCELACCEPTABLEDISTANCEHELPTEXT;
		 }
		 else if (this.distanceBetweenLocations !== null) {
			 return this.distanceBetweenLocations * 1000 > this.threshold ? `Distance > ${this.thresholdDisplay}` : `Distance < ${this.thresholdDisplay}`;
		 }
	 }

	 get distanceClass() {
		 return this.distanceBetweenLocations !== null && this.distanceBetweenLocations * 1000 > this.threshold && this.outsideDeliveryRadius !== 'No' ? 'slds-p-top_small red-text' : 'slds-p-top_small';
	 }

	 get distanceHelpText() {
		return this.outsideDeliveryRadius && this.outsideDeliveryRadius === 'No' ? CONSTANTS.LABEL_HAPPYPARCELSCANHELPTEXT : CONSTANTS.LABEL_HAPPYPARCELDISTANCECALCULATEDDELIVERYHELPTEXT;
	 }

	 // return flag to show/hide the emotion icon when outside delivery radius is not avilable and 
	 // either manifest or delivered coordinates are available
	 get showEmotionIcon() {
		 return (this.outsideDeliveryRadius === undefined && this.latestEventMessage !== undefined && this.manifestGps.length === 0) ||
		 	(this.manifestGps.length === 2 && this.latestEventMessage === undefined) ? false : true;
	 }
 
	 /**
	  * This occurs on the completion of an article search (in the parent)
	  * Store the events and extract Delivered event from the events received.
	  */
	  @api
	  get events() { return _events; }
	  set events(value) {
		 if(value) {
			 this._events = value;
		 }
		 this.setLatestEventMessage(this._events);
	  }

	  /**
	   * Get the analytics api result from parent
	   * Calcualte the distance between manifest and delivered locations if not done during connected callback
	   */
	  @api
	  get analyticsApiResult() { return _analyticsApiResult;}
	  set analyticsApiResult(value) {
		  if(value) {
			  this._analyticsApiResult = value;
			  //calcualte distance between locations if not done
			  if (this.manifestGps.length === 2 && this.deliveredGps.length === 2 && this.distanceBetweenLocations === null) {
				this.calculateDistance();
			  }
		  }
	  }

	  /**
	   * Extract latest Delivered event message from the events received.
	   */
	   setLatestEventMessage(events) {
		  if(events && events.length > 0) {
			 //Loop backward to get the latest events
			 for (let i = events.length - 1; i >= 0; i--) {
				 const item = events[i];
				 //get the latest delivered event message with gps coordinates
				 if (this._deliveredEventTypes.includes(item.event.EventType__c) && 
				 	item.event.EventGeoLocation__Latitude__s && item.event.EventGeoLocation__Longitude__s) {
					 this.latestEventMessage = item.event;
					 this.outsideDeliveryRadius = item.event.Outside_Delivery_Radius__c;
					 this.accuracy = item.event.Geo_Precision__c;
					 break;
				 }				
			 }
		  }

		  //calcualte distance between locations
		  if (this.manifestGps.length === 2 && this.deliveredGps.length === 2) {
			this.calculateDistance();
		  } else {
			this.isDataLoading = false;
		  }
	  }

	  // calcualtes distance between locations if available
	  calculateDistance() {
		  this.isDataLoading = true;
		  getDistanceBetweenGeoCoordinates(this.manifestGps[0], this.manifestGps[1], 
				this.deliveredGps[0], this.deliveredGps[1]).then((result) => {
					this.distanceBetweenLocations = result;
					this.isDataLoading = false;
		  });
	  }
 
	  // handler for map click
	  handleMapClick(event) {
		  let manifestGps = null;
		  let deliveredGps = null;
		  let mapMarkers;

		  //get coordinates for manifested location from GCP
		  if (this.manifestGps.length === 2) {
			manifestGps = this.manifestGps;
		  }
		  //get coordinates for latest delivered location from SAP
		  if (this.deliveredGps.length === 2) {
			deliveredGps = this.deliveredGps;
		  }
		  mapMarkers = this.setMapMarkers(manifestGps, deliveredGps);

		  //dispatch event to parent to show map
		  const detail = {mapMarkers: mapMarkers};
		  this.dispatchEvent(new CustomEvent('mapclick', {detail: detail}));
	  }
 
	 // function to set the map markers for lightning map
	 setMapMarkers(manifestGps, deliveredGps) {
		 let mapMarkers = [];
		 if (manifestGps != null) {
			 mapMarkers.push({
				 //manifest location
				 location: {
					 Latitude: manifestGps[0],
					 Longitude: manifestGps[1],
				 },
				 value: 'manifestLocation',
				 title: 'Manifest Location',
				 mapIcon: {
					 path: CONSTANTS.LOCATION_ICON_SVG_PATH,
					 fillColor: 'red',
					 fillOpacity: .6,
					 strokeColor: 'black',
					 strokeOpacity: 0.35,
					 strokeWeight: 2,
					 scale: 2,
					 anchor: {x: 12, y: 21}
				 },
			 });
		 }
 
		 if (deliveredGps != null) {
			 mapMarkers.push({
				 //delivered location
				 location: {
					 Latitude: deliveredGps[0],
					 Longitude: deliveredGps[1],
				 },
				 value: 'deliveredLocation',
				 title: 'Delivered Location',
				 mapIcon: {
					 path: CONSTANTS.LOCATION_ICON_SVG_PATH,
					 fillColor: 'darkgreen',
					 fillOpacity: .6,
					 strokeColor: 'black',
					 strokeOpacity: 0.35,
					 strokeWeight: 2,
					 scale: 2,
					 anchor: {x: 12, y: 21}
				 },
			 });
		 }
		 return mapMarkers;
	 }
 }