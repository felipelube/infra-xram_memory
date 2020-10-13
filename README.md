# Projeto xRAM-Memory

Este repositório concentra todos os serviços do projeto xRAM-Memory orquestrados através da ferramenta docker-compose.

## Detalhamento dos containers e suas responsabilidades
Abaixo segue detalhamento sobre a responsabilidade dos containers, tal como definidos no arquivo `docker-compose.yml`.

### Web (frontend)
Aplicação Vue.js construída com o framework Nuxt.js responsável pela renderização do site tanto em client-side como em server-side. O site expõe um mecanismo de busca público e arquivo de notícias relacionadas a diversos temas da política.

As funcionalidades principais são:

- Visualização de notícias e documentos
- Busca texto-completo e multifacetada de notícias e documentos
- Navegação através da taxonomia do conteúdo: Assuntos e Palavras-chave
- Página de contato com envio de e-mail ao administrador
- Menu dinâmico de acordo com o conteúdo do backend, com possibilidades de posicionamento links.
- Páginas de conteúdos são geradas do backend
- Visualização de imagens em álbuns de fotos

### Webadmin (backend e api)
Aplicação construída com o framework Django 2. Atua como gerenciador de conteúdo e provê a API consumida por Web. As funcionalidades principais são:

- Gerenciamento de conteúdo: Notícias, Sites de notícias, Documentos e Páginas.
- Gerenciamento de taxonomia: Assuntos e Palavras-chave
- Gerenciamento de arquivos: imagens, documentos em pdf e outros
- Gerenciamento de acesso: usuários e grupos
- Geração do índice de busca através de comunicação com serviço dedicado


#### Entidades (modelos):
#### Album (Álbum de fotos)
Entidade de conveniência que mantém um link 1-para-1 com o modelo `Folder` da aplicação de terceiros `django-filer` de forma a prover um repositório para as fotos do álbum, bem como informações sobre o álbum.
Para a criação de um álbum, o usuário cria uma pasta dentro de uma pasta especial no sistema.

#### News (Notícia)
Uma notícia da internet. Este é o modelo mais importante no sistema. Concentra as informações sobre uma peça jornalística, bem como uma ligação com um veículo de impressa, um endereço de versão arquivada externamente, uma imagem da notícia e as diversas capturas desta notícia (se existirem) em PDF.

O modelo concentra também as operações relacionadas, como: adicionar uma captura de notícia em PDF, adicionar palavras-chave, adicionar informações básicas etc. Também possui algumas *flags* por conveniência.

#### Document (Documento)
Esta entidade representa um documento enviado pelo usuário ou gerado pelo sistema.

Documentos são uma camada sobre arquivos com informações úteis como, notícias associadas, tipo mime, data de publicação e taxonomia.

#### NewsPDFCapture (Captura de notícia em PDF)
Um modelo que relaciona um Documento do tipo PDF com uma notícia e uma data de captura.

#### NewsImageCapture (Imagem de notícia)
Um modelo que relaciona um Documento do tipo imagem com uma notícia e uma data de captura e url original. Serve como uma imagem associada a uma Notícia.

#### StaticPage (Página estática)
Modelo que guarda uma página com conteúdo genérico para o site. É possível definir um texto de chamada, uma url amigável, o conteúdo e o posicionamento de um link para esta página no menu.

#### Keyword (Palavra-chave)
Uma simples palavra-chave associada a uma Notícia ou Documento.

#### Keyword (Palavra-chave)
Um tópico que pode ter um texto descritivo e estar em destaque no site, por exemplo: "A prisão do presidente Temer".

### Celery-worker (worker para trabalhos distribuídos)
Diversos processos em webadmin são executados por meio de tarefas em segundo plano, por exemplo, a geração de informações básicas sobre uma notícia, a busca de um logotipo para um site de notícias, a captura de uma notícia em PDF. Este serviço, que pode ter várias instâncias, faz essas tarefas. Ele acessa diretamente o banco de dados para atualizar os dados e se comunica com o Rabbitmq.

### Files (servidor de arquivos)
Este é um servidor web dedicado para servir arquivos. A aplicação webadmin gera arquivos enviados pelo usuário e precisa de arquivos estáticos para o seu funcionamento. Ele também serve o índice de busca construído pela serviço `elasticlunr_index_builder`. Este container não serve os arquivos estáticos de web, que são poucos e servidos por este container mesmo.

### Contact Message Relay (serviço relay de mensagens de contato)
Este serviço cuida do envio de mensagens de e-mail através do formulário de contato em web. Além disso, provê uma camada extra de proteção contra Cross-site request forgery ao validar um desafio do Recaptcha *server-side* conforme o [fluxo definido pelo Google](https://developers.google.com/recaptcha/docs/verify). O serviço só envia o e-mail depois de validar o formato da mensagem de contato e fazer a verificação acima.

### Rabbitmq
Uma instância do RabbitMQ, o broker de mensagens utilizado para a coordenação de tarefas entre webadmin e as diversas instâncias de celery-worker.

### Database (Banco de dados)
Uma instância do banco de dados Postgres. Ela armazena todo o conteúdo das entidades de webadmin.

### Backup
Faz backup de forma automática tanto dos arquivos como do banco de dados utilizando a ferramenta Borgmatic

### ElasticLunr Index Builder (Gerador de índices de busca locais)
Serviço responsável pela construção de um índice de pesquisa [ElasticLunr](http://elasticlunr.com/), consumido pela pesquisa client-side no serviço webadmin.
Expõe uma API simples para comunicação segura (através de um segredo) entre um cliente, no caso o container webadmin, que deve enviar todo o conteúdo a ser indexado via JSON. O índice então é gerado num local configurado.

### Memcache
Cache utilizado pelo serviço webadmin para otimizar a entrega da API e em travas.
A geração de um índice pelo serviço `elasticlunr_index_builder` é feita no máximo uma vez por um período de tempo determinado. Essa configuração é passada ao container `webadmin`, que utiliza uma entrada no cache provido por este container para manter uma trava que impede a geração do índice várias vezes por outros processos.

