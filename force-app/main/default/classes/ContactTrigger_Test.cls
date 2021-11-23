/**
    * This Class is as as test class for Contact Trigger sending email to new COntacts via ET.  
    * 
    * @Author kalpita.talwadekar@auspost.com.au
    * @Date 2/10/2015
    *   
    */
@isTest
private class ContactTrigger_Test {
    
    //variables
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    
    @testSetup static void setup() {
        // Setup custom setting data
        database.insert(new SystemSettings__c(Disable_Triggers__c=false,DisableContactTrigger_ETEmail__c=false));
       
        // inserting et configuration record
        database.insert( new et4ae5__Configuration__c(et4ae5__Support_Ticket_Recipient__c = 'example@example.com') );   
    }
    

    /** 
    * @name: ContactTriggerTest()
    * @desciption: test method for testing Contact Trigger sending email to new COntacts via ET. 
    * @param: NA
    * @return: NA
    *
    */
    private static testmethod void ContactTriggerTest() {  
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            con.LeadSource = SSSWConstants.SBS_Online;
            Test.startTest();
            Database.insert(con);
            Test.stopTest();
            // If no exceptions occurred, it was successful 
           System.assert(!String.isBlank(con.Id));
        }        
    }

}