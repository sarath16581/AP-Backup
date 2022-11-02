/**
 * @description Service class or utility functions and server communication
 * @author Ranjeewa Silva
 * @date 2022-02-11
 * @changelog
 * 2022-02-11 - Ranjeewa Silva - Created
 * 2022-09-14 - Dattaraj Deshmukh - Added 'Display ETA To Driver' and removed 'Display Start Time' field.
 * 				Updated FIELD_TYPES to include 'Checkbox' column.
 */

// server calls
import loadBulkEditConfig from '@salesforce/apex/PUDPickupBookingController.loadBulkEditConfig';
import getDepotWithRoutes from '@salesforce/apex/PUDPickupBookingController.getDepot';
import getRoutesWithChildBookings from '@salesforce/apex/PUDPickupBookingController.getRoutes';
import updateBookings from '@salesforce/apex/PUDPickupBookingController.updateBookings';

// custom labels
import LABEL_NOROUTESSELECTEDMESSAGE from '@salesforce/label/c.PUDBulkEditNoRoutesSelectedMessage';
import LABEL_NOBOOKINSTODISPLAYMESSAGE from '@salesforce/label/c.PUDBulkEditNoBookingsToDisplayMessage';
import LABEL_NOMATCHESFOUNDMESSAGE from '@salesforce/label/c.PUDBulkEditNoMatchesFoundMessage';

// objects
import PUD_BOOKING_OBJECT from '@salesforce/schema/PUD_Booking__c';

// fields
import FIELD_START_TIME from '@salesforce/schema/PUD_Booking__c.Start_Time__c';
import FIELD_DISPLAY_ETA_TO_DRIVER from '@salesforce/schema/PUD_Booking__c.Display_ETA_to_Driver__c';
import FIELD_ROUTE_LOOKUP from '@salesforce/schema/PUD_Booking__c.Route_Lookup__c';
import FIELD_ROUTE_LOOKUP_NAME from '@salesforce/schema/PUD_Booking__c.Route_Lookup__r.Name';
import FIELD_BOOKING_LOCATION_ADDRESS from '@salesforce/schema/PUD_Booking__c.Booking_Location_Address__c';
import FIELD_BOOKING_RECORDTYPE_NAME from '@salesforce/schema/PUD_Booking__c.RecordType.Name';
import FIELD_STREET from '@salesforce/schema/PUD_Booking__c.Street__c';
import FIELD_CITY from '@salesforce/schema/PUD_Booking__c.City__c';
import FIELD_STATE from '@salesforce/schema/PUD_Booking__c.State__c';
import FIELD_POSTCODE from '@salesforce/schema/PUD_Booking__c.Post_Code__c';
import FIELD_BOOKING_ID from '@salesforce/schema/PUD_Booking__c.Id';
import FIELD_BOOKING_NAME from '@salesforce/schema/PUD_Booking__c.Name';
import FIELD_BOOKING_TYPE from '@salesforce/schema/PUD_Booking__c.Booking_Type__c';
import FIELD_BOOKING_COMMENTS from '@salesforce/schema/PUD_Booking__c.Booking_Comments__c';
import FIELD_PARENT_BOOKING_NAME from '@salesforce/schema/PUD_Booking__c.Parent_Booking__r.Name';
import FIELD_DWELL_TIME_PLANNED from '@salesforce/schema/PUD_Booking__c.Dwell_Time_Planned__c';
import FIELD_LOCATION from '@salesforce/schema/PUD_Booking__c.Location__c';

import { get } from 'c/utils';

import CLIENT_FORM_FACTOR from '@salesforce/client/formFactor';

export const CONSTANTS = {
	DEFAULT_DWELL_TIME_IN_MINUTES: 5,
	NUMBER_OF_MINUTES_PER_INTERVAL: 5,
	DEFAULT_ROUTE_START_TIME_HH: 8,
	DEFAULT_ROUTE_START_TIME_MM: 30,
	DEFAULT_ROUTE_END_TIME_HH: 17,
	DEFAULT_ROUTE_END_TIME_MM: 0,

	PUD_BOOKING_OBJECT : PUD_BOOKING_OBJECT.objectApiName,

	PUD_BOOKING_FIELDS : {
	    FIELD_BOOKING_ID : FIELD_BOOKING_ID.fieldApiName,
	    FIELD_BOOKING_NAME : FIELD_BOOKING_NAME.fieldApiName,
	    FIELD_BOOKING_RECORDTYPE_NAME : FIELD_BOOKING_RECORDTYPE_NAME.fieldApiName,
	    FIELD_BOOKING_TYPE : FIELD_BOOKING_TYPE.fieldApiName,
	    FIELD_START_TIME : FIELD_START_TIME.fieldApiName,
	    FIELD_ROUTE_LOOKUP : FIELD_ROUTE_LOOKUP.fieldApiName,
	    FIELD_ROUTE_LOOKUP_NAME : FIELD_ROUTE_LOOKUP_NAME.fieldApiName,
		FIELD_DISPLAY_ETA_TO_DRIVER : FIELD_DISPLAY_ETA_TO_DRIVER.fieldApiName,
	    FIELD_BOOKING_COMMENTS : FIELD_BOOKING_COMMENTS.fieldApiName,
	    FIELD_BOOKING_LOCATION_ADDRESS : FIELD_BOOKING_LOCATION_ADDRESS.fieldApiName,
	    FIELD_STREET : FIELD_STREET.fieldApiName,
	    FIELD_CITY : FIELD_CITY.fieldApiName,
	    FIELD_STATE : FIELD_STATE.fieldApiName,
	    FIELD_POSTCODE : FIELD_POSTCODE.fieldApiName,
	    FIELD_PARENT_BOOKING_NAME : FIELD_PARENT_BOOKING_NAME.fieldApiName,
	    FIELD_DWELL_TIME_PLANNED : FIELD_DWELL_TIME_PLANNED.fieldApiName,
	    FIELD_LOCATION : FIELD_LOCATION.fieldApiName
	},

	FIELD_TYPES : {
    	TEXT: 'TEXT',
    	TEXTAREA: 'TEXTAREA',
    	DATE: 'DATE',
    	DATETIME: 'DATETIME',
    	TIME: 'TIME',
    	INTEGER: 'INTEGER',
		CHECKBOX: 'CHECKBOX'
    },

	CLIENT_FORM_FACTOR: CLIENT_FORM_FACTOR,

	LABEL_NOROUTESSELECTEDMESSAGE: LABEL_NOROUTESSELECTEDMESSAGE,
	LABEL_NOBOOKINSTODISPLAYMESSAGE: LABEL_NOBOOKINSTODISPLAYMESSAGE,
	LABEL_NOMATCHESFOUNDMESSAGE: LABEL_NOMATCHESFOUNDMESSAGE
}

// private vars
let _config;

/**
 * load runtime config required for Bulk Edit UI
 */
export const getConfig = async () => {
	if(!_config) {
		_config = await loadBulkEditConfig();
		return Promise.resolve(_config);
	} else {
		return Promise.resolve(_config);
	}
}

/**
 * Retrieve route details with child bookings.
 */
export const getRoutes = async (routeIds, bookingRecordTypes) => {

    const result = await getRoutesWithChildBookings({
        routeIds: routeIds,
        bookingRecordTypes: bookingRecordTypes
    });
	return result;
}

/**
 * Retrieve depot with all child routes.
 */
export const getDepot = async (depotId) => {

    const result = await getDepotWithRoutes({
        depotId: depotId
    });
	return result;
}

export const saveBookings = async (bookings) => {
    const result = await updateBookings({
        bookings: bookings
    });
	return result;
}

/**
 * converts the epoch time passed in into decimal format.
 */
export const epochToDecimalTime = (epochTime) => {
	if (epochTime) {
		const d = new Date(epochTime);
		// get utc hours and utc minutes
		return (d.getUTCHours() + (d.getUTCMinutes() / 60));
	}
	return;
}

/**
 * formats the decimal time for display
 */
export const decimalToDisplayTime = (decimalTime) => {
	if (decimalTime) {
		const hours = parseInt(decimalTime, 10);
		const minutes = Math.round((decimalTime - hours)*60);
		return getDisplayTimeString(hours, minutes);
	}
	return '';
}

/**
 * formats hours and minutes passed in for display
 */
export const getDisplayTimeString = (hours, minutes) => {
	const hhLabel = (hours === 0 ? '12' : (hours<=12 ? hours : hours-12));
	const minLabel = (minutes === 0 ? '' : (minutes < 10 ? '0'+minutes : ''+minutes));
	return hhLabel + (minLabel.length > 0 ? ':' : '') + minLabel + (hours<12?'am':'pm');
}

export const getValue = (record, fieldName, defaultValue) => {
    if (fieldName === CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_LOCATION_ADDRESS) {
        // 'Booking_Location_Address__c' formula field currently contain formatting (<br> tags) for display on Job boards.
        // hack for getting the full address without formatting - Street__c, City__c, State__c, Post_Code__c
        const locationName = get(record, CONSTANTS.PUD_BOOKING_FIELDS.FIELD_LOCATION, '');
        const address = (get(record, CONSTANTS.PUD_BOOKING_FIELDS.FIELD_STREET, '') + ' '
                            + get(record, CONSTANTS.PUD_BOOKING_FIELDS.FIELD_CITY, '') + ' '
                            + get(record, CONSTANTS.PUD_BOOKING_FIELDS.FIELD_STATE, '') + ' '
                            + get(record, CONSTANTS.PUD_BOOKING_FIELDS.FIELD_POSTCODE, ''));
        return (locationName.length > 0 ? locationName + '\n': '') + address.trim();
    }
    return get(record, fieldName, defaultValue);
}

export const getColorCodeStyleClass = (booking) => {
    if (booking.RecordType && booking.RecordType.DeveloperName) {
        return (booking.RecordType.DeveloperName === 'AP_Permanent_Pickup' ? 'color-code_permanent'
    				: booking.RecordType.DeveloperName === 'AP_Adhoc_Pickup' ? 'color-code_adhoc'
    				: booking.RecordType.DeveloperName === 'AP_Dependant_Delivery' ? 'color-code_dependent'
    				: booking.RecordType.DeveloperName === 'MPB_Pickup' ? 'color-code_mpb'
    				: booking.RecordType.DeveloperName === 'Other' ? 'color-code_other'
    				: 'color-code_default');
    }

    return 'color-code_default';
}