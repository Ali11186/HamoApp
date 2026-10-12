import 'package:flutter_test/flutter_test.dart';
import 'package:mohammed_store/core/constants/app_constants.dart';

void main() {
  group('Product category structure', () {
    test('exposes only the requested top-level groups', () {
      expect(AppConstants.productCategories, ['اتصالات', 'فودافون', 'فواتير']);
      expect(AppConstants.productCategories, isNot(contains('الكل')));
      expect(AppConstants.productCategories, isNot(contains('عروض أخرى')));
    });

    test('provides all requested child sections with unique stored values', () {
      expect(AppConstants.productSubcategories['اتصالات']!.keys, [
        'رصيد صافي',
        'حكاية ميكسات (نت ومكالمات)',
        'حكاية إنترنت (نت فقط)',
        'باقات اتصالات الإضافية',
        'كروت الشحن',
      ]);
      expect(AppConstants.productSubcategories['فودافون']!.keys, [
        'رصيد صافي',
        'باقات فليكس الأساسية',
        'باقات الإنترنت الأساسية',
        'باقات فليكس الإضافية',
        'كروت الشحن',
      ]);
      expect(AppConstants.productSubcategories['فواتير']!.keys,
          ['فواتير اتصالات', 'فواتير فودافون']);

      final values = AppConstants.productSubcategoryValues;
      expect(values.length, 12);
      expect(values.toSet().length, values.length);
    });

    test('filters a parent group while retaining legacy products', () {
      expect(
        AppConstants.categoryQueryValues('اتصالات'),
        ['Etisalat', ...AppConstants.productSubcategories['اتصالات']!.values],
      );
      expect(
        AppConstants.categoryQueryValues('Vodafone'),
        ['Vodafone', ...AppConstants.productSubcategories['فودافون']!.values],
      );
      expect(AppConstants.categoryQueryValues('فواتير اتصالات'),
          ['Bills_Etisalat']);
      expect(AppConstants.categoryQueryValues('Etisalat_mix'), ['Etisalat_mix']);
    });

    test('keeps product labels and edit choices linked to their groups', () {
      expect(AppConstants.categoryLabel('Etisalat_mix'),
          'اتصالات • حكاية ميكسات (نت ومكالمات)');
      expect(AppConstants.editableProductCategory('Vodafone'),
          'Vodafone_balance');
      expect(AppConstants.editableProductCategory('Other'), 'Other');
    });
  });
}
