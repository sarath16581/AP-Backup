/**
 * @description       : This class will be called from APT_DoVLanguageTriggerHandler
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-21-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-21-2021   Mansi Shah   Initial Version
**/
public class APT_DovLanguageTriggerHelper {

    /**
    * @description: This method will update the DoV Language on Agreement record based on DoV Language records associated with the Agreement 
    * @author Mansi Shah | 05-21-2021 
    * @param newList 
    * @param oldMap 
    * @param newMap 
    **/
    public static void setDoVLanguageOnAgreement(List<APT_DoV_Language__c> newList,Map<Id,APT_DoV_Language__c> oldMap,Map<Id,APT_DoV_Language__c> newMap){
        Set<Id> setOfAgreementIds = new Set<Id>();

        //This part will execute in After Insert method
        if(newList != null){
            for(APT_DoV_Language__c oDovLanguage : newList){
                if(oDoVLanguage.APT_DoV_Product__c != null && oDoVLanguage.APT_DoV_Action__c != null && oDoVLanguage.APT_Contract__c != null)
                {
                    setOfAgreementIds.add(oDoVLanguage.APT_Contract__c);
                }
            }
        }

        //This part will execute in After Update method
        if(newMap != null){
            for(APT_DoV_Language__c oDovLanguage : newMap.values()){
                if(oldMap.containsKey(oDoVLanguage.Id) && 
                    oDoVLanguage.APT_DoV_Product__c != null && oDoVLanguage.APT_DoV_Action__c != null &&
                    (oldMap.get(oDoVLanguage.Id).APT_DoV_Product__c != oDoVLanguage.APT_DoV_Product__c ||
                    oldMap.get(oDoVLanguage.Id).APT_DoV_Action__c != oDoVLanguage.APT_DoV_Action__c))
                {
                    setOfAgreementIds.add(oDoVLanguage.APT_Contract__c);
                }
            }
        }

        if(setOfAgreementIds != null){
            //Query DoV Language Records
            List<APT_DoV_Language__c> listOfDoVLanguages = new List<APT_DoV_Language__c>();
            listOfDoVLanguages = [SELECT Id,APT_Contract__c,APT_DoV_Product__c,APT_DoV_Action__c 
                                    FROM APT_DoV_Language__c
                                    WHERE APT_Contract__c IN: setOfAgreementIds];
            
            Map<Id,List<APT_DoV_Language__c>> mapOfAgreementIdAndDovLanguageList = new Map<Id,List<APT_DoV_Language__c>>();
            if(listOfDoVLanguages != null && !listOfDoVLanguages.isEmpty())
            {
                List<Apttus__APTS_Agreement__c> listOfAgreementToUpdate = new List<Apttus__APTS_Agreement__c>();
                for(APT_DoV_Language__c oDoVLanguage : listOfDoVLanguages)
                {
                    if(mapOfAgreementIdAndDovLanguageList.containsKey(oDoVLanguage.APT_Contract__c)){
                        mapOfAgreementIdAndDovLanguageList.get(oDoVLanguage.APT_Contract__c).add(oDoVLanguage);
                    }
                    else{
                        mapOfAgreementIdAndDovLanguageList.put(oDoVLanguage.APT_Contract__c,new List<APT_DoV_Language__c>{oDoVLanguage});
                    }
                }

                if(mapOfAgreementIdAndDovLanguageList != null && mapOfAgreementIdAndDovLanguageList.keySet().size() > 0)
                {
                    for(Id oAgreementId : mapOfAgreementIdAndDovLanguageList.keySet())
                    {
                        String sDoVLanguage = '';
                        for(Integer i=0;i<mapOfAgreementIdAndDovLanguageList.get(oAgreementId).size();i++)
                        {
                            if(i==mapOfAgreementIdAndDovLanguageList.get(oAgreementId).size()-1){
                                sDoVLanguage += mapOfAgreementIdAndDovLanguageList.get(oAgreementId)[i].APT_DoV_Product__c +' - '+mapOfAgreementIdAndDovLanguageList.get(oAgreementId)[i].APT_DoV_Action__c;
                            }
                            else{
                                sDoVLanguage += mapOfAgreementIdAndDovLanguageList.get(oAgreementId)[i].APT_DoV_Product__c +' - '+mapOfAgreementIdAndDovLanguageList.get(oAgreementId)[i].APT_DoV_Action__c+';';
                            }
                        }
                        Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c(Id=oAgreementId);
                        oAgreement.APT_DOV_Language__c = sDoVLanguage;
                        listOfAgreementToUpdate.add(oAgreement);
                    }
                    if(listOfAgreementToUpdate != null && !listOfAgreementToUpdate.isEmpty()){
                        update listOfAgreementToUpdate;
                    }
                }
            }
        } 
    }
}