/**
 * Commenting class as not needed now and 
 * Description: This apex class if helper class for apex class - APT_ConfigurationTriggerHandler.
 * Created By: Darshan Chauhan 
 * Created Date: 18th May, 2021
 */
public with sharing class APT_ConfigurationTriggerHelper {

    // public static boolean isRecurssionCartConfiguration = false;
    // public static Map<String, String> previousApprovalStatusValue = new Map<String, String>();

    // public static void updateCartOnApproval(String cartId){

    //     List<Apttus_Config2__ProductConfiguration__c> configs = [SELECT id, Apttus_Config2__IsPricePending__c, APT_STE_Pricing_Tier__c 
    //                                                             from Apttus_Config2__ProductConfiguration__c WHERE id =: cartId];

    //     System.debug('configs >>> DC >>>'+configs);

    //     List<Apttus_Config2__ProductAttributeValue__c> pvaObjList = new List<Apttus_Config2__ProductAttributeValue__c>();
    //     pvaObjList = [SELECT Id, APT_Tier_Approved__c,APT_Approved_Tier_After_Adjustment__c,APT_Tier__c from Apttus_Config2__ProductAttributeValue__c WHERE 
    //             Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c =: cartId ];
    //     if(!pvaObjList.isEmpty()){
    //         for( Apttus_Config2__ProductAttributeValue__c pvaObj : pvaObjList ){
    //             pvaObj.APT_Tier_Approved__c = TRUE;
    //             pvaObj.APT_Tier__c =pvaObj.APT_Approved_Tier_After_Adjustment__c;
    //         }
    //         update pvaObjList;
    //     }        
    //     System.debug('pvaObjList >>> DC >>>'+pvaObjList);
        
    //     //addding CR logic here
    //     Apttus_CPQApi.CPQWebService.associateConstraintRules(cartId,null);
    //     Apttus_CPQApi.CPQWebService.applyConstraintRules(cartID, false);
    //     Apttus_CPQApi.CPQ.ConstraintResultDO constraintResult = Apttus_CPQApi.CPQWebService.getConstraintRuleResult(cartID);
    //     if(constraintResult.NeedMoreProcessing)
    //     {
    //         Apttus_CPQApi.CPQWebService.associateConstraintRules(cartId,null);
    //         Apttus_CPQApi.CPQWebService.applyConstraintRules(cartID, false);
    //     } // CR logic ends
        
    //     Apttus_Config2__ProductConfiguration__c configToBeUpdated = new Apttus_Config2__ProductConfiguration__c();
    //     configToBeUpdated.Id = configs[0].Id;
    //     configToBeUpdated.Apttus_Config2__IsPricePending__c = true;
    //     update configToBeUpdated;
    //     System.debug('configs >>> DC >>>'+configToBeUpdated);
    //     Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
    //     objUpdatePriceRequestDO.CartId = cartId;
    //     Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
    //     System.debug('Reprice Result '+result);
        
    //     Apttus_CpqApi.CPQ.FinalizeCartRequestDO request = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
    //     // add request parameters
    //     request.CartId = cartId;
    //     // finalize the cart
    //     Apttus_CpqApi.CPQ.FinalizeCartResponseDO response = Apttus_CpqApi.CPQWebService.finalizeCart(request);
    // }

}