/**
  * @author       : arjun.singh@auspost.com.au
  * @date         : 19/06/2020
  * @description  : Component for transfer to preferred PO for Help & Support Community. It has following features
  *                 1. Search feature by postcode to get the near by PO locations return from a service
  *                 2. Display the list of PO location in a table format.
  *                 3. Display the distance between user and PO location
  *                 4. Display the business hour details
--------------------------------------- History --------------------------------------------------
23.03.2020    arjun.singh@auspost.com.au    Created
 */
import { LightningElement, track } from 'lwc';
import getNearByPostOfficeAddress from "@salesforce/apex/ChasPreferredLocationController.getNearByPostOfficeAddress"; 
import json2 from '@salesforce/resourceUrl/json2';
const pageNumber = 1;
const recordsPerPage = '3';
export default class ChasPreferredLocation extends LightningElement {
    @track bShowModal = false;
    @track enteredPostCode;
    @track addressData;
    @track showAddress = false;
    @track showPagination; //Show/hide pagination; valid values are true/false
    @track totalRecords; //Total no.of records; valid type is Integer
    @track records; //All records available in the data table; valid type is Array 
    @track pageSize = 3; //No.of records to be displayed per page
    @track totalPages; //Total no.of pages
    @track pageNumber = pageNumber; //Page number
    @track controlPagination = 'showIt';
    @track controlPrevious = 'hideIt'; //Controls the visibility of Previous page button
    @track controlNext = 'showIt'; //Controls the visibility of Next page button
    @track pageSizeOptions = recordsPerPage;
    @track recordsToDisplay ; //Records to be displayed on the page
    @track disablePrevButton;
    @track disableNextButton;
    @track userCurrentlocation;
    @track businessHours;
    @track postOfficeStatus;
    @track addressWithBusinessHours={};
    @track addressListWithBusinessHours=[];
    @track searchingFlag=false;
    @track startSequence= 1;
    @track endsequence = 3;
    @track increaseCounter =3 ;
    @track decreaseCounter =0 ;
    @track showSelectedPostOffice = false;
    @track selectedPostOffice;
    @track noResultFound = false;
    @track noResultMsg;
    @track showKmAway = true;
    @track shareLocation = '';
    
    connectedCallback() {
        if(this.addressData){
            this.totalRecords = this.addressData.size();
            this.records = this.addressData;            
            this.controlPagination = this.showPagination === false ? 'hideIt' : 'showIt';
            this.setRecordsToDisplay();
        }
    }
    /**
     * @description: Inner method to call the Server class "ChasPreferredLocationController.getNearByPostOfficeAddress".
     *               Server method calls the service to get all the near by PO locations. This method passes the user current location
     *               to calculate the distance between user and return PO address.    
     * @param: usrCurrentlocation 
     */
    async searchPostOffice(usrCurrentlocation) {
        // resetting the pagination controls, start of the call
        this.startSequence = 1;
        this.endsequence = 3;
        this.pageNumber = 1;
        let result = await getNearByPostOfficeAddress({postCodeVar:this.enteredPostCode, currentLocation:JSON.stringify(usrCurrentlocation)});
        if(result && result[0].postOfficeAvailable){
            this.addressData =  result;
            // Sorting method is used the sort the PO address in asending order of return PO address distance with logged in user location.
            this.sortData('distanceBetweenLocation', 'asc');
            // Below method is used to get the business hours details corresponding to each return PO address.
            this.hoursInformation(this.addressData);
            this.showAddress =  true;
            this.totalRecords = this.addressData.length;
            this.records =  this.addressListWithBusinessHours;
            this.noResultFound = false;
            this.noResultMsg = '';
            this.setRecordsToDisplay();
        }else{
            this.showAddress =  false;
            this.searchingFlag = false;
            this.noResultFound = true;
            this.noResultMsg = 'No Post Offices found near your location.';
        }
        
    }
    /**
   * Used to implement the sorting feature on datatable
   */
  sortData(fieldName, sortDirection) {
    // var data = JSON.parse(JSON.stringify(this.recordsToDisplay));
    let  data = [];    
    data = JSON.parse(JSON.stringify(this.addressData));
    //function to return the value stored in the field
    var key = (a) => a[fieldName];
    var reverse = sortDirection === "asc" ? 1 : -1;
    data.sort((a, b) => {
      let valueA = key(a) ? key(a) : "";
      let valueB = key(b) ? key(b) : "";
      return reverse * ((valueA > valueB) - (valueB > valueA));
    });
    
    this.addressData = data;
  }
  /**
   * @Description : Used to get the Business hours details for each PO Address.It passes the list of PO address
   *                returned from Server . 
   * @param {list of returned PO addresses } result 
   */
    hoursInformation(result){
        this.addressListWithBusinessHours = [];
        for (let i = 0; i < result.length; i++) {
            this.hoursInformationForEachLocation(result[i]);
        }

    }
    returnWeekDay(weekday){
        let dayName;
        if(weekday == 0){
            dayName = 'Monday';
        } else if(weekday == 1){
            dayName = 'Tuesday';
        }else if(weekday == 2){
            dayName = 'Wednesday';
        }else if(weekday == 3){
            dayName = 'Thursday';
        }else if(weekday == 4){
            dayName = 'Friday';
        }else if(weekday == 5){
            dayName = 'Saturday';
        }else if(weekday == 6){
            dayName = 'Sunday';
        }
        return dayName ;
    }
    /**
     * @Description : Inner method to get the business hours details for each PO location.
     *                It convert the business hours details return from service into a dynamic 
     *                list starting from current date when user searches the POST for transfer.
     * */
    hoursInformationForEachLocation(location){
        let currentdate = new Date();
        let hoursList = location.hoursDetailsList;
        let hoursMap= new Map();
        let hrsList ;
        let orderedHrsList = [];
        let todalNumberOfDay = 0;
        this.businessHours = {};
        this.addressWithBusinessHours = {};
        this.postOfficeStatus = '';
        //Store the return list of business hours details in a Map with key as weekday( like 0,1,2..)
        for (let i = 0; i < hoursList.length; i++) {
            hoursMap.set(hoursList[i].weekday, hoursList[i]);
        }
        if(hoursMap){
            todalNumberOfDay = hoursMap.size;
        }
        // get the current day when user is in process of triggering the PO transfer request.
        let currentDay = currentdate.getDay();
        // Conversion required because service return the weekday starting with Monday as 0, 
        //but javascript take Sunday as 0.
        if(currentDay == 0){
            currentDay = 6;
        }else{
            currentDay = currentDay - 1;
        }
        let currentDayStr = currentDay.toString();
        // Store the current day business hour details as first element of the list because it will be the first 
        // element displayed in UI . So this will be dynamic based on the day when user triggers the PO transfer request.
        if(hoursMap.has(currentDayStr)){
            let currenthrs = {};
            currenthrs = hoursMap.get(currentDayStr);
            orderedHrsList.push(currenthrs);
            this.businessHourDetails(currenthrs);
        }
        // Once the current day business hours details is stored then below code 
        // stors rest in increasing sequence till the last business day return from the service.
        let nextDay = currentDay + 1;
        let nextDayStr = nextDay.toString();
        while(nextDay <= todalNumberOfDay){
            if(hoursMap.has(nextDayStr)){
                orderedHrsList.push(hoursMap.get(nextDayStr));
            }
            nextDay++;
            nextDayStr =  nextDay.toString();
        }
        if(currentDay > 0){
            let k = 0;
            while(k < currentDay){
                let kString = k.toString();
                if(hoursMap.has(kString)){
                    orderedHrsList.push(hoursMap.get(kString));
                }
                k++;
            }
        }
        // Below loop is used to stored the remaning business day details starting from Monday to current day.
        for (let i = 0; i < orderedHrsList.length; i++) {
            let dayNameVar = this.returnWeekDay(orderedHrsList[i].weekday);
            orderedHrsList[i].weekday = dayNameVar;
        }
        /* Construct the JSON string which has 
          1.location: PO Address
          2. businessHours : business hours in a list starting from current day to maximum then from Monday to current day
          3. postOfficeStatus : It will have value as Open now or closed now, based on the current time falls between business hours.
          4. currentBusinessHours : business hour details for current day
          5. showBusinessHoursForWeek : A boolean flag with value as true or false based on the business hours details is returned from the service or not.
        */        
        this.addressWithBusinessHours = {
            'location' : location,
             'businessHours' : orderedHrsList,
             'postOfficeStatus': this.postOfficeStatus,
             'currentBusinessHours':this.businessHours,
             'showBusinessHoursForWeek': false
        }
        this.addressListWithBusinessHours.push(this.addressWithBusinessHours);
    }
    /**
     * @description : This method calculate whether the PO is Open or closed at the time
     *                user initiated the PO transfer request.
     */
    businessHourDetails(currenthrs){
        let startTime = currenthrs.startTime;
        let endTime = currenthrs.endTime;
        this.businessHours = {};
        let startTimeVar = this.formatTime(startTime);
        let endTimeVar = this.formatTime(endTime);
        let currentDate = new Date();
        if((currentDate > startTimeVar) && (currentDate < endTimeVar)){
            this.postOfficeStatus = 'Open now';
        }else{
            this.postOfficeStatus = 'Closed now';
        }
        this.businessHours = startTime + ' - ' + endTime ;

    }
    /**
     *@description : Returns the current time format using date/time function.
     */
    formatTime(timeVar){
        let timevalue = [];
        let setTime = new Date();
        if(timeVar){
            timevalue = timeVar.split(':');
            let hrVar = parseInt(timevalue[0]);
            let minVar = timevalue[1];
            if(minVar.indexOf('am') > 0){
                minVar = minVar.replace('am','');
                minVar =  minVar.trim();
            }else if(minVar.indexOf('pm') > 0){
                minVar = minVar.replace('pm','');
                minVar =  minVar.trim(); 
                hrVar = hrVar + 12;
            } 
            setTime.setHours(hrVar, parseInt(minVar), 0);
        }
        return setTime;
    }
    /**
     * @description : Used for searching available post office location
     *                based on the post code entered by the user in the form.
     *                It fetched the near by post offices location using a service.
     *                Service is called irrespective of the user sharing the location or not.
     *                This service is called even if the user doesnt allow to share the current location, this is achieved in the error handler part
     */
     searchHandler(){
        this.searchingFlag = true;
        this.recordsToDisplay = [];
       
        // call async method if the user allows to share geolocation, goes into error when it is blocked
        if (navigator.geolocation) {
            
            navigator.geolocation.getCurrentPosition(position => {
                let latitueVar = position.coords.latitude;
                let longitudeVar = position.coords.longitude;
                let usrCurrentlocation = {
                    latitudeStr : latitueVar,
                    longitudeStr : longitudeVar
                };
                this.searchPostOffice(usrCurrentlocation);
            },err => {
                let latitueVar = 0;
                let longitudeVar = 0;
                let usrCurrentlocation = {
                latitudeStr : latitueVar,
                longitudeStr : longitudeVar
                };
            this.showKmAway = false;
            this.searchPostOffice(usrCurrentlocation);
            });
          } 
        else {
            console.log('Geolocation is not supported by this browser.');
          }
    }
    
    /**
     * Description : take the post code provided by the user for near by available PO location search
     */
    handleInputValueChange(event){
        this.enteredPostCode = event.target.value;
    }
    openModal(){
        this.bShowModal = true;
        
    }
    closeModal(){
        this.bShowModal = false;
        if(this.selectedPostOffice){
            this.showSelectedPostOffice = true;
        }
    }
    /**
     * @Description : This method is called to expand/collapse the business hours details 
     *                for selected/clicked down/up arrow for each PO location displayed in the screen  
     */
    expandworkinghrhandler(event){
        let detailVar = event.detail;
        if(detailVar.showListOfHrs){
            let calculatedIndex = (this.pageSizeOptions * (this.pageNumber - 1)) + detailVar.index ;
            this.records[calculatedIndex].showBusinessHoursForWeek =  true;
        }else{
            let calculatedIndex = (this.pageSizeOptions * (this.pageNumber - 1)) + detailVar.index ;
            this.records[calculatedIndex].showBusinessHoursForWeek =  false;
        }
        this.setRecordsToDisplay();
    }
    /**
     * @Description : calls when user select one of the PO location for PO transfer request. 
     */
    selectedlocationHandler(event){
        let value = event.detail;
        this.bShowModal = false;
        this.showSelectedPostOffice = true;
        this.selectedPostOffice = value;
        // dispatch an event to inform the parent component with selected PO location
       this.dispatchEvent(
            new CustomEvent("selectedpostoffice", {
              detail: {value}
            })
        );
    }
    /**
     * @Description : calls when user wants to change the selected PO location and wants to select the differnt PO location
     */
    changelocationhandler(){
        this.bShowModal = true;
        this.showSelectedPostOffice = false;
        this.recordsToDisplay=[];
        this.showAddress= false;
    }
    previousPage(){
        this.pageNumber = this.pageNumber-1;
        if (this.pageNumber == this.totalPages -1 && this.totalRecords % this.increaseCounter > 0)
        {
            this.decreaseCounter = this.totalRecords % this.increaseCounter;
            this.startSequence =this.startSequence  - this.increaseCounter;
            this.endsequence =this.endsequence  - this.decreaseCounter; 
        } else{
            this.startSequence =this.startSequence  - this.increaseCounter;
            this.endsequence =this.endsequence  - this.increaseCounter; 
        }
        this.setRecordsToDisplay();
    }
    nextPage(){
        this.pageNumber = this.pageNumber+1;
        this.startSequence =this.startSequence  + this.increaseCounter;
        if((this.endsequence  + this.increaseCounter) <= this.totalRecords){    
            this.endsequence = this.endsequence  + this.increaseCounter; 
        }else{
            this.endsequence = this.totalRecords; 
        }
        this.setRecordsToDisplay();
    }
    setRecordsToDisplay(){
        this.recordsToDisplay = [];
        if(!this.pageSize)
            this.pageSize = this.totalRecords;

        this.totalPages = Math.ceil(this.totalRecords/this.pageSize);
        this.setPaginationControls();
        for(let i=(this.pageNumber-1)*this.pageSize; i < this.pageNumber*this.pageSize; i++){
            if(i === this.totalRecords) break;
            this.recordsToDisplay.push(this.records[i]);
        }
        this.searchingFlag = false;
    }
    setPaginationControls(){
        //Control Pre/Next buttons visibility by Total pages
        if(this.totalPages === 1){
            this.controlPrevious = 'hideIt';
            this.controlNext = 'hideIt';
        }else if(this.totalPages > 1){
           this.controlPrevious = 'showIt';
           this.controlNext = 'showIt';
        }
        //Control Pre/Next buttons visibility by Page number
        if(this.pageNumber <= 1){
            this.pageNumber = 1;
            this.controlPrevious = 'hideIt';
        }else if(this.pageNumber >= this.totalPages){
            this.pageNumber = this.totalPages;
            this.controlNext = 'hideIt';
        }
        //Control Pre/Next buttons visibility by Pagination visibility
        if(this.controlPagination === 'hideIt'){
            this.controlPrevious = 'hideIt';
            this.controlNext = 'hideIt';
        }
        if(this.controlPrevious === 'hideIt'){
            this.disablePrevButton = true;
        }else{
            this.disablePrevButton = false;
        }
        if(this.controlNext === 'hideIt'){
            this.disableNextButton = true;
        }else{
            this.disableNextButton = false;
        }
    }
/**
     * @Description : close modal window when escape key is pressed
     */
    handleKeyPress({code}) {

        if ('Escape' === code) {
            //this.template.querySelector('c-modal').hide();
            console.log('i am in close');
            this.bShowModal = false;
            if(this.selectedPostOffice){
                this.showSelectedPostOffice = true;
            }
        }
    }
}