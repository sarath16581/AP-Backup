/**
* Description: This Wrapper class is used to parse response 
* from Individual Credit Assessment web service to APEX class.
* Most of the properties names are same as Schema party service
* we need this class to show results on VF page.
* Created By: Mausam Padhiyar
* Created Date: 24th Nov, 2015
**/
public with sharing class APT_IndividualCreditAssessmentWrapper {
    /**
        This class is used for set variables
    **/
    public with sharing class individualCommercialResponse_element {
        public String individualDecision {get; set;}
        public String status {get; set;}
        public Decimal creditLimit {get; set;}

        public APT_IndividualCreditAssessmentWrapper.individualCommercialResults_element response {get; set;}
        public list<APT_IndividualCreditAssessmentWrapper.error_element> listErrorDetails {get; set;}
    }
    /**
        This class is used for set variables
    **/
    public with sharing class individualCommercialResults_element {
        public list<APT_IndividualCreditAssessmentWrapper.individualApplicants_element> listAdditionalApplicantResults {get; set;}
        public APT_IndividualCreditAssessmentWrapper.commercialApplication commercialApplication {get; set;}
    }
    /**
        This class is used for set variables
    **/
    public with sharing class individualApplicants_element {
        public APT_IndividualCreditAssessmentWrapper.applicantDetails applicantDetails {get; set;}
        public APT_IndividualCreditAssessmentWrapper.result_element additionalApplicantDecision {get; set;}
    }
    /**
        This class is used for set variables
    **/
    public with sharing class applicantDetails {
        public String firstName {get; set;}
        public String middleName {get; set;}
        public String lastName {get; set;}
        public Date dateOfBirth {get; set;}
        public String driversLicence {get; set;}
    }
    /**
        This class is used for set variables
    **/
    public with sharing class result_element {
        public String decisionCode {get; set;}
        public list<APT_IndividualCreditAssessmentWrapper.Reason> listReasons {get; set;}
    }
    /**
        This class is used for set variables
    **/
    public with sharing class Reason {
        public String reasonCode {get; set;}
        public String description {get; set;}
        public String rule {get; set;}
    }
    /**
        This class is used for set variables
    **/
    public with sharing class commercialApplication {
        public String creditAmountRequired {get; set;}
        public String termDays {get; set;}
        public Integer businessHistoryAge {get; set;}
    }
    /**
        This class is used for set variables
    **/
    public with sharing class error_element { 
        public String code {get; set;}
        public String type_x {get; set;}
        public String description {get; set;}
    }
}