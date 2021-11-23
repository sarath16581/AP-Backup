/**
 * @author       : arjun.singh@auspost.com.au
 * @date         : 23/03/2020
 * @description  : Js for getting the related event Messages and related data
 *                 for displaying information in google map
 */
/*******************************  History ************************************************
14.05.2020    arjun.singh@auspost.com.au    Updated to include Google Map related Method
10.08.2020    disha.kariya@auspost.com.au   Added changes to display a link to google map direction
17.08.2020    disha.kariya@auspost.com.au   Updated to display Attempted Delivery on GPS Pin Drop
02.09.2020    disha.kariya@auspost.com.au   Changes to add helptext for map direction
/*******************************  History ************************************************/

import { LightningElement, api, track, wire } from "lwc";
import getRelatedEventMessages from "@salesforce/apex/MyNetworkCaseListController.getRelatedEventMessages";
import getSafeDropInformation from "@salesforce/apex/MyNetworkCaseListController.getSafeDropInformation";
import getAddressFromGeoLocationForEventMessage from "@salesforce/apex/MyNetworkCaseListController.getAddressFromGeoLocationForEventMessage";
import { loadStyle } from "lightning/platformResourceLoader";
import customStyle from "@salesforce/resourceUrl/MYNetworkCustomStyle";
import { NavigationMixin } from "lightning/navigation";
import { get } from "c/utils";
/** the address to send display google map direction */
import GOOGLE_MAP_DIRECTION from '@salesforce/label/c.Google_map_direction';
import MAP_DIRECTION_HELPTEXT from '@salesforce/label/c.Map_direction_helptext';
const dateFormat ={
  day: "numeric",
  month: "short",
  year: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  hour12: false
};

export default class RelatedEventMessages extends NavigationMixin(LightningElement) {
  @api recordId;
  @track eventMessages = [];
  @track hasEventMessage = false;
  @track statusIcon = "checkMark";
  @track bShowModal = false;
  @track mapMarker={};
  @track mapMarkers=[];
  @track safeDropDetails;
  @track safeDropDataAvailable = false;
  @track detailInfoIcon = 'utility:chevronright'
  @track childTableId;
  @track activeSections = ['A'];  
  @track sortingEventMessage =[];
  @track sortingEventMessageFound = false;
  @track unableToFetchDetailsFromGoogleApi = false;
  @track googleDirectionURL = 'javascript:void(0);'

  connectedCallback() {
    this.bShowModal = false;
    Promise.all([
      loadStyle(this, customStyle + "/MYNetworkCustomStyle.css")
    ]).catch(error => {
      console.log("error in loading the style>>", error);
    });
    /* @Description: Method used to get the related event messages for a Case.
    */
    getRelatedEventMessages({ caseRecordId: this.recordId })
      .then(result => {
        if (result) {
          let eventMessageList = [];
          let eventMessagesVar = result.eventMessageWithGeoCodeList ;
          
          for (let i = 0; i < eventMessagesVar.length; i++) {
            let eventMessageRec = {};
           this.getStatusImage(eventMessagesVar[i].EventType__c);
            if (this.statusIcon === "lock") {
              eventMessageRec.imageColorCss = "yellowcolor";
              eventMessageRec.displayIconName = "utility:lock";
            } else {
              eventMessageRec.imageColorCss = "greencolor";
              eventMessageRec.displayIconName = "utility:check";
            }
            if(eventMessagesVar[i].eventMessageRecord.ActualDateTime__c){   
              let acutalDateVar = new Date(eventMessagesVar[i].eventMessageRecord.ActualDateTime__c) ;
              eventMessageRec.actualDate =   acutalDateVar.toLocaleDateString("en-US", dateFormat); 
            }else{
              eventMessageRec.actualDate = '';
            }   
            if(eventMessagesVar[i].eventMessageRecord.PlannedDateTime__c){   
              let planDateVar = new Date(eventMessagesVar[i].eventMessageRecord.PlannedDateTime__c) ;
              eventMessageRec.planDate =   planDateVar.toLocaleDateString("en-US", dateFormat); 
            }else{
              eventMessageRec.planDate = '';
            }    
            eventMessageRec.showthisrow=false;
            eventMessageRec = Object.assign(eventMessageRec, eventMessagesVar[i]);
            eventMessageList.push(eventMessageRec);
            this.hasEventMessage = true;
          }
          this.eventMessages = eventMessageList;          
        }
        if(this.eventMessages){
          this.SafeDropInformationFromServer(this.recordId);
        }               
        let sortingEvMessage = result.sortingEventMessage ;
        if(sortingEvMessage.length > 0){
          for(let i = 0; i < sortingEvMessage.length; i++){
            if(sortingEvMessage[i].ActualDateTime__c){   
              let pDateVar = new Date(sortingEvMessage[i].ActualDateTime__c) ;
              let eventMessageR = {};
                eventMessageR.planDate =   pDateVar.toLocaleDateString("en-US", dateFormat); 
                eventMessageR = Object.assign(eventMessageR, sortingEvMessage[i]);
                this.sortingEventMessage.push(eventMessageR);
            }else{
              this.sortingEventMessage.push(sortingEvMessage[i]);
            }
          } 
            this.sortingEventMessageFound = true;
        }else{
          this.sortingEventMessageFound = false;
        }
      })
      .catch(error => {
        console.log("error>>>", error);
      });
  }  
   /**
    * @Description : Fetches the Event Message having geolocation and also Articles receiver address details
    *                These data will be used to display the Actual/Delivered Address in Google map 
    * @param  :       Case record Id
    */  
  SafeDropInformationFromServer(recordId){
    getSafeDropInformation({ caseRecordId: recordId })
    .then(result => {
      console.log('result>>>>>',result);
      if (result != null && result.isValid) {
        this.safeDropDetails = result;
        console.log('this.safeDropDetails>>>',this.safeDropDetails);
        this.safeDropDataAvailable = true;
      }
    })
    .catch(error => {
      console.log("error>>>", error);
    });
}
/**
 * @description :  This method is called from the "where was parcel delivered" button and will 
 *                 display Actual/Delivered Address in google map 
 */

safeDropInfoOnGoogleMap(event){
  let markers=[];
  if(this.safeDropDetails.addresseeAddress.latitudeValue != null && this.safeDropDetails.addresseeAddress.longitudeValue != null){
  
   let titleValue = 'Addressee Address (' + this.safeDropDetails.addresseeAddress.combinedAddress + ')' ;
    let addressAddressMarker={
      location: {
        'Latitude': this.safeDropDetails.addresseeAddress.latitudeValue,
        'Longitude': this.safeDropDetails.addresseeAddress.longitudeValue
    },
    title: titleValue
    };
    markers.push(addressAddressMarker);
    if(this.isValidAttemptedAddress || this.isValidDeliveredAddress){
    if(this.isValidAttemptedAddress){
        let attemptedTitle = 'Attempted Delivery Address (' + this.safeDropDetails.attemptedAddress.combinedAddress + ')';
        let attemptedMapMarker={
            location: {
            'Latitude': this.safeDropDetails.attemptedAddress.latitudeValue,
            'Longitude': this.safeDropDetails.attemptedAddress.longitudeValue
            },
            title: attemptedTitle
        };
        markers.push(attemptedMapMarker);
    }
    if(this.isValidDeliveredAddress){
      let deliveredTitle =  'Delivered Address (' + this.safeDropDetails.deliveredAddress.combinedAddress + ')';
      let deliveredMapMarker={
        location: {
          'Latitude': this.safeDropDetails.deliveredAddress.latitudeValue,
          'Longitude': this.safeDropDetails.deliveredAddress.longitudeValue
      },
      title: deliveredTitle
      };
      markers.push(deliveredMapMarker);
    }
    }else{
      // TO No Marker
      console.log('No Marker Data');
      this.unableToFetchDetailsFromGoogleApi = true;
    }
    if(this.safeDropDetails.manifestAddress != null){
      let manifestTitle ;
       if(this.safeDropDetails.manifestAddress.combinedAddress != null){
        manifestTitle = 'Manifest Address ('+ this.safeDropDetails.manifestAddress.combinedAddress + ')';
       }else{
        manifestTitle = 'Manifest Address';
       }
      let manifestAddressMarker={
        location: {
          Street:this.safeDropDetails.manifestAddress.streetName,
          City:this.safeDropDetails.manifestAddress.streetCity,
          State:this.safeDropDetails.manifestAddress.streetState,
          PostalCode :this.safeDropDetails.manifestAddress.streetPostCode,
          Country:this.safeDropDetails.manifestAddress.streetCountry,
      },
      title: manifestTitle
      };
      markers.push(manifestAddressMarker);
      console.log('manifestAddressMarker>>>',manifestAddressMarker);
    }
  }else{
    // TO No Marker
    console.log('No Marker Data');
    this.unableToFetchDetailsFromGoogleApi = true;
  }
  
  
  console.log('this.MapMarkers',markers);
  this.mapMarkers = markers;
  this.bShowModal = true;
}

/**
 * @description :  This method is called to open google map to display direction between addressee address and delivered address
 */
navigateToGoogleMap() {
        // Navigate to a URL
        let destinationAddress = '';
        if(this.isValidAttemptedAddress){
            destinationAddress = this.safeDropDetails.attemptedAddress.latitudeValue + ',' + this.safeDropDetails.attemptedAddress.longitudeValue;
        } else if(this.isValidDeliveredAddress){
            destinationAddress = this.safeDropDetails.deliveredAddress.latitudeValue + ',' + this.safeDropDetails.deliveredAddress.longitudeValue;
        }
        if(this.safeDropDetails.addresseeAddress.latitudeValue != null && this.safeDropDetails.addresseeAddress.longitudeValue != null && destinationAddress != '' ) {
            this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: GOOGLE_MAP_DIRECTION + '&origin=' + this.safeDropDetails.addresseeAddress.latitudeValue +','+ this.safeDropDetails.addresseeAddress.longitudeValue +'&destination='+ destinationAddress + '&travelmode=driving'
                    }
                }
            );
        }
    }
    get isValidDeliveredAddress() {
        return get(this.safeDropDetails, 'deliveredAddress', false) && get(this.safeDropDetails, 'deliveredAddress.combinedAddress', false) && get(this.safeDropDetails, 'deliveredAddress.latitudeValue', false) && get(this.safeDropDetails, 'deliveredAddress.longitudeValue', false);
    }
    get isValidAttemptedAddress() {
        return get(this.safeDropDetails, 'attemptedAddress', false) && get(this.safeDropDetails, 'attemptedAddress.combinedAddress', false) && get(this.safeDropDetails, 'attemptedAddress.latitudeValue', false) && get(this.safeDropDetails, 'attemptedAddress.longitudeValue', false);
    }
    /**
     * Returns the help text for map directions
     */
    get helpText() {
        return MAP_DIRECTION_HELPTEXT;
    }
  getStatusImage(eventType) {
    let eventTypeFound;
    false;
    let eventTypeList = [
      "DOM-0034",
      "DOM-0034",
      "INT-0004",
      "INT-0006",
      "INT-0007",
      "INT-0031",
      "INT-0034",
      "INT-0038",
      "INT-0065",
      "INT-2033",
      "INT-2034",
      "INT-2046",
      "INT-2049",
      "INT-2103",
      "INT-2104",
      "INT-2112",
      "INT-2113",
      "INT-2119",
      "INT-2120"
    ];

    for (let i = 0; i < eventTypeList.length; i++) {
      if (eventTypeList[i] === eventType) {
        this.statusIcon = "lock";
      }
    }
  }
  /**
   * @Description: This method is called from 'google map' hyperlink on event message related list .
   *               It will display single geolocation in google map
   * 
   */

  geoLocationHandlerForSingleMap(event){
    let eventMessageRecordId = event.target.name;
    console.log('eventMessageRecordId>>>',eventMessageRecordId);
    if(eventMessageRecordId){
      getAddressFromGeoLocationForEventMessage({eventRecordId : eventMessageRecordId})
        .then(result=>{
          if(result){
            let titleVar;
            console.log('resultvalue>>',result);
             if(result.addressValue){
              titleVar = result.addressValue ;
             }else{
              titleVar = 'No exact Street Address received from Google';
             }
            let latitudeVar = result.geoLatitdue ;
            let longitudeVar = result.geoLongitude ; 
            let markers=[];
            let googleMarker={
              location: {
                'Latitude': latitudeVar,
                'Longitude': longitudeVar
            },
             title: titleVar
            };
            markers.push(googleMarker);
            this.mapMarkers = markers;

            this.bShowModal = true;
          }
          
        })
        .catch(error=>{
          console.log('error>>>>>',error);
        })
      
  }
}
  closeModal(){
    this.bShowModal = false; 
  }
  handleSectionToggle(event) {
    const openSections = event.detail.openSections;        
}
}