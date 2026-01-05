This is for testing deployment to argocd with Operator helm on EKS <br/>

### Prerequisite:
- Create namespace
- Create Secret:
```
apiVersion: v1
kind: Secret
metadata:
  name: keycloak-db-secret
  namespace: keycloak
type: Opaque
stringData:
  db-username: postgres
  db-password: postgres
  db-name: keycloakdbrds
```
- Modify values files: Keycloak Opreate + Keycloak Deployment
```
+ keycloakImage
+ resources
+ db: vendor, url
```

### Run argocd: 2 options to execute
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
  
