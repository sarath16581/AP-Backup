/**
  * @author       : RSolomon
  * @date         : 08/05/2019
  * @description  : Form wrapper to handle Asynch callouts
--------------------------------------- History --------------------------------------------------
08.05.2019    Rufus Solomon    Created
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