public with sharing class brideas_RelatedIdeasCtrl {
    @AuraEnabled
    public static List<brideas_IdeaWrapper> getRelatedIdeasToIdea(Idea currentIdea) {
        List<brideas_IdeaWrapper> ideasWrapped = new List<brideas_IdeaWrapper>();
        List<Idea> similaIdeas = brideas_Helper.getSimilarIdeas('', currentIdea.Title);
        List<String> ideaIds = new List<String>();

        for(Idea similaIdea: similaIdeas) {
            ideaIds.add(similaIdea.Id);
        }

        Map<String, Integer> ideasVotesNumber = brideas_Helper.getIdeasVotesNumber(ideaIds);

        for(Idea similaIdea: similaIdeas) {
            if(String.valueOf(similaIdea.Id) == currentIdea.Id) continue;

            brideas_IdeaWrapper ideaWrapped = new brideas_IdeaWrapper();
            ideaWrapped.item = similaIdea;

            if(ideasVotesNumber.containsKey(String.valueOf(similaIdea.Id))) {
                ideaWrapped.votesNum = ideasVotesNumber.get(String.valueOf(similaIdea.Id));
            }

            ideasWrapped.add(ideaWrapped);
        }

        return ideasWrapped;
    }

}