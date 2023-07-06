/***
 * @author Darshan Chauhan
 * @date 2021-05-25
 * @group 
 * @description Test class consisting of methods for tier adjustments.
 * @changelog
 * 2021-05-25 - Darshan Chauhan - Created
 * 2021-09-27 - Madhuri Awasthi : REQ2594537 (Allow StarTrack Standard Delegation Approval Process for Intermediaries for Price Adjustment)
 * Ken McGuire 2023.04.19 Proposal field migration to opportunity
*/
public with sharing class APT_PricingAdjustmentController {
    /**
     * This method apply adjustment to the propsal and return back to the cart
     * @param - configurationId - it refers to the cart id / configuration record id
     * @param - businessObjectId - it refers to the proposal id
     * @param - flow - it refers to what type of configuration record is
     * @param - configRequestId - it refers to the tempObject id
     */
    @AuraEnabled
    public Static Map<String, String> onApply(String configurationId, String businessObjectId, String flow, string configRequestId){        
        try {
            Apttus_Config2__ProductConfiguration__c prodConfig = new Apttus_Config2__ProductConfiguration__c(); // Product Configuration Record
            String instanceURL = '';// Salesforce Base URL
            Map<String, String> outputMap = new Map<String, String>();
            instanceURL = URL.getSalesforceBaseUrl().toExternalForm();

            String finalURL;
            prodConfig = [SELECT Id, Apttus_Config2__Status__c,Apttus_QPConfig__Proposald__c,Apttus_QPConfig__Proposald__r.Name,
                         Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c, Apttus_QPConfig__Proposald__r.Apttus_Proposal__Proposal_Name__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Approval_Stage__c 
                         FROM Apttus_Config2__ProductConfiguration__c 
                         WHERE Id = :configurationId];
            
            if(prodConfig != null){
                if(prodConfig.Apttus_Config2__Status__c != APT_Constants.URL_SAVED ){
                    prodConfig.Apttus_Config2__Status__c = APT_Constants.URL_SAVED;                    
                    // update prodConfig;     
                }
                //Apttus_Config2.FieldExpressionWebService.attachApplicableExpressionsOnAdd(configurationId, NULL);
                // Apttus_Config2.FieldExpressionWebService fieldExpressionRequest = new Apttus_Config2.FieldExpressionWebService();
                // fieldExpressionRequest.attachApplicableExpressionsOnAdd(configurationId, null);
                prodConfig.Apttus_Config2__IsPricePending__c = true;
                update prodConfig;

                Apttus_Proposal__Proposal__c proposalObj =[Select id, Apttus_Proposal__Opportunity__r.IsStartrackProposal__c,APT_Tier_Adjustment_Type__c, APT_Pricing_Request_Type__c, 
                                                                APT_Tier_Adjustment_Justification__c, APT_Customer_Background__c, APT_Intermediary__c, APT_Conversation__c, 
                                                                APT_Name_of_Intermediary_s_Client__c  From Apttus_Proposal__Proposal__c 
                                                                where id = :prodConfig.Apttus_QPConfig__Proposald__c LIMIT 1 ]; //

                // List<Apttus_Config2__LineItem__c> lineItems = [Select Id, Apttus_Config2__LineType__c,APT_StarTrack_Proposal__c,
                //                                     APT_Approval_Required_ST__c from Apttus_Config2__LineItem__c Where Apttus_Config2__ConfigurationId__c =:configurationId ];
                // Apttus_Config2.CPQStruct.UpdateLineItemRequestDO request = new Apttus_Config2.CPQStruct.UpdateLineItemRequestDO();
                // Apttus_Config2.CartService.updateLineItems(request);

                // Apttus_Config2.CustomClass.ValidationResult validationResult = Apttus_Config2.CPQWebService.validateCart(configurationId);

                if( proposalObj != null && String.isNotBlank(proposalObj.Apttus_Proposal__Opportunity__r.IsStartrackProposal__c) && (proposalObj.Apttus_Proposal__Opportunity__r.IsStartrackProposal__c).equalsIgnoreCase('Yes')
                    && String.isNotBlank(proposalObj.APT_Tier_Adjustment_Type__c ) ){
                    set<Id> productId = new set<Id>();
                    // if(String.isNotBlank(proposalObj.APT_Tier_Adjustment_Type__c) ){
                        
                        //List<Revenue_by_Billing_Account__c> revenueBillingAccList = new List<Revenue_by_Billing_Account__c>();
                        List<AggregateResult> revenueBillingAccList = new List<AggregateResult>();
                        if(prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c != null){
                            // revenueBillingAccList = [SELECT Id, Customer__c, Product__c from Revenue_by_Billing_Account__c 
                            //WHERE Customer__c =: prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c];
                             
                            //Adding Customer__r.Sales_Segment__c to check the sales team
                            revenueBillingAccList = [select Customer__r.Sales_Segment__c,MAX(APT_Last_Rev_Realized__c) LastRev,Product__c product from Revenue_by_Billing_Account__c
                                                        WHERE Customer__c =: prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c GROUP BY Customer__r.Sales_Segment__c,Product__c];
    
                            if(!revenueBillingAccList.isEmpty() && revenueBillingAccList.size() > 0){
                                //logic for checkign cart products
                                List<Apttus_Config2__LineItem__c> allLineItems = [SELECT Id, Apttus_Config2__ProductId__c, APT_StarTrack_Proposal__c, APT_Approval_Required_ST__c, 
                                                                                  Apttus_CQApprov__Approval_Status__c, Apttus_Config2__LineType__c
                                                                                  FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =: configurationId];
                                
                                Boolean isError = false;
                                for(Apttus_Config2__LineItem__c lineItem : allLineItems){
                                    productId.add(lineItem.Apttus_Config2__ProductId__c);
                                }                               
                                for(AggregateResult rba : revenueBillingAccList ){
                                    system.debug('rba** '+rba);                                          
                                    system.debug('Check Sales>>'+rba.get('Sales_Segment__c'));                            
                                    if(productId.contains(String.valueOf(rba.get('product')))){
                                        if(rba.get('Sales_Segment__c') == 'Intermediaries' || rba.get('Sales_Segment__c') == 'Intermediaries - Not Active'){
                                            isError = false;
                                        }  
                                        else {
                                            Date revRealizedDate = (Date)rba.get('LastRev');
                                            system.debug('days between ** '+revRealizedDate.daysBetween(system.today()));
                                            if(revRealizedDate.daysBetween(system.today()) < 365)
                                                isError = true;
                                        }     
                                    }   
                                }
                                if(isError){
                                    outputMap.put('isError','true');
                                    outputMap.put('errorMsg','This opportunity is not for New Business/Cross Sell/Winback. To make a request for custom pricing, raise a Deal Support Request (DSR)');
                                } else{
                                    outputMap.put('isError','false');
                                    outputMap.put('errorMsg','');

                                    Apttus_Config2.FieldExpressionWebService.attachApplicableExpressionsOnAdd(configurationId, NULL);                


                                    List<Apttus_Config2__LineItem__c> allLineItems1 = [SELECT Id, Apttus_Config2__ProductId__c, APT_StarTrack_Proposal__c, APT_Approval_Required_ST__c, 
                                                                                  Apttus_CQApprov__Approval_Status__c, Apttus_Config2__LineType__c
                                                                                  FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =: configurationId];
                                                                                                                      
                                    
                                    if(!allLineItems1.isEmpty()){
                                        for( Apttus_Config2__LineItem__c lineItemObj : allLineItems1 ){
                                            if(lineItemObj.APT_StarTrack_Proposal__c 
                                                && lineItemObj.APT_Approval_Required_ST__c 
                                                && lineItemObj.Apttus_Config2__LineType__c.equalsIgnoreCase(APT_Constants.LINE_TYPE_PRODUCT_SERVICE)  ){
                                                lineItemObj.Apttus_CQApprov__Approval_Status__c = APT_Constants.LABEL_APPROVAL_REQUIRED;
                                            }
                                        }
                                        update allLineItems1;
                                    }

                                    if(callRePrice(configurationId)){
                                        callRePrice(configurationId);
                                    }
                                    
                                    finalURL = instanceURL;
                                    finalURL += '/apex/Apttus_Config2__Cart?cartStatus=New'+'&configRequestId='+configRequestId+'&flow='+flow+'&id='+configurationId+'&launchState=cart&oldConfigId='+configRequestId+'#!/cartgrid';

                                    outputMap.put('finalURL',finalURL);
                                }
                                
                            } else {

                                Apttus_Config2.FieldExpressionWebService.attachApplicableExpressionsOnAdd(configurationId, NULL);                

                                
                                List<Apttus_Config2__LineItem__c> allLineItems = [SELECT Id, Apttus_Config2__ProductId__c, APT_StarTrack_Proposal__c, APT_Approval_Required_ST__c, 
                                                                                  Apttus_CQApprov__Approval_Status__c, Apttus_Config2__LineType__c
                                                                                  FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =: configurationId];
                                if(!allLineItems.isEmpty()){
                                    for( Apttus_Config2__LineItem__c lineItemObj : allLineItems ){
                                        if(lineItemObj.APT_StarTrack_Proposal__c 
                                            && lineItemObj.APT_Approval_Required_ST__c 
                                            && lineItemObj.Apttus_Config2__LineType__c.equalsIgnoreCase(APT_Constants.LINE_TYPE_PRODUCT_SERVICE)  ){
                                            lineItemObj.Apttus_CQApprov__Approval_Status__c = APT_Constants.LABEL_APPROVAL_REQUIRED;
                                        }
                                    }
                                    update allLineItems;
                                }

                                if(callRePrice(configurationId)){
                                    callRePrice(configurationId);
                                }

                                finalURL = instanceURL;
                                finalURL += '/apex/Apttus_Config2__Cart?cartStatus=New'+'&configRequestId='+configRequestId+'&flow='+flow+'&id='+configurationId+'&launchState=cart&oldConfigId='+configRequestId+'#!/cartgrid';
                                outputMap.put('isError','false');
                                outputMap.put('errorMsg','');
                                outputMap.put('finalURL',finalURL);
                            }
                        } else{
                            Apttus_Config2.FieldExpressionWebService.attachApplicableExpressionsOnAdd(configurationId, NULL);                

                                
                            List<Apttus_Config2__LineItem__c> allLineItems = [SELECT Id, Apttus_Config2__ProductId__c, APT_StarTrack_Proposal__c, APT_Approval_Required_ST__c, 
                                                                                Apttus_CQApprov__Approval_Status__c, Apttus_Config2__LineType__c
                                                                                FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =: configurationId];
                            if(!allLineItems.isEmpty()){
                                for( Apttus_Config2__LineItem__c lineItemObj : allLineItems ){
                                    if(lineItemObj.APT_StarTrack_Proposal__c 
                                        && lineItemObj.APT_Approval_Required_ST__c 
                                        && lineItemObj.Apttus_Config2__LineType__c.equalsIgnoreCase(APT_Constants.LINE_TYPE_PRODUCT_SERVICE)  ){
                                        lineItemObj.Apttus_CQApprov__Approval_Status__c = APT_Constants.LABEL_APPROVAL_REQUIRED;
                                    }
                                }
                                update allLineItems;
                            }

                            if(callRePrice(configurationId)){
                                callRePrice(configurationId);
                            }
                            finalURL = instanceURL;
                            finalURL += '/apex/Apttus_Config2__Cart?cartStatus=New'+'&configRequestId='+configRequestId+'&flow='+flow+'&id='+configurationId+'&launchState=cart&oldConfigId='+configRequestId+'#!/cartgrid';
                            // outputMap.put('outside','else');
                            outputMap.put('isError','false');
                            outputMap.put('errorMsg','');
                            outputMap.put('finalURL',finalURL);
                            // outputMap.put('propsalRecord',String.valueOf(lstProposal));
                        }
                    // } else{
                    //     if(callRePrice(configurationId)){
                    //         callRePrice(configurationId);
                    //     }
                    //     finalURL = instanceURL;
                    //     finalURL += '/apex/Apttus_Config2__Cart?cartStatus=New'+'&configRequestId='+configRequestId+'&flow='+flow+'&id='+configurationId+'&launchState=cart&oldConfigId='+configRequestId+'#!/cartgrid';
                    //     outputMap.put('outside','else');
                    //     outputMap.put('isError','false');
                    //     outputMap.put('errorMsg','');
                    //     outputMap.put('finalURL',finalURL);
                    //     outputMap.put('propsalRecord',String.valueOf(lstProposal));
                    // }
                } 
                
                // else{
                //     if(callRePrice(configurationId)){
                //         callRePrice(configurationId);
                //     }
                //     finalURL = instanceURL;
                //     finalURL += '/apex/Apttus_Config2__Cart?cartStatus=New'+'&configRequestId='+configRequestId+'&flow='+flow+'&id='+configurationId+'&launchState=cart&oldConfigId='+configRequestId+'#!/cartgrid';
                //     outputMap.put('outside','else');
                //     outputMap.put('isError','false');
                //     outputMap.put('errorMsg','');
                //     outputMap.put('finalURL',finalURL);
                //     outputMap.put('propsalRecord',String.valueOf(lstProposal));
                // }
                
            }
            
            return outputMap;
        } catch (Exception e) {
            System.debug('Execption occured on line number'+e.getLineNumber()+'<<<and reason is>>'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * This method reset the adjustment applied to the propsal and return back to the cart
     * @param - configurationId - it refers to the cart id / configuration record id
     * @param - businessObjectId - it refers to the proposal id
     * @param - flow - it refers to what type of configuration record is
     * @param - configRequestId - it refers to the tempObject id
     */
    @AuraEnabled
    public Static Map<String, String> onReset(String configurationId, String businessObjectId, String flow, String configRequestId){        
        try {
            Apttus_Config2__ProductConfiguration__c prodConfig = new Apttus_Config2__ProductConfiguration__c(); // Product Configuration Record
            String instanceURL = '';// Salesforce Base URL
            Map<String, String> outputMap = new Map<String, String>();
            instanceURL = URL.getSalesforceBaseUrl().toExternalForm();

            String finalURL;
            prodConfig = [SELECT Id, Apttus_Config2__Status__c,Apttus_QPConfig__Proposald__c,Apttus_QPConfig__Proposald__r.Name,
                          Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Proposal_Name__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Approval_Stage__c
                          FROM Apttus_Config2__ProductConfiguration__c 
                          WHERE Id = :configurationId];
            
            if(prodConfig != null){
                if(prodConfig.Apttus_Config2__Status__c != APT_Constants.URL_SAVED ){
                    prodConfig.Apttus_Config2__Status__c = APT_Constants.URL_SAVED;
                    update prodConfig;
                }
                Apttus_Proposal__Proposal__c proposalObj = new Apttus_Proposal__Proposal__c();
                proposalObj = [Select Id, Apttus_Proposal__Opportunity__r.IsStartrackProposal__c, APT_Tier_Adjustment_Type__c, APT_Pricing_Request_Type__c, 
                                APT_Tier_Adjustment_Justification__c, APT_Intermediary__c, APT_Customer_Background__c, APT_Conversation__c, 
                                APT_Name_of_Intermediary_s_Client__c from Apttus_Proposal__Proposal__c where Id=:prodConfig.Apttus_QPConfig__Proposald__c limit 1];
                 
                if(proposalObj != null){
                    if(proposalObj.Apttus_Proposal__Opportunity__r.IsStartrackProposal__c.equalsIgnoreCase('Yes')){
                        proposalObj.APT_Tier_Adjustment_Type__c = '';
                        proposalObj.APT_Pricing_Request_Type__c = '';
                        proposalObj.APT_Tier_Adjustment_Justification__c = '';
                        proposalObj.APT_Intermediary__c = '';
                        proposalObj.APT_Customer_Background__c = '';
                        proposalObj.APT_Conversation__c = '';
                        proposalObj.APT_Name_of_Intermediary_s_Client__c = null;
                        proposalObj.APT_competitor__c = '';
                        update proposalObj;
                        prodConfig.Apttus_Config2__IsPricePending__c = true;
                        update prodConfig;

                        List<Apttus_Config2__LineItem__c> allLineItems = [SELECT Id, Apttus_Config2__ProductId__c, APT_StarTrack_Proposal__c, APT_Approval_Required_ST__c, 
                                                                          Apttus_CQApprov__Approval_Status__c, Apttus_Config2__LineType__c
                                                                          FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =: configurationId];
                        if(!allLineItems.isEmpty()){
                            for( Apttus_Config2__LineItem__c lineItemObj : allLineItems ){
                                if(lineItemObj.APT_StarTrack_Proposal__c 
                                    && lineItemObj.APT_Approval_Required_ST__c 
                                    && lineItemObj.Apttus_Config2__LineType__c.equalsIgnoreCase(APT_Constants.LINE_TYPE_PRODUCT_SERVICE)  ){
                                    lineItemObj.Apttus_CQApprov__Approval_Status__c = '';
                                }
                            }
                            update allLineItems;
                        }
                    }
                }
            }
            Apttus_Config2.FieldExpressionWebService.attachApplicableExpressionsOnAdd(configurationId, NULL);
            if(callRePrice(configurationId)){
                callRePrice(configurationId);
            }
            finalURL = instanceURL;
            finalURL += '/apex/Apttus_Config2__Cart?cartStatus=New'+'&configRequestId='+configRequestId+'&flow='+flow+'&id='+configurationId+'&launchState=cart&oldConfigId='+configRequestId+'#!/cartgrid';

            outputMap.put('isError','false');
            outputMap.put('errorMsg','');
            outputMap.put('finalURL',finalURL);
            return outputMap;
        } catch (Exception e) {
            System.debug('Execption occured on line number'+e.getLineNumber()+'<<<and reason is>>'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * @param - businessObjectId - it refers to the proposal id
     */
    @AuraEnabled
    public static String getOpptyType(string businessObjectId){
        try {
            Apttus_Proposal__Proposal__c proposalObj = [Select Id,Apttus_Proposal__Opportunity__c,Apttus_Proposal__Opportunity__r.Type 
                                                        from Apttus_Proposal__Proposal__c where Id=:businessObjectId limit 1];
            
            if(proposalObj != null){
                if(proposalObj.Apttus_Proposal__Opportunity__r.Type == APT_Constants.OPPORTUNITY_TYPE_NEW_CUSTOMER){
                    return APT_Constants.OPPORTUNITY_TYPE_NEW_BUSINESS;
                } else if(proposalObj.Apttus_Proposal__Opportunity__r.Type == APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER){
                    return APT_Constants.OPPORTUNITY_TYPE_CROSS_SELL;
                }
            }
            return '';
        } catch (Exception e) {
            System.debug('Execption occured on line number'+e.getLineNumber()+'<<<and reason is>>'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * This method calls the pricing api.
     * * @param - cartId - it refers to the cart id / configuration record id
     */
    public static Boolean callRePrice(String cartId){
        boolean hasPendingItems = false;
        Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
        objUpdatePriceRequestDO.CartId = cartId;
        Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
        hasPendingItems = result.IsPricePending;
        return hasPendingItems;
    }
    /**
     * This method used to return back to cart withoud making changes to the pricing adjustment.
     * @param - configurationId - it refers to the cart id / configuration record id
     */
    @AuraEnabled
    public static void onCancel(String configurationId){ 
        try {
            Apttus_Config2__ProductConfiguration__c prodConfig = new Apttus_Config2__ProductConfiguration__c();

            prodConfig = [SELECT Id, Apttus_Config2__Status__c,Apttus_QPConfig__Proposald__c,Apttus_QPConfig__Proposald__r.Name,
                         Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c, Apttus_QPConfig__Proposald__r.Apttus_Proposal__Proposal_Name__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Approval_Stage__c
                         FROM Apttus_Config2__ProductConfiguration__c 
                         WHERE Id = :configurationId];
            
            if(prodConfig != null){
                if(prodConfig.Apttus_Config2__Status__c != APT_Constants.URL_SAVED ){
                    prodConfig.Apttus_Config2__Status__c = APT_Constants.URL_SAVED;                    
                    update prodConfig;     
                }
            }  
        } catch (Exception e) {
            System.debug('Execption occured on line number'+e.getLineNumber()+'<<<and reason is>>'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}