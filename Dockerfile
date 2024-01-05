FROM ubuntu:22.04

RUN apt update && apt install -y curl wget libevent-dev gcc libc6-dev libssl-dev

RUN wget https://downloads.dlang.org/releases/2.x/2.105.3/dmd_2.105.3-0_amd64.deb
RUN dpkg -i dmd_2.105.3-0_amd64.deb && rm -rf dmd_2.105.3-0_amd64.deb

COPY . /app
WORKDIR /app

RUN dub build -b release

EXPOSE 5000
ENTRYPOINT [ "./filemyst" ]
