/*****************************************************************************************************************
    
    Author:         Lyndon Lavapie(Cloud Sherpas)  
    Date Created:   08/04/2015
    Description:    This Class is used to recall and resubmit approval(escalate approval)
    
    Change Log:
    Date:          Author:              	Description:
    08/04/2016     Lyndon Lavapie    		Created

******************************************************************************************************************/
global without sharing class FlowRecallResubmitApprovalProcess implements Process.Plugin { 
    global Process.PluginResult invoke(Process.PluginRequest request) { 
      String recId = (String) request.inputParameters.get('RecordId');
      recallResbmitApproval(recId);
      Map<String,Object> result = new Map<String,Object>();
      return new Process.PluginResult(result);
   }
    global Process.PluginDescribeResult describe() { 
      Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
      result.Name = 'Escalate Approval';
      result.Tag = 'Escalate Approval';
      result.inputParameters = new 
         List<Process.PluginDescribeResult.InputParameter>{ 
            new Process.PluginDescribeResult.InputParameter('RecordId', 
            Process.PluginDescribeResult.ParameterType.STRING, true)
         }; 

       
      
      return result; 
   }
    private static final String ApprovalCommentEscalated = 'Approval Escalated';
    private static final String ApprovalRecallComment = 'Recalled To Escalate Approval';
    /*********************************************************************************************************************************
    	Author: 		Lyndon Lavapie
    	Description:	Recall Approval Process, update Escalate approval flag then resubmit approval(Escalate)
    
    	Input:		    Id target object Id
    	Output:		    Void
	*********************************************************************************************************************************/
    public void recallResbmitApproval(Id recId){
    	Agreement_Document__c ad = [Select Id, Escalate_Approval_Flag__c From Agreement_Document__c where Id =: recId];
    	if(!ad.Escalate_Approval_Flag__c){
			//Recall Approval
            Approval.ProcessWorkitemRequest PWR1 = new Approval.ProcessWorkitemRequest();
            ProcessInstance pi = [Select Id, CompletedDate ,Status From ProcessInstance Where TargetObjectId =:  recId And Status = 'Pending' Limit 1];
            ProcessInstanceWorkitem  workitem = [select Id from ProcessInstanceWorkitem where ProcessInstanceId = :pi.id Limit 1];
            PWR1.setWorkitemId(workitem.Id);
            PWR1.setComments(ApprovalRecallComment);
            PWR1.setAction('Removed');
            Approval.ProcessResult result =  Approval.process(PWR1, false);
            system.debug(result + 'result');
            
            if(result.isSuccess()){
                //update escalate approval flag
                ad.Escalate_Approval_Flag__c = true;
                ad.Allow_Submit_For_Approval__c = true;
                Database.SaveResult sr = Database.update(ad, false);
                //resubmit approval
                if(sr.isSuccess()){
                    system.debug('successfully updated Agreement Document. ID: '+ sr.getId());
                    Approval.ProcessSubmitRequest req1 =new Approval.ProcessSubmitRequest();
                    req1.setComments(ApprovalCommentEscalated);
                    req1.setObjectId(recId);
                    req1.setSubmitterId(UserInfo.getUserId());
                    Approval.ProcessResult result2 = Approval.process(req1);
                    system.debug('Submit Approval Result'+ result2);
                }
            }else{
                system.debug('the following error occurred: '+result.getErrors());
            }
    	}
    }
}