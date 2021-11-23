/**
 * This apex class is test class for apex class - APT_RefreshPricingController.
 * Created By - Mausam Padhiyar
 * Created Date - 7th Oct, 2016
 * Last Modified By -
 * Last Modified Date - 
 */
@isTest
public with sharing class APT_RefreshPricingController_Test {
    
    /**
     * Test Method 1     * 
     */
    private static testMethod void testMethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        
        System.runAs(testuser) {
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.type = 'New Customer';
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
            bundle1.Non_contracted__c = false;
            bundle1.APT_Contract_Pricing__c = true;
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli = APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert proposal;
            
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                    proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
            insert prodconfig;
            
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                    1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                    null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
                                                                    'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
                                                                    'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                    true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
                                                                    5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                                                                    bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
                                                                    bundleLine.Apttus_Config2__NetPrice__c = 5225;
                                                                    bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
                                                                    bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
                                                                    
            bundleLine.Apttus_Config2__ContractNumbers__c = '12345678';
            insert bundleLine; 
            
            
            test.startTest();
            
            ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t.cs5.my.salesforce.com/p/opp/SelectSearch?addTo=006O0000008RV39&retURL=%2F006O0000008RV39');
            Apexpages.currentpage().getparameters().put('source', 'Cart');
            Apexpages.currentpage().getparameters().put('Id', prodconfig.id);
            Apexpages.currentpage().getparameters().put(APT_Constants.URL_BUSINESS_OBJECT_ID, proposal.id);
            
            APT_RefreshPricingController controller = new APT_RefreshPricingController();
            PageReference pgRef = controller.refreshPrice();
            system.assert(pgRef != null);
            
            test.stopTest();
        }
    }
}