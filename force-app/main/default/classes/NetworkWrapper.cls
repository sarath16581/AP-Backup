public without sharing class NetworkWrapper {
	public Network__c network {get;private set;}
	public integer openCases {get;set;}
	public integer closedCases {get;set;}
	public integer outstandingResponseDays {get;set;}
	public List<Network__c> fromByPasses {get;private set;}
	public List<Network__c> toByPasses {get;private set;}
	
	public NetworkWrapper(Network__c network){
		this.network = network;
		fromByPasses = new List<Network__c>();
		toByPasses = new List<Network__c>();
		openCases = 0;
		closedCases = 0;
		outstandingResponseDays = 0;
	}
}