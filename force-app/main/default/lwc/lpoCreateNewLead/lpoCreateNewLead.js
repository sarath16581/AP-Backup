/* @author Mav3rik
 * @date 2020-10-27
 * @group Lead
 * @tag Lead
 * @domain Core
 * @description LWC Component for Creating new Leads in the LPO Partner Community
 * @changelog
 * 2020-10-27 - Mav3rik - Created
 */
import LwcForm from "c/lwcForm";
import { track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import saveLead from "@salesforce/apex/LPOLeadController.saveLead";
import updateLead from "@salesforce/apex/LPOLeadController.updateLead";
import checkDuplicates from "@salesforce/apex/LPOLeadController.checkDuplicates";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import LEAD_OBJECT from "@salesforce/schema/Lead";
import PRODUCTS_FIELD from "@salesforce/schema/Lead.Products__c";
import COMPETITOR_FIELD from "@salesforce/schema/Lead.Competitor__c";

// Product description in a card in Revenue Information
const PRODUCT_DESCRIPTIONS = [
  {
    title: "MyPost Business",
    desc:
      "Allow customers to send both Domestic and International parcels with no minimum spend requirements and at the same time the more they send the more they save."
  },

  {
    title: "Mail Products & Services",
    desc: "Unaddressed Mail & Campaign Targeter or any other mail services."
  },
  {
    title: "Warehousing Solutions",
    desc:
      "Perfect for your customer if they require an external 3rd party pick and pack solution. Our solution known as Fulfilio."
  },

  {
    title: "StarTrack - Road Express & Premium",
    desc:
      "A Business to Business (B2B) & Business to Consumer (B2C) solution for moving cartons or pallets. Courier: Same Day cross town delivery for businesses within a defined metro zone."
  },

  {
    title: "Parcel Services",
    desc:
      "eParcel domestic & International for growing ecommerce customers. Unlike MyPost Business contracted parcel services (minimum volume 2000 parcel per annum domestic / $3000 spend per annum Internationally)"
  },

  {
    title: "Payments - Financial Services",
    desc:
      "SecurePay provides an secure payment gateway for customers who process online payments usually through a shopping cart."
  }
];

export default class LpoCreateNewLead extends NavigationMixin(LwcForm) {
  productDescriptions = PRODUCT_DESCRIPTIONS;

  // Picklist Values
  @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
  objectInfo;
  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: PRODUCTS_FIELD
  })
  ProductsPicklistValues;
  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: COMPETITOR_FIELD
  })
  CompetitorPicklistValues;

  // Save and Error Messages
  @track saveMessage = "";
  @track saveMessageOnAdditionalDetails = "";
  @track saveMessageOnRevenueInfo = "";
  @track errorMessage = "";
  duplicatesDetected = false;
  @track errorDuplicateList =  [];
  @track errorMessageOnAdditionalDetails = "";
  @track errorMessageOnRevenueInfo = "";

  // Save State
  @track saveState = false;

  // Lead Record ID
  @track leadRecordId = "";

  // Re-used abn number value (It appears twice on the form. We need to keep track)
  @track abnNumber = "";

  // Lead Creation Flag
  @track isLeadRecordCreated = false;

  confirmSavingAsDuplicate = false;
  options = [{ label: 'Save as duplicate', value: 'confirm' }];
  value = [];

  handleCheckOverride(event) {
    this.confirmSavingAsDuplicate = event.detail.value; 
  }

  /**
   * @description Handle navigation to Lead Record Page
   */
  handleRecordNavigation() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.leadRecordId,
        actionName: "view"
      }
    });
  }

  /**
   * @description Handle Insert of Lead Basic Info
   */
  async handleInsert() {
    const allValid = this.validateInputs();

    if (allValid) {
      const leadData = this.getVisibleData();
      const lead = { sobjectType: "Lead" };
      lead.FirstName = leadData.firstName;
      lead.LastName = leadData.lastName;
      lead.Email = leadData.email;
      lead.Phone = leadData.phone;
      lead.Company = leadData.businessName;
      lead.ABN__c = leadData.abnNumber;
      lead.Website = leadData.website;
      lead.LeadSource = "Local Business Partner Program";
      lead.Campaign_Name__c = "Local Business Partner Program";
      this.abnNumber = leadData.abnNumber;

      try {
        await this.handleInsertRecord(lead);
        this.saveMessage = "Lead record successfully created";
        this.clearDuplicateInfo();
      } catch (error) {
        this.errorMessage = this.handleError(error);
      }
    }
  }

  /**
   * @description Handle Update of Lead Basic Info
   */
  async handleUpdate() {
    const allValid = this.validateInputs();

    if (allValid) {
      const leadData = this.getVisibleData();
      const lead = { sobjectType: "Lead" };
      lead.Id = this.leadRecordId;
      lead.FirstName = leadData.firstName;
      lead.LastName = leadData.lastName;
      lead.Email = leadData.email;
      lead.Phone = leadData.phone;
      lead.Company = leadData.businessName;
      lead.ABN__c = leadData.abnNumber;
      lead.Website = leadData.website;
      this.abnNumber = leadData.abnNumber;

      try {
        await this.handleUpdateRecord(lead);
        this.saveMessage = "Lead record successfully updated";
        clearDuplicateInfo();
      } catch (error) {
        this.errorMessage = this.handleError(error);
      }
    }
  }

  /**
   * @description Handle Update of Lead Additional Details
   */
  async handleUpdateAdditionalDetails() {
    if (!!this.leadRecordId) {
      const leadData = this.getVisibleData();
      const lead = { sobjectType: "Lead" };
      lead.Id = this.leadRecordId;
      lead.Account_No__c = leadData.existingBusinessCreditAccountNumber;
      lead.Customer_Number__c = leadData.existingMypostBusinessQRBarcodeNumber;
      lead.ABN__c = leadData.abnNumber;
      this.abnNumber = leadData.abnNumber;

      try {
        await this.handleUpdateRecord(lead);
        this.saveMessageOnAdditionalDetails =
          "Lead additional details successfully updated";
      } catch (error) {
        this.errorMessageOnAdditionalDetails = this.handleError(error);
      }
    }
  }

  /**
   * @description Handle Update of Lead Revenue Info
   */
  async handleUpdateRevenueInfo() {
    if (!!this.leadRecordId) {
      const leadData = this.getVisibleData();
      const lead = { sobjectType: "Lead" };
      lead.Id = this.leadRecordId;
      lead.Products__c = leadData.productsInterestedIn;
      lead.Competitor__c = leadData.otherCompetitorsCustomerIsCurrentlyUsing;
      lead.Description = this.getDescriptionValue(leadData);

      try {
        await this.handleUpdateRecord(lead);
        this.saveMessageOnRevenueInfo =
          "Lead revenue information successfully updated";
      } catch (error) {
        this.errorMessageOnRevenueInfo = this.handleError(error);
      }
    }
  }

  /**
   * @description Handle description and treat undefined values as empty string
   * @param {object} leadRecord - Lead record object
   */
  getDescriptionValue(leadRecord) {
    const blankIfUndefined = (str) => {
      if (!str) return "";
      return str;
    };
    const description = `
      ${blankIfUndefined(leadRecord.describeTheTypeOfItemsCustomerIsSending)} 
      ${blankIfUndefined(leadRecord.volumeSpendPerMonth)} 
      ${blankIfUndefined(leadRecord.currentPackagingUsed)} 
      ${blankIfUndefined(leadRecord.sendingDomesticOrInternational)} 
      ${blankIfUndefined(leadRecord.otherDetailsOfConversationWithCustomer)} 
    `;
    return description.trim();
  }

  /**
   * @description Handle Lead Insert
   * @param {object} lead - Lead Record
   */
  async handleInsertRecord(lead) {
    try {
      this.saveState = true;
      this.clearMessages();

      // confirmSavingAsDuplciate is false on rendered, 
      if (!this.confirmSavingAsDuplicate) {
        await checkDuplicates({
          leadRecord: lead,
        });
      }
      this.leadRecordId = await saveLead({
        leadRecord: lead,
      });
      this.isLeadRecordCreated = true;
      this.saveState = false;
    } catch (error) {
      throw error;
    }
  }

  /**
   * @description Handle Lead Update
   * @param {object} lead - Lead Record
   */
  async handleUpdateRecord(lead) {
    try {
      this.saveState = true;
      this.clearMessages();
      await updateLead({
        leadRecord: lead
      });
      this.saveState = false;
    } catch (error) {
      throw error;
    }
  }

  /**
   * @description Handle errors
   * @param {*} error - The exception from apex class (e.g. E-mail address is invalid)
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
    else {
      // check if there's any record json tacked onto the error message by parsing the token
      const duplicateErrorData = error.body.message.split('|');
      const message = duplicateErrorData[0];
      this.duplicatesDetected = true; // while fuzzy matches do not have records, we need this to show the checkbox
      // if there is extra JSON, parse to show in a list
      if (duplicateErrorData.length > 1) {
        const recordList = duplicateErrorData[1];
        this.errorDuplicateList = JSON.parse(recordList).map(record => {
          // the record may have any of the three, we consolidate them into a singular prop
          const address = record.BillingAddress || record.MailingAddress || record.Address;
          return {
            type: record.attributes.type,
            id: record.Id,
            name: record.Name,
            address: address ? `${address.postalCode} ${address.state}` : '',
          };
        });
      }
      return message;
    }
  }

  get hasDuplicateRecordData() { return this.errorDuplicateList.length > 0 }

  /**
   * @description Get field error messages
   * @param {*} error - The exception from apex class (e.g. E-mail address is invalid)
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
   * @param {*} error - The exception from apex class (e.g. E-mail address is invalid)
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
   * @description Clear the duplicate vairables
   */
  clearDuplicateInfo() {
    this.duplicatesDetected = false;
    this.errorDuplicateList = [];
  }

  /**
   * @description Clear all the save/error messages
   */
  clearMessages() {
    this.saveMessage = "";
    this.saveMessageOnAdditionalDetails = "";
    this.saveMessageOnRevenueInfo = "";
    this.errorMessage = "";
    this.errorMessageOnAdditionalDetails = "";
    this.errorMessageOnRevenueInfo = "";
    this.clearDuplicateInfo();
  }

  /**
   * @description Generate a url and open a new tab using the data from event
   * Do not use NavigateMixin.navigate because a bug will cause it to open in the same window event thought _blank is specified
   */
  navToDuplicateRecord(event) {
    event.stopPropagation();
    const recordId = event.currentTarget.dataset.id;
    const type = event.currentTarget.dataset.type;
    this[NavigationMixin.GenerateUrl]({
      type: "standard__recordPage",
      attributes: {
        recordId, 
        objectApiName: type,
        actionName: "view"
      }
    }).then(url => window.open(url, '_blank'));
  }
}