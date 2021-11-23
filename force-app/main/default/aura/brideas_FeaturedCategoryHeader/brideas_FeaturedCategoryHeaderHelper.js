({
    retrieveFeaturedCategory: function(cmp) {
        var action = cmp.get('c.getFeaturedCategory');

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS' && respVal && respVal !== '') {
                cmp.set('v.featuredCategory', respVal);
                cmp.set('v.isLoaded', true);
            }
        });

        $A.enqueueAction(action);
    },
    /*Below code is added on 16-08-2018 to retrieve featured category image url 
      and render the image on Ideas List page as part of Communities changes.*/
    retrieveFeaturedCategoryImageUrl: function(cmp) {
        var action = cmp.get('c.getFeaturedCategoryImageUrl');

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS' && respVal && respVal !== '') {
                cmp.set('v.featuredCategoryImageUrl', respVal);
                cmp.set('v.isLoaded', true);
            }
        });

        $A.enqueueAction(action);
    }
})