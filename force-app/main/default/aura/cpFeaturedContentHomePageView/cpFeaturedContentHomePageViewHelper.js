({
	fetchFeaturedContents : function(component, pageSize) {
		var action = component.get("c.getFeaturedContents");
        action.setParams({
            "noOfRecordsTofetch" : pageSize
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {                
                var articles = [];
                var fetchedArticles = response.getReturnValue();
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