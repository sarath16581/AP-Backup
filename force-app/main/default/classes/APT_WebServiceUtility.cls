/**
* Description: This class is used while calling TIBCO web service
* Created By: Himanshu jain
* Created Date: 1st Oct, 2015
**/
public with sharing class APT_WebServiceUtility {
    
    //Credit Assessment type
    public static final string ABN = 'ABN';
    public static final string ACN = 'ACN';
    public static final string ORGANIZATION_NAME = 'Business Name';
    
    public static final string ENTITY_TYPE_TRUST = 'TRUST';
    public static final string ENTITY_TYPE_INDIVIDUAL = 'INDV';
    public static final string ENTITY_TYPE_COMPANY = 'COMP';
    public static final string CONSTANT_VEDA_ACTIVE = 'ACT';
    
    
    //default Timeout
    public static final Integer DEFAULT_WEBSERVICE_TIMEOUT = 40000;
    
    
    //organization type
    public static final string ORGANIZATION_TYPE_COMPANY = 'Company';
    public static final string ORGANIZATION_TYPE_SOLETRADER = 'Partnership/ Sole Trader';
    
    public static string CREDIT_CHECK_USERNAME;
    
    public static string CREDIT_CHECK_PASSWORD;
    
    
    //String Formats for Authorization
    public static final string AUTHORIZATION = 'Authorization';
    
    public static final string AUTHORIZATION_HEADER_FORMAT = 'Basic {0}';
    public static final string HEADER_VALUE_FORMAT = '{0}:{1}';
    
    
    //Interface names
    public static final string INTERFACE_NAME_QUERYABN = 'queryABN';
    public static final string INTERFACE_NAME_CREDIT_ASSESSMENT = 'getCreditAssessment';
    public static final string INTERFACE_NAME_QUERYRATECARDS = 'queryRatecards';
    
    
    //Business Reference ID
    
    //public static final string BUSINESS_REFERENCE_ID_FORMAT = 'Apttus_{0}_WebService';
    //character limit is 50
    public static final string BUSINESS_REFERENCE_ID_FORMAT = 'APT_{0}';
    
    
    //Error Message String
    
    public static final string ORG_ID_ALREADY_SEARCHED = 'This ABN/ACN have already been requested for Credit Assessment.';
    public static final String REQUEST = 'Request';
    public static final String APTTUS = 'Apttus';
    public static final String FLOAT_10 = '1.0';
    
    /**
        This method creates an authorization header for the webservices
    **/
    public static String getAuthorizationHeader(){
        APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
        if(r2tSystemProperty != null && String.isNotBlank(r2tSystemProperty.APT_User_Name__c)) {
            CREDIT_CHECK_USERNAME = r2tSystemProperty.APT_User_Name__c;
        }

        if(r2tSystemProperty != null &&  String.isNotBlank(r2tSystemProperty.APT_Password__c)) {
            CREDIT_CHECK_PASSWORD = r2tSystemProperty.APT_Password__c;
        }

        String headerString = String.format(HEADER_VALUE_FORMAT, new List<String> {CREDIT_CHECK_USERNAME,CREDIT_CHECK_PASSWORD});
        
        Blob headerValue = Blob.valueOf(headerString);
       
        String authorizationHeader = String.format(AUTHORIZATION_HEADER_FORMAT,new List<String> {EncodingUtil.base64Encode(headerValue)});
        return authorizationHeader;         
    } 
    
    /**
      This method creates an interface headers for various serices and passes to the web server.
    */
    public static APT_SchemaCommondatamodeService.InterfaceHeader getOrgIDInterfaceHeader(String interfaceName){
        
        APT_SchemaCommondatamodeService.InterfaceHeader interfaceHeader = new APT_SchemaCommondatamodeService.InterfaceHeader();
        interfaceHeader.InterfaceName = interfaceName;//'queryABN' ;
        interfaceHeader.MessageType= REQUEST ;
        interfaceHeader.BusinessReferenceID= String.format(BUSINESS_REFERENCE_ID_FORMAT, new List<String> {interfaceName}); 
        
        //Adding to create uniques business Reference ID each Time.
        interfaceHeader.BusinessReferenceID = interfaceHeader.BusinessReferenceID + DateTime.Now();
        
        interfaceHeader.SourceSystemID= APTTUS ;
        interfaceHeader.Timestamp= DateTime.now() ;
        interfaceHeader.InterfaceVersion = FLOAT_10;
        
        System.Debug(interfaceHeader.BusinessReferenceID);
        
        
        return interfaceHeader;
    }
    
    

    /**
     This method creates an interface headers for various serices and passes to the web server.
    */
    public static APT_CA_CommonDataModelSchema.InterfaceHeader getCreditAssessmentInterfaceHeader2(String interfaceName){
        
        APT_CA_CommonDataModelSchema.InterfaceHeader interfaceHeader = new APT_CA_CommonDataModelSchema.InterfaceHeader();
        interfaceHeader.InterfaceName = interfaceName;
        interfaceHeader.MessageType= REQUEST ;
        interfaceHeader.BusinessReferenceID= String.format(BUSINESS_REFERENCE_ID_FORMAT, new List<String> {interfaceName}); 
                
        //Adding to create uniques business Reference ID each Time.
        interfaceHeader.BusinessReferenceID = interfaceHeader.BusinessReferenceID + DateTime.Now();
        
        interfaceHeader.SourceSystemID= APTTUS ;
        interfaceHeader.Timestamp= DateTime.now() ;
        interfaceHeader.InterfaceVersion = FLOAT_10;
        
        System.Debug(interfaceHeader.BusinessReferenceID);
        
        return interfaceHeader;
    }

    /**
        This method creates an interface headers for various serices and passes to the web server.
    **/  
    
    public static APT_SAP_CommonDataModel.InterfaceHeader getqueryRateCardInterfaceHeader(String interfaceName){
        
        APT_SAP_CommonDataModel.InterfaceHeader interfaceHeader = new APT_SAP_CommonDataModel.InterfaceHeader();
        interfaceHeader.InterfaceName = interfaceName;//'queryRatecards' ;
        interfaceHeader.MessageType= REQUEST ;
        interfaceHeader.BusinessReferenceID= String.format(BUSINESS_REFERENCE_ID_FORMAT, new List<String> {interfaceName}); 
        
        //Adding to create uniques business Reference ID each Time.
        interfaceHeader.BusinessReferenceID = interfaceHeader.BusinessReferenceID + DateTime.Now();
        
        interfaceHeader.SourceSystemID= APTTUS ;
        interfaceHeader.Timestamp= DateTime.now() ;
        interfaceHeader.InterfaceVersion = FLOAT_10; 
        
        return interfaceHeader;
    }
    
     /**
        This method creates an interface headers for various serices and passes to the web server for SAP.
    **/
    public static APT_SAP_CommonDataModel.InterfaceHeader getSyncContractRatesInterfaceHeader(String interfaceName, datetime local){
        
        APT_SAP_CommonDataModel.InterfaceHeader interfaceHeader = new APT_SAP_CommonDataModel.InterfaceHeader();
        interfaceHeader.InterfaceName = interfaceName;
        interfaceHeader.MessageType= REQUEST ;
        interfaceHeader.BusinessReferenceID= String.format(BUSINESS_REFERENCE_ID_FORMAT, new List<String> {interfaceName}); 
        
        //Adding to create uniques business Reference ID each Time.
        interfaceHeader.BusinessReferenceID = interfaceHeader.BusinessReferenceID + local;
        
        interfaceHeader.SourceSystemID= APTTUS ;
        //interfaceHeader.Timestamp= DateTime.now() ;
        interfaceHeader.Timestamp= local; //APOST-1480
        interfaceHeader.InterfaceVersion = FLOAT_10; 
        
        return interfaceHeader;
    }
      
    /**
     This method will retrieve input httpheaders
    **/
    public static Map<String,String> getinputHttpHeaders(){
    
        Map<String,String> inputHttpHeaders = new Map<String,String>();
            
        inputHttpHeaders.put(AUTHORIZATION, getAuthorizationHeader());
        return inputHttpHeaders;
    }
}