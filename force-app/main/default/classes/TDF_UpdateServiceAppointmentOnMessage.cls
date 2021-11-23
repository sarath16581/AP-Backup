/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-12
* @domain Field Service 
* @description  Service to update Service Appointments when a message is posted by a Driver or Dispatcher
*                   If a message is posted on a Work Order by a Dispatcher, the service adds text to the subject of the SA record and its related
*                    FFD to notify the driver, and set flags so the SA is visble in the Service Apointment list field with Messaging filter set
*                   If a message is posted on a Work Order by a Driver, the service clears the text to the subject of the SA record and its related
*                    and adjust flags for the Service Apointment list view
*                   If a message is closed, the subject text is removed and the flags are reset

*                   Called from the following:
*                   1) FeedItemTriggerHander (calls updateSAOnTDFPost)
*                   2) FeedCommentTriggerHandler (calls updateSAOnTDFComment)
*                   3) FSL Gantt action 'Close Message' (calls updateSASubjectAndFlags directly)
*
* @changelog 
* 2020-08-12 - Andrew Judd - Created 
* 2020-09-22 - Andrew Judd - Added with sharing 
* 2020-09-23 - Andrew Judd - Changed logic to for retrieve of profile in updateOnPost and updateOnComment
* 2020-09-23 - Andrew Judd - Updated comment in updateSASubjectAndFlags
*/
public with sharing class TDF_UpdateServiceAppointmentOnMessage {    
	
    //Function to set flags, set and clear subject on Service Appointments if POST is submitted from a TDF Driver or Planner or admin
    public static void updateOnPost(List<FeedItem> feedItemList){
        
        String parentId;
        Id userId = UserInfo.getUserId();
        String profileString;
        List<Boolean> controlFlagsDriverList = new List<Boolean>{false,true,true};
        List<Boolean> controlFlagsDispatcherList = new List<Boolean>{true,false,true};
        Map<Id,List<Boolean>> woIdWithControlFlagsMap = new Map<Id,List<Boolean>>();
        List<FeedItem> feedItemToProcessList = new List<FeedItem>();

        //Build a list of processable items
        for(FeedItem fi : feedItemList){

            //Get the record posted on
            parentId = fi.ParentId;

            //If feed item associated to a Work Order
            if(parentId.left(3) == '0WO'){
                
                //If feed item is a TextPost
                if(fi.Type == 'TextPost'){
                    
                    //Add to list of processable feed items
                    feedItemToProcessList.add(fi);
                }
            }
        }
        
        //If any feed items to process
        if(feedItemToProcessList.size() > 0) {

            //Get the profile from the user
            profileString = [SELECT Profile.Name FROM User WHERE Id = :userId].Profile.Name;
        
            //For each feed item record to process
            for(FeedItem fi : feedItemToProcessList){
                
                //Get the record posted on
                parentId = fi.ParentId;

                //If post created by a TDF Driver user
                if(profileString == 'TDF Driver'){
                    //Then set flags to display in fsl gantt and clear subject text
                    woIdWithControlFlagsMap.put(parentId,controlFlagsDriverList.clone());
                    
                }
                //If post created by a TDF Planner user (i.e. Dispatcher) or admin
                if(profileString == 'TDF Planner' || profileString == 'System Administrator' ){
                    //Then set flags to display in fsl gantt and set subject text to notifiy driver
                    woIdWithControlFlagsMap.put(parentId,controlFlagsDispatcherList.clone());
                } 
            }
        }

        //If any driver and dispatcher posts to process
        if(woIdWithControlFlagsMap.size() > 0){
            updateSASubjectAndFlags(woIdWithControlFlagsMap);
        }
    }

    //Function to set flags, set and clear subject on Service Appointments if a COMMENT added to post from a TDF Driver or Planner or admin
    public static void updateOnComment(List<FeedComment> feedCommentList){
        
        String parentId;
        Id userId = UserInfo.getUserId();
        String profileString;
        List<Boolean> controlFlagsDriverList = new List<Boolean>{false,true,true};
        List<Boolean> controlFlagsDispatcherList = new List<Boolean>{true,false,true};
        Map<Id,List<Boolean>> woIdWithControlFlagsMap = new Map<Id,List<Boolean>>();
        List<FeedComment> feedCommentToProcessList = new List<FeedComment>();

        //Build a list of processable comments
        for(FeedComment fc : feedCommentList){

            //Get the record posted on
            parentId = fc.ParentId;

            //If feed comment associated to a Work Order
            if(parentId.left(3) == '0WO'){
                
                //Add to list of processable feed comments
                feedCommentToProcessList.add(fc);
            }
        }        

        //If any feed comments to process
        if(feedCommentToProcessList.size() > 0){

            //Get the profile from the user
            profileString = [SELECT Profile.Name FROM User WHERE Id = :userId].Profile.Name;
            
            //For each comment record to process
            for(FeedComment fc : feedCommentToProcessList){
                
                //Get the record posted on
                parentId = fc.ParentId;

                //If comment is created by a TDF Driver user
                if(profileString == 'TDF Driver'){
                    //Then set flags to display in fsl gantt and clear subject text
                    woIdWithControlFlagsMap.put(parentId,controlFlagsDriverList.clone());
                }
                //If comment created by a TDF Planner user (i.e. Dispatcher) or admin
                if(profileString == 'TDF Planner' || profileString == 'System Administrator' ){
                    //Then set flags to display in fsl gantt and set subject text to notifiy driver
                    woIdWithControlFlagsMap.put(parentId,controlFlagsDispatcherList.clone());
                } 
            }
        }

        //If any driver and dispatcher comments to process
        if(woIdWithControlFlagsMap.size() > 0){
            updateSASubjectAndFlags(woIdWithControlFlagsMap);
        }
    }    

    //Function to update the Service Appointment that a chatter post or comment has been made on, 
    //-and if it is not an FFD do the same to its related FFD Service Appointment
    public static void updateSASubjectAndFlags(Map<Id,List<Boolean>> woIdWithControlFlagsMap){
        
        Map<Id,Id> ffdWOToPostWOMap = new Map<Id,Id>();
        Set<Id> woIdSet = new Set<Id>();
        List<Boolean> controlFlagsList = new List<Boolean>();
        Id woId;
        Id woPostedOnId;
        String subjectPrefixString;
        Boolean addMsgRec;
        Boolean setRespFlag;
        Boolean setMsgActiveFlag;
        
        //#For all work orders passed in, get their related FFD work order
        //Constrain on Resource Type of Technician (T) only to only get Service Appointment assignments for the driver
        //ignoring assignments to the Duty (Crew) service resource
        List<AssignedResource> assResList = [SELECT ServiceAppointment.ParentRecordId, ServiceResource.Fit_For_Duty_Work_Order__c 
                                                FROM AssignedResource 
                                                WHERE ServiceAppointment.ParentRecordId 
                                                IN :woIdWithControlFlagsMap.keySet()  
                                                AND ServiceResource.ResourceType = 'T'];

        //Add to map of ffdWOToPostWOMap to provide a link between the non ffd wo that was posted on and its related ffd
        for(AssignedResource assRes : assResList){
            ffdWOToPostWOMap.put(assRes.ServiceResource.Fit_For_Duty_Work_Order__c,assRes.ServiceAppointment.ParentRecordId);
        }

        //Get set of all work order ids for SA query. Add all ids passed in, and all related FFDs
        woIdSet.addAll(woIdWithControlFlagsMap.keySet());
        woIdSet.addAll(ffdWOToPostWOMap.keySet());

        //Get all Service Appointments
        List<ServiceAppointment> saList = [SELECT Id, Subject, Response_Received__c, Message_Active__c, ParentRecordId 
                                            FROM ServiceAppointment 
                                            WHERE ParentRecordId 
                                            IN :woIdSet];
        
        //If SAs found
        if(saList.size() > 0){
        
            //#Process each SA record
            for(ServiceAppointment sa : saList){
                
                woId = sa.ParentRecordId;

                //If SA has subject text
                if(sa.Subject != null){
                    //Get the start of the subject text
                    subjectPrefixString = sa.Subject.left(18);
                }

                //If sa wo was posted on
                if(woIdWithControlFlagsMap.get(woId) != null){

                    //Get list of control flags
                    controlFlagsList = woIdWithControlFlagsMap.get(woId);

                    //Get control flags from list
                    addMsgRec = controlFlagsList.get(0);
                    setRespFlag = controlFlagsList.get(1);
                    setMsgActiveFlag = controlFlagsList.get(2);
     
                    //If adding message (i.e. posted by Dispatcher)
                    if(addMsgRec){                
                        //If not already set
                        if(subjectPrefixString != '**MESSAGE RECEIVED'){
                            
                            //Then append to message text
                            sa.Subject = '**MESSAGE RECEIVED** ' + sa.Subject;
                        }
                    }
                    //Else removing (i.e. posted by Driver or closing)
                    else{
                        //If present
                        if(subjectPrefixString == '**MESSAGE RECEIVED'){

                            //Then remove
                            sa.Subject = sa.Subject.replace('**MESSAGE RECEIVED BELOW** ','');
                            sa.Subject = sa.Subject.replace('**MESSAGE RECEIVED** ','');
                        }
                    }
                    //Set response and message active flags for gantt display
                    sa.Response_Received__c = setRespFlag;
                    sa.Message_Active__c = setMsgActiveFlag;
                }
                //Else record was not posted on, and has been included to set subject text on this related FFD
                else{
                                        
                    //Get the wo that was posted on that relates to this ffd
                    woPostedOnId = ffdWOToPostWOMap.get(woId);

                    //Get list of control flags of the related record
                    controlFlagsList = woIdWithControlFlagsMap.get(woPostedOnId);

                    //Get control flags from list. 
                    //-Note that the control response and active flags are not set on the related FFD
                    //-Only it's subject is updated to advise the driver there is a message on a WO below
                    addMsgRec = controlFlagsList.get(0);

                    //If adding message (i.e. posted by Dispatcher)
                    if(addMsgRec){    
                        if(subjectPrefixString != '**MESSAGE RECEIVED'){
                        
                            //Then append message below text
                            sa.Subject = '**MESSAGE RECEIVED BELOW** ' + sa.Subject;
                        }
                    }
                    //Else removing (i.e. posted by Driver or closing)
                    else {
                        //If present
                        if(subjectPrefixString == '**MESSAGE RECEIVED'){

                            //Then remove
                            sa.Subject = sa.Subject.replace('**MESSAGE RECEIVED BELOW** ','');
                            sa.Subject = sa.Subject.replace('**MESSAGE RECEIVED** ','');
                        }
                    }
                }
            }
            
            //apply changes
            update saList;

        } //end if sas found
    } 
}