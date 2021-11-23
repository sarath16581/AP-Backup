({
    /**
    *   Called when event AsynchApexContinuationRequest is fired. Use this component to call continuation methods in Lightning.
    *   Pass class name , function name and parameters to be dynamically called by Apex "AsynchApexContinuationController"
    *   The class name passed here needs to implement either IAsynchApexContinuationREST or IAsynchApexContinuationSOAP.
    *   This invokes component AsynchApexContinuationProxy. To pass on function Params to VF page
    */
    onContinuationRequest : function(cmp, evt, hlpr) {
        var className = evt.getParam("className");
        var methodName = evt.getParam("methodName");
        var methodParams = evt.getParam("methodParams");
        var useAsynchCallout =  evt.getParam("useAsynchCallout");
        if(useAsynchCallout != false){
                    useAsynchCallout = true;
        }
        if(methodParams != null){
            methodParams = JSON.parse(JSON.stringify(methodParams));
            var callback = evt.getParam("callback");
            cmp.find("proxy").invoke(className,methodName, methodParams,useAsynchCallout, callback);
        }
    }
})