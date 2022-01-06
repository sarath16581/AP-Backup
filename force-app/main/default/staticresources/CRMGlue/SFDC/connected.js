/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * The main interface between the Cephas generic code and SFDC
 */
define(['util', 'i18next', 'integration', 'agent/voice', 'config', 'SFDC/tracking', 'SFDC/case', 'SFDC/task', 'SFDC/pop'],
            function (util, i18n, sforce, voice, config, tracking, caseObj, task, pop) {
    var log_prefix = "SFDC/connected: ";
    var _searchSettings = null;

    var initialize = function (searchSettings) {
        try {
            console.log(log_prefix + 'initialize');
            _searchSettings = searchSettings;
            caseObj.initialize(searchSettings.searchCaseKVP);
            sforce.interaction.cti.enableClickToDial();
            sforce.interaction.cti.onClickToDial(dial);
            sforce.console.addEventListener('CTIEvent', receiveSFMessage);
            sforce.console.onFocusedPrimaryTab(tracking.primaryTabFocused);

            /*
             * Voice: Search on case, then a custom search field, then the ANI
             */
            util.getInstance('voice.pop').subscribe(function (message) {
                console.log(log_prefix + "voice.pop");
                var ixn = message.call;

                try {
                    var aniSearch = function (params) {
                        console.log(log_prefix + "aniSearch");

                        // end of the line for internal calls
                        if (ixn.callType === 'Internal') {
                            console.log(log_prefix + "is internal call");
                            return;
                        }

                        var ani = ixn.ani;
                        if (ixn.callType === 'Outbound') {
                            ani = ixn.dnis;
                        }

                        console.log(log_prefix + "ANI=" + ani);
                        if (config.NO_ANI_SEARCH) {
                            console.log(log_prefix + "aniSearch - not enabled");

                            // go straight to the search
                            doSearch(params, 'phoneNumber', ani);
                        }
                        else {
                            ConnectorController.findContact('Phone', ani, function (contact) {
                                if (contact !== null) {
                                    if (contact.Id === undefined) { // multiple contacts
                                        console.log(log_prefix + "contact search - multiple contacts");
                                        doSearch(params, 'phoneNumber', ani);
                                    }
                                    else {
                                        contact.Name = $("<div/>").html(contact.Name).text(); // contains HTML chars
                                        console.log(log_prefix + "findContact - " + contact.Id + ", " + contact.Name);
                                        params.contact = contact;
                                        pop.start(params);
                                    }
                                }
                                else {
                                    console.log(log_prefix + "contact search - no records found");
                                    doSearch(params, 'phoneNumber', ani);
                                }
                            });
                        }

                        console.log(log_prefix + "aniSearch - finished");
                    };

                    var params = {
                        searchField: message.fieldName,
                        searchValue: message.fieldValue,
                        searchType: searchSettings.voiceSearchType,
                        ixn: ixn,
                        popOnly: ixn.parentCallUri !== undefined, /* just a pop for consult calls */
                        noCase: ixn.callType === 'Outbound'
                    };

                    // do the actual search
                    caseObj.search(params).then(
                        function (contact, caseId, caseNumber) { // success case
                            if (contact !== null) {
                                params.contact = contact;
                                params.caseId = caseId;
                                params.caseNumber = caseNumber;
                                pop.start(params);
                            }
                            // else the case search window is open, so do nothing
                        },
                        function () { // fail case
                            return fieldSearch(params);
                        }).then(null,
                        function () {
                            aniSearch(params);
                        });
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }

                console.log(log_prefix + "voice.pop - finished");
            });

            util.getInstance('voice.ended').subscribe(function (message) {
                console.log(log_prefix + "voice.ended");

                try {
                    var ixn = message.call;
                    var id = ixn.id;

                    if (tracking.exists(id)) {
                        var comments = "";
                        if (ixn.notes !== undefined && ixn.notes !== '') {
                            comments += "Note:\n" + ixn.notes + '\n\n';
                        }

                        task.finish(id, comments, ixn, ixn.duration).done(
                            function() {
                                tracking.remove(id)
                            }
                        );
                    }
                    else {
                        console.log(log_prefix + "could not find " + id);
                    }
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }
            });

            /*
             * Email: Search on case, then a custom search field, then the customer's email address,
             * then open a search screen using the email from address
             */
            util.getInstance('email.pop').subscribe(function (message) {
                console.log(log_prefix + "email.pop");
                var ixn = message.email;
                var params = {
                    searchField: message.fieldName,
                    searchValue: message.fieldValue,
                    searchType: searchSettings.emailSearchType,
                    ixn: ixn
                };

                // do the actual search
                caseObj.search(params).
                    then(
                        function (contact, caseId, caseNumber) { // success case
                            if (contact !== null) {
                                params.contact = contact;
                                params.caseId = caseId;
                                params.caseNumber = caseNumber;
                                pop.start(params);
                            }
                            // else the case search window is open, so do nothing
                        },
                        function() {
                            return fieldSearch(params);
                        }).
                    then(null,
                        function() {
                            return doSearch(params, 'email', ixn.from);
                        }
                    );
            });

            util.getInstance('email.ended').subscribe(function (message) {
                console.log(log_prefix + "email.ended");

                try {
                    var ixn = message.email;
                    var id = ixn.id;

                    if (tracking.exists(id)) {
                        var comments = "";
                        if (ixn.notes !== undefined && ixn.notes !== '') {
                            comments += "Note:\n" + ixn.notes + '\n\n';
                        }

                        comments += "Email\n";
                        comments += "Msg: " + ixn.emailDescription;

                        task.finish(id, comments, ixn, ixn.duration).done(
                            function() {
                                tracking.remove(id)
                            }
                        );
                    }
                    else {
                        console.log(log_prefix + "could not find " + id);
                    }
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }
            });

            /*
             * Chat: Search on case, then a custom search field, then the customer's name,
             * then open a search screen using the email address
             */
            util.getInstance('chat.pop').subscribe(function (message) {
                console.log(log_prefix + "chat.pop");
                var ixn = message.chat;
                var params = {
                    searchField: message.fieldName,
                    searchValue: message.fieldValue,
                    searchType: searchSettings.chatSearchType,
                    ixn: ixn
                };

                // do the actual search
                caseObj.search(params).
                    then(
                        function (contact, caseId, caseNumber) { // success case
                            if (contact !== null) {
                                params.contact = contact;
                                params.caseId = caseId;
                                params.caseNumber = caseNumber;
                                pop.start(params);
                            }
                            // else the case search window is open, so do nothing
                        },
                        function() {
                            return fieldSearch(params);
                        }).
                    then(null,
                        function() {
                            return doSearch(params, null, null);
                        }
                    );
            });

            util.getInstance('chat.ended').subscribe(function (message) {
                console.log(log_prefix + "chat.ended");

                try {
                    var ixn = message.chat;
                    var id = ixn.id;

                    if (tracking.exists(id)) {
                        var comments = "";
                        if (ixn.notes !== undefined && ixn.notes !== '') {
                            comments += "Note:\n" + ixn.notes + '\n\n';
                        }

                        comments += "Transcript:\n" + ixn.transcript;

                        task.finish(id, comments, ixn, ixn.duration).done(
                            function() {
                                tracking.remove(id)
                            }
                        );
                    }
                    else {
                        console.log(log_prefix + "could not find " + id);
                    }
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }
            });

            /******************************************************************************
             *                  Preview Outbound - pop
             ******************************************************************************/
            util.getInstance('preview.pop').subscribe(function (message) {
                console.log(log_prefix + "preview.pop");
                var ixn = message.record;

                var phoneSearch = function () {
                    console.log(log_prefix + "phoneSearch");
                    var phoneNumber = ixn.phone;
                    var params = {
                        ixn: ixn,
                        searchValue: message.fieldValue,
                        popOnly: true
                    };
                    
                    ConnectorController.findContact('Phone', phoneNumber,
                        function (contact) {
                            if (contact !== null) {
                                if (contact.Id === undefined) { // multiple contacts
                                    console.log(log_prefix + "contact search - multiple contacts");
                                    doSearch(params, 'phoneNumber', phoneNumber);
                                }
                                else {
                                    contact.Name = $("<div/>").html(contact.Name).text(); // convert HTML to plain text
                                    console.log(log_prefix + "phoneSearch: " + contact.Id + ", " + contact.Name + " (" + message.record.id + ")");
                                    params.contact = contact;
                                    pop.start(params);
                                }
                            }
                            else {
                                console.log(log_prefix + "contact search - no records found");
                                doSearch(params, 'phoneNumber', phoneNumber);
                            }
                        }
                    );
                    console.log(log_prefix + "phoneSearch - finished");
                };

                var params = {
                    searchField: message.fieldName,
                    searchValue: message.fieldValue,
                    searchType: searchSettings.voiceSearchType,
                    ixn: ixn,
                    popOnly: true
                };
                fieldSearch(params).
                    then(null, phoneSearch);
            });

            /******************************************************************************
             *                  Other functions
             ******************************************************************************/

            /**
             * Find a contact based on a KVP
             * @param params
             * @returns {*}
             */
            var fieldSearch = function(params) {
                var d = $.Deferred();

                var searchField = params.searchField;
                var searchValue = params.searchValue;
                var ixn = params.ixn;
                var searchType = params.searchType || null;

                try {
                    console.log(log_prefix + "fieldSearch");

                    if (searchField !== null &&
                            searchValue !== null) {
                        console.log(log_prefix + "fieldSearch - search field=" + searchField);
                        console.log(log_prefix + "fieldSearch - search value=" + searchValue);

                        if (searchValue !== undefined && searchValue !== '') {
                            ConnectorController.findContact(searchField, searchValue,
                                function (contact) {
                                    if (contact !== null) {
                                        if (contact.Id === undefined) { // multiple contacts
                                            console.log(log_prefix + 'fieldSearch - multiple contacts');
                                            doSearch(params, searchType, searchValue);
                                        }
                                        else {
                                            contact.Name = $("<div/>").html(contact.Name).text(); // convert to non-HTML
                                            console.log(log_prefix + "fieldSearch - " + contact.Id + ", " + contact.Name + " (" + ixn.id + ")");
                                            params.contact = contact;
                                            pop.start(params);
                                            console.log(log_prefix + "fieldSearch - success for " + ixn.id);
                                        }

                                        d.resolve();
                                    }
                                    else {
                                        console.log(log_prefix + "fieldSearch - no field value found");
                                        d.reject();
                                    }
                                }
                            );
                        }
                        else {
                            console.log(log_prefix + "fieldSearch - no field KVP in interaction");
                            d.reject();
                        }
                    }
                    else {
                        console.log(log_prefix + "fieldSearch - no field search");
                        d.reject();
                    }
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                    d.reject();
                }

                console.log(log_prefix + "fieldSearch - finished");
                return d.promise();
            };

            /**
             * Open up the VisualForce search page with the appropriate parameters.
             * @param params - search parameters
             * @param type - the column to show the search parameter
             * @param searchString
             * @returns a promise
             */
            var doSearch = function(params, type, searchString) {
                console.log(log_prefix + "doSearch - " + type + ", " + searchString);
                var d = $.Deferred();
                var url = '/apex/CRMDefaultSearch?id=' + params.ixn.id;

                if (config.NO_DEFAULT_SEARCH) {
                    console.log(log_prefix + "doSearch - not enabled");
                    d.reject();
                }
                else if (searchString !== undefined && searchString !== null && searchString !== '' && type !== null) {
                    url += "&" + type + '=' + searchString;
                    console.log(log_prefix + "url=" + url);
                    tracking.setParams(params);
                    sforce.console.openPrimaryTab(null, url, true, i18n.t('search.search'));
                    d.resolve();
                }
                else {
                    console.log(log_prefix + "url=" + url);
                    tracking.setParams(params);
                    sforce.console.openPrimaryTab(null, url, true, i18n.t('search.search'));
                    d.reject();
                }

                return d.promise();
            };
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.stack);
        }

        console.log(log_prefix + "initialized");
        util.getInstance('sfdc.connected').publish('initialized');
    };

    /**
     * Receive a message from SF
     * @param result
     */
    function receiveSFMessage(result) {
        var msg = JSON.parse(result.message);
        console.log("receiveSFMessage CTIEvent = " + msg.action);

        if (msg.action === "MarkDone") { // comes from customized SFDC page
            var data = {};

        }
        else if (msg.action === "ContactSelected") { // comes from Search page
            console.log(log_prefix + "ContactSelected - " + msg.objectId + ", " + msg.id);
            ConnectorController.getContact(msg.objectId, null,
                function (contact) {
                    var params = tracking.getParams(msg.id);
                    if (params !== null) {
                        params.contact = contact;

                        // start the whole process again...
                        pop.start(params);
                    }
                }
            );
        }
        else if (msg.action === "CaseSelected") { // comes from Case Search page
            console.log(log_prefix + "CaseSelected - " + msg.objectId + ", " + msg.id);
            ConnectorController.getContact(msg.objectId, null,
                function (contact) {
                    var params = tracking.getParams(msg.id);
                    if (params !== null) {
                        params.contact = contact;
                        params.caseId = msg.caseId;
                        params.caseNumber = msg.caseNumber;

                        // start the whole process again...
                        pop.start(params);
                    }
                }
            );
        }
    }

    /**
     * Dial a number via the SFDC "click to dial" functionality.
     * @param request
     */
    function dial(request) {
        var result = JSON.parse(request.result);
        var numberToCall = result.number;
        var caseNumber = null;
        var contactId = null;
        console.log(log_prefix + numberToCall);

        var params = {
            phoneNumber: numberToCall,
            userData: {}
        };

        var getContact = function() {
            var d = $.Deferred();

            if (result.object === 'Contact') {
                caseNumber = caseObj.getCaseNumber(result.objectId);
                contactId = result.objectId;
                console.log(log_prefix + "case number is " + caseNumber + ", contact is " + contactId);
                d.resolve();
            }
            else if (result.object === 'Account') {
                contactId = result.contactId;
                console.log(log_prefix + "contact is " + contactId);
                d.resolve();
            }
            else if (result.object === 'Case') {
                caseNumber = result.objectName;
                console.log(log_prefix + "case number is " + caseNumber);
                d.resolve();
            }
            else if (result.object === 'Task') {
                var taskId = result.objectId;
                console.log(log_prefix + "task is " + taskId);

                ConnectorController.getContactByTask(taskId,
                    function (task) {
                        contactId = task.WhoId;
                        caseNumber = task.CallObject;
                        console.log(log_prefix + "contact is " + contactId + ", case number is " + caseNumber);
                        d.resolve();
                    }
                );
            }
            else {
                console.log(log_prefix + "object is " + result.object);
                d.resolve();
            }

            return d;
        };

        var getDetails = function () {
            var d = $.Deferred();

            try {
                // make sure we can bring up an existing case/contact
                if (_searchSettings.searchVoiceKVP !== "") {

                    // get the contact id
                    getContact().done(function() {
                        if (caseNumber !== null && _searchSettings.searchCaseKVP !== "") {
                            params.userData[_searchSettings.searchCaseKVP] = caseNumber;
                        }

                        if (contactId !== null) {
                            ConnectorController.getContact(contactId, _searchSettings.searchVoiceField,
                                function (contact) {
                                    if (contact !== null) {
                                        var voiceField = contact[_searchSettings.searchVoiceField];

                                        if (voiceField !== null) {
                                            console.log(log_prefix + "voice field is " + voiceField);
                                            params.userData[_searchSettings.searchVoiceKVP] = voiceField;
                                        }
                                    }

                                    d.resolve();
                                }
                            );
                        }
                        else {
                            d.resolve();
                        }
                    });
                }
                else {
                    d.resolve();
                }
            }
            catch (e) {
                console.error(log_prefix + e.stack);
                d.resolve();
            }

            return d;
        };

        getDetails().done(
            function () {
                voice.dial(params);
            });
    }

    return {
        initialize: initialize
    };
});