/**
 Description: This Wrapper class is used to parse response 
 from Company Credit Assessment web service to APEX class.
 Most of the properties names are same as Schema party service
 we need this class to show results on VF page.
 Created By: Mausam Padhiyar
 Created Date: 24th Nov, 2015
**/
public with sharing class APT_CompanyCreditAssessmentWrapper {
    /**
        Class used for creating variables
    */
    public with sharing class companyBusinessResponse_element {
        public String companyBusinessDecision {get; set;}
        public String status {get; set;}
        public Decimal creditLimit {get; set;}

        public APT_CompanyCreditAssessmentWrapper.responseResult_element response {get; set;}
        public list<APT_CompanyCreditAssessmentWrapper.error_element> listErrors {get; set;}
    }
    /**
        Class used for creating variables
    */
    public with sharing class responseResult_element {
        public APT_CompanyCreditAssessmentWrapper.companyBusinessCommercialApplication_element commercialApplication {get; set;}
        public APT_CompanyCreditAssessmentWrapper.organisationResponse_element organisationResults {get; set;}
    }
    /**
        Class used for creating variables
    */
    public with sharing class companyBusinessCommercialApplication_element {
        public String creditAmountRequired {get; set;}
        public String termDays {get; set;}
    }
    /**
        Class used for creating variables
    */
    public with sharing class organisationResponse_element {
        public APT_CompanyCreditAssessmentWrapper.organisationDetails organisationDetails {get; set;}
        public APT_CompanyCreditAssessmentWrapper.result_element organisationDecision {get; set;}
    }
    /**
        Class used for creating variables
    */
    public with sharing class organisationDetails {
        public String name {get; set;}
        public String entityType {get; set;}
        public String industryType {get; set;}
        public String australianCompanyNumber {get; set;}
        public Boolean ExistingCustomerFlag {get; set;}
        public Integer australiaPostArrears {get; set;}
        public Integer CustomerPerformance {get; set;}
    }
    /**
        Class used for creating variables
    */
    public with sharing class result_element {
        public String decisionCode {get; set;}
        public list<APT_CompanyCreditAssessmentWrapper.reason> listReasons {get; set;}
    }
    /**
        Class used for creating variables
    */
    public with sharing class reason {
        public String reasonCode {get; set;}
        public String description {get; set;}
        public String rule {get; set;}
    }
    /**
        Class used for creating variables
    */
    public with sharing class error_element {
        public String code {get; set;}
        public String type_x {get; set;}
        public String description {get; set;}
    }
}