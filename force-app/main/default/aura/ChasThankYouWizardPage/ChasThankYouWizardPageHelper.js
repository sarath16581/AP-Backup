({

    /**
     * When the thankyou component needs to pass a custom message to analytics
     * This is used to build the additional attributes that need to be passed.
     */
    buildAdditionalAttributes: function(existingObj, config, component) {
        // example of config:
        // 'analyticsAdditionalAttributes': {
        //      'form.details' : {'enquiry type': 'selectedRadioName'},
        //      'form.referenceId': 'trackingId'
        //  }
        // selectedRadioName <-- v.wizardData.[selectedRadioName]
        // trackingId <-- v.wizardData.[trackingId]
        // etc...

        if(!$A.util.isEmpty(config)) {
            for(var key in config) {
                var value = '';
                var valueMapping = config[key];
                if($A.util.isObject(valueMapping)) {
                    for(var valueMappingKey in valueMapping) {
                        var valueMappingValueMapping = valueMapping[valueMappingKey];
                        var additionalValue = component.get('v.wizardData.' + valueMappingValueMapping);
                        if(!$A.util.isEmpty(additionalValue)) {
                            value += ($A.util.isEmpty(value) ? '' : '|') + valueMappingKey + ':' + additionalValue;
                        }
                    }
                } else {
                    // assumed to be string
                    value = component.get('v.wizardData.' + valueMapping);
                }

                existingObj = this.sliceIn(existingObj, key, value);

            }
        }

        return existingObj;
    },

    /**
     * Recurssively build an object based on dot notation
     */
    sliceIn: function(obj, path, value) {
        var v = path.split('.');
        if(v.length > 1) {
            var zeroElement = v.shift();
            obj[zeroElement] = (obj[zeroElement] ? obj[zeroElement] : {});
            obj[zeroElement] = this.sliceIn(obj[zeroElement], v.join('.'), value);
        } else {
            obj[v[0]] = value;
        }
        return obj;
    },
  
});