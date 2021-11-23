/**
* @description       : BCAFormController helper class
* @author            : avula.jansirani@auspost.com.au
* @group             : 
* @last modified on  : 05-14-2021
* @last modified by  : ankur.gandhi@auspost.com.au
* Modifications Log 
* Ver   Date         Author                               Modification
* -------------------------------------------------------------------------
* 1.0   24-03-2021  avula.jansirani@auspost.com.au   Initial Version 
*       26-03-2021  victor.cheng@auspost.com.au             Added ContentDocument methods
**/
public without sharing class BCAFormHelper {

    // parser for JSON data from LWC
    public class relatedFile {
        public String PathOnClient;
        public String Title;
        public Blob VersionData;
    }

    /**
     * @param file JSON Object from LWC
     *
     * @return returns a wrapper object with the status and contentDocumentId, used for linking on submit
     */
    public static SaveFileResult createContentDocument(Map<String, Object> file)
    {
        SaveFileResult result = new SaveFileResult();

        String fileJson = JSON.serialize(file);
        relatedFile relatedDocument = (relatedFile) JSON.deserialize(fileJson, relatedFile.class);
        ContentVersion contentVersionFile = new ContentVersion();
        contentVersionFile.PathOnClient = relatedDocument.PathOnClient;
        contentVersionFile.Title = relatedDocument.Title;
        contentVersionFile.VersionData = relatedDocument.VersionData;

        // changed to stubbing
        Database.SaveResult[] srFiles = ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{contentVersionFile});
        if(srFiles[0].isSuccess())
        {
            result.contentVersion = contentVersionFile;

            List<ContentVersion> cvs = ContentVersionsSelector.newInstance().selectById(new Set<Id>{contentVersionFile.Id}).values();
            System.debug('BCAFormHelper:: createContentDocument: ' + cvs);

            result.contentDocumentId = cvs[0].ContentDocumentId;
            result.previewUrl = URL.getOrgDomainUrl().toExternalForm() + '/sfc/servlet.shepherd/document/download/' + result.contentDocumentId;
            //result.previewUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + contentVersionFile.Id;
            result.status = BCAFormConstants.OK;
        }
        else
        {
            result.status = BCAFormConstants.ERROR;
            result.message = '';
            for(Database.Error err : srFiles[0].getErrors()) {
                System.debug('The following error has occurred.');
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('Fields that affected this error: ' + err.getFields());

                result.message += err.getMessage();
            }
        }

        return result;
    }


    public static SaveFileResult deleteContentDocument(String contentDocumentId)
    {
        SaveFileResult delResult = new SaveFileResult();
        try{
            List<ContentDocument> files = ContentDocumentsSelector.newInstance().selectById(new Set<Id> {contentDocumentId}).values();
            if(files.size() == 1){
                //delete files;
                ApplicationDatabase.getInstance().dmlDelete(files);
                delResult.status = BCAFormConstants.OK;
            }
            else {
                delResult.status = BCAFormConstants.ERROR;
                delResult.message = 'file not found for docId:' + contentDocumentId;
            }
        }  catch(Exception e) {
            delResult.status = BCAFormConstants.ERROR;
            delResult.message = e.getMessage();
        }
        return delResult;
    }

    /**
    * method to check the duplicate org is present or not. Return 'true' if duplicate found otherwise return 'false'.
    * */
    public static Boolean isDuplicateOrgExists(String abn, String userOrgId){
        System.debug('userinfo. getProfileId()='+userinfo.getProfileId());
        System.debug('UserInfo.getUserId()='+UserInfo.getUserId());
        Boolean isDuplicate = false;
        if(!String.isEmpty(abn)){
            // Setup the user input ABN/ACN data for the duplicate check validation
            List<Account> accDupCheckList = new List<Account>();
            Account accTestDupCheck = new Account();
            
            accTestDupCheck.ABN__c = abn;
            accTestDupCheck.ACN__c = abn;
            accTestDupCheck.recordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{'Business_Account'}).values()[0].Id;
            
            accDupCheckList.add(accTestDupCheck);
            
            isDuplicate = BCAFormBase.containDuplicateABNACN(accDupCheckList, userOrgId);  
        }

        return isDuplicate;
        
    }
    
    /**
    * method for auto refererral check
    *  The method returns 'false' and 'failed reason' if any one check from below is failed. if all passed then return 'true'
    *  1. EntityType is 'Trust' or 'Partnership'
    *  2. Is org is part of hotlist?
    *  3. org type known and existing credit assesment is 'Rejected'
    * 
    *  @param entityTypeGroup : Example 'Government', 'Trust' or 'Partner'
    *  @param userOrgId       : Account Id (User's Org Id)
    * */
    public static ReferralCheckResults isAutoReferred(String entityType, Id userOrgId, String caId){ 
        ReferralCheckResults refCheckResults = new ReferralCheckResults();
          
        //-- 1. If entity type is 'Trust' or ' partner' then returning 'true'(referral check is failed) and 'failed reason'
        if(!String.isEmpty(entityType) && 
           (entityType.equalsIgnoreCase(BCAFormConstants.ENTITY_TYPE_TRUST) || entityType.equalsIgnoreCase(APT_Constants.ENTITY_TYPE_PARTNERSHIP))){
               refCheckResults.isReferred = true;
               if(entityType.equalsIgnoreCase(BCAFormConstants.ENTITY_TYPE_TRUST)){
                   refCheckResults.failedReason = BCAFormConstants.TRUST_REFERRAL_REASON; 
               } 
               else{
                   refCheckResults.failedReason = BCAFormConstants.PARTNERSHIP_REFERRAL_REASON;
               }
               return refCheckResults;
           }
           
        
        if(userOrgId != null && Schema.Account.SObjectType == userOrgId.getSobjectType()){
                        
            Set<SObjectField> fieldOveriedsSet = new Set<SObjectField>{Account.Id, Account.Role_Type_Roll_Up__c, Account.L2C_Hotlist__c};            
            List<Account> accList = AccountsSelector.newInstance(1, fieldOveriedsSet).selectById( new Set<Id>{userOrgId}).values();
           
            If(!accList.isEmpty()){
                
                //-- 2.  Is org is part of hotlist? then returning 'false'(referral check is failed) and 'failed reason' 
                if(accList[0].L2C_Hotlist__c){
                    refCheckResults.isReferred = true;
                    refCheckResults.failedReason = BCAFormConstants.HOTLISTED_CUSTOMER_REFERRAL_REASON;
                    return refCheckResults;
                }
                
                //-- 3. Org type is Known and existing credit assessment record status is rejected' then returning 'false'(referral check is failed) and 'failed reason'
                //--Check if recent created Credit assessment is 'Rejected'
                if(accList[0].Role_Type_Roll_Up__c == 'Known' && 
                    checkIsRecentCreditAssementRecordStatusIsRejected(userOrgId, caId)){
                    refCheckResults.isReferred = true;
                    refCheckResults.failedReason = BCAFormConstants.PREVIOUS_C_A_REJECTED_REFERRAL_REASON;
                    return refCheckResults;
               }
                
            }
        } 
        else{
            System.debug('The user org Id is not of ACcount Sobject Type='+userOrgId); 
            refCheckResults.isReferred = true;
            refCheckResults.failedReason = 'The user org Id is not of ACcount Sobject Type';
            return refCheckResults;  // null
        }
        
        //-- 5. If above all scenarios are 'passed' then 
        refCheckResults.isReferred = false;
        
        return refCheckResults;
    }
    
    /**
     * Get the recent created 'credit assesment record' of the given ACcount(userOrgId),
     * if 'credit assesment record' exists and its 'statu's is 'Rejected' then return 'true' otherwise false
     * */
    private static Boolean checkIsRecentCreditAssementRecordStatusIsRejected(String userOrgId, String caId){  
                
        List<APT_Credit_Assessment__c> caList = CreditsAssessmentSelector.newInstance('CreatedDate', 'Desc', 1).selectByExcludeId(caId,userOrgId).values();
        if(!caList.isEmpty() && !String.isEmpty(caList[0].APT_Credit_Assessment_Status__c)&& caList[0].APT_Credit_Assessment_Status__c == BCAFormConstants.CREDIT_ASSESSMENT_STATUS_REJECTED){
            return true;
        }
        
        return false;
    }
            
    /**
    * method for auto approval check
    *  The method returns 'true' if any one check from below is passed
    *  1. credit amount <= 10000$
    *  2. entityTypeGroup = Government
    * 
    *  @param entityTypeGroup : Example 'Government', 'Trust' or 'Partner'
    *  @param creditAmount       : The bca recommened credit amount
    * */
    public static Boolean isAutoApproved(String entityType, Decimal creditAmount){
        System.debug('creditAmount='+creditAmount);
        //-- 1. If entity type is 'Government' then returning true
        if(!String.isEmpty(entityType) &&  entityType.equalsIgnoreCase(BCAFormConstants.ENTITY_TYPE_GOVERNMENT)){ 
            return true;
        }
        
        //-- 2.  credit amount( <= 10000$, this amount is gessting from CS) then return true
        List<BCA_Settings__c> bcaSetting = [SELECT Id, Name, Number_Value__c FROM BCA_Settings__c WHERE Name = 'Auto_Approval_Max_Credit_Limit' LIMIT 1];
        if(bcaSetting.size() == 1){
            System.debug('bcaSetting[0].Number_Value__c='+bcaSetting[0].Number_Value__c);
            if (creditAmount <= bcaSetting[0].Number_Value__c){
                return true;
            }   
        }  
        
        return false;
    }
    
    /**
     * [Jansi]
     * insert content document links
     * */
    private static void insertContentDocumentLinks(List<ContentDocumentLink> cdlList){
        try{
            if(cdlList.size() > 0){
                ApplicationDatabase.getInstance().dmlInsert(cdlList);
            }   
        }catch(Exception ex){
            System.debug('Error in linking trust fiels to credit assesment record');
        }
    }
    
     /**
     * [Jansi]
     * insert creditassesment networks
     * */
    private static void insertCreditAssesmentNetworks(List<Credit_Assessment_Network__c> outlets){
        try{
            if(outlets.size() > 0){
                ApplicationDatabase.getInstance().dmlInsert(outlets);
                //insert outlets;
            }   
        }catch(Exception ex){
            System.debug('Error in linking outlets to credit assesment record'); 
        }
    }

    private static APT_ASIC_Report__c createASICReport(BCAFormController.ABNReportsCached abnReportsCached)
    {
        if(abnReportsCached != null)
        {
            APT_SchemaPartyCustomerService.ASICReport_element asicReport = abnReportsCached.ASICReport;
            APT_ASIC_Report__c selectedASICReport = new APT_ASIC_Report__c();
            selectedASICReport.APT_ASIC_Name__c = asicReport.ASICName;
            selectedASICReport.APT_Organisation_Number__c = asicReport.ASICOrganisationNumber;
            selectedASICReport.APT_ABN__c = asicReport.ASICABN;
            selectedASICReport.APT_Organisation_Number_Heading__c = asicReport.ASICOrganisationNumberHeading;
            selectedASICReport.APT_Prescribed_Interest_Number__c = asicReport.ASICPrescribedInterestNumber;
            selectedASICReport.APT_Undertaking_Name__c = asicReport.ASICUndertakingName;
            selectedASICReport.APT_Type__c = asicReport.ASICType;
            selectedASICReport.APT_Registration_Date__c = asicReport.ASICRegistrationDate;
            selectedASICReport.APT_Status__c = asicReport.ASICStatus;
            selectedASICReport.APT_State__c = asicReport.ASICState;
            selectedASICReport.APT_Business_Registration_Number__c = asicReport.ASICBusinessRegistrationNumber;
            selectedASICReport.APT_Jurisdiction__c = asicReport.ASICJurisdiction;
            selectedASICReport.APT_Locality__c = asicReport.ASICLocality;
            selectedASICReport.APT_Address_State__c = asicReport.ASICAddressState;
            selectedASICReport.APT_Postcode__c = asicReport.ASICPostcode;
            return selectedASICReport;
        }
        
        return null;
    }
    private static APT_ABRreport__c createABRReport(BCAFormController.ABNReportsCached abnReportsCached)
    {
        if(abnReportsCached != null)
        {
            APT_SchemaPartyCustomerService.AustralianBusinessRegisterReport_element abrReport = abnReportsCached.ABRReport;

            APT_ABRreport__c selectedABRReport = new APT_ABRreport__c();
            selectedABRReport.APT_ASIC_Number__c = abrReport.ASICNumber;
            selectedABRReport.APT_ASIC_Number_Type__c = abrReport.ASICNumberType;
            selectedABRReport.APT_ABN__c = abrReport.ABN;
            selectedABRReport.APT_ABN_Status__c = abrReport.ABNStatus;
            selectedABRReport.APT_ABN_Status_From_Date__c = abrReport.ABNStatusFromDate;
            selectedABRReport.APT_Entity_Type_Text__c = abrReport.EntityTypeText;
            selectedABRReport.APT_Entity_TypeInd__c = abrReport.EntityTypeInd;

            if(abrReport.IndividualName != null){
                selectedABRReport.APT_Individual_Name__c = String.join(abrReport.IndividualName, APT_Constants.SEPARATOR_NEXT_LINE);
            }
            selectedABRReport.APT_Non_Individual_Name__c = abrReport.NonIndividualName;
            selectedABRReport.APT_Business_Address_State__c = abrReport.BusinessAddressState;
            selectedABRReport.APT_Business_Address_Postcode__c = abrReport.BusinessAddressPostcode;
            selectedABRReport.APT_GST_Status__c = abrReport.GSTStatus;
            selectedABRReport.APT_GST_Status_From_Date__c = abrReport.GSTStatusFromDate;
            selectedABRReport.APT_Trading_Name__c = abrReport.TradingName;

            return selectedABRReport;
        }
        return null;
    }
    
    /**
    * [Jansi]
    *  businessrules and approval checks
    * 1. Duplicate Org check
    * 2. If 'duplicate org' check Passed, then chcek for 'business credit referral' check
    * 3. If 'business credit referral' check passed then do 'auto approval' check
    * */
    public static CreditRulesAndApprovalCheckResults creditBusinessRulesAndApprovalChecks(APT_Credit_Assessment__c ca, String userOrgId){  
        CreditRulesAndApprovalCheckResults chkResults = new CreditRulesAndApprovalCheckResults();
        //-- 1. CHECK "DUPLICATE ORG"
        if(!isDuplicateOrgExists(ca.APT_ABN__c , userOrgId)){
            System.debug('No duplicate Org Exists, Duplicate org check is PASSED');
            
            try{
                updateOrganisation(userOrgId, ca);
            }catch(Exception ex){
                System.debug('Error while updating the org details==> '+ex);
            }
            
            
            // -- 2. DO 'BUSINESS REFERREL CHECKS' 
            ReferralCheckResults refChkResults = isAutoReferred(ca.APT_Entity_Type__c, userOrgId, ca.Id);
            System.debug('refChkResults='+refChkResults);
            //If not referred then do check for auto approval.
            if(refChkResults.isReferred != null && refChkResults.isReferred == false){     
                // if 'cWrapper.userOrgId' then get from BCAFormBase.getUserAccountId() , but it won't be null. Only admins will have null
                System.debug('Credit Assessment NOT Referred !!!');
                //-- 3. DO 'AUTO APPROVAL CHECKS' 
                if(isAutoApproved(ca.APT_Entity_Type__c, ca.APT_Requested_Credit_Limit__c)){ //APT_Credit_Amount_Required__c
                    // approval check passed
                    System.debug('Credit Assessment Auto Approved');
                    chkResults.status = BCAFormConstants.CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED;
                }else{
                    chkResults.isRequiredEquifaxValidation = true;
                    return chkResults;
                }
            }else{
                //-- 'referral'check failed,
                System.debug('Credit Assessment Referred !!!');
                chkResults.reason = refChkResults.failedReason;
                chkResults.status = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
            }
        }else{
            // --duplicate org found  
            System.debug('duplicate Org found');
            chkResults.status = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
            chkResults.reason = BCAFormConstants.DUPLICATE_ORG_REASON;
        }
        return chkResults;
    }
    
    /**
     * [Jansi]
    * Insert credit assesment recod and further actions
    * 1. Insert credit assessment record
    * 2. Link Trust fiels for Trust entity type to credit assessmen
    * 3. Link outlets to creditassessment
    * 4. Check business credit rules and auto approval checks
    * */
    public static SaveAssessmentWrapper createCreditAssessment(String creditAssessmentStr)  {     
        
        String caStatus;
        String caReason;
        String messageToApplicant ;
        String appStatusToApplicant;
        
        //-- Parsing the JSON string to wrapper
        CreditAssessmentWrapper cWrapper = (CreditAssessmentWrapper)System.JSON.deserialize(creditAssessmentStr, CreditAssessmentWrapper.class);
        
        APT_Credit_Assessment__c caRecord = cWrapper.creditAssessment();
        
        SaveAssessmentWrapper saveWrapper = new SaveAssessmentWrapper();
        saveWrapper.addToLog('begin save');
        
         // -- add ABR/ASIC reports
        // get them from cache
        try {
            BCAFormController.ABNReportsCached abnReportsCached = (BCAFormController.ABNReportsCached) CacheManager.get(BCAFormConstants.BCA_ABN_DETAILS_KEY);            
            APT_ASIC_Report__c asicReport = createASICReport(abnReportsCached);
            APT_ABRreport__c abrReport = createABRReport(abnReportsCached);
            ApplicationDatabase.getInstance().dmlInsert(new List<SObject> {asicReport, abrReport});
            caRecord.APT_ASIC_Report__c = asicReport.Id;
            caRecord.APT_ABR_Report__c = abrReport.Id;
            
        }catch (Exception ex) {
            System.debug('Error building ABR/ASIC reports:' + ex.getMessage());
        }
        
        //-- 1. Insert credit assessment record
        try {
            ApplicationDatabase.getInstance().dmlInsert(new List<APT_Credit_Assessment__c> {caRecord});
            saveWrapper.caId = caRecord.Id;
            saveWrapper.status = BCAFormConstants.CREDIT_ASSESSMENT_INSERTION_SUCCESS;
            
        }catch(Exception ex) {
            System.debug('caaFormController::' + ex.getMessage());
            saveWrapper.status =  BCAFormConstants.CREDIT_ASSESSMENT_INSERTION_FAILURE;
            appStatusToApplicant = BCAFormConstants.CREDIT_ASSESSMENT_ERROR_STATUS_TO_APPLICANT;
            messageToApplicant = BCAFormConstants.MESSAGE_BODY_TO_USER_FOR_ERROR_IN_CREDIT_ASSESMENT_CREATION;

            saveWrapper.addToLog('error on insert:' + ex.getMessage());
        }
                 
        //-- Once'ca' record is inserted successfully then proceeding with below
        if(!String.isEmpty(caRecord.Id)){ 
            try{
                //-- 2. insert document links(trust fiels)
                insertContentDocumentLinks(cWrapper.linkDocuments(caRecord));
                
                // -- 3. insert postal outlets/networks
                insertCreditAssesmentNetworks(cWrapper.createPostalOutlets(caRecord));
                                
                //-- 4. Check business reference rules and approval checks
                CreditRulesAndApprovalCheckResults checkResults = creditBusinessRulesAndApprovalChecks(caRecord, cWrapper.userOrgId);
                
                if(checkResults.isRequiredEquifaxValidation != null && checkResults.isRequiredEquifaxValidation){
                    saveWrapper.isEquifaxValidationRequired = true;
                    //saveWrapper.addToLog('Need Equifax Validations...');
                    return saveWrapper;
                }
                
                caReason = checkResults.reason;
                caStatus = checkResults.status;
                System.debug('caStatus=='+caStatus);
                
                if(!String.isEmpty(caStatus)){

                    APT_Credit_Assessment__c queriedCA = CreditsAssessmentSelector.newInstance(1, creditAssessmentFields()).selectById( new Set<Id>{caRecord.Id}).values()[0];
                    
                    if(caStatus == APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED){
                        messageToApplicant= BCAFormConstants.CREDIT_ASSESSMENT_REFERRED_MSG_TO_APPLICANT;
                        appStatusToApplicant = BCAFormConstants.CREDIT_ASSESSMENT_RECEIVED_STATUS_TO_APPLICANT;
                    }else if(caStatus == BCAFormConstants.CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED){
                        messageToApplicant= BCAFormConstants.CREDIT_ASSESSMENT_AUTO_APPROVED_MSG_TO_APPLICANT;
                        appStatusToApplicant = BCAFormConstants.CREDIT_ASSESSMENT_SUCCESSFUL_STATUS_TO_APPLICANT;
                    }
                    messageToApplicant = replaceValuesInMessageToApplicant(messageToApplicant, queriedCA.APT_Correspondence_Email_Address__c, queriedCA.Application_Reference_Number__c);

                    //--  6. UPDATE Creditassesment
                    updateCreditAssessment(caRecord.Id, caStatus, caReason, null);
                    //saveWrapper.addToLog('updated credit assessment with:' + caStatus + ', ' + caReason);
                }
            }catch(Exception ex){
                messageToApplicant= BCAFormConstants.CREDIT_ASSESSMENT_REFERRED_MSG_TO_APPLICANT;
                appStatusToApplicant = BCAFormConstants.CREDIT_ASSESSMENT_RECEIVED_STATUS_TO_APPLICANT;
            }
        }
        
        saveWrapper.message = messageToApplicant;
        saveWrapper.appCurrentStatus = appStatusToApplicant;
        return saveWrapper;
    }
    
    public static void updateCreditAssessment(String caId, String status,String reason, String equifaxStatus){
        try{
            APT_Credit_Assessment__c ca = new APT_Credit_Assessment__c();
            ca.Id = caId;
            ca.APT_Credit_Assessment_Status__c = status;
            ca.L2C_Referral_Rejection_Reason__c = !String.isEmpty(reason) ? reason : '';
            
            if(!String.isEmpty(equifaxStatus)) ca.Equifax_Status__c = equifaxStatus;
            
            update ca;
            
        }catch(Exception ex){
            System.debug('Updation of credit assessment is failed==>'+ex);  
        }
    }

    private static void updateOrganisation(Id userOrgId, APT_Credit_Assessment__c caRecord){// SaveAssessmentWrapper saveWrapper) //[Jansi: commented saveWrapper]
         List<String> logs = new List<String>();
        //saveWrapper.addToLog('Update Organisation ' + userOrgId);
        if(null != userOrgId){
            Map<Id, Account> mapAccountsByIds = AccountsSelector.newInstance().selectById(new Set<Id> {userOrgId});
            if(mapAccountsByIds.size() == 1){
                
                Account org = mapAccountsByIds.get(userOrgId);

                // ABN
                org.ABN__c = caRecord.APT_ABN__c;
                org.ACN__c = caRecord.APT_ACN__c;
                org.Name = caRecord.APT_Legal_Entity_Name__c;
                org.Legal_Entity_Type__c = caRecord.APT_Entity_Type__c;
                org.Organisation_Trading_Name__c = caRecord.APT_Business_Name__c;

                // Business Address TBD - how the address fields map
                org.ShippingStreet = caRecord.APT_Street_Name__c + (String.isNotBlank(caRecord.APT_Address_Line_2__c) ? ' ' + caRecord.APT_Address_Line_2__c : '');
                org.ShippingCity = caRecord.APT_City__c;
                org.ShippingState = caRecord.APT_State__c;
                org.ShippingPostalCode = caRecord.APT_Postcode__c;
                org.ShippingCountry = caRecord.APT_Country__c;

                org.BillingStreet = caRecord.APT_Postal_Address_Line_1__c + (String.isNotBlank(caRecord.APT_Postal_Address_Line_2__c) ? ' ' + caRecord.APT_Postal_Address_Line_2__c : '');
                org.BillingCity = caRecord.APT_Postal_City__c;
                org.BillingState = caRecord.APT_Postal_State__c;
                org.BillingPostalCode = caRecord.APT_Postal_Postcode__c;
                org.BillingCountry = caRecord.APT_Postal_Country__c;

                // business type
                if(caRecord.Industry_Class__c != null && caRecord.APT_Industry_Type__c != null){
                    List<ANZSIC_Code__c> anzsicCodes = ANZSICCodesSelector.newInstance().selectByTypeAndClass(caRecord.APT_Industry_Type__c
                            , caRecord.Industry_Class__c);
                    if(anzsicCodes.size() == 1)
                    {
                        org.ANZSIC_Code__c = anzsicCodes[0].Id;
                    }
                }
                org.NumberOfEmployees = (Integer) caRecord.APT_Number_of_Employees__c;

                try {
                    Database.SaveResult srUpdate = Database.update(org);
                    logs.add('Saved Organisation ');
                }
                catch(Exception ex){
                    System.debug('BCAFormHelper:: error on updating Org ' + userOrgId + ', ex:' + ex.getMessage());
                    logs.add('Error Updating Org ' + ex.getMessage());
                }
            }
            else{
                System.debug('BCAFormHelper:: error, Org Id does not exist ' + userOrgId );
                logs.add('Error Org not found ' + userOrgId);
            }
        }
        else{
            System.debug('BCAFormHelper:: error, no related org');
            logs.add('Error, no related org');
        }
        System.debug('updateOrganisation LOGS ==> '+logs);
    }

    
    
   /***********************************************************************************************************************************
    * EQUIFAX RELATED CODE --- STARTS
    * *********************************************************************************************************************************/
    
      
    public static final String SOLE_TRADER_EQUIFAX_REQUEST_TYPE = 'SoleTrader';
    public static final String COMPANY_EQUIFAX_REQUEST_TYPE = 'Company';
    private static final String OTHER_EQUIFAX_REQUEST_TYPE = 'Other';
    
    public static final string COMPANY_BUSINESS_DECISION = 'companyBusinessDecision';
    public static final string APPLICATION_DECISION = 'applicationDecision';
    public static final string PRE_DECLINE = 'PRE_DECLINE';
    public static final string PRE_REFER = 'PRE_REFER';
    public static final string DESCRIPTION = 'description';
    public static final string EXCEPTION_DESCRIPTION = 'ExceptionDescription';
    public static final string RESPONSE_EXCEPTION = 'Exception';
    
        
    /**
     * Building HTTP equifax request from CA record
     * */
    public static EquifaxRequest buildEquifaxRequest(String caId){
        
        EquifaxRequest reqWrapper = new EquifaxRequest();    
               
       //Query ca record
        APT_Credit_Assessment__c ca =  getCARecord(creditAssessmentFields(), caId);
        
        if(!String.isEmpty(ca.APT_Entity_Type__c)){
           
            //-- For 'BUSINESS' and 'OTHER_INCORPORATED', send Company equifax request
            if(ca.APT_Entity_Type__c.equalsIgnoreCase(BCAFormConstants.ENTITY_TYPE_BUSINESS) ||
               ca.APT_Entity_Type__c.equalsIgnoreCase(BCAFormConstants.ENTITY_TYPE_OTHER_INCORPORATED )){
                   reqWrapper.reqType = COMPANY_EQUIFAX_REQUEST_TYPE;
                   reqWrapper.req = EquifaxController.buildHttpRequest(EquifaxController.buildCompanyCreditAssesmentRequest(buildCompanyEquifaxRequestWrapper(ca)), reqWrapper.reqType);
               }
            
            //-- For 'INDV' send Individual equifax request
            else if(ca.APT_Entity_Type__c.equalsIgnoreCase(BCAFormConstants.ENTITY_TYPE_INDV)){
                reqWrapper.reqType = SOLE_TRADER_EQUIFAX_REQUEST_TYPE;
                reqWrapper.req = EquifaxController.buildHttpRequest(EquifaxController.buildIndividualCreditAssesmentRequest(buildSoleTraderEquifaxRequestWrapper(ca)), reqWrapper.reqType);
            } 
        }
        //store 'credit amount' requested to check in the response while parsing
        reqWrapper.requestedAmount = ca.APT_Requested_Credit_Limit__c;
        
        //store 'CA' ref number to check in the response while parsing
        reqWrapper.caRefNumber = ca.Application_Reference_Number__c;
        
        //store 'contact Email address'  to check in the response while parsing
        reqWrapper.contactEmailAddress = ca.APT_Correspondence_Email_Address__c;
        
        //store 'contact Email address'  to check in the response while parsing
        reqWrapper.caId = ca.Id;
        
        return reqWrapper;
    }
    
          
    /**
    * Building company Equifax wrapper object from CreditAssessment record
    **/
    public static EquifaxController.CompanyRequest buildCompanyEquifaxRequestWrapper(APT_Credit_Assessment__c ca){
        
        EquifaxController.CompanyRequest companyReq = new EquifaxController.CompanyRequest();
        String reqOrgType;
        
        if(ca.APT_Entity_Type__c.equalsIgnoreCase(BCAFormConstants.ENTITY_TYPE_BUSINESS))
            reqOrgType = COMPANY_EQUIFAX_REQUEST_TYPE; 
        
        else if(ca.APT_Entity_Type__c.equalsIgnoreCase(BCAFormConstants.ENTITY_TYPE_OTHER_INCORPORATED ))
            reqOrgType = OTHER_EQUIFAX_REQUEST_TYPE;  
        
        companyReq.reqHeader = new EquifaxController.Header( );
        
        companyReq.reqBody = new EquifaxController.CompanyRequestBody(  
            ca.APT_Contact_Name__c, '123', ca.APT_Postal_Address_Line_1__c, ca.APT_Postal_City__c, ca.APT_Postal_State__c, ca.APT_Postal_Postcode__c,
            String.valueOf(ca.APT_Requested_Credit_Limit__c), 'D14', ca.APT_Legal_Entity_Name__c, reqOrgType, 'INC', ca.APT_ACN__c, ca.APT_ABN__c,
            '123', ca.APT_Postal_Address_Line_1__c, ca.APT_Postal_City__c, ca.APT_Postal_State__c, ca.APT_Postal_Postcode__c);
        
        System.debug('companyReq wrapper = '+companyReq);
        
        return companyReq;
    }
    
     /**
      * Building soleTrader Equifax wrapper object from CreditAssessment record
      **/
    public static EquifaxController.SoleTraderRequest buildSoleTraderEquifaxRequestWrapper(APT_Credit_Assessment__c ca){ 
        
        EquifaxController.SoleTraderRequest soleTraderReq = new EquifaxController.SoleTraderRequest();
        
        soleTraderReq.reqHeader = new EquifaxController.Header( );
        
        soleTraderReq.reqBody = new EquifaxController.SoleTraderRequestBody( 
            ca.APT_Applicant_1_First_Name__c, 
            '123', ca.APT_Applicant_1_Street_Name__c, ca.APT_Applicant_1_Suburb__c, ca.APT_Applicant_1_State__c, ca.APT_Applicant_1_Postcode__c,
            String.valueOf(ca.APT_Requested_Credit_Limit__c), 'D14', ca.APT_Legal_Entity_Name__c, ca.APT_ABN__c,
            ca.APT_Applicant_1_First_Name__c, ca.APT_Applicant_1_Last_Name__c, String.ValueOf(ca.APT_Applicant_1_Date_of_Birth__c), '123', ca.APT_Applicant_1_Street_Name__c,
            ca.APT_Applicant_1_Suburb__c, ca.APT_Applicant_1_State__c, ca.APT_Applicant_1_Postcode__c,  
            ca.APT_Applicant_1_First_Name__c, ca.APT_Applicant_1_Last_Name__c);
        
        System.debug('soleTraderReq wrapper = '+soleTraderReq);
        
        return soleTraderReq;
    }
    
    
    /**
     * Parsing the httpResponse returned from equifax
     * */
    public static SaveAssessmentWrapper parseResponse(HTTPResponse res,  EquifaxRequest equifaxReqWrapper){//String caId, String reqType, Double requestedAmount){
        
        //-- parse the httpresponse into a map
        Map<String,String> decisionMap = EquifaxController.parseHttpResponse(res);
       
        //process the parsed response map
        EquifaxProcessedResults processedResults = processDecisionMap(decisionMap, equifaxReqWrapper.reqType);
             
        return processEquifaxStatusAndUpdateCreditAssesmentStatus(equifaxReqWrapper, processedResults);// processedResults.status, reqType.caId, processedResults.reason, requestedAmount);
    }
    
    
    
    /**
    * Process the Equifax 'company' 0r 'soleTrader' decisionMap
    * reqType =  'company' 0r 'soleTrdaer'   
    * */
    public static EquifaxProcessedResults processDecisionMap(Map<String,String> decisionMap, String reqType){
        EquifaxProcessedResults results = new EquifaxProcessedResults();
       
        try {
            String decision;
            
            if(reqType == COMPANY_EQUIFAX_REQUEST_TYPE)
                decision = COMPANY_BUSINESS_DECISION;                 //Possible return values:: ERROR, PRE_DECLINE, PRE_REFER, DECLINE, REFER, WITHDRAW, APPROVE
            
            else if(reqType == SOLE_TRADER_EQUIFAX_REQUEST_TYPE)
                decision = APPLICATION_DECISION;
            
            if(decisionMap != null){
                //Contains 'Decision'
                if(decisionMap.containsKey(decision)){
                    
                    //getting equifax status(decision)
                    results.equifaxStatus = decisionMap.get(decision);
                    
                    //Checking if the Decision retirned by Equifax is either 'pre-decline' or 'decline' then setting outcome as 'rejected'
                    if(PRE_DECLINE.equalsIgnoreCase(decisionMap.get(decision)) || APT_Constants.CREDIT_ASSESSMENT_STATUS_DECLINE.equalsIgnoreCase(decisionMap.get(decision))){
                        results.status = APT_Constants.APPROVAL_STATUS_REJECTED;
                    }
                    
                    //Checking if the Decision returned by Equifax is 'Approve' then setting outcome as 'Approved'
                    else if(APT_Constants.APPROVAL_STAGE_APPROVE2.equalsIgnoreCase(decisionMap.get(decision))){
                        results.status = APT_Constants.APPROVAL_STAGE_APPROVED;
                    }
                    
                    //other than above then setting outcome as 'Referred'
                    else {
                        results.status = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
                    }
                    
                }
                
                //Contains 'Description' and not 'approved' then taking to update in 'CA' record 'reason' field
                if(decisionMap.containsKey(DESCRIPTION) &&  !APT_Constants.APPROVAL_STAGE_APPROVE2.equalsIgnoreCase(decisionMap.get(decision))){
                    results.reason = decisionMap.get(DESCRIPTION);
                }
            }
            
        }  catch(Exception ex){  // TO DO :@Ankur to confirm this block 
            // setting error reason
            String errorMsg= 'ERROR in BCAFormHelper.parseEquifaxResponse(), line no='+ex.getLineNumber() +', =>'+ex.getMessage();
            results.reason = trimMessage(errorMsg); //To set in CA object 'reason' field for reference the issue later
            //results.status = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
            system.debug('Error in BCAFormHelper.parseEquifaxResponse(), line no='+ex.getLineNumber() +', =>'+ex.getMessage());
        }
        
        // for any of the reason if status is empty from equifax or exception case then setting as 'Referred'
        if(String.isEmpty(results.status)) results.status = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
        
        return results;
    }

   
    /**
     * caStatus : Equifax processed 'Decision' status
     * ca Id : Credit assesment record Id
     * caReason: Equifax Description
     * 1. Based on 'caStatus' build the referred or approved message to show to the BCA applicant
     * 2. IF requsted amount > 50000k and Equifax is approved, then we are updating CA record status as 'Referred'
     * 3. Updating the CA record status and/or reason
     * */
    private static SaveAssessmentWrapper processEquifaxStatusAndUpdateCreditAssesmentStatus( EquifaxRequest equifaxReqWrapper, EquifaxProcessedResults processedResults){//String caStatus, String caId, String caReason, Double requestedAmount){
                
        String caStatus = processedResults.status;
        String caReason = processedResults.reason;
        
        System.debug('caReason=='+caReason);
        System.debug('caStatus=='+caStatus);
        SaveAssessmentWrapper saveWrapper = new SaveAssessmentWrapper();
        saveWrapper.caId = equifaxReqWrapper.caId;
        
        String messageToApplicant ;
        String appStatusToApplicant;
        
        if(!String.isEmpty(caStatus)){       
            // check if requested credit limit is >$50K then setting as 'Referred' with 'reason'
            if(caStatus == APT_Constants.APPROVAL_STAGE_APPROVED && equifaxReqWrapper.requestedAmount > BCAFormConstants.EQUIFAX_MAX_APPROVED_CREDIT_LIMIT){
                caStatus = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
                caReason= BCAFormConstants.CREDIT_LIMIT_GREATER_THAN_FIFTY_K_REASON;
            }
            
            // Setting message to show to applicant for 'Referred' and 'Rejected' status
            if(caStatus == APT_Constants.APPROVAL_STATUS_REJECTED ||  caStatus == APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED){
                messageToApplicant= BCAFormConstants.CREDIT_ASSESSMENT_REFERRED_MSG_TO_APPLICANT;
                appStatusToApplicant = BCAFormConstants.CREDIT_ASSESSMENT_RECEIVED_STATUS_TO_APPLICANT;
            }
            
            // Setting message to show to applicant for 'Approved'
            else if(caStatus == APT_Constants.APPROVAL_STAGE_APPROVED){
                messageToApplicant= BCAFormConstants.CREDIT_ASSESSMENT_AUTO_APPROVED_MSG_TO_APPLICANT;
                appStatusToApplicant = BCAFormConstants.CREDIT_ASSESSMENT_SUCCESSFUL_STATUS_TO_APPLICANT;
                
            }
            
            //--replacing CA ref number and contact email in the message
            messageToApplicant = replaceValuesInMessageToApplicant(messageToApplicant, equifaxReqWrapper.contactEmailAddress, equifaxReqWrapper.caRefNumber);

            //--   UPDATE Creditassesment
            BCAFormHelper.updateCreditAssessment(equifaxReqWrapper.caId, caStatus, caReason, processedResults.equifaxStatus);
            
            saveWrapper.addToLog('updated credit assessment with:' + caStatus + ', ' + caReason);
            
        }
        saveWrapper.message = messageToApplicant;
        saveWrapper.appCurrentStatus = appStatusToApplicant;
        saveWrapper.status = BCAFormConstants.CREDIT_ASSESSMENT_INSERTION_SUCCESS;
        return saveWrapper;
    }
    
    /***********************************************************************************************************************************
    * EQUIFAX RELATED CODE --- ENDS
    * *********************************************************************************************************************************/

     /**
     * replacing the message with CA record reference number and contact email address
     * */
    private static String replaceValuesInMessageToApplicant(String messageToApplicant,String contactEmail, String refNum){
       
        // need the below check to bypass mocking
        if(!String.isEmpty(refNum))
            messageToApplicant = messageToApplicant.replace('<xxxxxx>', refNum);
        messageToApplicant = messageToApplicant.replace('<CONTACT_EMAIL>', contactEmail);

        return messageToApplicant;
    }
    
        
    /**
    * Trimming the error message 
    **/
    private static String trimMessage(String msg){
        return msg.length() >=255 ? msg.subString(0,253) : msg;
    }
    
    
    /**
     * Query CA record with given fields and given CA record Id
     * caObjFieldsSet : Set of CA record fields to query
     * caId : CA record Id
     * */
    private static APT_Credit_Assessment__c  getCARecord(Set<SObjectField> caObjFieldsSet, String caId){
        System.debug('caId='+caId);
        //Query ca record 
        List<APT_Credit_Assessment__c> caList = CreditsAssessmentSelector.newInstance(1, caObjFieldsSet).selectById( new Set<Id>{caId}).values();
        System.debug('caList='+caList);
        if(caList.size() > 0) return caList[0];
        else return null;
    }
    
  
    /**
     * Generate pdf attachment from Credit assement records HTML content
     * */
     // @Future(callout=true)
    public static void generatePDF(String caId){
        
        try{                                                   
            System.debug('pdf generation STARTS...');
            //insert summary pdf
            DateTime sysTime = Datetime.now();
            
            PageReference PDf =  Page.bcaSummaryPDF;
            PDf.getParameters().put('caId',caId);
            PDf.setRedirect(true);
            
            Attachment attach = new Attachment();
            Blob b = PDf.getContent();
            attach.Body = b;
            attach.Name = BCAFormConstants.SUMMARY_PDF_FILE_NAME+'_'+sysTime+'.pdf';
            attach.IsPrivate = false;
            attach.ParentId = caId;
            
            insert attach;
        }catch(Exception ex) {
            System.debug('Error while inserting pdf summary attachment::' + ex.getMessage());
        }
    }
    
    /**
    *  wrapper classes 
    * */
    public class CreditRulesAndApprovalCheckResults{  
        public String status{get;set;}
        public String reason{get;set;}
        public boolean isRequiredEquifaxValidation{get;set;}
    }
    
    /**
    * wrapper classes
    * */
    public class SaveAssessmentWrapper{
        @AuraEnabled public String appCurrentStatus;
        @AuraEnabled public String status;
        @AuraEnabled public String message;
        @AuraEnabled public String caId;
        @AuraEnabled public Boolean isEquifaxValidationRequired;
        
        @AuraEnabled public List<String> log;
        public void addToLog(String s)
        {
            if(log == null){
                log = new List<String> ();
            }
            log.add(s);
        }
    }
    
    // wrapper to send back LWC on save
    public class SaveFileResult {
        @AuraEnabled public ContentVersion contentVersion;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String previewUrl;
        @AuraEnabled public String status;
        @AuraEnabled public String message;
    }
    
    private Class ReferralCheckResults{
        private Boolean isReferred{get;set;}  
        private String failedReason{get;set;} 
    }
    
    public Class EquifaxProcessedResults{
        public String status{get;set;}  
        public String reason{get;set;} 
        public String equifaxStatus{get;set;} 
    }
    
    
    public class EquifaxRequest{
        public HttpRequest req {set;get;}
        public String caId { get; set; }
        public String reqType {set;get;}
        public Double requestedAmount {set;get;}
        public String caRefNumber {set;get;}
        public String contactEmailAddress {set;get;}
        public String reqLabel{set;get;}
    }

    private static Set<SObjectField> creditAssessmentFields() {
        return new Set<SObjectField> {
                APT_Credit_Assessment__c.Id,
                APT_Credit_Assessment__c.Name,
                APT_Credit_Assessment__c.L2C_Assessment_Type__c,
                APT_Credit_Assessment__c.APT_ABN__c,
                APT_Credit_Assessment__c.APT_ACN__c,
                APT_Credit_Assessment__c.APT_Date_Commenced__c,
                APT_Credit_Assessment__c.APT_Entity_Type__c,
                APT_Credit_Assessment__c.APT_Legal_Entity_Name__c,
                APT_Credit_Assessment__c.APT_Business_Name__c,

                // address
                APT_Credit_Assessment__c.APT_Unit_Number__c,
                APT_Credit_Assessment__c.APT_Street_Type__c,
                APT_Credit_Assessment__c.APT_Street_Number__c,
                APT_Credit_Assessment__c.APT_Street_Name__c,
                APT_Credit_Assessment__c.APT_Address_Line_2__c,
                APT_Credit_Assessment__c.APT_Suburb__c,
                APT_Credit_Assessment__c.APT_City__c,
                APT_Credit_Assessment__c.APT_State__c,
                APT_Credit_Assessment__c.APT_Country__c,
                APT_Credit_Assessment__c.APT_Postcode__c,
                APT_Credit_Assessment__c.APT_Telephone__c,
                APT_Credit_Assessment__c.APT_Fax__c,

                //post address
                APT_Credit_Assessment__c.APT_Postal_Address_Line_1__c, 
                APT_Credit_Assessment__c.APT_Postal_City__c, 
                APT_Credit_Assessment__c.APT_Postal_State__c, 
                APT_Credit_Assessment__c.APT_Postal_Postcode__c, 

                // Contact
                APT_Credit_Assessment__c.APT_Position_Title__c,
                APT_Credit_Assessment__c.APT_Contact_Name__c,
                APT_Credit_Assessment__c.APT_Email_Address__c,
                APT_Credit_Assessment__c.APT_Correspondence_Email_Address__c,

                // Type of Business
                APT_Credit_Assessment__c.APT_Nature_of_Business__c,
                APT_Credit_Assessment__c.APT_Industry_Type__c,

                // lodgement - TODO

                // Business Reference
                APT_Credit_Assessment__c.APT_Reference_Business_Name_1__c,
                APT_Credit_Assessment__c.APT_Reference_Business_Name_2__c,
                APT_Credit_Assessment__c.APT_Reference_Business_Name_3__c,
                APT_Credit_Assessment__c.APT_Reference_Contact_Name_1__c,
                APT_Credit_Assessment__c.APT_Reference_Contact_Name_2__c,
                APT_Credit_Assessment__c.APT_Reference_Contact_Name_3__c,
                APT_Credit_Assessment__c.APT_Reference_Job_Title_1__c,
                APT_Credit_Assessment__c.APT_Reference_Job_Title_2__c,
                APT_Credit_Assessment__c.APT_Reference_Job_Title_3__c,
                APT_Credit_Assessment__c.APT_Reference_Phone_Number_1__c,
                APT_Credit_Assessment__c.APT_Reference_Phone_Number_2__c,
                APT_Credit_Assessment__c.APT_Reference_Phone_Number_3__c,

                // applicant
                APT_Credit_Assessment__c.APT_Applicant_1_Title__c,
                APT_Credit_Assessment__c.APT_Applicant_1_First_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Middle_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Last_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Title__c,
                APT_Credit_Assessment__c.APT_Applicant_2_First_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Middle_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Last_Name__c,

                APT_Credit_Assessment__c.APT_Applicant_1_Unit_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Street_Type__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Street_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Street_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Address_Line_2__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Suburb__c,
                APT_Credit_Assessment__c.APT_Applicant_1_City__c,
                APT_Credit_Assessment__c.APT_Applicant_1_State__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Postcode__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Country__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Unit_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Street_Type__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Street_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Street_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Suburb__c,
                APT_Credit_Assessment__c.APT_Applicant_2_City__c,
                APT_Credit_Assessment__c.APT_Applicant_2_State__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Postcode__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Country__c,

                APT_Credit_Assessment__c.APT_Applicant_1_Business_Premises__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Business_Premises__c,

                APT_Credit_Assessment__c.APT_Applicant_1_Telephone__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Telephone__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Drivers_Licence_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Drivers_Licence_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Date_of_Birth__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Date_of_Birth__c,


                // credit limit
                APT_Credit_Assessment__c.APT_Requested_Credit_Limit__c,

                // Ts&Cs

                // background data
                APT_Credit_Assessment__c.APT_Assessment_Type__c,
                APT_Credit_Assessment__c.APT_Holding_Company__c,
                APT_Credit_Assessment__c.APT_Holding_Company_Name__c,
                APT_Credit_Assessment__c.APT_Holding_Company_ACN__c,
                APT_Credit_Assessment__c.APT_Number_of_Employees__c,
                APT_Credit_Assessment__c.APT_Business_Premises__c,
                APT_Credit_Assessment__c.APT_Business_Type__c,
                APT_Credit_Assessment__c.APT_ABR_Report__c,
                APT_Credit_Assessment__c.APT_ASIC_Report__c,
                APT_Credit_Assessment__c.APT_Credit_Assessment_Status__c,
                APT_Credit_Assessment__c.APT_Credit_Assessment_Complete__c,
                APT_Credit_Assessment__c.APT_Account_Type__c,

                // status
                APT_Credit_Assessment__c.APT_Status__c,
                APT_Credit_Assessment__c.Application_Reference_Number__c
        };
    }
}