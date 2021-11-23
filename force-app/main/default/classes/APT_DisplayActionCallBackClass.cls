/**
 * @description       : 
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-26-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-06-2021   Mansi Shah   Initial Version
**/
global with sharing class APT_DisplayActionCallBackClass implements Apttus_Config2.CustomClass.IDisplayActionCallback{
    //Global Variables
   public static FINAL String sProfile_BGBase = 'BG Base';
   public static Apttus_Config2__ProductConfiguration__c prodConfigObj;
  
   /*
   *************************************************************************************
   * Method Name : start
   * Description : Interface method. This method sets the action info list. It serve below purpose.
   1. Control buttons visiblity on Cart page.
   * Return Type : None
   * Parameters : Apttus_Config2.ProductConfiguration, List<Apttus_Config2.DisplayActionInfo>
   *************************************************************************************
   */
   global static void start(Apttus_Config2.ProductConfiguration cart, List<Apttus_Config2.DisplayActionInfo> disActionInfoList)
   {
       try{
           Profile profile_BGBase = [SELECT ID,Name FROM Profile WHERE Name =:sProfile_BGBase LIMIT 1];
           Id userProfileId = UserInfo.getProfileId();
           List<Apttus_Config2__ProductConfiguration__c> lstProdConfig = new List<Apttus_Config2__ProductConfiguration__c>();
           //Added by Darshan Chauhan for STP-5150 start
           if(!Test.isRunningTest()){             
               prodConfigObj = cart.getConfigSO();           
           }

           if(prodConfigObj != null){
               lstProdConfig =[Select id, Apttus_QPConfig__Proposald__r.Is_Startrack_Proposal__c  From Apttus_Config2__ProductConfiguration__c
               where id = :prodConfigObj.Id];
           }
           //Added by Darshan Chauhan for STP-5150 end
           for(Apttus_Config2.DisplayActionInfo actionInfoInst : disActionInfoList)
           {
               Apttus_Config2__ConfigCustomDisplayActions__c ActionSOInst = actionInfoInst.ActionSO;
           
               if(ActionSOInst.Apttus_Config2__ActionLabelName__c.equalsIgnoreCase(Label.APT_Action_OfflineRates) && profile_BGBase.Id == userProfileId)
               {
                   actionInfoInst.IsEnabled = false;
               }
               //Added by Darshan Chauhan for STP-5150 start
               if(!lstProdConfig.isEmpty()){
                   if(lstProdConfig[0].Apttus_QPConfig__Proposald__r.Is_Startrack_Proposal__c.equalsIgnoreCase(APT_Constants.OPTION_NO)){
                       if(ActionSOInst.Apttus_Config2__ActionLabelName__c.equalsIgnoreCase('APT_Pricing_Adjustments'))
                       {
                           actionInfoInst.IsEnabled = false;
                       }
                   }
               }
           }
           //Added by Darshan Chauhan for STP-5150 end
       }
       Catch(Exception e){
           System.debug('Exception occured '+e);
       }
       
   }

   global static void setActionProperties(Apttus_Config2.CustomClass.ActionParams actionParam)
   {
       System.debug('actionParam--------'+actionParam);
   }
}