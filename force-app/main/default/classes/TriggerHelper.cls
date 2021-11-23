/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 06/07/2015
  * @description  : Helper Class for all triggers in org to verify if triggers are activated.
  */
public with sharing class TriggerHelper{
    
    // Constants
    private static final String COMMA = ',';
    
    /**
      * @description       This method checks if triggers are enabled for the object
      * @param             objType 
      * @return            Boolean
      * @throws            NA
      */        
    public static Boolean isTriggerDisabled(String objType){
        Boolean isDisabled = false;
        if(String.isNotBlank(objType)){
            SystemSwitch__c custSettings = SystemSwitch__c.getInstance();
            if(custSettings != null){
                String objsDisabled = custSettings.ObjectTriggersToBeDisabled__c != null ? 
                                        custSettings.ObjectTriggersToBeDisabled__c.trim() : null ;
                if(String.isNotBlank(objsDisabled)){
                    Set<String> objSet = new Set<String>();
                    objSet.addAll(trimStringList(objsDisabled.split(COMMA)));
                    System.debug('** objSet ==>'+objSet);
                    if(objSet.contains(objType) && custSettings.DisableTriggers__c){
                        isDisabled = true;
                    }
                }
            }
        }
        System.debug('** Triggers Disabled ==>'+isDisabled);
        return isDisabled;
    }
    
    /**
      * @description       This method is used to trim content of list
      * @param             strList - List<String> 
      * @return            Void
      * @throws            NA
      */    
    public static List<String> trimStringList(List<String> strList){
        List<String> retList = new List<String>();
        for(String str : strList){
            retList.add(str.trim());
        }
        System.debug('** retList ==>'+retList);
        return retList;
    }
}