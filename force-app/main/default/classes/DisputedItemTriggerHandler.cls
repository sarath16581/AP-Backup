/**
 * @changelog
 * 2017-02-06 - Bharat P - Initial Version - Handles calls from Disputed Item Trigger
 * 2017-03-07 - Adrian A - Update to remove after trigger events and make sure CA creation happens inside disupted items trigger
 * 2021-06-02 - Ranjeewa Silva - Added new methods to recalculate product sub category on parent credit approval record on after update.
 */
public without sharing class DisputedItemTriggerHandler{
    
    /* @created by: Adrian Recio
     * @description Main before insert trigger handler method              
     */        
    public static void beforeInsertTriggerHandler(List <Disputed_Item__c> newList){
        populateCreditApproval(null, newList);
    }
    
    /* @created by: Adrian Recio
     * @description Main before update trigger handler method              
     */  
    public static void beforeUpdateTriggerHandler(Map <Id, Disputed_Item__c> oldMap, List <Disputed_Item__c> newList){
        populateCreditApproval(oldMap, newList);
    }

    /**
     * Invoked when a Disputed Item is being updated.
     * @param disputedItems updated disputed item records
     * @param existingDisputedItems old versions of the records
     */
    public static void afterUpdateTriggerHandler(List<Disputed_Item__c> disputedItems, Map<Id, Disputed_Item__c> existingDisputedItems) {
        Set<Id> creditApprovalsToRecalculateProductSubcategory = new Set<Id>();
        for (Disputed_Item__c disputedItem: disputedItems) {
            Disputed_Item__c oldDisputedItem = existingDisputedItems.get(disputedItem.Id);

            // product sub category needs to be recalculated in following scenarios:
            // - disputed item is changing status into 'Verified Claim' or changing status from 'Verified Claim' into
            //   some other status.
            // - disputed item is in 'Verified Claim' status and any of the below fields are changing value:
            //      - parent credit approval (Credit_Approval__c)
            //      - product (Product__c)
            //      - credit type (Type__c)
            //      - product sub category (Product_Sub_Category__c)
            //      - proposed credit (Proposed_Credit__c)
            if ((disputedItem.Status__c == 'Verified Claim' || oldDisputedItem.Status__c == 'Verified Claim')
                    && (disputedItem.Status__c != oldDisputedItem.Status__c
                        || disputedItem.Credit_Approval__c != oldDisputedItem.Credit_Approval__c
                        || disputedItem.Product__c != oldDisputedItem.Product__c
                        || disputedItem.Type__c != oldDisputedItem.Type__c
                        || disputedItem.Product_Sub_Category__c != oldDisputedItem.Product_Sub_Category__c
                        || disputedItem.Proposed_Credit__c != oldDisputedItem.Proposed_Credit__c)) {

                if (disputedItem.Credit_Approval__c != null) {
                    creditApprovalsToRecalculateProductSubcategory.add(disputedItem.Credit_Approval__c);
                }

                if (oldDisputedItem.Credit_Approval__c != null && disputedItem.Credit_Approval__c != oldDisputedItem.Credit_Approval__c) {
                    // credit approval linked to this Disputed Item has changed.
                    // need to recalculate the product sub category of the previous credit approval too.
                    creditApprovalsToRecalculateProductSubcategory.add(oldDisputedItem.Credit_Approval__c);
                }

            }
        }

        if (!creditApprovalsToRecalculateProductSubcategory.isEmpty()) {
            reCalculateProductSubCategoryOnCreditApprovals(creditApprovalsToRecalculateProductSubcategory);
        }
    }

    /**
     * Re-Calculate product sub category for the Credit Approvals passed in
     * @param creditApprovalIds Credit Approval Ids for recalculating product sub category
     */
    private static void reCalculateProductSubCategoryOnCreditApprovals(Set<Id> creditApprovalIds) {

        // do an aggregate query to grab the verified disputed items linked to credit approval ids passed in.
        // get the sum of credit amount grouped by product sub category, so that we can determine the product sub category
        // with the highest credit per for each credit approval. aggregate query is ordered by sum of credit amounts in descending order.
        AggregateResult[] aggregateResults = [SELECT Credit_Approval__c, Credit_Approval__r.Product_Sub_Category__c currentProductSubCategory, Product_Sub_Category__c, SUM(Credit_Amount_Exclusive_GST__c) value1
                                                    FROM Disputed_Item__c
                                                    WHERE Credit_Approval__c != null AND Credit_Approval__c IN :creditApprovalIds AND Status__c = 'Verified Claim'
                                                    GROUP BY Credit_Approval__c,  Credit_Approval__r.Product_Sub_Category__c, Product_Sub_Category__c
                                                    ORDER BY SUM(Credit_Amount_Exclusive_GST__c) desc];

        Map<Id, Credit_Approval__c> creditApprovalsToUpdate = new Map<Id, Credit_Approval__c>();
        Set<Id> creditApprovalsAlreadyCalculated = new Set<Id>();

        for (AggregateResult aggregateResult: aggregateResults) {
            Id creditApprovalId = (Id) aggregateResult.get('Credit_Approval__c');

            // for each credit approval only need to recalculate for the first product sub category group in query results
            // which is the product sub category with the highest credit amount.
            // check if the credit approval id has already been calculated.
            if (!creditApprovalsAlreadyCalculated.contains(creditApprovalId)) {

                // add credit approval id to avoid recalculating again.
                // product sub category with the highest credit amount is already found for this credit approval.
                creditApprovalsAlreadyCalculated.add(creditApprovalId);

                // product sub category currently set on credit approval. only need to update if this is different to the
                // recalculated product sub category
                String currentProductSubCategory = (String) aggregateResult.get('currentProductSubCategory');

                // recalculated product sub category with the maximum credit based on the current DML.
                String productSubCategoryWithMaximumProposedCredit = (String) aggregateResult.get('Product_Sub_Category__c');

                if (!String.isBlank(productSubCategoryWithMaximumProposedCredit)
                        && (String.isBlank(currentProductSubCategory) || !currentProductSubCategory.equals(productSubCategoryWithMaximumProposedCredit))) {

                    if (!creditApprovalsToUpdate.containsKey(creditApprovalId)) {
                        // update product sub category
                        creditApprovalsToUpdate.put(creditApprovalId, new Credit_Approval__c(Id = creditApprovalId, Product_Sub_Category__c = productSubCategoryWithMaximumProposedCredit));
                    }
                }
            }
        }

        if (!creditApprovalsToUpdate.isEmpty()) {
            update(creditApprovalsToUpdate.values());
        }
    }

    /* @created by: Adrian Recio
     * @description Main before delete trigger handler method       
     */  
    public static void beforeDeleteTriggerHandler(Map <Id, Disputed_Item__c> oldMap, List <Disputed_Item__c> oldList){
        deleteParentCA(oldMap, oldList);
    }
    
    /* @created by: Adrian Recio
     * @description: Method to validate and restrict DI update if parent CA is already submitted.          
     */ 
    public static Boolean validateCAStatus(Map <Id, Disputed_Item__c> oldMap, List<Disputed_Item__c> disputedItemsList){

        set<Id> oldCASet = new set<Id>();

        for(Disputed_Item__c diVar : oldMap.values()){
            if(diVar.Credit_Approval__c!=null){
                oldCASet.add(diVar.Credit_Approval__c);
            }
        }

        Map<Id, Credit_Approval__c> caOldValueMap = new Map<Id, Credit_Approval__c>([Select Id, Status__c from Credit_Approval__c 
                                                                                     where Id IN :oldCASet AND 
                                                                                     (Status__c='Approved' or 
                                                                                     Status__c='Pending Approval Decision')]);

        for(Disputed_Item__c diVar: disputedItemsList){

            Disputed_Item__c oldDiVar = oldMap.get(diVar.Id);
            if(oldDiVar.Credit_Approval__c!=null && oldDiVar.ERP_ID__c == diVar.ERP_ID__c &&
                (diVar.Product__c!=oldDiVar.Product__c || diVar.Type__c!=oldDiVar.Type__c)){
                if(caOldValueMap.containsKey(oldDiVar.Credit_Approval__c)){
                    diVar.addError('Related credit approval is already submitted.');
                    return true;
                }
            }
        }

        return false;
    }

    /* @created by: Adrian Recio
     * @description: Main method that calls sub methods to populate CAs based on DIs presence.            
     */  
    public static void populateCreditApproval(Map <Id, Disputed_Item__c> oldMap, List<Disputed_Item__c> disputedItemsList){
        try{
            // Decalre Id Sets and Map to contain CA and its related Case and Product Family
            Set <String> disputeItemCaseNumber = new Set <String>();
            Set <String> disputeItemProductFamily = new Set <String>();   
            Set <String> disputeItemType = new Set <String>();      
            Map <String, Map<String,Credit_Approval__c>> creditApprovalMap = new Map <String, Map<String,Credit_Approval__c>> ();
            List<Disputed_Item__c> tempDIList = new List<Disputed_Item__c>();
            List<Disputed_Item__c> nullInvalidDIList = new List<Disputed_Item__c>();

            Boolean caError = false;

            // Validate DI update. Restrict update if related CA is already submitted/pending approval
            // Validation should be successful for all DIs in the batch to make sure multiple depndency of CA and DI is correct
    
            if(oldMap!=null && AdjustmentTriggerHandler.adjustmentLink==false){
                caError = validateCAStatus(oldMap, disputedItemsList);
            }

            if(caError==false){
                // Filter dipsuted items (Only with PF and CT populated will be calculated)
                // Build Id Set
                for(Disputed_Item__c disputeItemVar : disputedItemsList){
                    // Pull old map if present
                    // Cancel any DI calculations if updated is performed in ERP
                    Disputed_Item__c diOld;
                    if(oldMap!=null){
                        diOld = oldMap.get(disputeItemVar.Id);
                    }

                    Boolean IsNullDI = true;

                    if( diOld==null &&
                        disputeItemVar.Product__c!=null && 
                        disputeItemVar.Type__c!=null   &&
                        disputeItemVar.Status__c!='Rejected' && 
                        disputeItemVar.Status__c!='Invalid Claim'){

                        tempDIList.add(disputeItemVar);
                        IsNullDI = false;

                        system.debug('DI Insert');
                    }else if(diOld!=null){
                        IsNullDI = false;

                        if((disputeItemVar.Product__c!=diOld.Product__c || 
                               disputeItemVar.Type__c!=diOld.Type__c ) &&
                               disputeItemVar.ERP_ID__c==diOld.ERP_ID__c &&
                                 disputeItemVar.Product__c!=null && 
                                 disputeItemVar.Type__c!=null   &&
                                 disputeItemVar.Status__c!='Rejected' && 
                                 disputeItemVar.Status__c!='Invalid Claim'){

                                 tempDIList.add(disputeItemVar);
                                 system.debug('DI Update');
                        }
                    }

                    system.debug('Null Check:' + IsNullDI);

                    if(IsNullDI==true){
                        disputeItemVar.Credit_Approval__c = null;
                        nullInvalidDIList.add(disputeItemVar);
                    }
                }

                // Refresh DI list
                disputedItemsList = tempDIList;

                system.debug('DI Count from Temp:' + disputedItemsList.size());

                if(disputedItemsList.size()>0){
                    // Build Id Set
                    for(Disputed_Item__c disputeItemVar : disputedItemsList){
                        disputeItemCaseNumber.add(disputeItemVar.Case__c);
                        disputeItemProductFamily.add(disputeItemVar.Product__c); 
                        disputeItemType.add(disputeItemVar.Type__c);
                    }                

                    // Pull list of parent CA
                    List<Credit_Approval__c> caList =  [Select Id, Name, Case__c, Product_Family__c, Product_Sub_Category__c,
                                                               Type__c, Status__c, (Select Id, Proposed_Credit__c, Credit_Amount_Exclusive_GST__c, Product__c, Product_Sub_Category__c from Disputed_Items__r Where Status__c != 'Rejected' AND Status__c != 'Invalid Claim')
                                                               From Credit_Approval__c 
                                                               Where Case__c IN :disputeItemCaseNumber 
                                                               And Product_Family__c IN :disputeItemProductFamily
                                                               And Type__c IN :disputeItemType];
                    
                    creditApprovalMap = mapCA(caList,creditApprovalMap); // Build initial CA Map
                    List<Credit_Approval__c> newCAList = disputeCAConnect(disputedItemsList, creditApprovalMap, false); // Build list of credit approval for insert
                    
                    // If new CA is needed, insert and refresh main map
                    if(newCAList.size()>0){
                        insert newCAList; // Insert missing credit approvals
                        creditApprovalMap = mapCA(newCAList,creditApprovalMap); // Re-build/update CA map
                    }

                    // Connect CA to disputed items
                    disputeCAConnect(disputedItemsList, creditApprovalMap, true); // Update dispute items with matching parent CA
                    
                    if(OldMap!=null){
                        recalculateCATotalsbyPFUpdate(OldMap, disputedItemsList);
                        deletebyParentCAUpdate(OldMap, disputedItemsList, nullInvalidDIList);
                    }
                }
            }
        }catch(Exception e){
            e.getStackTraceString();
        }
    }
    
    /* @created by: Adrian Recio
     * @description Main method that deletes related CA if it is orphaned by all of its DI     
     */ 
    public static void deleteParentCA(Map <Id, Disputed_Item__c> oldMap, List<Disputed_Item__c> oldList){
        set<Id> caIdSet = new set<Id>();
        
        // Build CA Id SetdeleteParentCA
        for(Disputed_Item__c dIVar: oldList){
            caIdSet.add(dIVar.Credit_Approval__c);
        }
        
        // Pull parent approval process
        /*List<Credit_Approval__c> caParentList = [Select Id, (Select Id from Disputed_Items__r where Id NOT IN :oldMap.keySet()) 
                                                 from Credit_Approval__c where Id IN :caIdSet];*/
        List<Credit_Approval__c> deleteCAList = new List<Credit_Approval__c>();
        
        // Identify CA without child DI
        for(Credit_Approval__c caVar: [Select Id, (Select Id from Disputed_Items__r where Id NOT IN :oldMap.keySet()) 
                                                 from Credit_Approval__c where Id IN :caIdSet]){
            if(caVar.Disputed_Items__r.size()==0){
                deleteCAList.add(caVar);
            }
        }
        
        // If list is not empty perform delete
        if(deleteCAList.size()>0){
            try{
                delete deleteCAList;
            }catch(Exception e){
                system.debug('Error Stack Delete CA:' + e.getStackTraceString());
            }
        }
    }
    
    /* @created by: Adrian Recio
     * @description Delete CA if it is orphaned after repareting all its child to a new CA based on PF update     
     */ 
    public static void deletebyParentCAUpdate(Map <Id, Disputed_Item__c> OldMap, 
                                              List<Disputed_Item__c> disputedItemsList,
                                              LIst<Disputed_Item__c> nullInvalidDIList){
        // Id sets that will contain parameters to filter CA for delete based on DI's PF update
        set<Id> reassignedCASet = new set<Id>();
        set<Id> includedCASet = new set<Id>();
        set<Id> disputeIdSet = new set<Id>();
        
        List<Disputed_Item__c> mergeDIList = nullInvalidDIList;
        mergeDIList.addAll(disputedItemsList);

        for(Disputed_Item__c diVar: mergeDIList){
            Disputed_Item__c olddiVar = OldMap.get(diVar.Id);
            includedCASet.add(diVar.Credit_Approval__c); 
            disputeIdSet.add(diVar.Id);
            if(diVar.Credit_Approval__c!=olddiVar.Credit_Approval__c || diVar.Credit_Approval__c==null){
                reassignedCASet.add(olddiVar.Credit_Approval__c);
            }
        }
        
        List<Credit_Approval__c> caDeleteList = [Select (Select Id from Disputed_Items__r where Id NOT IN :disputeIdSet), 
                                                 Id from Credit_Approval__c where Id IN :reassignedCASet and Id NOT IN :includedCASet];
        List<Credit_Approval__c> finalCADeleteList = new List<Credit_Approval__c>();
        
        for(Credit_Approval__c caVar: caDeleteList){
            if(caVar.Disputed_Items__r.size()==0){
                finalCADeleteList.add(caVar);
            }
        }
        
        if(finalCADeleteList.size()>0){
            try{
                delete finalCADeleteList;
            }catch(Exception e){
                e.getStackTraceString();
            }
        }
    }
    
   /* @created by: Adrian Recio
    * @description Recalculate CA total if product family of disputed item is updated   
    */ 
    public static void recalculateCATotalsbyPFUpdate(Map <Id, Disputed_Item__c> OldMap, List<Disputed_Item__c> disputedItemsList){
        try{
            Map<Id,List<Disputed_Item__c>> diCalculateMap = new Map<Id,List<Disputed_Item__c>>();
            
            for(Disputed_Item__c diVar: disputedItemsList){
                
                Disputed_Item__c olddiVar = OldMap.get(diVar.Id);
                
                // If product is updated, recalculate credit approval
                if((diVar.Product__c!=olddiVar.Product__c 
                    || diVar.Type__c!=olddiVar.Type__c) && 
                    diVar.Status__c=='Verified Claim'){
                    List<Disputed_Item__c> diListTemp = new List<Disputed_Item__c>();
                    if(diCalculateMap.containsKey(diVar.Credit_Approval__c)){
                        diListTemp = diCalculateMap.get(diVar.Credit_Approval__c);
                    }
                    diListTemp.add(diVar);
                    diCalculateMap.put(diVar.Credit_Approval__c,diListTemp);
                }
            }
        
             if(diCalculateMap.size()>0){
                    List<Credit_Approval__c> caCalculateList = [Select CreditAmountExclusiveGST__c, CreditAmountInclusiveGST__c,
                                                                GSTAmount__c,Id, Amount_Charged__c, Amount_Claimed__c, Credit_Amount__c 
                                                                from Credit_Approval__c where Id IN :diCalculateMap.keySet()];
                    for(Credit_Approval__c caVar: caCalculateList){
                        List<Disputed_Item__c> diAddList = diCalculateMap.get(caVar.Id);
                        for(Disputed_Item__c diVar: diAddList){
                            try{
                                caVar.Amount_Charged__c = nullReverse(caVar.Amount_Charged__c, false) + nullReverse(diVar.Amount__c, false);
                                caVar.Amount_Claimed__c = nullReverse(caVar.Amount_Claimed__c, false) + nullReverse(diVar.Amount_Claimed__c, false);
                                caVar.Credit_Amount__c = nullReverse(caVar.Credit_Amount__c, false) + nullReverse(diVar.Proposed_Credit__c, false);
                                caVar.CreditAmountExclusiveGST__c = nullReverse(caVar.CreditAmountExclusiveGST__c, false) + nullReverse(diVar.Credit_Amount_Exclusive_GST__c, false);
                                caVar.CreditAmountInclusiveGST__c = nullReverse(caVar.CreditAmountInclusiveGST__c, false) + nullReverse(diVar.Credit_Amount_Inclusive_GST__c, false);
                                caVar.GSTAmount__c = nullReverse(caVar.GSTAmount__c, false) + nullReverse(diVar.GSTAmount__c, false);
                                
                                caVar.Amount_Charged__c = nullReverse(caVar.Amount_Charged__c, true);
                                caVar.Amount_Claimed__c = nullReverse(caVar.Amount_Claimed__c, true);
                                caVar.Credit_Amount__c = nullReverse(caVar.Credit_Amount__c, true);
                                caVar.CreditAmountExclusiveGST__c = nullReverse(caVar.CreditAmountExclusiveGST__c, true);
                                caVar.CreditAmountInclusiveGST__c = nullReverse(caVar.CreditAmountInclusiveGST__c, true);
                                caVar.GSTAmount__c = nullReverse(caVar.GSTAmount__c, true);
                            }catch(Exception e){
                                system.debug('CA Calculation Error:' + e.getStackTraceString());
                            }
                        }
                    }
                    update caCalculateList;
                }
        }catch(Exception e){
            e.getStackTraceString();
        }   
    }
    
     /* @created by: Adrian Recio
     * @description: Field null checker          
     */ 
    public static Decimal nullReverse(Decimal intVal, Boolean zeroReverse){
        if(intVal==0 && zeroReverse){
            return null;
        }else if(intVal==null){
            return 0;
        }else if(intVal>=0){
            return intVal;
        }
        
        return null;
    }

    /* @created by: Adrian Recio
     * @description             
     */ 
    public static Map <String, Map<String,Credit_Approval__c>> mapCA(List<Credit_Approval__c> caList,
                                                                     Map <String, Map<String,Credit_Approval__c>> creditApprovalMap){
        Map <String, Map<String,Credit_Approval__c>> creditApprovalMapTemp = creditApprovalMap;
        for (Credit_Approval__c creditApproval : caList){
            // If case map doesn't exist create 
            If(creditApprovalMapTemp.containsKey(creditApproval.Case__c)==false){
                Map<String,Credit_Approval__c> familyCAMap = new Map<String,Credit_Approval__c>();
                familyCAMap.put(creditApproval.Product_Family__c + creditApproval.Type__c,creditApproval);
                creditApprovalMapTemp.put(creditApproval.Case__c, familyCAMap);  
            }else{
                // Get product family-credit approval map for current case
                Map<String,Credit_Approval__c> familyCaMap = creditApprovalMapTemp.get(creditApproval.Case__c);
                // If family for case is already populated, do nothing
                if(familyCAMap.containsKey(creditApproval.Product_Family__c + creditApproval.Type__c)==false){ 
                    familyCAMap.put(creditApproval.Product_Family__c + creditApproval.Type__c,creditApproval);
                    creditApprovalMapTemp.put(creditApproval.Case__c, familyCAMap);  
                }
            }   
        }
        return creditApprovalMapTemp;
    }
    
    /* @created by: Adrian Recio
     * @description: Binds CA to child DI depending on bindDI boolean.
     *               If true, perform bind, If false, perform check of missing CA parent records.            
     */ 
    public static List<Credit_Approval__c> disputeCAConnect(List<Disputed_Item__c> dIList, 
                                                            Map<String, Map<String, Credit_Approval__c>> creditApprovalMap,
                                                            Boolean bindDI){
     
        List<Credit_Approval__c> newCAList = new List<Credit_Approval__c>();
        Map<String, Set<String>> caseToFamilyOnCreateSet = new Map<String, Set<String>>();

        for(Disputed_Item__c disputeItem : dIList){
            if(bindDI == true){
                Map<String,Credit_Approval__c> familyCaMap = creditApprovalMap.get(disputeItem.Case__c);

                if(familyCaMap.containsKey(disputeItem.Product__c + disputeItem.Type__c)==true){ 
                    Credit_Approval__c pCAVar = familyCAMap.get(disputeItem.Product__c + disputeItem.Type__c);
                    if((pCAVar.Status__c == 'Approved' || 
                        pCAVar.Status__c == 'Pending Approval Decision') && 
                        AdjustmentTriggerHandler.adjustmentLink == false){
                        disputeItem.addError('Credit Approval with Product Family of ' + 
                                                                 disputeItem.Product__c + 
                                                                ' and Credit Type of ' + 
                                                                 disputeItem.Type__c + 
                                                                 ' is already submitted.');
                        disputeItem.Product__c.addError('Please select a different Product Family or Credit Type combination.');
                        disputeItem.Type__c.addError('Please select a different Product Family or Credit Type combination.');
                    }else{
                        disputeItem.Credit_Approval__c =  pCAVar.Id;
                    } 
                }
            }else{  
                Boolean isForCreate = false;
                if(caseToFamilyOnCreateSet.containsKey(disputeItem.Case__c)){
                    Set<string> pfSet = caseToFamilyOnCreateSet.get(disputeItem.Case__c);
                    if(pfSet.contains(disputeItem.Product__c + disputeItem.Type__c)){
                        isForCreate = true;
                    }
                }

                if (creditApprovalMap.containsKey(disputeItem.Case__c) == false && 
                    isForCreate == false){
                    Credit_Approval__c creditApprove = mapDItoCA(disputeItem);
                    newCAList.add(creditApprove);
                    
                    // Tag CA for creation
                    Set<String> pfSet = new Set<String>();

                    if(caseToFamilyOnCreateSet.containsKey(disputeItem.Case__c)){
                        pfSet = caseToFamilyOnCreateSet.get(disputeItem.Case__c);
                    }

                    pfSet.add(disputeItem.Product__c + disputeItem.Type__c);
                    caseToFamilyOnCreateSet.put(disputeItem.Case__c,pfSet);
                }
            }             
        }

        return newCAList;

    }

    /* @created by: Adrian Recio
     * @description: Mapping method that create CA approval based on presence of child dispute.           
     */ 
    public static Credit_Approval__c mapDItoCA(Disputed_Item__c disputeItem){
        Credit_Approval__c pCAVar = new Credit_Approval__c(); 
        pCAVar.Type__c = disputeItem.Type__c;
        pCAVar.OwnerId = disputeItem.OwnerId;
        pCAVar.Product_Family__c = disputeItem.Product__c;
        pCAVar.Case__c = disputeItem.Case__c;
        pCAVar.Status__c = 'New';
        pCAVar.Product_Sub_Category__c = disputeItem.Product_Sub_Category__c;
        return pCAVar;
    }
}