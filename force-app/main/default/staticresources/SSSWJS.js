var j$ = jQuery.noConflict();

/**
*
*  Base64 encode / decode
*  http://www.webtoolkit.info/
*
**/
var Base64 = {
	
	// private property
	_keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
	
	// public method for encoding
	encode : function (input) {
	    var output = "";
	    var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
	    var i = 0;
	
	    input = Base64._utf8_encode(input);
	
	    while (i < input.length) {
	
	        chr1 = input.charCodeAt(i++);
	        chr2 = input.charCodeAt(i++);
	        chr3 = input.charCodeAt(i++);
	
	        enc1 = chr1 >> 2;
	        enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
	        enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
	        enc4 = chr3 & 63;
	
	        if (isNaN(chr2)) {
	            enc3 = enc4 = 64;
	        } else if (isNaN(chr3)) {
	            enc4 = 64;
	        }
	
	        output = output +
	        this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
	        this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);
	
	    }
	
	    return output;
	},
	
	// public method for decoding
	decode : function (input) {
	    var output = "";
	    var chr1, chr2, chr3;
	    var enc1, enc2, enc3, enc4;
	    var i = 0;
	
	    input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
	
	    while (i < input.length) {
	
	        enc1 = this._keyStr.indexOf(input.charAt(i++));
	        enc2 = this._keyStr.indexOf(input.charAt(i++));
	        enc3 = this._keyStr.indexOf(input.charAt(i++));
	        enc4 = this._keyStr.indexOf(input.charAt(i++));
	
	        chr1 = (enc1 << 2) | (enc2 >> 4);
	        chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
	        chr3 = ((enc3 & 3) << 6) | enc4;
	
	        output = output + String.fromCharCode(chr1);
	
	        if (enc3 != 64) {
	            output = output + String.fromCharCode(chr2);
	        }
	        if (enc4 != 64) {
	            output = output + String.fromCharCode(chr3);
	        }
	
	    }
	
	    output = Base64._utf8_decode(output);
	
	    return output;
	
	},
	
	// private method for UTF-8 encoding
	_utf8_encode : function (string) {
	    string = string.replace(/\r\n/g,"\n");
	    var utftext = "";
	
	    for (var n = 0; n < string.length; n++) {
	
	        var c = string.charCodeAt(n);
	
	        if (c < 128) {
	            utftext += String.fromCharCode(c);
	        }
	        else if((c > 127) && (c < 2048)) {
	            utftext += String.fromCharCode((c >> 6) | 192);
	            utftext += String.fromCharCode((c & 63) | 128);
	        }
	        else {
	            utftext += String.fromCharCode((c >> 12) | 224);
	            utftext += String.fromCharCode(((c >> 6) & 63) | 128);
	            utftext += String.fromCharCode((c & 63) | 128);
	        }
	
	    }
	
	    return utftext;
	},
	
	// private method for UTF-8 decoding
	_utf8_decode : function (utftext) {
	    var string = "";
	    var i = 0;
	    var c = c1 = c2 = 0;
	
	    while ( i < utftext.length ) {
	
	        c = utftext.charCodeAt(i);
	
	        if (c < 128) {
	            string += String.fromCharCode(c);
	            i++;
	        }
	        else if((c > 191) && (c < 224)) {
	            c2 = utftext.charCodeAt(i+1);
	            string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
	            i += 2;
	        }
	        else {
	            c2 = utftext.charCodeAt(i+1);
	            c3 = utftext.charCodeAt(i+2);
	            string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
	            i += 3;
	        }
	
	    }
	
	    return string;
	}

}
        
j$(document).ready(function() {
	// Fix for multi object lookups 
	j$('div.reference').each(function() {
		console.log('hereherehere');
		
		var divElement = j$(this);
		//console.log("divElement.children('select').length: " + divElement.children('select').length);
		if (divElement.children('select').length > 0) {
			//console.log("where is the a: " + divElement.children('span.lookupInput').children('a').attr('href'));
			var lookup = divElement.children('span.lookupInput').children('a').attr('href');
			if (lookup && lookup.indexOf("_lktp") != -1) {
				var newLink = lookup.replace("_lktp","_mlktp");
				divElement.children('span.lookupInput').children('a').attr('href', newLink);
				//console.log("link: " + divElement.children('span.lookupInput').children('a').attr('href'));
			}
		}
	});

	// Putting back styleClasses that APEX removes for some readonly fields
    j$("span.datetime").addClass("form-control input-sm");
    j$("select:disabled").addClass("form-control input-sm");

	// Replace boolean fields that are render in text with checkbox images
    if (j$("span.form-control.boolean").text() == "true") {
        var newHTML = j$("span.form-control.boolean").text().replace('true','<img src="/img/checkbox_checked.gif"/>');
        j$("span.form-control.boolean").html(newHTML);
    } else {
        var newHTML = j$("span.form-control.boolean").text().replace('false','<img src="/img/checkbox_unchecked.gif"/>');
        j$("span.form-control.boolean").html(newHTML);
    }
    j$("span.form-control.input-sm.boolean").removeClass("form-control input-sm");

	// Configuring style classes for reference fields that relate to multiple Objects
    j$("div.reference").removeClass("form-control input-sm");
    j$("span.reference select").addClass("form-control input-sm");
    j$("span.reference input").addClass("form-control input-sm");
    
    // Remove hyperlink from reference fields if text is changed
    j$("input.reference").change(function() {
    	j$(this).removeAttr("ondblclick");
    	j$(this).css("text-decoration", "none");
    });
});

// Handle url field types
function linkClicked(input) {
	
    var patt = new RegExp(/([A-Za-z]+:)+\/\//);
    var check = patt.exec(input.value);
    
    if (check && check.length > 0) {
        var url = input.value;
    } else {
        var url = 'http://' + input.value;
    }
    
    window.open(url, '_blank');
}

// Handle reference field types
var lookupId;
var lookupName;
function referenceDblClicked(input, value) {
	
	if (input) {
		console.log('[referenceDblClicked] input: ' + input.value);
	}
	
	if (value) {
		console.log('[referenceDblClicked] value: ' + value);
		lookupId = value;
		lookupName = input.value;
		sforce.console.getEnclosingPrimaryTabId(openSubtab);
	}
}
function openSubtab(result) {
	//sforce.console.openSubtab(result.id , '/'+lookupId, false, lookupName, null, openSubTabSuccess);
    //sforce.console.openSubtab(result.id , '/'+lookupId, false, '', null, openSubTabSuccess);
    sforce.console.openSubtab(result.id , '/'+lookupId, true, '', null);
}
function openSubTabSuccess(result) {
    if (result.success == true) {
        sforce.console.focusSubtabById(result.id,null);
    } else {
        alert('subtab cannot be opened');
    }
};

// Toggle visibility of block sections
function toggleSection(section) {
    var sectionIcon = document.getElementById(section + '-icon');
    var sectionDisplay = document.getElementById(section).style.display ? document.getElementById(section).style.display : "block";
    
    if (sectionDisplay == "block") {
        document.getElementById(section).style.display = "none";
        sectionIcon.className = "caseDrawerIcon cdCollapsedIcon";
    } else {
        document.getElementById(section).style.display = "block";
        sectionIcon.className = "caseDrawerIcon cdExpandedIcon";
    }
}

// Show saved dialog for caseDetail and caseSummary
function showSavedDialog() {
    var element = document.getElementById('saved-dialog');
    	
    element.className = "show";
   
	setTimeout(function() {
		var o = 1;
		(function fade() {
		    element.style.opacity = o -= 0.1;
		    (o < 0) ? element.className = "hide" : setTimeout(fade,40);
		})();
	}, 2000);
};

var georgeIsALegend_numberOfTabs = 0;
var georgeIsALegend_tabCounter = 0;
function openPrimaryTabByObjectId(objectId){
	if(sforce && sforce.console && sforce.console.isInConsole()){
		sforce.console.getPrimaryTabIds(function(result){
			georgeIsALegend_tabCounter = 0;
			georgeIsALegend_numberOfTabs = result.ids.length;
			georgeIsALegend_checkOpenedTab(result.ids, objectId);
		});
	}
}

function georgeIsALegend_checkOpenedTab(ids, objectId){
	if(georgeIsALegend_tabCounter < georgeIsALegend_numberOfTabs){
		sforce.console.getPageInfo(ids[georgeIsALegend_tabCounter], function(result){
			if(result.pageInfo) {
				var pageInfo = j$.evalJSON(result.pageInfo);
				console.log(pageInfo);
				if(pageInfo) {
					if(objectId.indexOf(pageInfo.objectId) == 0){
						sforce.console.focusPrimaryTabById(ids[georgeIsALegend_tabCounter]);
					} else {
		    			georgeIsALegend_tabCounter++;
		    			georgeIsALegend_checkOpenedTab(ids, objectId);
		    		}
	    		}
	    	}
		});
	} else{
		sforce.console.openPrimaryTab(null, '/' + objectId, true);
	}
}