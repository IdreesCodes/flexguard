import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transactions_provider.dart';
import '../utils/constants.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_detail_screen.dart';
import 'add_transaction_sheet.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ChangeNotifierProvider(
      create: (_) => TransactionsProvider(userId: auth.currentUser!.id!)..refresh(),
      builder: (context, _) {
        final txp = context.watch<TransactionsProvider>();
        return Scaffold(
          appBar: AppBar(title: const Text('Transactions')),
          backgroundColor: AppColors.accentBlue,
          body: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240 && txp.hasMore && !txp.isFetching) {
                txp.fetchMore();
              }
              return false;
            },
            child: ListView.builder(
              itemCount: txp.transactions.length + (txp.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= txp.transactions.length) {
                  return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                }
                final tx = txp.transactions[index];
                return TransactionListItem(
                  tx: tx,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionDetailScreen(tx: tx))),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_transactions',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<TransactionsProvider>(),
                child: const AddTransactionSheet(),
              ),
            ),
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}


