# High Performace web server

Just testing concepts.  
1. How to start kafka check [here](./infra/README.md)  
2. Launch page-builder using chart: `chart install ./charts/page-builder`
3. Launch stream-web-server using chart: `chart install ./charts/stream-web-server`
4. Chart is not building apps from sources. In case you ned to change something build docker image, push it, add your set of values and override docker image location for charts, use charts with your variables.
5. open `http://127.0.0.1:8080` in your browser.

Docker containers for this project:  
https://hub.docker.com/repository/docker/dkurilo/stream-web-server  
https://hub.docker.com/repository/docker/dkurilo/page-builder

Useful links:  
https://www.youtube.com/watch?v=y8C7TDJWPg4  
https://denibertovic.com/talks/k8s-haskell-webinar/  
https://github.com/fpco/haskell-multi-docker-example/  
https://github.com/haskell-works/hw-kafka-client  
