### Notes:
- Use only for import realm 1st time
- Use to manual add users via manifest yaml files (on dev)

### Optional: 
- To import manual users to KC, you can modify values.yaml to add users for the first time only. Because users, role, policy bind to Realm, if Realm name exists, it can't to import. Then execute values-realmImport to add users to db. 
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
