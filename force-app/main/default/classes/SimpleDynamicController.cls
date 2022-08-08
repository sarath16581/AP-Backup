public class SimpleDynamicController {

    public String recId
	{
		get;
		set
		{
			if (value != null) 
			{
				recId = '';
			}
		}
	}

    private List<InteractionViewRelatedListSettings__c> sortList(List<InteractionViewRelatedListSettings__c> listSettings) {
		List<ComparableSObjectWrapper> wrapperList = new List<ComparableSObjectWrapper>();
		for (InteractionViewRelatedListSettings__c s : listSettings) {
			wrapperList.add(new ComparableSObjectWrapper(s, 'DisplayOrder__c'));
		}
		wrapperList.sort();
		
		List<InteractionViewRelatedListSettings__c> sortedList = new List<InteractionViewRelatedListSettings__c>();
		for (ComparableSObjectWrapper w : wrapperList) {
			sortedList.add((InteractionViewRelatedListSettings__c)w.sObj);
		}
		return sortedList;
	}

    public Component.Apex.OutputPanel getDynamicDetail() {
        Component.Apex.OutputPanel op = new Component.Apex.OutputPanel();

        List<InteractionViewRelatedListSettings__c> listSettings = sortList(InteractionViewRelatedListSettings__c.getAll().values());

        for (InteractionViewRelatedListSettings__c s : listSettings) {
            if (!s.HideList__c) {
                op.childComponents.add(RelatedListComponent.getRelatedList('0030p00000XXTT3', '0030p00000XXTT3', s));
            }
        }
        return op;
    }

    // Just return the first Account, for example purposes only
    public Account acct {
        get { return [SELECT Id, Name, OwnerId FROM Account LIMIT 1]; }
    }
}