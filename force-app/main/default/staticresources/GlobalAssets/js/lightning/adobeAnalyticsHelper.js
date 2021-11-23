/****
 * Helper class to handle communication between <c:adobeAnalyticsInterfaceComponent> and the calling component
 * Usage of this class requires the calling component to register the adobe application event
 * <aura:registerEvent name="adobeAnalyticsInterfaceEvent" type="c:adobeAnalyticsInterfaceEvent"/>
 */
window.AP_ANALYTICS_HELPER = (function() {
    var my = {

        /**
         * Pushes a tracking event to the AdobeAnalyticsInterface if the component has been rendered to the page
         * This will parse the object
         */
        trackByObject: function(params) {
            params.trackingType = (!params.trackingType ? 'site-interact' : params.trackingType);
            my.pushAdobeTrackingEvent(params);
        },

        /**
         * Track an interaction event
         */
        analyticsTrackInteraction: function(trackingType, category, description) {
            my.pushAdobeTrackingEvent({
                trackingType: (!trackingType ? 'site-interact' : trackingType),
                interactionCategory: category,
                interactionDescription: description
            });
        },

        /**
         * Pushes a tracking event to the AdobeAnalyticsInterface with the component.form attributes completed
         */
        analyticsTrackFormAction: function(trackingType, name, step, stage, detail, product, referenceId) {
            my.pushAdobeTrackingEvent({
                trackingType: (!trackingType ? 'site-interact' : trackingType),
                componentAttributes: {
                    form: {
                        name: name,
                        step: step,
                        stage: stage,
                        detail: detail,
                        product: product,
                        referenceId: referenceId
                    }
                }
            });
        },

        /**
         * Pushes a tracking event to the AdobeAnalyticsInterface if the component has been rendered to the page
         */
        pushAdobeTrackingEvent: function(data) {
            var appEvent = $A.get("e.c:adobeAnalyticsInterfaceEvent");
            appEvent.setParams(data);
            appEvent.fire();
        },

        listen: function() {
            document.addEventListener('click', $A.getCallback(function(e) {
                var el = e.target;

                // check whether this element is trackable or not
                if(el.dataset != null && el.dataset.trackable==='true') {
                    var type = el.dataset.trackingType;
                    var category = el.dataset.interactionCategory;
                    var description = el.dataset.interactionDescription;

                    if(!$A.util.isEmpty(type) && !$A.util.isEmpty(category) && !$A.util.isEmpty(description)) {
                        my.pushAdobeTrackingEvent({
                            trackingType: type,
                            interactionCategory: category,
                            interactionDescription: description
                        });
                    }
                }
            }));
        }
    };

    return my;
})();