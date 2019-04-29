# lando-nginx-geoip2

A Bitnami based NGINX image with [Maxmind's geoip2 database](https://dev.maxmind.com/geoip/geoip2/geolite2/) support [compiled in](https://github.com/leev/ngx_http_geoip2_module). For use with a local [Lando](https://github.com/lando/lando) set up where you want your test environment to closely match production where you are also using the geoip2 nginx module.

Will allow you to add a query parameter with an IP address for the value which is then searched in the Maxmind database to provide a country code, country name and city name as response headers.

## Setup

You will need to add something like the following to a custom `lando.conf.tpl` file:

```
geoip2 {{NGINX_CONFDIR}}/geoip/GeoLite2-Country.mmdb {
    auto_reload 5m;
    $geoip2_metadata_country_build metadata build_epoch;
    $geoip2_data_country_code default=UK source=$arg_testip country iso_code;
    $geoip2_data_country_name default=England source=$arg_testip country names en;
}

geoip2 {{NGINX_CONFDIR}}/geoip/GeoLite2-City.mmdb {
    $geoip2_data_city_name default=London source=$arg_testip city names en;
}

add_header X-Country-Code      $geoip2_data_country_code;
add_header X-Country-Name      $geoip2_data_country_name;
add_header X-City-Name         $geoip2_data_city_name;
```

The rest of the `lando.conf.tpl` needs to be based off Lando's default one.

You will need to override the default nginx image and include the custom config in your `.lando.yml` file with something like:

```
services:
  appserver_nginx:
    type: nginx
    webroot: web
    config:
      server: lando/nginx.conf.tpl
    overrides:
      image: agilecollective/lando-nginx-geoip2:latest
```

The example above overrides the `appserver_nginx` container produced when using a Drupal recipe with nginx as the webserver.

## Use

With this custom image and the nginx config supplied above the container should add the `X-Country-Code`, `X-Country-Name` and `X-City-Name` headers to HTTP responses. They will default to `UK`, `England` and `London` respectively. Due to this being a local environment nginx won't know what your external IP address so `source=$arg_testip` is used to listen to an query parameter `testip`. For example if you provide an address like `http://mylandosite.lndo.site?testip=82.102.21.70` you should see the following headers:

```
X-City-Name: Milan
X-Country-Code: IT
X-Country-Name: Italy
```

You can modify the `lando.conf.tpl` to use whatever parameter name you want or provide different defaults.
