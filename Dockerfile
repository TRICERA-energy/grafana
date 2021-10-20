FROM node:16-alpine3.12 as plugin-builder

# Update the image and install git as well as go
# Both are needed for cloning and installing the mqtt plugin
RUN apk add --update --no-cache git go

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

WORKDIR /usr/

# Clone and install go mage - needed for the mqtt plugin installation
RUN git clone https://github.com/magefile/mage

WORKDIR /usr/mage/

RUN go run bootstrap.go

WORKDIR /usr/src/app/plugins/

# Clone the mqtt datasource plugin and build it    
RUN git clone https://github.com/Tricera-Hendrik-Weiss/mqtt-datasource.git

WORKDIR /usr/src/app/plugins/mqtt-datasource

RUN yarn install 
RUN yarn build

# Use the latest Grafana version as execution image
FROM grafana/grafana:8.0.4

# Copy the mqtt plugin into the image
COPY --from=plugin-builder /usr/src/app/plugins/mqtt-datasource /var/lib/grafana/plugins/mqtt-datasource

# Provision Grafana (Dashboards, Alerts, Datasources)
COPY ./provisioning/ /etc/grafana/provisioning

# Overwrite default Grafana images - EXPERIMENTAL
COPY ./grafana_icon.svg /usr/share/grafana/public/img