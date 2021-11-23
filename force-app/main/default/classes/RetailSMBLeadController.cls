/*
    @Author      :  Snigdha.Sahu@auspost.com.au    
    @Name        :  RetailSMBLeadController
    @Date        :  15/05/2016
    @Description :  Controller for Lead Creation from the RetailSMB site
*/

public without sharing class RetailSMBLeadController{     

    private final Lead newLead;
    public String Company{get;set;}
    public String FirstName{get;set;}
    public String LastName{get;set;}
    public String Phone{get;set;}
    public String Email{get;set;}
    public String Description{get;set;}
    public String LeadCreator{get;set;}
    public String CreatorWCC{get;set;}
    public String PostalManagerEmail{get;set;}
    

    
    /* public RetailSMBLeadController (ApexPages.StandardController stdController){    
        this.newLead = (Lead)stdController.getRecord();    
    } */
            
    public void submitLead() {                       
       
       
       try {   
                
                //system.debug(' New Lead ' + apexpages.currentpage().getParameters());
                //system.debug ( ' New Lead email = ' + newLead.email );     
                
                Lead newLead = new Lead ();
                newLead.Company = Company;
                newLead.FirstName =  FirstName; 
                newLead.LastName =  LastName ;
                newLead.Email=  Email;
                newLead.Phone =  Phone;  
                newLead.Description =  Description;
                newLead.Name_of_lead_creator__c =  LeadCreator;
                newLead.Creator_Centre_Code__c =  CreatorWCC;
                newLead.Lead_Creator_Email__c =  PostalManagerEmail;    
                    
                
                // look for an associated lead with the same email and currentdate
                for( Lead checkLead :[SELECT Id, Name, CreatedDate, Company FROM Lead WHERE Email = :newLead.email and CreatedDate=TODAY LIMIT 1])
                {
                    newLead.Id = checkLead.Id; //update the same lead                                    
                }
                newLead.leadSource = 'Retail SMB';
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule= true;
                newLead.setOptions(dmo);
                Database.upsertResult results = Database.upsert(newLead);
                if (results.isCreated())
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Lead created successfully.Thank you!'));
                else
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Lead updated successfully.Thank you!'));
                
            }  
            catch (DmlException ex)
            {
                for (Integer i = 0; i < ex.getNumDml(); i++) 
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lead creation failed: ' + ex.getDmlMessage(i)));
 					
                    
                 }
            }

        }

    

}