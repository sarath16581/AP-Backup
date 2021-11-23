({
    retrieveCategoryInfo: function(cmp, category){
        var action = cmp.get('c.getCategoryItem');

        action.setParams({
            categoryName: category
        });
        action.setStorable();
        action.setCallback(this, function(response){
            var state = response.getState(),
                resVal = response.getReturnValue();

            if (state === 'SUCCESS' && resVal !== null && typeof resVal.Name !== 'undefined' && resVal.Name !== '') {
                cmp.set('v.categoryInfo', resVal);
                cmp.set('v.isLoaded', true);
            } else {
                cmp.set('v.categoryInfo', null);
                cmp.set('v.isLoaded', false);
            }
        });

        $A.enqueueAction(action);
    }
})