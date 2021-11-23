({
afterRender: function (component, helper) {
      this.superAfterRender();
      document.getElementById("chasProgress").focus();
  }
})