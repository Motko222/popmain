path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
cd $path

read -p "Sure? " c
case $c in y|Y) ;; *) exit ;; esac

#create env
cd $path
[ -f env ] || cp env.sample env
nano env

#install script
cd /opt
rm -r popmain
mkdir popmain
cd popmain
curl -L https://pipe.network/p1-cdn/releases/latest/download/pop -o pop
chmod +x pop

cat <<EOF > dockerfile
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y ca-certificates curl libssl-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY pop .
RUN chmod 777 pop
RUN chmod +x ./pop
CMD ["./pop"]
EOF

docker build -t popmain .
