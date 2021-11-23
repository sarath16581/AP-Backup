/*************************************************************************************************************
* Description - Cascade Adjustments
* Created By - Mausam Padhiyar
* Created Date - 28th Oct, 2015

* Last Modified By - Mausam Padhiyar
* Last Modified Date - 21st Sept, 2016 | 1165 : Contract Pricing
* 
* Last Modified By - Mausam Padhiyar
* Last Modified Date - 26st Sept, 2016 | 1397 : PBP should have new status
********************************************/
global with sharing class APT_PricingCallBack implements Apttus_Config2.CustomClass.IPricingCallback3 {
    // cart
    private Apttus_Config2.ProductConfiguration cart = null;
        
    //mode
    private Apttus_Config2.CustomClass.PricingMode mode = null;
   
    //map<Id, Apttus_Config2__ProductAttributeValue__c> mapProductAttributeValue = new map<Id, Apttus_Config2__ProductAttributeValue__c>();
    //map<String, APT_Charge_Code__c> mapChargeCode = new map<String, APT_Charge_Code__c>();
    
    
     /**
     * Callback at the beginning of the pricing call.
     * Use the start method to initialize state
     * @param cart the cart object
     */
    //Integer i = 0;
    //list<String> listTemp = new list<String>();
    //Map<decimal, Apttus_Config2__LineItem__c> mapBundleLineItem = new Map<decimal, Apttus_Config2__LineItem__c>();
    global void start(Apttus_Config2.ProductConfiguration cart) {
        this.cart = cart;
        /*
        system.debug('*** ['+ i++ +'] ***'+ '*** start ***');
        listTemp.add('*** ['+ i++ +'] ***'+ '*** start ***');
        for(Apttus_Config2.LineItem lineItem : cart.getLineItems()) {
            Apttus_Config2__LineItem__c lineItemSO = lineItem.getLineItemSO();
            system.debug('*** ['+ i++ +'] ***' + '*** start ***'+'***  mode ***'+ mode + '*** line item id ***'+lineItemSO.Id+'*** line type ***'+ lineItemSO.Apttus_Config2__LineType__c + '*** product id ***' + lineItemSO.Apttus_Config2__ProductId__c + '*** parent number ***' +lineItemSO.Apttus_Config2__ParentBundleNumber__c + '*** primary line item ***' +lineItemSO.Apttus_Config2__PrimaryLineNumber__c + '*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c+'*** cascade adjustements ***'+lineItemSO.APT_Cascade_Adjustments__c);
            listTemp.add('*** ['+ i++ +'] ***' + '*** start ***'+'***  mode ***'+ mode + '*** line item id ***'+lineItemSO.Id+'*** line type ***'+ lineItemSO.Apttus_Config2__LineType__c + '*** product id ***' + lineItemSO.Apttus_Config2__ProductId__c + '*** parent number ***' +lineItemSO.Apttus_Config2__ParentBundleNumber__c + '*** primary line item ***' +lineItemSO.Apttus_Config2__PrimaryLineNumber__c + '*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c+'*** cascade adjustements ***'+lineItemSO.APT_Cascade_Adjustments__c);
            if(mapBundleLineItem.get(lineItemSO.Apttus_Config2__PrimaryLineNumber__c) == null) {
                mapBundleLineItem.put(lineItemSO.Apttus_Config2__PrimaryLineNumber__c, lineItemSO);
            }
        }
        */
    }
        
   /**
      * Callback to indicate the pricing mode
      * @param mode the pricing mode
      */
    global void setMode(Apttus_Config2.CustomClass.PricingMode mode) {
        this.mode = mode;
    }
    
    /**
     * onPriceItemSet
     */
    global void onPriceItemSet(Apttus_Config2__PriceListItem__c priceListItemSO, Apttus_Config2.LineItem lineItemMO) {
        /*
        Apttus_Config2__LineItem__c lineItemSO = lineItemMO.getLineItemSO();
        system.debug('*** ['+ i++ +'] ***' + '*** onPriceItemSet ***'+'***  mode ***'+ mode + '*** line item id ***'+lineItemSO.Id+'*** line type ***'+ lineItemSO.Apttus_Config2__LineType__c + '*** product id ***' + lineItemSO.Apttus_Config2__ProductId__c + '*** parent number ***' +lineItemSO.Apttus_Config2__ParentBundleNumber__c + '*** primary line item ***' +lineItemSO.Apttus_Config2__PrimaryLineNumber__c + '*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c+'*** cascade adjustements ***'+lineItemSO.APT_Cascade_Adjustments__c);
        listTemp.add('*** ['+ i++ +'] ***' + '*** onPriceItemSet ***'+'***  mode ***'+ mode + '*** line item id ***'+lineItemSO.Id+'*** line type ***'+ lineItemSO.Apttus_Config2__LineType__c + '*** product id ***' + lineItemSO.Apttus_Config2__ProductId__c + '*** parent number ***' +lineItemSO.Apttus_Config2__ParentBundleNumber__c + '*** primary line item ***' +lineItemSO.Apttus_Config2__PrimaryLineNumber__c + '*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c+'*** cascade adjustements ***'+lineItemSO.APT_Cascade_Adjustments__c);
        if(mode == Apttus_Config2.CustomClass.PricingMode.BASEPRICE && lineItemSO.APT_Cascade_Adjustments__c) {
            Apttus_Config2__LineItem__c bundleLineItem = mapBundleLineItem.get(lineItemSO.Apttus_Config2__ParentBundleNumber__c);
            if(bundleLineItem != null) {
                //adjustment type and adjustment amount
                if(bundleLineItem.Apttus_Config2__AdjustmentAmount__c != null && !String.isEmpty(bundleLineItem.Apttus_Config2__AdjustmentType__c)) {
                    //apply discount
                    lineItemSO.Apttus_Config2__AdjustmentAmount__c = bundleLineItem.Apttus_Config2__AdjustmentAmount__c;
                    lineItemSO.Apttus_Config2__AdjustmentType__c = bundleLineItem.Apttus_Config2__AdjustmentType__c;
                    system.debug('*** ['+ i++ +'] ***'+  '*** onPriceItemSet ***'+'***  mode ***'+ mode + '*** apply adjustments ***' + '*** line item id ***'+lineItemSO.Id+'*** line type ***'+ lineItemSO.Apttus_Config2__LineType__c);
                    listTemp.add('*** ['+ i++ +'] ***'+  '*** onPriceItemSet ***'+'***  mode ***'+ mode + '*** apply adjustments ***' + '*** line item id ***'+lineItemSO.Id+'*** line type ***'+ lineItemSO.Apttus_Config2__LineType__c);
                }
                else if(bundleLineItem.Apttus_Config2__AdjustmentAmount__c == null && String.isBlank(bundleLineItem.Apttus_Config2__AdjustmentType__c) && lineItemSO.Apttus_Config2__AdjustmentAmount__c != null && String.isNotBlank(lineItemSO.Apttus_Config2__AdjustmentType__c)) {
                    //remove discount
                    lineItemSO.Apttus_Config2__AdjustmentAmount__c = bundleLineItem.Apttus_Config2__AdjustmentAmount__c;
                    lineItemSO.Apttus_Config2__AdjustmentType__c = bundleLineItem.Apttus_Config2__AdjustmentType__c;
                    system.debug('*** ['+ i++ +'] ***'+  '*** onPriceItemSet ***'+'***  mode ***'+ mode + '*** remove adjustments ***' + '*** line item id ***'+lineItemSO.Id+'*** line type ***'+ lineItemSO.Apttus_Config2__LineType__c);
                    listTemp.add('*** ['+ i++ +'] ***'+  '*** onPriceItemSet ***'+'***  mode ***'+ mode + '*** remove adjustments ***' + '*** line item id ***'+lineItemSO.Id+'*** line type ***'+ lineItemSO.Apttus_Config2__LineType__c);
                } else {}
            }
        }
        */
    }
    
     /**
     * Callback before pricing the line item collection
     * Use this method to do all required pre-processing to prepare the line items for pricing.
     * @param itemColl the line item collection to pre-process
     */  
    global void beforePricing(Apttus_Config2.ProductConfiguration.LineItemColl itemColl) {
        /*
        for(Apttus_Config2.LineItem lineItem : itemColl.getAllLineItems()) {
            Apttus_Config2__LineItem__c lineItemSO = lineItem.getLineItemSO();
            system.debug('*** beforePricing Method Iterating itemColl ***' + '*** mode ***'+ mode + '*** lineItem id: ' +lineItemSO.Id + 'line type: ' + lineItemSO.Apttus_Config2__LineType__c + '*** product id ***'+lineItemSO.Apttus_Config2__ProductId__c +'*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c);
            listTemp.add('['+ i++ +']*** beforePricing Method Iterating itemColl ***' + '*** mode ***'+ mode + '*** lineItem id: ' +lineItemSO.Id + 'line type: ' + lineItemSO.Apttus_Config2__LineType__c + '*** product id ***'+lineItemSO.Apttus_Config2__ProductId__c +'*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c);
        }
        */
        
        
         if(mode == Apttus_Config2.CustomClass.PricingMode.BASEPRICE){
            map<Id, Apttus_Config2__LineItem__c> mapLineItem = new map<Id, Apttus_Config2__LineItem__c>();
            map<Id, Apttus_Config2__LineItem__c> mapBundleLineItem = new map<Id, Apttus_Config2__LineItem__c>();
                
            for(Apttus_Config2.LineItem lineItem : itemColl.getAllLineItems()) {
                Apttus_Config2__LineItem__c lineItemSO = lineItem.getLineItemSO();
                mapLineItem.put(lineItemSO.ID, lineItemSO);
                if(String.isBlank(lineItemSO.Apttus_Config2__OptionId__c) && lineItemSO.Apttus_Config2__IsPrimaryLine__c){
                    mapBundleLineItem.put(lineItemSO.Apttus_Config2__ProductId__c,lineItemSO);
                }
                
                System.Debug('lineItemSO.APT_New__c__'+lineItemSO.APT_New__c);
                System.Debug('lineItemSO.APT_Amendment__c__'+lineItemSO.APT_Amendment__c);
                System.Debug('lineItemSO.Apttus_Config2__PricingStatus__c__'+lineItemSO.Apttus_Config2__PricingStatus__c);
                System.Debug('lineItemSO.APT_Product_Name__c__'+lineItemSO.APT_Product_Name__c);
                System.Debug('lineItemSO.Apttus_Config2__LineType__c__'+lineItemSO.Apttus_Config2__LineType__c);
                System.Debug('lineItemSO.Apttus_Config2__IsOptionRollupLine__c__'+lineItemSO.Apttus_Config2__IsOptionRollupLine__c);
                System.Debug('lineItemSO.Apttus_Config2__IsPrimaryLine__c__'+lineItemSO.Apttus_Config2__IsPrimaryLine__c);
                
                //1165
                if(!lineItemSO.APT_New__c && !lineItemSO.APT_Amendment__c && String.isNotBlank(lineItemSO.Apttus_Config2__PricingStatus__c) && lineItemSO.Apttus_Config2__PricingStatus__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_STATUS)) {
                    lineItemSO.APT_New__c = true;
                    System.Debug('IN 1165');

                }
                
                if(lineItemSO.APT_Amendment__c && null != lineItemSO.Apttus_Config2__PricingStatus__c && String.isNotBlank(lineItemSO.Apttus_Config2__PricingStatus__c) && lineItemSO.Apttus_Config2__PricingStatus__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_STATUS)) {
                    //1397
                    if(null != lineItemSO.APT_Product_Name__c && String.isNotBlank(lineItemSO.APT_Product_Name__c) && lineItemSO.APT_Product_Name__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_POST_BILLPAY)
                        && lineItemSO.Apttus_Config2__IsPrimaryLine__c && !lineItemSO.Apttus_Config2__IsOptionRollupLine__c
                        && null != lineItemSO.Apttus_Config2__LineType__c && String.isNotBlank(lineItemSO.Apttus_Config2__LineType__c) &&  lineItemSO.Apttus_Config2__LineType__c.equalsIgnoreCase(APT_Constants.LINE_TYPE_PRODUCT_SERVICE)) {
                        lineItemSO.APT_Amendment__c = true;    
                        System.Debug('IN 1397 IF');
                    } else {
                        lineItemSO.APT_Amendment__c = false;
                        System.Debug('IN 1397 ELSE');
                    }
                    //1397
                    
                }
                //1165
            }
            
            Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c();
            Apttus_Config2__LineItem__c bundleProductLineItem = new Apttus_Config2__LineItem__c();
            List<Apttus_Config2__ProductAttributeValue__c> pavList = new List<Apttus_Config2__ProductAttributeValue__c>();
            Apttus_Config2__ProductAttributeValue__c attributeValueObj = new Apttus_Config2__ProductAttributeValue__c();
            String bandOrginalValue ;
            String currentBandValue ;
            
            for(Apttus_Config2.LineItem lineItemMO : itemColl.getAllLineItems()) {
                lineItem = lineItemMO.getLineItemSO();
               
                if(lineItem.APT_Cascade_Adjustments__c && null != lineItem.Apttus_Config2__OptionId__c &&String.isNotBlank(lineItem.Apttus_Config2__OptionId__c)){
                    bundleProductLineItem = mapBundleLineItem.get(lineItem.Apttus_Config2__ProductId__c);
                    if(bundleProductLineItem != null) {
                        //rate card key
                        if(null != bundleProductLineItem.APT_Rate_Card_Key__c && String.isNotBlank(bundleProductLineItem.APT_Rate_Card_Key__c)){
                            lineItem.APT_Rate_Card_Key__c = bundleProductLineItem.APT_Rate_Card_Key__c;//APOST-1301
                        } else if(String.isBlank(bundleProductLineItem.APT_Rate_Card_Key__c) && null != lineItem.APT_Rate_Card_Key__c && String.isNotBlank(lineItem.APT_Rate_Card_Key__c)) {
                            lineItem.APT_Rate_Card_Key__c = bundleProductLineItem.APT_Rate_Card_Key__c;//APOST-1301
                        } else {}
                        
                        //adjustment type and adjustment amount
                         if((bundleProductLineItem.Apttus_Config2__AdjustmentAmount__c != null && !String.isEmpty(bundleProductLineItem.Apttus_Config2__AdjustmentType__c)) || 
                                              bundleProductLineItem.Apttus_Config2__AdjustmentType__c == APT_Constants.OFFER_HIGHER_BAND) {
                            //apply discount
                            lineItem.Apttus_Config2__AdjustmentAmount__c = bundleProductLineItem.Apttus_Config2__AdjustmentAmount__c;
                            lineItem.Apttus_Config2__AdjustmentType__c = bundleProductLineItem.Apttus_Config2__AdjustmentType__c;
                        }
                        else if(bundleProductLineItem.Apttus_Config2__AdjustmentAmount__c == null && String.isBlank(bundleProductLineItem.Apttus_Config2__AdjustmentType__c) && ((lineItem.Apttus_Config2__AdjustmentAmount__c != null && String.isNotBlank(lineItem.Apttus_Config2__AdjustmentType__c)) ||
                                        lineItem.Apttus_Config2__AdjustmentType__c == APT_Constants.OFFER_HIGHER_BAND)) {
                            //remove discount
                            lineItem.Apttus_Config2__AdjustmentAmount__c = bundleProductLineItem.Apttus_Config2__AdjustmentAmount__c;
                            lineItem.Apttus_Config2__AdjustmentType__c = bundleProductLineItem.Apttus_Config2__AdjustmentType__c;
                        } else {}
                    }                  
                }
                
                //Code Added for International CO -By Akansha
                 //Offer Higher Band Code Start
                 if(( null != lineItem.Apttus_Config2__ProductId__r.ProductCode && String.isNotBlank(lineItem.Apttus_Config2__ProductId__r.ProductCode) && (lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)||
                 lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE)||lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL))) && (lineItem.Apttus_Config2__IsPrimaryLine__c)){
                     if(lineItem.Apttus_Config2__LineType__c!= null && lineItem.Apttus_Config2__LineType__c.equalsIgnoreCase(APT_Constants.LINE_TYPE_PRODUCT_SERVICE)){
                         if(null != lineItem.APT_Band__c && String.isNotBlank(lineItem.APT_Band__c)){
                             currentBandValue = lineItem.APT_Band__c;
                             bandOrginalValue = lineItem.Apttus_Config2__AttributeValueId__r.APT_Band_Original_Value__c;
                             if(lineItem.Apttus_Config2__AdjustmentType__c!= null && lineItem.Apttus_Config2__AdjustmentType__c.equalsIgnoreCase(APT_Constants.OFFER_HIGHER_BAND)){
                                 if(string.isNotBlank(currentBandValue) && string.isNotBlank(bandOrginalValue)){
                                     if((currentBandValue!= APT_Constants.BAND_5) && (currentBandValue.equalsIgnoreCase(bandOrginalValue))){
                                           attributeValueObj.Id = lineItem.Apttus_Config2__AttributeValueId__c;
                                           if(bandOrginalValue.equalsIgnoreCase(APT_Constants.BAND_1)){
                                               lineItem.Apttus_Config2__AttributeValueId__r.APT_Band__c = APT_Constants.BAND_2;
                                                attributeValueObj.APT_Band__c = APT_Constants.BAND_2;
                                           }if(bandOrginalValue.equalsIgnoreCase(APT_Constants.BAND_2)){
                                                lineItem.Apttus_Config2__AttributeValueId__r.APT_Band__c = APT_Constants.BAND_3;
                                                attributeValueObj.APT_Band__c = APT_Constants.BAND_3;
                                           }if(bandOrginalValue.equalsIgnoreCase(APT_Constants.BAND_3)){
                                                lineItem.Apttus_Config2__AttributeValueId__r.APT_Band__c = APT_Constants.BAND_4;
                                                attributeValueObj.APT_Band__c = APT_Constants.BAND_4;
                                           }if(bandOrginalValue.equalsIgnoreCase(APT_Constants.BAND_4)){
                                                lineItem.Apttus_Config2__AttributeValueId__r.APT_Band__c = APT_Constants.BAND_5;
                                                attributeValueObj.APT_Band__c = APT_Constants.BAND_5;
                                           }
                                           pavList.add(attributeValueObj);
                                           lineItem.APT_Is_Higher_Band_Offered__c = APT_Constants.BOOL_TRUE;
                                     }
                                 }
                             }
                             else{
                                 if(!currentBandValue.equalsIgnoreCase(bandOrginalValue)){
                                     attributeValueObj.Id = lineItem.Apttus_Config2__AttributeValueId__c;
                                     attributeValueObj.APT_Band__c = bandOrginalValue;
                                     pavList.add(attributeValueObj);
                                     lineItem.Apttus_Config2__AttributeValueId__r.APT_Band__c = bandOrginalValue;
                                     lineItem.APT_Is_Higher_Band_Offered__c = APT_Constants.BOOL_FALSE;
                                 }
                             }
                         }
                     }
                 }
            }
            if(pavList != NULL && !pavList.isEmpty()){
                    system.debug('Saving PAV List'+pavList.Size());
                    update pavList;
            }
        }
        /* Added By  Mansi Shah */
        OverWrite_LPD_NetPrice(itemColl);
        
    }
      
      /**
     * Callback before pricing the line item collection
     * Use this method to do all required pre-processing to prepare the line items for pricing.
     * @param itemColl the line item collection to pre-process
     */  
    global void beforePricingLineItem(Apttus_Config2.ProductConfiguration.LineItemColl itemColl, 
                                                  Apttus_Config2.LineItem lineItemMO) {
        /*
        Apttus_Config2__LineItem__c line= lineItemMO.getLineItemSO();
        system.debug('*** beforePricingLineItem Method lineItemMO ***' + '*** mode ***'+ mode + '*** lineItem id: ' +line.Id + 'line type: ' + line.Apttus_Config2__LineType__c + '*** product id ***'+line.Apttus_Config2__ProductId__c +'*** option id ***'+line.Apttus_Config2__OptionId__c);
        listTemp.add('['+ i++ +']*** beforePricingLineItem Method lineItemMO ***' + '*** mode ***'+ mode + '*** lineItem id: ' +line.Id + 'line type: ' + line.Apttus_Config2__LineType__c + '*** product id ***'+line.Apttus_Config2__ProductId__c +'*** option id ***'+line.Apttus_Config2__OptionId__c);
        for(Apttus_Config2.LineItem lineItem : itemColl.getAllLineItems()) 
        */
    }
                                                  
                                                  
    /**
     * Callback after pricing the line item collection
     * Use this method to do all required post-processing after line items are priced.
     * @param itemColl the line item collection to post-process
     */
    global void afterPricing(Apttus_Config2.ProductConfiguration.LineItemColl itemColl) {
        /*
        for(Apttus_Config2.LineItem lineItem : itemColl.getAllLineItems()) {
            Apttus_Config2__LineItem__c lineItemSO = lineItem.getLineItemSO();
            system.debug('*** afterPricing Method Iterating itemColl ***' + '*** mode ***'+ mode + '*** lineItem id: ' +lineItemSO.Id + 'line type: ' + lineItemSO.Apttus_Config2__LineType__c + '*** product id ***'+lineItemSO.Apttus_Config2__ProductId__c +'*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c);
            listTemp.add('['+ i++ +']*** afterPricing Method Iterating itemColl ***' + '*** mode ***'+ mode + '*** lineItem id: ' +lineItemSO.Id + 'line type: ' + lineItemSO.Apttus_Config2__LineType__c + '*** product id ***'+lineItemSO.Apttus_Config2__ProductId__c +'*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c);
        }
        */
    }
     /**
     * Callback after pricing the line item collection
     * Use this method to do all required post-processing after line items are priced.
     * @param itemColl the line item collection to post-process
     */   
    global void afterPricingLineItem(Apttus_Config2.ProductConfiguration.LineItemColl itemColl, 
                                                  Apttus_Config2.LineItem lineItemMO) {
      /*   Apttus_Config2__LineItem__c line= lineItemMO.getLineItemSO();
        system.debug('line---------->'+line.Id);
        if(line.Apttus_Config2__PrimaryLineNumber__c == 1  && line.Apttus_Config2__IsPrimaryLine__c == true && line.APT_Rate_Card_Key__c != null){
        system.debug('lineID---------->'+line.Id);
        Apttus_Config2__LineItem__c rateCardLineItem = [SELECT Id, Apttus_Config2__AttributeValueId__c, Apttus_Config2__AttributeValueId__r.Category__c,
                                    Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,
                                    Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone_Code__c
                                    FROM Apttus_Config2__LineItem__c
                                    WHERE Apttus_Config2__ConfigurationId__c = :line.Apttus_Config2__ConfigurationId__c
                                    AND Apttus_Config2__ParentBundleNumber__c = :line.Apttus_Config2__PrimaryLineNumber__c
                                    AND Apttus_Config2__OptionId__r.APT_Category__c != null
                                    AND Apttus_Config2__OptionId__r.APT_Network_Type__c != null
                                    limit 1];
        
        list<Apttus_Config2__UsagePriceTier__c> listExistingUPT = [SELECT Id
                                                                        FROM Apttus_Config2__UsagePriceTier__c
                                                                        WHERE Apttus_Config2__LineItemId__c =: rateCardLineItem.Id ];
                                                                        
        list<Apttus_Config2__UsagePriceTier__c> listtoUpdateUPT = new list<Apttus_Config2__UsagePriceTier__c>();
        Apttus_Config2__UsagePriceTier__c VtoUpdateUPT = new Apttus_Config2__UsagePriceTier__c();
        list<APT_Usage_Price_Tier_Copy__c> listDupUsagePriceTier = [SELECT Id,APT_Sequence__c,APT_Lineitem_Id_Copy__c
                                                                        FROM APT_Usage_Price_Tier_Copy__c
                                                                        WHERE APT_Lineitem_Id_Copy__c=: rateCardLineItem.Id ];
        for(APT_Usage_Price_Tier_Copy__c upt: listDupUsagePriceTier){
                             VtoUpdateUPT = new Apttus_Config2__UsagePriceTier__c();
                             VtoUpdateUPT.Apttus_Config2__Sequence__c = upt.APT_Sequence__c;
                             VtoUpdateUPT.Apttus_Config2__LineItemId__c = upt.APT_Lineitem_Id_Copy__c;
                             listtoUpdateUPT.add(VtoUpdateUPT);
                                    
        }                                                                
        //Delete listExistingUPT;
        Insert listtoUpdateUPT;
       // Delete listExistingUPT;
        //list<APT_Usage_Price_Tier_Copy__c> listDupUsagePriceTier = new list<APT_Usage_Price_Tier_Copy__c>();
        
        }*/
        /*
        Apttus_Config2__LineItem__c line= lineItemMO.getLineItemSO();
        system.debug('*** afterPricingLineItem Method lineItemMO ***' + '*** mode ***'+ mode + '*** lineItem id: ' +line.Id + 'line type: ' + line.Apttus_Config2__LineType__c + '*** product id ***'+line.Apttus_Config2__ProductId__c +'*** option id ***'+line.Apttus_Config2__OptionId__c);
        listTemp.add('['+ i++ +']*** afterPricingLineItem Method lineItemMO ***' + '*** mode ***'+ mode + '*** lineItem id: ' +line.Id + 'line type: ' + line.Apttus_Config2__LineType__c + '*** product id ***'+line.Apttus_Config2__ProductId__c +'*** option id ***'+line.Apttus_Config2__OptionId__c);
        for(Apttus_Config2.LineItem lineItem : itemColl.getAllLineItems()) {
            Apttus_Config2__LineItem__c lineItemSO = lineItem.getLineItemSO();
            system.debug('*** afterPricingLineItem Method Iterating itemColl ***' + '*** mode ***'+ mode + '*** lineItem id: ' +lineItemSO.Id + 'line type: ' + lineItemSO.Apttus_Config2__LineType__c + '*** product id ***'+lineItemSO.Apttus_Config2__ProductId__c +'*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c);
            listTemp.add('['+ i++ +']*** afterPricingLineItem Method Iterating itemColl ***' + '*** mode ***'+ mode + '*** lineItem id: ' +lineItemSO.Id + 'line type: ' + lineItemSO.Apttus_Config2__LineType__c + '*** product id ***'+lineItemSO.Apttus_Config2__ProductId__c +'*** option id ***'+lineItemSO.Apttus_Config2__OptionId__c);
        }
        */
    }
    
     /**
     * Callback after all batches of line items are processed
    */
    global void finish() {
        /*
        system.debug('['+ i++ +']*** Finish Method ***' + '*** mode:'+ mode );
        listTemp.add('['+ i++ +']*** Finish Method ***' + '*** mode:'+ mode );
        List<Apttus_Config2__TempObject__c> lstTempObj = new List<Apttus_Config2__TempObject__c> ();
        if (listTemp.Size() > 0){
        
            for(String s: listTemp){
                Apttus_Config2__TempObject__c tmp = new Apttus_Config2__TempObject__c();
                tmp.Apttus_Config2__Data__c = s;
                lstTempObj.add(tmp);
            }
        }
        
        insert lstTempObj; 
        system.debug('*** finish completed***' + '*** lstTempObj ***'+lstTempObj);
        */
    }  
    
    /*
        Created By: Mansi Shah
        Created Date : 29th May 2021
        Description :  This method will overwrite Apttus's Net Price field with custom calculation value for "Local Pickup and Delivery Services" product only
    */
     public static void OverWrite_LPD_NetPrice(Apttus_Config2.ProductConfiguration.LineItemColl itemColl)
    {
       try{
            for(Apttus_Config2.LineItem lineItem : itemColl.getAllLineItems())
            {    
                Apttus_Config2__LineItem__c oLineItem = lineItem.getLineItemSO();
                if(oLineItem.Apttus_Config2__ProductId__r.Name.equalsIgnoreCase(APT_Constants.PRODUCT_NAME_LOCAL_PICKUP_DELIVERY) &&
                   oLineItem.Apttus_Config2__AttributeValueId__r.APT_LPD_Total_Service_Fee__c != null &&
                   oLineItem.Apttus_Config2__BasePriceOverride__c != oLineItem.Apttus_Config2__AttributeValueId__r.APT_LPD_Total_Service_Fee__c &&
                   oLineItem.Apttus_Config2__AdjustmentType__c != APT_Constants.ADJUSTMENT_TYPE_PRICE_OVERRIDE)
                {
                    oLineItem.Apttus_Config2__BasePriceOverride__c = oLineItem.Apttus_Config2__AttributeValueId__r.APT_LPD_Total_Service_Fee__c;  
                }
            }
        }
        Catch(Exception e){
            System.debug('Error occured '+e.getMessage()+ e.getLineNumber()+e.getStackTraceString());
        }
    }
 }