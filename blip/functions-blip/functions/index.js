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
      
exports.findItemInWalmart = functions.https.onRequest((req,res) => {
    var item = req.body.item,
        store = req.body.store;
    console.log(item, store);
    walmart.stores.search(
      store, item).then(function(items){
       console.log(items);
       res.send(items)
      })
})

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


// When a user is created, register them with Stripe
exports.createNewStripeCustomer = functions.auth.user().onCreate(event => {
    const data = event.data;
    const emailHash = crypto.createHash('md5').update(data.email).digest('hex');
    console.log(emailHash);
    return stripe.customers.create({
      email: data.email
    }).then(customer => {
      return admin.database().ref(`/Users/${emailHash}/customer_id`).set(customer.id);
      console.log(admin.database().ref(`/Users/${emailHash}/customer_id`))
    });
  });

exports.updateStripeCustomerDefaultSource = functions.https.onRequest((req,res) => {
  var customer = req.body.customerID,
    source = req.body.source;
  
  stripe.customers.update(customer, {
      default_source: source
  }, function(err, customer) {
      if (err) {
          console.log(err,req.body)
          res.status(500).end()
      } else {
          res.status(200).send()
      }
    });
  });

exports.getCustomer = functions.https.onRequest((req,res) => {
  stripe.customers.retrieve(req.body.customerID,
    function(err, customer) {
    // asynchronously called
      if (err) {
          console.log(err,req.body)
          res.status(500).end()
      } else {
          res.status(200).json(customer)
      }
    });
  });
  
  // Add a payment source (card) for a user by writing a stripe payment source token to Realtime database
exports.addNewPaymentSource = functions.https.onRequest((req,res) => {
  stripe.customers.createSource(req.body.customerID,
    {source: req.body.sourceID},
    function(err, source) {
    // asynchronously called
      if (err) {
        console.log(err,req.body)
          res.status(500).end()
      } else {
          res.status(200).send()
      }
    });
  });

  //adds the store to firebase
function addStore(storeName, storeLogo, storeBackground, storeDescription){
  var store = {storeName, storeLogo, storeBackground, storeDescription};
  admin.database().ref('stores/').update(store).then(() =>{
    console.log('Update succeeded!');
  });
}

function newDelivery(storeName, deliveryLat, deliveryLong, deliveryMainInstruction, deliverySubInstruction, originLat, originLong, pickupMainInstruction, pickupSubInstruction, recieverName, recieverNumber, pickupNumber)
{
  var deliveryDetails = {storeName, deliveryLat, deliveryLong, deliveryMainInstruction, deliverySubInstruction, originLat, originLong, pickupMainInstruction, pickupSubInstruction, recieverName, recieverNumber, pickupNumber};
  
  // Get a key for a new Post.
  var newPostKey = firebase.database().ref().child('posts').push().key;
  admin.database().ref('AllJobs/'+newPostKey).update(deliveryDetails).then(() =>{
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
      res.status(401).send(error);
    }else{
      getClosestJobIdAndDistance(lat, long, function(err, data){
        if(err){
          console.log("Found an Error");
          res.send(200,"No job found");
          // res.send(null);
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
    return admin.database().ref(`/Users/${emailHash}`).remove();
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