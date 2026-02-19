import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  Future<String> getsServerKeyToken() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "bangerdrop-aaed4",
        "private_key_id": "d3fe7cd65a427865b2f560b68e53fefadc22e6e5",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC2jL9ezA9VCJdg\nIEYc7i3HHDzoMxTJOWUhxAZ3w3vvo8vQxRM6Ju0vAe73uQunO5TxrpzyVxCQvDFq\nuuzIC9NKh+EiawdZzh+GeC11QVLe4PaRuvkKGXGgdrYwIwgrMxXU8YGri6tW3tQY\nDa3t8NObaS7j9rMaAd4zBrGwmn14li4pNlURJEpwLpljGhS2DH95rcP2r+P2A/xL\n84HPqAUYwtIcRPWZR1tGlCz3Jj9TQ+qIxWbCzSPXD/VIrUTQNfreicNOYExc5qiP\naQ/AYfPJ3SvBSxLDFDNM+8mcBQXwU8iqql4StuhZVN9cZ/FU8bam7NHDpULkAlxI\nYpdgzJgtAgMBAAECggEAGSrdFL62u8HMIjk7hrA3qM8gforRqiRlkvrUQXK2sC/k\nNkt//nEbcMhSyohn2OMtV7H70AASN+zE4LLArkZ4bOVq3onkS4ylaq6VkH2JuqdH\n7IjbM3nqi8rnYfTnzWePnPoRfIsW+4phB1KWJiB2VrjGTtuA5GxZgVjCQAIsm5Et\nO1Sv03Dc7FxISlw/lvHffjuOkMARZUPgzfXdDmogpNuu9JUCRle64Vj1wriSIyuM\nTXM0jm1mIGFs0/MTNrB1WMc/63ok/4m0Wxlw3OZXn7hf+11O6D7xeaKiq4urNCqO\nOZFpW7PyCJhRi9tSMo7YoAhFAKjToLuNjo1RVERpqQKBgQDk7KXNQ7d4HUHSEmvX\nrkSNfdFxi07+yShOeJpj3oOZp+r9t8A5EDuJRMigII/j4+fNJqD2+Wc6gtzPA2TG\nRqci/DUuQirMdnXfb9KpvdeeqU9tvK08ewiteTl8ju9I2HdeugtBnpd/ICki++9d\nP0dzG5K6ZNAn2mdtUlasmMSnewKBgQDMI/lBSXLHtibEhTHzk2dHYIvGvzU9MnNu\nAT90vz4FlVO1Lkos/6/HP2VjELLkiYxygX4oh5c7umak1+aeCBp35Ng3qOPKw/es\nckAsEXwrg2rwSd04XV/tBOxlPhd+MrpKIK9ZIXJ90NGwW8y+1VtemyLxxjc5jjCo\nJN2zFwzadwKBgQC9JFmJUx3PfDzZ2KaJuU6iqQXXjoZiNMm8rCDDyyFoXzjlEGEd\nxK+sJsysoLrCS5dGBViRNld4HI9b6y3kNJP7b+5wnfLGpEmXpsijvlrcmH8r5+wq\nQG1XBwXcSCykP1XBSm3qdaIuQuA6K3YF0TazgGCm6IyjoOw7gwBh8obo6QKBgQCV\ndjU1jsAh5oRl2BtleePhB5fvMOma38hRn0pFgQu47Mb33WdjoOSi3hCuQnioCOky\noQqsQ/H/Qg+K26Q2yjoO1BdWUSpOt8IrmQ7Q9RBTj4mJWptEfGESWUt3KMnslNl+\nEoYvnOSFp5EPLXcvtWiLUMx59iVS139abHuBdvvrKwKBgG8OtpnbhuJ4Z7PevjDx\nxGXWmkyiPFSxJGSmp6CPcFzT0eV3W03uUaalX6nq/NJDQ+WZX9cUlZm3zIGFziO0\naGTI73fSBvlL94uBbKtiv0NO8go1JroieytMkpiJ5UYmR+Hs/99Uw1gnjmmBvGAH\nK5zblMv0LnpOCFgU7wheTWdJ\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-fbsvc@bangerdrop-aaed4.iam.gserviceaccount.com",
        "client_id": "102263735924439530122",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40bangerdrop-aaed4.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      }),
      scopes,
    );
    final accessServerKey = client.credentials.accessToken.data;

    return accessServerKey;
  }
}






                                //   GetServerKey getKey = GetServerKey();
                                //   String accessToken =
                                //       await getKey.getsServerKeyToken();

                                //   // Get target device FCM token
                                //   String? targetToken =
                                //       await notificationServices
                                //           .getDeviceToken();

                                //   if (targetToken == null) {
                                //     print('Target device token not found.');
                                //     return;
                                //   }

                                //   // Construct HTTP v1 payload
                                //   var payload = {
                                //     "message": {
                                //       "token": targetToken,
                                //       "notification": {
                                //         "title": "Hello there",
                                //         "body":
                                //             "This is a notification for Banger Drop",
                                //       },
                                //       "data": {"type": "msg"},
                                //     },
                                //   };

                                //   // Send notification using HTTP v1 API
                                //   final response = await http.post(
                                //     Uri.parse(
                                //       'https://fcm.googleapis.com/v1/projects/bangerdrop-aaed4/messages:send',
                                //     ),
                                //     headers: {
                                //       'Content-Type': 'application/json',
                                //       'Authorization': 'Bearer $accessToken',
                                //     },
                                //     body: jsonEncode(payload),
                                //   );

                                //   print('Status: ${response.statusCode}');
                                //   print('Response body: ${response.body}');
                                // },