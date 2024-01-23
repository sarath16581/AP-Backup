({
	doInit: function(cmp, event, helper) {
        helper.setLoggedInUserName(cmp);
		helper.getCommunityUrl(cmp);
        
        /* Added below code on 19/10/2018 for Header and Footer changes for mobile App. */
        /* Comparing the user agent string from mobile App and setting the status to show or hide. */
        var agentString = "";
        //Get the user agent string.
        agentString = navigator.userAgent;
        //Checking the user agent string for iOS or Android.
        if(agentString == 'com.auspost.mobile.ios' || agentString == 'com.auspost.mobile.android'){
            //Set the status to hide.
            cmp.set('v.status', 'hide'); 
        }else{
            //Set the status to show.
            cmp.set('v.status', 'show');
        }
	},
	openMobileMenu: function(cmp, event, helper) {
		$A.util.addClass(cmp.find('mobileNav'), 'is-active');
        cmp.set('v.mobileMenuVisible', true);
	},

	closeMobileMenu: function(cmp, event, helper) {
		$A.util.removeClass(cmp.find('mobileNav'), 'is-active');
		$A.util.removeClass(cmp.find('mobileLogin'), 'is-open');
		$A.util.removeClass(cmp.find('mobileChevron'), 'is-open');
		document.getElementById("mobileLoginButton").setAttribute("aria-expanded", "false");
        cmp.set('v.mobileMenuVisible', false);
	},

	openMobileLogin: function(cmp, event, helper) {
		$A.util.addClass(cmp.find('mobileNav'), 'is-active');
		$A.util.addClass(cmp.find('mobileLogin'), 'is-open');
		$A.util.addClass(cmp.find('mobileChevron'), 'is-open');
		document.getElementById("mobileLoginButton").setAttribute("aria-expanded", "true");
        cmp.set('v.mobileMenuVisible', true);
	},

	toggleMobileLogin: function(cmp, event, helper) {
		$A.util.toggleClass(cmp.find('mobileLogin'), 'is-open');
		$A.util.toggleClass(cmp.find('mobileChevron'), 'is-open');
		
		var loginButton = document.getElementById("mobileLoginButton");
		var x = loginButton.getAttribute("aria-expanded"); 
		if (x === "true") {
			x = "false"
		} else {
			x = "true"
		}
		loginButton.setAttribute("aria-expanded", x);
	},
	openDesktopLogin: function(cmp, event, helper) {
		$A.util.addClass(cmp.find('desktopLogin'), 'is-open');
		document.getElementById("desktopLoginButton").setAttribute("aria-expanded", "true");
	},

	closeDesktopLogin: function(cmp, event, helper) {
		$A.util.removeClass(cmp.find('desktopLogin'), 'is-open');
		document.getElementById("desktopLoginButton").setAttribute("aria-expanded", "false");
	},
	toggleDesktopLogin: function(cmp, event, helper) {
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

	gotoUrl: function(cmp, event, helper) {
		var url = event.target.dataset.url;
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url": url
		});
		urlEvent.fire();
	},
	logout: function(cmp, event, helper) {
		window.location.replace(cmp.get('v.communityUrl') + "/secur/logout.jsp");
	}
})