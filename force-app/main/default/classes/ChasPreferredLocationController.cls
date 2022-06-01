/**
  * @author       : arjun.singh@auspost.com.au
  * @date         : 19/06/2020
  * @description  : Class is used for PO transfer request. It has methods used to get 
                    near by PO locations fetched from a servive.
--------------------------------------- History --------------------------------------------------
23.03.2020    arjun.singh@auspost.com.au    Created : Change made for roll out of Transfer to another PO
19.01.2021    hara.sahoo@auspost.com.au     Modified : Add query parameter to the endpoint URL, to filter out only Post offices
25.05.2022    mahesh.parvathaneni@auspost.com.au Modified : DDS - 7397 Added WCID from the Locations service
 */
public without sharing class ChasPreferredLocationController {
    /**
     * @Description : Method return the near by PO locations based on given post office post code.
     */
    @AuraEnabled
    public static list<AddressDetails> getNearByPostOfficeAddress(string postCodeVar, String currentLocation){
    list<AddressDetails>  AddressDetailsList = new list<AddressDetails>();
    try{
        AusPostSettings__c setting = AusPostSettings__c.getValues('POTransferRequest');
        Map<string,object> currentLocationMap = (Map<string,object>)JSON.deserializeUntyped(currentLocation);
        Decimal currentLocationLatitude ;
        Decimal currentLocationLongitude ; 
        for(string strKey: currentLocationMap.keySet()){
            if(strKey.equalsIgnoreCase('latitudeStr')){
                currentLocationLatitude = (Decimal)currentLocationMap.get('latitudeStr');
            }else if(strKey.equalsIgnoreCase('longitudeStr')){
                currentLocationLongitude = (Decimal)currentLocationMap.get('longitudeStr');
            }
        }

        Location currentLocationVar = Location.newInstance(currentLocationLatitude, currentLocationLongitude);
        String urlStr = setting.URL__c+postCodeVar+'?AUTH-KEY='+setting.AppKey__c+'&types=PO';
        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(urlStr);
        req.setMethod('GET');
        
        Http h = new Http();
        HttpResponse res = new HttpResponse();
        res = h.send(req);
        AddressDetailsList = parseResponse(res.getbody(), currentLocationVar);
    }catch (Exception e){
        AddressDetailsList.add(new AddressDetails(false,null, null, null, null, null));
    }
        return AddressDetailsList;
    }
    /**
     * @Description : class for capturing business hour details for each PO location
     */
    public class hoursDetails{
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String weekday;
        @AuraEnabled
        public String startTime;
        @AuraEnabled
        public String endTime;
        public hoursDetails(String typeVar, String weekdayVar, String startTimeVar, String endTimeVar){
            type = typeVar;
            weekday = weekdayVar;
            startTime = startTimeVar;
            endTime = endTimeVar ;
        }
    }
    /**
     * @Description : Class used to construct list of an Object which has 
     *                1. PO Address
     *                2. PO Title
     *                3. Distance between user and PO location
     *                4. Boolean to confirm that PO exist
     *                5. business hour details corresponding to each post f
     *                6. work center id
     */
    public class AddressDetails{
        @AuraEnabled
        public Boolean postOfficeAvailable{get;set;}
        @AuraEnabled
        public String title{get;set;}
        @AuraEnabled
        public String address{get;set;}
        @AuraEnabled
        public Decimal distanceBetweenLocation{get;set;}
        @AuraEnabled
        public list<hoursDetails> hoursDetailsList{get;set;}
        @AuraEnabled
        public String wcid{get;set;}
        public AddressDetails(Boolean postOfficeAvailableVar, String titleVar, String addressVar, Decimal distanceBetweenLocationVar, list<hoursDetails> hoursDetailsListVar, String wcidVar){
            address = addressVar;
            title =  titleVar;
            postOfficeAvailable = postOfficeAvailableVar;
            distanceBetweenLocation = distanceBetweenLocationVar;
            hoursDetailsList = hoursDetailsListVar;
            wcid = wcidVar;
        }
        
    }
    /**
     * @Description: Method for parsing the result lists return from location api.
     *               Service returns below informations.
     *               a. Post Offices with Address and Title
     *               b. Post Office geo location
     *               c. Post Office business hours details
     */
    private static list<AddressDetails> parseResponse(String resBody, Location currentLocation){

        list<AddressDetails> AddressDetailsList = new list<AddressDetails>();
        Map<String,Object> gr = (Map<String,Object>)JSON.deserializeUntyped(resBody);
        List<Object> results = (List<Object>)gr.get('points');
        if(!results.isEmpty()){
            for(object obj: results){
                Map<string,object> objValue =  (Map<string,object>) obj ;
                String fullAddressDetails ;
                Decimal distanceInKM ;
                list<hoursDetails> hoursDetailsList = new list<hoursDetails>();
                String wcid;
                if(objValue.containsKey('geo_location')){
                    object geoLocationValue = objValue.get('geo_location'); 
                    Map<string,object> geoLocationMap = (Map<string,object>) geoLocationValue ;
                    Decimal geoLatitude = (Decimal)geoLocationMap.get('lat');
                    Decimal geoLongitude = (Decimal)geoLocationMap.get('lon');
                    if(geoLatitude != null && geoLongitude != null){
                        location postOfficeLoc = Location.newInstance(geoLatitude, geoLongitude);
                        distanceInKM = Location.getDistance(currentLocation, postOfficeLoc, 'km');
                        if(distanceInKM != null){
                            distanceInKM = distanceInKM.setScale(2);
                        }
                    }
                }
                if(objValue.containsKey('hours')){
                    list<object> hoursData = new list<object>();                    
                    hoursData = (list<object>)objValue.get('hours');
                    hoursDetailsList = getHoursDetails(hoursData);
                }
                //added wcid from the repsonse
                if (objValue.containsKey('work_centre_id') && String.isNotBlank(String.valueOf(objValue.get('work_centre_id')))) {
                    wcid = String.valueOf(objValue.get('work_centre_id'));
                }
                if(objValue.containsKey('address')){
                    object addressValue = objValue.get('address');
                    Map<string,object> addressMap = (Map<string,object>) addressValue ;
                    String addressLine = (String)addressMap.get('address_line_1');
                    String suburbStr = (String)addressMap.get('suburb');
                    String stateStr = (String)addressMap.get('state');
                    String postcode = (String)addressMap.get('postcode');
                    String title = (String)objValue.get('name');
                
                    fullAddressDetails = addressLine + ', ' + suburbStr + ', ' + stateStr + ', ' + postcode;
                    AddressDetailsList.add(new AddressDetails(true,title, fullAddressDetails, distanceInKM, hoursDetailsList, wcid));
                }else{
                    AddressDetailsList.add(new AddressDetails(false,null, null, null, null, null));
                }
            }
        }else{
            AddressDetailsList.add(new AddressDetails(false,null, null, null, null, null));
        }
        return AddressDetailsList ;
    }

    private static list<hoursDetails> getHoursDetails(list<object> hoursData){
        list<hoursDetails> hoursDetailsList = new list<hoursDetails>() ;
        for(object hrObject : hoursData){
            Map<string,object> hrObjectMap = (Map<string,object>) hrObject ;
            String typeStr = hrObjectMap.containsKey('type')? (String)hrObjectMap.get('type'): null ;
            if(typeStr.equalsIgnoreCase('HOURS')){
                String weekdayStr = hrObjectMap.containsKey('weekday')?(String)hrObjectMap.get('weekday'): null ;
                String startTimeStr = hrObjectMap.containsKey('start_time')?(String)hrObjectMap.get('start_time'): null ;
                Time StartTimeVar = fetchTime(startTimeStr);
                String formattedStartTime = getformattedTime(StartTimeVar);
                String endTimeStr = hrObjectMap.containsKey('end_time')?(String)hrObjectMap.get('end_time'): null ;
                Time endTimeVar = fetchTime(endTimeStr);
                String formattedEndTime = getformattedTime(endTimeVar);
                hoursDetails hoursDetailsRecord = new hoursDetails(typeStr, weekdayStr, formattedStartTime, formattedEndTime);
                hoursDetailsList.add(hoursDetailsRecord);
            }
        }
        return hoursDetailsList;
    }  
    
    private static Time fetchTime(String timeStr){
        Time timeVar;
        if(timeStr != null){
            list<string> timeList = timeStr.split(':');
            if(!timeList.isEmpty()){
                integer hrValue = integer.valueOf(timeList[0]);
                integer minuteValue = integer.valueOf(timeList[1]);
                timeVar = Time.newInstance(hrValue, minuteValue, 0, 0);                
            }
        }
        return timeVar ;
    }
    
    private static string getformattedTime(Time timeVar){
        String formatTimeStr;
        Datetime currentDateTime = Datetime.newInstance(Date.today(), timeVar);
        String formatTime = currentDateTime.format('h:mm a');
        formatTimeStr = formatTime.replace('AM', 'am').replace('PM','pm');
        return formatTimeStr;
    }
}