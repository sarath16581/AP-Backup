/**
  * @author       : arjun.singh@auspost.com.au
  * @date         : 23/03/2020
  * @description  : Component JS to support landing page of myNetwork Community
--------------------------------------- History --------------------------------------------------
23.03.2020    arjun.singh@auspost.com.au    Created
12.05.2020    Hara Sahoo                   Added JS function for handleClick(event) and getSelectedRows(event)
26.10.2020    Swati.Mogadala@auspost.com.au REQ2289157 handleClick(evt) modified to check if any records are records selected for printing
30.10.2020    Swati.Mogadala@auspost.com.au REQ2329468 Error message fixed - 'Please select case(s) for printing'
08.09.2022    Naveen Rajanna - REQ2963906: domain check to populate prefix myNetwork if required
01.11.2022    Dattaraj Deshmukh - Updated to show case investigations for StarTrack cases. 
31.01.2023	  Dattaraj Deshmukh - Updated to show number of case numbers.
*/
/* eslint-disable default-case */
/* eslint-disable no-console */
import { LightningElement, track } from "lwc";
import myNetworkCases from "@salesforce/apex/MyNetworkCaseListController.myNetworkCases";
import getFilteredCases from "@salesforce/apex/MyNetworkCaseListController.getFilteredCases";
import assignSelectedRecords from "@salesforce/apex/MyNetworkCaseListController.assignSelectedRecords";

import { NavigationMixin } from "lightning/navigation";
/*import compensationAndPostageValue from 'c/compensationAndPostageValue';*/
import { loadStyle } from "lightning/platformResourceLoader";
import customStyle from "@salesforce/resourceUrl/MYNetworkCustomStyle";
const DELAY = 300;
const recordsPerPage = [100, 50, 25, 10, 1];
const pageNumber = 1;
const showIt = "visibility:visible";
const hideIt = "visibility:hidden"; //visibility keeps the component space, but display:none doesn't

/* Custom list of columns used to display the cases in MyNetowrk Home page view.
 */
const columns = [
  {
    label: "Case Number",
    fieldName: "caseLink",
    type: "url",
    typeAttributes: {
      label: { fieldName: "caseNum" },
      tooltip: "Go to detail page",
      target: "_self",
      variant: "base",
    },
    cellAttributes: { class: { fieldName: "caseNumberCSSClass" } },
    initialWidth: 120,
    wrapText: true,
  },
  {
    label: "Printed",
    fieldName: "Case_Print",
    type: "text",
    initialWidth: 100,
    wrapText: true,
  },
  {
    label: "Details",
    fieldName: "Case_Details",
    type: "text",
    cellAttributes: { class: { fieldName: "detailCSSClass" } },
    initialWidth: 100,
    wrapText: true,
  },
  {
    label: "Escalation",
    fieldName: "Case_Escalation",
    type: "text",
    cellAttributes: {
      class: { fieldName: "dotCSSClass" },
      iconName: {
        fieldName: "displayIconName",
      },
    },
    initialWidth: 100,
    wrapText: true,
  },
  
  {
    label: "Priority",
    fieldName: "Case_Priority",
    sortable: true,
    initialWidth: 100,
    wrapText: true,
  },
  {
    label: "Sent To Network Date",
    fieldName: "Case_sentToNetworkDate",
    type: "date",
    typeAttributes: {
      day: "numeric",
      month: "short",
      year: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    },
    sortable: true,
    initialWidth: 150,
    wrapText: true,
  },
  {
    label: "Reference ID",
    fieldName: "Case_RefereceId",
    type: "text",
    initialWidth: 200,
    wrapText: true,
  },
  {
    label: "Customer Type",
    fieldName: "Case_CustomerType",
    type: "text",
    initialWidth: 120,
    wrapText: true,
  },
  {
    label: "Enquiry Subtype",
    fieldName: "Case_enquirySubtype",
    type: "text",
    initialWidth: 150,
    wrapText: true,
  },
  {
    label: "Addressee Address",
    fieldName: "Case_addresseeAddress",
    type: "text",
    initialWidth: 150,
    wrapText: true,
  },
  {
    label: "Addressee Postcode",
    fieldName: "Case_addresseePostcode",
    type: "text",
    initialWidth: 120,
    wrapText: true,
  },
  {
    label: "Network Name",
    fieldName: "Case_networkName",
    type: "text",
    initialWidth: 150,
    wrapText: true,
  },
  {
    label: "Assigned To",
    fieldName: "Case_assignedTo",
    type: "text",
    initialWidth: 150,
    wrapText: true,
  },
];

export default class CaseList extends NavigationMixin(LightningElement) {
  @track error;
  @track columns = columns;
  @track cases; //All Cases available for data table
  @track showTable = false; //Used to render table after we get the data from apex controller
  @track recordsToDisplay = []; //Records to be displayed on the page
  @track rowNumberOffset; //Row number
  @track selectedListViewApiName = "All_Cases";
  @track caseRecord;
  @track showCaseRecordDetails = false;
  @track totalNumberOfCases = 0;
  @track onloadflag;
  @track totalNumberOfFilteredCases = 0;
  @track cachedIsPrinted = false;
  @track cachedIsEscalated = false;
  @track searchingFlag;
  @track sortedBy;
  @track sortedDirection = "desc";
  @track noCasesFoundflag = false;
  @track noCasesFoundMsg = "";
  @track loadLandingPage = true;

  @track showSearchBox = false; //Show/hide search box; valid values are true/false
  @track showPagination; //Show/hide pagination; valid values are true/false
  @track pageSizeOptions = recordsPerPage; //Page size options; valid values are array of integers
  @track totalRecords; //Total no.of records; valid type is Integer
  @track records; //All records available in the data table; valid type is Array
  @track pageSize; //No.of records to be displayed per page
  @track totalPages; //Total no.of pages
  @track pageNumber = pageNumber; //Page number
  @track searchKey; //Search Input
  @track controlPagination = showIt;
  @track controlPrevious = hideIt; //Controls the visibility of Previous page button
  @track controlNext = showIt; //Controls the visibility of Next page button
  @track totalNumberOfCasesVar;
  @track totalNumberOfFilteredCasesVar;
  @track defaultNumber = "100";
  @track assignToSelfErrMsg;
  @track assignToSelfHasErr;
  @track bShowModal = false;
  @track loadLandingPageErrMsg;
  @track sortedRecords = [];
  @track selectedRecords = [];
  @track casesRecords = [];

  sfdcBaseURL;
  constructor() {
    super();
    this.searchingFlag = true;
  }
  connectedCallback() {
    this.onloadflag = true;
    this.loadLandingPageErrMsg = '';
    this.assignToSelfHasErr = false;
    this.assignToSelfErrMsg = '';
	this.sfdcBaseURL = window.location.origin;

    Promise.all([
      loadStyle(this, customStyle + "/MYNetworkCustomStyle.css"),
    ]).catch((error) => {
      console.log("error in loading the style>>", error);
    });
    /* Call myNetworkCases apex method to get the cases related to default case view
     * which is 'All_Cases'. This method is called when users log in to mynetwork commununity.
     * Also when they came back to landing page from case detail page.
     */

    myNetworkCases({ selectedViewString: this.selectedListViewApiName })
      .then((result) => {
        if (result) {
          //this.totalNumberOfCases = result.length;
          this.getcaseDataPopulation(result);
          this.showCaseRecordDetails = false;
          if (this.pageSizeOptions && this.pageSizeOptions.length > 0)
            this.pageSize = this.pageSizeOptions[0];
          else {
            this.pageSize = this.totalRecords;
            this.showPagination = false;
          }
          this.controlPagination =
            this.showPagination === false ? hideIt : showIt;
          this.setRecordsToDisplay();
          this.showSearchBox = true;
        }
      })
      .catch((error) => {
        this.error = error;
        console.log("error>", this.error);
        this.loadLandingPage = false;
        this.searchingFlag = false;
        this.loadLandingPageErrMsg='There is a problem with the case search. Please contact your System Administrator'
      });
  }

  /**
   * 
   * @param caseData: Method populates case details for common fields for AP and ST (StarTrack) cases. 
   */
  populateCaseData(caseRecord, data, i){
      caseRecord.Case_Print = data[i].myNetworkCase.Checkbox__c ? "Yes" : "No";
      caseRecord.Case_Details = data[i].caseIcon;
      caseRecord.detailCSSClass = data[i].caseColor;

      caseRecord.caseNumberCSSClass = "blue";
      if (data[i].myNetworkCase.Facility_Milestones_Violated__c > 1) {
        caseRecord.dotCSSClass = "redcolor";
        caseRecord.displayIconName = "utility:warning";
      }
      caseRecord.Case_CustomerType = data[i].myNetworkCase.Customer_Type__c;
      caseRecord.Case_addresseeAddress = data[i].myNetworkCase.Address2__c;
      caseRecord.Case_addresseePostcode =
      data[i].myNetworkCase.Address2Postcode__c;
      if (data[i].myNetworkCase.Network__r != null) {
        caseRecord.Case_networkName = data[i].myNetworkCase.Network__r.Name;
      }
      if (data[i].myNetworkCase.PONUser__r != null) {
        caseRecord.Case_assignedTo = data[i].myNetworkCase.PONUser__r.Name;
      }
      caseRecord = Object.assign(caseRecord, data[i]);
  }

  /* Method take the cases return from apex method as input parameter and return the list of case wrapper
   *  used to display the case list view on MyNetwork landing page.
   */
  getcaseDataPopulation(data) {
    let caseRecordList = [];
    this.cases = [];
    this.loadLandingPageErrMsg = '';
    this.assignToSelfHasErr = false;
    this.assignToSelfErrMsg = '';
    for (let i = 0; i < data.length; i++) {
      let caseRecord = {};
      
     
      //check if case investigations exists under a case. For all ST Cases, investigations exists under a case.
      if(data[i].myNetworkCase.hasOwnProperty('CaseInvestigations__r') && data[i].myNetworkCase.CaseInvestigations__r) {
        
        

        let cInvestigations = data[i].myNetworkCase.CaseInvestigations__r;
		console.log('data[i] :');console.log(data[i]);
        // for(let cInvestigationCnt = 0; cInvestigationCnt < cInvestigations.length; cInvestigationCnt++) {
          
		// 	caseRecord.rowNumber = (i + cInvestigationCnt) ;

		//   	//setting Case.Type for wrapper variable for ST cases.
		//   	caseRecord.Case_enquirySubtype = data[i].myNetworkCase.Type;
	
		// 	//populate common fields between case investigation and case object.
		// 	this.populateCaseData(caseRecord, data, i);

		// 	//setting caseInvestigations to blank
		// 	caseRecord.caseInvestigation = '';
		// 	caseRecord.caseInvestigation = cInvestigations[cInvestigationCnt].Name;
		// 	caseRecord.Case_sentToNetworkDate = cInvestigations[cInvestigationCnt].CreatedDate;
		// 	caseRecord.Case_RefereceId = cInvestigations[cInvestigationCnt].Article__r ? cInvestigations[cInvestigationCnt].Article__r.Name : '';
		// 	caseRecord.caseInvestigationId = cInvestigations[cInvestigationCnt].Id;

		// 	//As case and case investigation need to be shown under one column,
		// 	//caseNum is populated with case number and Case Investigation Number.

		// 	caseRecord.caseLink = (this.sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") + "/caseinvestigation/" +cInvestigations[cInvestigationCnt].Id;
		// 	//caseRecord.caseLink = (this.sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") + "/case/" + data[i].caseId+'?caseInvestigationRecordId='+cInvestigations[cInvestigationCnt].Id;
		// 	caseRecord.caseNum = (data[i].myNetworkCase.hasOwnProperty('CaseInvestigations__r') && data[i].myNetworkCase.CaseInvestigations__r) ?  (data[i].caseNum + ' - ' +  caseRecord.caseInvestigation) : data[i].caseNum;
		// 	caseRecord.Case_Priority = cInvestigations[cInvestigationCnt].Priority__c;
		// 	caseRecord.casePriority = cInvestigations[cInvestigationCnt].Priority__c;

		// 	let investigationArray = caseRecord.myNetworkCase.CaseInvestigations__r.filter(cInvest => cInvest.Id === caseRecord.caseInvestigationI);
		// 	caseRecord.myNetworkCase.CaseInvestigations__r = investigationArray;
			
		// 	console.log('previouse css: '+caseRecord.Case_Details);
		// 	console.log('previouse css detailCSSClass: '+caseRecord.detailCSSClass);
			

		// 	//setting New/Updated/SUI Flag on case investigation record.
		// 	caseRecord.Case_Details = data[i].updatedCaseInvestigationIds.includes(cInvestigations[cInvestigationCnt].Id) ? 'UPDATED' 
		// 								: data[i].stillUnderCaseInvestigationIds.includes(cInvestigations[cInvestigationCnt].Id) ? 'SUI' 
		// 								: data[i].newCaseInvestigationIds.includes(cInvestigations[cInvestigationCnt].Id)  ? 'NEW' : caseRecord.Case_Details;
		// 	caseRecord.detailCSSClass = data[i].updatedCaseInvestigationIds.indexOf(cInvestigations[cInvestigationCnt].Id) != -1 ? 'Red' 
		// 								: data[i].stillUnderCaseInvestigationIds.indexOf(cInvestigations[cInvestigationCnt].Id) != -1 ? 'Orange' 
		// 								: data[i].newCaseInvestigationIds.indexOf(cInvestigations[cInvestigationCnt].Id) != -1 ? 'green' : caseRecord.detailCSSClass;
			
		// 	console.log('caseRecord.Case_Details: '+caseRecord.Case_Details+' caseRecord.detailCSSClass: '+caseRecord.detailCSSClass);
		// 	console.log(cInvestigations[cInvestigationCnt]);
			
		// 	if(this.selectedListViewApiName === 'Cases_updated') {
		// 		if(data[i].updatedCaseInvestigationIds.indexOf(cInvestigations[cInvestigationCnt].Id) != -1 
		// 			|| data[i].stillUnderCaseInvestigationIds.indexOf(cInvestigations[cInvestigationCnt].Id) != -1
		// 			) {
		// 				caseRecordList.push(caseRecord);
		// 			}
		// 	}
		// 	else {
		// 		caseRecordList.push(caseRecord);
		// 	}
		// 	//create new instance of caseRecord to store next case investigation record wrapper.
		// 	caseRecord = new Object();
        // }
		/** NEW CODE STARTED */
			let cInvestigationRecord =  data[i].caseInvestigation;
			caseRecord.rowNumber = i ;

		  	//setting Case.Type for wrapper variable for ST cases.
		  	caseRecord.Case_enquirySubtype = data[i].myNetworkCase.Type;
		
			//populate common fields between case investigation and case object.
			this.populateCaseData(caseRecord, data, i);

			//setting caseInvestigations to blank
			caseRecord.caseInvestigation = '';
			caseRecord.caseInvestigation = cInvestigationRecord.Name;
			caseRecord.Case_sentToNetworkDate = cInvestigationRecord.CreatedDate;
			caseRecord.Case_RefereceId = cInvestigationRecord.Article__r ? cInvestigationRecord.Article__r.Name : '';
			caseRecord.caseInvestigationId = cInvestigationRecord.Id;

			//As case and case investigation need to be shown under one column,
			//caseNum is populated with case number and Case Investigation Number.

			caseRecord.caseLink = (this.sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") + "/caseinvestigation/" +cInvestigationRecord.Id;
			//caseRecord.caseLink = (this.sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") + "/case/" + data[i].caseId+'?caseInvestigationRecordId='+cInvestigations[cInvestigationCnt].Id;
			caseRecord.caseNum = (data[i].myNetworkCase.hasOwnProperty('CaseInvestigations__r') && data[i].myNetworkCase.CaseInvestigations__r) ?  (data[i].caseNum + ' - ' +  caseRecord.caseInvestigation) : data[i].caseNum;
			caseRecord.Case_Priority = cInvestigationRecord.Priority__c;
			caseRecord.casePriority = cInvestigationRecord.Priority__c;

			let investigationArray = caseRecord.myNetworkCase.CaseInvestigations__r.filter(cInvest => cInvest.Id === caseRecord.caseInvestigationI);
			caseRecord.myNetworkCase.CaseInvestigations__r = investigationArray;
			
			console.log('previouse css: '+caseRecord.Case_Details);
			console.log('previouse css detailCSSClass: '+caseRecord.detailCSSClass);
			

			//setting New/Updated/SUI Flag on case investigation record.
			// caseRecord.Case_Details = data[i].updatedCaseInvestigationIds.includes(cInvestigations[cInvestigationCnt].Id) ? 'UPDATED' 
			// 							: data[i].stillUnderCaseInvestigationIds.includes(cInvestigations[cInvestigationCnt].Id) ? 'SUI' 
			// 							: data[i].newCaseInvestigationIds.includes(cInvestigations[cInvestigationCnt].Id)  ? 'NEW' : caseRecord.Case_Details;
			// caseRecord.detailCSSClass = data[i].updatedCaseInvestigationIds.indexOf(cInvestigations[cInvestigationCnt].Id) != -1 ? 'Red' 
			// 							: data[i].stillUnderCaseInvestigationIds.indexOf(cInvestigations[cInvestigationCnt].Id) != -1 ? 'Orange' 
			// 							: data[i].newCaseInvestigationIds.indexOf(cInvestigations[cInvestigationCnt].Id) != -1 ? 'green' : caseRecord.detailCSSClass;
			
			// 
			console.log('caseRecord.Case_Details: '+caseRecord.Case_Details+' caseRecord.detailCSSClass: '+caseRecord.detailCSSClass);
			console.log(cInvestigationRecord);
			
			// if(this.selectedListViewApiName === 'Cases_updated') {
			// 	if(data[i].updatedCaseInvestigationIds.indexOf(cInvestigationRecord.Id) != -1 
			// 		|| data[i].stillUnderCaseInvestigationIds.indexOf(cInvestigationRecord.Id) != -1 ) {
			// 			caseRecordList.push(caseRecord);
			// 	}
			// }
			// else {
			caseRecordList.push(caseRecord);
			// }
			//create new instance of caseRecord to store next case investigation record wrapper.
			caseRecord = new Object();
        
			/** NEW CODE ENDED */

      }
      else {
        this.populateCaseData(caseRecord, data, i);

			caseRecord.rowNumber = i;
			caseRecord.Case_sentToNetworkDate = data[i].myNetworkCase.Sent_To_Network_Date__c;
			caseRecord.Case_RefereceId = data[i].myNetworkCase.ReferenceID__c;
			caseRecord.Case_enquirySubtype = data[i].isStarTrackCase ? data[i].myNetworkCase.Type : data[i].myNetworkCase.EnquirySubType__c;
			caseRecord.caseNumberCSSClass = "blue";
			caseRecord.caseLink = (this.sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") + "/case/" + data[i].caseId;
			caseRecord.caseNum = data[i].caseNum;
			caseRecord.Case_Priority = data[i].myNetworkCase.Priority;
			caseRecord.casePriority = data[i].casePriority;


			caseRecordList.push(caseRecord);
      }
    }

    this.searchingFlag = false;
    this.cases = caseRecordList;
    this.records = caseRecordList;
    this.totalRecords = caseRecordList.length;
    this.recordsToDisplay = this.cases;
    //Sorting Feature
    //this.sortData('Case_Priority','asc');
    this.customSortingWithMultipleColumn();
    this.showTable = true;
    this.noCasesFoundflag = false;
    if (this.cases.length === 0) {
      this.noCasesFoundflag = true;
      this.noCasesFoundMsg = "No Case Result Found";
      this.showTable = false;
    }
    this.totalNumberOfFilteredCases = this.cases.length;//this.cases.length;

	

	//calculate total number of cases only when List view is set to 'All_Cases'.
	if(this.selectedListViewApiName === 'All_Cases') {
		this.totalNumberOfCases = (this.totalNumberOfCases ||  this.totalNumberOfCases === 0) ? this.cases.length : this.totalNumberOfCases;
	}

	console.log('this.selectedListViewApiName: '+this.selectedListViewApiName);
	console.log('this.totalNumberOfCases: '+this.totalNumberOfCases);
    this.loadLandingPage = false;
  }
  /* This method is handler of event fired from when the case list view is changed.It takes the selected
   *  list view as input and call the apex method myNetworkCases. Interally again it calls getCaseDataPopulation
   *  method to generate the case wrapper used to display the case list view on myNetowrk landing page
   */
  listViewChangeHandler(event) {
    this.selectedListViewApiName = event.detail;
    this.cases = [];
    this.showTable = false;
    this.searchingFlag = true;
    myNetworkCases({ selectedViewString: this.selectedListViewApiName })
      .then((result) => {
        if (result) {
          this.getcaseDataPopulation(result);
          this.showCaseRecordDetails = false;
        }
      })
      .catch((error) => {
        this.error = error;
        console.log("error>", this.error);
        this.loadLandingPage = false;
        this.searchingFlag = false;
        this.loadLandingPageErrMsg='There is a problem with the case search. Please contact your System Administrator';
      });
  }
  /**
   * Handler for serachfieldschange event and it will be called on the click of Search button.
   * The input parameter is a json string which contains all the data related to filter/liswview.
   * It will call getFilteredCases apex method and will get the case result as a part of dynamic SOQL.
   * On the successful case result, a second method getCaseDataPopulation will be called to generate the
   * Case wrapper used to display the case result.
   */
  async searchfieldschangeHandler(event) {
    this.searchingFlag = true;
    let eventData = event.detail;
    this.showTable = false;
	//assigning selected list view.
	if(eventData){
		this.selectedListViewApiName = JSON.parse(event.detail).selectedlistview;
	}
    let result = await getFilteredCases({ filteredString: event.detail });
    if (result) {
      this.searchingFlag = false;
      this.getcaseDataPopulation(result);
      this.showCaseRecordDetails = false;
    } else {
      this.searchingFlag = false;
      this.loadLandingPage = false;
      this.loadLandingPageErrMsg='There is a problem with the case search. Please contact your System Administrator';
    }
  }
  /**
   * Thie method is called on the click on caseNumber hyperlink and will take
   * user to case detail page.
   */
  handleRowAction(event) {
    console.log(JSON.stringify(event.detail.action));
    if (event.detail.action.name === "Edit") {
      let caseIdVar = event.detail.row.myNetworkCase.Id;
      // Navigate to a URL
      this[NavigationMixin.Navigate](
        {
          type: "standard__webPage",
          attributes: {
            url: "/casedetail/" + caseIdVar,
          },
        },
        true // Replaces the current page in your browser history with the URL
      );
    }
  }
  /**
   * This method is called on the click of assign to self button and internally it will update case assigned to
   * fied with logged in user.
   */
  
  /**
   * Used to implement the sorting feature on datatable
   */
  updateColumnSorting(event) {
    this.sortedBy = event.detail.fieldName;
    this.sortedDirection = event.detail.sortDirection;
    this.sortData(this.sortedBy, this.sortedDirection);
  }
  /**
   * Used to implement the sorting feature on datatable
   */
  sortData(fieldName, sortDirection) {
    // var data = JSON.parse(JSON.stringify(this.recordsToDisplay));
    let  data = [];
    if(fieldName === 'Case_Priority'){
      fieldName = 'casePriority';
    }
     data = JSON.parse(JSON.stringify(this.cases));
    //function to return the value stored in the field
    var key = (a) => a[fieldName];
    var reverse = sortDirection === "asc" ? 1 : -1;
    data.sort((a, b) => {
      let valueA = key(a) ? key(a).toLowerCase() : "";
      let valueB = key(b) ? key(b).toLowerCase() : "";
      return reverse * ((valueA > valueB) - (valueB > valueA));
    });
    
    //set sorted data to opportunities attribute
    //this.recordsToDisplay = data;
    this.records = data;
    this.totalRecords = data.length;
    this.setRecordsToDisplay();
  }
    
  /**
   * Custom Sorting using case priority and sent to network date field.
   */
  customSortingWithMultipleColumn(){
    let caseList = this.records;
    let caseMap= new Map();
    let caseSortedMap = new Map();
    let finalSortedCaseList = [];
    let caseVar ;
    let caserecordListVar ;
    let caseRec;
      for (let i = 0; i < caseList.length; i++) {
        if(caseMap.has(caseList[i].Case_Priority)){
            caseVar = {};
            caserecordListVar = [];
            caseRec = {};
            caseVar = caseList[i];
            caserecordListVar = caseMap.get(caseList[i].Case_Priority);
            caseRec = Object.assign(caseRec, caseVar);
            caserecordListVar.push(caseRec);
            caseMap.set(caseList[i].Case_Priority, caserecordListVar);
        }else{
          let caseVariable = caseList[i];
          caserecordListVar = [];
          let carVarData = {};
          carVarData = Object.assign(carVarData, caseVariable);
          caserecordListVar.push(carVarData);
          caseMap.set(caseList[i].Case_Priority, caserecordListVar);
        }
      }
      for (let key of caseMap.keys()) {
        let casesForEachPriority = caseMap.get(key);
        this.customSortingOnSingleColumn(casesForEachPriority, 'Case_sentToNetworkDate', 'asc');
        caseSortedMap.set(key, this.sortedRecords);
      }
      let caseTempList =[];
      for (let key of caseSortedMap.keys()) {
        caseTempList = caseSortedMap.get(key);
        for (let i = 0; i < caseTempList.length; i++) {
          let cVar = caseTempList[i];
          cVar.rowNumber = i;
          finalSortedCaseList.push(cVar);
        }
      }
    this.records = finalSortedCaseList;
    this.cases = finalSortedCaseList ;
    this.recordsToDisplay = this.finalSortedCaseList;
    this.totalRecords = finalSortedCaseList.length;
    this.setRecordsToDisplay();
  }
  customSortingOnSingleColumn(data, keyValue, sortDirection){ 
    this.sortedRecords = [];
    var key = a => a[keyValue];   
    var reverse = sortDirection === "asc" ? 1 : -1;
    data.sort((a, b) => {
      let valueA = key(a) ? key(a).toLowerCase() : "";
      let valueB = key(b) ? key(b).toLowerCase() : "";
      return reverse * ((valueA > valueB) - (valueB > valueA));
    });
    
    //set sorted data to opportunities attribute
    //this.recordsToDisplay = data;
    this.sortedRecords = data;
    
  }
  handleRecordsPerPage(event) {
    this.pageSize = event.target.value;
    this.setRecordsToDisplay();
  }
  handlePageNumberChange(event) {
    if (event.keyCode === 13) {
      this.pageNumber = event.target.value;
      this.setRecordsToDisplay();
    }
  }
  previousPage() {
    this.pageNumber = this.pageNumber - 1;
    this.setRecordsToDisplay();
  }
  nextPage() {
    this.pageNumber = this.pageNumber + 1;
    this.setRecordsToDisplay();
  }
  setRecordsToDisplay() {
    this.recordsToDisplay = [];
    if (!this.pageSize) this.pageSize = this.totalRecords;
    this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
    this.setPaginationControls();
    for (
      let i = (this.pageNumber - 1) * this.pageSize;
      i < this.pageNumber * this.pageSize;
      i++
    ) {
      if (i === this.totalRecords) break;
      this.records[i].rowNumber = i;
      this.recordsToDisplay.push(this.records[i]);
      
    }
    //this.dispatchEvent(new CustomEvent('paginatorchange', {detail: this.recordsToDisplay})); //Send records to display on table to the parent component
    //this.recordsToDisplay = event.detail;
    /*if (this.recordsToDisplay[0] != null) {
      this.rowNumberOffset = this.recordsToDisplay[0].rowNumber - 1;
    } else {
      console.log("No cases found");
    }*/
  }
  setPaginationControls() {
    //Control Pre/Next buttons visibility by Total pages
    if (this.totalPages === 1) {
      this.controlPrevious = hideIt;
      this.controlNext = hideIt;
    } else if (this.totalPages > 1) {
      this.controlPrevious = showIt;
      this.controlNext = showIt;
    }
    //Control Pre/Next buttons visibility by Page number
    if (this.pageNumber <= 1) {
      this.pageNumber = 1;
      this.controlPrevious = hideIt;
    } else if (this.pageNumber >= this.totalPages) {
      this.pageNumber = this.totalPages;
      this.controlNext = hideIt;
    }
    //Control Pre/Next buttons visibility by Pagination visibility
    if (this.controlPagination === hideIt) {
      this.controlPrevious = hideIt;
      this.controlNext = hideIt;
    }
  }
  handleKeyChange(event) {
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value.trim();
    if(searchKey) {
      this.delayTimeout = setTimeout(() => {
        this.controlPagination = hideIt;
        this.setPaginationControls();
        this.searchKey = searchKey.trim();
        //Use other field name here in place of 'Name' field if you want to search by other field
        //this.recordsToDisplay = this.records.filter(rec => rec.includes(searchKey));
        //Search with any column value (Updated as per the feedback)
        this.recordsToDisplay = this.records.filter((rec) =>
          JSON.stringify(rec).includes(searchKey)
        );
        if(Array.isArray(this.recordsToDisplay) && this.recordsToDisplay.length > 0) {
          if(this.recordsToDisplay[0] != null) {
            //this.dispatchEvent(new CustomEvent('paginatorchange', {detail: this.recordsToDisplay})); //Send records to display on table to the parent component
            if(this.rowNumberOffset > 0) {
              this.rowNumberOffset = this.recordsToDisplay[0].rowNumber - 1;
            }else {
              this.rowNumberOffset = 0;
            }
            //this.records= this.recordsToDisplay;
            this.totalRecords = this.recordsToDisplay.length;
            //this.setRecordsToDisplay();
          } else {
            console.log("No cases found");
          }
        }
      }, DELAY);
    } else {
      this.controlPagination = showIt;

      //If searchKey is blank, setting totalRecords to number of records originially list had.
      this.totalRecords = this.records.length;
      this.setRecordsToDisplay();
    }
  }
  
  handleClick(evt) {
    console.log('this.selectedRecords',this.selectedRecords);
	var hostname = window.location.hostname;

    //this.selectedRecords == null modified with length() to get message when no case is selected  
    if(this.selectedRecords.length === 0){
      this.assignToSelfHasErr = true;
      this.assignToSelfErrMsg = 'Please select case(s) for printing'
    }else{
      evt.preventDefault();
      evt.stopPropagation();
      this.VFpage = {
        type: "standard__webPage",
        attributes: {
          url:
            "https://" +
            hostname + (this.sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") +
            "/apex/myNetworkCasePDFGenerator?selectedIds=" +
            encodeURI(this.selectedRecords),
        },
      };
      // Navigate to the Case print VF page.
      this[NavigationMixin.Navigate](this.VFpage);
    }
  }


  // Getting selected rows
  getSelectedRows(event) {
    const selectedRows = event.detail.selectedRows;
    let conIds = new Set();
	let caseInvestigationIds = [];
    // getting selected record id
    for (let i = 0; i < selectedRows.length; i++) {
      conIds.add(selectedRows[i].myNetworkCase.Id);
	  selectedRows[i].hasOwnProperty('caseInvestigationId') ? conIds.add(selectedRows[i].caseInvestigationId) : '';
    }
    // coverting to array
    this.selectedRecords = Array.from(conIds);
	//this.selectedRecords.push(caseInvestigationIds);


  }
  // openModal() {
  //   let selectedRows = this.template
  //     .querySelector("lightning-datatable")
  //     .getSelectedRows();
  //   let selectedCaseId = [];
  //   let selectedCaseRowIdsVar = [];
  //   let caseSelected = false;
  //   let selectedCaseInvestigationId = [];
    
  //   for (let i = 0; i < selectedRows.length; i++) {

  //     //if case is ST case, select case investigation for owner updates
  //     if(selectedRows[i].caseInvestigationId){
  //       selectedCaseInvestigationId.push(selectedRows[i].caseInvestigationId);
  //     }
  //     else{
  //       selectedCaseId.push(selectedRows[i].caseId);
  //     }
  //     selectedCaseRowIdsVar.push(selectedRows[i].rowNumber);
  //     caseSelected = true;
  //   }
  //   if(selectedCaseRowIdsVar.length > 20){
  //     this.assignToSelfErrMsg = 'Please select maximum of 20 cases for assignment';
  //     this.assignToSelfHasErr = true;
  //   } else{
  //     if(caseSelected){
  //       this.selectedCaseIdJson = selectedCaseInvestigationId.length>0 ? JSON.stringify(selectedCaseInvestigationId) : JSON.stringify(selectedCaseId);
  //       this.selectedCaseId = selectedCaseRowIdsVar;
  //       this.bShowModal = true;
  //       this.assignToSelfHasErr = false;
  //     }else{
  //       this.assignToSelfErrMsg = 'Please select case(s) for assignment';
  //       this.assignToSelfHasErr = true;
  //     }
  //   }
  // }

  handleAssignToUser() {
    let selectedRows = this.template
      .querySelector("lightning-datatable")
      .getSelectedRows();
    let selectedCaseId = [];
    let selectedCaseRowIdsVar = [];
    let caseSelected = false;
    let selectedCaseInvestigationId = [];
    
    for (let i = 0; i < selectedRows.length; i++) {

      //if case is ST case, select case investigation for owner updates
      if(selectedRows[i].caseInvestigationId){
        selectedCaseInvestigationId.push(selectedRows[i].caseInvestigationId);
      }
      else{
        selectedCaseId.push(selectedRows[i].caseId);
      }
      selectedCaseRowIdsVar.push(selectedRows[i].rowNumber);
      caseSelected = true;
    }
    if(selectedCaseRowIdsVar.length > 20){
      this.assignToSelfErrMsg = 'Please select maximum of 20 records for assignment';
      this.assignToSelfHasErr = true;
    } else{
      if(caseSelected){
        //merging selectedCaseId and selectedCaseInvestigationId arrays into one and generating JSON string.
        this.selectedRecordIdJson = JSON.stringify(selectedCaseId.concat(selectedCaseInvestigationId));
        this.selectedCaseId = selectedCaseRowIdsVar;
        this.bShowModal = true;
        this.assignToSelfHasErr = false;
      }else{
        this.assignToSelfErrMsg = 'Please select records for assignment';
        this.assignToSelfHasErr = true;
      }
    }
  }

  closemodalpopuphandler() {
    this.bShowModal = false;
  }
  async assignuserHandler(event) {
    this.bShowModal = false;
    this.searchingFlag = true;
    this.showTable = false;
    this.assignToSelfHasErr = false;

    let selecteduserId = event.detail;
   
    let result = await assignSelectedRecords({
      recordIds: this.selectedRecordIdJson,
      selectedUserId: selecteduserId,
      isAssignSelf : false
    });

    if (!result.hasError) {
      for (let i = 0; i < this.selectedCaseId.length; i++) {
        let arryIndex = this.selectedCaseId[i];
        let caseRecord = this.cases[arryIndex];
        caseRecord.Case_assignedTo = result.resultValue;
        this.recordsToDisplay[arryIndex] = caseRecord;
      }
      this.searchingFlag = false;
      this.showTable = true;
    } else {
      this.searchingFlag = false;
      this.showTable = true;
      this.assignToSelfHasErr = true;
      this.assignToSelfErrMsg = result.resultValue;
    }
  }
  /**
   * This method is called on the click of assign to self button and internally it will update case assigned to
   * fied with logged in user.
   */
  async assignToSelfHandler() {
    let selectedRows = this.template
      .querySelector("lightning-datatable")
      .getSelectedRows();
    let selectedCaseId = [];
    let selectedCaseRowIds = [];
    let selectedCaseInvestigationId = [];

    let caseSelected = false;
    for (let i = 0; i < selectedRows.length; i++) {

      //if a case is ST case, select case investigation for owner updates
      if(selectedRows[i].caseInvestigationId){
        selectedCaseInvestigationId.push(selectedRows[i].caseInvestigationId);
      }
      else{
        selectedCaseId.push(selectedRows[i].caseId);
      }

      selectedCaseRowIds.push(selectedRows[i].rowNumber);
      caseSelected = true;
    }
    if(selectedCaseRowIds.length > 20) {
      this.assignToSelfErrMsg = 'Please select maximum of 20 records for assignment';
      this.assignToSelfHasErr = true;
    }else {
      if(caseSelected) {
        this.searchingFlag = true;
        this.showTable = false;
        this.assignToSelfHasErr = false;
        let selectedRecordIdJson = JSON.stringify(selectedCaseId.concat(selectedCaseInvestigationId));

        //let result = await assignToSelf({ caseIds: selectedCaseIdJson });

        let result = await assignSelectedRecords({
          recordIds: selectedRecordIdJson,
          selectedUserId: '',
          isAssignSelf : true
        });

        if (!result.hasError) {
          for (let i = 0; i < selectedCaseRowIds.length; i++) {
            let arryIndex = selectedCaseRowIds[i];
            let caseRecord = this.cases[arryIndex];
            caseRecord.Case_assignedTo = result.resultValue;
            let carVarData={};
            carVarData = Object.assign(carVarData, caseRecord);
          this.recordsToDisplay[arryIndex] = caseRecord;
          }
          this.searchingFlag = false;
          this.showTable = true;
        } else {
          this.searchingFlag = false;
          this.showTable = true;
          this.assignToSelfHasErr = true;
          this.assignToSelfErrMsg = result.resultValue;
        }  
      }else {
        this.assignToSelfErrMsg = 'Please select records for assignment';
        this.assignToSelfHasErr = true;
      }
    }   
  }
}