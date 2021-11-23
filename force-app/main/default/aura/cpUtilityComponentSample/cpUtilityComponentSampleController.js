/**************************************************
Description:
History:
--------------------------------------------------
2018-05-18  nathan.franklin@auspost.com.au  Created
**************************************************/
({
    loadFieldLabels: function(cmp, ev, helper) {
		var utility = cmp.find('utility');
		var loader = cmp.find('loader');
		utility.getSObjectFieldLabels(['Account.Name', 'Contact.FirstName'], function(result) {
		    var labels = [];
		    var keys = Object.keys(result);
		    for(var i=0;i<keys.length;i++) {
		    	labels.push({fieldName: keys[i], label: result[keys[i]]});
      		}
			cmp.set('v.labels', labels);
  		}, function(error) {}, loader);
    },

    loadPicklistValues: function(cmp, ev, helper) {
		var utility = cmp.find('utility');
		var loader = cmp.find('loader');

		// returns a Map<String, Map<String, String>>
		// convert this into arrays so it can be used by an aura iterator
		utility.getSObjectFieldPicklistValues(['Account.Type'], function(result) {
		    // process the response
		    //	formatted: { 'Account.Type' : { 'key name' : 'value' }, ... }
		    var picklistValues = [];
		    var keys = Object.keys(result);
		    for(var i=0;i<keys.length;i++) {
		        var picklistValue = {fieldName: keys[i], values: []};
		        var valueKeys = Object.keys(result[keys[i]]);
		        for(var a=0;a<valueKeys.length;a++) {
					picklistValue.values.push({key: valueKeys[a], value: result[keys[i]][valueKeys[a]]});
          		}
          		picklistValues.push(picklistValue);
      		}
			cmp.set('v.picklistValues', picklistValues);
  		}, function(error) {}, loader);
	}
})