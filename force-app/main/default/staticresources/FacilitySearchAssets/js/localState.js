var localState = (function() {
	var my = {
	  	vars: {},

		set: function(item, value) {
			my.vars[item] = value;
		},

		get: function(item) {
			return my.vars[item];
		}
 	};

	return my;
});