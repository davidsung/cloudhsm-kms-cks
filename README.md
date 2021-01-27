# Using CloudHSM for KMS Custom Key Store

```
terraform init
terraform plan
terraform apply
```

## Create CloudHSM certificates
```
mkdir certs && cd certs
terraform output cloudhsm_cluster_csr > cluster.csr
openssl genrsa -aes256 -out customerCA.key 2048
openssl req -new -x509 -days 3652 -keyout customerCA.key -subj '/O=Octagon Ltd./C=HK' -out customerCA.crt
openssl x509 -req -days 3652 -in cluster.csr \
                              -CA customerCA.crt \
                              -CAkey customerCA.key \
                              -CAcreateserial \
                              -out CustomerHsmCertificate.crt
cd ..
```

## Initialize CloudHSM Cluster
To initialize the CloudHSM, execute the following command:
```
aws cloudhsmv2 initialize-cluster --cluster-id $(terraform output -json | jq -r .cloudhsm_cluster_id.value) \
                                    --signed-cert file://certs/CustomerHsmCertificate.crt \
                                    --trust-anchor file://certs/customerCA.crt
```
You should see the following result:
```
{
    "State": "INITIALIZE_IN_PROGRESS",
    "StateMessage": "Cluster is initializing. State will change to INITIALIZED upon completion."
}
```

# Install AWS CloudHSM Client on management instance
Connect to your client instance
```
wget https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/EL6/cloudhsm-client-latest.el6.x86_64.rpm
sudo yum install -y ./cloudhsm-client-latest.el6.x86_64.rpm
```

Copy self signed CA certificate to the client instance
```
scp customerCA.crt ec2-user@$(terraform output -json | jq -r .hsm_client_hostname.value):~/
sudo mv customerCA.crt /opt/cloudhsm/etc/
```

Configure HSM IP address
```
sudo service cloudhsm-client stop
sudo /opt/cloudhsm/bin/configure -a <IP address>
sudo service cloudhsm-client start
sudo /opt/cloudhsm/bin/configure -m
```

# CloudHSM Management Utility
```
/opt/cloudhsm/bin/cloudhsm_mgmt_util /opt/cloudhsm/etc/cloudhsm_mgmt_util.cfg
```

```
aws-cloudhsm>listUsers
Users on server 0(server1):
Number of users found:2

    User Id             User Type       User Name                          MofnPubKey    LoginFailureCnt         2FA
         1              PRECO           admin                                    NO               0               NO
         2              AU              app_user                                 NO               0               NO
```

```
aws-cloudhsm>loginHSM PRECO admin password
```

```
aws-cloudhsm>changePswd PRECO admin <NewPassword>
```

```
aws-cloudhsm>listUsers
```

```
aws-cloudhsm>quit
```

## Create CU kmsuser
```
/opt/cloudhsm/bin/cloudhsm_mgmt_util /opt/cloudhsm/etc/cloudhsm_mgmt_util.cfg
```

```
loginHSM CO admin <Password>
```

```
createUser CU kmsuser password
```

```
logoutHSM
```

```
quit
```

## Create KMS Custom Key Store
Create a KMS Custom Key Store using the CloudHSM provisioned above, remember to replace `kmsPswd` below with the one you entered in the previous step
```
aws kms create-custom-key-store \
        --custom-key-store-name KmsKeyStore \
        --cloud-hsm-cluster-id $(terraform output -json | jq -r .cloudhsm_cluster_id.value) \
        --key-store-password kmsPswd \
        --trust-anchor-certificate file://certs/customerCA.crt
```

## Connect KMS Custom Key Store to CloudHSM
Connect the KMS Custom Key Store to the CloudHSM Cluster, please replace the `custom-key-store-id` with the returned value in the previous step
```
aws kms connect-custom-key-store --custom-key-store-id cks-1234567890abcdef0
```
Note: this step might take quite long to complete, approximately around 20mins

## Login HSM using key_mgmt_util
```
sudo service cloudhsm-client start
/opt/cloudhsm/bin/key_mgmt_util
loginHSM -u CU -s [crypto_user_name] -p [password]
```

## Logout and exit
```
logoutHSM
exit
```