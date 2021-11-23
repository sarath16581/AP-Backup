/*****************************************************************************************************************
    
    Author:         Lyndon Lavapie(Cloud Sherpas)  
    Date Created:   11/04/2015
    Description:    This test class is for FlowRecallResubmitApprovalProcess.
    
    Change Log:
    Date:          Author:                  Description:
    11/04/2016     Lyndon Lavapie           Created
    01/06/2016     Andrew Judd (Salesforce.com)  Added setting of Network.Org_Unit_Type__c and Facility.Licence_Type__c to LPO for filter

******************************************************************************************************************/
@isTest
public class FlowRecallResubmitApprovalProcess_Test {
    static testmethod void flowTests() {
        
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole r = [select id from UserRole where developername='PartnerInfo_National_RNP_Manager' limit 1];
        User ux = new User(Alias = 'testx', Email='testx@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true, UserRoleId=r.Id,
                        TimeZoneSidKey='America/Los_Angeles', UserName='testx@auspost.com.au');                                                
        insert ux;
        
        User l1Approver = new User(Alias = 'testx', Email='approver1@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true, UserRoleId=r.Id,
                        TimeZoneSidKey='America/Los_Angeles', UserName='approver1@auspost.com.au');                                                
        insert l1Approver;
        
        User l2Approver = new User(Alias = 'testx', Email='approver2@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true, UserRoleId=r.Id,
                        TimeZoneSidKey='America/Los_Angeles', UserName='approver2@auspost.com.au');                                                
        insert l2Approver;
        
        system.runAs(ux){
            //create organization record
            Account parentAccount = new Account(
                                                    name = 'Test0',
                                                    phone = '123',
                                                    RecordTypeId = organizationRecType.id
                                                );
    
            insert parentAccount;
            //create contact
            Contact cObj = new Contact (FirstName='Test', LastName='Contact', email='test@test.com', accountId=parentAccount.Id);
            insert cObj;
            //create account contact role
            AccountContactRole cAObj = new AccountContactRole (AccountId =parentAccount.id, ContactId=cObj.Id, isPrimary=true);
            insert cAObj;  
            //create networks
            Network__c parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId());
            insert parentNetwork;
    
            Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO');
            insert network;
    
            //create facility
            Account facilityAcc1 = new Account(
                                                name='test1', 
                                                phone='123', 
                                                recordtypeid=facitlityRecType.id,
                                                Licence_Type__c = 'LPO',
                                                Network_Facility__c = network.id );
            insert facilityAcc1;
            
            //create licence
            Account licenceAcc1 = new Account(
                                            name='test2', 
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Licence_Status__c= 'Draft',
                                            ParentId = parentAccount.id );
            insert licenceAcc1;
            
            //create Agreement Document
            Agreement_Document__c pad = new Agreement_Document__c(
                                            Active_Date__c = system.today(),
                                            Approval_Type__c = 'Full',
                                            Licence__c = licenceAcc1.Id,
                                            Status__c = 'New',
                                            Allow_Submit_For_Approval__c = true,
                                            Level_1_Approver__c = l1Approver.Id,
                                            Level_2_Approver__c = l2Approver.Id
                                            );
            Insert pad;
            //submit approval
            Approval.ProcessSubmitRequest req1 =new Approval.ProcessSubmitRequest();
            req1.setObjectId(pad.Id);
            req1.setSubmitterId(UserInfo.getUserId());
            Approval.process(req1);
            
            
            FlowRecallResubmitApprovalProcess plugin = new FlowRecallResubmitApprovalProcess();
            plugin.describe();
            Map<String, Object> inputParams = new Map<String,Object>();
            string recId = pad.Id;
            InputParams.put('RecordId', recId);
            
            Process.PluginRequest request = new Process.PluginRequest(inputParams);  
            plugin.invoke(request);
            
            Agreement_Document__c testPAD = [Select Id, Escalate_Approval_Flag__c From Agreement_Document__c limit 1];
            system.assertEquals(testPAD.Escalate_Approval_Flag__c, true);
            
        }

    }
}