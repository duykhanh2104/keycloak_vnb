### Notes:
- Use only for import realm 1st time
- Use to manual add users via manifest yaml files (on dev)

### Add users/role/groups to values.yaml: 
- To import manual users to KC, you can modify values.yaml to add users for the first time only. Because users, role, policy bind to Realm, if Realm name exists, it can't to import.

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

### deploy to argocd
#### Option 1: using cmd:
```
  argocd app create keycloak-realm-import \
  --repo https://github.com/duykhanh2104/keycloak_vnb.git \
  --path argocd-realmImport \
  --dest-server https://1A1BE5EB269CCA0C00A4ACE5B454408F.gr7.us-east-1.eks.amazonaws.com \
  --dest-namespace keycloak \
  --values values.yaml
```
- Click sync to deploy:
  <img width="986" height="443" alt="image" src="https://github.com/user-attachments/assets/e374b2f3-83ca-4bcf-a275-1c13dd71a083" />

  #### Option 2: using manifest:
  
