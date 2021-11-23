global class APT_ValidateProposalController {

    private Apttus_Proposal__Proposal__c propSO;
    public String pageSource {set;get{return ApexPages.currentPage().getParameters().get(APT_Constants.URL_SOURCE);}}
    public String propID {set;get{return ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_ID);}}
    
     public APT_ValidateProposalController() {
        
        if(null != propID && APT_Constants.EMPTY_STRING != propID) 
        {
            this.propSO = [select ID,Apttus_Proposal__Proposal_Expiration_Date__c,Apttus_Proposal__Presented_Date__c,APT_Quote_Accepted_Date__c from Apttus_Proposal__Proposal__c where ID =:propID];           
        }
        
     }
    
    public String getcheckAndRedirect()
    {   
        //1869
        //usage price tier
        map<String, Integer> mapUsagePriceTierCount = new map<String, Integer>();
        Integer iUsagePriceTierCount = 1;
        set<Id> setValidLineItemIds = new set<Id>();
        for(Apttus_Config2__UsagePriceTier__c upt : [SELECT Id, Apttus_Config2__LineItemId__c
                                                    FROM Apttus_Config2__UsagePriceTier__c 
                                                    WHERE Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c = :propSO.Id
                                                    AND Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c = :APT_Constants.CONFIGURATION_STATUS_FINALIZED]) {
            
            setValidLineItemIds.add(upt.Apttus_Config2__LineItemId__c);
            iUsagePriceTierCount = mapUsagePriceTierCount.get(upt.Apttus_Config2__LineItemId__c);
            if(iUsagePriceTierCount != null){
                iUsagePriceTierCount++;
            } else {
                iUsagePriceTierCount = 1;
            }
            mapUsagePriceTierCount.put(upt.Apttus_Config2__LineItemId__c, iUsagePriceTierCount);
        }
        system.debug('*** mapUsagePriceTierCount ***'+mapUsagePriceTierCount);
        //set<Id> setPriceListItemId = new set<Id>();
        map<Id, Apttus_Config2__LineItem__c> mapLineItem = new map<Id, Apttus_Config2__LineItem__c>();
        for(Apttus_Config2__LineItem__c li : [SELECT Id, Apttus_Config2__PriceListItemId__c, Apttus_Config2__LineNumber__c
                                                FROM Apttus_Config2__LineItem__c WHERE Id IN :setValidLineItemIds]) {
            
            //setPriceListItemId.add(li.Apttus_Config2__PriceListItemId__c);
            mapLineItem.put(li.Id, li);
        }
        system.debug('*** mapLineItem ***'+mapLineItem);
        //proposal usage price tier
        map<String, Integer> mapProposalUsagePriceTierCount = new map<String, Integer>();
        iUsagePriceTierCount = 1;
        for(Apttus_QPConfig__ProposalUsagePriceTier__c pupt : [SELECT Id, Apttus_QPConfig__LineItemId__c, Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__DerivedFromId__c
                                                    FROM Apttus_QPConfig__ProposalUsagePriceTier__c 
                                                    WHERE Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c = :propSO.Id]) {
            
            //setValidLineItemIds.add(upt.Apttus_Config2__LineItemId__c);
            iUsagePriceTierCount = mapProposalUsagePriceTierCount.get(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__DerivedFromId__c);
            if(iUsagePriceTierCount != null){
                iUsagePriceTierCount++;
            } else {
                iUsagePriceTierCount = 1;
            }
            mapProposalUsagePriceTierCount.put(pupt.Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__DerivedFromId__c, iUsagePriceTierCount);
        }
        system.debug('*** mapProposalUsagePriceTierCount ***'+mapProposalUsagePriceTierCount);
        Integer iProposalUsagePriceTierCount = 0;
        iUsagePriceTierCount = 0;
        //String errorMsg;
        for(Id liId : setValidLineItemIds) {
            if(mapUsagePriceTierCount.get(liId) != null && mapProposalUsagePriceTierCount.get(liId) != null){
                iProposalUsagePriceTierCount = mapProposalUsagePriceTierCount.get(liId);
                iUsagePriceTierCount = mapUsagePriceTierCount.get(liId);
                system.debug(iProposalUsagePriceTierCount + '***' + iUsagePriceTierCount);
                if(iUsagePriceTierCount != iProposalUsagePriceTierCount) {
                    return Label.APT_Missing_Proposal_Usage_Price_Tier_Error + APT_Constants.SEPERATOR_SPACE + mapLineItem.get(liId).Apttus_Config2__LineNumber__c;
                    /*
                    if(errorMsg != null && String.isNotBlank(errorMsg)){
                        errorMsg += '\n' + Label.APT_Missing_Proposal_Usage_Price_Tier_Error + APT_Constants.SEPERATOR_SPACE + mapLineItem.get(liId).Apttus_Config2__LineNumber__c;
                    } else {
                        errorMsg = Label.APT_Missing_Proposal_Usage_Price_Tier_Error + APT_Constants.SEPERATOR_SPACE + mapLineItem.get(liId).Apttus_Config2__LineNumber__c;
                    }
                    */
                }
            } else if(mapUsagePriceTierCount.get(liId) != null && mapProposalUsagePriceTierCount.get(liId) == null) {
                return Label.APT_Missing_Proposal_Usage_Price_Tier_Error + APT_Constants.SEPERATOR_SPACE + mapLineItem.get(liId).Apttus_Config2__LineNumber__c;
            } else {}
        }
        
        /*
        if(errorMsg != null && String.isNotBlank(errorMsg)){
            return errorMsg;
        }
        */
        
        /**
        list<Apttus_Config2__UsagePriceTier__c> listUsagePriceTier = new list<Apttus_Config2__UsagePriceTier__c>();
        listUsagePriceTier = ;


        list<Apttus_QPConfig__ProposalUsagePriceTier__c> listProposalUsagePriceTier = new list<Apttus_QPConfig__ProposalUsagePriceTier__c>();
        listProposalUsagePriceTier = [SELECT Id
                                    FROM Apttus_QPConfig__ProposalUsagePriceTier__c
                                    WHERE Apttus_QPConfig__LineItemId__r.Apttus_QPConfig__ConfigurationId__r.Apttus_QPConfig__Proposald__c = :propSO.Id];

        
        if(listUsagePriceTier.size() != listProposalUsagePriceTier.size()) {
            return Label.APT_Missing_Proposal_Usage_Price_Tier_Error;
        }
        **/
        //1869
        
        if(null != propSO && null != propSO.Apttus_Proposal__Proposal_Expiration_Date__c && APT_Constants.URL_PRESENT_PROPOSAL  == pageSource && propSO.Apttus_Proposal__Proposal_Expiration_Date__c < System.Today())
        {
            return APT_Constants.ERROR_MESSAGE_CANNOT_PRESENT_PROPOSAL;
        }
        else if(null != propSO && null != propSO.Apttus_Proposal__Proposal_Expiration_Date__c && APT_Constants.URL_ACCEPT_PROPOSAL  == pageSource && propSO.Apttus_Proposal__Proposal_Expiration_Date__c < System.Today())
        {
            return APT_Constants.ERROR_MESSAGE_CANNOT_ACCEPT_PROPOSAL;
        }
        else if(null != propSO && null != propSO.Apttus_Proposal__Proposal_Expiration_Date__c && propSO.Apttus_Proposal__Proposal_Expiration_Date__c >= System.Today())
        {
            return APT_Constants.SUCCESS_LABEL_SMALL ;
        }
        else    
        {
            return APT_Constants.ERROR_MESSAGE_MALFORMED_URL ;
        }
    }
}