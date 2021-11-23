/**
* @description       : A class to parse the JSON string coming from LWC component bcaForm
* @author            : Victor Cheng
* @group             :
* @last modified on  : 06-02-2021
* @last modified by  : ankur.gandhi@auspost.com.au
* Modifications Log
* Ver   Date         Author                               Modification
* -------------------------------------------------------------------------
* 1.0   25-03-2021  Victor Cheng   Initial Version
**/

public with sharing class CreditAssessmentWrapper {
    public String userOrgId{get;set;}
    public ABNDetails abnDetails {get;set;}
    public BusinessAddressDetails businessAddressDetails {get;set;}
    public BusinessTypeDetails businessTypeDetails {get;set;}
    public List<BusinessPerson> directors {get;set;}
    public BusinessContact businessContact {get;set;}
    public EmailCorrespondence emailForCorrespondence {get;set;}
    public CreditAmount creditAmount {get;set;}
    public DirectDebit directDebit {get;set;}
    public List<BusinessReference> businessRefs {get;set;}
   // public LodgingAppPersonDetails lodgingAppPersonDetails {get; set;}  //Jansi commented on 29-04-2021

    public List<TrustFile> trustFiles {get; set;}
    public List<PostalOutlet> postalOutlets {get;set;}
    
    public String appSummaryHTML {get;set;} //Jansi added

    // the created record
    private APT_Credit_Assessment__c caRecord;

    private Boolean isGovernment() { return caRecord.APT_Entity_Type__c == 'GOVT'; }
    private Boolean isPartner() { return caRecord.APT_Entity_Type__c == 'PARTNERSHIP'; }
    private Boolean isTrust() { return caRecord.APT_Entity_Type__c == 'TRUST'; }
    public APT_Credit_Assessment__c creditAssessment()
    {
        caRecord = new APT_Credit_Assessment__c();
        caRecord.APT_Organisation_Name__c = userOrgId;

        // populate each section
        abnDetails.populateRecord(caRecord);
        businessAddressDetails.populateRecord(caRecord);
        businesstypeDetails.populateRecord(caRecord);
        populateDirectors();
        businessContact.populateRecord(caRecord);
        emailForCorrespondence.populateRecord(caRecord);
        creditAmount.populateRecord(caRecord);
        if(directDebit != null){
            directDebit.populateRecord(caRecord);
        }   
        populateReferences();
        //lodgingAppPersonDetails.populateRecord(caRecord);

        // storing in GMT
        caRecord.Application_Submitted_Date_Time__c = Datetime.now();
        // assume true?
        caRecord.Application_TC_Acceptance__c = true;
        caRecord.L2C_Assessment_Type__c = BCAFormConstants.ASSESSMENT_INITIATION_TYPE_ONLINE;

        //update legal entity name of CA Record for Entity type Trust after populating all data because of other dependencies
        if(caRecord.APT_Entity_Type__c.equalsIgnoreCase(BCAFormConstants.ENTITY_TYPE_TRUST)){
            // TRUSTEE name update
            String trustName = caRecord.APT_Applicant_1_First_Name__c;
            trustName += ' ' + (caRecord.APT_Applicant_1_Middle_Name__c != null ? caRecord.APT_Applicant_1_Middle_Name__c + ' ' : '') + caRecord.APT_Applicant_1_Last_Name__c;
            trustName += ' ATF ' + caRecord.APT_Legal_Entity_Name__c;

            caRecord.APT_Legal_Entity_Name__c = trustName.left(255);
        }
        caRecord.Application_Summary_Content__c = appSummaryHTML;   //Jansi added
        return caRecord;
    }

    // because directors is an array of objects
    private void populateDirectors()
    {
        if(!isGovernment()){
            // no need for government types    
            BusinessPerson person1 = directors[0];

            // always store the first applicant
            caRecord.APT_Applicant_1_First_Name__c = person1.firstName;
            caRecord.APT_Applicant_1_Middle_Name__c = person1.middleName;
            caRecord.APT_Applicant_1_Last_Name__c = person1.lastName;
            caRecord.APT_Applicant_1_Previous_Name__c = person1.previousName;
            caRecord.APT_Applicant_1_Date_of_Birth__c = person1.parsedDob();

            // address
            caRecord.APT_Applicant_1_Street_Name__c = person1.currentResidentialAddress.addressLine1;
            caRecord.APT_Applicant_1_Address_Line_2__c = person1.currentResidentialAddress.addressLine2;
            caRecord.APT_Applicant_1_City__c = person1.currentResidentialAddress.city;
            caRecord.APT_Applicant_1_Suburb__c = person1.currentResidentialAddress.city.length() > 25 ? person1.currentResidentialAddress.city.subString(0,24): person1.currentResidentialAddress.city;  // Added by Jansi - 14-04-2021
            caRecord.APT_Applicant_1_State__c = person1.currentResidentialAddress.state;
            caRecord.APT_Applicant_1_Postcode__c = person1.currentResidentialAddress.postcode;
            caRecord.APT_Applicant_1_Country__c = person1.currentResidentialAddress.countryCode != null ? person1.currentResidentialAddress.countryCode : 'AU';

            if(person1.lessThan12MonthsAtAddress())
            {
                // store previous address
                caRecord.APT_Applicant_1_Previous_Address_Line_1__c = person1.previousResidentialAddress.addressLine1;
                caRecord.APT_Applicant_1_Previous_Address_Line_2__c = person1.previousResidentialAddress.addressLine2;
                caRecord.APT_Applicant_1_Previous_Address_City__c = person1.previousResidentialAddress.city;
                caRecord.APT_Applicant_1_Previous_Address_State__c = person1.previousResidentialAddress.state;
                caRecord.APT_Applicant_1_Previous_Postcode__c = person1.previousResidentialAddress.postcode;
                caRecord.APT_Applicant_1_Previous_Address_Country__c = person1.previousResidentialAddress.countryCode != null ? person1.previousResidentialAddress.countryCode : 'AU';
            }

            caRecord.APT_Applicant_1_Telephone__c = person1.phone;
            caRecord.APT_Applicant_1_Email_Address__c = person1.email;

            // driver's license
            caRecord.APT_Applicant_1_Drivers_Licence_Number__c = person1.driversLicense;

            // only store the 2nd one for partners
            if(isPartner())
            {
                BusinessPerson person2 = directors[1];

                // always store the first applicant
                caRecord.APT_Applicant_2_First_Name__c = person2.firstName;
                caRecord.APT_Applicant_2_Middle_Name__c = person2.middleName;
                caRecord.APT_Applicant_2_Last_Name__c = person2.lastName;
                caRecord.APT_Applicant_2_Previous_Name__c = person2.previousName;
                caRecord.APT_Applicant_2_Date_of_Birth__c = person2.parsedDob();

                // address
                caRecord.APT_Applicant_2_Street_Name__c = person2.currentResidentialAddress.addressLine1;
                caRecord.APT_Applicant_2_Address_Line_2__c = person2.currentResidentialAddress.addressLine2;
                caRecord.APT_Applicant_2_City__c = person2.currentResidentialAddress.city;
                caRecord.APT_Applicant_2_Suburb__c= person2.currentResidentialAddress.city.length() > 25 ? person2.currentResidentialAddress.city.subString(0, 24): person2.currentResidentialAddress.city;  // Added by Jansi - 14-04-2021
                caRecord.APT_Applicant_2_State__c = person2.currentResidentialAddress.state;
                caRecord.APT_Applicant_2_Postcode__c = person2.currentResidentialAddress.postcode;
                caRecord.APT_Applicant_2_Country__c = person2.currentResidentialAddress.countryCode != null ? person2.currentResidentialAddress.countryCode : 'AU';

                if(person2.lessThan12MonthsAtAddress())
                {
                    // store previous address
                    caRecord.APT_Applicant_2_Previous_Address_Line_1__c = person2.previousResidentialAddress.addressLine1;
                    caRecord.APT_Applicant_2_Previous_Address_Line_2__c = person2.previousResidentialAddress.addressLine2;
                    caRecord.APT_Applicant_2_Previous_Address_City__c = person2.previousResidentialAddress.city;
                    caRecord.APT_Applicant_2_Previous_Address_State__c = person2.previousResidentialAddress.state;
                    caRecord.APT_Applicant_2_Previous_Postcode__c = person2.previousResidentialAddress.postcode;
                    caRecord.APT_Applicant_2_Previous_Address_Country__c = person2.previousResidentialAddress.countryCode != null ? person2.previousResidentialAddress.countryCode : 'AU';
                }

                caRecord.APT_Applicant_2_Telephone__c = person2.phone;
                caRecord.APT_Applicant_2_Email_Address__c = person2.email;

                caRecord.APT_Applicant_2_Drivers_Licence_Number__c = person1.driversLicense;
            }
        }
    }

    private void populateReferences()
    {
        if(isGovernment())
        {
            // EARLY OUT, no references for government entities
            return;
        }
        BusinessReference ref1 = businessRefs[0];
        caRecord.APT_Reference_Business_Name_1__c = ref1.businessName;
        caRecord.APT_Reference_Contact_Name_1__c = ref1.fullName;
        caRecord.APT_Reference_Job_Title_1__c = ref1.positionTitle;
        caRecord.APT_Reference_Phone_Number_1__c = ref1.phone;

        BusinessReference ref2 = businessRefs[1];
        caRecord.APT_Reference_Business_Name_2__c = ref2.businessName;
        caRecord.APT_Reference_Contact_Name_2__c = ref2.fullName;
        caRecord.APT_Reference_Job_Title_2__c = ref2.positionTitle;
        caRecord.APT_Reference_Phone_Number_2__c = ref2.phone;

        BusinessReference ref3 = businessRefs[2];
        caRecord.APT_Reference_Business_Name_3__c = ref3.businessName;
        caRecord.APT_Reference_Contact_Name_3__c = ref3.fullName;
        caRecord.APT_Reference_Job_Title_3__c = ref3.positionTitle;
        caRecord.APT_Reference_Phone_Number_3__c = ref3.phone;
    }

    public List<ContentDocumentLink> linkDocuments(APT_Credit_Assessment__c newRecord)
    {
        // the record should be the same, but for clarity, we should pass it back in with another name
        List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink> ();

        if(trustFiles != null) {
            for (TrustFile fileObj : trustFiles) {
                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId = fileObj.contentDocumentId;
                link.LinkedEntityId = newRecord.Id;

                cdLinks.add(link);
            }
        }

        System.debug('CreditAssessmentWrapper:: linkDocuments:');
        System.debug(cdLinks);
        return cdLinks;
    }

    public List<Credit_Assessment_Network__c> createPostalOutlets(APT_Credit_Assessment__c newRecord)
    {
        List<Credit_Assessment_Network__c> networks = new List<Credit_Assessment_Network__c>();

        if(postalOutlets != null)
        {
            for(PostalOutlet outlet: postalOutlets)
            {
                Credit_Assessment_Network__c caNetwork = new Credit_Assessment_Network__c();
                caNetwork.Credit_Assessment__c = newRecord.Id;
                caNetwork.Network__c = outlet.id;
                networks.add(caNetwork);
            }
        }
        return networks;
    }


    private static Date parseStringToDate(String s)
    {
        return Date.valueOf(s + ' 00:00:00');
    }



    // supporting internal classes for parsing the save record
    public class ABNDetails {
        public String ABN {get;set;}
        public String LegalEntityName {get;set;}
        public String TradingNameStr {get;set;}

        // from selection
        public String tradingName {get;set;}
        public String otherTradingName {get;set;}

        public String EntityTypeGroup {get;set;}
        public String EntityTypeMasterLabel {get;set;}
        public String ABNStatusFromDate {get;set;}
        public String OrganisationNumber {get;set;}
        public String ACN {get;set;}
        public ACNDetails acnDetails {get;set;}
        public void populateRecord(APT_Credit_Assessment__c caRecord){
            caRecord.APT_ABN__c = ABN;
            caRecord.APT_ACN__c = acnDetails != null ? acnDetails.ACN : ACN;
            caRecord.APT_Legal_Entity_Name__c = LegalEntityName;
            caRecord.APT_Entity_Type__c = EntityTypeMasterLabel;
            caRecord.APT_Date_Commenced__c = parseStringToDate(ABNStatusFromDate);
            caRecord.APT_Business_Name__c = tradingName != '_manualEntry' ? tradingName : otherTradingName;
        }
    }

    private class ACNDetails {
        public String ACN {get;set;}
    }

    @TestVisible
    private class BusinessAddressDetails {
        public StreetAddressAME streetAddress {get;set;}
        public StreetAddressAME postalAddress {get;set;}
        public String isBusNStreetAddressSame {get;set;}
        public void populateRecord(APT_Credit_Assessment__c caRecord)
        {
            caRecord.APT_Street_Name__c = streetAddress.addressLine1;
            // TODO TBC address line 2
            caRecord.APT_Address_Line_2__c = streetAddress.addressLine2;
            caRecord.APT_City__c = streetAddress.city;
            caRecord.APT_Suburb__c = streetAddress.city.length() > 25 ? streetAddress.city.subString(0,24) : streetAddress.city;  //// Added by Jansi - 14-04-2021
            caRecord.APT_State__c = streetAddress.state;
            caRecord.APT_Postcode__c = streetAddress.postcode;
            caRecord.APT_Country__c = streetAddress.countryCode !=null ? streetAddress.countryCode : 'AU';

            if('no' == isBusNStreetAddressSame)
            {
                caRecord.APT_Postal_Address_Line_1__c = postalAddress.addressLine1;
                caRecord.APT_Postal_Address_Line_2__c = postalAddress.addressLine2;
                caRecord.APT_Postal_City__c = postalAddress.city;
                caRecord.APT_Postal_State__c = postalAddress.state;
                caRecord.APT_Postal_Postcode__c = postalAddress.postcode;
                caRecord.APT_Postal_Country__c = postalAddress.countryCode != null ? postalAddress.countryCode : 'AU';
            }
            else
            {
                caRecord.APT_Postal_Address_Line_1__c = caRecord.APT_Street_Name__c;
                caRecord.APT_Postal_Address_Line_2__c = caRecord.APT_Address_Line_2__c;
                caRecord.APT_Postal_City__c = caRecord.APT_City__c;
                caRecord.APT_Postal_State__c = caRecord.APT_State__c;
                caRecord.APT_Postal_Postcode__c = caRecord.APT_Postcode__c;
                caRecord.APT_Postal_Country__c = caRecord.APT_Country__c;
            }
        }
    }

    @TestVisible
    private class StreetAddressAME {
        public String line1 {get;set;}
        public String line2 {get;set;}

        public String addressLine1 {
            get{
                return String.isBlank(addressLine1)? line1 : addressLine1;
            }
            set;}
        public String addressLine2 {
            get{
                return String.isBlank(addressLine2)? line2 : addressLine2;
            }
            set;}
        public String city {get;set;}
        public String state {get;set;}
        public String postcode {get;set;}
        public String countryCode {get;set;}
    }

    @TestVisible
    private class BusinessTypeDetails {
        public String industryDivision {get;set;}
        public String industryClass {get;set;}
        public String noOfDirectors {get;set;}
        public void populateRecord(APT_Credit_Assessment__c caRecord)
        {
            caRecord.APT_Industry_Type__c = industryDivision.substring(0, 1);
            caRecord.Industry_Class__c = industryClass;
            if(!String.isEmpty(noOfDirectors))             // Jansi added
                caRecord.APT_Number_of_Employees__c = Integer.valueOf(noOfDirectors);
        }
    }

    // AKA Director/Partner
    @TestVisible
    private class BusinessPerson {
        public String firstName {get;set;}
        public String middleName {get;set;}
        public String lastName {get;set;}
        public String previousName {get;set;}
        public String dob {get;set;}
        public String phone {get;set;}
        public String email {get;set;}
        public String timeAtAddress {get;set;}

        public String driversLicense {get;set;}

        public StreetAddressAME currentResidentialAddress {get;set;}
        public StreetAddressAME previousResidentialAddress {get;set;}

        public Date parsedDob()
        {
            return parseStringToDate(dob);
        }

        public Boolean lessThan12MonthsAtAddress() {
            return timeAtAddress.contains('Less');
        }
    }

    @TestVisible
    private class BusinessContact {
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String positionTitle {get;set;}
        public String phone {get;set;}
        public String email {get;set;}

        public void populateRecord(APT_Credit_Assessment__c caRecord)
        {
            caRecord.APT_Contact_Name__c = firstName + ' ' + lastName;
            caRecord.Contact_First_Name__c = firstName;
            caRecord.Contact_Last_Name__c = lastName;
            //TODO what position if it's one of the Directors/Partners?
            caRecord.APT_Position_Title__c = positionTitle;
            caRecord.APT_Telephone__c = phone;
            caRecord.APT_Email_Address__c = email;
        }
    }

    @TestVisible
    private class EmailCorrespondence {
        public String email {get; set;}
        public void populateRecord(APT_Credit_Assessment__c caRecord)
        {
            caRecord.APT_Correspondence_Email_Address__c = email;
        }
    }

    @TestVisible
    public class CreditAmount {
        public Integer monthlyAmount {get; set;}
        public Decimal recommendedAmount {get; set;}
        public void populateRecord(APT_Credit_Assessment__c caRecord)
        {
            caRecord.APT_Requested_Credit_Limit__c = recommendedAmount;
        }
    }

    @TestVisible
    private class DirectDebit {
        public String accountName {get; set;}
        public String bankName {get; set;}
        public String bsb {get; set;}
        public String accountNumber {get; set;}
        public void populateRecord(APT_Credit_Assessment__c caRecord)
        {
            caRecord.Direct_Debit_Account_Name__c = accountName;
            caRecord.Direct_Debit_Bank_Name__c = bankName;
            caRecord.Direct_Debit_BSB_Number__c = bsb;
            caRecord.Direct_Debit_Account_Number__c = accountNumber;

            // if we're here, assume true
            caRecord.Direct_Debit_TC_Acceptance__c = true;
        }
    }

    @TestVisible
    private class BusinessReference {
        public String businessName {get; set;}
        public String fullName {get; set;}
        public String positionTitle {get; set;}
        public String phone {get; set;}
    }

   /* private class LodgingAppPersonDetails {
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String positionTitle {get;set;}
        public String phone {get;set;}

        public void populateRecord(APT_Credit_Assessment__c caRecord)
        {
            caRecord.Lodging_Person_Name__c = firstName + ' ' + lastName;
            caRecord.Lodging_Person_Position_Title__c = positionTitle;
            caRecord.Lodging_Person_Phone_Number__c = phone;
        }
    }*/

    @TestVisible
    private class PostalOutlet {
        public String id {get; set;}
    }

    private class TrustFile {
        public String contentDocumentId {get; set;}
    }

}