$(document).ready(function() {
    var csrftoken = Cookies.get('csrftoken'); //getCookie('csrftoken');

    function update_add_request(doorbell_id, lampi_id, vals, is_add=false) {
        let doorbellSelect = $('#doorbellSelect');
        let lampiSelect = $('#lampiSelect');
        let newHue = $('#newHue');
        let newSaturation = $('#newSaturation');
        let newBrightnesss = $('#newBrightness');
        let newNumberFlashes = $('#newNumberFlashes');

        data_to_send = {
            csrfmiddlewaretoken: csrftoken,
            doorbell: doorbell_id,
            lampi: lampi_id,
            is_add: is_add,
        };

        if (vals['hue'])
            data_to_send.hue = vals['hue']
        if (vals['saturation'])
            data_to_send.saturation = vals['saturation']
        if (vals['brightness'])
            data_to_send.brightness = vals['brightness']
        if (vals['number_flashes'])
            data_to_send.number_flashes = vals['number_flashes']
        console.log(data_to_send);
        $.post("/lampi/links/update/", data_to_send, function(data, status) {
            var vals = JSON.parse(data);
            console.log(data);
            if (vals.outcome === "updated") {
                var alert = $('<div class="alert alert-success fade show" role="alert">Successfully Updated!</div>').appendTo("#alert-container");
                createAutoClosingAlert(alert, 2000);
            } else if (vals.outcome === "created") {
                var alert = $('<div class="alert alert-success fade show" role="alert">Successfully Added!</div>').appendTo("#alert-container");
                createAutoClosingAlert(alert, 2000);
            } else if (vals.outcome === "failed") {
                if (is_add) {
                    var alert = $('<div class="alert alert-danger fade show" role="alert">' + vals.message + '</div>').appendTo("#alert-container");
                    createAutoClosingAlert(alert, 2000);
                } else {
                    var alert = $('<div class="alert alert-danger fade show" role="alert">Failed to update link!</div>').appendTo("#alert-container");
                    createAutoClosingAlert(alert, 2000);
                }
            }
        });
    }

    function createAutoClosingAlert(selector, delay) {
        var alert = selector.alert();
        window.setTimeout(function() { alert.alert('close');}, delay);
        /*window.setTimeout(function()
                {selector.hide(500, function() {
                    selector.remove();
                })}, delay);*/
    }

    $(".input-listen-changes").on('change', function() {
        console.log("detected change")
        let row = $(this).closest(".editable-table-row");
        let doorbell = row.data('doorbell-uid');
        let lampi = row.data('lampi-uid');
        let name = $(this).attr('name');
        var vals = {};
        vals[name] = $(this).val();
        update_add_request(doorbell, lampi, vals);
        console.log(vals);
    });

    $("#saveNewLink").click(function() {
       let doorbellSelect = $('#doorbellSelect :selected').val();
       let lampiSelect = $('#lampiSelect :selected').val();
       let newHue = $('#newHue').val();
       let newSaturation = $('#newSaturation').val();
       let newBrightnesss = $('#newBrightness').val();
       let newNumberFlashes = $('#newNumberFlashes').val();

       var vals = {};
       if (doorbellSelect != "" && lampiSelect != "") {
           if (newHue != "") {
               vals['hue'] = newHue;
           }
           if (newSaturation != "") {
               vals['saturation'] = newSaturation;
           }
           if (newBrightness != "") {
               vals['brightness'] = newBrightnesss;
           }
           if (newNumberFlashes != "") {
               vals['number_flashes'] = newNumberFlashes;
           }
           update_add_request(doorbellSelect, lampiSelect, vals, true);
       }
    });
});