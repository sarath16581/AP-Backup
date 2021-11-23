/*
 * @date 2021-05-12
 * @author avula.jansirani@auspost.com.au
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core 
 * @description Create Billing Account for CA records (FROM APT_CreditAssessmentTrigger)
 *
 */
public class BCABillingAccountCreationController {
    
    public static final string AUTO_APPROVED = 'Auto-Approved' ;
    public static final string CREDIT_ASSESMENT_INITIATION_TYPE_ONLINE = 'Online';
    public static final string CREDIT_ASSESSMENT_STATUS_APPROVED = 'Approved' ;
    
    private static final String SOURCE_SYSTEM='salesforce';
    
    /**
     * method 
     * caIdSet : set of Credit Assessment record Ids
     * This method take the set of Credit Assessment record Ids then make a callout to camunda to create a biiling account
     * */
    public static void createBillingAccount(Set<Id> caIdSet){
        try{
            for(String caId : caIdSet){
                CreateBillingAccountHelper.externalOnboardingRequestWithConnectionDetails extOnboardingReqWithConDetailsWrapper = 
                    CreateBillingAccountController.generateExternalOnboardingRecord(caId, null);
                
                //-- if 'org' is connected 'endpoint' then submit request to camunda
                if(extOnboardingReqWithConDetailsWrapper.connected)
                    submitBillingAccountRequest(caId, extOnboardingReqWithConDetailsWrapper.onboardingRequestId);
            }
        }catch(Exception ex){
            System.debug('Exception in BCABillingAccountCreationController.createBillingAccount() ==>'+ex.getMessage()); 
        }
        
    }
    
     /**
     * Check the conditions to see whether the CA record needs a Billing account creation or not
     * Added by - avula.jansirani@auspost.com.au , 11-05-2021
     * */
    public static Boolean isAllowTocreateBillingAccount(APT_Credit_Assessment__c ca){
        
        if(CREDIT_ASSESMENT_INITIATION_TYPE_ONLINE.equalsIgnoreCase(ca.L2C_Assessment_Type__c) &&
           (AUTO_APPROVED.equalsIgnoreCase(ca.APT_Credit_Assessment_Status__c) || CREDIT_ASSESSMENT_STATUS_APPROVED.equalsIgnoreCase(ca.APT_Credit_Assessment_Status__c)) &&
           String.isBlank(ca.Integration_Status__c) && String.isBlank(ca.Billing_Account__c)) {
               return true;
           }
        
        return false;
    }
    
    /**
     * Submit Billing account request and get the response
   * */
    @future(callout=true)
    public static void submitBillingAccountRequest(string caId, string onboardingRequestId){
        try{
            CreateBillingAccountHelper.BillingAccountWithEmptyfields billingAccountWithEmptyfieldsVar;
            CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetails onboardingReqWrapper;
            billingAccountWithEmptyfieldsVar = CreateBillingAccountController.generateBillingAccountCreationRequestFromCA(caId);
            onboardingReqWrapper = CreateBillingAccountHelper.ExternalOnboardingRequestDetails(billingAccountWithEmptyfieldsVar, onboardingRequestId);
            
            BillingAccountWrapper billingAccount = onboardingReqWrapper.billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails;
            billingAccount.transactionId = onboardingReqWrapper.onboardingRequestId;
            String billingAccountJson = System.JSON.serialize(billingAccount, true);
            String requestObjId = onboardingReqWrapper.billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails.requestObjId;
            
            //submit request and parse the response
            HttpResponse response = BillingAccountService.getInstance().submitRequest(billingAccountJson, onboardingRequestId, SOURCE_SYSTEM);
            parseBillingAccountResponse(response, requestObjId, onboardingRequestId);
            
        }catch(Exception ex){
            System.debug('Exception in BCABillingAccountCreationController.submitBillingAccountRequest()==> '+ex); 
        }
    }
    
    /**
     * parsing the billing account response, update CA and onboarding req objects with response status
   * */
    public static void parseBillingAccountResponse(HttpResponse response, String requestObjId, String onboardingRequestId){
        String status;
        String responseMsg;
        try{
            system.debug('response='+response);
            if (response.getStatusCode() == 202) {
                //success scenario
                status = 'Requested';
            }else{
                //Error scenario
                status = 'Error';
                String errorMag = getErrorMsgFromResponse(response);
                responseMsg = errorMag != ''? errorMag :'Issue with Billing Account Creation';
            }
            
        }catch(Exception ex){
            responseMsg = ex.getMessage();
            System.debug('Exception in parseBillingAccountResponse()==> '+ex); 
        }finally{
            //Update CA and Onboarding record with 'Reuested' or 'Error' status
            CreateBillingAccountHelper.updateCaAndOnboardingObj(requestObjId, onboardingRequestId, status, responseMsg );
        }
    }
    
    /**
     * Get error message from HTTPResponse (in case of error scenario)
     * */
    private static String getErrorMsgFromResponse(HttpResponse response){
        String responseMsg = '';
        String responseString = String.valueOf(response.getBody()); 
        Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(responseString);
       
        if(responseMap.containsKey('errors')){
            for(object ob:  (List<object>)responseMap.get('errors')){
                Map<String, object> errorMaps = (Map<String, object>) ob;
                if(errorMaps.containsKey('detail')){
                    responseMsg  = responseMsg + (String)errorMaps.get('detail');
                }
            }
        }
        return responseMsg;
    }

}