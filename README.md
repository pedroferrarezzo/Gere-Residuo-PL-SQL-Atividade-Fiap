# Atividade
"Agora que você já sabe das possibilidades de automação usando o PL/SQL, selecione um tema na lista abaixo referente a cidades inteligentes, faça uma análise, examine e descubra atividades podem ser automatizadas por meio da execução de um pacote ou trigger ou procedimento ou função de banco de dados.

Temas de cidades inteligentes

1. Gerenciamento de Tráfego:

Controle de semáforos inteligentes baseado em fluxo de tráfego e condições climáticas.
Monitoramento e análise de padrões de tráfego para otimização de rotas e redução de congestionamentos.
Detecção e notificação automática de acidentes de trânsito para serviços de emergência.
2. Gestão de Resíduos:

Rastreamento de caminhões de coleta de lixo em tempo real para otimização de rotas.
Agendamento automático de coleta com base na capacidade dos recipientes de lixo.
Notificação aos moradores sobre dias de coleta e separação adequada de resíduos.
3. Monitoramento Ambiental:

Sistema de alerta precoce para desastres naturais, como inundações, incêndios florestais e terremotos.
Monitoramento da qualidade do ar e da água em tempo real.
Controle de irrigação inteligente em parques e áreas verdes com base nas condições climáticas.
4. Segurança Pública:

Análise de dados para previsão de crimes e distribuição eficiente de recursos policiais.
Sistema de vigilância por vídeo com reconhecimento facial para identificação de suspeitos.
Integração de sistemas de alarme e notificação em caso de emergências, como incêndios ou invasões.
Com um tema selecionado, será necessário:

- Criar uma modelagem de dados (MER) que represente o tema selecionado. Essa modelagem deve conter de 4 a 5 tabelas que representam o funcionamento de parte do tema (tabela como usuário, login, cadastro não serão aceitas), gere os códigos/scripts em PL/SQL para criação das entidades/tabelas do modelo;

- Com a modelagem pronta, localize quatro atividades que tenham potencial para automação, crie um arquivo PDF com as quatro atividades e qual o motivo para que elas sejam automatizadas;

- Crie os códigos em PL/SQL que façam essa automação. Ou seja, se você propôs a automação para disparar um e-mail em algum evento de alteração de dados, então, deve criar o código PL/SQL para isso."

# LISTA DE AUTOMAÇÕES
- PROCEDURE que abre uma agenda para coleta de lixo em um bairro;
Motivo: Criar uma agenda de coleta de lixo para um dado bairro, seguindo
o MER desenvolvido, envolve diversas tarefas (citadas abaixo) que
realizadas manualmente ou via linguagens de programação, acarretariam
gasto de recursos desnecessários e possíveis erros:
  - Se o bairro não possuir uma coleta em andamento, além de o
motorista e o caminhão estiverem disponíveis um INSERT deve ser
realizado na tabela T_AGENDA;
  - Um UPDATE deve ser realizado nas tabelas T_MOTORISTA,
T_BAIRRO, T_CAMINHAO nas respectivas colunas informando
que estes agora estão envolvidos na agenda em andamento;

  - Um INSERT deve ser realizado na tabela T_NOTIFICACAO para
cada morador do bairro em que a coleta de lixo acontecerá.

- PROCEDURE que encerra uma agenda de coleta de lixo em um bairro;
Motivo: Encerrar uma agenda de coleta de lixo para um dado bairro,
seguindo o MER desenvolvido, envolve diversas tarefas (citadas abaixo)
que realizadas manualmente ou via linguagens de programação,
acarretariam gasto de recursos desnecessários e possíveis erros:
  - Se a quantidade de lixo coletada informada (em KG) for maior que
0, e a agenda passada estiver de fato aberta um UPDATE deve ser
realizado na tabela T_AGENDA para encerrá-la;
  - Um UPDATE deve ser realizado nas tabelas T_MOTORISTA,
T_CAMINHAO e T_BAIRRO liberando-os para uma posterior
abertura de agenda;
  - Um UPDATE deve ser realizado na tabela T_BAIRRO alterando o
percentual de lixo coletado. Está métrica é calculada por meio de
uma FUNCTION;
  - Um DELETE deve ser executado na tabela T_NOTIFICACAO
excluindo as notificações geradas anteriormente na abertura da
agenda.

- TRIGGER que envia um e-mail para os moradores de um bairro
informando sobre a agenda de coleta de lixo;
Motivo: Seguindo a premissa do tópico escolhido, a justificação para a
criação desta trigger é a notificação inteligente dos moradores de um
bairro acerca do dia de coleta e tipo de resíduo.
Observações:
  - A trigger é executada a cada INSERT na tabela T_NOTIFICACAO;
  - O meio de comunicação escolhido é E-MAIL. Pelo servidor da FIAP
não possuir módulos instalados para tal (informação passada pelo
tutor), foi programado no BEGIN da TRIGGER uma série de
DBMS_OUTPUT.PUT_LINE para simular o envio.

- FUNCTIONs diversas para construção das PROCEDURES.
Motivo: As PROCEDURES programadas de vez em quando precisavam
de validações de colunas e cálculos aritméticos. Funções foram
desenvolvidas para tal:
  - Função para cálculo do percentual de coleta de lixo de um bairro;
  - Função para verificação de disponibilidade de um caminhão de
lixo;
  - Função para verificação de disponibilidade de um motorista;
  - Função que valida se um bairro possui agendamentos em aberto
ou não;
  - Função que recebe um número e retorna o nome por extenso do
dia da semana correspondente (Ex: 1 – Domingo, 2 – Segunda
Feira...).
