public without sharing class FeedItemQueryUtil {
	
	public static List<FeedItem> queryFileFeedItems(Id parentId) {
		return [SELECT Id, RelatedRecordId, Title, Type, LastModifiedDate, InsertedById, InsertedBy.Name, ContentSize, ParentId 
				FROM FeedItem 
				WHERE ParentId = :parentId AND Type = 'ContentPost' 
				ORDER BY LastModifiedDate DESC];
	}
}