import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _dataCollectionAgreementKey =
      'data_collection_agreement_accepted';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get hasAcceptedDataCollection =>
      _prefs.getBool(_dataCollectionAgreementKey) ?? false;

  Future<void> acceptDataCollection() async {
    await _prefs.setBool(_dataCollectionAgreementKey, true);
  }

  Future<void> resetDataCollectionAgreement() async {
    await _prefs.remove(_dataCollectionAgreementKey);
  }
}
