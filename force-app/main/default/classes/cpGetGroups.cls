//Class to retrieve chatter group for lightning component used in customer community
public without sharing class cpGetGroups {
    
    @auraEnabled
    //Get chatter group
    public static list<cpChatterGroupWrapper> getCommunityGroups(String noOfRecordsToFetch, String groupVisibility){
        try{
            //Fetch  user current community
            String communityId = Network.getNetworkId();
            
            map<String, ConnectApi.GroupVisibilityType> groupVisibilityMap = new map<String, ConnectApi.GroupVisibilityType> {
                                                                        'Private groups' => ConnectApi.GroupVisibilityType.PrivateAccess,
                                                                        'Public groups' => ConnectApi.GroupVisibilityType.PublicAccess,
                                                                        'Unlisted groups' => ConnectApi.GroupVisibilityType.UnlistedAccess
                                                                    };
            
            //The number of the page to return. Starts at 0. If you pass in null or 0, the first page is returned.
            Integer pageParam = 0;
            
            //The number of items per page. Valid values are from 1 through 100. If you pass in null, the default size is 25.
            Integer maxResult = 100;
            //Page Size contains the no of records to be displayed on UI
            Integer recordCountToFetch = 10;
            if(Integer.valueOf(noOfRecordsToFetch) > 0 && Integer.valueOf(noOfRecordsToFetch) < 101){
               recordCountToFetch = Integer.valueOf(noOfRecordsToFetch);
            }
            
            //list to contain wrapped group informations
            list<cpChatterGroupWrapper> chatterGroupList = new list<cpChatterGroupWrapper>();
            
            // Create a list of groups.
            if(String.isNotBlank(communityId) || test.isRunningTest()){
                ConnectApi.ChatterGroupPage groupPage;
                if(!test.isRunningTest())
                    groupPage = ConnectApi.ChatterGroups.getGroups(communityId, pageParam, maxResult);
                else 
                    groupPage = ConnectApi.ChatterGroups.getGroups(null, 0, 5);
                if(groupPage.groups != null){
                    for (ConnectApi.ChatterGroup aGroup : groupPage.groups){
                        if(!String.isBlank(aGroup.id)){
                            //check visibility
                            ConnectApi.GroupVisibilityType visibility = aGroup.visibility;
                            if(groupVisibility != 'all groups' && groupVisibilityMap.containsKey(groupVisibility) &&  visibility == groupVisibilityMap.get(groupVisibility)){
                                //Group member count
                                Integer groupMemberCount = aGroup.memberCount;
                                //group Name
                                String groupName = aGroup.Name;
                                //system.debug('==GroupName=>'+groupName);
                                //group Description
                                String groupDescription = aGroup.description;
                                //group Image url
                                ConnectApi.Photo photo = aGroup.photo;
                                String smallPhotoUrl = photo.smallPhotoUrl;
                                //lastFeedElementPostDate 
                                String lastFeedElementPostDate = (aGroup.lastFeedElementPostDate).format('dd MMMM yyyy \'at\' h:mm a');
                                //Add group to wrapper
                                chatterGroupList.add(new cpChatterGroupWrapper(aGroup.id, groupMemberCount, groupName, groupDescription, smallPhotoUrl, lastFeedElementPostDate));
                                
                                Integer groupSize = chatterGroupList.size();
                                if(recordCountToFetch == groupSize){
                                    break;
                                }
                            } else if(groupVisibility == 'All groups'){
                                //display all groups
                                //Group member count
                                Integer groupMemberCount = aGroup.memberCount;
                                //group Name
                                String groupName = aGroup.Name;
                                //system.debug('==GroupName=>'+groupName);
                                //group Description
                                String groupDescription = aGroup.description;
                                //group Image url
                                ConnectApi.Photo photo = aGroup.photo;
                                String smallPhotoUrl = photo.smallPhotoUrl;
                                //lastFeedElementPostDate 
                                String lastFeedElementPostDate = (aGroup.lastFeedElementPostDate).format('dd MMMM yyyy \'at\' h:mm a');
                                //Add group to wrapper
                                chatterGroupList.add(new cpChatterGroupWrapper(aGroup.id, groupMemberCount, groupName, groupDescription, smallPhotoUrl, lastFeedElementPostDate));
                                
                                Integer groupSize = chatterGroupList.size();
                                if(recordCountToFetch == groupSize){
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            return chatterGroupList;
        }catch(exception ex){
            return null;
        }
    }
    
    //Method to retrieve Coversation Id from Custom setting to navigate to detail page
    @AuraEnabled
    //Get chatter group redirect list view Id
    public static String getConversationSettings(){
        try{
            Community_Settings__mdt communitySettingMetadata = [SELECT DeveloperName,Entity_Name__c,Entity_Value__c 
                                                                FROM Community_Settings__mdt 
                                                                WHERE DeveloperName = 'Community_Conversation_Detail' LIMIT 1];
    
            String conversationId = communitySettingMetadata.Entity_Value__c;
            
            if (string.isBlank(conversationId))
                conversationId = '';
            
            if (conversationId == null ) {
                return 'set the Id parameters for Navigation to Conversation detail page';
            }
                    
            return (conversationId).trim();
        } catch(exception ex){
            return null;
        }
    }
}