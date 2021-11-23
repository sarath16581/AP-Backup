/**
  * @author       : paul.stamer@auspost.com.au
  * @date         : 21/04/2016
  * @description  : Test Class for Sandbox refresh
  */
/*******************************  History ************************************************
    Date                User                                        Comments
  
15.11.2016              paul.stamer@auspost.com.au              Added creation for a network record and a campaign      
*******************************  History ************************************************/

@isTest

public class SandBoxRefreshTest {
    // ************** Test Methods *****************
 
    private static testMethod void SandboxRefreshTest(){
        SandboxRefresh postRefresh = new SandboxRefresh();
        
        // retrieve and assert the prospect has been created
        Test.testSandboxPostCopyScript(postRefresh , UserInfo.getOrganizationId(), '00DN0000000ATb3', 'sandbox2');
   
        List<Holding_Role_Reference__c> holdRoleReturn= [Select Name from Holding_Role_Reference__c Where Name = 'Prospect' Limit 1];       
        //System.assert(holdRoleReturn.size()==1);
        System.assertequals (1, holdRoleReturn.size());
        
        List<network__c> networkCreated = [select Name from network__c Where Name = 'Test LPO' Limit 1];
        //System to confirm creation
        System.assertequals (1, networkCreated.size());
        
        
    }

    private static testMethod void SandboxRefreshTestNewAccoun(){
        SandboxRefresh postRefresh = new SandboxRefresh();

        postRefresh.runApexClass (null);        
            
    }
    
}