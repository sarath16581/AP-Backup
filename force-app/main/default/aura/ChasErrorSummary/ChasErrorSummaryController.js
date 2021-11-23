({
	onclick : function(cmp, event, helper) {
		var inputid = event.target.dataset.inputid;
		document.getElementById(inputid).focus();
		document.getElementById(inputid).scrollIntoView({behavior: "auto", block: "center", inline: "nearest"});
		window.scrollBy(0, -50);
	}
})