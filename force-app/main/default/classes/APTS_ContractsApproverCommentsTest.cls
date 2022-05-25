@isTest
public class APTS_ContractsApproverCommentsTest {
    public static testmethod void testmethod1(){
        
        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000';
        insert tempacct;
        
        Contact con= APT_TestUtils.createContact();
        insert con;
        
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        insert proposal;
        
         Application__c appli = new Application__c();
        //appli.Name = 'test';
        appli.Opportunity__c = opp.Id;
        appli.Account__c = tempacct.Id;
        insert appli;
        
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel';
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract.APT_New_Rate_Card_Download__c = true;
        //User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];
        aptContract.OwnerId = UserInfo.getUserId();
        aptContract.APMS_Application__c = appli.ID;
        aptContract.Apttus__Status_Category__c = 'Request';
        aptContract.Apttus__Status__c = 'Request';
        aptContract.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        insert aptContract;

		
		Apttus_Approval__Approval_Request__c approvalReq = new Apttus_Approval__Approval_Request__c();
        approvalReq.Apttus_Approval__Approval_Status__c = 'Not Submitted';
        //approvalReq.Apttus_Approval__ChildObjectId__c = bundleLine.Id;
		approvalReq.Apttus_Approval__Object_Id__c = aptContract.ID;
        
        approvalReq.Apttus_Approval__Object_Type__c = 'Apttus__APTS_Agreement__c';
        
		approvalReq.Apttus_Approval__Initial_Submitter__c = UserInfo.getUserId();
        insert approvalReq;
        
        approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
        approvalReq.Apttus_Approval__Approver_Comments__c = 'Approved Discount - 89';
        approvalReq.Apttus_Approval__StepLabel__c = 'Dangerous Goods';
        approvalReq.Apttus_QPApprov__ProposalId__c = proposal.Id;
        update approvalReq;
        
        System.debug('##########Approval request'+approvalReq);
        
        Test.startTest();
        
        APTS_ContractApproverCommentsController objController = new APTS_ContractApproverCommentsController();
        objController.ContractID = ID.valueOf(aptContract.Id);
        objController.ContractSO = aptContract;
        
        objController.getApprovalRequestComment();
        
        Test.stopTest();       
    } 
    
    
    
     public static testmethod void testmethod2(){
        
        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000';
        insert tempacct;
        
        Contact con= APT_TestUtils.createContact();
        insert con;
        
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        insert proposal;
        
         Application__c appli = new Application__c();
        //appli.Name = 'test';
        appli.Opportunity__c = opp.Id;
        appli.Account__c = tempacct.Id;
        insert appli;
        
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel';
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract.APT_New_Rate_Card_Download__c = true;
        //User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];
        aptContract.OwnerId = UserInfo.getUserId();
        aptContract.APMS_Application__c = appli.ID;
        aptContract.Apttus__Status_Category__c = 'Request';
        aptContract.Apttus__Status__c = 'Request';
        aptContract.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        insert aptContract;

		
		Apttus_Approval__Approval_Request__c approvalReq = new Apttus_Approval__Approval_Request__c();
        approvalReq.Apttus_Approval__Approval_Status__c = 'Not Submitted';
        //approvalReq.Apttus_Approval__ChildObjectId__c = bundleLine.Id;
		approvalReq.Apttus_Approval__Object_Id__c = aptContract.ID;
		approvalReq.Apttus_Approval__Initial_Submitter__c = UserInfo.getUserId();
        approvalReq.Apttus_Approval__Object_Type__c = 'Apttus__APTS_Agreement__c';
        insert approvalReq;
        
        approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
        approvalReq.Apttus_Approval__Approver_Comments__c = 'Approved Discount - 89';
        approvalReq.Apttus_Approval__StepLabel__c = 'Dangerous Goods';
        approvalReq.Apttus_QPApprov__ProposalId__c = proposal.Id;
        update approvalReq;
        
        System.debug('##########Approval request'+approvalReq);
        
        Test.startTest();
        
        APT_ContractSOPApprovedRejController objController = new APT_ContractSOPApprovedRejController();
        objController.ContractID = ID.valueOf(aptContract.Id);
        
        objController.getapprovalRequestSO();
        objController.getagreementSO();
        
        Test.stopTest();
        
        
        
    } 
    
   public static testmethod String testGetHeaderURL(){
        Apttus_Config2__ConfigSystemProperties__c cofingSetting = new Apttus_Config2__ConfigSystemProperties__c(name = 'System Properties');
 		insert cofingSetting;
        
        Folder folder = [SELECT Id FROM Folder where Type = 'Document' LIMIT 1];
        Document objDocument = new Document();
        objDocument.Name = 'R2T Contract Letterhead';
        objDocument.FolderId = folder.ID;
        objDocument.Body = blob.valueOf('test String');
        insert objDocument;
        Test.startTest();
        APT_URLimagesHeaderFooter objController = new APT_URLimagesHeaderFooter();
        String headerURL = objController.getHeaderURL();
        Test.stopTest();
       return headerURL;
        
    }   
    
    
    public static testmethod String testGetFooterURL(){
        Apttus_Config2__ConfigSystemProperties__c cofingSetting = new Apttus_Config2__ConfigSystemProperties__c(name = 'System Properties');
 		insert cofingSetting;
        
        Folder folder = [SELECT Id FROM Folder where Type = 'Document' LIMIT 1];
        Document objDocument = new Document();
        objDocument.Name = 'R2T_Quote_LetterHead_Footer';
        objDocument.FolderId = folder.ID;
        objDocument.Body = blob.valueOf('test String');
        insert objDocument;
        Test.startTest();
        APT_URLimagesHeaderFooter objController = new APT_URLimagesHeaderFooter();
        String footerURL = objController.getFooterURL();
        Test.stopTest();
       return footerURL;
        
    } 
    
   /* public static testmethod String testQuoteGetHeaderURL(){
        Apttus_Config2__ConfigSystemProperties__c cofingSetting = new Apttus_Config2__ConfigSystemProperties__c(name = 'System Properties');
 		insert cofingSetting;
        
        Folder folder = [SELECT Id FROM Folder where Type = 'Document' LIMIT 1];
        Document objDocument = new Document();
        objDocument.Name = 'R2T_Quote_LetterHead';
        objDocument.DeveloperName = 'APT_R2T_Quote_LetterHead';
       
        objDocument.FolderId = folder.ID;
        objDocument.Body = blob.valueOf('test String');
        insert objDocument;
        Test.startTest();
        APT_QuoteURLimagesHeaderFooter objController = new APT_QuoteURLimagesHeaderFooter();
        String headerURL = objController.getHeaderURL();
        Test.stopTest();
       return headerURL;
        
    }*/
    
    public static testmethod String testQuoteGetFooterURL(){
        Apttus_Config2__ConfigSystemProperties__c cofingSetting = new Apttus_Config2__ConfigSystemProperties__c(name = 'System Properties');
 		insert cofingSetting;
        
        Folder folder = [SELECT Id FROM Folder where Type = 'Document' LIMIT 1];
        Document objDocument = new Document();
        objDocument.Name = 'R2T_Quote_LetterHead_Footer';
        objDocument.FolderId = folder.ID;
        objDocument.Body = blob.valueOf('test String');
        insert objDocument;
        Test.startTest();
        APT_QuoteURLimagesHeaderFooter objController = new APT_QuoteURLimagesHeaderFooter();
        String footerURL = objController.getFooterURL();
        Test.stopTest();
       return footerURL;
        
    } 
    public static testmethod void testDGTProposalApprovalsgetComment(){
        
        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000';
        insert tempacct;
        
        Contact con= APT_TestUtils.createContact();
        insert con;
        
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        insert proposal;
        
         Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
         insert prodconfig;
        
         Application__c appli = new Application__c();
        //appli.Name = 'test';
        appli.Opportunity__c = opp.Id;
        appli.Account__c = tempacct.Id;
        insert appli;
        
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel';
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract.APT_New_Rate_Card_Download__c = true;
        //User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];
        aptContract.OwnerId = UserInfo.getUserId();
        aptContract.APMS_Application__c = appli.ID;
        aptContract.Apttus__Status_Category__c = 'Request';
        aptContract.Apttus__Status__c = 'Request';
        aptContract.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        insert aptContract;
        
        Product2 product =APT_TestUtils.createInternationalProduct('Car',APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS,'Postal Services');
            product.Apttus_Config2__ConfigurationType__c = APT_Constants.LABEL_LINE_TYPE_BUNDLE;
            insert product;

		
		Apttus_Approval__Approval_Request__c approvalReq = new Apttus_Approval__Approval_Request__c();
        approvalReq.Apttus_Approval__Approval_Status__c = 'Not Submitted';
        //approvalReq.Apttus_Approval__ChildObjectId__c = bundleLine.Id;
		approvalReq.Apttus_Approval__Object_Id__c = proposal.ID;
		approvalReq.Apttus_Approval__Initial_Submitter__c = UserInfo.getUserId();
	    approvalReq.Apttus_Approval__Approver_Comments__c = 'Approved Discount - 89';
        approvalReq.Apttus_Approval__StepLabel__c = 'Dangerous Goods';
        approvalReq.Apttus_QPApprov__ProposalId__c = proposal.Id;
        approvalReq.Apttus_Approval__Object_Type__c = 'Apttus_Config2__ProductConfiguration__c';
        insert approvalReq;
        
        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
        insert priceListItem;
        
        Apttus_Config2__ProductOptionComponent__c prodOptionComponent = new Apttus_Config2__ProductOptionComponent__c(Apttus_Config2__Sequence__c=2);
            insert prodOptionComponent;
        
        Apttus_Config2__LineItem__c lineItem = APT_TestUtils.getConfigLineItem(prodconfig.id,null ,1,true,2,'Product/Service',product.id,false,prodOptionComponent.id,product.id,null,'',2.3,false,'',2,priceList.id,priceListItem.Id,'','','','',false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        lineItem.Apttus_Config2__IsOptionRollupLine__c = false;
       
        insert lineItem;
        
        System.debug('##########Approval request'+approvalReq);
        
        Test.startTest();
        
        APT_DGTProposalApprovalsCustomController objController = new APT_DGTProposalApprovalsCustomController();
       objController.propSO =  proposal;
        objController.propID = proposal.ID;
        String approvalComment = objController.getApprovalRequestComment();
        String pLines = objController.getProductLines();
        
        Test.stopTest();       
    } 
    
    
    
  
    
    
}