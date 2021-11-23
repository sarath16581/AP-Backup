/**
 * Description: Create Price List, Price List Item, Price Matrix and Price Matrix records for contract
 * Created By - Mausam Padhiyar
 * Created Date - 15th Sept, 2016
 * 
 * How to execute?
 * Id jobID = System.enqueueJob(new APT_ContractPricingQueueable(new Set<ID>{'a4wO00000004M0bIAE'}));
 */
public with sharing class APT_ContractPricingQueueable implements Queueable {
    
    public set<Id> setAgreementId;
    
    /**
     * Constructor
     */
    public APT_ContractPricingQueueable(set<id> agreemenIdSet) {
        setAgreementId = agreemenIdSet;
    }
    
    /**
     * execute
     */
    public void execute(QueueableContext context) {
        Savepoint sp = Database.setSavepoint();
        try {
            system.debug('*** start ***'+setAgreementId.size());
            set<String> setContractNumber = new set<String>();
            //map<String, set<String>> mapPriceListItem = new map<String, set<String>>();
            //set<String> setExistingPLI;
            set<Id> setExistingPriceListItemIds = new set<Id>();
            //set<Id> setExistingProductIds = new set<Id>();
            map<String, String> mapExistingPriceListItem = new map<String, String>();
            set<Id> setExistingLineItemIds = new set<Id>();
            map<String, String> mapLineItemByAgreement = new map<String, String>();
            list<Apttus__AgreementLineItem__c> listAgreementLineItem = [SELECT Id, Apttus__AgreementId__c, Apttus__AgreementId__r.APT_Contract_Number__c,
                                                                        Apttus_CMConfig__DerivedFromId__c, Apttus__ListPrice__c, 
                                                                        Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__PriceListItemId__c,
                                                                        Apttus__ProductId__c, Apttus_CMConfig__OptionId__c,
                                                                        Apttus_CMConfig__OptionId__r.APT_Contract_Pricing__c,
                                                                        Apttus__ProductId__r.APT_Contract_Pricing__c,
                                                                        Apttus__ProductId__r.Name,
                                                                        Apttus_CMConfig__OptionId__r.Name
                                                                        FROM Apttus__AgreementLineItem__c
                                                                        WHERE Apttus__AgreementId__c IN :setAgreementId
                                                                        AND Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__PriceListItemId__c != null
                                                                        AND (Apttus__ProductId__r.APT_Contract_Pricing__c = true 
                                                                        OR Apttus_CMConfig__OptionId__r.APT_Contract_Pricing__c = true)];
            
            if(listAgreementLineItem != null && listAgreementLineItem.size() > 0) {
                for(Apttus__AgreementLineItem__c ali : listAgreementLineItem) {
                    system.debug('**** ali.Apttus_CMConfig__DerivedFromId__c ***'+ali.Apttus_CMConfig__DerivedFromId__c);
                    system.debug('**** ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__PriceListItemId__c ***'+ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__PriceListItemId__c);
                    system.debug('*** product name ***'+ali.Apttus__ProductId__r.Name);
                    system.debug('*** option name ***'+ali.Apttus_CMConfig__OptionId__r.Name);
                    
                    setContractNumber.add(ali.Apttus__AgreementId__c);
                    
                    if(ali.Apttus_CMConfig__DerivedFromId__c != null) {
                        setExistingLineItemIds.add(ali.Apttus_CMConfig__DerivedFromId__c);
                        mapLineItemByAgreement.put(ali.Apttus_CMConfig__DerivedFromId__c, ali.Apttus__AgreementId__c);
                    }
                    
                    
                    if(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__PriceListItemId__c != null) {
                        setExistingPriceListItemIds.add(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__PriceListItemId__c);
                        mapExistingPriceListItem.put(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__PriceListItemId__c, ali.Apttus__AgreementId__c);
                    }
                    
                    /*
                    setExistingProductIds.add(ali.Apttus__ProductId__c);
                    if(ali.Apttus_CMConfig__OptionId__c != null) {
                        setExistingProductIds.add(ali.Apttus_CMConfig__OptionId__c);
                    }
                    */
                }
            }
            
            
            /******** manage price list *********/
            if(setContractNumber.size() > 0) {
                /***** manage price list ******/
                map<String, Apttus_Config2__PriceList__c> mapExistingPriceList = new map<String, Apttus_Config2__PriceList__c>();
                set<Id> setExistingContractPriceListIds = new set<Id>();
                for(Apttus_Config2__PriceList__c priceList : [SELECT Id, Apttus_Config2__ContractNumber__c
                                                        FROM Apttus_Config2__PriceList__c
                                                        WHERE Apttus_Config2__ContractNumber__c IN :setContractNumber]) {
                    
                    setExistingContractPriceListIds.add(priceList.Id);
                    mapExistingPriceList.put(priceList.Apttus_Config2__ContractNumber__c, priceList);
                }
                
                Apttus_Config2__PriceList__c priceList;
                list<Apttus_Config2__PriceList__c> listPriceList = new list<Apttus_Config2__PriceList__c>();
                for(String contractNumber : setContractNumber) {
                    //priceList = mapExistingPriceList.get(contractNumber);
                    if(mapExistingPriceList.get(contractNumber) == null) {
                        priceList = createPriceList(contractNumber, priceList);
                        listPriceList.add(priceList);
                        mapExistingPriceList.put(contractNumber, priceList);
                    }
                }
                
                system.debug('*** new price list ***'+listPriceList.size());
                if(listPriceList.size() > 0) {
                    insert listPriceList;
                }
                
                /******* manage price list item ********/
                map<String, Apttus_Config2__PriceListItem__c> mapNewPriceListItem = new map<String, Apttus_Config2__PriceListItem__c>();
                if(listAgreementLineItem != null && listAgreementLineItem.size() > 0){
                    
                    String pliQuery = APT_Constants.SOQL_SELECT 
                                + APT_AmendRenewUtility.getAllAgrFields('Apttus_Config2__PriceListItem__c') 
                                + ' FROM Apttus_Config2__PriceListItem__c WHERE Id IN :setExistingPriceListItemIds';
                
                    system.debug('*** pliQuery ***'+pliQuery);
                    list<Apttus_Config2__PriceListItem__c> listExistingPLI = database.query(pliQuery);
                    
                    map<Id, Apttus_Config2__PriceListItem__c> mapExistingPLI = new map<Id, Apttus_Config2__PriceListItem__c>();
                    if(listExistingPLI != null && listExistingPLI.size() > 0) {
                        for(Apttus_Config2__PriceListItem__c pli : listExistingPLI) {
                            mapExistingPLI.put(pli.Id, pli);
                        }
                    }
                    
                    map<String, Apttus_Config2__PriceListItem__c> mapExistingContractPLI = new map<String, Apttus_Config2__PriceListItem__c>();
                    Boolean bNewPLI = false;
                    //Apttus_Config2__PriceList__c priceList;
                    Apttus_Config2__PriceListItem__c newPriceListItem;
                    Apttus_Config2__PriceListItem__c existingContractPLI;
                    Apttus_Config2__PriceListItem__c existingPLI;
                    list<Apttus_Config2__PriceListItem__c> listNewPriceListItem = new list<Apttus_Config2__PriceListItem__c>();
                    for(Apttus__AgreementLineItem__c ali : listAgreementLineItem) {
                        bNewPLI = false;
                        priceList = new Apttus_Config2__PriceList__c();
                        existingPLI = new Apttus_Config2__PriceListItem__c();
                        existingPLI = mapExistingPLI.get(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__PriceListItemId__c);
                        priceList = mapExistingPriceList.get(ali.Apttus__AgreementId__c);
                        if(existingPLI != null && priceList != null) {
                            existingContractPLI = new Apttus_Config2__PriceListItem__c();
                            existingContractPLI = mapExistingContractPLI.get(ali.Apttus__AgreementId__c + APT_Constants.SEPERATOR_SIMILARITY + existingPLI.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + existingPLI.Apttus_Config2__ChargeType__c);
                            
                            if(existingContractPLI != null) {
                                if(!existingContractPLI.Apttus_Config2__ChargeType__c.equalsIgnoreCase(existingPLI.Apttus_Config2__ChargeType__c) || !existingContractPLI.Apttus_Config2__PriceType__c.equalsIgnoreCase(existingPLI.Apttus_Config2__PriceType__c)) {
                                    bNewPLI = true;
                                }
                                
                                if(existingContractPLI.Apttus_Config2__HasCriteria__c && existingPLI.Apttus_Config2__HasCriteria__c && !existingContractPLI.Apttus_Config2__Criteria__c.equalsIgnoreCase(existingPLI.Apttus_Config2__Criteria__c)) {
                                    bNewPLI = true;
                                }
                                
                                if((!existingContractPLI.Apttus_Config2__HasCriteria__c && existingPLI.Apttus_Config2__HasCriteria__c) || (existingContractPLI.Apttus_Config2__HasCriteria__c && !existingPLI.Apttus_Config2__HasCriteria__c)) {
                                    bNewPLI = true;
                                }    
                            } else {
                                 bNewPLI = true;
                            }
                            
                            system.debug('*** bNewPLI ***'+bNewPLI);
                            if(bNewPLI) {
                                //new price list item
                                newPriceListItem = new Apttus_Config2__PriceListItem__c();
                                newPriceListItem = createPriceListItem(existingPLI, newPriceListItem, priceList);
                                newPriceListItem.Apttus_Config2__ListPrice__c = ali.Apttus__ListPrice__c;   //list price
                                
                                listNewPriceListItem.add(newPriceListItem);
                                mapNewPriceListItem.put(existingPLI.id, newPriceListItem);
                                mapExistingContractPLI.put(ali.Apttus__AgreementId__c + APT_Constants.SEPERATOR_SIMILARITY + existingPLI.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + existingPLI.Apttus_Config2__ChargeType__c, newPriceListItem);
                            }
                        }
                    }
                    
                    system.debug('*** listNewPriceListItem > size ***'+listNewPriceListItem.size());
                    if(listNewPriceListItem != null && listNewPriceListItem.size() > 0) {
                        insert listNewPriceListItem;
                    }
                }
                
                /**
                String pliQuery = APT_Constants.SOQL_SELECT 
                                + APT_AmendRenewUtility.getAllAgrFields('Apttus_Config2__PriceListItem__c') 
                                + ' FROM Apttus_Config2__PriceListItem__c WHERE Id IN :setExistingPriceListItemIds';
                
                system.debug('*** pliQuery ***'+pliQuery);
                list<Apttus_Config2__PriceListItem__c> listExistingPLI = database.query(pliQuery);
                
                String contractPLIQuery = APT_Constants.SOQL_SELECT 
                                + APT_AmendRenewUtility.getAllAgrFields('Apttus_Config2__PriceListItem__c') 
                                + ', Apttus_Config2__PriceListId__r.Apttus_Config2__ContractNumber__c FROM Apttus_Config2__PriceListItem__c WHERE Apttus_Config2__PriceListId__c IN :setExistingContractPriceListIds AND Apttus_Config2__ProductId__c IN :setExistingProductIds';
                
                system.debug('*** contractPLIQuery ***'+contractPLIQuery);
                list<Apttus_Config2__PriceListItem__c> listExistingContractPLI = database.query(contractPLIQuery);
                
                map<String, list<Apttus_Config2__PriceListItem__c>> mapExistingContractPLI = new map<String, list<Apttus_Config2__PriceListItem__c>>();
                if(listExistingContractPLI != null) {
                    list<Apttus_Config2__PriceListItem__c> listExistingCPLI = new list<Apttus_Config2__PriceListItem__c>();
                    for(Apttus_Config2__PriceListItem__c pli : listExistingContractPLI) {
                        listExistingCPLI = mapExistingContractPLI.get(pli.Apttus_Config2__PriceListId__r.Apttus_Config2__ContractNumber__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ChargeType__c);
                        
                        if(listExistingCPLI != null) {
                            listExistingCPLI.add(pli);
                            mapExistingContractPLI.put(pli.Apttus_Config2__PriceListId__r.Apttus_Config2__ContractNumber__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ChargeType__c, listExistingCPLI);
                        } else {
                            listExistingCPLI = new list<Apttus_Config2__PriceListItem__c>();
                            listExistingCPLI.add(pli);
                            mapExistingContractPLI.put(pli.Apttus_Config2__PriceListId__r.Apttus_Config2__ContractNumber__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ChargeType__c, listExistingCPLI);
                        }
                    }
                }
                
                map<String, Apttus_Config2__PriceListItem__c> mapNewPriceListItem = new map<String, Apttus_Config2__PriceListItem__c>();
                if(listExistingPLI != null && listExistingPLI.size() > 0) {
                    system.debug('*** listExistingPLI > size ***'+listExistingPLI.size());
                    String contractNumber;
                    Boolean bCreateNewPLI = false;
                    Apttus_Config2__PriceListItem__c newPriceListItem;
                    list<Apttus_Config2__PriceListItem__c> listExistingCPLI = new list<Apttus_Config2__PriceListItem__c>();
                    list<Apttus_Config2__PriceListItem__c> listNewPriceListItem = new list<Apttus_Config2__PriceListItem__c>();
                    for(Apttus_Config2__PriceListItem__c pli : listExistingPLI) {
                        contractNumber = mapExistingPriceListItem.get(pli.Id);
                        if(contractNumber != null) {
                            priceList = mapExistingPriceList.get(contractNumber);
                            if(priceList != null) {
                                system.debug('*** priceList ***'+priceList);
                                listExistingCPLI = mapExistingContractPLI.get(contractNumber + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ChargeType__c);
                                if(listExistingCPLI != null) {
                                    system.debug('*** listExistingCPLI > size ***'+listExistingCPLI.size());
                                    //compare contract pli and 
                                    bCreateNewPLI = false;
                                    for(Apttus_Config2__PriceListItem__c cpli : listExistingCPLI) {
                                        system.debug('*** cpli.Apttus_Config2__HasCriteria__c ***'+cpli.Apttus_Config2__HasCriteria__c);
                                        system.debug('*** pli.Apttus_Config2__HasCriteria__c ***'+pli.Apttus_Config2__HasCriteria__c);
                                        if(cpli.Apttus_Config2__HasCriteria__c && pli.Apttus_Config2__HasCriteria__c) {
                                            if(!cpli.Apttus_Config2__ChargeType__c.equalsIgnoreCase(pli.Apttus_Config2__ChargeType__c) 
                                                || !cpli.Apttus_Config2__PriceType__c.equalsIgnoreCase(pli.Apttus_Config2__PriceType__c)
                                                || (!cpli.Apttus_Config2__Criteria__c.equalsIgnoreCase(pli.Apttus_Config2__Criteria__c))) {
                                                
                                                
                                                system.debug('*** cpli.Apttus_Config2__ChargeType__c ***'+cpli.Apttus_Config2__ChargeType__c);
                                                system.debug('*** cpli.Apttus_Config2__PriceType__c ***'+cpli.Apttus_Config2__PriceType__c);
                                                system.debug('*** cpli.Apttus_Config2__Criteria__c ***'+cpli.Apttus_Config2__Criteria__c);
                                                system.debug('*** pli.Apttus_Config2__ChargeType__c ***'+pli.Apttus_Config2__ChargeType__c);
                                                system.debug('*** pli.Apttus_Config2__PriceType__c ***'+pli.Apttus_Config2__PriceType__c);
                                                system.debug('*** pli.Apttus_Config2__Criteria__c ***'+pli.Apttus_Config2__Criteria__c);
                                                
                                                //create new pli
                                                //newPriceListItem = createPriceListItem(pli, newPriceListItem, priceList);
                                                //listNewPriceListItem.add(newPriceListItem);
                                                bCreateNewPLI = true;
                                            }
                                        } else if((!cpli.Apttus_Config2__HasCriteria__c && pli.Apttus_Config2__HasCriteria__c) || (cpli.Apttus_Config2__HasCriteria__c && !pli.Apttus_Config2__HasCriteria__c)){
                                            bCreateNewPLI = true;
                                        } else {}
                                    }
                                    
                                    if(bCreateNewPLI) {
                                        //create new pli
                                        newPriceListItem = createPriceListItem(pli, newPriceListItem, priceList);
                                        listNewPriceListItem.add(newPriceListItem);
                                        mapNewPriceListItem.put(pli.id, newPriceListItem);
                                    }
                                } else {
                                    system.debug('*** no existing pli ***');
                                    //create new pli
                                    newPriceListItem = createPriceListItem(pli, newPriceListItem, priceList);
                                    system.debug('*** newPriceListItem ***'+newPriceListItem);
                                    listNewPriceListItem.add(newPriceListItem);
                                    mapNewPriceListItem.put(pli.id, newPriceListItem);
                                }
                            }
                        }
                    }
                    
                    system.debug('*** listNewPriceListItem > size ***'+listNewPriceListItem.size());
                    if(listNewPriceListItem.size() > 0) {
                        insert listNewPriceListItem;
                    }
                }
                **/
                
                /**** manage price matrix *****/
                String pmQuery = APT_Constants.SOQL_SELECT 
                                + APT_AmendRenewUtility.getAllAgrFields('Apttus_Config2__PriceMatrix__c') 
                                + ',Apttus_Config2__PriceListItemId__r.Apttus_Config2__PriceListId__r.Apttus_Config2__ContractNumber__c, Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c, Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c  FROM Apttus_Config2__PriceMatrix__c WHERE Apttus_Config2__PriceListItemId__c IN :setExistingPriceListItemIds';
                
                system.debug('*** pmQuery ***'+pmQuery);
                list<Apttus_Config2__PriceMatrix__c> listExistingPM = database.query(pmQuery);
                
                map<String, Apttus_Config2__PriceMatrix__c> mapPriceMatrix = new map<String, Apttus_Config2__PriceMatrix__c>();
                set<Id> setExistingPriceMatrixId = new set<Id>();
                
                if(listExistingPM != null && listExistingPM.size() > 0 ) {
                    system.debug('*** listExistingPM > size ***'+listExistingPM.size());
                    system.debug('*** mapNewPriceListItem.keyset ***'+mapNewPriceListItem.keySet());
                    list<Apttus_Config2__PriceMatrix__c> listNewPM = new list<Apttus_Config2__PriceMatrix__c>();
                    Apttus_Config2__PriceMatrix__c newPM = new Apttus_Config2__PriceMatrix__c();
                    Apttus_Config2__PriceListItem__c newPriceListItem = new Apttus_Config2__PriceListItem__c();
                    String strAgreementId;
                    for(Apttus_Config2__PriceMatrix__c pm : listExistingPM) {
                        setExistingPriceMatrixId.add(pm.Id);
                        
                        system.debug('*** pm.Apttus_Config2__PriceListItemId__c ***'+pm.Apttus_Config2__PriceListItemId__c);
                        newPriceListItem = mapNewPriceListItem.get(pm.Apttus_Config2__PriceListItemId__c);
                        
                        strAgreementId = mapExistingPriceListItem.get(pm.Apttus_Config2__PriceListItemId__c);
                        system.debug('*** strAgreementId ***'+strAgreementId);
                        system.debug('*** mapExistingPriceListItem.keySet() ***'+mapExistingPriceListItem.keySet());
                        system.debug('*** pm.Apttus_Config2__PriceListItemId__c ***'+pm.Apttus_Config2__PriceListItemId__c);
                        if(newPriceListItem != null) {
                            system.debug('*** newPriceListItem ***'+newPriceListItem);
                            newPM = new Apttus_Config2__PriceMatrix__c();
                            newPM = createPriceMatrix(pm, newPM, newPriceListItem);
                            
                            listNewPM.add(newPM);
                            system.debug('*** new pm key ***'+strAgreementId + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c);
                            system.debug('*** new pm key ***'+strAgreementId + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c);
                            mapPriceMatrix.put(strAgreementId + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c, newPM);
                        } 
                        /*
                        //existing
                        else {
                            system.debug('*** pm key ***'+strAgreementId + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c);
                            mapPriceMatrix.put(strAgreementId + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c, pm);
                        }
                        */
                    }
                    
                    system.debug('*** listNewPM > size ***'+listNewPM.size());
                    if(listNewPM.size() > 0) {
                        insert listNewPM;
                    }
                }
                
                
                /****** manage price matrix entry *******/
                if(setExistingLineItemIds.size() > 0) {
                    
                    
                    String uptQuery = APT_Constants.SOQL_SELECT 
                                + APT_AmendRenewUtility.getAllAgrFields('Apttus_Config2__UsagePriceTier__c') 
                                + ', Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListId__r.Apttus_Config2__ContractNumber__c, Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c, Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c FROM Apttus_Config2__UsagePriceTier__c WHERE Apttus_Config2__LineItemId__c IN :setExistingLineItemIds';
                
                    system.debug('*** uptQuery ***'+uptQuery);
                    list<Apttus_Config2__UsagePriceTier__c> listExistingUPT = database.query(uptQuery);  
                    set<Id> setDeleteExistingPMId = new set<Id>();
                    
                    if(listExistingUPT != null && listExistingUPT.size() > 0) {
                        system.debug('*** listExistingUPT > size ***'+listExistingUPT.size());
                        Apttus_Config2__PriceMatrixEntry__c pme = new Apttus_Config2__PriceMatrixEntry__c();
                        Apttus_Config2__PriceMatrix__c pm;
                        list<Apttus_Config2__PriceMatrixEntry__c> listPME = new list<Apttus_Config2__PriceMatrixEntry__c>();
                        String strAgreementId;
                        for(Apttus_Config2__UsagePriceTier__c upt : listExistingUPT) {
                            strAgreementId = mapLineItemByAgreement.get(upt.Apttus_Config2__LineItemId__c);
                            system.debug('*** strAgreementId  > pme ***'+strAgreementId);
                            if(String.isNotBlank(strAgreementId)) {
                                system.debug('*** pme key ***'+strAgreementId + APT_Constants.SEPERATOR_SIMILARITY + upt.Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + upt.Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c);
                                pm = mapPriceMatrix.get(strAgreementId + APT_Constants.SEPERATOR_SIMILARITY + upt.Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c + APT_Constants.SEPERATOR_SIMILARITY + upt.Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c);
                                
                                if(pm != null) {
                                    pme = new Apttus_Config2__PriceMatrixEntry__c();
                                    pme = createPriceMatrixEntry(pme, upt, pm);
                                    
                                    setDeleteExistingPMId.add(pm.Id);
                                    listPME.add(pme);
                                }
                            }
                        }
                        
                        system.debug('*** setDeleteExistingPMId > size ***'+setDeleteExistingPMId.size());
                        DELETE [SELECT Id FROM Apttus_Config2__PriceMatrixEntry__c WHERE Apttus_Config2__PriceMatrixId__c IN :setDeleteExistingPMId];
                        
                        system.debug('*** listPME > size ***'+listPME.size());
                        if(listPME != null && listPME.size() > 0) {
                            insert listPME;
                        }
                    }
                }
                
            }
        } catch(system.exception ex) {
            Database.rollback( sp );
        }
    }
    
    /**
     * Create Price List
     */
    public static Apttus_Config2__PriceList__c createPriceList(String contractNumber, Apttus_Config2__PriceList__c priceList) {
        priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = 'Australia Post Price List' + APT_Constants.SEPERATOR_SPACE + contractNumber;
        priceList.Apttus_Config2__Active__c = true;
        priceList.Apttus_Config2__Description__c = 'This Price List is created for Contract Pricing purpose.';
        priceList.Apttus_Config2__ContractNumber__c = contractNumber;
        
        return priceList;
    } 
    
    /**
     * Create Price List Item
     */
    public static Apttus_Config2__PriceListItem__c createPriceListItem(Apttus_Config2__PriceListItem__c existingPLI, Apttus_Config2__PriceListItem__c newPriceListItem,
                                                                        Apttus_Config2__PriceList__c priceList) {

        newPriceListItem = existingPLI.clone(false);
        newPriceListItem.Apttus_Config2__PriceListId__c = priceList.Id;
        newPriceListItem.APTS_Ext_ID__c  = null;
        system.debug('*** price list id ***'+newPriceListItem.Apttus_Config2__PriceListId__c);
        system.debug('*** new Price List Item ***'+newPriceListItem);
        return newPriceListItem;
    }
    
    /**
     * Create Price Matrix
     */
    public static Apttus_Config2__PriceMatrix__c createPriceMatrix(Apttus_Config2__PriceMatrix__c existingPM, Apttus_Config2__PriceMatrix__c newPM,
                                                                        Apttus_Config2__PriceListItem__c newPriceListItem) {

        
        newPM = existingPM.clone(false);
        newPM.Apttus_Config2__PriceListItemId__c = newPriceListItem.Id;
        newPM.APTS_Ext_ID__c = null;
        return newPM;
    }
    
     /**
     * Create Price Matrix Entry
     */
    public static Apttus_Config2__PriceMatrixEntry__c createPriceMatrixEntry(Apttus_Config2__PriceMatrixEntry__c pme, Apttus_Config2__UsagePriceTier__c upt, Apttus_Config2__PriceMatrix__c pm) {
        pme.Apttus_Config2__Sequence__c = upt.Apttus_Config2__Sequence__c;
        pme.Apttus_Config2__AdjustmentType__c = upt.Apttus_Config2__AdjustmentType__c;
        pme.Apttus_Config2__Dimension1Value__c = upt.Apttus_Config2__Dimension1Value__c;
        pme.Apttus_Config2__Dimension2Value__c = upt.Apttus_Config2__Dimension2Value__c;
        pme.Apttus_Config2__Dimension3Value__c = upt.Apttus_Config2__Dimension3Value__c;
        pme.Apttus_Config2__Dimension4Value__c = upt.Apttus_Config2__Dimension4Value__c;
        pme.Apttus_Config2__Dimension5Value__c = upt.Apttus_Config2__Dimension5Value__c;
        pme.Apttus_Config2__Dimension6Value__c = upt.Apttus_Config2__Dimension6Value__c;
        
        pme.Apttus_Config2__AdjustmentAmount__c = upt.Apttus_Config2__AdjustmentAmount__c;
        pme.Apttus_Config2__PriceOverride__c = upt.Apttus_Config2__PriceOverride__c;
        pme.Apttus_Config2__UsageRate__c = upt.Apttus_Config2__UsageRate__c;
        
        pme.Apttus_Config2__TierStartValue__c = upt.Apttus_Config2__TierStartValue__c;
        pme.Apttus_Config2__TierEndValue__c = upt.Apttus_Config2__TierEndValue__c;
        
        pme.Apttus_Config2__PriceMatrixId__c = pm.Id;
        //pme.APTS_Ext_ID__c = null;
        
        system.debug('*** pme ***'+pme.Apttus_Config2__Sequence__c + pme.Apttus_Config2__AdjustmentType__c + pme.Apttus_Config2__Dimension1Value__c + pme.Apttus_Config2__Dimension2Value__c +
                    pme.Apttus_Config2__Dimension2Value__c + pme.Apttus_Config2__Dimension3Value__c + pme.Apttus_Config2__Dimension4Value__c +
                    pme.Apttus_Config2__Dimension5Value__c + pme.Apttus_Config2__Dimension6Value__c + pme.Apttus_Config2__AdjustmentAmount__c + pme.Apttus_Config2__AdjustmentType__c +
                    pme.Apttus_Config2__PriceOverride__c + pme.Apttus_Config2__UsageRate__c + pme.Apttus_Config2__TierStartValue__c +
                    pme.Apttus_Config2__TierEndValue__c + pme.Apttus_Config2__PriceMatrixId__c);
        
        return pme;
    }
}