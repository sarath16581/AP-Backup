/**
 * @description       : This class will be called from APT_DoVLanguage Trigger.
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-21-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-21-2021   Mansi Shah   Initial Version
**/
public class APT_DovLanguageTriggerHandler {
    public static void afterInsert(List<APT_DoV_Language__c> newListDoVLanguages){
       APT_DovLanguageTriggerHelper.setDoVLanguageOnAgreement(newListDoVLanguages,null,null);
    }
    
     public static void afterUpdate(Map<Id,APT_DoV_Language__c> oldMap,Map<Id,APT_DoV_Language__c> newMap){
       APT_DovLanguageTriggerHelper.setDoVLanguageOnAgreement(null,oldMap,newMap);
    }   
}