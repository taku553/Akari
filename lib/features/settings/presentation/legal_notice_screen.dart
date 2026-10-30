import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/max_width_container.dart';

/// 特定商取引法に関する表記の各項目
/// TODO: 下記のvalueを実際の情報に書き換えてください
class _LegalNoticeItem {
  final String label;
  final String value;

  const _LegalNoticeItem({required this.label, required this.value});
}

const _legalNoticeItems = <_LegalNoticeItem>[
  _LegalNoticeItem(label: '販売業者名', value: 'Takuのアトリエ'),
  _LegalNoticeItem(label: '運営統括責任者', value: '髙橋拓也'),
  _LegalNoticeItem(
    label: '所在地',
    value: '〒150-0001 東京都渋谷区神宮前5丁目51番8号ラ・ポルト青山 2F-7',
  ),
  _LegalNoticeItem(label: '電話番号', value: '090-4774-7919'),
  _LegalNoticeItem(label: 'メールアドレス', value: 'support@taku-atelier.com'),
  _LegalNoticeItem(label: '販売価格', value: '（各商品・サブスクリプションの購入画面に表示される価格による）'),
  _LegalNoticeItem(
    label: '商品代金以外に必要な料金',
    value: 'インターネット接続に伴う通信料等はお客様のご負担となります',
  ),
  _LegalNoticeItem(
    label: 'お支払い方法',
    value: '各アプリストア（App Store / Google Play）が定める決済方法',
  ),
  _LegalNoticeItem(label: 'お支払い時期', value: '購入手続き完了時に決済されます'),
  _LegalNoticeItem(label: '商品の引き渡し（提供）時期', value: '決済完了後、直ちにサービスをご利用いただけます'),
  _LegalNoticeItem(
    label: '返品・キャンセルについて',
    value: 'デジタルコンテンツの性質上、購入後の返品・返金には応じられません。詳細は各アプリストアの規約に従います',
  ),
  _LegalNoticeItem(label: '動作環境', value: '（対応OS・バージョン等を入力）'),
];

class LegalNoticeScreen extends StatelessWidget {
  const LegalNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '特定商取引法に関する表記',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MaxWidthContainer(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _legalNoticeItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = _legalNoticeItems[index];
            return _buildItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildItem(_LegalNoticeItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
