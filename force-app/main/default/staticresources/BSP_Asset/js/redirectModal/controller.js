var redirectModal = (function() {
	'use strict';

	var j$ = jQuery.noConflict();

	var model = new localState();

	var regex = new RegExp(/^[0-9]{4}$/i); // Postcode regex - only 4 digits

	var my = {

		initialize: function() {
			// Find all the address fields in the popup
			var addressPanel = j$('.comp1_addressPanel');
			var txtName = j$('#ReturnName');
			var txtCompany = j$('#ReturnCompanyName');
			var txtLine1 = addressPanel.find('[id$="txtLine1"]');
			var txtLine2 = addressPanel.find('[id$="txtLine2"]');
			var txtCity = addressPanel.find('[id$="txtCity"]');
			var txtState = addressPanel.find('[id$="txtState"]');
			var txtPostcode = addressPanel.find('[id$="txtPostcode"]');
			var hfDPID = addressPanel.find('[id$="hfDPID"]');
			var txtCountry = addressPanel.find('[id$="txtCountry"]');
			var errorsPanel = j$("#redirectDialog").find('.form-errors');

			model.set('txtLine1', txtLine1);
			model.set('txtLine2', txtLine2);
			model.set('txtCity', txtCity);
			model.set('txtState', txtState);
			model.set('txtPostcode', txtPostcode);
			model.set('hfDPID', hfDPID);
			model.set('txtCountry', txtCountry);
			model.set('txtName', txtName);
			model.set('txtCompany', txtCompany);
			model.set('errorsPanel', errorsPanel);

			// Add all the input fields into an array
			model.set('inputFields', [txtName, txtCompany, txtLine1, txtLine2, txtCity, txtState, txtPostcode, txtCountry]);

			// Run the postcode regex on every key stroke
			txtPostcode.blur(function count() {
				my.regexPostcode(j$(this), this.value);
			});
		},

		// Add Regex for the Postcode (4 digits only)
		regexPostcode: function(element, value)
		{
			var valid = regex.test(value);

			if (valid)
			{
				// Valid, hide error messages and CSS from input element
				model.get('errorsPanel').addClass('hidden');
				element.parent().removeClass('has-error');
			}
			else
			{
				// Invalid, show messages and CSS on input element
				model.get('errorsPanel').removeClass('hidden');
				element.parent().addClass('has-error');
			}

			return valid;
		},

		// Clear all the field values (in case it's the second time the popup has been opened, don't keep old entered data)
		resetForm: function()
		{
			j$.each(model.get('inputFields'), function(){
				this.val(null);
			});
			model.get('hfDPID').val(null);
		},

		// Reset all error messages and flags
		resetValidation: function()
		{
			model.get('errorsPanel').addClass('hidden');
			j$.each(model.get('inputFields'), function(){
				this.parent().removeClass('has-error');
			});
		},

		// Perform redirect form validation
		validateForm: function(callback)
		{
			var hasError = false;
			my.resetValidation();

			j$.each(model.get('inputFields'), function(){
				if(!this.val() && this != model.get('txtLine2') && this != model.get('txtCompany'))
				{
					this.parent().addClass('has-error');
					hasError = true;
				}
			});

			if (!my.regexPostcode(model.get('txtPostcode'), model.get('txtPostcode').val()))
			{
				model.get('txtPostcode').parent().addClass('has-error');
				hasError = true;
			}

			if (hasError)
			{
				model.get('errorsPanel').removeClass('hidden');
			}
			else
			{
				callback();
			}
		},

		newDialog: function(title, isRecall)
		{
			// Reset all the things everytime the dialog is opened
			my.resetForm();
			my.resetValidation();

			// Collapse Terms and Conditions (if expanded)
			document.getElementById('termsAndConditionsText').style.display = 'none';

			// Bring up the dialog
			var dialogController = {
				show : function()
				{
					j$("#redirectDialog").dialog({
						dialogClass: "no-close",
						closeOnEscape: true,
						draggable: false,
						modal: true,
						title: title,
						width: 580,
						resizable: false,
						position: { my: "center", at: "center", of: window },
						buttons: [
							{
								"class": "custom",
								text: "Submit",
								click: function() {
									// Validate thte form and then submit
									my.validateForm(function(){
										// Put all the redirect/recall details into an object which is deserialised in a wrapper class instance (apex)
										var redirectDetails = {
											Name : model.get('txtName').val(),
											Company : model.get('txtCompany').val(),
											AddressLine1 : model.get('txtLine1').val(),
											AddressLine2 : model.get('txtLine2').val(),
											City : model.get('txtCity').val(),
											State : model.get('txtState').val(),
											Postcode : model.get('txtPostcode').val(),
											Country : model.get('txtCountry').val()
										};

										showLoading();

										// VF remoting, submit the request
										BSPConsignmentSearch.submitRedirect(model.get('articleId'), isRecall, redirectDetails, function(response, event){
											if (event.type == 'exception')
											{
												alert(event.message);
												hideLoading();
											}
											else if (response)
											{
												document.getElementById("caseNumber").innerHTML = response.CaseNumber;
												// document.getElementById("returnOrRedirect").innerHTML = isRecall ? "return" : "update the address on";

												// Show a success message
												j$("#redirectDialogSuccessMessage").dialog({
													dialogClass: "no-close",
													closeOnEscape: true,
													draggable: false,
													modal: true,
													title: "Success",
													width: 580,
													resizable: false,
													position: { my: "center", at: "center", of: window },
													buttons: [
														{
															"class": "custom",
															text: "OK",
															click: function() {
																j$(this).dialog("close");
															}
														}
													],
													close: function( event, ui ) {
														// Upon closing, trigger the search function again to update all relevant info
														showLoading();
														searchArticle();
													}
												});

												j$("#redirectDialog").dialog("close");
												hideLoading();
											}
											else
											{
												alert(event.message);
												hideLoading();
											}
										});
									})
								}
							},
							{
								"class": "custom",
								text: "Cancel",
								click: function() {
									j$(this).dialog("close");
								}
							}
						]
					});
				}
			}

			showLoading();

			// Prepopulate address fields with the original sender address
			// If it's an article, find the parent consignment and prepopulate the consignment's sender address
			BSPConsignmentSearch.getCurrentAddress(model.get('articleId'), function(response)
			{
				if (response && response.length > 0)
				{
					var article = response[0];

					// If there is a parent consignment, use that
					if (article.hasOwnProperty('Consignment__r'))
					{
						article = article.Consignment__r;
					}

					// For both redirect and recall, prepopulate name and company
					model.get('txtName').val(article.SenderName__c);
					model.get('txtCompany').val(article.SenderCompany__c);

					// Only prepopulate the rest of the fields when it's recall
					if (isRecall)
					{
						model.get('txtLine1').val(article.SenderAddressLine1__c);
						model.get('txtLine2').val(article.SenderAddressLine2__c);
						model.get('txtCity').val(article.SenderCity__c);
						model.get('txtState').val(article.SenderState__c);
						model.get('txtPostcode').val(article.SenderPostcode__c);
						model.get('txtCountry').val(article.SenderCountryName__c);
					}

					dialogController.show();
				}

				hideLoading();
			},
			{ escape : false });
		},

		checkElgibility : function()
		{
			var redirectButton = j$('#redirectButton');
			var recallButton = j$('#recallButton');
			var disabled = false;
			var tooltipRecall = 'Have parcels that are in-transit returned to you - your contracted return to sender charge applies.';
			var tooltipRedirect = 'Update or correct the address on this parcel. This will add at least 1 day to the delivery time. Your contracted return to sender charge applies.';

			if (model.get('recallInProgress') == true)
			{
				disabled = true;
				tooltipRecall = 'Recall/Redirect is already in progress';
				tooltipRedirect = 'Recall/Redirect is already in progress';
			}
			else if (model.get('eligible') == false)
			{
				disabled = true;
				tooltipRecall = 'We are unable to recall this parcel online at the moment. Please create an enquiry, select RTS and we will be in touch to confirm if we can process your request.';
				tooltipRedirect = 'We are unable to redirect this parcel online at the moment. Please create an enquiry, select RTS and we will be in touch to confirm if we can process your request';
			}

			recallButton.prop('title', tooltipRecall);
			redirectButton.prop('title', tooltipRedirect);

			j$.each([redirectButton, recallButton], function(){
				this.removeClass('disabledButton');
				if (disabled) this.addClass('disabledButton');

				this.tooltip({
					position: {
						my: "center bottom-20",
						at: "center top",
						using: function( position, feedback ) {
							$( this ).css( position );
							$( "<div>" )
							.addClass( "arrow" )
							.addClass( feedback.vertical )
							.addClass( feedback.horizontal )
							.appendTo( this );
						}
					}
				});
			});

			// Hook up the click events
			if (!disabled)
			{
				recallButton.click(function(){
					redirectModal.newDialog('Recall This Item', true);
				});

				redirectButton.click(function(){
					redirectModal.newDialog('Redirect This Item To', false);
				});
			}
		}
	};

	// return a public interface
	return {
		initialize: my.initialize,
		newDialog: my.newDialog,
		checkElgibility: my.checkElgibility,

		// expose the model
		model: model
	};
});