/**
 * @description       : Copied code from 'bspProfile' class and modified to lightning uplift need basis
 * @author            : avula.jansirani@auspost.com.au
 * @group             : 
 * @last modified on  : 08-05-2020
 * @last modified by  : avula.jansirani@auspost.com.au
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   08-05-2020  avula.jansirani@auspost.com.au   Initial Version
**/
/**************************************************
Type:          bspProfileUplift
History:
--------------------------------------------------
10-08-2020    avula.jansirani@auspost.com.au   Added uplift changes       
**************************************************/
public with sharing class bspProfileUplift extends bspBaseUplift {

    /**
     * The method to change the passwod
     * */
    @AuraEnabled
    public static String changePassword(String newPassword,String verifyNewPassword, String oldpassword )  {
        PageReference p =Site.changePassword(newPassword, verifyNewPassword, oldpassword); 
        if (Test.isRunningTest()) {
            return 'Success';
        }
        return p.getUrl();
    } 
    
     /**
     * The method to update the bsp user pofile
     * */
    @AuraEnabled
    public static void save(String mailingAddressInput, String businessName, String businessNumber, String userStr) {
        
        AddressExtension mailingAddress = (AddressExtension) JSON.deserialize(mailingAddressInput, AddressExtension.class);
        
        User u = (User)JSON.deserialize(userStr, User.class);
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
            userContact.MailingStreet = mailingAddress.line1.split(',',2)[0];//mailingAddress.line1;
            userContact.MailingStreet2__c =mailingAddress.line2;
            //userContact.MailingStreet = u.Street.split(',',2)[0];
           // try {
               // userContact.MailingStreet2__c = u.Street.split(',',2)[1];
            //} catch(Exception e) {
            //}
            userContact.MailingCity = u.City;
            userContact.MailingState = u.State;
            userContact.MailingPostalCode = u.Postalcode;
            userContact.MailingCountry = u.Country;
            userContact.Mailing_DPID__c = u.DPID__c;
            userContact.Phone = u.Phone;
            userContact.MobilePhone = u.MobilePhone;
        }
        
        try{
            if(userContact!=null){
                update userContact;
            }
            update u;
        }
        catch(Exception ex){
            throw new ErrorException(ex.getMessage());
        }
        
    }
    
     /**
     * The method to get the bsp user pofile data from logged in use user and its contact object
     * */
    @AuraEnabled(cacheable=true) 
    public static UserProfileDetails getUserProfileDetails() 
    {
        UserProfileDetails ud = new UserProfileDetails();
        // Get User id then detail
        ud.user = [SELECT Id, FirstName, LastName, Email, MobilePhone, Phone, CompanyName, Legacy_Id__c, Contact.BillingAccount__r.Source_System__c,
                   Country, Street, City, State, Postalcode, ContactId, DPID__c, Username, Contact.Account.Name, Contact.BillingAccount__r.Legacy_Id__c, Contact.MailingStreet2__c 
                   FROM User WHERE Id = : UserInfo.getUserId()];
        
        ud.mailingAddress = new AddressExtension( ud.user.Street, ud.user.Contact.MailingStreet2__c,  ud.user.City,  ud.user.State, ud.user.PostalCode,  ud.user.DPID__c, 
                                                 ud.user.Country);
        ud.businessName=ud.user.Contact.Account.Name;
        ud.businessNumber = ud.user.Contact.BillingAccount__r.Legacy_Id__c ;

        return ud;
    } 
    
     /**
     * Inner class to store user profile details
     * */
    public class UserProfileDetails{
        @AuraEnabled
        public AddressExtension mailingAddress {get;set;}
        @AuraEnabled
        public User user{get;set;}
        @AuraEnabled
        public String businessName {get;set;}
        @AuraEnabled
        public String businessNumber {get;set;} 
    }
    
    /** 
    * Custom Exception
    * */
    class ErrorException extends Exception{}
}