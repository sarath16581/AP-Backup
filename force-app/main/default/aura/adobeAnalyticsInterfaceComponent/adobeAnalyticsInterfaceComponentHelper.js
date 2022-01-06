/**************************************************
 Description: Component for handling Adobe Analytics integration

 History:
 --------------------------------------------------
 2019-08-27  nathan.franklin@auspost.com.au  Created
 2021-09-09  phap.mai@auspost.com.au         Added: DDS-7455 - for compensation form, when the stage is error related, get the error attribute from the detail attribute. The changes and more details on lines begin with [DDS-7455] tag.
 **************************************************/
({
    /**
     * Stores all the mappings of attribute name to component.x analytics structure
     */
    pageViewKeyMappings: {
        'pageViewFormName': 'form.name',
        'pageViewFormStep': 'form.step',
        'pageViewFormStage': 'form.stage',
        'pageViewFormError': 'form.error',
        'pageViewFormDetail': 'form.detail',
        'pageViewFormProduct': 'form.product',
        'pageViewFormReferenceId': 'form.referenceId'
    },

    queuedMessages: [],

    /**
     * Queue all messages until we have processed our server callouts
     */
    queueMessage: function(component, helper, message) {
        if(!component.get('v.isLoaded')) {
            this.queuedMessages.push(message);
        } else {
            // once all server callouts have been processed we call push directly to skip the queueing process
            this.pushMessage(component, message);
        }
    },

    /**
     * Call by controller once all data has loaded to push any queued messages
     */
    handleQueue: function(component, helper) {
        this.queuedMessages.forEach(function(item) {
            helper.pushMessage(component, message);
        });
        this.queuedMessages = [];
    },

    /**
     * Method will make the callout to adobe.
     *
     * Message:
     * {
     *      type,
     *      interactionCategory,
     *      interactionDescription,
     *      attributes <- .components
     * }
     *
     */
    pushMessage: function(component, message) {

        // referenced from global namespace defined outside the lightning component (usually community HEAD directive)
        analytics.page.pageData.sitePrefix = component.get('v.sitePrefix');
        analytics.page.pageData.pageAbort = 'true';

        if(!$A.util.isEmpty(message.interactionCategory)) {
            analytics.page.pageData.interactionCategory = message.interactionCategory;
        } else {
            delete analytics.page.pageData.interactionCategory;
        }

        if(!$A.util.isEmpty(message.interactionDescription)) {
            analytics.page.pageData.interactionDescription = message.interactionDescription;
        } else {
            delete analytics.page.pageData.interactionDescription;
        }

        if(analytics.user == null) analytics.user = {};
        if(analytics.user.userData == null) analytics.user.userData = {};

        if(component.get('v.trackCommunityLoggedInStatus')) {
            analytics.user.userData.loginStatus = (component.get('v.isLoggedIn') ? 'authenticated' : 'anonymous'); //For users in logged in state
        } else {
            delete analytics.user.userData.loginStatus;
        }
        if(component.get('v.trackCommunityLoggedInAPCN')) {
            analytics.user.userData.apcn = component.get('v.apcn');
        } else {
            delete analytics.user.userData.apcn;
        }

        // [DDS-7455] if compensation form has error, grab the error attribute to be equal detail attribute since the AP_ANALYTICS_HELPER library do not support error parameter
        let isPageMeasurementErrorEvent = component.get('v.isPageMeasurementErrorEvent');

        if(isPageMeasurementErrorEvent)
        {
            message.attributes['form']['error'] = message.attributes['form']['detail'];
            delete message.attributes['form']['detail'];
            delete message.attributes['form']['stage'];

            // set back error flag to false for next round of event
            component.set('v.isPageMeasurementErrorEvent', false);
        }
        
        
        // if attributes is not set then the previous component data structure that was used is used for this request.
        analytics.component = message.attributes || {};

        console.log('Pushing Analytics Event >> ', message.type, message, JSON.parse(JSON.stringify(analytics)));

        _satellite.track(message.type);
    },

    /**
     * Build a list of attributes to send via a page view tracking
     */
    getAnalayticsComponentAttributes: function(component) {
        var output = {};
        for(var key in this.pageViewKeyMappings) {
            var value = component.get('v.' + key);
            var mapping = this.pageViewKeyMappings[key];
            output = this.sliceIn(output, mapping, value);
        }
        return output;
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
    }
});