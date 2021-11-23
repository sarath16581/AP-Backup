//Class to retrieve chatter feeds used by component in customer community.
public without sharing class cpGetChatterFeeds {
    
    //retrieve all the feed items of FeedType 'Home' 
    @AuraEnabled
    //Get chatter feeds
    public static list<cpChatterFeedWrapper> getFeedElements(Integer noOfRecordsToFetch) { 
        try{
            //Fetch  user’s current community
            String communityId = Network.getNetworkId();
            //system.debug('==communityId==>'+communityId);
           
            //Setting FeedType to 'Home' 
            ConnectApi.FeedType feedType = ConnectApi.FeedType.Home;
            
            //page token to use to view the page. If 'null', the first page is returned
            String pageParam = '';
            String tempNickName = null;
            
            //Valid values are from 1 through 100. If you pass in null, the default size is 25.
            Integer maxResult = 100;
            //recordCountToFetch contains the no of records to be displayed on UI
            Integer recordCountToFetch = 25;
            if(Integer.valueOf(noOfRecordsToFetch) > 0 && Integer.valueOf(noOfRecordsToFetch) < 101){
                recordCountToFetch = Integer.valueOf(noOfRecordsToFetch);
            }        
                    
            //Sort Order in which the feed Elements will be fetched & displayed on UI
            ConnectApi.FeedSortOrder FeedSortOrder = ConnectApi.FeedSortOrder.CreatedDateDesc;
            //Set of User Id to fetch User Nickname from User record
            set<String> userIds = new set<String>();
            //Map to contain User Id vs User Record 
            map<Id, user> usermap = new map<Id, user>();
            //List of Wrapper Class to reurn to Component
            list<cpChatterFeedWrapper> wrappedChatterFeed = new list<cpChatterFeedWrapper>();
              
            if(string.isNotBlank(communityId) || test.isRunningTest()){
                ConnectApi.FeedElementPage fep;
                if(test.isRunningTest())
                    fep = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(null, ConnectApi.FeedType.Home, ' ', 10, ConnectApi.FeedSortOrder.CreatedDateDesc);
                else 
                    fep = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(communityId, feedType, pageParam, maxResult, FeedSortOrder);
                List<ConnectApi.FeedElement> feedElements = fep.elements;
                //system.debug('==feedElements size==>'+feedElements.size());
                if(feedElements.size() > 0){
                    for(ConnectApi.FeedElement feedelement : feedElements){
                        ConnectApi.FeedElementCapabilities capability = feedelement.capabilities;
                        if(capability != null){
                            ConnectApi.QuestionAndAnswersCapability question = capability.questionAndAnswers;
                            //system.debug('==question==>'+question);
                            if(question != null) {
                                //Fetch FeedElement Id
                                String FeedElementId = feedelement.Id;
                                
                                //fetch Best Answer Id
                                ConnectApi.Comment bestAnswer = question.bestAnswer;
                                //system.debug('==bestAnswer==>'+bestAnswer);
                                //Initialising Best Answer Id
                                String bestAnswerId = '';
                                if(bestAnswer != null){
                                    bestAnswerId = bestAnswer.Id;
                                    ConnectApi.FeedBody bestAnswerBody = bestAnswer.body;
                                    //system.debug('==bestAnswerBody text==>'+bestAnswerBody.text);
                                }
                                
                                //fetching Question title
                                String questionTitle = question.questionTitle;
                                if(questionTitle.length() > 48){
                                    questionTitle = questionTitle.substring(0, 47) +'...';
                                }
                                //system.debug('==questionTitle==>'+questionTitle);
                                
                                //fetch total view, Comment and Like count
                                ConnectApi.InteractionsCapability intraction = capability.interactions;
                                Long totalVLCCount = intraction.count;
                                
                                //fetch total Comment count
                                ConnectApi.CommentsCapability comment = capability.comments;
                                ConnectApi.CommentPage comentPage = comment.page;
                                Long commentCount = comentPage.total;
                                
                                //Fetch Relative createdDate
                                String relativeCreatedDate = feedelement.relativeCreatedDate;
                                ConnectApi.ActorWithId parentContent = feedelement.parent;
                                
                                //fetch User Id To retrieve Nickname from User
                                String actorId ='';
                                if(test.isRunningTest())
                                    actorId = userInfo.getUserId();
                                else 
                                    actorId = parentContent.Id; 
                                
                                if(actorId.startsWith('005')){
                                    userIds.add(actorId);
                                }
                                
                                //Initialised with null. Later will be populated with User Profile image URL
                                String smallIconUrl = '';
                                
                                //setting Nickname to blank
                                String actorNickName = '';
                                
                                //add it to wrapper 
                                wrappedChatterFeed.add(new cpChatterFeedWrapper(FeedElementId, questionTitle, smallIconUrl, actorId, actorNickName, relativeCreatedDate, totalVLCCount, commentCount, bestAnswerId));
                                
                                //Check to return list of size equal to the page Size as for loop iterates for Max Size defined
                                Integer wrappedChatterFeedSize = wrappedChatterFeed.size();
                                if(recordCountToFetch == wrappedChatterFeedSize){
                                    Break;
                                }
                            }
                        }
                    }
                }
                
                //Fetching User nickName from User Id
                if(userIds.size() > 0){
                    usermap  = new map<Id, user>([Select Id, Name, SmallPhotoUrl, CommunityNickname From User Where Id IN: userIds]);
                }
                    
                //adding User Nickname
                if(!usermap.isEmpty() && wrappedChatterFeed.size() > 0){
                    for(cpChatterFeedWrapper feedWrapper : wrappedChatterFeed){
                        if(usermap.containsKey(feedWrapper.actorId)){
                            tempNickName = usermap.get(feedWrapper.actorId).CommunityNickname;
                            if(tempNickName.length() > 11){
                                    feedWrapper.actorNickName = tempNickName.substring(0, 11) +'...';
                                }
                            else{
                                 feedWrapper.actorNickName = tempNickName;
                            }
                            feedWrapper.imageIconUrl = usermap.get(feedWrapper.actorId).SmallPhotoUrl;
                        }
                    }
                }
                
                //system.debug('==wrappedChatterFeed size==>'+wrappedChatterFeed.size());
                return wrappedChatterFeed;
            } else {
                throw (new AUPostCustomException('No community found')); 
            }
        } catch(exception ex){
            return null;
        }
    }
    
    public without sharing class AUPostCustomException extends Exception {}
}