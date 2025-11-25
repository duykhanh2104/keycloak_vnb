### 1. Setup K3s:
curl -sfL https://get.k3s.io | sh -
#### After K3s setup done will have:
- kubeconfig: /etc/rancher/k3s/k3s.yaml <br>
- binary: /usr/local/bin/k3s

#### setup kube config:
> mkdir -p ~/.kube
> sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
> sudo chown $(id -u):$(id -g) ~/.kube/config
> chmod 600 ~/.kube/config
> export KUBECONFIG=$HOME/.kube/config
> kubectl get nodes -o wide
> kubectl get pods -A
> kubectl get pods --all-namespaces

### 2. Setup Keycloak Operator
### Create local storage for postgres data
  > mkdir -p /home/ec2-user/data/postgres-keycloak <br>
  > chown 999:999 data/postgres-keycloak/
### File yaml: postgres-keycloak.yaml, postgres-pv-pvc.yaml, keycloak-nodeport.yaml, keycloak-instance.yaml

### setup manual without OLM keycloak operator:
  > kubectl create namespace keycloak <br>
  > kubectl config set-context --current --namespace keycloak

### setup CRD: 
Install the CRDs by following commands <https://www.keycloak.org/operator/installation> 

  > kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.5/kubernetes/keycloaks.k8s.keycloak.org-v1.yml <br>
  > #### can use: kubectl apply -f file crd.yaml <br>
  
  > kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.5/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml  <br>
  > #### can use kubectl apply -f crdimport.yaml

### deployment keycloak operator to namespace
  > ref link: kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.5/kubernetes/kubernetes.yml <br>
  > #### kubectl apply -f keycloak-operator.yaml

### create PV to mapping local host path
  > kubectl apply -f postgres-pv-pvc.yaml

### create db postgres
  > kubectl apply -f postgres-keycloak.yaml

### create keycloak instance
  > kubectl apply -f keycloak-instance.yaml

Use Keycloak Operator to create Keycloak instance pointed to this DB:<br>
• Namespace: keycloak <br>
• Postgres service: postgres-db.keycloak.svc.cluster.local:5432 <br>
• DB: keycloak <br>
• User/pass: keycloak/password <br>

### Use nodeport or ingress to public page keycloak admin page:
  > kubectl apply -f keycloak-nodeport.yaml

### Link access:
> http://34.225.67.85:30080/

### Get user/pw:
  > kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 --decode; echo
### Get password:
  > kubectl -n keycloak get secret keycloak-initial-admin   -o jsonpath='{.data.password}' | base64 --decode; echo

