({
    doInit: function(cmp, event, helper) {
        helper.retrieveIdeasCount(cmp);
        helper.retrieveIdeaCommentsCount(cmp);
        helper.retrieveVotesCount(cmp);
    }
})