/**************************************************
Type:		Controller for Button on Standard page on ContractAssistanceForm__c
Purpose:	Controls visual force page to display errors to user.
History:
--------------------------------------------------
07.12.2017    Clint D'Silva    Created
**************************************************/
public class ContractAssistanceFormController {
    private final ContractAssistanceForm__c stdCntrlObjCAF ;
    private list<OpportunityLineItem> oppPrdLst {get;set;}
    private string btnOpt; 
    public string sObjectId {get; private set;} 
    public static final string ERR_MSG_CURR_USR_CHANGE = 'Only users who are part of Commercial Team can change owner.';
    public static final string ERR_MSG_CLOSE_OPP_OWNR = 'Only Opportunity Owner can close Legal Support Request';
    public static final string ERR_MSG_RESUB_CUSTOMISE = 'Only an Opportunity Owner or Request Owner can Resubmit a Legal Support Request. The status needs to be Rejected to perform this task.';
    public static final string ERR_MSG_NO_BASE_OBJ = 'No Commercial Team Request Record';
    
    public  ContractAssistanceFormController(ApexPages.StandardController stdController){
       oppPrdLst = null;         
       string sId ; 
       sObject sObj = stdController.getRecord();
        sObjectId = sObj.id;
        if (sObj == null || sObj.id == null) {
           sId = ApexPages.CurrentPage().getParameters().get('id');  
        } else {sId = sObj.id; sObjectId = sObj.id; }
            
        if(sObj instanceof  ContractAssistanceForm__c){
            try {
            	this.stdCntrlObjCAF = [select id, opportunity__c,Status__c,OpportunityOwner__c, opportunity__r.ownerid, ownerid from ContractAssistanceForm__c where id = :sId];    
            } catch(exception ex){
            	stdCntrlObjCAF = null;      
            }  
        } else { 
          stdCntrlObjCAF = null;  
        }
    }
	
    // Set status when ReSubmit button is clicked
    public string  onReSubmit(){
        string sMessage = '';
        if(this.stdCntrlObjCAF != null){
            if((this.stdCntrlObjCAF.OpportunityOwner__c == userinfo.getUserId() || this.stdCntrlObjCAF.ownerid == userinfo.getUserId() ) && this.stdCntrlObjCAF.Status__c == 'Rejected'  ){
            	this.stdCntrlObjCAF.Status__c = 'New';     
            } else {
              sMessage = ERR_MSG_RESUB_CUSTOMISE ; // 'Only an Opportunity Owner or Request Owner can Resubmit a Legal Support Request. The status needs to be Rejected to perform this task.';      
            }
        } else {
        	sMessage = ERR_MSG_NO_BASE_OBJ; //'No Legal Support Request Record';     
        }
        return sMessage;
    }
    
    // Set status to Close when Close button is clicked
    public string  onClose(){
        string sMessage = '';
        if(this.stdCntrlObjCAF != null){
            if(this.stdCntrlObjCAF.OpportunityOwner__c  == userinfo.getUserId()  ){
            	this.stdCntrlObjCAF.Status__c = 'Closed';    
            } else {
              sMessage = ERR_MSG_CLOSE_OPP_OWNR; // 'Only Opportunity Owner can close Legal Support Request'      
            }
        } else {
        	sMessage = ERR_MSG_NO_BASE_OBJ; // 'No Legal Support Request Record';     
        }
        return sMessage;
    }
    
    // Invoke appropriate function based on parameter set in query string
    PUBLIC PageReference autoRun(){
        if(stdCntrlObjCAF != null){
            string sMessage = '';
        	String theId = this.stdCntrlObjCAF.id;   
            PageReference pageRef = new PageReference('/' + theId);
            btnOpt = ApexPages.CurrentPage().getParameters().get('opt');
        	
            if(btnOpt == 'cls'){
           		system.debug('In close'); 
           		  sMessage =  this.onClose();  
        	} else if (btnOpt == 'usr'){
            	system.debug('In Usr'); 
        		 sMessage = this.AssignCurrentUser();    
        	} else if (btnOpt == 'resub'){
            	system.debug('In reSub'); 
        		 sMessage = this.onReSubmit();    
        	}
            
            if(string.isBlank(sMessage)) {
            	update stdCntrlObjCAF; 
                pageRef.setRedirect(true);
        		return pageRef;
            } else {
            	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,sMessage )); 
    			return null;
            }    
        }
        Return null;         
    }   
    
    // Assign ownership to current user when Assign to me button is clicked 
    public string AssignCurrentUser (){
        string errMsg = '';
        if(this.stdCntrlObjCAF != null){
        	this.stdCntrlObjCAF.OwnerId = userinfo.getUserId();
            system.debug('this.stdCntrlObjCAF.OwnerId=' + this.stdCntrlObjCAF.OwnerId);
            list<GroupMember> commercialTeamMemberLst = [SELECT id FROM GroupMember WHERE Group.Type = 'Queue'and group.name = 'Commercial Team'and UserOrGroupId = :userinfo.getUserId()];
            if(commercialTeamMemberLst.size() <= 0 ){
               errMsg = ERR_MSG_CURR_USR_CHANGE ; // 'Only users who are part of Commercial Team can change owner.' ; 
            }    
        } else {
        	errMsg = ERR_MSG_NO_BASE_OBJ; // 'No Legal Support Request Record';    
        }	
        return errMsg;
    }
        
    // Get list of opportunity products
    public list<OpportunityLineItem> getOppPrd(){
        if(oppPrdLst == null && stdCntrlObjCAF != null){
          oppPrdLst =  [select id, opportunityid,product2id,Product2.name from OpportunityLineItem where opportunityid = :stdCntrlObjCAF.opportunity__c ];   
        }
        return oppPrdLst != null?oppPrdLst:(new list<OpportunityLineItem>() ) ; 
    }
    
    // get count of opportunity products
    public integer getOppPrdCount(){
        return getOppPrd().size();
    }
}