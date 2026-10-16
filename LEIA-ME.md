# Rua das Manilhas — protótipo Roblox

Uma rua noturna com quatro bares. **Boteco do Zap** e **Cantina da Canga** têm duas mesas de Truco Mineiro jogáveis cada. **Royal do Blefe** e **Dama da Meia-Noite** têm duas mesas de pôquer cada, com fichas e cartas decorativas. O pôquer ainda não tem regras nem apostas jogáveis.

O jogador nasce na rua, anda até um bar e aperta **E** perto de uma cadeira. Assentos opostos formam dupla: **1 e 3, azul**; **2 e 4, vermelha**. A partida de uma mesa começa quando seus quatro assentos ficam ocupados. As mesas têm partidas independentes.

## Instalar no Roblox Studio

1. Em **ServerScriptService**, atualize o Script `TrucoServer` com todo o conteúdo de [`TrucoServer.server.luau`](TrucoServer.server.luau).
2. Em **ServerScriptService**, atualize ou crie outro Script `BarBuilder` com todo o conteúdo de [`BarBuilder.server.luau`](BarBuilder.server.luau).
3. Em **StarterPlayer > StarterPlayerScripts**, atualize o LocalScript `TrucoClient` com todo o conteúdo de [`TrucoClient.client.luau`](TrucoClient.client.luau).
4. Salve com **Ctrl+S** e clique em **Play**. A rua é gerada quando o servidor inicia, então ela não aparece antes do teste. Para personalizar o cenário de forma permanente, edite o `BarBuilder` ou copie o modelo gerado para o Workspace no modo de edição; o gerador detecta `RuaDasManilhas` quando já existe.
5. Para testar o truco, use **Teste > Server & Clients**, escolha **4 clientes**, e faça todos sentarem na **mesma mesa de truco**.

Se você colou uma versão anterior do cenário no Studio, substitua o código do `BarBuilder`. Se salvou o modelo antigo `BotequimTruco` no Workspace, remova esse modelo pelo Explorer para evitar os dois cenários juntos. Não deixe cópias extras de `TrucoServer` ou `TrucoClient` ativas.

Os arquivos `.luau` no VS Code não se sincronizam automaticamente com Scripts do Studio quando você trabalha por copiar e colar. O arquivo `.rbxl.lock` não é o código do jogo.

## Como jogar

- Ande pela rua e entre no bar desejado. Use **E** para sentar.
- Ao sentar, a câmera fica atrás do personagem, apontada para a mesa. O personagem, as cartas do truco e as fichas decorativas do pôquer aparecem no cenário.
- As cartas de truco são criadas **localmente** para cada jogador: você vê suas cartas, os outros veem os versos. Na mão de 10, a dupla que decide também vê as cartas do parceiro.
- Os botões pequenos no rodapé jogam uma carta, pedem truco, aceitam, aumentam, correm ou escolhem uma carta coberta quando a regra permite.
- **Levantar** ou pular tira você da mesa e devolve a câmera normal. Levantar reinicia apenas a partida daquela mesa.
- Sentar nas mesas de pôquer permite observar as fichas e o salão; o jogo de pôquer será implementado depois.

Para partidas simultâneas nas quatro mesas de truco, configure a capacidade do servidor para pelo menos **16 jogadores**; aumente se quiser visitantes circulando.

## Regras desta versão

- Baralho de 40 cartas, três por jogador, sem vira.
- Manilhas fixas, da maior para a menor: **4♣, 7♥, A♠, 7♦**.
- Cartas comuns: **3 > 2 > A > K > J > Q > 7 > 6 > 5 > 4**.
- Cada mão começa valendo 2. Pedidos: **4 → 6 → 10 → 12**. Correr entrega à outra dupla o valor já aceito.
- Mão de 10: a dupla com 10 pontos vê as cartas do parceiro e decide jogar por 4 ou correr, entregando 2.
- Mão de ferro: com ambas as duplas em 10 pontos, as cartas ficam ocultas até serem jogadas.
- Vence a primeira dupla com pelo menos 12 pontos.

## Próximas melhorias de jogabilidade

Prioridade sugerida: um cronômetro de turno para mesas que ficam paradas; aviso visual de quem deve jogar; convites para sentar com amigos; opção de assistir sem ocupar cadeira; sons de cartas, pedidos e vitória; e, depois, pôquer com regras e fichas reais de jogo. Essas ideias ainda não estão implementadas.
