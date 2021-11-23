var QAS_AUTOCOMPLETE = {
		sz_QasDataUrl : 'https://test.haitd.oss-server.com/token.json',
		sz_AddressUrl : 'https://digitalapi-pdev.npe.auspost.com.au/qac/address',
		sz_DetailsUrl : 'https://digitalapi-pdev.npe.auspost.com.au/qac/details',
		sz_star : 'true',
		sz_QasToken : 'ab06a0a6-84a1-478b-ae57-e2a8a33a1e73', // Use UserToken from QAC response
		minLength : 4,
		delay : 500,
		source : function(request, response) {
			me = this;
			$.ajax({
				beforeSend: function(req) {
					req.setRequestHeader("auspost-access-token", QAS_AUTOCOMPLETE.sz_QasToken);
				},
				url : QAS_AUTOCOMPLETE.sz_AddressUrl,
				crossDomain : true,
				dataType : "jsonp",
				data : {
					term : request.term,
					aat : QAS_AUTOCOMPLETE.sz_QasToken
				},
				jsonp : "jsonp",
				success : function(data) {
					console.log(data);
					if(data == null || typeof data == 'undefined'){
						// Token is wrong or expired
						QAS_AUTOCOMPLETE.v_fGetQasData(QAS_AUTOCOMPLETE.source, [request, response], me);
					} else {
						response($.map(data, function(item) {
							if(item.address == '' && item.moniker == '')
							{
								return false;
							}
							console.log('ITEM:'+item);
							return {
								label : item.address,
								value : item.address,
								moniker : item.moniker
							};
						}));
					}
				},
				error: function(){
					// There some problems with connection or parsing data here
				}
			});
		},
		select : function(event, ui) {
			me = this;
			if (ui.item.label == 'Address not found') {
				// The end user has indicated that none of the options are correct - do something 
				return false;
			} else if (ui.item.moniker == '') {
				// There were no items returned by QAS.
				return false;
			}
			$.ajax({
				beforeSend: function(req) {
					req.setRequestHeader("auspost-access-token", QAS_AUTOCOMPLETE.sz_QasToken);
				},
				url : QAS_AUTOCOMPLETE.sz_DetailsUrl,
				crossDomain : true,
				dataType : "jsonp",
				data : {
					'address' : ui.item.value,
					aat : QAS_AUTOCOMPLETE.sz_QasToken
				},
				jsonp : "jsonp",
				success : function(data) {
					console.log(data);
					if(data == null || typeof data == 'undefined'){
						// Token is wrong or expired
						QAS_AUTOCOMPLETE.v_fGetQasData(QAS_AUTOCOMPLETE.select, [event, ui], me);
					} else {
						$('#toAddressLineOne').val(data.addressLine1);
						$('#toAddressLineTwo').val(data.addressLine2);
						$('#toSuburb').val(data.city);
						$('#toState').val(data.state);
						$('#toPostcode').val(data.postcode);
						$('#dpid').val(data.dpid);
					}
				},
				error: function(){
					// There some problems with connection or parsing data here
				}
			});
		},
		v_fGetQasData : function (the_fn_Callback, the_a_Arguments, the_o_This){
			$.ajax({
				url : QAS_AUTOCOMPLETE.sz_QasDataUrl,
				crossDomain : true,
				dataType : "jsonp",
				data : {},
				success : function(data) {
					// Update token and then callback 
					console.log(data);
					QAS_AUTOCOMPLETE.sz_QasToken = data.token;
					if(typeof the_fn_Callback == 'function'){
						the_fn_Callback.apply(the_o_This, the_a_Arguments);
					}
				},
				error: function(){
					// There some problems with connection or parsing data here
				}
			});
		}
};

$(function(){
	$("#qasToAddressLine").autocomplete(QAS_AUTOCOMPLETE);
});

