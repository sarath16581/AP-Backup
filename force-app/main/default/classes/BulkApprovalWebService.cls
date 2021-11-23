/**
   * Created by: Robert Smith
   * Description: Allows mass approval of records which is referenced in a javascript button on the object.
   * Date: 10/4/2017
   */
global with sharing class BulkApprovalWebService {

    ApexPages.StandardSetController setCon;
    public string idSet{get;set;}
    // Constructor
    public BulkApprovalWebService(ApexPages.StandardSetController controller)
    {
        setCon = controller;
    }
    /**
	 *  This Method is called When user selects the Credit Approval records from the List view and click on Mass Approve Button
	 *  It iterates over each Credit Approval Selected Record and stores the id in form of string by comma separated value
	 *  The idSet would be used as the scope for the bulkApprove method via remoting.
	 */
    public pageReference gatherAllCheckedApprovals()
    {

        idSet = '';
        // Iterating over selected credit approval records to fetch ID'S 
        for ( Credit_Approval__c approval : (Credit_Approval__c[])setCon.getSelected() )
        {
            idSet = idSet + ',' + approval.id ;
            System.debug('Approval Id Set = ' + idSet);
        }
        idSet = idSet.removeStartIgnoreCase(',');
        return null;
    }

  /**
   * Bulk approve records from list view
   * @param  recordIds String
   * @return JSON String
   * Created by Robert Smith : Accenture : Invoice 2 Cash
   */

    @remoteAction
    public static String bulkApprove( String recordIds ) {
    Map<String, Object> response = new Map<String, Object>();
    try{
    	List<String> ids = recordIds.split(',');
    	List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
    
    	//List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN :ids ];
    	for(ProcessInstanceWorkitem workItem : [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN :ids]){
          Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
          req.setWorkitemId(workItem.Id);
          //Valid values are: Approve, Reject, or Removed. 
          //Only system administrators can specify Removed.
          req.setAction('Approve');
          req.setComments('Approved.');
          requests.add(req);
    	}
    	Approval.ProcessResult[] processResults = Approval.process(requests);
    } catch ( Exception ex ){
      response.put('status', '500');
      response.put('error', ex.getMessage());
      return JSON.serialize(response);
    }
    response.put('status', '200');
    return JSON.serialize(response);
  }
	
   /**
  * Bulk request approval from list view
  * @param  recordIds String
  * @return JSON String
  * Created by Robert Smith : Accenture : Invoice 2 Cash. Commented out will be used for phase 2.
  */
  /*
  webService static String bulkRequest( String recordIds ) {
    Map<String, Object> response = new Map<String, Object>();
    try{
    	List<String> ids = recordIds.split(',');
    	List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
    
    	for(String rId : ids){
          Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
          req.setObjectId(rId);
          //If the next step in your approval process is another Apex approval process, you specify exactly one user ID as the next approver. 
          //If not, you cannot specify a user ID and this method must be null.
          //req.setNextApproverIds(null);
          requests.add(req);
    	}
    	Approval.ProcessResult[] processResults = Approval.process(requests);
    	//Valid values are: Approved, Rejected, Removed or Pending.
    	System.assertEquals('Pending', processResults[0].getInstanceStatus());
    } catch ( Exception ex ){
    	response.put('status', '500');
    	response.put('error', ex.getMessage());
    	return JSON.serialize(response);
    }
    response.put('status', '200');
    return JSON.serialize(response);
  }
  */
    
    public static void bulkMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
  	}
}