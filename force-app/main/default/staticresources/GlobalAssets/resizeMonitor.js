window.RESIZE_MONITOR_LOADED = (window.RESIZE_MONITOR_LOADED ? window.RESIZE_MONITOR_LOADED : false);
if (!window.RESIZE_MONITOR_LOADED && window.parent) {
    window.RESIZE_MONITOR_LOADED = true;

    (function() {
        var lastHeight = 0;
        function resizeHandler(e) {
            if (window.parent) {
                var height = Math.max((document.documentElement != null ? document.documentElement.scrollHeight : 0), (document.body != null ? document.body.scrollHeight : 0));
                if(height != lastHeight) {
                    console.log('>> POSTED RESIZE OUT 1 = ', height);
                    window.parent.postMessage({
                        name: 'resize',
                        value: height
                    }, '*');
                    lastHeight = height;
                }
            }
        }

        //window.addEventListener("load", resizeHandler);
        window.addEventListener("resize", resizeHandler);

        //MutationObserver = window.MutationObserver;
        //if(MutationObserver != null) {

        var observer = new MutationObserver(function(mutations) {
            resizeHandler();
        });
        
        observer.observe(document, {
            subtree: true,
            attributes: true
        });
        //}

    })();
}