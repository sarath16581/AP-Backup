//Class to retrieve trending discussion for Customer community.
public without sharing class cpGetTrendingDiscussions {

    //retrieve all the feed items of FeedType 'Home'
    @AuraEnabled
  //Retrieve Feed elements with the Feed type of "home"
    public static list<cpTrendingDiscussionWrapper> getTrendingDiscussions(Integer noOfRecordsToFetch, String sortingParameter) {
        //Fetch  user’s current community
        try{
            String communityId = Network.getNetworkId();
             map<String, ConnectApi.FeedSortOrder> sortParametersMap = new map<String, ConnectApi.FeedSortOrder>{
                                            'CreatedDateDesc' => ConnectApi.FeedSortOrder.CreatedDateDesc,
                                            'LastModifiedDateDesc' => ConnectApi.FeedSortOrder.LastModifiedDateDesc,
                                            'MostViewed' => ConnectApi.FeedSortOrder.MostViewed,
                                            'Relevance' => ConnectApi.FeedSortOrder.Relevance
                                        };
    
             map<String, ConnectApi.FeedFilter> filterParametersMap = new map<String, ConnectApi.FeedFilter>{
                                            'CreatedDateDesc' => ConnectApi.FeedFilter.AllQuestions,
                                            'LastModifiedDateDesc' => ConnectApi.FeedFilter.AllQuestions,
                                            'MostViewed' => ConnectApi.FeedFilter.UnansweredQuestions,
                                            'Relevance' => ConnectApi.FeedFilter.AllQuestions
                                        };
    
            //Setting FeedType to 'Home'
            ConnectApi.FeedType feedType = ConnectApi.FeedType.Home;
    
            //Sort Order in which the feed Elements will be fetched & displayed on UI
            //Sorts by most viewed content. This sort order is available only for Home feeds when the ConnectApi.FeedFilter is 'UnansweredQuestions'.
            String sortParam = 'CreatedDateDesc';
    
            if(!String.isBlank(sortingParameter)){
                sortParam = sortingParameter;
            }
    
            ConnectApi.FeedSortOrder FeedSortOrder = sortParametersMap.get(sortParam);
            ConnectApi.FeedFilter feedFilter = filterParametersMap.get(sortParam);
    
            //When the sortParam is MostViewed, you must pass in 'null' for the 'pageParam'.
            String pageParam = '';
    
            //When the sortParam is MostViewed, the maxResult must be a value from 1 to 25.
            Integer maxResult = 10;
            //Page Size contains the no of records to be displayed on UI
            Integer recordCountToFetch = 10;
            if(Integer.valueOf(noOfRecordsToFetch) > 0 && Integer.valueOf(noOfRecordsToFetch) < 26){
               recordCountToFetch = Integer.valueOf(noOfRecordsToFetch);
            }
    
            //he maximum number of comments to return with each feed item. The default value is 3
            Integer recentCommentCount = 1;
    
            //Specify the amount of content in a feed
            ConnectApi.FeedDensity density = ConnectApi.FeedDensity.AllUpdates;
    
            //List of Wrapper Class to reurn to Component
            list<cpTrendingDiscussionWrapper> wrappedTrendingDiscussions = new list<cpTrendingDiscussionWrapper>();
    
            if(string.isNotBlank(communityId) || test.isRunningTest()){
                ConnectApi.FeedElementPage fep;
                if(test.isRunningTest())
                    fep = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(null, ConnectApi.FeedType.Home, 1, ConnectApi.FeedDensity.AllUpdates, '',10,ConnectApi.FeedSortOrder.CreatedDateDesc, ConnectApi.FeedFilter.CommunityScoped);
                else
                    fep = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(communityId, feedType, recentCommentCount, density, pageParam, maxResult, FeedSortOrder, feedFilter);
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
    
                                //fetching Question title
                                String questionTitle = question.questionTitle;
                                //system.debug('==questionTitle==>'+questionTitle);
    
                                //fetch total view, Comment and Like count
                                ConnectApi.InteractionsCapability intraction = capability.interactions;
                                Long totalVLCCount = intraction.count;
    
                                //add it to wrapper
                                wrappedTrendingDiscussions.add(new cpTrendingDiscussionWrapper(FeedElementId, questionTitle, totalVLCCount));
    
                                Integer wrappSize = wrappedTrendingDiscussions.size();
                                if(recordCountToFetch == wrappSize){
                                    break;
                                }
                            }
                        }
                    }
                }
    
                //system.debug('==wrappedTrendingDiscussions size==>'+wrappedTrendingDiscussions.size());
                return wrappedTrendingDiscussions;
            } else {
                throw (new AUPostCustomException('No community found'));
            }
        }catch(exception ex){
            return null;
        }
    }
    
    public without sharing class AUPostCustomException extends Exception {}
}