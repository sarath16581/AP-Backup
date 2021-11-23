@isTest
public class APT_ProposalApprovalEmailControllerTest {

    public static testmethod void testmethod1(){
        
        Contact con= APT_TestUtils.createContact();
            insert con;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            tempacct.Legacy_Id__c = '60000000';
            insert tempacct;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            insert opp;
            
            Product2 product =APT_TestUtils.createInternationalProduct('Car',APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD,'Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
        
            Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
            insert quote;
            
            Apttus_Config2__ProductConfiguration__c config =new  Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=quote.id,Apttus_Config2__PriceListId__c=priceList.id,Apttus_Config2__Status__c='Finalized');         insert config;
            
            Apttus_Config2__SummaryGroup__c summaryGroup = new Apttus_Config2__SummaryGroup__c (Apttus_Config2__ConfigurationId__c=config.id, Apttus_Config2__ItemSequence__c=78, Apttus_Config2__LineNumber__c=45);
            insert summaryGroup ;
            
            Apttus_Config2__ProductOptionComponent__c prodOptionComponent = new Apttus_Config2__ProductOptionComponent__c(Apttus_Config2__Sequence__c=2);
            insert prodOptionComponent;
            
            Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c(Name='Test',Apttus_Config2__Active__c=true,
                                                                Apttus_Config2__HierarchyLabel__c='High',Apttus_Config2__Type__c='Offering',Apttus_Config2__GuidePage__c='Sample');
            insert category;
            
            Apttus_Config2__ClassificationHierarchy__c classHierarchy = new Apttus_Config2__ClassificationHierarchy__c(Apttus_Config2__HierarchyId__c=category.id, Apttus_Config2__Label__c='Sample');
            insert classHierarchy ;
            
            Apttus_Config2__LineItem__c lineItem = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id  ,1,true,2,'Product/Service',product.id,false,prodOptionComponent.id,
                                                                                   product.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem.Id,'','','','',
                                                                                   false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        lineItem.Apttus_Config2__IsOptionRollupLine__c = false;
        insert lineItem;
                
        Test.startTest();
        
        APT_ProposalApprovalEmailController objemailcontroller = new APT_ProposalApprovalEmailController();
        objemailcontroller.propID=quote.id;
        String result = objemailcontroller.getProductLines();
        
        Test.stopTest();
        
        
        
        
    } 
}