'use strict';

const functions = require('firebase-functions'),
      admin = require('firebase-admin'),
      logging = require('@google-cloud/logging')();
var crypto = require('crypto');
admin.initializeApp(functions.config().firebase);
var express = require('express');
var bodyParser = require('body-parser');
var walmart = require('walmart')("qeq7xghhtkb8ate7x59px7yk");
const app = express();
const geo = require('geolib');
const stripe = require('stripe')("sk_test_pHrsE3Th44nSEbFbUXvlpC6X"),
      currency ="CAD";

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
    stripe.ephemeralKeys.create(
      {customer: req.body.customerID},
      {stripe_version: stripe_version}
    ).then((key) => {
      res.status(200).json(key);
    }).catch((err) => {
      res.status(500).end();
    });
  });

exports.charges = functions.https.onRequest((req,res) => {
  var customer = req.body.customerID,
      amount = req.body.amount,
      currency = req.body.currency,
      Email = req.body.email_hash;
  const emailHash = crypto.createHash('md5').update(Email).digest('hex');
  console.log(amount);
  stripe.charges.create({
    customer : customer,
    amount: amount,
    currency : currency,
    capture: false
  },function(err,charge){
    if (err) {
      console.log(err,req.body)
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
  stripe.charges.capture(chargeID, function(err, charge){
    console.log(charge);
    if (err){
      console.log(err.req.body)
      res.status(500).end()
    } else {
      res.status(200).send(charge.id)
    }
  })
});


exports.createStore =  functions.https.onRequest((req, res) =>{
  var storeName = req.body.storeName;
  var storeLogo = req.body.storeLogo;
  var storeBackground = req.body.storeBackground;
  var locationLat = req.body.locationLat;
  var locationLong = req.body.locationLong;
  var routing_number = req.body.routingNumber;
  var account_number = req.body.accountNumber;
  var city = req.body.city;
  var country = req.body.country;
  var line1 = req.body.line1;
  var postal_code = req.body.postalCode;
  var province = req.body.province;
  var business_name = req.body.businessName;
  var business_tax_id = req.body.businessTaxId;
  var first_name = req.body.firstName;
  var last_name = req.body.lastName;
  var personal_id_number = req.body.personalIdNumber;
  var dob_day = req.body.dobDay;
  var dob_month = req.body.dobMonth;
  var dob_year = req.body.dob_year;
  var date = Math.floor(new Date() / 1000);

  var email = req.body.email;

  stripe.accounts.create({
    "country":"CA",
    "email":email,
    "type":"custom",
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
        "country": country,
        "line1": line1,
        "postal_code": postal_code,
        "state": province
      },
      "business_name":"Nike",
      "business_tax_id":"000000000",
      "dob":{
        "day":"01",
        "month":"01",
        "year":"1990"
      },
      "first_name":first_name,
      "last_name":last_name,
      "personal_id_number":personal_id_number,
      "type": "company"
    },
    "tos_acceptance":{
      "date":date.toString,
      "ip":"138.51.250.201"
    }
  }, function(err, account){
    if(err){
      console.log(err);
      res.status(400).end();
    }else{
      stripe.tokens.create({
        bank_account: {
          country: 'CA',
          currency: 'cad',
          account_holder_name: business_name,
          account_holder_type: 'company',
          routing_number: routing_number,
          account_number: account_number
        }
      }, function(err, token) {
        if (err){
          console.log("Could not create store due to;"+err);
          res.status(450).end
        }else{
          var storeDetails = {storeName, storeLogo, storeBackground, locationLat, locationLong};
          storeDetails.stripeAccount = account;
          storeDetails.strpeAccount.token = token.id;
          var storeID = admin.database().ref().child('stores').push().key;
          admin.database().ref('stores/'+storeID).update(storeDetails).then(() =>{
            console.log('Created store successfully')
          });
          res.status(200).send(storeID);
        }
      });
    }
  });
});


  exports.updateStripeAccount = functions.https.onRequest((req,res) => {
    console.log(req.body);
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
          "personal_id_number": sin,
          "type": "individual", 
        },
        "tos_acceptance": {
          "date": tos_time,
          "ip": "99.250.237.232"
        }
      }, function(err, account) {
        if (err){
          console.log(err)
          res.end()
        }
        else{
          console.log(account)
          res.send(account)
        }
      });
  })

exports.createNewStripeAccount = functions.https.onRequest((req,res) => {
  const email = req.body.email;
  const emailHash = crypto.createHash('md5').update(email).digest('hex');
  const firstName = req.body.firstName;
  const lastName = req.body.lastName;

  return stripe.accounts.create({
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
  },function(err, account){
    if (err){
      console.log(err);
      res.end();
    }
    else{
      admin.database().ref(`/Couriers/${emailHash}/stripeAccount`).set(account)
      console.log(account);
      res.send(200, account);
    }
  });
});

function addStore(storeName, storeLogo, storeBackground, storeDescription){
  var store = {storeName, storeLogo, storeBackground, storeDescription};
  admin.database().ref('stores/').update(store).then(() =>{
    console.log('Update succeeded!');
  });
}

function checkUserVerifiedOrFlagged(emailHash, callback){
  admin.database().ref('Couriers/'+emailHash).once('value', function(snapshot){
    var userValues = snapshot.val();
    if(userValues != null){
      const flagged = userValues.flagged;
      const verified = userValues.verified;
      if (!(verified)){
        var notVerifiedError = new Error("User needs to verify their background check");
        callback(notVerifiedError, null);
      }
      else if (flagged != null){
        var flaggedError = new Error("User account has been flagged due to leaving a job");
        callback(flaggedError, null);
      }
      else{
        callback(null, true);
      }
    }else{
      //SOME WEIRD THING HAPPEN
    }
  });
}

function getChargeAmount(deliveryLat, deliveryLong, pickupLat, pickupLong){
  const distanceBtw = geo.getDistance({latitude: deliveryLat, longitude: deliveryLong}, {latitude: pickupLat, longitude: pickupLong});
  const price = (distanceBtw/10) + 450 + 1 + 3.5;
  return price*100;
}

exports.makeDeliveryRequest = functions.https.onRequest((req,res) => {
  //storeName, deliveryLat, deliveryLong, deliveryMainInstruction, deliverySubInstruction, originLat, originLong, pickupMainInstruction, pickupSubInstruction, recieverName, recieverNumber, pickupNumber  
  var storeID = req.body.storeID;
  admin.database().ref(`/stores/${storeID}`).once("value", function(snapshot){
    if (snapshot.exists){
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
          stripeAccountKey = snapshot.child(`/stripeAccount/keys/secret`).val(),
          stripeAccount = require("stripe")(stripeAccountKey);
          chargeAmount = getChargeAmount(deliveryLat,deliveryLong, originLat,originLong);
          // @TODO: You have to calculate amount using a function. First get the delivery location from above, then pickup location
                  // Calculate the distance between teh pickup point, and delivery point, divide that answer by 10, then add 450. this will be the 
                  // amount we charge the company (remember: 1 dollar per KM plus 1 for pickup, 3.5 for delivery, Then you must
                  // convert all that to cents because stripe works only with cents not dollars)

      stripe.charges.create({
        amount: chargeAmount,
        currency: "cad",
        application_fee: 100,
        capture: false,
        description: "Delivery Charge",
        source: snapshot.child(`/stripeAccount/token`).val()
      }).then(function(err, charge) {
        if (err){
          console.log(err);
          res.status(450).end
        }else{
          const call = newDelivery(charge.id,storeID,deliveryLat,deliveryLong,deliveryMainInstruction,deliverySubInstruction,originLat,originLong,pickupMainInstruction,pickupSubInstruction,recieverName,recieverNumber,pickupNumber);
          if (call === 500){
            console.log("Incorrect storeID")
            res.status(400).end();
          }else{
            console.log("Created delivery")
            res.status(200).send();
          }
        }
      });
    }else{
      console.log("No such storeID");
      res.status(500).end()
    }
  })
});

exports.getBestJob = functions.https.onRequest((req,res) => {
  var long = req.body.locationLong,
      lat = req.body.locationLat,
      emailHash = req.body.emailHash;
  var minDist = 20000,
      currentDist = 0,
      jobKey;

  checkUserVerifiedOrFlagged(emailHash, function(error, checked){
    if (error){
      console.log(error.message, req.body);
      if (error.message === "User needs to verify their background check"){
        res.status(400).send(error);
      }else{
        res.status(500).send(error);
      }
      
    }else{
      getClosestJobIdAndDistance(lat, long, function(err, data){
        if(err){
          console.log("Found an Error");
          res.status(600).send(err);
        }else{
          var maxDist = 20000;
          const closestJobIdDict = data[0];//This is a dictionary
          const closestJobId = Object.keys(closestJobIdDict)[0];
          console.log("Initial MaxDist is: "+maxDist);
          console.log("Dict: "+closestJobIdDict+" ID: "+closestJobId);
          const totalDistance = data[1];
          var jobBundle = closestJobIdDict;
          maxDist = maxDist - totalDistance;
    
          var allJobsref = admin.database().ref('AllJobs');
          allJobsref.once('value', function(snapshot){
            var allJobsValues = snapshot.val();
            if(allJobsValues != null){
              for (const jobId in allJobsValues){
                if(jobId != closestJobId){//So skip if it sees the same job as the closest it already found
                  const pickupLat = allJobsValues[jobId].originLat;
                  const pickupLong = allJobsValues[jobId].originLong;
                  const deliveryLat = allJobsValues[jobId].deliveryLat;
                  const deliveryLong = allJobsValues[jobId].deliveryLong;
                  var x = geo.getDistance({latitude: pickupLat, longitude: pickupLong}, {latitude: lat, longitude: long});
                  var y = geo.getDistance({latitude: pickupLat, longitude: pickupLong}, {latitude: closestJobIdDict[closestJobId].originLat, longitude: closestJobIdDict[closestJobId].originLong});
                  var m = geo.getDistance({latitude: pickupLat, longitude: pickupLong}, {latitude: deliveryLat, longitude: deliveryLong});
                  var n = Math.min(...[x,y]);
    
                  if (maxDist >= (m+n)){
                    var jobDict = {};
                    // jobDict[jobId] = allJobsValues[jobId];
                    jobBundle[jobId] = allJobsValues[jobId];
                    maxDist = maxDist - (m+n);
                    admin.database().ref('AllJobs/'+jobId).remove().then(() =>{
                      console.log("Removed job from AllJobs reference successfully");
                    }, () =>{console.log("Cannot remove job from AllJobs reference")});
                    console.log("MaxDist is: "+maxDist);
                  }
                }else{
                  admin.database().ref('AllJobs/'+jobId).remove().then(() =>{
                    console.log("Removed job from AllJobs reference successfully");
                  }, () =>{console.log("Cannot remove job from AllJobs reference")});
                }
              }//End of For loop
    
              admin.database().ref('Couriers/'+emailHash+'/givenJob/deliveries').update(jobBundle).then(() =>{
                console.log('Update succeeded!');
                res.status(200).send("OK It Gave Back Jobs");
              });
            }else{
              //No more jobs in the AllJobs Reference, so put the closestJob found in helper in user's reference
              admin.database().ref('Couriers/'+emailHash+'/givenJob/deliveries').update(jobBundle).then(() =>{
                console.log('Update succeeded!');
                res.status(200).send("OK It Gave Back Jobs");
              });
            }
          });//End of observe single event
        }
      });
    }// End of first if statement
  });//End of is flagged or verified function
});//End of Function
  
function gotError(err){
  if(err != null){
    console.log("Inside gotError Function: "+err);
  }
}

function getClosestJobIdAndDistance(lat, long, callback){
  var allJobsref = admin.database().ref('AllJobs');
  allJobsref.once('value', function(snapshot){
    // console.log(data.val());
    var allJobsValues = snapshot.val();
    if (allJobsValues != null){
      var keysArr = Object.keys(allJobsValues);// this gives an array of keys of JobIDs
      var minimumDistance = 20000;
      var totalDistance = 20000;
      var closestJobId;
      var closestJobDict = {};    //should hold the closest job available
      for (const jobId in allJobsValues){
        const pickupLat = allJobsValues[jobId].originLat;
        const pickupLong = allJobsValues[jobId].originLong;
        const deliveryLat = allJobsValues[jobId].deliveryLat;
        const deliveryLong = allJobsValues[jobId].deliveryLong;
        const distanceFromCurrentLocationToPickup = geo.getDistance({latitude: lat, longitude: long}, {latitude: pickupLat, longitude: pickupLong});
        const distanceFromPickupToDelivery = geo.getDistance({latitude: pickupLat, longitude: pickupLong}, {latitude: deliveryLat, longitude: deliveryLong});
        if(distanceFromCurrentLocationToPickup+distanceFromPickupToDelivery < totalDistance){
          closestJobDict = {};
          closestJobDict[jobId] = allJobsValues[jobId];
          closestJobId = jobId;
          totalDistance = (distanceFromCurrentLocationToPickup+distanceFromPickupToDelivery);
        }
      }//end of for loop
      console.log(closestJobDict);
      if (Object.keys(closestJobDict).length > 0){
        var result = [closestJobDict, totalDistance];
        console.log('Found 1: '+closestJobDict+" "+result);
        admin.database().ref('AllJobs/'+closestJobId).remove().then(() =>{
          console.log("Removed job from AllJobs reference successfully");
        }, () =>{console.log("Cannot remove job from AllJobs reference")});
        //Closure Function below
        callback(null,result);
      }else{
        console.log('Found Nothing!');
        var noJobError = new Error("No Jobs Available");
        callback(noJobError, null);
        //found no close jobs
      }//end of if-statements
    }else{
      //AllJobs Reference is empty
      var emptyRefError = new Error("No Jobs Available");
      callback(emptyRefError, null);
    }
  });//end of observe
}

exports.deleteUserFromDatabase = functions.auth.user().onDelete(event =>{
    const data = event.data;
    const emailHash = crypto.createHash('md5').update(data.email).digest('hex');
    console.log('Deleting user from database');
    return admin.database().ref(`/Couriers/${emailHash}`).remove();
    console.log('Deleted user from database');
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
function newDelivery(storeID, deliveryLat, deliveryLong, deliveryMainInstruction, deliverySubInstruction, originLat, originLong, pickupMainInstruction, pickupSubInstruction, recieverName, recieverNumber, pickupNumber)
{

  getStore(storeID, function(storeValues, error){
    if (error){
      alert(error.message);
      console.log(error);
      return 500;
    }else{
      var deliveryDetails = {storeID, deliveryLat, deliveryLong, deliveryMainInstruction, deliverySubInstruction, originLat, originLong, pickupMainInstruction, pickupSubInstruction, recieverName, recieverNumber, pickupNumber};
      // deliveryDetails[storeName] = storeValues;
      deliveryDetails.isTaken = false;
      deliveryDetails.isCompleted = false;
      // Get a key for a new Post.
      var newPostKey = admin.database().ref().child('AllJobs').push().key;
      admin.database().ref('stores/'+storeID+'/deliveries/'+newPostKey).update(deliveryDetails).then(() =>{
        console.log('Update succeeded: stores')
      });

      admin.database().ref('AllJobs/'+newPostKey).update(deliveryDetails).then(() =>{
        console.log('Update succeeded: alljobs');
      });
    }
  })
}

function getStore(storeID, callback){
  var storesRef = admin.database().ref('stores/'+storeID);
  storesRef.once('value',function(snapshot){
    if (snapshot.exists()){
      const storeValues = snapshot.val();
      callback(storeValues,null);
    }else{
      const error = new Error("No such store availablie");
      callback(null,error);
    }
    
  });
}