/**************************************************
Type:       Controller for AdvancedSearchContactComponent component (POB search) 
Purpose:    Used by AdvancedSearchContactComponent VF Component to search for Contacts/Person Accounts using the POB Numbers. 
History:
--------------------------------------------------
2023-10-02    Boris Bachovski    Refactor to use IsInactiveCustomer__c instead of is_Inactive_Customer__c
**************************************************/

/**
  * @author       : dilshan.egodawela@auspost.com.au
  * @date         : 30/06/2017
  * @description  : Controller for AdvancedSearchContactComponent to search contacts based on PostOffice Box Numbers
  *
  * Updates       :
  *						18 Aug 2017     dilshan.egodawela@auspost.com.au 		Method to get the minimun LOA value.
  *
  */  
public with sharing class AdvancedSearchContactComponentController{
    
    public Integer ROW_LIMIT = 50;
    
    // Variables
    public String strFirstName {get;set;}
    public String strLastName {get;set;}
    public String strPhone {get;set;}
    public String strpostalcode {get;set;}

    public AddressExtension proxyAddress {get;set;}
    
    public Boolean expandAddress {get;set;}
    
    // Pagination variables
    public Integer totalPageNum {get;set;}
    public Integer totalRecordsNum {get;set;}
    public List<Integer> list_pageNo {get;set;}
    private Integer contactPageSize;
    public Integer currentPageNum {get;set;}
    public Boolean isNewSearch {get;set;}
    public Boolean showList {get;set;}
    
    @TestVisible private List<ContactListDisplay> contacts;
    public List<ContactListDisplay> contacts4Page {get; set;}
    
    private Boolean hasAccountNum;
    private Boolean hasAccountName;
    private Boolean hasContactFieldSearch;
    public decimal minLOA {get;set;}

    
    /*
        @constructor : initializes variable & loads contact for CTI
     */
    public AdvancedSearchContactComponentController(){
        initPage(); // initialize page
        prodFilter = 'POB';
        setMinLOA();
    }
    
    /**
      * @description       This method is invoked from constructor to initialize page variables
      * @param             NA
      * @return            Void
      * @throws            NA
      */ 
    public void initPage() {
        contactPageSize = 100;
        currentPageNum = 1;
        isNewSearch = false;
        showList = false;
  
        proxyAddress = new AddressExtension();
        expandAddress = false;
        
        contacts = new List<ContactListDisplay>();    
        contacts4Page = new List<ContactListDisplay> ();
    }

    public String prodFilter {get; set;}    

    public  List<SelectOption> getFilterOptions() {
        
         List<SelectOption> prodFilterOptions = new List<SelectOption>();
         prodFilterOptions.add(new SelectOption('POB','Post Office Box'));
         //ChartOptions.add(new SelectOption('LNG','Load and Go')); 
         return prodFilterOptions;                       
    }
    public void setMinLOA(){
        List<LOA_Settings__c> loas = LOA_Settings__c.getall().values();
        List<decimal> b = new List<decimal>();
        for(LOA_Settings__c a : loas){
            b.add(a.LOA_Value__c);
        }
        b.sort();
        if(!b.isEmpty()){
            minLOA = b.get(0);
            System.debug('min : '+minLOA);
        }   
    }
    
    /**
      * @description       This method is invoked when Search button is clicked which displays contacts matching the search parameters
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    public void searchForContact() { 
        initPage();
    }  
    
    /**
      * @description       This method is invoked when Clear button is clicked to clear variables
      * @param             NA
      * @return            void
      * @throws            Method might throw exception which is handled by Try-Catch block
      */
    public void clearSearch(){
        initPage();
    }    
       
    @RemoteAction
    public static List<ContactListDisplay> searchCustomerREST(String parameter1 , String parameter2, String parameter3){
	List<ContactListDisplay> returnList = new List<ContactListDisplay>();
    List<String> aPCNs = new list<String>();
    HttpRequest req = new HttpRequest(); 
 
	req.setMethod('GET');
    String endPoint; 
    
    AusPostSettings__c setting = AusPostSettings__c.getValues('SAP_SearchByProductParameters');
            if (setting != null)
            {
                endPoint = setting.URL__c;
            }

	req.setEndpoint(endPoint+'?ProductID=\'POB\'&Parameter1=\''+parameter1+'\'&Parameter2=\''+EncodingUtil.urlEncode(parameter2, 'UTF-8').replaceAll('\\+','%20')+'\'&Parameter3=\''+parameter3+'\'&$format=json');
	//req.setEndpoint('https://webapi-pdevext.npe.auspost.com.au/pdev/crm/ConsumerManagement/v1/pobLease/SearchBusPartnersByProductParameters?ProductID=\'POB\'&Parameter1=\''+Parameter1+'\'&Parameter2=\''+Parameter2+'\'&$format=json');
	//req.setHeader('Authorization', 'Basic X1RJQl9ERVZfU1NPOkx3NU5rZmly');
	Blob headerValue = Blob.valueOf(setting.Username__c + ':' + setting.Password__c);
	//Blob headerValue = Blob.valueOf('salesforce' + ':' + 'Salesforce123!');
	String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
	req.setHeader('Authorization', authorizationHeader);

	System.debug('authorizationHeader: '+authorizationHeader);
	Http http = new Http();
  	
   	   
	HTTPResponse res = http.send(req);
        if(res.getStatusCode() == 200){
        System.debug('res.getBody() : '+res.getBody());
//String jsonbosy = '{"d":{"results":[{"__metadata":{"id":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1000023788\')","uri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1000023788\')","type":"zgw_consumer_management_srv.BusinessPartner","properties":{"ConsumerInfo":{"associationuri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1000023788\')/$links/ConsumerInfo"},"BusinessPartnerType":{"associationuri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1000023788\')/$links/BusinessPartnerType"}}},"BusinessPartnerID":"1000023788","BusinessPartnerTypeID":"1","ConsumerInfo":{"__deferred":{"uri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1000023788\')/ConsumerInfo"}},"BusinessPartnerType":{"__deferred":{"uri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1000023788\')/BusinessPartnerType"}}}]}}';
Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            
System.debug(results.get('d'));
Map<String, Object> a = (Map<String, Object>)results.get('d');
//List<Object> a2 = (List<Object>)a.get('BusinessPartnerID');
System.debug(a.get('results'));
List<Object> a2 = (List<Object>)a.get('results');
            System.debug('.size() : '+a2.size());
if(a2.size() != 0){
//System.debug('Booo : '+a2[0].get('BusinessPartnerID'));
    for(Object x : a2){
Map<String, Object> a3 = (Map<String, Object>)x;
System.debug(a3.get('BusinessPartnerID'));

               
        //List<String> APCNs = new list<String>{'1000022896','1110022896'};

        aPCNs.add((String)a3.get('BusinessPartnerID'));
            
    }
            

        for(Contact con:[SELECT Id, Name,APCN__c, OtherStreet, OtherStreet2__c, OtherCity, OtherState, OtherPostalCode, 
                                  IsInactiveCustomer__c, Account.isCustomerPortal, OtherCountry, OtherDPID__c, MailingDPID__c,
                                  SocialKeys__c, ReversePhoneFields__c, Salutation, CRMCSSOID__c, IsDuplicate__c, Phone, HomePhone,
                                  OtherPhone,LevelOfAssurance__c, MobilePhone,VerifiedMobile__c, Email, ServiceType__c, MailingStreet, MailingStreet2__c, MailingCity, 
                                  MailingState, MailingCountry, MailingPostalCode, AccountId, Account.Name, Account.IsPersonAccount, 
                                  Account.RecordTypeId, Account.RecordType.Name, Account.ABN__c,Account.Role_Type_Roll_Up__c, 
                                  Account.ServiceSLA__c, Account.IsVIP__c, BillingAccount__r.Id, BillingAccount__r.Name, 
                                  BillingAccount__r.LEGACY_ID__c, Unique_Mobile__c, (SELECT Id,IsClosed FROM Cases)
                         FROM Contact where Account.IsPersonAccount = true AND Account.APCN__c IN :aPCNs ORDER BY Unique_Mobile__c DESC, Name Limit 50]){
        
                 
        	returnList.add(new ContactListDisplay((Contact)con));
                         }
            }
            }
        return returnList;
        
    }
       
    //Wrapper class for the displayed contacts
    public class ContactListDisplay {       
        public Contact contact{get;set;}     
        public Integer numberOfOpenCases{get;set;}
        public Integer numberOfClosedCases{get;set;}
        
        public ContactListDisplay(){
        	numberOfOpenCases = 0;
        	numberOfClosedCases = 0;
        }   
        
        public ContactListDisplay(Contact con){
            this();
            this.contact = con; 
        	if(con.cases != null)
            	for(Case caseRec : con.cases)
                	if(caseRec.IsClosed) numberOfClosedCases++;
                        else numberOfOpenCases++;
        }
    }   
}