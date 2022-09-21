/**
 * @description PUD bookings data table with sorting, filtering and inline edit support. Forms part of the PUD Bulk Edit
 *              user interface. Receives bookings data from parent component and inline edits are published back to the parent
 *              as custom events.
 * @author Ranjeewa Silva
 * @date 2022-03-08
 * @changelog
 * 2022-03-08 - Ranjeewa Silva - Created
 * 2022-09-14 - Dattaraj Deshmukh - Added 'Display ETA To Driver' and removed 'Display Start Time' column. 
 *              Updated 'getCellAttributes()' to conditionally allow inline editing for 'Display ETA To Driver'.
 */

import { LightningElement, api } from 'lwc';
import { CONSTANTS, getValue, getColorCodeStyleClass } from 'c/pudBulkEditBookingsService';
import { debounce, get } from 'c/utils';

export default class PudBulkEditBookingsDatatable extends LightningElement {

	// bookings received from parent.
  	@api bookings;

	// search term to use for filtering the data table.
  	searchTerm;

  	// cached list of computed bookings for display (after filtering by search term, and after sorting).
  	// cache is invalidated whenever a rebuild is necessary.
  	_computedBookingsCache;

	// indicates the bookings data is currently being filtered
  	isFiltering;

	// indicates the bookings data is currently being sorted
  	isSorting;

	// field currently used for sorting the data
  	sortedBy;

	// sort direction - ascending or descending
  	sortDirection;

	// list of column definitions for rendering bookings data table.
	// consider making this configurable ( field sets or metadata ) - hardcoded for now.
	bookingsTableColumns =[
		{label: 'Booking Id', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_NAME, editable:false, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.TEXT, headerCssClass : 'slds-th__action slds-text-link_reset', dataCssClass : 'slds-cell-wrap'},
		{label: 'Record Type', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_RECORDTYPE_NAME, editable:false, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.TEXT, headerCssClass : 'slds-th__action slds-text-link_reset max-width_small', dataCssClass : 'slds-cell-wrap max-width_small', colorCoded:true},
		{label: 'Booking Type', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_TYPE, editable:false, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.TEXT, headerCssClass : 'slds-th__action slds-text-link_reset max-width_x-small', dataCssClass : 'slds-cell-wrap max-width_x-small'},
		{label: 'Route', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_ROUTE_LOOKUP_NAME, editable:false, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.TEXT, headerCssClass : 'slds-th__action slds-text-link_reset max-width_small', dataCssClass : 'slds-cell-wrap'},
		{label: 'Start Time', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_START_TIME, editable:true, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.TIME, headerCssClass : 'slds-th__action slds-text-link_reset', dataCssClass : 'slds-cell-wrap'},
		{label: 'Dwell Time (mins)', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_DWELL_TIME_PLANNED, editable:true, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.INTEGER, typeAttributes: {min:1, max:9999},headerCssClass : 'slds-th__action slds-text-link_reset', dataCssClass : 'slds-cell-wrap'},
		{label: 'Display ETA To Driver', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_DISPLAY_ETA_TO_DRIVER, editable:false, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.CHECKBOX, headerCssClass : 'slds-th__action slds-text-link_reset', dataCssClass : 'slds-cell-wrap', conditionalInlineEdit:true},
		{label: 'Parent Booking', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_PARENT_BOOKING_NAME, editable:false, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.TEXT, headerCssClass : 'slds-th__action slds-text-link_reset', dataCssClass : 'slds-cell-wrap'},
		{label: 'Booking Comments', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_COMMENTS, editable:true, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.TEXTAREA, typeAttributes: {maxLength:1500}, headerCssClass : 'slds-th__action slds-text-link_reset max-width_small', dataCssClass : 'slds-cell-wrap max-width_small'},
		{label: 'Location Address', fieldName: CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_LOCATION_ADDRESS, editable:false, sortedColumn: false, fieldType: CONSTANTS.FIELD_TYPES.TEXT, headerCssClass : 'slds-th__action slds-text-link_reset max-width_medium', dataCssClass : 'slds-cell-wrap max-width_medium'}
	];

	// message displayed when no rows to display after filtering bookings.
	noMatchesFoundMessage = CONSTANTS.LABEL_NOMATCHESFOUNDMESSAGE;

	// search term change handler
    debounceSearchTermChangeHandler = debounce(this.updateSearchTerm, 200);

	/**
	 * returns true if bookings for selected routes are available and loaded.
	 */
	get hasBookingsToShow() {
		return (this._computedBookingsCache && this._computedBookingsCache.length > 0);
	}


	/**
	 * compute the actual dataset to be rendered in the table.
	 */
	get computedBookings() {

		if (!this.bookings || this.bookings.length === 0) {
		    // no bookings received from parent. nothing to render.
			return [];
		}

		if (this._computedBookingsCache) {
			return this._computedBookingsCache;
        }

		const computedDataset = this.filteredBookings.map(item => {

			const columns = this.bookingsTableColumns.map(column => {
			    const col = {
					...column,
					fieldValue: getValue(item, column.fieldName, null),
					key: item['Id'] + column.fieldName,
					styleCss: column.dataCssClass + ((item.dirtyFields && item.dirtyFields.length > 0) ? ' slds-cell-edit slds-is-edited': ' slds-cell-edit'),
					cellAttributes: this.getCellAttributes(item, column)
				};
				return col;
			});

			return {
				...item,
				_columns: columns
			};
		});

		this._computedBookingsCache = computedDataset;

		if (this.sortedBy) {
			this.sortData(this.sortedBy);
        }

		return this._computedBookingsCache;
	}

	/**
     * return filtered bookings after filtering by the specified search term.
     */
	get filteredBookings() {

        this.isFiltering = true;

        let filteredBookings;

        if (this.searchTerm) {
            // we have a search term. filter records based on the search term.
            const escapedSearchTerm = this.searchTerm.replace(/[.*+\-?^${}()|[\]\\]/g, '\\$&');
            const pattern = '\\b' + escapedSearchTerm;
            const cachedRegEx = new RegExp(pattern, 'i');
            if(escapedSearchTerm) {
                filteredBookings = this.bookings.filter(item => {
                    let value = item.Name
                                    + '|' + getValue(item, CONSTANTS.PUD_BOOKING_FIELDS.FIELD_ROUTE_LOOKUP_NAME, '')
                                    + '|' + getValue(item, CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_LOCATION_ADDRESS, '')
                                    + '|' + getValue(item, CONSTANTS.PUD_BOOKING_FIELDS.FIELD_BOOKING_RECORDTYPE_NAME, '')
                                    + '|' + getValue(item, CONSTANTS.PUD_BOOKING_FIELDS.FIELD_PARENT_BOOKING_NAME, '');
                    return cachedRegEx.test(value);
                });
            }
        } else {
            // search term is not set - return the full list
            filteredBookings= [...this.bookings];
        }

        this.isFiltering = false;
        return filteredBookings;
    }

	/**
	 * provides a summary of bookings currently rendered (e.g. '3 of 215 Bookings' => 3 bookings filtered out of a possible 215
	 * based on the search term).
	 */
	get bookingsCountSummary() {
	    let summary = '';
	    summary += ((this.computedBookings && this.computedBookings.length !== this.bookings.length) ? (this.computedBookings.length + ' of ') : '');
	    summary += ((this.bookings ? this.bookings.length : 0) + ' Bookings ');
	    return summary;
	}

	/**
     * provides support for parent to filter the data in the table
     */
    @api setSearchTerm(value) {
        this.updateSearchTerm(value);
    }

    /**
	 * called by parent to notify updates to individual bookings. this approach ensures that we only have to
	 * rerender the updated booking. no need to compute the whole data table.
	 */
    @api pushUpdated(updatedBooking) {
        if (this._computedBookingsCache && this._computedBookingsCache.length > 0) {

			// locate the updated booking in currently rendered dataset.
			const bookingIndex = this._computedBookingsCache.findIndex(booking => booking.Id === updatedBooking.Id);
            if (bookingIndex > -1) {
                // booking found - rebuild only the dirty booking
                const columns = this.bookingsTableColumns.map(column => {
                    const col = {
                        ...column,
                        fieldValue: getValue(updatedBooking, column.fieldName, null),
                        key: updatedBooking['Id'] + column.fieldName,
                        styleCss: column.dataCssClass + ((updatedBooking.dirtyFields && updatedBooking.dirtyFields.length > 0) ? ' slds-cell-edit slds-is-edited': ' slds-cell-edit'),
                        cellAttributes: this.getCellAttributes(updatedBooking, column)
                    };
                    return col;
                });

				// update the cache to rerender the updated booking row
                this._computedBookingsCache[bookingIndex] =  {
                    ...updatedBooking,
                    _columns: columns
                };
            }
        }
    }

	/**
	 * handle field value change as a result of an inline edit.
	 */
	handleValueChange(event) {
		if (event.detail && event.detail.id) {

			// propagate the event up to the parent.
            const fieldValueChange = new CustomEvent('fieldvaluechange', {
                detail: {
                    id : event.detail.id,
                    fieldName : event.detail.fieldName,
                    draftValue : event.detail.draftValue
                }
            });
            this.dispatchEvent(fieldValueChange);
		}
	}

	/**
	 * handler for changing search term for filtering.
	 */
	handleSearchTermChange(event) {
	    this.debounceSearchTermChangeHandler(event.target.value);
	}

	/**
	 * handle sorting data by a selected column
	 */
	handleSort(event) {
        const target = event.currentTarget
        const id = target.dataset.id

        //Set sort order based on field
        if (this.sortedBy === id) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortedBy = id;
            this.sortDirection = 'desc';
        }

        this.sortData(this.sortedBy);
    }

	/**
	 * update search term and trigger a rebuild of the filtered bookings cache
	 */
	updateSearchTerm(value) {
		this.searchTerm = value;
		// invalidate the cache so it can be rebuilt based on the search term.
		this._computedBookingsCache = null;
	}

    async sortData(sortedBy) {

        this.isSorting = true;

        const cloneData = [...this._computedBookingsCache];

        // grab the definition of the sort column
        const fieldType = this.bookingsTableColumns.filter((field) => field.fieldName === sortedBy);
        const fieldSort = this.bookingsTableColumns.filter((field) => field.sortedColumn === true);

        // sort the data factoring in if it's a date field then we reference the timestamp instead of the actual date
        const primer = (val, row) => {
            if(!fieldType || fieldType.length === 0) {
                return val;
            } else {
                if((fieldType[0].fieldType === CONSTANTS.FIELD_TYPES.DATE || fieldType[0].fieldType === CONSTANTS.FIELD_TYPES.TIME) && !isNaN((new Date(val)).getTime())) {
                    return (new Date(val)).getTime()
                } else {
                    return val;
                }
            }
        };

        //Set sorted column
        if(fieldType[0] !== undefined && !fieldType[0].sortedColumn){
            fieldType[0].sortedColumn = true;
        }
        if(fieldSort[0] !== undefined && fieldType[0].fieldName !== fieldSort[0].fieldName){
            fieldSort[0].sortedColumn = false;
        }

        // sort our data
        cloneData.sort(this.sortBy(sortedBy, (this.sortDirection === 'asc' ? 1 : -1), primer));
        this._computedBookingsCache = cloneData;

        this.isSorting = false;
    }

    // Sort the data columns
    sortBy = (field, reverse, primer) => {
        const key = primer
            ? function(x) {
                return primer(getValue(x, field, x[field]), x);
            }
            : function(x) {
                return getValue(x, field, x[field]);
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

    getCellAttributes(booking, column) {
        if(column.colorCoded){
            return ({styleClass: 'dot ' + getColorCodeStyleClass(booking)});
        }
        else if(column.conditionalInlineEdit){ //set column value editable if Booking.start_time__c is NOT NULL.
            const isStartTimePopulated = booking.Start_Time__c ? !isNaN(booking.Start_Time__c) : false;  
            return ({editable : isStartTimePopulated});
        }
        return null;
    }

    get isAsc() {
	    return (this.sortDirection === 'asc');
	}

	get isLoading() {
		return (this.isFiltering || this.isSorting);
    }
}