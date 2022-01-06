/* ########################################################################### *
/* ***** DOCUMENT INFO  ****************************************************** *
/* ########################################################################### *
 * ##### NAME:  webapps.js
 * ##### VERSION: v0.3
 * ##### UPDATED: 30/11/2009 (Damian Keeghan - Deloitte's Online Practice)
 * #####          06/07/2010 (Sasima Sae-Lim - Australia Post)
 * #####          06/30/2010 (Elvis Svonja   - Australia Post)
 * #####					15/12/2010 (Ken Shi				 - Australia Post)
 * #####					27/01/2011 (Ken Shi				 - Australia Post)
 * #####					15/02/2011 (Ken Shi				 - Australia Post) 
 * #####					14/08/2011 (George Hiley - Deloitte Online - Design refresh)
/* ########################################################################### *

/* ########################################################################### *
/* ***** INDEX *************************************************************** *
/* ########################################################################### *
/* ##### INITIALISATION
/* ##### VISUAL INITIALISATION
/* ##### FUNCTIONAL INITIALISATION
/* ##### TOOLS
/* ##### AUTOCOMPLETE
/* ########################################################################### */

/* ########################################################################### *
/* ##### GLOBAL VARIABLES
/* ########################################################################### */


var DEBUG_MODE = false;
var DEBUG_OMNITURE = false;
//var API_AUTOCOMPLETE = "/api/postcode/search.txt?key=63fa7c3657ea97f3809aacaa42142bae";
//var API_AUTOCOMPLETE_NO_POBOX = "/api/postcode/search.txt?key=63fa7c3657ea97f3809aacaa42142bae&excludePostBoxFlag=true";
var API_AUTOCOMPLETE = "/js/original/samplesuburb.txt";
var API_AUTOCOMPLETE_NO_POBOX = "/js/original/samplesuburb.txt";

var apps_pac_3d_updateResizedTextFields;

/* ########################################################################### *
/* ##### INITIALISATION
/* ########################################################################### */

$(document).ready(function(){
    init_apps_visual();
    init_apps_functional();
});

/* ########################################################################### *
/* ##### VISUAL INITIALISATION
/* ########################################################################### */

function init_apps_visual(){
    init_apps_pac_servicesTable();
    init_apps_pac_3d_sizer();
    init_apps_pac_weightSlider();
    init_forms_trackItem();
}

/* ########################################################################### *
/* ##### FUNCTIONAL INITIALISATION
/* ########################################################################### */

function init_apps_functional(){
    if (!DEBUG_MODE) init_apps_modal();
    init_apps_autocomplete();
    init_apps_modal_textInputs();
		init_fx_rate();
  	init_currency(); 		
}


/* ########################################################################### *
/* ##### AFTER CONTENT LOAD
/* ########################################################################### */

function apps_after_content_load() {
    init_classHelpers(); //inside global.js
    init_tooltips(); //inside global.js
    init_tables(); // inside global.js
    init_global_forms(); // inside global.js
    init_apps_autocomplete();
    init_apps_pac_servicesTable();
    init_apps_pac_3d_sizer();
    init_apps_pac_weightSlider();
    init_apps_modal_textInputs();
		init_fx_rate();
    init_forms_trackItem();
    apps_modal_stepsNavigation();
    fn_ie_jumpfix();

    // IE6 only
    if ($('html.ie6').length > 0) { 
      init_ie_ie6_inputs(); 
    }
}

/* ########################################################################### *
/* ##### TOOLS
/* ########################################################################### */

function init_apps_modal() {

    // Execute on pages with .page-tools
    if($(".page-tools").length > 0) { 
  
      // Setup tools step navigation
      apps_modal_stepsNavigation();
      
      /*
       * Form submission handlers
       * - Hijack the submit form button on form.fn_app_submit to replace page loads with ajax
       */        
      $("form.fn_app_submit").live("submit", function() {

          var form = $(this);
          
          // Clear validation
          _apps_validation_clearValidation(form);
          
          // Clear placeholder text if applicable
          $(form).find('input[type="text"]').filter('[title]').each(function() {
        		var input = $(this);
        		if (input.val() == input.attr('title')) {
        		  input.val('');
        		}
      	  });
      	  
          // Scroll up to the <h1>
          $.scrollTo("h1", 500, function() {
          
            // Validate and submit form
            var valid = true;
            if($(form).hasClass("fn_app_submit_pcs")) {
                if(onPCSValidation(form)==true){
                    //onFormSubmit(form);
                } else {
                    valid = false;
                }
            } else if($(form).hasClass("fn_track_submit")) {
                
            
                if(onTrackValidation(form)==true){
                    _apps_setTrackIDCookies();
                    //onFormSubmit(form);
								}else {
                    valid = false;   
                }
            }  else if($(form).hasClass("fn_rate_submit")) {
                if(onRateValidation(form)==true){
                    //onFormSubmit(form);
								}else {
                    valid = false;   
                }
						}
						
					  if (valid) {
					   onFormSubmit(form);
					  }
					  else
					  {
					    // Set placeholder text if applicable
              $(form).find('input[type="text"]').filter('[title]').trigger('blur');
					  }

          });
          
          return false;
      }); 
      /* END FORM SUBMISSION HANDLERS */
      
      
      /*
       * Form validation
       *
       */				
       var onRateValidation = function(form){
				var isValid = true;
				
          var notices = Array();
          
          $(form).find("input, searchCriteria.audAmount").each(function(){
              var fieldValid = onRateFieldValidation(this, form, notices);
              isValid = (fieldValid==false) ? fieldValid : isValid;
          });
          
					$(form).find("select").each(function(){
							var fieldValid = onCurrencyFieldValidation(this, form, notices);
							isValid = (fieldValid==false) ? fieldValid : isValid;
					});
					
        if(isValid==false) {
          _app_validation_output(false, notices, $(form));       
        }  
        return isValid;
			}
			
			var onRateFieldValidation = function(field, form, notices){
				var isValid = true;
				var control = $(field);
				var controlHolder = $(control).parents(".ctrlHolder");
   			var errorMessage = "";
   			
       	if($(control).val()==""){
       		errorMessage = "Please enter a valid convert amount.";
       		notices.push(errorMessage);
       		$(control).addClass('error');
					isValid = false;
       	} else{
			   	if($(control).val() > 30000 ){
       			errorMessage = "Please enter an amount less than $30,000.00.";
       			notices.push(errorMessage);
       			$(control).addClass('error');
						isValid = false;
       		}else{
						if($(control).val() < 0){
							errorMessage = "Please enter a valid amount.";
							notices.push(errorMessage);
							$(control).addClass('error');
							isValid = false;
						}
					}
      	}
				
				return isValid;
			}

			var onCurrencyFieldValidation = function(field, form, notices){
				var isValid = true;
				var control = $(field);
				var controlHolder = $(control).parents(".ctrlHolder");
   			var errorMessage = "";
				
       	if($(control).val()==""){
       		errorMessage = "Please select a currency.";
       		notices.push(errorMessage);
       		$(control).addClass('error');
					isValid = false;
       	}
			
				return isValid;
      }
			
      var onPCSValidation = function(form) {
          var isValid = true;
          
          $(form).find(".fn_valid_minChars3").each(function() {
              var fieldValid = onPCSFieldValidation(this, form);
              isValid = (fieldValid==false) ? fieldValid : isValid;
          });
          
          return isValid;
      }
      
      var onPCSFieldValidation = function(field, form){
          var control = $(field);
          var controlHolder = $(control).parents(".ctrlHolder");
          var label = $(controlHolder).find("label, .label")[0];
          label = $(label).text();
          label = label.replace("*", ""); 
          var notices = Array();
          
          var controlId = $(control).attr("id");
          
          var isValid = true;
          var tagName = field.tagName;
          
          var errorMessage = "Please enter " + label;
          notices[0] = errorMessage;
          
          if(tagName=="INPUT"){
              if($(control).data("hintText")!=null && $(control).data("hintText") == $(control).val()){
                  errorMessage = "Please enter a value";
                  notices[0] = errorMessage;
                  $(control).addClass('error');
                  isValid = false;
              } else {
                  if($(control).val().length < 3){
                      if($(control).val()==""){
                          errorMessage = "Please enter suburb, town, city or postcode";
                          notices[0] = errorMessage;
                      } else {
                          errorMessage = "Please enter at least 3 characters";
                          notices[0] = errorMessage;
                      }
                      $(control).addClass('error');                        
                      isValid = false;    
                  }
              }
          }
          
          if(isValid==false){
            _app_validation_output(false, notices, $(form));
          }
          
          return isValid;
      }
              
      function onTrackValidation(form) {

        // Set inputs
        // Grab the textarea element & clear any current value
        var textarea = $('#trackIds');
        $(textarea).val('');
  
        // Parse all inputs
        var count = 0;
        $(form).find('.fn_dynamicInputEntries .inputContainer input.text').each(function()
        {
          if ($(this).val().length > 0 && $(this).val() != $(this).attr('title'))
          {
            // This input has a value, add it to the textarea
            count++;          
            var value = $(this).val();
            var newLine = (count == 10) ? '' : '\n';
            $(textarea).val($(textarea).val().toString() + value + newLine);
          }
        });      
      
      	var isValid = true;
      	var control = $(form).find("#trackIds")[0];
      	var controlHolder = $(control).parents(".trackItemsContainer");
      	var trackIds = $(control).val();
      	var errorMessage = "";
      	var notices = Array();
      	
      	if (trackIds == null || trackIds.replace(/^\s+|\s+$/g,"") == "") {
				  $(form).find('.trackNumbers input.text:first').addClass('error');
      		notices.push("Please enter a tracking ID");
      		isValid = false;
      	} else {
      		trackIds = trackIds.split("\n");
      		if (trackIds.length > 10) {
      			notices.push("Maximum of 10 tracking IDs are allowed");
      			isValid = false;
      		} else {
      			// Process strings from text area
      			for (var i in trackIds) {
      				if (!(/^[a-zA-Z0-9]{0,50}$/.test(trackIds[i]))) {
      				  
      				  // Failed... so process inputs to add .error class
      				  $(form).find('.trackNumbers input.text').each(function() {
      				    if ($(this).val().length > 0 && $(this).val() != $(this).attr('title'))
      				    {
            				if (!(/^[a-zA-Z0-9]{0,50}$/.test($(this).val()))) { 
            				  $(this).addClass('error');
            				}       				      
      				    } 
      				  });
      					
      					notices.push("A tracking ID is invalid or exceeds 50 characters - please correct");
      					isValid = false;
      					break;
      				}
      			}
      			
      		}
      	}
      
        // Write up validation errors
      	if(isValid==false){
          _app_validation_output(false, notices, $(form).find('.trackNumbers:first'));
      	}
      	        
      	return isValid;
      }        
      
      // Function to write out validation messages
      // @param isValid bool if errors or success
      // @param notices Array of messages
      // @param container jQuery DOM node(s) to append validation
      // @param title Title if required
      var _app_validation_output = function (isValid, notices, container, title) {
        
        var htmlWrapper = (isValid ? '<div class="validation success hidden"></div>' : '<div id="errors" class="validation errors hidden"></div>');
        var htmlNotices = '';
        if (title != undefined) {
          htmlNotices += '<p>' + title + '</p>';
        }
        
        htmlNotices += '<ul class="clearfix">';
        
        // For each notice add an <li>
        for (var x = 0; x < notices.length; x++) {
          htmlNotices += '<li>' + notices[x] + '</li>';
        }
        htmlNotices += '</ul>';
        
        if ($(container).find('.validation').length > 0) {
          $(container).find('.validation').slideUp('slow', function() {   
            $(this).html(htmlNotices).slideDown('slow');
          });
        }
        else
        {
          $(container).prepend(htmlWrapper);
          $(container).find('.validation').hide().removeClass('hidden').html(htmlNotices).slideDown('slow');
        }
      }
      
      
      /*
       * Form submission
       *
       */
      var onFormSubmit = function(form) {
                
          // Grab form action
          var action = $(form).attr("action");
          
          // Clear validation
          _apps_validation_clearValidation(form);
					
					// Add by Ken Shi 2011-02-15 - Distinguish 'I want to' module on Home / Personal / Business landing	
					// var url = $("title").html().toLowerCase();
					//var pageId = "i want to";
					//if(url == "australia post - home"){ pageId = "hometab"; }
					//else if(url == "australia post - personal"){ pageId = "perstab"; }
					//else if(url == "australia post - business"){ pageId = "busitab"; }
					
          // Main loading script for tool steps (note Track ID loading is handled below in apps_loadTrackItem method)
			    function _toolsStepLoad(currentStep, newStep, form)
			    {					
            var modalContent = $(newStep);
            var action = $(form).attr('action');
            $('#pageload').remove();
            $('body').append('<div id="pageload" class="hidden"></div>');
            var pageload = $('#pageload');
			
			// Clear placeholder text on input forms (ensure don't submit title text as values) - ghiley 04/10/11
			$('#main input[type="text"]').filter('[title]').each(function() {
				var input = $(this);
				if (input.val() == input.attr('title')) {
				  input.unbind('blur').val('');
				}
			});

            //$(modalContent).load(action + " .tools-step-active .module-inner", $(form).serializeArray(), function()
            $(pageload).load(action + ' #app_results', $(form).serializeArray(), function()
            { 
              //var j_pageName = '';
              //if ($(pageload).find('.j_pageName').length > 0) {
              //  j_pageName = $(pageload).find('.j_pageName').html();
              //}
              
              // OMNITURE
              s_code = '';
              if ($(pageload).find('.omniture:last').length > 0) {
                var omnitureJs = $(pageload).find('.omniture:last').attr('data-omniture');
                $(pageload).find('.omniture:last').html('<script>' + omnitureJs + '</script>');

                if (j_pageName != "") 
                {
                  s.pageName = j_pageName;
                }
                else
                { 
                  s.pageName = g_pageName;
                }
                s_code=s.t();
                if (DEBUG_OMNITURE) alert('OMNITURE DEBUG: ' + omnitureJs);
              }
              else
              {
                if (DEBUG_OMNITURE) alert('OMNITURE DEBUG: .omniture object and code not found in ajax request');
              }
                          
              // Set the new content
              $(modalContent).html($(pageload).find('.tools-step-active:last').html());
              
              
              // ERRORS: If returned with errors, do not proceed to next step
              if ($(modalContent).find('.errors').length > 0) {
                
                // Switch this new modalContent back to replace the previous modalContent
                $(currentStep).find('.module-content').html($(modalContent).find('.module-content').html());
                $(currentStep).addClass('tools-step-active');
                $(modalContent).remove();
                modalContent = $(currentStep);
              }              
              else
              {
                // Handle the disclaimer              
                // If no disclaimer on new page, empty the current one
                if ($(pageload).find('.tools-step-active:last').nextAll('.disclaimer:first').length < 1) {
                  $('#main .tools-step-active:last').nextAll('.disclaimer:first').empty();
                }
                else
                {
                  // Disclaimer exists on next page, check we have a current .disclaimer HTML holder or create one
                  if ($('#main .tools-step-active:last').nextAll('.disclaimer:first').length < 1) {
                    
                    // If has .module-corner-bottom (eg. IE8)
                    var last = ($('#main .tools-step-active:last').next('.module-corner-bottom').length > 0) ? $('#main .tools-step-active:last').next('.module-corner-bottom') : $('#main .tools-step-active:last');
                    $(last).after('<div class="disclaimer"></div>');
                  }
                  
                  $('#main .tools-step-active:last').nextAll('.disclaimer:first').html($(pageload).find('.tools-step-active:last').nextAll('.disclaimer:first').html());
                }
                
                // Handle shop products module
                if ($(pageload).find('.module-products').length > 0) {
                  if ($('#main #track_result').length > 0) {
                    $('#main #track_result').append($(pageload).find('.module-products'));
                  }
                  else
                  {
                    $('#main #app_results').append($(pageload).find('.module-products'));
                  }
                  init_slider(); // in global.js
                }
              }

              // Get rid of loaded content
              $('#pageload').remove();              
              
              apps_after_content_load();
              
              /*

              var overlayHtml = $('#main').html().toLowerCase();
              overlayHtml = unescape(overlayHtml);
              
              // Sending letters within Australia
              if(overlayHtml.search("sending letters within australia")>0 && overlayHtml.search("select an envelope type")>0){
                  s.pageName ="auspost:"+pageId+":calculate postage cost:sending letter within australia:home page";
                  s.prop6=s.eVar6="";
                  s.events="";
              }
                                          
              // Sending letters within Australia
              if(overlayHtml.search("sending letters internationally")>0 && overlayHtml.search("select your country")>0){
                  s.pageName ="auspost:"+pageId+":calculate postage cost:sending letter internationally:home page"; 
                  s.prop6=s.eVar6="";
                  s.events="";
              }
                  
              // Sending parcels within Australia
              if(overlayHtml.search("sending parcels within australia")>0 && overlayHtml.search("type of parcel")>0){
                  s.pageName ="auspost:"+pageId+":calculate postage cost:sending parcel within australia:home page"; 
                  s.prop6=s.eVar6="";
                  s.events="";
              }
                                      
              // Sending parcels internationally
              if(overlayHtml.search("sending parcels internationally")>0 && overlayHtml.search("select your country")>0){
                  s.pageName ="auspost:"+pageId+":calculate postage cost:sending parcel internationally:home page";  
                  s.prop6=s.eVar6="";
                  s.events="";
              }
                  
              // Postcode
              if(overlayHtml.search("find postcode")>0 && overlayHtml.search("Please select an item from the list below to view details.")>0){
                  s.pageName="auspost:"+pageId+":postcode search:result";
                  s.prop6=s.eVar6="Postcode Search - Tool Full Search";
                  s.events="event6"; 
              }
              
              // Track
              if(overlayHtml.search("track item")>0 && overlayHtml.search("tracking details")>0){
                  s.pageName = "auspost:"+pageId+":track my item:track item result";
                  s.prop6=s.eVar6="Track my item";
                  s.events="event6"; 
              }
              
              if(overlayHtml.search("track item")>0 && overlayHtml.search("tracking details")<0){
                  s.pageName = "auspost:"+pageId+":track my item:track result list";
                  s.prop6=s.eVar6="";
                  s.events=""; 
              }

							// Currency Conventer
              if(overlayHtml.search("convert currency")>0 && overlayHtml.search("conversion summary")>0){
                  s.pageName="auspost:"+pageId+":currency converter:result";
									s.eVar32=s.prop32=$(modalContent).find("input, searchCriteria.audAmount").val();
									s.eVar33=s.prop33=$(modalContent).find("select, searchCriteria.currency").val();
                  s.prop6=s.eVar6="Currency Conventer - Home Page Full Search";
                  s.events="event6";
              }

							// send usage 
							//if (DEBUG_OMNITURE) alert("s.pageName: " + s.pageName + ";\n\n j_pageName: " + j_pageName);
							//s.pageName = (j_pageName != '') ? j_pageName : s.pageName;
              //var s_code=s.t();
              */
              
              $(modalContent).hide().removeClass('hidden').find('.module-content').css('opacity', 0);
              $(modalContent).fadeIn(500, function()
              {
                $(modalContent).find('.module-content').show().animate({"opacity": 1}, 1000);
                
                // Turn off loading on current module
                $(currentStep).find('.module-heading').removeClass('loading');
                
                // IE6, IE7 and IE8 tweaks
                if ($('html.ie6, html.ie7, html.ie8').length > 0) {    
                  init_roundedCorners();
                }
              });      

            });
          }					
                    
					// Setup containers
					var currentStep = $(form).parents('.tools-step-active');
					
					// Create next step container if it doesn't exist
					if ($(currentStep).nextAll('.tools-step-active:first').length < 1)
					{						
            // Hide .disclaimer if there is one
            if ($(currentStep).nextAll('.disclaimer:first').length > 0) {
              $(currentStep).nextAll('.disclaimer:first').hide();
            }

            if ($('#main #track_result').length > 0) {
              $('#main #track_result').append('<div class="tools-step tools-step-active module hidden"></div>');
            }
            else
            {
              $('#main #app_results').append('<div class="tools-step tools-step-active module hidden"></div>');
            }            
                      					
					}
					var newStep = $(currentStep).nextAll('.tools-step-active:first');
					
          // Set loading on current module
          $(currentStep).find('.module-heading').addClass('loading');  
          						
					// Hide shop products
					$('#main .module-products').each(function() 
					{ 
					  $(this).hide();
					});          	
					
					// Check if meant to keep the current step active
					if ($(currentStep).hasClass('tools-step-keep-active')) {

            // Do not deactivate, load content
					  _toolsStepLoad(currentStep, newStep, form);
					}
					else
					{
					  // Deactivate current step and load content
						$(currentStep).removeClass('tools-step-active');
						
						// Hide the buttons (hacks mainly for IE)
						$(currentStep).find('.module-content .actions, .inputContainerActions, .articleDetailsContainer').hide();
						
            // Transition into new step								
						$(currentStep).find('.module-content').slideUp(800, function()
						{
							  _toolsStepLoad(currentStep, newStep, form);
            });
					}
        }
    }
}

// Handle track results table / opening a single track item
function apps_loadTrackItem(anchor, href) {

  function _trackLoad(currentStep, newStep, anchor, href)
  {					
      var modalContent = $(newStep);
      var action = href;
  
      $('#pageload').remove();
      $('body').append('<div id="pageload" class="hidden"></div>');
      var pageload = $('#pageload');
	  
	  
		// Clear placeholder text on input forms (ensure don't submit title text as values) - ghiley 04/10/11
		$('#main input[type="text"]').filter('[title]').each(function() {
			var input = $(this);
			if (input.val() == input.attr('title')) {
			  input.unbind('blur').val('');
			}
		});
      
      $(pageload).load(action + ' #app_results', function()
      { 
      
        // Set the new content
        $(modalContent).html($(pageload).find('.tools-step-active:last').html());
        
        //var j_pageName = '';
        //if ($(pageload).find('.j_pageName').length > 0) {
        //  j_pageName = $(pageload).find('.j_pageName').html();
        //}
        
        // OMNITURE
        s_code = '';
        if ($(pageload).find('.omniture:last').length > 0) {
          var omnitureJs = $(pageload).find('.omniture:last').attr('data-omniture');
          $(pageload).find('.omniture:last').html('<script>' + omnitureJs + '</script>');
          if (j_pageName != "") 
          {
            s.pageName = j_pageName;
          }
          else
          { 
            s.pageName = g_pageName;
          }
          s_code=s.t();
          if (DEBUG_OMNITURE) alert('OMNITURE DEBUG: ' + omnitureJs);
        }
        else
        {
          if (DEBUG_OMNITURE) alert('OMNITURE DEBUG: .omniture object and code not found in ajax request');
        }        

        // Handle the disclaimer              
        // If no disclaimer on new page, empty the current one
        if ($(pageload).find('.tools-step-active:last').nextAll('.disclaimer').length < 1) {
          $('#main .tools-step-active:last').nextAll('.disclaimer').empty();
        }
        else
        {
          // Disclaimer exists on next page, check we have a current .disclaimer HTML holder or create one
          if ($('#main .tools-step-active:last').nextAll('.disclaimer:first').length < 1) {
          
            // If has .module-corner-bottom (eg. IE8)
            var last = ($('#main .tools-step-active:last').next('.module-corner-bottom').length > 0) ? $('#main .tools-step-active:last').next('.module-corner-bottom') : $('#main .tools-step-active:last');
            $(last).after('<div class="disclaimer"></div>');            
          }
          $('#main .tools-step-active:last').nextAll('.disclaimer:first').html($(pageload).find('.tools-step-active:last').nextAll('.disclaimer:first').html());
        }
        
        // Handle shop products module
        if ($(pageload).find('.module-products').length > 0) {
          
          if ($('#main #track_result').length > 0) {
            $('#main #track_result').append($(pageload).find('.module-products'));
          }
          else
          {
            $('#main #app_results').append($(pageload).find('.module-products'));
          }          
          
          init_slider(); // in global.js
        }
                
        // Get rid of loaded content
        $('#pageload').remove();
      
				// Add by Ken Shi 2011-02-15 - Distinguish 'I want to' module on Home / Personal / Business landing	
				// var url = $("title").html().toLowerCase();
				// var pageId = "i want to";
				// if(url == "australia post - home"){ pageId = "hometab"; }
				// else if(url == "australia post - personal"){ pageId = "perstab"; }
				// else if(url == "australia post - business"){ pageId = "busitab"; }        
        
        apps_after_content_load();
  
        /*
        var overlayHtml = $('#main').html().toLowerCase();
        overlayHtml = unescape(overlayHtml);
        
        // Sending letters within Australia
        if(overlayHtml.search("sending letters within australia")>0 && overlayHtml.search("select an envelope type")>0){
            s.pageName ="auspost:"+pageId+":calculate postage cost:sending letter within australia:home page";
            s.prop6=s.eVar6="";
            s.events="";
        }
                                    
        // Sending letters within Australia
        if(overlayHtml.search("sending letters internationally")>0 && overlayHtml.search("select your country")>0){
            s.pageName ="auspost:"+pageId+":calculate postage cost:sending letter internationally:home page"; 
            s.prop6=s.eVar6="";
            s.events="";
        }
            
        // Sending parcels within Australia
        if(overlayHtml.search("sending parcels within australia")>0 && overlayHtml.search("type of parcel")>0){
            s.pageName ="auspost:"+pageId+":calculate postage cost:sending parcel within australia:home page"; 
            s.prop6=s.eVar6="";
            s.events="";
        }
                                
        // Sending parcels internationally
        if(overlayHtml.search("sending parcels internationally")>0 && overlayHtml.search("select your country")>0){
            s.pageName ="auspost:"+pageId+":calculate postage cost:sending parcel internationally:home page";  
            s.prop6=s.eVar6="";
            s.events="";
        }
            
        // Postcode
        if(overlayHtml.search("find postcode")>0 && overlayHtml.search("Please select an item from the list below to view details.")>0){
            s.pageName="auspost:"+pageId+":postcode search:result";
            s.prop6=s.eVar6="Postcode Search - Tool Full Search";
            s.events="event6";
        }
        
        // Track
        if(overlayHtml.search("track item")>0 && overlayHtml.search("tracking details")>0){
            s.pageName = "auspost:"+pageId+":track my item:track item result";
            s.prop6=s.eVar6="Track my item";
            s.events="event6";
        }
        
        if(overlayHtml.search("track item")>0 && overlayHtml.search("tracking details")<0){
            s.pageName = "auspost:"+pageId+":track my item:track result list";
            s.prop6=s.eVar6="";
            s.events="";
        }
  
  			// Currency Conventer
        if(overlayHtml.search("convert currency")>0 && overlayHtml.search("conversion summary")>0){
            s.pageName="auspost:"+pageId+":currency converter:result";
  					s.eVar32=s.prop32=$(modalContent).find("input, searchCriteria.audAmount").val();
  					s.eVar33=s.prop33=$(modalContent).find("select, searchCriteria.currency").val();
            s.prop6=s.eVar6="Currency Conventer - Home Page Full Search";
            s.events="event6";
        }
  
  			// send usage 
				//if (DEBUG_OMNITURE) alert("s.pageName: " + s.pageName + ";\n\n j_pageName: " + j_pageName);
				//s.pageName = (j_pageName != '') ? j_pageName : s.pageName;
        //var s_code=s.t();
        
        */
        
        // Fade in if a new step (and is currently hidden)
        if ($(modalContent).hasClass('hidden')) {
          $(modalContent).hide().removeClass('hidden').find('.module-content').css('opacity', 0);
          $(modalContent).fadeIn(500, function()
          {
            $(modalContent).find('.module-content').animate({"opacity": 1}, 1000);
            
            // Turn off loading on current module
            $(currentStep).find('.module-heading').removeClass('loading');
            
            // IE6, IE7 and IE8 tweaks
            if ($('html.ie6, html.ie7, html.ie8').length > 0) {    
              init_roundedCorners();
            }
          });
        }
        else
        {
          // Slide down as loaded in the same step panel (is not hidden)
          $(modalContent).find('.module-content').hide().slideDown(500, function()
          {
            // Turn off loading on current module
            $(currentStep).find('.module-heading').removeClass('loading');
            
            // IE6, IE7 and IE8 tweaks
            if ($('html.ie6, html.ie7, html.ie8').length > 0) {    
              init_roundedCorners();
            }
          });
        }
      });
  }
  
  // Scroll up to the <h1>
  $.scrollTo("h1", 500, function() {

    // Setup containers
    var currentStep = $(anchor).parents('.tools-step-active');
    var newStep = currentStep;
    
    // Check if should load in the current step panel or create a new one
    if ($(anchor).hasClass('fn_loadInCurrentPanel')) {

      // Hide next .disclaimer if there is one
      if ($(currentStep).nextAll('.disclaimer').length > 0) {
        $(currentStep).nextAll('.disclaimer').hide();
      }
      
      // Set newStep to currenStep to load in the same step panel
      newStep = currentStep;
    }
    else
    {
      // Create next step container if it doesn't exist
			if ($(currentStep).nextAll('.tools-step-active:first').length < 1)
			{						
        // Hide .disclaimer if there is one
        if ($(currentStep).nextAll('.disclaimer:first').length > 0) {
          $(currentStep).nextAll('.disclaimer:first').hide();
        }
        
        if ($('#main #track_result').length > 0) {
          $('#main #track_result').append('<div class="tools-step tools-step-active module hidden"></div>');     
        }
        else
        {
          $('#main #app_results').append('<div class="tools-step tools-step-active module hidden"></div>');     
        }          

               					
			}
      
      // Set newStep to the newly created tools-step panel to load next content
      newStep = $(currentStep).nextAll('.tools-step-active:first');
    }
    
    // Set loading on current module
    $(currentStep).find('.module-heading').addClass('loading');  
    
    // Hide shop products
		$('#main .module-products').each(function() 
		{ 
		  $(this).hide();
		});	
    
    // Check if meant to keep the current step active
    if ($(currentStep).hasClass('tools-step-keep-active')) {
    
      // Do not deactivate, load content
      _trackLoad(currentStep, newStep, anchor, href);
    }
    else
    {
      // If load in a new panel
      if (!$(anchor).hasClass('fn_loadInCurrentPanel')) {

        // Deactivate current step style
      	$(currentStep).removeClass('tools-step-active');
      }
      
      // Hide the buttons (hacks mainly for IE)
			$(currentStep).find('.module-content .actions, .inputContainerActions, .articleDetailsContainer').hide();

    	$(currentStep).find('.module-content').slideUp(800, function()
    	{
    		  _trackLoad(currentStep, newStep, anchor, href);
      });
    }
  });
}


// Handle transitioning from current step to target step
function apps_stepTransition(currentStep, targetStep) {

    // Scroll page to keep visible
    $.scrollTo("h1", 500, function() {
  
    // Transition out and remove current step and all steps after target step
    $(targetStep).find('.module-heading').addClass('loading');

    // Ensure we are transitioning-out all steps that are after the target step
    var nextSteps = $(targetStep).nextAll('.tools-step');
    
    // Remove all disclaimers except for the target step's disclaimer
    var last = ($(targetStep).next('.module-corner-bottom').length > 0) ? $(targetStep).next('.module-corner-bottom') : $(targetStep);
    if ($(last).next('.disclaimer').length > 0) {
      $(last).next('.disclaimer').nextAll('.disclaimer').remove();
    }
    else
    {
      $(last).nextAll('.disclaimer').remove();     
    }
    
    // Remove all product modules except for the target step's
    var last = ($(targetStep).next('.module-corner-bottom').length > 0) ? $(targetStep).next('.module-corner-bottom') : $(targetStep);
    var last = ($(last).next('.disclaimer').length > 0) ? $(last).next('.disclaimer') : $(last);
    if ($(last).next('.module-products').length > 0) {
      $(last).next('.module-products').nextAll('.module-products').remove();
    }
    else
    {
      $(last).nextAll('.module-products').remove();     
    }    
    
    $(nextSteps).removeClass('tools-step-active');
    $(nextSteps).find('.module-heading .module-actions').fadeOut();
    
    // Hide the buttons (hacks mainly for IE)
		$(currentStep).find('.module-content .actions, .inputContainerActions, .articleDetailsContainer').hide();
    
    // Hide current step module content
    $(currentStep).find('.module-content').slideUp(500, function() {
    
      // Fade out next steps & remove
      $(nextSteps).fadeOut(500, function() {
        $(nextSteps).remove();
        $(last).nextAll('.module-corner-bottom').remove(); // Remove any IE bottom corners         
        
        // Transition in target step
        $(targetStep).find('.module-content').slideDown(500, function() {
          $(targetStep).find('.module-heading').removeClass('loading');
          $(targetStep).addClass('tools-step-active');
          $(targetStep).nextAll('.disclaimer').show();
          $(targetStep).nextAll('.module-products').show();
          
          // Hide the buttons (hacks mainly for IE)
					$(targetStep).find('.module-content .actions, .inputContainerActions, .articleDetailsContainer').show();
          
          // Initialise
          apps_after_content_load();
        });
      });
    });
  });
}


/*
 * Tools steps navigation (insert and manage buttons and interaction)
 *
 */
function apps_modal_stepsNavigation() {

  /*
   * Global
   *
   */
  if ($('#app_results').length > 0) {
  
    // Get all steps
    var steps = $('#app_results .tools-step');
  
    // Handle hard links back to first step / tool reset
    $('.fn_restart').unbind('click').bind('click', function() {
      $(steps).eq(0).find('form')[0].reset(); // Reset the form
      var targetStep = $(steps).eq(0);
      var currentStep = $(steps)[$(steps).length - 1];  // Last item in the steps stack
      apps_stepTransition(currentStep, targetStep);
      return false;            
    });
    
  }


  /*
   * Track item
   *
   */
   
  if ($('#app_results.track').length > 0) {
    var steps = $('#app_results.track .tools-step');
    if ($(steps).eq(0).length > 0) {
          
      // Remove buttons
      $(steps).find('.fn_reset, .fn_newSearch, .fn_close, .fn_back, .fn_print').remove();
      
      // STEP 1
      if ($(steps).eq(1).length < 1) {
                
        // Enable the reset button
        $(steps).eq(0).find('.module-actions').append('<a href="#" class="fn_reset">Reset</a>');
        $('.fn_reset').unbind('click').bind('click', function() {
          $(this).parents('.tools-step').find('form')[0].reset();
          _apps_validation_clearValidation($(this).parents('.tools-step').find('form'));
		  _clear_form_elements($(this).parents('.tools-step'));
          init_forms_trackItem(); // From script.js
          return false;
        });
      }
      else
      {
        // STEP 2+ (Results list or Result)
        
        // Handle track articleDetailsContainer expando collapso
        if ($('.articleDetailsContainer').length > 0) {
          // $('.articleDetailsContainer').addClass('collapse');
          $('.articleDetailsContainer .articleDetailsLinkExpand').unbind('click').click(function(event) {
            $(this).parents('.articleDetailsContainer:first').toggleClass('collapse');
            $(this).blur();
            return false;
          });
        }
                
        // Result(s) are visible, enable the New search button
        $(steps).eq(0).find('.module-actions').append('<a href="#" class="fn_newSearch">New search</a>');
        $('.fn_newSearch').unbind('click').bind('click', function() {
          // Transition back to step
          var targetStep = $(steps).eq(0); 
          var currentStep = $(steps)[$(steps).length - 1];  // Last item in the steps stack
          apps_stepTransition(currentStep, targetStep);
          
          $(targetStep).find('form')[0].reset();
          _apps_validation_clearValidation($(targetStep).find('form'));
          init_forms_trackItem(); // From script.js
          
          return false;            
        });
        
        // Check if displaying results list or a single tracking summary has been returned
        var isResultsList = ($(steps).eq(1).find('.resultsList').length > 0) ? true : false;         
        if (isResultsList) {
        
          // STEP 3 and above - Result (after results listing) plus 
          if ($(steps).eq(2).length > 0) 
          {
            
            // Enable close button on Step 2 results table
            $(steps).not(':first, :last').find('.module-actions').append('<a href="#" class="fn_back">Back to results</a>');
            $('.fn_back').unbind('click').bind('click', function() {
              // Transition back to step
              var targetStep = $(this).parents('.tools-step');
              var currentStep = $(steps)[$(steps).length - 1];  // Last item in the steps stack
              apps_stepTransition(currentStep, targetStep);
              return false;
            });            
          
            // Remove and create print button
            $(steps).eq($(steps).length - 1).find('.module-actions').append('<a href="#" class="fn_print">Print</a>');
            $(steps).eq($(steps).length - 1).find('.fn_print').unbind('click').bind('click', function() {
              window.print();
              return false;
            });  
          
            // Insert / handle previous button
            if ($(steps).eq($(steps).length - 1).find('.actions .right .btn-previous').length < 1) {
              $(steps).eq($(steps).length - 1).find('.actions .right').prepend('<a href="#" class="btn secondary btn-previous"><span class="caret"></span>Previous</a>');
              $(steps).eq($(steps).length - 1).find('.actions .right .btn-previous').click(function() {
                // Transition back to step
                var currentStep = $(this).parents('.tools-step');
                var targetStep = $(currentStep).prevAll('.tools-step:first');
                apps_stepTransition(currentStep, targetStep);
                return false;
              });
            }
          }
          else
          {
            // STEP 2: Results listing
            
            // Enable close button on results table
            $(steps).eq(1).find('.module-actions').append('<a href="#" class="fn_close">Close</a>');
            $('.fn_close').unbind('click').bind('click', function() {
              // Transition back to step
              var targetStep = $(steps).eq(0);
              var currentStep = $(this).parents('.tools-step');  // Last item in the steps stack
              apps_stepTransition(currentStep, targetStep);
              return false;            
            });
            
            // Wire up results list rows to load track items (ignore .articleItemDetails)
            $('.fn_tableResultsList tbody tr').not('.articleItemDetails').each(function() {
              
              // If this tr has a link handle click
              if ($(this).find('a').length > 0)
              {
                $(this).find('a').click(function(event) { event.preventDefault(); });
              
                // Wire click events
                $(this).unbind('click').bind('click', function()
                {
                  // Load the result
              		var href = $(this).find('a').attr("href");
              		apps_loadTrackItem(this, href);
                });
              }
            });
            
            // Tweak for .articleItemDetails results list rows
            $('.fn_tableResultsList tbody tr.articleItemDetails').each(function() {
            
              // Set class of previous
              $(this).prev().addClass('hasArticleItemDetails');
            });            
          }
        }
        else
        {
          // Displaying a single result without a results list
          // Remove and create print button
          $(steps).eq(1).find('.module-actions').append('<a href="#" class="fn_print">Print</a>');
          $(steps).eq(1).find('.fn_print').unbind('click').bind('click', function() {
            window.print();
            return false;
          });  
        
          // Insert / handle previous button
          if ($(steps).eq(1).find('.actions .right .btn-previous').length < 1) {
            $(steps).eq(1).find('.actions .right').prepend('<a href="#" class="btn secondary btn-previous"><span class="caret"></span>Previous</a>');
            $(steps).eq(1).find('.actions .right .btn-previous').click(function() {
              // Transition back to step
              var currentStep = $(this).parents('.tools-step');
              var targetStep = $(currentStep).prevAll('.tools-step:first');
              apps_stepTransition(currentStep, targetStep);
              return false;
            });
          }            
        }
      }
      
      // For all steps, wire up any track links (a.fn_track_link)
      if ($('.articleDetailItem a.fn_track_link').length > 0)
      {
        // Wire click events
        $('.articleDetailItem a.fn_track_link').unbind('click').bind('click', function(event) { 
          
          // Load the result
      		var href = $(this).attr("href");
      		apps_loadTrackItem(this, href);

          event.preventDefault(); 
        });
      } 
    }
  }


  /*
   * Currency converter
   *
   */
  if ($('#app_results.fxr').length > 0) {
    if ($('#app_results.fxr .tools-step').eq(1).length > 0) {
      
      // Remove and create print button
      $('#app_results.fxr .tools-step').eq(1).find('.module-actions .fn_print').remove();
      $('#app_results.fxr .tools-step').eq(1).find('.module-actions').append('<a href="#" class="fn_print">Print</a>');
      $('.fn_print').unbind('click').bind('click', function() {
        window.print();
        return false;
      }); 
      
      // Remove and recreate close button
      $('#app_results.fxr .tools-step').eq(1).find('.fn_close').remove();
      $('#app_results.fxr .tools-step').eq(1).find('.module-actions').append('<a href="#" class="fn_close">Close</a>');
      $('.fn_close').unbind('click').bind('click', function() {
        // Transition back to step
        var currentStep = $(this).parents('.tools-step-active');
        var targetStep = $(currentStep).prevAll('.tools-step-active:first');
        apps_stepTransition(currentStep, targetStep);
        return false;
      });
      
      // Enable reset button
      $('#app_results.fxr .tools-step').eq(0).find('.fn_reset').remove();
      $('#app_results.fxr .tools-step').eq(0).find('.module-actions').append('<a href="#" class="fn_reset">Reset</a>');
      $('.fn_reset').unbind('click').bind('click', function() {
        //$(this).parents('.tools-step').find('form')[0].reset();
        //$(this).parents('.tools-step').find('input').each(function() { $(this).val(''); });
        //$('#searchCriteria').val('');
        //$(this).parents('.tools-step').find('select').each(function() {
        //  $(this).find('option:first').attr('selected', true);
        //});
        _clear_form_elements($(this).parents('.tools-step'));
        
        $(this).remove();
        $('#app_results.fxr .tools-step .fn_close').trigger('click');
        return false;
      });             
    }
  }


  /*
   * Postcode search
   *
   */
  if ($('#app_results.pcs').length > 0) {

    // Enable close button
    if ($('#app_results.pcs .tools-step').eq(1).length > 0) {
      
      // Remove and recreate close button
      $('#app_results.pcs .tools-step').eq(1).find('.fn_close').remove();
      
      /* If there are multiple results display close button, else display print and back button */
      if ($('#app_results.pcs .tools-step').eq(1).find('.fn_tablePostcodeList').length > 0) {
      
        $('#app_results.pcs .tools-step').eq(1).find('.module-actions-default').append('<a href="#" class="fn_close">Close</a>');
        $('.fn_close').unbind('click').bind('click', function() {
          // Transition back to step
          var currentStep = $(this).parents('.tools-step-active');
          var targetStep = $(currentStep).prevAll('.tools-step-active:first');
          apps_stepTransition(currentStep, targetStep);
          return false;
        });
      }
      else
      {
        // Remove and create print button
        $('#app_results.pcs .tools-step').eq(1).find('.module-actions-default .fn_print').remove();
        $('#app_results.pcs .tools-step').eq(1).find('.module-actions-default').append('<a href="#" class="fn_print">Print</a>');
        $('.fn_print').unbind('click').bind('click', function() {
          window.print();
          return false;
        });
        
        $('#app_results.pcs .tools-step').eq(1).find('.module-actions-default').append('<a href="#" class="fn_close">Close</a>');
        $('.fn_close').unbind('click').bind('click', function() {
          // Transition back to step
          var currentStep = $(this).parents('.tools-step-active');
          var targetStep = $(currentStep).prevAll('.tools-step-active:first');
          apps_stepTransition(currentStep, targetStep);
          return false;
        });        
      }
    
      // Enable reset button
      $('#app_results.pcs .tools-step').eq(0).find('.fn_reset').remove();
      $('#app_results.pcs .tools-step').eq(0).find('.module-actions').append('<a href="#" class="fn_reset">Reset</a>');
      $('.fn_reset').unbind('click').bind('click', function() {
        $(this).parents('.tools-step').find('form')[0].reset();
        $(this).remove();
		_clear_form_elements($(this).parents('.tools-step'));
        $('#app_results.pcs .tools-step .fn_close').trigger('click');
        return false;
      });
    }
  }
  
  
  /*
   * Postage Calculator
   *
   */
  if ($('#app_results.pac').length > 0) {
  
    // PAC Actions
    
    // PAC steps 1 and 2
    for (var x = 1; x < 3; x++) {
      if ($('#app_results.pac .tools-step').eq(x).length > 0) {
        
        // If this is active, set to reset button
        if ($('#app_results.pac .tools-step').eq(x).hasClass('tools-step-active')) {
          
          // Remove and recreate reset button
          $('#app_results.pac .tools-step').eq(x).find('.module-actions .fn_reset, .module-actions .fn_edit').remove();
          $('#app_results.pac .tools-step').eq(x).find('.module-actions').append('<a href="#" class="fn_reset">Reset</a>');
          $('.fn_reset').unbind('click').bind('click', function() {
            $(this).parents('.tools-step').find('form')[0].reset();
            _clear_form_elements($(this).parents('.tools-step'));
            // If this panel has box size & slider
            if ($(this).parents('.tools-step').find('.parcelDimensionContainer').length > 0) {
              apps_pac_3d_enableDimensionsInput(true);
            }
            
            // If this panel has slider, trigger click to reset it
            $(this).parents('.tools-step').find('.ui-slider').each(function() {              
              $('select.fn_apps_weightSlider').click();
            });
            
            // Reset services            
            $("#servicesTable").find("tr.fn_service").each(function() {
              // If the top level radio is checked (after form reset) then display its kids, else hide them)
              if($(this).find("input[type='radio']:checked:not(.options input[type='radio']:checked)").length>0){
                $(this).addClass("active");
              }
              else
              {
                $(this).removeClass("active");
              }
            });
            
            return false;
          });
        }
        else
        {
          // Else set to edit button with transition
          $('#app_results.pac .tools-step').eq(x).find('.module-actions .fn_reset, .module-actions .fn_edit').remove();
          $('#app_results.pac .tools-step').eq(x).find('.module-actions').append('<a href="#" class="fn_edit">Edit</a>');
          $('.fn_edit').unbind('click').bind('click', function() {
            // Transition back to step
            var currentStep = $('.tools-step-active');
            var targetStep = $(this).parents('.tools-step');
            apps_stepTransition(currentStep, targetStep);
            return false;
          });       
        }
      }
    }
    
    // PAC steps 3 (print button)
    if ($('#app_results.pac .tools-step').eq(3).length > 0) {
    
      // Remove and create print button
      $('#app_results.pac .tools-step').eq(3).find('.module-actions .fn_print').remove();
      $('#app_results.pac .tools-step').eq(3).find('.module-actions').append('<a href="#" class="fn_print">Print</a>');
      $('.fn_print').unbind('click').bind('click', function() {
        window.print();
        return false;
      });
    }
  
    // Insert / manage previous buttons
    if ($('#app_results.pac .tools-step-active .actions .right .btn-previous').length < 1) {
      // Insert back button
      $('#app_results.pac .tools-step-active .actions .right').prepend('<a href="#" class="btn secondary btn-previous"><span class="caret"></span>Previous</a>');
      
      // Wire up back button functionality
      $('#app_results.pac .tools-step-active .actions .btn-previous').click(function() {
        
        // Transition back to step
        var currentStep = $(this).parents('.tools-step');
        var targetStep = $(currentStep).prevAll('.tools-step:first');
        apps_stepTransition(currentStep, targetStep);
        
        return false;
      });
    }
  }
}

/*
 * Validation helper removes .validation object and .error classes from a form
 *
 */
function _apps_validation_clearValidation(form) {
  $(form).find('.validation').slideUp();
  $(form).find('.error').removeClass('error');
}

/*
 * Form reset / clearer helpful function
 *
 */
function _clear_form_elements(ele) {
  $(ele).find(':input').each(function() {
    switch(this.type) {
      case 'password':
      case 'select-multiple':
      case 'select-one':
      case 'text':
      case 'textarea':
          $(this).val('');
          break;
      case 'checkbox':
      case 'radio':
          this.checked = false;
    }
  });
  $('input[type="text"]').filter('[title]').trigger('blur');
}


// Handle PAC services table
function init_apps_pac_servicesTable() {
    var servicesList = $("#servicesTable").find("tr");
    var servicesListLength = $(servicesList).length;
    var i = 0;
    
    // Handle each tr / row of the PAC services table
    $(servicesList).each(function(){
    
        // If this is a fn_service row
        if($(this).hasClass("fn_service")) {
        
            var serviceRow = $(this);
            var serviceOptions = $(this).find("div.fn_options");
            
            // Update services summary table when an input is clicked
            $(serviceRow).find("input").bind("click", function() { 
              apps_updatePacServiceSummary($(this).parents('form:first'));
            });
            
            // Update services summary table when an input is clicked
            $(serviceRow).find(".extraCover input.text").bind("keyup", function() { 
              apps_updatePacServiceSummary($(this).parents('form:first'));
            });            
            
            // Add service click show/hide
            $(serviceRow).find("input[type='radio']").bind("click", function(){
                
                //reset all tooltips
                $("button.infotip, button.tooltip").resetAccessibleTooltip({speed: 250});
                
                apps_reset_servicesList(servicesList);
                $(serviceRow).addClass("active");
                
            });
            
            if($(serviceRow).find("input[type='radio']:checked:not(.options input[type='radio']:checked)").length>0){
                $(serviceRow).addClass("active");
            }
            
            // Add services options click show/hide
            $(serviceOptions).find("ul.controlsList li").each(function(){
                var optionsControlItem = $(this);
                
                if($(optionsControlItem).find("ul.controlsList").length>0){
                    $(optionsControlItem).find("ul.controlsList").hide();
                }
                
                $(optionsControlItem).find("input[type='radio']").bind("click", function() {
                    apps_reset_serviceOptionsList(serviceOptions);
                    $(optionsControlItem).find("ul.controlsList").addClass("active").show();
                });
                
                if ($(optionsControlItem).find("input[type='radio']:checked").length > 0) {
                    $(optionsControlItem).find("ul.controlsList").addClass("active").show();
                }
                
            });
            
            // Extra Cover Section
            $(serviceOptions).find(".extraCover").each(function() {
            
                var parentCheckbox = $(this).parent().find("input[type='checkbox']");
                var extraCoverInput = $(this).find("input[type='text']");
                var dependantService = $(this).find("ul.extraCoverList");
                
                if($(parentCheckbox).attr("checked") == false) {
                    $(extraCoverInput).attr("disabled", "disabled").addClass("disabled");
                    $(dependantService).hide();
                }
                
                $(parentCheckbox).bind("click", function() {
                    if($(parentCheckbox).attr("checked") == true) {
                        $(extraCoverInput).removeAttr("disabled").removeClass("disabled");
                        $(dependantService).show();
                    } else {
                        $(extraCoverInput).attr("disabled", "disabled").addClass("disabled");
                        $(dependantService).hide();
                    }
                    
                });
            });
                        
            //Limit to numeric text only
            $(serviceOptions).find("input.fn_valid_numeric").bind("keypress", function(e){
                if( e.which!=8 && e.which!=0 && (e.which<48 || e.which>57)){
                    return false;
                }                                             
            });
        }
        
    });
}

// Handle PAC service summary table
function apps_updatePacServiceSummary(form) {

  // Check if H3 already exists, set to loading
  if ($(form).find('.pac-services-summary h3').length < 1) {
    $(form).find('.pac-services-summary').prepend('<h3>Your charges at a glance</h3>');
  }
  
  $(form).find('.pac-services-summary h3').addClass('loading');
  
  // Hide and remove the current table summary
  $(form).find('.table-pac-services-summary-wrapper').slideUp(500, function() {
    
    // Remove the old summary table
    $(form).find('.table-pac-services-summary-wrapper table.table-pac-services-summary').remove();
    
    // Load the new summary
    $(form).find('.table-pac-services-summary-wrapper').load($(form).attr('action') + " table.table-pac-services-summary",  $(form).serializeArray(), function() {
      
      // Show table
      $(form).find('.table-pac-services-summary-wrapper').slideDown(500, function() {      
        
        // Turn off loading
        $(form).find('.pac-services-summary h3').removeClass('loading');
      
      });
    });
  });
}


// Handle track item form
function init_forms_trackItem() {
  
  // Handle email notification links
  _apps_track_trackAdviceEmailNotification();

  // Note: This needs to execute before the following .fn_dynamicInputEntries script
  if ($('#trackForm #trackIds').length > 0)
  {
    // Hide the textarea
    $('#trackIds').parents('.trackItemsContainer').hide();
    
    if ($('.trackNumbersWrapper').length < 1) {
    
      // Render the inputs
      var html = '<div class="trackNumbersWrapper clearfix"><div class="trackNumbers fn_dynamicInputEntries">';
      html += '<p>Please enter your tracking number without any spaces or dashes. You can add up to 10 tracking numbers. When you enter a new number an additional input field will appear. </p>';
      
      for (var x = 0; x < 10; x++) {
        html += '<div class="inputContainer clearfix"><label for="num' + x + '" class="visuallyhidden">Tracking number #' + x + '</label><input id="num' + x + '" name="num' + x + '" class="text" type="text" value="" maxlength="50" title="Enter tracking number..."></div>';
      }
      
      html += '<div class="inputContainer inputContainerActions clearfix"><button type="submit" value="Submit" class="button primary">Search</button></div>';
      html += '</div></div>';
      
      $('#trackIds').parents('.trackItemsContainer').after(html);
    }
    
    init_global_forms(); // Inside global.js
  
    // Copy the contents of the dynamic inputs over to the hidden text area on keyup
    var wrapper = $('#trackIds').parents('#trackForm');
    $(wrapper).find('.fn_dynamicInputEntries .inputContainer input.text').unbind('keyup').bind('keyup', function()
    {
      // Grab the textarea element & clear any current value
      var textarea = $('#trackIds');
      $(textarea).val('');

      // Parse all inputs
      var count = 0;
      $(wrapper).find('.fn_dynamicInputEntries .inputContainer input.text').each(function()
      {
        if ($(this).val().length > 0 && $(this).val() != $(this).attr('title'))
        {
          // This input has a value, add it to the textarea
          count++;          
          var value = $(this).val();
          var newLine = (count == 10) ? '' : '\n';
          $(textarea).val($(textarea).val().toString() + value + newLine);
        }
      });
    });
    
    $(wrapper).find('.fn_dynamicInputEntries .inputContainer input.text').bind('blur', function()
    {
      // Grab the textarea element & clear any current value
      var textarea = $('#trackIds');
      $(textarea).val('');

      // Parse all inputs
      var count = 0;
      $(wrapper).find('.fn_dynamicInputEntries .inputContainer input.text').each(function()
      {
        if ($(this).val().length > 0 && $(this).val() != $(this).attr('title'))
        {
          // This input has a value, add it to the textarea
          count++;          
          var value = $(this).val();
          var newLine = (count == 10) ? '' : '\n';
          $(textarea).val($(textarea).val().toString() + value + newLine);
        }
      });
    });    
    
    // Wire up tracking input toggle
    // $('#trackIds').parents('.trackItemsContainer').hide();
  }


  // Dynamic input entry forms
  $('.fn_dynamicInputEntries').each(function() {
    
    // Hide all empty input containers and show the first and action buttons
    $(this).find('.inputContainer input.text').each(function() {
      if (($(this).val().length < 1) || $(this).val() == $(this).attr('title')) {
        $(this).parents('.inputContainer').addClass('hidden');
      }
    });
    $(this).find('.inputContainer.hidden:first, .inputContainerActions').removeClass('hidden');

    // For each key up, determine which inputs should be visible and show a new one if there isn't currently a blank
    $(this).find('.inputContainer input.text').bind('keyup', function() 
    {
      _handleDynamicInputs();
    });
       
  });
  
  if ($('.fn_dynamicInputEntries').length > 0) {
    setInterval(_handleDynamicInputs, 1000);
  }
  
  
  // Recently used track IDs
  if ($('.trackNumbersWrapper').length > 0) {

    // Retrieve track IDs cookies
    var cookies = _apps_getTrackIDCookies();

    if (cookies.length > 0) {

      // Generate HTML for recently used track numbers content
      var html = '';
      
      html += '<h4>Recently used:</h4><ul>';
      for (var x = 0; x < cookies.length; x++)
      {
        html += '<li><a href="' + cookies[x] + '" rel="' + cookies[x] + '">' + cookies[x] + '</a></li>';
      }
      html += '</ul>';
      
      // Add container if not exist
      if ($('.trackNumbersWrapper .trackNumbers-recentlyUsed').length < 1) {
        $('.trackNumbersWrapper').append('<div class="trackNumbers-recentlyUsed"></div>');
      }  

      // Set the recently used HTML
      $('.trackNumbers-recentlyUsed').html(html);

      // Wire up track links
      $('.trackNumbers-recentlyUsed a').click(function() {
        
        // Grab the clicked ID
        var id = $(this).attr('rel');
        
        // Clear the form of all entries, add this ID to the first input, add this ID to the textarea submit the form
        $('#trackForm')[0].reset();      
        $('#trackForm #trackIds').val(id);
        $('#trackForm .trackNumbersWrapper .inputContainer input.text:first').val(id);
        $('#trackForm').submit();
        
        return false;
      });      
    }
  }  
}

function _handleDynamicInputs() {

    // Show a new input element if the current input has a value, and if another input exists
    $('.fn_dynamicInputEntries').find('.inputContainer').not('.inputContainerActions').each(function() {
      
      // Check if the input has a value
      if ($(this).find('input.text').val().length > 0 && $(this).find('input.text').val() != $(this).find('input.text').attr('title'))
      {
        // This input has text, ensure the next item is also visible (if it exists)
        if ($(this).next('.inputContainer').length > 0) {
          
          // Ignore .inputContainerActions
          if (!$(this).next('.inputContainer').hasClass('inputContainerActions'))
          {
            // Make it visible if not already
            $(this).next('.inputContainer').removeClass('hidden');
          }
        }
      }
    });

}

// Track item email notifcations form
function _apps_track_trackAdviceEmailNotification() {
  if ($('.trackAdvice').length > 0) {
    var trackAdvice = $('.trackAdvice');
    var form = $(trackAdvice).parents('form:first');
    
    // Handle form submit (note this is still the main track application form)
    $(form).find('button[type="submit"]').unbind('click').bind('click', function() {
                    
      // Validate email address(es)
      $(trackAdvice).find('h3').addClass('loading');
      
      // Clear placeholder text if applicable
      $(form).find('input[type="text"]').filter('[title]').each(function() {
    		var input = $(this);
    		if (input.val() == input.attr('title')) {
    		  input.val('');
    		}
  	  });
  	    	  
      // Hide and remove content (causes form to be fired twice)      
      //$(trackAdvice).find('.trackAdviceContent').slideUp(500, function() {
              
        // Grab the form data before we clear the current form
        var formData = $(form).serializeArray();
        //alert(formData);
        
        // Empty content from wrapper
        $(trackAdvice).find('.trackAdviceContent').empty();
                
        // Load the next page
        $(trackAdvice).find('.trackAdviceContent').load($(form).attr('action') + " .trackAdviceContent",  formData, function() {

          // Initialise content
          init_forms_trackItem();
          
          // Show content
          $(trackAdvice).find('.trackAdviceContent').slideDown(500, function() {      
            
            // Turn off loading
            $(trackAdvice).find('h3').removeClass('loading');
                      
          });
          
        });
        
      //});      
      
      return false;
    });
  }
}

// Handle recently tracked item searches (as cookies)
function _apps_setTrackIDCookies() {
  var cookies = Array();
  var oldCookies = _apps_getTrackIDCookies();

  // Store the new IDs
  $('.trackNumbersWrapper .inputContainer input.text').each(function () {
    if ($(this).val().length > 0 && $(this).val() != $(this).attr('title')) {
    
      // If not already stored
      if (jQuery.inArray($(this).val(), oldCookies) == -1 && jQuery.inArray($(this).val(), cookies) == -1) {
        cookies.push($(this).val());
      }
    }
  });
  
  // Append the old IDs retrieved from cookies
  for (var x = 0; x < oldCookies.length; x++) {
    cookies.push(oldCookies[x]);
  }
  
  // Now store all IDs as cookies
  for (var x = 0; x < cookies.length; x++) {
    $.cookie('auspost_trackid_' + x, cookies[x], { expires: 1 });
  }

}

function _apps_getTrackIDCookies() {
  var MAX_COOKIES = 10; // Enable max 10
  var cookies = Array();
  for (var x = 0; x < MAX_COOKIES; x++) {
    if ($.cookie('auspost_trackid_' + x)) { cookies.push($.cookie('auspost_trackid_' + x)); }
  }
  return cookies;
}

function apps_reset_servicesList(servicesList) {
    $(servicesList).each(function() {
        $(this).removeClass("active");
    });
}

function apps_reset_serviceOptionsList(serviceOptions){
    $(serviceOptions).find("ul.controlsList li ul.controlsList").hide();
}

/* ########################################################################### *
/* ##### 3D PACKAGE RESIZER
/* ########################################################################### */

var FLASH_SIZER_READY = false;

function fl_setFlashReady(){
    //called by the flash when it has loaded
    apps_pac_3d_focusDetection();
    apps_pac_3d_applyRestrictions();
    apps_pac_3d_updateBox();

    setTimeout(function(){
        apps_pac_3d_setDimensions($(".fn_updateDimensions"), true);                 
    }, 100);
    
    FLASH_SIZER_READY = true;
    
    return false;
}

function init_apps_pac_3d_sizer(){
	//Flash Sizer
	if($("#flashSizerContent").length>0){
		var sizerUrl = $("#flashSizerContent .settings .swfUrl").text();
		
		var flashvars = {};
		var params = {};
		params.menu = "false";
		params.wmode = "transparent";
		params.allowscriptaccess = "always";
		var attributes = {};
		attributes.id = "PackageSizer";
		attributes.name = "PackageSizer";
		attributes.styleclass = "flashSizerContent";
		attributes.tabIndex = "-1";
		swfobject.embedSWF(sizerUrl, "flashSizerContent", "490", "150", "9.0.0", null, flashvars, params, attributes);
	}
	
	apps_pac_3d_updateResizedTextFields = function(width, height, depth) {
		$("#app_results.pac input.fn_sizer_width").val(width).trigger('blur');
		$("#app_results.pac input.fn_sizer_height").val(height).trigger('blur');
		$("#app_results.pac input.fn_sizer_length").val(depth).trigger('blur');
	};

    //"box type" automatic updating
    if($(".fn_updateDimensions").length>0) {
        apps_pac_3d_enableDimensionsInput(true);
        
        $(".fn_updateDimensions").each(function(){
            var dimensionsSelect = $(this);
            
            $(dimensionsSelect).find("option:not(.fn_default)").each(function(){
                var text = $(this).text();
                
                var dimensionsString = text.substring(text.indexOf("(")+1,text.indexOf(")"));
                var dimensions = dimensionsString.split(" x "); 
                
                $(this).data("dimensions", dimensions);
                
                //$(this).text(text.replace("("+dimensionsString+")", ""));
            });
            
            $(dimensionsSelect).bind("change", function(){
                apps_pac_3d_setDimensions(dimensionsSelect, false);
            });
        });
    }

    if($(".fn_hideDimensions:checked").length>0){
        apps_pac_3d_hideDimensions();
    } else if($(".fn_showDimensions:checked").length>0){
        apps_pac_3d_showDimensions();
    }   

    if($(".fn_hideDimensions, .fn_showDimensions").length>0){
        $(".fn_hideDimensions").bind("click", function(){
            apps_pac_3d_hideDimensions();
            
            // IE8 vertical jump fix
            var node = $(this).parents('.tools-step:first').find('.parcelWeightContainer');
            $(node).css('padding-bottom', $(node).css('padding-bottom'));
            if ($('.ie6').length > 0) {
              $(node).css('padding-bottom', '30px');
            }
            fn_ie_jumpfix();
        });
        
        $(".fn_showDimensions").bind("click", function(){
            apps_pac_3d_showDimensions();
            
            // IE8 vertical jump fix
            var node = $(this).parents('.tools-step:first').find('.parcelWeightContainer');
            $(node).css('padding-bottom', $(node).css('padding-bottom'));  
            if ($('.ie6').length > 0) {
              $(node).css('padding-bottom', '30px');
            }
            fn_ie_jumpfix();       
        });     
    }
}

function apps_pac_3d_hideDimensions() {
    $('.parcelDimensionContainer01, .parcelDimensionContainer').addClass('visuallyhidden');
    apps_pac_3d_enableDimensionsInput(false);
    $(".fn_updateDimensions").find("option:selected").removeAttr("selected").find(".fn_default").attr("selected", "selected");
    apps_pac_3d_updateResizedTextFields("", "", "");    
    $(".fn_updateDimensions").attr("disabled", "disabled");
}

function apps_pac_3d_showDimensions() {
    $('.parcelDimensionContainer01, .parcelDimensionContainer').removeClass('visuallyhidden');
    $(".fn_updateDimensions").removeAttr("disabled");
    apps_pac_3d_enableDimensionsInput(true);

    if($("#app_results.pac input.fn_sizer_width").val().length>0 || $("#app_results.pac input.fn_sizer_height").val().length>0 || $("#app_results.pac input.fn_sizer_length").val().length>0){
        setTimeout(function(){
            apps_pac_3d_doBoxResize();
            apps_pac_3d_setDimensions($(".fn_updateDimensions"), true);
        }, 250);
    }
}

function apps_pac_3d_setDimensions(dimensionsSelect, init){
    var selected = $(dimensionsSelect).find("option:selected");
    
    if($(selected).text()=="My own box" && $(".fn_showDimensions:checked").length>0){
        if(init==true){
            //do nothing
        } else {
            apps_pac_3d_updateResizedTextFields("", "", "");    
        }
        
        if(FLASH_SIZER_READY){
            apps_pac_3d_doBoxResize();
        }
        
        apps_pac_3d_enableDimensionsInput(true);
    } else {
        var dimensions = $(selected).data("dimensions");
        
        if(dimensions!=null){
            apps_pac_3d_updateResizedTextFields(dimensions[1], dimensions[2], dimensions[0]);
            
            if(FLASH_SIZER_READY){
                apps_pac_3d_doBoxResize();
            }
            
            apps_pac_3d_enableDimensionsInput(false);
        }
    }
    if ($('.ie6').length > 0) {
      var node = $('.tools-step').find('.parcelWeightContainer');
      $(node).css('padding-bottom', '30px');
    }
    fn_ie_jumpfix();
}

function apps_pac_3d_enableDimensionsInput(enabled){
    if(enabled){
        $("#app_results.pac input.fn_sizer_width").removeAttr("readonly").removeClass("readonly");
        $("#app_results.pac input.fn_sizer_height").removeAttr("readonly").removeClass("readonly");
        $("#app_results.pac input.fn_sizer_length").removeAttr("readonly").removeClass("readonly");     
    } else {
        $("#app_results.pac input.fn_sizer_width").attr("readonly", "readonly").addClass("readonly");
        $("#app_results.pac input.fn_sizer_height").attr("readonly", "readonly").addClass("readonly");
        $("#app_results.pac input.fn_sizer_length").attr("readonly", "readonly").addClass("readonly");
    }
    
    if(FLASH_SIZER_READY){
        try{
            apps_pac_3d_getSizer().Enabled(enabled);
        } catch(e){}
    }
}

function apps_pac_3d_getSizer(){
    return document["PackageSizer"];
}

function fl_writeSizeToTextFields(width, height, depth){
    //apps_pac_3d_updateResizedTextFields(width*10, height*10, depth*10);
    apps_pac_3d_updateResizedTextFields(width, height, depth);
}

function apps_pac_3d_updateBox(){
    $("#app_results.pac input.fn_sizer_width, #app_results.pac input.fn_sizer_height, #app_results.pac input.fn_sizer_length").bind("keyup", function(){
        if(FLASH_SIZER_READY){
            apps_pac_3d_doBoxResize();
        }
    });
}

function apps_pac_3d_doBoxResize(){
    var w = $("#app_results.pac input.fn_sizer_width").val();
    var h = $("#app_results.pac input.fn_sizer_height").val();
    var d = $("#app_results.pac input.fn_sizer_length").val();

    /*if(w>105){
        $("#app_results.pac input.fn_sizer_width").val(105);    
    }
    
    if(h>105){
        $("#app_results.pac input.fn_sizer_height").val(105);   
    }
    
    if(d>105){
        $("#app_results.pac input.fn_sizer_length").val(105);   
    }*/
    
    if(FLASH_SIZER_READY){
        //apps_pac_3d_getSizer().Resize(w/10, h/10, d/10);
        try{
            apps_pac_3d_getSizer().Resize(w, h, d);
        } catch(e){}
    }
}

function apps_pac_3d_focusDetection(){
    $("#PackageSizer").bind("mouseout blur", function(){
        if(FLASH_SIZER_READY){
            try{
                apps_pac_3d_getSizer().OnBlur();
            } catch(e){}
        }
    });
}

function apps_pac_3d_applyRestrictions(){
    $("#app_results.pac .parcelDimensionInputs input.fn_valid_numeric").bind("keypress", function(e){
        if( e.which!=8 && e.which!=0 &&e.which!=46 && (e.which<48 || e.which>57)){
            return false;
        }
    });
}

function init_apps_modal_textInputs(){
    if($(".fn_app_enableTextInputs").length>0){
        $(".fn_app_enableTextInputs").each(function(){
            var list = $(this).parents("ul");
            
            var radio = $(this);
            var inputs = $(this).parents("li").find("input.text");
            
            $(this).parents("li").find("input.fn_valid_numeric").bind("keypress", function(e){
                if( e.which!=8 && e.which!=0 && (e.which<48 || e.which>57)){
                    return false;
                }                                             
            });
            
            $(list).find("li input[type='radio']:not(.fn_app_enableTextInputs)").bind("click", function(){
                $(inputs).attr("disabled", "disabled");
                $(inputs).addClass("disabled");
            });
            
            $(inputs).attr("disabled", "disabled");                         
            $(inputs).addClass("disabled");
            
            $(".fn_app_enableTextInputs").bind("click", function(){
                $(inputs).removeAttr("disabled");
                $(inputs).removeClass("disabled");
            });
            
            if($(this).attr("checked")==true){
                $(inputs).removeAttr("disabled");
                $(inputs).removeClass("disabled");
            }
        });
    }
}

/* ########################################################################### *
/* ##### WEIGHT SLIDER
/* ########################################################################### */

function init_apps_pac_weightSlider(){
	if($("#app_results.pac select.fn_apps_weightSlider").length > 0){
		$("#app_results.pac select.fn_apps_weightSlider").each(function () 
		{ 
		  // Check if not already initialised
		  if ($(this).next('.ui-slider').length < 1) {
		
  		  $(this).selectToUISlider({
    			labels: 6,
    			tooltip: true,
    			tooltipSrc: "text",
    			labelSrc: "value"
    		});
    		
    		$(".ui-slider").each(function(){
    			var firstMargin = $(this).find(".ui-slider-label-show:first-child").css("margin-left");
    			
    			if(firstMargin=="-9px"){
    				$(this).addClass("ui-slider-shortAdjust");
    			}
    		});
    		
  		}
		});
		
		setTimeout(function(){
			if(isIE(6, true)){
				//isIE function sits in global.js
				$(".ui-slider").parents("fieldset.last").css("padding-top", "13px");
			}
		}, 250);
	}
}

/* ########################################################################### *
/* ##### FX RATE
/* ########################################################################### */

/*
function apps_modal_fixes(){
    $(".fn_app_checkOverflow").each(function(){
        if($(this).find(".errors").length==0){
            $(this).addClass("resultsWindow_noScroll"); 
        }
    });
}
*/

function init_fx_rate(){
	//Limit to numeric text only
  $("#app_fxr_form .fn_rate_submit input.fn_valid_numeric").bind("keypress", function(e){
  	if( e.which!=8 && e.which!=0 && e.which!=13 && e.which!=46 && (e.which<48 || e.which>57)){
    	return false;
    }                                             
  });
	
	$("#fxResultTable tr.new").each(function(){
		$(this).mouseover(function(){
			 if(!$(this).hasClass("active")){
			 		$(this).css("cursor", "pointer").addClass("trover").find("img").attr("src", "/static/css/images/fx_arrow_red_highlight.gif");
					$(this).attr("title", "click here for more information");
					$(this).find(".moreInfo label").css("color", "#A80A14");
			 }
			 else{
			 	  $(this).css("cursor", "default");		
			 }
		});
		
		$(this).mouseout(function() {
			if($(this).hasClass("trover") && !$(this).hasClass("active")) {
				$(this).removeClass("trover").find("img").attr("src", "/static/css/images/fx_arrow_red.gif");
				$(this).attr("title", "");
				$(this).find(".moreInfo label").css("color", "#E41300");
			}
		});
	});
}


/* ########################################################################### *
/* ##### CURRENCY CONVERTER (GH20110807)
/* ########################################################################### */

function init_currency() {

  $('.btn-convert-currency-flip').hover(function() 
  {
    $(this).addClass('btn-convert-currency-flip-hover');
  }, function () 
  {
    $(this).removeClass('btn-convert-currency-flip-hover');
  });
}


/* ########################################################################### *
/* ##### AUTOCOMPLETE
/* ########################################################################### */

function init_apps_autocomplete(){
    $(".fn_autocomplete").each(function(){
        var results_width = 207;
        
        if($(this).parents("#module_iWantTo").length>0||$(this).parents("#modal_iWantTo").length>0){
            results_width = 182;
        }
        
        $(this).autocomplete(API_AUTOCOMPLETE, {
            minChars: 3,
            width: results_width,
            matchContains: false,
            autoFill: false,
            captureUsage: true,
            formatItem: function(row, i, max) {
                return row[2] + " " + row[3] + " " + row[1];
            },
            formatMatch: function(row, i, max) {
                return row[2] + " " + row[1];
            },
            formatResult: function(row) {
                return row[2] + " " + row[1];
            },
            onSelection: function() {
                $(".fn_autocomplete").parents("form").find("select option:first").attr("selected", true);
            },
            max: 10
        });         
    });
    
    // Modified by Elvis (29/09/2010) - do automatic autopopulate of suburb/state/country
    // Also the parents("form").find("select option:first") is not required to reset value for these selects.
    $(".fn_autocomplete_short").autocomplete(API_AUTOCOMPLETE, {
        minChars: 3,
        width: 182,
        matchContains: false,
        autoFill: false,
        captureUsage: false,
        formatItem: function(row, i, max) {
            return row[2] + " " + row[3] + " " + row[1];
        },
        formatMatch: function(row, i, max) {
            return row[2] + " " + row[1];
        },
        formatResult: function(row) {
            return row[1];
        },
        onSelection: function(row) {
        
            $(".flg_updateStateOnSuburbChange").find("option[text='"+row[3]+"']").attr("selected","selected");           
            $(".flg_updateSuburbOnPcodeChange").val(row[2]);            
            $(".flg_updateCountry").val("Australia");                                
            //$(".fn_autocomplete_short").parents("form").find("select option:first").attr("selected", true);
        },
        max: 10
    });    
    
    // Added by Elvis (21/09/2010) - function for Suburb autocomplete, and do automatic autopopulate of pcode/state/country
    // Also the parents("form").find("select option:first") is not required to reset value for these selects.
    $(".fn_autocomplete_suburb").autocomplete(API_AUTOCOMPLETE, {
        minChars: 3,
        width: 182,
        matchContains: false,
        autoFill: false,
        captureUsage: false,
        formatItem: function(row, i, max) {
            return row[2] + " " + row[3] + " " + row[1];
        },
        formatMatch: function(row, i, max) {
            return row[2] + " " + row[1];
        },
        formatResult: function(row) {
            return row[2];
        },
        onSelection: function(row) {    
        
            $(".flg_updateStateOnSuburbChange").find("option[text='"+row[3]+"']").attr("selected","selected");            
            $(".flg_updatePcodeOnSuburbChange").val(row[1]);
            $(".flg_updateCountry").val("Australia");        
            //$(".fn_autocomplete_suburb").parents("form").find("select option:first").attr("selected", true);
        },
        max: 10
    }); 
    
    $(".fn_autocomplete_no_pobox").autocomplete(API_AUTOCOMPLETE_NO_POBOX, {
        minChars: 3,
        width: 182,
        matchContains: false,
        autoFill: false,
        captureUsage: false,
        formatItem: function(row, i, max) {
            return row[2] + " " + row[3] + " " + row[1];
        },
        formatMatch: function(row, i, max) {
            return row[2] + " " + row[1];
        },
        formatResult: function(row) {
            return row[1];
        },
        onSelection: function() {
            $(".fn_autocomplete_po_box").parents("form").find("select option:first").attr("selected", true);
        },
        max: 10
    });
    
}

/* ########################################################################### *
/* ##### PLUGINS
/* ########################################################################### */

/* ########################################################################### *
/* ##### - AUTOCOMPLETE
/* ########################################################################### */

/*
 * Autocomplete - jQuery plugin 1.0.2
 *
 * Copyright (c) 2007 Dylan Verheul, Dan G. Switzer, Anjesh Tuladhar, Jörn Zaefferer
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Revision: $Id: jquery.autocomplete.js 5751 2008-06-26 20:12:49Z joern.zaefferer $
 *
 */

;(function($) {
    
$.fn.extend({
    autocomplete: function(urlOrData, options) {
        var isUrl = typeof urlOrData == "string";
        options = $.extend({}, $.Autocompleter.defaults, {
            url: isUrl ? urlOrData : null,
            data: isUrl ? null : urlOrData,
            delay: isUrl ? $.Autocompleter.defaults.delay : 10,
            max: options && !options.scroll ? 10 : 150
        }, options);
        
        // if highlight is set to false, replace it with a do-nothing function
        options.highlight = options.highlight || function(value) { return value; };
        
        // if the formatMatch option is not specified, then use formatItem for backwards compatibility
        options.formatMatch = options.formatMatch || options.formatItem;
        
        return this.each(function() {
            new $.Autocompleter(this, options);
        });
    },
    result: function(handler) {
        return this.bind("result", handler);
    },
    search: function(handler) {
        return this.trigger("search", [handler]);
    },
    flushCache: function() {
        return this.trigger("flushCache");
    },
    setOptions: function(options){
        return this.trigger("setOptions", [options]);
    },
    unautocomplete: function() {
        return this.trigger("unautocomplete");
    }
});

$.Autocompleter = function(input, options) {

    var KEY = {
        UP: 38,
        DOWN: 40,
        DEL: 46,
        TAB: 9,
        RETURN: 13,
        ESC: 27,
        COMMA: 188,
        PAGEUP: 33,
        PAGEDOWN: 34,
        BACKSPACE: 8
    };

    // Create $ object for input element
    var $input = $(input).attr("autocomplete", "off").addClass(options.inputClass);

    var timeout;
    var previousValue = "";
    var cache = $.Autocompleter.Cache(options);
    var hasFocus = 0;
    var lastKeyPressCode;
    var config = {
        mouseDownOnSelect: false
    };
    var select = $.Autocompleter.Select(options, input, selectCurrent, config);
    
    var blockSubmit;
    
    var sentOmniture = false;
    
    // prevent form submit in opera when selecting with return key
    $.browser.opera && $(input.form).bind("submit.autocomplete", function() {
        if (blockSubmit) {
            blockSubmit = false;
            return false;
        }
    });
    
    // only opera doesn't trigger keydown multiple times while pressed, others don't work with keypress at all
    $input.bind(($.browser.opera ? "keypress" : "keydown") + ".autocomplete", function(event) {
        // track last key pressed
        lastKeyPressCode = event.keyCode;
        switch(event.keyCode) {
        
            case KEY.UP:
                event.preventDefault();
                if ( select.visible() ) {
                    select.prev();
                } else {
                    onChange(0, true);
                }
                break;
                
            case KEY.DOWN:
                event.preventDefault();
                if ( select.visible() ) {
                    select.next();
                } else {
                    onChange(0, true);
                }
                break;
                
            case KEY.PAGEUP:
                event.preventDefault();
                if ( select.visible() ) {
                    select.pageUp();
                } else {
                    onChange(0, true);
                }
                break;
                
            case KEY.PAGEDOWN:
                event.preventDefault();
                if ( select.visible() ) {
                    select.pageDown();
                } else {
                    onChange(0, true);
                }
                break;
            
            // matches also semicolon
            case options.multiple && $.trim(options.multipleSeparator) == "," && KEY.COMMA:
            case KEY.TAB:
            case KEY.RETURN:
            case KEY.ENTER:
                if( selectCurrent() ) {
                    // stop default to prevent a form submit, Opera needs special handling
                    event.preventDefault();
                    blockSubmit = true;
                    return false;
                }
                break;
                
            case KEY.ESC:
                select.hide();
                break;
                
            default:
                clearTimeout(timeout);
                timeout = setTimeout(onChange, options.delay);
                break;
        }
    }).focus(function(){
        // track whether the field has focus, we shouldn't process any
        // results if the field no longer has focus
        hasFocus++;
    }).blur(function() {
        hasFocus = 0;
        if (!config.mouseDownOnSelect) {
            hideResults();
        }
    }).click(function() {
        // show select when clicking in a focused field
        if ( hasFocus++ > 1 && !select.visible() ) {
            onChange(0, true);
        }
    }).bind("search", function() {
        // TODO why not just specifying both arguments?
        var fn = (arguments.length > 1) ? arguments[1] : null;
        function findValueCallback(q, data) {
            var result;
            if( data && data.length ) {
                for (var i=0; i < data.length; i++) {
                    if( data[i].result.toLowerCase() == q.toLowerCase() ) {
                        result = data[i];
                        break;
                    }
                }
            }
            if( typeof fn == "function" ) fn(result);
            else $input.trigger("result", result && [result.data, result.value]);
        }
        $.each(trimWords($input.val()), function(i, value) {
            request(value, findValueCallback, findValueCallback);
        });
    }).bind("flushCache", function() {
        cache.flush();
    }).bind("setOptions", function() {
        $.extend(options, arguments[1]);
        // if we've updated the data, repopulate
        if ( "data" in arguments[1] )
            cache.populate();
    }).bind("unautocomplete", function() {
        select.unbind();
        $input.unbind();
        $(input.form).unbind(".autocomplete");
    });
    
    
    function selectCurrent() {
        var selected = select.selected();
        if( !selected )
            return false;
        
        options.onSelection(selected.data);  //Modified by Elvis (21/09/2010) - passes data row to the onSelection function.
        
        var v = selected.result;
        previousValue = v;
        
        if ( options.multiple ) {
            var words = trimWords($input.val());
            if ( words.length > 1 ) {
                v = words.slice(0, words.length - 1).join( options.multipleSeparator ) + options.multipleSeparator + v;
            }
            v += options.multipleSeparator;
        }
        
        $input.val(v);
        hideResultsNow();
        $input.trigger("result", [selected.data, selected.value]);
        return true;
    }
    
    function onChange(crap, skipPrevCheck) {
        if( lastKeyPressCode == KEY.DEL || lastKeyPressCode == KEY.ENTER || lastKeyPressCode == KEY.RETURN) {
            select.hide();
            return;
        }
        
        var currentValue = $input.val();
                
        if ( !skipPrevCheck && currentValue == previousValue )
            return;
        
        previousValue = currentValue;
        
        currentValue = lastWord(currentValue);
        
        if ( currentValue.length >= options.minChars) {
            $input.addClass(options.loadingClass);
            if (!options.matchCase)
                currentValue = currentValue.toLowerCase();
            request(currentValue, receiveData, hideResultsNow);
        } else {
            stopLoading();
            select.hide();
            sentOmniture = false;
        }
    };
    
    function trimWords(value) {
        if ( !value ) {
            return [""];
        }
        var words = value.split( options.multipleSeparator );
        var result = [];
        $.each(words, function(i, value) {
            if ( $.trim(value) )
                result[i] = $.trim(value);
        });
        return result;
    }
    
    function lastWord(value) {
        if ( !options.multiple )
            return value;
        var words = trimWords(value);
        return words[words.length - 1];
    }
    
    // fills in the input box w/the first match (assumed to be the best match)
    // q: the term entered
    // sValue: the first matching result
    function autoFill(q, sValue){
        // autofill in the complete box w/the first match as long as the user hasn't entered in more data
        // if the last user key pressed was backspace, don't autofill
        if( options.autoFill && (lastWord($input.val()).toLowerCase() == q.toLowerCase()) && lastKeyPressCode != KEY.BACKSPACE ) {
            // fill in the value (keep the case the user has typed)
            $input.val($input.val() + sValue.substring(lastWord(previousValue).length));
            // select the portion of the value not typed by the user (so the next character will erase)
            $.Autocompleter.Selection(input, previousValue.length, previousValue.length + sValue.length);
        }
    };

    function hideResults() {
        clearTimeout(timeout);
        timeout = setTimeout(hideResultsNow, 200);
    };

    function hideResultsNow() {
        var wasVisible = select.visible();
        select.hide();
        clearTimeout(timeout);
        stopLoading();
        if (options.mustMatch) {
            // call search and run callback
            $input.search(
                function (result){
                    // if no value found, clear the input box
                    if( !result ) {
                        if (options.multiple) {
                            var words = trimWords($input.val()).slice(0, -1);
                            $input.val( words.join(options.multipleSeparator) + (words.length ? options.multipleSeparator : "") );
                        }
                        else
                            $input.val( "" );
                    }
                }
            );
        }
        if (wasVisible)
            // position cursor at end of input field
            $.Autocompleter.Selection(input, input.value.length, input.value.length);
    };

    /* Update by Ken Shi on 2010-08-30 for Omniture*/
    function receiveData(q, data) {
        if ( data && data.length && hasFocus ) {
            stopLoading();
            select.display(data, q);
            autoFill(q, data[0].value);
            select.show();
            
            // Code Added START 2010-08-30
            if(!sentOmniture && options.captureUsage){
                sentOmniture = true;
                var s=s_gi(s_account);
                s.linkTrackVars='eVar6,prop6,events';
                s.linkTrackEvents='event6';
                s.eVar6=s.prop6='Postcode Search - Popdown';
                s.events='event6';
                s.tl(this,'o','Tool Usage'); 
            }
            // Code Added END 2010-08-30            
        } else {
            hideResultsNow();
        }
    };

    function request(term, success, failure) {
        if (!options.matchCase)
            term = term.toLowerCase();
        var data = cache.load(term);
        // recieve the cached data
        if (data && data.length) {
            success(term, data);
        // if an AJAX url has been supplied, try loading the data now
        } else if( (typeof options.url == "string") && (options.url.length > 0) ){
            
            var extraParams = {
                timestamp: +new Date()
            };
            $.each(options.extraParams, function(key, param) {
                extraParams[key] = typeof param == "function" ? param() : param;
            });
            
            $.ajax({
                // try to leverage ajaxQueue plugin to abort previous requests
                mode: "abort",
                // limit abortion to this input
                port: "autocomplete" + input.name,
                dataType: options.dataType,
                url: options.url,
                data: $.extend({
                    q: lastWord(term),
                    limit: options.max
                }, extraParams),
                success: function(data) {
                    var parsed = options.parse && options.parse(data) || parse(data);
                    cache.add(term, parsed);
                    success(term, parsed);
                }
            });
        } else {
            // if we have a failure, we need to empty the list -- this prevents the the [TAB] key from selecting the last successful match
            select.emptyList();
            failure(term);
        }
    };
    
    function parse(data) {
        var parsed = [];
        var rows = data.split("\n");
        for (var i=0; i < rows.length; i++) {
            var row = $.trim(rows[i]);
            if (row) {
                row = row.split("|");
                parsed[parsed.length] = {
                    data: row,
                    value: row[0],
                    result: options.formatResult && options.formatResult(row, row[0]) || row[0]
                };
            }
        }
        return parsed;
    };

    function stopLoading() {
        $input.removeClass(options.loadingClass);
    };

};

$.Autocompleter.defaults = {
    inputClass: "ac_input",
    resultsClass: "ac_results",
    loadingClass: "ac_loading",
    minChars: 1,
    delay: 400,
    matchCase: false,
    matchSubset: true,
    matchContains: false,
    cacheLength: 10,
    max: 100,
    mustMatch: false,
    extraParams: {},
    selectFirst: true,
    formatItem: function(row) { return row[0]; },
    formatMatch: null,
    onSelection: function(){},
    autoFill: false,
    width: 0,
    multiple: false,
    multipleSeparator: ", ",
    captureUsage: false, // switch on/off to capture usage
    highlight: function(value, term) {
        return value.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + term.replace(/([\^\$\(\)\[\]\{\}\*\.\+\?\|\\])/gi, "\\$1") + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<strong>$1</strong>");
    },
    scroll: true,
    scrollHeight: 180
};

$.Autocompleter.Cache = function(options) {

    var data = {};
    var length = 0;
    
    function matchSubset(s, sub) {
        if (!options.matchCase) 
            s = s.toLowerCase();
        var i = s.indexOf(sub);
        if (i == -1) return false;
        return i == 0 || options.matchContains;
    };
    
    function add(q, value) {
        if (length > options.cacheLength){
            flush();
        }
        if (!data[q]){ 
            length++;
        }
        data[q] = value;
    }
    
    function populate(){
        if( !options.data ) return false;
        // track the matches
        var stMatchSets = {},
            nullData = 0;

        // no url was specified, we need to adjust the cache length to make sure it fits the local data store
        if( !options.url ) options.cacheLength = 1;
        
        // track all options for minChars = 0
        stMatchSets[""] = [];
        
        // loop through the array and create a lookup structure
        for ( var i = 0, ol = options.data.length; i < ol; i++ ) {
            var rawValue = options.data[i];
            // if rawValue is a string, make an array otherwise just reference the array
            rawValue = (typeof rawValue == "string") ? [rawValue] : rawValue;
            
            var value = options.formatMatch(rawValue, i+1, options.data.length);
            
            /* 
                ====================================================================
                MODIFIED SECTION TO ADD CACHING OF POSTCODE AND SUBURBS INDIVIDUALLY 
                ====================================================================
            */
            
            var groupRegExp = new RegExp("([a-zA-z\\s]+)(\\d{4}|\\d{3})", "g");
            
            var matchValue = groupRegExp.exec(value);
            
            //SUBURB
            if ( matchValue[1] === false )
                continue;
                
            var firstChar = matchValue[1].charAt(0).toLowerCase();
            // if no lookup array for this character exists, look it up now
            if( !stMatchSets[firstChar] ) 
                stMatchSets[firstChar] = [];

            // if the match is a string
            var row = {
                value: matchValue[1],
                data: rawValue,
                result: options.formatResult && options.formatResult(rawValue) || matchValue[1]
            };
            
            // push the current match into the set list
            stMatchSets[firstChar].push(row);

            // keep track of minChars zero items
            if ( nullData++ < options.max ) {
                stMatchSets[""].push(row);
            }
            
            //POSTCODE
            if ( matchValue[2] === false )
                continue;
                
            var firstChar = matchValue[2].charAt(0).toLowerCase();
            // if no lookup array for this character exists, look it up now
            if( !stMatchSets[firstChar] ) 
                stMatchSets[firstChar] = [];

            // if the match is a string
            var row = {
                value: matchValue[2],
                data: rawValue,
                result: options.formatResult && options.formatResult(rawValue) || matchValue[2]
            };
            
            // push the current match into the set list
            stMatchSets[firstChar].push(row);

            // keep track of minChars zero items
            if ( nullData++ < options.max ) {
                stMatchSets[""].push(row);
            }
        };

        // add the data items to the cache
        $.each(stMatchSets, function(i, value) {
            // increase the cache size
            options.cacheLength++;
            // add to the cache
            add(i, value);
        });
    }
    
    // populate any existing data
    setTimeout(populate, 25);
    
    function flush(){
        data = {};
        length = 0;
    }
    
    return {
        flush: flush,
        add: add,
        populate: populate,
        load: function(q) {
            if (!options.cacheLength || !length)
                return null;
            /* 
             * if dealing w/local data and matchContains than we must make sure
             * to loop through all the data collections looking for matches
             */
            if( !options.url && options.matchContains ){
                // track all matches
                var csub = [];
                // loop through all the data grids for matches
                for( var k in data ){
                    // don't search through the stMatchSets[""] (minChars: 0) cache
                    // this prevents duplicates
                    if( k.length > 0 ){
                        var c = data[k];
                        $.each(c, function(i, x) {
                            // if we've got a match, add it to the array
                            if (matchSubset(x.value, q)) {
                                csub.push(x);
                            }
                        });
                    }
                }               
                return csub;
            } else 
            // if the exact item exists, use it
            if (data[q]){
                return data[q];
            } else
            if (options.matchSubset) {
                for (var i = q.length - 1; i >= options.minChars; i--) {
                    var c = data[q.substr(0, i)];
                    if (c) {
                        var csub = [];
                        $.each(c, function(i, x) {
                            if (matchSubset(x.value, q)) {
                                csub[csub.length] = x;
                            }
                        });
                        return csub;
                    }
                }
            }
            return null;
        }
    };
};

$.Autocompleter.Select = function (options, input, select, config) {
    var CLASSES = {
        ACTIVE: "ac_over"
    };
    
    var listItems,
        active = -1,
        data,
        term = "",
        needsInit = true,
        element,
        list;
    
    // Create results
    function init() {
        if (!needsInit)
            return;
          
        element = $("<div/>")
        .hide()
        .addClass(options.resultsClass)
        .addClass('module')
        .css("position", "absolute")
        .appendTo(document.body);
        
        $('<div class="module-inner"></div>').appendTo(element);
    
        list = $("<ul/>").appendTo($(element).find('.module-inner')).mouseover( function(event) {
            if(target(event).nodeName && target(event).nodeName.toUpperCase() == 'LI') {
                active = $("li", list).removeClass(CLASSES.ACTIVE).index(target(event));
                $(target(event)).addClass(CLASSES.ACTIVE);            
            }
        }).click(function(event) {
            $(target(event)).addClass(CLASSES.ACTIVE);
            select();
            // TODO provide option to avoid setting focus again after selection? useful for cleanup-on-focus
            input.focus();
            return false;
        }).mousedown(function() {
            config.mouseDownOnSelect = true;
        }).mouseup(function() {
            config.mouseDownOnSelect = false;
        });
        
        if( options.width > 0 )
            element.css("width", options.width);
            
        needsInit = false;
    } 
    
    function target(event) {
        var element = event.target;
        while(element && element.tagName != "LI")
            element = element.parentNode;
        // more fun with IE, sometimes event.target is empty, just ignore it then
        if(!element)
            return [];
        return element;
    }

    function moveSelect(step) {
        listItems.slice(active, active + 1).removeClass(CLASSES.ACTIVE);
        movePosition(step);
        var activeItem = listItems.slice(active, active + 1).addClass(CLASSES.ACTIVE);
        if(options.scroll) {
            var offset = 0;
            listItems.slice(0, active).each(function() {
                offset += this.offsetHeight;
            });
            if((offset + activeItem[0].offsetHeight - list.scrollTop()) > list[0].clientHeight) {
                list.scrollTop(offset + activeItem[0].offsetHeight - list.innerHeight());
            } else if(offset < list.scrollTop()) {
                list.scrollTop(offset);
            }
        }
    };
    
    function movePosition(step) {
        active += step;
        if (active < 0) {
            active = listItems.size() - 1;
        } else if (active >= listItems.size()) {
            active = 0;
        }
    }
    
    function limitNumberOfItems(available) {
        return options.max && options.max < available
            ? options.max
            : available;
    }
    
    function fillList() {
        list.empty();
        var max = limitNumberOfItems(data.length);
        for (var i=0; i < max; i++) {
            if (!data[i])
                continue;
            var formatted = options.formatItem(data[i].data, i+1, max, data[i].value, term);
            if ( formatted === false )
                continue;
            var li = $("<li/>").html( options.highlight(formatted, term) ).addClass(i%2 == 0 ? "ac_even" : "ac_odd").appendTo(list)[0];
            $.data(li, "ac_data", data[i]);
        }
        listItems = list.find("li");
        if ( options.selectFirst ) {
            listItems.slice(0, 1).addClass(CLASSES.ACTIVE);
            active = 0;
        }
        // apply bgiframe if available
        if ( $.fn.bgiframe )
            list.bgiframe();
    }
    
    return {
        display: function(d, q) {
            init();
            data = d;
            term = q;
            fillList();
        },
        next: function() {
            moveSelect(1);
        },
        prev: function() {
            moveSelect(-1);
        },
        pageUp: function() {
            if (active != 0 && active - 8 < 0) {
                moveSelect( -active );
            } else {
                moveSelect(-8);
            }
        },
        pageDown: function() {
            if (active != listItems.size() - 1 && active + 8 > listItems.size()) {
                moveSelect( listItems.size() - 1 - active );
            } else {
                moveSelect(8);
            }
        },
        hide: function() {
            element && element.hide();
            listItems && listItems.removeClass(CLASSES.ACTIVE);
            active = -1;
        },
        visible : function() {
            return element && element.is(":visible");
        },
        current: function() {
            return this.visible() && (listItems.filter("." + CLASSES.ACTIVE)[0] || options.selectFirst && listItems[0]);
        },
        show: function() {
            var offset = $(input).offset();
            element.css({
                width: typeof options.width == "string" || options.width > 0 ? options.width : $(input).width(),
                top: offset.top + input.offsetHeight,
                left: offset.left
            }).show();
            if(options.scroll) {
                list.scrollTop(0);
                list.css({
                    maxHeight: options.scrollHeight,
                    overflow: 'auto'
                });
                
                if($.browser.msie && typeof document.body.style.maxHeight === "undefined") {
                    var listHeight = 0;
                    listItems.each(function() {
                        listHeight += this.offsetHeight;
                    });
                    var scrollbarsVisible = listHeight > options.scrollHeight;
                    list.css('height', scrollbarsVisible ? options.scrollHeight : listHeight );
                    if (!scrollbarsVisible) {
                        // IE doesn't recalculate width when scrollbar disappears
                        listItems.width( list.width() - parseInt(listItems.css("padding-left")) - parseInt(listItems.css("padding-right")) );
                    }
                }
                
            }
        },
        selected: function() {
            var selected = listItems && listItems.filter("." + CLASSES.ACTIVE).removeClass(CLASSES.ACTIVE);
            return selected && selected.length && $.data(selected[0], "ac_data");
        },
        emptyList: function (){
            list && list.empty();
        },
        unbind: function() {
            element && element.remove();
        }
    };
};

$.Autocompleter.Selection = function(field, start, end) {
    if( field.createTextRange ){
        //Removed due to IE bug
        
        /*var selRange = field.createTextRange();
        selRange.collapse(true);
        selRange.moveStart("character", start);
        selRange.moveEnd("character", end);
        selRange.select();*/
    } else if( field.setSelectionRange ){
        field.setSelectionRange(start, end);
    } else {
        if( field.selectionStart ){
            field.selectionStart = start;
            field.selectionEnd = end;
        }
    }
    //field.focus();
};

})(jQuery);

/* ########################################################################### *
/* ##### - JQUERY UI with SLIDER
/* ########################################################################### */

/*
 * jQuery UI 1.7.1
 *
 * Copyright (c) 2009 AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 * http://docs.jquery.com/UI
 */
jQuery.ui||(function(c){var i=c.fn.remove,d=c.browser.mozilla&&(parseFloat(c.browser.version)<1.9);c.ui={version:"1.7.1",plugin:{add:function(k,l,n){var m=c.ui[k].prototype;for(var j in n){m.plugins[j]=m.plugins[j]||[];m.plugins[j].push([l,n[j]])}},call:function(j,l,k){var n=j.plugins[l];if(!n||!j.element[0].parentNode){return}for(var m=0;m<n.length;m++){if(j.options[n[m][0]]){n[m][1].apply(j.element,k)}}}},contains:function(k,j){return document.compareDocumentPosition?k.compareDocumentPosition(j)&16:k!==j&&k.contains(j)},hasScroll:function(m,k){if(c(m).css("overflow")=="hidden"){return false}var j=(k&&k=="left")?"scrollLeft":"scrollTop",l=false;if(m[j]>0){return true}m[j]=1;l=(m[j]>0);m[j]=0;return l},isOverAxis:function(k,j,l){return(k>j)&&(k<(j+l))},isOver:function(o,k,n,m,j,l){return c.ui.isOverAxis(o,n,j)&&c.ui.isOverAxis(k,m,l)},keyCode:{BACKSPACE:8,CAPS_LOCK:20,COMMA:188,CONTROL:17,DELETE:46,DOWN:40,END:35,ENTER:13,ESCAPE:27,HOME:36,INSERT:45,LEFT:37,NUMPAD_ADD:107,NUMPAD_DECIMAL:110,NUMPAD_DIVIDE:111,NUMPAD_ENTER:108,NUMPAD_MULTIPLY:106,NUMPAD_SUBTRACT:109,PAGE_DOWN:34,PAGE_UP:33,PERIOD:190,RIGHT:39,SHIFT:16,SPACE:32,TAB:9,UP:38}};if(d){var f=c.attr,e=c.fn.removeAttr,h="http://www.w3.org/2005/07/aaa",a=/^aria-/,b=/^wairole:/;c.attr=function(k,j,l){var m=l!==undefined;return(j=="role"?(m?f.call(this,k,j,"wairole:"+l):(f.apply(this,arguments)||"").replace(b,"")):(a.test(j)?(m?k.setAttributeNS(h,j.replace(a,"aaa:"),l):f.call(this,k,j.replace(a,"aaa:"))):f.apply(this,arguments)))};c.fn.removeAttr=function(j){return(a.test(j)?this.each(function(){this.removeAttributeNS(h,j.replace(a,""))}):e.call(this,j))}}c.fn.extend({remove:function(){c("*",this).add(this).each(function(){c(this).triggerHandler("remove")});return i.apply(this,arguments)},enableSelection:function(){return this.attr("unselectable","off").css("MozUserSelect","").unbind("selectstart.ui")},disableSelection:function(){return this.attr("unselectable","on").css("MozUserSelect","none").bind("selectstart.ui",function(){return false})},scrollParent:function(){var j;if((c.browser.msie&&(/(static|relative)/).test(this.css("position")))||(/absolute/).test(this.css("position"))){j=this.parents().filter(function(){return(/(relative|absolute|fixed)/).test(c.curCSS(this,"position",1))&&(/(auto|scroll)/).test(c.curCSS(this,"overflow",1)+c.curCSS(this,"overflow-y",1)+c.curCSS(this,"overflow-x",1))}).eq(0)}else{j=this.parents().filter(function(){return(/(auto|scroll)/).test(c.curCSS(this,"overflow",1)+c.curCSS(this,"overflow-y",1)+c.curCSS(this,"overflow-x",1))}).eq(0)}return(/fixed/).test(this.css("position"))||!j.length?c(document):j}});c.extend(c.expr[":"],{data:function(l,k,j){return !!c.data(l,j[3])},focusable:function(k){var l=k.nodeName.toLowerCase(),j=c.attr(k,"tabindex");return(/input|select|textarea|button|object/.test(l)?!k.disabled:"a"==l||"area"==l?k.href||!isNaN(j):!isNaN(j))&&!c(k)["area"==l?"parents":"closest"](":hidden").length},tabbable:function(k){var j=c.attr(k,"tabindex");return(isNaN(j)||j>=0)&&c(k).is(":focusable")}});function g(m,n,o,l){function k(q){var p=c[m][n][q]||[];return(typeof p=="string"?p.split(/,?\s+/):p)}var j=k("getter");if(l.length==1&&typeof l[0]=="string"){j=j.concat(k("getterSetter"))}return(c.inArray(o,j)!=-1)}c.widget=function(k,j){var l=k.split(".")[0];k=k.split(".")[1];c.fn[k]=function(p){var n=(typeof p=="string"),o=Array.prototype.slice.call(arguments,1);if(n&&p.substring(0,1)=="_"){return this}if(n&&g(l,k,p,o)){var m=c.data(this[0],k);return(m?m[p].apply(m,o):undefined)}return this.each(function(){var q=c.data(this,k);(!q&&!n&&c.data(this,k,new c[l][k](this,p))._init());(q&&n&&c.isFunction(q[p])&&q[p].apply(q,o))})};c[l]=c[l]||{};c[l][k]=function(o,n){var m=this;this.namespace=l;this.widgetName=k;this.widgetEventPrefix=c[l][k].eventPrefix||k;this.widgetBaseClass=l+"-"+k;this.options=c.extend({},c.widget.defaults,c[l][k].defaults,c.metadata&&c.metadata.get(o)[k],n);this.element=c(o).bind("setData."+k,function(q,p,r){if(q.target==o){return m._setData(p,r)}}).bind("getData."+k,function(q,p){if(q.target==o){return m._getData(p)}}).bind("remove",function(){return m.destroy()})};c[l][k].prototype=c.extend({},c.widget.prototype,j);c[l][k].getterSetter="option"};c.widget.prototype={_init:function(){},destroy:function(){this.element.removeData(this.widgetName).removeClass(this.widgetBaseClass+"-disabled "+this.namespace+"-state-disabled").removeAttr("aria-disabled")},option:function(l,m){var k=l,j=this;if(typeof l=="string"){if(m===undefined){return this._getData(l)}k={};k[l]=m}c.each(k,function(n,o){j._setData(n,o)})},_getData:function(j){return this.options[j]},_setData:function(j,k){this.options[j]=k;if(j=="disabled"){this.element[k?"addClass":"removeClass"](this.widgetBaseClass+"-disabled "+this.namespace+"-state-disabled").attr("aria-disabled",k)}},enable:function(){this._setData("disabled",false)},disable:function(){this._setData("disabled",true)},_trigger:function(l,m,n){var p=this.options[l],j=(l==this.widgetEventPrefix?l:this.widgetEventPrefix+l);m=c.Event(m);m.type=j;if(m.originalEvent){for(var k=c.event.props.length,o;k;){o=c.event.props[--k];m[o]=m.originalEvent[o]}}this.element.trigger(m,n);return !(c.isFunction(p)&&p.call(this.element[0],m,n)===false||m.isDefaultPrevented())}};c.widget.defaults={disabled:false};c.ui.mouse={_mouseInit:function(){var j=this;this.element.bind("mousedown."+this.widgetName,function(k){return j._mouseDown(k)}).bind("click."+this.widgetName,function(k){if(j._preventClickEvent){j._preventClickEvent=false;k.stopImmediatePropagation();return false}});if(c.browser.msie){this._mouseUnselectable=this.element.attr("unselectable");this.element.attr("unselectable","on")}this.started=false},_mouseDestroy:function(){this.element.unbind("."+this.widgetName);(c.browser.msie&&this.element.attr("unselectable",this._mouseUnselectable))},_mouseDown:function(l){l.originalEvent=l.originalEvent||{};if(l.originalEvent.mouseHandled){return}(this._mouseStarted&&this._mouseUp(l));this._mouseDownEvent=l;var k=this,m=(l.which==1),j=(typeof this.options.cancel=="string"?c(l.target).parents().add(l.target).filter(this.options.cancel).length:false);if(!m||j||!this._mouseCapture(l)){return true}this.mouseDelayMet=!this.options.delay;if(!this.mouseDelayMet){this._mouseDelayTimer=setTimeout(function(){k.mouseDelayMet=true},this.options.delay)}if(this._mouseDistanceMet(l)&&this._mouseDelayMet(l)){this._mouseStarted=(this._mouseStart(l)!==false);if(!this._mouseStarted){l.preventDefault();return true}}this._mouseMoveDelegate=function(n){return k._mouseMove(n)};this._mouseUpDelegate=function(n){return k._mouseUp(n)};c(document).bind("mousemove."+this.widgetName,this._mouseMoveDelegate).bind("mouseup."+this.widgetName,this._mouseUpDelegate);(c.browser.safari||l.preventDefault());l.originalEvent.mouseHandled=true;return true},_mouseMove:function(j){if(c.browser.msie&&!j.button){return this._mouseUp(j)}if(this._mouseStarted){this._mouseDrag(j);return j.preventDefault()}if(this._mouseDistanceMet(j)&&this._mouseDelayMet(j)){this._mouseStarted=(this._mouseStart(this._mouseDownEvent,j)!==false);(this._mouseStarted?this._mouseDrag(j):this._mouseUp(j))}return !this._mouseStarted},_mouseUp:function(j){c(document).unbind("mousemove."+this.widgetName,this._mouseMoveDelegate).unbind("mouseup."+this.widgetName,this._mouseUpDelegate);if(this._mouseStarted){this._mouseStarted=false;this._preventClickEvent=(j.target==this._mouseDownEvent.target);this._mouseStop(j)}return false},_mouseDistanceMet:function(j){return(Math.max(Math.abs(this._mouseDownEvent.pageX-j.pageX),Math.abs(this._mouseDownEvent.pageY-j.pageY))>=this.options.distance)},_mouseDelayMet:function(j){return this.mouseDelayMet},_mouseStart:function(j){},_mouseDrag:function(j){},_mouseStop:function(j){},_mouseCapture:function(j){return true}};c.ui.mouse.defaults={cancel:null,distance:1,delay:0}})(jQuery);;/*
 * jQuery UI Slider 1.7.1
 *
 * Copyright (c) 2009 AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 * http://docs.jquery.com/UI/Slider
 *
 * Depends:
 *  ui.core.js
 */
(function(a){a.widget("ui.slider",a.extend({},a.ui.mouse,{_init:function(){var b=this,c=this.options;this._keySliding=false;this._handleIndex=null;this._detectOrientation();this._mouseInit();this.element.addClass("ui-slider ui-slider-"+this.orientation+" ui-widget ui-widget-content ui-corner-all");this.range=a([]);if(c.range){if(c.range===true){this.range=a("<div></div>");if(!c.values){c.values=[this._valueMin(),this._valueMin()]}if(c.values.length&&c.values.length!=2){c.values=[c.values[0],c.values[0]]}}else{this.range=a("<div></div>")}this.range.appendTo(this.element).addClass("ui-slider-range");if(c.range=="min"||c.range=="max"){this.range.addClass("ui-slider-range-"+c.range)}this.range.addClass("ui-widget-header")}if(a(".ui-slider-handle",this.element).length==0){a('<a href="#"></a>').appendTo(this.element).addClass("ui-slider-handle")}if(c.values&&c.values.length){while(a(".ui-slider-handle",this.element).length<c.values.length){a('<a href="#"></a>').appendTo(this.element).addClass("ui-slider-handle")}}this.handles=a(".ui-slider-handle",this.element).addClass("ui-state-default ui-corner-all");this.handle=this.handles.eq(0);this.handles.add(this.range).filter("a").click(function(d){d.preventDefault()}).hover(function(){a(this).addClass("ui-state-hover")},function(){a(this).removeClass("ui-state-hover")}).focus(function(){a(".ui-slider .ui-state-focus").removeClass("ui-state-focus");a(this).addClass("ui-state-focus")}).blur(function(){a(this).removeClass("ui-state-focus")});this.handles.each(function(d){a(this).data("index.ui-slider-handle",d)});this.handles.keydown(function(i){var f=true;var e=a(this).data("index.ui-slider-handle");if(b.options.disabled){return}switch(i.keyCode){case a.ui.keyCode.HOME:case a.ui.keyCode.END:case a.ui.keyCode.UP:case a.ui.keyCode.RIGHT:case a.ui.keyCode.DOWN:case a.ui.keyCode.LEFT:f=false;if(!b._keySliding){b._keySliding=true;a(this).addClass("ui-state-active");b._start(i,e)}break}var g,d,h=b._step();if(b.options.values&&b.options.values.length){g=d=b.values(e)}else{g=d=b.value()}switch(i.keyCode){case a.ui.keyCode.HOME:d=b._valueMin();break;case a.ui.keyCode.END:d=b._valueMax();break;case a.ui.keyCode.UP:case a.ui.keyCode.RIGHT:if(g==b._valueMax()){return}d=g+h;break;case a.ui.keyCode.DOWN:case a.ui.keyCode.LEFT:if(g==b._valueMin()){return}d=g-h;break}b._slide(i,e,d);return f}).keyup(function(e){var d=a(this).data("index.ui-slider-handle");if(b._keySliding){b._stop(e,d);b._change(e,d);b._keySliding=false;a(this).removeClass("ui-state-active")}});this._refreshValue()},destroy:function(){this.handles.remove();this.range.remove();this.element.removeClass("ui-slider ui-slider-horizontal ui-slider-vertical ui-slider-disabled ui-widget ui-widget-content ui-corner-all").removeData("slider").unbind(".slider");this._mouseDestroy()},_mouseCapture:function(d){var e=this.options;if(e.disabled){return false}this.elementSize={width:this.element.outerWidth(),height:this.element.outerHeight()};this.elementOffset=this.element.offset();var h={x:d.pageX,y:d.pageY};var j=this._normValueFromMouse(h);var c=this._valueMax()-this._valueMin()+1,f;var k=this,i;this.handles.each(function(l){var m=Math.abs(j-k.values(l));if(c>m){c=m;f=a(this);i=l}});if(e.range==true&&this.values(1)==e.min){f=a(this.handles[++i])}this._start(d,i);k._handleIndex=i;f.addClass("ui-state-active").focus();var g=f.offset();var b=!a(d.target).parents().andSelf().is(".ui-slider-handle");this._clickOffset=b?{left:0,top:0}:{left:d.pageX-g.left-(f.width()/2),top:d.pageY-g.top-(f.height()/2)-(parseInt(f.css("borderTopWidth"),10)||0)-(parseInt(f.css("borderBottomWidth"),10)||0)+(parseInt(f.css("marginTop"),10)||0)};j=this._normValueFromMouse(h);this._slide(d,i,j);return true},_mouseStart:function(b){return true},_mouseDrag:function(d){var b={x:d.pageX,y:d.pageY};var c=this._normValueFromMouse(b);this._slide(d,this._handleIndex,c);return false},_mouseStop:function(b){this.handles.removeClass("ui-state-active");this._stop(b,this._handleIndex);this._change(b,this._handleIndex);this._handleIndex=null;this._clickOffset=null;return false},_detectOrientation:function(){this.orientation=this.options.orientation=="vertical"?"vertical":"horizontal"},_normValueFromMouse:function(d){var c,h;if("horizontal"==this.orientation){c=this.elementSize.width;h=d.x-this.elementOffset.left-(this._clickOffset?this._clickOffset.left:0)}else{c=this.elementSize.height;h=d.y-this.elementOffset.top-(this._clickOffset?this._clickOffset.top:0)}var f=(h/c);if(f>1){f=1}if(f<0){f=0}if("vertical"==this.orientation){f=1-f}var e=this._valueMax()-this._valueMin(),i=f*e,b=i%this.options.step,g=this._valueMin()+i-b;if(b>(this.options.step/2)){g+=this.options.step}return parseFloat(g.toFixed(5))},_start:function(d,c){var b={handle:this.handles[c],value:this.value()};if(this.options.values&&this.options.values.length){b.value=this.values(c);b.values=this.values()}this._trigger("start",d,b)},_slide:function(f,e,d){var g=this.handles[e];if(this.options.values&&this.options.values.length){var b=this.values(e?0:1);if((e==0&&d>=b)||(e==1&&d<=b)){d=b}if(d!=this.values(e)){var c=this.values();c[e]=d;var h=this._trigger("slide",f,{handle:this.handles[e],value:d,values:c});var b=this.values(e?0:1);if(h!==false){this.values(e,d,(f.type=="mousedown"&&this.options.animate),true)}}}else{if(d!=this.value()){var h=this._trigger("slide",f,{handle:this.handles[e],value:d});if(h!==false){this._setData("value",d,(f.type=="mousedown"&&this.options.animate))}}}},_stop:function(d,c){var b={handle:this.handles[c],value:this.value()};if(this.options.values&&this.options.values.length){b.value=this.values(c);b.values=this.values()}this._trigger("stop",d,b)},_change:function(d,c){var b={handle:this.handles[c],value:this.value()};if(this.options.values&&this.options.values.length){b.value=this.values(c);b.values=this.values()}this._trigger("change",d,b)},value:function(b){if(arguments.length){this._setData("value",b);this._change(null,0)}return this._value()},values:function(b,e,c,d){if(arguments.length>1){this.options.values[b]=e;this._refreshValue(c);if(!d){this._change(null,b)}}if(arguments.length){if(this.options.values&&this.options.values.length){return this._values(b)}else{return this.value()}}else{return this._values()}},_setData:function(b,d,c){a.widget.prototype._setData.apply(this,arguments);switch(b){case"orientation":this._detectOrientation();this.element.removeClass("ui-slider-horizontal ui-slider-vertical").addClass("ui-slider-"+this.orientation);this._refreshValue(c);break;case"value":this._refreshValue(c);break}},_step:function(){var b=this.options.step;return b},_value:function(){var b=this.options.value;if(b<this._valueMin()){b=this._valueMin()}if(b>this._valueMax()){b=this._valueMax()}return b},_values:function(b){if(arguments.length){var c=this.options.values[b];if(c<this._valueMin()){c=this._valueMin()}if(c>this._valueMax()){c=this._valueMax()}return c}else{return this.options.values}},_valueMin:function(){var b=this.options.min;return b},_valueMax:function(){var b=this.options.max;return b},_refreshValue:function(c){var f=this.options.range,d=this.options,l=this;if(this.options.values&&this.options.values.length){var i,h;this.handles.each(function(p,n){var o=(l.values(p)-l._valueMin())/(l._valueMax()-l._valueMin())*100;var m={};m[l.orientation=="horizontal"?"left":"bottom"]=o+"%";a(this).stop(1,1)[c?"animate":"css"](m,d.animate);if(l.options.range===true){if(l.orientation=="horizontal"){(p==0)&&l.range.stop(1,1)[c?"animate":"css"]({left:o+"%"},d.animate);(p==1)&&l.range[c?"animate":"css"]({width:(o-lastValPercent)+"%"},{queue:false,duration:d.animate})}else{(p==0)&&l.range.stop(1,1)[c?"animate":"css"]({bottom:(o)+"%"},d.animate);(p==1)&&l.range[c?"animate":"css"]({height:(o-lastValPercent)+"%"},{queue:false,duration:d.animate})}}lastValPercent=o})}else{var j=this.value(),g=this._valueMin(),k=this._valueMax(),e=k!=g?(j-g)/(k-g)*100:0;var b={};b[l.orientation=="horizontal"?"left":"bottom"]=e+"%";this.handle.stop(1,1)[c?"animate":"css"](b,d.animate);(f=="min")&&(this.orientation=="horizontal")&&this.range.stop(1,1)[c?"animate":"css"]({width:e+"%"},d.animate);(f=="max")&&(this.orientation=="horizontal")&&this.range[c?"animate":"css"]({width:(100-e)+"%"},{queue:false,duration:d.animate});(f=="min")&&(this.orientation=="vertical")&&this.range.stop(1,1)[c?"animate":"css"]({height:e+"%"},d.animate);(f=="max")&&(this.orientation=="vertical")&&this.range[c?"animate":"css"]({height:(100-e)+"%"},{queue:false,duration:d.animate})}}}));a.extend(a.ui.slider,{getter:"value values",version:"1.7.1",eventPrefix:"slide",defaults:{animate:false,delay:0,distance:0,max:100,min:0,orientation:"horizontal",range:false,step:1,value:0,values:null}})})(jQuery);;

/* ########################################################################### *
/* ##### - SELECT TO UI SLIDER
/* ########################################################################### */

/*
 * --------------------------------------------------------------------
 * jQuery-Plugin - selectToUISlider - creates a UI slider component from a select element(s)
 * by Scott Jehl, scott@filamentgroup.com
 * http://www.filamentgroup.com
 * reference article: http://www.filamentgroup.com/lab/update_jquery_ui_16_slider_from_a_select_element/
 * demo page: http://www.filamentgroup.com/examples/slider_v2/index.html
 * 
 * Copyright (c) 2008 Filament Group, Inc
 * Dual licensed under the MIT (filamentgroup.com/examples/mit-license.txt) and GPL (filamentgroup.com/examples/gpl-license.txt) licenses.
 *
 * Usage Notes: please refer to our article above for documentation
 *  
 * --------------------------------------------------------------------
 */

jQuery.fn.selectToUISlider=function(settings){var selects=jQuery(this);var options=jQuery.extend({labels:3,tooltip:true,tooltipSrc:'text',labelSrc:'value',labelSuffix:null,sliderOptions:null},settings);var handleIds=(function(){var tempArr=[];selects.each(function(){tempArr.push('handle_'+jQuery(this).attr('id'));});return tempArr;})();var selectOptions=(function(){var opts=[];selects.eq(0).find('option').each(function(){opts.push({value:jQuery(this).attr('value'),text:jQuery(this).text()});});return opts;})();var groups=(function(){if(selects.eq(0).find('optgroup').size()>0){var groupedData=[];selects.eq(0).find('optgroup').each(function(i){groupedData[i]={};groupedData[i].label=jQuery(this).attr('label');groupedData[i].options=[];jQuery(this).find('option').each(function(){groupedData[i].options.push({text:jQuery(this).text(),value:jQuery(this).attr('value')});});});return groupedData;}
else return null;})();function isArray(obj){return obj.constructor==Array;}
function ttText(optIndex){return(options.tooltipSrc=='text')?selectOptions[optIndex].text:selectOptions[optIndex].value;}
var sliderOptions={step:1,min:0,orientation:'horizontal',max:selectOptions.length-1,range:selects.length>1,slide:function(e,ui){var thisHandle=jQuery(ui.handle);var textval=ttText(ui.value);thisHandle.attr('aria-valuetext',textval).attr('aria-valuenow',ui.value).find('.ui-slider-tooltip .ttContent').text(textval);var currSelect=jQuery('#'+thisHandle.attr('id').split('handle_')[1]);currSelect.find('option').eq(ui.value).attr('selected','selected');},values:(function(){var values=[];selects.each(function(){values.push(jQuery(this).get(0).selectedIndex);});return values;})()};options.sliderOptions=(settings)?jQuery.extend(sliderOptions,settings.sliderOptions):sliderOptions;selects.unbind('change keyup click').bind('change keyup click',function(){var thisIndex=jQuery(this).get(0).selectedIndex;var thisHandle=jQuery('#handle_'+jQuery(this).attr('id'));var handleIndex=thisHandle.data('handleNum');thisHandle.parents('.ui-slider:eq(0)').slider("values",handleIndex,thisIndex);var textval=ttText(thisIndex);thisHandle.attr('aria-valuetext',textval).attr('aria-valuenow',thisIndex).find('.ui-slider-tooltip .ttContent').text(textval);});var sliderComponent=jQuery('<div></div>');selects.each(function(i){var hidett='';var thisLabel=jQuery('label[for='+jQuery(this).attr('id')+']');var labelText=(thisLabel.size()>0)?'Slider control for '+thisLabel.text()+'':'';var thisLabelId=thisLabel.attr('id')||thisLabel.attr('id','label_'+handleIds[i]).attr('id');if(options.tooltip==false){hidett=' style="display: none;"';}
jQuery('<a '+'href="#" tabindex="0" '+'id="'+handleIds[i]+'" '+'class="ui-slider-handle" '+'role="slider" '+'aria-labelledby="'+thisLabelId+'" '+'aria-valuemin="'+options.sliderOptions.min+'" '+'aria-valuemax="'+options.sliderOptions.max+'" '+'aria-valuenow="'+options.sliderOptions.values[i]+'" '+'aria-valuetext="'+ttText(options.sliderOptions.values[i])+'" '+'><span class="screenReaderContext">'+labelText+'</span>'+'<span class="ui-slider-tooltip ui-widget-content ui-corner-all"'+hidett+'><span class="ttContent"></span>'+'<span class="ui-tooltip-pointer-down ui-widget-content"><span class="ui-tooltip-pointer-down-inner"></span></span>'+'</span></a>').data('handleNum',i).appendTo(sliderComponent);});if(groups){var inc=0;var scale=sliderComponent.append('<dl class="ui-slider-scale ui-helper-reset" role="presentation"></dl>').find('.ui-slider-scale:eq(0)');jQuery(groups).each(function(h){scale.append('<dt style="width: '+(100/groups.length).toFixed(2)+'%'+'; left:'+(h/(groups.length-1)*100).toFixed(2)+'%'+'"><span>'+this.label+'</span></dt>');var groupOpts=this.options;jQuery(this.options).each(function(i){var style=(inc==selectOptions.length-1||inc==0)?'style="display: none;"':'';var labelText=(options.labelSrc=='text')?groupOpts[i].text:groupOpts[i].value;labelText=(options.labelSuffix==null)?labelText:labelText+options.labelSuffix;scale.append('<dd style="left:'+leftVal(inc)+'"><span class="ui-slider-label">'+labelText+'</span><span class="ui-slider-tic ui-widget-content"'+style+'></span></dd>');inc++;});});}
else{var scale=sliderComponent.append('<ol class="ui-slider-scale ui-helper-reset" role="presentation"></ol>').find('.ui-slider-scale:eq(0)');jQuery(selectOptions).each(function(i){var style=(i==selectOptions.length-1||i==0)?'style="display: none;"':'';var labelText=(options.labelSrc=='text')?this.text:this.value;labelText=(options.labelSuffix==null)?labelText:labelText+options.labelSuffix;scale.append('<li style="left:'+leftVal(i)+'"><span class="ui-slider-label">'+labelText+'</span><span class="ui-slider-tic ui-widget-content"'+style+'></span></li>');});}
function leftVal(i){return(i/(selectOptions.length-1)*100).toFixed(2)+'%';}
if(options.labels>1)sliderComponent.find('.ui-slider-scale li:last span.ui-slider-label, .ui-slider-scale dd:last span.ui-slider-label').addClass('ui-slider-label-show');var increm=Math.max(1,Math.round(selectOptions.length/options.labels));for(var j=0;j<selectOptions.length;j+=increm){if((selectOptions.length-j)>increm){sliderComponent.find('.ui-slider-scale li:eq('+j+') span.ui-slider-label, .ui-slider-scale dd:eq('+j+') span.ui-slider-label').addClass('ui-slider-label-show');}}
sliderComponent.find('.ui-slider-scale dt').each(function(i){jQuery(this).css({'left':((100/(groups.length))*i).toFixed(2)+'%'});});sliderComponent.insertAfter(jQuery(this).eq(this.length-1)).slider(options.sliderOptions).attr('role','application').find('.ui-slider-label').each(function(){jQuery(this).css('marginLeft',-jQuery(this).width()/2-9);});sliderComponent.find('.ui-tooltip-pointer-down-inner').each(function(){var bWidth=jQuery('.ui-tooltip-pointer-down-inner').css('borderTopWidth');var bColor=jQuery(this).parents('.ui-slider-tooltip').css('backgroundColor')
jQuery(this).css('border-top',bWidth+' solid '+bColor);});var values=sliderComponent.slider('values');if(isArray(values)){jQuery(values).each(function(i){sliderComponent.find('.ui-slider-tooltip .ttContent').eq(i).text(ttText(this));});}
else{sliderComponent.find('.ui-slider-tooltip .ttContent').eq(0).text(ttText(values));}
return this;}
;
