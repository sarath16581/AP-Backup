/**
This apex class is trigger handler for apex trigger - APT_SiteInspectionTrigger 
Created By - Mausam Padhiyar
Created Date - 19th Aug, 2016

Last Modified By - Mausam Padhiyar
Last Modified Date - 12th Oct, 2016 | Defect 1661 | Populate UMS and Print Post Collection Point Ids
*/
public with sharing class APT_SiteInspectionTriggerHandler {
    
    public static String afterInsertEvent(list<APT_Site_Inspection__c> listSiteInspection) {
        try {
            map<Id, list<APT_Site_Inspection__c>> mapSiteInspection = new map<Id, list<APT_Site_Inspection__c>>();
            list<APT_Site_Inspection__c> listSI = new list<APT_Site_Inspection__c>();
            set<Id> setAgreementLineItemId = new set<Id>();
            for(APT_Site_Inspection__c si : listSiteInspection) {
                //if(String.isBlank(si.APT_Contract_Line_Item__c)) {
                	setAgreementLineItemId.add(si.APT_Contract_Line_Item__c);
                	
                    listSI = mapSiteInspection.get(si.APT_Contract__c);
                    if(listSI != null && listSI.size() > 0){
                        listSI.add(si);
                        mapSiteInspection.put(si.APT_Contract__c, listSI);
                    } else {
                        listSI = new list<APT_Site_Inspection__c>();
                        listSI.add(si);
                        mapSiteInspection.put(si.APT_Contract__c, listSI);
                    }
                //}
            }
            
            set<Id> setOSId = new set<Id>();
            for(Apttus__APTS_Agreement__c agreement : [SELECT Id, Operational_Schedule__c 
                                                            FROM Apttus__APTS_Agreement__c 
                                                            WHERE Id IN :mapSiteInspection.keySet()])  {
                setOSId.add(agreement.Operational_Schedule__c);
            }
            
            if(setOSId != null && setOSId.size() > 0) {
                map<Id, APT_Operational_Schedule__c> mapOS = new map<Id, APT_Operational_Schedule__c>();
                for(APT_Operational_Schedule__c os : [SELECT Id, APT_International_Collection_Point_Ids__c,
                                                        APT_Parcel_Collection_Point_Ids__c, APT_UMS_Collection_Point_Ids__c,
                                                        APT_Print_Post_Collection_Point_Ids__c, APT_Contract__c
                                                        FROM APT_Operational_Schedule__c
                                                        WHERE Id IN :setOSId]) {
                    mapOS.put(os.APT_Contract__c, os);
                }
                
                map<Id, Apttus__AgreementLineItem__c> mapAgreementLineItem = new map<Id, Apttus__AgreementLineItem__c>([SELECT Id, Name,
                																										Apttus__ProductId__c, Apttus__ProductId__r.ProductCode
                																										FROM Apttus__AgreementLineItem__c
                																										WHERE Id IN :setAgreementLineItemId]);
                
                
                listSI = new list<APT_Site_Inspection__c>();
                APT_Operational_Schedule__c operationSchedule = new APT_Operational_Schedule__c();
                
                for(Id agreementId : mapOS.keySet()) {
                    listSI = mapSiteInspection.get(agreementId);
                    operationSchedule = mapOS.get(agreementId);
                    if(listSI != null && listSI.size() > 0 && operationSchedule != null) {
                        for(APT_Site_Inspection__c si : listSI) {
                        	//generic 
                        	if(String.isBlank(si.APT_Contract_Line_Item__c)) {
	                            operationSchedule.APT_International_Collection_Point_Ids__c += APT_Constants.SEPERATOR_COMMA + si.Id;
	                            operationSchedule.APT_Parcel_Collection_Point_Ids__c += APT_Constants.SEPERATOR_COMMA + si.Id;
	                            //1661
	                            operationSchedule.APT_Parcel_Express_Collection_Point_Ids__c += APT_Constants.SEPERATOR_COMMA + si.Id;
	                            operationSchedule.APT_UMS_Collection_Point_Ids__c += APT_Constants.SEPERATOR_COMMA + si.Id;
	                            operationSchedule.APT_Print_Post_Collection_Point_Ids__c += APT_Constants.SEPERATOR_COMMA + si.Id;
	                            //1661
                        	} 
                        	//product specific
                        	else if(String.isNotBlank(si.APT_Contract_Line_Item__c)) {
                        		Apttus__AgreementLineItem__c ali = mapAgreementLineItem.get(si.APT_Contract_Line_Item__c);
                        		if(ali != null && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode)) {              
                        			/*  
                        			//duplicate collection point ids seen because of process builder        			
	                        		if(String.isNotBlank(operationSchedule.APT_Parcel_Collection_Point_Ids__c) && !operationSchedule.APT_Parcel_Collection_Point_Ids__c.contains(si.Id) && (ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) {
	                        			operationSchedule.APT_Parcel_Collection_Point_Ids__c += APT_Constants.SEPERATOR_COMMA + si.Id;
	                        		} else if(String.isBlank(operationSchedule.APT_Parcel_Collection_Point_Ids__c) && (ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) {
	                        			operationSchedule.APT_Parcel_Collection_Point_Ids__c = si.Id;
	                        		} else if(String.isNotBlank(operationSchedule.APT_International_Collection_Point_Ids__c) && !operationSchedule.APT_International_Collection_Point_Ids__c.contains(si.Id) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)) {
	                        			operationSchedule.APT_International_Collection_Point_Ids__c += APT_Constants.SEPERATOR_COMMA + si.Id;
	                        		} else if(String.isBlank(operationSchedule.APT_International_Collection_Point_Ids__c) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)) {
	                        			operationSchedule.APT_International_Collection_Point_Ids__c = si.Id;
	                        		} else 
	                        		*/
	                        		
	                        		//UMS
	                        		if(String.isNotBlank(operationSchedule.APT_UMS_Collection_Point_Ids__c) && !operationSchedule.APT_UMS_Collection_Point_Ids__c.contains(si.Id) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES)) {
	                        			operationSchedule.APT_UMS_Collection_Point_Ids__c += APT_Constants.SEPERATOR_COMMA + si.Id;
	                        		} else if(String.isBlank(operationSchedule.APT_UMS_Collection_Point_Ids__c) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES)) {
	                        			operationSchedule.APT_UMS_Collection_Point_Ids__c = si.Id;
	                        		} 
	                        		//Print Post
	                        		else if(String.isNotBlank(operationSchedule.APT_Print_Post_Collection_Point_Ids__c) && !operationSchedule.APT_Print_Post_Collection_Point_Ids__c.contains(si.Id) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
	                        			operationSchedule.APT_Print_Post_Collection_Point_Ids__c += APT_Constants.SEPERATOR_COMMA + si.Id;
	                        		} else if(String.isBlank(operationSchedule.APT_Print_Post_Collection_Point_Ids__c) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
	                        			operationSchedule.APT_Print_Post_Collection_Point_Ids__c = si.Id;
	                        		} else { }
                        		}
                        	} else { }                        
                            
                            mapOS.put(agreementId, operationSchedule);
                        }
                    }
                }
                
                if(mapOS.values() != null && mapOS.values().size() > 0) {
                    update mapOS.values();
                }
            }
        } catch(system.exception ex) {
            return ex.getMessage();
        }
        
        return APT_Constants.SUCCESS_LABEL;
    }
}