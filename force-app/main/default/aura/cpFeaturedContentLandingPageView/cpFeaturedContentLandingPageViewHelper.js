({
	fetchFeaturedContents : function(component, pageSize) {
        var recordCount = pageSize+1;
		var action = component.get("c.getFeaturedContents");
        action.setParams({
            "noOfRecordsTofetch" : recordCount
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                var contents = [];
                var resultLength = result.length;
                if(resultLength > pageSize){
                    resultLength = resultLength -1;
                }
                
                for(var idx=0; idx <resultLength; idx++){
                    contents.push(result[idx]);
                }
                component.set("v.cpCurrentPageSize", pageSize);
                
                if(result.length <= pageSize){
                    var cmpTarget = component.find('viewMoreButton');
        			$A.util.addClass(cmpTarget, 'slds-hide');
                }
                
                var articles = [];
                var fetchedArticles = result;
                for (var index in fetchedArticles) {
                    var article = {};
                    article.idx = fetchedArticles[index].Id;
                    article.routeInput = {recordId: fetchedArticles[index].Id};
                    article.content = fetchedArticles[index].Content__c;
                    article.contentText = fetchedArticles[index].ContentText__c;
                    articles.push(article);
                } 
                component.set('v.articles', articles);
            }
        });
        $A.enqueueAction(action);
	}
})