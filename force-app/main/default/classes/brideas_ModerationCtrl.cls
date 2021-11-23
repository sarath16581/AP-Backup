/**
 * Created by lovandos on 8/23/17.
 */

public with sharing class brideas_ModerationCtrl {
    private static final Integer DEFAULT_ITEMS_PER_PAGE = 5;

    public List<Idea> bannedIdeas {get;set;}
    public List<IdeaComment> bannedIdeaComments {get;set;}
    public String instanceURL {get;set;}
    public String itemId {get;set;}
    public String itemType {get;set;}
    public Integer currentPage {get;set;}
    public Integer itemsPerPage {get;set;}
    public Integer pagesTotal {get;set;}

    public brideas_ModerationCtrl() {
        bannedIdeas = new List<Idea>();
        bannedIdeaComments = new List<IdeaComment>();
        instanceURL = System.URL.getSalesforceBaseURL().toExternalForm();
        itemType = 'Idea post';
        currentPage = 1;
        itemsPerPage = DEFAULT_ITEMS_PER_PAGE;
        pagesTotal = 1;
        retrieveBannedItems();
    }

    public void retrieveBannedItems() {

        if(currentPage > pagesTotal) {
            currentPage = currentPage - 1;
            return ;
        }

        String query = '';
        List<String> bannedItemIds = new List<String>(brideas_Helper.getBannedItemsIds(itemType));

        if(bannedItemIds.isEmpty()) return ;

        if(itemType == 'Idea post') {
            query = 'SELECT Id, Title, CreatedDate, CreatedBy.Id, CreatedBy.Name FROM Idea ' +
                    ' WHERE Id IN (\'' + String.join(bannedItemIds, '\',\'') + '\') ORDER BY CreatedDate DESC';
            query += ' LIMIT ' + itemsPerPage;
            query += (currentPage > 1) ? ' OFFSET ' + String.valueOf(itemsPerPage * (currentPage - 1)) : '';

            bannedIdeas = Database.query(query);

        } else if(itemType == 'Idea comment') {
            query = 'SELECT Id, CommentBody, CreatedDate, CreatedBy.Id, CreatedBy.Name, IdeaId, Idea.Title FROM IdeaComment' +
                    ' WHERE Id IN (\'' + String.join(bannedItemIds, '\',\'') + '\') ORDER BY CreatedDate DESC';
            query += ' LIMIT ' + itemsPerPage;
            query += (currentPage > 1) ? ' OFFSET ' + String.valueOf(itemsPerPage * (currentPage - 1)) : '';

            bannedIdeaComments = Database.query(query);

        } else {
            //unexpected case
        }

        retrieveBannedItemsCount(bannedItemIds);
    }

    public void retrieveBannedItemsCount(List<String> bannedItemIds) {
        String query = '';
        Integer itemsCount = 0;

        if(itemType == 'Idea post') {
            query = 'SELECT COUNT() FROM Idea WHERE Id IN (\'' + String.join(bannedItemIds, '\',\'') + '\')';
            itemsCount = Database.countQuery(query);

        } else if(itemType == 'Idea comment') {
            query = 'SELECT COUNT() FROM IdeaComment WHERE Id IN (\'' + String.join(bannedItemIds, '\',\'') + '\')';
            itemsCount = Database.countQuery(query);

        } else {
            //unexpected case
        }

        if(String.isNotEmpty(query)) {
            itemsCount = Database.countQuery(query);

            if(itemsCount > 0) {

                pagesTotal = Integer.valueOf(Math.ceil(itemsCount/(Double)itemsPerPage));
            }
        }
    }

    public void unbanItem() {
        List<brideas_Banned_Idea_Item__c> bannedItems = [SELECT Id FROM brideas_Banned_Idea_Item__c WHERE Item_Id__c = :itemId AND Type__c = :itemType];

        try {
            delete bannedItems;
        } catch (DmlException e) {
            System.debug(e.getMessage());
            return ;
        }

        refreshBannedItems();
    }

    public void deleteItem() {
        List<SObject> bannedItems = new List<SObject>();

        if(itemType == 'Idea post') {
            bannedItems = [SELECT Id FROM Idea WHERE Id = :itemId LIMIT 1];

        } else if(itemType == 'Idea comment') {
            bannedItems = [SELECT Id FROM IdeaComment WHERE Id = :itemId LIMIT 1];

        } else {
            //unexpected case
        }

        try {
            delete bannedItems;
        } catch (DmlException e) {
            System.debug(e.getMessage());
            return ;
        }

        refreshBannedItems();
    }

    private void refreshBannedItems() {

        List<Idea> bannedIdeasUpdated = new List<Idea>();
        List<IdeaComment> bannedIdeaCommentsUpdated = new List<IdeaComment>();

        if(itemType == 'Idea post') {
            for(Idea i: bannedIdeas) {
                if(String.valueOf(i.Id) != itemId) {
                    bannedIdeasUpdated.add(i);
                }
            }
            bannedIdeas = bannedIdeasUpdated;

        } else if(itemType == 'Idea comment') {
            for(IdeaComment ic: bannedIdeaComments) {
                if(String.valueOf(ic.Id) != itemId) {
                    bannedIdeaCommentsUpdated.add(ic);
                }
            }
            bannedIdeaComments = bannedIdeaCommentsUpdated;

        } else {
            //unexpected case
        }
    }
}