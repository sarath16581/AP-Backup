/**
 * Used for special calls from Lightning components
 * @param msg
 * @param isWebSocket
 * @param port
 */
window.sendToWDE = function(msg, isWebSocket, port) {
    console.log("sendToWDE");
    msg.CI = 'ignore'; // ignore the connection id for these calls

    if (typeof port === 'undefined') {
        port = 5050;
    }

    // note: websockets don't work with Lightning yet as they can't be added to the CSP list of sites.
    // Hopefully they'll add support soon because this is just plain annoying...
    if (isWebSocket === 'true') {
        var websocket = new WebSocket('wss://localhost:' + port + '/SFDCSocketListener');

        websocket.onopen = function (e) {
            console.log("websocket.onopen");
            websocket.send(JSON.stringify(msg));
            websocket.close();
        };
    }
    else {
        $.ajax({
            url: 'https://localhost:' + port,
            data: "/request=" + JSON.stringify(msg),
            type: 'GET',
            processData: false,
            timeout: 5000,
            cache: false,
            dataType: 'jsonp',
            error: function (xhr, ajaxOptions, thrownError) {
                console.error('https://localhost:' + port + ' ' + ajaxOptions + ' - ' + xhr.status + ' ' + thrownError);
            }
        });
    }
};