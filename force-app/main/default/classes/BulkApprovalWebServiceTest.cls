/**
   * Created by: Adrian Recio
   * Description: Test class for BulkApprovalWebService class
   * Date: 10/4/2017
   */
@IsTest
private class BulkApprovalWebServiceTest {
    /* Test Method for bulk approvals */
    public static testmethod void testWebservice(){
        try{
             // Create Test Case
            Case cs = I2CTestDataBuilder.createCase();
            insert cs;
            
            cs.OwnerId = Userinfo.getUserId();
            update cs;
    
            
            String gsRecordTypeID = Schema.SObjectType.Disputed_Item__c.getRecordTypeInfosByName().get('SAP ERP').getRecordTypeId();
            
            // Create Test Disputed Items without existing CA
            List<Disputed_Item__c> diListWithoutCA = I2CTestDataBuilder.createDisputeItem(cs);
            List<Disputed_Item__c> diListWithoutCAtoBeUpdated = new List<Disputed_Item__c>();
            for(Disputed_Item__c dst : diListWithoutCA){
                if(dst.Product__c!='Road' && dst.Product__c!='Air'){
                    dst.recordtypeId = gsRecordTypeID;
                    diListWithoutCAtoBeUpdated.add(dst);
                }    
            }
    
            // Create Test Disputed Items with existing CA
            List<Disputed_Item__c> diListwithCA = I2CTestDataBuilder.createDisputeItem(cs);
            
            insert diListWithoutCAtoBeUpdated; // populateCreditApproval
     
            // Pull populated CA
            List<Credit_Approval__c> caList = [Select Id, Status__c, Ready_For_Approval__c from Credit_Approval__c];
            
            // Complete required values in CA for approval
            /*for(Credit_Approval__c caVar: caList){
                caVar.Ready_for_Approval__c = true;
            }*/
            
            // Update CA for approval
            //update caList;
                
            // Create an approval request for the account
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(caList[0].id);
            // Submit on behalf of a specific submitter
            req1.setSubmitterId(UserInfo.getUserId());
            // Submit the record to specific process and skip the criteria evaluation
            req1.setProcessDefinitionNameOrId('Enterprise_Credit_Disputesv1_4');
            req1.setSkipEntryCriteria(true);
            
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
            
            // Verify the result
            System.assert(result.isSuccess());
            
            System.assertEquals('Rejected', result.getInstanceStatus(), 
                                'Instance Status'+result.getInstanceStatus());
           
            // Approve the submitted request
            // First, get the ID of the newly created item
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            
            Set<Id>caSet = new Set<Id>();
            caSet.add(caList[0].Id);
            // Instantiate the new ProcessWorkitemRequest object and populate it
            /*
            Approval.ProcessWorkitemRequest req2 = 
                new Approval.ProcessWorkitemRequest();
                req2.setComments('Approving request.');
                req2.setAction('Approve');
                req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            */
            
            // Use the ID from the newly created item to specify the item to be worked
            //req2.setWorkitemId(newWorkItemIds.get(0));
            
            // Submit the request for approval
            //Approval.ProcessResult result2 =  Approval.process(req2);
            
            // Verify the results
            //System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
            
            /*System.assertEquals(
                'Approved', result2.getInstanceStatus(), 
                'Instance Status'+result2.getInstanceStatus());*/
            
            test.startTest();
                system.debug('CA Set Value-- '+string.valueOf(caSet).remove('}').remove('{'));
                ApexPages.StandardSetController controller = new ApexPages.StandardSetController(caList);
                BulkApprovalWebService baws = new BulkApprovalWebService(controller);
                baws.gatherAllCheckedApprovals();
                BulkApprovalWebService.bulkApprove(string.valueOf(caSet).remove('}').remove('{')); // Successful Approval
                BulkApprovalWebService.bulkApprove(null); // Failed Approval
            test.stopTest();
        }catch(Exception e){
            e.getStackTraceString();    
        }
    }
    
    public static testMethod void bulkMethodTest(){
     BulkApprovalWebService.bulkMethod();
  }
}