/**
* @author       : 
* @date         : 
* @description  : controller class for edd calculation
*/
/*******************************  History ************************************************
02/03/2016  kalpita.talwadekar@auspost.com.au   Updated to add the edd images and code changes
11/08/2016  kalpita.talwadekar@auspost.com.au   Updated to add the edd incident fix to include weekends and public holidays
12/09/2019  arjun.singh@auspost.com.au          Updated to consume new response for EDD Integration
*******************************  History ************************************************/
public without sharing class EDDWidgetController {    
    public String dateString {get;set;}    
    public String senderPostcode {get;set;}
    public String receiverPostcode {get;set;}    
    public Case dummyCase {get;set;}    
    public Boolean datePostedFlag{get;set;}
    public List<Service> services{get;set;}    
    public Boolean servicesFound{get;set;}

    public String eddResponseJson;
    public String senderPostCodePreviousValue;
    public String receiverPostcodePreviousValue;

    private static final String EXPRESS = 'express';
    private static final String COURIER = 'courier';
    private static final String REGULAR = 'regular';
    private static final String CONFIRM_IMG = 'confirm16.png';
    private static final String ERROR_IMG = 'error16.png';
    private static final String WARNING_IMG = 'warning16.png';
    private static final String ITEMS = 'items';
    private static final String TYPE = 'type';
    private static final String SERVICE = 'Service';
    private static final String CATEGORY = 'category';
    private static final String CODE = 'code';
    private static final String DELIVERY_ESTIMATE = 'DeliveryEstimate';
    private static final String MAXIMUM = 'maximum';
    private static final String ESTIMATE = 'estimate';
    private static final String ASK_POST_OFFICE = 'Ask at Post Office';
    
    /**
      @description  controller class to do the initial setup
      @param    NA
      @return   NA
      @throws NA
      */
    public EDDWidgetController(){
        dummyCase = new Case();        
        services = new List<Service>();        
        servicesFound = false;
        datePostedFlag = false;
    }    
   
    /**
      @description  Method to get the Estimated Deliver time using EDD Integration.New EDD response
      *             sends out all the services as a response and will be displayed in salesforce UI
      *             to provide the maximum information to inernal users.
      @param    NA
      @return   NA
      @throws NA
    */
    public void fetchEDD(){
        try{
            String maxDateString = '';
            String maxDayInDays = '';            
            servicesFound = false;             
            services = new List<Service>();
            if(!string.isEmpty(SenderPostcode) && !string.isEmpty(SenderPostcode)){
                System.debug('Coming inside');
                if((senderPostCodePreviousValue == SenderPostcode) && (receiverPostcodePreviousValue == ReceiverPostcode)){
                        parseEDDJsonResponse(eddResponseJson);
                }else{
                        senderPostCodePreviousValue = SenderPostcode ;
                        receiverPostcodePreviousValue = ReceiverPostcode;
                        AusPostSettings__c settings = AusPostSettings__c.getValues('EstimatedDeliveryDateV2');
                        string url = settings.URL__c + '?category=DOMESTIC&from=' + SenderPostcode.trim() + '&to=' + ReceiverPostcode.trim() ;
                        system.debug('calling url = ' + url);           
                        HttpRequest req = new HttpRequest();
                        req.setEndpoint(url);
                        req.setMethod('GET');
                        Blob headerValue = Blob.valueOf(settings.AppKey__c );
                        req.setHeader('AUTH-KEY', 'Basic ' + EncodingUtil.base64Encode(headerValue));
                        req.setHeader('Content-Type','application/json');            
                        
                        Http http = new Http();
                        HttpResponse res;            
                      
                        res = http.send(req);
                        if(res.getStatusCode() == 400 || res.getStatusCode() == 200){
                            system.debug('Content from AusPost: ' + res.getBody());
                            JSONParser parser = JSON.createParser(res.getBody());               
                                
                            if(res.getStatusCode() == 200){                 
                                eddResponseJson = String.valueOf(res.getBody());
                                // On Successful response, parse and display the response in user friendly format
                                parseEDDJsonResponse(eddResponseJson);
                            } else if(res.getStatusCode() == 400){
                                while (parser.nextToken() != null) {
                                    system.debug('7: ' + parser.getText());
                                    String serviceType = parser.getText();
                                    parser.nextToken();
                                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                                        error e = (error)parser.readValueAs(error.class);                                
                                        dateString = 'Error: ' + e.defaultMessage;
                                        servicesFound = false;
                                        break;
                                    }
                                }
                            } 
                        }else {
                            servicesFound = false;
                            dateString = 'Error: A Network error has occurred. Code: ' + res.getStatusCode();
                        }
                    }    
                }else {
                    servicesFound = false;
                    dateString = 'Please fill in Sender and Receiver postcode' ;
                }
                       
        }catch(Exception e){
            servicesFound = false;
            dateString = 'Issue with EDD Integration, Please contact System Administrator.' ;
        }
    }
    /**
        @description : Parse the EDD Integration response.EDD Response has all the domestic services
    *                  (Parcel/letter) with details . Salesforce will fetch/display only Service Type, Estimated Delivery time
    *                  to display before creation of related Enquiry     
        @param    String eddResponseJson
        @return   NA 
     */
    public void parseEDDJsonResponse(String eddResponseJson){
        List<Service> servicesTemp = new List<Service>();      
        datePostedFlag = false;
        Map<String, Object> jsnDeserialized  = (Map<String, Object>)JSON.deserializeUntyped(eddResponseJson);                       
        date dateSent ;
        if(dummyCase.DatePosted__c != null){
            dateSent = date.valueOf(datetime.newInstance(dummyCase.DatePosted__c, time.newInstance(0,0,0,0)).format('yyyy-MM-dd'));
            datePostedFlag = true;
        }
        if(jsnDeserialized.containsKey(ITEMS)){
            List<Object> itemsVar = (List<Object>) jsnDeserialized.get(ITEMS); 
                for(Object itmObject : itemsVar){
                    Map<String, Object> itmKeyValue = (Map<String, Object>)itmObject ;                
                    if(itmKeyValue.get(TYPE) == SERVICE){
                        list<Object> innerItems = (list<Object>)itmKeyValue.get(ITEMS);
                        String categoryVar = String.valueOf(itmKeyValue.get(CATEGORY));
                        categoryVar = categoryVar.remove('DOMESTIC_');
                        String serviceTypeVar = itmKeyValue.get(CODE) + ' ' + categoryVar ;
                        for(Object innerObject : innerItems){
                            Map<String, Object> innerObjectMap = (Map<String, Object>)innerObject ;
                            if(innerObjectMap.containsKey(TYPE) && innerObjectMap.get(TYPE) == DELIVERY_ESTIMATE){                        
                                Integer maxInt = Integer.valueOf(innerObjectMap.get(MAXIMUM));
                                String slaVar = String.valueOf(innerObjectMap.get(ESTIMATE));
                                String nextBusinessDate ;
                                String missingItmLogDate ;
                                Boolean missingItemRequiredFlag = false;                                
                               
                                System.debug('serviceTypeVar>>>'+serviceTypeVar);

                                if(dateSent != null && maxInt != null){
                                   nextBusinessDate = calculateNextBusinessDay(dateSent, maxInt);                                   
                                   missingItmLogDate = calculateMissingItmLogDate(nextBusinessDate, serviceTypeVar);                                   
                                }
                                if(missingItmLogDate != null && date.parse(missingItmLogDate) > system.today()){
                                    missingItemRequiredFlag = true;
                                }
                                if(slaVar.contains(ASK_POST_OFFICE)){
                                    nextBusinessDate = '';
                                    slaVar = 'EDD Unavailable';
                                }
                                if(categoryVar.equalsIgnoreCase('parcel')){
                                    services.add(new Service(serviceTypeVar, maxInt, slaVar, nextBusinessDate, true, missingItmLogDate, missingItemRequiredFlag ));                            
                                    servicesFound = true ;
                                }else if(categoryVar.equalsIgnoreCase('letter')){
                                    servicesTemp.add(new Service(serviceTypeVar, maxInt, slaVar, nextBusinessDate, false, missingItmLogDate,missingItemRequiredFlag ));
                                    servicesFound = true ;
                                }
                            }   
                        }
                    }
                }
        }      
        if(!servicesTemp.isEmpty()){
            Services.addAll(servicesTemp);
        }
    } 
    /** 
    @   Description :Services returned as a part of EDD Integration with different attributes 
    *                serviceType :              like (Regular letter, Priority letter, Express letter, Express Parcel, Regular Parcel)
    *                max :                      estimated delivery date: in day related to different service type,
    *                sla:                       sla for different service type, 
    *                nextBusinessDate :         Calculated internally in salesforce using max attribute , 
    *                isParcel :                 Calculated internally in saleseforce to differentiate between parcel and letter, 
    *                missingItmLogDate :        Calculated internally in saleseforce, 
    *                missingItmCaseRequired :   Calculated internally in saleseforce
     */
    public class Service {
        public string serviceType {get;set;}        
        public integer max {get;set;}
        public string sla {get;set;}
        public String nextBusinessDate{get;set;}
        public Boolean isParcel{get;set;}
        public String missingItmLogDate{get;set;}
        public Boolean missingItmCaseRequired{get;set;}
        public Service(String serviceTypeVar, integer maxVar, String slaVar, String nextBusinessDateVar, Boolean isParcelVar, String missingItmLogDateVar, Boolean missingItmCaseRequiredVar){
            serviceType = serviceTypeVar;           
            max = maxVar;
            sla = slaVar;
            nextBusinessDate = nextBusinessDateVar;
            isParcel = isParcelVar;
            missingItmLogDate = missingItmLogDateVar;
            missingItmCaseRequired = missingItmCaseRequiredVar;
        }
    }

    /** 
        @Description : Returns the next business day considering the weekends and holidays
        @param : date dateSent(Article lodgement date) , integer returnedMaxDay(max number of days returned from EDD Integration)
        @return : NA
    */
    private String calculateNextBusinessDay(Date dateSent, integer returnedMaxDay){
        datetime nextbusinessDayVar = BusinessHours.nextStartDate(bHours.Id, dateSent);
        Datetime maxDeliveryDate =  addDays(dateSent,returnedMaxDay); 
        return maxDeliveryDate.format('dd/MM/yyyy');        
    }
    
    public Datetime addDays(Datetime startDate, Integer days)
    {
        //If startdate is not within working days, take next working day
        startDate = BusinessHours.nextStartDate(bHours.Id, startDate);
		
        for (Integer elapsed = 0; elapsed < days; elapsed++)
        {
            //Add 1 day
            startDate = startDate.addDays(1);
            
            //Check if new date is within working days
            if (!BusinessHours.isWithin(bHours.Id, startDate))
            { 
                //If new date is not within working days, get new working day
                startDate = BusinessHours.nextStartDate(bHours.Id, startDate);
            }
        }
        return startDate;
    }
    /** 
        @Description : Returns the next business day after which a case can be raised for missing items
        @param : date dateSent(Article lodgement date) , integer maxDayInDays(max number of days returned from EDD Integration), String tempArticleType
        @return : String dateString
    */
    private String calculateMissingItmLogDate(String maxDateString,String tempArticleType){ 
        
        DateTime endDate ;
		 datetime nextbusinessDayVar ;
        //logic to calculate next business day         
        if(maxDateString != null ){
            Date maxdate = Date.parse(maxDateString) ;
            Integer wrkingDays = 0;
            // For Express services , missing itemcase can be logged after 1 business day  and for rest of the services 
            // missing item case can be logged after 3 business day
            Integer noOfDays = tempArticleType.tolowercase().contains(EXPRESS) ? 1 : 5;
            DateTime tempDate = tempArticleType.tolowercase().contains(EXPRESS) ?  addDays(maxDate, 1) : addDays(maxDate, 5);
            system.debug('--+maxDate'+maxDate);
            Date tempOld;
            //date and date + 1day
            // Below logic is to get the net business day on which missing item case can be logged
            Boolean noWorkingDay = true;
            Date startDate = maxDate;
            endDate = tempDate;
            
			 nextbusinessDayVar = BusinessHours.nextStartDate(bHours.Id, endDate);
        }
        //return (datetime.newInstance(endDate, time.newInstance(0,0,0,0)).format('dd/MM/yyyy'));        
		return nextbusinessDayVar.format('dd/MM/yyyy');  
    } 
    
    List<Holiday> holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate, h.RecurrenceType From Holiday h];

    BusinessHours bHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true] ;
    
    /**
      * @author       : 
      * @date         : 
      * @description  : Class for error handing and codes
      */
    public class error {
        public string code {get;set;}
        public string defaultMessage {get;set;}
    }
}