/**
* Author: 		Angelo Rivera
* Name: 		BatchCreditApprovalEscalation
* Description: 	Extract Credit approval records and escalate current approval if over the configured business days for escalation on
*					the matching Credit Approval Process Settings record.
* Revision History
* 07-08-2017 	1.0		AP.Rivera		Created
**/

global without sharing class BatchCreditApprovalEscalation implements Database.Batchable<sObject> {
	
	public String query;
	public static final String PENDING_AD = 'Pending Approval Decision';
	public static final String PENDING_STATUS = 'Pending';
	
	global BatchCreditApprovalEscalation() {
		query = 'Select Id, Name, Status__c, Date_Submitted_to_Current_Approver__c from Credit_Approval__c ' +
					'where Status__c =: PENDING_AD and Date_Submitted_to_Current_Approver__c != NULL';
	}
	
	// Start Method
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	//Execute Logic
   	global void execute(Database.BatchableContext BC, List<Credit_Approval__c> lstCreditApproval) {
   		try{
	   		if(!lstCreditApproval.isEmpty()){
		   		Set<Id> setCreditApprovalId = new Set<Id>();
		   		Set<Id> setApprovalSubmissionId = new Set<Id>();
		   		Set<Id> setCAProcessSettingId = new Set<Id>();
		   		Set<Id> setCAProcessSettingEscalateId = new Set<Id>();
		   		Set<Id> setProcessInstanceIds = new Set<Id>();
		   		Set<Id> setApprovalWorkflowId = new Set<Id>();
		   		Map<Id, Approval_Submission__c> mapCAIdAppSubmission = new Map<Id, Approval_Submission__c>();
		   		Map<Id, List<Approval_Workflow__c>> mapAppSubIdAppSteps = new Map<Id, List<Approval_Workflow__c>>();
		   		Map<Id, Credit_Approval_Process_Setting__c> mapCredAppProcessSetting = new Map<Id, Credit_Approval_Process_Setting__c>();
		   		Map<Id, List<Approval_Steps__c>> mapCAPSIdApprovalStep = new Map<Id, List<Approval_Steps__c>>();
		   		Map<Id, Id> mapAppSubIdCredAppProcSetId = new Map<Id, Id>();
		   		Map<Id, ProcessInstance> mapCAIdProcInstance = new map<Id, ProcessInstance>();
		   		Map<Id, ProcessInstanceNode> mapInstanceNode = new map<Id, ProcessInstanceNode>();
		   		Map<Id, String> mapProcInstEscComment = new Map<Id, String>();
		   		Map<Id, String> mapAppWorkflowIdEscComment = new Map<Id, String>();
				Set<Id> escalationCAIds = new Set<Id>();
                
	   			for(Credit_Approval__c creditApprovalRec : lstCreditApproval){
	   				setCreditApprovalId.add(creditApprovalRec.Id);
	   			}

	   			//retrieves Approval_Submission__c and maps to corresponding credit approval record
	   			retrieveApprovalSubmission(mapCAIdAppSubmission, setApprovalSubmissionId, setCAProcessSettingId, mapAppSubIdCredAppProcSetId, setCreditApprovalId);			

	   			//retrieve Approval_Workflow__c and maps to corresponding Approval_Submission__c
	   			mapAppSubIdAppSteps = retrieveAppSubmissionAppWorkflowStepsMap(setApprovalSubmissionId);

	   			if(!setCAProcessSettingId.isEmpty()){
		   			//retrieve Credit_Approval_Process_Setting__c related to current credit approval record
		   			retrieveCredAppProcSettingMap(mapCredAppProcessSetting, setCAProcessSettingEscalateId, setCAProcessSettingId);

	   				//retrieve Approval_Steps__c and maps to corresponding Credit_Approval_Process_Setting__c
	   				mapCAPSIdApprovalStep = retrieveCredAppProcSettingApprovalStepMap(setCAProcessSettingEscalateId);

		   			//retrieve process instance and maps to corresponding credit approval record
					mapCAIdProcInstance = retrieveCreditAppProcessInstMap(setCreditApprovalId);

		            //retrieve Map of process instance and node steps
		            mapInstanceNode = retrieveInstanceNodeMap(mapCAIdProcInstance);

		            for(Credit_Approval__c credApprovalRec : lstCreditApproval){
			        	Long approvalSubmittedElapsedDay = computeForElapsedDay(credApprovalRec.Date_Submitted_to_Current_Approver__c);			        	
						if(mapCAIdProcInstance.containsKey(credApprovalRec.Id)){
							ProcessInstance procInstanceRec = mapCAIdProcInstance.get(credApprovalRec.Id);
							String currentApprovalStepName = mapInstanceNode.get(procInstanceRec.Id).ProcessNodeName;
							Approval_Submission__c appSubmission = new Approval_Submission__c();
				            appSubmission = mapCAIdAppSubmission.get(credApprovalRec.Id);
				            if(appSubmission!=null){
					            Id credAppProcSettigId = mapAppSubIdCredAppProcSetId.get(appSubmission.Id);
					            if(mapCredAppProcessSetting.containsKey(credAppProcSettigId)){			            	
					            	Credit_Approval_Process_Setting__c credAppProcSettingRec = new Credit_Approval_Process_Setting__c();
					            	credAppProcSettingRec = mapCredAppProcessSetting.get(credAppProcSettigId);
					            	if(credAppProcSettingRec.Escalate_Process__c){
					            		if(mapCAPSIdApprovalStep.containsKey(credAppProcSettigId)){
					            			Set<String> setStepName = new Set<String>();
					            			for( Approval_Steps__c appStepRec: mapCAPSIdApprovalStep.get(credAppProcSettigId)){
					            				setStepName.add(appStepRec.Step_Name__c);
								            }

								            if(setStepName.contains(currentApprovalStepName)){
                                                if(approvalSubmittedElapsedDay >= credAppProcSettingRec.EscalationTimeinBusinessDays__c){
								            		Boolean processApproval = false;								            		
								            		List<Approval_Workflow__c> lstAppWorkflowSteps = new List<Approval_Workflow__c>();
								            		lstAppWorkflowSteps = mapAppSubIdAppSteps.get(appSubmission.Id);
                                                    String lastApprovalWorkflowStep = lstAppWorkflowSteps[lstAppWorkflowSteps.size()-1].Step_Name__c;
								            		
								            		for(Approval_Workflow__c appWorkFlowStep : lstAppWorkflowSteps){
								            			if(appWorkFlowStep.Step_Name__c != lastApprovalWorkflowStep){
								            				if(appWorkFlowStep.Step_Name__c == currentApprovalStepName){
									            				setApprovalWorkflowId.add(appWorkFlowStep.Id);
									            				mapAppWorkflowIdEscComment.put(appWorkFlowStep.Id, credAppProcSettingRec.Escalation_Comment__c);						            				
								            					processApproval = true;
								            				}
								            			}
								            		}

								            		if(processApproval){
														setProcessInstanceIds.add(procInstanceRec.Id);
								            			mapProcInstEscComment.put(procInstanceRec.Id, credAppProcSettingRec.Escalation_Comment__c);
                                                        escalationCAIds.add(credApprovalRec.Id);
								            		}else{
								            			System.debug('###DEBUG - This will not be auto approved since its on the final approval step.');
								            		}
								            	}else{
								            		System.debug('###DEBUG - Elapsed Days is less than the Escalation Time in Business Days');
								            	}
								            }
					            		}
					            	}
					            }
					        }
						}
			        }
			        //auto approve process instance
			        if(setProcessInstanceIds != null && !setProcessInstanceIds.isEmpty()){
			        	approveProcessInstance(setProcessInstanceIds, mapProcInstEscComment, escalationCAIds);
			        	//update status of approval work flow to Escalated
			        	if(setApprovalWorkflowId != null && !setApprovalWorkflowId.isEmpty()){
			        		updateApprovalWorkflow(setApprovalWorkflowId, mapAppWorkflowIdEscComment);
                            retrieveApprovalWorkflowNextStep(mapCAIdProcInstance);
                            updateCACurrentApprover(escalationCAIds);
			        	}
			        }
	   			}
		   	}
		}catch(exception e){
            System.debug('###DEBUG: Error while processing batch  - ' + e.getMessage());
            System.debug('###DEBUG: Error while processing batch trace  - ' + e.getStackTraceString());
        }
	}

	/**
	* Name: 		retrieveApprovalSubmission
	* Description: 	Method to retrieve Approval_Submission__c and maps to corresponding credit approval record
	**/
	public void retrieveApprovalSubmission(Map<Id, Approval_Submission__c> mapCAIdAppSubmission, Set<Id> setApprovalSubmissionId, 
												Set<Id> setCAProcessSettingId, Map<Id, Id> mapAppSubIdCredAppProcSetId, 
													Set<Id> setCreditApprovalId){
		for(Approval_Submission__c appSubmission: [Select Id, Name, Credit_Approval__c, Credit_Approval_Process_Setting__c 
												   From Approval_Submission__c Where Status__c =: PENDING_STATUS And Credit_Approval__c in: setCreditApprovalId 
												   order by LastModifiedDate Desc]){
			mapCAIdAppSubmission.put(appSubmission.Credit_Approval__c, appSubmission);
			setApprovalSubmissionId.add(appSubmission.Id);
			setCAProcessSettingId.add(appSubmission.Credit_Approval_Process_Setting__c);
			mapAppSubIdCredAppProcSetId.put(appSubmission.Id, appSubmission.Credit_Approval_Process_Setting__c);
		}	
	} 

	/**
	* Name: 		updateApprovalWorkflow
	* Description: 	Method to update Approval_Workflow__c
	**/
	public void updateApprovalWorkflow(Set<Id> setApprovalWorkflowId, Map<Id, String> mapAppWorkflowIdEscComment){
		List<Approval_Workflow__c> lstApprovalWorkflow = new List<Approval_Workflow__c>();
		for(Approval_Workflow__c aws : [Select Id, Actual_Approver__c, Step_Name__c, Status__c,Sequence__c, Comments__c, Approved_Date_Time__c 
										From Approval_Workflow__c Where Id in: setApprovalWorkflowId]){
			aws.Status__c = 'Escalated';
			aws.Comments__c = mapAppWorkflowIdEscComment.get(aws.Id);
			aws.Approved_Date_Time__c = System.now();
			aws.Actual_Approver__c = UserInfo.getUserId();
			lstApprovalWorkflow.add(aws);
		}
		update lstApprovalWorkflow;
	}

	/**
	* Name: 		approveProcessInstance
	* Description: 	Method to approve process instance
	**/
	public void approveProcessInstance(Set<Id> pIds, Map<Id, String> mapProcInstEscComment, Set<Id> crdAppIds){
		Approval.ProcessWorkitemRequest[] lstProcWorkItemForApproval = New Approval.ProcessWorkitemRequest[]{};
        List<Credit_Approval__c> listCrdApp = new List<Credit_Approval__c>();
		for(ProcessInstanceWorkitem piw : [Select Id,ProcessInstanceId from ProcessInstanceWorkitem 
											where ProcessInstanceId in :pIds]){
			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
	        req.setComments(mapProcInstEscComment.get(piw.ProcessInstanceId));
	        req.setAction('Approve'); 
	        req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
	        req.setWorkitemId(piw.Id);
	        lstProcWorkItemForApproval.add(req);			
		}
        if(lstProcWorkItemForApproval != null && !lstProcWorkItemForApproval.isEmpty()){
            for(Credit_Approval__c crdApp : [Select Id, Escalated__c, Escalated_Date_Time__c, Status__c From Credit_Approval__c Where Id IN :crdAppIds]){
                if(crdApp.Status__c != Label.I2C_Approved){
                    crdApp.Escalated__c = true;
                    crdApp.Escalated_Date_Time__c = System.now();
                    listCrdApp.add(crdApp);    
                }                
       		}
        	if(listCrdApp != null && !listCrdApp.isEmpty()){
            	update listCrdApp;    
        	}
			Approval.ProcessResult[] result2 =  Approval.process(lstProcWorkItemForApproval);
        }
	}

	/**
	* Name: 		computeForElapsedDay
	* Description: 	Method to get the elapsed time
	**/
	public Long computeForElapsedDay(DateTime dateSubmitted){
        Long dayCount = 0;
        List<BusinessHours> businessHoursId = [select Id from BusinessHours where Name =: Label.I2C_Escalation_Business_Hours_Name And IsActive =: true Limit 1];
        if(businessHoursId != null && businessHoursId.size() > 0){
            dayCount = -1;
            Datetime dayPointer = null;
            Long NoOfDays = DateTime.now().Date().daysBetween(dateSubmitted.date());
            for(integer i=0; i>=NoOfDays; i--){
                dayPointer = DateTime.now().addDays(i);
                Boolean isWithinTime = BusinessHours.isWithin(businessHoursId[0].Id, dayPointer);
                if(isWithinTime){
                    dayCount = dayCount + 1;
                }       	            
            }
        }else{
            dayCount = dateSubmitted.date().daysBetween(DateTime.now().Date());    
        }
		return dayCount;
	}

	/**
	* Name: 		retrieveAppSubmissionAppWorkflowStepsMap
	* Description: 	Method to retrieve Approval_Workflow__c and maps to corresponding Approval_Submission__c
	**/
	public Map<Id,List<Approval_Workflow__c>> retrieveAppSubmissionAppWorkflowStepsMap(Set<Id> setApprovalSubmissionId){
		Map<Id,List<Approval_Workflow__c>> appSubIdAppStepsMap = new Map<Id,List<Approval_Workflow__c>>();
		for(Approval_Workflow__c appWorkflow : [select Id, Submission_Group__c, Step_Name__c, Status__c,Sequence__c 
												From Approval_Workflow__c Where Submission_Group__c in: setApprovalSubmissionId 
												order by Sequence__c ASC]){
			if(!appSubIdAppStepsMap.containsKey(appWorkflow.Submission_Group__c))
                    appSubIdAppStepsMap.put(appWorkflow.Submission_Group__c, new List<Approval_Workflow__c>());
                        appSubIdAppStepsMap.get(appWorkflow.Submission_Group__c).add(appWorkflow);
		}
		return appSubIdAppStepsMap;	
	}

	/**
	* Name: 		retrieveCredAppProcSettingMap
	* Description: 	Method to retrieve Credit_Approval_Process_Setting__c related to current credit approval record
	**/
	public void retrieveCredAppProcSettingMap(Map<Id, Credit_Approval_Process_Setting__c> mapCredAppProcessSetting, 
												Set<Id> setCAProcessSettingEscalateId, Set<Id> setCAProcessSettingId){
		for(Credit_Approval_Process_Setting__c caps : [Select Id, Name, Escalate_Process__c, Escalation_Comment__c, EscalationTimeinBusinessDays__c
													from Credit_Approval_Process_Setting__c 
														where Id in: setCAProcessSettingId 
															and Escalate_Process__c = true]){
			mapCredAppProcessSetting.put(caps.Id, caps);
			setCAProcessSettingEscalateId.add(caps.Id);
		}
	}

	/**
	* Name: 		retrieveCredAppProcSettingApprovalStepMap
	* Description: 	Method to retrieve Approval_Steps__c and maps to corresponding Credit_Approval_Process_Setting__c
	**/
	public Map<Id,List<Approval_Steps__c>> retrieveCredAppProcSettingApprovalStepMap(Set<Id> setCAProcessSettingEscalateId){
		Map<Id,List<Approval_Steps__c>> credAppProcSettingAppStepMap = new Map<Id,List<Approval_Steps__c>>();
		for(Approval_Steps__c approvalStep : [Select Id, Name, Step_Name__c, Credit_Approval_Process__c, Escalate__c
												from Approval_Steps__c
													where Credit_Approval_Process__c in: setCAProcessSettingEscalateId
														and Escalate__c = true]){
			if(!credAppProcSettingAppStepMap.containsKey(approvalStep.Credit_Approval_Process__c))
                credAppProcSettingAppStepMap.put(approvalStep.Credit_Approval_Process__c, new List<Approval_Steps__c>());
                    credAppProcSettingAppStepMap.get(approvalStep.Credit_Approval_Process__c).add(approvalStep);
		}
		return credAppProcSettingAppStepMap;
	}

	/**
	* Name: 		retrieveCreditAppProcessInstMap
	* Description: 	Method to retrieve process instance and maps to corresponding credit approval record
	**/
	public map<Id, ProcessInstance> retrieveCreditAppProcessInstMap(Set<Id> setCreditApprovalId){
		map<Id, ProcessInstance> credAppIdProcInstanceMap = new map<Id, ProcessInstance>();
        for(ProcessInstance pi : [Select Id, TargetObjectId, Status, CreatedDate,
                                    (Select Id, ProcessInstanceId, StepStatus, Comments, CreatedDate
                                        from Steps order by CreatedDate DESC)
                                    from ProcessInstance
                                    	where TargetObjectId =: setCreditApprovalId
                                    		and Status =: PENDING_STATUS]){
            
            if (!credAppIdProcInstanceMap.containsKey(pi.TargetObjectId)){
                credAppIdProcInstanceMap.put(pi.TargetObjectId, pi);
            }else{
                ProcessInstance maxInstance = credAppIdProcInstanceMap.get(pi.TargetObjectId);
                if ( maxInstance.CreatedDate < pi.CreatedDate ){
                    credAppIdProcInstanceMap.put(pi.TargetObjectId, pi);
                }
            }
        }
        return credAppIdProcInstanceMap;
	}

	/**
	* Name: 		retrieveInstanceNodeMap
	* Description: 	Method to retrieve Map of process instance and node steps
	**/
	public map<Id, ProcessInstanceNode> retrieveInstanceNodeMap(map<Id, ProcessInstance> mapCAIdProcInstance){
	    set<Id> processInstIds = new set<Id>();
        for ( ProcessInstance pi : mapCAIdProcInstance.values()){
            for ( ProcessInstanceStep pis : pi.Steps){
                if ( pis.StepStatus == 'Started'){
                    processInstIds.add( pi.Id );        
                }
            }
        }

		map<Id, ProcessInstanceNode> instanceNodeMap = new map<Id, ProcessInstanceNode>();
		for(ProcessInstanceNode node : [SELECT Id, NodeStatus, ProcessNodeName, ProcessInstanceId 
	                                    FROM ProcessInstanceNode WHERE ProcessInstanceId IN: processInstIds 
	                                    AND NodeStatus =: PENDING_STATUS]){
	    	instanceNodeMap.put(node.ProcessInstanceId, node);
	    }
	    return instanceNodeMap;
	}
    
    /**
	* Name: 		retrieveApprovalWorkflowNextStep
	* Description: 	Method to retrieve the Next Step after Escalation Step 
	**/
	public void retrieveApprovalWorkflowNextStep(map<Id, ProcessInstance> mapProcInstance){
        List<Approval_Workflow__c> listAppWrkFlow = new List<Approval_Workflow__c>();
        map<Id, ProcessInstanceNode> nodeMap = new map<Id, ProcessInstanceNode>();
        nodeMap = retrieveInstanceNodeMap(mapProcInstance);
        Set<Id> prcsInstIds = new Set<Id>();
        prcsInstIds.addAll(nodeMap.keySet());
        for(Approval_Workflow__c appWrkFlow: [Select Id, Submitted_Date_Time__c, Step_Name__c, Status__c, Process_Instance_ID__c From Approval_Workflow__c 
                                              Where Status__c =: PENDING_STATUS And Process_Instance_ID__c In: prcsInstIds]){
        	if(nodeMap.get(appWrkFlow.Process_Instance_ID__c) != null && nodeMap.get(appWrkFlow.Process_Instance_ID__c).ProcessNodeName == appWrkFlow.Step_Name__c){
            	appWrkFlow.Submitted_Date_Time__c = System.now();
                listAppWrkFlow.add(appWrkFlow);
            }            
        }
        update listAppWrkFlow;
	}
    
    /**
	* Name: 		updateCACurrentApprover
	* Description: 	Method to update the current approver after the previous step has been escalated 
	**/
	public void updateCACurrentApprover(Set <Id> crdAppIds){
        Map<Id,Id> caAppMap = new Map<Id, Id>();
        List<Credit_Approval__c> lstCA = new List<Credit_Approval__c>();
        
        for(ProcessInstance processInst : [Select Id, TargetObjectId, (Select Id, ProcessInstanceId, ActorId, StepStatus From StepsAndworkItems WHERE StepStatus = 'Pending') 
                                           From ProcessInstance Where TargetObjectId IN :crdAppIds]){
            for(ProcessInstanceHistory prsInstStep : processInst.StepsAndworkItems){
                if(prsInstStep.StepStatus.equals('Pending') && !String.valueOf(prsInstStep.ActorId).startsWith('00G')){
                    caAppMap.put(processInst.TargetObjectId, prsInstStep.ActorId);    
                }                        
            }                           
        }        
        for(Credit_Approval__c crdApp : [Select Id, Current_Approver_Name__c, Status__c From Credit_Approval__c Where Id IN :crdAppIds]){
            String currentApprover = caAppMap.get(crdApp.Id);
            if(crdApp.Status__c != Label.I2C_Approved){
                crdApp.Current_Approver_Name__c = currentApprover;
                lstCA.add(crdApp);    
            }                
        }
        if(lstCA != null && !lstCA.isEmpty()){
            update lstCA;    
        }
    }
    
	global void finish(Database.BatchableContext BC) {
		System.debug('###DEBUG: Batch Process BatchCreditApprovalEscalation Completed');
	}	
}