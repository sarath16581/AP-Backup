({
    init: function(cmp, event, helper){
        var initialCategory = cmp.get('v.initialCategory');

        if (initialCategory !== null && initialCategory !== '') {
            helper.retrieveCategoryInfo(cmp, initialCategory);
        }
    },

    handleMessage: function(cmp, event, helper){
        var msg = event.getParam('message');
        var chnl = event.getParam('channel');
        var msgObj = JSON.parse(msg);

        if (chnl !== 'brideas_filter') return;

        if (typeof msgObj.category !== 'undefined') {
            helper.retrieveCategoryInfo(cmp, msgObj.category);
        }
    }
})