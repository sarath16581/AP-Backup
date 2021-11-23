/**************************************************
Type:       Contact Controller Extension used for creating and editing Contact.             
Purpose:    Used by ManageContact VF page. User's default Record Type will be used for creating new record.  

saveNew variable is used to decide whether Save or Save&New is clicked.
copyFromBilling variable is used to know whether Address should be copied from Billing or Physical address.
displaySave variable is used to render the "Please Save.." message after the page is refreshed.
newUrl variable is the VF page URL to redirect after Save&New is clicked.
--------------------------------------------------
July-2016:    snigdha.sahu@auspost.com.au Created     
                                  
**************************************************/
public with sharing class ManageContactControllerExtension {
    
    // Constants
    private static final String COMMA = ',';
    private static final String WHITE_SPACE = '';
    private static final String CONTACT_SOBJ = 'Contact';
    private static final String CREATED_DATE = 'CreatedDate';
    private static final String CREATED_BY_ID = 'CreatedById';
    private static final String LAST_MOD_DATE = 'LastModifiedDate';
    private static final String LAST_MOD_ID = 'LastModifiedById';
    
    public Contact currentContact {get; set;}
    public Boolean showComp {get; set;}
    public Boolean success {get; set;}
    public AddressExtension mailingAddress {get;set;}
    public AddressExtension otherAddress {get;set;}
    public Boolean saveNew {get; set;}
    public Boolean copyFromMailing {get; set;}
    public Boolean displaySave {get; set;}
    public String newUrl{get; set;}
    public Date Birthdate {get; set;}

    public ManageContactControllerExtension(ApexPages.StandardController stdController)  
    {
        Id id = ApexPages.currentPage().getParameters().get('id');
        if(id == null) {
            currentContact = new Contact();
            currentContact.OwnerID = UserInfo.getUserId();
                }
        else { 
            String query = 'SELECT ';
            
            /*
            Map<String, Schema.fieldset> contactFieldSets = Schema.SObjectType.Contact.fieldSets.getMap();
            for (String fsName : contactFieldSets.keySet() ) {
                         if(fsName.toLowerCase().startsWith('ManageContact_')) {
                               for(Schema.FieldSetMember f : (contactFieldSets.get(fsName)).getFields()) {
                                   query += f.getFieldPath() + ', ';
                               }
                            }                               
                 }
            query += 'id,MailingCity,MailingState,MailingCountry,MailingPostalCode,MailingStreet,Mailing_DPID__c,';
            query += 'OtherCity,OtherState,OtherCountry,OtherPostalCode,OtherStreet,Other_DPID__c';
            query += ' FROM Contact where id= :id limit 1'; */
              
            // Get a map of field name and field token
            Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(CONTACT_SOBJ.toLowerCase()).getDescribe().Fields.getMap();
            list<string> selectFields = new list<string>();
            if (fMap != null){
                for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    
                    if (fd.isCreateable()){ // field is creatable
                        if(!CREATED_DATE.equalsIgnoreCase(fd.getName()) || CREATED_BY_ID.equalsIgnoreCase(fd.getName()) || LAST_MOD_DATE.equalsIgnoreCase(fd.getName()) || LAST_MOD_ID.equalsIgnoreCase(fd.getName()))
                            selectFields.add(fd.getName());
                    }
                }
            }

            if (!selectFields.isEmpty()){
                for (string s:selectFields){
                    query += s + COMMA ;
                }
                //if (query.endsWith(COMMA)){query = query.substring(0,query.lastIndexOf(COMMA));}

            }
            //create final query 
            
            query += 'id, Edit_Contact__c FROM Contact where id= :id limit 1'; 
            
            //query += 'id,MailingCity,MailingState,MailingCountry,MailingPostalCode,MailingStreet,Mailing_DPID__c,';
            //query += 'OtherCity,OtherState,OtherCountry,OtherPostalCode,OtherStreet,Other_DPID__c, OwnerId';
            //query += ' FROM Contact where id= :id limit 1'; 
                                       
            currentContact = Database.query(query);
         }   


        List<String> mailingStreet = String.isNotBlank(currentContact.MailingStreet) ? currentContact.MailingStreet.split(COMMA) : new List<String>();
        List<String> otherStreet = String.isNotBlank(currentContact.OtherStreet) ? currentContact.OtherStreet.split(COMMA) : new List<String>();
        
        System.debug('** mailingStreet ==>'+mailingStreet);
        System.debug('** otherStreet ==>'+otherStreet);
        
        String mailingStreet1 = mailingStreet.size() > 0 && mailingStreet.get(0) != null ? mailingStreet.get(0) : null ;
        String mailingStreet2 = mailingStreet.size() > 1 && mailingStreet.get(1) != null ? mailingStreet.get(1) : null ;
        
        String otherStreet1 = otherStreet.size() > 0 && otherStreet.get(0) != null ? otherStreet.get(0) : null ;
        String otherStreet2 = otherStreet.size() > 1 && otherStreet.get(1) != null ? otherStreet.get(1) : null ;
        
        System.debug('** mailingStreet1 ==>'+mailingStreet1);
        System.debug('** mailingStreet2 ==>'+mailingStreet2);
        System.debug('** otherStreet1 ==>'+otherStreet1);
        System.debug('** otherStreet2 ==>'+otherStreet2);
        
        mailingAddress = new AddressExtension(mailingStreet1, mailingStreet2,
                                                currentContact.MailingCity, currentContact.MailingState, currentContact.MailingPostalCode, 
                                                currentContact.Mailing_DPID__c, currentContact.MailingCountry);
        otherAddress = new AddressExtension(otherStreet1, otherStreet2, 
                                                currentContact.OtherCity, currentContact.OtherState, currentContact.OtherPostalCode, 
                                                currentContact.Other_DPID__c,currentContact.OtherCountry);
        success = false;
        showComp = true;
        displaySave = false;
    }    
    
    public PageReference saveContact() {
      PageReference pr;
      try
      {
        System.debug('** mailingAddress==>'+mailingAddress);
        System.debug('** otherAddress==>'+otherAddress);
        currentContact.MailingStreet = mailingAddress.line1 + (String.isNotBlank(mailingAddress.line2) ? COMMA : WHITE_SPACE) + mailingAddress.line2;
        currentContact.MailingCity = mailingAddress.city;
        currentContact.MailingState = mailingAddress.state;
        currentContact.MailingPostalCode = mailingAddress.postcode;
        currentContact.MailingCountry = mailingAddress.country;
        currentContact.Mailing_DPID__c = mailingAddress.dpid;
        
        currentContact.OtherStreet = otherAddress.line1 + (String.isNotBlank(otherAddress.line2) ? COMMA : WHITE_SPACE) + otherAddress.line2;
        currentContact.OtherCity = otherAddress.city;
        currentContact.OtherState = otherAddress.state;
        currentContact.OtherPostalCode = otherAddress.postcode;
        currentContact.OtherCountry = otherAddress.country;
        currentContact.Other_DPID__c = otherAddress.dpid;
        
        upsert currentContact;
      }
      catch(DmlException ex){
        for (Integer i = 0; i < ex.getNumDml(); i++) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(i))); 
        }
      }
      catch(Exception ex)
      {
        ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The Contact has missing required fields, or a validation rule. The system was not able to save the Contact');
        ApexPages.addMessage(errorMsg);
      }
      success = true;
      displaySave = false;
/**
If Save & New is clicked, then redirect to the same VF page with blank values.
If Save is clicked, then redirect to the details page of the Contact record.
**/      
      if(saveNew) {
          saveNew=null;
          copyFromMailing=null;
          pr = new PageReference(newUrl);
         }
      else {    
          pr =  new PageReference('/' + currentContact.Id);
          }
      pr.setRedirect(true);
      return pr;
           
    }
    
   public void copyAddress() {
   
         if(copyFromMailing) {
            currentContact.OtherStreet = mailingAddress.line1 + (String.isNotBlank(mailingAddress.line2) ? COMMA : WHITE_SPACE) + mailingAddress.line2;
            currentContact.OtherCity = mailingAddress.city;
            currentContact.OtherState = mailingAddress.state;
            currentContact.OtherPostalCode = mailingAddress.postcode;
            currentContact.OtherCountry = mailingAddress.country;
            currentContact.Other_DPID__c = mailingAddress.dpid;
            otherAddress = mailingAddress.clone();
            }
         else {
                currentContact.MailingStreet = otherAddress.line1 + (String.isNotBlank(otherAddress.line2) ? COMMA : WHITE_SPACE) + otherAddress.line2;
                currentContact.MailingCity = otherAddress.city;
                currentContact.MailingState = otherAddress.state;
                currentContact.MailingPostalCode = otherAddress.postcode;
                currentContact.MailingCountry = otherAddress.country;
                currentContact.Mailing_DPID__c = otherAddress.dpid;
                mailingAddress = otherAddress.clone();
                }   
         displaySave = true;

    }

    

    public PageReference cancelOp() {
        success=false;
        return new PageReference('/003/o');
    }
}