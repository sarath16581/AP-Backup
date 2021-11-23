({
	doInit: function(component, event, helper) {
      // close the popup 
      var navigate = component.get("v.navigateFlow");
      navigate("FINISH");
   }
})