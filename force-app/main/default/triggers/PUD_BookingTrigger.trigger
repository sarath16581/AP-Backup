/*Trigger to create jobs on the creation and update of a booking
History:
15/10/2019  ajudd@salesforce.com    Added set of Legacy Id
21/11/2019  ajudd@salesforce.com    Added set of Revenue Check
26/11/2019  ajudd@salesforce.com    Added set of Route from Booking Location
02/12/2019  dheeraj.mandavilli@auspost.com.au Added set of Stop Credit 
05/12/2019  ajudd@salesforce.com	Update to default of depot - only trigger on insert and simplify code
21/01/2020  dheeraj.mandavilli@auspost.com.au Added set of Key Number
18/03/2020  dheeraj.mandavilli@auspost.com.au Added If condition on Booking Type to populate Revenue Check Field
2021-09-29 - Ranjeewa Silva - Populate additional address fields (frontage geocode and side of street) onto booking when location is updated.

-------------------------  
*/
trigger PUD_BookingTrigger on PUD_Booking__c (before insert, before update, after insert, after update) {
    
    if(Trigger.isBefore){
        
        if(Trigger.isUpdate || Trigger.isInsert){
            
            //Initialise network id (to store default depot)
            Id DefaultDepotNetworkId = null;
            
            //If record creation - get user's default depot from public group
            if(Trigger.isInsert){
            
                /*get default Network Depot for current user from Public group in which he is member Start */
                String currentUserId = UserInfo.getUserId();
                List<GroupMember> groupMemberList = new List<GroupMember>();
                
                //get public group members for current user
                groupMemberList = [SELECT Group.Name FROM GroupMember WHERE UserOrGroupId=:currentUserId];
                    
                Set<String> groupNameSet = new Set<String>();
                
                //loop trough the Public groups to get group name set
                for(GroupMember objCGM : groupMemberList){
                    groupNameSet.add(objCGM.Group.Name);
                }
                
                //If user belongs to groups
                if(groupNameSet.size() > 0){
                    //get any networks with the same name as the group name
                    List<Network__c> networkList =[SELECT Id,Name FROM Network__c WHERE Name IN : groupNameSet];
                    
                    //if there is one, get the first and assign it to Booking by storing in a variable
                    if(networkList.size()>0){                        
                        DefaultDepotNetworkId = networkList[0].Id;
                    }
                }
            }//end get default depot
            
            for(PUD_Booking__c booking : Trigger.New){ 
                
                //##Set Search and other reference fields## - Note these fields also used as common fields on booking to populate job
                //If booking new and location is set, or updated and location changed
                //Also set Customer
                if((Trigger.isInsert && booking.Booking_Location__c != null) || 
                   (Trigger.isUpdate && Trigger.oldMap.get( booking.Id ).Booking_Location__c != booking.Booking_Location__c)){
                       //Then update search location and address field to those from new location
                       booking.Street__c = booking.Booking_Location_Street__c;
                       booking.City__c = booking.Booking_Location_City__c;
                       booking.Post_Code__c = booking.Booking_Location_Post_Code__c;
                       booking.State__c = booking.Booking_Location_State__c;
                       booking.Location__c = booking.Booking_Location_Name_LU__c;
                       booking.Customer__c = booking.Booking_Location_Customer__c;
                       booking.Network__c = booking.Booking_Location_Network__c;
                       booking.Geo__Latitude__s = booking.Booking_Location_Latitude__c;
                       booking.Geo__Longitude__s = booking.Booking_Location_Longitude__c;
                       booking.LEGACY_ID__c = booking.LEGACY_ID_FX__c;
                       booking.Billing_Account__c = booking.Booking_Location_Billing_Account__c;
                       // add code here
                       if(booking.Booking_Type__c != 'Delivery'){
                          booking.Revenue_Check__c = booking.Booking_Location_Revenue_Check__c; 
                       }
                       booking.Stop_Credit__c = booking.Booking_Location_Stop_Credit__c;
                       booking.Key_Number__c = booking.Location_Key_Number__c;
                       
                       
                       //If the route is not set, then set as the route on the location
                       if(booking.Route_Lookup__c == null){
                       		booking.Route_Lookup__c = booking.Booking_Location_Route__c;
                       }
                       
                       //If the depot is not set, then set as the network id (users default depot from logic above)
                       if(booking.Depot__c == null){
                          	booking.Depot__c = DefaultDepotNetworkId;
                       }

                       booking.Frontage_Geo__Latitude__s = booking.Booking_Location_Frontage_Latitude__c;
                       booking.Frontage_Geo__Longitude__s = booking.Booking_Location_Frontage_Longitude__c;
                       booking.DPID__c = booking.Booking_Location_DPID__c;
                       booking.Side_Of_Street_Code__c = booking.Booking_Location_Side_Of_Street_Code__c;
                   }
            }   
        }
    } 
    
    if(Trigger.isAfter){
        
        if(Trigger.isUpdate || Trigger.isInsert){
            
            //Call method to refresh jobs impacted by change to booking
            PUD_BookingUtil.refreshJobs(Trigger.oldMap, Trigger.New, Trigger.isUpdate);
        }
    }
}