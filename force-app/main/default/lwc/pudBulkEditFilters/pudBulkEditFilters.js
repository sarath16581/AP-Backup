/**
 * @description Display the filters for selecting routes / bookings to select on PUD bulk edit screen.
 * @author Ranjeewa Silva
 * @date 2022-01-21
 * @changelog
 * 2022-01-21 - Ranjeewa Silva - Created
 */

import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CONSTANTS, getDepot } from 'c/pudBulkEditBookingsService';

export default class PudBulkEditFilters extends LightningElement {

	// PUD depot(Network__c object) Id supplied by the parent.
	_depotId;
    @api
    get depotId() { return this._depotId; }
    set depotId(value) {
        if (value) {
            this._depotId = value;
            if (!this.depot) {
                // get the details of the depot. we do this on receiving depot id, only when a depot selection has not been
                // made in this component. if user has already made a depot selection ignore the value supplied by parent.
                this.getDepot(this._depotId);
            }
        }
    }


	// maximum number of routes that can be selected
    @api maxRoutesSelection;

	// selected depot including all routes operated by that depot. if depot id is supplied by the parent component,
	// details of supplied depot is loaded. if not supplied, the user can select a depot. @track decorator is used to
	// track changes to internal field values of the complex object.
	@track depot;

    // booking record type id to filter the bookings.
    bookingRecordTypeId = '';

	// if set to true, indicates the data is currently being loaded.
    isLoading;

	// booking record type metadata loaded via the wire adapter.
    _bookingRecordTypeInfos;
	@wire(getObjectInfo, { objectApiName: CONSTANTS.PUD_BOOKING_OBJECT })
	pudBookingObjectInfo({ error, data }) {
		if (data) {
			this._bookingRecordTypeInfos = data.recordTypeInfos;
		} else if (error) {
			this._bookingRecordTypeInfos = [];
		}
	}

	handleDepotSelected(event) {
		if (event.detail && event.detail.record) {
		    // depot selection made by user on user interface. load details of the depot including it's child routes.
		    this.getDepot(event.detail.record.Id);
		}
	}

	handleClearSelectedDepot(event) {
		this.depot = null;
	}

	handleSelectRoute(event) {
		if (event.target.name) {
		    // route selection is made. update underlying data model.
		    this.selectRoute(event.target.name, event.target.checked);
		}
	}

	handleClearSelectedRoute(event) {
		if (event.detail.item.name) {
		    // selected route is cleared. update underlying data model.
			this.selectRoute(event.detail.item.name, false);
		}
	}

	handleBookingRecordTypeSelect(event){
	    // update the record type id based on the selection
		this.bookingRecordTypeId = event.target.value;
	}

	handleResetFilters(event) {
	    // reset all filters.
		this.depot = null;
		this.bookingRecordTypeId = '';
	}

	handleApplyFilters(event) {
	    // confirm selections and dispatch event containing selection to parent
		if (this.selectedRoutes && this.selectedRoutes.length > 0) {
			const routeIds = this.selectedRoutes.map(item => {
				return item.routeId;
			});

			const recordTypesFilter = this.bookingRecordTypeId && this.bookingRecordTypeId !== '' ? [this.bookingRecordTypeId] : [];

			const confirmFiltersEvent = new CustomEvent('confirm', {
				detail: {
					routeIds: routeIds,
					bookingRecordTypes: recordTypesFilter
				}
			});
			this.dispatchEvent(confirmFiltersEvent);
		}
	}

	/**
	 * retrieve details of the selected depot together with all routes operated by that depot.
	 */
	getDepot(depotId) {
        this.isLoading = true;

		getDepot(depotId)
			.then((result) => {
			    const depot = {
                    depotId: depotId,
                    name: '',
                    routes: []
                };
                if (result) {
                    depot.name = result.Name;
                    if (result.Routes__r && result.Routes__r.length > 0) {
                        const routes = result.Routes__r.map(item => {
                            return {
                                routeId: item.Id,
                                name: item.Name,
                                isSelected: false,
                                isDisabled: false
                            };
                        });
                        depot.routes = routes;
                    }
                }
                this.depot = depot;
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
            });
	}

	selectRoute(routeId, selected) {
 	    const numberOfRoutesSelected = this.selectedRoutes.length + (selected ? 1 : -1);
		this.depot.routes.forEach(item => {

			if (item.routeId === routeId) {
				item.isSelected = selected;
			}

			// check number of routes currently selected and enable/disable ability to select more routes.
			if (this.maxRoutesSelection && numberOfRoutesSelected >= this.maxRoutesSelection && !item.isSelected) {
				item.isDisabled = true;
			} else {
				item.isDisabled = false;
			}
		});
  	}

	get selectedDepotPill() {
		return this.depot ? [{ type: 'icon', label: this.depot.name, iconName: 'custom:custom32'}] : [];
	}

	get selectedRoutes() {

		if (this.depot && this.depot.routes && this.depot.routes.length > 0) {
			const filteredRoutes = this.depot.routes.filter(item => {
				return (item.isSelected);
			});
			return filteredRoutes;
		}
		return [];
	}

	get selectedRoutePills() {
		const selectedRoutePills = this.selectedRoutes.map(item => {
			 return {
				 label: item.name,
				 type: 'icon',
				 iconName: 'custom:custom73',
				 name: item.routeId
			 };
		});
		return selectedRoutePills;
	}

	get hasSelectedRoutes() {
		return (this.selectedRoutes && this.selectedRoutes.length > 0);
	}

	get filteringDisabled() {
		return !this.hasSelectedRoutes;
	}

	get bookingRecordTypeOptions() {

		const recordTypeOptions = [{ label: '--N/A--', value: '' }];

		if (this._bookingRecordTypeInfos) {
			Object.values(this._bookingRecordTypeInfos).forEach(item => {
				if (!item.master) {
					recordTypeOptions.push({label: item.name, value: item.recordTypeId});
				}
			});
		}
		return recordTypeOptions;
	}
}