$(document).ready(function(){

  $("ul.left-tabbed-selector li").click(function(e) {
    $("ul.left-tabbed-selector li").removeClass("selected");
    $(e.currentTarget).closest("li").addClass("selected");
  });

  MRSO = {

    initialize: function() {
      $("input[name=moveType]").on("click", this.handleMoveType);
      $(".fn_tooltip").mouseover(this.handleTooltipOver);
      $(".fn_tooltip").mouseout(this.handleTooltipOut);
      $(".input.dates input").datepicker();
      $("a.fn_another_person").on("click", this.handleNewPerson);
    },

    
    handleMoveType: function(e) {
      console.log("clicked")
      var selection = $(e.currentTarget);
      var finishDate = $("#inputFinishDate");
      if (selection.val() == "MOVE_TEMP") {
        finishDate.fadeIn(250);
      } else {
        finishDate.fadeOut(250);
      }
    },

    handleTooltipOver: function(e) {
      var tip = $(e.currentTarget);
      tip.children(".tooltip").fadeIn();
    },

    handleTooltipOut: function(e) {
      var tip = $(e.currentTarget);
      tip.children(".tooltip").fadeOut();
    },

    handleNewPerson: function(e) {
      e.preventDefault();
      var row = $("#newPerson").html();
      $(".moving-people").append($(row).fadeIn().attr("style", ""));
    }

  }

  MRSO.initialize();

});

