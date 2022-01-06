/**
* @author Naveen Rajanna
* @date 2021-07-07
* @description Controller class for apt_UseOfflineRatesLWC.
* @changelog
* 2021-07-07 - Naveen Rajanna - Created
*/

public with sharing class APT_UseOfflineRatesController {
    
    /**
    * This method will apply adjustments to proposal to use Offline rates and change proposal stage to Generated
    * @param configId contains the Product Config Id for the proposal
    * @param proposal contains the instance of Apttus_Proposal__Proposal__c object
    * @return  `Map<String, String>`
    * @exception throw AuraHandledException
    */
    @AuraEnabled
    public static Map<String, String> save(String configId, Apttus_Proposal__Proposal__c proposal) {
        Map<String, String> outputMap = new Map<String, String>{};
        try {
            if(String.isNotBlank(configId) & proposal != null) {
                //validation call back
                Apttus_Config2.CustomClass.ValidationResult result = Apttus_Config2.CPQWebService.validateCart(configId);
                System.debug(result);
                if(!result.isSuccess){
                    outputMap.put('result', 'error');
                    outputMap.put('message', result.Messages.toString());
                    return outputMap;
                }
                
                //finalize cart
                Apttus_CPQApi.CPQ.FinalizeCartRequestDO finalRequest = new Apttus_CPQApi.CPQ.FinalizeCartRequestDO();
                finalRequest.CartId = configId;
                Apttus_CPQApi.CPQ.FinalizeCartResponseDO finalResponse = Apttus_CPQApi.CPQWebService.finalizeCart(finalRequest);
                
                //Update proposal fields to 'use offline rates' and change stage to Generated
                proposal.APT_Use_Offline_Rates__c = true;
                proposal.Apttus_QPApprov__Approval_Status__c = null;
                proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_GENERATED;
                
                update proposal;
                
                outputMap.put('result', 'success');
                outputMap.put('message', System.Label.APT_Use_Offline_Rates_Success_Message);
            } else {
                outputMap.put('result', 'error');
                outputMap.put('message', System.Label.APT_Use_Offline_Rates_MissingConfig_Message);
            }
            return outputMap;
            
        } catch (Exception e) {
            System.debug('Execption occured on line number'+e.getLineNumber()+'<<<and reason is>>'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}