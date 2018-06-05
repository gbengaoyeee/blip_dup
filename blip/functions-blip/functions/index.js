'use strict';

const functions = require('firebase-functions'),
    admin = require('firebase-admin'),
    logging = require('@google-cloud/logging'),
    request = require('request');
var crypto = require('crypto');
admin.initializeApp(functions.config().firebase);
var express = require('express');
var bodyParser = require('body-parser');
var walmart = require('walmart')("qeq7xghhtkb8ate7x59px7yk");
const app = express();
const geo = require('geolib');
const stripe = require('stripe')("sk_test_4I0ubK7NduuV6dhJouhEAqtu"),
    currency = "CAD";
const cors = require('cors')({ origin: true });
const Nexmo = require('nexmo');
const nexmo = new Nexmo({
    apiKey: '95edf8df',
    apiSecret: 'x1JhAApGI5OXgVAZ'
},{debug: true});

exports.sendSms = functions.https.onRequest((req, res) => {
    const phoneNumber = req.body.phoneNumber
    const message = req.body.message

    nexmo.message.sendSms(
        '12046615913', phoneNumber, message, {type: 'unicode'},
        (error, responseData) => {
            if(error){
                console.log('Error sending sms',error);
            } else{
                console.dir(responseData);
                res.status(200).send();
            }
        }
    )
});

exports.ephemeral_keys = functions.https.onRequest((req, res) => {
    const stripe_version = req.body.api_version;
    console.log(req);
    console.log(stripe_version);
    console.log(req.body.customerID);
    if (!stripe_version) {
        res.status(400).end();
        console.log("error with stripe version")
        return;
    }
    // This function assumes that some previous middleware has determined the
    // correct customerId for the session and saved it on the request object.
    stripe.ephemeralKeys.create({
        customer: req.body.customerID
    }, {
            stripe_version: stripe_version
        }).then((key) => {
            res.status(200).json(key);
        }).catch((err) => {
            res.status(500).end();
        });
});

exports.charges = functions.https.onRequest((req, res) => {
    var customer = req.body.customerID,
        amount = req.body.amount,
        currency = req.body.currency,
        Email = req.body.email_hash;
    const emailHash = crypto.createHash('md5').update(Email).digest('hex');
    console.log(amount);
    stripe.charges.create({
        customer: customer,
        amount: amount,
        currency: currency,
        capture: false
    }, function (err, charge) {
        if (err) {
            console.log(err, req.body)
            res.status(500).end()
        } else {
            res.status(200).send(charge.id)
        }
    })
});

exports.captureCharge = functions.https.onRequest((req, res) => {
    var chargeID = req.body.chargeID;
    var accountID = req.body.accountID;
    console.log(chargeID);
    stripe.charges.capture(chargeID, function (err, charge) {
        console.log(charge);
        if (err) {
            console.log(err.req.body)
            res.status(500).end()
        } else {
            res.status(200).send(charge.id)
        }
    })
});

exports.getAccountBalance = functions.https.onRequest((req, res) => {
    var emailHash = req.body.emailHash;
    admin.database().ref(`Couriers/${emailHash}/stripeAccount/keys/secret`).once("value", function (snapshot) {
        if (snapshot.exists) {
            var stripeAccount = require('stripe')(snapshot.val())
            stripeAccount.balance.retrieve(function (err, balance) {
                if (err) {
                    console.log(err);
                    res.status(400).end();
                } else {
                    const availBalance = balance.available[0];
                    const pendingBalance = balance.pending[0];
                    console.log(availBalance.amount + pendingBalance.amount);
                    const totalBalance = availBalance.amount + pendingBalance.amount;
                    res.status(200).send('' + totalBalance);
                }
            })
        }
    })
})

exports.getDeliveryPrice = functions.https.onRequest((req, res) => {
    var deliveryLat = req.body.deliveryLat;
    var deliveryLong = req.body.deliveryLong;
    var pickupLat = req.body.pickupLat;
    var pickupLong = req.body.pickupLong;
    const price = getChargeAmount(deliveryLat, deliveryLong, pickupLat, pickupLong);
    if (price !== undefined || price != null) {
        console.log("Cost of delivery is;", price);
        res.status(200).send(price);
    } else {
        console.log("A field is empty");
        res.status(400).end();
    }
})

exports.createTestStore = functions.https.onRequest((req, res) => {
    var storeName = "Test Store";
    var storeLogo = "https://www.google.com/url?sa=i&source=images&cd=&cad=rja&uact=8&ved=2ahUKEwiRgdr1iJzbAhUI0IMKHQeaAHwQjRx6BAgBEAU&url=http%3A%2F%2Fwww.brandsoftheworld.com%2Flogo%2Fwalmart&psig=AOvVaw3C4LLfJirtNg2SpKD8VK8Z&ust=1527172998529215";
    var storeBackground = "https://www.google.com/url?sa=i&source=images&cd=&cad=rja&uact=8&ved=2ahUKEwiRgdr1iJzbAhUI0IMKHQeaAHwQjRx6BAgBEAU&url=http%3A%2F%2Fwww.brandsoftheworld.com%2Flogo%2Fwalmart&psig=AOvVaw3C4LLfJirtNg2SpKD8VK8Z&ust=1527172998529215";
    var locationLat = "43.64";
    var locationLong = "-79.19";
    var description = "Your store description";
    var address_city = "Toronto";
    var address_country = "CA";
    var address_line1 = "Line 1";
    var address_zip = "A0A 0A0";
    var address_state = "ON";
    var business_name = "Test business";
    var business_tax_id = "000000000";
    var first_name = "Your name";
    var last_name = "Your last name";
    var date = Math.floor(new Date() / 1000);
    var email = "test@grr.la";

    stripe.customers.create({
        "business_vat_id": business_tax_id,
        "description": business_name,
        "email": email,
        "metadata": {
            rep_first_name: first_name,
            rep_last_name: last_name,
            signup_date: date
        },
        "source": "tok_ca"
    }, function (err, customer) {
        if (err) {
            console.log(err);
            res.status(400).end(); // COULD NOT CREATE CUSTOMER ERROR
        } else {
            var storeDetails = {
                storeName,
                storeLogo,
                description,
                storeBackground,
                locationLat,
                locationLong
            };
            storeDetails.customer = customer;
            var storeID = admin.database().ref().child('stores').push().key;
            admin.database().ref('stores/' + storeID).update(storeDetails).then(() => {
                console.log('Created store successfully')
                cors(req, res, () => {
                    res.status(200).send(storeID);
                })
            });
        }
    });
});

exports.updateStorePayment = functions.https.onRequest((req, res) => {
    var storeID = req.body.storeID;
    var sourceID = req.body.sourceID;
    return admin.database().ref(`/stores/${storeID}/customer/id`).once('value').then(function (snapshot) {
        if (snapshot.exists) {
            stripe.customers.update(snapshot.val(), {
                source: sourceID
            }, function (err, customer) {
                if (err) {
                    console.log("STRIPE ERROR", err);
                    res.status(400).send(err);
                } else {
                    admin.database().ref(`/stores/${storeID}/customer`).update(customer).then(() => {
                        console.log("COMPLETE", customer);
                        res.status(200).send(customer);
                    });
                }
            });
        } else {// No such customer
            console.log("CustomerID does not exist or store does not exist");
            res.status(404).end();
        }
    }, function (error) {
        console.log("OBSERVER ERROR", error);
    });
})

///Validate the email provided
function validateEmail(email) {
    return /[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}/.test(email);
}
///Validates the password provided
function validatePassword(password) {
    return /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*()\-+=_[\]|;:'"\/.,<>`~]).{6,}$/.test(password);
}
///Checks if both passwords provided match
function checkPasswordMatch(password1, password2) {
    return password1 === password2;
}
///Checks if firstName, lastName and photoURL is not empty(photoURL not necessary but why not)
///Returns false if empty else true
function checkFirstLastPhotoAndPhone(firstName, lastName, photoURL, phoneNumber){
    return (firstName != "" && lastName != "" && photoURL != "" && phoneNumber != "");
}
///Adds the successfully created user to the database
function addCourierToDatabase(uid, firstName, lastName, email, emailHash, photoURL, phoneNumber) {
    const dict = {
        "uid": uid, "firstName": firstName, "lastName": lastName, "photoURL": photoURL,
        "email": email, "rating": 5.0, "currentDevice": "", "verified": false, "phoneNumber":phoneNumber
    };
    return new Promise(function (resolve, reject) {
        admin.database().ref('Couriers/' + emailHash).update(dict).then(() => {
            console.log("Added to the database successfully");
            resolve()
        }, function (error) {
            console.log("Couldn't add the user to the database for some reason");
            reject(error);
        });
    });
}
exports.createCourier = functions.https.onRequest((req, res) => {
    const firstName = req.body.firstName;
    const lastName = req.body.lastName;
    const email = req.body.email;
    const password = req.body.password;
    const confirmPassword = req.body.confirmPassword;
    const phoneNumber = req.body.phoneNumber;
    const photoURL = req.body.photoURL;
    //hash the email
    const emailHash = crypto.createHash('md5').update(email).digest('hex');
    return admin.auth().createUser({//can also add photourl later on
        email: email,
        emailVerified: false,
        password: password,
        displayName: "" + firstName + " " + lastName,
        photoURL: photoURL,
        disabled: false
    }).then(function (user) {
        console.log("Created user succesfully with uid:", user.uid);
        console.log("photo", user.photoURL);
        addCourierToDatabase(user.uid, firstName, lastName, email, emailHash, photoURL, phoneNumber).then(function (resolve) {
            createCourierStripeAccount(email, emailHash, firstName, lastName).then(function(account){
                console.log(account);
                res.status(200).end();
            }, function(error){
                console.log("Error creating stripe after adding user to db",error);
                res.status(402).end();
            });
        }, function (error) {
            console.log('Error Adding user to db');
            res.status(401).send(error);//406
        });
    }, function (error) {
        console.log("Error creating user:", error);
        res.status(400).send(error);//405
    });
});


exports.createStore = functions.https.onRequest((req, res) => {
    var storeName = req.body.storeName;
    var storeLogo = req.body.storeLogo;
    var storeBackground = req.body.storeBackground;
    var locationLat = req.body.locationLat;
    var locationLong = req.body.locationLong;
    var address_city = req.body.city;
    var address_country = req.body.country;
    var address_line1 = req.body.line1;
    var address_zip = req.body.postalCode;
    var address_state = req.body.province;
    var business_name = req.body.businessName;
    var business_tax_id = req.body.businessTaxId;
    var first_name = req.body.firstName;
    var last_name = req.body.lastName;
    var date = Math.floor(new Date() / 1000);
    var email = req.body.email;
    var date = Math.floor(new Date() / 1000);

    stripe.customers.create({
        "business_vat_id": business_tax_id,
        "description": business_name,
        "email": email,
        "metadata": {
            rep_first_name: first_name,
            rep_last_name: last_name,
            signup_date: date,
            address_city: address_city,
            address_country: address_country,
            address_line1: address_line1,
            address_zip: address_zip,
            address_state: address_state
        }
    }, function (err, customer) {
        if (err) {
            console.log(err);
            res.status(400).end(); // COULD NOT CREATE CUSTOMER ERROR
        } else {
            var storeDetails = {
                storeName,
                storeLogo,
                storeBackground,
                locationLat,
                locationLong
            };
            storeDetails.creationDate = date;
            storeDetails.customer = customer;
            var storeID = admin.database().ref().child('stores').push().key;
            admin.database().ref('stores/' + storeID).update(storeDetails).then(() => {
                console.log('Created store successfully')
                res.status(200).send(storeID); // OK
            });
        }
    });
});

exports.updateStripeAccount = functions.https.onRequest((req, res) => {
    console.log("Update account started", req.body);
    const routing_number = req.body.routing_number;
    const emailHash = req.body.emailHash;
    const account_number = req.body.account_number;
    const city = req.body.city;
    const line1 = req.body.line1;
    const postal_code = req.body.postal_code;
    const state = req.body.state;
    const dob_day = req.body.dob_day;
    const dob_month = req.body.dob_month;
    const dob_year = req.body.dob_year;
    const first_name = req.body.first_name;
    const last_name = req.body.last_name;
    const sin = req.body.sin;
    const tos_time = req.body.tos_time;
    const accountID = req.body.account_ID;

    stripe.accounts.update(accountID, {
        "external_account": {
            "object": "bank_account",
            "country": "CA",
            "currency": "cad",
            "routing_number": routing_number,
            "account_number": account_number
        },
        "legal_entity": {
            "address": {
                "city": city,
                "country": "CA",
                "line1": line1,
                "postal_code": postal_code,
                "state": state
            },
            "dob":{
                "day": dob_day,
                "month": dob_month,
                "year": dob_year
            },
            "personal_id_number": sin,
            "type": "individual",
        },
        "tos_acceptance": {
            "date": tos_time,
            "ip": "99.250.237.232"
        }
    }, function (err, account) {
        if (err) {
            console.log(err);
            res.status(400).send(err);
        } else {
            console.log(account);
            admin.database().ref(`/Couriers/${emailHash}/stripeAccount`).update(account);
            res.status(200).end();
        }
    });
})
function createCourierStripeAccount(email, emailHash, firstName, lastName) {
    return new Promise(function (resolve, reject) {
        stripe.accounts.create({
            country: "CA",
            default_currency: "cad",
            type: "custom",
            email: email,
            legal_entity: {
                type: "individual",
                first_name: firstName,
                last_name: lastName
            },
            payout_schedule: {
                interval: "weekly",
                weekly_anchor: "wednesday"
            }
        }, function (err, account) {
            if (err) {
                reject(err);
            } else {
                admin.database().ref(`/Couriers/${emailHash}/stripeAccount`).set(account).then(function (fulfilled) {
                    resolve(account);
                }, function (error) {
                    console.log('Error setting stripeAccount for the first time');
                    reject(error);
                });
            }
        });
    });
}
exports.createNewStripeAccount = functions.https.onRequest((req, res) => {
    const email = req.body.email;
    const emailHash = crypto.createHash('md5').update(email).digest('hex');
    const firstName = req.body.firstName;
    const lastName = req.body.lastName;
    createCourierStripeAccount(email, emailHash, firstName, lastName).then(function(account){
        console.log(account);
        res.status(200).end();
    }, function(error){
        console.log(error);
        res.status(400).end();
    });
});

function checkUserVerifiedOrFlagged(emailHash, callback) {
    return admin.database().ref('Couriers/' + emailHash).once('value').then(function (snapshot) {
        var userValues = snapshot.val();
        if (userValues != null) {
            const flagged = userValues.flagged;
            const verified = userValues.verified;
            if (verified == false) {
                var notVerifiedError = new Error("User needs to verify their background check");
                callback(notVerifiedError, null);
                return;
            } else if (flagged != null) {
                var flaggedError = new Error("User account has been flagged due to leaving a job");
                callback(flaggedError, null);
                return;
            } else {
                callback(null, true);
                return;
            }
        }
    }, function (error) {
        console.log(error);
    });
}

function getChargeAmount(deliveryLat, deliveryLong, pickupLat, pickupLong) {
    const distanceBtw = geo.getDistance({
        latitude: deliveryLat,
        longitude: deliveryLong
    }, {
            latitude: pickupLat,
            longitude: pickupLong
        });
    const price = Math.floor((distanceBtw / 1000) + 4.50); // 4.50 for successfull delivery.
    return price * 100;
}

exports.getDeliveryStatus = functions.https.onRequest((req, res) => {
    const deliveryID = req.body.deliveryID;
    const storeID = req.body.storeID;
    admin.database().ref(`/AllJobs/${deliveryID}`).once("value", function (snapshot) {
        if (snapshot.exists) {
            console.log("Found delivery in AllJobs");
            res.status(206).end(); // NOT TAKEN
        }
        else {
            admin.database().ref(`/TakenJobs/${deliveryID}`).once("value", function (secondSnapshot) {
                if (secondSnapshot.exists) {
                    console.log("Found delivery in TakenJobs");
                    res.status(200).send(secondSnapshot); // OK
                }
                else {
                    console.log("Unknown deliveryID");
                    res.status(400).end();
                }
            })
        }
    })
})

exports.makeDeliveryRequest = functions.https.onRequest((req, res) => {
    //storeName, deliveryLat, deliveryLong, deliveryMainInstruction, deliverySubInstruction, originLat, originLong, pickupMainInstruction, pickupSubInstruction, recieverName, recieverNumber, pickupNumber  
    var storeID = req.body.storeID;
    admin.database().ref(`/stores/${storeID}`).once("value", function (snapshot) {
        if (snapshot.exists) {
            console.log(storeID);
            var deliveryLat = req.body.deliveryLat,
                deliveryLong = req.body.deliveryLong,
                deliveryMainInstruction = req.body.deliveryMainInstruction,
                deliverySubInstruction = req.body.deliverySubInstruction,
                originLat = req.body.originLat,
                originLong = req.body.originLong,
                pickupMainInstruction = req.body.pickupMainInstruction,
                pickupSubInstruction = req.body.pickupSubInstruction,
                recieverName = req.body.recieverName,
                recieverNumber = req.body.recieverNumber,
                pickupNumber = req.body.pickupNumber,
                newPostKey = admin.database().ref().child('AllJobs').push().key,
                chargeAmount = getChargeAmount(deliveryLat, deliveryLong, originLat, originLong);

            if (snapshot.child(`/customer`).val() == null) {
                console.log("Cannot create a delivery. No customer returned by stripe");
                res.status(400).end(); // NO CUSTOMER ERROR
                return
            }
            stripe.charges.create({
                amount: chargeAmount + 100,
                currency: "cad",
                description: "Delivery; " + newPostKey + " By store; " + storeID,
                customer: snapshot.child(`/customer/id`).val()
            }, function (err, charge) {
                if (err) {
                    console.log(err);
                    res.status(450).end // CANNOT CHARGE ERROR
                } else {
                    var deliveryDetails = {
                        storeID,
                        deliveryLat,
                        deliveryLong,
                        deliveryMainInstruction,
                        deliverySubInstruction,
                        originLat,
                        originLong,
                        pickupMainInstruction,
                        pickupSubInstruction,
                        recieverName,
                        recieverNumber,
                        pickupNumber,
                        chargeAmount
                    };
                    deliveryDetails.isTaken = false;
                    deliveryDetails.isCompleted = false;
                    deliveryDetails.chargeID = charge;
                    console.log("Charge succeeded", deliveryDetails);
                    admin.database().ref('stores/' + storeID + '/deliveries/' + newPostKey).update(deliveryDetails).then(() => {
                        console.log('Update succeeded: stores')
                    });
                    admin.database().ref('AllJobs/' + newPostKey).update(deliveryDetails).then(() => {
                        console.log('Update succeeded: alljobs');
                        cors(req, res, () => {
                            res.status(200).send(newPostKey);
                        }) // OK
                    });
                }
            });
        } else {
            console.log("No such storeID");
            res.status(500).end(); // INCORRECT STOREID ERROR
        }
    })
});

exports.payOnDelivery = functions.database.ref('/CompletedJobs/{id}').onCreate((snapshot, context) => {
    console.log(snapshot.val());
    const chargeID = snapshot.child("chargeID/id").val();
    const amount = +(snapshot.child("chargeID/amount").val());
    const amountAfterCut = (amount - 100) * 0.75;
    const emailHash = snapshot.child("jobTaker").val();
    if (chargeID == null || amount == null || emailHash == null) {
        console.log("Could not parse data");
        return false
    }
    console.log("Checking userRef", emailHash, amountAfterCut, chargeID);
    return admin.database().ref(`Couriers/${emailHash}`).once("value").then(function(userSnapshot) {
        var accountID = userSnapshot.child("stripeAccount/id").val();
        stripe.transfers.create({
            amount: amountAfterCut,
            currency: "cad",
            source_transaction: chargeID,
            destination: accountID
        }, function(err, transfer) {
            if (err){
                console.log(err);
            }else{
                console.log("Transfer made", transfer);
            }
        })
    })
})

exports.getPaidForDelivery = functions.https.onRequest((req, res) => {
    var deliveryID = req.body.deliveryID;
    var amount = req.body.amount;
    var emailHash = req.body.emailHash;
    var chargeID = req.body.chargeID;
    admin.database().ref(`/Couriers/${emailHash}/stripeAccount/id`).once("value", function (snapshot) {
        var accountID = snapshot.val();
        console.log("ACCOUNTID:", accountID);
        if (accountID == null) {
            console.log("Could not retrieve account ID");
            res.status(450).end(); // COULD NOT RETRIVE ACCOUNT ID ERROR
            return
        }
        stripe.transfers.create({
            amount: (amount - 100) * 0.75,
            currency: "cad",
            source_transaction: chargeID,
            destination: accountID
        }, function (err, transfer) {
            if (err) {
                console.log(err);
                res.status(420).end(); // COULD NOT TRANSFER ERROR
            } else {
                console.log(transfer);
                res.status(200).send(transfer); // OK
            }
        });
    });
})

exports.getBestJob = functions.https.onRequest((req, res) => {
    var long = req.body.locationLong,
        lat = req.body.locationLat,
        emailHash = req.body.emailHash;
    var minDist = 20000,
        currentDist = 0,
        jobKey;

    checkUserVerifiedOrFlagged(emailHash, function(error, checked) {
        if (error) {
            console.log(error.message, req.body);
            if (error.message === "User needs to verify their background check") {
                res.status(400).send("need to verify");
                return
            } else {
                res.status(500).send("need to unflag");
                return
            }

        } else {
            getClosestJobIdAndDistance(lat, long, function(err, data) {
                if (err) {
                    console.log("Found an Error");
                    res.status(404).send(err);
                    return
                } else {
                    var maxDist = 12000;
                    const closestJobIdDict = data[0]; //This is a dictionary
                    const closestJobId = Object.keys(closestJobIdDict)[0];
                    console.log("Initial MaxDist is: " + maxDist);
                    console.log("Dict: " + closestJobIdDict + " ID: " + closestJobId);
                    const totalDistance = data[1];
                    var jobBundle = closestJobIdDict;
                    maxDist = maxDist - totalDistance;

                    var allJobsref = admin.database().ref('AllJobs');
                    allJobsref.once('value', function(snapshot) {
                        var allJobsValues = snapshot.val();
                        if (allJobsValues != null) {
                            for (const jobId in allJobsValues) {//looping thru all the jobs in the Alljobs reference
                                //check to see if the number of jobs found is greater than 6
                                if (Object.keys(jobBundle).length === 6){
                                    break;// Break out of the loop if there are 6 jobs already found
                                }
                                if (jobId != closestJobId) { //So skip if it sees the same job as the closest it already found
                                    const pickupLat = allJobsValues[jobId].originLat;
                                    const pickupLong = allJobsValues[jobId].originLong;
                                    const deliveryLat = allJobsValues[jobId].deliveryLat;
                                    const deliveryLong = allJobsValues[jobId].deliveryLong;
                                    var x = geo.getDistance({
                                        latitude: pickupLat,
                                        longitude: pickupLong
                                    }, {
                                        latitude: lat,
                                        longitude: long
                                    });
                                    var y = geo.getDistance({
                                        latitude: pickupLat,
                                        longitude: pickupLong
                                    }, {
                                        latitude: closestJobIdDict[closestJobId].originLat,
                                        longitude: closestJobIdDict[closestJobId].originLong
                                    });
                                    var m = geo.getDistance({
                                        latitude: pickupLat,
                                        longitude: pickupLong
                                    }, {
                                        latitude: deliveryLat,
                                        longitude: deliveryLong
                                    });
                                    var n = Math.min(...[x, y]);

                                    if (maxDist >= (m + n)) {
                                        var jobDict = {};
                                        // jobDict[jobId] = allJobsValues[jobId];
                                        jobBundle[jobId] = allJobsValues[jobId];
                                        maxDist = maxDist - (m + n);
                                        admin.database().ref('AllJobs/' + jobId).remove().then(() => {
                                            console.log("Removed job from AllJobs reference successfully");
                                        }, () => {
                                            console.log("Cannot remove job from AllJobs reference")
                                        });
                                        console.log("MaxDist is: " + maxDist);
                                    }
                                } else {
                                    admin.database().ref('AllJobs/' + jobId).remove().then(() => {
                                        console.log("Removed job from AllJobs reference successfully");
                                    }, () => {
                                        console.log("Cannot remove job from AllJobs reference")
                                    });
                                }
                            } //End of For loop

                            admin.database().ref('Couriers/' + emailHash + '/givenJob').update(jobBundle).then(() => {
                                console.log('Update succeeded!');
                                res.status(200).send("OK It Gave Back Jobs");
                            });
                        } else {
                            //No more jobs in the AllJobs Reference, so put the closestJob found in helper in user's reference
                            admin.database().ref('Couriers/' + emailHash + '/givenJob').update(jobBundle).then(() => {
                                console.log('Update succeeded!');
                                res.status(200).send("OK It Gave Back Jobs");
                            });
                        }
                    }); //End of observe single event
                }
            });
        } // End of first if statement
    }); //End of is flagged or verified function
}); //End of Function


function gotError(err) {
    if (err != null) {
        console.log("Inside gotError Function: " + err);
    }
}

function getClosestJobIdAndDistance(lat, long, callback) {
    var allJobsref = admin.database().ref('AllJobs');
    allJobsref.once('value', function (snapshot) {
        // console.log(data.val());
        var allJobsValues = snapshot.val();
        if (snapshot.val() != null) {
            var keysArr = Object.keys(allJobsValues); // this gives an array of keys of JobIDs
            var minimumDistance = 20000;
            var totalDistance = 20000;
            var closestJobId;
            var closestJobDict = {}; //should hold the closest job available
            for (const jobId in allJobsValues) {
                const pickupLat = allJobsValues[jobId].originLat;
                const pickupLong = allJobsValues[jobId].originLong;
                const deliveryLat = allJobsValues[jobId].deliveryLat;
                const deliveryLong = allJobsValues[jobId].deliveryLong;
                const distanceFromCurrentLocationToPickup = geo.getDistance({
                    latitude: lat,
                    longitude: long
                }, {
                        latitude: pickupLat,
                        longitude: pickupLong
                    });
                const distanceFromPickupToDelivery = geo.getDistance({
                    latitude: pickupLat,
                    longitude: pickupLong
                }, {
                        latitude: deliveryLat,
                        longitude: deliveryLong
                    });
                if (distanceFromCurrentLocationToPickup + distanceFromPickupToDelivery < totalDistance) {
                    closestJobDict = {};
                    closestJobDict[jobId] = allJobsValues[jobId];
                    closestJobId = jobId;
                    totalDistance = (distanceFromCurrentLocationToPickup + distanceFromPickupToDelivery);
                }
            } //end of for loop
            console.log(closestJobDict);
            if (Object.keys(closestJobDict).length > 0) {
                var result = [closestJobDict, totalDistance];
                console.log('Found 1: ' + closestJobDict + " " + result);
                admin.database().ref('AllJobs/' + closestJobId).remove().then(() => {
                    console.log("Removed job from AllJobs reference successfully");
                }, () => {
                    console.log("Cannot remove job from AllJobs reference")
                });
                //Closure Function below
                callback(null, result);
            } else {
                console.log('Found Nothing!');
                var noJobError = new Error("No Jobs Available");
                callback(noJobError, null);
                //found no close jobs
            } //end of if-statements
        } else {
            //AllJobs Reference is empty
            console.log("ALL MESSED UP");
            var emptyRefError = new Error("No Jobs Available");
            callback(emptyRefError, null);
        }
    }); //end of observe
}

exports.deleteUserFromDatabase = functions.auth.user().onDelete(event => {
    const data = event.data;
    const emailHash = crypto.createHash('md5').update(data.email).digest('hex');
    console.log('Deleting user from database');
    return admin.database().ref(`/Couriers/${emailHash}`).remove().then(function (fulfilled) {
        console.log('Deleted user from database');
    }, function (error) {
        console.log("Couldn't delete the user's reference");
    });
});

// To keep on top of errors, we should raise a verbose error report with Stackdriver rather
// than simply relying on console.error. This will calculate users affected + send you email
// alerts, if you've opted into receiving them.
// [START reporterror]
function reportError(err, context = {}) {
    // This is the name of the StackDriver log stream that will receive the log
    // entry. This name can be any valid log stream name, but must contain "err"
    // in order for the error to be picked up by StackDriver Error Reporting.
    const logName = 'errors';
    const log = logging.log(logName);

    // https://cloud.google.com/logging/docs/api/ref_v2beta1/rest/v2beta1/MonitoredResource
    const metadata = {
        resource: {
            type: 'cloud_function',
            labels: { function_name: process.env.FUNCTION_NAME }
        }
    };

    // https://cloud.google.com/error-reporting/reference/rest/v1beta1/ErrorEvent
    const errorEvent = {
        message: err.stack,
        serviceContext: {
            service: process.env.FUNCTION_NAME,
            resourceType: 'cloud_function'
        },
        context: context
    };

    // Write the error log entry
    return new Promise((resolve, reject) => {
        log.write(log.entry(metadata, errorEvent), error => {
            if (error) { reject(error); }
            resolve();
        });
    });
}
// [END reporterror]

// Sanitize the error message for the user
function userFacingMessage(error) {
    return error.type ? error.message : 'An error occurred, developers have been alerted';
}





//API STARTS HERE
function newDelivery(storeID, deliveryLat, deliveryLong, deliveryMainInstruction, deliverySubInstruction, originLat, originLong, pickupMainInstruction, pickupSubInstruction, recieverName, recieverNumber, pickupNumber) {

    getStore(storeID, function (storeValues, error) {
        if (error) {
            alert(error.message);
            console.log(error);
            return 500;
        } else {
            var deliveryDetails = { storeID, deliveryLat, deliveryLong, deliveryMainInstruction, deliverySubInstruction, originLat, originLong, pickupMainInstruction, pickupSubInstruction, recieverName, recieverNumber, pickupNumber };
            // deliveryDetails[storeName] = storeValues;
            deliveryDetails.isTaken = false;
            deliveryDetails.isCompleted = false;
            // Get a key for a new Post.
            var newPostKey = admin.database().ref().child('AllJobs').push().key;
            admin.database().ref('stores/' + storeID + '/deliveries/' + newPostKey).update(deliveryDetails).then(() => {
                console.log('Update succeeded: stores')
            });

            admin.database().ref('AllJobs/' + newPostKey).update(deliveryDetails).then(() => {
                console.log('Update succeeded: alljobs');
            });
        }
    })
}

function getStore(storeID, callback) {
    var storesRef = admin.database().ref('stores/' + storeID);
    storesRef.once('value', function (snapshot) {
        if (snapshot.exists()) {
            const storeValues = snapshot.val();
            callback(storeValues, null);
        } else {
            const error = new Error("No such store availablie");
            callback(null, error);
        }

    });
}