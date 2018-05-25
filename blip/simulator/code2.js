const request = require("request")
request.get({
    url: "https://us-central1-blip-c1e83.cloudfunctions.net/makeDeliveryRequest",
    qs: {
        "storeID": "Use the store ID from previous request",
        "deliveryLat": "43.668184",
        "deliveryLong": "-79.49899",
        "deliveryMainInstruction": "Eg. Deliver order 1234",
        "deliverySubInstruction": "Eg. Deliver to John Smith at front door",
        "originLat": "43.698184",
        "originLong": "-79.48899",
        "pickupMainInstruction": "Eg. Pickup from My business",
        "pickupSubInstruction": "Eg. Come to the back door",
        "recieverName": "John Smith",
        "recieverNumber": "XXX-XXX-XXXX",
        "pickupNumber": "XXX-XXX-XXXX"
    }
}, function(err, response, body) {
    if (!err) {
        // Save the response ID as your delivery request number in your database
    }
})