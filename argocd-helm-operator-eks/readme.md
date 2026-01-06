This is for testing deployment to argocd with Operator helm on EKS <br/>

### 1. Prerequisite:
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
- Modify values files: Keycloak Opreate + Keycloak Deployment if needed
> Keycloak Operator:
```
+ keycloakImage
+ replicas
+ resources

```
> Keycloak Deployment:
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
### 2. Run argocd: 2 options to execute
> Command line:
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

> Run manifest:
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

### Optional: 
- To import manual users to KC, you can modify values-realmImport.yaml to add users for the first time only. Because users, role, policy bind to Realm, if Realm name exists, it can't to import. Then execute values-realmImport to add users to db. 
```
# Replace name realm
realmImport:
  enabled: false
  name: demo-realm
  namespace: keycloak
  keycloakCRName: keycloak
  realm: demo1
  enabledFlag: true

  clients:
    - clientId: myclient
      enabled: true
      protocol: openid-connect
      publicClient: true
      directAccessGrantsEnabled: true

  roles:
    realm:
      - name: APP_ADMIN
      - name: APP_USER
    client:
      myclient:
        - name: admin
        - name: user

  groups:
    - name: AAD
      clientRoles:
        myclient:
          - user
    - name: AAA
      clientRoles:
        myclient:
          - admin

  users:
    - username: user1
      enabled: true
      credentials:
        - type: password
          value: secret
          temporary: false
      groups:
        - AAD
    - username: user2
      enabled: true
      credentials:
        - type: password
          value: secret
          temporary: false
      groups:
        - AAD
    - username: user3
      enabled: true
      credentials:
        - type: password
          value: secret
          temporary: false
      groups:
        - AAD
    - username: admin5
      enabled: true
      credentials:
        - type: password
          value: secret
          temporary: false
      groups:
        - AAA
    - username: admin6
      enabled: true
      credentials:
        - type: password
          value: secret
          temporary: false
      groups:
        - AAA
```
  
