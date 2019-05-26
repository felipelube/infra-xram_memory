- [ ] Sincronizar submódulos
- [ ] Criar volumes e redes
  ```bash
  docker network create web
  docker volume create xram_memory_webadmin_media
  docker volume create xram_memory_webadmin_static
  docker volume create xram_memory_db_data
  docker volume create xram_memory_es1_data
  ```
- [ ] Dar permissão ao usuário www-data nos volumes de arquivos:
  ```bash
  chown 33:33 /var/lib/docker/volumes/xram_memory_webadmin_media/_data/ -R
  chown 33:33 /var/lib/docker/volumes/xram_memory_webadmin_static/_data/ -R
  ```
- [ ] Criar arquivos para variáveis-ambiente
  ```bash
  cp .env.dist .env
  cp backend.env.dist backend.env
  cp contact_message_relay.env.dist contact_message_relay.env
  cp ./proxy/.env.dist ./proxy/.env
  ```
- [ ] Criar arquivos de configuração do ElasticSearch
- [ ] Gerar certificados do Elastic Search
  Ferramenta disponível em: https://docs.search-guard.com/latest/offline-tls-tool

  - [ ] gerar um arquivo de configuração para a ferramenta
  - [ ] executar um container com o java https://hub.docker.com/_/openjdk
    `docker run -it --rm -v <pasta dos certificados>:/root/tools/out openjdk:8 bash`
  2. no container, baixe a ferramenta tls-tool
    `wget <url>`
  3. Gere a autoridade certificadora
    `./sgtlstool.sh -ca -c xram-memory.yml`
  4. Gere os certificados para os nodes
    `./sgtlstool.sh -crt -c xram-memory.yml`
  5. Converta o certificado administrativo para o formato PKCS#8
    `openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./out/kirk.key -out ./out/kirk-key.pem`
- [ ] Coloque a senha que encriptou os certificados na configuração do ES
- [ ] Suba apenas o container do ES
   ```bash
   docker-compose up es-node1
   ```
- [ ] Gere senhas para os usuários do ES e substitua essas informações nos arquivos de var. ambiente
  `docker exec es-node1 /bin/sh /usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh -p <senha>`
- [ ] Definir variáveis ambiente dentro dos arquivos
- [ ] Assegurar a permissão dos arquivos
- [ ] Reconstruir imagens
  ```
  docker-compose build
  ```
- [ ] Aplicar as configurações dentro do container do ES
  ```bash
  docker exec -it es-node1 bash
  cd plugins/opendistro_security/tools/
  chmod +x ./securityadmin.sh
  ./securityadmin.sh -cd ../securityconfig/ -icl -nhnv  \
    -cacert ../../../config/root-ca.pem \
    -cert ../../../config/kirk.pem \
    -key ../../../config/kirk-key.pem \
    -kspass <senha de encriptação dos certificados>

   ```
- [ ] Suba os outros containers, menos o proxy
- [ ] Crie um super usuário para webadmin
  ```
  docker exec -it xram_memory_webadmin ./manage.py createsuperuser
  ```
- [ ] (re) Crie o índice
  ```
  docker exec -it xram_memory_webadmin ./manage.py search_index --rebuild
  ```
- [ ] Configurar o proxy para redirecionar HTTP => HTTPS
- [ ] Verificar as permissões dos arquivos, especialmente dos certificados e chaves

- [ ] Testar a busca
- [ ] Testar a inserção de notícias, inclusive em massa
- [ ] Testar o envio de e-mails