// This is a generated file - do not edit.
//
// Generated from market_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Commodity data (e.g., gold, silver, etc.)
class CommodityItem extends $pb.GeneratedMessage {
  factory CommodityItem({
    $core.String? date,
    $core.String? time,
    $core.String? symbol,
    $core.String? name,
    $core.double? price,
    $core.double? changePercent,
    $core.String? unit,
    $core.String? nameFa,
    $core.String? nameEn,
  }) {
    final result = create();
    if (date != null) result.date = date;
    if (time != null) result.time = time;
    if (symbol != null) result.symbol = symbol;
    if (name != null) result.name = name;
    if (price != null) result.price = price;
    if (changePercent != null) result.changePercent = changePercent;
    if (unit != null) result.unit = unit;
    if (nameFa != null) result.nameFa = nameFa;
    if (nameEn != null) result.nameEn = nameEn;
    return result;
  }

  CommodityItem._();

  factory CommodityItem.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CommodityItem.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CommodityItem', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'date')
    ..aOS(2, _omitFieldNames ? '' : 'time')
    ..aOS(3, _omitFieldNames ? '' : 'symbol')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..a<$core.double>(5, _omitFieldNames ? '' : 'price', $pb.PbFieldType.OD)
    ..a<$core.double>(6, _omitFieldNames ? '' : 'changePercent', $pb.PbFieldType.OD)
    ..aOS(7, _omitFieldNames ? '' : 'unit')
    ..aOS(8, _omitFieldNames ? '' : 'nameFa')
    ..aOS(9, _omitFieldNames ? '' : 'nameEn')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommodityItem clone() => CommodityItem()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommodityItem copyWith(void Function(CommodityItem) updates) => super.copyWith((message) => updates(message as CommodityItem)) as CommodityItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommodityItem create() => CommodityItem._();
  @$core.override
  CommodityItem createEmptyInstance() => create();
  static $pb.PbList<CommodityItem> createRepeated() => $pb.PbList<CommodityItem>();
  @$core.pragma('dart2js:noInline')
  static CommodityItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommodityItem>(create);
  static CommodityItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get date => $_getSZ(0);
  @$pb.TagNumber(1)
  set date($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDate() => $_has(0);
  @$pb.TagNumber(1)
  void clearDate() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get time => $_getSZ(1);
  @$pb.TagNumber(2)
  set time($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get symbol => $_getSZ(2);
  @$pb.TagNumber(3)
  set symbol($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSymbol() => $_has(2);
  @$pb.TagNumber(3)
  void clearSymbol() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get price => $_getN(4);
  @$pb.TagNumber(5)
  set price($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPrice() => $_has(4);
  @$pb.TagNumber(5)
  void clearPrice() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get changePercent => $_getN(5);
  @$pb.TagNumber(6)
  set changePercent($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasChangePercent() => $_has(5);
  @$pb.TagNumber(6)
  void clearChangePercent() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get unit => $_getSZ(6);
  @$pb.TagNumber(7)
  set unit($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUnit() => $_has(6);
  @$pb.TagNumber(7)
  void clearUnit() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get nameFa => $_getSZ(7);
  @$pb.TagNumber(8)
  set nameFa($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasNameFa() => $_has(7);
  @$pb.TagNumber(8)
  void clearNameFa() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get nameEn => $_getSZ(8);
  @$pb.TagNumber(9)
  set nameEn($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasNameEn() => $_has(8);
  @$pb.TagNumber(9)
  void clearNameEn() => $_clearField(9);
}

class CommodityData extends $pb.GeneratedMessage {
  factory CommodityData({
    $core.Iterable<CommodityItem>? metalPrecious,
  }) {
    final result = create();
    if (metalPrecious != null) result.metalPrecious.addAll(metalPrecious);
    return result;
  }

  CommodityData._();

  factory CommodityData.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CommodityData.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CommodityData', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..pc<CommodityItem>(1, _omitFieldNames ? '' : 'metalPrecious', $pb.PbFieldType.PM, subBuilder: CommodityItem.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommodityData clone() => CommodityData()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommodityData copyWith(void Function(CommodityData) updates) => super.copyWith((message) => updates(message as CommodityData)) as CommodityData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommodityData create() => CommodityData._();
  @$core.override
  CommodityData createEmptyInstance() => create();
  static $pb.PbList<CommodityData> createRepeated() => $pb.PbList<CommodityData>();
  @$core.pragma('dart2js:noInline')
  static CommodityData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommodityData>(create);
  static CommodityData? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CommodityItem> get metalPrecious => $_getList(0);
}

/// Cryptocurrency data
class CryptoItem extends $pb.GeneratedMessage {
  factory CryptoItem({
    $core.String? date,
    $core.String? time,
    $fixnum.Int64? timeUnix,
    $core.String? name,
    $core.String? nameFa,
    $core.String? price,
    $core.String? priceToman,
    $core.double? changePercent,
    $fixnum.Int64? marketCap,
    $core.String? linkIcon,
  }) {
    final result = create();
    if (date != null) result.date = date;
    if (time != null) result.time = time;
    if (timeUnix != null) result.timeUnix = timeUnix;
    if (name != null) result.name = name;
    if (nameFa != null) result.nameFa = nameFa;
    if (price != null) result.price = price;
    if (priceToman != null) result.priceToman = priceToman;
    if (changePercent != null) result.changePercent = changePercent;
    if (marketCap != null) result.marketCap = marketCap;
    if (linkIcon != null) result.linkIcon = linkIcon;
    return result;
  }

  CryptoItem._();

  factory CryptoItem.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CryptoItem.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CryptoItem', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'date')
    ..aOS(2, _omitFieldNames ? '' : 'time')
    ..aInt64(3, _omitFieldNames ? '' : 'timeUnix')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'nameFa')
    ..aOS(6, _omitFieldNames ? '' : 'price')
    ..aOS(7, _omitFieldNames ? '' : 'priceToman')
    ..a<$core.double>(8, _omitFieldNames ? '' : 'changePercent', $pb.PbFieldType.OD)
    ..aInt64(9, _omitFieldNames ? '' : 'marketCap')
    ..aOS(10, _omitFieldNames ? '' : 'linkIcon')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CryptoItem clone() => CryptoItem()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CryptoItem copyWith(void Function(CryptoItem) updates) => super.copyWith((message) => updates(message as CryptoItem)) as CryptoItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CryptoItem create() => CryptoItem._();
  @$core.override
  CryptoItem createEmptyInstance() => create();
  static $pb.PbList<CryptoItem> createRepeated() => $pb.PbList<CryptoItem>();
  @$core.pragma('dart2js:noInline')
  static CryptoItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CryptoItem>(create);
  static CryptoItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get date => $_getSZ(0);
  @$pb.TagNumber(1)
  set date($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDate() => $_has(0);
  @$pb.TagNumber(1)
  void clearDate() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get time => $_getSZ(1);
  @$pb.TagNumber(2)
  set time($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timeUnix => $_getI64(2);
  @$pb.TagNumber(3)
  set timeUnix($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeUnix() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeUnix() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get nameFa => $_getSZ(4);
  @$pb.TagNumber(5)
  set nameFa($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNameFa() => $_has(4);
  @$pb.TagNumber(5)
  void clearNameFa() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get price => $_getSZ(5);
  @$pb.TagNumber(6)
  set price($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPrice() => $_has(5);
  @$pb.TagNumber(6)
  void clearPrice() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get priceToman => $_getSZ(6);
  @$pb.TagNumber(7)
  set priceToman($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPriceToman() => $_has(6);
  @$pb.TagNumber(7)
  void clearPriceToman() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get changePercent => $_getN(7);
  @$pb.TagNumber(8)
  set changePercent($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasChangePercent() => $_has(7);
  @$pb.TagNumber(8)
  void clearChangePercent() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get marketCap => $_getI64(8);
  @$pb.TagNumber(9)
  set marketCap($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMarketCap() => $_has(8);
  @$pb.TagNumber(9)
  void clearMarketCap() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get linkIcon => $_getSZ(9);
  @$pb.TagNumber(10)
  set linkIcon($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLinkIcon() => $_has(9);
  @$pb.TagNumber(10)
  void clearLinkIcon() => $_clearField(10);
}

class CryptoData extends $pb.GeneratedMessage {
  factory CryptoData({
    $core.Iterable<CryptoItem>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  CryptoData._();

  factory CryptoData.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CryptoData.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CryptoData', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..pc<CryptoItem>(1, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: CryptoItem.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CryptoData clone() => CryptoData()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CryptoData copyWith(void Function(CryptoData) updates) => super.copyWith((message) => updates(message as CryptoData)) as CryptoData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CryptoData create() => CryptoData._();
  @$core.override
  CryptoData createEmptyInstance() => create();
  static $pb.PbList<CryptoData> createRepeated() => $pb.PbList<CryptoData>();
  @$core.pragma('dart2js:noInline')
  static CryptoData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CryptoData>(create);
  static CryptoData? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CryptoItem> get items => $_getList(0);
}

/// Fiat currency rates
class CurrencyItem extends $pb.GeneratedMessage {
  factory CurrencyItem({
    $core.String? date,
    $core.String? time,
    $fixnum.Int64? timeUnix,
    $core.String? symbol,
    $core.String? nameEn,
    $core.String? name,
    $core.double? price,
    $core.double? changeValue,
    $core.double? changePercent,
    $core.String? unit,
  }) {
    final result = create();
    if (date != null) result.date = date;
    if (time != null) result.time = time;
    if (timeUnix != null) result.timeUnix = timeUnix;
    if (symbol != null) result.symbol = symbol;
    if (nameEn != null) result.nameEn = nameEn;
    if (name != null) result.name = name;
    if (price != null) result.price = price;
    if (changeValue != null) result.changeValue = changeValue;
    if (changePercent != null) result.changePercent = changePercent;
    if (unit != null) result.unit = unit;
    return result;
  }

  CurrencyItem._();

  factory CurrencyItem.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CurrencyItem.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CurrencyItem', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'date')
    ..aOS(2, _omitFieldNames ? '' : 'time')
    ..aInt64(3, _omitFieldNames ? '' : 'timeUnix')
    ..aOS(4, _omitFieldNames ? '' : 'symbol')
    ..aOS(5, _omitFieldNames ? '' : 'nameEn')
    ..aOS(6, _omitFieldNames ? '' : 'name')
    ..a<$core.double>(7, _omitFieldNames ? '' : 'price', $pb.PbFieldType.OD)
    ..a<$core.double>(8, _omitFieldNames ? '' : 'changeValue', $pb.PbFieldType.OD)
    ..a<$core.double>(9, _omitFieldNames ? '' : 'changePercent', $pb.PbFieldType.OD)
    ..aOS(10, _omitFieldNames ? '' : 'unit')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrencyItem clone() => CurrencyItem()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrencyItem copyWith(void Function(CurrencyItem) updates) => super.copyWith((message) => updates(message as CurrencyItem)) as CurrencyItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CurrencyItem create() => CurrencyItem._();
  @$core.override
  CurrencyItem createEmptyInstance() => create();
  static $pb.PbList<CurrencyItem> createRepeated() => $pb.PbList<CurrencyItem>();
  @$core.pragma('dart2js:noInline')
  static CurrencyItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CurrencyItem>(create);
  static CurrencyItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get date => $_getSZ(0);
  @$pb.TagNumber(1)
  set date($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDate() => $_has(0);
  @$pb.TagNumber(1)
  void clearDate() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get time => $_getSZ(1);
  @$pb.TagNumber(2)
  set time($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timeUnix => $_getI64(2);
  @$pb.TagNumber(3)
  set timeUnix($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeUnix() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeUnix() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get symbol => $_getSZ(3);
  @$pb.TagNumber(4)
  set symbol($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSymbol() => $_has(3);
  @$pb.TagNumber(4)
  void clearSymbol() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get nameEn => $_getSZ(4);
  @$pb.TagNumber(5)
  set nameEn($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNameEn() => $_has(4);
  @$pb.TagNumber(5)
  void clearNameEn() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get name => $_getSZ(5);
  @$pb.TagNumber(6)
  set name($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasName() => $_has(5);
  @$pb.TagNumber(6)
  void clearName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get price => $_getN(6);
  @$pb.TagNumber(7)
  set price($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPrice() => $_has(6);
  @$pb.TagNumber(7)
  void clearPrice() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get changeValue => $_getN(7);
  @$pb.TagNumber(8)
  set changeValue($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasChangeValue() => $_has(7);
  @$pb.TagNumber(8)
  void clearChangeValue() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get changePercent => $_getN(8);
  @$pb.TagNumber(9)
  set changePercent($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasChangePercent() => $_has(8);
  @$pb.TagNumber(9)
  void clearChangePercent() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get unit => $_getSZ(9);
  @$pb.TagNumber(10)
  set unit($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUnit() => $_has(9);
  @$pb.TagNumber(10)
  void clearUnit() => $_clearField(10);
}

class CurrencyData extends $pb.GeneratedMessage {
  factory CurrencyData({
    $core.Iterable<CurrencyItem>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  CurrencyData._();

  factory CurrencyData.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CurrencyData.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CurrencyData', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..pc<CurrencyItem>(1, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: CurrencyItem.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrencyData clone() => CurrencyData()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrencyData copyWith(void Function(CurrencyData) updates) => super.copyWith((message) => updates(message as CurrencyData)) as CurrencyData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CurrencyData create() => CurrencyData._();
  @$core.override
  CurrencyData createEmptyInstance() => create();
  static $pb.PbList<CurrencyData> createRepeated() => $pb.PbList<CurrencyData>();
  @$core.pragma('dart2js:noInline')
  static CurrencyData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CurrencyData>(create);
  static CurrencyData? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CurrencyItem> get items => $_getList(0);
}

/// Gold market data
class GoldItem extends $pb.GeneratedMessage {
  factory GoldItem({
    $core.String? date,
    $core.String? time,
    $fixnum.Int64? timeUnix,
    $core.String? symbol,
    $core.String? nameEn,
    $core.String? name,
    $core.double? price,
    $core.double? changeValue,
    $core.double? changePercent,
    $core.String? unit,
    $core.String? nameFa,
  }) {
    final result = create();
    if (date != null) result.date = date;
    if (time != null) result.time = time;
    if (timeUnix != null) result.timeUnix = timeUnix;
    if (symbol != null) result.symbol = symbol;
    if (nameEn != null) result.nameEn = nameEn;
    if (name != null) result.name = name;
    if (price != null) result.price = price;
    if (changeValue != null) result.changeValue = changeValue;
    if (changePercent != null) result.changePercent = changePercent;
    if (unit != null) result.unit = unit;
    if (nameFa != null) result.nameFa = nameFa;
    return result;
  }

  GoldItem._();

  factory GoldItem.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GoldItem.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GoldItem', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'date')
    ..aOS(2, _omitFieldNames ? '' : 'time')
    ..aInt64(3, _omitFieldNames ? '' : 'timeUnix')
    ..aOS(4, _omitFieldNames ? '' : 'symbol')
    ..aOS(5, _omitFieldNames ? '' : 'nameEn')
    ..aOS(6, _omitFieldNames ? '' : 'name')
    ..a<$core.double>(7, _omitFieldNames ? '' : 'price', $pb.PbFieldType.OD)
    ..a<$core.double>(8, _omitFieldNames ? '' : 'changeValue', $pb.PbFieldType.OD)
    ..a<$core.double>(9, _omitFieldNames ? '' : 'changePercent', $pb.PbFieldType.OD)
    ..aOS(10, _omitFieldNames ? '' : 'unit')
    ..aOS(11, _omitFieldNames ? '' : 'nameFa')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoldItem clone() => GoldItem()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoldItem copyWith(void Function(GoldItem) updates) => super.copyWith((message) => updates(message as GoldItem)) as GoldItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GoldItem create() => GoldItem._();
  @$core.override
  GoldItem createEmptyInstance() => create();
  static $pb.PbList<GoldItem> createRepeated() => $pb.PbList<GoldItem>();
  @$core.pragma('dart2js:noInline')
  static GoldItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GoldItem>(create);
  static GoldItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get date => $_getSZ(0);
  @$pb.TagNumber(1)
  set date($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDate() => $_has(0);
  @$pb.TagNumber(1)
  void clearDate() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get time => $_getSZ(1);
  @$pb.TagNumber(2)
  set time($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timeUnix => $_getI64(2);
  @$pb.TagNumber(3)
  set timeUnix($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeUnix() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeUnix() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get symbol => $_getSZ(3);
  @$pb.TagNumber(4)
  set symbol($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSymbol() => $_has(3);
  @$pb.TagNumber(4)
  void clearSymbol() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get nameEn => $_getSZ(4);
  @$pb.TagNumber(5)
  set nameEn($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNameEn() => $_has(4);
  @$pb.TagNumber(5)
  void clearNameEn() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get name => $_getSZ(5);
  @$pb.TagNumber(6)
  set name($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasName() => $_has(5);
  @$pb.TagNumber(6)
  void clearName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get price => $_getN(6);
  @$pb.TagNumber(7)
  set price($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPrice() => $_has(6);
  @$pb.TagNumber(7)
  void clearPrice() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get changeValue => $_getN(7);
  @$pb.TagNumber(8)
  set changeValue($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasChangeValue() => $_has(7);
  @$pb.TagNumber(8)
  void clearChangeValue() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get changePercent => $_getN(8);
  @$pb.TagNumber(9)
  set changePercent($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasChangePercent() => $_has(8);
  @$pb.TagNumber(9)
  void clearChangePercent() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get unit => $_getSZ(9);
  @$pb.TagNumber(10)
  set unit($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUnit() => $_has(9);
  @$pb.TagNumber(10)
  void clearUnit() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get nameFa => $_getSZ(10);
  @$pb.TagNumber(11)
  set nameFa($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasNameFa() => $_has(10);
  @$pb.TagNumber(11)
  void clearNameFa() => $_clearField(11);
}

class GoldData extends $pb.GeneratedMessage {
  factory GoldData({
    $core.Iterable<GoldItem>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  GoldData._();

  factory GoldData.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GoldData.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GoldData', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..pc<GoldItem>(1, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: GoldItem.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoldData clone() => GoldData()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoldData copyWith(void Function(GoldData) updates) => super.copyWith((message) => updates(message as GoldData)) as GoldData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GoldData create() => GoldData._();
  @$core.override
  GoldData createEmptyInstance() => create();
  static $pb.PbList<GoldData> createRepeated() => $pb.PbList<GoldData>();
  @$core.pragma('dart2js:noInline')
  static GoldData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GoldData>(create);
  static GoldData? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<GoldItem> get items => $_getList(0);
}

/// Generic order book level used by TSE/IFB stock items
class OrderBookLevel extends $pb.GeneratedMessage {
  factory OrderBookLevel({
    $core.int? zd,
    $fixnum.Int64? qd,
    $fixnum.Int64? pd,
    $fixnum.Int64? po,
    $fixnum.Int64? qo,
    $core.int? zo,
  }) {
    final result = create();
    if (zd != null) result.zd = zd;
    if (qd != null) result.qd = qd;
    if (pd != null) result.pd = pd;
    if (po != null) result.po = po;
    if (qo != null) result.qo = qo;
    if (zo != null) result.zo = zo;
    return result;
  }

  OrderBookLevel._();

  factory OrderBookLevel.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory OrderBookLevel.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OrderBookLevel', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'zd', $pb.PbFieldType.O3)
    ..aInt64(2, _omitFieldNames ? '' : 'qd')
    ..aInt64(3, _omitFieldNames ? '' : 'pd')
    ..aInt64(4, _omitFieldNames ? '' : 'po')
    ..aInt64(5, _omitFieldNames ? '' : 'qo')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'zo', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrderBookLevel clone() => OrderBookLevel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrderBookLevel copyWith(void Function(OrderBookLevel) updates) => super.copyWith((message) => updates(message as OrderBookLevel)) as OrderBookLevel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OrderBookLevel create() => OrderBookLevel._();
  @$core.override
  OrderBookLevel createEmptyInstance() => create();
  static $pb.PbList<OrderBookLevel> createRepeated() => $pb.PbList<OrderBookLevel>();
  @$core.pragma('dart2js:noInline')
  static OrderBookLevel getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OrderBookLevel>(create);
  static OrderBookLevel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get zd => $_getIZ(0);
  @$pb.TagNumber(1)
  set zd($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasZd() => $_has(0);
  @$pb.TagNumber(1)
  void clearZd() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get qd => $_getI64(1);
  @$pb.TagNumber(2)
  set qd($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQd() => $_has(1);
  @$pb.TagNumber(2)
  void clearQd() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get pd => $_getI64(2);
  @$pb.TagNumber(3)
  set pd($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPd() => $_has(2);
  @$pb.TagNumber(3)
  void clearPd() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get po => $_getI64(3);
  @$pb.TagNumber(4)
  set po($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPo() => $_has(3);
  @$pb.TagNumber(4)
  void clearPo() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get qo => $_getI64(4);
  @$pb.TagNumber(5)
  set qo($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasQo() => $_has(4);
  @$pb.TagNumber(5)
  void clearQo() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get zo => $_getIZ(5);
  @$pb.TagNumber(6)
  set zo($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasZo() => $_has(5);
  @$pb.TagNumber(6)
  void clearZo() => $_clearField(6);
}

/// Stock‐like instruments (debt securities, futures, housing facilities, symbols, etc.)
class StockItem extends $pb.GeneratedMessage {
  factory StockItem({
    $core.String? time,
    $core.String? l18,
    $core.String? l30,
    $core.String? isin,
    $fixnum.Int64? id,
    $core.String? cs,
    $core.int? csId,
    $fixnum.Int64? z,
    $fixnum.Int64? bvol,
    $fixnum.Int64? mv,
    $core.double? eps,
    $core.double? pe,
    $fixnum.Int64? tmin,
    $fixnum.Int64? tmax,
    $fixnum.Int64? pmin,
    $fixnum.Int64? pmax,
    $fixnum.Int64? py,
    $fixnum.Int64? pf,
    $fixnum.Int64? pl,
    $fixnum.Int64? plc,
    $core.double? plp,
    $fixnum.Int64? pc,
    $fixnum.Int64? pcc,
    $core.double? pcp,
    $core.int? tno,
    $fixnum.Int64? tvol,
    $fixnum.Int64? tval,
    $core.int? buyCountI,
    $core.int? buyCountN,
    $core.int? sellCountI,
    $core.int? sellCountN,
    $fixnum.Int64? buyIVolume,
    $fixnum.Int64? buyNVolume,
    $fixnum.Int64? sellIVolume,
    $fixnum.Int64? sellNVolume,
    $core.Iterable<OrderBookLevel>? orderLevels,
  }) {
    final result = create();
    if (time != null) result.time = time;
    if (l18 != null) result.l18 = l18;
    if (l30 != null) result.l30 = l30;
    if (isin != null) result.isin = isin;
    if (id != null) result.id = id;
    if (cs != null) result.cs = cs;
    if (csId != null) result.csId = csId;
    if (z != null) result.z = z;
    if (bvol != null) result.bvol = bvol;
    if (mv != null) result.mv = mv;
    if (eps != null) result.eps = eps;
    if (pe != null) result.pe = pe;
    if (tmin != null) result.tmin = tmin;
    if (tmax != null) result.tmax = tmax;
    if (pmin != null) result.pmin = pmin;
    if (pmax != null) result.pmax = pmax;
    if (py != null) result.py = py;
    if (pf != null) result.pf = pf;
    if (pl != null) result.pl = pl;
    if (plc != null) result.plc = plc;
    if (plp != null) result.plp = plp;
    if (pc != null) result.pc = pc;
    if (pcc != null) result.pcc = pcc;
    if (pcp != null) result.pcp = pcp;
    if (tno != null) result.tno = tno;
    if (tvol != null) result.tvol = tvol;
    if (tval != null) result.tval = tval;
    if (buyCountI != null) result.buyCountI = buyCountI;
    if (buyCountN != null) result.buyCountN = buyCountN;
    if (sellCountI != null) result.sellCountI = sellCountI;
    if (sellCountN != null) result.sellCountN = sellCountN;
    if (buyIVolume != null) result.buyIVolume = buyIVolume;
    if (buyNVolume != null) result.buyNVolume = buyNVolume;
    if (sellIVolume != null) result.sellIVolume = sellIVolume;
    if (sellNVolume != null) result.sellNVolume = sellNVolume;
    if (orderLevels != null) result.orderLevels.addAll(orderLevels);
    return result;
  }

  StockItem._();

  factory StockItem.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory StockItem.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StockItem', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'time')
    ..aOS(2, _omitFieldNames ? '' : 'l18')
    ..aOS(3, _omitFieldNames ? '' : 'l30')
    ..aOS(4, _omitFieldNames ? '' : 'isin')
    ..aInt64(5, _omitFieldNames ? '' : 'id')
    ..aOS(6, _omitFieldNames ? '' : 'cs')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'csId', $pb.PbFieldType.O3)
    ..aInt64(8, _omitFieldNames ? '' : 'z')
    ..aInt64(9, _omitFieldNames ? '' : 'bvol')
    ..aInt64(10, _omitFieldNames ? '' : 'mv')
    ..a<$core.double>(11, _omitFieldNames ? '' : 'eps', $pb.PbFieldType.OD)
    ..a<$core.double>(12, _omitFieldNames ? '' : 'pe', $pb.PbFieldType.OD)
    ..aInt64(13, _omitFieldNames ? '' : 'tmin')
    ..aInt64(14, _omitFieldNames ? '' : 'tmax')
    ..aInt64(15, _omitFieldNames ? '' : 'pmin')
    ..aInt64(16, _omitFieldNames ? '' : 'pmax')
    ..aInt64(17, _omitFieldNames ? '' : 'py')
    ..aInt64(18, _omitFieldNames ? '' : 'pf')
    ..aInt64(19, _omitFieldNames ? '' : 'pl')
    ..aInt64(20, _omitFieldNames ? '' : 'plc')
    ..a<$core.double>(21, _omitFieldNames ? '' : 'plp', $pb.PbFieldType.OD)
    ..aInt64(22, _omitFieldNames ? '' : 'pc')
    ..aInt64(23, _omitFieldNames ? '' : 'pcc')
    ..a<$core.double>(24, _omitFieldNames ? '' : 'pcp', $pb.PbFieldType.OD)
    ..a<$core.int>(25, _omitFieldNames ? '' : 'tno', $pb.PbFieldType.O3)
    ..aInt64(26, _omitFieldNames ? '' : 'tvol')
    ..aInt64(27, _omitFieldNames ? '' : 'tval')
    ..a<$core.int>(28, _omitFieldNames ? '' : 'BuyCountI', $pb.PbFieldType.O3, protoName: 'Buy_CountI')
    ..a<$core.int>(29, _omitFieldNames ? '' : 'BuyCountN', $pb.PbFieldType.O3, protoName: 'Buy_CountN')
    ..a<$core.int>(30, _omitFieldNames ? '' : 'SellCountI', $pb.PbFieldType.O3, protoName: 'Sell_CountI')
    ..a<$core.int>(31, _omitFieldNames ? '' : 'SellCountN', $pb.PbFieldType.O3, protoName: 'Sell_CountN')
    ..aInt64(32, _omitFieldNames ? '' : 'BuyIVolume', protoName: 'Buy_I_Volume')
    ..aInt64(33, _omitFieldNames ? '' : 'BuyNVolume', protoName: 'Buy_N_Volume')
    ..aInt64(34, _omitFieldNames ? '' : 'SellIVolume', protoName: 'Sell_I_Volume')
    ..aInt64(35, _omitFieldNames ? '' : 'SellNVolume', protoName: 'Sell_N_Volume')
    ..pc<OrderBookLevel>(36, _omitFieldNames ? '' : 'orderLevels', $pb.PbFieldType.PM, subBuilder: OrderBookLevel.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StockItem clone() => StockItem()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StockItem copyWith(void Function(StockItem) updates) => super.copyWith((message) => updates(message as StockItem)) as StockItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StockItem create() => StockItem._();
  @$core.override
  StockItem createEmptyInstance() => create();
  static $pb.PbList<StockItem> createRepeated() => $pb.PbList<StockItem>();
  @$core.pragma('dart2js:noInline')
  static StockItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StockItem>(create);
  static StockItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get time => $_getSZ(0);
  @$pb.TagNumber(1)
  set time($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearTime() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get l18 => $_getSZ(1);
  @$pb.TagNumber(2)
  set l18($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasL18() => $_has(1);
  @$pb.TagNumber(2)
  void clearL18() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get l30 => $_getSZ(2);
  @$pb.TagNumber(3)
  set l30($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasL30() => $_has(2);
  @$pb.TagNumber(3)
  void clearL30() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get isin => $_getSZ(3);
  @$pb.TagNumber(4)
  set isin($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsin() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsin() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get id => $_getI64(4);
  @$pb.TagNumber(5)
  set id($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasId() => $_has(4);
  @$pb.TagNumber(5)
  void clearId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get cs => $_getSZ(5);
  @$pb.TagNumber(6)
  set cs($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCs() => $_has(5);
  @$pb.TagNumber(6)
  void clearCs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get csId => $_getIZ(6);
  @$pb.TagNumber(7)
  set csId($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCsId() => $_has(6);
  @$pb.TagNumber(7)
  void clearCsId() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get z => $_getI64(7);
  @$pb.TagNumber(8)
  set z($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasZ() => $_has(7);
  @$pb.TagNumber(8)
  void clearZ() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get bvol => $_getI64(8);
  @$pb.TagNumber(9)
  set bvol($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBvol() => $_has(8);
  @$pb.TagNumber(9)
  void clearBvol() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get mv => $_getI64(9);
  @$pb.TagNumber(10)
  set mv($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMv() => $_has(9);
  @$pb.TagNumber(10)
  void clearMv() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get eps => $_getN(10);
  @$pb.TagNumber(11)
  set eps($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasEps() => $_has(10);
  @$pb.TagNumber(11)
  void clearEps() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get pe => $_getN(11);
  @$pb.TagNumber(12)
  set pe($core.double value) => $_setDouble(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPe() => $_has(11);
  @$pb.TagNumber(12)
  void clearPe() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get tmin => $_getI64(12);
  @$pb.TagNumber(13)
  set tmin($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTmin() => $_has(12);
  @$pb.TagNumber(13)
  void clearTmin() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get tmax => $_getI64(13);
  @$pb.TagNumber(14)
  set tmax($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasTmax() => $_has(13);
  @$pb.TagNumber(14)
  void clearTmax() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get pmin => $_getI64(14);
  @$pb.TagNumber(15)
  set pmin($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasPmin() => $_has(14);
  @$pb.TagNumber(15)
  void clearPmin() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get pmax => $_getI64(15);
  @$pb.TagNumber(16)
  set pmax($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasPmax() => $_has(15);
  @$pb.TagNumber(16)
  void clearPmax() => $_clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get py => $_getI64(16);
  @$pb.TagNumber(17)
  set py($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasPy() => $_has(16);
  @$pb.TagNumber(17)
  void clearPy() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get pf => $_getI64(17);
  @$pb.TagNumber(18)
  set pf($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasPf() => $_has(17);
  @$pb.TagNumber(18)
  void clearPf() => $_clearField(18);

  @$pb.TagNumber(19)
  $fixnum.Int64 get pl => $_getI64(18);
  @$pb.TagNumber(19)
  set pl($fixnum.Int64 value) => $_setInt64(18, value);
  @$pb.TagNumber(19)
  $core.bool hasPl() => $_has(18);
  @$pb.TagNumber(19)
  void clearPl() => $_clearField(19);

  @$pb.TagNumber(20)
  $fixnum.Int64 get plc => $_getI64(19);
  @$pb.TagNumber(20)
  set plc($fixnum.Int64 value) => $_setInt64(19, value);
  @$pb.TagNumber(20)
  $core.bool hasPlc() => $_has(19);
  @$pb.TagNumber(20)
  void clearPlc() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.double get plp => $_getN(20);
  @$pb.TagNumber(21)
  set plp($core.double value) => $_setDouble(20, value);
  @$pb.TagNumber(21)
  $core.bool hasPlp() => $_has(20);
  @$pb.TagNumber(21)
  void clearPlp() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get pc => $_getI64(21);
  @$pb.TagNumber(22)
  set pc($fixnum.Int64 value) => $_setInt64(21, value);
  @$pb.TagNumber(22)
  $core.bool hasPc() => $_has(21);
  @$pb.TagNumber(22)
  void clearPc() => $_clearField(22);

  @$pb.TagNumber(23)
  $fixnum.Int64 get pcc => $_getI64(22);
  @$pb.TagNumber(23)
  set pcc($fixnum.Int64 value) => $_setInt64(22, value);
  @$pb.TagNumber(23)
  $core.bool hasPcc() => $_has(22);
  @$pb.TagNumber(23)
  void clearPcc() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.double get pcp => $_getN(23);
  @$pb.TagNumber(24)
  set pcp($core.double value) => $_setDouble(23, value);
  @$pb.TagNumber(24)
  $core.bool hasPcp() => $_has(23);
  @$pb.TagNumber(24)
  void clearPcp() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.int get tno => $_getIZ(24);
  @$pb.TagNumber(25)
  set tno($core.int value) => $_setSignedInt32(24, value);
  @$pb.TagNumber(25)
  $core.bool hasTno() => $_has(24);
  @$pb.TagNumber(25)
  void clearTno() => $_clearField(25);

  @$pb.TagNumber(26)
  $fixnum.Int64 get tvol => $_getI64(25);
  @$pb.TagNumber(26)
  set tvol($fixnum.Int64 value) => $_setInt64(25, value);
  @$pb.TagNumber(26)
  $core.bool hasTvol() => $_has(25);
  @$pb.TagNumber(26)
  void clearTvol() => $_clearField(26);

  @$pb.TagNumber(27)
  $fixnum.Int64 get tval => $_getI64(26);
  @$pb.TagNumber(27)
  set tval($fixnum.Int64 value) => $_setInt64(26, value);
  @$pb.TagNumber(27)
  $core.bool hasTval() => $_has(26);
  @$pb.TagNumber(27)
  void clearTval() => $_clearField(27);

  @$pb.TagNumber(28)
  $core.int get buyCountI => $_getIZ(27);
  @$pb.TagNumber(28)
  set buyCountI($core.int value) => $_setSignedInt32(27, value);
  @$pb.TagNumber(28)
  $core.bool hasBuyCountI() => $_has(27);
  @$pb.TagNumber(28)
  void clearBuyCountI() => $_clearField(28);

  @$pb.TagNumber(29)
  $core.int get buyCountN => $_getIZ(28);
  @$pb.TagNumber(29)
  set buyCountN($core.int value) => $_setSignedInt32(28, value);
  @$pb.TagNumber(29)
  $core.bool hasBuyCountN() => $_has(28);
  @$pb.TagNumber(29)
  void clearBuyCountN() => $_clearField(29);

  @$pb.TagNumber(30)
  $core.int get sellCountI => $_getIZ(29);
  @$pb.TagNumber(30)
  set sellCountI($core.int value) => $_setSignedInt32(29, value);
  @$pb.TagNumber(30)
  $core.bool hasSellCountI() => $_has(29);
  @$pb.TagNumber(30)
  void clearSellCountI() => $_clearField(30);

  @$pb.TagNumber(31)
  $core.int get sellCountN => $_getIZ(30);
  @$pb.TagNumber(31)
  set sellCountN($core.int value) => $_setSignedInt32(30, value);
  @$pb.TagNumber(31)
  $core.bool hasSellCountN() => $_has(30);
  @$pb.TagNumber(31)
  void clearSellCountN() => $_clearField(31);

  @$pb.TagNumber(32)
  $fixnum.Int64 get buyIVolume => $_getI64(31);
  @$pb.TagNumber(32)
  set buyIVolume($fixnum.Int64 value) => $_setInt64(31, value);
  @$pb.TagNumber(32)
  $core.bool hasBuyIVolume() => $_has(31);
  @$pb.TagNumber(32)
  void clearBuyIVolume() => $_clearField(32);

  @$pb.TagNumber(33)
  $fixnum.Int64 get buyNVolume => $_getI64(32);
  @$pb.TagNumber(33)
  set buyNVolume($fixnum.Int64 value) => $_setInt64(32, value);
  @$pb.TagNumber(33)
  $core.bool hasBuyNVolume() => $_has(32);
  @$pb.TagNumber(33)
  void clearBuyNVolume() => $_clearField(33);

  @$pb.TagNumber(34)
  $fixnum.Int64 get sellIVolume => $_getI64(33);
  @$pb.TagNumber(34)
  set sellIVolume($fixnum.Int64 value) => $_setInt64(33, value);
  @$pb.TagNumber(34)
  $core.bool hasSellIVolume() => $_has(33);
  @$pb.TagNumber(34)
  void clearSellIVolume() => $_clearField(34);

  @$pb.TagNumber(35)
  $fixnum.Int64 get sellNVolume => $_getI64(34);
  @$pb.TagNumber(35)
  set sellNVolume($fixnum.Int64 value) => $_setInt64(34, value);
  @$pb.TagNumber(35)
  $core.bool hasSellNVolume() => $_has(34);
  @$pb.TagNumber(35)
  void clearSellNVolume() => $_clearField(35);

  @$pb.TagNumber(36)
  $pb.PbList<OrderBookLevel> get orderLevels => $_getList(35);
}

class StockData extends $pb.GeneratedMessage {
  factory StockData({
    $core.Iterable<StockItem>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  StockData._();

  factory StockData.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory StockData.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StockData', package: const $pb.PackageName(_omitMessageNames ? '' : 'market'), createEmptyInstance: create)
    ..pc<StockItem>(1, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: StockItem.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StockData clone() => StockData()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StockData copyWith(void Function(StockData) updates) => super.copyWith((message) => updates(message as StockData)) as StockData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StockData create() => StockData._();
  @$core.override
  StockData createEmptyInstance() => create();
  static $pb.PbList<StockData> createRepeated() => $pb.PbList<StockData>();
  @$core.pragma('dart2js:noInline')
  static StockData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StockData>(create);
  static StockData? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<StockItem> get items => $_getList(0);
}


const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
