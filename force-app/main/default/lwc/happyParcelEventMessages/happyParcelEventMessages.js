/**
 * @description Happy Parcel Event Messages
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-09-15 - Disha Kariya - Replaced data table with custom table to add button icon and other features
 * 2020-09-16 - Disha Kariya - Changes to display padlock for events with disclaimer
 * 2020-09-21 - Disha Kariya - Removed disclaimer changes, added status(Restricted) column, added network information popup
 * 2020-09-23 - Ranjeewa Silva - Implemented colour coding for event messages based on the event type.
 * 2020-10-02 - Disha KAriya - Added a check to set events after columns have been set
 * 2021-05-05 - Ranjeewa Silva - Expose event message attachment(image), if an attachment is available.
 * 2021-07-12 - Nathan Franklin - Added temporary Google Maps link (to be implemented correctly in future piece of work)
 * 2021-10-01 - Nathan Franklin - Add event reason (with transient attributes) + uplift to version 52
 * 2021-10-04 - Mathew Jose - Added the changes associated with row overflow feature in the data table.
 *	2022-04-11 - Mahesh Parvathaneni - Changed from google map new tab to lightning map
 */
 import { LightningElement, api, track } from "lwc";
 import { getConfig, getDataTableMappingFromDisplayType, CONSTANTS, get } from "c/happyParcelService";
 
 export default class HappyParcelEventMessages extends LightningElement {
 
	 //Event message type definitions with colour coding
	 _eventMessageTypes;
 
	 //event messages recieved from parent
	 _eventMessages;
 
	 // help text to display in happy parcel card
	 helpText = CONSTANTS.LABEL_HAPPYPARCELSCANEVENTSHELPTEXT;
 
	 @api loading = false;
 
	 @track startTableLoad;
	 @track showTable;
 
	 @track _events = [];
 
	 // stores a list of the columns to render in the event messages table
	 @track columns = [];
 
	 // stores a list of the columns to render in the event messages table as overflow
	 @track overflowColumns = [];
	 // stored the sort settings to update the icon display on the datatable
	 @track sortedBy = '';
	 @track sortDirection = 'asc';
	 @track isAsc = true;
	 @track isDsc = false;
 
	 connectedCallback() {
		 // grab a list of event types to monitor for with signature for delivery
		 getConfig().then(result => {
			 const columnOutput = [];
			 /*result.eventMessageFields.forEach(item => {
				 columnOutput.push({label: item.fieldLabel, fieldName: item.fieldName, fixedWidth: false, sortedColumn: false, fieldType: item.fieldType, cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
 
				 // some dirty width hacks
				 if(columnOutput[columnOutput.length-1].fieldName === 'EventDescription__c') {
					 columnOutput[columnOutput.length-1].cssClass = 'slds-th__action slds-text-link_reset event-width';
				 }
				 if(columnOutput[columnOutput.length-1].fieldName === 'State_Territory_Province__c') {
					 columnOutput[columnOutput.length-1].cssClass = 'slds-th__action slds-text-link_reset event-state';
				 }
 
				 // sort the datable by the first column in the fieldset
				 if(!this.sortedBy) {
					 this.sortedBy = item.fieldName;
				 }
			 } );*/
 
			 //Moved the above logic to a re-usable function inorder to set the overflow columns.
			 this.pushColumns(result.eventMessageFields, false, columnOutput);
			 // sort the datable by the first column in the fieldset
			 if(!this.sortedBy) {
				 this.sortedBy = columnOutput[0].fieldName;
			 }
			 this.columns = columnOutput;
 
			 //add overflow columns in addition to the intial columns.
			 this.overflowColumns = this.pushColumns(result.eventMessageOverflowFields, true, []);
 
			 const eventMessageTypes = {};
			 //grab the event message type definitions by event type so it is easier to access when iterating through the events
			 for(const [key, value] of Object.entries(result.eventMessageTypeDefinitions)) {
				 value.forEach(item => {
					 eventMessageTypes[item.Label] = item;
				 });
			 }
 
			 this._eventMessageTypes = eventMessageTypes;
 
			 // now that event message type definitions are known, check if event data is available.
			 // if available, compute events to display.
			 if (this._eventMessages) {
				 this.setEvents(this._eventMessages);
			 }
 
		 });
	 }
 
 
	 /**
	  * For instances where there are a large number of events attached to an article, we use lazy loading
	  * This is the handler when the user clicks the 'Load' button
	  */
	 handleShowTable() {
		 this.startTableLoad = true;
 
		 // use set timeout, to give the component opportunity to rerender and display the spinner
		 setTimeout(() => {
			 this.showTable = true;
		 }, 1);
	 }
 
	 /**
	  * When populating the events for display, we need to flatten the array to remove the .event in every event object
	  */
	 @api
	 get eventMessages() { return this._events; }
	 set eventMessages(value) {
		 this._eventMessages = value;
 
		 //Set events only if columns have been set
		 if(this.columns.length > 0){
			 this.setEvents(value);
		 }
	 }
 
	 get hasEvents() {
		 return this._events && this._events.length > 0;
	 }
 
	 setEvents(value) {
 
		 if(value) {
			 this.startTableLoad = false;
 
			 this._events = value.map(item => {
				 //Moved the below iteration to a new function as it can be re-used for overflow fields.
				 /*const columns = [...this.columns].map(column => {
					 const col = {...column, fieldValue: item.event[column.fieldName], key: item.event.EventID__c + column.fieldName, extendedAttributes: {}};
 
					 if(['Status__c', 'ActualLocation__c', 'EventDescription__c'].includes(col.fieldName)) {
						 col.isCustom = true;
 
						 // add an element as the name of the field
						 // set this to true so we can access it in our composition
						 // TODO a bit of a dirty hack but it works for now...
						 col['fieldNameIs_' + column.fieldName] = true;
 
						 if(column.fieldName === 'EventDescription__c') {
							 col.colourCssClass = this.getEventTypeCssClassName(item.event.EventType__c);
 
							 // add the event reason (if one exists) into the event description column
							 // we do this in component markup
							 col.extendedAttributes['eventReason'] = item.transientAttributes['eventReason'];
						 }
 
						 if(column.fieldName === 'Status__c') {
							 col.isLock = (get(item, 'event.Status__c', '').indexOf('Lock') > -1);
						 }
					 }
 
					 return col;
				 });*/
				 
				 //To do - Refactor the above code.
				 //Setting field value, css, isCustom, lock for both base and over flow columns.
				 const overflowColumns = this.pushColumnValue([...this.overflowColumns], item);
 
				 //check if over flow section is required at all to determine if we need to show the expander icon.
				 let overflowRequired = overflowColumns.some(x => x.fieldValue); 
 
				 const columns = this.pushColumnValue([...this.columns], item);
 
				 // set a value to indicate whether GPS co-ords are available or not
				 const hasGeoCoordinates = (item.event.EventGeoLocation__Latitude__s && item.event.EventGeoLocation__Longitude__s);
				 // set the map markers required for lightning map component
				 const mapMarkers = hasGeoCoordinates ? this.setMapMarkers(item) : [];
				 //Added new attributes oveFlow and _overFlowColumns to support overflow functionality on the datatable.
				 //overFlow is set to false to ensure each row will be in a collapsed state initially.
				 //_overFlowColumns has the overflow colum values.
				 return {
					 ...item.event,
					 _columns: columns,
					 overflowRequired: overflowRequired,
					 showOverflow: false,
					 _overflowColumns: overflowColumns,
					 showNetworkDetails: false,
					 showCriticalIncidents: false,
					 showAttachment: false,
					 hasGeoCoordinates,
					 showMap: false,
					 _mapMarkers: mapMarkers
				 };
			 });
 
			 // if there are more than 20 event messages then we lazy load them
			 this.showTable = (this._events.length < 20);
 
			 // default sort the dataset as per starting configuration
			 this.sortData(this.sortedBy);
		 } else {
			 this.startTableLoad = false;
			 this.showTable = true;
			 this._events = [];
		 }
 
	 }
 
	 get columnCount() {
		 return get(this.columns, 'length', 0);
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
			 const col = {...column, fieldValue: item.event[column.fieldName], key: item.event.EventID__c + column.fieldName,extendedAttributes: {}};
			 if(['Status__c', 'ActualLocation__c', 'EventDescription__c'].includes(col.fieldName)) {
				 col.isCustom = true;
 
				 // add an element as the name of the field
				 // set this to true so we can access it in our composition
				 // TODO a bit of a dirty hack but it works for now...
				 col['fieldNameIs_' + column.fieldName] = true;
 
				 if(column.fieldName === 'EventDescription__c') {
					 col.colourCssClass = this.getEventTypeCssClassName(item.event.EventType__c);
					 // add the event reason (if one exists) into the event description column
					 // we do this in component markup
					 // we only display the reason if it's different from the description to stop duplicate text
					 col.extendedAttributes['eventReason'] = (item.event['EventDescription__c'] !== item.transientAttributes['eventReason'] ? item.transientAttributes['eventReason'] : '');
 
				 }
 
				 if(column.fieldName === 'Status__c') {
					 col.isLock = (get(item, 'event.Status__c', '').indexOf('Lock') > -1);
				 }
			 }
			 return col;
		 });
 
	 };
	 /**
	  * Used to set the overFlow value associated with each event to facilitate the opening of more details section.
	  */
	 handleShowOverflow( event ) {
		 let eventId = event.target.dataset.eventId;
		 console.log( 'Index is ' + eventId );
		 if ( this._events ) {
			 let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
			 if (eventIndex > -1) {
				 //Show overflow
				 this._events[eventIndex].showOverflow = true;
			 }
		 }
	 }
	 onHandleSort(event) {
		 const target = event.currentTarget
		 const id = target.dataset.id
 //		const { fieldName: sortedBy, sortDirection } = event.detail;
		 this.sortData(id);
	 }
 
	 handleNetworkInfo(event) {
		 const target = event.currentTarget;
		 const eventId = target.dataset.id;
		 let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
		 if (eventIndex > -1) {
			 this._events[eventIndex].showNetworkDetails = true;
		 }
	 }
 
	 closePopupHandler(event) {
		 const eventId = event.detail;
		 let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
		 if (eventIndex > -1) {
			 this._events[eventIndex].showNetworkDetails = false;
		 }
	 }

	/**
	 * Determines the event to show related critical incidents
	 */
	handleShowCriticalIncidents(event) {
		const target = event.currentTarget;
		const eventId = target.dataset.id;
		let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
		if (eventIndex > -1) {
			this._events[eventIndex].showCriticalIncidents = true;
		}
	}

	/**
	 * Determines the event to show related critical incidents
	 */
	handleCloseCriticalIncidents(event) {
		const eventId = event.detail;
		let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
		if (eventIndex > -1) {
			this._events[eventIndex].showCriticalIncidents = false;
		}
	}
 
	 handleShowAttachment(event) {
		 const target = event.currentTarget;
		 const eventId = target.dataset.id;
		 let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
		 if (eventIndex > -1) {
			 this._events[eventIndex].showAttachment = true;
		 }
	 }
 
	 handleCloseAttachment(event) {
		 const eventId = event.detail;
		 let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
		 if (eventIndex > -1) {
			 this._events[eventIndex].showAttachment = false;
		 }
	 }
 
	 handleCloseOverflow(event) {
		 const eventId = event.detail;
		 let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
		 if (eventIndex > -1) {
			 this._events[eventIndex].showOverflow = false;
		 }
	 }	
 
	 async sortData(sortedBy) {
		 const cloneData = [...this._events];
 
		 // grab the definition of the sort column
		 const fieldType = this.columns.filter((field) => field.fieldName === sortedBy);
		 const fieldSort = this.columns.filter((field) => field.sortedColumn === true);
 
		 // sort the data factoring in if it's a date field then we reference the timestamp instead of the actual date
		 const primer = (val, row) => {
			 if(!fieldType || fieldType.length === 0) {
				 return val;
			 } else {
				 if(fieldType[0].type === 'date' && !isNaN((new Date(val)).getTime())) {
					 return (new Date(val)).getTime()
				 } else {
					 return val;
				 }
			 }
		 };
 
		 //Set sort order based on field
		 if (this.sortedBy === sortedBy) {
			 this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
		 } else {
			 this.sortDirection = 'desc';
		 }
 
		 //Set sorted column
		 if(fieldType[0] !== undefined && !fieldType[0].sortedColumn){
			 fieldType[0].sortedColumn = true;
		 }
		 if(fieldSort[0] !== undefined && fieldType[0].fieldName !== fieldSort[0].fieldName){
			 fieldSort[0].sortedColumn = false;
		 }
 
		 //Set icon visible
		 if (this.sortDirection === 'asc') {
			 this.isAsc = true;
			 this.isDsc = false;
		 } else {
			 this.isAsc = false;
			 this.isDsc = true;
		 }
 
		 // sort our data
		 cloneData.sort(this.sortBy(sortedBy, (this.sortDirection === 'asc' ? 1 : -1), primer));
 
		 this._events = cloneData;
 //		this.sortDirection = this.sortDirection;
		 this.sortedBy = sortedBy;
	 }
 
	 // Sort the data columns
	 sortBy(field, reverse, primer) {
		 const key = primer
			 ? function(x) {
				 return primer(x[field], x);
			 }
			 : function(x) {
				 return x[field];
			 };
 
		 return function(a, b) {
			 a = key(a);
			 b = key(b);
 
			 if(a === undefined) {
				 // accounts for empty values to make sure they are all grouped together either at the top or at the bottom
				 return reverse * 1;
			 } else if(b === undefined) {
				 // accounts for empty values to make sure they are all grouped together either at the top or at the bottom
				 return reverse * -1;
			 } else {
				 return reverse * ((a > b) - (b > a));
			 }
		 };
	 }
 
	 getEventTypeCssClassName(eventType) {
		 if(this._eventMessageTypes && this._eventMessageTypes[eventType] && this._eventMessageTypes[eventType].ColourCode__c && this._eventMessageTypes[eventType].ColourCode__c != 'None') {
			 return 'event-description-dot color-code_' + this._eventMessageTypes[eventType].ColourCode__c.toLowerCase();
		 }
		 return 'event-description-dot color-code_default';
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
		 let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
		 if (eventIndex > -1) {
			 this._events[eventIndex].showMap = true;
		 }
	 }

	 // handler to hide the map from happyParcelEventMessageMap event
	 handleCloseMap(event) {
		const eventId = event.detail;
		let eventIndex = this._events.findIndex(event => event.EventID__c === eventId);
		if (eventIndex > -1) {
			this._events[eventIndex].showMap = false;
		}
	}
 }