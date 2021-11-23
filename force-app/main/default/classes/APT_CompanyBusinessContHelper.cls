/**
 Description: This class is helper class for company business controller
 Created By: Himanshu jain
 Created Date: 1st Oct, 2015
 
 Last Modified By - Mausam Padhiyar
 Last Modified Date - 13th Sept, 2016 | 1524 : set default entity type = individual
**/

public with sharing class APT_CompanyBusinessContHelper {
    
    /**
      This class parse ORG ID response data to apex wrapper class.
    */
    public static APT_OrgIDWebServiceWrapper.queryABNResponseType parseOrgIDResponseToWrapper(APT_SchemaPartyCustomerService.queryABNResponseType webServiceResponse,
                                                                                            decimal creditLimitRequired,
                                                                                            String organisationName){
        try {
            APT_OrgIDWebServiceWrapper.queryABNResponseType responseWrapper = new APT_OrgIDWebServiceWrapper.queryABNResponseType();
            
            
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgIdResultWrapList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.ErrorType error = new APT_OrgIDWebServiceWrapper.ErrorType();
            
            
            responseWrapper.OrgIdResult =  orgIdResultWrapList;
            responseWrapper.Error =  error;
            
            System.debug('webServiceResponse.Error'+webServiceResponse.Error);
            //parsing error details in case of some error
            if(webServiceResponse.Error != null){
                
                error.ErrorTypeDesc = webServiceResponse.Error.ErrorType;
                error.InputContainer = webServiceResponse.Error.InputContainer;
                error.ErrorDescriptiontype = webServiceResponse.Error.ErrorDescription;  
                  
            }
            
            System.debug('webServiceResponse.OrgIdResult:'+webServiceResponse.OrgIdResult);        
            if(webServiceResponse.OrgIdResult != null){
                
                integer uniqueNumber = 1;
                APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIDWrap = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
                for(APT_SchemaPartyCustomerService.OrgIdResult_element responseOrgIDWrap : webServiceResponse.OrgIdResult){
                    
            
                    orgIDWrap = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
                    
                    orgIDWrap.MatchName = responseOrgIDWrap.MatchName;
                    orgIDWrap.OrganisationNumber = responseOrgIDWrap.OrganisationNumber;
                    orgIDWrap.AustralianBusinessNumber = responseOrgIDWrap.AustralianBusinessNumber;
                    orgIDWrap.OrganisationNumberHeading = responseOrgIDWrap.OrganisationNumberHeading;
                    orgIDWrap.State = responseOrgIDWrap.State;
                    
                    orgIDWrap.OrganisationType = new APT_OrgIDWebServiceWrapper.OrganisationType_element();
                                
                    orgIDWrap.ASICReport = getASICReport(responseOrgIDWrap.ASICReport);
                    orgIDWrap.AustralianBusinessRegisterReport = getABRReport(responseOrgIDWrap.AustralianBusinessRegisterReport);
                    orgIDWrap.BureauReport = getBureauReport(responseOrgIDWrap.BureauReport);
                    orgIDWrap.ASICBNRReport = getASICBNRReport(responseOrgIDWrap.ASICBNRReport);        
                    
                    system.debug('*** orgIDWrap.AustralianBusinessRegisterReport ***'+orgIDWrap.AustralianBusinessRegisterReport);
                    system.debug('*** Organisation Type ***'+responseOrgIDWrap.OrganisationType);
                    //system.debug('*** Organisation Type BCA***'+responseOrgIDWrap.BureauReport.BCACompanyType);
                    orgIDWrap.StatusString = APT_Constants.EMPTY_STRING;
                    
                    orgIDWrap.ShowSelect = false;
                     
                    //validate trust
                    String asicReportType = orgIDWrap.ASICReport.ASICType;
                    String abnReportType = orgIdWrap.AustralianBusinessRegisterReport.EntityTypeInd;
                    
                    //show select Based on Active or ASIC OR ABR Report
                    if(orgIDWrap.ASICReport != null){
                        orgIDWrap.ShowSelect = APT_Constants.CONSTANT_VEDA_REGD.equalsIgnoreCase(orgIDWrap.ASICReport.ASICStatus)
                                                     || APT_WebServiceUtility.CONSTANT_VEDA_ACTIVE.equalsIgnoreCase(orgIDWrap.ASICReport.ASICStatus);
                                                     
                        
                        if(String.IsNotBlank(orgIDWrap.ASICReport.ASICStatus)){
                            orgIDWrap.StatusString = orgIDWrap.ASICReport.ASICStatus;
                        }
                        
                        if(orgIDWrap.AustralianBusinessRegisterReport != null &&  String.IsNotBlank(orgIDWrap.AustralianBusinessRegisterReport.ABNStatus)
                                    && String.IsNotBlank(orgIDWrap.ASICReport.ASICStatus)){
                            orgIDWrap.StatusString = orgIDWrap.StatusString + APT_Constants.SEPERATOR_BACKWARD_SLASH;
                        }
                    } 
                    
                    if(orgIDWrap.AustralianBusinessRegisterReport != null){
                        if(String.IsNotBlank(orgIDWrap.AustralianBusinessRegisterReport.ABNStatus)){
                            orgIDWrap.StatusString = orgIDWrap.StatusString + orgIDWrap.AustralianBusinessRegisterReport.ABNStatus;
                        }
                        
                        if(!orgIDWrap.ShowSelect && String.IsBlank(orgIDWrap.ASICReport.ASICStatus)){
                            orgIDWrap.ShowSelect = APT_WebServiceUtility.CONSTANT_VEDA_ACTIVE.equalsIgnoreCase(orgIDWrap.AustralianBusinessRegisterReport.ABNStatus)                                                    
                                                         || APT_Constants.CONSTANT_VEDA_REGD.equalsIgnoreCase(orgIDWrap.AustralianBusinessRegisterReport.ABNStatus);
                       
                        }
                    }
                    
                    //1524
                    if(String.isBlank(asicReportType) && String.isBlank(abnReportType)) {
                        asicReportType = 'IND'; /*APT_Constants.STRING_INDV;*/ //default > individual
                        if(responseOrgIDWrap.ASICBNRReport != null && responseOrgIDWrap.ASICBNRReport.BusinessNameHolder != null && responseOrgIDWrap.ASICBNRReport.BusinessNameHolder.AssociatedBusinessNames != null) {
                            orgIDWrap.ShowSelect = true;
                        }
                    }
                    
                    APT_Entity_Type_Mapping__mdt entitytype = getEntityType(asicReportType, abnReportType);
                    
                    system.debug('*** entitytype ***'+entitytype);

                    //1524                    
                    //Set Show Select Based on Sole Trader OR Trust. - Deprecated as if Active components cam be selected.
                    // Also set Entity type to Trust, Sole trader or individual
                    if(entitytype != null){
                        orgIDWrap.EntityTypeMasterLabel = entitytype.MasterLabel;
                        orgIDWrap.EntityTypeLabel = entitytype.APT_Entity_Type__c;
                        if(entitytype.APT_Is_Sole_Trader_Entity__c){
                            orgIDWrap.EntityTypeCustom = APT_WebServiceUtility.ENTITY_TYPE_INDIVIDUAL;
                            
                        } else if(APT_Constants.CONSTANT_VEDA_TRUST.equalsIgnoreCase(entitytype.APT_Entity_Type__c)) {
                            orgIDWrap.EntityTypeCustom = APT_WebServiceUtility.ENTITY_TYPE_TRUST;
                            
                        } 
                        else if('GOVT'.equalsIgnoreCase(entitytype.APT_Entity_Type__c)){
                            orgIDWrap.EntityTypeCustom = 'GOVT';
                        }
                        else if('OTHER_INCORPORATED'.equalsIgnoreCase(entitytype.APT_Entity_Type__c) || 'OTHER'.equalsIgnoreCase(entitytype.APT_Entity_Type__c)){
                            orgIDWrap.EntityTypeCustom = 'Other';
                        }
                        else {
                            orgIDWrap.EntityTypeCustom = APT_WebServiceUtility.ENTITY_TYPE_COMPANY;
                        }
                    } else {
                        orgIDWrap.ShowSelect = false;
                        system.debug('*** orgIDWrap.ShowSelect4 ***'+orgIDWrap.ShowSelect);
                    }
                    
                    
                    
                    
                    System.Debug('orgIDWrap.ShowSelect-->' + orgIDWrap.ShowSelect);
                    
                    System.Debug('uniqueNumber-->' + uniqueNumber);
                    orgIDWrap.OrgIdResultUniqueNumber = uniqueNumber;
                    uniqueNumber++;
                    orgIdResultWrapList.add(orgIDWrap);
                }
            }
            
            //Removing All List for which their name does not match with Entity Name
            if(responseWrapper.OrgIdResult != null && responseWrapper.OrgIdResult.size() > 1){
                List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> selectedOrgIdResultWrapList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            
                for(APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdWrapper : responseWrapper.OrgIdResult){
                    if(checkValidorgIDWrapper(orgIdWrapper)){
                        selectedOrgIdResultWrapList.add(orgIdWrapper);
                    }
                }
                
                responseWrapper.OrgIdResult =  selectedOrgIdResultWrapList;
            } else if(responseWrapper.OrgIdResult != null && responseWrapper.OrgIdResult.size() == 1){
                
                APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdWrapper = responseWrapper.OrgIdResult[0];
                if(checkValidorgIDWrapper(orgIdWrapper)){
                    String NonIndividualName = orgIdWrapper.AustralianBusinessRegisterReport.NonIndividualName;
                    String IndividualName = orgIdWrapper.AustralianBusinessRegisterReport.IndividualName != null ? String.join(orgIdWrapper.AustralianBusinessRegisterReport.IndividualName, ',') 
                                                    : APT_Constants.EMPTY_STRING;
                    String registeredName = String.IsNotBlank(NonIndividualName) ? NonIndividualName 
                                                : String.IsNotBlank(IndividualName) ? IndividualName :(String.IsNotBlank(orgIdWrapper.ASICReport.ASICName ) 
                                                    ? orgIdWrapper.ASICReport.ASICName 
                                                    : orgIdWrapper.MatchName);
                    orgIdWrapper.MatchName = registeredName;
                }
            } else{
                
            }
            
             return responseWrapper;
       } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
    }
    
    private static boolean checkValidorgIDWrapper(APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdWrapper){
        Boolean flag = false;
        String matchName = orgIdWrapper.MatchName;
        String NonIndividualName = orgIdWrapper.AustralianBusinessRegisterReport.NonIndividualName;
        String IndividualName = orgIdWrapper.AustralianBusinessRegisterReport.IndividualName != null ? String.join(orgIdWrapper.AustralianBusinessRegisterReport.IndividualName, ',') 
                                        : APT_Constants.EMPTY_STRING;
        String registeredName = String.IsNotBlank(NonIndividualName) ? NonIndividualName 
                                    : String.IsNotBlank(IndividualName) ? IndividualName :(String.IsNotBlank(orgIdWrapper.ASICReport.ASICName ) 
                                            ? orgIdWrapper.ASICReport.ASICName 
                                            : matchName);
                                        
        flag = String.isNotBlank(matchName) && matchName.equalsIgnoreCase(registeredName);
        return flag;
    }
    
    /**
      This method maps wsdl ABR element to custom wrapper ABR element.
    */
    public static APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element getABRReport(APT_SchemaPartyCustomerService.AustralianBusinessRegisterReport_element ABRReportResp){
        try {
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element ABRReport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            
            system.debug('ABRReportResp-->' + ABRReportResp);
            
            if(ABRReportResp != null){
                ABRReport.ASICNumber = ABRReportResp.ASICNumber;
                ABRReport.ASICNumberType = ABRReportResp.ASICNumberType;
                ABRReport.ABN = ABRReportResp.ABN;
                ABRReport.ABNStatus = ABRReportResp.ABNStatus;
                ABRReport.ABNStatusFromDate = ABRReportResp.ABNStatusFromDate;
                ABRReport.EntityTypeText = ABRReportResp.EntityTypeText;
                ABRReport.EntityTypeInd = ABRReportResp.EntityTypeInd;
                ABRReport.IndividualName = ABRReportResp.IndividualName;
                ABRReport.NonIndividualName = ABRReportResp.NonIndividualName;
                ABRReport.BusinessAddressState = ABRReportResp.BusinessAddressState;
                ABRReport.BusinessAddressPostcode = ABRReportResp.BusinessAddressPostcode;
                ABRReport.GSTStatus = ABRReportResp.GSTStatus;
                ABRReport.GSTStatusFromDate = ABRReportResp.GSTStatusFromDate;
                ABRReport.TradingName = ABRReportResp.TradingName;
                ABRReport.ErrorMsg = ABRReportResp.ErrorMsg;
                ABRReport.WarningMsg = ABRReportResp.WarningMsg;
            }
                    
            return ABRReport;
       } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }         
    }
    
    /**
     This method maps wsdl ASIC element to custom wrapper ASIC element.
    */
    public static APT_OrgIDWebServiceWrapper.ASICReport_element getASICReport(APT_SchemaPartyCustomerService.ASICReport_element ASICReportResp){
       try { 
            APT_OrgIDWebServiceWrapper.ASICReport_element ASICReport = new APT_OrgIDWebServiceWrapper.ASICReport_element();
            
            system.debug('ASICReportResp-->' + ASICReportResp);
            if(ASICReportResp != null){
                ASICReport.ASICName = ASICReportResp.ASICName;
                ASICReport.ASICOrganisationNumber = ASICReportResp.ASICOrganisationNumber;
                ASICReport.ASICABN = ASICReportResp.ASICABN;
                ASICReport.ASICOrganisationNumberHeading = ASICReportResp.ASICOrganisationNumberHeading;
                ASICReport.ASICPrescribedInterestNumber = ASICReportResp.ASICPrescribedInterestNumber;
                ASICReport.ASICUndertakingName = ASICReportResp.ASICUndertakingName;
                ASICReport.ASICType = ASICReportResp.ASICType;
                ASICReport.ASICRegistrationDate = ASICReportResp.ASICRegistrationDate;
                ASICReport.ASICStatus = ASICReportResp.ASICStatus;
                ASICReport.ASICState = ASICReportResp.ASICState;
                ASICReport.ASICBusinessRegistrationNumber = ASICReportResp.ASICBusinessRegistrationNumber;
                ASICReport.ASICJurisdiction = ASICReportResp.ASICJurisdiction;
                ASICReport.ErrorMsg = ASICReportResp.ErrorMsg;
                ASICReport.WarningMsg = ASICReportResp.WarningMsg;
                ASICReport.ASICLocality = ASICReportResp.ASICLocality;
                ASICReport.ASICAddressState = ASICReportResp.ASICAddressState;
                ASICReport.ASICPostcode = ASICReportResp.ASICPostcode;
            }
            return ASICReport;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }        
    }
    
    /**
     This method maps wsdl bureau report element to custom wrapper bureau report element.
    */
    public static APT_OrgIDWebServiceWrapper.BureauReport_element getBureauReport(APT_SchemaPartyCustomerService.BureauReport_element BureauReportResp){
       try {  
        APT_OrgIDWebServiceWrapper.BureauReport_element BureauReport = new APT_OrgIDWebServiceWrapper.BureauReport_element();
        return BureauReport;
       } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }         
    }
    
    /**
    * This method maps wsdl ASIC BNR report element to custom wrapper ASIC BNR report element.
    */
    public static APT_OrgIDWebServiceWrapper.ASICBNRReport_element getASICBNRReport(APT_SchemaPartyCustomerService.ASICBNRReport_element ASICBNRReportResp){
       try { 
            //Not used right now so not updating the class.
            APT_OrgIDWebServiceWrapper.ASICBNRReport_element ASICBNRReport = new APT_OrgIDWebServiceWrapper.ASICBNRReport_element();
            
            /**
             public APT_OrgIDWebServiceWrapper.BusinessNameType BusinessName {get; set;}
            public APT_OrgIDWebServiceWrapper.BusinessNameHolderType BusinessNameHolder {get;set;}
            public String[] ErrorMsg  {get;set;}
            public String[] WarningMsg {get;set;}
            
            ***/
            return ASICBNRReport;
       } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }         
    }
    
    /**
    * This method return Org ID response Details for selected ASIC Report.
    */
    public static APT_OrgIDWebServiceWrapper.OrgIdResult_element getSelectedOrgIDWrapper(List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgIdResultWrapList, Integer selectedUniqueNumber){
       try { 
            APT_OrgIDWebServiceWrapper.OrgIdResult_element selectedOrgIdWrapper = null;
            
            for(APT_OrgIDWebServiceWrapper.OrgIdResult_element wrap :  orgIdResultWrapList){
                if(wrap.OrgIdResultUniqueNumber == selectedUniqueNumber){
                    selectedOrgIdWrapper = wrap;
                    break;
                }
            } 
            return selectedOrgIdWrapper;
       } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
    }
        /*
        This method will return selected ASIC Report.
    */
    public static APT_ASIC_Report__c getSelectedASICReport(APT_OrgIDWebServiceWrapper.ASICReport_element asicReport){
        try {
            APT_ASIC_Report__c selectedASICReport = new APT_ASIC_Report__c();
            system.debug('**** ASIC TYPE ****'+asicReport.ASICType);
            if(asicReport != null){
                    
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
            }
            return selectedASICReport;
        } catch(system.exception ex) {
                    
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                    return null;
        }        
    }
        /*
        This method will return selected ABR Report.
    */    
    public static APT_ABRreport__c getSelectedABRReport(APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element abrReport){
        try {
            APT_ABRreport__c selectedABRReport = new APT_ABRreport__c();
            
            if(abrReport != null){
                    
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
            }
            return selectedABRReport;
       } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
        
    }
        /*
        This method will return Entity type.
    */       
    public static APT_Entity_Type_Mapping__mdt getEntityType(String asicReportType,string abnReportType){
        try {
            APT_Entity_Type_Mapping__mdt entityType;
            
            String valueFormat;
            
            if(String.isNotBlank(asicReportType)){
                valueFormat = APT_Constants.SEPARATOR_PERCENT + asicReportType + APT_Constants.SEPARATOR_PERCENT;
            } else if(String.isNotBlank(abnReportType)){ 
                valueFormat = APT_Constants.SEPARATOR_PERCENT + abnReportType + APT_Constants.SEPARATOR_PERCENT;
            }  else {
                return null;
            }
            system.debug('-->'+valueFormat);
            List<APT_Entity_Type_Mapping__mdt> EntityTypeMapings = [SELECT MasterLabel, APT_ASIC_Type__c, APT_Entity_Type__c, 
                                                                    APT_Is_Sole_Trader_Entity__c 
                                                                    FROM APT_Entity_Type_Mapping__mdt 
                                                                    WHERE APT_ASIC_Type__c like: valueFormat 
                                                                    AND APT_Is_Active__c = true];
            if(EntityTypeMapings != null && EntityTypeMapings.size() > 0){
                entityType = EntityTypeMapings[0];      
            }
            
            return entityType;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
    
         /*
        This method will return credit assesment.
    */      
    public static APT_Credit_Assessment__c showSoletraderPage(APT_Credit_Assessment__c creditAssesment,
                                                            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdWrap){
        try {
            creditAssesment.APT_Legal_Entity_Name__c = orgIdWrap.ASICReport.ASICName;
            //1550
            if(String.isBlank(creditAssesment.APT_Business_Type__c )) {
                creditAssesment.APT_Business_Type__c = orgIdWrap.EntityTypeMasterLabel;                            
            }     
            //1550       
                    
            creditAssesment.APT_Term_Days__c = APT_Constants.CONSTANT_VEDA_ACCOUNT_TYPE;
            //Calculate Business History Age
            if(orgIdWrap.AustralianBusinessRegisterReport.ABNStatusFromDate != null) {
                date abnStatusFromDate = orgIdWrap.AustralianBusinessRegisterReport.ABNStatusFromDate;
                date todaysDate = date.today();
                Integer monthsDifference = abnStatusFromDate.monthsBetween(todaysDate);
                if(todaysDate.day() > abnStatusFromDate.day()) {
                    monthsDifference++;
                }
                creditAssesment.APT_Business_History_Age__c = monthsDifference;
            }
    
            return creditAssesment;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
    
    
    /*
        This method will set value for credit assessment.
    */
    public static APT_Credit_Assessment__c showCompanyBusinessPage(APT_Credit_Assessment__c creditAssesment, 
                                                            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdWrap){
       try { 
            creditAssesment.APT_Legal_Entity_Name__c = orgIdWrap.ASICReport.ASICName;
            
            creditAssesment.APT_Entity_Type__c = orgIdWrap.EntityTypeLabel;
            creditAssesment.APT_ACN__c = orgIdWrap.ASICReport.ASICOrganisationNumber;
            creditAssesment.APT_Account_Type__c = APT_Constants.CONSTANT_VEDA_ACCOUNT_TYPE;
            creditAssesment.APT_Business_Type__c = orgIdWrap.EntityTypeMasterLabel;
            return creditAssesment;
       } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
    } 
    /*
        This method will set value for charge account.
    */      
    public static APT_Charge_Account__c chargeAccountForSoleTrader(APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdWrap,
                                                                        APT_Charge_Account__c chargeAccount) {
       try {
            chargeAccount.APT_Business_name__c = orgIdWrap.MatchName;
            chargeAccount.APT_Company_Name__c = orgIdWrap.MatchName;
            //chargeAccount.APT_Entity_Type__c = entityType;
            
            chargeAccount.APT_ACN__c = String.isNotBlank(orgIdWrap.ASICReport.ASICOrganisationNumber) ? 
                                                orgIdWrap.ASICReport.ASICOrganisationNumber : orgIdWrap.AustralianBusinessRegisterReport.ASICNumber;
            chargeAccount.APT_ABN__c = String.isNotBlank(orgIdWrap.ASICReport.ASICABN) ? 
                                                orgIdWrap.ASICReport.ASICABN: orgIdWrap.AustralianBusinessRegisterReport.ABN;
            
            //chargeAccount.APT_Account_Type__c = 'D30';
            chargeAccount.APT_Term_Days__c = APT_Constants.CONSTANT_VEDA_TERM_DAYS;
            
            //copy billing address
            chargeAccount.APT_Applicant1_BA_Unit_Number__c = chargeAccount.APT_Billing_Address_Unit_Number__c;
            chargeAccount.APT_Applicant1_BA_Street_Number__c = chargeAccount.APT_Billing_Address_Street_Number__c;
            chargeAccount.APT_Applicant1_BA_Street_Name__c = chargeAccount.APT_Billing_Address_Street_Name__c;
            chargeAccount.APT_Applicant1_BA_Street_Type__c = chargeAccount.APT_Billing_Address_Street_Type__c;
            chargeAccount.APT_Applicant1_BA_Suburb__c = chargeAccount.APT_Billing_Address_Suburb__c;
            chargeAccount.APT_Applicant1_BA_Street_Postcode__c = chargeAccount.APT_Billing_Address_Street_Postcode__c;
            chargeAccount.APT_Applicant1_BA_State__c = chargeAccount.APT_Billing_Addres_State__c;
            chargeAccount.APT_Applicant1_BA_Country_Code__c = chargeAccount.APT_Billing_Address_Country_Code__c;
    
            //copy street address
            chargeAccount.APT_Applicant1_SA_Unit_Number__c = chargeAccount.APT_Street_Address_Unit_Number__c;
            chargeAccount.APT_Applicant1_SA_Street_Number__c = chargeAccount.APT_Street_Address_Street_Number__c;
            chargeAccount.APT_Applicant1_SA_Street_Name__c = chargeAccount.APT_Street_Address_Street_Name__c;
            chargeAccount.APT_Applicant1_SA_Street_Type__c = chargeAccount.APT_Street_Address_Street_Type__c;
            chargeAccount.APT_Applicant1_SA_Suburb__c = chargeAccount.APT_Street_Address_Suburb__c;
            chargeAccount.APT_Applicant1_SA_Street_Postcode__c = chargeAccount.APT_Street_Address_Street_Postcode__c;
            chargeAccount.APT_Applicant1_SA_State__c = chargeAccount.APT_Street_Address_State__c;
            chargeAccount.APT_Applicant1_SA_Country_Code__c = chargeAccount.APT_Street_Address_Country_Code__c;
            
            return chargeAccount;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
    
    /**
        This method will set value for charge account.
    **/                                                            
    public static APT_Charge_Account__c chargeAccountForCompanyBusiness(APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdWrap,
                                                                        APT_Charge_Account__c chargeAccount) {
        try {
            chargeAccount.APT_Company_Name__c = orgIdWrap.MatchName;
            chargeAccount.APT_ACN__c = String.isNotBlank(orgIdWrap.ASICReport.ASICOrganisationNumber) ? 
                                                orgIdWrap.ASICReport.ASICOrganisationNumber : orgIdWrap.AustralianBusinessRegisterReport.ASICNumber;
            chargeAccount.APT_ABN__c = String.isNotBlank(orgIdWrap.ASICReport.ASICABN) ? 
                                                orgIdWrap.ASICReport.ASICABN: orgIdWrap.AustralianBusinessRegisterReport.ABN;
            //chargeAccount.APT_ABN__c = orgIdWrap.ASICReport.ASICABN;
            chargeAccount.APT_Term_Days__c = APT_Constants.CONSTANT_VEDA_TERM_DAYS;
    
            return chargeAccount;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
    
    /*------------------------------------------------------------
    Author:        Shashwat Nath
    Description:   Method to perform HTTP callout to TIBCO
                   parse the response returned for the Company Credit Assessment
    Inputs:        creditAssessmentId : Credit Assessment Recordid
                   chargeAccount : Instance of the Charge Account
                   entityTypeForAssessment : Type of Entity for ex Company Or Other
    Returns:       Map<String,String> : Map of Response element and response value
    */
      
      public static Map<String,String> creditCheckForCompanyBusiness(String creditAssessmentId, string entityTypeForAssessment, APT_Charge_Account__c chargeAccount ){ 
         try {  
                Map<String,String> decisionMap = new Map<String,String>();
                string totalProposedCreditLimit = '';
                string requestString = '';
                //Querying the Credit Assessment Record 
                APT_Credit_Assessment__c creditAssesment = [select id, APT_Legal_Entity_Name__c, APT_Entity_Type__c, APT_Industry_Type__c,  APT_ACN__c, APT_ABN__c,
                                                                APT_Proposal__r.Apttus_Proposal__Opportunity__r.type,APT_Term_Days__c ,APT_Applicant_1_First_Name__c,APT_Applicant_1_Middle_Name__c,
                                                                APT_Applicant_1_Last_Name__c,APT_Applicant_1_Date_of_Birth__c,APT_Applicant_1_Drivers_Licence_Number__c,APT_Credit_Amount_Required__c, APT_Account_Type__c,L2C_Star_Track_Proposed_Credit_Limit__c, L2C_AP_Proposed_Credit_Limit__c,
                                                                APT_Applicant_1_Property__c,APT_Applicant_1_Unit_Number__c,APT_Applicant_1_Street_Number__c ,APT_Applicant_1_Street_Name__c, APT_Applicant_1_Street_Type__c,
                                                                APT_Applicant_1_Suburb__c, APT_Applicant_1_Postcode__c , APT_Applicant_2_First_Name__c,APT_Applicant_2_Middle_Name__c,APT_Applicant_1_State__c,
                                                                APT_Applicant_2_Last_Name__c, APT_Applicant_2_Date_of_Birth__c , APT_Applicant_2_Drivers_Licence_Number__c ,APT_Applicant_2_Credit_Check_Consent__c ,
                                                                APT_Applicant_2_Property__c , APT_Applicant_2_Unit_Number__c , APT_Applicant_2_Street_Number__c , 
                                                                APT_Applicant_2_Street_Name__c , APT_Applicant_2_Street_Type__c , APT_Applicant_2_Postcode__c  from APT_Credit_Assessment__c where id=: creditAssessmentId];
               
                
               //Fething the details from the Custom setting to set the EndPoint for the callout
                APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
                string endPoint = '';
                if(r2tSystemProperty != null && r2tSystemProperty.APT_CompanyCreditAssessmentEndPointURL__c != null) {
                    endPoint = r2tSystemProperty.APT_CompanyCreditAssessmentEndPointURL__c;
                }
              
               if(creditAssesment.APT_ACN__c!=null && creditAssesment.APT_ABN__c !=null) {
                    requestString = '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                         '<env:Header>'+
                              '<InterfaceHeader xmlns="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1">'+
                                '<InterfaceName>getCreditAssessment</InterfaceName>'+
                                '<InterfaceVersion>1.0</InterfaceVersion>'+
                              '<MessageType>Request</MessageType>'+
                              '<BusinessReferenceID>'+system.now()+'</BusinessReferenceID>'+
                               '<SourceSystemID>Apttus</SourceSystemID>'+
                                 '<Timestamp>2019-05-30T12:29:49.038Z</Timestamp>'+ 
                                '</InterfaceHeader>'+
                           '</env:Header>'+
                           '<env:Body>'+
                            '<getCompanyCreditAssessment xmlns="http://www.auspost.com.au/Service/Party/Customer/getCompanyCreditAssessment:v1" xmlns:n1="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending">'+
                             '<CompanyBusinessRequest xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                 '<applicationID xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+generateRandomNumber().escapeXML()+'</applicationID>'+
                                '<primaryContact xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                '<name>'+(chargeAccount.APT_Contact_Name__c).escapeXML()+'</name>'+
                                '<email>dummymail@test.com</email>'+
                                  '<phone>'+
                                   '<areaCode>02</areaCode>'+
                                    '<number>12345678</number>'+
                                     '</phone>'+
                                      '<mobile>61412345678</mobile>'+
                                       '<address>'+
                                         '<streetNumber>'+(chargeAccount.APT_Billing_Address_Street_Number__c).escapeXML()+'</streetNumber>'+
                                         '<streetName>'+(chargeAccount.APT_Billing_Address_Street_Name__c).escapeXML()+'</streetName>'+
                                          '<suburb>'+(chargeAccount.APT_Billing_Address_Suburb__c).escapeXML()+'</suburb>'+
                                          '<state>'+(chargeAccount.APT_Billing_Addres_State__c).escapeXML()+'</state>'+
                                          '<postcode>'+(chargeAccount.APT_Billing_Address_Street_Postcode__c).escapeXML()+'</postcode>'+
                                       '</address>'+
                                       '<promotionalInformation>false</promotionalInformation>'+
                                    '</primaryContact>'+
                                    '<commercialApplication xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                     '<creditAmountRequired>'+string.valueOf(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c).IntValue()).escapeXML()+'</creditAmountRequired>'+
                                      '<termDays>D14</termDays>'+
                                    '</commercialApplication>'+
                                    '<organisation xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                     '<organisationDetails>'+
                                      '<name>'+(creditAssesment.APT_Legal_Entity_Name__c).escapeXML()+'</name>'+
                                       '<entityType>'+entityTypeForAssessment.escapeXML()+'</entityType>'+
                                       '<entitySubtype>INC</entitySubtype>'+
                                        '<australianCompanyNumber>'+(creditAssesment.APT_ACN__c).escapeXML()+'</australianCompanyNumber>'+
                                          '<australianBusinessNumber>'+(creditAssesment.APT_ABN__c).escapeXML()+'</australianBusinessNumber>'+
                                       '</organisationDetails>'+
                                       '<tradingAddress>'+
                                        '<streetNumber>'+(chargeAccount.APT_Billing_Address_Street_Number__c).escapeXML()+'</streetNumber>'+
                                         '<streetName>'+(chargeAccount.APT_Billing_Address_Street_Name__c).escapeXML()+'</streetName>'+
                                          '<suburb>'+(chargeAccount.APT_Billing_Address_Suburb__c).escapeXML()+'</suburb>'+
                                          '<state>'+(chargeAccount.APT_Billing_Addres_State__c).escapeXML()+'</state>'+
                                          '<postcode>'+(chargeAccount.APT_Billing_Address_Street_Postcode__c).escapeXML()+'</postcode>'+
                                       '</tradingAddress>'+
                                    '</organisation>'+
                                    '<paymentDetails xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                      '<paymentOption>Cash</paymentOption>'+
                                   '</paymentDetails>'+
                                 '</CompanyBusinessRequest>'+
                             '</getCompanyCreditAssessment>'+
                           '</env:Body>'+
                        '</env:Envelope>';
                }
                else if(creditAssesment.APT_ABN__c == null && creditAssesment.APT_ACN__c!=null) {
                    requestString = '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                         '<env:Header>'+
                              '<InterfaceHeader xmlns="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1">'+
                                '<InterfaceName>getCreditAssessment</InterfaceName>'+
                                '<InterfaceVersion>1.0</InterfaceVersion>'+
                              '<MessageType>Request</MessageType>'+
                              '<BusinessReferenceID>'+system.now()+'</BusinessReferenceID>'+
                               '<SourceSystemID>Apttus</SourceSystemID>'+
                                 '<Timestamp>2019-05-30T12:29:49.038Z</Timestamp>'+ 
                                '</InterfaceHeader>'+
                           '</env:Header>'+
                           '<env:Body>'+
                            '<getCompanyCreditAssessment xmlns="http://www.auspost.com.au/Service/Party/Customer/getCompanyCreditAssessment:v1" xmlns:n1="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending">'+
                             '<CompanyBusinessRequest xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                 '<applicationID xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+generateRandomNumber().escapeXML()+'</applicationID>'+
                                '<primaryContact xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                '<name>'+(chargeAccount.APT_Contact_Name__c).escapeXML()+'</name>'+
                                 '<email>dummymail@test.com</email>'+
                                  '<phone>'+
                                   '<areaCode>02</areaCode>'+
                                    '<number>12345678</number>'+
                                     '</phone>'+
                                      '<mobile>61412345678</mobile>'+
                                       '<address>'+
                                         '<streetNumber>'+(chargeAccount.APT_Billing_Address_Street_Number__c).escapeXML()+'</streetNumber>'+
                                         '<streetName>'+(chargeAccount.APT_Billing_Address_Street_Name__c).escapeXML()+'</streetName>'+
                                          '<suburb>'+(chargeAccount.APT_Billing_Address_Suburb__c).escapeXML()+'</suburb>'+
                                          '<state>'+(chargeAccount.APT_Billing_Addres_State__c).escapeXML()+'</state>'+
                                          '<postcode>'+(chargeAccount.APT_Billing_Address_Street_Postcode__c).escapeXML()+'</postcode>'+
                                       '</address>'+
                                       '<promotionalInformation>false</promotionalInformation>'+
                                    '</primaryContact>'+
                                    '<commercialApplication xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                     '<creditAmountRequired>'+String.ValueOf(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c).IntValue()).escapeXML()+'</creditAmountRequired>'+
                                      '<termDays>D14</termDays>'+
                                    '</commercialApplication>'+
                                    '<organisation xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                     '<organisationDetails>'+
                                      '<name>'+(creditAssesment.APT_Legal_Entity_Name__c).escapeXML()+'</name>'+
                                       '<entityType>'+entityTypeForAssessment.escapeXML()+'</entityType>'+
                                       '<entitySubtype>INC</entitySubtype>'+
                                        '<australianCompanyNumber>'+(creditAssesment.APT_ACN__c).escapeXML()+'</australianCompanyNumber>'+
                                       '</organisationDetails>'+
                                       '<tradingAddress>'+
                                        '<streetNumber>'+(chargeAccount.APT_Billing_Address_Street_Number__c).escapeXML()+'</streetNumber>'+
                                         '<streetName>'+(chargeAccount.APT_Billing_Address_Street_Name__c).escapeXML()+'</streetName>'+
                                          '<suburb>'+(chargeAccount.APT_Billing_Address_Suburb__c).escapeXML()+'</suburb>'+
                                          '<state>'+(chargeAccount.APT_Billing_Addres_State__c).escapeXML()+'</state>'+
                                          '<postcode>'+(chargeAccount.APT_Billing_Address_Street_Postcode__c).escapeXML()+'</postcode>'+
                                       '</tradingAddress>'+
                                    '</organisation>'+
                                    '<paymentDetails xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                      '<paymentOption>Cash</paymentOption>'+
                                   '</paymentDetails>'+
                                 '</CompanyBusinessRequest>'+
                             '</getCompanyCreditAssessment>'+
                           '</env:Body>'+
                        '</env:Envelope>';    
                }
                
                else if(creditAssesment.APT_ABN__c != null && creditAssesment.APT_ACN__c==null){
                requestString = '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                         '<env:Header>'+
                              '<InterfaceHeader xmlns="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1">'+
                                '<InterfaceName>getCreditAssessment</InterfaceName>'+
                                '<InterfaceVersion>1.0</InterfaceVersion>'+
                              '<MessageType>Request</MessageType>'+
                              '<BusinessReferenceID>'+system.now()+'</BusinessReferenceID>'+
                               '<SourceSystemID>Apttus</SourceSystemID>'+
                                 '<Timestamp>2019-05-30T12:29:49.038Z</Timestamp>'+ 
                                '</InterfaceHeader>'+
                           '</env:Header>'+
                           '<env:Body>'+
                            '<getCompanyCreditAssessment xmlns="http://www.auspost.com.au/Service/Party/Customer/getCompanyCreditAssessment:v1" xmlns:n1="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending">'+
                             '<CompanyBusinessRequest xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                 '<applicationID xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+generateRandomNumber().escapeXML()+'</applicationID>'+
                                '<primaryContact xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                '<name>'+(chargeAccount.APT_Contact_Name__c).escapeXML()+'</name>'+
                                 '<email>dummymail@test.com</email>'+
                                  '<phone>'+
                                   '<areaCode>02</areaCode>'+
                                    '<number>12345678</number>'+
                                     '</phone>'+
                                      '<mobile>61412345678</mobile>'+
                                       '<address>'+
                                         '<streetNumber>'+(chargeAccount.APT_Billing_Address_Street_Number__c).escapeXML()+'</streetNumber>'+
                                         '<streetName>'+(chargeAccount.APT_Billing_Address_Street_Name__c).escapeXML()+'</streetName>'+
                                          '<suburb>'+(chargeAccount.APT_Billing_Address_Suburb__c).escapeXML()+'</suburb>'+
                                          '<state>'+(chargeAccount.APT_Billing_Addres_State__c).escapeXML()+'</state>'+
                                          '<postcode>'+(chargeAccount.APT_Billing_Address_Street_Postcode__c).escapeXML()+'</postcode>'+
                                       '</address>'+
                                       '<promotionalInformation>false</promotionalInformation>'+
                                    '</primaryContact>'+
                                    '<commercialApplication xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                     '<creditAmountRequired>'+string.valueOf(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c).IntValue()).escapeXML()+'</creditAmountRequired>'+
                                      '<termDays>D14</termDays>'+
                                    '</commercialApplication>'+
                                    '<organisation xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                     '<organisationDetails>'+
                                      '<name>'+(creditAssesment.APT_Legal_Entity_Name__c).escapeXML()+'</name>'+
                                       '<entityType>'+entityTypeForAssessment.escapeXML()+'</entityType>'+
                                       '<entitySubtype>INC</entitySubtype>'+
                                        '<australianBusinessNumber>'+(creditAssesment.APT_ABN__c).escapeXML()+'</australianBusinessNumber>'+
                                       '</organisationDetails>'+
                                       '<tradingAddress>'+
                                        '<streetNumber>'+(chargeAccount.APT_Billing_Address_Street_Number__c).escapeXML()+'</streetNumber>'+
                                         '<streetName>'+(chargeAccount.APT_Billing_Address_Street_Name__c).escapeXML()+'</streetName>'+
                                          '<suburb>'+(chargeAccount.APT_Billing_Address_Suburb__c).escapeXML()+'</suburb>'+
                                          '<state>'+(chargeAccount.APT_Billing_Addres_State__c).escapeXML()+'</state>'+
                                          '<postcode>'+(chargeAccount.APT_Billing_Address_Street_Postcode__c).escapeXML()+'</postcode>'+
                                       '</tradingAddress>'+
                                    '</organisation>'+
                                    '<paymentDetails xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                      '<paymentOption>Cash</paymentOption>'+
                                   '</paymentDetails>'+
                                 '</CompanyBusinessRequest>'+
                             '</getCompanyCreditAssessment>'+
                           '</env:Body>'+
                        '</env:Envelope>';   
                }
                
                
               system.debug(' REQUEST STRING'+requestString);
               if(String.IsNotBlank(requestString)){
               // Creating the HTTP Request 
                   HttpRequest req = new HttpRequest();
                   if(String.isNotBlank(endPoint)){
                       // Setting Request Endpoint
                       req.setEndpoint(endPoint);
                   }
                   // Setting Request Header
                   req.setHeader('SOAPAction','/Services/ExternalCreditAssessmentServices/getCompanyCreditAssessment_v1');
                   // Setting Request Method
                   req.setMethod('POST');
                   // Setting Request Body
                   req.setBody(requestString);
                   req.setHeader(APT_WebServiceUtility.AUTHORIZATION , APT_WebServiceUtility.getinputHttpHeaders().get(APT_WebServiceUtility.AUTHORIZATION));
                   req.setHeader('Content-Type', 'text/xml');
                   // Setting Request Timeout
                   req.setTimeout(120000);
                   Http http = new Http();
                   //Making Call out to TIBCO
                   HTTPResponse res = http.send(req); 
                   system.debug('---Respone--'+res.getbody());
                   Dom.Document doc = res.getBodyDocument();
                   Dom.XMLNode rootElement = doc.getRootElement();
                   //Parsing the Response
                   decisionMap =  parseXML(rootElement, decisionMap);
                   //Returning the response
                   system.debug('***** DECISION MAP*****'+decisionMap);
                   return decisionMap;
               }
               else{
                  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please Validate the ABN/ACN'));
                  return null;
               }
               
         } catch(system.exception e) {
            system.debug('***** Exception Line Number*****'+e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        } 
        
     }
     
   /*------------------------------------------------------------
    Author:        Shashwat Nath
    Description:   Method to parse the response xml and store all the values in a Map
    Inputs:        DOM.XMLNode: Root element of the Response                 
                      entityTypeForAssessment : Type of Entity for ex Company Or Other
    Returns:       Map<String,String> : Map of Response element and response value
    */
    
     private static Map<String,String> parseXML(DOM.XMLNode node , Map<String,String> decisionMap) {
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            // Putting the response and element value to the Map
            decisionMap.put(node.getname(),node.getText().trim());
        }
        for (Dom.XMLNode child: node.getChildElements()) {
            parseXML(child , decisionMap);
        }
       return decisionMap;
    }
    
    /*------------------------------------------------------------
    Author:        Shashwat Nath
    Description:   Method to perform HTTP callout to TIBCO
                   parse the response returned for the Individual Credit Assessment
    Inputs:        creditAssessmentId : Credit Assessment Recordid
                   chargeAccount : Instance of the Charge Account
    Returns:       void
    */
    
      public static Map<String,String> creditCheckForSoleTrader(String creditAssessmentId ,APT_Charge_Account__c chargeAccount ){  
        try {
            Map<String,String> decisionMap = new Map<String,String>();
            string endpoint = '' ;
            string totalProposedCreditLimit = '' ;
            string requestString = '' ;
            //Querying the Credit Assessment Record 
            APT_Credit_Assessment__c creditAssesment = [select id, APT_Legal_Entity_Name__c, APT_Entity_Type__c, APT_Industry_Type__c,  APT_ACN__c,
                                                            APT_Credit_Amount_Required__c, APT_Account_Type__c, APT_Term_Days__c , APT_Business_History_Age__c, 
                                                            APT_Applicant_1_First_Name__c, APT_Applicant_1_Middle_Name__c,
                                                            APT_Applicant_1_Last_Name__c, APT_Applicant_1_Date_of_Birth__c,
                                                            APT_Applicant_1_Drivers_Licence_Number__c, APT_Applicant_1_Property__c,
                                                            APT_Applicant_1_Unit_Number__c, APT_Applicant_1_Street_Number__c, 
                                                            APT_Applicant_1_Street_Name__c, APT_Applicant_1_Street_Type__c, 
                                                            APT_Applicant_1_Suburb__c, APT_Applicant_1_Postcode__c, APT_Applicant_1_State__c,
                                                            APT_Applicant_1_Country__c, 
                                                            APT_Proposal__r.Apttus_Proposal__Opportunity__r.type, 
                                                            APT_Applicant_2_First_Name__c, APT_Applicant_2_Middle_Name__c,
                                                            APT_Applicant_2_Last_Name__c, APT_Applicant_2_Date_of_Birth__c,
                                                            APT_Applicant_2_Drivers_Licence_Number__c, APT_Applicant_2_Property__c,
                                                            APT_Applicant_2_Unit_Number__c, APT_Applicant_2_Street_Number__c, 
                                                            APT_Applicant_2_Street_Name__c, APT_Applicant_2_Street_Type__c, 
                                                            APT_Applicant_2_Suburb__c, APT_Applicant_2_Postcode__c, APT_Applicant_2_State__c,
                                                            APT_Applicant_2_Country__c,L2C_AP_Proposed_Credit_Limit__c,L2C_Star_Track_Proposed_Credit_Limit__c,
                                                            APT_Applicant_2_Credit_Check_Consent__c, APT_Applicant_1_Credit_Check_Consent__c
                                                            from APT_Credit_Assessment__c where id=: creditAssessmentId];
                    
            
            
            //Fething the details from the Custom setting to set the EndPoint for the callout
            APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
            if(r2tSystemProperty != null && r2tSystemProperty.APT_INDV_Credit_Assessment_End_Point_URL__c != null) {
                endpoint = r2tSystemProperty.APT_INDV_Credit_Assessment_End_Point_URL__c;
            }
            
            if(chargeAccount.APT_ABN__c != null){
                requestString = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:com="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1" xmlns:get="http://www.auspost.com.au/Service/Party/Customer/getIndividualCreditAssessment:v1" xmlns:len="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending">'+
                                   '<soapenv:Header>'+
                                      '<com:InterfaceHeader>'+
                                         '<com:InterfaceName>getCreditAssessment</com:InterfaceName>'+
                                         '<com:InterfaceVersion>1.0</com:InterfaceVersion>'+
                                         '<com:MessageType>Request</com:MessageType>'+
                                         '<com:BusinessReferenceID>'+system.now()+'</com:BusinessReferenceID>'+
                                         '<com:SourceSystemID>Apttus</com:SourceSystemID>'+
                                         '<com:Timestamp>2019-05-30T12:29:49.038Z</com:Timestamp>'+
                                      '</com:InterfaceHeader>'+
                                   '</soapenv:Header>'+
                                   '<soapenv:Body>'+
                                      '<get:getIndividualCreditAssessment>'+
                                         '<len:IndividualCommercialRequest>'+
                                            '<len:applicationID>'+generateRandomNumber().escapeXML()+'</len:applicationID>'+
                                            '<len:primaryContact>'+
                                               '<len:name>'+(creditAssesment.APT_Applicant_1_First_Name__c).escapeXML()+'</len:name>'+
                                               '<len:email>dummymail@test.com</len:email>'+
                                               '<len:phone>'+
                                                  '<len:areaCode>02</len:areaCode>'+
                                                  '<len:number>12345678</len:number>'+
                                               '</len:phone>'+
                                               '<len:mobile>61412345678</len:mobile>'+
                                               '<len:address>'+
                                                  '<len:streetNumber>'+(creditAssesment.APT_Applicant_1_Street_Number__c).escapeXML()+'</len:streetNumber>'+
                                                  '<len:streetName>'+(creditAssesment.APT_Applicant_1_Street_Name__c).escapeXML()+'</len:streetName>'+
                                                  '<len:suburb>'+(creditAssesment.APT_Applicant_1_Suburb__c).escapeXML()+'</len:suburb>'+
                                                  '<len:state>'+(creditAssesment.APT_Applicant_1_State__c).escapeXML()+'</len:state>'+
                                                  '<len:postcode>'+(creditAssesment.APT_Applicant_1_Postcode__c).escapeXML()+'</len:postcode>'+
                                               '</len:address>'+
                                              '<len:promotionalInformation>false</len:promotionalInformation>'+
                                            '</len:primaryContact>'+
                                            '<len:commercialApplication>'+
                                               '<len:creditAmountRequired>'+string.valueOf(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c).IntValue()).escapeXML()+'</len:creditAmountRequired>'+
                                               '<len:termDays>D14</len:termDays>'+
                                            '</len:commercialApplication>'+
                                            '<len:businessDetails>'+
                                               '<len:tradingName>'+(creditAssesment.APT_Legal_Entity_Name__c).escapeXML()+'</len:tradingName>'+
                                               '<len:ABN>'+(chargeAccount.APT_ABN__c).escapeXML()+'</len:ABN>'+
                                             '</len:businessDetails>'+
                                            '<len:additionalApplicants>'+
                                               '<len:applicant>'+
                                                  '<len:applicantDetails>'+
                                                     '<len:firstName>'+(creditAssesment.APT_Applicant_1_First_Name__c).escapeXML()+'</len:firstName>'+
                                                     '<len:lastName>'+(creditAssesment.APT_Applicant_1_Last_Name__c).escapeXML()+'</len:lastName>'+
                                                     '<len:dateOfBirth>'+String.ValueOf(creditAssesment.APT_Applicant_1_Date_of_Birth__c).escapeXML()+'</len:dateOfBirth>'+
                                                   '</len:applicantDetails>'+
                                                  '<len:address>'+
                                                     '<len:streetNumber>'+(creditAssesment.APT_Applicant_1_Street_Number__c).escapeXML()+'</len:streetNumber>'+
                                                     '<len:streetName>'+(creditAssesment.APT_Applicant_1_Street_Name__c).escapeXML()+'</len:streetName>'+
                                                     '<len:suburb>'+(creditAssesment.APT_Applicant_1_Suburb__c).escapeXML()+'</len:suburb>'+
                                                     '<len:state>'+(creditAssesment.APT_Applicant_1_State__c).escapeXML()+'</len:state>'+
                                                     '<len:postcode>'+(creditAssesment.APT_Applicant_1_Postcode__c).escapeXML()+'</len:postcode>'+
                                                  '</len:address>'+
                                                  '<len:contactDetails>'+
                                                     '<len:email>dummymail@test.com</len:email>'+
                                                     '<len:phone>'+
                                                        '<len:areaCode>02</len:areaCode>'+
                                                        '<len:number>12345678</len:number>'+
                                                     '</len:phone>'+
                                                     '<len:mobile>61412345678</len:mobile>'+
                                                  '</len:contactDetails>'+
                                                  '<len:additionalApplicantData>'+
                                                     '<len:name>'+(creditAssesment.APT_Applicant_1_First_Name__c).escapeXML()+'</len:name>'+
                                                     '<len:value>'+(creditAssesment.APT_Applicant_1_Last_Name__c).escapeXML()+'</len:value>'+
                                                  '</len:additionalApplicantData>'+
                                                  '<len:consentToCheckCreditHistory>false</len:consentToCheckCreditHistory>'+
                                               '</len:applicant>'+
                                            '</len:additionalApplicants>'+
                                            '<len:paymentDetails>'+
                                               '<len:paymentOption>Cash</len:paymentOption>'+
                                            '</len:paymentDetails>'+
                                         '</len:IndividualCommercialRequest>'+
                                      '</get:getIndividualCreditAssessment>'+
                                   '</soapenv:Body>'+
                                '</soapenv:Envelope>';
            }
            else{
                requestString = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:com="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1" xmlns:get="http://www.auspost.com.au/Service/Party/Customer/getIndividualCreditAssessment:v1" xmlns:len="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending">'+
                                   '<soapenv:Header>'+
                                      '<com:InterfaceHeader>'+
                                         '<com:InterfaceName>getCreditAssessment</com:InterfaceName>'+
                                         '<com:InterfaceVersion>1.0</com:InterfaceVersion>'+
                                         '<com:MessageType>Request</com:MessageType>'+
                                         '<com:BusinessReferenceID>'+system.now()+'</com:BusinessReferenceID>'+
                                         '<com:SourceSystemID>Apttus</com:SourceSystemID>'+
                                         '<com:Timestamp>2019-05-30T12:29:49.038Z</com:Timestamp>'+
                                      '</com:InterfaceHeader>'+
                                   '</soapenv:Header>'+
                                   '<soapenv:Body>'+
                                      '<get:getIndividualCreditAssessment>'+
                                         '<len:IndividualCommercialRequest>'+
                                            '<len:applicationID>'+generateRandomNumber().escapeXML()+'</len:applicationID>'+
                                            '<len:primaryContact>'+
                                               '<len:name>'+(creditAssesment.APT_Applicant_1_First_Name__c).escapeXML()+'</len:name>'+
                                               '<len:email>dummymail@test.com</len:email>'+
                                               '<len:phone>'+
                                                  '<len:areaCode>02</len:areaCode>'+
                                                  '<len:number>12345678</len:number>'+
                                               '</len:phone>'+
                                               '<len:mobile>61412345678</len:mobile>'+
                                               '<len:address>'+
                                                  '<len:streetNumber>'+(creditAssesment.APT_Applicant_1_Street_Number__c).escapeXML()+'</len:streetNumber>'+
                                                  '<len:streetName>'+(creditAssesment.APT_Applicant_1_Street_Name__c).escapeXML()+'</len:streetName>'+
                                                  '<len:suburb>'+(creditAssesment.APT_Applicant_1_Suburb__c).escapeXML()+'</len:suburb>'+
                                                  '<len:state>'+(creditAssesment.APT_Applicant_1_State__c).escapeXML()+'</len:state>'+
                                                  '<len:postcode>'+(creditAssesment.APT_Applicant_1_Postcode__c).escapeXML()+'</len:postcode>'+
                                               '</len:address>'+
                                              '<len:promotionalInformation>false</len:promotionalInformation>'+
                                            '</len:primaryContact>'+
                                            '<len:commercialApplication>'+
                                               '<len:creditAmountRequired>'+String.ValueOf(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c).IntValue()).escapeXML()+'</len:creditAmountRequired>'+
                                               '<len:termDays>D14</len:termDays>'+
                                            '</len:commercialApplication>'+
                                            '<len:businessDetails>'+
                                               '<len:tradingName>'+(creditAssesment.APT_Legal_Entity_Name__c).escapeXML()+'</len:tradingName>'+
                                             '</len:businessDetails>'+
                                            '<len:additionalApplicants>'+
                                               '<len:applicant>'+
                                                  '<len:applicantDetails>'+
                                                     '<len:firstName>'+(creditAssesment.APT_Applicant_1_First_Name__c).escapeXML()+'</len:firstName>'+
                                                     '<len:lastName>'+(creditAssesment.APT_Applicant_1_Last_Name__c).escapeXML()+'</len:lastName>'+
                                                     '<len:dateOfBirth>'+String.ValueOf(creditAssesment.APT_Applicant_1_Date_of_Birth__c).escapeXML()+'</len:dateOfBirth>'+
                                                   '</len:applicantDetails>'+
                                                  '<len:address>'+
                                                     '<len:streetNumber>'+(creditAssesment.APT_Applicant_1_Street_Number__c).escapeXML()+'</len:streetNumber>'+
                                                     '<len:streetName>'+(creditAssesment.APT_Applicant_1_Street_Name__c).escapeXML()+'</len:streetName>'+
                                                     '<len:suburb>'+creditAssesment.APT_Applicant_1_Suburb__c+'</len:suburb>'+
                                                     '<len:state>'+(creditAssesment.APT_Applicant_1_State__c).escapeXML()+'</len:state>'+
                                                     '<len:postcode>'+(creditAssesment.APT_Applicant_1_Postcode__c).escapeXML()+'</len:postcode>'+
                                                  '</len:address>'+
                                                  '<len:contactDetails>'+
                                                     '<len:email>dummymail@test.com</len:email>'+
                                                     '<len:phone>'+
                                                        '<len:areaCode>02</len:areaCode>'+
                                                        '<len:number>12345678</len:number>'+
                                                     '</len:phone>'+
                                                     '<len:mobile>61412345678</len:mobile>'+
                                                  '</len:contactDetails>'+
                                                  '<len:additionalApplicantData>'+
                                                     '<len:name>'+(creditAssesment.APT_Applicant_1_First_Name__c).escapeXML()+'</len:name>'+
                                                     '<len:value>'+(creditAssesment.APT_Applicant_1_Last_Name__c).escapeXML()+'</len:value>'+
                                                  '</len:additionalApplicantData>'+
                                                  '<len:consentToCheckCreditHistory>false</len:consentToCheckCreditHistory>'+
                                               '</len:applicant>'+
                                            '</len:additionalApplicants>'+
                                            '<len:paymentDetails>'+
                                               '<len:paymentOption>Cash</len:paymentOption>'+
                                            '</len:paymentDetails>'+
                                         '</len:IndividualCommercialRequest>'+
                                      '</get:getIndividualCreditAssessment>'+
                                   '</soapenv:Body>'+
                                '</soapenv:Envelope>';
            }
            
           system.debug(' REQUEST STRING'+requestString);
           // Creating the HTTP Request 
           if(String.IsNotBlank(requestString)){
               HttpRequest req = new HttpRequest();
               if(String.IsNotBlank(endpoint)){
                   //Setting Request Endpoint
                   req.setEndpoint(endpoint);
               }
               // Setting Request Header
               req.setHeader('SOAPAction','/Services/ExternalCreditAssessmentServices/getIndividualCreditAssessment_v1');
               // Setting Request Method
               req.setMethod('POST');
               // Setting Request Body
               req.setBody(requestString);
               req.setHeader(APT_WebServiceUtility.AUTHORIZATION , APT_WebServiceUtility.getinputHttpHeaders().get(APT_WebServiceUtility.AUTHORIZATION));
               req.setHeader('Content-Type', 'text/xml');
               // Setting Request Timeout
               req.setTimeout(120000);
               Http http = new Http();
               //Making Call out to TIBCO
               system.debug(' REQUEST STRING'+req.getbody());
               HTTPResponse res = http.send(req); 
               system.debug('---Respone--'+res.getbody());
               Dom.Document doc = res.getBodyDocument();
               Dom.XMLNode rootElement = doc.getRootElement();
               system.debug('---Root Element--'+rootElement);
               //Parsing the Response
               decisionMap =  parseXML(rootElement, decisionMap);
               system.debug('***** DECISION MAP*****'+decisionMap);
               return decisionMap;
           }
           else{
                  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please Validate the ABN/ACN'));
                  return null;
           }
         
       } catch(system.exception e) {
            system.debug('***** Exception Line Number*****'+e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
    
   /**
       This method is used for generate random number 
   **/ 
    public static String generateRandomNumber() {
     try {
        Datetime now = Datetime.now();
        Long timenow = now.getTime();
        String test = String.ValueOf(timenow);
        return test;
     } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }   

    }
     /**
      This method will return org id of particular request.
    **/
    public static boolean ValidateIsExistingABNACN(APT_Charge_Account__c chargeAccountDetail, String accountID) {
       
       try{
            Boolean oldOrgIDRequest = false;
            
            String ABN = chargeAccountDetail.APT_ABN__c;
            String ACN = chargeAccountDetail.APT_ACN__c;
            
            String cust = APT_Constants.Customer;
            
            List<Account> accounts = null; 
              
            String accountQuery =  APT_Constants.account_query;
            
            if(String.isNotBlank(ABN)){
                accountQuery = accountQuery + APT_Constants.STRING_ABN_C;
            }
            
            if(String.isNotBlank(ABN) && String.isNotBlank(ACN)){
                accountQuery = accountQuery + APT_Constants.ADD_WHITESPACE  
                                            + APT_Constants.OPERATOR_OR  + APT_Constants.ADD_WHITESPACE;
            }
            
            if(String.isNotBlank(ACN)){
                accountQuery = accountQuery + APT_Constants.STRING_ACN_C;
            }
            accountQuery  = accountQuery + APT_Constants.ROUND_PARANTHESIS_END;
            
            system.debug('**** Final Query ****'+accountQuery);
            
            accounts = Database.query(accountQuery);
            system.debug('**** Account Size ****'+accounts.size());
            if(accounts != null && accounts.size() == 1 && accounts[0].id == accountID) {
                oldOrgIDRequest = false;
            } else {
                oldOrgIDRequest = (accounts != null) && (accounts.size() > 0);
            }
            return oldOrgIDRequest;
     } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }  
    }

    /**
        This method will copy fields from Charge Account to Credit Assessment.
     */
    public static APT_Credit_Assessment__c updateCreditAssessmentFields(APT_Credit_Assessment__c creditAssessment, APT_Charge_Account__c chargeAccount) {
        try {
            if(chargeAccount.APT_Industry_Type__c != null) {
                creditAssessment.APT_Industry_Type__c = chargeAccount.APT_Industry_Type__c.subString(0, 1);
            }          
            
            creditAssessment.APT_ABN__c = chargeAccount.APT_ABN__c;
            creditAssessment.APT_ACN__c = chargeAccount.APT_ACN__c;
    
            if(chargeAccount.APT_Company_Name__c != null) {
                creditAssessment.APT_Legal_Entity_Name__c = chargeAccount.APT_Company_Name__c;
            } else if(chargeAccount.APT_Business_name__c != null) {
                creditAssessment.APT_Legal_Entity_Name__c = chargeAccount.APT_Business_name__c;            
            } else {}
    
            
            creditAssessment.APT_Term_Days__c = APT_Constants.END_CHARACTER_D + chargeAccount.APT_Term_Days__c;
            creditAssessment.APT_Account_Type__c = APT_Constants.END_CHARACTER_D + chargeAccount.APT_Term_Days__c;
            creditAssessment.APT_Credit_Amount_Required__c = chargeAccount.APT_Credit_Limit_Required__c;
            creditAssessment.APT_Applicant_1_First_Name__c = chargeAccount.APT_First_Name__c;
            creditAssessment.APT_Applicant_1_Last_Name__c = chargeAccount.APT_Last_Name__c;
            creditAssessment.APT_Applicant_1_Date_of_Birth__c = chargeAccount.APT_Applicant1_Date_of_Birth__c;
            
            creditAssessment.APT_Applicant_1_Unit_Number__c = chargeAccount.APT_Applicant1_BA_Unit_Number__c;
            creditAssessment.APT_Applicant_1_Street_Number__c = chargeAccount.APT_Applicant1_BA_Street_Number__c;
            creditAssessment.APT_Applicant_1_Street_Name__c = chargeAccount.APT_Applicant1_BA_Street_Name__c;
            creditAssessment.APT_Applicant_1_Street_Type__c = chargeAccount.APT_Applicant1_BA_Street_Type__c;
            creditAssessment.APT_Applicant_1_Suburb__c = chargeAccount.APT_Applicant1_BA_Suburb__c;
            creditAssessment.APT_Applicant_1_Postcode__c = chargeAccount.APT_Applicant1_BA_Street_Postcode__c;
            creditAssessment.APT_Applicant_1_State__c = chargeAccount.APT_Applicant1_BA_State__c;
            creditAssessment.APT_Applicant_1_Country__c = chargeAccount.APT_Applicant1_BA_Country_Code__c;
    
            creditAssessment.APT_Applicant_1_Credit_Check_Consent__c = chargeAccount.APT_A1_Consent_to_check_credit_history__c;
            
            return creditAssessment;
       } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }             
    }
}