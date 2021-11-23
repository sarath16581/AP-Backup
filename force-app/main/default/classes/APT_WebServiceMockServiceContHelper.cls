/**
Description: 
Created By: Drashtee Shah
Created Date: 24th Feb, 2016
Last Modified By:
Last Modified Date:
*/

global with sharing class APT_WebServiceMockServiceContHelper implements WebServiceMock {
    /*
    global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
               
               
                // first argument
                APT_CA_IndividualCreditAssessment.Req_CommercialApplication first_argument = new APT_CA_IndividualCreditAssessment.Req_CommercialApplication();
                    // sub 1
                    
                    APT_CA_IndividualCreditAssessment.Req_CommercialApplication sub1 = new APT_CA_IndividualCreditAssessment.Req_CommercialApplication();
                    sub1.creditAmountRequired = '100';
                    sub1.termDays = '30';
                    sub1.businessHistoryAge = 20;
                    
                    
                    //sub2
                    APT_CA_IndividualCreditAssessment.Req_AdditionalApplicants sub2 = new APT_CA_IndividualCreditAssessment.Req_AdditionalApplicants();
                    
                        // sub sub List
                        List<APT_CA_IndividualCreditAssessment.Req_AdditionalApplicant> sub_subList = new List<APT_CA_IndividualCreditAssessment.Req_AdditionalApplicant>();
                        //sub sub1
                        APT_CA_IndividualCreditAssessment.Req_AdditionalApplicant sub_sub1 = new APT_CA_IndividualCreditAssessment.Req_AdditionalApplicant();
                        
                            // sub sub sub1
                            APT_CA_IndividualCreditAssessment.Req_ApplicantDetails sub_sub_sub1 = new APT_CA_IndividualCreditAssessment.Req_ApplicantDetails();
                            sub_sub_sub1.firstName = 'asdas';
                            sub_sub_sub1.middleName = 'asdas';
                            sub_sub_sub1.lastName = 'asdas';
                            sub_sub_sub1.dateOfBirth = System.Today() - 100;
                            sub_sub_sub1.driversLicence = 'asdas';
                            sub_sub_sub1.existingCustomerFlag = true;
                            sub_sub_sub1.AustraliaPostArrears = 100;
                            sub_sub_sub1.customerPerformance = 100;
                            
                            //sub sub sub2
                            List<APT_CA_IndividualCreditAssessment.Req_Address> sub_sub_sub3 = new List<APT_CA_IndividualCreditAssessment.Req_Address>();
                            APT_CA_IndividualCreditAssessment.Req_Address sub_sub_sub2 = new APT_CA_IndividualCreditAssessment.Req_Address();
                            sub_sub_sub2.property = 'asdas';
                            sub_sub_sub2.unitNumber = 'asdas';
                            sub_sub_sub2.streetNumber = 'asdas';
                            sub_sub_sub2.streetName = 'asdas';
                            sub_sub_sub2.streetType = 'asdas';
                            sub_sub_sub2.suburb = 'asdas';
                            sub_sub_sub2.postcode = 'asdas';
                            sub_sub_sub2.state = 'asdas';
                            sub_sub_sub2.countryCode = 'asdas';
                            
                            sub_sub_sub3.add(sub_sub_sub2);
                        sub_sub1.Consent_to_check_credit_history = true;
                        sub_sub1.applicantDetails = sub_sub_sub1;
                        sub_sub1.CurrentAddress = sub_sub_sub2;
                        sub_sub1.PreviousAddress = sub_sub_sub3;
                        sub_subList.add(sub_sub1);
                    sub2.applicant = sub_subList;
                //second argument
                APT_CA_IndividualCreditAssessment.Req_AdditionalApplicants second_argument = new APT_CA_IndividualCreditAssessment.Req_AdditionalApplicants();
                
                // Main Response
                APT_CA_IndividualCreditAssessment.IndividualCommercialRequest testresponse1 = new APT_CA_IndividualCreditAssessment.IndividualCommercialRequest();
                testresponse1.AP_UniqueID = 'm00O00000008OJS';
                testresponse1.commercialApplication = first_argument;
                testresponse1.additionalApplicants = second_argument;
                
                response.put('response_x', testresponse1);
        
        }
        
        */
    
    /**
        Invoke method
    */    
    global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
               
               
               //argument for result1
               List<APT_CA_CompanyCreditAssessment.Reason> reason1 = new List<APT_CA_CompanyCreditAssessment.Reason>();
               APT_CA_CompanyCreditAssessment.Reason reason = new APT_CA_CompanyCreditAssessment.Reason();
               reason.reasonCode = APT_Constants.TEMP_STRING;
               reason.description = APT_Constants.TEMP_STRING;
               reason.rule = APT_Constants.TEMP_STRING;
               
               reason1.add(reason);
               
               //argument1 for ror
               APT_CA_CompanyCreditAssessment.Res_OrganisationDetails rod = new APT_CA_CompanyCreditAssessment.Res_OrganisationDetails();
               rod.name = APT_Constants.TEMP_STRING;
               rod.entityType = APT_Constants.STRING_PRV;
               rod.industryType = APT_Constants.STRING_PRV;
               rod.australianCompanyNumber = APT_Constants.STRING_009610342;
               rod.ExistingCustomerFlag = true;
               rod.australiaPostArrears = 0820;
               rod.CustomerPerformance = 100;
               
               //argument2 for ror
               APT_CA_CompanyCreditAssessment.Result result1 = new APT_CA_CompanyCreditAssessment.Result();
               result1.decisionCode = APT_Constants.TEMP_STRING;
               result1.reasons = reason1;
               
               // argument1 for cca
               APT_CA_CompanyCreditAssessment.Rsp_CompanyBusiness_CommercialApplication rcca = new APT_CA_CompanyCreditAssessment.Rsp_CompanyBusiness_CommercialApplication();
               rcca.creditAmountRequired = APT_Constants.STRING_100;
               rcca.termDays = APT_Constants.CONSTANT_VEDA_TERM_DAYS;
               
               //argument2 for cca
               APT_CA_CompanyCreditAssessment.Rsp_OrganisationResponse ror = new APT_CA_CompanyCreditAssessment.Rsp_OrganisationResponse();
               ror.organisationDetails = rod;
               ror.organisationDecision = result1;
               
               // argument for cbr
               APT_CA_CompanyCreditAssessment.Rsp_Results cca = new APT_CA_CompanyCreditAssessment.Rsp_Results();
               cca.commercialApplication = rcca;
               cca.organisationResults = ror;
               
               // only argument to main response
               APT_CA_CompanyCreditAssessment.Rsp_CompanyBusinessResponse cbr = new APT_CA_CompanyCreditAssessment.Rsp_CompanyBusinessResponse();
               cbr.companyBusinessDecision = APT_Constants.TEMP_STRING;
               cbr.status = APT_Constants.TEMP_STRING;
               cbr.creditLimit = 10;
               cbr.response = cca;
               
               // main response
               APT_CA_CompanyCreditAssessment.getCompanyCreditAssessmentResponseType mainResponse = new APT_CA_CompanyCreditAssessment.getCompanyCreditAssessmentResponseType();
               mainResponse.Rsp_CompanyBusinessResponse = cbr;
               
            response.put(APT_Constants.STRING_RESPONSE_MOCK, mainResponse);
           }

}