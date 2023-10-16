/*
* This class will create SAP Rates records for Sync Contract and Rates request
* Created By - Mausam Padhiyar
* Created Date - 26th Aug, 2016

Last Modified By - Shashwat.Nath@Auspost.com.au
Last Modified Date - 10th July, 2020 |  Changes done to capture Price Structure and Cubic Factor for Banded Z6
13 Sep, 2023 : Bharat Patel | Proposal line item's filter update condition to consider APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC
*/

global class APT_CreateSAPRatesBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    global set<String> setPLIId {get; set;}
    global set<Id> setAgreementId {get; set;}
    global set<String> setErrorMessage {get; set;}
    global map<String, Apttus_Proposal__Proposal_Line_Item__c> mapPrimaryPLI {get; set;}
    global map<Id, Id> mapAgreementByPLI {get; set;}
    
    /**
        Constructor
    */
    global APT_CreateSAPRatesBatch(set<String> pliIdSet, set<Id> agreementIdSet, 
                                    map<Id, Id> agreementByPLIMap,
                                    map<String, Apttus_Proposal__Proposal_Line_Item__c> primaryPLIMap) {        
        setPLIId = new set<String>();
        setAgreementId = new set<Id>();
        setErrorMessage = new set<String>();
        mapAgreementByPLI = new map<Id, Id>();
        mapPrimaryPLI = new map<String, Apttus_Proposal__Proposal_Line_Item__c>();
        
        setPLIId = pliIdSet;
        setAgreementId = agreementIdSet;
        mapAgreementByPLI = agreementByPLIMap;
        mapPrimaryPLI = primaryPLIMap; 
    }
    
    /**
        start
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        return Database.getQueryLocator([SELECT Id, Name, APT_Charge_Code_Formula__c,
                                        Apttus_Proposal__Proposal__c,
                                        Apttus_Proposal__Proposal__r.Name,
                                        Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c,
                                        Apttus_QPConfig__IsPrimaryLine__c,
                                        Apttus_QPConfig__ParentBundleNumber__c, 
                                        Apttus_QPConfig__PrimaryLineNumber__c,
                                        Apttus_QPConfig__AttributeValueId__c,
                                        Apttus_QPConfig__DerivedFromId__c,
                                        Apttus_Proposal__Product__c,
                                        Apttus_Proposal__Product__r.ProductCode,
                                        Apttus_QPConfig__OptionId__c,
                                        Apttus_QPConfig__OptionId__r.ProductCode,
                                        Apttus_QPConfig__NetPrice__c,
                                        Apttus_QPConfig__ChargeType__c,
                                        APT_Rate_Card_Key__c,
                                        Apttus_QPConfig__Quantity2__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Price_Structure__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Band__c,
                                        Apttus_QPConfig__AttributeValueId__r.Category__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Consignment_Pricing__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Day_of_Delivery__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Estimated_Revenue__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Industry__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Letters__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Signature_On_Delivery__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Volume_Data__c,
                                        Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.Name,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Minimum_Quantity__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Returns_of_Total_Annual_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Up_to_500g_of_Total_Returns_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Average_Chargeable_Weight_Kg__c,
                                        Apttus_QPConfig__AttributeValueId__r.Transit_cover__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Up_to_500g_Rate__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Base_Uplift_Percentage__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Calculated_Uplift_Percentage__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Average_Weight_Over_500g__c,
                                        Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_1_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_2_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_3_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_4_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_5_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_6_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_7_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_8_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Airmail_Letters_Annual_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelsLT2kgAnnualVolume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelsGT2kgAnnualVolume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_ECI_Documents_Annual_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.ECI_Merchandise_Annual_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_PackNTrackInternationalAnnualVolume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_RegisteredPostInternationalAnnualVol__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_ECI_Documents_AVG_Weight_KG__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_ECI_Merchandise_AVG_Weight_KG__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelGT2kgAVGWeightKG__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelLT2kgAVGWeightKG__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Airmail_Letters_AVG_Weight_KG__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_RegisteredPostInternationalAVGWeight__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_PackNTrackInternationalAVGWeightKG__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Domestic_Customer__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_1Digital_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_2Digital_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_3Digital_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_4Digital_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_5Digital_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_6Digital_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_7Digital_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_8Digital_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Zone_9Digital_Dispersion__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Int_Express_Document_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Int_Express_Doc_Weight_Kg__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Express_Merchandise__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Exp_Merch_Weight_Kgs__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Standard_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Standard_Weight_Kgs__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Standard_W_Sig_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Std_W_Sig_Weight_Kgs__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Economy_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Economy_Weight_Kgs__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Economy_W_Sig_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Eco_W_Sig_Weight_Kgs__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Returns_Express_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Returns_Exp_Weight_Kgs__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Returns_Std_Ut_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Ret_Std_Ut_Weight_Kgs__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Airmail_Letters_Volume__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_International_Airmail_Let_Weight_Kgs__c,
                                        CreatedById,
                                        CreatedBy.Name
                                        FROM Apttus_Proposal__Proposal_Line_Item__c
                                        WHERE Id IN :setPLIId]);
    }
    
    /**
        execute
     */
    global void execute(Database.BatchableContext BC, list<Apttus_Proposal__Proposal_Line_Item__c> listPLI){
        try {
            if(listPLI != null && listPLI.size() > 0) {
                System.debug('listPLI|'+listPLI);
                set<Id> setProposalLineItemId = new set<Id>();
                set<String> setChargeCode = new set<String>();
                for(Apttus_Proposal__Proposal_Line_Item__c pli : listPLI) {
                    setProposalLineItemId.add(pli.Id);
                    setChargeCode.add(pli.APT_Charge_Code_Formula__c);
                }
                
                map<Id, list<Apttus_QPConfig__ProposalUsagePriceTier__c>> mapPUPT = new map<Id, list<Apttus_QPConfig__ProposalUsagePriceTier__c>>();
                list<Apttus_QPConfig__ProposalUsagePriceTier__c> listPUPT;
                
                //available zones
                set<String> setAvailableZones1;
                map<String, set<String>> mapAvailableZones  = new map<String, set<String>>();
                //available zones
                
                list<Apttus_QPConfig__ProposalUsagePriceTier__c> listPUPTByZone;
                map<String, list<Apttus_QPConfig__ProposalUsagePriceTier__c>> mapProposalUsagePriceTierByZone = new map<String, list<Apttus_QPConfig__ProposalUsagePriceTier__c>>();
                
                set<String> setApttusWeightCode;                
                map<String, set<String>> mapApttusWeightCode = new map<String, set<String>>();
                
                decimal dApttusWeightCode = 0;
                decimal dMaxApttusWeightCode;
                map<String, decimal> mapMaxApttusWeightCode = new map<String, decimal>();
                
                for(Apttus_QPConfig__ProposalUsagePriceTier__c pupt : [SELECT Id, Apttus_QPConfig__LineItemId__c, 
                                                                            Apttus_QPConfig__Dimension1Value__c, Apttus_QPConfig__Dimension2Value__c, 
                                                                            Apttus_QPConfig__Dimension3Value__c, 
                                                                            Apttus_QPConfig__UsageRate__c,
                                                                            Apttus_QPConfig__AdjustmentAmount__c, 
                                                                            Apttus_QPConfig__PriceOverride__c,
                                                                            Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c,
                                                                            Apttus_QPConfig__LineItemId__r.Apttus_Proposal__Product__c,
                                                                            Apttus_QPConfig__LineItemId__r.Apttus_Proposal__Product__r.ProductCode,
                                                                            Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__c,
                                                                            Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode,
                                                                            //Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.APT_RAF_Code__c,
                                                                            Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__ChargeType__c,
                                                                            Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c,
                                                                            Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c
                                                                            FROM Apttus_QPConfig__ProposalUsagePriceTier__c
                                                                            WHERE Apttus_QPConfig__LineItemId__c IN :setProposalLineItemId]) {
                    
                    //proposal usage price tier
                    listPUPT = mapPUPT.get(pupt.Apttus_QPConfig__LineItemId__c);      
                    if(listPUPT != null && listPUPT.size() > 0) {
                        listPUPT.add(pupt);
                        mapPUPT.put(pupt.Apttus_QPConfig__LineItemId__c, listPUPT);
                    } else {
                        listPUPT = new list<Apttus_QPConfig__ProposalUsagePriceTier__c>();
                        listPUPT.add(pupt);
                        mapPUPT.put(pupt.Apttus_QPConfig__LineItemId__c, listPUPT);
                    }                     
                    //proposal usage price tier
                                        
                    if(!String.isEmpty(pupt.Apttus_QPConfig__LineItemId__r.Apttus_Proposal__Product__r.ProductCode) && (pupt.Apttus_QPConfig__LineItemId__r.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || pupt.Apttus_QPConfig__LineItemId__r.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) {
                        
                        listPUPTByZone = mapProposalUsagePriceTierByZone.get(pupt.Apttus_QPConfig__LineItemId__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c);
                        if(listPUPTByZone != null) {
                            listPUPTByZone.add(pupt);
                            mapProposalUsagePriceTierByZone.put(pupt.Apttus_QPConfig__LineItemId__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c, listPUPTByZone);
                        } else {
                            listPUPTByZone = new list<Apttus_QPConfig__ProposalUsagePriceTier__c>();
                            listPUPTByZone.add(pupt);
                            mapProposalUsagePriceTierByZone.put(pupt.Apttus_QPConfig__LineItemId__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c, listPUPTByZone);
                        }
                        
                        //available zones 
                        setAvailableZones1 = mapAvailableZones.get(pupt.Apttus_QPConfig__LineItemId__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c);
                        if(setAvailableZones1 != null) {
                            setAvailableZones1.add(pupt.Apttus_QPConfig__Dimension1Value__c);
                            mapAvailableZones.put(pupt.Apttus_QPConfig__LineItemId__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c, setAvailableZones1);
                        } else {
                            setAvailableZones1 = new set<String>();
                            setAvailableZones1.add(pupt.Apttus_QPConfig__Dimension1Value__c);
                            mapAvailableZones.put(pupt.Apttus_QPConfig__LineItemId__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c, setAvailableZones1);
                        }
                        //available zones 
                        
                        setApttusWeightCode = mapApttusWeightCode.get(pupt.Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c);
                        if(setApttusWeightCode != null) {
                            setApttusWeightCode.add(pupt.Apttus_QPConfig__Dimension2Value__c);
                            mapApttusWeightCode.put(pupt.Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c,  setApttusWeightCode);
                        } else {
                            setApttusWeightCode = new set<String>();
                            setApttusWeightCode.add(pupt.Apttus_QPConfig__Dimension2Value__c);
                            mapApttusWeightCode.put(pupt.Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c, setApttusWeightCode);
                        }
                        
                        dApttusWeightCode = 0;
                        if(String.isNotBlank(pupt.Apttus_QPConfig__Dimension2Value__c)) {
                            dApttusWeightCode = decimal.valueOf(pupt.Apttus_QPConfig__Dimension2Value__c);
                        }
                        dMaxApttusWeightCode = mapMaxApttusWeightCode.get(pupt.Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c);
                        if(dMaxApttusWeightCode != null) {                              
                            if(dMaxApttusWeightCode < dApttusWeightCode) {
                                mapMaxApttusWeightCode.put(pupt.Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c, dApttusWeightCode);
                            } 
                        } else {
                            mapMaxApttusWeightCode.put(pupt.Apttus_QPConfig__LineItemId__r.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c, dApttusWeightCode);
                        }
                    }                                           
                }   
                
                //SAP Group Template
                map<String, list<APT_SAP_Group_Template__c>> mapSAPGroupTemplateByChargeCode = new map<String, list<APT_SAP_Group_Template__c>>();
                map<String, set<String>> mapSAPWeightCode = new map<String, set<String>>();
                if(setChargeCode.size() > 0) {       
                    list<APT_SAP_Group_Template__c> listSAPGroupTemplateByChargeCode;
                    set<String> setSAPWeightCode;
                    for(APT_SAP_Group_Template__c sgt : [SELECT Id, Name, APT_Charge_Code__c,
                                                            APT_Display_Order_Sequence__c, APT_Price_Value__c, 
                                                            APT_Price_Value_Description__c, APT_Zone__c,
                                                            APT_Weight_Range_Code__c
                                                            FROM APT_SAP_Group_Template__c
                                                            WHERE APT_Charge_Code__c IN :setChargeCode
                                                            ORDER BY APT_Display_Order_Sequence__c, APT_Price_Value__c]){
                                                
                        //filter by charge code
                        listSAPGroupTemplateByChargeCode = mapSAPGroupTemplateByChargeCode.get(sgt.APT_Charge_Code__c);
                        if(listSAPGroupTemplateByChargeCode != null) {
                            listSAPGroupTemplateByChargeCode.add(sgt);
                            mapSAPGroupTemplateByChargeCode.put(sgt.APT_Charge_Code__c, listSAPGroupTemplateByChargeCode);
                        } else {
                            listSAPGroupTemplateByChargeCode = new list<APT_SAP_Group_Template__c>();
                            listSAPGroupTemplateByChargeCode.add(sgt);
                            mapSAPGroupTemplateByChargeCode.put(sgt.APT_Charge_Code__c, listSAPGroupTemplateByChargeCode);
                        } 
                        
                        setSAPWeightCode = mapSAPWeightCode.get(sgt.APT_Charge_Code__c + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c);
                        if(setSAPWeightCode != null) {
                            setSAPWeightCode.add(sgt.APT_Weight_Range_Code__c);
                            mapSAPWeightCode.put(sgt.APT_Charge_Code__c + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c, setSApWeightCode);
                        } else {
                            setSAPWeightCode = new set<String>();
                            setSAPWeightCode.add(sgt.APT_Weight_Range_Code__c);
                            mapSAPWeightCode.put(sgt.APT_Charge_Code__c + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c, setSApWeightCode);
                        }
                    }
                }
                
                //SAP Group Template
                map<String, set<String>> mapValidWeightCode = prepareValidWeightCodeMap(mapApttusWeightCode, mapSAPWeightCode, mapMaxApttusWeightCode);
                
                list<APT_SAP_Rate__c> listSAPRate = new list<APT_SAP_Rate__c>();
                Id rateRecordTypeId = Schema.SObjectType.APT_SAP_Rate__c.getRecordTypeInfosByName().get(APT_Constants.RATE).getRecordTypeId();
                Id detailedRateRecordTypeId = Schema.SObjectType.APT_SAP_Rate__c.getRecordTypeInfosByName().get(APT_Constants.DETAILED_RATE).getRecordTypeId();
                map<String, APT_SAP_Rate__c> mapSAPRate = new map<String, APT_SAP_Rate__c>();
                Apttus_Proposal__Proposal_Line_Item__c parentPLI;
                
                APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = APT_R2T_International_Pricing_Properties__c.getValues(APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES);
                APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
                
                set<String> setAvailableZones;
                list<APT_SAP_Group_Template__c> listSAPGroupTemplateByChargeCode;
                
                for(Apttus_Proposal__Proposal_Line_Item__c pli : listPLI) {     
                    system.debug('>> pli:' + pli);
                    system.debug('>> mapAgreementByPLI:' + mapAgreementByPLI);
                    Id agreementId = mapAgreementByPLI.get(pli.Id);                    
                    listPUPT = new list<Apttus_QPConfig__ProposalUsagePriceTier__c>();
                    listPUPT = mapPUPT.get(pli.Id);
                    String key;
                    if(pli.Apttus_QPConfig__ParentBundleNumber__c != null) {
                        key = pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + Integer.valueOf(pli.Apttus_QPConfig__ParentBundleNumber__c);
                    }
                    parentPLI = mapPrimaryPLI.get(key);
                    system.debug('>> agreementId:' + agreementId);
                    system.debug('>> listPUPT:' + listPUPT);
                    //system.debug('>> listPUPT.size():' + listPUPT.size());
                    if(agreementId != null && listPUPT != null && listPUPT.size() > 0) {
                        
                        system.debug('pli.Apttus_Proposal__Product__r.ProductCode:' + pli.Apttus_Proposal__Product__r.ProductCode);
                        system.debug('pli.Apttus_Proposal__Product__r.ProductCode:' + pli.Apttus_Proposal__Product__r.ProductCode);
                        //international
                        if(String.isNotBlank(pli.Apttus_Proposal__Product__r.ProductCode) && (pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE) || 
                                         pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL))) {
                            system.debug('Inside International condition');
                               populateInternationalSAPRate(rateRecordTypeId, agreementId, pli, parentPLI, listPUPT, mapSAPRate, listSAPRate, r2tSystemProperties, r2tInternationalPricingProperties);
                        }
                        
                        //domestic
                        else if(String.isNotBlank(pli.Apttus_Proposal__Product__r.ProductCode) && (pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) {
                             populateDomesticSAPRate(rateRecordTypeId, agreementId, pli, parentPLI, listPUPT, mapSAPRate, listSAPRate, r2tSystemProperties, r2tInternationalPricingProperties);
                             
                             //detailed rates
                             if(String.isNotBlank(pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c) && (pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED) || pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC))){
                                listSAPGroupTemplateByChargeCode = new list<APT_SAP_Group_Template__c> ();
                                listSAPGroupTemplateByChargeCode = mapSAPGroupTemplateByChargeCode.get(pli.APT_Charge_Code_Formula__c);
                                System.debug('listSAPGroupTemplateByChargeCode: ' +listSAPGroupTemplateByChargeCode);
                                setAvailableZones = new set<String>();                      
                                setAvailableZones = mapAvailableZones.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c);
                                 System.debug('setAvailableZones:' + setAvailableZones);
                                System.debug('mapProposalUsagePriceTierByZone:' + mapProposalUsagePriceTierByZone);
                                if(listSAPGroupTemplateByChargeCode != null && listSAPGroupTemplateByChargeCode.size() > 0 && setAvailableZones != null && setAvailableZones.size() > 0) {
                                    populateDomesticSAPDetailedRate(detailedRateRecordTypeId, agreementId, listSAPRate, pli, mapSAPRate, setAvailableZones, listSAPGroupTemplateByChargeCode, mapValidWeightCode, mapProposalUsagePriceTierByZone);
                                }                               
                             }
                        }
                    }
                }
                
                if(listSAPRate.size() > 0) {
                    insert listSAPRate;
                }
            }
        } catch(system.exception ex) {
            setErrorMessage.add(ex.getMessage());
            System.debug('Error:>>>>>>' + ex.getMessage());
        }
    }
    
    /**
        Populate SAP Rates for International
    */
    public static void populateInternationalSAPRate(Id rateRecordTypeId, Id agreementId, Apttus_Proposal__Proposal_Line_Item__c pli, 
                                                    Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                    list<Apttus_QPConfig__ProposalUsagePriceTier__c> listPUPT,
                                                    map<String, APT_SAP_Rate__c> mapSAPRate,
                                                    list<APT_SAP_Rate__c> listSAPRate,
                                                    APT_R2T_System_Properties__c r2tSystemProperties,
                                                    APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties) {
        
        APT_SAP_Rate__c sapRate; 
        Integer iCount = 0;       
        for(Apttus_QPConfig__ProposalUsagePriceTier__c pupt : listPUPT) {
            if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL)){
            sapRate = mapSAPRate.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + parentPLI.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension3Value__c); 
                }else{
            sapRate = mapSAPRate.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + parentPLI.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c);
            }
            if(sapRate != null) {
                sapRate = populateRate(sapRate, parentPLI, pupt, APT_Constants.RATE_CARD_TYPE_INTERNATIONAL, r2tSystemProperties, r2tInternationalPricingProperties);   
                if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL)){
                mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + parentPLI.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension3Value__c, sapRate); 
                }else{
                mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + parentPLI.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c, sapRate);          
                 }
            } else {
                sapRate = new APT_SAP_Rate__c();
                sapRate.recordTypeId = rateRecordTypeId;
                sapRate.APT_Apttus_Contract__c = agreementId;
                sapRate.APT_Proposal_Line_Item__c = pli.Id;
                sapRate.APT_Display_Order_Sequence__c = iCount;
                iCount++;           
                sapRate = populateRate(sapRate, parentPLI, pupt, APT_Constants.RATE_CARD_TYPE_INTERNATIONAL, r2tSystemProperties, r2tInternationalPricingProperties);
                if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL)){
                mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + parentPLI.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension3Value__c, sapRate); 
                }else{
                mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + parentPLI.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c, sapRate);          
                }
                listSAPRate.add(sapRate);
            }
        }
    }
    
    /**
        Populate SAP Rates for Domestic
    */
    public static void populateDomesticSAPRate(Id rateRecordTypeId, Id agreementId, Apttus_Proposal__Proposal_Line_Item__c pli, 
                                                Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                list<Apttus_QPConfig__ProposalUsagePriceTier__c> listPUPT,
                                                map<String, APT_SAP_Rate__c> mapSAPRate,
                                                list<APT_SAP_Rate__c> listSAPRate,
                                                APT_R2T_System_Properties__c r2tSystemProperties,
                                                APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties) {
        
        APT_SAP_Rate__c sapRate;      
        Integer iCount = 0;  
        for(Apttus_QPConfig__ProposalUsagePriceTier__c pupt : listPUPT) {
            sapRate = mapSAPRate.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension2Value__c);
            if(sapRate != null) {
                sapRate = populateRate(sapRate, parentPLI, pupt, APT_Constants.RATE_CARD_TYPE_DOMESTIC, r2tSystemProperties, r2tInternationalPricingProperties);
                mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension2Value__c, sapRate);                
            } else {
                sapRate = new APT_SAP_Rate__c();
                sapRate.recordTypeId = rateRecordTypeId;
                sapRate.APT_Apttus_Contract__c = agreementId;
                sapRate.APT_Proposal_Line_Item__c = pli.Id;
                sapRate.APT_Display_Order_Sequence__c = iCount;
                iCount++;               
                sapRate = populateRate(sapRate, parentPLI, pupt, APT_Constants.RATE_CARD_TYPE_DOMESTIC, r2tSystemProperties, r2tInternationalPricingProperties);
                mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension2Value__c, sapRate);                
                listSAPRate.add(sapRate); 
            }
        }
    }
    
    /**
        Populate SAP Detailed Rates for Domestic
    */
    public static void populateDomesticSAPDetailedRate(Id detailedRateRecordTypeId, Id agreementId, list<APT_SAP_Rate__c> listSAPRate, 
                                                        Apttus_Proposal__Proposal_Line_Item__c pli, 
                                                        map<String, APT_SAP_Rate__c> mapSAPRate,
                                                        set<String> setAvailableZones, 
                                                        list<APT_SAP_Group_Template__c> listSAPGroupTemplateByChargeCode,
                                                        map<String, set<String>> mapValidWeightCode,
                                                        map<String, list<Apttus_QPConfig__ProposalUsagePriceTier__c>> mapProposalUsagePriceTierByZone) {
        
        APT_SAP_Rate__c sapDetailedRate;
        
        for(APT_SAP_Group_Template__c sgt : listSAPGroupTemplateByChargeCode) {
            if(setAvailableZones != null) {
                system.debug('setAvailableZones: ' +setAvailableZones);
                system.debug('sgt.APT_Zone__c: '+sgt.APT_Zone__c);
                if(setAvailableZones.contains(sgt.APT_Zone__c)) {
                    list<Apttus_QPConfig__ProposalUsagePriceTier__c> listPUPT = mapProposalUsagePriceTierByZone.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c);
                    if(listPUPT != null) {                        
                        for(Apttus_QPConfig__ProposalUsagePriceTier__c pupt : listPUPT) {
                            if(sgt.APT_Zone__c.equalsIgnoreCase(pupt.Apttus_QPConfig__Dimension1Value__c)) {
                                set<String> validWeightCode = mapValidWeightCode.get(pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension2Value__c);
                                if(validWeightCode != null && validWeightCode.contains(sgt.APT_Weight_Range_Code__c) == true) {
                                    if(mapSAPRate.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c)) != null) {
                                        sapDetailedRate = mapSAPRate.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c));
                                        
                                        sapDetailedRate = populateSAPDetailedRate(sapDetailedRate, sgt, pupt /*, rateCardType*/);
                                        mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c), sapDetailedRate);
                                    } else {
                                        sapDetailedRate = new APT_SAP_Rate__c();
                                        sapDetailedRate.recordTypeId = detailedRateRecordTypeId;
                                        sapDetailedRate.APT_Apttus_Contract__c = agreementId;
                                        sapDetailedRate.APT_Proposal_Line_Item__c = pli.Id;
                                        sapDetailedRate.APT_Display_Order_Sequence__c = sgt.APT_Display_Order_Sequence__c;
                                        sapDetailedRate = populateSAPDetailedRate(sapDetailedRate, sgt, pupt /*, rateCardType*/);
                                        mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c), sapDetailedRate);
                                        listSAPRate.add(sapDetailedRate);
                                    }
                                }
                            }
                        }
                    }
                } else {
                    system.debug('!setAvailableZones.contains(sgt.APT_Zone__c): '+sgt.APT_Zone__c);
                    // APOST-1524 > apply rate N1 => N0, V0 => V1
                    if(!String.isEmpty(sgt.APT_Zone__c) && sgt.APT_Zone__c.contains(APT_Constants.ADD_ZERO)) {
                        
                        String zone = sgt.APT_Zone__c.subString(0, 1);
                        zone += APT_Constants.ONE;
                        system.debug('zone: '+ zone);
                        system.debug('mapProposalUsagePriceTierByZone: '+ mapProposalUsagePriceTierByZone);
                        list<Apttus_QPConfig__ProposalUsagePriceTier__c> listPUPT = mapProposalUsagePriceTierByZone.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + zone);
                        system.debug('pli.Id + APT_Constants.SEPERATOR_SIMILARITY + zone|'+pli.Id + APT_Constants.SEPERATOR_SIMILARITY + zone);
                        System.debug('mainclass: listPUPT'+listPUPT);
                        if(listPUPT != null) {
                            for(Apttus_QPConfig__ProposalUsagePriceTier__c pupt : listPUPT) {
                                if(zone.equalsIgnoreCase(pupt.Apttus_QPConfig__Dimension1Value__c)) {
                                    set<String> validWeightCode = mapValidWeightCode.get(pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension2Value__c);
                                    if(validWeightCode != null && validWeightCode.contains(sgt.APT_Weight_Range_Code__c)) {
                                        if(mapSAPRate.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c)) != null) {
                                            sapDetailedRate = mapSAPRate.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c));
                                            
                                            sapDetailedRate = populateSAPDetailedRate(sapDetailedRate, sgt, pupt /*, rateCardType*/);
                                            mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c), sapDetailedRate);
                                        } else {
                                            sapDetailedRate = new APT_SAP_Rate__c();
                                            sapDetailedRate.recordTypeId = detailedRateRecordTypeId;
                                            sapDetailedRate.APT_Apttus_Contract__c = agreementId;
                                            sapDetailedRate.APT_Proposal_Line_Item__c = pli.Id;
                                          sapDetailedRate.APT_Display_Order_Sequence__c = sgt.APT_Display_Order_Sequence__c;
                                            sapDetailedRate = populateSAPDetailedRate(sapDetailedRate, sgt, pupt /*, rateCardType*/);
                                            mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c), sapDetailedRate);
                                            listSAPRate.add(sapDetailedRate);
                                        }
                                    }
                                }
                            }
                        }
                    } 
                    else if(APT_R2T_SAP_Missing_Zone_Mapping__c.getValues(sgt.APT_Zone__c) != null) {
                        //SAP Missing Zone Mapping i.e. NN, NR, AT
                        APT_R2T_SAP_Missing_Zone_Mapping__c sapMissingZoneMapping = APT_R2T_SAP_Missing_Zone_Mapping__c.getValues(sgt.APT_Zone__c);
                        if(!String.isEmpty(sapMissingZoneMapping.APT_To_Zone__c)) {
                            list<Apttus_QPConfig__ProposalUsagePriceTier__c> listPUPT = mapProposalUsagePriceTierByZone.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + sapMissingZoneMapping.APT_To_Zone__c);
                            if(listPUPT != null) {
                                for(Apttus_QPConfig__ProposalUsagePriceTier__c pupt : listPUPT) {
                                    if(sapMissingZoneMapping.APT_To_Zone__c.equalsIgnoreCase(pupt.Apttus_QPConfig__Dimension1Value__c)) {
                                        set<String> validWeightCode = mapValidWeightCode.get(pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + pupt.Apttus_QPConfig__Dimension2Value__c);
                                        if(validWeightCode != null && validWeightCode.contains(sgt.APT_Weight_Range_Code__c)) {
                                            if(mapSAPRate.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c)) != null) {
                                                sapDetailedRate = mapSAPRate.get(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c));
                                                
                                                sapDetailedRate = populateSAPDetailedRate(sapDetailedRate, sgt, pupt /*, rateCardType*/);
                                                mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c), sapDetailedRate);
                                            } else {
                                                sapDetailedRate = new APT_SAP_Rate__c();
                                                sapDetailedRate.recordTypeId = detailedRateRecordTypeId;
                                                sapDetailedRate.APT_Apttus_Contract__c = agreementId;
                                                sapDetailedRate.APT_Proposal_Line_Item__c = pli.Id;
                                            sapDetailedRate.APT_Display_Order_Sequence__c = sgt.APT_Display_Order_Sequence__c;
                                                sapDetailedRate = populateSAPDetailedRate(sapDetailedRate, sgt, pupt /*, rateCardType*/);
                                                mapSAPRate.put(pli.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Charge_Code_Formula__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + sgt.APT_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + decimal.valueOf(sgt.APT_Weight_Range_Code__c), sapDetailedRate);
                                                listSAPRate.add(sapDetailedRate);
                                            }
                                        }
                                    }
                                }
                            }
                        }                       
                    }
                    else {
                        //0 rates
                        sapDetailedRate = new APT_SAP_Rate__c();
                        sapDetailedRate.recordTypeId = detailedRateRecordTypeId;
                        sapDetailedRate.APT_Apttus_Contract__c = agreementId;
                        sapDetailedRate.APT_Proposal_Line_Item__c = pli.Id;
            sapDetailedRate.APT_Display_Order_Sequence__c = sgt.APT_Display_Order_Sequence__c;
                        //APOST-1374
                        sapDetailedRate.APT_Service_Price_Value__c = sgt.APT_Price_Value__c;
                        sapDetailedRate.APT_Service_Price_Description__c = sgt.APT_Price_Value_Description__c;
                        //APOST-1374
                        sapDetailedRate.APT_Base_Rate__c = 0;
                        sapDetailedRate.APT_Subsequent_Rate__c = 0;
                        sapDetailedRate.APT_Per_Kg_Rate__c = 0;
                        
                        listSAPRate.add(sapDetailedRate);
                    }
                }
            }           
        }       
    }
    
    /**
        Populate SAP Rates
    */
    public static APT_SAP_Rate__c populateRate(APT_SAP_Rate__c sapRate, Apttus_Proposal__Proposal_Line_Item__c parentPLI, Apttus_QPConfig__ProposalUsagePriceTier__c pupt,
                                            String rateCardType, APT_R2T_System_Properties__c r2tSystemProperties,
                                            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties) {
        
        if(String.isNotBlank(pupt.Apttus_QPConfig__Dimension1Value__c)) {
            sapRate.APT_Destination_Zone_Code__c = pupt.Apttus_QPConfig__Dimension1Value__c.ToUpperCase();
        }
        
        /* Shashwat.Nath@Auspost.com.au added the below lines of code to populate the Cubic Factor and Price Structure
           for Banded Z6 Rates Calculation which would be sent as output rate to show in the CSV files being fed to SAP */
        if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c !=null) {
            sapRate.Cubic_Factor__c = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c;
        }
        sapRate.Price_Structure__c = parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c;
        /* Shashwat.Nath@Auspost.com.au Code Ends*/
        //domestic
        if(String.isNotBlank(rateCardType) && rateCardType.equalsIgnoreCase(APT_Constants.RATE_CARD_TYPE_DOMESTIC)) {
            
            if(String.isNotBlank(pupt.Apttus_QPConfig__Dimension2Value__c)) {
                sapRate.APT_Weight_Range_Code__c = decimal.valueOf(pupt.Apttus_QPConfig__Dimension2Value__c);
            }
            
            String serviceType;
            if(String.isNotBlank(parentPLI.Apttus_Proposal__Product__r.ProductCode) && parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)) {
                serviceType = APT_Constants.SERVICE_TYPE_S;
            } else if(String.isNotBlank(parentPLI.Apttus_Proposal__Product__r.ProductCode) && parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)) {
                serviceType = APT_Constants.SERVICE_TYPE_X;
            } else {}
            
            sapRate.APT_Lookup_Full__c = parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c + APT_Constants.SEPERATOR_UNDER_SCROLL + 
                                    serviceType + APT_Constants.SEPERATOR_UNDER_SCROLL + 
                                    parentPLI.Apttus_QPConfig__AttributeValueId__r.Category__c + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                    parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c +
                                    APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                    pupt.Apttus_QPConfig__Dimension2Value__c;  
                                    
            sapRate.APT_Lookup_Sub__c = parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c + APT_Constants.SEPERATOR_UNDER_SCROLL + 
                                        parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c +
                                        APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                        pupt.Apttus_QPConfig__Dimension2Value__c;  
        
            if(String.isNotBlank(pupt.Apttus_QPConfig__Dimension3Value__c)) {
                if(pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_BASE) && pupt.Apttus_QPConfig__UsageRate__c != null) {
                    sapRate.APT_Base_Rate__c = pupt.Apttus_QPConfig__UsageRate__c.setScale(2);
                } 
                
                if(pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT) && pupt.Apttus_QPConfig__UsageRate__c != null) {
                    sapRate.APT_Subsequent_Rate__c = pupt.Apttus_QPConfig__UsageRate__c.setScale(2);
                } else {
                    //Subsequent Rate = Base Rate
                    if(sapRate.APT_Base_Rate__c != null && sapRate.APT_Subsequent_Rate__c == null) {
                        sapRate.APT_Subsequent_Rate__c = sapRate.APT_Base_Rate__c;
                    }
                }
                
                if(pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG) && pupt.Apttus_QPConfig__UsageRate__c != null) {
                    sapRate.APT_Per_Kg_Rate__c = pupt.Apttus_QPConfig__UsageRate__c.setScale(2);
                } 
            }  
        }
        
        //international
        else if(String.isNotBlank(rateCardType) && rateCardType.equalsIgnoreCase(APT_Constants.RATE_CARD_TYPE_INTERNATIONAL)) {
            if(String.isNotBlank(pupt.Apttus_QPConfig__Dimension2Value__c) && pupt.Apttus_QPConfig__Dimension2Value__c.equalsIgnoreCase(APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item) && pupt.Apttus_QPConfig__UsageRate__c != null) {
                sapRate.APT_Base_Rate__c = pupt.Apttus_QPConfig__UsageRate__c.setScale(2);
            } else if(String.isNotBlank(pupt.Apttus_QPConfig__Dimension2Value__c) && pupt.Apttus_QPConfig__Dimension2Value__c.equalsIgnoreCase(APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG) && pupt.Apttus_QPConfig__UsageRate__c != null) {
                sapRate.APT_Per_Kg_Rate__c = pupt.Apttus_QPConfig__UsageRate__c.setScale(2);
            } else {}
            
            sapRate.APT_Subsequent_Rate__c = sapRate.APT_Base_Rate__c;
            
            Boolean bCSP = false;
            if(!parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Letters__c){
                bCSP = true;
            }   

           //For new Products
                Decimal Wt_Range_D;
                Decimal Wt_Range_DR;
                if(pupt.Apttus_QPConfig__Dimension3Value__c == APT_Constants.Weight_Upto500g){
                   Wt_Range_D = decimal.ValueOf(APT_Constants.Weight_0_5);
                   Wt_Range_DR = Wt_Range_D.setscale(1);
                }else if(pupt.Apttus_QPConfig__Dimension3Value__c == APT_Constants.Weight_Over500gupto1kg){
                   Wt_Range_D = decimal.ValueOf(APT_Constants.Weight_1);
                   Wt_Range_DR = Wt_Range_D.setscale(0);
                }else if(pupt.Apttus_QPConfig__Dimension3Value__c == APT_Constants.Weight_Over1kgupto2kg || pupt.Apttus_QPConfig__Dimension3Value__c == APT_Constants.Weight_Upto2kg){
                   Wt_Range_D = decimal.ValueOf(APT_Constants.Weight_2);
                   Wt_Range_DR = Wt_Range_D.setscale(0);
                }else if(pupt.Apttus_QPConfig__Dimension3Value__c == APT_Constants.Weight_Over2kgupto20kg){
                   Wt_Range_D = decimal.ValueOf(APT_Constants.Weight_20);
                   Wt_Range_DR = Wt_Range_D.setscale(0);
                }
                system.debug('pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode: '+ pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode);
            if(String.isNotBlank(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode) && 
                    (pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_DOCT)||
                    pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_MERCH)||                                                                                                                                          
                    pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_STANDARD)||
                    pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_ECONOMY)||
                    pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_RETURNS_EXPRESS)||
                    pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_RETURNS_STANDARD)||
                    pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_STANDARD_SIGN)||
                    pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_ECONOMY_SIGN)
                    )){
            
                    sapRate.APT_Lookup_Full__c = pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_UNDER_SCROLL + Wt_Range_DR;
                    sapRate.APT_Lookup_Sub__c = pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    sapRate.APT_Weight_Range_Code__c = Wt_Range_D;
                    
                    
            }else if(String.isNotBlank(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode) &&
            pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS)){
                    sapRate.APT_Lookup_Full__c =  APT_Constants.AIRLET_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c + APT_Constants.SEPERATOR_UNDER_SCROLL + Wt_Range_DR;
                    sapRate.APT_Lookup_Sub__c = APT_Constants.AIRLET_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    sapRate.APT_Weight_Range_Code__c = Wt_Range_D;
                    sapRate.APT_RAF_Code__c = r2tSystemProperties.APT_AIRMAIL_LETTERS_RAF_Code__c;
            
            }
            else if(String.isNotBlank(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode) && pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT)) {
                //EMSDOCT
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c.equalsIgnoreCase(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__ChargeType__c)) {
                    sapRate.APT_Lookup_Full__c = APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    sapRate.APT_Lookup_Sub__c = APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    
                    //RAF Code
                    if(bCSP && !String.isEmpty(r2tSystemProperties.APT_EMSDOCT_RAF_Code__c)) {
                        sapRate.APT_RAF_Code__c = r2tSystemProperties.APT_EMSDOCT_RAF_Code__c;
                    }
                    
                    //weight range code
                    if(r2tSystemProperties.APT_EMSDOCT_Weight_Range_Code__c != null) {
                        sapRate.APT_Weight_Range_Code__c = r2tSystemProperties.APT_EMSDOCT_Weight_Range_Code__c;
                    }
                }
                //EMSMERCH
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c.equalsIgnoreCase(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__ChargeType__c)) {
                    sapRate.APT_Lookup_Full__c = APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    sapRate.APT_Lookup_Sub__c = APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    
                    //RAF Code
                    if(bCSP && !String.isEmpty(r2tSystemProperties.APT_EMSMERCH_RAF_Code__c)) {
                        sapRate.APT_RAF_Code__c = r2tSystemProperties.APT_EMSMERCH_RAF_Code__c;
                    }
                    
                    //weight range code
                    if(r2tSystemProperties.APT_EMSMERCH_Weight_Range_Code__c != null) {
                        sapRate.APT_Weight_Range_Code__c = r2tSystemProperties.APT_EMSMERCH_Weight_Range_Code__c;
                    }
                }
                //EMSMER20
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c.equalsIgnoreCase(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__ChargeType__c)) {
                    sapRate.APT_Lookup_Full__c = APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    sapRate.APT_Lookup_Sub__c = APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                
                    //RAF Code
                    if(bCSP && !String.isEmpty(r2tSystemProperties.APT_EMSMER20_RAF_Code__c)) {
                        sapRate.APT_RAF_Code__c = r2tSystemProperties.APT_EMSMER20_RAF_Code__c;
                    }
                    
                    //weight range code
                    if(r2tSystemProperties.APT_EMSMER20_Weight_Range_Code__c != null) {
                        sapRate.APT_Weight_Range_Code__c = r2tSystemProperties.APT_EMSMER20_Weight_Range_Code__c;
                    }
                }                   
            } 
            else if(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT)) {
                //AIRPCL
                system.debug('r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c: '+r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c);
                system.debug('pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__ChargeType__c: '+pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__ChargeType__c);
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c) && r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c.equalsIgnoreCase(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__ChargeType__c)) {
                    sapRate.APT_Lookup_Full__c = APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    sapRate.APT_Lookup_Sub__c = APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    
                    //RAF Code
                    if(bCSP && !String.isEmpty(r2tSystemProperties.APT_AIRPCL_RAF_Code__c)) {
                        sapRate.APT_RAF_Code__c = r2tSystemProperties.APT_AIRPCL_RAF_Code__c;
                    } 
                    
                    //weight range code
                    if(r2tSystemProperties.APT_AIRPCL_Weight_Range_Code__c != null) {
                        sapRate.APT_Weight_Range_Code__c = r2tSystemProperties.APT_AIRPCL_Weight_Range_Code__c;
                    }
                }
                //AIRSMPCL
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c) && r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c.equalsIgnoreCase(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__ChargeType__c)) {
                    sapRate.APT_Lookup_Full__c = APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                    sapRate.APT_Lookup_Sub__c = APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                
                    //RAF Code
                    if(bCSP && !String.isEmpty(r2tSystemProperties.APT_AIRSMPCL_RAF_Code__c)) {
                        sapRate.APT_RAF_Code__c = r2tSystemProperties.APT_AIRSMPCL_RAF_Code__c;
                    }
                    
                    //weight range code
                    if(r2tSystemProperties.APT_AIRSMPCL_Weight_Range_Code__c != null) {
                        sapRate.APT_Weight_Range_Code__c = r2tSystemProperties.APT_AIRSMPCL_Weight_Range_Code__c;
                    }
                }
            } 
            else {
                sapRate.APT_Lookup_Full__c = pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                sapRate.APT_Lookup_Sub__c = pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode + APT_Constants.SEPERATOR_UNDER_SCROLL + pupt.Apttus_QPConfig__Dimension1Value__c;
                
                //RAF Code
                if(bCSP && !String.isEmpty(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode) && pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_AIRLET_RAF_Code__c)) {
                    sapRate.APT_RAF_Code__c = r2tSystemProperties.APT_AIRLET_RAF_Code__c;
                } else if(bCSP && !String.isEmpty(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode) && pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_AIRLET_RAF_Code__c)) {
                    sapRate.APT_RAF_Code__c = r2tSystemProperties.APT_AIRRPI_RAF_Code__c;
                } else if(bCSP && !String.isEmpty(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode) && pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_AIRLET_RAF_Code__c)) {
                    sapRate.APT_RAF_Code__c = r2tSystemProperties.APT_AIRPTI_RAF_Code__c;
                } else { }
                
                //weight range code
                if(!String.isEmpty(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode) && pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT) && r2tSystemProperties.APT_AIRLET_Weight_Range_Code__c != null) {
                    sapRate.APT_Weight_Range_Code__c = r2tSystemProperties.APT_AIRLET_Weight_Range_Code__c;
                } else if(!String.isEmpty(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode) && pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT) && r2tSystemProperties.APT_AIRRPI_Weight_Range_Code__c != null) {
                    sapRate.APT_Weight_Range_Code__c = r2tSystemProperties.APT_AIRRPI_Weight_Range_Code__c;
                } else if(!String.isEmpty(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode) && pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT) && r2tSystemProperties.APT_AIRPTI_Weight_Range_Code__c != null) {
                    sapRate.APT_Weight_Range_Code__c = r2tSystemProperties.APT_AIRPTI_Weight_Range_Code__c;
                } else { }
            } 
            
            if(String.isNotBlank(sapRate.APT_Lookup_Full__c)) {
                sapRate.APT_Lookup_Full__c = sapRate.APT_Lookup_Full__c.ToUpperCase();
            }  
            
            if(String.isNotBlank(sapRate.APT_Lookup_Sub__c)) {
                sapRate.APT_Lookup_Sub__c = sapRate.APT_Lookup_Sub__c.ToUpperCase();
            }  
        }
        //none
        else {}
        
        if(pupt.Apttus_QPConfig__UsageRate__c != pupt.Apttus_QPConfig__PriceOverride__c) {
            sapRate.APT_Base_Rate_Manually_Adjusted_Flag__c = APT_Constants.ONE;
            sapRate.APT_Per_Kg_Manually_Adjusted_Flag__c = APT_Constants.ONE;
        }
        
        return sapRate;
    }
    
    /**
        Populate SAP Detailed Rate
    */
    public static APT_SAP_Rate__c populateSAPDetailedRate(APT_SAP_Rate__c sapDetailedRate, APT_SAP_Group_Template__c sgt,
                                                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt) {
        
        sapDetailedRate.APT_Service_Price_Value__c = sgt.APT_Price_Value__c;
        sapDetailedRate.APT_Service_Price_Description__c = sgt.APT_Price_Value_Description__c;
        /* Shashwat.Nath@Auspost.com.au added the below lines of code to populate the Cubic Factor and Price Structure
           for Banded Z6 Rates Calculation which would be sent as output rate to show in the CSV files being fed to SAP */
        sapDetailedRate.APT_Weight_Range_Code__c = decimal.valueOf(sgt.APT_Weight_Range_Code__c);
        sapDetailedRate.Price_Structure__c = pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c;
        if(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c!=null) {
            sapDetailedRate.Cubic_Factor__c = pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c;
        }
        /* Shashwat.Nath@Auspost.com.au code ends */
        
        if(!String.isEmpty(pupt.Apttus_QPConfig__Dimension3Value__c) && pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_BASE) && pupt.Apttus_QPConfig__UsageRate__c != null) {
            sapDetailedRate.APT_Base_Rate__c = pupt.Apttus_QPConfig__UsageRate__c.setScale(2);
        } else if(!String.isEmpty(pupt.Apttus_QPConfig__Dimension3Value__c) && pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT) && pupt.Apttus_QPConfig__UsageRate__c != null) {
            sapDetailedRate.APT_Subsequent_Rate__c = pupt.Apttus_QPConfig__UsageRate__c.setScale(2);
        } else if(!String.isEmpty(pupt.Apttus_QPConfig__Dimension3Value__c) && pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG) && pupt.Apttus_QPConfig__UsageRate__c != null) {
            sapDetailedRate.APT_Per_Kg_Rate__c = pupt.Apttus_QPConfig__UsageRate__c.setScale(2);
        } else {}
        
        if(sapDetailedRate.APT_Base_Rate__c != null && sapDetailedRate.APT_Subsequent_Rate__c == null) {
            sapDetailedRate.APT_Subsequent_Rate__c = sapDetailedRate.APT_Base_Rate__c;
        }
        
        return sapDetailedRate;
    }
    
    /**
        This method will prepare valid weight code information based on SAP Group Template
     */
    public static map<String, set<String>> prepareValidWeightCodeMap(map<String, set<String>> mapApttusWeightCode,
                                                                    map<String, set<String>> mapSAPWeightCode,
                                                                    map<String, decimal> mapMaxApttusWeightCode) {
        
        System.debug('*** prepareValidWeightCodeMap ***');
                                                                        System.debug('*** mapApttusWeightCode=> ' + mapApttusWeightCode);
         System.debug('*** mapSAPWeightCode=> ' + mapSAPWeightCode);
        System.debug('*** mapMaxApttusWeightCode=> ' + mapMaxApttusWeightCode);
        integer i = 0;
        String zone;
        String chargeCode;
        decimal dMaxApttusWeightCode;
        boolean validatePreviousWeightRange = true;
        
        set<String> setApttusWeightCode = new set<String>();
        list<String> listApttusWeightCode = new list<String>();
        map<String, set<String>> mapValidWeightCode = new map<String, set<String>>();
        
        //sap weight code
        for(String strKey : mapSAPWeightCode.keySet()) {
            //apttus weight code
            
            zone = APT_Constants.EMPTY_STRING;
            //setApttusWeightCode.clear();
            setApttusWeightCode = new set<String>();        
            
            if(mapApttusWeightCode.get(strKey) != null) {
                //available in apttus               
                setApttusWeightCode = mapApttusWeightCode.get(strKey);
            } else  {
                //not available in apttus and replace based on customs settings
                Integer iIndex = strKey.indexOf(APT_Constants.SEPERATOR_SIMILARITY);
                zone = strKey.subString(iIndex + 1, strKey.length());
                if(!String.isEmpty(zone) && APT_R2T_SAP_Missing_Zone_Mapping__c.getValues(zone) != null) {                  
                    chargeCode = strKey.subString(0, iIndex);
                    //NN > NT1, NR > NT2, AT > AAT
                    setApttusWeightCode = mapApttusWeightCode.get(chargeCode + APT_Constants.SEPERATOR_SIMILARITY + APT_R2T_SAP_Missing_Zone_Mapping__c.getValues(zone).APT_To_Zone__c);
                }
            }
            
            listApttusWeightCode.clear();
            if(setApttusWeightCode != null) {
                for(String apttusWeightCode : setApttusWeightCode) {
                    listApttusWeightCode.add(apttusWeightCode);
                }
            }
            
            if(listApttusWeightCode != null && listApttusWeightCode.size() > 0) {
                i = 0;
                for(String apttusWeightCode : listApttusWeightCode) {                   
                    for(String sapWeightCode : mapSAPWeightCode.get(strKey)) {                      
                        if(apttusWeightCode != null && sapWeightCode != null) {
                            validatePreviousWeightRange = true;
                            decimal dApttusWeightCode = decimal.valueOf(apttusWeightCode);
                            decimal dSAPWeightCode = decimal.valueOf(sapWeightCode);
                            system.debug('*** dApttusWeightCode => ' + dApttusWeightCode);
                            system.debug('*** dSAPWeightCode => ' + dSAPWeightCode);
                            if(i != 0) {
                                decimal dPrevApttusWeightCode = decimal.valueOf(listApttusWeightCode.get(i - 1));
                                if(dSAPWeightCode <= dPrevApttusWeightCode) {
                                    validatePreviousWeightRange = false;
                                } else {
                                    validatePreviousWeightRange = true;
                                }
                            }
                            
                            if(dSAPWeightCode <= dApttusWeightCode && true == validatePreviousWeightRange) {
                                set<String> setValidWeightCode = mapValidWeightCode.get(strKey + APT_Constants.SEPERATOR_SIMILARITY + apttusWeightCode);
                                if(setValidWeightCode != null) {
                                    setValidWeightCode.add(sapWeightCode);                                        
                                    mapValidWeightCode.put(strKey + APT_Constants.SEPERATOR_SIMILARITY + apttusWeightCode, setValidWeightCode);
                                } else {
                                    setValidWeightCode = new set<String>();
                                    setValidWeightCode.add(sapWeightCode);
                                    mapValidWeightCode.put(strKey + APT_Constants.SEPERATOR_SIMILARITY + apttusWeightCode, setValidWeightCode);
                                }
                            } else {
                                //Manage 62.5 > 63
                                dMaxApttusWeightCode = 0;                               
                                if(mapMaxApttusWeightCode.get(strKey) != null) {
                                    dMaxApttusWeightCode = mapMaxApttusWeightCode.get(strKey);
                                } else {
                                    if(APT_R2T_SAP_Missing_Zone_Mapping__c.getValues(zone) != null) {
                                        dMaxApttusWeightCode = mapMaxApttusWeightCode.get(chargeCode + APT_Constants.SEPERATOR_SIMILARITY + APT_R2T_SAP_Missing_Zone_Mapping__c.getValues(zone).APT_To_Zone__c);
                                    }
                                }                               
                                
                                if(dMaxApttusWeightCode != null && dMaxApttusWeightCode == dApttusWeightCode && math.ceil(dApttusWeightCode) == dSAPWeightCode) {
                                    set<String> setValidWeightCode = mapValidWeightCode.get(strKey + APT_Constants.SEPERATOR_SIMILARITY + apttusWeightCode);
                                    if(setValidWeightCode != null) {
                                        setValidWeightCode.add(sapWeightCode);
                                        mapValidWeightCode.put(strKey + APT_Constants.SEPERATOR_SIMILARITY + apttusWeightCode, setValidWeightCode);
                                    } else {
                                        setValidWeightCode = new set<String>();
                                        setValidWeightCode.add(sapWeightCode);
                                        mapValidWeightCode.put(strKey + APT_Constants.SEPERATOR_SIMILARITY + apttusWeightCode, setValidWeightCode);
                                    }
                                }
                            }
                        }
                    }
                    i++;                    
                }
            }
        }
        System.debug('*** mapValidWeightCode => ' + mapValidWeightCode);
        return mapValidWeightCode;
    }
    
    /**
        Finish
     */
    global void finish(Database.BatchableContext BC) {
        if(setErrorMessage.size() > 0) {
            //send email alert
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :BC.getJobId()];
                        
            if(a.NumberOfErrors > 0) {
                setErrorMessage.add(a.ExtendedStatus);
            }
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
            //get email addresses
            APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
            String emailAddresses;            
            if(r2tSystemProperties != null) {            
                if(!String.isEMpty(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c)) {
                    emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
                }
            } 
            list<String> toAddresses = new list<String>();
            if(!String.isEmpty(emailAddresses)) {
                toAddresses = emailAddresses.split(APT_Constants.SEPERATOR_COMMA);
            }
            mail.setToAddresses(toAddresses);
            
            mail.setSubject(APT_Constants.SYNC_CONTRACT_RATES_ERROR);
            
            //Handle Batch Error Message 
            Integer iErrorCount = setErrorMessage.size();
                
            String errorMessage;
            for(String errorMessage1 : setErrorMessage) {
                if(String.isNotBlank(errorMessage)) {
                    errorMessage += APT_Constants.SEPERATOR_NEW_LINE + errorMessage1;
                } else {
                    errorMessage = errorMessage1;
                }
            }
            
            //add Batch Error Message in Email
            if(String.isNotBlank(errorMessage)) {
                mail.setPlainTextBody(APT_Constants.SYNC_CONTRACT_RATES_BATCH_JOB_COMPLETED_WITH + iErrorCount + APT_Constants.EMAIL_PLAIN_TEXT_PART_3 + errorMessage);
            }
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });           
        } else {
              APT_SyncContractAndRatesBatch controller = new APT_SyncContractAndRatesBatch(setAgreementId, setPLIId);
              database.executeBatch(controller, 1);
        }
    }
}