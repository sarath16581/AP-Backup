/***
 * @author Drashtee Shah
 * @date 2016-02-29
 * @group 
 * @description This class is test class for APT_SyncContractAndRatesBatch.
 * @changelog
 * 2016-02-29 - Drashtee Shah - Created
 * 2016-08-30 - Mausam Padhiyar - modified
 * 2020-03-05 - seth.heang@auspost.com.au - Fixed SOQL101 error on Proposal Trigger
 * 2020-06-02 - shashwat.a.nath@accenture.com - Updated the method testMethod1 to include the isactive and LIMIT clause on user query 
 * 2020-03-08 - seth.heang@auspost.com.au - Update Contract test data to fulfil the updated criteria in APT_SyncContractAndRatesSchedule class, and get picked up for the rate sync
 * 2021-11-17 - Mathew Jose - Fixing the test method failures created by the introduction of key contact lookup filter on Opportuntiy (CI-194)
 * 2022-02-11  REQ2723568: API version 52 upgrade
 * 2024-01-30 - Ranjeewa Silva - Updates to existing tests to ensure test data conforms to new validation rule in APT_Sub_Account__c.
 *								 Fixed 'testMethod1' failing due to the dependency on a specific user being available in the org and active!!!
*/
@isTest
private class APT_SyncContractAndRatesBatch_Test {
    /* 
    this method will create test data for test class execution.
    */
    private static TestMethod void testMethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {       
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            APT_Sub_Account__c sub_Account2 = new APT_Sub_Account__c();
            sub_Account2.Name = 'test';
            sub_Account2.APT_Organisation__c = tempacct.Id;
            sub_Account2.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account2;
            
            List<APT_Sub_Account__c> lstsubacc = new List<APT_Sub_Account__c>();
            lstsubacc.add(sub_Account);
            lstsubacc.add(sub_Account2);
            
            Map<String,list<APT_Sub_Account__c>> mapsubacc = new Map<String,list<APT_Sub_Account__c>>();
            mapsubacc.put(String.valueOf(tempacct.Id),lstsubacc); 
            Map<String,list<APT_Sub_Account__c>> mapsubacc1 = new Map<String,list<APT_Sub_Account__c>>();
            mapsubacc1.put(String.valueOf(sub_Account2.Id),lstsubacc); 
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.KeyContact__c = con.Id;
            opp.StageName = 'Identify';
            insert opp;
            
            User u = [SELECT Id,Name,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;

            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','eParcelPostReturn','Postal Services','CAT1', 'Standard');
                 option.Apttus_Config2__ConfigurationType__c='Option';
                 option.APT_Sync_with_Opportunity__c=true;
                 option.APT_International_Pricing__c = false;
                 insert option;
                 
                 Product2 option8 = APT_TestUtils.createDomesticProduct('International Digital PCMS Bundle','InternationalDigitalPCMSBundle','Postal Services','CAT1', 'Standard');
                 option8.Apttus_Config2__ConfigurationType__c='Bundle';
                 option8.APT_Sync_with_Opportunity__c=true;
                 option8.APT_International_Pricing__c = false;
                 insert option8;
                 system.debug('option8---->'+option8);
                 
                 
                 //Create Option product 2
                 Product2 option2 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelIdentityonDeliveryService','Postal Services','CAT1', 'Standard');
                 option2.Apttus_Config2__ConfigurationType__c='Option';
                 option2.APT_Sync_with_Opportunity__c=true;
                 option2.APT_International_Pricing__c = false;
                 insert option2;
                 
                 //Create PriceBookEntry
                 Id pricebookId = Test.getStandardPricebookId();             
                 PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
                 insert standardPrice;
                 
                 
                 Id pricebookId1 = Test.getStandardPricebookId();             
                 PricebookEntry standardPrice1 = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option8.ID);            
                 insert standardPrice1;
                 
                 //Create Price list Item
                 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
                 insert pli;
                 //Create Option PLI
                 Apttus_Config2__PriceListItem__c optpli= APT_TestUtils.createPriceListItem(priceList.ID,option.ID,'C Manufacturing','BAND 2');
                 insert optpli;
                 
                 Apttus_Config2__PriceListItem__c optpli1= APT_TestUtils.createPriceListItem(priceList.ID,option8.ID,'C Manufacturing','BAND 2');
                 insert optpli1;
                 
                 //Create Option PLI 2
                 Apttus_Config2__PriceListItem__c optpli2= APT_TestUtils.createPriceListItem(priceList.ID,option8.ID,'C Manufacturing','BAND 2');
                 insert optpli2;
                 
                 //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 
                 insert Proposal;
                 
                
                 // Fixed SOQL101 Error
                 /*Apttus_Proposal__Proposal__c Proposal2= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal2.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal2.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal2.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal2;*/
                 
                 List<Apttus_Proposal__Proposal__c> lstprop = new List<Apttus_Proposal__Proposal__c>();
                 lstprop.add(Proposal);
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Option Line Item
            Apttus_Config2__LineItem__c optLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 2, false,//Config id, grpid, LineNum, isPrimary
            2,'Option', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            option.Id, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, optpli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            optLine.Apttus_Config2__AllowManualAdjustment__c = true;
            optLine.Apttus_Config2__NetPrice__c = 5225;
            optLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            optLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert optLine;
            
            
            Apttus_Config2__LineItem__c optLine8 = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 2, false,//Config id, grpid, LineNum, isPrimary
            2,'Option8', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            option8.Id, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, optpli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            optLine8.Apttus_Config2__AllowManualAdjustment__c = true;
            optLine8.Apttus_Config2__NetPrice__c = 5225;
            optLine8.Apttus_Config2__PrimaryLineNumber__c = 1;
            optLine8.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert optLine8;
            
            //Create Option Line Item 2
            Apttus_Config2__LineItem__c optLine2 = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 3, false,//Config id, grpid, LineNum, isPrimary
            3,'Option', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            option2.Id, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, optpli2.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            optLine2.Apttus_Config2__AllowManualAdjustment__c = true;
            optLine2.Apttus_Config2__NetPrice__c = 5225;
            optLine2.Apttus_Config2__PrimaryLineNumber__c = 1;
            optLine2.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert optLine2;
            
             //Create Product Attribute value
            Apttus_Config2__ProductAttributeValue__c prntpav = APT_TestUtils.GetAttributeValue(bundleLine.Id,'High',true,true,true,'5674','Industry',true,true);
            prntpav.APT_Min_Transit_Cover_Amount_Per_Article__c = 45.4;
            prntpav.APT_Zone_1Digital_Dispersion__c=3.4;
            insert prntpav;
            system.debug('prntpav---->'+prntpav);
            
            set<String> setPLIId = new set<String>();
            
          
           //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.APT_Charge_Code_Formula__c = 'some';
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            //proposalLT1.Apttus_QPConfig__AttributeValueId__c= prntpav.Id;
            insert proposalLT1;
            
            Apttus_Proposal__Proposal_Line_Item__c proposalLT11= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,option8.id,option.id);
            proposalLT11.Apttus_QPConfig__Quantity2__c=3;
            proposalLT11.APT_Charge_Code_Formula__c = 'some';
            proposalLT11.Apttus_QPConfig__NetPrice__c=10;
            proposalLT11.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT11.Apttus_Proposal__Product__c=option8.id;
            proposalLT11.Apttus_QPConfig__OptionId__c = null;
            proposalLT11.Apttus_QPConfig__ParentBundleNumber__c = 1;
            proposalLT1.Apttus_QPConfig__AttributeValueId__c= prntpav.Id;
            insert proposalLT11;
            
            setPLIId.add(proposalLT1.Id);
            
            List<Apttus_Proposal__Proposal_Line_Item__c> lstoptptLT = new List<Apttus_Proposal__Proposal_Line_Item__c>();
            
            
            //Create Option Proposal Line Item
            Apttus_Proposal__Proposal_Line_Item__c proposaloptLT1= APT_TestUtils.getProposalLineItem(Proposal.id,optLine.id,optpli.id,bundle1.id,option.id);
            proposaloptLT1.Apttus_QPConfig__Quantity2__c=3;
            proposaloptLT1.APT_Charge_Code_Formula__c = 'some';
            proposaloptLT1.Apttus_QPConfig__NetPrice__c=10;
            proposaloptLT1.Apttus_QPConfig__IsPrimaryLine__c = false;
            proposaloptLT1.Apttus_QPConfig__OptionId__c = option.id;
            proposaloptLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            proposaloptLT1.Apttus_QPConfig__ChargeType__c = 'Parcel Post Call for Returns - Delivery Fee (per article)';
            lstoptptLT.add(proposaloptLT1);
            
            //Create Option Proposal Line Item 2
            Apttus_Proposal__Proposal_Line_Item__c proposaloptLT2= APT_TestUtils.getProposalLineItem(Proposal.id,optLine2.id,optpli2.id,bundle1.id,option2.id);
            proposaloptLT2.Apttus_QPConfig__Quantity2__c=3;
            proposaloptLT2.APT_Charge_Code_Formula__c = 'some';
            proposaloptLT2.Apttus_QPConfig__NetPrice__c=10;
            proposaloptLT2.Apttus_QPConfig__IsPrimaryLine__c = false;
            proposaloptLT2.Apttus_QPConfig__OptionId__c = option2.id;
            proposaloptLT2.Apttus_QPConfig__ParentBundleNumber__c = 1;
            proposaloptLT2.Apttus_QPConfig__ChargeType__c = 'Parcel Post Call for Returns - Pick-up Fee (per request)';
            lstoptptLT.add(proposaloptLT2);
            insert lstoptptLT;
            
            for(Apttus_Proposal__Proposal_Line_Item__c pli1 : lstoptptLT) {
                setPLIId.add(pli1.Id);
            }
            
            test.startTest();        // 10/23/19: Fix for SOQL101 error
            //APT_SAP_Group_Template__c
            APT_SAP_Group_Template__c sgt = new APT_SAP_Group_Template__c();
            sgt.Name = 'test';
            sgt.APT_Charge_Code__c = 'some';
            sgt.APT_Price_Value_Description__c = '100';
            sgt.APT_Price_Value__c = '100';
            insert sgt;
            
            APT_SAP_Group_Template__c sgt2 = new APT_SAP_Group_Template__c();
            sgt2.Name = 'test';
            sgt2.APT_Charge_Code__c = 'some';
            sgt2.APT_Price_Value_Description__c = '100';
            sgt2.APT_Price_Value__c = '100';
            insert sgt2;
            
            String sgtid = sgt.Id; 
            sgt = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgtid];
                    
            String sgt2id = sgt2.Id; 
            sgt2 = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgt2id];
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.APT_Min_Transit_Cover_Amount_Per_Article__c = 45.4;
            attribute1.APT_Domestic_Customer__c = 'No';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.Id;
            update proposalLT1;
           // proposalLT1.Apttus_QPConfig__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c = attribute1.APT_Min_Transit_Cover_Amount_Per_Article__c;
            //update proposalLT1;
            
            
            List<Apttus_Proposal__Proposal_Line_Item__c> lstoptpli = [Select Id,Apttus_QPConfig__ChargeType__c,Apttus_QPConfig__OptionId__r.ProductCode,Apttus_QPConfig__NetPrice__c from Apttus_Proposal__Proposal_Line_Item__c where Apttus_QPConfig__OptionId__c != null];
            
           
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            insert pupt;
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            insert pupt2;
            
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            aptContract.Apttus__Primary_Contact__c = con.ID;
            
            // Test.StartTest();
            insert aptContract;
           
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Lodgement_Point_Ids__c = '1,2,3,4';
            aos.APT_International_Lodgement_Point_Ids__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Maximum_Transit_Cover__c = 566.34;
            r2tSystemProperties.APT_Transit_Cover_Percentage_Non_Bundled__c = 12;
            r2tSystemProperties.APT_Transit_Cover_Percentage_Bundled__c = 15;
            r2tSystemProperties.APT_Customer_Collect_Location_Fee__c = 454;
            r2tSystemProperties.APT_Day_Specific_Delivery_Fee__c = 44;
            r2tSystemProperties.APT_Date_Specific_Delivery_Fee__c = 484;
            r2tSystemProperties.APT_Date_Embargo_Fee__c = 434;
            r2tSystemProperties.APT_AM_PM_Delivery_Window_Fee__c = 4345;
            r2tSystemProperties.APT_AM_PM_Delivery_Window_Day_Date_Fee__c = 345;
            r2tSystemProperties.APT_Two_Hour_Delivery_Window_Fee__c = 349;
            r2tSystemProperties.APT_Two_Hour_Delivery_Window_DayDate_Fee__c = 456;
            r2tSystemProperties.APT_Express_Courier_UpTo_2KG_Per_Item_UK__c = 256;
            r2tSystemProperties.APT_Express_Courier_Up_To_2KG_Per_KG_UK__c = 356;
            r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_Item_UK__c = 456;
            r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_KG_UK__c = 556;
            r2tSystemProperties.APT_Express_Courier_UpTo_2KG_Per_Item_NZ__c = 256;
            r2tSystemProperties.APT_Express_Courier_Up_To_2KG_Per_KG_NZ__c = 356;
            r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_Item_NZ__c = 456;
            r2tSystemProperties.APT_Express_Courier_Over_2KG_Per_KG_NZ__c = 556;
            r2tSystemProperties.APT_Airmail_Rates_Up_To_2KG_Per_Item_NZ__c = 256;
            r2tSystemProperties.APT_Airmail_Rates_Up_To_2KG_Per_KG_NZ__c = 356;
            r2tSystemProperties.APT_Airmail_Rates_Over_2KG_Per_Item_NZ__c = 456;
            r2tSystemProperties.APT_Airmail_Rates_Over_2KG_Per_KG_NZ__c = 556;
            r2tSystemProperties.APT_Zone_1Digital_Dispersion__c=7.60;
            
            insert r2tSystemProperties;
            system.debug('r2tSystemProperties--->'+r2tSystemProperties);
            
            APT_Agreement_Lodgement_Point__c alp = APT_TestUtils.createLodgementPoint(tempacct.Id, aptContract.id, network1.Id, null, product.Id, null);
            alp.APT_Sub_Account__c = sub_Account2.id;
            
            insert alp;
            APT_SAP_Rate__c ObjNew1 = new APT_SAP_Rate__c(APT_Proposal_Line_Item__c = lstoptpli[0].ID, APT_Apttus_Contract__c = aptContract.ID);
            insert ObjNew1;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            
            //APT_SyncContractAndRatesBatch.syncContractAndRatesResultWrapper wrapper1 = new APT_SyncContractAndRatesBatch.syncContractAndRatesResultWrapper();
            //wrapper1.strResponse = '';
           // wrapper1.contractNumber = '';
           // wrapper1.SAPERPContractNumber = '';
           // wrapper1.businessReferenceId = '';
            
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            APT_SyncContractAndRatesBatch.populateAccount(tempacct,alp,mapsubacc,APT_Constants.PAYMENT_METHOD_CASH_ACCOUNT);
            APT_SyncContractAndRatesBatch.populateAccount(tempacct,alp,mapsubacc,'Credit Card');
            APT_SyncContractAndRatesBatch.populateSubAccount(tempacct,alp,mapsubacc);
            APT_SyncContractAndRatesBatch.populateSalesRepDetails(u);
            APT_SyncContractAndRatesBatch.populateFeaturesDetails('RateCard',proposalLT1,lstoptpli,r2tSystemProperties);
            
            System.debug(LoggingLevel.error, '  ** proposalLT1.Apttus_QPConfig__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c   '  + proposalLT1.Apttus_QPConfig__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c );
            System.debug(LoggingLevel.error, '  ** attribute1   '  + attribute1 );
            System.debug(LoggingLevel.error, '  ** proposalLT1    '  + proposalLT1  );
            
            APT_SyncContractAndRatesBatch.populateTransitCoverDetails(APT_Constants.RATE_CARD_TYPE_DOMESTIC,proposalLT1,r2tSystemProperties);
            lstoptpli.get(0).Apttus_QPConfig__OptionId__r.ProductCode = APT_Constants.PRODUCT_CODE_MISSING_MANIFEST_FEE;
            lstoptpli.get(1).Apttus_QPConfig__OptionId__r.ProductCode = APT_Constants.PRODUCT_CODE_ADMINISTRATIVE_FEE;
            //lstoptpli = [Select Id,Apttus_QPConfig__ChargeType__c,Apttus_QPConfig__OptionId__r.ProductCode,Apttus_QPConfig__NetPrice__c from Apttus_Proposal__Proposal_Line_Item__c where Apttus_QPConfig__OptionId__c != null];
            APT_SyncContractAndRatesBatch.populateStandardCharges(APT_Constants.RATE_CARD_TYPE_INTERNATIONAL,lstoptpli,r2tSystemProperties,proposalLT1);
            lstoptpli.get(0).Apttus_QPConfig__OptionId__r.ProductCode = APT_Constants.PRODUCT_CODE_MINIMUM_COLLECTION_VALUE;
            lstoptpli.get(1).Apttus_QPConfig__OptionId__r.ProductCode = APT_Constants.PRODUCT_CODE_RETURN_TO_SENDER;
            APT_SyncContractAndRatesBatch.populateStandardCharges(APT_Constants.RATE_CARD_TYPE_INTERNATIONAL,lstoptpli,r2tSystemProperties,proposalLT1);
            APT_SyncContractAndRatesBatch.populateContractDetails(aptContract,lstprop,aos);
            aos.APT_Parcel__c = false;
            update aos;
            APT_SyncContractAndRatesBatch.populateContractDetails(aptContract,lstprop,aos);
            aos.APT_International_Postal__c = false;
            aos.APT_Parcel__c = true;
            update aos;
            Test.StopTest();
            APT_SyncContractAndRatesBatch.populateContractDetails(aptContract,lstprop,aos);
            APT_SyncContractAndRatesBatch.populateExpressCourierRates(r2tSystemProperties,'UK');
            APT_SyncContractAndRatesBatch.populateExpressCourierRates(r2tSystemProperties,'NZ');
            APT_SyncContractAndRatesBatch.populateAirmailRates(r2tSystemProperties);
			// this test is failing as the test is expecting an Active user named 'Natasha Adelson' !!!
			//User user=[select id,name,Phone,Title,FirstName,LastName,MiddleName,MobilePhone,Fax,Email from user where name='Natasha Adelson' AND isactive =true LIMIT 1];
			User user = ApplicationTestDataFactory.getUsers(1, true)[0];
            APT_SyncContractAndRatesBatch.populateContactDetails(user,null);
            APT_SyncContractAndRatesBatch.populateName(user,null);
            APT_SyncContractAndRatesBatch.populateSubAccount(null,alp,mapsubacc1);
            //APT_SyncContractAndRatesBatch.populateZoneDispersion(proposalLT11,r2tSystemProperties);
            Database.executeBatch(scrb);
        }
            
    }
     /* 
    this method will create test data for test class execution.
    */   
    private static TestMethod void testMethod2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {            
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            APT_Sub_Account__c sub_Account2 = new APT_Sub_Account__c();
            sub_Account2.Name = 'test';
            sub_Account2.APT_Organisation__c = tempacct.Id;
            sub_Account2.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account2;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
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
                 
                 Test.StartTest(); // Fixed SOQL101 error on Proposal trigger
                 //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 Apttus_Proposal__Proposal__c Proposal2= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal2.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal2.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal2.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal2;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;                  
          
           //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            
            List<Apttus_QPConfig__ProposalUsagePriceTier__c> puptlist = new List<Apttus_QPConfig__ProposalUsagePriceTier__c>();
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt);
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt2);
            
            insert puptlist;
                   
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            aptContract.APT_Contract_Type__c = 'Renewal Contract';
            // Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
        }    
        
    }
        /* 
    this method will create test data for test class execution.
    */
    private static TestMethod void testMethodInternational() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {          
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;            
            
            Account tempacct = APT_TestUtils.createOrganisation();
            tempacct.Owner = u;
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
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
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            List<Apttus_QPConfig__ProposalUsagePriceTier__c> puptlist = new List<Apttus_QPConfig__ProposalUsagePriceTier__c>();
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt);
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt2);
            
            insert puptlist;
            
            
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            aptContract.Apttus__Contract_End_Date__c = System.today() + 100;
            Test.StartTest();
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
           system.assert(agreementIdSet.size() > 0); 
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
        }
            
        }
    /* 
    this method will create test data for test class execution.
    */
    private static TestMethod void testMethodInternationalElse() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {           
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
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
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = '3,000 - 4,999';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            List<Apttus_QPConfig__ProposalUsagePriceTier__c> puptlist = new List<Apttus_QPConfig__ProposalUsagePriceTier__c>();
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt);
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt2);
            
            insert puptlist;
            
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
        }
    }
    /* 
    this method will create test data for test class execution.
    */            
    private static TestMethod void testMethodInternational2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {           
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;            
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
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
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            List<Apttus_QPConfig__ProposalUsagePriceTier__c> puptlist = new List<Apttus_QPConfig__ProposalUsagePriceTier__c>();
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt);
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt2);
            
            insert puptlist;
            
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
    
        }
    }
    /* 
    this method will create test data for test class execution.
    */    
    private static TestMethod void testMethodInternational2Option() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {         
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;            
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
            //create international product
             Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
             bundle1.APT_Sync_with_Opportunity__c=true;
             bundle1.APT_Is_Charge_Account_Product__c = true;
             bundle1.APT_Is_Cash_Account_Product__c = false;
             insert bundle1;
             
             //Create Option product
             Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','ECIPCL','Postal Services','CAT1', 'Standard');
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
             Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
             //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
             Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
             Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
             Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
             insert Proposal;
             
             //Create Product Configuration             
             Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
             proposal.Id, 'Proposal',
             'Ad Hoc',priceList.Id, null,
             'Finalized',
             null, Datetime.now(), true);
             prodconfig.Apttus_Config2__Status__c = 'Finalized';
             insert prodconfig;
                 
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = option.ID;
            proposalLT1.Apttus_QPConfig__ChargeType__c = 'License Fee';
            //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            List<Apttus_QPConfig__ProposalUsagePriceTier__c> puptlist = new List<Apttus_QPConfig__ProposalUsagePriceTier__c>();
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt);
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt2);
            
            insert puptlist;
            
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c = 'License Fee';
            r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c = 'License Fee';
            r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c = 'License Fee';
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch.syncContractAndRatesResultWrapper wrapperSyncRate = new APT_SyncContractAndRatesBatch.syncContractAndRatesResultWrapper();
            String strResponse = wrapperSyncRate.strResponse;
            String contractNumber = wrapperSyncRate.contractNumber;
            String SAPERPContractNumber = wrapperSyncRate.SAPERPContractNumber;
            String businessReferenceId = wrapperSyncRate.businessReferenceId;
            
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
        }
    }
    /* 
    this method will create test data for test class execution.
    */    
    private static TestMethod void testMethodInternational2Option2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {         
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','AIRPCL','Postal Services','CAT1', 'Standard');
                 option.Apttus_Config2__ConfigurationType__c='Option';
                 option.APT_Sync_with_Opportunity__c=true;
                 option.APT_International_Pricing__c = false;
                 option.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
                 insert option;
                 
                 Product2 option1 = APT_TestUtils.createDomesticProduct('International Digital PCMS Bundle','InternationalDigitalPCMSBundle','Postal Services','CAT1', 'Standard');
                 option1.Apttus_Config2__ConfigurationType__c='Bundle';
                 option1.APT_Sync_with_Opportunity__c=true;
                 option1.APT_International_Pricing__c = false;
                 option1.ProductCode = APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE;
                 insert option1;
                 
                 //Create PriceBookEntry
                 Id pricebookId = Test.getStandardPricebookId();             
                 PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
                 insert standardPrice;
                 
                 
                 
                 //Create Price list Item
                 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
                 insert pli;
                 
                 //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = option.ID;
            proposalLT1.Apttus_QPConfig__ChargeType__c = 'License Fee';
            proposalLT1.Apttus_Proposal__Product__c = option.ID;
            //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT1;
            
            Apttus_Proposal__Proposal_Line_Item__c proposalLT11= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option1.id);
            proposalLT11.Apttus_QPConfig__Quantity2__c=3;
            proposalLT11.Apttus_QPConfig__NetPrice__c=10;
            proposalLT11.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT11.Apttus_QPConfig__OptionId__c = option.ID;
            proposalLT11.Apttus_QPConfig__ChargeType__c = 'License Fee';
            proposalLT11.Apttus_Proposal__Product__c = option.ID;
            //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT11;
            
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            
            set<String> setPLIId1 = new set<String>();
            setPLIId.add(proposalLT11.Id);
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT2= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT2.Apttus_QPConfig__Quantity2__c=3;
            proposalLT2.Apttus_QPConfig__NetPrice__c=10;
            proposalLT2.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT2.Apttus_QPConfig__OptionId__c = option.ID;
            proposalLT2.Apttus_QPConfig__ChargeType__c = 'License Fee';
            proposalLT2.Apttus_Proposal__Product__c = option.ID;
            //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT2;
            setPLIId.add(proposalLT2.id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute11 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute11.Revenue_Committment__c = 'Less than $3,000';
            attribute11.Apttus_QPConfig__LineItemId__c = proposalLT11.ID;
            attribute11.APT_Volume_Data__c = 'Yes';
            attribute11.APT_Minimum_Quantity__c = 0;
            insert attribute11;
            
            proposalLT11.Apttus_QPConfig__AttributeValueId__c = attribute11.ID;
            update proposalLT11;
            
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            List<Apttus_QPConfig__ProposalUsagePriceTier__c> puptlist = new List<Apttus_QPConfig__ProposalUsagePriceTier__c>();
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt);
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt2);
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt3 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt3.Apttus_QPConfig__Sequence__c = 1;
            pupt3.Apttus_QPConfig__LineItemId__c = proposalLT2.ID;
            pupt3.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt3.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt3.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt3.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt3);
            
            insert puptlist;
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            
            Test.StartTest();
            
            insert aptContract;
            
            //Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
             
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            //r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'License Fee';
            r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c = 'License Fee';
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            
            //test.startTest();
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
            
            test.stopTest();
        }
            
    }
    
    /* 
    this method will create test data for test class execution.
    */    
    private static TestMethod void testMethodInternational2Option3() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {         
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','AIRPCL','Postal Services','CAT1', 'Standard');
                 option.Apttus_Config2__ConfigurationType__c='Option';
                 option.APT_Sync_with_Opportunity__c=true;
                 option.APT_International_Pricing__c = false;
                 option.ProductCode = APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE;
                 insert option;
                 
                 //Create PriceBookEntry
                 Id pricebookId = Test.getStandardPricebookId();             
                 PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
                 insert standardPrice;
                 
                 //Create Price list Item
                 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
                 insert pli;
                 
                 //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = option.ID;
            proposalLT1.Apttus_QPConfig__ChargeType__c = 'License Fee';
            proposalLT1.Apttus_Proposal__Product__c = option.ID;
            //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT2= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT2.Apttus_QPConfig__Quantity2__c=3;
            proposalLT2.Apttus_QPConfig__NetPrice__c=10;
            proposalLT2.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT2.Apttus_QPConfig__OptionId__c = option.ID;
            proposalLT2.Apttus_QPConfig__ChargeType__c = 'License Fee';
            proposalLT2.Apttus_Proposal__Product__c = option.ID;
            //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT2;
            setPLIId.add(proposalLT2.id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Minimum_Quantity__c = 0;
            attribute1.APT_eParcel_Lodgment__c = false;
            attribute1.APT_International_Letters__c = true;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            List<Apttus_QPConfig__ProposalUsagePriceTier__c> puptlist = new List<Apttus_QPConfig__ProposalUsagePriceTier__c>();
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt);
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt2);
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt3 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt3.Apttus_QPConfig__Sequence__c = 1;
            pupt3.Apttus_QPConfig__LineItemId__c = proposalLT2.ID;
            pupt3.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt3.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt3.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt3.Apttus_QPConfig__AdjustmentAmount__c = 100;
            puptlist.add(pupt3);
            
            insert puptlist;
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            //r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'License Fee';
            r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c = 'License Fee';
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
        }
            
    }
    
    /* 
    this method will create test data for test class execution.
    */    
    private static TestMethod void testMethodInternational3() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {       
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
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
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.APT_Charge_Code_Formula__c = 'some';
            //proposalLT1.Apttus_QPConfig__ChargeType__c = 'Parcel Post Call for Returns - Delivery Fee (per article)';
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_eParcel_Lodgment__c = false;
            attribute1.APT_International_Letters__c = true;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Zone_1_Dispersion__c = 10;
            attribute1.APT_Zone_2_Dispersion__c = 10;
            attribute1.APT_Zone_3_Dispersion__c = 10;
            attribute1.APT_Zone_4_Dispersion__c = 10;
            attribute1.APT_Zone_5_Dispersion__c = 10;
            attribute1.APT_Zone_6_Dispersion__c = 10;
            attribute1.APT_Zone_7_Dispersion__c = 10;
            attribute1.APT_Zone_8_Dispersion__c = 10;
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            //APT_SAP_Group_Template__c
            List<APT_SAP_Group_Template__c> sgtlist  = new  List<APT_SAP_Group_Template__c> ();
             
            APT_SAP_Group_Template__c sgt = new APT_SAP_Group_Template__c();
            sgt.Name = 'test';
            sgt.APT_Charge_Code__c = 'some';
            sgt.APT_Price_Value_Description__c = '100';
            sgt.APT_Price_Value__c = '100';
            
            sgtlist.add(sgt);
            
            APT_SAP_Group_Template__c sgt2 = new APT_SAP_Group_Template__c();
            sgt2.Name = 'test';
            sgt2.APT_Charge_Code__c = 'some';
            sgt2.APT_Price_Value_Description__c = '100';
            sgt2.APT_Price_Value__c = '100';
            sgtlist.add(sgt2);
            insert sgtlist;
            
            String sgtid = sgtlist[0].Id; 
            sgt = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgtid];
                    
            String sgt2id = sgtlist[1].Id; 
            sgt2 = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgt2id];
                    
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            pupt.Apttus_QPConfig__UsageRate__c = 6;
            insert pupt;
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            pupt2.Apttus_QPConfig__UsageRate__c = 6;
            insert pupt2;
            
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
           // r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c = 'Parcel Post Call for Returns - Delivery Fee (per article)';
           // r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c = 'Parcel Post Call for Returns - Delivery Fee (per article)';
           // r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c = 'Parcel Post Call for Returns - Delivery Fee (per article)';
           // r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Parcel Post Call for Returns - Delivery Fee (per article)';
          //  r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c = 'Parcel Post Call for Returns - Delivery Fee (per article)';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Zone_1_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_2_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_3_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_4_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_5_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_6_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_7_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_8_Dispersion__c = 1;
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            APT_SAP_SyncContractAndRatesService.DetailedRateType dtldrate = new APT_SAP_SyncContractAndRatesService.DetailedRateType();
            dtldrate.BaseRate = 12.25;
            dtldrate.SubsequentRate = null;
            
            
            //TODO:
            //APT_SyncContractAndRatesBatch.populateDetailedRate(dtldrate,sgt,pupt);
            
            
            APT_SAP_SyncContractAndRatesService.ProductType prod= new  APT_SAP_SyncContractAndRatesService.ProductType();
            Database.executeBatch(scrb);
            APT_SAP_SyncContractAndRatesService.SubProductDetailsType Subproddetails = new  APT_SAP_SyncContractAndRatesService.SubProductDetailsType();
            //APT_SyncContractAndRatesBatch.populateSubProductDetails(Subproddetails,proposalLT1,prod,r2tInternationalPricingProperties);
            bundle1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS;
            update bundle1;
            //APT_SyncContractAndRatesBatch.populateSubProductDetails(Subproddetails,proposalLT1,prod,r2tInternationalPricingProperties);
            bundle1.ProductCode = APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT;
            update bundle1;
            //APT_SyncContractAndRatesBatch.populateSubProductDetails(Subproddetails,proposalLT1,prod,r2tInternationalPricingProperties);
        }
            
    }
    /* 
    this method will create test data for test class execution.
    */    
private static TestMethod void testMethodInternational4() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {       
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
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
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.APT_Charge_Code_Formula__c = 'some';
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_eParcel_Lodgment__c = false;
            attribute1.APT_International_Letters__c = true;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            //APT_SAP_Group_Template__c
            List<APT_SAP_Group_Template__c> sgtlist  = new  List<APT_SAP_Group_Template__c> ();
             
            APT_SAP_Group_Template__c sgt = new APT_SAP_Group_Template__c();
            sgt.Name = 'test';
            sgt.APT_Charge_Code__c = 'some';
            sgt.APT_Price_Value_Description__c = '100';
            sgt.APT_Price_Value__c = '100';
            
            sgtlist.add(sgt);
            
            APT_SAP_Group_Template__c sgt2 = new APT_SAP_Group_Template__c();
            sgt2.Name = 'test';
            sgt2.APT_Charge_Code__c = 'some';
            sgt2.APT_Price_Value_Description__c = '100';
            sgt2.APT_Price_Value__c = '100';
            sgtlist.add(sgt2);
            insert sgtlist;
            
            String sgtid = sgtlist[0].Id; 
            sgt = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgtid];
                    
            String sgt2id = sgtlist[1].Id; 
            sgt2 = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgt2id];
            
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            pupt.Apttus_QPConfig__UsageRate__c = 6;
            insert pupt;
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_SUBSEQUENT;
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            pupt2.Apttus_QPConfig__UsageRate__c = 6;
            insert pupt2;
            
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            APT_SAP_SyncContractAndRatesService.DetailedRateType dtldrate = new APT_SAP_SyncContractAndRatesService.DetailedRateType();
            dtldrate.BaseRate = 12.25;
            dtldrate.SubsequentRate = null;
            
            //TODO:
            //APT_SyncContractAndRatesBatch.populateDetailedRate(dtldrate,sgt,pupt);
            
            Database.executeBatch(scrb);
        }
        
    }
     /* 
    this method will create test data for test class execution.
    */   
    private static TestMethod void testMethodInternational5() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {   
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            opp.type = 'Existing Customer';
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
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
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.APT_Charge_Code_Formula__c = 'some';
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_eParcel_Lodgment__c = false;
            attribute1.APT_International_Letters__c = true;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
             //APT_SAP_Group_Template__c
            List<APT_SAP_Group_Template__c> sgtlist  = new  List<APT_SAP_Group_Template__c> ();
             
            APT_SAP_Group_Template__c sgt = new APT_SAP_Group_Template__c();
            sgt.Name = 'test';
            sgt.APT_Charge_Code__c = 'some';
            sgt.APT_Price_Value_Description__c = '100';
            sgt.APT_Price_Value__c = '100';
            
            sgtlist.add(sgt);
            
            APT_SAP_Group_Template__c sgt2 = new APT_SAP_Group_Template__c();
            sgt2.Name = 'test';
            sgt2.APT_Charge_Code__c = 'some';
            sgt2.APT_Price_Value_Description__c = '100';
            sgt2.APT_Price_Value__c = '100';
            sgtlist.add(sgt2);
            insert sgtlist;
            
            String sgtid = sgtlist[0].Id; 
            sgt = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgtid];
                    
            String sgt2id = sgtlist[1].Id; 
            sgt2 = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgt2id];
                    
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            pupt.Apttus_QPConfig__UsageRate__c = 6;
            insert pupt;
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = APT_Constants.DOMESTIC_PRICE_TYPE_PER_KG;
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            pupt2.Apttus_QPConfig__UsageRate__c = 6;
            insert pupt2;
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            APT_SAP_SyncContractAndRatesService.DetailedRateType dtldrate = new APT_SAP_SyncContractAndRatesService.DetailedRateType();
            dtldrate.BaseRate = 12.25;
            dtldrate.SubsequentRate = null;
            
            //TODO:
            //APT_SyncContractAndRatesBatch.populateDetailedRate(dtldrate,sgt,pupt);
            
            Database.executeBatch(scrb);
        }
    }
    
    /* 
    this method will create test data for test class execution.
    */    
    private static TestMethod void testMethodInternational6() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {      
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
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
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.APT_Charge_Code_Formula__c = 'some';
            insert proposalLT1;
            
            
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_eParcel_Lodgment__c = false;
            attribute1.APT_International_Letters__c = true;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Zone_1_Dispersion__c = 10;
            attribute1.APT_Zone_2_Dispersion__c = 10;
            attribute1.APT_Zone_3_Dispersion__c = 10;
            attribute1.APT_Zone_4_Dispersion__c = 10;
            attribute1.APT_Zone_5_Dispersion__c = 10;
            attribute1.APT_Zone_6_Dispersion__c = 10;
            attribute1.APT_Zone_7_Dispersion__c = 10;
            attribute1.APT_Zone_8_Dispersion__c = 10;
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            //APT_SAP_Group_Template__c
            List<APT_SAP_Group_Template__c> sgtlist  = new  List<APT_SAP_Group_Template__c> ();
            APT_SAP_Group_Template__c sgt = new APT_SAP_Group_Template__c();
            sgt.Name = 'test';
            sgt.APT_Charge_Code__c = 'some';
            sgt.APT_Price_Value_Description__c = '100';
            sgt.APT_Price_Value__c = '100';
            
            sgtlist.add(sgt);
            
            APT_SAP_Group_Template__c sgt2 = new APT_SAP_Group_Template__c();
            sgt2.Name = 'test';
            sgt2.APT_Charge_Code__c = 'some';
            sgt2.APT_Price_Value_Description__c = '100';
            sgt2.APT_Price_Value__c = '100';
            sgtlist.add(sgt2);
            insert sgtlist;
            
            String sgtid = sgtlist[0].Id; 
            sgt = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgtid];
                    
            String sgt2id = sgtlist[1].Id; 
            sgt2 = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgt2id];
                    
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            insert pupt;
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            insert pupt2;
            
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Zone_1_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_2_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_3_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_4_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_5_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_6_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_7_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_8_Dispersion__c = 1;
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
        }
            
    }
    /* 
    this method will create test data for test class execution.
    */    
    private static TestMethod void testMethodInternational6LodgementPoint() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;
            
            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
                 Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;
                 
                 //Create Option product
                 Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
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
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.APT_Charge_Code_Formula__c = 'some';
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_eParcel_Lodgment__c = true;
            attribute1.APT_International_Letters__c = true;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Zone_1_Dispersion__c = 10;
            attribute1.APT_Zone_2_Dispersion__c = 10;
            attribute1.APT_Zone_3_Dispersion__c = 10;
            attribute1.APT_Zone_4_Dispersion__c = 10;
            attribute1.APT_Zone_5_Dispersion__c = 10;
            attribute1.APT_Zone_6_Dispersion__c = 10;
            attribute1.APT_Zone_7_Dispersion__c = 10;
            attribute1.APT_Zone_8_Dispersion__c = 10;
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            List<APT_SAP_Group_Template__c> sgtlist = new List<APT_SAP_Group_Template__c>();
            
            //APT_SAP_Group_Template__c
            APT_SAP_Group_Template__c sgt = new APT_SAP_Group_Template__c();
            sgt.Name = 'test';
            sgt.APT_Charge_Code__c = 'some';
            sgt.APT_Price_Value_Description__c = '100';
            sgt.APT_Price_Value__c = '100';
            
            sgtlist.add(sgt);
            
            APT_SAP_Group_Template__c sgt2 = new APT_SAP_Group_Template__c();
            sgt2.Name = 'test';
            sgt2.APT_Charge_Code__c = 'some';
            sgt2.APT_Price_Value_Description__c = '100';
            sgt2.APT_Price_Value__c = '100';
            sgtlist.add(sgt2);
            insert sgtlist;
            
            String sgtid = sgtlist[0].Id; 
            sgt = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgtid];
                    
            String sgt2id = sgtlist[1].Id; 
            sgt2 = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgt2id];
                    
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            insert pupt;
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            insert pupt2;
            
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Zone_1_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_2_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_3_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_4_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_5_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_6_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_7_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_8_Dispersion__c = 1;
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
        }
    }
     /* 
    this method will create test data for test class execution.
    */    
    private static TestMethod void testMethodInternationalPCMS() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
            admin.Name = 'APTS_ContentRepositoryType';
            admin.Apttus__Value__c = 'Chatter';
            insert admin;
            
            APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
            customsetting1.Name = 'APT_MSA_Service_Schedule';
            insert customsetting1;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            APT_Sub_Account__c sub_Account = new APT_Sub_Account__c();
            sub_Account.Name = 'test';
            sub_Account.APT_Organisation__c = tempacct.Id;
            sub_Account.APT_Sub_Account_Request_Status__c = 'Draft';
            insert sub_Account;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            
            //Creating new Price List Item record
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            
                //create international product
               /*  Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 bundle1.APT_Sync_with_Opportunity__c=true;
                 bundle1.APT_Is_Charge_Account_Product__c = true;
                 bundle1.APT_Is_Cash_Account_Product__c = false;
                 insert bundle1;*/
                 
                 Product2 bundle1 =APT_TestUtils.createInternationalProduct('International Digital PCMS Bundle incl Airmail Letters',
                                                                     'InternationalDigitalPCMSBundlewithAirmail','Parcel Services');
                 product.APT_Product_type__c = 'International';
                 product.APT_Sync_with_Opportunity__c = true;
                 product.Non_contracted__c = false;
                 insert bundle1;
                 
                 
                 
                 //Create Option product
                /* Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','InternationalBundle','Postal Services','CAT1', 'Standard');
                 option.Apttus_Config2__ConfigurationType__c='Option';
                 option.APT_Sync_with_Opportunity__c=true;
                 option.APT_International_Pricing__c = false;
                 insert option;*/
                 Product2 option = APT_TestUtils.createInternationalProduct('International Airmail Letters','AIRMAIL_LETTERS','Parcel Services');
                 option.Non_contracted__c = false;
                 option.Apttus_Config2__ConfigurationType__c='Option';
                 option.APT_Sync_with_Opportunity__c=true;
                 insert option;
                 
                 
                 //Create PriceBookEntry
                 Id pricebookId = Test.getStandardPricebookId();             
                 PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
                 insert standardPrice;
                 
                 //Create Price list Item
                 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
                 insert pli;
                 
                 //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
                 //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
                 Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
                 Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
                 Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Finalized',
                 null, Datetime.now(), true);
                 prodconfig.Apttus_Config2__Status__c = 'Finalized';
                 insert prodconfig;
                 
              
               
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.APT_Charge_Code_Formula__c = 'some';
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //Create product Attribute value                
            Apttus_QPConfig__ProposalProductAttributeValue__c attribute1 = new Apttus_QPConfig__ProposalProductAttributeValue__c();
            attribute1.Revenue_Committment__c = 'Less than $3,000';
            attribute1.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            attribute1.APT_eParcel_Lodgment__c = true;
            attribute1.APT_International_Letters__c = true;
            attribute1.APT_Volume_Data__c = 'Yes';
            attribute1.APT_Zone_1_Dispersion__c = 10;
            attribute1.APT_Zone_2_Dispersion__c = 10;
            attribute1.APT_Zone_3_Dispersion__c = 10;
            attribute1.APT_Zone_4_Dispersion__c = 10;
            attribute1.APT_Zone_5_Dispersion__c = 10;
            attribute1.APT_Zone_6_Dispersion__c = 10;
            attribute1.APT_Zone_7_Dispersion__c = 10;
            attribute1.APT_Zone_8_Dispersion__c = 10;
            attribute1.APT_Zone_1Digital_Dispersion__c = 10;
            attribute1.APT_Zone_2Digital_Dispersion__c = 10;
            attribute1.APT_Zone_3Digital_Dispersion__c = 10;
            attribute1.APT_Zone_4Digital_Dispersion__c = 10;
            attribute1.APT_Zone_5Digital_Dispersion__c = 10;
            attribute1.APT_Zone_6Digital_Dispersion__c = 10;
            attribute1.APT_Zone_7Digital_Dispersion__c = 10;
            attribute1.APT_Zone_8Digital_Dispersion__c = 10;
            attribute1.APT_Zone_9Digital_Dispersion__c = 10;
            attribute1.APT_Minimum_Quantity__c = 0;
            insert attribute1;
            
            proposalLT1.Apttus_QPConfig__AttributeValueId__c = attribute1.ID;
            update proposalLT1;
            
            List<APT_SAP_Group_Template__c> sgtlist = new List<APT_SAP_Group_Template__c>();
            
            //APT_SAP_Group_Template__c
            APT_SAP_Group_Template__c sgt = new APT_SAP_Group_Template__c();
            sgt.Name = 'test';
            sgt.APT_Charge_Code__c = 'some';
            sgt.APT_Price_Value_Description__c = '100';
            sgt.APT_Price_Value__c = '100';
            
            sgtlist.add(sgt);
            
            APT_SAP_Group_Template__c sgt2 = new APT_SAP_Group_Template__c();
            sgt2.Name = 'test';
            sgt2.APT_Charge_Code__c = 'some';
            sgt2.APT_Price_Value_Description__c = '100';
            sgt2.APT_Price_Value__c = '100';
            sgtlist.add(sgt2);
            insert sgtlist;
            
            String sgtid = sgtlist[0].Id; 
            sgt = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgtid];
                    
            String sgt2id = sgtlist[1].Id; 
            sgt2 = [select id,Name,APT_Charge_Code__c,APT_Weight_Range_Code__c,APT_Price_Value_Description__c,APT_Price_Value__c,APT_Zone__c from
                    APT_SAP_Group_Template__c where id =: sgt2id];
                    
            //Apttus_QPConfig__ProposalUsagePriceTier__c
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt.Apttus_QPConfig__Sequence__c = 1;
            pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
            insert pupt;
            
            Apttus_QPConfig__ProposalUsagePriceTier__c pupt2 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
            pupt2.Apttus_QPConfig__Sequence__c = 1;
            pupt2.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
            pupt2.Apttus_QPConfig__Dimension1Value__c = 'WG';
            pupt2.Apttus_QPConfig__Dimension2Value__c = '0.50';
            pupt2.Apttus_QPConfig__Dimension3Value__c = 'Base';
            pupt2.Apttus_QPConfig__AdjustmentAmount__c = 100;
            insert pupt2;
            
            //agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Ownerid=u.id;
            aptContract.Apttus__Status__c = 'Fully Signed';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = true;
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            
            system.assert(agreementIdSet.size() > 0);
            
            //APT_Operational_Schedule__c
            APT_Operational_Schedule__c aos = new APT_Operational_Schedule__c();
            aos.APT_Contract__c = aptContract.Id;
            aos.APT_Parcel__c = true;
            aos.APT_International_Postal__c = true;
            aos.APT_Parcel_Lodgement_Points__c = '1,2,3,4';
            aos.APT_International_Lodgement_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Points__c = '1,2,3,4';
            aos.APT_International_Collection_Points__c = '1,2,3,4';
            aos.APT_Parcel_Collection_Times__c = '1,2,3,4';
            insert aos;
            
            //APT_Site_Inspection__c
            APT_Site_Inspection__c asi = new APT_Site_Inspection__c();
            asi.APT_Organisation__c = tempacct.Id;
            asi.APT_Contract__c = aptContract.ID;
            asi.Name = '1';
            insert asi;
            
            //Network__c
            Network__c network1 = new Network__c();
            network1.Name = '1';
            insert network1;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Zone_1_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_2_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_3_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_4_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_5_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_6_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_7_Dispersion__c = 1;
            r2tSystemProperties.APT_Zone_8_Dispersion__c = 1;
            
            insert r2tSystemProperties;
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            APT_SyncContractAndRatesBatch scrb = new APT_SyncContractAndRatesBatch(agreementIdSet, setPLIId);
            Database.executeBatch(scrb);
        }
    }
    
    /* 
    this method will create test data for test class execution.
    */    
    private static TestMethod void testWebService() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {       
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;

            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
            con.AccountId = tempacct.Id;
            insert con;            
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.StageName = 'Identify';
            opp.KeyContact__c = con.Id;
            insert opp;
            
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
            
            //create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
            //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
            Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
            Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
            Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal',
            'Ad Hoc',priceList.Id, null,
            'Finalized',
            null, Datetime.now(), true);
            prodconfig.Apttus_Config2__Status__c = 'Finalized';
            insert prodconfig;
             
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;                  
          
            //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
            insert proposalLT1;
            
            set<String> setPLIId = new set<String>();
            setPLIId.add(proposalLT1.Id);
            
            //create agreement
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= 'eParcel' ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContract.Apttus__Status__c = 'SFDC Case Created';
            // Update Included_Product_Lines__c to 'eParcels Domestic' to fulfil criteria in APT_SyncContractAndRatesSchedule class and get picked up for the rate Sync
            aptContract.Included_Product_Lines__c = 'eParcels Domestic';
            aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContract.APT_New_Rate_Card_Download__c = false;
            aptContract.Apttus__Status_Category__c = 'In Signatures';
            Test.StartTest();
            insert aptContract;
            Test.StopTest();
            
            set<Id> agreementIdSet = new set<Id>();
            agreementIdSet.add(aptContract.Id);
            system.assert(agreementIdSet.size() > 0);
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';        
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(priceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
            r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            insert r2tSystemProperties;
            
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockSyncContract1());
            //APT_SyncContractAndRatesSchedule scrb = new APT_SyncContractAndRatesSchedule();
            system.schedule('a '+Datetime.now(), '0 32 16 4 2 ?', new APT_SyncContractAndRatesSchedule());
          //  APT_SAP_SyncContractAndRatesService.SubAccountType test1 = new APT_SAP_SyncContractAndRatesService.SubAccountType();
          //  APT_SAP_SyncContractAndRatesService.ReferenceNumbers_element test2 = new APT_SAP_SyncContractAndRatesService.ReferenceNumbers_element();
          //  APT_SAP_SyncContractAndRatesService.syncContractAndRatesResponseType test3 = new APT_SAP_SyncContractAndRatesService.syncContractAndRatesResponseType();
           // APT_SAP_SyncContractAndRatesService.ReferenceNumber_element test4 = new APT_SAP_SyncContractAndRatesService.ReferenceNumber_element();
        }    
    }
     /* 
    this method will create test data for test class execution.
    */   
    /*
    private static TestMethod void testPrepareValidWeightCodeMap() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            map<String, set<String>> mapApttusWeightCode = new  map<String, set<String>>();
            map<String, set<String>> mapSAPWeightCode = new map<String, set<String>>();
            map<String, decimal> mapMaxApttusWeightCode = new map<String, decimal>();
            mapApttusWeightCode.put('1',new set<string>{'1','2'});
            mapSAPWeightCode.put('1',new set<string>{'1'});
            mapMaxApttusWeightCode.put('1',1);
            
            //APT_SyncContractAndRatesBatch ascarb = new APT_SyncContractAndRatesBatch();
            APT_SyncContractAndRatesBatch.prepareValidWeightCodeMap(mapApttusWeightCode,mapSAPWeightCode,mapMaxApttusWeightCode);
        }
            
        }
        */
}