/**
Description: This apex class if handler class for apex trigger - APT_AgreementTrigger.
Created By: Garvita Rai
Created Date: 25th Nov, 2015

Last Modified By: Mausam Padhiyar
Last Modified Date: 16th Aug, 2016 | Defect 1284 | DOS issue

Last Modified By: Mausam Padhiyar
Last Modified Date: 13th Sept, 2016 | Defect 1284 | Courier Schedule Run checkbox issue

Last Modified By: Mausam Padhiyar
Last Modified Date: 10th Oct, 2016 | Contract Pricing

Last Modified By: Ramtej Juloori
Last Modified Date: 24th May, 2019 | Create operational schedule with record types

Last Modified By: Anshul Goyal
Last Modified Date: 28th June, 2019 |28062019|added null conditions to fix the selctive query issue for the case records

Last Modified By: Seth Heang
Last Modified Date: 19th Dec, 2019 | update courier condition to also apply to local pickup and delivery service

Last Modified By - Lija Jawahar
Last Modified Date - 28th May 2020 | SOQL Limit exceeding Fix

2020-10-22 - Mathew Jose - Identifying and setting included product lines on Agreement.

Last Modified By - Mahesh Patel
Last Modified Date - 15th Feb, 2021 | Decommision Contract Pricing

Last Modified By - Mahesh Patel
Last Modified Date - 23rd Feb, 2021 | STP-4289 STPAC - DLWT: Ability to generate the DOS with details of Track Mail product is auto populated

2021-03-02 - Mathew Jose - Amended Local pick & delivery service's automation on DOS to be based on included product lines
2021-08-31 - Naveen Rajanna - REQ2542972 - Set term to 'Fixed Term' when UMS or print Post
2022-04-14 -Sri Harsha-CI-128- Updated trigger code to populate expiration date.
2022-07-21 - INC1993350 Adding ContentDocument query to get the notes and attachment in lightning.
**/
public with sharing class APT_AgreementTriggerHandler{

    public static final string SOQL_AGREEMENT_LINE_ITEM_SELECT_INNER_WITHOUT_COMMA = ', (select APT_Agreement_Line_Item__c ';
    Public static final String ORGID = UserInfo.getOrganizationId();

    /**
        This method will update agreement's field based on field of owner user.(i.e. Manager, Seller Manager, Sales General Manager)
        @params -
        listOwner- list of Users
        listAgreement  - list of Agreements
     **/
    public static String  afterChangeofOwner(List<User>listOwner, List<Apttus__APTS_Agreement__c> listAgreement) {
        try{
            /*List<User> listOwner = new List<User>([SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where id in:setOwnerId]);*/
            Map <Id,Id> mapOwner = new Map<Id,Id>();
            for(User u : listOwner){
                mapOwner.put(u.id,u.ManagerId);
                mapOwner.put(u.ManagerId,u.Seller_Manager__c);
                mapOwner.put(u.Seller_Manager__c,u.Sales_General_Manager__c);
            }

            //Not feasible with Process Builder – not possible to access User fields via Owner lookup in Process Builder
            for(Apttus__APTS_Agreement__c agreement : listAgreement){
                system.debug('@@@@'+String.valueOf(agreement.OwnerId).substring( 0,3 ));
                if(String.valueOf(agreement.OwnerId).substring( 0,3 ).equalsIgnoreCase(APT_Constants.LABEL_USER_ID_PREFIX)){
                    agreement.APT_Seller_Manager__c = mapOwner.get(agreement.OwnerId);
                    agreement.APT_Sales_Director__c=mapOwner.get(agreement.APT_Seller_Manager__c);
                    agreement.APT_Sales_General_Manager__c=mapOwner.get(agreement.APT_Sales_Director__c);
                }
            }
            return APT_Constants.SUCCESS_LABEL;
        }
        catch(Exception e){
            return e.getMessage();
        }
    }

    /**
        This method will update agreement's Product lines field by looking at the products selected in the related proposal line items.
        @params -
        listAgreement  - list of Agreements
        relatedProposalMap - Map of related Proposals with line Items
     **/
    public static String  setProductLines(List<Apttus__APTS_Agreement__c> listAgreement, Map<Id, Apttus_Proposal__Proposal__c> relatedProposalMap) {
        try{
            for(Apttus__APTS_Agreement__c agreement : listAgreement){
                system.debug('Related Proposal Id'+agreement.Apttus_QPComply__RelatedProposalId__c);
                if(agreement.Apttus_QPComply__RelatedProposalId__c != null){
                    List<Apttus_Proposal__Proposal_Line_Item__c> proposalLineItems  = relatedProposalMap.get(agreement.Apttus_QPComply__RelatedProposalId__c)?.
                                                                                    Apttus_Proposal__R00N70000001yUfBEAU__r;
                    if(proposalLineItems != null){                    
                        agreement.Included_Product_Lines__c = getRelevantProductLinesString(proposalLineItems);
                    }

                    //REQ2542972
                    if (String.isNotBlank(agreement.Term__c) && !agreement.Term__c.equalsIgnoreCase(APT_Constants.TERM_FIXED_TERM) &&
                            String.isNotBlank(agreement.Included_Product_Lines__c) &&
                            (agreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_PRINT_POST) || agreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_UMS))) {
                        agreement.Term__c = APT_Constants.TERM_FIXED_TERM;
                    }
                }
            }
            return APT_Constants.SUCCESS_LABEL; 
        }catch(Exception e){
            return e.getMessage(); 
        }
    }
    /**
        Method is used to derive the multi-select picklist value for included product lines on an agreement.
        @params -
        pLineItems  - list of Proposal line items
     **/

    public static String getRelevantProductLinesString(List<Apttus_Proposal__Proposal_Line_Item__c> pLineItems) {
        Set<String>productLinesSet = new Set<String>();
        for(Apttus_Proposal__Proposal_Line_Item__c pli : pLineItems){
            //get the product record if the config type is not option and the product line items tagged on it.
            if(!string.isBlank(pli.Apttus_Proposal__Product__r.APT_Product_Lines__c) && pli.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c != 'Option'){
                productLinesSet.add(pli.Apttus_Proposal__Product__r.APT_Product_Lines__c);
            }
        }
        return productLinesSet.isEmpty() ? null : String.join(new List<String>(productLinesSet), ';');        
    }

    /**
      before Agreement is Fully Signed
     **/
    public static Void  beforeAgreementFullySigned(Map<Id, Apttus__APTS_Agreement__c> oldAgreementMap, List<Apttus__APTS_Agreement__c> newAgreementList) {
        Set<ID> proposalIdSet = new Set<ID>();
        List<APT_Agreement_Lodgement_Point__c> agreementLPList = null;
        Set<ID> agreementIds = new Set<ID>();
        try {
            for(Apttus__APTS_Agreement__c agreement : newAgreementList){
                Apttus__APTS_Agreement__c oldAgreement = oldAgreementMap.get(agreement.id);
                if(!String.isEmpty(oldAgreement.Apttus__Status__c) && !String.isEmpty(agreement.Apttus__Status__c) &&
                        !oldAgreement.Apttus__Status__c.equalsIgnoreCase(agreement.Apttus__Status__c)
                        && (APT_Constants.AGREEMENT_STATUS_FULLY_SIGNED).equalsIgnoreCase(agreement.Apttus__Status__c)){
                    proposalIdSet.add(agreement.Apttus_QPComply__RelatedProposalId__c);
                    agreementIds.add(agreement.id);
                }

            }

            if(proposalIdSet.size()> 0){
                agreementLPList = [select id,APT_Billing_Account__c,APT_Billing_Account__r.LEGACY_ID__c, APT_Agreement__c
                from APT_Agreement_Lodgement_Point__c where APT_Agreement__c in: agreementIds
                And APT_Billing_Account__r.LEGACY_ID__c != null];
            }

            //popolate Billing accounts on Contract
            Map<String, String> contractTOBillingAccountMap = new Map<String, String>();
            if(agreementLPList != null && agreementLPList.size() > 0 ){
                for(APT_Agreement_Lodgement_Point__c agrLP : agreementLPList){

                    if(null != agrLP.APT_Billing_Account__r.LEGACY_ID__c && String.isNotBlank(agrLP.APT_Billing_Account__r.LEGACY_ID__c)){
                        String BillingAccountId  = String.IsNotBlank(contractTOBillingAccountMap.get(agrLP.APT_Agreement__c))
                                ? contractTOBillingAccountMap.get(agrLP.APT_Agreement__c) + APT_Constants.ADD_COMMA
                                : APT_Constants.SEPERATOR_NO_SPACE ;
                        if(!BillingAccountId.contains(agrLP.APT_Billing_Account__r.LEGACY_ID__c)) {
                            BillingAccountId = BillingAccountId + agrLP.APT_Billing_Account__r.LEGACY_ID__c;
                            contractTOBillingAccountMap.put(agrLP.APT_Agreement__c, BillingAccountId);
                        }

                    }
                }
            }


            //Populate Product Names to contract
            Map<ID, Boolean> postalProductsOnAgreementMap = new Map<ID, Boolean>();
            Map<ID, Boolean> eParcelProductsOnAgreementMap = new Map<ID, Boolean>();
            Map<ID, Boolean> otherProductsOnAgreementMap = new Map<ID, Boolean>();
            Map<ID, Boolean> cspProductsOnAgreementMap = new Map<ID, Boolean>();

            for(Apttus__AgreementLineItem__c ali: [select id, Apttus__ProductId__r.Name, Apttus__ProductId__r.ProductCode, Apttus__ProductId__r.Family,
                    Apttus__ProductId__r.APT_Apttus_Product_Classification__c, Apttus__AgreementId__c, Apttus__AgreementId__r.APT_Ratecards_Created__c,
                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Gross_Settlement_fee__c,
                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c,
                    Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_International_Letters__c
            from Apttus__AgreementLineItem__c where Apttus__AgreementId__c in : agreementIds]){

                //Kushal Logic to check
                System.Debug('^^^^^^^^Kushal'+ali.Apttus__AgreementId__r.APT_Ratecards_Created__c);
                System.Debug('^^^^^^^^Kushal'+ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Gross_Settlement_fee__c);

                if(APT_Constants.BUNDLE_NAME_INTERNATIONAL.equalsIgnoreCase(ali.Apttus__ProductId__r.Name)){
                    system.debug('ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c --->' + ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c);
                    system.debug('ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_International_Letters__c --->' + ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_International_Letters__c);

                    if(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c != null &&
                            ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c){
                        cspProductsOnAgreementMap.put(ali.Apttus__AgreementId__c, true);

                    } else if(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_International_Letters__c != null &&
                            ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_International_Letters__c){
                        otherProductsOnAgreementMap.put(ali.Apttus__AgreementId__c, true);
                    } else{
                        otherProductsOnAgreementMap.put(ali.Apttus__AgreementId__c, true);
                    }
                    //US-126: Added APPC Product
                } else if(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode)
                        || APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode)
                         || APT_Constants.PRODUCT_CODE_APPC.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode)){
                    eParcelProductsOnAgreementMap.put(ali.Apttus__AgreementId__c, true);
                } else if(APT_Constants.PARCEL_SERVICES.equalsIgnoreCase(ali.Apttus__ProductId__r.Family)){
                    otherProductsOnAgreementMap.put(ali.Apttus__AgreementId__c, true);
                } else {
                    postalProductsOnAgreementMap.put(ali.Apttus__AgreementId__c, true);
                }
            }

            for(Apttus__APTS_Agreement__c agreement : newAgreementList){
                if(agreementIds.contains(agreement.ID)){
                    if(String.IsNotBlank(contractTOBillingAccountMap.get(agreement.ID))){
                        agreement.APT_Associated_Billing_Accounts__c = contractTOBillingAccountMap.get(agreement.ID);
                    }

                    Boolean postalProductsFlag = postalProductsOnAgreementMap.get(agreement.Id) != null ? postalProductsOnAgreementMap.get(agreement.Id) : false;
                    Boolean otherProductsFlag = otherProductsOnAgreementMap.get(agreement.Id) != null ? otherProductsOnAgreementMap.get(agreement.Id) : false;
                    Boolean eParcelProductsFlag = eParcelProductsOnAgreementMap.get(agreement.Id) != null ? eParcelProductsOnAgreementMap.get(agreement.Id) : false;
                    Boolean cspinternationalProductsFlag = cspProductsOnAgreementMap.get(agreement.Id) != null ? cspProductsOnAgreementMap.get(agreement.Id) : false;

                    system.debug('postalProductsFlag--->' + postalProductsFlag);
                    system.debug('otherProductsFlag--->' + otherProductsFlag);
                    system.debug('eParcelProductsFlag--->' + eParcelProductsFlag);
                    system.debug('cspinternationalProductsFlag--->' + cspinternationalProductsFlag);
                    system.debug('Eparcel--->' + (eParcelProductsFlag && !(otherProductsFlag) && !(postalProductsFlag) ));


                    if(eParcelProductsFlag && !(otherProductsFlag) && !(postalProductsFlag) ){
                        agreement.APT_Rollup_Product_Names__c = APT_Constants.eParcel_Product;
                    } else if(postalProductsFlag && !otherProductsFlag && !cspinternationalProductsFlag && !eParcelProductsFlag ) {
                        agreement.APT_Rollup_Product_Names__c = APT_Constants.POSTAL_SERVICES;
                    } else {
                        agreement.APT_Rollup_Product_Names__c = APT_Constants.Other_Product;
                    }

                    /*
                    if(postalProductsFlag && !otherProductsFlag && !eParcelProductsFlag){
                        agreement.APT_Rollup_Product_Names__c = APT_Constants.POSTAL_SERVICES;
                    } else if(eParcelProductsFlag && (otherProductsFlag || postalProductsFlag)){
                        agreement.APT_Rollup_Product_Names__c = APT_Constants.Other_Product;
                    } else if(eParcelProductsFlag && !otherProductsFlag && !otherProductsFlag){
                        agreement.APT_Rollup_Product_Names__c = APT_Constants.eParcel_Product;
                    } else {}*/
                }
            }
        } catch(system.exception ex) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            throw ex;
        }
    }


    /**
       @params -
       setAgIds - Set Of Agreement Ids
   **/
    public static void afterAgreementActivatedForChildAgreements(set<Id> setAgIds) {
        if(setAgIds != null && setAgIds.size() > 0){
            Map<Id,Apttus__APTS_Related_Agreement__c> mapAgreementToAgreement = new Map<ID,Apttus__APTS_Related_Agreement__c>();
            List<Apttus__APTS_Related_Agreement__c>  relatedAgreementDetailsList = [select Apttus__APTS_Contract_To__c, Apttus__APTS_Contract_From__c,
                    Apttus__APTS_Contract_To__r.Apttus__Version_Number__c
            from Apttus__APTS_Related_Agreement__c
            where Apttus__APTS_Contract_To__c in :setAgIds];

            if(relatedAgreementDetailsList != null && relatedAgreementDetailsList.size() > 0){
                for(Apttus__APTS_Related_Agreement__c relationship : relatedAgreementDetailsList){
                    mapAgreementToAgreement.put(relationship.Apttus__APTS_Contract_From__c,relationship);
                }
                Set<ID> parentAgreementIdSet = new Set<ID>();
                parentAgreementIdSet.addAll(mapAgreementToAgreement.keySet());

                /**
                //1655
                String queryString = 'Select  '
                                         + getSelectFieldsString('APT_SAP_Contracts__c')
                                         + ' from APT_SAP_Contracts__c where APT_Apttus_Contract__c in: parentAgreementIdSet';
                system.Debug('queryString-->' + queryString);
                system.Debug('parentAgreementIdSet-->' + parentAgreementIdSet);
                system.Debug('mapAgreementToAgreement-->' + mapAgreementToAgreement);
                List<APT_SAP_Contracts__c> sapContractsList = database.query(queryString);
                List<APT_SAP_Contracts__c> sapContractsToBeCloned = new List<APT_SAP_Contracts__c>();
                if(sapContractsList != null && sapContractsList.size() > 0 ){
                    APT_SAP_Contracts__c cloneSAPContract;
                    for(APT_SAP_Contracts__c sapContract : sapContractsList){
                        cloneSAPContract = new APT_SAP_Contracts__c();
                        cloneSAPContract = sapContract.clone();
                        if(mapAgreementToAgreement.get(sapContract.APT_Apttus_Contract__c) != null){
                            cloneSAPContract.APT_Apttus_Contract__c = mapAgreementToAgreement.get(sapContract.APT_Apttus_Contract__c).Apttus__APTS_Contract_To__c;
                            String sapContractnumber  = sapContract.APT_SAP_Contract_Number__c.substring(0,7);

                            cloneSAPContract.APT_SAP_Contract_Number__c = sapContractnumber +'.' +
                                                                             + mapAgreementToAgreement.get(sapContract.APT_Apttus_Contract__c).Apttus__APTS_Contract_To__r.Apttus__Version_Number__c;
                            sapContractsToBeCloned.add(cloneSAPContract);
                        }

                    }

                    if(sapContractsToBeCloned != null && sapContractsToBeCloned.size() > 0){
                        insert sapContractsToBeCloned;
                    }
                }
                //1655
                **/

            }

        }


    }

    /**
       Method to activate the contract when the Status is Fully Signed and Record type is Secure pay
       @params -
       setAgIds - Set Of Agreement Ids
   **/
    public static String  afterAgreementFullySigned(set<Id> setAgIds) {
        try{
            MAP<Id,Id> mapAgIds = new MAP<Id,Id>();
            String[] remDocIds = new String[]{};
            for(attachment att : [select id,parentID from attachment where parentId IN: setAgIds ORDER BY LastModifiedDate ASC]){
                mapAgIds.put(att.parentID,att.Id);
            }
            //Adding ContentDocument query to fetch the file type from Content Document in lightning 
            
            for(ContentDocumentLink contDocLink :ContentDocumentLinksSelector.newInstance().search(new Map<String, Object>{'entityIds' => setAgIds}, true).values()){              
                 mapAgIds.put(contDocLink.LinkedEntityId,contDocLink.contentdocumentId);                                   
            }
            list<String> activateDocIds;
            for(Id agreementId:setAgIds){
                if(String.isEmpty(mapAgIds.get(agreementId))){
                    return APT_Constants.AGREEMENT_ATTACHMENT_ERROR_MESSAGE;
                }
                activateDocIds = new list<String>();
                activateDocIds.add(mapAgIds.get(agreementId));
                Boolean response = Apttus.AgreementWebService.activateAgreement(agreementId, activateDocIds, remDocIds);
                Boolean responseatt = Apttus.AgreementWebService.publishToChatterRepository(agreementId, mapAgIds.get(agreementId));
                // Boolean responseatt = Apttus.AgreementWebService.publishToDocumentRepository(agreementId, mapAgIds.get(agreementId));
            }
            return APT_Constants.SUCCESS_LABEL;
        } catch(Exception ex) {
            return ex.getMessage();
        }
    }


    /**
        This method will create operational schedule records
    **/
    public static String createOperationalSchedule(List<Apttus__APTS_Agreement__c> listAgrmnt) {
        try{
            Map<ID,Schema.RecordTypeInfo> recordTypeMap = new Map<ID, Schema.RecordTypeInfo>();
            Map<ID,RecordType> opSchedRecTypeMap = new Map<ID, RecordType>();
            recordTypeMap = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById();
            opSchedRecTypeMap = RecordTypesSelector.newInstance().selectByDeveloperName('APT_Operational_Schedule__c', new Set<String>{APT_Constants.RECORD_TYPE_NAME_APPC,APT_Constants.OPERATIONAL_SCHEDULE_STARTTRACK_RECORDTYPE});    //CI:126 Added APPC Record Type   
            List<APT_Operational_Schedule__c> listOprSchedule = new List<APT_Operational_Schedule__c>();
            Set<ID> proposalIDSet = new Set<ID>();
            APT_Operational_Schedule__c opSchedule = new APT_Operational_Schedule__c();

            // CI:126 preparing Data for OperationalSchedule record population
            Set<Id> setAccountIds = new Set<Id>();
            Set<Id> setAgreements = new Set<Id>();
            //contract pricing
            set<Id> agreementIds = new set<Id>();
            //contract pricing
            //collect proposal ids
            List<Id> proposalIds = new List<Id>();
            for(Apttus__APTS_Agreement__c agrmnt : listAgrmnt){
                //28062019-added to make sure the null proposal ids are not added in the list
                if(agrmnt.Apttus_QPComply__RelatedProposalId__c!=null){
                    proposalIds.add(agrmnt.Apttus_QPComply__RelatedProposalId__c);
                }

                //CI:126
                setAccountIds.add(agrmnt.Apttus__Account__c);
                setAgreements.add(agrmnt.Id);
            }

            //CI:126
            Map<Id,Account> mapAccount = AccountsSelector.newInstance().selectById(setAccountIds);
            //commenting below SOQL, not required as a part of CI-106 which is a design change on top of CI-126 by Gopesh Banker on 22/04/2022
            // Map<Id,APT_Site_Inspection__c> mapSiteInspection = new Map<Id,APT_Site_Inspection__c>([SELECT Id,APT_Contract__r.Operational_Schedule__c,
            // APT_Agreement_Lodgement_Point__c,
            // APT_Agreement_Lodgement_Point__r.APT_Agreement_Line_Item__c,
            // APT_Agreement_Lodgement_Point__r.APT_Agreement_Line_Item__r.Apttus__ProductId__c,
            // APT_Agreement_Lodgement_Point__r.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode,
            // APT_Contract__r.Operational_Schedule__r.APT_Parcel_Collection_Point_Ids__c,
            // APT_Contract__r.Operational_Schedule__r.APT_Parcel_Collection_Points__c,
            // APT_Collection_Street_Address__c,
            // APT_State__c,
            // APT_Suburb__c,
            // APT_Postal_Code__c,
            // APT_Agreement_Lodgement_Point__r.APT_Billing_Account__r.LEGACY_ID__c,
            // APT_Contract__r.Operational_Schedule__r.APT_Parcel_Collection_Times__c,
            // APT_Requested_Collection_Time__c
            // FROM APT_Site_Inspection__c
            // WHERE APT_Agreement_Lodgement_Point__r.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode =: APT_Constants.PRODUCT_CODE_APPC
            // AND APT_Contract__c IN :setAgreements]);

            //create map of proposals to identify if it has startrack products
            //The proposalToPriceListMap which was used to iterate through the proposal line items is removed.
            //This iteration is will be based on SOQL below which retrieves the related proposal line items.
            //Map<Id,List<Apttus_Proposal__Proposal_Line_Item__c>> proposalToPriceListMap = new Map<Id,List<Apttus_Proposal__Proposal_Line_Item__c>>();
            Map<Id,Apttus_Proposal__Proposal__c > proposalsWithLineItemsMap = new Map<Id,Apttus_Proposal__Proposal__c >();
            //Iterate through the list of proposal line items and query related product fields for the related proposal on contract
            if(!proposalIds.isEmpty()){ //28062019- added to fix selective query issue
                //need to move this query to the selector if it exists.
                proposalsWithLineItemsMap = new Map <Id, Apttus_Proposal__Proposal__c>([
                                                                                       Select Id, APT_minimum_monthly_spend__c, APT_STE_Pricing_Tier__c,
                                                                                           (SELECT Id, Apttus_Proposal__Product__c, Apttus_Proposal__Proposal__c,
                                                                                            Apttus_Proposal__Product__r.APT_Product_type__c,
                                                                                            Apttus_Proposal__Product__r.Name,
                                                                                            Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Monthly_Spend__c, 
                                                                                            Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_StarTrack_Service_Type__c,
                                                                                            Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c,
                                                                                            Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Spend_Per_Annum__c,
                                                                                            Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c,
                                                                                            Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Existing_APPC_Customer__c                                                                           
                                                                                            FROM Apttus_Proposal__R00N70000001yUfBEAU__r)
                                                                                       FROM Apttus_Proposal__Proposal__c
                                                                                       WHERE Id IN :proposalIds]);                                                                                                                                                                                                                                         
            }

            //create a map to query case under related proposal to copy approved entities, approved ABN and payment terms from
            //the latest case
            //system.debug('proposalIds '+proposalIds.size());
            //system.debug('proposalIds '+proposalIds);
            Map<Id,Case> proposalToCaseMap = new Map<Id,Case>();
            if(!proposalIds.isEmpty()){ ////28062019- added to fix selective query issue
                for(Case proposalCase :[SELECT Id, Proposal__c, APT_Approved_ABN__c,
                        APT_Approved_Entities__c, APT_Payment_Terms__c FROM Case
                WHERE Proposal__c IN :proposalIds ORDER BY LastModifiedDate DESC]){
                    if(!proposalToCaseMap.containsKey(proposalCase.Proposal__c)){
                        proposalToCaseMap.put(proposalCase.Proposal__c,proposalCase);
                    }
                }
            }

            //LJ moved out of for loop
            List<R2T_Exempted_Contract_Settings__mdt> contractSettingList = [SELECT Id, MasterLabel, Operational_Schedule_RecordType__c FROM R2T_Exempted_Contract_Settings__mdt ];
            Map<String ,R2T_Exempted_Contract_Settings__mdt> contractSettingsMap = new Map<String ,R2T_Exempted_Contract_Settings__mdt>();
            for(R2T_Exempted_Contract_Settings__mdt contSetting : contractSettingList){
                contractSettingsMap.put(contSetting.MasterLabel, contSetting);

            }
            for(Apttus__APTS_Agreement__c agrmnt : listAgrmnt){
                proposalIDSet.add(agrmnt.Apttus_QPComply__RelatedProposalId__c);
                if(recordTypeMap.get(agrmnt.recordTypeID).getName().containsIgnoreCase(APT_Constants.RECORD_TYPE_MSA_SERVICE_SCHEDULE) && (agrmnt.APT_Contract_Type__c.equalsIgnoreCase(APT_Constants.CONTRACT_TYPE_NEW_CONTRACT))){
                    opSchedule = new APT_Operational_Schedule__c();
                    opSchedule.APT_Contract__c=agrmnt.Id;
                    opSchedule.APT_Minimum_Monthly_Revenue__c = proposalsWithLineItemsMap.get(agrmnt.Apttus_QPComply__RelatedProposalId__c)?.APT_minimum_monthly_spend__c;
                    //for agreement's proposal get the line items from the proposalsWithLineItemsMap
                    if(proposalsWithLineItemsMap.containskey(agrmnt.Apttus_QPComply__RelatedProposalId__c) && !proposalsWithLineItemsMap.get(agrmnt.Apttus_QPComply__RelatedProposalId__c).Apttus_Proposal__R00N70000001yUfBEAU__r.isEmpty()){ 
                        for(Apttus_Proposal__Proposal_Line_Item__c propLineItem : proposalsWithLineItemsMap.get(agrmnt.Apttus_QPComply__RelatedProposalId__c).Apttus_Proposal__R00N70000001yUfBEAU__r){
                            system.debug('prop details 1 '+propLineItem);
                            if(propLineItem.Apttus_Proposal__Product__r.APT_Product_type__c != null){
                                String productType = propLineItem.Apttus_Proposal__Product__r.APT_Product_type__c;
                                //If Product Type = Startrack, ensure relevant checkboxes are set on the Operational schedule.
                                if(productType.equalsIgnoreCase(APT_Constants.OPERATIONAL_SCHEDULE_STARTRACK_PRODUCT_TYPE)){
                                    opSchedule.APT_Startrack__c = true;
                                    // set the operational schedule record type to star track
                                    opSchedule.RecordTypeId = opSchedRecTypeMap.values()?.get(1)?.Id;
//                                    string productName = propLineItem.Apttus_Proposal__Product__r.Name;
//                                    if(productName.equalsIgnoreCase(APT_Constants.OPERATIONAL_SCHEDULE_EXPRESS_ROAD_PRODUCT)) {
//                                        opSchedule.APT_Express_Road__c = true;
//                                    }
//                                    else if(productName.equalsIgnoreCase(APT_Constants.OPERATIONAL_SCHEDULE_SPECIAL_SERVICES_PRODUCT)){
//                                        opSchedule.APT_Special_Services_Tailgate__c = true;
//                                    }
//                                    else if(productName.equalsIgnoreCase(APT_Constants.OPERATIONAL_SCHEDULE_PRIORITY_AIR_SERVICES_PRODUCT)){
//                                        String serviceType = propLineItem.Apttus_QPConfig__DerivedFromId__r?.Apttus_Config2__AttributeValueId__r?.APT_StarTrack_Service_Type__c;
//                                        System.debug('Service Type::'+serviceType);
//                                        if(serviceType != null){
//                                            if(serviceType.equalsIgnoreCase('FPP')){
//                                                opSchedule.Fixed_Price_Premium__c = true;
//                                            }else if(serviceType.equalsIgnoreCase('PRM')){
//                                                opSchedule.Premium_Priority_Air_Services__c = true;
//                                            }
//                                        }
//                                    }
//                                    else if(productName.equalsIgnoreCase(APT_Constants.OPERATIONAL_SCHEDULE_SECURITY_SERVICES_PRODUCT)) {
//                                        opSchedule.APT_Security_Services__c = true;
//                                    }
//                                    else if(productName.equalsIgnoreCase(APT_Constants.OPERATIONAL_SCHEDULE_NEXT_FLIGHT_PRODUCT)) {
//                                        opSchedule.APT_Next_Flight__c = true;
//                                    }

                                }       

                                //STP-4289 STPAC - DLWT: Ability to generate the DOS with details of Track Mail product is auto populated
                                //Set Track Mail to true in case of Track Mail Product
                                //Update Minimum Quantity for Track Mail Product on DOS
                                if(productType.equalsIgnoreCase(APT_Constants.OPERATIONAL_SCHEDULE_TRACKMAIL_PRODUCT_TYPE))
                                {
                                    opSchedule.APT_Track_Mail__c = true;         
                                    opSchedule.APT_TrackMail_Minimum_Quantity__c = propLineItem.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c;                                  
                                }
                                
                                //US:CI-126
                                if(productType.equalsIgnoreCase(APT_Constants.PRODUCT_TYPE_PARCEL_CONTRACT)) 
                                    {
                                      opSchedule.RecordTypeId = opSchedRecTypeMap.values()?.get(0)?.Id;  
                                      if(propLineItem.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Existing_APPC_Customer__c)
                                      {
                                        opSchedule.APT_APPC_Minimum_spend__c = mapAccount.get(agrmnt.Apttus__Account__c).APT_Min_Spend_Per_Annum__c;
                                      }
                                      else {
                                          opSchedule.APT_APPC_Minimum_spend__c = propLineItem.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Spend_Per_Annum__c;
                                         }
                                          opSchedule.APT_Parcel_Services_Transit_Cover_Amount__c = propLineItem.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c;
                                    }
                                
                                //US: CI-126
                                //commenting below SOQL, not required as a part of CI-106 which is a design change on top of CI-126 by Gopesh Banker on 22/04/2022
                                // for(APT_Site_Inspection__c siteInsp : mapSiteInspection.values())
                                // {                                    
                                //     if(agrmnt.id == siteInsp.APT_Contract__c)
                                //     {
                                //         if(String.IsNotBlank(siteInsp.APT_Contract__r.Operational_Schedule__c) &&
                                //         String.isNotBlank(siteInsp.APT_Agreement_Lodgement_Point__c) &&
                                //         String.isNotBlank(siteInsp.APT_Agreement_Lodgement_Point__r.APT_Agreement_Line_Item__c) &&
                                //         String.isNotBlank(siteInsp.APT_Agreement_Lodgement_Point__r.APT_Agreement_Line_Item__r.Apttus__ProductId__c) &&
                                //         siteInsp.APT_Agreement_Lodgement_Point__r.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_APPC))
                                //         {	
                                //             opSchedule.APT_Parcel_Collection_Point_Ids__c = opSchedule.APT_Parcel_Collection_Point_Ids__c + ',' + siteInsp.Id;
                                //             opSchedule.APT_Parcel_Collection_Points__c = opSchedule.APT_Parcel_Collection_Points__c + ' ' + siteInsp.APT_Collection_Street_Address__c + ' ' + siteInsp.APT_State__c + ' ' + siteInsp.APT_Suburb__c + ' ' + siteInsp.APT_Postal_Code__c + ' ' + siteInsp.APT_Agreement_Lodgement_Point__r.APT_Billing_Account__r.LEGACY_ID__c + ' ';
                                //             opSchedule.APT_Parcel_Collection_Times__c = opSchedule.APT_Parcel_Collection_Times__c + ' ' + siteInsp.APT_Requested_Collection_Time__c;
                                //         }
                                //     }                                    
                                // }
                                

                                //Following code which calculated the monthly spend based on the proposal line items removed
                                //This calculation is now based on the Minimum Monthly Spend field on Proposal.
                                /*Decimal currentMonthlySpend = propLineItem.Apttus_QPConfig__DerivedFromId__r?.Apttus_Config2__AttributeValueId__r?.APT_Monthly_Spend__c;
                                maxMonthlySpend = (currentMonthlySpend != null && currentMonthlySpend > maxMonthlySpend) ? currentMonthlySpend : maxMonthlySpend;
                                opSchedule.APT_Minimum_Monthly_Revenue__c =  maxMonthlySpend;*/

                                //if product type is defined for the product query metadata R2T_Exempted_Contract_Settings__mdt defines product type and record type mapping
                                R2T_Exempted_Contract_Settings__mdt contractSettings =  contractSettingsMap.get(propLineItem.Apttus_Proposal__Product__r.APT_Product_type__c);
                                //if record type is assigned in metadata create operational schedule with that record type
                                if(contractSettings != null && contractSettings.Operational_Schedule_RecordType__c != null){
                                    opSchedule.RecordTypeId = contractSettings.Operational_Schedule_RecordType__c;
                                }
                                //Following code is being removed as contractsetting metadata was removed.
                                //Startrack checkbox is set based on Product type.
                                /*if(contractSettings != null && contractSettings.MasterLabel == APT_Constants.OPERATIONAL_SCHEDULE_STARTTRACK_RECORDTYPE){
                                    opSchedule.APT_Startrack__c = true;
                                }*/
                                if(contractSettings != null && contractSettings.MasterLabel == APT_Constants.OPERATIONAL_SCHEDULE_WORKFORCE_VERIFICATION_RECORDTYPE){
                                    opSchedule.APT_Workforce_Verification__c = true;
                                    //copy Approved Entities, Approved ABN and Payment terms from case related to related proposal of the agreement
                                    if(proposalToCaseMap.get(agrmnt.Apttus_QPComply__RelatedProposalId__c) != null){
                                        opSchedule.APT_Approved_ABN__c = proposalToCaseMap.get(agrmnt.Apttus_QPComply__RelatedProposalId__c).APT_Approved_ABN__c;
                                        opSchedule.APT_Approved_Entities__c = proposalToCaseMap.get(agrmnt.Apttus_QPComply__RelatedProposalId__c).APT_Approved_Entities__c;
                                        opSchedule.APT_Payment_Terms__c = proposalToCaseMap.get(agrmnt.Apttus_QPComply__RelatedProposalId__c).APT_Payment_Terms__c;
                                    }
                                }
                            }
                        }
                    }
                    listOprSchedule.add(opSchedule);
                }
                

                //contract pricing
                if(recordTypeMap.get(agrmnt.recordTypeID).getName().containsIgnoreCase(APT_Constants.RECORD_TYPE_POST_BILLPAY_CONTRACT)) {
                    agreementIds.add(agrmnt.Id);
                }
                //contract pricing
            } 

            insert listOprSchedule;

            system.Debug('proposalIDSet--->' + proposalIDSet);



            //add Agreement Line items.
            Map<ID, ID> configMapToProposal = new Map<ID,ID>();
            if(proposalIDSet != null && proposalIDSet.size() > 0){
                List<Apttus_Config2__ProductConfiguration__c> configurationList = [select id, Apttus_QPConfig__Proposald__c
                from Apttus_Config2__ProductConfiguration__c
                where Apttus_QPConfig__Proposald__c in: proposalIDSet
                AND Apttus_Config2__Status__c =: APT_Constants.CONFIGURATION_STATUS_FINALIZED
                order By Apttus_Config2__VersionNumber__c Asc];
                system.Debug('--->' + configurationList);
                system.Debug('proposalIDSet--->' + proposalIDSet);

                if(configurationList!= null && configurationList.size()> 0 ){
                    for(Apttus_Config2__ProductConfiguration__c config : configurationList){
                        configMapToProposal.Put( config.Apttus_QPConfig__Proposald__c, config.ID);
                    }
                }

                for(Apttus__APTS_Agreement__c agrmnt : listAgrmnt){
                    String configID = configMapToProposal.get(agrmnt.Apttus_QPComply__RelatedProposalId__c);

                    if(null != agrmnt.Included_Product_Lines__c && String.IsNotBlank(agrmnt.Included_Product_Lines__c) && String.IsNotBlank(configID)){
                        APT_AmendRenewUtility.createAgreementChildRecords(configID, agrmnt.ID);
                    }
                }
            }

            //Decommissioned Contract Pricing
            //Id jobID = System.enqueueJob(new APT_ContractPricingQueueable(agreementIds));
            
        } catch(Exception e){
            // return e.getMessage();
            return 'Error '+e.getMessage()+' at line '+e.getStackTraceString();
        }

        return APT_Constants.SUCCESS_LABEL;

    }
    /**
     This method will Create Agreement line items as well as agreement price tiers for agreements.
     @params -
     agreementList- list of Agreements
  **/
    public static void addPostBillPayLineItemsToChild(List<Apttus__APTS_Agreement__c> agreementList){
        try {
            Set<ID> agreementIds = new Set<ID>();
            ID postBillPayRecordTypeId;// = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Postbillpay Contract').getRecordTypeId();

            RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType= :APT_Constants.SOQL_AGREEMENT_OBJECT and DeveloperName = :APT_Constants.SOQL_POSTBILLPAT_CONTRACT];
            postBillPayRecordTypeId = rt.id;
            system.debug('--->' + rt);


            List<Apttus__AgreementLineItem__c> agreementLineItemsToBeInserted = new List<Apttus__AgreementLineItem__c>();


            List<Apttus__APTS_Agreement__c> agreementsToBeProcessed = new List<Apttus__APTS_Agreement__c>();

            for(Apttus__APTS_Agreement__c agreement : agreementList){

                System.Debug(agreement.RecordTypeID + '-->');
                System.Debug(postBillPayRecordTypeId + '-->postBillPayRecordTypeId');

                if(postBillPayRecordTypeId == agreement.RecordTypeID && null != agreement.Apttus__Parent_Agreement__c && String.isNotBlank(agreement.Apttus__Parent_Agreement__c)
                        && APT_Constants.CONTRACT_TYPE_NEW_CONTRACT.equalsIgnoreCase(agreement.APT_Contract_Type__c)){
                    agreementIds.add(agreement.Apttus__Parent_Agreement__c);
                    agreementsToBeProcessed.add(agreement);
                }
            }
            if(agreementIds.size() > 0){

                List<Apttus__AgreementLineItem__c> agreementLineItemsList = getAgreementLineItemsCloned(agreementIds);
                if(agreementLineItemsList == null || agreementLineItemsList.size() == 0){ return;}

                Map<id,List<Apttus__AgreementLineItem__c>> agreementLineItemMapByAgreementId = new Map<id,List<Apttus__AgreementLineItem__c>>();
                List<Apttus__AgreementLineItem__c> aliList;
                for(Apttus__AgreementLineItem__c aLineItem : agreementLineItemsList){
                    aliList = agreementLineItemMapByAgreementId.get(aLineItem.Apttus__AgreementId__c) != null  ? agreementLineItemMapByAgreementId.get(aLineItem.Apttus__AgreementId__c)
                            : new List<Apttus__AgreementLineItem__c>();
                    System.Debug(aLineItem + '-->');
                    aliList.add(aLineItem);
                    agreementLineItemMapByAgreementId.put(aLineItem.Apttus__AgreementId__c,aliList);
                }

                for(Apttus__APTS_Agreement__c agreement : agreementsToBeProcessed){
                    if(agreementLineItemMapByAgreementId.get(agreement.Apttus__Parent_Agreement__c) != null){
                        for(Apttus__AgreementLineItem__c ali : agreementLineItemMapByAgreementId.get(agreement.Apttus__Parent_Agreement__c) ){

                            Apttus__AgreementLineItem__c aliClone = ali.clone(false,true);
                            aliClone.Apttus__AgreementId__c = agreement.id;

                            agreementLineItemsToBeInserted.add(aliClone);
                        }
                    }

                }
            }
            Set<ID> agreementIdSet = new Set<ID>();
            if(agreementLineItemsToBeInserted.size() > 0 ) {
                insert agreementLineItemsToBeInserted;
                List<APT_Agreement_Rate_Card__c> agreementRatecards = new List<APT_Agreement_Rate_Card__c>();
                for(Apttus__AgreementLineItem__c ali : agreementLineItemsToBeInserted){


                    if(ali.Agreement_Rate_Card__r != null && ali.Agreement_Rate_Card__r.size() > 0 ){
                        for(APT_Agreement_Rate_Card__c arc : ali.Agreement_Rate_Card__r){

                            APT_Agreement_Rate_Card__c arcClone = arc.clone();
                            arcClone.APT_Agreement_Line_Item__c = ali.id;
                            arcClone.APT_Agreement__c= ali.Apttus__AgreementId__c;

                            agreementRatecards.add(arcClone);
                        }
                    }
                    agreementIdSet.add(ali.Apttus__AgreementId__c);
                }

                if(agreementRatecards.size() > 0 ){ insert agreementRatecards;}
                if(agreementIdSet.size() > 0){
                    List<Apttus__APTS_Agreement__c> agreementListToBeUpdated = new List<Apttus__APTS_Agreement__c>();
                    Apttus__APTS_Agreement__c agreement;
                    for(String agrmtID : agreementIdSet){
                        agreement = new Apttus__APTS_Agreement__c();
                        agreement.Id = agrmtID;
                        agreement.APT_Ratecards_Created__c = true;
                        agreementListToBeUpdated.add(agreement);
                    }
                    update agreementListToBeUpdated;
                }

            }

        } catch(system.exception ex) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));

            throw ex;
        }
    }

    public static final string SOQL_AGREEMENT_RATE_CARD_OBJECT_INNER_REF = ' from Agreement_Rate_Card__r order by Name) ';
    /**
      Method for get agreenebt line items
  **/
    public static List<Apttus__AgreementLineItem__c> getAgreementLineItemsCloned(Set<Id> agreementIds){
        try {
            String objectName = APT_Constants.SOQL_AGREEMENT_LINE_ITEM_OBJECT;
            String selects = APT_Constants.SOQL_AGREEMENT_OBJECT_SELECT ;

            system.debug(logginglevel.error,'*** selects 1 ***'+selects);


            selects = selects + getSelectFieldsString(objectName);

            string agreementRatecardFields = getSelectFieldsString(APT_Constants.SOQL_AGREEMENT_RATE_CARD_OBJECT);

            system.debug(logginglevel.error,'*** agreementRatecardFields  ***'+agreementRatecardFields );




            String agreementRateCardString;
            if(String.isNotBlank(agreementRatecardFields)) {
                agreementRateCardString = APT_Constants.SOQL_AGREEMENT_LINE_ITEM_SELECT_INNER + agreementRatecardFields + SOQL_AGREEMENT_RATE_CARD_OBJECT_INNER_REF;
            } else {
                agreementRateCardString = SOQL_AGREEMENT_LINE_ITEM_SELECT_INNER_WITHOUT_COMMA + agreementRatecardFields + SOQL_AGREEMENT_RATE_CARD_OBJECT_INNER_REF;
            }

            system.debug(logginglevel.error,'*** APT_Constants.SOQL_AGREEMENT_LINE_ITEM_SELECT_INNER***'+APT_Constants.SOQL_AGREEMENT_LINE_ITEM_SELECT_INNER);
            system.debug(logginglevel.error,'*** agreementRatecardFields ***'+agreementRatecardFields );
            system.debug(logginglevel.error,'*** SOQL_AGREEMENT_RATE_CARD_OBJECT_INNER_REF***'+SOQL_AGREEMENT_RATE_CARD_OBJECT_INNER_REF);
            system.debug(logginglevel.error,'*** agreementRateCardString ***'+agreementRateCardString );

            /*string agreementLPFields = getSelectFieldsString(APT_Constants.SOQL_AGREEMENT_LODGEMENT_POINT_OBJECT);

             String agreementLPFieldsString = APT_Constants.SOQL_AGREEMENT_LODGEMENT_POINT_FIELDS + agreementLPFields + APT_Constants.SOQL_AGREEMENT_LODGEMENT_POINT_FROM;

             string agreementUsagePriceFields = getSelectFieldsString(APT_Constants.SOQL_AGREEMENT_USAGE_PRICE_TIER_OBJECT);

             String agreementUsagePriceFieldsString = APT_Constants.SOQL_AGREEMENT_USAGE_PRICE_TIER_SELECT_INNER + agreementUsagePriceFields
                                                             + APT_Constants.SOQL_AGREEMENT_USAGE_PRICE_TIER_FROM;


             String query = selects + agreementRateCardString  + agreementLPFieldsString + agreementUsagePriceFieldsString
                                 + APT_Constants.SOQL_FROM + objectName + APT_Constants.SOQL_AGREEMENT_USAGE_PRICE_TIER_WHERE;

             */

            system.debug(logginglevel.error,'*** APT_Constants.SOQL_FROM ***'+APT_Constants.SOQL_FROM);
            system.debug(logginglevel.error,'*** objectName ***'+objectName);
            system.debug(logginglevel.error,'*** APT_Constants.SOQL_AGREEMENT_USAGE_PRICE_TIER_WHERE ***'+APT_Constants.SOQL_AGREEMENT_USAGE_PRICE_TIER_WHERE);

            String query = selects + agreementRateCardString + APT_Constants.SOQL_FROM
                    + objectName + APT_Constants.SOQL_AGREEMENT_USAGE_PRICE_TIER_WHERE;

            System.Debug(logginglevel.error,'query-->' + query);

            List<Apttus__AgreementLineItem__c> agreementLineItemsList = database.query(query);

            return agreementLineItemsList;
        } catch(system.exception ex) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            throw ex;
            //return null;
        }
    }
    /**
        Method for get selected field string
    **/
    private static String getSelectFieldsString(String objectName){
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
        String queryFields = APT_Constants.SEPERATOR_NO_SPACE;

        if (fMap != null){

            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isUpdateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }

        system.debug(logginglevel.error,'*** selectFields ***'+selectFields);
        if (!selectFields.isEmpty()){
            queryFields = String.Join(selectFields, APT_Constants.SEPERATOR_COMMA_SPACE) ;
        }
        system.debug(logginglevel.error,'*** queryFields ***'+queryFields);
        return queryFields;
    }

    /**
     Method for Deleting Extra Contract Line Item(LOI/Postpaybill Contract)
    **/
    public static void deleteExtralineItems(Map<ID, Apttus__APTS_Agreement__c> oldAgreementMap,
            Map<ID, Apttus__APTS_Agreement__c> newAgreementMap){
        try{
            List<Apttus__APTS_Agreement__c> agreementsToBeProcessed = new List<Apttus__APTS_Agreement__c>();
            Set<ID> proposalIDSet = new Set<ID>();
            map<Id, String> mapOSId = new map<Id, String>();
            for(Apttus__APTS_Agreement__c newAgreement: newAgreementMap.values()){
                Apttus__APTS_Agreement__c oldAgreement = oldAgreementMap.get(newAgreement.id);

                if(string.isEmpty(oldAgreement.Included_Product_Lines__c) && !string.isEmpty(newAgreement.Included_Product_Lines__c)){
                    agreementsToBeProcessed.add(newAgreement);
                    proposalIDSet.add(newAgreement.Apttus_QPComply__RelatedProposalId__c);
                }

                //1084
                system.debug('*** included product lines ***'+newAgreement.Included_Product_Lines__c);
                if((null != newAgreement.Included_Product_Lines__c && String.isNotBlank(newAgreement.Included_Product_Lines__c) && String.isNotBlank(oldAgreementMap.get(newAgreement.id).Included_Product_Lines__c) && !newAgreement.Included_Product_Lines__c.equalsIgnoreCase(oldAgreementMap.get(newAgreement.id).Included_Product_Lines__c)) || (String.isNotBlank(newAgreement.Included_Product_Lines__c) && String.isBlank(oldAgreementMap.get(newAgreement.id).Included_Product_Lines__c))) {
                    mapOSId.put(newAgreement.Operational_Schedule__c, newAgreement.Included_Product_Lines__c);
                }
                //1084
            }

            //1084
            String includedProductLines;
            list<APT_Operational_Schedule__c> listUpdateOS = new list<APT_Operational_Schedule__c>();
            APT_Operational_Schedule__c os = new APT_Operational_Schedule__c();
            system.debug('*** mapOSId ***'+mapOSId);
            for(Id osId : mapOSId.keySet()) {
                system.debug('*** osId ***'+osId);
                os = new APT_Operational_Schedule__c();
                includedProductLines = null;
                os.Id = osId;
                includedProductLines = mapOSId.get(osId);

                //domestic
                //CI-126: Added Condition for Parcel Contract Product Type
                if(String.isNotBlank(includedProductLines) && (includedProductLines.contains(APT_Constants.EPARCELS_DOMESTIC) || includedProductLines.contains(APT_Constants.PRODUCT_TYPE_PARCEL_CONTRACT))) {
                    os.APT_Parcel__c = true;
                } else {
                    os.APT_Parcel__c = false;
                    os.APT_Parcel_Services_eParcel__c = false;
                    os.APT_Parcel_Services_Transit_Cover__c = false;
                    os.APT_Parcel_Servcs_eParcel_Retrns_Service__c = false;
                    os.APT_Parcel_Srvics_eParcel_Call_for_Retrn__c = false;
                    os.APT_Parcl_Servcs_eParcl_Identity_on_Deli__c = false;

                    os.APT_Parcels_AP_Contact__c = null;
                    os.APT_Parcels_Customer_Contact__c = null;
                    os.APT_Parcels_Minimum_Quantity_per_annum__c = null;

                    os.APT_Parcel_Lodgement_Points__c = null;
                    os.APT_Parcel_Collection_Points__c = null;

                    os.APT_Parcel_Services_Express_Post_Parcel__c = false;
                    os.APT_Parcel_Services_Express_eParcel__c = false;
                }

                //international postal
                if(String.isNotBlank(includedProductLines) && includedProductLines.contains(APT_Constants.INTERNATIONAL)) {
                    os.APT_International_Postal__c = true;
                } else {
                    os.APT_International_Postal__c = false;

                    os.APT_International_Postal_AP_Contact__c = null;
                    os.APT_Internat_Postal_Customer_Contact__c = null;
                    os.APT_IP_Minimum_Revenue_per_annum__c = null;
                    os.APT_International_Lodgement_Points__c = null;
                    os.APT_International_Collection_Points__c = null;

                    os.APT_IP_Services_Airmail__c = false;
                    os.APT_IP_Services_Registered_Post__c = false;
                    os.APT_IP_Services_Pack_and_Track__c = false;
                    os.APT_IP_Servcs_Exprss_Courier_Internatnal__c = false;
                }

                //print post
                if(String.isNotBlank(includedProductLines) && includedProductLines.contains(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
                    os.APT_Print_Post__c = true;
                } else {
                    os.APT_Print_Post__c = false;
                    os.APT_Print_Post_AP_Contact__c = null;
                    os.APT_Print_Post_Publications__c = null;
                    os.APT_Print_Post_Customer_Contact__c = null;
                    os.APT_Print_Post_Lodgement_Points__c = null;
                    os.APT_Print_Post_Collection_Points__c = null;
                }

                //courier or local pickup
                // Change by mathewjose@auspost.com.au - Updated the condition to check for local pickup & delivery amongst the included product lines.
                if(String.isNotBlank(includedProductLines) && (includedProductLines.contains(APT_Constants.PRODUCT_CODE_COURIER) || includedProductLines.contains(APT_Constants.PRODUCT_NAME_LOCAL_PICKUP_DELIVERY))) {
                    os.APT_Courier__c = true;
                    os.APT_Courier_Scheduled_Run__c = true;     //1284
                } else {
                    os.APT_Courier__c = false;
                    os.APT_Courier_Scheduled_Run__c = false;    //1284
                    os.APT_Courier_AP_Contact__c = null;
                    os.APT_Courier_on_demand_services__c = false;
                    os.APT_Interstate_Distribution__c = false;
                    os.APT_Taxi_Truck_services__c = false;
                    os.APT_Courier_Customer_Contact__c = null;
                    os.APT_Courier_Business_Account_del__c = null;
                }

                //ums
                if(String.isNotBlank(includedProductLines) && includedProductLines.contains(APT_Constants.PRODUCT_CODE_UMS)) {
                    os.APT_Unaddressed_Mail__c = true;
                } else {
                    os.APT_Unaddressed_Mail__c = false;
                    os.APT_UMS_Minimum_Quantity__c = null;
                    os.APT_UMS_Customer_Contact__c = null;
                    os.APT_UMS_Lodgement_Points__c = null;
                    os.APT_UMS_Mode_of_Booking__c = null;
                }

                if(os.Id != null) {
                    listUpdateOS.add(os);
                }
            }
            system.debug('*** listUpdateOS ***'+listUpdateOS);
            if(listUpdateOS.size() > 0) {
                update listUpdateOS;
            }
            //1084

            Map<ID, ID> configMapToProposal = new Map<ID,ID>();
            if(proposalIDSet != null && proposalIDSet.size() > 0){
                List<Apttus_Config2__ProductConfiguration__c> configurationList = [select id, Apttus_QPConfig__Proposald__c
                from Apttus_Config2__ProductConfiguration__c
                where Apttus_QPConfig__Proposald__c in: proposalIDSet
                AND Apttus_Config2__Status__c =: APT_Constants.CONFIGURATION_STATUS_FINALIZED
                order By Apttus_Config2__VersionNumber__c Asc];
                system.Debug('--->' + configurationList);
                system.Debug('proposalIDSet--->' + proposalIDSet);

                if(configurationList!= null && configurationList.size() > 0 ){
                    for(Apttus_Config2__ProductConfiguration__c config : configurationList){
                        configMapToProposal.Put( config.Apttus_QPConfig__Proposald__c, config.ID);
                    }
                }

                for(Apttus__APTS_Agreement__c agrmnt : agreementsToBeProcessed){
                    String configID = configMapToProposal.get(agrmnt.Apttus_QPComply__RelatedProposalId__c);

                    if(null != agrmnt.Included_Product_Lines__c && String.IsNotBlank(agrmnt.Included_Product_Lines__c) && String.IsNotBlank(configID)){
                        APT_AmendRenewUtility.createAgreementChildRecords(configID, agrmnt.ID);
                    }
                }
            }
            /*
            if(agreementIdsToBeProcessed.size() > 0 ) {

                deleteAgreementLineItemsBasedOnProductType(agreementIdsToBeProcessed);
            }*/
        }
        catch(Exception e){
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            throw e;
        }
    }
    /**
       Method for delete agreement line item
   **/
    // Updated by Adrian Recio
    // Description Method not used. Commented out to reduce code limit consumption
    // Date 7/4/2017
    /*
    @future
    public static void deleteAgreementLineItemsBasedOnProductType(Set<ID> agreementIds){
        try {
            //List<Apttus__AgreementLineItem__c> aliList = [select id, Apttus__AgreementId__c,Apttus__AgreementId__r.Included_Product_Lines__c , Apttus__ProductId__c, Apttus__ProductId__r.APT_Product_type__c, Apttus__ProductId__r.Non_contracted__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c  in : agreementIds ];
            List<Apttus__AgreementLineItem__c> aliTobeDeleted = new List<Apttus__AgreementLineItem__c>();
            //System.debug('aliList --> ' + aliList);

            for(Apttus__AgreementLineItem__c ali : [select id, Apttus__AgreementId__c,
                                                        Apttus__AgreementId__r.Included_Product_Lines__c ,
                                                        Apttus__ProductId__c, Apttus__ProductId__r.APT_Product_type__c,
                                                        Apttus__ProductId__r.Non_contracted__c,
                                                        Apttus__AgreementId__r.RecordType.DeveloperName
                                                        from Apttus__AgreementLineItem__c
                                                        where Apttus__AgreementId__c  in : agreementIds ]) { //aliList ){
                System.Debug('ProductId--> ' +  ali.Apttus__ProductId__c);
                String linesToBeInsertedTypes = ali.Apttus__AgreementId__r.Included_Product_Lines__c;
                String productType =  ali.Apttus__ProductId__r.APT_Product_type__c;

                if(!(String.IsNotBlank(productType)
                        && linesToBeInsertedTypes.ToLowercase().contains(productType.toLowerCase()))
                        || ali.Apttus__ProductId__r.Non_contracted__c){
                    aliTobeDeleted.add(ali);

                }
             }

             System.debug('aliTobeDeleted --> ' + aliTobeDeleted);
             if(aliTobeDeleted != null && aliTobeDeleted.size() > 0){
                 List<APT_Agreement_Lodgement_Point__c> alpList = [select id from APT_Agreement_Lodgement_Point__c where APT_Agreement_Line_Item__c in:aliTobeDeleted];
                 if(alpList != null && alpList.size() > 0){
                     List<Database.DeleteResult> deleteResults  = Database.delete(alpList, false);
                 }
                 List<Database.DeleteResult> deleteResultsALI  = Database.delete(aliTobeDeleted, false);
             }
        } catch(system.exception ex) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            throw ex;
        }

    }
    */
    /**
    Method for update agreement with attribute
   **/

    public static String updateAgreementwithAttribute(List<Apttus__APTS_Agreement__c> listAgrmnt) {

        try{
            set<id> quoteIds = new set<id>();
            Set<ID> opportunityIds = new Set<ID>();

            Map<Id,Apttus_Proposal__Proposal_Line_Item__c> mapQuotePLI =new  Map<Id,Apttus_Proposal__Proposal_Line_Item__c>();

            for(Apttus__APTS_Agreement__c ag:listAgrmnt){
                quoteIds.add(ag.Apttus_QPComply__RelatedProposalId__c);
                opportunityIds.add(ag.Apttus__Related_Opportunity__c);
            }

            Map<Id,Opportunity> mapOpportunity =new  Map<Id,Opportunity>([select id, Amount, Account.Organisation_Trading_Name__c,
                    Account.Name, Account.Organisation_Alternate_Name__c
            from opportunity where id in : opportunityIds]);
            List<Application__c> applicationsList = [select id, name, Opportunity__c, SettlementProfile__c,
                    PricingPlan__r.PricingPlanDesc__c from Application__c
            where Opportunity__c in : opportunityIds];
            Map<ID, Application__c> mapApplicationsWithOpportunityIds = new Map<ID, Application__c>();
            Map<ID, Apttus_Proposal__Proposal__c> mapProposal = new Map<ID, Apttus_Proposal__Proposal__c>([select id,Apttus_Proposal__Proposal_Expiration_Date__c, APT_Contracting_Entity__c,Apttus_QPApprov__Approval_Status__c  from Apttus_Proposal__Proposal__c where id in: quoteIds]);

            //creating APMS List based on Opportunity
            if(applicationsList != null && applicationsList.size() > 0 ){
                for(Application__c application : applicationsList){
                    mapApplicationsWithOpportunityIds.put(application.Opportunity__c, application);
                }
            }



            for(Apttus_Proposal__Proposal_Line_Item__c pLI: [select id,Apttus_Proposal__Proposal__c,Apttus_QPConfig__AttributeValueId__r.Category__c from
                    Apttus_Proposal__Proposal_Line_Item__c where
            Apttus_QPConfig__IsPrimaryLine__c=True AND Apttus_QPConfig__LineType__c != :APT_Constants.LABEL_LINE_TYPE_OPTION
            AND (APT_Product_Name__c= :APT_Constants.PRODUCT_NAME_EPARCEL OR APT_Product_Name__c= :APT_Constants.PRODUCT_NAME_EPARCEL_EXPRESS)
            AND Apttus_Proposal__Proposal__c in: quoteIds]){
                mapQuotePLI.put(pLI.Apttus_Proposal__Proposal__c,pLI);
            }

            for(Apttus__APTS_Agreement__c agreement: listAgrmnt){
                agreement.APT_Customer_Application_Contact__c = agreement.Apttus__Primary_Contact__c;
                agreement.APT_Commercial_Contact__c = agreement.Apttus__Primary_Contact__c;
                agreement.APT_Operational_contact__c = agreement.Apttus__Primary_Contact__c;
                agreement.APT_System_User__c = agreement.Apttus__Primary_Contact__c;
                Application__c apms = mapApplicationsWithOpportunityIds.get(agreement.Apttus__Related_Opportunity__c);
                Apttus_Proposal__Proposal__c proposal = mapProposal.get(agreement.Apttus_QPComply__RelatedProposalId__c);
                agreement.Contract_Expiration_Date__c=mapProposal.get(agreement.Apttus_QPComply__RelatedProposalId__c).Apttus_Proposal__Proposal_Expiration_Date__c;
                Opportunity opp = mapOpportunity.get(agreement.Apttus__Related_Opportunity__c);

                if(mapQuotePLI.get(agreement.Apttus_QPComply__RelatedProposalId__c) != null){
                    agreement.APT_Domestic_Category__c =mapQuotePLI.get(agreement.Apttus_QPComply__RelatedProposalId__c).Apttus_QPConfig__AttributeValueId__r.Category__c;
                }

                if(null != opp){
                    agreement.Apttus__Total_Contract_Value__c = opp.Amount;
                    //agreement.APT_Registered_Business_Name__c = String.IsBlank(opp.Account.Organisation_Trading_Name__c) ? opp.Account.Name : opp.Account.Organisation_Trading_Name__c;
                    agreement.APT_Registered_Business_Name__c =opp.Account.Name;
                    agreement.APTContract_Party_Legal_and_Trading_Name__c = opp.Account.Name;
                    //agreement.APT_Trading_As__c = String.IsBlank(opp.Account.Organisation_Alternate_Name__c) ? opp.Account.Name : opp.Account.Organisation_Alternate_Name__c;
                    agreement.APT_Trading_As__c = opp.Account.Organisation_Trading_Name__c;
                }


                if(null != proposal){
                    agreement.APT_Contracting_Entity1__c = proposal.APT_Contracting_Entity__c;
                    if(!String.isEmpty(proposal.Apttus_QPApprov__Approval_Status__c) && proposal.Apttus_QPApprov__Approval_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_APPROVED)) {
                        agreement.APT_Pricing_Category__c = APT_Constants.AGREEMENT_CATEGORY_CUSTOMISED;
                    }
                }
                system.debug('-->' + apms);
                if(apms !=null && APT_Constants.RECORD_TYPE_SECURE_PAY_ONLINE_PAYMENTS.equalsIgnoreCase(Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(agreement.recordtypeid).getname()))
                {
                    agreement.APMS_Application__c = apms.id;
                    //APT_Settlement_Profile_days__c = SettlementProfile__c
                    //APT_Price_Plan__c = PricingPlan__r.PricingPlanDesc__c
                    agreement.APT_Settlement_Profile_days__c = getSettlementProfile(apms.SettlementProfile__c);
                    agreement.APT_Price_Plan__c = getPricingPlan(apms.PricingPlan__r.PricingPlanDesc__c);
                }
            }
        } catch(Exception e){
            system.debug('Exception type caught: ' + e.getTypeName());
            system.debug('Line number: ' + e.getLineNumber());
            system.debug('Stack trace: ' + e.getStackTraceString());

            // return e.getMessage();
            return e.getStackTraceString();
        }

        return APT_Constants.SUCCESS_LABEL;
    }
    
     /* Shashwat.Nath@auspost.com.au has added the below method on 21/09/2020 as part of STP-Release 2 , to supersede the original Opportunity
       when DOV is done on the Contract . A new Checkbox is being introduced to record Opportunity Superceding */
    public static void supersedeOriginalOpportunity(Set<Id> opportunityIdSet){
    try{
        List<Opportunity> opportunityListToBeUpdated = new List<Opportunity>();
        // Iterate on list of DOV Opportunities to get the original opportunity and update the Supersede Checkbox on Original Opportunity
        for(Opportunity opportunityRec : [SELECT id , ECLM_Original_Opportunity_No__c ,ECLM_Original_Opportunity_No__r.Is_Superseded_Opportunity__c  from Opportunity WHERE ID IN: opportunityIdSet AND 
                                           Opportunity_SubType__c ='DoV Increase']){
            
            //Only supersede the Original Opportunity if its not already supersesed.
            If(opportunityRec.ECLM_Original_Opportunity_No__c !=null && !opportunityRec.ECLM_Original_Opportunity_No__r.Is_Superseded_Opportunity__c){
                opportunity oppToBeSuperseded = new Opportunity();
                oppToBeSuperseded.id = opportunityRec.ECLM_Original_Opportunity_No__c;
                oppToBeSuperseded.Is_Superseded_Opportunity__c = True;
                opportunityListToBeUpdated.add(oppToBeSuperseded);
            }
        }
        
        // Update the List of Opportunities to be Superseded
        update opportunityListToBeUpdated;
        
        }
        catch(Exception ex) {
             UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'APT_AgreementTriggerHandler' , 'supersedeOriginalOpportunity', 'APT_AgreementTrigger ', LoggingLevel.ERROR);
        }         
    }
    
    /**
    Method for retrieve get Settlement Profile
   **/
    @TestVisible private static Integer getSettlementProfile(String settlementProfile) {
        Integer settlementProfileValue = 0;

        if(String.isBlank(settlementProfile)){
            settlementProfileValue = 0;
        } else if((APT_Constants.SETTLEMENT_PROFILE_5).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 5;
        } else if((APT_Constants.SETTLEMENT_PROFILE_7).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 7;
        } else if((APT_Constants.SETTLEMENT_PROFILE_14).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 14;
        } else if((APT_Constants.SETTLEMENT_PROFILE_15).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 15;
        } else if((APT_Constants.SETTLEMENT_PROFILE_28).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 28;
        } else if((APT_Constants.SETTLEMENT_PROFILE_30).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 30;
        } else if((APT_Constants.SETTLEMENT_PROFILE_45).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 45;
        } else if((APT_Constants.SETTLEMENT_PROFILE_60).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 60;
        } else if((APT_Constants.SETTLEMENT_PROFILE_90).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 90;
        } else if((APT_Constants.SETTLEMENT_PROFILE_120).equalsIgnoreCase(settlementProfile)){
            settlementProfileValue = 120;
        } else {

        }
        return settlementProfileValue;
    }
    /**
     Method for retrieve Pricing Plan
    **/
    @TestVisible private static string getPricingPlan(String pricingPlan) {

        String pricingPlanVal = APT_Constants.PRICING_PLAN_2_4;
        if(String.isBlank(pricingPlan)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_2_4;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_1_2)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_1_2;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_1_3)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_1_3;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_1_4)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_1_4;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_1_5)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_1_5;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_1_6)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_1_6;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_1_7)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_1_7;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_1_8)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_1_8;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_1_9)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_1_9;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_2_0)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_2_0;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_2_1)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_2_1;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_2_2)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_2_2;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_2_3)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_2_3;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_2_4)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_2_4;
        } else if(pricingPlan.contains(APT_Constants.PRICING_PLAN_3_5)){
            pricingPlanVal = APT_Constants.PRICING_PLAN_3_5;
        }

        string pricingPlanValue = pricingPlanVal + APT_Constants.SEPARATOR_PERCENT;
        return pricingPlanValue;
    }

    /**
    public static void callSubmitGenerateDocAPI(map<Id, String> mapSubmitGenDocIds, map<Id, Apttus__APTS_Agreement__c> mapAgreement) {
        system.debug('** callSubmitGenerateDocAPI **');
        if(mapSubmitGenDocIds != null) {

            list<Apttus__APTS_Agreement__c> listAgreement = [SELECT Id, Name, RecordType.DeveloperName,
                                                            Apttus__Subtype__c, APT_Contract_Type__c
                                                            FROM Apttus__APTS_Agreement__c
                                                            WHERE Id IN :mapAgreement.keySet()];
            if(listAgreement != null && listAgreement.size() > 0) {
                set<String> setRecordTypes = new set<String>();
                set<String> setSubTypes = new set<String>();
                set<String> setContractTypes = new set<String>();
                for(Apttus__APTS_Agreement__c agreement : listAgreement) {
                    setRecordTypes.add(agreement.RecordType.DeveloperName);
                    setSubTypes.add(agreement.Apttus__Subtype__c);
                    setContractTypes.add(agreement.APT_Contract_Type__c);
                }

                List<APT_R2T_Templates_Settings__c>  templateCS = [SELECT Id, Name, Compare_against_IPL__c, Template_Product_Name__c, Sequence_No__c, Template_ID__c, Default_Document_Output__c, Security_Level__c
                                                                 FROM APT_R2T_Templates_Settings__c
                                                                 WHERE Record_Type_API__c IN :setRecordTypes
                                                                       AND
                                                                       Subtype__c IN :setSubTypes
                                                                       AND
                                                                       Contract_Type__c IN :setContractTypes
                                                                       AND
                                                                       Settings_Type__c = 'Template'
                                                                 ORDER BY Sequence_No__c];

                map<Id, String> mapTemplatepLevel = new map<Id, String>();
                map<Id, String> mapTemplateDocFormat = new map<Id, String>();

                if(templateCS != null && templateCS.size() > 0) {
                    //convert template reference id to id
                    set<String> setTemplateReferences = new set<String>();
                    for(APT_R2T_Templates_Settings__c ts : templateCS) {
                        setTemplateReferences.add(ts.Template_ID__c);
                    }

                    map<String, Id> mapTemplateId = new map<String, Id>();
                    for(Apttus__APTS_Template__c template : [SELECT Id, Apttus__ReferenceId__c
                                                            FROM Apttus__APTS_Template__c
                                                            WHERE Apttus__ReferenceId__c IN :setTemplateReferences]) {

                        mapTemplateId.put(template.Apttus__ReferenceId__c, template.id);
                    }

                    for(APT_R2T_Templates_Settings__c ts : templateCS) {
                        mapTemplatepLevel.put(mapTemplateId.get(ts.Template_ID__c), ts.Security_Level__c);
                        mapTemplateDocFormat.put(mapTemplateId.get(ts.Template_ID__c), ts.Default_Document_Output__c);
                    }
                }

                map<Id, list<String>> mapTemplateIds = new map<Id, list<String>>();
                String templateIds;
                list<String> listTemplateIds = new list<String>();
                String agreementId;
                for(String aId : mapSubmitGenDocIds.keySet()) {
                    agreementId = aId;
                    templateIds = mapSubmitGenDocIds.get(aId);
                    listTemplateIds = templateIds.split(APT_Constants.SEPERATOR_COMMA);
                    mapTemplateIds.put(aId, listTemplateIds);
                }

                String sessionId = userInfo.getSessionId();
                //server url
                Apttus__ComplySystemProperties__c complySystemProperties = Apttus__ComplySystemProperties__c.getvalues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
                String serverURL = complySystemProperties.Apttus__InstanceUrl__c + '/services/Soap/u/29.0/' + UserInfo.getOrganizationId(); //Merge server URL


                //for(Id agreementId : mapTemplateIds.keySet()) {
                //    for(String templateId : mapTemplateIds.get(agreementId)) {
                //        //there should be one future call only
                //        submitGenDoc(agreementId, templateId, mapTemplatepLevel.get(templateId), mapTemplateDocFormat.get(templateId), sessionId, serverURL);
                //    }
                //}


                submitGenDoc(agreementId, templateIds, mapTemplatepLevel.get(templateIds), mapTemplateDocFormat.get(templateIds), sessionId, serverURL);
            }
        }
    }

    //@future
    private static void submitGenDoc(Id agreementId, String templateId, String pLevel, String outputFormat, String sessionId, String serverURL) {
        system.debug('** submitGenDoc **');
        if(!test.isRunningTest()) {
            Id attachmentId = Apttus.MergeWebService.submitGenerateDoc(templateId, agreementId, pLevel, outputFormat, false, sessionId, serverURL);
        }
    }
    **/
}



//**/