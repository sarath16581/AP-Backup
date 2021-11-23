/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 03/12/2015
  * @description  : Controller class for CN18 form
  */
/*******************************  History ************************************************
    
*******************************  History ************************************************/
public with sharing class SSSWCN18FormContExt {
    
    public transient String htmlBody { get; set; }
    public Case relatedCase {get;set;}
    private String caseId ;
    private Boolean isCreate = false;
    public STring msgBody1 {get;set;}
    public STring msgBody2 {get;set;}
    public STring msgBody3 {get;set;}
    
    /** 
      * @name: SSSWCN18FormContExt()
      * @desciption: Controller method to get the case record 
      * @param: NA
      * @return: NA
      *
      */
    public SSSWCN18FormContExt(ApexPages.StandardController controller) {
        
        if (controller.getRecord() != null) {
            relatedCase = (Case)controller.getRecord(); 
            caseId = controller.getRecord().Id;
            isCreate = apexpages.currentpage().getparameters().get('create') == 'true' ? true : false;
        }
    }
    
    /** 
      * @name: getBody()
      * @desciption: method to create the body of the cn18 form and attach to case
      * @param: NA
      * @return: NA
      *
      */
    public void getBody() {
        try {

            if(!String.isBlank(caseId)) {
                relatedCase = [Select Id, CaseNumber, Secondary_Contact__c, SecondaryContact__r.FirstName, Address2Line1__c ,Address2State__c ,Address2Postcode__c, 
                                SecondaryContact__r.LastName, Address2line2__c,Address1Line1__c,Address1Suburb__c,Address1line2__c,
                                Address1State__c,Address1Postcode__c, Contact.MailingStreet, Contact.MailingStreet2__c, Address2Suburb__c ,
                                Contact.MailingCity,Contact.MailingState,Contact.MailingPostalCode,
                                Account.Name,ProductCategory__c,ReferenceID__c,Contact.Name,
                                DescriptionofContents__c,DatePosted__c,ProductSubCategory__c,
                                Contact.Firstname, Contact.LastName,Primary_Name__c,Address1__c,
                                Address2__c from Case where Id =: caseId limit 1];
                //creating message body
                String datePosted = relatedCase.DatePosted__c!=null   ? relatedCase.DatePosted__c.day()+'/'+
                                relatedCase.DatePosted__c.month() +'/'+relatedCase.DatePosted__c.year()  :''; 
                String addreseeFrstName = !STring.isblank(relatedCase.Secondary_Contact__c) ? 
                                                    relatedCase.Secondary_Contact__c.split(' ' , 2).get(0) : '';                                                      
               
                msgBody1 = Label.CL_CN18_Content.replaceAll('#addFName',addreseeFrstName).replaceAll('#contName',relatedCase.Contact.Name).replaceAll('#caseNumber',relatedCase.CaseNumber);
               
                String senderAdd = !String.isBlank(relatedCase.Primary_Name__c ) ? relatedCase.Primary_Name__c +', ' : '' ;
                senderAdd += !String.isBlank(relatedCase.Address1Line1__c ) ? relatedCase.Address1Line1__c +', ' : ''  ;
                senderAdd += !String.isBlank(relatedCase.Address1Line2__c) ? relatedCase.Address1Line2__c +', ' : ''  ;
                senderAdd += !String.isBlank(relatedCase.Address1Suburb__c ) ? relatedCase.Address1Suburb__c +', ' : ''  ;
                senderAdd += !String.isBlank(relatedCase.Address1State__c ) ? relatedCase.Address1State__c +', ' : ''  ;
                senderAdd += !String.isBlank(relatedCase.Address1Postcode__c ) ? relatedCase.Address1Postcode__c +', ' : ''  ;
                senderAdd += '<br/><br/>';                
                String refNumber = !String.isBlank(relatedCase.ReferenceID__c) ? relatedCase.ReferenceID__c : '';
                String descCont = !String.isBlank(relatedCase.DescriptionofContents__c) ? relatedCase.DescriptionofContents__c : '' ;
                  
                msgBody2 = Label.CL_CN18_ParcelDetails.replaceAll('#refNumber#',refNumber).replaceAll('#senderDetails#',senderAdd ).replaceAll('#descOfCOntent#',descCont ).replaceAll('#datePosted#',datePosted );
                
                msgBody3 = Label.CL_CN18_Signature.replaceAll('#usernameInitial#',userinfo.getFirstName() +' ' + userinfo.getLastName().substring(0,1));
                
                PageReference pdf = Page.SSSWCN18Form;
                // add parent id to the parameters for standardcontroller
                pdf.getParameters().put('id',caseId);
            
                // create the new attachment
                Attachment attach = new Attachment();
                // the contents of the attachment from the pdf
                Blob body;
                // returns the output of the page as a PDF
                body = !test.isRunningTest() ? body = pdf.getContent() : Blob.valueOf('Unit Test Attachment Body');
                attach.Body = body;
                // add the user entered name
                attach.Name = 'CN 18 Form'+ '.pdf';
                attach.IsPrivate = true;
                // attach the pdf to the account
                attach.ParentId = caseId;
                if(isCreate)  {
                    database.insert(attach);
                }
            }
            
        } 
        catch (Exception exp) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    'SSSWCN18FormContExt', 'getBody', 
                                                    null, LoggingLevel.ERROR);
        }
    } 
    
}