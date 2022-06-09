/**
 * Created by hasan on 6/06/2022.
 */

public with sharing class ChasProductsAndServicesController extends ChasBase{

    /**
* This method will create Case for Products and services
* */
    @AuraEnabled
    public static CaseWrapper createCaseFromProductsAndServices( Map <String,String> wizardData, Map <String,String> authUserData ){
        CaseWrapper caseWrapper = new CaseWrapper();
        caseWrapper.caseStatus = 'SUCCESS';

        try{
            //-- Getting recordType Ids
            String SSSWGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                    .get(ChasConstants.CASE_RECORDTYPE_SSSWGENERALDELIVERY).getRecordTypeId();

            String sswDeleveryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().
                    get(ChasConstants.CASE_RECORDTYPE_SSSWDELIVERY).getRecordTypeId();

            //-- defaulting the values
            String recordTypeId = SSSWGeneralRecordTypeId;
            String typeVal = 'General Enquiry';
            String enquirySubType= 'Product & service information';
            String origin = 'Portal';
            String CHASEnquiryType = 'Products & services';

            String typeAndProduct = null;
            String productCategory = null;
            String productSubCategory = null;
            String subject = null;

            String isEligibleForMyNetworkAssignment = '';

            //-- Getting all wizard data details
            String wcid = (String) wizardData.get('wcid');
            String toWcid = (String) wizardData.get('toWcid');
            String subProductId = 'SUB-PROD-ID-' + (String) wizardData.get('subProductId');
            String transferToPoProductExclusions = ChasConstants.TRANSFER_TO_PO_PROD_SUBTYPE_ID_EXCLUSIONS;
            String issueDetailsType =  (String) wizardData.get('selectedRadio1Name');
            String mailProductsEnquiryType =  (String) wizardData.get('mailProductsEnquiryType');
            String transferTrackingNumber =  (String) wizardData.get('trackingId');
            String idDocumentsAccountsEnquiryType =  (String) wizardData.get('idDocumentsAccountsEnquiryType');

            String orderNumber =  (String) wizardData.get('orderNumber');
            String orderTrackingNumber =  (String) wizardData.get('orderTrackingNumber');
            String enquiryType =  (String) wizardData.get('selectedRadio3Name');
            String madeAndOrder = (String) wizardData.get('selectedRadio2Name');

            //--  delivery address
            String deliveryAddressLine1 =  (String) wizardData.get('deliveryAddressLine1') !=null ? (String) wizardData.get('deliveryAddressLine1'):'';
            String deliveryAddressLine2 =  (String) wizardData.get('deliveryAddressLine2') !=null ? (String) wizardData.get('deliveryAddressLine2'):'';
            String deliveryCity =  (String) wizardData.get('deliveryCity') !=null ? (String) wizardData.get('deliveryCity'):'';
            String deliveryState =  (String) wizardData.get('deliveryState') !=null ? (String) wizardData.get('deliveryState'):'';
            String deliveryPostcode =  (String) wizardData.get('deliveryPostcode') !=null ? (String) wizardData.get('deliveryPostcode'):'';

            //-- authenticated user details
            String userContactEmail = authUserData.get('userContactEmail');
            String userContactFirstName =  authUserData.get('userContactFirstName');
            String userContactLastName =  authUserData.get('userContactLastName');
            String userContactPhone =  authUserData.get('userContactPhone');
            //-- guest user details
            String givenName =  (String)wizardData.get('givenName');
            String surname =  (String)wizardData.get('surname');
            String email =  (String)wizardData.get('emailId');
            String phone =  (String)wizardData.get('phone');
            //-- ENQUIRY DETAILS
            String enquiryDetails = (String) wizardData.get('enquiryDetails');

            String contactPreferrence =  (String)wizardData.get('contactPreferrence');  // Contact Preference, added by Edmarco on July 2019

            //-- Subject : Trimming the issueDetails details to 255 chars
            if(enquiryDetails != null){
                if(enquiryDetails.trim().length() > 255){
                    subject = enquiryDetails.substring(0, 255);
                }else{
                    subject = enquiryDetails;
                }
            }
            //-- Check network eligibility
            if(!String.isEmpty(wcid) && !String.isEmpty(wizardData.get('isParcelAwaitingCollection')) && 'true'.equalsIgnoreCase(wizardData.get('isParcelAwaitingCollection'))
                    && !transferToPoProductExclusions.containsIgnoreCase(subProductId)) {
                isEligibleForMyNetworkAssignment = 'true';
            }
            String selectedPostOffice = (String) wizardData.get('selectedPostOffice')!=null ? 'Please transfer item to : ' + (String) wizardData.get('selectedPostOffice'): null;
            String originalDeliveryAddress = 'Original delivery address : ' + deliveryAddressLine1 + ' ' + deliveryAddressLine2 + ', ' + deliveryCity + ', ' + deliveryState + ', ' + deliveryPostcode;
            //Spingali - Get user contact details to set contactId on case
            //String userId = UserInfo.getUserId();
            //User userContact = [SELECT contactId FROM User WHERE Id= :userId LIMIT 1];

            //-- Building Comment Body
            String commentBody ='Enquiry details : '  + issueDetailsType ;
            if(commentBody != null)
                //Removing this logic as Mail Products will add Details to Subject and Case Comments
                // if(issueDetailsType != 'Mail products'){
                commentBody = commentBody+ '\n' +'Details : '+enquiryDetails;
            //   }
            commentBody = commentBody + '\n' + 'Contact Preference : ' + contactPreferrence;  // Contact Preference, added by Edmarco on July 2019
            if(issueDetailsType == 'Online Shop' && madeAndOrder == 'Yes')
                commentBody = commentBody+ '\n' +'Order Number : '+orderNumber + '\n' +
                        'Contact Preference : ' + contactPreferrence;   // Contact Preference, added by Edmarco on July 2019
            if(selectedPostOffice != null){
                commentBody = commentBody+ '\n' + selectedPostOffice ;
            }
            //-- Change made for roll out of Products and services uplift
            if(transferTrackingNumber != null)
            {
                commentBody = commentBody+ '\n' + 'Tracking Id: ' + transferTrackingNumber;
            }
            if(issueDetailsType == 'Mail products' && mailProductsEnquiryType == 'Transfer to another post office'){
                commentBody = commentBody+ '\n' + originalDeliveryAddress;
            }

            if(issueDetailsType == 'ID, documents & accounts' && idDocumentsAccountsEnquiryType == 'Delete MyPost account') {
                commentBody = commentBody+ '\n' + 'MyPost account closure request, please check customer product holdings, refer SOP 05.06. MyPost Account – Cancel or merge MyPost account requests';
            }

            if(issueDetailsType == 'Mail products'){
                if(mailProductsEnquiryType == '24/7 Parcel Locker'){
                    typeAndProduct = 'General Enquiry|Web & Apps|Parcel Lockers';
                    productCategory = 'Web & Apps';
                    productSubCategory = 'Parcel lockers';
                }else if(mailProductsEnquiryType == 'Express Post'){
                    typeAndProduct = 'General Enquiry|Domestic Parcels|Express';
                    productCategory = 'Domestic Parcels';
                    productSubCategory = 'Express';
                }else if(mailProductsEnquiryType == 'Letter'){
                    typeAndProduct = 'General Enquiry|Domestic Letters|Regular Mail';
                    productCategory = 'Domestic Parcels';
                    productSubCategory = 'Regular Mail';
                }else if(mailProductsEnquiryType == 'Parcel'){
                    typeAndProduct = 'General Enquiry|Domestic Parcels|Parcel Post';
                    productCategory = 'Domestic Parcels';
                    productSubCategory = 'Parcel Post';
                }else if(mailProductsEnquiryType == 'Parcel Collect'){
                    typeAndProduct = 'General Enquiry|Web & Apps|Parcel Collect';
                    productCategory = 'Web & Apps';
                    productSubCategory = 'Parcel Collect';
                }else if(mailProductsEnquiryType == 'PO Box and Private Bag'){
                    typeAndProduct = 'General Enquiry|Post Office & Business Hub Services|PO Boxes & Bags';
                    productCategory = 'Post Office & Business Hub Services';
                    productSubCategory = 'PO Boxes & Bags';
                }else if(mailProductsEnquiryType == 'Tracking'){
                    typeAndProduct = 'General Enquiry|Domestic Parcels|Parcel Post';
                    productCategory = 'Domestic Parcels';
                    productSubCategory = 'Parcel Post';
                    enquirySubType = 'Tracking';
                }else if(mailProductsEnquiryType == 'Transfer to another post office'){
                    typeAndProduct = 'General Enquiry|Web & Apps|Parcel Lockers';
                    productCategory = 'Domestic Parcels';
                    productSubCategory = 'Parcel Post';
                    enquirySubType = 'Item Transfer';
                    recordTypeId = sswDeleveryRecordTypeId;
                }
            }else if(issueDetailsType == 'Post office'){
                typeAndProduct = 'General Enquiry|Post Office & Business Hub Services|Mail Redirection';
                productCategory = 'Post Office & Business Hub Services';
                productSubCategory = 'Mail Redirection';
            }else if(issueDetailsType == 'ID, documents & accounts'){
                if(idDocumentsAccountsEnquiryType == 'ID check'){
                    typeAndProduct = 'General Enquiry|Travel & ID|Identity & document services';
                    productCategory = 'Travel & ID';
                    productSubCategory = 'Identity & document services';
                }else if(idDocumentsAccountsEnquiryType == 'Land title'){
                    typeAndProduct = 'General Enquiry|Travel & ID|Land titles check';
                    productCategory = 'Travel & ID';
                    productSubCategory = 'Land titles check';
                }else if(idDocumentsAccountsEnquiryType == 'Letter'){
                    typeAndProduct = 'General Enquiry|Travel & ID|Land titles check';
                    productCategory = 'Travel & ID';
                    productSubCategory = 'Land titles check';
                }else if(idDocumentsAccountsEnquiryType == 'MyPost general enquiries'){ //DDS-10119 Changed to Mypost general enquires
                    typeAndProduct = 'General Enquiry|Travel & ID|My Post ID card';
                    productCategory = 'Travel & ID';
                    productSubCategory = 'My Post ID card';
                }else if(idDocumentsAccountsEnquiryType == 'Passport'){
                    typeAndProduct = 'General Enquiry|Travel & ID|Passport';
                    productCategory = 'Travel & ID';
                    productSubCategory = 'Passport';
                }else if(idDocumentsAccountsEnquiryType == 'Police check'){
                    typeAndProduct = 'General Enquiry|Travel & ID|Identity & document services';
                    productCategory = 'Travel & ID';
                    productSubCategory = 'Identity & document services';
                }else if(idDocumentsAccountsEnquiryType == 'Tax file number (TFN)'){
                    typeAndProduct = 'General Enquiry|Travel & ID|Tax file number';
                    productCategory = 'Travel & ID';
                    productSubCategory = 'Tax file number';
                }else if(idDocumentsAccountsEnquiryType == 'Delete MyPost account'){
                    typeVal = 'Investigation';
                    typeAndProduct = 'Investigation|Web & Apps|MyPost Deliveries';
                    productCategory = 'Web & Apps';
                    productSubCategory = 'MyPost Deliveries';
                    enquirySubType = 'Account Enquiry';
                }else if(idDocumentsAccountsEnquiryType == 'Other'){
                    typeAndProduct = 'General Enquiry|Travel & ID|Identity & document services';
                    productCategory = 'Travel & ID';
                    productSubCategory = 'Identity & document services';
                }
            }else if(issueDetailsType == 'Online shop'){
                typeAndProduct = 'General Enquiry|Web & Apps|Online shop';
                productCategory = 'Web & Apps';
                productSubCategory = 'Online shop';
            }else if(issueDetailsType == 'Money'){
                productCategory = 'Money & Insurance';
                if(enquiryType == 'Bank@Post'){
                    typeAndProduct = 'General Enquiry|Money & Insurance|Bank@Post';
                    productSubCategory = 'Bank@Post';
                }else if(enquiryType == 'Post Billpay'){
                    typeAndProduct = 'General Enquiry|Money & Insurance|Post BillPay';
                    productSubCategory = 'Post BillPay';
                }
            }
            //-- Building Case object
            Case toBeCreateCase = new Case();
            toBeCreateCase.RecordTypeId =recordTypeId;
            toBeCreateCase.Type=typeVal;
            toBeCreateCase.EnquirySubType__c = enquirySubType;
            toBeCreateCase.Type_and_Product__c=typeAndProduct;
            toBeCreateCase.ProductCategory__c=productCategory;
            toBeCreateCase.ProductSubCategory__c=productSubCategory;
            toBeCreateCase.Subject=subject;
            toBeCreateCase.Origin = origin;
            toBeCreateCase.AllocateToQueue__c = true;
            toBeCreateCase.CHASEnquiryType__c=CHASEnquiryType;
            //Added for guest users
            toBeCreateCase.First_Name__c = givenName;
            toBeCreateCase.Last_Name__c=surname;
            toBeCreateCase.SuppliedEmail=email;
            toBeCreateCase.SuppliedPhone=phone;
            toBeCreateCase.Preferred_Communication_Method__c=contactPreferrence;  // Contact Preference, added by Edmarco on July 2019
            toBeCreateCase.Description = selectedPostOffice ;
            if(transferTrackingNumber != null && issueDetailsType == 'Mail products' && mailProductsEnquiryType == 'Transfer to another post office'){
                toBeCreateCase.ReferenceID__c=transferTrackingNumber;
            }else if(orderTrackingNumber != null && issueDetailsType == 'Online Shop' && madeAndOrder == 'Yes'){
                toBeCreateCase.ReferenceID__c=orderTrackingNumber;
            }
            //-- Change made for roll out of Products and services uplift : defaulting the case type to Feedback, added selectedPostOffice and originalDeliveryAddress to the case description
            if(issueDetailsType == 'Mail products' && mailProductsEnquiryType == 'Transfer to another post office'){
                toBeCreateCase.Type=ChasConstants.FEEDBACK;
                String caseDescription = '';
                if(selectedPostOffice !=null)
                {
                    caseDescription = selectedPostOffice;
                }
                caseDescription = caseDescription + '\n' + originalDeliveryAddress;
                if(isEligibleForMyNetworkAssignment == 'true' && !String.isEmpty(toWcid))
                {
                    caseDescription = caseDescription + '\n' + 'WCC ID: ' + toWcid;
                    //--The flag denotes an evaluation of the network assignment, based on factors evaluated from the service.
                    //19-08-2021: this is now being set only if network assignment actually happens
                    //toBeCreateCase.Automated_Network_Assignment__c = true;
                }
                toBeCreateCase.Description = caseDescription;
            }

            if(deliveryAddressLine1 != null)
                toBeCreateCase.Address4__c = deliveryAddressLine1;
            if(deliveryAddressLine2 !=null)
                toBeCreateCase.Address4Line2__c = deliveryAddressLine2;
            if(deliveryCity !=null)
                toBeCreateCase.Address4Suburb__c =deliveryCity;
            if(deliveryState !=null)
                toBeCreateCase.Address4State__c = deliveryState;
            if(deliveryPostcode !=null)
                toBeCreateCase.Address4Postcode__c = deliveryPostcode;

            //Spingali - ContactId on case is cleared due to routing rules being applied with AllocatetoQueue=true.Explicity set the contactId on case when allocatetoQueue=true
            //if(userContact !=null)
            //toBeCreateCase.ContactId = userContact.ContactId;
            toBeCreateCase.ContactId = getContactId(UserInfo.getUserId());
            //-- mapping Logged in user details
            if(userContactFirstName !=null)
                toBeCreateCase.First_Name__c=userContactFirstName;
            if(userContactLastName !=null)
                toBeCreateCase.Last_Name__c=userContactLastName;
            if(userContactEmail !=null)
                toBeCreateCase.SuppliedEmail=userContactEmail;
            if(userContactPhone !=null)
                toBeCreateCase.SuppliedPhone=userContactPhone;

            //-- Get the wizarddata for product and services conditional case routing
            // 17-08-2021 switched to direct routing
            if(!String.isEmpty(wcid) && !String.isEmpty(wizardData.get('isParcelAwaitingCollection')) && 'true'.equalsIgnoreCase(wizardData.get('isParcelAwaitingCollection'))
                    && !transferToPoProductExclusions.containsIgnoreCase(subProductId)) {
                setDirectRoutingValues(toBeCreateCase, RoutingBypass.NETWORK, wcid);
                /*  ChasCaseAssignment caseAssignment = new ChasCaseAssignment(toBeCreateCase, wcid);
                  Id jobId = System.enqueueJob(caseAssignment);*/

            }
            Database.SaveResult[] results;
            if (toBeCreateCase.Automated_Network_Assignment__c && toBeCreateCase.Network__c != null){
                SharingBypass lSharingBypass = new SharingBypass();
                results = lSharingBypass.insertSObjects(new SObject[] {toBeCreateCase});
            }
            else {
                results = Database.insert(new SObject[] {toBeCreateCase });
            }
            List<CaseComment> comments = new List<CaseComment>();
            comments.add(new CaseComment(CommentBody = commentBody, IsPublished = true));
            //temporarily removed due to inability to make case comment private in authenticated community user context
            //checkNetworkAssigningResult(toBeCreateCase, vComments);

            //-- Parse Case results and create Case Comment
            caseWrapper = ChasUtil.parseInsertedCaseResultsAndCreateComment(results, caseWrapper, comments);
            // checkNetworkAssigningResult(toBeCreateCase);

            /*Case routing logic : Route the case to the myNetwork queue if:
1. Parcel awaiting collection
2. Workcenter id on the corresponding parcel awaiting collection event is not null
3. Exclude certain article sub products
*/


        }catch(Exception ex){
            caseWrapper.caseStatus = 'ERROR';
            System.debug('*** - Error while in createCaseFromProductandServices method ==='+ex);
        }
        return caseWrapper;
    }

}