
console.log('hey');


var stripe = Stripe('pk_test_P3R1xmIzcdaTTBm1dudDPkgd');
var elements = stripe.elements();


var style = {
    base: {
        // Add your base input styles here. For example:
        fontSize: '25px',
        color: "#7795f8",
    }
};
// Create an instance of the card Element.
var card = elements.create('card', { style: style });

// Add an instance of the card Element into the `card-element` <div>.
card.mount('#card-element');

var form = document.getElementById('payment-form');
form.addEventListener('submit', function (event) {
    event.preventDefault();

    stripe.createToken(card).then(function (result) {
        if (result.error) {
            // Inform the customer that there was an error.
            var errorElement = document.getElementById('card-errors');
            errorElement.textContent = result.error.message;
        } else {
            // Send the token to your server.
            stripeTokenHandler(result.token);
        }
    });
});
function stripeTokenHandler(token) {
    //HERE IS THE TOKEN YOU GET BACK FORM ENTERING CARD INFO, USE THIS TO CREATE THE HTTPS REQUEST
    // Insert the token ID into the form so it gets submitted to the server
    var form = document.getElementById('payment-form');
    var hiddenInput = document.createElement('input');
    hiddenInput.setAttribute('type', 'hidden');
    hiddenInput.setAttribute('name', 'stripeToken');
    hiddenInput.setAttribute('value', token.id);
    form.appendChild(hiddenInput);
}