/**
Created By - Mahesh Patel
Created Date - 12th Nov, 2020
Last Modified By -
Last Modified Date -
Ken McGuire 2023.04.19 Proposal field migration to opportunity
Description - Product Attribute Callback Test Class
*/
@isTest
public with sharing class APT_ProductAttributeCallbackTest {
    /**
     * method to test set defaults on attribute value
     */
    static testmethod void setDefaultsTest(){
            
            Test.startTest();

            //Create custom class
            Apttus_Config2__ConfigCustomClasses__c customSetting = new Apttus_Config2__ConfigCustomClasses__c();
            customSetting.Name = 'Custom Classes';
            customSetting.Apttus_Config2__ProductAttributeCallbackClass__c = 'APT_ProductAttributeCallback';
            insert customSetting;

            //Create pricelist
            Apttus_Config2__PriceList__c priceList = APT_TestUtil2.createPriceList();
            insert priceList;

            Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
            pli.Apttus_Config2__Active__c = true;
            pli.Apttus_Config2__PriceListId__c = priceList.id;
            insert pli;

            //Create postcode mapping
            APT_Post_Code_Mapping__c postCodeMapping = APT_TestUtils.createPostCodeMapping('0200', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC3');
            insert postCodeMapping;

            //Create test organisation
            Account accVar = APT_TestUtil2.createOrganisation();
            insert accVar;

            //Create test opportunity
            Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);
            oppVar.StageName = 'Identify';
            oppVar.APTpostcodesuburb__c = postCodeMapping.Id;
        	insert oppVar;

            //Create proposal
            Apttus_Proposal__Proposal__c proposalVar = APT_TestUtil2.createQuoteProposalNoAgrmnt(accVar, oppVar, APT_Constants.RECORD_TYPE_PROPOSAL, priceList);
            insert proposalVar;


            //Create Product Configuration
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtil2.getProductConfiguration('Product Configuration', 1,
                    proposalVar.Id, 'Proposal','Ad Hoc',
                    priceList.Id, null,'New',null,
                    Datetime.now(), true);
            insert prodconfig;

            //product
            Product2 product = APT_TestUtils.createStarTrackProduct('Security Services Tier 3', 'SecurityServicesTier3', 'Parcel Services', 'Tier 3', 'SE3', 'StarTrack');
            insert product;
            
            //Create LineItem
            List<Apttus_Config2__LineItem__c> lstLineItem = new List<Apttus_Config2__LineItem__c>();

            // Eparcel Express Configuration Line Item
            Apttus_Config2__LineItem__c starTrackLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                    1, 'Product/Service', product.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                    null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                    'Each', 1, priceList.Id, null,//Uom, term, priceList, Pli,
                    'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                    true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                    5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            lstLineItem.add(starTrackLI);
            insert lstLineItem;

            //create Product Attribute
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtil2.createAttributeValue(starTrackLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
            
            insert attribute1;

            //attributes
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
            insert productAttributeGroup;
            
            list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
            Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Zone_Type__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute1);
            
            Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Inbound_Outbound__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute2);

            insert listProductAttribute;

            Apttus_Config2__ProductAttributeGroupMember__c pagm = new Apttus_Config2__ProductAttributeGroupMember__c();
            pagm.Apttus_Config2__AttributeGroupId__c = productAttributeGroup.Id;
            pagm.Apttus_Config2__ProductId__c = product.Id;
            pagm.Apttus_Config2__Sequence__c = 1;
            insert pagm;

            // Assign back the attribute to the bundle
            List<Apttus_Config2__LineItem__c> appConfigLineItemList = new List<Apttus_Config2__LineItem__c>();
            starTrackLI.Apttus_Config2__AttributeValueId__c = attribute1.Id;
            appConfigLineItemList.add(starTrackLI);
            update appConfigLineItemList;

            Apttus_Config2.CallbackTester.testProductAttributeCallback
                                              ( prodconfig.id
                                              , starTrackLI
                                              , new APT_ProductAttributeCallback());
            
            Test.stopTest();
    }

    
}