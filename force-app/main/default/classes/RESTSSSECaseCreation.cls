/* Version      Author                      Description
*   1.0         Bharat P        REST API class for consuming request from Tibco for creation of
*                               Case and other related object records and sending a response for 
*                               Startrack Special Services and Security Express.
*/

@RestResource(urlMapping='/v1.0/request/SSSECaseJob')
global with sharing class RESTSSSECaseCreation{
    
    //Creation of a new startrack special services and security express case
    @HttpPost
    global static void createNewSSSECase(){
        
        //Roll back save point
        Savepoint sp = Database.setSavepoint();
        
        //Request Json Message received from TIBCO
        String requestMsg = RestContext.request.requestBody.toString();
        try{
            
            //Deserialization of the request message to be read
            Map<String, Object> reqData = (Map<String, Object>)JSON.deserializeUntyped(requestMsg);
            Map<String, String> mapStr = new Map<String, String>();
            List<Map<String, String>> lstMapStr = new List<Map<String, String>>();
            List<Map<String, Object>> lstMapObj = new List<Map<String, Object>>();
            
            //Retrieving Freight Items data request from the request message received
            List<Object> lstObjFI = (List<Object>) reqData.get('freightitems');
            
            //Case Number retrieved to pass to TIBCO as part of response message
            String caseNum = newSSSECaseData(reqData, lstObjFI);
            
            //Check if any of the details are missing in the JSON request received and throw an exception
            if(caseNum == null){
                throw new DMLException('Case or Job or Freight Item details missing in the request');           
            }
            
            //Success response message
            RESTSSSEResponse respSSSE = new RESTSSSEResponse(true,'','success','201',caseNum);
            
            //Serializing the successful response message
            serializeSSSEResp(respSSSE);
            
        }catch(Exception ex){
            
            //Roll Back of data in case of failure
            Database.rollback(sp);
            
            //Failure response message with the response code passed to TIBCO
            RESTSSSEResponse respSSSE = new RESTSSSEResponse(false,ex.getMessage(),'fail','500','');
            
            //Serializing the failed response message
            serializeSSSEResp(respSSSE);
            
            //Logging of the exception in Application Logs object with the exception details
            GlobalUtility.logMessage('ERROR','RESTSSSECaseCreation','createNewSSSECase','','Exception',ex.getMessage(),requestMsg,ex,0);
        }
    }
    
    //Method for creation of a new case with Request Data and List of Freight Items as Input pparameters
    private static string newSSSECaseData(Map<String, Object> requestData, List<Object> listObjFI){
        
        Case cseRec = null;        
        Job__c jobRec = null;
        Id recordTypeIdJob = null;
        Id ownerQueueId = null;
        FreightItem__c freightItemRec = null;
        String FI = 'FreightItem__c';
        List<FreightItem__c> lstFReightItems = new List<FreightItem__c>();
        
        //Initiation of List of Freight Items
        List<FreightItem__c> lstObjFITemp = new List<FreightItem__c>();
        
        //Retrieving the custom metadata type - SSSE Field Mapping
        DescribeSObjectResult describeResult = SSSE_Field_Mapping__mdt.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());

        //Dynamic select query for querying all the fields in the custom metadata type         
        String mappingQuerySSSE = 'SELECT ' + String.join(fieldNames, ',' ) + ' FROM ' + describeResult.getName();
        
        //Dynamic select query for querying all the fields in the custom metadata type only for freight item object
        String mappingQuerySSSEFI = 'SELECT ' + String.join(fieldNames, ',' ) + ' FROM ' + describeResult.getName() + ' Where Actual_Field_Object_API_Name__c =: FI';       
        
        //Retrieving the case details from the request message
        Map<String,Object> dataCase = (Map<String,Object>)requestData.get('case');
        
        //Retrieving the job details from the request message
        Map<String,Object> dataJob = (Map<String,Object>)requestData.get('job');
        
        //Retrieving case record type id for startrack special services and security express
        Id recordTypeIdSSSE = Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf(dataJob.get('Job_Type__c'))).getRecordTypeId();
        
        //For loop on the custom metadata records
        for(SSSE_Field_Mapping__mdt mappingSSSE : Database.query(mappingQuerySSSE)){
            
            //Check if the record is related to case object
            if(mappingSSSE.Actual_Field_Object_API_Name__c.equalsIgnoreCase('Case')){                
                if(requestData.get('case') != null && dataCase.get(mappingSSSE.Request_Field_Name__c) != null){
                    if(cseRec == null){
                        cseRec = new Case();
                        cseRec.RecordTypeId = recordTypeIdSSSE;
                    }
                    
                    //Check for date type field records for parsing and converting to string
                    if(mappingSSSE.Field_Data_Type__c != null && mappingSSSE.Field_Data_Type__c.equalsIgnoreCase('Date')){
                        cseRec.put(mappingSSSE.Actual_Field_Name__c, Date.parse(String.valueOf(dataCase.get(mappingSSSE.Request_Field_Name__c))));
                        
                    //Check for datetime type field records for parsing and converting to string
                    }else if(mappingSSSE.Field_Data_Type__c != null && mappingSSSE.Field_Data_Type__c.equalsIgnoreCase('DateTime')){
                        cseRec.put(mappingSSSE.Actual_Field_Name__c, DateTime.parse(String.valueOf(dataCase.get(mappingSSSE.Request_Field_Name__c))));    
                    
                    }else{
                        cseRec.put(mappingSSSE.Actual_Field_Name__c, dataCase.get(mappingSSSE.Request_Field_Name__c));    
                    }
                }
            //Check if the record is related to the custom Job object    
            }else if(mappingSSSE.Actual_Field_Object_API_Name__c.equalsIgnoreCase('Job__c')){
                if(requestData.get('job') != null && dataJob.get(mappingSSSE.Request_Field_Name__c) != null){
                    if(jobRec == null){
                        jobRec = new Job__c();
                    }
                    
                    //Check for date type field records for parsing and converting to string
                    if(mappingSSSE.Field_Data_Type__c != null && mappingSSSE.Field_Data_Type__c.equalsIgnoreCase('Date')){
                        jobRec.put(mappingSSSE.Actual_Field_Name__c, Date.parse(String.valueOf(dataJob.get(mappingSSSE.Request_Field_Name__c))));    
                    
                    //Check for datetime type field records for parsing and converting to string
                    }else if(mappingSSSE.Field_Data_Type__c != null && mappingSSSE.Field_Data_Type__c.equalsIgnoreCase('DateTime')){
                        jobRec.put(mappingSSSE.Actual_Field_Name__c, DateTime.parse(String.valueOf(dataJob.get(mappingSSSE.Request_Field_Name__c))));   
                    
                    }else{
                        jobRec.put(mappingSSSE.Actual_Field_Name__c, dataJob.get(mappingSSSE.Request_Field_Name__c));    
                    }                                       
                }                
            }
        }
        
        //Retrieve the Freight Item details from the request message
        if(requestData.get('freightitems') != null){
            
            //Iterating over the list of freight items
            for(Object obj : listObjFI){
                freightItemRec = new FreightItem__c();
                Map<String,Object> dataFI = (Map<String,Object>)obj;
                
                //Iterating over the list of records for Freight Items in the custom metadata
                for(SSSE_Field_Mapping__mdt mappingSSSEFI : Database.query(mappingQuerySSSE + ' Where Actual_Field_Object_API_Name__c =: FI')){
                    if(dataFI.get(mappingSSSEFI.Request_Field_Name__c) != null){
                        
                        //Check for date type field records for parsing and converting to string
                        if(mappingSSSEFI.Field_Data_Type__c != null && mappingSSSEFI.Field_Data_Type__c.equalsIgnoreCase('Date')){                      
                            freightItemRec.put(mappingSSSEFI.Actual_Field_Name__c, Date.parse(String.valueOf(dataFI.get(mappingSSSEFI.Request_Field_Name__c))));    
                        
                        //Check for datetime type field records for parsing and converting to string
                        }else if(mappingSSSEFI.Field_Data_Type__c != null && mappingSSSEFI.Field_Data_Type__c.equalsIgnoreCase('DateTime')){
                            freightItemRec.put(mappingSSSEFI.Actual_Field_Name__c, DateTime.parse(String.valueOf(dataFI.get(mappingSSSEFI.Request_Field_Name__c))));    
                        
                        }else{
                            freightItemRec.put(mappingSSSEFI.Actual_Field_Name__c, dataFI.get(mappingSSSEFI.Request_Field_Name__c));     
                        }
                    }                                                
                }
                
                //Adding each freight item record to a list of freight items
                lstObjFITemp.add(freightItemRec);
            }
        }
        
        //Inserting a case record
        if(cseRec != null){
            insert cseRec;
        }
        
        //Check for null values for case and job record before inserting a job record related to the case
        if(cseRec != null && cseRec.Id != null && jobRec != null){
            jobRec.Case__c = cseRec.Id;
            
            //Retrieving the Job type from the request to fetch the record type id of the Job
            if(Schema.SObjectType.Job__c.getRecordTypeInfosByName().get(String.valueOf(dataJob.get('Job_Type__c'))) != null){
                recordTypeIdJob = Schema.SObjectType.Job__c.getRecordTypeInfosByName().get(String.valueOf(dataJob.get('Job_Type__c'))).getRecordTypeId();
            }
            
            //Assigning the record type to the job
            jobRec.RecordTypeId = recordTypeIdJob;
            
            String jobType = String.valueOf(dataJob.get('Job_Type__c'));
            if (String.isNotBlank(jobType)) {
                ownerQueueId = [select Id from Group where Name =: jobType and Type = 'Queue'].Id;
            }
            
            if (ownerQueueId != null) {
                jobRec.OwnerId = ownerQueueId;
            }
            
            //Inserting the Job record
            insert jobRec;
        }
        
        /*Check for null values for Job and freight item records before inserting a freight item records 
        related to the job*/
        if(jobRec != null && jobRec.Id != null && freightItemRec != null){
            
            //Assigning each freight item to the job
            for(FreightItem__c lst : lstObjFITemp){
                lst.Job__c = jobRec.Id;
                lst.OwnerId = ownerQueueId;
            }
            
            //Inserting a list of freight items related to the job record
            insert lstObjFITemp;
        }
        
        //Checking if any of the object data is null in the request for throwing an exception
        if(cseRec == null || jobRec == null || freightItemRec == null){
            return null;      
        }

        //Query to retrievethe case number of the inserted case record to pass as part of the response message        
        List<Case> CaseNum = [Select CaseNumber from Case Where Id =: cseRec.Id];
        return CaseNum[0].CaseNumber;
    }
    
    //Inner class containing the response variables
    global class RESTSSSEResponse{
        
        //Whether response received is success or failure  
        public Boolean Success;
        
        //Response Message
        public String Message;
        
        //Response Result
        public String Result;
        
        // Response Code for success or failure
        public String StatusCode;
        
        //Case Number generated on successful insertion of case record
        public String CaseNumber;
        
        //Constructor for providing the success or failure response
        public RESTSSSEResponse(Boolean s, String msg, String res, String code, String caseNum){
            
            //Success Response details
            if (s == true){
                this.Message = msg;
                this.Result = res;
                this.StatusCode = code;
                this.CaseNumber = caseNum;
                
            //Failure Response details   
            }else{
                this.Message = msg;
                this.Result = res;
                this.StatusCode = code;
                this.CaseNumber = caseNum;
            }
            this.Success = s;
        }
    }
    
    //Serialization of the json response message
    private static void serializeSSSEResp(Object respSSSE){
        
        //Retrieving the response from the REST API context
        RestResponse res = RestContext.response;
        if (res == null){
            res = new RestResponse();
            RestContext.response = res;
        }
        res.addHeader('Content-Type', 'application/json');
        
        //Blob value of the serialized response
        res.responseBody = blob.valueOf(JSON.serializePretty(respSSSE));
    }
}