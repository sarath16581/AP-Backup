trigger SocialPostUpdateCase on SocialPost (after insert, after update) {
 
 	/*
 	/* trigger will update fields on Case object as necessary when Social Post is received */
 	/* Created: 4/30/15 by Joanne Hicks 
 	*/
 
	Set<Id> caseIds = new Set<Id>();
	
	//build list of Case Ids
	For (SocialPost sp : trigger.new) {
		If (sp.parentId != null && sp.isOutbound==false)
			caseIds.add(sp.parentId);
	}
	
	// query those cases if in 'On Hold' status
	List<Case> cases = [select Id, Status from Case where id in :caseIds and status = 'On Hold'];
	
	for (Case c : cases) {
		
	 	  	  c.Status = 'Customer Responded';
	}
	  
	if (cases.size() > 0)
		update cases;
}