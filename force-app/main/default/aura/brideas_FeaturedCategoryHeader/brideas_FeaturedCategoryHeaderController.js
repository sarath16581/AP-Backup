({
    init: function(cmp, event, helper){
        helper.retrieveFeaturedCategory(cmp);
        /*Below code is added on 16-08-2018 to retrieve featured category image url 
          and render the image on Ideas List page as part of Communities changes.*/
        helper.retrieveFeaturedCategoryImageUrl(cmp);
    },

    selectCategory: function(cmp){
        var sendMsgEvent = $A.get('e.ltng:sendMessage');

        sendMsgEvent.setParams({
            'message': cmp.get('v.featuredCategory'),
            'channel': 'select_category'
        });

        sendMsgEvent.fire();
    }
})