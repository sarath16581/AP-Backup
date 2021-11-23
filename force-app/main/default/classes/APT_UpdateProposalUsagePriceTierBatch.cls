/**
Description: This batch job will update proposal usage price tier records based on line item rate card records
Created By - Mausam Padhiyar
Created Date - 19th May, 2016
Last Modified By -
Last Modified Date - 
**/
global class APT_UpdateProposalUsagePriceTierBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global set<String> setErrorMessage {get;set;}
    set<Id> setProposalId = new set<Id>();
    
    //constructor
    global APT_UpdateProposalUsagePriceTierBatch (set<Id> proposalIdSet){
        setErrorMessage = new set<String>();
        setProposalId = proposalIdSet;
    }
    
    //start
    global Database.QueryLocator start(Database.BatchableContext bc) {        
        //start
        return Database.getQueryLocator([SELECT Id, APT_Price_Structure__c, Apttus_QPConfig__OptionId__c,
                                        Apttus_QPConfig__OptionId__r.APT_Domestic_Pricing__c,
                                        APT_Charge_Code_Formula__c, Apttus_QPConfig__AttributeValueId__c,
                                        Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c,
                                        Apttus_Proposal__Product__c, Apttus_Proposal__Product__r.ProductCode,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Consignment_Pricing__c,
                                        Apttus_QPConfig__AttributeValueId__r.APT_Signature_On_Delivery__c
                                        FROM Apttus_Proposal__Proposal_Line_Item__c
                                        WHERE Apttus_Proposal__Proposal__c IN :setProposalId
                                        AND Apttus_QPConfig__OptionId__r.APT_Domestic_Pricing__c = true]);
    }
    
    //execute 
    global void execute(Database.BatchableContext bc, list<Apttus_Proposal__Proposal_Line_Item__c> scope){
        try {
            /*
            //charge code calculation
            set<String> setNetworkType = new set<String>{APT_Constants.NETWORK_TYPE_STANDARD, APT_Constants.NETWORK_TYPE_EXPRESS};
            set<String> setWeightMeasure = new set<String>{APT_Constants.WEIGHT_MEASURE_CUBIC, APT_Constants.WEIGHT_MEASURE_DEADWEIGHT};
            set<String> setPriceStructure = new set<String>();
            //charge code calculation
            */
            
            //update proposal usage price tier
            list<APT_R2T_Weight_Field_Mapping__c> listR2TWeightFieldMapping = APT_R2T_Weight_Field_Mapping__c.getAll().values();
            map<String, APT_R2T_Weight_Field_Mapping__c> mapR2TWeightFieldMapping = new map<String, APT_R2T_Weight_Field_Mapping__c>();
            if(listR2TWeightFieldMapping != null && listR2TWeightFieldMapping.size() > 0) {
                for(APT_R2T_Weight_Field_Mapping__c r2tWeightFieldMapping : listR2TWeightFieldMapping) {
                    mapR2TWeightFieldMapping.put(r2tWeightFieldMapping.Name, r2tWeightFieldMapping);
                }
            } else {
                system.debug('***ERROR =>' + APT_Constants.ERROR_MISSING_R2T_WEIGHT_FIELD_MAPPING);
                setErrorMessage.add(APT_Constants.ERROR_MISSING_R2T_WEIGHT_FIELD_MAPPING);
            }
            
            set<Id> setProposalLineItemId = new set<Id>();
            for(Apttus_Proposal__Proposal_Line_Item__c pli : scope) {
                setProposalLineItemId.add(pli.Id);
                //setPriceStructure.add(pli.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c);    //charge code calculation
            }
            System.debug('***setProposalLineItemId =>' + setProposalLineItemId);
            
            /*
            System.debug(' setPriceStructure: ' + setPriceStructure +
                        ' setNetworkType: ' + setNetworkType + 
                        ' setWeightMeasure: ' + setWeightMeasure);
            //charge code calculation
            map<String, APT_Charge_Code__c> mapChargeCode = new map<String, APT_Charge_Code__c>();
            for(APT_Charge_Code__c chargeCode : [SELECT APT_Charge_Code_C1__c, APT_Charge_Code_C2__c, APT_Charge_Code_C3__c, APT_Charge_Code_C4__c,
                                            APT_Price_Structure__c, APT_Network_Type__c, APT_Weight_Measure__c, APT_Consignment_Pricing__c, APT_Signature__c
                                            FROM APT_Charge_Code__c 
                                            WHERE APT_Price_Structure__c IN :setPriceStructure
                                            AND APT_Network_Type__c IN :setNetworkType
                                            AND APT_Weight_Measure__c IN :setWeightMeasure]) {
            
                mapChargeCode.put(chargeCode.APT_Price_Structure__c + APT_Constants.SEPERATOR_SIMILARITY + chargeCode.APT_Network_Type__c + APT_Constants.SEPERATOR_SIMILARITY + 
                                    chargeCode.APT_Weight_Measure__c + APT_Constants.SEPERATOR_SIMILARITY + chargeCode.APT_Consignment_Pricing__c + APT_Constants.SEPERATOR_SIMILARITY +
                                    chargeCode.APT_Signature__c, chargeCode);
            }
            
            String networkType;
            String weightMeasure;
            Boolean bConsignmentPricing;
            Boolean bSignature;
            list<Apttus_Proposal__Proposal_Line_Item__c> listPLI = new list<Apttus_Proposal__Proposal_Line_Item__c>();
            for(Apttus_Proposal__Proposal_Line_Item__c pli : scope) {
                networkType = null;
                weightMeasure = null;
                bSignature = null;
                bConsignmentPricing = null;
                
                if(!String.isEmpty(pli.Apttus_Proposal__Product__r.ProductCode)){
                    if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)) {
                        networkType = APT_Constants.NETWORK_TYPE_STANDARD;
                    } else if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)) {
                        networkType = APT_Constants.NETWORK_TYPE_EXPRESS;
                    } else { }
                }
                system.debug('*** networkType ***'+networkType);
                if(pli.Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c != null && pli.Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c > 1) {
                    weightMeasure = APT_Constants.WEIGHT_MEASURE_DEADWEIGHT;
                } else{
                    weightMeasure = APT_Constants.WEIGHT_MEASURE_CUBIC;
                }
                system.debug('*** weightMeasure ***'+weightMeasure);
                if(!String.isEmpty(pli.Apttus_QPConfig__AttributeValueId__r.APT_Consignment_Pricing__c)) {
                    if(pli.Apttus_QPConfig__AttributeValueId__r.APT_Consignment_Pricing__c.equalsIgnoreCase(APT_Constants.OPTION_YES)) {
                        bConsignmentPricing = true;
                    } else {
                        bConsignmentPricing = false;
                    }
                }
                system.debug('*** bConsignmentPricing ***'+bConsignmentPricing);
                if(!String.isEmpty(pli.Apttus_QPConfig__AttributeValueId__r.APT_Signature_On_Delivery__c)) {
                    if(pli.Apttus_QPConfig__AttributeValueId__r.APT_Signature_On_Delivery__c.equalsIgnoreCase(APT_Constants.OPTION_YES)) {
                        bSignature = true;
                    } else {
                        bSignature = false;
                    }
                }
                system.debug('*** bSignature ***'+bSignature);
                APT_Charge_Code__c chargeCode = mapChargeCode.get(pli.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c + APT_Constants.SEPERATOR_SIMILARITY + networkType + APT_Constants.SEPERATOR_SIMILARITY +
                                                                    weightMeasure + APT_Constants.SEPERATOR_SIMILARITY + bConsignmentPricing + APT_Constants.SEPERATOR_SIMILARITY + 
                                                                    bSignature);
                                                                    
                if(chargeCode != null) {
                    system.debug('*** chargeCode ***'+chargeCode);
                    pli.APT_Charge_Code_Formula__c = chargeCode.APT_Charge_Code_C1__c + chargeCode.APT_Charge_Code_C2__c + chargeCode.APT_Charge_Code_C3__c + chargeCode.APT_Charge_Code_C4__c;
                    listPLI.add(pli);
                }
                
            }
            update listPLI;
            //charge code calculation
            */
            
            map<String, APT_Line_Item_Rate_Card__c> mapLineItemRateCard = new map<String, APT_Line_Item_Rate_Card__c>();
            list<APT_Line_Item_Rate_Card__c> listLineItemRateCard = database.query('Select ' + getAllFields('APT_Line_Item_Rate_Card__c') + ' FROM APT_Line_Item_Rate_Card__c WHERE APT_Proposal_Line_Item__c IN :setProposalLineItemId');
            System.debug('***listLineItemRateCard => ' + listLineItemRateCard);
            for(APT_Line_Item_Rate_Card__c lirc : listLineItemRateCard) {
                mapLineItemRateCard.put(lirc.APT_Proposal_Line_Item__c + '~' + lirc.APT_Value_1__c, lirc);
                system.debug('***mapLineItemRateCard LOOP:  ' + mapLineItemRateCard);
            }
            
            map<String, String> labelToAPIName = new map<String, String> ();

            map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.APT_Line_Item_Rate_Card__c.fields.getMap();
            for (Schema.SObjectField field : fieldsMap.values()) {
                labelToAPIName.put(field.getDescribe().getLabel(), field.getDescribe().getName());
            }
            
            //String APINAME = labelToAPIName.get('Value 3');
            //system.debug('*** APINAME ***'+APINAME);
                        
            list<Apttus_QPConfig__ProposalUsagePriceTier__c> listUpdatePUPT = new list<Apttus_QPConfig__ProposalUsagePriceTier__c>();
            for(Apttus_QPConfig__ProposalUsagePriceTier__c pupt : [SELECT Id, Name,
                                                                    Apttus_QPConfig__Dimension1Value__c, Apttus_QPConfig__Dimension2Value__c,
                                                                    Apttus_QPConfig__Dimension3Value__c,
                                                                    Apttus_QPConfig__AdjustmentAmount__c, Apttus_QPConfig__PriceOverride__c,
                                                                    Apttus_QPConfig__UsageRate__c,
                                                                    Apttus_QPConfig__LineItemId__c, Apttus_QPConfig__LineItemId__r.APT_Price_Structure__c
                                                                    FROM Apttus_QPConfig__ProposalUsagePriceTier__c
                                                                    WHERE Apttus_QPConfig__LineItemId__c IN :setProposalLineItemId]) {
                
                //for products other than AP, price structure would be null
                if(pupt.Apttus_QPConfig__LineItemId__r.APT_Price_Structure__c != null)
                {
                    APT_R2T_Weight_Field_Mapping__c r2tWeightFieldMapping = mapR2TWeightFieldMapping.get(pupt.Apttus_QPConfig__LineItemId__r.APT_Price_Structure__c);
                    if(r2tWeightFieldMapping != null) {
                        if(r2tWeightFieldMapping.APT_Weight_Field__c == null || r2tWeightFieldMapping.APT_Weight_Value__c == null) {
                            setErrorMessage.add(APT_Constants.ERROR_INVALID_R2T_WEIGHT_FIELD_MAPPING + ' for ' + pupt.Apttus_QPConfig__LineItemId__r.APT_Price_Structure__c);
                        } else {
                            list<String> listWeightFields = r2tWeightFieldMapping.APT_Weight_Field__c.split(',');
                            list<String> listWeightValues = r2tWeightFieldMapping.APT_Weight_Value__c.split(',');
                            
                            if(listWeightFields != null && listWeightValues != null) {
                                Integer iCount = 0;
                                
                                for(String weightValue : listWeightValues) {
                                    //get field api
                                    String fieldAPIName = labelToAPIName.get(listWeightFields[iCount]);
                                    //system.debug('*** fieldAPIName ***'+fieldAPIName);
                                    
                                    //get line item rate card
                                    APT_Line_Item_Rate_Card__c lineItemRateCard = mapLineItemRateCard.get(pupt.Apttus_QPConfig__LineItemId__c + '~' + pupt.Apttus_QPConfig__Dimension1Value__c);
                                    system.debug('***lineItemRateCard => ' + lineItemRateCard);
                                    
                                    if(weightValue.contains('>') == true) {
                                        //String weightValue = '>5+Base';
                                        Integer iIndex = weightValue.indexOf('+');
                                        //system.debug('*** iIndex ***'+iIndex);
                                        String priceType = weightValue.subString(iIndex+1, weightValue.length());
                                        //system.debug('*** priceType ***'+priceType);
                                        weightValue = weightValue.subString(1, iIndex);
                                        //system.debug('*** weightValue ***'+weightValue);
                                        //weightValue = weightValue.subString(1, weightValue.length());
                                        if(lineItemRateCard != null && String.IsNotBlank(fieldAPIName) && String.IsNotBlank(weightValue) && String.IsNotBlank(pupt.Apttus_QPConfig__Dimension2Value__c ) && decimal.valueOf(pupt.Apttus_QPConfig__Dimension2Value__c) > decimal.valueOf(weightValue)) {
                                            if(String.IsNotBlank(priceType) && (priceType.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_BASE) == true || priceType.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT) == true) && String.IsNotBlank(pupt.Apttus_QPConfig__Dimension3Value__c ) && (pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_BASE) == true || pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT))) {
                                                //base or subsequent
                                                //system.debug('*** fieldAPIName3 ***'+fieldAPIName);
                                                //system.debug('*** value ***'+lineItemRateCard.get(fieldAPIName));
                                                String rate = (String) lineItemRateCard.get(fieldAPIName);
                                                if(String.IsNotBlank(rate)) {
                                                    pupt.Apttus_QPConfig__UsageRate__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__AdjustmentAmount__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__PriceOverride__c = decimal.valueOf(rate);
                                                }
                                                
                                                //listUpdatePUPT.add(pupt);
                                            } else if(String.IsNotBlank(priceType)  && priceType.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG) == true && String.IsNotBlank(pupt.Apttus_QPConfig__Dimension3Value__c)  && pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG) == true) {
                                                //per kg
                                                String rate = (String) lineItemRateCard.get(fieldAPIName);
                                                if(String.IsNotBlank(rate)) {
                                                    pupt.Apttus_QPConfig__UsageRate__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__AdjustmentAmount__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__PriceOverride__c = decimal.valueOf(rate);
                                                }
                                                
                                                //listUpdatePUPT.add(pupt);
                                            }
                                        } 
                                    } 
                                    else if(weightValue.contains('+') == true) {
                                        //String weightValue = '>5+Base';
                                        Integer iIndex = weightValue.indexOf('+');
                                        //system.debug('*** iIndex ***'+iIndex);
                                        String priceType = weightValue.subString(iIndex+1, weightValue.length());
                                        //system.debug('*** priceType ***'+priceType);
                                        weightValue = weightValue.subString(0, iIndex);
                                        //system.debug('*** weightValue ***'+weightValue);
                                        //weightValue = weightValue.subString(1, weightValue.length());
                                        if(lineItemRateCard != null && String.IsNotBlank(fieldAPIName) && String.IsNotBlank(weightValue) && String.IsNotBlank(pupt.Apttus_QPConfig__Dimension2Value__c)   && decimal.valueOf(pupt.Apttus_QPConfig__Dimension2Value__c) >= decimal.valueOf(weightValue)) {
                                            System.debug('priceType::' + priceType + 'fieldAPIName::' + fieldAPIName + 'pupt.Apttus_QPConfig__Dimension3Value__c::' + pupt.Apttus_QPConfig__Dimension3Value__c);
                                            if(String.IsNotBlank(priceType) && priceType.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_BASE) == true && String.IsNotBlank(pupt.Apttus_QPConfig__Dimension3Value__c)&& pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_BASE) == true) {
                                                //base or subsequent
                                                //system.debug('*** fieldAPIName3 ***'+fieldAPIName);
                                                //system.debug('*** value ***'+lineItemRateCard.get(fieldAPIName));
                                                String rate = (String) lineItemRateCard.get(fieldAPIName);
                                                if(String.IsNotBlank(rate)) {
                                                    pupt.Apttus_QPConfig__UsageRate__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__AdjustmentAmount__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__PriceOverride__c = decimal.valueOf(rate);
                                                }
                                            }
                                            else if(String.IsNotBlank(priceType) && priceType.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT) == true && String.IsNotBlank(pupt.Apttus_QPConfig__Dimension3Value__c) && pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT) == true) {
                                                //per kg
                                                String rate = (String) lineItemRateCard.get(fieldAPIName);
                                                if(String.IsNotBlank(rate)) {
                                                    pupt.Apttus_QPConfig__UsageRate__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__AdjustmentAmount__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__PriceOverride__c = decimal.valueOf(rate);
                                                }
                                            }
                                            else if(String.IsNotBlank(priceType) && priceType.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG) == true && String.IsNotBlank(pupt.Apttus_QPConfig__Dimension3Value__c) && pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG) == true) {
                                                //per kg
                                                String rate = (String) lineItemRateCard.get(fieldAPIName);
                                                if(String.IsNotBlank(rate)) {
                                                    pupt.Apttus_QPConfig__UsageRate__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__AdjustmentAmount__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__PriceOverride__c = decimal.valueOf(rate);
                                                }
                                            }
                                        } 
                                    }
                                    else {
                                        //validate weight
                                        System.debug('weightValue::::::: ' + weightValue);
                                        if(lineItemRateCard != null && String.IsNotBlank(fieldAPIName) && String.IsNotBlank(weightValue) && String.IsNotBlank(pupt.Apttus_QPConfig__Dimension2Value__c) && decimal.valueOf(pupt.Apttus_QPConfig__Dimension2Value__c) == decimal.valueOf(weightValue)) {
                                            if(String.IsNotBlank( pupt.Apttus_QPConfig__Dimension3Value__c ) && pupt.Apttus_QPConfig__Dimension3Value__c.equalsIgnoreCase(APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG) == false) {
                                                //base or subsequent
                                                //system.debug('*** fieldAPIName2 ***'+fieldAPIName);
                                                //system.debug('*** value ***'+lineItemRateCard.get(fieldAPIName));
                                                String rate = (String) lineItemRateCard.get(fieldAPIName);
                                                if(String.IsNotBlank(rate)) {
                                                    pupt.Apttus_QPConfig__UsageRate__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__AdjustmentAmount__c = decimal.valueOf(rate);
                                                    pupt.Apttus_QPConfig__PriceOverride__c = decimal.valueOf(rate);
                                                }
                                                
                                                //listUpdatePUPT.add(pupt);
                                            } else {
                                                //per kg
                                                pupt.Apttus_QPConfig__UsageRate__c = 0;
                                                pupt.Apttus_QPConfig__AdjustmentAmount__c = 0;
                                                pupt.Apttus_QPConfig__PriceOverride__c = 0;
                                                
                                                //listUpdatePUPT.add(pupt);
                                            }
                                        } 
                                    }
                                    iCount ++;
                                }
                            }
                        }
                    } else {
                        setErrorMessage.add(APT_Constants.ERROR_MISSING_R2T_WEIGHT_FIELD_MAPPING + ' for ' + pupt.Apttus_QPConfig__LineItemId__r.APT_Price_Structure__c);
                    }
                    listUpdatePUPT.add(pupt);
                }
            }
            
             //update proposal usage price tier
            if(listUpdatePUPT.size() > 0) {
                update listUpdatePUPT;
            }
            
        } catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage() + '\n Line Number is ' + ex.getLineNumber());          
        }
    }
    
    //finish
    global void finish(Database.BatchableContext bc) {
        //finish
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :bc.getJobId()];
        
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        //get email addresses
        APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
        String emailAddresses;            
        if(r2tSystemProperties != null) {            
            if(String.isNotBlank(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c)) {
                emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
            }
        } 
        
        list<String> toAddresses = new list<String>();
        if(String.isNotBlank(emailAddresses)) {
            toAddresses = emailAddresses.split(',');
        }
        //toAddresses.add(a.CreatedBy.Email);
        
        //String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('*** Proposal Usage Price Tier Update Batch Status ***');
        
        //Handle Batch Error Message    
        if(a.NumberOfErrors > 0) {
            setErrorMessage.add(a.ExtendedStatus);
        }
        Integer iErrorCount = setErrorMessage.size();
            
        String errorMessage;
        for(String errorMessage1 : setErrorMessage) {
            if(String.isNotBlank(errorMessage)) {
                errorMessage += '\n' + errorMessage1;
            } else {
                errorMessage = errorMessage1;
            }
        }
        
        //add Batch Error Message in Email
        if(String.isNotBlank(errorMessage)) {
            mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ iErrorCount + ' failures. \n\n Error(s) : \n ' + errorMessage);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } 
        //else {
        //    mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ iErrorCount + ' failures.');
        //}       
        
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
        String commaSepratedFields = '';

        for(String fieldName : fieldMap.keyset()){
            if(String.isBlank(commaSepratedFields)){
                commaSepratedFields = fieldName;
            }else{
                commaSepratedFields = commaSepratedFields + ', ' + fieldName;
            }
        }
        query = commaSepratedFields;
        //query = 'select ' + commaSepratedFields + ' from ';

        return query;
    } 
}