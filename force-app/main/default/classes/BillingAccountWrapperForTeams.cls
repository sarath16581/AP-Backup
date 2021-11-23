/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Helper for createSTBillingAccount component and used for creating the billing account request
 * @changelog
 * 2021-03-10 - shashwat.nath@auspost.com.au - Created
 * 2021-03-15 - dheeraj.mandavilli@auspost.com.au - Updated the structure based upon Teams API Spec.
 */
public with sharing class BillingAccountWrapperForTeams {
     // Billing Account Request JSON Creation
    @AuraEnabled
    public String orgRecordId;
    @AuraEnabled
    public String processType;
    @AuraEnabled
    public String requestObjId;
    @AuraEnabled
    public String targetSystem;
    @AuraEnabled
    public Team team;
    @AuraEnabled
    public String transactionId; 

    //Team Details
    public class Team {
        @AuraEnabled
        public CreditDetails creditDetails;
        @AuraEnabled
        public Organisations organisations;
        @AuraEnabled
        public List<String> service;
    }
    //Status Details
    public class CreditDetails{
        @AuraEnabled
        public String authoriser;
        @AuraEnabled
        public Integer creditLimit;
        @AuraEnabled
        public Integer estimatedMonthlyRevenue;
        @AuraEnabled
        public Date nextRevenueDueDate;
        @AuraEnabled
        public String creditOfficer;
        @AuraEnabled
        public String creditAssessNo;
    }

    //Org Details
    public class Organisations{
        @AuraEnabled
        public String abn;
        @AuraEnabled
        public String phone;
        @AuraEnabled
        public String accountName1;
        @AuraEnabled
        public String accountName2;
        @AuraEnabled
        public String acn;
        @AuraEnabled
        public Address billingAddress;
        @AuraEnabled
        public Address mailingAddress;
        @AuraEnabled
        public Contact primaryContact;
        @AuraEnabled
        public Contact secondaryContact;
    }

    //Billing Address Details
    public class Address {
        @AuraEnabled
        public String addressLine1;
        @AuraEnabled
        public String addressLine2;
        @AuraEnabled
        public String suburb;
        @AuraEnabled
        public Integer postcode;
    }

    //Primary Contact Details
    public class Contact {
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String jobTitle;
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String phone;
        @AuraEnabled
        public String salutation;
    }
    
    public BillingAccountWrapperForTeams(){
        team = new Team();
        team.organisations = new Organisations();
        team.creditDetails = new CreditDetails();
        team.organisations.billingAddress = new Address();
        team.organisations.mailingAddress = new Address();
        team.organisations.primaryContact = new Contact();
        team.organisations.secondaryContact = new Contact();
    }
}