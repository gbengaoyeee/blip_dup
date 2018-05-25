// First make an HTTPS request to create a store object
const request = require("request")
request.get({
    url: "https://us-central1-blip-c1e83.cloudfunctions.net/createTestStore",
    qs: {
        "storeName": "Test Store",
        "storeLogo": "Your store logo URL",
        "storeBackground": "Your store background URL",
        "locationLat": "43.698184",
        "locationLong": "-79.48899",
        "city": "Your city",
        "country": "CA",
        "line1": "Your line 1 address",
        "postalCode": "L5L 6A2",
        "province": "ON",
        "businessName": "Test Business",
        "businessTaxId": "000000000",
        "firstName": "Your name",
        "lastName": "Your last name",
        "email": "Your email"
    }
}, function(err, response, body) {
    if (!err) {
        // Save the response ID in your database
    }
})