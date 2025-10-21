# curbshare

a mobile app that connects drivers with homeowners renting out unused parking spaces, reducing roadside parking and improving pedestrian access. It helps ease urban parking shortages while allowing homeowners to earn passive income and drivers to find secure, affordable, and convenient parking.

## Technologgies used
- Flutter

- Firebase handle all data, auth (phone and google)
- Google Map Api
- Express JS to deploy func to firebase directly
- FCM for notification push
- Stripe for dummy payment

## API Key needed:
- /AndroidManifest.xml android:name="com.google.android.geo.API_KEY"
            android:value="Input the value of own api key" />

- lib/services/place_service.dart   final String apiKey = "Input Your API Key";
- Stripe publish key (main.dart) and private key + wh key in backend folder create a .env for it
- Stripe.publishableKey = 'input your publish'; // your publishable key
- use firebaseOption if wanted. must have firebase_options.dart before able to initialized the firebase
- await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
