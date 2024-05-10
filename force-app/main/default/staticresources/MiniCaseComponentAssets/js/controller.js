/**
 * @author Nathan Franklin
 * @date
 * @changelog
 * 2020-04-10  nathan.franklin@auspost.com.au  Removed code duplication for case creation
 * 2020-10-05 - Disha Kariya - Allow safe drop attachment for case creation
 * 2020-10-12 - Ranjeewa Silva - Pass additional parameters to happy parcels to enable DTN case creation.
 * 2021-10-10 - Nathan Franklin - Change safedrop logic to delivery proof and fixed attachment bug
 */
var frontendMiniCaseComponentController = (function() {
    'use strict';

    var CORS_MESSENGER = new window.AP_CORS_MESSENGER();

    //const
    var DEFAULT_SYNC_CONTEXT = 'NoContext';

    var j$ = jQuery.noConflict();

    var model = new localState();

    var my = {

        initialize: function() {

            // happy haprcel initialisers
            model.set('hpCaseOriginator', 'Customer');
            model.set('hpSenderDetails', {});
            model.set('hpReceiverDetails', {});
            model.set('hpLodgementDate', null);
            model.set('hpSelectedArticles', []);
            model.set('hpQueuedItem', '');
            model.set('hpInitialised', false);
            model.set('hpDeliveryProofImage', []);

            // listen for the Happy Parcels component initiailisation event
            // this is necessary because HP is loaded in an IFRAME to get around CSS style leakage from the parent Visualforce page.
            // we need this because if the component hasn't initialised yet, it won't start receiving tracking numbers to search for.
            // lightningOut may take a little while to initialise. I have observed it sometimes taking 4-6 seconds, but usually around 1 to 2 seconds
            CORS_MESSENGER.get(document.getElementById('hpWindow').contentWindow, 'lightningComponentInitialised', function() {
                console.log('hpInitialised');
                model.set('hpInitialised', true);

                // if there is already a queued item then process it and remove it from the queue
                if(model.get('hpQueuedItem')) {
                    // fire a call to happy parcels component to trigger a search
                    CORS_MESSENGER.push(document.getElementById('hpWindow').contentWindow, 'setLightningAttribute', model.get('hpQueuedItem'));

                    model.set('hpQueuedItem', '');
                }
            });

            // used to determine when to show and hide the waiting icon
            model.set('waitQueueCount', 0);
            model.set('currentTabId', null);

            // this is used to set a param after the window has fully initialised
            // for code clarity and structure, this is placed here and then used within registerSelfSynchronisationEvents.
            // if we wait to add the window.load event listener in registerSelfSynchronisationEvents, it may have already fired, hence why we do it here
            model.set('isWindowLoaded', false);
            j$(window).load(function() {
                model.set('isWindowLoaded', true);
            });

            // this determines which panels are allowed to be synchronised
            my.setMiniCaseContext().then(function() {
                console.log('MiniCaseComponentController syncContext:', model.get('syncContext'));

                // monitor changes to dom
                my.wireEvents();

                // why??
                my.clearMiniCaseErrorPanel();

                // get the current tab id if one exists
                sforce.console.getEnclosingPrimaryTabId(function(currentTabResult) {
                    if(currentTabResult.success) {
                        model.set('currentTabId', currentTabResult.id);
                        //<-- PPE: 15-04-2024
                        localStorage.setItem(
                            `CTI_${currentTabResult.id}`,
                            JSON.stringify({
                                ...model.vars,
                                _timeStamp : new Date().getTime()
                            })
                        );
                        //PPE -->
                    }
                });
            });
        },

        /**
         * Monitor DOM actions
         */
        wireEvents: function() {
            // wire up console event monitoring to keep field values in sync with other panels.
            sforce.console.addEventListener('MiniCaseFieldSet', my.miniCaseFieldValueChanged);

            // dynamically add console event monitoring for all the fields we are tracking in the mini console search
            // this is to catch any minicase messages like MiniCaseFieldSet_ProductCategory__c
            // these messages are generated when a value needs to be updated across other instances of the mini case, for example:
            //		1. When a picklist value on the UI is selected (push that value to other instances of minicase)
            //		2. When CTI received specific field values from Genesys (push that value to other instances of minicase)
            if(j$.isArray(model.get('fields'))) {
                for(var i=0;i<model.get('fields').length;i++) {
                    sforce.console.addEventListener('MiniCaseFieldSet_' + model.get('fields')[i], (function(field) {
                        return function(result) {
                            my.miniCaseFieldValueChanged(field, result.message);
                        }
                    })(model.get('fields')[i]));
                }
            }

            // convert the referenceId field to uppercase
            if(j$('.MiniCaseFieldSet_ReferenceID__c').length > 0) {
                j$('.MiniCaseFieldSet_ReferenceID__c').on('input', function() {
                    var selectionStart = this.selectionStart;
                    var selectionEnd = this.selectionEnd;
                    this.value = this.value.toUpperCase();
                    this.selectionStart = selectionStart;
                    this.selectionEnd = selectionEnd;
                });
            }

            // when a tab is change check to see whether a query should be exectued
            sforce.console.addEventListener('PrimaryTabChanged', my.setCurrentPrimaryTab);

            // other event listeners
            sforce.console.addEventListener('ShowEDDTab', my.showEDDTab);
            sforce.console.addEventListener('UpdateMiniCaseRecordTypeID', my.updateMiniCaseRecordTypeId);

            // used to setup the messages for receiving synchronised values in bulk
            // (such as the result of RequestValues being fires and receiving a SynchronisedValues message in return)
            my.registerSelfSynchronisationEvents();

            // monitor for when the current primary tab window is closed
            // if there is a specific context to this window (specifically a chat context),
            // 		then we need to broadcast this message to remove the state storage of the values in QuickLinksFooterPanel
            // TODO, this will cause an event to fire multiple times when multiple instances are loaded under the same primary tab.
            // TODO, while this carries no impact it should be fixed at some point.
            sforce.console.getEnclosingPrimaryTabId(function (primaryTabResult) {
                if(primaryTabResult.id) {
                    // add an event listener specific for the current primary tab this instance is loaded in.
                    sforce.console.addEventListener(sforce.console.ConsoleEvent.CLOSE_TAB, function(result) {
                        var syncContext = model.get('syncContext');
                        var chatKey = model.get('chatKey');
                        if(syncContext !== DEFAULT_SYNC_CONTEXT && !my.isEmpty(chatKey)) {
                            // dispatch a message to QuickLinksFooterPanel which will remove all the stored data in memory for this context
                            sforce.console.fireEvent('MiniCaseStorageDestroyContext', syncContext);
                        }
                    }, { tabId : primaryTabResult.id });
                }
            });

            // add a monitor to received changes to the height of the happy parcel window.
            CORS_MESSENGER.setHeightPullMonitor(document.getElementById('hpWindow'));

            // monitor when we received proxied events from Lightning Wrapper.
            CORS_MESSENGER.get(document.getElementById('hpWindow').contentWindow, 'lightningEvent', my.handleHappyParcelLightningEvent);

            j$(document).on('click', '#trackOnlineLink', my.openTrackInNewTab);
        },

        /**
         * This is the callback for anytime a lightning event is generated for Happy Parcel
         * This is handled via the CORS_MESSENGER event proxy which allows 2 way communication between the lightning component and this visualforce
         */
        handleHappyParcelLightningEvent: function(e) {
            console.log('Happy Parcel Lightning Event', e);

            if(e && e.detail && e.type === 'selectedarticles') {
                // this is used to track which articles are selected when viewing a consignment
                // the mini case capability allows for multiple child case creation under the primary case for all articles selected
                // one exception to this rule is when there is only 1 case selected, that tracking id becomes the primary case without any additional child case.
                model.set('hpSelectedArticles', e.detail);
            } else if(e && e.detail && e.type === 'externaledd') {
                // the user clicked the 'Calculate' button inside Happy Parcel
                my.showEDDTab({ message: JSON.stringify({ SenderPostcode: e.detail.senderPostCode, ReceiverPostcode: e.detail.receiverPostCode, SentDate: e.detail.lodgementDate }) });
            } else if(e && e.type === 'customerdetails' && e.detail) {
                // after an article returns search results
                // the customer details event is dispatched which contains all the details related to the sender/receiver
                if(e.detail.type === 'sender') {
                    model.set('hpSenderDetails', e.detail);
                } else if(e.detail.type === 'receiver') {
                    model.set('hpReceiverDetails', e.detail);
                }
            } else if(e && e.type === 'customerselect' && e.detail) {
                // a customer details panel was selected.
                // this sets the case originator
                if(e.detail.type === 'sender') {
                    model.set('hpCaseOriginator', 'Sender');
                } else if(e.detail.type === 'receiver') {
                    model.set('hpCaseOriginator', 'Addressee');
                }
            } else if(e && e.type === 'customerdeselect' && e.detail) {
                // a customer details panel was deselected
                // NOTE: a deselect event is NOT fired when the panel's selected property is being set to false as the result of the other panel's selected property being set to true
                // Reset the case originator back to it's default value
                model.set('hpCaseOriginator', 'Customer');
            } else if(e && e.type === 'trackingsearchcomplete' && e.detail) {
                var syncContext = model.get('syncContext');

                // after a tracking search has been completed in Happy Parcel, it will generate this event and pass through the correct case clearview code mappings based on the product returned in the search
                // this is used to simply default the values to improve accuracy of the product category mappings
                if(e.detail.type) {
                    console.log('Setting type field: ', e.detail);
                    my.miniCaseFieldValueChanged('Type__c', JSON.stringify({syncContext: syncContext, value: e.detail.type}));
                }
                if(e.detail.productCategory) {
                    console.log('Setting productCategory field: ', e.detail);
                    my.miniCaseFieldValueChanged('ProductCategory__c', JSON.stringify({syncContext: syncContext, value: e.detail.productCategory}));
                }
                if(e.detail.productSubCategory) {
                    console.log('Setting productSubCategory field: ', e.detail);
                    my.miniCaseFieldValueChanged('ProductSubCategory__c', JSON.stringify({syncContext: syncContext, value: e.detail.productSubCategory}));
                }

                // default the enquiry sub type field if it's parcels or letters based
                if(e.detail.productCategory === 'Domestic Parcels' || e.detail.productCategory === 'Domestic Letters') {
                    my.miniCaseFieldValueChanged('EnquirySubType__c', JSON.stringify({syncContext: syncContext, value: 'Tracking'}));
                } else if(e.detail.productCategory === 'International Parcels' || e.detail.productCategory === 'International Letters') {
                    my.miniCaseFieldValueChanged('EnquirySubType__c', JSON.stringify({syncContext: syncContext, value: 'Inbound tracking'}));
                }

                // this is the ArticleLodgementDate__c from the queried article
                if(e.detail.lodgementDate) {
                    model.set('hpLodgementDate', e.detail.lodgementDate);
                }

                // reset delivery proof variable to ensure we don't inadvertently attach delivery proof if its not intended
                model.set('hpDeliveryProofImage', []);
            } else if(e && e.detail && e.type === 'idclick' && e.detail.id) {
                // this occurs if a link is clicked in Happy Parcel that requires a record page to be opened
                sforce.console.openPrimaryTab(null, '/' + e.detail.id, true);
            } else if(e && e.detail && e.type === 'attachdeliveryproof') {
                var deliveryProofAttach = model.get('hpDeliveryProofImage');
                deliveryProofAttach = (deliveryProofAttach ? deliveryProofAttach : []);
				if(e.detail.selected === true) {
                    deliveryProofAttach.push(e.detail.trackingId);
					model.set('hpDeliveryProofImage', deliveryProofAttach);
				} else if(e.detail.selected === false) {
                    deliveryProofAttach = deliveryProofAttach.filter(function(item) { return item !== e.detail.trackingId });
					model.set('hpDeliveryProofImage', deliveryProofAttach);
				}
            }
        },

        /**
         * This sets a context of which minicasecomponents can communicate with this mini case.
         * Only mini case components with the same context can communicate with each other.
         * All other messages received from other contexts will be ignored.
         */
        setMiniCaseContext: function() {
            model.set('syncContext', DEFAULT_SYNC_CONTEXT);
            model.set('chatKey', '');

            var def = j$.Deferred();

            // sforce.console.chat.getDetailsByPrimaryTabId does not fire is user is not a live agent user
            // this will ensure the promise always resolves.
            if(model.get('isLiveAgentUser')) {
                sforce.console.getEnclosingPrimaryTabId(function(tabResult) {
                    if(tabResult.success === true) {
                        sforce.console.chat.getDetailsByPrimaryTabId(tabResult.id, function (result) {
                            if (result.success) {
                                model.set('syncContext', result.details.chatKey);
                                model.set('chatKey', result.details.chatKey);
                                //j$('#chatkey').text(result.details.chatKey);
                            }

                            // always resolve
                            def.resolve();
                        });
                    } else {
                        // always resolve
                        def.resolve();
                    }
                });
            } else {
                def.resolve();
            }

            return def.promise();
        },

        registerSelfSynchronisationEvents: function() {

            // receive the RequestValues results which are requested when the component is initially loaded
            // this is a 1 time only thing
            sforce.console.addEventListener(model.get('pageId') + '_SynchronisedValues_OnLoad', function(result){
                console.log('> ' + model.get('pageId') + '_SynchronisedValues_OnLoad <');
                my.setupValues(result);

                // if values have been passed to this instance then check to see if a query needs to be made.
                my.maybeDoActionLoaders();
            });

            // this is received when an entire set of synchronised values is pushed out from QuickLinksFooterPanel
            // the only time this happens is when a clear is fired (RequestValues is fired with a param of 'clear')
            sforce.console.addEventListener('SynchronisedValues', my.onSynchronisedValues);

            // whenever a new instance of this component is created, it sends a request to get the existing values in the workspace
            // these values are stored in QuickLinksFooterPanel and will trigger a return event (model.get('pageId') + '_SynchronisedValues_OnLoad') with the current values.
            // we use window onload event to ensure the native picklist4.js file has initialised prior to requesting values.. else the dependent fields wont work.
            var maybeWindowLoaded = function() {
                // make sure the window loaded param is set before sending request values
                // this is set in the initialise where the window.load is monitored.
                if(!model.get('isWindowLoaded')) {
                    setTimeout(maybeWindowLoaded, 100);
                    return;
                }

                //add the chat key into message for future checking
                var objMessage = {
                    syncContext: model.get('syncContext'),
                    message: model.get('pageId')
                };
                var message = JSON.stringify(objMessage);

                // fire event off to QUickLinksFooterPanel so it sends the current stored values
                sforce.console.fireEvent('RequestValues', message);
            };

            maybeWindowLoaded();
        },

        /**
         * This is called when the SynchronisedValues message is received
         * Currently, the only use case for this is when the event RequestValues is fired with a param of 'clear'
         */
        onSynchronisedValues: function(result) {
            my.setupValues(result);

            // if values have been passed to this instance then check to see if a query needs to be made.
            my.maybeDoActionLoaders();
        },

        /**
         * This is fired when onchange event handlers are triggered for the mini case interface fields
         * in MiniCaseComponent.component: onchange="(function(e, el){miniCasePageController.inputChangeHandler(e, '{!f.fieldPath}', el)})(event, this);" />
         */
        inputChangeHandler: function(e, field, el) {
            // check if this change event was created directly from jQuery (jQuery framework sets the isTrigger value)
            // if it is we don't fire another synchronise message
            if(!e.isTrigger) {
                // this will fire a messages subch as: MiniCaseFieldSet_Type_and_Product__c and will include this instances context (NoContext / chat key / etc...) and the value of the field
                miniCasePageController.fireSynchroniseEvent(field, el);

                // hide any errors that were previously shown as a result of any failures
                miniCasePageController.clearMiniCaseErrorPanel();
            }
        },

        /**
         * Fired when a minicase field on the UI has changed.
         * This is the result of inputChangeHandler being fired when the user changes a UI field from the interface (not when triggering a .change() in code)
         */
        fireSynchroniseEvent: function(fieldPath, el) {
            var $el = j$(el);

            //add the chat key into message for future checking
            var objMessage = {
                value: $el.val(),
                syncContext: model.get('syncContext')
            };
            var message = JSON.stringify(objMessage);

            console.log('>> fireSynchroniseEvent', fieldPath, message);

            // This will send an event to keep all the other instances of this component in sync.
            // as long as the other panels are in the same syncContext
            // This is also caught by QuickLinksFooterPanel and stored for the next time an instance with the same context is open and a RequestValues is fired
            sforce.console.fireEvent('MiniCaseFieldSet_' + fieldPath, message);

        },

        /**
         * Whenever a monitored field's synchronise event is fired (example: MiniCaseFieldSet_ProductCategory__c), we catch it here and process it
         * This occurs from events such as MiniCaseFieldSet_ProductCategory__c (proxied) and the event MiniCaseFieldSet
         * NOTE:
         * 	This message is also caught by the same instance that fired the message to begin with
         */
        miniCaseFieldValueChanged: function(field, message) {

            var obj = my.safeParseJSON(message);
            var syncContext = DEFAULT_SYNC_CONTEXT; // <-- by default the message is from NoContext unless otherwise specified
            var value = '';
            if(typeof obj === 'object') {
                value = obj.value;
                syncContext = (obj.hasOwnProperty('syncContext') ? obj.syncContext : syncContext);
            } else {
                value = obj;
            }

            // ignore this message if the context if not the same as the context set in this instance
            if(syncContext !== model.get('syncContext'))
                return;

            //console.log('>> miniCaseFieldValueChanged', model.get('syncContext'), syncContext, value, field, model.get('isWindowLoaded'));

            // each element is rendered as either a select, an input or a textarea.
            // this makes sure we can grab any regardless of field type.
            var $el = j$('.wrapper_MiniCaseFieldSet_' + field).find('select, input, textarea');
            $el.val(value);
            $el.change();

            // this will ensure the Type_and_Product__c field is set to the correct value
            // the Type_and_Product__c field is combination between Type|ProductCategory|ProductSubCategory and is the controlling field for EnquirySubType__c
            // no values will be available in the EnquirySubType__c picklist until the Type_and_Product__c field is set.
            if(field !== 'Type_and_Product__c') {
                my.setJoinPicklist();
            }

            if(field === 'Type') {
                if(value === 'General Enquiry') {
                    j$('[id$="btnCloseEnquiry"]').show();
                    j$('[id$="btnCreateCase"]').hide();
                } else {
                    j$('[id$="btnCreateCase"]').show();
                    j$('[id$="btnCloseEnquiry"]').hide();
                }
            }

            // check whether or not a query for cases/sapEM should be triggerred
            my.maybeDoActionLoaders();
        },

        /**
         * Whenever a mini case field value is changed, we need to make sure the hidden Type_and_Product__c field is set correctly
         * This field is the controlling field for EnquirySubType__c which means it needs to be set so EnquirySubType__c can be populated with the right picklist values
         */
        setJoinPicklist: function() {
            var type = j$('.wrapper_MiniCaseFieldSet_Type select').val();
            var productCategory = j$('.wrapper_MiniCaseFieldSet_ProductCategory__c select').val();
            var productSubCategory = j$('.wrapper_MiniCaseFieldSet_ProductSubCategory__c select').val();
            var value = type + '|' + productCategory + '|' + productSubCategory;

            // this will trigger the EnquirySubType__c field to be populated with a list of dependent values from the Type_and_Product__c field
            j$('.wrapper_MiniCaseFieldSet_Type_and_Product__c select').val(value);
            j$('.wrapper_MiniCaseFieldSet_Type_and_Product__c select').change();
        },

        // /**
        //  * This is used only for HLC customers. A buttons on the error dialogs to invoke this function
        //  * This bypasses any duplicate checking
        //  */
        // jAddCase: function(el, closeEnquiry) {
        //     var previousText = j$(el).val();
        //     j$(el).val("Processing...");
        //     j$(el).attr("disabled", "disabled");
        //     var chatKey = model.get('chatKey');
        //
        //     my.clearMiniCaseErrorPanel();
        //     if(my.isPageValid()) {
        //         miniCaseShowProgress();
        //         window.console&&console.log('############################ creating case #############################');
        //
        //         var json = my.getFieldsAndValuesAsJSON();
        //         window.console&&console.log(json);
        //
        //         var articles = [];
        //         if(typeof window.TIBCOTrackingResult_getAllSelectedArticles == 'function'){
        //             articles = TIBCOTrackingResult_getAllSelectedArticles();
        //         }
        //         var articlesJSON = JSON.stringify(articles);
        //         window.console&&console.log(json);
        //
        //         window.console&&console.log('######################## sending to controller ##########################');
        //         // remote action
        //         MiniCaseComponentController.createCase(chatKey, json, closeEnquiry, articlesJSON,
        //             function(result, event) {
        //                 console.log('---------------------- response from controller -------------------------');
        //                 window.console&&console.log(event);
        //                 window.console&&console.log(result);
        //                 if (result != null) {
        //                     if(result.indexOf("Duplicate") == 0) {
        //                         my.showPopup(closeEnquiry);
        //                     }
        //                     else if(result.indexOf("Error:") == 0) {
        //                         my.showMiniCaseErrorPanel(result);
        //                     } else {
        //                         my.clearMiniCase();
        //                         my.closePopup();
        //                         sforce.console.openPrimaryTab(null,'/' + result, true);
        //                     }
        //                 }
        //
        //                 my.miniCaseHideProgress();
        //
        //                 j$(el).val(previousText);
        //                 j$(el).removeAttr("disabled", "disabled");
        //             }
        //         );
        //     } else {
        //         my.showMiniCaseErrorPanel('Please enter all fields highlighted in red.');
        //         j$(el).val(previousText);
        //         j$(el).removeAttr("disabled", "disabled");
        //     }
        // },

        /**
         * This is used only when agent are in HLC queues. In this scenario, a button will be displayed on the duplicate case error popup and will allow a HLC agent to still create a case and ignore the duplicate case warning
         */
        createCaseWithoutDuplicateCheck: function(el, closeEnquiry) {
            my.createCase(el, closeEnquiry, true);

            // close the popup after the case has been created
            my.closePopup();
        },

        /**
         * Create a new case
         */
        createCaseWithDuplicateCheck: function(el, closeEnquiry) {
            my.createCase(el, closeEnquiry, false);
        },

        createCase: function(el, closeEnquiry, ignoreDuplicate) {
            var previousText = j$(el).val();
            j$(el).val("Processing...");
            j$(el).attr("disabled", "disabled");
            var chatKey = model.get('chatKey');
            my.clearMiniCaseErrorPanel();
            if(my.isPageValid()) {
                miniCaseShowProgressTop();

                window.console&&console.log('############################ creating case #############################');
                console.log('##json##'+json);
                var json = my.getFieldsAndValuesAsJSON();
                window.console&&console.log(json);

                // the mini case capability allows for multiple child case creation under the primary case for all child articles selected when viewing a consignment
                // one exception to this rule is when there is only 1 case selected, that tracking id becomes the primary case without any additional child case.
                var articles = model.get('hpSelectedArticles');
                console.log('articls:', articles);
                var safedrop = model.get('hpDeliveryProofImage');
                var safedropJSON = JSON.stringify(safedrop);
                // if(typeof window.TIBCOTrackingResult_getAllSelectedArticles == 'function'){
                //     articles = TIBCOTrackingResult_getAllSelectedArticles();
                // }
                var articlesJSON = JSON.stringify(articles);
                window.console&&console.log(json);

                window.console&&console.log('######################## sending to controller ##########################');
                // apex remote action
                MiniCaseComponentController.createCase(chatKey, json, closeEnquiry, articlesJSON, ignoreDuplicate, safedropJSON,
                    function(result, event) {
                        console.log('---------------------- response from controller -------------------------');
                        window.console&&console.log(event);
                        window.console&&console.log(result);
                        if (result != null) {
                            if(result.indexOf("Duplicate") == 0) {
                                my.showPopup(closeEnquiry);
                            }
                            else if(result.indexOf("Error:") == 0) {
                                my.showMiniCaseErrorPanel(result);
                            } else {
                                my.clearMiniCase();

                                // if this window is in a live chat context then we need to open this window as a subtab to the live chat window.
                                // if it's not then we open in a primary tab
                                if(!my.isEmpty(model.get('chatKey'))) {
                                    sforce.console.getEnclosingPrimaryTabId(function(res) {
                                        sforce.console.openSubtab(res.id, '/' + result, true);
                                    });
                                }else{
                                    sforce.console.openPrimaryTab(null,'/' + result, true);
                                }

                            }
                        }
                        miniCaseHideProgressTop();

                        j$(el).val(previousText);
                        j$(el).removeAttr("disabled", "disabled");
                    }
                );
            } else {
                my.showMiniCaseErrorPanel('Please enter all fields highlighted in red.');
                j$(el).val(previousText);
                j$(el).removeAttr("disabled", "disabled");
            }
        },

        isPageValid: function(){
            var result = true;
            j$('.flaggedAsRequired').each(function(index){
                //window.console && console.log(j$(this));

                if(j$(this).val() == null || j$(this).val().trim() == '' ){
                    result = false;
                }
            });
            var p = my.getFieldSetFieldsAndValues();
            console.log('--p--'+p.Type +p.ProductCategory__c+p.ProductSubCategory__c+p.EnquirySubType__c);
            if (p.Type == null || p.Type__c == '' || p.ProductCategory__c == null || p.ProductCategory__c == '' || p.ProductSubCategory__c == null ||
                p.ProductSubCategory__c == '' || p.EnquirySubType__c == null || p.EnquirySubType__c == '') {
                result = false;
            }

            console.log('result'+result);
            return result;
        },

        /**
         * Is called from QuickLinksFooterPanel (through an event) after a primary tab change event occurs.
         */
        setCurrentPrimaryTab: function() {
            my.maybeDoActionLoaders();
        },

        /**
         * Check whether or not a request should be sent to the server for a SAPEM search or case search
         */
        maybeDoActionLoaders: function() {
            // We only want to do this search if this instance is in the current tab (where possible)
            // An exception to this is the SSSWSearch tab which does not fire a primary tab change
            sforce.console.getFocusedPrimaryTabId(function(focusedTabResult) {
                // either no tab is exposed or we are on the current tab
                if(model.get('currentTabId') == null && focusedTabResult.success) {
                    // this little delay here is for the inactive 'navigation tab window' that holds an instance of the MiniCaseComponent
                    // we make sure that the inactive navigation tab MiniCaseComponent delays it's SAPEM search to minimise lock and duplicate errors
                    // focusedTabResult.success will be true if the user is viewing an actual tab which means we can safely put a delay in here for the navigation tab
                    // NOTE: model.get('currentTabId') == null means this is the MiniCaseComponent instance loaded in the navigation tab (without a tab id)
                    // NOTE: This whole synchronisation 'feature' needs to be rewritten and will be as a part of the lightning uplift.
                    //          This should suffice for now.
                    console.log('Delaying action loaders on inactive navigation tab');
                    setTimeout(function() {
                        my.doActionLoaders();
                    }, 1000);
                } else if(model.get('currentTabId') == null || (focusedTabResult.success && focusedTabResult.id == model.get('currentTabId'))) {
                    my.doActionLoaders();
                }
            });
        },

        /**
         * final check before sending a request to the server
         */
        doActionLoaders: function() {
            var values = my.getFieldSetFieldsAndValues();
            var productCategory = values.ProductCategory__c;
            var productSubCategory = values.ProductSubCategory__c;
            var referenceId = values.ReferenceID__c;
            var enquiryType = values.Enquiry_Type__c;
            var enquirySubType = values.EnquirySubType__c;
            var caseType = values.Type;
            var complaint = values.Complaint__c;
            var contactId = values.ContactId;

            // make sure we should actually call the sap em function
            if(j$.inArray(productCategory, ['International Letters', 'Domestic Letters', 'International Parcels', 'Domestic Parcels']) > -1 &&
                referenceId != null && referenceId.trim() != '') {

                // only call if we haven't already called and the right parameters match
                if(model.get('currentSAPEMReferenceId') != referenceId || j$.inArray(model.get('currentProductCategory'), ['International Letters', 'Domestic Letters', 'International Parcels', 'Domestic Parcels']) == -1) {
                    console.log('Performing SAPEM Search', referenceId, productCategory);

                    model.set('currentSAPEMReferenceId', referenceId);
                    model.set('currentProductCategory', productCategory);

                    // my.showLoadProgress();
                    //
                    // // this requires us to invoke SAPEM and perform an article search
                    // loadSAPEM(referenceId);

                   // Parameters passed into Happy Parcels. Mini case contextual information is included in 'hostContext'
                   // parameter.
                    var hpParams = {
                        trackingId: referenceId,
                        hostContext: {
                            productCategory: productCategory,
                            productSubCategory: productSubCategory,
                            caseType: caseType,
                            enquirySubType: enquirySubType,
                            complaint: complaint,
                            contactId: contactId
                        }
                    };

                    // Given happy parcels is loading inside an IFRAME, by the time this is called, the IFRAME may not have been initialised yet.
                    // If thats the case then, we need to 'queue' a call up to be executed after Happy Parcels is fully loaded.
                    // This is a bit of a hack mixing lightning with classic
                    if(model.get('hpInitialised')) {
                        // fire a call to happy parcels component to trigger a search
                        CORS_MESSENGER.push(document.getElementById('hpWindow').contentWindow, 'setLightningAttribute', hpParams);
                    } else {
                        model.set('hpQueuedItem', hpParams);
                    }
                }
            }

            // make sure we should case the load related cases
            if(referenceId != null && referenceId.trim() != '' && model.get('currentCaseReferenceId') != referenceId) {
                console.log('Performing Case Search', referenceId);

                model.set('currentCaseReferenceId', referenceId);

                my.showLoadProgress();

                // if the reference isn't empty and we haven't already sent a request to the server to search for this reference
                // we send a request to pull back all the related cases
                loadRelatedCases(referenceId);
            }
        },

        /**
         * This is used by CTIListener2 Page... but I'm not sure if it's used in that components.... to clarify...
         */
        updateMiniCaseRecordTypeId: function(result){
            //window.console&&console.log('############# UpdateMiniCaseRecordTypeID: ' + result.message);

            var tempLists = picklist.picklists;
            for(var picklistId in tempLists){
                var currentPicklist = tempLists[picklistId];
                if(currentPicklist.controller_id != null){
                    j$(document.getElementById(picklistId)).val('');
                }
            }

            // apex remote action
            var obj = my.getFieldSetFieldsAndValues();
            jrReloadPicklists(result.message, obj.Type, obj.ProductCategory__c, obj.ProductSubCategory__c, obj.EnquirySubType__c);
        },

        /**
         * SHow loader for remote actions
         */
        showLoadProgress: function() {
            model.set('waitQueueCount', model.get('waitQueueCount')+1);
            miniCaseShowProgress();
        },

        /**
         * This first check to see whether any actions are still pending and if they are, no hiding is done.
         */
        hideLoadProgress: function() {
            var waitQueue = model.get('waitQueueCount');
            waitQueue--;
            model.set('waitQueueCount', (waitQueue < 0 ? 0 : waitQueue));

            if(waitQueue <= 0) {
                miniCaseHideProgress();
            }
        },

        actionComplete: function() {
            my.hideLoadProgress();
        },

        getFieldsAndValuesAsJSON: function() {
            var arr = my.getFieldSetFieldsAndValues();
            //window.console&&console.log(arr);
            //console.log('> hfIsConsignment < ', j$('#hfIsConsignment').val());


            var senderDetails = model.get('hpSenderDetails');
            var receiverDetails = model.get('hpReceiverDetails');

            // the sender details from the article that was queried
            arr.Address1__c = senderDetails.address;
            arr.PrimaryContactName__c = senderDetails.name;
            arr.Primary_Name__c = senderDetails.name;
            arr.Primary_Company__c = senderDetails.companyName;
            arr.PrimaryEmail__c = my.isValidEmail(senderDetails.email) ? senderDetails.email : '';
            arr.Primary_Email__c = my.isValidEmail(senderDetails.email) ? senderDetails.email : '';
            arr.Address1Postcode__c = senderDetails.postcode;
            //arr.PrimaryContact__c = caseOriginator.PrimaryContact__c;

            // the receiver details from the article that was queried
            arr.Address2__c = receiverDetails.address;
            arr.SecondaryContactName__c = receiverDetails.name;
            arr.Secondary_Companry__c = receiverDetails.companyName;
            arr.SecondaryEmail__c = my.isValidEmail(receiverDetails.email) ? receiverDetails.email : '';
            arr.Address2Postcode__c = receiverDetails.postcode;

            // other fields requiring to be set
            arr.DatePosted__c = model.get('hpLodgementDate');
            arr.CaseOriginator__c = model.get('hpCaseOriginator');


            // if(document.getElementById("hfIsConsignment") != null){
            //     //console.log('> is TIBCO Function TIBCOTrackingResultComponent_getCaseOriginator <', typeof window.TIBCOTrackingResultComponent_getCaseOriginator);
            //
            //
            //     if(typeof window.TIBCOTrackingResultComponent_getCaseOriginator == 'function') {
            //         var caseOriginator = TIBCOTrackingResultComponent_getCaseOriginator();
            //         window.console&&console.log(caseOriginator);
            //         arr["CaseOriginator__c"] = caseOriginator.CaseOriginator__c;
            //         arr["Address1__c"] = caseOriginator.Address1__c;
            //         arr["PrimaryContactName__c"] = caseOriginator.PrimaryContactName__c;
            //         arr["PrimaryEmail__c"] = caseOriginator.PrimaryEmail__c;
            //         arr["PrimaryContact__c"] = caseOriginator.PrimaryContact__c;
            //         arr["Address1Postcode__c"] = caseOriginator.Address1Postcode__c;
            //         arr["Address2__c"] = caseOriginator.Address2__c;
            //         arr["SecondaryContactName__c"] = caseOriginator.SecondaryContactName__c;
            //         arr["SecondaryEmail__c"] = caseOriginator.SecondaryEmail__c;
            //         arr["SecondaryContact__c"] = caseOriginator.SecondaryContact__c;
            //         arr["Address2Postcode__c"] = caseOriginator.Address2Postcode__c;
            //         if(caseOriginator.DatePosted__c != null) {
            //             arr["DatePosted__c"] = caseOriginator.DatePosted__c;
            //         }
            //     }
            // } else {
            //     //console.log('> is TIBCO Function TIBCOArticleComponent_getCaseOriginator <', typeof window.TIBCOArticleComponent_getCaseOriginator);
            //
            //     if(typeof window.TIBCOArticleComponent_getCaseOriginator == 'function') {
            //         var caseOriginator = TIBCOArticleComponent_getCaseOriginator();
            //         window.console&&console.log(caseOriginator);
            //         arr["CaseOriginator__c"] = caseOriginator.CaseOriginator__c;
            //         arr["Address1__c"] = caseOriginator.Address1__c;
            //         arr["Primary_Name__c"] = caseOriginator.PrimaryContactName__c;
            //         arr["Primary_Company__c"] = caseOriginator.Primary_Company__c;
            //         arr["Primary_Email__c"] = caseOriginator.PrimaryEmail__c;
            //         arr["PrimaryContact__c"] = caseOriginator.PrimaryContact__c;
            //         arr["Address1Postcode__c"] = caseOriginator.Address1Postcode__c;
            //         arr["Address2__c"] = caseOriginator.Address2__c;
            //         arr["SecondaryContactName__c"] = caseOriginator.SecondaryContactName__c;
            //         arr["Secondary_Companry__c"] = caseOriginator.Secondary_Companry__c;
            //         arr["SecondaryEmail__c"] = caseOriginator.SecondaryEmail__c;
            //         arr["SecondaryContact__c"] = caseOriginator.SecondaryContact__c;
            //         arr["Address2Postcode__c"] = caseOriginator.Address2Postcode__c;
            //         if(caseOriginator.DatePosted__c != null) {
            //             arr["DatePosted__c"] = caseOriginator.DatePosted__c;
            //         }
            //     }
            // }

            return JSON.stringify(arr);
        },

        showPopup: function(closeEnquiry) {
            if(!closeEnquiry) {
                j$('[id$="popup"]').removeClass('hide').addClass('show');
            } else {
                j$('[id$="popup2"]').removeClass('hide').addClass('show');
            }
        },

        getFieldSetFieldsAndValues: function() {

            var prdSubCat;
            var o = {};

            var arr = j$('[class*="wrapper_MiniCaseFieldSet_"]');
            arr.each(function() {
                var $el = j$(this).find('select, input, textarea');
                if($el.length > 0) {
                    // grab the text on the class
                    var reg = new RegExp('wrapper_MiniCaseFieldSet_(.*?)(\\s|$)', 'ig');
                    var results = reg.exec(j$(this).attr('class'));
                    if(results && results[1]) {
                        o[results[1]] = $el.val();
                    }
                }
            });

            var hfContactId = j$('[id$="hfContactId"]');
            if (hfContactId.val().trim() != '') {
                o.ContactId = hfContactId.val().trim();
            }

            if(j$('.wrapper_MiniCaseFieldSet_ProductSubCategory__c select').length > 0) {
                o.ProductSubCategory__c = j$('.wrapper_MiniCaseFieldSet_ProductSubCategory__c select').val();
            }

            // if this instance is loaded inside a live agent chat
            var chatKey = model.get('chatKey');
            if(!my.isEmpty(chatKey)){
                o.ChatKey__c = chatKey;
            }

            console.log('>>> getFieldSetFieldsAndValues <<<', o);

            return o;
        },

        /**
         * Catch any values that are being passed by events from other instances of this component
         * This is the result of a RequestValues message being fires and a SynchronisedValues or [page id]_SynchronisedValues_OnLoad message being returned with an object of values {ProductCategory__c: '', ReferenceID__c: '', ...}
         */
        setupValues: function(result) {

            if(my.isEmpty(result.message))
                return;

            var obj = my.safeParseJSON(result.message);
            var syncContext = DEFAULT_SYNC_CONTEXT;
            var fieldValues = {};
            if(typeof obj === 'object' && obj.hasOwnProperty('syncContext')) {
                syncContext = obj.syncContext;
                fieldValues = obj.values;
            } else {
                fieldValues = obj;
            }

            // only proceed if the context's match
            if(syncContext !== model.get('syncContext'))
                return;

            if(!my.isEmpty(fieldValues)) {
                console.log('fieldValues:', fieldValues);

                // reset our 'current' values used to send back to the server (since we are receiving potentially new values from a synchronise event)
                if(!my.isEmpty(fieldValues.ReferenceID__c) && fieldValues.ReferenceID__c.toString().trim() == '') {
                    model.set('currentSAPEMReferenceId', '');
                    model.set('currentCaseReferenceId', '');
                }
                if(!my.isEmpty(fieldValues.ProductCategory__c) && fieldValues.ProductCategory__c.toString().trim() == '') {
                    model.set('currentProductCategory', '');
                }

                // this is now a legacy value that doesnt need to be set anymore
                // this is handled automatically as the type, product cat, product sub cat fields are set
                // we don't need to explicitly set this field value
                delete fieldValues['Type_and_Product__c'];

                // loop through the initial priority list of values to se in the specified order of this array
                // this will ensure all field values are set and dependent field generate correctly.
                var priorityOrderedValues = ['Type', 'ProductCategory__c', 'ProductSubCategory__c', 'EnquirySubType__c'];
                for(var i=0;i<priorityOrderedValues.length;i++) {
                    if(fieldValues.hasOwnProperty(priorityOrderedValues[i])) {
                        var $el = j$('.wrapper_MiniCaseFieldSet_' + priorityOrderedValues[i]).find('select, input, textarea');

                        if($el.length > 0) {
                            var value = fieldValues[priorityOrderedValues[i]];
                            value = (my.isEmpty(value) ? '' : value.toString());
                            my.miniCaseFieldValueChanged(priorityOrderedValues[i], JSON.stringify({syncContext: syncContext, value: value}));
                        }
                    }
                }

                // loop through any outstanding field values and attempt to set them if the field exists
                for(var propertyName in fieldValues) {
                    if(fieldValues.hasOwnProperty(propertyName) && j$.inArray(propertyName, priorityOrderedValues) == -1) {
                        var $el = j$('.wrapper_MiniCaseFieldSet_' + propertyName).find('select, input, textarea');

                        if($el.length > 0) {
                            var value = fieldValues[propertyName];
                            my.miniCaseFieldValueChanged(propertyName, JSON.stringify({syncContext: syncContext, value: value}));
                        }
                    }
                }

                if(fieldValues.hasOwnProperty('Type') && fieldValues['Type'] === 'General Enquiry') {
                    j$('[id$="btnCloseEnquiry"]').show();
                    j$('[id$="btnCreateCase"]').hide();
                } else {
                    j$('[id$="btnCreateCase"]').show();
                    j$('[id$="btnCloseEnquiry"]').hide();
                }
            }
        },

        /**
         * When the calculate edd is clicked in TIBCO article component.
         */
        showEDDTab: function(result) {
            // NOTE: This should be refactored and removed from this page when possible.... NF
            var eddDetails = JSON.parse(result.message);
            var fromPostcode = eddDetails.SenderPostcode;
            var toPostcode = eddDetails.ReceiverPostcode;
            var sentDate = eddDetails.SentDate;
            var articleType = eddDetails.ArticleType;
            if(model.get('eddWidgitEventId') !== '') {
                // bring EDD into focus
                j$('#miniCaseTabs a[href="#edd"]').tab('show');

                // send the details across to EDD
                var values = {
                    fromPostcode: fromPostcode,
                    toPostcode: toPostcode,
                    sentDate: sentDate,
                    articleType: articleType
                };
                sforce.console.fireEvent(model.get('eddWidgitEventId'), JSON.stringify(values));
            }
        },

        openTrackInNewTab: function(e) {
            var $el = j$(e.currentTarget);
            my.openPrimaryTabUrl($el.attr('href'), 'Track');

            e.preventDefault();
            return false;
        },

        getQueryString: function(name) {
            var sPageURL = window.location.search.substring(1);
            var sURLVariables = sPageURL.split('&');
            for (var i = 0; i < sURLVariables.length; i++) {
                var sParameterName = sURLVariables[i].split('=');
                if (sParameterName[0] == name) {
                    return sParameterName[1];
                }
            }
        },

        /**
         * Accepts either non JSON strings or JSON strings and will return the appropriate value
         */
        safeParseJSON: function(str) {
            if(typeof str === 'object') {
                return str;
            }

            var obj;
            try {
                obj = JSON.parse(str);
            } catch(err) {
                obj = str;
            }

            return obj;
        },

        closePopup: function() {
            j$('[id$="popup"]').removeClass('show').addClass('hide');
            j$('[id$="popup2"]').removeClass('show').addClass('hide');
        },

        clearMiniCaseErrorPanel: function() {
            j$(".messageText").html("");
            my.hideMinisCaseMessage();
        },

        clearMiniCase: function() {
            my.clearMiniCaseErrorPanel();

            // send a clear message just for the current context
            var objMessage = {
                syncContext: model.get('syncContext'),
                message: 'clear'
            };
            var message = JSON.stringify(objMessage);
            sforce.console.fireEvent('RequestValues', message);

            model.set('hpCaseOriginator', 'Customer');
            model.set('currentSAPEMReferenceId', {});
            model.set('hpSenderDetails', {});
            model.set('hpReceiverDetails', {});
            model.set('hpLodgementDate', null);
            model.set('hpSelectedArticles', []);
            model.set('hpDeliveryProofImage', []);

            // force a refresh of the IFRAME
            document.getElementById('hpWindow').src = document.getElementById('hpWindow').src
        },

        hideMinisCaseMessage: function() {
            j$('[id$="pnlMiniCaseMessage"]').removeClass('show').addClass('hide');
            j$(".message").hide();
        },

        showMiniCaseMessage: function() {
            j$('[id$="pnlMiniCaseMessage"]').removeClass('hide').addClass('show');
            j$(".message").show();

        },

        showMiniCaseErrorPanel: function(msg) {
            //window.console&&console.log('showing error message: ' + msg);
            j$(".messageText").html(msg);
            my.showMiniCaseMessage();
        },

        openPrimaryTabUrl: function(url, title) {
            sforce.console.openPrimaryTab(null, url, true, title);
        },

        openPrimaryTab: function(id){
            sforce.console.openPrimaryTab(null, '/' + id, true);
        },

        isEmpty: function(val) {
            // test results
            //---------------
            // []        true, empty array
            // {}        true, empty object
            // null      true
            // undefined true
            // ''        true, empty string
            // ''        true, empty string
            // 0         false, number
            // true      false, boolean
            // false     false, boolean
            // Date      false
            // function  false

            if (val === undefined)
                return true;

            if (val === '')
                return true;

            if (typeof (val) == 'function' || typeof (val) == 'number' || typeof (val) == 'boolean' || Object.prototype.toString.call(val) === '[object Date]')
                return false;

            if (val == null || val.length === 0)        // null or 0 length array
                return true;

            if (typeof(val) == 'object') {
                // empty object
                var r = true;

                for (var f in val)
                    r = false;

                return r;
            }

            return false;
        },

        isValidEmail: function(email) {
            var patt = /.+@.+\..+/i;
            return patt.test(email);
        }
    };

    // return a public interface
    return {
        initialize: my.initialize,
        wireAccordion: my.wireAccordion,
        fireSynchroniseEvent: my.fireSynchroniseEvent,
        closePopup: my.closePopup,
        clearMiniCaseErrorPanel: my.clearMiniCaseErrorPanel,
        clearMiniCase: my.clearMiniCase,
        actionComplete: my.actionComplete,
        createCaseWithoutDuplicateCheck: my.createCaseWithoutDuplicateCheck,
        createCaseWithDuplicateCheck: my.createCaseWithDuplicateCheck,
        inputChangeHandler: my.inputChangeHandler,
        openPrimaryTab: my.openPrimaryTab,
        // expose the model
        model: model
    };
});



