/**
Description: This apex class is test class for apex trigger - APT_ProposalTrigger.
Created By - Aakash Khatri
Created Date - 30th August 2016
Last Modified By - 
Last Modified Date - 
**/
@isTest
private class APT_DeleteSAPRatesBatch_Test {
    private static testMethod void testMethod1() {
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
            System.runAs(testuser) 
            {  
                Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
                insert testPriceList;
                APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
                insert r2tSystemProperties;
                //Create Account
                 Account acc = APT_TestUtils.createOrganisation();
                 insert acc;                          
                 
                 //Create Opportunity
                 Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
                 insert opty;
                 
                 //Create PriceList
                 Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
                 insert priceList;
                 
                 //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
                 option.Apttus_Config2__ConfigurationType__c='Option';
                 option.APT_Sync_with_Opportunity__c=true;
                 option.APT_International_Pricing__c = false;
                 insert option;
                 
                 //Create PriceBookEntry
                 Id pricebookId = Test.getStandardPricebookId();             
                 PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
                 insert standardPrice;
                 
                 //Create Price list Item
                 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
                 insert pli;
                
                //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
                 proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 insert Proposal;
                 
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Ready For Finalization',
                 null, Datetime.now(), true);
                 insert prodconfig;
                 
                 // Create LineItem
                 Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                    1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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
                  
                   //Create Proposal Line Item               
                    Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.ID,bundleLine.ID,pli.ID,bundle1.ID,option.ID);
                    proposalLT1.Apttus_QPConfig__LineType__c = 'Option';
                    proposalLT1.Apttus_QPConfig__DerivedFromId__c = bundleLine.Id;
                    insert proposalLT1;
                    
                   //Create Proposal Product AttributeValue
                   Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue1 =APT_TestUtils.getProposalProductAttributeValue(proposalLT1.ID);
                   insert ProposalProductAttributeValue1;
                   
                   //Update Proposal Line Item with Proposal Product AttributeValue
                   proposalLT1.Apttus_QPConfig__AttributeValueId__c=ProposalProductAttributeValue1.ID;
                   Update proposalLT1;
                   
                    
                    Apttus_Proposal__Proposal_Line_Item__c proposalLT2= APT_TestUtils.getProposalLineItem(Proposal.ID,bundleLine.ID,pli.ID,bundle1.ID,null);
                    insert proposalLT2;
                   
                   //Create Proposal Product AttributeValue
                   Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue2 =APT_TestUtils.getProposalProductAttributeValue(proposalLT2.ID);
                   insert ProposalProductAttributeValue2;
                   
                   //Update Proposal Line Item with Proposal Product AttributeValue
                   proposalLT2.Apttus_QPConfig__AttributeValueId__c=ProposalProductAttributeValue2.ID;
                   Update proposalLT2; 

                   
                   //create Logdement Zone             
                   APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
                   insert logdZone;               
                   
                    //Create Feature Pricing              
                   APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
                   insert featurePricing;
                  
                  //Create product Attribute value                
                    Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
                    attribute1.Category__c='CAT1';
                    attribute1.APT_Lodgement_Zone__c=logdZone.ID;               
                    attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
                    insert attribute1;
                      
                    
                  // update product Attribute value               
                   Update attribute1; 
                  
                  APT_Opportunity_Product_Line_Item__c opli = new APT_Opportunity_Product_Line_Item__c();
                  opli.APT_Quote_Proposal__c = proposal.Id;
                  opli.APT_Product_Configuration__c = prodconfig.Id;
                  opli.APT_Product__c = bundle1.Id;
                  opli.APT_Classification__c = 'New Business';
                  opli.APT_Sub_Classification__c = 'Product Penetration';
                  opli.APT_Quantity__c = 2;
                  opli.APT_Unit_Sales_Price__c = 100;
                  opli.APT_Revenue_Start_Date__c = System.Today();
                  opli.APT_Revenue_End_Date__c = System.Today() + 100;
                  opli.APT_Contract_Product__c = 'Yes';
                  insert opli;
                  
                  // create network
                    Network__c network1 = new Network__c();
                    network1.Post_Code__c = 'somecode';
                    network1.State__c = 'ACT';

                    // Adrian Recio, 22/5/2017, Test class population for APT Business Unit field
                    network1.APT_Business_Unit__c = 'random';
                    network1.Business_Unit__c = 'random';
                    network1.APT_DWS_ID__c = 'random';
                    network1.APT_eParcel_Enabled__c = 'Yes';
                    network1.APT_Transport_Capability__c = 'VAN Only';
                    network1.Org_ID__c = 'RandOm';
                    network1.ORG_UNIT_ADDR_1__c = 'somerandom';
                    insert network1;
                    
                    // create APT_Quote_Rate_Card__c
                    APT_Quote_Rate_Card__c qrc = new APT_Quote_Rate_Card__c();
                    //qrc.Name = 'testRateCard';
                    qrc.APT_Line_Item__c = bundleLine.Id;
                    insert qrc;
                    
                    //create APT_Line_Item_Rate_Card__c
                    APT_Line_Item_Rate_Card__c lirc = new APT_Line_Item_Rate_Card__c();
                    //lirc.Name = 'testlirc';
                    lirc.APT_Proposal_Line_Item__c = proposalLT1.ID;
                    //lirc.APT_Quote_Proposal__c = Proposal.ID;
                    
                    insert lirc;
                    
                    //Create temp prposal line item
                    //Create Proposal Line Item
                    List<Apttus_Proposal__Proposal_Line_Item__c> ListPli = new List<Apttus_Proposal__Proposal_Line_Item__c>();
                    set<String> pliIdSet = new set<String>();
                    
                    Apttus_Proposal__Proposal_Line_Item__c proposalLT11= APT_TestUtils.getProposalLineItem(Proposal.ID,bundleLine.ID,pli.ID,bundle1.ID,option.ID);
                    proposalLT11.Apttus_QPConfig__LineType__c = 'Option';
                    proposalLT11.Apttus_QPConfig__DerivedFromId__c = bundleLine.Id;
                    insert proposalLT11;
                    
                    ListPli.add(proposalLT11);
                    pliIdSet.add(proposalLT11.Id);
                    prodconfig.Apttus_Config2__Status__c = 'Finalized';
                    update prodconfig;
                    set<String> setErrorMessage = new Set<String>();
                    setErrorMessage.add('error');
                    
                    Test.starttest();
                    APT_DeleteSAPRatesBatch batchController = new APT_DeleteSAPRatesBatch(pliIdSet);
                    batchController.setErrorMessage = setErrorMessage;
                    database.executeBatch(batchController);
                    
                    Test.stoptest();  
                    //System.assert(proposalLT1.Apttus_QPConfig__AttributeValueId__c !=null);
                   //System.assert(proposalLT2.Apttus_QPConfig__AttributeValueId__c !=null);
                  // system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);
            }
    }
}