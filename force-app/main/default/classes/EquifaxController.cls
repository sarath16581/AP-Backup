/**
* @description       : EquifaxController for equifax related checks
* @author            : avula.jansirani@auspost.com.au
* @group             : 
* @last modified on  : 05-20-2021
* @last modified by  : ankur.gandhi@auspost.com.au
* Modifications Log 
* Ver   Date         Author                               Modification
* -------------------------------------------------------------------------
* 1.0   30-03-2021  avula.jansirani@auspost.com.au   Initial Version 
**/

public class EquifaxController {
    
    //-- Sole Trdaer Wrapper
    public class SoleTraderRequest{
        public Header reqHeader;
        public SoleTraderRequestBody reqBody;
    }
    
    //-- Company Wrapper
    public class CompanyRequest{
        public Header reqHeader;
        public CompanyRequestBody reqBody;
    }    
    
    //--Request Header wrapper
    public class Header{
        private String interfaceName{get;set;}
        private String interfaceVersion{get;set;}
        private String messageType{get;set;}
        private Datetime businessReferenceID{get;set;}
        private String sourceSystemID{get;set;}
        private String timestamp{get;set;}
        
        public Header(String intName, String iVer, String msgType, Datetime refId, String sourceSysId, String timeStampStr){
            this.interfaceName = intName;
            this.interfaceVersion = iVer;
            this.messageType = msgType;
            this.businessReferenceID = refId;
            this.sourceSystemID = sourceSysId;
            this.timestamp = timeStampStr;
        }
        
        public Header(){
            this.interfaceName = 'getCreditAssessment';
            this.interfaceVersion = '1.0';
            this.messageType = 'Request' ;
            this.businessReferenceID = system.now();
            this.sourceSystemID = 'BCA';               
            this.timestamp = '2019-05-30T12:29:49.038Z';
        }
    }
    
    //--Request Body 'Primary contact info'
    public class PrimaryContactInfo{
        private String name{get;set;}       //[Required]: //Length Min =1, Max=128
        private String  email{get;set;}      //[Required]:Should be a Valid Email Address
        private String phoneAreaCode{get;set;}   //[Required]: Phone-area-code must be 02, 03, 07 or 08.
        public String phoneNumber{get;set;}      //[Required]: length = 	8
        private String mobile{get;set;}          //[Optional]: Mobile Number (eg: 61412345678 or 0412345678 or +61412345678)
        private Address address{get;set;}
        private Boolean promotionInfo{get;set;}  //[Optional]: Boolean
        
        PrimaryContactInfo(String nameStr, Address addressObj){
            this.name = !String.isEmpty(nameStr) ? replaceStr(nameStr, '', ONE_TWENTY_EIGHT) : '';  
            this.email = 'dummymail@test.com';
            this.phoneAreaCode = '02';
            this.phoneNumber = '12345678';
            this.mobile ='61412345678';
            this.address = addressObj;
            this.promotionInfo = false;
        }
        //-- BUILD Other constructors if want to pass all field values
    }
    
    //--Request Body 'Additional Applicant'
    public class AdditionalApplicantInfo{
        private String firstName{get;set;}  //[Required: Alphabetic characters, blanks, apostrophes and hyphens permitted. The first character must be alphabetic. Minimum Length: 1 Maximum Length: 15]
        private String  lastName{get;set;} //Alphabetic characters, blanks, apostrophes and hyphens permitted. Minimum length is 2 characters unless the only character is O. The first character must be alphabetic. Minimum Length: 2 (Except O) Maximum Length: 25
        private String dob{get;set;}          //DD/MM/YYYY as per confluence page, but I think it is yyyy-mm-dd, @Ankur, please confirm.
        private Address address{get;set;}
        private String email{get;set;}
        private String phoneAreaCode{get;set;}
        private String phoneNumber{get;set;}
        private String mobile{get;set;}
        
        public AdditionalApplicantInfo(String fname, String lName, String dateOfBirth, String stNum, String stName, String subrub, String state, String pincode){
            this.firstName = !String.isEmpty(fname) ? replaceStr(fname, ALPHABET_BLANK_HYPHEN_APOSTROPHE, FIFTEEN): '';   
            this.lastName = !String.isEmpty(lName) ? replaceStr(lName, ALPHABET_BLANK_HYPHEN_APOSTROPHE, TWENTY_FIVE): '';
            this.dob = dateOfBirth.escapeXML();      // make sure to pass with yyyy-mm-dd
            this.address = new Address(stNum, stName, subrub, state, pincode);
            this.email = 'dummymail@test.com';
            this.phoneAreaCode = '02';
            this.phoneNumber = '12345678';
            this.mobile = '61412345678';
        }
        
    }
    
    //--Address wrapper
    Public class Address{
        private String streetNumber{get;set;} //[Optional]: First character must be numeric followed by upto 7 alphanumeric characters Minimum length : 1 Maximum length : 8
        private String streetName{get;set;} //[Optional]:May contain alphanumeric characters and blanks only. Minimum length: 1 Maximum length: 25
        private String subrub{get;set;} //[Required]:May contain alphabetic characters, spaces and hyphens only. Maximum length 22 characters.
        private String state{get;set;}  //[Required]:Enumeration:ACT, NSW, NT, QLD, SA, TAS, VIC, WA
        private String postCode{get;set;}  //[Required]:Numeric Length : 4
        
        public Address(String stNum, String stName, String city, String stateStr, String postCodeStr){
            this.streetNumber = !String.isEmpty(stNum) ? stNum.escapeXML() : '' ; 
            this.streetName = !String.isEmpty(stName) ? replaceStr(stName, ALPHA_NUMERIC_AND_SPACE, TWENTY_FIVE) : '' ; 
            this.subrub = !String.isEmpty(city) ? replaceStr(city, ALPHA_NUMERIC_SPACE_HYPHEN, TWENTY_TWO) : '' ;
            this.state = !String.isEmpty(stateStr) ? stateStr.escapeXML() : '' ;
            this.postCode = !String.isEmpty(postCodeStr) ? postCodeStr.escapeXML() : '' ;
        }
    }
    
    //--SoleTrader request body wrapper
    public class SoleTraderRequestBody{
        private String applicationID{get;set;}    //[Required]:A unique ID that is used to identify the application in all operations
        private PrimaryContactInfo primaryContact{get;set;}
        private String creditAmountRequired{get;set;}   //[Required : Minimum Value: 1 Maximum Value:999,999,999]
        private String termDays{get;set;}            // [Required]: Enumeration: D7, D30, D14              
        //businessDetails
        private String businessTradingName{get;set;}   //[Optionl]
        private String businessABN{get;set;}           //[Optionl]
        //additional applicant
        private AdditionalApplicantInfo additionalApplicant{get;set;}
        private String paymentOption{get;set;}               //[Required: Cash, Cheque, CreditCard, DirectDebit, ElectronicFundsTransfer, Eftpos]
        private String applicantAdditionalDataName{get;set;} //[Required] not provided lengths
        private String applicantAdditionalDataValue{get;set;} //[Required]not provided lengths
        
        
        public SoleTraderRequestBody( 
            String primaryContactName,
            String primaryContactStreetNum, String primaryContactStreetName, String primaryContatCity, String primaryContactState, String primaryContactPostcode,
            String creditAmtRequired, String termDaysStr,String  busTradingName, String abn,
            String additionalApplicantFName, String additionalApplicantLName, String additionalApplicantDOB,  String additionalApplicantStNum, String additionalApplicantStName, String additionalApplicantSubrub, 
            String additionalApplicantState, String additionalApplicantPostcode,
            String applicantAdditionalName, String applicantAdditionalValue ){
                
                this.applicationID = generateRandomNumber().escapeXML();
                this.primaryContact = new PrimaryContactInfo(primaryContactName, new Address(primaryContactStreetNum, primaryContactStreetName, primaryContatCity, primaryContactState, primaryContactPostcode));
                this.creditAmountRequired = String.valueOf(Decimal.ValueOf(creditAmtRequired).IntValue()).escapeXML();
                this.termDays = termDaysStr;
                this.businessTradingName =!String.isEmpty(busTradingName) ? busTradingName.escapeXML() :'';
                this.businessABN =!String.isEmpty(abn) ? abn.escapeXML() :'';
                this.additionalApplicant = new AdditionalApplicantInfo(
                    additionalApplicantFName, additionalApplicantLName, additionalApplicantDOB, additionalApplicantStNum, additionalApplicantStName
                    ,additionalApplicantSubrub, additionalApplicantState, additionalApplicantPostcode );
                this.paymentOption = 'Cash';
                this.applicantAdditionalDataName = applicantAdditionalName;
                this.applicantAdditionalDataValue = applicantAdditionalValue;
            }
    }
    
    //--Company request body wrapper
    public class CompanyRequestBody{
        private String applicationID{get;set;}              //[Required]:A unique ID that is used to identify the application in all operations
        private PrimaryContactInfo primaryContact{get;set;}
        private String creditAmountRequired{get;set;}    //[Required]:Minimum Value: 1 Maximum Value:999,999,999
        private String termDays{get;set;}                // [Required]: Enumeration: D7, D30, D14     
        private String orgName{get;set;}                 // [Required]: No Restriction Minimum Length: 1 Maximum Length: 72 
        private String orgEntityType{get;set;}          // [Required]: Business, Company, Government, Other
        private String ogEntitySubType{get;set;}        // [Optional]: INC, LTD, NL, PTY, PL, RB
        private String orgACN{get;set;}                 // [Optional]: 9 digit number
        private String orgABN{get;set;}                 // [Optional]: 11 digit number
        private Address orgTradingAddress{get;set;}
        private String paymentOption{get;set;}          // [Required]: Enumeration: Cash, Cheque, CreditCard, DirectDebit, ElectronicFundsTransfer, Eftpos
        
        public CompanyRequestBody(
            String primaryContactName,
            String  primaryContactStreetNum, String primaryContactStreetName, String primaryContatCity, String primaryContactState, String primaryContactPostcode,
            String creditAmtRequired, String termDaysStr,
            String orgNameStr,  String orgEntityTypeStr,  String ogEntitySubTypeStr, String orgACNStr, String orgABNStr,
            String  orgStreetNum, String orgStreetName,String orgCity, String orgState, String orgPostcode){
                
                this.applicationID = generateRandomNumber().escapeXML();
                this.primaryContact = new PrimaryContactInfo(primaryContactName, new Address(primaryContactStreetNum, primaryContactStreetName, primaryContatCity, primaryContactState, primaryContactPostcode));
                this.creditAmountRequired = String.valueOf(Decimal.ValueOf(creditAmtRequired).IntValue()).escapeXML();
                this.termDays =  !String.isEmpty(termDaysStr) ? termDaysStr : 'D14';
                this.orgName = !String.isEmpty(orgNameStr) ? replaceStr(orgNameStr, '', SEVENTY_TWO) : '';
                this.orgEntityType = !String.isEmpty(orgEntityTypeStr) ? orgEntityTypeStr.escapeXML() : '';
                this.ogEntitySubType = ogEntitySubTypeStr;  // INC
                this.orgACN =  !String.isEmpty(orgACNStr) ? orgACNStr.escapeXML() :'';
                this.orgABN =  !String.isEmpty(orgABNStr) ? orgABNStr.escapeXML() : '';
                this.orgTradingAddress = new Address(orgStreetNum, orgStreetName, orgCity, orgState, orgPostcode);
                this.paymentOption = 'Cash';
                
            }
        
    }
    
     /**
     * Building 'soletrader' equifax SOAP request from wrapper object
     * **/
    public static String buildIndividualCreditAssesmentRequest(SoleTraderRequest soleTraderReq){
        
        String requestString = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:com="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1" xmlns:get="http://www.auspost.com.au/Service/Party/Customer/getIndividualCreditAssessment:v1" xmlns:len="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending">'+
            '<soapenv:Header>'+
            '<com:InterfaceHeader>'+
            '<com:InterfaceName>'+soleTraderReq.reqHeader.interfaceName+'</com:InterfaceName>'+
            '<com:InterfaceVersion>'+soleTraderReq.reqHeader.interfaceVersion+'</com:InterfaceVersion>'+
            '<com:MessageType>'+soleTraderReq.reqHeader.messageType+'</com:MessageType>'+
            '<com:BusinessReferenceID>'+soleTraderReq.reqHeader.businessReferenceID+'</com:BusinessReferenceID>'+
            '<com:SourceSystemID>'+soleTraderReq.reqHeader.sourceSystemID+'</com:SourceSystemID>'+
            '<com:Timestamp>'+soleTraderReq.reqHeader.timestamp+'</com:Timestamp>'+
            '</com:InterfaceHeader>'+
            '</soapenv:Header>'+
            '<soapenv:Body>'+    
            '<get:getIndividualCreditAssessment>'+
            '<len:IndividualCommercialRequest>'+
            '<len:applicationID>'+soleTraderReq.reqBody.applicationID+'</len:applicationID>'+
            '<len:primaryContact>'+
            '<len:name>'+soleTraderReq.reqBody.primaryContact.name+'</len:name>'+
            '<len:email>'+soleTraderReq.reqBody.primaryContact.email+'</len:email>'+
            '<len:phone>'+
            '<len:areaCode>'+soleTraderReq.reqBody.primaryContact.phoneAreaCode+'</len:areaCode>'+
            '<len:number>'+soleTraderReq.reqBody.primaryContact.phoneNumber+'</len:number>'+
            '</len:phone>'+
            '<len:mobile>'+soleTraderReq.reqBody.primaryContact.mobile+'</len:mobile>'+
            '<len:address>'+
            '<len:streetNumber>'+soleTraderReq.reqBody.primaryContact.address.streetNumber+'</len:streetNumber>'+
            '<len:streetName>'+soleTraderReq.reqBody.primaryContact.address.streetName+'</len:streetName>'+
            '<len:suburb>'+soleTraderReq.reqBody.primaryContact.address.subrub+'</len:suburb>'+
            '<len:state>'+soleTraderReq.reqBody.primaryContact.address.state+'</len:state>'+
            '<len:postcode>'+soleTraderReq.reqBody.primaryContact.address.postCode+'</len:postcode>'+
            '</len:address>'+
            '<len:promotionalInformation>'+soleTraderReq.reqBody.primaryContact.promotionInfo+'</len:promotionalInformation>'+
            '</len:primaryContact>'+
            '<len:commercialApplication>'+
            '<len:creditAmountRequired>'+soleTraderReq.reqBody.creditAmountRequired+'</len:creditAmountRequired>'+
            '<len:termDays>'+soleTraderReq.reqBody.termDays+'</len:termDays>'+
            '</len:commercialApplication>'+
            '<len:businessDetails>'+
            '<len:tradingName>'+soleTraderReq.reqBody.businessTradingName+'</len:tradingName>';
        
        String abnString =  !String.isEmpty(soleTraderReq.reqBody.businessABN) ? ('<len:ABN>'+soleTraderReq.reqBody.businessABN+'</len:ABN>'): '';
        
        requestString = requestString + abnString +
            '</len:businessDetails>'+
            '<len:additionalApplicants>'+
            '<len:applicant>'+
            '<len:applicantDetails>'+
            '<len:firstName>'+soleTraderReq.reqBody.additionalApplicant.firstName+'</len:firstName>'+
            '<len:lastName>'+soleTraderReq.reqBody.additionalApplicant.lastName+'</len:lastName>'+
            '<len:dateOfBirth>'+soleTraderReq.reqBody.additionalApplicant.dob+'</len:dateOfBirth>'+
            '</len:applicantDetails>'+
            '<len:address>'+
            '<len:streetNumber>'+soleTraderReq.reqBody.additionalApplicant.address.streetNumber+'</len:streetNumber>'+
            '<len:streetName>'+soleTraderReq.reqBody.additionalApplicant.address.streetName+'</len:streetName>'+
            '<len:suburb>'+soleTraderReq.reqBody.additionalApplicant.address.subrub+'</len:suburb>'+
            '<len:state>'+soleTraderReq.reqBody.additionalApplicant.address.state+'</len:state>'+
            '<len:postcode>'+soleTraderReq.reqBody.additionalApplicant.address.postCode+'</len:postcode>'+
            '</len:address>'+
            '<len:contactDetails>'+
            '<len:email>'+soleTraderReq.reqBody.additionalApplicant.email+'</len:email>'+
            '<len:phone>'+
            '<len:areaCode>'+soleTraderReq.reqBody.additionalApplicant.phoneAreaCode+'</len:areaCode>'+
            '<len:number>'+soleTraderReq.reqBody.additionalApplicant.phoneNumber+'</len:number>'+
            '</len:phone>'+
            '<len:mobile>'+soleTraderReq.reqBody.additionalApplicant.mobile+'</len:mobile>'+
            '</len:contactDetails>'+
            '<len:additionalApplicantData>'+
            '<len:name>'+soleTraderReq.reqBody.applicantAdditionalDataName+'</len:name>'+
            '<len:value>'+soleTraderReq.reqBody.applicantAdditionalDataValue+'</len:value>'+
            '</len:additionalApplicantData>'+
            '<len:consentToCheckCreditHistory>false</len:consentToCheckCreditHistory>'+
            '</len:applicant>'+
            '</len:additionalApplicants>'+
            '<len:paymentDetails>'+
            '<len:paymentOption>'+soleTraderReq.reqBody.paymentOption+'</len:paymentOption>'+
            '</len:paymentDetails>'+
            '</len:IndividualCommercialRequest>'+
            '</get:getIndividualCreditAssessment>'+
            '</soapenv:Body>'+
            '</soapenv:Envelope>';
        System.debug('SoleTrader Equifax request = '+requestString);
        return requestString;
    }
    
    /**
     * Building 'company' equifax SOAP request from wrapper object
     * **/
    public static String buildCompanyCreditAssesmentRequest(CompanyRequest companyReq){
        String requestString = '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
            '<env:Header>'+
            '<InterfaceHeader xmlns="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1">'+
            '<InterfaceName>'+companyReq.reqHeader.interfaceName+'</InterfaceName>'+
            '<InterfaceVersion>'+companyReq.reqHeader.interfaceVersion+'</InterfaceVersion>'+
            '<MessageType>'+companyReq.reqHeader.messageType+'</MessageType>'+
            '<BusinessReferenceID>'+companyReq.reqHeader.businessReferenceID+'</BusinessReferenceID>'+
            '<SourceSystemID>'+companyReq.reqHeader.sourceSystemID+'</SourceSystemID>'+
            '<Timestamp>'+companyReq.reqHeader.timestamp+'</Timestamp>'+ 
            '</InterfaceHeader>'+
            '</env:Header>'+
            '<env:Body>'+
            '<getCompanyCreditAssessment xmlns="http://www.auspost.com.au/Service/Party/Customer/getCompanyCreditAssessment:v1" xmlns:n1="http://www.auspost.com.au/Service/Party/Customer/Individual/Enterprise/Commercial/Lending">'+
            '<CompanyBusinessRequest xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
            '<applicationID xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+companyReq.reqBody.applicationID+'</applicationID>'+
            '<primaryContact xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
            '<name>'+companyReq.reqBody.primaryContact.name+'</name>'+
            '<email>'+companyReq.reqBody.primaryContact.email+'</email>'+
            '<phone>'+
            '<areaCode>'+companyReq.reqBody.primaryContact.phoneAreaCode+'</areaCode>'+
            '<number>'+companyReq.reqBody.primaryContact.phoneNumber+'</number>'+
            '</phone>'+
            '<mobile>'+companyReq.reqBody.primaryContact.mobile+'</mobile>'+
            '<address>'+
            '<streetNumber>'+companyReq.reqBody.primaryContact.address.streetNumber+'</streetNumber>'+
            '<streetName>'+companyReq.reqBody.primaryContact.address.streetName+'</streetName>'+
            '<suburb>'+companyReq.reqBody.primaryContact.address.subrub+'</suburb>'+
            '<state>'+companyReq.reqBody.primaryContact.address.state+'</state>'+
            '<postcode>'+companyReq.reqBody.primaryContact.address.postCode+'</postcode>'+
            '</address>'+
            '<promotionalInformation>'+companyReq.reqBody.primaryContact.promotionInfo+'</promotionalInformation>'+
            '</primaryContact>'+
            '<commercialApplication xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
            '<creditAmountRequired>'+companyReq.reqBody.creditAmountRequired+'</creditAmountRequired>'+
            '<termDays>'+companyReq.reqBody.termDays+'</termDays>'+
            '</commercialApplication>'+
            '<organisation xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
            '<organisationDetails>'+
            '<name>'+companyReq.reqBody.orgName+'</name>'+
            '<entityType>'+companyReq.reqBody.orgEntityType+'</entityType>'+
            '<entitySubtype>'+companyReq.reqBody.ogEntitySubType+'</entitySubtype>';
        
        String acnString =  !String.isEmpty(companyReq.reqBody.orgACN) ? ('<australianCompanyNumber>'+companyReq.reqBody.orgACN+'</australianCompanyNumber>'): '';
        String abnString =  !String.isEmpty(companyReq.reqBody.orgABN) ? ( '<australianBusinessNumber>'+companyReq.reqBody.orgABN+'</australianBusinessNumber>'): '';
        
        requestString = requestString + acnString+ abnString +
            '</organisationDetails>'+
            '<tradingAddress>'+
            '<streetNumber>'+companyReq.reqBody.orgTradingAddress.streetNumber+'</streetNumber>'+
            '<streetName>'+companyReq.reqBody.orgTradingAddress.streetName+'</streetName>'+
            '<suburb>'+companyReq.reqBody.orgTradingAddress.subrub+'</suburb>'+
            '<state>'+companyReq.reqBody.orgTradingAddress.state+'</state>'+
            '<postcode>'+companyReq.reqBody.orgTradingAddress.postCode+'</postcode>'+
            '</tradingAddress>'+
            '</organisation>'+
            '<paymentDetails xmlns="http://www.auspost.com.au/Service/Party/Customer/Company/Enterprise/Commercial/Lending">'+
            '<paymentOption>'+companyReq.reqBody.paymentOption+'</paymentOption>'+
            '</paymentDetails>'+
            '</CompanyBusinessRequest>'+
            '</getCompanyCreditAssessment>'+
            '</env:Body>'+
            '</env:Envelope>';
        System.debug('Company Equifax request = '+requestString);
        return requestString;
    }
    
    
    /*------------------------------------------------------------
    Description:   Method to parse the response xml and store all the values in a Map
    Inputs:        DOM.XMLNode: Root element of the Response                 
    entityTypeForAssessment : Type of Entity for ex Company Or Other
    Returns:       Map<String,String> : Map of Response element and response value
    */
    
    public static Map<String,String> parseXML(DOM.XMLNode node , Map<String,String> decisionMap) {
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            // Putting the response and element value to the Map
            decisionMap.put(node.getname(),node.getText().trim());
        }
        for (Dom.XMLNode child: node.getChildElements()) {
            parseXML(child , decisionMap);
        }
        return decisionMap;
    }
    
    /**
    This method is used for generate random number 
    **/ 
    public static String generateRandomNumber() {
        try {
            //Datetime now = Datetime.now();
            //Long timenow = now.getTime();
            // String test = String.ValueOf(timenow);
            return String.ValueOf(Datetime.now().getTime());
            //return test;
        } catch(system.exception ex) {
            System.debug('Exception in EquifaxController.generateRandomNumber()'+ex.getMessage());
            return null;
        }   
        
    }
    /**
     * Building HTTP request 
     * */
     public static HttpRequest buildHttpRequest(String requestString, String businessType){
        //Map<String,String> decisionMap = new Map<String,String>();
        
        // Creating the HTTP Request 
        if(String.IsNotBlank(requestString)){
            
            HttpRequest req = new HttpRequest();
            //Fething the details from the Custom setting to set the EndPoint for the callout
            APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
            if(r2tSystemProperty != null){
                if(businessType == BCAFormHelper.SOLE_TRADER_EQUIFAX_REQUEST_TYPE && r2tSystemProperty.APT_INDV_Credit_Assessment_End_Point_URL__c != null) {
                    req.setEndpoint(r2tSystemProperty.APT_INDV_Credit_Assessment_End_Point_URL__c);
                    req.setHeader('SOAPAction','/Services/ExternalCreditAssessmentServices/getIndividualCreditAssessment_v1');
                } else if(businessType ==  BCAFormHelper.COMPANY_EQUIFAX_REQUEST_TYPE && r2tSystemProperty.APT_CompanyCreditAssessmentEndPointURL__c != null) {
                    req.setEndpoint(r2tSystemProperty.APT_CompanyCreditAssessmentEndPointURL__c);
                    req.setHeader('SOAPAction','/Services/ExternalCreditAssessmentServices/getCompanyCreditAssessment_v1');
                }
            }
            
            // Setting Request Method
            req.setMethod('POST');
            // Setting Request Body
            req.setBody(requestString);
            req.setHeader(APT_WebServiceUtility.AUTHORIZATION , APT_WebServiceUtility.getinputHttpHeaders().get(APT_WebServiceUtility.AUTHORIZATION));
            req.setHeader('Content-Type', 'text/xml');
            // Setting Request Timeout
            req.setTimeout(120000);
            system.debug(' REQUEST STRING=>'+req.getbody());
           /* Http http = new Http();
            //Making Call out to TIBCO
            system.debug(' REQUEST STRING=>'+req.getbody());
            HTTPResponse res = http.send(req); 
            system.debug('---Respone--=>'+res.getbody());
            Dom.Document doc = res.getBodyDocument();
            Dom.XMLNode rootElement = doc.getRootElement();
           // system.debug('---Root Element--'+rootElement);
            //Parsing the Response
            decisionMap =  parseXML(rootElement, decisionMap);
            system.debug('***** DECISION MAP*****'+decisionMap);*/
            return req;
        }
        else{
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please Validate the ABN/ACN'));   // TO DO
            return null;
        }
    }
    
    public static Map<String,String> parseHttpResponse(HTTPResponse res){
        Map<String,String> decisionMap = new Map<String,String>();
        system.debug('---Respone--=>'+res.getbody());
        Dom.Document doc = res.getBodyDocument();
        Dom.XMLNode rootElement = doc.getRootElement();
        // system.debug('---Root Element--'+rootElement);
        //Parsing the Response
        decisionMap =  parseXML(rootElement, decisionMap);
        //system.debug('***** DECISION MAP*****'+decisionMap);
        return decisionMap;
    }
    
    private static String replaceStr(String sourceStr, String allowChars,Integer length){
       
        String replaceStr;
       
        if(allowChars == ALPHA_NUMERIC_AND_SPACE)
            replaceStr = sourceStr.replaceAll('[^a-zA-Z0-9\\s+]', '');
        
        else if(allowChars == ALPHA_NUMERIC_SPACE_HYPHEN)
            replaceStr = sourceStr.replaceAll('[^a-zA-Z0-9\\-\\s+]', '');
        
         else if(allowChars == ALPHABET_BLANK_HYPHEN_APOSTROPHE)
            replaceStr = sourceStr.replaceAll('[^a-zA-Z\'\\-\\s+]', '');
        
        else 
            replaceStr = sourceStr;
       
        if(replaceStr.length() > length )
            replaceStr = replaceStr.substring(0, length-1);
        
        return replaceStr.escapeXML();  // Escape may not be needed in all scenarios as we are replacing special characters
    }
    
    private static final String ALPHA_NUMERIC_AND_SPACE = 'alphaNumericAndSpace';
    private static final String ALPHA_NUMERIC_SPACE_HYPHEN = 'alphaNumericSpaceHyphen';
    private static final String ALPHABET_BLANK_HYPHEN_APOSTROPHE = 'AlphaBlankHyphenApostrophe';
    private static final INTEGER TWENTY_FIVE = 25;
    private static final INTEGER TWENTY_TWO = 22;
    private static final INTEGER SEVENTY_TWO = 72;
    private static final INTEGER ONE_TWENTY_EIGHT = 128;
    private static final INTEGER FIFTEEN = 15;
    
     
}