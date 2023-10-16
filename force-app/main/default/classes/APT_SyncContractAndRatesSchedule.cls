/**
Schedule Sync Contract and Rates Batch.
Created By - Mausam Padhiyar
Created Date - 2nd Feb, 2016

Last Modified By - Mausam Padhiyar
Last Modified Date - 26th Aug, 2016 | Multi Product SAP Implementation

Last Modified By - Seth Heang
Last Modified Date - 08th Mar, 2020 | Update SOQL criteria for Agreement to exclude agreement without related Opportunities and related Proposals, 
										and apply only for eParcel/Express and International products
13, Sep,2023: Bharat Patel - Update proposal filter condition, to consider APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC proposal

**********************************************************************************************************
How to execute?
system.schedule('Sync Contract and Rates Job', '0 32 16 4 2 ?', new APT_SyncContractAndRatesSchedule());
system.schedule('Sync Contract and Rates Job',  '0 59 * * * ?', new APT_SyncContractAndRatesSchedule());
system.schedule('Sync Contract and Rates Job',  '0 30 * * * ?', new APT_SyncContractAndRatesSchedule());
**********************************************************************************************************
**/
global class APT_SyncContractAndRatesSchedule implements Schedulable {
  /**
    Execute 
   */
    global void execute(SchedulableContext SC) {
        
        set<Id> setAgreementId = new set<Id>();
        set<Id> setOpportunityId = new set<Id>();
        map<Id, Id> mapAgreementByOpportunity = new map<Id, Id>();
        for(Apttus__APTS_Agreement__c agreement : [SELECT Id, Name, Apttus__Related_Opportunity__c,
                            Apttus_QPComply__RelatedProposalId__c
                                                  FROM Apttus__APTS_Agreement__c                                                  
                                                  WHERE Apttus__Related_Opportunity__c != null
                                                  AND Apttus_QPComply__RelatedProposalId__c != null
                                                   AND APT_New_Rate_Card_Download__c = false
                                                  AND Apttus__Status_Category__c = :APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_SIGNATURES
                                                  AND Apttus__Status__c = :APT_Constants.AGREEMENT_STATUS_SFDC_CASE_CREATED
                                                  AND APT_New_Rate_Card_Download__c = false
                                                  AND APT_Rollup_Product_Names__c != :APT_Constants.POSTAL_SERVICES
                                                  ]) {
          
            setAgreementId.add(agreement.Id);
            setOpportunityId.add(agreement.Apttus__Related_Opportunity__c);
            mapAgreementByOpportunity.put(agreement.Apttus__Related_Opportunity__c, agreement.Id);
        }
      
        if(setOpportunityId.size() > 0){
            //APT_SyncContractAndRatesBatch batchController = new APT_SyncContractAndRatesBatch(setAgreementId);
            //Database.executeBatch(batchController, 1);
            set<Id> setProposalId = new set<Id>();
            map<Id, Id> mapAgreementByProposal = new map<Id, Id>();
            for(Apttus_Proposal__Proposal__c proposal : [SELECT Id, Name, Apttus_Proposal__Opportunity__c,
                                                        Apttus_Proposal__Approval_Stage__c, 
                                                        Apttus_Proposal__Presented_Date__c,
                                                        Apttus_Proposal__Opportunity__r.KeyContact__c,
                                                        Owner.Id,
                                                        APT_Method_of_Payment__c
                                                        FROM Apttus_Proposal__Proposal__c
                                                        WHERE Apttus_Proposal__Opportunity__c IN :setOpportunityId
                                                        AND (Apttus_Proposal__Approval_Stage__c = :APT_Constants.QUOTE_TYPE_DRAFT
                                                        OR Apttus_Proposal__Approval_Stage__c = :APT_Constants.APPROVAL_STAGE_ACCEPTED
                                                        OR Apttus_Proposal__Approval_Stage__c = :APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC)
                                                        ORDER BY Apttus_Proposal__Presented_Date__c]) {
              
              setProposalId.add(proposal.Id);
              Id agreementId = mapAgreementByOpportunity.get(proposal.Apttus_Proposal__Opportunity__c);
              mapAgreementByProposal.put(proposal.Id, agreementId);
            }
            
            
            if(setProposalId != null && setProposalId.size() > 0) {
              set<Id> setPLIId = new set<Id>();
              map<Id,Id> mapAgreementByPLI = new map<Id, Id>();
              map<String, Apttus_Proposal__Proposal_Line_Item__c> mapPrimaryPLI = new map<String, Apttus_Proposal__Proposal_Line_Item__c>();
              for(Apttus_Proposal__Proposal_Line_Item__c pli: [SELECT Id, Name, APT_Charge_Code_Formula__c,
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
                                WHERE Apttus_Proposal__Proposal__c IN :setProposalId]) {
                
                
                setPLIId.add(pli.Id);
                Id agreementId = mapAgreementByProposal.get(pli.Apttus_Proposal__Proposal__c);
                mapAgreementByPLI.put(pli.Id, agreementId);
                
                if(false == (pli.Apttus_QPConfig__ParentBundleNumber__c != null) && pli.Apttus_QPConfig__IsPrimaryLine__c) {
                        mapPrimaryPLI.put(pli.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_QPConfig__PrimaryLineNumber__c, pli);
                    }
              }
              
              if(setPLIId != null && setPLIId.size() > 0) {
                set<String> setProposalLineItemId = new set<String>();
                for(Apttus_QPConfig__ProposalUsagePriceTier__c pupt : [SELECT Id, Apttus_QPConfig__LineItemId__c
                                            FROM Apttus_QPConfig__ProposalUsagePriceTier__c
                                            WHERE Apttus_QPConfig__LineItemId__c IN :setPLIId]) {
                  setProposalLineItemId.add(pupt.Apttus_QPConfig__LineItemId__c);
                }
                system.debug('*** setProposalLineItemId ***'+setProposalLineItemId);
                    system.debug('*** setAgreementId ***'+setAgreementId);
                    system.debug('*** mapPrimaryPLI ***'+mapPrimaryPLI);
                    system.debug('*** mapAgreementByPLI ***'+mapAgreementByPLI);
                //call batch to create SAP Rates 
                APT_CreateSAPRatesBatch controller = new APT_CreateSAPRatesBatch(setProposalLineItemId, setAgreementId, mapAgreementByPLI, mapPrimaryPLI);
                database.executeBatch(controller, 1);
              }              
            }
        }      
   }
   }