({
	retrieveItems: function(cmp) {
    	var action = cmp.get('c.getIdeas'),
			orderBy = cmp.get('v.orderBy'),
			communityName = ' ',
			itemsPerPage = cmp.get('v.itemsPerPage'),
            filterData = {};

		cmp.set('v.listLoading', true);
		cmp.set('v.listItems', []);

        filterData.search = cmp.get('v.configSearchString');

        action.setParams({
			community:    communityName,
			filterData:   filterData,
			page:         1,
			itemsPerPage: itemsPerPage,
            orderBy:      orderBy
        	});

        action.setCallback(this, function(response){
				var state = response.getState(),
					resVal = response.getReturnValue();

				if (state === 'SUCCESS') {
					cmp.set('v.listItems', resVal);
				}

				cmp.set('v.listLoading', false);
        	});

        $A.enqueueAction(action);
	}
})