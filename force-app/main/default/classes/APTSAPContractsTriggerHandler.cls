/**
  * @author       : Snigdha.Sahu@auspost.com.au
  * @date         : 16/08/2016
  * @description  : Handler Class for SAP Contracts object trigger which includes context-specific methods 
                    that are automatically called when a trigger is executed.
  */
 
public with sharing class APTSAPContractsTriggerHandler{
    //Variables
    private static SAPContractsUtility sapContractsUtil;
    
    
    public static void execute(){
        sapContractsUtil = new SAPContractsUtility();    
        if(Trigger.isBefore){
                beforeHandler();        // invoke of before handler
        }
        else if(Trigger.isAfter){
                afterHandler();         // invoke of after handler
        }
    }
    
    /**
      * @description       This method is handler for before events invoked by execute method.
                           Method invokes the helper class methods based on the scenario.                       
      * @param             NA 
      * @return            Void
      * @throws            NA
      */  
    
     private static void beforeHandler(){
            if(Trigger.isInsert || Trigger.isUpdate){
             sapContractsUtil.syncVolumeRevenue(Trigger.new);
         }
         
     }
    
     /**
      * @description       This method is handler for after events invoked by execute method.
                           Method invokes the helper class methods based on the scenario.                          
      * @param             NA 
      * @return            Void
      * @throws            NA
      */  
    
    private static void afterHandler(){
         /*if(Trigger.isInsert){//methods for insert
             
             sapContractsUtil.syncVolumeRevenue(Trigger.new);
         }
         else if(Trigger.isUpdate){
             
             sapContractsUtil.syncVolumeRevenue(Trigger.new);
         }*/
         
     }
    
    
    
    
}