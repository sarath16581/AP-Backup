/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the methods that are used by the VisualForce page.
 */
define(['jquery', 'util', 'Glue', 'SFDC/api', 'i18next', 'jqueryI18next', 'i18nextXHRBackend', 'SFDC/connected', 'SFDC/lang'],
            function ($, util, glue, sfdc, i18n, jqueryI18next, XHR, connected, pageLang) {
    var log_prefix = "SFDC/sfdc: ";
    var _connectorSettings;
    var i18initialized = false;

    function start(settings) {
        console.log(log_prefix + 'start');
        _connectorSettings = getConnectorSettings(settings);
        var fieldSearchSettings = getFieldSearchOptions(settings);

        util.getInstance('glue.state').subscribe(
            function (message) {
                switch (message) {
                    case "connecting":
                        console.log(log_prefix + 'Connecting...');
                        sfdc.setSoftphoneLabel(i18n.t('connect.connecting'));
                        sfdc.setSoftphoneStyle('connecting');
                        break;

                    case "connected":
                        console.log(log_prefix + 'Connected');
                        sfdc.setSoftphoneLabel(i18n.t('connect.connected'));
                        sfdc.setSoftphoneStyle('connected');
                        connected.initialize(fieldSearchSettings);
                        break;

                    case "not connected":
                        console.log(log_prefix + 'Not Connected');
                        sfdc.setSoftphoneLabel(i18n.t('connect.notConnected'));
                        sfdc.setSoftphoneStyle('not connected');
                        break;
                }
            });

        glue.initialize( _connectorSettings);
    }

    /**
     * The entry point from the SFDC VisualForce page. Process some config and start the connection to GWS.
     * @param resourceLoc
     */
    var initialize = function(resourceLoc, settings, isLightning) {
        var d = $.Deferred();
        sfdc.initialize(isLightning);

        try {
            console.log(log_prefix + 'initialize (' + resourceLoc + ')');

            // internationalization
            var userLang = window.navigator.userLanguage || window.navigator.language;
            console.log(log_prefix + "lang=" + userLang);

            if (!i18initialized) {
                i18n.use(XHR).init({
                        "debug": true,
                        "lng": userLang,
                        "fallbackLng": "en",
                        "backend": {
                            "loadPath": resourceLoc + 'locales/{{lng}}.json'
                        }
                    }, function () {
                        jqueryI18next.init(i18n, $);
                        i18initialized = true;
                        $("body").localize();

                        // set up the search page strings
                        pageLang.initialize();
                    
                        if (sforce.console.isInConsole()) {
                            console.log(log_prefix + 'in console');
                            start(settings);
                            d.resolve(i18n);
                        }
                        else {
                            console.log(log_prefix + 'NOT in Salesforce console.');
                            d.reject();
                        }
                    }
                );
            }
            else if (sforce.console.isInConsole()) {
                console.log(log_prefix + 'in console');
                start(settings);
                d.resolve();
            }
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.stack);
            d.reject();
        }

        return d.promise();
    };

    function getConnectorSettings(settings) {
        var pollPort = getOption(settings, 'ConnectorSettings', 'PollPort', '5050');
        var useWebSockets = getOption(settings, 'ConnectorSettings', 'UseWebSockets', 'false');
        var showContact = getOption(settings, 'PopSettings', 'ShowContact', 'true') === 'true';
        var noDefaultSearch = getOption(settings, 'PopSettings', 'NoDefaultSearch', 'false') === 'true';
        var noANISearch = getOption(settings, 'PopSettings', 'NoANISearch', 'false') === 'true';
        var showCase = getOption(settings, 'CaseSettings', 'ShowCase', 'false') === 'true';
        var newCaseOnPop = getOption(settings, 'CaseSettings', 'NewCaseOnPop', 'false') === 'true';
        var newCaseIfNoSearchKVPPresent = getOption(settings, 'CaseSettings', 'NewCaseIfNoSearchKVPPresent', 'false') === 'true';
        var searchCaseIfWrongCase = getOption(settings, 'CaseSettings', 'SearchCaseIfWrongCase', 'false') === 'true';
        var openNewCaseInEditMode = getOption(settings, 'CaseSettings', 'OpenNewCaseInEditMode', 'false') === 'true';
        var openExistingCaseInEditMode = getOption(settings, 'CaseSettings', 'OpenExistingCaseInEditMode', 'false') === 'true';
        var createTask = getOption(settings, 'TaskSettings', 'CreateTask', 'false') === 'true';
        var newTaskOnPop = getOption(settings, 'TaskSettings', 'NewTaskOnPop', 'false') === 'true';
        var openInitialTaskInEditMode = getOption(settings, 'TaskSettings', 'OpenInitialTaskInEditMode', 'false') === 'true';
        var openFinalTaskInEditMode = getOption(settings, 'TaskSettings', 'OpenFinalTaskInEditMode', 'false') === 'true';
        var caseMap = getOption(settings, 'DataMapping', 'CaseMap', '');
        var taskMap = getOption(settings, 'DataMapping', 'TaskMap', '');
        var dispositionKVP = getOption(settings, 'DataMapping', 'DispositionKVP');

        return {
            pollPort: pollPort,
            useWebSockets: useWebSockets,
            showContact: showContact,
            noDefaultSearch: noDefaultSearch,
            noANISearch: noANISearch,
            showCase: showCase,
            newCaseOnPop: newCaseOnPop,
            searchCaseIfWrongCase: searchCaseIfWrongCase,
            newCaseIfNoSearchKVPPresent: newCaseIfNoSearchKVPPresent,
            openNewCaseInEditMode: openNewCaseInEditMode,
            openExistingCaseInEditMode: openExistingCaseInEditMode,
            createTask: createTask,
            newTaskOnPop: newTaskOnPop,
            openInitialTaskInEditMode: openInitialTaskInEditMode,
            openFinalTaskInEditMode: openFinalTaskInEditMode,
            caseMap: caseMap,
            taskMap: taskMap,
            dispositionKVP: dispositionKVP
        };
    }

    function getOption(settings, section, optionName, defValue) {
        var value = settings['/' + section + '/' + optionName];
        if (value) {
            console.log("getOption: " + section + " " + optionName + ": " + value);
            return value;
        } else {
            console.log("getOption: " + section + " " + optionName + " (default): " + defValue);
            return defValue;
        }
    }

    function getSearchOption(settings, optionName, defValue) {
        return getOption(settings, 'FieldSearchSettings', optionName, defValue);
    }

    function getFieldSearchOptions(settings) {
        return {
            voiceSearchType: getSearchOption(settings, "VoiceSearchType", 'phoneNumber'),
            emailSearchType: getSearchOption(settings, "EmailSearchType", 'email'),
            chatSearchType: getSearchOption(settings, "ChatSearchType", 'name'),
            openmediaSearchType: getSearchOption(settings, "OpenMediaSearchType", 'name'),
            searchCaseKVP: getSearchOption(settings, "SearchCaseKVP", 'CaseNumber'),
            voiceSearchKVP: getSearchOption(settings, "VoiceSearchKVP", ''),
            voiceSearchField: getSearchOption(settings, "VoiceSearchField", 'Phone')
        };
    }
                
    var terminate = function() {
        console.log(log_prefix + "terminate");
        glue.terminate();
    };

    return {
        initialize: initialize,
        terminate: terminate
    };
});