/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Helper for createBillingAccount component and used for billing account creation
 * @changelog
 * 2020-11-18 - arjun.singh@auspost.com.au - Created
 * 2021-05-12 - avula.jansirani@auspost.com.au - added submitRequest() method
 */
public with sharing class BillingAccountService {
    public static BillingAccountService getInstance() {
        return (BillingAccountService) Application.Utilities.getInstance(BillingAccountService.class);
    }
    /**
     * @Description : Request generation for Billing Account Creation 
     * */    
    public HttpRequest getRequest(String requestBody , String businessReferenceId, String sourceSystem) {  
        AusPostSettings__c setting = AusPostSettings__c.getValues('CreateBillingAccountCredentials'); 
        //System.debug('setting='+setting);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(setting.URL2__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('businessReferenceId', businessReferenceId);
        request.setHeader('sourceSystemId', sourceSystem);
        request.setBody(requestBody);
        return request;
    }
    public Continuation getContinuation(String requestBody , String businessReferenceId, String sourceSystem) {
        Continuation con = new Continuation(120);
        con.addHttpRequest(getRequest(requestBody, businessReferenceId, sourceSystem));
        return con;
    }
    /**
     * @Description: Parse the respons returned as a part of billing account creation
     */
    public Boolean parseResponse(HttpResponse response , String requestObjId, String chargeAccountRequestId, String onboardingRequestId, CreateBillingAccountControllerForTeams.contractDetail contractDetails ) {
        String status;
        String responseMsg;
        Boolean callOutSuccess = false;
        try{
            //system.debug('**Before success status**'+response.getStatusCode());
            if (response.getStatusCode() == 202) {
                //system.debug('**Inside success status**');
                status = 'Requested';
                callOutSuccess = true;
                if(contractDetails !=null){
                    CreateTeamsBillingAccountHelper.updateDSRAndChargeAccountAndContract(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg, contractDetails);
                }
                else{
                    CreateBillingAccountHelper.updateDSRAndChargeAccount(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg);
                }

            } else {
                status = 'Error';            
                String responseString = String.valueOf(response.getBody()); 
                Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(responseString);
                if(responseMap.containsKey('errors')){
                    Object errObject = responseMap.get('errors');
                    System.debug('errObject>>'+errObject);
                    List<object> errorMap = (List<object>) errObject;
                    for(object ob: errorMap){
                        Map<String, object> errorMaps = (Map<String, object>) ob;
                        if(errorMaps.containsKey('detail')){
                            responseMsg  = (String)errorMaps.get('detail');
                        }
                    }
                }
                if(responseMsg == null){
                    responseMsg = 'Issue with Billing Account Creation';
                }
                if(contractDetails !=null){
                    CreateTeamsBillingAccountHelper.updateDSRAndChargeAccountAndContract(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg, contractDetails);
                }
                else{
                    CreateBillingAccountHelper.updateDSRAndChargeAccount(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg);
                }
            }
        
        }catch(Exception e){
            system.debug('*** Exception Message ****'+e.getMessage());
            status = 'Error'; 
            responseMsg = 'Issue with Billing Account Creation 1';
            if(contractDetails !=null){
                CreateTeamsBillingAccountHelper.updateDSRAndChargeAccountAndContract(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg, contractDetails);
            }
            else{
                CreateBillingAccountHelper.updateDSRAndChargeAccount(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg);
            }
        }
        return callOutSuccess;
    }
    
     /**
     * @Description : submitRequest 
     * */    
    public HttpResponse submitRequest(String requestBody , String businessReferenceId, String sourceSystem) { 
         return new Http().send(getRequest(requestBody, businessReferenceId, sourceSystem));
    }
    
    
}