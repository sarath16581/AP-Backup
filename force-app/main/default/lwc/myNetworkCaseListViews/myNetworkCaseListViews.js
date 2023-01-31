/**
 * @author       : arjun.singh@auspost.com.au
 * @date         : 23/03/2020
 * @description  : Component that has custom list view and search filters
 * --------------------------------------- History --------------------------------------------------
 * 2022-11-28 	Dattaraj Deshmukh	Added 'star_track_cases' list view. Added Enquiry Type and Product Catergory values.
 **/
/* eslint-disable no-console */
import { LightningElement, track, wire, api } from "lwc";
import getFiltersData from "@salesforce/apex/MyNetworkCaseListController.getFiltersData";
import clearCache from "@salesforce/apex/MyNetworkCaseListController.clearCache";
import getpickListValues from "@salesforce/apex/MyNetworkCaseListController.getpickListValues";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import CASE_OBJECT from "@salesforce/schema/Case";
import PRIORITY_FIELD from "@salesforce/schema/Case.Priority";
export default class CaseListViews extends LightningElement {
  @track listViewsArray = [];
  @track listEnquirySubType;
  @track listProductCategory;
  @track selectEnquirySubType = "--Select--";
  @track selectedIsPrinted = "--Select--";
  @track listIsPrinted = [];
  @track selectedListView = "All_Cases";
  @track casePrintedFlag = "--Select--";
  @track searchFieldDetails = [];
  @track selectedPriorityValue = "--Select--";
  @track selectedProductCategoryValue = "--Select--";
  @track casePrintFlagVal = false;
  @track AddressePostcodeVal = "";
  @track caseNumberVal = "";
  @track selectedNetworkRecrdId = "";
  @track searchButtonClickedFlag = false;
  @track listEnquiryType; // this is used only for StarTrack cases.

  @api loadingFlag;

  @track priorityPickListValues;
  @track activeSections = [];

  @wire(getpickListValues)
  CasePickListValueSet({ error, data }) {
	if (data) {
	  this.listEnquirySubType = [{ label: "--Select--", value: "--Select--" }];
	  this.listProductCategory = [{ label: "--Select--", value: "--Select--" }];
	  for (let i = 0; i < data.length; i++) {
		if(data[i].FieldName__c === 'EnquirySubType'){
		  let dataVar = { label: data[i].MasterLabel, value: data[i].MasterLabel };
		  this.listEnquirySubType.push(dataVar);
		}else if(data[i].FieldName__c === 'ProductCategory'){
		  let dataVar = { label: data[i].MasterLabel, value: data[i].MasterLabel };
		  this.listProductCategory.push(dataVar);
		}else if(data[i].FieldName__c === 'EnquiryType') { //check for ST cases ONLY.
		  let dataVar = { label: data[i].MasterLabel, value: data[i].MasterLabel, isStarTrackCase : true };
		  this.listEnquirySubType.push(dataVar);
		}else if(data[i].FieldName__c === 'StarTrackProductCategory') { //check for ST cases ONLY.
		  let dataVar = { label: data[i].MasterLabel, value: data[i].MasterLabel, isStarTrackCase : true };
		  this.listProductCategory.push(dataVar);
		}
		
	  }
	  this.loadingFlag = false;
	} else {
	  this.error = error;
	  this.loadingFlag = false;
	}
  }
  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  objectInfo;

  @wire(getPicklistValues, {
	recordTypeId: "$objectInfo.data.defaultRecordTypeId",
	fieldApiName: PRIORITY_FIELD
  })
  priorityPickListValuesSet({ error, data }) {
	if (data) {
	  this.priorityPickListValues = [
		{ label: "--Select--", value: "--Select--" },
		...data.values
	  ];
	  this.loadingFlag = false;
	} else {
	  this.error = error;
	  this.loadingFlag = false;
	}
  }
  connectedCallback() {
	this.listViewsArray = [
	  { label: "All Cases", value: "All_Cases" },
	  { label: "My Cases", value: "My_Cases" },
	  {
		label: "Enterprise customers/high value customers",
		value: "Enterprise_customers"
	  },
	  {
		label: "Facility reported damages-eParcel and wine damages",
		value: "Facility_reported"
	  }
	  ,
	  { label: "Updated Cases", value: "Cases_updated" },
	  { label: "StarTrack Cases", value: "star_track_cases" },
	  
	];

	this.listIsPrinted = [
	  { label: "--Select--", value: "--Select--" },
	  { label: "Yes", value: "Yes" },
	  { label: "No", value: "No" }
	];
	this.filterDataFromCache();
  }
  /**
	 @Description : Will be called on change of selected list view from  case list view page.
					Intenally it will call the searchFilterCase method which will capture the filters and 
					selected list view and pass it to apex controller.
	 */

  handleSelectedListViewChange(event) {
	this.selectedListView = event.detail.value;
	this.searchFilteredCase();
  }
  /**
		@description : This method is used to get the cache data from platform cache and will be used
						auto populate the fitlers/select list view and will return the case result dynamically
						based on selected filters/listview. 
	 */
  async filterDataFromCache() {
	let result = await getFiltersData();
	if (result) {
	  let resultJson = JSON.parse(result);
	  this.template.querySelectorAll("lightning-input-field").forEach(each => {
		if (
		  each.fieldName === "Network__c" &&
		  resultJson.selectedNetworkRecrdIdVal
		) {
		  this.selectedNetworkRecrdId = resultJson.selectedNetworkRecrdIdVal;
		} else if (
		  each.fieldName === "Address2Postcode__c" &&
		  resultJson.addressePostcodeVal
		) {
		  this.AddressePostcodeVal = resultJson.addressePostcodeVal;
		}
	  });

	  this.template.querySelectorAll("lightning-combobox").forEach(each => {
		if (each.name === "Priority" && resultJson.priorityVal) {
		  this.selectedPriorityValue = resultJson.priorityVal;
		} else if (
		  each.name === "listEnquirySubType" &&
		  resultJson.enquirySubTypeVal
		) {
		  this.selectEnquirySubType = resultJson.enquirySubTypeVal;
		} else if (
		  each.name === "productCategory" &&
		  resultJson.selectedProductCategoryVal
		) {
		  this.selectedProductCategoryValue =
			resultJson.selectedProductCategoryVal;
		} else if (
		  each.name === "listViewsArray" &&
		  resultJson.selectedlistview
		) {
		  this.selectedListView = resultJson.selectedlistview;
		} else if (each.name === "isPrinted" && resultJson.isPrinted) {
		  this.casePrintedFlag = resultJson.isPrinted;
		}
	  });
	  this.searchButtonClickedFlag = resultJson.searchButtonClicked;
	  this.caseNumberVal = "";
	  this.searchFilteredCase();
	} 
  }
  /**
	 @Description : This method is called on click of seach button and will inturn calls searchFilteredCase()
					and returns the case results to be displayed in case list view
	 */
  searchButtonhandler() {
	this.searchButtonClickedFlag = true;
	this.searchFilteredCase();
  }
  /**
	 @Description: This method is used to create a json of selected filteres/list view and pass it to backend 
					controller.Apex Method will de serialize the json and will generate the soql dynamically
					to return the case result.
	 */
  searchFilteredCase() {

	//searching if selected EnquiryType value is of the type StarTrack.

	let enquirySubType = this.listEnquirySubType.find(el => el.value === this.selectEnquirySubType );
	let stProductCategory = this.listProductCategory.find(el => el.value === this.selectedProductCategoryValue );
   
	this.searchFieldDetails = {
	  isPrinted: this.casePrintedFlag,
	  priorityVal: this.selectedPriorityValue,
	  enquirySubTypeVal: this.selectEnquirySubType,
	  addressePostcodeVal: this.AddressePostcodeVal,
	  selectedProductCategoryVal: this.selectedProductCategoryValue,
	  selectedNetworkRecrdIdVal: this.selectedNetworkRecrdId,
	  selectedlistview: this.selectedListView,
	  searchButtonClicked: this.searchButtonClickedFlag,
	  caseNumberVal: this.caseNumberVal,
	  isStarTrackSearch : ( (enquirySubType && enquirySubType.isStarTrackCase) || (stProductCategory && stProductCategory.isStarTrackCase ) ) ? true : false
	};

	let searchFieldJson = JSON.stringify(this.searchFieldDetails);
	this.loadingFlag = false;
	this.dispatchEvent(
	  new CustomEvent("searchfieldschange", {
		detail: searchFieldJson
	  })
	);
  }
  /**
	 @Description: This method is called on click of Clear button. It will clear out all the 
				   selected filters and cache store in platfom cache. 
	 */
  clearSearch(event) {
	this.loadingFlag = true;
	clearCache()
	  .then(result => {
		if (result) {
		  this.casePrintedFlag = "--Select--";
		  this.selectedPriorityValue = "--Select--";
		  this.selectEnquirySubType = "--Select--";
		  this.AddressePostcodeVal = "";
		  this.caseNumberVal = "";
		  this.selectedProductCategoryValue = "--Select--";
		  this.selectedNetworkRecrdId = "";
		  this.loadingFlag = false;
		  this.searchButtonClickedFlag = false;
		  this.searchFilteredCase();
		}
	  })
	  .catch(error => {
		console.log("err>>>", this.error);
	  });
  }
  /**
	 @Description : This method is called on change of any input fields and will populate the related linked 
					variable to be used of getting the case result. 
	 */
  handleFieldChange(event) {
	if (event.target.name === "Priority") {
	  this.selectedPriorityValue = event.target.value;
	} else if (event.target.name === "listEnquirySubType") {
	  this.selectEnquirySubType = event.target.value;
	} else if (event.target.fieldName === "Address2Postcode__c") {
	  this.AddressePostcodeVal = event.target.value;
	} else if (event.target.name === "caseNumber") {
	  this.caseNumberVal = event.target.value.trim();
	} else if (event.target.name === "productCategory") {
	  this.selectedProductCategoryValue = event.target.value;
	} else if (event.target.name === "isPrinted") {
	  this.casePrintedFlag = event.target.value;
	} else if (event.target.fieldName === "Network__c") {
	  this.selectedNetworkRecrdId = event.target.value;
	}
  }
  handleSectionToggle(event) {
	const openSections = event.detail.openSections;
  }
}