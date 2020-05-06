# mqtt-analyzer

## Connecting to Amazon Webservice (AWS) IoT using  MQTT Protocol 

To connect to AWS-IoT a Client Certificate has to be installed on the iOS-Device.

The following instructions refer to a Windows 10 PC:

Create an AWS IoT certificate as described here:

https://docs.aws.amazon.com/iot/latest/developerguide/device-certs-create.html

The AWS-IoT platform creates three files (Certificate like 47d5ccf612.pem.crt, public key like  47d5ccf612.public.key and a private key like 47d5ccf612.private.key ) that have to be downloaded to your PC. Additionally the Amazon Root Certificate (like ‘Amazon Root CA 1’) which is needed for the server authentication has to be downloaded.

Then using the private key (47d5ccf612.private.key) and Certificate (47d5ccf612.cert.pem)    a Certificate in PKCS12 Format has to be created. 
This can be done with the open source application ‘openssl’. OpenSsl must be compiled on your Computer as described in this tutorial:

https://www.youtube.com/watch?v=PMHEoBkxYaQ

Alternatively an installable Versions can be used, but I didn’t try this.

Use the following command in an administrator command prompt:
openssl pkcs12 -export -out YOURPFXFILE.pfx - inkey *****-private.pem.key -in *****-certificate.pem.crt'
(for '*****-private.pem.key' and '*****-certificate.pem.crt' take the files which you got from Amazon)

Now the certificate YOURPFXFILE.pfx (can be renamed) must be transferred to the iOS Device.

I used the way to send the file as E-Mail attachment.
 Open the E-mail, double tap the Certificate and install it on your iPhone.
Then go to Settings  General  Profile  go to the Certificate and pap Install. iOS will ask for your device code and will tell that the Profile is not signed. Tap one more time on Install.
Now you are asked for the Password of the certificate, which you entered before. Tap Ready.
If your certificate is not properly installed follow the steps suggested in this link

https://discussions.apple.com/thread/8490385

