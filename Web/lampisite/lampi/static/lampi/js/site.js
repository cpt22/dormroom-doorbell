$(document).ready(function() {
    $("#edit-doorbell-name-form").hide();

   /*$(".clickable-row").click(function() {
       consle.log($(this));
       var url = $(this).data("data-href");
       console.log(url);
      window.location = url;
   });
    */

    $("#edit-doorbell-name-button").click(function() {
        $("#doorbell-name").hide();
        $("#edit-doorbell-name-form").show();
    });

    $("#cancel-edit-doorbell-name").click(function() {
        console.log("hi");
        $("#doorbell-name").show();
        $("#edit-doorbell-name-form").hide();
    });
});

