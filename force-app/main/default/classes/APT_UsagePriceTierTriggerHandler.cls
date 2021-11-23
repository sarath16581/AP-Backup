/**
Description: This class is handler class of apex trigger - APT_UsagePriceTierTrigger
CreatedBy - Mausam Padhiyar
Created Date - 21st June, 2016
*/
public with sharing class APT_UsagePriceTierTriggerHandler {
    /**
      Method for before update event
    **/
    public static String beforeUpdateEvent(list<Apttus_Config2__UsagePriceTier__c> listUsagePriceTier) {
        try {
            set<Id> setLineItemId = new set<Id>();
            for(Apttus_Config2__UsagePriceTier__c upt : listUsagePriceTier) {
                setLineItemId.add(upt.Apttus_Config2__LineItemId__c);
            }
            
            map<Id, Apttus_Config2__LineItem__c> mapLineItem = new map<Id, Apttus_Config2__LineItem__c>([SELECT Id, Apttus_Config2__ProductId__r.ProductCode,
                                                                                                        Apttus_Config2__AdjustmentAmount__c, 
                                                                                                        APT_Rate_Card_Key__c
                                                                                                        FROM Apttus_Config2__LineItem__c 
                                                                                                        WHERE Id IN :setLineItemId]);
            for(Apttus_Config2__UsagePriceTier__c upt : listUsagePriceTier) {
                Apttus_Config2__LineItem__c li = mapLineItem.get(upt.Apttus_Config2__LineItemId__c);
                if(li != null && !String.isEmpty(li.Apttus_Config2__ProductId__r.ProductCode) 
                    && ((li.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE) && !String.isEmpty(li.APT_Rate_Card_Key__c) && li.Apttus_Config2__AdjustmentAmount__c != null)
                    || (li.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) && !String.isEmpty(li.APT_Rate_Card_Key__c) && li.Apttus_Config2__AdjustmentAmount__c != null)
                    || (li.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) && !String.isEmpty(li.APT_Rate_Card_Key__c) && li.Apttus_Config2__AdjustmentAmount__c != null))) {
                    
                    upt.Apttus_Config2__UsageRate__c = upt.Apttus_Config2__PriceOverride__c;    //update unit price
                }
            }
            
        } catch(system.Exception ex) {
            return ex.getMessage();
        }
        
        return APT_Constants.SUCCESS_LABEL;
    }
}