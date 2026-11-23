# Pixel Radar

Trabalho final de Desenvolvimento para Dispositivos Móveis do IF Goiano. Aplicativo Flutter para Android que consulta promoções de jogos para PC na CheapShark. Cada conta guarda suas próprias ofertas no SQLite do dispositivo.

## Executar no Android

Use Flutter 3.44.9 com Dart 3.12.2 ou uma versão compatível, o SDK Android e um emulador ou celular com depuração USB. Na raiz do projeto, execute:

```sh
flutter pub get
flutter devices
flutter run -d ID_DO_ANDROID
```

Substitua `ID_DO_ANDROID` pelo identificador exibido em `flutter devices`. O primeiro acesso abre o Login. Toque em **Criar uma conta**, cadastre nome, e-mail e senha e entre. O catálogo requer internet. Cadastro, login e leitura dos favoritos usam somente o banco local.

## Fluxos

- **Cadastro e Login** usam formulários validados. O banco exige e-mail único. A senha é verificada com Argon2id e um salt aleatório por conta. Após fechar o processo é preciso entrar novamente.
- **Promoções** consulta até 30 ofertas ao entrar, ao trocar o filtro ou ao tocar em **Atualizar ofertas**. O filtro Todas inclui as lojas retornadas pela API. Steam, Epic Games Store e GOG aparecem como filtros se estiverem ativas. Cada card mostra o preço em dólares e o total estimado em reais.
- **Detalhes do jogo** abre ao tocar na oferta, tanto no catálogo quanto nos favoritos. A tela busca o resumo e os gêneros na Steam, dando preferência ao português do Brasil. Exibe a data e a taxa da conversão. Para ofertas Steam, traz também o preço atual informado pela loja brasileira, quando disponível. O botão no fim abre a loja pelo redirecionamento da CheapShark.
- **Favoritos** guarda a oferta específica da loja, seus preços e a data em que foi salva. A estrela adiciona ou remove a oferta. Para testar o isolamento, favorite com uma conta, saia, cadastre outra e confira as duas coleções.

## Organização

| Arquivo ou pasta | Responsabilidade |
| --- | --- |
| `lib/main.dart` | Tema, providers e escolha da tela de acordo com a sessão |
| `lib/models/` | Modelos de loja, oferta e favorito |
| `lib/data/` | Cliente HTTP, credenciais e consultas ao SQLite |
| `lib/state/` | Conta, favoritos, filtros e estados de carregamento ou erro |
| `lib/ui/` | Telas de acesso, catálogo, favoritos, detalhes e card compartilhado |

As aulas 06, 08, 09 e 11 fundamentam, respectivamente, navegação e formulários, SQLite, consumo de API REST e Provider. O guia de implementação fornece a estrutura de autenticação e de favoritos por oferta.

## API e recursos

A CheapShark disponibiliza dados públicos de promoções para PC sem chave. A aplicação consulta `GET /api/1.0/stores` e `GET /api/1.0/deals?onSale=1&pageSize=30`, acrescentando `storeID` ao selecionar uma loja. A disponibilidade e os valores mudam com o tempo. [Documentação da CheapShark](https://apidocs.cheapshark.com/) · [Catálogo Public APIs](https://github.com/public-apis/public-apis#games--comics)

As capas vêm das URLs informadas pela API. A paisagem em pixel art acompanha o aplicativo. A Barlow Condensed está incluída em `assets/` com a licença SIL Open Font License.

A Frankfurter fornece a cotação de referência em `GET /v2/rate/USD/BRL`. O aplicativo multiplica o preço da oferta por essa taxa e guarda a última cotação e a data no SQLite para uso offline. Nos favoritos, essa estimativa usa o preço em dólar salvo. O preço cobrado pela loja pode variar por região. [Documentação da Frankfurter](https://frankfurter.dev/)

A descrição vem do endpoint `/api/appdetails` da loja Steam, solicitado com `cc=br` e `l=brazilian`. Para favoritos antigos, o aplicativo recupera o identificador Steam pela CheapShark. Se o jogo não tiver identificação ou descrição disponível, a tela informa isso e mantém o acesso à oferta. [Loja Steam Brasil](https://store.steampowered.com/?cc=br)

## Verificação

```sh
flutter analyze
flutter test
flutter build apk --release
```

