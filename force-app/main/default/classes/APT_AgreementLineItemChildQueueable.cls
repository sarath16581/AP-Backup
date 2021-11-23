/**
 Description: 
 Created By: Himanshu jain
 Created Date: 25th Jun, 2016
 
 Last Modified By - Mausam Padhiyar
 Last Modified Date - 20th Sept, 2016 | 1165 : Contract Pricing Queueable
 
 Last Modified By - Mahesh Patel
 Last Modified Date - 15th Feb, 2021 | Decommision Contract Pricing
**/

public with sharing class APT_AgreementLineItemChildQueueable implements Queueable {
    
    public Set<ID> agreementIDList;
    /**
     Constructor
    **/
    public APT_AgreementLineItemChildQueueable(Set<ID> agreementIDList){
        try{
            this.agreementIDList = agreementIDList;
        } catch(Exception e){
            system.debug(Logginglevel.ERROR, e.getMessage());
           
            //return e.getMessage();
        }
    }
    /**
      Execute Method
    **/
    public void execute(QueueableContext context) {
        try {
            agreementLodgementPoint(agreementIDList);

            //Decommissioned Contract Pricing
            //Id jobID = System.enqueueJob(new APT_ContractPricingQueueable(agreementIDList));
        } catch(Exception e){
            system.debug(Logginglevel.ERROR, e.getMessage());
        }
    }
    /**
     Method will insert lodgement point
    **/
    public static void  agreementLodgementPoint(Set<ID> agreementIDSet) {
        //try{
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            
            List<APT_Agreement_Lodgement_Point__c> listagrmntLodgemntPoint = new List<APT_Agreement_Lodgement_Point__c>();
                
            Map<ID,Apttus__AgreementLineItem__c> agreementLineItemMap = new Map<ID,Apttus__AgreementLineItem__c>([select id, Apttus__AgreementId__c, 
                                                                        Apttus__ProductId__c, Apttus_CMConfig__LineNumber__c,
                                                                        Apttus_CMConfig__ItemSequence__c, Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c,
                                                                        Apttus__AgreementId__r.Operational_Schedule__c, Apttus__ProductId__r.ProductCode,
                                                                        APT_New__c, Apttus_CMConfig__LineType__c, Apttus_CMConfig__IsPrimaryLine__c,
                                                                        Apttus_CMConfig__IsOptionRollupLine__c
                                                                        from Apttus__AgreementLineItem__c 
                                                                        where Apttus__AgreementId__c in: agreementIDSet]);
            
            //listAgreementLineItem = ;
            Set<Id> setAgreementId = new Set<Id>();
            Set<Id> setQuoteId= new Set<Id>();
            Map<Id,Id> mapAgreement = new Map<Id,Id>();
            map<String, Apttus__AgreementLineItem__c> mapAgreementLineItem = new map<String, Apttus__AgreementLineItem__c>();
            
            Boolean bNewPricing = false;
            for(Apttus__AgreementLineItem__c  agrmntLineItem : agreementLineItemMap.values()){
                setAgreementId.add(agrmntLineItem.Apttus__AgreementId__c);
                mapAgreementLineItem.put(agrmntLineItem.Apttus__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + agrmntLineItem.Apttus_CMConfig__LineNumber__c + APT_Constants.SEPERATOR_SIMILARITY + agrmntLineItem.Apttus_CMConfig__ItemSequence__c, agrmntLineItem);
                setQuoteId.add(agrmntLineItem.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c);
                mapAgreement.put(agrmntLineItem.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c,agrmntLineItem.Apttus__AgreementId__c);
                
                //DoV
                system.debug('*** agrmntLineItem.APT_New__c ***'+agrmntLineItem.APT_New__c);
                system.debug('*** agrmntLineItem.Apttus__ProductId__r.ProductCode ***'+agrmntLineItem.Apttus__ProductId__r.ProductCode);
                system.debug('*** agrmntLineItem.Apttus_CMConfig__LineType__c ***'+agrmntLineItem.Apttus_CMConfig__LineType__c);
                if(agrmntLineItem.APT_New__c && agrmntLineItem.Apttus_CMConfig__IsPrimaryLine__c && !agrmntLineItem.Apttus_CMConfig__IsOptionRollupLine__c && ((String.isBlank(agrmntLineItem.Apttus__ProductId__r.ProductCode)) || (String.isNotBlank(agrmntLineItem.Apttus__ProductId__r.ProductCode) && !agrmntLineItem.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST))) && String.isNotBlank(agrmntLineItem.Apttus_CMConfig__LineType__c) && agrmntLineItem.Apttus_CMConfig__LineType__c.equalsIgnoreCase(APT_Constants.LINE_TYPE_PRODUCT_SERVICE)) {
                    bNewPricing = true;
                    system.debug('*** New Pricing ***');
                }
                //DoV
            }
            
            //System.debug(logginglevel.error,' ** setQuoteId  ' + setQuoteId);
            Map<Id,Apttus_Proposal__Proposal__c> mapQuote = new Map<Id,Apttus_Proposal__Proposal__c>();
            for(Apttus_Proposal__Proposal__c quote : [SELECT id,Apttus_Proposal__Account__c from Apttus_Proposal__Proposal__c where id in : setQuoteId ]){
                mapQuote.put(quote.id,quote);
            } 
            
            Map <Id,Apttus_Proposal__Proposal_Line_Item__c> mapProposalLineItem = new Map<Id,Apttus_Proposal__Proposal_Line_Item__c>();
            for(Apttus_Proposal__Proposal_Line_Item__c propLineItem: [SELECT Apttus_QPConfig__DerivedFromId__c,
                                                              Apttus_Proposal__Product__c,Apttus_QPConfig__LineNumber__c,Apttus_Proposal__Proposal__c,
                                                              Apttus_QPConfig__ItemSequence__c from Apttus_Proposal__Proposal_Line_Item__c where Apttus_Proposal__Proposal__c in :setQuoteId ] ){
                mapProposalLineItem.put(propLineItem.id,propLineItem);
            }
            system.Debug('mapAgreementLineItem-------->' + mapAgreementLineItem);
            
            
             //copy agreement lodgement point from quote
            List<APT_Quote_Lodgement_Point__c> listQuoteLodgementPoint = database.query(APT_Constants.SOQL_SELECT + APT_AmendRenewUtility.getAllAgrFields(APT_Constants.SOQL_QUOTE_LODGEMENT_POINT_OBJECT) + APT_Constants.SOQL_QUOTE_LODGEMENT_POINT_FROM);
            if(listQuoteLodgementPoint != null && listQuoteLodgementPoint.size() > 0){
                Set<String> quoteLodgementFieldNames = new Set<String>(APT_AmendRenewUtility.getFieldNames(APT_Quote_Lodgement_Point__c.getSObjectType()));
                APT_Agreement_Lodgement_Point__c agrmntLodgmntRec;
                for( APT_Quote_Lodgement_Point__c quoteLodgementPoint : listQuoteLodgementPoint){
                   agrmntLodgmntRec = new APT_Agreement_Lodgement_Point__c();
                   if(quoteLodgementPoint.APT_Proposal_Line_Item__c <> null){
                        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = mapProposalLineItem.get(quoteLodgementPoint.APT_Proposal_Line_Item__c);
                        Apttus__AgreementLineItem__c agreementLineItem = mapAgreementLineItem.get(proposalLineItem.Apttus_Proposal__Product__c + APT_Constants.SEPERATOR_SIMILARITY + proposalLineItem.Apttus_QPConfig__LineNumber__c + APT_Constants.SEPERATOR_SIMILARITY + proposalLineItem.Apttus_QPConfig__ItemSequence__c);
                        if(agreementLineItem != null) {
                            for (String fieldName : APT_AmendRenewUtility.getFieldNames(APT_Agreement_Lodgement_Point__c.getSObjectType())) {
                                 if(quoteLodgementFieldNames.contains(fieldName)){
                                    Object value = quoteLodgementPoint.get(fieldName);
                                    agrmntLodgmntRec.put(fieldName,value);
                                     
                                 }
                            }
                            agrmntLodgmntRec.APT_Agreement__c = agreementLineItem.Apttus__AgreementId__c ;
                            agrmntLodgmntRec.APT_Agreement_Line_Item__c = agreementLineItem.Id;
                            agrmntLodgmntRec.APT_Organisation__c = mapQuote.get(quoteLodgementPoint.APT_Quote_Proposal__c).Apttus_Proposal__Account__c;
                            listagrmntLodgemntPoint.add(agrmntLodgmntRec);
                        } 
                    } else {
                        Object value;
                        for (String fieldName : APT_AmendRenewUtility.getFieldNames(APT_Agreement_Lodgement_Point__c.getSObjectType())) {
                            if(quoteLodgementFieldNames.contains(fieldName)){
                                value = quoteLodgementPoint.get(fieldName); 
                                agrmntLodgmntRec.put(fieldName,value);
                            }
                        }
                        agrmntLodgmntRec.APT_Agreement__c=mapAgreement.get(quoteLodgementPoint.APT_Quote_Proposal__c);
                        agrmntLodgmntRec.APT_Organisation__c =mapQuote.get(quoteLodgementPoint.APT_Quote_Proposal__c).Apttus_Proposal__Account__c;
                        listagrmntLodgemntPoint.add(agrmntLodgmntRec);
                    }
                }
                
                if(listagrmntLodgemntPoint.size() > 0) {
                    insert listagrmntLodgemntPoint ;
                }
            }
            
            //creating agreement rate card
            Set<Id> setPropLineItemId = mapProposalLineItem.keySet();
            list<APT_Line_Item_Rate_Card__c> listLineItemRateCard = database.query(APT_Constants.SOQL_SELECT + APT_AmendRenewUtility.getAllAgrFields(APT_Constants.SOQL_LINE_ITEM_RATE_CARD_OBJECT) + APT_Constants.SOQL_LINE_ITEM_RATE_CARD_FROM);
            list<APT_Agreement_Rate_Card__c> listClonedAgreementRateCard = new list<APT_Agreement_Rate_Card__c>();
            Set<String> sourceFieldNames = new Set<String>(APT_AmendRenewUtility.getFieldNames(APT_Agreement_Rate_Card__c.getSObjectType()));
            if(listLineItemRateCard != null && listLineItemRateCard.size() > 0) {
                APT_Agreement_Rate_Card__c clonedAgreementRateCard;
                for(APT_Line_Item_Rate_Card__c lirc : listLineItemRateCard) {
                    system.debug('*** lirc ****'+lirc);
                    clonedAgreementRateCard = new APT_Agreement_Rate_Card__c();
                    
                    for (String fieldName : APT_AmendRenewUtility.getFieldNames(APT_Line_Item_Rate_Card__c.getSObjectType())) {
                        if(sourceFieldNames.contains(fieldName)){
                            Object value = lirc.get(fieldName);
                            clonedAgreementRateCard.put(fieldName,value);
                        }
                    }
                    
                    Apttus_Proposal__Proposal_Line_Item__c propLineItemRec = mapProposalLineItem.get(lirc.APT_Proposal_Line_Item__c);
                    if(propLineItemRec != null){
                        Apttus__AgreementLineItem__c agreementLineItem = mapAgreementLineItem.get(propLineItemRec.Apttus_Proposal__Product__c + APT_Constants.SEPERATOR_SIMILARITY + propLineItemRec.Apttus_QPConfig__LineNumber__c + APT_Constants.SEPERATOR_SIMILARITY + propLineItemRec.Apttus_QPConfig__ItemSequence__c);
                        if(agreementLineItem != null) {
                            clonedAgreementRateCard.APT_Agreement_Line_Item__c = agreementLineItem.Id;
                            clonedAgreementRateCard.APT_Agreement__c = agreementLineItem.Apttus__AgreementId__c;
                            listClonedAgreementRateCard.add(clonedAgreementRateCard);
                        }
                    }
                    
                    
                }
            }
            
            if(listClonedAgreementRateCard.size() > 0) {
                system.debug('listClonedAgreementRateCard--->' + listClonedAgreementRateCard);
                insert listClonedAgreementRateCard;
            }
            system.debug(Logginglevel.ERROR, 'Sucess');
            
            if(agreementIDSet.size() > 0){
                /*
                //1084
                map<Id, String> mapOS = new map<Id, String>();
                for(Apttus__APTS_Agreement__c agreement : [SELECT Id, Included_Product_Lines__c, Operational_Schedule__c
                                                            FROM Apttus__APTS_Agreement__c
                                                            WHERE Id IN :agreementIDSet]) {
                    mapOS.put(agreement.Operational_Schedule__c, agreement.Included_Product_Lines__c);
                }
                system.debug('*** mapOS ***'+mapOS);
                String includedProductLines;
                list<APT_Operational_Schedule__c> listUpdateOS = new list<APT_Operational_Schedule__c>();
                APT_Operational_Schedule__c os = new APT_Operational_Schedule__c();
                for(Id osId : mapOS.keySet()) {
                    os = new APT_Operational_Schedule__c();
                    includedProductLines = null;
                    os.Id = osId;
                    includedProductLines = mapOS.get(osId);
                    if(String.isNotBlank(includedProductLines) && includedProductLines.contains(APT_Constants.EPARCELS_DOMESTIC)) {
                        os.APT_Parcel__c = true;
                    } else {
                        os.APT_Parcel__c = false;
                    }
                    
                    if(String.isNotBlank(includedProductLines) && includedProductLines.contains(APT_Constants.INTERNATIONAL)) {
                        os.APT_International_Postal__c = true;
                    } else {
                        os.APT_International_Postal__c = false;
                        system.debug('*** os.APT_International_Postal__c ***'+os.APT_International_Postal__c);
                    }
                    
                    listUpdateOS.add(os);
                }
                system.debug('*** listUpdateOS ***'+listUpdateOS);
                if(listUpdateOS.size() > 0) {
                    update listUpdateOS;
                }
                //1084
                */
                
                List<Apttus__APTS_Agreement__c> agreementListToBeUpdated = new List<Apttus__APTS_Agreement__c>();
                Apttus__APTS_Agreement__c agreement;
                for(String agrmtID : agreementIDSet){
                    agreement = new Apttus__APTS_Agreement__c();
                    agreement.Id = agrmtID;
                    agreement.APT_Ratecards_Created__c = true;
                    
                    //DoV
                    agreement.APT_New_Pricing__c = bNewPricing;
                    system.debug('*** agreement.APT_New_Pricing__c ***'+agreement.APT_New_Pricing__c);
                    //DoV
                    
                    system.debug('*** rate cards created? ***'+agreement.APT_Ratecards_Created__c);
                    agreementListToBeUpdated.add(agreement);
                }
                update agreementListToBeUpdated;
            }
            
            //return APT_Constants.SUCCESS_LABEL;
        /*
        }catch(Exception e){
            system.debug(Logginglevel.ERROR, e.getMessage());
            throw e;
            //return e.getMessage();
        }
        */
    }
}