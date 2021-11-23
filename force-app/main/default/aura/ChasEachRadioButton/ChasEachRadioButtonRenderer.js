/**************************************************
 Description: Customer renderer to apply data attributes to the created element

 History:
 --------------------------------------------------
 2019-09-09  nathan.franklin@auspost.com.au  Created
 **************************************************/
({
    afterRender: function(component, helper) {
        this.superAfterRender();

        // apply any data attributes to the radio button that were passed in via the 'dataset' property
        var el = component.find('radioBtn').getElement();
        var dataset = component.get('v.dataset');
        if(!$A.util.isEmpty(dataset)) {
            var datasetKeys = Object.keys(dataset);
            for(var i=0;i<datasetKeys.length;i++) {
                el.setAttribute('data-' + datasetKeys[i], dataset[datasetKeys[i]]);
            }
        }
    }
})