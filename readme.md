# Create local storage for postgres data
  > mkdir -p /home/ec2-user/data/postgres-keycloak
  > chown 999:999 data/postgres-keycloak/
# File yaml: postgres-keycloak.yaml, postgres-pv-pvc.yaml, keycloak-nodeport.yaml, keycloak-instance.yaml

# setup manual without OLM keycloak operator:
  kubectl create namespace keycloak 
  kubectl config set-context --current --namespace keycloak

# setup CRD: 
Install the CRDs by entering the following commands following <https://www.keycloak.org/operator/installation> 

  kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.5/kubernetes/keycloaks.k8s.keycloak.org-v1.yml     #can kubectl apply -f file crd.yaml
  kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.5/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml  # can kubectl apply -f crdimport.yaml

# deployment keycloak operator to namespace
  kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.5/kubernetes/kubernetes.yml # can kubectl apply -f keycloak-operator.yaml

# create PV to mapping local host path
  kubectl apply -f postgres-pv-pvc.yaml

# create db
  kubectl apply -f postgres-keycloak.yaml

# create keycloak instance
  kubectl apply -f keycloak-instance.yaml


Use Keycloak Operator to create Keycloak instance pointed to this DB:
• Namespace: keycloak
• Postgres service: postgres-db.keycloak.svc.cluster.local:5432
• DB: keycloak
• User/pass: keycloak/password

Use nodeport or ingress to public page keycloak admin page:
  kubectl apply -f keycloak-nodeport.yaml

Link access:
http://34.225.67.85:30080/

Get user/pw:
  kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 --decode; echo
Get password:
  kubectl -n keycloak get secret keycloak-initial-admin   -o jsonpath='{.data.password}' | base64 --decode; echo

