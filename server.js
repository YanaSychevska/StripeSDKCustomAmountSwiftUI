const stripe = require('stripe')('sk_test_...');
const express = require('express');
const app = express();
app.use(express.json());

app.post('/prepare-payment-sheet', async (req, res) => {
    const customer = await stripe.customers.create();
    const ephemeralKey = await stripe.ephemeralKeys.create({customer: customer.id},
                                                           {apiVersion: '2024-04-10'});
    const paymentIntent = await stripe.paymentIntents.create({
        amount: 1099,
        currency: 'usd',
        customer: customer.id,
        automatic_payment_methods: {
            enabled: true,
        },
    });
    
    res.json({
        paymentIntentID: paymentIntent.id,
        clientSecret: paymentIntent.client_secret,
        ephemeralKey: ephemeralKey.secret,
        customer: customer.id,
        publishableKey: 'pk_test_...'
    });
});

app.post('/update-payment-sheet', async (req, res) => {
    const paymentIntent = await stripe.paymentIntents.update(
        req.body.paymentIntentID,
        {
            amount: req.body.amount,
        }
    );
    console.log(req.body)
    console.log(res.body)
    
    res.json({});
});

app.listen(4242, () => console.log('Running on port 4242'));

