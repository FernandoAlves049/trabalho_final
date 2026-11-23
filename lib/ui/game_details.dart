import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/game_info_api.dart';
import '../models/deal.dart';
import '../state/exchange_provider.dart';
import 'money.dart';
import 'style.dart';

class GameDetails extends StatefulWidget {
  const GameDetails({
    super.key,
    required this.deal,
    required this.store,
    this.savedAt,
  });
  final Deal deal;
  final String store;
  final DateTime? savedAt;

  @override
  State<GameDetails> createState() => _GameDetailsState();
}

class _GameDetailsState extends State<GameDetails> {
  late Future<GameInfo?> request;

  @override
  void initState() {
    super.initState();
    request = context.read<GameInfoApi>().lookup(widget.deal);
  }

  Future<void> visit() async {
    try {
      if (await launchUrl(
        widget.deal.link,
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // O Android pode estar sem navegador disponível.
    }
    if (mounted) message(context, 'Não foi possível abrir a oferta.');
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final exchange = context.watch<ExchangeProvider>();
    final quote = exchange.quote;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do jogo')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: FutureBuilder<GameInfo?>(
              future: request,
              builder: (context, snapshot) {
                final info = snapshot.data;
                final image = info != null && info.banner.isNotEmpty
                    ? info.banner
                    : deal.thumb;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    if (image.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 460 / 215,
                          child: Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) => const ColoredBox(
                              color: panel,
                              child: Icon(
                                Icons.sports_esports_outlined,
                                color: violet,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      widget.store,
                      style: const TextStyle(
                        color: violet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(deal.title, style: headline(34)),
                    if (info != null && info.genres.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          info.genres,
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Text('Sobre o jogo', style: headline(23)),
                    const SizedBox(height: 6),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator()
                    else if (snapshot.hasError) ...[
                      const Text(
                        'Não foi possível carregar o resumo.',
                        style: TextStyle(color: muted),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => setState(
                            () => request = context.read<GameInfoApi>().lookup(
                              deal,
                            ),
                          ),
                          child: const Text('Tentar novamente'),
                        ),
                      ),
                    ] else if (info == null || info.summary.isEmpty)
                      const Text(
                        'A Steam não disponibilizou um resumo para este jogo.',
                        style: TextStyle(color: muted),
                      )
                    else ...[
                      Text(
                        info.summary,
                        style: const TextStyle(
                          color: paper,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Fonte: Steam',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.savedAt == null
                                ? 'Preço da oferta'
                                : 'Oferta salva em ${shortDate(widget.savedAt!)}',
                            style: const TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Wrap(
                            spacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(usd(deal.price), style: headline(26)),
                              Text(
                                usd(deal.regular),
                                style: const TextStyle(
                                  color: muted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                '−${deal.discount}%',
                                style: const TextStyle(color: lime),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (quote != null) ...[
                            Text(
                              '${brl(quote.inReais(deal.price))} estimados',
                              style: const TextStyle(
                                color: lime,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Câmbio de ${shortDate(quote.date)} · US\$ 1 = R\$ ${quote.rate.toStringAsFixed(4).replaceAll('.', ',')} · Frankfurter',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ] else
                            Text(
                              exchange.loading
                                  ? 'Consultando o câmbio…'
                                  : 'Conversão em reais indisponível.',
                              style: const TextStyle(color: muted),
                            ),
                          if (exchange.failed)
                            TextButton(
                              onPressed: exchange.loading
                                  ? null
                                  : exchange.refresh,
                              child: const Text('Atualizar câmbio'),
                            ),
                          if (widget.store == 'Steam' &&
                              info?.brazilPrice != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Preço atual na Steam Brasil: ${brl(info!.brazilPrice!)}',
                                style: const TextStyle(color: paper),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: visit,
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: Text('Ver oferta na ${widget.store}'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
