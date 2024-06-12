/**
 * @description Happy Parcel Latest Scans
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-09-18 - Disha Kariya - Changes to display network details based on Network Organisation ID (WCC) on Event Message
 * 2020-09-18 - Ranjeewa Silva - Show only the latest 'featured' scan events.
 * 2021-05-05 - Ranjeewa Silva - Expose event message attachment(image), if an attachment is available.
 * 2021-07-12 - Nathan Franklin - Added temporary Google Maps link (to be implemented correctly in future piece of work)
 * 2021-10-01 - Nathan Franklin - Add event reason (with transient attributes) + uplift to version 52
 * 2021-10-19 - Mathew Jose - Added the expander for more event message details.
 * 2022-04-11 - Mahesh Parvathaneni - Changed from google map new tab to lightning map
 */
import { api, track } from "lwc";
import HappyParcelBase from "c/happyParcelBase";
import { get, getConfig, CONSTANTS } from "c/happyParcelService";

export default class HappyParcelLatestScans extends HappyParcelBase {

	// the event types used for featured scans
	_featuredScanEventTypes = [];

	// event message type definitions with colour coding configuration
	_eventMessageTypes = [];

	// tracking api results received from parent
	_trackingApiResult;

	// stores a list of the columns to render in the event messages pop up
	@track columns = [];	
	// featured scan events extracted from the events received from parent
	@track featuredScanEvents = [];

	@api loading = false;
	chevronDownIcon = "utility:chevrondown"; //icon name for chevrondown
	chevronUpIcon = "utility:chevronup"; //icon name for chevronup

	/**
	 * Setting this value occurs on the completion of an article search (in the parent)
	 * Store the value and extract featured scan events received in tracking API results.
	 */
	@api
	get trackingApiResult() { return _trackingApiResult; }
	set trackingApiResult(value) {
		this._trackingApiResult = value;
		this.setLatestFeaturedScanEvents(this._trackingApiResult);
	}

	helpText = CONSTANTS.LABEL_HAPPYPARCELLATESTSCANSHELPTEXT;

	get eventsExist() {
		return this.featuredScanEvents.length > 0;
	}

	/**
	 * Extract featured scan events from tracking api results passed in.
	 */
	setLatestFeaturedScanEvents(value) {
		if (value) {
			let alt = false;
			let animationDelay = parseInt(this.animationDelay, 10);

			this.featuredScanEvents = get(value, 'events', []).filter(item => {
				return this._featuredScanEventTypes.includes(item.event.EventType__c);
			}).slice(-6).reverse().map((item, index) => {
				alt = !alt;
				animationDelay += 50;

				const d = Date.parse(item.event.ActualDateTime__c);

				// set a value to indicate whether GPS co-ords are available or not
				const hasGeoCoordinates = (item.event.EventGeoLocation__Latitude__s && item.event.EventGeoLocation__Longitude__s);
				// set the map markers required for lightning map component
				const mapMarkers = hasGeoCoordinates ? this.setMapMarkers(item) : [];

				//updating event description with concatenation of original event decription and event reason.
				const eventDescriptionCombined = (item.transientAttributes.eventReason ? `${item.event.EventDescription__c} (${item.transientAttributes.eventReason})` : item.event.EventDescription__c);		

				const columns = this.pushColumnValue([...this.columns],item);

				//check if atleast one of the fields have values.
				let eventDetailsRequired = columns.some(x => x.fieldValue); 

				return {
					...item,
					parsedDateTime: d.toString(),
					showNetworkDetails: false,
					showAttachment: false,
					eventDetailsRequired: eventDetailsRequired,
					eventDescriptionCombined: eventDescriptionCombined,
					showEventDetails: false,
					showCriticalIncidents: false,
					_eventColumns: columns,
					isLock: (get(item, 'event.Status__c', '').indexOf('Lock') > -1) ,
					animationCssStyle: this.getAnimationStyleCss(animationDelay),
					cssClass: this.getEventTypeCssClass(item.event.EventType__c) + ' animated ' + (alt ? 'zoomInLeft' : 'zoomInRight'),
					hasGeoCoordinates,
					showMap: false,
					_mapMarkers: mapMarkers,
					expandEventSection: index > 2 ? false : true,
					chevronIcon: index > 2 ? this.chevronUpIcon : this.chevronDownIcon
				};
			});
		} else {
			this.featuredScanEvents = [];
		}
	}

	connectedCallback() {
		// grab a list of event types to monitor for featured scans
		getConfig().then(result => {
			this._featuredScanEventTypes = result.featuredScanEventTypes;

			const eventMessageTypes = {};

			for(const [key, value] of Object.entries(result.eventMessageTypeDefinitions)) {
				value.forEach(item => {
					eventMessageTypes[item.Label] = item;
				});
			}

			this._eventMessageTypes = eventMessageTypes;

			const columnOutput = [];

			this.pushColumns(result.eventMessageFeaturedOverflowFields, false, columnOutput);

			// sort the datable by the first column in the fieldset
			if(!this.sortedBy) {
				this.sortedBy = columnOutput[0].fieldName;
			}
			this.columns = columnOutput;			
			// now that featured scan event types are known, check if tracking api results with event data is available.
			// if available, extract featured scan events.
			if (this._trackingApiResult) {
				this.setLatestFeaturedScanEvents(this._trackingApiResult);
			}
		});
	}

	/**
	 * Used to push the column names based on the array of fields from the field set (Base and overflow)
	 */
	pushColumns(columnArray, overFlow, initialValue) {
		return columnArray.reduce((acc, obj)=> {

			var css = (obj.fieldName === 'EventDescription__c') ? "slds-th__action slds-text-link_reset event-width" 
					: (obj.fieldName === 'State_Territory_Province__c') ? "slds-th__action slds-text-link_reset event-state"
					: "slds-th__action slds-text-link_reset maxWidth";

			acc.push({label: obj.fieldLabel, fieldName: obj.fieldName, fieldHelpText: obj.fieldHelpText, fixedWidth: false, sortedColumn: false, fieldType: obj.fieldType, cssClass : css, overFlow : overFlow});

			return acc;

		}, initialValue)
	}	

	/**
	* Used to set field values and key in the columns(Overflow & Base) to derive the rows to be presented in the event message table. 
	*/
	pushColumnValue(columns, item) {
		return columns.map(column => {
			const col = {...column, fieldValue: item.event[column.fieldName], key: item.event.EventID__c + column.fieldName, extendedAttributes: {}};

			// add an element as the name of the field
			// set this to true so we can access it in our composition
			// TODO a bit of a dirty hack but it works for now...
			col['fieldNameIs_' + column.fieldName] = true;

			if(column.fieldName === 'EventDescription__c') {
				// add the event reason (if one exists) into the event description column
				// we do this in component markup
				// we only display the reason if it's different from the description to stop duplicate text
				col.extendedAttributes['eventReason'] = (item.event['EventDescription__c'] !== item.transientAttributes['eventReason'] ? item.transientAttributes['eventReason'] : '');
			}

			return col;
		});
	}
	/*
	 * Used to set showEventDetails associated with each event to facilitate the opening of more details section.
	 */
	handleShowEventDetails( event ) {
		let eventId = event.target.dataset.eventId;
		if ( this.featuredScanEvents ) {
			let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
			if (eventIndex > -1) {
				//Show event details
				this.featuredScanEvents[eventIndex].showEventDetails = true;
				this.expandEventSection(eventIndex);
			}
		}
	}
	/*
	 * Used to set showEventDetails to false associated with each event to facilitate the closure of more details section.
	 */
	handleCloseEventDetails(event) {
		const eventId = event.detail;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (eventIndex > -1) {
			this.featuredScanEvents[eventIndex].showEventDetails = false;
		}
	}		
	/**
	 * Determines the event for which the network detail popup is open
	 */
	handleNetworkInfo(event) {
		const target = event.currentTarget;
		const eventId = target.dataset.id;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (eventIndex > -1) {
			this.featuredScanEvents[eventIndex].showNetworkDetails = true;
			this.expandEventSection(eventIndex);
		}
	}

	/**
	 * Closes the popup for network information
	 */
	closePopupHandler(event) {
		const eventId = event.detail;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (eventIndex > -1) {
			this.featuredScanEvents[eventIndex].showNetworkDetails = false;
		}
	}

	
	/**
	 * Determines the event to show related critical incidents
	 */
	handleShowCriticalIncidents(event) {
		const target = event.currentTarget;
		const eventId = target.dataset.id;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (eventIndex > -1) {
			this.featuredScanEvents[eventIndex].showCriticalIncidents = true;
			this.expandEventSection(eventIndex);
		}
	}

	/**
	 * Determines the event to show related critical incidents
	 */
	handleCloseCriticalIncidents(event) {
		const eventId = event.detail;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (eventIndex > -1) {
			this.featuredScanEvents[eventIndex].showCriticalIncidents = false;
		}
	}
	
	handleShowAttachment(event) {
		const target = event.currentTarget;
		const eventId = target.dataset.id;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (eventIndex > -1) {
			this.featuredScanEvents[eventIndex].showAttachment = true;
			this.expandEventSection(eventIndex);
		}
	}

	handleCloseAttachment(event) {
		const eventId = event.detail;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (eventIndex > -1) {
			this.featuredScanEvents[eventIndex].showAttachment = false;
		}
	}

	getEventTypeCssClass(eventType) {

		if(this._eventMessageTypes && this._eventMessageTypes[eventType] && this._eventMessageTypes[eventType].ColourCode__c && this._eventMessageTypes[eventType].ColourCode__c != 'None') {
			return 'color-code_' + this._eventMessageTypes[eventType].ColourCode__c.toLowerCase();
		}
		return 'color-code_default';
	}

	// function to set the map markers for lightning map
	setMapMarkers(item) {
		return [{
			location: {
				Latitude: item.event.EventGeoLocation__Latitude__s,
				Longitude: item.event.EventGeoLocation__Longitude__s,
			}
		 }];
	}

	// function to render map on click of map icon
	handleShowMap(event) {
		const target = event.currentTarget;
		const eventId = target.dataset.id;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (eventIndex > -1) {
			this.featuredScanEvents[eventIndex].showMap = true;
			this.expandEventSection(eventIndex);
		}
	}

	// handler to hide the map from happyParcelEventMessageMap event
	handleCloseMap(event) {
		const eventId = event.detail;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (eventIndex > -1) {
			this.featuredScanEvents[eventIndex].showMap = false;
		}
	}

	//handler for chevron to expand and collapse the scan events
	handleChevronClick(event) {
		let iconName = event.target.iconName;
		let eventId = event.target.dataset.id;
		let eventIndex = this.featuredScanEvents.findIndex(item => item.event.EventID__c === eventId);
		if (iconName === this.chevronDownIcon) {
			this.featuredScanEvents[eventIndex].chevronIcon = this.chevronUpIcon;
			this.featuredScanEvents[eventIndex].expandEventSection = false;
		} else {
			this.featuredScanEvents[eventIndex].chevronIcon = this.chevronDownIcon;
			this.featuredScanEvents[eventIndex].expandEventSection = true;
		}
	}

	//expand event section to show map, attachment etc. if it's not opened 
	expandEventSection(eventIndex) {
		let iconName = this.featuredScanEvents[eventIndex].chevronIcon;
		if (iconName === this.chevronUpIcon) {
			this.featuredScanEvents[eventIndex].chevronIcon = this.chevronDownIcon;
			this.featuredScanEvents[eventIndex].expandEventSection = true;
		} 
	}
}