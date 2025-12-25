This guide is for deployment keycloak operator 26.4.5 version on eks:<br>
- Apply crd (custom resource definition) for operator<br>
- Update values: **[endpoint_rds_address]** to db value in **03-keycloak-deployment.yaml** <br>
- Update values: **[aws cert arn]** for alb-ingress in **05-alb-ingress.yaml** <br/>
<br>
Notes: <br>
- For cert: If you dont have cert, you can use openssl to generate key.pem, key and add it to AWS Certificate manager, the ALB needs cert imported to offload at ALB https side. <br>
- The topo: Client > ALB https listen(offload cert) > target group( port 80) > keycloak_pods <br>
- Before apply yaml files, should prequisited: provision eks, provision maria db: 10.11.10 <br>
then create db with name **[keycloakdbrds]**, update value **[username/password]** to **01.secret-db.yaml**<br>
