/**
Description: This Class will populate the parent lookup when cloned.
Created By - Raviteja Gona
Created Date - 19th June, 2017
**/
public without sharing class APT_ProposalCloneHandler{
 public static String UpdateProposalandConfigWithCloneFlag(List<Apttus_Proposal__Proposal__c> Plist){
   try{
       Map<ID,Schema.RecordTypeInfo> rt_Map = Apttus_Proposal__Proposal__c.sObjectType.getDescribe().getRecordTypeInfosById();
        for(Apttus_Proposal__Proposal__c P: Plist){
            if(P.isClone()) {
                string recordtypeName = rt_map.get(P.RecordTypeId).getName();
                if(recordtypeName == APT_Constants.RECORD_TYPE_PROPOSAL){
                P.APT_Parent_Proposal__c=P.getCloneSourceId();
                }
            }
        }
     
        }
        catch(Exception e)
        {
            //system.debug('Expception -'+e);
            return null;
        }
        return APT_Constants.SUCCESS_LABEL;
        
        }

}