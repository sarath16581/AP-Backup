/**
 * This class is only to support continuous calls from lightning components,
 * ApexContinuation callout framework will be used to make asyc callouts from lightning,
 * any VF related callouts must be implemented outside of this class, this should not support any Aura functionality
 * History:
 *      Created by hasantha on 24/09/2018.
 */

public with sharing class Cognition_IAsynchApexContinuationImpl implements IAsynchApexContinuationREST{

    public static CustomerCognitionSettings__c customerCognitionSettings {
        get {
            if (customerCognitionSettings == null) {
                customerCognitionSettings = CustomerCognitionSettings__c.getOrgDefaults();
            }
            return customerCognitionSettings;
        }
        set;
    }

    /**
     * Implementation of setHTTPrequest,
     * setting the request will the specific call method will prepare the http request to send out in a continuous call,
     *
     * @param request
     * @param classNameStr
     * @param methodName this should be used to determine which endpoint needs to be called
     * @param params the parameters for the endpoint need to be appended
     */
    public void setHTTPRequest(HttpRequest request, String classNameStr, String methodName, String[] params) {
        CustomerCognitionSettings__c customerCognitionSettings = CustomerCognitionSettings__c.getOrgDefaults();
        String requestBody = '';

                System.debug('params>>>'+params);
        try {
            // Consignment info related request parameter preparation
            if(methodName == 'ConsignmentInfo') {
                Cognition_DataModel.ConsignmentInfoRequest objConsignmentInfoRequest = new Cognition_DataModel.ConsignmentInfoRequest();
                objConsignmentInfoRequest.RequestGUID = params[0];
                objConsignmentInfoRequest.Consignment = params[1];
                objConsignmentInfoRequest.ClientIpAddress = '::1';
                objConsignmentInfoRequest.ClientUserName = UserInfo.getUserName();

                requestBody = JSON.serialize(objConsignmentInfoRequest);
                // Customer Details related request parameter preparation
            } else if(methodName == 'CustomerDetails') {
                // prepare for call CustomerDetails
                Cognition_DataModel.CustomerViewDetailRequest objCustomerViewDetailRequest = new Cognition_DataModel.CustomerViewDetailRequest();
                objCustomerViewDetailRequest.RequestGUID =  params[0];
                objCustomerViewDetailRequest.FromSeq =  Integer.valueof(params[1]);
                objCustomerViewDetailRequest.ToSeq =  Integer.valueof(params[2]);
                requestBody = JSON.serialize(objCustomerViewDetailRequest);
            } else if(methodName == 'PickupInfo'){
                // prepare for call pickup info callout
                Cognition_DataModel.PickupInfoRequest objPickupInfoRequest = new Cognition_DataModel.PickupInfoRequest();
                objPickupInfoRequest.RequestGUID = params[0];
                objPickupInfoRequest.BookingNbr = params[1];
                objPickupInfoRequest.ClientIpAddress = '::1';
                objPickupInfoRequest.ClientUserName = UserInfo.getUserName();

                requestBody = JSON.serialize(objPickupInfoRequest);
            }

            System.debug('jsonRequest>>>'+requestBody);
            // prepare the request
            String authorizationHeader = 'Basic ' + customerCognitionSettings.BasicAuthnHeader__c;
            request.setHeader('Authorization', authorizationHeader);
            request.setHeader('Content-Type', 'application/json');
            // get the api name, method name must be the api name defined in the custom setting
            CognitionAPIs__c api = CognitionAPIs__c.getInstance(methodName);
            // system wide callout time out setting
            CognitionAPIs__c timeoutRecord = CognitionAPIs__c.getInstance('Timeout');
            request.setTimeout(Integer.valueof(timeoutRecord.Timeout__c));
            // Set request parameters
            request.setMethod('POST');
            request.setEndpoint(customerCognitionSettings.EndPoint__c + api.API_Name__c);
            // If the callout includes a body (POST and PUT requests)
            if (String.isNotBlank(requestBody)) {
                // Set the body to the callout
                request.setBody(requestBody);
            }
        } catch (exception e){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Cognition_IAsynchApexContinuationImpl', Cognition_IAsynchApexContinuationImpl.class.getName(), 'loadCparseResponseonfigs',
                    null, LoggingLevel.ERROR
            );
        }
    }

    public Integer getTimeOut() {
        return 120;
    }

    /**
     * Parse the response based on the method name passed.
     * @param response
     * @return
     */
    public Object parseResponse(HttpResponse response) {

        try {
            // access the response
            String jsonResponse = response.getBody();
            Integer statusCode = response.getStatusCode();

            // status code check
            if (statusCode >= 2000) {
                System.debug('Data Async Callout Error : ' + statusCode);
                return null;
            }

            // parse the full response and get the payload
            jsonResponse = response.getBody();
            HttpResponseInfo responseInfo = (HttpResponseInfo) System.JSON.deserialize(jsonResponse, HttpResponseInfo.class);

            System.debug('responseInfo : ' + responseInfo);

            // TODO: error handeling based on parameters passed through response
            if(responseInfo.methodName == 'ConsignmentInfo') {
                // parse the consignment details to pass to client
                Cognition_DataModel.CustomerViewConInfo consignmentDetails = (Cognition_DataModel.CustomerViewConInfo) System.JSON.deserialize(responseInfo.payload, Cognition_DataModel.CustomerViewConInfo.class);
                // interpret for data formatting in apex
                consignmentDetails.EventDateTime = Cognition_Util.convertTimeStamp(consignmentDetails.EventDateTime);
                consignmentDetails.DespatchDate = Cognition_Util.convertTimeStamp(consignmentDetails.DespatchDate);
                consignmentDetails.ETADateTime = Cognition_Util.convertTimeStamp(consignmentDetails.ETADateTime);
                consignmentDetails.PredictedETADateTime = Cognition_Util.convertTimeStamp(consignmentDetails.PredictedETADateTime);

                return consignmentDetails;
            } else if(responseInfo.methodName == 'CustomerDetails'){
                // parse the response
                List<Cognition_DataModel.CustomerViewDetailResponseV2> customerDetailResponseList = (List<Cognition_DataModel.CustomerViewDetailResponseV2>) System.JSON.deserialize('['+responseInfo.payload+']', List<Cognition_DataModel.CustomerViewDetailResponseV2>.class);

                List<Cognition_DataModel.cls_ConInfo> conInfoList = new List<Cognition_DataModel.cls_ConInfo>();
                for(Cognition_DataModel.CustomerViewDetailResponseV2 custDetail : customerDetailResponseList){
                    for(Cognition_DataModel.cls_ConInfo conInfo : custDetail.ConInfo){
                        conInfoList.add(conInfo);
                    }
                }
                Cognition_DataModel.CustomerDetailsResponse CustomerViewWrapper = new Cognition_DataModel.CustomerDetailsResponse();
                CustomerViewWrapper.conInfo = conInfoList;
                return CustomerViewWrapper;
            }else if(responseInfo.methodName == 'PickupInfo'){
                // parse the consignment details to pass to client
                Cognition_DataModel.CustomerViewPickupInfo pickupDetails = (Cognition_DataModel.CustomerViewPickupInfo) System.JSON.deserialize(responseInfo.payload, Cognition_DataModel.CustomerViewPickupInfo.class);
                // interpret for data formatting in apex
                pickupDetails.EventDateTime = Cognition_Util.convertTimeStamp(pickupDetails.EventDateTime);
    			pickupDetails.ReadyTime = Cognition_Util.convertTimeStamp(pickupDetails.ReadyTime);
    			pickupDetails.CloseTime = Cognition_Util.convertTimeStamp(pickupDetails.CloseTime);
    			return pickupDetails;
            }
        } catch (exception e){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Cognition_IAsynchApexContinuationImpl', Cognition_IAsynchApexContinuationImpl.class.getName(), 'loadCparseResponseonfigs',
                    null, LoggingLevel.ERROR
            );
        }

        return null;
    }


    public with sharing class HttpResponseInfo{
        public string payload { get; set; }
        public string [] params { get; set; }
        public string []errorList { get; set; }
        public string className { get; set; }
        public string methodName { get; set; }
    }

}