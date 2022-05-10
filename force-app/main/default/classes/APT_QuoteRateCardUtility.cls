/**
 * Created by: Sautul Mehta 
 * Description: Class for quote rate card utility which is used by data transformation logic
 * @changelog
 * 2021-10-05 - Sautul Mehta - Class Created as part of CI-8
 */
public virtual class APT_QuoteRateCardUtility Implements APT_IQuoteRateCardUtility {

    public string priceModel {get;set;}
    public string lodgementZone {get;set;}
     
    final static string separator = '_';
    static final Integer THRESHOLD_FORMULA = 22; 

    private map<string, Apttus_Config2__UsagePriceTier__c> uptValuesMap {get;set;}

	// Get UPT data based on config line id
    public virtual list<Apttus_Config2__UsagePriceTier__c> getUPTs(string configLineId){
        return [select Id, Apttus_Config2__Dimension1Value__c, Apttus_Config2__Dimension2Value__c, Apttus_Config2__Dimension3Value__c, Apttus_Config2__Dimension4Value__c, Apttus_Config2__Dimension5Value__c, Apttus_Config2__Dimension6Value__c, Apttus_Config2__AdjustmentAmount__c from Apttus_Config2__UsagePriceTier__c where Apttus_Config2__LineItemId__c =: configLineId];
    }
    
    // Construct rate card values with all columns without applying the formula
    public virtual list<string> constructFlatRateCardValues(list<string> weightCode_UnitKeys, map<string, Apttus_Config2__UsagePriceTier__c> uptValuesMap, string product){
        list<string> flatRateCardValues = new list<string>();       
        
        for(Integer i=0; i< weightCode_UnitKeys.size(); i++) {
            string key = product + separator + weightCode_UnitKeys[i]; 
            
            if(uptValuesMap.containsKey(key)){
                flatRateCardValues.add(String.ValueOf(uptValuesMap.get(key).Apttus_Config2__AdjustmentAmount__c));
            }
            else{
                flatRateCardValues.add('0');
            }
        }
        
        return flatRateCardValues;
    }
    
     // get unique combination of weight code and weight unit 
    // weight code unit should be grouped by weight code
    // like 0.5_Bas, 0.5_Kg, then 1_Base, 1_Kg
    public virtual list<string> getColumnsToConstructQuoteRateCards(list<Decimal> weightCodes, list<string> weightUnits){
        
        // sorting the weight codes and units so the data could be in sequqnce 
        // like 0.5_base, 0.5_kg, 1_base, 1_kg
        weightCodes.sort();
        weightUnits.sort();
        
        list<string> weightCode_UnitKeys = new list<string>();
        for(Decimal weightCode : weightCodes){
            for(string weightUnit : weightUnits){
                weightCode_UnitKeys.add(string.valueOf(weightCode) + separator + weightUnit );
            }
        }
        return weightCode_UnitKeys;
    }
    
    // Final construction of Quote Rate Card Object Values
    public virtual APT_Quote_Rate_Card__c assignQuoteRateCardValues(list<string> values){
        Integer arraySize = values.size();
        string emptyString = '';
        APT_Quote_Rate_Card__c quoteRateCard = new APT_Quote_Rate_Card__c();
        quoteRateCard.APT_value_2__c = arraySize>=1? values[0]:emptyString;
        quoteRateCard.APT_value_3__c = arraySize>=2?values[1]:emptyString;
        quoteRateCard.APT_value_4__c = arraySize>=3?values[2]:emptyString;
        quoteRateCard.APT_value_5__c = arraySize>=4?values[3]:emptyString;
        quoteRateCard.APT_value_6__c = arraySize>=5?values[4]:emptyString;
        quoteRateCard.APT_value_7__c = arraySize>=6?values[5]:emptyString;
        quoteRateCard.APT_value_8__c = arraySize>=7?values[6]:emptyString;
        quoteRateCard.APT_value_9__c = arraySize>=8?values[7]:emptyString;
        quoteRateCard.APT_value_10__c = arraySize>=9?values[8]:emptyString;
        quoteRateCard.APT_value_11__c=	arraySize>=10?values[9]:emptyString;
        quoteRateCard.APT_value_12__c=	arraySize>=11?values[10]:emptyString;
        quoteRateCard.APT_value_13__c=	arraySize>=12?values[11]:emptyString;
        quoteRateCard.APT_value_14__c=	arraySize>=13?values[12]:emptyString;
        quoteRateCard.APT_value_28__c=	arraySize>=1?values[arraySize-1]:emptyString;
        
    	return quoteRateCard;
    }
    
    // Convert the flat structure to the calculated columns
    public list<string> calculateRateCardValues(list<string> flatRateCardValues, list<decimal> weightCodes){
        
        Integer flatRateCardValuesCount = flatRateCardValues.size();
        list<string> rateCardValues = new list<string>();
        
        Integer flatRateCardValueIndex = 0;
        Integer weightCodeIndex = 0;
        Integer resetIndex = 0;
        while(flatRateCardValueIndex < flatRateCardValuesCount){
            if(weightCodes[weightCodeIndex] >= THRESHOLD_FORMULA){
                rateCardValues.add(flatRateCardValues[flatRateCardValueIndex]);
                flatRateCardValueIndex++;
                if(resetIndex == 1){
                    resetIndex = 0;
                    weightCodeIndex++;
                }
                else{
                    resetIndex = 1;
                }
            }
            else{
                String rateCardValue =
                    string.valueOf(decimal.valueOf(flatRateCardValues[flatRateCardValueIndex]) 
                                   + (decimal.valueOf(flatRateCardValues[flatRateCardValueIndex+1]) * weightCodes[weightCodeIndex]));
                rateCardValues.add(rateCardValue);
                flatRateCardValueIndex += 2;
                weightCodeIndex++;
                
            }
        }
        
        return rateCardValues;
    }
    
    // Create quote card records
     public virtual list<APT_Quote_Rate_Card__c> createQuoteRateCards(map<string, Apttus_Config2__UsagePriceTier__c> uptValuesMap, list<string> products, list<string> weightCode_UnitKeys, list<Decimal> weightCodes, string configLineId){
		
        // populdate price model and lodgement zone.
        this.extractConfigLineItem(configLineId);
       
        // Get appc definitions data to have the sequnce of products in quote rate card
        list<APT_APPC_Definition__c> appcDefinitions = this.getAPPCDefinitionsData(lodgementZone, priceModel);
        
        list<APT_Quote_Rate_Card__c> quoteRateCards = new list<APT_Quote_Rate_Card__c>();
        
         // This is used in XAC template to merge the first column for APPC rate card with same name
         Integer recordIndexRes = 0;
         
        // loop through appc definition data as those are the all products we will going to have 
        // in output and with the correct sequence
        String currentDestinationZone = '';
        String showColour = '1';
         
        for (APT_APPC_Definition__c appcDefinition : appcDefinitions){
            if(currentDestinationZone == appcDefinition.APT_Dest_Zone1__c){
                recordIndexRes = 0;
            }
            else{
                recordIndexRes = 1;
                currentDestinationZone = appcDefinition.APT_Dest_Zone1__c;
                showColour = showColour == '1'? '0':'1';
            }

            // define the keys will will be compared with products
            // key will be the combination of lodgement, zone1, zone2 on doc
            // for eg: Capital_Interstate_Capital
            string appcKey = appcDefinition.APT_Lodgement__c + separator +   
                appcDefinition.APT_Dest_Zone1__c + separator + appcDefinition.APT_Dest_Zone2__c;
            
            string product = '';
            for(string p : products){
                if(p == appcKey){
                    product = p;
                }
            }
            
            list<string> flatRateCardValues = constructFlatRateCardValues(weightCode_UnitKeys, uptValuesMap, product);
            
            // Convert the flat structure to the calculated columns
            list<string> calculatedRateCardValues = this.calculateRateCardValues(flatRateCardValues, weightCodes);
            calculatedRateCardValues.add(product);
            calculatedRateCardValues.add(configLineId);
            calculatedRateCardValues.add(appcDefinition.APT_Dest_Zone1__c);
            calculatedRateCardValues.add(appcDefinition.APT_Dest_Zone2_In_RateCard__c);
            
            // This logic is added specifically for XAC template to show the alternate colour in rate card template.
            calculatedRateCardValues.add(string.valueof(recordIndexRes));
            calculatedRateCardValues.add(showColour);
            
            // Final construction of Quote Rate Card Object Values
            APT_Quote_Rate_Card__c qr = this.assignQuoteRateCardValues(calculatedRateCardValues);
            qr.APT_Line_Item__c = configLineId;
            
            quoteRateCards.add(qr);
        }
        
        return quoteRateCards;
    }
    
    // Fetching config line item for speed product to set the value of price model and lodgement zone.
    public virtual void extractConfigLineItem(string lineItemId){
 		Apttus_Config2__LineItem__c configLineItem = 
            [select Id,  Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c, Apttus_Config2__OptionId__r.Lodgement_Zone__c from Apttus_Config2__LineItem__c where Id =: lineItemId LIMIT 1];
         
        priceModel = configLineItem.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c;
         lodgementZone = configLineItem.Apttus_Config2__OptionId__r.Lodgement_Zone__c; 
    }
     
    // Get appc definitions data based on lodgement zone and price model 
    // which is used to define the sequence of products from upt data. 
    private list<APT_APPC_Definition__c> getAPPCDefinitionsData(string lodgementZone, string priceModel){
       	return [select Id, APT_Price_Model__c, APT_Lodgement__c, APT_Dest_Zone1__c, APT_Dest_Zone2__c, APT_Dest_Zone2_In_RateCard__c  from APT_APPC_Definition__c where APT_Price_Model__c =: priceModel and APT_Lodgement__c  =: lodgementZone ORDER BY APT_Sort_Sequence__c];     
    }
}