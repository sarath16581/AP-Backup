/** 
* @author Gaurav  
* @date 2017-?-?
* @domain Field Service 
* @description Utility Class to instatiate Transport TDF scheduled jobs 
*               based on custom setting data in TDF_NotificationScheduler
*
* @changelog 
* 04-08-2020 - Andrew Judd - Added support for DispatchWorkScheduler
* 05-08-2020 - Andrew Judd - Added support for GenerateWorkScheduler
* 25-08-2020 - Andrew Judd - Removed scheduling of the following:
*                               - ServiceReportNotificationScheduler
*                               - TDF_FollowWorkOrderScheduler
*/
public class TDF_SchedulerUtility{

    public Map<String, String> collaborationGroupMap;
    public String chatterMsg;

    //Constructor with the Chatter message
    public TDF_SchedulerUtility(String msg){

        chatterMsg = msg;

        Set<String> dispatcherNameSet = new Set<String>();        
        List<ServiceTerritory> serviceTerritoryList = new List<ServiceTerritory>();
        collaborationGroupMap = new Map<String, String>();

        //get all the Service Territories
        serviceTerritoryList = [SELECT Id, TerritoryDispatcher__c FROM ServiceTerritory];

        //loop theogh the Service Territories for getting their Dispatcher name and add the names in a Set       
        for(ServiceTerritory objServiceTerritory : serviceTerritoryList){
            if(objServiceTerritory.TerritoryDispatcher__c != null){
                dispatcherNameSet.add(objServiceTerritory.TerritoryDispatcher__c);
            }
        }

        //get the Collaboration Group for the Dispatcher Name Set and create Map
        for(CollaborationGroup objCollaborationGroup : [SELECT Id, Name FROM CollaborationGroup WHERE Name IN : dispatcherNameSet]){
            for(ServiceTerritory objST : serviceTerritoryList){
                if(objCollaborationGroup.Name == objST.TerritoryDispatcher__c){
                    collaborationGroupMap.put(objST.TerritoryDispatcher__c, objCollaborationGroup.Id);
                }
            }
        } 
    }
    
    //method for posting Rest Break Notification using Scheduler class
    //Called from TDF_RestBreakNotificationScheduler
    public void restBreakNotifications(){

        List<WorkOrder> workOrderListToUpdate = new List<WorkOrder>();
        //AJ 17.08.18 New set to store service resources that have been notified
        Set<String> srNotifiedSet = new Set<String>();
        Long longMinutes;
        
        //AJ 8-12-17 Fix Define Work Order window start and end so only checking records with due date in 2 hr window
        DateTime dtWindowStart = System.now().addHours(-1); 
        DateTime dtWindowEnd = System.now().addHours(1);

        //loop through the WorkOrders that are neither In Progress nor Completed and Rest Break check box is selected, and (AJ 8-12-17 fix) within window
        for(WorkOrder objWorkOrder : [SELECT Id, IsAlertSupervisor__c, Rest_Break_Due__c, Primary_SA__r.SchedStartTime, Primary_SA__r.Primary_SR__c, Primary_SA__r.ServiceTerritoryId, Primary_SA__r.ServiceTerritory.TerritoryDispatcher__c FROM WorkOrder WHERE Status != 'In Progress' AND Status != 'Completed' AND IsRestBreak__c = true AND IsAlertSupervisor__c = false AND Rest_Break_Due__c >: dtWindowStart AND Rest_Break_Due__c <: dtWindowEnd ORDER BY Primary_SA__r.SchedStartTime ASC]){
            
            //If SR Assigned
            if(objWorkOrder.Primary_SA__r.Primary_SR__c != null){

                //AJ 17.08.18 If not already posted to this SR - where SR has more than one rest break, post is sent to earliest scheduled one only due to sort order in query
                if(!srNotifiedSet.contains(objWorkOrder.Primary_SA__r.Primary_SR__c)){
                    
                    //AJ 17.08.18 replaced with new due date
                    if(objWorkOrder.Rest_Break_Due__c != null){
    
                        //Set Due time
                        DateTime dueTime = objWorkOrder.Rest_Break_Due__c;
                        
                        //Define the Alert Start time. AJ 17.08.18 30 mins before Due start sending alerts
                        DateTime startAlert = objWorkOrder.Rest_Break_Due__c.addMinutes(-30);
                        
                        //Define Supervisor alert time. AJ 17.08.18 10 mins before Due (i.e. in last 10 min window) send final alert                      
                        DateTime supervisorAlert = objWorkOrder.Rest_Break_Due__c.addMinutes(-10);
                        Datetime now = System.now();  
                        
                        //AJ 18.08.17 Get minutes between due time and now
                        longMinutes = ((dueTime.getTime())/1000/60) - ((now.getTime())/1000/60);                
    
                        //Define the chatter post 
                        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
                        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                        
                        //check the start alert time and supervisor alert time
                        //if below condition satisfied then Post the Alert to Driver
                        if(now >= startAlert && now < supervisorAlert){
    
                            //Build message with minutes to due
                            textSegmentInput.text = chatterMsg + ' within ' + longMinutes + ' minutes.' + '\n';
                            messageBodyInput.messageSegments.add(textSegmentInput);
                            
                            feedItemInput.body = messageBodyInput;
                            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                            feedItemInput.subjectId = objWorkOrder.Id;
                            //AJ 04-09-20: Added to allow call of test class without SeeAllData
                            if(!test.isRunningTest()){
                                ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput); 
                            }
                            
                            //AJ 17.08.18 record notification sent to SR
                            srNotifiedSet.add(objWorkOrder.Primary_SA__r.Primary_SR__c);
    
                        }
    
                        //else this condition satisfied then Post the Alert to Driver including its Dispatcher.
                        else if((now >= supervisorAlert && !objWorkOrder.IsAlertSupervisor__c) || test.isRunningTest()){
                                
                            //Build final message with NOW!
                            textSegmentInput.text = chatterMsg + ' NOW!' + '\n';
                            messageBodyInput.messageSegments.add(textSegmentInput);
                            
                            //AJ 17.08.18 Use parent fields
                            if(objWorkOrder.Primary_SA__r.ServiceTerritoryId != null && collaborationGroupMap.get(objWorkOrder.Primary_SA__r.ServiceTerritory.TerritoryDispatcher__c) != null){
                                mentionSegmentInput.id = collaborationGroupMap.get(objWorkOrder.Primary_SA__r.ServiceTerritory.TerritoryDispatcher__c);
                                messageBodyInput.messageSegments.add(mentionSegmentInput);
                            }                                       
    
                            feedItemInput.body = messageBodyInput;
                            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                            feedItemInput.subjectId = objWorkOrder.Id;
                            if(!test.isRunningTest()){
                                ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId() , feedItemInput); 
                                
                                //AJ 17.08.18 record notification sent to SR
                                srNotifiedSet.add(objWorkOrder.Primary_SA__r.Primary_SR__c);
                            }
    
                            //After posting an alert inculding the Supervisor then make the checkbox true
                            objWorkOrder.IsAlertSupervisor__c = true;
                            workOrderListToUpdate.add(objWorkOrder);
                        }
                    }
                }
            }
        }
        //Update the Work Order list
        if(workOrderListToUpdate.size() > 0){
            update workOrderListToUpdate;
        }
    }

    //Method used for Scheduling Notification, follow and Unfollow Schedulers
    public static void scheduleJobs(){ 

        //Loop through the Notification Scheduler Custom Setting Records
        for(TDF_NotificationScheduler__c objNotificationSch : TDF_NotificationScheduler__c.getAll().values()){

            //Define the interval of Scheduling different Notification Schedulers
            Integer interval;
            if(objNotificationSch.ScheduleTime__c != null){
                interval = Integer.valueOf(objNotificationSch.ScheduleTime__c);
            }
            Integer n = 0;           

            //AJ 27.02.18 Added support for RefreshTerritoriesScheduler
            //AJ 04.08.20 Added support for DispatchWorkScheduler and GenerateWorkScheduler
            if(interval != null && (	objNotificationSch.Name == 'RestBreakNotificationScheduler' || 
                                    	//objNotificationSch.Name == 'ServiceReportNotificationScheduler' || 
                                    	objNotificationSch.Name == 'RefreshTerritoriesScheduler' || 
                                        objNotificationSch.Name == 'DispatchWorkScheduler' ||
                                        objNotificationSch.Name == 'GenerateWorkScheduler')){
            
                while(n+interval <= 60){ 
                               
                    System.debug(' Interval ->'+interval);
                    System.debug(' n ->'+n);
                    
                    String cron = '0 '+ n +' * 1/1 * ? *';                

                    if(objNotificationSch.Name == 'RestBreakNotificationScheduler'){

                        TDF_RestBreakNotificationScheduler objRestBreakScheduler = new TDF_RestBreakNotificationScheduler(objNotificationSch.FeedMessage__c);
                        if(Test.isRunningTest()){
                            System.schedule('Test TDF Rest Break Scheduler'+n, cron, objRestBreakScheduler);
                        }else{
                            System.schedule('TDF Rest Break Scheduler'+n, cron, objRestBreakScheduler);
                        }
                                     
                    }else if(objNotificationSch.Name == 'RefreshTerritoriesScheduler'){
                        
                        TDF_RefreshTerritoriesScheduler objRTScheduler = new TDF_RefreshTerritoriesScheduler();
                        if(Test.isRunningTest()){
                            System.schedule('Test TDF Refresh Territories Scheduler'+n, cron, objRTScheduler );
                        }else{
                            System.schedule('TDF Refresh Territories Scheduler'+n, cron, objRTScheduler );
                        }                                       
                    }else if(objNotificationSch.Name == 'DispatchWorkScheduler'){
                        
                        TDF_DispatchWorkScheduler objDWScheduler = new TDF_DispatchWorkScheduler();
                        if(Test.isRunningTest()){
                            System.schedule('Test TDF Dispatch Work Scheduler'+n, cron, objDWScheduler );
                        }else{
                            System.schedule('TDF Dispatch Work Scheduler'+n, cron, objDWScheduler );
                        }                                       
                    }else if(objNotificationSch.Name == 'GenerateWorkScheduler'){
                        
                        TDF_GenerateWorkScheduler objGWScheduler = new TDF_GenerateWorkScheduler();                        
                        if(Test.isRunningTest()){
                            System.schedule('Test TDF Generate Work Scheduler'+n, cron, objGWScheduler );
                        }else{
                            System.schedule('TDF Generate Work Scheduler'+n, cron, objGWScheduler );
                        }                                       
                    }
                    n = n + interval;
                }            
            }
        }

        //Execute Scheduler class to execute batch class for unfollow records of previous day.
        //TODO: Determine if there is a need to still unfollow work orders
        //This might still be required if the FSL Managed package still auto creates work order follow records 
        TDF_UnfollowWorkOrderScheduler objUnfollowWOSch = new TDF_UnfollowWorkOrderScheduler();
        
        if(Test.isRunningTest()){

            System.schedule('Test TDF UnFollow Work Order', '0 0 0 1/1 * ? *', objUnfollowWOSch);

        }else{

            System.schedule('TDF UnFollow Work Order', '0 0 0 1/1 * ? *', objUnfollowWOSch);

        }
        
        //Schedule auto follow scheduler class for the day.
        //TDF_Ennhance 25-08-2020: Commented out as follow work order not required since messaging no long relies on push notifications
        /*
        TDF_FollowWorkOrderScheduler objFollowWOSch = new TDF_FollowWorkOrderScheduler();
        
        if(Test.isRunningTest()){

            System.schedule('Test TDF Follow Work Order', '0 0 1 1/1 * ? *', objFollowWOSch);  

        }else{

            System.schedule('TDF Follow Work Order', '0 0 1 1/1 * ? *', objFollowWOSch);  

        }*/
    } 
}