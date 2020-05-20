cd C:\normallog
docker build -t rdilip83/normallogger:v10 .
docker push rdilip83/normallogger:v10

cd c:\jsonlog
docker build -t rdilip83/jsonlogger:v11 .
docker push rdilip83/jsonlogger:v11
kd C:\jsonlog\nodejsonlogdeployment.yaml
ka C:\jsonlog\nodejsonlogdeployment.yaml

