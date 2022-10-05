/**
 * @description Main component that wraps all functionality exposed by PUD Bulk Edit user interface. Responsible for
 *  	  	  	managing the data model containing routes and bookings based on selected filters:
 *  	  	  	  	  - Retrieve routes and bookings based on the selected filters
 *  	  	  	  	  - Listen to events published by child components and update the model. Updating the model causes child
 *  	  	  	  	  	components to re-render.
 *  	  	  	  	  - Save the changes to the database and refresh the model.
 *
 * @author Ranjeewa Silva
 * @date 2022-02-14
 * @changelog
 * 2022-02-14 - Ranjeewa Silva - Created
 * 2022-09-14 - Dattaraj Deshmukh - Added logic for 'FIELD_DISPLAY_ETA_TO_DRIVER'. 
 * 				FIELD_DISPLAY_ETA_TO_DRIVER checkbox is made editable only if Start_Time__c is populated. 
 * 				If Start_Time__c is updated to be blank, FIELD_DISPLAY_ETA_TO_DRIVER is unchecked.
 */

import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CONSTANTS, getConfig, getRoutes, saveBookings, epochToDecimalTime } from 'c/pudBulkEditBookingsService';


export default class PudBulkEditBookings extends LightningElement {

    // id of the home depot of current user.
    homeDepotId;

	// data model holding routes and bookings based on selected filters. data model is updated based on actions performed by
	// the user on the interface (e.g. drag and drop bookings, edit booking attributes on data table). changes are saved
	// permanently only when the 'Save' button is pressed.
	@track routes = [];

	// mapping of booking id to booking. this makes it easier to locate the booking by a booking id.
	_bookings;

	// id of the booking currently being dragged. populated on receiving custom event published at the start of the drag action.
	draggedBookingId;

	// booking currently selected by the user. a booking can be selected in the timeline view by clicking on it.
	selectedBooking;

	// id of the route which contained the booking when the current drag started.
	sourceRouteId;

	// ids of routes selected for filtering data
	@track selectedRouteIds = [];

	// booking record types selected for filtering data
	@track selectedBookingRecordTypes;

	// zoom level applied currently. defaults to 0.
	zoomLevel = 0;

	// indicates if there are any unsaved changes
	hasDirtyRecords = false;

	// if true, the filters panel is visible
	showFiltersPanel = true;

	// indicates the data is being loaded from the backend.
	isLoading = false;

	// expose custom labels
	label = {
		noRoutesSelectedMessage: CONSTANTS.LABEL_NOROUTESSELECTEDMESSAGE,
		noBookingsToDisplayMessage: CONSTANTS.LABEL_NOBOOKINSTODISPLAYMESSAGE
	};

	connectedCallback() {
	    this.isLoading = true;
        // load the bulk edit runtime config.
        // set the home depot id if returned in the runtime config
        getConfig().then(result => {
            this.homeDepotId = result.homeDepotId;
        }).finally(() => {
            this.isLoading = false;
	    });
    }

	/**
	 * Returns the earliest start time of bookings in selected routes.
	 * Default start time is returned if no bookings match selected filters.
	 */
	get earliestStartTime() {
		let startTime = null;

		this.routes.forEach(item => {
			if ((item.startTime >= 0)  && (startTime === null || (item.startTime < startTime))) {
				startTime = item.startTime;
			}
		});

		return (startTime !== null ? startTime: Date.UTC(1970, 1, 1, CONSTANTS.DEFAULT_ROUTE_START_TIME_HH, CONSTANTS.DEFAULT_ROUTE_START_TIME_MM));
	}

	/**
	 * Returns the latest end time of selected routes.
	 * Default end time is returned if no bookings match selected filters.
	 */
 	get latestEndTime() {
 	  	let endTime = null;

 	  	this.routes.forEach(item => {
			if ((item.endTime >= 0) && (endTime === null || (item.endTime > endTime))) {
				endTime = item.endTime;
			}
		});

		return (endTime !== null ? endTime: Date.UTC(1970, 0, 1, CONSTANTS.DEFAULT_ROUTE_END_TIME_HH, CONSTANTS.DEFAULT_ROUTE_END_TIME_MM));
  	}

  	get bookings() {
  	    const output = [];
  	    this.routes.forEach(route => {
  	        route.bookings.forEach(item => {
  	            //output.push(item.booking);
  	            output.push({
  	                ...item.booking,
  	                dirtyFields: item.dirtyFields
				});
            });
        });
        return output;
    }

	/**
	 * returns true if selected routes are available and loaded.
	 */
	get routesAvailable() {
  	  	return (this.routes && this.routes.length > 0);
  	}

	/**
	 * returns true if bookings for selected routes are available and loaded.
	 */
  	get bookingsAvailable() {
		return (this._bookings && Object.keys(this._bookings).length > 0);
	}

  	handleApplyFilters(event) {
  	  	if (event.detail) {
  	  	  	this.selectedRouteIds = event.detail.routeIds;
  	  	  	this.selectedBookingRecordTypes = event.detail.bookingRecordTypes;
  	  	  	this.selectedBooking = null;
  	  	  	this.getSelectedRoutes(this.selectedRouteIds, this.selectedBookingRecordTypes);
  	  	}
  	}

  	handleShowFiltersPanel(event) {
  	  	this.showFiltersPanel = !this.showFiltersPanel;

  	  	const filtersPanelElement = this.template.querySelector('.bulk-edit-filters-panel');
  	  	if (filtersPanelElement) {
  	  	  	filtersPanelElement.classList.add(this.showFiltersPanel ? 'slds-is-open': 'slds-is-hidden');
  	  	  	filtersPanelElement.classList.remove(this.showFiltersPanel ? 'slds-is-hidden': 'slds-is-open');
  	  	}
  	}

  	handleBookingDragStart(event) {
  	  	this.draggedBookingId = event.detail.bookingId;
  	  	this.sourceRouteId = event.detail.routeId;
  	}

	handleBookingDrop(event) {

	  	// select the route where the booking was assigned prior to current drag event.
	  	const [sourceRoute] = this.routes.filter(item => {
	  	  	return (item.route.Id === this.sourceRouteId);
  	 	});

		// select the route where the booking is now assigned after the current drop event.
  	 	const [targetRoute] = this.routes.filter(item => {
  	 		return (item.route.Id === event.detail.routeId);
  	  	});

		if (sourceRoute && targetRoute && event.detail.startTimeHH && event.detail.startTimeMM) {

		  	// remove the dragged booking from source route and add it the list of bookings assigned to target route.
		  	// also update other attributes of the dragged booking (e.g. Route_Lookup__c & Start_Time__c).
		  	let draggedBooking;
		  	let bookings = sourceRoute.bookings.filter(item => {
  	  			if (item.booking.Id === this.draggedBookingId) {
  	  			  	// found the dragged booking. update booking attributes. do not return the booking, so that it gets
  	  			  	// removed from source route.
					item.booking.Start_Time__c = Date.UTC(1970, 0, 1, event.detail.startTimeHH, event.detail.startTimeMM);
					item.booking.Route_Lookup__c = targetRoute.route.Id;
					item.booking.Route_Lookup__r = {Id: targetRoute.route.Id, Name: targetRoute.route.Name};
					if (!item.dirtyFields.includes(CONSTANTS.PUD_BOOKING_FIELDS.FIELD_START_TIME)) {
                        item.dirtyFields.push(CONSTANTS.PUD_BOOKING_FIELDS.FIELD_START_TIME);
                    }
                    if (!item.dirtyFields.includes(CONSTANTS.PUD_BOOKING_FIELDS.FIELD_ROUTE_LOOKUP)) {
                        item.dirtyFields.push(CONSTANTS.PUD_BOOKING_FIELDS.FIELD_ROUTE_LOOKUP);
                    }
					// keep a reference to dragged booking, so that it can be assigned to the target route's list of bookings.
					draggedBooking = item;
  	  	 		} else {
  	  	 			return item;
  	  			}
  	  		});
  	  		sourceRoute.bookings = bookings;
  	  		if (draggedBooking) {
  	  		  	// add dragged booking to target route's bookings list
  	  			targetRoute.bookings = [...targetRoute.bookings, draggedBooking];
  	  	 	}

  	  	 	// we have unsaved changes. mark that there are dirty records.
  	  		this.hasDirtyRecords = true;

  	  		this.template.querySelector('c-pud-bulk-edit-bookings-datatable').pushUpdated({
  	  		    ...draggedBooking.booking,
                dirtyFields: draggedBooking.dirtyFields
            });
  		}

		// drop event has been received. data populated by previous drag event is no longer relevant.
  		this.draggedBookingId = null;
  		this.sourceRouteId = null;
 	}

 	handleBookingFieldValueChange(event) {

 	    if (event.detail.id) {
 	        const updatedBooking = this._bookings[event.detail.id];
            if (updatedBooking && updatedBooking.booking) {
	            updatedBooking.booking[event.detail.fieldName] = event.detail.draftValue;
	            if (!updatedBooking.dirtyFields.includes(event.detail.fieldName)) {
					updatedBooking.dirtyFields.push(event.detail.fieldName);
				}

				// if start_time__c is blanked out, set Display_ETA_To_Driver__c to false.
				if(event.detail.fieldName == CONSTANTS.PUD_BOOKING_FIELDS.FIELD_START_TIME
					&& event.detail.draftValue !== 0 && !event.detail.draftValue) {
						//set Display_ETA_To_Driver__c to false and add it in updatedBooking.dirtyFields property.
						updatedBooking.booking[CONSTANTS.PUD_BOOKING_FIELDS.FIELD_DISPLAY_ETA_TO_DRIVER] = false;
						updatedBooking.dirtyFields.push(CONSTANTS.PUD_BOOKING_FIELDS.FIELD_DISPLAY_ETA_TO_DRIVER);
				} 

	            // we have unsaved changes. mark that there are dirty records.
                this.hasDirtyRecords = true;

                // locate the parent route
	            const [route] = this.routes.filter(item => {
                    return (item.route.Id === updatedBooking.booking.Route_Lookup__c);
                });

				// force a re-render by reassigning the bookings
				route.bookings = [...route.bookings];
				this.template.querySelector('c-pud-bulk-edit-bookings-datatable').pushUpdated({
                    ...updatedBooking.booking,
                    dirtyFields: updatedBooking.dirtyFields
                });
	        }
        }
    }

 	handleBookingSelect(event) {
 	  	if (event.detail && event.detail.bookingId) {
	        this.selectedBooking = this._bookings[event.detail.bookingId];
	        const searchTerm = this.selectedBooking && this.selectedBooking.booking.Name ? this.selectedBooking.booking.Name : null;
	        this.template.querySelector('c-pud-bulk-edit-bookings-datatable').setSearchTerm(searchTerm);
		}
  	}

  	handleCancel(event) {
  	  	this.getSelectedRoutes(this.selectedRouteIds, this.selectedBookingRecordTypes);
	}

	handleSave(event) {
		const dirtyBookings = [];
		this.routes.forEach(route => {
            route.bookings.forEach(item => {
                if (item.dirtyFields && item.dirtyFields.length > 0) {
                    const fields = {};
                    fields[CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_ID] = item.booking[CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_ID];
                    item.dirtyFields.forEach(f => {
                        fields[f] = item.booking[f];
                    });

                    dirtyBookings.push({
                        ...fields,
                        sobjectType: CONSTANTS.PUD_BOOKING_OBJECT
                    });
                }
            });
        });

		if (dirtyBookings.length > 0) {
			this.isLoading = true;
            saveBookings(dirtyBookings)
                .then((result) => {
                    this.isLoading = false;
                    this.getSelectedRoutes(this.selectedRouteIds, this.selectedBookingRecordTypes);
                })
                .catch((error) => {
                    this.dispatchEvent(new ShowToastEvent({
							title: 'Save Error',
							message: error.body.message,
							variant: 'error'}));
                    this.isLoading = false;
                });
        }
    }

	handleZoomIn(event) {
	  	this.zoomLevel++;
  	}

	handleZoomOut(event) {
	  	this.zoomLevel--;
 	}

 	get zoomOutDisabled() {
 		return ((this.horizontalScale + this.zoomLevel) <=1);
  	}

  	get zoomInDisabled() {
		return this.zoomLevel >= 5;
	}

	get horizontalScale() {

		const lowRange = parseInt(Math.floor(epochToDecimalTime(this.earliestStartTime)), 10);
		const highRange = parseInt(Math.ceil(epochToDecimalTime(this.latestEndTime)), 10);
		const intervalCount = ((highRange+1) - (lowRange-1)) * 12;

		const maximumIntervalsForFullWidth = (CONSTANTS.CLIENT_FORM_FACTOR !== 'Large' ? (CONSTANTS.CLIENT_FORM_FACTOR !== 'Medium' ? 24 : 36) : 36);

		return (intervalCount > maximumIntervalsForFullWidth ? parseInt(Math.floor(intervalCount/maximumIntervalsForFullWidth), 10) : 1);
	}

	get horizontalScalingFactor() {
		return ((this.horizontalScale ? this.horizontalScale : 1) + this.zoomLevel);
	}

	getSelectedRoutes(routeIds, bookingRecordTypes) {
	  	this.isLoading = true;
		getRoutes(routeIds, bookingRecordTypes)
		  	.then((result) => {

		  	  	this.routes = result;

		  	  	// store the mapping of booking id to booking. this makes it easier to locate a booking by it's id.
                const bookingsMap = {};
                this.routes.forEach(route => {
                    route.bookings.forEach(item => {
                        bookingsMap[item.booking.Id] = item;
                    });
                });

                this._bookings = bookingsMap;
                this.hasDirtyRecords = false;
  	  	  	  	this.zoomLevel =0;
  	  	  	  	this.isLoading = false;
  	  	  	})
  	  	  	.catch((error) => {
  	  	  	  	this.isLoading = false;
  	  	  	});

 	}
}