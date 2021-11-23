/*==================================================================================================
 * Description: Applies business rules to the form.
 * Remarks:
 * [2012-02-13] - Script creation. [Karl Balemi]
 =================================================================================================*/

$(document).ready(function(){
	
	var eparcelAccApp = false;
	var creditAccApp = false;

	//hide the trust details section
	$('#trust-details').hide();
	$('#cred-acc-2').hide();
	$('#cred-acc-3').hide();
	$('#cred-acc-4').hide();
	
	$('#credit-acc-app').hide();
	$('#eparcel-acc-app').hide();
	$('#terms-conditions').hide();
	
	$('#terms-conditions-business-credit').hide();
	$('#terms-conditions-eparcel').hide();
	
	//hide or show the trust details section depending on trust details check box	
	$('#tt-checkbox').click(function() {
		if($(this).is(':checked')) {			
			$('#trust-details').show();			
		}
		else {
			$('#trust-details').hide();
		}		
	});
	
	$('.cred-acc-1-radio').click(function(){
		if($('#cred-acc-1-yes').is(':checked')) {
			$('#cred-acc-2').show();
			$('#cred-acc-3').hide();
			$('#cred-acc-4').hide();
		}
		else {
			$('#cred-acc-2').hide();
			$('#cred-acc-3').show();
		}
		
	});
	
	$('.cred-acc-3-radio').click(function(){
		if($('#cred-acc-3-yes').is(':checked')) {
			$('#cred-acc-4').show();
			$('#cred-acc-5').show();
			$('#cred-acc-6').show();
			creditAccApp = true;
		}
		else {
			$('#cred-acc-4').hide();
			$('#cred-acc-5').hide();
			$('#cred-acc-6').hide();
			creditAccApp = false;
		}
	});
	
	$('.cred-acc-4-radio').click(function(){
		if($('#cred-acc-4-yes').is(':checked')) {
			$('#cred-acc-5').hide();
			$('#cred-acc-6').hide();
		}
		else {
			$('#cred-acc-5').show();
			$('#cred-acc-6').show();
		}
	});
	
	$('.cred-acc-5-radio').click(function(){
		if($('#cred-acc-5-less500').is(':checked')) {
			$('#cred-acc-6').hide();
		}
		else {
			$('#cred-acc-6').show();
		}
	});
	
	$('.cred-acc-6-radio').click(function(){
		if($('#cred-acc-6-yes').is(':checked')) {
			eparcelAccApp = true;
		}
		else {
			eparcelAccApp = false;
		}
	});
	
	$('#continue-btn').click(function(){
		$('#terms-conditions').show();

		if(creditAccApp) {
			$('#credit-acc-app').show();
			$('#terms-conditions-business-credit').show();
			//$('#business-details-app').hide();
		}
		else{
			$('#credit-acc-app').hide();
			$('#terms-conditions-business-credit').hide();
			//$('#business-details-app').hide();
		}
		
		if(eparcelAccApp) {
			$('#eparcel-acc-app').show();
			$('#terms-conditions-eparcel').show();
		}
		else{
			$('#eparcel-acc-app').hide();
			$('#terms-conditions-eparcel').hide();
		}
	});
});