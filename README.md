### Purpose  
When configuration requires ssl or testing features for SSL connections and you need to terminate it down to http for your local development for one reason or another.

### How it works  
[TLDR in conclusion](#TLDR)  
Simply build the image using the defaults or provide `--build-arg`'s to populate the `nginx.conf.template` with the address to do ssl termination for.

Possible `--build-arg` arguments:
`--build-arg PROXY_TO_ADDRESS=172.17.0.1`
`--build-arg PROXY_TO_PORT=80`
or
`--build-arg PROXY_TO_FULL_ADDRESS=some-http-address`

###### Ex.
`docker build --build-arg PROXY_TO_PORT=5050 -t local-ssl .`

What happens  
- Pulls `nginx:stable-alpine`, a ~23mb image containing nginx
- Installs `openssl`
- Creates a self-signed certificate
- Copys the `nginx.conf.template` file into the image
- Replaces `PROXY_ADDRESS` in `nginx.conf.template`

Rebuilding the image is pretty much a non-issue so dont worry too much. If you'd like to iterate customizing the nginx template a bit faster you can add `-v "${PWD}/nginx.conf.template":/etc/nginx/templates/nginx.conf.template` to mount the file. You'll need to restart the container for changes to load.  

Next, run the image.  

We're going to map port 4050 on our host machine to our containers port 443.
`docker run --rm -p 4050:443 --name ssl-container local-ssl`

We now have a container running that will receive https connections from port 4050 on the host and connect to 443 inside our container (where our nginx is listening)

Now according to the values in our [build example above](#ex.), when we can make a connection to `https://localhost:4050` (note the https) our connection will be proxied to our http address `http://172.17.0.1:5050` (172.17.0.1 is the default linux docker bridge)

### Gotchas
Make sure the server/service that is handling the request to nginx accepts self-signed certificates.  
In node.js you want to [set the `rejectUnauthorized` setting to false](https://nodejs.org/api/https.html#https_https_request_url_options_callback)

If you're unfamiliar with docker networking it can be fairly confusing even [with documentation](https://docs.docker.com/network/network-tutorial-standalone/). The important thing to note is *inside* the container localhost points to the container itself and *not* the localhost you connect to in the browser. This is why we use the docker brdige network at `172.17.0.1` to connect to services on the host (as long as their listening on the bridge network interface `172.17.0.1` or preferably all interfaces).

If you are familiar with docker networking, you can link containers via docker networks/depends_on and use the containers DNS name instead of 172.17.0.1.


### Why / Inspiration
I've seen little badges like ![this](https://img.shields.io/badge/Sample-Badge-blue) around for while and recently stumbled upon [shields.io](https://shields.io). After some time figuring out how it worked I wanted to test it locally and remotely for private repositories.  

A core issue here is shields.io requires access to the repository or you bring your own json. Luckily they have a docker image ready to be pulled down and setup locally. I found the [json endpoint service](https://shields.io/endpoint) being what I needed.

One problem, their JSON endpoint only works with https endpoints and returns an [invalid badge if you provide a http address endpoint](https://github.com/badges/shields/blob/master/services/endpoint/endpoint.service.js#L64-L66) like ![this](https://img.shields.io/endpoint?url=http%3A%2F%2Flocalhost%2Fjsonendpoint), even with NODE_ENV set to non-production . Thats not very easy to deal with without constantly deploying your WIP endpoint. I ultimately created [this solution](https://gitlab.codeopensrc.com/kc/kc.app.website/-/snippets/24). One since its easier and two, due to the fetching mechanism in the npm `got` package they use has the default [https.get ssl setting `rejectUnauthorized` set to true](https://nodejs.org/api/https.html#https_https_request_url_options_callback) (which is obviously a good idea, just not ideal for development) and rejects self-signed certificates. 

### Conclusion
###### TLDR
Something in your local development requires an outgoing https connection (testing or rare scenario illustrated above) and you have docker available.

`git clone repo.git`
`cd repo`
`docker build --build-arg PROXY_TO_PORT=5050 -t local-ssl .`
`docker run --rm -p 4050:443 --name ssl-container local-ssl`  


|https|
|---|
| Web Browser/Service -> https://localhost:4050 |

|https|
|---|
| https://localhost:4050 -> [ ssl-container:443 ] |

|http|
|---|
| [ ssl-container:443 ] -> http://172.17.0.1:5050 |
