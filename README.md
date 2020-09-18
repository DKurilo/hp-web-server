# High Performace web server

Just testing concepts.  
1. How to start kafka check [here](./infra/README.md)  
2. Install Metric Server that allows to read cpu data for horizontal autoscaler
  1. `helm repo add stable https://kubernetes-charts.storage.googleapis.com`
  2. `helm repo update`
  1. `helm install my-metrics-server --set "args={--kubelet-insecure-tls, --kubelet-preferred-address-types=InternalIP, --v=2}" stable/metrics-server --namespace kube-system`
3. Launch page-builder using helm: `helm install ./charts/page-builder --generate-name`
4. Launch stream-web-server using helm: `helm install ./charts/stream-web-server --generate-name`
5. Helm is not building apps from sources. In case you need to change something build docker image, push it, add your set of values and override docker image location for charts, use helm with your variables.
6. open `http://127.0.0.1:8080` in your browser.

Docker containers for this project:  
https://hub.docker.com/repository/docker/dkurilo/stream-web-server  
https://hub.docker.com/repository/docker/dkurilo/page-builder

Useful links:  
https://www.youtube.com/watch?v=y8C7TDJWPg4  
https://denibertovic.com/talks/k8s-haskell-webinar/  
https://github.com/fpco/haskell-multi-docker-example/  
https://github.com/haskell-works/hw-kafka-client  

Sometimes kafka doesn't create builder topic properly. To change it connect to kafka docker container and use commands:  
`kafka-topics.sh --describe --zookeeper $KAFKA_ZOOKEEPER_CONNECT` to check topics  
`kafka-topics.sh --alter --topic builder --partitions 10 --zookeeper $KAFKA_ZOOKEEPER_CONNECT` to change topic
