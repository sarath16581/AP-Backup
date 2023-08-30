/**
 * @changeLog:
 * 2023-08-28 Mahesh Parvathaneni - Added Merchant Portal link in top header 
*/

({
	doInit: function (cmp, event, helper) {
		helper.setLoggedInUserName(cmp);
		helper.getCommunityUrl(cmp);
		helper.getMerchantPortalCookieHandlerProxyUrl(cmp);
	},
	openDesktopLogin: function (cmp, event, helper) {
		$A.util.addClass(cmp.find('desktopLogin'), 'is-open');
		document.getElementById("desktopLoginButton").setAttribute("aria-expanded", "true");
	},

	closeDesktopLogin: function (cmp, event, helper) {
		$A.util.removeClass(cmp.find('desktopLogin'), 'is-open');
		document.getElementById("desktopLoginButton").setAttribute("aria-expanded", "false");
	},
	toggleDesktopLogin: function (cmp, event, helper) {
		$A.util.toggleClass(cmp.find('desktopLogin'), 'is-open');

		var loginButton = document.getElementById("desktopLoginButton");
		var x = loginButton.getAttribute("aria-expanded");
		if (x === "true") {
			x = "false"
		} else {
			x = "true"
		}
		loginButton.setAttribute("aria-expanded", x);
	},
	gotoUrl: function (cmp, event, helper) {
		var communityUrl = cmp.get('v.communityUrl');
		var navigate = cmp.find('bspNavUtil').navigation(communityUrl);
		var link = event.currentTarget.dataset.link;
		
		if (link === 'updateUserDetailsLink') {
			navigate.toUserProfileEditPage();
		} else if (link === 'changePasswordLink') {
			navigate.toChangePasswordPage();
		} else if (link === 'logoutLink'){
			navigate.toLogout();
		} else if (link === 'homeLink' && cmp.get('v.loggedInUserName') != 'Log in'){
			navigate.toHome();
		}
	},
	logout: function(cmp, event, helper) {
		window.location.replace(cmp.get('v.communityUrl') + "/secur/logout.jsp");
	},
	goToMerchantPortal: function(cmp, event, helper) {
		let merchantPortalCookieHdlrProxyUrl = cmp.get("v.merchantPortalCookieHdlrProxyUrl");
		if(merchantPortalCookieHdlrProxyUrl !== null && merchantPortalCookieHdlrProxyUrl !== undefined) {
			window.location.replace(cmp.get('v.merchantPortalCookieHdlrProxyUrl'));
		}
	}
})