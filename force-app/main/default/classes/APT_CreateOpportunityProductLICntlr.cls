/**
Description: This apex class is the controller for Visualforce page - APT_CreateOpportunityProductLineItem.
Created By: Raviteja Epuri
Created Date: 15th Feb, 2015

Update by Lyndon Lavapie, 30/7/2018, added changes for CR 148/13
2021-10-26  naveen.rajanna@auspost.cm.au PRB0050942 - Addded null check to avoid null pointer exception and changed api version to 52
*/


/* Shashwat.Nath@Auspost.com has Updated the Class on 01/08/2020 to implement a queable Interface . This class will no more be used as a Controller for 
   "APT_CreateOpportunityProductLineItem" VF Page as this page is being Removed from Apttus Shopping Cart
   and the Synchronisation of the Products would be automated When User Either Saves the shopping Cart or does Online or Offline Checkout .
   The Synchronisation points would be same for New , DOV or Renewal Flow .
   -All the Page messages which were put to display before the users 
   are also cleaned up
   -The methods that were doing VF page Specific actions are also removed  */

public class APT_CreateOpportunityProductLICntlr implements Queueable {

    /* Shashwat.Nath@Auspost.com has created the below Set of Variables for product Sync between apttus Proposal Products 
       and Opportunity Products as part of US - 2218 for SFT Release 2 */
       
    Public list<APT_Opportunity_Product_Line_Item__c> lstEntries{get;set;}
    public boolean haserrorMessages{get;set;}
    Public Set<id> configIdSet;
    Public Set<Id> quoteIdSet;
    List<Id> oLIDelete = New List<Id>();
    Map<string,Apttus_Config2__LineItem__c> mapCartProducts =new Map<string,Apttus_Config2__LineItem__c>(); 
    Map<String,Map<string,Apttus_Config2__LineItem__c>> mapofQuoteIdAndMapCartProducts = new Map<String,Map<string,Apttus_Config2__LineItem__c>>();
    Map<String, List<Apttus_Config2__LineItem__c>> mapquoteIdToLineItemList = new Map<String, List<Apttus_Config2__LineItem__c>>();
    Map<id, Set<String>> quoteIdUniqueProductMap = new Map<id, Set<String>>();
    Map<Id, PriceBookEntry> mapPriceBookEntry = new Map<Id, PriceBookEntry>();
    Map<Id,Id> proposalIdOpportunityId = new Map<Id,Id>();
    List<id> opportunityLineItemToDeleteCustom =  new List<id>();
    List<id> opportunityLineItemToDeleteStandard =  new List<id>();
    List<id> opportunityLineItemToDeleteAddAll =  new List<id>();
    Set<Id> idSet = new Set<Id>();
    Public static final String ORGID = UserInfo.getOrganizationId();
    
    
    /* Shashwat.Nath has updated the constructor to accept set of Product Configuration Id's and Related Proposal Id's from the 
       product configuration Trigger */
       
    public APT_CreateOpportunityProductLICntlr(Set<id> prodConfigListIdSet,Set<id> quoteProposalIdSet){
        // Setting the quoteId coming from the Trigger to be used later in the logic
        quoteIdSet = quoteProposalIdSet; 
        // Setting the product config coming from the Trigger to be used later in the logic
        configIdSet = prodConfigListIdSet;
        
        /*If there are multiple proposals associated to an opportunity , calling this method to delete the OpportunityProductLineItems and Related
          APT_Opportunity_Product_Line_Item__c custom object records for the proposals which are non Primary */
          
        deleteNonPrimaryOppProdLineItemsStandard(quoteIdSet);
   
    }
    
    /* The execute method of this queabale class implements the logic to create the "APT_Opportunity_Product_Line_Item__c " custom object records and then 
       sync the same records as Opportunity Products */
       
    public void execute(QueueableContext context) {
        try{
                Set<Id> opptyIds = new Set<Id>();
                set<id> newProductsAdded = new Set<Id>();
                lstEntries= new list<APT_Opportunity_Product_Line_Item__c>();
                system.debug('**** Quote Id in execute method****' +quoteIdSet );
                system.debug('**** Config Id in execute method ****' +configIdSet );
                
                /* Querying and Iterating through the Line Item records which are associated to product configuration ID set being passed from the Product Configuration Trigger */
                
                for(Apttus_Config2__LineItem__c liadded:[select id,name,Apttus_Config2__ProductId__r.Name,Apttus_Config2__ProductId__r.Non_contracted__c,Apttus_Config2__ProductId__r.APT_Sales_Unit_Price__c,
                                                            APT_Sales_Unit_Price__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Expected_Revenue_Start_Date__c,
                                                            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Expected_Revenue_End_Date__c,
                                                            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.type,
                                                            Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c,Apttus_Config2__OptionId__r.Name,Apttus_Config2__OptionId__r.APT_Sales_Unit_Price__c,
                                                            Apttus_Config2__OptionId__r.APT_Sync_with_Opportunity__c,Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__LineType__c,
                                                            APT_Product_Name__c, APT_Contracted_Line_Item__c, Apttus_Config2__AttributeValueId__r.APT_Volume_Thresholds__c,
                                                            Apttus_Config2__AttributeValueId__r.APT_Non_Contracted_Rates_Printpost__c from Apttus_Config2__LineItem__c 
                                                            where Apttus_Config2__ConfigurationId__c =:configIdSet and APT_Is_OPC_deleted__c = false]){
        
        
                    /* Creating a Map of the Proposal Id to the List of Related Line Item Records */
                    if(!mapquoteIdToLineItemList.keyset().isEmpty() && mapquoteIdToLineItemList.containskey(liadded.apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c)){
                        mapquoteIdToLineItemList.get(liadded.apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c).add(liadded);
                    }
                    else {
                        mapquoteIdToLineItemList.put(liadded.apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c , new List<Apttus_Config2__LineItem__c>{liadded});
                    }
                    // Adding the Products Id to  set
                    if(liadded.Apttus_Config2__IsPrimaryLine__c && liadded.Apttus_Config2__LineType__c !=APT_Constants.LABEL_LINE_TYPE_OPTION){ 
                        newProductsAdded.add(liadded.Apttus_Config2__ProductId__c);
                    }
                    else if(liadded.Apttus_Config2__LineType__c ==APT_Constants.LABEL_LINE_TYPE_OPTION){
                        newProductsAdded.add(liadded.Apttus_Config2__OptionId__c);
                    }
                    
                    // Creating a Map of Proposal Id and Related Opportunity Id
                    proposalIdOpportunityId.put(liadded.apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c, liadded.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c);
                } 
                
                /* Mapping Proposal Id and mapofCartProducts . Each proposal would have it's Map of cart products having a key as Product Name and 
                   it respective Line Item */
                   
                for(String quoteid: mapquoteIdToLineItemList.keyset()){
                    mapCartProducts = new Map<String,Apttus_Config2__LineItem__c>();
                    for( Apttus_Config2__LineItem__c lineItem : mapquoteIdToLineItemList.get(quoteid)){
                        mapCartProducts.put(lineItem.APT_Product_Name__c , lineItem);
                    }
                    mapofQuoteIdAndMapCartProducts.put(quoteid , mapCartProducts);
                }
        
                /* Querying and Iterating on APT_Opportunity_Product_Line_Item__c records associated to proposals */
                for(APT_Opportunity_Product_Line_Item__c opsaved:[select id,name,APT_Classification__c,APT_Product_Text__c,APT_Contract_Product__c,APT_Product__r.name,APT_Product_Configuration__c,
                                                                    APT_Quantity__c,APT_Quote_Proposal__r.name,APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__c,APT_Revenue_End_Date__c,APT_Revenue_Start_Date__c,APT_Sequence_Number__c,
                                                                    APT_Sub_Classification__c,APT_TotalPrice__c,APT_Unit_Sales_Price__c, APT_Quote_Proposal__r.Apttus_Proposal__Account__c, APT_Change_Classification__c , (select id from Opportunity_Product__r)
                                                                    from APT_Opportunity_Product_Line_Item__c
                                                                    where APT_Quote_Proposal__c =:quoteIdSet]){
                                                                    
                    /* Mapping  quote Id to Set of Product Names , which would be used later to determine if there is already an APT_Opportunity_Product_Line_Item__c entry created for 
                        that product linked to a proposal in scope */                                              
                    If(!mapofQuoteIdAndMapCartProducts.keyset().isempty() && mapofQuoteIdAndMapCartProducts.get(opsaved.APT_Quote_Proposal__c).ContainsKey(opsaved.APT_Product__r.name) && 
                                opsaved.APT_Product_Configuration__c!=NULL){
                         
                        // Checking if Map lready has a proposal in its Key then just add the name of the product to the same product Set       
                        if(quoteIdUniqueProductMap.containsKey(opsaved.APT_Quote_Proposal__c)){
                            quoteIdUniqueProductMap.get(opsaved.APT_Quote_Proposal__c).add(opsaved.APT_Product__r.name); 
        
                        }
                        else{
                            quoteIdUniqueProductMap.put(opsaved.APT_Quote_Proposal__c , new Set<String>{opsaved.APT_Product__r.name});
                        }
                    }
                    
                    else{
                        
                        /* If there are APT_Opportunity_Product_Line_Item__c for products which are not there in the Cart , adding the ids of those
                            records and the related Opportunity product records to a list and deleting those records */
                        for(OpportunityLineItem oliToBeDelete : opsaved.Opportunity_Product__r){
                            if(!opportunityLineItemToDeleteStandard.contains(oliToBeDelete.Id)){
                                opportunityLineItemToDeleteStandard.add(oliToBeDelete.id);
                            }
                        }
                        if(!opportunityLineItemToDeleteCustom.contains(opsaved.Id)){ 
                            opportunityLineItemToDeleteCustom.add(opsaved.Id);
                        }  
                    }     
                } 
                
                /*Updating the "APT_Apttus_Delete_Override__c " flag before the deletion of OpportunityLineItems so that the "APT_OpportunityProductLineItem"
                  does not fire when the deletion is happening via code */
                List<OpportunityLineitem> oppLineItem = [ Select id , APT_Apttus_Delete_Override__c from OpportunityLineitem WHERE ID IN:opportunityLineItemToDeleteStandard ] ;
                    for(OpportunityLineitem opli : oppLineItem ){
                        opli.APT_Apttus_Delete_Override__c =true;    
                    }
               Update oppLineItem; 
               
                // Deleting the list of id's (APT_Opportunity_Product_Line_Item__c  and Related Opportunity Products) 
                // Adding all the items to be deleted in one single list to save an additional DML and avoid Chunking on deletion 
                opportunityLineItemToDeleteAddAll.addall(opportunityLineItemToDeleteCustom);
                opportunityLineItemToDeleteAddAll.addAll(opportunityLineItemToDeleteStandard);
                database.delete(opportunityLineItemToDeleteAddAll, true);
                integer seqNum=lstEntries.size();
                APT_Opportunity_Product_Line_Item__c  oP;
                system.debug('***** Map quote Id Line Item List ****'+mapquoteIdToLineItemList); 
                system.debug('***** quoteIdUniqueProductMap ****'+quoteIdUniqueProductMap);
                system.debug('***** New Products Added ****'+newProductsAdded);  
                
                /* Getting the Pricebook Entries for the Products . This method would also create price book entries for the products for which
                   there are no entries in the System */
                 mapPriceBookEntry = APT_ConfigurationTriggerHandler.managePriceBookEntry(newProductsAdded);
                  system.debug('***** Price Book Entry Map****'+mapPriceBookEntry );
                /* Iterating through each of the Proposals in scope and then further Iterating through each of the Line items associated 
                   to that proposal to create instances of APT_Opportunity_Product_Line_Item__c for each product in the Cart . Also making sure 
                   that no duplicate records are added for the same Product */ 
                      
                for(id quoteid: mapquoteIdToLineItemList.keyset()){
                    for(Apttus_Config2__LineItem__c lI: mapquoteIdToLineItemList.get(quoteid)){ 
                        system.debug('***** Map quote Id Line Item List ****'+lstEntries);                                    
                        if((quoteIdUniqueProductMap.get(quoteid) == null || (quoteIdUniqueProductMap.get(quoteid)!=null && !quoteIdUniqueProductMap.get(quoteid).contains(lI.APT_Product_Name__c)) && 
                                lI.APT_Product_Name__c!=null) && ((lI.Apttus_Config2__LineType__c ==APT_Constants.LABEL_LINE_TYPE_OPTION &&  lI.Apttus_Config2__OptionId__r.APT_Sync_with_Opportunity__c) || (lI.Apttus_Config2__LineType__c !=APT_Constants.LABEL_LINE_TYPE_OPTION &&  lI.Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c))){
                            
                            /* Adding the products to the map inside the loop so that the APT_Opportunity_Product_Line_Item__c for the same product is not duplicated */
                            if(quoteIdUniqueProductMap.get(quoteid)!=null){
                                quoteIdUniqueProductMap.get(quoteid).add(lI.APT_Product_Name__c);
                            }
                            else{
                                quoteIdUniqueProductMap.put(quoteid, new Set<String>{lI.APT_Product_Name__c}); 
                            }
                            
                            // Setting up the values for the APT_Opportunity_Product_Line_Item__c record to be inserted
                            oP = new APT_Opportunity_Product_Line_Item__c();
                            op.APT_Sequence_Number__c=seqNum; 
                            op.APT_Quote_Proposal__c = lI.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c ;
                            op.APT_Product_Configuration__c =  lI.Apttus_Config2__ConfigurationId__c;
                            if(lI.Apttus_Config2__IsPrimaryLine__c && lI.Apttus_Config2__LineType__c !=APT_Constants.LABEL_LINE_TYPE_OPTION){
                                oP.APT_Product__c= li.Apttus_Config2__ProductId__c;
                                oP.APT_Product_Text__c= li.Apttus_Config2__ProductId__r.Name;
                                oP.APT_Unit_Sales_Price__c= li.Apttus_Config2__ProductId__r.APT_Sales_Unit_Price__c;
                               // newProductsAdded.add(oP.APT_Product__c);
                            }
                            else if(lI.Apttus_Config2__LineType__c ==APT_Constants.LABEL_LINE_TYPE_OPTION){
                                oP.APT_Product__c= li.Apttus_Config2__OptionId__c;
                                oP.APT_Product_Text__c= li.Apttus_Config2__OptionId__r.Name;
                                oP.APT_Unit_Sales_Price__c= li.Apttus_Config2__OptionId__r.APT_Sales_Unit_Price__c; 
                                //newProductsAdded.add(oP.APT_Product__c);
                            } 
                            op.APT_Quantity__c =1;            
                            if(li.Apttus_Config2__ProductId__r.Non_contracted__c 
                                || (APT_Constants.PRINT_POST_RATES_NON_CONTRACTED).equalsIgnoreCase(li.Apttus_Config2__AttributeValueId__r.APT_Volume_Thresholds__c)
                                || li.Apttus_Config2__AttributeValueId__r.APT_Non_Contracted_Rates_Printpost__c ){
        
                                oP.APT_Contract_Product__c= APT_Constants.OPTION_NO;
                            } 
                            else {
                                oP.APT_Contract_Product__c= APT_Constants.OPTION_YES;            
                            } 
                            
                            if(newProductsAdded.contains(op.APT_Product__c) && mapPriceBookEntry.get(op.APT_Product__c)!= null){
                                op.APT_Unit_Sales_Price__c = mapPriceBookEntry.get(op.APT_Product__c).UnitPrice;
                            }
                            // 09/18/2019: Set default value of Growth? picklist field
                            op.APT_Change_Classification__c = APT_Constants.OPTION_NO; 
                            system.debug('**** Unit Sales Price ****'+op.APT_Unit_Sales_Price__c);
                            system.debug('**** Quantity ****'+op.APT_Quantity__c);
                            system.debug('**** Product ****'+op.APT_Product__c);
                            if(op.APT_Unit_Sales_Price__c != null && op.APT_Quantity__c != null) {
                                op.APT_TotalPrice__c= op.APT_Unit_Sales_Price__c * op.APT_Quantity__c;
                            }
                            if (APT_Constants.CLASSIFICATION_GROWTH.equalsIgnoreCase(op.APT_Classification__c)) {
                                op.APT_Change_Classification__c = APT_Constants.OPTION_YES;       // rewritten as Yes if Classification is Growth?
                            }      
                            //Added the APT_Product__c (lookup) check to handle null specific exception for complex Bundles Product's defination based on Charge Type
                            if(!String.isBlank(oP.APT_Product__c)) {
                            idSet.add(op.APT_Quote_Proposal__c);
                            // Adding to the list of APT_Opportunity_Product_Line_Item__c to be Inserted.
                            lstEntries.add(op);
                            seqNum++;
                        }
                    }
                }
                }

                /*
                On Shopping Cart Save / Finalize request, Opportunity Products Sync process initiate.

                Shopping Cart having an Lookup relation with Quote/Proposal. In Opportunity Sync process an Custom object
                APT_Opportunity_Product_Line_Item__c is used. The custom object also having Lookup relation with Quote/Proposal.
                On Shopping Cart Save / Finalize request, the Proposal record used & lock.

                On Cart's status update, Configuration Trigger initiate Opportunity Product Sync Queueable process, where the Custom object
                APT_Opportunity_Product_Line_Item__c, due to Lookup relation with Proposal Object, on record insert statement execute,
                getting the Proposal record LOCK exception. To handle the record lock exception, added below SOQL statement with 'FOR UPDATE',
                which can add delay time (Max 10 Seconds) if the Proposal record in use.
                */
                List<Apttus_Proposal__Proposal__c> activeProposal = [Select Id from Apttus_Proposal__Proposal__c where Apttus_Proposal__Primary__c = true and Id =: quoteIdSet FOR UPDATE ];
            
                // Inserting the APT_Opportunity_Product_Line_Item__c Records 
                system.debug('**** Size of the List ****'+lstEntries.size());
                insert lstEntries;
                
                /* Making sure that there are no duplicate "APT_Opportunity_Product_Line_Item__c" object records are created for the 
                   same Product , If there are duplicates then delete the duplicate before Syncing them to Opportunity Product */
              
                    Map<id,List<APT_Opportunity_Product_Line_Item__c>> quoteIdproductLineItemMap = new Map<id,List<APT_Opportunity_Product_Line_Item__c>>();
                    List<APT_Opportunity_Product_Line_Item__c> listTobedeleted = new List<APT_Opportunity_Product_Line_Item__c>();
                    
                    // Iterating through all the APT_Opportunity_Product_Line_Item__c associated to the Proposals is scope 
                    for(APT_Opportunity_Product_Line_Item__c opc : [ Select id , APT_Product__c,APT_Classification__c , APT_Sub_Classification__c ,APT_Quantity__c,
                                                                    APT_Unit_Sales_Price__c , APT_Quote_Proposal__c,APT_Quote_Proposal__r.Name , APT_Contract_Product__c
                                                                    FROM APT_Opportunity_Product_Line_Item__c WHERE APT_Quote_Proposal__c =:quoteIdSet]){
                            
                            // Creating a map of each proposal Id and respective APT_Opportunity_Product_Line_Item__c records
                            if(quoteIdproductLineItemMap.containskey(opc.APT_Quote_Proposal__c)){
                                quoteIdproductLineItemMap.get(opc.APT_Quote_Proposal__c).add(opc);    
                            }
                            else{
                                quoteIdproductLineItemMap.put(opc.APT_Quote_Proposal__c, new List<APT_Opportunity_Product_Line_Item__c >{opc});   
                            }
                     } 
                     
                     //Iteranting through APT_Opportunity_Product_Line_Item__c through each of the proposal and adding the duplicate records to a list
                     for(id opliId : quoteIdproductLineItemMap.keyset()){
                           Set<String> productsAllreadyAdded = new Set<String>(); 
                           for(APT_Opportunity_Product_Line_Item__c opli : quoteIdproductLineItemMap.get(opliId )){
                               
                               if(!productsAllreadyAdded.contains(opli.APT_Product__c)){
                                   productsAllreadyAdded.add(opli.APT_Product__c);    
                               }
                               else{
                                   listTobedeleted.add(opli);
                               }
                           } 
                     }              
                    // Deleteing the duplicate records
                    system.debug('**** Size of the List to be deleted****'+listTobedeleted.size());
                    delete listTobedeleted;
                
                // Calling Method to Sync the records to Opportunity Products 
                syncOpportunityProducts();
                
            }  catch(Exception ex) {
                  UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'APT_CreateOpportunityProductLICntlr ' , 'execute', 'APT_ConfigurationTrigger ', LoggingLevel.ERROR);
            }
        }
        
    /* Shashwat.Nath@Auspost.com created this method to create the Opportunity Products based on the records inserted in APT_Opportunity_Product_Line_Item__c 
       object in order to keep them in Sync with the Products available in the Proposal Cart */
       
    public void syncOpportunityProducts(){
        
        try{
               List<OpportunityLineitem> opportunityLineItemtoBeInserted = new List<OpportunityLineitem>();
               // Querying the APT_Opportunity_Product_Line_Item__c  Records to fetch and Map the Values for the Opportunity Products to be created
               Set<String> uniqueProdSet = new Set<String>();
               List<Id> duplicateProductIds = new List<Id>();
               for(APT_Opportunity_Product_Line_Item__c opc : [ Select id , APT_Product__c,APT_Classification__c , APT_Sub_Classification__c ,APT_Quantity__c,
                                                                APT_Unit_Sales_Price__c , APT_Quote_Proposal__c,APT_Quote_Proposal__r.Name , APT_Contract_Product__c,
                                                                (select id from Opportunity_Product__r) FROM
                                                                APT_Opportunity_Product_Line_Item__c WHERE APT_Quote_Proposal__c IN: quoteIdSet ]){
                     
                                                               
                    // Making Sure the records get Created only if there is no associated Opportunity Product to  APT_Opportunity_Product_Line_Item__c record                                           
                    if(!uniqueProdSet.contains(opc.APT_Product__c) && opc.Opportunity_Product__r.isEmpty()){ 
                        uniqueProdSet.add(opc.APT_Product__c);                                         
                        OpportunityLineitem oli = new OpportunityLineitem();        
                        oli.Quantity = 1;
                        oli.UnitPrice = opc.APT_Unit_Sales_Price__c;
                        oli.Contract_Number__c = opc.APT_Quote_Proposal__r.Name;
                        if(proposalIdOpportunityId.get(opc.APT_Quote_Proposal__c)!=null){
                            oli.OpportunityId = proposalIdOpportunityId.get(opc.APT_Quote_Proposal__c);
                        }
                        oli.PriceBookEntryId = mapPriceBookEntry.get(opc.APT_Product__c).Id;
                        oli.Product2id = opc.APT_Product__c;
                        oli.Contract_Product__c= opc.APT_Contract_Product__c;
                        oli.APT_Is_Apttus_Opportunity_Line_item__c = true;
                        oli.APT_OPC_Line_Items__c = opc.Id;
                        oli.APT_Apttus_Delete_Override__c = false;
                        opportunityLineItemtoBeInserted.add(oli);
                        System.debug('**** List of Opportunity Products to be Added **** '+opportunityLineItemtoBeInserted);
                    }
                    
               }
               
                // Map for Opportunity and Related List of products 
               Map<Id , List<id>> opportunityIdListOfProductMap = new  Map<Id , List<id>>();
               // List of manually added products to be deleted during Sync
               List<OpportunityLineitem> manuallyAddedDuplicateOpportunityProdToBeDeleted = new List<OpportunityLineitem>();
               List<OpportunityLineitem> OpportunityProdAlreadyExistsing = new List<OpportunityLineitem>();
               
               // Creating a Map of proposal Id and List of Products associated from List of Opportunity products to be Inserted
               for(OpportunityLineitem  opli : opportunityLineItemtoBeInserted){
                   if(opportunityIdListOfProductMap.containskey(opli.OpportunityId)){
                       opportunityIdListOfProductMap.get(opli.OpportunityId).add(opli.Product2id);
                   }
                   else{
                       opportunityIdListOfProductMap.put(opli.OpportunityId , new List<id>{opli.Product2id});    
                   }
               
               }
               
               // Querying the Already existing Opportunity Products for the opportunities in Scope
               OpportunityProdAlreadyExistsing = [ SELECT id , Opportunityid , Product2id from OpportunityLineitem WHERE Opportunityid =: opportunityIdListOfProductMap.keyset()];
               
               /*Comparing between the New opportunity products being inserted and already present opportunity products , if there are any 
                 duplicates found based on the product , then adding the already existing opportunity product to a list for deletion */
               
               for( OpportunityLineitem  opli : OpportunityProdAlreadyExistsing){
                   if(opportunityIdListOfProductMap.get(opli.Opportunityid).contains(opli.Product2id) && !manuallyAddedDuplicateOpportunityProdToBeDeleted.contains(opli)){
                       manuallyAddedDuplicateOpportunityProdToBeDeleted.add(opli); 
                   }    
               }
               // Deleting the manually added duplicate product before the Sync
               database.delete(manuallyAddedDuplicateOpportunityProdToBeDeleted, false);  
               
               // Inserting the Opportunity Product Records
               insert opportunityLineItemtoBeInserted;
                
        }  
        catch(Exception ex) {
             UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'APT_CreateOpportunityProductLICntlr ' , 'execute', 'APT_ConfigurationTrigger ', LoggingLevel.ERROR);
        }
    }
    
    /* Shashwat.Nath@Auspost.com created the below Method to delete the Opportunity Products related to non Primary Proposals under the same 
       opportunity when a Primary Proposal is Saved or Finalized . This would also delete APT_Opportunity_Product_Line_Item__c record associated to 
       Opportunity Product being deleted Non Primary Proposals */
       
       
    public void deleteNonPrimaryOppProdLineItemsStandard(Set<Id> quoteIdSet){
        try{
               List<Apttus_Proposal__Proposal__c> proposalList= [ Select id, Apttus_Proposal__Opportunity__c from Apttus_Proposal__Proposal__c WHERE Id IN:quoteIdSet];
               Set<Id> opportunityIdSet = new Set<Id>();
               List<Id> opportunityproductLineItemTobeDeletedCustom = new List<Id>();
               List<Id> opportunityproductLineItemTobeDeletedStandard = new List<Id>();
               List<Id> deleteAllAtOnce = new List<Id>();
               // getting the opportunity Id's for related Proposals
               for(Apttus_Proposal__Proposal__c proposal : proposalList){
                   opportunityIdSet.add(proposal.Apttus_Proposal__Opportunity__c);    
               }
               
               //Getting the Opportunity records and related Opportunity product records for the Proposals which are no more Primary .
               List<Opportunity> oppList = [ Select id , (Select id, APT_OPC_Line_Items__r.APT_Quote_Proposal__r.Apttus_Proposal__Primary__c from OpportunityLineItems WHERE APT_OPC_Line_Items__c!=null AND APT_OPC_Line_Items__r.APT_Quote_Proposal__r.Apttus_Proposal__Primary__c = false )
                                                             from Opportunity WHERE ID IN : opportunityIdSet ];
                                                             
               for(Opportunity opp : oppList ){
                   for(OpportunityLineItem oppLineItem : opp.OpportunityLineItems){
                       if(!opportunityproductLineItemTobeDeletedStandard.contains(oppLineItem.id)){
                           opportunityproductLineItemTobeDeletedStandard.add(oppLineItem.id);
                       }
                       if(oppLineItem.APT_OPC_Line_Items__c!=null && !opportunityproductLineItemTobeDeletedCustom.contains(oppLineItem.APT_OPC_Line_Items__c)){
                           opportunityproductLineItemTobeDeletedCustom.add(oppLineItem.APT_OPC_Line_Items__c);
                       }       
                   }
               }
               
                /*Updating the "APT_Apttus_Delete_Override__c " flag before the deletion of OpportunityLineItems so that the "APT_OpportunityProductLineItem"
                  does not fire when the deletion is happening via code */
               List<OpportunityLineitem> oppLineItem = [ Select id , APT_Apttus_Delete_Override__c from OpportunityLineitem WHERE ID IN:opportunityproductLineItemTobeDeletedStandard ] ;
                    for(OpportunityLineitem opli : oppLineItem ){
                        opli.APT_Apttus_Delete_Override__c =true;    
                    }
               Update oppLineItem; 
               
               // Adding all the items to be deleted in one single list to save an additional DML and avoid Chunking on deletion 
               // Adding the APT_Opportunity_Product_Line_Item__c id's to be deleted
               deleteAllAtOnce.addAll(opportunityproductLineItemTobeDeletedCustom);
               system.debug('***** Custom List to be deleted *****'+opportunityproductLineItemTobeDeletedCustom);
               
               // Adding the OpportunityLineItems to be deleted
               deleteAllAtOnce.addAll(opportunityproductLineItemTobeDeletedStandard);
               system.debug('***** Standard List to be deleted *****'+opportunityproductLineItemTobeDeletedStandard);
              
               // Delete the List of ID's
               system.debug('***** Final List to be deleted *****'+deleteAllAtOnce );
               database.delete(deleteAllAtOnce , true);
           
        } 
        catch(Exception ex) {
             UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'APT_CreateOpportunityProductLICntlr ' , 'execute', 'APT_ConfigurationTrigger ', LoggingLevel.ERROR);
        }    
    }
    
 }