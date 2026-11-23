import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deal.dart';
import '../state/deals_provider.dart';
import '../state/exchange_provider.dart';
import '../state/session_provider.dart';
import 'deal_card.dart';
import 'style.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool favorites = false;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !favorites,
    onPopInvokedWithResult: (popped, _) {
      if (!popped && favorites) setState(() => favorites = false);
    },
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: favorites
                ? FavoritesScreen(
                    onExplore: () => setState(() => favorites = false),
                  )
                : const DealsScreen(),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: const Color(0xff383548),
        selectedIndex: favorites ? 1 : 0,
        onDestinationSelected: (i) => setState(() => favorites = i == 1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer_rounded, color: lime),
            label: 'Promoções',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border_rounded),
            selectedIcon: Icon(Icons.star_rounded, color: lime),
            label: 'Favoritos',
          ),
        ],
      ),
    ),
  );
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader();
  @override
  Widget build(BuildContext context) => BrandBar(
    trailing: IconButton(
      tooltip: 'Sair da conta',
      onPressed: context.read<SessionProvider>().logout,
      icon: const Icon(Icons.logout_rounded, color: muted),
    ),
  );
}

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DealsProvider>(
    builder: (context, catalog, _) {
      final rows = catalog.deals;
      return _CatalogList(
        header: [
          const _CatalogHeader(),
          const ArcadeBanner(
            title: 'Promoções de jogos',
            label: 'JOGOS PARA PC',
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final store in [
                  const Store('', 'Todas', true),
                  ...catalog.filters,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(store.name),
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false,
                      selected: (catalog.selected ?? '') == store.id,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (catalog.selected ?? '') == store.id
                            ? ink
                            : muted,
                      ),
                      selectedColor: lime,
                      backgroundColor: panel,
                      side: const BorderSide(color: line),
                      onSelected: (_) {
                        final id = store.id.isEmpty ? null : store.id;
                        if (id != catalog.selected) catalog.load(id);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(child: Text('Ofertas', style: headline(28))),
              if (!catalog.loading && catalog.error == null)
                Text(
                  '${rows.length} ${rows.length == 1 ? 'resultado' : 'resultados'}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              IconButton(
                onPressed: catalog.loading
                    ? null
                    : () {
                        context.read<ExchangeProvider>().refresh();
                        catalog.load(catalog.selected);
                      },
                tooltip: 'Atualizar ofertas',
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
        ],
        count: rows.length,
        itemBuilder: (_, i) =>
            DealCard(deal: rows[i], store: catalog.storeName(rows[i].storeId)),
        status: catalog.loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(34),
                  child: CircularProgressIndicator(),
                ),
              )
            : catalog.error != null
            ? _Notice(
                icon: Icons.cloud_off_outlined,
                title: 'Falha ao carregar',
                detail: catalog.error!,
                action: 'Tentar novamente',
                onTap: () => catalog.load(catalog.selected),
              )
            : rows.isEmpty
            ? _Notice(
                icon: Icons.sell_outlined,
                title: 'Sem ofertas agora',
                detail: 'Esta consulta não retornou promoções.',
                action: 'Ver todas as lojas',
                onTap: () => catalog.load(),
              )
            : null,
      );
    },
  );
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Consumer<SessionProvider>(
    builder: (_, session, child) {
      final rows = session.favorites;
      return _CatalogList(
        header: [
          const _CatalogHeader(),
          const ArcadeBanner(
            title: 'Meus favoritos',
            label: 'OFERTAS SALVAS',
            height: 128,
          ),
          const SizedBox(height: 18),
          Text('Coleção de ${session.user?.name ?? ''}', style: headline(28)),
          const SizedBox(height: 5),
          const Text(
            'Preço em dólar salvo na data indicada. Estimativa em reais pelo último câmbio disponível.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 15),
        ],
        count: rows.length,
        itemBuilder: (_, i) => DealCard(
          deal: rows[i].deal,
          store: rows[i].store,
          savedAt: rows[i].savedAt,
        ),
        status: rows.isEmpty
            ? _Notice(
                icon: Icons.star_border_rounded,
                title: 'Nenhum favorito ainda',
                detail: 'Toque na estrela de uma oferta para guardá-la aqui.',
                action: 'Explorar promoções',
                onTap: onExplore,
              )
            : null,
      );
    },
  );
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.header,
    required this.count,
    required this.itemBuilder,
    this.status,
  });
  final List<Widget> header;
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? status;
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
    itemCount: 1 + (status != null ? 1 : count),
    itemBuilder: (context, index) {
      if (index == 0) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: header,
        );
      }
      if (status != null) return status!;
      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: itemBuilder(context, index - 1),
      );
    },
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title, detail, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(icon, color: violet, size: 32),
        const SizedBox(height: 8),
        Text(title, style: headline(24)),
        const SizedBox(height: 5),
        Text(
          detail,
          style: const TextStyle(color: muted),
          textAlign: TextAlign.center,
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}
