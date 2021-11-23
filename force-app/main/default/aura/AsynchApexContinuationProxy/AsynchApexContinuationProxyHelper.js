({
    /**
    *   Create a unique ID that is passed to the VF message event and then used to retrieve it back
    */
    getUniqueId : function() {
    		return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        		var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        		return v.toString(16);
      		});
    	}
})