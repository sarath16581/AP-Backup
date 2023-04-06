/**
  * @author       : arjun.singh@auspost.com.au
  * @date         : 19/06/2020
  * @description  : Component used for PO tansfer request. It display
  *                 the selected po location deatils 
--------------------------------------- History --------------------------------------------------
23.03.2020    arjun.singh@auspost.com.au    Created
 */
import { LightningElement, api,track } from 'lwc';
import LOCATION_IMAGE from '@salesforce/resourceUrl/ChasIcons'; 
export default class ChasSelectedPostOfficeAddress extends LightningElement {
    @api office;
    locationPinImgage = LOCATION_IMAGE + '/chas-icons/svgs/UI/icons/locationImage.svg';
    @track iconName="utility:chevrondown";
    @track showListOfHrs = false;

    toggleHander(event){
        if(event.target.iconName === 'utility:chevrondown'){
            event.target.iconName = 'utility:chevronup' ;
            this.showListOfHrs = true;
        }else if(event.target.iconName === 'utility:chevronup'){
            event.target.iconName = 'utility:chevrondown' ;
            this.showListOfHrs = false;
        }
    }
}