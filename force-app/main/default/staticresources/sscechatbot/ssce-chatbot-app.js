(function (d, s, id) {
  var sfData = document.getElementById("ssce-chatbot-data");
  var endpoint = sfData.getAttribute("data-endpoint");
  var js,
    fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) {
    return;
  }
  js = d.createElement(s);
  js.id = id;
  js.src = endpoint + "/js/app.js";
  fjs.parentNode.insertBefore(js, fjs);
})(document, "script", "ssce-chatbot-script");
