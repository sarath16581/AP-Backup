/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Helper for createBillingAccount component and used for billing account creation
 * @changelog
 * 2020-11-18 - arjun.singh@auspost.com.au - Created
 * 2021-05-12 - avula.jansirani@auspost.com.au - added submitRequest() method
 * 2022-08-04 - Seth Heang - Updated parseResponse method to handle rating plan activation changes
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
     * @description		Parse the response returned as a part of billing account creation and rating plan activation creation
	 * @param			HttpResponse response, 
	 * @param 			String requestObjId, 
	 * @param			String chargeAccountRequestId, 
	 * @param			String onboardingRequestId, 
	 * @param			CreateBillingAccountControllerForTeams.contractDetail contractDetails, 
	 * @param			CreateBillingAccountController.ratingPlanInfo specify rating plan detail for new customer or existing customer flow and if APPC product exists
	 * @return			Boolean; true for callout success or false for callout failure
     */
    public Boolean parseResponse(HttpResponse response , String requestObjId, String chargeAccountRequestId, String onboardingRequestId, CreateBillingAccountControllerForTeams.contractDetail contractDetails, CreateBillingAccountController.ratingPlanInfo ratingPlanDetails) {
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
                    //Team flow
                    CreateTeamsBillingAccountHelper.updateDSRAndChargeAccountAndContract(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg, contractDetails);
                }
                else{
                    //SAP flow
                    CreateBillingAccountHelper.updateDSRAndChargeAccount(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg, ratingPlanDetails);
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
                // error response for billing account flow
                if(responseMsg == null && chargeAccountRequestId != null){
                    responseMsg = 'Issue with Billing Account Creation';
                }
                // error response for rating plan flow
                else if(responseMsg == null && chargeAccountRequestId == null){
                    responseMsg = 'Issue with Rating Plan Activation Creation';
                }
                if(contractDetails !=null){
                    CreateTeamsBillingAccountHelper.updateDSRAndChargeAccountAndContract(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg, contractDetails);
                }
                else{
                    CreateBillingAccountHelper.updateDSRAndChargeAccount(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg, ratingPlanDetails);
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
                CreateBillingAccountHelper.updateDSRAndChargeAccount(requestObjId, chargeAccountRequestId, onboardingRequestId, status, responseMsg, ratingPlanDetails);
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