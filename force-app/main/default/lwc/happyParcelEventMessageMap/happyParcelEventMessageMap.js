/**
 * @description Happy Parcel Event Message Map
 * @author Mahesh Parvathaneni
 * @date 2022-04-11
 * @group Tracking
 * @changelog
 */
import { api } from 'lwc';
import HappyParcelBase from 'c/happyParcelBase';

export default class HappyParcelEventMessageMap extends HappyParcelBase {
    @api eventId; // id of the event message from the parent
    @api mapMarkers; // map markers from the parent to use in the lighnting map  
    @api listView = 'hidden'; // displaying/hiding the list of locations. Default is 'hidden'. Valid values are hidden/visible 
    @api zoomLevel; //zoom-level for the map. 
    @api selectedMarkerValue; //selected marker value to highlight the location
    @api markersTitle; //markers title passed from parent
    @api showFooter = false; //render footer for the map with a link to open in new tab/window

    // dynamic css class to make sure overrides are applicable when there is no list view 
    // as em-map-card__container is overriden from static resource
    get containerClass() {
        return this.listView === 'visible' ? 'em-map-list-card__container map-icon' : 'em-map-card__container map-icon';
    }

    // handler on card close button click
    handleCardCloseClick() {
        this.dispatchEvent(new CustomEvent('closemap', {detail: this.eventId}));
    }

    // handler on marker select
    handleMarkerSelect(event) {
        this.selectedMarkerValue = event.target.selectedMarkerValue;
    }

    connectedCallback() {
        //set the default zoom level when there is only one marker
        if (this.mapMarkers.length === 1) {
            this.zoomLevel = '15';
        }
    }
}