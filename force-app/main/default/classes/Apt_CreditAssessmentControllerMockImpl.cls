/*------------------------------------------------------------
Author:   :      Shashwat Nath
Date Created:    15/06/2019
Description:     Mock Class For Response


History
<Date>           <Authors Name>    <Brief Description of Change>
06/09/2019      Shashwat Nath      Created
------------------------------------------------------------*/
@isTest
global class Apt_CreditAssessmentControllerMockImpl implements HttpCalloutMock {
    // Implement this interface method
    
    public String type;
    public String assessmentType;
    global Apt_CreditAssessmentControllerMockImpl(final String type, final string assessmentType){
         this.type = type;
         this.assessmentType = assessmentType;
    }
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'text/xml');
        // Company Response
        if(assessmentType=='Company'){
            String reponseb = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">'+
                '<SOAP-ENV:Header>'+
                    '<ns0:InterfaceHeader xmlns:ns0=\"http://www.auspost.com.au/Schema/CommonDataModel/Common:v1\">'+
                        '<ns0:InterfaceName>getCompanyCreditAsse</ns0:InterfaceName>'+
                        '<ns0:InterfaceVersion>1.0</ns0:InterfaceVersion>'+
                        '<ns0:MessageType>Reply</ns0:MessageType>'+
                        '<ns0:BusinessReferenceID>2019-06-15 10:30:44</ns0:BusinessReferenceID>'+
                        '<ns0:SourceSystemID>Veda</ns0:SourceSystemID>'+
                        '<ns0:SourceInformation/>'+
                        '<ns0:Timestamp>2019-06-15T20:30:57.777+10:00</ns0:Timestamp>'+
                    '</ns0:InterfaceHeader>'+
                '</SOAP-ENV:Header>'+
                '<SOAP-ENV:Body>'+
                    '<ns0:getCompanyCreditAssessmentResponse xmlns:jms1=\"http://www.tibco.com/namespaces/tnt/plugins/jms\" xmlns:ns0=\"http://www.auspost.com.au/Service/Party/Customer/getCompanyCreditAssessment:v1\" xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">'+
                        '<ns1:Rsp_CompanyBusinessResponse xmlns:ns1=\"http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending\">';
                            
                            If(type=='APPROVE'){
                                reponseb = reponseb + '<ns1:companyBusinessDecision>APPROVE</ns1:companyBusinessDecision>' ;
                            }
                            else If(type=='PRE_REFER'){
                                reponseb = reponseb + '<ns1:companyBusinessDecision>PRE_REFER</ns1:companyBusinessDecision>';
                            }
                            else If(type=='PRE_DECLINE'){
                                reponseb = reponseb + '<ns1:companyBusinessDecision>PRE_DECLINE</ns1:companyBusinessDecision>';
                            }
                            
                            reponseb = reponseb + '<ns1:status>Completed</ns1:status>'+
                            '<ns1:response>'+
                                '<ns1:primaryContact>'+
                                    '<ns1:name>shashwat</ns1:name>'+
                                    '<ns1:phone>48463512</ns1:phone>'+
                                    '<ns1:email>dummymail@test.com</ns1:email>'+
                                '</ns1:primaryContact>'+
                                '<ns1:commercialApplication>'+
                                    '<ns1:creditAmountRequired>15000</ns1:creditAmountRequired>'+
                                    '<ns1:termDays>14</ns1:termDays>'+
                                '</ns1:commercialApplication>'+
                                '<ns1:organisationResults>'+
                                    '<ns1:organisationDetails>'+
                                        '<ns1:name>A.J. CARTER &amp; SONS PTY. LIMITED</ns1:name>'+
                                        '<ns1:entityType>Company</ns1:entityType>'+
                                        '<ns1:entitySubtype>INC</ns1:entitySubtype>'+
                                        '<ns1:australianCompanyNumber>008565624</ns1:australianCompanyNumber>'+
                                        '<ns1:australianBusinessNumber>23008565624</ns1:australianBusinessNumber>'+
                                        '<ns1:state>VIC</ns1:state>'+
                                    '</ns1:organisationDetails>'+
                                    '<ns1:organisationDecision>'+
                                        '<ns2:decisionCode xmlns:ns2=\"http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending/CompanyBusinessDecision\">APPROVE</ns2:decisionCode>'+
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
            res.setbody(reponseb);
        }
        // Individual Response
        else if(assessmentType=='Individual'){
            string reponseb = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">'+
                '<SOAP-ENV:Header>'+
                    '<ns0:InterfaceHeader xmlns:ns0=\"http://www.auspost.com.au/Schema/CommonDataModel/Common:v1\">'+
                        '<ns0:InterfaceName>getIndividualCreditA</ns0:InterfaceName>'+
                        '<ns0:InterfaceVersion>1.0</ns0:InterfaceVersion>'+
                        '<ns0:MessageType>Reply</ns0:MessageType>'+
                        '<ns0:BusinessReferenceID>2019-06-16 06:10:52</ns0:BusinessReferenceID>'+
                        '<ns0:SourceSystemID>Veda</ns0:SourceSystemID>'+
                        '<ns0:SourceInformation/>'+
                        '<ns0:Timestamp>2019-06-16T16:10:53.996+10:00</ns0:Timestamp>'+
                    '</ns0:InterfaceHeader>'+
                '</SOAP-ENV:Header>'+
                '<SOAP-ENV:Body>'+
                    '<ns0:getIndividualCreditAssessmentResponse xmlns:jms1=\"http://www.tibco.com/namespaces/tnt/plugins/jms\" xmlns:ns0=\"http://www.auspost.com.au/Service/Party/Customer/getIndividualCreditAssessment:v1\" xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">'+
                        '<ns1:Rsp_IndividualCommercialResponse xmlns:ns1=\"http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending\">'+
                            '<ns1:status>Completed</ns1:status>';
                            If(type=='APPROVE'){
                                reponseb = reponseb+'<ns1:applicationDecision>APPROVE</ns1:applicationDecision>';
                            }
                            else If(type=='PRE_REFER'){
                                reponseb = reponseb+'<ns1:applicationDecision>PRE_REFER</ns1:applicationDecision>';
                            }
                            else If(type=='PRE_DECLINE'){
                                reponseb = reponseb+'<ns1:applicationDecision>PRE_DECLINE</ns1:applicationDecision>';
                            }
                            reponseb = reponseb+'<ns1:response>'+
                                '<ns1:primaryContact>'+
                                    '<ns1:name>Shashwat</ns1:name>'+
                                    '<ns1:phone>48463512</ns1:phone>'+
                                    '<ns1:email>dummymail@test.com</ns1:email>'+
                                    '<ns1:ABN>78770630806</ns1:ABN>'+
                                '</ns1:primaryContact>'+
                                '<ns1:additionalApplicantResults>'+
                                    '<ns1:applicantDetails>'+
                                        '<ns1:firstName>Shashwat</ns1:firstName>'+
                                        '<ns1:lastName>Nath</ns1:lastName>'+
                                        '<ns1:dateOfBirth>2019-06-17Z</ns1:dateOfBirth>'+
                                    '</ns1:applicantDetails>'+
                                    '<ns1:additionalApplicantDecision>'+
                                        '<ns2:decisionCode xmlns:ns2=\"http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending/IndividualCommercialDecision\">PRE_DECLINE</ns2:decisionCode>'+
                                        '<ns2:reasons xmlns:ns2=\"http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending/IndividualCommercialDecision\">'+
                                            '<ns2:reasonCode>PD_35</ns2:reasonCode>'+
                                            '<ns2:description>Age of Individual is unacceptable</ns2:description>'+
                                            '<ns2:rule>AgeOfApplicantDecline</ns2:rule>'+
                                        '</ns2:reasons>'+
                                    '</ns1:additionalApplicantDecision>'+
                                '</ns1:additionalApplicantResults>'+
                                '<ns1:commercialApplication>'+
                                    '<ns1:creditAmountRequired>50000</ns1:creditAmountRequired>'+
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
            res.setbody(reponseb);
        }
        // Exception Response
        else if(assessmentType=='Exception'){
             string reponseb = '<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">'+
                   '<SOAP-ENV:Body>'+
                      '<SOAP-ENV:Fault>'+
                         '<faultcode>Server</faultcode>'+
                         '<faultstring>This is an operation implementation generated fault</faultstring>'+
                         '<detail>'+
                            '<ns0:SOAPException xmlns:ns0=\"http://www.auspost.com.au/Schema/CommonDataModel/Common:v1\">'+
                               '<ns0:InterfaceHeader>'+
                                  '<ns0:InterfaceName>getCompanyCreditAsse</ns0:InterfaceName>'+
                                  '<ns0:InterfaceVersion/>'+
                                  '<ns0:MessageType>Reply</ns0:MessageType>'+
                                  '<ns0:BusinessReferenceID>Unknown</ns0:BusinessReferenceID>'+
                                  '<ns0:SourceSystemID>N/A</ns0:SourceSystemID>'+
                                  '<ns0:Timestamp>2019-06-12T19:44:28.316+10:00</ns0:Timestamp>'+
                               '</ns0:InterfaceHeader>'+
                               '<ns0:Exception>'+
                                  '<ns0:ExceptionCategory>SystemException</ns0:ExceptionCategory>'+
                                  '<ns0:ExceptionType>SystemTerminal</ns0:ExceptionType>'+
                                  '<ns0:ExceptionCode>WS-9000</ns0:ExceptionCode>'+
                                  '<ns0:ExceptionDescription>The request message could not be parsed.</ns0:ExceptionDescription>'+
                               '</ns0:Exception>'+
                            '</ns0:SOAPException>'+
                         '</detail>'+
                      '</SOAP-ENV:Fault>'+
                   '</SOAP-ENV:Body>'+
                '</SOAP-ENV:Envelope>';
                res.setbody(reponseb);
        }
        res.setStatusCode(200);
        return res;
    }
}