# Bastion and SSM usecase

Here I have used a bastion host in a public subnet to access my other resources residing in the private subnet, if I were to do this setup for a org/enterprise 
I would not create a public subnet or the bastion host, I'll just attach the Teams logins with the AWS IAM identity center 

> if a company uses Microsoft Teams and Office 365, they will use Microsoft Entra ID [formerly Azure AD] to manage employee logins, these logins can be used by AWS to 
> login into AWS CLI using your standard corporate email and pass

> AWS grants you a temporary session under an IAM Role (e.g., CloudEngineer-ReadOnly).

> That role has the AmazonSSMManagedInstanceCore and ReadOnlyAccess policies attached.

> You open your local terminal and run aws ssm start-session --target i-0abcd1234... and you are instantly securely dropped into the EC2 instance's shell.

## How to exectue this handshake

### Phase 1: Prepare AWS IAM Identity Center
First, you need to tell AWS to stop managing users itself and prepare to listen to an external directory.

- Open the AWS Console and navigate to IAM Identity Center.

- Enable the service (if you haven't already in your organization).

- Go to Settings > Identity source and click Change identity source.

- Select External identity provider.

- In the Service provider metadata section, click Download metadata file. You now have the AWS XML file; keep it handy. Leave this AWS window open.

### Phase 2: Create the Enterprise App in Entra ID
Now, you head over to the Microsoft side to set up the application that will "push" identities to AWS.

- Log into the Microsoft Entra admin center (formerly Azure Portal).

- Navigate to Identity > Applications > Enterprise applications.

- Click New application and search the gallery for AWS IAM Identity Center. Add it.

- Once created, go to the Single sign-on tab on the left menu and select SAML.

### Phase 3: The Metadata Handshake
This is where the two systems exchange cryptographic trust.

- Tell Entra about AWS: On the Entra SAML page, click Upload metadata file and select the XML file you downloaded from AWS in Phase 1. This automatically populates the AWS entity IDs and reply URLs in Azure.

- Tell AWS about Entra: Scroll down on that same Entra SAML page to the SAML Certificates section and download the Federation Metadata XML.

- Go back to your open AWS IAM Identity Center tab. In the Identity provider metadata section, upload this Entra XML file.

- Click Next, review, and type ACCEPT to finalize the identity source change.

- At this point, the SAML authentication bridge is built. If a user tries to log into AWS, it will redirect them to a Microsoft login screen.

### Phase 4: Configure SCIM (The Enterprise Magic)
Without SCIM, you would have to manually create a user in AWS and perfectly match their email to their Entra ID account. At scale, that's impossible. SCIM automates this.

- In AWS IAM Identity Center, go to Settings > Automatic provisioning and click Enable.

- AWS will generate two crucial pieces of data: a SCIM endpoint URL and an Access token. Copy both securely.

- Back in Entra ID, go to your AWS Enterprise Application and click the Provisioning tab.

- Set the Provisioning Mode to Automatic.

- Under Admin Credentials, paste the Tenant URL (the SCIM endpoint) and the Secret Token (the Access token) you got from AWS.

- Click Test Connection (it should succeed), save, and then toggle the Provisioning Status to On.

## For Interviews

I eliminated the traditional Bastion host to reduce the public attack surface. Instead, the infrastructure relies on AWS Systems Manager (SSM).
In this project, EC2 instances are provisioned in strictly private subnets with IAM instance profiles allowing SSM connections. 
In an enterprise environment, engineers would authenticate via corporate SSO, assume a role with SSM permissions, 
and securely tunnel into the instances without ever exposing port 22 or managing physical SSH keys.


# How to access jenkins and nexus ddeployed in private subnet

## SSH port forwarding

I'll be using a ssh tunnel in gitbash and map a empty port on my pc to private port of jenkins/nexus using bastion as bridge

1. To Access Jenkins (Private Port 8080)
```Bash
ssh -i "your-key.pem" -L 9090:JENKINS_PRIVATE_IP:8080 ubuntu@BASTION_PUBLIC_IP -N
```
- Then go to chrome and `http://localhost:9090`
2. To Access Nexus (Private Port 8081)
```Bash
ssh -i "your-key.pem" -L 9091:NEXUS_PRIVATE_IP:8081 ubuntu@BASTION_PUBLIC_IP -N
```
- Then go to chrome and `http://localhost:8081`
3. To Access Sonarqube (Private Port 9000)
```Bash
ssh -i "your-key.pem" -L 9092:SONARQUBE_PRIVATE_IP:9000 ubuntu@BASTION_PUBLIC_IP -N
```
- Then go to chrome and `http://localhost:9092`


Breaking Down What the Flags Mean:
`-L 9090:JENKINS_PRIVATE_IP:8080` : This is the magic flag. It says: "Take port 9090 on my laptop, and forward whatever hits it to JENKINS_PRIVATE_IP:8080 via the Bastion connection."

`-N` : This tells SSH not to open an interactive terminal shell. It tells it to just sit there quietly and hold the tunnel open.

As long as that Git Bash window stays open, your tunnel is alive. You go to localhost:9090 for Jenkins, and localhost:9091 for Nexus. The moment you press Ctrl + C in your terminal, the tunnel snaps shut, and the private instances are completely isolated from the world again.

## For troubleshooting
```bash
eval $(ssh-agent -s) # load your keys into CLI's memeory
ssh-add bastion.pem
ssh-add nexus/jenkins.pem

# Jump through the Bastion straight to the private Nexus IP
ssh -A -i bastion.pem ubuntu@bastion_ip # -A : Enables authentication agent forwarding. This allows the remote server to use your local SSH agent (ssh-agent) to authenticate you onto subsequent machines (like a jump host or bastion) without copying your private keys to the intermediate server.
# -a: Disables authentication agent forwarding. This explicitly prevents your local SSH agent from being passed to the remote machine, protecting your keys if the remote server is compromised.

# Once inside the Bastion, hop directly onto the new Nexus private IP:
ssh ubuntu@nexus_ip
```

# To route traffic to the dashboards hosted on EKS

Because *.portfolio.local is not a real domain on the internet, web browser will not know how to find it.

## 1. Find your AWS LoadBalancer URL
After running  bootstrap.sh script, execute:

```Bash
kubectl get svc -n ingress-nginx
Copy the long EXTERNAL-IP string provided by AWS (e.g., a123bc...amazonaws.com).
```

## 2. Find the underlying IP Address
Run a simple ping to grab the active IP behind that load balancer:

```Bash
ping a123bc...amazonaws.com
(Copy the resolved IP address, for example: 54.210.43.5)
```

## 3. Update your local machine's Host file
Open your local computer's host configuration file (/etc/hosts on Linux/Mac, or C:\Windows\System32\drivers\etc\hosts on Windows) with administrative privileges, and append this line:

```Bash
54.210.43.5  grafana.portfolio.local kibana.portfolio.local argocd.portfolio.local
```
Now, when you type http://argocd.portfolio.local directly into your browser your computer will bypass public DNS registries, hit your AWS Load Balancer, flow through your ingress-nginx controller, and bring up your UI dashboards.