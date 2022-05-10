/**************************************************
Description: This apex class if handler class for apex trigger - APT_AgreementLineItemTrigger.
History:
2015-12-03 Garvita Rai Created
2016-10-07 Mausam Padhiyar Modified  , defect-1512
2019-05-31 anshul.goyal@auspost.com.au Modified | 31052019 | mark boolean custom fields (Regular_Speed_Service__c,Premium_Express_Speed_Service__c) on the operational schedule record
2019-12-19 Seth Heang Modified | Update operational schedule to capture attribute value for Local Pickup and Delivery Product, and populate agreement attribute value based on Line's Item attribute value into agreement line item's field
2020-01-27 Sheryl Crisostomo Modified | Added additional picklist value called Pickup & Delivery At the same time for Local Pickup and Delivery service type
2021-03-02 - Mathew Jose - Amended International & Local pick & delivery service's automation on DOS checkoxes to be based on relevant product codes & charge types (STP-4590)
2021-06-22 Naveen Rajanna Changed APT_LPD_Frequency__c picklist to APT_LPD_Multiple_Frequency__c  multi-picklist field
2021-10-28 Sautul Mehta - CI-96 Changes for APPC Contract Template Document Generation.
2022-04-26 Pradeep Jaiswal - CI-224 Populated Cubic Status, Cubic Factor and Existing APPC Customer Attributes
**************************************************/

public with sharing class APT_AgreementLineItemTriggerHandler{
    
    /**
     * before insert trigger event
     */
    public static String beforeInsertEvent(List<Apttus__AgreementLineItem__c> aliList) {
        try {
            //1084
            for(Apttus__AgreementLineItem__c ali : aliList) {
                if(ali.APT_Mark_All_Agreement_Line_Items_as_Old__c) {
                    ali.APT_New__c = false;
                }
            }
            //1084
            return APT_Constants.SUCCESS_LABEL;
        } catch(system.exception ex) {
            return ex.getMessage();
        }
    }
    
     /**
        This method will copy agreement lodgement point from quote and also creates agreement rate card.
        @params -
        aliList- list of Agreement line items        
     */
    /*
    public static void createAgreementChildRecords(List<Apttus__AgreementLineItem__c> aliList){
        try {
            Set<ID> agreementIDs = new Set<ID>();
            
            for(Apttus__AgreementLineItem__c ali : aliList){
                if(!ali.APT_Contract_Type__c){
                    agreementIDs.add(ali.Apttus__AgreementId__c);
                }
                system.Debug(ali.APT_Contract_Type__c + '--->ali');
                
            }
            
            //Map<ID, Apttus__APTS_Agreement__c> agreementMap = new Map<ID, Apttus__APTS_Agreement__c>([select id,RecordType.DeveloperName from Apttus__APTS_Agreement__c 
            //                                                                where id in: agreementIDs
            //                                                                And (RecordType.DeveloperName != 'APT_Community_Update_Pack') ]);
            //createALIChildRecords(agreementMap.keySet());
            //createALIChildRecords(agreementIDs);
            if(agreementIDs.size() > 0){
                //ID jobID = System.enqueueJob(new APT_AgreementLineItemChildQueueable(agreementIDs));
            }
        } catch (exception ex) {
            system.debug('Exception'+ ex.getMessage());
        }
    }
    */
    
    /**
     * after insert agreement line item
     */
    public static String afterInsertOrDeleteEvent(List<Apttus__AgreementLineItem__c> aliList, Boolean isInsert, Boolean isDelete) {
        try {
            
            //process builder to trigger
            set<Id> setAgreementLineItemId = new set<Id>();
            for(Apttus__AgreementLineItem__c ali : aliList) {
                setAgreementLineItemId.add(ali.Id);
            }
            
            //set<Id> setUniqueOSId = new set<Id>();
            map<Id, APT_Operational_Schedule__c> mapOS = new map<Id, APT_Operational_Schedule__c>();
            //list<APT_Operational_Schedule__c> listOS = new list<APT_Operational_Schedule__c>();
            APT_Operational_Schedule__c os;
            Apttus_CMConfig__AgreementProductAttributeValue__c newApav;
            // map used for 'Local Pickup and Delivery Services' Product that associate Agreement Line Item and Agreement Product Attribute Value
            map<Apttus__AgreementLineItem__c, Apttus_CMConfig__AgreementProductAttributeValue__c> mapLocalPickup = new map<Apttus__AgreementLineItem__c, Apttus_CMConfig__AgreementProductAttributeValue__c>();
             for(Apttus__AgreementLineItem__c ali : [SELECT Id, Apttus__ProductId__c, Apttus__ProductId__r.Name, Apttus__ProductId__r.ProductCode,
                                                    Apttus_CMConfig__ChargeType__c, Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c,
                                                    Apttus_CMConfig__OptionId__c, Apttus_CMConfig__OptionId__r.Name, Apttus_CMConfig__OptionId__r.ProductCode,
                                                    Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c,
                                                    Apttus__AgreementId__r.recordType.Name, Apttus__AgreementId__r.Operational_Schedule__c,
                                                    Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c, 
                                                    Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r.APT_Dangerous_Goods_Flag__c,
                                                    APT_Identical_Line__c, List_Price_Text__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Subsequent_Parcel_Discount__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Spend_Per_Annum__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Status__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Factor__c,  
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Existing_APPC_Customer__c, 
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Distance_Facility_Provided_In_Km__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Multiple_Frequency__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_1__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_2__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Service_Type__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_1__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_1__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_2__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_2__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_1__c,
                                                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_2__c
                                                    FROM Apttus__AgreementLineItem__c
                                                    WHERE Id IN :setAgreementLineItemId]) {
                
                if(mapOS.get(ali.Apttus__AgreementId__r.Operational_Schedule__c) != null) {
                    os = mapOS.get(ali.Apttus__AgreementId__r.Operational_Schedule__c);
                } else {
                    os = new APT_Operational_Schedule__c();
                }

                // initialise agreement product attribute value if empty, else skip
                if(mapLocalPickup.get(ali) != null){
                    newApav = mapLocalPickup.get(ali);
                }else{
                    newApav = new Apttus_CMConfig__AgreementProductAttributeValue__c();
                }
                
                //UMS
                if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES)
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_Unaddressed_Mail__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_Unaddressed_Mail__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //Print post
                if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_Print_Post__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_Print_Post__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //Local Pickup 
                if((String.isBlank(ali.Apttus_CMConfig__OptionId__c) 
                    && String.isNotBlank(ali.Apttus__ProductId__c) 
                    && null != ali.Apttus__ProductId__r.ProductCode 
                    && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) 
                    && (ali.Apttus__ProductId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_LOCAL_PICKUP_DELIVERY))
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) 
                    && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c 
                    && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) 
                    && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c 
                    && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c)
                    ) || ali.Apttus__ProductId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_APPC)) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_Parcel__c = true; //US-126
                        // Populate relevant attribute values from DerivedFrom field and save into an agreement product attribute value
                        newApav.APT_LPD_Service_Type__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Service_Type__c;
                        newApav.APT_LPD_Multiple_Frequency__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Multiple_Frequency__c;
                        newApav.APT_LPD_Distance_Facility_Provided_In_Km__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Distance_Facility_Provided_In_Km__c;
                        newApav.APT_LPD_Collection_Address_From_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_1__c;
                        newApav.APT_LPD_Collection_Address_From_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_2__c;
                        newApav.APT_LPD_From_Time_24_hour_clock_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_1__c;
                        newApav.APT_LPD_To_Time_24_hour_clock_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_1__c;
                        newApav.APT_LPD_From_Time_24_hour_clock_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_2__c;
                        newApav.APT_LPD_To_Time_24_hour_clock_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_2__c;
                        newApav.APT_LPD_Collection_Address_To_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_1__c;
                        newApav.APT_LPD_Collection_Address_To_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_2__c;
                        // Attach agreement line item to agreement product attribute value
                        newApav.Apttus_CMConfig__LineItemId__c = ali.id;

                        newApav.APT_Subsequent_Parcel_Discount__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Subsequent_Parcel_Discount__c;
                        newApav.APT_Min_Transit_Cover_Amount_Per_Article__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c;
                        newApav.APT_Min_Spend_Per_Annum__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Spend_Per_Annum__c;
                        newApav.APTS_Price_Structure__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c;
                        newApav.APT_Cubic_Factor__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Factor__c;
                        newApav.APT_Cubic_Status__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Status__c;
                        newApav.APT_Existing_APPC_Customer__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Existing_APPC_Customer__c;
                        
                        // Populate attribute values from DerivedFrom field into a new operational schedule
                        os.APT_LPD_Service_Type__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Service_Type__c;
                        os.APT_LPD_Multiple_Frequency__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Multiple_Frequency__c;
                        //mathew.jose@auspost.com.au added the following line to update the checkbox on DOS for the Local Pickup & Delivery.
                        os.APT_Courier__c = true;
                        // 'Service Type and Frequency' field is used to distinguish combination of:
                        // - Frequency: 'Scheduled' or 'Ad hoc'
                        // - Service Type: 'Delivery' or 'Pickup' or 'Pickup & Delivery At the same time'
                        // And is solely used to tick appropriate service type's checkboxes in the 'R2T Long Form Operational Schedule' template
                        if(String.isNotBlank(os.APT_LPD_Multiple_Frequency__c)){
                            if((os.APT_LPD_Service_Type__c).equalsIgnoreCase('Delivery Service')
                               || (os.APT_LPD_Service_Type__c).equalsIgnoreCase('Pickup Service')
                               || (os.APT_LPD_Service_Type__c).equalsIgnoreCase('Pickup & Delivery At the same time')){
                                    // Check Service types so that appropriate frequency such as 'Ad hoc' or 'Scheduled' can be assigned correctly
                                    List<String> multiFrequency = os.APT_LPD_Multiple_Frequency__c.split(';');
                                    if(multiFrequency.contains('Ad hoc')){
                                        os.APT_LPD_Service_Type_and_Frequency__c += os.APT_LPD_Service_Type__c + ' Ad hoc; ';
                                    }else{
                                        os.APT_LPD_Service_Type_and_Frequency__c += os.APT_LPD_Service_Type__c + ' Scheduled; ';
                                    }
                               }else{
                                // Adhoc is not available for other service types
                                   os.APT_LPD_Service_Type_and_Frequency__c += os.APT_LPD_Service_Type__c + '; ';
                               }
                        }
                        
                        // Populate the other relevent attribute values
                        os.APT_LPD_Distance_Facility_Provided_In_Km__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Distance_Facility_Provided_In_Km__c;
                        os.APT_LPD_Collection_Address_From_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_1__c;
                        os.APT_LPD_Collection_Address_From_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_2__c;
                        os.APT_LPD_From_Time_24_hour_clock_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_1__c;
                        os.APT_LPD_To_Time_24_hour_clock_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_1__c;
                        os.APT_LPD_From_Time_24_hour_clock_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_2__c;
                        os.APT_LPD_To_Time_24_hour_clock_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_2__c;
                        os.APT_LPD_Collection_Address_To_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_1__c;
                        os.APT_LPD_Collection_Address_To_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_2__c;
                    } 
                                   
                    if(isDelete) {
                        os.APT_Courier__c = false;
                    }
                    // Associate agreement line item with relevant  agreement product attribute value using a map
                    mapLocalPickup.put(ali, newApav);
                    mapOS.put(os.Id, os);
                }
                //eparcel
                if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_BUNDLE)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c
                  ) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_Parcel_Services_eParcel__c = true;
                        os.APT_Parcel__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_Parcel_Services_eParcel__c = false;
                        os.APT_Parcel__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //eparcel and dangerous goods flag = true
                if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_BUNDLE)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c
                    && null != ali.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c && String.isNotBlank(ali.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c)
                    && ali.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r.APT_Dangerous_Goods_Flag__c
                    && null != ali.Apttus_CMConfig__ChargeType__c && String.isNotBlank(ali.Apttus_CMConfig__ChargeType__c) && ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.CHARGE_TYPE_STANDARD_PRICE)) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_Parcel_Services_Special_Parcel__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_Parcel_Services_Special_Parcel__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //eparcel call for return
                if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_EPARCEL_CALL_FOR_RETURN) 
                    && null != ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_OPTION)
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_Parcel_Srvics_eParcel_Call_for_Retrn__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_Parcel_Srvics_eParcel_Call_for_Retrn__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //eParcel Post Return
                if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_EPARCEL_POST_RETURN) 
                    && null != ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_Parcel_Servcs_eParcel_Retrns_Service__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_Parcel_Servcs_eParcel_Retrns_Service__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                /**
                //defect 1512
                //Identity on Delivery Service
                if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_IDENTITY_ON_DELIVERY_SERVICE) 
                    && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_OPTION)
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_Parcl_Servcs_eParcl_Identity_on_Deli__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_Parcl_Servcs_eParcl_Identity_on_Deli__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                **/
                
                //eparcel express
                if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_BUNDLE)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c
                    && null != ali.Apttus_CMConfig__ChargeType__c && null != ali.Apttus_CMConfig__ChargeType__c && String.isNotBlank(ali.Apttus_CMConfig__ChargeType__c) && ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.CHARGE_TYPE_STANDARD_PRICE)) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_Parcel_Services_Express_Post_Parcel__c = true;
                        os.APT_Parcel_Services_Express_eParcel__c = true;
                        os.APT_Parcel__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_Parcel_Services_Express_Post_Parcel__c = false;
                        os.APT_Parcel_Services_Express_eParcel__c = false;
                        os.APT_Parcel__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //international postal
                //mathew.jose@auspost.com.au updated the if condition to include all the different international product codes & charge types.                
                if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) 
                    && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode)                      
                    && (ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE) || 
                        ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail) ||
                        ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS)) 
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus_CMConfig__ChargeType__c && String.isNotBlank(ali.Apttus_CMConfig__ChargeType__c)   
                    && (ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.BUNDLE_NAME_INTERNATIONAL) ||
                        ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new) ||
                        ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew))
                    && null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_BUNDLE)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_International_Postal__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_International_Postal__c = false;
                    }
                    /*
                    system.debug('*** estimated revenue ***'+ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c);
                    if(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c != null) {
                        os.APT_IP_Minimum_Revenue_per_annum__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c;
                    }
                    */
                    
                    mapOS.put(os.Id, os);
                }
                
                
                //registered post
                if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT) 
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        os.APT_IP_Services_Registered_Post__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_IP_Services_Registered_Post__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //express courier international
                if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT) 
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) { 
                        os.APT_IP_Servcs_Exprss_Courier_Internatnal__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_IP_Servcs_Exprss_Courier_Internatnal__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //air mail
                //updated by spingali to use AIRMAIL_INTERNATIONAL_PRODUCT
                if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT) 
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {  
                        os.APT_IP_Services_Airmail__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_IP_Services_Airmail__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //pack and track
                if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT) 
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {  
                        os.APT_IP_Services_Pack_and_Track__c = true;
                    } 
                    
                    if(isDelete) {
                        os.APT_IP_Services_Pack_and_Track__c = false;
                    }
                    
                    mapOS.put(os.Id, os);
                }
                
                //min collection value
                if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_MIN_COLLECTION_VALUE) 
                    && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                    && null != ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_OPTION)
                    && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
                    
                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {  
                        os.APT_Parcel_Minimum_Collection_Value__c = ali.List_Price_Text__c;
                    } 
                    
                    if(isDelete) {
                        os.APT_Parcel_Minimum_Collection_Value__c = null;
                    }
                    
                    mapOS.put(os.Id, os);
                }

               //31052019- fetch priority product codes from the custom metadata 'Priority_Product_Name__mdt'
                Set <String> priorityProdCodes = new  Set <String>();
                for(Priority_Product_Name__mdt ppName:  [SELECT MasterLabel, QualifiedApiName FROM Priority_Product_Name__mdt]){
                    priorityProdCodes.add(ppName.QualifiedApiName);
                }

                //31052019- check the prerequisite for the operational schedule and then set the boolean flags for the priority products
                if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && priorityProdCodes.contains(ali.Apttus__ProductId__r.ProductCode)
                        && String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
                        && null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
                        && null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c
                 ) {

                    os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
                    if(isInsert) {
                        if(ali.Apttus__ProductId__r.ProductCode==APT_Constants.PRODUCT_CODE_PriorityProd_RegularSpeedService){
                            os.Regular_Speed_Service__c = true;
                        }
                        else if(ali.Apttus__ProductId__r.ProductCode==APT_Constants.PRODUCT_CODE_PriorityProd_PremExpSpeedService){
                            os.Premium_Express_Speed_Service__c = true;
                        }
                    }

                    if(isDelete) {
                            os.Regular_Speed_Service__c = false;
                            os.Premium_Express_Speed_Service__c = false; 
                    }

                    mapOS.put(os.Id, os);
                }
            }
            
            if(mapOS != null && mapOS.values().size() > 0) {
                update mapOS.values();
            }
            //process builder to trigger

            // Create New Agreement Product Attribute Value on Agreement Line Item object from Line Item's Attribute Value fields
            if(!mapLocalPickup.isEmpty()){
                insert mapLocalPickup.values();
                List<Apttus__AgreementLineItem__c> listAli = new List<Apttus__AgreementLineItem__c>();
                // Update Agreement line item to attach associated agreement product attribute object from the map
                for(Apttus__AgreementLineItem__c newALI : mapLocalPickup.keySet()){
                    newALI.Apttus_CMConfig__AttributeValueId__c = mapLocalPickup.get(newALI).id;
                    listAli.add(newALI);
                }
                update listAli;
            }
            
            return APT_Constants.SUCCESS_LABEL;
        } catch(system.exception ex) {
            return ex.getMessage();
        }
    }
}