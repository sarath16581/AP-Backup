({
	init: function(cmp, event, helper){
        cmp.set('v.isVisible', false);
        helper.retrieveFeaturedCategory(cmp);
        helper.initCategoryOptions(cmp);
    },

	handleVisibilityChange: function(cmp){
		cmp.set('v.category', cmp.get('v.activeCategory'));
		cmp.set('v.errorMsg', '');

        var titleInput = cmp.find('ideaTitleInput');
        if (typeof titleInput !== 'undefined') {
            titleInput.focus();
        }
	},

	cancel: function(cmp, event, helper){
        helper.clearAllFields(cmp);
		cmp.set('v.isVisible', false);
	},

	save: function(cmp){
		var action = cmp.get('c.createNewIdea'),
			title = cmp.get('v.title'),
			category = cmp.get('v.category'),
			body = cmp.get('v.bodyText'),
			fieldsValidity = cmp.get('v.fieldsValidity');

		if (!fieldsValidity.title.valid || !fieldsValidity.body.valid || !fieldsValidity.category.valid) {
            cmp.find('ideaTitleInput').showHelpMessageIfInvalid();
            cmp.find('ideaCategorySelect').showHelpMessageIfInvalid();
            cmp.find('ideaBodyInput').showHelpMessageIfInvalid();

            return;
		}

		var fields = {
				community: cmp.get('v.communityName'),
				title:     title,
				body:      body,
				category:  category
			};

        action.setParams({
            fields: fields
        	});

        action.setCallback(this, function(response){
				var state = response.getState(),
					returnVal = response.getReturnValue(),
					successEvent = cmp.getEvent('ideaCreateSuccess');

				cmp.set('v.isSaving', false);

				if (state === 'SUCCESS' && returnVal !== null) {
					cmp.set('v.isVisible', false);

					successEvent.setParams({'newIdea': returnVal});
					successEvent.fire();
				} else {
					var errors = response.getError(),
						msg = 'Unknown error';

					if (errors && errors[0] && errors[0].message) {
						msg = errors[0].message;
					}

					cmp.set('v.errorMsg', msg);
				}

				cmp.set('v.title', '');
				cmp.set('v.category', '');
				cmp.set('v.bodyText', '');
				cmp.set('v.similarIdeas', []);
        	});

        $A.enqueueAction(action);

		cmp.set('v.isSaving', true);
	},

	searchSimilar: function(cmp) {
		var action = cmp.get('c.getSimilarIdeas'),
			title = cmp.get('v.title');

		action.setParams({
            community: cmp.get('v.communityName'),
			title: title
        	});

        action.setCallback(this, function(response){
			var state = response.getState(),
				returnVal = response.getReturnValue();

			if (state === 'SUCCESS') {
				cmp.set('v.similarIdeas', returnVal);
			}
        });

        $A.enqueueAction(action);
	}
})