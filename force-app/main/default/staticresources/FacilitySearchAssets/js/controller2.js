var controller = (function() {
	'use strict';

	var j$ = jQuery.noConflict();

	var model = new localState();

	var my = {

		initialize: function() {
			// monitor changes to dom
			my.wireEvents();
			my.wireAccordion();
			my.setPageTitle();

			model.set('searchedAddress', '');

			var searched = model.get('hasSearchedFacility') || 'false';
			if(searched != 'false') {
			    my.searchComplete();
   			}
		},

		/**
		 * Monitor DOM actions
		 */
		wireEvents: function() {
			j$(document).on('keypress', '[id$="txtKeyword"]', my.keywordKeyPress);
			j$(document).on('keypress', '[id$="senderAddress"]', my.searchKeyPress);
			j$(document).on('keypress', '[id$="recipientAddress"]', my.searchKeyPress);

			j$(document).on('click', 'input[type=submit][id$="btnPostcode"]', my.searchPostCode);
			j$(document).on('click', 'input[type=submit][id$="btnSenderAddress"]', my.getCodeAddress);
			j$(document).on('click', 'input[type=submit][id$="btnRecipientAddress"]', my.getCodeAddress);

			j$(document).on('click', 'h3.bobthebuilder', my.accordionClick);

			j$(document).on('click', '#showMap', my.maybeGenerateMap);
		},

		wireAccordion: function() {
			// Load accordion
			j$(".accordion").accordion({
				heightStyle: "content",
				collapsible: true,
				active : "none"
			});
		},

		setPageTitle: function() {
		  	setTimeout(sforce.console.setTabTitle('Network Search'), '500');
			sforce.console.setTabIcon('/img/icon/telescope16.png', null, null);
  		},

		searchComplete: function() {
			my.wireAccordion();
			my.hideProgress();

			var locations = model.get('locations') || [];
			if(model.get('searchMethod') == 'postcode' && locations.length == 0) {
				alert('There were no Facilities related to the search. Please try again, or contact the Administrator.');
				return;
			}

			// hide the network type checkboxes
			my.setNetworkTypeCheckboxDisplay();

			// load the map if needed
			my.maybeGenerateMapMarkers();
		},

		keywordKeyPress: function() {
			my.resetLocalityId();
		},

		showProgress: function() {
			j$('#waitingDiv').show();
		},

		hideProgress: function() {
			j$('#waitingDiv').hide();
		},

		// added by shengpeng.xiao@bluewolf.com at 2014.7.21
		setLocalityId: function(el, item) {
			if(item && item.localityId) {
				j$("input[id*='localityId']").val(item.localityId);
			}
		},

		resetLocalityId: function() {
			j$("input[id*='localityId']").val('');
		},

		/**
		 * enter was pressed on the search boxes
		 */
		searchKeyPress: function(e) {
			if (e.keyCode == 13) {
				j$(e.currentTarget).closest('tr').find('input[type="submit"]').click();
				e.preventDefault();
				e.returnValue = false;
			}
		},

		/**
		 * When accordion item is clicked, the map marker should activated if the map is loaded
		 */
		accordionClick: function(e) {
		    if(!model.get('mapLoaded')) return;

			var $el = j$(e.currentTarget);
			var facilityId = $el.attr('data-facilityId');

			model.set('triggeredClickSource', 'accordion');
			my.highlightMarker(facilityId);
			model.set('triggeredClickSource', '');
  		},

  		goToFacility: function(facilityId) {
			model.set('triggeredClickSource', 'goToFacility');
			my.highlightMarker(facilityId);
			model.set('triggeredClickSource', '');
		},

  		highlightMarker: function(facilityId, isClicked) {
			if(!model.get('mapLoaded')) return;

			console.log('>> highlightMarker: ', facilityId);

			var markers = model.get('mapMarkers') || [];
			for(var i=0;i<markers.length;i++) {
				if(markers[i].facilityId == facilityId) {
					google.maps.event.trigger(markers[i], "click");
					break;
				}
			}
		},

		maybeGenerateMap: function() {
			if(model.get('mapLoaded')) return;

			console.log('>> maybeGenerateMap');

			// generate google map
			var map = new google.maps.Map(j$('#map').get(0), {
				zoom: 10,
				center: new google.maps.LatLng(-37.814, 144.96332),
				mapTypeId: google.maps.MapTypeId.ROADMAP
			});

			model.set('map', map);
			model.set('mapLoaded', true);

			// remove the showmap dom element
			j$('#showMap').remove();

			// generate map markers with the current configuration
			my.maybeGenerateMapMarkers();
  		},

		/**
		 * Clear existing map markers and free up memory
		 */
		maybeClearMapMarkers: function() {
		    console.log('>> maybeClearMapMarkers');

			var markers = model.get('mapMarkers') || [];
			console.log('>> clearing: ' + markers.length + ' map markers.');

			if(markers && markers.length > 0) {
			    // as per https://developers.google.com/maps/documentation/javascript/examples/marker-remove
			    for(var i=0;i<markers.length;i++) {
			        markers[i].setMap(null);
			        google.maps.event.clearInstanceListeners(markers[i]);
       			}
   			}

			model.set('mapMarkers', []);
			model.set('markerGroups', []);
  		},

		/**
		 * Generate map markers only if the map itself has been generated
		 * The map will only be generated once the user clicks show map.
		 */
  		maybeGenerateMapMarkers: function() {
  		    // do nothing if the map isn't loaded
			if(!model.get('mapLoaded')) return;

			console.log('>> maybeGenerateMapMarkers');

			// clear existing markers
			my.maybeClearMapMarkers();

			// generate new markers based on config.
			// NOTE: pnlPageVars is refreshed with AJAX from the server
			// 			This populates a number of variables used here to rebuild the markers
			var defaultLocationId = '';
			var defaultLocationGroupId = '';
			var locations = model.get('locations');
			var map = model.get('map');
			var markerUrl = model.get('markerURL');
			var addressLoc = model.get('addressLoc');
			var recordTypes = model.get('listOfRecordTypes');
			var mapMarkers = [];
			var markerGroups = {};
			console.log('Record Types: ', recordTypes)
			for (var i = 0; i < recordTypes.length; i++) {
				markerGroups[recordTypes[i][0]] = [];
			}

			var latlngbounds = new google.maps.LatLngBounds();
			var infowindow = new google.maps.InfoWindow();

			console.log('Locations: ', locations);
			console.log('addressLoc: ', addressLoc);

			if(locations.length > 0) {
			    defaultLocationId = locations[0][4];
			    defaultLocationGroupId = locations[0][3];

				map.setOptions({
					zoom: 13,
					center: new google.maps.LatLng(locations[0][1], locations[0][2])
				});

				// only plot if locations exist
				for (var i = 0; i < locations.length; i++) {
				    var location = locations[i];
					var marker = new google.maps.Marker({
						position: new google.maps.LatLng(location[1], location[2]),
						map: map,
						title: locations[i][0],
						icon: markerUrl + '/' + locations[i][7] + '.png',
						facilityId: location[4]
					});

					google.maps.event.addListener(marker, 'click', (function(marker, location) {
					    return function(e) {
							infowindow.setContent(location[0] + '<br/>' + location[5] + (location[6] != '' ? ', ' + location[6] : ''));
							infowindow.open(map, marker);

							// ensure the category is selected in the tabs
							// give jquery ui some time to set the
							var $item = j$('#acc' + marker.facilityId);

							// a little bit dodgy but should stop the recursion...
							// should be rewritten
							var triggeredClickSource = model.get('triggeredClickSource') || '';
							if(triggeredClickSource != 'accordion') {
								my.selectTab(location[3]);
								var $item = j$('#acc' + marker.facilityId);
								var $accordion = $item.closest('.accordion');
								var $allItems = $accordion.find('> h3.bobthebuilder');
								var index = $allItems.index($item.get(0));

								$accordion.accordion('option', 'active', index);
       						}
						}
					})(marker, location));

					// save locations
					latlngbounds.extend(new google.maps.LatLng(location[1], location[2]));
					mapMarkers.push(marker);
					markerGroups[location[3]].push(marker);
				}
			}

			// address marker
			if (addressLoc.length > 0) {
				var marker = new google.maps.Marker({
					position: new google.maps.LatLng(addressLoc[0][0], addressLoc[0][1]),
					map: map,
					title: my.getSearchedAddress()
				});

				google.maps.event.addListener(marker, 'click', (function(marker) {
				    return function() {
				        if(my.getSearchedAddress() != '') {
							infowindow.setContent(my.getSearchedAddress());
							infowindow.open(map, marker);
						}
					}
				})(marker));

				latlngbounds.extend(new google.maps.LatLng(addressLoc[0][0], addressLoc[0][1]));
				mapMarkers.push(marker);
			}

			// auto zoom and centre
			if(addressLoc.length > 0 || locations.length > 0) {
				console.log('>> latlngbounds: ', latlngbounds);
				map.fitBounds(latlngbounds);
			}

			// check that the map isnt zoomed in too much
			var currentZoom = map.getZoom();
			var listener = google.maps.event.addListener(map, "idle", function() {
              	if (map.getZoom() > 14) map.setZoom(14);
              	google.maps.event.removeListener(listener);
            });

			// store the map markers so we can clear them later
			model.set('mapMarkers', mapMarkers);
			model.set('markerGroups', markerGroups);

			// update the map marker display to hide the markers not ticked with the network type checkboxes
			console.log('>> checking visibility of markers');
			j$('#facilitysearch-facilitytype input[type=checkbox]').each(function() {
				console.log('>> found checkbox');
				if (!j$(this).is(':checked')) {
					my.toggleGroup(j$(this).attr('id'), false);
    			}
			});

			var hasCase = model.get('caseNetwork');
			if(hasCase && defaultLocationId != '' && defaultLocationGroupId != '') {
			    // check to ensure the default group being selected has its checkbox selected
			    if(!j$('#' + defaultLocationGroupId).is(':checked')) {
			        j$('#' + defaultLocationGroupId).click();
          		}

				my.goToFacility(defaultLocationId);
			}

    	},

		toggleGroup: function(type, checked) {
		    if(!model.get('mapLoaded')) return;

		    var markerGroups = model.get('markerGroups');
//		    console.log('>> type: ', type);
//		    console.log('>> checked: ', checked);
//		    console.log('>> markerGroups: ', markerGroups);

			for (var i = 0; i < markerGroups[type].length; i++) {
				var marker = markerGroups[type][i];
				marker.setVisible(checked);
			}
		},

    	setNetworkTypeCheckboxDisplay: function() {
    		// added by shengpeng.xiao@bluewolf.com at 2014.6.30
        	// check network types. if all the network of on type has no geo location , hide the network type check box
        	var locations = model.get('locations') || [];
			var locationStr = locations.toString();
			// alert("locationStr >>>" + locationStr);
			j$("#facilitysearch-facilitytype input:checkbox").each(function() {
				var recordTypeId = j$(this).attr("id");
				if(locationStr.indexOf(recordTypeId) == -1) {
					j$(this).parent().parent().hide();
				}else {
					j$(this).parent().parent().show();
				}
			});
			// added end
    	},

    	getSearchedAddress: function() {
			if(model.get('searchMethod') == 'address') {
			    return model.get('searchAddress');
   			} else {
   			    return model.get('searchPostCode');
      		}
     	},

		// get geocode address (formated as lat_lng)
		getCodeAddress: function(e) {
			var $el = j$(e.currentTarget);
			var address = $el.closest('tr').find('textarea').val();
			if (address.trim() == "") {
				alert('Please provide address info before clicking search button');
				return;
			}

			model.set('searchMethod', 'address');
			model.set('searchAddress', address);
			model.set('searchPostCode', '');

			var thePostCode;
			var postcodes = address.match(/\d{4}/g);
			if(postcodes && postcodes.length > 0) {
			  thePostCode = postcodes.pop();
			}

			// show waiting
			my.showProgress();

			var geocoder = new google.maps.Geocoder();
			geocoder.geocode({'address': address}, function(results, status) {
				if (status == google.maps.GeocoderStatus.OK) {
					var latlngStr = results[0].geometry.location;

					//pass lat and lng back to Apex
					var locationParameter = latlngStr.lat()+'_'+latlngStr.lng();
					if(thePostCode && /^\d{4}$/.test(thePostCode)) {
					  locationParameter += '_' + thePostCode;
					}
					console.log('Location Parameter: ', locationParameter);

					// action function
					// calls searchComplete() when finished
					doSearchAddress(locationParameter, false);
				} else {
					my.hideProgress();

					alert('Google Maps could not find your address as entered. Please remove some of the finer details of the address (i.e Unit or Level Detail) and try again.'); // previous message 'Seached address not found.'
				}
			});

			e.preventDefault();
			return false;
		},

		searchPostCode: function(e) {
			var $el = j$(e.currentTarget);
			var searchText = $el.closest('tr').find('input[type=text]').val();
			if (searchText.trim() == "") {
				alert('Please provide suburb info before clicking search button');
				return;
			}

			model.set('searchMethod', 'postcode');
			model.set('searchAddress', '');
			model.set('searchPostCode', searchText);

			my.showProgress();

			// action function
			// calls searchComplete() when finished
			doSearchPostcode(false);

			e.preventDefault();
			return false;
		},

		openFacilityDetail: function(facilityId,facilityName) {

			// shouldn't be retrieving..
			// TODO: remove/fix
			model.set('facilityRecordId', facilityId);
			model.set('facilityRecordName', facilityName);

			var contactId = model.get('contactId');

			if(contactId.length>0) {
				console.log('>>>> opening in subtab of contact....');
				//this is from contact service console
				my.fireOpenNewFacilityDetailSubTabEvent(contactId, model.get('facilityRecordId'));
			} else if (sforce.console.isInConsole()) {
				console.log('>>>> opening in subtab of console?????....');
				sforce.console.getEnclosingPrimaryTabId(my.openSubtab);
			} else {
				console.log('>>>> opening in primary tab....');
				sforce.console.openPrimaryTab(null, '/' + model.get('facilityRecordId'), true);
			}
		},

		fireOpenNewFacilityDetailSubTabEvent: function(cId,fId) {
			sforce.console.fireEvent('OpenTabFromFacilitySearch', cId+'_'+fId);
		},

		ckbPreventStatusChangeSynch: function(el) {
			j$("[id='" + el.id + "']").prop('checked', j$(el).is(':checked'));
		},

		networkExternalSystemSynch: function(el) {
			j$('.' + j$(el).attr('class')).val(j$(el).val());
		},

		selectFacility: function(accordionId) {
			var currentAccordion = j$(accordionId);
			var parent = j$(accordionId).parent();
			var arr = parent.find('h3.bobthebuilder');
			var index = parent.find('h3.bobthebuilder').index(currentAccordion);

			console.log(parent.accordion("option", "active"));
			parent.accordion("option", "active", index);
		},

		selectTab: function(recordTypeIdTab) {
			var selectedTab = '#tab' + recordTypeIdTab;
			j$(selectedTab).trigger("click");
		},

		contactFacility: function(method, facilityId, facilityEmail, facilityEscalationEmail, el) {
			console.log('Clicked');
			// alert('contactFacility');
			j$(el).attr("disabled", "disabled");  // Nandan N : added to disable button for INC0563756

			if(method == 'via ServiceNow' && model.get('contactEmail') == '') {
				alert('Contact has no email');
				j$(el).removeAttr("disabled", "disabled");
				return false;
			} else {
				if (model.get('caseCurrentNetwork') != '' && model.get('caseCurrentNetwork') != facilityId) {
					alert('Please use the \'Contact Another Network\' button to contact this Network.');
					return false;
				}

				showFacilitySearchProgress();

				var ckb = j$('#ckbPreventStatusChange_' + facilityId);
				var preventStatusChange = ckb && ckb.is(':checked');
				if(model.get('requiresToSetEmail') == 'true') {
					FacilitySearch2.setTempEmailToContact(model.get('caseContactId'), function(result, event) {
						console.log('>>>> done setting temp email...');
						my.contactFacilityCore(method, facilityId, facilityEmail, facilityEscalationEmail, preventStatusChange, el);
					});
				} else {
					my.contactFacilityCore(method, facilityId, facilityEmail, facilityEscalationEmail, preventStatusChange, el);
				}
			}


			return false;
		},

		contactFacilityCore: function(method, facilityId, facilityEmail, facilityEscalationEmail, preventStatusChange, el) {
			if(model.get('contactRequiresEscalation') == 'true') {
				my.contactViaEmail('URL', facilityId, el, preventStatusChange, (model.get('contactRequiresEscalation') == 'true' ? true : false), facilityEscalationEmail);
			} else {
				if (method == 'Manually' || method == 'via ServiceNow') {
					var externalSystem = '';

					if(method == 'Manually') {
						externalSystem = j$('.pklExternalSystem_' + facilityId).val();
						if(externalSystem == '' || externalSystem == null) {
							externalSystem = j$('.pklExternalSystem1_' + facilityId).val();
						}
						if(externalSystem == '' || externalSystem == null) {
							externalSystem = '';
						}
					}
					my.contactViaManually(facilityId, preventStatusChange,externalSystem);

				} else if (method == 'via MyNetwork') {
					my.contactViaSalesforce(facilityEscalationEmail, facilityId, el, preventStatusChange, false, '');
				} else if (method == 'via Email') {
					my.contactViaEmail('URL', facilityId, el, preventStatusChange, (model.get('contactRequiresEscalation') == 'true' ? true : false), facilityEscalationEmail);
				} else {
					my.contactViaFax(facilityId, preventStatusChange, el);
				}
			}
		},

		contactViaEmail: function(deprecated,facilityID, el, preventStatusChange, contactRequiresEscalation, escalationEmail) {
			var previousText = j$(el).val();
			j$(el).val("Sending...");
			j$(el).attr("disabled", "disabled");

			showFacilitySearchProgress();

			// TODO: remove / fix
			//model.set('emailURL', URL);

			var comments = document.getElementById(facilityID) ? document.getElementById(facilityID).value : '';

			FacilitySearch2.contactViaEmail(comments,facilityID, model.get('caseId'), preventStatusChange, contactRequiresEscalation, escalationEmail, function(returnedCaseId, event) {
				hideFacilitySearchProgress();

				j$(el).val(previousText);
				//j$(el).removeAttr("disabled", "disabled");

				if(event.status){
					if(returnedCaseId == model.get('caseId')){
						if (sforce.console.isInConsole()) {
							sforce.console.getEnclosingTabId(function(result1) {
								sforce.console.getEnclosingPrimaryTabId(function(result2){
									sforce.console.getEnclosingPrimaryTabObjectId(function(result3) {
										sforce.console.closeTab(result1.id);
										sforce.console.openPrimaryTab(result2.id, '/' + result3.id, true);
									});
								});
							});

							alert("Email is sent successfully");
						} else {
							//window.open(emailURL);
							alert("Email is sent successfully");
						}
					} else if(returnedCaseId.indexOf('Error') == 0){
						alert(returnedCaseId);
					}
				} else {
					alert(event.message);
				}
				j$(el).removeAttr("disabled", "disabled");  // Nandan N : Moved the attribute removal at the end for INC0563756
			});
		},

		//remoting call to generate fax PDF
		contactViaFax: function(facilityId, preventStatusChange, el) {
			var previousText = j$(el).val();
			j$(el).val("Sending...");
			j$(el).attr("disabled", "disabled");

			var faxComments = document.getElementById(facilityId).value;
			FacilitySearch2.contactViaFax(facilityId, model.get('caseId'), faxComments, preventStatusChange, function(result, event){

				 hideFacilitySearchProgress();

				 j$(el).val(previousText);
				 //j$(el).removeAttr("disabled");
				 console.log(result);
				 if(event.status && result != null) {
					sforce.console.getEnclosingTabId(function(r) {
						sforce.console.getEnclosingPrimaryTabId(function(primaryTab) {
							sforce.console.getEnclosingPrimaryTabObjectId(function(res) {
								sforce.console.closeTab(r.id);
								sforce.console.openPrimaryTab(primaryTab.id, '/' + res.id, true);
							});
						});
					});

					alert('The Fax has been sent');
				 } else {
					alert(event.message);
				 }
				j$(el).removeAttr("disabled", "disabled");  // Nandan N : Moved the attribute removal at the end for INC0563756
			});
		},

		contactViaSalesforce: function(escalationEmail, facilityId, el, preventStatusChange) { //, el){
			// added by shengpeng.xiao@bluewolf.com 2014.6.18 beginadded by shengpeng.xiao@bluewolf.com 2014.6.18 begin
			// if email1 not specified, prevent the action
			var inputText = j$(el).val();
			j$(el).val("Sending...");
			j$(el).attr("disabled", "disabled");

			// added by shengpeng.xiao@bluewolf.com 2014.6.18 end
			FacilitySearch2.contactViaSalesforce(model.get('caseId'), escalationEmail, facilityId, preventStatusChange, function(result, event) {
				hideFacilitySearchProgress();

				j$(el).val(inputText);
				//j$(el).removeAttr("disabled");

				if(event.status) {
					if(result.indexOf('Error:') == 0) {
						alert(result);
					} else {
						//added by shengpeng.xiao@bluewolf.com at 2014.6.18 begin
						if(result == model.get('caseId')) {
							if (sforce.console.isInConsole()) {
								sforce.console.getEnclosingPrimaryTabId(function(result) {
									sforce.console.getEnclosingPrimaryTabObjectId(function(res) {
										sforce.console.openPrimaryTab(result.id, '/' + res.id, true);
									});
								});
								alert("Email is sent successfully");
							} else {
								//window.open(emailURL);
								 alert("Email is sent successfully");
							}

						}
						//added by shengpeng.xiao@bluewolf.com at 2014.6.18 begin

						/*sforce.console.getEnclosingTabId(function(result){
							sforce.console.closeTab(result.id);
						});*/
						sforce.console.getPrimaryTabIds(function(result){
							//window.console&&console.log('george says: refreshing tab ids: ' + result.ids);
							//window.console&&console.log(result.ids);
							j$.each(result.ids, function(index, value){
								//window.console&&console.log('george says: refreshing tab ' + value);
								//sforce.console.refreshPrimaryTabById(value, false);
								sforce.console.getTabLink(sforce.console.TabLink.SALESFORCE_URL, value, function(r) {
									window.console&&console.log('r.tabLink: ' + r.tabLink);
									sforce.console.openPrimaryTab(value, r.tabLink, true);
								});
							});
						});
					}
				} else {
					alert('System Error: Unable to assign case to Network Queue - ' + event.message + '=====>>>>' + event.where);
				}
				j$(el).removeAttr("disabled", "disabled");  // Nandan N : Moved the attribute removal at the end for INC0563756
			});
		},

		lodgementPoint: function(facilityId){
			//window.console&&console.log('>>> facility id= ' + facilityId);
			my.showProgress();

			console.log('Case Id: ', model.get('caseId'));

			FacilitySearch2.lodgementPoint(model.get('caseId'), facilityId, function(result, event){
				sforce.console.getEnclosingPrimaryTabId(function(er){
					sforce.console.getEnclosingPrimaryTabObjectId(function(res) {
					    my.hideProgress();
						sforce.console.openPrimaryTab(er.id, '/' + res.id, true, '', my.openNetworkSubtab);
					});
				});
				//location.reload();
			});
		},

		/**
		 * It seems that this has never worked or stopped working?
		 */
		openNetworkSubtab: function(result) {
			sforce.console.openSubtab(result.id, '/apex/FacilitySearch?id=' + model.get('caseId') + '&isdtp=vw', true, '', null, function(res) {
				window.console&&console.log('>>> res.success : ' + res.success);
			});
		},

		contactViaManually: function(facilityId, preventStatusChange, externalSystem){
			if(!preventStatusChange) {
				FacilitySearch2.contactViaManually(model.get('caseId'), facilityId, externalSystem, function(result, event) {
					hideFacilitySearchProgress();

					if(event.status) {
						if(result.indexOf('Error') == 0){
							alert('System ' + result);
						} else {
							sforce.console.getEnclosingTabId(function(result) {
								sforce.console.getEnclosingPrimaryTabId(function(r) {
									sforce.console.getEnclosingPrimaryTabObjectId(function(res) {
										sforce.console.closeTab(result.id);
										sforce.console.openPrimaryTab(r.id, '/' + res.id, true);
									});
								});
							});
						}
					} else {
						alert('System Error: Unable to assign case to Network Queue - ' + event.message + '=====>>>>' + event.where);
					}
				});
			} else {
				hideFacilitySearchProgress();
			}
		},

		openSubtab: function(result) {
			if(result.id=='null') {
				sforce.console.openPrimaryTab(null, 'https://'+location.hostname+'/'+model.get('facilityRecordId'), true, model.get('facilityRecordName'), function() { }, 'salesforceTab');
			} else {
				sforce.console.openSubtab(result.id , 'https://'+location.hostname+'/'+model.get('facilityRecordId'), false, model.get('facilityRecordName'), null, function(result) {
				    if(result.success == true) {
						sforce.console.focusSubtabById(result.id,null);
					} else {
						alert('subtab cannot be opened');
					}
    			}, 'salesforceSubtab');
			}
		},

		loadRelatedList: function(uniqueId, title, objectId, relatedFieldNames, isCaseRelated)
		{
			var uniqueIds = {};

			if(j$('#myframe_' + uniqueId).length == 0) {
				j$('#toggler_' + uniqueId).after('<iframe id="myframe_' + uniqueId + '" src="" width="100%" height="0px" frameBorder="0" />');
			}

			if (!uniqueIds.hasOwnProperty(uniqueId))
			{
				uniqueIds[uniqueId] = 1;
			}

			uniqueIds[uniqueId] = uniqueIds[uniqueId] + 1;
			var toggler = j$('#toggler_' + uniqueId);

			if(uniqueIds[uniqueId] % 2 == 0) {
				toggler.html('Hide ' + title);
				j$('#myframe_' + uniqueId).attr('src', '/apex/NetworkDynamicRelatedList?id=' + objectId + '&relatedListFieldNames=' + relatedFieldNames + '&isCaseRelated=' + isCaseRelated);
			} else {
				toggler.html('Show ' + title);
				j$('#myframe_' + uniqueId).attr('src', '');
				j$('#myframe_' + uniqueId).attr('height', '0px');
			}
		},

		resilzeRelatedListFrame: function(id, h)
		{
			if(j$('#myframe_' + id).length > 0)
				j$('#myframe_' + id).attr('height', h);
		}
	};

	// return a public interface
	return {
		initialize: my.initialize,
		wireAccordion: my.wireAccordion,
		showProgress: my.showProgress,
		hideProgress: my.hideProgress,
		searchComplete: my.searchComplete,
		openFacilityDetail: my.openFacilityDetail,
		ckbPreventStatusChangeSynch: my.ckbPreventStatusChangeSynch,
		networkExternalSystemSynch: my.networkExternalSystemSynch,
		selectFacility: my.selectFacility,
		selectTab: my.selectTab,
		contactFacility: my.contactFacility,
		lodgementPoint: my.lodgementPoint,
		openSubtab: my.openSubtab,
		toggleGroup: my.toggleGroup,
		highlightMarker: my.highlightMarker,
		loadRelatedList: my.loadRelatedList,
		resilzeRelatedListFrame: my.resilzeRelatedListFrame,

		// expose the model
		model: model
	};
});