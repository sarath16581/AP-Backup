({
	doInit: function (cmp, event, helper) {
		var idea = cmp.get('v.item.item');
		cmp.set('v.shortBody', helper.cutText(idea.Body, 400));
	}

})