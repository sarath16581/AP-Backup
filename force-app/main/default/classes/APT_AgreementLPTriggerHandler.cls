/***
* Author: Himanshu
* This class is helper to Agreement Lodgement point Trigger
* 
* Last Modified By - Mausam Padhiyar
* Last Modified Date - 20th Aug, 2016 | Defect - 1509 | Parcel and Express Parcel Lodgement Points
*
* Last Modified By - Mausam Padhiyar
* Last Modified Date - 7th Sept, 2016 | International Lodgement Points - Digital nad Non-Digital
* 
* Last Modified By - Kushal Bhalodiya
* Last Modified Date - 26th Sept, 2016 | Defect 1428
*
* Last Modified By - Mausam Padhiyar
* Last Modified Date - 12th Oct, 2016 | Defect 1661 | Populate Print Post and UMS Lodgement Point Ids
*
* Last Modified By - Seth Heang
* Last Modified Date - 19th Oct, 2019 | Populate Local Pickup and Delivery Service Lodgement Point Ids
*
* Last Modified By - Mahesh Patel
* Last Modified Date - 1st Mar, 2021 | STP-4673 Update TrackMail Lodgement Point on Operational Schedule record associated with contract
**/
public with sharing class APT_AgreementLPTriggerHandler {
    
    /**
      This method updates operational Schedules based on New LP added to the contract.
    **/
    public static void updateOperationalScheduleOnLPChange(List<APT_Agreement_Lodgement_Point__c> agreementLPList){
        
        try {
            Set<ID> agreementIds = new Set<ID>();
            for(APT_Agreement_Lodgement_Point__c alp : agreementLPList){
                agreementIds.add(alp.APT_Agreement__c);
            }
            
            
            Map<ID, APT_Operational_Schedule__c> operationalScheduleMapToBeUpdated = new Map<ID, APT_Operational_Schedule__c>();
            for(APT_Agreement_Lodgement_Point__c lp : [select id,APT_Lodgement_Point_Lookup__r.Name,
                                                    APT_Billing_Account__r.LEGACY_ID__c,APT_Agreement_Line_Item__c,
                                                    APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_International_Letters__c,
                                                    APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c,
                                                    APT_Lodgement_Point_Lookup__c, APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode,
                                                    APT_Agreement__c, APT_Agreement__r.Operational_Schedule__c,
                                                    APT_Agreement_Line_Item__r.Apttus__ProductId__r.Name,
                                                    APT_Agreement_Line_Item__r.Apttus__ProductId__r.APT_Product_type__c,
                                                    APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c,
                                                    APT_Lodgement_Point_Lookup__r.APT_GA_Code__c
                                                    from APT_Agreement_Lodgement_Point__c 
                                                    where APT_Agreement__c in: agreementIds
                                                    And APT_Status__c <>: APT_Constants.INACTIVE]){
                
                String dosID = lp.APT_Agreement__r.Operational_Schedule__c;
                
                APT_Operational_Schedule__c dos;
                if(operationalScheduleMapToBeUpdated.containsKey(dosID)){
                    
                    dos = operationalScheduleMapToBeUpdated.get(dosID);
                } else if(!String.isEmpty(dosID)){
                    
                    dos = new APT_Operational_Schedule__c();
                    dos.Id = dosID;
                    operationalScheduleMapToBeUpdated.put(dosID, dos);
                    dos.APT_Parcel_Lodgement_Points__c = APT_Constants.EMPTY_STRING;
                    dos.APT_International_Lodgement_Points__c = APT_Constants.EMPTY_STRING;
                    dos.APT_Print_Post_Lodgement_Points__c = APT_Constants.EMPTY_STRING;
                    dos.APT_UMS_Lodgement_Points__c = APT_Constants.EMPTY_STRING;
                    dos.APT_International_Lodgement_Point_Ids__c = APT_Constants.EMPTY_STRING;
                    dos.APT_Parcel_Lodgement_Point_Ids__c = APT_Constants.EMPTY_STRING;
                    dos.APT_Distribution_Channel_Codes__c = APT_Constants.EMPTY_STRING;
                    dos.APT_GA_Codes__c = APT_Constants.EMPTY_STRING;
                    dos.APT_LPD_Lodgement_Points__c = APT_Constants.EMPTY_STRING;
                    dos.APT_LPD_Lodgement_Point_Ids__c = APT_Constants.EMPTY_STRING;
                    dos.APT_TrackMail_Lodgement_Point_Ids__c = APT_Constants.EMPTY_STRING;
                    dos.APT_TrackMail_Lodgement_Points__c = APT_Constants.EMPTY_STRING;
                    
                    
                } else{
                    system.debug(Logginglevel.ERROR, 'Operational Schedule not found for current agreement');
                    continue;
                }
                
                /*
                //Defect 970 Start
                if(String.IsNotblank(lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c)
                        && !(dos.APT_GA_Codes__c).contains(lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c)
                        && dos.APT_GA_Codes__c.length() < 45){
                    dos.APT_GA_Codes__c= dos.APT_GA_Codes__c + lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c + ';';
                 
                }
                
                if(String.IsNotblank(lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c)
                        && !(dos.APT_Distribution_Channel_Codes__c ).contains(lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c)
                        && dos.APT_Distribution_Channel_Codes__c.length() < 200){
                    dos.APT_Distribution_Channel_Codes__c = dos.APT_Distribution_Channel_Codes__c 
                                                            + lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c+ ';';
                 
                }
                
                                                           
                // defect 970 End
                */
                
                if(null != lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c && String.IsNotblank(lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c)
                        && !(dos.APT_GA_Codes__c).contains(lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c)
                        && (dos.APT_GA_Codes__c).countMatches(APT_Constants.SEPERATOR_SEMI_COLON) <=4){
                    dos.APT_GA_Codes__c= dos.APT_GA_Codes__c + lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c + APT_Constants.SEPERATOR_SEMI_COLON;
                 
                } else if(null != lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c && String.IsNotblank(lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c)
                        && !(dos.APT_GA_Codes__c).contains(lp.APT_Lodgement_Point_Lookup__r.APT_GA_Code__c)
                        && (dos.APT_GA_Codes__c).countMatches(APT_Constants.SEPERATOR_SEMI_COLON) >4
                        && !(dos.APT_GA_Codes__c).contains(APT_Constants.multiple_values)){
                     dos.APT_GA_Codes__c= dos.APT_GA_Codes__c + APT_Constants.multiple_values + APT_Constants.SEPERATOR_SEMI_COLON;       
                } else {}
                
                if(null != lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c && String.IsNotblank(lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c)
                        && !(dos.APT_Distribution_Channel_Codes__c ).contains(lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c)
                        && (dos.APT_Distribution_Channel_Codes__c).countMatches(APT_Constants.SEPERATOR_SEMI_COLON) <=4){
                    dos.APT_Distribution_Channel_Codes__c = dos.APT_Distribution_Channel_Codes__c 
                                                            + lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c+ APT_Constants.SEPERATOR_SEMI_COLON; 
                 
                } else if(null != lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c && String.IsNotblank(lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c)
                        && !(dos.APT_Distribution_Channel_Codes__c ).contains(lp.APT_Lodgement_Point_Lookup__r.APT_Distribution_Channel__c)
                        && (dos.APT_Distribution_Channel_Codes__c).countMatches(APT_Constants.SEPERATOR_SEMI_COLON) >4
                        && !(dos.APT_Distribution_Channel_Codes__c).contains(APT_Constants.multiple_values)){
                    dos.APT_Distribution_Channel_Codes__c = dos.APT_Distribution_Channel_Codes__c 
                                                            + APT_Constants.multiple_values + APT_Constants.SEPERATOR_SEMI_COLON; 
                 
                } else {}
                
                String lpName = lp.APT_Lodgement_Point_Lookup__r.Name;
                String billingAccountNumber = String.IsNotBlank(lp.APT_Billing_Account__r.LEGACY_ID__c) 
                                                ? APT_Constants.SEPERATOR_COLON + lp.APT_Billing_Account__r.LEGACY_ID__c +  APT_Constants.SEPERATOR_COLON 
                                                : APT_Constants.SEPERATOR_COLON;
                String lpString = lpName + billingAccountNumber;
                
                //generic lp case
                if(String.isEmpty(lp.APT_Agreement_Line_Item__c)){
                    
                    if(!(dos.APT_Parcel_Lodgement_Points__c).contains(lpString)){
                        dos.APT_Parcel_Lodgement_Points__c = dos.APT_Parcel_Lodgement_Points__c + lpString;
                    }
                    if(!(dos.APT_International_Lodgement_Points__c).contains(lpString)){
                        dos.APT_International_Lodgement_Points__c = dos.APT_International_Lodgement_Points__c + lpString;
                    }
                    if(!(dos.APT_Print_Post_Lodgement_Points__c).contains(lpString)){
                        dos.APT_Print_Post_Lodgement_Points__c = dos.APT_Print_Post_Lodgement_Points__c + lpString;
                    }
                    if(!(dos.APT_UMS_Lodgement_Points__c).contains(lpString)){
                        dos.APT_UMS_Lodgement_Points__c = dos.APT_UMS_Lodgement_Points__c + lpString;
                    }
                    // Local Pickup - populate lodgement point
                    if(!(dos.APT_LPD_Lodgement_Points__c).contains(lpString)){
                        dos.APT_LPD_Lodgement_Points__c = dos.APT_LPD_Lodgement_Points__c + lpString;
                    }

                    //STP-4673 Update TrackMail Lodgement Point on Operational Schedule record associated with contract
                    if(!(dos.APT_TrackMail_Lodgement_Points__c).contains(lpString)){
                        dos.APT_TrackMail_Lodgement_Points__c = dos.APT_TrackMail_Lodgement_Points__c + lpString;
                    }
                    
                    //1661
                    if(String.isBlank(dos.APT_UMS_Lodgement_Point_Ids__c)) {
                      dos.APT_UMS_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if(!dos.APT_UMS_Lodgement_Point_Ids__c.contains(lp.APT_Lodgement_Point_Lookup__c)) {
                      dos.APT_UMS_Lodgement_Point_Ids__c = dos.APT_UMS_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c;
                    } else { }
                    
                    if(String.isBlank(dos.APT_Print_Post_Lodgement_Point_Ids__c)) {
                      dos.APT_Print_Post_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if(!dos.APT_Print_Post_Lodgement_Point_Ids__c.contains(lp.APT_Lodgement_Point_Lookup__c)) {
                      dos.APT_Print_Post_Lodgement_Point_Ids__c = dos.APT_Print_Post_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c;
                    } else { }
                    //1661
                    
                    // Local Pickup - populate lodgement point id
                    if(String.isBlank(dos.APT_LPD_Lodgement_Point_Ids__c)) {
                      dos.APT_LPD_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if(!dos.APT_LPD_Lodgement_Point_Ids__c.contains(lp.APT_Lodgement_Point_Lookup__c)) {
                      dos.APT_LPD_Lodgement_Point_Ids__c = dos.APT_LPD_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c;
                    } 

                    if(String.IsBlank(dos.APT_Parcel_Lodgement_Point_Ids__c)) {
                        dos.APT_Parcel_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if( !(dos.APT_Parcel_Lodgement_Point_Ids__c).contains(lp.APT_Lodgement_Point_Lookup__c)){
                        dos.APT_Parcel_Lodgement_Point_Ids__c = dos.APT_Parcel_Lodgement_Point_Ids__c +  APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c; 
                    } else {
                        
                    }
                    
                    //Digital | Lodgement Points
                    if(String.IsBlank(dos.APT_International_Lodgement_Point_Ids__c)) {
                        dos.APT_International_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if( !(dos.APT_International_Lodgement_Point_Ids__c).contains(lp.APT_Lodgement_Point_Lookup__c)){
                        dos.APT_International_Lodgement_Point_Ids__c = dos.APT_International_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c;                 
                    } else {}
                    
                    //Non-Digital | Lodgement Points
                    if(String.IsBlank(dos.APT_Non_Digital_International_LP_Ids__c)) {
                        dos.APT_Non_Digital_International_LP_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if( !(dos.APT_Non_Digital_International_LP_Ids__c).contains(lp.APT_Lodgement_Point_Lookup__c)){
                        dos.APT_Non_Digital_International_LP_Ids__c = dos.APT_Non_Digital_International_LP_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c; 
                    } else {}
                             
                    //STP-4673 Update TrackMail Lodgement Point on Operational Schedule record associated with contract
                    if(String.IsBlank(dos.APT_TrackMail_Lodgement_Point_Ids__c)) {
                        dos.APT_TrackMail_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if( !(dos.APT_TrackMail_Lodgement_Point_Ids__c).contains(lp.APT_Lodgement_Point_Lookup__c)){
                        dos.APT_TrackMail_Lodgement_Point_Ids__c = dos.APT_TrackMail_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c; 
                    }
                } 
                //1509
                else if((APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD).equalsIgnoreCase(lp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode)){
                    //parcels lp
                    if(String.IsBlank(dos.APT_Parcel_Lodgement_Point_Ids__c)) {
                        dos.APT_Parcel_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if(null != dos.APT_Parcel_Lodgement_Point_Ids__c && String.IsNotBlank(dos.APT_Parcel_Lodgement_Point_Ids__c) && !(dos.APT_Parcel_Lodgement_Point_Ids__c).contains(lp.APT_Lodgement_Point_Lookup__c)){
                        dos.APT_Parcel_Lodgement_Point_Ids__c = dos.APT_Parcel_Lodgement_Point_Ids__c +  APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c; 
                    }  else {}
                    
                    if(!(dos.APT_Parcel_Lodgement_Points__c).contains(lpString)){
                        dos.APT_Parcel_Lodgement_Points__c = dos.APT_Parcel_Lodgement_Points__c + lpString;
                    }  else {}                              
                } 
                else if((APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS).equalsIgnoreCase(lp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode)){
                    //parcels lp
                    if(String.IsBlank(dos.APT_Express_Parcel_Lodgement_Point_Ids__c)) {
                        dos.APT_Express_Parcel_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if(null != dos.APT_Express_Parcel_Lodgement_Point_Ids__c && String.IsNotBlank(dos.APT_Express_Parcel_Lodgement_Point_Ids__c) && !(dos.APT_Express_Parcel_Lodgement_Point_Ids__c).contains(lp.APT_Lodgement_Point_Lookup__c)){
                        dos.APT_Express_Parcel_Lodgement_Point_Ids__c = dos.APT_Express_Parcel_Lodgement_Point_Ids__c +  APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c; 
                    }  else {}
                    
                    if(!(dos.APT_Parcel_Lodgement_Points__c).contains(lpString)){
                        dos.APT_Parcel_Lodgement_Points__c = dos.APT_Parcel_Lodgement_Points__c + lpString;
                    }  else {}                              
                }
                //1509
                //International Bundle fields are reused for new International Bundle as we cannot have a legacy digital bundle and new digital bundle in 1 Agreement
                else if((APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE).equalsIgnoreCase(lp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode)||
                    (APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE).equalsIgnoreCase(lp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode)||
                      (APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL ).equalsIgnoreCase(lp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode)){
                    //Digital | International Lodgement Point Ids
                    if(lp.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c) {
                        if(String.IsBlank(dos.APT_International_Lodgement_Point_Ids__c)) {
                            dos.APT_International_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                        } else if( !(dos.APT_International_Lodgement_Point_Ids__c).contains(lp.APT_Lodgement_Point_Lookup__c)){
                            dos.APT_International_Lodgement_Point_Ids__c = dos.APT_International_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c;                     
                        } else {}
                    }
                    //Non-Digital | International Lodgement Point Ids
                    else if(lp.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_International_Letters__c) {
                        if(String.IsBlank(dos.APT_Non_Digital_International_LP_Ids__c)) {
                            dos.APT_Non_Digital_International_LP_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                        } else if( !(dos.APT_Non_Digital_International_LP_Ids__c).contains(lp.APT_Lodgement_Point_Lookup__c)){
                            dos.APT_Non_Digital_International_LP_Ids__c = dos.APT_Non_Digital_International_LP_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c; 
                        } else {}
                    } else {}
                    
                    //international lp
                    if(!(dos.APT_International_Lodgement_Points__c).contains(lpString)){
                        dos.APT_International_Lodgement_Points__c = dos.APT_International_Lodgement_Points__c + lpString;
                    } else {}
                    
                } 
                 else if((APT_Constants.PRODUCT_CODE_PRINT_POST).equalsIgnoreCase(lp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode)){
                    //print post lp
                    if(!(dos.APT_Print_Post_Lodgement_Points__c).contains(lpString)){
                        dos.APT_Print_Post_Lodgement_Points__c = dos.APT_Print_Post_Lodgement_Points__c + lpString;
                    } else {}
                    
                    
                    //1661
                    if(String.isBlank(dos.APT_Print_Post_Lodgement_Point_Ids__c)) {
                      dos.APT_Print_Post_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if(!dos.APT_Print_Post_Lodgement_Point_Ids__c.contains(lp.APT_Lodgement_Point_Lookup__c)) {
                      dos.APT_Print_Post_Lodgement_Point_Ids__c = dos.APT_Print_Post_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c;
                    } else { }
                    //1661                   
                    
                } else if((APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES).equalsIgnoreCase(lp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode)){
                    //UMS lp
                    
                    if(!(dos.APT_UMS_Lodgement_Points__c).contains(lpString)){
                        dos.APT_UMS_Lodgement_Points__c = dos.APT_UMS_Lodgement_Points__c + lpString;
                    } else {}
                    
                    
                    //1661
                    if(String.isBlank(dos.APT_UMS_Lodgement_Point_Ids__c)) {
                      dos.APT_UMS_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if(!dos.APT_UMS_Lodgement_Point_Ids__c.contains(lp.APT_Lodgement_Point_Lookup__c)) {
                      dos.APT_UMS_Lodgement_Point_Ids__c = dos.APT_UMS_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c;
                    } else { }
                    //1661
                    
                }
                else if((APT_Constants.PRODUCT_CODE_LOCAL_PICKUP_DELIVERY).equalsIgnoreCase(lp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode)){
                    //Local Pickup lp
                    
                    // populate lodgement point
                    if(!(dos.APT_LPD_Lodgement_Points__c).contains(lpString)){
                        dos.APT_LPD_Lodgement_Points__c = dos.APT_LPD_Lodgement_Points__c + lpString;
                    } 
                    
                    // populate lodgement point id
                    if(String.isBlank(dos.APT_LPD_Lodgement_Point_Ids__c)) {
                      dos.APT_LPD_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if(!dos.APT_LPD_Lodgement_Point_Ids__c.contains(lp.APT_Lodgement_Point_Lookup__c)) {
                      dos.APT_LPD_Lodgement_Point_Ids__c = dos.APT_LPD_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c;
                    } 
                    
                }
                //STP-4673 Update TrackMail Lodgement Point on Operational Schedule record associated with contract
                else if((APT_Constants.OPERATIONAL_SCHEDULE_TRACKMAIL_PRODUCT_TYPE).equalsIgnoreCase(lp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.APT_Product_type__c)){
                    //Populate lodgement point
                    if(!(dos.APT_TrackMail_Lodgement_Points__c).contains(lpString)){
                        dos.APT_TrackMail_Lodgement_Points__c = dos.APT_TrackMail_Lodgement_Points__c + lpString;
                    } 
                    
                    // populate lodgement point id
                    if(String.isBlank(dos.APT_TrackMail_Lodgement_Point_Ids__c)) {
                      dos.APT_TrackMail_Lodgement_Point_Ids__c = lp.APT_Lodgement_Point_Lookup__c;
                    } else if(!dos.APT_TrackMail_Lodgement_Point_Ids__c.contains(lp.APT_Lodgement_Point_Lookup__c)) {
                      dos.APT_TrackMail_Lodgement_Point_Ids__c = dos.APT_TrackMail_Lodgement_Point_Ids__c + APT_Constants.SEPERATOR_COMMA + lp.APT_Lodgement_Point_Lookup__c;
                    } 
                }                
            }
            if(operationalScheduleMapToBeUpdated.values().size() > 0){
                update operationalScheduleMapToBeUpdated.values();
            }
        } catch (Exception ex) {
            //system.debug('Exception'+ex.getMessage());
        }
    }
  /**
      Defect 1428
    **/
    public static String updateLPDetailsToLineItem(list<APT_Agreement_Lodgement_Point__c> listAgreementLP) {
        try 
        {
            Set<ID> setAgreementID = new Set<ID>();
            for(APT_Agreement_Lodgement_Point__c agrLP : listAgreementLP)
            {
                setAgreementID.add(agrLP.APT_Agreement__c);
            }
            Map<ID,APT_Agreement_Lodgement_Point__c> mapAllAgreementLP = new Map<ID,APT_Agreement_Lodgement_Point__c>([select ID,APT_Status__c, APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, APT_Lodgement_Point_Lookup__c, APT_Billing_Account__c, APT_Cash_Account__c, APT_Charge_Account__c, APT_Sub_Account__c, APT_Agreement_Line_Item__r.Apttus__ProductId__c from APT_Agreement_Lodgement_Point__c where APT_Agreement__c IN:setAgreementID]);
            //AND APT_Status__c = :APT_Constants.ACTIVE
            Map<ID, List<APT_Agreement_Lodgement_Point__c>> mapProductToAgrLP = new Map<ID, List<APT_Agreement_Lodgement_Point__c>>();
            for(APT_Agreement_Lodgement_Point__c agrLP : mapAllAgreementLP.values())
            {
                if(null != agrLP.APT_Agreement_Line_Item__r.Apttus__ProductId__c && mapProductToAgrLP.containsKey(agrLP.APT_Agreement_Line_Item__r.Apttus__ProductId__c))
                {
                    mapProductToAgrLP.get(agrLP.APT_Agreement_Line_Item__r.Apttus__ProductId__c).add(agrLP);
                }
                else if(null != agrLP.APT_Agreement_Line_Item__r.Apttus__ProductId__c)
                {
                    mapProductToAgrLP.put(agrLP.APT_Agreement_Line_Item__r.Apttus__ProductId__c, new List<APT_Agreement_Lodgement_Point__c>{agrLP});
                }
            }
            Set<ID> setProductIDs = new Set<ID>();
            for(APT_Agreement_Lodgement_Point__c agrLP : listAgreementLP)
            {
                if(mapAllAgreementLP.containsKey(agrLP.ID) && mapAllAgreementLP.get(agrLP.ID).APT_Agreement_Line_Item__c != null)
                {
                    setProductIDs.add(mapAllAgreementLP.get(agrLP.ID).APT_Agreement_Line_Item__r.Apttus__ProductId__c);
                }
            }
            Map<ID, String> mapLineToLPs = new Map<ID,String>();
            Map<ID, String> mapLineToLP_BillingAccount_IDs = new Map<ID,String>();
            Map<ID, String> mapLineToLP_ChargeAccount_IDs = new Map<ID,String>();
            Map<ID, String> mapLineToLP_CashAccount_IDs = new Map<ID,String>();
            Map<ID, String> mapLineToLP_SubAccount_IDs = new Map<ID,String>();

            for(ID prodID : setProductIDs)
            {
                for(APT_Agreement_Lodgement_Point__c objAgrLP : mapProductToAgrLP.get(prodID))
                {
                    if(null != objAgrLP.APT_Agreement_Line_Item__c && null != objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c)
                    {
                        if(objAgrLP.APT_Status__c == APT_Constants.ACTIVE && mapLineToLPs.containsKey(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c))
                        {
                            mapLineToLPs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, mapLineToLPs.get(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c) + ',' + objAgrLP.APT_Lodgement_Point_Lookup__c);
                            mapLineToLP_BillingAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, mapLineToLP_BillingAccount_IDs.get(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c) + objAgrLP.APT_Lodgement_Point_Lookup__c + ':' + objAgrLP.APT_Billing_Account__c+';');
                            mapLineToLP_ChargeAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, mapLineToLP_ChargeAccount_IDs.get(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c) + objAgrLP.APT_Lodgement_Point_Lookup__c + ':' + objAgrLP.APT_Charge_Account__c+';');
                            mapLineToLP_CashAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, mapLineToLP_CashAccount_IDs.get(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c) + objAgrLP.APT_Lodgement_Point_Lookup__c + ':' + objAgrLP.APT_Cash_Account__c+';');
                            mapLineToLP_SubAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, mapLineToLP_SubAccount_IDs.get(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c) + objAgrLP.APT_Lodgement_Point_Lookup__c + ':' + objAgrLP.APT_Sub_Account__c+';');
                        }
                        else if(objAgrLP.APT_Status__c == APT_Constants.ACTIVE)
                        {
                            mapLineToLPs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, objAgrLP.APT_Lodgement_Point_Lookup__c);
                            mapLineToLP_BillingAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, objAgrLP.APT_Lodgement_Point_Lookup__c + ':' + objAgrLP.APT_Billing_Account__c+';');
                            mapLineToLP_ChargeAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, objAgrLP.APT_Lodgement_Point_Lookup__c + ':' + objAgrLP.APT_Charge_Account__c+';');
                            mapLineToLP_CashAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, objAgrLP.APT_Lodgement_Point_Lookup__c + ':' + objAgrLP.APT_Cash_Account__c+';');
                            mapLineToLP_SubAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, objAgrLP.APT_Lodgement_Point_Lookup__c + ':' + objAgrLP.APT_Sub_Account__c+';');
                        }
                        else
                        {
                            mapLineToLPs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c,'');
                            mapLineToLP_BillingAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, '');
                            mapLineToLP_ChargeAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, '');
                            mapLineToLP_CashAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, '');
                            mapLineToLP_SubAccount_IDs.put(objAgrLP.APT_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, '');
                        }
                    }
                }
            }
            List<Apttus_Config2__LineItem__c> listLineToUpdate = new List<Apttus_Config2__LineItem__c>();
            Boolean lpAdded = false;
            for(ID lineItemID : mapLineToLPs.keySet())
            {
                lpAdded = false;
                if(null != mapLineToLPs.get(lineItemID))
                {
                    lpAdded = true;
                }
                listLineToUpdate.add(new Apttus_Config2__LineItem__c(ID = lineItemID, APT_Added_LP__c = lpAdded, APT_Selected_LP__c = mapLineToLPs.get(lineItemID), APT_Agreement_Billing_Account_IDs__c = mapLineToLP_BillingAccount_IDs.get(lineItemID), APT_Agreement_Charge_Account_IDs__c = mapLineToLP_ChargeAccount_IDs.get(lineItemID), APT_Agreement_Cash_Account_IDs__c = mapLineToLP_CashAccount_IDs.get(lineItemID), APT_Agreement_Sub_Account_IDs__c = mapLineToLP_SubAccount_IDs.get(lineItemID)));
            }
            if(listLineToUpdate.size() > 0)
            {
                update listLineToUpdate;
            }
            return APT_Constants.SUCCESS_LABEL;
        } 
        catch(Exception ex) 
        {
            return ex.getMessage();
        }
    }
    
    /**
      Defect 1428
    **/
    public static String updateLPDetailsFromLineItem(List<APT_Agreement_Lodgement_Point__c> MapNewAgreementLP) {
        try 
        {
            Set<ID> setAgreementLineItemID = new Set<ID>();
            for(APT_Agreement_Lodgement_Point__c agrLP : MapNewAgreementLP)
            {
                setAgreementLineItemID.add(agrLP.APT_Agreement_Line_Item__c);
            }
            Map<ID,Apttus__AgreementLineItem__c> mapAgreementLineItem = new Map<ID,Apttus__AgreementLineItem__c>([select ID,Apttus_CMConfig__DerivedFromId__c, Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Billing_Account_IDs__c, Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Charge_Account_IDs__c, Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Cash_Account_IDs__c, Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Sub_Account_IDs__c from Apttus__AgreementLineItem__c where ID IN : setAgreementLineItemID]);
            List<String> listLPBillingData = new List<String>();
            List<String> listLPChargeData = new List<String>();
            List<String> listLPCashData = new List<String>();
            List<String> listLPSubData = new List<String>();
            Map<String, String> mapLPtoBillingAccount = new Map<String, String>();
            Map<String, String> mapLPtoChargeAccount = new Map<String, String>();
            Map<String, String> mapLPtoCashAccount = new Map<String, String>();
            Map<String, String> mapLPtoSubAccount = new Map<String, String>();
            for(APT_Agreement_Lodgement_Point__c agrLP : MapNewAgreementLP)
            {
                listLPBillingData.clear();
                listLPChargeData.clear();
                listLPCashData.clear();
                listLPSubData.clear();
                if(mapAgreementLineItem.containsKey(agrLP.APT_Agreement_Line_Item__c) && null != mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__c)
                {
                    if(null != mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Billing_Account_IDs__c && '' != mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Billing_Account_IDs__c)
                    {
                        listLPBillingData = mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Billing_Account_IDs__c.split(';');
                        for(String LPData : listLPBillingData)
                        {
                            listLPBillingData = LPData.split(':');
                            for(integer i = 0; i < listLPBillingData.size()-1; i++)
                            {
                                mapLPtoBillingAccount.put(listLPBillingData[i],listLPBillingData[i+1]);
                            }
                        }
                    }
                    if(null != mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Charge_Account_IDs__c && '' != mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Charge_Account_IDs__c)
                    {
                        listLPChargeData = mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Charge_Account_IDs__c.split(';');
                        for(String LPData : listLPChargeData)
                        {
                            listLPChargeData = LPData.split(':');
                            for(integer i = 0; i < listLPChargeData.size()-1; i++)
                            {
                                mapLPtoChargeAccount.put(listLPChargeData[i],listLPChargeData[i+1]);
                            }
                        }
                    }
                    if(null != mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Cash_Account_IDs__c && '' != mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Cash_Account_IDs__c)
                    {
                        listLPCashData = mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Cash_Account_IDs__c.split(';');
                        for(String LPData : listLPCashData)
                        {
                            listLPCashData = LPData.split(':');
                            for(integer i = 0; i < listLPCashData.size()-1; i++)
                            {
                                mapLPtoCashAccount.put(listLPCashData[i],listLPCashData[i+1]);
                            }
                        }
                    }
                    if(null != mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Sub_Account_IDs__c && '' != mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Sub_Account_IDs__c)
                    {
                        listLPSubData = mapAgreementLineItem.get(agrLP.APT_Agreement_Line_Item__c).Apttus_CMConfig__DerivedFromId__r.APT_Agreement_Sub_Account_IDs__c.split(';');
                        for(String LPData : listLPSubData)
                        {
                            listLPSubData = LPData.split(':');
                            for(integer i = 0; i < listLPSubData.size()-1; i++)
                            {
                                mapLPtoSubAccount.put(listLPSubData[i],listLPSubData[i+1]);
                            }
                        }
                    }
                    if(mapLPtoBillingAccount.containsKey(agrLP.APT_Lodgement_Point_Lookup__c) && 'null' != mapLPtoBillingAccount.get(agrLP.APT_Lodgement_Point_Lookup__c))
                    {
                        agrLP.APT_Billing_Account__c = mapLPtoBillingAccount.get(agrLP.APT_Lodgement_Point_Lookup__c);
                        agrLP.APT_Billing_Account_Flag__c = true;
                    }
                    
                    if(mapLPtoChargeAccount.containsKey(agrLP.APT_Lodgement_Point_Lookup__c) && 'null' != mapLPtoChargeAccount.get(agrLP.APT_Lodgement_Point_Lookup__c))
                    {
                        agrLP.APT_Charge_Account__c = mapLPtoChargeAccount.get(agrLP.APT_Lodgement_Point_Lookup__c);
                        agrLP.APT_Billing_Account_Flag__c = true;
                    }
                    
                    if(mapLPtoCashAccount.containsKey(agrLP.APT_Lodgement_Point_Lookup__c) && 'null' != mapLPtoCashAccount.get(agrLP.APT_Lodgement_Point_Lookup__c))
                    {
                        agrLP.APT_Cash_Account__c = mapLPtoCashAccount.get(agrLP.APT_Lodgement_Point_Lookup__c);
                        agrLP.APT_Billing_Account_Flag__c = true;
                    }
                    
                    if(mapLPtoSubAccount.containsKey(agrLP.APT_Lodgement_Point_Lookup__c) && 'null' != mapLPtoSubAccount.get(agrLP.APT_Lodgement_Point_Lookup__c))
                    {
                        agrLP.APT_Sub_Account__c = mapLPtoSubAccount.get(agrLP.APT_Lodgement_Point_Lookup__c);
                        agrLP.APT_Billing_Account_Flag__c = true;
                    }
                }
            }
            return APT_Constants.SUCCESS_LABEL;
        } 
        catch(Exception ex) 
        {
            return ex.getMessage();
        }
    } 
    
    /**
      Defect 1568
    **/
    public static String validateDuplicateAccounts(List<APT_Agreement_Lodgement_Point__c> listNewAgreementLP) {
        try
        {
            Set<ID> setAgreementID = new Set<ID>();
            for(APT_Agreement_Lodgement_Point__c AgrLPObj : listNewAgreementLP)
            {
                setAgreementID.add(AgrLPObj.APT_Agreement__c);
            }
            Set<String> setLPIdToBillingAccountCombination = new Set<String>();
            Set<String> setLPIdToChargeAccountCombination = new Set<String>();
            Set<String> setLPIdToSubAccountCombination = new Set<String>();
            Map<ID, List<APT_Agreement_Lodgement_Point__c>> mapAgreementIDTolistLP = new Map<ID, List<APT_Agreement_Lodgement_Point__c>>();
            
            for(APT_Agreement_Lodgement_Point__c AgrLPObj : [select ID, APT_Billing_Account__c, APT_Charge_Account__c,APT_Sub_Account__c, APT_Agreement__c, APT_Product__c from APT_Agreement_Lodgement_Point__c where ID NOT IN :listNewAgreementLP and APT_Status__c = 'Active' and APT_Agreement__c IN: setAgreementID and APT_Billing_Account_Flag__c = True and (APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode = :APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS  OR APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode = :APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)])
            {
                if(mapAgreementIDTolistLP.containsKey(AgrLPObj.APT_Agreement__c))
                {
                    mapAgreementIDTolistLP.get(AgrLPObj.APT_Agreement__c).add(AgrLPObj);
                }
                else
                {
                    mapAgreementIDTolistLP.put(AgrLPObj.APT_Agreement__c, new List<APT_Agreement_Lodgement_Point__c>{AgrLPObj});
                }
            }
            for(ID AgrID : mapAgreementIDTolistLP.keySet())
            {
                for(APT_Agreement_Lodgement_Point__c AgrLPObj : mapAgreementIDTolistLP.get(AgrID))
                {
                    setLPIdToBillingAccountCombination.add(AgrLPObj.APT_Product__c + '' + AgrLPObj.APT_Billing_Account__c);
                    setLPIdToChargeAccountCombination.add(AgrLPObj.APT_Product__c + '' + AgrLPObj.APT_Charge_Account__c);
                    setLPIdToSubAccountCombination.add(AgrLPObj.APT_Product__c + '' + AgrLPObj.APT_Sub_Account__c);
                }
                for(APT_Agreement_Lodgement_Point__c AgrLPObj : listNewAgreementLP)
                {
                    if((AgrLPObj.APT_Billing_Account__c != null && setLPIdToBillingAccountCombination.contains(AgrLPObj.APT_Product__c + '' + AgrLPObj.APT_Billing_Account__c)) || (AgrLPObj.APT_Charge_Account__c != null && setLPIdToChargeAccountCombination.contains(AgrLPObj.APT_Product__c + '' +AgrLPObj.APT_Charge_Account__c)) || (AgrLPObj.APT_Charge_Account__c != null && setLPIdToSubAccountCombination.contains(AgrLPObj.APT_Product__c + '' +AgrLPObj.APT_Sub_Account__c)))
                    {
                        return 'Account already associated to other Lodgement Point record';
                    }
                }
            }
            return APT_Constants.SUCCESS_LABEL;
        }
        catch(Exception ex) 
        {
            //return ex.getMessage();
            return 'Account already associated to other Lodgement Point record';
        }
    }
}