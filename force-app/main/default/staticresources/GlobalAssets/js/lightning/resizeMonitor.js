window.RESIZE_MONITOR_LOADED = (window.RESIZE_MONITOR_LOADED ? window.RESIZE_MONITOR_LOADED : false);
if (!window.RESIZE_MONITOR_LOADED && window.parent) {
    window.RESIZE_MONITOR_LOADED = true;

    /**
     * targetNode: Select the node that will be observed for mutations
     * messageName: append this to the post message to capture by parent
     * config: Options for the observer (which mutations to observe)
    **/
    var resizeMonitoringObserver = function(targetNode, messageName, config, callback) {

        if(!targetNode) {
            targetNode = document;
        }

        if(!messageName){
            messageName = "resize";
        }

        if(!config){
            config = ({childList:true, subtree:true ,attributes: true });
        }
        if(!callback) {
            callback = function() {
                var height = document.body.scrollHeight ;
                if(height < 600) {
                    height = 600;
                }
                var message = {
                    name: "resize",
                    value: "height:"+height+"px; width:100%;"
                };
                parent.postMessage(message, '*');
                lastHeight = height;
            }
        }

        // Create an observer instance linked to the callback function
        MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
        if(MutationObserver != null) {
            var observer = new MutationObserver(callback);
            // Start observing the target node for configured mutations
            observer.observe(targetNode, config);
        }
    }
    
}
