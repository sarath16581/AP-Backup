/**
Description: This apex class is the handler class for apex trigger - Apt_RateCardKeyTrigger
Last Modified By: Seth Heang - seth.p.heang@accenture.com
Last Modified Date: 13/01/2020 | Add method to overwrite Apttus's Net Price field with custom calculation value for "Local Pickup and Delivery Services" product only
Last Modified By: Mathew Jose
Last Modified Date: 29/05/2021 | Added methods onRateCardKeyUpdate & onPriceChange as part of the before update for improved shopping cart performance (STP-5812)
Last Modified By: Mansi Shah
Last Modified Date: 29/05/2021 | Commented code for updating NetPrice with custom pricing for Local Pickup and Delivery Services Product
**/
 public class APT_LineItemTriggerHandler {
    public static void APT_updateConfig(list<Apttus_Config2__LineItem__c> lineItemRec){
            set<id> lineItemConfig=new set<id>();    
            list<Apttus_Config2__ProductConfiguration__c> updateConfi=new list<Apttus_Config2__ProductConfiguration__c>();

                    for(Apttus_Config2__LineItem__c lineItemRecF: lineItemRec){
                        
                            if((lineItemRecF.Apttus_Config2__AddedBy__c=='Constraint Rule' && lineItemRecF.Apttus_Config2__ConstraintCheckStatus__c=='Auto Added') && 
                            (lineItemRecF.APT_Product_Name__c=='International Digital PCMS Bundle incl Airmail Letters' && lineItemRecF.Apttus_Config2__OptionId__c==null)){
                            lineItemConfig.add(lineItemRecF.Apttus_Config2__ConfigurationId__c);
                            system.debug('Apttus_Config2__ConfigurationId__c---->'+lineItemRecF.Apttus_Config2__ConfigurationId__c);
                    }
                    }
                    list<Apttus_Config2__ProductConfiguration__c> configLineRecord  =[select id,Apttus_CQApprov__Approval_Status__c,Apttus_QPConfig__Proposald__c from Apttus_Config2__ProductConfiguration__c where id=:lineItemConfig];
                    list<id> Proposal=new list<id>();
                    list<Task> listTask=new list<Task>();

                    for(Apttus_Config2__ProductConfiguration__c configF:configLineRecord){
                        Proposal.add(configF.Apttus_QPConfig__Proposald__c);
                    }    
                    
                    for(Apttus_Proposal__Proposal__c proposalNe:[select id from Apttus_Proposal__Proposal__c where id=:Proposal]){
                            

        Task tsk = new Task(ActivityDate = date.today(), WhatId = proposalNe.Id, Subject = 'An auto added International PCMS Inc Airmail letters was deleted', Status='Completed', Type='Other', Description='An auto added International PCMS Inc Airmail letters was deleted');

                            listTask.add(tsk);
                    }
                    if(!listTask.isEmpty()){
                    Insert listTask;
                    }
           
   }
    /*  Modified By: Mansi Shah - Commented as per User Story - STP-5810 */
    /* 
    * This method will overwrite Apttus's Net Price field with custom calculation value for "Local Pickup and Delivery Services" product only
    * @param - list of line items
    */
    /*public static void OverWrite_LPD_NetPrice(list<Apttus_Config2__LineItem__c> lineItem){
        
        // Check for changes on Apttus's NetPrice to prevent recursive processing
        List<Apttus_Config2__LineItem__c> processedLineItem = (List<Apttus_Config2__LineItem__c>) RecursionUtility.getUnprocessedRecords('Local Pickup Attribute Changes', lineItem, new Set<String>{'Apttus_Config2__NetPrice__c'});        
        List<Apttus_Config2__LineItem__c> liToBeUpdated = new List<Apttus_Config2__LineItem__c>();
        try{
            if(!processedLineItem.IsEmpty()){
                // Retrieve adjustment type, net price, total service fee fields from Local Pickup and Delivery Services Product on non-recursive line items
                for(Apttus_Config2__LineItem__c li : [SELECT id, Apttus_Config2__NetPrice__c, APT_Product_Name__c, Apttus_Config2__AttributeValueId__r.APT_LPD_Total_Service_Fee__c, Apttus_Config2__AdjustmentType__c
                                                                FROM Apttus_Config2__LineItem__c WHERE id in: processedLineItem AND APT_Product_Name__c =: APT_Constants.PRODUCT_NAME_LOCAL_PICKUP_DELIVERY]){
                    // prevent the calculation update if the adjustment type is 'Price Override'
                    if(li.Apttus_Config2__NetPrice__c != li.Apttus_Config2__AttributeValueId__r.APT_LPD_Total_Service_Fee__c 
                       && li.Apttus_Config2__AdjustmentType__c != APT_Constants.ADJUSTMENT_TYPE_PRICE_OVERRIDE){
                           li.Apttus_Config2__NetPrice__c = li.Apttus_Config2__AttributeValueId__r.APT_LPD_Total_Service_Fee__c;
                           liToBeUpdated.add(li);
                    }
                }
                if(!liToBeUpdated.IsEmpty()){
                    update liToBeUpdated;
                }
            }
            
        }catch(Exception ex){
            // Logs exception for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Apttus CPQ', APT_LineItemTriggerHandler.class.getName(), 'OverWrite_LPD_NetPrice','Apttus_Config2__LineItem__c', LoggingLevel.ERROR);
        }
    }*/


    /* 
    * This method will set the new flag to true if the Rate Card key (RK code) is changed
    * This is being implemeted as part STP-5812 moving the workflow to before triggers(Shopping cart performance)
    * @param - Trigger.new, Trigger.oldMap
    */
    public static void onRateCardKeyUpdate(list<Apttus_Config2__LineItem__c> newlineItems,Map<Id,Apttus_Config2__LineItem__c> oldLineItemMap){
        for(Apttus_Config2__LineItem__c li : newlineItems){
            String oldRateCardKey = oldLineItemMap.get(li.Id)?.APT_Rate_Card_Key__c;
            System.debug('oldRateCardKey::'+oldRateCardKey);
            System.debug('newRateCardKey::'+li.APT_Rate_Card_Key__c);
            if(!String.isBlank(li.APT_Rate_Card_Key__c) && !li.APT_Rate_Card_Key__c.equalsignorecase(oldRateCardKey)){
                li.APT_New__c = true;   
            }
        }
    }

    /* 
    * This method will set the Is Band Changed flag to true based on a criteria
    * This is being implemeted as part STP-5812 moving the workflow to before triggers(Shopping cart performance improvement)
    * @param - Trigger.newMap, Trigger.oldMap
    */
    public static void onPriceChange(Map<Id, Apttus_Config2__LineItem__c> newlineItemsMap,Map<Id,Apttus_Config2__LineItem__c> oldLineItemMap){
        //get Configuration record associate with the line Items
        Map<Id, Apttus_Config2__LineItem__c> lineItemsMap = new Map<Id, Apttus_Config2__LineItem__c>([SELECT Id, Apttus_Config2__ConfigurationId__r.APT_Created_On__c 
                                                                                                    FROM Apttus_Config2__LineItem__c 
                                                                                                    WHERE Id IN : newlineItemsMap.keySet()]);

        for(Apttus_Config2__LineItem__c li : newlineItemsMap.Values()){
            String createdOn = lineItemsMap.get(li.Id)?.Apttus_Config2__ConfigurationId__r?.APT_Created_On__c;
            Decimal oldAdjAmount = oldLineItemMap.get(li.Id)?.Apttus_Config2__AdjustmentAmount__c;
            String oldAdjType = oldLineItemMap.get(li.Id)?.Apttus_Config2__AdjustmentType__c;
            String newAdjType = li?.Apttus_Config2__AdjustmentType__c;
            if(((oldAdjAmount != null && oldAdjAmount != li.Apttus_Config2__AdjustmentAmount__c) || 
                (!String.isBlank(newAdjType) && !newAdjType.equalsignorecase(oldAdjType) || !String.isBlank(oldAdjType) && !oldAdjType.equalsignorecase(newAdjType))) &&
                !li.APT_New_Amend__c &&
                createdOn.equalsignorecase('Amendment Quote')){
                    li.APT_Is_Band_Changed__c   = true;
            }
        }
    }    


}