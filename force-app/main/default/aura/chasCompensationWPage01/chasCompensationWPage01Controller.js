({
    doInit : function(component, event, helper)
    {
        // display header
        component.set('v.wizardData.showHeaderForCompensationForm', true);

        // get compensation
        helper.retrieveCompensation(component);
    },

    onScreen4 : function(component, event, helper)
    {
        
        let isScreen4 = component.get('v.screen4');
        let nextStepsConfiguration = component.get('v.nextStepsConfiguration');

        // safe escape
        if (!isScreen4)
            return;

        // prevent duplicate serve trip
        if (!$A.util.isEmpty(nextStepsConfiguration))
            return;
        
        // get next step configurations
        helper.retrieveNextStepsConfiguration(component);
    },

    checkBeforeNext : function(component, event, helper)
    {
        // reset the error summary to prevent dilluting
        helper.clearErrorPanel(component);

        let haveRequiredInput = helper.checkPresentOfData(component);
        let correctDataFormat = helper.checkDataFormat(component);

        // fire missing field analytic event if checking is failed
        let currentPage = component.get('v.currentPage');
        if (!haveRequiredInput)
        {
            if (currentPage === 1)
            {
                helper.registerMixAnalyticsEvent(component, {form : 'page1_missing_field', interact : 'page1_and_2_button_continue'});
            }
            else if(currentPage === 2)
            {
                helper.registerMixAnalyticsEvent(component, {form : 'page2_missing_field', interact : 'page1_and_2_button_continue'});
            }
        }

        // fire incorrect format analytic event if checking is failed, if input is already identified with missing value, no need to fire invalid format event
        if (haveRequiredInput && !correctDataFormat)
        {
            if (currentPage === 1)
            {
                helper.registerMixAnalyticsEvent(component, {form : 'page1_invalid_field_format', interact : 'page1_and_2_button_continue'});
            }
            else if(currentPage === 2)
            {
                helper.registerMixAnalyticsEvent(component, {form : 'page2_invalid_field_format', interact : 'page1_and_2_button_continue'});
            }
        }

        if (!haveRequiredInput || !correctDataFormat)
        {
            helper.bringErrorsToSurface(component);
            return;
        }

        // check left attemps
        if (!helper.checkAttemps(component))
        {
            helper.registerMixAnalyticsEvent(component, {form : 'page1_out_of_attemps', interact : 'page1_and_2_button_continue', trackingType : 'helpsupport-form-navigate'});
            return;
        }

        if (!helper.innocent(component))
        {
            helper.registerMixAnalyticsEvent(component, {form : 'page1_bot_detected', interact : 'page1_and_2_button_continue', trackingType : 'helpsupport-form-navigate'});
            return;
        }
        
        // transaction data against master data
        if (helper.checkTransactionData(component))
        {
            if (currentPage === 1)
            {
                helper.registerMixAnalyticsEvent(component, {form : 'page1_clear_error', interact : 'page1_and_2_button_continue'});
            }
            else if(currentPage === 2)
            {
                helper.registerMixAnalyticsEvent(component, {form : 'page2_clear_error', interact : 'page1_and_2_button_continue'});
            }
            
            $A.enqueueAction(component.get('c.next'));
        } else
        {
            helper.increaseAttemps(component);
        }
    },

    next : function(component, event, helper)
    {
        let currentPage = component.get('v.currentPage');

        // clear error panel
        helper.clearErrorPanel(component);

        currentPage = currentPage + 1;
        component.set('v.currentPage', currentPage);
    },

    prev : function(component, event, helper)
    {
        let currentPage = component.get('v.currentPage');
        
        // clear error panel
        helper.clearErrorPanel(component);
        
        if (currentPage === 2)
        {
            helper.registerMixAnalyticsEvent(component, {form : 'page2_clear_error', interact : 'page2_button_back'});
        }
        else if(currentPage === 3)
        {
            helper.registerAnalyticsEvent(component, 'page3_button_edit');
        }

        currentPage = currentPage - 1;
        component.set('v.currentPage', Math.max(1, currentPage));
    },

    pageFlip : function(component, event, helper)
    {
        let currentPage = component.get('v.currentPage');
        helper.flipToPage(component, currentPage);
    },

    handleCompactSwitch : function(component, event, helper)
    {
        let name = event.currentTarget.name;
        let compacts = component.get('v.compacts');
        let fullText = compacts[name]['full'];
        let shortText = compacts[name]['short'];
        let expanded = compacts[name]['expanded'];

        if (expanded)
        {
            compacts[name]['display'] = shortText;
        }
        else
        {
            compacts[name]['display'] = fullText;
        }
        
        compacts[name]['expanded'] = !expanded;
        
        component.set('v.compacts', compacts);
    },

    commitAndNext : function(component, event, helper)
    {
        helper.registerAnalyticsEvent(component, 'page3_button_confirm');
        helper.commitAndNext(component, event);
    },

    /**
     * intermedia to fire analytic event after setTimeOut
     * @param {*} component 
     * @param {*} event 
     * @param {*} helper 
     */
    handlePendingQueueMessages : function(component, event, helper)
    {
        helper.handleQueueMessages(component);
    }
})