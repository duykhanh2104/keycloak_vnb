This guide is for deployment keycloak operator 26.4.5 version on eks:
-Apply crd (custom resource definition) for operator
-Update values: **endpoint_rds_address** to db value in 03-keycloak-deployment.yaml 
-Update values: **aws cert arn** for alb-ingress in 05-alb-ingress.yaml <br/>
<br>
Notes: <br>
-For cert: If you dont have cert, you can use openssl to generate key.pem, key and add it to AWS Certificate manager, the ALB needs cert imported to offload at ALB https side. 
-The topo: Client > ALB https listen(offload cert) > target group( port 80) > keycloak_pods
