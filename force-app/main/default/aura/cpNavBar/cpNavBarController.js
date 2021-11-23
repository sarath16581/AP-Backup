({
    doInit : function(component, event, helper) {
       helper.fetchMenuItems(component);
	},
    
    onClick: function(component, event, helper) {
        var id = event.target.dataset.menuItemId;
        console.log('prnting id' + id);
		if (id) {
			component.getSuper().navigate(id);
		}
	},

	toggleCSS: function(cmp, event) {
		// var cmpTarget = cmp.find('toggleIt');
		// $A.util.toggleClass(cmpTarget, 'cp-mobile-show-menu');

		var aTag = document.getElementById('cp-nav-id');
		aTag.getAttribute('aria-expanded') == 'false' ? aTag.setAttribute('aria-expanded', 'true') : aTag.setAttribute('aria-expanded', 'false');
		aTag.classList.toggle('cp-mobile-show-menu');
	},

	removeCSS: function(cmp, event) {
		// var cmpTarget = cmp.find('toggleIt');
		// $A.util.removeClass(cmpTarget, 'cp-mobile-show-menu');

		var aTag = document.getElementById('cp-nav-id');
		aTag.classList.remove('cp-mobile-show-menu');
		aTag.setAttribute('aria-expanded', 'false');
	}
})