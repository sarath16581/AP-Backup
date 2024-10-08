public with sharing class ApplicationFlowEmailTypeObjectCollection {
    
	@AuraEnabled
	public String objectType;

	@AuraEnabled
	public List<ApplicationFlowEmailType> emailNotifications;

	public ApplicationFlowEmailTypeObjectCollection(String objectType) {
		this.objectType = objectType;
		this.emailNotifications = new List<ApplicationFlowEmailType>();
	}

	public void addFlowEmailType(ApplicationFlowEmailType emailNotification) {
		this.emailNotifications.add(emailNotification);
	}
	
}