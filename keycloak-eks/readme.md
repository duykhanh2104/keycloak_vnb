#### Build up EKS cluster
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" <br>
unzip awscliv2.zip <br>
sudo ./aws/install <br>

aws --version <br>

Setup kubectl <br>
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.2/2025-11-13/bin/linux/amd64/kubectl <br>
chmod +x kubectl <br>

sudo mv kubectl /usr/local/bin/ <br>
kubectl version <br>
 

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp <br>

sudo mv /tmp/eksctl /usr/local/bin/ <br>
eksctl version <br>

Create IAM role attach to ec2, IAM user should have access to IAM, EC2, and CloudFormation: <br>
As mentioned earlier we need to provide the IAM user access to EC2, Cloudformation, and IAM, however, for the sake of this demo, we will provide full Administrative Access to the User(which is recommended in real-world scenarios): <br>

After creating the role we need to add this role to our Bootstrap EC2 Instance: <br>


Create cluster eks: <br>
> eksctl create cluster --name eks-cluster-demo --region us-east-1 --node-type t3a.large

> eksctl create cluster --name my-demo-cluster --region us-east-1 --node-type t3.small --nodes-min 1 --nodes-max 3 --nodes 2

eksctl get cluster --region us-east-1 <br>
NAME            REGION          EKSCTL CREATED <br>
my-eks-cluster  us-east-1       True <br>

-Aws dung cloudformation de tao, co the xem trang thai bang log output hoac stacks cloudformation: est 20mins

kubectl get nodes <br>
kubectl get all <br>

-Create a Pod using Kubectl to Validate the Cluster
kubectl run webapp --image=httpd <br>
kubectl get pods <br>

kubectl create deployment demo-nginx --image=nginx --replicas=2 --port=80  <br>

-Let’s now expose this application to the external network by using the command <br>
kubectl expose deployment demo-nginx --port=80 --type=LoadBalancer <br>

Enable autocomplete: <br>
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null <br>
echo 'source /etc/bash_completion.d/kubectl' >> ~/.bashrc <br> 
echo 'alias k=kubectl' >> ~/.bashrc <br>
source ~/.bashrc <br>

-----------
To remove resource: <br>
eksctl delete cluster my-eks-cluster --region us-east-1 <br>

#lenh de terminate node: <br>
kubectl cordon ip-192-168-19-197.ec2.internal <br>
kubectl drain ip-192-168-19-197.ec2.internal --ignore-daemonsets --delete-emptydir-data --force <br>
aws ec2 terminate-instances --instance-ids i-08159985cdd0ff274 <br>

#### Self cert to aws acm
Ref link: https://medium.com/@chamilad/adding-a-self-signed-ssl-certificate-to-aws-acm-88a123a04301 <br>

>openssl genrsa -out my-aws-private.key 2048
##### With SAN (recommended)
cat > openssl.cnf <<'EOF'
[ req ]<br>
default_bits       = 2048 <br>
prompt             = no<br>
default_md         = sha256<br>
req_extensions     = req_ext<br>
distinguished_name = dn<br>

[ dn ]<br>
C = VN<br>
ST = HN<br>
L = HN<br>
O = VNB<br>
CN = auth.keycloak.me <br>

[ req_ext ] <br>
subjectAltName = @alt_names <br>

[ alt_names ] <br>
DNS.1 = auth.keycloak.me <br>
EOF <br>

>openssl req -new -x509 -nodes -sha256 -days 3650 -key my-aws-private.key -out my-aws-public.crt -config openssl.cnf <br>
>openssl pkcs12 -export -inkey my-aws-private.key -in my-aws-public.crt -out my-aws-public.p12 -name "keycloak" 

>aws acm import-certificate --certificate fileb://my-aws-public.crt --private-key fileb://my-aws-private.key --region us-east-1


#### Install EBS CSI Driver
https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html <br>

1. Open the Amazon EKS console. <br>
2. In the left pane, select Clusters, and then select the name of your cluster on the Clusters page. <br>
3. In the Details section on the Overview tab, note the value of the OpenID Connect provider URL. <br>
4. Open the IAM console at  https://console.aws.amazon.com/iam/. <br>
5. In the left navigation pane, choose Identity Providers under Access management. If a Provider is listed that matches the URL for your cluster, then you already have a provider for your cluster. If a provider isn’t listed that matches the URL for your cluster, then you must create one. <br>
6. To create a provider, choose Add provider. <br>
7. For Provider type, select OpenID Connect. <br>
8. For Provider URL, enter the OIDC provider URL for your cluster. <br>
9. For Audience, enter sts.amazonaws.com. <br>
10. (Optional) Add any tags, for example a tag to identify which cluster is for this provider. <br>
11. Choose Add provider. <br>

https://oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxxx

-Assign IAM roles to Kubernetes service accounts
>eksctl create iamserviceaccount --name my-service-account --namespace default --cluster my-eks-cluster --role-name my-role     --attach-policy-arn arn:aws:iam::$AWS_Account_id:policy/my-policy --approve --region=us-east-1


-Create and associate role (AWS CLI)
From <https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html>  <br>

-Query OIDC cho cluster  
>aws eks describe-cluster --region us-east-1 --name eks-cluster-demo --query "cluster.identity.oidc.issuer"
Output: "https://oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxx" <br>

>eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster eks-cluster-demo --approve
IAM Open ID Connect provider is already associated with cluster "my-eks-cluster" in "us-east-1" <br>

-Create IAM role for service account ebs-scsi-controller and Assign policy AmaazonEBSCSIDriverPolicy:
aws iam create-role --role-name AmazonEBSCSIDriverRole --assume-role-policy-document file://ebscsiControoler-trust-relationship.json <br>
{ <br>
    "Role": { <br>
        "Path": "/", <br>
        "RoleName": "AmazonEBSCSIDriverRole", <br>
        "RoleId": "AROAVPEYV3ZFA5OMIF2H2", <br>
        "Arn": "arn:aws:iam::$AWS_Account_Id:role/AmazonEBSCSIDriverRole", <br>
        "CreateDate": "2025-12-09T01:54:25+00:00", <br>
        "AssumeRolePolicyDocument": { <br>
            "Version": "2012-10-17", <br>
            "Statement": [ <br>
                { <br>
                    "Effect": "Allow", <br>
                    "Principal": { <br>
                        "Federated": "arn:aws:iam::$AWS_Account_Id:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxxxxxxxxxxxxxxxx" <br>
                    }, <br>
                    "Action": "sts:AssumeRoleWithWebIdentity", <br>
                    "Condition": { <br>
                        "StringEquals": { <br>
                            "oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxxxxxxxxxxxxxxxx:aud": "sts.amazonaws.com", <br>
                            "oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxxxxxxxxxxxxxxxx:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa" <br>
                        } <br>
                    } <br>
                }<br>
            ]<br>
        }<br>
    }<br>
}<br>


>aws iam list-policies --scope AWS --query "Policies[?contains(PolicyName, 'EBS') && contains(PolicyName, 'CSI')].[PolicyName,Arn]" --output table

-----------------------------------------------------------------------------------------------------------------------<br>
|                                                    ListPolicies                                                     |<br>
+---------------------------------------+-----------------------------------------------------------------------------+<br>
|  AmazonEBSCSIDriverPolicy             |  arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy              |<br>
|  ROSAAmazonEBSCSIDriverOperatorPolicy |  arn:aws:iam::aws:policy/service-role/ROSAAmazonEBSCSIDriverOperatorPolicy  |<br>
+---------------------------------------+-----------------------------------------------------------------------------+<br>


-Permission json:
>aws iam attach-role-policy --role-name AmazonEBSCSIDriverRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

-Bind the role to Service account:
>eksctl create iamserviceaccount   --cluster eks-cluster-demo   --namespace kube-system   --name ebs-csi-controller-sa   --attach-policy-arn arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy   --approve --region us-east-1

-Create IRSA:
>eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster eks-cluster-demo --role-name AmazonEKS_EBS_CSI_DriverRole --role-only --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve --region us-east-1

>eksctl get iamserviceaccount --cluster eks-cluster-demo --region us-east-1
NAMESPACE       NAME                    ROLE ARN<br>
kube-system     ebs-csi-controller-sa   arn:aws:iam::$AWS_Account_Id:role/AmazonEKS_EBS_CSI_DriverRole<br>

Ref: https://velog.io/@rockwellvinca/EKS-AWS-EBS-CSI-Driver-%EC%84%A4%EC%B9%98-%EB%B0%8F-%EA%B5%AC%EC%84%B1<br>

-Setup addon:
>eksctl create addon --name aws-ebs-csi-driver --cluster eks-cluster-demo --service-account-role-arn arn:aws:iam::$AWS_Account_Id:role/AmazonEKS_EBS_CSI_DriverRole --force --region us-east-1

kubectl get sa -n kube-system | grep ebs<br>
ebs-csi-controller-sa                         0         43s<br>
ebs-csi-node-sa                               0         43s<br>

>eksctl get addon --cluster eks-cluster-demo --region us-east-1
2025-12-10 02:21:30 [ℹ]  Kubernetes version "1.32" in use by cluster "eks-cluster-demo"<br>
2025-12-10 02:21:30 [ℹ]  getting all addons<br>

-----------------------


#### Install AWS LB Controller
Ref AWS LB Controller: https://velog.io/@rockwellvinca/EKS-AWS-Load-Balancer-Controller-%EB%B6%80%ED%95%98%EB%B6%84%EC%82%B0-%ED%99%98%EA%B2%BD<br>

AWS Load Balancer Controller has two main roles.<br>
First , it has the role of provisioning and managing AWS ELB, and<br>
second , it interacts with the control plane of AWS EKS Cluster to check pod information and confirm events.<br>

1.Create an IAM policy<br>
2.Create an IAM Role (attach an IAM policy + attach the cluster's OIDC to the trust relationship policy)<br>
3.Create a Service Account by granting an IAM Role to the Service Account (IRSA process)<br>
4.Install the AWS Load Balancer Controller by adding an IRSA Service Account.<br>

IP mode causes the AWS load balancer to forward traffic directly to the pod IP address. This means that traffic is forwarded directly to the IP address of the service backend, rather than through kube-proxy on individual EC2 worker nodes.<br>
<img width="1218" height="839" alt="image" src="https://github.com/user-attachments/assets/5095314e-891d-47ec-8daf-10488dd80a4a" />

-Download json file aws lb controller:
>curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.3/docs/install/iam_policy.json
1.Create IAM Policy<br>
>aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy  --policy-document file://iam_policy.json
2.Create IAM Role<br>
3.Crete IRSA<br>
>eksctl create iamserviceaccount --cluster eks-cluster-demo --namespace kube-system --name aws-load-balancer-controller  --role-name AmazonEKS_LoadBalancerControllerRole --attach-policy-arn arn:aws:iam::$AWS_Account_id:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve --region us-east-1

>eksctl get iamserviceaccount --cluster eks-cluster-demo --region us-east-1
NAMESPACE       NAME                            ROLE ARN<br>
kube-system     aws-load-balancer-controller    arn:aws:iam::$AWS_Account_id:role/eksctl-eks-cluster-demo-addon-iamserviceaccou-Role1-c2HcHuD6CpiM<br>
kube-system     ebs-csi-controller-sa           arn:aws:iam::$AWS_Account_id:role/AmazonEKS_EBS_CSI_DriverRole<br>

kubectl get serviceaccounts -n kube-system aws-load-balancer-controller -o yaml<br>

2. aws iam attach-role-policy --role-name eksctl-eks-cluster-demo-addon-iamserviceaccou-Role1-c2HcHuD6CpiM --policy-arn arn:aws:iam::$AWS_Account_id:policy/AWSLoadBalancerControllerIAMPolicy

>kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.13.5/cert-manager.yaml

Huong dan: https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/lbc-manifest.html<br>
>curl -Lo v2_13_3_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.13.3/v2_13_3_full.yaml
>sed -i.bak -e '730,738d' ./v2_13_3_full.yaml
>sed -i.bak -e 's|your-cluster-name|eks-cluster-demo|' ./v2_13_3_full.yaml
>kubectl apply -f v2_13_3_full.yaml
>curl -Lo v2_13_3_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.13.3/v2_13_3_ingclass.yaml

>kubectl apply -f v2_13_3_ingclass.yaml
>kubectl get deployment -n kube-system aws-load-balancer-controller


>kubectl -n keycloak get ingress keycloak-ingress
NAME               CLASS   HOSTS              ADDRESS   PORTS   AGE<br>
keycloak-ingress   alb     auth.keycloak.me             80      132m<br>

>kubectl -n kube-system logs deploy/aws-load-balancer-controller --tail=200

-Fix loi ko co address ingress:<br>
>curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
-Cap  nhat lai file json
>aws iam attach-role-policy --role-name eksctl-eks-cluster-demo-addon-iamserviceaccou-Role1-c2HcHuD6CpiM --policy-arn arn:aws:iam::$AWS_Account_id:policy/AWSLoadBalancerControllerIAMPolicy

>kubectl -n keycloak delete ingress keycloak-ingress
>kubectl apply -f 08-alb-svc.yaml

>kubectl -n keycloak get ingress keycloak-ingress
NAME               CLASS   HOSTS              ADDRESS                                                                   PORTS   AGE<br>
keycloak-ingress   alb     auth.keycloak.me   k8s-keycloak-keycloak-*********************.us-east-1.elb.amazonaws.com   80      3m21s<br>

>kubectl -n keycloak exec -it keycloak-0 -c keycloak -- /opt/keycloak/bin/kc.sh show-config

>kubectl -n keycloak logs keycloak-0 -c keycloak --tail=300 --follow
>kubectl -n keycloak get ingress --> lay thong tin ELB cua AWS

>nslookup k8s-keycloak-keycloak-***************************.us-east-1.elb.amazonaws.com --> add 2 IP to host etc to test on local PC
-Link access:
>https://k8s-keycloak-keycloak-***************************.us-east-1.elb.amazonaws.com/

-get user/pass
>kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d; echo
>kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d; echo

#### Keycloak setup
Apply namespace<br>
Apply CRD for keycloak<br>
Apply from 1 - 7 yaml file<br>

