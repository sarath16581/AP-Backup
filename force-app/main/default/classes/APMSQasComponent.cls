public with sharing class APMSQasComponent 
{
    // 2014-06 APMS This class and visualforce component ApmsQasComponent
    //          are used to fetch predictive address from QAS.
    //          This class and the VF component is the implementation layer for QAS 
    //          which calls AddressValidation component.
    public AddressExtension currentAddress {get;set;}
    public string qasTypeString {get;set;}

    public List<SelectOption> getStates()
    {
        // this function generates picklist values
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption('', 'Please select'));
        options.add(new selectOption('ACT', 'ACT'));
        options.add(new selectOption('NSW', 'NSW'));
        options.add(new selectOption('NT', 'NT'));
        options.add(new selectOption('QLD', 'QLD'));
        options.add(new selectOption('SA', 'SA'));                
        options.add(new selectOption('TAS', 'TAS'));
        options.add(new selectOption('VIC', 'VIC'));
        options.add(new selectOption('WA', 'WA'));                                
        return options;
    }
    
    public List<SelectOption> getCountries()
    {
        // this function generates picklist values
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption('', 'Please select'));
        options.add(new selectOption('Australia', 'Australia'));
        options.add(new selectOption('Other', 'Other'));        
        return options;
    }   
}