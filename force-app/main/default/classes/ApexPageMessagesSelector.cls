/* @author Nathan Franklin
 * @date 2020-09-07
 * @group Core
 * @tag ApexPageMessages
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 */
public virtual inherited sharing class ApexPageMessagesSelector extends ApplicationSelector {

    public static ApexPageMessagesSelector newInstance() {
		return (ApexPageMessagesSelector)Application.Selectors.newInstance(ApexPageMessagesSelector.class);
    }
    public List<Apexpages.Message> getPageMessages() {
      return ApexPages.getMessages();
    }
    //This is a dummy value and will not be used 
    public virtual override SObjectType getSObjectType() {
	  	return Opportunity.getSObjectType();
	  }
    //This is a dummy value and will not be used 
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Opportunity.Id,Opportunity.Name,Opportunity.StageName
		};
	}
}