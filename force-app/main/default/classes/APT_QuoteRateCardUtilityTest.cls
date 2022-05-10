@istest
public class APT_QuoteRateCardUtilityTest {
    
    @testSetup 
    public static void setup() { 
        // Create APPC Zone Mappings
        List<APT_APPC_Definition__c> appcZoneMappings = new List<APT_APPC_Definition__c>();
        appcZoneMappings.add( new APT_APPC_Definition__c(APT_Price_Model__c = 'Z6', APT_Lodgement__c = 'Country', 
                                                         APT_Dest_Zone1__c = 'Same State',  APT_Dest_Zone2_In_RateCard__c = 'Capital/Local', 
                                                         APT_Dest_Zone2__c= 'Local'));
        appcZoneMappings.add(new APT_APPC_Definition__c(APT_Price_Model__c = 'Z6', APT_Lodgement__c = 'Country', 
                                                        APT_Dest_Zone1__c = 'Same State', APT_Dest_Zone2_In_RateCard__c = 'Capital', 
                                                        APT_Dest_Zone2__c= 'Local'));
        insert appcZoneMappings;      
        
        // Create Option Product
        //Product2 optionProduct = new Product2(Name = 'APPC', Lodgement_Zone__c = 'Country');
        //insert optionProduct;
        
        
        // Create Config Line Item
        // Apttus_Config2__LineItem__c configLineItem1 = new Apttus_Config2__LineItem__c( Apttus_Config2__OptionId__c = optionProduct.Id);
        // insert configLineItem1;
        
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;
        
        //Create Opportunity
        Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
        insert opty;
        
        //Create PriceList
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;

        Product2 bundle1 = APT_TestUtils.createDomesticProduct('APPC','APPC','Others',null,null);
        bundle1.APT_Product_type__c = 'APPC';
        bundle1.Lodgement_Zone__c = 'Country';
        insert bundle1;
        
        //Create Price list Item
        Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
        insert pli;
        
        //Create Proposal
        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
        insert Proposal;
        
        //Create Product Configuration             
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                   proposal.Id, 'Proposal',
                                                                                                   'Ad Hoc',priceList.Id, null,
                                                                                                   'Ready For Finalization',
                                                                                                   null, Datetime.now(), true);
        insert prodconfig;
        
        // Create LineItem
        Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                                 1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                                 null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
                                                                                 'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
                                                                                 'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                 true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
                                                                                 5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        
        bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
        bundleLine.Apttus_Config2__NetPrice__c = 5225; 
        bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
        bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
        bundleLine.Apttus_Config2__OptionId__c = bundle1.Id;
        insert bundleLine;       
        
        //Create product Attribute value                
        Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
        attribute1.Category__c='CAT1';
        attribute1.APT_Postcode__c = '2000';
        attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
        attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
        attribute1.APTS_Price_Structure__c = 'Z6';
        insert attribute1; 
        
        Apttus__APTS_Template__c template = new Apttus__APTS_Template__c(Name = 'APPC_RateCard');
        insert template;
    }
    
    @istest
    public static void testGetColumnsToConstructQuoteRateCards(){
        APT_QuoteRateCardUtility quoteRateCardUtility = new APT_QuoteRateCardUtility();
        list<Decimal> weightCodes = new list<Decimal>{0.5, 22, 5, 1, 2};
            list<string> weightUnits = new list<string> {'PerKg', 'Base'};
                list<string> columns = quoteRateCardUtility.getColumnsToConstructQuoteRateCards(weightCodes, weightUnits);
        list<string> expectedColumns = new list<string> { '0.5_Base', '0.5_PerKg', 
            '1_Base', '1_PerKg', '2_Base', '2_PerKg', '5_Base', '5_PerKg', '22_Base', '22_PerKg' };
                for(Integer index = 0; index < columns.size(); index++){
                    system.assertEquals(columns[index], expectedColumns[index]);            
                }
    }
    
    @isTest
    public static void testAssignQuoteRateCardValues(){
        APT_QuoteRateCardUtility quoteRateCardUtility = new APT_QuoteRateCardUtility();
        list<string> values = new list<string>{'2', '3.7', '1', '4.5', '5', ''};
            APT_Quote_Rate_Card__c quoteRateCard = quoteRateCardUtility.assignQuoteRateCardValues(values);
        
        System.assert(quoteRateCard.APT_value_2__c == values[0]);
        System.assert(quoteRateCard.APT_value_3__c == values[1]);
        System.assert(quoteRateCard.APT_value_4__c == values[2]);
        System.assert(quoteRateCard.APT_value_5__c == values[3]);
        System.assert(quoteRateCard.APT_value_6__c == values[4]);
        System.assert(quoteRateCard.APT_value_7__c == values[5]);
        System.assert(quoteRateCard.APT_value_8__c == values[5]);
        System.assert(quoteRateCard.APT_value_9__c == values[5]);
        System.assert(quoteRateCard.APT_value_10__c == values[5]);
    }
    
    @istest
    public static void testConstructFlatRateCardValues(){
        APT_QuoteRateCardUtility quoteRateCardUtility = new APT_QuoteRateCardUtility();
        map<string, Apttus_Config2__UsagePriceTier__c> uptValuesMap = new map<string, Apttus_Config2__UsagePriceTier__c>();
        uptValuesMap.put('P1_0.5_Base', new Apttus_Config2__UsagePriceTier__c(Apttus_Config2__AdjustmentAmount__c = 1.25));
        uptValuesMap.put('P1_1_PerKg', new Apttus_Config2__UsagePriceTier__c(Apttus_Config2__AdjustmentAmount__c = 2.7));
        string product = 'P1';
        
        list<string> weightCode_UnitKeys = new list<string> { '0.5_Base', '0.5_PerKg', 
            '1_Base', '1_PerKg', '2_Base', '2_PerKg', '5_Base', '5_PerKg', '22_Base', '22_PerKg' };
                
                list<string> flatRateCardValues = quoteRateCardUtility.constructFlatRateCardValues(weightCode_UnitKeys, uptValuesMap, product);
        
        System.assert(flatRateCardValues[0] == '1.25');
        System.assert(flatRateCardValues[3] == '2.7');
        System.assert(flatRateCardValues[1] == '0');
        System.assert(flatRateCardValues[2] == '0');
    }
    
    @istest
    public static void testCalculateRateCardValues(){
        APT_QuoteRateCardUtility quoteRateCardUtility = new APT_QuoteRateCardUtility();
        list<string> flatRateCardValues = new list<string> { '1.5', '0', '2.5', '0', '3.5', '0', '2', '0.5'};
            list<decimal> weightCodes = new list<decimal> { 0.5, 1, 5, 22};
                list<string> rateCardValues = quoteRateCardUtility.calculateRateCardValues(flatRateCardValues, weightCodes);
        list<string> expectedValues = new list<string>{'1.5', '2.5', '3.5', '2', '0.5'};
            
            for(Integer i = 0; i< rateCardValues.size(); i++){
                System.assert(rateCardValues[i] == expectedValues[i]);        
            }
    }
    
    //public virtual list<APT_Quote_Rate_Card__c> createQuoteRateCards(map<string, Apttus_Config2__UsagePriceTier__c> uptValuesMap, list<string> products, list<string> weightCode_UnitKeys, list<Decimal> weightCodes, string configLineId){
    @istest
    public static void testCreateQuoteRateCards(){
        APT_QuoteRateCardUtility quoteRateCardUtility = new APT_QuoteRateCardUtility();
        
        map<string, Apttus_Config2__UsagePriceTier__c> uptValuesMap = new map<string, Apttus_Config2__UsagePriceTier__c>();
        list<string> products = new list<string>();
        list<string> weightCode_UnitKeys = new list<string>();
        list<Decimal> weightCodes = new list<Decimal>();
        
        Apttus_Config2__LineItem__c configLineItem = [select Id from Apttus_Config2__LineItem__c];
        string configLineId = configLineItem.Id;
        
        list<APT_Quote_Rate_Card__c> quoteRateCards =  quoteRateCardUtility.createQuoteRateCards(uptValuesMap, products, weightCode_UnitKeys, weightCodes, configLineId);
    }
}