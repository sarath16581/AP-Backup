/**
 @description:  This controller class is used for linking PSR and apply appropriate business rule if PSR requires standard delegated pricing or custom pricing.
            Delegated pricing is using existing pricing in apttus while custom pricing require making an API call to retrieve rate from COMPASS pricing tool. 
 @author Seth Heang & Nasir Jawed
 @date 2022-04-01
 @changelog: 
 2022-04-01 - Seth Heang - Created
2022-05-05 - Nasir Jawed - Modified for CI-134 for Delegate Pricing
**/
public with sharing class APT_CompassPricingController {
    public String lineItemId {get; set;}
    public String configId {get; set;}
    public String opportunityId {get; set;}

    public String parentPageURL{get;set;}
    
    public APT_CompassPricingController(){
        // get parameters from VF Page
        lineItemId = apexpages.currentPage().getParameters().get('selectedRecordID');
        configId = apexpages.currentPage().getParameters().get('configId');
        opportunityId = apexpages.currentPage().getParameters().get('opportunityId');


        //BRP temp
        String hostURL = String.valueof(URL.getSalesforceBaseUrl().toExternalForm());
        hostURL += '/apex/Apttus_Config2__Cart?configRequestId=' + configId + '&id=' + configId + '#/cart';

        parentPageURL = hostURL;


    }

    public String compassPricingAttributes {
        get {
            // build attributes map pf VF paramters to pass into LWC 
            Map<String, Object> componentAttributes = new Map<String, Object> {
                'lineitemId' => lineItemId,
                'configId' => configId,
                'opportunityId' => opportunityId
            };
            return JSON.serialize(componentAttributes);
        }
        private set;
    }

    /**
     * This method retrieve APPC PSR provided all valid criteria is met and return the list of PSR back to the LWC.
     * It is linked to Wire Method in LWC to populate the PSR table in LWC on page load
     * @param String oppId
     * @return List<Deal_Support_Request__c>
     */
    @AuraEnabled(cacheable=true)
    public static List<SObject> getPSRList(String oppID){
        
        List<Deal_Support_Request__c> completedPSRList = new List<Deal_Support_Request__c>();
        List<Deal_Support_Request__c> psrList = new List<Deal_Support_Request__c>();
        AuraHandledException exceptionHandler;
        try{
            // retrieve PSR APPC record type Id
            Id psrAPPCRecTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{APT_Constants.PSR_APPC_RECORD_TYPE_APINAME}).values()[0].Id;
            /**
             * Query PSR based on following criteria:
             * -Quote’s Opportunity should be equal to the Deal Support Request’s Opportunity
             * -PSR stage and status is Completed and Completed respectively.
             * -Record type of DSR should be “Pricing Support Request - Australia Post Parcel Contract” and PSR.Product = ‘Australia Post Parcel Contract’
             */
            Map<String, Object> searchParams = new Map<String, Object>();
            searchParams.put('opportunityIds', new Set<Id>{oppID});
            searchParams.put('recTypeIds', new Set<Id>{psrAPPCRecTypeId});
            searchParams.put('productNames', new Set<String>{APT_Constants.PSR_APPC_PRODUCT_NAME});
            //psrList = DealSupportRequestsSelector.newInstance().search(searchParams, new Set<Object>(), true);
            psrList = DealSupportRequestsSelector.newInstance().search(searchParams, new Set<Object>{DealSupportRequestsSelector.Options.WITH_ORGANISATION}, true);

            // validate if there is no PSR raised and display error message
            if(psrList.size() == 0){
                exceptionHandler = new AuraHandledException(System.Label.APT_NoAPPCPSR);
                exceptionHandler.setMessage(System.Label.APT_NoAPPCPSR);
                throw exceptionHandler;
            }
            List<SObject> psrSObject = new List<SObject>();
            psrSObject.addAll(psrList);
            return psrSObject;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * This method return the ID of the temporary configuration object used by Apttus shopping cart to temporarily store product information in one session.
     * It is linked to Wire Method in LWC to fetch the temporary configuration object ID on page load
     * @param String configId
     * @return Apttus_Config2__TempObject__c.Id
     */
    @AuraEnabled(cacheable=true)
    public static Id fetchConfigRequestId(String configId){
        try {
            // fetch the temporary configuration object ID based on Apttus config Id
            Id configRequestRecId = APT_ConfigTempObjectsSelector.newInstance(1).selectByConfigId(new Set<Id>{configId})[0].Id;
            return configRequestRecId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * This method is used to link the PSR to the current proposal.
     * It validates APPC product's config details and PSR details to determine if standard delegated pricing is satisfactory or a custom rate from COMPASS is required.
     *  -Delegated Pricing: recalculate the apttus cart with existing apttus rate
     *  -Customised Pricing: make an external callout to COMPASS to get custom rate
     * @param SObject objDSR
     * @param String configId
     * @param String selectedLineItemId
     * @return String for Success Message
     */
    @AuraEnabled
    public static String onApply(SObject objDSR, string configId, string selectedLineItemId){
        ID conID=(String) configId;
        List<Apttus_Config2__ProductAttributeValue__c> pavRec;
        AuraHandledException exceptionHandler;
        Deal_Support_Request__c selectedPSR = (Deal_Support_Request__c) objDSR;         
        
        
      try{
            // fetch product attribute value and its neccessary fields' values for validation purposes
            pavRec = APT_ProductAttributeValuesSelector.newInstance().selectByLineItemId(new Set<Id>{selectedLineItemId});
            
            // check if validity end date has passed in PSR and display error message
            if(selectedPSR.Quote_Validity_End_Date__c < Date.today()){
                exceptionHandler = new AuraHandledException(System.Label.APT_ExpiredQuoteValidityEndDate);
                exceptionHandler.setMessage(System.Label.APT_ExpiredQuoteValidityEndDate);
                throw exceptionHandler;
            }

            // validate if selected PSR record’s Lodgement Zone does not match with cart’s Selected Lodgement Zone, Additional Lodgement Zone 1 and Additional Lodgement Zone 2
            if((pavRec[0].APT_Selected_Lodgement_Zone__c != null) && (selectedPSR.Approved_lodgement_zone__c != null) && (!selectedPSR.Approved_lodgement_zone__c.contains(pavRec[0].APT_Selected_Lodgement_Zone__c))
                || (pavRec[0].APT_Additional_Lodgement_Zone_1__c != null && (selectedPSR.Approved_lodgement_zone__c != null) && !selectedPSR.Approved_lodgement_zone__c.contains(pavRec[0]?.APT_Additional_Lodgement_Zone_1__c))
                || (pavRec[0].APT_Additional_Lodgement_Zone_2__c != null && (selectedPSR.Approved_lodgement_zone__c != null) && !selectedPSR.Approved_lodgement_zone__c.contains(pavRec[0]?.APT_Additional_Lodgement_Zone_2__c))){
                exceptionHandler = new AuraHandledException(System.Label.APT_MismatchedLodgementZone);
                exceptionHandler.setMessage(System.Label.APT_MismatchedLodgementZone);
                throw exceptionHandler;
            }
           
            System.debug('BRP: OnApply() L 143');

            // Standard delegated pricing is required
            if(selectedPSR.Approved_Event__c == APT_Constants.PSR_APPC_STANDARD_DELEGATED_PRICING) {
                updateProdConfigAndPricingForCart(conID,selectedPSR);               
            }              

            return System.Label.APT_LinkPSRSuccess;
        }
         catch(Exception e){
           System.debug('BRP: OnApply() Exception L 157 = ' + e);
          throw new AuraHandledException(e.getMessage());
        }
    }

    
    

    
    

    /**
     * This method updates the shopping cart configuration record and recalculate the Apttus product pricing in the shopping cart.
     * @param String quoteConfigurationId, DSR object
     * @return void
     */     
    private static void updateProdConfigAndPricingForCart(ID quoteConfigurationId,Deal_Support_Request__c selectedPSR ) {
                  
            List<Apttus_Config2__LineItem__c> lineItemList;            
            List<ID> pavList= new List<ID>();
            List<Apttus_Config2__ProductAttributeValue__c> pavListQuery;            
            List<Apttus_Proposal__Proposal__c > proposalListUpdate= new List<Apttus_Proposal__Proposal__c >();
            List<Apttus_Proposal__Proposal__c> currentProposal;
            List<Apttus_Config2__ProductConfiguration__c> productConfig;           
            List<Apttus_Config2__LineItem__c> lineItemToUpdate = new List<Apttus_Config2__LineItem__c>();           
            boolean constraintRuleResult;
            
            
            //fetch all the lineitem by using configurationID
                    
            lineItemList = LineItemsSelector.newInstance().selectByProdConfId(new set<ID>{(ID)quoteConfigurationId});
            system.debug('lineItemList :'+ lineItemList );
            for(Apttus_Config2__LineItem__c li:lineItemList ){                             
                pavList.add(li.Apttus_Config2__AttributeValueId__c);                               
            }            

            //Fetch all the Product Attribute value records and update all the records with Tier and Price structure
            if(pavList != null && pavList.size() > 0 ){
                pavListQuery = APT_ProductAttributeValuesSelector.newInstance().selectByPavID(pavList);                
                system.debug('pavListQuery :'+ pavListQuery.size());
                UpdateProductAttributeValues(pavListQuery,selectedPSR, quoteConfigurationId);               
                  
                constraintRuleResult = applyConstraintRules(quoteConfigurationId);  
                System.debug('constraintRuleResult:' + constraintRuleResult);                             
                              
            }  
           
            if(constraintRuleResult == false ){
                Boolean isPricePending;                                  
                isPricePending = updatePriceForCart(quoteConfigurationId); 
                system.debug('isPricePending:'+ isPricePending);              
                if(isPricePending == false ){                            
                    
                    if(quoteConfigurationId!=null){
                        productConfig=ProductConfigurationSelector.newInstance().selectByConfigId(new set<ID>{(ID)quoteConfigurationId});
                    }
                    //getting the current proposal record
                    if(productConfig != null){
                        id proposalID = productConfig[0].Apttus_QPConfig__Proposald__c; 
                        system.debug('proposalID:'+ proposalID);  
                        currentProposal=APT_ProposalObjectsSelector.newInstance().selectByConfigIds(new set<ID>{(ID)proposalID});
                    }                    
                    //updating the proposal record for the field expiry date from the salected DSR
                    if(currentProposal!=null){
                        system.debug('currentProposal:'+ currentProposal[0]); 
                        currentProposal[0].Apttus_Proposal__Proposal_Expiration_Date__c=selectedPSR.Quote_Validity_End_Date__c;
                        proposalListUpdate.add(currentProposal[0]);
                        ApplicationDatabase.getInstance().dmlUpdate(proposalListUpdate);
                    }               
                }
            }        
    } 
    
    /* This method updated the Product Attribute value records with the DSR records when it is delegate pricing 
     * Param : List of Product Attribute value, DSR record and configuration id
     */
    public static void UpdateProductAttributeValues(List<Apttus_Config2__ProductAttributeValue__c> productAttributeValuesListToUpdate,Deal_Support_Request__c selectedPSR,Id quoteConfigurationId){
        List<Apttus_Config2__ProductAttributeValue__c> pavListUpdate= new List<Apttus_Config2__ProductAttributeValue__c>();
        Boolean liUpdateRequired = false; 
             
        // updating all the product Attribute values for the proposal
        for(Apttus_Config2__ProductAttributeValue__c pav: productAttributeValuesListToUpdate){
            
            if(pav.APT_Customer_Tier__c == selectedPSR.Approved_Tier__c && liUpdateRequired == false)
            {
                liUpdateRequired = true;              
            }

            pav.APT_Customer_Tier__c = selectedPSR.Approved_Tier__c;   
            pav.Applied_PSR__c =  selectedPSR.id;  
            system.debug('pav.Applied_PSR__c:'+pav.Applied_PSR__c + 'PSRID'+ selectedPSR.id);
            pav.APTS_Price_Structure__c =  selectedPSR.Approved_Pricing_Structure__c;
            pav.APT_RK_Code_AppliedYN__c=APT_Constants.OPTION_YES;           
            pavListUpdate.add(pav);
            system.debug('pavListUpdate:'+pavListUpdate);
        }
        
        if(pavListUpdate.size() > 0){            
            ApplicationDatabase.getInstance().dmlUpdate(pavListUpdate);
        }  
        
        if(liUpdateRequired &&  quoteConfigurationId != null) {            
            List<Apttus_Config2__LineItem__c> liListUpdate= new List<Apttus_Config2__LineItem__c>();
            List<Apttus_Config2__LineItem__c> liList  = LineItemsSelector.newInstance().selectByProdConfId(new set<ID>{(ID)quoteConfigurationId});
            for( Apttus_Config2__LineItem__c li : liList)
            {
                li.Apttus_Config2__PricingStatus__c = 'Pending';
                liListUpdate.add(li); 
            }
            if(liListUpdate.size() > 0){            
                ApplicationDatabase.getInstance().dmlUpdate(liListUpdate);
            } 
           
        }
    
    }
    /* This method does the repricing of the Cart
     * param : product Configuration ID
     */
    public static boolean updatePriceForCart(ID quoteConfigurationId) {
        boolean isPricePendingCheck;
        Apttus_Config2__ProductConfiguration__c  updateConfig = new Apttus_Config2__ProductConfiguration__c();
        updateConfig.Id = quoteConfigurationId;
        //updateConfig.Apttus_Config2__Status__c = 'Saved'; //to save the respected cart from backend
        updateConfig.Apttus_Config2__IsPricePending__c = true;  
        ApplicationDatabase.getInstance().dmlUpdate(new List<Apttus_Config2__ProductConfiguration__c>{updateConfig});
        
        // Apttus webservice method to reprice the cart
        if(!Test.isRunningTest()){            
            Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
            objUpdatePriceRequestDO.CartId = quoteConfigurationId;
            Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
            IsPricePendingCheck= result.IsPricePending;           
        }else{            
            IsPricePendingCheck= false;    
        }      
        return IsPricePendingCheck;
    }

    /**
     * Back button navigates back to cart summary page of the shopping cart
     * Reason for this solution is due to Salesforce technical Limitation: 
     *  1.PageReference and lighting/navigation service library are not supported in Lightning out framework
     *  2.Javascript native navigation functions(e.g. history.back() and Location.href()) does not work correctly in Apttus shopping cart's lightning experience
     * Solution: VF page action:function to call apex method directly to return PageReference object and perform navigation
     * @return PageReference
     */
    public static PageReference goBack(){ 
        // navigate to the url paramter, passed in from the VF page
        string backURL = Apexpages.currentPage().getParameters().get('url');
        return new PageReference(backURL);
    }
    
    /* This method calls the constraint rule when the repricing is done after the delegate or custom pricing is completed
     * param : product Configuration ID
     */
    public static boolean applyConstraintRules(ID quoteConfigurationId) {
        List<Integer> primaryLines = new List<Integer>();
        Boolean returnReuslt = false;
        if(!Test.isRunningTest()){
            Apttus_CPQApi.CPQWebService.associateConstraintRules(quoteConfigurationId, primaryLines);
            Apttus_CPQApi.CPQWebService.applyConstraintRules(quoteConfigurationId, false);    
    
            Apttus_CPQApi.CPQ.ConstraintResultDO constraintResult = Apttus_CPQApi.CPQWebService.getConstraintRuleResult(quoteConfigurationId);
            if(constraintResult.NeedMoreProcessing)
            {
                Apttus_CPQApi.CPQWebService.associateConstraintRules(quoteConfigurationId, primaryLines);
                Apttus_CPQApi.CPQWebService.applyConstraintRules(quoteConfigurationId, false);    
            }
            returnReuslt = constraintResult.HasPendingError;
            return returnReuslt;
        }
        return returnReuslt;
    } 
   
}