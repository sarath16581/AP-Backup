/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/05/2019
  * @description  : Example Form Wrapper Component
--------------------------------------- History --------------------------------------------------
05.04.2019    Sameed Khan(Mav3rik)    Created
**/
({
    onContinuationRequest: function (cmp, evt, hlpr) {
        const className = evt.getParam("className");
        const methodName = evt.getParam("methodName");
        const methodParams = evt.getParam("methodParams");
        const useAsynchCallout = evt.getParam("useAsynchCallout");

        if (methodParams != null) {
            const params = JSON.parse(JSON.stringify(methodParams));
            const callback = evt.getParam("callback");
            cmp.find("proxy").invoke(className, methodName, params, !!useAsynchCallout, callback);
        }
    }
})