/**
 * @description Service class or utility functions and server communication
 * @author Ranjeewa Silva
 * @date 2020-10-05
 * @changelog
 * 2020-10-05 - Ranjeewa Silva - Created
 * 2020-11-08 - Ranjeewa Silva - Export 'Priority' and 'Origin' fields as constants.
 */

//Server calls
import createCaseDirectToNetwork from '@salesforce/apex/DtnCaseWizardController.createCaseDirectToNetwork'
import doDuplicateCheck from '@salesforce/apex/DtnCaseWizardController.doDuplicateCheck'
import getCaseDescriptionDefaultValue from '@salesforce/apex/DtnCaseWizardController.getCaseDescriptionDefaultValue'

import CASE_OBJECT from '@salesforce/schema/Case';

//Case object field mappings
import FIELD_ALLOCATE_TO_QUEUE from '@salesforce/schema/Case.AllocateToQueue__c';
import FIELD_ARTICLE from '@salesforce/schema/Case.ArticleTest__c';
import FIELD_AUTOMATED_NETWORK_ASSIGNMENT from '@salesforce/schema/Case.Automated_Network_Assignment__c';
import FIELD_CASE_ORIGINATOR_FIELD from '@salesforce/schema/Case.CaseOriginator__c';
import FIELD_COMPLAINT from '@salesforce/schema/Case.Complaint__c';
import FIELD_CONTACTID from '@salesforce/schema/Case.ContactId';
import FIELD_DATE_POSTED from '@salesforce/schema/Case.DatePosted__c';
import FIELD_DESCRIPTION from '@salesforce/schema/Case.Description';
import FIELD_DESCRIPTION_OF_CONTENTS from '@salesforce/schema/Case.DescriptionofContents__c';
import FIELD_ENQUIRY_SUB_TYPE from '@salesforce/schema/Case.EnquirySubType__c';
import FIELD_ENQUIRY_TYPE from '@salesforce/schema/Case.Enquiry_Type__c';
import FIELD_NETWORK from '@salesforce/schema/Case.Network__c';
import FIELD_ORIGIN from '@salesforce/schema/Case.Origin';
import FIELD_OWNERID from '@salesforce/schema/Case.OwnerId';
import FIELD_PRIORITY from '@salesforce/schema/Case.Priority';
import FIELD_PRODUCT_CATEGORY from '@salesforce/schema/Case.ProductCategory__c';
import FIELD_PRODUCT_SUB_CATEGORY from '@salesforce/schema/Case.ProductSubCategory__c';
import FIELD_RECORDTYPEID from '@salesforce/schema/Case.RecordTypeId';
import FIELD_REFERENCEID from '@salesforce/schema/Case.ReferenceID__c';
import FIELD_STATUS from '@salesforce/schema/Case.Status';
import FIELD_TYPE from '@salesforce/schema/Case.Type';
import FIELD_VALUE_OF_CONTENTS from '@salesforce/schema/Case.ValueofContents__c';

//Sender Address fields on Case
import FIELD_ADDRESS1 from '@salesforce/schema/Case.Address1__c';
import FIELD_ADDRESS1_LINE1 from '@salesforce/schema/Case.Address1Line1__c';
import FIELD_ADDRESS1_LINE2 from '@salesforce/schema/Case.Address1line2__c';
import FIELD_ADDRESS1_SUBURB from '@salesforce/schema/Case.Address1Suburb__c';
import FIELD_ADDRESS1_STATE from '@salesforce/schema/Case.Address1State__c';
import FIELD_ADDRESS1_POSTCODE from '@salesforce/schema/Case.Address1Postcode__c';
import FIELD_ADDRESS1_COUNTRY from '@salesforce/schema/Case.Address1Country__c';
import FIELD_ADDRESS1_DPID from '@salesforce/schema/Case.Address1DPID__c';
//Sender Contact Details on Case
import FIELD_PRIMARY_NAME from '@salesforce/schema/Case.Primary_Name__c';
import FIELD_PRIMARY_COMPANY from '@salesforce/schema/Case.Primary_Company__c';
import FIELD_PRIMARY_EMAIL from '@salesforce/schema/Case.Primary_Email__c';

//Receiver Address fields on Case
import FIELD_ADDRESS2 from '@salesforce/schema/Case.Address2__c';
import FIELD_ADDRESS2_LINE1 from '@salesforce/schema/Case.Address2Line1__c';
import FIELD_ADDRESS2_LINE2 from '@salesforce/schema/Case.Address2line2__c';
import FIELD_ADDRESS2_SUBURB from '@salesforce/schema/Case.Address2Suburb__c';
import FIELD_ADDRESS2_STATE from '@salesforce/schema/Case.Address2State__c';
import FIELD_ADDRESS2_POSTCODE from '@salesforce/schema/Case.Address2Postcode__c';
import FIELD_ADDRESS2_COUNTRY from '@salesforce/schema/Case.Address2Country__c';
import FIELD_ADDRESS2_DPID from '@salesforce/schema/Case.Address2DPID__c';

//Receiver Contact Details on Case
import FIELD_SECONDARY_CONTACT from '@salesforce/schema/Case.Secondary_Contact__c';
import FIELD_SECONDARY_COMPANY from '@salesforce/schema/Case.Secondary_Companry__c';
import FIELD_SECONDARY_EMAIL from '@salesforce/schema/Case.SecondaryEmail__c';

//Article Fields
import FIELD_SENDER_ADDRESS from '@salesforce/schema/Article__c.SenderAddress__c';
import FIELD_SENDER_ADDRESSLINE1 from '@salesforce/schema/Article__c.SenderAddressLine1__c';
import FIELD_SENDER_ADDRESSLINE2 from '@salesforce/schema/Article__c.SenderAddressLine2__c';
import FIELD_SENDER_CITY from '@salesforce/schema/Article__c.SenderCity__c';
import FIELD_SENDER_STATE from '@salesforce/schema/Article__c.SenderState__c';
import FIELD_SENDER_POSTCODE from '@salesforce/schema/Article__c.SenderPostcode__c';
import FIELD_SENDER_COUNTRY from '@salesforce/schema/Article__c.SenderCountry__c';
import FIELD_SENDER_COUNTRYNAME from '@salesforce/schema/Article__c.SenderCountryName__c';
import FIELD_RECEIVER_ADDRESS from '@salesforce/schema/Article__c.ReceiverAddress__c';
import FIELD_RECEIVER_ADDRESSLINE1 from '@salesforce/schema/Article__c.ReceiverAddressLine1__c';
import FIELD_RECEIVER_ADDRESSLINE2 from '@salesforce/schema/Article__c.ReceiverAddressLine2__c';
import FIELD_RECEIVER_CITY from '@salesforce/schema/Article__c.ReceiverCity__c';
import FIELD_RECEIVER_STATE from '@salesforce/schema/Article__c.ReceiverState__c';
import FIELD_RECEIVER_POSTCODE from '@salesforce/schema/Article__c.ReceiverPostcode__c';
import FIELD_RECEIVER_COUNTRY from '@salesforce/schema/Article__c.ReceiverCountry__c';
import FIELD_RECEIVER_COUNTRYNAME from '@salesforce/schema/Article__c.ReceiverCountryName__c';

import LABEL_DIRECTTONETWORKADDRESSHELPTEXT from '@salesforce/label/c.DirectToNetworkAddressHelpText';

export const CONSTANTS = {

    CASE_OBJECT : CASE_OBJECT.objectApiName,

    CASE_FIELDS : {
        FIELD_ALLOCATE_TO_QUEUE: FIELD_ALLOCATE_TO_QUEUE.fieldApiName,
        FIELD_AUTOMATED_NETWORK_ASSIGNMENT: FIELD_AUTOMATED_NETWORK_ASSIGNMENT.fieldApiName,
        FIELD_ARTICLE: FIELD_ARTICLE.fieldApiName,
        FIELD_PRODUCT_CATEGORY: FIELD_PRODUCT_CATEGORY.fieldApiName,
        FIELD_PRODUCT_SUB_CATEGORY: FIELD_PRODUCT_SUB_CATEGORY.fieldApiName,
        FIELD_COMPLAINT: FIELD_COMPLAINT.fieldApiName,
        FIELD_TYPE: FIELD_TYPE.fieldApiName,
        FIELD_ENQUIRY_SUB_TYPE: FIELD_ENQUIRY_SUB_TYPE.fieldApiName,
        FIELD_CASE_ORIGINATOR_FIELD: FIELD_CASE_ORIGINATOR_FIELD.fieldApiName,
        FIELD_RECORDTYPEID: FIELD_RECORDTYPEID.fieldApiName,
        FIELD_REFERENCEID: FIELD_REFERENCEID.fieldApiName,
        FIELD_NETWORK: FIELD_NETWORK.fieldApiName,
        FIELD_CONTACTID: FIELD_CONTACTID.fieldApiName,
        FIELD_VALUE_OF_CONTENTS: FIELD_VALUE_OF_CONTENTS.fieldApiName,
        FIELD_DESCRIPTION_OF_CONTENTS: FIELD_DESCRIPTION_OF_CONTENTS.fieldApiName,
        FIELD_DATE_POSTED: FIELD_DATE_POSTED.fieldApiName,
        FIELD_DESCRIPTION: FIELD_DESCRIPTION.fieldApiName,
        FIELD_OWNERID: FIELD_OWNERID.fieldApiName,
        FIELD_STATUS: FIELD_STATUS.fieldApiName,
        FIELD_ORIGIN: FIELD_ORIGIN.fieldApiName,
        FIELD_PRIORITY: FIELD_PRIORITY.fieldApiName,
        SENDER : {
            FIELD_ADDRESS1: FIELD_ADDRESS1.fieldApiName,
            FIELD_ADDRESS1_LINE1: FIELD_ADDRESS1_LINE1.fieldApiName,
            FIELD_ADDRESS1_LINE2: FIELD_ADDRESS1_LINE2.fieldApiName,
            FIELD_ADDRESS1_SUBURB: FIELD_ADDRESS1_SUBURB.fieldApiName,
            FIELD_ADDRESS1_STATE: FIELD_ADDRESS1_STATE.fieldApiName,
            FIELD_ADDRESS1_POSTCODE: FIELD_ADDRESS1_POSTCODE.fieldApiName,
            FIELD_ADDRESS1_COUNTRY: FIELD_ADDRESS1_COUNTRY.fieldApiName,
            FIELD_ADDRESS1_DPID: FIELD_ADDRESS1_DPID.fieldApiName,
            //FIELD_PRIMARY_CONTACT_NAME: FIELD_PRIMARY_CONTACT_NAME.fieldApiName,
            FIELD_PRIMARY_NAME: FIELD_PRIMARY_NAME.fieldApiName,
            FIELD_PRIMARY_COMPANY: FIELD_PRIMARY_COMPANY.fieldApiName,
            FIELD_PRIMARY_EMAIL: FIELD_PRIMARY_EMAIL.fieldApiName
        },
        RECEIVER : {
            FIELD_ADDRESS2: FIELD_ADDRESS2.fieldApiName,
            FIELD_ADDRESS2_LINE1: FIELD_ADDRESS2_LINE1.fieldApiName,
            FIELD_ADDRESS2_LINE2: FIELD_ADDRESS2_LINE2.fieldApiName,
            FIELD_ADDRESS2_SUBURB: FIELD_ADDRESS2_SUBURB.fieldApiName,
            FIELD_ADDRESS2_STATE: FIELD_ADDRESS2_STATE.fieldApiName,
            FIELD_ADDRESS2_POSTCODE: FIELD_ADDRESS2_POSTCODE.fieldApiName,
            FIELD_ADDRESS2_COUNTRY: FIELD_ADDRESS2_COUNTRY.fieldApiName,
            FIELD_ADDRESS2_DPID: FIELD_ADDRESS2_DPID.fieldApiName,
            FIELD_SECONDARY_CONTACT: FIELD_SECONDARY_CONTACT.fieldApiName,
            FIELD_SECONDARY_COMPANY: FIELD_SECONDARY_COMPANY.fieldApiName,
            FIELD_SECONDARY_EMAIL: FIELD_SECONDARY_EMAIL.fieldApiName
        }
    },

    ARTICLE_FIELDS : {
        FIELD_SENDER_ADDRESS: FIELD_SENDER_ADDRESS.fieldApiName,
        FIELD_SENDER_ADDRESSLINE1: FIELD_SENDER_ADDRESSLINE1.fieldApiName,
        FIELD_SENDER_ADDRESSLINE2: FIELD_SENDER_ADDRESSLINE2.fieldApiName,
        FIELD_SENDER_CITY: FIELD_SENDER_CITY.fieldApiName,
        FIELD_SENDER_STATE: FIELD_SENDER_STATE.fieldApiName,
        FIELD_SENDER_POSTCODE: FIELD_SENDER_POSTCODE.fieldApiName,
        FIELD_SENDER_COUNTRY: FIELD_SENDER_COUNTRY.fieldApiName,
        FIELD_SENDER_COUNTRYNAME: FIELD_SENDER_COUNTRYNAME.fieldApiName,
        FIELD_RECEIVER_ADDRESS: FIELD_RECEIVER_ADDRESS.fieldApiName,
        FIELD_RECEIVER_ADDRESSLINE1: FIELD_RECEIVER_ADDRESSLINE1.fieldApiName,
        FIELD_RECEIVER_ADDRESSLINE2: FIELD_RECEIVER_ADDRESSLINE2.fieldApiName,
        FIELD_RECEIVER_CITY: FIELD_RECEIVER_CITY.fieldApiName,
        FIELD_RECEIVER_STATE: FIELD_RECEIVER_STATE.fieldApiName,
        FIELD_RECEIVER_POSTCODE: FIELD_RECEIVER_POSTCODE.fieldApiName,
        FIELD_RECEIVER_COUNTRY: FIELD_RECEIVER_COUNTRY.fieldApiName,
        FIELD_RECEIVER_COUNTRYNAME: FIELD_RECEIVER_COUNTRYNAME.fieldApiName
    },

    LABEL_DIRECTTONETWORKADDRESSHELPTEXT : LABEL_DIRECTTONETWORKADDRESSHELPTEXT
};

/**
 * Create a new case assigned to network.
 */
export const createCase = async (caseRecord, ignoreDuplicates, attachSafedrop) => {

    let result = await createCaseDirectToNetwork({
		newCase: caseRecord,
		ignoreDuplicates: ignoreDuplicates,
		attachSafedrop: attachSafedrop
	});

	console.log('createCaseDirectToNetwork', result);
	return result;
}

/**
 * Check for duplicate cases and warn user.
 */
export const checkDuplicateCases = async (caseRecord) => {

    let result = await doDuplicateCheck({
		newCase: caseRecord
	});

	console.log('doDuplicateCheck', result);
	return result;
}

/**
 * Check for duplicate cases and warn user.
 */
export const getDefaultCaseDescription = async (caseRecord) => {

    let result = await getCaseDescriptionDefaultValue({
		newCase: caseRecord
	});

	console.log('getDefaultCaseDescription', result);
	return result;
}