/**************************************************
Description :               Webservice to create a pickup and delivery booking
Usage   :                   Called by MPB
Custom Metadatatype :       ResourceAPI__mdt
/api/1.0/pud/booking/create 	(customer id in Request Body)

History:
--------------------------------------------------
2019-05-13      ajudd@salesforce.com
2019-11-11		Dheeraj.Mandavilli@auspost.com.au
2020-02-07      Dheeraj.Mandavilli@auspost.com.au     Added logic to remove leading '0's from Billing account number
2020-03-18      Dheeraj.Mandavilli@auspost.com.au     Added Logic to capture article count from Payload
18-06-2021      REQ2529715  Naveen Rajanna Use the parse method of AMEFinalResponse to deserialise
2021-10-15 - Ranjeewa Silva - Populate frontage geolocation, dpid and side of street code returned on AME address lookup.
**************************************************/

public with sharing class ResourcePudCreateBookingV1 extends ResourceAPIService.IApi{
    /**
* Handle the create booking request for MPB as part of PUD Project
* Caller is expecting either a 201 response if the booking create was successful or a 500 with an error response if the create failed.
*/
    public override ResourceAPIService.IResourceResponse post() {            
        // In case on multiple validation error , need to pass all errors.
        List<String> errors = new List<String>();  
        
        // Variables to hold the values sourced from JSON body
        String requestCustomerNo; //Customer Id sourced from the JSON body
        String requestBAN;//Billing Account Number sourced from the JSON body
        String requestCustomerId;//Customer Salesforce Id sourced from the JSON body
        String requestLocation;//Name sourced from the JSON body
        String requestDate;//Date sourced from the JSON body
        String requestStartTime;//Start Time sourced from the JSON body
        String requestEndTime;//End Time sourced from the JSON body
        String requestContactPhone;//Contact Phone sourced from the JSON body
        String requestContactName;//Contact Name sourced from the JSON body
        String requestContactEmail;//Contact Email sourced from the JSON body
        String requestAddressLine1;//Address Line 1 sourced from the JSON body
        String requestAddressLine2;//Address Line 2 sourced from the JSON body
        String requestAddressLine3;//Address Line 3 sourced from the JSON body
        String requestStreet;//Variable to store concatenation of Address Line 1, 2 and 3 sourced from the JSON body
        string requestFullAddress;////Variable to store concatenation of Address Line 1, 2,3, city, state and postcode sourced from the JSON body
        String requestCity;//City sourced from the JSON body
        String requestPostCode;//PostCode sourced from the JSON body
        String requestState;//state sourced from the JSON body
        String requestBookingComments;//booking comments sourced from the JSON body
        String requestDepot;//Depot sourced from the JSON body
        boolean requestRevCheck;//revcheck sourced from the JSON body
        String requestArticleCount;//articlecount sourced from the JSON body
        
        //Temporary Variables to format the start time, end time and articles information
        String articleInfo;
        Time myStartTime;
        Time myEndTime;
        String requestSourceSystem;
        string allstring;      
        Map<String, Object> results = null;
        Map<String, Object> bookingAttributes = null;
        Map<String, Object> systemAttributes = null;
        List<Object> articleAttributes = null;
        List<String> artInfo = null;       
        Billing_Account__c requestAccount=null;
        Id requestNetwork=null;
        boolean custMatch = false;
        string billOrg;
        string ban1;
        
        try {
            //The MPB payload deserialization starts here
            String mpbJson = RestContext.request.requestBody.toString();
            
            PUD_MPBPayloadClass response = (PUD_MPBPayloadClass) System.JSON.deserialize(mpbJson, PUD_MPBPayloadClass.class);
            
            requestBAN=response.Booking.billingAccountNumber;
            system.debug('DK requestBAN = ' + requestBAN);
            
            //Logic to truncate leading zeros
            ban1 = requestBAN.replaceFirst('^0+','');
            system.debug('DK requestBAN1 = ' + ban1); 
                        
            requestCustomerId=response.Booking.customerId;
            system.debug('DK requestCustomerId = ' + requestCustomerId);
            
            requestDepot=response.Booking.depot;
            system.debug('DK requestDepot = ' + requestDepot);
            
            if(String.isNotBLANK(requestBAN) && String.isNotBLANK(requestCustomerId) && String.isNotBLANK(requestDepot)){
                
                try{
                    //Validate the Billing Account Number and Match Organisation associated with that billing account
                    requestAccount=validateAccount(ban1); 
                    
                    system.debug('requestAccount Id'+requestAccount.Id); 
                    system.debug('requestAccount Ogr'+requestAccount.Organisation__c);
                    billorg = String.valueof(requestAccount.Organisation__c);
                    system.debug('billorg  :::'+billorg);
                    custmatch = billorg.equalsIgnoreCase(requestCustomerId);
                    system.debug('custMatch :::'+custMatch);
                    if(custMatch == false){
                        return new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', 'The request doesnt contain matching Customer');    
                    }
                }
                catch(Exception Ex){
                    if(requestAccount == null){
                        return new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', 'The request doesnt contain matching Billing Account'); 
                    }
                }
                
                try{
                    //Validate the Deport details by matching against Network Object
                    requestNetwork=validateNetwork(requestDepot);
                    system.debug('requestNetwork value'+requestNetwork); 
                }
                catch(Exception Ex){
                    if(requestNetwork == null){ 
                        return new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', 'The request doesnt contain matching Depot'); 
                    }
                }
                
                
                if(response.Requestor.sourceSystem=='MPB'){
                    Id RecTyp = RecordTypes.getRecordTypeByName('MPB_Pickup','PUD_Booking__c').Id;
                    requestSourceSystem=RecTyp;
                    system.debug('record Type Id:::'+RecTyp);
                }
                
                requestCustomerNo=response.Booking.customerNumber;
                system.debug('Dk requestCustomerNo = ' + requestCustomerNo);
                
                if(response.Booking.locationName !=null){
                    requestLocation=response.Booking.locationName;  
                }
                system.debug('DK requestLocation = ' + requestLocation);
                system.debug('DK date in Json  = ' + response.Booking.dateVal);
                
                requestDate=response.Booking.dateVal;
                system.debug('DK requestDate = ' + requestDate);
                
                requestStartTime=response.Booking.startTime;
                system.debug('DK requestStartTime = ' + requestStartTime);
                
                requestEndTime=response.Booking.endTime;
                system.debug('DK requestEndTime = ' + requestEndTime);
                
                String[] strTimeSplit = requestStartTime.split(':');
                myStartTime = Time.newInstance( Integer.valueOf(strTimeSplit[0]) //hour
                                               ,Integer.valueOf(strTimeSplit[1]) //min
                                               ,0                                //sec
                                               ,0);                              //ms
                String[] strTimeSplit1 = requestEndTime.split(':');
                myEndTime = Time.newInstance( Integer.valueOf(strTimeSplit1[0]) //hour
                                             ,Integer.valueOf(strTimeSplit1[1]) //min
                                             ,0                                //sec
                                             ,0);
                
                requestContactPhone=response.Booking.contactPhone;
                system.debug('DK requestContactPhone = ' + requestContactPhone);
                
                requestContactName=response.Booking.contactName;
                system.debug('DK requestContactName = ' + requestContactName);
                
                requestContactEmail=response.Booking.contactEmail;
                system.debug('DK requestContactEmail = ' + requestContactEmail);
                
                requestAddressLine1=response.Booking.addressLine1;
                system.debug('DK requestAddressLine1 = ' + requestAddressLine1);
                
                requestAddressLine2=response.Booking.addressLine2;
                system.debug('DK requestAddressLine2 = ' + requestAddressLine2);
                
                requestAddressLine3=response.Booking.addressLine3;
                system.debug('DK requestAddressLine3 = ' + requestAddressLine3);
                
                if(requestAddressLine2 !=null && requestAddressLine3 !=null){
                    requestStreet=requestAddressLine1+' '+requestAddressLine2+' '+requestAddressLine3;
                    system.debug('DK requestStreet with 3 lines = ' + requestStreet); 
                }
                else if(requestAddressLine2 ==null && requestAddressLine3 !=null){
                    requestStreet=requestAddressLine1+' '+requestAddressLine3;
                    system.debug('DK requestStreet with 2 lines = ' + requestStreet); 
                }
                else if(requestAddressLine2 !=null && requestAddressLine3 ==null){
                    requestStreet=requestAddressLine1+' '+requestAddressLine2;
                    system.debug('DK requestStreet with 2 lines = ' + requestStreet);
                }
                else{
                    requestStreet=requestAddressLine1;
                }
                
                requestCity=response.Booking.city;
                system.debug('DK requestCity = ' + requestCity);
                
                requestPostCode=response.Booking.postCode;
                system.debug('DK requestPostCode = ' + requestPostCode);
                
                requestState=response.Booking.state;
                system.debug('DK requestState = ' + requestState);
                
                requestFullAddress=requestStreet+' '+requestCity+' '+requestState+' '+requestPostCode;
                system.debug('DK requestFUllAddress = ' + requestFullAddress);
                
                requestBookingComments=response.Booking.bookingComments;
                system.debug('DK requestBookingComments = ' + requestBookingComments);
                
                requestRevCheck=response.Booking.revenueCheck;
                system.debug('DK requestRevCheck = ' + requestRevCheck);
                
                requestArticleCount = response.Booking.articleCount;
                system.debug('DK requestArticleCount = ' + requestArticleCount);
                
                List<PUD_MPBPayloadClass.Article> artiInfo=response.Booking.articles;
                system.debug('Article Info in  JSON:::'+artiInfo);
                List<String> myfinalList= new List<String>();
                for(PUD_MPBPayloadClass.Article arti: artiInfo) {
                    articleInfo= 'Id: '+ arti.articleId +'  '+'PostCode: '+arti.destinationPostCode+'  '+'Domestic: '+arti.internationalOrDomestic+
                        +'  '+'H x L x W: '+arti.height+' X '+arti.length+' X '+arti.width+'  '+'Weight: '+ arti.weight;
                    system.debug('artInfo List:::'+articleInfo);
                    myfinalList.add(articleInfo);
                    
                }
                system.debug('My Final List::'+myfinalList);
                allstring = string.join(myfinalList,'\n');   
            }
            else{
                return new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', 'The request doesnt contain either Billing Account or Customer Or Depot');  
            } 
            
        } catch(Exception ex) {
            return new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', ex.getMessage()); 
        }   
        
        try {
            //Insert the Booking Record
            PUD_Booking__c booking= new PUD_Booking__c();
            booking.Location__c =requestLocation;
            booking.Customer__c=requestCustomerId;
            system.debug('Customer before submission:::'+ booking.Customer__c);
            booking.Billing_Account__c=requestAccount.Id;
            system.debug('Billing Account before submission:::'+ booking.Billing_Account__c);
            booking.Effective_Date__c= Date.valueOf(requestDate);
            booking.Earliest_Start_Time__c = myStartTime;
            booking.Latest_End_Time__c= myEndTime;
            booking.Contact_Phone_Number__c=requestContactPhone;
            booking.Contact_Email__c=requestContactEmail;
            booking.Contact_Name__c=requestContactName;
            booking.Depot__c=requestNetwork;
            system.debug('Network before submission:::'+ booking.Depot__c);
            booking.Source_Street__c=requestStreet;
            booking.Source_City__c=requestCity;
            booking.Source_Post_Code__c=requestPostCode;
            booking.Source_State__c=requestState;
            booking.recordtypeId=requestSourceSystem;
            booking.Expiry_Date__c=Date.valueOf(requestDate);
            booking.Booking_Comments__c=requestBookingComments;
            booking.Address_Verified__c=false;
            booking.Revenue_Check__c=requestRevCheck;
            booking.Article_Count__c = requestArticleCount;
            booking.Article_Info__c=allstring;
            insert booking;
            system.debug('The record created successfully:::'+booking.Id);
            //To validate the address passed from MPB by calling AME API
            validateAddressFutureMethod(requestFullAddress,booking.Id); 
            if (errors.isEmpty()) {
                return new PudValidationApiSynchronousResourceResponse(201, 'Record Created Successfully');
            } else {
                system.debug(errors);
                return new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', String.join(errors, '\n'));
            }
        } catch(Exception ex) {
            return new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', ex.getMessage());
        }
    }
    /*
* Validate the Billing Account sourced in the MPB Payload against Salesforce
* Also, check the customer Id associated to Billing account matches with the customer Id on bIlling account existing in salesforce 
*/
    public static Billing_Account__c validateAccount(string legacyId) {        
        
        Billing_Account__c acct=[Select Id,Name,Organisation__c,LEGACY_ID__c from Billing_Account__c where LEGACY_ID__c=:legacyId LIMIT 1];   
        
        if(acct != null){
            return acct;  
        }
        return null;
    }
    
    /*
* Validate the Depot sourced in the MPB Payload against Salesforce
* Check the depot existing in salesforce by querying against Network__c object.
*/
    public static Id validateNetwork(string networkId) {
        Id foundNetworkId = null; 
        
        Network__c ntwk=[Select Id,Name,Org_ID__c from Network__c where Org_ID__c=:networkId LIMIT 1];    
        
        if(ntwk !=null){
            foundNetworkId = ntwk.Id;
        } 
        
        return foundNetworkId;
    }
    
    static AusPostSettings__c addressValidationSetting = AusPostSettings__c.getValues('AMEAddressValidation');
    /*
*FOR PUD MPB Bookings this method will validate Address and obtain confidence and DPID from AME
*/
    @Future(callout=true)
    public static void validateAddressFutureMethod(string fulladdress,string bookingId){
        
        
        List<AMEInitialResponse.Address> addressLst = getDPIDFromAME(fulladdress,bookingId);
        
        //Retrive the DPID from above method and store it in variable
        string DPIDVal=string.valueof(addressLst[0].dpid);
        system.debug('DPID:::'+DPIDVal);
        string conf=addressLst[0].confidence;
        system.debug('confidence value:::'+conf);
        
        //Pass the DPID returned from AME API and perform a get resuest to AME to obtain geo-cordinates
        getGeocoridinates(DPIDVal,conf,bookingId);
        
    }
    
/*FOR PUD MPB Bookings this method will pass Address as input 
* Get DPID and confidence from AME
*/
    public static List<AMEInitialResponse.Address> getDPIDFromAME(string fulladdress,string bookingId) {
        
        List<AMEInitialResponse.Address> addressList = new List<AMEInitialResponse.Address>();
        system.debug('Booking Record Id='+bookingId);
        String url = addressValidationSetting.URL2__c + '?text=' + EncodingUtil.urlEncode(fulladdress, 'UTF-8');
        system.debug('URL:::'+url);
        String body='{"id":"377eac5d-8871-4567-aad1-c38f3cc34858","maxResults":1,"predictive":false,"addresses":[{"id":"2403b1e8-4832-4d39-982f-95d706bdfb2d","text":"'+fulladdress+'"}],"detail":{"singleLine":true}}';
        system.debug('body:::'+body);
        String token=addressValidationSetting.Token__c;
        system.debug('token:::'+token);
        
        //Send the request to AME
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json;charset=UTF-8');
        req.setHeader('AUTH-KEY',token);
        req.setBody(body);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        System.debug(res);
        system.debug('Response Body:::'+res.getBody());
        system.debug('Response status code:::'+res.getStatusCode());
        if (res.getStatusCode() == 200) {
            String jsonString=res.getBody();
            AMEInitialResponse response = (AMEInitialResponse) System.JSON.deserialize(jsonString, AMEInitialResponse.class);
            List<AMEInitialResponse.Result> results=response.results;
            system.debug('Results in  JSON:::'+results);
            addressList=results[0].addresses; 
        }
        else{
            new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', 'POST Call to AME API is unsuccessful');
        }
        return addressList;
    }
    
    /*
*FOR PUD MPB Bookings this method will pass DPID as input 
* Get geo-coridinates from AME
* Update booking record with AME Returned address, latititude, Longitude and Address Vareified Flag values
*/
    public static void getGeocoridinates(string dpid, string confi, string bkgId) {
        
        String url = addressValidationSetting.URL3__c + EncodingUtil.urlEncode(dpid, 'UTF-8') + '?singleLine=true&semiStructured=true&structured=false&upu=false&geo=true&delivery=false';
        system.debug('URL:::'+url);
        String token=addressValidationSetting.Token__c;
        system.debug('token:::'+token);
        
        //Send the request to AME
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('AUTH-KEY', token);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res);
        system.debug('Response Body:::'+res.getBody());
        system.debug('Response status code:::'+res.getStatusCode());
        if (res.getStatusCode() == 200) {
            String jsonAddressString =res.getBody();
            AMEFinalResponse addrResponse = AMEFinalResponse.parse(jsonAddressString); //REQ2529715
            List<AMEFinalResponse.Result> results=addrResponse.results;
            List<AMEFinalResponse.Address> addressAttributes=results[0].addresses;
            List<AMEFinalResponse.GeoDataList> geoVals=addressAttributes[0].geoDataList;
            //system.debug('Lat in  Final JSON:::'+geoVals[0].latitude);
            //system.debug('Lat in  Final JSON:::'+geoVals[0].longitude);
            AMEFinalResponse.SemiStructured addressVals=addressAttributes[0].semiStructured;
            List<String> addressLines= addressVals.addressLines;
			string fullAddress = string.join(addressLines,' ');
            system.debug('Address Lines in  allstring:::'+fullAddress);
            //string finaladdress = 
            //system.debug('Address Line3 in  Final JSON:::'+addressLines[2]);
            PUD_Booking__c booking1= [Select Id,Confidence__c,Address_Verified__c,Street__c,City__c,Post_Code__c,State__c,
                                      Geo__Latitude__s,Geo__Longitude__s from PUD_Booking__c where Id=:bkgId LIMIT 1];
            if(geoVals[0].latitude != null && geoVals[0].longitude !=null){
                booking1.Address_Verified__c=true;
                booking1.Confidence__c=confi;
                booking1.Street__c=fullAddress;
                booking1.City__c=addressVals.locality;
                booking1.Post_Code__c=addressVals.postcode;
                booking1.State__c=addressVals.state;
                booking1.Geo__Latitude__s=geoVals[0].latitude;
                booking1.Geo__Longitude__s=geoVals[0].longitude;
                booking1.DPID__c = addressAttributes[0].dpid;
                booking1.Side_Of_Street_Code__c = addressAttributes[0].deliveryData?.sideOfStreetCode;
                // get street frontage geo data if available
                AMEFinalResponse.GeoDataList frontageGeo = addressAttributes[0].getGeoData(AMEFinalResponse.GEO_FEATURE_TYPE_GNAF_FRONTAGE);
                if (frontageGeo != null) {
                    booking1.Frontage_Geo__Latitude__s = frontageGeo.latitude;
                    booking1.Frontage_Geo__Longitude__s = frontageGeo.longitude;
                }
                update booking1;
            }
            else{
                new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', 'Update Booking Failed');    
            }
        }
        else{
            new PudValidationApiSynchronousResourceResponse(500, 'Error', '500', 'GET Call to AME API is unsuccessful'); 
        }
    }
    
    
    public class PudValidationApiSynchronousResourceResponse extends ResourceAPIService.IResourceResponse {
        
        public PudValidationApiSynchronousResourceResponse(Integer responseCode, String status) {
            this(responseCode, status, '', '');
        }
        
        public PudValidationApiSynchronousResourceResponse(Integer responseCode, String status, String errorCode, String errorMessage) {
            output.put('status', status);
            
            if(!String.isEmpty(errorCode)) {
                output.put('code', errorCode);
            }
            
            if(!String.isEmpty(errorMessage)) {
                output.put('message', errorMessage);
            }
            
            this.responseCode = responseCode;
        }
    }
}