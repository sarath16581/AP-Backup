/**************************************************
Name:       PartnerInfoApprovalProcessReportClsTest
Purpose:    Test Class for PartnerInfoApprovalProcessReportCls
Used By:    
History:
--------------------------------------------------
14.09.2015  Ashutosh (Salesforce.com)    Created
01.16.2016  Andrew Judd (Salesforce.com) Added setting of Network.Org_Unit_Type__c and Facility.Licence_Type__c to LPO for filter
**************************************************/

@isTest
public class PartnerInfoApprovalProcessReportClsTest{

    private static Network__c parentNetwork;
    private static Account licenceAcc1;
    private static Account facilityAcc1;
    public static User userObj;
    
    private static void setup(){
    
        // Insert Partner Info Custom Setting
        Partner_Info_Settings__c setting = new Partner_Info_Settings__c(
                                                                            Email_List_2__c = 'test@test.com',
                                                                            Email_List_3__c = 'test@test.com',
                                                                            First_Reminder_Days__c = 63,
                                                                            Second_Reminder_Days__c = 25,
                                                                            Third_Reminder_Days__c = 7,
                                                                            Level_3_Approval_Amount__c = 10000
                                                                        );

        insert setting;
        
        RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
        RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');



        Account parentAccount = new Account(
                                                name = 'Test0',
                                                phone = '123',
                                                ABN__c='11223344556',
                                                RecordTypeId = organizationRecType.id
                                            );

        insert parentAccount;

        parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId());
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO');
        insert network;

        facilityAcc1 = new Account(
                                            name='test1', 
                                            phone='123', 
                                            recordtypeid=facitlityRecType.id,
                                            Is_a_facility__c = true,
                                            Network_Facility__c = network.id,
                                            Subjected_To_GST__c = false,
                                            Licence_Type__c = 'LPO',
                                            ShippingState = 'SA');
        insert facilityAcc1;
        
        // Add a licence to this facility
        /*licenceAcc1 = new Account(
                                            name='test2', 
                                            phone='124', 
                                            recordtypeid=licenceRecType.id, 
                                            Facility__c =facilityAcc1.id, 
                                            Licence_Status__c= 'Draft',
                                            ParentId = parentAccount.id,
                                            Network_Manager__c=Userinfo.getUserId(),
                                            Assignment_Effective_From_Date__c = Date.today().addMonths(1)
                                            );
        insert licenceAcc1;*/

        Date licence1Anniversary = Date.today().addDays(2).addYears(1).addMonths(1).toStartOfMonth().addDays(-1);

        RecordType negPaymentRecType = RecordTypes.getRecordTypeByName('Negotiated Payment Type F1', 'Partner_Addendum__c');
        /*Partner_Addendum__c addendum1 = new Partner_Addendum__c(
                                                                Licence__c = licenceAcc1.Id, 
                                                                Status__c = 'Draft',
                                                                RecordTypeId = negPaymentRecType.Id,
                                                                End_Date__c = licence1Anniversary
                                                                );  
        insert  addendum1; */
 
         // Insert new Partner Info Change record
        Partner_Info_Change__c change1 = new Partner_Info_Change__c(
                                                                       Facility__c = facilityAcc1.id,
                                                                       Approval_Status__c = 'Draft'
                                                                    );
        // Should insert without error
        insert change1;                                                                    
        
        if([select count() from ProcessInstance where targetobjectid=:change1.id] < 1)
        {   
            System.debug('IN here');
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Partner Approve.');
            req.setNextApproverIds(new Id[] {Userinfo.getUserId()});
            req.setObjectId(change1.Id);

            //Submit the approval request
            Approval.ProcessResult result = Approval.process(req);

        }                         
      
    }
    
    private static testMethod void testsetupApprovalStructure(){

       test.startTest();
        setup(); 
        PartnerInfoApprovalProcessReportCls pObj = new PartnerInfoApprovalProcessReportCls();
        pObj.getStates();
        pObj.getApprovalStatus();
        pObj.selectedState = 'SA';
        pObj.approvalStatusStr = 'AllPendingApprovals';
        pObj.setupApprovalStructure();
        system.assert(pObj.pICWrapperList.size()>0);
        pObj.selectedState = 'All';
        pObj.approvalStatusStr = 'AllPendingApprovals';
        pObj.setupApprovalStructure();
        system.assert(pObj.pICWrapperList.size()>0);             
       test.stopTest(); 
    }
    
  
    
}