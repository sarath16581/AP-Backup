import { LightningElement, track, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import getBusinessUnit from "@salesforce/apex/CaseHandOffController.getBusinessUnit";
import handOffCase from "@salesforce/apex/CaseHandOffController.handOffCase";
import searchConsignmentStarTrack from "@salesforce/apexContinuation/CaseHandOffController.searchConsignmentStarTrack";

import { CloseActionScreenEvent } from "lightning/actions";
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getFocusedTabInfo, closeTab } from "lightning/platformWorkspaceApi";

import CASEOBJECT from "@salesforce/schema/Case";
import CASENUMBER from "@salesforce/schema/Case.CaseNumber";
import CASERECORDTYPEID from "@salesforce/schema/Case.RecordTypeId";
import CASERECORDTYPENAME from "@salesforce/schema/Case.RecordType.DeveloperName";
import PRODUCTID from "@salesforce/schema/Case.ArticleTest__r.ProductID__c";
import ARTICLENAME from "@salesforce/schema/Case.ArticleTest__r.Name";

const FIELDS = [
  CASENUMBER,
  CASERECORDTYPEID,
  CASERECORDTYPENAME,
  PRODUCTID,
  ARTICLENAME,
];

export default class CaseHandOff extends LightningElement {
  isLoading = false;
  @api recordId;
  errorMessage;
  @track caseRecord;
  @track handoffWrapper = {
	caseId: "",
	articleId: "",
	handoffReason: "",
	comment: "",
	businessUnit: "",
	contactCenter: "",
	caseRecordType: "",
  };

  @track contactCenterOptions = [
	{
	  label: "Australia Post MyCustomers",
	  value: "UnifiedAusPostHandoffTriageQueue",
	},
	{
	  label: "StarTrack Service Cloud",
	  value: "UnifiedStarTrackHandoffTriageQueue",
	},
  ];

  @track handoffReasonOptions = [];

  get caseRecordTypeId() {
	return getFieldValue(this.caseRecord, CASERECORDTYPEID);
  }

  get productId() {
	return getFieldValue(this.caseRecord, PRODUCTID);
  }

  get articleName() {
	return getFieldValue(this.caseRecord, ARTICLENAME);
  }

  // get the record id from URL
  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
	this.isLoading = true;
	if (currentPageReference) {
	  this.recordId = currentPageReference.state?.recordId;
	}
  }

  // get Case Data
  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredCase({ error, data }) {
	if (data) {
	  this.caseRecord = data;
	  this.handoffWrapper.caseRecordType =
		this.caseRecord.fields.RecordType.value.fields.DeveloperName.value;
	} else if (error) {
	  this.caseRecord = undefined;
	  this.handoffWrapper.caseRecordType = undefined;
	  console.error("wiredCase error ==>", error);
	}
  }

  // get business unit
  @wire(getBusinessUnit, { productId: "$productId" })
  wiredBusinessUnit({ error, data }) {
	if (data) {
	  this.handoffWrapper.businessUnit = data;
	  if (this.handoffWrapper.businessUnit == "AustraliaPost") {
		this.handoffWrapper.contactCenter = "UnifiedAusPostHandoffTriageQueue";
	  } else {
		this.handoffWrapper.contactCenter =
		  "UnifiedStarTrackHandoffTriageQueue";
	  }
	  this.isLoading = false;
	} else if (error) {
	  this.handoffWrapper.businessUnit = undefined;
	  console.error("wiredBusinessUnit error ==>", error);
	}
  }

  // get handOff Picklist Values
  @wire(getPicklistValuesByRecordType, {
	objectApiName: CASEOBJECT,
	recordTypeId: "$caseRecordTypeId",
  })
  wiredCasePicklists({ error, data }) {
	if (data) {
	  this.handoffReasonOptions =
		data.picklistFieldValues.CaseTransferReason__c.values;
	} else if (error) {
	  console.error("wiredCasePicklists error ==>", error);
	}
  }

  // validation for contact center change
  handleContactCenterChange(event) {
	this.handoffWrapper.contactCenter = event.detail.value;
	let contactCenterElm = this.template.querySelector(
	  "lightning-combobox[data-id=contactCenter]"
	);
	contactCenterElm.setCustomValidity("");
	if (
	  this.handoffWrapper.contactCenter ==
		"UnifiedStarTrackHandoffTriageQueue" &&
	  this.handoffWrapper.businessUnit == "AustraliaPost"
	) {
	  contactCenterElm.setCustomValidity(
		"Cannot convert case to ST, consignment product is a AP product"
	  );
	} else if (
	  this.handoffWrapper.contactCenter == "UnifiedAusPostHandoffTriageQueue" &&
	  this.handoffWrapper.businessUnit == "StarTrack"
	) {
	  contactCenterElm.setCustomValidity(
		"Cannot convert case to AP, consignment product is a ST product"
	  );
	}

	contactCenterElm.reportValidity();
  }

  handleHandOffReasonChange(event) {
	this.handoffWrapper.handoffReason = event.detail.value;
  }

  handleCommentChange(event) {
	this.handoffWrapper.comment = event.detail.value;
  }

  //This method is called to handle case transfer process
  handOffCase() {
	if (this.checkValidity()) {
	  this.isLoading = true;

	  if (this.handoffWrapper.businessUnit === "StarTrack") {
		searchConsignmentStarTrack({ consignmentNumber: this.articleName })
		  .then((result) => {
			// Once the consignment search is complete, proceed with the handoff
			if (result.length > 1) {
			  this.isLoading = false;
			  this.showNotification(
				"Error",
				"Case transfer failed as consignment search found duplicate records, report the issue to your manager",
				"error"
			  );
			} else {
			  this.handoffWrapper.articleId = result[0].Id;
			  this.processHandOffCase();
			}
		  })
		  .catch((error) => {
			this.isLoading = false;
			this.showNotification(
			  "Error",
			  "Consignment search failed. Please contact Salesforce support team",
			  "error"
			);
			console.error(
			  "searchConsignmentStarTrack error ==>",
			  JSON.stringify(error)
			);
		  });
	  } else {
		// Directly proceed with handoff
		this.processHandOffCase();
	  }
	}
  }

  processHandOffCase() {
	this.handoffWrapper.caseId = this.recordId;

	handOffCase({
	  handoffWrapper: this.handoffWrapper,
	})
	  .then((result) => {
		this.isLoading = false;
		this.showNotification(
		  "Success",
		  "Case transferred successfully",
		  "success"
		);
		this.dispatchEvent(new CloseActionScreenEvent());
		this.closeCaseTab();
	  })
	  .catch((error) => {
		this.isLoading = false;
		this.showNotification(
		  "Error",
		  "Case transfer failed, please try again. If the error continues, report the issue to your manager",
		  "error"
		);
		console.error("processHandOffCase error ==>", JSON.stringify(error));
	  });
  }

  handleCancel(event) {
	event.preventDefault();
	this.dispatchEvent(new CloseActionScreenEvent());
  }

  checkValidity() {
	let isInputsCorrect = [
	  ...this.template.querySelectorAll(
		"lightning-combobox, lightning-textarea"
	  ),
	].reduce((validSoFar, inputField) => {
	  inputField.reportValidity();
	  return validSoFar && inputField.checkValidity();
	}, true);

	if (this.articleName == null) {
	  isInputsCorrect = false;
	  this.errorMessage = "No consignment is associated with this case";
	}
	return isInputsCorrect;
  }

  showNotification(title, message, variant) {
	const evt = new ShowToastEvent({
	  title: title,
	  message: message,
	  variant: variant,
	});
	this.dispatchEvent(evt);
  }

  async closeCaseTab() {
	const { tabId } = await getFocusedTabInfo();
	await closeTab(tabId);
  }
}