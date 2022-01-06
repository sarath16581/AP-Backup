// JavaScript Document

/* Global definition */

var g_url = document.location.href.toLowerCase();
var g_pageName = "";
//var j_pageName = ""; Removed by Ken Shi on 2011-09-13
var g_SBU = "";

/* Define pageName */

// parse breadbrumb to page name 
$('div#breadcrumbs ul').children().each(function() {
	var childHTML = $(this).html().toLowerCase();
	
	// decodes any encoded string
	childHTML = unescape(childHTML).replace(/^\s\s*/, "").replace(/\s\s*$/, "");
	
	// remove link tag wrap
	if(escape(childHTML.search(">")) > 0){
		childHTML = childHTML.substring(childHTML.search(">") + 1, childHTML.search("</a>"));
	}
	
	// build page name based on breadcrumbs
	g_pageName = g_pageName + ":" + childHTML;
});

if(g_pageName != "" && g_pageName != undefined){
	// clean up built page name
	g_pageName = g_pageName.toLowerCase().replace(":home", "auspost");
	
	// set site section have only 4 characters (remove all space)
	var pageName_array = g_pageName.split(":");
	pageName_array[2] = pageName_array[2].toLowerCase().replace(/\s\s*/g, "").substr(0, 4);
	
	// reset page name
	g_pageName = "";
	
	// rebuild page name
	for(var i = 0; i < pageName_array.length; i=i+2){
		g_pageName = g_pageName + ":" + pageName_array[i];
	}
	
	g_pageName = g_pageName.substr(1);
	
	// remove http:// or https://
	if(window.parent.document.location.protocol == "https:")
		g_url = g_url.slice(8);
	else
		g_url = g_url.slice(7);
	
	// build file name when none exists or equals to index.html  
	var url_array = g_url.split("/");
	if(url_array[url_array.length - 1] == "" || url_array[url_array.length - 1] == "index.html")
		g_pageName = g_pageName + ":home page";
}
else // homepage
{
	g_pageName = "auspost:home";
}

/* Define prop15 SBU */

// parse DC.Creator meta tag to SBU
g_SBU = $("meta[name='DC.Creator']").attr("content").toLowerCase();

g_SBU = g_SBU.replace(/^\s\s*/, "").replace(/\s\s*$/, "");
if(g_SBU != "" && g_SBU != "Australia Post" && g_SBU.indexOf("-") > 0){
	var SBU_array = g_SBU.split("-");
	
	g_SBU = SBU_array[1].replace(/^\s\s*/, "").replace(/\s\s*$/, "");
}
else{
	g_SBU = "eservices";
}

s.prop15=g_SBU;
