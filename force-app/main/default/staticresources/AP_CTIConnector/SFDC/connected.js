	/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * The main interface between the Cephas generic code and SFDC
 */
define(['util', 'i18next', 'integration', 'agent/voice', 'config', 'SFDC/tracking', 'SFDC/case', 'SFDC/task', 'SFDC/pop'],
            function (util, i18n, sforce, voice, config, tracking, caseObj, task, pop) {
    var log_prefix = "SFDC/connected: ";
    var _searchSettings = null;
	var transId = '';
	var _connectionDate = new Date().getTime() + 'a';
	var multiContacts = 'false'; //Added by APR 13.09
	
    var initialize = function (searchSettings) {
        try {
            console.log(log_prefix + 'initialize');
            _searchSettings = searchSettings;
			console.log(log_prefix + "DATA: " + JSON.stringify(_searchSettings));
            caseObj.initialize(searchSettings.searchCaseKVP);
            sforce.interaction.cti.enableClickToDial();
            sforce.interaction.cti.onClickToDial(dial); 
            sforce.console.addEventListener('CTIEvent', receiveSFMessage);
            sforce.console.onFocusedPrimaryTab(tracking.primaryTabFocused);

            /*
             * Voice: Search on case, then a custom search field, then the ANI
             */
            util.getInstance('voice.pop').subscribe(function (message) {
                console.log(log_prefix + "voice.pop");
                var ixn = message.call;

                try {
                    var aniSearch = function (params) {
                        console.log(log_prefix + "aniSearch");
						
						var ani;
						
                        // end of the line for internal calls
                        if(ixn.callType === 'Inbound' || ixn.callType === 'Internal' || 
								(ixn.callType === 'Consult' && ixn.role === 'RoleDestination') || 
                                ( ixn.callType === 'Outbound' && ixn.userData['ENG_CB_Status'] === 'Success')) { // added extra conditions for Call-Back
							ani = ixn.userData['r_INFO_CustomerANI'];
                            console.log(log_prefix + "is internal call");
							transId = ixn.id;
							
							/** START - APRIVERA - Modified 09/04/17 **/
							j$('#hfInboundJSON').val(j$.toJSON(ixn));

							console.log(log_prefix + "ANI=" + ani);
							if (config.NO_ANI_SEARCH) {
								console.log(log_prefix + "aniSearch - not enabled");

								// go straight to the search
								doSearch(params, 'phoneNumber', ani);
								multiContacts = 'true';
								console.log(log_prefix + " Inbound - aniSearch - not enabled -  multiContacts " + multiContacts);
							} else {
								AP_ConnectorController.findContact('Phone', ani, function (contact) {
									if (contact !== null) {
										if (contact.Id === undefined) { // multiple contacts
											console.log(log_prefix + "contact search - multiple contacts");											
											doSearch(params, 'phoneNumber', ani);	
											multiContacts = 'true';
											console.log(log_prefix + " Inbound - findContact = multiple contacts -  multiContacts " + multiContacts);
										}
										else {
											contact.Name = $("<div/>").html(contact.Name).text(); // contains HTML chars
											console.log(log_prefix + "findContact - " + contact.Id + ", " + contact.Name);
											params.contact = contact;
											pop.start(params);
										}
									}
									else {
										console.log(log_prefix + "contact search - no records found");
										doSearch(params, 'phoneNumber', ani);
										multiContacts = 'true';
										console.log(log_prefix + " Inbound - findContact = no records found -  multiContacts " + multiContacts);
									}
									
								});
								//added by Kalpita for case value pre-populate
								//var ixn = params.ixn;
								var caseMap = {};
								if (ixn.userData !== undefined) {
									var caseMapArray = config.CASE_MAP.split(',');
									console.log('caseMapArray--'+caseMapArray);
									$.each(caseMapArray, function (index, value) {
										console.log('--value--'+value);
										var fieldMap = value.split(':');
										var sfdcField = fieldMap[0];
										console.log('--fieldMap[0]--'+fieldMap[0]);
										if (fieldMap.length > 1) {
											var genesysValue = ixn.userData[fieldMap[1]];
											console.log('--fieldMap[1]--'+fieldMap[1]);
											console.log('--genesysValue--'+genesysValue);
											if (genesysValue !== undefined) {
												console.log(log_prefix + "Map - " + sfdcField + ":" + genesysValue);
												caseMap[sfdcField] = genesysValue;
											}
										}
									});
									console.log('CaseMap .. '+caseMap);
									//if added by Kalpita for prepopulating values from Case_Map into the clearview codes on minicasecomponent
									if(caseMap.EnquiryType && caseMap.EnquiryType.trim() != ''){
										sforce.console.fireEvent('MiniCaseFieldSet_Type', htmlDecode(caseMap.EnquiryType), function(result){console.log('synching from CTI EnquiryType');});
									}
									if(caseMap.ProductType && caseMap.ProductType.trim() != '') {
										sforce.console.fireEvent('MiniCaseFieldSet_ProductCategory__c', htmlDecode(caseMap.ProductType), function(result){console.log('synching from CTI ProductType');});
									}

									if(caseMap.EnquiryType && caseMap.EnquiryType.trim() != '' && caseMap.ProductType && caseMap.ProductType.trim() != '' &&
										caseMap.ProductSubtype && caseMap.ProductSubtype.trim() != '') {
										var typeProduct = caseMap.EnquiryType + '|' +  caseMap.ProductType + '|' + caseMap.ProductSubtype;
										sforce.console.fireEvent('MiniCaseFieldSet_Type_and_Product__c', typeProduct, function(result){console.log('synching from CTI type and product');});
									}

									if(caseMap.ProductSubtype && caseMap.ProductSubtype.trim()){
										sforce.console.fireEvent('MiniCaseFieldSet_ProductSubCategory__c', htmlDecode(caseMap.ProductSubtype), function(result){console.log('synching from CTI  ProductSubtype')});
									}
									if(caseMap.EnquirySubtype && caseMap.EnquirySubtype.trim() != ''){
										sforce.console.fireEvent('MiniCaseFieldSet_EnquirySubType__c', htmlDecode(caseMap.EnquirySubtype), function(result){console.log('synching from CTI EnquirySubtype')});
									}
									if(caseMap.ReferenceID_c != null && caseMap.ReferenceID_c.trim() != '') {
										sforce.console.fireEvent('MiniCaseFieldSet_ReferenceID__c', htmlDecode(caseMap.ReferenceID_c), function(result){});
									}
								}
								//end of added by Kalpita for pre-populate
							}
							/** END - APRIVERA - Modified 09/04/17 **/						
							
                            return;
                        }
						else if(ixn.callType === 'Outbound' && ixn.userData['ENG_CB_Status'] !== 'Success') {
                            ani = ixn.dnis;
							
							/** START - APRIVERA - Modified 09/04/17 **/	
							console.log(log_prefix + "ANI=" + ani);	
							transId = ixn.id;
							
							var trimedObjectDestination = ani.substring(3);
							
							// using the destination attribute locate the contact
							AP_ConnectorController
								.findContact(
									'',trimedObjectDestination,function(contact) {
										console.log(log_prefix + '*** SFDC Debug: - Function return : '+ JSON.stringify(contact));
										
										if (contact !== null) {
											if (contact.Id === undefined) { // multiple contacts
												multiContacts = 'true';
												console.log(log_prefix + " Inbound - findContact = multiple contacts -  multiContacts " + multiContacts);
											}
											else {
												console.log(log_prefix + '*** SFDC Debug: - openPrimaryTab to :'+ contact.Id);
												sforce.console.openPrimaryTab(null, '/' + contact.Id, true);
												
												if(contact.Id.startsWith('003')) {
													console.log(log_prefix + '*** SFDC Debug: - object.Id :'+ contact.Id);
													params.contact = contact; 		//added by Kalpita to get the contact id for task creation on outbound
													pop.start(params); 		  		//added by Kalpita to get the contact id for task creation on outbound 
												} 
												
												//inform workspace of SFobject id for subsequent use in activity creation and transfer
												var newData = '"actionData":{"sfdcObjectId":"' + contact.Id + '","id":"' + ixn.id + '"}';
												console.log(log_prefix + '*** SFDC Debug: - newData :'+ newData);
												sendAttachData(newData);
											}
										}
										else {
											console.log(log_prefix + '*** SFDC Debug: No records found with phone field containing: '
														+ trimedObjectDestination);
											console.log(log_prefix + "No records found with phone field containing: "
														+ ani);
										}
									});
									
							/** END - APRIVERA - Modified 09/04/17 **/	
                        }
						
                        console.log(log_prefix + "aniSearch - finished");
                    };

                    var params = {
                        searchField: message.fieldName,
                        searchValue: message.fieldValue,
                        searchType: searchSettings.voiceSearchType,
                        ixn: ixn,
                        popOnly: ixn.parentCallUri !== undefined, /* just a pop for consult calls */
                        noCase: ixn.callType === 'Outbound'
                    };

                    // do the actual search
                    caseObj.search(params).then(
                        function (contact, caseId, caseNumber) { // success case
                            if (contact !== null) {
                                params.contact = contact;
                                params.caseId = caseId;
                                params.caseNumber = caseNumber;
                                pop.start(params);
                            }
							
                            // else the case search window is open, so do nothing
                        },
                        function () { // fail case
                            return fieldSearch(params);
                        }).then(null,
                        function () {
                            aniSearch(params);
                        });
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }

                console.log(log_prefix + "voice.pop - finished");
            });

            util.getInstance('voice.ended').subscribe(function (message) {
                console.log(log_prefix + "voice.ended");

                try {
                    var ixn = message.call;
                    var id = ixn.id;
									
					//added by Kalpita for moving fireAttachDataEvent to vfpage on close enquiry
					/*sforce.console.fireEvent('fireAttachDataEvent', function(result){
						console.log( log_prefix + "Sending back outcome to WS.");
					});
					*/
					//added by Kalpita to have task creation for all scenarios without entry checks.
					var comments = "";
					if (ixn.notes !== undefined && ixn.notes !== '') {
						comments += "Note:\n" + ixn.notes + '\n\n';
					}
					task.finish(id, comments, ixn, ixn.duration).done(
                            function() {
                                tracking.remove(id)
                            }
                        );
					
                    /*
					if (tracking.exists(id)) {
                        var comments = "";
                        if (ixn.notes !== undefined && ixn.notes !== '') {
                            comments += "Note:\n" + ixn.notes + '\n\n';
                        }

                        task.finish(id, comments, ixn, ixn.duration).done(
                            function() {
                                tracking.remove(id)
                            }
                        );
                    }
                    else {
						
                        console.log(log_prefix + "could not find " + id);
                    }
					*/
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }
            });

            /*
             * Email: Search on case, then a custom search field, then the customer's email address,
             * then open a search screen using the email from address
             */
            util.getInstance('email.pop').subscribe(function (message) {
                console.log(log_prefix + "email.pop");
                var ixn = message.email;
                var params = {
                    searchField: message.fieldName,
                    searchValue: message.fieldValue,
                    searchType: searchSettings.emailSearchType,
                    ixn: ixn
                };

                // do the actual search
                caseObj.search(params).
                    then(
                        function (contact, caseId, caseNumber) { // success case
                            if (contact !== null) {
                                params.contact = contact;
                                params.caseId = caseId;
                                params.caseNumber = caseNumber;
                                pop.start(params);
                            }
                            // else the case search window is open, so do nothing
                        },
                        function() {
                            return fieldSearch(params);
                        }).
                    then(null,
                        function() {
                            return doSearch(params, 'email', ixn.from);
                        }
                    );
            });

            util.getInstance('email.ended').subscribe(function (message) {
                console.log(log_prefix + "email.ended");

                try {
                    var ixn = message.email;
                    var id = ixn.id;

                    if (tracking.exists(id)) {
                        var comments = "";
                        if (ixn.notes !== undefined && ixn.notes !== '') {
                            comments += "Note:\n" + ixn.notes + '\n\n';
                        }

                        comments += "Email\n";
                        comments += "Msg: " + ixn.emailDescription;

                        task.finish(id, comments, ixn, ixn.duration).done(
                            function() {
                                tracking.remove(id)
                            }
                        );
                    }
                    else {
                        console.log(log_prefix + "could not find " + id);
                    }
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }
            });

            /*
             * Chat: Search on case, then a custom search field, then the customer's name,
             * then open a search screen using the email address
             */
            util.getInstance('chat.pop').subscribe(function (message) {
                console.log(log_prefix + "chat.pop");
                var ixn = message.chat;
                var params = {
                    searchField: message.fieldName,
                    searchValue: message.fieldValue,
                    searchType: searchSettings.chatSearchType,
                    ixn: ixn
                };

                // do the actual search
                caseObj.search(params).
                    then(
                        function (contact, caseId, caseNumber) { // success case
                            if (contact !== null) {
                                params.contact = contact;
                                params.caseId = caseId;
                                params.caseNumber = caseNumber;
                                pop.start(params);
                            }
                            // else the case search window is open, so do nothing
                        },
                        function() {
                            return fieldSearch(params);
                        }).
                    then(null,
                        function() {
                            return doSearch(params, null, null);
                        }
                    );
            });

            util.getInstance('chat.ended').subscribe(function (message) {
                console.log(log_prefix + "chat.ended");

                try {
                    var ixn = message.chat;
                    var id = ixn.id;

                    if (tracking.exists(id)) {
                        var comments = "";
                        if (ixn.notes !== undefined && ixn.notes !== '') {
                            comments += "Note:\n" + ixn.notes + '\n\n';
                        }

                        comments += "Transcript:\n" + ixn.transcript;

                        task.finish(id, comments, ixn, ixn.duration).done(
                            function() {
                                tracking.remove(id)
                            }
                        );
                    }
                    else {
                        console.log(log_prefix + "could not find " + id);
                    }
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }
            });

            /******************************************************************************
             *                  Preview Outbound - pop
             ******************************************************************************/
            util.getInstance('preview.pop').subscribe(function (message) {
                console.log(log_prefix + "preview.pop");
                var ixn = message.record;

                var phoneSearch = function () {
                    console.log(log_prefix + "phoneSearch");
                    var phoneNumber = ixn.phone;
                    var params = {
                        ixn: ixn,
                        searchValue: message.fieldValue,
                        popOnly: true
                    };
                    
                    AP_ConnectorController.findContact('Phone', phoneNumber,
                        function (contact) {
                            if (contact !== null) {
                                if (contact.Id === undefined) { // multiple contacts
                                    console.log(log_prefix + "contact search - multiple contacts");
                                    doSearch(params, 'phoneNumber', phoneNumber);
                                }
                                else {
                                    contact.Name = $("<div/>").html(contact.Name).text(); // convert HTML to plain text
                                    console.log(log_prefix + "phoneSearch: " + contact.Id + ", " + contact.Name + " (" + message.record.id + ")");
                                    params.contact = contact;
                                    pop.start(params);
                                }
                            }
                            else {
                                console.log(log_prefix + "contact search - no records found");
                                doSearch(params, 'phoneNumber', phoneNumber);
                            }
                        }
                    );
                    console.log(log_prefix + "phoneSearch - finished");
                };

                var params = {
                    searchField: message.fieldName,
                    searchValue: message.fieldValue,
                    searchType: searchSettings.voiceSearchType,
                    ixn: ixn,
                    popOnly: true
                };
                fieldSearch(params).
                    then(null, phoneSearch);
            });

            /******************************************************************************
             *                  Other functions
             ******************************************************************************/

            /**
             * Find a contact based on a KVP
             * @param params
             * @returns {*}
             */
            var fieldSearch = function(params) {
                var d = $.Deferred();

                var searchField = params.searchField;
                var searchValue = params.searchValue;
                var ixn = params.ixn;
                var searchType = params.searchType || null;

                try {
                    console.log(log_prefix + "fieldSearch");

                    if (searchField !== null &&
                            searchValue !== null) {
                        console.log(log_prefix + "fieldSearch - search field=" + searchField);
                        console.log(log_prefix + "fieldSearch - search value=" + searchValue);

                        if (searchValue !== undefined && searchValue !== '') {
                            AP_ConnectorController.findContact(searchField, searchValue,
                                function (contact) {
                                    if (contact !== null) {
                                        if (contact.Id === undefined) { // multiple contacts
                                            console.log(log_prefix + 'fieldSearch - multiple contacts');
                                            doSearch(params, searchType, searchValue);
                                        }
                                        else {
                                            contact.Name = $("<div/>").html(contact.Name).text(); // convert to non-HTML
                                            console.log(log_prefix + "fieldSearch - " + contact.Id + ", " + contact.Name + " (" + ixn.id + ")");
                                            params.contact = contact;
                                            pop.start(params);
                                            console.log(log_prefix + "fieldSearch - success for " + ixn.id);
                                        }

                                        d.resolve();
                                    }
                                    else {
                                        console.log(log_prefix + "fieldSearch - no field value found");
                                        d.reject();
                                    }
                                }
                            );
                        }
                        else {
                            console.log(log_prefix + "fieldSearch - no field KVP in interaction");
                            d.reject();
                        }
                    }
                    else {
                        console.log(log_prefix + "fieldSearch - no field search");
                        d.reject();
                    }
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                    d.reject();
                }

                console.log(log_prefix + "fieldSearch - finished");
                return d.promise();
            };

            /**
             * Open up the VisualForce search page with the appropriate parameters.
             * @param params - search parameters
             * @param type - the column to show the search parameter
             * @param searchString
             * @returns a promise
             */
            var doSearch = function(params, type, searchString) {
				console.log(log_prefix + "params: " + JSON.stringify(params));				
				console.log(log_prefix + "searchString: " + JSON.stringify(searchString));
                console.log(log_prefix + "doSearch - " + type + ", " + searchString);
                var d = $.Deferred();
                var url = '/apex/SSSWSearch?aId=null'  ;//+ '&ANI=' +  params.ixn.id;

                if (config.NO_DEFAULT_SEARCH) {
                    console.log(log_prefix + "doSearch - not enabled");
                    d.reject();
                }
                else if (searchString !== undefined && searchString !== null && searchString !== '' && type !== null) {
                    if(searchString.toLowerCase() != 'unavailable') {
                    	url += '&ANI=' + searchString;
                    }
                    //url += '&ANI=' + searchString; 
                    console.log(log_prefix + "url=" + url);
                    tracking.setParams(params);
                    sforce.console.openPrimaryTab(null, url, true, 'MyCustomers Search');
                    d.resolve();
                }
                else {
                    console.log(log_prefix + "url=" + url);
                    tracking.setParams(params);
                    sforce.console.openPrimaryTab(null, url, true, 'MyCustomers Search');
                    d.reject();
                }
				

                return d.promise();
            };
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.stack);
        }

        console.log(log_prefix + "initialized");
        util.getInstance('sfdc.connected').publish('initialized');
    };
	
	//method added by Kalpita mapping data	
	function htmlDecode(value){
		return j$('<div/>').html(value).text();
	}

	/** START - APRIVERA - Modified 09/04/17 **/	
	function sendAttachData(newData) {
		console.log("sendAttachData - " + JSON.stringify(newData));
		//processAttachData('{"action":"AttachData","actionData":' + newData + '}');
		processAttachData(newData);
	}

	function processAttachData(objToProcess) {
		console.log('*** SFDC Debug: processAttachData = '+ JSON.stringify(objToProcess));
		//Send(objToProcess);
		Send_KPT(objToProcess); //added by Kalpita
	}
	
	/** END - APRIVERA - Modified 09/04/17 **/		
		
	
	var sendOutcomes = 'false'; //added by Kalpita as identifier 13.09
	
    /**
     * Receive a message from SF
     * @param result
     */
    function receiveSFMessage(result) {
        var msg = JSON.parse(result.message);
		var myObj2 = eval('(' + result.message + ')');
        console.log("receiveSFMessage CTIEvent = " + msg.action);

        if (msg.action === "MarkDone") { // comes from customized SFDC page
            var data = {};

        }
		else if(msg.action === "AttachData") {
			console.log("msg.actionData = " + JSON.stringify(msg.actionData));
			//sendAttachData(msg.actionData);
			console.log("myObj2.actionData = " + myObj2);
			processAttachData(myObj2);
			sendOutcomes = 'true'; //added by Kalpita as identifier 13.09
		}
        else if (msg.action === "ContactSelected") { // comes from Search page
            console.log(log_prefix + "ContactSelected - " + msg.objectId + ", " + msg.id);
            AP_ConnectorController.getContact(msg.objectId, null,
                function (contact) {
                    var params = tracking.getParams(msg.id);
                    if (params !== null) {
                        params.contact = contact;

                        // start the whole process again...
                        //pop.start(params);
                    }
                }
            );
			processAttachData(result.message); // add by kapita 14.09
        }
        else if (msg.action === "CaseSelected") { // comes from Case Search page
            console.log(log_prefix + "CaseSelected - " + msg.objectId + ", " + msg.id);
            AP_ConnectorController.getContact(msg.objectId, null,
                function (contact) {
                    var params = tracking.getParams(msg.id);
                    if (params !== null) {
                        params.contact = contact;
                        params.caseId = msg.caseId;
                        params.caseNumber = msg.caseNumber;

                        // start the whole process again...
                        pop.start(params);
                    }
                }
            );
        }
    }
	
	//method added by Kalpita
	function Send_KPT(message) {
		var requestTimeout = 5000;
		var dataMessage = message;
		if(message.action==='ContactSelected') {
			var msg2 = message;
			//msg2.CI = config.CI;
			dataMessage = msg2;
		}
		else if(sendOutcomes === 'true') {
			var msg = {			
				action: "AttachData",			
				ActionData: {
					id: transId,
					userData:{
						ENG_Outcome_4: message.actionData.ENG_Outcome_4,
						ENG_Outcome_3: message.actionData.ENG_Outcome_3,
						ENG_Outcome_2: message.actionData.ENG_Outcome_2,
						ENG_Outcome_1: message.actionData.ENG_Outcome_1,
						BusinessResultDisplay: message.actionData.BusinessResultDisplay
					}
				},
				CI: config.CI			
			};
			//dataMessage.CI = config.CI;
			dataMessage = JSON.stringify(msg).replace(/&/g , "\\u0026").replace(/#/g , "\\u0023");//JSON.stringify(msg);//.replace(/&/g , "\\u0026").replace(/#/g , "\\u0023");
		}
		
		j$.ajax({
			url : config.URL,
			timeout : requestTimeout,
			data : '/request=' + dataMessage,
			async : false,
			crossDomain : true,
			cache : false,
			dataType : 'jsonp',
			success : function(data) {
				console.log('*** SFDC Debug: Send_KPT - Response sent: '+ data.response);
			},
			error : function(xhr, ajaxOptions, thrownError) {
				console.log('*** SFDC Debug: Response error Send_KPT (' + xhr.status + ' ' + thrownError + ' --' + xhr.responseText);
			}
		});
		
		console.log('*** SFDC Debug: Send_KPT - Message.ActionData: Stringify - '+ JSON.stringify(dataMessage));
	}

	sforce.console.addEventListener('fireAttachDataEvent',  function(result) {
	   var transactionID = j$.cookie('transactionID');
	   var ctiMessageAsJSON = {};

	   ctiMessageAsJSON.action = "AttachData";
	   ctiMessageAsJSON.actionData = {};
	   ctiMessageAsJSON.actionData.SF_UserId = "{!$User.ID}";
	   ctiMessageAsJSON.actionData.id = transactionID;

	   var hfEnquirySubType__c = j$('#hfEnquirySubType__c').val();
	   var hfProductCategory__c = j$('#hfProductCategory__c').val();
	   var hfType = j$('#hfType').val();
	   var hfProductSubCategory__c = j$('#hfProductSubCategory__c').val();

	   var nvcCustomerId = j$('#nvcCustomerId').html();

	   ctiMessageAsJSON.actionData.ENG_Outcome_4 = hfType;
	   ctiMessageAsJSON.actionData.ENG_Outcome_2 = hfProductCategory__c;
	   ctiMessageAsJSON.actionData.ENG_Outcome_3 = hfProductSubCategory__c;
	   ctiMessageAsJSON.actionData.ENG_Outcome_1 = hfEnquirySubType__c;
	   ctiMessageAsJSON.actionData.BusinessResultDisplay = hfType + ' > ' + hfProductCategory__c + ' > ' + hfProductSubCategory__c + ' > ' + hfEnquirySubType__c;
	   ctiMessageAsJSON.actionData.nvcCustomerId = nvcCustomerId;

	   var ctiJson = j$.toJSON(ctiMessageAsJSON);
	   console.log(ctiJson);
	   sforce.console.fireEvent('CTIEvent', ctiJson, function (ctiresult) {
		   for(var key in ctiresult){
			   window.console && console.log(key + '### >>' + ctiresult[key]);
		   }
	   });
	});
		
	
    /**
     * Dial a number via the SFDC "click to dial" functionality.
     * @param request
     */
    function dial(request) {
        var result = JSON.parse(request.result);
        var numberToCall = result.number;
        var caseNumber = null;
        var contactId = null;
        console.log(log_prefix + numberToCall);

        var params = {
            phoneNumber: numberToCall,
            userData: {}
        };

        var getContact = function() {
            var d = $.Deferred();

            if (result.object === 'Contact') {
                caseNumber = caseObj.getCaseNumber(result.objectId);
                contactId = result.objectId;
                console.log(log_prefix + "case number is " + caseNumber + ", contact is " + contactId);
                d.resolve();
            }
            else if (result.object === 'Account') {
                contactId = result.contactId;
                console.log(log_prefix + "contact is " + contactId);
                d.resolve();
            }
            else if (result.object === 'Case') {
                caseNumber = result.objectName;
                console.log(log_prefix + "case number is " + caseNumber);
                d.resolve();
            }
            else if (result.object === 'Task') {
                var taskId = result.objectId;
                console.log(log_prefix + "task is " + taskId);

                AP_ConnectorController.getContactByTask(taskId,
                    function (task) {
                        contactId = task.WhoId;
                        caseNumber = task.CallObject;
                        console.log(log_prefix + "contact is " + contactId + ", case number is " + caseNumber);
                        d.resolve();
                    }
                );
            }
            else {
                console.log(log_prefix + "object is " + result.object);
                d.resolve();
            }

            return d;
        };

        var getDetails = function () {
            var d = $.Deferred();

            try {
                // make sure we can bring up an existing case/contact
                if (_searchSettings.searchVoiceKVP !== "") {

                    // get the contact id
                    getContact().done(function() {
                        if (caseNumber !== null && _searchSettings.searchCaseKVP !== "") {
                            params.userData[_searchSettings.searchCaseKVP] = caseNumber;
                        }

                        if (contactId !== null) {
                            AP_ConnectorController.getContact(contactId, _searchSettings.searchVoiceField,
                                function (contact) {
                                    if (contact !== null) {
                                        var voiceField = contact[_searchSettings.searchVoiceField];

                                        if (voiceField !== null) {
                                            console.log(log_prefix + "voice field is " + voiceField);
                                            params.userData[_searchSettings.searchVoiceKVP] = voiceField;
                                        }
                                    }

                                    d.resolve();
                                }
                            );
                        }
                        else {
                            d.resolve();
                        }
                    });
                }
                else {
                    d.resolve();
                }
            }
            catch (e) {
                console.error(log_prefix + e.stack);
                d.resolve();
            }

            return d;
        };

        getDetails().done(
            function () {
                voice.dial(params);
            });
    }

    return {
        initialize: initialize
    };
});