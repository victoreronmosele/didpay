import 'package:auto_size_text/auto_size_text.dart';
import 'package:didpay/features/currency/currency_dropdown.dart';
import 'package:didpay/features/home/transaction.dart';
import 'package:didpay/l10n/app_localizations.dart';
import 'package:didpay/shared/shake_animated_text.dart';
import 'package:didpay/shared/theme/grid.dart';
import 'package:didpay/shared/utils/currency_util.dart';
import 'package:didpay/shared/utils/number_validation_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tbdex/tbdex.dart';

class Payin extends HookWidget {
  final TransactionType transactionType;
  final ValueNotifier<String> amount;
  final ValueNotifier<PayinKeyPress> keyPress;
  final ValueNotifier<Offering?> selectedOffering;
  final List<Offering> offerings;

  const Payin({
    required this.transactionType,
    required this.amount,
    required this.keyPress,
    required this.selectedOffering,
    required this.offerings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = useState(false);
    final decimalPaddingHint = useState('');

    final formattedAmount = CurrencyUtil.formatFromString(
      amount.value,
      currency: selectedOffering.value?.data.payin.currencyCode,
    );

    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          amount.value = '0';
          decimalPaddingHint.value = '';
        });
        return;
      },
      [selectedOffering.value],
    );

    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final current = amount.value;
          final key = keyPress.value.key;
          if (key == '') return;

          shouldAnimate.value = (key == '<')
              ? !NumberValidationUtil.isValidDelete(current)
              : (transactionType == TransactionType.deposit
                  ? !NumberValidationUtil.isValidInput(
                      current,
                      key,
                      currency: selectedOffering.value?.data.payin.currencyCode,
                    )
                  : !NumberValidationUtil.isValidInput(current, key));
          if (shouldAnimate.value) return;

          if (key == '<') {
            amount.value = (current.length > 1)
                ? current.substring(0, current.length - 1)
                : '0';
          } else {
            amount.value = (current == '0' && key == '.')
                ? '$current$key'
                : (current == '0')
                    ? key
                    : '$current$key';
          }

          final decimalDigits = CurrencyUtil.getDecimalDigits(
            selectedOffering.value?.data.payin.currencyCode,
          );

          final hasDecimal = amount.value.contains('.');
          final hintDigits = hasDecimal
              ? decimalDigits - amount.value.split('.')[1].length
              : decimalDigits;

          decimalPaddingHint.value = hasDecimal && hintDigits > 0
              ? (hintDigits == decimalDigits ? '.' : '') + '0' * hintDigits
              : '';
        });

        return;
      },
      [keyPress.value],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShakeAnimatedWidget(
          shouldAnimate: shouldAnimate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: AutoSizeText.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: formattedAmount),
                          TextSpan(
                            text: decimalPaddingHint.value,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                  const SizedBox(width: Grid.half),
                  _buildPayinCurrency(context),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Grid.xs),
        _buildPayinLabel(context),
      ],
    );
  }

  Widget _buildPayinCurrency(BuildContext context) {
    switch (transactionType) {
      case TransactionType.deposit:
        return CurrencyDropdown(
          transactionType: transactionType,
          selectedOffering: selectedOffering,
          offerings: offerings,
        );
      case TransactionType.withdraw:
      case TransactionType.send:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Grid.xxs),
          child: Text(
            selectedOffering.value?.data.payin.currencyCode ?? '',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        );
    }
  }

  Widget _buildPayinLabel(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    final labels = {
      TransactionType.deposit: Loc.of(context).youDeposit,
      TransactionType.withdraw: Loc.of(context).youWithdraw,
      TransactionType.send: Loc.of(context).youSend,
    };

    final label = labels[transactionType] ?? 'unknown transaction type';

    return Text(label, style: style);
  }
}

class PayinKeyPress {
  final int count;
  final String key;

  PayinKeyPress(this.count, this.key);
}
