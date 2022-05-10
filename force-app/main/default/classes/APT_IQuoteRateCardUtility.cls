/**
 * Created by: Sautul Mehta
 * Description: Interface for quote rate card utility which is used by data transformation logic
 * @changelog
 * 2021-10-05 - Sautul Mehta - Interface Created as part of CI-8
 */
public interface APT_IQuoteRateCardUtility {
    
    list<Apttus_Config2__UsagePriceTier__c> getUPTs(string configLineId);
    
    APT_Quote_Rate_Card__c assignQuoteRateCardValues(list<string> values);
    
    list<string> getColumnsToConstructQuoteRateCards(list<Decimal> weightCodes, list<string> weightUnits);
    
    list<string> calculateRateCardValues(list<string> flatRateCardValues, list<decimal> weightCodes);
    
    list<APT_Quote_Rate_Card__c> createQuoteRateCards(map<string, Apttus_Config2__UsagePriceTier__c> uptValuesMap, list<string> products, list<string> weightCode_UnitKeys, list<Decimal> weightCodes, string configLineId);
}