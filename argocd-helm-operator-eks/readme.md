This is for testing deployment to argocd with Operator helm on EKS <br/>

### 1. Prerequisite:
- Create self cert for domain: auth.keycloak.me with openssl:
```
openssl genrsa -out my-aws-private.key 2048
# With SAN (recommended)
cat > openssl.cnf <<'EOF'
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[ dn ]
C = VN
ST = HN
L = HN
O = VNB
CN = auth.keycloak.me

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = auth.keycloak.me
EOF

openssl req -new -x509 -nodes -sha256 -days 3650 \
  -key my-aws-private.key \
  -out my-aws-public.crt \
  -config openssl.cnf

openssl pkcs12 -export \
  -inkey my-aws-private.key \
  -in my-aws-public.crt \
  -out my-aws-public.p12 \
  -name "keycloak"
```
- Import cert to AWS ACM to use for offload cert on ALB later:
```
aws acm import-certificate \
  --certificate fileb://my-aws-public.crt \
  --private-key fileb://my-aws-private.key \
  --region us-east-1

```
- Create AWS RDS, get endpoint to update to db-url on values.yaml files. After create RDS mariadb, you should run mysql command to create DB instances with name: keycloakdbrds.
- Create namespace: keycloak
- Create Secret and apply it to namespace keycloak or use another way to mount secret for db
```
apiVersion: v1
kind: Secret
metadata:
  name: keycloak-db-secret
  namespace: keycloak
type: Opaque
stringData:
  db-username: admin
  db-password: admin***
  db-name: keycloakdbrds
```
### 2. Modify values files: Keycloak Opreate + Keycloak Deployment if needed
> 2.1. Keycloak Operator:
```
+ keycloakImage
+ replicas
+ resources

```
> 2.2. Keycloak Deployment:
```
+ replicas
+ resources, startupProbe
+ db: vendor, url, pool
db:
    vendor: mariadb
    host: database-1.c6royoums8vm.us-east-1.rds.amazonaws.com              # Get endpoint from AWS RDS mariadb
    port: 3306
    database: keycloakdbrds
    usernameSecret:
      name: keycloak-db-secret
      key: db-username
    passwordSecret:
      name: keycloak-db-secret
      key: db-password
    url: "jdbc:mariadb://database-1.c6royoums8vm.us-east-1.rds.amazonaws.com:3306/keycloakdbrds"
    pool:
      enabled: true
      init: 1
      min: 5
      max: 10

```
### 3. Run argocd: 2 options to execute
> Option 1: using Command line:
```
argocd app create keycloak \
  --repo https://github.com/duykhanh2104/keycloak_vnb.git \
  --path argocd_keycloak \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace keycloak \
  --sync-policy automated \
  --sync-option CreateNamespace=true \
  --grpc-web
```

> Option 2: Run manifest: review params before run:
```
kubectl apply -n argocd -f "./others/manifests/appset-dev.yaml"

# to check it:
kubectl get applicationsets -n argocd
kubectl get applications -n argocd
```

### Check helm:
```
# to check syntax:
helm lint

# to render helm template
helm template ./
```

### Capture screen:
<img width="1472" height="1252" alt="image" src="https://github.com/user-attachments/assets/692eb0d4-bdbc-483c-b15a-ea4bc643c29c" />
<img width="1471" height="654" alt="image" src="https://github.com/user-attachments/assets/2f87ea40-eed1-494f-9723-775caa4da5cc" />
<img width="1464" height="657" alt="image" src="https://github.com/user-attachments/assets/9c29e48b-9b50-45cc-9cf4-94616afebf0d" />
<img width="1467" height="1027" alt="image" src="https://github.com/user-attachments/assets/60d610a6-abb6-4c0a-ba22-e40f4d214302" />



