/**
 * Created by: Sautul Mehta
 * Description: Test Class for view rate card handler
 * @changelog
 * 2021-10-05 - Sautul Mehta - Class Created as part of CI-8
 */
@istest
public class APT_ViewRateCardHandlerTest {
    
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
        
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;
        
        //Create Opportunity
        Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
        insert opty;
        
        //Create PriceList
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;

        Product2 bundle1 = APT_TestUtils.createDomesticProduct('APPC','APPC','APPC',null,null);
        bundle1.APT_Product_type__c = 'APPC';
        bundle1.Lodgement_Zone__c = 'Country';
        bundle1.APT_Apttus_Product_Classification__c = 'APPC';
        
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
                                                                                 1, 'Option', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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
    public static void testProcess(){ 
        Apttus_Config2__ProductConfiguration__c cart = [select Id from Apttus_Config2__ProductConfiguration__c];
        string configLineId = cart.Id; 
        APT_ViewRateCardHandler viewRateCardHandler = new APT_ViewRateCardHandler();
        viewRateCardHandler.process(configLineId);
    }
    
    @istest
    public static void testGenerateDocument(){
        APT_ViewRateCardHandler viewRateCardHandler = new APT_ViewRateCardHandler();
        Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c];
        string proposalId = proposal.Id;
        viewRateCardHandler.generateDocument(proposalId);
    }
    
     @istest 
    public static void createLineItemRateCard(){
        APT_ViewRateCardHandler viewRateCardHandler = new APT_ViewRateCardHandler();
        Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c];
        string proposalId = proposal.Id;
        Apttus_Config2__ProductConfiguration__c config = [Select Id from Apttus_Config2__ProductConfiguration__c];
        string cartId = config.Id;
        viewRateCardHandler.createLineItemRateCard(cartId, proposalId);
    }
}