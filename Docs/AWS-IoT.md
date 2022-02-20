# Connect to AWS IoT

## On AWS Management Console

- Open the AWS IoT management console

https://eu-central-1.console.aws.amazon.com/iot/home?region=eu-central-1#/connectdevice/

Select Linux/OSX as Platform
Node.js as SDK

- Create a thing e.g., "example"

- Download the connection kit for Linux/OSX

This will give you a file named "connect_device_package.zip"
The package contains four files:

| Content |
| --------------------- |
| `example.cert.pem` |
| `example.private.key` |
| `example.public.key` |
| `start.sh` |

Execute the following command in your terminal (macOS, Linux, Git bash on Windows) to create a P12 file:

```bash
openssl pkcs12 -export -in example.cert.pem -inkey example.private.key -out example.p12
```

This will ask you for an export password. You have to specify this later in the MQTTAnalyzer app. So make sure to remember it.

Open the `start.sh` file. You will find the host-name in the last command. 
Example: `123456abcdefgh-ats.iot.eu-central-1.amazonaws.com`

You can also find this endpoint on the AWS [settings page](https://eu-central-1.console.aws.amazon.com/iot/home?region=eu-central-1#/settings).

## Create an access policy

Without this, you will get a "Socket closed by remote peer" error after connecting to the broker.

Create a new policy:
https://eu-central-1.console.aws.amazon.com/iot/home?region=eu-central-1#/create/policy

| --------------- | ----- |
| Policy name | All |
| Policy effect | Allow |
| Policy action | * |
| Policy resource | * |

Select `create` to create the policy.

Open the certificate page:
https://eu-central-1.console.aws.amazon.com/iot/home?region=eu-central-1#/certificatehub

Select your certificate and attach the `All` policy to this certificate.

## Open MQTTAnalyzer

- Create a new broker setting in MQTTAnalyzer
- Paste the hostname, select the option `Use default settings for AWS IoT`. This will update the port number to 8883 and activate SSL with certificate.
- Copy the P12 file you have previously created to the MQTTAnalyzer folder in iCloud or directly to your device.
- Select the certificate
- Enter the password that you have chosen for the P12 file
