({
	doInit: function (component, event, helper) {
		helper.getLocalList(component);
	},

	homeClick: function (component) {
		window.location = component.get("v.objClassController").pathPrefix + "/s"; //REQ2963906 included the path prefix if exists
	},

	profileClick: function (component) {
		//REQ2963906 - removed server call and included the path prefix if exists
		window.location =
			component.get("v.objClassController").pathPrefix + "/s/profile/" + component.get("v.objClassController").id;
	},

	logoutClick: function (component) {
		//REQ2963906 - removed server call and included the path prefix if exists
		if (component.get("v.objClassController").retailLogoutURL) {
			window.location = component.get("v.objClassController").retailLogoutURL;
		} else {
			window.location = component.get("v.objClassController").pathPrefix + "/secur/logout.jsp";
		}
	},
});