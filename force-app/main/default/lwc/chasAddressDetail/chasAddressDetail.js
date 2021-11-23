/**
  * @author       : arjun.singh@auspost.com.au
  * @date         : 19/06/2020
  * @description  : Component for transfer to preferred PO for Help & Support Community. It has following features
  *                 1. Display the po locations in a table format
                    2. Display the distance between user and PO location
                    3. Display the business hour details
--------------------------------------- History --------------------------------------------------
23.03.2020    arjun.singh@auspost.com.au    Created
 */
import { LightningElement, api, track} from 'lwc';
import LOCATION_IMAGE from '@salesforce/resourceUrl/ChasIcons';
export default class ChasAddressDetail extends LightningElement {
    @api locationDetails;
    //Called after the component finishes inserting to DOM
    //@track searchingFlag= true;
    @track iconName="utility:chevrondown";
    @track showListOfHrs = false;
    @api showkilometres;
    locationPinImgage = LOCATION_IMAGE + '/chas-icons/svgs/UI/icons/locationImage.svg';

   /**
    * @Description : This method used to expand/collapse the business hours details.
    */ 
    toggleHander(event){
        let indexVar = event.target.value ;
        if(event.target.iconName === 'utility:chevrondown'){
            event.target.iconName = 'utility:chevronup' ;
            this.showListOfHrs = true;

        }else if(event.target.iconName === 'utility:chevronup'){
            event.target.iconName = 'utility:chevrondown' ;
            this.showListOfHrs = false;
        } 
        let dataToSend = {
            index : indexVar,
            showListOfHrs : this.showListOfHrs
        }
        this.dispatchEvent(
            new CustomEvent("expandworkinghr", {
              detail: dataToSend
            })
        );
        
    }
    SelectHandler(event){
        let addressVar = event.target.value;
        this.dispatchEvent(
            new CustomEvent("selectedlocation", {
              detail: addressVar
            })
        );
    }
    SelectHandlerMobile(event){
        let addressVar = event.target.value;
        this.dispatchEvent(
            new CustomEvent("selectedlocation", {
              detail: addressVar
            })
        );
    }
    
}