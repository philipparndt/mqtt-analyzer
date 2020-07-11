# Create a certificate for AWS IoT

## AWS page

- Open the AWS IoT page and go to Secure / Certificates.
- Press the `Create` button in order to create a new certificate.
- Select `One-click certificate creation (recommended)` (`Create certificate` button)
- Download the certificate files for example `2740d89289-certificate.pem.crt` and `2740d89289-private.pem.key`
you do not need `2740d89289-public.pem.key` for this example.
- Select `Activate` to activate the certificate
- Select `Attach a policy` and attach a policy that allows access to MQTT. For example:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iot:*",
      "Resource": "*"
    }
  ]
}
```

- Go to a thing and open the `Interact` page.
- Copy the `Reast API Endpoint` url (example `abcdefghijklmn-ats.iot.eu-west-1.amazonaws.com`)

## In your terminal

```bash
openssl pkcs12 -export -in 2740d89289-certificate.pem.crt -inkey 2740d89289-private.pem.key -out aws-iot.p12
```

Copy the result file to your device using Finder / iTunes or copy it to iCloud.

## Within the app

- Create a new setting using the given url.
- Select `Use default settings for AWS IoT?`
- Select the `aws-iot.p12` certificate and the chosen password.
