/**************************************************
Type:         Controller for visualforce page bspProfile
History:
--------------------------------------------------
10-08-2020    avula.jansirani@auspost.com.au   Added  @AuraEnabled annatation      
**************************************************/

public with sharing class AddressExtension {
    @AuraEnabled public string line1 {get;set;}
    @AuraEnabled public string line2 {get;set;}
    @AuraEnabled public string city {get;set;}
    @AuraEnabled public string state {get;set;}
    @AuraEnabled public string postcode {get;set;}
    @AuraEnabled public string dpid {get;set;}
    @AuraEnabled  public string country {get;set;}
    @AuraEnabled public string countryName {get;set;}

    public AddressExtension(){
        this.line1 = '';
        this.line2 = '';
        this.city = '';
        this.state = '';
        this.postcode = '';
        this.dpid = '';
        this.countryName = '';
        this.country = '';
    }

    public AddressExtension(string line1, string line2, string city, string state, string postcode, string dpid, string country){
        this.line1 = line1;
        this.line2 = line2;
        this.city = city;
        this.state = state;
        this.postcode = postcode;
        this.dpid = dpid;
        this.countryName = country;
        if(string.isEmpty(country)){
            this.country = 'AU';
        }else{
            if(country.length() > 2){
                this.country = country.substring(0, 2).toUpperCase();
            }else {
                this.country = country.toUpperCase();
            }
        }
    }

}