({
    initCategoryOptions: function(cmp) {
        var action = cmp.get('c.getCategoryOptions'),
            categoryOptions = cmp.get('v.categoryOptions');

        if(categoryOptions && categoryOptions.length > 0) return;

        action.setParams({
            options: {
                source: 'Ideas categories',
                zoneName: ''
            }
        });

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS' && respVal.length > 0) {
                cmp.set('v.categoryOptions', respVal);
            }
        });

        $A.enqueueAction(action);
    },

    retrieveFeaturedCategory: function(cmp) {
        var action = cmp.get('c.getFeaturedCategory');

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS' && respVal && respVal !== '') {
                cmp.set('v.activeCategory', respVal);
                cmp.set('v.isFeatureCategory', true);
            }
        });

        $A.enqueueAction(action);
    },

    clearAllFields: function(cmp){
        cmp.set('v.title', '');
        cmp.set('v.category', '');
        cmp.set('v.bodyText', '');
        cmp.set('v.similarIdeas', []);

        var categorySelect = cmp.find('ideaCategorySelect');
        if (categorySelect !== null) {
            categorySelect.set('v.required', false);
        }

        this.clearFieldsErrors(cmp);
    },

    clearFieldsErrors: function(cmp){
        cmp.set('v.fieldsValidity.title', null);
        cmp.set('v.fieldsValidity.category', null);
        cmp.set('v.fieldsValidity.body', null);
    }
})