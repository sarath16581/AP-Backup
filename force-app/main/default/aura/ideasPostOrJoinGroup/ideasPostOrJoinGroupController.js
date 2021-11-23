({
    /* Function to set the common variables, retrieve user info and set the filter parameters initially */
	doInit: function(cmp, event, helper) {
        var urlVars = helper.parseUrlHash();
        helper.initCommonVars(cmp);
		helper.retrieveUserInfo(cmp);
        if (urlVars.idea_theme) {
			cmp.set('v.filters.idea_theme', urlVars.idea_theme);
		}

        if (typeof urlVars.show !== 'undefined' || typeof urlVars.category !== 'undefined' || typeof urlVars.status !== 'undefined') {
            cmp.set('v.filters', {
                showBy: {mOpened: true, options: '', selected: urlVars.show},
                category: {mOpened: false, options: '', selected: urlVars.category},
                status: {mOpened: false, options: '', selected: urlVars.status},
                search: ''
            });
        } else {
            cmp.set('v.filters', {
                showBy: {mOpened: true, options: '', selected: ''},
                category: {mOpened: false, options: '', selected: ''},
                status: {mOpened: false, options: '', selected: ''},
                search: ''
            });
		}
	},
    
    /* Function to check the user type and set the parameters */
    openCreateDialog: function(cmp) {
		var userInfo = cmp.get('v.userInfo');
		var authorizationMessage =  $A.get('$Label.c.msgAuthorizationRequired');

		if (userInfo && userInfo.Type !== '' && userInfo.Type !== 'Guest') {
			cmp.set('v.showCreateModal', true);
		} else {
			var errEvt = cmp.getEvent('ideasErrorEvent');
			errEvt.setParams({'type':'auth_required', 'message': authorizationMessage});
			errEvt.fire();
		}
	},

    /* Function to set the show join group modal to true */
    joinIdeasGroup: function(cmp) {
        cmp.set('v.showJoinGroupModal', true);
	},

    /* Function to set the show create modal to true */
	closeCreateDialog: function(cmp) {
		cmp.set('v.showCreateModal', false);
	}
})