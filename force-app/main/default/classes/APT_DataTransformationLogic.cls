/**
 * Created by: Sautul Mehta
 * Description: Class to have the data transformation logic wrapper for APPC Rate Card.
 * @changelog
 * 2021-10-05 - Sautul Mehta - Class Created as part of CI-8
 */
global with sharing class APT_DataTransformationLogic {
    static string separator = '_';
    
    private static list<string> products {get;set;}
    private static list<Decimal> weightCodes {get;set;}
    private static list<string> weightUnits {get;set;}
    private static map<string, Apttus_Config2__UsagePriceTier__c> uptValuesMap {get;set;}
    private static string priceModel {get;set;}
    private static string lodgementZone {get;set;}
    private APT_IQuoteRateCardUtility quoteRateCardUtility {get;set;}
    
    public APT_DataTransformationLogic(APT_IQuoteRateCardUtility quoteRateCardUtility){
        products = new list<string>();
        weightCodes = new list<Decimal>();
        weightUnits = new list<string>();
        uptValuesMap =  new map<string, Apttus_Config2__UsagePriceTier__c>();
        priceModel =  '';
        lodgementZone =  '';
        this.quoteRateCardUtility = quoteRateCardUtility;
    }
    
    // method to transform upt values to quote rate card structure which 
    // will be used for XAC
    public list<APT_Quote_Rate_Card__c> transformUPTToQuoteRateCard(string configLineId) {  
        
        // get UPT data based on config line item
        list<Apttus_Config2__UsagePriceTier__c> upts = quoteRateCardUtility.getUPTs(configLineId);
        
        // populate the uptValuesMap, products, weightCodes, weightUnits based on the passed UPTs
        processUPTs(upts);
        
        // get keys for constructing the unique columns for quote rate card based on weightCodes, weightUnits.
        // for eg: 0.5_base, 0.5_kg, 1_base, 1_kg, ...
        list<string> weightCode_UnitKeys = quoteRateCardUtility.getColumnsToConstructQuoteRateCards(weightCodes, weightUnits);
         
        // generate quote rate cards based on the products as y-axis, weightCode_UnitKeys as x axis and 
        // amount from uptValuesMap 
        return quoteRateCardUtility.createQuoteRateCards(uptValuesMap, products, weightCode_UnitKeys, weightCodes, configLineId);
    }
    
    // To populate the uptValuesMap, products, weightCodes, weightUnits
    private void processUPTs(list<Apttus_Config2__UsagePriceTier__c> upts){
        
        // Set is used as we can get rid of duplicate values
        Set<Decimal> weightCodesSet = new Set<Decimal>(); // dimension 2 values
        Set<string> weightUnitsSet = new Set<string>(); // dimension 3 values
        Set<String> dimension1values = new set<string>();
        
        // traverse through the upt list and populate the values in set
        for(Apttus_Config2__UsagePriceTier__c upt : upts){
            dimension1values.add(upt.Apttus_Config2__Dimension1Value__c);
            weightCodesSet.add(Decimal.valueOf(upt.Apttus_Config2__Dimension2Value__c));
            weightUnitsSet.add(upt.Apttus_Config2__Dimension3Value__c);
            uptValuesMap.put(upt.Apttus_Config2__Dimension1Value__c + separator + upt.Apttus_Config2__Dimension2Value__c + separator + upt.Apttus_Config2__Dimension3Value__c, upt);
        }
        
        // convert set to list as sorting can be done and index elements can be fetched.
        products = new list<string>(dimension1values);
        weightCodes = new list<Decimal>(weightCodesSet);
        weightUnits = new list<string>(weightUnitsSet);
    }
}