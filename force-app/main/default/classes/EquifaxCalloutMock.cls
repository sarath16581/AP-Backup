@isTest
public class EquifaxCalloutMock {
    
    public static String getCompanyResponse() {
        return '<?xml version="1.0" encoding="UTF-8"?>'+
                '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+
                    '<SOAP-ENV:Header>'+
                        '<ns0:InterfaceHeader xmlns:ns0="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1">'+
                            '<ns0:InterfaceName>getCompanyCreditAsse</ns0:InterfaceName>'+
                            '<ns0:InterfaceVersion>1.0</ns0:InterfaceVersion>'+
                            '<ns0:MessageType>Reply</ns0:MessageType>'+
                            '<ns0:BusinessReferenceID>2021-04-16 10:53:28</ns0:BusinessReferenceID>'+
                            '<ns0:SourceSystemID>Veda</ns0:SourceSystemID>'+
                            '<ns0:SourceInformation/>'+
                            '<ns0:Timestamp>2021-04-16T20:53:29.408+10:00</ns0:Timestamp>'+
                        '</ns0:InterfaceHeader>'+
                    '</SOAP-ENV:Header>'+
                    '<SOAP-ENV:Body>'+
                        '<ns0:getCompanyCreditAssessmentResponse xmlns:jms1="http://www.tibco.com/namespaces/tnt/plugins/jms" xmlns:ns0="http://www.auspost.com.au/Service/Party/Customer/getCompanyCreditAssessment:v1" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+
                            '<ns1:Rsp_CompanyBusinessResponse xmlns:ns1="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
                                '<ns1:companyBusinessDecision>PRE_REFER</ns1:companyBusinessDecision>'+
                               '<ns1:status>PENDING_PRELIMINARY_ASSESSMENT</ns1:status>'+
                                '<ns1:response>'+
                                    '<ns1:primaryContact>'+
                                        '<ns1:name>Test Name</ns1:name>'+
                                        '<ns1:phone>12345678</ns1:phone>'+
                                        '<ns1:email>dummymail@test.com</ns1:email>'+
                                    '</ns1:primaryContact>'+
                                    '<ns1:commercialApplication>'+
                                        '<ns1:creditAmountRequired>69200</ns1:creditAmountRequired>'+
                                        '<ns1:termDays>14</ns1:termDays>'+
                                    '</ns1:commercialApplication>'+
                                    '<ns1:organisationResults>'+
                                        '<ns1:organisationDetails>'+
                                            '<ns1:name>WHITE CITY PTY LTD</ns1:name>'+
                                            '<ns1:entityType>Company</ns1:entityType>'+
                                            '<ns1:entitySubtype>INC</ns1:entitySubtype>'+
                                            '<ns1:australianCompanyNumber>061621832</ns1:australianCompanyNumber>'+
                                            '<ns1:australianBusinessNumber>31061621832</ns1:australianBusinessNumber>'+
                                            '<ns1:state>VIC</ns1:state>'+
                                        '</ns1:organisationDetails>'+
                                        '<ns1:organisationDecision>'+
                                            '<ns2:decisionCode xmlns:ns2="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending/CompanyBusinessDecision">PRE_REFER</ns2:decisionCode>'+
                                            '<ns2:reasons xmlns:ns2="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending/CompanyBusinessDecision">'+
                                                '<ns2:reasonCode>PR_2</ns2:reasonCode>'+
                                               '<ns2:description>Loan amount not acceptable</ns2:description>'+
                                                '<ns2:rule>LoanAmountRefer</ns2:rule>'+
                                            '</ns2:reasons>'+
                                        '</ns1:organisationDecision>'+
                                    '</ns1:organisationResults>'+
                                    '<ns1:esisResponse>'+
                                        '<ns1:registrationNumberDetails/>'+
                                    '</ns1:esisResponse>'+
                                '</ns1:response>'+
                            '</ns1:Rsp_CompanyBusinessResponse>'+
                        '</ns0:getCompanyCreditAssessmentResponse>'+
                    '</SOAP-ENV:Body>'+
                '</SOAP-ENV:Envelope>';
    }
    
    public static string getIndividualResponse(){
        return '<?xml version="1.0" encoding="UTF-8"?>'+
                '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+
                    '<SOAP-ENV:Header>'+
                       '<ns0:InterfaceHeader xmlns:ns0="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1">'+
                            '<ns0:InterfaceName>getIndividualCreditA</ns0:InterfaceName>'+
                            '<ns0:InterfaceVersion>1.0</ns0:InterfaceVersion>'+
                            '<ns0:MessageType>Reply</ns0:MessageType>'+
                            '<ns0:BusinessReferenceID>2021-04-16 11:12:34</ns0:BusinessReferenceID>'+
                            '<ns0:SourceSystemID>Veda</ns0:SourceSystemID>'+
                            '<ns0:SourceInformation/>'+
                            '<ns0:Timestamp>2021-04-16T21:12:36.094+10:00</ns0:Timestamp>'+
                        '</ns0:InterfaceHeader>'+
                    '</SOAP-ENV:Header>'+
                    '<SOAP-ENV:Body>'+
                        '<ns0:getIndividualCreditAssessmentResponse xmlns:jms1="http://www.tibco.com/namespaces/tnt/plugins/jms" xmlns:ns0="http://www.auspost.com.au/Service/Party/Customer/getIndividualCreditAssessment:v1" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+
                            '<ns1:Rsp_IndividualCommercialResponse xmlns:ns1="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending">'+
                                '<ns1:status>PENDING_FINAL_ASSESSMENT</ns1:status>'+
                                '<ns1:applicationDecision>REFER</ns1:applicationDecision>'+
                                '<ns1:response>'+
                                    '<ns1:primaryContact>'+
                                        '<ns1:name>Jansi</ns1:name>'+
                                        '<ns1:phone>12345678</ns1:phone>'+
                                        '<ns1:email>dummymail@test.com</ns1:email>'+
                                        '<ns1:ABN>80112125659</ns1:ABN>'+
                                    '</ns1:primaryContact>'+
                                    '<ns1:additionalApplicantResults>'+
                                        '<ns1:applicantDetails>'+
                                            '<ns1:firstName>Test</ns1:firstName>'+
                                            '<ns1:lastName>AA</ns1:lastName>'+
                                            '<ns1:dateOfBirth>2000-04-27Z</ns1:dateOfBirth>'+
                                        '</ns1:applicantDetails>'+
                                        '<ns1:additionalApplicantDecision>'+
                                            '<ns2:decisionCode xmlns:ns2="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending/IndividualCommercialDecision">REFER</ns2:decisionCode>'+
                                            '<ns2:reasons xmlns:ns2="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending/IndividualCommercialDecision">'+
                                                '<ns2:reasonCode>R_1</ns2:reasonCode>'+
                                                '<ns2:description>Bureau credit file was recently created</ns2:description>'+
                                                '<ns2:rule>AgeBureauFileRefer</ns2:rule>'+
                                            '</ns2:reasons>'+
                                        '</ns1:additionalApplicantDecision>'+
                                    '</ns1:additionalApplicantResults>'+
                                    '<ns1:commercialApplication>'+
                                        '<ns1:creditAmountRequired>60000</ns1:creditAmountRequired>'+
                                        '<ns1:termDays>14</ns1:termDays>'+
                                    '</ns1:commercialApplication>'+
                                    '<ns1:esisResponse>'+
                                        '<ns1:registrationNumberDetails/>'+
                                        '<ns1:securedPartyGroupNo/>'+
                                        '<ns1:categoryCode/>'+
                                        '<ns1:categoryCodeDescription/>'+
                                        '<ns1:goni/>'+
                                        '<ns1:contractTypeCode/>'+
                                    '</ns1:esisResponse>'+
                                '</ns1:response>'+
                            '</ns1:Rsp_IndividualCommercialResponse>'+
                        '</ns0:getIndividualCreditAssessmentResponse>'+
                    '</SOAP-ENV:Body>'+
                '</SOAP-ENV:Envelope>';
    }

}