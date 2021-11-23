({
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

		helper.retrieveItems(cmp, function(){
				helper.retrievePagesTotal(cmp);
			});

        helper.updateOrderByLabel(cmp);
        //helper.retrieveStatusColors(cmp);
        
        var baseURL = $A.get("$Site").siteUrlPrefix;
        cmp.set('v.loginPage', baseURL+'/login');
	},

    handleIdeaFilter: function(cmp, event, helper) {
        var newFilters = event.getParam('filters'),
        	filters = cmp.get('v.filters');

        newFilters.search = filters.search;

        cmp.set('v.filters', newFilters);
        helper.resetPaginationControlls(cmp);
        helper.retrieveItems(cmp, function(){
				helper.retrievePagesTotal(cmp);
			});
    },
    /*Below code is commented on 08-08-2018 for Communities Ideas List Page for moving the 
      Post idea or Join group button to a new component in the header.*/
	/*openCreateDialog: function(cmp) {
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

    joinIdeasGroup: function(cmp) {
        cmp.set('v.showJoinGroupModal', true);
	},*/

	closeCreateDialog: function(cmp) {
		cmp.set('v.showCreateModal', false);
	},

	orderByTrending: function(cmp, event, helper){
		helper.changeOrderBy(cmp, event, 'Trending');
	},

	orderByPopular: function(cmp, event, helper){
		helper.changeOrderBy(cmp, event, 'Popular');
	},

	orderByRecent: function(cmp, event, helper){
		helper.changeOrderBy(cmp, event, 'Recent');
	},

    orderByOldest: function(cmp, event, helper){
        helper.changeOrderBy(cmp, event, 'Oldest');
    },

	searchIdeas: function(cmp, event, helper) {
		var query = cmp.get('v.searchQuery');

		cmp.set('v.filters.search', query);

		helper.resetPaginationControlls(cmp);
		helper.retrieveItems(cmp, function(){
				helper.retrievePagesTotal(cmp);
			});
	},

	openPreviousPage: function(cmp, event, helper) {
		var p = cmp.get('v.currentPage');

		if (p > 1) {
			cmp.set('v.currentPage', p - 1);
			helper.retrieveItems(cmp);
			helper.scrollToTop();
		}
	},

	openNextPage: function(cmp, event, helper) {
		var p = cmp.get('v.currentPage'),
			pagesTotal = cmp.get('v.pagesTotal');

		if (p < pagesTotal) {
			cmp.set('v.currentPage', p + 1);
			helper.retrieveItems(cmp);
			helper.scrollToTop();
		}
	},

	handleOpenIdea: function(cmp, event) {
		var ideaId = event.getParam('id'),
			items = cmp.find('listItem');

		for (var i = 0; i < items.length; i+=1) {
			if (items[i].get('v.showDetails') && items[i].get('v.item.Id') !== ideaId) {
				items[i].set('v.showDetails', false);
			}
		}
	},

	handleIdeaCreated: function(cmp, event) {
		var newIdea = event.getParam('newIdea'),
			items = cmp.get('v.listItems');

		newIdea.Votes = [{Type:'Up'}];
		newIdea.isNew = true;
		items.unshift(newIdea);

		cmp.set('v.listItems', items);
	},

	handleErrorEvent: function(cmp, event) {
		var errorType = event.getParam('type'),
            message = event.getParam('message'),
            loginUrl = cmp.get('v.loginPage'),
			removeMsg = function() {
					if (cmp.isValid()) {
						cmp.set('v.systemMessage', {type: '', body: ''});
					}
				};

		if (errorType === 'auth_required' && (loginUrl && loginUrl !== '')) {
            var hdnLoginBtn = cmp.find('hiddenLoginBtn');

            hdnLoginBtn.getElement().click();

        } else {
            cmp.set('v.systemMessage', {type: 'error', body: message});

            setTimeout($A.getCallback(removeMsg), 5000);
		}
	}
})