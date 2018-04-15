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

exports.getBestJob = functions.https.onRequest((req,res) => {
  var long = req.body.locationLong,
      lat = req.body.locationLat,
      emailHash = req.body.emailHash;
  var minDist = 20000,
      currentDist = 0,
      jobKey;
  admin.database().ref('AllJobs').on('value').then((snapshot) =>{ 
    console.log(snapshot);
  })
})

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