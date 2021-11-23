/**
Description: This apex class is test class for apex class - APT_CreateSAPRatesBatch.
Created By - Aakash Khatri
Created Date - 30th August 2016
Last Modified By - Mausam Padhiyar
Last Modified Date - 31st Aug, 2016

05.03.2020  shashwat.nath@accenture.com   Fixed SOQL101 error
05.03.2020  seth.p.heang@accenture.com    Increase code coverages
**/
@isTest
private class APT_CreateSAPRatesBatch_Test {
    private static testMethod void testMethod1() {
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
            System.runAs(testuser) 
            {          
                Contact con= APT_TestUtils.createContact();
                insert con;
                Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
                insert testPriceList;
                APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
                insert r2tSystemProperties;
                //Create Account
                 Account acc = APT_TestUtils.createOrganisation();
                 insert acc;                          
                 
                 //Create Opportunity
                 Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
                 opty.StageName = 'Identify';
                 insert opty;
                 
                 //Create PriceList
                 Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
                 insert priceList;
                 
                 //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 bundle1.ProductCode = 'eParcelStandard';
                 insert bundle1;
                
                 Product2 bundle2 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 bundle1.ProductCode = 'InternationalBundle';
                 insert bundle2;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
                 option.Apttus_Config2__ConfigurationType__c='Option';
                 option.APT_Sync_with_Opportunity__c=true;
                 option.APT_International_Pricing__c = false;
                 option.ProductCode = 'eParcelStandard';
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
                 proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
                 insert Proposal;
                 
                 Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
                aptContract.APT_Product__c= 'eParcel' ;
                aptContract.Apttus__Related_Opportunity__c=opty.Id;
                aptContract.Apttus__Account__c=acc.Id;
                aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
                aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
                //aptContract.Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c ='Charge Account';
        
                // List<Apttus__APTS_Agreement__c> agr = new List<Apttus__APTS_Agreement__c>();
                insert aptContract;
                 
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
                    proposalLT1.APT_Charge_Code_Formula__c = '7C55';
                    proposalLT1.Apttus_Proposal__Proposal__c = proposal.Id;
                    proposalLT1.Apttus_QPConfig__PrimaryLineNumber__c = 1;
                    insert proposalLT1;
                    
                    
                   //Create Proposal Product AttributeValue
                   Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue1 =APT_TestUtils.getProposalProductAttributeValue(proposalLT1.ID);
                   insert ProposalProductAttributeValue1;
                   
                   //Update Proposal Line Item with Proposal Product AttributeValue
                   proposalLT1.Apttus_QPConfig__AttributeValueId__c=ProposalProductAttributeValue1.ID;
                   Update proposalLT1;
                   
                    
                    Apttus_Proposal__Proposal_Line_Item__c proposalLT2= APT_TestUtils.getProposalLineItem(Proposal.ID,bundleLine.ID,pli.ID,bundle2.ID,null);
                    proposalLT2.APT_Charge_Code_Formula__c = '7C55';
                    proposalLT2.Apttus_Proposal__Proposal__c = proposal.Id; 
                    proposalLT2.Apttus_QPConfig__PrimaryLineNumber__c = 2;
                    //insert proposalLT2;
                   
                   //Create Proposal Product AttributeValue
                   Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue2 =APT_TestUtils.getProposalProductAttributeValue(proposalLT2.ID);
                   //insert ProposalProductAttributeValue2;
                   Test.starttest();
                   //Update Proposal Line Item with Proposal Product AttributeValue
                   proposalLT2.Apttus_QPConfig__AttributeValueId__c=ProposalProductAttributeValue2.ID;
                   //Update proposalLT2; 

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
                    proposalLT11.Apttus_QPConfig__ParentBundleNumber__c = 1;
                    proposalLT11.APT_Charge_Code_Formula__c = '7C55';
                    proposalLT11.Apttus_Proposal__Proposal__c = proposal.Id;
                    proposalLT11.Apttus_QPConfig__PrimaryLineNumber__c = 1;
                    insert proposalLT11;
                    
                    ListPli.add(proposalLT11);
                    pliIdSet.add(proposalLT1.Id);
                    pliIdSet.add(proposalLT2.Id);
                    pliIdSet.add(proposalLT11.Id);
                    prodconfig.Apttus_Config2__Status__c = 'Finalized';
                    update prodconfig;
                    
                    set<String> setErrorMessage = new Set<String>();
                    setErrorMessage.add('error');
                    set<Id> agreementIdSet = new set<Id>();
                    agreementIdSet.add(aptContract.ID);
                    map<Id, Id> agreementByPLIMap = new map<Id, Id>();
                    agreementByPLIMap.put(proposalLT11.Id, aptContract.ID);
                    map<String, Apttus_Proposal__Proposal_Line_Item__c> primaryPLIMap = new map<String, Apttus_Proposal__Proposal_Line_Item__c>();
                    primaryPLIMap.put(proposalLT11.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + proposalLT11.Apttus_QPConfig__PrimaryLineNumber__c, proposalLT11);
                    
                    //Apttus_QPConfig__ProposalUsagePriceTier__c
                    list<Apttus_QPConfig__ProposalUsagePriceTier__c> listPUPT = new list<Apttus_QPConfig__ProposalUsagePriceTier__c>();
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt1 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt1.Apttus_QPConfig__Sequence__c = 1;
                    pupt1.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt1.Apttus_QPConfig__Dimension1Value__c = 'WG';
                    pupt1.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt1.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt1.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt1);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt21 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt21.Apttus_QPConfig__Sequence__c = 2;
                    pupt21.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt21.Apttus_QPConfig__Dimension1Value__c = 'WG';
                    pupt21.Apttus_QPConfig__Dimension2Value__c = '200';
                    pupt21.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt21.Apttus_QPConfig__AdjustmentAmount__c = 200;
                    listPUPT.add(pupt21);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt2.Apttus_QPConfig__Sequence__c = 1;
                    pupt2.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt2.Apttus_QPConfig__Dimension1Value__c = 'N0';
                    pupt2.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt2);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt11 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt11.Apttus_QPConfig__Sequence__c = 1;
                    pupt11.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt11.Apttus_QPConfig__Dimension1Value__c = 'WG';
                    pupt11.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt11.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt11.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt11);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt12 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt12.Apttus_QPConfig__Sequence__c = 1;
                    pupt12.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt12.Apttus_QPConfig__Dimension1Value__c = 'N1';
                    pupt12.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt12.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt12.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt12);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt111 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt111.Apttus_QPConfig__Sequence__c = 1;
                    pupt111.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt111.Apttus_QPConfig__Dimension1Value__c = 'V1';
                    pupt111.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt111.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt111.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt111);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt121 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt121.Apttus_QPConfig__Sequence__c = 1;
                    pupt121.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt121.Apttus_QPConfig__Dimension1Value__c = 'V1';
                    pupt121.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt121.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt121.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt121);
                    
                    insert listPUPT;
                    
                    
                    list<APT_SAP_Group_Template__c> listSGT = new list<APT_SAP_Group_Template__c>();
                    APT_SAP_Group_Template__c sgt1 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'N0-5', APT_Price_Value_Description__c = 'N0 up to 500g');
                    listSGT.add(sgt1);
                    
                    APT_SAP_Group_Template__c sgt2 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'N0-63', APT_Price_Value_Description__c = 'N1 0.51-62.5kg');
                    listSGT.add(sgt2);
                    
                    APT_SAP_Group_Template__c sgt3 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'WG-5', APT_Price_Value_Description__c = 'WG up to 500g');
                    listSGT.add(sgt3);
                    
                    APT_SAP_Group_Template__c sgt4 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'WG-63', APT_Price_Value_Description__c = 'WG 0.51-62.5kg');
                    listSGT.add(sgt4);
                    
                    APT_SAP_Group_Template__c sgt5 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'V0-5', APT_Price_Value_Description__c = 'N1 up to 500g');
                    listSGT.add(sgt5);
                    
                    APT_SAP_Group_Template__c sgt6 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'V0-63', APT_Price_Value_Description__c = 'N0 0.51-62.5kg');
                    listSGT.add(sgt6);
                    
                    APT_SAP_Group_Template__c sgt7 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'V1-5', APT_Price_Value_Description__c = 'N0 up to 500g');
                    listSGT.add(sgt7);
                    
                    APT_SAP_Group_Template__c sgt8 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'V1-63', APT_Price_Value_Description__c = 'N0 0.51-62.5kg');
                    listSGT.add(sgt8);
                    
                    APT_SAP_Group_Template__c sgt9 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'NN-5', APT_Price_Value_Description__c = 'N0 up to 500g');
                    listSGT.add(sgt9);
                    
                    APT_SAP_Group_Template__c sgt10 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'NN-63', APT_Price_Value_Description__c = 'N0 0.51-62.5kg');
                    listSGT.add(sgt10);
                    
                    APT_SAP_Group_Template__c saptemp=new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'WG-5', APT_Price_Value_Description__c = 'AT up to 500g');
                    listSGT.add(saptemp);
                
                    APT_SAP_Group_Template__c saptemp3=new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'WG-5', APT_Price_Value_Description__c = 'NN up to 500g');
                    listSGT.add(saptemp3);
                
                    APT_SAP_Group_Template__c saptemp4=new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'WG-5', APT_Price_Value_Description__c = 'NR up to 500g');
                    listSGT.add(saptemp4);
                
                    APT_SAP_Group_Template__c saptemp5=new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'WG-5', APT_Price_Value_Description__c = 'V0 up to 500g');
                    listSGT.add(saptemp5);
                    
                    APT_SAP_Group_Template__c saptemp1=new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'WG-5', APT_Price_Value_Description__c = '0 up to 500g');
                    listSGT.add(saptemp1);
                    
                    APT_SAP_Group_Template__c sgt11 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'NR-5', APT_Price_Value_Description__c = 'N0 up to 500g');
                    listSGT.add(sgt11);
                    
                    APT_SAP_Group_Template__c sgt12 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'NR-63', APT_Price_Value_Description__c = 'N0 0.51-62.5kg');
                    listSGT.add(sgt12);
                    
                    
                    APT_SAP_Group_Template__c sgt13 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'AT-5', APT_Price_Value_Description__c = 'N0 up to 500g');
                    listSGT.add(sgt13);
                    
                    APT_SAP_Group_Template__c sgt14 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '7C55', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'AT-63', APT_Price_Value_Description__c = 'N0 0.51-62.5kg');
                    listSGT.add(sgt14);
                
                    APT_SAP_Group_Template__c sgt15 = new APT_SAP_Group_Template__c(APT_Charge_Code__c = '8B66', APT_Display_Order_Sequence__c = 0, APT_Price_Value__c = 'AT-74', APT_Price_Value_Description__c = 'N0 0.51-62.5kg');
                    listSGT.add(sgt15);
                    
                    insert listSGT;
                    
                    APT_R2T_SAP_Missing_Zone_Mapping__c sapMissingZoneMapping1 = new APT_R2T_SAP_Missing_Zone_Mapping__c(Name = 'NN', APT_To_Zone__c = 'N0');
                    insert sapMissingZoneMapping1;
                    
                    APT_R2T_SAP_Missing_Zone_Mapping__c sapMissingZoneMapping2 = new APT_R2T_SAP_Missing_Zone_Mapping__c(Name = 'VV', APT_To_Zone__c = 'V0');
                    insert sapMissingZoneMapping2;
                    
                    APT_CreateSAPRatesBatch batchController = new APT_CreateSAPRatesBatch(pliIdSet, agreementIdSet, agreementByPLIMap, primaryPLIMap);
                    batchController.setErrorMessage = setErrorMessage;
                    database.executeBatch(batchController);
                    
                    Test.stoptest();  
                    //System.assert(proposalLT1.Apttus_QPConfig__AttributeValueId__c !=null);
                   //System.assert(proposalLT2.Apttus_QPConfig__AttributeValueId__c !=null);
                  // system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);
            }
    }
    
    private static testMethod void testMethod2() {
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
            System.runAs(testuser) 
            {          
                Contact con= APT_TestUtils.createContact();
                insert con;
                Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
                insert testPriceList;
                APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
                insert r2tSystemProperties;
                //Create Account
                 Account acc = APT_TestUtils.createOrganisation();
                 insert acc;                          
                 
                 //Create Opportunity
                 Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
                 opty.StageName = 'Identify';
                 insert opty;
                 
                 //Create PriceList
                 Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
                 insert priceList;
                 
                 //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 bundle1.ProductCode = 'InternationalBundle';
                 insert bundle1;
                
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 option.Apttus_Config2__ConfigurationType__c='Option';
                 option.APT_Sync_with_Opportunity__c=true;
                 option.APT_International_Pricing__c = false;
                 option.ProductCode = APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT;
                 insert option;
                 
                 Product2 option2 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 option2.Apttus_Config2__ConfigurationType__c='Option';
                 option2.APT_Sync_with_Opportunity__c=true;
                 option2.APT_International_Pricing__c = false;
                 option2.ProductCode = APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT;
                 insert option2;
                 
                 Product2 option3 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 option3.Apttus_Config2__ConfigurationType__c='Option';
                 option3.APT_Sync_with_Opportunity__c=true;
                 option3.APT_International_Pricing__c = false;
                //option3.ProductCode = APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT;
                 insert option3;
                 
                 Product2 option4 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 option4.Apttus_Config2__ConfigurationType__c='Option';
                 option4.APT_Sync_with_Opportunity__c=true;
                 option4.APT_International_Pricing__c = false;
                 option4.ProductCode = APT_Constants.InternationalAirmailLetters_INTERNATIONAL_PRODUCT;
                 insert option4;
                
                 //Create PriceBookEntry
                 Id pricebookId = Test.getStandardPricebookId();             
                 PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
                 insert standardPrice;
                 
                 PricebookEntry standardPrice2 = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option2.ID);            
                 insert standardPrice2;
                 
                 PricebookEntry standardPrice3 = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option3.ID);            
                 insert standardPrice3;
                 
                 PricebookEntry standardPrice4 = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option4.ID);            
                 insert standardPrice4;
                
                 //Create Price list Item
                 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
                 insert pli;
                
                //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
                 proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
                 insert Proposal;
                 
                 Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
                aptContract.APT_Product__c= 'eParcel' ;
                aptContract.Apttus__Related_Opportunity__c=opty.Id;
                aptContract.Apttus__Account__c=acc.Id;
                aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
                aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
                //aptContract.Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c ='Charge Account';
        
                // List<Apttus__APTS_Agreement__c> agr = new List<Apttus__APTS_Agreement__c>();
                insert aptContract;
                 
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
                  
                  Test.startTest(); 
                   //Create Proposal Line Item               
                   list<Apttus_Proposal__Proposal_Line_Item__c> pliList = new list<Apttus_Proposal__Proposal_Line_Item__c>();
                    Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.ID,bundleLine.ID,pli.ID,bundle1.ID,option.ID);
                    proposalLT1.Apttus_QPConfig__LineType__c = 'Option';
                    proposalLT1.Apttus_QPConfig__DerivedFromId__c = bundleLine.Id;
                    proposalLT1.APT_Charge_Code_Formula__c = '7C55';
                    proposalLT1.Apttus_Proposal__Proposal__c = proposal.Id;
                    proposalLT1.Apttus_QPConfig__PrimaryLineNumber__c = 1;
                    proposalLT1.Apttus_QPConfig__ChargeType__c = 'Airmail Parcels';
                    //insert proposalLT1;
                    pliList.add(proposalLT1);
                    
                    Apttus_Proposal__Proposal_Line_Item__c proposalLT12= APT_TestUtils.getProposalLineItem(Proposal.ID,bundleLine.ID,pli.ID,bundle1.ID,option2.ID);
                    proposalLT12.Apttus_QPConfig__LineType__c = 'Option';
                    proposalLT12.Apttus_QPConfig__DerivedFromId__c = bundleLine.Id;
                    proposalLT12.APT_Charge_Code_Formula__c = '7C55';
                    proposalLT12.Apttus_Proposal__Proposal__c = proposal.Id;
                    proposalLT12.Apttus_QPConfig__PrimaryLineNumber__c = 1;
                    proposalLT12.Apttus_QPConfig__ParentBundleNumber__c = 1;
                    proposalLT12.Apttus_QPConfig__ChargeType__c = 'ECI Documents';
                    //insert proposalLT12;
                    pliList.add(proposalLT12);
                    
                    Apttus_Proposal__Proposal_Line_Item__c proposalLT13= APT_TestUtils.getProposalLineItem(Proposal.ID,bundleLine.ID,pli.ID,bundle1.ID,option3.ID);
                    proposalLT13.Apttus_QPConfig__LineType__c = 'Option';
                    proposalLT13.Apttus_QPConfig__DerivedFromId__c = bundleLine.Id;
                    proposalLT13.APT_Charge_Code_Formula__c = '7C55';
                    proposalLT13.Apttus_Proposal__Proposal__c = proposal.Id;
                    proposalLT13.Apttus_QPConfig__PrimaryLineNumber__c = 1;
                    proposalLT13.Apttus_QPConfig__ParentBundleNumber__c = 1;
                    proposalLT13.Apttus_QPConfig__ChargeType__c = 'Airmail Small Parcels';
                    //insert proposalLT13;
                    pliList.add(proposalLT13);
                
                    Apttus_Proposal__Proposal_Line_Item__c proposalLT14= APT_TestUtils.getProposalLineItem(Proposal.ID,bundleLine.ID,pli.ID,bundle1.ID,option4.ID);
                    proposalLT14.Apttus_QPConfig__LineType__c = 'Option';
                    proposalLT14.Apttus_QPConfig__DerivedFromId__c = bundleLine.Id;
                    proposalLT14.APT_Charge_Code_Formula__c = '7C55';
                    proposalLT14.Apttus_Proposal__Proposal__c = proposal.Id;
                    proposalLT14.Apttus_QPConfig__PrimaryLineNumber__c = 1;
                    proposalLT14.Apttus_QPConfig__ParentBundleNumber__c = 1;
                    proposalLT14.Apttus_QPConfig__ChargeType__c = 'International Airmail Letters';
                    pliList.add(proposalLT14);
                    
                     Apttus_Proposal__Proposal_Line_Item__c proposalLT2= APT_TestUtils.getProposalLineItem(Proposal.ID,bundleLine.ID,pli.ID,bundle1.ID,null);
                    proposalLT2.APT_Charge_Code_Formula__c = '7C55';
                    proposalLT2.Apttus_Proposal__Proposal__c = proposal.Id; 
                    proposalLT2.Apttus_QPConfig__PrimaryLineNumber__c = 2;
                    //insert proposalLT2;
                    pliList.add(proposalLT2);
                    
                    insert pliList;
                    
                   //Create Proposal Product AttributeValue
                   Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue1 =APT_TestUtils.getProposalProductAttributeValue(proposalLT1.ID);
                   insert ProposalProductAttributeValue1;
                   
                   //Update Proposal Line Item with Proposal Product AttributeValue
                   List<Apttus_Proposal__Proposal_Line_Item__c> updateProposalLineItemList = new List<Apttus_Proposal__Proposal_Line_Item__c>();
                   proposalLT1.Apttus_QPConfig__AttributeValueId__c=ProposalProductAttributeValue1.ID;
                   updateProposalLineItemList.add(proposalLT1);//Update proposalLT1;
                   
                   proposalLT12.Apttus_QPConfig__AttributeValueId__c=ProposalProductAttributeValue1.ID;
                   updateProposalLineItemList.add(proposalLT12);//Update proposalLT12;
                   
                   proposalLT13.Apttus_QPConfig__AttributeValueId__c=ProposalProductAttributeValue1.ID;
                   updateProposalLineItemList.add(proposalLT13);//Update proposalLT13;
                    
                   update updateProposalLineItemList;
                   
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
                  
                  // Test.startTest();        // 10/23/19: Fix for SOQL101 error
                  //Create product Attribute value                
                    Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
                    attribute1.Category__c='CAT1';
                    attribute1.APT_Lodgement_Zone__c=logdZone.ID;               
                    attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
                    attribute1.APT_International_Letters__c = false;
                    attribute1.APT_eParcel_Lodgment__c = true;
                    insert attribute1;
                      
                    
                  // update product Attribute value               
                   //Update attribute1; 
                  
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
                    proposalLT11.Apttus_QPConfig__ParentBundleNumber__c = 1;
                    proposalLT11.APT_Charge_Code_Formula__c = '7C55';
                    proposalLT11.Apttus_Proposal__Proposal__c = proposal.Id;
                    proposalLT11.Apttus_QPConfig__PrimaryLineNumber__c = 1;
                    proposalLT11.Apttus_QPConfig__ChargeType__c = 'Airmail Parcels';
                    insert proposalLT11;
                    //Test.starttest();
                    ListPli.add(proposalLT11);
                    pliIdSet.add(proposalLT1.Id);
                    pliIdSet.add(proposalLT2.Id);
                    pliIdSet.add(proposalLT11.Id);
                    prodconfig.Apttus_Config2__Status__c = 'Finalized';
                    update prodconfig;
                    
                    set<String> setErrorMessage = new Set<String>();
                    setErrorMessage.add('error');
                    set<Id> agreementIdSet = new set<Id>();
                    agreementIdSet.add(aptContract.ID);
                    map<Id, Id> agreementByPLIMap = new map<Id, Id>();
                    agreementByPLIMap.put(proposalLT11.Id, aptContract.ID);
                    map<String, Apttus_Proposal__Proposal_Line_Item__c> primaryPLIMap = new map<String, Apttus_Proposal__Proposal_Line_Item__c>();
                    primaryPLIMap.put(proposalLT11.Apttus_Proposal__Proposal__c + APT_Constants.SEPERATOR_SIMILARITY + proposalLT11.Apttus_QPConfig__PrimaryLineNumber__c, proposalLT11);
                    //Apttus_QPConfig__ProposalUsagePriceTier__c
                    list<Apttus_QPConfig__ProposalUsagePriceTier__c> listPUPT = new list<Apttus_QPConfig__ProposalUsagePriceTier__c>();
                    
                                 
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt1 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt1.Apttus_QPConfig__Sequence__c = 1;
                    pupt1.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt1.Apttus_QPConfig__Dimension1Value__c = 'WG';
                    pupt1.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt1.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt1.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt1);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt145 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt145.Apttus_QPConfig__Sequence__c = 1;
                    pupt145.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt145.Apttus_QPConfig__Dimension1Value__c = '1';
                    pupt145.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt145.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt145.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    
                    listPUPT.add(pupt145);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt21 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt21.Apttus_QPConfig__Sequence__c = 2;
                    pupt21.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt21.Apttus_QPConfig__Dimension1Value__c = 'WG';
                    pupt21.Apttus_QPConfig__Dimension2Value__c = '200';
                    pupt21.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt21.Apttus_QPConfig__AdjustmentAmount__c = 200;
                    listPUPT.add(pupt21);
                    
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt2145 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt2145.Apttus_QPConfig__Sequence__c = 2;
                    pupt2145.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt2145.Apttus_QPConfig__Dimension1Value__c = '1';
                    pupt2145.Apttus_QPConfig__Dimension2Value__c = '200';
                    pupt2145.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt2145.Apttus_QPConfig__AdjustmentAmount__c = 200;
                    listPUPT.add(pupt2145);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt2.Apttus_QPConfig__Sequence__c = 1;
                    pupt2.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt2.Apttus_QPConfig__Dimension1Value__c = 'N0';
                    pupt2.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt2.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt2);
                    
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt2456 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt2456.Apttus_QPConfig__Sequence__c = 1;
                    pupt2456.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt2456.Apttus_QPConfig__Dimension1Value__c = '1';
                    pupt2456.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt2456.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt2456.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt2456);
                    
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt11 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt11.Apttus_QPConfig__Sequence__c = 1;
                    pupt11.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt11.Apttus_QPConfig__Dimension1Value__c = 'WG';
                    pupt11.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt11.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt11.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt11);
                    
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt1145 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt1145.Apttus_QPConfig__Sequence__c = 1;
                    pupt1145.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt1145.Apttus_QPConfig__Dimension1Value__c = '1';
                    pupt1145.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt1145.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt1145.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt1145);
                    
                    
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt12 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt12.Apttus_QPConfig__Sequence__c = 1;
                    pupt12.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt12.Apttus_QPConfig__Dimension1Value__c = 'N0';
                    pupt12.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt12.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt12.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt12);
                    
                    
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt12354 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt12354.Apttus_QPConfig__Sequence__c = 1;
                    pupt12354.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt12354.Apttus_QPConfig__Dimension1Value__c = '1';
                    pupt12354.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt12354.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt12354.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt12354);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt111 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt111.Apttus_QPConfig__Sequence__c = 1;
                    pupt111.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt111.Apttus_QPConfig__Dimension1Value__c = 'V1';
                    pupt111.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt111.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt111.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt111);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt121 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt121.Apttus_QPConfig__Sequence__c = 1;
                    pupt121.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt121.Apttus_QPConfig__Dimension1Value__c = 'V1';
                    pupt121.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt121.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt121.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt121);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt1_2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt1_2.Apttus_QPConfig__Sequence__c = 1;
                    pupt1_2.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt1_2.Apttus_QPConfig__Dimension1Value__c = 'WG';
                    pupt1_2.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt1_2.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt1_2.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt1_2);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt22 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt22.Apttus_QPConfig__Sequence__c = 2;
                    pupt22.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt22.Apttus_QPConfig__Dimension1Value__c = 'WG';
                    pupt22.Apttus_QPConfig__Dimension2Value__c = '200';
                    pupt22.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_BASE;
                    pupt22.Apttus_QPConfig__AdjustmentAmount__c = 200;
                    listPUPT.add(pupt22);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt2_2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt2_2.Apttus_QPConfig__Sequence__c = 1;
                    pupt2_2.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
                    pupt2_2.Apttus_QPConfig__Dimension1Value__c = 'N0';
                    pupt2_2.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt2_2.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                    pupt2_2.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt2_2);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt112 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt112.Apttus_QPConfig__Sequence__c = 1;
                    pupt112.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt112.Apttus_QPConfig__Dimension1Value__c = 'WG';
                    pupt112.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt112.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                    pupt112.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt112);
                    
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt11245 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt11245.Apttus_QPConfig__Sequence__c = 1;
                    pupt11245.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
                    pupt11245.Apttus_QPConfig__Dimension1Value__c = '1';
                    pupt11245.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt11245.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
                    pupt11245.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt11245);
                    
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt122 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt122.Apttus_QPConfig__Sequence__c = 1;
                    pupt122.Apttus_QPConfig__LineItemId__c = proposalLT12.ID;
                    pupt122.Apttus_QPConfig__Dimension1Value__c = 'N0';
                    pupt122.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt122.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                    pupt122.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt122);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt1112 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt1112.Apttus_QPConfig__Sequence__c = 1;
                    pupt1112.Apttus_QPConfig__LineItemId__c = proposalLT12.ID;
                    pupt1112.Apttus_QPConfig__Dimension1Value__c = 'V1';
                    pupt1112.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt1112.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
                    pupt1112.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt1112);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt1212 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt1212.Apttus_QPConfig__Sequence__c = 1;
                    pupt1212.Apttus_QPConfig__LineItemId__c = proposalLT12.ID;
                    pupt1212.Apttus_QPConfig__Dimension1Value__c = 'V1';
                    pupt1212.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt1212.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt1212.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt1212);
                    
                    Apttus_QPConfig__ProposalUsagePriceTier__c pupt12121 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
                    pupt12121.Apttus_QPConfig__Sequence__c = 1;
                    pupt12121.Apttus_QPConfig__LineItemId__c = proposalLT12.ID;
                    pupt12121.Apttus_QPConfig__Dimension1Value__c = '1';
                    pupt12121.Apttus_QPConfig__Dimension2Value__c = '100';
                    pupt12121.Apttus_QPConfig__Dimension3Value__c = 'Base';
                    pupt12121.Apttus_QPConfig__AdjustmentAmount__c = 100;
                    listPUPT.add(pupt12121);
                    
                    //insert listPUPT;
                    insert listPUPT;
                    
                                        
                    list<APT_R2T_SAP_Missing_Zone_Mapping__c> listSAPMZM = new list<APT_R2T_SAP_Missing_Zone_Mapping__c>();
                    APT_R2T_SAP_Missing_Zone_Mapping__c sapMissingZoneMapping1 = new APT_R2T_SAP_Missing_Zone_Mapping__c(Name = 'NN', APT_To_Zone__c = 'N0');
                    listSAPMZM.add(sapMissingZoneMapping1);
                    
                    APT_R2T_SAP_Missing_Zone_Mapping__c sapMissingZoneMapping2 = new APT_R2T_SAP_Missing_Zone_Mapping__c(Name = 'NR', APT_To_Zone__c = 'N0');
                    listSAPMZM.add(sapMissingZoneMapping2);
                    
                    APT_R2T_SAP_Missing_Zone_Mapping__c sapMissingZoneMapping3 = new APT_R2T_SAP_Missing_Zone_Mapping__c(Name = 'AT', APT_To_Zone__c = 'N0');
                    listSAPMZM.add(sapMissingZoneMapping3);
                    insert listSAPMZM;
                    
                    //list<APT_R2T_International_Pricing_Properties__c> listR2TIPP = new list<APT_R2T_International_Pricing_Properties__c>();
                    APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c(Name = 'R2T International Pricing Properties',
                                                                                                        APT_AIRLET_Charge_Type__c = 'Airmail Letters',
                                                                                                        APT_AIRRPI_Charge_Type__c = 'RegPost International',
                                                                                                        APT_AIRPTI_Charge_Type__c = 'Pack & Track',
                                                                                                        APT_AIRPCL_Charge_Type__c = 'Airmail Parcels',
                                                                                                        APT_AIRSMPCL_Charge_Type__c = 'Airmail Small Parcels',
                                                                                                        APT_EMSDOCT_Charge_Type__c = 'ECI Documents',
                                                                                                        APT_EMSMERCH_Charge_Type__c = 'ECI <2kgs',
                                                                                                        APT_EMSMER20_Charge_Type__c = 'ECI Merchandise');
                    insert ipp;
                    
                    
                    
                    APT_CreateSAPRatesBatch batchController = new APT_CreateSAPRatesBatch(pliIdSet, agreementIdSet, agreementByPLIMap, primaryPLIMap);
                    batchController.setErrorMessage = setErrorMessage;
                    database.executeBatch(batchController);
                    // APT_CreateSAPRatesBatch.populateDomesticSAPDetailedRate(null,null,null,null,null,setAvailableZones1,sapTeplist,null,mapProposalUsagePriceTierByZone);
                    
                    Test.stoptest();  
                    //System.assert(proposalLT1.Apttus_QPConfig__AttributeValueId__c !=null);
                   //System.assert(proposalLT2.Apttus_QPConfig__AttributeValueId__c !=null);
                  // system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);
            }
    }
}