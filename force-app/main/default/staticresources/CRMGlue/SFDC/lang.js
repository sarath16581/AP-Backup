/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Get/set some language strings for the default/case search windows
 */
define(['i18next'], function(i18n) {
    var log_prefix = "SFDC/lang: ";
    var storageKey = "CRM.lang";
    var _storage = window.localStorage;

    function setText(key, text) {
        _storage.setItem(storageKey + '.' + key, JSON.stringify(text));
    }

    var getText = function(key) {
        var text = _storage.getItem(storageKey + '.' + key);

        if (text !== null) {
            return JSON.parse(text);
        }

        console.warn(log_prefix + 'key ' + key + ' not found');
        return null;
    };

    var initialize = function() {
        console.log(log_prefix + "initialize");
        var defaultSearchText = {
            search: i18n.t('search.search'),
            phoneNumber: i18n.t('search.phoneNumber'),
            name: i18n.t('search.name'),
            email: i18n.t('search.email'),
            account: i18n.t('search.account'),
            address: i18n.t('search.address')
        };
        setText('default', defaultSearchText);

        var caseSearchText = {
            search: i18n.t('search.search'),
            caseSearch: i18n.t('search.caseSearch'),
            caseNumber: i18n.t('search.caseNumber'),
            subject: i18n.t('search.subject'),
            account: i18n.t('search.account'),
            name: i18n.t('search.name'),
            dateCreated: i18n.t('search.dateCreated')
        };
        setText('case', caseSearchText);
    };

    return {
        initialize: initialize,
        getText : getText
    };
});
