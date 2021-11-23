({
    doInit: function(cmp, event, helper) {
        var urlVars;
        var filters = event.getParam("filters");

        if (typeof filters !== 'undefined') {
            cmp.set('v.filters', filters);
        }

        urlVars = helper.parseUrlHash();

        cmp.set('v.filters', {
            showBy: {opened: true, mOpened: false, options: '', selected: ''},
            category: {opened: true, mOpened: false, options: '', selected: ''},
            status: {opened: true, mOpened: false, options: '', selected: ''},
            search: ''
        });

        if (typeof urlVars.show !== 'undefined') {
            cmp.set('v.filters.showBy.selected', urlVars.show);
        }

        if (typeof urlVars.category !== 'undefined') {
            cmp.set('v.filters.category.selected', urlVars.category);
        }

        if(typeof urlVars.status !== 'undefined') {
            cmp.set('v.filters.status.selected', urlVars.status);
        }

        helper.initFilterData(cmp);
    },

    toggleFilter: function(cmp, event) {
        var targetEl = event.target,
            target = targetEl ? (targetEl.getAttribute('data-target') || '') : '',
            filters = cmp.get('v.filters');

        if (typeof filters !== 'object' || target === '' || !filters.hasOwnProperty(target)) {
            return;
        }
console.log('target123 ' +target);
        cmp.set('v.filters.' + target + '.opened', !filters[target].opened);
    },

    toggleFilterMobile: function(cmp, event) {
        var targetEl = event.target,
            target = targetEl ? (targetEl.getAttribute('data-target') || '') : '',
            filters = cmp.get('v.filters');

        if (typeof filters !== 'object' || target === '') {
            return;
        }

        for (var fname in filters) {
            if (!filters.hasOwnProperty(fname)) {
                continue;
            }

            if (fname !== target || filters[fname].mOpened) {
                cmp.set('v.filters.' + fname + '.mOpened', false);
            } else {
                cmp.set('v.filters.' + fname + '.mOpened', true);
            }
        }
    },

    selectFilter: function(cmp, event, helper) {
        var targetEl = event.target,
            filterName = targetEl ? (targetEl.getAttribute('data-name') || '') : '',
            newVal = targetEl ? (targetEl.getAttribute('data-value') || '') : '',
            currentVal;

        if (filterName === '') {
            return;
        }

        cmp.set('v.filters.' + filterName + '.mOpened', false);
        currentVal = cmp.get('v.filters.' + filterName + '.selected');

        if (currentVal === newVal) {
            return;
        }

        cmp.set('v.filters.' + filterName + '.selected', newVal);

        var filterEvent = cmp.getEvent('ideasFilterEvent');
        filterEvent.setParams({'filters': cmp.get('v.filters')});
        filterEvent.fire();

        if (filterName === 'category') {
            var sendMsgEvent = $A.get('e.ltng:sendMessage');

            sendMsgEvent.setParams({
                'message': JSON.stringify({category: newVal}),
                'channel': 'brideas_filter'
                });

            sendMsgEvent.fire();
        }
    },

    handleMessage: function(cmp, event, helper) {
        var msg = event.getParam('message');
        var chnl = event.getParam('channel');

        if (chnl === 'select_category') {
            cmp.set('v.filters.category.selected', msg);

            var filterEvent = cmp.getEvent('ideasFilterEvent');
            filterEvent.setParams({filters: cmp.get('v.filters')});
            filterEvent.fire();
        }
    }
})