/**************************************************
Type:         Handles Address QAS functionality
History:
--------------------------------------------------
2019-04-19    nathan.franklin1@auspost.com.au - Added a formSubmitted variable as workaround for server side validation. (A little bit dodgy)
2019-06-17    saiswetha.pingali@auspost.com.au       MW0003497 - Display all countries from Custom setting.
2021-10-05	seth.heang@auspost.com.au    Uplift SF API Version to 52
**************************************************/
public with sharing class bspQasComponent {
	// 2014-06 CCU / BSP This class is copied from AddressComponentV1,
	//    for QAS. AddressComponentV1 has specific CSS styling,
	//    so need to create this replica to start new.
	public AddressExtension currentAddress {
		get {
			if(currentAddress == null) {
				currentAddress = new AddressExtension();
			}
			return currentAddress;
		}
		set;
	}
	public String qasTypeString {get;set;}
	public Boolean formSubmitted {get;set;}

	public List<SelectOption> getCountries() {
		// this function generates picklist values
		List<selectOption> options = new List<selectOption>();
		Map<String, CountryCodes__c> countries = CountryCodes__c.getAll();
		List<String> countryCodes = new List<String>();
		countryCodes.addAll(countries.keySet());
		countryCodes.sort();
		for( String countryCode : countryCodes){
			CountryCodes__c country = countries.get(countryCode);
			options.add(new SelectOption(country.Name,country.Name));
		}
		return options;
	}
}