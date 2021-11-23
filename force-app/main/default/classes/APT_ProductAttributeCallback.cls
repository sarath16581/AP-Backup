/**
Created By - Mahesh Patel
Created Date - 12th Nov, 2020
Last Modified By -
Last Modified Date -
Description - Product Attribute Callback Class
*/
global with sharing class APT_ProductAttributeCallback implements Apttus_Config2.CustomClass.IProductAttributeCallback {

    global void start(Apttus_Config2.ProductConfiguration config) {
        system.debug('***productAttributeCallBack > start() > ' + config);
    }

    global void setDefaults(Apttus_Config2.LineItem lineItem, Apttus_Config2__ProductAttributeValue__c productAttribute) {

        system.debug('***productAttributeCallBack > setDefaults() > productAttribute:' + productAttribute);
        // lineItem is a wrapper class to the lineItem class which we use in product configuration.
        // Take line Item from this wrapper class.
        Apttus_Config2__LineItem__c prodLineItem = lineItem.getLineItemSO();
        system.debug('***productAttributeCallBack > Product Selected: ' + prodLineItem.Apttus_Config2__Description__c);

        Id configurationId = prodLineItem.Apttus_Config2__ConfigurationId__c;

        Apttus_Config2__ProductConfiguration__c prodConfig = [SELECT Apttus_QPConfig__Proposald__r.APT_postcode_suburb__c
                                                                FROM Apttus_Config2__ProductConfiguration__c 
                                                                WHERE Id = :configurationId LIMIT 1];

        system.debug('***productAttributeCallBack > APT_postcode_suburb__c: ' + prodConfig.Apttus_QPConfig__Proposald__r.APT_postcode_suburb__c);
        
        //Set postcode suburb lookup default value from proposal
        if(prodConfig.Apttus_QPConfig__Proposald__r.APT_postcode_suburb__c != null) {
            productAttribute.APT_Post_Code_Suburb__c = prodConfig.Apttus_QPConfig__Proposald__r.APT_postcode_suburb__c;
        }
    }
    
    global void finish() {
        system.debug('***productAttributeCallBack > finish()');
    }
}