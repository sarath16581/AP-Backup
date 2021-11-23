public with sharing class AddressComponentV1Controller {
	AddressExtension currentAddress = null;
	public AddressExtension getCurrentAddress() {
		if(currentAddress == null) 
			currentAddress = new AddressExtension('', '', '', '', '', '', ''); 
		return currentAddress;
	}
	public void setCurrentAddress(AddressExtension addr) {currentAddress = addr;}
	
}