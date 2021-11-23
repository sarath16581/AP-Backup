({
    doInit: function(component, event, helper) {
        component.set("v.URL", window.location);
    },
    social: function() {

        console.log('social sharing function:');

        var images = document.getElementsByClassName('image')
        console.log(images);

        var metaList = document.getElementsByTagName("meta");
        for (var i = 0; i < metaList.length; i++) {
            if (metaList[i].getAttribute("property") == "og:title") {
                metaList[i].content = document.title;
            }
        }

        for (var i = 0; i < metaList.length; i++) {
            if (metaList[i].getAttribute("property") == "og:image") {
                metaList[i].content = images[0].currentSrc;
            }
        }


        console.log(images[0].currentSrc);
    }


    // social: function(element, event) {
    // 		var metaTarget = document.find(property="og:title");
    // 		this.metaTarget.content = "I'm new content";
    // },
})