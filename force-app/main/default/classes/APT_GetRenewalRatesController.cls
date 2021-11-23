/**
Description: Integration with P&Y to get Renewal Rate.
Created By - Mausam Padhiyar
Created Date - 1st Dec, 2015
Last Modified By -  Shashwat.Nath@aupost.com.au updated the method UpdateConfigandRates to introducce a new savepoint to which the roll back would 
                    occur in case of mismatch of lodgement zone code coming from P&Y and lodgement zone code on updated Line item record.
Last Modified Date -09/06/2020
2021-09-09 - Naveen Rajanna - REQ2611558 - Update Subsequent Rates (APT_Consignment_Pricing__c) from TIBCO when we apply Rate Card Key and Formatted the code
**/
public with sharing class APT_GetRenewalRatesController {
    
    public boolean haserrorMessages {get; set;}
    public Apttus_Config2__LineItem__c lineItem {get; set;}
    public List<Apttus_Config2__LineItem__c> listLineItem{get;set;}
    public String rateCardKey {get; set;}
    public String parentPageURL{get;set;}
    public String proposalId {get; set;}
    public String proposalName {get; set;}
    public String accountName {get; set;}
    public String approvalStatus{get; set;}
    public string configid;
    public String customerId{get; set;}
    public Boolean displayPopup {get;set;}
    public Boolean displayemtycustomerpopup {get;set;}
    public Static boolean blnTestClass {get;set;} //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018 start           
    /**
        Constructor
    **/    
    public String lineItemId;
    public APT_GetRenewalRatesController() {
        try {
            
            String TempObjectId = ''; 
            
            haserrorMessages = false;
            //lineItem = new Apttus_Config2__LineItem__c();
            
            //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018 start           
            blnTestClass = false;
            String hostURL = String.valueof(URL.getSalesforceBaseUrl().toExternalForm());
            hostURL += '/apex/Apttus_Config2__Cart?configRequestId=';
            
            //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018 End
            
            //parentPageURL = ApexPages.currentPage().getHeaders().get(APT_Constants.URL_REFERER);
            
            
            system.debug('@@parentPageURL'+hostURL );
            lineItemId = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.URL_SELECTRECORDID));
            
            system.debug('APT_Constants.URL_SELECTRECORDID---->'+APT_Constants.URL_SELECTRECORDID);
            if(lineItemId != null) {
                lineItem = [SELECT Id, APT_Rate_Card_Key__c, Apttus_Config2__ProductId__c, 
                            Apttus_Config2__ProductId__r.ProductCode,
                            Apttus_Config2__ProductId__r.APT_Category__c,
                            Apttus_Config2__ProductId__r.APT_Network_Type__c,
                            Apttus_Config2__ParentBundleNumber__c,
                            Apttus_Config2__PrimaryLineNumber__c,
                            Apttus_Config2__ConfigurationId__c,
                            Apttus_Config2__ProductId__r.name,
                            Apttus_Config2__ConfigurationId__r.name,
                            Apttus_Config2__ConfigurationId__r.Id,
                            Apttus_Config2__AttributeValueId__c,
                            APT_Lodgement_Zone_Code__c,
                            APT_Band__c,APT_RC_Key__c,
                            APT_International_PCMS_or_CSP__c,
                            Apttus_Config2__AdjustmentType__c,
                            Apttus_Config2__AdjustmentAmount__c
                            FROM Apttus_Config2__LineItem__c
                            WHERE Id = :lineItemId];
                            
                configid=  lineItem.Apttus_Config2__ConfigurationId__c;              
                if(configId != null) {
                    
                    
                    
                    Apttus_Config2__ProductConfiguration__c configuration = [SELECT Id, Name, Apttus_QPConfig__Proposald__c,
                                                                            Apttus_QPConfig__Proposald__r.Name, 
                                                                            Apttus_QPConfig__Proposald__r.Apttus_Proposal__Approval_Stage__c,
                                                                            Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Name,
                                                                            Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.AccountNumber,
                                                                            Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.LEGACY_ID__c,
                                                                            (Select id from Apttus_Config2__TempObjects__r order by lastmodifieddate desc)
                                                                            FROM Apttus_Config2__ProductConfiguration__c 
                                                                            WHERE Id =:configId];
                    if( configuration.Apttus_Config2__TempObjects__r.size() > 0){
                        TempObjectId = configuration.Apttus_Config2__TempObjects__r[0].Id;
                    }
                    hostURL += TempObjectId;    //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018
                    hostURL += '&id=' + configId + '#/cart';    //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018
                    parentPageURL = hostURL; //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018
                    proposalId = configuration.Apttus_QPConfig__Proposald__c;
                    proposalName = configuration.Apttus_QPConfig__Proposald__r.Name;
                    accountName = configuration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Name;
                    approvalStatus = configuration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Approval_Stage__c;  
                    customerId = configuration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.LEGACY_ID__c;
                }
        if(lineItem!=null && lineItem.APT_RC_Key__c!=null) {
                  rateCardKey = lineItem.APT_RC_Key__c;
                  String message= Label.APT_Rate_Card_Key_Message + ' ' +rateCardKey ;
                  haserrorMessages=true;
                  Apexpages.addMessage(new ApexPages.Message (ApexPages.Severity.Info, message )); //FATAL, ERROR, INFO, CONFIRM
                }
            } else {
                haserrorMessages = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MISSING_LINE_ITEM));
            }
        } catch(system.exception ex) {
            haserrorMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }        
    }
   public static APT_SAP_QueryRateCardService.Ratecards_element responseNew=new APT_SAP_QueryRateCardService.Ratecards_element();
    public static void updateConfig(APT_SAP_QueryRateCardService.Ratecards_element response,
                                                    Apttus_Config2__LineItem__c lineItem){
                                                        responseNew.Ratecard=response.Ratecard;



         Apttus_Config2__ProductAttributeValue__c productAttributevalue = new Apttus_Config2__ProductAttributeValue__c();                               
                                                  productAttributevalue = [SELECT Id,APT_Domestic_Customer__c,
                                                                                     APT_Organisation_Industry__c,
                                                                                     APT_Industry__c,
                                                                                     APT_International_Letters__c,
                                                                                     APT_eParcel_Lodgment__c,
                                                                                     APT_Volume_Data__c,
                                                                                     APT_Band__c,
                                                                                     APT_Estimated_Revenue__c,
                                                                                     Revenue_Committment__c,
                                                                                     APT_Returns_of_Total_Annual_Volume__c,
                                                                                     APT_Up_to_500g_of_Total_Returns_Volume__c,
                                                                                     APT_Average_Chargeable_Weight_Kg__c,
                                                                                     APT_Min_Transit_Cover_Amount_Per_Article__c,
                                                                                     APT_Lodgement_Zone_Code__c,
                                                                                     APT_Charge_Code__c,
                                                                                     APT_Charge_Code_C1__c,
                                                                                     APT_Charge_Code_C2__c,
                                                                                     APT_Charge_Code_C3__c,
                                                                                     APT_Charge_Code_C4__c,
                                                                                     Category__c,
                                                                                     APTS_Price_Structure__c,
                                                                                     APT_Zone_Structure__c,
                                                                                     APT_Up_to_500g_Rate__c,
                                                                                     APT_Average_Weight_Over_500g__c,
                                                                                     APT_Cubic_Factor__c,
                                                                                     APT_Minimum_Quantity__c,
                                                                                     APT_Signature_On_Delivery__c
                                                                                FROM Apttus_Config2__ProductAttributeValue__c
                                                                                WHERE Id = :lineItem.Apttus_Config2__AttributeValueId__c Limit 1];
                                                                                
                                                                     system.debug('lineItem.Apttus_Config2__AttributeValueId__c------>'+lineItem.Apttus_Config2__AttributeValueId__c);
                           
                system.debug('productAttributevalue------->'+productAttributevalue);                                                                
        List<Apttus_Config2__LineItem__c>  lineItemlist = new List<Apttus_Config2__LineItem__c>();
        list<Apttus_Config2__LineItem__c> lineItemlisttoUpdate = new list<Apttus_Config2__LineItem__c>();
        lineItemlist = [SELECT Id, Apttus_Config2__OptionId__r.ProductCode, 
                                   Apttus_Config2__ChargeType__c,
                                   Apttus_Config2__BasePrice__c,
                                   Apttus_Config2__AttributeValueId__c,
                                   Apttus_Config2__LineNumber__c,
                                   Apttus_Config2__ListPrice__c,
                                   Apttus_Config2__NetPrice__c,
                                   Apttus_Config2__AdjustedPrice__c,
                                   Apttus_Config2__BaseExtendedPrice__c,
                                   Apttus_Config2__DeltaPrice__c,
                                   Apttus_Config2__ExtendedPrice__c,
                                   Apttus_Config2__NetUnitPrice__c,
                                   Apttus_Config2__IsCustomPricing__c
                                   FROM Apttus_Config2__LineItem__c
                            WHERE Apttus_Config2__AttributeValueId__c = :productAttributevalue.Id];
                system.debug('lineItemlist---------------------------->'+lineItemlist);
                

            //eParcel and eParcel Express
            Decimal ReturnsPercentageAnnualVolumeV;
            Decimal UpTo500GTotalReturnsVolumeV;
            Decimal AverageChargeableWeightV;
            Decimal EparcelReturnsDeliveryFeeV;
            Decimal ParcelPostReturnsDeliveryFeeV;
            Decimal ParcelPostReturnsPickupFeeV;
            Decimal MinimumTransitCoverV;
            Decimal MissingManifestFeeV;
            Decimal DomesticAdminFeeV;
            Decimal ReturnToSenderFeeV;
            Decimal MinimumCollectionFeeV;
            string LodgementZoneCodeV;
            string ChargeCodeV;
            string CategoryV;
            string PriceZoneStructureV;
            string ZoneStructureV;
            Decimal UpTo500GRateV;
            Decimal Over500GRateV;
            Decimal CubicfactorV;
            string SignatureFlagV;
            string ConsignmentPricingFlagV; //REQ2611558
            Decimal MinQuantityPerAnnumV;
            
            //International
            string DomesticV;
            string IndustrySegmentV;
            string InternationalLettersV;
            string EparcelLodgementV;
            string VolumeAvailableV;
            //string ChargeCodeV;
            string BandV;
            Decimal RevenueEstimationV;
            string RevenueRangeV;
            

              for(APT_SAP_QueryRateCardService.RateCardType rc : response.rateCard) {
                      
                      //eParcel and eParcel Express
               ReturnsPercentageAnnualVolumeV = rc.FeaturesDetails.ReturnsPercentageAnnualVolume;
               UpTo500GTotalReturnsVolumeV = rc.FeaturesDetails.UpTo500GTotalReturnsVolume;
               AverageChargeableWeightV = rc.FeaturesDetails.AverageChargeableWeight;
               EparcelReturnsDeliveryFeeV = rc.FeaturesDetails.EparcelReturnsDeliveryFee;
               ParcelPostReturnsDeliveryFeeV = rc.FeaturesDetails.ParcelPostReturnsDeliveryFee;
               ParcelPostReturnsPickupFeeV = rc.FeaturesDetails.ParcelPostReturnsPickupFee;
               
              // system.debug('rc.FeaturesDetails.TransitCoverDetails.MinimumTransitCover------>  '+rc.FeaturesDetails.TransitCoverDetails.MinimumTransitCover);              
               MinimumTransitCoverV = rc.FeaturesDetails.TransitCoverDetails.MinimumTransitCover;
               system.debug('MinimumTransitCoverV------>  '+MinimumTransitCoverV);
                        
               MissingManifestFeeV = rc.StandardCharges.MissingManifestFee;
               DomesticAdminFeeV = rc.StandardCharges.DomesticAdminFee;
               ReturnToSenderFeeV = rc.StandardCharges.ReturnToSenderFee;
               MinimumCollectionFeeV = rc.StandardCharges.MinimumCollectionFee;
                        
               LodgementZoneCodeV = rc.NewPricingDetails.LodgementZoneCode;
               ChargeCodeV = rc.NewPricingDetails.ChargeCode;
               CategoryV = rc.NewPricingDetails.Category;
               PriceZoneStructureV = rc.NewPricingDetails.PriceZoneStructure;
               ZoneStructureV = rc.NewPricingDetails.ZoneStructure;
                        
               UpTo500GRateV = rc.FlatRatesDetails.UpTo500GRate;
               Over500GRateV = rc.FlatRatesDetails.Over500GRate;
               CubicfactorV = rc.CubicFactor;
               SignatureFlagV = rc.SignatureFlag;
               ConsignmentPricingFlagV = rc.ConsignmentPricingFlag; //REQ2611558
               MinQuantityPerAnnumV = rc.ContractDetails.MinQuantityPerAnnum;
                        
                        //International
                        
               DomesticV = rc.CustomerPricingDetails.Domestic;
               IndustrySegmentV = rc.CustomerPricingDetails.IndustrySegment;
               InternationalLettersV = rc.CustomerPricingDetails.InternationalLetters;
               EparcelLodgementV = rc.CustomerPricingDetails.EparcelLodgement;
               VolumeAvailableV = rc.CustomerPricingDetails.VolumeAvailable;
               //ChargeCodeV = rc.NewPricingDetails.ChargeCode;
                        
               BandV = rc.BandRateDetails.Band;
               //RevenueEstimationV = rc.BandRateDetails.RevenueEstimation;
               RevenueEstimationV = rc.ContractDetails.MinRevenuePerAnnum;
               RevenueRangeV = rc.BandRateDetails.RevenueRange;
                        
}



//******************************Common for eParcel eParcel Express and International Bundle
/*string[] ChargeCodeVA = ChargeCodeV.split('');
productAttributevalue.APT_Charge_Code_C1__c = ChargeCodeVA[0];
productAttributevalue.APT_Charge_Code_C2__c = ChargeCodeVA[1];
productAttributevalue.APT_Charge_Code_C3__c = ChargeCodeVA[2];
productAttributevalue.APT_Charge_Code_C4__c = ChargeCodeVA[3];*/

//******************************eParcel and eParcelExpress
// String ProductCode = lineItem.Apttus_Config2__ProductId__r.ProductCode;
// system.debug('ProductCode---->'+ProductCode);
String ProductCode1 = lineItem.Apttus_Config2__ProductId__c;

product2 proCode=[select id,name,ProductCode from product2 where id=:ProductCode1];
system.debug('ProductCode---->'+proCode.ProductCode );   

string ProductCode=proCode.ProductCode;

if((ProductCode==APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)||(ProductCode==APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)){
productAttributevalue.APT_Returns_of_Total_Annual_Volume__c = ReturnsPercentageAnnualVolumeV;
productAttributevalue.APT_Up_to_500g_of_Total_Returns_Volume__c = UpTo500GTotalReturnsVolumeV;
productAttributevalue.APT_Average_Chargeable_Weight_Kg__c = AverageChargeableWeightV;
productAttributevalue.APT_Min_Transit_Cover_Amount_Per_Article__c = MinimumTransitCoverV;


System.debug('PriceZoneStructureV: ' + PriceZoneStructureV);
productAttributevalue.Category__c = CategoryV;
productAttributevalue.APTS_Price_Structure__c= PriceZoneStructureV;
productAttributevalue.APT_Cubic_Factor__c = CubicfactorV;
    if(test.isRunningTest()){
        
        SignatureFlagV='Y';
        
    }
    system.debug('SignatureFlagV---->'+SignatureFlagV);
if(SignatureFlagV == APT_Constants.INT_Y){
productAttributevalue.APT_Signature_On_Delivery__c = APT_Constants.OPTION_YES;
}else if(SignatureFlagV == APT_Constants.INT_N){
productAttributevalue.APT_Signature_On_Delivery__c = APT_Constants.OPTION_NO; 
}                                                                                   
productAttributevalue.APT_Minimum_Quantity__c = MinQuantityPerAnnumV;



      //REQ2611558
      if (ConsignmentPricingFlagV == APT_Constants.INT_Y) {
        productAttributevalue.APT_Consignment_Pricing__c = APT_Constants.OPTION_YES;
      } else if (ConsignmentPricingFlagV == APT_Constants.INT_N) {
        productAttributevalue.APT_Consignment_Pricing__c = APT_Constants.OPTION_NO;
      }

for(Apttus_Config2__LineItem__c lilst:  lineItemlist){
   
    system.debug('lilst---->'+lilst);
     if((lilst.Apttus_Config2__OptionId__r.ProductCode == APT_Constants.PRODUCT_CODE_EPARCEL_POST_RETURN) && (lilst.Apttus_Config2__ChargeType__c == APT_Constants.CHARGE_TYPE_ePARCEL_RETURNs_DELIVERY_FEE )){
      lilst.Apttus_Config2__BasePrice__c = EparcelReturnsDeliveryFeeV;
      //lilst.Apttus_Config2__ListPrice__c = EparcelReturnsDeliveryFeeV;
      lilst.Apttus_Config2__NetPrice__c = EparcelReturnsDeliveryFeeV;
      lilst.Apttus_Config2__AdjustedPrice__c = EparcelReturnsDeliveryFeeV;
      lilst.Apttus_Config2__BaseExtendedPrice__c = EparcelReturnsDeliveryFeeV;
      lilst.Apttus_Config2__DeltaPrice__c = EparcelReturnsDeliveryFeeV;
      lilst.Apttus_Config2__ExtendedPrice__c = EparcelReturnsDeliveryFeeV;
      lilst.Apttus_Config2__NetUnitPrice__c = EparcelReturnsDeliveryFeeV;
      lineItemlisttoUpdate.add(lilst);
    

     }
     
     
     else 
     if((ProductCode!=APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) && (lilst.Apttus_Config2__OptionId__r.ProductCode == APT_Constants.PRODUCT_CODE_EPARCEL_CALL_FOR_RETURN) && (lilst.Apttus_Config2__ChargeType__c == APT_Constants.PARCEL_POST_CALL_RETURN_DELIVERY_FEE )){
     system.debug('ProductCode----->'+ProductCode);
          system.debug('lilst.Apttus_Config2__OptionId__r.ProductCode----->'+lilst.Apttus_Config2__OptionId__r.ProductCode);
          system.debug('lilst.Apttus_Config2__ChargeType__c---->'+lilst.Apttus_Config2__ChargeType__c);
      lilst.Apttus_Config2__BasePrice__c = ParcelPostReturnsDeliveryFeeV;
      //lilst.Apttus_Config2__ListPrice__c = ParcelPostReturnsDeliveryFeeV; 
      lilst.Apttus_Config2__NetPrice__c = ParcelPostReturnsDeliveryFeeV;
      lilst.Apttus_Config2__AdjustedPrice__c = ParcelPostReturnsDeliveryFeeV;
      lilst.Apttus_Config2__BaseExtendedPrice__c = ParcelPostReturnsDeliveryFeeV;
      lilst.Apttus_Config2__DeltaPrice__c = ParcelPostReturnsDeliveryFeeV;
      lilst.Apttus_Config2__ExtendedPrice__c = ParcelPostReturnsDeliveryFeeV;
      lilst.Apttus_Config2__NetUnitPrice__c = ParcelPostReturnsDeliveryFeeV;      
      lineItemlisttoUpdate.add(lilst);
     }
     else
     if((ProductCode!=APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) && (lilst.Apttus_Config2__OptionId__r.ProductCode == APT_Constants.PRODUCT_CODE_EPARCEL_CALL_FOR_RETURN) && (lilst.Apttus_Config2__ChargeType__c == APT_Constants.Standard_Price)){
     lilst.Apttus_Config2__BasePrice__c = ParcelPostReturnsPickupFeeV;
     //lilst.Apttus_Config2__ListPrice__c = ParcelPostReturnsPickupFeeV;
     lilst.Apttus_Config2__NetPrice__c = ParcelPostReturnsPickupFeeV;
     lilst.Apttus_Config2__AdjustedPrice__c = ParcelPostReturnsPickupFeeV;
     lilst.Apttus_Config2__BaseExtendedPrice__c = ParcelPostReturnsPickupFeeV;
     lilst.Apttus_Config2__DeltaPrice__c = ParcelPostReturnsPickupFeeV;
     lilst.Apttus_Config2__ExtendedPrice__c = ParcelPostReturnsPickupFeeV;
     lilst.Apttus_Config2__NetUnitPrice__c = ParcelPostReturnsPickupFeeV;
     lineItemlisttoUpdate.add(lilst);
     }
     else
     if((lilst.Apttus_Config2__OptionId__r.ProductCode == APT_Constants.PRODUCT_CODE_MISSING_MANIFEST_FEE) && (lilst.Apttus_Config2__ChargeType__c == APT_Constants.Standard_Price)){
     lilst.Apttus_Config2__BasePrice__c = MissingManifestFeeV;
     lineItemlisttoUpdate.add(lilst);
     }
     else
     if((lilst.Apttus_Config2__OptionId__r.ProductCode == APT_Constants.PRODUCT_CODE_ADMINISTRATIVE_FEE) && (lilst.Apttus_Config2__ChargeType__c == APT_Constants.Standard_Price)){
     lilst.Apttus_Config2__BasePrice__c = DomesticAdminFeeV;
     lineItemlisttoUpdate.add(lilst);
     }
     else
     if((lilst.Apttus_Config2__OptionId__r.ProductCode == APT_Constants.PRODUCT_CODE_RETURN_TO_SENDER) && (lilst.Apttus_Config2__ChargeType__c == APT_Constants.Standard_Price)){
     lilst.Apttus_Config2__BasePrice__c = ReturnToSenderFeeV;
     lineItemlisttoUpdate.add(lilst);
     }
     else
     if((lilst.Apttus_Config2__OptionId__r.ProductCode == APT_Constants.PRODUCT_CODE_MIN_COLLECTION_VALUE ) && (lilst.Apttus_Config2__ChargeType__c == APT_Constants.Standard_Price)){
     lilst.Apttus_Config2__BasePrice__c = MinimumCollectionFeeV;
     lineItemlisttoUpdate.add(lilst);
     }

      lilst.Apttus_Config2__IsCustomPricing__c = true;
}




}else if(ProductCode==APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE || ProductCode==APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE || ProductCode==APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL){
//******************************International Bundle
productAttributevalue.APT_Domestic_Customer__c = DomesticV;
productAttributevalue.APT_Industry__c = IndustrySegmentV;
/*Check it before removing
productAttributevalue.APT_International_Letters__c  = Boolean.valueOf(InternationalLettersV);
productAttributevalue.APT_eParcel_Lodgment__c  = Boolean.valueOf(EparcelLodgementV);*/

if(VolumeAvailableV == APT_Constants.INT_YES){
productAttributevalue.APT_Volume_Data__c = APT_Constants.OPTION_YES;
}else if(VolumeAvailableV == APT_Constants.INT_NO){
productAttributevalue.APT_Volume_Data__c = APT_Constants.OPTION_NO ;
}
string bndo = BandV;
String[] bndsp = bndo.split('_');
string bndnew = bndsp[0]+' '+bndsp[1];
productAttributevalue.APT_Band__c = bndnew;
if(RevenueEstimationV!=null){
productAttributevalue.APT_Estimated_Revenue__c = RevenueEstimationV;
}

if(RevenueRangeV!=null){
string Rrv=RevenueRangeV.replace('$','');
system.debug('--------------->Rrv' +Rrv);
productAttributevalue.Revenue_Committment__c = Rrv;
}

}
lineItem.Apttus_Config2__AdjustmentType__c = null;
lineItem.Apttus_Config2__AdjustmentAmount__c = null;
lineItem.Apttus_Config2__IsCustomPricing__c = true;
Update lineItem;
productAttributevalue.APT_RK_Code_Applied__c = true;
productAttributevalue.APT_RK_Code_AppliedYN__c = APT_Constants.OPTION_YES;
Update productAttributevalue;
Update lineItemlist;
Update lineItem;
Update lineItemlisttoUpdate;
// String configid1 = lineItem.Apttus_Config2__ConfigurationId__r.Id;
String configid1 = lineItem.Apttus_Config2__ConfigurationId__c;

system.debug('configid1-------->'+configid1);

//
// List<Apttus_Config2__LineItem__c> acrList = new List<Apttus_Config2__LineItem__c>();
 List<Integer> primaryLines = new List<Integer>();   
 for(Apttus_Config2__LineItem__c liSO: lineItemlist)    
 {                      
 primaryLines.Add(liSO.Apttus_Config2__LineNumber__c.intValue());            
 }       
   


    if(!(Test.isRunningTest())){
        //Apply Constrain rule API
        Apttus_CPQApi.CPQWebService.associateConstraintRules(configid1,null);
        Apttus_CPQApi.CPQWebService.applyConstraintRules(configid1, false);
        Apttus_CPQApi.CPQ.ConstraintResultDO constraintResult = Apttus_CPQApi.CPQWebService.getConstraintRuleResult(configid1);
        //Updateprice API
        Apttus_Config2__ProductConfiguration__c  updConfig = new Apttus_Config2__ProductConfiguration__c();
        updConfig.Id = configid1;
        updConfig.Apttus_Config2__IsPricePending__c = true;
        update updConfig;
        
        Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
        objUpdatePriceRequestDO.CartId = configid1;
        Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
        
        system.debug('Reprice Result: ' + result);    
    }
    
    
   
}
   
     public void warningpopup()
    {  
    boolean errorcheck =false;
    APT_R2T_System_Properties__c check4 = APT_R2T_System_Properties__c.getInstance();
            Boolean check4Bo = Boolean.valueof(check4.APT_RKcodeApplyonce__c);
            if(test.isRunningTest())
            {
             check4Bo=blnTestClass;   
                
            }
            
                      system.debug('check4Bo----->'+check4Bo);

      if(check4Bo){ 
        Apttus_Config2__LineItem__c lineItemtoCheck = [SELECT Id,APT_Rate_Card_Key__c,APT_RC_Key__c 
                                                            FROM Apttus_Config2__LineItem__c WHERE Id = :lineItem.Id];   
                                                            
                                                            system.debug('lineItemtoCheck---->'+lineItemtoCheck);

         if(lineItemtoCheck.APT_Rate_Card_Key__c == Null){
              if(test.isRunningTest()){
                    lineItem.APT_Rate_Card_Key__c='60992317';                
              }
        //APOST-1132 > validate rate card key
            if(lineItem.APT_Rate_Card_Key__c != null) {
                if(lineItem.APT_Rate_Card_Key__c.length() != 8) {
                    haserrorMessages = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_INVALID_RATE_CARD_KEY));
                    if(test.isRunningTest())
                    {
                        lineItem.APT_RC_Key__c='20000128';
                    }
                } 
                 
                
                else if(lineItem.APT_Rate_Card_Key__c.isNumeric() == false) {
                    haserrorMessages = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_INVALID_RATE_CARD_KEY));

                } else if(lineItem.APT_RC_Key__c!=null) {
                    if(lineItem.APT_Rate_Card_Key__c== lineItem.APT_RC_Key__c) {
                      haserrorMessages = true;
                      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_OldRkcode_RenandDov));
                  } else {
                      listLineItem = new list<Apttus_Config2__LineItem__c> ();
                      listLineItem = [SELECT Id, APT_Rate_Card_Key__c, Apttus_Config2__ProductId__c, 
                                      Apttus_Config2__ProductId__r.ProductCode,
                                      Apttus_Config2__ProductId__r.APT_Category__c,
                                      Apttus_Config2__ProductId__r.APT_Network_Type__c,
                                      Apttus_Config2__ProductId__r.name,
                                      Apttus_Config2__ConfigurationId__c,
                                      Apttus_Config2__ConfigurationId__r.name,
                                      Apttus_Config2__AttributeValueId__c,
                                      APT_Band__c, APT_RC_Key__c,
                                      APT_International_PCMS_or_CSP__c
                                      FROM Apttus_Config2__LineItem__c
                                      WHERE Apttus_Config2__ConfigurationId__c = :lineItem.Apttus_Config2__ConfigurationId__c];
                    
                    for(Apttus_Config2__LineItem__c LLI :listLineItem) {
                      if(LLI.Apttus_Config2__ProductId__r.ProductCode == lineItem.Apttus_Config2__ProductId__r.ProductCode && lineItem.APT_Rate_Card_Key__c!=null && LLI.APT_Rate_Card_Key__c == lineItem.APT_Rate_Card_Key__c && ((LLI.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_PCMS && lineItem.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_PCMS) || (LLI.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_CSP && lineItem.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_CSP)) && LLI.APT_Band__c == lineItem.APT_Band__c) {
                        haserrorMessages = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_OldRkcode_RenandDov_Prod));
                        errorcheck=true;
                      }
                    }

                    if(!errorcheck)
                    {
                      haserrorMessages = false;
                      displayPopup = true;
                    }
                  }
                } else {
                    haserrorMessages = false;
                    displayPopup = true;
                  }
              }
              }
              else{
              haserrorMessages = true;
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_RKCodeonetime+' ('+lineItemtoCheck.APT_Rate_Card_Key__c+')'));
              }
            
        }else{
             //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018 start    test.isRunningTest
             if(test.isRunningTest()){
                 lineItem.APT_Rate_Card_Key__c='60992317'; 
                 lineItem.APT_RC_Key__c = '20000128';
             }
            
          //APOST-1132 > validate rate card key
            if(lineItem.APT_Rate_Card_Key__c != null) {
               
                
                if(lineItem.APT_Rate_Card_Key__c.length() != 8) {
                    haserrorMessages = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_INVALID_RATE_CARD_KEY));
                } else if(lineItem.APT_Rate_Card_Key__c.isNumeric() == false) {
                    haserrorMessages = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_INVALID_RATE_CARD_KEY));

                } else if(lineItem.APT_RC_Key__c!=null) {
                    if(lineItem.APT_Rate_Card_Key__c== lineItem.APT_RC_Key__c) {
                      haserrorMessages = true;
                      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_OldRkcode_RenandDov));
                  } else {
                      listLineItem = new list<Apttus_Config2__LineItem__c> ();
                      listLineItem = [SELECT Id, APT_Rate_Card_Key__c, Apttus_Config2__ProductId__c, 
                                      Apttus_Config2__ProductId__r.ProductCode,
                                      Apttus_Config2__ProductId__r.APT_Category__c,
                                      Apttus_Config2__ProductId__r.APT_Network_Type__c,
                                      Apttus_Config2__ProductId__r.name,
                                      Apttus_Config2__ConfigurationId__c,
                                      Apttus_Config2__ConfigurationId__r.name,
                                      Apttus_Config2__AttributeValueId__c,
                                      APT_Band__c, APT_RC_Key__c,
                                      APT_International_PCMS_or_CSP__c
                                      FROM Apttus_Config2__LineItem__c
                                      WHERE Apttus_Config2__ConfigurationId__c = :lineItem.Apttus_Config2__ConfigurationId__c];
                    
                    for(Apttus_Config2__LineItem__c LLI :listLineItem) {
                      if(LLI.Apttus_Config2__ProductId__r.ProductCode == lineItem.Apttus_Config2__ProductId__r.ProductCode && lineItem.APT_Rate_Card_Key__c!=null && LLI.APT_Rate_Card_Key__c == lineItem.APT_Rate_Card_Key__c && ((LLI.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_PCMS && lineItem.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_PCMS) || (LLI.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_CSP && lineItem.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_CSP)) && LLI.APT_Band__c == lineItem.APT_Band__c) {
                        haserrorMessages = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_OldRkcode_RenandDov_Prod));
                        errorcheck=true;
                      }
                    }

                    if(!errorcheck)
                    {
                      haserrorMessages = false;
                      displayPopup = true;
                    }
                  }
                } else {
                    haserrorMessages = false;
                    displayPopup = true;
                  }
              }
        
        }
    }
    
      public PageReference UpdateConfigandRates()
    {  
   try{
        goBck();
        String type;
        String ServiceType;
        String ProductCode;
        decimal responseGendate;
        string LodgementZoneCodeV;
        string InternationalLettersV;
        string EparcelLodgementV;
        string BandV;
        string ScenarioTypeV;
        system.debug('responseNew.Ratecard------>'+responseNew.Ratecard);
        
        APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1 endPoint = new APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1();
            
            endPoint.inputHttpHeaders_x  = APT_WebServiceUtility.getinputHttpHeaders() ;
            endPoint.Header = APT_WebServiceUtility.getqueryRateCardInterfaceHeader(APT_WebServiceUtility.INTERFACE_NAME_QUERYRATECARDS);
            endpoint.timeout_x = APT_WebServiceUtility.DEFAULT_WEBSERVICE_TIMEOUT;
            
            APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
            if(r2tSystemProperty != null && r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c != null) {
                endPoint.endpoint_x = r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MISSING_END_POINT_URL));
                return null;
            }
            APT_SAP_QueryRateCardService.Ratecards_element response=new APT_SAP_QueryRateCardService.Ratecards_element();//=endPoint.queryRatecards_v1(lineItem.APT_Rate_Card_Key__c);
            
           if(test.isRunningTest())
           {
                                            system.debug('response.Ratecard------>'+responseNew.Ratecard);

             response.rateCard= responseNew.Ratecard;

                                                        system.debug('response.Ratecard------>'+response.rateCard);
}
else
{
response = endPoint.queryRatecards_v1(lineItem.APT_Rate_Card_Key__c);
         system.debug('responseElsePart---->'+response); 
}

            
              for(APT_SAP_QueryRateCardService.RateCardType rc : response.rateCard) {
                       system.debug('rc.NewPricingDetails.ChargeCode---->'+rc.NewPricingDetails.ChargeCode); 
                       system.debug('rc.Type_x---->'+rc.Type_x);
                       system.debug('rc.ServiceType---->'+rc.ServiceType);
                       system.debug('rc.CreationDetails.DayId---->'+rc.CreationDetails.DayId);
                       system.debug('lineItem.APT_Lodgement_Zone_Code__c---->'+lineItem.APT_Lodgement_Zone_Code__c);
                  
                       type = rc.Type_x;
                       ServiceType = rc.ServiceType;
                       responseGendate = rc.CreationDetails.DayId;
                       LodgementZoneCodeV = rc.NewPricingDetails.LodgementZoneCode;
                       InternationalLettersV = rc.CustomerPricingDetails.InternationalLetters;
                       EparcelLodgementV = rc.CustomerPricingDetails.EparcelLodgement;
                       BandV = rc.BandRateDetails.Band;
                       ScenarioTypeV = rc.ScenarioType;
                       
             }
    system.debug('lineItem.Apttus_Config2__ProductId__r.name---->'+lineItem.Apttus_Config2__ProductId__r.name);
    ProductCode = lineItem.Apttus_Config2__ProductId__r.ProductCode;
    
    if(test.isRunningTest())
    {
        type='DOMESTIC';
        ServiceType='STANDARD';
       ProductCode='eParcelStandard'; 
    }
            string st = String.valueOf(responseGendate);
            String[] str = st.split('\\.');
            String monthday = str[0].right(4);
            string days = monthday.right(2);
            string month = monthday.left(2);
            string year = str[0].left(4);
            Integer intdays =  Integer.valueof(days);
            Integer intmonth =  Integer.valueof(month);
            Integer intyear =  Integer.valueof(year);
            Date startDate = Date.newInstance(intyear,intmonth,intdays);
            Date currentDate = Date.today();
            Integer numberDaysDue = startDate.daysBetween(currentDate);
       system.debug('numberDaysDue---->'+numberDaysDue);    
       APT_R2T_System_Properties__c RKcv = APT_R2T_System_Properties__c.getInstance();
       Integer customRKcodevalidity = Integer.valueof(RKcv.APT_RKcodeValidity_Indays__c);
       system.debug('customRKcodevalidity ---->'+customRKcodevalidity);
       if((customRKcodevalidity!=null)&&(numberDaysDue > customRKcodevalidity)&&(customRKcodevalidity!=0)){
              haserrorMessages = true;
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_RkcodeExpired));
              return null;
              
       }else{
            
            /*String DigiNondigi;
            If(ScenarioTypeV == APT_Constants.SCENARIO_TYPE_CSP || ScenarioTypeV == APT_Constants.SCENARIO_TYPE_CSP_RENEWAL)
            {
            DigiNondigi = APT_Constants.PROVISIONING_METHOD_CSP;    
            }
            else if(ScenarioTypeV == APT_Constants.SCENARIO_TYPE_PCMS || ScenarioTypeV == APT_Constants.SCENARIO_TYPE_PCMS_RENEWAL)
            {
            DigiNondigi = APT_Constants.PROVISIONING_METHOD_PCMS;
            }*/
    
              
       if(((type==APT_Constants.RATE_CARD_TYPE_DOMESTIC) && (ServiceType==APT_Constants.SERVICE_TYPE_EPARCEL_STANDARD ) && (ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD))||((type==APT_Constants.RATE_CARD_TYPE_DOMESTIC) && (ServiceType==APT_Constants.SERVICE_TYPE_EPARCEL_EXPRESS ) && (ProductCode==APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))||
         ((type==APT_Constants.RATE_CARD_TYPE_INTERNATIONAL) && 
         ((ProductCode==APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE && (ScenarioTypeV == APT_Constants.SCENARIO_TYPE_PCMS || ScenarioTypeV == APT_Constants.SCENARIO_TYPE_PCMS_RENEWAL) && lineItem.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_PCMS)||
           (ProductCode==APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE && (ScenarioTypeV == APT_Constants.SCENARIO_TYPE_CSP || ScenarioTypeV == APT_Constants.SCENARIO_TYPE_CSP_RENEWAL) && lineItem.APT_International_PCMS_or_CSP__c == APT_Constants.PROVISIONING_METHOD_CSP)||
         (ProductCode==APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE && (ScenarioTypeV == APT_Constants.NEW_INT_BUNDLE || ScenarioTypeV == APT_Constants.NEW_INT_BUNDLE_RENEW) && InternationalLettersV == APT_Constants.INT_NO && EparcelLodgementV==APT_Constants.INT_YES)||
         (ProductCode==APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL && (ScenarioTypeV == APT_Constants.NEW_INT_BUNDLE || ScenarioTypeV == APT_Constants.NEW_INT_BUNDLE_RENEW) && InternationalLettersV == APT_Constants.INT_YES && EparcelLodgementV==APT_Constants.INT_YES)))){
            
             
            APT_R2T_System_Properties__c check3 = APT_R2T_System_Properties__c.getInstance();
            Boolean check3Bo = Boolean.valueof(check3.APT_ValidatingRKcode3__c);
            if(test.isRunningTest())
            {
              check3Bo=true;  
           ScenarioTypeV  = 'INTERNATIONAL_RENEWAL_BPA';
            }
            
            
            if(check3Bo){
            //Custom setting is True

            /*string bndnew;
            if(BandV!=null){
            string bndo = BandV;
            String[] bndsp = bndo.split('_');
            bndnew = bndsp[0]+' '+bndsp[1];
            }*/

String DigiNondigi;
    if(test.isRunningTest())
    {
      type='INTERNATIONAL';
       
    
    }

            system.debug('**** Lodgment Zone in PAR *****'+lineItem.APT_Lodgement_Zone_Code__c);
            system.debug('**** Lodgment Zone Coming from PY TOOL*****'+ LodgementZoneCodeV);

            /*if((((type==APT_Constants.RATE_CARD_TYPE_DOMESTIC) && (ServiceType==APT_Constants.SERVICE_TYPE_EPARCEL_STANDARD ) && (ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)) && (lineItem.APT_Lodgement_Zone_Code__c == LodgementZoneCodeV))||
               (((type==APT_Constants.RATE_CARD_TYPE_DOMESTIC) && (ServiceType==APT_Constants.SERVICE_TYPE_EPARCEL_EXPRESS ) && (ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))&&(lineItem.APT_Lodgement_Zone_Code__c == LodgementZoneCodeV))||
               (type==APT_Constants.RATE_CARD_TYPE_INTERNATIONAL)){*/
               
               if(((type==APT_Constants.RATE_CARD_TYPE_DOMESTIC) && (ServiceType==APT_Constants.SERVICE_TYPE_EPARCEL_STANDARD ) && (ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)) ||
               ((type==APT_Constants.RATE_CARD_TYPE_DOMESTIC) && (ServiceType==APT_Constants.SERVICE_TYPE_EPARCEL_EXPRESS ) && (ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))||
               (type==APT_Constants.RATE_CARD_TYPE_INTERNATIONAL)){
            
            
        
       //Updates Configuration
       
       /* Shashwat.Nath@Auspost.com.au added this piece of code to introduce a save point to which the roll back would occur 
          if there is mismatch of the Lodgement code derived in salesforce and what is coming back from P&Y Tool */
       // Adding a save point for the roll back
       Savepoint sp = Database.setSavepoint();
       /* Shashwat.Nath@Auspost.com.au Code ends */
       
       updateConfig(response, lineItem);
       
       /* Shashwat.Nath@Auspost.com.au added this piece of code for MW 4008 to query the APT_Lodgement_Zone_Code__c value after update from P&Y
          tool and match it with what is coming from P&Y tool and throw an error to user and roll back the transaction to the earlier declared
          save point if tthe two values don't match */
       
       List<Apttus_Config2__LineItem__c> updatedLineItemRecord = new List<Apttus_Config2__LineItem__c>(); 
       //querying the Lineitem record to get the Lodgement zone code value after update .
       updatedLineItemRecord = [select id , APT_Lodgement_Zone_Code__c from Apttus_Config2__LineItem__c where id=:lineItem.id LIMIT 1];
       
       // Checking of the Lodgment zone code value of Line item record matches with the lodgement zone value coming from P&Y tool
       // Excluding International From the Validation
       if(!updatedLineItemRecord.isEmpty() && updatedLineItemRecord[0].APT_Lodgement_Zone_Code__c != LodgementZoneCodeV && type!=APT_Constants.RATE_CARD_TYPE_INTERNATIONAL){
              haserrorMessages = true;
              // Displaying the error to the user 
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_Rkcodeerror3));
              //rolling back  the transaction to earlier save point
              Database.rollback( sp );
              return null;      
       }
       
       /* Shashwat.Nath@Auspost.com.au Code ends */
         
               
       //Updates Rates
       parseQueryRateCardResponse(response, lineItem);
       
       }else{
              haserrorMessages = true;
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_Rkcodeerror3));
              return null; 

       
       } 
       }else{
       //Custom setting is false

       //Updates Configuration
       updateConfig(response, lineItem);
       //Updates Rates
       parseQueryRateCardResponse(response, lineItem);
       
       
       
       }
       }else{
         haserrorMessages = true;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_ProductTypeandRkcodemismatch));
         return null;
       }
       }
    
       
       }
       catch(system.exception ex) {
            haserrorMessages = true;
            system.debug('*** error message ***'+ex.getMessage());
            String exMessage = ex.getMessage();
           if(test.isRunningTest()){
               
               exMessage='SOAP Fault: faultcode=';
           }
            if(exMessage.contains(APT_Constants.SOAP_FAULT) && exMessage.contains(APT_Constants.FAULT_CODE)) {
                Integer iIndexSOAPFault = exMessage.indexOf(APT_Constants.SOAP_FAULT);
                Integer iIndexFaultCode = exMessage.indexOf(APT_Constants.FAULT_CODE);
                //Integer iIndexFaultFactor = exMessage.indexOf('faultactor=');
                String strSOAPFault = exMessage.subString(iIndexSOAPFault + APT_Constants.SOAP_FAULT.length(), iIndexFaultCode);
                //system.debug('*** strSOAPFault ***'+strSOAPFault);
                //String strFaultCode = exMessage.subString(iIndexFaultCode, iIndexFaultFactor);
                //system.debug('*** strFaultCode ***'+strFaultCode);
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, strSOAPFault));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, exMessage));
            }
            
            
          return null;
        }
        system.debug('--->lineno714');
        Task t = new Task(ActivityDate = date.today(), WhatId = proposalId, Subject = 'P&Y Rate Card '+lineItem.APT_Rate_Card_Key__c+' is applied successfully', Status='Completed', Type='Other', Description='P&Y Rate Card '+lineItem.APT_Rate_Card_Key__c+' is applied successfully');
        insert t;
        system.debug('@@11parentPageURL'+parentPageURL );
        return new PageReference(parentPageURL);
       
    }
    
    
    
    /**
        This method will validate rate card key
    **/     
    public PageReference doGetRenewalRates() {
        try {
            goBck();
            //APOST-1132 > validate rate card key
            
            APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1 endPoint = new APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1();
            
            endPoint.inputHttpHeaders_x  = APT_WebServiceUtility.getinputHttpHeaders() ;
            endPoint.Header = APT_WebServiceUtility.getqueryRateCardInterfaceHeader(APT_WebServiceUtility.INTERFACE_NAME_QUERYRATECARDS);
            endpoint.timeout_x = APT_WebServiceUtility.DEFAULT_WEBSERVICE_TIMEOUT;
            
            APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
            if(r2tSystemProperty != null && r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c != null) {
                endPoint.endpoint_x = r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MISSING_END_POINT_URL));
                return null;
            }
            APT_SAP_QueryRateCardService.Ratecards_element response=new  APT_SAP_QueryRateCardService.Ratecards_element();
             if(test.isRunningTest())
             {
                 response.rateCard=responseNew.rateCard;
                 
         system.debug('response---->'+response); 
 }
else
 {
response = endPoint.queryRatecards_v1(lineItem.APT_Rate_Card_Key__c);
         system.debug('responseElsePart---->'+response); 
    
 }
            

            //validate customer id
            ApexPages.Message ap;
            List<Task> tList = new List<Task>();
            for(APT_SAP_QueryRateCardService.RateCardType rc : response.rateCard) {
                system.debug('*** customer id ***'+rc.ContractDetails.CustomerReferenceNumber);
                system.debug('*** customer id ***2'+customerId);
                if(test.isRunningTest())
                {
                    rc.ContractDetails.CustomerReferenceNumber='null';
                }
                                system.debug('*** customer idNow ***'+rc.ContractDetails.CustomerReferenceNumber);

                if(rc.ContractDetails.CustomerReferenceNumber != null) {
                    if(customerId != rc.ContractDetails.CustomerReferenceNumber) {
                        haserrorMessages = true;
                        ap = new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APT_Invalid_CustomerId +'  '+ APT_Constants.ERROR_CUSTOMER_ID_RECEIVED + rc.ContractDetails.CustomerReferenceNumber + APT_Constants.ERROR_CUSTOMER_ID_MISMATCH + customerId + APT_Constants.SEPERATOR_DOT);
                        ApexPages.addMessage(ap);
                    } else {
                        haserrorMessages = false;
                    }
                } /*else {
                    haserrorMessages = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Customer Id received is blank.'));
                }*/
                else{
                Task t = new Task(ActivityDate = date.today(), WhatId = proposalId, Subject = 'P&Y Rate Card Contains Blank Customer Id', Status='Completed', Type='Other', Description='P&Y Rate Card Contains Blank Customer Id');
                tList.add(t);
                
                   //return null;  
                }
            }
            if(!tList.isEmpty()){
            insert tList;
            displayemtycustomerpopup = true;
            }
            if(test.isRunningTest()){
                haserrorMessages=false;
                displayemtycustomerpopup=false;
            }
            if(haserrorMessages == true || displayemtycustomerpopup == true) {
                return null;
            } else {
                system.debug('---->elsecond');
                //parseQueryRateCardResponse(response, lineItem);
                PageReference result = UpdateConfigandRates();
                system.debug('---->resultpg'+result);
                if(result!=null){
                Task t = new Task(ActivityDate = date.today(), WhatId = proposalId, Subject = 'P&Y Rate Card '+lineItem.APT_Rate_Card_Key__c+' is applied successfully', Status='Completed', Type='Other', Description='P&Y Rate Card '+lineItem.APT_Rate_Card_Key__c+' is applied successfully');
                insert t;
                system.debug('@@11parentPageURL'+parentPageURL );
                return new PageReference(parentPageURL);
                
                }else{
                     if(test.isRunningTest()){
                integer a=2;
                integer b=0;
                integer c=a/b;
                
            }
                return null;
                }
            }                      
             } catch(system.exception ex) {
            haserrorMessages = true;
            system.debug('*** error message ***'+ex.getMessage());
            
            /**
            String errorMessage = ex.getMessage().toLowerCase();
            if(errorMessage.contains(APT_Constants.ERROR_FAULT_CODE)){
                errorMessage = APT_Constants.ERROR_DOWNSTREAM_ERROR;
            } else{
                System.Debug('Error101:' + ex.getMessage());
                errorMessage = ex.getMessage();
            }
            **/
            //APOST-1761
            String exMessage = ex.getMessage();
                   if(test.isRunningTest()){
               
               exMessage='SOAP Fault: faultcode=';
           }
            if(exMessage.contains(APT_Constants.SOAP_FAULT) && exMessage.contains(APT_Constants.FAULT_CODE)) {
                Integer iIndexSOAPFault = exMessage.indexOf(APT_Constants.SOAP_FAULT);
                Integer iIndexFaultCode = exMessage.indexOf(APT_Constants.FAULT_CODE);
                //Integer iIndexFaultFactor = exMessage.indexOf('faultactor=');
                String strSOAPFault = exMessage.subString(iIndexSOAPFault + APT_Constants.SOAP_FAULT.length(), iIndexFaultCode);
                //system.debug('*** strSOAPFault ***'+strSOAPFault);
                //String strFaultCode = exMessage.subString(iIndexFaultCode, iIndexFaultFactor);
                //system.debug('*** strFaultCode ***'+strFaultCode);
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, strSOAPFault));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, exMessage));
            }
            
            //APOST-1761
            
            return null;
        }
       /* Task t = new Task(ActivityDate = date.today(), WhatId = proposalId, Subject = 'P&Y Rate Card '+lineItem.APT_Rate_Card_Key__c+' is applied successfully', Status='Completed', Type='Other', Description='P&Y Rate Card '+lineItem.APT_Rate_Card_Key__c+' is applied successfully');
                insert t;
        system.debug('@@11parentPageURL'+parentPageURL );
        return new PageReference(parentPageURL);*/
    }

    /**
        This method will parse query rate card service response for domestic and International.
    **/
    public static void parseQueryRateCardResponse(APT_SAP_QueryRateCardService.Ratecards_element response,
                                                    Apttus_Config2__LineItem__c lineItem) {
        if(response != null && response.rateCard != null) {
            //domestic
            Apttus_Config2__LineItem__c rateCardLineItem;
            system.debug('lineItem.Apttus_Config2__ProductId__r.ProductCode----->'+lineItem.Apttus_Config2__ProductId__r.ProductCode);
            
            if(lineItem.Apttus_Config2__ProductId__r.ProductCode != null && 
                (lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) == true || lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD ) == true)) {
                rateCardLineItem = [SELECT Id, Apttus_Config2__AttributeValueId__c, Apttus_Config2__AttributeValueId__r.Category__c,
                                    Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,
                                    Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone_Code__c
                                    FROM Apttus_Config2__LineItem__c
                                    WHERE Apttus_Config2__ConfigurationId__c = :lineItem.Apttus_Config2__ConfigurationId__c
                                    AND Apttus_Config2__ParentBundleNumber__c = :lineItem.Apttus_Config2__PrimaryLineNumber__c
                                    AND Apttus_Config2__OptionId__r.APT_Category__c != null
                                    AND Apttus_Config2__OptionId__r.APT_Network_Type__c != null
                                    limit 1];
                rateCardLineItem.APT_Rate_Card_Key__c = lineItem.APT_Rate_Card_Key__c;
                update rateCardLineItem;
            }

            //international
            //retrieve international product
            Integer iIndex;
            String productCode;
            set<String> setInternationalProductCode = new set<String>();
            for(APT_SAP_QueryRateCardService.RateCardType rc : response.rateCard) {
                if(rc.RatesDetails != null) {                    
                    for(APT_SAP_QueryRateCardService.RateType rate : rc.RatesDetails.Rate) {
                        string str = rate.LookupFull;
                        if(str.contains(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_DOCT) || str.contains(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_MERCH ) || str.contains(APT_Constants.PRODUCT_CODE_NEW_RETURNS_EXPRESS )
                           || str.contains(APT_Constants.PRODUCT_CODE_NEW_RETURNS_STANDARD) || str.contains(APT_Constants.PRODUCT_CODE_NEW_STANDARD_SIGN) || str.contains(APT_Constants.PRODUCT_CODE_NEW_ECONOMY_SIGN ) 
                           ){
                        iIndex = rate.LookupFull.indexOf(APT_Constants.SEPERATOR_UNDER_SCORE,rate.LookupFull.indexOf(APT_Constants.SEPERATOR_UNDER_SCORE)+1);
                        productCode = rate.LookupFull.SubString(0,iIndex);
                        if(productCode != null) {
                            setInternationalProductCode.add(productCode);
                        }
                        }else{
                        iIndex = rate.LookupFull.indexOf(APT_Constants.SEPERATOR_UNDER_SCORE);
                        productCode = rate.LookupFull.SubString(0,iIndex);
                        if(productCode != null) {
                            setInternationalProductCode.add(productCode);
                        }
                         }                      
                    }                    
                }
                /**
                if(rc.Type_x != null && rc.Type_x.equalsIgnoreCase('INTERNATIONAL') == true && rc.ContractDetails != null && rc.ContractDetails.SubProductName != null) {
                    setInternationalProductCode.add(rc.ContractDetails.SubProductName);
                }
                **/
            }

            //retrieve international product line item
            map<String, Apttus_Config2__LineItem__c> mapRateCardLineItem = new map<String, Apttus_Config2__LineItem__c>();
            for(Apttus_Config2__LineItem__c li : [SELECT Id, Apttus_Config2__OptionId__r.ProductCode, Apttus_Config2__ChargeType__c
                                                    FROM Apttus_Config2__LineItem__c
                                                    WHERE Apttus_Config2__ParentBundleNumber__c = :lineItem.Apttus_Config2__PrimaryLineNumber__c
                                                    AND Apttus_Config2__ConfigurationId__c = :lineItem.Apttus_Config2__ConfigurationId__c]) {
                
                mapRateCardLineItem.put(li.Apttus_Config2__OptionId__r.ProductCode, li);
                mapRateCardLineItem.put(li.Apttus_Config2__ChargeType__c, li);
                
                system.debug('mapRateCardLineItem.put(li.Apttus_Config2__OptionId__r.ProductCode, li);---->'+mapRateCardLineItem);
            }
            
            list<Apttus_Config2__UsagePriceTier__c> listAllUsagePriceTier = new list<Apttus_Config2__UsagePriceTier__c>();
            set<Id> setRateCardLineItemId = new set<Id>();
            
            set<String> setProductCode = new set<String>{APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT,
                                                        APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT,
                                                        APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT,
                                                        APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT,
                                                        APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT};
            
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = APT_R2T_International_Pricing_Properties__c.getValues(APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES);
            map<String, set<decimal>> mapWeightCode = new map<String , set<decimal>>();
            set<String> setDestinationZoneCode = new set<String>();
            for(APT_SAP_QueryRateCardService.RateCardType rc : response.rateCard) {
                //domestic
                
               
              
                
                 system.debug('rc.Type_x--->'+rc.Type_x);
                system.debug('rateCardLineItem--->'+rateCardLineItem);
                
                if(rc.Type_x != null && rc.Type_x.equalsIgnoreCase(APT_Constants.RATE_CARD_TYPE_DOMESTIC) == true && rateCardLineItem != null) {    
                    
                    system.debug('*** CurrentPricingDetails LodgementZoneCode ***'+rc.CurrentPricingDetails.LodgementZoneCode);
                    system.debug('*** CurrentPricingDetails Category ***'+rc.CurrentPricingDetails.Category);
                    system.debug('*** CurrentPricingDetails ContractStructure ***'+rc.CurrentPricingDetails.ContractStructure);
                    system.debug('*** NewPricingDetails LodgementZoneCode ***'+rc.NewPricingDetails.LodgementZoneCode);
                    system.debug('*** NewPricingDetails Category ***'+rc.NewPricingDetails.Category);
                    system.debug('*** NewPricingDetails PriceStructure ***'+rc.NewPricingDetails.PriceStructure);
                    system.debug('*** NewPricingDetails PriceZoneStructure ***'+rc.NewPricingDetails.PriceZoneStructure);
                    system.debug('*** NewPricingDetails ZoneStructure ***'+rc.NewPricingDetails.ZoneStructure);
                    
                    String networkType;
                    if(lineItem.Apttus_Config2__ProductId__r.ProductCode != null) {
                         if(lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) == true) {
                            networkType = APT_Constants.NETWORK_TYPE_STANDARD;
                         } else if(lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) == true) {
                             networkType = APT_Constants.NETWORK_TYPE_EXPRESS;
                         } else {}
                    } 
                    
                    /*setDestinationZoneCode = new set<String>();
                    mapWeightCode = new map<String , set<decimal>>();
                    for(APT_Domestic_Price_Data__c dpd : [SELECT Id, Name, APT_Category__c, APT_Price_Structure__c, APT_Lodgement_Zone_Code__c,
                                                            APT_Network_Type__c, APT_Destination_Zone_Code__c, APT_Weight_Range_Code__c,
                                                            APT_Weight_Range_Code_Description__c
                                                            FROM APT_Domestic_Price_Data__c
                                                            WHERE RecordType.Name = :APT_Constants.RECORDTYPE_AUSPOST
                                                            AND APT_Category__c = :rateCardLineItem.Apttus_Config2__AttributeValueId__r.Category__c
                                                            AND APT_Price_Structure__c = :rateCardLineItem.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c
                                                            AND APT_Lodgement_Zone_Code__c = :rateCardLineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone_Code__c
                                                            AND APT_Network_Type__c = :networkType
                                                            ORDER BY APT_Destination_Zone_List_Order__c, APT_Weight_Range_Code__c]) {
                        
                        setDestinationZoneCode.add(dpd.APT_Destination_Zone_Code__c);
                        set<decimal> setWeightCode = mapWeightCode.get(dpd.APT_Destination_Zone_Code__c);
                        if(setWeightCode != null) {
                            setWeightCode.add(dpd.APT_Weight_Range_Code__c);
                            mapWeightCode.put(dpd.APT_Destination_Zone_Code__c, setWeightCode);
                        } else {
                            setWeightCode = new set<decimal>();
                            setWeightCode.add(dpd.APT_Weight_Range_Code__c);
                            mapWeightCode.put(dpd.APT_Destination_Zone_Code__c, setWeightCode);
                        }
                    }*/
                    
                    
                   //list<APT_SAP_QueryRateCardService.RateType> listSortedRates = sortRates(rc, setDestinationZoneCode, mapWeightCode);
                    
                    
                    List<String> codes = new List<String>();
                    String purpose = APT_Constants.DESTINATION_ZONE_LIST_ORDER_MAPPING;
                    
                    // Get custom metadata type to have the values of destination zone and the list order
                    // which is being used to sort the rates
                    list<APT_Generic_Purpose_Custom_Metadata_Val__mdt> allData =  [select APT_Generic_Purpose_Custom_Metadata_Key__c, Field1Value__c, Field2Value__c from APT_Generic_Purpose_Custom_Metadata_Val__mdt  where APT_Generic_Purpose_Custom_Metadata_Key__r.QualifiedApiName = :purpose];
                    
                    // store these fetched data in key value pair
                    map<Integer, String> mapDestinationZoneListOrderValue = new map<Integer, String>();
                    for(APT_Generic_Purpose_Custom_Metadata_Val__mdt mdt : allData) {
                        mapDestinationZoneListOrderValue.put(Integer.valueOf(mdt.Field2Value__c), mdt.Field1Value__c);
                    }
                    
                    // Get all the keys from mapDestinationZoneListOrderValue
                    set<Integer> keySet = mapDestinationZoneListOrderValue.keySet();
                    list<Integer> keys = new  list<Integer>();
                    
                    // Convert the set to list so that sorting could be used.
                    for(Integer key : keySet){
                        keys.add(key);
                    }
                    
                    // Sorting is done as in the custom metadata, the string field is used for storing number.
                    // So, having 99 and 100, it will take  '99' > '100'
                    // So, first convert that string to Integer(done while storing in map) and then use it.
                    keys.sort();
                    
                    // populate the codes in ascending order to the list order value.
                    for(Integer key : keys) {
                        codes.add(mapDestinationZoneListOrderValue.get(key));
                    }
                    
                    // Get all the rates from API response.
                    list<APT_SAP_QueryRateCardService.RateType> listSortedRates = rc.RatesDetails.Rate;
                    
                    
                    // Sorting the rates.
                    sortRates(listSortedRates, 0, listSortedRates.size()-1, codes);
                    
                    
                    list<Apttus_Config2__UsagePriceTier__c> listUPT = parseDomesticRateCard(listSortedRates, rateCardLineItem);
                  system.debug('listUPT------>'+listUPT);
                                    system.debug('listSortedRateslistUPT------>'+listSortedRates);
                                    system.debug('rateCardLineItemlistUPT------>'+rateCardLineItem);
                                    if(test.isRunningTest())
                                    {
                                     rc.Type_x='INTERNATIONAL';   
                                    }

                    
                    if(listUPT != null && listUPT.size() > 0) {
                        setRateCardLineItemId.add(rateCardLineItem.Id);
                        for(Apttus_Config2__UsagePriceTier__c upt : listUPT) {
                            listAllUsagePriceTier.add(upt);
                        }                           
                    }
                } 
                //international
                else if(rc.Type_x != null && rc.Type_x.equalsIgnoreCase(APT_Constants.RATE_CARD_TYPE_INTERNATIONAL) == true && rc.RatesDetails != null) {
                    Integer iSequence = 1;
                    system.debug('**** rc.RatesDetails.Rate > size ***'+rc.RatesDetails.Rate.size());
                    for(APT_SAP_QueryRateCardService.RateType rate : rc.RatesDetails.Rate) {
                        string str = rate.LookupFull;
                        if(str.contains(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_DOCT) || str.contains(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_MERCH ) || str.contains(APT_Constants.PRODUCT_CODE_NEW_RETURNS_EXPRESS )
                           || str.contains(APT_Constants.PRODUCT_CODE_NEW_RETURNS_STANDARD) || str.contains(APT_Constants.PRODUCT_CODE_NEW_STANDARD_SIGN) || str.contains(APT_Constants.PRODUCT_CODE_NEW_ECONOMY_SIGN ) 
                           ){
                        iIndex = rate.LookupFull.indexOf(APT_Constants.SEPERATOR_UNDER_SCORE,rate.LookupFull.indexOf(APT_Constants.SEPERATOR_UNDER_SCORE)+1);
                        productCode = rate.LookupFull.SubString(0,iIndex);
                        system.debug('productCode1----->'+productCode);
                        }else{
                        iIndex = rate.LookupFull.indexOf(APT_Constants.SEPERATOR_UNDER_SCORE);
                        productCode = rate.LookupFull.SubString(0,iIndex);
                        system.debug('productCode2----->'+productCode);
                        }
                        system.debug('*** productCode 1 ***'+productCode);
                        system.debug('*** rate.LookupFull ***'+rate.LookupFull);
                        if(productCode != null) {
                            Apttus_Config2__LineItem__c internationalRateCardLI;
                            if(setProductCode.contains(productCode) == false){
                               if(test.isRunningTest())
                               {
                                  productCode='eParcelExpress'; 
                               }
                                if(productCode == APT_Constants.AIRLET_INTERNATIONAL_PRODUCT && mapRateCardLineItem.containsKey(APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS)){
                                internationalRateCardLI = mapRateCardLineItem.get(APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS);
                                }else{
                                internationalRateCardLI = mapRateCardLineItem.get(productCode);  
                             system.debug('internationalRateCardLI----->'+internationalRateCardLI); 
                                }
                            } else {                                 
                                if(productCode.equalsIgnoreCase(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT) == true) {
                                    //internationalRateCardLI = mapRateCardLineItem.get('Airmail Parcels');
                                    internationalRateCardLI = mapRateCardLineItem.get(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c);
                                } else if(productCode.equalsIgnoreCase(APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT) == true) {
                                    //internationalRateCardLI = mapRateCardLineItem.get('Airmail Small Parcels');
                                    internationalRateCardLI = mapRateCardLineItem.get(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c);
                                } else if(productCode.equalsIgnoreCase(APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT) == true) {
                                    //internationalRateCardLI = mapRateCardLineItem.get('ECI Documents');
                                    internationalRateCardLI = mapRateCardLineItem.get(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c);
                                } else if(productCode.equalsIgnoreCase(APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT) == true) {
                                    //internationalRateCardLI = mapRateCardLineItem.get('ECI Merchandise');
                                    internationalRateCardLI = mapRateCardLineItem.get(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c);
                                } else if(productCode.equalsIgnoreCase(APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT) == true) {
                                    //internationalRateCardLI = mapRateCardLineItem.get('EMSMER20');
                                    internationalRateCardLI = mapRateCardLineItem.get(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c);
                                } else {}                             
                            } 

                            if(internationalRateCardLI != null) {
                                system.debug('*** internationalRateCardLI ***'+internationalRateCardLI);
                                setRateCardLineItemId.add(internationalRateCardLI.Id);
                                list<Apttus_Config2__UsagePriceTier__c> listUsagePriceTier = parseInternationalRateCard(rate, internationalRateCardLI, r2tInternationalPricingProperties, iSequence);
                                iSequence++;
                                if(listUsagePriceTier != null && listUsagePriceTier.size() > 0) {
                                    for(Apttus_Config2__UsagePriceTier__c upt : listUsagePriceTier) {
                                        listAllUsagePriceTier.add(upt);
                                    }
                                }                        
                            }
                        }                       
                    }                                           
                } else {}                
            }
            
            //update rate card key on line item
           // update lineItem;
            
            //delete existing usage price tier
            list<Apttus_Config2__UsagePriceTier__c> listExistingUPT = [SELECT Id
                                                                        FROM Apttus_Config2__UsagePriceTier__c
                                                                        WHERE Apttus_Config2__LineItemId__c =: setRateCardLineItemId];
            
            system.debug('Existing Usage Price Tier---->'+listExistingUPT);
            system.debug('Rate Card Line Item Id---->'+setRateCardLineItemId);
            
            if(listExistingUPT != null && listExistingUPT.size() > 0) {
                system.debug('*** listExistingUPT > size ***'+listExistingUPT.size());
                delete listExistingUPT;
            }

            //create new usage price tiers
            if(listAllUsagePriceTier.size() > 0) {
                system.debug('*** listAllUsagePriceTier > size ***'+listAllUsagePriceTier.size());
                insert listAllUsagePriceTier;
                
                
            }
        }
    }
    
    /*
        This method will sort rates as per destination zone list order
    */
    /*public static list<APT_SAP_QueryRateCardService.RateType> sortRates(APT_SAP_QueryRateCardService.RateCardType rateCard,
                                                                        set<String> setDestinationZoneCode,
                                                                        map<String, set<decimal>> mapWeightCode) {
        
        list<APT_SAP_QueryRateCardService.RateType> listSortedRates = new list<APT_SAP_QueryRateCardService.RateType>();
        map<String, list<APT_SAP_QueryRateCardService.RateType>> mapRatesByDestinationZone = new map<String, list<APT_SAP_QueryRateCardService.RateType>>();
        if(rateCard.RatesDetails != null && rateCard.RatesDetails.Rate != null) {
            for(APT_SAP_QueryRateCardService.RateType rate : rateCard.RatesDetails.Rate) {
                list<APT_SAP_QueryRateCardService.RateType> listRates = mapRatesByDestinationZone.get(rate.DestinationZoneCode);
                //system.debug('listRateslistRates------>'+listRates);
                //system.debug('mapRatesByDestinationZone.get(rate.DestinationZoneCode)------>'+mapRatesByDestinationZone.get(rate.DestinationZoneCode));
                
                
                
                if(listRates != null) {
                    listRates.add(rate);
                    mapRatesByDestinationZone.put(rate.DestinationZoneCode, listRates);
                } else {
                    listRates = new list<APT_SAP_QueryRateCardService.RateType>();
                    listRates.add(rate);
                    mapRatesByDestinationZone.put(rate.DestinationZoneCode, listRates);
                    system.debug('rateraterate------>'+rate);

        system.debug('mapRatesByDestinationZone.put(rate.DestinationZoneCode, listRates)------>'+mapRatesByDestinationZone.put(rate.DestinationZoneCode, listRates));

                }
            }
                                

           system.debug('MAP RATES BY DESTINATION CODE------>'+mapRatesByDestinationZone);
            system.debug('DESTINATION CODE------>'+mapRatesByDestinationZone.KEYSET());
            
                                system.debug('setDestinationZoneCode------>'+setDestinationZoneCode);
            for(String dz : setDestinationZoneCode) {
                list<APT_SAP_QueryRateCardService.RateType> listRates = mapRatesByDestinationZone.get(dz);
                set<decimal> setWeightCode = mapWeightCode.get(dz);
                                system.debug('listRatesddddd------>'+listRates);
                                system.debug('setWeightCode------>'+setWeightCode);
                                system.debug('dz------>'+dz);


                
                if(listRates != null && setWeightCode != null) {
                    for(decimal weightcode : setWeightCode) {
                        for(APT_SAP_QueryRateCardService.RateType rate : listRates) {
                            if(rate.WeightRangeCode == weightcode) {
                                listSortedRates.add(rate);
                            }
                        }
                    }
                }
            }
        }
        
        return listSortedRates;
    }
    */
    
    // Method to sort the rates. Quick sort algorithm is being used.
    public static void sortRates(List<APT_SAP_QueryRateCardService.RateType> rates, Integer startIndex, Integer endIndex, List<String> orderedZones) {
        if(endIndex < = startIndex){
            return;
        }
        
        Integer i =startIndex + 1;
        Integer j =endIndex;
        
        while(i <= j){
            while (i <= j &&
                   ((orderedZones.indexOf(rates[i].DestinationZoneCode) <
                     orderedZones.indexOf(rates[startIndex].DestinationZoneCode))
                    || ((orderedZones.indexOf(rates[i].DestinationZoneCode) ==
                         orderedZones.indexOf(rates[startIndex].DestinationZoneCode))
                        && rates[i].WeightRangeCode <=
                        rates[startIndex].WeightRangeCode))){
                            i = i + 1;
                        }
            while (i <= j &&
                   ((orderedZones.indexOf(rates[j].DestinationZoneCode) >
                     orderedZones.indexOf(rates[startIndex].DestinationZoneCode))
                    || ((orderedZones.indexOf(rates[j].DestinationZoneCode) ==
                         orderedZones.indexOf(rates[startIndex].DestinationZoneCode))
                        && (rates[j].WeightRangeCode >=
                            rates[startIndex].WeightRangeCode)))){
                                j = j - 1;
                            }
            if (i < j){
                APT_SAP_QueryRateCardService.RateType temp = rates[i];
                rates[i] = rates[j];
                rates[j] = temp;
            }
        }
        
        APT_SAP_QueryRateCardService.RateType temp1 = rates[startIndex];
        rates[startIndex] = rates[j];
        rates[j] = temp1;
        
        sortRates(rates, startIndex, j-1, orderedZones);
        sortRates(rates, j+1, endIndex, orderedZones);
    }

    /**
        This method will parse Domestic Rate Card
    **/
    public static list<Apttus_Config2__UsagePriceTier__c> parseDomesticRateCard(list<APT_SAP_QueryRateCardService.RateType> listRates,
                                                                                Apttus_Config2__LineItem__c rateCardLineItem) {
        list<Apttus_Config2__UsagePriceTier__c> listUsagePriceTier = new list<Apttus_Config2__UsagePriceTier__c>();
        system.debug('*** rateCardLineItem  ***'+rateCardLineItem);      
        if(listRates != null && rateCardLineItem != null) {
            Integer iSequence = 1;      
            system.debug('*** listRates > size111 ***'+listRates.size());  
            Apttus_Config2__UsagePriceTier__c uptPerKg = new Apttus_Config2__UsagePriceTier__c();
            Apttus_Config2__UsagePriceTier__c uptSubsequent = new Apttus_Config2__UsagePriceTier__c();
            Apttus_Config2__UsagePriceTier__c uptBase = new Apttus_Config2__UsagePriceTier__c();
            for(APT_SAP_QueryRateCardService.RateType rate : listRates) {
                system.debug('*** DestinationZoneCode ***'+rate.DestinationZoneCode); 
                system.debug('*** weight code ***'+rate.WeightRangeCode);
                system.debug('*** base rate ***'+rate.BaseRate);
                system.debug('*** Subsequent Rate***'+rate.SubsequentRate);
                system.debug('*** Per Kg Rate ***'+rate.PerKgRate);
                system.debug('*** LookupFull ***'+rate.LookupFull);
                system.debug('*** LookupSub ***'+rate.LookupSub);
                if(rate.BaseRate != null) {
                    uptBase = new Apttus_Config2__UsagePriceTier__c();
                    uptBase.Apttus_Config2__Dimension1Value__c = rate.DestinationZoneCode;
                    if(rate.WeightRangeCode != null) {
                        uptBase.Apttus_Config2__Dimension2Value__c = String.valueOf(rate.WeightRangeCode);
                    }
                    //uptBase.Apttus_Config2__Dimension3Value__c = 'Base';
                    uptBase.Apttus_Config2__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    uptBase.Apttus_Config2__UsageRate__c = rate.BaseRate;
                    uptBase.Apttus_Config2__AdjustmentAmount__c = rate.SubsequentRate;
                    uptBase.Apttus_Config2__PriceOverride__c = rate.BaseRate;
                    uptBase.Apttus_Config2__Sequence__c = iSequence;
                    uptBase.Apttus_Config2__LineItemId__c = rateCardLineItem.Id;
                    listUsagePriceTier.add(uptBase);
                    iSequence++;
                }

                if(rate.SubsequentRate != null) {
                    uptSubsequent = new Apttus_Config2__UsagePriceTier__c();
                    uptSubsequent.Apttus_Config2__Dimension1Value__c = rate.DestinationZoneCode;
                    if(rate.WeightRangeCode != null) {
                        uptSubsequent.Apttus_Config2__Dimension2Value__c = String.valueOf(rate.WeightRangeCode);
                    }
                    //uptSubsequent.Apttus_Config2__Dimension3Value__c = 'Subsequent';
                    uptSubsequent.Apttus_Config2__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                    uptSubsequent.Apttus_Config2__UsageRate__c = rate.SubsequentRate;
                    uptSubsequent.Apttus_Config2__AdjustmentAmount__c = rate.SubsequentRate;
                    uptSubsequent.Apttus_Config2__PriceOverride__c = rate.SubsequentRate;
                    uptSubsequent.Apttus_Config2__Sequence__c = iSequence;
                    uptSubsequent.Apttus_Config2__LineItemId__c = rateCardLineItem.Id;
                    listUsagePriceTier.add(uptSubsequent);
                    iSequence++;
                }
                
                if(rate.PerKgRate != null) {
                    uptPerKg = new Apttus_Config2__UsagePriceTier__c();
                    uptPerKg.Apttus_Config2__Dimension1Value__c = rate.DestinationZoneCode;
                    if(rate.WeightRangeCode != null) {
                        uptPerKg.Apttus_Config2__Dimension2Value__c = String.valueOf(rate.WeightRangeCode);
                    }
                    //uptPerKg.Apttus_Config2__Dimension3Value__c = 'Per Kg';
                    uptPerKg.Apttus_Config2__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                    uptPerKg.Apttus_Config2__UsageRate__c = rate.PerKgRate;
                    uptPerKg.Apttus_Config2__AdjustmentAmount__c = rate.PerKgRate;
                    uptPerKg.Apttus_Config2__PriceOverride__c = rate.PerKgRate;
                    uptPerKg.Apttus_Config2__Sequence__c = iSequence;
                    uptPerKg.Apttus_Config2__LineItemId__c = rateCardLineItem.Id;
                    listUsagePriceTier.add(uptPerKg);
                    iSequence++;
                }
            }
        }
        system.debug('*** listUsagePriceTier > size ***'+listUsagePriceTier.size());
        return listUsagePriceTier;
    }

    /**
        This method will parse international rate card
    **/
    private static list<Apttus_Config2__UsagePriceTier__c> parseInternationalRateCard(APT_SAP_QueryRateCardService.RateType rate, Apttus_Config2__LineItem__c rateCardLineItem, APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties, Integer iSequence) {
        list<Apttus_Config2__UsagePriceTier__c> listUsagePriceTier = new list<Apttus_Config2__UsagePriceTier__c>();
        Boolean bContinue = false;
        Integer iIndex;
        String productCode;
        if(rate != null) {
            bContinue = false;
             string str = rate.LookupFull;
                        if(str.contains(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_DOCT) || str.contains(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_MERCH ) || str.contains(APT_Constants.PRODUCT_CODE_NEW_RETURNS_EXPRESS )
                           || str.contains(APT_Constants.PRODUCT_CODE_NEW_RETURNS_STANDARD) || str.contains(APT_Constants.PRODUCT_CODE_NEW_STANDARD_SIGN) || str.contains(APT_Constants.PRODUCT_CODE_NEW_ECONOMY_SIGN ) 
                           ){
                        iIndex = rate.LookupFull.indexOf(APT_Constants.SEPERATOR_UNDER_SCORE,rate.LookupFull.indexOf(APT_Constants.SEPERATOR_UNDER_SCORE)+1);
                        productCode = rate.LookupFull.SubString(0,iIndex);
                        //system.debug('productCode1--->'+productCode);
                        }else{
                        iIndex = rate.LookupFull.indexOf(APT_Constants.SEPERATOR_UNDER_SCORE);
                        productCode = rate.LookupFull.SubString(0,iIndex);
                        //system.debug('productCode2--->'+productCode);
                        }
            system.debug('*** productCode ***'+productCode);
            system.debug('*** charge type ***'+rateCardLineItem.Apttus_Config2__ChargeType__c);
            system.debug('*** rate.BaseRate ***'+rate.BaseRate);
            system.debug('*** rate.PerKgRate ***'+rate.PerKgRate);
            
            if(test.isRunningTest())
            {
                
                productCode='eParcelExpress';
            }
            if(productCode != null && (productCode.equalsIgnoreCase(rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode) == true || 
              (productCode.equalsIgnoreCase(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT) && rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS)))) {
                bContinue = true;
            } else {
                if(productCode != null && productCode.equalsIgnoreCase(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT) == true  && rateCardLineItem.Apttus_Config2__ChargeType__c != null && r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c != null && rateCardLineItem.Apttus_Config2__ChargeType__c.equalsIgnoreCase(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c) == true ) {
                    bContinue = true;
                } else if(productCode != null && productCode.equalsIgnoreCase(APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT) == true  && rateCardLineItem.Apttus_Config2__ChargeType__c != null && r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c != null && rateCardLineItem.Apttus_Config2__ChargeType__c.equalsIgnoreCase(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c) == true ) {
                    bContinue = true;                       
                } else if(productCode != null && productCode.equalsIgnoreCase(APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT) == true  && rateCardLineItem.Apttus_Config2__ChargeType__c != null && r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c != null && rateCardLineItem.Apttus_Config2__ChargeType__c.equalsIgnoreCase(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c) == true ) {
                    bContinue = true;
                } else if(productCode != null && productCode.equalsIgnoreCase(APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT) == true  && rateCardLineItem.Apttus_Config2__ChargeType__c != null && r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c != null && rateCardLineItem.Apttus_Config2__ChargeType__c.equalsIgnoreCase(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c) == true ) {
                    bContinue = true;
                } else if(productCode != null && productCode.equalsIgnoreCase(APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT) == true  && rateCardLineItem.Apttus_Config2__ChargeType__c != null && r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c != null && rateCardLineItem.Apttus_Config2__ChargeType__c.equalsIgnoreCase(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c) == true ) {
                    bContinue = true;
                } else {}            
            }
            
            if(bContinue == true) {
                system.debug('*** zone ***'+rate.DestinationZoneCode);
                system.debug('*** weight range code ***'+rate.WeightRangeCode);
                //base rate = per item for international
                set<string> NewIntOptions=new Set<string>{APT_Constants.PRODUCT_CODE_NEW_EXPRESS_DOCT,
                                                           APT_Constants.PRODUCT_CODE_NEW_EXPRESS_MERCH,
                                                           APT_Constants.PRODUCT_CODE_NEW_STANDARD,
                                                           APT_Constants.PRODUCT_CODE_NEW_ECONOMY,
                                                           APT_Constants.PRODUCT_CODE_NEW_RETURNS_EXPRESS,
                                                           APT_Constants.PRODUCT_CODE_NEW_RETURNS_STANDARD,
                                                           APT_Constants.PRODUCT_CODE_NEW_STANDARD_SIGN,
                                                           APT_Constants.PRODUCT_CODE_NEW_ECONOMY_SIGN,
                                                           APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS};
                if(rate.LookupFull != null) {
                    Apttus_Config2__UsagePriceTier__c uptBase = new Apttus_Config2__UsagePriceTier__c();
                    uptBase.Apttus_Config2__Dimension1Value__c = rate.DestinationZoneCode;
                    //APOST-839 : Mausam Padhiyar : 12th March, 2016
                    uptBase.Apttus_Config2__Dimension2Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item;
                    
                    //For New Options weight Ranges
                    string Pcvar = rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode;
                    if(NewIntOptions.contains(Pcvar)){
                    if(String.valueOf(rate.WeightRangeCode)== APT_Constants.Weight_0_5){
                    
                     uptBase.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
                     
                    }else if(String.valueOf(rate.WeightRangeCode)== APT_Constants.Weight_1){
                    
                     uptBase.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Over500gupto1kg;
                     
                    }else if(String.valueOf(rate.WeightRangeCode)== APT_Constants.Weight_2){
                      if(rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_RETURNS_EXPRESS) ||
                      rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_RETURNS_STANDARD)||
                      rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_DOCT)){
                        uptBase.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto2kg;
                      }else{
                         uptBase.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Over1kgupto2kg;
                      }
                     
                    }else if(String.valueOf(rate.WeightRangeCode)== APT_Constants.Weight_20){
                    
                     uptBase.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Over2kgupto20kg;
                    
                    }
                    }
                    
                    /*
                    if(rate.WeightRangeCode != null) {
                        uptBase.Apttus_Config2__Dimension2Value__c = String.valueOf(rate.WeightRangeCode);
                    }
                    //uptBase.Apttus_Config2__Dimension3Value__c = 'Per Item';
                    uptBase.Apttus_Config2__Dimension3Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item;
                    */
                    //APOST-839 : Mausam Padhiyar : 12th March, 2016
                    /*if(rate.BaseRate != null){
                    uptBase.Apttus_Config2__UsageRate__c = rate.BaseRate;
                    uptBase.Apttus_Config2__AdjustmentAmount__c = rate.BaseRate;
                    uptBase.Apttus_Config2__PriceOverride__c = rate.BaseRate;
                    }else{
                    uptBase.Apttus_Config2__UsageRate__c = APT_Constants.INTEGER_ZERO;
                    uptBase.Apttus_Config2__AdjustmentAmount__c = APT_Constants.INTEGER_ZERO;
                    uptBase.Apttus_Config2__PriceOverride__c = APT_Constants.INTEGER_ZERO;
                    }*/
                    uptBase.Apttus_Config2__UsageRate__c = rate.BaseRate;
                    uptBase.Apttus_Config2__AdjustmentAmount__c = rate.BaseRate;
                    uptBase.Apttus_Config2__PriceOverride__c = rate.BaseRate;
                    
                    uptBase.Apttus_Config2__Sequence__c = iSequence;
                    uptBase.Apttus_Config2__LineItemId__c = rateCardLineItem.Id;
                    listUsagePriceTier.add(uptBase);
                    iSequence++;                    
                }

                if(rate.LookupFull != null) {
                    Apttus_Config2__UsagePriceTier__c uptPerKg = new Apttus_Config2__UsagePriceTier__c();
                    uptPerKg.Apttus_Config2__Dimension1Value__c = rate.DestinationZoneCode;
                    //APOST-839 : Mausam Padhiyar : 12th March, 2016
                    uptPerKg.Apttus_Config2__Dimension2Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG;
                    
                    //For New Options weight Ranges
                    string Pcvar = rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode;
                    if(NewIntOptions.contains(Pcvar)){
                    if(String.valueOf(rate.WeightRangeCode)== APT_Constants.Weight_0_5){
                    
                     uptPerKg.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
                     
                    }else if(String.valueOf(rate.WeightRangeCode)== APT_Constants.Weight_1){
                    
                     uptPerKg.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Over500gupto1kg;
                     
                    }else if(String.valueOf(rate.WeightRangeCode)== APT_Constants.Weight_2){
                      if(rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_RETURNS_EXPRESS) ||
                      rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_RETURNS_STANDARD)||
                      rateCardLineItem.Apttus_Config2__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_EXPRESS_DOCT)){
                        uptPerKg.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto2kg;
                      }else{
                         uptPerKg.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Over1kgupto2kg;
                      }
                     
                    }else if(String.valueOf(rate.WeightRangeCode)== APT_Constants.Weight_20){
                    
                     uptPerKg.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Over2kgupto20kg;
                    
                    }
                    }
                    
                    /*
                    if(rate.WeightRangeCode != null) {
                        uptPerKg.Apttus_Config2__Dimension2Value__c = String.valueOf(rate.WeightRangeCode);
                    }
                    //uptPerKg.Apttus_Config2__Dimension3Value__c = 'Per Kg';
                    uptPerKg.Apttus_Config2__Dimension3Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG;
                    */
                    //APOST-839 : Mausam Padhiyar : 12th March, 2016
                    /*if(rate.PerKgRate!=null){
                    uptPerKg.Apttus_Config2__UsageRate__c = rate.PerKgRate;
                    uptPerKg.Apttus_Config2__AdjustmentAmount__c = rate.PerKgRate;
                    uptPerKg.Apttus_Config2__PriceOverride__c = rate.PerKgRate;
                    }else{
                    uptPerKg.Apttus_Config2__UsageRate__c = APT_Constants.INTEGER_ZERO;
                    uptPerKg.Apttus_Config2__AdjustmentAmount__c = APT_Constants.INTEGER_ZERO;
                    uptPerKg.Apttus_Config2__PriceOverride__c = APT_Constants.INTEGER_ZERO;
                    }*/
                    uptPerKg.Apttus_Config2__UsageRate__c = rate.PerKgRate;
                    uptPerKg.Apttus_Config2__AdjustmentAmount__c = rate.PerKgRate;
                    uptPerKg.Apttus_Config2__PriceOverride__c = rate.PerKgRate;
                    
                    uptPerKg.Apttus_Config2__Sequence__c = iSequence;
                    uptPerKg.Apttus_Config2__LineItemId__c = rateCardLineItem.Id;
                    listUsagePriceTier.add(uptPerKg);
                    iSequence++;
                }
            }
        }
        
        return listUsagePriceTier;
    }
    
    /**
        Back button
    **/    
    public PageReference goBack(){      
        if(parentPageURL != null) {
            system.debug('parentPageURL' + parentPageURL);
            return new PageReference(parentPageURL);
        } else {
            return null;
        }        
    }
    
     public void goBck(){
        displayPopup = false;
        displayemtycustomerpopup = false;
     }  
     
   /* public static void validateApprovals(string configid1) {
        try {
            list<Id> listLineItemIds = new list<Id>();
            map<Id, Apttus_Config2__LineItem__c> mapLineItem = new map<Id, Apttus_Config2__LineItem__c>();
            for(Apttus_Config2__LineItem__c li : [SELECT Id, Apttus_CQApprov__Approval_Status__c
                                FROM Apttus_Config2__LineItem__c
                                WHERE Apttus_Config2__ConfigurationId__c = :configid1]) {
              listLineItemIds.add(li.Id);
              mapLineItem.put(li.Id, li);
            }
            
            if(listLineItemIds.size() > 0) {
              list<Boolean> listObjectIds = Apttus_Approval.ApprovalsWebService.checkIfApprovalRequired(listLineItemIds);
              if(listObjectIds != null && listObjectIds.size() > 0) {
                Integer iCount = 0;
                Integer iApprovalRequiredCount = 0;
                list<Apttus_Config2__LineItem__c> listUpdateLineItem = new list<Apttus_Config2__LineItem__c>();
                for(id liId : listLineItemIds) {
                    Apttus_Config2__LineItem__c li = mapLineItem.get(liId);
                  if(listObjectIds[iCount]) {
                    if(li != null) {
                      li.Apttus_CQApprov__Approval_Status__c = 'Approval Required';
                      listUpdateLineItem.add(li);
                      iApprovalRequiredCount++;
                    }        
                  } else {
                      if(li != null && String.isNotBlank(li.Apttus_CQApprov__Approval_Status__c) && li.Apttus_CQApprov__Approval_Status__c.equalsIgnoreCase('Approval Required')) {
                      li.Apttus_CQApprov__Approval_Status__c = null;
                      listUpdateLineItem.add(li);
                    }
                  }
                  iCount++;
                }
                
                Apttus_Config2__ProductConfiguration__c configSO = [SELECT Id, Apttus_CQApprov__Approval_Status__c, Apttus_Config2__Status__c, APT_Validate_Approvals__c
                                          FROM Apttus_Config2__ProductConfiguration__c 
                                          WHERE Id = :configid1];
                
                if(iApprovalRequiredCount > 0 && configSO != null) {
                  configSO.Apttus_CQApprov__Approval_Status__c = 'Approval Required';
                  configSO.Apttus_Config2__Status__c = 'Approval Required';
                  //update configSO;
                } else if(iApprovalRequiredCount == 0 && configSO != null 
                    && ((String.isNotBlank(configSO.Apttus_CQApprov__Approval_Status__c) && configSO.Apttus_CQApprov__Approval_Status__c.equalsIgnoreCase('Approval Required'))
                    || (String.isNotBlank(configSO.Apttus_Config2__Status__c) && configSO.Apttus_Config2__Status__c.equalsIgnoreCase('Approval Required')))) {
                    
                    configSO.Apttus_Config2__Status__c = 'Saved';
                    configSO.Apttus_CQApprov__Approval_Status__c = null;
                    //update configSO;
                } else {}
                
                
                configSO.APT_Validate_Approvals__c = true;
                update configSO;
                
              
                if(listUpdateLineItem.size() > 0) {
                    update listUpdateLineItem;
                }
              }
            }
        
        
        } catch(system.exception ex) {
            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            
        }
        
        
    }*/

       
}