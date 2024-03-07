/**
 * @description: A class which handles Contract creation and Service Details modification
 *                      when Create Contract button is clicked on Proposal
 * @author: Yatika Bansal
 *Modifications Log
 *1.0 : 07-06-2023 : Yatika bansal : Added method for Creating Amendment Contract on 'Generate Agreement' action from LWC
* 17-07-2023 : Yatika bansal : Modified method for Creating Amendment Contract on 'Generate Agreement' action from LWC
* 20-07-2023 - Yatika bansal : Modified createContract method to include post billpay
* 27-07-2023 - Yatika bansal : Added method for Creating Renewal Contract on 'Generate Agreement' action from LWC, Modified existing methods
* 02-08-2023 - Yatika bansal : Set Contract Fields for new contract/renewal contract
* 04-08-2023 - Yatika bansal : Added method to update alis with same Product Lines to have same Service Dates
* 22-08-2023 - Yatika bansal : Updated createRenewalContract method to set renewal condition same as original contract
* 24-08-2023 - Yatika bansal : Updated createRenewalContract method to set ACD same as original contract
* 10-10-2023 - Bharat Patel : Uppdated createAmendContract() createRenewalContract() set AgreementToSFContractTriggerHandler disableCloning
**/
public without sharing class APT_ContractServiceDetailsController {

    /**
    * @description: This method creates a Agreement/Contract record from respected Proposal
    * @author Bharat Patel
    * @param Apttus_Proposal__Proposal__c proposal
    * @return Agreement/Contract Id
    **/
    public static string createContract(Apttus_Proposal__Proposal__c proposal){
        Apttus__APTS_Agreement__c aggreement = new Apttus__APTS_Agreement__c();
        aggreement.Apttus_QPComply__RelatedProposalId__c = proposal.Id;
        aggreement.Apttus__Related_Opportunity__c = proposal.Apttus_Proposal__Opportunity__c;
        aggreement.Apttus__Account__c = proposal.Apttus_Proposal__Account__c ;
        aggreement.APT_Date_of_Generation_Rate_Card__c = proposal.APT_Date_of_Generation_Rate_Card__c;
        aggreement.Apttus_CMConfig__ConfigurationFinalizedDate__c = proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c;
        aggreement.Apttus_CMConfig__PriceListId__c = proposal.Apttus_QPConfig__PriceListId__c;
        aggreement.Apttus__Status__c = APT_Constants.AGREEMENT_STATUS_REQUEST ;
        aggreement.APT_Sales_Team__c = proposal.Apttus_Proposal__Account__r.Sales_Segment__c ;
        aggreement.OwnerId = proposal.OwnerId;
        aggreement.Apttus__Primary_Contact__c = proposal.APT_Opportunity_Key_contact__c;
        aggreement.Apttus__Contract_Start_Date__c = System.today();
        if(proposal.APT_Postbillpay_Included__c > 0){
            aggreement.recordTypeId = System.Label.APT_PBPRecordTypeID;
        }else{
            aggreement.recordTypeId = System.Label.APT_MSARecordTypeID;
        }

        ApplicationDatabase.getInstance().dmlInsert(new List<Apttus__APTS_Agreement__c>{aggreement});
        return aggreement.Id;
    }

    /**
    * @description: This method creates a contract record
    * @author Yatika Bansal
    * @param String proposalId
    * @return Contract Id
    **/
    @AuraEnabled
    public static String createContractRecord(String proposalId){
        try{
            Map<Id, Apttus_Proposal__Proposal__c> proposalById = APT_ProposalObjectsSelector.newInstance(1)
                .selectByConfigId(new Set<Id>{proposalId},
                                  new Set<Object> {APT_ProposalObjectsSelector.Options.WITH_ACCOUNT});
            Apttus_Proposal__Proposal__c proposal = proposalById.values()[0];

            Id amendRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE).getRecordTypeId();
            Id renewRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE).getRecordTypeId();
            
            if(proposal.RecordTypeId == amendRecordTypeId) { //Amend
                return createAmendContract(proposal);
            }else if(proposal.RecordTypeId == renewRecordTypeId) { //Renew
                return createRenewalContract(proposal);
            }else{
                //Checking if credit assessment is required or not
                if(proposal.Apttus_Proposal__Account__r.Role_Type_Roll_Up__c == 'Prospect') {
                    List<APT_Credit_Assessment__c> creditAssess = APT_CreditAssessmentSelector.newInstance(1)
                        .selectByProposalAndAssessStatus(new Set<Id>{proposalId},
                                                         new Set<String> {APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED, APT_Constants.CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED});
                    
                    if(creditAssess.size() > 0){                   
                        return createContract(proposal);
                    }else{
                        return APT_Constants.STRING_RESPONSE_INCOMPLETE + '_' + proposal.Apttus_Proposal__Opportunity__c;
                    }
                }
                else {                   
                    return createContract(proposal);
                }
            }
        }
        Catch(Exception ex){
            return APT_Constants.ERROR_PREFIX + ex.getMessage() ;
        }
    }

    /**
    * @description: This method returns service details of an agreement.
    * @author Yatika Bansal
    * @param String contractId
    * @return list of Service Detail Record wrapper//(cacheable = true)
    **/
    @AuraEnabled
    public static List<ServiceDetailRecord> getServiceDetail(String contractId){
         List<Apttus__AgreementLineItem__c> alis = APT_AgreementLineItemsSelector.newInstance()
            .selectByContractIdsAndLineType(new Set<Id> {contractId},
                                                     new Set<String>{APT_Constants.PARAM_PRODUCT_Type, APT_Constants.PARAM_PRODUCT_Type_Misc} ,
                                                     new Set<Object> {APT_AgreementLineItemsSelector.Options.WITH_PRODUCT});
        
        //Get Bundle ALI with correct charge type
        List<Apttus__AgreementLineItem__c> filteredAli = getServiceDetailALI(alis);

        Set<String> uniqueProductLines = new Set<String>();
        List<ServiceDetailRecord> serviceDetailRecs = new List<ServiceDetailRecord>();
        for(Apttus__AgreementLineItem__c ali : filteredAli){
            if(!uniqueProductLines.contains(ali.Apttus__ProductId__r.APT_Product_Lines__c)){
                uniqueProductLines.add(ali.Apttus__ProductId__r.APT_Product_Lines__c);
                
                ServiceDetailRecord rec = new ServiceDetailRecord();
                rec.productLine = ali.Apttus__ProductId__r.APT_Product_Lines__c;
                rec.serviceId = ali.Id;
                
                serviceDetailRecs.add(rec);               
            }
        }
        
        return serviceDetailRecs;
    }

    /**
    * @description: This method returns current collection address.
    * @author Yatika Bansal
    * @param String contractId
    * @return address
    **/
    @AuraEnabled(cacheable = true)
    public static String getCurrentAddress(String contractId){
        List<APT_Operational_Schedule__c> os= APT_OperationalScheduleSelector.newInstance(1)
                .selectByContractId(new Set<Id>{contractId});

        if(os.size() > 0){
            return os[0].APT_Parcel_Collection_Points__c;
        }else{
            return APT_Constants.ERROR_PREFIX;
        }
    }

    /**
    * @description: This method updates collection address.
    * @author Yatika Bansal
    * @param String contractId
    * @param String address
    * @return Success/Error
    **/
    @AuraEnabled
    public static String updateCollectionAddress(String contractId, String address){
        try{
            List<APT_Operational_Schedule__c> os = APT_OperationalScheduleSelector.newInstance(1)
                .selectByContractId(new Set<Id>{contractId});

            os[0].APT_Parcel_Collection_Points__c = address;
            update os[0];

            return APT_Constants.SUCCESS_LABEL_SMALL;
        }
        Catch(Exception ex){
            return APT_Constants.ERROR_PREFIX + ex.getMessage() ;
        }
    }
    
    /**
    * @description: This method creates a Amend Agreement/Contract record from respected Proposal
    * @author Yatika Bansal
    * @param Apttus_Proposal__Proposal__c proposal
    * @return Agreement/Contract Id
    **/
    public static string createAmendContract(Apttus_Proposal__Proposal__c proposal){        
        AgreementToSFContractTriggerHandler.disableCloning = true;
        List<Apttus__APTS_Agreement__c> sourceAgreements = ApttusContractsSelector.newInstance(1)
            .selectByAgreementNumber(new Set<String>{proposal.APT_Contract_Number__c}, new Set<Object> {ApttusContractsSelector.Options.WITH_PROPOSAL});
        
        if(!sourceAgreements.isEmpty()){
            Apttus__APTS_Agreement__c sourceAgreement = sourceAgreements[0];
            // Use existing function: APT_AmendRenewUtility.renewAgreement() method to create contract record
            Apttus__APTS_Agreement__c  amendedAgreement = APT_AmendRenewUtility.amendAgreement(APT_Constants.RECORD_TYPE_DOV_CONTRACT,
                                                                                               proposal.Apttus_Proposal__Opportunity__c, proposal.Id, sourceAgreement, 
                                                                                               APT_Constants.CREATE_AMENDMENT_CONTRACT);                      
            amendedAgreement.Apttus__Primary_Contact__c = proposal.APT_Opportunity_Key_contact__c;
            amendedAgreement.APT_Customer_Application_Contact__c = proposal.APT_Opportunity_Key_contact__c;
            amendedAgreement.APT_Commercial_Contact__c = proposal.APT_Opportunity_Key_contact__c;
            amendedAgreement.APT_Operational_contact__c = proposal.APT_Opportunity_Key_contact__c;
            amendedAgreement.APT_System_User__c = proposal.APT_Opportunity_Key_contact__c;
            amendedAgreement.Apttus__Contract_Start_Date__c = sourceAgreement.Apttus__Contract_Start_Date__c;
            amendedAgreement.Apttus__Term_Months__c = sourceAgreement.Apttus__Term_Months__c;
            amendedAgreement.Apttus__Contract_End_Date__c = sourceAgreement.Apttus__Contract_End_Date__c;
            
            ApplicationDatabase.getInstance().dmlInsert(new List<Apttus__APTS_Agreement__c>{amendedAgreement});
            
            //after inserting agreement record, build relationship with original agreement using existing function
            Boolean isAmendRelationShipBuild = APT_AmendRenewUtility.afterAmend(sourceAgreement.Id, amendedAgreement.Id, false);
            if(isAmendRelationShipBuild){
                return amendedAgreement.Id;
            }else{
                return APT_Constants.ERROR_PREFIX + APT_Constants.AMEND_AGREEMENT_FAILED ;
            }
        }else{
                return APT_Constants.ERROR_PREFIX + APT_Constants.AMEND_AGREEMENT_FAILED ;
        }
    }
        
    /**
    * @description: This method creates a Renewal Agreement/Contract record from respected Proposal
    * @author Yatika Bansal
    * @param Apttus_Proposal__Proposal__c proposal
    * @return Agreement/Contract Id
    **/
    public static string createRenewalContract(Apttus_Proposal__Proposal__c proposal){
        AgreementToSFContractTriggerHandler.disableCloning = true;
        List<Apttus__APTS_Agreement__c> sourceAgreements = ApttusContractsSelector.newInstance(1)
            .selectByAgreementNumber(new Set<String>{proposal.APT_Contract_Number__c}, new Set<Object> {ApttusContractsSelector.Options.WITH_PROPOSAL});
        
        if(!sourceAgreements.isEmpty()){
            Apttus__APTS_Agreement__c sourceAgreement = sourceAgreements[0];
            // Use existing function: APT_AmendRenewUtility.renewAgreement() method to create contract record
            Apttus__APTS_Agreement__c  renewedAgreement = APT_AmendRenewUtility.renewAgreement(APT_Constants.RECORD_TYPE_RENEWAL_CONTRACT,
                                                                                               proposal.Apttus_Proposal__Opportunity__c, proposal.Id, sourceAgreement);
                   
            renewedAgreement.Apttus__Primary_Contact__c = proposal.APT_Opportunity_Key_contact__c;
            renewedAgreement.APT_Customer_Application_Contact__c = proposal.APT_Opportunity_Key_contact__c;
            renewedAgreement.APT_Commercial_Contact__c = proposal.APT_Opportunity_Key_contact__c;
            renewedAgreement.APT_Operational_contact__c = proposal.APT_Opportunity_Key_contact__c;
            renewedAgreement.APT_System_User__c = proposal.APT_Opportunity_Key_contact__c;
            renewedAgreement.Term__c = sourceAgreement.Term__c;
            renewedAgreement.Apttus__Contract_Start_Date__c = Date.today();
            
            ApplicationDatabase.getInstance().dmlInsert(new List<Apttus__APTS_Agreement__c>{renewedAgreement});
            
            //after inserting agreement record, build relationship with original agreement using existing function
            Boolean isRenewRelationShipBuild = APT_AmendRenewUtility.afterRenew(sourceAgreement.Id, renewedAgreement.Id, false);
            if(isRenewRelationShipBuild){
                return renewedAgreement.Id;
            }else{
                return APT_Constants.ERROR_PREFIX + APT_Constants.RENEWAL_AGREEMENT_FAILED ;
            }
        }else{
                return APT_Constants.ERROR_PREFIX + APT_Constants.RENEWAL_AGREEMENT_FAILED ;
        }
    }
    
    /**
    * @description: This method updates all alis with same Product Lines to have same Service Dates
    * @param contractId
    * @param serviceIds
    * @author Yatika Bansal
    * @return Success/Error
    **/
    @AuraEnabled
    public static String updateAlis(String contractId, List<Id> serviceIds){
        try{ 
            //Get ali
            List<Apttus__AgreementLineItem__c> alis = APT_AgreementLineItemsSelector.newInstance()
                .selectByContractIdsAndLineType(new Set<Id> {contractId},
                                                new Set<String>{APT_Constants.PARAM_PRODUCT_Type, APT_Constants.PARAM_PRODUCT_Type_Misc} ,
                                                new Set<Object> {APT_AgreementLineItemsSelector.Options.WITH_PRODUCT});
            
            List<Apttus__AgreementLineItem__c> filteredAli = getServiceDetailALI(alis);            
            
            Map<String, List<Date>> mapDatesByProductLine = new Map<String, List<Date>>();
            List<Apttus__AgreementLineItem__c> aliToBeUpdated = new  List<Apttus__AgreementLineItem__c>();
            for(Apttus__AgreementLineItem__c ali : filteredAli){
                if(serviceIds.contains(ali.Id)){
                    mapDatesByProductLine.put(ali.Apttus__ProductId__r.APT_Product_Lines__c, new List<Date>{ali.Apttus_CMConfig__EffectiveDate__c , ali.Apttus_CMConfig__EndDate__c});
                }else{
                    aliToBeUpdated.add(ali);
                }
            }
                        
            //Update Ali with same product line
            for(Apttus__AgreementLineItem__c ali : aliToBeUpdated){
                List<Date> dates = mapDatesByProductLine.get(ali.Apttus__ProductId__r.APT_Product_Lines__c);
                ali.Apttus_CMConfig__EffectiveDate__c = dates[0];
                ali.Apttus_CMConfig__EndDate__c = dates[1];                
            }
            
            if(aliToBeUpdated.size() > 0){
                ApplicationDatabase.getInstance().dmlUpdate(aliToBeUpdated);
            }
            return APT_Constants.SUCCESS_LABEL_SMALL;
        }
        Catch(Exception ex){
            return APT_Constants.ERROR_PREFIX + ex.getMessage() ;
        }
    }
    
    /**
    * @description: This method returns alis to be displayed as service detail sections.
    * @author Yatika Bansal
    * @param List alis
    * @return List filtered alis
    **/
    public static List<Apttus__AgreementLineItem__c> getServiceDetailALI( List<Apttus__AgreementLineItem__c> alis){
        Map<String, String> mapChargeTypeByName = new Map<String, String>();
        APT_Product_Charge_Type_Mapping__mdt[] productChargeTypeMapping = [Select APT_Charge_Type__c, APT_Product_Name__c from APT_Product_Charge_Type_Mapping__mdt]; 
        for(APT_Product_Charge_Type_Mapping__mdt mapRec : productChargeTypeMapping){
            mapChargeTypeByName.put(mapRec.APT_Product_Name__c, mapRec.APT_Charge_Type__c);
        }
        
        
        List<Apttus__AgreementLineItem__c> filteredAlis = new List<Apttus__AgreementLineItem__c>();        
        for(Apttus__AgreementLineItem__c ali : alis){
            if(ali.Apttus_CMConfig__ChargeType__c == APT_Constants.CHARGE_TYPE_STANDARD_PRICE || (mapChargeTypeByName.containsKey(ali.APT_Product_Name__c) 
                                                         && ali.Apttus_CMConfig__ChargeType__c == mapChargeTypeByName.get(ali.APT_Product_Name__c))){
                filteredAlis.add(ali);
            }
        }
        return filteredAlis;
    }
    
    //Wrapper Class to return Ali fields
    public class ServiceDetailRecord {
        @AuraEnabled
        public String productLine {get;set;}
        @AuraEnabled
        public Id serviceId {get;set;}
    }
}