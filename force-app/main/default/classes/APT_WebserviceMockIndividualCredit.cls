/**

Created By: Aakash Khatri 
Created Date: 5th Apr, 2016
Last Modified By:
Last Modified Date:
*/
global with sharing class APT_WebserviceMockIndividualCredit implements WebServiceMock {
    /**
        Invoke Method
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
               
               APT_CA_IndividualCreditAssessment.Result result1 = new APT_CA_IndividualCreditAssessment.Result();
               result1.decisionCode = APT_Constants.RANDOM_STRING;
               result1.reasons = null;
               
               List<APT_CA_IndividualCreditAssessment.Rsp_IndividualApplicants> additionalApplicantResultsList = new List<APT_CA_IndividualCreditAssessment.Rsp_IndividualApplicants>();
               APT_CA_IndividualCreditAssessment.Rsp_IndividualApplicants additionalApplicantResults = new APT_CA_IndividualCreditAssessment.Rsp_IndividualApplicants();
               additionalApplicantResults.applicantDetails = null;
               additionalApplicantResults.additionalApplicantDecision = result1;
               
               additionalApplicantResultsList.add(additionalApplicantResults);
               
               APT_CA_IndividualCreditAssessment.Rsp_CommercialApplication commercialApplication = new APT_CA_IndividualCreditAssessment.Rsp_CommercialApplication();
               commercialApplication.creditAmountRequired = APT_Constants.RANDOM_STRING;
               commercialApplication.termDays = APT_Constants.RANDOM_STRING;
               commercialApplication.businessHistoryAge = 10;
               
               APT_CA_IndividualCreditAssessment.Rsp_IndividualCommercialResults response1 = new APT_CA_IndividualCreditAssessment.Rsp_IndividualCommercialResults();
               response1.additionalApplicantResults = additionalApplicantResultsList ;
               response1.commercialApplication = commercialApplication;
               
               APT_CA_IndividualCreditAssessment.Rsp_IndividualCommercialResponse icr = new APT_CA_IndividualCreditAssessment.Rsp_IndividualCommercialResponse();
               icr.individualDecision = APT_Constants.RANDOM_STRING;
               icr.status = APT_Constants.RANDOM_STRING;
               icr.creditLimit = 1;
               icr.response = response1;
               //icr.errorDetails = null;
               
               // main response
               APT_CA_IndividualCreditAssessment.getIndividualCreditAssessmentResponseType mainResponse = new APT_CA_IndividualCreditAssessment.getIndividualCreditAssessmentResponseType();
               mainResponse.Rsp_IndividualCommercialResponse = icr;
               
            response.put(APT_Constants.STRING_RESPONSE_MOCK, mainResponse);
           }
}