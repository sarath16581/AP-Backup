public with sharing class APT_AppliedRuleInfoActionTriggerHandler {
    public static String APT_DeleteBlankRule(list<Apttus_Config2__AppliedRuleActionInfo__c> AriaList){
           try{ 
            Set<Id> AriIds = new Set<Id>();
            list<Apttus_Config2__AppliedRuleInfo__c> AritoQuery=new list<Apttus_Config2__AppliedRuleInfo__c>();        
            list<Apttus_Config2__AppliedRuleInfo__c> AritoDelete=new list<Apttus_Config2__AppliedRuleInfo__c>();

                    for(Apttus_Config2__AppliedRuleActionInfo__c Aria: AriaList){
                            if(Aria.Apttus_Config2__AppliedRuleInfoId__c!= null){
                            AriIds.add(Aria.Apttus_Config2__AppliedRuleInfoId__c);
                    }
                    }
                    
                    if(!AriIds.isEmpty()){
                    AritoQuery = [select id,Apttus_Config2__ConstraintRuleId__c from Apttus_Config2__AppliedRuleInfo__c 
                                      where Id =: AriIds];
                    }
                    for(Apttus_Config2__AppliedRuleInfo__c ari: AritoQuery){
                            if(ari.Apttus_Config2__ConstraintRuleId__c == null){
                            AritoDelete.add(ari);
                    }
                    }
                    
                    if(!AritoDelete.isEmpty()){
                    Database.Delete(AritoDelete);
                    }
                    
        return APT_Constants.SUCCESS_LABEL;
        } catch(Exception ex) {
            return ex.getMessage();
        }
           
   }

}