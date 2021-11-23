/* ########################################################################### *
/* ***** DOCUMENT INFO  ****************************************************** *
/* ########################################################################### *
 * ##### NAME:  global.js
 * ##### VERSION: v1.1
 * ##### UPDATED: 27/07/2010 (Damian Keeghan - Deloitte's Online Practice)
 * ##### UPDATED: 13/09/2010 (Ken Shi - update init_faqs() function)
 * ##### UPDATED: 27/09/2010 (Ken Shi - update init_faqs() function)
 * ##### UPDATED: 01/10/2010 (Ken Shi - update rotatingBanner() function)
 * ##### UPDATED: 14/09/2011 (George Hiley - Deloitte Online - Design refresh)
 * ##### UPDATED: 06/02/2012 (George Hiley - Deloitte Online - Design refresh)
/* ########################################################################### *

/* ########################################################################### *
/* ***** INDEX *************************************************************** *
/* ########################################################################### *
/* ##### GLOBAL VARIABLES
/* ##### INITIALISATION
/* ##### CUSTOM
/* ##### CSS3 HELPER
/* ##### TOOLTIPS
/* ##### ACCESSIBLE TOOLTIPS (WCAG LEVEL AAA)
/* ##### COOKIES
/* ##### SCROLL TO
/* ##### BG IFRAME
/* ########################################################################### */

/* ########################################################################### *
/* ##### GLOBAL VARIABLES
/* ########################################################################### */


var STATIC_ANIMATION = false;

/* ########################################################################### *
/* ##### INITIALISATION
/* ########################################################################### */

$(document).ready(init_global);

function init_global()
{ 
  // Helpers
  init_classHelpers();

  // Tooltips
	init_tooltips();
	
  // IE
  init_ie();
  
  // Slider
  init_slider();
  
  // Forms
  init_global_forms();

  // Tables
  init_tables();  
  
  // Search drop down
  init_search();
  
  // Expando Collapso
  // init_expandoCollapso();
  
  // Expando Collapso
  init_expandoCollapso_faq();  
  
  // Accessibility
  init_accessibility();
  
	// Body related scripts
  init_body(); 
  
  // Newsletter form
  init_forms_newsletter();
}


/* ########################################################################### *
/* ##### CUSTOM
/* ########################################################################### */

/*
 * Misc body / global
 *
 */
 
function init_body()
{
  // Random display one of the hero promo messages
  if ($('.hero .promo-banner .content-message').length > 1) {
    $('.hero .promo-banner .content-message').addClass('hidden').removeClass('visuallyhidden');
    var rand = Math.floor(Math.random() * ($('.hero .promo-banner .content-message').length));
    $('.hero .promo-banner .content-message').eq(rand).removeClass('hidden');
  }

  // Check height of right column and adjust main content height if required
  if ($('#quick-links').length > 0) {
    _rightColHeight();
    setInterval(_rightColHeight, 2000);
  }
  
  // Top links
  if ($('a.top').length > 0) {
    $('a.top').click(function() {
      $.scrollTo(0, 500);
      return false;
    });
  }
  
  // Breadcrumbs
  if ($('#breadcrumbs').length > 0) {
    /*
    $('#breadcrumbs').css('opacity', 0.6);
    $('#breadcrumbs').hover(function() 
    {
      $(this).fadeTo('fast', 1);
    }, 
    function() 
    {
      $(this).fadeTo('fast', 0.6);
    });
    */
  }
}

function _rightColHeight() {
  
  // Check if there is an element that we need to offset
  var offset = 0;
  if ($('.hero-image').length > 0) {
    offset = $('.hero-image').height() - 150;
  }
  
  // Grab the height, subtract the offset
  var height = $('#quick-links').outerHeight();
  height = (height - offset);
  
  // Set the min-height of #main content area
  $('#main').css('min-height', height);
  
  // Hack for ie6
  if ($('.ie6').length > 0) {
    $('#main').css('height', height);
  }  
}

 
/*
 * Slider
 *
 * NB: The slider's "preload: true" appears to break on various modules in IE8 hence has been removed.
 */
function init_slider()
{
  $('.js_slider').not('.fn_isInitialised').each(function()
  {
    // Check if this is a products slider module
    if ($(this).parents('.module-products').length > 0)
    {
      $(this).slides({
  			generateNextPrev: true,
  			slideSpeed: 500
  		});
  		$(this).addClass('fn_isInitialised');
    }
    else
    {
  		$(this).slides({
  			generateNextPrev: false,
  			play: 4000,
  			slideSpeed: 500,
  			hoverPause: true
  		});
  		$(this).addClass('fn_isInitialised');  		
    }
  });  
}

 
/*
 * Forms
 *
 */
function init_global_forms() { 

  // Rework for tools with Java Spring framework not supporting placeholder attribute
  if ($('.page-tools').not('.page-general').length > 0) {

    // Setup focus / blur events to handle placeholder text (only on #main)
    $('#main input[type="text"]').filter('[title]').not('.fn_placeholder_wired').focus(function() {
  	  var input = $(this);
  	  if (input.val() == input.attr('title')) {
  		input.val('');
  		input.removeClass('placeholder');
  	  }
  	}).blur(function() {
  	  var input = $(this);
  	  if (input.val() == '' || input.val() == input.attr('title')) {
  		input.addClass('placeholder');
  		input.val(input.attr('title'));
  	  }
  	}).addClass('fn_placeholder_wired');
  	
  	$('#main input[type="text"]').filter('[title]').blur();
  	
  	// Clear on form submit
  	$('#main input[type="text"]').filter('[title]').parents('form').submit(function() {
  	  $(this).find('input[type="text"]').filter('[title]').each(function() {
    		var input = $(this);
    		if (input.val() == input.attr('title')) {
    		  input.val('');
    		}
  	  });
  	});  
  }

  // Handle HTML5 input placeholder text
  if(!Modernizr.input.placeholder) {
  	$('[placeholder]').focus(function() {
  	  var input = $(this);
  	  if (input.val() == input.attr('placeholder')) {
  		input.val('');
  		input.removeClass('placeholder');
  	  }
  	}).blur(function() {
  	  var input = $(this);
  	  if (input.val() == '' || input.val() == input.attr('placeholder')) {
  		input.addClass('placeholder');
  		input.val(input.attr('placeholder'));
  	  }
  	}).blur();
  	$('[placeholder]').parents('form').submit(function() {
  	  $(this).find('[placeholder]').each(function() {
  		var input = $(this);
  		if (input.val() == input.attr('placeholder')) {
  		  input.val('');
  		}
  	  })
  	});
  }
}


/*
 * Tables
 *
 * 
 */
function init_tables() 
{
  // Table results listings, enable hover and click to fire the first <a> element.
  // This script should be executed before less global scripts which may prefer to unbind and manually handle the 'click' event.

  $('.fn_tableResultsList').each(function()
  {
    // Handle each tr
    $(this).find('tbody tr').not('.noLink').each(function() 
    {

      // If this tr has a link, handle hover and click
      if ($(this).find('a').length > 0)
      {
      
        // Wire click events
        $(this).click(function()
        {    
          // Go to the first <a> href
          location.href = $(this).find('a:first-child').attr('href');
        });    
          
        // Handle hover event
        $(this).hover(
          function() 
          {
            $(this).addClass('hover');
          }, 
          function()
          {
            $(this).removeClass('hover');
          }
        );  
            
      }

    });

  });


/*
 * Tables: Currency Convert
 * Currency converter table hover / click, handles showing details.
 * 
 */
 
  $('.fn_tableCurrencyList').each(function()
  { 
    // Remove any binded click events
    $(this).find('tbody tr').unbind('click');
    
    // Prevent click on <a> elements
    $(this).find('tbody tr.new a').bind('click', function(event) 
      {
        $(this).parents('tr.new:first').trigger('click');
        $(this).blur();
        return false;
      });

    // Hide rows
    $(this).find('tbody tr.grey').hide();

    // Wire click events
    $(this).find('tbody tr.new').click(function()
    {
      // Get the target ID
      var targetHref = $(this).find('a:first').attr('href');
      targetHref = targetHref.substring(targetHref.indexOf('#'));
      
      var results = $(this).parents('.tools-step:first');
      
      // Hide rows
      $(results).find('tr.grey').hide();
      
      // If already visible it should hide...
      if ($(targetHref).hasClass('active')) {

        // Hide all open results
        $(results).find('.resultsList .active').removeClass('active');
        
        // Change close btns to view 
        $(results).find('.moreInfo a').each(function() {
          $(this).html($(this).attr('title'));
        });
      }
      else
      {
        // Hide all open results
        $(results).find('.resultsList .active').removeClass('active');
        
        // Change close btns to view 
        $(results).find('.moreInfo a').each(function() {
          $(this).html($(this).attr('title'));
        });
        
        // Show target
        $(this).addClass('active');
        $(targetHref).addClass('active');
        
        //$(this).next('.grey td').show();
        // Hide rows
        $(this).next('tr.grey').addClass('active').show();
        
        // Change view btn to close 
        $(this).find('.moreInfo a').html('Close');
      }
      
      
    });
  });

/*
 * Tables: Post Code search results
 * Table hover / click, handles showing post code map links, more / pagination, enable single result to go move to next page
 * 
 */
 
  $('.fn_tablePostcodeList').each(function()
  { 
    var PAGING_COUNT = 20;
    
    // Hide results
    $('#app_results.pcs .resultsDetails').hide();
  
    // Remove any binded click events
    $(this).find('tbody tr').unbind('click');

    // Add more pagination link if there are more than PAGING_COUNT results
    if ($(this).find('tbody tr').length > PAGING_COUNT)
    {
      // Hide all results after PAGING_COUNT
      $(this).find('tbody tr:nth-child(' + PAGING_COUNT + ')').nextAll('tr').hide().addClass('hidden');
      
      // Create and wire more results button
      $(this).after('<a href="#" class="btn secondary btn-more">Display more results</a>');
      
      // Display the next results
      $(this).next('.btn-more').click(function() {
        
        var hiddenNodes = $(this).prev('.fn_tablePostcodeList').find('tbody tr.hidden');
        for (var x = 0; x < PAGING_COUNT; x++)
        {
          $(hiddenNodes).eq(x).removeClass('hidden').show();
        }
        
        // Check if there are any more to display
        if ($(this).prev('.fn_tablePostcodeList').find('tbody tr.hidden').length < 1)
        {
          // Hide the button, no more hidden results
          $(this).hide();
        }
        
        return false;
      });
    }

    // Wire click events
    $(this).find('tbody tr').click(function()
    {
      // Get the target ID
      var targetHref = $(this).find('a:first').attr('href');
      targetHref = targetHref.substring(targetHref.indexOf('#'));
      
      var results = $(this).parents('.tools-step:first');
      
      // Hide all post code details
      $(results).find('.resultsDetails ol > li').hide();
      
      // Show the targeted post code details (although the div.resultsDetails wrapper is still hidden from the display)
      $(results).find(targetHref).show();
      
      // Insert the Post code map (if we haven't already done so)
      $('#gmap').remove();
      $(results).find(targetHref).append('<div id="gmap" class="map"></div>');
      
      
      // Hide the results list table / transition page
      $(results).addClass('module-loading');
      $(results).find('.resultsList').slideUp('slow', function() 
      {
        // Show the results details
        $(results).find('.resultsDetails').slideDown('slow', function() 
        { 
          /* Setup Google Map */
          var location = $(results).find(targetHref + ' .postcodeDetails .location h4').html();          
          var address = location + ' ' + ' australia';
          // alert(address);

          _insertGmap(address);

          $(this).parents('.module-loading').removeClass('module-loading');
        });
      });
      
      // Update the action links
      $(results).find('.module-actions .module-actions-default').fadeOut('slow', function()
      {
        $(results).find('.module-actions').append('<div class="module-actions-js hidden"><a href="#" class="btn-print">Print</a> <a href="#" class="btn-backToResults">Back to results</a></div>');
        $(results).find('.module-actions .module-actions-js').hide().removeClass('hidden').fadeIn('slow');

        // Wire up action links
        $(results).find('.btn-print').click(function() { window.print(); return false; });
        
        $(results).find('.btn-backToResults').click(function() {
  
          // Hide the results details / transition page
          $(results).addClass('module-loading');
          $(results).find('.resultsDetails').slideUp('slow', function() 
          {
            // Show the results list table
            $(results).find('.resultsList').slideDown('slow', function() 
            {
              $(this).parents('.module-loading').removeClass('module-loading');
            });
          });
          
          // Revert actions links back to original
          $(results).find('.module-actions .module-actions-js').fadeOut('slow', function() 
          { 
            $(this).remove();
            $(results).find('.module-actions .module-actions-default').fadeIn('slow'); 
          });
          
          return false;
        });
      });
      
      return false;
    });
  
  });  
  
  // Handle single result list
  if ($('#app_results .postcodeList').length > 0 && $('#app_results .fn_tablePostcodeList').length == 0) {
    if ($('#app_results .postcodeList > li').length == 1) {
      
      // Insert the Post code map (if we haven't already done so)
      $('#gmap').remove();
      $('#app_results .postcodeList > li:first').append('<div id="gmap" class="map"></div>');
      
      /* Setup Google Map */
      var location = $('#app_results .postcodeList > li .postcodeDetails .location h4').html();          
      var address = location + ' ' + ' australia';
      // alert(address);

       _insertGmap(address);    
    }
  }
}

/*
 *  Insert a Google Map
 *
 */
function _insertGmap(address) {  
  if ($('.ie6').length > 0) {
    $('#gmap').html('<img src="http://maps.googleapis.com/maps/api/staticmap?center=' + address + '&zoom=14&size=643x480&sensor=false">');
  }
  else
  {

    // Set via lat long (also remove geocoder below if using lat long)
    // var myLatlng = new google.maps.LatLng(-34.397, 150.644);
    
    var map;            
    var myOptions = {
      zoom: 13,
      //center: myLatlng,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    map = new google.maps.Map(document.getElementById("gmap"), myOptions);
  
    // Remove geocoder code to enable lat long above
    var geocoder = new google.maps.Geocoder();         
    geocoder.geocode( { 'address': address}, function(results, status) {
      if (status == google.maps.GeocoderStatus.OK) {
        map.setCenter(results[0].geometry.location);
      } else {
        // alert("Geocode was not successful for the following reason: " + status);
        // Remove the map
        $('#gmap').remove();
      }
    });
    
    //var ctaLayer = new google.maps.KmlLayer('http://gmaps-samples.googlecode.com/svn/trunk/ggeoxml/cta.kml');
    //ctaLayer.setMap(map);
  }
  
}

/*
 * Search results
 *
 * 
 */
function init_search()
{
  $('.nav-search .input-txt').keyup(function()
  {
    // On keyup, if there is contents in the search input, display drop down search results.
    // NB: Likely requires adjustment in dev with ajax integration.
    if ($(this).val().length > 0) {
      $(this).siblings('.list-nav').addClass('list-nav-visible');
      
      // Fix display bug in IE7
      if ($('html.ie7').length > 0) {
        $(this).siblings('.list-nav li:last button').css('display','block');
      }
    }
    else
    {
      $(this).siblings('.list-nav').removeClass('list-nav-visible');
    }
  });
  
  $('.nav-search .input-txt').bind('blur', function()
  {
    $(this).siblings('.list-nav').removeClass('list-nav-visible');
  });  
}

/*
 * FAQ EXPANDO COLLAPSO
 * 
 */
function init_expandoCollapso_faq()
{
  // Parse .faq-expando-collapso objects
  var wrapper = '.faq-expando-collapso';
  var trigger = '.faq-title';
  var target  = '.faq-content';
  
  // Get the target object class
  $(wrapper).each(function() {
    
    // Setup each trigger
    $(this).find(trigger).each(function() {
      
      // Hide the target if the trigger is not marked as active
      if ($(this).hasClass('active'))
      { 
        // Display the target
        $(this).next(target).removeClass('hidden');
      }
      else
      {
        // Hide the target
        $(this).next(target).hide().removeClass('hidden');
      }
      
      // Wire up the click
      $(this).click(function()
      {
        // Toggle active state of this element
        $(this).toggleClass('active');
        
        // Check if is now active
        if ($(this).hasClass('active'))
        {
          // Is active so show
          $(this).next(target).show();
        }
        else
        {
          // Is not active so hide
          $(this).next(target).hide();
        }
        
        // Prevent click
        return false;
      });
 
    });
  });
}


/*
 * IE
 *
 */
function init_ie()
{
  // IE6, IE7 and IE8 tweaks
  if ($('html.ie6, html.ie7, html.ie8').length > 0) {  
  
    // Menu / drop-down bg-iframe fix
    $('#nav-primary .list-nav .module-inner, .nav-search .list-nav .module-inner').bgiframe();
    
    // Last child
    $('.list-nav li:last-child, .shop-header-tools li:last-child, .shop-product:last-child, .module-promo:last-child').addClass('last');
    
    // Hero promo banner IE wedge
    $('.hero .promo-banner').append('<div class="corner"></div>');
    
    // Rounded corners
    init_roundedCorners();
  }

  // IE6 & IE7  
  if ($('html.ie6, html.ie7').length > 0) {  
  
    // Handle primary navigation li:focus / li:hover
    if ($('#nav-primary li').length > 0) {
      $('#nav-primary li').hover(function() 
      { 
        $(this).addClass('hover');
        $(this).find('.list-nav').show();
      }, function() 
      {      
        $(this).removeClass('hover'); 
        $(this).find('.list-nav').hide();
      });
    }  

    // Misc class fixes
    $('.stamps-sub-heading:first-child').addClass('stamps-sub-heading-first');
    
  }

  // IE6 only
  if ($('html.ie6').length > 0) {  
  
    // Set width of hero image and overlay strip
    $('#header-container .overlay, #header-container .hero-image').width($(window).width());
    // Bind to window resize
    $(window).resize(function() {
      $('#header-container .overlay, #header-container .hero-image').width($(window).width());    
    });
   
    // First child
    $('.shop-product:first-child, .footer-bottom li:first-child, #nav-top li:first-child').addClass('first');
    $('.shop-product:first-child').addClass('shop-product-first');
    $('.callout-row .module-promo:first-child').addClass('module-promo-first');
    $('#footer-container .column:first-child').addClass('column-first');
    
    // Checkbox & inputs
    init_ie_ie6_inputs()
    
    // PNG fix
    DD_belatedPNG.fix('.promo-banner, .corner');
  }
}

// Checkbox & inputs
function init_ie_ie6_inputs() {
  $('input[type="checkbox"]').addClass('input-checkbox');
  $('input[type="radio"]').addClass('input-radio');
}


/*
 * Rounded corners
 *
 */
 
function init_roundedCorners() {

  $('.module').each(function() {
    
    // Added tweaks for IE corners, excluding various modules if not required / avoided.
    if (!$(this).hasClass('js_slider')) {
      $(this).addClass('module-corners');
      
      // Only add if not already exist
      if ($(this).next('.module-corner-bottom').length < 1) {
        $(this).after('<div class="module-corner-bottom"><div class="module-corner-bottom-right"></div></div>');
      }
    }
  });
}


/*
 * Accessibility 
 *
 */
 
function init_accessibility() {
  
  /* Enable primary nav display on keyboard focus */
  if ($('#nav-primary li').length > 0) {
  
    // Enable turning off menu. 
    // If user tabs into menu but clicks out drop down will remain visible. This enables a mouse hover to hide.
    $('#nav-primary li').hover(function() 
    { 
      $(this).addClass('hover');
      $(this).find('.list-nav').show();
    }, function() 
    {      
      $(this).removeClass('hover'); 
      $(this).find('.list-nav').hide();
    });
  
    // Enable tab navigation to display menu
    $('#nav-primary li a.btn-home, #nav-primary li a.btn-personal, #nav-primary li a.btn-business').focus(function() { 
      $(this).parents('li:first').siblings('li').removeClass('hover');
      $(this).parents('li:first').siblings('li').find('.list-nav').hide();        
      $(this).parents('li:first').addClass('hover');
      $(this).parents('li:first').find('.list-nav').show();     
    });
    
    // Turn off business drop down if tab to search
    $('.nav-search input').focus(function() {
      $('#nav-primary li').removeClass('hover');
      $('#nav-primary li').find('.list-nav').hide(); 
    });
  }
} 


/*
 * Newsletter subscribe form 
 *
 */

function init_forms_newsletter() {
  if ($('.form-newsletter').length > 0) {
    $('.form-newsletter input[type="submit"]').click(function () {
    
      // Clear validation
      $('.form-newsletter input.input-error').removeClass('input-error');
      $('.form-newsletter .errors').remove();
      //$('.form-newsletter .errors').fadeOut(500, function() {

        // Validate fields
        var valid = true;
        $('.form-newsletter .fn_isValid_name').each(function () {
          if ($(this).val() == '' || $(this).val() == $(this).attr('title') || $(this).val().length > 80) {
            $(this).addClass('input-error');
            $(this).parents('p:first').after('<p class="errors">Please enter your name</p>');
            valid = false;
          }
        });
  
        $('.form-newsletter .fn_isValid_email').each(function () {
          if ($(this).val() == '' || $(this).val() == $(this).attr('title') || $(this).val().length > 80) {
            $(this).addClass('input-error');          
            $(this).parents('p:first').after('<p class="errors">Please enter a valid email address</p>');
            valid = false;
          }
          else
          {
            var reg = /^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/;
            var address = $(this).val();
            if(reg.test(address) == false) {          
              $(this).addClass('input-error');            
              $(this).parents('p:first').after('<p class="errors">Please enter a valid email address</p>');
              valid = false;
            }          
          }
        });
              
        if (!valid) return false;
      //});
    });
  }
}


/* ########################################################################### *
/* ##### CSS3 HELPER
/* ########################################################################### */

function init_classHelpers(){
	$("body").removeClass("noJS");
	
	if(isIE(6, true)){
		STATIC_ANIMATION = true;
		init_ie6_classes();
	} else if(isIE(8, true)){
		init_ie8_classes();
	}
}

function init_ie6_classes(){
	init_ie8_classes();
	
	//list item
	$("li:first-child").each(function(){
		if($(this).hasClass("active")){
			$(this).addClass("first_active");					
		};
		$(this).addClass("first");
	});
	
	//column
	$(".column:first-child").addClass("first");
	
	//replacement for >
	$(".fn_childItems > li").addClass("childItem");
	
	fn_ie_jumpfix();
	
	$(".button").each(function(){
		var button = $(this);
		var hoverClass = "hover";
		
		if($(button).hasClass("primary")){
			hoverClass += " hover_primary";				
		} else if($(button).hasClass("secondary")){
			hoverClass += " hover_secondary";				
		} else if($(button).hasClass("tertiary")){
			hoverClass += " hover_tertiary";				
		} else if($(button).hasClass("search")){
			hoverClass += " hover_search";				
		}
		
		$(button).hover(function(){
			$(this).addClass(hoverClass);						
		}, function(){
			$(this).removeClass(hoverClass);
		});
	});
}

function fn_ie_jumpfix() {
  // Only effect the really good browsers
  if ($('.ie6, .ie7').length > 0) {
  
    $('.fn_ie_jumpfix, .tools-step .actions').each(function() {    
      if ($(this).prev('.jumpfix').length > 0) {
        $(this).prev('.jumpfix').remove();
      }
      $(this).before("<div class=\"jumpfix\"></div>");
    });
    
  	setTimeout(function(){
  		$(".fn_ie_jumpfix, .tools-step .actions").css("zoom", "1");					
  	}, 100);
  }
}

function init_ie8_classes(){
	//IE8 and IE7 both handle :first-child 
	//but don't support last-child
	
	//list item
	$("li:last-child").each(function(){
		if($(this).hasClass("active")){
			$(this).addClass("last_active");					
		};
		$(this).addClass("last");
	});
	
	//column
	$(".column:last-child").addClass("last");
	
	//table alt styles
	$("table tbody tr:even").each(function(){
		$(this).addClass("alt");
	});
	
	//remove captions from screen if required
	$("table caption.offscreen").each(function(){
		var html = $(this).html();
		$(this).html("<span class=\"offscreen\">"+html+"</span>");
	});
}


/* ########################################################################### *
/* ##### TOOLTIPS
/* ########################################################################### */

function init_tooltips(){
	if($("a.fn_tooltip").length>0){
		$("a.fn_tooltip").accessibleTooltip({
			speed: 250
		});
	}
	
	if($("a.fn_infotip").length>0){
		$("a.fn_infotip").accessibleTooltip({
			speed: 250,
			buttonStyle: "infotip"
		});
	}
}


/* ########################################################################### *
/* ##### ACCESSIBLE TOOLTIPS (WCAG LEVEL AAA)
/* ########################################################################### */

/**
 * jQuery.accessibleTooltip - Accessible Tooltip Plugin.
 * Copyright (c) 2009-2010 Damian Keeghan - dkeeghan@deloitte.com.au
 * Date: 02/02/2010
 * @author Damian Keeghan
 * @version 1.0
 *
 */

(function($){
	//creates an accessibleTooltip from an A tag
	$.fn.accessibleTooltip = function(options){
		var defaults = {
			speed: 250,
			labelText: function(btn){
				return $(btn).parent().find("label, .label").text().replace("*", "");	
			},
			helpPrefix: "Help text for",
			leftOffset: 15,
			topOffset: -1,
			buttonStyle: "tooltip",
			tooltipStyle: "tooltip",
			onShow: function(btn, tooltipDiv){
				$(tooltipDiv).animate({opacity: 1}, 0);	
			}
		};
		
		var options = $.extend(defaults, options);

		return this.each(function(){
			var aTooltip = $(this);
			
			var label = options.labelText($(aTooltip));

			var helpText = $(aTooltip).attr("title");
			
			if(helpText==""){
				$(aTooltip).remove();
			} else {
				$(aTooltip).after("<button type=\"button\" class=\"fn_tooltip "+options.buttonStyle+"\">"+options.helpPrefix+" "+label+"</button>");
				
				var tooltip = $(aTooltip).parent().find("button.fn_tooltip");
				$(tooltip).data("isClicked", false);
				
				$(aTooltip).remove();
				
				var tooltipContent = "<div class=\""+options.tooltipStyle+"\" style=\"display: none\"><h3 style=\"position: absolute; left: -99999px\">Help for "+label+"</h3><p>"+helpText+"</p><span style=\"position: absolute; left: -99999px\">End help</span></div>";
				$(tooltip).after(tooltipContent);
				
				var tooltipDiv = $(tooltip).parent().find("div."+options.tooltipStyle);
	
				$(tooltip).unbind("click").bind("click", function(e){
					e.preventDefault();
					
					if($(tooltip).data("isClicked")==false){
						$(tooltip).data("isClicked", true);
						setPosition(tooltip, tooltipDiv);
						
						if(options.speed==0){
							$(tooltipDiv).show();
							options.onShow($(aTooltip), $(tooltipDiv));
						} else {
							$(tooltipDiv).fadeIn(options.speed, function(){
								options.onShow($(aTooltip), $(tooltipDiv));										 
							});
						}
					} else {
						if(options.speed==0){
							$(tooltipDiv).hide();
							$(tooltip).data("isClicked", false);
						} else {
							$(tooltipDiv).fadeOut(options.speed, function(){
								$(tooltip).data("isClicked", false);
							});
						}
					}
					
					return false;
				});
				
				$(tooltip).bind("focus mouseover", function(){
					if($(tooltip).data("isClicked")==false){
						setPosition(tooltip, tooltipDiv);
						
						if(options.speed==0){
							$(tooltipDiv).show();
							options.onShow($(aTooltip), $(tooltipDiv));
						} else {
							$(tooltipDiv).fadeIn(options.speed, function(){
								options.onShow($(aTooltip), $(tooltipDiv));
								setPosition(tooltip, tooltipDiv);								   
							});
						}
					}
				});
				
				$(tooltip).bind("blur mouseout", function(){
					if($(tooltip).data("isClicked")==false){
						if(options.speed==0){
							$(tooltipDiv).hide();
						} else {
							$(tooltipDiv).fadeOut(options.speed);
						}
					}
				});	
				
				$(window).resize(function(){
					if($(tooltip).data("isClicked")==true){
						setPosition(tooltip, tooltipDiv);	
					}
				});
			}
		});
		
		function setPosition(tooltip, tooltipDiv){
			var tooltipDimensions = {top: $(tooltip).position().top, left: $(tooltip).position().left, width: $(tooltip).width(), height: $(tooltip).height()}
			
			var tooltipDivHeight = $(tooltipDiv).height();
			
			var tooltipDivLeftPos = (tooltipDimensions.left + tooltipDimensions.width + options.leftOffset);
			var tooltipDivTopPos = tooltipDimensions.top + options.topOffset + $(tooltip).parents(".resultsWindow").scrollTop();
			
			$(tooltipDiv).css({top: tooltipDivTopPos, left: tooltipDivLeftPos});
		}
	};
	
	$.fn.resetAccessibleTooltip = function(options){
		var defaults = {
			speed: 250,
			tooltipStyle: "tooltip"
		};
		
		var options = $.extend(defaults, options);
		
		return this.each(function(){
			var tooltip = $(this);

			var tooltipDiv = $(tooltip).parent().find("div."+options.tooltipStyle);
			
			if(options.speed==0){
				$(tooltipDiv).hide();
				$(tooltip).data("isClicked", false);
			} else {
				$(tooltipDiv).fadeOut(options.speed, function(){
					$(tooltip).data("isClicked", false);
				});
			}						   
		});	
	}
})(jQuery);

/* ########################################################################### *
/* ##### UTIL FUNCTIONS
/* ########################################################################### */

function isIE(version, lessThan){
	version = (version==undefined) ? 6 : version;
	lessThan = (lessThan==undefined) ? false : lessThan;
	
	if(lessThan){
		if (($.browser.msie)&&(parseInt($.browser.version)<=version)){
			return true;
		}
	} else {
		if (($.browser.msie)&&(parseInt($.browser.version)==version)){
			return true;
		}
	}
	
	return false;	
}

(function($){
	//Gets url query string params
	$.query = function(s) {
		var r = {};
		if (s) {
				var q = s.substring(s.indexOf('?') + 1); // remove everything up to the ?
				q = q.replace(/\&$/, ''); // remove the trailing &
				$.each(q.split('&'), function() {
						var splitted = this.split('=');
						var key = splitted[0];
						var val = splitted[1];
						// convert numbers
						if (/^[0-9.]+$/.test(val)) val = parseFloat(val);
						// convert booleans
						if (val == 'true') val = true;
						if (val == 'false') val = false;
						// ignore empty values
						if (typeof val == 'number' || typeof val == 'boolean' || val.length > 0) r[key] = val;
				});
		}
		return r;
	};
	
	//Gets the entire HTML container, including the selector
	$.fn.outerHTML = function() {
		return $('<div>').append( this.eq(0).clone() ).html();
	};
})(jQuery);

/* ########################################################################### *
/* ##### - COOKIES
/* ########################################################################### */

/**
 * Cookie plugin
 *
 * Copyright (c) 2006 Klaus Hartl (stilbuero.de)
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 */

jQuery.cookie=function(name,value,options){if(typeof value!='undefined'){options=options||{};if(value===null){value='';options=$.extend({},options);options.expires=-1;}
var expires='';if(options.expires&&(typeof options.expires=='number'||options.expires.toUTCString)){var date;if(typeof options.expires=='number'){date=new Date();date.setTime(date.getTime()+(options.expires*24*60*60*1000));}else{date=options.expires;}
expires='; expires='+date.toUTCString();}
var path=options.path?'; path='+(options.path):'';var domain=options.domain?'; domain='+(options.domain):'';var secure=options.secure?'; secure':'';document.cookie=[name,'=',encodeURIComponent(value),expires,path,domain,secure].join('');}else{var cookieValue=null;if(document.cookie&&document.cookie!=''){var cookies=document.cookie.split(';');for(var i=0;i<cookies.length;i++){var cookie=jQuery.trim(cookies[i]);if(cookie.substring(0,name.length+1)==(name+'=')){cookieValue=decodeURIComponent(cookie.substring(name.length+1));break;}}}
return cookieValue;}};


/* ########################################################################### *
/* ##### - SCROLL TO
/* ########################################################################### */

/**
 * jQuery.ScrollTo - Easy element scrolling using jQuery.
 * Copyright (c) 2007-2009 Ariel Flesler - aflesler(at)gmail(dot)com | http://flesler.blogspot.com
 * Dual licensed under MIT and GPL.
 * Date: 5/25/2009
 * @author Ariel Flesler
 * @version 1.4.2
 *
 * http://flesler.blogspot.com/2007/10/jqueryscrollto.html
 */
;(function(d){var k=d.scrollTo=function(a,i,e){d(window).scrollTo(a,i,e)};k.defaults={axis:'xy',duration:parseFloat(d.fn.jquery)>=1.3?0:1};k.window=function(a){return d(window)._scrollable()};d.fn._scrollable=function(){return this.map(function(){var a=this,i=!a.nodeName||d.inArray(a.nodeName.toLowerCase(),['iframe','#document','html','body'])!=-1;if(!i)return a;var e=(a.contentWindow||a).document||a.ownerDocument||a;return d.browser.safari||e.compatMode=='BackCompat'?e.body:e.documentElement})};d.fn.scrollTo=function(n,j,b){if(typeof j=='object'){b=j;j=0}if(typeof b=='function')b={onAfter:b};if(n=='max')n=9e9;b=d.extend({},k.defaults,b);j=j||b.speed||b.duration;b.queue=b.queue&&b.axis.length>1;if(b.queue)j/=2;b.offset=p(b.offset);b.over=p(b.over);return this._scrollable().each(function(){var q=this,r=d(q),f=n,s,g={},u=r.is('html,body');switch(typeof f){case'number':case'string':if(/^([+-]=)?\d+(\.\d+)?(px|%)?$/.test(f)){f=p(f);break}f=d(f,this);case'object':if(f.is||f.style)s=(f=d(f)).offset()}d.each(b.axis.split(''),function(a,i){var e=i=='x'?'Left':'Top',h=e.toLowerCase(),c='scroll'+e,l=q[c],m=k.max(q,i);if(s){g[c]=s[h]+(u?0:l-r.offset()[h]);if(b.margin){g[c]-=parseInt(f.css('margin'+e))||0;g[c]-=parseInt(f.css('border'+e+'Width'))||0}g[c]+=b.offset[h]||0;if(b.over[h])g[c]+=f[i=='x'?'width':'height']()*b.over[h]}else{var o=f[h];g[c]=o.slice&&o.slice(-1)=='%'?parseFloat(o)/100*m:o}if(/^\d+$/.test(g[c]))g[c]=g[c]<=0?0:Math.min(g[c],m);if(!a&&b.queue){if(l!=g[c])t(b.onAfterFirst);delete g[c]}});t(b.onAfter);function t(a){r.animate(g,j,b.easing,a&&function(){a.call(this,n,b)})}}).end()};k.max=function(a,i){var e=i=='x'?'Width':'Height',h='scroll'+e;if(!d(a).is('html,body'))return a[h]-d(a)[e.toLowerCase()]();var c='client'+e,l=a.ownerDocument.documentElement,m=a.ownerDocument.body;return Math.max(l[h],m[h])-Math.min(l[c],m[c])};function p(a){return typeof a=='object'?a:{top:a,left:a}}})(jQuery);

/* ########################################################################### *
/* ##### BG IFRAME
/* ########################################################################### */

/* Copyright (c) 2006 Brandon Aaron (http://brandonaaron.net)
 * Dual licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) 
 * and GPL (http://www.opensource.org/licenses/gpl-license.php) licenses.
 *
 * $LastChangedDate: 2007-06-19 20:25:28 -0500 (Tue, 19 Jun 2007) $
 * $Rev: 2111 $
 *
 * Version 2.1
 */
(function($){$.fn.bgIframe=$.fn.bgiframe=function(s){if($.browser.msie&&parseInt($.browser.version)<=6){s=$.extend({top:'auto',left:'auto',width:'auto',height:'auto',opacity:true,src:'javascript:false;'},s||{});var prop=function(n){return n&&n.constructor==Number?n+'px':n;},html='<iframe class="bgiframe"frameborder="0"tabindex="-1"src="'+s.src+'"'+'style="display:block;position:absolute;z-index:-1;'+(s.opacity!==false?'filter:Alpha(Opacity=\'0\');':'')+'top:'+(s.top=='auto'?'expression(((parseInt(this.parentNode.currentStyle.borderTopWidth)||0)*-1)+\'px\')':prop(s.top))+';'+'left:'+(s.left=='auto'?'expression(((parseInt(this.parentNode.currentStyle.borderLeftWidth)||0)*-1)+\'px\')':prop(s.left))+';'+'width:'+(s.width=='auto'?'expression(this.parentNode.offsetWidth+\'px\')':prop(s.width))+';'+'height:'+(s.height=='auto'?'expression(this.parentNode.offsetHeight+\'px\')':prop(s.height))+';'+'"/>';return this.each(function(){if($('> iframe.bgiframe',this).length==0)this.insertBefore(document.createElement(html),this.firstChild);});}return this;};if(!$.browser.version)$.browser.version=navigator.userAgent.toLowerCase().match(/.+(?:rv|it|ra|ie)[\/: ]([\d.]+)/)[1];})(jQuery);
