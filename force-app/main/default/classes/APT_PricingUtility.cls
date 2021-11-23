/**
Description - This class is utility class for pricing which provided methods.
Created By - Mausam Padhiyar
Created Date - 29th Sept, 2015
Last Modified By - Mahesh Patel
Last Modified Date - 20th Oct, 2020
Change Description - Added startrack product's PLI/PM/PME creation logic 
 */
public with sharing class APT_PricingUtility {
    
    /**
        This method will delete price list item for international products.
        @params -
        setProductId - set of product ids        
     */
    //public static void deletePriceListItems(list<String> setProductId) {
    //    delete [SELECT Id FROM Apttus_Config2__PriceListItem__c WHERE Apttus_Config2__ProductId__c IN :setProductId];
    //}
    
    /**
        This method will delete price matrix for international products.
        @params -
        setProductId - set of product ids        
     */
    //public static void deletePriceMatrix(list<String> setProductId) {
    //    delete [SELECT Id FROM Apttus_Config2__PriceMatrix__c 
    //            WHERE Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c IN :setProductId];
    //}
    
    /**
        This method will delete price matrix entry for international products.
        @params -
        setProductId - set of product ids        
     */ /*
    public static void deletePriceMatrixEntries(list<String> setProductId) {
        delete [SELECT Id FROM Apttus_Config2__PriceMatrixEntry__c 
                WHERE Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c IN :setProductId];
    }    
    */
    /**
        This method will create Price List Item records for International Products.
        @params -
        setProduct - set of product codes
        setIndustry - set of industry
        setBand - set of band
        seteParcelLodgment - set of eParcelLodgment i.e. eParcel rates(true) or CSP rates(false)
        defaultPriceListID - default price list item id
        mapProduct - get product using product code
     */
    public static list<Apttus_Config2__PriceListItem__c> createPriceListItemForInternational(set<String> setProduct,                                                        
                                                        set<String> setBand,
                                                        set<String> seteParcelLodgment,
                                                        String defaultPriceListID,
                                                        map<String, String> mapProduct,
                                                        map<String, list<String>> mapChargeType,
                                                        map<String, Apttus_Config2__PriceListItem__c> mapExistingPLI) {
        
        list<Apttus_Config2__PriceListItem__c> listPriceListItem = new list<Apttus_Config2__PriceListItem__c>();
        list<String> listChargeType = new list<String>();
        Apttus_Config2__PriceListItem__c pli;
        for(String prod : setProduct) {
            //reset
            listChargeType.clear();
            // set charge type   
            system.debug('mapChargeType----->'+mapChargeType); 
            if(prod == APT_Constants.AIRLET_INTERNATIONAL_PRODUCT) {
                listChargeType = mapChargeType.get(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT);
            } else if(prod == APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT){
                listChargeType = mapChargeType.get(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT);
            } else if(prod == APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT){
                listChargeType = mapChargeType.get(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT);
            } else if(prod == APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT) {
                listChargeType = mapChargeType.get(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT);
            } else if(prod == APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT) {
                listChargeType = mapChargeType.get(APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT);
            } 
             else if(prod == APT_Constants.PRODUCT_InternationalExpressDocuments) {
                 listChargeType = mapChargeType.get(APT_Constants.PRODUCT_InternationalExpressDocuments);
             } else if(prod == APT_Constants.PRODUCT_InternationalExpressMerchandise) {
                 listChargeType = mapChargeType.get(APT_Constants.PRODUCT_InternationalExpressMerchandise);
             } else if(prod == APT_Constants.PRODUCT_InternationalStandard) {
                 listChargeType = mapChargeType.get(APT_Constants.PRODUCT_InternationalStandard);
             } else if(prod == APT_Constants.PRODUCT_InternationalEconomy) {
                 listChargeType = mapChargeType.get(APT_Constants.PRODUCT_InternationalEconomy);
          }
          
          else if(prod == APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERNATIONALSTANDARD) {
                 listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERNATIONALSTANDARD);
          }
          
           else if(prod == APT_Constants.PRODUCT_AIRMAILLETTER) {
                 listChargeType = mapChargeType.get(APT_Constants.PRODUCT_AIRMAILLETTER);
          }
          
            else if(prod == APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERTIONALEXPRESS) {
                 listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERTIONALEXPRESS);
          }
          
            else if(prod == APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE) {
                 listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE);
          }
          
            else if(prod == APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE) {
                 listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE);
          }
          
          //else if(prod == APT_Constants.PRODUCT_EXTRACOVER) {
            //     listChargeType = mapChargeType.get(APT_Constants.PRODUCT_EXTRACOVER);
            // } else if(prod == APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE) {
            //     listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE);
            // } else if(prod == APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERTIONALEXPRESS) {
            //     listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERTIONALEXPRESS);
            // } else if(prod == APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERNATIONALSTANDARD) {
            //     listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERNATIONALSTANDARD);
            // } else if(prod == APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE) {
            //     listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE);
            // } else if(prod == APT_Constants.PRODUCT_INTERNATIONALDIGITALPCMSBUNDLE) {
            //     listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALDIGITALPCMSBUNDLE);
            // } 
             
            
            
            // // code was added by HA
            //     else if(prod == APT_Constants.PRODUCT_INTERNATIONALDIGITALPCMSBUNDLE) {
            //     listChargeType = mapChargeType.get(APT_Constants.PRODUCT_INTERNATIONALDIGITALPCMSBUNDLE);
            // }
            
            
            else {
                listChargeType.add(APT_Constants.CHARGE_TYPE_STANDARD_PRICE);
            }            
            
            pli = new Apttus_Config2__PriceListItem__c();
            Apttus_Config2__PriceListItem__c existingPLI;
            for(String band : setBand) {
                for(String eParcelLodgment : seteParcelLodgment) {                        
                    for(String chargeType : listChargeType) {
                        system.debug('listChargeType+++++'+listChargeType);
                        // added by HA
                        eParcelLodgment='false';
                        String key = prod + APT_Constants.SEPERATOR_SIMILARITY + band + APT_Constants.SEPERATOR_SIMILARITY + eParcelLodgment;
                        system.debug('*** key2 ***'+key.toLowerCase());
                        existingPLI = mapExistingPLI.get(key.toLowerCase());
                        system.debug('*** existing pli ***'+existingPLI);
                        if(existingPLI == null) {
                            system.debug('*** new pli ***');
                            pli = new Apttus_Config2__PriceListItem__c();
                            pli.Apttus_Config2__ProductId__c = mapProduct.get(prod);
                            //pli.Apttus_Config2__ProductId__c = productId;
                            pli.Apttus_Config2__PriceListId__c = defaultPriceListID;
                            pli.Apttus_Config2__ListPrice__c = APT_Constants.INTEGER_ZERO;
                            
                            pli.Apttus_Config2__ChargeType__c =  chargeType;
                            pli.Apttus_Config2__PriceType__c = APT_Constants.PRICE_TYPE_USAGE;
                            pli.Apttus_Config2__PriceMethod__c = APT_Constants.PRICE_METHOD_PER_UNIT;
                            pli.Apttus_Config2__PriceUom__c = APT_Constants.PRICE_UOM_EACH;
                            
                            pli.Apttus_Config2__Active__c = APT_Constants.BOOL_TRUE;
                            
                            pli.Apttus_Config2__Criteria__c = generateJSONStringForInternational(band, eParcelLodgment);
                            
                            //pli.APT_Industry__c = industry;
                            pli.APT_Band__c = band;
                          //  pli.APT_eParcel_Lodgment__c = boolean.valueOf(eParcelLodgment);
                            pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_TRUE;
                            //APOST-1521
                            pli.Apttus_Config2__AllowManualAdjustment__c = false;
                            //APOST-1521
                            
                            listPriceListItem.add(pli);
                        }
                    }
                }
            }
        }
        
        return listPriceListItem;
    }
    
    /**
        This method will generate JSON string being used in charge type criteria.
        Industry, Band and eParcelLodgment is used as Charge Type Criteria
        @params -
        industry - name of industry
        band - name of band
        eParcelLodgment - eParcel rates(true) or CSP rates(false)
     */
    /*
    public static String generateJSONStringForInternational(String industry, 
                                                            String band, 
                                                            String eParcelLodgment) {
        
        JSONGenerator jGenerator = JSON.createGenerator(APT_Constants.BOOL_TRUE);
        jGenerator.writeStartObject();
        jGenerator.writeStringField(APT_Constants.SOBJECT_NAME, APT_Constants.LINE_ITEM_SOBJECT_API_NAME);
        jGenerator.writeStringField(APT_Constants.SOBJECT_LABEL, APT_Constants.LINE_ITEM);
        jGenerator.writeNullField(APT_Constants.SEARCH_TEXT);
        
        jGenerator.writeFieldName(APT_Constants.FILTER);
        jGenerator.writeStartObject();
            jGenerator.writeFieldName(APT_Constants.PREDICATES);
            jGenerator.writeStartArray();
            jGenerator.writeEndArray();
            jGenerator.writeNullField(APT_Constants.COND_EXPR_STR);
            jGenerator.writeFieldName(APT_Constants.CHILD_FILTER);
                jGenerator.writeStartObject();
                jGenerator.writeStringField(APT_Constants.RELATION_FIELD_NAME, APT_Constants.LINE_ITEM_ID_API_NAME);
                jGenerator.writeFieldName(APT_Constants.PREDICATES);
                jGenerator.writeStartArray();
                    jGenerator.writeStartObject();
                    jGenerator.writeNumberField(APT_Constants.ROW_NUM, APT_Constants.INTEGER_ONE);
                    jGenerator.writeNullField(APT_Constants.RHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_TYPE);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_LABEL);
                    jGenerator.writeNullField(APT_Constants.RHS_CHILD_FILTER_NAME);
                    jGenerator.writeNullField(APT_Constants.REF_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.OFF_SET_VALUE);
                    jGenerator.writeNullField(APT_Constants.LHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.LHS_CHILD_FILTER_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_VALUE, industry);
                    jGenerator.writeStringField(APT_Constants.FIELD_TYPE, APT_Constants.FIELD_TYPE_PICKLIST);
                    jGenerator.writeStringField(APT_Constants.FIELD_NAME, APT_Constants.INDUSTRY_API_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_LABEL, APT_Constants.INDUSTRY);
                    jGenerator.writeStringField(APT_Constants.COMP_OPER, APT_Constants.OPERATOR_EQUAL_TO);
                    jGenerator.writeStringField(APT_Constants.BOOL_OPER, APT_Constants.OPERATOR_AND);
                    jGenerator.writeEndObject(); 
                    
                    jGenerator.writeStartObject();
                    jGenerator.writeNumberField(APT_Constants.ROW_NUM, APT_Constants.INTEGER_TWO);
                    jGenerator.writeNullField(APT_Constants.RHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_TYPE);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_LABEL);
                    jGenerator.writeNullField(APT_Constants.RHS_CHILD_FILTER_NAME);
                    jGenerator.writeNullField(APT_Constants.REF_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.OFF_SET_VALUE);
                    jGenerator.writeNullField(APT_Constants.LHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.LHS_CHILD_FILTER_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_VALUE, band);
                    jGenerator.writeStringField(APT_Constants.FIELD_TYPE, APT_Constants.FIELD_TYPE_PICKLIST);
                    jGenerator.writeStringField(APT_Constants.FIELD_NAME, APT_Constants.BAND_API_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_LABEL, APT_Constants.BAND);
                    jGenerator.writeStringField(APT_Constants.COMP_OPER, APT_Constants.OPERATOR_EQUAL_TO);
                    jGenerator.writeStringField(APT_Constants.BOOL_OPER, APT_Constants.OPERATOR_AND);
                    jGenerator.writeEndObject(); 
                    
                    jGenerator.writeStartObject();
                    jGenerator.writeNumberField(APT_Constants.ROW_NUM, APT_Constants.INTEGER_THREE);
                    jGenerator.writeNullField(APT_Constants.RHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_TYPE);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_LABEL);
                    jGenerator.writeNullField(APT_Constants.RHS_CHILD_FILTER_NAME);
                    jGenerator.writeNullField(APT_Constants.REF_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.OFF_SET_VALUE);
                    jGenerator.writeNullField(APT_Constants.LHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.LHS_CHILD_FILTER_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_VALUE, eParcelLodgment);
                    jGenerator.writeStringField(APT_Constants.FIELD_TYPE, APT_Constants.FIELD_TYPE_BOOLEAN);
                    jGenerator.writeStringField(APT_Constants.FIELD_NAME, APT_Constants.EPARCEL_LODGEMENT_API_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_LABEL, APT_Constants.EPARCEL_LODGEMENT);
                    jGenerator.writeStringField(APT_Constants.COMP_OPER, APT_Constants.OPERATOR_EQUAL_TO);
                    jGenerator.writeNullField(APT_Constants.BOOL_OPER);
                    jGenerator.writeEndObject();                    
                jGenerator.writeEndArray();
                
                jGenerator.writeStringField(APT_Constants.COND_EXPR_STR, APT_Constants.ONE +  APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND + APT_Constants.SEPERATOR_SPACE +
                                                                            APT_Constants.TWO + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND + APT_Constants.SEPERATOR_SPACE + 
                                                                            APT_Constants.THREE);
                jGenerator.writeStringField(APT_Constants.CHILD_SOBJECT_NAME, APT_Constants.OBJECT_API_NAME_PRODUCT_ATTRIBUTE_VALUE);
                jGenerator.writeStringField(APT_Constants.CHILD_SOBJECT_LABEL, APT_Constants.OBJECT_LABEL_PRODUCT_ATTRIBUTE_VALUE);
                jGenerator.writeEndObject();       
        
        jGenerator.writeEndObject();
        
        jGenerator.writeFieldName(APT_Constants.FIELDS);
        jGenerator.writeStartArray();
        jGenerator.writeString(APT_Constants.ATTRIBUTE_INDUSTRY_API_NAME);
        jGenerator.writeString(APT_Constants.ATTRIBUTE_BAND_API_NAME);
        jGenerator.writeString(APT_Constants.ATTRIBUTE_EPARCEL_LODGEMENT_API_NAME);
        jGenerator.writeEndArray();
        jGenerator.writeStringField(APT_Constants.EXPR_STR, APT_Constants.ROUND_PARANTHESIS_START + APT_Constants.INDUSTRY + APT_Constants.SEPERATOR_SPACE +
                                                            APT_Constants.SEPERATOR_EQUAL +  APT_Constants.SEPERATOR_SPACE + industry + 
                                                            APT_Constants.ROUND_PARANTHESIS_END + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND +
                                                            APT_Constants.SEPERATOR_SPACE + APT_Constants.ROUND_PARANTHESIS_START + APT_Constants.BAND +
                                                            APT_Constants.SEPERATOR_SPACE + APT_Constants.SEPERATOR_EQUAL + APT_Constants.SEPERATOR_SPACE +
                                                            + band + APT_Constants.ROUND_PARANTHESIS_END + APT_Constants.SEPERATOR_SPACE +
                                                            APT_Constants.OPERATOR_AND + APT_Constants.SEPERATOR_SPACE + APT_Constants.ROUND_PARANTHESIS_START +
                                                            APT_Constants.EPARCEL_LODGEMENT + APT_Constants.SEPERATOR_SPACE + APT_Constants.SEPERATOR_EQUAL +
                                                            APT_Constants.SEPERATOR_SPACE + eParcelLodgment + APT_Constants.ROUND_PARANTHESIS_END);
        jGenerator.writeEndObject();
        string stringJSON = jGenerator.getAsString();
        
        return stringJSON;
    }
    */
    
    /**
        This method will generate JSON string being used in charge type criteria.
        Industry, Band and eParcelLodgment is used as Charge Type Criteria
        @params -
        industry - name of industry
        band - name of band
        eParcelLodgment - eParcel rates(true) or CSP rates(false)
     */
    public static String generateJSONStringForInternational(String band, 
                                                            String eParcelLodgment) {
        
        JSONGenerator jGenerator = JSON.createGenerator(APT_Constants.BOOL_TRUE);
        jGenerator.writeStartObject();
        jGenerator.writeStringField(APT_Constants.SOBJECT_NAME, APT_Constants.LINE_ITEM_SOBJECT_API_NAME);
        jGenerator.writeStringField(APT_Constants.SOBJECT_LABEL, APT_Constants.LINE_ITEM);
        jGenerator.writeNullField(APT_Constants.SEARCH_TEXT);
        
        jGenerator.writeFieldName(APT_Constants.FILTER);
        jGenerator.writeStartObject();
            jGenerator.writeFieldName(APT_Constants.PREDICATES);
            jGenerator.writeStartArray();
            jGenerator.writeEndArray();
            jGenerator.writeNullField(APT_Constants.COND_EXPR_STR);
            jGenerator.writeFieldName(APT_Constants.CHILD_FILTER);
                jGenerator.writeStartObject();
                jGenerator.writeStringField(APT_Constants.RELATION_FIELD_NAME, APT_Constants.LINE_ITEM_ID_API_NAME);
                jGenerator.writeFieldName(APT_Constants.PREDICATES);
                jGenerator.writeStartArray(); 
                    jGenerator.writeStartObject();
                    jGenerator.writeNumberField(APT_Constants.ROW_NUM, APT_Constants.INTEGER_ONE);
                    jGenerator.writeNullField(APT_Constants.RHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_TYPE);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_LABEL);
                    jGenerator.writeNullField(APT_Constants.RHS_CHILD_FILTER_NAME);
                    jGenerator.writeNullField(APT_Constants.REF_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.OFF_SET_VALUE);
                    jGenerator.writeNullField(APT_Constants.LHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.LHS_CHILD_FILTER_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_VALUE, band);
                    jGenerator.writeStringField(APT_Constants.FIELD_TYPE, APT_Constants.FIELD_TYPE_PICKLIST);
                    jGenerator.writeStringField(APT_Constants.FIELD_NAME, APT_Constants.BAND_API_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_LABEL, APT_Constants.BAND);
                    jGenerator.writeStringField(APT_Constants.COMP_OPER, APT_Constants.OPERATOR_EQUAL_TO);
                    jGenerator.writeStringField(APT_Constants.BOOL_OPER, APT_Constants.OPERATOR_AND);
                    jGenerator.writeEndObject(); 
                    
                    jGenerator.writeStartObject();
                    jGenerator.writeNumberField(APT_Constants.ROW_NUM, APT_Constants.INTEGER_TWO);
                    jGenerator.writeNullField(APT_Constants.RHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_TYPE);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_LABEL);
                    jGenerator.writeNullField(APT_Constants.RHS_CHILD_FILTER_NAME);
                    jGenerator.writeNullField(APT_Constants.REF_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.OFF_SET_VALUE);
                    jGenerator.writeNullField(APT_Constants.LHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.LHS_CHILD_FILTER_NAME);
                    //commented by HA
                   // jGenerator.writeStringField(APT_Constants.FIELD_VALUE, eParcelLodgment);
                    jGenerator.writeStringField(APT_Constants.FIELD_TYPE, APT_Constants.FIELD_TYPE_BOOLEAN);
                    jGenerator.writeStringField(APT_Constants.FIELD_NAME, APT_Constants.EPARCEL_LODGEMENT_API_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_LABEL, APT_Constants.EPARCEL_LODGEMENT);
                    jGenerator.writeStringField(APT_Constants.COMP_OPER, APT_Constants.OPERATOR_EQUAL_TO);
                    jGenerator.writeNullField(APT_Constants.BOOL_OPER);
                    jGenerator.writeEndObject();                    
                jGenerator.writeEndArray();
                
                jGenerator.writeStringField(APT_Constants.COND_EXPR_STR, APT_Constants.ONE + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND + APT_Constants.SEPERATOR_SPACE + APT_Constants.TWO);
                jGenerator.writeStringField(APT_Constants.CHILD_SOBJECT_NAME, APT_Constants.OBJECT_API_NAME_PRODUCT_ATTRIBUTE_VALUE);
                jGenerator.writeStringField(APT_Constants.CHILD_SOBJECT_LABEL, APT_Constants.OBJECT_LABEL_PRODUCT_ATTRIBUTE_VALUE);
                jGenerator.writeEndObject();       
        
        jGenerator.writeEndObject();
        
        jGenerator.writeFieldName(APT_Constants.FIELDS);
        jGenerator.writeStartArray();
        jGenerator.writeString(APT_Constants.ATTRIBUTE_BAND_API_NAME);
        jGenerator.writeString(APT_Constants.ATTRIBUTE_EPARCEL_LODGEMENT_API_NAME);
        jGenerator.writeEndArray();
        //jGenerator.writeStringField('exprStr', '(Band = '
        //                                        + band + ') AND (eParcel Lodgment = '
        //                                        + eParcelLodgment +')');
        
        jGenerator.writeStringField(APT_Constants.EXPR_STR, APT_Constants.ROUND_PARANTHESIS_START + APT_Constants.BAND + APT_Constants.SEPERATOR_SPACE +
                                                            APT_Constants.SEPERATOR_EQUAL + APT_Constants.SEPERATOR_SPACE + band + 
                                                            APT_Constants.ROUND_PARANTHESIS_END);
                                                            //commented by HA
                                                            // + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND +
                                                            // APT_Constants.SEPERATOR_SPACE + APT_Constants.ROUND_PARANTHESIS_START + APT_Constants.EPARCEL_LODGEMENT +
                                                            // APT_Constants.SEPERATOR_SPACE + APT_Constants.SEPERATOR_EQUAL + APT_Constants.SEPERATOR_SPACE + 
                                                            // eParcelLodgment + APT_Constants.ROUND_PARANTHESIS_END);
        
        jGenerator.writeEndObject();
        string stringJSON = jGenerator.getAsString();
        
        return stringJSON;
    }
    
    /**
        This method will create price matrix for international.
        Zone and International Price Type are used as Dimension
        @params -
        listPriceListItem - list of price list item
        mapDimension - get dimension using dimension name
     */
    public static list<Apttus_Config2__PriceMatrix__c> createPriceMatrixForInternational(list<Apttus_Config2__PriceListItem__c> listPriceListItem, 
                                                        map<String, String> mapDimension,
                                                        APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties,
                                                        map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix) {
        
        list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new list<Apttus_Config2__PriceMatrix__c>();
        Apttus_Config2__PriceMatrix__c existingPM;
        Apttus_Config2__PriceMatrix__c pm;
        for(Apttus_Config2__PriceListItem__c pli : listPriceListItem) {
            existingPM = mapExistingPriceMatrix.get(pli.Id);
            if(existingPM == null) {
                pm = new Apttus_Config2__PriceMatrix__c();
                if(r2tInternationalPricingProperties.APT_Dimension1_Name__c != null && r2tInternationalPricingProperties.APT_Dimension1_Type__c != null) {
                    pm.Apttus_Config2__Dimension1Id__c = mapDimension.get(r2tInternationalPricingProperties.APT_Dimension1_Name__c);
                    pm.Apttus_Config2__Dimension1ValueType__c = r2tInternationalPricingProperties.APT_Dimension1_Type__c;
                }
                
                if(r2tInternationalPricingProperties.APT_Dimension2_Name__c != null && r2tInternationalPricingProperties.APT_Dimension2_Type__c != null) {
                    pm.Apttus_Config2__Dimension2Id__c = mapDimension.get(r2tInternationalPricingProperties.APT_Dimension2_Name__c);
                    pm.Apttus_Config2__Dimension2ValueType__c = r2tInternationalPricingProperties.APT_Dimension2_Type__c;
                }
                
                if(r2tInternationalPricingProperties.APT_Dimension3_Name__c != null && r2tInternationalPricingProperties.APT_Dimension3_Type__c != null) {
                    pm.Apttus_Config2__Dimension3Id__c = mapDimension.get(r2tInternationalPricingProperties.APT_Dimension3_Name__c);
                    pm.Apttus_Config2__Dimension3ValueType__c = r2tInternationalPricingProperties.APT_Dimension3_Type__c;
                }
                
                if(r2tInternationalPricingProperties.APT_Dimension4_Name__c != null && r2tInternationalPricingProperties.APT_Dimension4_Type__c != null) {
                    pm.Apttus_Config2__Dimension4Id__c = mapDimension.get(r2tInternationalPricingProperties.APT_Dimension4_Name__c);
                    pm.Apttus_Config2__Dimension4ValueType__c = r2tInternationalPricingProperties.APT_Dimension4_Type__c;
                }
                
                if(r2tInternationalPricingProperties.APT_Dimension5_Name__c != null && r2tInternationalPricingProperties.APT_Dimension5_Type__c != null) {
                    pm.Apttus_Config2__Dimension5Id__c = mapDimension.get(r2tInternationalPricingProperties.APT_Dimension5_Name__c);
                    pm.Apttus_Config2__Dimension5ValueType__c = r2tInternationalPricingProperties.APT_Dimension5_Type__c;
                }
                
                if(r2tInternationalPricingProperties.APT_Dimension6_Name__c != null && r2tInternationalPricingProperties.APT_Dimension6_Type__c != null) {
                    pm.Apttus_Config2__Dimension6Id__c = mapDimension.get(r2tInternationalPricingProperties.APT_Dimension6_Name__c);
                    pm.Apttus_Config2__Dimension6ValueType__c = r2tInternationalPricingProperties.APT_Dimension6_Type__c;
                }
                
                //pm.Apttus_Config2__Dimension2Id__c = mapDimension.get('Weight Code');
                //pm.Apttus_Config2__Dimension2ValueType__c = APT_Constants.DIMENSION_VALUE_TYPE_RANGE;
                //pm.Apttus_Config2__Dimension2Id__c = mapDimension.get('International Price Type');
                //pm.Apttus_Config2__Dimension2ValueType__c = APT_Constants.DIMENSION_VALUE_TYPE_DISCRETE;
                
                pm.Apttus_Config2__PriceListItemId__c = pli.Id;
                pm.Apttus_Config2__Sequence__c = 1;
                
                listPriceMatrix.add(pm);
            }
        }
        system.debug('listPriceMatrix--->'+listPriceMatrix);
        return listPriceMatrix;
    }
    
    /**
        This method will create price matrix entry records for international.
        @params -
        listPriceMatrix - list of price matrix records
        mapInternationalPriceData - get international price data using key. Key is product code/charge type, industry and band
     */
    public static list<Apttus_Config2__PriceMatrixEntry__c> createPriceMatrixEntryForInternational(list<Apttus_Config2__PriceMatrix__c> listPriceMatrix,
                                                        map<String, list<APT_International_Price_Data__c>> mapInternationalPriceData) {
        
        list<Apttus_Config2__PriceMatrixEntry__c> listPME = new list<Apttus_Config2__PriceMatrixEntry__c>();
        //if no price matrix
        if(listPriceMatrix.size() == 0) {
            system.debug('listPriceMatrix---->'+listPriceMatrix.size());

            return listPME;
        }
        
        APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = APT_R2T_International_Pricing_Properties__c.getValues(APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES);
        if(r2tInternationalPricingProperties == null) {
            system.debug('r2tInternationalPricingProperties---->'+r2tInternationalPricingProperties);

            return listPME;
        }
        system.debug('listPriceMatrix---->'+listPriceMatrix);

        String dimensionValue1;
        String dimensionValue2;
        String dimensionValue3;
        String dimensionValue4;
        String dimensionValue5;
        String dimensionValue6;
        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(APT_Constants.INTERNATIONAL_PRICE_DATA_OBJECT_API_NAME).getDescribe().fields.getMap();
                
        for(String fieldAPIName : fieldMap.keySet()) {
            String fieldLabel = fieldMap.get(fieldAPIName).getDescribe().getLabel();
            System.debug('fieldLabel:'+fieldLabel);
            if(r2tInternationalPricingProperties.APT_Dimension1_Value__c != null && r2tInternationalPricingProperties.APT_Dimension1_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue1 = fieldAPIName;
            } else if(r2tInternationalPricingProperties.APT_Dimension1_Value__c != null && r2tInternationalPricingProperties.APT_Dimension1_Value__c.equalsIgnoreCase(APT_Constants.INTERNATIONAL_PRICE_TYPE) == true) {
                dimensionValue1 = r2tInternationalPricingProperties.APT_Dimension1_Value__c;
            }
            
            if(r2tInternationalPricingProperties.APT_Dimension2_Value__c != null && r2tInternationalPricingProperties.APT_Dimension2_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue2 = fieldAPIName;
            } else if(r2tInternationalPricingProperties.APT_Dimension2_Value__c != null && r2tInternationalPricingProperties.APT_Dimension2_Value__c.equalsIgnoreCase(APT_Constants.INTERNATIONAL_PRICE_TYPE) == true) {
                dimensionValue2 = r2tInternationalPricingProperties.APT_Dimension2_Value__c;
            }
            
            if(r2tInternationalPricingProperties.APT_Dimension3_Value__c != null && r2tInternationalPricingProperties.APT_Dimension3_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue3 = fieldAPIName;
            } else if(r2tInternationalPricingProperties.APT_Dimension3_Value__c != null && r2tInternationalPricingProperties.APT_Dimension3_Value__c.equalsIgnoreCase(APT_Constants.INTERNATIONAL_PRICE_TYPE) == true) {
                dimensionValue3 = r2tInternationalPricingProperties.APT_Dimension3_Value__c;
            }

            if(r2tInternationalPricingProperties.APT_Dimension4_Value__c != null && r2tInternationalPricingProperties.APT_Dimension4_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue4 = fieldAPIName;
            } else if(r2tInternationalPricingProperties.APT_Dimension4_Value__c != null && r2tInternationalPricingProperties.APT_Dimension4_Value__c.equalsIgnoreCase(APT_Constants.INTERNATIONAL_PRICE_TYPE) == true) {
                dimensionValue4 = r2tInternationalPricingProperties.APT_Dimension4_Value__c;
            }
            
            if(r2tInternationalPricingProperties.APT_Dimension5_Value__c != null && r2tInternationalPricingProperties.APT_Dimension5_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue5 = fieldAPIName;
            } else if(r2tInternationalPricingProperties.APT_Dimension5_Value__c != null && r2tInternationalPricingProperties.APT_Dimension5_Value__c.equalsIgnoreCase(APT_Constants.INTERNATIONAL_PRICE_TYPE) == true) {
                dimensionValue5 = r2tInternationalPricingProperties.APT_Dimension5_Value__c;
            }
            
            if(r2tInternationalPricingProperties.APT_Dimension6_Value__c != null && r2tInternationalPricingProperties.APT_Dimension6_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue6 = fieldAPIName;
            } else if(r2tInternationalPricingProperties.APT_Dimension6_Value__c != null && r2tInternationalPricingProperties.APT_Dimension6_Value__c.equalsIgnoreCase(APT_Constants.INTERNATIONAL_PRICE_TYPE) == true) {
                dimensionValue6 = r2tInternationalPricingProperties.APT_Dimension6_Value__c;
            }
        }
        system.debug('dimensionValue1----->'+dimensionValue1);
                system.debug('mapInternationalPriceData---->'+mapInternationalPriceData);

        Apttus_Config2__PriceMatrixEntry__c pmePerItem = new Apttus_Config2__PriceMatrixEntry__c();
        Apttus_Config2__PriceMatrixEntry__c pmePerKg = new Apttus_Config2__PriceMatrixEntry__c();
        list<APT_International_Price_Data__c> listIPD;
        for(Apttus_Config2__PriceMatrix__c pm : listPriceMatrix) {
            listIPD = new list<APT_International_Price_Data__c>();
            if(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT
                || pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT) {
                
                listIPD = mapInternationalPriceData.get(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c
                                                                                        + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.APT_Band__c);
            } else {
                listIPD = mapInternationalPriceData.get(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode
                                                                                        + APT_Constants.SEPERATOR_SIMILARITY + pm.Apttus_Config2__PriceListItemId__r.APT_Band__c);
            }
             
            if(listIPD.size() > 0) {
                system.debug('*** productcode ***'+pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode);
                system.debug('*** listIPD > size ***'+listIPD.size());
                Integer iSequence = 0;
                for(APT_International_Price_Data__c ipd : listIPD) {
                    iSequence++;
                    //per item
                    pmePerItem = new Apttus_Config2__PriceMatrixEntry__c();
                    //pmePerItem.Apttus_Config2__Dimension1Value__c = ipd.APT_Zone__c;
                    if(dimensionValue1 != null && dimensionValue1 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue1) != null) {
                            pmePerItem.Apttus_Config2__Dimension1Value__c = String.valueOf(ipd.get(dimensionValue1));
                        }    
                    } else if(dimensionValue1 != null && dimensionValue1 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerItem.Apttus_Config2__Dimension1Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item;
                    }
                    
                    //pmePerItem.Apttus_Config2__Dimension2Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item;
                    if(dimensionValue2 != null && dimensionValue2 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue2) != null) {
                            pmePerItem.Apttus_Config2__Dimension2Value__c = String.valueOf(ipd.get(dimensionValue2));
                        }   
                    } else if(dimensionValue2 != null && dimensionValue2 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerItem.Apttus_Config2__Dimension2Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item;
                    }
                    
                    if(dimensionValue3 != null && dimensionValue3 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue3) != null) {
                            pmePerItem.Apttus_Config2__Dimension3Value__c = String.valueOf(ipd.get(dimensionValue3));
                        }  
                    } else if(dimensionValue3 != null && dimensionValue3 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerItem.Apttus_Config2__Dimension3Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item;
                    }
                    
                    if(dimensionValue4 != null && dimensionValue4 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue4) != null) {
                            pmePerItem.Apttus_Config2__Dimension4Value__c = String.valueOf(ipd.get(dimensionValue4));
                        }  
                    } else if(dimensionValue4 != null && dimensionValue4 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerItem.Apttus_Config2__Dimension4Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item;
                    }
                    
                    if(dimensionValue5 != null && dimensionValue5 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue5) != null) {
                            pmePerItem.Apttus_Config2__Dimension5Value__c = String.valueOf(ipd.get(dimensionValue5));
                        } 
                    } else if(dimensionValue5 != null && dimensionValue5 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerItem.Apttus_Config2__Dimension5Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item;
                    }
                    
                    if(dimensionValue6 != null && dimensionValue6 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue6) != null) {
                            pmePerItem.Apttus_Config2__Dimension6Value__c = String.valueOf(ipd.get(dimensionValue6));
                        }                       
                    } else if(dimensionValue6 != null && dimensionValue6 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerItem.Apttus_Config2__Dimension6Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_Item;
                    }                    
                    
                    pmePerItem.Apttus_Config2__AdjustmentType__c = APT_Constants.ADJUSTMENT_TYPE_LIST_PRICE_OVERRIDE;
                    pmePerItem.Apttus_Config2__PriceMatrixId__c = pm.Id;
                    pmePerItem.Apttus_Config2__Sequence__c = iSequence;
                    
                    iSequence++;                    
                    //per kg
                    pmePerKg = new Apttus_Config2__PriceMatrixEntry__c();
                    //pmePerKg.Apttus_Config2__Dimension1Value__c = ipd.APT_Zone__c;
                    if(dimensionValue1 != null && dimensionValue1 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue1) != null) {
                            pmePerKg.Apttus_Config2__Dimension1Value__c = String.valueOf(ipd.get(dimensionValue1));
                        }     
                    } else if(dimensionValue1 != null && dimensionValue1 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerKg.Apttus_Config2__Dimension1Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG;
                    }
                    
                    //pmePerKg.Apttus_Config2__Dimension2Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG;
                    if(dimensionValue2 != null && dimensionValue2 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue2) != null) {
                            pmePerKg.Apttus_Config2__Dimension2Value__c = String.valueOf(ipd.get(dimensionValue2));
                        } 
                    } else if(dimensionValue2 != null && dimensionValue2 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerKg.Apttus_Config2__Dimension2Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG;
                    }
                    
                    if(dimensionValue3 != null && dimensionValue3 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue3) != null) {
                            pmePerKg.Apttus_Config2__Dimension3Value__c = String.valueOf(ipd.get(dimensionValue3));
                        }   
                    } else if(dimensionValue3 != null && dimensionValue3 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerKg.Apttus_Config2__Dimension3Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG;
                    }
                    
                    if(dimensionValue4 != null && dimensionValue4 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue4) != null) {
                            pmePerKg.Apttus_Config2__Dimension4Value__c = String.valueOf(ipd.get(dimensionValue4));
                        }  
                    } else if(dimensionValue4 != null && dimensionValue4 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerKg.Apttus_Config2__Dimension4Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG;
                    }
                    
                    if(dimensionValue5 != null && dimensionValue5 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue5) != null) {
                            pmePerKg.Apttus_Config2__Dimension5Value__c = String.valueOf(ipd.get(dimensionValue5));
                        }                       
                    } else if(dimensionValue5 != null && dimensionValue5 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerKg.Apttus_Config2__Dimension5Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG;
                    }
                    
                    if(dimensionValue6 != null && dimensionValue6 != APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        if(ipd.get(dimensionValue6) != null) {
                            pmePerKg.Apttus_Config2__Dimension6Value__c = String.valueOf(ipd.get(dimensionValue6));
                        }                       
                    } else if(dimensionValue6 != null && dimensionValue6 == APT_Constants.INTERNATIONAL_PRICE_TYPE) {
                        pmePerKg.Apttus_Config2__Dimension6Value__c = APT_Constants.INTERNATIONAL_PRICE_TYPE_PER_KG;
                    }
                    
                    pmePerKg.Apttus_Config2__AdjustmentType__c = APT_Constants.ADJUSTMENT_TYPE_LIST_PRICE_OVERRIDE;
                    pmePerKg.Apttus_Config2__PriceMatrixId__c = pm.Id;
                    pmePerKg.Apttus_Config2__Sequence__c  = iSequence;
                    
                    if(pm.Apttus_Config2__PriceListItemId__r.APT_eParcel_Lodgment__c == true) {
                        //eParcel
                        //per item
                        pmePerItem.Apttus_Config2__AdjustmentAmount__c = ipd.APT_eParcel_Per_Item_Rate__c;
                        pmePerItem.Apttus_Config2__PriceOverride__c = ipd.APT_eParcel_Per_Item_Rate__c;
                                                
                        //per kg
                        pmePerKg.Apttus_Config2__AdjustmentAmount__c = ipd.APT_eParcel_Per_Kg_Rate__c;
                        pmePerKg.Apttus_Config2__PriceOverride__c = ipd.APT_eParcel_Per_Kg_Rate__c;
                    } else {
                        //CSP
                        //per item
                        pmePerItem.Apttus_Config2__AdjustmentAmount__c = ipd.APT_CSP_Per_Item_Rate__c;
                        pmePerItem.Apttus_Config2__PriceOverride__c = ipd.APT_CSP_Per_Item_Rate__c;
                        
                        //per kg
                        pmePerKg.Apttus_Config2__AdjustmentAmount__c = ipd.APT_CSP_Per_Kg_Rate__c;
                        pmePerKg.Apttus_Config2__PriceOverride__c = ipd.APT_CSP_Per_Kg_Rate__c;
                    }
                    listPME.add(pmePerItem); 
                    listPME.add(pmePerKg);      
                }
            }
        }
        system.debug('listPME----->'+listPME);
        return listPME;
    }    
    
    
    /**
        This method will create price list item records for domestic.
        @params -
        listProduct - list of products
        defaultPriceListID - default price list id
        mapLodgmentZone - lodgment zone map. category and network type will be used as key
        mapPricingStructure - pricing structure map. category and network type will be used as key
        
     */
    public static list<Apttus_Config2__PriceListItem__c> createPriceListItemForDomestic(list<Product2> listProduct,
                                                                                        String defaultPriceListID,
                                                                                        map<String, set<String>> mapLodgmentZone,
                                                                                        map<String, set<String>> mapPricingStructure,
                                                                                        map<String, Apttus_Config2__PriceListItem__c> mapExistingPriceListItem) {
        
        list<Apttus_Config2__PriceListItem__c> listPriceListItem = new list<Apttus_Config2__PriceListItem__c>();
        
        for(Product2 product : listProduct) {
            set<String> setLodgmentZone = mapLodgmentZone.get(product.APT_Category__c + APT_Constants.SEPERATOR_SIMILARITY + product.APT_Network_Type__c);
            set<String> setPricingStructure = mapPricingStructure.get(product.APT_Category__c + APT_Constants.SEPERATOR_SIMILARITY + product.APT_Network_Type__c);
            String key;
            if(setLodgmentZone != null && setLodgmentZone.size() > 0 && setPricingStructure != null && setPricingStructure.size() > 0) {
                for(String lodgmentZone : setLodgmentZone) {
                    Apttus_Config2__PriceListItem__c pli;
                    for(String pricingStructure : setPricingStructure) {
                        key = product.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pricingStructure + APT_Constants.SEPERATOR_SIMILARITY + lodgmentZone;
                        system.debug('*** key2 ***'+key.toLowerCase());
                        Apttus_Config2__PriceListItem__c existingPLI = mapExistingPriceListItem.get(key.toLowerCase());
                        system.debug('*** existingPLI ***'+existingPLI);
                        if(existingPLI == null) {
                            system.debug('*** new pli ***');
                            pli = new Apttus_Config2__PriceListItem__c();
                            pli.Apttus_Config2__ProductId__c = product.Id;
                            pli.Apttus_Config2__PriceListId__c = defaultPriceListID;
                            pli.Apttus_Config2__ListPrice__c = APT_Constants.INTEGER_ZERO;
                            pli.Apttus_Config2__ChargeType__c =  APT_Constants.CHARGE_TYPE_STANDARD_PRICE;
                            pli.Apttus_Config2__PriceType__c = APT_Constants.PRICE_TYPE_USAGE;
                            pli.Apttus_Config2__PriceMethod__c = APT_Constants.PRICE_METHOD_PER_UNIT;
                            pli.Apttus_Config2__PriceUom__c = APT_Constants.PRICE_UOM_EACH;
                            
                            pli.Apttus_Config2__Active__c = APT_Constants.BOOL_TRUE;
                            
                            pli.Apttus_Config2__Criteria__c = generateJSONStringForDomestic(lodgmentZone, pricingStructure);
                            
                            pli.APT_Price_Structure__c = pricingStructure;
                            pli.APT_Lodgement_Zone_Code__c = lodgmentZone;
                            pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_TRUE;
                            
                            listPriceListItem.add(pli);
                        } 
                    }
                }               
            }
        }
        
        return listPriceListItem;
    }
    
    /**
        This method will generate charge type criteria JSON string for domestic.
        lodgment zone and pricing structure are used as charege tye criteria
        @params -
        lodgmentZone - lodgment zone
        pricingStructure - pricing structure
     */    
    public static String generateJSONStringForDomestic(String lodgmentZone, String pricingStructure) {
        JSONGenerator jGenerator = JSON.createGenerator(APT_Constants.BOOL_TRUE);
        jGenerator.writeStartObject();
        jGenerator.writeStringField(APT_Constants.SOBJECT_NAME, APT_Constants.LINE_ITEM_SOBJECT_API_NAME);
        jGenerator.writeStringField(APT_Constants.SOBJECT_LABEL, APT_Constants.LINE_ITEM);
        jGenerator.writeNullField(APT_Constants.SEARCH_TEXT);
        
        jGenerator.writeFieldName(APT_Constants.FILTER);
        jGenerator.writeStartObject();
            jGenerator.writeFieldName(APT_Constants.PREDICATES);
            jGenerator.writeStartArray();
            jGenerator.writeEndArray();
            jGenerator.writeNullField(APT_Constants.COND_EXPR_STR);
            jGenerator.writeFieldName(APT_Constants.CHILD_FILTER);
                jGenerator.writeStartObject();
                jGenerator.writeStringField(APT_Constants.RELATION_FIELD_NAME, APT_Constants.LINE_ITEM_ID_API_NAME);
                jGenerator.writeFieldName(APT_Constants.PREDICATES);
                jGenerator.writeStartArray();
                    jGenerator.writeStartObject();
                    jGenerator.writeNumberField(APT_Constants.ROW_NUM, APT_Constants.INTEGER_ONE);
                    jGenerator.writeNullField(APT_Constants.RHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_TYPE);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_LABEL);
                    jGenerator.writeNullField(APT_Constants.RHS_CHILD_FILTER_NAME);
                    jGenerator.writeNullField(APT_Constants.REF_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.OFF_SET_VALUE);
                    jGenerator.writeNullField(APT_Constants.LHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.LHS_CHILD_FILTER_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_VALUE, lodgmentZone);
                    jGenerator.writeStringField(APT_Constants.FIELD_TYPE, APT_Constants.FIELD_TYPE_STRING);
                    jGenerator.writeStringField(APT_Constants.FIELD_NAME, APT_Constants.LODGEMENT_ZONE_CODE_API_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_LABEL, APT_Constants.LODGEMENT_ZONE_CODE);
                    jGenerator.writeStringField(APT_Constants.COMP_OPER, APT_Constants.OPERATOR_EQUAL_TO);
                    jGenerator.writeStringField(APT_Constants.BOOL_OPER, APT_Constants.OPERATOR_AND);
                    jGenerator.writeEndObject(); 
                    
                    jGenerator.writeStartObject();
                    jGenerator.writeNumberField(APT_Constants.ROW_NUM, APT_Constants.INTEGER_TWO);
                    jGenerator.writeNullField(APT_Constants.RHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_TYPE);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.RHS_FIELD_LABEL);
                    jGenerator.writeNullField(APT_Constants.RHS_CHILD_FILTER_NAME);
                    jGenerator.writeNullField(APT_Constants.REF_FIELD_NAME);
                    jGenerator.writeNullField(APT_Constants.OFF_SET_VALUE);
                    jGenerator.writeNullField(APT_Constants.LHS_SOBJECT_NAME);
                    jGenerator.writeNullField(APT_Constants.LHS_CHILD_FILTER_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_VALUE, pricingStructure);
                    jGenerator.writeStringField(APT_Constants.FIELD_TYPE, APT_Constants.FIELD_TYPE_PICKLIST);
                    jGenerator.writeStringField(APT_Constants.FIELD_NAME, APT_Constants.PRICE_STRUCTURE_API_NAME);
                    jGenerator.writeStringField(APT_Constants.FIELD_LABEL, APT_Constants.PRICE_STRUCTURE);
                    jGenerator.writeStringField(APT_Constants.COMP_OPER, APT_Constants.OPERATOR_EQUAL_TO);
                    jGenerator.writeNullField(APT_Constants.BOOL_OPER);
                    jGenerator.writeEndObject();                    
                jGenerator.writeEndArray();
                
                //jGenerator.writeStringField('condExpr', '1 AND 2');
                jGenerator.writeStringField(APT_Constants.COND_EXPR_STR, APT_Constants.ONE + APT_Constants.SEPERATOR_SPACE +
                                            APT_Constants.OPERATOR_AND +  APT_Constants.SEPERATOR_SPACE + APT_Constants.TWO);
                //jGenerator.writeStringField('childSObjectName', 'Apttus_Config2__ProductAttributeValue__c');
                jGenerator.writeStringField(APT_Constants.CHILD_SOBJECT_NAME, APT_Constants.OBJECT_API_NAME_PRODUCT_ATTRIBUTE_VALUE);
                //jGenerator.writeStringField('childSObjectLabel', 'Product Attribute Value');
                jGenerator.writeStringField(APT_Constants.CHILD_SOBJECT_LABEL, APT_Constants.OBJECT_LABEL_PRODUCT_ATTRIBUTE_VALUE);
                jGenerator.writeEndObject();       
        
        jGenerator.writeEndObject();
        
        jGenerator.writeFieldName(APT_Constants.FIELDS);
        jGenerator.writeStartArray();
        jGenerator.writeString(APT_Constants.ATTRIBUTE_LODGEMENT_ZONE_CODE_API_NAME);
        jGenerator.writeString(APT_Constants.ATTRIBUTE_PRICE_STRUCTURE_API_NAME);
        jGenerator.writeEndArray();
        //jGenerator.writeStringField(APT_Constants.EXPR_STR, '(Lodgement Zone Code = ' + lodgmentZone + ') AND (Price Structure = '
        //                                        + pricingStructure +')');
        jGenerator.writeStringField(APT_Constants.EXPR_STR, APT_Constants.ROUND_PARANTHESIS_START + APT_Constants.LODGEMENT_ZONE_CODE + APT_Constants.SEPERATOR_SPACE + 
                                                            APT_Constants.SEPERATOR_EQUAL +  APT_Constants.SEPERATOR_SPACE + lodgmentZone + 
                                                            APT_Constants.ROUND_PARANTHESIS_END + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND +
                                                            APT_Constants.SEPERATOR_SPACE + APT_Constants.ROUND_PARANTHESIS_START + APT_Constants.PRICE_STRUCTURE +
                                                            APT_Constants.SEPERATOR_SPACE + APT_Constants.SEPERATOR_EQUAL + APT_Constants.SEPERATOR_SPACE + 
                                                            pricingStructure + APT_Constants.ROUND_PARANTHESIS_END);
        jGenerator.writeEndObject();
        string stringJSON = jGenerator.getAsString();
        
        return stringJSON;
    }
    
    /**
        This method will create price matrix for domestic.
        Destination Zone Code, Weight Range Code and Domestic Price Type are used as Dimension
        @params -
        listPriceListItem - list of price list item
        mapDimension - get dimension using dimension name
     */
    public static list<Apttus_Config2__PriceMatrix__c> createPriceMatrixForDomestic(list<Apttus_Config2__PriceListItem__c> listPriceListItem, 
                                                                                map<String, String> mapDimension,
                                                                                APT_R2T_Domestic_Pricing_Properties__c r2tDomesticPricingProperties,
                                                                                map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix) {
        
        list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new list<Apttus_Config2__PriceMatrix__c>();
        Apttus_Config2__PriceMatrix__c existingPriceMatrix;
        Apttus_Config2__PriceMatrix__c pm;
        for(Apttus_Config2__PriceListItem__c pli : listPriceListItem) {
            existingPriceMatrix = mapExistingPriceMatrix.get(pli.Id);
            if(existingPriceMatrix == null) {
                pm = new Apttus_Config2__PriceMatrix__c();
                //pm.Apttus_Config2__Dimension1Id__c = mapDimension.get('Destination Zone Code');
                //pm.Apttus_Config2__Dimension1ValueType__c = APT_Constants.DIMENSION_VALUE_TYPE_DISCRETE;
                if(r2tDomesticPricingProperties.APT_Dimension1_Name__c != null && r2tDomesticPricingProperties.APT_Dimension1_Type__c != null) {
                    pm.Apttus_Config2__Dimension1Id__c = mapDimension.get(r2tDomesticPricingProperties.APT_Dimension1_Name__c);
                    pm.Apttus_Config2__Dimension1ValueType__c = r2tDomesticPricingProperties.APT_Dimension1_Type__c;
                }
                
                //pm.Apttus_Config2__Dimension2Id__c = mapDimension.get('Weight Range Code');
                //pm.Apttus_Config2__Dimension2ValueType__c = APT_Constants.DIMENSION_VALUE_TYPE_RANGE;
                if(r2tDomesticPricingProperties.APT_Dimension2_Name__c != null && r2tDomesticPricingProperties.APT_Dimension2_Type__c != null) {
                    pm.Apttus_Config2__Dimension2Id__c = mapDimension.get(r2tDomesticPricingProperties.APT_Dimension2_Name__c);
                    pm.Apttus_Config2__Dimension2ValueType__c = r2tDomesticPricingProperties.APT_Dimension2_Type__c;
                }
                
                //pm.Apttus_Config2__Dimension3Id__c = mapDimension.get('Domestic Price Type');
                //pm.Apttus_Config2__Dimension3ValueType__c = APT_Constants.DIMENSION_VALUE_TYPE_DISCRETE;            
                if(r2tDomesticPricingProperties.APT_Dimension3_Name__c != null && r2tDomesticPricingProperties.APT_Dimension3_Type__c != null) {
                    pm.Apttus_Config2__Dimension3Id__c = mapDimension.get(r2tDomesticPricingProperties.APT_Dimension3_Name__c);
                    pm.Apttus_Config2__Dimension3ValueType__c = r2tDomesticPricingProperties.APT_Dimension3_Type__c;
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension4_Name__c != null && r2tDomesticPricingProperties.APT_Dimension4_Type__c != null) {
                    pm.Apttus_Config2__Dimension4Id__c = mapDimension.get(r2tDomesticPricingProperties.APT_Dimension4_Name__c);
                    pm.Apttus_Config2__Dimension4ValueType__c = r2tDomesticPricingProperties.APT_Dimension4_Type__c;
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension5_Name__c != null && r2tDomesticPricingProperties.APT_Dimension5_Type__c != null) {
                    pm.Apttus_Config2__Dimension5Id__c = mapDimension.get(r2tDomesticPricingProperties.APT_Dimension5_Name__c);
                    pm.Apttus_Config2__Dimension5ValueType__c = r2tDomesticPricingProperties.APT_Dimension5_Type__c;
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension6_Name__c != null && r2tDomesticPricingProperties.APT_Dimension6_Type__c != null) {
                    pm.Apttus_Config2__Dimension6Id__c = mapDimension.get(r2tDomesticPricingProperties.APT_Dimension6_Name__c);
                    pm.Apttus_Config2__Dimension6ValueType__c = r2tDomesticPricingProperties.APT_Dimension6_Type__c;
                }
                
                pm.Apttus_Config2__PriceListItemId__c = pli.Id;
                pm.Apttus_Config2__Sequence__c = 1;
                
                listPriceMatrix.add(pm);
            }
        }
        return listPriceMatrix;
    }
    
    /**
        This method will create price matrix entry records for domestic.
        @params -
        listPriceMatrix - list of price matrix records
        mapDomesticPriceData- get domestic price data using key. Key is product code/charge type, industry and band
     */
    public static list<Apttus_Config2__PriceMatrixEntry__c> createPriceMatrixEntryForDomestic(list<Apttus_Config2__PriceMatrix__c> listPriceMatrix,
                                                        map<String, list<APT_Domestic_Price_Data__c>> mapDomesticPriceData) {
        
        list<Apttus_Config2__PriceMatrixEntry__c> listPME = new list<Apttus_Config2__PriceMatrixEntry__c>();
        //if no price matrix
        if(listPriceMatrix.size() == 0) {
            return listPME;
        }
        
        APT_R2T_Domestic_Pricing_Properties__c r2tDomesticPricingProperties = APT_R2T_Domestic_Pricing_Properties__c.getValues(APT_Constants.R2T_DOMESTIC_PRICING_PROPERTIES);
        if(r2tDomesticPricingProperties == null) {
            return listPME;
        }
        
        String dimensionValue1;
        String dimensionValue2;
        String dimensionValue3;
        String dimensionValue4;
        String dimensionValue5;
        String dimensionValue6;
        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(APT_Constants.DOMESTIC_PRICE_DATA_OBJECT_API_NAME).getDescribe().fields.getMap();
                
        String fieldLabel;
        for(String fieldAPIName : fieldMap.keySet()) {
            fieldLabel = fieldMap.get(fieldAPIName).getDescribe().getLabel();
            if(r2tDomesticPricingProperties.APT_Dimension1_Value__c != null && r2tDomesticPricingProperties.APT_Dimension1_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue1 = fieldAPIName;
            } else if(r2tDomesticPricingProperties.APT_Dimension1_Value__c != null && r2tDomesticPricingProperties.APT_Dimension1_Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE) == true) {
                dimensionValue1 = r2tDomesticPricingProperties.APT_Dimension1_Value__c;
            }
            
            if(r2tDomesticPricingProperties.APT_Dimension2_Value__c != null && r2tDomesticPricingProperties.APT_Dimension2_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue2 = fieldAPIName;
            } else if(r2tDomesticPricingProperties.APT_Dimension2_Value__c != null && r2tDomesticPricingProperties.APT_Dimension2_Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE) == true) {
                dimensionValue2 = r2tDomesticPricingProperties.APT_Dimension2_Value__c;
            }
            
            if(r2tDomesticPricingProperties.APT_Dimension3_Value__c != null && r2tDomesticPricingProperties.APT_Dimension3_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue3 = fieldAPIName;
            } else if(r2tDomesticPricingProperties.APT_Dimension3_Value__c != null && r2tDomesticPricingProperties.APT_Dimension3_Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE) == true) {
                dimensionValue3 = r2tDomesticPricingProperties.APT_Dimension3_Value__c;
            }
            
            if(r2tDomesticPricingProperties.APT_Dimension4_Value__c != null && r2tDomesticPricingProperties.APT_Dimension4_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue4 = fieldAPIName;
            } else if(r2tDomesticPricingProperties.APT_Dimension4_Value__c != null && r2tDomesticPricingProperties.APT_Dimension4_Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE) == true) {
                dimensionValue4 = r2tDomesticPricingProperties.APT_Dimension4_Value__c;
            }
            
            if(r2tDomesticPricingProperties.APT_Dimension5_Value__c != null && r2tDomesticPricingProperties.APT_Dimension5_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue5 = fieldAPIName;
            } else if(r2tDomesticPricingProperties.APT_Dimension5_Value__c != null && r2tDomesticPricingProperties.APT_Dimension5_Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE) == true) {
                dimensionValue5 = r2tDomesticPricingProperties.APT_Dimension5_Value__c;
            }
            
            if(r2tDomesticPricingProperties.APT_Dimension6_Value__c != null && r2tDomesticPricingProperties.APT_Dimension6_Value__c.equalsIgnoreCase(fieldLabel) == true) {
                dimensionValue6 = fieldAPIName;
            } else if(r2tDomesticPricingProperties.APT_Dimension6_Value__c != null && r2tDomesticPricingProperties.APT_Dimension6_Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE) == true) {
                dimensionValue6 = r2tDomesticPricingProperties.APT_Dimension6_Value__c;
            }
        }
        
        Integer iSequence = 0;
        Apttus_Config2__PriceMatrixEntry__c basePME = new Apttus_Config2__PriceMatrixEntry__c();
        Apttus_Config2__PriceMatrixEntry__c subsequentPME = new Apttus_Config2__PriceMatrixEntry__c();
        Apttus_Config2__PriceMatrixEntry__c perKgPME = new Apttus_Config2__PriceMatrixEntry__c();
        for(Apttus_Config2__PriceMatrix__c pm : listPriceMatrix) {        
            list<APT_Domestic_Price_Data__c> listDPD = mapDomesticPriceData.get(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Category__c 
                                                                                + APT_Constants.SEPERATOR_SIMILARITY 
                                                                                + pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c 
                                                                                + APT_Constants.SEPERATOR_SIMILARITY 
                                                                                + pm.Apttus_Config2__PriceListItemId__r.APT_Lodgement_Zone_Code__c
                                                                                + APT_Constants.SEPERATOR_SIMILARITY 
                                                                                + pm.Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c);
            if(listDPD != null && listDPD.size() > 0) {
                iSequence = 0;
                for(APT_Domestic_Price_Data__c dpd : listDPD) {
                    iSequence++;
                    //base
                    if(dpd.APT_Base_Rate__c != null) {
                        basePME = new Apttus_Config2__PriceMatrixEntry__c();
                        //basePME.Apttus_Config2__Dimension1Value__c = dpd.APT_Destination_Zone_Code__c;
                        //if(dpd.APT_Weight_Range_Code__c != null) {
                        //    basePME.Apttus_Config2__Dimension2Value__c = string.valueOf(dpd.APT_Weight_Range_Code__c);
                        //}                    
                        //basePME.Apttus_Config2__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                        
                        if(!String.isEmpty(dimensionValue1) && dimensionValue1 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue1) != null) {
                                basePME.Apttus_Config2__Dimension1Value__c = String.valueOf(dpd.get(dimensionValue1));
                            }  
                        } else if(!String.isEmpty(dimensionValue1) && dimensionValue1.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            basePME.Apttus_Config2__Dimension1Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                        }
                        
                        if(!String.isEmpty(dimensionValue2) && dimensionValue2 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue2) != null) {
                                basePME.Apttus_Config2__Dimension2Value__c = String.valueOf(dpd.get(dimensionValue2));
                            } 
                        } else if(!String.isEmpty(dimensionValue2) && dimensionValue2.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            basePME.Apttus_Config2__Dimension2Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                        }
                        
                        if(!String.isEmpty(dimensionValue3) && dimensionValue3 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue3) != null) {
                                basePME.Apttus_Config2__Dimension3Value__c = String.valueOf(dpd.get(dimensionValue3));
                            } 
                        } else if(!String.isEmpty(dimensionValue3) && dimensionValue3.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            basePME.Apttus_Config2__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                        }
                        
                        if(!String.isEmpty(dimensionValue4) && dimensionValue4 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue4) != null) {
                                basePME.Apttus_Config2__Dimension4Value__c = String.valueOf(dpd.get(dimensionValue4));
                            }    
                        } else if(!String.isEmpty(dimensionValue4) && dimensionValue4.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            basePME.Apttus_Config2__Dimension4Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                        }
                        
                        if(!String.isEmpty(dimensionValue5) && dimensionValue5 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue5) != null) {
                                basePME.Apttus_Config2__Dimension5Value__c = String.valueOf(dpd.get(dimensionValue5));
                            }   
                        } else if(!String.isEmpty(dimensionValue5) && dimensionValue5.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            basePME.Apttus_Config2__Dimension5Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                        }
                        
                        if(!String.isEmpty(dimensionValue6) && dimensionValue6 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue6) != null) {
                                basePME.Apttus_Config2__Dimension6Value__c = String.valueOf(dpd.get(dimensionValue6));
                            }  
                        } else if(!String.isEmpty(dimensionValue6) && dimensionValue6.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            basePME.Apttus_Config2__Dimension6Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                        }                        
                        
                        basePME.Apttus_Config2__AdjustmentType__c = APT_Constants.ADJUSTMENT_TYPE_LIST_PRICE_OVERRIDE;
                        basePME.Apttus_Config2__PriceMatrixId__c = pm.Id;
                        basePME.Apttus_Config2__Sequence__c = iSequence;
                        
                        basePME.Apttus_Config2__AdjustmentAmount__c = dpd.APT_Base_Rate__c;
                        basePME.Apttus_Config2__PriceOverride__c = dpd.APT_Base_Rate__c;
                        
                        listPME.add(basePME);
                        iSequence++;
                    }
                    
                    //subsequent
                    if(dpd.APT_Subsequent_Rate__c != null) {
                        subsequentPME = new Apttus_Config2__PriceMatrixEntry__c();
                        //subsequentPME.Apttus_Config2__Dimension1Value__c = dpd.APT_Destination_Zone_Code__c;
                        //if(dpd.APT_Weight_Range_Code__c != null) {
                        //    subsequentPME.Apttus_Config2__Dimension2Value__c = String.valueOf(dpd.APT_Weight_Range_Code__c);
                        //}                    
                        //subsequentPME.Apttus_Config2__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                        
                        if(!String.isEmpty(dimensionValue1 ) && dimensionValue1 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue1) != null) {
                                subsequentPME.Apttus_Config2__Dimension1Value__c = String.valueOf(dpd.get(dimensionValue1));
                            }                           
                        } else if(!String.isEmpty(dimensionValue1 ) && dimensionValue1.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            subsequentPME.Apttus_Config2__Dimension1Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                        }
                        
                        if(!String.isEmpty(dimensionValue2) && dimensionValue2 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue2) != null) {
                                subsequentPME.Apttus_Config2__Dimension2Value__c = String.valueOf(dpd.get(dimensionValue2));
                            }
                        } else if(!String.isEmpty(dimensionValue2) && dimensionValue2.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            subsequentPME.Apttus_Config2__Dimension2Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                        }
                        
                        if(!String.isEmpty(dimensionValue3) && dimensionValue3 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue3) != null) {
                                subsequentPME.Apttus_Config2__Dimension3Value__c = String.valueOf(dpd.get(dimensionValue3));
                            }
                        } else if(!String.isEmpty(dimensionValue3) && dimensionValue3.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            subsequentPME.Apttus_Config2__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                        }
                        
                        if(!String.isEmpty(dimensionValue4) && dimensionValue4 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue4) != null) {
                                subsequentPME.Apttus_Config2__Dimension4Value__c = String.valueOf(dpd.get(dimensionValue4));
                            }     
                        } else if(!String.isEmpty(dimensionValue4) && dimensionValue4.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            subsequentPME.Apttus_Config2__Dimension4Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                        }
                        
                        if(!String.isEmpty(dimensionValue5) && dimensionValue5 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue5) != null) {
                                subsequentPME.Apttus_Config2__Dimension5Value__c = String.valueOf(dpd.get(dimensionValue5));
                            }   
                        } else if(!String.isEmpty(dimensionValue5) && dimensionValue5.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            subsequentPME.Apttus_Config2__Dimension5Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                        }
                        
                        if(!String.isEmpty(dimensionValue6) && dimensionValue6 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue6) != null) {
                                subsequentPME.Apttus_Config2__Dimension6Value__c = String.valueOf(dpd.get(dimensionValue6));
                            }   
                        } else if(!String.isEmpty(dimensionValue6) && dimensionValue6.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            subsequentPME.Apttus_Config2__Dimension6Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                        }   
                        
                        subsequentPME.Apttus_Config2__AdjustmentType__c = APT_Constants.ADJUSTMENT_TYPE_LIST_PRICE_OVERRIDE;
                        subsequentPME.Apttus_Config2__PriceMatrixId__c = pm.Id;
                        subsequentPME.Apttus_Config2__Sequence__c = iSequence;
                        
                        subsequentPME.Apttus_Config2__AdjustmentAmount__c = dpd.APT_Subsequent_Rate__c;
                        subsequentPME.Apttus_Config2__PriceOverride__c = dpd.APT_Subsequent_Rate__c;
                       
                        listPME.add(subsequentPME); 
                        
                        iSequence++;
                    }
                    
                    //per kg
                    if(dpd.APT_Per_Kg_Rate__c!= null) {
                        perKgPME = new Apttus_Config2__PriceMatrixEntry__c();
                        //perKgPME.Apttus_Config2__Dimension1Value__c = dpd.APT_Destination_Zone_Code__c;
                        //if(dpd.APT_Weight_Range_Code__c != null) {
                        //    perKgPME.Apttus_Config2__Dimension2Value__c = String.valueOf(dpd.APT_Weight_Range_Code__c);
                        //}                        
                        //perKgPME.Apttus_Config2__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                        
                        if(!String.isEmpty(dimensionValue1 ) && dimensionValue1 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue1) != null) {
                                perKgPME.Apttus_Config2__Dimension1Value__c = String.valueOf(dpd.get(dimensionValue1));
                            }    
                        } else if(!String.isEmpty(dimensionValue1 ) && dimensionValue1.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            perKgPME.Apttus_Config2__Dimension1Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                        }
                        
                        if(!String.isEmpty(dimensionValue2 ) && dimensionValue2 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue2) != null) {
                                perKgPME.Apttus_Config2__Dimension2Value__c = String.valueOf(dpd.get(dimensionValue2));
                            }  
                        } else if(!String.isEmpty(dimensionValue2) && dimensionValue2.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            perKgPME.Apttus_Config2__Dimension2Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                        }
                        
                        if(!String.isEmpty(dimensionValue3 ) && dimensionValue3 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue3) != null) {
                                perKgPME.Apttus_Config2__Dimension3Value__c = String.valueOf(dpd.get(dimensionValue3));
                            }
                        } else if(!String.isEmpty(dimensionValue3 ) && dimensionValue3.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            perKgPME.Apttus_Config2__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                        }
                        
                        if(!String.isEmpty(dimensionValue4 ) && dimensionValue4 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue4) != null) {
                                perKgPME.Apttus_Config2__Dimension4Value__c = String.valueOf(dpd.get(dimensionValue4));
                            }  
                        } else if(!String.isEmpty(dimensionValue4 ) && dimensionValue4.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            perKgPME.Apttus_Config2__Dimension4Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                        }
                        
                        if(!String.isEmpty(dimensionValue5) && dimensionValue5 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue5) != null) {
                                perKgPME.Apttus_Config2__Dimension5Value__c = String.valueOf(dpd.get(dimensionValue5));
                            }
                        } else if(!String.isEmpty(dimensionValue5) && dimensionValue5.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            perKgPME.Apttus_Config2__Dimension5Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                        }
                        
                        if(!String.isEmpty(dimensionValue6) && dimensionValue6 != APT_Constants.DOMESTIC_PRICE_TYPE) {
                            if(dpd.get(dimensionValue6) != null) {
                                perKgPME.Apttus_Config2__Dimension6Value__c = String.valueOf(dpd.get(dimensionValue6));
                            }
                        } else if(!String.isEmpty(dimensionValue6) && dimensionValue6.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE)) {
                            perKgPME.Apttus_Config2__Dimension6Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                        }   
                        
                        perKgPME.Apttus_Config2__AdjustmentType__c = APT_Constants.ADJUSTMENT_TYPE_LIST_PRICE_OVERRIDE;
                        perKgPME.Apttus_Config2__PriceMatrixId__c = pm.Id;
                        perKgPME.Apttus_Config2__Sequence__c = iSequence;
                        
                        perKgPME.Apttus_Config2__AdjustmentAmount__c = dpd.APT_Per_Kg_Rate__c;
                        perKgPME.Apttus_Config2__PriceOverride__c = dpd.APT_Per_Kg_Rate__c;                   
                        
                        listPME.add(perKgPME); 
                    }   
                }
            }
        }
        return listPME;
    }  
    
    /**
        This method will retrun all fields of provided object.
        @params -
        objectName - object api name
     */
    public static String getAllFields(String objectName){

        String query;
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objectName).getDescribe().fields.getMap();
        //String commaSepratedFields = '';
        String commaSepratedFields;

        for(String fieldName : fieldMap.keyset()){
            //if(commaSepratedFields == null || commaSepratedFields == ''){
            if(String.isEmpty(commaSepratedFields)){
                commaSepratedFields = fieldName;
            }else{
                commaSepratedFields = commaSepratedFields + APT_Constants.SEPERATOR_COMMA_SPACE + fieldName;
            }
        }
        query = commaSepratedFields;
        //query = 'select ' + commaSepratedFields + ' from ';

        return query;
    }   

    /**
        This method will create price list item records for startrack products.
        @params -
        listProduct - list of products
        defaultPriceListID - default price list id
        mapLodgmentZone - lodgment zone map. category and network type will be used as key
        mapExistingPriceListItem - existing plis. pricingKey will be used as key
        mapLodgmentZoneDescription - description of lodgement zones
        mapPostCodeMapping - map of post codes and zone types
        mapRateCardVersion - map of domestic data to rate card version
     */
    public static List<Apttus_Config2__PriceListItem__c> createPriceListItemForSTE(List<Product2> listProduct, 
                                                                                    String defaultPriceListID, 
                                                                                    map<String, set<String>> mapLodgmentZone, 
                                                                                    map<String, Apttus_Config2__PriceListItem__c> mapExistingPriceListItem,
                                                                                    map<String, String> mapLodgmentZoneDescription,
                                                                                    map<String, set<String>> mapPostCodeMapping,
                                                                                    map<String, String> mapRateCardVersion,
                                                                                    map<String, String> mapRateCardUpdatedOn) 
    {
        List<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>();

        for(Product2 product : listProduct) 
        {
            //for each product's category and netwrok type, get lodgement zones
            set<String> setLodgmentZone = mapLodgmentZone.get(product.APT_Category__c + APT_Constants.ADD_TILDE + product.APT_Network_Type__c);
            string rateCardVersion = mapRateCardVersion.get(product.APT_Category__c + APT_Constants.ADD_TILDE + product.APT_Network_Type__c);
            string rateCardUpdatedOn = mapRateCardUpdatedOn.get(product.APT_Category__c + APT_Constants.ADD_TILDE + product.APT_Network_Type__c);
            system.debug('createPriceListItemForSTE product: '+ product.ProductCode);
            system.debug('createPriceListItemForSTE setLodgmentZone: '+ setLodgmentZone);

            if(setLodgmentZone != null && setLodgmentZone.size() > 0) 
            {
                for(String lodgmentZone : setLodgmentZone) 
                {
                    //for each lodgement zone, create pricing key as below combination
                    String pricingKey = product.APT_Category__c + APT_Constants.ADD_TILDE  + product.APT_Network_Type__c + APT_Constants.ADD_TILDE + lodgmentZone;
                    system.debug('createPriceListItemForSTE key: '+ pricingKey);

                    //sequence Numbers
                    Integer sequence = 1;
                    Apttus_Config2__PriceListItem__c existingPLI;

                    //get post code mapping zone type
                    set<String> postCodeMappingZoneTypes = mapPostCodeMapping.get(product.APT_Network_Type__c);

                    //for all post code mapping combination, create pli for given lodgement zone
                    if(postCodeMappingZoneTypes != null && postCodeMappingZoneTypes.size() > 0)
                    {
                        for(String postCodeMappingZoneType : postCodeMappingZoneTypes)
                        {
                            system.debug('postCodeMappingZoneType: '+ postCodeMappingZoneType);
                            if(postCodeMappingZoneType != null)
                            {
                                //split post code mapping zone type
                                string[] postCodeMappingZoneTypeSplit = postCodeMappingZoneType.split(APT_Constants.ADD_HYPHEN);

                                if(postCodeMappingZoneTypeSplit != null && postCodeMappingZoneTypeSplit.size() == 2)
                                {
                                    //zone type is the first value
                                    string zoneType = postCodeMappingZoneTypeSplit[0];

                                    //zones are second value
                                    string[] zones = postCodeMappingZoneTypeSplit[1].split(APT_Constants.ADD_TILDE);
                                    string mainZone;
                                    string altZone;
                                    string pliZones;
                                    string zoneDescription;

                                    if(zones != null && zones.size() > 0)
                                    {
                                        mainZone = zones[0];
                                        pliZones = mainZone;
                                        zoneDescription = mapLodgmentZoneDescription.get(mainZone);

                                        if(zones.size() > 1 && zones[1] != 'null' && zones[1] != mainZone)
                                        {
                                            altZone = zones[1];
                                            pliZones = pliZones + APT_Constants.ADD_TILDE + altZone;
                                            zoneDescription = zoneDescription + APT_Constants.ADD_COMMA + mapLodgmentZoneDescription.get(altZone);
                                        }
                                    }

                                    if(lodgmentZone == mainZone)
                                    {
                                        //for each lodgement zone, create unique zone combination key as below combination
                                        string zoneCombination = pricingKey + APT_Constants.ADD_TILDE  + postCodeMappingZoneType;

                                        system.debug('zoneType: '+ zoneType);
                                        system.debug('pliZones: '+ pliZones);
                                        system.debug('zoneCombination: '+ zoneCombination);

                                        //check if there is any existing PLI with same unique zone combination
                                        existingPLI = mapExistingPriceListItem.get(zoneCombination);

                                        List<Map<String, String>> criteriaFields = new List<Map<String, String>>();
                                        Map<String, String>  criteriaField = new Map<String, String>();
                                        criteriaField.put(APT_Constants.FIELD_VALUE, postCodeMappingZoneType);
                                        criteriaField.put(APT_Constants.FIELD_TYPE, 'String');
                                        criteriaField.put(APT_Constants.FIELD_NAME, 'APT_Zone_Criteria__c');
                                        criteriaField.put(APT_Constants.FIELD_EXPR, 'Apttus_Config2__AttributeValueId__r.APT_Zone_Criteria__c');
                                        criteriaField.put(APT_Constants.FIELD_LABEL, 'Zone Criteria');
                                        criteriaFields.add(criteriaField);

                                        Apttus_Config2__PriceListItem__c priceListItem = createPriceListItem(product.Id, defaultPriceListID, pricingKey, sequence, zoneType, pliZones, zoneCombination, zoneDescription, rateCardVersion, rateCardUpdatedOn, criteriaFields);

                                        if(existingPLI != null)
                                        {
                                            priceListItem.Id = existingPLI.Id;
                                        }

                                        listPriceListItem.add(priceListItem);

                                        sequence++;
                                    }
                                }
                            }
                        }
                    }
                }               
            }
        }
        
        return listPriceListItem;
    }

    /**
        This method will create price list item records for startrack products.
        @params -
        productId - product id 
        defaultPriceListID - price list id 
        pricingKey - pricing key 
        Integer sequence - sequence
        zoneType - zone type
        zones - zones
        zoneCombination - zone combination unique key on PLI 
        zoneDescription - zone description
        rateCardVersion - rate card version
        rateCardUpdatedOn - rate card updated on
        criteriaFields - charge type critiera fields collection
     */
    private static Apttus_Config2__PriceListItem__c createPriceListItem(String productId, 
                                                                        String defaultPriceListID, 
                                                                        String pricingKey, 
                                                                        Integer sequence,
                                                                        string zoneType,
                                                                        string zones,
                                                                        string zoneCombination,
                                                                        string zoneDescription,
                                                                        string rateCardVersion,
                                                                        string rateCardUpdatedOn,
                                                                        List<Map<String, String>> criteriaFields) 
    {
        //create pli record for the given values
        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__ProductId__c = productId;
        pli.Apttus_Config2__PriceListId__c = defaultPriceListID;
        pli.Apttus_Config2__ListPrice__c = APT_Constants.INTEGER_ZERO;
        pli.Apttus_Config2__ChargeType__c =  APT_Constants.CHARGE_TYPE_STANDARD_PRICE;
        pli.Apttus_Config2__PriceType__c = APT_Constants.PRICE_TYPE_USAGE;
        pli.Apttus_Config2__PriceMethod__c = APT_Constants.PRICE_METHOD_PER_UNIT;
        pli.Apttus_Config2__PriceUom__c = APT_Constants.PRICE_UOM_EACH;
        pli.Apttus_Config2__Active__c = APT_Constants.BOOL_TRUE;
        pli.Apttus_Config2__Criteria__c = criteriaFields != null ? generateJSONStringForSTE(criteriaFields) : null;
        pli.Apttus_Config2__Sequence__c = sequence;
        pli.APT_Pricing_Key__c = pricingKey;
        pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_FALSE;
        pli.Apttus_Config2__AllowManualAdjustment__c = APT_Constants.BOOL_FALSE;
        pli.Apttus_Config2__AllocateGroupAdjustment__c = APT_Constants.BOOL_FALSE;
        pli.APT_Zone_Type__c = zoneType;
        pli.APT_Zones__c = zones;
        pli.APT_Zone_Combination__c = zoneCombination;
        pli.APT_Zone_Description__c = zoneDescription;
        pli.APT_Rate_Card_Version__c = rateCardVersion;
        pli.APT_Rate_Card_Updated_On__c = rateCardUpdatedOn;
        
        system.debug('createPriceListItemForSTE pli.Apttus_Config2__Criteria__c: '+ pli.Apttus_Config2__Criteria__c);
        
        return pli;
    }
    
    /**
        This method will generate charge type criteria JSON string for startrack products.
        lodgment zone and pricing structure are used as charege tye criteria
        @params -
        criteriaFields - fields to be added in criteria
     */    
    private static String generateJSONStringForSTE(List<Map<String, String>> criteriaFields) 
    {
        //generate json structure for the criteria of pli
        Integer rowNum = 1;
        APT_PLICriteriaModel pliCriteria = new APT_PLICriteriaModel();
        pliCriteria.sObjectName = APT_Constants.LINE_ITEM_SOBJECT_API_NAME;
        pliCriteria.sObjectLabel = APT_Constants.LINE_ITEM;
        pliCriteria.filter = new APT_PLICriteriaModel.Filter();
        pliCriteria.fields = new List<String>();
        pliCriteria.exprStr = '';
        pliCriteria.filter.predicates = new List<String>();
        pliCriteria.filter.childFilter = new APT_PLICriteriaModel.ChildFilter();
        pliCriteria.filter.childFilter.relationFieldName = APT_Constants.LINE_ITEM_ID_API_NAME;
        pliCriteria.filter.childFilter.predicates = new List<APT_PLICriteriaModel.Predicates>();
        pliCriteria.filter.childFilter.condExpr = '';

        //add all the criterias in json
        for(Map<String, String> criteriaField: criteriaFields)
        {
            //add predicates
            APT_PLICriteriaModel.Predicates predicate = new APT_PLICriteriaModel.Predicates();
            predicate.RowNum = rowNum;
            predicate.FieldValue = criteriaField.get(APT_Constants.FIELD_VALUE);
            predicate.FieldType = criteriaField.get(APT_Constants.FIELD_TYPE);
            predicate.FieldName = criteriaField.get(APT_Constants.FIELD_NAME);
            predicate.FieldLabel = criteriaField.get(APT_Constants.FIELD_LABEL);
            predicate.CompOper = APT_Constants.OPERATOR_EQUAL_TO;

            //add row number
            if(rowNum != criteriaFields.size())
            {
                predicate.BoolOper = APT_Constants.OPERATOR_AND;
            }

            pliCriteria.filter.childFilter.predicates.add(predicate);

            //add condition expression
            if(pliCriteria.filter.childFilter.condExpr != '')
            {
                pliCriteria.filter.childFilter.condExpr = pliCriteria.filter.childFilter.condExpr + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND + APT_Constants.SEPERATOR_SPACE;
            }
            pliCriteria.filter.childFilter.condExpr = pliCriteria.filter.childFilter.condExpr + rowNum;

            //add expression
            if(pliCriteria.exprStr != '')
            {
                pliCriteria.exprStr = pliCriteria.exprStr + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND + APT_Constants.SEPERATOR_SPACE;
            }

            //add fields
            pliCriteria.fields.add(criteriaField.get(APT_Constants.FIELD_EXPR));

            pliCriteria.exprStr = pliCriteria.exprStr + APT_Constants.ROUND_PARANTHESIS_START + criteriaField.get(APT_Constants.FIELD_LABEL) + APT_Constants.SEPERATOR_EQUAL + criteriaField.get(APT_Constants.FIELD_VALUE) + APT_Constants.ROUND_PARANTHESIS_END;

            rowNum++;
        }

        pliCriteria.filter.childFilter.childSObjectName = APT_Constants.OBJECT_API_NAME_PRODUCT_ATTRIBUTE_VALUE;
        pliCriteria.filter.childFilter.childSObjectLabel = APT_Constants.OBJECT_LABEL_PRODUCT_ATTRIBUTE_VALUE;

        return JSON.serialize(pliCriteria);
    }
    
    /**
        This method will create price matrix for startrack products.
        Destination Zone Code, Weight Range Code and Startrack Price Type are used as Dimension
        @params -
        listPriceListItem - list of price list item
        mapDimension - get dimension using dimension name,
        stPricingProperties - custom settings data for price dimensions
        mapExistingPriceMatrix - exising PM
     */
    public static List<Apttus_Config2__PriceMatrix__c> createPriceMatrixForSTE(set<Id> setPriceListItemId, 
                                                                                map<String, String> mapDimension,
                                                                                APT_R2T_Domestic_Pricing_Properties__c stPricingProperties,
                                                                                map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix) 
    {
        
        List<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new List<Apttus_Config2__PriceMatrix__c>();
        Apttus_Config2__PriceMatrix__c existingPriceMatrix;
        Apttus_Config2__PriceMatrix__c priceMatrix;

        //for each price list item, create price matrix
        for(Id priceListItemId : setPriceListItemId) 
        {
            //check if price matrix exists for given pli, if not create new
            existingPriceMatrix = mapExistingPriceMatrix.get(priceListItemId);
            priceMatrix = new Apttus_Config2__PriceMatrix__c();

            //assign dimension ids and type to price matrix records
            priceMatrix.Apttus_Config2__Dimension1Id__c = mapDimension.get(stPricingProperties.APT_Dimension1_Name__c);
            priceMatrix.Apttus_Config2__Dimension1ValueType__c = stPricingProperties.APT_Dimension1_Type__c;
        
            priceMatrix.Apttus_Config2__Dimension2Id__c = mapDimension.get(stPricingProperties.APT_Dimension2_Name__c);
            priceMatrix.Apttus_Config2__Dimension2ValueType__c = stPricingProperties.APT_Dimension2_Type__c;
        
            priceMatrix.Apttus_Config2__Dimension3Id__c = mapDimension.get(stPricingProperties.APT_Dimension3_Name__c);
            priceMatrix.Apttus_Config2__Dimension3ValueType__c = stPricingProperties.APT_Dimension3_Type__c;
        
            priceMatrix.Apttus_Config2__Dimension4Id__c = mapDimension.get(stPricingProperties.APT_Dimension4_Name__c);
            priceMatrix.Apttus_Config2__Dimension4ValueType__c = stPricingProperties.APT_Dimension4_Type__c;
        
            priceMatrix.Apttus_Config2__Dimension5Id__c = mapDimension.get(stPricingProperties.APT_Dimension5_Name__c);
            priceMatrix.Apttus_Config2__Dimension5ValueType__c = stPricingProperties.APT_Dimension5_Type__c;
        
            priceMatrix.Apttus_Config2__Dimension6Id__c = mapDimension.get(stPricingProperties.APT_Dimension6_Name__c);
            priceMatrix.Apttus_Config2__Dimension6ValueType__c = stPricingProperties.APT_Dimension6_Type__c;
            
            priceMatrix.Apttus_Config2__PriceListItemId__c = priceListItemId;
            priceMatrix.Apttus_Config2__Sequence__c = 1;
            
            if(existingPriceMatrix != null) 
            {
                priceMatrix.Id = existingPriceMatrix.Id;
            }
            listPriceMatrix.add(priceMatrix);
        }
        return listPriceMatrix;
    }
    
    /**
        This method will create price matrix entry records for startrack products.
        @params -
        listPriceMatrix - list of price matrix records
        mapDomesticPriceData- get domestic price data using key. Key is product code, category, network type, pickup zone and dest zone
    */
    public static List<Apttus_Config2__PriceMatrixEntry__c> createPriceMatrixEntryForSTE(List<Apttus_Config2__PriceMatrix__c> listPriceMatrix,
                                                                                        map<String, List<APT_Domestic_Price_Data__c>> mapDomesticPriceData) 
    {
        List<Apttus_Config2__PriceMatrixEntry__c> listPriceMatrixEntry = new List<Apttus_Config2__PriceMatrixEntry__c>();
        Apttus_Config2__PriceMatrixEntry__c basicRatePME = new Apttus_Config2__PriceMatrixEntry__c();
        Apttus_Config2__PriceMatrixEntry__c subsequentRatePME = new Apttus_Config2__PriceMatrixEntry__c();
        Apttus_Config2__PriceMatrixEntry__c perKgRatePME = new Apttus_Config2__PriceMatrixEntry__c();
        
        //get pricing properties
        APT_R2T_Domestic_Pricing_Properties__c stPricingProperties = APT_R2T_Domestic_Pricing_Properties__c.getValues(APT_Constants.ST_PRICING_PROPERTIES);

        //if no price matrix or pricing properties
        if(listPriceMatrix.size() == 0 || stPricingProperties == null) 
        {
            return listPriceMatrixEntry;
        }
        
        //get Dimesion Field API Names
        Map<string, string> dimensions = new Map<string, string>();
        dimensions.put('dimension1', stPricingProperties.APT_Dimension1_Value__c);
        dimensions.put('dimension2', stPricingProperties.APT_Dimension2_Value__c);
        dimensions.put('dimension3', stPricingProperties.APT_Dimension3_Value__c);
        dimensions.put('dimension4', stPricingProperties.APT_Dimension4_Value__c);
        dimensions.put('dimension5', stPricingProperties.APT_Dimension5_Value__c);
        dimensions.put('dimension6', stPricingProperties.APT_Dimension6_Value__c);
            
        system.debug('dimensions: ' + dimensions);

        //for each price matrix, create price matrix entries
        for(Apttus_Config2__PriceMatrix__c priceMatrix : listPriceMatrix) 
        {        
            system.debug('APT_Pricing_Key__c: ' + priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c);
            system.debug('APT_Zones__c: ' + priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Zones__c);
            
            //get domestice price data for the pricing key
            List<APT_Domestic_Price_Data__c> listDomesticPriceData = mapDomesticPriceData.get(priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c);
            system.debug('listDomesticPriceData: ' + listDomesticPriceData);

            if(listDomesticPriceData != null && listDomesticPriceData.size() > 0) 
            {
                system.debug('listDomesticPriceData Size: ' + listDomesticPriceData.size());
                Integer iSequence = 1;
                String domesticZoneType;

                //get zone type for the main outbound domestic entry based on which price matrix entries will be created
                for(APT_Domestic_Price_Data__c domesticPriceData : listDomesticPriceData) 
                {
                    if(domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.OUTBOUND)
                    {
                        domesticZoneType = domesticPriceData.APT_Zone_Type__c;
                        break;
                    }
                }

                if(domesticZoneType != null)
                {
                    //deserialize zones
                    APT_ZoneTypeModel zoneTypeModel = (APT_ZoneTypeModel)JSON.deserialize(domesticZoneType, APT_ZoneTypeModel.class);
                    system.debug('zoneTypeModel: ' + zoneTypeModel);

                    //in case of onforwarding alternate zone, get domestic data for all alternate zones too
                    if(zoneTypeModel.onforwardingAlternateZone != null && priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c == APT_Constants.ZONE_TYPE_ONFORWARDING_ALTERNATE)
                    {
                        //get pricing Key
                        String[] pricingKeyValues = priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c.Split(APT_Constants.ADD_TILDE);

                        //get all alternate zones
                        string[] onforwardAlternateZones = zoneTypeModel.onforwardingAlternateZone.split(APT_Constants.ADD_COMMA);
                        for(String onforwardAlternateZone: onforwardAlternateZones)
                        {
                            if(priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Zones__c == onforwardAlternateZone)
                            {
                                string[] onforwardAlternate = onforwardAlternateZone.split(APT_Constants.ADD_TILDE);

                                //generate new pricing key to get alternate zones data and add it to exising list
                                String alternatePricingKey = pricingKeyValues[0] + APT_Constants.ADD_TILDE + pricingKeyValues[1] + APT_Constants.ADD_TILDE + onforwardAlternate[1];
                                List<APT_Domestic_Price_Data__c> alternateZoneDomesticData = mapDomesticPriceData.get(alternatePricingKey);
                                if(alternateZoneDomesticData != null)
                                {
                                    listDomesticPriceData.addall(alternateZoneDomesticData);
                                }
                            }
                        }
                    }

                    for(APT_Domestic_Price_Data__c domesticPriceData : listDomesticPriceData) 
                    {
                        Set<string> zoneTypes = new Set<string>();

                        //for direct zone
                        if(zoneTypeModel.directZone != null && priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c == APT_Constants.ZONE_TYPE_DIRECT)
                        {
                            //if inbound, search in from zone. if outbound, search in to zone
                            if((domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.OUTBOUND && domesticPriceData.APT_Lodgement_Zone_Code__c == zoneTypeModel.directZone) ||
                            (domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.INBOUND && domesticPriceData.APT_Destination_Zone_Code__c == zoneTypeModel.directZone))
                            {
                                zoneTypes.add(APT_Constants.ZONE_TYPE_DIRECT);
                            }
                        }
                        else 
                        {
                            //for onforwarding zone
                            if(zoneTypeModel.onforwardingZone != null && priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c == APT_Constants.ZONE_TYPE_ONFORWARDING)
                            {
                                //if inbound, search in from zone. if outbound, search in to zone
                                if((domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.OUTBOUND && domesticPriceData.APT_Lodgement_Zone_Code__c == zoneTypeModel.onforwardingZone) ||
                                    (domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.INBOUND && domesticPriceData.APT_Destination_Zone_Code__c == zoneTypeModel.onforwardingZone))
                                {
                                    zoneTypes.add(APT_Constants.ZONE_TYPE_ONFORWARDING);
                                }
                            }
                            //for onforwarding alternate zone
                            if(zoneTypeModel.onforwardingAlternateZone != null && priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c == APT_Constants.ZONE_TYPE_ONFORWARDING_ALTERNATE)
                            {
                                string[] onforwardingAlternateZones = zoneTypeModel.onforwardingAlternateZone.split(APT_Constants.ADD_COMMA);
                                for(String onforwardingAlternateZone: onforwardingAlternateZones)
                                {
                                    if(priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Zones__c == onforwardingAlternateZone)
                                    {
                                        string[] onforwardingAlternate = onforwardingAlternateZone.split(APT_Constants.ADD_TILDE);

                                        //if inbound, search in from zone. if outbound, search in to zone
                                        if((domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.OUTBOUND && domesticPriceData.APT_Lodgement_Zone_Code__c == onforwardingAlternate[0]) ||
                                            (domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.INBOUND && domesticPriceData.APT_Destination_Zone_Code__c == onforwardingAlternate[0]))
                                        {
                                            zoneTypes.add(APT_Constants.ZONE_TYPE_ONFORWARDING);
                                        }

                                        //if inbound, search in from zone. if outbound, search in to zone
                                        if((domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.OUTBOUND && domesticPriceData.APT_Lodgement_Zone_Code__c == onforwardingAlternate[1]) ||
                                            (domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.INBOUND && domesticPriceData.APT_Destination_Zone_Code__c == onforwardingAlternate[1]))
                                        {
                                            zoneTypes.add(APT_Constants.ZONE_TYPE_ALTERNATE);
                                        }
                                    }
                                }
                            }
                        }

                        system.debug('zoneTypes: ' + zoneTypes);

                        //for each zone, create price matrix entry
                        for(string zoneType: zoneTypes)
                        {
                            string[] dimensionValue = new string[6];
                            Integer dimensionIndex = 0;

                            //assign dimension values
                            for(string dimension: dimensions.keySet())
                            {
                                string dimensionName = dimensions.get(dimension);

                                //if dimsion is zone typw, assign zone type
                                if(!String.isEmpty(dimensionName) && dimensionName.equalsIgnoreCase(APT_Constants.ZONE_TYPE)) {
                                    dimensionValue[dimensionIndex] = zoneType;
                                }
                                //else assign actual dimesion value
                                else if(!String.isEmpty(dimensionName) && !dimensionName.equalsIgnoreCase(APT_Constants.PRICE_TYPE)) {
                                    dimensionValue[dimensionIndex] = String.valueOf(domesticPriceData.get(dimensionName));
                                }

                                dimensionIndex++;
                            }

                            system.debug('zoneType dimensionValue: ' + zoneType + ':'+ dimensionValue);

                            //create pme for basic charge
                            if(domesticPriceData.APT_Base_Rate__c != null)
                            {
                                dimensionIndex = 0;
                                for(string dimension: dimensions.keySet())
                                {
                                    //set the price type dimension to base
                                    string dimensionName = dimensions.get(dimension);
                                    if(!String.isEmpty(dimensionName) && dimensionName.equalsIgnoreCase(APT_Constants.PRICE_TYPE)) {
                                        dimensionValue[dimensionIndex] = APT_Constants.ST_PRICE_TYPE_BASE;
                                    }

                                    dimensionIndex++;
                                }

                                basicRatePME = CreatePME(dimensionValue, priceMatrix.Id, iSequence, domesticPriceData.APT_Base_Rate__c);
                                listPriceMatrixEntry.add(basicRatePME); 
                                iSequence++;

                                system.debug('zoneType basicRatePME: ' + zoneType + ':'+ basicRatePME);

                            }

                            //create pme for basic charge
                            if(domesticPriceData.APT_Per_Kg_Rate__c != null)
                            {
                                dimensionIndex = 0;
                                for(string dimension: dimensions.keySet())
                                {
                                    //set the price type dimension to per kg
                                    string dimensionName = dimensions.get(dimension);
                                    if(!String.isEmpty(dimensionName) && dimensionName.equalsIgnoreCase(APT_Constants.PRICE_TYPE)) {
                                        dimensionValue[dimensionIndex] = APT_Constants.ST_PRICE_TYPE_PER_KG;
                                    }

                                    dimensionIndex++;
                                }
                                
                                perKgRatePME = CreatePME(dimensionValue, priceMatrix.Id, iSequence, domesticPriceData.APT_Per_Kg_Rate__c);
                                listPriceMatrixEntry.add(perKgRatePME); 
                                iSequence++;
                                system.debug('zoneType perKgRatePME: ' + zoneType + ':'+ perKgRatePME);
                            }

                            //create pme for minimum charge
                            if(domesticPriceData.APT_Subsequent_Rate__c != null)
                            {
                                dimensionIndex = 0;
                                for(string dimension: dimensions.keySet())
                                {
                                    //set the price type dimension to minimum
                                    string dimensionName = dimensions.get(dimension);
                                    if(!String.isEmpty(dimensionName) && dimensionName.equalsIgnoreCase(APT_Constants.PRICE_TYPE)) {
                                        dimensionValue[dimensionIndex] = APT_Constants.ST_PRICE_TYPE_MINIMUM;
                                    }

                                    dimensionIndex++;
                                }
                                
                                subsequentRatePME = CreatePME(dimensionValue, priceMatrix.Id, iSequence, domesticPriceData.APT_Subsequent_Rate__c);
                                listPriceMatrixEntry.add(subsequentRatePME); 
                                iSequence++;
                                system.debug('zoneType subsequentRatePME: ' + zoneType + ':'+ subsequentRatePME);
                            }
                        }
                    }
                }
            }
        }
        return listPriceMatrixEntry;
    }
    
    /**
        This method will create price matrix entry records.
        @params -
        listPriceMatrix - list of price matrix records
        dimensions- dimension values
        priceMatrixId - price matrix id
        iSequence - sequence number
        amount - amount
    */
    private static Apttus_Config2__PriceMatrixEntry__c createPME(string[] dimensionValue, string priceMatrixId, Integer iSequence, Decimal amount)
    {
        //creates pme records from the input params for prime matrix
        Apttus_Config2__PriceMatrixEntry__c priceMatrixEntry = new Apttus_Config2__PriceMatrixEntry__c();
        priceMatrixEntry.Apttus_Config2__Dimension1Value__c = dimensionValue[0];
        priceMatrixEntry.Apttus_Config2__Dimension2Value__c = dimensionValue[1];
        priceMatrixEntry.Apttus_Config2__Dimension3Value__c = dimensionValue[2];
        priceMatrixEntry.Apttus_Config2__Dimension4Value__c = dimensionValue[3];
        priceMatrixEntry.Apttus_Config2__Dimension5Value__c = dimensionValue[4];
        priceMatrixEntry.Apttus_Config2__Dimension6Value__c = dimensionValue[5];
        priceMatrixEntry.Apttus_Config2__AdjustmentType__c = APT_Constants.ADJUSTMENT_TYPE_LIST_PRICE_OVERRIDE;
        priceMatrixEntry.Apttus_Config2__PriceMatrixId__c = priceMatrixId;
        priceMatrixEntry.Apttus_Config2__Sequence__c = iSequence;
        priceMatrixEntry.Apttus_Config2__AdjustmentAmount__c = amount;
        priceMatrixEntry.Apttus_Config2__PriceOverride__c = amount;

        return priceMatrixEntry;
    }

    /**
        This method will create price list item record for startrack products.
        @params -
        listProduct - list of products
        defaultPriceListID - default price list id
        mapExistingPriceListItem - existing plis. pricingKey will be used as key
        mapRateCardVersion - map of domestic data to rate card version
        mapRateCardUpdatedOn - map of rate card updated on
     */
    public static List<Apttus_Config2__PriceListItem__c> createSinglePriceListItem(List<Product2> listProduct, 
                                                                                    String defaultPriceListID, 
                                                                                    map<String, Apttus_Config2__PriceListItem__c> mapExistingPriceListItem,
                                                                                    map<String, String> mapRateCardVersion,
                                                                                    map<String, String> mapRateCardUpdatedOn) 
    {
        List<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>();

        for(Product2 product : listProduct) 
        {
            //for each product's category and netwrok type, get rateCardVersion & rateCardUpdatedOn
            string rateCardVersion = mapRateCardVersion.get(product.APT_Category__c + APT_Constants.ADD_TILDE + product.APT_Network_Type__c);
            string rateCardUpdatedOn = mapRateCardUpdatedOn.get(product.APT_Category__c + APT_Constants.ADD_TILDE + product.APT_Network_Type__c);

            //for each lodgement zone, create pricing key as below combination
            String pricingKey = product.APT_Category__c + APT_Constants.ADD_TILDE  + product.APT_Network_Type__c;

            //sequence Numbers
            Integer sequence = 1;
                            
            //check if there is any existing PLI for same product
            Apttus_Config2__PriceListItem__c existingPLI = mapExistingPriceListItem.get(product.Id);

            Apttus_Config2__PriceListItem__c priceListItem = createPriceListItem(product.Id, defaultPriceListID, pricingKey, sequence, null, null, null, null, rateCardVersion, rateCardUpdatedOn, null);

            if(existingPLI != null)
            {
                priceListItem.Id = existingPLI.Id;
            }
            listPriceListItem.add(priceListItem);
        }
        
        return listPriceListItem;
    }

    /**
        This method will create price matrix entry records for startrack products.
        @params -
        listPriceMatrix - list of price matrix records
        mapDomesticPriceData- get domestic price data using key. Key is product code, category, network type, pickup zone and dest zone
    */
    public static List<Apttus_Config2__PriceMatrixEntry__c> createPMEForSinglePLISTE(List<Apttus_Config2__PriceMatrix__c> listPriceMatrix,
                                                                                                  map<String, List<APT_Domestic_Price_Data__c>> mapDomesticPriceData) 
    {
        List<Apttus_Config2__PriceMatrixEntry__c> listPriceMatrixEntry = new List<Apttus_Config2__PriceMatrixEntry__c>();
        Apttus_Config2__PriceMatrixEntry__c priceMatrixEntry = new Apttus_Config2__PriceMatrixEntry__c();
        
        //get pricing properties
        APT_R2T_Domestic_Pricing_Properties__c stPricingProperties = APT_R2T_Domestic_Pricing_Properties__c.getValues(APT_Constants.ST_SINGLE_PRICING_PROPERTIES);

        //if no price matrix or pricing properties
        if(listPriceMatrix.size() == 0 || stPricingProperties == null) 
        {
            return listPriceMatrixEntry;
        }
        
        //get Dimesion Field API Names
        Map<string, string> dimensions = new Map<string, string>();
        dimensions.put('dimension1', stPricingProperties.APT_Dimension1_Value__c);
        dimensions.put('dimension2', stPricingProperties.APT_Dimension2_Value__c);
        dimensions.put('dimension3', stPricingProperties.APT_Dimension3_Value__c);
        dimensions.put('dimension4', stPricingProperties.APT_Dimension4_Value__c);
        dimensions.put('dimension5', stPricingProperties.APT_Dimension5_Value__c);
        dimensions.put('dimension6', stPricingProperties.APT_Dimension6_Value__c);
            
        system.debug('dimensions: ' + dimensions);

        //for each price matrix, create price matrix entries
        for(Apttus_Config2__PriceMatrix__c priceMatrix : listPriceMatrix) 
        {        
            //get domestice price data for the pricing key
            List<APT_Domestic_Price_Data__c> listDomesticPriceData = mapDomesticPriceData.get(priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c);
            system.debug('listDomesticPriceData: ' + listDomesticPriceData);

            if(listDomesticPriceData != null && listDomesticPriceData.size() > 0) 
            {
                system.debug('listDomesticPriceData Size: ' + listDomesticPriceData.size());
                Integer iSequence = 1;

                for(APT_Domestic_Price_Data__c domesticPriceData : listDomesticPriceData) 
                {
                    string[] dimensionValue = new string[6];
                    Integer dimensionIndex = 0;

                    //assign dimension values
                    for(string dimension: dimensions.keySet())
                    {
                        string dimensionName = dimensions.get(dimension);

                        //assign actual dimesion value
                        if(!String.isEmpty(dimensionName)) {
                            dimensionValue[dimensionIndex] = String.valueOf(domesticPriceData.get(dimensionName));
                        }

                        dimensionIndex++;
                    }

                    system.debug('dimensionValue: ' + dimensionValue);

                    //create pme                             
                    priceMatrixEntry = CreatePME(dimensionValue, priceMatrix.Id, iSequence, null);
                    listPriceMatrixEntry.add(priceMatrixEntry); 
                    iSequence++;
                }
            }
        }
        return listPriceMatrixEntry;
    }
}