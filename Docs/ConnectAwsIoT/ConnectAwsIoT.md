## Connecting to Amazon Web Services (AWS) IoT using  MQTT Protocol 

To connect to AWS-IoT a Client Certificate has to be transferred to the iOS-Device.

The following instructions refer to a Windows 10 PC:

Create an AWS IoT certificate as described here:

https://docs.aws.amazon.com/iot/latest/developerguide/device-certs-create.html

The AWS-IoT platform creates three files (Certificate like 47d5ccf612-certificate.pem.crt, public key like  47d5ccf612-public.pem.key and a private key like 47d5ccf612-private.pem.key ) that have to be downloaded to your PC. Additionally the AWS-IoT Root Certificate (like ‘Amazon Root CA 1’) which is needed for the server authentication on other IoT-Devices can be downloaded. On iOS-Devices this root certificate should alyready be present in the device's certificate cache.

Then using the private key (xyz-private.pem.key) and Certificate (xyz-certificate.pem.crt) a certificate in PKCS12 format has to be created. 
This can be done with the open source application ‘openssl’. OpenSsl must be compiled on your Computer as described in this tutorial:

https://www.youtube.com/watch?v=PMHEoBkxYaQ

Alternatively an installable versions of openssl can be used (not tested).

Use the following command in an administrator command prompt:

openssl pkcs12 -export -in xyz-certificate.pem.crt -inkey xyz-private.pem.key -out aws-client.p12

(for  'xyz-certificate.pem.crt' and 'xyz-private.pem.key' take the files which you got from Amazon)

You are asked to enter a password which you will use in future to open the certificate.

Now the certificate aws-client.p12 must be transferred to the iOS-Device.

You can do this using 'iTunes' or 'Finger' from a Mac or 'iTunes' from a Windows PC or Mac.

We decribe the way using iTunes:
1) Open iTunes on your Mac or PC.
2) Connect your iPhone to your computer using a USB cable.
3) Click your device in iTunes.

4) In the left sidebar, click File Sharing.

5) Select the 'MQTT-Analyzer' app.

6) Click the 'Add files' button and add the certificate aws-client.p12





