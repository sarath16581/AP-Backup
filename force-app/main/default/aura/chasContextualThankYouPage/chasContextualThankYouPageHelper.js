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
    convertDateToLocaleString : function(component,dt) {
        var dtString = dt.toLocaleString("en-US", {weekday: 'short'}) + ' ' + dt.toLocaleString("en-US", {day: 'numeric'}) + ' ' +dt.toLocaleString("en-US", {month:'short'});
        return dtString;
    },

    /**
     * DDS-5820: retrieve configuration for next steps
     * @param {*} component
     * @returns: next steps configuration
     */
    retrieveNextStepsConfigurations : function(component)
    {
        // start spinner
        component.set('v.loading', true);

        // infer page variation
        let mtdGroup = this.pageVariation(component);

        // store value for other reasoning
        component.set('v.pageVariation', mtdGroup);

        // retrive next steps metadata
        let nextStepMetadataRetriever = component.get('c.getNextStepMetadata');
        nextStepMetadataRetriever.setParams({
            mtdGroup
        });
        nextStepMetadataRetriever.setCallback(this, function(response) {
            // stop spinner
            component.set('v.loading', false);
            
            let status = response.getState();
            if (status === 'SUCCESS')
                component.set('v.nextStepsConfiguration', this.processNextStepConfiguration(component, response.getReturnValue()));
            else
                console.log('retrieve metadata error', response.getError());
        });
        $A.enqueueAction(nextStepMetadataRetriever);
    },

    /**
     * DDS-5820: reasoning to get corresponding next steps metadata group
     * @param {*} component
     * @returns: next steps metadata group
     */
    pageVariation: function(component)
    {
        let mtdGroup = '';
        let isDeliveredScan = !$A.util.isEmpty(component.get('v.wizardData.latestDeliveredScanWcid'));
        let isSafeDrop = component.get('v.wizardData.hasCustomerSeenSafeDrop') === 'true'? true : false;
        let isPastEddPlusBusinessDays = component.get('v.wizardData.isEnquiryDatePastEDDPlusBusinessdays');
        let isWithinEddPlusBusinessDays = component.get('v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays');
        let isWithinEdd = component.get('v.wizardData.isEnquiryDateWithinEDD');
        let isNoEddReturned = component.get('v.wizardData.isNoEddReturned');
        let containsPharma = component.get('v.wizardData.selectedRadio4Name');
        // DDS-5272, 5273: different header for pharma and NO EDD variations
        let header = isNoEddReturned || containsPharma == 'Yes' ? "We've received your enquiry" : component.get('v.header');
        
        // DDS-6707: set expectedDeliveryText for isWithinEdd and isWithinEddPlusBusinessDays 
        let expectedDeliveryText = isWithinEdd ? $A.get('$Label.c.withinEDDText') : isWithinEddPlusBusinessDays ? $A.get('$Label.c.withinEDDPlusBusinessDaysText') : "" ;
        component.set('v.expectedDeliveryText',expectedDeliveryText);
        
        // no EDD returned -- DDS-5272
        isNoEddReturned && (mtdGroup = 'noEDD');

        // article is not yet delivered & enquiry date is within EDD + n days
        !isDeliveredScan && isPastEddPlusBusinessDays && (mtdGroup = 'nextStepsPastEDDPlusBusinessDays');

        // article is not yet delivered & enquiry date is past EDD + n days
        !isDeliveredScan && !isPastEddPlusBusinessDays && isWithinEddPlusBusinessDays && (mtdGroup = 'nextStepsWithinEDDPlusBusinessDays');

        // article is within EDD -- DDS-5269
        !isDeliveredScan && !isPastEddPlusBusinessDays && !isWithinEddPlusBusinessDays && isWithinEdd && (mtdGroup = 'withinEDD');

        // article is delivered & customer hasn't seen safe drop
        isDeliveredScan && !isSafeDrop && (mtdGroup = 'nextStepsDelivered');
        
        // article is delivered & customer seen safe drop
        isDeliveredScan && isSafeDrop && (mtdGroup = 'nextStepsSafeDropDelivered');
        
        // article contains essential pharma items
        containsPharma == 'Yes' && (mtdGroup = 'nextStepsContainsPharma');
        
        // set header accordingly 
        component.set('v.header', header);

        return mtdGroup;
    },

    /**
     * DDS-5820: process retrieved metadata into consumable configuration
     * @param {*} component
     * @param {*} response: response from metadata retrieving
     * @returns: next steps configuration
     */
    processNextStepConfiguration : function(component, response)
    {
        // safe escape
        if(!response)
            return [];

        // process metadata into consumable configuration
        let configuration = [];
        response.forEach(meta => {
            configuration.push({
                id : meta.Step_ID__c,
                label : this.replaceAnchorString(component, meta.Label__c),
                image : meta.Image__c,
                sublabel : this.replaceAnchorString(component, meta.Sub_Label__c),
            })
        })
        return configuration;
    },

    /**
     * DDS-5820: replace anchor string with actual value
     * @param {*} component
     * @param {*} text: text to replace
     * @returns: replaced text
     */
    replaceAnchorString : function(component, text)
    {
        // safe escape
        if ($A.util.isEmpty(text))
            return text;
        
        let regex = new RegExp('\\{!(.*?)\\}','g');
        let allMatches = text.match(regex) || [];
        for (let anchorString of allMatches)
        {
            let actualValue = component.get(anchorString.substring(2, anchorString.length - 1)) || '';  // strip the {!} part
            text = text.replace(anchorString, actualValue);
        }
        return text;
    },
})