/* created by CV of Aus Post on 31.11.11
 * purpose of trigger is to check inbound Lead and if Lead has lead source that is a campaign name, then link via a new campaign member record.
 * this saves relying on users creating leads to also perform this step
 * Richard Clarke 2013-03-13 corrected defect which was attempting to add a campaign member for as many as there were active campaigns resulting in too many DML statement exception
 *
 * @changelog
 * 2021-08-11 - Seth Heang - Uplift API version to 52
*/
trigger updateLeadTrigger on Lead (after insert) {
    List<Campaign> cList = new List<Campaign>([Select id, Name from Campaign where IsActive = true]);
    Map<String,id> campMap = new Map<String,id>();
    List<CampaignMember> cMember = new List<CampaignMember>();
    // Create a map of campaign name to campaign id
    for(Campaign c : cList) { 
        campMap.put(c.Name, c.id);
    }
    if(cList.size() != 0) {
        // For each lead which has a lead source defined attempt to find a campaign with a matching name
        for(Lead l : trigger.new){
            if((String.isBlank(l.LeadSource) == false ) && campMap.containsKey(l.LeadSource)) {
                cMember.add(new CampaignMember(CampaignId = campMap.get(l.LeadSource), LeadId = l.id));
            }
        }
        Database.SaveResult[] result = Database.insert(cMember,false); // allow for partial insert - errors will be attempted duplicates which we can ignore.
    }
}