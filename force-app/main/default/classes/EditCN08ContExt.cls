/**************************************************
Type:       Controller Extension class       
Purpose:    Prefill CN08 from case and article where possible.
            Insert/update case attachment of CN08 PDF.
Used by:    EditCN08.page
History:
-------------------------------------------------- 
25/02/2014  A. Tran (Bluewolf)  Created.
9/12/2015	kalpita test		updated - to add null check as case console view related list using custom page button
**************************************************/

public with sharing class EditCN08ContExt {
    
    public CN08__c cn08 { get; set; }
    private ApexPages.StandardController controller;

    public EditCN08ContExt(ApexPages.StandardController controller) {
        
        this.controller = controller;
        
        if (controller.getRecord() != null) 
        {
            cn08 = (CN08__c)controller.getRecord();
            
            if (cn08.Id == null) {
                
                Id caseId = apexpages.currentpage().getparameters().get('caseId')!=null ? 
                                apexpages.currentpage().getparameters().get('caseId') : cn08.Case__c;
                cn08.Case__c = caseId;                                
                Case kase = getCase(caseId);
                Id articleId;
                if(kase.ArticleTest__c!=null) {
                    articleId = kase.ArticleTest__c;
                }
                
                System.debug('XXXXBWXXXX: Case' + caseId);
                System.debug('XXXXBWXXXX: Article' + articleId);
                
                Article__c article = getArticle(articleId);
                
                preloadCN08(kase, article);
                
            } else {
                cn08 = getCN08(cn08.Id);
            }
        }
    }
    
    public PageReference save() {
        
        if (cn08.Id == null) {
            insert cn08;
        } else {
            update cn08;
        }        
        
        return null;
    }
    
    public PageReference createAttachment() {
        cn08 = getCN08(cn08.Id);
        PageReference pdf = getCN08Pdf(cn08.Id);

        String cn08Name = cn08.Name + '.pdf';
        List<Attachment> attachList = [SELECT Id, Name, LastModifiedDate FROM Attachment WHERE ParentId = :cn08.Case__c AND Name = :cn08Name];
        
        if (attachList.isEmpty()) {
            // modified by shengpeng.xiao@bluewolf.com at 2014.7.9
            // adjust test class as getcontent is not allowed in test method
            Blob body;
            if(Test.isRunningTest()) {
                body = Blob.valueOf('test body');
            }else {
                body = pdf.getContent();
            }
            Attachment attach = new Attachment(
                ParentId = cn08.Case__c, 
                Name = cn08.Name + '.pdf', 
                Body = body
            );
            
            insert attach;
        } else {
            if(Test.isRunningTest()) {
                attachList[0].Body = Blob.valueOf('test body');
            }else {
                attachList[0].Body = pdf.getContent();
            }
            
            update attachList[0];
        }
                
        return pdf;
    }
    
    private PageReference getCN08Pdf(Id cn08Id) {
        PageReference pdf = Page.SSSWCN08Form;
        pdf.getParameters().put('id', cn08Id);
        pdf.setRedirect(false);

        return pdf;
    }

    private Article__c getArticle(Id caseArticleId) {
        String query = 'SELECT ArticleID__c, ReceiverName__c, ReceiverAddress__c, ReceiverEmail__c, SubProduct__c, ServiceCode__c, SignatureRequiredFlag__c,'; 
        query += ' ConsignmentParcelCount__c, ArticleCount__c, DeliveryInstructions__c, ArticleTransitAmountValue__c, ActualWeight__c, SenderName__c,';
        query += ' SenderCompany__c, SenderAddress__c, SenderEmail__c, TimetableCode__c, DestinationPostCode__c, ProductCategory__c, ArticleLodgementDate__c,';
        query += ' MailCategory__c, Service__c, MailClass__c, MailSubClass__c, InsuranceAmount__c';
        query += ' FROM Article__c';
        query += ' WHERE id = :caseArticleId LIMIT 1';
        
        List<Article__c> obj = Database.query(query); 
        return obj.size() > 0 ? obj[0] : null;
    }
    
    private void preloadCN08(Case c, Article__c article) {    

        if (article != null) {  

            if (article.MailCategory__c != null && article.MailCategory__c.toLowerCase().contains('airmail')) {
                cn08.IsPriority__c = true;
                cn08.MailType__c = 'Priority/Air';
                
                if (cn08.SpecialIndications__c != null && cn08.SpecialIndications__c.length() > 0) {
                    cn08.SpecialIndications__c = cn08.SpecialIndications__c + ';By airmail';
                } else {
                    cn08.SpecialIndications__c = 'By airmail';
                }
                
            } else if (article.MailCategory__c != null && (article.MailCategory__c.toLowerCase().contains('seamail') || article.MailCategory__c.toLowerCase().contains('sea mail'))) {
                cn08.IsPriority__c = false;
                cn08.MailType__c = 'S.A.L.';
                
                if (cn08.SpecialIndications__c != null && cn08.SpecialIndications__c.length() > 0) {
                    cn08.SpecialIndications__c = cn08.SpecialIndications__c + ';S.A.L.';
                } else {
                    cn08.SpecialIndications__c = 'S.A.L.';
                }
            }
            
            if (article.Service__c != null && article.Service__c.toLowerCase().contains('registered')) {
                cn08.InquiryType__c = 'Registered';
            }
            
            if (article.MailClass__c != null && article.MailClass__c.toLowerCase().contains('letter')) {
                cn08.ItemType__c = 'Letter';
            }

            cn08.ItemWeight__c = article.ActualWeight__c;
            cn08.NumberOfItems__c = article.ArticleCount__c;

            cn08.InsuredValue__c = article.InsuranceAmount__c;
        }
        
        if (c != null) {            
            cn08.SenderName__c = c.Primary_Name__c;
            cn08.SenderAddress__c = c.Address1__c;
            
            cn08.AddresseeName__c = c.Secondary_Contact__c;
            cn08.AddresseeAddress__c = c.Address2__c;
        }        
    }
    
    private CN08__c getCN08(Id cn08Id) {
        String query = 'select AddresseeAddress__c, AddresseeDeclarationRequested__c, AddresseeName__c, AddresseePhone__c, AmountOfIndemnity__c, BillListNumber__c, BulkAdvice__c, Case__c,';
        query += ' ChargesPaid__c, CODAmount__c, CODCurrency__c, ContentsDescription__c, DateOfArrival__c, DateOfDuplicate__c, DateOfInquiry__c, DispatchDate__c,';
        query += ' DispatchingOffficeOfExchange__c, Id, InquiryType__c, InsuredValue__c, IsDeleted, IsPriority__c, ItemType__c, ItemWeight__c,';
        query += ' ListType__c, MailNumber__c, MailType__c, Name, NumberOfItems__c, OfficeOfExchangeOfDestination__c, OfficePostedFrom__c, OtherFees__c, PostedDate__c, ReasonForInquiry__c, ReceiptSeen__c,';
        query += ' Reference__c, ReturnAddress__c, SenderAddress__c, SenderName__c, SenderPhone__c, SerialNumber__c, ServiceOfDestination__c, SpecialIndications__c, ToBeSentTo__c';
        query += ' from CN08__c WHERE Id = :cn08Id';
        
        List<CN08__c> cn08List = Database.query(query);
        return cn08List.isEmpty() ? null : cn08List[0]; 
    }

    private Case getCase(Id caseId) {
        String query = 'select Id, ArticleTest__c, Primary_Name__c, Address1__c, Secondary_Contact__c, Address2__c  ';
        query += '  from Case WHERE Id = :caseId';
        
        List<Case> caseList = Database.query(query);
        return caseList.isEmpty() ? null : caseList[0]; 
    }
    
}