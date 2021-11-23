/**
 * @description       : This is the test class written for APT_SaveConfigController class
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-26-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-25-2021   Mansi Shah   Initial Version
**/
@isTest
public class APT_SaveConfigControllerTest {
        /**
        * @description: This method will set up the test data for test methods 
        * @author Mansi Shah | 05-25-2021 
        **/
        @TestSetup
        static void makeData(){
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
                                                                        1, 'Product/Service', null, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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
            }
        }
        
        /**
        * @description:
        * @author Mansi Shah | 05-25-2021 
        **/
        @isTest
        public static void testSaveConfiguration(){
            Apttus_Config2__ProductConfiguration__c prodconfig = [SELECT ID,Apttus_QPConfig__Proposald__c 
                                                                  FROM Apttus_Config2__ProductConfiguration__c
                                                                  LIMIT 1];
    
                String instanceURL = URL.getSalesforceBaseUrl().toExternalForm()+'APT_SaveConfigController';
                ApexPages.currentPage().getHeaders().put('Referer', instanceURL);
                Apexpages.currentpage().getparameters().put('Id', prodconfig.id);
                Apexpages.currentpage().getparameters().put('flow', 'NewQuote');
                Apexpages.currentpage().getparameters().put(APT_Constants.URL_BUSINESS_OBJECT_ID, prodconfig.Apttus_QPConfig__Proposald__c);
                
                APT_SaveConfigController controller = new APT_SaveConfigController();
                PageReference pgRef = controller.saveCart();
                system.assert(pgRef != null);
        }
}