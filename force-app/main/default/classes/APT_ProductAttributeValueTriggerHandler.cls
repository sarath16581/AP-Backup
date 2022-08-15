/**
Description - This apex class is handler class for apex trigger - APT_ProductAttributeValueTrigger.
Created By - Mausam Padhiyar
Created Date - 16th Oct, 2015

Last Modified By - Muasam Padhiyar
Last Modified Date - 11th Aug,2016 | Defect 1332 | BAND5 Approvals. set revenue committment

Last Modified By - Muasam Padhiyar
Last Modified Date - 26th Sept,2016 | Defect 1560 | post billpay validation

Last Modified By - Muasam Padhiyar
Last Modified Date - 21st Oct,2016 | Defect 1588 | revenue commitment and offer higherband

Last Modified By - Muasam Padhiyar
Last Modified Date - 7th Nov,2016 | Defect 1493 | 

Last Modified By - SaiSwetha Pingali
Last Modified Date - 10th May 2021 
Changes Made - Fix to set industry attribute only if the value is not blank at organisation.

Mathew Jose - 29/05/2021 - Added to beforeInsertEvent method to set the zone dispersions (STP-5812)
Mathew Jose - 29/05/2021 - Added afterUpdateEvent method to set the Is Band Changed flag on lineItem (STP-5812)
Pradeep Jaiswal - 26/4/2022 - CI-224 - Removed Existing Customer field from layout and checked Exisiting Customer from opportunity
Bharat Patel 15-05-2022 Added condition for option NO

Naveen Rajanna - 11/02/2022 - REQ2649482 - Modified API Version and Minimum Quantity to be set to Category low and high if entered quantity exceeds category range

Pradeep Jaiswal - 26/4/2022 - CI-224 - Removed Existing Customer field from layout and checked Exisiting Customer from opportunity
Naveen Rajanna - 20/05/2022 - INC1976447 - Fix Null pointer exception preventing Add Product (StarTrack product – Premium – STE) in shopping cart
Naveen Rajanna - 24/05/2022 - INC1977875 - To fix query not being selective error and missing code changes for REQ2649482
**/
public with sharing class APT_ProductAttributeValueTriggerHandler {
    
    /**
        This method will insert product atribute.
        @params
        listProductAttributeValue - list of product attribute value
    **/
    public static Void beforeInsertEvent(list<Apttus_Config2__ProductAttributeValue__c> listProductAttributeValue) {
        try {
            //Defect 1809
            Set<ID> lineItemIDSet = new Set<ID>();
            for(Apttus_Config2__ProductAttributeValue__c pav : listProductAttributeValue) {
                System.Debug('Line item ID kushal '+pav.Apttus_Config2__LineItemId__c);
                lineItemIDSet.add(pav.Apttus_Config2__LineItemId__c);
            }
            //CI-224 Removed APT_Existing_APPC_Customer__c 
            Map<ID,Apttus_Config2__LineItem__c> lineItemMap = new Map<ID,Apttus_Config2__LineItem__c>([select ID,Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__r.Industry, 
                                                                                                       Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__r.Role_Type_Roll_Up__c,
                                                                                                       Apttus_Config2__ProductId__r.ProductCode,Apttus_Config2__ProductId__r.APT_Apttus_Product_Classification__c,
                                                                                                       Apttus_Config2__OptionId__r.APT_Apttus_Product_Classification__c,
                                                                                                         Apttus_Config2__ConfigurationId__c, 
                                                                                                       Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__r.APT_Eligible_APPC_Tier__c,
                                                                                                       Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Cubic_Factor__c,
                                                                                                       Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Cubic_Factor_Type__c,
                                                                                                       Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Cubic_Calculation1__c,
                                                                                                       Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Cubic_Calculation2__c,
                                                                                                       Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Total_Physical_Weight_Kg1__c,
                                                                                                       Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Type                                                                                                                                                                                     
                                                                                                       from Apttus_Config2__LineItem__c where ID in : lineItemIDSet]);
            //STP-5812 - Converting workflow to trigger for improved shopping cart performance.  
            Map<String,Map<String, Decimal>> productCodeToZoneDispersionMap = new Map<String,Map<String, Decimal>>();
            productCodeToZoneDispersionMap = getInternationalZoneDispersion(lineItemMap);          
            //list<Apttus_Config2__ProductAttributeValue__c> listPAV = new list<Apttus_Config2__ProductAttributeValue__c>();
            for(Apttus_Config2__ProductAttributeValue__c pav : listProductAttributeValue) {
                Apttus_Config2__LineItem__c configLineItem = lineItemMap.get(pav.Apttus_Config2__LineItemId__c);
                if(configLineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_APPC){
                    
                    // CI-69 ------- Existing Customer Use Case ----------
                    // For Existing APPC Customer case, Tier will only get defaulted to Eligible APPC Tier when Tier is blank 
                    // (as there could be scenario where Tier value is defaulted but when Compass send custom Tier in that case it should take that value rather then defaulting from Eligible APPC Tier)
                    //CI-224 Existing APPC Customer flag from Proposal rather than from Account Object 
                    String strExistingAPPCCustomer = lineItemMap.get(pav.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Type;
                    
                    if(strExistingAPPCCustomer == APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER) { 
                       
                        if(String.isBlank(pav.APT_Customer_Tier__c)){
                            pav.APT_Customer_Tier__c = configLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__r.APT_Eligible_APPC_Tier__c;
                        }
                    }
                  

                } else{
                    
                    //listPAV.add(pav);
                    //workflow rule to trigger
                    //default cubic factor from proposal
                    if(/*pav.APT_Cubic_Factor__c == 1 &&*/ pav.APT_Proposal_Cubic_Factor__c != null && pav.APT_Proposal_Cubic_Factor__c != 0) {
                        pav.APT_Cubic_Factor__c = pav.APT_Proposal_Cubic_Factor__c;
                    }
                    if(lineItemMap.containsKey(pav.Apttus_Config2__LineItemId__c) && lineItemMap.get(pav.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__r.Role_Type_Roll_Up__c == 'Customer')
                    {
                        //spingali - Commented and added below code to set industry attribute only if the value is not blank at organisation. 
                        
                        if (!(string.ISBLANK(lineItemMap.get(pav.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__r.Industry)))
                            pav.APT_Industry__c = lineItemMap.get(pav.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__r.Industry;
                    }
                    //workflow rule to trigger
                    //STP-5812 - Updates Mathew Jose (Shopping Cart performance)
                    String productCode = lineItemMap.get(pav.Apttus_Config2__LineItemId__c)?.Apttus_Config2__ProductId__r.ProductCode;
                    if(productCodeToZoneDispersionMap.containsKey(productCode)){
                        //Set zone dispersion values
                        Map<String, Decimal> zoneDispersions = new Map<String,Decimal>();
                        zoneDispersions = productCodeToZoneDispersionMap.get(productCode);
                        if(zoneDispersions.containsKey('Zone 1')){
                            pav.APT_Zone_1_Dispersion__c = zoneDispersions.get('Zone 1');
                        }
                        if(zoneDispersions.containsKey('Zone 2')){
                            pav.APT_Zone_2_Dispersion__c = zoneDispersions.get('Zone 2');
                        }
                        if(zoneDispersions.containsKey('Zone 3')){
                            pav.APT_Zone_3_Dispersion__c = zoneDispersions.get('Zone 3');
                        }
                        if(zoneDispersions.containsKey('Zone 4')){
                            pav.APT_Zone_4_Dispersion__c = zoneDispersions.get('Zone 4');
                        }
                        if(zoneDispersions.containsKey('Zone 5')){
                            pav.APT_Zone_5_Dispersion__c = zoneDispersions.get('Zone 5');
                        }
                        if(zoneDispersions.containsKey('Zone 6')){
                            pav.APT_Zone_6_Dispersion__c = zoneDispersions.get('Zone 6');
                        }
                        if(zoneDispersions.containsKey('Zone 7')){
                            pav.APT_Zone_7_Dispersion__c = zoneDispersions.get('Zone 7');
                        }
                        if(zoneDispersions.containsKey('Zone 8')){
                            pav.APT_Zone_8_Dispersion__c = zoneDispersions.get('Zone 8');
                        }                                                                                                                                                
                        
                    }
                    
                }
                //APOST-924
                //populateFieldValues(listPAV,null);
                //return APT_Constants.SUCCESS_LABEL;
            } 
        }catch(Exception ex) {
            //return ex.getMessage();
            for(Apttus_Config2__ProductAttributeValue__c pav : listProductAttributeValue){
                pav.addError(ex.getMessage());    
             }
        }
    }
    /* 
    * This method will be executed on the after update trigger context
    * Added the logic to set the Is Band Changed flag on line items as part STP-5812 which is moving the workflow to before triggers(Shopping cart performance improvement)
    * @param - Trigger.newMap, Trigger.oldMap
    */
    public static void afterUpdateEvent(Map<Id,Apttus_Config2__ProductAttributeValue__c> pavNewMap, Map<Id,Apttus_Config2__ProductAttributeValue__c> pavOldMap) {
        //get the associated line item records associated with the
        try{ 
            Map<Id, Apttus_Config2__LineItem__c> mapLineItem = new Map <Id, Apttus_Config2__LineItem__c>();
            List<Apttus_Config2__LineItem__c> lineItemsToUpdate =  new List<Apttus_Config2__LineItem__c>();
            for(Apttus_Config2__ProductAttributeValue__c pav: [SELECT Id, Name,
                                                                Apttus_Config2__LineItemId__c, 
                                                                Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.APT_Created_On__c,
                                                                Apttus_Config2__LineItemId__r.APT_New_Amend__c
                                                                FROM Apttus_Config2__ProductAttributeValue__c 
                                                                WHERE Id IN :pavNewMap.keySet()]){
                mapLineItem.put(pav.Apttus_Config2__LineItemId__c,pav.Apttus_Config2__LineItemId__r);               
            }
            for(Apttus_Config2__ProductAttributeValue__c paVal : pavNewMap.Values()){
                String newBandValue = paVal.APT_Band__c;
                String oldBandValue = pavOldMap.get(paVal.Id)?.APT_Band__c;
                //get the created On and New Amend fields from the associated line Item record (STP-5812)
                Apttus_Config2__LineItem__c lineItem = mapLineItem.get(paVal.Apttus_Config2__LineItemId__c);
                String createdOn = lineItem?.Apttus_Config2__ConfigurationId__r?.APT_Created_On__c;
                Boolean newAmend = lineItem?.APT_New_Amend__c;            
                if(String.isNotBlank(oldBandValue) && !oldBandValue.equalsIgnoreCase(newbandValue)){
                    if(createdOn == 'Amendment Quote' && !newAmend){
                        lineItem.APT_Is_Band_Changed__c = true;
                        lineItemsToUpdate.add(lineItem);                    
                    }              
                }
            }
            if(!lineItemsToUpdate.isEmpty()){
                update lineItemsToUpdate;
            }
            //return APT_Constants.SUCCESS_LABEL;
        } catch(Exception ex) {
            //return ex.getMessage();
            for(Apttus_Config2__ProductAttributeValue__c pav : pavNewMap.Values()){
                pav.addError(ex.getMessage());    
             }
        }
                                                                                                
    }
    
    /*
    //APOST-924 : not required
    static set<string> setSizeVals = new set<string>();
    static set<string> setDistributionVals = new set<string>();
    public static string populateFieldValues(list<Apttus_Config2__ProductAttributeValue__c> listProductAttributeValue,Map<Id,Apttus_Config2__ProductAttributeValue__c> mapOldPav) { 
        try{   
          for(Schema.PicklistEntry pickVal:Apttus_Config2__ProductAttributeValue__c.APT_Distribution_type__c.getDescribe().getPicklistValues()){
               setDistributionVals.add(pickVal.getValue()); 
           }
          for(Schema.PicklistEntry pickVal:Apttus_Config2__ProductAttributeValue__c.APT_Size__c.getDescribe().getPicklistValues()){
               setSizeVals.add(pickVal.getValue()); 
           }
           
          for(Apttus_Config2__ProductAttributeValue__c pav : listProductAttributeValue){
           if(mapOldPav==null && pav.APT_Distribution_Type_Printpost__c!=null){
                parseFieldValue(pav,pav.APT_Distribution_Type_Printpost__c);
               
          }else if(mapOldPav!=null && pav.APT_Distribution_Type_Printpost__c!=null){
              if(pav.APT_Distribution_Type_Printpost__c != mapOldPav.get(pav.id).APT_Distribution_Type_Printpost__c){
                parseFieldValue(pav,pav.APT_Distribution_Type_Printpost__c);
              }
          } 
         }  
         return APT_Constants.SUCCESS_LABEL;
         } catch(Exception ex) {
            return ex.getMessage();
         }   
         
    }
    
    
    public static void parseFieldValue(Apttus_Config2__ProductAttributeValue__c pav,string fieldValue) {
        
              string distributionVal='';
              string sizeVal='';
              for(string s: fieldValue.split(';')){
                  if(setDistributionVals.contains(s)){
                     if(distributionVal ==''){
                       distributionVal=s;
                     } else{
                        distributionVal =distributionVal +';'+s;
                     }
                  }else if(setSizeVals.contains(s)){
                     if(sizeVal ==''){
                       sizeVal=s;
                     } else{
                        sizeVal =sizeVal +';'+s;
                     }
                  }
                  if(distributionVal!=''){
                   pav.APT_Distribution_type__c =distributionVal;
                  }
                  if(sizeVal!=''){
                   pav.APT_Size__c =sizeVal;
                  } 
        }
     }
     */
     
    /**
Method to update fields before event update
**/
    public static String beforeUpdateEvent(list<Apttus_Config2__ProductAttributeValue__c> listProductAttributeValue,
                                           Map<Id,Apttus_Config2__ProductAttributeValue__c> pavOldMap,
                                           Map<Id,Apttus_Config2__ProductAttributeValue__c> pavNewMap) {
                                               try {
                                                   system.debug('*** PAV before Update Handler ***');
                                                   set<String> setProductType = new set<String>();
                                                   set<String> setCategory = new set<String>();
                                                   set<String> setLodgementZone = new set<String>();
                                                   set<Id> setLineItemId = new set<Id>();
                                                   //search lodgement zone
                                                   set<String> setZoneStructure = new set<String>();
                                                   set<String> setPriceStructure = new set<String>();
                                                   set<decimal> setPostCode = new set<decimal>();
                                                   //search lodgement zone
                                                   
                                                   //calculate estimated revenue
                                                   list<Apttus_Config2__ProductAttributeValue__c> listPAV = new list<Apttus_Config2__ProductAttributeValue__c>();
                                                   list<Apttus_Config2__LineItem__c> listLineItem = new list<Apttus_Config2__LineItem__c>();
                                                   Apttus_Config2__LineItem__c lineItemSO;
                                                   //calculate estimated revenue
                                                   
                                                   for(Apttus_Config2__ProductAttributeValue__c pav : listProductAttributeValue) {
                                                       system.debug('*** PAV before Update Handler > pav.id ***'+pav.Id);
                                                       
                                                       /*
//1493
if(String.isNotBlank(pav.APT_Domestic_Customer__c) && pav.APT_Domestic_Customer__c.equalsIgnoreCase('No') 
&& String.isNotBlank(pav.APT_Volume_Data__c) && pav.APT_Volume_Data__c.equalsIgnoreCase('Yes')
&& pav.APT_Estimated_Revenue__c > 0 && pav.APT_Estimated_Revenue__c < 3000) {
return 'Estimated Revenue($) is ' + pav.APT_Estimated_Revenue__c + ' Revenue Commitment can not be Less than 3,000 when Domestic Customer is No.';
}
//1493
*/
                                                       
                                                       //1560
                                                       if(String.isNotBlank(pav.APT_Volume_Threshold_Post_BillPay__c) && String.isNotBlank(pav.APT_PostBillPay_Volume_threshold__c)
                                                          && !pav.APT_PostBillPay_Volume_threshold__c.contains(pav.APT_Volume_Threshold_Post_BillPay__c)) {
                                                              //pav.addError('Invalid Annual Volume Review.');
                                                              
                                                              return 'Invalid Annual Volume Review.';
                                                          }
                                                       //1560
                                                       
                                                       /*
if(pav.APT_Volume_Data__c != null && pav.APT_Volume_Data__c == 'Yes' && pav.APT_AirmailSmallParcelGT2kgAVGWeightKG__c < 2) {
pav.addError('Invalid value for Airmail Parcel greater than 2kg AVG Weight(KG). It must be greater than 2 kg.');
}
*/
                                                       
                                                       // Code Added for International CO - By Akansha
                                                       //workflow to trigger
                                                       //set band
                                                       String oldBandValue;
                                                       String newbandValue;
                                                       if((pavOldMap.get(pav.Id).APT_Band__c) == null && (pavNewMap.get(pav.Id).APT_Band__c) == null){
                                                           oldBandValue =  '';
                                                           newbandValue =  '';
                                                       }else{
                                                           oldBandValue = pavOldMap.get(pav.Id).APT_Band__c; 
                                                           newbandValue = pavNewMap.get(pav.Id).APT_Band__c;
                                                       }
                                                       if((String.isNotBlank(oldBandValue) && oldBandValue.equalsIgnoreCase(newbandValue)) || String.isBlank(oldBandValue)){
                                                           if(pav.APT_Volume_Data__c != null && pav.APT_Volume_Data__c.equalsIgnoreCase(APT_Constants.OPTION_NO) && (pav.APT_RK_Code_Applied__c == false)) {
                                                               if(pav.Revenue_Committment__c != null) {
                                                                   if(pav.Revenue_Committment__c.equalsIgnoreCase(APT_Constants.REVENUE_COMMITTMENT_LESS_THAN_3000)) {
                                                                       pav.APT_Band__c = APT_Constants.BAND_1;
                                                                       pav.APT_Band_Original_Value__c = pav.APT_Band__c ;
                                                                   } else {
                                                                       pav.APT_Band__c = APT_Constants.BAND_2;
                                                                       pav.APT_Band_Original_Value__c = pav.APT_Band__c ;
                                                                   }
                                                               }
                                                           }
                                                       }
                                                       //set band
                                                       
                                                       //set min quantity based on category
                                                       if(pav.Category__c != null) {    //defect 1057 //REQ2649482
                                                            if(pav.Category__c.equalsIgnoreCase(APT_Constants.CATEGORY_CAT1)) {
                                                                pav.APT_Minimum_Quantity__c = calculateMinimumQuantity(pav.APT_Minimum_Quantity__c, 1000, 1999);
                                                            } else if(pav.Category__c.equalsIgnoreCase(APT_Constants.CATEGORY_CAT2)) {
                                                                pav.APT_Minimum_Quantity__c = calculateMinimumQuantity(pav.APT_Minimum_Quantity__c, 2000, 4999);
                                                            } else if(pav.Category__c.equalsIgnoreCase(APT_Constants.CATEGORY_CAT3)) {
                                                                pav.APT_Minimum_Quantity__c = calculateMinimumQuantity(pav.APT_Minimum_Quantity__c, 5000, 9999);
                                                            } else if(pav.Category__c.equalsIgnoreCase(APT_Constants.CATEGORY_CAT4)) {
                                                                pav.APT_Minimum_Quantity__c = calculateMinimumQuantity(pav.APT_Minimum_Quantity__c, 10000, 19999);
                                                            } else if(pav.Category__c.equalsIgnoreCase(APT_Constants.CATEGORY_CAT5)) {
                                                                pav.APT_Minimum_Quantity__c = calculateMinimumQuantity(pav.APT_Minimum_Quantity__c, 20000, 49999);
                                                            } else if(pav.Category__c.equalsIgnoreCase(APT_Constants.CATEGORY_CAT6) && (pav.APT_Minimum_Quantity__c == null || pav.APT_Minimum_Quantity__c == 1 || pav.APT_Minimum_Quantity__c < 50000)) {
                                                                pav.APT_Minimum_Quantity__c = 50000;
                                                            }
                                                        }
                                                       
                                                       //set min quantity based on category
                                                       
                                                       //workflow to trigger
                                                       
                                                       setProductType.add(pav.APT_Product_Type__c);
                                                       setCategory.add(pav.Category__c);                
                                                       setLodgementZone.add(pav.APT_Lodgement_Zone__c);
                                                       setLineItemId.add(pav.Apttus_Config2__LineItemId__c);
                                                       
                                                       //search lodgement zone
                                                       setZoneStructure.add(pav.APT_Zone_Structure__c);
                                                       setPriceStructure.add(pav.APTS_Price_Structure__c);
                                                       if(pav.APT_Postcode__c != null) {
                                                           setPostCode.add(decimal.valueOf(pav.APT_Postcode__c));
                                                       }
                                                       //search lodgement zone
                                                       
                                                       //cubic factor - updated for REQ1282919 - VO             
                                                       if(pav.Category__c != null && pav.Category__c.equalsIgnoreCase(APT_Constants.CATEGORY_CAT1) && pav.APT_Cubic_Factor__c != null && (pav.APTS_Price_Structure__c != null && pav.APTS_Price_Structure__c != 'WINE {Z30}') ) {
                                                           pav.APT_Cubic_Factor__c = null;
                                                       }
                                                       //cubic factor
                                                       
                                                       //calculate estimated revenue
                                                       if(pav.APT_Volume_Data__c != null && true == pav.APT_Volume_Data__c.equalsIgnoreCase(APT_Constants.OPTION_YES)){
                                                           listPAV.add(pav);
                                                       }
                                                       //calculate estimated revenue
                                                       
                                                   }
                                                   
                                                   // Getting the mapLineItem to fetch the product code 
                                                   // This was placed after search lodgement zone 
                                                   // Changes for CI-7 (APPC)
                                                   //CI-224 Removed APT_Existing_APPC_Customer__c
                                                   map<Id, Apttus_Config2__LineItem__c> mapLineItem = new map<Id, Apttus_Config2__LineItem__c>([SELECT Id, Name, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode,
                                                                                                                                                Apttus_Config2__ConfigurationId__c, 
                                                                                                                                                Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__r.APT_Eligible_APPC_Tier__c,
                                                                                                                                                Apttus_Config2__LineType__c,
                                                                                                                                                Apttus_Config2__AttributeValueId__r.APT_Industry__c, 
                                                                                                                                                Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c,
                                                                                                                                                Apttus_Config2__AttributeValueId__r.APT_International_Letters__c,
                                                                                                                                                Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Type
                                                                                                                                                FROM Apttus_Config2__LineItem__c WHERE Id IN :setLineItemId]);
                                                   
                                                   //search lodgement zone
                                                   if(setZoneStructure.size() > 0) {
                                                       map<String, list<APT_Lodgement_Zone__c>> mapLZ = new map<String, list<APT_Lodgement_Zone__c>>();
                                                       
                                                       String pavAPTTierRef = '';                                          
                                                       for(Apttus_Config2__ProductAttributeValue__c pav : listProductAttributeValue) {
                                                           
                                                           Apttus_Config2__LineItem__c configLineItem = mapLineItem.get(pav.Apttus_Config2__LineItemId__c);
                                                           
                                                           System.debug('configLineItem.Apttus_Config2__ProductId__r.ProductCode' + configLineItem.Apttus_Config2__ProductId__r.ProductCode);
                                                           System.debug('pav.APTS_Price_Structure__c' + pav.APTS_Price_Structure__c);
                                                           System.debug('pav.APT_RK_Code_Applied__c' + pav.APT_RK_Code_Applied__c);
                                                           System.debug('pav.APT_Cubic_Factor__c' + pav.APT_Cubic_Factor__c);
                                                           if(configLineItem != null 
                                                              && configLineItem.Apttus_Config2__ProductId__r != null
                                                              && configLineItem.Apttus_Config2__ProductId__r.ProductCode != null //INC1976447
                                                              && configLineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) 
                                                              && pav.APTS_Price_Structure__c != null
                                                              && pav.APTS_Price_Structure__c.equalsIgnoreCase(APT_Constants.STRING_BANDED_Z6) 
                                                              && pav.APT_RK_Code_Applied__c == false ){
                                                                  pav.APT_Cubic_Factor__c = NULL;
                                                              }
                                                           System.debug('pav.APT_Cubic_Factor__c '+pav.APT_Cubic_Factor__c);
                                                           
                                                           decimal postcode = 0;
                                                           
                                                           if(configLineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_APPC){
                                                               
                                                               // CI-69 Code block for new APPC customer to fetch the tier value based on the min spend per anumn entered on the cart attribute configuration.
                                                               //CI-224 Existing APPC Customer flag from Proposal rather then from Account Object
                                                               string strNewAPPCCustomer = mapLineItem.get(pav.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Type;
                                                               
                                                               if(strNewAPPCCustomer == APT_Constants.OPPORTUNITY_TYPE_NEW_CUSTOMER && pav.APT_Min_Spend_Per_Annum__c != NULL && pav.APT_RK_Code_AppliedYN__c == APT_Constants.OPTION_NO)
                                                               {
                                                                   APT_Simplified_Parcel_Spend_Range__c sr;
                                                                   // CI-69 Fetch the APT_Simplified_Parcel_Spend_Range__c where the pav.APT_Min_Spend_Per_Annum__c is in range of APT_Min_Spend__c and APT_Max_Spend__c
                                                                   if(pavAPTTierRef == '') {
                                                                    
                                                                     sr = [select Id, APT_Min_Spend__c, APT_Max_Spend__c, APT_Tier__c from APT_Simplified_Parcel_Spend_Range__c where APT_Product_Code__c =:APT_Constants.PRODUCT_CODE_APPC and APT_Min_Spend__c <= :pav.APT_Min_Spend_Per_Annum__c and APT_Max_Spend__c >= :pav.APT_Min_Spend_Per_Annum__c LIMIT 1];
                                                                   }
                                                                   else 
                                                                   {
                                                                        pav.APT_Customer_Tier__c = pavAPTTierRef;
                                                                   }                                                                 
                                                                   if(!String.isBlank(sr?.APT_Tier__c)){

                                                                        pavAPTTierRef = sr.APT_Tier__c;
                                                                       pav.APT_Customer_Tier__c = sr.APT_Tier__c;
                                                                   }
                                                               }
                                                               
                                                               if(pav.APT_Primary_Postcode__c != null) {
                                                                   postcode = decimal.valueOf(pav.APT_Primary_Postcode__c);

                                                                   for(APT_Lodgement_Zone__c lodgementZone : [SELECT Id, Name, APT_Lodgement_Zone_Code__c, APT_Post_Code_Start__c, APT_Post_Code_End__c,
                                                                                                  APT_Zone_Structure__c 
                                                                                                  FROM APT_Lodgement_Zone__c 
                                                                                                  WHERE APT_Zone_Structure__c IN :setZoneStructure and APT_Post_Code_Start__c =: postcode]) {
                                                                                                      
                                                                                                      list<APT_Lodgement_Zone__c> listLodgementZone = mapLZ.get(lodgementZone.APT_Zone_Structure__c);
                                                                                                      if(listLodgementZone != null) {
                                                                                                          listLodgementZone.add(lodgementZone);
                                                                                                          mapLZ.put(lodgementZone.APT_Zone_Structure__c, listLodgementZone);
                                                                                                      } else {
                                                                                                          listLodgementZone = new list<APT_Lodgement_Zone__c>();
                                                                                                          listLodgementZone.add(lodgementZone);
                                                                                                          mapLZ.put(lodgementZone.APT_Zone_Structure__c, listLodgementZone);
                                                                                                      }
                                                                                                  }

                                                               }
                                                           } else{
                                                               if(pav.APT_Postcode__c != null) {
                                                                   postcode = decimal.valueOf(pav.APT_Postcode__c);

                                                                   for(APT_Lodgement_Zone__c lodgementZone : [SELECT Id, Name, APT_Lodgement_Zone_Code__c, APT_Post_Code_Start__c, APT_Post_Code_End__c,
                                                                                                  APT_Zone_Structure__c 
                                                                                                  FROM APT_Lodgement_Zone__c 
                                                                                                  WHERE APT_Zone_Structure__c IN :setZoneStructure]) {
                                                                                                      
                                                                                                      list<APT_Lodgement_Zone__c> listLodgementZone = mapLZ.get(lodgementZone.APT_Zone_Structure__c);
                                                                                                      if(listLodgementZone != null) {
                                                                                                          listLodgementZone.add(lodgementZone);
                                                                                                          mapLZ.put(lodgementZone.APT_Zone_Structure__c, listLodgementZone);
                                                                                                      } else {
                                                                                                          listLodgementZone = new list<APT_Lodgement_Zone__c>();
                                                                                                          listLodgementZone.add(lodgementZone);
                                                                                                          mapLZ.put(lodgementZone.APT_Zone_Structure__c, listLodgementZone);
                                                                                                      }
                                                                                                  }
                                                               }
                                                           }
                                                           
                                                           list<APT_Lodgement_Zone__c> listLodgementZone = mapLZ.get(pav.APT_Zone_Structure__c);
                                                           if(listLodgementZone != null) {
                                                               for(APT_Lodgement_Zone__c lz: listLodgementZone) {
                                                                   if(lz.APT_Post_Code_Start__c <= postcode && lz.APT_Post_Code_End__c >= postcode) {
                                                                       //if(pav.APT_Lodgement_Zone__c == null) {
                                                                       pav.APT_Lodgement_Zone__c = lz.Id;
                                                                       setLodgementZone.add(pav.APT_Lodgement_Zone__c);    //feature pricing
                                                                       //}
                                                                   }
                                                               }
                                                           }
                                                       }
                                                   }
                                                   //search lodgement zone
                                                   
                                                   //calculate estimated revenue
                                                   if(listPAV.size() > 0){
                                                       set<String> setProduct = new set<String>();
                                                       set<String> setZone = new set<String>();
                                                       set<String> setBand = new set<String>();
                                                       map<String, list<Apttus_Config2__PriceMatrixEntry__c>> mappmeByZone = new map<String, list<Apttus_Config2__PriceMatrixEntry__c>>();
                                                       map<String, double> mpPMEByBand = new map<String, double>();
                                                       
                                                       //Start of INC1977875 fix - To fix query not being selective error
                                                       list<string> myIds = new list<string>();
                                                       list<string> pliIds = new list<string>();
                                                       list<string> pmIds = new list<string>();
                                                       
                                                       for (Product2 product :  [select Id from Product2  where APT_International_Pricing__c = true]){
                                                           myIds.add(product.Id);
                                                       }
                                                       for (Apttus_Config2__PriceListItem__c pli : [select Id from Apttus_Config2__PriceListItem__c   where  Apttus_Config2__ProductId__c in :myIds]){
                                                           pliIds.add(pli.Id);
                                                       }
                                                       for (Apttus_Config2__PriceMatrix__c pm :  [select Id from Apttus_Config2__PriceMatrix__c  where  Apttus_Config2__PriceListItemId__c in :pliIds]){
                                                           pmIds.add(pm.Id);
                                                       }
                                                       
                                                       list<Apttus_Config2__PriceMatrixEntry__c> priceMatrixEntries =  
                                                           [select Apttus_Config2__Dimension1Value__c, Apttus_Config2__Dimension2Value__c, Apttus_Config2__Dimension3Value__c,
                                                            Apttus_Config2__AdjustmentAmount__c,
                                                            Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band__c, Apttus_Config2__PriceOverride__c,
                                                            Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode,   
                                                            Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Lodgement_Zone_Code__c,
                                                            Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_eParcel_Lodgment__c,
                                                            Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Zones__c,  
                                                            Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_International_Pricing__c,
                                                            Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band_Range_Max__c from 
                                                            Apttus_Config2__PriceMatrixEntry__c 
                                                            where Apttus_Config2__PriceMatrixId__c in :pmIds];
                                                       //End of INC1977875 fix - To fix query not being selective error

                                                       for(Apttus_Config2__PriceMatrixEntry__c pme : priceMatrixEntries){
                                                           setProduct.add(pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode);
                                                           setZone.add(pme.Apttus_Config2__Dimension1Value__c); // dimension 1 value stores zone for international price
                                                           setBand.add(pme.Apttus_Config2__PriceMatrixId__r?.Apttus_Config2__PriceListItemId__r?.APT_Band__c);
                                                           //System.debug('setproduct::'+setProduct);
                                                           //by industry + band
                                                           mpPMEByBand.put(pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band__c, 
                                                                           pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band_Range_Max__c);
                                                           
                                                           //by industry + band + product
                                                           if(pme.Apttus_Config2__Dimension3Value__c!=null){ // dimension 3 value is for weight in international price data
                                                               list<Apttus_Config2__PriceMatrixEntry__c> listPmeByZone1 = mappmeByZone.get(pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__Dimension3Value__c);
                                                               if(listPmeByZone1 != null && listPmeByZone1.size() > 0) {
                                                                   listPmeByZone1.add(pme);
                                                                   mappmeByZone.put(pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__Dimension3Value__c, listPmeByZone1);
                                                               } else {
                                                                   listPmeByZone1 = new list<Apttus_Config2__PriceMatrixEntry__c>();
                                                                   listPmeByZone1.add(pme);
                                                                   mappmeByZone.put(pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__Dimension1Value__c + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__Dimension3Value__c, listPmeByZone1);
                                                               }
                                                               
                                                           }
                                                           else{
                                                               list<Apttus_Config2__PriceMatrixEntry__c> listPmeByZone = mappmeByZone.get(pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__Dimension1Value__c);
                                                               if(listPmeByZone != null && listPmeByZone.size() > 0) {
                                                                   listPmeByZone.add(pme);
                                                                   mappmeByZone.put(pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__Dimension1Value__c, listPmeByZone);
                                                               } else {
                                                                   listPmeByZone = new list<Apttus_Config2__PriceMatrixEntry__c>();
                                                                   listPmeByZone.add(pme);
                                                                   mappmeByZone.put(pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pme.Apttus_Config2__Dimension1Value__c, listPmeByZone);
                                                               }
                                                           }
                                                       }
                                                       
                                                       list<String> listBand = new list<String>();
                                                       listBand.addAll(setBand);
                                                       listBand.sort();
                                                       
                                                       // Code Added fro International CO - By Akansha
                                                       String oldBandValue;
                                                       String newbandValue;
                                                       for(Apttus_Config2__ProductAttributeValue__c pav : listProductAttributeValue) {
                                                           if((pavOldMap.get(pav.Id).APT_Band__c) == null && (pavNewMap.get(pav.Id).APT_Band__c) == null){
                                                               oldBandValue =  '';
                                                               newbandValue =  '';
                                                           }else{
                                                               oldBandValue = pavOldMap.get(pav.Id).APT_Band__c; 
                                                               newbandValue = pavNewMap.get(pav.Id).APT_Band__c;
                                                           }
                                                           system.debug('*** oldBandValue ***'+oldBandValue);
                                                           system.debug('*** newbandValue ***'+newbandValue);
                                                           if((String.isNotBlank(oldBandValue) && oldBandValue.equalsIgnoreCase(newbandValue)) || String.isBlank(oldBandValue)){
                                                               //String pricePoint = '';   //remove hardcoding
                                                               String pricePoint;
                                                               if(pav.APT_eParcel_Lodgment__c == true && pav.APT_International_Letters__c == true) {
                                                                   pricePoint = APT_Constants.ePARCEL_PRICE_POINT;
                                                               } else if(pav.APT_eParcel_Lodgment__c == true && pav.APT_International_Letters__c == false) {
                                                                   pricePoint = APT_Constants.ePARCEL_PRICE_POINT;
                                                               } else if(pav.APT_eParcel_Lodgment__c == false && pav.APT_International_Letters__c == true) {
                                                                   pricePoint = APT_Constants.CSP_PRICE_POINT;
                                                               } else {
                                                                   //default price point. This won't be the case.
                                                                   pricePoint = APT_Constants.ePARCEL_PRICE_POINT;
                                                               }  
                                                               
                                                               Apttus_Config2__LineItem__c lineItem = mapLineItem.get(pav.Apttus_Config2__LineItemId__c);
                                                               system.debug('*** listBand ***'+listBand);
                                                               for(String band : listBand){
                                                                   system.debug('*** band ***'+band);
                                                                   double dbEstimatedRevenue = processInternationalPriceData(lineItem, band, setProduct, setZone, pricePoint, mappmeByZone, pav);
                                                                   system.debug('*** dbEstimatedRevenue ***'+dbEstimatedRevenue);
                                                                   //find max revenue band
                                                                   double dbMaximumRevenueBand = mpPMEByBand.get(band);
                                                                   system.debug('*** dbMaximumRevenueBand ***'+dbMaximumRevenueBand);
                                                                   //validate band
                                                                   boolean bIsValidBand = validateBand(dbEstimatedRevenue, dbMaximumRevenueBand, band);
                                                                   system.debug('*** bIsValidBand ***'+bIsValidBand);
                                                                   //if valid band
                                                                   if(bIsValidBand == true) {
                                                                       //populate estimated revenue on attribute
                                                                       if(pav.APT_RK_Code_Applied__c == false){
                                                                           pav.APT_Estimated_Revenue__c = dbEstimatedRevenue;
                                                                       }
                                                                       pav.APT_Band__c = band;
                                                                       pav.APT_Band_Original_Value__c = pav.APT_Band__c ;
                                                                       //update productAttributeValue;   //will be executed only once
                                                                       
                                                                       /*
//defect-1332
if(pav.APT_BAND__c.equalsIgnoreCase(APT_Constants.BAND_5)) {
if(pav.APT_Estimated_Revenue__c <= 50000) {
pav.Revenue_Committment__c = APT_Constants.REVENUE_COMMITTMENT_35000_50000;
} else if(pav.APT_Estimated_Revenue__c > 50000) {
pav.Revenue_Committment__c = APT_Constants.REVENUE_COMMITTMENT_ABOVE_50000;
} else {} 
}
//defect-1332
*/
                                
                                break;
                            }                      
                        }
                    }
                    
                    //defect-1332
                    //set revenue committment
                    if(pav.APT_Volume_Data__c != null && pav.APT_Volume_Data__c.equalsIgnoreCase(APT_Constants.OPTION_YES) && pav.APT_BAND__c != null && (pav.APT_RK_Code_Applied__c == false)) {
                        if((String.isNotBlank(oldBandValue) && oldBandValue.equalsIgnoreCase(newbandValue)) || String.isBlank(oldBandValue)) {  //1588
                            if(pav.APT_BAND__c.equalsIgnoreCase(APT_Constants.BAND_1)) {
                                /**
//1493
if(String.isNotBlank(pav.APT_Domestic_Customer__c) && pav.APT_Domestic_Customer__c.equalsIgnoreCase('No')
&& String.isNotBlank(pav.APT_Volume_Data__c) && pav.APT_Volume_Data__c.equalsIgnoreCase('Yes')
&& pav.APT_Estimated_Revenue__c > 0 && pav.APT_Estimated_Revenue__c < 3000) {

return 'Estimated Revenue($) is ' + pav.APT_Estimated_Revenue__c + '. Revenue Commitment can not be Less than 3,000 when Domestic Customer is No.';
} 
//1493
**/
                                pav.Revenue_Committment__c = APT_Constants.REVENUE_COMMITTMENT_LESS_THAN_3000;
                            } else if(pav.APT_BAND__c.equalsIgnoreCase(APT_Constants.BAND_2)) {
                                pav.Revenue_Committment__c = APT_Constants.REVENUE_COMMITTMENT_3000_4999;
                            } else if(pav.APT_BAND__c.equalsIgnoreCase(APT_Constants.BAND_3)) {
                                pav.Revenue_Committment__c = APT_Constants.REVENUE_COMMITTMENT_5000_19999;
                            } else if(pav.APT_BAND__c.equalsIgnoreCase(APT_Constants.BAND_4)) {
                                pav.Revenue_Committment__c = APT_Constants.REVENUE_COMMITTMENT_20000_34999;
                            } else if(pav.APT_BAND__c.equalsIgnoreCase(APT_Constants.BAND_5)) {     //defect 1332
                                if(pav.APT_Estimated_Revenue__c >= 35000 && pav.APT_Estimated_Revenue__c <= 50000) {
                                    pav.Revenue_Committment__c = APT_Constants.REVENUE_COMMITTMENT_35000_50000;
                                } else if(pav.APT_Estimated_Revenue__c > 50000) {
                                    pav.Revenue_Committment__c = APT_Constants.REVENUE_COMMITTMENT_ABOVE_50000;
                                } else {}   //defect 1332
                            } else {}
                        }
                    }
                    //set revenue committment
                    //defect-1332
                    
                    /*
if(String.isNotBlank(pav.APT_Domestic_Customer__c) && pav.APT_Domestic_Customer__c.equalsIgnoreCase('No') 
&& String.isNotBlank(pav.APT_Volume_Data__c) && pav.APT_Volume_Data__c.equalsIgnoreCase('Yes')
&& pav.APT_Estimated_Revenue__c != null && pav.APT_Estimated_Revenue__c != 0
&& pav.Revenue_Committment__c.equalsIgnoreCase('Less than 3,000')){
return 'Invalid Revenue Commitment. Revenue Commitment can not be Less than 3,000 when Domestic Customer is No.';
}
*/
                }
            }
            //calculate estimated revenue
            
            //feature pricing
            if(setLodgementZone.size() > 0) {
                map<Id, String> mapLodgementZone = new map<Id, String>();
                for(APT_Lodgement_Zone__c lz : [SELECT Id, Name, APT_Lodgement_Zone_Code__c FROM APT_Lodgement_Zone__c WHERE Id IN :setLodgementZone]) {
                    mapLodgementZone.put(lz.Id, lz.APT_Lodgement_Zone_Code__c);
                }
                
                map<String, APT_Feature_Pricing__c> mapFeaturePricing = new map<String, APT_Feature_Pricing__c>();
                for(APT_Feature_Pricing__c fp : [SELECT Id, Name, APT_Category__c, APT_Lodgement_Zone__c, APT_Network_Type__c, APT_Product_Type__c, 
                                                 APT_Flag_Fall_Rate__c, APT_Per_Kg_Rate__c 
                                                 FROM APT_Feature_Pricing__c
                                                 WHERE APT_Product_Type__c IN :setProductType
                                                 AND APT_Category__c IN :setCategory
                                                 AND APT_Lodgement_Zone__c IN :mapLodgementZone.values()]) {
                                                     
                                                     mapFeaturePricing.put(fp.APT_Category__c + APT_Constants.SEPERATOR_SIMILARITY + fp.APT_Lodgement_Zone__c + APT_Constants.SEPERATOR_SIMILARITY + fp.APT_Product_Type__c + APT_Constants.SEPERATOR_SIMILARITY + fp.APT_Network_Type__c, fp);
                                                 }
                
                for(Apttus_Config2__ProductAttributeValue__c pav : listProductAttributeValue) {
                    Apttus_Config2__LineItem__c li = mapLineItem.get(pav.Apttus_Config2__LineItemId__c);
                    //eParcel Standard
                    if(li != null && li.Apttus_Config2__ProductId__c != null && li.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) {
                        if(mapFeaturePricing.get(pav.Category__c + APT_Constants.SEPERATOR_SIMILARITY + mapLodgementZone.get(pav.APT_Lodgement_Zone__c) + APT_Constants.SEPERATOR_SIMILARITY + pav.APT_Product_Type__c + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.NETWORK_TYPE_STANDARD) != null) {
                            APT_Feature_Pricing__c fp = mapFeaturePricing.get(pav.Category__c + APT_Constants.SEPERATOR_SIMILARITY + mapLodgementZone.get(pav.APT_Lodgement_Zone__c) + APT_Constants.SEPERATOR_SIMILARITY + pav.APT_Product_Type__c + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.NETWORK_TYPE_STANDARD);
                            
                            //flag fall rate
                            if(fp != null && fp.APT_Flag_Fall_Rate__c != null) {
                                pav.APT_Flag_Fall_Rate__c = fp.APT_Flag_Fall_Rate__c;
                            }
                            //per kg rate
                            if(fp != null && fp.APT_Per_Kg_Rate__c != null) {
                                pav.APT_Per_Kg_Rate__c = fp.APT_Per_Kg_Rate__c;
                            }                  
                        }
                    }
                    //eParcel Express
                    else if(li != null && li.Apttus_Config2__ProductId__c != null && li.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) {                    
                        if(mapFeaturePricing.get(pav.Category__c + APT_Constants.SEPERATOR_SIMILARITY +  mapLodgementZone.get(pav.APT_Lodgement_Zone__c) + APT_Constants.SEPERATOR_SIMILARITY + pav.APT_Product_Type__c + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.NETWORK_TYPE_EXPRESS) != null) {
                            APT_Feature_Pricing__c fp = mapFeaturePricing.get(pav.Category__c + APT_Constants.SEPERATOR_SIMILARITY + mapLodgementZone.get(pav.APT_Lodgement_Zone__c) + APT_Constants.SEPERATOR_SIMILARITY + pav.APT_Product_Type__c + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.NETWORK_TYPE_EXPRESS);
                            //flag fall rate
                            if(fp != null && fp.APT_Flag_Fall_Rate__c != null) {
                                pav.APT_Flag_Fall_Rate__c = fp.APT_Flag_Fall_Rate__c;
                            }
                            //per kg rate
                            if(fp != null && fp.APT_Per_Kg_Rate__c != null) {
                                pav.APT_Per_Kg_Rate__c = fp.APT_Per_Kg_Rate__c;
                            }                         
                        }
                    }                
                    else{}
                }
            }
            //Defect: 1426 --  Reset Apttus_Config2__LineItem__c.APT_Added_LP__c whenever APT_Lodgement_Zone__c is changed
            for(Apttus_Config2__ProductAttributeValue__c pav : listProductAttributeValue) {
                
                if(pav.APT_Lodgement_Zone__c != null && pav.APT_Lodgement_Zone__c != pavOldMap.get(pav.ID).APT_Lodgement_Zone__c)
                {
                    lineItemSO = new Apttus_Config2__LineItem__c(ID = pav.Apttus_Config2__LineItemId__c, APT_Added_LP__c = false);
                    listLineItem.add(lineItemSO);
                }
                
            }
            if(listLineItem.size() > 0)
            {
                Update listLineItem;
            }
            
            //feature pricing
            
            return APT_Constants.SUCCESS_LABEL;
        }catch(Exception ex) {
            return ex.getMessage();
        }
                                                                        }
    //Added Mathew
    public static Map<String,Map<String, Decimal>> getInternationalZoneDispersion(Map<ID,Apttus_Config2__LineItem__c> lineItemsMap){
        Map<String,String> lineItemIdToProductCodeMap = new Map <String, String>();
        Map<String,Map<String, Decimal>> productCodeToZoneDispersion = new Map <String,Map<String,Decimal>>();
        //check if the InternationalDigitalPCMSBundlewithAirmail is present amonst the line items.
        for(Apttus_Config2__LineItem__c li : lineItemsMap.Values()){
            if(APT_CONSTANTS.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL.equalsIgnoreCase(li.Apttus_Config2__ProductId__r.ProductCode)){
                //add to Map
                lineItemIdToProductCodeMap.put(li.Id,li.Apttus_Config2__ProductId__r.ProductCode);
            }
        }
        //get the custom metadata
        if(!lineItemIdToProductCodeMap.isEmpty()){
            for(APT_Zone_To_Dispersion_Map__mdt zDMap: [SELECT Id, Dispersion__c,Zone__c,Product_Code__c 
                                                        FROM APT_Zone_To_Dispersion_Map__mdt
                                                        WHERE Product_Code__c IN : lineItemIdToProductCodeMap.Values()]){
                                                            Map<String,Decimal> zoneToDispersionMap = new Map <String,Decimal>();                                            
                                                            if(productCodeToZoneDispersion.containsKey(zDMap.Product_Code__c)){
                                                                zoneToDispersionMap = productCodeToZoneDispersion.get(zDMap.Product_Code__c);
                                                                zoneToDispersionMap.put(zDMap.Zone__c,zDMap.Dispersion__c);
                                                            }else{
                                                                zoneToDispersionMap.put(zDMap.Zone__c,zDMap.Dispersion__c);
                                                            }
                                                            productCodeToZoneDispersion.put(zDMap.Product_Code__c,zoneToDispersionMap);                                        
                                                            
                                                        }
        }
        return productCodeToZoneDispersion;
        
    }
    
    /*
Calculate Band when Volume Data = No based on Revenue Committment selected on attributes
*/
    /*
public static void bandInfo(list<Apttus_Config2__ProductAttributeValue__c> ProductAttributeList) {
map<String, APT_International_Price_Data__c> mapBand = new map<String, APT_International_Price_Data__c>();
for(APT_International_Price_Data__c ipd : [SELECT Id, Name, APT_Band__c,
APT_Band_Range_Min__c, APT_Band_Range_Max__c
FROM APT_International_Price_Data__c
limit 50000]) {

mapBand.put(ipd.APT_Band_Range_Min__c + '-' + ipd.APT_Band_Range_Max__c, ipd);
}
system.debug('*** mapBand ***'+mapBand);
system.debug('*** mapBand > size ***'+mapBand.size());

for(Apttus_Config2__ProductAttributeValue__c pav : ProductAttributeList) {
system.debug('*** volume data ***'+pav.APT_Volume_Data__c);
system.debug('*** revenue committment ***'+pav.Revenue_Committment__c);
if(pav.APT_Volume_Data__c == 'No' && pav.Revenue_Committment__c != null) {
string revenueCommittment = pav.Revenue_Committment__c.replaceAll('[a-zA-Z$, ]','');
system.debug('*** revenueCommittment ***'+revenueCommittment);
list<string> listRevenueCommittment = revenueCommittment.split('-');
system.debug('*** listRevenueCommittment ***'+listRevenueCommittment );
if(listRevenueCommittment != null) {
for(APT_International_Price_Data__c ipd : mapBand.values()) {    
system.debug('*** band range min ***'+ipd.APT_Band_Range_Min__c );
system.debug('*** band range max ***'+ipd.APT_Band_Range_Max__c );
system.debug('*** listRevenueCommittment > size ***'+listRevenueCommittment.size());                                      
if(listRevenueCommittment.size() == 2 && ipd.APT_Band_Range_Min__c != null && ipd.APT_Band_Range_Max__c != null) {
system.debug('*** listRevenueCommittment[0] ***'+listRevenueCommittment[0]);
system.debug('*** listRevenueCommittment[1] ***'+listRevenueCommittment[1]);                                                                            
if(Integer.valueOf(listRevenueCommittment[0]) == Integer.valueOf(ipd.APT_Band_Range_Min__c) && Integer.valueOf(listRevenueCommittment[1]) == Integer.valueOf(ipd.APT_Band_Range_Max__c)) {
pav.APT_Band__c = ipd.APT_Band__c;
system.debug('*** pav.APT_Band__c > 1 ***'+pav.APT_Band__c ); 
}                       
} else if(listRevenueCommittment.size() == 1) {
if(Integer.valueOf(listRevenueCommittment[0]) >= Integer.valueOf(ipd.APT_Band_Range_Max__c)) {
pav.APT_Band__c = ipd.APT_Band__c;
system.debug('*** pav.APT_Band__c > 2 ***'+pav.APT_Band__c ); 
}
}                       
}           
}                
}
}
}
*/
    
    /*
public static void bandInfo(list<Apttus_Config2__ProductAttributeValue__c> ProductAttributeList) {
try{
List<Aggregateresult> Bandlist = new List<Aggregateresult>();
Bandlist=[select AVG(APT_Band_Range_Min__c) min, AVG(APT_Band_Range_Max__c) max, APT_Band__c band from APT_International_Price_Data__c group by APT_Band__c];
system.debug('@@Aggrerate'+Bandlist );
for(Apttus_Config2__ProductAttributeValue__c P1:ProductAttributeList ){
if(p1.Revenue_Committment__c!=null && Bandlist.size()>0 ){
String TempString1 =P1.Revenue_Committment__c;
String TempString2 =TempString1.replaceAll('[a-zA-Z$, ]','');
String[] TempString3=TempString2.split('-');

for(Aggregateresult AIP:Bandlist){
if( (TempString3.size()==2) && (integer.valueof(TempString3[0])==integer.valueof((decimal)AIP.get('min'))) && (integer.valueof(TempString3[1])==integer.valueof((decimal)AIP.get('max')))) {
System.debug('Entered 1st if');
system.debug('@@before'+P1.APT_Band__c);
P1.APT_Band__c=(string)AIP.get('band');


}
else if((TempString3.size()==1) && (integer.valueof(TempString3[0])>integer.valueof((decimal)AIP.get('max')))) {
P1.APT_Band__c=(string)AIP.get('band');
}
}

}

}

}

catch(Exception ex) {
ex.getMessage();
}


}
*/
    
    /**
This method will return true if band is valid otherwise false.
*/
    private static Boolean validateBand(double dbEstimatedRevenue, double dbMaximumRevenueBand, String band) {
        if(dbEstimatedRevenue <= dbMaximumRevenueBand || band.equalsIgnoreCase(APT_Constants.BAND_5) == true) {
            return true;
        } else {
            return false;
        }
    }
    
    /**
This method will return Estimated Revenue for specific BAND provided as parameter.
Estimated revenue is summation of product revenue.

@params:
lineItem:                       line item details
band:                           BAND_1, BAND_2, BAND_3, BAND_4 or BAND_5
setProduct:                     set of international products
setZone:                        Zone1, Zone2, Zone3, Zone4, Zone5, Zone6, Zone7 and Zone8
pricePoint:                     eParcel or CSP
mappmeByZone:  list of internation price data by key
mapProductAttributeValue:       product attribute value by line item id
*/
    public static double processInternationalPriceData(Apttus_Config2__LineItem__c lineItem, String band, set<String> setProduct, set<String> setZone, 
                                                       String pricePoint, map<String, list<Apttus_Config2__PriceMatrixEntry__c>> mappmeByZone,  Apttus_Config2__ProductAttributeValue__c productAttributeValue) {
                                                           double dbEstimatedRevenue = 0;   
                                                           try {
                                                               for(String product : setProduct) {
                                                                   double dbProductRevenue = calculateProductRevenue(lineItem, band, product, setZone, pricePoint, mappmeByZone, productAttributeValue);
                                                                   system.debug('*** before > dbProductRevenue ***'+dbProductRevenue);
                                                                   //*******New Bundles International Digital PCMS,International Digital PCMS Inc Airmail letters and International Airmail Letters(Start)
                                                                   double dbprNew = calculateProductRevenueforNewIntBundle(dbProductRevenue,lineItem,band,product,setZone, 
                                                                                                                           pricePoint,mappmeByZone,productAttributeValue);
                                                                   dbProductRevenue += dbprNew;
                                                                   
                                                                   dbEstimatedRevenue += dbProductRevenue;
                                                                   system.debug('*** after > dbProductRevenue ***'+dbProductRevenue);
                                                               } 
                                                           } 
                                                           catch(Exception ex) {
                                                               system.debug('Exception'+ex.getMessage());
                                                               return null;
                                                           }
                                                           //system.debug('*** dbEstimatedRevenue ***'+dbEstimatedRevenue );       
                                                           return dbEstimatedRevenue;
                                                       }
    
    /**
* This method will return Product Revenue.
* Formula: PRODUCT_TOTAL_REVENUE =∑(n=1)^8〖PRODUCT_VOLUME  x  DISPERSION for ZONE n  (PER_ITEM_RATE for ZONE n+ PRODUCT_AVG_WEIGHT  x  PER_KG_RATE for ZONE n〗) 
* @params:
* lineItem:                       line item details
* band:                           BAND_1, BAND_2, BAND_3, BAND_4 or BAND_5
* setProduct:                     set of international products
* setZone:                        Zone1, Zone2, Zone3, Zone4, Zone5, Zone6, Zone7 and Zone8
* pricePoint:                     eParcel or CSP
* mappmeByZone:  list of internation price data by key
* mapProductAttributeValue:       product attribute value by line item id
**/
    public static double calculateProductRevenue(Apttus_Config2__LineItem__c lineItem, String band, String product, set<String> setZone, 
                                                 String pricePoint, map<String, list<Apttus_Config2__PriceMatrixEntry__c>> mappmeByZone,  
                                                 Apttus_Config2__ProductAttributeValue__c productAttributeValue) {
                                                     
                                                     /**
* system.debug('*** Zone 1 Dispersion ***'+productAttributeValue.APT_Zone_1_Dispersion__c);
* system.debug('*** Zone 2 Dispersion ***'+productAttributeValue.APT_Zone_2_Dispersion__c);
* system.debug('*** Zone 3 Dispersion ***'+productAttributeValue.APT_Zone_3_Dispersion__c);
* system.debug('*** Zone 4 Dispersion ***'+productAttributeValue.APT_Zone_4_Dispersion__c);
* system.debug('*** Zone 5 Dispersion ***'+productAttributeValue.APT_Zone_5_Dispersion__c);
* system.debug('*** Zone 6 Dispersion ***'+productAttributeValue.APT_Zone_6_Dispersion__c);
* system.debug('*** Zone 7 Dispersion ***'+productAttributeValue.APT_Zone_7_Dispersion__c);
* system.debug('*** Zone 8 Dispersion ***'+productAttributeValue.APT_Zone_8_Dispersion__c);
* system.debug('*** product ***'+product);
* **/
                                                     double dbProductRevenue = 0;
                                                     //System.debug('Product::::'+product); 
                                                     try{
                                                         for(String zone : setZone) {
                                                             String key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone;
                                                             //system.debug('*** key ***'+key);
                                                             
                                                             if(mappmeByZone.get(key) != null) {              
                                                                 decimal perKGRate = 0;
                                                                 decimal perItemRate = 0;
                                                                 for(Apttus_Config2__PriceMatrixEntry__c pme : mappmeByZone.get(key)) {
                                                                     if(pme.Apttus_Config2__Dimension2Value__c == 'Per Item'){
                                                                         perItemRate = pme.Apttus_Config2__AdjustmentAmount__c;
                                                                     }
                                                                     else if(pme.Apttus_Config2__Dimension2Value__c == 'Per Kg'){
                                                                         perKGRate = pme.Apttus_Config2__AdjustmentAmount__c;
                                                                     }
                                                                 }
                                                                 
                                                                 if(!((product == APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT  && productAttributeValue.APT_ECI_Merchandise_AVG_Weight_KG__c > 2)
                                                                      || (product == APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT  && productAttributeValue.APT_ECI_Merchandise_AVG_Weight_KG__c <= 2))){
                                                                          
                                                                          Decimal volume = getVolume(productAttributeValue, product);
                                                                          Decimal dispersion = getDispersion(productAttributeValue, zone, product);
                                                                          Decimal weight = getWeight(productAttributeValue, product);
                                                                          
                                                                          dbProductRevenue += calculateRevenue(volume, dispersion, perItemRate, weight, perKGRate);
                                                                      }
                                                             }            
                                                         }     
                                                     } 
                                                     catch(Exception ex) {
                                                         system.debug('Exception'+ex.getMessage());
                                                         return null;
                                                     }  
                                                     
                                                     system.debug('dbProductRevenue***--> '+dbProductRevenue);
                                                     return dbProductRevenue;
                                                 }
    
    public static double calculateProductRevenueforNewIntBundle(Double dbProductRevenue,Apttus_Config2__LineItem__c lineItem, String band, String product,set<String> setZone, 
                                                                String pricePoint, map<String, list<Apttus_Config2__PriceMatrixEntry__c>> mappmeByZone, 
                                                                Apttus_Config2__ProductAttributeValue__c productAttributeValue) {
                                                                    system.debug('dbProductRevenue*----> '+dbProductRevenue);                       
                                                                    List<Apttus_Config2__PriceMatrixEntry__c> pmeList;
                                                                    String key;                     
                                                                    for(String zone : setZone) {                     
                                                                        pmeList = new List<Apttus_Config2__PriceMatrixEntry__c>();            
                                                                        if(product == APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT){
                                                                            key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Upto2kg;
                                                                            if(mappmeByZone.get(key) != null) {  
                                                                                for(Apttus_Config2__PriceMatrixEntry__c pme : mappmeByZone.get(key)){ 
                                                                                    pmeList.add(pme);
                                                                                }                                                           
                                                                            }
                                                                        }
                                                                        else if(product == APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT){
                                                                            if(productAttributeValue.APT_International_Exp_Merch_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_0_5)){
                                                                                key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Upto500g;
                                                                            }
                                                                            else if((productAttributeValue.APT_International_Exp_Merch_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_0_5))&&
                                                                                    (productAttributeValue.APT_International_Exp_Merch_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_1))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over500gupto1kg;
                                                                                    }
                                                                            else if((productAttributeValue.APT_International_Exp_Merch_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_1))&&
                                                                                    (productAttributeValue.APT_International_Exp_Merch_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_2))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over1kgupto2kg;
                                                                                    }
                                                                            else if((productAttributeValue.APT_International_Exp_Merch_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_2))&&
                                                                                    (productAttributeValue.APT_International_Exp_Merch_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_20))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over2kgupto20kg;
                                                                                    }
                                                                            if(mappmeByZone.get(key) != null) {  
                                                                                for(Apttus_Config2__PriceMatrixEntry__c pme : mappmeByZone.get(key)){ 
                                                                                    pmeList.add(pme);
                                                                                }
                                                                            }
                                                                        }
                                                                        else if(product == APT_Constants.STANDARD_INTERNATIONAL_PRODUCT){
                                                                            if(productAttributeValue.APT_International_Standard_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_0_5)){
                                                                                key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Upto500g;
                                                                            }
                                                                            else if((productAttributeValue.APT_International_Standard_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_0_5))&&
                                                                                    (productAttributeValue.APT_International_Standard_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_1))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over500gupto1kg;
                                                                                    }
                                                                            else if((productAttributeValue.APT_International_Standard_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_1))&&
                                                                                    (productAttributeValue.APT_International_Standard_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_2))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over1kgupto2kg;
                                                                                    }
                                                                            else if((productAttributeValue.APT_International_Standard_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_2))&&
                                                                                    (productAttributeValue.APT_International_Standard_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_20))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over2kgupto20kg;
                                                                                    }
                                                                            if(mappmeByZone.get(key) != null) {  
                                                                                for(Apttus_Config2__PriceMatrixEntry__c pme : mappmeByZone.get(key)){ 
                                                                                    pmeList.add(pme);
                                                                                } 
                                                                            }
                                                                        }
                                                                        else if(product == APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT){
                                                                            if(productAttributeValue.APT_International_Std_W_Sig_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_0_5)){
                                                                                key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Upto500g;
                                                                            }
                                                                            else if((productAttributeValue.APT_International_Std_W_Sig_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_0_5))&&
                                                                                    (productAttributeValue.APT_International_Std_W_Sig_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_1))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over500gupto1kg;
                                                                                    }
                                                                            else if((productAttributeValue.APT_International_Std_W_Sig_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_1))&&
                                                                                    (productAttributeValue.APT_International_Std_W_Sig_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_2))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over1kgupto2kg;
                                                                                    }
                                                                            else if((productAttributeValue.APT_International_Std_W_Sig_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_2))&&
                                                                                    (productAttributeValue.APT_International_Std_W_Sig_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_20))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over2kgupto20kg;
                                                                                    }
                                                                            if(mappmeByZone.get(key) != null) {  
                                                                                for(Apttus_Config2__PriceMatrixEntry__c pme : mappmeByZone.get(key)){ 
                                                                                    pmeList.add(pme);
                                                                                } 
                                                                            }
                                                                        }
                                                                        else if(product == APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT){
                                                                            if(productAttributeValue.APT_International_Economy_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_0_5)){
                                                                                key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Upto500g;
                                                                            }
                                                                            else if((productAttributeValue.APT_International_Economy_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_0_5))&&
                                                                                    (productAttributeValue.APT_International_Economy_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_1))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over500gupto1kg;
                                                                                    }
                                                                            else if((productAttributeValue.APT_International_Economy_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_1))&&
                                                                                    (productAttributeValue.APT_International_Economy_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_2))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over1kgupto2kg;
                                                                                    }
                                                                            if(mappmeByZone.get(key) != null) {  
                                                                                for(Apttus_Config2__PriceMatrixEntry__c pme : mappmeByZone.get(key)){ 
                                                                                    pmeList.add(pme);
                                                                                } 
                                                                            }
                                                                        }
                                                                        else if(product == APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT){
                                                                            if(productAttributeValue.APT_International_Eco_W_Sig_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_0_5)){
                                                                                key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Upto500g;
                                                                            }
                                                                            else if((productAttributeValue.APT_International_Eco_W_Sig_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_0_5))&&
                                                                                    (productAttributeValue.APT_International_Eco_W_Sig_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_1))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over500gupto1kg;
                                                                                    }
                                                                            else if((productAttributeValue.APT_International_Eco_W_Sig_Weight_Kgs__c > Decimal.valueOf(APT_Constants.Weight_1))&&
                                                                                    (productAttributeValue.APT_International_Eco_W_Sig_Weight_Kgs__c <= Decimal.valueOf(APT_Constants.Weight_2))){
                                                                                        key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Over1kgupto2kg;
                                                                                    }
                                                                            if(mappmeByZone.get(key) != null) {  
                                                                                for(Apttus_Config2__PriceMatrixEntry__c pme : mappmeByZone.get(key)){ 
                                                                                    pmeList.add(pme);
                                                                                } 
                                                                            }
                                                                        }
                                                                        else if(product == APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS){
                                                                            key = band + APT_Constants.SEPERATOR_SIMILARITY + product + APT_Constants.SEPERATOR_SIMILARITY + zone + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.Weight_Upto500g;
                                                                            if(mappmeByZone.get(key) != null) {  
                                                                                for(Apttus_Config2__PriceMatrixEntry__c pme : mappmeByZone.get(key)){ 
                                                                                    pmeList.add(pme);
                                                                                }
                                                                            }
                                                                        }
                                                                        
                                                                        system.debug('KeyToExtractPME: ' + key);
                                                                        
                                                                        
                                                                        if(!pmeList.IsEmpty()) {  
                                                                            decimal perKGRate = 0;
                                                                            decimal perItemRate = 0;
                                                                            for(Apttus_Config2__PriceMatrixEntry__c pme : pmeList){  
                                                                                if(pme.Apttus_Config2__Dimension2Value__c == 'Per Item'){
                                                                                    perItemRate = pme.Apttus_Config2__AdjustmentAmount__c;
                                                                                }
                                                                                else if(pme.Apttus_Config2__Dimension2Value__c == 'Per Kg'){
                                                                                    perKGRate = pme.Apttus_Config2__AdjustmentAmount__c;
                                                                                }
                                                                            }
                                                                            
                                                                            Decimal volume = getVolume(productAttributeValue, product);
                                                                            Decimal dispersion = getDispersion(productAttributeValue, zone, product);
                                                                            Decimal weight = getWeight(productAttributeValue, product);
                                                                            dbProductRevenue += calculateRevenue(volume, dispersion, perItemRate, weight,  perKGRate);
                                                                        }
                                                                    }
                                                                    system.debug('dbProductRevenue**----> '+dbProductRevenue);
                                                                    return dbProductRevenue;
                                                                }
    
    private static Decimal getDispersion(Apttus_Config2__ProductAttributeValue__c productAttributeValue, String zone, String product){
        
        if(product == APT_Constants.AIRLET_INTERNATIONAL_PRODUCT || product == APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT || product == APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT
           || product == APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT || product == APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT || 
           product == APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT || product == APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT || 
           product == APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT || product == APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS){
               if(zone ==  APT_Constants.ZONE1){
                   return productAttributeValue.APT_Zone_1_Dispersion__c;
               }
               else if(zone == APT_Constants.ZONE2){
                   return productAttributeValue.APT_Zone_2_Dispersion__c;
               }
               else if(zone == APT_Constants.ZONE3){
                   return productAttributeValue.APT_Zone_3_Dispersion__c;
               }
               else if(zone == APT_Constants.ZONE4){
                   return productAttributeValue.APT_Zone_4_Dispersion__c;
               }
               else if(zone == APT_Constants.ZONE5){
                   return productAttributeValue.APT_Zone_5_Dispersion__c;
               }
               else if(zone == APT_Constants.ZONE6){
                   return productAttributeValue.APT_Zone_6_Dispersion__c;
               }
               else if(zone == APT_Constants.ZONE7){
                   return productAttributeValue.APT_Zone_7_Dispersion__c;
               }
               else if(zone == APT_Constants.ZONE8){
                   return productAttributeValue.APT_Zone_8_Dispersion__c;
               }
               else {
                   return 0;
               }
               
           }
        else if(product == APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT || product == APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT
                || product == APT_Constants.STANDARD_INTERNATIONAL_PRODUCT || product == APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT
                || product == APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT || product == APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT){
                    if(zone == APT_Constants.ZONE1){
                        return productAttributeValue.APT_Zone_1Digital_Dispersion__c;
                    }
                    else if(zone == APT_Constants.ZONE2){
                        return productAttributeValue.APT_Zone_2Digital_Dispersion__c;
                    }
                    else if(zone == APT_Constants.ZONE3){
                        return productAttributeValue.APT_Zone_3Digital_Dispersion__c;
                    }
                    else if(zone == APT_Constants.ZONE4){
                        return productAttributeValue.APT_Zone_4Digital_Dispersion__c;
                    }
                    else if(zone == APT_Constants.ZONE5){
                        return productAttributeValue.APT_Zone_5Digital_Dispersion__c;
                    }
                    else if(zone == APT_Constants.ZONE6){
                        return productAttributeValue.APT_Zone_6Digital_Dispersion__c;
                    }
                    else if(zone == APT_Constants.ZONE7){
                        return productAttributeValue.APT_Zone_7Digital_Dispersion__c;
                    }
                    else if(zone == APT_Constants.ZONE8){
                        return productAttributeValue.APT_Zone_8Digital_Dispersion__c;
                    }
                    else if(zone == APT_Constants.ZONE9){
                        return productAttributeValue.APT_Zone_9Digital_Dispersion__c;
                    }
                    else {
                        return 0;
                    }
                }
        
        return 0;
    }
    
    private static Decimal  getVolume(Apttus_Config2__ProductAttributeValue__c productAttributeValue, string product){
        if(product == APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_Int_Express_Document_Volume__c;
        }
        else if(product == APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_International_Express_Merchandise__c ;
        }
        else if(product == APT_Constants.STANDARD_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_International_Standard_Volume__c ;
        }
        else if(product == APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_International_Standard_W_Sig_Volume__c ;
        }
        else if(product == APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_International_Economy_Volume__c ;
        }
        else if(product == APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_International_Economy_W_Sig_Volume__c ;
        }
        else if(product == APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS) {
            return productAttributeValue.APT_International_Airmail_Letters_Volume__c ;
        }
        else if(product == APT_Constants.AIRLET_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_Airmail_Letters_Annual_Volume__c ;
        }
        else if(product == APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_AirmailSmallParcelsGT2kgAnnualVolume__c ;
        }
        else if(product == APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_PackNTrackInternationalAnnualVolume__c ;
        }
        else if(product == APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_RegisteredPostInternationalAnnualVol__c ;
        }
        else if(product == APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_AirmailSmallParcelsLT2kgAnnualVolume__c ;
        }
        else if(product == APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_ECI_Documents_Annual_Volume__c ;
        }
        else if(product == APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.ECI_Merchandise_Annual_Volume__c ;
        }
        else if(product == APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.ECI_Merchandise_Annual_Volume__c ;
        }
        else {
            return 0;
        }
    }
    
    private static Decimal getWeight(Apttus_Config2__ProductAttributeValue__c productAttributeValue, String product){
        if(product ==  APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_Int_Express_Doc_Weight_Kg__c;
        }
        else if(product ==  APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_International_Exp_Merch_Weight_Kgs__c ;
        }
        else if(product ==  APT_Constants.STANDARD_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_International_Standard_Weight_Kgs__c ;
        }
        else if(product ==  APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT) {
            return productAttributeValue.APT_International_Std_W_Sig_Weight_Kgs__c ;
        }
        else if(product ==  APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_International_Economy_Weight_Kgs__c ;
        }
        else if(product ==  APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_International_Eco_W_Sig_Weight_Kgs__c ;
        }
        else if(product ==  APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS ){
            return productAttributeValue.APT_International_Airmail_Let_Weight_Kgs__c ;
        }
        else if(product ==  APT_Constants.AIRLET_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_Airmail_Letters_AVG_Weight_KG__c ;
        }
        else if(product ==  APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_AirmailSmallParcelGT2kgAVGWeightKG__c ;
        }
        else if(product ==  APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_PackNTrackInternationalAVGWeightKG__c ;
        }
        else if(product ==  APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_RegisteredPostInternationalAVGWeight__c ;
        }
        else if(product ==  APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_AirmailSmallParcelLT2kgAVGWeightKG__c ;
        }
        else if(product ==  APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_ECI_Documents_AVG_Weight_KG__c ;
        }
        else if(product ==  APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_ECI_Merchandise_AVG_Weight_KG__c ;
        }
        else if(product ==  APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT ){
            return productAttributeValue.APT_ECI_Merchandise_AVG_Weight_KG__c ;
        }
        else {
            return 0;
        }
    }
    
    private static Decimal calculateRevenue(decimal volume, decimal dispersion, decimal perItemRate, decimal weight, decimal perKGRate){
        return volume * (dispersion / 100) * (perItemRate + (weight * perKGRate));       
    }

    private static Decimal calculateMinimumQuantity(Decimal minQty, Integer minValue, Integer maxValue) {
        return (minQty == null || minQty == 1 || minQty < minValue)
                ? (Decimal) minValue
                : (minQty >= maxValue ? (Decimal) maxValue : minQty);
    }
}