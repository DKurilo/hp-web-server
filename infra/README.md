# Log

## Start kubernetes cluster in Docker

It's easy part. Just open Docker Desktop preferences/Kubernetes and check in eneble Kubernetes checkbox.  
Now you have kubernetes cluster running.

## Install MetalLB

By default kubernetes cluster can't start LoadBalancer and we need it to work with Kafka broker. So we need to install one.  
To do it open [MetalLB site](https://metallb.universe.tf/installation/) and install MetalLB. I used:  
```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
```

## Create YAML files with configuration

In the current derectory there are four files.  
1. `zookeper.yml` to start zookeeper. Kafka needs zookeeper as underlying service.
2. `layer2-dockerce.yml` configuration for metallb. I found this configuration on [this site](https://medium.com/@JockDaRock/kubernetes-metal-lb-for-docker-for-mac-windows-in-10-minutes-23e22f54d1c8). This article contains one [response](https://medium.com/p/23e22f54d1c8/responses/show) and this response is very important.
3. `kafka-service.yml` contains service for kafka, it has type `LoadBalancer` we want to use.
4. `kafka-broker.yml` contains description for kafka broker that should be started.

Config files I found [here](https://dzone.com/articles/ultimate-guide-to-installing-kafka-docker-on-kuber) it's slightly outdated but still good.

## Instal `kafkacat`

```
brew install kafkacat
```
It's just tool that allow you to work with kafka before you have your application.

## Starting everything

1. in case you have MacBook allow to use `127.0.0.240` with
```
sudo ifconfig lo0 alias 127.0.0.240 up
```
[More about it.](https://superuser.com/questions/458875/how-do-you-get-loopback-addresses-other-than-127-0-0-1-to-work-on-os-x)  
1. start metallb config
```
kubectl apply -f ./layer2-dockerce.yml
```
2. start zookeeper
```
kubectl apply -f ./zookeeper.yml
```
3. start kafka service
```
kubectl apply -f ./kafka-service.yml
```
4. start kafka broker
```
kubectl apply -f ./kafka-broker.yml
```
5. test it with `kafkacat`
In a first terminal we are running consumer:
```
kafkacat -L -b 127.0.0.1:9092 -t topic-test -C
```
In a second terminal we are running producer:
```
echo 'Hello Kafka!' | kafkacat -b 127.0.0.1 -t topic-test -P
```
You should see `Hello Kafka!` in the first terminal with consumer.

That's it. We are ready to develop some interesting things.

# Links

https://github.com/wurstmeister/kafka-docker  
https://github.com/edenhill/kafkacat  
https://dzone.com/articles/ultimate-guide-to-installing-kafka-docker-on-kuber  
https://kubernetes.io/docs/reference/kubectl/cheatsheet/  
https://kafka.apache.org/documentation/  
