/**************************************************
Type:       Utility class to define constants
Purpose:    Defines constants for the string literals and other constant values used throughout the code 
       
History:
--------------------------------------------------
23.01.2014  Mohamed.Atheek@bluewolf.com  Created
04.01.2019  disha.kariya@auspost.com.au  Added Contact & Asset Record Type
07.01.2019  ramtej.juloori@auspost.com.au   Added constants for case record types
2019-03-20  gnana.muruganantham@auspost.com.au  Added constants for ACIC Request Case Record Type and Approved & Rejected Case Status 
2019-03-25  gnana.muruganantham@auspost.com.au  Added constants for ACIC App, Add Case Team Member Method, Update Proposal Method and Case Trigger 
2019-06-12  shashwat.nath@accenture.com Added constant STRING_ALL
**************************************************/

public class Constants {

    //RecordType Names
    public static final String RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT = 'Organisation';
    public static final String RECORDTYPE_NAME_ACCOUNT_PERSONACCOUNT = 'PersonAccount';
    public static final String RECORDTYPE_NAME_ACCOUNT_UNVERIFIED = 'Unverified';

    public static final String RECORDTYPE_NAME_CONTACT_UNVERIFIED = 'Unverified';
    public static final String RECORDTYPE_NAME_CONTACT_CONTACT = 'Contact';

    public static final String RECORDTYPE_NAME_ASSET_GENERAL = 'General';
    public static final String RECORDTYPE_NAME_ASSET_TANDC = 'TandC';

    public static final String RECORDTYPE_NAME_CASE_SSSW_GENERAL = 'SSSW_General';

    public static final String RECORDTYPE_NAME_QUICKREFERENCE_QUICKLINKS = 'QuickLinks';

    public static final String RECORDTYPE_NAME_TASK_SSSWCALL = 'SSSWCall';
    public static final String RECORDTYPE_NAME_TASK_SSSWSMS = 'SSSWSMS';

    public static final String RECORDTYPE_NAME_ARTICLE_ARTICLE = 'Article';
    public static final String RECORDTYPE_NAME_ARTICLE_CONSIGNMENT = 'Consignment';
    
    public static final String RECORDTYPE_NAME_DELIVERY_ENQUIRY = 'Delivery Enquiry';
    public static final String RECORDTYPE_NAME_CUSTOMER_DATA_REQUEST = 'Data Quality Management';
    public static final String RECORDTYPE_NAME_REPORT_REQUEST = 'Report Request';
    public static final String RECORDTYPE_NAME_CREDIT_DISPUTE_CLAIM = 'Credit Dispute Claim';
    public static final String RECORDTYPE_NAME_CUSTOMER_ONBOARDING = 'Customer Onboarding';
    
    public static final String RECORD_TYPE_CONTRACT_MANAGEMENT_ENQUIRY = 'Deal Enablement Centre';
    public static final String CONTR_MGMT_ENQ_QUEUE = 'Contract Management Enquiry';
    
    public static final String RECORDTYPE_NAME_ACIC_REQUEST = 'ACIC_Request';
    public static final String CASE_STATUS_APPROVED = 'Approved';
    public static final String CASE_STATUS_REJECTED = 'Rejected';
    public static final String ACIC_APP = 'ACIC';
    public static final String METH_ADD_CASETEAM_MEMBER = 'addCaseTeamMemberForACICCase';
    public static final String METH_UPDATE_PROPOSAL = 'updateProposalBasedOnACICStatus';
    public static final String CASE_TRIGGER = 'CaseTrigger';
    public static final String STRING_ALL = 'All';
    public static final String IN_EFFECT= 'In Effect';
    public static final String ACTIVATED= 'Activated';

    public static final String CLOSED_WON = 'Closed Won';
    public static final String CLSS_NEWBUSINESS = 'New Business';
    public static final String CLSS_CROSSSELL = 'Cross Sell';
    public static final String CLSS_WINBACK = 'Win Back';
    public static final String CLSS_RENEWAL = 'Renewal';
    public static final String CLSS_GROWTH = 'Growth';
    public static final String YES_STRING = 'Yes';
    public static final String NO_STRING = 'No';
    public static final String REVENUE_TYPE_DECREASE_REVENUE = 'Decrease Revenue';
    public static final String RECORDTYPE_NAME_AMENDMENT_QUOTE = 'Amendment Quote';
    
    public static Set<String> optyComparisonFields(){
        
        Set<String> comparisonField = new Set<String>();
        comparisonField.add('StageName');
        
        return comparisonField;
    }
    
    public static Set<String> optyLIComparisonFields(){
        
        Set<String> comparisonField = new Set<String>();
        comparisonField.add('Contract_Start_Date__c');
        comparisonField.add('Contract_End_Date__c');
        comparisonField.add('Change_Classification__c');
        return comparisonField;
    }
    
    public static Set<String> aptOptyLIComparisonFields(){
        
        Set<String> comparisonField = new Set<String>();
        comparisonField.add('APT_Revenue_Start_Date__c');
        comparisonField.add('APT_Revenue_End_Date__c');
        comparisonField.add('APT_Change_Classification__c');
        comparisonField.add('APT_Quantity__c');
        comparisonField.add('APT_Unit_Sales_Price__c');
        comparisonField.add('APT_Contract_Product__c');
        
        return comparisonField;
    }
    
    public static Set<String> growthCLSS(){//set that contains the classifications allowed for Growth? field
        Set<String> clssSet = new Set<String>();
        clssSet.add('Renewal');
        clssSet.add('Growth');
        
        return clssSet;
    }
    
    public static Set<String> salesAdminProfiles(){
        Set<String> profiles = new Set<String>();
        profiles.add('Sales Admin'); 
        profiles.add('System Administrator'); 
        profiles.add('Business Enablement');
        profiles.add('SSSW - Service Agent');
        profiles.add('Sales Contracts CME');
        profiles.add('Enterprise Onboarding');
        
        return profiles;
    }
    
    public static Set<String> salesUserProfiles(){
        Set<String> profiles = new Set<String>();
        profiles.add('Coverage Sales'); 
        profiles.add('BG Base');         
        profiles.add('Hub Users'); 
        profiles.add('Product Sales');
        profiles.add('Sales 3rd Party');
        profiles.add('SecurePay Super User');
        profiles.add('Solution Sales');
        
        return profiles;
    }
    
    public static Set<String> cwgComparisonFields() {
        Set<String> oppFields = new Set<String>();
        oppFields.add('StageName');
        
        return oppFields;
    }
}