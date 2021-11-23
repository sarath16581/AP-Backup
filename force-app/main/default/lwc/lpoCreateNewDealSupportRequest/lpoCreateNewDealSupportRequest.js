/* @author Mav3rik
 * @date 2020-10-27
 * @group Deal_Support_Request__c
 * @tag Deal_Support_Request__c
 * @domain Core
 * @description LWC Component for Creating new Deal Support Requests in the LPO Partner Community
 * @changelog
 * 2020-10-27 - Mav3rik - Created
 */
import { track, api, wire } from "lwc";
import LwcForm from "c/lwcForm";
import { NavigationMixin } from "lightning/navigation";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import DEAL_SUPPORT_REQUEST_OBJECT from "@salesforce/schema/Deal_Support_Request__c";
import PRODUCT_FIELD from "@salesforce/schema/Deal_Support_Request__c.Product__c";
import WORK_TYPE_FIELD from "@salesforce/schema/Deal_Support_Request__c.Work_Type__c";
import SUPPORT_WORK_TYPE_FIELD from "@salesforce/schema/Deal_Support_Request__c.Support_Work_Type__c";
import getOpportunity from "@salesforce/apex/LPODealSupportRequestController.getOpportunity";
import saveRecord from "@salesforce/apex/LPODealSupportRequestController.saveRecord";
import getWorkTypeValues from "@salesforce/apex/LPODealSupportRequestController.getWorkTypeValues";

export default class LpoCreateNewDealSupportRequest extends NavigationMixin(
  LwcForm
) {
  @api recordId;
  @track saveState;
  @track saveMessage;
  @track errorMessage;

  // Get Opportunity Record
  @track OpportunityRecord;
  @track isOpportunityLoaded = false;
  @wire(getOpportunity, { recordId: "$recordId" })
  wiredGetOpportunity({ error, data }) {
    if (data) {
      this.OpportunityRecord = data;
      this.isOpportunityLoaded = true;
    } else if (error) {
      this.OpportunityRecord = undefined;
      this.isOpportunityLoaded = false;
      this.errorMessage = this.handleError(error);
    }
  }

  // Get Custom Setting Subset Values for Work Type Picklist
  @track workTypeValues;
  @wire(getWorkTypeValues)
  wiredGetWorkTypeValues({ error, data }) {
    if (data) {
      this.workTypeValues = data;
    } else if (error) {
      this.errorMessage = this.handleError(error);
    }
  }

  // Get object for Picklist Values
  @wire(getObjectInfo, { objectApiName: DEAL_SUPPORT_REQUEST_OBJECT })
  objectInfo;
  // Product Picklist
  @track ProductPicklistValues;
  @track isProductPicklistValuesLoaded = false;
  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: PRODUCT_FIELD
  })
  wiredContactsProductPicklistValues({ error, data }) {
    if (data) {
      this.ProductPicklistValues = data;
      this.isProductPicklistValuesLoaded = true;
    } else if (error) {
      this.ProductPicklistValues = undefined;
      this.isProductPicklistValuesLoaded = false;
      this.errorMessage = this.handleError(error);
    }
  }
  // Work Type Picklist
  @track WorkTypePicklistValues;
  @track isWorkTypePicklistValuesLoaded;
  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: WORK_TYPE_FIELD
  })
  wiredWorkTypePicklistValues({ error, data }) {
    if (data) {
      if (!!this.workTypeValues) {
        const workTypeValuesList = this.workTypeValues.split(",");
        this.WorkTypePicklistValues = data.values.filter(
          (value) => workTypeValuesList.indexOf(value.label) > -1
        );
      } else {
        this.WorkTypePicklistValues = data.values;
      }
      this.isWorkTypePicklistValuesLoaded = true;
    } else if (error) {
      this.WorkTypePicklistValues = undefined;
      this.isWorkTypePicklistValuesLoaded = false;
      this.errorMessage = this.handleError(error);
    }
  }
  // Support Work Type Picklist
  @track SupportWorkTypePicklistValues;
  @track isSupportWorkTypePicklistValuesLoaded;
  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: SUPPORT_WORK_TYPE_FIELD
  })
  wiredSupportWorkTypePicklistValues({ error, data }) {
    if (data) {
      this.SupportWorkTypePicklistValues = data;
      this.isSupportWorkTypePicklistValuesLoaded = true;
    } else if (error) {
      this.SupportWorkTypePicklistValues = undefined;
      this.isSupportWorkTypePicklistValuesLoaded = false;
      this.errorMessage = this.handleError(error);
    }
  }
  // Support Work Type Dependent Picklist
  @track SupportWorkTypeDependentPicklistValues = [];
  handleWorkTypeChange(event) {
    this.handleValueChange(event);
    if (this.isSupportWorkTypePicklistValuesLoaded) {
      const key = this.SupportWorkTypePicklistValues.controllerValues[
        event.target.value
      ];
      this.SupportWorkTypeDependentPicklistValues = this.SupportWorkTypePicklistValues.values.filter(
        (opt) => opt.validFor.includes(key)
      );
    }
  }

  /**
   * @description Handle insert of Deal_Support_Request__c record
   */
  async handleInsert() {
    const allValid = this.validateInputs();
    if (allValid) {
      const recordData = this.getVisibleData();
      const record = { sobjectType: "Deal_Support_Request__c" };
      record.Opportunity__c = this.recordId;
      record.Organisation__c = this.OpportunityRecord.Account.Id;
      record.Product__c = recordData.product;
      record.Work_Type__c = recordData.workType;
      record.Support_Work_Type__c = recordData.supportWorkType;
      record.Description__c = recordData.description;
      // If the support work type picklist has values and nothing is set, show an error
      if (
        !recordData.supportWorkType &&
        this.SupportWorkTypeDependentPicklistValues.length > 0
      ) {
        this.errorMessage = "Support Work Type is required";
        return;
      }

      try {
        await this.handleInsertRecord(record);
      } catch (error) {
        this.errorMessage = this.handleError(error);
      }
    }
  }

  /**
   * @description Handle Record Insert
   * @param {object} record - Record
   */
  async handleInsertRecord(record) {
    try {
      this.saveState = true;
      this.clearMessages();
      const newRecordId = await saveRecord({ record });
      this.saveState = false;
      this.handleRecordNavigation({ recordId: newRecordId });
    } catch (error) {
      throw error;
    }
  }

  /**
   * @description Handle errors
   * @param {*} error - The exception from apex class
   */
  handleError(error) {
    this.saveState = false;
    if (!error.body.message) {
      const fieldErrorMessage = this.getFieldErrorMessages(error);
      if (!!fieldErrorMessage) {
        return fieldErrorMessage;
      } else {
        const pageErrorMessage = this.getPageErrorMessages(error);
        return pageErrorMessage;
      }
    }
    return error.body.message;
  }

  /**
   * @description Get field error messages
   * @param {*} error - The exception from apex class
   */
  getFieldErrorMessages(error) {
    const fieldsWithErrors = Object.keys(error.body.fieldErrors);
    const fieldErrorMessages = fieldsWithErrors.reduce((allErrorMsg, field) => {
      const fieldErrors = error.body.fieldErrors[field];
      const currentErrorMsg = fieldErrors.reduce((errorMsg, fieldError) => {
        if (!errorMsg) {
          errorMsg += fieldError.message;
        } else {
          errorMsg += `; ${fieldError.message}`;
        }
        return errorMsg;
      }, "");
      if (!allErrorMsg) {
        allErrorMsg += currentErrorMsg;
      } else {
        allErrorMsg += `; ${currentErrorMsg}`;
      }
      return allErrorMsg;
    }, "");
    return fieldErrorMessages;
  }

  /**
   * @description Get page error messages
   * @param {*} error - The exception from apex class
   */
  getPageErrorMessages(error) {
    if (!error.body.pageErrors) {
      return "";
    }
    const pageErrorMessages = error.body.pageErrors.reduce(
      (errorMsg, fieldError) => {
        if (!errorMsg) {
          errorMsg += fieldError.message;
        } else {
          errorMsg += `; ${fieldError.message}`;
        }
        return errorMsg;
      },
      ""
    );
    return pageErrorMessages;
  }

  /**
   * @description Clear save/error messages
   */
  clearMessages() {
    this.saveMessage = "";
    this.errorMessage = "";
  }

  /**
   * @description Handle navigation to Deal Support Request Record Page
   */
  handleRecordNavigation({ recordId }) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId,
        actionName: "view"
      }
    });
  }

  /**
   * @description Dispatch an event to close the Quick Action
   */
  closeQuickAction() {
    const closeQA = new CustomEvent("close");
    this.dispatchEvent(closeQA);
  }
}