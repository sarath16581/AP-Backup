/**
Description: This apex class if handler class for apex trigger - APT_ProposalTrigger.
Created By: Himanshu Jain
Created Date: 07th Jan, 2016

Last Modified By: Mausam  Padhiyar
Last Modified Date: 3rd Nov, 2016 | Validate Approvals

Last Modified By: Mausam  Padhiyar
Last Modified Date: 17th Jan, 2017 | 1825

Last Modified By: Lyndon Lavapie
Last Modified Date: 30th July, 2018 | Added changes for CR 146/13

Last Modified By: Ranjeewa Silva
Last Modified Date: 24th Aug, 2020 | Optimised syncWithOpportunity method to attempt the SOQL query only if there are
                                     Apttus product configurations matching the criteria.
                                     
Last Modified By : Mansi Shah
Last Modified Date : 15th June, 2021 | added a method onAfterUpdate for ST Pricing delegation Approvals
*/
public without sharing class APT_ConfigurationTriggerHandler {
    
    /**
     * before update trigger event
     */
    public static String beforeUpdateEvent(list<Apttus_Config2__ProductConfiguration__c> listConfiguration) {
         try {
            //validate approvals
            for(Apttus_Config2__ProductConfiguration__c config : listConfiguration) {
                if(config.APT_Config_Change__c && config.APT_Validate_Approvals__c) {
                    config.APT_Config_Change__c = false;
                } else if((!config.APT_Config_Change__c && !config.APT_Validate_Approvals__c) || (!config.APT_Config_Change__c && config.APT_Validate_Approvals__c)) {
                    config.APT_Config_Change__c = true;
                    config.APT_Validate_Approvals__c = false;
                } else {}
                
            }
            //validate approvals
            
            return APT_Constants.SUCCESS_LABEL;
        } catch(system.exception ex) {
            return ex.getMessage();
        }
    }
    
     /**
            This method will set field on agreement based on custom pricing
            @param
            listConfiguration - List of Product configuration
     */
    public static String afterInsertEvent(list<Apttus_Config2__ProductConfiguration__c> listConfiguration) {
        //APOST-1347
        try {
            set<Id> setAgreementId = new set<Id>();
            set<Id> setProposalId = new set<Id>();  //1825
            for(Apttus_Config2__ProductConfiguration__c configuration : listConfiguration) {
                if(String.isNotBlank(configuration.Apttus_CMConfig__AgreementId__c) && configuration.APT_Customised_Pricing__c) {
                    setAgreementId.add(configuration.Apttus_CMConfig__AgreementId__c);
                }

                setProposalId.add(configuration.Apttus_QPConfig__Proposald__c); //1825
            }
            
            list<Apttus__APTS_Agreement__c> listAgreement = new list<Apttus__APTS_Agreement__c>();
            for(Apttus__APTS_Agreement__c agreement : [SELECT Id, Name, APT_Pricing_Category__c 
                                                        FROM Apttus__APTS_Agreement__c  
                                                        WHERE Id IN :setAgreementId]) {
                agreement.APT_Pricing_Category__c = APT_Constants.AGREEMENT_CATEGORY_CUSTOMISED;
                listAgreement.add(agreement);
            }
            
            update listAgreement;

            //1825
            if(setProposalId.size() > 0) {
                list<Apttus_Proposal__Proposal__c> listProposal = new list<Apttus_Proposal__Proposal__c>();
                for(Apttus_Proposal__Proposal__c proposal : [SELECT Id, APT_Use_Offline_Rates__c
                                                            FROM Apttus_Proposal__Proposal__c
                                                            WHERE Id IN :setProposalId]) {
                    if(proposal.APT_Use_Offline_Rates__c) {
                        proposal.APT_Use_Offline_Rates__c = false;
                        listProposal.add(proposal);
                    }                    
                }

                if(listProposal.size() > 0) {
                    update listProposal;
                }
            }
            //1825

            return APT_Constants.SUCCESS_LABEL;
        } catch(system.exception ex) {
            return ex.getMessage();
        }
    }
    
    /**
    * @description : This method will be called from APT_ConfigurationTrigger. It will identify the approved Configuration and will enque job for furhter processing.
    * @author Mansi Shah | 06-09-2021 
    * @param configList 
    * @param oldConfigMap 
    **/
    public static void onAfterUpdate(List<Apttus_Config2__ProductConfiguration__c> configList, Map<ID, Apttus_Config2__ProductConfiguration__c> oldConfigMap){
        Set<Id> setOfApprovedConfigurationIds = new Set<Id>();
        for(Apttus_Config2__ProductConfiguration__c oProductConfig : configList)
        {
            if(oProductConfig.Apttus_CQApprov__Approval_Status__c != null &&
               oProductConfig.Apttus_CQApprov__Approval_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_PROCESSING_APPROVAL) &&
               oldConfigMap.containsKey(oProductConfig.Id) &&
               oProductConfig.Apttus_CQApprov__Approval_Status__c != oldConfigMap.get(oProductConfig.Id).Apttus_CQApprov__Approval_Status__c &&
               oldConfigMap.get(oProductConfig.Id).Apttus_CQApprov__Approval_Status__c != null &&
               oldConfigMap.get(oProductConfig.Id).Apttus_CQApprov__Approval_Status__c.equalsIgnoreCase(APT_Constants.PROPOSAL_APPROVAL_STATUS_PENDING_APPROVAL))
            {
                setOfApprovedConfigurationIds.add(oProductConfig.Id);
            }
        }
        
        if(setOfApprovedConfigurationIds != null && setOfApprovedConfigurationIds.size() > 0){
            ID jobID = System.enqueueJob(new APT_ProcessApprovedConfigurationBatch(setOfApprovedConfigurationIds));
        }
    }

    /**
            This method will sync proposal with opportunity
            @param
            configList- List of Product configuration
     */   
     
    /* Shashwat.Nath@Auspost.com has commented this method on 07/09/200 as the all the Sync related Logic has been moved to APT_CreateOpportunityProductLICntlr
       class as per the requirements based STP Release 2 Project . This method can be deleted after December 2020 */ 
    /*public static void syncWithOpportunity(List<Apttus_Config2__ProductConfiguration__c> configList, Map<ID, Apttus_Config2__ProductConfiguration__c> oldConfigMap) {
        
        Set<ID> configListToBeUpdated = new Set<ID>();
        Set<ID> finalProposalIds = new Set<ID>();
    try {    
        for(Apttus_Config2__ProductConfiguration__c configuration : configList){
            if(configuration.Apttus_Config2__BusinessObjectType__c.equalsIgnoreCase(APT_Constants.URL_PROPOSAL)
                && (configuration.Apttus_Config2__Status__c.equalsIgnoreCase(APT_Constants.URL_SAVED) )){                    
                    configListToBeUpdated.add(configuration.ID);                  
            }
        }

        //Only do the SOQL if we have found Apttus_Config2__ProductConfiguration__c matching criteria.
        if (!configListToBeUpdated.isEmpty()) {
            for (Apttus_Config2__ProductConfiguration__c config : [select id,Apttus_QPConfig__Proposald__c, Apttus_QPConfig__Proposald__r.Apttus_Proposal__Primary__c,Apttus_QPConfig__Proposald__r.RecordType.Name from Apttus_Config2__ProductConfiguration__c where Id IN :configListToBeUpdated]) {
                if (config.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Primary__c
                        && (APT_Constants.RECORD_TYPE_PROPOSAL).equalsIgnoreCase(config.Apttus_QPConfig__Proposald__r.RecordType.Name)) {
                    finalProposalIds.add(config.Apttus_QPConfig__Proposald__c);
                }
            }

            if (!finalProposalIds.isEmpty()) {
                sycWithOpportunity(finalProposalIds);
            }
        }
    } catch(system.exception ex) {
            system.debug('Exception'+ex.getMessage());
        }
    }*/
    
        /**
        This method will create opportunity line item records based on proposal line items.
        @params -
        setAcceptedProposalIds - set of accepted proposal ids
        
     */
    
     /* Shashwat.Nath@Auspost.com has commented this method on 07/09/200 as the all the Sync related Logic has been moved to APT_CreateOpportunityProductLICntlr
       class as per the requirements based STP Release 2 Project . This method can be deleted after December 2020 */  
    
    /*public static void sycWithOpportunity(set<Id> setAcceptedProposalIds) {
    
       
        set<Id> setOpportunityId = new set<Id>();
        try {
            if(setAcceptedProposalIds.size() > 0) {            
                list<APT_Opportunity_Product_Line_Item__c> listOPLI = new list<APT_Opportunity_Product_Line_Item__c>();
                
                
                set<Id> setProductId = new set<Id>(); 
               
                for(APT_Opportunity_Product_Line_Item__c oPLineItem : [select   id,name,APT_Classification__c,APT_Contract_Product__c,APT_Product__r.name,APT_Product_Configuration__c,APT_Quantity__c,APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__c,
                                APT_Revenue_End_Date__c,APT_Quote_Proposal__r.name,APT_Revenue_Start_Date__c,
                                APT_Sequence_Number__c,APT_Sub_Classification__c,APT_TotalPrice__c,APT_Unit_Sales_Price__c,
                                APT_Quote_Proposal__r.RecordType.name, APT_Quote_Proposal__r.APT_Revenue_Type__c, APT_Increase_in_Quantity__c,//Added for CR148/13
                                (select id from Opportunity_Product__r)
                                from APT_Opportunity_Product_Line_Item__c 
                                where APT_Quote_Proposal__c IN: setAcceptedProposalIds]) {
                   setProductId.add(oPLineItem.APT_Product__c);                
                   
                    setOpportunityId.add(oPLineItem.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__c);
                                    
                    listOPLI.add(oPLineItem);
                }
                
                map<Id, PriceBookEntry> mapPriceBookEntry = managePriceBookEntry(setProductId);
                
                list<OpportunityLineitem> listOpportunityLineItem = new list<OpportunityLineitem>();            
                                            
                listOpportunityLineItem = APT_ConfigurationTriggerHandler.createOpportunityLineItems(listOPLI, mapPriceBookEntry);                            
                           
                system.debug('listOpportunityLineItem:' + listOpportunityLineItem);

                if(listOpportunityLineItem.size() > 0) {
                    deleteExistingOpportunityLineItems(setOpportunityId);                
                    upsert listOpportunityLineItem;
                    
                    system.debug('after insert listOpportunityLineItem:' + listOpportunityLineItem);

                    for(OpportunityLineitem oli : listOpportunityLineItem){
                        oli.APT_Apttus_Delete_Override__c = false;
                    }
                    update listOpportunityLineItem;
                }            
                
            }
        } catch(Exception e){
            system.debug('Expception -'+e);
            
        }
        
    }*/
    
    /**
        This method will manage price book entry records for products. If price book entry does not exist then will be created.
        @params -
        setProductId - set of product ids
     */
    public static map<Id, PriceBookEntry> managePriceBookEntry(set<Id> setProductId) {
        map<Id, PriceBookEntry> mapPriceBookEntry = new map<Id, PriceBookEntry>();
        try {
            PriceBook2 standardPriceBook;
            If(!Test.isRunningTest()){
            standardPriceBook = [SELECT Id, Name, IsActive, IsStandard FROM PriceBook2 WHERE IsStandard = true AND isActive = true limit 1];
            }else{
            standardPriceBook= new PriceBook2(ID=Test.getStandardPricebookId());
            }    
            
            for(PriceBookEntry pbe : [SELECT Id, Product2Id FROM PriceBookEntry WHERE Product2Id IN :setProductId]){
                mapPriceBookEntry.put(pbe.Product2Id, pbe);
            }
            
            list<PriceBookEntry> listPriceBookEntry = new list<PriceBookEntry>();
            PriceBookEntry pbe;
            for(Id productId : setProductId) {              
                if((mapPriceBookEntry.get(productId) != null) == false) {
                    pbe = new PriceBookEntry();
                    pbe.Pricebook2Id = standardPriceBook.Id;
                    pbe.Product2Id = productId;
                    pbe.UnitPrice = 1000;
                    pbe.IsActive = true;
                    
                    listPriceBookEntry.add(pbe);
                }
            }
            
            insert listPriceBookEntry;
            
            mapPriceBookEntry.clear();
            for(PriceBookEntry pbet : [SELECT Id, Product2Id , UnitPrice FROM PriceBookEntry WHERE Product2Id IN :setProductId]){
                mapPriceBookEntry.put(pbet.Product2Id, pbet);
            }
            
        }catch(Exception e){
            system.debug('Expception -'+e);
            return null;
        }
        return mapPriceBookEntry;
    }
    
    /**
            This method will delete opportunity.
            @param
            setOpportunityId- Set of Opportunity id.
            
     */ 
     
     /* Shashwat.Nath@Auspost.com has commented this method on 07/09/200 as the all the Sync related Logic has been moved to APT_CreateOpportunityProductLICntlr
       class as per the requirements based STP Release 2 Project . This method can be deleted after December 2020 */ 
          
    /*public static void deleteExistingOpportunityLineItems(set<Id> setOpportunityId) {
     try {
        if(setOpportunityId.size() > 0) {   
            List<OpportunityLineitem> oliList = [SELECT Id FROM OpportunityLineitem 
                                                    WHERE OpportunityId IN :setOpportunityId
                                                    And APT_OPC_Line_Items__c = null
                                                    And APT_Is_Apttus_Opportunity_Line_item__c = true];
            
            if(oliList != null && oliList.size() > 0){
                for(OpportunityLineitem oli : oliList){
                    oli.APT_Apttus_Delete_Override__c = true;           
                }
                update oliList;
                system.debug('Opportunity Line Item To Be Deleted:' + oliList);
                delete oliList;
            }
        }         
        
    } catch(system.exception ex) {
            system.debug('Exception'+ex.getMessage());
        }
    }*/
    
   /**
            This method will create opportunity line item.
            @param
            lstopliToCopy- list of Opportunity Line item.
     */ 
     
     /* Shashwat.Nath@Auspost.com has commented this method on 07/09/200 as the all the Sync related Logic has been moved to APT_CreateOpportunityProductLICntlr
       class as per the requirements based STP Release 2 Project . This method can be deleted after December 2020 */
               
    /*public static list<OpportunityLineitem> createOpportunityLineItems(List<APT_Opportunity_Product_Line_Item__c> opcList, map<Id, PriceBookEntry> mapPriceBookEntry) {
        list<OpportunityLineitem> listOpportunityLineItemToInsert = new list<OpportunityLineitem>();
        list<OpportunityLineitem> listOpportunityLineItemTodelete = new list<OpportunityLineitem>();
        system.debug('Custom OPC LIST--->' + opcList);
        system.debug('PRICE BOOK ENTRY MAP--->' + mapPriceBookEntry);
        OpportunityLineitem oli ;
        try {
            for(APT_Opportunity_Product_Line_Item__c opc: opcList){
              
              List<OpportunityLineitem> oliList = opc.Opportunity_Product__r;
               if(oliList != null && oliList.size() > 0){
                   system.debug('oliList--->' + oliList);
        
                   for(OpportunityLineitem oliOld : oliList){
                       oli = oliFromOPC(opc,mapPriceBookEntry);
                       if(oli != null){ //Updated for CR148/13
                       oli.Id = oliOld.Id;
                           if(oli.Quantity == 0 || oli.Quantity == null){
                                listOpportunityLineItemTodelete.add(oli);
                            }else{
                       listOpportunityLineItemToInsert.add(oli);
                            }

                       system.debug('OPC--->' + oli.Id);
                       system.debug('oli--->' + oli);
                       }//Updated for CR148/13

                   }
               } else {
                   oli = oliFromOPC(opc,mapPriceBookEntry);
                   //Updated for CR148/13
                   if(oli != null && oli.Quantity > 0 && oli.Quantity != null ){
                   listOpportunityLineItemToInsert.add(oli);
               }
                   //Updated for CR148/13
               }

              system.debug('listOpportunityLineItemToInsert--->' + listOpportunityLineItemToInsert);
        
           }
           //Flush OPC on checkout for increase revenue
           if(!listOpportunityLineItemTodelete.isEmpty()){
               system.debug('To be deleted--->' + listOpportunityLineItemToInsert);
                delete listOpportunityLineItemTodelete;
           }
        } catch(system.exception ex) {
             system.debug('Exception'+ex.getMessage());
            return null;
        }
        return listOpportunityLineItemToInsert;
    }*/
    
     /* Shashwat.Nath@Auspost.com has commented this method on 07/09/200 as the all the Sync related Logic has been moved to APT_CreateOpportunityProductLICntlr
       class as per the requirements based STP Release 2 Project . This method can be deleted after December 2020 */ 
       
    /*private static OpportunityLineitem oliFromOPC(APT_Opportunity_Product_Line_Item__c opc, map<Id, PriceBookEntry> mapPriceBookEntry){
        OpportunityLineitem oli = new OpportunityLineitem();        
        oli.Classification__c = opc.APT_Classification__c;
        oli.Sub_Classification__c = opc.APT_Sub_Classification__c;        
        //for CR148/13
        //Added By Lyndon Lavapie
        //Start
        //new opportunity should only contain products and revenue with increase in revenue
        if(opc.APT_Quote_Proposal__r.APT_Revenue_Type__c == APT_AmendRenewController.INCREASE_REVENUE && opc.APT_Quote_Proposal__r.RecordType.name==APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE
            && opc.APT_Increase_in_Quantity__c != null && opc.APT_Increase_in_Quantity__c > 0){
            oli.Quantity = opc.APT_Increase_in_Quantity__c;
        }
        //Flush OPC on checkout for increase revenue
        else if(opc.APT_Quote_Proposal__r.APT_Revenue_Type__c == APT_AmendRenewController.INCREASE_REVENUE && opc.APT_Quote_Proposal__r.RecordType.name==APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE
            && (opc.APT_Increase_in_Quantity__c <= 0 || opc.APT_Increase_in_Quantity__c == 0)){
            oli.Quantity = opc.APT_Increase_in_Quantity__c;
            return oli;
        }
        //stop the new proposal from affecting the OPC of the current opportunity
        else if(opc.APT_Quote_Proposal__r.APT_Revenue_Type__c == APT_AmendRenewController.DECREASE_REVENUE && opc.APT_Quote_Proposal__r.RecordType.name==APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE ){
            return null;
        }else{
        oli.Quantity = opc.APT_Quantity__c;
        }
        //End
        oli.UnitPrice = opc.APT_Unit_Sales_Price__c;
        oli.Contract_Number__c = opc.APT_Quote_Proposal__r.Name;
        oli.OpportunityId = opc.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__c;
        oli.Contract_Start_Date__c = opc.APT_Revenue_Start_Date__c;
        oli.Contract_End_Date__c = opc.APT_Revenue_End_Date__c;      
        oli.PriceBookEntryId = mapPriceBookEntry.get(opc.APT_Product__c).Id;
        oli.Contract_Product__c= opc.APT_Contract_Product__c;
        oli.APT_Is_Apttus_Opportunity_Line_item__c = true;
        oli.APT_OPC_Line_Items__c = opc.Id;
        oli.APT_Apttus_Delete_Override__c = true;
        system.debug('unit sales price--->' + opc.APT_Unit_Sales_Price__c);
        system.debug('PB Entry--->' + oli.PriceBookEntryId);
        system.debug('OPC Product--->' + opc.APT_Contract_Product__c);
        system.debug('oli.Quantity--->' + oli.Quantity);



        return oli;
    }*/
    
    public static void onDeleteConfigurationRecord(List<Apttus_Config2__ProductConfiguration__c> configList){
        set<Id> proposalId = new Set<Id>();
        for(Apttus_Config2__ProductConfiguration__c configRec : configList){
            if(String.isNotBlank(configRec.Apttus_QPConfig__Proposald__c)){
                proposalId.add(configRec.Apttus_QPConfig__Proposald__c);
            }
        }
        System.debug('proposalId>>>'+proposalId); 
        List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
        proposalList = [Select Id, Is_Startrack_Proposal__c, APT_Tier_Adjustment_Type__c, APT_Pricing_Request_Type__c, 
                            APT_Tier_Adjustment_Justification__c, APT_Intermediary__c, APT_Customer_Background__c, APT_Conversation__c, 
                            APT_Name_of_Intermediary_s_Client__c from Apttus_Proposal__Proposal__c where Id IN: proposalId];
        System.debug('proposalList>>>'+proposalList); 
        if(!proposalList.isEmpty()){
            for( Apttus_Proposal__Proposal__c proposalObj : proposalList){
                if(proposalObj.Is_Startrack_Proposal__c.equalsIgnoreCase('Yes')){
                    proposalObj.APT_Tier_Adjustment_Type__c = '';
                    proposalObj.APT_Pricing_Request_Type__c = '';
                    proposalObj.APT_Tier_Adjustment_Justification__c = '';
                    proposalObj.APT_Intermediary__c = '';
                    proposalObj.APT_Customer_Background__c = '';
                    proposalObj.APT_Conversation__c = '';
                    proposalObj.APT_Name_of_Intermediary_s_Client__c = null;
                    proposalObj.APT_competitor__c = '';
                    // update proposalObj;
                }
            }
            update proposalList;
        }
    }
}