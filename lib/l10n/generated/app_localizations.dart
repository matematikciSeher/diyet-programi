import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diyet Programı'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get navHome;

  /// No description provided for @navDiary.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get navDiary;

  /// No description provided for @navPlans.
  ///
  /// In tr, this message translates to:
  /// **'Planlar'**
  String get navPlans;

  /// No description provided for @navProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @featureDashboard.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get featureDashboard;

  /// No description provided for @featureNutrition.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme Planı'**
  String get featureNutrition;

  /// No description provided for @featureDiary.
  ///
  /// In tr, this message translates to:
  /// **'Öğün Günlüğü'**
  String get featureDiary;

  /// No description provided for @featureFoodSearch.
  ///
  /// In tr, this message translates to:
  /// **'Yemek Ara'**
  String get featureFoodSearch;

  /// No description provided for @featureRecipes.
  ///
  /// In tr, this message translates to:
  /// **'Tarifler'**
  String get featureRecipes;

  /// No description provided for @featureMealPlans.
  ///
  /// In tr, this message translates to:
  /// **'Yemek Planı'**
  String get featureMealPlans;

  /// No description provided for @featureShoppingList.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş Listesi'**
  String get featureShoppingList;

  /// No description provided for @featureWater.
  ///
  /// In tr, this message translates to:
  /// **'Su Takibi'**
  String get featureWater;

  /// No description provided for @featureWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo Takibi'**
  String get featureWeight;

  /// No description provided for @featureMeasurements.
  ///
  /// In tr, this message translates to:
  /// **'Vücut Ölçümleri'**
  String get featureMeasurements;

  /// No description provided for @featureProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get featureProgress;

  /// No description provided for @featureFasting.
  ///
  /// In tr, this message translates to:
  /// **'Aralıklı Oruç'**
  String get featureFasting;

  /// No description provided for @featureActivity.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite'**
  String get featureActivity;

  /// No description provided for @featureNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get featureNotifications;

  /// No description provided for @featureAiCoach.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme Asistanı'**
  String get featureAiCoach;

  /// No description provided for @featureBarcode.
  ///
  /// In tr, this message translates to:
  /// **'Barkod Tara'**
  String get featureBarcode;

  /// No description provided for @featureProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get featureProfile;

  /// No description provided for @featurePremium.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get featurePremium;

  /// No description provided for @featureSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get featureSettings;

  /// No description provided for @featurePersonalInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Bilgiler'**
  String get featurePersonalInfo;

  /// No description provided for @personalInfoSaved.
  ///
  /// In tr, this message translates to:
  /// **'Bilgilerin kaydedildi.'**
  String get personalInfoSaved;

  /// No description provided for @personalInfoEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil bilgisi yok'**
  String get personalInfoEmptyTitle;

  /// No description provided for @personalInfoEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hedeflerin ve tercihlerin burada toplanır. Onboarding’i tamamladığında bu alanlar dolar.'**
  String get personalInfoEmptyMessage;

  /// No description provided for @personalInfoBasics.
  ///
  /// In tr, this message translates to:
  /// **'Temel bilgiler'**
  String get personalInfoBasics;

  /// No description provided for @personalInfoPreferences.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme tercihleri'**
  String get personalInfoPreferences;

  /// No description provided for @personalInfoTargetsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hedefler'**
  String get personalInfoTargetsTitle;

  /// No description provided for @personalInfoTargetsHint.
  ///
  /// In tr, this message translates to:
  /// **'Kalori ve makro hedefleri profilinden okunur; Beslenme Planı bunları ayrı saklamaz.'**
  String get personalInfoTargetsHint;

  /// No description provided for @personalInfoCurrentWeightHint.
  ///
  /// In tr, this message translates to:
  /// **'Güncel kilo Kilo Takibi ekranından güncellenir.'**
  String get personalInfoCurrentWeightHint;

  /// No description provided for @personalInfoOpenWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo takibine git'**
  String get personalInfoOpenWeight;

  /// No description provided for @personalInfoRecalculate.
  ///
  /// In tr, this message translates to:
  /// **'Hedefleri yeniden hesapla'**
  String get personalInfoRecalculate;

  /// No description provided for @personalInfoTargetsUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Kalori ve makro hedeflerin güncellendi.'**
  String get personalInfoTargetsUpdated;

  /// No description provided for @personalInfoPlanUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme planın yeni tercihlerinle güncellendi.'**
  String get personalInfoPlanUpdated;

  /// No description provided for @personalInfoName.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get personalInfoName;

  /// No description provided for @personalInfoAge.
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get personalInfoAge;

  /// No description provided for @personalInfoHeight.
  ///
  /// In tr, this message translates to:
  /// **'Boy'**
  String get personalInfoHeight;

  /// No description provided for @personalInfoTargetWeight.
  ///
  /// In tr, this message translates to:
  /// **'Hedef kilo'**
  String get personalInfoTargetWeight;

  /// No description provided for @personalInfoWaterGoal.
  ///
  /// In tr, this message translates to:
  /// **'Günlük su hedefi'**
  String get personalInfoWaterGoal;

  /// No description provided for @onboardingHeadline.
  ///
  /// In tr, this message translates to:
  /// **'Size özel beslenme planı'**
  String get onboardingHeadline;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedeflerinize, yaşam tarzınıza ve damak tadınıza göre hazırlanan bir plan ile başlayın.'**
  String get onboardingSubtitle;

  /// No description provided for @signInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza giriş yapın'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İlerlemeniz tüm cihazlarınızda güvenle saklanır.'**
  String get signInSubtitle;

  /// No description provided for @dashboardGreeting.
  ///
  /// In tr, this message translates to:
  /// **'{period, select, morning{Günaydın} afternoon{İyi günler} evening{İyi akşamlar} other{Merhaba}} 👋'**
  String dashboardGreeting(String period);

  /// No description provided for @dashboardGreetingNamed.
  ///
  /// In tr, this message translates to:
  /// **'{period, select, morning{Günaydın} afternoon{İyi günler} evening{İyi akşamlar} other{Merhaba}}, {name} 👋'**
  String dashboardGreetingNamed(String period, String name);

  /// No description provided for @dashboardMotivation.
  ///
  /// In tr, this message translates to:
  /// **'{index, select, 0{Küçük adımlar büyük farklar yaratır.} 1{Bugün tabağının yarısını sebzeyle doldurmayı dene.} 2{Su şişen yanında olsun; susamadan iç.} 3{Mükemmel değil, istikrarlı olmak kazandırır.} 4{Proteinli bir kahvaltı güne dengeli başlatır.} 5{Yavaş ye; tokluk hissi yaklaşık 20 dakikada gelir.} other{Dünkü seninle yarış, başkalarıyla değil.}}'**
  String dashboardMotivation(String index);

  /// No description provided for @dashboardCaloriesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kalori'**
  String get dashboardCaloriesTitle;

  /// No description provided for @dashboardKcalOfTarget.
  ///
  /// In tr, this message translates to:
  /// **'{consumed} / {target} kcal'**
  String dashboardKcalOfTarget(String consumed, String target);

  /// No description provided for @dashboardKcalLeft.
  ///
  /// In tr, this message translates to:
  /// **'kcal kaldı'**
  String get dashboardKcalLeft;

  /// No description provided for @dashboardKcalOver.
  ///
  /// In tr, this message translates to:
  /// **'kcal fazla'**
  String get dashboardKcalOver;

  /// No description provided for @dashboardEaten.
  ///
  /// In tr, this message translates to:
  /// **'Alınan'**
  String get dashboardEaten;

  /// No description provided for @dashboardTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get dashboardTarget;

  /// No description provided for @dashboardRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Kalan'**
  String get dashboardRemaining;

  /// No description provided for @kcalValue.
  ///
  /// In tr, this message translates to:
  /// **'{value} kcal'**
  String kcalValue(String value);

  /// No description provided for @gramsOfTarget.
  ///
  /// In tr, this message translates to:
  /// **'{value} / {target} g'**
  String gramsOfTarget(String value, String target);

  /// No description provided for @macroSummaryShort.
  ///
  /// In tr, this message translates to:
  /// **'P {protein} g · K {carbs} g · Y {fat} g'**
  String macroSummaryShort(String protein, String carbs, String fat);

  /// No description provided for @dashboardQuickActions.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı ekle'**
  String get dashboardQuickActions;

  /// No description provided for @quickAddFood.
  ///
  /// In tr, this message translates to:
  /// **'Yemek ekle'**
  String get quickAddFood;

  /// No description provided for @quickAddPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafla'**
  String get quickAddPhoto;

  /// No description provided for @quickAddBarcode.
  ///
  /// In tr, this message translates to:
  /// **'Barkod tara'**
  String get quickAddBarcode;

  /// No description provided for @quickAddVoice.
  ///
  /// In tr, this message translates to:
  /// **'Sesle ekle'**
  String get quickAddVoice;

  /// No description provided for @dashboardMealsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün öğünleri'**
  String get dashboardMealsTitle;

  /// No description provided for @mealBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In tr, this message translates to:
  /// **'Atıştırmalık'**
  String get mealSnack;

  /// No description provided for @mealEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir şey eklenmedi'**
  String get mealEmpty;

  /// No description provided for @mealAddFoodTo.
  ///
  /// In tr, this message translates to:
  /// **'{meal} öğününe yemek ekle'**
  String mealAddFoodTo(String meal);

  /// No description provided for @mealMoreItems.
  ///
  /// In tr, this message translates to:
  /// **'+{count} yiyecek daha'**
  String mealMoreItems(int count);

  /// No description provided for @actionSeeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get actionSeeAll;

  /// No description provided for @actionUndo.
  ///
  /// In tr, this message translates to:
  /// **'Geri al'**
  String get actionUndo;

  /// No description provided for @dashboardWaterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get dashboardWaterTitle;

  /// No description provided for @waterGlassesProgress.
  ///
  /// In tr, this message translates to:
  /// **'{count} / {goal} bardak'**
  String waterGlassesProgress(int count, int goal);

  /// No description provided for @litersOfTarget.
  ///
  /// In tr, this message translates to:
  /// **'{value} / {target} L'**
  String litersOfTarget(String value, String target);

  /// No description provided for @waterAddAmount.
  ///
  /// In tr, this message translates to:
  /// **'+{ml} ml'**
  String waterAddAmount(int ml);

  /// No description provided for @waterAdded.
  ///
  /// In tr, this message translates to:
  /// **'{ml} ml su eklendi'**
  String waterAdded(int ml);

  /// No description provided for @waterGoalReached.
  ///
  /// In tr, this message translates to:
  /// **'Günlük su hedefine ulaştın!'**
  String get waterGoalReached;

  /// No description provided for @dashboardActivityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite'**
  String get dashboardActivityTitle;

  /// No description provided for @activitySteps.
  ///
  /// In tr, this message translates to:
  /// **'Adım'**
  String get activitySteps;

  /// No description provided for @activityActiveKcal.
  ///
  /// In tr, this message translates to:
  /// **'Aktif kalori'**
  String get activityActiveKcal;

  /// No description provided for @activityExercise.
  ///
  /// In tr, this message translates to:
  /// **'Egzersiz'**
  String get activityExercise;

  /// No description provided for @minutesValue.
  ///
  /// In tr, this message translates to:
  /// **'{value} dk'**
  String minutesValue(String value);

  /// No description provided for @stepsGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedef {goal}'**
  String stepsGoal(String goal);

  /// No description provided for @dashboardScoreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük beslenme skoru'**
  String get dashboardScoreTitle;

  /// No description provided for @scoreOutOf.
  ///
  /// In tr, this message translates to:
  /// **'/ 100'**
  String get scoreOutOf;

  /// No description provided for @scoreBandStarting.
  ///
  /// In tr, this message translates to:
  /// **'Güne başlıyoruz'**
  String get scoreBandStarting;

  /// No description provided for @scoreBandFair.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirilebilir'**
  String get scoreBandFair;

  /// No description provided for @scoreBandGood.
  ///
  /// In tr, this message translates to:
  /// **'İyi gidiyorsun'**
  String get scoreBandGood;

  /// No description provided for @scoreBandGreat.
  ///
  /// In tr, this message translates to:
  /// **'Harika gidiyorsun'**
  String get scoreBandGreat;

  /// No description provided for @scoreFactorCalories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori hedefine yakınlık'**
  String get scoreFactorCalories;

  /// No description provided for @scoreFactorProtein.
  ///
  /// In tr, this message translates to:
  /// **'Protein hedefi'**
  String get scoreFactorProtein;

  /// No description provided for @scoreFactorFiber.
  ///
  /// In tr, this message translates to:
  /// **'Lif'**
  String get scoreFactorFiber;

  /// No description provided for @scoreFactorWater.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get scoreFactorWater;

  /// No description provided for @scoreFactorProduce.
  ///
  /// In tr, this message translates to:
  /// **'Sebze ve meyve'**
  String get scoreFactorProduce;

  /// No description provided for @scoreFactorProcessed.
  ///
  /// In tr, this message translates to:
  /// **'İşlenmiş gıda oranı'**
  String get scoreFactorProcessed;

  /// No description provided for @scoreFactorMealRhythm.
  ///
  /// In tr, this message translates to:
  /// **'Öğün düzeni'**
  String get scoreFactorMealRhythm;

  /// No description provided for @scoreTipCalories.
  ///
  /// In tr, this message translates to:
  /// **'Hedefine yaklaşmak için dengeli bir öğün ekleyebilirsin.'**
  String get scoreTipCalories;

  /// No description provided for @scoreTipProtein.
  ///
  /// In tr, this message translates to:
  /// **'Bir sonraki öğününe bir protein kaynağı eklemeyi dene.'**
  String get scoreTipProtein;

  /// No description provided for @scoreTipFiber.
  ///
  /// In tr, this message translates to:
  /// **'Tam tahıl, baklagil ve sebzeyle lif alımını artırabilirsin.'**
  String get scoreTipFiber;

  /// No description provided for @scoreTipWater.
  ///
  /// In tr, this message translates to:
  /// **'Bir bardak su içmek için iyi bir an.'**
  String get scoreTipWater;

  /// No description provided for @scoreTipProduce.
  ///
  /// In tr, this message translates to:
  /// **'Bir porsiyon sebze ya da meyve eklemeyi dene.'**
  String get scoreTipProduce;

  /// No description provided for @scoreTipProcessed.
  ///
  /// In tr, this message translates to:
  /// **'Paketli atıştırmalıklar yerine doğal seçenekleri tercih et.'**
  String get scoreTipProcessed;

  /// No description provided for @scoreTipMealRhythm.
  ///
  /// In tr, this message translates to:
  /// **'Öğünlerini düzenli kaydetmek dengeyi kolaylaştırır.'**
  String get scoreTipMealRhythm;

  /// No description provided for @scorePoints.
  ///
  /// In tr, this message translates to:
  /// **'{points} / {max}'**
  String scorePoints(String points, int max);

  /// No description provided for @scoreDetails.
  ///
  /// In tr, this message translates to:
  /// **'Skor nasıl hesaplanır?'**
  String get scoreDetails;

  /// No description provided for @scoreDisclaimerShort.
  ///
  /// In tr, this message translates to:
  /// **'Genel bir alışkanlık göstergesidir, tıbbi teşhis değildir.'**
  String get scoreDisclaimerShort;

  /// No description provided for @scoreDisclaimerLong.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme skoru; kalori hedefine yakınlık, protein, lif, su, sebze-meyve tüketimi, işlenmiş gıda oranı, makro dengesi ve öğün düzenine göre hesaplanan genel bir göstergedir. Bilimsel bir tıbbi değerlendirme ya da teşhis değildir. Sağlığınla ilgili kararlar için doktoruna veya diyetisyenine danış.'**
  String get scoreDisclaimerLong;

  /// No description provided for @dashboardPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün planı'**
  String get dashboardPlanTitle;

  /// No description provided for @planLogged.
  ///
  /// In tr, this message translates to:
  /// **'Eklendi'**
  String get planLogged;

  /// No description provided for @planEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bugün için planlanmış öğün yok.'**
  String get planEmpty;

  /// No description provided for @planCreate.
  ///
  /// In tr, this message translates to:
  /// **'Plan oluştur'**
  String get planCreate;

  /// No description provided for @planTodayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün için planım'**
  String get planTodayTitle;

  /// No description provided for @planDayTotal.
  ///
  /// In tr, this message translates to:
  /// **'{kcal} / {target} kcal'**
  String planDayTotal(String kcal, String target);

  /// No description provided for @planApproxNote.
  ///
  /// In tr, this message translates to:
  /// **'Besin değerleri yaklaşıktır; tarif ve porsiyona göre değişebilir.'**
  String get planApproxNote;

  /// No description provided for @planPortion.
  ///
  /// In tr, this message translates to:
  /// **'{factor} porsiyon'**
  String planPortion(String factor);

  /// No description provided for @planSwapMeal.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get planSwapMeal;

  /// No description provided for @planLogMeal.
  ///
  /// In tr, this message translates to:
  /// **'Günlüğe ekle'**
  String get planLogMeal;

  /// No description provided for @planMealLogged.
  ///
  /// In tr, this message translates to:
  /// **'{meal} günlüğe eklendi'**
  String planMealLogged(String meal);

  /// No description provided for @planMealSwapped.
  ///
  /// In tr, this message translates to:
  /// **'{meal} için yeni öneri: {title}'**
  String planMealSwapped(String meal, String title);

  /// No description provided for @planRegenerate.
  ///
  /// In tr, this message translates to:
  /// **'Planı yenile'**
  String get planRegenerate;

  /// No description provided for @planAssistantName.
  ///
  /// In tr, this message translates to:
  /// **'Plan asistanı'**
  String get planAssistantName;

  /// No description provided for @planChangeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu planı değiştir'**
  String get planChangeTitle;

  /// No description provided for @planChangeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sevmediğin bir şey mi var? Yaz, alternatif hazırlayayım.'**
  String get planChangeSubtitle;

  /// No description provided for @planChangeHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Tavuğu sevmiyorum'**
  String get planChangeHint;

  /// No description provided for @planChangeSend.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get planChangeSend;

  /// No description provided for @planSuggestionDislike.
  ///
  /// In tr, this message translates to:
  /// **'Tavuğu sevmiyorum'**
  String get planSuggestionDislike;

  /// No description provided for @planSuggestionSwapDinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam yemeğini değiştir'**
  String get planSuggestionSwapDinner;

  /// No description provided for @planSuggestionNoEggBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltıda yumurta olmasın'**
  String get planSuggestionNoEggBreakfast;

  /// No description provided for @planSuggestionFish.
  ///
  /// In tr, this message translates to:
  /// **'Akşam balık olsun'**
  String get planSuggestionFish;

  /// No description provided for @planSuggestionWholePlan.
  ///
  /// In tr, this message translates to:
  /// **'Bu planı değiştir'**
  String get planSuggestionWholePlan;

  /// No description provided for @planReplyExcluded.
  ///
  /// In tr, this message translates to:
  /// **'Şu öğünleri {ingredients} içermeyen alternatiflerle değiştirdim:'**
  String planReplyExcluded(String ingredients);

  /// No description provided for @planReplyChangeLine.
  ///
  /// In tr, this message translates to:
  /// **'{meal}: {from} → {to}'**
  String planReplyChangeLine(String meal, String from, String to);

  /// No description provided for @planReplyAlreadyAbsent.
  ///
  /// In tr, this message translates to:
  /// **'Planında zaten {ingredients} yok.'**
  String planReplyAlreadyAbsent(String ingredients);

  /// No description provided for @planReplyRemembered.
  ///
  /// In tr, this message translates to:
  /// **'Bundan sonraki planlarda {ingredients} önermeyeceğim.'**
  String planReplyRemembered(String ingredients);

  /// No description provided for @planReplyNoAlternative.
  ///
  /// In tr, this message translates to:
  /// **'{meal} için tercihlerine uyan başka bir öneri bulamadım.'**
  String planReplyNoAlternative(String meal);

  /// No description provided for @planReplyDiet.
  ///
  /// In tr, this message translates to:
  /// **'Planı güncelledim ({diet}):'**
  String planReplyDiet(String diet);

  /// No description provided for @planReplyDietUnchanged.
  ///
  /// In tr, this message translates to:
  /// **'Planın zaten buna uygun ({diet}).'**
  String planReplyDietUnchanged(String diet);

  /// No description provided for @planReplyPreferred.
  ///
  /// In tr, this message translates to:
  /// **'İstediğin gibi {ingredients} içeren bir öğün ekledim:'**
  String planReplyPreferred(String ingredients);

  /// No description provided for @planReplyAlreadyPresent.
  ///
  /// In tr, this message translates to:
  /// **'Planında zaten {ingredients} var: {meals}.'**
  String planReplyAlreadyPresent(String ingredients, String meals);

  /// No description provided for @planReplyPreferredNone.
  ///
  /// In tr, this message translates to:
  /// **'Tercihlerine uyan ve {ingredients} içeren bir öneri bulamadım.'**
  String planReplyPreferredNone(String ingredients);

  /// No description provided for @planReplySwapped.
  ///
  /// In tr, this message translates to:
  /// **'Yeni önerilerim:'**
  String get planReplySwapped;

  /// No description provided for @planReplyRegenerated.
  ///
  /// In tr, this message translates to:
  /// **'Senin için yeni bir günlük plan hazırladım.'**
  String get planReplyRegenerated;

  /// No description provided for @planReplyNotUnderstood.
  ///
  /// In tr, this message translates to:
  /// **'Tam anlayamadım. Örneğin \"Tavuğu sevmiyorum\", \"Akşam yemeğini değiştir\" ya da \"Kahvaltıda yumurta olmasın\" yazabilirsin.'**
  String get planReplyNotUnderstood;

  /// No description provided for @planIngredientChicken.
  ///
  /// In tr, this message translates to:
  /// **'tavuk'**
  String get planIngredientChicken;

  /// No description provided for @planIngredientRedMeat.
  ///
  /// In tr, this message translates to:
  /// **'kırmızı et'**
  String get planIngredientRedMeat;

  /// No description provided for @planIngredientFish.
  ///
  /// In tr, this message translates to:
  /// **'balık'**
  String get planIngredientFish;

  /// No description provided for @planIngredientShellfish.
  ///
  /// In tr, this message translates to:
  /// **'karides ve midye'**
  String get planIngredientShellfish;

  /// No description provided for @planIngredientEgg.
  ///
  /// In tr, this message translates to:
  /// **'yumurta'**
  String get planIngredientEgg;

  /// No description provided for @planIngredientMilk.
  ///
  /// In tr, this message translates to:
  /// **'süt'**
  String get planIngredientMilk;

  /// No description provided for @planIngredientCheese.
  ///
  /// In tr, this message translates to:
  /// **'peynir'**
  String get planIngredientCheese;

  /// No description provided for @planIngredientYogurt.
  ///
  /// In tr, this message translates to:
  /// **'yoğurt'**
  String get planIngredientYogurt;

  /// No description provided for @planIngredientLegumes.
  ///
  /// In tr, this message translates to:
  /// **'baklagil'**
  String get planIngredientLegumes;

  /// No description provided for @planIngredientGluten.
  ///
  /// In tr, this message translates to:
  /// **'gluten'**
  String get planIngredientGluten;

  /// No description provided for @planIngredientOats.
  ///
  /// In tr, this message translates to:
  /// **'yulaf'**
  String get planIngredientOats;

  /// No description provided for @planIngredientNuts.
  ///
  /// In tr, this message translates to:
  /// **'kuruyemiş'**
  String get planIngredientNuts;

  /// No description provided for @planIngredientPeanut.
  ///
  /// In tr, this message translates to:
  /// **'yer fıstığı'**
  String get planIngredientPeanut;

  /// No description provided for @planIngredientSesame.
  ///
  /// In tr, this message translates to:
  /// **'susam'**
  String get planIngredientSesame;

  /// No description provided for @planIngredientSoy.
  ///
  /// In tr, this message translates to:
  /// **'soya'**
  String get planIngredientSoy;

  /// No description provided for @planIngredientEggplant.
  ///
  /// In tr, this message translates to:
  /// **'patlıcan'**
  String get planIngredientEggplant;

  /// No description provided for @planIngredientMushroom.
  ///
  /// In tr, this message translates to:
  /// **'mantar'**
  String get planIngredientMushroom;

  /// No description provided for @featurePhotoLog.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafla Ekle'**
  String get featurePhotoLog;

  /// No description provided for @featureVoiceLog.
  ///
  /// In tr, this message translates to:
  /// **'Sesle Ekle'**
  String get featureVoiceLog;

  /// No description provided for @actionGetStarted.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get actionGetStarted;

  /// No description provided for @actionContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get actionContinue;

  /// No description provided for @actionContinueAsGuest.
  ///
  /// In tr, this message translates to:
  /// **'Misafir olarak devam et'**
  String get actionContinueAsGuest;

  /// No description provided for @actionSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get actionSignIn;

  /// No description provided for @actionSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluştur'**
  String get actionSignUp;

  /// No description provided for @actionForgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Parolamı unuttum'**
  String get actionForgotPassword;

  /// No description provided for @actionSignInWithGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile devam et'**
  String get actionSignInWithGoogle;

  /// No description provided for @actionSignInWithApple.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile devam et'**
  String get actionSignInWithApple;

  /// No description provided for @actionHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın var mı? Giriş yap'**
  String get actionHaveAccount;

  /// No description provided for @actionNeedAccount.
  ///
  /// In tr, this message translates to:
  /// **'Yeni misin? Hesap oluştur'**
  String get actionNeedAccount;

  /// No description provided for @actionDeleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı sil'**
  String get actionDeleteAccount;

  /// No description provided for @signInEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get signInEmailLabel;

  /// No description provided for @signInPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Parola'**
  String get signInPasswordLabel;

  /// No description provided for @signInNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ad (isteğe bağlı)'**
  String get signInNameLabel;

  /// No description provided for @signInOrDivider.
  ///
  /// In tr, this message translates to:
  /// **'veya'**
  String get signInOrDivider;

  /// No description provided for @signInGuestAccount.
  ///
  /// In tr, this message translates to:
  /// **'Misafir hesap'**
  String get signInGuestAccount;

  /// No description provided for @passwordResetSent.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta ile kayıtlı bir hesap varsa sıfırlama bağlantısı gönderilir.'**
  String get passwordResetSent;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silinsin mi?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın, buluttaki verilerin ve bu cihazdaki kişisel kayıtların silinir. Bu işlem geri alınamaz.'**
  String get deleteAccountMessage;

  /// No description provided for @authInvalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi gir.'**
  String get authInvalidEmail;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya parola hatalı.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailInUse.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta ile bir hesap zaten var.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In tr, this message translates to:
  /// **'Daha güçlü bir parola seç (en az 6 karakter).'**
  String get authWeakPassword;

  /// No description provided for @authTooManyRequests.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme. Bir süre bekleyip tekrar dene.'**
  String get authTooManyRequests;

  /// No description provided for @authCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Giriş iptal edildi.'**
  String get authCancelled;

  /// No description provided for @authRequiresRecentLogin.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı silmek için kısa süre önce giriş yapmış olman gerekiyor. Çıkış yapıp tekrar giriş yaptıktan sonra yeniden dene.'**
  String get authRequiresRecentLogin;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu giriş yöntemi henüz yapılandırılmadı.'**
  String get errorServiceUnavailable;

  /// No description provided for @actionSignOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get actionSignOut;

  /// No description provided for @actionRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get actionSave;

  /// No description provided for @actionAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get actionAdd;

  /// No description provided for @actionRemove.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get actionRemove;

  /// No description provided for @comingSoonTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In tr, this message translates to:
  /// **'{feature} bölümü hazırlanıyor.'**
  String comingSoonMessage(String feature);

  /// No description provided for @emptyStateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir şey yok'**
  String get emptyStateTitle;

  /// No description provided for @errorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti. Lütfen tekrar deneyin.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantınızı kontrol edin.'**
  String get errorNetwork;

  /// No description provided for @settingsTheme.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeDark;

  /// No description provided for @pageNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa bulunamadı'**
  String get pageNotFound;

  /// No description provided for @splashTagline.
  ///
  /// In tr, this message translates to:
  /// **'Dengeli beslen, iyi hisset'**
  String get splashTagline;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldin'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In tr, this message translates to:
  /// **'Birkaç kısa soruyla sana özel kalori ve besin hedeflerini oluşturalım. Yalnızca birkaç dakika sürer.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingBenefitPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana özel plan'**
  String get onboardingBenefitPlanTitle;

  /// No description provided for @onboardingBenefitPlanBody.
  ///
  /// In tr, this message translates to:
  /// **'Hedefine, vücuduna ve yaşam tarzına göre bilimsel formüllerle hesaplanan günlük kalori ve makro hedefleri.'**
  String get onboardingBenefitPlanBody;

  /// No description provided for @onboardingBenefitTrackingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zahmetsiz takip'**
  String get onboardingBenefitTrackingTitle;

  /// No description provided for @onboardingBenefitTrackingBody.
  ///
  /// In tr, this message translates to:
  /// **'Öğünlerini, suyunu ve kilonu saniyeler içinde kaydet; ilerlemeni net grafiklerle izle.'**
  String get onboardingBenefitTrackingBody;

  /// No description provided for @onboardingBenefitHabitsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı alışkanlıklar'**
  String get onboardingBenefitHabitsTitle;

  /// No description provided for @onboardingBenefitHabitsBody.
  ///
  /// In tr, this message translates to:
  /// **'Şok diyet yok. Sağlıklı bir tempo ve sevdiğin yiyeceklerle sürdürülebilir sonuçlar.'**
  String get onboardingBenefitHabitsBody;

  /// No description provided for @onboardingSkipIntro.
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get onboardingSkipIntro;

  /// No description provided for @onboardingBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get onboardingBack;

  /// No description provided for @onboardingNext.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In tr, this message translates to:
  /// **'Planımı başlat'**
  String get onboardingFinish;

  /// No description provided for @onboardingStepCounter.
  ///
  /// In tr, this message translates to:
  /// **'{current}/{total}'**
  String onboardingStepCounter(int current, int total);

  /// No description provided for @onboardingProgressSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Adım {current} / {total}'**
  String onboardingProgressSemantics(int current, int total);

  /// No description provided for @onboardingOptional.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı'**
  String get onboardingOptional;

  /// No description provided for @qNameTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana nasıl hitap edelim?'**
  String get qNameTitle;

  /// No description provided for @qNameSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Boş bırakıp devam edebilirsin.'**
  String get qNameSubtitle;

  /// No description provided for @qNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Adın'**
  String get qNameHint;

  /// No description provided for @qGoalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ana hedefin ne?'**
  String get qGoalTitle;

  /// No description provided for @qGoalSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Planını bu hedefe göre şekillendireceğiz.'**
  String get qGoalSubtitle;

  /// No description provided for @goalLoseWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo vermek'**
  String get goalLoseWeight;

  /// No description provided for @goalLoseWeightDesc.
  ///
  /// In tr, this message translates to:
  /// **'Sağlıklı ve kontrollü bir kalori açığıyla'**
  String get goalLoseWeightDesc;

  /// No description provided for @goalMaintainWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo korumak'**
  String get goalMaintainWeight;

  /// No description provided for @goalMaintainWeightDesc.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kilonda dengede kal'**
  String get goalMaintainWeightDesc;

  /// No description provided for @goalGainWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo almak'**
  String get goalGainWeight;

  /// No description provided for @goalGainWeightDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kademeli ve sağlıklı şekilde'**
  String get goalGainWeightDesc;

  /// No description provided for @goalBuildMuscle.
  ///
  /// In tr, this message translates to:
  /// **'Kas geliştirmek'**
  String get goalBuildMuscle;

  /// No description provided for @goalBuildMuscleDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek protein, ölçülü kalori fazlası'**
  String get goalBuildMuscleDesc;

  /// No description provided for @goalEatHealthier.
  ///
  /// In tr, this message translates to:
  /// **'Daha sağlıklı beslenmek'**
  String get goalEatHealthier;

  /// No description provided for @goalEatHealthierDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kalite, çeşitlilik ve denge odaklı'**
  String get goalEatHealthierDesc;

  /// No description provided for @qGenderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyetin?'**
  String get qGenderTitle;

  /// No description provided for @qGenderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bazal metabolizma hızı hesaplamasında kullanılır.'**
  String get qGenderSubtitle;

  /// No description provided for @genderFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get genderMale;

  /// No description provided for @genderUnspecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtmek istemiyorum'**
  String get genderUnspecified;

  /// No description provided for @genderUnspecifiedDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplamada iki değerin ortalaması kullanılır'**
  String get genderUnspecifiedDesc;

  /// No description provided for @qAgeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaç yaşındasın?'**
  String get qAgeTitle;

  /// No description provided for @qAgeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaş, günlük enerji ihtiyacını etkiler.'**
  String get qAgeSubtitle;

  /// No description provided for @unitYears.
  ///
  /// In tr, this message translates to:
  /// **'yaş'**
  String get unitYears;

  /// No description provided for @qHeightTitle.
  ///
  /// In tr, this message translates to:
  /// **'Boyun kaç?'**
  String get qHeightTitle;

  /// No description provided for @qHeightSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Santimetre cinsinden gir.'**
  String get qHeightSubtitle;

  /// No description provided for @unitCm.
  ///
  /// In tr, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @qWeightTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şu anki kilon kaç?'**
  String get qWeightTitle;

  /// No description provided for @qWeightSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sabah aç karnına ölçülen değer en doğrusudur.'**
  String get qWeightSubtitle;

  /// No description provided for @unitKg.
  ///
  /// In tr, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @qTargetWeightTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedef kilon kaç?'**
  String get qTargetWeightTitle;

  /// No description provided for @qTargetWeightSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gerçekçi bir hedef motivasyonunu korur.'**
  String get qTargetWeightSubtitle;

  /// No description provided for @targetWeightCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Şu anki kilon: {weight} kg'**
  String targetWeightCurrent(String weight);

  /// No description provided for @targetWeightDiff.
  ///
  /// In tr, this message translates to:
  /// **'Fark: {diff} kg'**
  String targetWeightDiff(String diff);

  /// No description provided for @targetWeightHealthyMin.
  ///
  /// In tr, this message translates to:
  /// **'Boyuna göre sağlıklı alt sınır: {weight} kg'**
  String targetWeightHealthyMin(String weight);

  /// No description provided for @inputRangeHint.
  ///
  /// In tr, this message translates to:
  /// **'{min}–{max} {unit}'**
  String inputRangeHint(String min, String max, String unit);

  /// No description provided for @qActivityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük aktivite seviyen?'**
  String get qActivityTitle;

  /// No description provided for @qActivitySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İşini ve gün içindeki genel hareketliliğini düşün.'**
  String get qActivitySubtitle;

  /// No description provided for @activitySedentary.
  ///
  /// In tr, this message translates to:
  /// **'Hareketsiz'**
  String get activitySedentary;

  /// No description provided for @activitySedentaryDesc.
  ///
  /// In tr, this message translates to:
  /// **'Masa başı iş, çok az yürüyüş'**
  String get activitySedentaryDesc;

  /// No description provided for @activityLight.
  ///
  /// In tr, this message translates to:
  /// **'Az aktif'**
  String get activityLight;

  /// No description provided for @activityLightDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hafif hareket, gün içinde biraz yürüyüş'**
  String get activityLightDesc;

  /// No description provided for @activityModerate.
  ///
  /// In tr, this message translates to:
  /// **'Orta aktif'**
  String get activityModerate;

  /// No description provided for @activityModerateDesc.
  ///
  /// In tr, this message translates to:
  /// **'Gün boyu ayakta ya da düzenli hareket halinde'**
  String get activityModerateDesc;

  /// No description provided for @activityActive.
  ///
  /// In tr, this message translates to:
  /// **'Çok aktif'**
  String get activityActive;

  /// No description provided for @activityActiveDesc.
  ///
  /// In tr, this message translates to:
  /// **'Fiziksel iş veya yoğun günlük hareket'**
  String get activityActiveDesc;

  /// No description provided for @activityVeryActive.
  ///
  /// In tr, this message translates to:
  /// **'Çok yoğun aktif'**
  String get activityVeryActive;

  /// No description provided for @activityVeryActiveDesc.
  ///
  /// In tr, this message translates to:
  /// **'Ağır fiziksel iş veya günde iki antrenman'**
  String get activityVeryActiveDesc;

  /// No description provided for @qExerciseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne sıklıkla egzersiz yapıyorsun?'**
  String get qExerciseTitle;

  /// No description provided for @qExerciseSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yürüyüş, spor salonu, koşu, yüzme gibi planlı egzersizler.'**
  String get qExerciseSubtitle;

  /// No description provided for @exerciseNone.
  ///
  /// In tr, this message translates to:
  /// **'Hiç ya da nadiren'**
  String get exerciseNone;

  /// No description provided for @exerciseOneToTwo.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 1–2 gün'**
  String get exerciseOneToTwo;

  /// No description provided for @exerciseThreeToFour.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 3–4 gün'**
  String get exerciseThreeToFour;

  /// No description provided for @exerciseFiveToSix.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 5–6 gün'**
  String get exerciseFiveToSix;

  /// No description provided for @exerciseDaily.
  ///
  /// In tr, this message translates to:
  /// **'Her gün'**
  String get exerciseDaily;

  /// No description provided for @qDietTitle.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme tercihin?'**
  String get qDietTitle;

  /// No description provided for @qDietSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Önerilerimiz bu tercihe uygun olacak.'**
  String get qDietSubtitle;

  /// No description provided for @dietOmnivore.
  ///
  /// In tr, this message translates to:
  /// **'Her şeyi yerim'**
  String get dietOmnivore;

  /// No description provided for @dietOmnivoreDesc.
  ///
  /// In tr, this message translates to:
  /// **'Et, balık, süt ürünleri ve bitkisel gıdalar'**
  String get dietOmnivoreDesc;

  /// No description provided for @dietVegetarian.
  ///
  /// In tr, this message translates to:
  /// **'Vejetaryen'**
  String get dietVegetarian;

  /// No description provided for @dietVegetarianDesc.
  ///
  /// In tr, this message translates to:
  /// **'Et ve balık yok; yumurta ve süt ürünleri var'**
  String get dietVegetarianDesc;

  /// No description provided for @dietVegan.
  ///
  /// In tr, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @dietVeganDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir hayvansal ürün yok'**
  String get dietVeganDesc;

  /// No description provided for @dietPescatarian.
  ///
  /// In tr, this message translates to:
  /// **'Pesketaryen'**
  String get dietPescatarian;

  /// No description provided for @dietPescatarianDesc.
  ///
  /// In tr, this message translates to:
  /// **'Et yok; balık ve deniz ürünleri var'**
  String get dietPescatarianDesc;

  /// No description provided for @qAllergiesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alerji veya intoleransın var mı?'**
  String get qAllergiesTitle;

  /// No description provided for @qAllergiesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla seçebilirsin. Bu besinleri önerilerimizden çıkarırız.'**
  String get qAllergiesSubtitle;

  /// No description provided for @allergyNone.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get allergyNone;

  /// No description provided for @allergenGluten.
  ///
  /// In tr, this message translates to:
  /// **'Gluten'**
  String get allergenGluten;

  /// No description provided for @allergenLactose.
  ///
  /// In tr, this message translates to:
  /// **'Laktoz'**
  String get allergenLactose;

  /// No description provided for @allergenMilk.
  ///
  /// In tr, this message translates to:
  /// **'Süt proteini'**
  String get allergenMilk;

  /// No description provided for @allergenEgg.
  ///
  /// In tr, this message translates to:
  /// **'Yumurta'**
  String get allergenEgg;

  /// No description provided for @allergenPeanut.
  ///
  /// In tr, this message translates to:
  /// **'Yer fıstığı'**
  String get allergenPeanut;

  /// No description provided for @allergenTreeNuts.
  ///
  /// In tr, this message translates to:
  /// **'Kuruyemiş'**
  String get allergenTreeNuts;

  /// No description provided for @allergenSoy.
  ///
  /// In tr, this message translates to:
  /// **'Soya'**
  String get allergenSoy;

  /// No description provided for @allergenFish.
  ///
  /// In tr, this message translates to:
  /// **'Balık'**
  String get allergenFish;

  /// No description provided for @allergenShellfish.
  ///
  /// In tr, this message translates to:
  /// **'Kabuklu deniz ürünleri'**
  String get allergenShellfish;

  /// No description provided for @allergenSesame.
  ///
  /// In tr, this message translates to:
  /// **'Susam'**
  String get allergenSesame;

  /// No description provided for @allergyOtherHint.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir alerji ekle'**
  String get allergyOtherHint;

  /// No description provided for @qDislikedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sevmediğin yiyecekler var mı?'**
  String get qDislikedTitle;

  /// No description provided for @qDislikedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seç ya da kendin yaz. Boş bırakabilirsin.'**
  String get qDislikedSubtitle;

  /// No description provided for @dislikedHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. bamya'**
  String get dislikedHint;

  /// No description provided for @foodOnion.
  ///
  /// In tr, this message translates to:
  /// **'Soğan'**
  String get foodOnion;

  /// No description provided for @foodGarlic.
  ///
  /// In tr, this message translates to:
  /// **'Sarımsak'**
  String get foodGarlic;

  /// No description provided for @foodMushroom.
  ///
  /// In tr, this message translates to:
  /// **'Mantar'**
  String get foodMushroom;

  /// No description provided for @foodEggplant.
  ///
  /// In tr, this message translates to:
  /// **'Patlıcan'**
  String get foodEggplant;

  /// No description provided for @foodOffal.
  ///
  /// In tr, this message translates to:
  /// **'Sakatat'**
  String get foodOffal;

  /// No description provided for @foodSeafood.
  ///
  /// In tr, this message translates to:
  /// **'Deniz ürünleri'**
  String get foodSeafood;

  /// No description provided for @foodOlive.
  ///
  /// In tr, this message translates to:
  /// **'Zeytin'**
  String get foodOlive;

  /// No description provided for @foodSpicy.
  ///
  /// In tr, this message translates to:
  /// **'Acı'**
  String get foodSpicy;

  /// No description provided for @foodBroccoli.
  ///
  /// In tr, this message translates to:
  /// **'Brokoli'**
  String get foodBroccoli;

  /// No description provided for @foodLegumes.
  ///
  /// In tr, this message translates to:
  /// **'Baklagiller'**
  String get foodLegumes;

  /// No description provided for @foodCoriander.
  ///
  /// In tr, this message translates to:
  /// **'Kişniş'**
  String get foodCoriander;

  /// No description provided for @foodCelery.
  ///
  /// In tr, this message translates to:
  /// **'Kereviz'**
  String get foodCelery;

  /// No description provided for @qMealsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günde kaç öğün yemek istersin?'**
  String get qMealsTitle;

  /// No description provided for @qMealsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kalori hedefin öğünlerine göre paylaştırılacak.'**
  String get qMealsSubtitle;

  /// No description provided for @mealsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} öğün'**
  String mealsCount(int count);

  /// No description provided for @meals2Desc.
  ///
  /// In tr, this message translates to:
  /// **'İki doyurucu ana öğün'**
  String get meals2Desc;

  /// No description provided for @meals3Desc.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı, öğle ve akşam'**
  String get meals3Desc;

  /// No description provided for @meals4Desc.
  ///
  /// In tr, this message translates to:
  /// **'3 ana öğün + 1 ara öğün'**
  String get meals4Desc;

  /// No description provided for @meals5Desc.
  ///
  /// In tr, this message translates to:
  /// **'3 ana öğün + 2 ara öğün'**
  String get meals5Desc;

  /// No description provided for @qBreakfastTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı alışkanlığın nasıl?'**
  String get qBreakfastTitle;

  /// No description provided for @qBreakfastSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğün planını buna göre düzenleyeceğiz.'**
  String get qBreakfastSubtitle;

  /// No description provided for @breakfastAlways.
  ///
  /// In tr, this message translates to:
  /// **'Her gün kahvaltı yaparım'**
  String get breakfastAlways;

  /// No description provided for @breakfastSometimes.
  ///
  /// In tr, this message translates to:
  /// **'Bazen yaparım'**
  String get breakfastSometimes;

  /// No description provided for @breakfastNever.
  ///
  /// In tr, this message translates to:
  /// **'Genelde kahvaltı yapmam'**
  String get breakfastNever;

  /// No description provided for @qWaterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük su hedefin?'**
  String get qWaterTitle;

  /// No description provided for @qWaterSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilona ve aktivitene göre bir öneri hazırladık; dilediğin gibi ayarlayabilirsin.'**
  String get qWaterSubtitle;

  /// No description provided for @waterLiters.
  ///
  /// In tr, this message translates to:
  /// **'{liters} L'**
  String waterLiters(String liters);

  /// No description provided for @waterRecommended.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen: {liters} L'**
  String waterRecommended(String liters);

  /// No description provided for @waterUseRecommended.
  ///
  /// In tr, this message translates to:
  /// **'Öneriyi kullan'**
  String get waterUseRecommended;

  /// No description provided for @waterGlasses.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşık {count} bardak'**
  String waterGlasses(int count);

  /// No description provided for @qFastingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aralıklı oruç denemek ister misin?'**
  String get qFastingTitle;

  /// No description provided for @qFastingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tamamen isteğe bağlı; istediğin zaman değiştirebilirsin.'**
  String get qFastingSubtitle;

  /// No description provided for @fastingNone.
  ///
  /// In tr, this message translates to:
  /// **'İstemiyorum'**
  String get fastingNone;

  /// No description provided for @fastingNoneDesc.
  ///
  /// In tr, this message translates to:
  /// **'Normal öğün düzenimle devam edeceğim'**
  String get fastingNoneDesc;

  /// No description provided for @fastingWindow.
  ///
  /// In tr, this message translates to:
  /// **'{fast}:{eat}'**
  String fastingWindow(int fast, int eat);

  /// No description provided for @fastingWindowDesc.
  ///
  /// In tr, this message translates to:
  /// **'{fast} saat oruç, {eat} saat yemek penceresi'**
  String fastingWindowDesc(int fast, int eat);

  /// No description provided for @fastingCautionNote.
  ///
  /// In tr, this message translates to:
  /// **'Hamilelik, emzirme, diyabet, yeme bozukluğu öyküsü veya düzenli ilaç kullanımı varsa aralıklı oruca başlamadan önce doktoruna danış.'**
  String get fastingCautionNote;

  /// No description provided for @qTargetDateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefine ne zaman ulaşmak istersin?'**
  String get qTargetDateTitle;

  /// No description provided for @qTargetDateSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli bir tempo, kalıcı sonuç demektir.'**
  String get qTargetDateSubtitle;

  /// No description provided for @targetDateRecommended.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen güvenli tempo'**
  String get targetDateRecommended;

  /// No description provided for @targetDateRecommendedDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini {date}'**
  String targetDateRecommendedDesc(String date);

  /// No description provided for @targetDateCustom.
  ///
  /// In tr, this message translates to:
  /// **'Kendi tarihimi seçeceğim'**
  String get targetDateCustom;

  /// No description provided for @targetDateCustomPick.
  ///
  /// In tr, this message translates to:
  /// **'Takvimden seç'**
  String get targetDateCustomPick;

  /// No description provided for @targetDateTooSoon.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarih için haftada {required} kg değişim gerekir. Güvenli üst sınır {max} kg olduğundan planın güvenli tempoya göre hazırlanacak.'**
  String targetDateTooSoon(String required, String max);

  /// No description provided for @errorSelectOption.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için bir seçenek belirle.'**
  String get errorSelectOption;

  /// No description provided for @errorValueRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir değer gir.'**
  String get errorValueRequired;

  /// No description provided for @errorOutOfRange.
  ///
  /// In tr, this message translates to:
  /// **'{min} ile {max} arasında bir değer gir.'**
  String errorOutOfRange(String min, String max);

  /// No description provided for @errorTargetBelowCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Kilo verme hedefinde hedef kilon şu anki kilondan düşük olmalı.'**
  String get errorTargetBelowCurrent;

  /// No description provided for @errorTargetAboveCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Bu hedef için hedef kilon şu anki kilondan yüksek olmalı.'**
  String get errorTargetAboveCurrent;

  /// No description provided for @errorTargetBelowHealthy.
  ///
  /// In tr, this message translates to:
  /// **'Bu hedef boyuna göre sağlıklı aralığın altında. En az {min} kg olmalı.'**
  String errorTargetBelowHealthy(String min);

  /// No description provided for @errorTargetDatePast.
  ///
  /// In tr, this message translates to:
  /// **'Hedef tarih bugünden sonra olmalı.'**
  String get errorTargetDatePast;

  /// No description provided for @summaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Planın hazır'**
  String get summaryTitle;

  /// No description provided for @summaryTitleNamed.
  ///
  /// In tr, this message translates to:
  /// **'{name}, planın hazır'**
  String summaryTitleNamed(String name);

  /// No description provided for @summarySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Verdiğin bilgilere göre hesapladığımız günlük hedeflerin:'**
  String get summarySubtitle;

  /// No description provided for @summaryDailyTarget.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen günlük kalori'**
  String get summaryDailyTarget;

  /// No description provided for @summaryKcalPerDay.
  ///
  /// In tr, this message translates to:
  /// **'kcal / gün'**
  String get summaryKcalPerDay;

  /// No description provided for @summaryMaintenance.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini günlük ihtiyacın: {kcal} kcal'**
  String summaryMaintenance(String kcal);

  /// No description provided for @summaryDeficit.
  ///
  /// In tr, this message translates to:
  /// **'{kcal} kcal açık'**
  String summaryDeficit(String kcal);

  /// No description provided for @summarySurplus.
  ///
  /// In tr, this message translates to:
  /// **'{kcal} kcal fazla'**
  String summarySurplus(String kcal);

  /// No description provided for @summaryBalanced.
  ///
  /// In tr, this message translates to:
  /// **'Enerji dengesi'**
  String get summaryBalanced;

  /// No description provided for @macroProtein.
  ///
  /// In tr, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In tr, this message translates to:
  /// **'Karbonhidrat'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In tr, this message translates to:
  /// **'Yağ'**
  String get macroFat;

  /// No description provided for @gramsValue.
  ///
  /// In tr, this message translates to:
  /// **'{value} g'**
  String gramsValue(String value);

  /// No description provided for @summaryWater.
  ///
  /// In tr, this message translates to:
  /// **'Su hedefi'**
  String get summaryWater;

  /// No description provided for @summaryGoalDuration.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini hedef süresi'**
  String get summaryGoalDuration;

  /// No description provided for @summaryWeeks.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{~1 hafta} other{~{count} hafta}}'**
  String summaryWeeks(int count);

  /// No description provided for @summaryGoalDate.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini {date}'**
  String summaryGoalDate(String date);

  /// No description provided for @summaryWeeklyRate.
  ///
  /// In tr, this message translates to:
  /// **'Haftada yaklaşık {kg} kg'**
  String summaryWeeklyRate(String kg);

  /// No description provided for @summaryNoDurationMaintain.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin mevcut kilonu korumak; bir bitiş tarihi yok.'**
  String get summaryNoDurationMaintain;

  /// No description provided for @summaryNoDurationSlow.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli kalori sınırı nedeniyle kilo değişimi çok yavaş olacak. Günlük hareketi artırmak süreci hızlandırır.'**
  String get summaryNoDurationSlow;

  /// No description provided for @summaryMetrics.
  ///
  /// In tr, this message translates to:
  /// **'Bazal metabolizma {bmr} kcal · VKİ {bmi}'**
  String summaryMetrics(String bmr, String bmi);

  /// No description provided for @summaryFormulaNote.
  ///
  /// In tr, this message translates to:
  /// **'Mifflin-St Jeor denklemi ve aktivite katsayısıyla hesaplanmıştır.'**
  String get summaryFormulaNote;

  /// No description provided for @noticeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dikkat etmen gerekenler'**
  String get noticeTitle;

  /// No description provided for @noticeMinor.
  ///
  /// In tr, this message translates to:
  /// **'18 yaşın altındasın. Büyüme döneminde kalori kısıtlaması önerilmez; hedefin sınırlı tutuldu. Lütfen bir doktor veya diyetisyenle görüş.'**
  String get noticeMinor;

  /// No description provided for @noticeSenior.
  ///
  /// In tr, this message translates to:
  /// **'65 yaş ve üzerinde kas kaybını önlemek için yeterli protein önemlidir. Planını bir uzmanla birlikte oluşturman önerilir.'**
  String get noticeSenior;

  /// No description provided for @noticeUnderweight.
  ///
  /// In tr, this message translates to:
  /// **'Vücut kitle indeksin sağlıklı aralığın altında. Kilo vermen önerilmez; bir sağlık uzmanına danışmanı öneririz.'**
  String get noticeUnderweight;

  /// No description provided for @noticeSevereObesity.
  ///
  /// In tr, this message translates to:
  /// **'Vücut kitle indeksin yüksek. En güvenli ilerleme için doktor veya diyetisyen takibi önerilir.'**
  String get noticeSevereObesity;

  /// No description provided for @noticePaceAdjusted.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğin tarih için gereken tempo güvenli sınırın üzerinde olduğundan hedefin daha sağlıklı bir tempoya göre ayarlandı.'**
  String get noticePaceAdjusted;

  /// No description provided for @noticeCalorieFloor.
  ///
  /// In tr, this message translates to:
  /// **'Kalori hedefin güvenli alt sınırın altına inmeyecek şekilde ayarlandı.'**
  String get noticeCalorieFloor;

  /// No description provided for @noticeFasting.
  ///
  /// In tr, this message translates to:
  /// **'Profilin için aralıklı oruç ek dikkat gerektirir. Başlamadan önce doktoruna danış.'**
  String get noticeFasting;

  /// No description provided for @disclaimerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bilgilendirme'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu uygulama genel bilgilendirme amaçlıdır ve doktor veya diyetisyen önerisinin yerine geçmez. Hamilelik, emzirme, kronik hastalık (diyabet, böbrek, kalp vb.), yeme bozukluğu öyküsü ya da düzenli ilaç kullanımı gibi durumlarda beslenme planını bir sağlık profesyoneliyle birlikte oluştur.'**
  String get disclaimerBody;

  /// No description provided for @foodAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yemek ekle'**
  String get foodAddTitle;

  /// No description provided for @foodSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek, yemek veya ürün ara...'**
  String get foodSearchHint;

  /// No description provided for @foodClearSearch.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı temizle'**
  String get foodClearSearch;

  /// No description provided for @foodTabRecent.
  ///
  /// In tr, this message translates to:
  /// **'Son kullanılanlar'**
  String get foodTabRecent;

  /// No description provided for @foodTabFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get foodTabFavorites;

  /// No description provided for @foodTabMine.
  ///
  /// In tr, this message translates to:
  /// **'Benimkiler'**
  String get foodTabMine;

  /// No description provided for @foodRecentEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Eklediğin yiyecekler burada görünecek; tek dokunuşla tekrar ekleyebilirsin.'**
  String get foodRecentEmpty;

  /// No description provided for @foodFavoritesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek detayındaki kalp simgesiyle favorilerine ekleyebilirsin.'**
  String get foodFavoritesEmpty;

  /// No description provided for @foodMineEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Kendi yiyeceklerini ve tariflerini oluşturabilirsin.'**
  String get foodMineEmpty;

  /// No description provided for @foodDatabaseUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek veritabanına şu anda ulaşılamıyor.'**
  String get foodDatabaseUnavailable;

  /// No description provided for @foodDatabaseUnavailableHint.
  ///
  /// In tr, this message translates to:
  /// **'Son kullanılanlar, favoriler ve kendi yiyeceklerin çalışmaya devam eder. Çevrimiçi olunca tekrar dene veya özel yiyecek oluştur.'**
  String get foodDatabaseUnavailableHint;

  /// No description provided for @foodAttributionOff.
  ///
  /// In tr, this message translates to:
  /// **'Paketli ürün verileri Open Food Facts gönüllülerinden gelir (ODbL).'**
  String get foodAttributionOff;

  /// No description provided for @foodAttributionOffLink.
  ///
  /// In tr, this message translates to:
  /// **'Open Food Facts'**
  String get foodAttributionOffLink;

  /// No description provided for @foodAttributionOffLicense.
  ///
  /// In tr, this message translates to:
  /// **'Open Food Facts verileri ODbL kapsamında kullanılır.'**
  String get foodAttributionOffLicense;

  /// No description provided for @foodCategoryFruit.
  ///
  /// In tr, this message translates to:
  /// **'Meyve'**
  String get foodCategoryFruit;

  /// No description provided for @foodCategoryVegetable.
  ///
  /// In tr, this message translates to:
  /// **'Sebze'**
  String get foodCategoryVegetable;

  /// No description provided for @foodCategoryProtein.
  ///
  /// In tr, this message translates to:
  /// **'Protein'**
  String get foodCategoryProtein;

  /// No description provided for @foodCategoryDairy.
  ///
  /// In tr, this message translates to:
  /// **'Süt ürünleri'**
  String get foodCategoryDairy;

  /// No description provided for @foodCategoryGrain.
  ///
  /// In tr, this message translates to:
  /// **'Tahıl'**
  String get foodCategoryGrain;

  /// No description provided for @foodCategoryBeverage.
  ///
  /// In tr, this message translates to:
  /// **'İçecek'**
  String get foodCategoryBeverage;

  /// No description provided for @foodNoResults.
  ///
  /// In tr, this message translates to:
  /// **'\"{query}\" için sonuç bulunamadı'**
  String foodNoResults(String query);

  /// No description provided for @foodNoResultsHint.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir yazım dene ya da kendi yiyeceğini oluştur.'**
  String get foodNoResultsHint;

  /// No description provided for @foodCreateCustom.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek oluştur'**
  String get foodCreateCustom;

  /// No description provided for @foodCreateRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Tarif oluştur'**
  String get foodCreateRecipe;

  /// No description provided for @foodSampleDataNotice.
  ///
  /// In tr, this message translates to:
  /// **'Örnek veri: Besin değerleri {source} kayıtlarından yuvarlanmıştır; ürüne ve tarife göre farklılık gösterebilir.'**
  String foodSampleDataNotice(String source);

  /// No description provided for @foodSampleBadge.
  ///
  /// In tr, this message translates to:
  /// **'Örnek veri'**
  String get foodSampleBadge;

  /// No description provided for @foodCustomBadge.
  ///
  /// In tr, this message translates to:
  /// **'Kendi yiyeceğim'**
  String get foodCustomBadge;

  /// No description provided for @foodRecipeBadge.
  ///
  /// In tr, this message translates to:
  /// **'Tarif'**
  String get foodRecipeBadge;

  /// No description provided for @foodQuickAdd.
  ///
  /// In tr, this message translates to:
  /// **'{food} ekle'**
  String foodQuickAdd(String food);

  /// No description provided for @foodAddedTo.
  ///
  /// In tr, this message translates to:
  /// **'{food}, {meal} öğününe eklendi'**
  String foodAddedTo(String food, String meal);

  /// No description provided for @foodMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğün'**
  String get foodMeal;

  /// No description provided for @foodAmount.
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get foodAmount;

  /// No description provided for @foodUnit.
  ///
  /// In tr, this message translates to:
  /// **'Ölçü'**
  String get foodUnit;

  /// No description provided for @foodNutrition.
  ///
  /// In tr, this message translates to:
  /// **'Besin değerleri'**
  String get foodNutrition;

  /// No description provided for @foodPer100.
  ///
  /// In tr, this message translates to:
  /// **'100 {unit} için {kcal} kcal'**
  String foodPer100(String unit, String kcal);

  /// No description provided for @foodAddToMeal.
  ///
  /// In tr, this message translates to:
  /// **'{meal} öğününe ekle'**
  String foodAddToMeal(String meal);

  /// No description provided for @foodFavoriteAdd.
  ///
  /// In tr, this message translates to:
  /// **'Favorilere ekle'**
  String get foodFavoriteAdd;

  /// No description provided for @foodFavoriteRemove.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkar'**
  String get foodFavoriteRemove;

  /// No description provided for @foodIngredients.
  ///
  /// In tr, this message translates to:
  /// **'Malzemeler'**
  String get foodIngredients;

  /// No description provided for @foodSource.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak: {source}'**
  String foodSource(String source);

  /// No description provided for @foodNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek bulunamadı.'**
  String get foodNotFound;

  /// No description provided for @foodInvalidAmount.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir miktar gir.'**
  String get foodInvalidAmount;

  /// No description provided for @foodDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get foodDelete;

  /// No description provided for @foodDeleted.
  ///
  /// In tr, this message translates to:
  /// **'{name} silindi'**
  String foodDeleted(String name);

  /// No description provided for @nutrientCalories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori'**
  String get nutrientCalories;

  /// No description provided for @nutrientFiber.
  ///
  /// In tr, this message translates to:
  /// **'Lif'**
  String get nutrientFiber;

  /// No description provided for @nutrientSugar.
  ///
  /// In tr, this message translates to:
  /// **'Şeker'**
  String get nutrientSugar;

  /// No description provided for @nutrientSaturatedFat.
  ///
  /// In tr, this message translates to:
  /// **'Doymuş yağ'**
  String get nutrientSaturatedFat;

  /// No description provided for @nutrientSodium.
  ///
  /// In tr, this message translates to:
  /// **'Sodyum'**
  String get nutrientSodium;

  /// No description provided for @mgValue.
  ///
  /// In tr, this message translates to:
  /// **'{value} mg'**
  String mgValue(String value);

  /// No description provided for @unitGram.
  ///
  /// In tr, this message translates to:
  /// **'g'**
  String get unitGram;

  /// No description provided for @unitMilliliter.
  ///
  /// In tr, this message translates to:
  /// **'ml'**
  String get unitMilliliter;

  /// No description provided for @unitPiece.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{adet}}'**
  String unitPiece(num count);

  /// No description provided for @unitSlice.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{dilim}}'**
  String unitSlice(num count);

  /// No description provided for @unitServing.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{porsiyon}}'**
  String unitServing(num count);

  /// No description provided for @unitBowl.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{kase}}'**
  String unitBowl(num count);

  /// No description provided for @unitGlass.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{bardak}}'**
  String unitGlass(num count);

  /// No description provided for @unitTablespoon.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{yemek kaşığı}}'**
  String unitTablespoon(num count);

  /// No description provided for @unitTeaspoon.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{tatlı kaşığı}}'**
  String unitTeaspoon(num count);

  /// No description provided for @portionQuantity.
  ///
  /// In tr, this message translates to:
  /// **'{quantity} {unit}'**
  String portionQuantity(String quantity, String unit);

  /// No description provided for @portionWithBase.
  ///
  /// In tr, this message translates to:
  /// **'{portion} ({base})'**
  String portionWithBase(String portion, String base);

  /// No description provided for @customFoodTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek oluştur'**
  String get customFoodTitle;

  /// No description provided for @customFoodName.
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get customFoodName;

  /// No description provided for @customFoodNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Ev yapımı granola'**
  String get customFoodNameHint;

  /// No description provided for @customFoodBrand.
  ///
  /// In tr, this message translates to:
  /// **'Marka (isteğe bağlı)'**
  String get customFoodBrand;

  /// No description provided for @customFoodBarcode.
  ///
  /// In tr, this message translates to:
  /// **'Barkod'**
  String get customFoodBarcode;

  /// No description provided for @customFoodPortion.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyon'**
  String get customFoodPortion;

  /// No description provided for @customFoodPortionAmount.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyon miktarı'**
  String get customFoodPortionAmount;

  /// No description provided for @customFoodPortionUnit.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyon türü'**
  String get customFoodPortionUnit;

  /// No description provided for @customFoodValuesTitle.
  ///
  /// In tr, this message translates to:
  /// **'1 porsiyondaki besin değerleri'**
  String get customFoodValuesTitle;

  /// No description provided for @customFoodValuesHint.
  ///
  /// In tr, this message translates to:
  /// **'Değerleri ürün etiketinden veya güvenilir bir kaynaktan gir.'**
  String get customFoodValuesHint;

  /// No description provided for @customFoodCalories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori (kcal)'**
  String get customFoodCalories;

  /// No description provided for @customFoodProtein.
  ///
  /// In tr, this message translates to:
  /// **'Protein (g)'**
  String get customFoodProtein;

  /// No description provided for @customFoodCarbs.
  ///
  /// In tr, this message translates to:
  /// **'Karbonhidrat (g)'**
  String get customFoodCarbs;

  /// No description provided for @customFoodFat.
  ///
  /// In tr, this message translates to:
  /// **'Yağ (g)'**
  String get customFoodFat;

  /// No description provided for @customFoodFiber.
  ///
  /// In tr, this message translates to:
  /// **'Lif (g, isteğe bağlı)'**
  String get customFoodFiber;

  /// No description provided for @customFoodSugar.
  ///
  /// In tr, this message translates to:
  /// **'Şeker (g, isteğe bağlı)'**
  String get customFoodSugar;

  /// No description provided for @customFoodSodium.
  ///
  /// In tr, this message translates to:
  /// **'Sodyum (mg, isteğe bağlı)'**
  String get customFoodSodium;

  /// No description provided for @customFoodSaved.
  ///
  /// In tr, this message translates to:
  /// **'{name} kaydedildi'**
  String customFoodSaved(String name);

  /// No description provided for @customFoodEnergyMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Makrolardan hesaplanan enerji yaklaşık {kcal} kcal; girdiğin kaloriyle uyuşmuyor. Değerleri kontrol et.'**
  String customFoodEnergyMismatch(String kcal);

  /// No description provided for @errorPositiveNumber.
  ///
  /// In tr, this message translates to:
  /// **'0\'dan büyük bir değer gir.'**
  String get errorPositiveNumber;

  /// No description provided for @errorNonNegativeNumber.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir değer gir.'**
  String get errorNonNegativeNumber;

  /// No description provided for @recipeBuilderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tarif oluştur'**
  String get recipeBuilderTitle;

  /// No description provided for @recipeName.
  ///
  /// In tr, this message translates to:
  /// **'Tarif adı'**
  String get recipeName;

  /// No description provided for @recipeNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Menemen'**
  String get recipeNameHint;

  /// No description provided for @recipeServings.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyon sayısı'**
  String get recipeServings;

  /// No description provided for @recipeAddIngredient.
  ///
  /// In tr, this message translates to:
  /// **'Malzeme ekle'**
  String get recipeAddIngredient;

  /// No description provided for @recipeNoIngredients.
  ///
  /// In tr, this message translates to:
  /// **'Henüz malzeme eklenmedi. Tarifin besin değerleri malzemelerden otomatik hesaplanır.'**
  String get recipeNoIngredients;

  /// No description provided for @recipeTotal.
  ///
  /// In tr, this message translates to:
  /// **'Tarifin tamamı'**
  String get recipeTotal;

  /// No description provided for @recipePerServing.
  ///
  /// In tr, this message translates to:
  /// **'1 porsiyon'**
  String get recipePerServing;

  /// No description provided for @recipeTotalWeight.
  ///
  /// In tr, this message translates to:
  /// **'Toplam ağırlık: {value} g'**
  String recipeTotalWeight(String value);

  /// No description provided for @recipeWeightNote.
  ///
  /// In tr, this message translates to:
  /// **'Değerler malzemelerin pişirilmeden önceki miktarlarına göre hesaplanır.'**
  String get recipeWeightNote;

  /// No description provided for @recipeNeedsIngredient.
  ///
  /// In tr, this message translates to:
  /// **'En az bir malzeme ekle.'**
  String get recipeNeedsIngredient;

  /// No description provided for @recipeSaved.
  ///
  /// In tr, this message translates to:
  /// **'{name} tarifi kaydedildi'**
  String recipeSaved(String name);

  /// No description provided for @foodPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Malzeme seç'**
  String get foodPickerTitle;

  /// No description provided for @barcodeManualTitle.
  ///
  /// In tr, this message translates to:
  /// **'Barkod numarasıyla ara'**
  String get barcodeManualTitle;

  /// No description provided for @barcodeManualHint.
  ///
  /// In tr, this message translates to:
  /// **'Barkod numarası'**
  String get barcodeManualHint;

  /// No description provided for @barcodeCameraUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Kamerayla tarama bu cihazda kullanılamıyor. Ürünün barkod numarasını elle girebilirsin.'**
  String get barcodeCameraUnavailable;

  /// No description provided for @barcodeSearch.
  ///
  /// In tr, this message translates to:
  /// **'Ürünü bul'**
  String get barcodeSearch;

  /// No description provided for @barcodeNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Open Food Facts kataloğunda bu barkoda ait ürün bulunamadı.'**
  String get barcodeNotFound;

  /// No description provided for @barcodeIncompleteCatalog.
  ///
  /// In tr, this message translates to:
  /// **'Barkod {barcode} Open Food Facts kataloğunda kayıtlı ancak ürün adı veya besin değerleri eksik. Özel yiyecek olarak ekleyebilirsin.'**
  String barcodeIncompleteCatalog(String barcode);

  /// No description provided for @barcodeDemoHint.
  ///
  /// In tr, this message translates to:
  /// **'Örnek veri barkodları: {codes}'**
  String barcodeDemoHint(String codes);

  /// No description provided for @barcodeAlignHint.
  ///
  /// In tr, this message translates to:
  /// **'Barkodu çerçevenin içine hizalayın'**
  String get barcodeAlignHint;

  /// No description provided for @barcodeEnterManually.
  ///
  /// In tr, this message translates to:
  /// **'Barkodu elle gir'**
  String get barcodeEnterManually;

  /// No description provided for @barcodeScanAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar tara'**
  String get barcodeScanAgain;

  /// No description provided for @barcodeSearching.
  ///
  /// In tr, this message translates to:
  /// **'Ürün aranıyor'**
  String get barcodeSearching;

  /// No description provided for @barcodeCameraPermissionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kamera izni gerekli'**
  String get barcodeCameraPermissionTitle;

  /// No description provided for @barcodeCameraPermissionMessage.
  ///
  /// In tr, this message translates to:
  /// **'Barkod taramak için kamera iznine ihtiyaç var. İzni ayarlardan açabilir veya barkodu elle girebilirsin.'**
  String get barcodeCameraPermissionMessage;

  /// No description provided for @barcodeOpenSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları aç'**
  String get barcodeOpenSettings;

  /// No description provided for @barcodeScanAreaLabel.
  ///
  /// In tr, this message translates to:
  /// **'Barkod tarama alanı'**
  String get barcodeScanAreaLabel;

  /// No description provided for @errorPermission.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için izin vermen gerekiyor. İzni cihaz ayarlarından açabilirsin.'**
  String get errorPermission;

  /// No description provided for @progressRange.
  ///
  /// In tr, this message translates to:
  /// **'{range, select, week{7 gün} month{30 gün} quarter{90 gün} other{}}'**
  String progressRange(String range);

  /// No description provided for @progressAddWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo ekle'**
  String get progressAddWeight;

  /// No description provided for @progressAddMeasurement.
  ///
  /// In tr, this message translates to:
  /// **'Ölçü ekle'**
  String get progressAddMeasurement;

  /// No description provided for @progressAddPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf ekle'**
  String get progressAddPhoto;

  /// No description provided for @progressKg.
  ///
  /// In tr, this message translates to:
  /// **'{value} kg'**
  String progressKg(String value);

  /// No description provided for @progressCm.
  ///
  /// In tr, this message translates to:
  /// **'{value} cm'**
  String progressCm(String value);

  /// No description provided for @progressPercent.
  ///
  /// In tr, this message translates to:
  /// **'%{value}'**
  String progressPercent(String value);

  /// No description provided for @progressGoalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilo hedefi'**
  String get progressGoalTitle;

  /// No description provided for @progressStartWeight.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get progressStartWeight;

  /// No description provided for @progressCurrentWeight.
  ///
  /// In tr, this message translates to:
  /// **'Güncel'**
  String get progressCurrentWeight;

  /// No description provided for @progressTargetWeight.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get progressTargetWeight;

  /// No description provided for @progressLostWeight.
  ///
  /// In tr, this message translates to:
  /// **'Verilen'**
  String get progressLostWeight;

  /// No description provided for @progressGainedWeight.
  ///
  /// In tr, this message translates to:
  /// **'Alınan'**
  String get progressGainedWeight;

  /// No description provided for @progressRemainingWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kalan'**
  String get progressRemainingWeight;

  /// No description provided for @progressGoalPercent.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin %{percent}\'i tamamlandı'**
  String progressGoalPercent(String percent);

  /// No description provided for @progressGoalReached.
  ///
  /// In tr, this message translates to:
  /// **'Hedef kilona ulaştın, tebrikler!'**
  String get progressGoalReached;

  /// No description provided for @progressNoTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef kilo belirlenmedi. Profilinden ekleyebilirsin.'**
  String get progressNoTarget;

  /// No description provided for @progressNoWeightTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kilo kaydı yok'**
  String get progressNoWeightTitle;

  /// No description provided for @progressNoWeightMessage.
  ///
  /// In tr, this message translates to:
  /// **'İlk kilonu ekleyerek ilerlemeni takip etmeye başla.'**
  String get progressNoWeightMessage;

  /// No description provided for @progressChartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilo grafiği'**
  String get progressChartTitle;

  /// No description provided for @progressChartNeedsMore.
  ///
  /// In tr, this message translates to:
  /// **'Grafik için bu dönemde en az iki kilo kaydı gerekiyor.'**
  String get progressChartNeedsMore;

  /// No description provided for @progressChartTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef {value}'**
  String progressChartTarget(String value);

  /// No description provided for @progressChartSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Kilo grafiği: {from} ile {to} arasında {count} kayıt, en düşük {min}, en yüksek {max}'**
  String progressChartSemantics(
    String from,
    String to,
    int count,
    String min,
    String max,
  );

  /// No description provided for @progressWeightHistory.
  ///
  /// In tr, this message translates to:
  /// **'Kilo kayıtları'**
  String get progressWeightHistory;

  /// No description provided for @progressEntryDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt silindi'**
  String get progressEntryDeleted;

  /// No description provided for @progressWeeklyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık ortalama'**
  String get progressWeeklyTitle;

  /// No description provided for @progressWeeklyWeight.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama kilo'**
  String get progressWeeklyWeight;

  /// No description provided for @progressWeeklyCalories.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama kalori'**
  String get progressWeeklyCalories;

  /// No description provided for @progressWeeklyScore.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama skor'**
  String get progressWeeklyScore;

  /// No description provided for @progressWeeklyVsLast.
  ///
  /// In tr, this message translates to:
  /// **'Geçen haftaya göre {change} kg'**
  String progressWeeklyVsLast(String change);

  /// No description provided for @progressWeeklyKcal.
  ///
  /// In tr, this message translates to:
  /// **'{value} kcal/gün'**
  String progressWeeklyKcal(String value);

  /// No description provided for @progressNoValue.
  ///
  /// In tr, this message translates to:
  /// **'—'**
  String get progressNoValue;

  /// No description provided for @progressWaistTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bel ölçüsü'**
  String get progressWaistTitle;

  /// No description provided for @progressMeasurementsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vücut ölçüleri'**
  String get progressMeasurementsTitle;

  /// No description provided for @progressNoMeasurements.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ölçü kaydı yok. Bel, kalça ve diğer ölçülerini ekleyerek tartıda görünmeyen değişimi de takip et.'**
  String get progressNoMeasurements;

  /// No description provided for @progressLastMeasured.
  ///
  /// In tr, this message translates to:
  /// **'Son ölçüm: {date}'**
  String progressLastMeasured(String date);

  /// No description provided for @progressSinceStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıçtan beri {change}'**
  String progressSinceStart(String change);

  /// No description provided for @measureWaist.
  ///
  /// In tr, this message translates to:
  /// **'Bel'**
  String get measureWaist;

  /// No description provided for @measureHip.
  ///
  /// In tr, this message translates to:
  /// **'Kalça'**
  String get measureHip;

  /// No description provided for @measureChest.
  ///
  /// In tr, this message translates to:
  /// **'Göğüs'**
  String get measureChest;

  /// No description provided for @measureNeck.
  ///
  /// In tr, this message translates to:
  /// **'Boyun'**
  String get measureNeck;

  /// No description provided for @measureArm.
  ///
  /// In tr, this message translates to:
  /// **'Kol'**
  String get measureArm;

  /// No description provided for @measureThigh.
  ///
  /// In tr, this message translates to:
  /// **'Bacak'**
  String get measureThigh;

  /// No description provided for @measureBodyFat.
  ///
  /// In tr, this message translates to:
  /// **'Yağ oranı'**
  String get measureBodyFat;

  /// No description provided for @progressPhotosTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme fotoğrafları'**
  String get progressPhotosTitle;

  /// No description provided for @progressPhotosEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Aynı ışıkta ve aynı pozda düzenli fotoğraf çekmek, değişimi görmenin en iyi yollarından biri.'**
  String get progressPhotosEmpty;

  /// No description provided for @progressPhotoCamera.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf çek'**
  String get progressPhotoCamera;

  /// No description provided for @progressPhotoGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden seç'**
  String get progressPhotoGallery;

  /// No description provided for @progressPhotoFirst.
  ///
  /// In tr, this message translates to:
  /// **'İlk'**
  String get progressPhotoFirst;

  /// No description provided for @progressPhotoLatest.
  ///
  /// In tr, this message translates to:
  /// **'Son'**
  String get progressPhotoLatest;

  /// No description provided for @progressPhotoAdded.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf eklendi'**
  String get progressPhotoAdded;

  /// No description provided for @progressPhotoDelete.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafı sil'**
  String get progressPhotoDelete;

  /// No description provided for @progressPhotoDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu fotoğraf kalıcı olarak silinsin mi?'**
  String get progressPhotoDeleteConfirm;

  /// No description provided for @progressPhotoDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf silindi'**
  String get progressPhotoDeleted;

  /// No description provided for @progressPhotoUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yüklenemedi'**
  String get progressPhotoUnavailable;

  /// No description provided for @actionDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get actionDelete;

  /// No description provided for @progressAdherenceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedef uyumu'**
  String get progressAdherenceTitle;

  /// No description provided for @progressAdherenceCalories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori uyumu'**
  String get progressAdherenceCalories;

  /// No description provided for @progressAdherenceProtein.
  ///
  /// In tr, this message translates to:
  /// **'Protein uyumu'**
  String get progressAdherenceProtein;

  /// No description provided for @progressAdherenceWater.
  ///
  /// In tr, this message translates to:
  /// **'Su uyumu'**
  String get progressAdherenceWater;

  /// No description provided for @progressAdherenceDays.
  ///
  /// In tr, this message translates to:
  /// **'{hit} / {total} gün'**
  String progressAdherenceDays(int hit, int total);

  /// No description provided for @progressAdherenceNoData.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönemde kayıt yok'**
  String get progressAdherenceNoData;

  /// No description provided for @progressAdherenceNote.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt girilen tamamlanmış günler üzerinden hesaplanır; bugün dahil değildir. Kalori: hedefin ±%10\'u, protein: hedefin en az %90\'ı, su: günlük su hedefi.'**
  String get progressAdherenceNote;

  /// No description provided for @progressScoreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük skor geçmişi'**
  String get progressScoreTitle;

  /// No description provided for @progressScoreAverage.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama {value}'**
  String progressScoreAverage(String value);

  /// No description provided for @progressScoreEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönemde skor hesaplanacak kayıt yok.'**
  String get progressScoreEmpty;

  /// No description provided for @progressToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get progressToday;

  /// No description provided for @progressNotLogged.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yok'**
  String get progressNotLogged;

  /// No description provided for @progressDaySummary.
  ///
  /// In tr, this message translates to:
  /// **'{kcal} kcal · {protein} g protein · {water} L su'**
  String progressDaySummary(String kcal, String protein, String water);

  /// No description provided for @progressWeightSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilo ekle'**
  String get progressWeightSheetTitle;

  /// No description provided for @progressWeightField.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get progressWeightField;

  /// No description provided for @progressDateField.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get progressDateField;

  /// No description provided for @progressWeightSaved.
  ///
  /// In tr, this message translates to:
  /// **'{value} kg kaydedildi'**
  String progressWeightSaved(String value);

  /// No description provided for @progressMeasurementSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçü ekle'**
  String get progressMeasurementSheetTitle;

  /// No description provided for @progressMeasurementHint.
  ///
  /// In tr, this message translates to:
  /// **'Ölçmek istediğin alanları doldur; boş bırakılanlar kaydedilmez. Mezuranı her seferinde aynı noktadan geçir.'**
  String get progressMeasurementHint;

  /// No description provided for @progressMeasurementNeedsValue.
  ///
  /// In tr, this message translates to:
  /// **'En az bir ölçü gir.'**
  String get progressMeasurementNeedsValue;

  /// No description provided for @progressMeasurementSaved.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüler kaydedildi'**
  String get progressMeasurementSaved;

  /// No description provided for @errorPurchase.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma tamamlanamadı. Ücret alınmadı; lütfen tekrar dene.'**
  String get errorPurchase;

  /// No description provided for @errorPurchaseUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma şu anda kullanılamıyor.'**
  String get errorPurchaseUnavailable;

  /// No description provided for @errorPremiumRequired.
  ///
  /// In tr, this message translates to:
  /// **'Bu özellik Premium üyelere özel.'**
  String get errorPremiumRequired;

  /// No description provided for @appFeatureCalorieTracking.
  ///
  /// In tr, this message translates to:
  /// **'Kalori takibi'**
  String get appFeatureCalorieTracking;

  /// No description provided for @appFeatureWeightTracking.
  ///
  /// In tr, this message translates to:
  /// **'Kilo takibi'**
  String get appFeatureWeightTracking;

  /// No description provided for @appFeatureWaterTracking.
  ///
  /// In tr, this message translates to:
  /// **'Su takibi'**
  String get appFeatureWaterTracking;

  /// No description provided for @appFeatureFoodLogging.
  ///
  /// In tr, this message translates to:
  /// **'Yemek ekleme'**
  String get appFeatureFoodLogging;

  /// No description provided for @appFeatureBasicProgress.
  ///
  /// In tr, this message translates to:
  /// **'Temel ilerleme'**
  String get appFeatureBasicProgress;

  /// No description provided for @appFeaturePersonalMealPlan.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel yemek planı'**
  String get appFeaturePersonalMealPlan;

  /// No description provided for @appFeaturePersonalMealPlanDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hedefine ve damak tadına göre her gün hazırlanan plan.'**
  String get appFeaturePersonalMealPlanDesc;

  /// No description provided for @appFeatureAiCoach.
  ///
  /// In tr, this message translates to:
  /// **'AI beslenme koçu'**
  String get appFeatureAiCoach;

  /// No description provided for @appFeatureAiCoachDesc.
  ///
  /// In tr, this message translates to:
  /// **'Sorularına sana özel, anında yanıtlar.'**
  String get appFeatureAiCoachDesc;

  /// No description provided for @appFeaturePhotoFoodAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraftan yemek analizi'**
  String get appFeaturePhotoFoodAnalysis;

  /// No description provided for @appFeaturePhotoFoodAnalysisDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tabağının fotoğrafını çek, kalorisi hesaplansın.'**
  String get appFeaturePhotoFoodAnalysisDesc;

  /// No description provided for @appFeatureAdvancedAnalytics.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş analizler'**
  String get appFeatureAdvancedAnalytics;

  /// No description provided for @appFeatureAdvancedAnalyticsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kalori, protein ve su hedeflerine uyumunu gör.'**
  String get appFeatureAdvancedAnalyticsDesc;

  /// No description provided for @appFeatureAdvancedRecipes.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş tarifler'**
  String get appFeatureAdvancedRecipes;

  /// No description provided for @appFeatureAdvancedRecipesDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hedefine uygun özel tarif koleksiyonu.'**
  String get appFeatureAdvancedRecipesDesc;

  /// No description provided for @appFeatureAutoShoppingList.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik alışveriş listesi'**
  String get appFeatureAutoShoppingList;

  /// No description provided for @appFeatureAutoShoppingListDesc.
  ///
  /// In tr, this message translates to:
  /// **'Planındaki malzemeler tek listede toplanır.'**
  String get appFeatureAutoShoppingListDesc;

  /// No description provided for @appFeatureAdvancedGoals.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş hedefler'**
  String get appFeatureAdvancedGoals;

  /// No description provided for @appFeatureAdvancedGoalsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Makro ve öğün hedeflerini kişiselleştir.'**
  String get appFeatureAdvancedGoalsDesc;

  /// No description provided for @appFeatureAdvancedReports.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş raporlar'**
  String get appFeatureAdvancedReports;

  /// No description provided for @appFeatureAdvancedReportsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme skoru geçmişi ve detaylı raporlar.'**
  String get appFeatureAdvancedReportsDesc;

  /// No description provided for @appFeatureAdFree.
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız kullanım'**
  String get appFeatureAdFree;

  /// No description provided for @appFeatureAdFreeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hiç reklam görmeden hedefine odaklan.'**
  String get appFeatureAdFreeDesc;

  /// No description provided for @appFeatureFasting.
  ///
  /// In tr, this message translates to:
  /// **'Aralıklı oruç'**
  String get appFeatureFasting;

  /// No description provided for @appFeatureFastingDesc.
  ///
  /// In tr, this message translates to:
  /// **'16:8 gibi oruç planları ve zamanlayıcı.'**
  String get appFeatureFastingDesc;

  /// No description provided for @appFeaturePeriodicReports.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık ve aylık raporlar'**
  String get appFeaturePeriodicReports;

  /// No description provided for @appFeaturePeriodicReportsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık ortalamalar ve dönem karşılaştırmaları.'**
  String get appFeaturePeriodicReportsDesc;

  /// No description provided for @premiumLockedTitle.
  ///
  /// In tr, this message translates to:
  /// **'{feature} Premium\'a özel'**
  String premiumLockedTitle(String feature);

  /// No description provided for @premiumUnlockAction.
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a geç'**
  String get premiumUnlockAction;

  /// No description provided for @premiumProfileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm özelliklerin kilidini aç'**
  String get premiumProfileSubtitle;

  /// No description provided for @paywallTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefine Premium ile daha hızlı ulaş'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana özel plan, AI koç ve gelişmiş raporlar tek abonelikte.'**
  String get paywallSubtitle;

  /// No description provided for @paywallPeriodWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get paywallPeriodWeekly;

  /// No description provided for @paywallPeriodMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get paywallPeriodMonthly;

  /// No description provided for @paywallPeriodAnnual.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get paywallPeriodAnnual;

  /// No description provided for @paywallPeriodLifetime.
  ///
  /// In tr, this message translates to:
  /// **'Ömür boyu'**
  String get paywallPeriodLifetime;

  /// No description provided for @paywallSavings.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} tasarruf'**
  String paywallSavings(int percent);

  /// No description provided for @paywallPerMonth.
  ///
  /// In tr, this message translates to:
  /// **'Aylık {price}'**
  String paywallPerMonth(String price);

  /// No description provided for @paywallSubscribe.
  ///
  /// In tr, this message translates to:
  /// **'Abone ol'**
  String get paywallSubscribe;

  /// No description provided for @paywallStartTrial.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün ücretsiz dene'**
  String paywallStartTrial(int days);

  /// No description provided for @paywallRestore.
  ///
  /// In tr, this message translates to:
  /// **'Satın alımları geri yükle'**
  String get paywallRestore;

  /// No description provided for @paywallLegal.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik, dönem bitmeden en az 24 saat önce iptal edilmezse otomatik olarak yenilenir. Mağaza hesap ayarlarından istediğin zaman iptal edebilirsin.'**
  String get paywallLegal;

  /// No description provided for @paywallTrialLegal.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük ücretsiz deneme bitiminde {price} ücretlendirilir. Deneme bitmeden en az 24 saat önce iptal edersen ücret alınmaz.'**
  String paywallTrialLegal(int days, String price);

  /// No description provided for @paywallPurchaseSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a hoş geldin!'**
  String get paywallPurchaseSuccess;

  /// No description provided for @paywallRestored.
  ///
  /// In tr, this message translates to:
  /// **'Premium üyeliğin geri yüklendi.'**
  String get paywallRestored;

  /// No description provided for @paywallNothingToRestore.
  ///
  /// In tr, this message translates to:
  /// **'Geri yüklenecek bir satın alma bulunamadı.'**
  String get paywallNothingToRestore;

  /// No description provided for @paywallActiveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Premium aktif'**
  String get paywallActiveTitle;

  /// No description provided for @paywallTrialUntil.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz deneme {date} tarihine kadar'**
  String paywallTrialUntil(String date);

  /// No description provided for @paywallRenewsOn.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihinde yenilenir'**
  String paywallRenewsOn(String date);

  /// No description provided for @paywallActiveUntil.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihine kadar geçerli'**
  String paywallActiveUntil(String date);

  /// No description provided for @settingsSubscription.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik'**
  String get settingsSubscription;

  /// No description provided for @settingsResetFakeSubscription.
  ///
  /// In tr, this message translates to:
  /// **'Test aboneliğini sıfırla'**
  String get settingsResetFakeSubscription;

  /// No description provided for @settingsLegal.
  ///
  /// In tr, this message translates to:
  /// **'Yasal'**
  String get settingsLegal;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicyUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası şu anda açılamıyor.'**
  String get settingsPrivacyPolicyUnavailable;

  /// No description provided for @scoreFactorMacroBalance.
  ///
  /// In tr, this message translates to:
  /// **'Makro dengesi'**
  String get scoreFactorMacroBalance;

  /// No description provided for @scoreTipMacroBalance.
  ///
  /// In tr, this message translates to:
  /// **'Protein, karbonhidrat ve yağı hedeflerine yakın oranda dağıtmaya çalış.'**
  String get scoreTipMacroBalance;

  /// No description provided for @diaryToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get diaryToday;

  /// No description provided for @diaryYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get diaryYesterday;

  /// No description provided for @diaryTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarın'**
  String get diaryTomorrow;

  /// No description provided for @diaryPreviousDay.
  ///
  /// In tr, this message translates to:
  /// **'Önceki gün'**
  String get diaryPreviousDay;

  /// No description provided for @diaryNextDay.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki gün'**
  String get diaryNextDay;

  /// No description provided for @diaryPickDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seç'**
  String get diaryPickDate;

  /// No description provided for @diaryCaloriesLeft.
  ///
  /// In tr, this message translates to:
  /// **'{kcal} kcal kaldı'**
  String diaryCaloriesLeft(String kcal);

  /// No description provided for @diaryCaloriesOver.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin {kcal} kcal üzerindesin'**
  String diaryCaloriesOver(String kcal);

  /// No description provided for @diaryCaloriesOfTarget.
  ///
  /// In tr, this message translates to:
  /// **'/ {target} kcal'**
  String diaryCaloriesOfTarget(String target);

  /// No description provided for @diaryMealEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'{meal, select, breakfast{Kahvaltını planlamaya başlayalım 🌱} lunch{Öğle yemeğini eklemeye ne dersin?} dinner{Akşam yemeğin henüz boş.} snack{Gün içindeki atıştırmalıklarını buraya ekleyebilirsin.} other{Henüz bir yiyecek eklenmedi.}}'**
  String diaryMealEmptyHint(String meal);

  /// No description provided for @diaryExpand.
  ///
  /// In tr, this message translates to:
  /// **'Genişlet'**
  String get diaryExpand;

  /// No description provided for @diaryCollapse.
  ///
  /// In tr, this message translates to:
  /// **'Daralt'**
  String get diaryCollapse;

  /// No description provided for @diaryEntryMenu.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek seçenekleri'**
  String get diaryEntryMenu;

  /// No description provided for @diaryEntryEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get diaryEntryEdit;

  /// No description provided for @diaryEntryCopy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get diaryEntryCopy;

  /// No description provided for @diaryEntryMove.
  ///
  /// In tr, this message translates to:
  /// **'Başka öğüne taşı'**
  String get diaryEntryMove;

  /// No description provided for @diaryEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydı düzenle'**
  String get diaryEditTitle;

  /// No description provided for @diaryEditAmount.
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get diaryEditAmount;

  /// No description provided for @diaryEditDecrease.
  ///
  /// In tr, this message translates to:
  /// **'Azalt'**
  String get diaryEditDecrease;

  /// No description provided for @diaryEditIncrease.
  ///
  /// In tr, this message translates to:
  /// **'Artır'**
  String get diaryEditIncrease;

  /// No description provided for @diaryEntryUpdated.
  ///
  /// In tr, this message translates to:
  /// **'{food} güncellendi'**
  String diaryEntryUpdated(String food);

  /// No description provided for @diaryEntryCopied.
  ///
  /// In tr, this message translates to:
  /// **'{food}, {date} tarihine kopyalandı'**
  String diaryEntryCopied(String food, String date);

  /// No description provided for @diaryEntryMoved.
  ///
  /// In tr, this message translates to:
  /// **'{food}, {meal} öğününe taşındı'**
  String diaryEntryMoved(String food, String meal);

  /// No description provided for @diaryFavoriteAdded.
  ///
  /// In tr, this message translates to:
  /// **'{food} favorilere eklendi'**
  String diaryFavoriteAdded(String food);

  /// No description provided for @diaryFavoriteRemoved.
  ///
  /// In tr, this message translates to:
  /// **'{food} favorilerden çıkarıldı'**
  String diaryFavoriteRemoved(String food);

  /// No description provided for @diaryEntryDeleted.
  ///
  /// In tr, this message translates to:
  /// **'{food} silindi'**
  String diaryEntryDeleted(String food);

  /// No description provided for @diaryDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yiyeceği sil'**
  String get diaryDeleteTitle;

  /// No description provided for @diaryDeleteMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu yiyeceği günlük kaydından silmek istediğine emin misin?'**
  String get diaryDeleteMessage;

  /// No description provided for @diaryMoveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi öğüne taşınsın?'**
  String get diaryMoveTitle;

  /// No description provided for @diaryCopyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nereye kopyalansın?'**
  String get diaryCopyTitle;

  /// No description provided for @diaryCopyToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugüne kopyala'**
  String get diaryCopyToday;

  /// No description provided for @diaryCopyTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarına kopyala'**
  String get diaryCopyTomorrow;

  /// No description provided for @diaryWaterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get diaryWaterTitle;

  /// No description provided for @diaryWaterOfGoal.
  ///
  /// In tr, this message translates to:
  /// **'{value} / {goal} ml'**
  String diaryWaterOfGoal(String value, String goal);

  /// No description provided for @diaryWaterRemove.
  ///
  /// In tr, this message translates to:
  /// **'{ml} ml azalt'**
  String diaryWaterRemove(int ml);

  /// No description provided for @diaryMlValue.
  ///
  /// In tr, this message translates to:
  /// **'{ml} ml'**
  String diaryMlValue(int ml);

  /// No description provided for @diaryWaterRemoved.
  ///
  /// In tr, this message translates to:
  /// **'{ml} ml su çıkarıldı'**
  String diaryWaterRemoved(int ml);

  /// No description provided for @diaryScoreTitle.
  ///
  /// In tr, this message translates to:
  /// **'{when, select, past{Günün Beslenme Skoru} future{Planlanan Beslenme Skoru} other{Bugünün Beslenme Skoru}}'**
  String diaryScoreTitle(String when);

  /// No description provided for @diaryScoreDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu skor genel beslenme alışkanlıklarını takip etmeye yardımcı olan tahmini bir göstergedir.'**
  String get diaryScoreDisclaimer;

  /// No description provided for @diaryScoreStatus.
  ///
  /// In tr, this message translates to:
  /// **'{status, select, met{hedefte} partial{geliştirilebilir} other{eksik}}'**
  String diaryScoreStatus(String status);

  /// No description provided for @diaryQuickAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne eklemek istiyorsun?'**
  String get diaryQuickAddTitle;

  /// No description provided for @diaryAddWater.
  ///
  /// In tr, this message translates to:
  /// **'Su ekle'**
  String get diaryAddWater;

  /// No description provided for @diaryAddWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo ekle'**
  String get diaryAddWeight;

  /// No description provided for @diaryAddActivity.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite ekle'**
  String get diaryAddActivity;

  /// No description provided for @diaryEmptyDayTitle.
  ///
  /// In tr, this message translates to:
  /// **'{when, select, past{Bu gün için kayıt yok.} future{Bu günü şimdiden planlayabilirsin.} other{Bugün henüz bir öğün eklemedin.}}'**
  String diaryEmptyDayTitle(String when);

  /// No description provided for @diaryEmptyDayMessage.
  ///
  /// In tr, this message translates to:
  /// **'Öğünlerini ekledikçe kalori, makro ve beslenme skorun burada güncellenir.'**
  String get diaryEmptyDayMessage;

  /// No description provided for @diaryPastDayNote.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş bir günü görüntülüyorsun; yaptığın değişiklikler bu güne kaydedilir.'**
  String get diaryPastDayNote;

  /// No description provided for @diaryFutureDayNote.
  ///
  /// In tr, this message translates to:
  /// **'İleri bir tarih seçili; eklediğin öğünler plan olarak bu güne kaydedilir.'**
  String get diaryFutureDayNote;

  /// No description provided for @diaryActivityTitleToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü aktivite'**
  String get diaryActivityTitleToday;

  /// No description provided for @diaryWeightTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get diaryWeightTitle;

  /// No description provided for @diaryWeightEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu gün için kilo kaydı yok.'**
  String get diaryWeightEmpty;

  /// No description provided for @diaryWeightValue.
  ///
  /// In tr, this message translates to:
  /// **'{value} kg'**
  String diaryWeightValue(String value);

  /// No description provided for @activityConnectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık verilerini bağla'**
  String get activityConnectTitle;

  /// No description provided for @activityConnectMessage.
  ///
  /// In tr, this message translates to:
  /// **'Apple Health veya Health Connect bağlandığında adım, mesafe ve aktif kalori bu cihazın günlüğünde tutulur ve Firebase\'e yazılmaz. Asistana aktivite veya gün özeti sorarsan bu özet soruyla birlikte gönderilir.'**
  String get activityConnectMessage;

  /// No description provided for @activityConnectAction.
  ///
  /// In tr, this message translates to:
  /// **'Bağlan'**
  String get activityConnectAction;

  /// No description provided for @activityConnectGranted.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık verileri bağlandı.'**
  String get activityConnectGranted;

  /// No description provided for @activityConnectUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık verisi bağlantısı bu cihazda henüz kullanılamıyor.'**
  String get activityConnectUnavailable;

  /// No description provided for @healthDataTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Verileri'**
  String get healthDataTitle;

  /// No description provided for @healthConnectName.
  ///
  /// In tr, this message translates to:
  /// **'Health Connect'**
  String get healthConnectName;

  /// No description provided for @healthAppleName.
  ///
  /// In tr, this message translates to:
  /// **'Apple Health'**
  String get healthAppleName;

  /// No description provided for @healthStatusLinked.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı'**
  String get healthStatusLinked;

  /// No description provided for @healthStatusNotLinked.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı değil'**
  String get healthStatusNotLinked;

  /// No description provided for @healthUnavailableBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu özellik bu cihazda kullanılamıyor.'**
  String get healthUnavailableBody;

  /// No description provided for @healthPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık verileri bağlı değil. Ayarlardan tekrar deneyebilirsin.'**
  String get healthPermissionDenied;

  /// No description provided for @healthPrivacyNote.
  ///
  /// In tr, this message translates to:
  /// **'Adım, mesafe ve aktif kalori bu cihazda tutulur ve Firebase\'e yazılmaz. Asistana aktivite veya gün özeti sorarsan bu özet soruyla birlikte gönderilir.'**
  String get healthPrivacyNote;

  /// No description provided for @healthConnectAction.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık verilerini bağla'**
  String get healthConnectAction;

  /// No description provided for @healthValueUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'—'**
  String get healthValueUnavailable;

  /// No description provided for @activityDistance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get activityDistance;

  /// No description provided for @activityDistanceKm.
  ///
  /// In tr, this message translates to:
  /// **'{value} km'**
  String activityDistanceKm(String value);

  /// No description provided for @activityDistanceMeters.
  ///
  /// In tr, this message translates to:
  /// **'{value} m'**
  String activityDistanceMeters(String value);

  /// No description provided for @progressActivityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hareket'**
  String get progressActivityTitle;

  /// No description provided for @progressActivityToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü adım'**
  String get progressActivityToday;

  /// No description provided for @progressActivityWeek.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün adım'**
  String get progressActivityWeek;

  /// No description provided for @weightNoteField.
  ///
  /// In tr, this message translates to:
  /// **'Not (isteğe bağlı)'**
  String get weightNoteField;

  /// No description provided for @weightNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'ör. Sabah, aç karnına'**
  String get weightNoteHint;

  /// No description provided for @weightAdd.
  ///
  /// In tr, this message translates to:
  /// **'Kilo Ekle'**
  String get weightAdd;

  /// No description provided for @weightAddFirst.
  ///
  /// In tr, this message translates to:
  /// **'İlk kilomu ekle'**
  String get weightAddFirst;

  /// No description provided for @weightEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kilo kaydı eklemedin.'**
  String get weightEmptyTitle;

  /// No description provided for @weightEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kilonu düzenli girdikçe ilerlemen, grafiğin ve hedefe kalan kilo burada görünür.'**
  String get weightEmptyMessage;

  /// No description provided for @weightJourneyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilo yolculuğun'**
  String get weightJourneyTitle;

  /// No description provided for @weightStatRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Hedefe kalan'**
  String get weightStatRemaining;

  /// No description provided for @weightStatPercent.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıçtan değişim'**
  String get weightStatPercent;

  /// No description provided for @weightStatLast.
  ///
  /// In tr, this message translates to:
  /// **'Son ölçüm'**
  String get weightStatLast;

  /// No description provided for @weightStatWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık ortalama'**
  String get weightStatWeekly;

  /// No description provided for @weightPerWeek.
  ///
  /// In tr, this message translates to:
  /// **'{value} kg/hafta'**
  String weightPerWeek(String value);

  /// No description provided for @weightRange.
  ///
  /// In tr, this message translates to:
  /// **'{range, select, week{7 gün} month{30 gün} quarter{3 ay} other{Tümü}}'**
  String weightRange(String range);

  /// No description provided for @weightHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt geçmişi'**
  String get weightHistoryTitle;

  /// No description provided for @weightHistoryEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Girdiğin kilo kayıtları burada listelenir.'**
  String get weightHistoryEmpty;

  /// No description provided for @weightDeltaPrevious.
  ///
  /// In tr, this message translates to:
  /// **'öncekine göre {change} kg'**
  String weightDeltaPrevious(String change);

  /// No description provided for @targetSuggestionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedeflerini güncelleyebilirsin'**
  String get targetSuggestionTitle;

  /// No description provided for @targetSuggestionBody.
  ///
  /// In tr, this message translates to:
  /// **'Güncel bilgilerine göre günlük kalori hedefin {current} yerine {suggested} kcal olarak öneriliyor.'**
  String targetSuggestionBody(String current, String suggested);

  /// No description provided for @targetSuggestionBodyNew.
  ///
  /// In tr, this message translates to:
  /// **'Profiline göre günlük hedefin {suggested} kcal olarak hesaplandı.'**
  String targetSuggestionBodyNew(String suggested);

  /// No description provided for @targetSuggestionLimited.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklik kademeli uygulanır: tek seferde en fazla 200 kcal.'**
  String get targetSuggestionLimited;

  /// No description provided for @targetSuggestionNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu öneri genel bir hesaplamadır; sağlık durumun varsa bir uzmana danış.'**
  String get targetSuggestionNote;

  /// No description provided for @targetSuggestionLater.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get targetSuggestionLater;

  /// No description provided for @targetSuggestionApply.
  ///
  /// In tr, this message translates to:
  /// **'Hedefi güncelle'**
  String get targetSuggestionApply;

  /// No description provided for @targetSuggestionApplied.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hedefin güncellendi. Planını yeni hedefe göre yenileyebilirsin.'**
  String get targetSuggestionApplied;

  /// No description provided for @measureEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz vücut ölçümü eklemedin.'**
  String get measureEmptyTitle;

  /// No description provided for @measureEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bel, kalça, göğüs, boyun, kol ve uyluk ölçülerini ekleyerek kilodan bağımsız değişimi de takip edebilirsin.'**
  String get measureEmptyMessage;

  /// No description provided for @measureAddFirst.
  ///
  /// In tr, this message translates to:
  /// **'İlk ölçümümü ekle'**
  String get measureAddFirst;

  /// No description provided for @measureSeeProgress.
  ///
  /// In tr, this message translates to:
  /// **'Kilo ve ölçüleri İlerleme\'de birlikte gör'**
  String get measureSeeProgress;

  /// No description provided for @measureSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçü özeti'**
  String get measureSummaryTitle;

  /// No description provided for @measureStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get measureStart;

  /// No description provided for @measureLatest.
  ///
  /// In tr, this message translates to:
  /// **'Son'**
  String get measureLatest;

  /// No description provided for @measureChange.
  ///
  /// In tr, this message translates to:
  /// **'Değişim'**
  String get measureChange;

  /// No description provided for @measureChartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçü grafiği'**
  String get measureChartTitle;

  /// No description provided for @measureChartSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{field} grafiği; en düşük {min}, en yüksek {max}.'**
  String measureChartSemantics(String field, String min, String max);

  /// No description provided for @measureHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm geçmişi'**
  String get measureHistoryTitle;

  /// No description provided for @nutritionPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme Planım'**
  String get nutritionPlanTitle;

  /// No description provided for @nutritionPlanGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedef: {goal}'**
  String nutritionPlanGoal(String goal);

  /// No description provided for @nutritionPlanDailyTarget.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kalori hedefi'**
  String get nutritionPlanDailyTarget;

  /// No description provided for @nutritionPlanEditGoals.
  ///
  /// In tr, this message translates to:
  /// **'Hedefleri düzenle'**
  String get nutritionPlanEditGoals;

  /// No description provided for @nutritionPlanPreviousWeek.
  ///
  /// In tr, this message translates to:
  /// **'Önceki hafta'**
  String get nutritionPlanPreviousWeek;

  /// No description provided for @nutritionPlanNextWeek.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki hafta'**
  String get nutritionPlanNextWeek;

  /// No description provided for @nutritionPlanWeekRange.
  ///
  /// In tr, this message translates to:
  /// **'{start} – {end}'**
  String nutritionPlanWeekRange(String start, String end);

  /// No description provided for @nutritionPlanEatingWindow.
  ///
  /// In tr, this message translates to:
  /// **'Yeme pencereni {start}–{end}; öğün saatleri buna göre ayarlandı.'**
  String nutritionPlanEatingWindow(String start, String end);

  /// No description provided for @nutritionPlanToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün öğünleri'**
  String get nutritionPlanToday;

  /// No description provided for @nutritionPlanCreate.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Plan Oluştur'**
  String get nutritionPlanCreate;

  /// No description provided for @nutritionPlanCreated.
  ///
  /// In tr, this message translates to:
  /// **'Yeni planın hazır.'**
  String get nutritionPlanCreated;

  /// No description provided for @nutritionPlanFromProfile.
  ///
  /// In tr, this message translates to:
  /// **'Kalori ve makro hedeflerin profilinden alınır.'**
  String get nutritionPlanFromProfile;

  /// No description provided for @nutritionPlanMealsPerDay.
  ///
  /// In tr, this message translates to:
  /// **'Günlük öğün sayısı'**
  String get nutritionPlanMealsPerDay;

  /// No description provided for @nutritionPlanDietType.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme tipi'**
  String get nutritionPlanDietType;

  /// No description provided for @nutritionPlanDisliked.
  ///
  /// In tr, this message translates to:
  /// **'Sevmediğin yiyecekler'**
  String get nutritionPlanDisliked;

  /// No description provided for @nutritionPlanDislikedHint.
  ///
  /// In tr, this message translates to:
  /// **'ör. Brokoli'**
  String get nutritionPlanDislikedHint;

  /// No description provided for @nutritionPlanGenerate.
  ///
  /// In tr, this message translates to:
  /// **'Planı oluştur'**
  String get nutritionPlanGenerate;

  /// No description provided for @nutritionPlanLogToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü günlüğe ekle'**
  String get nutritionPlanLogToday;

  /// No description provided for @nutritionPlanSwap.
  ///
  /// In tr, this message translates to:
  /// **'Bu yemeği değiştir'**
  String get nutritionPlanSwap;

  /// No description provided for @nutritionPlanOpenRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Tarifi gör'**
  String get nutritionPlanOpenRecipe;

  /// No description provided for @nutritionPlanAlreadyLogged.
  ///
  /// In tr, this message translates to:
  /// **'Bu öğün bugünkü günlüğünde zaten var.'**
  String get nutritionPlanAlreadyLogged;

  /// No description provided for @nutritionPlanAlternativesTitle.
  ///
  /// In tr, this message translates to:
  /// **'{meal} için alternatifler'**
  String nutritionPlanAlternativesTitle(String meal);

  /// No description provided for @nutritionPlanAlternativesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kalori hedefine, beslenme tipine, alerjilerine ve sevmediklerine uygun öneriler.'**
  String get nutritionPlanAlternativesSubtitle;

  /// No description provided for @servingsCount.
  ///
  /// In tr, this message translates to:
  /// **'{value} porsiyon'**
  String servingsCount(String value);

  /// No description provided for @recipeCategoryAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get recipeCategoryAll;

  /// No description provided for @recipeCategoryBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get recipeCategoryBreakfast;

  /// No description provided for @recipeCategoryLunch.
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get recipeCategoryLunch;

  /// No description provided for @recipeCategoryDinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get recipeCategoryDinner;

  /// No description provided for @recipeCategorySnack.
  ///
  /// In tr, this message translates to:
  /// **'Atıştırmalık'**
  String get recipeCategorySnack;

  /// No description provided for @recipeCategoryDessert.
  ///
  /// In tr, this message translates to:
  /// **'Tatlı'**
  String get recipeCategoryDessert;

  /// No description provided for @recipeCategoryDrink.
  ///
  /// In tr, this message translates to:
  /// **'İçecek'**
  String get recipeCategoryDrink;

  /// No description provided for @recipeCategoryHighProtein.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek Protein'**
  String get recipeCategoryHighProtein;

  /// No description provided for @recipeCategoryLowCalorie.
  ///
  /// In tr, this message translates to:
  /// **'Düşük Kalori'**
  String get recipeCategoryLowCalorie;

  /// No description provided for @recipeFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get recipeFavorites;

  /// No description provided for @recipeFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favori'**
  String get recipeFavorite;

  /// No description provided for @recipeAddFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favorilere ekle'**
  String get recipeAddFavorite;

  /// No description provided for @recipeRemoveFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkar'**
  String get recipeRemoveFavorite;

  /// No description provided for @recipeFavoritesEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz favori tarifin yok.'**
  String get recipeFavoritesEmptyTitle;

  /// No description provided for @recipeFavoritesEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Beğendiğin tariflerde kalp simgesine dokunarak burada topla.'**
  String get recipeFavoritesEmptyMessage;

  /// No description provided for @recipeSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Tarif veya malzeme ara'**
  String get recipeSearchHint;

  /// No description provided for @recipeNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Aramana uygun tarif bulunamadı.'**
  String get recipeNoResults;

  /// No description provided for @recipeClearFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri temizle'**
  String get recipeClearFilters;

  /// No description provided for @recipeDemoNutrition.
  ///
  /// In tr, this message translates to:
  /// **'Besin değerleri örnek USDA verisinden hesaplandı. Demo veridir.'**
  String get recipeDemoNutrition;

  /// No description provided for @recipeVegetarian.
  ///
  /// In tr, this message translates to:
  /// **'Vejetaryen'**
  String get recipeVegetarian;

  /// No description provided for @recipeSalad.
  ///
  /// In tr, this message translates to:
  /// **'Salata'**
  String get recipeSalad;

  /// No description provided for @recipeSoup.
  ///
  /// In tr, this message translates to:
  /// **'Çorba'**
  String get recipeSoup;

  /// No description provided for @recipePractical.
  ///
  /// In tr, this message translates to:
  /// **'Pratik'**
  String get recipePractical;

  /// No description provided for @recipeRecentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son görüntülenenler'**
  String get recipeRecentTitle;

  /// No description provided for @recipeRecommendedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana uygun'**
  String get recipeRecommendedTitle;

  /// No description provided for @recipeCalorieAny.
  ///
  /// In tr, this message translates to:
  /// **'Kalori'**
  String get recipeCalorieAny;

  /// No description provided for @recipeCalorieMax.
  ///
  /// In tr, this message translates to:
  /// **'≤ {kcal} kcal'**
  String recipeCalorieMax(int kcal);

  /// No description provided for @recipeSelectedServings.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen porsiyon'**
  String get recipeSelectedServings;

  /// No description provided for @recipeLoadMore.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla göster'**
  String get recipeLoadMore;

  /// No description provided for @recipeMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk'**
  String recipeMinutes(int minutes);

  /// No description provided for @recipeCreate.
  ///
  /// In tr, this message translates to:
  /// **'Tarif oluştur'**
  String get recipeCreate;

  /// No description provided for @recipeLogToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü Günlüğe Ekle'**
  String get recipeLogToday;

  /// No description provided for @recipeAddToPlan.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme Planına Ekle'**
  String get recipeAddToPlan;

  /// No description provided for @recipePickDay.
  ///
  /// In tr, this message translates to:
  /// **'Gün'**
  String get recipePickDay;

  /// No description provided for @recipePickMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğün'**
  String get recipePickMeal;

  /// No description provided for @recipeServingsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyon'**
  String get recipeServingsLabel;

  /// No description provided for @recipeLessServings.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyonu azalt'**
  String get recipeLessServings;

  /// No description provided for @recipeMoreServings.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyonu artır'**
  String get recipeMoreServings;

  /// No description provided for @recipeLogged.
  ///
  /// In tr, this message translates to:
  /// **'{name} {meal} öğününe eklendi'**
  String recipeLogged(String name, String meal);

  /// No description provided for @recipeAddedToPlan.
  ///
  /// In tr, this message translates to:
  /// **'Plana eklendi: {day}, {meal}'**
  String recipeAddedToPlan(String day, String meal);

  /// No description provided for @recipeOpenPlan.
  ///
  /// In tr, this message translates to:
  /// **'Planı aç'**
  String get recipeOpenPlan;

  /// No description provided for @recipeDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tarif silinsin mi?'**
  String get recipeDeleteTitle;

  /// No description provided for @recipeDeleteMessage.
  ///
  /// In tr, this message translates to:
  /// **'{name} tarifin kalıcı olarak silinecek.'**
  String recipeDeleteMessage(String name);

  /// No description provided for @recipeDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Tarif silindi.'**
  String get recipeDeleted;

  /// No description provided for @recipeNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Tarif bulunamadı.'**
  String get recipeNotFound;

  /// No description provided for @recipeMine.
  ///
  /// In tr, this message translates to:
  /// **'Benim tarifim'**
  String get recipeMine;

  /// No description provided for @recipeNutritionPerServing.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyon başı besin değerleri'**
  String get recipeNutritionPerServing;

  /// No description provided for @recipeIngredients.
  ///
  /// In tr, this message translates to:
  /// **'Malzemeler'**
  String get recipeIngredients;

  /// No description provided for @recipeNoIngredientList.
  ///
  /// In tr, this message translates to:
  /// **'Malzeme listesi eklenmemiş.'**
  String get recipeNoIngredientList;

  /// No description provided for @recipeSteps.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanışı'**
  String get recipeSteps;

  /// No description provided for @recipeNoSteps.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanış adımı eklenmemiş.'**
  String get recipeNoSteps;

  /// No description provided for @recipeDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kısa açıklama (isteğe bağlı)'**
  String get recipeDescription;

  /// No description provided for @recipeCategories.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get recipeCategories;

  /// No description provided for @recipeComputedCategoriesNote.
  ///
  /// In tr, this message translates to:
  /// **'\"Yüksek Protein\" ve \"Düşük Kalori\" besin değerlerine göre otomatik belirlenir.'**
  String get recipeComputedCategoriesNote;

  /// No description provided for @recipeNeedsCategory.
  ///
  /// In tr, this message translates to:
  /// **'En az bir kategori seç.'**
  String get recipeNeedsCategory;

  /// No description provided for @recipePrepMinutes.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlık'**
  String get recipePrepMinutes;

  /// No description provided for @recipeCookMinutes.
  ///
  /// In tr, this message translates to:
  /// **'Pişirme'**
  String get recipeCookMinutes;

  /// No description provided for @unitMinutes.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get unitMinutes;

  /// No description provided for @recipeIngredientsHint.
  ///
  /// In tr, this message translates to:
  /// **'Her satıra bir malzeme, ör.\n2 adet yumurta\n150 g lor peyniri'**
  String get recipeIngredientsHint;

  /// No description provided for @recipeStepsHint.
  ///
  /// In tr, this message translates to:
  /// **'Her satıra bir adım, ör.\nYumurtaları çırpın.\nTavada pişirin.'**
  String get recipeStepsHint;

  /// No description provided for @fastingEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün henüz bir oruç planlamadın.'**
  String get fastingEmptyTitle;

  /// No description provided for @fastingEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Yukarıdan bir protokol seçerek başlayabilirsin. Yeme pencerene göre öğün saatlerin ve hatırlatmaların da ayarlanır.'**
  String get fastingEmptyMessage;

  /// No description provided for @fastingProtocolTitle.
  ///
  /// In tr, this message translates to:
  /// **'Protokol'**
  String get fastingProtocolTitle;

  /// No description provided for @fastingProtocolLocked.
  ///
  /// In tr, this message translates to:
  /// **'Devam eden orucu bitirince protokolü değiştirebilirsin.'**
  String get fastingProtocolLocked;

  /// No description provided for @fastingPhaseFasting.
  ///
  /// In tr, this message translates to:
  /// **'Oruç'**
  String get fastingPhaseFasting;

  /// No description provided for @fastingPhaseEating.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceresi'**
  String get fastingPhaseEating;

  /// No description provided for @fastingChangeWindow.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceresi saatini değiştir'**
  String get fastingChangeWindow;

  /// No description provided for @fastingEatingStartPicker.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceresi başlangıcı'**
  String get fastingEatingStartPicker;

  /// No description provided for @fastingRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Hedefe {time} kaldı'**
  String fastingRemaining(String time);

  /// No description provided for @fastingEatingRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Yeme pencerenin kapanmasına {time} kaldı'**
  String fastingEatingRemaining(String time);

  /// No description provided for @fastingTargetReached.
  ///
  /// In tr, this message translates to:
  /// **'Hedef süreye ulaştın. Hazır olduğunda orucu bitirebilirsin.'**
  String get fastingTargetReached;

  /// No description provided for @fastingEndsAt.
  ///
  /// In tr, this message translates to:
  /// **'Hedef bitiş: {time}'**
  String fastingEndsAt(String time);

  /// No description provided for @fastingEatingEndsAt.
  ///
  /// In tr, this message translates to:
  /// **'Pencere kapanışı: {time}'**
  String fastingEatingEndsAt(String time);

  /// No description provided for @fastingTimerSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{phase}: {time}'**
  String fastingTimerSemantics(String phase, String time);

  /// No description provided for @fastingPaused.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı'**
  String get fastingPaused;

  /// No description provided for @fastingStart.
  ///
  /// In tr, this message translates to:
  /// **'Orucu Başlat'**
  String get fastingStart;

  /// No description provided for @fastingPause.
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get fastingPause;

  /// No description provided for @fastingResume.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get fastingResume;

  /// No description provided for @fastingFinish.
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get fastingFinish;

  /// No description provided for @fastingStarted.
  ///
  /// In tr, this message translates to:
  /// **'Oruç başladı. Bol su içmeyi unutma.'**
  String get fastingStarted;

  /// No description provided for @fastingFinishedCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler! {duration} oruç tamamlandı.'**
  String fastingFinishedCompleted(String duration);

  /// No description provided for @fastingFinishedEarly.
  ///
  /// In tr, this message translates to:
  /// **'Oruç {duration} sonra bitirildi. Kendini iyi hissetmek her zaman önceliklidir.'**
  String fastingFinishedEarly(String duration);

  /// No description provided for @fastingHoursMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk'**
  String fastingHoursMinutes(int hours, int minutes);

  /// No description provided for @fastingWindowMealsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceresindeki öğünlerin'**
  String get fastingWindowMealsTitle;

  /// No description provided for @fastingHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oruç geçmişi'**
  String get fastingHistoryTitle;

  /// No description provided for @fastingHistoryEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bitirdiğin oruçlar burada listelenir.'**
  String get fastingHistoryEmpty;

  /// No description provided for @fastingStatCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan'**
  String get fastingStatCompleted;

  /// No description provided for @fastingStatAverage.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama süre'**
  String get fastingStatAverage;

  /// No description provided for @fastingLast7Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün'**
  String get fastingLast7Days;

  /// No description provided for @fastingCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get fastingCompleted;

  /// No description provided for @fastingEndedEarly.
  ///
  /// In tr, this message translates to:
  /// **'Erken bitirildi'**
  String get fastingEndedEarly;

  /// No description provided for @fastingSessionDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Oruç kaydı silindi.'**
  String get fastingSessionDeleted;

  /// No description provided for @fastingDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Aralıklı oruç tıbbi bir tavsiye değildir. Hamilelik, emzirme, diyabet, yeme bozukluğu geçmişi, düzenli ilaç kullanımı veya kronik bir rahatsızlık varsa başlamadan önce doktoruna danış. Baş dönmesi veya halsizlik hissedersen orucu bitir.'**
  String get fastingDisclaimer;

  /// No description provided for @notificationsMaster.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationsMaster;

  /// No description provided for @notificationsMasterOff.
  ///
  /// In tr, this message translates to:
  /// **'Açtığında hatırlatmalar seçtiğin saatlerde gönderilir.'**
  String get notificationsMasterOff;

  /// No description provided for @notificationsScheduledCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Planlanmış hatırlatma yok} other{{count} hatırlatma planlandı}}'**
  String notificationsScheduledCount(int count);

  /// No description provided for @notificationsPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim izni verilmedi. Cihaz ayarlarından izin verebilirsin.'**
  String get notificationsPermissionDenied;

  /// No description provided for @notificationsOpenSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları aç'**
  String get notificationsOpenSettings;

  /// No description provided for @notificationsFastingNeedsProtocol.
  ///
  /// In tr, this message translates to:
  /// **'Oruç hatırlatmaları için Aralıklı Oruç ekranından bir protokol seç.'**
  String get notificationsFastingNeedsProtocol;

  /// No description provided for @reminderGroupMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğün'**
  String get reminderGroupMeal;

  /// No description provided for @reminderGroupWater.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get reminderGroupWater;

  /// No description provided for @reminderGroupGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get reminderGroupGoal;

  /// No description provided for @reminderGroupFasting.
  ///
  /// In tr, this message translates to:
  /// **'Oruç'**
  String get reminderGroupFasting;

  /// No description provided for @reminderGroupMotivation.
  ///
  /// In tr, this message translates to:
  /// **'Motivasyon'**
  String get reminderGroupMotivation;

  /// No description provided for @reminderGroupPlan.
  ///
  /// In tr, this message translates to:
  /// **'Plan'**
  String get reminderGroupPlan;

  /// No description provided for @reminderBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get reminderBreakfast;

  /// No description provided for @reminderLunch.
  ///
  /// In tr, this message translates to:
  /// **'Öğle yemeği'**
  String get reminderLunch;

  /// No description provided for @reminderSnack.
  ///
  /// In tr, this message translates to:
  /// **'Atıştırmalık'**
  String get reminderSnack;

  /// No description provided for @reminderDinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam yemeği'**
  String get reminderDinner;

  /// No description provided for @reminderWater.
  ///
  /// In tr, this message translates to:
  /// **'Su içme'**
  String get reminderWater;

  /// No description provided for @reminderDailyGoal.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hedef özeti'**
  String get reminderDailyGoal;

  /// No description provided for @reminderWeighIn.
  ///
  /// In tr, this message translates to:
  /// **'Kilo ölçümü'**
  String get reminderWeighIn;

  /// No description provided for @reminderFastingStart.
  ///
  /// In tr, this message translates to:
  /// **'Oruç başlangıcı'**
  String get reminderFastingStart;

  /// No description provided for @reminderEatingStart.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceresi başlangıcı'**
  String get reminderEatingStart;

  /// No description provided for @reminderEatingEnd.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceresi bitişi'**
  String get reminderEatingEnd;

  /// No description provided for @reminderFastingEnd.
  ///
  /// In tr, this message translates to:
  /// **'Oruç bitişi'**
  String get reminderFastingEnd;

  /// No description provided for @reminderMotivation.
  ///
  /// In tr, this message translates to:
  /// **'Günlük motivasyon'**
  String get reminderMotivation;

  /// No description provided for @reminderPlan.
  ///
  /// In tr, this message translates to:
  /// **'Plan hatırlatmaları'**
  String get reminderPlan;

  /// No description provided for @reminderPlanHint.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık plandaki öğünün adıyla, öğün saatinde gönderilir.'**
  String get reminderPlanHint;

  /// No description provided for @reminderWaterBalanced.
  ///
  /// In tr, this message translates to:
  /// **'Günlük su hedefine göre, uyanık saatlere yayılır.'**
  String get reminderWaterBalanced;

  /// No description provided for @reminderChangeTime.
  ///
  /// In tr, this message translates to:
  /// **'Saati değiştir'**
  String get reminderChangeTime;

  /// No description provided for @reminderWaterEvery.
  ///
  /// In tr, this message translates to:
  /// **'Her {hours} saatte bir, {start}–{end}'**
  String reminderWaterEvery(String hours, String start, String end);

  /// No description provided for @reminderEveryHours.
  ///
  /// In tr, this message translates to:
  /// **'{hours} saatte bir'**
  String reminderEveryHours(String hours);

  /// No description provided for @reminderWeeklyMonday.
  ///
  /// In tr, this message translates to:
  /// **'Her pazartesi {time}'**
  String reminderWeeklyMonday(String time);

  /// No description provided for @reminderFastingEndHint.
  ///
  /// In tr, this message translates to:
  /// **'Devam eden orucun hedef süresi dolunca'**
  String get reminderFastingEndHint;

  /// No description provided for @reminderOutsideWindow.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceren dışında olduğu için gönderilmez'**
  String get reminderOutsideWindow;

  /// No description provided for @reminderBreakfastTitle.
  ///
  /// In tr, this message translates to:
  /// **'🍳 Kahvaltı zamanı'**
  String get reminderBreakfastTitle;

  /// No description provided for @reminderLunchTitle.
  ///
  /// In tr, this message translates to:
  /// **'🍽️ Öğle yemeği zamanı'**
  String get reminderLunchTitle;

  /// No description provided for @reminderSnackTitle.
  ///
  /// In tr, this message translates to:
  /// **'🍎 Ara öğün zamanı'**
  String get reminderSnackTitle;

  /// No description provided for @reminderDinnerTitle.
  ///
  /// In tr, this message translates to:
  /// **'🌙 Akşam yemeği zamanı'**
  String get reminderDinnerTitle;

  /// No description provided for @reminderBreakfastBody.
  ///
  /// In tr, this message translates to:
  /// **'Güne güzel bir başlangıç yap.'**
  String get reminderBreakfastBody;

  /// No description provided for @reminderLunchBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü planındaki öğünü unutma.'**
  String get reminderLunchBody;

  /// No description provided for @reminderSnackBody.
  ///
  /// In tr, this message translates to:
  /// **'Ara öğününü atlamayı unutma.'**
  String get reminderSnackBody;

  /// No description provided for @reminderDinnerBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü planına göz at.'**
  String get reminderDinnerBody;

  /// No description provided for @reminderMealBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü öğününü planına eklemeyi unutma.'**
  String get reminderMealBody;

  /// No description provided for @reminderPlanMealTitle.
  ///
  /// In tr, this message translates to:
  /// **'{meal}: {recipe}'**
  String reminderPlanMealTitle(String meal, String recipe);

  /// No description provided for @reminderWaterTitle.
  ///
  /// In tr, this message translates to:
  /// **'💧 Su zamanı'**
  String get reminderWaterTitle;

  /// No description provided for @reminderWaterBody.
  ///
  /// In tr, this message translates to:
  /// **'Günlük su hedefin için bir bardak su iç.'**
  String get reminderWaterBody;

  /// No description provided for @reminderDailyGoalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünü nasıl geçirdin?'**
  String get reminderDailyGoalTitle;

  /// No description provided for @reminderDailyGoalBody.
  ///
  /// In tr, this message translates to:
  /// **'Kalori ve protein hedeflerine ne kadar yaklaştığını gör.'**
  String get reminderDailyGoalBody;

  /// No description provided for @reminderWeighInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık kilo ölçümü'**
  String get reminderWeighInTitle;

  /// No description provided for @reminderWeighInBody.
  ///
  /// In tr, this message translates to:
  /// **'Sabah aç karnına tartılıp kilonu kaydet.'**
  String get reminderWeighInBody;

  /// No description provided for @reminderFastingStartTitle.
  ///
  /// In tr, this message translates to:
  /// **'⏱️ Oruç başladı'**
  String get reminderFastingStartTitle;

  /// No description provided for @reminderFastingStartBody.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceren kapandı.'**
  String get reminderFastingStartBody;

  /// No description provided for @reminderEatingStartTitle.
  ///
  /// In tr, this message translates to:
  /// **'🍽️ Yeme penceren başladı'**
  String get reminderEatingStartTitle;

  /// No description provided for @reminderEatingStartBody.
  ///
  /// In tr, this message translates to:
  /// **'Planındaki öğünle yemeğine başlayabilirsin.'**
  String get reminderEatingStartBody;

  /// No description provided for @reminderEatingEndTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeme pencerin kapanıyor'**
  String get reminderEatingEndTitle;

  /// No description provided for @reminderEatingEndBody.
  ///
  /// In tr, this message translates to:
  /// **'Pencerenin kapanmasına {minutes} dakika kaldı.'**
  String reminderEatingEndBody(int minutes);

  /// No description provided for @reminderFastingEndTitle.
  ///
  /// In tr, this message translates to:
  /// **'🎉 Oruç süren tamamlandı'**
  String get reminderFastingEndTitle;

  /// No description provided for @reminderFastingEndBody.
  ///
  /// In tr, this message translates to:
  /// **'Hazır olduğunda orucunu bitirebilirsin.'**
  String get reminderFastingEndBody;

  /// No description provided for @reminderMotivationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Küçük adımlar, büyük değişim'**
  String get reminderMotivationTitle;

  /// No description provided for @reminderMotivationBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugün hedefin için yapabileceğin tek bir şeyi seç.'**
  String get reminderMotivationBody;

  /// No description provided for @assistantEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü beslenmen hakkında bana istediğin şeyi sorabilirsin.'**
  String get assistantEmptyTitle;

  /// No description provided for @assistantEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Profilin, günlüğün, planın, kilo kayıtların ve oruç bilgine bakarak yanıt veririm.'**
  String get assistantEmptyMessage;

  /// No description provided for @assistantHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir soru yaz…'**
  String get assistantHint;

  /// No description provided for @assistantThinking.
  ///
  /// In tr, this message translates to:
  /// **'Yanıt hazırlanıyor'**
  String get assistantThinking;

  /// No description provided for @assistantClear.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti temizle'**
  String get assistantClear;

  /// No description provided for @assistantError.
  ///
  /// In tr, this message translates to:
  /// **'Şu an yanıt veremedim. Lütfen biraz sonra tekrar dene.'**
  String get assistantError;

  /// No description provided for @assistantDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Öneri amaçlıdır; tıbbi tanı veya tedavi yerine geçmez.'**
  String get assistantDisclaimer;

  /// No description provided for @assistantQuickRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Bugün kaç kalori hakkım kaldı?'**
  String get assistantQuickRemaining;

  /// No description provided for @assistantQuickProtein.
  ///
  /// In tr, this message translates to:
  /// **'Protein hedefime ulaştım mı?'**
  String get assistantQuickProtein;

  /// No description provided for @assistantQuickDinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam için ne yiyebilirim?'**
  String get assistantQuickDinner;

  /// No description provided for @assistantQuickSwap.
  ///
  /// In tr, this message translates to:
  /// **'Planımdaki yemeği değiştirebilir miyim?'**
  String get assistantQuickSwap;

  /// No description provided for @assistantQuickOver.
  ///
  /// In tr, this message translates to:
  /// **'Bugün çok fazla kalori aldım'**
  String get assistantQuickOver;

  /// No description provided for @assistantRemainingCalories.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {consumed} kcal aldın. Hedefin {target} kcal, yani {remaining} kcal hakkın kaldı.'**
  String assistantRemainingCalories(
    String consumed,
    String target,
    String remaining,
  );

  /// No description provided for @assistantOverCaloriesInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {consumed} kcal aldın; hedefin {target} kcal. Hedefin {over} kcal üzerindesin — bu tek bir gün, sorun değil.'**
  String assistantOverCaloriesInfo(String consumed, String target, String over);

  /// No description provided for @assistantProteinReached.
  ///
  /// In tr, this message translates to:
  /// **'Evet! Bugün {consumed} g protein aldın, hedefin {target} g. Harika gidiyorsun.'**
  String assistantProteinReached(String consumed, String target);

  /// No description provided for @assistantProteinRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Henüz değil: {consumed} / {target} g protein. {remaining} g daha var. Profiline uygun protein kaynaklarını tariflerden seçebilirsin.'**
  String assistantProteinRemaining(
    String consumed,
    String target,
    String remaining,
  );

  /// No description provided for @assistantSuggestionIntro.
  ///
  /// In tr, this message translates to:
  /// **'{meal} için yaklaşık {remaining} kcal hakkın var. Şunlar uyabilir:'**
  String assistantSuggestionIntro(String meal, String remaining);

  /// No description provided for @assistantSuggestionLight.
  ///
  /// In tr, this message translates to:
  /// **'{meal} için {remaining} kcal kaldı; hafif ama doyurucu bir seçenek öneririm:'**
  String assistantSuggestionLight(String meal, String remaining);

  /// No description provided for @assistantSuggestionOver.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü hedefine ulaştın; yine de {meal} öğününü atlama. Sebze ve protein ağırlıklı hafif bir seçenek iyi olur:'**
  String assistantSuggestionOver(String meal);

  /// No description provided for @assistantSuggestionFromPlan.
  ///
  /// In tr, this message translates to:
  /// **'Planındaki: {title} ({kcal} kcal)'**
  String assistantSuggestionFromPlan(String title, String kcal);

  /// No description provided for @assistantSuggestionNone.
  ///
  /// In tr, this message translates to:
  /// **'Tercihlerine uyan bir öneri bulamadım. Tariflere göz atabilirsin.'**
  String get assistantSuggestionNone;

  /// No description provided for @assistantSwapGeneral.
  ///
  /// In tr, this message translates to:
  /// **'Elbette. Beslenme Planı\'nda bir öğüne dokunup “Bu yemeği değiştir”i seçersen hedefine, diyet tipine ve alerjilerine uygun alternatifler gösteririm.'**
  String get assistantSwapGeneral;

  /// No description provided for @assistantSwapMeal.
  ///
  /// In tr, this message translates to:
  /// **'Evet. Bugünkü {meal} öğünün: {title}. Beslenme Planı\'nda bu öğüne dokunup “Bu yemeği değiştir”i seçerek benzer kalorili alternatiflerden birini seçebilirsin.'**
  String assistantSwapMeal(String meal, String title);

  /// No description provided for @assistantOverTarget.
  ///
  /// In tr, this message translates to:
  /// **'Bugün hedefinin yaklaşık {over} kcal üzerindesin. Bu tek bir gün ve ilerlemeni bozmaz. Kendini cezalandırmana ya da öğün atlamana gerek yok; su içmeye devam et, sonraki öğünü dengeli seç ve yarın planına kaldığın yerden devam et.'**
  String assistantOverTarget(String over);

  /// No description provided for @assistantOverTargetNotReally.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlarına göre bugün hedefinin üzerine çıkmadın. Bazen öyle hissettirebilir; dengeli devam ediyorsun.'**
  String get assistantOverTargetNotReally;

  /// No description provided for @assistantWaterReached.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {amount} su içtin, hedefine ulaştın.'**
  String assistantWaterReached(String amount);

  /// No description provided for @assistantWaterRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {amount} su içtin; hedefin {goal}. {left} daha içebilirsin.'**
  String assistantWaterRemaining(String amount, String goal, String left);

  /// No description provided for @assistantWeightEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kilo kaydın yok. Kilo Takibi\'nden ilk kaydını ekleyebilirsin.'**
  String get assistantWeightEmpty;

  /// No description provided for @assistantWeightProgress.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç: {start}, şu an: {current} ({change}).'**
  String assistantWeightProgress(String start, String current, String change);

  /// No description provided for @assistantWeightTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin {target}; {left} kaldı.'**
  String assistantWeightTarget(String target, String left);

  /// No description provided for @assistantWaist.
  ///
  /// In tr, this message translates to:
  /// **'Son bel ölçün: {value}.'**
  String assistantWaist(String value);

  /// No description provided for @assistantWeightNote.
  ///
  /// In tr, this message translates to:
  /// **'Haftada yaklaşık 0,25–1 kg arası değişim sürdürülebilir kabul edilir; günlük dalgalanmalar normaldir.'**
  String get assistantWeightNote;

  /// No description provided for @assistantFastingNone.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir oruç protokolü seçmedin. Aralıklı Oruç sayfasından planlayabilirsin.'**
  String get assistantFastingNone;

  /// No description provided for @assistantFastingActive.
  ///
  /// In tr, this message translates to:
  /// **'Oruçtasın. Hedefe kalan süre: {time}.'**
  String assistantFastingActive(String time);

  /// No description provided for @assistantFastingEating.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceresindesin. Pencerenin kapanmasına {time} var.'**
  String assistantFastingEating(String time);

  /// No description provided for @assistantSafetyMedical.
  ///
  /// In tr, this message translates to:
  /// **'Bu konu tıbbi bir değerlendirme gerektiriyor; teşhis koyamam veya ilaç ve tedavi hakkında öneri veremem. Lütfen doktoruna ya da bir diyetisyene danış. Genel beslenme sorularında yardımcı olmaya devam edebilirim.'**
  String get assistantSafetyMedical;

  /// No description provided for @assistantSafetyEatingDisorder.
  ///
  /// In tr, this message translates to:
  /// **'Bunu paylaştığın için teşekkürler. Yemekle ilişkin seni zorluyorsa yalnız değilsin; bu konuda bir doktor, psikolog veya diyetisyenden destek almanı öneririm. Kendini güvende hissetmiyorsan hemen 112\'yi arayabilirsin.'**
  String get assistantSafetyEatingDisorder;

  /// No description provided for @assistantSafetyRestriction.
  ///
  /// In tr, this message translates to:
  /// **'Aşırı düşük kalori, öğün atlama veya çok hızlı kilo verme sağlığına zarar verebilir; bunu önermem. Sürdürülebilir ilerleme için hedefine uygun, dengeli bir plan daha etkilidir. Kişisel bir program için bir diyetisyene danışabilirsin.'**
  String get assistantSafetyRestriction;

  /// No description provided for @assistantHelp.
  ///
  /// In tr, this message translates to:
  /// **'Şunları sorabilirsin: kalan kalori hakkın, protein hedefin, bir öğün için öneri, plandaki yemeği değiştirme, su, kilo ilerlemen veya oruç durumun.'**
  String get assistantHelp;

  /// No description provided for @assistantNotConfigured.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme asistanı şu anda yapılandırılmamış.'**
  String get assistantNotConfigured;

  /// No description provided for @assistantOffline.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok. Önceki sohbetin duruyor; yeni bir yanıt için bağlantı gerekir.'**
  String get assistantOffline;

  /// No description provided for @assistantTimeout.
  ///
  /// In tr, this message translates to:
  /// **'Yanıt zaman aşımına uğradı. Tekrar deneyebilirsin.'**
  String get assistantTimeout;

  /// No description provided for @assistantRateLimited.
  ///
  /// In tr, this message translates to:
  /// **'Çok sık istek gönderildi. Biraz sonra tekrar dene.'**
  String get assistantRateLimited;

  /// No description provided for @assistantInvalidResponse.
  ///
  /// In tr, this message translates to:
  /// **'Asistan yanıtı okunamadı. Tekrar deneyebilirsin.'**
  String get assistantInvalidResponse;

  /// No description provided for @assistantEmptyResponse.
  ///
  /// In tr, this message translates to:
  /// **'Asistan boş bir yanıt döndürdü. Tekrar deneyebilirsin.'**
  String get assistantEmptyResponse;

  /// No description provided for @assistantMalformed.
  ///
  /// In tr, this message translates to:
  /// **'Asistan yanıtı bozuk. Tekrar deneyebilirsin.'**
  String get assistantMalformed;

  /// No description provided for @assistantUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme asistanı şu anda kullanılamıyor.'**
  String get assistantUnavailable;

  /// No description provided for @assistantMessageTooLong.
  ///
  /// In tr, this message translates to:
  /// **'Mesajın çok uzun. Daha kısa bir soru yaz.'**
  String get assistantMessageTooLong;

  /// No description provided for @assistantRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get assistantRetry;

  /// No description provided for @assistantPrivacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Asistan hakkında'**
  String get assistantPrivacyTitle;

  /// No description provided for @assistantPrivacyBody.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme asistanı öneri amaçlıdır. Tanı koymaz, ilaç veya tedavi önermez ve doktorun ya da diyetisyeninin yerine geçmez. Sohbet geçmişi yalnızca bu cihazda tutulur ve Firebase\'e gönderilmez. Bir soru gönderildiğinde, yanıt için gereken sınırlı bağlam yapılandırılmış bir sunucu ucuna iletilebilir; sağlayıcı anahtarı uygulamada saklanmaz. Adım, mesafe ve aktif kalori Firebase\'e yazılmaz; aktivite veya gün özeti sorduğunda cihazından giden isteğe eklenebilir. Asistan günlüğünü, planını, su kaydını veya kalori hedefini kendiliğinden değiştirmez.'**
  String get assistantPrivacyBody;

  /// No description provided for @assistantRecordsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtların'**
  String get assistantRecordsLabel;

  /// No description provided for @assistantCommentaryLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get assistantCommentaryLabel;

  /// No description provided for @assistantMissingInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgiye erişemiyorum.'**
  String get assistantMissingInfo;

  /// No description provided for @assistantAllergyBlocked.
  ///
  /// In tr, this message translates to:
  /// **'Alerjine uymayan bir öneri gösteremem. Güvenli bir alternatif için tariflere bakabilirsin.'**
  String get assistantAllergyBlocked;

  /// No description provided for @assistantConsumedOnly.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {consumed} kcal aldın. Kalori hedefin kayıtlı değil.'**
  String assistantConsumedOnly(String consumed);

  /// No description provided for @assistantMacroLine.
  ///
  /// In tr, this message translates to:
  /// **'{name}: {consumed} / {target} g'**
  String assistantMacroLine(String name, String consumed, String target);

  /// No description provided for @assistantWaterOnly.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {amount} su içtin. Su hedefin kayıtlı değil.'**
  String assistantWaterOnly(String amount);

  /// No description provided for @assistantActivitySteps.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {steps} adım attın.'**
  String assistantActivitySteps(int steps);

  /// No description provided for @assistantActivityDistance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe: {km} km.'**
  String assistantActivityDistance(String km);

  /// No description provided for @assistantActivityCalories.
  ///
  /// In tr, this message translates to:
  /// **'Aktif kalori: {kcal} kcal.'**
  String assistantActivityCalories(String kcal);

  /// No description provided for @assistantActivityWorkouts.
  ///
  /// In tr, this message translates to:
  /// **'Antrenman: {count}.'**
  String assistantActivityWorkouts(int count);

  /// No description provided for @assistantPlanEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bugün için kayıtlı bir plan göremiyorum.'**
  String get assistantPlanEmpty;

  /// No description provided for @assistantRecipeHeading.
  ///
  /// In tr, this message translates to:
  /// **'Kataloğundaki uygun tarifler:'**
  String get assistantRecipeHeading;

  /// No description provided for @assistantRecipeLine.
  ///
  /// In tr, this message translates to:
  /// **'{title} ({kcal} kcal, {protein} g protein)'**
  String assistantRecipeLine(String title, String kcal, String protein);

  /// No description provided for @assistantQuickToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün nasıl besleniyorum?'**
  String get assistantQuickToday;

  /// No description provided for @assistantQuickProteinBoost.
  ///
  /// In tr, this message translates to:
  /// **'Proteinimi nasıl artırırım?'**
  String get assistantQuickProteinBoost;

  /// No description provided for @assistantQuickWaterGoal.
  ///
  /// In tr, this message translates to:
  /// **'Su hedefime ulaştım mı?'**
  String get assistantQuickWaterGoal;

  /// No description provided for @assistantQuickPlanReview.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü planımı değerlendir'**
  String get assistantQuickPlanReview;

  /// No description provided for @assistantQuickRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Bana uygun tarif öner'**
  String get assistantQuickRecipe;

  /// No description provided for @assistantQuickDinnerLose.
  ///
  /// In tr, this message translates to:
  /// **'Kilo verme hedefime uygun akşam yemeği öner.'**
  String get assistantQuickDinnerLose;

  /// No description provided for @assistantQuickProteinMeal.
  ///
  /// In tr, this message translates to:
  /// **'Protein ağırlıklı bir öğün öner.'**
  String get assistantQuickProteinMeal;

  /// No description provided for @targetChangeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kilo bilgine göre günlük hedefini yeniden hesaplamak ister misin?'**
  String get targetChangeTitle;

  /// No description provided for @targetChangeCurrentWeight.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kilo'**
  String get targetChangeCurrentWeight;

  /// No description provided for @targetChangeNewWeight.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kilo'**
  String get targetChangeNewWeight;

  /// No description provided for @targetChangeCurrentCalories.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut günlük hedef'**
  String get targetChangeCurrentCalories;

  /// No description provided for @targetChangeNewCalories.
  ///
  /// In tr, this message translates to:
  /// **'Yeni önerilen hedef'**
  String get targetChangeNewCalories;

  /// No description provided for @targetChangeUseNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni hedefi kullan'**
  String get targetChangeUseNew;

  /// No description provided for @targetChangeKeepCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut hedefi koru'**
  String get targetChangeKeepCurrent;

  /// No description provided for @targetChangeSafety.
  ///
  /// In tr, this message translates to:
  /// **'Aşırı düşük kalori hedefleri güvenlik için sınırlanır. Bu bir tahmindir; tıbbi veya diyetisyen önerisi değildir.'**
  String get targetChangeSafety;

  /// No description provided for @targetChangeMacros.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen makrolar: {protein} g protein, {carbs} g karbonhidrat, {fat} g yağ.'**
  String targetChangeMacros(String protein, String carbs, String fat);

  /// No description provided for @sleepHoursTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uyku saatleri'**
  String get sleepHoursTitle;

  /// No description provided for @sleepHoursHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu saatlerde su hatırlatması gönderilmez.'**
  String get sleepHoursHint;

  /// No description provided for @sleepStart.
  ///
  /// In tr, this message translates to:
  /// **'Uyku başlangıcı'**
  String get sleepStart;

  /// No description provided for @sleepEnd.
  ///
  /// In tr, this message translates to:
  /// **'Uyku bitişi'**
  String get sleepEnd;

  /// No description provided for @notificationsPermissionHint.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim izni, hatırlatıcıları açtığında sorulur.'**
  String get notificationsPermissionHint;

  /// No description provided for @waterTodayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get waterTodayTitle;

  /// No description provided for @waterHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş günler'**
  String get waterHistoryTitle;

  /// No description provided for @waterEmptyHistory.
  ///
  /// In tr, this message translates to:
  /// **'Diğer günlerde henüz su kaydı yok.'**
  String get waterEmptyHistory;

  /// No description provided for @waterRemoveAmount.
  ///
  /// In tr, this message translates to:
  /// **'{amount} ml azalt'**
  String waterRemoveAmount(int amount);

  /// No description provided for @shoppingMyList.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş Listem'**
  String get shoppingMyList;

  /// No description provided for @shoppingAddItem.
  ///
  /// In tr, this message translates to:
  /// **'Ürün ekle'**
  String get shoppingAddItem;

  /// No description provided for @shoppingItemName.
  ///
  /// In tr, this message translates to:
  /// **'Ürün'**
  String get shoppingItemName;

  /// No description provided for @shoppingQuantity.
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get shoppingQuantity;

  /// No description provided for @shoppingUnit.
  ///
  /// In tr, this message translates to:
  /// **'Birim'**
  String get shoppingUnit;

  /// No description provided for @shoppingGenerateWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanın alışveriş listesini oluştur'**
  String get shoppingGenerateWeek;

  /// No description provided for @shoppingGenerated.
  ///
  /// In tr, this message translates to:
  /// **'Plandan {count} ürün eklendi.'**
  String shoppingGenerated(int count);

  /// No description provided for @shoppingEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Listen boş'**
  String get shoppingEmptyTitle;

  /// No description provided for @shoppingEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kendin ürün ekleyebilir veya bu haftanın planından liste oluşturabilirsin.'**
  String get shoppingEmptyMessage;

  /// No description provided for @shoppingCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get shoppingCompleted;

  /// No description provided for @shoppingClearCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananları temizle'**
  String get shoppingClearCompleted;

  /// No description provided for @shoppingFromRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Tariften'**
  String get shoppingFromRecipe;

  /// No description provided for @shoppingFromPlan.
  ///
  /// In tr, this message translates to:
  /// **'Plandan'**
  String get shoppingFromPlan;

  /// No description provided for @shoppingCategoryProduce.
  ///
  /// In tr, this message translates to:
  /// **'Sebze & Meyve'**
  String get shoppingCategoryProduce;

  /// No description provided for @shoppingCategoryMeat.
  ///
  /// In tr, this message translates to:
  /// **'Et & Tavuk'**
  String get shoppingCategoryMeat;

  /// No description provided for @shoppingCategoryDairy.
  ///
  /// In tr, this message translates to:
  /// **'Süt Ürünleri'**
  String get shoppingCategoryDairy;

  /// No description provided for @shoppingCategoryGrains.
  ///
  /// In tr, this message translates to:
  /// **'Tahıl & Bakliyat'**
  String get shoppingCategoryGrains;

  /// No description provided for @shoppingCategoryBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltılık'**
  String get shoppingCategoryBreakfast;

  /// No description provided for @shoppingCategoryOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get shoppingCategoryOther;

  /// No description provided for @recipeAddToShopping.
  ///
  /// In tr, this message translates to:
  /// **'Malzemeleri alışveriş listesine ekle'**
  String get recipeAddToShopping;

  /// No description provided for @recipeAddedToShopping.
  ///
  /// In tr, this message translates to:
  /// **'Malzemeler alışveriş listesine eklendi.'**
  String get recipeAddedToShopping;

  /// No description provided for @photoLogPick.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf çek veya seç'**
  String get photoLogPick;

  /// No description provided for @photoLogCamera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get photoLogCamera;

  /// No description provided for @photoLogGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get photoLogGallery;

  /// No description provided for @photoLogAnalyzing.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf analiz ediliyor…'**
  String get photoLogAnalyzing;

  /// No description provided for @photoLogUploading.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf hazırlanıyor…'**
  String get photoLogUploading;

  /// No description provided for @photoLogMatching.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecekler eşleştiriliyor…'**
  String get photoLogMatching;

  /// No description provided for @photoLogResults.
  ///
  /// In tr, this message translates to:
  /// **'Algılanan yiyecekler'**
  String get photoLogResults;

  /// No description provided for @photoLogEstimateBadge.
  ///
  /// In tr, this message translates to:
  /// **'Aday'**
  String get photoLogEstimateBadge;

  /// No description provided for @photoLogAddToDiary.
  ///
  /// In tr, this message translates to:
  /// **'Günlüğe Ekle'**
  String get photoLogAddToDiary;

  /// No description provided for @photoLogAdded.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecekler günlüğe eklendi.'**
  String get photoLogAdded;

  /// No description provided for @photoLogDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçlar adaydır. Besin değerleri onayından sonra yiyecek kaydından hesaplanır. Fotoğraf kaydedilmez.'**
  String get photoLogDisclaimer;

  /// No description provided for @photoLogName.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek adı'**
  String get photoLogName;

  /// No description provided for @photoLogAmount.
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get photoLogAmount;

  /// No description provided for @photoLogPortion.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyon'**
  String get photoLogPortion;

  /// No description provided for @photoLogMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğün'**
  String get photoLogMeal;

  /// No description provided for @voiceLogHint.
  ///
  /// In tr, this message translates to:
  /// **'Örneğin: İki yumurta, elli gram peynir ve iki dilim ekmek yedim.'**
  String get voiceLogHint;

  /// No description provided for @voiceLogSimulate.
  ///
  /// In tr, this message translates to:
  /// **'Örnek cümleyi kullan'**
  String get voiceLogSimulate;

  /// No description provided for @voiceLogParse.
  ///
  /// In tr, this message translates to:
  /// **'Ayır'**
  String get voiceLogParse;

  /// No description provided for @voiceLogResults.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıştırılmış sonuçlar'**
  String get voiceLogResults;

  /// No description provided for @voiceLogEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek bulunamadı. Metni düzenleyip yeniden deneyebilirsin.'**
  String get voiceLogEmpty;

  /// No description provided for @voiceLogDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma metne çevrilir ve yiyecekler aday olarak ayrılır. Besin değerleri onayından sonra hesaplanır. Ses kaydı saklanmaz.'**
  String get voiceLogDisclaimer;

  /// No description provided for @voiceLogListening.
  ///
  /// In tr, this message translates to:
  /// **'Dinleniyor…'**
  String get voiceLogListening;

  /// No description provided for @voiceLogStop.
  ///
  /// In tr, this message translates to:
  /// **'Durdur'**
  String get voiceLogStop;

  /// No description provided for @voiceLogMic.
  ///
  /// In tr, this message translates to:
  /// **'Konuş'**
  String get voiceLogMic;

  /// No description provided for @voiceLogMicSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofonla yiyecek söyle'**
  String get voiceLogMicSemantics;

  /// No description provided for @voiceLogTranscript.
  ///
  /// In tr, this message translates to:
  /// **'Metin'**
  String get voiceLogTranscript;

  /// No description provided for @photoLogNoMatch.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşme bulunamadı'**
  String get photoLogNoMatch;

  /// No description provided for @photoLogSearchAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar ara'**
  String get photoLogSearchAgain;

  /// No description provided for @photoLogManualSearch.
  ///
  /// In tr, this message translates to:
  /// **'Manuel ara'**
  String get photoLogManualSearch;

  /// No description provided for @photoLogCreateCustom.
  ///
  /// In tr, this message translates to:
  /// **'Özel yiyecek oluştur'**
  String get photoLogCreateCustom;

  /// No description provided for @photoLogRemove.
  ///
  /// In tr, this message translates to:
  /// **'Yiyeceği sil'**
  String get photoLogRemove;

  /// No description provided for @photoLogAddFood.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek ekle'**
  String get photoLogAddFood;

  /// No description provided for @photoLogChangeFood.
  ///
  /// In tr, this message translates to:
  /// **'Yiyeceği değiştir'**
  String get photoLogChangeFood;

  /// No description provided for @photoLogChooseMatch.
  ///
  /// In tr, this message translates to:
  /// **'Bir eşleşme seç'**
  String get photoLogChooseMatch;

  /// No description provided for @photoLogAmbiguousQuantity.
  ///
  /// In tr, this message translates to:
  /// **'Miktarı seç'**
  String get photoLogAmbiguousQuantity;

  /// No description provided for @photoLogSelectMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğün seç'**
  String get photoLogSelectMeal;

  /// No description provided for @photoLogAllergyWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu yiyecek profilinizdeki alerjiyle eşleşiyor. Bu bir güvenlik doğrulaması değildir.'**
  String get photoLogAllergyWarning;

  /// No description provided for @photoLogDislikeWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu yiyecek profilinde sevmediğin yiyecekler arasında.'**
  String get photoLogDislikeWarning;

  /// No description provided for @photoLogDietWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu yiyecek profilindeki beslenme tercihiyle çakışıyor olabilir.'**
  String get photoLogDietWarning;

  /// No description provided for @photoLogAcknowledge.
  ///
  /// In tr, this message translates to:
  /// **'Uyarıyı gördüm, yine de ekle'**
  String get photoLogAcknowledge;

  /// No description provided for @photoLogCalculated.
  ///
  /// In tr, this message translates to:
  /// **'Besin değeri yiyecek kaydından'**
  String get photoLogCalculated;

  /// No description provided for @photoLogAssumption.
  ///
  /// In tr, this message translates to:
  /// **'{quantity} {unit} ≈ {grams} g. Miktarı değiştirebilirsin.'**
  String photoLogAssumption(String quantity, String unit, String grams);

  /// No description provided for @photoLogConfidence.
  ///
  /// In tr, this message translates to:
  /// **'Güven %{percent}'**
  String photoLogConfidence(String percent);

  /// No description provided for @photoLogCameraSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Kamerayla fotoğraf çek'**
  String get photoLogCameraSemantics;

  /// No description provided for @photoLogGallerySemantics.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden fotoğraf seç'**
  String get photoLogGallerySemantics;

  /// No description provided for @photoLogManualGrams.
  ///
  /// In tr, this message translates to:
  /// **'Manuel gram'**
  String get photoLogManualGrams;

  /// No description provided for @voiceUnitTea.
  ///
  /// In tr, this message translates to:
  /// **'çay kaşığı'**
  String get voiceUnitTea;

  /// No description provided for @voiceUnitSpoon.
  ///
  /// In tr, this message translates to:
  /// **'kaşık'**
  String get voiceUnitSpoon;

  /// No description provided for @voiceUnitPlate.
  ///
  /// In tr, this message translates to:
  /// **'tabak'**
  String get voiceUnitPlate;

  /// No description provided for @voiceUnitDessert.
  ///
  /// In tr, this message translates to:
  /// **'tatlı kaşığı'**
  String get voiceUnitDessert;

  /// No description provided for @captureErrorNotConfigured.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafla yiyecek tanıma şu anda yapılandırılmamış.'**
  String get captureErrorNotConfigured;

  /// No description provided for @captureErrorTimeout.
  ///
  /// In tr, this message translates to:
  /// **'İstek zaman aşımına uğradı. Lütfen tekrar dene.'**
  String get captureErrorTimeout;

  /// No description provided for @captureErrorOffline.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok. Fotoğraf ve ses tanıma şu an kullanılamaz.'**
  String get captureErrorOffline;

  /// No description provided for @captureErrorRateLimited.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla istek gönderildi. Biraz sonra tekrar dene.'**
  String get captureErrorRateLimited;

  /// No description provided for @captureErrorInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Yanıt okunamadı. Lütfen tekrar dene.'**
  String get captureErrorInvalid;

  /// No description provided for @captureErrorEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek bulunamadı.'**
  String get captureErrorEmpty;

  /// No description provided for @captureErrorMalformed.
  ///
  /// In tr, this message translates to:
  /// **'Yanıt bozuk. Lütfen tekrar dene.'**
  String get captureErrorMalformed;

  /// No description provided for @captureErrorUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet şu anda kullanılamıyor.'**
  String get captureErrorUnavailable;

  /// No description provided for @captureErrorImageTooLarge.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf çok büyük. Daha küçük bir görsel dene.'**
  String get captureErrorImageTooLarge;

  /// No description provided for @captureErrorUnsupportedImage.
  ///
  /// In tr, this message translates to:
  /// **'Bu görsel biçimi desteklenmiyor.'**
  String get captureErrorUnsupportedImage;

  /// No description provided for @captureErrorSpeechUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma tanıma bu cihazda kullanılamıyor. Metni yazabilirsin.'**
  String get captureErrorSpeechUnavailable;

  /// No description provided for @captureErrorTranscription.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma metne çevrilemedi.'**
  String get captureErrorTranscription;

  /// No description provided for @captureErrorAmbiguous.
  ///
  /// In tr, this message translates to:
  /// **'Miktar veya yiyecek belirsiz. Seçim yapmadan kaydedilmez.'**
  String get captureErrorAmbiguous;

  /// No description provided for @captureErrorNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşen yiyecek yok. Aramadan veya özel yiyecek oluşturmadan kaydedilmez.'**
  String get captureErrorNotFound;

  /// No description provided for @captureErrorConfirmation.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetmek için onay gerekli.'**
  String get captureErrorConfirmation;

  /// No description provided for @captureErrorDuplicate.
  ///
  /// In tr, this message translates to:
  /// **'Bu ekleme zaten işlendi.'**
  String get captureErrorDuplicate;

  /// No description provided for @captureErrorAllergy.
  ///
  /// In tr, this message translates to:
  /// **'Alerji uyarısı onaylanmadan yiyecek kaydedilmez.'**
  String get captureErrorAllergy;

  /// No description provided for @confirmNewPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme planını değiştirmek istiyor musun?'**
  String get confirmNewPlanTitle;

  /// No description provided for @confirmNewPlanMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanın kalan öğünleri yeniden oluşturulur. Önceki öğünler tutulmaz.'**
  String get confirmNewPlanMessage;

  /// No description provided for @confirmRegeneratePlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün planını yenilemek istiyor musun?'**
  String get confirmRegeneratePlanTitle;

  /// No description provided for @confirmRegeneratePlanMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün planlanan tüm öğünleri değişecek.'**
  String get confirmRegeneratePlanMessage;

  /// No description provided for @confirmFastingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oruç planını değiştirmek istiyor musun?'**
  String get confirmFastingTitle;

  /// No description provided for @confirmFastingMessage.
  ///
  /// In tr, this message translates to:
  /// **'Yeme penceren ve oruç hatırlatmaların yeni protokole göre güncellenir.'**
  String get confirmFastingMessage;

  /// No description provided for @waterAdd100.
  ///
  /// In tr, this message translates to:
  /// **'+100 ml'**
  String get waterAdd100;

  /// No description provided for @waterAdd250.
  ///
  /// In tr, this message translates to:
  /// **'+250 ml'**
  String get waterAdd250;

  /// No description provided for @waterAdd500.
  ///
  /// In tr, this message translates to:
  /// **'+500 ml'**
  String get waterAdd500;

  /// No description provided for @weeklyPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'7 Günlük Plan'**
  String get weeklyPlanTitle;

  /// No description provided for @confirmRegenerateWeekTitle.
  ///
  /// In tr, this message translates to:
  /// **'7 günlük planı yenilemek istiyor musun?'**
  String get confirmRegenerateWeekTitle;

  /// No description provided for @confirmRegenerateWeekMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanın öğünleri profilindeki kalori ve makro hedeflerine göre yeniden oluşturulur. Onaylamadan mevcut plan değişmez.'**
  String get confirmRegenerateWeekMessage;

  /// No description provided for @planChangeRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarifi değiştir'**
  String get planChangeRecipe;

  /// No description provided for @macroFiber.
  ///
  /// In tr, this message translates to:
  /// **'Lif'**
  String get macroFiber;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
