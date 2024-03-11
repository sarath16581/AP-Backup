/**
*
* Description: Create Case with the given params and return the Case Number
*
* History :
* --------------------------------------------------
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
* 2022-02-07 alex.volkov@auspost.com.au Temporarily removed network assignment failure comment until approach to creation of automatic private comments is confirmed
* 2022-01-25 hasantha.liyanage@auspost.com.au DDS-9011 refactor of the method searchTrackingNumber() to handle multiple articles
* 2022-05-04 mahesh.parvathaneni@auspost.com.au DDS-10119 Changed to Mypost general enquiries from Mypost
* 2022-06-06 hasantha.liyanage@auspost.com.au DDS-10974 refactor of CreateCasefromProductandServices method,
*                                                       this has been moved to a new class 'ChasProductsAndServicesController' and the ChasBase class is created and extended here.
*                                                       some of the common shared methods are moved to ChasBase
* 2022-06-20 mahesh.parvathaneni@auspost.com.au DDS-6293 Fix for customer seen safe drop text in case description
* 2022-10-10 hasantha.liyanage@auspost.com.au DDS-12734 exception cheker
* 2022-11-14 thang.nguyen231@auspost.com.au DDS-13602 update case comments
* 2022-11-16 thang.nguyen231@auspost.com.au DDS-13697 exclude the eligible for network from the exception checker
* 2023-09-14 mahesh.parvathaneni@auspost.com.au added cacheable=true for retrieveCommunityURL and getLoggedInUserInfo methods
* 2023-10-10 jacob.isaac@auspost.com.au REQ3267978 - removing all reference of Mail Redirection picklist for International Letters/Parcel Product Cateogry
* 2023-11-20 - Nathan Franklin - Adding a tactical reCAPTCHA implementation to assist with reducing botnet attack vectors (INC2251557)
* 2024-02-14 - Swati Mogadala - REQ3414153 Adding address details to case description 
*/
public with sharing class ChasApexController extends ChasBase{

    public static ChasApexController getInstance() {
        return (ChasApexController)Application.Utilities.getInstance(ChasApexController.class);
    }

    @AuraEnabled(cacheable=true)
    public static String retrieveCommunityURL(){
        try {
            return ConnectApi.Communities.getCommunity(Network.getNetworkId()).siteUrl;
        } catch (Exception er) {
            throw new AuraHandledException(er.getMessage());
        }
    }
    
    @AuraEnabled
    public static CaseWrapper createCaseFromComplaintWizard( Map <String,String> wizardData){
        //System.debug('----- createCaseFromComplaintWizard ----- START');
        
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
            
            
            //-- Creating Case
            Database.SaveResult[] results = Database.insert(new SObject[] {toBeCreateCase });
            //-- Parse Case results and create Case Comment
            List<CaseComment> comments = new List<CaseComment>();
            comments.add(new CaseComment(CommentBody = commentBody, IsPublished = true));
            SharingBypass lSharingBypass = new SharingBypass();
            caseWrapper = lSharingBypass.parseInsertedCaseResultsAndCreateComment(results, caseWrapper, comments);
            
        }catch(Exception ex){
            caseWrapper.caseStatus = 'ERROR';
            System.debug('*** - Error while creating Case/CaseComment/retrieving CaseID ==='+ex);
        }
        return caseWrapper ;
        
    }
    
        /**
* This method will create Case for Missing Item Wizard
* */
    @AuraEnabled
    public static CaseWrapper createCaseFromMissingWizard( Map <String,String> wizardData, Map <String,String> authUserData ){
        //wizardData = ChasUtil.sanitizeMap(wizardData);
        CaseWrapper caseWrapper = new CaseWrapper();
        caseWrapper.caseStatus = 'SUCCESS';
         try {

             String typeAndProduct = null;
             String productSubCategory = null;
             String subject = null;
             String caseOriginator = null;

             String type = ChasConstants.INVESTIGATION;

             // DDS-8586
             // is the search eligible for multiple article selection?
             Boolean isEligibleForMultipleArticleSelection = (String.isNotEmpty(wizardData.get('isEligibleForMultipleArticleSelection'))) && 'true'.equalsIgnoreCase(wizardData.get('isEligibleForMultipleArticleSelection'));
             // this eligibility parameter is from the top level not the individual article level,
             // this could be changed based on the user's interactions from the UI
             Boolean isEligibleForMyNetworkAssignmentWizardLevel = (String.isNotEmpty(wizardData.get('isEligibleForMyNetworkAssignment'))) && 'true'.equalsIgnoreCase(wizardData.get('isEligibleForMyNetworkAssignment'));
             Boolean isMultipleArticlesSelected = false;            // are multiple article selected
             Boolean isDeliveredByMultipleDeliveryCenters = false;  // are those selected multiple articles are delivered from different delivery centers
             Boolean isAllSelectedArticlesDelivered = false;                // are those all selected multiple articles are delivered
             Boolean isAllArticlesSelectedAreEligibleForNetwork = false; // if either a single selected article of multiple selected articles are eligible for network
             Boolean allArticlesSuccessful = false; // if either a single selected article of multiple selected articles are eligible for network
             List<TrackingNumberDetails> selectedArticles = new List<TrackingNumberDetails>(); // hold the selected articles
             List<TrackingNumberDetails> allArticles = new List<TrackingNumberDetails>(); // hold the selected articles

             // are all the articles succesful in the consignment?
             allArticlesSuccessful = (String.isNotEmpty(wizardData.get('allArticlesSuccessful'))) && 'true'.equalsIgnoreCase(wizardData.get('allArticlesSuccessful'));

             // get the selected articles from the wizardData, this could be either single article selected or multiple/
             // regardless of isEligibleForMultipleArticleSelection this must have at least one article.
             selectedArticles = getArticles(wizardData, true);
             allArticles = getArticles(wizardData, false);
             // checking whether the article searched performed is eligible for multiple article selection or not,
             // if it is allowed routing needs to be changed accordingly
             if (isEligibleForMultipleArticleSelection) {
                 // in case if the UI validation failed when user proceeds without selecting at least one article, user must not allow to create a case.
                 if (selectedArticles.isEmpty()) {
                     throw new AuraHandledException('At least one article must be selected to submit an enquiry');
                 }
                 // is multiple articles selected
                 isMultipleArticlesSelected = isMultipleArticlesSelected(selectedArticles);

                 // if there are multiple articles, are they delivered from deferment delivery centers?
                 if (isMultipleArticlesSelected) {
                     isDeliveredByMultipleDeliveryCenters = isDeliveredByMultipleDeliveryCenters(selectedArticles);
                 }
                 // all the selected articles are delivered? even when there is a single article selected, we should get the isDelivered result
                 isAllSelectedArticlesDelivered = isAllArticlesDelivered(selectedArticles);
                 // either a single selected article of multiple selected articles are eligible for network
                 isAllArticlesSelectedAreEligibleForNetwork = isAllArticlesSelectedAreEligibleForNetwork(selectedArticles);
             }

             //--        Getting recordType Id
             String recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ChasConstants.CASE_RECORDTYPE_SSSWDELIVERY).getRecordTypeId();
             String enquirySubType = wizardData.get('enqSubtype'); //Enquiry subtype is decided in the searchTrackingNumber method when deciding the tracking message
             Datetime EDDPlusBusinessDays = !String.isEmpty(wizardData.get('deliveredByDateToUntil')) ? Date.valueOf(wizardData.get('deliveredByDateToUntil')) : !String.isEmpty(wizardData.get('deliveredByDatePlusBusinessDays')) ? Date.valueOf(wizardData.get('deliveredByDatePlusBusinessDays')) : null;
             // cases which are raised within EDD or EDD plus business days, plus dont have a delivered scan are eligible for hold
             Boolean isEligibleForHold = false;
             // RSolomon 2nd Apr: Sources value of radio button on form, that indicates if parcel contains essential medication
             Boolean containsPharma = ('yes'.equalsIgnoreCase(wizardData.get('selectedRadio4Name')));

			 Boolean isExpressPost = wizardData.get('selectedRadio3Name') == ChasConstants.EXPRESS_POST? true:false;

             // DDS-5273: article that contains pharma should not be held
             if (!containsPharma && !isExpressPost) {
                 if (!isMultipleArticlesSelected // DDS-8586 4. ignore holding for more than one tracking id and all of them are delivered but delivered by different delivery centres (non medication/medication priority set above in existing logic)
                         && String.isEmpty(wizardData.get('latestDeliveredScanWcid')) && ((!String.isEmpty(wizardData.get('isEnquiryDateWithinEDDPlusBusinessdays')) && 'true'.equalsIgnoreCase(wizardData.get('isEnquiryDateWithinEDDPlusBusinessdays'))) ||
                         !String.isEmpty(wizardData.get('isEnquiryDateWithinEDD')) && 'true'.equalsIgnoreCase(wizardData.get('isEnquiryDateWithinEDD')))) {
                     // avoid cases for which the case reopen date falls on the case creation date
                     if (EDDPlusBusinessDays != null && EDDPlusBusinessDays != System.today()) {
                         isEligibleForHold = true;
                     }
                 }
             }
             // if the enquiry subtype is tracking the enquiry type should be set to general enquiry, and the record type has to be General Enquiry
             // exclude cases which are eligible for hold
             if (ChasConstants.ENQ_SUB_TYPE_TRACKING.equals(enquirySubType)) {
                 if (isEligibleForHold) {
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

             Boolean isEligibleForMyNetwork = false;

             // DDS-8586 allow network for single delivery centers : more than one tracking id and tracking ids are all delivered from same delivery centre (non medication/medication priority set above in existing logic)
             if (isEligibleForMultipleArticleSelection) {
                 // DDS-8586 2. if multiple articles selected and not delivered by different delivery centers and all articles are in delivered status
                 if (isMultipleArticlesSelected && !isDeliveredByMultipleDeliveryCenters && isAllArticlesSelectedAreEligibleForNetwork) {
                     isEligibleForMyNetwork = true;
                 }

                 // DDS-8586 5. Single article selected and, the selected article is eligible for network: assign to network
                 if (!isMultipleArticlesSelected && isEligibleForMyNetworkAssignmentWizardLevel) {
                     isEligibleForMyNetwork = true;
                 }
             } else { // if NOT eligible for multiple article selection
                 // only if a single article is selected when multiple article selection is not allowed.
                 // this is to cater the old behaviour where we treat the search as one sigle article
                 if (allArticles.size() == 1) {
                     // DDS-6115 Direct to Network - Do not assign directly unless manifest matches address
                     Boolean dpidNotMatched = (String.isNotBlank(allArticles[0].dpid) && String.isNotBlank(wizardData.get('recipientDPID'))) && allArticles[0].dpid != wizardData.get('recipientDPID');
                     // if user selected address anf the manifest address is available and they doesn't match, then do not let the logic to assign to network.
                     isEligibleForMyNetwork = (dpidNotMatched ? false : isEligibleForMyNetworkAssignmentWizardLevel);
                 } else if (allArticles.size() > Integer.valueOf(ChasUtil.CHAS_SETTINGS.Consignment_Search_Display_Max_Articles__c)) {
                     // in case if the search is not allowed multiple selection and consignment has more than 5 articles.
                     // this is the only place we check for allArticlesSuccessful
                     if (isEligibleForMyNetworkAssignmentWizardLevel && allArticlesSuccessful) {
                         isEligibleForMyNetwork = true;
                     }
                 }
             }


            // if the case is eligible for my network , assign the type to INVESTIGATION and enquirySubType to Disputed delivery scan
            if(isEligibleForMyNetwork) {
                type = ChasConstants.INVESTIGATION;
                enquirySubType = ChasConstants.ENQ_SUB_TYPE_DISPUTED;
            }
            // reference ID to save against the case
            String referenceId = getReferenceId(wizardData, isEligibleForMultipleArticleSelection, isMultipleArticlesSelected, selectedArticles, allArticles);
            String productCategory= wizardData.get('selectedRadio2Name');
            String datePostedStr= wizardData.get('itemSentDate');
            // if EDD range is available consider the "deliveredByDateTo" as EDD, otherwise consider deliveredByDateOrEDD
            String EDD= !String.isEmpty(wizardData.get('deliveredByDateTo'))? wizardData.get('deliveredByDateTo'): wizardData.get('deliveredByDateOrEDD');

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
            String issueDetails = ChasUtil.sanitizeString(wizardData.get('issueDetails'));
            String reasonForEnquiry = ChasUtil.sanitizeString(wizardData.get('reasonForEnquiry'));
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

            if(wizardData.get('selectedRadio1Name') == ChasConstants.RECEIVER || wizardData.get('selectedRadio1Name') == ChasConstants.RECIPIENT) {
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
            String complaintDetails = ChasUtil.sanitizeString(wizardData.get('complaintDetails'));
            String issueDetailsDisplayText = '';
            if(!String.isEmpty(complaintDetails)) {
                issueDetailsDisplayText = '\n' + 'Issue Details : ' + complaintDetails;
            }

             String consignmentSearchComments = '';
             // get the consignment search type comments, based on the scenarios where user is allowed/not allowed to select multiple articles and/or
             // user select multiple articles or a single article the comments will be generated
             consignmentSearchComments = getConsignmentSearchTypeComments(isEligibleForMultipleArticleSelection, isMultipleArticlesSelected, containsPharma, isDeliveredByMultipleDeliveryCenters, isAllSelectedArticlesDelivered);

             //  When user is allowed to select multiple articles and user selects multiple articles OR,
             //  user is not allowed to select multiple articles and there are more than maximum allowed selection of articles in the consignment
             consignmentSearchComments += getConsignmentSearchSelectedArticleIdsComment(isEligibleForMultipleArticleSelection, isMultipleArticlesSelected, selectedArticles, allArticles);

             // append the 'Consignment Search' header if there are comments
             consignmentSearchComments = String.isEmpty(consignmentSearchComments) ? '' : 'Consignment Search \n'+consignmentSearchComments;

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
                if(String.IsNotEmpty(reasonForEnquiry))
                {
                    commentBody = commentBody + 'Reason for enquiry : ' + reasonForEnquiry+ '\n';
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
                if(isEligibleForMyNetwork)
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
                if(String.IsNotEmpty(reasonForEnquiry))
                {
                    commentBody = commentBody + 'Reason for enquiry : ' + reasonForEnquiry+ '\n';
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
                if(isEligibleForMyNetwork)
                {
                    commentBody = commentBody + 'Is eligible for network assignment : ' + 'Yes';
                } else
                {
                    commentBody = commentBody + 'Is eligible for network assignment : ' + 'No';
                }
            }
            // write to case comments if the case was held
            if(isEligibleForHold) {
                commentBody = commentBody + '\n'+ Label.ChasCaseEligibleForHoldMessage;
            } else if (!containsPharma) {
                commentBody = commentBody + '\n'+ Label.ChasCaseEligibleForHoldMessageNo;
            }
            // write to case comments if edd was estimated
            if(wizardData.get('isEDDEstimated') == 'true'){
                commentBody = commentBody + '\n'+ 'Estimated EDD: Yes';
            }

            //-- Subject : Trimming the complaint details to 255 chars
            if(String.IsNotEmpty(issueDetails)){
                if(wizardData.get('issueDetails').trim().length() > 255){
                    subject = issueDetails.substring(0, 255);
                }else{
                    subject = issueDetails;
                }
            }
            
            //-- Assigning Case Originator
            if(wizardData.get('selectedRadio1Name') !=null){
                if(wizardData.get('selectedRadio1Name') == ChasConstants.RECEIVER || wizardData.get('selectedRadio1Name') == ChasConstants.RECIPIENT){
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
            if(containsPharma) {
                toBeCreateCase.Priority = 'High';
            }

             // DDS-12944  is before EDD + 10 and is after EDD + 10 comments and does not contains pharma
             if (!isEligibleForHold && !containsPharma && !isEligibleForMyNetwork && convertedEDD !=null) { // EDD plus 10 passed + not essential medication + not eligible for network + has EDD
                 // DDS-12734 exception check
                 // if a single article is searched or a single article being selected from multiple to raise a case
                 if(allArticles.size() == 1 || selectedArticles.size() == 1) {
                     TrackingNumberDetails articlesDetail = new TrackingNumberDetails();
                     // if user search for a consignment and selects a single article
                     if(isEligibleForMultipleArticleSelection && selectedArticles.size() == 1) {
                         articlesDetail =  selectedArticles[0];
                     } else if(!isEligibleForMultipleArticleSelection && allArticles.size() == 1) {
                         // if user search only for an article
                         articlesDetail =  allArticles[0];
                     }
                     List<ExceptionCheckerService.ExceptionCheckDTO> exceptionCheckDTOS = new List<ExceptionCheckerService.ExceptionCheckDTO>();
                     ExceptionCheckerService.ExceptionCheckDTO exceptionCheckDTO= new ExceptionCheckerService.ExceptionCheckDTO();

                     // set case, this is to check the receiver
                     exceptionCheckDTO.CaseToCheck = toBeCreateCase;

                     List<ExceptionCheckerService.EventMessageDTO> eventMessageDTOs = new List<ExceptionCheckerService.EventMessageDTO>();
                     for(EventMessage msg : articlesDetail.eventMessages) {
                         ExceptionCheckerService.EventMessageDTO eventMessageDTO = new ExceptionCheckerService.EventMessageDTO();
                         eventMessageDTO.ActualDateTime = msg.actualDateTime;
                         eventMessageDTO.EventType = msg.eventType;
                         eventMessageDTOs.add(eventMessageDTO);
                     }
                     // set event messages
                     exceptionCheckDTO.eventMessages = eventMessageDTOs;
                     exceptionCheckDTOS.add(exceptionCheckDTO);

                     //calling the exception checker service for to be created case
                     List<ExceptionCheckerService.ExceptionResultDTO> exceptionResults = ExceptionCheckerService.getInstance().isExceptionApplies(exceptionCheckDTOS);
                     if(exceptionResults != null && exceptionResults[0].isException) {
                         // DDS-12944 Exception found upon case being raised
                         commentBody = commentBody + '\n'+ Label.AutoLITExceptionYes;
                     } else if(exceptionResults != null && !exceptionResults[0].isException){
                         toBeCreateCase.ClosedBySystem__c = true;
                         toBeCreateCase.Status = 'Closed';
                         toBeCreateCase.ByPassWorkflowRulesOnCreation__c = true;
                         // Exception found upon case being raised (when EDD+10 has already passed at time of case raised)
                         commentBody = commentBody + '\n'+ Label.AutoLITExceptionNo;
                     }
                 }
             }

            // 2019/10/09 - Issue Description to be set as Case Description, warning message to case reader is added if the user entered something in the issue details section
            if(!String.isEmpty(complaintDetails)) {
                toBeCreateCase.Description = Label.HS_Issue_Details_Warning +'\n\n'+ complaintDetails + '\n\n';
            }

            // DDS-6293 Fix for customer seen safe drop text in case description
            // Change made for roll out of Safe Drop feature on Missing Items form : add reason for enquiry to the case description
            if(String.IsNotEmpty(reasonForEnquiry))
            {
                String description = toBeCreateCase.Description != null ? toBeCreateCase.Description : '';
                toBeCreateCase.Description = description + 'Reason for enquiry : ' + reasonForEnquiry + '\n';
            }
            // Change made for roll out of Safe Drop feature on Missing Items form : has customer seen safe drop image to the case description
            if(isEligibleForMyNetwork)
            {
                String description = toBeCreateCase.Description != null ? toBeCreateCase.Description : '';
                if(wizardData.get('hasCustomerSeenSafeDrop') == 'true')
                {
                    toBeCreateCase.Description = description +'Has customer seen safedrop image : ' + 'Yes' + '\n';
                } else
                {
                    toBeCreateCase.Description = description +'Has customer seen safedrop image : ' + 'No' + '\n';
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
            // certain cases can be auto allocated from H&S directly to MyNetwork
            // this criteria is assessed here and if the criteria matches then the case is created and then updated to point to mynetwork
            // 17-08-2021 Updated to assign directly on creation

             if(!String.isEmpty(wcid) && isEligibleForMyNetwork) {
                 setDirectRoutingValues(toBeCreateCase, RoutingBypass.NETWORK, wcid);
             }

            //if eligible for hold, run the async process to update case details on case creation to put it ON HOLD and set a Reopen date
            // 17-08-2021 switched to direct routing
            if(isEligibleForHold) {
                setDirectRoutingValues(toBeCreateCase, RoutingBypass.HOLD, null);
            }

             // DDS-9811 Multiple article selection - update Description field (Message to Network is the field label on the UI)
             if(isMultipleArticlesSelected) {
                 toBeCreateCase.Description = toBeCreateCase.Description + '\n' + consignmentSearchComments;
             }

			 Database.SaveResult[] results;
             SharingBypass lSharingBypass = new SharingBypass();
             if (toBeCreateCase.Automated_Network_Assignment__c && toBeCreateCase.Network__c != null){
				results = lSharingBypass.insertSObjects(new SObject[] {toBeCreateCase});
			}
			else {
				results = Database.insert(new SObject[] {toBeCreateCase });
			}
            List<CaseComment> vComments = new List<CaseComment>(); // DDS-9235, DDS-8594 updating the case comments for different types of article selection
            commentBody += '\n' +consignmentSearchComments; // adding the
            vComments.add(new CaseComment(CommentBody = commentBody, IsPublished = true));
        //temporarily removed due to inability to make case comment private in authenticated community user context
        //checkNetworkAssigningResult(toBeCreateCase, vComments);
      //-- Parse Case results and create Case Comment
             caseWrapper = lSharingBypass.parseInsertedCaseResultsAndCreateComment(results, caseWrapper, vComments);

            // checkNetworkAssigningResult(toBeCreateCase);
            
            //            // 2019/09/30 start a queueable to assign the Network if the criteria matches
            //            String eddStatus = (String) wizardData.get('eddStatus');
            //            System.debug('ChasApexController eddStatus = ' + eddStatus + ', wcid = ' + wcid);
            //if( ChasCaseAssignment.VALID_STATUSES.indexOf(eddStatus) >= 0 && (wcid != null && wcid != '') && (String.isEmpty(wizardData.get('isReturnToSender')) || String.valueOf(wizardData.get('isReturnToSender')) == 'false')) {
            
         } catch (Exception ex) {
             System.debug('Error on case creation :: ' + '(MESSAGE):' + ex.getMessage() +
                     '(STACKTRACE):' + ex.getStackTraceString() +
                     '(LINENUMBER):' + ex.getLineNumber() +
                     '(CAUSE):' + ex.getCause());
             caseWrapper.caseStatus = 'ERROR';
         }
        return caseWrapper;
    }

    /**
     * get the consignment search type comments, based on the scenarios where user is allowed/not allowed to select multiple articles and/or
     * user select multiple articles or a single article the comments will be generated
     * @param isMultipleArticlesSelected is user allowed to select multiple articles
     * @param containsPharma is user mentioned there is pharma in the package
     * @param isDeliveredByMultipleDeliveryCenters are the articles selected are delivered from multiple delivery centers
     * @param isAllArticlesDelivered are all articles selected are delivered
     * @param isEligibleForMultipleArticleSelection is it eligible for multi select, populate comments only if this is true
     *
     * @return generate consignment type comments
     */
    private static String getConsignmentSearchTypeComments(Boolean isEligibleForMultipleArticleSelection ,Boolean isMultipleArticlesSelected, Boolean containsPharma, Boolean isDeliveredByMultipleDeliveryCenters, Boolean isAllArticlesDelivered) {
        String consignmentTypeComments = '';
        // when it is not allow to select multiple articles, there is no need of the 'Consignment Type : ' comment
        if(!isEligibleForMultipleArticleSelection) {
            return consignmentTypeComments;
        }
        if (!isMultipleArticlesSelected) {
            // Customer selects only one tracking id from the list
            consignmentTypeComments = 'Consignment Type: Single article selected' + (containsPharma ? ' (medication).' : '.') + '\n';
        } else if (isMultipleArticlesSelected && !isDeliveredByMultipleDeliveryCenters && isAllArticlesDelivered) {
            //  Customer select more than one tracking id and tracking ids are all delivered from same delivery centre (medication)
            consignmentTypeComments = 'Consignment Type: Disputed delivery for multiple articles' + (containsPharma ? ' (medication).' : '.') + '\n';
        } else if (isMultipleArticlesSelected && isDeliveredByMultipleDeliveryCenters && isAllArticlesDelivered) {
            //  Customer selects more than one tracking id and all of them are delivered but delivered by different delivery centres (medication)
            consignmentTypeComments = 'Consignment Type: Disputed delivery for multiple articles with different delivery centres' + (containsPharma ? ' (medication).' : '.') + '\n';
        } else if (isMultipleArticlesSelected && isDeliveredByMultipleDeliveryCenters && !isAllArticlesDelivered) {
            //  Customer select more than one tracking id and at least one article is not delivered (medication)
            consignmentTypeComments = 'Consignment Type: Multiple articles selected mix of delivered and in transit' + (containsPharma ? ' (medication).' : '.') + '\n';
        }
        return consignmentTypeComments;
    }

    /**
     * When user is allowed to select multiple articles and user selects multiple articles OR,
     * user is not allowed to select multiple articles and there are more than maximum allowed selection of articles in the consignment
     * @param isEligibleForMultipleArticleSelection is the consignment search allowed multiple selection of articles?
     * @param isMultipleArticlesSelected is user allowed to select multiple articles
     * @param selectedArticles selected articles when allowed multiple
     * @param allArticles all the articles in the consignment
     *
     * @return selected article IDS comment
     */
    private static String getConsignmentSearchSelectedArticleIdsComment(Boolean isEligibleForMultipleArticleSelection, Boolean isMultipleArticlesSelected, List<TrackingNumberDetails> selectedArticles, List<TrackingNumberDetails> allArticles) {
        String selectedArticleIdsComment = '';
        // when eligible for multi selection ans user selects more than a single article, we cannot store all the article id's in reference ID field
        // so let's let the agent/network know what are the tracking ids selected for consignment
        if (isEligibleForMultipleArticleSelection && isMultipleArticlesSelected) {
            List<String> selectedArticleIDS = new List<String>();
            for (TrackingNumberDetails article : selectedArticles) {
                selectedArticleIDS.add(article.articleId);
            }
            selectedArticleIdsComment = 'Tracking IDs:\n'+String.join(selectedArticleIDS, '\n');
        } else if (!isEligibleForMultipleArticleSelection && allArticles.size() > Integer.valueOf(ChasUtil.CHAS_SETTINGS.Consignment_Search_Display_Max_Articles__c)) {
            // user is not allowed to select multiple articles since the number of articles in the consignment exceeds the allowed number of articles
            selectedArticleIdsComment = 'More than 5 articles in consignment \n';
        }
        return selectedArticleIdsComment;
    }

    /**
     * get the reference Id based on the eligibility to multi select and the selection of articles.
     * @param wizardData JSON data passed in to controller
     * @param isEligibleForMultipleArticleSelection eligibility based on the number of articles in a consignment or a tracking id being a single article id
     * @param isMultipleArticlesSelected based on the eligibility user selected more than one article
     * @param selectedArticles user selected articles
     *
     * @return
     */
    private static String getReferenceId(Map<String, String> wizardData
            , Boolean isEligibleForMultipleArticleSelection
            , Boolean isMultipleArticlesSelected
            , List<TrackingNumberDetails> selectedArticles
            , List<TrackingNumberDetails> allArticles) {
        // this could be the article id or the consignment id used to search the tracking
        String referenceId = wizardData.get('trackingId');
        // if eligible for multiple article selection and only single article is selected, reference Id should be the selected article ID
        if (isEligibleForMultipleArticleSelection && !isMultipleArticlesSelected) {
            // get the selected article's article ID
            referenceId = selectedArticles[0].articleId;
        } else if (!isEligibleForMultipleArticleSelection && allArticles.size() == 1) {
            // if multiple selection is not allowed and consignment has only a single article
            referenceId = allArticles[0].articleId;
        }
        return referenceId;
    }

    /**
     * When user selects multiple articles and if all the articles are in Delivered status or not
     * @param selectedArticles selected articles by the user
     *
     * @return is all deliveres or not
     */
    private static Boolean isAllArticlesDelivered(List<TrackingNumberDetails> selectedArticles) {
        for (TrackingNumberDetails selectedArticle : selectedArticles) {
            if (!(String.isNotEmpty(selectedArticle.eddStatus)
                    && (ChasConstants.TRACK_STAT_LEFT_IN_A_SAFE_PLACE.equalsIgnoreCase(selectedArticle.eddStatus)
                    || ChasConstants.TRACK_STAT_DELIVERED.equalsIgnoreCase(selectedArticle.eddStatus)))) {
                return false;
            }
        }
        return true;
    }

    /**
     * if the selected articles has multiple articles and the articles are delivered by multiple delivery centers
     * @param selectedArticles selected articles by user
     *
     * @return Boolean result
     */
    private static Boolean isDeliveredByMultipleDeliveryCenters(List<TrackingNumberDetails> selectedArticles) {
        Set<String> deliveryCenters = new Set<String>();
        for (TrackingNumberDetails selectedArticle : selectedArticles) {
            deliveryCenters.add(selectedArticle.wcid);
        }

        if (deliveryCenters.size() > 1) {
            return true;
        }
        return false;
    }

    /**
     * if there are multiple articles selected by the user returns true,
     * otherwise false if the user selects one article,
     * NOTE : user will not allow to proceed without selecting at least one article.
     * @param selectedArticles selected articles by user
     *
     * @return Boolean result
     */
    private static Boolean isMultipleArticlesSelected(List<TrackingNumberDetails> selectedArticles) {
        if (!selectedArticles.isEmpty() && selectedArticles.size() > 1) {
            return true;
        }
        return false;
    }

    /**
     * if either multiple articles are selected or a single article selected,
     * check weather the selected areticles are eligible for my network assignment
     * @param selectedArticles
     *
     * @return a boolean value indicating the eligibility
     */
    private static Boolean isAllArticlesSelectedAreEligibleForNetwork(List<TrackingNumberDetails> selectedArticles) {
        if (selectedArticles.isEmpty()) {
            return false;
        }
        for (TrackingNumberDetails selectedArticle : selectedArticles) {
            if(!selectedArticle.isEligibleForMyNetworkAssignment) {
                return false;
            }
        }
        return true;
    }

    /**
     * Filter and get the selected articles from wizardData,
     * returned data based on the attribute isSelected on TrackingNumberDetails
     * @param wizardData contains all the data within the wizard
     *
     * @return list of selected articles
     */
    private static List<TrackingNumberDetails> getArticles(Map<String, String> wizardData, Boolean isSelectedArticlesOnly) {
        List<TrackingNumberDetails> allArticles = new List<TrackingNumberDetails>();
        if(String.isNotEmpty(wizardData.get('articles'))) {
            allArticles = (List<TrackingNumberDetails>) JSON.deserialize(wizardData.get('articles'), List<TrackingNumberDetails>.class);
        }

        List<TrackingNumberDetails> selectedArticles = new List<TrackingNumberDetails>();
        for (TrackingNumberDetails article : allArticles) {
            if (isSelectedArticlesOnly && article.isSelected) {
                selectedArticles.add(article);
            } else if (!isSelectedArticlesOnly) {
                selectedArticles.add(article);
            }
        }
        return selectedArticles;
    }

    /**
* This method will create Case for mail redirect and hold
* */
    @AuraEnabled
    public static CaseWrapper createCaseFromMailRedirectAndHold( Map <String,Object> wizardData, Map <String,String> authUserData ){
        
        CaseWrapper caseWrapper = new CaseWrapper();
        caseWrapper.caseStatus = 'SUCCESS';
        
        try{
            
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
                        //tpeAndProduct = ChasConstants.FEEDBACK_AND_INTERNATIONAL_LETTERS_AND_MAIL_REDIRECTION; //REQ3267978
                        tpeAndProduct = ChasConstants.FEEDBACK_AND_DOMESTIC_LETTERS_AND_MAIL_REDIRECTION;
                        //productCategory = ChasConstants.INTERNATIONAL_LETTERS;//REQ3267978
                        productCategory = ChasConstants.DOMESTIC_LETTERS;
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
            
            Database.SaveResult[] results = Database.insert(new SObject[] {toBeCreateCase });

            List<CaseComment> vComments = new List<CaseComment>();
            vComments.add(new CaseComment(CommentBody = commentBody, IsPublished = true));
            //-- Parse Case results and create Case Comment
            SharingBypass lSharingBypass = new SharingBypass();
            caseWrapper = lSharingBypass.parseInsertedCaseResultsAndCreateComment(results, caseWrapper, vComments);
            
        }catch(Exception ex){
            caseWrapper.caseStatus = 'ERROR';
            System.debug('*** - Error while in createCaseFromMailRedirectAndHold method ==='+ex);
        }
        return caseWrapper;
    }
    
    
    /**
* This method will create Case for delivery issue
* */
    @AuraEnabled
    public static CaseWrapper createCaseFromDeliveryIssue( Map <String,String> wizardData, Map <String,String> authUserData ){
        
        CaseWrapper caseWrapper = new CaseWrapper();
        caseWrapper.caseStatus = 'SUCCESS';
        
        try{
            
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
            
            //-- Building Comment Body
            String commentBody ='Issue details : '  + issueDetailsType ;
            if(issueDetailsType == 'Postie didn\'t knock' || issueDetailsType == 'Item was left in an unsafe place' || issueDetailsType == 'Item was damaged'){
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
            else if(issueDetailsType == 'Postie didn\'t knock'){
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
            toBeCreateCase.Description = 'Issue details : '+ issueDetailsType + '\n';
            if(isEligibleForMyNetworkAssignment == 'true')
            {
                //-- set the value for isEligibleForMyNetworkAssignment to the case field
                setDirectRoutingValues(toBeCreateCase, RoutingBypass.NETWORK, wcid);
                //toBeCreateCase.Description = 'Issue details : '+ issueDetailsType + '\n';
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
            // REQ3414153 Updated Description for Incorrect delivery issue
             if(issueDetailsType == 'Incorrect delivery address needs fixing')
               {
					toBeCreateCase.Description = toBeCreateCase.Description + '\n' +'Incorrect delivery address : '+inCorrectAddress + '\n' +'Correct delivery address : '+correctAddress +'\n\n' ;
                }
             //REQ2361513 -- Modified by Paul Swarnapandian
                if((issueDetailsType == 'Item was left in an unsafe place' || issueDetailsType == 'Postie didn\'t knock') && isEligibleForMyNetworkAssignment == 'true'){
                    commentBody = commentBody + '\n' + 'Is eligible for network assignment : ' + 'Yes';
                }
                else if ((issueDetailsType == 'Item was left in an unsafe place' || issueDetailsType == 'Postie didn\'t knock') && isEligibleForMyNetworkAssignment != 'true'){
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
            
			Database.SaveResult[] results;
            SharingBypass lSharingBypass = new SharingBypass();
			if (toBeCreateCase.Automated_Network_Assignment__c && toBeCreateCase.Network__c != null){
				results = lSharingBypass.insertSObjects(new SObject[] {toBeCreateCase});
			}
			else {
				results = Database.insert(new SObject[] {toBeCreateCase });
			}

            List<CaseComment> vComments = new List<CaseComment>();
            vComments.add(new CaseComment(CommentBody = commentBody, IsPublished = true));
        //temporarily removed due to inability to make case comment private in authenticated community user context
        //checkNetworkAssigningResult(toBeCreateCase, vComments);

            //-- Parse Case results and create Case Comment

            caseWrapper = lSharingBypass.parseInsertedCaseResultsAndCreateComment(results, caseWrapper, vComments);

            //-- Case routing based on the boolean isEligibleForMyNetworkAssignment
            // 17-08-2021 switched to direct routing
           /* if(isEligibleForMyNetworkAssignment == 'true')
            {
                ChasCaseAssignment caseAssignment = new ChasCaseAssignment(toBeCreateCase, wcid);
                Id jobId = System.enqueueJob(caseAssignment);
                
            } */
            
        }catch(Exception ex){
            caseWrapper.caseStatus = 'ERROR';
            System.debug('*** - Error while in createCaseFromDeliveryIssue method ==='+ex);
        }
        return caseWrapper;
    }

	/**
     * @description passing the tracking number will response with all the articles and tracking details linked to the
     * related consignment. Initially this method has been written to handle one article and the behaviour is changed
     * to handle multiple articles as a part of the ticket DDS-9011
     * @param trackingNumber
     *
     * @return ConsignmentDetails: this object is wrapped around a list of TrackingNumberDetails objects and
     * few other common parameters to handle multiple articles in the response.
     */
    @AuraEnabled
    public static ConsignmentDetails searchTrackingNumberWithCaptcha(String trackingNumber, String captchaToken) {
		
		if(UserInfo.getUserId() == null || UserInfo.getUserType().equalsIgnoreCase('Guest')) {
			Consumer_Help_and_Support__c settings = Consumer_Help_and_Support__c.getInstance();

			if(String.isEmpty(captchaToken)) {
				throw new AuraHandledException('reCAPTCHA token is empty');
			}

			String params = 'secret=' + EncodingUtil.urlEncode(settings.reCAPTCHASecretKey__c, 'UTF-8') + '&response=' + EncodingUtil.urlEncode(captchaToken, 'UTF-8');
			HttpRequest req = new HttpRequest();
			req.setEndpoint(settings.reCAPTCHAVerifyURL__c);
			req.setMethod('POST');
			req.setBody(params);
			try{
				Http http = new Http();
				HttpResponse response = http.send(req);

				Map<String, Object> recaptchaResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
				if(recaptchaResponse.get('success') != true) {
					throw new AuraHandledException('Could not verify reCAPTCHA token');
				}
			} catch(AuraHandledException exp) {
				throw new AuraHandledException(exp.getMessage());
			} catch(Exception exp) {
				throw new AuraHandledException('Could not verify reCAPTCHA token');	
			}
		}

		return searchTrackingNumber(trackingNumber);
	}

    /**
     * @description passing the tracking number will response with all the articles and tracking details linked to the
     * related consignment. Initially this method has been written to handle one article and the behaviour is changed
     * to handle multiple articles as a part of the ticket DDS-9011
     * @param trackingNumber
     *
     * @return ConsignmentDetails: this object is wrapped around a list of TrackingNumberDetails objects and
     * few other common parameters to handle multiple articles in the response.
     */
    @AuraEnabled
    public static ConsignmentDetails searchTrackingNumber(String trackingNumber) {
		
		//Initializing the return wrapper obj
        ConsignmentDetails consignmentDetailsWrapperObj = new ConsignmentDetails();
        if (trackingNumber != null && trackingNumber.trim().length() > 0) {

            HttpResponse httpRes = ChasCallout.requestStatus(trackingNumber);

            //Checking the httpResponse Status Codes
            if (httpRes != null) {

                String jsonString = httpRes.getBody();
                String enqSubTypeOverride = '';
                jsonString = jsonString.replace('"on"', '"eventDateTime"'); // replacing the dateTime in the response as this "on" is reserved keyword in apex
                jsonString = jsonString.replace('"from"', '"fromDateTime"');// replacing the from keyword in the response as it is a reserved keyword in apex
                //pares one track response
                ChasOneTrackResponse response = (ChasOneTrackResponse) System.JSON.deserialize(jsonString, ChasOneTrackResponse.class);
                ChasTrackStatus trackService = new ChasTrackStatus(response, trackingNumber);
                //Intilalizing status code in to wrapper
                if (httpRes.getStatusCode() != null) {
                    //trackingNumDetailsWrapperObj.trackingNumSerachStatusCode = httpRes.getStatusCode();
                    consignmentDetailsWrapperObj.trackingNumSerachStatusCode = trackService.responseCode;
                    consignmentDetailsWrapperObj.trackingNumSerachStatusMsg = httpRes.getStatus();
                }

                // DDS-7977: pass attributes from tracking response to wrapper object
                consignmentDetailsWrapperObj.allArticlesSuccessed = trackService.allArticlesSuccessed;

                List<TrackingNumberDetails> trackingNumDetailsWrapperObjs = new List<TrackingNumberDetails>();
                TrackingNumberDetails trackingNumDetailsWrapperObj;

                // if the tracking search result has more than one article and less than five, allow the user to select multiple articles when create case
                consignmentDetailsWrapperObj.isEligibleForMultipleArticleSelection = isEligibleForMultipleArticleSelection(trackService, Integer.valueOf(ChasUtil.CHAS_SETTINGS.Consignment_Search_Display_Max_Articles__c));

                for (ChasTrackStatus.ArticleDetailsWrapper article : trackService.articleDetailsWrappers) {
                    trackingNumDetailsWrapperObj = new TrackingNumberDetails();
                    trackingNumDetailsWrapperObj.trackingNumSerachStatusCode = consignmentDetailsWrapperObj.trackingNumSerachStatusCode;
                    //Special handling for response code 403
                    if (consignmentDetailsWrapperObj.trackingNumSerachStatusCode == 403) {
                        trackingNumDetailsWrapperObj.enqSubtype = ChasConstants.ENQ_SUB_TYPE_TRACKING;
                        trackingNumDetailsWrapperObj.itemType = ChasConstants.ITEM_TYPE_DOMESTIC;
                    }
                    // DDS-5488: Enquiry sub type should be “tracking” and type should be “general” for 404 response
                    if (consignmentDetailsWrapperObj.trackingNumSerachStatusCode == 404) {
                        trackingNumDetailsWrapperObj.enqSubtype = ChasConstants.ENQ_SUB_TYPE_TRACKING;
                        trackingNumDetailsWrapperObj.itemType = ChasConstants.ITEM_TYPE_DOMESTIC;
                    }
                    //If response status code is 200 then parsing the response
                    if (consignmentDetailsWrapperObj.trackingNumSerachStatusCode == 200) {
                        // setting the global tracking search response status message
                        trackingNumDetailsWrapperObj.trackingNumSerachStatusMsg = httpRes.getStatus();
                        //assign the dpid returned from the service
                        trackingNumDetailsWrapperObj.dpid = article.dpid;
                        //assign the articleId returned from the service
                        trackingNumDetailsWrapperObj.articleId = article.articleId;
                        //change made for roll out of Products and services uplift - assign the subProductId returned from the service
                        trackingNumDetailsWrapperObj.subProductId = article.subProductId;

                        // DDS-12734 exception check
                        List<EventMessage> allEventMessages = new List<EventMessage>();
                        // passing all the events from one track to backend
                        for (ChasTrackStatus.EventMessage event : article.events) {
                            EventMessage eventMessage = new EventMessage();
                            eventMessage.actualDateTime = event.actualDateTime;
                            eventMessage.eventType = event.eventType;
                            allEventMessages.add(eventMessage);
                        }
                        trackingNumDetailsWrapperObj.eventMessages = allEventMessages;

                        //fetch the safedDropDelivered date time
                        Datetime safedropDeliveredDateTime = article.safedropDeliveredDateTime;
                        String safedropDelivered = '';
                        //Convert the data time format to a desired format like "11:31 am, Wednesday 8 April"
                        if (safedropDeliveredDateTime != null) {
                            String dayOfWeek = safedropDeliveredDateTime.format('EEEE');
                            String dateOfWeek = safedropDeliveredDateTime.format('d MMMM ');
                            String timeOfWeek = safedropDeliveredDateTime.format('hh:mm a');
                            safedropDelivered = timeOfWeek + ', ' + dayOfWeek + ' ' + dateOfWeek;
                            trackingNumDetailsWrapperObj.safedropDelivered = safedropDelivered;
                        }

                        //if safedropped, then assign the edd status
                        if (trackingNumDetailsWrapperObj.safedropDelivered != null) {
                            trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_LEFT_IN_A_SAFE_PLACE;
                        }

                        // article type and the item type will be used to generate the case
                        if (article.articleType != null) {
                            trackingNumDetailsWrapperObj.articleType = article.articleType;
                            trackingNumDetailsWrapperObj.itemType = (article.articleType.containsIgnoreCase(ChasConstants.ITEM_TYPE_INTERNATIONAL) ? ChasConstants.ITEM_TYPE_INTERNATIONAL : ChasConstants.ITEM_TYPE_DOMESTIC);
                        }
                        //setting the value for a duplicate case, derived from the latest event code
                        trackingNumDetailsWrapperObj.duplicateCase = article.duplicateCase;
                        //set RTS scan flag if any
                        trackingNumDetailsWrapperObj.isReturnToSender = article.isReturnToSender;
                        //set signature flag if any
                        trackingNumDetailsWrapperObj.hasSignature = article.hasSignature;
                        //set isParcelAwaitingCollection flag if any
                        trackingNumDetailsWrapperObj.isParcelAwaitingCollection = article.eventCodeisAwaitingCollection;
                        // if there's a work center id (facility code)
                        trackingNumDetailsWrapperObj.wcid = article.wcid;
                        //-- change made for roll out of delivery issues network assignment automation
                        trackingNumDetailsWrapperObj.latestDeliveredScanWcid = article.hasDeliveredScanEvent;
                        trackingNumDetailsWrapperObj.previousDeliveredScanWcid = article.previousDeliveredScanWcid;
                        // set isRedirectApplied flag if any
                        trackingNumDetailsWrapperObj.isRedirectApplied = article.isRedirectApplied;
                        // if there's a latest event location, track it to decide the delivery location state like NSW,VIC etc.Temporary solution to be refactored
                        if (article.latestEvent != null) {
                            trackingNumDetailsWrapperObj.latestEventLocation = article.latestEvent.location;
                            trackingNumDetailsWrapperObj.latestEventLocationMessage = article.latestEvent.message;
                        }
                        // set the article's is delivered
                        trackingNumDetailsWrapperObj.isDelivered = article.isDelivered;
                        //set trackStatusValue value from the milestone
                        trackingNumDetailsWrapperObj.trackStatusValue = article.trackStatusValue;
                        //set deliveryChoicesSafeDropIneligibilityCode flag if any
                        trackingNumDetailsWrapperObj.deliveryChoicesSafeDropIneligibilityCode = article.deliveryChoicesSafeDropIneligibilityCode;
                        // set the value for isEligibleForMyNetworkAssignment
                        trackingNumDetailsWrapperObj.isEligibleForMyNetworkAssignment = article.isEligibleForMyNetworkAssignment;
                        // setting the EDD or delivered date
                        trackingNumDetailsWrapperObj.deliveredByDateOrEDD = article.deliveredByDate;
                        // setting the EDD From DateTime
                        trackingNumDetailsWrapperObj.deliveredByDateFrom = article.deliveredByDateFrom;
                        // // setting the EDD To DateTime
                        trackingNumDetailsWrapperObj.deliveredByDateTo = article.deliveredByDateTo;
                        // setting the EDD monitor date until
                        trackingNumDetailsWrapperObj.deliveredByDateToUntil = article.deliveredByDateToUntil;
                        // setting the EDD plus business days
                        trackingNumDetailsWrapperObj.deliveredByDatePlusBusinessDays = article.deliveredByDatePlusBusinessDays;
                        // check if the system date is within EDD plus business days
                        trackingNumDetailsWrapperObj.isEnquiryDateWithinEDDPlusBusinessdays = article.isEnquiryDateWithinEDDPlusBusinessdays;
                        trackingNumDetailsWrapperObj.isEnquiryDatePastEDDPlusBusinessdays = article.isEnquiryDatePastEDDPlusBusinessdays;
                        trackingNumDetailsWrapperObj.isEnquiryDateWithinEDD = article.isWithinEDD;

                        // this takes the highest priority in deciding what type of enquiry should be raised for the supplied article
                        // this is just for the enquiry type on the case and does not impact the ui feedback provided to a user.
                        if (article.isReturnToSender || article.isDeliveredLeftInASafePlace || (article.isDelivered && !article.deliveryChoicesSafeDropIneligibilityCode)) {
                            enqSubTypeOverride = ChasConstants.ENQ_SUB_TYPE_TRACKING;
                        }
                        // no EDD found, deliveredByDate on the response, update the enquiry subtype as Tracking if a case created
                        if (article.isNoEDDReturned
                                ) {
                            trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_NO_EDD_FOUND;
                            trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_MISSING);
                            // DDS-5272: indicator for no EDD return
                            trackingNumDetailsWrapperObj.isNoEddReturned = true;
                        } else if (article.isDelivered) {
                            // item delivered but submit a case,  update the enquiry subtype as Disputed Scan if a case created

                            trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_DELIVERED;
                            trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_DISPUTED);

                        } else if (article.isDeliveringLate) {
                            //The expected delivered date is passed today,  update the enquiry subtype as Missing item if a case created

                            trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_DELIVERING_LATE;
                            trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_MISSING);

                        } else if (article.isDeliveryOnTime) {
                            // delivering on time, the EDD shows the expected delivery date as a future date, ,  update the enquiry subtype as Tracking if a case created

                            trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_DELIVERING_ON_TIME;
                            trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_TRACKING);

                        } else if (article.isNotScannedYet) {
                            // no scan events found and the status is pending, update the enquiry subtype as Tracking if a case created

                            trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_NOT_SCANNED_YET;
                            trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_TRACKING);

                        } else if (article.isDeliveredLeftInASafePlace) {
                            // item is safe dropped, update the enquiry subtype as Disputed Scan if a case created

                            trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_LEFT_IN_A_SAFE_PLACE;
                            trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_DISPUTED);

                        } else if (article.isAwaitingCollection) {
                            // awaiting collection at the location, ,  update the enquiry subtype as Missing Item if a case created

                            trackingNumDetailsWrapperObj.eddStatus = ChasConstants.TRACK_STAT_AWAITING_COLLECTION;
                            trackingNumDetailsWrapperObj.enqSubtype = (!String.isEmpty(enqSubTypeOverride) ? enqSubTypeOverride : ChasConstants.ENQ_SUB_TYPE_MISSING);
                            // if there's a latest event location, track it to display it for awaiting collection status.
                            trackingNumDetailsWrapperObj.latestEventLocation = article.latestEvent.location;

                        } else if (article.isOnBoardForDelivery) {
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

                        // collecting the prepared individual article information
                        trackingNumDetailsWrapperObjs.add(trackingNumDetailsWrapperObj);
                    }
                    consignmentDetailsWrapperObj.trackingNumberDetails = trackingNumDetailsWrapperObjs;
                }
            }
        }
        return consignmentDetailsWrapperObj;
    }

    /** we will check whether the searched tracking is eligible for multiple article selection,
     * if the response has only one article, not eligible for multi select
     * if the response have more than one article and less than five articles, it is allowed to select multiple articles
     * if the response contain more than 5 articles, multiple article selection is not possible
     * (when we say more than 5 this should be able to fetched from a configurable attribute custom setting/metadata)
    **/
    private static Boolean isEligibleForMultipleArticleSelection(ChasTrackStatus trackService, Integer maxArticles) {
        if (trackService.articleDetailsWrappers != null && !trackService.articleDetailsWrappers.isEmpty()
                && trackService.articleDetailsWrappers.size() > 1
                && trackService.articleDetailsWrappers.size() <= maxArticles) {
                return true;
        }
            return false;
    }

    @AuraEnabled(cacheable=true)
    public static UserDetails getLoggedInUserInfo(){
        UserDetails userDetail = new UserDetails();
        userDetail.isUserAuthenticated = false;
        
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

                if(userObj.ContactId !=null){
                    //-- Querying  Contact Details
                    Contact contactbj = [SELECT Phone, Email, Name, FirstName, LastName FROM Contact WHERE Id= :userObj.ContactId LIMIT 1];
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
        
        return userDetail;
        
    }
    
    /**
*  Encrypt the data
* */
    @AuraEnabled
    public static EncryptDetails encryptData(String inputData){
        
        EncryptDetails encryptDetailObj = null;
        try{
            if(inputData != null && inputData.length() > 0){
                Blob cryptoKey =null;
                //-- Getting crypto key from Custom Settings
                try{
                    Consumer_Help_and_Support__c consumerHelpNSupport = Consumer_Help_and_Support__c.getOrgDefaults();
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
                System.debug(LoggingLevel.DEBUG,'*** ChasApexController.decryptData - decrypted Wizard data from Org Cache'); //decryptStr
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

    // refactoring notes , due to a know issue following variables are duplicated in both this class and the ChasBase
    // https://trailblazer.salesforce.com/issues_view?id=a1p3A000000ENHXQA4
    /**
     * check if there is any exception on network assigning and create corresponding case comment
     * the comment will be private by default
     * @author: phap.mai@auspost.com.au
     * @param iCase: target case
     * @deprecated checkNetworkAssigningResult method seems deprecated
     */
    private static void checkNetworkAssigningResult(Case iCase, List<CaseComment> comments)
    {
        // if target case is not an audience of network assignment quit early
        if (iCase.Automated_Network_Assignment__c) {

            SharingBypass helper = new SharingBypass();

            // create case comment if no network id found on network assigning
            if (ChasBase.noNetworkIdFound) {
                comments.add(helper.generateCaseComment('Unable to find network with requested org ID: ' + ChasBase.unavailableOrgId, false));
            }

            // create case comment if no network group found in network assigning
            if (ChasBase.noNetworkGroupFound) {
                comments.add(helper.generateCaseComment('Unable to find network queue for the requested org ID: ' + ChasBase.unavailableOrgId, false));
                // helper.createCaseComment(iCase.Id, comment, false, true);
            }
        }
    }

    /**
     * DTO to transfer consignment details,
     * a consignment could contain one or more articles, article specific information are delivered as a list of TrackingNumberDetails
     */
    public class ConsignmentDetails{
        @AuraEnabled public List<TrackingNumberDetails> trackingNumberDetails{get;set;}
        @AuraEnabled public Integer trackingNumSerachStatusCode{get;set;}
        @AuraEnabled public String trackingNumSerachStatusMsg{get;set;}
        @AuraEnabled public Boolean allArticlesSuccessed {get; set;}                    // DDS-7977: flag for all articles are either delivered or safe dropped
        @AuraEnabled public Boolean isEligibleForMultipleArticleSelection {get; set;}  // DDS-9011: is the tracking search is allowed to select multiple articles?
    }


    //-- TrackingNumberDetails Wrapper Class
    public class TrackingNumberDetails{
        @AuraEnabled public String articleId{get;set;}
        // is the article is selected from the UI only if eligible for multiple selection
        @AuraEnabled public Boolean isSelected {
            get {
                if (isSelected == null) {
                    return false;
                } else {
                    return isSelected;
                }
            }
            set;
        }
        @AuraEnabled public String articleType{get;set;}   //from Response, Ex:International, International Express,StarTrack International
        @AuraEnabled public Date deliveredByDateOrEDD{get;set;}
        //@AuraEnabled public String deliveredByDateFormatted{get;set;}
        @AuraEnabled public String eddStatus{get;set;}   // dateNotfound, datePassed, dateNotPassed
        @AuraEnabled public String itemType{get;set;}  // 'Domestic' or 'International'*/
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
        // is article delivered
        @AuraEnabled public Boolean isDelivered {
            get {
                if (isDelivered == null) {
                    return false;
                } else {
                    return isDelivered;
                }
            }
            set;
        }
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
        @AuraEnabled public List<EventMessage> eventMessages {
            get {
                if (eventMessages == null) {
                    return new List<EventMessage>();
                } else {
                    return eventMessages;
                }
            }
            set;
        }
    }
    public class EventMessage {
        @AuraEnabled public String eventType { get; set; }
        @AuraEnabled public DateTime actualDateTime { get; set; }
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