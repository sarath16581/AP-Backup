({
    init : function(cmp, event, helper) {
        var pageURL = decodeURIComponent(window.location.search.substring(1));
        var urlParams = pageURL.split('&');
        var param;
        var token = '';
        var action = '';
        var id = '';

        for (var i = 0; i < urlParams.length; i++) {
            param = urlParams[i].split('=');

            if (param.length === 2 && param[0] === 'token') {
                token = param[1];
            }

            if (param.length === 2 && param[0] === 'ideaId') {
                id = param[1];
            }

            if (param.length === 2 && param[0] === 'action') {
                action = param[1];
            }
        }

        if (action === 'unsubscribe' && id !== '') {
            helper.unsubscribeFromIdea(cmp, id);
        }

        if (action === 'unsubscribeall') {
            helper.unsubscribeFromAll(cmp);
        }
    }
})