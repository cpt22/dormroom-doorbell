$(document).ready(function() {
    var csrftoken = Cookies.get('csrftoken'); //getCookie('csrftoken');

    function update_add_request(doorbell_id, lampi_id, vals) {
        data_to_send = {
            csrfmiddlewaretoken: csrftoken,
            doorbell: doorbell_id,
            lampi: lampi_id,
        };

        if (vals['hue'])
            data_to_send.hue = vals['hue']
        if (vals['saturation'])
            data_to_send.saturation = vals['saturation']
        if (vals['brightness'])
            data_to_send.brightness = vals['brightness']
        if (vals['number_flashes'])
            data_to_send.number_flashes = vals['number_flashes']

        $.post("/lampi/links/update/", data_to_send, function(data, status) {
            console.log(status + data);
            var vals = JSON.parse(data);
            if (vals.outcome === "updated") {
                var alert = $('<div class="alert alert-success fade show" role="alert">Successfully Updated!</div>').appendTo("#alert-container");
                createAutoClosingAlert(alert, 2000);
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
});