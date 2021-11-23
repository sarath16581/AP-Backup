/**************************************************
Description:    This apex class is test class for APT_CartValidationCallBack_Test.
History:
--------------------------------------------------
2016-03-29  Kushal Bhalodia
2017-01-31 Mausam Padhiyar
2019-01-31  nathan.franklin@auspost.com.au Modified testAPTDecreaseRevenue to fix an an issue with the Too Many SOQL error with the deployment of MW0003089 - Opportunity Complexity rating in Salesforce
2020-04-20 seth.heang@auspost.com.au - Method to test category and minimum quantity threshold validation for eParcel/eParcel Express
**************************************************/
@isTest(SeeAllData=false)
public with sharing class APT_CartValidationCallBack_Test {
        /**
         * Added by Adrian Recio
         * Setup data for cart validation test methods
         * Setup data defaulted to amendment and increase revenue proposal
         */
        @testSetup static void setup() {
                // Get standard price book Id
                Id priceBookId = Test.getStandardPricebookId();

                //Create test admin config
                Apttus__APTS_Admin__c adminObj = APT_TestUtil2.createAptAdmin();
                insert adminObj;

                //Create validation field custom setting
                APT_R2TValidationFields__c valFieldVar = APT_TestUtil2.createAptValidationFields();
                insert valFieldVar;

                //Create config system properties
                Apttus_Config2__ConfigSystemProperties__c cofingSettingVar = APT_TestUtil2.createAptConfigSystem();
                insert cofingSettingVar;

                // Create custom class configuration
                Apttus_Config2__ConfigCustomClasses__c configCC = APT_TestUtil2.createAptConfigClass();
                insert configCC;

                // Create config line item custom fields
                List<Apttus_Config2__ConfigLineItemCustomFields__c>cliCustomFieldList = new List<Apttus_Config2__ConfigLineItemCustomFields__c>();
                Apttus_Config2__ConfigLineItemCustomFields__c cliCustomFieldVar = APT_TestUtil2.createCLICustomFields();
                cliCustomFieldList.add(cliCustomFieldVar);
                Apttus_Config2__ConfigLineItemCustomFields__c cliCustomFieldVar2 = new Apttus_Config2__ConfigLineItemCustomFields__c();
                cliCustomFieldVar2.Name = '2';
                cliCustomFieldVar2.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__AttributeValueId__r.APT_RK_Code_Applied__c,Apttus_Config2__AttributeValueId__r.APT_Post_Code_Suburb__c,Apttus_Config2__ProductId__r.APT_Product_type__c';
                cliCustomFieldList.add(cliCustomFieldVar2);
                insert cliCustomFieldList;

                //Create test classification
                Apttus_Config2__ClassificationName__c classVar = APT_TestUtil2.createAptCName();
                insert classVar;

                //Create pricelist
                Apttus_Config2__PriceList__c priceList = APT_TestUtil2.createPriceList();
                insert priceList;

                //Create R2T System properties custom setting
                //Assign the cart validation product of international bunlde
                APT_R2T_System_Properties__c r2tObj = APT_TestUtil2.createR2TSystemProperties(priceList,classVar);
                r2tObj.APT_Cart_Validation_products__c = ';' + APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE + ';';
                insert r2tObj;

                //Create test Products
                List<Product2> prodList = new List<Product2>();
                //Digital and non digital international bundle
                Product2 IntBundleVar = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                        APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE,
                        'Parcels & eCommerce Services',
                        'Postal Services');
                prodList.add(IntBundleVar);

                //International PCMS Bundle
                Product2 IntBundleVar2 = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                        APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE,
                        'Parcels & eCommerce Services',
                        'Postal Services');
                prodList.add(IntBundleVar2);

                //International digital pcms bundle
                Product2 IntBundleVar3 = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                        APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL,
                        'Parcels & eCommerce Services',
                        'Postal Services');
                prodList.add(IntBundleVar3);

                //International airmail letters
                Product2 IntBundleVar4 = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                        APT_Constants.PRODUCT_CODE_INTERNATIONAL_AIRMAIL_LETTERS,
                        'Parcels & eCommerce Services',
                        'Postal Services');
                prodList.add(IntBundleVar4);

                //Eparcel Express
                Product2 DomesticProdVar = APT_TestUtil2.createDomesticProduct(APT_Constants.PRODUCT_NAME_EPARCEL_EXPRESS,
                        APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS,
                        'Parcels & eCommerce Services',
                        'Postal Services',
                        'CAT1', 'Express');
                prodList.add(DomesticProdVar);

                //Startrack
                Product2 stProduct = APT_TestUtils.createStarTrackProduct('Special Services Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'RET', 'StarTrack');
                prodList.add(stProduct);

                insert prodList;

                //create Logdement Zone
                APT_Lodgement_Zone__c logdZone = APT_TestUtil2.createLodgementZone('Aust Antarctic Territory','AAT');
                insert logdZone;

                //Create price book entry
                List<PricebookEntry>pbeList = new List<PricebookEntry>();
                PricebookEntry priceBookEntry1 =  APT_TestUtil2.getPricebookEntry(priceBookId,IntBundleVar);
                pbeList.add(priceBookEntry1);
                PricebookEntry priceBookEntry2 =  APT_TestUtil2.getPricebookEntry(priceBookId,DomesticProdVar);
                pbeList.add(priceBookEntry2);
                insert pbeList;

                //Create Price list Item
                List<Apttus_Config2__PriceListItem__c> pliList = new List<Apttus_Config2__PriceListItem__c>();
                Apttus_Config2__PriceListItem__c pli1 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar.ID,'C Manufacturing','BAND 2');
                pliList.add(pli1);
                Apttus_Config2__PriceListItem__c pli2 = APT_TestUtil2.createPriceListItem(priceList.ID,DomesticProdVar.ID,'C Manufacturing','BAND 2');
                pliList.add(pli2);
                Apttus_Config2__PriceListItem__c pli3 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar2.ID,'C Manufacturing','BAND 2');
                pliList.add(pli3);
                Apttus_Config2__PriceListItem__c pli4 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar3.ID,'C Manufacturing','BAND 2');
                pliList.add(pli4);
                Apttus_Config2__PriceListItem__c pli5 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar4.ID,'C Manufacturing','BAND 2');
                pliList.add(pli5);
                Apttus_Config2__PriceListItem__c pli6 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar4.ID,'C Manufacturing','BAND 2');
                pliList.add(pli6);
                insert pliList;

                //Create price matrix
                List<Apttus_Config2__PriceMatrix__c> pmList = new List<Apttus_Config2__PriceMatrix__c>();
                Apttus_Config2__PriceMatrix__c pmVar = new Apttus_Config2__PriceMatrix__c();
                pmVar.Apttus_Config2__PriceListItemId__c = pli1.id;
                pmVar.Apttus_Config2__Sequence__c = 1;
                pmList.add(pmVar);

                Apttus_Config2__PriceMatrix__c pmVar2 = new Apttus_Config2__PriceMatrix__c();
                pmVar2.Apttus_Config2__PriceListItemId__c = pli2.id;
                pmVar2.Apttus_Config2__Sequence__c = 1;
                pmList.add(pmVar2);

                insert pmList;

                // Create test organisation
                Account accVar = APT_TestUtil2.createOrganisation();
                insert accVar;

                // Create test contact
                Contact conVar = APT_TestUtil2.createContact();
                insert conVar;

                // Create test opportunity of new customer
                List<Opportunity> oppList = new List<Opportunity>();
                Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar); // Represents the new opportunity for the amendment proposal
                oppVar.Amount = 3000;
                oppVar.StageName = 'Identify';
                oppList.add(oppVar);
                Opportunity oppVarOrig = APT_TestUtil2.createOpportunity(accVar); // Represent the original opportunity for the amendment proposal
                oppVarOrig.StageName = 'Identify';
                oppVarOrig.Amount = 3500;
                oppList.add(oppVarOrig);
                insert oppList;

                // Create test original agreement for amendment
                Apttus__APTS_Agreement__c  agreementVar  = APT_TestUtil2.createAgreement(accVar,
                        conVar,
                        oppVarOrig,
                        new Apttus_Proposal__Proposal__c(),
                        APT_AmendRenewController.SUPERSEDED_STATUS,
                        APT_AmendRenewController.AMENDED_STATUS_CATEGORY,
                        'MSA & Service Schedule');
                insert agreementVar;
                test.startTest(); //10/23/2019 - added as a fix for the SOQL error
                // Create test amendment proposal
                Apttus_Proposal__Proposal__c proposalVar = APT_TestUtil2.createQuoteProposal(accVar,
                        oppVar,
                        agreementVar,
                        APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,
                        priceList);
                // Add increase revenue as revenue type
                proposalVar.APT_Revenue_Type__c = APT_AmendRenewController.INCREASE_REVENUE;
                insert proposalVar;

                //Create Product Configuration
                List<Apttus_Config2__ProductConfiguration__c> configList = new List<Apttus_Config2__ProductConfiguration__c>();
                Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtil2.getProductConfiguration('Product Configuration', 1,
                        proposalVar.Id, 'Proposal','Ad Hoc',
                        priceList.Id, null,'New',null,
                        Datetime.now(), true);
                configList.add(prodconfig);
                insert configList;

                // Create LineItem
                List<Apttus_Config2__LineItem__c> lstLineItem = new List<Apttus_Config2__LineItem__c>();

                // Digitial International Bundle Configuration line item
                Apttus_Config2__LineItem__c IntBundleVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                        1, 'Product/Service', IntBundleVar.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                        'Each', 1, priceList.Id, pli1.Id,//Uom, term, priceList, Pli,
                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                IntBundleVarCLI.Apttus_Config2__AllowManualAdjustment__c = true;
                IntBundleVarCLI.Apttus_Config2__NetPrice__c = 5225;
                IntBundleVarCLI.Apttus_Config2__PrimaryLineNumber__c = 1;
                IntBundleVarCLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
                IntBundleVarCLI.APT_Is_OPC_deleted__c = false;
                IntBundleVarCLI.Apttus_Config2__LineSequence__c = 1;
                lstLineItem.add(IntBundleVarCLI);

                // Eparcel Express Configuration Line Item
                Apttus_Config2__LineItem__c DomesticVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                        1, 'Product/Service', DomesticProdVar.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                        'Each', 1, priceList.Id, pli2.Id,//Uom, term, priceList, Pli,
                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                DomesticVarCLI.Apttus_Config2__AllowManualAdjustment__c = true;
                DomesticVarCLI.Apttus_Config2__NetPrice__c = 5225;
                DomesticVarCLI.Apttus_Config2__PrimaryLineNumber__c = 2;
                DomesticVarCLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
                DomesticVarCLI.APT_Is_OPC_deleted__c = false;
                DomesticVarCLI.Apttus_Config2__LineSequence__c = 2;
                lstLineItem.add(DomesticVarCLI);

                // Non Digital Internation Bundle
                Apttus_Config2__LineItem__c NDIntBundleVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                        1, 'Product/Service', IntBundleVar.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                        'Each', 1, priceList.Id, pli3.Id,//Uom, term, priceList, Pli,
                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                NDIntBundleVarCLI.Apttus_Config2__AllowManualAdjustment__c = true;
                NDIntBundleVarCLI.Apttus_Config2__NetPrice__c = 5225;
                NDIntBundleVarCLI.Apttus_Config2__PrimaryLineNumber__c = 1;
                NDIntBundleVarCLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
                NDIntBundleVarCLI.APT_Is_OPC_deleted__c = false;
                NDIntBundleVarCLI.Apttus_Config2__LineSequence__c = 3;
                lstLineItem.add(NDIntBundleVarCLI);

                //International PCMS
                Apttus_Config2__LineItem__c InternationalPCMS_CLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                        1, 'Product/Service', IntBundleVar2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                        'Each', 1, priceList.Id, pli4.Id,//Uom, term, priceList, Pli,
                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                InternationalPCMS_CLI.Apttus_Config2__AllowManualAdjustment__c = true;
                InternationalPCMS_CLI.Apttus_Config2__NetPrice__c = 5225;
                InternationalPCMS_CLI.Apttus_Config2__PrimaryLineNumber__c = 1;
                InternationalPCMS_CLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
                InternationalPCMS_CLI.APT_Is_OPC_deleted__c = false;
                InternationalPCMS_CLI.Apttus_Config2__LineSequence__c = 4;
                lstLineItem.add(InternationalPCMS_CLI);

                //International Digital PCMS
                Apttus_Config2__LineItem__c IntDigitalPCMS_CLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                        1, 'Product/Service', IntBundleVar3.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                        'Each', 1, priceList.Id, pli5.Id,//Uom, term, priceList, Pli,
                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                IntDigitalPCMS_CLI.Apttus_Config2__AllowManualAdjustment__c = true;
                IntDigitalPCMS_CLI.Apttus_Config2__NetPrice__c = 5225;
                IntDigitalPCMS_CLI.Apttus_Config2__PrimaryLineNumber__c = 1;
                IntDigitalPCMS_CLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
                IntDigitalPCMS_CLI.APT_Is_OPC_deleted__c = false;
                IntDigitalPCMS_CLI.Apttus_Config2__LineSequence__c = 5;
                lstLineItem.add(IntDigitalPCMS_CLI);

                // International Airmail
                Apttus_Config2__LineItem__c IntAIrmail_CLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                        1, 'Product/Service', IntBundleVar4.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                        'Each', 1, priceList.Id, pli6.Id,//Uom, term, priceList, Pli,
                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                IntAIrmail_CLI.Apttus_Config2__AllowManualAdjustment__c = true;
                IntAIrmail_CLI.Apttus_Config2__NetPrice__c = 5225;
                IntAIrmail_CLI.Apttus_Config2__PrimaryLineNumber__c = 1;
                IntAIrmail_CLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
                IntAIrmail_CLI.APT_Is_OPC_deleted__c = false;
                IntAIrmail_CLI.Apttus_Config2__LineSequence__c = 6;
                lstLineItem.add(IntAIrmail_CLI);

                //StarTrack
                Apttus_Config2__LineItem__c starTrackLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                        1, 'Product/Service', stProduct.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                        'Each', 1, priceList.Id, pli6.Id,//Uom, term, priceList, Pli,
                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                IntAIrmail_CLI.Apttus_Config2__LineSequence__c = 7;
                lstLineItem.add(starTrackLI);
                insert lstLineItem;

                //create Product Attribute
                List<Apttus_Config2__ProductAttributeValue__c> prodAttList = new List<Apttus_Config2__ProductAttributeValue__c>();
                Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtil2.createAttributeValue(IntBundleVarCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
                //attribute1.Category__c = 'CAT1';
                attribute1.APT_Lodgement_Zone__c = logdZone.ID;
                attribute1.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
                attribute1.APT_eParcel_Lodgment__c = true; // Required true if digital
                attribute1.APT_International_Letters__c = false; // Required false if digital
                attribute1.APT_Minimum_Quantity__c = 10;
                attribute1.APTS_Price_Structure__c = 'BANDED {Z30}';
                prodAttList.add(attribute1);
                
                Apttus_Config2__ProductAttributeValue__c attribute2 = APT_TestUtil2.createAttributeValue(DomesticVarCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
                attribute2.Category__c = 'CAT1';
                attribute2.APT_Lodgement_Zone__c = logdZone.ID;
                attribute2.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
                attribute2.APT_eParcel_Lodgment__c = true;
                attribute2.APT_International_Letters__c = false;
                attribute2.APT_Minimum_Quantity__c = 20;
                attribute2.APTS_Price_Structure__c = 'BASE+PER_KG {Z30}';
                prodAttList.add(attribute2);

                Apttus_Config2__ProductAttributeValue__c attribute3 = APT_TestUtil2.createAttributeValue(NDIntBundleVarCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
                attribute3.Category__c = 'CAT1';
                attribute3.APT_Lodgement_Zone__c = logdZone.ID;
                attribute3.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
                attribute3.APT_eParcel_Lodgment__c = false; // Required false if non digital
                attribute3.APT_International_Letters__c = true; // Required true if non digitial
                attribute3.APT_Minimum_Quantity__c = 20;
                attribute3.APTS_Price_Structure__c = 'BASE+PER_KG {Z30}';
                prodAttList.add(attribute3);

                Apttus_Config2__ProductAttributeValue__c attributeST = APT_TestUtil2.createAttributeValue(starTrackLI.Id,null,false,false,false,null,null,false,True);
                prodAttList.add(attributeST);

                insert prodAttList;

                // Assign back the attribute to the bundle
                List<Apttus_Config2__LineItem__c> appConfigLineItemList = new List<Apttus_Config2__LineItem__c>();
                IntBundleVarCLI.Apttus_Config2__AttributeValueId__c = attribute1.Id;
                DomesticVarCLI.Apttus_Config2__AttributeValueId__c = attribute2.Id;
                starTrackLI.Apttus_Config2__AttributeValueId__c = attributeST.Id;

                appConfigLineItemList.add(IntBundleVarCLI);
                appConfigLineItemList.add(DomesticVarCLI);
                appConfigLineItemList.add(starTrackLI);
                update appConfigLineItemList;

                // Create Charge code
                List<APT_Charge_Code__c>aptCCList = new List<APT_Charge_Code__c>();
                APT_Charge_Code__c objChargeCode = APT_TestUtils.createChargeCode(attribute1.APTS_Price_Structure__c);
                aptCCList.add(objChargeCode);
                APT_Charge_Code__c objChargeCode2 = APT_TestUtils.createChargeCode(attribute2.APTS_Price_Structure__c);
                aptCCList.add(objChargeCode2);
                insert aptCCList;

                //Create usage price tier
                List<Apttus_Config2__UsagePriceTier__c> uptList = new List<Apttus_Config2__UsagePriceTier__c>();
                Apttus_Config2__UsagePriceTier__c uptVar = new Apttus_Config2__UsagePriceTier__c();
                uptVar.Apttus_Config2__LineItemId__c = IntBundleVarCLI.Id;
                uptVar.Apttus_Config2__PriceMatrixId__c = pmVar.Id;
                uptVar.Apttus_Config2__Sequence__c = 1;
                uptVar.Apttus_Config2__Dimension1Value__c = 'Zone1';
                uptVar.Apttus_Config2__Dimension2Value__c = 'Per Item';
                uptVar.Apttus_Config2__AdjustmentAmount__c = 10;
                uptVar.Apttus_Config2__UsageRate__c = 10;
                uptVar.Apttus_Config2__PriceOverride__c = 10;
                uptList.add(uptVar);

                Apttus_Config2__UsagePriceTier__c uptVar2 = new Apttus_Config2__UsagePriceTier__c();
                uptVar2.Apttus_Config2__LineItemId__c = DomesticVarCLI.Id;
                uptVar2.Apttus_Config2__PriceMatrixId__c = pmVar2.Id;
                uptVar2.Apttus_Config2__Sequence__c = 1;
                uptVar2.Apttus_Config2__Dimension1Value__c = 'Zone1';
                uptVar2.Apttus_Config2__Dimension2Value__c = 'Per Item';
                uptVar2.Apttus_Config2__AdjustmentAmount__c = 10;
                uptVar2.Apttus_Config2__UsageRate__c = 10;
                uptVar2.Apttus_Config2__PriceOverride__c = 10;
                uptList.add(uptVar2);

                Apttus_Config2__UsagePriceTier__c uptVar3 = new Apttus_Config2__UsagePriceTier__c();
                uptVar3.Apttus_Config2__LineItemId__c = DomesticVarCLI.Id;
                uptVar3.Apttus_Config2__PriceMatrixId__c = pmVar2.Id;
                uptVar3.Apttus_Config2__Sequence__c = 1;
                uptVar3.Apttus_Config2__Dimension1Value__c = 'Zone1';
                uptVar3.Apttus_Config2__Dimension2Value__c = 'Per Item';
                uptVar3.Apttus_Config2__AdjustmentAmount__c = 10;
                uptVar3.Apttus_Config2__UsageRate__c = 10;
                uptVar3.Apttus_Config2__PriceOverride__c = 10;
                uptList.add(uptVar3);

                insert uptList;

                List<OpportunityLineItem> listOli = new List<OpportunityLineItem>();
                OpportunityLineItem oli = APT_TestUtil2.createOpportunityLI(oppVar, priceBookEntry1.Id, 'New Business');
                oli.TotalPrice = 2000;
                oli.Quantity = 10;
                listOli.add(oli);

                OpportunityLineItem oli2 = APT_TestUtil2.createOpportunityLI(oppVar, priceBookEntry2.Id, 'New Business');
                oli2.TotalPrice = 1000;
                oli2.Quantity = 10;
                listOli.add(oli2);
                insert listOli;

                List<APT_Opportunity_Product_Line_Item__c> APTOplList = new List<APT_Opportunity_Product_Line_Item__c>();
                APT_Opportunity_Product_Line_Item__c APTopliVar = APT_TestUtil2.createAPTOpportunityLI(proposalVar,IntBundleVar);
                APTopliVar.APT_TotalPrice__c = 2000;
                APTopliVar.APT_Quantity__c = 10;
                APTopliVar.APT_Revenue_Start_Date__c = System.Today();
                APTopliVar.APT_Revenue_End_Date__c= System.Today() + 10;
                APTopliVar.APT_Classification__c = 'New Business';
                APTopliVar.APT_Unit_Sales_Price__c = 200;
                APTOplList.add(APTopliVar);

                APT_Opportunity_Product_Line_Item__c APTopliVar2 = APT_TestUtil2.createAPTOpportunityLI(proposalVar,DomesticProdVar);
                APTopliVar2.APT_TotalPrice__c = 1000;
                APTopliVar2.APT_Quantity__c = 10;
                APTopliVar2.APT_Revenue_Start_Date__c = System.Today();
                APTopliVar2.APT_Revenue_End_Date__c= System.Today() + 10;
                APTopliVar2.APT_Classification__c = 'New Business';
                APTopliVar2.APT_Unit_Sales_Price__c = 100;
                APTOplList.add(APTopliVar2);

                insert APTOplList;
                test.stopTest();
        }

        /**
         * Added by Adrian Recio
         * method to test validation for Increase Revenue
         */
        static testmethod void testAPTIncreaseRevenue(){
                
                // RSolomon - moved the below line to the top so the below transactions are within the new governor limits 
                Test.startTest();
                // Pull setup data
                Apttus_Config2__ProductConfiguration__c configVar = [Select Id from Apttus_Config2__ProductConfiguration__c];
                List<Apttus_Config2__LineItem__c> aptConfigList = [Select Id from Apttus_Config2__LineItem__c];

                // Instantiate call back class
                APT_CartValidationCallBack obj = new APT_CartValidationCallBack();
                // Instantiate cart page
                PageReference pref = Page.Apttus_Config2__CartDetailView;

                // Set current page to apttus standard cart page
                Test.setCurrentPage(pref);

                // Fire validation callbacktester from Apttus Conig2 Managed Package
                // Pass the line items and configuration that needs to be tested
                Apttus_Config2.CallbackTester.testValidationCallback(configVar.Id, aptConfigList, null, obj);
                Test.stopTest();
        }
        /**
         * Added by Adrian Recio
         * method to test validation for Decrease Revenue
         */
        static testmethod void testAPTDecreaseRevenue(){

                // NOTE: These have been moved inside the startTest method to take advantage of the new set of governor limits.
                //          Given the tangled hierarchy of Apttus functionality, it's easy to run into Too Many SOQL Queries which is what was occuring in this instance
                //          Account / Opportunity / Contact / Apttus proposal / Apttus agreement execution flows will all need to be reviewed to fix this issue

                Test.startTest();

                // Pull setup data
                Apttus_Config2__ProductConfiguration__c configVar = [Select Id from Apttus_Config2__ProductConfiguration__c];
                List<Apttus_Config2__LineItem__c> aptConfigList = [Select Id from Apttus_Config2__LineItem__c];

                // Update setup data to satisfy decrease revenue condition

                // Pull original account and create new opportunity related to it with decreased revenue
                Account accVar = [Select Id from Account];
                Opportunity newOppVarOrig = APT_TestUtil2.createOpportunity(accVar);
                newOppVarOrig.StageName = 'Identify';
                newOppVarOrig.Amount = 2500;
                newOppVarOrig.APT_Revenue_Decrease__c = 10;
                insert newOppVarOrig;

                // Instantiate call back class
                APT_CartValidationCallBack obj = new APT_CartValidationCallBack();
                // Instantiate cart page
                PageReference pref = Page.Apttus_Config2__CartDetailView;

                // Retrieve test agreement to be amended and reassign opportunity
                Apttus__APTS_Agreement__c aptAgVar = [Select Id, Apttus__Related_Opportunity__c from Apttus__APTS_Agreement__c];
                aptAgVar.Apttus__Related_Opportunity__c = newOppVarOrig.Id;
                update aptAgVar;

                // Change proposal type to decrease revenue
                Apttus_Proposal__Proposal__c proposalVar = [Select Id, APT_Revenue_Type__c from Apttus_Proposal__Proposal__c];
                proposalVar.APT_Revenue_Type__c = APT_AmendRenewController.DECREASE_REVENUE;
                update proposalVar;

                // Set current page to apttus standard cart page
                Test.setCurrentPage(pref);

                // Fire validation callbacktester from Apttus Conig2 Managed Package
                // Pass the line items and configuration that needs to be tested
                Apttus_Config2.CallbackTester.testValidationCallback(configVar.Id, aptConfigList, null, obj);
                Test.stopTest();
        }
        
       
        /**
         * Added by Seth Heang 20/04/2020
         * Method to test category and minimum quantity threshold validation for eParcel/eParcel Express
         */
        static testmethod void testCategoryMinimumQuantityValidation(){
                
                Test.startTest();
                // Pull setup data
                Apttus_Config2__ProductConfiguration__c configVar = [Select Id from Apttus_Config2__ProductConfiguration__c];
                APT_Lodgement_Zone__c logdZone = [Select Id from APT_Lodgement_Zone__c limit 1];
                Product2 domesticExpressProd = [Select id, ProductCode from Product2 where ProductCode =:APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS limit 1];
                Apttus_Config2__LineItem__c domesticExpressCLI = [Select Id, Apttus_Config2__ProductId__c, Apttus_Config2__AttributeValueId__c from Apttus_Config2__LineItem__c 
                                                                where Apttus_Config2__ProductId__c =: domesticExpressProd.Id];
                // update attribute value data to test Category 'CAT1' and Minimum Quantity above '1000'
                Apttus_Config2__ProductAttributeValue__c attributeCATs = APT_TestUtil2.createAttributeValue(domesticExpressCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
                attributeCATs.Category__c = 'CAT1';
                attributeCATs.APT_Lodgement_Zone__c = logdZone.ID;
                attributeCATs.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
                attributeCATs.APT_eParcel_Lodgment__c = true;
                attributeCATs.APT_International_Letters__c = false;
                attributeCATs.APT_Minimum_Quantity__c = 1200;
                attributeCATs.APTS_Price_Structure__c = 'BASE+PER_KG {Z30}';
                insert attributeCATs;
                
                domesticExpressCLI.Apttus_Config2__AttributeValueId__c = attributeCATs.Id;
                update domesticExpressCLI;
                
                List<Apttus_Config2__LineItem__c> aptConfigList = [Select Id from Apttus_Config2__LineItem__c];
                // Instantiate call back class
                APT_CartValidationCallBack obj = new APT_CartValidationCallBack();
                // Instantiate cart page
                PageReference pref = Page.Apttus_Config2__CartDetailView;

                // Set current page to apttus standard cart page
                Test.setCurrentPage(pref);

                // Fire validation callbacktester from Apttus Conig2 Managed Package
                // Pass the line items and configuration that needs to be tested
                Apttus_Config2.CallbackTester.testValidationCallback(configVar.Id, aptConfigList, null, obj);
                Test.stopTest();
        }
}