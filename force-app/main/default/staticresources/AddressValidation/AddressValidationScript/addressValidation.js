var $jq = jQuery.noConflict();
var opts = {
  lines: 7, // The number of lines to draw
  length: 1, // The length of each line
  width: 4, // The line thickness
  radius: 7, // The radius of the inner circle
  corners: 0.7, // Corner roundness (0..1)
  rotate: 13, // The rotation offset
  direction: 1, // 1: clockwise, -1: counterclockwise
  color: '#000', // #rgb or #rrggbb or array of colors
  speed: 1, // Rounds per second
  trail: 54, // Afterglow percentage
  shadow: false, // Whether to render a shadow
  hwaccel: false, // Whether to use hardware acceleration
  className: 'spinner', // The CSS class to assign to the spinner
  zIndex: 2e9, // The z-index (defaults to 2000000000)
  top: 'auto', // Top position relative to parent in px
  left: 'auto' // Left position relative to parent in px
};
var QAS_AUTOCOMPLETE = {
        sz_QasDataUrl : 'https://test.haitd.oss-server.com/token.json',
        sz_AddressUrl : 'https://digitalapi-pdev.npe.auspost.com.au/qac/address',
        sz_DetailsUrl : 'https://digitalapi-pdev.npe.auspost.com.au/qac/details',
        sz_star : 'true', // This value should receive from STS service
        minLength : 4,
        delay : 200,
        focus : function(event,ui) {
            return false;
        },
        source : function(request, response) {
            var myId = this.element;
            console.log(myId);
            var target = $jq(myId).next()[0];
            console.log(target);
            var spinner = new Spinner(opts).spin(target);
            var token = sforce.apex.execute("Utility","getToken",{});
            console.log(token);
            $jq.ajax({
                beforeSend: function(req) {
                    req.setRequestHeader("auspost-access-token", token);
                },
                url : QAS_AUTOCOMPLETE.sz_AddressUrl,
                traditional: true,
                crossDomain : true,
                dataType : "jsonp",
                data : {
                    term : request.term,
                    aat : token
                },
                jsonp : "jsonp",
                success : function(data) {
                	spinner.stop();
                    if(data == null || typeof data == 'undefined'){
                        // Token is wrong or expired
                        QAS_AUTOCOMPLETE.v_fGetQasData(QAS_AUTOCOMPLETE.source, [request, response], me);
                    } else {
                        response($jq.map(data, function(item) {
                            if(item.address == '' && item.moniker == '')
                            {
                                return false;
                            }
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
            var token = sforce.apex.execute("Utility","getToken",{});
            console.log(token);
            if (ui.item.label == 'Address not found') {
                // The end user has indicated that none of the options are correct - do something 
                return false;
            } else if (ui.item.moniker == '') {
                // There were no items returned by QAS.
                return false;
            }
            $jq.ajax({
                beforeSend: function(req) {
                    req.setRequestHeader("auspost-access-token", token);
                },
                url : QAS_AUTOCOMPLETE.sz_DetailsUrl,
                traditional: true,
                crossDomain : true,
                dataType : "jsonp",
                data : {
                    'address' : ui.item.value,
                    aat : token
                },
                jsonp : "jsonp",
                success : function(data) {
                    if(data == null || typeof data == 'undefined'){
                        // Token is wrong or expired
                        QAS_AUTOCOMPLETE.v_fGetQasData(QAS_AUTOCOMPLETE.select, [event, ui], me);
                    } else {
                        if(data.addressLine2 != null && data.addressLine2 != '') {
                            $jq("[id$='toAddressLineOne']").val(data.addressLine1+', '+data.addressLine2);
                        } else {
                            $jq("[id$='toAddressLineOne']").val(data.addressLine1);
                        }
                       // $jq("[id$='toAddressLineTwo']").val(data.addressLine2);
                        $jq("[id$='toSuburb']").val(data.city);
                        $jq("[id$='toState']").val(data.state);
                        $jq("[id$='toPostcode']").val(data.postcode);
                        $jq("[id$='dPid']").val(data.dpid);
                    }
                },
                error: function(){
                    // There some problems with connection or parsing data here
                }
            });
        },
        v_fGetQasData : function (the_fn_Callback, the_a_Arguments, the_o_This){
            $jq.ajax({
                url : QAS_AUTOCOMPLETE.sz_QasDataUrl,
                crossDomain : true,
                dataType : "jsonp",
                data : {},
                success : function(data) {
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

sforce.connection.sessionId = "{!$Api.Session_ID}";
$jq(function(){
    $jq(".addressValidation").autocomplete(QAS_AUTOCOMPLETE);
});
