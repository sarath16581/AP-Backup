/**
Description - This apex class is test class for apex Trigger - APT_AppliedRuleInfoTriggerHandler & apex class - APT_AppliedRuleInfoTriggerHandler
Created By - Raviteja Gona
Created Date - 21 Aug, 2017
Last Modified By -
Last Modified Date - 
**/
@isTest
private with sharing class APT_AppliedRuleInfoActionTrigger_Test {

private static testMethod void testMethod1() 
    
        {
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
            System.runAs(testuser) {    
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
                 Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Digital PCMS Bundle incl Airmail Letters',
                                                                             'InternationalDigitalPCMSBundlewithAirmail','Parcel Services');
                 insert bundle1;
                 
                 //Create Price list Item
                 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
                 insert pli;
                 
                 //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
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
                    
                   //create Logdement Zone             
                   APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
                   logdZone.APT_Post_Code_Start__c = 1000;
                   logdZone.APT_Post_Code_End__c = 9000;
                   insert logdZone;
                   
                   //create applied rule info
                   list<Apttus_Config2__AppliedRuleInfo__c> Arilist=new list<Apttus_Config2__AppliedRuleInfo__c>(); 
                   Apttus_Config2__AppliedRuleInfo__c ari1 = new Apttus_Config2__AppliedRuleInfo__c(Apttus_Config2__ConfigurationId__c=prodconfig.Id);
                   Arilist.add(ari1);
                   insert Arilist;
                   
                   //create applied rule Action info
                   list<Apttus_Config2__AppliedRuleActionInfo__c> AriAclist=new list<Apttus_Config2__AppliedRuleActionInfo__c>(); 
                   Apttus_Config2__AppliedRuleActionInfo__c ariAc1 = new Apttus_Config2__AppliedRuleActionInfo__c(Apttus_Config2__ConfigurationId__c=prodconfig.Id,
                                                                                                                  Apttus_Config2__AppliedRuleInfoId__c=Arilist[0].Id);
                   AriAclist.add(ariAc1);
                   insert AriAclist;


                   //Create Feature Pricing              
                   APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
                   insert featurePricing;
                  
                  //Create product Attribute value                
                    Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
                    attribute1.Category__c='CAT1';
                    attribute1.APT_Postcode__c = '2000';
                    attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
                    attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
                    attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
                    insert attribute1; 
                    
               
                Test.starttest();    
                  // update product Attribute value
                    //attribute1.Category__c='CAT1';
                    attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State;Large Postcode Direct';               
                   Update attribute1; 
                   //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
                Test.stoptest();
                system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);      
            }
    }

}