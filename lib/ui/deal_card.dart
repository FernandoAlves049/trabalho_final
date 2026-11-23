import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deal.dart';
import '../state/session_provider.dart';
import '../state/exchange_provider.dart';
import 'style.dart';
import 'game_details.dart';
import 'money.dart';

class DealCard extends StatelessWidget {
  const DealCard({
    super.key,
    required this.deal,
    required this.store,
    this.savedAt,
  });
  final Deal deal;
  final String store;
  final DateTime? savedAt;

  Future<void> toggle(BuildContext context) async {
    try {
      await context.read<SessionProvider>().toggle(deal, store);
    } catch (_) {
      if (context.mounted) {
        message(context, 'Falha ao atualizar os favoritos. Tente novamente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final saved = session.isFavorite(deal.id);
    final exchange = context.watch<ExchangeProvider>();
    final quote = exchange.quote;
    final placeholder = Container(
      color: const Color(0xff322c49),
      alignment: Alignment.center,
      child: const Icon(Icons.sports_esports_outlined, color: violet),
    );
    return Material(
      color: panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                GameDetails(deal: deal, store: store, savedAt: savedAt),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 11, 4, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 84,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 84,
                        height: 47,
                        child: deal.thumb.isEmpty
                            ? placeholder
                            : Image.network(
                                deal.thumb,
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, stack) => placeholder,
                              ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      alignment: Alignment.center,
                      width: 84,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xff293b30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '−${deal.discount}%',
                        style: const TextStyle(
                          color: lime,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store,
                      style: const TextStyle(
                        color: violet,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      deal.title,
                      style: const TextStyle(
                        color: paper,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          usd(deal.price),
                          style: const TextStyle(
                            color: lime,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          usd(deal.regular),
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                            decorationColor: muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quote != null
                          ? '${brl(quote.inReais(deal.price))} estimados'
                          : (exchange.loading
                                ? 'Consultando câmbio…'
                                : 'Câmbio indisponível'),
                      style: const TextStyle(color: paper, fontSize: 13),
                    ),
                    if (savedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Salvo em ${shortDate(savedAt!)}',
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip:
                    '${saved ? 'Remover dos' : 'Adicionar aos'} favoritos: ${deal.title} ($store)',
                onPressed: session.isSaving(deal.id)
                    ? null
                    : () => toggle(context),
                icon: Icon(
                  saved ? Icons.star_rounded : Icons.star_border_rounded,
                  color: saved ? lime : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
