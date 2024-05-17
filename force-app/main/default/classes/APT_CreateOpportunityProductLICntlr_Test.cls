/*
Created By - Kapil Devani
Created Date - 1st Mar, 2016
Last Modified By - Krishna Velani
Last Modified Date - 29th July, 2021
Changes done: Commented method call for STP-5314
*/

/*Shashwat.Nath@auspost.com Updated this test class to cover the scenarios based on the chnages for the OPC functionality
  as part of STP release 2 */

@isTest
public class APT_CreateOpportunityProductLICntlr_Test{
    
    @testSetup
    public static void setup(){
       
       Test.startTest();
       Account acc = APT_TestUtils.createOrganisation();
        insert acc;
        
        //Create Opportunity
        Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
        opty.type = 'New Customer';
        insert opty;
        
        Opportunity  existingOpty = APT_TestUtils.createOpportunity(acc.Id);
        existingOpty.type = 'Existing Customer';
        insert existingOpty;
        
        

        //Create PriceList
        Apttus_Config2__PriceList__c  priceList = APT_TestUtils.createPriceList();
        insert priceList;

        //Create Proposal
        List<Apttus_Proposal__Proposal__c> lstPro = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote 1', priceList.ID);
        Proposal.APT_Selected_LP__c = 'Selected Proposal';
        Proposal.RecordTypeID = [SELECT id from RecordType where Name ='Renewal Quote'].Id;
        system.debug('**** Quote Name ****'+Proposal.name);
        lstPro.add(Proposal);
        
        Apttus_Proposal__Proposal__c existingProposal= APT_TestUtils.getQuoteProposal(acc.ID,existingOpty.ID,'Proposal','Quote 2', priceList.ID);
        existingProposal.APT_Selected_LP__c = 'Selected Proposal 2';
        existingProposal.RecordTypeID = [SELECT id from RecordType where Name ='Renewal Quote'].Id;
        lstPro.add(existingProposal);
        //insert lstPro;
        
        Apttus_Proposal__Proposal__c secondPropUnderOpp = APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote 2', priceList.ID);
        existingProposal.APT_Selected_LP__c = 'Selected Proposal 4';
        existingProposal.RecordTypeID = [SELECT id from RecordType where Name ='Renewal Quote'].Id;
        lstPro.add(secondPropUnderOpp);
        insert lstPro;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
        bundle1.Non_contracted__c = false;
        insert bundle1;

        Product2 bundle2 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST002','Postal Services');
        bundle2.APT_Sync_with_Opportunity__c = true;
        bundle2.Apttus_Config2__HasOptions__c = true;
        bundle2.Non_contracted__c = true;
        bundle2.Apttus_Config2__ConfigurationType__c = 'Bundle';
        insert bundle2;

        Product2 option1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL_EXPRESS,'APOST003','Postal Services');
        option1.APT_Sync_with_Opportunity__c = true;
        option1.Apttus_Config2__ConfigurationType__c = 'Option';
        insert option1;
        
        //Create Product Configuration             
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
        proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
        insert prodconfig;
        
        Apttus_Config2__ProductConfiguration__c  prodconfig1 = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
        secondPropUnderOpp.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
        insert prodconfig1;

        //Create Price list Item
        Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
        insert pli;
        
        /*Apttus_Config2__PriceListItem__c pli1= APT_TestUtils.createPriceListItem(priceList.ID,bundle2.ID,'C Manufacturing','BAND 2');
        insert pli1;*/
        
        Apttus_Config2__PriceListItem__c pli2= APT_TestUtils.createPriceListItem(priceList.ID,option1.ID,'C Manufacturing','BAND 2');
        insert pli2;
        
        Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
        1, 'Product/Service', bundle2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
        'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
        bundleLine.Apttus_Config2__NetPrice__c = 5225;
        bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
        bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
        insert bundleLine;    
    
        Apttus_Config2__LineItem__c bundleLine1 = APT_TestUtils.getConfigLineItem(prodconfig1.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
        1, 'Product/Service', bundle2.Id, true,null,//ItemSeq, lineType, bundleId, customizable, productOptionId
        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
        'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        bundleLine1.Apttus_Config2__AllowManualAdjustment__c = true;
        bundleLine1.Apttus_Config2__NetPrice__c = 5225;
        bundleLine1.Apttus_Config2__PrimaryLineNumber__c = 1;
        bundleLine1.Apttus_Config2__NetAdjustmentPercent__c = -10;
        insert bundleLine1;
        
        Apttus_Config2__LineItem__c optionline1 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, false,//Config Id, grpId, LineNum, isPrimary
        1, 'Option', bundle2.Id, true,null,//ItemSeq, lineType, bundleId, customizable, productOptionId
        option1.Id, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
        'Each', 1, priceList.Id, pli2.Id,//Uom, term, priceList, Pli,
        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        bundleLine1.Apttus_Config2__AllowManualAdjustment__c = true;
        bundleLine1.Apttus_Config2__NetPrice__c = 5225;
        bundleLine1.Apttus_Config2__PrimaryLineNumber__c = 1;
        bundleLine1.Apttus_Config2__NetAdjustmentPercent__c = -10;
        insert optionline1;
		Test.stopTest();

    }
   
   /*Shashwat.Nath@Auspost.com Created this test method to test the functionality of Opportunity Line Item creation on Save 
     of the Proposal Cart */ 
     
   static testmethod  void testProductSyncOnSaveOfCart(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser ){
            Apttus_Config2__ProductConfiguration__c config = [ Select id,Apttus_QPConfig__Proposald__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c, Apttus_Config2__Status__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
            config.Apttus_Config2__Status__c = 'Saved';
       
            test.startTest();
                update config ;
            test.stopTest();
            List<OpportunityLineItem> opplineItemList = [ select id,Product2.Name,APT_OPC_Line_Items__c   from OpportunityLineItem WHERE opportunityid =:config.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c];
            
            //Assert that there has been a new Opportunity Product Created when User Saves the cart 
            system.assert( opplineItemList.size()>0);
           
            //Make Sure the new Opportunity Product created is having Eparcel Product as that product was added to the cart
            system.assertEquals( opplineItemList[0].Product2.Name , 'eParcel');   
            
            //Assert that a new Custon Object 'APT_Opportunity_Product_Line_Item__c'  record has been created which is associated to the Opportunity Product
            List<APT_Opportunity_Product_Line_Item__c> opportunityProdItemList = [ Select id from APT_Opportunity_Product_Line_Item__c Where APT_Product_Configuration__c =:config.id AND APT_Quote_Proposal__c =:config.Apttus_QPConfig__Proposald__c];
            
            //Assert that a new Custon Object 'APT_Opportunity_Product_Line_Item__c'  record has been created which is associated to the Opportunity Product                                                                        
            system.assert( opportunityProdItemList.size()>0); 
            
            // Assert that the custom object record created is same to the record which is associated to the Opportunity Product
            system.assertEquals( opplineItemList[0].APT_OPC_Line_Items__c  , opportunityProdItemList[0].id);
        }     
    }
    
    /*Shashwat.Nath@Auspost.com Created this test method to test the functionality of Opportunity Line Item creation on Checkout
     of the Proposal Cart */ 
     
    static testmethod  void testproductSyncOnCheckoutOfCart(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser ){
            // Query the product config data created in the setup method
            Apttus_Config2__ProductConfiguration__c config = [ Select id,Apttus_QPConfig__Proposald__c, Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c , Apttus_Config2__Status__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
            // Update the status to finalized , whichwould signify that user has checked out the cart 
            config.Apttus_Config2__Status__c = 'Finalized';
        
            test.startTest();
                update config ;
            test.stopTest();
            
            //Assert that new Opportunity Product custom object record has been created as part of the Sync
            List<APT_Opportunity_Product_Line_Item__c> opportunityProdItemList = [ Select id from APT_Opportunity_Product_Line_Item__c Where APT_Product_Configuration__c =:config.id AND 
                                                                                    APT_Quote_Proposal__c =:config.Apttus_QPConfig__Proposald__c];
                                                                                    
            //Assert that a new Custon Object 'APT_Opportunity_Product_Line_Item__c'  record has been created which is associated to the Opportunity Product
            system.assert( opportunityProdItemList.size()>0); 
            
            //query  Opportunity Product custom object record 
            List<OpportunityLineItem> opplineItemList = [ select id,Product2.Name,APT_OPC_Line_Items__c from OpportunityLineItem WHERE opportunityid =:config.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c];
            
            //Assert that there has been a new Opportunity Product Created when User checkout the cart 
            system.assert( opplineItemList.size()>0);
            
            //Make Sure the new Opportunity Product created is having Eparcel Product as that product was added to the cart
            system.assertEquals( opplineItemList[0].Product2.Name , 'eParcel'); 
            
            // Assert that the custom object record created is same to the record which is associated to the Opportunity Product
            system.assertEquals( opplineItemList[0].APT_OPC_Line_Items__c  , opportunityProdItemList[0].id);
        } 
    }
    
    /*Shashwat.Nath@Auspost.com Created this test method to test the functionality of multiple proposals under same opportunity and only one proposal
     being the primary . The sync should ensure that only the Products from the Primary proposal are synced */ 
     
    static testmethod  void testmultipleProposalSameOpportunity(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser ){
            // query the proposal records created in the setup method
            List<Apttus_Proposal__Proposal__c> apttusProposalList = [ Select id , APT_Selected_LP__c  from Apttus_Proposal__Proposal__c ];
            
            // query the config record which is associated to the first proposal under same opportunity
            Apttus_Config2__ProductConfiguration__c config = [ Select id,Apttus_QPConfig__Proposald__c, Apttus_QPConfig__Proposald__r.name , Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c , Apttus_Config2__Status__c from Apttus_Config2__ProductConfiguration__c 
                                                               WHERE Apttus_QPConfig__Proposald__c=:apttusProposalList[0].ID LIMIT 1];  
            
            //Update the status to finalize which would signify user has checked out the cart
            config.Apttus_Config2__Status__c = 'Finalized';
            
            update config ;
            
            Apttus_Config2__LineItem__c lineItem = [Select id ,Apttus_Config2__ProductId__c from Apttus_Config2__LineItem__c WHERE 
                                                    Apttus_Config2__ConfigurationId__c =:config.ID LIMIT 1];
                                                    
            //Create Custom Object record for non primary proposal
            APT_Opportunity_Product_Line_Item__c op = new APT_Opportunity_Product_Line_Item__c();
            op.APT_Quote_Proposal__c = config.Apttus_QPConfig__Proposald__c;
            op.APT_Product_Configuration__c = config.id;
            op.APT_Product__c = lineItem.Apttus_Config2__ProductId__c ;
            op.APT_Product_Text__c ='eParcel';
            oP.APT_Unit_Sales_Price__c = 100;
            op.APT_Quantity__c =1; 
            insert op;
            
            Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            Update standardPricebook;
            
            PriceBookEntry pbe = new PriceBookEntry();
            pbe.Pricebook2Id = standardPricebook.Id;
            pbe.Product2Id = lineItem.Apttus_Config2__ProductId__c;
            pbe.UnitPrice = 1000;
            pbe.IsActive = true;
            
            insert pbe ;
            
            //Dummy Opportunity Line Item Created for non primary proposal
            OpportunityLineitem oli = new OpportunityLineitem();        
            oli.Quantity = 1;
            oli.UnitPrice = 100;
            oli.Product2id = lineItem.Apttus_Config2__ProductId__c;
            oli.PriceBookEntryId = pbe.id;
            oli.Contract_Number__c = op.APT_Quote_Proposal__r.Name;
            oli.OpportunityId = config.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c;
            oli.APT_Is_Apttus_Opportunity_Line_item__c = true;
            oli.APT_OPC_Line_Items__c = op.Id;
            oli.APT_Apttus_Delete_Override__c = false;
            oli.Change_Classification__c = APT_Constants.OPTION_YES;
            insert oli;
       
            Apttus_Config2__ProductConfiguration__c config2 = [ Select id,Apttus_QPConfig__Proposald__c, Apttus_QPConfig__Proposald__r.name, Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c , Apttus_Config2__Status__c from Apttus_Config2__ProductConfiguration__c 
                                                           WHERE Apttus_QPConfig__Proposald__c=:apttusProposalList[2].ID LIMIT 1];
            
            // Update the primary checkbox of first proposal to false which would signify that user has created a new proposal under same opp  and made it primary
            apttusProposalList[0].Apttus_Proposal__Primary__c = false;
            update apttusProposalList[0];
            
            // Update the primary checkbox of second proposal under same opportunity to true which would signify that user has made this proposal as primary
            apttusProposalList[2].Apttus_Proposal__Primary__c = true;
            update apttusProposalList[2];
            config2.Apttus_Config2__Status__c = 'Finalized';
            
            //Test Starts
            test.startTest();
                update config2;  
            test.stopTest();
            //Test Stops
            
            
            // Query the Opportunity Product Linked to non primary proposal, these should be deleted by now .
            List<OpportunityLineItem> opplineItemList = [ select id,Product2.Name,APT_OPC_Line_Items__c from OpportunityLineItem WHERE id=:oli.id];
            // Assert Opportunity Products for non primary proposal are deleted
            system.assert( opplineItemList.size()==0);
               
            List<APT_Opportunity_Product_Line_Item__c> opportunityProdItemList = [ Select id from APT_Opportunity_Product_Line_Item__c Where APT_Product_Configuration__c =:config2.id AND 
                                                                                    APT_Quote_Proposal__c =:config2.Apttus_QPConfig__Proposald__c];
                                                                                    
            //Assert that a new Custon Object 'APT_Opportunity_Product_Line_Item__c'  record has been created which is associated to the Opportunity Product
            system.assert( opportunityProdItemList.size()>0); 
        }
    }
    
    /*Shashwat.Nath@Auspost.com Created this test method to test the functionality deletion of Opportunity Product and related custom object
      when user makes changes to cart by removing the already added product which was synced earlier . On removal of the product from the cart
      it should delete the opportunity product on salesforce side as well to maintain the Sync */
       
   static testmethod  void testDeletionOfNonCartProducts(){
       // Running as sales admin
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser ){
            Apttus_Config2__ProductConfiguration__c config = [ Select id,Apttus_QPConfig__Proposald__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c, Apttus_Config2__Status__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
            config.Apttus_Config2__Status__c = 'Saved';
            
            //Inserting product test data
            Product2 Express = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL_EXPRESS ,'APOST001','Postal Services');
            Express.Non_contracted__c = false;
            
            insert Express;
            
            //Create Custom Object record to be associated to Opportunity Product
            APT_Opportunity_Product_Line_Item__c op = new APT_Opportunity_Product_Line_Item__c();
            op.APT_Quote_Proposal__c = config.Apttus_QPConfig__Proposald__c;
            op.APT_Product_Configuration__c = config.id;
            op.APT_Product__c = Express.id;
            op.APT_Product_Text__c ='eParcel Express';
            oP.APT_Unit_Sales_Price__c = 100;
            op.APT_Quantity__c =1; 
            insert op;
            
            Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            Update standardPricebook;
            
            PriceBookEntry pbe = new PriceBookEntry();
            pbe.Pricebook2Id = standardPricebook.Id;
            pbe.Product2Id = Express.id;
            pbe.UnitPrice = 1000;
            pbe.IsActive = true;
            
            insert pbe ;
            
            //Create opportunity Product Record which would be getting deleted when we run the test to replicate the scenario when user removes
            //the product from the cart it should aloso delete it from Opportunity Product to maintain the sync
            
            OpportunityLineitem oli = new OpportunityLineitem();        
            oli.Quantity = 1;
            oli.UnitPrice = 100;
            oli.Product2id = Express.id;
            oli.PriceBookEntryId = pbe.id;
            oli.Contract_Number__c = op.APT_Quote_Proposal__r.Name;
            oli.OpportunityId = config.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c;
            oli.APT_Is_Apttus_Opportunity_Line_item__c = true;
            oli.APT_OPC_Line_Items__c = op.Id;
            oli.APT_Apttus_Delete_Override__c = false;
            oli.Change_Classification__c = APT_Constants.OPTION_YES;
            insert oli;
            
            //Test Starts
            test.startTest();
                update config ;
            test.stopTest();
            
            //Query Opportunity Products Created
            List<OpportunityLineItem> opplineItemList = [ select id,Product2.Name,APT_OPC_Line_Items__c   from OpportunityLineItem WHERE opportunityid =:config.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c];
            
            //Assert that there has been a new Opportunity Product Created when User Saves the cart 
            system.assert( opplineItemList.size()>0);
           
            
            List<OpportunityLineItem> opplineItemList1 = [Select id from OpportunityLineItem where id =:oli.id];
             
            //Assert that the Previously attached Opportunity Product Gets deleted to match only the products in the Apttus Cart
            system.assert( opplineItemList1.size()==0);
            
            List<APT_Opportunity_Product_Line_Item__c > oppProdLineItemList = [Select id from APT_Opportunity_Product_Line_Item__c  where id =:op.id];
            
            //Assert that the associated custom object record also gets deleted with deletion of Opportunity Product to Sync what is there in the cart
            system.assert( oppProdLineItemList.size()==0);
        }     
    }
    
    /*Shashwat.Nath@Aupost.Com Added this Method to test the deletion of manually Added Duplicate Opportunity Product during Sync */
    static testmethod  void testDeletionOfManuallyAddedProducts(){
       // Running as sales admin
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser ){
            Apttus_Config2__ProductConfiguration__c config = [ Select id,Apttus_QPConfig__Proposald__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c, Apttus_Config2__Status__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
            config.Apttus_Config2__Status__c = 'Saved';
            
            //Inserting product test data
            Product2 eParcel = [ Select id from Product2 where Apttus_Config2__ConfigurationType__c ='Bundle' LIMIT 1];
            Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            Update standardPricebook;
            
            PriceBookEntry pbe = new PriceBookEntry();
            pbe.Pricebook2Id = standardPricebook.Id;
            pbe.Product2Id = eParcel.id;
            pbe.UnitPrice = 1000;
            pbe.IsActive = true;
            
            insert pbe ;
            
            //Create opportunity Product Record which would be getting deleted when we run the test to replicate the scenario when user removes
            //the product from the cart it should aloso delete it from Opportunity Product to maintain the sync
            
            OpportunityLineitem oli = new OpportunityLineitem();        
            oli.Quantity = 1;
            oli.UnitPrice = 100;
            oli.Product2id = eParcel.id;
            oli.PriceBookEntryId = pbe.id;
            oli.OpportunityId = config.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c;
            oli.Change_Classification__c = APT_Constants.OPTION_YES;
            insert oli;
            
            //Test Starts
            test.startTest();
                update config ;
            test.stopTest();
            
            //Query Opportunity Products Created
            List<OpportunityLineItem> opplineItemList = [ select id,Product2.Name,APT_OPC_Line_Items__c   from OpportunityLineItem WHERE opportunityid =:config.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c];
            
            //Assert that there has been a new Opportunity Product Created when User Saves the cart 
            system.assert( opplineItemList.size()>0);
           
            
            List<OpportunityLineItem> opplineItemList1 = [Select id from OpportunityLineItem where id =:oli.id];
             
            //Assert that the Previously attached Manually Created Opportunity Product Gets deleted to match only the products in the Apttus Cart
            system.assert( opplineItemList1.size()==0);
            
        }     
    }
}