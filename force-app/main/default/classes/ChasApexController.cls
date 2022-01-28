/**
*
* Description: Create Case with the given params and return the Case Number
*
* History :
* --------------------------------------------------
* 11-Oct-2018 - Nanda Kothamasu - INC1222366  Fixed mapping for the Recipient name and country for Portal cases for Missing Item
* 2019-08-30 hasantha.liyanage@auspost.com.au Modified :
*             - createCaseFromMissingWizard : modified to pass the enqSubtype
*             - searchTrackingNumber : refactored and updated to support help and support missing item search call
* 2019-08-26 hasantha.liyanage@auspost.com.au Modified: set the enquiry type, record type and the typeAndProduct based on the enquirySubType,
*             (use of ternary operator to determine typeAndProduct should be improved by implementing a Map to retrieve the types, change being made this way as a quick change for community uplift 2nd drop)
* 2019-10-30 nathan.franklin@auspost.com.au Added community url method
* 2019-11-04 nathan.franklin@auspost.com.au Updated searchTrackingNumber to use instance of ChasTrackStatus rather than static
* 2019-11-07 nathan.franklin@auspost.com.au Standardised first/last names & address fields for missing item form
* 2019-11-15 hasantha.liyanage@auspost.com.au Append warning message to case Description
* 2020-02-24 gunith.devasurendra@auspost.com.au Enable Product and Services Cases to use the Routing Table (INC1547035)
* 2020-04-03 rufus.solomon@auspost.com.au Added support for essential pharma
* 2020-05-04 saiswetha.pingali@auspost.com.au INC1552781 - Fix to set contactId in CreateCasefromProductandServices as AllocatetoQueue flag is set to true. 
* 2020-06-05 Swati.mogadala@auspost.com.au REQ2150060 - Modified mapping for issue type:'Mail Products'for enquirytype 'Letters'&'Transfers' under'Products and Services'
* 2020-06-16 hara.sahoo@auspost.com.au Incorrect delivery address section added for delivery issue form and issue type values changes in accordance to the UI changes
* 2020-08-03 Snigdha.Sahu@auspost.com.au  INC1610402 - Default ProductCategory to Domestic Parcels for missingItem Cases
* 2020-09-10 hara.sahoo@auspost.com.au Change made for roll out of Safe Drop feature on Missing Items form
1. New One track service implemented in searchTrackingNumber
2. Added has customer seen safe drop image to the case description for network eligible cases
* 2020-09-15 hara.sahoo@auspost.com.au Change made for roll out of Transfer to another PO on Products and Services form.
* 2020-09-30 saiswetha.pingali@auspost.com.au - INC1644988 - Updated clearview codes for cases from Delivery Issues form.
* 2020-10-06 haraprasad.sahoo@auspost.com.au Modified : Change made for roll out of Safe Drop feature - Implements the consignment search API
* 2020-09-15 hara.sahoo@auspost.com.au Change made for roll out of Products and services uplift
* 2020-10-29 madhuri.awasthi@auspost.com.au - INC1644977 - Consumer Help and Support "Delivery Issues" form content changes. 
Note chasDevliveryIssuesWPage01.cmp and chasDevliveryIssuesWPage01Controller.js changes are also required as the Label values are used.
* 2020-10-30 naseer.abbasi@auspost.com.au Setting AllocateToQueue for all forms to assign owner via routing engine
* 2020-11-23 hara.sahoo@auspost.com.au Special handling for 403 response code for missing item form
* 2020-11-24 hara.sahoo@auspost.com.au changes made for roll out of delivery issues network assignment automation
* 2021-01-21 hara.sahoo@auspost.com.au Added guest user details to the case detail like FirstName,LatName,Email and Phone for cases with origin 'Portal'
* 2021-02-23 paul.swarnapandian@auspost.com.au - REQ2361525 - Case assignment flag written to the case comments on enquiries raiased via the Delivery Issues form  	
* 2021-03-18 madhuri.awasthi.awasthi@auspost.com.au - REQ2449698 - Adding Case Comments for Mail Products
* 2021-04-19 hara.sahoo@auspost.com.au Added date calculations for EDD tracking and related contextual thank you pages
* 2021-05-2021 madhuri.awasthi@auspost.com.au COnverting the Date to DD/MM/YYYY
* 2021-05-10 phap.mai@auspost.com.au DDS-5488: When Consignment API return 404 the case type should be 'General Enquiry' & sub-type should be 'Tracking'
* 2021-05-13 hara.sahoo@auspost.com.au: Assign cases raised within EDD or EDD + n days to Reopen Queue
* 2021-05-12 phap.mai@auspost.com.au DDS-5820: Added method to retrieve CHAS_ThankYouPageNextSteps metadata
* 2021-06-28 hara.sahoo@auspost.com.au When no EDD found, call shipment EDD service to get the estimates
* 2021-07-21 hara.sahoo@auspost.com.au Added case comments for items containing sentimental value
* 2021-08-17 alex.volkov@auspost.com.au Switched direct to network and holding queue assignments from queueable to real-time
* 2021-09-03 alex.volkov@auspost.com.au Added Sent To Network Date for Direct-To-Network assignments
* 2021-11-02 phap.mai@auspost.com.au DDS-7977 - Added attributes to indicate if all articles are delivered/safe dropped and optimize case routing accordingly
* 2021-11-04 phap.mai@auspost.com.au - Handled when network assigning failed to find network id or network group
* 2021-12-03 edgarallan.castillo3@auspost.com.au Updated case comment creation to use list of comments
*/
public with sharing class ChasApexController {

    public static ChasApexController newInstance() {
        return (ChasApexController)Application.Utilities.newInstance(ChasApexController.class);
    }

    @AuraEnabled
    public static String retrieveCommunityURL(){
        try {
            return ConnectApi.Communities.getCommunity(Network.getNetworkId()).siteUrl;
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }
    
    @AuraEnabled
    public static CaseWrapper createCaseFromComplaintWizard( Map <String,String> wizardData){
        System.debug('----- createCaseFromComplaintWizard ----- START');
        
        CaseWrapper caseWrapper = new CaseWrapper();
        caseWrapper.caseStatus = 'SUCCESS';
        //String caseNumber ='';
        String trimmedComplaintDetails ='';
        
        String origin = 'Web';
        
        String enquiryType =  (String)wizardData.get('selectedRadioName');
        String trackingID =  (String)wizardData.get('trackingId');
        String complaintDetails =  (String)wizardData.get('complaintDetails');
        String givenName =  (String)wizardData.get('givenName');
        String surname =  (String)wizardData.get('surname');
        String email =  (String)wizardData.get('emailId');
        String phone =  (String)wizardData.get('phone');
        String contactPreferrence =  (String)wizardData.get('contactPreferrence');  // Contact Preference, added by Edmarco on July 2019
        
        //-- logging input values
        System.debug('origin='+origin+', enquiryType='+enquiryType+', complaintDetails='+complaintDetails
                     +', givenName='+givenName+', surname='+surname+', email='+email+', phone='+phone+', contactPreferrence='+contactPreferrence); // Contact Preference, added by Edmarco on July 2019
        
        //-- Trimming the complaint details to 255 chars 
        if(complaintDetails != null){
            if(complaintDetails.trim().length() > 255){
                trimmedComplaintDetails = complaintDetails.substring(0, 255);
            }else{
                trimmedComplaintDetails = complaintDetails;
            }
            
        }
        String recordTypeId;
        String typeAndProduct;
        String enquirySubType;
        String productCategory;
        String productSubCategory;
        String type = 'General Enquiry';
        //String Description;
        String CHASEnquiryType='Complaints & feedback';
        
        //-- Getting recordType Ids
        Id SSSWGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get(ChasConstants.CASE_RECORDTYPE_SSSWGENERALDELIVERY).getRecordTypeId();
        
        enquiryType = enquiryType.trim();
        //-- Assigning the case field based on Enquiry Type
        if(enquiryType != null){
            if(enquiryType == 'Complaint' || enquiryType == 'General Feedback or Compliment'){
                recordTypeId = SSSWGeneralRecordTypeId;
                typeAndProduct = 'General Enquiry|Domestic Parcels|Parcel Post';
                enquirySubType = 'Tracking';
                productCategory = 'Domestic Parcels';
                productSubCategory = 'Parcel Post';
                
                
                
            }else if(enquiryType == 'Privacy concern'){
                recordTypeId = SSSWGeneralRecordTypeId;
                typeAndProduct = 'General Enquiry|Travel & ID|My Post ID card';
                enquirySubType = 'Product & service information';
                productCategory = 'Travel & ID';
                productSubCategory = 'My Post ID card';
                
                
            }
        }
        
        try {
            // NM Removed 13/08/2018 - no longer using.
            //Blob b = Crypto.GenerateAESKey(128);
            //String h = EncodingUtil.convertToHex(b);
            //String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-'  + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
            
            // NM Removed 13/08/2018 - no longer using.
            //Case caseReference = new Case(ChasExternalId__c=guid);
            
            String commentBody= 'Enquiry Type : ' + enquiryType + '\n' +     //-- Jansi :Replaced 'enquirySubType' with 'enquiryType' - July 03 2018
                'Details : ' + complaintDetails + '\n' +                               //-- Jansi :Replaced 'Case Comment =' with 'Detail :' - July 03 2018
                'Contact Preference : ' + contactPreferrence; // Contact Preference, added by Edmarco on July 2019
            
            System.debug('***CommentBody input = '+ commentBody);
            
            //--  Building Case object record
            Case toBeCreateCase = new Case(// ChasExternalId__c=guid,
                //AllocateToQueue__c=false,
                RecordTypeId=recordTypeId,
                Origin=origin,
                ReferenceID__c=trackingID,
                First_Name__c = givenName,
                Last_Name__c=surname,
                SuppliedEmail=email,
                SuppliedPhone=phone,
                Preferred_Communication_Method__c=contactPreferrence, // Contact Preference, added by Edmarco on July 2019
                Subject=trimmedComplaintDetails,
                Type=type,
                AllocateToQueue__c = true,
                ContactId = getContactId(UserInfo.getUserId()),
                Type_and_Product__c = typeAndProduct,
                EnquirySubType__c = enquirySubType,
                ProductCategory__c = productCategory,
                ProductSubCategory__c = productSubCategory,
                CHASEnquiryType__c = CHASEnquiryType,
                DescriptionofContents__c = trimmedComplaintDetails);
            
            System.debug('*** About to create case - toBeCreateCase input = '+toBeCreateCase);
            
            //-- Crating Case
            Database.SaveResult[] results = Database.insert(new SObject[] {toBeCreateCase });
            //-- Parse Case results and create Case Comment
            List<CaseComment> comments = new List<CaseComment>();
            comments.add(new CaseComment(CommentBody = commentBody, IsPublished = true));
            caseWrapper = ChasUtil.parseInsertedCaseResultsAndCreateComment(results, caseWrapper, comments);
            
        }catch(Exception ex){
            caseWrapper.caseStatus = 'ERROR';
            System.debug('*** - Error while creating Case/CaseComment/retrieving CaseID ==='+ex);
        }
        System.debug('----- createCaseFromComplaintWizard ----- END');
        return caseWrapper ;
        
    }
    
        /**
* This method will create Case for Missing Item Wizard
* */
    @AuraEnabled
    public static CaseWrapper createCaseFromMissingWizard( Map <String,String> wizardData, Map <String,String> authUserData ){
        CaseWrapper caseWrapper = new CaseWrapper();
        caseWrapper.caseStatus = 'SUCCESS';
        
         try{
            
            String typeAndProduct = null;
            String  productSubCategory= null;
            String subject = null;
            String caseOriginator = null;
            
            String type = ChasConstants.INVESTIGATION;
            //--        Getting recordType Id
            String recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ChasConstants.CASE_RECORDTYPE_SSSWDELIVERY).getRecordTypeId();
            String enquirySubType = wizardData.get('enqSubtype'); //Enquiry subtype is decided in the searchTrackingNumber method when deciding the tracking message
            Datetime EDDPlusBusinessDays = !String.isEmpty(wizardData.get('deliveredByDateToUntil')) ? Date.valueOf(wizardData.get('deliveredByDateToUntil')) : !String.isEmpty(wizardData.get('deliveredByDatePlusBusinessDays'))? Date.valueOf(wizardData.get('deliveredByDatePlusBusinessDays')): null;
            // cases which are raised within EDD or EDD plus business days, plus dont have a delivered scan are eligible for hold
            String isEligibleForHold = '';
            // DDS-5273: article that contains pharma should not be held
             if ('No'.equalsIgnoreCase(wizardData.get('selectedRadio4Name'))) {
                 if (String.isEmpty(wizardData.get('latestDeliveredScanWcid')) && ((!String.isEmpty(wizardData.get('isEnquiryDateWithinEDDPlusBusinessdays')) && 'true'.equalsIgnoreCase(wizardData.get('isEnquiryDateWithinEDDPlusBusinessdays'))) ||
                         !String.isEmpty(wizardData.get('isEnquiryDateWithinEDD')) && 'true'.equalsIgnoreCase(wizardData.get('isEnquiryDateWithinEDD')))) {
                     // avoid cases for which the case reopen date falls on the case creation date
                     if (EDDPlusBusinessDays != null && EDDPlusBusinessDays != System.today()) {
                         isEligibleForHold = 'true';
                     }
                 }
             }
            // if the enquiry subtype is tracking the enquiry type should be set to general enquiry, and the record type has to be General Enquiry
            // exclude cases which are eligible for hold
            if (ChasConstants.ENQ_SUB_TYPE_TRACKING.equals(enquirySubType)) {
                if(!String.isEmpty(isEligibleForHold) && 'true'.equalsIgnoreCase(isEligibleForHold)){
                    enquirySubType = ChasConstants.ENQ_SUB_TYPE_MISSING;
                } else {
                    type = ChasConstants.GENERAL_ENQUIRY;
                    recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ChasConstants.CASE_RECORDTYPE_SSSWGENERALDELIVERY).getRecordTypeId();
                }
                
            }    
            // if the enquiry subtype is tracking the enquiry type should be set to general enquiry, and the record type has to be General Enquiry
            if (ChasConstants.ENQ_SUB_TYPE_TRACKING.equals(enquirySubType)) {
                type = ChasConstants.GENERAL_ENQUIRY;
                recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ChasConstants.CASE_RECORDTYPE_SSSWGENERALDELIVERY).getRecordTypeId();
            }
            
            //-- Getting all field details from WizardData
            String isEligibleForMyNetwork = wizardData.get('isEligibleForMyNetworkAssignment');
            // if the case is eligible for my network , assign the type to INVESTIGATION and enquirySubType to Disputed delivery scan
            if(isEligibleForMyNetwork == 'true')
            {
                type = ChasConstants.INVESTIGATION;
                enquirySubType = ChasConstants.ENQ_SUB_TYPE_DISPUTED;
            }
            String referenceId = wizardData.get('trackingId');
            String productCategory= wizardData.get('selectedRadio2Name');
            String datePostedStr= wizardData.get('itemSentDate');
            // if EDD range is available consider the "deliveredByDateTo" as EDD, otherwise consider deliveredByDateOrEDD
            String EDD= !String.isEmpty(wizardData.get('deliveredByDateTo'))? wizardData.get('deliveredByDateTo'): wizardData.get('deliveredByDateOrEDD');
            // RSolomon 2nd Apr: Sources value of radio button on form, that indicates if parcel contains essential medication
            String containsPharma = ('yes'.equalsIgnoreCase(wizardData.get('selectedRadio4Name')) ? 'True' : 'False');
            // Gets the field value of the sentimental field on the LOMI forms
            String containsSentimentalValue = ('yes'.equalsIgnoreCase(wizardData.get('selectedSentiValue')) ? 'Yes' : 'No');
            
            // authenticated user details
            String userContactEmail = authUserData.get('userContactEmail');
            String userContactFirstName = (!String.isEmpty(authUserData.get('userContactFirstName')) ? authUserData.get('userContactFirstName') : '');
            String userContactLastName = (!String.isEmpty(authUserData.get('userContactLastName')) ? authUserData.get('userContactLastName') : '');
            
            String senderAddLine1 = wizardData.get('senderAddressLine1');
            String senderAddLine2 = wizardData.get('senderAddressLine2');
            String senderCity = wizardData.get('senderCity');
            String senderState = wizardData.get('senderState');
            String senderPostcode = wizardData.get('senderPostcode');
            String senderCountry = wizardData.get('senderCountry');
            
            String deliveryOrRecipientAddLine1 = wizardData.get('recipientAddressLine1');
            String deliveryOrRecipientAddLine2 = wizardData.get('recipientAddressLine2');
            String deliveryOrRecipientCity = wizardData.get('recipientCity');
            String deliveryOrRecipientState = wizardData.get('recipientState');
            String deliveryOrRecipientPostcode = wizardData.get('recipientPostcode');
            String deliveryOrRecipientCountry = wizardData.get('recipientCountry');
            String valuesOfContents = wizardData.get('itemValue');
            String suppliedPhone = authUserData.get('userContactPhone');
            String CHASEnquiryType = 'Missing or lost item';
            String issueDetails = wizardData.get('issueDetails');
            String contactPreferrence = (String)wizardData.get('contactPreferrence'); // Contact Preference, added by Edmarco on July 2019
            
            // setup which names to place on the case
            // the recipientGivenName/Surname fields will be populated if the 'Are you Recipient or Sender' question = 'Sender'
            // otherwise we use the authenticated users first/last name
            String senderFirstName = '';
            String senderLastName = '';
            String senderName = '';
            String senderEmail = '';
            String deliveryOrRecipientFirstName = '';
            String deliveryOrRecipientLastName = '';
            String deliveryOrRecipientName = '';
            String deliveryOrRecipientEmail = '';
            
            //Added for guest users
            String givenName =  (String)wizardData.get('givenName');
            String surname =  (String)wizardData.get('surname');
            String email =  (String)wizardData.get('emailId');
            String phone =  (String)wizardData.get('phone');

            if(wizardData.get('selectedRadio1Name') == ChasConstants.RECIPIENT) {
                deliveryOrRecipientFirstName = userContactFirstName;
                deliveryOrRecipientLastName = userContactLastName;
                deliveryOrRecipientName = (deliveryOrRecipientFirstName + ' ' + deliveryOrRecipientLastName).trim();
                deliveryOrRecipientEmail = userContactEmail;
            } else if(wizardData.get('selectedRadio1Name') == ChasConstants.SENDER) {
                senderFirstName = userContactFirstName;
                senderLastName = userContactLastName;
                senderName = (userContactFirstName + ' ' + userContactLastName).trim();
                senderEmail = userContactEmail;
                deliveryOrRecipientFirstName = (!String.isEmpty(wizardData.get('recipientGivenName')) ? wizardData.get('recipientGivenName') : '');
                deliveryOrRecipientLastName = (!String.isEmpty(wizardData.get('recipientSurname')) ? wizardData.get('recipientSurname') : '');
                deliveryOrRecipientName = (deliveryOrRecipientFirstName + ' ' + deliveryOrRecipientLastName).trim();
                deliveryOrRecipientEmail = '';
            }
            
            //--Converting input datePostedStr string to SF acceptable Date
            Date convertedPostedDate = null;
            String datePostedFormatted = '';
            if(datePostedStr != null && datePostedStr.trim().length() > 0 ){
                String convertedDateStr = ChasUtil.convertToSFDateStrFormat(datePostedStr);
                if(convertedDateStr !=null){
                    convertedPostedDate = Date.valueOf(convertedDateStr);
                     //Format change from MM/DD/YYYY to DD/MM/YYYY 
                     Date datePosted = Date.valueOf(datePostedStr);
                     datePostedFormatted = datePosted.day() + '/' + datePosted.month() + '/' + datePosted.year();
                }else{
                    caseWrapper.caseStatus = 'ERROR';                                                    //then not allowing to create case without date.
                    return caseWrapper;
                }
            }
            //--Converting input EDD string to SF acceptable Date
            Date convertedEDD = null;
            if(EDD != null && EDD.trim().length() > 0 ){
                String convertedEDDStr = ChasUtil.convertToSFDateStrFormat(EDD);
                if(convertedEDDStr !=null){
                    convertedEDD = Date.valueOf(convertedEDDStr);
                }else{
                    caseWrapper.caseStatus = 'ERROR';                                                    //then not allowing to create case without date.
                    return caseWrapper;
                }
            }
            String complaintDetails = wizardData.get('complaintDetails');
            String issueDetailsDisplayText = '';
            if(!String.isEmpty(complaintDetails)) {
                issueDetailsDisplayText = '\n' + 'Issue Details : ' + complaintDetails;
            }
            
            String commentBody= null;
            if(valuesOfContents != null && valuesOfContents != ''){
                commentBody ='Issue Type : Missing or Lost item'  + '\n' +
                    'Is the item a parcel or letter : ' + wizardData.get('selectedRadio2Name')+ '\n' +
                    'Domestic or International : ' + wizardData.get('senderOrRecipientType')+ '\n' +
                    'Date posted : ' + datePostedFormatted+ '\n' +
                    // RSolomon 2nd Apr: To display in Case comments if the parcel has essential medication
                    'Does the item contain essential medication : ' + wizardData.get('selectedRadio4Name')+ '\n' +
                    // To display in case comments if the parcel has sentimental value
                    'Is the item urgent, sentimental or high value? : ' + containsSentimentalValue + '\n' +
                    'Description of contents : ' + issueDetails+ '\n' +'Value of contents : ' + valuesOfContents + '\n' +
                    'Contact Preference : ' + contactPreferrence // Contact Preference, added by Edmarco on July 2019
                    + issueDetailsDisplayText + '\n';
                // Change made for roll out of Safe Drop feature on Missing Items form : add reason for enquiry to the case comments
                if(wizardData.get('reasonForEnquiry') != null)
                {
                    commentBody = commentBody + 'Reason for enquiry : ' + wizardData.get('reasonForEnquiry')+ '\n';
                }
                // Change made for roll out of Safe Drop feature on Missing Items form : add flag to indicate whether customer has seen safedrop image? to the case description
                if(wizardData.get('hasCustomerSeenSafeDrop') == 'true')
                {
                    commentBody = commentBody + 'Has customer seen safedrop image : ' + 'Yes' + '\n';
                } else
                {
                    commentBody = commentBody + 'Has customer seen safedrop image : ' + 'No' + '\n';
                }
                // Change made for roll out of Safe Drop feature on Missing Items form : add flag to indicate whether the case was eligible for network assignment
                if(isEligibleForMyNetwork == 'true')
                {
                    commentBody = commentBody + 'Is eligible for network assignment : ' + 'Yes';
                } else
                {
                    commentBody = commentBody + 'Is eligible for network assignment : ' + 'No';
                }
            }else{
                commentBody ='Issue Type : Missing or Lost item'  + '\n' +
                    'Is the item a parcel or letter : ' + wizardData.get('selectedRadio2Name')+ '\n' +
                    'Domestic or International : ' + wizardData.get('senderOrRecipientType')+ '\n' +
                    'Date posted : ' + datePostedFormatted + '\n' +
                    // RSolomon 2nd Apr: To display in Case comments if the parcel has essential medication
                    'Does the item contain essential medication : ' + wizardData.get('selectedRadio4Name')+ '\n' +
                    // To display in case comments if the parcel has sentimental value
                    'Is the item urgent, sentimental or high value? : ' + containsSentimentalValue + '\n' +
                    'Description of contents : ' + issueDetails + '\n' +
                    'Contact Preference : ' + contactPreferrence // Contact Preference, added by Edmarco on July 2019
                    + issueDetailsDisplayText + '\n';
                // Change made for roll out of Safe Drop feature on Missing Items form : add reason for enquiry to the case comments
                if(wizardData.get('reasonForEnquiry') != null)
                {
                    commentBody = commentBody + 'Reason for enquiry : ' + wizardData.get('reasonForEnquiry')+ '\n';
                }
                // Change made for roll out of Safe Drop feature on Missing Items form : add flag to indicate whether customer has seen safedrop image? to the case description
                if(wizardData.get('hasCustomerSeenSafeDrop') == 'true')
                {
                    commentBody = commentBody + 'Has customer seen safedrop image : ' + 'Yes' + '\n';
                } else
                {
                    commentBody = commentBody + 'Has customer seen safedrop image : ' + 'No' + '\n';
                }
                // Change made for roll out of Safe Drop feature on Missing Items form : add flag to indicate whether the case was eligible for network assignment
                if(isEligibleForMyNetwork == 'true')
                {
                    commentBody = commentBody + 'Is eligible for network assignment : ' + 'Yes';
                } else
                {
                    commentBody = commentBody + 'Is eligible for network assignment : ' + 'No';
                }
            }
            // write to case comments if the case was held
            if(isEligibleForHold == 'true')
            {
                commentBody = commentBody + '\n'+ Label.ChasCaseEligibleForHoldMessage;
            }
            // write to case comments if edd was estimated
            if(wizardData.get('isEDDEstimated') == 'true'){
                commentBody = commentBody + '\n'+ 'Estimated EDD: Yes';
            }
            
            //-- Subject : Trimming the complaint details to 255 chars
            if(wizardData.get('issueDetails') != null){
                if(wizardData.get('issueDetails').trim().length() > 255){
                    subject = wizardData.get('issueDetails').substring(0, 255);
                }else{
                    subject = wizardData.get('issueDetails');
                }
            }
            
            //-- Assigning Case Originator
            if(wizardData.get('selectedRadio1Name') !=null){
                if(wizardData.get('selectedRadio1Name') == ChasConstants.RECIPIENT){
                    caseOriginator = ChasConstants.ADDRESSE;
                }else{
                    caseOriginator = ChasConstants.SENDER;
                }
            }
            
            //-- Assigning 'typeAndProduct', 'productCategory', 'productSubCategory'
            
            //INC1610402 : Changing the default ProductCategory to Domestic Parcels
            productCategory = ChasConstants.DOMESTIC_PARCELS;
            
            //-- If Item Type is Domestic
            if(wizardData.get('senderOrRecipientType') == ChasConstants.ITEM_TYPE_DOMESTIC){
                
                //-- If 'Item' is 'Parcel'
                if(wizardData.get('selectedRadio2Name') ==ChasConstants.PARCEL){
                    //productCategory = ChasConstants.DOMESTIC_PARCELS;
                    
                    //-- If 'item sent' is through 'Regular Post'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.REGULAR_POST){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_DOMESTIC_PARCELS_PLUS_PARCEL_POST : ChasConstants.INVESTIGATION_PLUS_DOMESTIC_PARCELS_PLUS_PARCEL_POST);
                        productSubCategory = ChasConstants.PARCEL_POST;
                    }
                    
                    //-- If 'item sent' is through 'Express Post'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.EXPRESS_POST){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_DOMESTIC_PARCELS_PLUS_EXPRESS : ChasConstants.INVESTIGATION_PLUS_DOMESTIC_PARCELS_PLUS_EXPRESS);
                        productSubCategory =  ChasConstants.EXPRESS;
                    }
                    
                }
                
                
                //-- If 'Item' is 'Letter'
                if(wizardData.get('selectedRadio2Name') == ChasConstants.LETTER){
                    productCategory = ChasConstants.DOMESTIC_LETTERS;
                    
                    //-- If 'item sent' is through 'Regular Post'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.REGULAR_POST){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_DOMESTIC_LETTERS_PLUS_REGULAR_EMAIL : ChasConstants.INVESTIGATION_PLUS_DOMESTIC_LETTERS_PLUS_REGULAR_EMAIL);
                        productSubCategory = ChasConstants.REGULAR_MAIL;
                    }
                    
                    //-- If 'item sent' is through 'Express Post'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.EXPRESS_POST){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_DOMESTIC_LETTERS_PLUS_EXPRESS_POST : ChasConstants.INVESTIGATION_PLUS_DOMESTIC_LETTERS_PLUS_EXPRESS_POST);
                        productSubCategory = ChasConstants.EXPRESS_POST;
                    }
                    
                    //-- If 'item sent' is through 'Registered Post'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.REGISTERED_POST){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_DOMESTIC_LETTERS_PLUS_REGISTERED_POST : ChasConstants.INVESTIGATION_PLUS_DOMESTIC_LETTERS_PLUS_REGISTERED_POST);
                        productSubCategory = ChasConstants.REGISTERED_POST;
                    }
                    
                }
                
            } //-- If Item Type is International
            else if(wizardData.get('senderOrRecipientType') == ChasConstants.ITEM_TYPE_INTERNATIONAL){
                //-- If 'Item' is 'Parcel'
                if(wizardData.get('selectedRadio2Name') == ChasConstants.PARCEL){
                    productCategory = ChasConstants.INTERNATIONAL_PARCELS;
                    
                    //-- If 'item sent' is through 'Courier'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.COURIER){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_COURIER : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_COURIER);
                        productSubCategory = ChasConstants.INTERNATIONAL_COURIER ;
                    }
                    
                    //-- If 'item sent' is through 'Express'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.EXPRESS){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_EXPRESS : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_EXPRESS);
                        productSubCategory = ChasConstants.INTERNATIONAL_EXPRESS;
                    }
                    
                    //-- If 'item sent' is through 'Standard'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.STANDARD){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_STANDARD : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_STANDARD);
                        productSubCategory = ChasConstants.INTERNATIONAL_STANDARD;
                    }
                    
                    //-- If 'item sent' is through 'Economy Air'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.ECONOMY_AIR){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_ECONOMY_AIR_UNDER_2_KG : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_ECONOMY_AIR_UNDER_2_KG);
                        productSubCategory = ChasConstants.ECONOMY_AIR_UNDER_2_KG;
                    }
                    
                    //-- If 'item sent' is through 'Economy Sea'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.ECONOMY_SEA){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_ECONOMY_SEA_OVER_2_KG : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_ECONOMY_SEA_OVER_2_KG);
                        productSubCategory = ChasConstants.ECONOMY_SEA_OVER_2_KG;
                    }
                    
                }
                
                //-- If 'Item' is 'Letter'
                if(wizardData.get('selectedRadio2Name') == ChasConstants.LETTER){
                    productCategory = ChasConstants.INTERNATIONAL_LETTERS;
                    
                    //-- If 'item sent' is through 'Courier'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.COURIER){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_LETTERS_PLUS_INTERNATIONAL_COURIER : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_LETTERS_PLUS_INTERNATIONAL_COURIER);
                        productSubCategory = ChasConstants.INTERNATIONAL_COURIER;
                    }
                    
                    //-- If 'item sent' is through 'Express'
                    if(wizardData.get('selectedRadio3Name') ==  ChasConstants.EXPRESS){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_LETTERS_PLUS_INTERNATIONAL_EXPRESS : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_LETTERS_PLUS_INTERNATIONAL_EXPRESS);
                        productSubCategory = ChasConstants.INTERNATIONAL_EXPRESS;
                    }
                    
                    //-- If 'item sent' is through 'Standard'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.STANDARD){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_STANDARD : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_STANDARD);
                        productSubCategory = ChasConstants.INTERNATIONAL_STANDARD;
                    }
                    
                    //-- If 'item sent' is through 'Economy Air'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.ECONOMY_AIR){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_LETTERS_PLUS_ECONOMY_AIR_UNDER_500_GM : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_LETTERS_PLUS_ECONOMY_AIR_UNDER_500_GM);
                        productSubCategory = ChasConstants.ECONOMY_AIR_UNDER_500_GM;
                    }
                    
                    //-- If 'item sent' is through 'Economy Sea'
                    if(wizardData.get('selectedRadio3Name') == ChasConstants.ECONOMY_SEA){
                        typeAndProduct = (type == ChasConstants.GENERAL_ENQUIRY ?
                                          ChasConstants.GENERAL_ENQUIRY_PLUS_INTERNATIONAL_LETTERS_PLUS_ECONOMY_AIR_UNDER_500_GM : ChasConstants.INVESTIGATION_PLUS_INTERNATIONAL_LETTERS_PLUS_ECONOMY_AIR_UNDER_500_GM);
                        productSubCategory = ChasConstants.ECONOMY_AIR_UNDER_500_GM;                   //-- iS this "ChasConstants.ECONOMY_SEA_UNDER_500_GM"check with Matt
                    }
                    
                }
            }
            
            Case toBeCreateCase = new Case();
            toBeCreateCase.RecordTypeId = recordTypeId;
            toBeCreateCase.Type = type;
            toBeCreateCase.Type_and_Product__c = typeAndProduct;
            toBeCreateCase.EnquirySubType__c = enquirySubType;
            toBeCreateCase.ProductCategory__c = productCategory;
            toBeCreateCase.ProductSubCategory__c = productSubCategory;
            toBeCreateCase.Subject = subject;
            toBeCreateCase.CaseOriginator__c = caseOriginator;
            toBeCreateCase.CHASEnquiryType__c = CHASEnquiryType;
            toBeCreateCase.Origin = 'Portal';
            toBeCreateCase.AllocateToQueue__c = true;
            toBeCreateCase.DDC_Receiver_First_Name__c = deliveryOrRecipientFirstName; //userContactFirstName;  INC1222366
            toBeCreateCase.DDC_Receiver_Last_Name__c = deliveryOrRecipientLastName; //userContactLastName;   INC1222366
            toBeCreateCase.ContactId = getContactId(UserInfo.getUserId());
            //Added FirstName,LatName,Email,Phone for guest users*/
            toBeCreateCase.First_Name__c = givenName;
            toBeCreateCase.Last_Name__c=surname;
            toBeCreateCase.SuppliedPhone = suppliedPhone != null ? suppliedPhone : phone;
            toBeCreateCase.SuppliedEmail = userContactEmail != null ? userContactEmail : email;
            //toBeCreateCase.SuppliedPhone = suppliedPhone;
            //toBeCreateCase.SuppliedEmail = userContactEmail;
            toBeCreateCase.ReferenceID__c = referenceId;   // Added by Jansi Aug 08 - for issue - 756
            toBeCreateCase.Preferred_Communication_Method__c=contactPreferrence; // Contact Preference, added by Edmarco on July 2019
            toBeCreateCase.DescriptionofContents__c = subject;
            // RSolomon 2nd Apr: Update value for whether parcel contains essential pharma
            if(Boolean.valueOf(containsPharma)) {
                toBeCreateCase.Priority = 'High';
            }
            
            // 2019/10/09 - Issue Description to be set as Case Description, warning message to case reader is added if the user entered something in the issue details section
            if(!String.isEmpty(complaintDetails)) {
                toBeCreateCase.Description = Label.HS_Issue_Details_Warning +'\n\n'+ complaintDetails + '\n\n';
                // Change made for roll out of Safe Drop feature on Missing Items form : add reason for enquiry to the case description
                if(wizardData.get('reasonForEnquiry') != null)
                {
                    toBeCreateCase.Description = toBeCreateCase.Description + 'Reason for enquiry : ' + wizardData.get('reasonForEnquiry') + '\n';
                }
                // Change made for roll out of Safe Drop feature on Missing Items form : has customer seen safe drop image to the case description
                if(isEligibleForMyNetwork == 'true')
                {
                    if(wizardData.get('hasCustomerSeenSafeDrop') == 'true')
                    {
                        toBeCreateCase.Description = toBeCreateCase.Description +'Has customer seen safedrop image : ' + 'Yes' + '\n';
                    } else
                    {
                        toBeCreateCase.Description = toBeCreateCase.Description +'Has customer seen safedrop image : ' + 'No' + '\n';
                    }
                    
                }
            }
            
            if(convertedPostedDate !=null){
                toBeCreateCase.DatePosted__c = convertedPostedDate;
            }
            if(convertedEDD !=null){
                toBeCreateCase.EstimatedDelivery__c = convertedEDD;
            }
            toBeCreateCase.Address4__c = deliveryOrRecipientAddLine1;
            
            if(deliveryOrRecipientAddLine2 !=null){
                toBeCreateCase.Address4Line2__c = deliveryOrRecipientAddLine2;
            }
            if(deliveryOrRecipientAddLine2 !=null){
                toBeCreateCase.Address4Line2__c = deliveryOrRecipientAddLine2;
            }
            if(deliveryOrRecipientCity !=null){
                toBeCreateCase.Address4Suburb__c = deliveryOrRecipientCity;
            }
            if(deliveryOrRecipientState !=null){
                toBeCreateCase.Address4State__c = deliveryOrRecipientState;
            }
            if(deliveryOrRecipientPostcode !=null){
                toBeCreateCase.Address4Postcode__c = deliveryOrRecipientPostcode;
            }
            if(valuesOfContents !=null && valuesOfContents != ''){
                toBeCreateCase.ValueofContents__c = Decimal.valueOf(valuesOfContents);
            }
            toBeCreateCase.Address3__c = senderAddLine1;
            
            if(senderAddLine2 !=null){
                toBeCreateCase.Address3Line2__c = senderAddLine2;
            }
            if(senderCity !=null){
                toBeCreateCase.Address3Suburb__c =senderCity;
            }
            if(senderState !=null){
                toBeCreateCase.Address3State__c = senderState;
            }
            if(senderPostcode !=null){
                toBeCreateCase.Address3Postcode__c = senderPostcode;
            }
            
            // 2019-11-07 - Change to set the Sender/Addressee details into their correct fields right from the start
            //                  Previously the contact centre would manually copy these details from the 'portal' address fields into the sender/addressee
            //                  Setting these fields directly here saves time in CCC
            toBeCreateCase.Primary_Name__c = senderName;
            toBeCreateCase.Primary_Email__c = senderEmail;
            toBeCreateCase.Address1Line1__c = senderAddLine1;
            toBeCreateCase.Address1line2__c = senderAddLine2;
            toBeCreateCase.Address1Suburb__c = senderCity;
            toBeCreateCase.Address1State__c = senderState;
            toBeCreateCase.Address1Postcode__c = senderPostcode;
            toBeCreateCase.Address1Country__c = senderCountry;
            
            String address1 = senderAddLine1 == null ? '' : ' ' + senderAddLine1;
            address1 += senderAddLine2 == null ? '' : ' ' + senderAddLine2;
            address1 += senderCity == null ? '' : ' ' + senderCity;
            address1 += senderState == null ? '' : ' ' + senderState;
            address1 += senderPostcode == null ? '' : ' ' + senderPostcode;
            address1 += senderCountry == null ? '' : ' ' + senderCountry;
            
            address1 = address1.trim();
            if(address1.length() < 255) {
                toBeCreateCase.Address1__c = address1;
            } else {
                toBeCreateCase.Address1__c = address1.substring(0, 255);
            }
            
            toBeCreateCase.Secondary_Contact__c = deliveryOrRecipientName;
            toBeCreateCase.SecondaryEmail__c = deliveryOrRecipientEmail;
            toBeCreateCase.Address2Line1__c = deliveryOrRecipientAddLine1;
            toBeCreateCase.Address2line2__c = deliveryOrRecipientAddLine2;
            toBeCreateCase.Address2Suburb__c = deliveryOrRecipientCity;
            toBeCreateCase.Address2State__c = deliveryOrRecipientState;
            toBeCreateCase.Address2Postcode__c = deliveryOrRecipientPostcode;
            toBeCreateCase.Address2Country__c = deliveryOrRecipientCountry;
            
            String address2 = deliveryOrRecipientAddLine1 == null ? '' : ' ' + deliveryOrRecipientAddLine1;
            address2 += deliveryOrRecipientAddLine2 == null ? '' : ' ' + deliveryOrRecipientAddLine2;
            address2 += deliveryOrRecipientCity == null ? '' : ' ' + deliveryOrRecipientCity;
            address2 += deliveryOrRecipientState == null ? '' : ' ' + deliveryOrRecipientState;
            address2 += deliveryOrRecipientPostcode == null ? '' : ' ' + deliveryOrRecipientPostcode;
            address2 += deliveryOrRecipientCountry == null ? '' : ' ' + deliveryOrRecipientCountry;
            
            address2 = address2.trim();
            if (address2.length() < 255) {
                toBeCreateCase.Address2__c = address2;
             }
            else
            {
                toBeCreateCase.Address2__c = address2.substring(0, 255);
            }
            
            toBeCreateCase.Address3Country__c = senderCountry;
            toBeCreateCase.Address4Country__c = deliveryOrRecipientCountry;   // Added newly INC1222366

            String wcid = (String) wizardData.get('wcid');

            // DDS-7977: consignment handling optimize
           // Boolean allArticlesSuccessed = wizardData.get('allArticlesSuccessed') != null? Boolean.valueOf(wizardData.get('allArticlesSuccessed')) : false;
           // Boolean allArticlesNotSuccessed = wizardData.get('allArticlesNotSuccessed') != null? Boolean.valueOf(wizardData.get('allArticlesNotSuccessed')) : true;

            // certain cases can be auto allocated from H&S directly to MyNetwork
            // this criteria is assessed here and if the criteria matches then the case is created and then updated to point to mynetwork
            // 17-08-2021 Updated to assign directly on creation
            if(!String.isEmpty(wcid) && !String.isEmpty(wizardData.get('isEligibleForMyNetworkAssignment')) && 'true'.equalsIgnoreCase(wizardData.get('isEligibleForMyNetworkAssignment')))
            {
                setDirectRoutingValues(toBeCreateCase, RoutingBypass.NETWORK, wcid);
            }

            //if eligible for hold, run the async process to update case details on case creation to put it ON HOLD and set a Reopen date
            // 17-08-2021 switched to direct routing
            if(!String.isEmpty(isEligibleForHold) && 'true'.equalsIgnoreCase(isEligibleForHold))
            {
                setDirectRoutingValues(toBeCreateCase, RoutingBypass.HOLD, null);
            }

            
			Database.SaveResult[] results;
			if (toBeCreateCase.Automated_Network_Assignment__c && toBeCreateCase.Network__c != null){
				SharingBypass lSharingBypass = new SharingBypass();
				results = lSharingBypass.insertSObjects(new SObject[] {toBeCreateCase});
			}
			else {
				results = Database.insert(new SObject[] {toBeCreateCase });
			}
        List<CaseComment> vComments = new List<CaseComment>();
        vComments.add(new CaseComment(CommentBody = commentBody, IsPublished = true));
        checkNetworkAssigningResult(toBeCreateCase, vComments);
      //-- Parse Case results and create Case Comment
        caseWrapper = ChasUtil.parseInsertedCaseResultsAndCreateComment(results, caseWrapper, vComments);

            // checkNetworkAssigningResult(toBeCreateCase);
            
            //            // 2019/09/30 start a queueable to assign the Network if the criteria matches
            //            String eddStatus = (String) wizardData.get('eddStatus');
            //            System.debug('ChasApexController eddStatus = ' + eddStatus + ', wcid = ' + wcid);
            //if( ChasCaseAssignment.VALID_STATUSES.indexOf(eddStatus) >= 0 && (wcid != null && wcid != '') && (String.isEmpty(wizardData.get('isReturnToSender')) || String.valueOf(wizardData.get('isReturnToSender')) == 'false')) {
            
         } catch (Exception ex) {
             System.debug('Error on case creation :: ' + ex.getMessage());
             caseWrapper.caseStatus = 'ERROR';
         }
        return caseWrapper;
    }
    
    /**
* This method will create Case for mail redirect and hold
* */
    @AuraEnabled
    public static CaseWrapper createCaseFromMailRedirectAndHold( Map <String,Object> wizardData, Map <String,String> authUserData ){
        System.debug('----- createCaseFromMailRedirectAndHold ----- START');
        
        CaseWrapper caseWrapper = new CaseWrapper();
        caseWrapper.caseStatus = 'SUCCESS';
        
        try{
            System.debug('wizardData='+wizardData);
            
            //-- Getting recordType Id
            String recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().
                get(ChasConstants.CASE_RECORDTYPE_SSSWDELIVERY).getRecordTypeId();
            
            //-- defaulting
            String typeVal = ChasConstants.FEEDBACK;
            String enquirySubType= ChasConstants.MAIL_NOT_BEING_REDIRECTED_OR_HELD;
            
            String tpeAndProduct = null;
            String productCategory = null;
            String productSubCategory = null;
            String subject = null;
            String defaultFormGivenName = null;
            String defaultFormSurName = null;
            String origin = 'Portal';
            String CHASEnquiryType = 'Mail redirection & hold';
            
            //-- Getting additional person details
            List<Object> persons = (List<Object>) wizardData.get('household');
            System.debug('persons==='+persons);
            Map<Integer,String> personDetails = new  Map<Integer,String>();
            Integer count = 0;
            for(Object person :persons){
                Map<Object,Object> eachPersonStr = (Map<Object,Object>)person;
                if(count == 0){
                    defaultFormGivenName = (String)eachPersonStr.get('givenName');
                    defaultFormSurName = (String)eachPersonStr.get('surname');
                }else{
                    personDetails.put(count,(String)eachPersonStr.get('givenName')+'~~~~'+(String)eachPersonStr.get('surname'));
                }
                count = count+1;
            }
            System.debug('personDetails==='+personDetails);
            
            //-- Getting all wizard data details
            String enquiryType =  (String) wizardData.get('selectedRadio1Name');
            String customerRefNumber =  (String) wizardData.get('customerRefNumber');
            String contactOption =  (String) wizardData.get('selectedRadio2Name');
            String contactPhoneNumber =  (String) wizardData.get('phoneNumber');
            String contactEmailAddress =  (String) wizardData.get('emailAddress');
            String whichItemYouarHavingIssuesWith =  (String) wizardData.get('selectedRadio3Name');
            //-- old address
            String oldAddLine1 =  (String) wizardData.get('oldAddressLine1');
            String oldAddLine2 =  (String) wizardData.get('oldAddressLine2');
            String oldAddSubRub =  (String) wizardData.get('oldCity');
            String oldAddState =  (String) wizardData.get('oldState');
            String oldAddPostcode =  (String) wizardData.get('oldPostcode');
            
            String whereIsYouremailRedirected =  (String) wizardData.get('selectedRadio4Name');
            Boolean conditionCheckbox =  (Boolean) wizardData.get('conditionCheckbox');
            //--new address
            String newAddLine1 =  (String) wizardData.get('newAddressLine1');
            String newAddLine2 =  (String) wizardData.get('newAddressLine2');
            String newAddSubRub =  (String) wizardData.get('newCity');
            String newAddState =  (String) wizardData.get('newState');
            String newAddPostcode =  (String) wizardData.get('newPostcode');
            String newAddCountry =  (String) wizardData.get('newCountry');
            
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
            
            //-- Subject : Trimming the enquiryDetails details to 255 chars
            if(enquiryDetails != null){
                if(enquiryDetails.trim().length() > 255){
                    subject = enquiryDetails.substring(0, 255);
                }else{
                    subject = enquiryDetails;
                }
            }
            //-- Building Comment Body
            String commentBody ='Enquiry Type : '  + enquiryType+ '\n' +
                'Details : ' + enquiryDetails+ '\n' +
                'What items are you having issues with : ' ;            // DDS-4885: Change the question wording to “What items are you having issues with?”
            
            if(whichItemYouarHavingIssuesWith == 'Parcels'){
                commentBody = commentBody+'Parcel';
            } else if (whichItemYouarHavingIssuesWith == 'Both') {      // DDS-4885: Add option called “Both” for issued items
                commentBody = commentBody+'Both';
            }
            else{
                commentBody = commentBody+'Letter';
            }
            commentBody = commentBody+ '\n' +'Contact options : '+contactOption;
            if(contactOption == 'Phone number' && contactPhoneNumber != null){
                commentBody = commentBody+ '\n' +'Contact phone number : '+contactPhoneNumber;
            }
            if(contactOption == 'Email address' && contactEmailAddress !=null){
                commentBody = commentBody+ '\n' +'Contact email address : '+contactEmailAddress;
            }
            // DDS-4885: add "Both" option on MRS form
            if(enquiryType == 'Mail hold' && (whichItemYouarHavingIssuesWith == 'Letters' || whichItemYouarHavingIssuesWith == 'Both') && whereIsYouremailRedirected !=null){
                commentBody = commentBody+ '\n' +' Where is your mail being redirected to? : '+whereIsYouremailRedirected ;
            }
            //-- commented below by Jansi - 31 Jul 2018
            /*commentBody = commentBody+ '\n'+'I lodged the original application or was included as a member of the household in the original application : ';

if(conditionCheckbox){
commentBody = commentBody  + 'True';
}else{   //-- must be true from UI, so there is no way to come false
commentBody = commentBody  + 'False';
}*/
            
            //-- Appending Addresses to Case comment , by JansiJul 31 2018
            
            //-- Old/hold Address
            if(oldAddLine1 !=null && oldAddLine1.length() > 0){
                commentBody = commentBody  + '\n'+'Address : '+oldAddLine1 + ', ';
            }
            if(oldAddLine2 !=null && oldAddLine2.length() > 0){
                commentBody = commentBody +oldAddLine2 + ', ';
            }
            if(oldAddSubRub !=null && oldAddSubRub.length() > 0){
                commentBody = commentBody  +oldAddSubRub+ ' ';
            }
            if(oldAddState !=null && oldAddState.length() > 0){
                commentBody = commentBody  +oldAddState+ ' ';
            }
            if(oldAddPostcode !=null && oldAddPostcode.length() > 0){
                commentBody = commentBody  +oldAddPostcode;
            }
            
            //-- New  Address  
            if(enquiryType != 'Mail hold' && (whichItemYouarHavingIssuesWith == 'Parcels' || whereIsYouremailRedirected !=null)){
                if(newAddLine1 !=null && newAddLine1.length() > 0){
                    commentBody = commentBody  + '\n'+'New Address : '+newAddLine1 + ', ';
                }
                if(newAddLine2 !=null && newAddLine2.length() > 0){
                    commentBody = commentBody +newAddLine2 + ', ';
                }
                if(newAddSubRub !=null && newAddSubRub.length() > 0){
                    commentBody = commentBody  +newAddSubRub + ' ';
                }
                if(newAddState !=null && newAddState.length() > 0){
                    commentBody = commentBody  +newAddState + ' ';
                }
                if(newAddPostcode !=null && newAddPostcode.length() > 0){
                    commentBody = commentBody  +newAddPostcode + ' ';
                }
                if(newAddCountry !=null && newAddCountry !='Select (default)'){
                    commentBody = commentBody  +newAddCountry + ' ';
                }
            }
            
            for(Integer key : personDetails.keySet()){
                String[] valArray = personDetails.get(key).split('~~~~');
                commentBody = commentBody  + '\n' +'Additional person '+key+': '+valArray[0]+' '+valArray[1];
            }
            
            commentBody = commentBody + '\n' +
                'Contact Preference : ' + contactPreferrence;  // Contact Preference, added by Edmarco on July 2019
            
            System.debug('***CommentBod = '+ commentBody);
            
            if(enquiryType == 'Mail redirection'){
                productSubCategory = ChasConstants.MAIL_REDIRECTION;
                if(whichItemYouarHavingIssuesWith == 'Parcels'){
                    tpeAndProduct = ChasConstants.FEEDBACK_AND_DOMESTIC_PARCELS_AND_MAIL_REDIRECTION;
                    productCategory = ChasConstants.DOMESTIC_PARCELS;
                }else if(whichItemYouarHavingIssuesWith == 'Letters'){
                    if(whereIsYouremailRedirected == 'Within Australia'){
                        tpeAndProduct = ChasConstants.FEEDBACK_AND_DOMESTIC_LETTERS_AND_MAIL_REDIRECTION;
                        productCategory = ChasConstants.DOMESTIC_LETTERS;
                    }else if(whereIsYouremailRedirected == 'Overseas'){
                        tpeAndProduct = ChasConstants.FEEDBACK_AND_INTERNATIONAL_LETTERS_AND_MAIL_REDIRECTION;
                        productCategory = ChasConstants.INTERNATIONAL_LETTERS;
                    }
                    
                }
            }else if(enquiryType == 'Mail hold'){
                productSubCategory = ChasConstants.MAIL_HOLD;
                if(whichItemYouarHavingIssuesWith == 'Parcels'){
                    tpeAndProduct = ChasConstants.INVESTIGATION_AND_DOMESTIC_PARCELS_MAIL_HOLD;
                    productCategory = ChasConstants.DOMESTIC_PARCELS;
                }else if(whichItemYouarHavingIssuesWith == 'Letters'){
                    tpeAndProduct = ChasConstants.INVESTIGATION_AND_DOMESTIC_LETTERS_MAIL_HOLD;
                    productCategory = ChasConstants.DOMESTIC_LETTERS;
                    
                }
            }
            
            Case toBeCreateCase = new Case();
            toBeCreateCase.RecordTypeId =recordTypeId;
            toBeCreateCase.Type=typeVal;
            toBeCreateCase.EnquirySubType__c = enquirySubType;
            toBeCreateCase.Type_and_Product__c=tpeAndProduct;
            toBeCreateCase.ProductCategory__c=productCategory;
            toBeCreateCase.ProductSubCategory__c=productSubCategory;
            toBeCreateCase.Subject=subject;
            toBeCreateCase.AllocateToQueue__c = true;
            toBeCreateCase.Origin = origin;
            toBeCreateCase.CHASEnquiryType__c=CHASEnquiryType;
            toBeCreateCase.Preferred_Communication_Method__c=contactPreferrence;  // Contact Preference, added by Edmarco on July 2019
            //Added for guest users
            toBeCreateCase.First_Name__c = givenName;
            toBeCreateCase.Last_Name__c=surname;
            toBeCreateCase.SuppliedEmail=email;
            toBeCreateCase.SuppliedPhone=phone;

            toBeCreateCase.ContactId = getContactId(UserInfo.getUserId());
            if(customerRefNumber !=null){
                toBeCreateCase.CRN__c=customerRefNumber;
            }
            if(userContactFirstName !=null){
                toBeCreateCase.First_Name__c=defaultFormGivenName;
            }
            if(userContactLastName !=null){
                toBeCreateCase.Last_Name__c=defaultFormSurName;
            }
            
            if(contactEmailAddress !=null){
                toBeCreateCase.SuppliedEmail=contactEmailAddress;//userContactEmail;   // Based on Matt's input mapped to form email address - Jansi Jul 13
            }
            
            if(contactPhoneNumber !=null){
                toBeCreateCase.SuppliedPhone=contactPhoneNumber;//userContactPhone;    // Based on Matt's input mapped to form email address - Jansi Jul 13
            }
            
            toBeCreateCase.Address3__c =oldAddLine1;
            
            if(oldAddLine2 !=null){
                toBeCreateCase.Address3Line2__c = oldAddLine2;
            }
            
            if(oldAddSubRub !=null){
                toBeCreateCase.Address3Suburb__c = oldAddSubRub;
            }
            if(oldAddState !=null){
                toBeCreateCase.Address3State__c = oldAddState;
            }
            if(oldAddPostcode !=null){
                toBeCreateCase.Address3Postcode__c = oldAddPostcode;
            }
            
            if(enquiryType != 'Mail hold'){
                toBeCreateCase.Address4__c = newAddLine1;
            }
            
            if(enquiryType != 'Mail hold' && newAddLine2 !=null){
                toBeCreateCase.Address4Line2__c = newAddLine2;
            }
            if(enquiryType != 'Mail hold' &&newAddSubRub !=null){
                toBeCreateCase.Address4Suburb__c =newAddSubRub;
            }
            if(enquiryType != 'Mail hold' &&newAddState !=null){
                toBeCreateCase.Address4State__c = newAddState;
            }
            if(enquiryType != 'Mail hold' &&newAddPostcode !=null){
                toBeCreateCase.Address4Postcode__c = newAddPostcode;
            }
            
            if(enquiryType != 'Mail hold' && whereIsYouremailRedirected == 'Overseas' && newAddPostcode !=null){
                toBeCreateCase.Address4Country__c = newAddCountry;
            }
            
            
            System.debug('toBeCreateCase == '+toBeCreateCase);
            Database.SaveResult[] results = Database.insert(new SObject[] {toBeCreateCase });
            System.debug('results == '+results);

            List<CaseComment> vComments = new List<CaseComment>();
            vComments.add(new CaseComment(CommentBody = commentBody, IsPublished = true));
            //-- Parse Case results and create Case Comment
            caseWrapper = ChasUtil.parseInsertedCaseResultsAndCreateComment(results, caseWrapper, vComments);
            
        }catch(Exception ex){
            caseWrapper.caseStatus = 'ERROR';
            System.debug('*** - Error while in createCaseFromMailRedirectAndHold method ==='+ex);
        }
        System.debug('caseWrapper= ' +caseWrapper);
        System.debug('----- createCaseFromMailRedirectAndHold ----- END');
        return caseWrapper;
    }
    
    
    /**
* This method will create Case for delivery issue
* */
    @AuraEnabled
    public static CaseWrapper createCaseFromDeliveryIssue( Map <String,String> wizardData, Map <String,String> authUserData ){
        System.debug('----- createCaseFromDeliveryIssue ----- START');
        
        CaseWrapper caseWrapper = new CaseWrapper();
        caseWrapper.caseStatus = 'SUCCESS';
        
        try{
            System.debug('wizardData='+wizardData);
            
            //-- Getting recordType Id
            String recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().
                get(ChasConstants.CASE_RECORDTYPE_SSSWDELIVERY).getRecordTypeId();
            
            //-- defaulting
            String typeVal = ChasConstants.FEEDBACK;
            String enquirySubType= 'Delivery complaint';
            String origin = 'Portal';
            
            String typeAndProduct = null;
            String productCategory = null;
            String productSubCategory = null;
            String subject = null;
            String CHASEnquiryType = 'Delivery issue';
            String caseOriginator = null;
            String inCorrectAddress;
            String correctAddress;
            //String issueDescription;
            //-- Getting all wizard data details
            String issueDetailsType =  (String) wizardData.get('IssueName');
            String parcelOrLetter =  (String) wizardData.get('selectedRadio2Name');
            String trackingNumber =  (String) wizardData.get('trackingId');
            String issueDateStr =  (String) wizardData.get('issueDate');
            
            //--  address
            String addLine1 =  (String) wizardData.get('deliveryAddressLine1');
            String addLine2 =  (String) wizardData.get('deliveryAddressLine2');
            String addSubRub =  (String) wizardData.get('deliveryCity');
            String addState =  (String) wizardData.get('deliveryState');
            String addPostcode =  (String) wizardData.get('deliveryPostcode');
            
            //--  Incorrect Address
            String inCorrectaddLine1 =  (String) wizardData.get('inCorrectDeliveryAddressLine1');
            String inCorrectaddLine2 =  (String) wizardData.get('inCorrectDeliveryAddressLine2');
            String inCorrectaddSuburb =  (String) wizardData.get('inCorrectDeliveryCity');
            String inCorrectaddState =  (String) wizardData.get('inCorrectDeliveryState');
            String inCorrectaddPostcode =  (String) wizardData.get('inCorrectDeliveryPostcode');
            
            //-- Assigning Case Originator
            if(wizardData.get('selectedRadio3Name') !=null){
                if(wizardData.get('selectedRadio3Name') == ChasConstants.RECIPIENT){
                    caseOriginator = ChasConstants.ADDRESSE;
                }else{
                    caseOriginator = ChasConstants.SENDER;
                }
            }
            
            
            // Build the incorrect address
            if(inCorrectaddLine1 != null){
                inCorrectAddress = inCorrectaddLine1;
            }
            if(inCorrectaddLine2 != null){
                inCorrectAddress += ' '+ inCorrectaddLine2;
            }
            if(inCorrectaddSuburb != null){
                inCorrectAddress += ', '+ inCorrectaddSuburb;
            }
            if(inCorrectaddState != null){
                inCorrectAddress += ', '+ inCorrectaddState;
            }
            if(inCorrectaddPostcode != null){
                inCorrectAddress += ', '+ inCorrectaddPostcode;
            }
            // Build the correct address
            if(addLine1 != null){
                correctAddress = addLine1;
            }
            if(addLine2 != null){
                correctAddress += ' '+ addLine2;
            }
            if(addSubRub != null){
                correctAddress += ', '+ addSubRub;
            }
            if(addState != null){
                correctAddress += ', '+ addState;
            }
            if(addPostcode != null){
                correctAddress += ', '+ addPostcode;
            }
            
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
            String issueDetails = (String) wizardData.get('issueDetails');
            //-- ENQUIRY DETAILS for incorrect delivery address
            String issueDescription = (String) wizardData.get('issueDescription');
            
            String contactPreferrence =  String.valueOf(wizardData.get('contactPreferrence'));  // Contact Preference, added by Edmarco on July 2019
            
            //-- Subject : Trimming the issueDetails details to 255 chars 
            if(issueDetails != null){
                if(issueDetails.trim().length() > 255){
                    subject = issueDetails.substring(0, 255);
                }else{
                    subject = issueDetails;
                }
            }
            //-- Subject : Trimming the issueDescription details to 255 chars .This is for incorrect delivery address
            if(issueDescription != null){
                if(issueDescription.trim().length() > 255){
                    subject = issueDescription.substring(0, 255);
                }else{
                    subject = issueDescription;
                }
            }
            
            //--Converting input issueDate string to SF acceptable Date
            Date convertedIssueDate = null;
            System.debug('issueDateStr='+issueDateStr);
            if(issueDateStr != null && issueDateStr.trim().length() > 0 && issueDetailsType != 'Item was left in an unsafe place'){
                String convertedDateStr = ChasUtil.convertToSFDateStrFormat(issueDateStr);
                if(convertedDateStr !=null){
                    convertedIssueDate = Date.valueOf(convertedDateStr);
                }else{
                    System.debug(LoggingLevel.ERROR, 'The date entered in the form is incorrect.');       //TO DO(check with Matt if this scenario is fine): if input date is diff format from user,
                    //then not allowing to create case without date.
                    caseWrapper.caseStatus = 'ERROR';
                    return caseWrapper;
                }
            }
            System.debug('convertedIssueDate='+convertedIssueDate);
            
            //-- Building Comment Body
            String commentBody ='Issue details : '  + issueDetailsType ;
            if(issueDetailsType == 'Postie didn\'t knock before leaving a card' || issueDetailsType == 'Item was left in an unsafe place' || issueDetailsType == 'Item was damaged'){
                commentBody = commentBody+ '\n' +'Which items are you having issues with : '+parcelOrLetter;
            }
            
            if(convertedIssueDate != null  && issueDetailsType != 'Item was left in an unsafe place'){
                commentBody = commentBody+ '\n' +'When did the issue occur : '+convertedIssueDate.format();
            }
            //Code can be removed by 30/10/2020, as it's no more relevant
            /*if(trackingNumber != null && trackingNumber.trim().length() > 0 && issueDetailsType != 'Damage to property'){
commentBody = commentBody+ '\n' +'Tracking Number : '+trackingNumber;
}*/
            if(trackingNumber != null && trackingNumber.trim().length() > 0){
                commentBody = commentBody+ '\n' +'Tracking Number : '+trackingNumber;
            }
            if(issueDetailsType == 'Incorrect delivery address needs fixing'){
                commentBody = commentBody + '\n' +'Details : '+issueDescription ;
            } else
            {
                commentBody = commentBody + '\n' +'Details : '+issueDetails ;
            }
            
            if(contactPreferrence != null){
                commentBody = commentBody+ '\n' +'Contact Preference : '+contactPreferrence;
            }
            
            if(issueDetailsType == 'Incorrect delivery address needs fixing'){
                commentBody = commentBody + '\n' +'Incorrect delivery address : '+inCorrectAddress ;
                commentBody = commentBody + '\n' +'Correct delivery address : '+correctAddress ;
            }       
            
            if(issueDetailsType == 'Incorrect delivery address needs fixing'){
                if(parcelOrLetter == 'Parcel'){
                    typeAndProduct = 'Feedback|Domestic Parcels|Parcel Post';
                    productCategory = 'Domestic Parcels';
                    productSubCategory = 'Parcel Post';
                    enquirySubType = 'Delayed delivery';
                }else{
                    typeAndProduct = 'Feedback|Domestic Letters|Regular Mail';
                    productCategory = 'Domestic Letters';
                    productSubCategory = 'Regular Mail';
                    enquirySubType = 'Delayed delivery';
                }
            }
            else if(issueDetailsType == 'Postie didn\'t knock before leaving a card'){
                if(parcelOrLetter == 'Parcel'){
                    typeAndProduct = 'Feedback|Domestic Parcels|Parcel Post';
                    productCategory = 'Domestic Parcels';
                    productSubCategory = 'Parcel Post';
                    enquirySubType = 'Article carded - no delivery attempt';
                }else{
                    typeAndProduct = 'Feedback|Domestic Letters|Registered Post';
                    productCategory = 'Domestic Letters';
                    productSubCategory = 'Registered Post';
                    enquirySubType = 'Article carded - no delivery attempt';
                }
            }
            else if(issueDetailsType == 'Item was taken to an inconvenient Post Office'){
                /* if(parcelOrLetter == 'Parcel'){
typeAndProduct = 'Feedback|Domestic Parcels|Parcel Post';
productCategory = 'Domestic Parcels';
productSubCategory = 'Parcel Post';
}else{
typeAndProduct = 'Feedback|Domestic Letters|Registered Post';
productCategory = 'Domestic Letters';
productSubCategory = 'Registered Post';
}*/
                //spingali - INC1644988 - This option is always considered to be under 'DomesticParcels' category
                
                typeAndProduct = 'Feedback|Domestic Parcels|Parcel Post';
                productCategory = 'Domestic Parcels';
                productSubCategory = 'Parcel Post';
                
            }else if(issueDetailsType == 'Item was damaged'){
                if(parcelOrLetter == 'Parcel'){
                    typeAndProduct = 'Feedback|Domestic Parcels|Parcel Post';
                    productCategory = 'Domestic Parcels';
                    productSubCategory = 'Parcel Post';
                }else{
                    typeAndProduct = 'Feedback|Domestic Letters|Registered Post';
                    productCategory = 'Domestic Letters';
                    productSubCategory = 'Registered Post';
                }
                
            }else if(issueDetailsType == 'Item was left in an unsafe place'){
                if(parcelOrLetter == 'Parcel'){
                    typeAndProduct = 'Feedback|Domestic Parcels|Parcel Post';
                    productCategory = 'Domestic Parcels';
                    productSubCategory = 'Parcel Post';
                }else{
                    typeAndProduct = 'Feedback|Domestic Letters|Registered Post';
                    productCategory = 'Domestic Letters';
                    productSubCategory = 'Registered Post';
                }
                
            }else if(issueDetailsType == 'Something else'){
                typeAndProduct = 'General Enquiry|Domestic Parcels|Parcel Post';
                productCategory = 'Domestic Parcels';
                productSubCategory = 'Parcel Post';
                enquirySubType = 'Tracking';
                typeVal = ChasConstants.GENERAL_ENQUIRY;
            }
            
            Case toBeCreateCase = new Case();
            toBeCreateCase.RecordTypeId =recordTypeId;
            toBeCreateCase.Type=typeVal;
            toBeCreateCase.EnquirySubType__c = enquirySubType;
            toBeCreateCase.Type_and_Product__c=typeAndProduct;
            toBeCreateCase.ProductCategory__c=productCategory;
            toBeCreateCase.ProductSubCategory__c=productSubCategory;
            toBeCreateCase.Subject=subject;
            toBeCreateCase.AllocateToQueue__c = true;
            toBeCreateCase.Origin = origin;
            toBeCreateCase.CHASEnquiryType__c=CHASEnquiryType;
            toBeCreateCase.CaseOriginator__c = caseOriginator;
            //Added for guest users
            toBeCreateCase.First_Name__c = givenName;
            toBeCreateCase.Last_Name__c=surname;
            toBeCreateCase.SuppliedEmail=email;
            toBeCreateCase.SuppliedPhone=phone;
            //Code can be removed by 30/10/2020, as it's no more relevant
            /*if(trackingNumber != null && trackingNumber.trim().length() > 0 && issueDetailsType != 'Damage to property'){
toBeCreateCase.ReferenceID__c=trackingNumber;
}*/
            
            if(trackingNumber != null && trackingNumber.trim().length() > 0){
                toBeCreateCase.ReferenceID__c=trackingNumber;
            }
            //-- change made for roll out of delivery issues network assignment automation
            String wcid = (String) wizardData.get('latestDeliveredScanWcid');
            String isEligibleForMyNetworkAssignment = (String) wizardData.get('isEligibleForNetworkAssignmentDeliveryIssue');
            if(isEligibleForMyNetworkAssignment == 'true')
            {
                //-- set the value for isEligibleForMyNetworkAssignment to the case field
                setDirectRoutingValues(toBeCreateCase, RoutingBypass.NETWORK, wcid);
                toBeCreateCase.Description = 'Issue details : '+ issueDetailsType + '\n';
                toBeCreateCase.Description = toBeCreateCase.Description + 'Which items are you having issues with : '+ parcelOrLetter + '\n';
                if(issueDetails != null)
                {
                    toBeCreateCase.Description = toBeCreateCase.Description + Label.HS_Issue_Details_Warning +'\n\n'+ issueDetails + '\n\n';
                }
                if(issueDescription != null)
                {
                    toBeCreateCase.Description = toBeCreateCase.Description + Label.HS_Issue_Details_Warning +'\n\n'+ issueDescription + '\n\n';
                }
                
            } 
             //REQ2361513 -- Modified by Paul Swarnapandian
                if((issueDetailsType == 'Item was left in an unsafe place' || issueDetailsType == 'Postie didn\'t knock before leaving a card') && isEligibleForMyNetworkAssignment == 'true'){
                    commentBody = commentBody + '\n' + 'Is eligible for network assignment : ' + 'Yes';
                } 
                else if ((issueDetailsType == 'Item was left in an unsafe place' || issueDetailsType == 'Postie didn\'t knock before leaving a card') && isEligibleForMyNetworkAssignment != 'true'){
                    commentBody = commentBody + '\n' + 'Is eligible for network assignment : ' + 'No';
                }
                
                
            
            
            if(convertedIssueDate !=null){
                toBeCreateCase.DateofIncident__c=convertedIssueDate;
            }
            
            if(addLine1 != null){
                toBeCreateCase.Address4__c = addLine1;
            }
            
            if(addLine2 !=null){
                toBeCreateCase.Address4Line2__c = addLine2;
            }
            if(addSubRub !=null){
                toBeCreateCase.Address4Suburb__c =addSubRub;
            }
            if(addState !=null){
                toBeCreateCase.Address4State__c = addState;
            }
            if(addPostcode !=null){
                toBeCreateCase.Address4Postcode__c = addPostcode;
            }
            
            toBeCreateCase.ContactId = getContactId(UserInfo.getUserId());
            if(userContactFirstName !=null){
                toBeCreateCase.First_Name__c=userContactFirstName;
            }
            if(userContactLastName !=null){
                toBeCreateCase.Last_Name__c=userContactLastName;
            }
            
            if(userContactEmail !=null){
                toBeCreateCase.SuppliedEmail=userContactEmail;
            }
            
            if(userContactPhone !=null){
                toBeCreateCase.SuppliedPhone=userContactPhone;
            }
            
            toBeCreateCase.Preferred_Communication_Method__c=contactPreferrence;  // Contact Preference, added by Edmarco on July 2019
            
            System.debug('toBeCreateCase == '+toBeCreateCase);
			Database.SaveResult[] results;
			if (toBeCreateCase.Automated_Network_Assignment__c && toBeCreateCase.Network__c != null){
				SharingBypass lSharingBypass = new SharingBypass();
				results = lSharingBypass.insertSObjects(new SObject[] {toBeCreateCase});
			}
			else {
				results = Database.insert(new SObject[] {toBeCreateCase });
			}
            System.debug('results == '+results);

            List<CaseComment> vComments = new List<CaseComment>();
            vComments.add(new CaseComment(CommentBody = commentBody, IsPublished = true));
            checkNetworkAssigningResult(toBeCreateCase, vComments);

            //-- Parse Case results and create Case Comment
            caseWrapper = ChasUtil.parseInsertedCaseResultsAndCreateComment(results, caseWrapper, vComments);

            //-- Case routing based on the boolean isEligibleForMyNetworkAssignment
            // 17-08-2021 switched to direct routing
           /* if(isEligibleForMyNetworkAssignment == 'true')
            {
                ChasCaseAssignment caseAssignment = new ChasCaseAssignment(toBeCreateCase, wcid);
                Id jobId = System.enqueueJob(caseAssignment);
                
            } */
            //Code can be removed by 30/10/2020, as it's no more relevant
            /*for (Integer i = 0; i < results.size(); i++) {
if (results[i].isSuccess()) {
System.debug('Successfully created ID: '+ results[i].getId());
try{
String objName = results[i].getId().getSObjectType().getDescribe().getName(); 
System.debug('*** - objName = '+objName);
//-- Creating Case Comment for inserted Case
if( objName.equalsIgnoreCase('Case')){
caseWrapper.caseNumber = ChasUtil.createCaseComment(results[i].getId(),commentBody);
System.debug('*** Flow called - CaseNumber:'+caseWrapper.caseNumber);
}

}catch(Exception ex){
System.debug('*** - Error while retrieving Case Number/Creating Case Comment ==='+ex);
}

} else {
caseWrapper.caseStatus = 'ERROR';
System.debug('Error: could not create sobject '+ 'for array element ' + i + '.');
System.debug('The error reported was: '+ results[i].getErrors()[0].getMessage() + '\n');

}
}*/
            
        }catch(Exception ex){
            caseWrapper.caseStatus = 'ERROR';
            System.debug('*** - Error while in createCaseFromDeliveryIssue method ==='+ex);
        }
        System.debug('caseWrapper= ' +caseWrapper);
        System.debug('----- createCaseFromDeliveryIssue ----- END');
        return caseWrapper;
    }
    
    
    
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
                }else if(idDocumentsAccountsEnquiryType == 'MyPost'){
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
                if(isEligibleForMyNetworkAssignment == 'true')
                {
                    caseDescription = caseDescription + '\n' + 'WCC ID: ' + wcid;
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
            checkNetworkAssigningResult(toBeCreateCase, comments);

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
    
    /**
* @description     get the Contact Id of the provided User Id
* @param           Id i.e. User Id 
* @return          Id i.e. Contact Id for the user
*/
    private static Id getContactId(Id userId) {
        return [SELECT ContactId FROM User WHERE Id = :userId]?.ContactId;
    }
    
    /* -------------------------NEW SERVICE--------------------------------------*/
    /**
* This method will take the 'Tracking Number' as input and will call the rest service and return the response in JSON format
* */
    @AuraEnabled
    public static TrackingNumberDetails searchTrackingNumber(String trackingNumber){
        //Initializing the return wrapper obj
        TrackingNumberDetails trackingNumDetailsWrapperObj = new TrackingNumberDetails();
        
        if(trackingNumber != null && trackingNumber.trim().length() > 0){
            
            HttpResponse httpRes = ChasCallout.requestStatus(trackingNumber);
            
            //Checking the httpResponse Status Codes
            if(httpRes!=null){
                
                String jsonString = httpRes.getBody();
                String enqSubTypeOverride = '';
                jsonString = jsonString.replace('"on"', '"eventDateTime"'); // replacing the dateTime in the response as this "on" is reserved keyword in apex
                jsonString = jsonString.replace('"from"', '"fromDateTime"');// replacing the from keyword in the response as it is a reserved keyword in apex
                //pares one track response
                ChasOneTrackResponse response = (ChasOneTrackResponse) System.JSON.deserialize(jsonString, ChasOneTrackResponse.class);
                ChasTrackStatus trackService = new ChasTrackStatus(response, trackingNumber);
                //Intilalizing status code in to wrapper
                if(httpRes.getStatusCode() != null ){
                    //trackingNumDetailsWrapperObj.trackingNumSerachStatusCode = httpRes.getStatusCode();
                    trackingNumDetailsWrapperObj.trackingNumSerachStatusCode = trackService.responseCode;
                    trackingNumDetailsWrapperObj.trackingNumSerachStatusMsg = httpRes.getStatus();
                }
                //Special handling for response code 403
                if(trackingNumDetailsWrapperObj.trackingNumSerachStatusCode == 403){
                    trackingNumDetailsWrapperObj.enqSubtype = ChasConstants.ENQ_SUB_TYPE_TRACKING;
                    trackingNumDetailsWrapperObj.itemType = ChasConstants.ITEM_TYPE_DOMESTIC;
                }
                // DDS-5488: Enquiry sub type should be “tracking” and type should be “general” for 404 response
                if(trackingNumDetailsWrapperObj.trackingNumSerachStatusCode == 404){
                    trackingNumDetailsWrapperObj.enqSubtype = ChasConstants.ENQ_SUB_TYPE_TRACKING;
                    trackingNumDetailsWrapperObj.itemType = ChasConstants.ITEM_TYPE_DOMESTIC;
                }
                //If response status code is 200 then parsing the response
                if(trackingNumDetailsWrapperObj.trackingNumSerachStatusCode == 200){
                    //trackingNumDetailsWrapperObj.trackingNumSerachStatusCode = httpRes.getStatusCode();
                    trackingNumDetailsWrapperObj.trackingNumSerachStatusMsg = httpRes.getStatus();
                    //ChasTrackStatus trackService = new ChasTrackStatus(response, trackingNumber);
                    //assign the dpid returned from the service
                    trackingNumDetailsWrapperObj.dpid = trackService.dpid;
                    //assign the articleId returned from the service
                    trackingNumDetailsWrapperObj.articleId = trackService.articleId;
                    //change made for roll out of Products and services uplift - assign the subProductId returned from the service
                    trackingNumDetailsWrapperObj.subProductId = trackService.subProductId;
                    
                    //fetch the safedDropDelivered date time
                    Datetime safedropDeliveredDateTime = trackService.safedropDeliveredDateTime;
                    String safedropDelivered = '';
                    //Convert the data time format to a desired format like "11:31 am, Wednesday 8 April"
                    if(safedropDeliveredDateTime != null)
                    {
                        String dayOfWeek = safedropDeliveredDateTime.format('EEEE');
                        String dateOfWeek = safedropDeliveredDateTime.format('d MMMM ');
                        String timeOfWeek = safedropDeliveredDateTime.format('hh:mm a');
                        safedropDelivered = timeOfWeek + ', ' + dayOfWeek + ' ' + dateOfWeek;
                        trackingNumDetailsWrapperObj.safedropDelivered = safedropDelivered;  
                    }
                    
                    //if safedropped, then assign the edd status
                    if(trackingNumDetailsWrapperObj.safedropDelivered != null)
                    {
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_LEFT_IN_A_SAFE_PLACE;
                    }
                    
                    // article type and the item type will be used to generate the case
                    if (trackService.articleType != null) {
                        trackingNumDetailsWrapperObj.articleType = trackService.articleType;
                        trackingNumDetailsWrapperObj.itemType = (trackService.articleType.containsIgnoreCase(ChasConstants.ITEM_TYPE_INTERNATIONAL) ? ChasConstants.ITEM_TYPE_INTERNATIONAL : ChasConstants.ITEM_TYPE_DOMESTIC);
                    }
                    //setting the value for a duplicate case, derived from the latest event code
                    trackingNumDetailsWrapperObj.duplicateCase = trackService.duplicateCase;
                    //set RTS scan flag if any
                    trackingNumDetailsWrapperObj.isReturnToSender = trackService.isReturnToSender;
                    //set signature flag if any
                    trackingNumDetailsWrapperObj.hasSignature = trackService.hasSignature;
                    //set isParcelAwaitingCollection flag if any
                    trackingNumDetailsWrapperObj.isParcelAwaitingCollection = trackService.eventCodeisAwaitingCollection;
                    // if there's a work center id (facility code)
                    trackingNumDetailsWrapperObj.wcid = trackService.wcid;
                    //-- change made for roll out of delivery issues network assignment automation
                    trackingNumDetailsWrapperObj.latestDeliveredScanWcid = trackService.hasDeliveredScanEvent;
                    trackingNumDetailsWrapperObj.previousDeliveredScanWcid = trackService.previousDeliveredScanWcid;
                    // set isRedirectApplied flag if any
                    trackingNumDetailsWrapperObj.isRedirectApplied = trackService.isRedirectApplied;
                    // if there's a latest event location, track it to decide the delivery location state like NSW,VIC etc.Temporary solution to be refactored
                    if(trackService.latestEvent != null)
                    {
                        trackingNumDetailsWrapperObj.latestEventLocation = trackService.latestEvent.location;
                        trackingNumDetailsWrapperObj.latestEventLocationMessage = trackService.latestEvent.message;
                    }
                    //set trackStatusValue value from the milestone 
                    trackingNumDetailsWrapperObj.trackStatusValue = trackService.trackStatusValue;
                    //set deliveryChoicesSafeDropIneligibilityCode flag if any
                    trackingNumDetailsWrapperObj.deliveryChoicesSafeDropIneligibilityCode = trackService.deliveryChoicesSafeDropIneligibilityCode;
                    // set the value for isEligibleForMyNetworkAssignment
                    trackingNumDetailsWrapperObj.isEligibleForMyNetworkAssignment = trackService.isEligibleForMyNetworkAssignment;
                    // setting the EDD or delivered date
                    trackingNumDetailsWrapperObj.deliveredByDateOrEDD = trackService.deliveredByDate;
                    // setting the EDD From DateTime
                    trackingNumDetailsWrapperObj.deliveredByDateFrom = trackService.deliveredByDateFrom;
                    // // setting the EDD To DateTime
                    trackingNumDetailsWrapperObj.deliveredByDateTo = trackService.deliveredByDateTo;
                    // setting the EDD monitor date until
                    trackingNumDetailsWrapperObj.deliveredByDateToUntil = trackService.deliveredByDateToUntil;
                    // setting the EDD plus business days
                    trackingNumDetailsWrapperObj.deliveredByDatePlusBusinessDays = trackService.deliveredByDatePlusBusinessDays;
                    // check if the system date is within EDD plus business days
                    trackingNumDetailsWrapperObj.isEnquiryDateWithinEDDPlusBusinessdays =trackService.isEnquiryDateWithinEDDPlusBusinessdays;
                    trackingNumDetailsWrapperObj.isEnquiryDatePastEDDPlusBusinessdays =trackService.isEnquiryDatePastEDDPlusBusinessdays;
                    trackingNumDetailsWrapperObj.isEnquiryDateWithinEDD=trackService.isWithinEDD;

                    // this takes the highest priority in deciding what type of enquiry should be raised for the supplied article
                    // this is just for the enquiry type on the case and does not impact the ui feedback provided to a user.
                    if(trackService.isReturnToSender || trackService.isDeliveredLeftInASafePlace || (trackService.isDelivered && ! trackService.deliveryChoicesSafeDropIneligibilityCode)) {
                        enqSubTypeOverride = ChasConstants.ENQ_SUB_TYPE_TRACKING;
                    }
                    // no EDD found, deliveredByDate on the response, update the enquiry subtype as Tracking if a case created
                    if(trackService.isNoEDDReturned
                      ) {
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_NO_EDD_FOUND;
                        trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_MISSING);
                        // DDS-5272: indicator for no EDD return
                        trackingNumDetailsWrapperObj.isNoEddReturned = true;
                    }
                    else if(trackService.isDelivered) {
                        // item delivered but submit a case,  update the enquiry subtype as Disputed Scan if a case created
                        
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_DELIVERED;
                        trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_DISPUTED);
                        
                    } else if(trackService.isDeliveringLate) {
                        //The expected delivered date is passed today,  update the enquiry subtype as Missing item if a case created
                        
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_DELIVERING_LATE;
                        trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_MISSING);
                        
                    } else if(trackService.isDeliveryOnTime) {
                        // delivering on time, the EDD shows the expected delivery date as a future date, ,  update the enquiry subtype as Tracking if a case created
                        
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_DELIVERING_ON_TIME;
                        trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_TRACKING);
                        
                    } else if(trackService.isNotScannedYet) {
                        // no scan events found and the status is pending, update the enquiry subtype as Tracking if a case created
                        
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_NOT_SCANNED_YET;
                        trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_TRACKING);
                        
                    } else if(trackService.isDeliveredLeftInASafePlace) {
                        // item is safe dropped, update the enquiry subtype as Disputed Scan if a case created
                        
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_LEFT_IN_A_SAFE_PLACE;
                        trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_DISPUTED);
                        
                    } else if(trackService.isAwaitingCollection) {
                        // awaiting collection at the location, ,  update the enquiry subtype as Missing Item if a case created
                        
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_AWAITING_COLLECTION;
                        trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_MISSING);
                        // if there's a latest event location, track it to display it for awaiting collection status.
                        trackingNumDetailsWrapperObj.latestEventLocation = trackService.latestEvent.location;
                        
                    } else if(trackService.isOnBoardForDelivery) {
                        // It's coming today, ,  update the enquiry subtype as Missing Item if a case created
                        
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_COMING_TODAY;
                        trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_MISSING);
                        
                    } else {
                        // default
                        trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_NO_EDD_FOUND;
                        trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_TRACKING); 
                        // DDS-5272: indicator for no EDD return
                        trackingNumDetailsWrapperObj.isNoEddReturned = true;
                    }
                    // DDS-7977: pass attributes from tracking response to wrapper object
                    trackingNumDetailsWrapperObj.allArticlesSuccessed = trackService.allArticlesSuccessed;
                    trackingNumDetailsWrapperObj.allArticlesNotSuccessed = trackService.allArticlesNotSuccessed;
                    
                    return trackingNumDetailsWrapperObj;
                }
            }
            
        } else {
            //System.debug('Input trackingNumber is null or Empty');
        }
        
        return trackingNumDetailsWrapperObj;
    }
    
    @AuraEnabled
    public static UserDetails getLoggedInUserInfo(){
        System.debug('----- getLoggedInUserInfo ----- START');
        System.debug('UserInfo==='+UserInfo.getUserId());
        UserDetails userDetail = new UserDetails();
        userDetail.isUserAuthenticated = false;
        
        System.debug('UserInfo.getUserId()=='+UserInfo.getUserId());
        System.debug('UserInfo.getUserType()=='+UserInfo.getUserType());
        try{
            //-- iIf user is logged in then
            if(UserInfo.getUserId() != null && !UserInfo.getUserType().equalsIgnoreCase('Guest')){
                userDetail.isUserAuthenticated = true;
                userDetail.userFullName = UserInfo.getName();
                userDetail.userEmail = UserInfo.getUserEmail();
                userDetail.userFullName = UserInfo.getName();
                userDetail.userFirstName = UserInfo.getFirstName();
                userDetail.userLastName = UserInfo.getLastName();
                userDetail.userType = UserInfo.getUserType();
                String userId = UserInfo.getUserId();
                //-- Querying User ContactId
                User userObj = [SELECT ContactId FROM User WHERE Id= :userId LIMIT 1];
                System.debug('----- userObj ==='+userObj);
                
                if(userObj.ContactId !=null){
                    //-- Querying  Contact Details
                    Contact contactbj = [SELECT Phone, Email, Name, FirstName, LastName FROM Contact WHERE Id= :userObj.ContactId LIMIT 1];
                    System.debug('----- contactbj ==='+contactbj);
                    if(contactbj != null){
                        if(contactbj.Email != null){
                            userDetail.userContactEmail = contactbj.Email;
                        }
                        if(contactbj.Phone != null){
                            userDetail.userContactPhone = contactbj.Phone;
                        }
                        if(contactbj.FirstName != null){
                            userDetail.userContactFirstName = contactbj.FirstName;
                        }
                        if(contactbj.LastName != null){
                            userDetail.userContactLastName = contactbj.LastName;
                        }
                    }
                }
            }
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR,'ChasApexController: getLoggedInUserInfo() ===>'+ex);
        }
        
        System.debug('----- userDetail ==='+userDetail);
        
        //-- Query user contact, phone number
        System.debug('----- getLoggedInUserInfo ----- END');
        
        return userDetail;
        
    }
    
    /**
*  Encrypt the data
* */
    @AuraEnabled
    public static EncryptDetails encryptData(String inputData){
        System.debug(LoggingLevel.DEBUG,'ChasApexController.encryptData() --> encryptData  .... START');
        System.debug(LoggingLevel.DEBUG,'ChasApexController.encryptData() --> inputData='+inputData);
        
        EncryptDetails encryptDetailObj = null;
        try{
            if(inputData != null && inputData.length() > 0){
                Blob cryptoKey =null;
                //-- Getting crypto key from Custom Settings
                try{
                    Consumer_Help_and_Support__c consumerHelpNSupport = Consumer_Help_and_Support__c.getOrgDefaults();
                    System.debug(LoggingLevel.DEBUG,'consumerHelpNSupport custom setting='+consumerHelpNSupport);
                    if(consumerHelpNSupport != null && consumerHelpNSupport.Encoded_Crypto_Key__c != null){
                        cryptoKey = EncodingUtil.base64Decode(consumerHelpNSupport.Encoded_Crypto_Key__c);
                    }else{
                        System.debug(LoggingLevel.ERROR,'No Custom Setting is present for CHAS to get Encoded_Crypto_Key__c') ;
                    }
                }catch(Exception ex){
                    System.debug(LoggingLevel.ERROR,'Error while getting Custom Setting of CHAS to get Encoded_Crypto_Key__c'+ex.getMessage()) ;
                }
                
                encryptDetailObj = new EncryptDetails();
                //Blob cryptoKey = Crypto.generateAesKey(256);
                Blob blobInputData = Blob.valueOf(inputData);
                
                System.debug(LoggingLevel.DEBUG,'ChasApexController.encryptData() --> cryptoKey='+cryptoKey);
                System.debug(LoggingLevel.DEBUG,'ChasApexController.encryptData() --> blobInputData='+blobInputData);
                
                //Encrypt the data
                Blob encryptedBlobInputData = Crypto.encryptWithManagedIV('AES256', cryptoKey, blobInputData);
                //System.debug('encryptedBlobInputData='+encryptedBlobInputData);
                
                // 28/08/2018 - No longer saving the encrypted wizardData to LocalStorage so no need to return the data here.
                //- setting encrypted key and data to wrapper obj
                // encryptDetailObj.encodedKey  = EncodingUtil.base64Encode(cryptoKey);
                //encryptDetailObj.encodedData  =  EncodingUtil.base64Encode(encryptedBlobInputData);
                
                //Store our wizardData in Org Platform cache
                String encodedData =  EncodingUtil.base64Encode(encryptedBlobInputData);
                String guid = generateGUID();
                String orgCacheKey = 'local.HelpAndSupport.' + guid;
                // Org Cache by default lasts for 24hours. It can be available up to 48 hours but needs to be specified here.
                Cache.Org.put(orgCacheKey, encodedData);
                encryptDetailObj.cacheKey = guid;
                
            }
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR,'Error occoured :: ChasApexController.encryptData() ==>'+ex);
        }
        return encryptDetailObj;
    }
    
    /**
*  Decrypt the data
* */
    @AuraEnabled
    public static String decryptData(String encodedData, String cacheKey){
        
        System.debug('decryptBlobData  .... START');
        //System.debug('encodedData='+encodedData);
        System.debug('cacheKey='+cacheKey);
        
        String decryptStr = null;
        Blob cryptoKey = null;
        try {
            
            //-- Getting crypto key from Custom Settings
            try {
                Consumer_Help_and_Support__c consumerHelpNSupport = Consumer_Help_and_Support__c.getOrgDefaults();
                if (consumerHelpNSupport != null && consumerHelpNSupport.Encoded_Crypto_Key__c != null) {
                    cryptoKey = EncodingUtil.base64Decode(consumerHelpNSupport.Encoded_Crypto_Key__c);
                } else {
                    System.debug(LoggingLevel.ERROR, 'No Custom Setting is present for CHAS to get Encoded_Crypto_Key__c') ;
                }
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Error while getting Custom Setting of CHAS to get Encoded_Crypto_Key__c' + ex.getMessage()) ;
            }
            
            String orgCachedWizardData = '';
            if (cacheKey != null) {
                String orgCacheKey = 'local.HelpAndSupport.' + cacheKey;
                System.debug(LoggingLevel.DEBUG,'*** ChasApexController.decryptData - orgCacheKey : '+orgCacheKey);
                orgCachedWizardData = (String) Cache.Org.get(orgCacheKey);
            }
            else
                System.debug(LoggingLevel.DEBUG,'*** ChasApexController.decryptData - cacheKey is null do not attempt to retrieve cache.');
            
            Blob decryptedData = null;
            if (orgCachedWizardData != ''){
                decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey, EncodingUtil.base64Decode(orgCachedWizardData));
                decryptStr = decryptedData.toString();
                System.debug(LoggingLevel.DEBUG,'*** ChasApexController.decryptData - decrypted Wizard data from Org Cache: ' + decryptStr);
            } else
                System.debug(LoggingLevel.DEBUG,'*** ChasApexController.decryptData - orgCachedWizardData, lookup of Org Cache failed.');
            
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR,'Error occored :: ChasApexController.decryptBlobData() ==>'+ex);
        }
        
        return decryptStr;
    }

    /**
     * DDS-5820: method to retrieve ThankYouPage next step metadata
     * @param mtdGroup: group that required steps belong to
     * @return: list of steps belong to stated group
     */
    @AuraEnabled
    public static List<CHAS_ThankYouPageNextSteps__mdt> getNextStepMetadata(String mtdGroup)
    {
        List<CHAS_ThankYouPageNextSteps__mdt> metadatas =   [SELECT Step_ID__c, Image__c, Label__c, Sub_Label__c, Display_Order__c 
                                                            FROM CHAS_ThankYouPageNextSteps__mdt 
                                                            WHERE isActive__c = TRUE AND Group__c = :mtdGroup
                                                            ORDER BY Display_Order__c ASC];

        return metadatas.size() > 0? metadatas : null;
    }
    
    public static String generateGUID() {
        //String guid = '';
        String hex = '';
        try {
            Blob b = Crypto.generateAesKey(128);
            hex = EncodingUtil.convertToHex(b);
            //guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-'  + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        }
        catch (Exception e)
        {
            System.debug(LoggingLevel.ERROR,'Error occored :: ChasApexController.generateGUID() ==>'+e);
        }
        
        return hex;
    }


    private enum RoutingBypass{NETWORK, HOLD}

    /**
     * @description Helper class containing methods that need to bypass sharing settings
     */
    private without sharing class SharingBypass {
        /**
         * @description Method querying network Id by Org Id and Contact Facility
		 * @param orgId Organisation Id
		 * @return Id Network Id
		 */
        public Id getNetworkIdByOrgId(String orgId)
        {
            List<Network__c> networks = [SELECT Id FROM Network__c WHERE Org_ID__c =: orgId
                                            AND Contact_Facility__c = 'MyNetwork' LIMIT 1];
            return networks.isEmpty() ? null : networks[0].Id;
        }

        /**
        * @description Method inserting SObjects
        * @param pSObjects SObject List of SObject records to insert
        * @return List<Database.SaveResult> DML results
        */
        public List<Database.SaveResult> insertSObjects(List<SObject> pSObjects)
        {
            return Database.insert(pSObjects);
        }

        /**
        * @description Method generating a case comment with required visibility
        * @param pBody comment body
        * @param pPublicFlag public visibility flag
        * @return CaseComment resulting case comment
        */
        public CaseComment generateCaseComment(String pBody, Boolean pPublicFlag)
        {
            return new CaseComment(CommentBody = pBody, IsPublished = pPublicFlag);
        }
    }

    private static Boolean noNetworkIdFound = false;                // flag for no network ID found in setDirectRoutingValues
    private static String unavailableOrgId;                         // org ID that is unavailable
    private static Boolean noNetworkGroupFound = false;             // flag for no network group found in setDirectRoutingValues

    /**
     * check if there is any exception on network assigning and create corresponding case comment
     * the comment will be private by default
     * @author: phap.mai@auspost.com.au
     * @param iCase: target case
     */
    private static void checkNetworkAssigningResult(Case iCase, List<CaseComment> comments)
    {
        // if target case is not an audience of network assignment quit early
        if (iCase.Automated_Network_Assignment__c) {

            SharingBypass helper = new SharingBypass();

            // create case comment if no network id found on network assigning
            if (noNetworkIdFound) {
                comments.add(helper.generateCaseComment('Unable to find network with requested org ID: ' + unavailableOrgId, false));
            }

            // create case comment if no network group found in network assigning
            if (noNetworkGroupFound) {
                comments.add(helper.generateCaseComment('Unable to find network queue for the requested org ID: ' + unavailableOrgId, false));
                // helper.createCaseComment(iCase.Id, comment, false, true);
            }
        }
    }
    /**
     * @description Sets case owner, status and flags when routing rules need to be bypassed
     * @param pCase Case to route directly bypassing the routing engine
     * @param pBypass Type of bypass
     * @param pOrgId Organisation Id for network cases
     */
    private static void setDirectRoutingValues(Case pCase, final RoutingBypass pBypass, final String pOrgId){
        if (pBypass == RoutingBypass.NETWORK){
            pCase.Automated_Network_Assignment__c = true;
            SharingBypass vSharingBypass = new SharingBypass();
            Id vNetworkId = vSharingBypass.getNetworkIdByOrgId(pOrgId);
            if (vNetworkId != null){
                pCase.Status = SSSWConstants.STAT_AWAITING_NTWRK_RESPONSE;
                pCase.Network__c = vNetworkId;
                Map<Id, Group> vGroups = GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{SSSWConstants.QUEUE_DEV_NAME_SSSWNETWORKQUEUE});
                if (!vGroups.isEmpty()) {
                    pCase.OwnerId = vGroups.values()[0].Id;
	                pCase.Sent_To_Network_Date__c = System.now();
                    pCase.ByPassRoutingRulesOnCreation__c = true;
                    pCase.AllocateToQueue__c = false;
                }
                else
                {
                    // set the flag for case comment after case inserted
                    noNetworkGroupFound = true;
                }
                //Need to explicitly add description from rules due to routing bypass
                SSSW_Routing.populateCaseDescriptionFromDescriptionRules(new List<Case>{pCase}, null);
            } else
            {
                // set the flag for case comment after case inserted
                noNetworkIdFound = true;
                unavailableOrgId = pOrgId;
            }
        }
        else if (pBypass == RoutingBypass.HOLD){
            Map<Id, Group> vGroups = GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{SSSWConstants.QUEUE_NAME_REOPEN_Q});
            if (!vGroups.isEmpty()) {
                pCase.OwnerId = vGroups.values()[0].Id;
                Date reopenDate = ChasUtil.calculateNextBusinessDay(pCase.EstimatedDelivery__c, Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c != null ? Integer.valueOf(Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c) : 0);
                pCase.Status = SSSWConstants.CASE_STATUS_INPROGRESS;
                pCase.Case_Reopen_Date__c = reopenDate;
                pCase.HeldToOpenOn__c = reopenDate;
                pCase.ByPassRoutingRulesOnCreation__c = true;
                pCase.AllocateToQueue__c = false;
            }
        }
    }
    
    //-- Case Wrapper Class
    public class CaseWrapper{
        @AuraEnabled public String caseNumber{get;set;}
        @AuraEnabled public String caseStatus{get;set;}
    }
    
    //-- TrackingNumberDetails Wrapper Class
    public class TrackingNumberDetails{
        @AuraEnabled public String articleId{get;set;}
        @AuraEnabled public String articleType{get;set;}   //from Response, Ex:International, International Express,StarTrack International
        @AuraEnabled public Date deliveredByDateOrEDD{get;set;}
        //@AuraEnabled public String deliveredByDateFormatted{get;set;}
        @AuraEnabled public String eddStatus{get;set;}   // dateNotfound, datePassed, dateNotPassed
        @AuraEnabled public String itemType{get;set;}  // 'Domestic' or 'International'
        @AuraEnabled public String senderCountry{get;set;}
        @AuraEnabled public String recipientCountry{get;set;}
        @AuraEnabled public Integer trackingNumSerachStatusCode{get;set;}
        @AuraEnabled public String trackingNumSerachStatusMsg{get;set;}
        @AuraEnabled public String duplicateCase{get;set;}
        @AuraEnabled public String latestEventLocation{get;set;}
        @AuraEnabled public String latestEventLocationMessage{get;set;}
        @AuraEnabled public String enqSubtype{get;set;}
        @AuraEnabled public String enqType{get;set;}
        @AuraEnabled public String trackStatusValue{get;set;}
        @AuraEnabled public String wcid{get;set;}
        // Safedrop flow : delivery point id, to match the AME address with that returned from the service
        @AuraEnabled public String dpid{get;set;}
        // Safedrop flow : date time when the article was safedropped
        @AuraEnabled public String safedropDelivered{get;set;}
        // Safedrop flow : Inflight redirection applied
        @AuraEnabled public Boolean isRedirectApplied{get;set;}
        // article contains a return to sender scan event as defined in ChasTrackStatus
        @AuraEnabled public Boolean isReturnToSender { get; set; }
        // article contains signature as defined in ChasTrackStatus
        @AuraEnabled public Boolean hasSignature { get; set; }
        
        // article contains delivery choices safe drop ineligibility
        @AuraEnabled public Boolean deliveryChoicesSafeDropIneligibilityCode { get; set; }
        
        // determines whether or not whether a created case can be assigned directly to a network or not
        // This is based on conditions defined in ChasTrackStatus.isEligibleForMyNetworkAssignment
        @AuraEnabled public Boolean isEligibleForMyNetworkAssignment { get; set; }
        // determines whether or not whether a created case can be assigned directly to a network or not
        // This is for ProductAndServices form, based on latest event code "Awaiting-collection"
        @AuraEnabled public Boolean isParcelAwaitingCollection { get; set; }
        // determines the sub product id returned from the service, to be used for product exclusion in transfer to po form
        @AuraEnabled public String subProductId { get; set; }
        // change made for roll out of delivery issues network assignment automation. This is based on conditions defined in ChasTrackStatus.isEligibleForNetworkAssignmentDeliveryIssue
        @AuraEnabled public String latestDeliveredScanWcid{get;set;}
        @AuraEnabled public String previousDeliveredScanWcid{get;set;}
        @AuraEnabled public Boolean isEligibleForNetworkAssignmentDeliveryIssue { get; set; }
        @AuraEnabled public Boolean hasDeliveredScan{ get; set; }
        @AuraEnabled public Boolean isEnquiryDateWithinEDDPlusBusinessdays{ get; set; }
        @AuraEnabled public Boolean isEnquiryDatePastEDDPlusBusinessdays{ get; set; }
        @AuraEnabled public Boolean isEnquiryDateWithinEDD{ get; set; }
        @AuraEnabled public Date deliveredByDateFrom{get;set;}
        @AuraEnabled public Date deliveredByDateTo{get;set;}
        @AuraEnabled public Date deliveredByDateToUntil{get;set;}
        @AuraEnabled public Date deliveredByDatePlusBusinessDays{get;set;}
        @AuraEnabled public Boolean isNoEddReturned {get; set;}
        @AuraEnabled public Boolean isEDDEstimated {get; set;}
        @AuraEnabled public Boolean allArticlesSuccessed {get; set;}            // DDS-7977: flag for all articles are either delivered or safe dropped
        @AuraEnabled public Boolean allArticlesNotSuccessed {get; set;}         // DDS-7977: flag for all articles are neither delivered or safe dropped
    }
    
    //-- User Information Wrapper Class
    public class UserDetails{
        @AuraEnabled public String userFullName{get;set;}
        @AuraEnabled public String userEmail{get;set;}
        // @AuraEnabled public String userPhone{get;set;}
        @AuraEnabled public String userContactPhone{get;set;}
        @AuraEnabled public String userContactEmail{get;set;}
        @AuraEnabled public Boolean isUserAuthenticated{get;set;}
        @AuraEnabled public String userFirstName{get;set;}
        @AuraEnabled public String userLastName{get;set;}
        @AuraEnabled public String userContactFirstName{get;set;}
        @AuraEnabled public String userContactLastName{get;set;}
        @AuraEnabled public String userType{get;set;}
    }
    
    //-- Encoded key and data Wrapper Class
    public class EncryptDetails{
        @AuraEnabled public String encodedData{get;set;}
        
        // 28/08/2018 -  added so that we can lookup the global platform cache
        @AuraEnabled public String cacheKey{get;set;}
        //@AuraEnabled public String encodedKey{get;set;}
    }
}