/**
Description: This apex class is handler class for apex trigger - APT_RelatedAgreementTrigger.
Created By: Garvita Rai
Created Date: 2nd Dec, 2015
Last Modified By:
Last Modified Date:
*/
public with sharing class APT_RelatedAgreementTriggerHandler{
    
    /**
        This method will copy operational schedule
    **/
    public static String  copyOperationalSchedule(List<Apttus__APTS_Related_Agreement__c > listRelatedAgreement) {
        try{
            Set<Id> setParentAgreementId = new Set<Id>();
            Set<Id> setChildAgreementId = new Set<Id>();
            Map<Id,Id> mapParentChildAgrmntId = new Map<Id,Id>();
            for(Apttus__APTS_Related_Agreement__c relAgr : listRelatedAgreement ){                
                setParentAgreementId.add(relAgr.Apttus__APTS_Contract_From__c);
                setChildAgreementId.add(relAgr.Apttus__APTS_Contract_To__c);
                mapParentChildAgrmntId.put(relAgr.Apttus__APTS_Contract_From__c,relAgr.Apttus__APTS_Contract_To__c);
            }
            List<APT_Operational_Schedule__c> listOprSchedule = new List<APT_Operational_Schedule__c>();
            List<Apttus__APTS_Agreement__c > listChildAgreement = new List<Apttus__APTS_Agreement__c >();
            listChildAgreement=database.query(APT_Constants.SOQL_SELECT + APT_AmendRenewUtility.getAllAgrFields(APT_Constants.SOQL_AGREEMENT_OBJECT) + APT_Constants.SOQL_AGREEMENT_QUERY);
            List<APT_Operational_Schedule__c> listOperationSchedule = new List<APT_Operational_Schedule__c>();
            listOperationSchedule = database.query(APT_Constants.SOQL_SELECT + APT_AmendRenewUtility.getAllAgrFields(APT_Constants.SQOL_OPERATIONAL_SCHEDULE_OBJECT) + APT_Constants.SOQL_OPERATIONAL_SCHEDULE_QUERY);
            if(listOperationSchedule.size()>0){
                APT_Operational_Schedule__c operationalSchedule;
                for(APT_Operational_Schedule__c oprSchedule :listOperationSchedule){
                     operationalSchedule = new APT_Operational_Schedule__c();
                     for (String fieldName :APT_AmendRenewUtility.getFieldNames(APT_Operational_Schedule__c.getSObjectType())) {
                        Object value = oprSchedule.get(fieldName);
                        if(value != null) {
                            operationalSchedule.put(fieldName, value);
                        }
                        operationalSchedule.APT_Contract__c=mapParentChildAgrmntId.get(oprSchedule.APT_Contract__c);
                    }
                    
                    if(operationalSchedule.APT_Contract__c != null)   {                  
                        listOprSchedule.add(operationalSchedule);
                    }
                }
            }
            
            if(listOprSchedule.size()>0) {
                insert listOprSchedule;
            }
            
            return APT_Constants.SUCCESS_LABEL;
        }
        catch(Exception e){
            return e.getMessage();
        }
    }
}