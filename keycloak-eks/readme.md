#### Build up EKS cluster
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws --version

Setup kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.2/2025-11-13/bin/linux/amd64/kubectl
chmod +x kubectl

sudo mv kubectl /usr/local/bin/
kubectl version


curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin/
eksctl version

Create IAM role attach to ec2, IAM user should have access to IAM, EC2, and CloudFormation:
As mentioned earlier we need to provide the IAM user access to EC2, Cloudformation, and IAM, however, for the sake of this demo, we will provide full Administrative Access to the User(which is recommended in real-world scenarios):

After creating the role we need to add this role to our Bootstrap EC2 Instance:


Create cluster eks: 
> eksctl create cluster --name eks-cluster-demo --region us-east-1 --node-type t3a.large

> eksctl create cluster --name my-demo-cluster --region us-east-1 --node-type t3.small --nodes-min 1 --nodes-max 3 --nodes 2

eksctl get cluster --region us-east-1
NAME            REGION          EKSCTL CREATED
my-eks-cluster  us-east-1       True

-Aws dung cloudformation de tao, co the xem trang thai bang log output hoac stacks cloudformation: est 20mins

kubectl get nodes
kubectl get all

-Create a Pod using Kubectl to Validate the Cluster
kubectl run webapp --image=httpd
kubectl get pods

kubectl create deployment demo-nginx --image=nginx --replicas=2 --port=80

-Let’s now expose this application to the external network by using the command
kubectl expose deployment demo-nginx --port=80 --type=LoadBalancer

Enable autocomplete:
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
echo 'source /etc/bash_completion.d/kubectl' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
source ~/.bashrc

-----------
To remove resource:
eksctl delete cluster my-eks-cluster --region us-east-1

#lenh de terminate node:
kubectl cordon ip-192-168-19-197.ec2.internal
kubectl drain ip-192-168-19-197.ec2.internal --ignore-daemonsets --delete-emptydir-data --force
aws ec2 terminate-instances --instance-ids i-08159985cdd0ff274


#### Install EBS CSI Driver
https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html

1. Open the Amazon EKS console.
2. In the left pane, select Clusters, and then select the name of your cluster on the Clusters page.
3. In the Details section on the Overview tab, note the value of the OpenID Connect provider URL.
4. Open the IAM console at  https://console.aws.amazon.com/iam/.
5. In the left navigation pane, choose Identity Providers under Access management. If a Provider is listed that matches the URL for your cluster, then you already have a provider for your cluster. If a provider isn’t listed that matches the URL for your cluster, then you must create one.
6. To create a provider, choose Add provider.
7. For Provider type, select OpenID Connect.
8. For Provider URL, enter the OIDC provider URL for your cluster.
9. For Audience, enter sts.amazonaws.com.
10. (Optional) Add any tags, for example a tag to identify which cluster is for this provider.
11. Choose Add provider.

https://oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxxx

-Assign IAM roles to Kubernetes service accounts
>eksctl create iamserviceaccount --name my-service-account --namespace default --cluster my-eks-cluster --role-name my-role     --attach-policy-arn arn:aws:iam::$AWS_Account_id:policy/my-policy --approve --region=us-east-1


-Create and associate role (AWS CLI)
From <https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html> 

-Query OIDC cho cluster 
>aws eks describe-cluster --region us-east-1 --name eks-cluster-demo --query "cluster.identity.oidc.issuer"
Output: "https://oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxx"

>eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster eks-cluster-demo --approve
IAM Open ID Connect provider is already associated with cluster "my-eks-cluster" in "us-east-1"

-Create IAM role for service account ebs-scsi-controller and Assign policy AmaazonEBSCSIDriverPolicy:
aws iam create-role --role-name AmazonEBSCSIDriverRole --assume-role-policy-document file://ebscsiControoler-trust-relationship.json
{
    "Role": {
        "Path": "/",
        "RoleName": "AmazonEBSCSIDriverRole",
        "RoleId": "AROAVPEYV3ZFA5OMIF2H2",
        "Arn": "arn:aws:iam::$AWS_Account_Id:role/AmazonEBSCSIDriverRole",
        "CreateDate": "2025-12-09T01:54:25+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Federated": "arn:aws:iam::$AWS_Account_Id:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxxxxxxxxxxxxxxxx"
                    },
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            "oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxxxxxxxxxxxxxxxx:aud": "sts.amazonaws.com",
                            "oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxxxxxxxxxxxxxxxx:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
                        }
                    }
                }
            ]
        }
    }
}


>aws iam list-policies --scope AWS --query "Policies[?contains(PolicyName, 'EBS') && contains(PolicyName, 'CSI')].[PolicyName,Arn]" --output table

-----------------------------------------------------------------------------------------------------------------------
|                                                    ListPolicies                                                     |
+---------------------------------------+-----------------------------------------------------------------------------+
|  AmazonEBSCSIDriverPolicy             |  arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy              |
|  ROSAAmazonEBSCSIDriverOperatorPolicy |  arn:aws:iam::aws:policy/service-role/ROSAAmazonEBSCSIDriverOperatorPolicy  |
+---------------------------------------+-----------------------------------------------------------------------------+


-Permission json:
aws iam attach-role-policy --role-name AmazonEBSCSIDriverRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

-Bind the role to Service account:
eksctl create iamserviceaccount   --cluster eks-cluster-demo   --namespace kube-system   --name ebs-csi-controller-sa   --attach-policy-arn arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy   --approve --region us-east-1

-Create IRSA:
>eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster eks-cluster-demo --role-name AmazonEKS_EBS_CSI_DriverRole --role-only --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve --region us-east-1

>eksctl get iamserviceaccount --cluster eks-cluster-demo --region us-east-1
NAMESPACE       NAME                    ROLE ARN
kube-system     ebs-csi-controller-sa   arn:aws:iam::$AWS_Account_Id:role/AmazonEKS_EBS_CSI_DriverRole

Ref: https://velog.io/@rockwellvinca/EKS-AWS-EBS-CSI-Driver-%EC%84%A4%EC%B9%98-%EB%B0%8F-%EA%B5%AC%EC%84%B1

-Setup addon:
eksctl create addon --name aws-ebs-csi-driver --cluster eks-cluster-demo --service-account-role-arn arn:aws:iam::$AWS_Account_Id:role/AmazonEKS_EBS_CSI_DriverRole --force --region us-east-1

kubectl get sa -n kube-system | grep ebs
ebs-csi-controller-sa                         0         43s
ebs-csi-node-sa                               0         43s

eksctl get addon --cluster eks-cluster-demo --region us-east-1
2025-12-10 02:21:30 [ℹ]  Kubernetes version "1.32" in use by cluster "eks-cluster-demo"
2025-12-10 02:21:30 [ℹ]  getting all addons
2025-12-10 02:21:33 [ℹ]  to see issues for an addon run `eksctl get addon --name <addon-name> --cluster <cluster-name>`
NAME                    VERSION                 STATUS  ISSUES  IAMROLE                                                         UPDATE AVAILABLE                                    CONFIGURATION VALUES     NAMESPACE       POD IDENTITY ASSOCIATION ROLES
aws-ebs-csi-driver      v1.53.0-eksbuild.1      ACTIVE  0       arn:aws:iam::$AWS_Account_Id:role/AmazonEKS_EBS_CSI_DriverRole                                                         kube-system
coredns                 v1.11.4-eksbuild.2      ACTIVE  0                                                                       v1.11.4-eksbuild.24,v1.11.4-eksbuild.22,v1.11.4-eksbuild.20,v1.11.4-eksbuild.14,v1.11.4-eksbuild.10                          kube-system
kube-proxy              v1.32.6-eksbuild.12     ACTIVE  0                                                                       v1.32.9-eksbuild.2                                  kube-system
metrics-server          v0.8.0-eksbuild.5       ACTIVE  0                                                                                                                           kube-system
vpc-cni                 v1.20.4-eksbuild.2      ACTIVE  0                                                                       v1.20.5-eksbuild.1,v1.20.4-eksbuild.3               kube-system


-----------------------


#### Install AWS LB Controller
Ref AWS LB Controller: https://velog.io/@rockwellvinca/EKS-AWS-Load-Balancer-Controller-%EB%B6%80%ED%95%98%EB%B6%84%EC%82%B0-%ED%99%98%EA%B2%BD

AWS Load Balancer Controller has two main roles.
First , it has the role of provisioning and managing AWS ELB, and
second , it interacts with the control plane of AWS EKS Cluster to check pod information and confirm events.

1.Create an IAM policy
2.Create an IAM Role (attach an IAM policy + attach the cluster's OIDC to the trust relationship policy)
3.Create a Service Account by granting an IAM Role to the Service Account (IRSA process)
4.Install the AWS Load Balancer Controller by adding an IRSA Service Account.

IP mode causes the AWS load balancer to forward traffic directly to the pod IP address. This means that traffic is forwarded directly to the IP address of the service backend, rather than through kube-proxy on individual EC2 worker nodes.
<img width="1218" height="839" alt="image" src="https://github.com/user-attachments/assets/5095314e-891d-47ec-8daf-10488dd80a4a" />

-Download json file aws lb controller:
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.3/docs/install/iam_policy.json
1.Create IAM Policy
>aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy  --policy-document file://iam_policy.json
2.Create IAM Role
3.Crete IRSA
>eksctl create iamserviceaccount --cluster eks-cluster-demo --namespace kube-system --name aws-load-balancer-controller  --role-name AmazonEKS_LoadBalancerControllerRole --attach-policy-arn arn:aws:iam::$AWS_Account_id:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve --region us-east-1

>eksctl get iamserviceaccount --cluster eks-cluster-demo --region us-east-1
NAMESPACE       NAME                            ROLE ARN
kube-system     aws-load-balancer-controller    arn:aws:iam::$AWS_Account_id:role/eksctl-eks-cluster-demo-addon-iamserviceaccou-Role1-c2HcHuD6CpiM
kube-system     ebs-csi-controller-sa           arn:aws:iam::$AWS_Account_id:role/AmazonEKS_EBS_CSI_DriverRole

kubectl get serviceaccounts -n kube-system aws-load-balancer-controller -o yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::$AWS_Account_id:role/eksctl-eks-cluster-demo-addon-iamserviceaccou-Role1-c2HcHuD6CpiM
  creationTimestamp: "2025-12-10T02:56:54Z"
  labels:
    app.kubernetes.io/managed-by: eksctl
  name: aws-load-balancer-controller
  namespace: kube-system
  resourceVersion: "****"
  uid: fe0**********

2. aws iam attach-role-policy --role-name eksctl-eks-cluster-demo-addon-iamserviceaccou-Role1-c2HcHuD6CpiM --policy-arn arn:aws:iam::$AWS_Account_id:policy/AWSLoadBalancerControllerIAMPolicy

kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.13.5/cert-manager.yaml

Huong dan: https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/lbc-manifest.html
curl -Lo v2_13_3_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.13.3/v2_13_3_full.yaml
sed -i.bak -e '730,738d' ./v2_13_3_full.yaml
sed -i.bak -e 's|your-cluster-name|eks-cluster-demo|' ./v2_13_3_full.yaml
kubectl apply -f v2_13_3_full.yaml
curl -Lo v2_13_3_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.13.3/v2_13_3_ingclass.yaml

kubectl apply -f v2_13_3_ingclass.yaml
kubectl get deployment -n kube-system aws-load-balancer-controller


kubectl -n keycloak get ingress keycloak-ingress
NAME               CLASS   HOSTS              ADDRESS   PORTS   AGE
keycloak-ingress   alb     auth.keycloak.me             80      132m

• kubectl -n kube-system logs deploy/aws-load-balancer-controller --tail=200

Fix loi ko co address ingress:
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
Cap  nhat lai file json
aws iam attach-role-policy --role-name eksctl-eks-cluster-demo-addon-iamserviceaccou-Role1-c2HcHuD6CpiM --policy-arn arn:aws:iam::$AWS_Account_id:policy/AWSLoadBalancerControllerIAMPolicy

kubectl -n keycloak delete ingress keycloak-ingress
kubectl apply -f 08-alb-svc.yaml

kubectl -n keycloak get ingress keycloak-ingress
NAME               CLASS   HOSTS              ADDRESS                                                                   PORTS   AGE
keycloak-ingress   alb     auth.keycloak.me   k8s-keycloak-keycloak-*********************.us-east-1.elb.amazonaws.com   80      3m21s



kubectl -n keycloak exec -it keycloak-0 -c keycloak -- /opt/keycloak/bin/kc.sh show-config
Current Mode: production
Current Configuration:
        kc.health-enabled =  true (ENV)
        kc.bootstrap-admin-password =  ******* (ENV)
        kc.db-username =  keycloakadminsql (ENV)
        kc.db-url-database =  keycloakdb (ENV)
        kc.spi-cache-embedded-default-machine-name =  ip-192-168-4-205.ec2.internal (ENV)
        kc.log-level-org.infinispan.transaction.lookup.JBossStandaloneJTAManagerLookup =  null (Derived)
        kc.log-level-io.quarkus.config =  null (Derived)
        kc.hostname =  auth.keycloak.me (ENV)
        kc.log-console-output =  default (classpath application.properties)
        kc.https-port =  8443 (ENV)
        kc.spi-hostname-default-ssl-required =  NONE (ENV)
        kc.bootstrap-admin-username =  temp-admin (ENV)
        kc.log-level-io.quarkus.hibernate.orm.deployment.HibernateOrmProcessor =  null (Derived)
        kc.db =  postgres (ENV)
        kc.log-level-liquibase.database.core.PostgresDatabase =  null (Derived)
        kc.version =  26.4.5 (SysPropConfigSource)
        kc.truststore-paths =  /var/run/secrets/kubernetes.io/serviceaccount/ca.crt (ENV)
        kc.log-level-org.jboss.resteasy.resteasy_jaxrs.i18n =  null (Derived)
        kc.log-level-io.quarkus.arc.processor.BeanArchives =  null (Derived)
        kc.cache =  ispn (ENV)
        kc.db-url-host =  postgres-db (ENV)
        kc.log-level-io.quarkus.deployment.steps.ReflectiveHierarchyStep =  null (Derived)
        kc.db-password =  ******* (ENV)
        kc.http-port =  8080 (ENV)
        kc.proxy-headers-forwarded =  xforwarded (ENV)
        kc.http-enabled =  true (ENV)
        kc.log-level-org.hibernate.SQL_SLOW =  null (Derived)
        kc.hostname-strict-backchannel =  false (ENV)
        kc.log-level-io.quarkus.arc.processor.IndexClassLookupUtils =  null (Derived)
        kc.db-url-port =  5432 (ENV)
        kc.hostname-strict =  false (ENV)
        kc.log-level-org.hibernate.engine.jdbc.spi.SqlExceptionHelper =  null (Derived)
        kc.run-in-container =  true (ENV)
kubectl -n keycloak logs keycloak-0 -c keycloak --tail=300 --follow
kubectl -n keycloak get ingress --> lay thong tin ELB cua AWS

nslookup k8s-keycloak-keycloak-***************************.us-east-1.elb.amazonaws.com --> add 2 IP vao host etc de test tam


https://k8s-keycloak-keycloak-***************************.us-east-1.elb.amazonaws.com/

kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d; echo
kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d; echo
<img width="2070" height="2551" alt="image" src="https://github.com/user-attachments/assets/ba9cf867-75f6-4f6d-aa33-f24da265940b" />


#### Keycloak setup
