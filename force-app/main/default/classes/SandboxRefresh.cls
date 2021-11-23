/**
  * @author       : paul.stamer@auspost.com.au
  * @date         : 21/04/2016
  * @description  : Class for Sandbox refresh
  */
/*******************************  History ************************************************
Date                    User                                    Comments
04.11.2016              paul.stamer@auspost.com.au              Added the 'test org' creation and update        
15.11.2016              paul.stamer@auspost.com.au              Added creation for a network record and a campaign                  
*******************************  History ************************************************/

global class SandboxRefresh implements SandboxPostCopy {

    // Constants   
    private static final String RUNAPEXCLASS = 'runApexClass';
    
    /**
      * @description     This is to run the methods 'createOrgAndUpdate' 'createHoldingRole' 'createNetwork' 'createCampaign' and to catch the errors.   
      * @param           none   
      * @return          none  
      * @throws          errors when this is an error in creation  
      */
    
    global void runApexClass(SandboxContext context) {
        
        try{
            system.debug ('** orgid ==>'+ context.organizationId()); // the debug statement has been added for test coverage only
       
            createOrgAndUpdate();     
            createHoldingRole();
            createNetwork();
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    SandboxRefresh.class.getName(), RUNAPEXCLASS, 
                                                    null, LoggingLevel.ERROR);
        }      
        
    }

    /**
      * @description    To create and update a dummy record in the account object       
      * @param          none    
      * @return         none   
      * @throws         none   
      */        
    private static void createOrgAndUpdate(){
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        //create an organsation for test data, code for the billing account has been hard coded to look for a leagcy number 60000000
        Account acc=new Account();
        acc.name='Test org';
        acc.RecordTypeId = accRecTypeMap.get('Organisation').getRecordTypeId();
        database.insert (acc);
        
        //update the test account legacy id        
        acc.LEGACY_ID__c = label.OrganisationLegacyId;
        database.update (acc);
        
    }
    
    /**
      * @description    To create a dummy record in the holding role object       
      * @param          none    
      * @return         none   
      * @throws         none   
      */
    private static void createHoldingRole(){
        
        //creating a Prospect holding role for use with organisations
        Holding_Role_Reference__c holdingRoleRef = new Holding_Role_Reference__c(Name='Prospect');
        database.insert (holdingRoleRef);
                
    }
        /**
      * @description    To create a dummy record in the network object    
      * @param          none    
      * @return         none   
      * @throws         none   
      */
    private static void createNetwork(){
        Map<String,Schema.RecordTypeInfo> networkRecTypeMap = Schema.Sobjecttype.network__c.getRecordTypeInfosByName();
        //creating a test network
        network__c createTestNetwork = new network__c();
        createTestNetwork.name = 'Test LPO';
        createTestNetwork.Org_Unit_Type__c = 'LPO';
        createTestNetwork.RecordTypeId = networkRecTypeMap.get('Retail').getRecordTypeId();
        database.insert (createTestNetwork);
                
    }
   
    
}