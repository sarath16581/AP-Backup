/**************************************************
Type:         Controller for visualforce page bspProfile
History:
--------------------------------------------------
2014-05-27    Louis Wang (Bluewolf)        Created.
2019-06-27    nathan.franklin@auspost.com.au   Updated for BAM capability
**************************************************/
public with sharing class bspProfile extends bspBase {

    /*********
     * Can be removed on next deployment... added due to deployment errors
     * https://success.salesforce.com/issues_view?id=a1p300000008YkUAAU
     **/
    public Boolean hideSSCR5 {get;set;}
    /*
     * END
     **********/

    public User u {get;set;}
    public boolean isPasswordPage {get;set;}
    public String section {get;set;}
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}
    public AddressExtension mailingAddress {get;set;}
    public string businessName {get;set;}
    public string businessNumber {get;set;}
    
    public bspProfile()
    {    
        //Set header for page rendering and security for IE8
        setPageHeaders();
 
        string pageParam = ApexPages.currentPage().getParameters().get('section');
        if (pageParam != null && pageParam.toLowerCase() == 'password') 
        {
            section = 'password';
        } 
        else if (pageParam != null && pageParam.toLowerCase() == 'confirm') 
        {
            section = 'confirm';
        } 
        else 
        {
            section = 'profile';
        }

        // Get User id then detail
        u = [SELECT Id, FirstName, LastName, Email, MobilePhone, Phone, CompanyName, Legacy_Id__c, Contact.BillingAccount__r.Source_System__c,
                    Country, Street, City, State, Postalcode, ContactId, DPID__c, Username, Contact.Account.Name, Contact.BillingAccount__r.Legacy_Id__c 
                FROM User WHERE Id = : UserInfo.getUserId()];
 
        mailingAddress = new AddressExtension(u.Street, null, u.City, u.State, u.PostalCode, u.DPID__c, 
                                                u.Country); 
        businessName = u.Contact.Account.Name;
        businessNumber = u.Contact.BillingAccount__r.Legacy_Id__c ;
 
    }   

    private void setPageHeaders()
    {
        // the following code resolved IE8/9 mis-aligned rendering issue

        // Make sure IE9 will use edge (IE9) mode - without the insertion of the following header
        // <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
        // comes too late and gives this error
        // HTML1115: X-UA-Compatible META tag ('IE=edge,chrome=1') ignored because document mode is already finalized.
        // Caused by Vf outputing tags and content prior to this meta tag
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge,chrome=1');

        // Add headers as advised by security review 2013-02-15
        Apexpages.currentPage().getHeaders().put('X-Frame-Options', 'SameOrigin'); // To prevent clickjacking
        Apexpages.currentPage().getHeaders().put('Cache-control', 'no-store'); // To prevent the browser to store personal information into its cache
        Apexpages.currentPage().getHeaders().put('Pragma', 'no-cache');
    }

    public List<SelectOption> getStates()
    {
        // this function generates picklist values
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption('', 'Please select'));
        options.add(new selectOption('ACT', 'ACT'));
        options.add(new selectOption('NSW', 'NSW'));
        options.add(new selectOption('NT', 'NT'));
        options.add(new selectOption('QLD', 'QLD'));
        options.add(new selectOption('SA', 'SA'));                
        options.add(new selectOption('TAS', 'TAS'));
        options.add(new selectOption('VIC', 'VIC'));
        options.add(new selectOption('WA', 'WA'));                                
        return options;
    }    

    public List<SelectOption> getCountries()
    {
        // this function generates picklist values
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption('', 'Please select'));
        options.add(new selectOption('Australia', 'Australia'));
        return options;
    } 


    public PageReference save()
    {
        setPageHeaders();
        system.debug('xxx 1 mailingAddress.line1 = ' + mailingAddress.line1);    
        // pass data back to user record (from component variable)
        u.Street = mailingAddress.line1;
        u.City = mailingAddress.city;
        u.State = mailingAddress.state;
        u.PostalCode = mailingAddress.postcode;
        u.Country = mailingAddress.countryName;
        u.DPID__c = mailingAddress.dpid;
    
        // need to update the Contact record (re: Community User)
        Contact userContact;
        string contactId = u.ContactId;
        if(contactId!=null && contactId!='')
        {
            userContact = [SELECT Id FROM Contact 
                                WHERE Id = : contactId];
            userContact.FirstName = u.FirstName;
            userContact.LastName = u.LastName;
            userContact.MailingStreet = u.Street.split(',',2)[0];
            try {
                userContact.MailingStreet2__c = u.Street.split(',',2)[1];
            } catch(Exception e) {
            }
            userContact.MailingCity = u.City;
            userContact.MailingState = u.State;
            userContact.MailingPostalCode = u.Postalcode;
            userContact.MailingCountry = u.Country;
            userContact.Mailing_DPID__c = u.DPID__c;
            userContact.Phone = u.Phone;
            userContact.MobilePhone = u.MobilePhone;
        }

        try
        {
            if(userContact!=null)
            {
                update userContact;
            }
            system.debug('xxx 2 u.street = ' + u.street);                
            update u;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        return null;
    }    
        
    public PageReference changePassword() 
    {
        setPageHeaders();
        return Site.changePassword(newPassword, verifyNewPassword, oldpassword);    
    } 
}