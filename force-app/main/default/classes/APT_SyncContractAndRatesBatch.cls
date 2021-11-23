/**
Description: This batch job will Sync Contract Rates(SAP Interface).
Created By - Mausam Padhiyar
Created Date - 7th Oct, 2015
  
Last Modified By - Mausam Padhiyar
Last Modified Date - 17th Aug, 2016 | Defect 1492 | CHARGE_ACC_NBR field mapping issue

Last Modified By - Mausam Padhiyar
Last Modified Date - 20th Aug, 2016 | Defect 1509 | Parcel and Express Parcel Lodgement Point

Last Modified By - Mausam Padhiyar
Last Modified Date - 1st Sept, 2016 | MinRevenuePerAnnum for Above 50k fix

Last Modified By - Mausam Padhiyar
Last Modified Date - 7th Sept, 2016 | International Lodgement Points - Digital nad Non-Digital

Last Modified By - Mausam Padhiyar
Last Modified Date - 7th Sept, 2016 | International Lodgement Points - Digital nad Non-Digital

Last Modified By - Mausam Padhiyar
Last Modified Date - 12th Oct, 2016 | Defect 1661 | Populate Details for UMS and Print Post

Last Modified By - Mausam Padhiyar
Last Modified Date - 15th Nov, 2016 | Defect 1606 and 1661 | Populate Details of Sub Account and Cash Account on Account

Last Modified By - Mausam Padhiyar
Last Modified Date - 23rd Nov, 2016 | Defect 1783 |  Charge Code issue with AIRPTI AND AIRRPI

Last Modified By - Mausam Padhiyar
Last Modified Date - 29th Nov, 2016 | Defect 1826 |  fix null pointer exception

Last Modified By - Mausam Padhiyar
Last Modified Date - 1st Dec, 2016 | Defect 1830 |  Rate Card Key issue

Last Modified By - Mausam Padhiyar
Last Modified Date - 1st Dec, 2016 | Defect 1817 | eParcel Post Return price issue

Last Modified By - Mausam Padhiyar
Last Modified Date - 5th Dec, 2016 | Defect 1801 | Minimum Collection Value

Last Modified By - Mausam Padhiyar
Last Modified Date - 7th Dec, 2016 | Defect 1844 | no detailed rates for renewal contract

Last Modified By - Mausam Padhiyar
Last Modified Date - 25th Jan, 2017 | Defect 1825 | set contract type as offline

Last Modified By - Shashwat.Nath@auspost.com.au 
Last Modified Date - 10th July, 2020 | Changes Related to Banded Z6 Rates Calculations

Last Modified By - Seth Heang
Last Modified Date - 31st July, 2020 | SOQL 50001 fix on SAP Rate objects

Last Modified By - Seth Heang
Last Modified Date - 31st August, 2020 | STP-2246 - Update CSV filename to swap Case Number with Contract Number
**/ 
global class APT_SyncContractAndRatesBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    global set<Id> setAgreementId {get; set;}
    global set<String> setValidPLIId {get; set;}
    global set<String> setErrorMessage {get;set;}
    //global String businessReferenceID {get; set;}
    //global set<String> setResponse {get;set;}
    //global set<String> setBusinessReferenceID {get;set;}
        
    global list<syncContractAndRatesResultWrapper> listResponseWrapper {get; set;}
    
    /**
        Wrapper Class to hold responses
     */
    public with sharing class syncContractAndRatesResultWrapper {        
        public string strResponse {get;set;}
        public string contractNumber {get; set;}
        public string SAPERPContractNumber {get; set;}
        public string businessReferenceId {get; set;}
    }
    
    /**
        constructor
     */
    global APT_SyncContractAndRatesBatch(set<Id> agreementIdSet, set<String> setPLIId) {
        setErrorMessage = new set<String>();
        setValidPLIId = new set<String>();
        
        //setResponse = new set<String>();
        //setBusinessReferenceID = new set<String>();
        listResponseWrapper = new list<syncContractAndRatesResultWrapper>();
        
        setAgreementId = agreementIdSet;
        setValidPLIId = setPLIId;
    }
    
    /**
        start
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        return Database.getQueryLocator([SELECT Id, Name, Apttus__Related_Opportunity__c,
                                        Apttus__Related_Opportunity__r.Name,
                                        Apttus__Related_Opportunity__r.Type,
                                        Operational_Schedule__c,
                                        Apttus_QPComply__RelatedProposalId__c,
                                        Apttus__Account__c,
                                        Apttus__Primary_Contact__c,
                                        Owner.Id, SAP_Contract_Number__c,
                                        Apttus__FF_Agreement_Number__c,
                                        Apttus__Account__r.Name,
                                        Apttus__Total_Contract_Value__c,
                                        Apttus__Contract_Start_Date__c,
                                        Apttus__Contract_End_Date__c,
                                        APT_Contract_Type__c,
                                        Apttus__Agreement_Category__c,
                                        APT_Pricing_Category__c //1825
                                        FROM Apttus__APTS_Agreement__c
                                        WHERE Id IN :setAgreementId]);
    }
    
    /**
        execute
     */
    global void execute(Database.BatchableContext BC, list<Apttus__APTS_Agreement__c> listAgreement){
        try { 
            set<Id> setOpportunityId = new set<Id>();
            set<Id> setOperationalScheduleId = new set<Id>();
            set<Id> setAccountId = new set<Id>();
            set<Id> setContactId = new set<Id>();
            set<Id> setSalesRepId = new set<Id>();
            map<String, String> mapAccountByProposal = new map<String, String>();
            map<String, Apttus__APTS_Agreement__c> mapAgreement = new map<String, Apttus__APTS_Agreement__c>();
            set<Id> setAgreementIds = new set<Id>();    //1492
            for(Apttus__APTS_Agreement__c agreement : listAgreement) {
                setAgreementIds.add(agreement.Id);  //1492
                setOpportunityId.add(agreement.Apttus__Related_Opportunity__c);
                setOperationalScheduleId.add(agreement.Operational_Schedule__c);
                setAccountId.add(agreement.Apttus__Account__c);
                setContactId.add(agreement.Apttus__Primary_Contact__c);
                setSalesRepId.add(agreement.Owner.Id);
                
                mapAgreement.put(agreement.Apttus__Related_Opportunity__c, agreement);
                mapAccountByProposal.put(agreement.Apttus_QPComply__RelatedProposalId__c, agreement.Apttus__Account__c);
            }            
            
            map<String, Contact> mapContact = new map<String, Contact>([SELECT Id, Name, Title,
                                                                            FirstName, LastName, 
                                                                            MiddleName, Phone, 
                                                                            MobilePhone, Fax, Email
                                                                            FROM Contact
                                                                            WHERE Id IN :setContactId]);
                
            map<String, Account> mapAccount = new map<String, Account>();
            map<String, list<APT_Sub_Account__c>> mapSubAccount = new map<String, list<APT_Sub_Account__c>>();
            if(setAccountId!=null) {
                for(Account acc : [SELECT Id, Name, BillingCity, AccountNumber, 
                                BillingState,  BillingStreet, 
                                BillingPostalCode, BillingCountry,
                                LEGACY_ID__c
                                FROM Account
                                WHERE Id IN :setAccountId]) {
                    
                    mapAccount.put(acc.Id, acc);
                }
            }
                 
            map<String, APT_Operational_Schedule__c> mapOperationalSchedule = new map<String, APT_Operational_Schedule__c>();
            set<String> setLodgementPointIds = new set<String>();
            set<String> setCollectionPointNames = new set<String>();
            if(setAgreementId!=null) {
                for(APT_Operational_Schedule__c os : [SELECT Id, Name,
                                                    APT_International_Lodgement_Points__c,
                                                    APT_International_Lodgement_Times__c,
                                                    APT_International_Collection_Times__c,
                                                    APT_International_Collection_Points__c,
                                                    APT_Parcel__c,
                                                    APT_International_Postal__c,
                                                    APT_Parcel_Lodgement_Points__c,
                                                    APT_Parcel_Lodgement_Times__c,
                                                    APT_Parcel_Collection_Points__c ,
                                                    APT_Parcel_Collection_Times__c,
                                                    APT_Contract__r.Apttus_QPComply__RelatedProposalId__c,
                                                    APT_Parcel_Lodgement_Point_Ids__c,
                                                    APT_Express_Parcel_Lodgement_Point_Ids__c,  
                                                    APT_International_Lodgement_Point_Ids__c,
                                                    APT_Parcel_Collection_Point_Ids__c, 
                                                    APT_International_Collection_Point_Ids__c,
                                                    APT_Non_Digital_Collection_Point_Ids__c,
                                                    APT_Print_Post_Collection_Point_Ids__c,
                                                    APT_UMS_Collection_Point_Ids__c,
                                                    APT_Non_Digital_International_LP_Ids__c,
                                                    APT_Print_Post_Lodgement_Point_Ids__c,
                                                    APT_UMS_Lodgement_Point_Ids__c,
                                                    APT_Print_Post_Collection_Times__c,
                                                    APT_UMS_Collection_Times__c,
                                                    APT_Parcel_Express_Collection_Point_Ids__c,
                                                    APT_Parcel_Express_Collection_Times__c,
                                                    APT_Parcel_Express_Collection_Points__c
                                                    FROM APT_Operational_Schedule__c
                                                    WHERE APT_Contract__c IN :setAgreementId]) {
                
                    mapOperationalSchedule.put(os.APT_Contract__c, os);
                    
                    if(!String.isEmpty(os.APT_Parcel_Lodgement_Point_Ids__c)) {                        
                        list<String> listParcelLodgementPoints = os.APT_Parcel_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listParcelLodgementPoints != null) {
                            for(String lp : listParcelLodgementPoints) {
                                setLodgementPointIds.add(lp);
                            }
                        }                           
                    }
                    
                    //1509
                    if(!String.isEmpty(os.APT_Express_Parcel_Lodgement_Point_Ids__c)) {
                        list<String> listParcelLodgementPoints = os.APT_Express_Parcel_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listParcelLodgementPoints != null) {
                            for(String lp : listParcelLodgementPoints) {
                                setLodgementPointIds.add(lp);
                            }
                        }                           
                    }
                    //1509
                    
                    //Digital | Internationa Lodgement Points
                    if(!String.isEmpty(os.APT_International_Lodgement_Point_Ids__c)) {
                        list<String> listInternationalLodgementPoints = os.APT_International_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listInternationalLodgementPoints != null) {
                            for(String lp : listInternationalLodgementPoints) {
                                setLodgementPointIds.add(lp);
                            }
                        }                           
                    }
                    
                    //Non-Digital | Internationa Lodgement Points
                    if(!String.isEmpty(os.APT_Non_Digital_International_LP_Ids__c)) {
                        list<String> listInternationalLodgementPoints = os.APT_Non_Digital_International_LP_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listInternationalLodgementPoints != null) {
                            for(String lp : listInternationalLodgementPoints) {
                                setLodgementPointIds.add(lp);
                            }
                        }                           
                    }
                    
                    //1661
                    //UMS
                    if(!String.isEmpty(os.APT_UMS_Lodgement_Point_Ids__c)) {                        
                        list<String> listUMSLodgementPoints = os.APT_UMS_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listUMSLodgementPoints != null) {
                            for(String lp : listUMSLodgementPoints) {
                                setLodgementPointIds.add(lp);
                            }
                        }                           
                    }
                    
                    //Print Post
                    if(!String.isEmpty(os.APT_Print_Post_Lodgement_Point_Ids__c)) {                        
                        list<String> listPrintPostLodgementPoints = os.APT_Print_Post_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listPrintPostLodgementPoints != null) {
                            for(String lp : listPrintPostLodgementPoints) {
                                setLodgementPointIds.add(lp);
                            }
                        }                           
                    }
                    
                    //1661
                    
                    if(!String.isEmpty(os.APT_Parcel_Collection_Point_Ids__c)) {
                        list<String> listParcelCollectionPoints = os.APT_Parcel_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listParcelCollectionPoints != null) {
                            for(String cp : listParcelCollectionPoints) {
                                setCollectionPointNames.add(cp);    //site inspection id, 1492
                            }
                        }                           
                    }
                    
                    if(!String.isEmpty(os.APT_International_Collection_Point_Ids__c)) {
                        list<String> listInternationalCollectionPoints = os.APT_International_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listInternationalCollectionPoints != null) {
                            for(String cp : listInternationalCollectionPoints) {
                                setCollectionPointNames.add(cp);    //site inspection id, 1492
                            }
                        }                           
                    }
                    
                    //1606
                    if(!String.isEmpty(os.APT_Non_Digital_Collection_Point_Ids__c)) {
                        list<String> listInternationalCollectionPoints = os.APT_Non_Digital_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listInternationalCollectionPoints != null) {
                            for(String cp : listInternationalCollectionPoints) {
                                setCollectionPointNames.add(cp);
                            }
                        }                           
                    }
                    //1606
                    
                    //1661
                    //Parcel Express
                    if(!String.isEmpty(os.APT_Parcel_Express_Collection_Point_Ids__c)) {
                        list<String> listExpressCollectionPoints = os.APT_Parcel_Express_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listExpressCollectionPoints != null) {
                            for(String cp : listExpressCollectionPoints) {
                                setCollectionPointNames.add(cp);    //site inspection id, 1492
                            }
                        }                           
                    }
                    //UMS
                    if(!String.isEmpty(os.APT_UMS_Collection_Point_Ids__c)) {
                        list<String> listUMSCollectionPoints = os.APT_UMS_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listUMSCollectionPoints != null) {
                            for(String cp : listUMSCollectionPoints) {
                                setCollectionPointNames.add(cp);    //site inspection id, 1492
                            }
                        }                           
                    }
                    
                    //Print Post
                    if(!String.isEmpty(os.APT_Print_Post_Collection_Point_Ids__c)) {
                        list<String> listPrintPostCollectionPoints = os.APT_Print_Post_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                        if(listPrintPostCollectionPoints != null) {
                            for(String cp : listPrintPostCollectionPoints) {
                                setCollectionPointNames.add(cp);    //site inspection id, 1492
                            }
                        }                           
                    }
                    //1661
                }
            }            
            
            map<String, APT_Site_Inspection__c> mapCollectionPoint = new map<String, APT_Site_Inspection__c>();
            if(setCollectionPointNames != null) {
                for(APT_Site_Inspection__c si : [SELECT Id, Name, APT_Lodgement_Point__c
                                            FROM APT_Site_Inspection__c
                                            WHERE Id IN :setCollectionPointNames]) {    //1492
                                        
                    mapCollectionPoint.put(si.Id, si);
                }
            }
            
            map<String, Network__c> mapLodgementPoint = new map<String, Network__c>();
            //1492
            map<String, APT_Agreement_Lodgement_Point__c> mapAgreementLodgementPoint = new map<String, APT_Agreement_Lodgement_Point__c>();
            //1492
            
            if(setLodgementPointIds != null) {
                for(Network__c network : [SELECT Id, Name,
                                        APT_DWS_ID__c, Org_ID__c, APT_GA_Code__c
                                        FROM Network__c
                                        WHERE Id IN :setLodgementPointIds]) {
                    
                    mapLodgementPoint.put(network.Id, network);
                }
                
                //1492    
                set<Id> setSubAccountId = new set<Id>();
                for(APT_Agreement_Lodgement_Point__c alp : [SELECT Id, Name, APT_Lodgement_Point_Lookup__c,
                                                            APT_Billing_Account__c, APT_Billing_Account__r.LEGACY_ID__c,
                                                            APT_Billing_Account__r.Name, 
                                                            APT_Charge_Account__c, APT_Charge_Account__r.Name,
                                                            APT_Sub_Account__c, APT_Sub_Account__r.Name,
                                                            APT_Cash_Account__c, APT_Cash_Account__r.Name                                                   
                                                            FROM APT_Agreement_Lodgement_Point__c
                                                            WHERE APT_Lodgement_Point_Lookup__c IN :setLodgementPointIds
                                                            AND APT_Agreement__c IN :setAgreementIds]) {
                    setSubAccountId.add(alp.APT_Sub_Account__c);
                    mapAgreementLodgementPoint.put(alp.APT_Lodgement_Point_Lookup__c, alp);
                }
                
                for(APT_Sub_Account__c subAccount : [SELECT Id, Name, APT_Organisation__c
                                                    FROM APT_Sub_Account__c
                                                    WHERE Id IN :setSubAccountId]) {
                    
                    list<APT_Sub_Account__c> listSubAccount = mapSubAccount.get(subAccount.Id);
                    if(listSubAccount != null) {
                        listSubAccount.add(subAccount);
                        mapSubAccount.put(subAccount.Id, listSubAccount);
                    } else {
                        listSubAccount = new list<APT_Sub_Account__c>();
                        listSubAccount.add(subAccount);
                        mapSubAccount.put(subAccount.Id, listSubAccount);
                    }
                }
                //1492
            }           
            
            if(setOpportunityId.size() > 0) {
                map<Id, Apttus_Proposal__Proposal__c> mapProposalById = new map<Id, Apttus_Proposal__Proposal__c>();
                map<String, list<Apttus_Proposal__Proposal__c>> mapProposalByOppty = new map<String, list<Apttus_Proposal__Proposal__c>>();
                for(Apttus_Proposal__Proposal__c proposal : [SELECT Id, Name, Apttus_Proposal__Opportunity__c,
                                                        Apttus_Proposal__Approval_Stage__c, 
                                                        Apttus_Proposal__Presented_Date__c,
                                                        Apttus_Proposal__Opportunity__r.KeyContact__c,
                                                        Owner.Id,
                                                        APT_Method_of_Payment__c
                                                        FROM Apttus_Proposal__Proposal__c
                                                        WHERE Apttus_Proposal__Opportunity__c IN :setOpportunityId
                                                        AND (Apttus_Proposal__Approval_Stage__c = :APT_Constants.QUOTE_TYPE_DRAFT 
                                                        OR Apttus_Proposal__Approval_Stage__c = :APT_Constants.APPROVAL_STAGE_ACCEPTED)
                                                        ORDER BY Apttus_Proposal__Presented_Date__c]) {
                    
                    mapProposalById.put(proposal.Id, proposal);
                    
                    Apttus__APTS_Agreement__c agreement = mapAgreement.get(proposal.Apttus_Proposal__Opportunity__c);
                    if(agreement != null && !String.isEmpty(agreement.APT_Contract_Type__c) && (agreement.APT_Contract_Type__c.equalsIgnoreCase(APT_Constants.CONTRACT_TYPE_NEW_CONTRACT) || agreement.APT_Contract_Type__c.equalsIgnoreCase(APT_Constants.RECORD_TYPE_DOV_CONTRACT))){    //APOST-1245
                        list<Apttus_Proposal__Proposal__c> listProposalByOppty = mapProposalByOppty.get(proposal.Apttus_Proposal__Opportunity__c);
                        if(listProposalByOppty != null) {
                            listProposalByOppty.add(proposal); 
                            mapProposalByOppty.put(proposal.Apttus_Proposal__Opportunity__c, listProposalByOppty);
                        } else {
                            listProposalByOppty = new list<Apttus_Proposal__Proposal__c>();
                            listProposalByOppty.add(proposal);
                            mapProposalByOppty.put(proposal.Apttus_Proposal__Opportunity__c, listProposalByOppty);
                        }
                    } else if(agreement != null && agreement.APT_Contract_Type__c != null && agreement.APT_Contract_Type__c.equalsIgnoreCase(APT_Constants.CONTRACT_TYPE_RENEWAL_CONTRACT) && proposal.Apttus_Proposal__Approval_Stage__c != null && proposal.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED)) {
                        list<Apttus_Proposal__Proposal__c> listProposalByOppty = mapProposalByOppty.get(proposal.Apttus_Proposal__Opportunity__c);
                        if(listProposalByOppty != null) {
                            listProposalByOppty.add(proposal);
                            mapProposalByOppty.put(proposal.Apttus_Proposal__Opportunity__c, listProposalByOppty);
                        } else {
                            listProposalByOppty = new list<Apttus_Proposal__Proposal__c>();
                            listProposalByOppty.add(proposal);
                            mapProposalByOppty.put(proposal.Apttus_Proposal__Opportunity__c, listProposalByOppty);
                        }
                    } else { }
                }
                
                map<String, User> mapSalesRep = new map<String, User>([SELECT Id, FirstName, 
                                                                        LastName, MiddleName, Name, 
                                                                        MobilePhone, Title, 
                                                                        Phone, Fax, Email
                                                                        FROM User
                                                                        WHERE Id IN :setSalesRepId]);
                
                decimal MinQuantityPerAnnum = APT_Constants.INTEGER_ZERO;
                decimal MinRevenuePerAnnum = APT_Constants.INTEGER_ZERO;
                
                //current time
                dateTime gmt = system.now();
                Datetime local = gmt.Date();
                local = local.addHours(gmt.hour());
                local = local.addMinutes(gmt.minute());
                local = local.addSeconds(gmt.second());
                
                if(mapProposalById.keySet() != null) {
                    set<Id> setProposalLineItemId = new set<Id>();
                    
                    Id rateRecordTypeId = Schema.SObjectType.APT_SAP_Rate__c.getRecordTypeInfosByName().get(APT_Constants.RATE).getRecordTypeId();
                    Id detailedRateRecordTypeId = Schema.SObjectType.APT_SAP_Rate__c.getRecordTypeInfosByName().get(APT_Constants.DETAILED_RATE).getRecordTypeId();
                    map<String, list<APT_SAP_Rate__c>> mapSAPRate = new map<String, list<APT_SAP_Rate__c>>();
                    //list<APT_SAP_Rate__c> listSAPRate;
                    map<Id, list<Apttus_Proposal__Proposal_Line_Item__c>> mapProposalLineItem = new map<Id, list<Apttus_Proposal__Proposal_Line_Item__c>>();
                    map<Id, Apttus_Proposal__Proposal_Line_Item__c> mapPLI = new map<Id, Apttus_Proposal__Proposal_Line_Item__c>();
                    map<String, Apttus_Proposal__Proposal_Line_Item__c> mapPrimaryPLI = new map<String, Apttus_Proposal__Proposal_Line_Item__c>();
                    map<String, list<Apttus_Proposal__Proposal_Line_Item__c>> mapOptionPLI = new map<String, list<Apttus_Proposal__Proposal_Line_Item__c>>();
                    for(Apttus_Proposal__Proposal_Line_Item__c pli : [SELECT Id, Name, APT_Charge_Code_Formula__c,
                                                                Apttus_Proposal__Proposal__c,
                                                                Apttus_Proposal__Proposal__r.Name,
                                                                Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c,
                                                                Apttus_QPConfig__IsPrimaryLine__c,
                                                                Apttus_QPConfig__ParentBundleNumber__c, 
                                                                Apttus_QPConfig__PrimaryLineNumber__c,
                                                                Apttus_QPConfig__AttributeValueId__c,
                                                                Apttus_QPConfig__DerivedFromId__c,
                                                                Apttus_Proposal__Product__c,
                                                                Apttus_Proposal__Product__r.ProductCode,
                                                                Apttus_QPConfig__OptionId__c,
                                                                Apttus_QPConfig__OptionId__r.ProductCode,
                                                                Apttus_QPConfig__OptionId__r.Name,
                                                                Apttus_QPConfig__NetPrice__c,
                                                                Apttus_QPConfig__ChargeType__c,
                                                                APT_Rate_Card_Key__c,
                                                                Apttus_QPConfig__Quantity2__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Price_Structure__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Band__c,
                                                                Apttus_QPConfig__AttributeValueId__r.Category__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Consignment_Pricing__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Day_of_Delivery__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Estimated_Revenue__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Industry__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Letters__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Signature_On_Delivery__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Volume_Data__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.Name,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Minimum_Quantity__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Returns_of_Total_Annual_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Up_to_500g_of_Total_Returns_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Average_Chargeable_Weight_Kg__c,
                                                                Apttus_QPConfig__AttributeValueId__r.Transit_cover__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Up_to_500g_Rate__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Base_Uplift_Percentage__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Calculated_Uplift_Percentage__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Average_Weight_Over_500g__c,
                                                                Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_1_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_2_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_3_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_4_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_5_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_6_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_7_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_8_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Airmail_Letters_Annual_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelsLT2kgAnnualVolume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelsGT2kgAnnualVolume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_ECI_Documents_Annual_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.ECI_Merchandise_Annual_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_PackNTrackInternationalAnnualVolume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_RegisteredPostInternationalAnnualVol__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_ECI_Documents_AVG_Weight_KG__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_ECI_Merchandise_AVG_Weight_KG__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelGT2kgAVGWeightKG__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelLT2kgAVGWeightKG__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Airmail_Letters_AVG_Weight_KG__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_RegisteredPostInternationalAVGWeight__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_PackNTrackInternationalAVGWeightKG__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Domestic_Customer__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_1Digital_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_2Digital_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_3Digital_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_4Digital_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_5Digital_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_6Digital_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_7Digital_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_8Digital_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Zone_9Digital_Dispersion__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Int_Express_Document_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_Int_Express_Doc_Weight_Kg__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Express_Merchandise__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Exp_Merch_Weight_Kgs__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Standard_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Standard_Weight_Kgs__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Standard_W_Sig_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Std_W_Sig_Weight_Kgs__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Economy_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Economy_Weight_Kgs__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Economy_W_Sig_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Eco_W_Sig_Weight_Kgs__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Returns_Express_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Returns_Exp_Weight_Kgs__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Returns_Std_Ut_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Ret_Std_Ut_Weight_Kgs__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Airmail_Letters_Volume__c,
                                                                Apttus_QPConfig__AttributeValueId__r.APT_International_Airmail_Let_Weight_Kgs__c,
                                                                CreatedById,
                                                                CreatedBy.Name
                                                                FROM Apttus_Proposal__Proposal_Line_Item__c
                                                                WHERE Apttus_Proposal__Proposal__c IN :mapProposalById.keySet()]) {
                        
                        mapPLI.put(pli.Id, pli);
                        
                        //min quantity
                        if(String.isNotBlank(pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c) && pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED) && String.isNotBlank(pli.Apttus_Proposal__Product__r.ProductCode) && (pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)) && String.isEmpty(pli.Apttus_QPConfig__OptionId__c) && pli.Apttus_QPConfig__IsPrimaryLine__c) {
                            if(pli.Apttus_QPConfig__AttributeValueId__r.APT_Minimum_Quantity__c != null) {
                                MinQuantityPerAnnum = pli.Apttus_QPConfig__AttributeValueId__r.APT_Minimum_Quantity__c;
                            }
                        }
                        
                        //min revenue
                        if(String.isNotBlank(pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c) && pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED) && String.isNotBlank(pli.Apttus_Proposal__Product__r.ProductCode ) && 
                                (pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)|| pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) ||
                                 pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL))
                                 && String.isEmpty(pli.Apttus_QPConfig__OptionId__c) && pli.Apttus_QPConfig__IsPrimaryLine__c && !String.isEmpty(pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c)) {
                            if(pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.ToLowerCase().contains(APT_Constants.OPERATOR_LESS_THAN)) {
                              Integer iIndex = pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.ToLowerCase().indexOf(APT_Constants.OPERATOR_LESS_THAN);
                                String revenue = pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.subString(iIndex + 11, pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.length());   
                                if(String.isNotBlank(revenue)) {
                                    //revenue committment has special characters
                                    if(revenue.contains(APT_Constants.SEPERATOR_COMMA)) {
                                        revenue = revenue.replaceAll(APT_Constants.SEPERATOR_COMMA, APT_Constants.EMPTY_STRING);                      
                                    }
                                    
                                    MinRevenuePerAnnum = decimal.valueOf(revenue);
                                }   
                            } else if(pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.equalsIgnoreCase(APT_Constants.REVENUE_COMMITTMENT_ABOVE_50000)) {
                                String revenue = pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.subString(6, pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.length());
                                if(revenue != null){
                                  if(revenue.contains(APT_Constants.SEPERATOR_COMMA)) {
                                      revenue = revenue.replaceAll(APT_Constants.SEPERATOR_COMMA, APT_Constants.EMPTY_STRING);
                                  }
                                  MinRevenuePerAnnum = decimal.valueOf(revenue);
                                }                
                            }
                            //if(false == pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.ToLowerCase().contains(APT_Constants.OPERATOR_LESS_THAN)) 
                            else{
                              Integer iIndex = pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.indexOf(APT_Constants.ADD_HYPHEN);
                                String minRevenueRange = pli.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.subString(0, iIndex - 1);
                                if(String.isNotBlank(minRevenueRange)) {
                                    //revenue committment has special characters
                                    if(minRevenueRange.contains(APT_Constants.SEPERATOR_COMMA)) {
                                        minRevenueRange = minRevenueRange.replaceAll(APT_Constants.SEPERATOR_COMMA, APT_Constants.EMPTY_STRING);                      
                                    }
                                    
                                    MinRevenuePerAnnum =  decimal.valueOf(minRevenueRange);
                                }
                            } 
                        }
                        
                        setProposalLineItemId.add(pli.Id);
                        
                        list<Apttus_Proposal__Proposal_Line_Item__c> listPLI = mapProposalLineItem.get(pli.Apttus_Proposal__Proposal__c);
                        if(listPLI != null) {
                            listPLI.add(pli);
                            mapProposalLineItem.put(pli.Apttus_Proposal__Proposal__c, listPLI);
                        } else {
                            listPLI = new list<Apttus_Proposal__Proposal_Line_Item__c>();
                            listPLI.add(pli);
                            mapProposalLineItem.put(pli.Apttus_Proposal__Proposal__c, listPLI);
                        }
                        
                        if(false == (pli.Apttus_QPConfig__ParentBundleNumber__c != null) && pli.Apttus_QPConfig__IsPrimaryLine__c) {
                            mapPrimaryPLI.put(pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__PrimaryLineNumber__c, pli);
                        }
                        
                        if(pli.Apttus_QPConfig__ParentBundleNumber__c != null) {
                            list<Apttus_Proposal__Proposal_Line_Item__c> listOptionPLI = mapOptionPLI.get(pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ParentBundleNumber__c);
                            if(listOptionPLI != null) {
                                listOptionPLI.add(pli);
                                mapOptionPLI.put(pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ParentBundleNumber__c, listOptionPLI);
                            } else {
                                listOptionPLI = new list<Apttus_Proposal__Proposal_Line_Item__c>();
                                listOptionPLI.add(pli);
                                mapOptionPLI.put(pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ParentBundleNumber__c, listOptionPLI);
                            }
                        }                    
                    }                   
                    
                    map<String, list<APT_SAP_SyncContractAndRatesService.RateType>> mapRate = new map<String, list<APT_SAP_SyncContractAndRatesService.RateType>>();
                    map<String, list<APT_SAP_SyncContractAndRatesService.DetailedRateType>> mapDetailedRate = new map<String, list<APT_SAP_SyncContractAndRatesService.DetailedRateType>>();
                    
                    if(setValidPLIId.size() > 0) {
                      APT_SAP_SyncContractAndRatesService.RateType rate1;
                      APT_SAP_SyncContractAndRatesService.DetailedRateType detailedRate1;
                      
                      list<APT_SAP_SyncContractAndRatesService.RateType> listRate1;
                      list<APT_SAP_SyncContractAndRatesService.DetailedRateType> listDetailedRate1;
                      for(Id pliId : setValidPLIId) {
                        list<APT_SAP_Rate__c> listSAPRate1 = [SELECT Id, recordTypeId, APT_Apttus_Contract__c, 
                                                          APT_Proposal_Line_Item__c, 
                                                          APT_Base_Rate__c, APT_Subsequent_Rate__c,
                                                          APT_Per_Kg_Rate__c, APT_Lookup_Full__c,
                                                          APT_Lookup_Sub__c, APT_RAF_Code__c,
                                                          APT_Service_Price_Description__c,
                                                          APT_Service_Price_Value__c, APT_Weight_Range_Code__c,
                                                          APT_Base_Rate_Manually_Adjusted_Flag__c,
                                                          APT_Per_Kg_Manually_Adjusted_Flag__c,
                                                          APT_Destination_Zone_Code__c,
                                                          APT_Display_Order_Sequence__c,
                                                          Calculated_Base_Rate__c,
                                                          Calculated_Per_Kg_Rate__c,
                                                          Calculated_Subsequent_Rate__c
                                                          FROM APT_SAP_Rate__c
                                                          WHERE APT_Proposal_Line_Item__c = :pliId
                                                          ORDER BY APT_Display_Order_Sequence__c, APT_Service_Price_Value__c];
                        
                        if(listSAPRate1 != null && listSAPRate1.size() > 0) {
                          system.debug('*** pliId ***'+pliId);
                          system.debug('*** listSAPRate size ***'+listSAPRate1.size());
                          for(APT_SAP_Rate__c sapRate : listSAPRate1) {
                              
                                Apttus_Proposal__Proposal_Line_Item__c pli = mapPLI.get(pliId);
                                
                                //DRAFT
                                rate1 = populateRate(sapRate);
                                listRate1 = mapRate.get(sapRate.APT_Apttus_Contract__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.APT_Proposal_Line_Item__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.RecordTypeId);
                                if(listRate1 != null) {
                                  listRate1.add(rate1);
                                  mapRate.put(sapRate.APT_Apttus_Contract__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.APT_Proposal_Line_Item__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.RecordTypeId, listRate1);
                                } else {
                                  listRate1 = new list<APT_SAP_SyncContractAndRatesService.RateType>();
                                  listRate1.add(rate1);
                                  mapRate.put(sapRate.APT_Apttus_Contract__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.APT_Proposal_Line_Item__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.RecordTypeId, listRate1);
                                }
                                
                                //FINAL
                                if(pli != null && String.isNotBlank(pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c) && pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED) && String.isNotBlank(pli.Apttus_Proposal__Product__r.ProductCode) && (pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) {
                                  detailedRate1 = populateDetailedRate(sapRate);
                                  system.debug('***** Detailed Rates ******'+detailedRate1);
                                  listDetailedRate1 = mapDetailedRate.get(sapRate.APT_Apttus_Contract__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.APT_Proposal_Line_Item__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.RecordTypeId);
                                  if(listDetailedRate1 != null) {
                                    listDetailedRate1.add(detailedRate1);
                                    mapDetailedRate.put(sapRate.APT_Apttus_Contract__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.APT_Proposal_Line_Item__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.RecordTypeId, listDetailedRate1);
                                  } else {
                                    listDetailedRate1 = new list<APT_SAP_SyncContractAndRatesService.DetailedRateType>();
                                    listDetailedRate1.add(detailedRate1);
                                    mapDetailedRate.put(sapRate.APT_Apttus_Contract__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.APT_Proposal_Line_Item__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.RecordTypeId, listDetailedRate1);
                                  }
                                }
                                
                                /**
                                listSAPRate = mapSAPRate.get(sapRate.APT_Apttus_Contract__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.APT_Proposal_Line_Item__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.RecordTypeId);
                                if(listSAPRate != null && listSAPRate.size() > 0) {
                                    listSAPRate.add(sapRate);
                                    mapSAPRate.put(sapRate.APT_Apttus_Contract__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.APT_Proposal_Line_Item__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.RecordTypeId, listSAPRate);
                                } else {
                                    listSAPRate = new list<APT_SAP_Rate__c>();
                                    listSAPRate.add(sapRate);
                                    mapSAPRate.put(sapRate.APT_Apttus_Contract__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.APT_Proposal_Line_Item__c + APT_Constants.SEPERATOR_SIMILARITY + sapRate.RecordTypeId, listSAPRate);
                                }
                                **/
                            } 
                        }                        
                      }                     
                    }
                    
                    list<APT_SAP_SyncContractAndRatesService.CustomerContractType> listCustomerContract = new list<APT_SAP_SyncContractAndRatesService.CustomerContractType>();
                    
                    APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = APT_R2T_International_Pricing_Properties__c.getValues(APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES);
                    
                    APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
                    
                    list<Apttus__APTS_Agreement__c> listUpdateAgreement = new list<Apttus__APTS_Agreement__c>();
                    
                    map<String, APT_SAP_SyncContractAndRatesService.ProductType> mapProduct = new map<String, APT_SAP_SyncContractAndRatesService.ProductType>();
                    map<String, list<APT_SAP_SyncContractAndRatesService.SubProducType>> mapListSubProducts = new map<String, list<APT_SAP_SyncContractAndRatesService.SubProducType>>();
                    map<String, APT_SAP_SyncContractAndRatesService.SubProducType> mapSubProduct = new map<String, APT_SAP_SyncContractAndRatesService.SubProducType>();
                    map<String, list<APT_SAP_SyncContractAndRatesService.RateCardType>> mapListRateCard = new map<String, list<APT_SAP_SyncContractAndRatesService.RateCardType>>();
                    Boolean existingProduct = false;
                    Boolean existingSubProduct = false;
                    
                    for(Apttus__APTS_Agreement__c agreement : listAgreement) {
                        agreement.APT_New_Rate_Card_Download__c = true;
                        listUpdateAgreement.add(agreement);
                        
                        APT_SAP_SyncContractAndRatesService.CustomerContractType CustomerContract = new APT_SAP_SyncContractAndRatesService.CustomerContractType();
                        list<APT_SAP_SyncContractAndRatesService.ProductType> listProduct = new list<APT_SAP_SyncContractAndRatesService.ProductType>();
                        
                        list<Apttus_Proposal__Proposal__c> listProposal = mapProposalByOppty.get(agreement.Apttus__Related_Opportunity__c);
                        if(listProposal != null) {
                            for(Apttus_Proposal__Proposal__c proposal : listProposal) {
                                APT_Operational_Schedule__c operationSchedule = mapOperationalSchedule.get(agreement.Id);
                                
                                String accId = mapAccountByProposal.get(proposal.Id);
                                Account acc = mapAccount.get(accId);
                                
                                Contact c = mapContact.get(agreement.Apttus__Primary_Contact__c);   //APOST-1372
                                                                
                                User salesRep = mapSalesRep.get(agreement.Owner.Id);
                                populateCustomerContract(CustomerContract, salesRep, c, Acc, mapSubAccount, agreement, listProposal, operationSchedule, proposal.APT_Method_of_Payment__c, MinQuantityPerAnnum, MinRevenuePerAnnum, local);
                                
                                list<Apttus_Proposal__Proposal_Line_Item__c> listPLI = mapProposalLineItem.get(proposal.Id);
                                
                                if(listPLI != null) {
                                    APT_SAP_SyncContractAndRatesService.ProductsType products1 = new APT_SAP_SyncContractAndRatesService.ProductsType();
                                    for(Apttus_Proposal__Proposal_Line_Item__c pli : listPLI) {
                                      system.debug('*** product code ***'+pli.Apttus_Proposal__Product__r.ProductCode);
                                        system.debug('*** condition ***'+setValidPLIId.contains(pli.Id));
                                        if(setValidPLIId.contains(pli.Id)) {
                                            existingProduct = false;
                                            existingSubProduct = false;                                    
                                            Apttus_Proposal__Proposal_Line_Item__c parentPLI = mapPrimaryPLI.get(pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ParentBundleNumber__c);
                                            list<Apttus_Proposal__Proposal_Line_Item__c> listOptionPLI = mapOptionPLI.get(pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ParentBundleNumber__c);
                                                                                        
                                            APT_SAP_SyncContractAndRatesService.ProductType product;
                                            APT_SAP_SyncContractAndRatesService.SubProductsType SubProducts = new APT_SAP_SyncContractAndRatesService.SubProductsType();
                                            list<APT_SAP_SyncContractAndRatesService.SubProducType> listSubProduct;
                                            APT_SAP_SyncContractAndRatesService.SubProducType SubProduct;
                                            APT_SAP_SyncContractAndRatesService.SubProductDetailsType SubProductDetails = new APT_SAP_SyncContractAndRatesService.SubProductDetailsType();
                                            APT_SAP_SyncContractAndRatesService.RateCards_element rateCards = new APT_SAP_SyncContractAndRatesService.RateCards_element();
                                            list<APT_SAP_SyncContractAndRatesService.RateCardType> listRateCard;
                                            
                                            APT_SAP_SyncContractAndRatesService.RateCardType rateCard = new APT_SAP_SyncContractAndRatesService.RateCardType();
                                                                                        
                                            if(parentPLI != null) {
                                              system.debug('*** parentPLI.Apttus_Proposal__Product__r.ProductCode ***'+parentPLI.Apttus_Proposal__Product__r.ProductCode);
                                              //1661
                                              rateCard = populateRateCard(agreement.APT_Contract_Type__c, rateCard, pli, parentPLI, listOptionPLI, r2tSystemProperties, r2tInternationalPricingProperties, local);
                                              //1661
                                              
                                                if(!String.isEmpty(parentPLI.Apttus_Proposal__Product__r.ProductCode) && (parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) {
                                                    //domestic
                                                    if(mapProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode) != null){
                                                        product = mapProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode);
                                                        existingProduct = true;
                                                    } else {
                                                        product = new APT_SAP_SyncContractAndRatesService.ProductType();                                                        
                                                        existingProduct = false;
                                                        mapProduct.put(parentPLI.Apttus_Proposal__Product__r.ProductCode, product);                                           
                                                    }
                                                    
                                                    if(mapListSubProducts.get(parentPLI.Apttus_Proposal__Product__r.ProductCode) != null) {
                                                        listSubProduct = mapListSubProducts.get(parentPLI.Apttus_Proposal__Product__r.ProductCode);
                                                    } else {
                                                        listSubProduct = new list<APT_SAP_SyncContractAndRatesService.SubProducType>();
                                                        mapListSubProducts.put(parentPLI.Apttus_Proposal__Product__r.ProductCode, listSubProduct);
                                                    }    
                                                    
                                                    if(mapSubProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode) != null) {
                                                        SubProduct = mapSubProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode);
                                                        existingSubProduct = true;
                                                    } else {
                                                        SubProduct = new APT_SAP_SyncContractAndRatesService.SubProducType();
                                                        existingSubProduct = false;
                                                        mapSubProduct.put(parentPLI.Apttus_Proposal__Product__r.ProductCode, SubProduct);                                                        
                                                    }
                                                    
                                                    if(mapListRateCard.get(parentPLI.Apttus_Proposal__Product__r.ProductCode) != null) {
                                                        listRateCard = mapListRateCard.get(parentPLI.Apttus_Proposal__Product__r.ProductCode);
                                                    } else {
                                                        listRateCard = new list<APT_SAP_SyncContractAndRatesService.RateCardType>();
                                                        mapListRateCard.put(parentPLI.Apttus_Proposal__Product__r.ProductCode, listRateCard);
                                                    }
                                                    
                                                    product.Customer = populateCustomer(c, acc, mapSubAccount, proposal.APT_Method_of_Payment__c, MinQuantityPerAnnum, null);
                                                    
                                                } else if(!String.isEmpty(parentPLI.Apttus_Proposal__Product__r.ProductCode)  &&
                                                                     (parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)||
                                                                      parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) ||
                                                                      parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL))) {
                                                    //international
                                                    if(false == parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c && true == parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Letters__c) {
                                                        //CSP
                                                        if(mapProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP) != null) {
                                                            product = mapProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP);
                                                            existingProduct = true;
                                                        } else {
                                                            product = new APT_SAP_SyncContractAndRatesService.ProductType();                                                        
                                                            existingProduct = false; 
                                                            mapProduct.put(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP, product);  
                                                        }
                                                        
                                                        //listSubProduct = new list<APT_SAP_SyncContractAndRatesService.SubProducType>();                                                
                                                        //SubProduct = new APT_SAP_SyncContractAndRatesService.SubProducType();
                                                        //listRateCard = new list<APT_SAP_SyncContractAndRatesService.RateCardType>();  
                                                                                                                
                                                        if(mapListSubProducts.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP) != null) {
                                                            listSubProduct = mapListSubProducts.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP);
                                                        } else {
                                                            listSubProduct = new list<APT_SAP_SyncContractAndRatesService.SubProducType>();
                                                            mapListSubProducts.put(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP, listSubProduct);
                                                        }                                                        
                                                        
                                                        if(mapSubProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c) != null) {
                                                            SubProduct = mapSubProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c);
                                                            existingSubProduct = true;
                                                        } else {
                                                            SubProduct = new APT_SAP_SyncContractAndRatesService.SubProducType();
                                                            existingSubProduct = false;
                                                            mapSubProduct.put(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c, SubProduct);
                                                        }                                                        
                                                        
                                                        if(mapListRateCard.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c) != null) {
                                                            listRateCard = mapListRateCard.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c);
                                                        } else {
                                                            listRateCard = new list<APT_SAP_SyncContractAndRatesService.RateCardType>();
                                                            mapListRateCard.put(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_CSP + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c, listRateCard);
                                                        }                                                        
                                                    } else {
                                                        //PCMS
                                                       
                                                        if(mapProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS) != null) {
                                                            product = mapProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS);
                                                            existingProduct = true;
                                                        } else {
                                                            product = new APT_SAP_SyncContractAndRatesService.ProductType();                                                        
                                                            existingProduct = false;
                                                            mapProduct.put(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS, product);   
                                                        }
                                                        
                                                        //listSubProduct = new list<APT_SAP_SyncContractAndRatesService.SubProducType>();                                                
                                                        //SubProduct = new APT_SAP_SyncContractAndRatesService.SubProducType();
                                                        //listRateCard = new list<APT_SAP_SyncContractAndRatesService.RateCardType>();
                                                                                                                
                                                        if(mapListSubProducts.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS) != null) {
                                                            listSubProduct = mapListSubProducts.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS);
                                                        } else {
                                                            listSubProduct = new list<APT_SAP_SyncContractAndRatesService.SubProducType>();
                                                            mapListSubProducts.put(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS, listSubProduct);
                                                        }                                                        
                                                        
                                                        if(mapSubProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c) != null) {
                                                            SubProduct = mapSubProduct.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c);
                                                            existingSubProduct = true;
                                                        } else {
                                                            SubProduct = new APT_SAP_SyncContractAndRatesService.SubProducType();
                                                            existingSubProduct = false;
                                                            mapSubProduct.put(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c, SubProduct);
                                                        }                                                        
                                                        
                                                        if(mapListRateCard.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c) != null) {
                                                            listRateCard = mapListRateCard.get(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c);
                                                        } else {
                                                            listRateCard = new list<APT_SAP_SyncContractAndRatesService.RateCardType>();
                                                            mapListRateCard.put(parentPLI.Apttus_Proposal__Product__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + APT_Constants.PROVISIONING_METHOD_PCMS + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__ChargeType__c, listRateCard);
                                                        }

                                                          }                                                        
                                                                                                        
                                                    product.Customer = populateCustomer(c, acc, mapSubAccount, proposal.APT_Method_of_Payment__c, null, MinRevenuePerAnnum);
                                                    
                                                 } else {}
                                            } 
                                            //1661
                                            //UMS or Print Post
                                            else if(String.isNotBlank(pli.Apttus_Proposal__Product__r.ProductCode) && (pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)) ) {
                                              system.debug('*** pli.Apttus_Proposal__Product__r.ProductCode ***'+pli.Apttus_Proposal__Product__r.ProductCode);
                                              if(mapProduct.get(pli.Apttus_Proposal__Product__r.ProductCode) != null) {
                                                product = mapProduct.get(pli.Apttus_Proposal__Product__r.ProductCode);  
                                                existingProduct = true;                                              
                                                system.debug('*** existing product ***');
                                              } else {
                                                product = new APT_SAP_SyncContractAndRatesService.ProductType();
                                                mapProduct.put(pli.Apttus_Proposal__Product__r.ProductCode, product);
                                                existingProduct = false;
                                                system.debug('*** new product ***');
                                              }
                                              
                                              if(mapListSubProducts.get(pli.Apttus_Proposal__Product__r.ProductCode) != null) {
                                                    listSubProduct = mapListSubProducts.get(pli.Apttus_Proposal__Product__r.ProductCode);
                                                } else {
                                                    listSubProduct = new list<APT_SAP_SyncContractAndRatesService.SubProducType>();
                                                    mapListSubProducts.put(pli.Apttus_Proposal__Product__r.ProductCode, listSubProduct);                                                    
                                                }                                                        
                                                
                                                if(mapSubProduct.get(pli.Apttus_Proposal__Product__r.ProductCode) != null) {
                                                    SubProduct = mapSubProduct.get(pli.Apttus_Proposal__Product__r.ProductCode);
                                                    existingSubProduct = true;
                                                } else {
                                                    SubProduct = new APT_SAP_SyncContractAndRatesService.SubProducType();
                                                    existingSubProduct = false;
                                                    mapSubProduct.put(pli.Apttus_Proposal__Product__r.ProductCode, SubProduct);
                                                }                                                        
                                                
                                                if(mapListRateCard.get(pli.Apttus_Proposal__Product__r.ProductCode) != null) {
                                                    listRateCard = mapListRateCard.get(pli.Apttus_Proposal__Product__r.ProductCode);
                                                } else {
                                                    listRateCard = new list<APT_SAP_SyncContractAndRatesService.RateCardType>();
                                                    mapListRateCard.put(pli.Apttus_Proposal__Product__r.ProductCode, listRateCard);
                                                }
                                            }
                                            //1661
                                            else {
                                                product = new APT_SAP_SyncContractAndRatesService.ProductType();
                                                listSubProduct = new list<APT_SAP_SyncContractAndRatesService.SubProducType>();                                                
                                                SubProduct = new APT_SAP_SyncContractAndRatesService.SubProducType();
                                                listRateCard = new list<APT_SAP_SyncContractAndRatesService.RateCardType>();                                                
                                            }                                            
                                            system.debug('*** product code ***'+pli.Apttus_Proposal__Product__r.ProductCode);
                                            system.debug('*** ratecard type ***'+rateCard.Type_x);
                                            product.ProductDetails = populateProductDetails(rateCard.Type_x, pli.Apttus_Proposal__Product__r.ProductCode, operationSchedule);
                                            //product.Customer = populateCustomer(c, acc, mapSubAccount, proposal.APT_Method_of_Payment__c, MinQuantityPerAnnum, MinRevenuePerAnnum);
                                            product.SalesRepresentative = populateSalesRepresentative(salesRep, c, acc, mapSubAccount, proposal.APT_Method_of_Payment__c);
                                            product.LodgementPoints = populateLodgementPoints(product.ProductDetails.Name, operationSchedule, mapLodgementPoint, parentPLI, acc, mapSubAccount, proposal.APT_Method_of_Payment__c, mapAgreementLodgementPoint);
                                            product.CollectionPoints = populateCollectionPoints(product.ProductDetails.Name, operationSchedule, mapCollectionPoint, parentPLI, acc, mapSubAccount, proposal.APT_Method_of_Payment__c, mapAgreementLodgementPoint);
                                            
                                            //mapProduct.put(parentPLI.Apttus_Proposal__Product__r.ProductCode, product);
                                            //mapListSubProducts.put(parentPLI.Apttus_Proposal__Product__r.ProductCode, listSubProduct);                                            
                                            //mapSubProduct.put(parentPLI.Apttus_Proposal__Product__r.ProductCode, SubProduct);                                                                                        
                                            //mapListRateCard.put(parentPLI.Apttus_Proposal__Product__r.ProductCode, listRateCard);
                                            
                                            //list<APT_SAP_SyncContractAndRatesService.SubProducType> listSubProduct = new list<APT_SAP_SyncContractAndRatesService.SubProducType>();
                                            //list<APT_SAP_SyncContractAndRatesService.RateCardType> listRateCard = new list<APT_SAP_SyncContractAndRatesService.RateCardType>();                                            
                                            list<APT_SAP_SyncContractAndRatesService.RateType> listRate = new list<APT_SAP_SyncContractAndRatesService.RateType>();
                                            list<APT_SAP_SyncContractAndRatesService.DetailedRateType> listDetailedRate = new list<APT_SAP_SyncContractAndRatesService.DetailedRateType>();
                                            APT_SAP_SyncContractAndRatesService.RatesDetails_element ratesDetails = new APT_SAP_SyncContractAndRatesService.RatesDetails_element();
                                            APT_SAP_SyncContractAndRatesService.DetailedRatesDetails_element detailedRatesDetails = new APT_SAP_SyncContractAndRatesService.DetailedRatesDetails_element();
                                            
                                                                                        
                                            //DRAFT
                                            listRate = mapRate.get(agreement.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.Id + APT_Constants.SEPERATOR_SIMILARITY + rateRecordTypeId);
                                            
                                            
                                            //FINAL
                                            //1844
                                            //if(String.isNotBlank(agreement.APT_Contract_Type__c) && !agreement.APT_Contract_Type__c.equalsIgnoreCase(APT_Constants.RECORD_TYPE_RENEWAL_CONTRACT ) && String.isNotBlank(pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c) && pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED) && String.isNotBlank(pli.Apttus_Proposal__Product__r.ProductCode) && (pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) {
                                            if(String.isNotBlank(agreement.APT_Contract_Type__c) && String.isNotBlank(pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c) && pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED) && String.isNotBlank(pli.Apttus_Proposal__Product__r.ProductCode) && (pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) {
                                              listDetailedRate = mapDetailedRate.get(agreement.Id + APT_Constants.SEPERATOR_SIMILARITY + pli.Id + APT_Constants.SEPERATOR_SIMILARITY + detailedRateRecordTypeId);
                                            }
                                            
                                            ratesDetails.Rate = listRate;                                            
                                            detailedRatesDetails.DetailedRate = listDetailedRate;                                            
                                            rateCard.RatesDetails = ratesDetails;                                            
                                            rateCard.DetailedRatesDetails = detailedRatesDetails;
                                            listRateCard.add(rateCard);
                                            rateCards.RateCard = listRateCard;
                                                                                        
                                            populateSubProductDetails(SubProductDetails, pli, product, r2tInternationalPricingProperties);
                                            SubProductDetails.RateCards = rateCards;
                                            
                                            SubProduct.SubProductDetails = SubProductDetails;
                                            //listSubProduct.add(SubProduct); 
                                            
                                            if(!existingSubProduct) {
                                                listSubProduct.add(SubProduct);
                                            }
                                            
                                            SubProducts.SubProduct = listSubProduct;
                                            
                                            product.SubProducts = SubProducts; 
                                            
                                            if(!existingProduct) {
                                                listProduct.add(product);                                                
                                            }
                                        }                                    
                                    }
                                    
                                    products1.Product = listProduct;
                                    
                                    CustomerContract.Products = products1;                                      
                                }
                            }
                        }
                        listCustomerContract.add(CustomerContract);
                    }                    
                    syncContractRates(listCustomerContract, listResponseWrapper, local);
                    
                    update listUpdateAgreement;
                    
                    
                }                
            }            
        } catch(System.Exception ex) {
            //APOST-1761
            String exMessage = ex.getMessage();
            if(exMessage.contains(APT_Constants.SOAP_FAULT) && exMessage.contains(APT_Constants.FAULT_CODE)) {
                Integer iIndexSOAPFault = exMessage.indexOf(APT_Constants.SOAP_FAULT);
                Integer iIndexFaultCode = exMessage.indexOf(APT_Constants.FAULT_CODE);
                //Integer iIndexFaultFactor = exMessage.indexOf('faultactor=');
                String strSOAPFault = exMessage.subString(iIndexSOAPFault + APT_Constants.SOAP_FAULT.length(), iIndexFaultCode);
                                
                setErrorMessage.add(strSOAPFault);
            } else {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getLineNumber() + APT_Constants.SEPERATOR_SPACE + ex.getMessage()));
                setErrorMessage.add(ex.getLineNumber() + APT_Constants.SEPERATOR_SPACE + ex.getMessage());
            }
            //APOST-1761  
        }
    }
    
    /**
        Finish
     */
    global void finish(Database.BatchableContext BC) {
        //finish
        
        if(!Test.isRunningTest()) {
          APT_DeleteSAPRatesBatch controller = new APT_DeleteSAPRatesBatch(setValidPLIId);
          //database.executeBatch(controller, 1);
          // SOQL 50001 fix - increase batch size from 1 to 2000 due to changes at QueryLocator in start() to query on SAP Rate records
          database.executeBatch(controller, 2000);
        }
        
        
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :BC.getJobId()];
                        
        if(a.NumberOfErrors > 0) {
            setErrorMessage.add(a.ExtendedStatus);
        }
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
        //get email addresses
        APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
        String emailAddresses;            
        if(r2tSystemProperties != null) {            
            if(!String.isEMpty(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c)) {
                emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
            }
        } 
        list<String> toAddresses = new list<String>();
        if(!String.isEmpty(emailAddresses)) {
            toAddresses = emailAddresses.split(APT_Constants.SEPERATOR_COMMA);
        }
        mail.setToAddresses(toAddresses);
        
        String responseMsg;
        for(syncContractAndRatesResultWrapper responseWrapper : listResponseWrapper) {
            if(String.isNotBlank(responseMsg)) {
                responseMsg += APT_Constants.SEPERATOR_NEW_LINE + APT_Constants.SEPERATOR_NEW_LINE + APT_Constants.SEPERATOR_NEW_LINE + APT_Constants.CONTRACT_NUMBER + APT_Constants.SEPERATOR_COLON + APT_Constants.SEPERATOR_SPACE + responseWrapper.contractNumber + APT_Constants.SEPERATOR_COMMA + APT_Constants.SEPERATOR_SPACE + APT_Constants.SAPERP_CONTRACT_NUMBER + APT_Constants.SEPERATOR_COLON + APT_Constants.SEPERATOR_SPACE + responseWrapper.SAPERPContractNumber + APT_Constants.SEPERATOR_COMMA + APT_Constants.SEPERATOR_SPACE + APT_Constants.BUSINESS_REFERENCE_ID + APT_Constants.SEPERATOR_COLON + APT_Constants.SEPERATOR_SPACE + responseWrapper.businessReferenceId + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND.ToLowerCase() + APT_Constants.SEPERATOR_SPACE + APT_Constants.RESPONSE + APT_Constants.SEPERATOR_COLON + APT_Constants.SEPERATOR_SPACE + responseWrapper.strResponse;
            } else {
                responseMsg = APT_Constants.CONTRACT_NUMBER + APT_Constants.SEPERATOR_COLON + APT_Constants.SEPERATOR_SPACE + responseWrapper.contractNumber + APT_Constants.SEPERATOR_COMMA + APT_Constants.SEPERATOR_SPACE + APT_Constants.SAPERP_CONTRACT_NUMBER + APT_Constants.SEPERATOR_COLON + APT_Constants.SEPERATOR_SPACE  + responseWrapper.SAPERPContractNumber + APT_Constants.SEPERATOR_COMMA + APT_Constants.SEPERATOR_SPACE + APT_Constants.BUSINESS_REFERENCE_ID + APT_Constants.SEPERATOR_COLON + APT_Constants.SEPERATOR_SPACE + responseWrapper.businessReferenceId + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND.ToLowerCase() + APT_Constants.SEPERATOR_SPACE + APT_Constants.RESPONSE + APT_Constants.SEPERATOR_COLON + APT_Constants.SEPERATOR_SPACE + responseWrapper.strResponse;
            }                
        }
        
        if(setErrorMessage.size() > 0) {            
            mail.setSubject(APT_Constants.SYNC_CONTRACT_RATES_ERROR);
            
            //Handle Batch Error Message 
            Integer iErrorCount = setErrorMessage.size();
                
            String errorMessage;
            for(String errorMessage1 : setErrorMessage) {
                if(String.isNotBlank(errorMessage)) {
                    errorMessage += APT_Constants.SEPERATOR_NEW_LINE + errorMessage1;
                } else {
                    errorMessage = errorMessage1;
                }
            }
            
            //add Batch Error Message in Email
            if(String.isNotBlank(errorMessage) && String.isNotBlank(responseMsg)) {
                mail.setPlainTextBody(APT_Constants.SYNC_CONTRACT_RATES_BATCH_JOB_COMPLETED_WITH + iErrorCount + APT_Constants.FAILURES_AND_RESPONSES + responseMsg + APT_Constants.ERRORS_AND_NEW_LINE + errorMessage);
            } else{
                mail.setPlainTextBody(APT_Constants.SYNC_CONTRACT_RATES_BATCH_JOB_COMPLETED_WITH + iErrorCount + APT_Constants.EMAIL_PLAIN_TEXT_PART_3 + errorMessage);
            }
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } else {
            mail.setSubject(APT_Constants.SYNC_CONTRACT_RATES_RESPONSE);
            
            mail.setPlainTextBody(APT_Constants.SYNC_CONTRACT_RATES_RESPONSE_MSG + responseMsg);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    
    /**
        Send Sync Contract Rates request
     */
    public static void syncContractRates(list<APT_SAP_SyncContractAndRatesService.CustomerContractType> listCustomerContract, /*set<String> setResponse, set<String> setBusinessReferenceID,*/ 
                                            list<syncContractAndRatesResultWrapper> listResponseWrapper,
                                            datetime local) {
                                                system.debug('*** INSIDE syncContractRates');
        if(listCustomerContract != null) {
            for(APT_SAP_SyncContractAndRatesService.CustomerContractType CustomerContract : listCustomerContract) {
                APT_SAP_CustomerContractService service = new APT_SAP_CustomerContractService();
                APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1 endPoint = new APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1();
                
                endPoint.inputHttpHeaders_x  = APT_WebServiceUtility.getinputHttpHeaders() ;
                endPoint.Header = APT_WebServiceUtility.getSyncContractRatesInterfaceHeader(APT_Constants.SYNC_CONTRACT_RATES, local);
                endpoint.timeout_x = APT_WebServiceUtility.DEFAULT_WEBSERVICE_TIMEOUT;
                
                APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
                if(r2tSystemProperty != null && String.isNotBlank(r2tSystemProperty.APT_Sync_Contract_Rate_End_Point_URL__c)) {
                    endPoint.endpoint_x = r2tSystemProperty.APT_Sync_Contract_Rate_End_Point_URL__c;
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SOAP_ENDPOINT_EXCEPTION));
                }
                 
                system.debug('***** Input to Tibco *****' +CustomerContract);               
                APT_SAP_SyncContractAndRatesService.syncContractAndRatesResponseType response = endPoint.syncContractAndRates_v1(CustomerContract);
                system.debug('***Response from TIBCO :' +response.ResponseDescription);
                syncContractAndRatesResultWrapper responseWrapper = new syncContractAndRatesResultWrapper();                
                responseWrapper.strResponse = response.ResponseDescription;
                responseWrapper.contractNumber = CustomerContract.ContractDetails.Id;
                responseWrapper.SAPERPContractNumber = CustomerContract.ContractDetails.SAPERPContractNumber;
                responseWrapper.businessReferenceId = endPoint.Header.BusinessReferenceID;
                listResponseWrapper.add(responseWrapper);
            }
        }
    }
     
    /**
        This method will return local time
     */
    public static String getLocalTime(datetime local) {
        String year = string.valueOf(system.now().year());
        String month = string.valueOf(system.now().month());
        String day = string.valueOf(system.now().day());
        
        String hour = string.valueOf(system.now().hour());
        String minute = string.valueOf(local.minute());
        String second = string.valueOf(local.second());
        
        
        String strTime = year+APT_Constants.ADD_HYPHEN+month+APT_Constants.ADD_HYPHEN+day+APT_Constants.SEPERATOR_SPACE+hour+APT_Constants.SEPERATOR_COLON+minute+APT_Constants.SEPERATOR_COLON+second ;
        return strTime;
    }
    
    /**
        This method will populate Customer Contract information
     */
    public static void populateCustomerContract(APT_SAP_SyncContractAndRatesService.CustomerContractType CustomerContract,
                                                User salesRep, 
                                                Contact c,
                                                Account acc,
                                                map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                Apttus__APTS_Agreement__c agreement,
                                                list<Apttus_Proposal__Proposal__c> listProposal,
                                                APT_Operational_Schedule__c operationSchedule,
                                                String paymentMethod,
                                                decimal MinQuantityPerAnnum,
                                                decimal MinRevenuePerAnnum,
                                                datetime local) {
        
        CustomerContract.SAPFilesnames = populateSAPFilesnames(agreement, operationSchedule, local);
        System.debug('***SAPFilesnames: ' + CustomerContract.SAPFilesnames);
        CustomerContract.ContractDetails = populateContractDetails(agreement, listProposal, operationSchedule);
        CustomerContract.Customer = populateCustomer(c, acc, mapSubAccount, paymentMethod, MinQuantityPerAnnum, MinRevenuePerAnnum);
        CustomerContract.SalesRepresentative = populateSalesRepresentative(salesRep, c, acc, mapSubAccount, paymentMethod);        
    }
    
    /**
        This method will populate SAP File Names
     */
    public static APT_SAP_SyncContractAndRatesService.SAPFilesnames_element populateSAPFilesnames(Apttus__APTS_Agreement__c agreement,
                                                                                                APT_Operational_Schedule__c operationSchedule,
                                                                                                datetime local) {
        APT_SAP_SyncContractAndRatesService.SAPFilesnames_element SAPFilesnames = new APT_SAP_SyncContractAndRatesService.SAPFilesnames_element();
                
        if(agreement != null) {
            String productGroup;
            if(operationSchedule != null){
                if(true == operationSchedule.APT_Parcel__c) {
                    //productGroup = 'PARCEL';
                    productGroup = APT_Constants.PRODUCT_GROUP_PARCEL;
                } 
                
                if(true == operationSchedule.APT_International_Postal__c){
                    if(!String.isEmpty(productGroup)) {
                        //productGroup += 'INTERNATIONAL POSTAL';
                        productGroup += APT_Constants.PRODUCT_GROUP_INTERNATIONAL_POSTAL;                        
                    } else {
                        //productGroup = 'INTERNATIONAL POSTAL';
                        productGroup = APT_Constants.PRODUCT_GROUP_INTERNATIONAL_POSTAL;
                    }               
                }   
            } 
            
            //APOST-1272
            String accountName = agreement.Apttus__Account__r.Name;
            if(!String.isEmpty(accountName)) {
                Pattern nonWordChar = Pattern.compile(APT_Constants.SPECIAL_CHAR_PATTERN);
                accountName = nonWordChar.matcher(accountName).replaceAll(APT_Constants.EMPTY_STRING);
                
                if(accountName.length() > 30) {
                    accountName = accountName.subString(0, 30);
                }
            }
            
            //APOSt-1253
            String totalContractValue;
            if(agreement.Apttus__Total_Contract_Value__c != null) {
                totalContractValue = String.valueOf(Integer.valueOf(agreement.Apttus__Total_Contract_Value__c));
            }
            
            /*
             * STP-2246 | Update CSV filename to swap Case Number with Contract Number
             * Change: Convert special character "."(dot) into "_"(underscore) for the naming of the CSV file creation
             * Reason: TIBCO integration does not recognise "."(dot) character
             */ 
            String updateContractNumber = agreement.Apttus__FF_Agreement_Number__c.replace('.','_');
            if(!String.isEmpty(agreement.APT_Contract_Type__c) && !agreement.APT_Contract_Type__c.equalsIgnoreCase(APT_Constants.CONTRACT_TYPE_RENEWAL_CONTRACT)) {//APOST-1255
                SAPFilesnames.ContractFilename = updateContractNumber + APT_Constants.SEPERATOR_UNDER_SCROLL + accountName + APT_Constants.SEPERATOR_UNDER_SCROLL + 
                                            APT_Constants.UPLOAD_NEW_CONTRACT_INFO + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            productGroup + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            totalContractValue + APT_Constants.SEPERATOR_UNDER_SCROLL + getLocalTime(local);
                                            
                SAPFilesnames.RatecardsFilename = updateContractNumber + APT_Constants.SEPERATOR_UNDER_SCROLL + accountName + APT_Constants.SEPERATOR_UNDER_SCROLL + 
                                            APT_Constants.UPLOAD_NEW_CONTRACT_RATE_CARD + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            productGroup + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            totalContractValue + APT_Constants.SEPERATOR_UNDER_SCROLL + getLocalTime(local);
                                            
                SAPFilesnames.DetailedRatesFilename = updateContractNumber + APT_Constants.SEPERATOR_UNDER_SCROLL + accountName + APT_Constants.SEPERATOR_UNDER_SCROLL + 
                                            APT_Constants.UPLOAD_NEW_CONTRACT_RATES + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            productGroup + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            totalContractValue + APT_Constants.SEPERATOR_UNDER_SCROLL + getLocalTime(local);
                                            
            } else if(!String.isEmpty(agreement.APT_Contract_Type__c) && agreement.APT_Contract_Type__c.equalsIgnoreCase(APT_Constants.CONTRACT_TYPE_RENEWAL_CONTRACT)) {
                SAPFilesnames.ContractFilename = updateContractNumber + APT_Constants.SEPERATOR_UNDER_SCROLL + accountName + APT_Constants.SEPERATOR_UNDER_SCROLL + 
                                            APT_Constants.UPLOAD_RENEWAL_CONTRACT_INFO + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            productGroup + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            totalContractValue + APT_Constants.SEPERATOR_UNDER_SCROLL + getLocalTime(local);
                
                SAPFilesnames.RatecardsFilename = updateContractNumber + APT_Constants.SEPERATOR_UNDER_SCROLL + accountName + APT_Constants.SEPERATOR_UNDER_SCROLL + 
                                            APT_Constants.UPLOAD_RENEWAL_CONTRACT_RATE_CARD + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            productGroup + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            totalContractValue + APT_Constants.SEPERATOR_UNDER_SCROLL + getLocalTime(local);
                                         
                SAPFilesnames.DetailedRatesFilename = updateContractNumber + APT_Constants.SEPERATOR_UNDER_SCROLL + accountName + APT_Constants.SEPERATOR_UNDER_SCROLL + 
                                            APT_Constants.UPLOAD_RENEWAL_CONTRACT_RATES + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            productGroup + APT_Constants.SEPERATOR_UNDER_SCROLL +
                                            totalContractValue + APT_Constants.SEPERATOR_UNDER_SCROLL + getLocalTime(local);
            } 
            else { }                              
        }
        
        if(!String.isEmpty(SAPFilesnames.ContractFilename)) {
            Pattern nonWordChar = Pattern.compile(APT_Constants.SPECIAL_CHAR_PATTERN);
            SAPFilesnames.ContractFilename = nonWordChar.matcher(SAPFilesnames.ContractFilename).replaceAll(APT_Constants.EMPTY_STRING);
            if(SAPFilesnames.ContractFilename.length() > 140) {
                SAPFilesnames.ContractFilename = SAPFilesnames.ContractFilename.subString(0, 140);
            }
            SAPFilesnames.ContractFilename += APT_Constants.FILE_EXT_CSV;
        }
        
        if(!String.isEmpty(SAPFilesnames.RatecardsFilename)) {
            Pattern nonWordChar = Pattern.compile(APT_Constants.SPECIAL_CHAR_PATTERN);
            SAPFilesnames.RatecardsFilename = nonWordChar.matcher(SAPFilesnames.RatecardsFilename).replaceAll(APT_Constants.EMPTY_STRING);
            if(SAPFilesnames.RatecardsFilename.length() > 140) {
                SAPFilesnames.RatecardsFilename = SAPFilesnames.RatecardsFilename.subString(0, 140);
            }
            SAPFilesnames.RatecardsFilename += APT_Constants.FILE_EXT_CSV;
        }
        
        if(!String.isEmpty(SAPFilesnames.DetailedRatesFilename)) {
            Pattern nonWordChar = Pattern.compile(APT_Constants.SPECIAL_CHAR_PATTERN);
            SAPFilesnames.DetailedRatesFilename = nonWordChar.matcher(SAPFilesnames.DetailedRatesFilename).replaceAll(APT_Constants.EMPTY_STRING);
            if(SAPFilesnames.DetailedRatesFilename.length() > 140) {
                SAPFilesnames.DetailedRatesFilename = SAPFilesnames.DetailedRatesFilename.subString(0, 140);
            }
            SAPFilesnames.DetailedRatesFilename += APT_Constants.FILE_EXT_CSV;
        }       
        
        return SAPFilesnames;
    }
    
    /**
        This method will populate Contract Details
     */
    public static APT_SAP_SyncContractAndRatesService.ContractDetailsType populateContractDetails(Apttus__APTS_Agreement__c agreement,
                                                                                            list<Apttus_Proposal__Proposal__c> listProposal,
                                                                                            APT_Operational_Schedule__c operationSchedule) {
        APT_SAP_SyncContractAndRatesService.ContractDetailsType ContractDetails = new APT_SAP_SyncContractAndRatesService.ContractDetailsType();
        
        if(agreement != null) {
            ContractDetails.Id = agreement.Name;
            //ContractDetails.Id = agreement.SAP_Contract_Number__c;
            ContractDetails.SAPERPContractNumber = agreement.SAP_Contract_Number__c;
            
            ContractDetails.OpportunityID = agreement.Apttus__Related_Opportunity__r.Name;
            //APOST-1372
            /*
            if(operationSchedule != null) {
                if(operationSchedule.APT_Parcel__c == true && operationSchedule.APT_International_Postal__c == true) {
                    //ContractDetails.Type_x = 'NEW_CUSTOMER';
                    ContractDetails.Type_x = APT_Constants.CONTRACT_DETAIL_NEW_CUSTOMER;
                } else if(operationSchedule.APT_Parcel__c == true && operationSchedule.APT_International_Postal__c == false) {
                    //ContractDetails.Type_x = 'NEW_CUSTOMER';
                    ContractDetails.Type_x = APT_Constants.CONTRACT_DETAIL_NEW_CUSTOMER;
                } else if(operationSchedule.APT_Parcel__c == false && operationSchedule.APT_International_Postal__c == true) {
                    //ContractDetails.Type_x = 'INTERNATIONAL_NEW_EPARCEL';
                    ContractDetails.Type_x = APT_Constants.CONTRACT_DETAIL_INTERNATIONAL_NEW_EPARCEL;
                }
            }
            */
            
            //1825
            if(String.isNotBlank(agreement.APT_Pricing_Category__c) && agreement.APT_Pricing_Category__c.equalsIgnoreCase(APT_Constants.OFFLINE_RATES)) {
                ContractDetails.Type_x = APT_Constants.OFFLINE;
            } else {
                ContractDetails.Type_x = agreement.Apttus__Agreement_Category__c;
            }
            //1825

            //APOST-1372
            
            ContractDetails.CommencementDate = agreement.Apttus__Contract_Start_Date__c;
            ContractDetails.ExpiryDate = agreement.Apttus__Contract_End_Date__c;
            
            //APOST-1372
            /*
            if(agreement.Apttus__Related_Opportunity__r.Type != null) {
                if(agreement.Apttus__Related_Opportunity__r.Type == APT_Constants.OPPORTUNITY_TYPE_NEW_CUSTOMER) {
                    ContractDetails.SalesActivity = APT_Constants.SALES_ACTIVITY_NEW;
                } else if(agreement.Apttus__Related_Opportunity__r.Type == APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER) {
                    ContractDetails.SalesActivity = APT_Constants.SALES_ACTIVITY_RENEWAL;
                }
            }
            */
            if(!String.isEmpty(agreement.APT_Contract_Type__c)) {
                if(!agreement.APT_Contract_Type__c.equalsIgnoreCase(APT_Constants.CONTRACT_TYPE_RENEWAL_CONTRACT)) {
                    ContractDetails.SalesActivity = APT_Constants.SALES_ACTIVITY_NEW;
                } else {
                    ContractDetails.SalesActivity = APT_Constants.SALES_ACTIVITY_RENEWAL;
                }
            }
            //APOST-1372
            
            ContractDetails.Quote = populateQuote(listProposal);             
        } 
        
        return ContractDetails;
    }
    
    /**
        This method will populate quote information
     */
    public static list<APT_SAP_SyncContractAndRatesService.QuoteType> populateQuote(list<Apttus_Proposal__Proposal__c> listProposal) {
        list<APT_SAP_SyncContractAndRatesService.QuoteType> listQuote = new list<APT_SAP_SyncContractAndRatesService.QuoteType>();
        
        if(listProposal != null) {
            for(Apttus_Proposal__Proposal__c proposal : listProposal) {
                APT_SAP_SyncContractAndRatesService.QuoteType Quote = new APT_SAP_SyncContractAndRatesService.QuoteType();
                Quote.QuoteNumber = proposal.Name;
                
                if(!String.isEmpty(proposal.Apttus_Proposal__Approval_Stage__c) && proposal.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_DRAFT)) {
                    Quote.QuoteType = APT_Constants.QUOTE_TYPE_DRAFT;
                } else if(!String.isEmpty(proposal.Apttus_Proposal__Approval_Stage__c) && proposal.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED)) {
                    Quote.QuoteType = APT_Constants.QUOTE_TYPE_FINAL;
                } 
                else { }        
                
                Quote.SourceSystem = APT_Constants.SOURCE_SYSTEM_APTTUS;
                
                listQuote.add(Quote);
            }
        }
        
        return listQuote;
    }
    
    /**
        This method will poulate customer information
     */
    public static APT_SAP_SyncContractAndRatesService.CustomerType populateCustomer(Contact c, Account acc,
                                                                                map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                                                String paymentMethod,
                                                                                decimal MinQuantityPerAnnum,
                                                                                decimal MinRevenuePerAnnum) {
        APT_SAP_SyncContractAndRatesService.CustomerType CustomerType = new APT_SAP_SyncContractAndRatesService.CustomerType();
        CustomerType.CustomerDetails = populateCustomerDetails(c, acc, MinQuantityPerAnnum, MinRevenuePerAnnum);
        CustomerType.OrganisationContact = populateOrganisationContact(acc, c);
        CustomerType.IndividualContact = populateIndividualContact(null, c, acc);
        APT_Agreement_Lodgement_Point__c alp;
        CustomerType.Account = populateAccount(acc, alp, mapSubAccount, paymentMethod);
        
        return CustomerType;
    }
    
    /**
        This method will populate customer details information
     */
    public static APT_SAP_SyncContractAndRatesService.CustomerDetailsType populateCustomerDetails(Contact c, Account acc, decimal MinQuantityPerAnnum, decimal MinRevenuePerAnnum) {
        APT_SAP_SyncContractAndRatesService.CustomerDetailsType CustomerDetails = new APT_SAP_SyncContractAndRatesService.CustomerDetailsType();
        if(c != null) {
            CustomerDetails.Id = c.Name;
            //CustomerDetails.Type_x = expected null
            //CustomerDetails.MinRevenuePerAnnum = expected null
        }
        
        CustomerDetails.MinQuantityPerAnnum = MinQuantityPerAnnum;
        CustomerDetails.MinRevenuePerAnnum = MinRevenuePerAnnum;
        
        if(acc != null && !String.isEmpty(acc.LEGACY_ID__c)){
            CustomerDetails.CustomerReferenceNumbers = populateCustomerReferenceNumbers(acc);
        }
                
        return CustomerDetails;
    }    
    
    /**
        This method will populate Customer Reference Number information
     */
    public static APT_SAP_SyncContractAndRatesService.CustomerReferenceNumbers_element populateCustomerReferenceNumbers(Account acc) {
        APT_SAP_SyncContractAndRatesService.CustomerReferenceNumbers_element CustomerReferenceNumbers = new APT_SAP_SyncContractAndRatesService.CustomerReferenceNumbers_element();
                
        list<String> listCustomerReferenceNumber = new list<String>();
        listCustomerReferenceNumber.add(acc.LEGACY_ID__c);
        CustomerReferenceNumbers.CustomerReferenceNumber = listCustomerReferenceNumber;
        
        return CustomerReferenceNumbers;
    }
    
    /**
        This method will populate Organisation contact information
     */
    public static APT_SAP_SyncContractAndRatesService.OrganisationContactType populateOrganisationContact(Account acc, Contact c) {
        APT_SAP_SyncContractAndRatesService.OrganisationContactType OrganisationContact = new APT_SAP_SyncContractAndRatesService.OrganisationContactType();
        OrganisationContact.Organisation = populateOrganisation(acc);
        OrganisationContact.ContactDetails = populateContactDetails(null, c);
        OrganisationContact.Address = populateAddress(acc);
        
        return OrganisationContact;
    }
    
    /**
        This method will populate organisation information
     */
    public static APT_SAP_SyncContractAndRatesService.OrganisationType populateOrganisation(Account acc) {
        APT_SAP_SyncContractAndRatesService.OrganisationType Organisation = new APT_SAP_SyncContractAndRatesService.OrganisationType();
        if(acc != null) {
            Organisation.OrganisationName = acc.Name;
            Organisation.LegalName = acc.Name;
        }
        
        return Organisation;
    }
    
    /**
        This method will populate contact details information
     */
    public static APT_SAP_SyncContractAndRatesService.ContactDetailsType populateContactDetails(User salesRep, Contact c) {
        APT_SAP_SyncContractAndRatesService.ContactDetailsType ContactDetails = new APT_SAP_SyncContractAndRatesService.ContactDetailsType();
        
        if(salesRep != null) {
            ContactDetails.PhoneNumber = salesRep.Phone;
            ContactDetails.MobileNumber = salesRep.MobilePhone;
            ContactDetails.FaxNumber = salesRep.Fax;
            ContactDetails.EmailAddress = salesRep.Email;
        } else if(c != null) {
            ContactDetails.PhoneNumber = c.Phone;
            ContactDetails.MobileNumber = c.MobilePhone;
            ContactDetails.FaxNumber = c.Fax;
            ContactDetails.EmailAddress = c.Email;
        } else {
            
        }
        
        return ContactDetails;
    } 
    
    /**
        This method will populate address information
     */
    public static APT_SAP_SyncContractAndRatesService.AddressType populateAddress(Account acc) {
        APT_SAP_SyncContractAndRatesService.AddressType Address = new APT_SAP_SyncContractAndRatesService.AddressType();
        if(acc != null) {
            Address.AddressLine = acc.BillingStreet;
            Address.Suburb = acc.BillingCity;
            Address.State = acc.BillingState;
            Address.PostCode = acc.BillingPostalCode;
            if(!String.isEmpty(acc.BillingCountry)) {
                Address.CountryCode = acc.BillingCountry.subString(0, 2);
            }
            
        }
        
        return Address;
    }
    
    /**
        This method will populate Individual Contact information
     */
    public static APT_SAP_SyncContractAndRatesService.IndividualContactType populateIndividualContact(User salesRep, Contact c, Account acc) {
        APT_SAP_SyncContractAndRatesService.IndividualContactType IndividualContact = new APT_SAP_SyncContractAndRatesService.IndividualContactType();
        IndividualContact.Name = populateName(salesRep, c);
        IndividualContact.ContactDetails = populateContactDetails(salesRep, c);
        IndividualContact.Address = populateAddress(acc);
        
        return IndividualContact;   
    }
    
    /**
        This method will populate name information
     */
    public static APT_SAP_SyncContractAndRatesService.NameType populateName(User salesRep, Contact c) {
        APT_SAP_SyncContractAndRatesService.NameType name1 = new APT_SAP_SyncContractAndRatesService.NameType();
        
        if(salesRep != null) {
            name1.Title = salesRep.Title;
            name1.FirstName = salesRep.FirstName;
            name1.LastName = salesRep.LastName;
            name1.MiddleNames = new list<String>{salesRep.MiddleName};
            name1.FullName = salesRep.Name;
        } else if(c != null) {
            name1.Title = c.Title;
            name1.FirstName = c.FirstName;
            name1.LastName = c.LastName;
            name1.MiddleNames = new list<String>{c.MiddleName};
            name1.FullName = c.Name;
        } else {
            
        }
        
        return name1;
    }
    
    /**
        This method will populate Account information
     */
    public static APT_SAP_SyncContractAndRatesService.AccountType populateAccount(Account acc, APT_Agreement_Lodgement_Point__c alp,
                                                                map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                                String paymentMethod) {
        APT_SAP_SyncContractAndRatesService.AccountType Account1 = new APT_SAP_SyncContractAndRatesService.AccountType();
        
        //1492
        
        if(alp != null && alp.APT_Billing_Account__c != null) {           
            Account1.Id = alp.APT_Billing_Account__r.LEGACY_ID__c;
            Account1.Name = alp.APT_Billing_Account__r.Name;
        }
        else if(alp != null && alp.APT_Charge_Account__c != null) {            
            Account1.Id = alp.APT_Charge_Account__r.Name;
            Account1.Name = alp.APT_Charge_Account__r.Name;
        }
        //1492
        
        //1606 and 1661
        else if(alp != null && alp.APT_Sub_Account__c != null) {            
            Account1.Id = alp.APT_Sub_Account__r.Name;
            Account1.Name = alp.APT_Sub_Account__r.Name;
        }
        else if(alp != null && alp.APT_Cash_Account__c != null) {            
            Account1.Id = alp.APT_Cash_Account__r.Name;
            Account1.Name = alp.APT_Cash_Account__r.Name;
        }
        //1606 and 1661
        
        else if(acc != null) {
            Account1.Id = acc.AccountNumber;
            Account1.Name = acc.Name;
        }
        
        if(!String.isEmpty(paymentMethod)) {
            if(paymentMethod.equalsIgnoreCase(APT_Constants.PAYMENT_METHOD_CASH_ACCOUNT)) {
                Account1.Type_x = APT_Constants.ACCOUNT_TYPE_CASH;
            } else {
                Account1.Type_x = APT_Constants.ACCOUNT_TYPE_CUST;
            }
        }        
        if(!String.isEmpty(Account1.Type_x) && Account1.Type_x.equalsIgnoreCase(APT_Constants.ACCOUNT_TYPE_CUST)) {
            Account1.SubAccount = populateSubAccount(acc, alp, mapSubAccount);
        }        
        
        return Account1;
    }   
    
    
    /**
        This method will populate subaccount information
     */
    public static list<APT_SAP_SyncContractAndRatesService.SubAccountType> populateSubAccount(Account acc, APT_Agreement_Lodgement_Point__c alp,
                                                                            map<String, list<APT_Sub_Account__c>> mapSubAccount) {
                
        list<APT_SAP_SyncContractAndRatesService.SubAccountType> listSubAccount = new list<APT_SAP_SyncContractAndRatesService.SubAccountType>();
        
        if(alp != null && alp.APT_Sub_Account__c != null) {
            list<APT_Sub_Account__c> listSA = mapSubAccount.get(alp.APT_Sub_Account__c);
            if(listSA != null) {
                for(APT_Sub_Account__c sa : listSA) {
                    APT_SAP_SyncContractAndRatesService.SubAccountType SubAccount = new APT_SAP_SyncContractAndRatesService.SubAccountType();
                    SubAccount.Id = sa.Name;
                    SubAccount.Name = sa.Name;
                    SubAccount.Type_x = APT_Constants.SUB_ACCOUNT_TYPE_CUST;
                    listSubAccount.add(SubAccount);
                }
            }
        }
        
        return listSubAccount;    
    }
    
    /**
        This method will populate sales rep information
     */
    public static APT_SAP_SyncContractAndRatesService.SalesRepresentativeType populateSalesRepresentative(User salesRep,
                                                                                                        Contact c,
                                                                                                        Account acc,
                                                                                                        map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                                                                        String paymentMethod) {
        
        APT_SAP_SyncContractAndRatesService.SalesRepresentativeType SalesRepresentative = new APT_SAP_SyncContractAndRatesService.SalesRepresentativeType();
        SalesRepresentative.SalesRepDetails = populateSalesRepDetails(salesRep);
        SalesRepresentative.OrganisationContact = populateOrganisationContact(acc, c);
        SalesRepresentative.IndividualContact = populateIndividualContact(salesRep, c, acc);
        APT_Agreement_Lodgement_Point__c alp;
        SalesRepresentative.Account = populateAccount(acc, alp, mapSubAccount, paymentMethod);
        
        return SalesRepresentative; 
    }
    
    /**
        This method will populate sales rep details information
     */
    public static APT_SAP_SyncContractAndRatesService.SalesRepDetailsType populateSalesRepDetails(User salesRep) {
        APT_SAP_SyncContractAndRatesService.SalesRepDetailsType SalesRepDetails = new APT_SAP_SyncContractAndRatesService.SalesRepDetailsType();
        if(salesRep != null){
            SalesRepDetails.id = salesRep.Name;
            SalesRepDetails.Type_x = APT_Constants.SALES_REP_TYPE_SELLER;
        }
        
        return SalesRepDetails;
    }
    
    /**
        This method will populate product details information
     */
    public static APT_SAP_SyncContractAndRatesService.ProductDetailsType populateProductDetails(String rateCardType, String productCode,
                                                   APT_Operational_Schedule__c operationSchedule) {
        APT_SAP_SyncContractAndRatesService.ProductDetailsType ProductDetails = new APT_SAP_SyncContractAndRatesService.ProductDetailsType();
        if(!String.isEmpty(rateCardType)) {
            ProductDetails.Type_x = rateCardType;
            //APOST-1372
            
            if(rateCardType.equalsIgnoreCase(APT_Constants.RATE_CARD_TYPE_DOMESTIC) && operationSchedule != null) {
                if(true == operationSchedule.APT_Parcel__c) {
                    ProductDetails.Name = APT_Constants.PRODUCT_GROUP_PARCEL;
                    ProductDetails.Id = APT_Constants.PRODUCT_GROUP_PARCEL;
                    //ProductDetails.Name = APT_Constants.PRODUCT_DETAILS_PCMS;
                    //ProductDetails.Id = APT_Constants.PRODUCT_DETAILS_PCMS;
                }
            } else if(rateCardType.equalsIgnoreCase(APT_Constants.RATE_CARD_TYPE_INTERNATIONAL) && operationSchedule != null) {
                if(true == operationSchedule.APT_International_Postal__c) {
                    ProductDetails.Name = APT_Constants.PRODUCT_DETAILS_INTERNATIONAL_POSTAL;   //APOST-1372
                    ProductDetails.Id = APT_Constants.PRODUCT_DETAILS_INTERNATIONAL_POSTAL;     //APOST-1372
                }
            }
            else { }
                   
            /*
            if(rateCardType == APT_Constants.RATE_CARD_TYPE_DOMESTIC) {
                ProductDetails.Name = 'Parcel';
                ProductDetails.Id = 'Parcel';
            } else if(rateCardType == APT_Constants.RATE_CARD_TYPE_INTERNATIONAL){ 
                ProductDetails.Name = 'International Postal';
                ProductDetails.Id = 'International Postal';
            }
            */
            //APOST-1372
        } 
        //1661
        else if(String.isNotBlank(productCode) && productCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES)) {
          ProductDetails.Name = APT_Constants.PRODUCT_DETAILS_UNADDRESSED_MAIL;
            ProductDetails.Id = APT_Constants.PRODUCT_DETAILS_UNADDRESSED_MAIL;
        } else if(String.isNotBlank(productCode) && productCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
          ProductDetails.Name = APT_Constants.PRODUCT_DETAILS_PRINT_POST;
            ProductDetails.Id = APT_Constants.PRODUCT_DETAILS_PRINT_POST;
        } 
        //1661
        else {}
        
        return ProductDetails;
    }
    
    /**
        This method will populate lodgement points information
     */
    public static APT_SAP_SyncContractAndRatesService.LodgementPoints_element populateLodgementPoints(String productType, 
                                                                                    APT_Operational_Schedule__c operationSchedule, 
                                                                                    map<String, Network__c> mapLodgementPoint,
                                                                                    Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                                                    Account acc,
                                                                                    map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                                                    String paymentMethod,
                                                                                    map<String, APT_Agreement_Lodgement_Point__c> mapAgreementLodgementPoint) {
        
        APT_SAP_SyncContractAndRatesService.LodgementPoints_element LodgementPoints = new APT_SAP_SyncContractAndRatesService.LodgementPoints_element();
        LodgementPoints.LodgementPoint = populateLodgementPoint(productType, operationSchedule, mapLodgementPoint, parentPLI, acc, mapSubAccount, paymentMethod, mapAgreementLodgementPoint);
        
        return LodgementPoints; 
    }
    
    /**
        This method will populate lodgement information
     */
    public static list<APT_SAP_SyncContractAndRatesService.LodgementPointType> populateLodgementPoint(String productType, 
                                                                                    APT_Operational_Schedule__c operationSchedule, 
                                                                                    map<String, Network__c> mapLodgementPoint,
                                                                                    Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                                                    Account acc, 
                                                                                    map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                                                    String paymentMethod,
                                                                                    map<String, APT_Agreement_Lodgement_Point__c> mapAgreementLodgementPoint) {
                
        list<APT_SAP_SyncContractAndRatesService.LodgementPointType> listLodgementPoint = new list<APT_SAP_SyncContractAndRatesService.LodgementPointType>();
        
        system.debug('*** productType ***'+productType);
        
        if(operationSchedule != null && !String.isEmpty(productType) && mapLodgementPoint != null) {
            if(productType.equalsIgnoreCase(APT_Constants.PRODUCT_GROUP_PARCEL)) {              
                if(String.isNotBlank(parentPLI.Apttus_Proposal__Product__r.ProductCode) && parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) && !String.isEmpty(operationSchedule.APT_Parcel_Lodgement_Point_Ids__c)) {
                    list<String> listLodgementPointNames = operationSchedule.APT_Parcel_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                    listLodgementPoint = populateLodgementPoint(listLodgementPointNames, listLodgementPoint, operationSchedule, productType, null, acc, mapAgreementLodgementPoint, mapSubAccount, mapLodgementPoint, paymentMethod);
                    
                    /**
                    if(listLodgementPointNames != null) {
                        for(String lp : listLodgementPointNames) {
                            APT_SAP_SyncContractAndRatesService.LodgementPointType LodgementPoint = new APT_SAP_SyncContractAndRatesService.LodgementPointType();
                            Network__c network = mapLodgementPoint.get(lp);
                            if(network != null) {
                                LodgementPoint.Id = network.Name;
                                LodgementPoint.Name = network.Name;
                                LodgementPoint.Description = network.Name;
                                //LodgementPoint.WorkCentreID = network.APT_DWS_ID__c;
                                LodgementPoint.WorkCentreID = network.Org_ID__c;
                                LodgementPoint.GACode = network.APT_GA_Code__c;
                                //LodgementPoint.EPOSCode = expected null
                            }
                            
                            if(!String.isEmpty(operationSchedule.APT_Parcel_Lodgement_Times__c)) {
                                LodgementPoint.LodgementTime = operationSchedule.APT_Parcel_Lodgement_Times__c.split(APT_Constants.SEPERATOR_COMMA);
                            }
            
                            LodgementPoint.Zone = populateZone(productType, parentPLI);
                            LodgementPoint.Address = populateAddress(acc);
                            LodgementPoint.CustomerOrganisation = populateOrganisation(acc);
                            
                            //1492
                            APT_Agreement_Lodgement_Point__c alp = mapAgreementLodgementPoint.get(network.Id);
                            LodgementPoint.Account = populateAccount(acc, alp, mapSubAccount, paymentMethod);
                            //1492
                            
                            listLodgementPoint.add(LodgementPoint);
                        }
                    }
                    **/
                }
                //1509
                else if(String.isNotBlank(parentPLI.Apttus_Proposal__Product__r.ProductCode) && parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) && !String.isEmpty(operationSchedule.APT_Express_Parcel_Lodgement_Point_Ids__c)) {
                    list<String> listLodgementPointNames = operationSchedule.APT_Express_Parcel_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                    listLodgementPoint = populateLodgementPoint(listLodgementPointNames, listLodgementPoint, operationSchedule, productType, null, acc, mapAgreementLodgementPoint, mapSubAccount, mapLodgementPoint, paymentMethod);
                    
                    /**
                    if(listLodgementPointNames != null) {
                        for(String lp : listLodgementPointNames) {
                            APT_SAP_SyncContractAndRatesService.LodgementPointType LodgementPoint = new APT_SAP_SyncContractAndRatesService.LodgementPointType();
                            Network__c network = mapLodgementPoint.get(lp);
                            if(network != null) {
                                LodgementPoint.Id = network.Name;
                                LodgementPoint.Name = network.Name;
                                LodgementPoint.Description = network.Name;
                                //LodgementPoint.WorkCentreID = network.APT_DWS_ID__c;
                                LodgementPoint.WorkCentreID = network.Org_ID__c;
                                LodgementPoint.GACode = network.APT_GA_Code__c;
                                //LodgementPoint.EPOSCode = expected null
                            }
                            
                            if(!String.isEmpty(operationSchedule.APT_Parcel_Lodgement_Times__c)) {
                                LodgementPoint.LodgementTime = operationSchedule.APT_Parcel_Lodgement_Times__c.split(APT_Constants.SEPERATOR_COMMA);
                            }
            
                            LodgementPoint.Zone = populateZone(productType, parentPLI);
                            LodgementPoint.Address = populateAddress(acc);
                            LodgementPoint.CustomerOrganisation = populateOrganisation(acc);
                            
                            //1492
                            APT_Agreement_Lodgement_Point__c alp = mapAgreementLodgementPoint.get(network.Id);
                            LodgementPoint.Account = populateAccount(acc, alp, mapSubAccount, paymentMethod);
                            //1492
                            
                            listLodgementPoint.add(LodgementPoint);
                        }
                    }
                    **/
                }
                //1509                
            } 
            else if(parentPLI != null && String.isNotBlank(parentPLI.Apttus_Proposal__Product__r.ProductCode) &&
                          (parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)||
                       parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) ||
                       parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL))) {  //1661
                APT_SAP_SyncContractAndRatesService.LodgementPointType LodgementPoint = new APT_SAP_SyncContractAndRatesService.LodgementPointType();
                
                list<String> listLodgementPointNames = new list<String>();
                //Digital | Lodgement Points
                if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c && String.isNotBlank(operationSchedule.APT_International_Lodgement_Point_Ids__c)) {
                  listLodgementPointNames  = operationSchedule.APT_International_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                }
                //Non-Digital | Lodgement Points
                else if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Letters__c && String.isNotBlank(operationSchedule.APT_Non_Digital_International_LP_Ids__c)) {
                  listLodgementPointNames  = operationSchedule.APT_Non_Digital_International_LP_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                } else {}
                //if(!String.isEmpty(operationSchedule.APT_International_Lodgement_Point_Ids__c)) 
                //listLodgementPointNames  = operationSchedule.APT_International_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                
                listLodgementPoint = populateLodgementPoint(listLodgementPointNames, listLodgementPoint, operationSchedule, productType, null, acc, mapAgreementLodgementPoint, mapSubAccount, mapLodgementPoint, paymentMethod);
                
                /**
                if(listLodgementPointNames.size() > 0) {
                    for(String lp : listLodgementPointNames) {
                        Network__c network = mapLodgementPoint.get(lp);
                        if(network != null) {
                            
                            LodgementPoint.Id = network.Name;
                            LodgementPoint.Name = network.Name;
                            LodgementPoint.Description = network.Name;
                            //LodgementPoint.WorkCentreID = network.APT_DWS_ID__c;
                            LodgementPoint.WorkCentreID = network.Org_ID__c;
                            LodgementPoint.GACode = network.APT_GA_Code__c;
                            //LodgementPoint.EPOSCode = expected null                               
                        }
                        
                        if(!String.isEmpty(operationSchedule.APT_International_Lodgement_Times__c)) {
                            LodgementPoint.LodgementTime = operationSchedule.APT_International_Lodgement_Times__c.split(APT_Constants.SEPERATOR_COMMA);
                        }
                        LodgementPoint.Zone = populateZone(productType, parentPLI);
                        LodgementPoint.Address = populateAddress(acc);
                        LodgementPoint.CustomerOrganisation = populateOrganisation(acc);
                        
                        //1492
                        APT_Agreement_Lodgement_Point__c alp = mapAgreementLodgementPoint.get(network.Id);
                        LodgementPoint.Account = populateAccount(acc, alp, mapSubAccount, paymentMethod);
                        //1492
                        
                        listLodgementPoint.add(LodgementPoint);
                    }
                }                
                **/
                
            } 
            //1661
            else if(String.isNotBlank(productType) && productType.equalsIgnoreCase(APT_Constants.PRODUCT_DETAILS_UNADDRESSED_MAIL) && operationSchedule != null && String.isNotBlank(operationSchedule.APT_UMS_Lodgement_Point_Ids__c)) {
              list<String> listLodgementPointNames = operationSchedule.APT_UMS_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
              listLodgementPoint = populateLodgementPoint(listLodgementPointNames, listLodgementPoint, operationSchedule, productType, null, acc, mapAgreementLodgementPoint, mapSubAccount, mapLodgementPoint, paymentMethod);
            } else if(String.isNotBlank(productType) && productType.equalsIgnoreCase(APT_Constants.PRODUCT_DETAILS_PRINT_POST) && operationSchedule != null && String.isNotBlank(operationSchedule.APT_Print_Post_Lodgement_Point_Ids__c)) { 
              list<String> listLodgementPointNames = operationSchedule.APT_Print_Post_Lodgement_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
              listLodgementPoint = populateLodgementPoint(listLodgementPointNames, listLodgementPoint, operationSchedule, productType, null, acc, mapAgreementLodgementPoint, mapSubAccount, mapLodgementPoint, paymentMethod);
            } 
            //1661
            else { }
        }
        
        return listLodgementPoint;
    }
    
    /**
      This method will populate Lodgement Zone
    */
    public static list<APT_SAP_SyncContractAndRatesService.LodgementPointType> populateLodgementPoint(list<String> listLodgementPointNames,
                                                    list<APT_SAP_SyncContractAndRatesService.LodgementPointType> listLodgementPoint,
                                                  APT_Operational_Schedule__c operationSchedule,
                                                  String productType,
                                                  Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                  Account acc,
                                                  map<String, APT_Agreement_Lodgement_Point__c> mapAgreementLodgementPoint,
                                                  map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                  map<String, Network__c> mapLodgementPoint,
                                                  String paymentMethod) {
            
        if(listLodgementPointNames != null) {
            for(String lp : listLodgementPointNames) {
                APT_SAP_SyncContractAndRatesService.LodgementPointType LodgementPoint = new APT_SAP_SyncContractAndRatesService.LodgementPointType();
                Network__c network = mapLodgementPoint.get(lp);
                if(network != null) {
                    LodgementPoint.Id = network.Name;
                    LodgementPoint.Name = network.Name;
                    LodgementPoint.Description = network.Name;
                    //LodgementPoint.WorkCentreID = network.APT_DWS_ID__c;
                    LodgementPoint.WorkCentreID = network.Org_ID__c;
                    LodgementPoint.GACode = network.APT_GA_Code__c;
                    //LodgementPoint.EPOSCode = expected null
                }
                
                if(!String.isEmpty(operationSchedule.APT_Parcel_Lodgement_Times__c)) {
                    LodgementPoint.LodgementTime = operationSchedule.APT_Parcel_Lodgement_Times__c.split(APT_Constants.SEPERATOR_COMMA);
                }

                LodgementPoint.Zone = populateZone(productType, parentPLI);
                LodgementPoint.Address = populateAddress(acc);
                LodgementPoint.CustomerOrganisation = populateOrganisation(acc);
                
                //1492
                APT_Agreement_Lodgement_Point__c alp = mapAgreementLodgementPoint.get(network.Id);
                LodgementPoint.Account = populateAccount(acc, alp, mapSubAccount, paymentMethod);
                //1492
                
                listLodgementPoint.add(LodgementPoint);
            }
        }
        
        return listLodgementPoint;
    }
    
    /**
        This method will populate zone information
     */
    public static APT_SAP_SyncContractAndRatesService.ZoneDetailsType populateZone(String productType, Apttus_Proposal__Proposal_Line_Item__c parentPLI) {
        APT_SAP_SyncContractAndRatesService.ZoneDetailsType Zone = new APT_SAP_SyncContractAndRatesService.ZoneDetailsType();
        
        if(parentPLI != null) {
          Zone.Id = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c;
          Zone.Name = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.Name;
        }
                
        Zone.Type_x = productType;
        Zone.Category = productType; 
        
        return Zone;
    }
    
    /**
        This method will populate collection points information
     */
    public static APT_SAP_SyncContractAndRatesService.CollectionPoints_element populateCollectionPoints(String productType, 
                                                                                                APT_Operational_Schedule__c os,
                                                                                                map<String, APT_Site_Inspection__c> mapCollectionPoint,
                                                                                                Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                                                                Account acc,
                                                                                                map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                                                                String paymentMethod,
                                                                                                map<String, APT_Agreement_Lodgement_Point__c> mapAgreementLodgementPoint) {
        
        APT_SAP_SyncContractAndRatesService.CollectionPoints_element CollectionPoints = new APT_SAP_SyncContractAndRatesService.CollectionPoints_element();
        CollectionPoints.CollectionPoint = populateCollectionPoint(productType, os, mapCollectionPoint, parentPLI, acc, mapSubAccount, paymentMethod, mapAgreementLodgementPoint);
        
        return CollectionPoints;
    }
    
    /**
        This method will populate collection point information
     */
    public static list<APT_SAP_SyncContractAndRatesService.CollectionPointType> populateCollectionPoint(String productType,
                                                                                                APT_Operational_Schedule__c os,
                                                                                                map<String, APT_Site_Inspection__c> mapCollectionPoint,
                                                                                                Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                                                                Account acc,
                                                                                                map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                                                                String paymentMethod,
                                                                                                map<String, APT_Agreement_Lodgement_Point__c> mapAgreementLodgementPoint) {
                
        //CollectionPoint.CollectionMethod > list = ?
        
        list<APT_SAP_SyncContractAndRatesService.CollectionPointType> listCollectionPoint = new list<APT_SAP_SyncContractAndRatesService.CollectionPointType>();
        
        if(os != null && !String.isEmpty(productType)) {
          //domestic
          //standard
            if(productType.equalsIgnoreCase(APT_Constants.PRODUCT_GROUP_PARCEL) && parentPLI != null && String.isNotBlank(parentPLI.Apttus_Proposal__Product__r.ProductCode) && parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)) {
                                
                if(!String.isEmpty(os.APT_Parcel_Collection_Point_Ids__c)) {
                    list<String> listCollectionPoints = os.APT_Parcel_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                    
                    listCollectionPoint = populateCollectionPoint(paymentMethod, productType, os.APT_Parcel_Collection_Times__c, listCollectionPoint, listCollectionPoints, parentPLI, acc, mapCollectionPoint, mapSubAccount, mapAgreementLodgementPoint);
                    
                }                
            } 
            //express
            else if(productType.equalsIgnoreCase(APT_Constants.PRODUCT_GROUP_PARCEL) && parentPLI != null && String.isNotBlank(parentPLI.Apttus_Proposal__Product__r.ProductCode) && parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)) {
                                
                if(!String.isEmpty(os.APT_Parcel_Express_Collection_Point_Ids__c)) {  //1826
                    list<String> listCollectionPoints = os.APT_Parcel_Express_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                    
                    listCollectionPoint = populateCollectionPoint(paymentMethod, productType, os.APT_Parcel_Express_Collection_Times__c, listCollectionPoint, listCollectionPoints, parentPLI, acc, mapCollectionPoint, mapSubAccount, mapAgreementLodgementPoint);
                    
                }                
            } 
            //international
            else if(productType.equalsIgnoreCase(APT_Constants.PRODUCT_DETAILS_INTERNATIONAL_POSTAL)) {              
                
                //1606
                //Digital | Collection Points                           
                if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c && !String.isEmpty(os.APT_International_Collection_Point_Ids__c)) {
                    list<String> listCollectionPoints = os.APT_International_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                    
                    listCollectionPoint = populateCollectionPoint(paymentMethod, productType, os.APT_International_Collection_Times__c, listCollectionPoint, listCollectionPoints, parentPLI, acc, mapCollectionPoint, mapSubAccount, mapAgreementLodgementPoint);
                    
                } 
                //Non-Digital | Collection Points
                else if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Letters__c && !String.isEmpty(os.APT_Non_Digital_Collection_Point_Ids__c)) {
                    list<String> listCollectionPoints = os.APT_Non_Digital_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                    
                    listCollectionPoint = populateCollectionPoint(paymentMethod, productType, os.APT_International_Collection_Times__c, listCollectionPoint, listCollectionPoints, parentPLI, acc, mapCollectionPoint, mapSubAccount, mapAgreementLodgementPoint);
                    
                } else  {}
                //1606
            } 
            //UMS
            else if(productType.equalsIgnoreCase(APT_Constants.PRODUCT_DETAILS_UNADDRESSED_MAIL)) {
                                                                          
                if(!String.isEmpty(os.APT_UMS_Collection_Point_Ids__c)) {
                    list<String> listCollectionPoints = os.APT_UMS_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                    
                    listCollectionPoint = populateCollectionPoint(paymentMethod, productType, os.APT_UMS_Collection_Times__c, listCollectionPoint, listCollectionPoints, parentPLI, acc, mapCollectionPoint, mapSubAccount, mapAgreementLodgementPoint);
                }
            }
            //print post
            else if(productType.equalsIgnoreCase(APT_Constants.PRODUCT_DETAILS_PRINT_POST)) {
                                                                          
                if(!String.isEmpty(os.APT_Print_Post_Collection_Point_Ids__c)) {
                    list<String> listCollectionPoints = os.APT_Print_Post_Collection_Point_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                    
                    listCollectionPoint = populateCollectionPoint(paymentMethod, productType, os.APT_Print_Post_Collection_Times__c, listCollectionPoint, listCollectionPoints, parentPLI, acc, mapCollectionPoint, mapSubAccount, mapAgreementLodgementPoint);
                }
            }
            else { }
        }
        
        return listCollectionPoint;    
    }
    
    /**
      This method will populate collection point
    */
    public static list<APT_SAP_SyncContractAndRatesService.CollectionPointType> populateCollectionPoint(String paymentMethod, string productType,
                                                      String collectionTimes,
                                                    list<APT_SAP_SyncContractAndRatesService.CollectionPointType> listCollectionPoint,
                                                      list<String> listCollectionPoints,
                                                      Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                      Account acc, 
                                                      map<String, APT_Site_Inspection__c> mapCollectionPoint,
                                                      map<String, list<APT_Sub_Account__c>> mapSubAccount,
                                                      map<String, APT_Agreement_Lodgement_Point__c> mapAgreementLodgementPoint) {
      
      APT_SAP_SyncContractAndRatesService.CollectionPointType CollectionPoint;
              
      if(listCollectionPoints != null) {
          for(String cp : listCollectionPoints) {
            if(String.isNotBlank(cp)) {
              CollectionPoint = new APT_SAP_SyncContractAndRatesService.CollectionPointType();
              
              if(!String.isEmpty(collectionTimes)) {
                  CollectionPoint.CollectionTime = collectionTimes.split(APT_Constants.SEPERATOR_COMMA);
              }
              
              APT_Site_Inspection__c siteInspection = mapCollectionPoint.get(cp);                            
                APT_Agreement_Lodgement_Point__c alp;   //1492
                if(siteInspection != null) {
                    CollectionPoint.Id = siteInspection.Name;
                    CollectionPoint.Name = siteInspection.Name;
                    CollectionPoint.Description = siteInspection.Name;
                    
                    alp = mapAgreementLodgementPoint.get(siteInspection.APT_Lodgement_Point__c);    //1492
                }
                
                CollectionPoint.Zone = populateZone(productType, parentPLI);
                                                                        
                CollectionPoint.Account = populateAccount(acc, alp, mapSubAccount, paymentMethod);  //1492
                
                CollectionPoint.CustomerOrganisation = populateOrganisation(acc);
                CollectionPoint.Address = populateAddress(acc);   
                
                //CollectionPoint.WorkCentreID = expected null
                //CollectionPoint.GACode = expected null
                //CollectionPoint.EPOSCode = expected null
                //CollectionPoint.BookingMode = expected null
                
                listCollectionPoint.add(CollectionPoint);  
            }                                     
          }
      }
      
      return listCollectionPoint;
    }
     
    /**
        This method will populate rate card
     */
    public static APT_SAP_SyncContractAndRatesService.RateCardType populateRateCard(String contractType,
                                                                                    APT_SAP_SyncContractAndRatesService.RateCardType rateCard,
                                                                                    Apttus_Proposal__Proposal_Line_Item__c pli,
                                                                                    Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                                                    list<Apttus_Proposal__Proposal_Line_Item__c> listOptionPLI,
                                                                                    APT_R2T_System_Properties__c r2tSystemProperties,
                                                                                    APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties,
                                                                                    datetime local) {
        
        rateCard.QuoteNumber = pli.Apttus_Proposal__Proposal__r.Name;
        
        //APOST-1372
        /*
        if(contractType != null && contractType == APT_Constants.CONTRACT_TYPE_NEW_CONTRACT) {
            rateCard.Recontracting = APT_Constants.CONTRACT_DETAIL_INTERNATIONAL_NEW_EPARCEL;
        } else if(contractType != null && contractType == APT_Constants.CONTRACT_TYPE_RENEWAL_CONTRACT) {
            rateCard.Recontracting = APT_Constants.CONTRACT_DETAIL_INTERNATIONAL_RENEWAL_EPARCEL;
        }
        */
        if(!String.isEmpty(contractType)) {
            if(contractType.equalsIgnoreCase(APT_Constants.CONTRACT_TYPE_NEW_CONTRACT)) {
                rateCard.Recontracting = APT_Constants.OPPORTUNITY_TYPE_NEW_BUSINESS;
            } else {
                rateCard.Recontracting = APT_Constants.RECONTRACTING;
            }
        }
        //APOST-1372
        
                        
        //rateCard.Type_x
        if(parentPLI != null && !String.isEmpty(parentPLI.Apttus_Proposal__Product__c) && !String.isEmpty(parentPLI.Apttus_Proposal__Product__r.ProductCode) && (parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) {
            rateCard.Type_x = APT_Constants.RATE_CARD_TYPE_DOMESTIC;
            if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)) {
                rateCard.ServiceType = APT_Constants.SERVICE_TYPE_PARCEL_POST;
                rateCard.ServiceTypeFlag = APT_Constants.SERVICE_TYPE_S;
            } else if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)) {
                rateCard.ServiceType = APT_Constants.SERVICE_TYPE_EXPRESS_POST;
                rateCard.ServiceTypeFlag = APT_Constants.SERVICE_TYPE_X;
            } else { }
            
            //for domestic only
            if(!String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Signature_On_Delivery__c) && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Signature_On_Delivery__c.equalsIgnoreCase(APT_Constants.OPTION_YES)) {
                rateCard.SignatureFlag = APT_Constants.SIGNATURE_Y;
            } else {
                rateCard.SignatureFlag = APT_Constants.SIGNATURE_N;
            }
            
            if(!String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Consignment_Pricing__c) && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Consignment_Pricing__c.equalsIgnoreCase(APT_Constants.OPTION_YES)) {
                rateCard.ConsignmentPricingFlag = APT_Constants.SIGNATURE_Y;
            } else {
                rateCard.ConsignmentPricingFlag = APT_Constants.SIGNATURE_N;
            } 
            
            rateCard.ScenarioType = APT_Constants.CONTRACT_DETAIL_NEW_CUSTOMER;
            
            rateCard.FlatRatesDetails = populateFlatRatesDetailsType(parentPLI);
            
            rateCard.CubicFactor = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c;     
            //rateCard.MinQuantity = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Minimum_Quantity__c;
            //rateCard.MinQuantity = parentPLI.Apttus_QPConfig__Quantity2__c;
            
            //1830
            if(String.isNotBlank(pli.APT_Rate_Card_Key__c)) {
                rateCard.RateCardKey = pli.APT_Rate_Card_Key__c;  
            } else {
                rateCard.RateCardKey = pli.Name;    
            }
            //1830
                        
            rateCard.ProvisioningMethod = APT_Constants.PROVISIONING_METHOD_PCMS;  
                    
        } else if(parentPLI != null && !String.isEmpty(parentPLI.Apttus_Proposal__Product__c) && !String.isEmpty(parentPLI.Apttus_Proposal__Product__r.ProductCode) && 
                     (parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)||
                       parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) ||
                       parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL))) {
            rateCard.Type_x = APT_Constants.RATE_CARD_TYPE_INTERNATIONAL;
            //rateCard.ScenarioType = APT_Constants.CONTRACT_DETAIL_INTERNATIONAL_NEW_EPARCEL;
            
            if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)){
            
            
            if(true == parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Letters__c && false == parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c) {
                rateCard.ProvisioningMethod = APT_Constants.PROVISIONING_METHOD_CSP;
                rateCard.ScenarioType = APT_Constants.SCENARIO_TYPE_CSP;
            } else {
                rateCard.ProvisioningMethod = APT_Constants.PROVISIONING_METHOD_PCMS;
                rateCard.ScenarioType = APT_Constants.SCENARIO_TYPE_PCMS;
            }
            }else if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) ||
                  parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL )){
                rateCard.ProvisioningMethod = APT_Constants.PROVISIONING_METHOD_PCMS;
                rateCard.ScenarioType = APT_Constants.NEW_INT_BUNDLE;
            }
            rateCard.BandRateDetails = populateBandRateDetails(parentPLI);
            //PCMS
            if(true == parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c) {
                rateCard.UKRatesDetails = populateUKRatesDetails(r2tSystemProperties);
                rateCard.NewZealandRatesDetails = populateNewZealandRatesDetails(r2tSystemProperties);
            }            
                        
            //1830
            if(String.isNotBlank(parentPLI.APT_Rate_Card_Key__c)) {
                rateCard.RateCardKey = parentPLI.APT_Rate_Card_Key__c;  
            } else {
                rateCard.RateCardKey = parentPLI.Name;      
            }
            //1830
            
            rateCard.CustomerPricingDetails = populateCustomerPricingDetails(/*rateCard.Type_x,*/ parentPLI, r2tSystemProperties);
            
            
            rateCard.VolumeAverageWeightDetails = populateVolumeAverageWeight(pli, parentPLI, r2tInternationalPricingProperties);
            
            rateCard.ZoneDispersionDetails = populateZoneDispersion(parentPLI, r2tSystemProperties);
            
        } else { }
        
        if(parentPLI != null) {
            rateCard.BaseUpliftPercentage = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Base_Uplift_Percentage__c;
            rateCard.CalculatedUpliftPercentage = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Calculated_Uplift_Percentage__c;
        
            rateCard.FeaturesDetails = populateFeaturesDetails(rateCard.Type_x, parentPLI, listOptionPLI, r2tSystemProperties);
            rateCard.StandardCharges = populateStandardCharges(rateCard.Type_x, listOptionPLI, r2tSystemProperties, parentPLI);
            rateCard.CurrentPricingDetails = populateCurrentPricingDetails(pli, parentPLI);
            rateCard.NewPricingDetails = populateNewPricingDetails(pli, parentPLI, r2tSystemProperties, r2tInternationalPricingProperties);
        }
        
                
        //rateCard.BarcodedParcelFlag = Expected Null        
        //PrecedingRateCardKey = Expected Null
        
        //rateCard.RateCardKey = parentPLI.APT_Rate_Card_Key__c;
        
        
        //APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
        
        //current date time
        /*
        dateTime gmt = system.now();
        Datetime local = gmt.Date();
        local = local.addHours(gmt.hour());
        local = local.addMinutes(gmt.minute());
        local = local.addSeconds(gmt.second());
        */
        
        rateCard.CreationDetails = populateCreationDetails(pli, local);
        rateCard.StatusDetails = populateStatusDetails(pli, local);
        rateCard.ExtractDetails = populateExtractDetails(/*rateCard.Type_x,*/ pli, local);
        rateCard.DeliveryChoicesFeeDetails = populateDeliveryChoicesFeeDetails(r2tSystemProperties);
        rateCard.Comments = populateComments();
        
        return rateCard;
    }
    
    /**
        This method will populate creation details 
     */
    public static APT_SAP_SyncContractAndRatesService.CreationType populateCreationDetails(Apttus_Proposal__Proposal_Line_Item__c pli, dateTime local) {
        APT_SAP_SyncContractAndRatesService.CreationType CreationDetails = new APT_SAP_SyncContractAndRatesService.CreationType();
        //CreationDetails.Timestamp = dateTime.now();
        /*
        dateTime gmt = system.now();
        Datetime local = gmt.Date();
        local = local.addHours(gmt.hour());
        local = local.addMinutes(gmt.minute());
        local = local.addSeconds(gmt.second());
        */
        CreationDetails.Timestamp = local;
        //CreationDetails.Timestamp = datetime.valueOf(getLocalTime());
        //CreationDetails.DayId = Date.Today().Day();
        //CreationDetails.MonthId = Date.Today().Month();
        
        String strYear = String.valueOf(system.now().Year());
        String strMonth = String.valueOf(system.now().Month());
        String strDay = String.valueOf(system.now().Day());
        
        if(strMonth.length() == 1) {
            strMonth = APT_Constants.ADD_ZERO + strMonth;
        }
        
        if(strDay.length() == 1) {
            strDay = APT_Constants.ADD_ZERO + strDay;
        }
        
        CreationDetails.DayId = decimal.valueOf(strYear + strMonth + strDay);
        CreationDetails.MonthId = decimal.valueOf(strYear + strMonth);
                
        CreationDetails.UserId = pli.CreatedBy.Name;
        CreationDetails.UploadType = APT_Constants.UPLOAD_TYPE_USER;
        CreationDetails.ToolName = APT_Constants.UPLOAD_TYPE_TOOL_NAME;
        CreationDetails.UserLevel = APT_Constants.ONE;
        
        //CreationDetails.BulkRatecardOutputFlag = expected null;
        return CreationDetails;
    }
    
    /**
        This method will populate status details
     */
    public static APT_SAP_SyncContractAndRatesService.StatusDetails populateStatusDetails(Apttus_Proposal__Proposal_Line_Item__c pli, dateTime local) {
        APT_SAP_SyncContractAndRatesService.StatusDetails StatusDetails = new APT_SAP_SyncContractAndRatesService.StatusDetails();
        
        if(!String.isEmpty(pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c)) {
            if(pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.QUOTE_TYPE_DRAFT)) {
                StatusDetails.Type_x = APT_Constants.APPROVAL_STAGE_DRAFT;
            } else if(pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED)) {
                StatusDetails.Type_x = APT_Constants.STATUS_DETAILS_TYPE_FINAL;
            } else { }         
        }
        
        StatusDetails.Flag = APT_Constants.FLAG;        
        //StatusDetails.Timestamp = dateTime.now();
        StatusDetails.Timestamp = local;
        StatusDetails.UserId = pli.CreatedBy.Name;
        
        return StatusDetails;
    }
    
    /**
        This method will populat extract details
     */
    public static APT_SAP_SyncContractAndRatesService.ExtractDetails populateExtractDetails(/*String rateCardType,*/ Apttus_Proposal__Proposal_Line_Item__c pli, datetime local) {
        APT_SAP_SyncContractAndRatesService.ExtractDetails ExtractDetails = new APT_SAP_SyncContractAndRatesService.ExtractDetails();

        //if(rateCardType != null && rateCardType == APT_Constants.RATE_CARD_TYPE_DOMESTIC) {
            ExtractDetails.Flag = APT_Constants.FLAG;
        //}
        
        //ExtractDetails.Timestamp = dateTime.now();
        ExtractDetails.Timestamp = local;
        ExtractDetails.UserId = pli.CreatedBy.Name;
        ExtractDetails.ApprovalDetails = populateApprovalDetails(/*rateCardType,*/ pli, local);
        
        return ExtractDetails;
    }
    
    /**
        This method will populate approval details
     */
    public static APT_SAP_SyncContractAndRatesService.ApprovalDetails populateApprovalDetails(/*String rateCardType,*/ Apttus_Proposal__Proposal_Line_Item__c pli, datetime local) {
        APT_SAP_SyncContractAndRatesService.ApprovalDetails ApprovalDetails = new APT_SAP_SyncContractAndRatesService.ApprovalDetails();

        //if(rateCardType != null && rateCardType == APT_Constants.RATE_CARD_TYPE_DOMESTIC) {
            ApprovalDetails.Flag = APT_Constants.FLAG;
        //}
        
        //ApprovalDetails.Timestamp = dateTime.now();
        ApprovalDetails.Timestamp = local;
        ApprovalDetails.UserId = pli.CreatedBy.Name;
        
        return ApprovalDetails;
    }
    
    /**
        This method will populate volume and avg weight information
     */
    public static APT_SAP_SyncContractAndRatesService.VolumeAverageWeightDetails_element populateVolumeAverageWeight(Apttus_Proposal__Proposal_Line_Item__c pli,
                                                                    Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                                    APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties) {
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightDetails_element VolumeAverageWeightDetails = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightDetails_element();
        
        list<APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType> listVolumeAverageWeight = new list<APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType>();
        if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)){
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight1 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight1.InternationalService = r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c;   //APOST-1372
            VolumeAverageWeight1.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_ECI_Documents_Annual_Volume__c;       
            VolumeAverageWeight1.AvgUnitWeightGrams = (parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_ECI_Documents_AVG_Weight_KG__c * 1000);
        }
        
        listVolumeAverageWeight.add(VolumeAverageWeight1);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight2 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        //VolumeAverageWeight2.InternationalService = pli.Apttus_QPConfig__ChargeType__c;
        if(parentPLI != null) {
            //if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_ECI_Merchandise_AVG_Weight_KG__c <= 2) {
            //    VolumeAverageWeight2.InternationalService = r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c;  //APOST-1372
            //} else {
                VolumeAverageWeight2.InternationalService = r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c;  //APOST-1372
            //}
            
            VolumeAverageWeight2.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.ECI_Merchandise_Annual_Volume__c;       
            VolumeAverageWeight2.AvgUnitWeightGrams = (parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_ECI_Merchandise_AVG_Weight_KG__c * 1000);
        }
        
        listVolumeAverageWeight.add(VolumeAverageWeight2);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight3 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        //VolumeAverageWeight3.InternationalService = pli.Apttus_QPConfig__ChargeType__c;
        if(parentPLI != null) {
            VolumeAverageWeight3.InternationalService = r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c;  //APOST-1372
            VolumeAverageWeight3.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelsGT2kgAnnualVolume__c;       
            VolumeAverageWeight3.AvgUnitWeightGrams = (parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelGT2kgAVGWeightKG__c * 1000);
        }
        
        listVolumeAverageWeight.add(VolumeAverageWeight3);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight4 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        //VolumeAverageWeight4.InternationalService = pli.Apttus_QPConfig__ChargeType__c;
        if(parentPLI != null) {
            VolumeAverageWeight4.InternationalService = r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c;  //APOST-1372
            VolumeAverageWeight4.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelsLT2kgAnnualVolume__c;       
            VolumeAverageWeight4.AvgUnitWeightGrams = (parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelLT2kgAVGWeightKG__c * 1000);
        }
        
        listVolumeAverageWeight.add(VolumeAverageWeight4);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight5 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        //VolumeAverageWeight5.InternationalService = pli.Apttus_QPConfig__ChargeType__c;
        if(parentPLI != null) {
            VolumeAverageWeight5.InternationalService = r2tInternationalPricingProperties.APT_AIRLET_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight5.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Airmail_Letters_Annual_Volume__c;       
            VolumeAverageWeight5.AvgUnitWeightGrams = (parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Airmail_Letters_AVG_Weight_KG__c * 1000);
        }
        
        listVolumeAverageWeight.add(VolumeAverageWeight5);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight6 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        //VolumeAverageWeight6.InternationalService = pli.Apttus_QPConfig__ChargeType__c;
        if(parentPLI != null) {
            VolumeAverageWeight6.InternationalService = r2tInternationalPricingProperties.APT_AIRRPI_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight6.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_RegisteredPostInternationalAnnualVol__c;       
            VolumeAverageWeight6.AvgUnitWeightGrams = (parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_RegisteredPostInternationalAVGWeight__c * 1000);
        }
        
        listVolumeAverageWeight.add(VolumeAverageWeight6);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight7 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        VolumeAverageWeight7.InternationalService = pli.Apttus_QPConfig__ChargeType__c;
        if(parentPLI != null) {
            VolumeAverageWeight7.InternationalService = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight7.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_PackNTrackInternationalAnnualVolume__c;       
            VolumeAverageWeight7.AvgUnitWeightGrams = (parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_PackNTrackInternationalAVGWeightKG__c * 1000);
        }
        
        listVolumeAverageWeight.add(VolumeAverageWeight7);
        }
        else if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) ||
                       parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL )){
             
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight8 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight8.InternationalService = r2tInternationalPricingProperties.APT_EXPRESSDOCT_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight8.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Int_Express_Document_Volume__c;     
            VolumeAverageWeight8.AvgUnitWeightGrams = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Int_Express_Doc_Weight_Kg__c; 
        }
        listVolumeAverageWeight.add(VolumeAverageWeight8);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight9 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight9.InternationalService = r2tInternationalPricingProperties.APT_EXPRESS_MERCH_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight9.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Express_Merchandise__c;       
            VolumeAverageWeight9.AvgUnitWeightGrams = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Exp_Merch_Weight_Kgs__c; 
        }
        listVolumeAverageWeight.add(VolumeAverageWeight9);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight10 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight10.InternationalService = r2tInternationalPricingProperties.APT_STANDARD_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight10.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Standard_Volume__c;       
            VolumeAverageWeight10.AvgUnitWeightGrams = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Standard_Weight_Kgs__c; 
        }
        listVolumeAverageWeight.add(VolumeAverageWeight10);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight11 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight11.InternationalService = r2tInternationalPricingProperties.APT_ECONOMY_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight11.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Economy_Volume__c;       
            VolumeAverageWeight11.AvgUnitWeightGrams = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Economy_Weight_Kgs__c; 
        }
        listVolumeAverageWeight.add(VolumeAverageWeight11);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight12 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight12.InternationalService = r2tInternationalPricingProperties.APT_RETURNS_EXPRESS_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight12.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Returns_Express_Volume__c;       
            VolumeAverageWeight12.AvgUnitWeightGrams = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Returns_Exp_Weight_Kgs__c; 
        }
        listVolumeAverageWeight.add(VolumeAverageWeight12);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight13 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight13.InternationalService = r2tInternationalPricingProperties.APT_RETURNS_STANDARD_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight13.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Returns_Std_Ut_Volume__c;       
            VolumeAverageWeight13.AvgUnitWeightGrams = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Ret_Std_Ut_Weight_Kgs__c; 
        }
        listVolumeAverageWeight.add(VolumeAverageWeight13);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight14 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight14.InternationalService = r2tInternationalPricingProperties.APT_STANDARD_WITH_SIGN_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight14.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Standard_W_Sig_Volume__c;       
            VolumeAverageWeight14.AvgUnitWeightGrams = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Std_W_Sig_Weight_Kgs__c; 
        }
        listVolumeAverageWeight.add(VolumeAverageWeight14);
        
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight15 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight15.InternationalService = r2tInternationalPricingProperties.APT_ECONOMY_WITH_SIGN_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight15.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Economy_W_Sig_Volume__c;       
            VolumeAverageWeight15.AvgUnitWeightGrams = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Eco_W_Sig_Weight_Kgs__c; 
        }
        listVolumeAverageWeight.add(VolumeAverageWeight15);
        
        }
        
        if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL )){
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight16 = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        if(parentPLI != null) {
            VolumeAverageWeight16.InternationalService = r2tInternationalPricingProperties.APT_AIRMAIL_LETTERS_Charge_Type__c;    //APOST-1372
            VolumeAverageWeight16.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Airmail_Letters_Volume__c;       
            VolumeAverageWeight16.AvgUnitWeightGrams = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Airmail_Let_Weight_Kgs__c; 
        }
        listVolumeAverageWeight.add(VolumeAverageWeight16);
        }
        
        VolumeAverageWeightDetails.VolumeAverageWeight = listVolumeAverageWeight;
        return VolumeAverageWeightDetails;
        
        /*
        APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType VolumeAverageWeight = new APT_SAP_SyncContractAndRatesService.VolumeAverageWeightType();
        //VolumeAverageWeight.InternationalService
        //VolumeAverageWeight.AvgUnitWeightGrams
        //VolumeAverageWeight.AnnualVolume
        if(pli.Apttus_QPConfig__OptionId__r.ProductCode == APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT) {
            //EMSDOCT
            if(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c != null && r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c == pli.Apttus_QPConfig__ChargeType__c) {
                VolumeAverageWeight.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_ECI_Documents_Annual_Volume__c;
            } else {
                //EMSMERCH and EMSMER20
                VolumeAverageWeight.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.ECI_Merchandise_Annual_Volume__c;
            } 
        } else if(pli.Apttus_QPConfig__OptionId__r.ProductCode == APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT) {
            //AIRPCL
            if(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c != null && r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c == pli.Apttus_QPConfig__ChargeType__c) {
                VolumeAverageWeight.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelsGT2kgAnnualVolume__c;
            }
            
            //AIRSMPCL
            if(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c != null && r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c == pli.Apttus_QPConfig__ChargeType__c) {
                VolumeAverageWeight.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_AirmailSmallParcelsLT2kgAnnualVolume__c;
            }
        } else if(pli.Apttus_QPConfig__OptionId__r.ProductCode != null && pli.Apttus_QPConfig__OptionId__r.ProductCode == APT_Constants.AIRLET_INTERNATIONAL_PRODUCT) {
            VolumeAverageWeight.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Airmail_Letters_Annual_Volume__c;
        } else if(pli.Apttus_QPConfig__OptionId__r.ProductCode != null && pli.Apttus_QPConfig__OptionId__r.ProductCode == APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT) {
            VolumeAverageWeight.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_RegisteredPostInternationalAnnualVol__c;
        } else if(pli.Apttus_QPConfig__OptionId__r.ProductCode != null && pli.Apttus_QPConfig__OptionId__r.ProductCode == APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT) {
            VolumeAverageWeight.AnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_PackNTrackInternationalAnnualVolume__c;
        }
        
        return VolumeAverageWeight;
        */
    }    
    
    /**
        This method will populate zone dispersion information
     */
    public static APT_SAP_SyncContractAndRatesService.ZoneDispersionDetails_element populateZoneDispersion(Apttus_Proposal__Proposal_Line_Item__c parentPLI,
                                                                                                        APT_R2T_System_Properties__c r2tSystemProperties) {
        APT_SAP_SyncContractAndRatesService.ZoneDispersionDetails_element ZoneDispersionDetails = new APT_SAP_SyncContractAndRatesService.ZoneDispersionDetails_element();
       
        list<APT_SAP_SyncContractAndRatesService.ZoneDispersionType> listZoneDispersion = new list<APT_SAP_SyncContractAndRatesService.ZoneDispersionType>();
        
        if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) ||
                       parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL )){
                       
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion11 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion11.Zone = APT_Constants.ZONE1;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_1Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_1Digital_Dispersion__c != r2tSystemProperties.APT_Zone_1Digital_Dispersion__c) {
            ZoneDispersion11.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_1Digital_Dispersion__c;
        } else {       
            ZoneDispersion11.DefaultDispersion = r2tSystemProperties.APT_Zone_1Digital_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion11);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion12 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion12.Zone = APT_Constants.ZONE2;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_2Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_2Digital_Dispersion__c != r2tSystemProperties.APT_Zone_2Digital_Dispersion__c) {
            ZoneDispersion12.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_2Digital_Dispersion__c;
        } else {       
            ZoneDispersion12.DefaultDispersion = r2tSystemProperties.APT_Zone_2Digital_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion12);              
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion13 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion13.Zone = APT_Constants.ZONE3;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_3Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_3Digital_Dispersion__c != r2tSystemProperties.APT_Zone_3Digital_Dispersion__c) {
            ZoneDispersion13.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_3Digital_Dispersion__c;
        } else {       
            ZoneDispersion13.DefaultDispersion = r2tSystemProperties.APT_Zone_3Digital_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion13);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion14 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion14.Zone = APT_Constants.ZONE4;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_4Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_4Digital_Dispersion__c != r2tSystemProperties.APT_Zone_4Digital_Dispersion__c) {
            ZoneDispersion14.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_4Digital_Dispersion__c;
        } else {       
            ZoneDispersion14.DefaultDispersion = r2tSystemProperties.APT_Zone_4Digital_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion14);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion15 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion15.Zone = APT_Constants.ZONE5;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_5Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_5Digital_Dispersion__c != r2tSystemProperties.APT_Zone_5Digital_Dispersion__c) {
            ZoneDispersion15.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_5Digital_Dispersion__c;
        } else {       
            ZoneDispersion15.DefaultDispersion = r2tSystemProperties.APT_Zone_5Digital_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion15);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion16 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion16.Zone = APT_Constants.ZONE6;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_6Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_6Digital_Dispersion__c != r2tSystemProperties.APT_Zone_6Digital_Dispersion__c) {
            ZoneDispersion16.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_6Digital_Dispersion__c;
        } else {       
            ZoneDispersion16.DefaultDispersion = r2tSystemProperties.APT_Zone_6Digital_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion16);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion17 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion17.Zone = APT_Constants.ZONE7;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_7Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_7Digital_Dispersion__c != r2tSystemProperties.APT_Zone_7Digital_Dispersion__c) {
            ZoneDispersion17.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_7Digital_Dispersion__c;
        } else {       
            ZoneDispersion17.DefaultDispersion = r2tSystemProperties.APT_Zone_7Digital_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion17);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion18 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion18.Zone = APT_Constants.ZONE8;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_8Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_8Digital_Dispersion__c != r2tSystemProperties.APT_Zone_8Digital_Dispersion__c) {
            ZoneDispersion18.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_8Digital_Dispersion__c;
        } else {       
            ZoneDispersion18.DefaultDispersion = r2tSystemProperties.APT_Zone_8Digital_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion18);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion19 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion19.Zone = APT_Constants.ZONE9;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_9Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_9Digital_Dispersion__c != r2tSystemProperties.APT_Zone_9Digital_Dispersion__c) {
            ZoneDispersion19.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_9Digital_Dispersion__c;
        } else {       
            ZoneDispersion19.DefaultDispersion = r2tSystemProperties.APT_Zone_9Digital_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion19);
        
        } 
        
        if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE) || 
        parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL )){
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion1 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion1.Zone = APT_Constants.ZONE1;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_1_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_1_Dispersion__c != r2tSystemProperties.APT_Zone_1_Dispersion__c) {
            ZoneDispersion1.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_1_Dispersion__c;
        } else {       
            ZoneDispersion1.DefaultDispersion = r2tSystemProperties.APT_Zone_1_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion1);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion2 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion2.Zone = APT_Constants.ZONE2;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_2_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_2_Dispersion__c != r2tSystemProperties.APT_Zone_2_Dispersion__c) {
            ZoneDispersion2.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_2_Dispersion__c;
        } else {
            ZoneDispersion2.DefaultDispersion = r2tSystemProperties.APT_Zone_2_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion2);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion3 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion3.Zone = APT_Constants.ZONE3;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_3_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_3_Dispersion__c != r2tSystemProperties.APT_Zone_3_Dispersion__c) {
            ZoneDispersion3.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_3_Dispersion__c;
        } else {
            ZoneDispersion3.DefaultDispersion = r2tSystemProperties.APT_Zone_3_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion3);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion4 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion4.Zone = APT_Constants.ZONE4;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_4_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_4_Dispersion__c != r2tSystemProperties.APT_Zone_4_Dispersion__c) {
            ZoneDispersion4.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_4_Dispersion__c;
        } else {
            ZoneDispersion4.DefaultDispersion = r2tSystemProperties.APT_Zone_4_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion4);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion5 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion5.Zone = APT_Constants.ZONE5;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_5_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_5_Dispersion__c != r2tSystemProperties.APT_Zone_5_Dispersion__c) {
            ZoneDispersion5.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_5_Dispersion__c;
        } else {
            ZoneDispersion5.DefaultDispersion = r2tSystemProperties.APT_Zone_5_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion5);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion6 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion6.Zone = APT_Constants.ZONE6;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_6_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_6_Dispersion__c != r2tSystemProperties.APT_Zone_6_Dispersion__c) {
            ZoneDispersion6.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_6_Dispersion__c;
        } else{
            ZoneDispersion6.DefaultDispersion = r2tSystemProperties.APT_Zone_6_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion6);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion7 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion7.Zone = APT_Constants.ZONE7;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_7_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_7_Dispersion__c != r2tSystemProperties.APT_Zone_7_Dispersion__c) {
            ZoneDispersion7.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_7_Dispersion__c;
        } else {
            ZoneDispersion7.DefaultDispersion = r2tSystemProperties.APT_Zone_7_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion7);
        
        APT_SAP_SyncContractAndRatesService.ZoneDispersionType ZoneDispersion8 = new APT_SAP_SyncContractAndRatesService.ZoneDispersionType();
        ZoneDispersion8.Zone = APT_Constants.ZONE8;
        if(r2tSystemProperties != null && r2tSystemProperties.APT_Zone_8_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_8_Dispersion__c != r2tSystemProperties.APT_Zone_8_Dispersion__c) {
            ZoneDispersion8.ManualDispersion = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_8_Dispersion__c;
        } else {
            ZoneDispersion8.DefaultDispersion = r2tSystemProperties.APT_Zone_8_Dispersion__c;
        }
        listZoneDispersion.add(ZoneDispersion8);
        }
             
        
    
        ZoneDispersionDetails.ZoneDispersion = listZoneDispersion;
       
        return ZoneDispersionDetails;
    }    
    
    /**
        This method will populate customer pricing details
     */
    public static APT_SAP_SyncContractAndRatesService.CustomerPricingDetailsType populateCustomerPricingDetails(/*String rateType, */ Apttus_Proposal__Proposal_Line_Item__c parentPLI, APT_R2T_System_Properties__c r2tSystemProperties) {
        APT_SAP_SyncContractAndRatesService.CustomerPricingDetailsType CustomerPricingDetails = new APT_SAP_SyncContractAndRatesService.CustomerPricingDetailsType();
        //if(rateType != null && rateType == 'INTERNATIONAL') {
            //CustomerPricingDetails.Domestic = 'NO';
            CustomerPricingDetails.Domestic = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Domestic_Customer__c;
            
            //CustomerPricingDetails.IndustrySegment = 'YES';
            CustomerPricingDetails.IndustrySegment = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Industry__c;
            
            //YES or NO Values
            if(parentPLI.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL)){
                 CustomerPricingDetails.InternationalLetters = APT_Constants.OPTION_YES.ToUpperCase();
                 CustomerPricingDetails.EparcelLodgement = APT_Constants.OPTION_YES.ToUpperCase();
            }else{
            if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Letters__c) {
                CustomerPricingDetails.InternationalLetters = APT_Constants.OPTION_YES.ToUpperCase();
            } else {
                CustomerPricingDetails.InternationalLetters = APT_Constants.OPTION_NO.ToUpperCase();
            }
            
            if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c) {
                CustomerPricingDetails.EparcelLodgement = APT_Constants.OPTION_YES.ToUpperCase();
            } else {
                CustomerPricingDetails.EparcelLodgement = APT_Constants.OPTION_NO.ToUpperCase();
            }
            }
            if(!String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Volume_Data__c) && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Volume_Data__c.equalsIgnoreCase(APT_Constants.OPTION_YES) && r2tSystemProperties != null) {
                CustomerPricingDetails.VolumeAvailable = APT_Constants.OPTION_YES.toUpperCase();
                //CustomerPricingDetails.DispersionType = 'YES';
                Boolean bManualDispersion = false;
                if(r2tSystemProperties.APT_Zone_1_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_1_Dispersion__c != null && r2tSystemProperties.APT_Zone_1_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_1_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_2_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_2_Dispersion__c != null && r2tSystemProperties.APT_Zone_2_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_2_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_3_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_3_Dispersion__c != null && r2tSystemProperties.APT_Zone_3_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_3_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_4_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_4_Dispersion__c != null && r2tSystemProperties.APT_Zone_4_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_4_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_5_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_5_Dispersion__c != null && r2tSystemProperties.APT_Zone_5_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_5_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_6_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_6_Dispersion__c != null && r2tSystemProperties.APT_Zone_6_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_6_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_7_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_7_Dispersion__c != null && r2tSystemProperties.APT_Zone_7_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_7_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_8_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_8_Dispersion__c != null && r2tSystemProperties.APT_Zone_8_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_8_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_1Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_1Digital_Dispersion__c != null && r2tSystemProperties.APT_Zone_1Digital_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_1Digital_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_2Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_2Digital_Dispersion__c != null && r2tSystemProperties.APT_Zone_2Digital_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_2Digital_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_3Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_3Digital_Dispersion__c != null && r2tSystemProperties.APT_Zone_3Digital_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_3Digital_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_4Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_4Digital_Dispersion__c != null && r2tSystemProperties.APT_Zone_4Digital_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_4Digital_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_5Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_5Digital_Dispersion__c != null && r2tSystemProperties.APT_Zone_5Digital_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_5Digital_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_6Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_6Digital_Dispersion__c != null && r2tSystemProperties.APT_Zone_6Digital_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_6Digital_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_7Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_7Digital_Dispersion__c != null && r2tSystemProperties.APT_Zone_7Digital_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_7Digital_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_8Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_8Digital_Dispersion__c != null && r2tSystemProperties.APT_Zone_8Digital_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_8Digital_Dispersion__c) {
                    bManualDispersion = true;
                }
                if(r2tSystemProperties.APT_Zone_9Digital_Dispersion__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_9Digital_Dispersion__c != null && r2tSystemProperties.APT_Zone_9Digital_Dispersion__c != parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Zone_9Digital_Dispersion__c) {
                    bManualDispersion = true;
                }
                
                if(bManualDispersion) {
                    CustomerPricingDetails.DispersionType = APT_Constants.DISPERSION_TYPE_MANUAL;
                } else {
                    CustomerPricingDetails.DispersionType = APT_Constants.DISPERSION_TYPE_DEFAULT;
                }
            } else {
                CustomerPricingDetails.VolumeAvailable = APT_Constants.OPTION_NO.toUpperCase();
                //CustomerPricingDetails.DispersionType = 'NO';
            }
            
            /*
            if(rateType == APT_Constants.RATE_CARD_TYPE_DOMESTIC) {
                CustomerPricingDetails.Domestic = 'YES';
                CustomerPricingDetails.IndustrySegment = 'NO';
            } else {
                CustomerPricingDetails.Domestic = 'NO';
                CustomerPricingDetails.IndustrySegment = 'YES';
            }*/
        //}
        
        return CustomerPricingDetails;
    }
    
    /**
        This method will populate feature details
     */
    public static APT_SAP_SyncContractAndRatesService.FeaturesDetailsType populateFeaturesDetails(String rateCardType, Apttus_Proposal__Proposal_Line_Item__c parentPLI, list<Apttus_Proposal__Proposal_Line_Item__c> listOptionPLI, APT_R2T_System_Properties__c r2tSystemProperties) {
        APT_SAP_SyncContractAndRatesService.FeaturesDetailsType FeaturesDetails = new APT_SAP_SyncContractAndRatesService.FeaturesDetailsType();
        
        FeaturesDetails.ReturnsPercentageAnnualVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Returns_of_Total_Annual_Volume__c;
        FeaturesDetails.UpTo500GTotalReturnsVolume = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Up_to_500g_of_Total_Returns_Volume__c;
        FeaturesDetails.AverageChargeableWeight = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Average_Chargeable_Weight_Kg__c;
        
        if(listOptionPLI != null) {
            for(Apttus_Proposal__Proposal_Line_Item__c optionPLI : listOptionPLI) {
                system.debug('*** option product code ***'+optionPLI.Apttus_QPConfig__OptionId__r.ProductCode);
                if(!String.isEmpty(optionPLI.Apttus_QPConfig__OptionId__r.ProductCode) && optionPLI.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_EPARCEL_POST_RETURN)) {    //1817
                    FeaturesDetails.EparcelReturnsDeliveryFee = optionPLI.Apttus_QPConfig__NetPrice__c;
                    system.debug('*** option net price ***'+optionPLI.Apttus_QPConfig__NetPrice__c);
                }
                
                if(!String.isEmpty(optionPLI.Apttus_QPConfig__ChargeType__c) && optionPLI.Apttus_QPConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.PARCEL_POST_CALL_RETURN_DELIVERY_FEE)) {
                    FeaturesDetails.ParcelPostReturnsDeliveryFee = optionPLI.Apttus_QPConfig__NetPrice__c;
                }
                
                if(!String.isEmpty(optionPLI.Apttus_QPConfig__ChargeType__c) && optionPLI.Apttus_QPConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.PARCEL_POST_CALL_RETURN_PICK_UP_FEE)) {
                    FeaturesDetails.ParcelPostReturnsPickupFee = optionPLI.Apttus_QPConfig__NetPrice__c;
                }
                
                if(!String.isEmpty(optionPLI.Apttus_QPConfig__OptionId__r.ProductCode) && optionPLI.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.ePARCEL_IDENTITY_DELIVERY_SERVICE)) {
                    FeaturesDetails.IdentityDeliveryFee = optionPLI.Apttus_QPConfig__NetPrice__c;
                }
            }
        }
        
        //FeaturesDetails.ReturnPaidUpTo500GParcelPostFee = expected null
        //FeaturesDetails.ReturnPaidAnnualFee = expected null        
        
        FeaturesDetails.TransitCoverDetails = populateTransitCoverDetails(rateCardType, parentPLI, r2tSystemProperties);
        
        return FeaturesDetails;
    }
    
    /**
        This method will populate transit cover details
     */
    public static APT_SAP_SyncContractAndRatesService.TransitCoverDetailsType populateTransitCoverDetails(String rateCardType, Apttus_Proposal__Proposal_Line_Item__c parentPLI, APT_R2T_System_Properties__c r2tSystemProperties) {
        APT_SAP_SyncContractAndRatesService.TransitCoverDetailsType TransitCoverDetails = new APT_SAP_SyncContractAndRatesService.TransitCoverDetailsType();
        
        //TransitCoverDetails.TransitCover = Missing Mapping
        
        TransitCoverDetails.MinimumTransitCover = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c;
        
        if(r2tSystemProperties != null) {
            if(!String.isEmpty(rateCardType) && rateCardType.equalsIgnoreCase(APT_Constants.RATE_CARD_TYPE_DOMESTIC) && r2tSystemProperties.APT_Maximum_Transit_Cover__c != null) {
                TransitCoverDetails.MaximumTransitCover = r2tSystemProperties.APT_Maximum_Transit_Cover__c;
            }
            
            if(TransitCoverDetails.MinimumTransitCover != null) {
                if(TransitCoverDetails.MinimumTransitCover == 0 && r2tSystemProperties.APT_Transit_Cover_Percentage_Non_Bundled__c != null) {
                    TransitCoverDetails.Percentage = r2tSystemProperties.APT_Transit_Cover_Percentage_Non_Bundled__c / 100; 
                } else if(TransitCoverDetails.MinimumTransitCover != 0 && r2tSystemProperties.APT_Transit_Cover_Percentage_Bundled__c != null) {
                    TransitCoverDetails.Percentage = r2tSystemProperties.APT_Transit_Cover_Percentage_Bundled__c / 100; 
                } else {}                
            }
        }
        
        return TransitCoverDetails;
    }
    
    /**
        This method will populate standard charges
     */
    public static APT_SAP_SyncContractAndRatesService.StandardChargesType populateStandardCharges(String rateCardType, list<Apttus_Proposal__Proposal_Line_Item__c> listOptionPLI, APT_R2T_System_Properties__c r2tSystemProperties, Apttus_Proposal__Proposal_Line_Item__c parentPLI) {
        APT_SAP_SyncContractAndRatesService.StandardChargesType StandardCharges = new APT_SAP_SyncContractAndRatesService.StandardChargesType();
                
        if(listOptionPLI != null) {
            for(Apttus_Proposal__Proposal_Line_Item__c optionPLI : listOptionPLI) {
                if(!String.isEmpty(optionPLI.Apttus_QPConfig__OptionId__r.ProductCode) && optionPLI.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_MISSING_MANIFEST_FEE)) {
                    StandardCharges.MissingManifestFee = optionPLI.Apttus_QPConfig__NetPrice__c;
                }
                
                if(!String.isEmpty(optionPLI.Apttus_QPConfig__OptionId__r.ProductCode) && optionPLI.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ADMINISTRATIVE_FEE)) {
                    StandardCharges.DomesticAdminFee = optionPLI.Apttus_QPConfig__NetPrice__c;
                }
                
                if(!String.isEmpty(optionPLI.Apttus_QPConfig__OptionId__r.ProductCode) && optionPLI.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_MIN_COLLECTION_VALUE)) {   //1801
                    StandardCharges.MinimumCollectionFee = optionPLI.Apttus_QPConfig__NetPrice__c;
                }
                
                if(!String.isEmpty(optionPLI.Apttus_QPConfig__OptionId__r.ProductCode) && optionPLI.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_RETURN_TO_SENDER)) {
                    StandardCharges.ReturnToSenderFee = optionPLI.Apttus_QPConfig__NetPrice__c;
                }
            }
        }
        
        //for international only
        if(!String.isEmpty(rateCardType) && rateCardType.equalsIgnoreCase(APT_Constants.RATE_CARD_TYPE_INTERNATIONAL) && r2tSystemProperties != null && !String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Domestic_Customer__c)) {
            /*
            //APOST-677
            if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Domestic_Customer__c == 'Yes') {
                StandardCharges.CollectionFee = 0;
                StandardCharges.InternationalAdminFee = 0;
            } else{
                if(r2tSystemProperties.APT_Collection_Fee__c != null) {
                    StandardCharges.CollectionFee = r2tSystemProperties.APT_Collection_Fee__c.setScale(2);
                }
                
                if(r2tSystemProperties.APT_International_Admin_Fee__c != null) {
                    StandardCharges.InternationalAdminFee = r2tSystemProperties.APT_International_Admin_Fee__c.setScale(2);
                }
            }
            //APOST-677
            */
            
            //APOST-869
            //if domestic customer = yes then collectionFee and InternationalFee should be null
            if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Domestic_Customer__c.equalsIgnoreCase(APT_Constants.OPTION_NO)) {
                if(r2tSystemProperties.APT_Collection_Fee__c != null) {
                    StandardCharges.CollectionFee = r2tSystemProperties.APT_Collection_Fee__c.setScale(2);
                }
                
                if(r2tSystemProperties.APT_International_Admin_Fee__c != null) {
                    StandardCharges.InternationalAdminFee = r2tSystemProperties.APT_International_Admin_Fee__c.setScale(2);
                }
            }
            //APOST-869
        }
                       
        return StandardCharges;
    }
    
    /**
        This method will populate delivery choice fee details
     */
    public static APT_SAP_SyncContractAndRatesService.DeliveryChoicesFeesType populateDeliveryChoicesFeeDetails(APT_R2T_System_Properties__c r2tSystemProperties) {
        APT_SAP_SyncContractAndRatesService.DeliveryChoicesFeesType DeliveryChoicesFeeDetails = new APT_SAP_SyncContractAndRatesService.DeliveryChoicesFeesType();
        
        if(r2tSystemProperties != null) {
            if(r2tSystemProperties.APT_Customer_Collect_Location_Fee__c != null) {
                DeliveryChoicesFeeDetails.CustomerCollectLocation = r2tSystemProperties.APT_Customer_Collect_Location_Fee__c;
            }
            
            if(r2tSystemProperties.APT_Day_Specific_Delivery_Fee__c != null) {
                DeliveryChoicesFeeDetails.DaySpecificDeliveryFee = r2tSystemProperties.APT_Day_Specific_Delivery_Fee__c;
            }
            
            if(r2tSystemProperties.APT_Date_Specific_Delivery_Fee__c != null) {
                DeliveryChoicesFeeDetails.DateSpecificDeliveryFee = r2tSystemProperties.APT_Date_Specific_Delivery_Fee__c;
            }
            
            if(r2tSystemProperties.APT_Date_Embargo_Fee__c != null) {
                DeliveryChoicesFeeDetails.DateEmbargoFee = r2tSystemProperties.APT_Date_Embargo_Fee__c;
            }
            
            if(r2tSystemProperties.APT_AM_PM_Delivery_Window_Fee__c != null) {
                DeliveryChoicesFeeDetails.AMPMDeliveryWindowFee = r2tSystemProperties.APT_AM_PM_Delivery_Window_Fee__c;
            }
            
            if(r2tSystemProperties.APT_AM_PM_Delivery_Window_Day_Date_Fee__c != null) {
                DeliveryChoicesFeeDetails.AMPMDeliveryWindowDayDateFee = r2tSystemProperties.APT_AM_PM_Delivery_Window_Day_Date_Fee__c;
            }
            
            if(r2tSystemProperties.APT_Two_Hour_Delivery_Window_Fee__c != null) {
                DeliveryChoicesFeeDetails.TwoHourDeliveryWindowFee = r2tSystemProperties.APT_Two_Hour_Delivery_Window_Fee__c;
            }
            
            if(r2tSystemProperties.APT_Two_Hour_Delivery_Window_DayDate_Fee__c != null) {
                DeliveryChoicesFeeDetails.TwoHourDeliveryWindowDayDateFee = r2tSystemProperties.APT_Two_Hour_Delivery_Window_DayDate_Fee__c;
            }
        }        
        
        return DeliveryChoicesFeeDetails;
    }
    
    /**
        This method will populate current pricing details
     */
    public static APT_SAP_SyncContractAndRatesService.CurrentPricingDetailsType populateCurrentPricingDetails(Apttus_Proposal__Proposal_Line_Item__c pli, Apttus_Proposal__Proposal_Line_Item__c parentPLI) {
        APT_SAP_SyncContractAndRatesService.CurrentPricingDetailsType CurrentPricingDetails = new APT_SAP_SyncContractAndRatesService.CurrentPricingDetailsType();
        
        //mapping not found
        //CurrentPricingDetails.LodgementZoneName = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.Name;
        
        //not required
        //CurrentPricingDetails.LodgementZoneCode = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c;
        //CurrentPricingDetails.ChargeCode = pli.APT_Charge_Code_Formula__c;        
        //CurrentPricingDetails.Category = parentPLI.Apttus_QPConfig__AttributeValueId__r.Category__c;
        
        //CurrentPricingDetails.ContractTerm = expected null
        //CurrentPricingDetails.ContractStructure = expected null
        
        return CurrentPricingDetails;
    }
    
    /**
        This method will populate new pricing details
     */
    public static APT_SAP_SyncContractAndRatesService.NewPricingDetailsType populateNewPricingDetails(Apttus_Proposal__Proposal_Line_Item__c pli, 
                                                                                                Apttus_Proposal__Proposal_Line_Item__c parentPLI, 
                                                                                                APT_R2T_System_Properties__c r2tSystemProperties,
                                                                                                APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties) {
        APT_SAP_SyncContractAndRatesService.NewPricingDetailsType NewPricingDetails = new APT_SAP_SyncContractAndRatesService.NewPricingDetailsType();
        
        if(!String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c)) {
            //domestic
            NewPricingDetails.LodgementZoneCode = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c;
        
            NewPricingDetails.ChargeCode = pli.APT_Charge_Code_Formula__c;
        } else {
            //international
            NewPricingDetails.LodgementZoneCode = APT_Constants.LODGEMENT_ZONE_CODE_AU;
            
            //charge code
            if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_International_Letters__c && !parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_eParcel_Lodgment__c) {
                //CSP
                if(pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT)) {
                    //EMSDOCT
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_EMSDOCT_Contract_Structure__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_EMSDOCT_Contract_Structure__c;
                    }
                    //EMSMERCH
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_EMSMERCH_Contract_Structure__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_EMSMERCH_Contract_Structure__c;
                    }
                    //EMSMER20
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_EMSMER20_Contract_Structure__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_EMSMER20_Contract_Structure__c;
                    }
                } else if(pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT)) {
                    //AIRPCL
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c) && r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_AIRPCL_Contract_Structure__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRPCL_Contract_Structure__c;
                    }
                    
                    //AIRSMPCL
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c) && r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_AIRSMPCL_Contract_Structure__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRSMPCL_Contract_Structure__c;
                    }
                } else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_AIRLET_Contract_Structure__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRLET_Contract_Structure__c;
                } else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_AIRPTI_Contract_Structure__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRPTI_Contract_Structure__c;
                } else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_AIRRPI_Contract_Structure__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRRPI_Contract_Structure__c;
                } else {}
            } else {
                //PCMS
                if(pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT)) {
                    //EMSDOCT
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c.equalsIgnoreCase( pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_EMSDOCT_Charge_Code__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_EMSDOCT_Charge_Code__c;
                    }
                    //EMSMERCH
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_EMSMERCH_Charge_Code__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_EMSMERCH_Charge_Code__c;
                    }
                    //EMSMER20
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_EMSMER20_Charge_Code__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_EMSMER20_Charge_Code__c;
                    }
                } else if(pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT)) {
                    //AIRPCL
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c) && r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_AIRPCL_Charge_Code__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRPCL_Charge_Code__c;
                    }
                    
                    //AIRSMPCL
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c) && r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c) && !String.isEmpty(r2tSystemProperties.APT_AIRSMPCL_Charge_Code__c)) {
                        NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRSMPCL_Charge_Code__c;
                    }
                } else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_AIRLET_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRLET_Charge_Code__c;
                } else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_AIRPTI_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRPTI_Charge_Code__c;
                } else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_AIRRPI_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRRPI_Charge_Code__c;
                } 
                
                else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_EXPRESS_DOCT_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_EXPRESS_DOCT_Charge_Code__c;
                } 
                else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_EXPRESS_MERCH_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_EXPRESS_MERCH_Charge_Code__c;
                } 
                else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.STANDARD_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_STANDARD_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_STANDARD_Charge_Code__c;
                } 
                else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_STANDARD_SIGN_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_STANDARD_SIGN_Charge_Code__c;
                }               
                else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_ECONOMY_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_ECONOMY_Charge_Code__c;
                } 
                else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_ECONOMY_SIGN_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_ECONOMY_SIGN_Charge_Code__c;
                } 
                else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.RETURNS_EXPRESS_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_RETURNS_EXPRESS_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_RETURNS_EXPRESS_Charge_Code__c;
                } 
                else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.RETURNS_STANDARD_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tSystemProperties.APT_RETURNS_STANDARD_Charge_Code__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_RETURNS_STANDARD_Charge_Code__c;
                }
                else if(!String.isEmpty(pli.Apttus_QPConfig__OptionId__r.ProductCode) && pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS) && 
                    pli.Apttus_QPConfig__OptionId__r.Name.equalsIgnoreCase(APT_Constants.INTERNATIONAL_AIRMAIL_LETTERS) && !String.isEmpty(r2tSystemProperties.APT_AIRMAIL_LETTERS_Contract_structure__c)) {
                    NewPricingDetails.ChargeCode = r2tSystemProperties.APT_AIRMAIL_LETTERS_Contract_structure__c;
                }

                else {}
            }            
        }
        
        NewPricingDetails.LodgementZoneName = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone__c;
        
        NewPricingDetails.Category = parentPLI.Apttus_QPConfig__AttributeValueId__r.Category__c;
        NewPricingDetails.PriceZoneStructure = parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c;
        
        if(!String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c)) {
            Integer iIndex = parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c.indexOf(APT_Constants.SEPERATOR_SPACE);
            if(iIndex != null) {
                NewPricingDetails.PriceStructure = parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c.subString(0, iIndex);
            }
        }
        
        if(!String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c)) {
            Integer iIndex = parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c.indexOf(APT_Constants.Left_curly_bracket);
            if(iIndex != null) {
                NewPricingDetails.ZoneStructure = parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c.subString(iIndex + 1, parentPLI.Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c.length() - 1);
            }
        }        
        
        //NewPricingDetails.ValidFrom = expected null
        //NewPricingDetails.ValidTo = expected null
        
        return NewPricingDetails;
    }
    
    /**
        This method will populate flat rate details type information
     */
    public static APT_SAP_SyncContractAndRatesService.FlatRatesDetailsType populateFlatRatesDetailsType(Apttus_Proposal__Proposal_Line_Item__c parentPLI) {
        APT_SAP_SyncContractAndRatesService.FlatRatesDetailsType FlatRatesDetailsType = new APT_SAP_SyncContractAndRatesService.FlatRatesDetailsType();
        //APOST-1060
        //FlatRatesDetailsType.UpTo500GRate = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Up_to_500g_Rate__c;
        
        //APOST-869
        //If 0 zone then Over500GRate should be null.
        //if(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c != null && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Lodgement_Zone_Code__c.contains(APT_Constants.ADD_ZERO) == false){
        //APOST-1060
        //    FlatRatesDetailsType.Over500GRate = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Average_Weight_Over_500g__c;
        //}
        
        
        //FlatRatesDetailsType.DispersionType = expected null
        FlatRatesDetailsType.MaxWeightBreak = populateMaxWeightBreak();
        
        return FlatRatesDetailsType;
    } 
    
    /**
        This method will populate max weight break details
     */
    public static APT_SAP_SyncContractAndRatesService.MaxWeightBreak_element populateMaxWeightBreak() {
        APT_SAP_SyncContractAndRatesService.MaxWeightBreak_element MaxWeightBreak = new APT_SAP_SyncContractAndRatesService.MaxWeightBreak_element();
        //MaxWeightBreak.code = expected null
        //MaxWeightBreak.Description = expected null
        
        return MaxWeightBreak;
    }
    
    /**
        This method will populate band rate details
     */
    public static APT_SAP_SyncContractAndRatesService.BandRateDetailsType populateBandRateDetails(Apttus_Proposal__Proposal_Line_Item__c parentPLI) {
        APT_SAP_SyncContractAndRatesService.BandRateDetailsType BandRateDetails = new APT_SAP_SyncContractAndRatesService.BandRateDetailsType();
         
        if(!String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Band__c)) {
            BandRateDetails.Band = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Band__c.replace(APT_Constants.SEPERATOR_SPACE, APT_Constants.SEPERATOR_UNDER_SCROLL);
        }
         
        if(!String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Volume_Data__c) && parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Volume_Data__c.equalsIgnoreCase(APT_Constants.OPTION_YES)) {
            BandRateDetails.RevenueEstimation = parentPLI.Apttus_QPConfig__AttributeValueId__r.APT_Estimated_Revenue__c;    
        }
        
        if(!String.isEmpty(parentPLI.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c)) {
            BandRateDetails.RevenueRange = parentPLI.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c;
            /*
            //minRevenue
            if(parentPLI.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.ToLowerCase().contains('less than') == false) {
                Integer iIndex = parentPLI.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.indexOf(APT_Constants.ADD_HYPHEN);
                String minRevenueRange = parentPLI.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.subString(0, iIndex - 1);
                if(minRevenueRange != null) {
                    //revenue committment has special characters
                    if(minRevenueRange.contains(',') == true) {
                        minRevenueRange = minRevenueRange.replaceAll(',', APT_Constants.EMPTY_STRING);                      
                    }
                    
                    //BandRateDetails.MinRevenue =  decimal.valueOf(minRevenueRange);
                }
            } else {
                Integer iIndex = parentPLI.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.ToLowerCase().indexOf('less than');
                String revenue = parentPLI.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.subString(iIndex + 11, parentPLI.Apttus_QPConfig__AttributeValueId__r.Revenue_Committment__c.length());   
                if(revenue != null) {
                    //revenue committment has special characters
                    if(revenue.contains(',') == true) {
                        revenue = revenue.replaceAll(',', APT_Constants.EMPTY_STRING);                      
                    }
                    
                    //BandRateDetails.MinRevenue = decimal.valueOf(revenue);
                    //BandRateDetails.RevenueRange = decimal.valueOf(revenue);
                }               
            }
            */
        }
        
        return BandRateDetails;
    }
    
    /**
        This method will populate UK Rates details
     */
    public static APT_SAP_SyncContractAndRatesService.UKRatesDetailsType populateUKRatesDetails(APT_R2T_System_Properties__c r2tSystemProperties) {
        APT_SAP_SyncContractAndRatesService.UKRatesDetailsType UKRatesDetails = new APT_SAP_SyncContractAndRatesService.UKRatesDetailsType();
        UKRatesDetails.ExpressCourierRates = populateExpressCourierRates(r2tSystemProperties, APT_Constants.COUNTRY_CODE_UK);
        
        return UKRatesDetails;
    }
    
    /**
        This method will populate express courier rates
     */
    public static APT_SAP_SyncContractAndRatesService.ExpressCourierRates_element populateExpressCourierRates(APT_R2T_System_Properties__c r2tSystemProperties, String countryCode) {
        APT_SAP_SyncContractAndRatesService.ExpressCourierRates_element ExpressCourierRates = new APT_SAP_SyncContractAndRatesService.ExpressCourierRates_element();
        
        if(r2tSystemProperties != null && countryCode.equalsIgnoreCase(APT_Constants.COUNTRY_CODE_UK)) {
            if(r2tSystemProperties.APT_Express_Courier_UpTo_2KG_Per_Item_UK__c != null) {
                ExpressCourierRates.UpTo2KGPerItem = r2tSystemProperties.APT_Express_Courier_UpTo_2KG_Per_Item_UK__c.setScale(2);
            }
            
            if(r2tSystemProperties.APT_Express_Courier_Up_To_2KG_Per_KG_UK__c != null) {
                ExpressCourierRates.UpTo2KGPerKG = r2tSystemProperties.APT_Express_Courier_Up_To_2KG_Per_KG_UK__c.setScale(2);
            }
            
            if(r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_Item_UK__c != null) {
                ExpressCourierRates.Over2KGPerItem = r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_Item_UK__c.setScale(2);
            }
            
            if(r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_KG_UK__c != null) {
                ExpressCourierRates.Over2KGPerKG = r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_KG_UK__c.setScale(2);
            }
        }
        
        if(r2tSystemProperties != null && countryCode.equalsIgnoreCase(APT_Constants.COUNTRY_CODE_NZ)) {
            if(r2tSystemProperties.APT_Express_Courier_UpTo_2KG_Per_Item_NZ__c != null) {
                ExpressCourierRates.UpTo2KGPerItem = r2tSystemProperties.APT_Express_Courier_UpTo_2KG_Per_Item_NZ__c.setScale(2);
            }
            
            if(r2tSystemProperties.APT_Express_Courier_Up_To_2KG_Per_KG_NZ__c != null) {
                ExpressCourierRates.UpTo2KGPerKG = r2tSystemProperties.APT_Express_Courier_Up_To_2KG_Per_KG_NZ__c.setScale(2);
            }
            
            if(r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_Item_NZ__c != null) {
                ExpressCourierRates.Over2KGPerItem = r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_Item_NZ__c.setScale(2);
            }
            
            if(r2tSystemProperties.APT_Express_Courier_UpTo_2KG_Per_Item_NZ__c != null) {
                ExpressCourierRates.Over2KGPerKG = r2tSystemProperties.APT_Express_Courier_UpTo_2KG_Per_Item_NZ__c;
            }
        }
        
        return ExpressCourierRates;
    }
    
    /**
        This method will populate newzealand rates details
     */
    public static APT_SAP_SyncContractAndRatesService.NewZealandRatesDetailsType populateNewZealandRatesDetails(APT_R2T_System_Properties__c r2tSystemProperties) {
        APT_SAP_SyncContractAndRatesService.NewZealandRatesDetailsType NewZealandRatesDetails = new APT_SAP_SyncContractAndRatesService.NewZealandRatesDetailsType();
        NewZealandRatesDetails.AirmailRates = populateAirmailRates(r2tSystemProperties);
        NewZealandRatesDetails.ExpressCourierRates = populateExpressCourierRates(r2tSystemProperties, APT_Constants.COUNTRY_CODE_NZ);
        
        return NewZealandRatesDetails;
    }
    
    /**
        This method will populate air mail rates
     */
    public static APT_SAP_SyncContractAndRatesService.AirmailRates_element populateAirmailRates(APT_R2T_System_Properties__c r2tSystemProperties) {
        APT_SAP_SyncContractAndRatesService.AirmailRates_element AirmailRates = new APT_SAP_SyncContractAndRatesService.AirmailRates_element();
                
        if(r2tSystemProperties != null) {
            if(r2tSystemProperties.APT_Airmail_Rates_Up_To_2KG_Per_Item_NZ__c != null) {
                AirmailRates.UpTo2KGPerItem = r2tSystemProperties.APT_Airmail_Rates_Up_To_2KG_Per_Item_NZ__c.setScale(2);
            }
            
            if(r2tSystemProperties.APT_Airmail_Rates_Up_To_2KG_Per_KG_NZ__c != null) {
                AirmailRates.UpTo2KGPerKG = r2tSystemProperties.APT_Airmail_Rates_Up_To_2KG_Per_KG_NZ__c.setScale(2);
            }
            
            if(r2tSystemProperties.APT_Airmail_Rates_Over_2KG_Per_Item_NZ__c != null) {
                AirmailRates.Over2KGPerItem = r2tSystemProperties.APT_Airmail_Rates_Over_2KG_Per_Item_NZ__c.setScale(2);
            }
            
            if(r2tSystemProperties.APT_Airmail_Rates_Over_2KG_Per_KG_NZ__c != null) {
                AirmailRates.Over2KGPerKG = r2tSystemProperties.APT_Airmail_Rates_Over_2KG_Per_KG_NZ__c.setScale(2);
            }
        }
        
        return AirmailRates;
    }
    
    /**
        This method will populate comments 
     */
    public static APT_SAP_SyncContractAndRatesService.Comments_element populateComments() {
        APT_SAP_SyncContractAndRatesService.Comments_element Comments = new APT_SAP_SyncContractAndRatesService.Comments_element();
        //Comments.Comment = expected null
        
        return Comments;
    }    
    
    /**
        This method will populate sub product details
     */
    public static void populateSubProductDetails(APT_SAP_SyncContractAndRatesService.SubProductDetailsType SubProductDetails,
                                                Apttus_Proposal__Proposal_Line_Item__c pli,
                                                APT_SAP_SyncContractAndRatesService.ProductType product,
                                                APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties) {
        
        if(!String.isEmpty(pli.Apttus_Proposal__Product__r.ProductCode)) {
            if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)) {
                //SubProductDetails.Id = product.ProductDetails.Name;
                //SubProductDetails.Name = product.ProductDetails.Name;
                //SubProductDetails.Id = 'PCMS';
                //SubProductDetails.Name = 'PCMS';
                SubProductDetails.Id = APT_Constants.SUB_PRODUCT_PARCEL_SERVICES_EPARCEL;
                SubProductDetails.Name = APT_Constants.SUB_PRODUCT_PARCEL_SERVICES_EPARCEL;
            } else if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)) {
                SubProductDetails.Id = APT_Constants.SUB_PRODUCT_PARCEL_SERVICES_EXPRESS_EPARCEL;
                SubProductDetails.Name = APT_Constants.SUB_PRODUCT_PARCEL_SERVICES_EXPRESS_EPARCEL;
            } 
            else if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE)||
                      pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE)||
                      pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL)) {
                //APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = APT_R2T_International_Pricing_Properties__c.getValues(APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES);
                if(pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT)) {
                    //EMSDOCT
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c)) {
                        SubProductDetails.Id = APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT;
                        SubProductDetails.Name = APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT;
                    }
                    //EMSMERCH
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c)) {
                        SubProductDetails.Id = APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT;
                        SubProductDetails.Name = APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT;
                    }
                    //EMSMER20
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c) && r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c)) {
                        SubProductDetails.Id = APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT;
                        SubProductDetails.Name = APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT;
                    }                   
                } else if(pli.Apttus_QPConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT)) {
                    //AIRPCL
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c) && r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c)) {
                        SubProductDetails.Id = APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT;
                        SubProductDetails.Name = APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT;
                    }
                    //AIRSMPCL
                    if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c) && r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c.equalsIgnoreCase(pli.Apttus_QPConfig__ChargeType__c)) {
                        SubProductDetails.Id = APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT;
                        SubProductDetails.Name = APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT;
                    }
                } else {
                    SubProductDetails.Id = pli.Apttus_QPConfig__OptionId__r.ProductCode;
                    SubProductDetails.Name = pli.Apttus_QPConfig__OptionId__r.ProductCode;
                }           
            } 
            //1661
            //UMS
            else if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES)) {
            SubProductDetails.Id = APT_Constants.PRODUCT_DETAILS_UNADDRESSED_MAIL;
              SubProductDetails.Name = APT_Constants.PRODUCT_DETAILS_UNADDRESSED_MAIL;
          } 
          //print post
          else if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
            SubProductDetails.Id = APT_Constants.PRODUCT_DETAILS_PRINT_POST;
              SubProductDetails.Name = APT_Constants.PRODUCT_DETAILS_PRINT_POST;
          } 
          //1661
          else {}
        }               
        
        //SubProductDetails.Type_x
        //SubProductDetails.MinQuantityPerAnnum
    }
    
    
    
    /**
        Populate Populate Rate
    */
    public static APT_SAP_SyncContractAndRatesService.RateType populateRate(APT_SAP_Rate__c sapRate) {
        APT_SAP_SyncContractAndRatesService.RateType rate = new APT_SAP_SyncContractAndRatesService.RateType();
        rate.DestinationZoneCode = sapRate.APT_Destination_Zone_Code__c;
        rate.WeightRangeCode = sapRate.APT_Weight_Range_Code__c;
        rate.LookupFull = sapRate.APT_Lookup_Full__c;
        rate.LookupSub = sapRate.APT_Lookup_Sub__c;
        /* Shashwat.Nath@auspost.com.au commented out the below lines of code to incorporate the calculated rates for BANDED Z6
        rate.BaseRate = sapRate.APT_Base_Rate__c;
        rate.SubsequentRate = sapRate.APT_Subsequent_Rate__c;
        rate.PerKgRate = sapRate.APT_Per_Kg_Rate__c;*/
        
        /* Shashwat.Nath@Auspost.com.au added the below lines of code to update the output rates to consider
           the Banded Z6 calculations with Banker's rounding(HALF_EVEN) . For other pricing structures the below fields will return the actual rates commented out 
           in above piece of code */
        
        rate.BaseRate = sapRate.Calculated_Base_Rate__c.setscale(2, RoundingMode.HALF_EVEN);
        rate.SubsequentRate = sapRate.Calculated_Subsequent_Rate__c.setscale(2, RoundingMode.HALF_EVEN);
        rate.PerKgRate = sapRate.Calculated_Per_Kg_Rate__c.setscale(2, RoundingMode.HALF_EVEN);
        
        /*Shashwat.Nath@auspost.com.au code ends */
        
        rate.RAFCode = sapRate.APT_RAF_Code__c;
        rate.BaseRateManuallyAdjustedFlag = sapRate.APT_Base_Rate_Manually_Adjusted_Flag__c;
        rate.PerKgManuallyAdjustedFlag = sapRate.APT_Per_Kg_Manually_Adjusted_Flag__c;
        
        return rate;
    }
    
    /**
        Populate Detailed Rate
    */
    public static APT_SAP_SyncContractAndRatesService.DetailedRateType populateDetailedRate(APT_SAP_Rate__c sapRate) {
        APT_SAP_SyncContractAndRatesService.DetailedRateType detailedRate = new APT_SAP_SyncContractAndRatesService.DetailedRateType();
        detailedRate.ServicePriceValue = sapRate.APT_Service_Price_Value__c;
        detailedRate.ServicePriceDescription = sapRate.APT_Service_Price_Description__c;
        /* Shashwat.Nath@auspost.com.au commented out the below lines of code to incorporate the calculated rates for BANDED Z6
        detailedRate.BaseRate = sapRate.APT_Base_Rate__c;
        detailedRate.SubsequentRate = sapRate.APT_Subsequent_Rate__c;
        detailedRate.PerKgRate = sapRate.APT_Per_Kg_Rate__c; */
        
        /* Shashwat.Nath@Auspost.com.au added the below lines of code to update the output rates to consider
           the Banded Z6 calculations with Banker's rounding(HALF_EVEN). For other pricing structures the below fields will return the actual rates commented out 
           in above piece of code */
        detailedRate.BaseRate = sapRate.Calculated_Base_Rate__c.setscale(2, RoundingMode.HALF_EVEN);
        detailedRate.SubsequentRate = sapRate.Calculated_Subsequent_Rate__c.setscale(2, RoundingMode.HALF_EVEN);
        detailedRate.PerKgRate = sapRate.Calculated_Per_Kg_Rate__c.setscale(2, RoundingMode.HALF_EVEN);
        
        /*Shashwat.Nath@auspost.com.au code ends */
        
        return detailedRate;
    }
}