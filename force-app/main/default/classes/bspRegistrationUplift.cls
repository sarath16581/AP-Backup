/**
 * @description       : Copied code from 'bspRegistration' class and modified to lightning uplift need basis
 * @author            : avula.jansirani@auspost.com.au
 * @group             : 
 * @last modified on  : 08-05-2020
 * @last modified by  : avula.jansirani@auspost.com.au
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   08-05-2020  avula.jansirani@auspost.com.au   Initial Version
**/
public without sharing class bspRegistrationUplift
{
    /**************************************************
    Type:         Controller for visualforce page bspRegistrationUplift
    History:
    --------------------------------------------------
    2020-07-13	  avula.jansirani@auspost.com.au		Initial updation to lightning uplift(modified "bspRegistration.apxc" class code in this class to work align with LWC )
    2020-04-11    ankur.gandhi@auspost.com.au           Adding without sharing due to critical update for @AuraEnabled methods access
    2020-11-26    avula.jansirani@auspost.com.au        Removed System.debug lines
    **************************************************/

    public static Contact c {get; set;}
    public static AddressExtension mailingAddress {get;set;}
    private static string ccuProfileId {get;set;}
    private static string generalRecordTypeId {get;set;}
    private static string usernameExtension {get;set;}
    private static string caseSubject {get; set;}

    /** 
    * Custom Exception
    * */
    class ErrorException extends Exception{}

    /*
     * grab default detail from Custom Setting to create new bsp user
     *  Changed to static for LWC component.
     * */
    private static void getBSPSetting()
    {
        CCUSettings__c configSetting = CCUSettings__c.getInstance();
        ccuProfileId = configSetting.CCUCommunityUserProfileId__c;
        generalRecordTypeId = configSetting.GeneralRecordTypeId__c;
        usernameExtension = configSetting.UsernameExtension__c;
        caseSubject = configSetting.AdminCaseSubject__c;
    }

    /**
	 * @description creating new BSP Community user
	 * @param mailingAddressInput as 'user address'
	 * @param businessName as 'Organisation Name'
	 * @param businessNumber as 'Organisation number'
	 * @param contactStr as 'Contact details in String format'
	 * */
    @AuraEnabled
    public static void save(String mailingAddressInput, String businessName, String businessNumber, String contactStr) {
        
        mailingAddress = (AddressExtension) JSON.deserialize(mailingAddressInput, AddressExtension.class);
        c = (Contact)JSON.deserialize(contactStr, Contact.class);
        
        // default to Australia
        c.MailingCountry = 'Australia';
        c.Phone = c.Phone.replaceAll('[^\\d]','');
        
        getBSPSetting();
        
        // When Create Account button is clicked,
        //    - create a Contact
        //    - create a User
        //    - Create a Case
        SavePoint sp = Database.setSavepoint();
        String myBusinessName;
        myBusinessName = string.escapeSingleQuotes(businessName.trim());
        myBusinessName = '\''+myBusinessName + '\'';
        businessNumber = string.escapeSingleQuotes(businessNumber.trim());
        
        //Updated Nov. 22, 2016 - StarTrack update to not allow portal guest to create new account against StarTrack billing account (Australia Post account number) and StarTrack Account Name (Business Name)
        String query = 'SELECT Id, Organisation__r.Id, Organisation__r.Name FROM Billing_Account__c WHERE Organisation__r.Name = ' + myBusinessName + ' AND LEGACY_ID__c = \''+businessNumber+'\' AND Source_System__c = \'' + BspConstants.SOURCE_SYSTEM_SAP_ERP + '\' LIMIT 1';
        
        // Check if entered Business name and Australia Post account number exists
        List<Billing_Account__c> accts = Database.query(query);
        if(accts.size() == 0){
            string msgString = 'Your account is not created. Please provide the right Business Name and Business Credit Account.';
            throw new ErrorException(msgString);
        }
        // pick the first record from the list
        Billing_Account__c a = accts[0];
        
        // check if the contact already exists in CRM,
        //    based on FirstName, LastName and Email
        List<Contact> checkContacts = new List<Contact>();
        Boolean canICreateContact = true;
        Boolean canIUpdateContact = false;
        //Fix - INC1308447 Updated SOQL to include Phone
        checkContacts = [SELECT Id, Email, FirstName, LastName,Account.Name,Phone,MobilePhone
                         FROM Contact
                         WHERE FirstName = : c.FirstName
                         AND LastName = : c.LastName
                         AND Email = : c.Email
                         AND BillingAccount__c = :a.Id
                         AND IsPersonAccount = false
                         ORDER BY CreatedDate];
        if(checkContacts.size()==0) {
            //-[Jansi[15-07-2020]:Added FirstName,LastName,MobilePhone to query which is giving error "SObject row was retrieved via SOQL without querying the requested field: Contact.FirstName" in below code]
            checkContacts = [SELECT Id, Email,Phone,FirstName,LastName,MobilePhone
                             FROM Contact
                             WHERE FirstName = : c.FirstName
                             AND LastName = : c.LastName
                             AND Email = : c.Email
                             AND BillingAccount__c = null
                             AND IsPersonAccount = false
                             ORDER BY CreatedDate];
            if(checkContacts.size()==0) {
                checkContacts = [SELECT Id, Email,Phone
                                 FROM Contact
                                 WHERE FirstName = : c.FirstName
                                 AND LastName = : c.LastName
                                 AND Email = : c.Email
                                 AND IsPersonAccount = false
                                 ORDER BY CreatedDate];

                if(checkContacts.size()>0) {
                    // if the Contact already exists, throw error
                    string msgString = 'You already have an existing account with Australia Post related to a different Billing Account. Please contact Australia Post to update your details.';
                    throw new ErrorException(msgString);
                }
            }
            else{
                canIUpdateContact = true;
                c = checkContacts[0];
            }
        } else {
            canICreateContact = false;
            c = checkContacts[0];
        }
        
        
        
        // check if the particular username already been taken
        List<User> checkUsers = [SELECT Id
                                 FROM User
                                 WHERE Username = : c.Email + usernameExtension];
        if(checkUsers.size()>0)
        {
            // if the User already exists, throw error
            string msgString = 'The Email Address/Login Name is already taken. Please contact us to enable your account. Or use forget password to receive your latest credentials via Email';
            //[Jansi: 15-07-2020]: commented ApexPages and added new exception thrown
            throw new ErrorException(msgString);
        }
        
        
        //Set contact details
        c.accountId = a.Organisation__r.Id;
        // fetch info from component variable
        c.MailingStreet = mailingAddress.line1.split(',',2)[0];
        c.MailingStreet2__c = mailingAddress.line2;
        c.MailingCity = mailingAddress.city;
        c.MailingState = mailingAddress.state;
        c.MailingPostalCode = mailingAddress.postcode;
        c.MailingCountry = mailingAddress.countryName;
        c.Mailing_DPID__c = mailingAddress.dpid;
        // set billing account on contact
        c.BillingAccount__c = a.Id;
        try{
            If(CanIUpdateContact) {
                update c;
            }
            else If(CanICreateContact) {
                insert c;
            }
            
            // grab the bam application
            BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
            BAMApplicationRole__c role = [Select Id From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' and Role__c = 'User'];
            
            // create BAM application and contact role for initial state
            BAMContactApplication__c contactApp = new BAMContactApplication__c(Application__c = app.Id, Contact__c = c.Id, Status__c = 'Active');
            insert contactApp;
            
            BAMContactRole__c contactRole = new BAMContactRole__c(ContactApplication__c = contactApp.Id, ApplicationRole__c = role.Id, Status__c = 'Active');
            insert contactRole;
        }
        catch(Exception ex){
            Database.rollback(sp);
            throw new ErrorException(ex.getMessage());
        }
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.EmailHeader.triggerUserEmail = true;
        string aliasString = c.FirstName.substring(0,1) + c.LastName;
        if(c.LastName.Length()>4){
            aliasString = c.FirstName.substring(0,1) + c.LastName.substring(0,4);
        }
        
        User u = new User(  alias = aliasString,
                          firstname = c.FirstName,
                          Street = mailingAddress.line1,
                          City = mailingAddress.city,
                          State = mailingAddress.state,
                          PostalCode = mailingAddress.postcode,
                          Country = mailingAddress.countryName,
                          DPID__c = mailingAddress.dpid,
                          CompanyName = businessName,
                          Phone = c.Phone,
                          MobilePhone = c.MobilePhone,
                          email=c.email,
                          emailencodingkey='UTF-8',
                          lastname=c.LastName,
                          languagelocalekey='en_US',
                          localesidkey='en_AU',
                          profileid = ccuProfileId,
                          contactId=c.Id,
                          timezonesidkey='Australia/Sydney',
                          username=c.email+usernameExtension);
        u.setOptions(dmo);
        
        try {
            insert u;
        }catch(Exception ex){
            Database.rollback(sp);
            throw new ErrorException(ex.getMessage());
        }
        //--[Jansi:23-07-2020] Assign PSET
        assignPermissionSet(u.Id, 'BSP_Community_Access');
        
        Case myCase = new Case(RecordTypeId=generalRecordTypeId,
                               Subject=caseSubject,
                               Type='General Enquiry',
                               Origin='BSP',
                               ContactId=c.Id);
        try{
            insert myCase;
        }catch(Exception ex){
            Database.rollback(sp);
            throw new ErrorException(ex.getMessage());
        }
    }

    /**
	 * @description assigning 'BSP_Community_Access' PSet to the newly created bsp user
	 * @param userId as 'user Id'
	 */
    @future
    public static void assignPermissionSet(Id userId, String permissionSetName){
        try{
            //--[Jansi:23-07-2020] Assign PSET
            PermissionSet bspPset = [SELECT Id FROM PermissionSet where Name = :permissionSetName LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.PermissionSetId = bspPset.Id;
            psa.AssigneeId = userId;
            insert psa;   
            
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'Error while assigning PSet to community User =>'+ex.getMessage() );
        }
    }


    /**
    * Get List of the countries for address LWC
    * */
    @AuraEnabled(cacheable = true)
    public static List<SelectOptionCustom> getCountries() {
        // this function generates picklist values
        List<SelectOptionCustom> options = new List<SelectOptionCustom>();
        Map<String, CountryCodes__c> countries = CountryCodes__c.getAll();
        List<String> countryCodes = new List<String>();
        countryCodes.addAll(countries.keySet());
        countryCodes.sort();
        for( String countryCode : countryCodes){
            CountryCodes__c country = countries.get(countryCode);
            options.add(new SelectOptionCustom(country.Name,country.Name));
        }
        return options;
    }
    
    
    /**
    * Custom select Option: Added this because standard SelectOption class is not supported by LWC
    * */
    public class SelectOptionCustom {
        public SelectOptionCustom(String value, String label) {
            this.value = value;
            this.label = label;
            this.disabled = false;
            this.escapeItem = false;
        }
        
        public SelectOptionCustom(String value, String label, Boolean isDisabled) {
            this.value = value;
            this.label = label;
            this.disabled = isDisabled;
            this.escapeItem = false;
        }
        
        @AuraEnabled public String label { get;set; }
        @AuraEnabled public String value { get;set; }
        @AuraEnabled public Boolean disabled { get;set; }
        @AuraEnabled public Boolean escapeItem { get;set; }
        
    }

}