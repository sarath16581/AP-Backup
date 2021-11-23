/**************************************************
Type:           test class for CustomerScopeQuestionsUtility
History:
--------------------------------------------------
10.05.2019      Ramtej    Created
**************************************************/
@istest
public class CustomerScopeQuestionsUtilityTest {

    @testSetup static void setUpData() {
        //setup data to support Customer scoping questionnaire record.
        Opportunity opp = new Opportunity(Name = 'Test Optty', StageName = 'Identify', CloseDate = system.today());
        insert opp;
        Customer_Scoping_Questionnaire__c CSQ = new Customer_Scoping_Questionnaire__c(CSQ_Status__c = 'Approved_by_SM', Opportunity__c = opp.Id);
        insert CSQ;
        Freight_Offering__c freightOffering = new Freight_Offering__c(Customer_Scoping_Questionnaire__c = CSQ.Id, Cartons__c = true, 
                                                                      B2BCartons__c = 50, B2CCartons__c  = 50, Qty_ConnotesCartons__c = 100, 
                                                                      Qty_Items_cartons__c = 100, B2CBBP__c = 50, B2BBBP__c = 50, 
                                                                      B2BSatchels__c = 50, B2CSatchels__c = 50);
        insert freightOffering;
        Pick_Up_Location__c pickUpLoc = new Pick_Up_Location__c(pick_up_location_status__c = 'Rejected', CSQ__c = CSQ.Id, Freight_Offering__c = freightOffering.id);
        insert pickUpLoc;
               
    } 
    
    public testmethod static void testFromCSQApproval(){
        //create a user setting manager who will be approver when CSQ record is submitted for approval
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User Manager = new User(Alias = 'testx', Email='testx@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='testx@auspost.com.au');                                                
        insert Manager;
        User submitter = new User(Alias = 'testx1', Email='testx1@auspost.com.au',
                        EmailEncodingKey='UTF-8', LastName='x', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='testx1@auspost.com.au', ManagerId = manager.Id);   
        
        system.runAs(submitter){
            //Query the record to submit for approval
            Customer_Scoping_Questionnaire__c CSQ = [SELECT Id FROM Customer_Scoping_Questionnaire__c LIMIT 1];
            
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(CSQ.id);
            Approval.ProcessResult result = Approval.process(req1);
            system.assertEquals(Approval.isLocked(CSQ.id), true);//make sure the record is locked
            
            test.startTest();
            CustomerScopeQuestionsUtility.unlockCSQApprovalRec(new List<Id>{CSQ.Id});
            test.stopTest();
        }
        
    }
}