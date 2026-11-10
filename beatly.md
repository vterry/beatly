
# Beatly

O Beatly é um aplicativo mobile focado em auxiliar no estudo de música, suas principais funcionalidades são:

## Metrônomo

O usuário configura o a velocidade do metrônomo, a divisão do tempo, o volume de cada click no celular.

O metrônomo disponibiliza uma sessão de "desafio", onde o usuário deverá selecionar um valor de incremento da velocidade do metrônomo, uma velocidade mínima de inicio e uma velocidade máxima.
## Rotina de Estudos

Na pasta de estudos o usuário consegue criar Rotinas de estudos, onde cada rotina é um agrupamento de atividades.

Cada atividade possuirá um nome, uma classificação, um tempo que deverá ser dedicado aquela atividades, e se o usuário desejar uma velocidade no metrônomo. Na atividade deverá ter uma opção de iniciar o metrônomo de forma automática junto com a contagem regressiva do tempo configurado para aquela atividade.

As classificações para cada atividade serão um grupo pré determinado de: Técnica, Velocidade, Teoria Musica, Improviso e Free Style

O usuário pode criar várias rotinas e pode iniciar cada uma delas de forma isolada, onde a conclusão de uma atividade inicia a próxima. Entre a execução de uma atividade ou outra é sinalizado ao usuário atráves de um aviso sonoro suave, para não assusta-lo. Junto de um pequeno contato que sinaliza o inicio do próximo estudo. Esse contador pode ser configurado nas configurações gerais do aplicativo. O default deverá ser 5 segundos

## Mapa de evolução

Após a conclusão da rotina, será apresentado um gráfico de teia mostrando qual categoria foi mais treinada naquela sessão e um resumo mensal.


# Plano de Especificação e Implementação

## Definições

- Todo o aplicativo deverá funcionar standalone no celular.
- Iremos publicar uma versão apenas para Android
- Iremos utilizar Flutter na implementação do Aplicativo
- Iremos chamar de Piloto o arquiteto de software que irá operar e validar a evolução das atividades no Antigravity
- Iremos chamar de usuário o cliente que ira usar o aplicativo.

## Configurações gerais do trabalho

1. Selecione o melhor modelo de agente que equilibre uso de token e complexidade da tarefa a ser realizada - Se possível, baixe skills especificas da internet para cada atividade.
2. Nosso modelo de trabalho será baseado no TDD, onde iremos construir e evoluir os testes de acordo com os casos de uso e garantir que cada etapa funciona de maneira evolutiva e incremental.
3. Toda interação devera ser focada em resolver uma parte do processo. Onde o piloto irá validar e aprovar cada interação. O histórico e evolução de cada etapa deve ser salvo para que o contexto não seja perdido ou poluído com informações desnecessárias.
## Etapas do trabalho de Refinamento
1. Refinamento de requisitos - Selecione o agente correto para ler esse documento e gere um documento de especificação funcional chamado de SPEC.md.
2. Refinamento de Arquitetura - Selecione o agente correto para ler a SPEC.md e crie um documento de arquitetura do sistema em um ADR.md.
3. Refinamento da implementação - Selecione o agente correto para ler a SPEC.md e o ADR.md e construa um mapa de implementação. Com a separação de tarefas, onde cada etapa deve ser validada e testada de forma incremental.
4. Experiência do usuário: Gere exemplos de telas do aplicativo baseado na SPEC.md. considere trabalhar modelos de Design minimalistas, com tema escuro baseado no tema escuro do aplicativo Obisidian.
5. Crie um logotipo visualizarmos o aplicativo quando ele estiver instalado.

## Loop de Implementação
1. Validação dos requisitos, decisões de arquitetura e guia de implementação e trade-offs.
2. Selecionar uma atividade do plano de implementação
3. Gere e os casos de testes unitários
4. Gere a implementação do aplicativo
5. Gere testes de integração
6. Disponibilize uma forma do usuário validar a atividade
7. Realize code review final: Se tiver correções volte ao inicio do loop de implementação.
8. Valide com o Piloto se podemos ir para o próximo ciclo
   