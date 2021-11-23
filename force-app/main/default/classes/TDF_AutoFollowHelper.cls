/** 
* @author Gaurav
* @date 2017-?-?
* @domain Field Service 
* @description Functions to follow and unfollow work orders based on assignment of drivers to service appointments
                Follow is requried to support the creation of push notifications
*               Called from trigger TDF_AutoFollowParentRecords                
*
* @changelog 
* 2020-07-14 - Andrew Judd - Commented out all methods except unfollowScheduler as since push notifications are not longer used for messaging
*                               Follow and unfollow not required
*/
public class TDF_AutoFollowHelper {

    //method to follow the WorkOrders by Service Resource's User
    /*TDF Enhance 25-08-2020: Commented out as not required
    public static void follow(List<AssignedResource> assignedResources){

        List<EntitySubscription> follows = new List<EntitySubscription>();
        Set<Id> serviceResourceIds = new Set<Id>();
        Set<Id> serviceAppointmentIds = new Set<Id>();
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>();        

        //get the Custom Setting record where name is FollowWorkOrder and get its Schedule Time
        Integer hoursToAdd = Integer.valueOf(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder').ScheduleTime__c);
        Datetime startTime = System.now();

        //Add that Schedule time of FollowWorkOrder Custom Setting record to the latest time that will define the EndTime
        Datetime endTime = startTime.addHours(hoursToAdd);

        //loop through the Assigned Resources and get the ServiceResourceId and ServiceAppointmentId
        for(AssignedResource ar : assignedResources) {
            serviceResourceIds.add(ar.ServiceResourceId);
            serviceAppointmentIds.add(ar.ServiceAppointmentId);
        }

        //query all Service Appointments that are associated with AssignedResource
        for(ServiceAppointment objSA : [SELECT ParentRecordId, SchedStartTime, SchedEndTime, (SELECT Id, ServiceResourceId FROM ServiceResources) FROM ServiceAppointment WHERE ParentRecord.Type = 'WorkOrder' AND Id IN : serviceAppointmentIds]){            

            //If condition satisfied for Service Appointment then add that Service Appointment Id into Set            
            if(objSA.SchedStartTime >= startTime && objSA.SchedEndTime <= endTime){

                //If Service Appointment having Assigned Resource then add the first Assigned Resource's Service Resource Id into Set
                if(objSA.ServiceResources.size()>0){
                    serviceResourceIds.add(objSA.ServiceResources[0].ServiceResourceId);
                }
                serviceAppointments.put(objSA.Id, objSA);
            }
        }

        //query all ServiceResource that are associated with AssignedResource
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN : serviceResourceIds]);

        System.debug('serviceAppointments ->'+serviceAppointments);

        //loop through the Service Appointments and follow its Parent(WorkOrder) by its Assigned Resource's ServiceResourceId
        for(ServiceAppointment objSA : serviceAppointments.values()){
            
            ServiceResource sr;

            if(objSA.ServiceResources.size()>0){
                sr = serviceResources.get(objSA.ServiceResources[0].ServiceResourceId);
            }
            
            EntitySubscription es;
            //es = new EntitySubscription();
            //es.ParentId = objSA.Id;
            //es.SubscriberId = sr.RelatedRecordId;

            //follow serviceappointments
            //follows.add(es);

            es = new EntitySubscription();
            es.ParentId = objSA.ParentRecordId;
            es.SubscriberId = sr.RelatedRecordId;

            //follow WorkOrders
            follows.add(es);                                    
        }

        //insert follows
        System.debug('follows ->'+follows+' Size->'+follows.size());
        if(follows.size()>0){
            insert(follows);
        }        
    }*/

    //method to un-follow the WorkOrders by Service Resource's User
    /*TDF Enhance 25-08-2020: Commented out as not required
    public static void unfollow(List<AssignedResource> assignedResources){

        List<EntitySubscription> unfollows = new List<EntitySubscription>();
        Set<Id> serviceResourceIds = new Set<Id>();
        Set<Id> serviceAppointmentIds = new Set<Id>();

        //loop through the Assigned Resources and get the ServiceResourceId and ServiceAppointmentId
        for(AssignedResource ar : assignedResources) {
            serviceResourceIds.add(ar.ServiceResourceId);
            serviceAppointmentIds.add(ar.ServiceAppointmentId);
        }

        //load all ServiceResource that are associated with AssignedResource
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>();
        //load all serviceappointment that are associated with AssignedResource
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>();
        
        Set<Id> relatedRecordIdSet = new Set<Id>();
        Set<Id> parentRecordIdSet = new Set<Id>();        

        //loop through the Service Resources and populate Map and add Service Resource RelatedRecord Id in a Set
        for(ServiceResource objSR : [SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN : serviceResourceIds]){
            serviceResources.put(objSR.Id, objSR);
            relatedRecordIdSet.add(objSR.RelatedRecordId);
        }

        //loop through the Service Appointment and populate Map and add ParentRecord Ids in a Set
        for(ServiceAppointment objSA : [SELECT Id, ParentRecordId FROM ServiceAppointment WHERE ParentRecord.Type = 'WorkOrder' AND Id IN : serviceAppointmentIds]){
            serviceAppointments.put(objSA.Id, objSA);
            parentRecordIdSet.add(objSA.ParentRecordId);
        }
        
        //query all the Entity Subscriptions related to WorkOrders
        List<EntitySubscription> entitySubscriptionList = new List<EntitySubscription>();
        entitySubscriptionList = [SELECT Id, ParentId, SubscriberId FROM EntitySubscription WHERE ParentId IN : parentRecordIdSet AND SubscriberId IN : relatedRecordIdSet];

        //loop throught the Assigned Resources and unfollow the records by deleting the Entity Subscription
        for(AssignedResource ar : assignedResources) {

            ServiceResource sr = serviceResources.get(ar.ServiceResourceId);
            List<EntitySubscription> es = new List<EntitySubscription>();

            //es = [SELECT Id FROM EntitySubscription WHERE ParentId = :ar.ServiceAppointmentId AND SubscriberId = :sr.RelatedRecordId];            
            //unfollow serviceappointment
            //unfollows.addAll(es);

            //unfollow parent workorder if the serviceresource is not assigned to any other SA related to the WO.
            ServiceAppointment sa = serviceAppointments.get(ar.ServiceAppointmentId);

            if(sa != null) {

                ///List<AssignedResource> srs2 = [SELECT AssignedResourceNumber FROM AssignedResource WHERE ServiceAppointmentId IN (Select Id from serviceappointment where parentRecordId = :sa.parentRecordId) AND ServiceResourceId IN (Select id from ServiceResource Where relatedRecordId = :sr.RelatedRecordId)];
                //if (srs2.size() == 1) {
                //    es = [SELECT Id FROM EntitySubscription WHERE ParentId =: sa.parentRecordId AND SubscriberId =: sr.RelatedRecordId];
                //    unfollows.addAll(es);
                //}

                for(EntitySubscription objES : entitySubscriptionList){
                    if(objES.ParentId == sa.parentRecordId && objES.SubscriberId == sr.RelatedRecordId){
                        es.add(objES);
                    }
                }
                unfollows.addAll(es);
            }
        }

        System.debug('unfollows ->'+unfollows+' Size->'+unfollows.size());
        if(unfollows.size()>0){
            delete(unfollows);
        }
    }*/
   
    //update scenario. When AR is updated with new SR, old SR unfollow parent records and new SR follow parent records
    /*TDF Enhance 25-08-2020: Commented out as not required
    public static void updateFollow(Map<Id, AssignedResource> oldArs, List<AssignedResource> newArs){

        List<AssignedResource> toUnfollow = new List<AssignedResource>();
        List<AssignedResource> toFollow = new List<AssignedResource>();
        Set<String> serviceResourceIdSet = new Set<String>();
        Map<String, User> serviceResourceUserMap = new Map<String, User>();
        Set<String> serviceAppointmentIdSet = new Set<String>();
        Map<String, ServiceAppointment> serviceAppointmentWOMap = new Map<String, ServiceAppointment>();
        Set<String> userIdSet = new Set<String>();
        Map<String, User> userMap = new Map<String, User>();
        Set<String> workOrderIdSet = new Set<String>();
        Map<String, WorkOrder> workOrderMap = new Map<String, WorkOrder>();

        //get the old and new Service Resource Ids and Service Appointment Ids in sets
        for(AssignedResource ar: newArs) {
            if(ar.ServiceResourceId != oldArs.get(ar.Id).ServiceResourceId){
                serviceResourceIdSet.add(ar.ServiceResourceId);
                serviceResourceIdSet.add(oldArs.get(ar.Id).ServiceResourceId);
                serviceAppointmentIdSet.add(ar.ServiceAppointmentId);
            }
        }

        List<ServiceResource> serviceResourceList = new List<ServiceResource>([SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN : serviceResourceIdSet]);
        
        //get the User Id from Service Resource Ids
        for(ServiceResource objSR : serviceResourceList){
            userIdSet.add(objSR.RelatedRecordId);            
        }
        //populate user map
        for(User objUser : [SELECT Id, Name FROM User WHERE Id IN : userIdSet]){
            userMap.put(objUser.Id, objUser);
        }
        //populate map with Service Resource Id and its User
        for(ServiceResource objSR : serviceResourceList){
            serviceResourceUserMap.put(objSR.Id, userMap.get(objSR.RelatedRecordId));
        }

        //get the WorkOrder Id from Service Appointment Ids and populate a Map
        for(ServiceAppointment objSA : [SELECT Id, Work_Order__c, Work_Order__r.WorkOrderNumber, ParentRecordId FROM ServiceAppointment WHERE Id IN : serviceAppointmentIdSet]){
            if(objSA.ParentRecordId != null){
                serviceAppointmentWOMap.put(objSA.Id, objSA);
                if(String.valueOf(objSA.ParentRecordId).startsWith('0WO')){
                    workOrderIdSet.add(objSA.ParentRecordId);
                }                
            }
        }
        for(WorkOrder objWO : [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Id IN : workOrderIdSet]){
            workOrderMap.put(objWO.Id, objWO);
        }

        //loop through the trigger context
        for(AssignedResource ar: newArs) {
            //Condition to check the different Service Resource Ids on update
            if(ar.ServiceResourceId != oldArs.get(ar.Id).ServiceResourceId) {

                //Post 2 Notification mentioning old user and new user on Service Appointment
                if(serviceAppointmentWOMap.get(ar.ServiceAppointmentId) != null && workOrderMap.get(serviceAppointmentWOMap.get(ar.ServiceAppointmentId).ParentRecordId) != null && ar.ServiceAppointmentId ==  oldArs.get(ar.Id).ServiceAppointmentId){
                    System.debug('In Post Notification');

                    postNotification(workOrderMap.get(serviceAppointmentWOMap.get(ar.ServiceAppointmentId).ParentRecordId), serviceResourceUserMap.get(ar.ServiceResourceId), serviceResourceUserMap.get(oldArs.get(ar.Id).ServiceResourceId));
                }

                toUnfollow.add(oldArs.get(ar.Id));
                toFollow.add(ar);
            }
        }
        if(toUnfollow.size() > 0) {
            unfollow(toUnfollow);
            follow(toFollow);
        }
    }*/

    //Method to post 2 chatter feed on Service Appointment mentioning old and new Service Resource User Id
    /*TDF Enhance 25-08-2020: Commented out as not required
    public static void postNotification(WorkOrder objWO, User newResourceUser, User oldResourceUser){

        // New Service Resource Chatter Post Start 
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        textSegmentInput.text = ' Existing work '+ objWO.WorkOrderNumber + ' was removed from you' +'\n';
        messageBodyInput.messageSegments.add(textSegmentInput);
        mentionSegmentInput.id = oldResourceUser.Id;
        messageBodyInput.messageSegments.add(mentionSegmentInput);                                               

        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = objWO.Id;
        
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput); 
        System.debug('feedElement ->'+feedElement);           
        // New Service Resource Chatter Post End

        // Old Service Resource Chatter Post Start
        feedItemInput = new ConnectApi.FeedItemInput();
        mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        messageBodyInput = new ConnectApi.MessageBodyInput();
        textSegmentInput = new ConnectApi.TextSegmentInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        textSegmentInput.text = ' New work '+ objWO.WorkOrderNumber + ' is added for you' +'\n';
        messageBodyInput.messageSegments.add(textSegmentInput);
        mentionSegmentInput.id = newResourceUser.Id;
        messageBodyInput.messageSegments.add(mentionSegmentInput);                                               

        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = objWO.Id;
        
        ConnectApi.FeedElement feedElement1 = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);             
        System.debug('feedElement 1->'+feedElement1);
        // New Service Resource Chatter Post End      
    }*/

    //method used for Following records using Scheduler
    /*TDF Enhance 25-08-2020: Commented out as not required
    public static void followScheduler(){

        List<EntitySubscription> follows = new List<EntitySubscription>();
        Set<Id> serviceResourceIds = new Set<Id>();
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>();

        Integer hoursToAdd;

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') != null && TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder').ScheduleTime__c != null){
           hoursToAdd = Integer.valueOf(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder').ScheduleTime__c);
        }else{
            hoursToAdd = 24;
        }
        Datetime startTime = System.now().addHours(hoursToAdd);
        Datetime endTime = startTime.addDays(1);

        //load all serviceappointment that are associated with AssignedResource
        for(ServiceAppointment objSA : [SELECT ParentRecordId, (SELECT Id, ServiceResourceId FROM ServiceResources) FROM ServiceAppointment WHERE ParentRecord.Type = 'WorkOrder' AND SchedStartTime >=: startTime AND SchedEndTime <=: endTime]){

            if(objSA.ServiceResources.size()>0){
                serviceResourceIds.add(objSA.ServiceResources[0].ServiceResourceId);
            }
            serviceAppointments.put(objSA.Id, objSA);
        }

        //query all ServiceResource that are associated with AssignedResource
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN : serviceResourceIds]);


        for(ServiceAppointment objSA : serviceAppointments.values()){
            
            ServiceResource sr;

            if(objSA.ServiceResources.size()>0){
                sr = serviceResources.get(objSA.ServiceResources[0].ServiceResourceId);
            
                EntitySubscription es;
                //es = new EntitySubscription();
                //es.ParentId = objSA.Id;
                //es.SubscriberId = sr.RelatedRecordId;
    
                //follow serviceappointments
                //follows.add(es);
    
                es = new EntitySubscription();
                es.ParentId = objSA.ParentRecordId;
                es.SubscriberId = sr.RelatedRecordId;
    
                //follow WorkOrders
                follows.add(es);   
            }                                 
        }
        if(follows.size()>0){
            if(!test.isRunningTest()){
                insert(follows);
            }
        }
    }*/

    //method used for unfollowing records using Scheduler
    //TDF Enhance: Keep this in place for now in case there is still a need to remove auto follows added by the FSL Managed package
    //The method is called from TDF_UnfollowWorkOrderBatch
    public static void unfollowScheduler(ServiceAppointment objSA){

        Datetime now = System.now();
        Datetime startTime = now.addDays(-2); 
        Datetime endTime = now.addDays(-1);        
              
        if(objSA.SchedStartTime >= startTime && objSA.SchedEndTime <= endTime){

            List<EntitySubscription> unfollows = new List<EntitySubscription>();

            List<EntitySubscription> entitySubscriptionList = new List<EntitySubscription>();

            if(objSA.ServiceResources.size()>0 && objSA.ServiceResources[0].ServiceResource.RelatedRecordId != null){

                //entitySubscriptionList = [SELECT Id FROM EntitySubscription WHERE ParentId =: objSA.Id AND SubscriberId =: objSA.ServiceResources[0].ServiceResource.RelatedRecordId];

                //unfollow serviceappointment
                //unfollows.addAll(entitySubscriptionList);

                entitySubscriptionList = new List<EntitySubscription>();
                entitySubscriptionList = [SELECT Id FROM EntitySubscription WHERE ParentId =: objSA.parentRecordId AND SubscriberId =: objSA.ServiceResources[0].ServiceResource.RelatedRecordId];

                //unfollow WorkOrders
                unfollows.addAll(entitySubscriptionList);            
            }

            if(unfollows.size()>0){
                delete(unfollows);
            }  
        }      
    }      
}