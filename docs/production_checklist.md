- [ ] Sincronizar submódulos
- [ ] Criar volumes e redes
  ```bash
  docker network create web
  docker volume create xram_memory_webadmin_media
  docker volume create xram_memory_webadmin_static
  docker volume create xram_memory_db_data
  docker volume create xram_memory_es1_data
  docker volume create xram_memory_backup_repo
  docker volume create xram_memory_backup_cache
  ```
- [ ] Dar permissão ao usuário www-data nos volumes de arquivos:
  ```bash
  chown 33:33 /var/lib/docker/volumes/xram_memory_webadmin_media/_data/ -R
  chown 33:33 /var/lib/docker/volumes/xram_memory_webadmin_static/_data/ -R
  ```
- [ ] Criar arquivos para variáveis-ambiente
  ```bash
  cp .env.dist .env && cp backend.env.dist backend.env && cp contact_message_relay.env.dist contact_message_relay.env && cp ./proxy/.env.dist ./proxy/.env
  ```
- [ ] Criar arquivos de configuração do ElasticSearch
  ```bash
  cp elastic_search/internal_users.yml.dist elastic_search/internal_users.yml && cp elastic_search/custom-elasticsearch.yml.dist elastic_search/custom-elasticsearch.yml
  ```
- [ ] Gerar certificados do Elastic Search
   - [ ] gerar um arquivo de configuração para a ferramenta, preencher as senhas e as configurações LDAP, de acordo com o domínio publicado:
   ```bash
   cd elastic_search/certificates
   cp xram-memory.yml.dist xram-memory.yml
   vim xram-memory.yml
   ```
  - [ ] executar um container com o java https://hub.docker.com/_/openjdk
    `docker run -it --rm -v <pasta dos certificados>:/root/tools/out openjdk:8 bash`
  1. navegue até /root/
  2. no container, baixe e extraia a ferramenta tls-tool (Ferramenta disponível em: https://docs.search-guard.com/latest/offline-tls-tool)
      ```bash
      wget -O tlstool.zip https://search.maven.org/remotecontent?filepath=com/floragunn/search-guard-tlstool/1.7/search-guard-tlstool-1.7.zip
      unzip tlstool.zip
      cd tools
      ```
  3. Gere a autoridade certificadora
    `./sgtlstool.sh -ca -c ./out/xram-memory.yml ./out`
  4. Gere os certificados para os nodes
    `./sgtlstool.sh -crt -c ./out/xram-memory.yml ./out`
  5. Converta o certificado administrativo para o formato PKCS#8 (use a senha definida na configuração)
    `openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./out/kirk.key -out ./out/kirk-key.pem`
  6. saia do container
- [ ] Verifique se os arquivos de certificado (*.pem e *.key) estão em ./elastic_search/certificates/out/
- [ ] Verifique a configuração do elastic_search
   1.
   ```bash
   cd ../
   vim custom-elasticsearch.yml
   ```
   2. verifique as configurações `opendistro_security.nodes_dn` e `opendistro_security.authcz.admin_dn`,
      elas devem bater com os valores usados na configuração da ferramenta de certificados
      - `opendistro_security.nodes_dn` deve conter todos os dns definidos em `nodes[0]`
      - `opendistro_security.authcz.admin_dn` deve conter todos os dns definidos em `clients`
   3. opendistro_security.ssl.transport.pemkey_password e opendistro_security.ssl.http.pemkey_password
      devem conter os valores de `ca.root.pkPassword` e `defaults.pkPassword`, respectivamente
      (geralmente a mesma senha)
   4. `http.cors.allow-origin` deve ser a url do serviço `web`, do site.

- [ ] Retorne ao diretório principal e suba apenas o container do ES
   ```bash
   docker-compose up -d es-node1
   ```
- [ ] Gere senhas para os usuários do ES e substitua essas informações no arquivo
   `internal_users.yml` e nos arquivos de var. ambiente `.env` e `backend.env`
  `docker exec es-node1 /bin/sh /usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh -p <senha>`
- [ ] Definir variáveis ambiente com as senhas dentro dos arquivos
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
- [ ] Reinicie o container es-node1
- [ ] Assegure a permissão dos arquivos de configuração
- [ ] Reconstruir imagens
  ```
  docker-compose build
  ```

- [ ] Suba os outros containers, menos o proxy
  ```
  docker-compose up -d web es-node1 webadmin database files celery-worker rabbitmq certs-extractor contact_message_relay
  ```
- [ ] Crie um super usuário para webadmin
  ```
  docker exec -it xram_memory_webadmin ./manage.py createsuperuser

- [ ] (Opcional) Faça um restore de um dump anterior
   ```bash
   docker cp xram_memory.dump xram_memory_db:/home/xram_memory.dump
   docker exec -it xram_memory_db pg_restore -c -U xram_memory -d xram_memory /home/xram_memory.dump

   ```
  ```
- [ ] (re) Crie o índice
  ```
  docker exec -it xram_memory_webadmin ./manage.py search_index --rebuild
  ```
- [ ] (produção) Configurar o proxy para redirecionar HTTP => HTTPS
- [ ] (produção) Configurar o proxy para gerar certificados

- [ ] Verificar as permissões dos arquivos, especialmente dos certificados e chaves

- [ ] Testar a busca
- [ ] Testar a inserção de notícias, inclusive em massa
- [ ] Testar o envio de e-mails

## Backups
- [ ] Criar os volumes para backup
```bash
  docker volume create xram_memory_backup_cache
  docker volume create xram_memory_backup_repo
```

- [ ] Entrar no container e criar um repositório em /mnt/borg-repository
```bash
  docker exec -it xram_memory_backup sh
  cd /mnt/borg-repository/
  borg init -e repokey-blake2  ./
  <inserir a senha do repositório>
```
- [ ] Usar a mesma senha criada no arquivo de configuração
- [ ] Reiniciar o container de backup