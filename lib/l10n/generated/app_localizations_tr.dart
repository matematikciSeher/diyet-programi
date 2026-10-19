// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Diyet Programı';

  @override
  String get navHome => 'Bugün';

  @override
  String get navDiary => 'Günlük';

  @override
  String get navPlans => 'Planlar';

  @override
  String get navProgress => 'İlerleme';

  @override
  String get navProfile => 'Profil';

  @override
  String get featureDashboard => 'Bugün';

  @override
  String get featureNutrition => 'Beslenme Planı';

  @override
  String get featureDiary => 'Öğün Günlüğü';

  @override
  String get featureFoodSearch => 'Yemek Ara';

  @override
  String get featureRecipes => 'Tarifler';

  @override
  String get featureMealPlans => 'Yemek Planı';

  @override
  String get featureShoppingList => 'Alışveriş Listesi';

  @override
  String get featureWater => 'Su Takibi';

  @override
  String get featureWeight => 'Kilo Takibi';

  @override
  String get featureMeasurements => 'Vücut Ölçümleri';

  @override
  String get featureProgress => 'İlerleme';

  @override
  String get featureFasting => 'Aralıklı Oruç';

  @override
  String get featureActivity => 'Aktivite';

  @override
  String get featureNotifications => 'Bildirimler';

  @override
  String get featureAiCoach => 'Beslenme Asistanı';

  @override
  String get featureBarcode => 'Barkod Tara';

  @override
  String get featureProfile => 'Profil';

  @override
  String get featurePremium => 'Premium';

  @override
  String get featureSettings => 'Ayarlar';

  @override
  String get featurePersonalInfo => 'Kişisel Bilgiler';

  @override
  String get personalInfoSaved => 'Bilgilerin kaydedildi.';

  @override
  String get personalInfoEmptyTitle => 'Profil bilgisi yok';

  @override
  String get personalInfoEmptyMessage =>
      'Hedeflerin ve tercihlerin burada toplanır. Onboarding’i tamamladığında bu alanlar dolar.';

  @override
  String get personalInfoBasics => 'Temel bilgiler';

  @override
  String get personalInfoPreferences => 'Beslenme tercihleri';

  @override
  String get personalInfoTargetsTitle => 'Günlük hedefler';

  @override
  String get personalInfoTargetsHint =>
      'Kalori ve makro hedefleri profilinden okunur; Beslenme Planı bunları ayrı saklamaz.';

  @override
  String get personalInfoCurrentWeightHint =>
      'Güncel kilo Kilo Takibi ekranından güncellenir.';

  @override
  String get personalInfoOpenWeight => 'Kilo takibine git';

  @override
  String get personalInfoRecalculate => 'Hedefleri yeniden hesapla';

  @override
  String get personalInfoTargetsUpdated =>
      'Kalori ve makro hedeflerin güncellendi.';

  @override
  String get personalInfoPlanUpdated =>
      'Beslenme planın yeni tercihlerinle güncellendi.';

  @override
  String get personalInfoName => 'Ad';

  @override
  String get personalInfoAge => 'Yaş';

  @override
  String get personalInfoHeight => 'Boy';

  @override
  String get personalInfoTargetWeight => 'Hedef kilo';

  @override
  String get personalInfoWaterGoal => 'Günlük su hedefi';

  @override
  String get onboardingHeadline => 'Size özel beslenme planı';

  @override
  String get onboardingSubtitle =>
      'Hedeflerinize, yaşam tarzınıza ve damak tadınıza göre hazırlanan bir plan ile başlayın.';

  @override
  String get signInTitle => 'Hesabınıza giriş yapın';

  @override
  String get signInSubtitle =>
      'İlerlemeniz tüm cihazlarınızda güvenle saklanır.';

  @override
  String dashboardGreeting(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'morning': 'Günaydın',
      'afternoon': 'İyi günler',
      'evening': 'İyi akşamlar',
      'other': 'Merhaba',
    });
    return '$_temp0 👋';
  }

  @override
  String dashboardGreetingNamed(String period, String name) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'morning': 'Günaydın',
      'afternoon': 'İyi günler',
      'evening': 'İyi akşamlar',
      'other': 'Merhaba',
    });
    return '$_temp0, $name 👋';
  }

  @override
  String dashboardMotivation(String index) {
    String _temp0 = intl.Intl.selectLogic(index, {
      '0': 'Küçük adımlar büyük farklar yaratır.',
      '1': 'Bugün tabağının yarısını sebzeyle doldurmayı dene.',
      '2': 'Su şişen yanında olsun; susamadan iç.',
      '3': 'Mükemmel değil, istikrarlı olmak kazandırır.',
      '4': 'Proteinli bir kahvaltı güne dengeli başlatır.',
      '5': 'Yavaş ye; tokluk hissi yaklaşık 20 dakikada gelir.',
      'other': 'Dünkü seninle yarış, başkalarıyla değil.',
    });
    return '$_temp0';
  }

  @override
  String get dashboardCaloriesTitle => 'Günlük kalori';

  @override
  String dashboardKcalOfTarget(String consumed, String target) {
    return '$consumed / $target kcal';
  }

  @override
  String get dashboardKcalLeft => 'kcal kaldı';

  @override
  String get dashboardKcalOver => 'kcal fazla';

  @override
  String get dashboardEaten => 'Alınan';

  @override
  String get dashboardTarget => 'Hedef';

  @override
  String get dashboardRemaining => 'Kalan';

  @override
  String kcalValue(String value) {
    return '$value kcal';
  }

  @override
  String gramsOfTarget(String value, String target) {
    return '$value / $target g';
  }

  @override
  String macroSummaryShort(String protein, String carbs, String fat) {
    return 'P $protein g · K $carbs g · Y $fat g';
  }

  @override
  String get dashboardQuickActions => 'Hızlı ekle';

  @override
  String get quickAddFood => 'Yemek ekle';

  @override
  String get quickAddPhoto => 'Fotoğrafla';

  @override
  String get quickAddBarcode => 'Barkod tara';

  @override
  String get quickAddVoice => 'Sesle ekle';

  @override
  String get dashboardMealsTitle => 'Bugünün öğünleri';

  @override
  String get mealBreakfast => 'Kahvaltı';

  @override
  String get mealLunch => 'Öğle';

  @override
  String get mealDinner => 'Akşam';

  @override
  String get mealSnack => 'Atıştırmalık';

  @override
  String get mealEmpty => 'Henüz bir şey eklenmedi';

  @override
  String mealAddFoodTo(String meal) {
    return '$meal öğününe yemek ekle';
  }

  @override
  String mealMoreItems(int count) {
    return '+$count yiyecek daha';
  }

  @override
  String get actionSeeAll => 'Tümü';

  @override
  String get actionUndo => 'Geri al';

  @override
  String get dashboardWaterTitle => 'Su';

  @override
  String waterGlassesProgress(int count, int goal) {
    return '$count / $goal bardak';
  }

  @override
  String litersOfTarget(String value, String target) {
    return '$value / $target L';
  }

  @override
  String waterAddAmount(int ml) {
    return '+$ml ml';
  }

  @override
  String waterAdded(int ml) {
    return '$ml ml su eklendi';
  }

  @override
  String get waterGoalReached => 'Günlük su hedefine ulaştın!';

  @override
  String get dashboardActivityTitle => 'Aktivite';

  @override
  String get activitySteps => 'Adım';

  @override
  String get activityActiveKcal => 'Aktif kalori';

  @override
  String get activityExercise => 'Egzersiz';

  @override
  String minutesValue(String value) {
    return '$value dk';
  }

  @override
  String stepsGoal(String goal) {
    return 'Hedef $goal';
  }

  @override
  String get dashboardScoreTitle => 'Günlük beslenme skoru';

  @override
  String get scoreOutOf => '/ 100';

  @override
  String get scoreBandStarting => 'Güne başlıyoruz';

  @override
  String get scoreBandFair => 'Geliştirilebilir';

  @override
  String get scoreBandGood => 'İyi gidiyorsun';

  @override
  String get scoreBandGreat => 'Harika gidiyorsun';

  @override
  String get scoreFactorCalories => 'Kalori hedefine yakınlık';

  @override
  String get scoreFactorProtein => 'Protein hedefi';

  @override
  String get scoreFactorFiber => 'Lif';

  @override
  String get scoreFactorWater => 'Su';

  @override
  String get scoreFactorProduce => 'Sebze ve meyve';

  @override
  String get scoreFactorProcessed => 'İşlenmiş gıda oranı';

  @override
  String get scoreFactorMealRhythm => 'Öğün düzeni';

  @override
  String get scoreTipCalories =>
      'Hedefine yaklaşmak için dengeli bir öğün ekleyebilirsin.';

  @override
  String get scoreTipProtein =>
      'Bir sonraki öğününe bir protein kaynağı eklemeyi dene.';

  @override
  String get scoreTipFiber =>
      'Tam tahıl, baklagil ve sebzeyle lif alımını artırabilirsin.';

  @override
  String get scoreTipWater => 'Bir bardak su içmek için iyi bir an.';

  @override
  String get scoreTipProduce => 'Bir porsiyon sebze ya da meyve eklemeyi dene.';

  @override
  String get scoreTipProcessed =>
      'Paketli atıştırmalıklar yerine doğal seçenekleri tercih et.';

  @override
  String get scoreTipMealRhythm =>
      'Öğünlerini düzenli kaydetmek dengeyi kolaylaştırır.';

  @override
  String scorePoints(String points, int max) {
    return '$points / $max';
  }

  @override
  String get scoreDetails => 'Skor nasıl hesaplanır?';

  @override
  String get scoreDisclaimerShort =>
      'Genel bir alışkanlık göstergesidir, tıbbi teşhis değildir.';

  @override
  String get scoreDisclaimerLong =>
      'Beslenme skoru; kalori hedefine yakınlık, protein, lif, su, sebze-meyve tüketimi, işlenmiş gıda oranı, makro dengesi ve öğün düzenine göre hesaplanan genel bir göstergedir. Bilimsel bir tıbbi değerlendirme ya da teşhis değildir. Sağlığınla ilgili kararlar için doktoruna veya diyetisyenine danış.';

  @override
  String get dashboardPlanTitle => 'Bugünün planı';

  @override
  String get planLogged => 'Eklendi';

  @override
  String get planEmpty => 'Bugün için planlanmış öğün yok.';

  @override
  String get planCreate => 'Plan oluştur';

  @override
  String get planTodayTitle => 'Bugün için planım';

  @override
  String planDayTotal(String kcal, String target) {
    return '$kcal / $target kcal';
  }

  @override
  String get planApproxNote =>
      'Besin değerleri yaklaşıktır; tarif ve porsiyona göre değişebilir.';

  @override
  String planPortion(String factor) {
    return '$factor porsiyon';
  }

  @override
  String get planSwapMeal => 'Değiştir';

  @override
  String get planLogMeal => 'Günlüğe ekle';

  @override
  String planMealLogged(String meal) {
    return '$meal günlüğe eklendi';
  }

  @override
  String planMealSwapped(String meal, String title) {
    return '$meal için yeni öneri: $title';
  }

  @override
  String get planRegenerate => 'Planı yenile';

  @override
  String get planAssistantName => 'Plan asistanı';

  @override
  String get planChangeTitle => 'Bu planı değiştir';

  @override
  String get planChangeSubtitle =>
      'Sevmediğin bir şey mi var? Yaz, alternatif hazırlayayım.';

  @override
  String get planChangeHint => 'Örn. Tavuğu sevmiyorum';

  @override
  String get planChangeSend => 'Gönder';

  @override
  String get planSuggestionDislike => 'Tavuğu sevmiyorum';

  @override
  String get planSuggestionSwapDinner => 'Akşam yemeğini değiştir';

  @override
  String get planSuggestionNoEggBreakfast => 'Kahvaltıda yumurta olmasın';

  @override
  String get planSuggestionFish => 'Akşam balık olsun';

  @override
  String get planSuggestionWholePlan => 'Bu planı değiştir';

  @override
  String planReplyExcluded(String ingredients) {
    return 'Şu öğünleri $ingredients içermeyen alternatiflerle değiştirdim:';
  }

  @override
  String planReplyChangeLine(String meal, String from, String to) {
    return '$meal: $from → $to';
  }

  @override
  String planReplyAlreadyAbsent(String ingredients) {
    return 'Planında zaten $ingredients yok.';
  }

  @override
  String planReplyRemembered(String ingredients) {
    return 'Bundan sonraki planlarda $ingredients önermeyeceğim.';
  }

  @override
  String planReplyNoAlternative(String meal) {
    return '$meal için tercihlerine uyan başka bir öneri bulamadım.';
  }

  @override
  String planReplyDiet(String diet) {
    return 'Planı güncelledim ($diet):';
  }

  @override
  String planReplyDietUnchanged(String diet) {
    return 'Planın zaten buna uygun ($diet).';
  }

  @override
  String planReplyPreferred(String ingredients) {
    return 'İstediğin gibi $ingredients içeren bir öğün ekledim:';
  }

  @override
  String planReplyAlreadyPresent(String ingredients, String meals) {
    return 'Planında zaten $ingredients var: $meals.';
  }

  @override
  String planReplyPreferredNone(String ingredients) {
    return 'Tercihlerine uyan ve $ingredients içeren bir öneri bulamadım.';
  }

  @override
  String get planReplySwapped => 'Yeni önerilerim:';

  @override
  String get planReplyRegenerated =>
      'Senin için yeni bir günlük plan hazırladım.';

  @override
  String get planReplyNotUnderstood =>
      'Tam anlayamadım. Örneğin \"Tavuğu sevmiyorum\", \"Akşam yemeğini değiştir\" ya da \"Kahvaltıda yumurta olmasın\" yazabilirsin.';

  @override
  String get planIngredientChicken => 'tavuk';

  @override
  String get planIngredientRedMeat => 'kırmızı et';

  @override
  String get planIngredientFish => 'balık';

  @override
  String get planIngredientShellfish => 'karides ve midye';

  @override
  String get planIngredientEgg => 'yumurta';

  @override
  String get planIngredientMilk => 'süt';

  @override
  String get planIngredientCheese => 'peynir';

  @override
  String get planIngredientYogurt => 'yoğurt';

  @override
  String get planIngredientLegumes => 'baklagil';

  @override
  String get planIngredientGluten => 'gluten';

  @override
  String get planIngredientOats => 'yulaf';

  @override
  String get planIngredientNuts => 'kuruyemiş';

  @override
  String get planIngredientPeanut => 'yer fıstığı';

  @override
  String get planIngredientSesame => 'susam';

  @override
  String get planIngredientSoy => 'soya';

  @override
  String get planIngredientEggplant => 'patlıcan';

  @override
  String get planIngredientMushroom => 'mantar';

  @override
  String get featurePhotoLog => 'Fotoğrafla Ekle';

  @override
  String get featureVoiceLog => 'Sesle Ekle';

  @override
  String get actionGetStarted => 'Başlayalım';

  @override
  String get actionContinue => 'Devam et';

  @override
  String get actionContinueAsGuest => 'Misafir olarak devam et';

  @override
  String get actionSignIn => 'Giriş yap';

  @override
  String get actionSignUp => 'Hesap oluştur';

  @override
  String get actionForgotPassword => 'Parolamı unuttum';

  @override
  String get actionSignInWithGoogle => 'Google ile devam et';

  @override
  String get actionSignInWithApple => 'Apple ile devam et';

  @override
  String get actionHaveAccount => 'Hesabın var mı? Giriş yap';

  @override
  String get actionNeedAccount => 'Yeni misin? Hesap oluştur';

  @override
  String get actionDeleteAccount => 'Hesabı sil';

  @override
  String get signInEmailLabel => 'E-posta';

  @override
  String get signInPasswordLabel => 'Parola';

  @override
  String get signInNameLabel => 'Ad (isteğe bağlı)';

  @override
  String get signInOrDivider => 'veya';

  @override
  String get signInGuestAccount => 'Misafir hesap';

  @override
  String get passwordResetSent =>
      'Bu e-posta ile kayıtlı bir hesap varsa sıfırlama bağlantısı gönderilir.';

  @override
  String get deleteAccountTitle => 'Hesap silinsin mi?';

  @override
  String get deleteAccountMessage =>
      'Hesabın, buluttaki verilerin ve bu cihazdaki kişisel kayıtların silinir. Bu işlem geri alınamaz.';

  @override
  String get authInvalidEmail => 'Geçerli bir e-posta adresi gir.';

  @override
  String get authInvalidCredentials => 'E-posta veya parola hatalı.';

  @override
  String get authEmailInUse => 'Bu e-posta ile bir hesap zaten var.';

  @override
  String get authWeakPassword =>
      'Daha güçlü bir parola seç (en az 6 karakter).';

  @override
  String get authTooManyRequests =>
      'Çok fazla deneme. Bir süre bekleyip tekrar dene.';

  @override
  String get authCancelled => 'Giriş iptal edildi.';

  @override
  String get authRequiresRecentLogin =>
      'Hesabı silmek için kısa süre önce giriş yapmış olman gerekiyor. Çıkış yapıp tekrar giriş yaptıktan sonra yeniden dene.';

  @override
  String get errorServiceUnavailable =>
      'Bu giriş yöntemi henüz yapılandırılmadı.';

  @override
  String get actionSignOut => 'Çıkış yap';

  @override
  String get actionRetry => 'Tekrar dene';

  @override
  String get actionCancel => 'Vazgeç';

  @override
  String get actionSave => 'Kaydet';

  @override
  String get actionAdd => 'Ekle';

  @override
  String get actionRemove => 'Kaldır';

  @override
  String get comingSoonTitle => 'Yakında';

  @override
  String comingSoonMessage(String feature) {
    return '$feature bölümü hazırlanıyor.';
  }

  @override
  String get emptyStateTitle => 'Henüz bir şey yok';

  @override
  String get errorGeneric => 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';

  @override
  String get errorNetwork => 'İnternet bağlantınızı kontrol edin.';

  @override
  String get settingsTheme => 'Görünüm';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get pageNotFound => 'Sayfa bulunamadı';

  @override
  String get splashTagline => 'Dengeli beslen, iyi hisset';

  @override
  String get onboardingWelcomeTitle => 'Hoş geldin';

  @override
  String get onboardingWelcomeBody =>
      'Birkaç kısa soruyla sana özel kalori ve besin hedeflerini oluşturalım. Yalnızca birkaç dakika sürer.';

  @override
  String get onboardingBenefitPlanTitle => 'Sana özel plan';

  @override
  String get onboardingBenefitPlanBody =>
      'Hedefine, vücuduna ve yaşam tarzına göre bilimsel formüllerle hesaplanan günlük kalori ve makro hedefleri.';

  @override
  String get onboardingBenefitTrackingTitle => 'Zahmetsiz takip';

  @override
  String get onboardingBenefitTrackingBody =>
      'Öğünlerini, suyunu ve kilonu saniyeler içinde kaydet; ilerlemeni net grafiklerle izle.';

  @override
  String get onboardingBenefitHabitsTitle => 'Kalıcı alışkanlıklar';

  @override
  String get onboardingBenefitHabitsBody =>
      'Şok diyet yok. Sağlıklı bir tempo ve sevdiğin yiyeceklerle sürdürülebilir sonuçlar.';

  @override
  String get onboardingSkipIntro => 'Atla';

  @override
  String get onboardingBack => 'Geri';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingFinish => 'Planımı başlat';

  @override
  String onboardingStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String onboardingProgressSemantics(int current, int total) {
    return 'Adım $current / $total';
  }

  @override
  String get onboardingOptional => 'İsteğe bağlı';

  @override
  String get qNameTitle => 'Sana nasıl hitap edelim?';

  @override
  String get qNameSubtitle => 'Boş bırakıp devam edebilirsin.';

  @override
  String get qNameHint => 'Adın';

  @override
  String get qGoalTitle => 'Ana hedefin ne?';

  @override
  String get qGoalSubtitle => 'Planını bu hedefe göre şekillendireceğiz.';

  @override
  String get goalLoseWeight => 'Kilo vermek';

  @override
  String get goalLoseWeightDesc => 'Sağlıklı ve kontrollü bir kalori açığıyla';

  @override
  String get goalMaintainWeight => 'Kilo korumak';

  @override
  String get goalMaintainWeightDesc => 'Mevcut kilonda dengede kal';

  @override
  String get goalGainWeight => 'Kilo almak';

  @override
  String get goalGainWeightDesc => 'Kademeli ve sağlıklı şekilde';

  @override
  String get goalBuildMuscle => 'Kas geliştirmek';

  @override
  String get goalBuildMuscleDesc => 'Yüksek protein, ölçülü kalori fazlası';

  @override
  String get goalEatHealthier => 'Daha sağlıklı beslenmek';

  @override
  String get goalEatHealthierDesc => 'Kalite, çeşitlilik ve denge odaklı';

  @override
  String get qGenderTitle => 'Cinsiyetin?';

  @override
  String get qGenderSubtitle =>
      'Bazal metabolizma hızı hesaplamasında kullanılır.';

  @override
  String get genderFemale => 'Kadın';

  @override
  String get genderMale => 'Erkek';

  @override
  String get genderUnspecified => 'Belirtmek istemiyorum';

  @override
  String get genderUnspecifiedDesc =>
      'Hesaplamada iki değerin ortalaması kullanılır';

  @override
  String get qAgeTitle => 'Kaç yaşındasın?';

  @override
  String get qAgeSubtitle => 'Yaş, günlük enerji ihtiyacını etkiler.';

  @override
  String get unitYears => 'yaş';

  @override
  String get qHeightTitle => 'Boyun kaç?';

  @override
  String get qHeightSubtitle => 'Santimetre cinsinden gir.';

  @override
  String get unitCm => 'cm';

  @override
  String get qWeightTitle => 'Şu anki kilon kaç?';

  @override
  String get qWeightSubtitle => 'Sabah aç karnına ölçülen değer en doğrusudur.';

  @override
  String get unitKg => 'kg';

  @override
  String get qTargetWeightTitle => 'Hedef kilon kaç?';

  @override
  String get qTargetWeightSubtitle => 'Gerçekçi bir hedef motivasyonunu korur.';

  @override
  String targetWeightCurrent(String weight) {
    return 'Şu anki kilon: $weight kg';
  }

  @override
  String targetWeightDiff(String diff) {
    return 'Fark: $diff kg';
  }

  @override
  String targetWeightHealthyMin(String weight) {
    return 'Boyuna göre sağlıklı alt sınır: $weight kg';
  }

  @override
  String inputRangeHint(String min, String max, String unit) {
    return '$min–$max $unit';
  }

  @override
  String get qActivityTitle => 'Günlük aktivite seviyen?';

  @override
  String get qActivitySubtitle =>
      'İşini ve gün içindeki genel hareketliliğini düşün.';

  @override
  String get activitySedentary => 'Hareketsiz';

  @override
  String get activitySedentaryDesc => 'Masa başı iş, çok az yürüyüş';

  @override
  String get activityLight => 'Az aktif';

  @override
  String get activityLightDesc => 'Hafif hareket, gün içinde biraz yürüyüş';

  @override
  String get activityModerate => 'Orta aktif';

  @override
  String get activityModerateDesc =>
      'Gün boyu ayakta ya da düzenli hareket halinde';

  @override
  String get activityActive => 'Çok aktif';

  @override
  String get activityActiveDesc => 'Fiziksel iş veya yoğun günlük hareket';

  @override
  String get activityVeryActive => 'Çok yoğun aktif';

  @override
  String get activityVeryActiveDesc =>
      'Ağır fiziksel iş veya günde iki antrenman';

  @override
  String get qExerciseTitle => 'Ne sıklıkla egzersiz yapıyorsun?';

  @override
  String get qExerciseSubtitle =>
      'Yürüyüş, spor salonu, koşu, yüzme gibi planlı egzersizler.';

  @override
  String get exerciseNone => 'Hiç ya da nadiren';

  @override
  String get exerciseOneToTwo => 'Haftada 1–2 gün';

  @override
  String get exerciseThreeToFour => 'Haftada 3–4 gün';

  @override
  String get exerciseFiveToSix => 'Haftada 5–6 gün';

  @override
  String get exerciseDaily => 'Her gün';

  @override
  String get qDietTitle => 'Beslenme tercihin?';

  @override
  String get qDietSubtitle => 'Önerilerimiz bu tercihe uygun olacak.';

  @override
  String get dietOmnivore => 'Her şeyi yerim';

  @override
  String get dietOmnivoreDesc => 'Et, balık, süt ürünleri ve bitkisel gıdalar';

  @override
  String get dietVegetarian => 'Vejetaryen';

  @override
  String get dietVegetarianDesc =>
      'Et ve balık yok; yumurta ve süt ürünleri var';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietVeganDesc => 'Hiçbir hayvansal ürün yok';

  @override
  String get dietPescatarian => 'Pesketaryen';

  @override
  String get dietPescatarianDesc => 'Et yok; balık ve deniz ürünleri var';

  @override
  String get qAllergiesTitle => 'Alerji veya intoleransın var mı?';

  @override
  String get qAllergiesSubtitle =>
      'Birden fazla seçebilirsin. Bu besinleri önerilerimizden çıkarırız.';

  @override
  String get allergyNone => 'Yok';

  @override
  String get allergenGluten => 'Gluten';

  @override
  String get allergenLactose => 'Laktoz';

  @override
  String get allergenMilk => 'Süt proteini';

  @override
  String get allergenEgg => 'Yumurta';

  @override
  String get allergenPeanut => 'Yer fıstığı';

  @override
  String get allergenTreeNuts => 'Kuruyemiş';

  @override
  String get allergenSoy => 'Soya';

  @override
  String get allergenFish => 'Balık';

  @override
  String get allergenShellfish => 'Kabuklu deniz ürünleri';

  @override
  String get allergenSesame => 'Susam';

  @override
  String get allergyOtherHint => 'Başka bir alerji ekle';

  @override
  String get qDislikedTitle => 'Sevmediğin yiyecekler var mı?';

  @override
  String get qDislikedSubtitle => 'Seç ya da kendin yaz. Boş bırakabilirsin.';

  @override
  String get dislikedHint => 'Örn. bamya';

  @override
  String get foodOnion => 'Soğan';

  @override
  String get foodGarlic => 'Sarımsak';

  @override
  String get foodMushroom => 'Mantar';

  @override
  String get foodEggplant => 'Patlıcan';

  @override
  String get foodOffal => 'Sakatat';

  @override
  String get foodSeafood => 'Deniz ürünleri';

  @override
  String get foodOlive => 'Zeytin';

  @override
  String get foodSpicy => 'Acı';

  @override
  String get foodBroccoli => 'Brokoli';

  @override
  String get foodLegumes => 'Baklagiller';

  @override
  String get foodCoriander => 'Kişniş';

  @override
  String get foodCelery => 'Kereviz';

  @override
  String get qMealsTitle => 'Günde kaç öğün yemek istersin?';

  @override
  String get qMealsSubtitle =>
      'Kalori hedefin öğünlerine göre paylaştırılacak.';

  @override
  String mealsCount(int count) {
    return '$count öğün';
  }

  @override
  String get meals2Desc => 'İki doyurucu ana öğün';

  @override
  String get meals3Desc => 'Kahvaltı, öğle ve akşam';

  @override
  String get meals4Desc => '3 ana öğün + 1 ara öğün';

  @override
  String get meals5Desc => '3 ana öğün + 2 ara öğün';

  @override
  String get qBreakfastTitle => 'Kahvaltı alışkanlığın nasıl?';

  @override
  String get qBreakfastSubtitle => 'Öğün planını buna göre düzenleyeceğiz.';

  @override
  String get breakfastAlways => 'Her gün kahvaltı yaparım';

  @override
  String get breakfastSometimes => 'Bazen yaparım';

  @override
  String get breakfastNever => 'Genelde kahvaltı yapmam';

  @override
  String get qWaterTitle => 'Günlük su hedefin?';

  @override
  String get qWaterSubtitle =>
      'Kilona ve aktivitene göre bir öneri hazırladık; dilediğin gibi ayarlayabilirsin.';

  @override
  String waterLiters(String liters) {
    return '$liters L';
  }

  @override
  String waterRecommended(String liters) {
    return 'Önerilen: $liters L';
  }

  @override
  String get waterUseRecommended => 'Öneriyi kullan';

  @override
  String waterGlasses(int count) {
    return 'Yaklaşık $count bardak';
  }

  @override
  String get qFastingTitle => 'Aralıklı oruç denemek ister misin?';

  @override
  String get qFastingSubtitle =>
      'Tamamen isteğe bağlı; istediğin zaman değiştirebilirsin.';

  @override
  String get fastingNone => 'İstemiyorum';

  @override
  String get fastingNoneDesc => 'Normal öğün düzenimle devam edeceğim';

  @override
  String fastingWindow(int fast, int eat) {
    return '$fast:$eat';
  }

  @override
  String fastingWindowDesc(int fast, int eat) {
    return '$fast saat oruç, $eat saat yemek penceresi';
  }

  @override
  String get fastingCautionNote =>
      'Hamilelik, emzirme, diyabet, yeme bozukluğu öyküsü veya düzenli ilaç kullanımı varsa aralıklı oruca başlamadan önce doktoruna danış.';

  @override
  String get qTargetDateTitle => 'Hedefine ne zaman ulaşmak istersin?';

  @override
  String get qTargetDateSubtitle => 'Güvenli bir tempo, kalıcı sonuç demektir.';

  @override
  String get targetDateRecommended => 'Önerilen güvenli tempo';

  @override
  String targetDateRecommendedDesc(String date) {
    return 'Tahmini $date';
  }

  @override
  String get targetDateCustom => 'Kendi tarihimi seçeceğim';

  @override
  String get targetDateCustomPick => 'Takvimden seç';

  @override
  String targetDateTooSoon(String required, String max) {
    return 'Bu tarih için haftada $required kg değişim gerekir. Güvenli üst sınır $max kg olduğundan planın güvenli tempoya göre hazırlanacak.';
  }

  @override
  String get errorSelectOption => 'Devam etmek için bir seçenek belirle.';

  @override
  String get errorValueRequired => 'Lütfen bir değer gir.';

  @override
  String errorOutOfRange(String min, String max) {
    return '$min ile $max arasında bir değer gir.';
  }

  @override
  String get errorTargetBelowCurrent =>
      'Kilo verme hedefinde hedef kilon şu anki kilondan düşük olmalı.';

  @override
  String get errorTargetAboveCurrent =>
      'Bu hedef için hedef kilon şu anki kilondan yüksek olmalı.';

  @override
  String errorTargetBelowHealthy(String min) {
    return 'Bu hedef boyuna göre sağlıklı aralığın altında. En az $min kg olmalı.';
  }

  @override
  String get errorTargetDatePast => 'Hedef tarih bugünden sonra olmalı.';

  @override
  String get summaryTitle => 'Planın hazır';

  @override
  String summaryTitleNamed(String name) {
    return '$name, planın hazır';
  }

  @override
  String get summarySubtitle =>
      'Verdiğin bilgilere göre hesapladığımız günlük hedeflerin:';

  @override
  String get summaryDailyTarget => 'Önerilen günlük kalori';

  @override
  String get summaryKcalPerDay => 'kcal / gün';

  @override
  String summaryMaintenance(String kcal) {
    return 'Tahmini günlük ihtiyacın: $kcal kcal';
  }

  @override
  String summaryDeficit(String kcal) {
    return '$kcal kcal açık';
  }

  @override
  String summarySurplus(String kcal) {
    return '$kcal kcal fazla';
  }

  @override
  String get summaryBalanced => 'Enerji dengesi';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Karbonhidrat';

  @override
  String get macroFat => 'Yağ';

  @override
  String gramsValue(String value) {
    return '$value g';
  }

  @override
  String get summaryWater => 'Su hedefi';

  @override
  String get summaryGoalDuration => 'Tahmini hedef süresi';

  @override
  String summaryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '~$count hafta',
      one: '~1 hafta',
    );
    return '$_temp0';
  }

  @override
  String summaryGoalDate(String date) {
    return 'Tahmini $date';
  }

  @override
  String summaryWeeklyRate(String kg) {
    return 'Haftada yaklaşık $kg kg';
  }

  @override
  String get summaryNoDurationMaintain =>
      'Hedefin mevcut kilonu korumak; bir bitiş tarihi yok.';

  @override
  String get summaryNoDurationSlow =>
      'Güvenli kalori sınırı nedeniyle kilo değişimi çok yavaş olacak. Günlük hareketi artırmak süreci hızlandırır.';

  @override
  String summaryMetrics(String bmr, String bmi) {
    return 'Bazal metabolizma $bmr kcal · VKİ $bmi';
  }

  @override
  String get summaryFormulaNote =>
      'Mifflin-St Jeor denklemi ve aktivite katsayısıyla hesaplanmıştır.';

  @override
  String get noticeTitle => 'Dikkat etmen gerekenler';

  @override
  String get noticeMinor =>
      '18 yaşın altındasın. Büyüme döneminde kalori kısıtlaması önerilmez; hedefin sınırlı tutuldu. Lütfen bir doktor veya diyetisyenle görüş.';

  @override
  String get noticeSenior =>
      '65 yaş ve üzerinde kas kaybını önlemek için yeterli protein önemlidir. Planını bir uzmanla birlikte oluşturman önerilir.';

  @override
  String get noticeUnderweight =>
      'Vücut kitle indeksin sağlıklı aralığın altında. Kilo vermen önerilmez; bir sağlık uzmanına danışmanı öneririz.';

  @override
  String get noticeSevereObesity =>
      'Vücut kitle indeksin yüksek. En güvenli ilerleme için doktor veya diyetisyen takibi önerilir.';

  @override
  String get noticePaceAdjusted =>
      'Seçtiğin tarih için gereken tempo güvenli sınırın üzerinde olduğundan hedefin daha sağlıklı bir tempoya göre ayarlandı.';

  @override
  String get noticeCalorieFloor =>
      'Kalori hedefin güvenli alt sınırın altına inmeyecek şekilde ayarlandı.';

  @override
  String get noticeFasting =>
      'Profilin için aralıklı oruç ek dikkat gerektirir. Başlamadan önce doktoruna danış.';

  @override
  String get disclaimerTitle => 'Bilgilendirme';

  @override
  String get disclaimerBody =>
      'Bu uygulama genel bilgilendirme amaçlıdır ve doktor veya diyetisyen önerisinin yerine geçmez. Hamilelik, emzirme, kronik hastalık (diyabet, böbrek, kalp vb.), yeme bozukluğu öyküsü ya da düzenli ilaç kullanımı gibi durumlarda beslenme planını bir sağlık profesyoneliyle birlikte oluştur.';

  @override
  String get foodAddTitle => 'Yemek ekle';

  @override
  String get foodSearchHint => 'Yiyecek, yemek veya ürün ara...';

  @override
  String get foodClearSearch => 'Aramayı temizle';

  @override
  String get foodTabRecent => 'Son kullanılanlar';

  @override
  String get foodTabFavorites => 'Favoriler';

  @override
  String get foodTabMine => 'Benimkiler';

  @override
  String get foodRecentEmpty =>
      'Eklediğin yiyecekler burada görünecek; tek dokunuşla tekrar ekleyebilirsin.';

  @override
  String get foodFavoritesEmpty =>
      'Yiyecek detayındaki kalp simgesiyle favorilerine ekleyebilirsin.';

  @override
  String get foodMineEmpty =>
      'Kendi yiyeceklerini ve tariflerini oluşturabilirsin.';

  @override
  String get foodDatabaseUnavailable =>
      'Yiyecek veritabanına şu anda ulaşılamıyor.';

  @override
  String get foodDatabaseUnavailableHint =>
      'Son kullanılanlar, favoriler ve kendi yiyeceklerin çalışmaya devam eder. Çevrimiçi olunca tekrar dene veya özel yiyecek oluştur.';

  @override
  String get foodAttributionOff =>
      'Paketli ürün verileri Open Food Facts gönüllülerinden gelir (ODbL).';

  @override
  String get foodAttributionOffLink => 'Open Food Facts';

  @override
  String get foodAttributionOffLicense =>
      'Open Food Facts verileri ODbL kapsamında kullanılır.';

  @override
  String get foodCategoryFruit => 'Meyve';

  @override
  String get foodCategoryVegetable => 'Sebze';

  @override
  String get foodCategoryProtein => 'Protein';

  @override
  String get foodCategoryDairy => 'Süt ürünleri';

  @override
  String get foodCategoryGrain => 'Tahıl';

  @override
  String get foodCategoryBeverage => 'İçecek';

  @override
  String foodNoResults(String query) {
    return '\"$query\" için sonuç bulunamadı';
  }

  @override
  String get foodNoResultsHint =>
      'Farklı bir yazım dene ya da kendi yiyeceğini oluştur.';

  @override
  String get foodCreateCustom => 'Yiyecek oluştur';

  @override
  String get foodCreateRecipe => 'Tarif oluştur';

  @override
  String foodSampleDataNotice(String source) {
    return 'Örnek veri: Besin değerleri $source kayıtlarından yuvarlanmıştır; ürüne ve tarife göre farklılık gösterebilir.';
  }

  @override
  String get foodSampleBadge => 'Örnek veri';

  @override
  String get foodCustomBadge => 'Kendi yiyeceğim';

  @override
  String get foodRecipeBadge => 'Tarif';

  @override
  String foodQuickAdd(String food) {
    return '$food ekle';
  }

  @override
  String foodAddedTo(String food, String meal) {
    return '$food, $meal öğününe eklendi';
  }

  @override
  String get foodMeal => 'Öğün';

  @override
  String get foodAmount => 'Miktar';

  @override
  String get foodUnit => 'Ölçü';

  @override
  String get foodNutrition => 'Besin değerleri';

  @override
  String foodPer100(String unit, String kcal) {
    return '100 $unit için $kcal kcal';
  }

  @override
  String foodAddToMeal(String meal) {
    return '$meal öğününe ekle';
  }

  @override
  String get foodFavoriteAdd => 'Favorilere ekle';

  @override
  String get foodFavoriteRemove => 'Favorilerden çıkar';

  @override
  String get foodIngredients => 'Malzemeler';

  @override
  String foodSource(String source) {
    return 'Kaynak: $source';
  }

  @override
  String get foodNotFound => 'Yiyecek bulunamadı.';

  @override
  String get foodInvalidAmount => 'Geçerli bir miktar gir.';

  @override
  String get foodDelete => 'Sil';

  @override
  String foodDeleted(String name) {
    return '$name silindi';
  }

  @override
  String get nutrientCalories => 'Kalori';

  @override
  String get nutrientFiber => 'Lif';

  @override
  String get nutrientSugar => 'Şeker';

  @override
  String get nutrientSaturatedFat => 'Doymuş yağ';

  @override
  String get nutrientSodium => 'Sodyum';

  @override
  String mgValue(String value) {
    return '$value mg';
  }

  @override
  String get unitGram => 'g';

  @override
  String get unitMilliliter => 'ml';

  @override
  String unitPiece(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'adet',
    );
    return '$_temp0';
  }

  @override
  String unitSlice(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dilim',
    );
    return '$_temp0';
  }

  @override
  String unitServing(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'porsiyon',
    );
    return '$_temp0';
  }

  @override
  String unitBowl(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kase',
    );
    return '$_temp0';
  }

  @override
  String unitGlass(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bardak',
    );
    return '$_temp0';
  }

  @override
  String unitTablespoon(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'yemek kaşığı',
    );
    return '$_temp0';
  }

  @override
  String unitTeaspoon(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tatlı kaşığı',
    );
    return '$_temp0';
  }

  @override
  String portionQuantity(String quantity, String unit) {
    return '$quantity $unit';
  }

  @override
  String portionWithBase(String portion, String base) {
    return '$portion ($base)';
  }

  @override
  String get customFoodTitle => 'Yiyecek oluştur';

  @override
  String get customFoodName => 'İsim';

  @override
  String get customFoodNameHint => 'Örn. Ev yapımı granola';

  @override
  String get customFoodBrand => 'Marka (isteğe bağlı)';

  @override
  String get customFoodBarcode => 'Barkod';

  @override
  String get customFoodPortion => 'Porsiyon';

  @override
  String get customFoodPortionAmount => 'Porsiyon miktarı';

  @override
  String get customFoodPortionUnit => 'Porsiyon türü';

  @override
  String get customFoodValuesTitle => '1 porsiyondaki besin değerleri';

  @override
  String get customFoodValuesHint =>
      'Değerleri ürün etiketinden veya güvenilir bir kaynaktan gir.';

  @override
  String get customFoodCalories => 'Kalori (kcal)';

  @override
  String get customFoodProtein => 'Protein (g)';

  @override
  String get customFoodCarbs => 'Karbonhidrat (g)';

  @override
  String get customFoodFat => 'Yağ (g)';

  @override
  String get customFoodFiber => 'Lif (g, isteğe bağlı)';

  @override
  String get customFoodSugar => 'Şeker (g, isteğe bağlı)';

  @override
  String get customFoodSodium => 'Sodyum (mg, isteğe bağlı)';

  @override
  String customFoodSaved(String name) {
    return '$name kaydedildi';
  }

  @override
  String customFoodEnergyMismatch(String kcal) {
    return 'Makrolardan hesaplanan enerji yaklaşık $kcal kcal; girdiğin kaloriyle uyuşmuyor. Değerleri kontrol et.';
  }

  @override
  String get errorPositiveNumber => '0\'dan büyük bir değer gir.';

  @override
  String get errorNonNegativeNumber => 'Geçerli bir değer gir.';

  @override
  String get recipeBuilderTitle => 'Tarif oluştur';

  @override
  String get recipeName => 'Tarif adı';

  @override
  String get recipeNameHint => 'Örn. Menemen';

  @override
  String get recipeServings => 'Porsiyon sayısı';

  @override
  String get recipeAddIngredient => 'Malzeme ekle';

  @override
  String get recipeNoIngredients =>
      'Henüz malzeme eklenmedi. Tarifin besin değerleri malzemelerden otomatik hesaplanır.';

  @override
  String get recipeTotal => 'Tarifin tamamı';

  @override
  String get recipePerServing => '1 porsiyon';

  @override
  String recipeTotalWeight(String value) {
    return 'Toplam ağırlık: $value g';
  }

  @override
  String get recipeWeightNote =>
      'Değerler malzemelerin pişirilmeden önceki miktarlarına göre hesaplanır.';

  @override
  String get recipeNeedsIngredient => 'En az bir malzeme ekle.';

  @override
  String recipeSaved(String name) {
    return '$name tarifi kaydedildi';
  }

  @override
  String get foodPickerTitle => 'Malzeme seç';

  @override
  String get barcodeManualTitle => 'Barkod numarasıyla ara';

  @override
  String get barcodeManualHint => 'Barkod numarası';

  @override
  String get barcodeCameraUnavailable =>
      'Kamerayla tarama bu cihazda kullanılamıyor. Ürünün barkod numarasını elle girebilirsin.';

  @override
  String get barcodeSearch => 'Ürünü bul';

  @override
  String get barcodeNotFound =>
      'Open Food Facts kataloğunda bu barkoda ait ürün bulunamadı.';

  @override
  String barcodeIncompleteCatalog(String barcode) {
    return 'Barkod $barcode Open Food Facts kataloğunda kayıtlı ancak ürün adı veya besin değerleri eksik. Özel yiyecek olarak ekleyebilirsin.';
  }

  @override
  String barcodeDemoHint(String codes) {
    return 'Örnek veri barkodları: $codes';
  }

  @override
  String get barcodeAlignHint => 'Barkodu çerçevenin içine hizalayın';

  @override
  String get barcodeEnterManually => 'Barkodu elle gir';

  @override
  String get barcodeScanAgain => 'Tekrar tara';

  @override
  String get barcodeSearching => 'Ürün aranıyor';

  @override
  String get barcodeCameraPermissionTitle => 'Kamera izni gerekli';

  @override
  String get barcodeCameraPermissionMessage =>
      'Barkod taramak için kamera iznine ihtiyaç var. İzni ayarlardan açabilir veya barkodu elle girebilirsin.';

  @override
  String get barcodeOpenSettings => 'Ayarları aç';

  @override
  String get barcodeScanAreaLabel => 'Barkod tarama alanı';

  @override
  String get errorPermission =>
      'Bu işlem için izin vermen gerekiyor. İzni cihaz ayarlarından açabilirsin.';

  @override
  String progressRange(String range) {
    String _temp0 = intl.Intl.selectLogic(range, {
      'week': '7 gün',
      'month': '30 gün',
      'quarter': '90 gün',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get progressAddWeight => 'Kilo ekle';

  @override
  String get progressAddMeasurement => 'Ölçü ekle';

  @override
  String get progressAddPhoto => 'Fotoğraf ekle';

  @override
  String progressKg(String value) {
    return '$value kg';
  }

  @override
  String progressCm(String value) {
    return '$value cm';
  }

  @override
  String progressPercent(String value) {
    return '%$value';
  }

  @override
  String get progressGoalTitle => 'Kilo hedefi';

  @override
  String get progressStartWeight => 'Başlangıç';

  @override
  String get progressCurrentWeight => 'Güncel';

  @override
  String get progressTargetWeight => 'Hedef';

  @override
  String get progressLostWeight => 'Verilen';

  @override
  String get progressGainedWeight => 'Alınan';

  @override
  String get progressRemainingWeight => 'Kalan';

  @override
  String progressGoalPercent(String percent) {
    return 'Hedefin %$percent\'i tamamlandı';
  }

  @override
  String get progressGoalReached => 'Hedef kilona ulaştın, tebrikler!';

  @override
  String get progressNoTarget =>
      'Hedef kilo belirlenmedi. Profilinden ekleyebilirsin.';

  @override
  String get progressNoWeightTitle => 'Henüz kilo kaydı yok';

  @override
  String get progressNoWeightMessage =>
      'İlk kilonu ekleyerek ilerlemeni takip etmeye başla.';

  @override
  String get progressChartTitle => 'Kilo grafiği';

  @override
  String get progressChartNeedsMore =>
      'Grafik için bu dönemde en az iki kilo kaydı gerekiyor.';

  @override
  String progressChartTarget(String value) {
    return 'Hedef $value';
  }

  @override
  String progressChartSemantics(
    String from,
    String to,
    int count,
    String min,
    String max,
  ) {
    return 'Kilo grafiği: $from ile $to arasında $count kayıt, en düşük $min, en yüksek $max';
  }

  @override
  String get progressWeightHistory => 'Kilo kayıtları';

  @override
  String get progressEntryDeleted => 'Kayıt silindi';

  @override
  String get progressWeeklyTitle => 'Haftalık ortalama';

  @override
  String get progressWeeklyWeight => 'Ortalama kilo';

  @override
  String get progressWeeklyCalories => 'Ortalama kalori';

  @override
  String get progressWeeklyScore => 'Ortalama skor';

  @override
  String progressWeeklyVsLast(String change) {
    return 'Geçen haftaya göre $change kg';
  }

  @override
  String progressWeeklyKcal(String value) {
    return '$value kcal/gün';
  }

  @override
  String get progressNoValue => '—';

  @override
  String get progressWaistTitle => 'Bel ölçüsü';

  @override
  String get progressMeasurementsTitle => 'Vücut ölçüleri';

  @override
  String get progressNoMeasurements =>
      'Henüz ölçü kaydı yok. Bel, kalça ve diğer ölçülerini ekleyerek tartıda görünmeyen değişimi de takip et.';

  @override
  String progressLastMeasured(String date) {
    return 'Son ölçüm: $date';
  }

  @override
  String progressSinceStart(String change) {
    return 'Başlangıçtan beri $change';
  }

  @override
  String get measureWaist => 'Bel';

  @override
  String get measureHip => 'Kalça';

  @override
  String get measureChest => 'Göğüs';

  @override
  String get measureNeck => 'Boyun';

  @override
  String get measureArm => 'Kol';

  @override
  String get measureThigh => 'Bacak';

  @override
  String get measureBodyFat => 'Yağ oranı';

  @override
  String get progressPhotosTitle => 'İlerleme fotoğrafları';

  @override
  String get progressPhotosEmpty =>
      'Aynı ışıkta ve aynı pozda düzenli fotoğraf çekmek, değişimi görmenin en iyi yollarından biri.';

  @override
  String get progressPhotoCamera => 'Fotoğraf çek';

  @override
  String get progressPhotoGallery => 'Galeriden seç';

  @override
  String get progressPhotoFirst => 'İlk';

  @override
  String get progressPhotoLatest => 'Son';

  @override
  String get progressPhotoAdded => 'Fotoğraf eklendi';

  @override
  String get progressPhotoDelete => 'Fotoğrafı sil';

  @override
  String get progressPhotoDeleteConfirm =>
      'Bu fotoğraf kalıcı olarak silinsin mi?';

  @override
  String get progressPhotoDeleted => 'Fotoğraf silindi';

  @override
  String get progressPhotoUnavailable => 'Fotoğraf yüklenemedi';

  @override
  String get actionDelete => 'Sil';

  @override
  String get progressAdherenceTitle => 'Hedef uyumu';

  @override
  String get progressAdherenceCalories => 'Kalori uyumu';

  @override
  String get progressAdherenceProtein => 'Protein uyumu';

  @override
  String get progressAdherenceWater => 'Su uyumu';

  @override
  String progressAdherenceDays(int hit, int total) {
    return '$hit / $total gün';
  }

  @override
  String get progressAdherenceNoData => 'Bu dönemde kayıt yok';

  @override
  String get progressAdherenceNote =>
      'Kayıt girilen tamamlanmış günler üzerinden hesaplanır; bugün dahil değildir. Kalori: hedefin ±%10\'u, protein: hedefin en az %90\'ı, su: günlük su hedefi.';

  @override
  String get progressScoreTitle => 'Günlük skor geçmişi';

  @override
  String progressScoreAverage(String value) {
    return 'Ortalama $value';
  }

  @override
  String get progressScoreEmpty => 'Bu dönemde skor hesaplanacak kayıt yok.';

  @override
  String get progressToday => 'Bugün';

  @override
  String get progressNotLogged => 'Kayıt yok';

  @override
  String progressDaySummary(String kcal, String protein, String water) {
    return '$kcal kcal · $protein g protein · $water L su';
  }

  @override
  String get progressWeightSheetTitle => 'Kilo ekle';

  @override
  String get progressWeightField => 'Kilo';

  @override
  String get progressDateField => 'Tarih';

  @override
  String progressWeightSaved(String value) {
    return '$value kg kaydedildi';
  }

  @override
  String get progressMeasurementSheetTitle => 'Ölçü ekle';

  @override
  String get progressMeasurementHint =>
      'Ölçmek istediğin alanları doldur; boş bırakılanlar kaydedilmez. Mezuranı her seferinde aynı noktadan geçir.';

  @override
  String get progressMeasurementNeedsValue => 'En az bir ölçü gir.';

  @override
  String get progressMeasurementSaved => 'Ölçüler kaydedildi';

  @override
  String get errorPurchase =>
      'Satın alma tamamlanamadı. Ücret alınmadı; lütfen tekrar dene.';

  @override
  String get errorPurchaseUnavailable => 'Satın alma şu anda kullanılamıyor.';

  @override
  String get errorPremiumRequired => 'Bu özellik Premium üyelere özel.';

  @override
  String get appFeatureCalorieTracking => 'Kalori takibi';

  @override
  String get appFeatureWeightTracking => 'Kilo takibi';

  @override
  String get appFeatureWaterTracking => 'Su takibi';

  @override
  String get appFeatureFoodLogging => 'Yemek ekleme';

  @override
  String get appFeatureBasicProgress => 'Temel ilerleme';

  @override
  String get appFeaturePersonalMealPlan => 'Kişiye Özel Haftalık Menü';

  @override
  String get appFeaturePersonalMealPlanDesc =>
      'Kalori hedefin, öğün sayın, tercihlerin ve alerjilerinle hazırlanan 7 günlük menü.';

  @override
  String get appFeatureAiCoach => 'Beslenme Asistanı';

  @override
  String get appFeatureAiCoachDesc =>
      'Günlük kayıtlarına göre değerlendirme ve uygulanabilir beslenme önerileri.';

  @override
  String get appFeaturePhotoFoodAnalysis => 'Fotoğraftan yemek analizi';

  @override
  String get appFeaturePhotoFoodAnalysisDesc =>
      'Tabağının fotoğrafını çek, kalorisi hesaplansın.';

  @override
  String get appFeatureAdvancedAnalytics => 'Gelişmiş analizler';

  @override
  String get appFeatureAdvancedAnalyticsDesc =>
      'Kalori, protein ve su hedeflerine uyumunu gör.';

  @override
  String get appFeatureAdvancedRecipes => 'Gelişmiş tarifler';

  @override
  String get appFeatureAdvancedRecipesDesc =>
      'Hedefine uygun özel tarif koleksiyonu.';

  @override
  String get appFeatureAutoShoppingList => 'Otomatik alışveriş listesi';

  @override
  String get appFeatureAutoShoppingListDesc =>
      'Planındaki malzemeler tek listede toplanır.';

  @override
  String get appFeatureAdvancedGoals => 'Gelişmiş hedefler';

  @override
  String get appFeatureAdvancedGoalsDesc =>
      'Makro ve öğün hedeflerini kişiselleştir.';

  @override
  String get appFeatureAdvancedReports => 'Gelişmiş raporlar';

  @override
  String get appFeatureAdvancedReportsDesc =>
      'Beslenme skoru geçmişi ve detaylı raporlar.';

  @override
  String get appFeatureAdFree => 'Reklamsız Kullanım';

  @override
  String get appFeatureAdFreeDesc =>
      'Banner, geçiş ve ödüllü reklamlar gösterilmez.';

  @override
  String get appFeatureFasting => 'Aralıklı oruç';

  @override
  String get appFeatureFastingDesc => '16:8 gibi oruç planları ve zamanlayıcı.';

  @override
  String get appFeaturePeriodicReports => 'Haftalık ve aylık raporlar';

  @override
  String get appFeaturePeriodicReportsDesc =>
      'Haftalık ortalamalar ve dönem karşılaştırmaları.';

  @override
  String premiumLockedTitle(String feature) {
    return '$feature Premium\'a özel';
  }

  @override
  String get premiumUnlockAction => 'Premium\'a geç';

  @override
  String get premiumProfileSubtitle =>
      'Asistan, haftalık menü ve reklamsız kullanım';

  @override
  String get paywallTitle => 'Hedefine Premium ile daha hızlı ulaş';

  @override
  String get paywallSubtitle =>
      'Beslenme asistanı, kişiye özel haftalık menü ve reklamsız kullanım.';

  @override
  String get paywallPeriodWeekly => 'Haftalık';

  @override
  String get paywallPeriodMonthly => 'Aylık';

  @override
  String get paywallPeriodAnnual => 'Yıllık';

  @override
  String get paywallPeriodLifetime => 'Ömür boyu';

  @override
  String paywallSavings(int percent) {
    return '%$percent tasarruf';
  }

  @override
  String paywallPerMonth(String price) {
    return 'Aylık $price';
  }

  @override
  String get paywallSubscribe => 'Abone ol';

  @override
  String paywallStartTrial(int days) {
    return '$days gün ücretsiz dene';
  }

  @override
  String get paywallRestore => 'Satın alımları geri yükle';

  @override
  String get paywallLegal =>
      'Abonelik, dönem bitmeden en az 24 saat önce iptal edilmezse otomatik olarak yenilenir. Mağaza hesap ayarlarından istediğin zaman iptal edebilirsin.';

  @override
  String paywallTrialLegal(int days, String price) {
    return '$days günlük ücretsiz deneme bitiminde $price ücretlendirilir. Deneme bitmeden en az 24 saat önce iptal edersen ücret alınmaz.';
  }

  @override
  String get paywallPurchaseSuccess => 'Premium\'a hoş geldin!';

  @override
  String get paywallRestored => 'Premium üyeliğin geri yüklendi.';

  @override
  String get paywallNothingToRestore =>
      'Geri yüklenecek bir satın alma bulunamadı.';

  @override
  String get paywallActiveTitle => 'Premium aktif';

  @override
  String paywallTrialUntil(String date) {
    return 'Ücretsiz deneme $date tarihine kadar';
  }

  @override
  String paywallRenewsOn(String date) {
    return '$date tarihinde yenilenir';
  }

  @override
  String paywallActiveUntil(String date) {
    return '$date tarihine kadar geçerli';
  }

  @override
  String get settingsSubscription => 'Abonelik';

  @override
  String get settingsResetFakeSubscription => 'Test aboneliğini sıfırla';

  @override
  String get testPremiumSectionTitle => 'Geliştirme testi';

  @override
  String get testPremiumSectionMessage =>
      'Bu düğme mağaza ödemesi yapmaz. Premium özellikleri yalnızca bu cihazda, geliştirme ve test amacıyla açar.';

  @override
  String get testPremiumStart => 'Test Premium Üyeliğini Başlat';

  @override
  String get testPremiumConfirmTitle => 'Test üyeliği başlatılsın mı?';

  @override
  String get testPremiumConfirmMessage =>
      'Bu işlem gerçek bir ödeme değildir. Premium üyelik yalnızca geliştirme ve test amacıyla etkinleştirilir. Uygulama kapatılıp açıldığında bu test durumu korunur.';

  @override
  String get testPremiumConfirmAction => 'Test üyeliğini başlat';

  @override
  String get testPremiumStarted =>
      'Test üyeliği etkinleştirildi. Gerçek bir ödeme yapılmadı.';

  @override
  String get testPremiumActiveTitle => 'Premium Üyeliğin Aktif';

  @override
  String get testPremiumActiveMessage =>
      'Bu üyelik yalnızca geliştirme ve test içindir. Gerçek bir satın alma veya mağaza aboneliği değildir.';

  @override
  String get testPremiumReset => 'Test Üyeliğini Sıfırla';

  @override
  String get testPremiumResetDone => 'Test üyeliği sıfırlandı.';

  @override
  String get settingsLegal => 'Yasal';

  @override
  String get settingsPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get settingsPrivacyPolicyUnavailable =>
      'Gizlilik Politikası şu anda açılamıyor.';

  @override
  String get scoreFactorMacroBalance => 'Makro dengesi';

  @override
  String get scoreTipMacroBalance =>
      'Protein, karbonhidrat ve yağı hedeflerine yakın oranda dağıtmaya çalış.';

  @override
  String get diaryToday => 'Bugün';

  @override
  String get diaryYesterday => 'Dün';

  @override
  String get diaryTomorrow => 'Yarın';

  @override
  String get diaryPreviousDay => 'Önceki gün';

  @override
  String get diaryNextDay => 'Sonraki gün';

  @override
  String get diaryPickDate => 'Tarih seç';

  @override
  String diaryCaloriesLeft(String kcal) {
    return '$kcal kcal kaldı';
  }

  @override
  String diaryCaloriesOver(String kcal) {
    return 'Hedefin $kcal kcal üzerindesin';
  }

  @override
  String diaryCaloriesOfTarget(String target) {
    return '/ $target kcal';
  }

  @override
  String diaryMealEmptyHint(String meal) {
    String _temp0 = intl.Intl.selectLogic(meal, {
      'breakfast': 'Kahvaltını planlamaya başlayalım 🌱',
      'lunch': 'Öğle yemeğini eklemeye ne dersin?',
      'dinner': 'Akşam yemeğin henüz boş.',
      'snack': 'Gün içindeki atıştırmalıklarını buraya ekleyebilirsin.',
      'other': 'Henüz bir yiyecek eklenmedi.',
    });
    return '$_temp0';
  }

  @override
  String get diaryShowAllMeals => 'Tüm öğünler';

  @override
  String get diaryExpand => 'Genişlet';

  @override
  String get diaryCollapse => 'Daralt';

  @override
  String get diaryEntryMenu => 'Yiyecek seçenekleri';

  @override
  String get diaryEntryEdit => 'Düzenle';

  @override
  String get diaryEntryCopy => 'Kopyala';

  @override
  String get diaryEntryMove => 'Başka öğüne taşı';

  @override
  String get diaryEditTitle => 'Kaydı düzenle';

  @override
  String get diaryEditAmount => 'Miktar';

  @override
  String get diaryEditDecrease => 'Azalt';

  @override
  String get diaryEditIncrease => 'Artır';

  @override
  String diaryEntryUpdated(String food) {
    return '$food güncellendi';
  }

  @override
  String diaryEntryCopied(String food, String date) {
    return '$food, $date tarihine kopyalandı';
  }

  @override
  String diaryEntryMoved(String food, String meal) {
    return '$food, $meal öğününe taşındı';
  }

  @override
  String diaryFavoriteAdded(String food) {
    return '$food favorilere eklendi';
  }

  @override
  String diaryFavoriteRemoved(String food) {
    return '$food favorilerden çıkarıldı';
  }

  @override
  String diaryEntryDeleted(String food) {
    return '$food silindi';
  }

  @override
  String get diaryDeleteTitle => 'Yiyeceği sil';

  @override
  String get diaryDeleteMessage =>
      'Bu yiyeceği günlük kaydından silmek istediğine emin misin?';

  @override
  String get diaryMoveTitle => 'Hangi öğüne taşınsın?';

  @override
  String get diaryCopyTitle => 'Nereye kopyalansın?';

  @override
  String get diaryCopyToday => 'Bugüne kopyala';

  @override
  String get diaryCopyTomorrow => 'Yarına kopyala';

  @override
  String get diaryWaterTitle => 'Su';

  @override
  String diaryWaterOfGoal(String value, String goal) {
    return '$value / $goal ml';
  }

  @override
  String diaryWaterRemove(int ml) {
    return '$ml ml azalt';
  }

  @override
  String diaryMlValue(int ml) {
    return '$ml ml';
  }

  @override
  String diaryWaterRemoved(int ml) {
    return '$ml ml su çıkarıldı';
  }

  @override
  String diaryScoreTitle(String when) {
    String _temp0 = intl.Intl.selectLogic(when, {
      'past': 'Günün Beslenme Skoru',
      'future': 'Planlanan Beslenme Skoru',
      'other': 'Bugünün Beslenme Skoru',
    });
    return '$_temp0';
  }

  @override
  String get diaryScoreDisclaimer =>
      'Bu skor genel beslenme alışkanlıklarını takip etmeye yardımcı olan tahmini bir göstergedir.';

  @override
  String diaryScoreStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'met': 'hedefte',
      'partial': 'geliştirilebilir',
      'other': 'eksik',
    });
    return '$_temp0';
  }

  @override
  String get diaryQuickAddTitle => 'Ne eklemek istiyorsun?';

  @override
  String get diaryAddWater => 'Su ekle';

  @override
  String get diaryAddWeight => 'Kilo ekle';

  @override
  String get diaryAddActivity => 'Aktivite ekle';

  @override
  String diaryEmptyDayTitle(String when) {
    String _temp0 = intl.Intl.selectLogic(when, {
      'past': 'Bu gün için kayıt yok.',
      'future': 'Bu günü şimdiden planlayabilirsin.',
      'other': 'Bugün henüz bir öğün eklemedin.',
    });
    return '$_temp0';
  }

  @override
  String get diaryEmptyDayMessage =>
      'Öğünlerini ekledikçe kalori, makro ve beslenme skorun burada güncellenir.';

  @override
  String get diaryPastDayNote =>
      'Geçmiş bir günü görüntülüyorsun; yaptığın değişiklikler bu güne kaydedilir.';

  @override
  String get diaryFutureDayNote =>
      'İleri bir tarih seçili; eklediğin öğünler plan olarak bu güne kaydedilir.';

  @override
  String get diaryActivityTitleToday => 'Bugünkü aktivite';

  @override
  String get diaryWeightTitle => 'Kilo';

  @override
  String get diaryWeightEmpty => 'Bu gün için kilo kaydı yok.';

  @override
  String diaryWeightValue(String value) {
    return '$value kg';
  }

  @override
  String get activityConnectTitle => 'Sağlık verilerini bağla';

  @override
  String get activityConnectMessage =>
      'Apple Health veya Health Connect bağlandığında adım, mesafe ve aktif kalori bu cihazın günlüğünde tutulur ve Firebase\'e yazılmaz. Asistana aktivite veya gün özeti sorarsan bu özet soruyla birlikte gönderilir.';

  @override
  String get activityConnectAction => 'Bağlan';

  @override
  String get activityConnectGranted => 'Sağlık verileri bağlandı.';

  @override
  String get activityConnectUnavailable =>
      'Sağlık verisi bağlantısı bu cihazda henüz kullanılamıyor.';

  @override
  String get healthDataTitle => 'Sağlık Verileri';

  @override
  String get healthConnectName => 'Health Connect';

  @override
  String get healthAppleName => 'Apple Health';

  @override
  String get healthStatusLinked => 'Bağlı';

  @override
  String get healthStatusNotLinked => 'Bağlı değil';

  @override
  String get healthUnavailableBody => 'Bu özellik bu cihazda kullanılamıyor.';

  @override
  String get healthPermissionDenied =>
      'Sağlık verileri bağlı değil. Ayarlardan tekrar deneyebilirsin.';

  @override
  String get healthPrivacyNote =>
      'Adım, mesafe ve aktif kalori bu cihazda tutulur ve Firebase\'e yazılmaz. Asistana aktivite veya gün özeti sorarsan bu özet soruyla birlikte gönderilir.';

  @override
  String get healthConnectAction => 'Sağlık verilerini bağla';

  @override
  String get healthValueUnavailable => '—';

  @override
  String get activityDistance => 'Mesafe';

  @override
  String activityDistanceKm(String value) {
    return '$value km';
  }

  @override
  String activityDistanceMeters(String value) {
    return '$value m';
  }

  @override
  String get progressActivityTitle => 'Hareket';

  @override
  String get progressActivityToday => 'Bugünkü adım';

  @override
  String get progressActivityWeek => 'Son 7 gün adım';

  @override
  String get weightNoteField => 'Not (isteğe bağlı)';

  @override
  String get weightNoteHint => 'ör. Sabah, aç karnına';

  @override
  String get weightAdd => 'Kilo Ekle';

  @override
  String get weightAddFirst => 'İlk kilomu ekle';

  @override
  String get weightEmptyTitle => 'Henüz kilo kaydı eklemedin.';

  @override
  String get weightEmptyMessage =>
      'Kilonu düzenli girdikçe ilerlemen, grafiğin ve hedefe kalan kilo burada görünür.';

  @override
  String get weightJourneyTitle => 'Kilo yolculuğun';

  @override
  String get weightStatRemaining => 'Hedefe kalan';

  @override
  String get weightStatPercent => 'Başlangıçtan değişim';

  @override
  String get weightStatLast => 'Son ölçüm';

  @override
  String get weightStatWeekly => 'Haftalık ortalama';

  @override
  String weightPerWeek(String value) {
    return '$value kg/hafta';
  }

  @override
  String weightRange(String range) {
    String _temp0 = intl.Intl.selectLogic(range, {
      'week': '7 gün',
      'month': '30 gün',
      'quarter': '3 ay',
      'other': 'Tümü',
    });
    return '$_temp0';
  }

  @override
  String get weightHistoryTitle => 'Kayıt geçmişi';

  @override
  String get weightHistoryEmpty => 'Girdiğin kilo kayıtları burada listelenir.';

  @override
  String weightDeltaPrevious(String change) {
    return 'öncekine göre $change kg';
  }

  @override
  String get targetSuggestionTitle => 'Hedeflerini güncelleyebilirsin';

  @override
  String targetSuggestionBody(String current, String suggested) {
    return 'Güncel bilgilerine göre günlük kalori hedefin $current yerine $suggested kcal olarak öneriliyor.';
  }

  @override
  String targetSuggestionBodyNew(String suggested) {
    return 'Profiline göre günlük hedefin $suggested kcal olarak hesaplandı.';
  }

  @override
  String get targetSuggestionLimited =>
      'Değişiklik kademeli uygulanır: tek seferde en fazla 200 kcal.';

  @override
  String get targetSuggestionNote =>
      'Bu öneri genel bir hesaplamadır; sağlık durumun varsa bir uzmana danış.';

  @override
  String get targetSuggestionLater => 'Şimdi değil';

  @override
  String get targetSuggestionApply => 'Hedefi güncelle';

  @override
  String get targetSuggestionApplied =>
      'Günlük hedefin güncellendi. Planını yeni hedefe göre yenileyebilirsin.';

  @override
  String get measureEmptyTitle => 'Henüz vücut ölçümü eklemedin.';

  @override
  String get measureEmptyMessage =>
      'Bel, kalça, göğüs, boyun, kol ve uyluk ölçülerini ekleyerek kilodan bağımsız değişimi de takip edebilirsin.';

  @override
  String get measureAddFirst => 'İlk ölçümümü ekle';

  @override
  String get measureSeeProgress => 'Kilo ve ölçüleri İlerleme\'de birlikte gör';

  @override
  String get measureSummaryTitle => 'Ölçü özeti';

  @override
  String get measureStart => 'Başlangıç';

  @override
  String get measureLatest => 'Son';

  @override
  String get measureChange => 'Değişim';

  @override
  String get measureChartTitle => 'Ölçü grafiği';

  @override
  String measureChartSemantics(String field, String min, String max) {
    return '$field grafiği; en düşük $min, en yüksek $max.';
  }

  @override
  String get measureHistoryTitle => 'Ölçüm geçmişi';

  @override
  String get nutritionPlanTitle => 'Beslenme Planım';

  @override
  String nutritionPlanGoal(String goal) {
    return 'Hedef: $goal';
  }

  @override
  String get nutritionPlanDailyTarget => 'Günlük kalori hedefi';

  @override
  String get nutritionPlanEditGoals => 'Hedefleri düzenle';

  @override
  String get nutritionPlanPreviousWeek => 'Önceki hafta';

  @override
  String get nutritionPlanNextWeek => 'Sonraki hafta';

  @override
  String nutritionPlanWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String nutritionPlanEatingWindow(String start, String end) {
    return 'Yeme pencereni $start–$end; öğün saatleri buna göre ayarlandı.';
  }

  @override
  String get nutritionPlanToday => 'Bugünün öğünleri';

  @override
  String get nutritionPlanCreate => 'Yeni Plan Oluştur';

  @override
  String get nutritionPlanCreated => 'Yeni planın hazır.';

  @override
  String get nutritionPlanFromProfile =>
      'Kalori ve makro hedeflerin profilinden alınır.';

  @override
  String get nutritionPlanMealsPerDay => 'Günlük öğün sayısı';

  @override
  String get nutritionPlanDietType => 'Beslenme tipi';

  @override
  String get nutritionPlanDisliked => 'Sevmediğin yiyecekler';

  @override
  String get nutritionPlanDislikedHint => 'ör. Brokoli';

  @override
  String get nutritionPlanGenerate => 'Planı oluştur';

  @override
  String get nutritionPlanLogToday => 'Bugünkü günlüğe ekle';

  @override
  String get nutritionPlanSwap => 'Bu yemeği değiştir';

  @override
  String get nutritionPlanOpenRecipe => 'Tarifi gör';

  @override
  String get nutritionPlanAlreadyLogged =>
      'Bu öğün bugünkü günlüğünde zaten var.';

  @override
  String nutritionPlanAlternativesTitle(String meal) {
    return '$meal için alternatifler';
  }

  @override
  String get nutritionPlanAlternativesSubtitle =>
      'Kalori hedefine, beslenme tipine, alerjilerine ve sevmediklerine uygun öneriler.';

  @override
  String servingsCount(String value) {
    return '$value porsiyon';
  }

  @override
  String get recipeCategoryAll => 'Tümü';

  @override
  String get recipeCategoryBreakfast => 'Kahvaltı';

  @override
  String get recipeCategoryLunch => 'Öğle';

  @override
  String get recipeCategoryDinner => 'Akşam';

  @override
  String get recipeCategorySnack => 'Atıştırmalık';

  @override
  String get recipeCategoryDessert => 'Tatlı';

  @override
  String get recipeCategoryDrink => 'İçecek';

  @override
  String get recipeCategoryHighProtein => 'Yüksek Protein';

  @override
  String get recipeCategoryLowCalorie => 'Düşük Kalori';

  @override
  String get recipeFavorites => 'Favoriler';

  @override
  String get recipeFavorite => 'Favori';

  @override
  String get recipeAddFavorite => 'Favorilere ekle';

  @override
  String get recipeRemoveFavorite => 'Favorilerden çıkar';

  @override
  String get recipeFavoritesEmptyTitle => 'Henüz favori tarifin yok.';

  @override
  String get recipeFavoritesEmptyMessage =>
      'Beğendiğin tariflerde kalp simgesine dokunarak burada topla.';

  @override
  String get recipeSearchHint => 'Tarif veya malzeme ara';

  @override
  String get recipeNoResults => 'Aramana uygun tarif bulunamadı.';

  @override
  String get recipeClearFilters => 'Filtreleri temizle';

  @override
  String get recipeDemoNutrition =>
      'Besin değerleri örnek USDA verisinden hesaplandı. Demo veridir.';

  @override
  String get recipeVegetarian => 'Vejetaryen';

  @override
  String get recipeSalad => 'Salata';

  @override
  String get recipeSoup => 'Çorba';

  @override
  String get recipePractical => 'Pratik';

  @override
  String get recipeRecentTitle => 'Son görüntülenenler';

  @override
  String get recipeRecommendedTitle => 'Sana uygun';

  @override
  String get recipeCalorieAny => 'Kalori';

  @override
  String recipeCalorieMax(int kcal) {
    return '≤ $kcal kcal';
  }

  @override
  String get recipeSelectedServings => 'Seçilen porsiyon';

  @override
  String get recipeLoadMore => 'Daha fazla göster';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String get recipeCreate => 'Tarif oluştur';

  @override
  String get recipeLogToday => 'Bugünkü Günlüğe Ekle';

  @override
  String get recipeAddToPlan => 'Beslenme Planına Ekle';

  @override
  String get recipePickDay => 'Gün';

  @override
  String get recipePickMeal => 'Öğün';

  @override
  String get recipeServingsLabel => 'Porsiyon';

  @override
  String get recipeLessServings => 'Porsiyonu azalt';

  @override
  String get recipeMoreServings => 'Porsiyonu artır';

  @override
  String recipeLogged(String name, String meal) {
    return '$name $meal öğününe eklendi';
  }

  @override
  String recipeAddedToPlan(String day, String meal) {
    return 'Plana eklendi: $day, $meal';
  }

  @override
  String get recipeOpenPlan => 'Planı aç';

  @override
  String get recipeDeleteTitle => 'Tarif silinsin mi?';

  @override
  String recipeDeleteMessage(String name) {
    return '$name tarifin kalıcı olarak silinecek.';
  }

  @override
  String get recipeDeleted => 'Tarif silindi.';

  @override
  String get recipeNotFound => 'Tarif bulunamadı.';

  @override
  String get recipeMine => 'Benim tarifim';

  @override
  String recipePortionGrams(String grams) {
    return 'Bir porsiyon yaklaşık $grams';
  }

  @override
  String get recipeAllergens => 'Alerjenler';

  @override
  String get recipeNoDeclaredAllergens =>
      'Listelenen malzemelerde belirgin alerjen görünmüyor.';

  @override
  String get recipeNutritionPerServing => 'Porsiyon başı besin değerleri';

  @override
  String get recipeIngredients => 'Malzemeler';

  @override
  String get recipeNoIngredientList => 'Malzeme listesi eklenmemiş.';

  @override
  String get recipeSteps => 'Hazırlanışı';

  @override
  String get recipeNoSteps => 'Hazırlanış adımı eklenmemiş.';

  @override
  String get recipeDescription => 'Kısa açıklama (isteğe bağlı)';

  @override
  String get recipeCategories => 'Kategori';

  @override
  String get recipeComputedCategoriesNote =>
      '\"Yüksek Protein\" ve \"Düşük Kalori\" besin değerlerine göre otomatik belirlenir.';

  @override
  String get recipeNeedsCategory => 'En az bir kategori seç.';

  @override
  String get recipePrepMinutes => 'Hazırlık';

  @override
  String get recipeCookMinutes => 'Pişirme';

  @override
  String get unitMinutes => 'dk';

  @override
  String get recipeIngredientsHint =>
      'Her satıra bir malzeme, ör.\n2 adet yumurta\n150 g lor peyniri';

  @override
  String get recipeStepsHint =>
      'Her satıra bir adım, ör.\nYumurtaları çırpın.\nTavada pişirin.';

  @override
  String get fastingEmptyTitle => 'Bugün henüz bir oruç planlamadın.';

  @override
  String get fastingEmptyMessage =>
      'Yukarıdan bir protokol seçerek başlayabilirsin. Yeme pencerene göre öğün saatlerin ve hatırlatmaların da ayarlanır.';

  @override
  String get fastingProtocolTitle => 'Protokol';

  @override
  String get fastingProtocolLocked =>
      'Devam eden orucu bitirince protokolü değiştirebilirsin.';

  @override
  String get fastingPhaseFasting => 'Oruç';

  @override
  String get fastingPhaseEating => 'Yeme penceresi';

  @override
  String get fastingChangeWindow => 'Yeme penceresi saatini değiştir';

  @override
  String get fastingEatingStartPicker => 'Yeme penceresi başlangıcı';

  @override
  String fastingRemaining(String time) {
    return 'Hedefe $time kaldı';
  }

  @override
  String fastingEatingRemaining(String time) {
    return 'Yeme pencerenin kapanmasına $time kaldı';
  }

  @override
  String get fastingTargetReached =>
      'Hedef süreye ulaştın. Hazır olduğunda orucu bitirebilirsin.';

  @override
  String fastingEndsAt(String time) {
    return 'Hedef bitiş: $time';
  }

  @override
  String fastingEatingEndsAt(String time) {
    return 'Pencere kapanışı: $time';
  }

  @override
  String fastingTimerSemantics(String phase, String time) {
    return '$phase: $time';
  }

  @override
  String get fastingPaused => 'Duraklatıldı';

  @override
  String get fastingStart => 'Orucu Başlat';

  @override
  String get fastingPause => 'Duraklat';

  @override
  String get fastingResume => 'Devam et';

  @override
  String get fastingFinish => 'Bitir';

  @override
  String get fastingStarted => 'Oruç başladı. Bol su içmeyi unutma.';

  @override
  String fastingFinishedCompleted(String duration) {
    return 'Tebrikler! $duration oruç tamamlandı.';
  }

  @override
  String fastingFinishedEarly(String duration) {
    return 'Oruç $duration sonra bitirildi. Kendini iyi hissetmek her zaman önceliklidir.';
  }

  @override
  String fastingHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get fastingWindowMealsTitle => 'Yeme penceresindeki öğünlerin';

  @override
  String get fastingHistoryTitle => 'Oruç geçmişi';

  @override
  String get fastingHistoryEmpty => 'Bitirdiğin oruçlar burada listelenir.';

  @override
  String get fastingStatCompleted => 'Tamamlanan';

  @override
  String get fastingStatAverage => 'Ortalama süre';

  @override
  String get fastingLast7Days => 'Son 7 gün';

  @override
  String get fastingCompleted => 'Tamamlandı';

  @override
  String get fastingEndedEarly => 'Erken bitirildi';

  @override
  String get fastingSessionDeleted => 'Oruç kaydı silindi.';

  @override
  String get fastingDisclaimer =>
      'Aralıklı oruç tıbbi bir tavsiye değildir. Hamilelik, emzirme, diyabet, yeme bozukluğu geçmişi, düzenli ilaç kullanımı veya kronik bir rahatsızlık varsa başlamadan önce doktoruna danış. Baş dönmesi veya halsizlik hissedersen orucu bitir.';

  @override
  String get notificationsMaster => 'Bildirimler';

  @override
  String get notificationsMasterOff =>
      'Açtığında hatırlatmalar seçtiğin saatlerde gönderilir.';

  @override
  String notificationsScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hatırlatma planlandı',
      zero: 'Planlanmış hatırlatma yok',
    );
    return '$_temp0';
  }

  @override
  String get notificationsPermissionDenied =>
      'Bildirim izni verilmedi. Cihaz ayarlarından izin verebilirsin.';

  @override
  String get notificationsOpenSettings => 'Ayarları aç';

  @override
  String get notificationsFastingNeedsProtocol =>
      'Oruç hatırlatmaları için Aralıklı Oruç ekranından bir protokol seç.';

  @override
  String get reminderGroupMeal => 'Öğün';

  @override
  String get reminderGroupWater => 'Su';

  @override
  String get reminderGroupGoal => 'Hedef';

  @override
  String get reminderGroupFasting => 'Oruç';

  @override
  String get reminderGroupMotivation => 'Motivasyon';

  @override
  String get reminderGroupPlan => 'Plan';

  @override
  String get reminderBreakfast => 'Kahvaltı';

  @override
  String get reminderLunch => 'Öğle yemeği';

  @override
  String get reminderSnack => 'Atıştırmalık';

  @override
  String get reminderDinner => 'Akşam yemeği';

  @override
  String get reminderWater => 'Su içme';

  @override
  String get reminderDailyGoal => 'Günlük hedef özeti';

  @override
  String get reminderWeighIn => 'Kilo ölçümü';

  @override
  String get reminderFastingStart => 'Oruç başlangıcı';

  @override
  String get reminderEatingStart => 'Yeme penceresi başlangıcı';

  @override
  String get reminderEatingEnd => 'Yeme penceresi bitişi';

  @override
  String get reminderFastingEnd => 'Oruç bitişi';

  @override
  String get reminderMotivation => 'Günlük motivasyon';

  @override
  String get reminderPlan => 'Plan hatırlatmaları';

  @override
  String get reminderPlanHint =>
      'Haftalık plandaki öğünün adıyla, öğün saatinde gönderilir.';

  @override
  String get reminderWaterBalanced =>
      'Günlük su hedefine göre, uyanık saatlere yayılır.';

  @override
  String get reminderChangeTime => 'Saati değiştir';

  @override
  String reminderWaterEvery(String hours, String start, String end) {
    return 'Her $hours saatte bir, $start–$end';
  }

  @override
  String reminderEveryHours(String hours) {
    return '$hours saatte bir';
  }

  @override
  String reminderWeeklyMonday(String time) {
    return 'Her pazartesi $time';
  }

  @override
  String get reminderFastingEndHint => 'Devam eden orucun hedef süresi dolunca';

  @override
  String get reminderOutsideWindow =>
      'Yeme penceren dışında olduğu için gönderilmez';

  @override
  String get reminderBreakfastTitle => '🍳 Kahvaltı zamanı';

  @override
  String get reminderLunchTitle => '🍽️ Öğle yemeği zamanı';

  @override
  String get reminderSnackTitle => '🍎 Ara öğün zamanı';

  @override
  String get reminderDinnerTitle => '🌙 Akşam yemeği zamanı';

  @override
  String get reminderBreakfastBody => 'Güne güzel bir başlangıç yap.';

  @override
  String get reminderLunchBody => 'Bugünkü planındaki öğünü unutma.';

  @override
  String get reminderSnackBody => 'Ara öğününü atlamayı unutma.';

  @override
  String get reminderDinnerBody => 'Bugünkü planına göz at.';

  @override
  String get reminderMealBody => 'Bugünkü öğününü planına eklemeyi unutma.';

  @override
  String reminderPlanMealTitle(String meal, String recipe) {
    return '$meal: $recipe';
  }

  @override
  String get reminderWaterTitle => '💧 Su zamanı';

  @override
  String get reminderWaterBody => 'Günlük su hedefin için bir bardak su iç.';

  @override
  String get reminderDailyGoalTitle => 'Bugünü nasıl geçirdin?';

  @override
  String get reminderDailyGoalBody =>
      'Kalori ve protein hedeflerine ne kadar yaklaştığını gör.';

  @override
  String get reminderWeighInTitle => 'Haftalık kilo ölçümü';

  @override
  String get reminderWeighInBody => 'Sabah aç karnına tartılıp kilonu kaydet.';

  @override
  String get reminderFastingStartTitle => '⏱️ Oruç başladı';

  @override
  String get reminderFastingStartBody => 'Yeme penceren kapandı.';

  @override
  String get reminderEatingStartTitle => '🍽️ Yeme penceren başladı';

  @override
  String get reminderEatingStartBody =>
      'Planındaki öğünle yemeğine başlayabilirsin.';

  @override
  String get reminderEatingEndTitle => 'Yeme pencerin kapanıyor';

  @override
  String reminderEatingEndBody(int minutes) {
    return 'Pencerenin kapanmasına $minutes dakika kaldı.';
  }

  @override
  String get reminderFastingEndTitle => '🎉 Oruç süren tamamlandı';

  @override
  String get reminderFastingEndBody =>
      'Hazır olduğunda orucunu bitirebilirsin.';

  @override
  String get reminderMotivationTitle => 'Küçük adımlar, büyük değişim';

  @override
  String get reminderMotivationBody =>
      'Bugün hedefin için yapabileceğin tek bir şeyi seç.';

  @override
  String get assistantEmptyTitle =>
      'Bugünkü beslenmen hakkında bana istediğin şeyi sorabilirsin.';

  @override
  String get assistantEmptyMessage =>
      'Profilin, günlüğün, planın, kilo kayıtların ve oruç bilgine bakarak yanıt veririm.';

  @override
  String get assistantHint =>
      'Merak ettiğin sağlık veya beslenme sorusunu yaz…';

  @override
  String get assistantSend => 'Gönder';

  @override
  String get assistantThinking => 'Yanıt hazırlanıyor';

  @override
  String get assistantClear => 'Sohbeti temizle';

  @override
  String get assistantError =>
      'Şu an yanıt veremedim. Lütfen biraz sonra tekrar dene.';

  @override
  String get assistantDisclaimer =>
      'Öneri amaçlıdır; tıbbi tanı veya tedavi yerine geçmez.';

  @override
  String get assistantQuickRemaining => 'Bugün kaç kalori hakkım kaldı?';

  @override
  String get assistantQuickProtein => 'Protein hedefime ulaştım mı?';

  @override
  String get assistantQuickDinner => 'Akşam için ne yiyebilirim?';

  @override
  String get assistantQuickSwap => 'Planımdaki yemeği değiştirebilir miyim?';

  @override
  String get assistantQuickOver => 'Bugün çok fazla kalori aldım';

  @override
  String assistantRemainingCalories(
    String consumed,
    String target,
    String remaining,
  ) {
    return 'Bugün $consumed kcal aldın. Hedefin $target kcal, yani $remaining kcal hakkın kaldı.';
  }

  @override
  String assistantOverCaloriesInfo(
    String consumed,
    String target,
    String over,
  ) {
    return 'Bugün $consumed kcal aldın; hedefin $target kcal. Hedefin $over kcal üzerindesin — bu tek bir gün, sorun değil.';
  }

  @override
  String assistantProteinReached(String consumed, String target) {
    return 'Evet! Bugün $consumed g protein aldın, hedefin $target g. Harika gidiyorsun.';
  }

  @override
  String assistantProteinRemaining(
    String consumed,
    String target,
    String remaining,
  ) {
    return 'Henüz değil: $consumed / $target g protein. $remaining g daha var. Profiline uygun protein kaynaklarını tariflerden seçebilirsin.';
  }

  @override
  String assistantSuggestionIntro(String meal, String remaining) {
    return '$meal için yaklaşık $remaining kcal hakkın var. Şunlar uyabilir:';
  }

  @override
  String assistantSuggestionLight(String meal, String remaining) {
    return '$meal için $remaining kcal kaldı; hafif ama doyurucu bir seçenek öneririm:';
  }

  @override
  String assistantSuggestionOver(String meal) {
    return 'Bugünkü hedefine ulaştın; yine de $meal öğününü atlama. Sebze ve protein ağırlıklı hafif bir seçenek iyi olur:';
  }

  @override
  String assistantSuggestionFromPlan(String title, String kcal) {
    return 'Planındaki: $title ($kcal kcal)';
  }

  @override
  String get assistantSuggestionNone =>
      'Tercihlerine uyan bir öneri bulamadım. Tariflere göz atabilirsin.';

  @override
  String get assistantSwapGeneral =>
      'Elbette. Beslenme Planı\'nda bir öğüne dokunup “Bu yemeği değiştir”i seçersen hedefine, diyet tipine ve alerjilerine uygun alternatifler gösteririm.';

  @override
  String assistantSwapMeal(String meal, String title) {
    return 'Evet. Bugünkü $meal öğünün: $title. Beslenme Planı\'nda bu öğüne dokunup “Bu yemeği değiştir”i seçerek benzer kalorili alternatiflerden birini seçebilirsin.';
  }

  @override
  String assistantOverTarget(String over) {
    return 'Bugün hedefinin yaklaşık $over kcal üzerindesin. Bu tek bir gün ve ilerlemeni bozmaz. Kendini cezalandırmana ya da öğün atlamana gerek yok; su içmeye devam et, sonraki öğünü dengeli seç ve yarın planına kaldığın yerden devam et.';
  }

  @override
  String get assistantOverTargetNotReally =>
      'Kayıtlarına göre bugün hedefinin üzerine çıkmadın. Bazen öyle hissettirebilir; dengeli devam ediyorsun.';

  @override
  String assistantWaterReached(String amount) {
    return 'Bugün $amount su içtin, hedefine ulaştın.';
  }

  @override
  String assistantWaterRemaining(String amount, String goal, String left) {
    return 'Bugün $amount su içtin; hedefin $goal. $left daha içebilirsin.';
  }

  @override
  String get assistantWeightEmpty =>
      'Henüz kilo kaydın yok. Kilo Takibi\'nden ilk kaydını ekleyebilirsin.';

  @override
  String assistantWeightProgress(String start, String current, String change) {
    return 'Başlangıç: $start, şu an: $current ($change).';
  }

  @override
  String assistantWeightTarget(String target, String left) {
    return 'Hedefin $target; $left kaldı.';
  }

  @override
  String assistantWaist(String value) {
    return 'Son bel ölçün: $value.';
  }

  @override
  String get assistantWeightNote =>
      'Haftada yaklaşık 0,25–1 kg arası değişim sürdürülebilir kabul edilir; günlük dalgalanmalar normaldir.';

  @override
  String get assistantFastingNone =>
      'Henüz bir oruç protokolü seçmedin. Aralıklı Oruç sayfasından planlayabilirsin.';

  @override
  String assistantFastingActive(String time) {
    return 'Oruçtasın. Hedefe kalan süre: $time.';
  }

  @override
  String assistantFastingEating(String time) {
    return 'Yeme penceresindesin. Pencerenin kapanmasına $time var.';
  }

  @override
  String get assistantSafetyMedical =>
      'Bu konu tıbbi bir değerlendirme gerektiriyor; teşhis koyamam veya ilaç ve tedavi hakkında öneri veremem. Lütfen doktoruna ya da bir diyetisyene danış. Genel beslenme sorularında yardımcı olmaya devam edebilirim.';

  @override
  String get assistantSafetyEatingDisorder =>
      'Bunu paylaştığın için teşekkürler. Yemekle ilişkin seni zorluyorsa yalnız değilsin; bu konuda bir doktor, psikolog veya diyetisyenden destek almanı öneririm. Kendini güvende hissetmiyorsan hemen 112\'yi arayabilirsin.';

  @override
  String get assistantSafetyRestriction =>
      'Aşırı düşük kalori, öğün atlama veya çok hızlı kilo verme sağlığına zarar verebilir; bunu önermem. Sürdürülebilir ilerleme için hedefine uygun, dengeli bir plan daha etkilidir. Kişisel bir program için bir diyetisyene danışabilirsin.';

  @override
  String get assistantHelp =>
      'Bu soru mevcut yerel beslenme bilgisinin kapsamında değil. Uydurma veya kişiye özel tıbbi bilgi üretmiyorum. Şunları sorabilirsin: bugünkü beslenme değerlendirmen, aldığın veya kalan kalori, protein kaynakları, bir öğün veya tarif, su takibi, haftalık menün, alışveriş listen, kilo hedefi veya uyku. Kayıt yoksa tahmin etmem.';

  @override
  String get assistantClarifyPrompt => 'Bunu hangi açıdan öğrenmek istiyorsun?';

  @override
  String get assistantDetailAsk =>
      'Bunu biraz daha açar mısın? Örneğin bugünkü kalorini, bir öğün önerisini veya su takibini sorabilirsin.';

  @override
  String get assistantOpenDiary => 'Öğünlerimi aç';

  @override
  String get assistantOpenWater => 'Su takibine git';

  @override
  String get assistantOpenPlan => 'Menümü görüntüle';

  @override
  String get assistantOpenRecipes => 'Tarifleri incele';

  @override
  String get assistantOpenShopping => 'Alışveriş listemi aç';

  @override
  String get assistantOpenWeight => 'Kilo takibine git';

  @override
  String get assistantOpenFasting => 'Oruç takibine git';

  @override
  String get assistantNotConfigured =>
      'Beslenme asistanı şu anda yapılandırılmamış.';

  @override
  String get assistantOffline =>
      'İnternet bağlantısı yok. Önceki sohbetin duruyor; yeni bir yanıt için bağlantı gerekir.';

  @override
  String get assistantTimeout =>
      'Yanıt zaman aşımına uğradı. Tekrar deneyebilirsin.';

  @override
  String get assistantRateLimited =>
      'Çok sık istek gönderildi. Biraz sonra tekrar dene.';

  @override
  String get assistantInvalidResponse =>
      'Asistan yanıtı okunamadı. Tekrar deneyebilirsin.';

  @override
  String get assistantEmptyResponse =>
      'Asistan boş bir yanıt döndürdü. Tekrar deneyebilirsin.';

  @override
  String get assistantMalformed =>
      'Asistan yanıtı bozuk. Tekrar deneyebilirsin.';

  @override
  String get assistantUnavailable =>
      'Beslenme asistanı şu anda kullanılamıyor.';

  @override
  String get assistantMessageTooLong =>
      'Mesajın çok uzun. Daha kısa bir soru yaz.';

  @override
  String get assistantRetry => 'Tekrar dene';

  @override
  String get assistantPrivacyTitle => 'Asistan hakkında';

  @override
  String get assistantPrivacyBody =>
      'Beslenme asistanı öneri amaçlıdır. Tanı koymaz, ilaç veya tedavi önermez ve doktorun ya da diyetisyeninin yerine geçmez. Sohbet geçmişi yalnızca bu cihazda tutulur ve Firebase\'e gönderilmez. Bir soru gönderildiğinde, yanıt için gereken sınırlı bağlam yapılandırılmış bir sunucu ucuna iletilebilir; sağlayıcı anahtarı uygulamada saklanmaz. Adım, mesafe ve aktif kalori Firebase\'e yazılmaz; aktivite veya gün özeti sorduğunda cihazından giden isteğe eklenebilir. Asistan günlüğünü, planını, su kaydını veya kalori hedefini kendiliğinden değiştirmez.';

  @override
  String get assistantRecordsLabel => 'Kayıtların';

  @override
  String get assistantCommentaryLabel => 'Yorum';

  @override
  String get assistantMissingInfo => 'Bu bilgiye erişemiyorum.';

  @override
  String get assistantAllergyBlocked =>
      'Alerjine uymayan bir öneri gösteremem. Güvenli bir alternatif için tariflere bakabilirsin.';

  @override
  String assistantConsumedOnly(String consumed) {
    return 'Bugün $consumed kcal aldın. Kalori hedefin kayıtlı değil.';
  }

  @override
  String assistantMacroLine(String name, String consumed, String target) {
    return '$name: $consumed / $target g';
  }

  @override
  String assistantWaterOnly(String amount) {
    return 'Bugün $amount su içtin. Su hedefin kayıtlı değil.';
  }

  @override
  String assistantActivitySteps(int steps) {
    return 'Bugün $steps adım attın.';
  }

  @override
  String assistantActivityDistance(String km) {
    return 'Mesafe: $km km.';
  }

  @override
  String assistantActivityCalories(String kcal) {
    return 'Aktif kalori: $kcal kcal.';
  }

  @override
  String assistantActivityWorkouts(int count) {
    return 'Antrenman: $count.';
  }

  @override
  String get assistantPlanEmpty => 'Bugün için kayıtlı bir plan göremiyorum.';

  @override
  String get assistantRecipeHeading => 'Kataloğundaki uygun tarifler:';

  @override
  String assistantRecipeLine(String title, String kcal, String protein) {
    return '$title ($kcal kcal, $protein g protein)';
  }

  @override
  String get assistantQuickToday => 'Bugün nasıl besleniyorum?';

  @override
  String get assistantQuickProteinBoost => 'Proteinimi nasıl artırırım?';

  @override
  String get assistantQuickWaterGoal => 'Su hedefime ulaştım mı?';

  @override
  String get assistantQuickPlanReview => 'Bugünkü planımı değerlendir';

  @override
  String get assistantQuickRecipe => 'Bana uygun tarif öner';

  @override
  String get assistantQuickDinnerLose =>
      'Kilo verme hedefime uygun akşam yemeği öner.';

  @override
  String get assistantQuickProteinMeal => 'Protein ağırlıklı bir öğün öner.';

  @override
  String get targetChangeTitle =>
      'Yeni kilo bilgine göre günlük hedefini yeniden hesaplamak ister misin?';

  @override
  String get targetChangeCurrentWeight => 'Mevcut kilo';

  @override
  String get targetChangeNewWeight => 'Yeni kilo';

  @override
  String get targetChangeCurrentCalories => 'Mevcut günlük hedef';

  @override
  String get targetChangeNewCalories => 'Yeni önerilen hedef';

  @override
  String get targetChangeUseNew => 'Yeni hedefi kullan';

  @override
  String get targetChangeKeepCurrent => 'Mevcut hedefi koru';

  @override
  String get targetChangeSafety =>
      'Aşırı düşük kalori hedefleri güvenlik için sınırlanır. Bu bir tahmindir; tıbbi veya diyetisyen önerisi değildir.';

  @override
  String targetChangeMacros(String protein, String carbs, String fat) {
    return 'Önerilen makrolar: $protein g protein, $carbs g karbonhidrat, $fat g yağ.';
  }

  @override
  String get sleepHoursTitle => 'Uyku saatleri';

  @override
  String get sleepHoursHint => 'Bu saatlerde su hatırlatması gönderilmez.';

  @override
  String get sleepStart => 'Uyku başlangıcı';

  @override
  String get sleepEnd => 'Uyku bitişi';

  @override
  String get notificationsPermissionHint =>
      'Bildirim izni, hatırlatıcıları açtığında sorulur.';

  @override
  String get waterTodayTitle => 'Bugün';

  @override
  String get waterHistoryTitle => 'Geçmiş günler';

  @override
  String get waterEmptyHistory => 'Diğer günlerde henüz su kaydı yok.';

  @override
  String waterRemoveAmount(int amount) {
    return '$amount ml azalt';
  }

  @override
  String get shoppingMyList => 'Alışveriş Listem';

  @override
  String get shoppingAddItem => 'Ürün ekle';

  @override
  String get shoppingItemName => 'Ürün';

  @override
  String get shoppingQuantity => 'Miktar';

  @override
  String get shoppingUnit => 'Birim';

  @override
  String get shoppingGenerateWeek => 'Bu haftanın alışveriş listesini oluştur';

  @override
  String shoppingGenerated(int count) {
    return 'Plandan $count ürün eklendi.';
  }

  @override
  String get shoppingEmptyTitle => 'Listen boş';

  @override
  String get shoppingEmptyMessage =>
      'Kendin ürün ekleyebilir veya bu haftanın planından liste oluşturabilirsin.';

  @override
  String get shoppingCompleted => 'Tamamlandı';

  @override
  String get shoppingClearCompleted => 'Tamamlananları temizle';

  @override
  String get shoppingFromRecipe => 'Tariften';

  @override
  String get shoppingFromPlan => 'Plandan';

  @override
  String get shoppingCategoryProduce => 'Sebze & Meyve';

  @override
  String get shoppingCategoryMeat => 'Et & Tavuk';

  @override
  String get shoppingCategoryDairy => 'Süt Ürünleri';

  @override
  String get shoppingCategoryGrains => 'Tahıl & Bakliyat';

  @override
  String get shoppingCategoryBreakfast => 'Kahvaltılık';

  @override
  String get shoppingCategoryOther => 'Diğer';

  @override
  String get recipeAddToShopping => 'Malzemeleri alışveriş listesine ekle';

  @override
  String get recipeAddedToShopping => 'Malzemeler alışveriş listesine eklendi.';

  @override
  String get photoLogPick => 'Fotoğraf çek veya seç';

  @override
  String get photoLogCamera => 'Kamera';

  @override
  String get photoLogGallery => 'Galeri';

  @override
  String get photoLogAnalyzing => 'Fotoğraf analiz ediliyor…';

  @override
  String get photoLogUploading => 'Fotoğraf hazırlanıyor…';

  @override
  String get photoLogMatching => 'Yiyecekler eşleştiriliyor…';

  @override
  String get photoLogResults => 'Algılanan yiyecekler';

  @override
  String get photoLogEstimateBadge => 'Aday';

  @override
  String get photoLogAddToDiary => 'Günlüğe Ekle';

  @override
  String get photoLogAdded => 'Yiyecekler günlüğe eklendi.';

  @override
  String get photoLogDisclaimer =>
      'Sonuçlar adaydır. Besin değerleri onayından sonra yiyecek kaydından hesaplanır. Fotoğraf kaydedilmez.';

  @override
  String get photoLogName => 'Yiyecek adı';

  @override
  String get photoLogAmount => 'Miktar';

  @override
  String get photoLogPortion => 'Porsiyon';

  @override
  String get photoLogMeal => 'Öğün';

  @override
  String get voiceLogHint =>
      'Örneğin: İki yumurta, elli gram peynir ve iki dilim ekmek yedim.';

  @override
  String get voiceLogSimulate => 'Örnek cümleyi kullan';

  @override
  String get voiceLogParse => 'Ayır';

  @override
  String get voiceLogResults => 'Ayrıştırılmış sonuçlar';

  @override
  String get voiceLogEmpty =>
      'Yiyecek bulunamadı. Metni düzenleyip yeniden deneyebilirsin.';

  @override
  String get voiceLogDisclaimer =>
      'Konuşma metne çevrilir ve yiyecekler aday olarak ayrılır. Besin değerleri onayından sonra hesaplanır. Ses kaydı saklanmaz.';

  @override
  String get voiceLogListening => 'Dinleniyor…';

  @override
  String get voiceLogStop => 'Durdur';

  @override
  String get voiceLogMic => 'Konuş';

  @override
  String get voiceLogMicSemantics => 'Mikrofonla yiyecek söyle';

  @override
  String get voiceLogTranscript => 'Metin';

  @override
  String get photoLogNoMatch => 'Eşleşme bulunamadı';

  @override
  String get photoLogSearchAgain => 'Tekrar ara';

  @override
  String get photoLogManualSearch => 'Manuel ara';

  @override
  String get photoLogCreateCustom => 'Özel yiyecek oluştur';

  @override
  String get photoLogRemove => 'Yiyeceği sil';

  @override
  String get photoLogAddFood => 'Yiyecek ekle';

  @override
  String get photoLogChangeFood => 'Yiyeceği değiştir';

  @override
  String get photoLogChooseMatch => 'Bir eşleşme seç';

  @override
  String get photoLogAmbiguousQuantity => 'Miktarı seç';

  @override
  String get photoLogSelectMeal => 'Öğün seç';

  @override
  String get photoLogAllergyWarning =>
      'Bu yiyecek profilinizdeki alerjiyle eşleşiyor. Bu bir güvenlik doğrulaması değildir.';

  @override
  String get photoLogDislikeWarning =>
      'Bu yiyecek profilinde sevmediğin yiyecekler arasında.';

  @override
  String get photoLogDietWarning =>
      'Bu yiyecek profilindeki beslenme tercihiyle çakışıyor olabilir.';

  @override
  String get photoLogAcknowledge => 'Uyarıyı gördüm, yine de ekle';

  @override
  String get photoLogCalculated => 'Besin değeri yiyecek kaydından';

  @override
  String photoLogAssumption(String quantity, String unit, String grams) {
    return '$quantity $unit ≈ $grams g. Miktarı değiştirebilirsin.';
  }

  @override
  String photoLogConfidence(String percent) {
    return 'Güven %$percent';
  }

  @override
  String get photoLogCameraSemantics => 'Kamerayla fotoğraf çek';

  @override
  String get photoLogGallerySemantics => 'Galeriden fotoğraf seç';

  @override
  String get photoLogManualGrams => 'Manuel gram';

  @override
  String get voiceUnitTea => 'çay kaşığı';

  @override
  String get voiceUnitSpoon => 'kaşık';

  @override
  String get voiceUnitPlate => 'tabak';

  @override
  String get voiceUnitDessert => 'tatlı kaşığı';

  @override
  String get captureErrorNotConfigured =>
      'Fotoğrafla yiyecek tanıma şu anda yapılandırılmamış.';

  @override
  String get captureErrorTimeout =>
      'İstek zaman aşımına uğradı. Lütfen tekrar dene.';

  @override
  String get captureErrorOffline =>
      'İnternet bağlantısı yok. Fotoğraf ve ses tanıma şu an kullanılamaz.';

  @override
  String get captureErrorRateLimited =>
      'Çok fazla istek gönderildi. Biraz sonra tekrar dene.';

  @override
  String get captureErrorInvalid => 'Yanıt okunamadı. Lütfen tekrar dene.';

  @override
  String get captureErrorEmpty => 'Yiyecek bulunamadı.';

  @override
  String get captureErrorMalformed => 'Yanıt bozuk. Lütfen tekrar dene.';

  @override
  String get captureErrorUnavailable => 'Hizmet şu anda kullanılamıyor.';

  @override
  String get captureErrorImageTooLarge =>
      'Fotoğraf çok büyük. Daha küçük bir görsel dene.';

  @override
  String get captureErrorUnsupportedImage => 'Bu görsel biçimi desteklenmiyor.';

  @override
  String get captureErrorSpeechUnavailable =>
      'Konuşma tanıma bu cihazda kullanılamıyor. Metni yazabilirsin.';

  @override
  String get captureErrorTranscription => 'Konuşma metne çevrilemedi.';

  @override
  String get captureErrorAmbiguous =>
      'Miktar veya yiyecek belirsiz. Seçim yapmadan kaydedilmez.';

  @override
  String get captureErrorNotFound =>
      'Eşleşen yiyecek yok. Aramadan veya özel yiyecek oluşturmadan kaydedilmez.';

  @override
  String get captureErrorConfirmation => 'Kaydetmek için onay gerekli.';

  @override
  String get captureErrorDuplicate => 'Bu ekleme zaten işlendi.';

  @override
  String get captureErrorAllergy =>
      'Alerji uyarısı onaylanmadan yiyecek kaydedilmez.';

  @override
  String get confirmNewPlanTitle =>
      'Beslenme planını değiştirmek istiyor musun?';

  @override
  String get confirmNewPlanMessage =>
      'Bu haftanın kalan öğünleri yeniden oluşturulur. Önceki öğünler tutulmaz.';

  @override
  String get confirmRegeneratePlanTitle =>
      'Bugünün planını yenilemek istiyor musun?';

  @override
  String get confirmRegeneratePlanMessage =>
      'Bugünün planlanan tüm öğünleri değişecek.';

  @override
  String get confirmFastingTitle => 'Oruç planını değiştirmek istiyor musun?';

  @override
  String get confirmFastingMessage =>
      'Yeme penceren ve oruç hatırlatmaların yeni protokole göre güncellenir.';

  @override
  String get waterAdd100 => '+100 ml';

  @override
  String get waterAdd250 => '+250 ml';

  @override
  String get waterAdd500 => '+500 ml';

  @override
  String get weeklyPlanTitle => '7 Günlük Plan';

  @override
  String get confirmRegenerateWeekTitle =>
      '7 günlük planı yenilemek istiyor musun?';

  @override
  String get confirmRegenerateWeekMessage =>
      'Bu haftanın öğünleri profilindeki kalori ve makro hedeflerine göre yeniden oluşturulur. Onaylamadan mevcut plan değişmez.';

  @override
  String get planChangeRecipe => 'Bu tarifi değiştir';

  @override
  String get macroFiber => 'Lif';

  @override
  String get paywallPurchaseLater =>
      'Gerçek satın alma bu sürümde yok. Fiyat veya abonelik taahhüdü gösterilmez.';

  @override
  String get assistantMissingMeals =>
      'Bugün için beslenme kaydı yok. Değerlendirme yapmam için günlüğe bir öğün eklemen gerekir. Tahmin üretmiyorum.';

  @override
  String get assistantMissingMacros =>
      'Öğün kaydın var ama protein, karbonhidrat ve yağ değerleri yok. Bu makroları tahmin etmiyorum.';

  @override
  String get assistantMissingPlan =>
      'Bugün için kayıtlı bir menü yok. Kayıtlı plana dayanmadan öğün uydurmuyorum.';

  @override
  String assistantDailyIntro(int meals, String consumed, String target) {
    return 'Bugün $meals öğün kaydın var. $consumed / $target kcal.';
  }

  @override
  String assistantDailyOver(String over) {
    return 'Hedefinin $over kcal üstündesin. Öğün atlamayı önermem; sıradaki öğünü daha hafif tutabilirsin.';
  }

  @override
  String assistantDailyProteinShort(String consumed, String target) {
    return 'Protein hedefin dolmadı ($consumed / $target g). Profiline uyan bir protein kaynağı ekleyebilirsin.';
  }

  @override
  String get assistantDailyOnTrack =>
      'Kayıtların hedefinle uyumlu görünüyor. Bu bir tıbbi değerlendirme değildir.';

  @override
  String get assistantDailyTargetLow =>
      'Kayıtlı günlük kalori hedefin genel güvenlik sınırının altında. Daha düşük bir hedef önermiyorum.';

  @override
  String assistantMacroReached(String name, String consumed, String target) {
    return '$name: $consumed / $target g. Bu makro için kayıtlı hedefe ulaşmışsın.';
  }

  @override
  String assistantMacroRemaining(
    String name,
    String consumed,
    String target,
    String remaining,
  ) {
    return '$name: $consumed / $target g. Kayıtlara göre $remaining g daha var.';
  }

  @override
  String get assistantPlanHeading => 'Bugün kayıtlı menündeki öğünler:';

  @override
  String get assistantNutritionUnrecorded => 'besin değeri kayıtlı değil';

  @override
  String get adBannerLabel => 'Reklam';

  @override
  String get assistantWelcome =>
      'Bugün daha dengeli beslenmek için sana nasıl yardımcı olabilirim?';

  @override
  String get assistantSummaryTitle => 'Günlük beslenme özeti';

  @override
  String get assistantSummaryEmpty =>
      'Bugün için öğün kaydı yok. Kayıt eklediğinde alınan, hedef ve kalan kaloriyi burada gösterebilirim.';

  @override
  String assistantSummaryNoTarget(String consumed) {
    return 'Alınan $consumed kcal. Kişisel kalori hedefin kayıtlı olmadığı için kalan kaloriyi hesaplamıyorum.';
  }

  @override
  String assistantSummaryCalories(
    String consumed,
    String target,
    String remaining,
  ) {
    return 'Alınan $consumed kcal. Hedef $target kcal. Kalan $remaining kcal.';
  }

  @override
  String assistantSummaryOver(String consumed, String target, String over) {
    return 'Alınan $consumed kcal. Hedef $target kcal. Hedefin $over kcal üzerinde.';
  }

  @override
  String get assistantSummaryError => 'Günlük özet şu anda okunamadı.';

  @override
  String get assistantSearchHint => 'Kategori ara';

  @override
  String get assistantSearchEmpty => 'Bu aramayla eşleşen kategori yok.';

  @override
  String get assistantNutritionSection => 'Beslenme';

  @override
  String get assistantWellnessSection => 'Sağlıklı Yaşam';

  @override
  String get assistantSectionDiet => 'Beslenme ve diyet';

  @override
  String get assistantSectionFoods => 'Yiyecekler ve besin seçimi';

  @override
  String get assistantSectionHabits => 'Günlük yaşam ve alışkanlıklar';

  @override
  String get assistantSectionDigestion => 'Sindirim ve genel sağlık';

  @override
  String get assistantSectionSpecial => 'Özel beslenme ihtiyaçları';

  @override
  String get assistantSuggestedTitle => 'Önerilen sorular';

  @override
  String get assistantQuickDaily => 'Günlük değerlendirme';

  @override
  String get assistantQuickMeals => 'Öğün önerileri';

  @override
  String get assistantQuickWellness => 'Sağlıklı yaşam';

  @override
  String get assistantQuickWeek => 'Haftalık değerlendirme';

  @override
  String get assistantBrowseTopics => 'Kategoriler';

  @override
  String get assistantClearTitle => 'Sohbet temizlensin mi?';

  @override
  String get assistantClearBody =>
      'Bu cihazdaki beslenme asistanı konuşması silinir.';

  @override
  String get assistantGuideMissingMeals =>
      'Bugünkü öğün kayıtların eksik olduğu için tam bir değerlendirme yapamıyorum. Günlüğe bir öğün ekleyince buradan bakabilirim.';

  @override
  String get assistantGuideWaterMissing =>
      'Bugün için su kaydı yok. Miktarı tahmin etmiyorum.';

  @override
  String assistantGuideWeekIntro(int elapsed, int logged) {
    return 'Bu hafta bugüne kadar $elapsed günün $logged gününde öğün kaydı var.';
  }

  @override
  String assistantGuideWeekDay(String day, String kcal) {
    return '$day: $kcal kcal.';
  }

  @override
  String assistantGuideWeekDayTarget(String day, String kcal, String target) {
    return '$day: $kcal kcal, hedef $target kcal.';
  }

  @override
  String get assistantGuideWeekNoMeals =>
      'Bu hafta için öğün kaydı yok. Kayıt olmayan günleri başarısızlık saymıyorum.';

  @override
  String assistantGuideWeekWater(int count, String amount) {
    return 'Su kaydı olan $count günde toplam $amount.';
  }

  @override
  String get assistantGuideWeekWaterNone =>
      'Bu hafta su kaydı yok. İçilen miktarı tahmin etmiyorum.';

  @override
  String get assistantGuideWeekNote =>
      'Yalnızca kayıtlı günleri değerlendiriyorum. Eksik kayıt yanlış beslenme değildir.';

  @override
  String assistantGuideMealCoverage(String logged, String missing) {
    return 'Kayıtlı öğün türleri: $logged. Kaydı olmayanlar: $missing. Kaydı olmayan öğünü yanlış beslenme saymıyorum.';
  }

  @override
  String get assistantGuideTagsMissing =>
      'Öğün kayıtlarında besin grubu etiketi yok. Hangi grubu az tükettiğini tahmin etmiyorum.';

  @override
  String assistantGuideTags(String tags) {
    return 'Kayıtlardaki etiketler: $tags. Etiketi olmayan gruplar hakkında kesin konuşmuyorum.';
  }

  @override
  String get assistantGuideRecipesIntro =>
      'Kayıtlı tariflerden tercihlerine uygun olanlar:';

  @override
  String get assistantGuideRecipesNone =>
      'Kayıtlı tariflerde tercihlerine uyan bir sonuç bulamadım. Var olmayan tarif yazmıyorum.';

  @override
  String get assistantGuideRecipesEmpty =>
      'Bu cihazda kayıtlı tarif yok. Tarif ekleyince buradan gösterebilirim.';

  @override
  String get assistantGuidePrefsNone =>
      'Kayıtlı alerji, sevmediğin besin veya beslenme düzeni bulamadım. Bunları varsaymıyorum.';

  @override
  String assistantGuidePrefsKnown(String summary) {
    return 'Kayıtlı bilgiler: $summary. Bunlarla çelişen bir besin önermem.';
  }

  @override
  String get assistantGuidePlanEmpty =>
      'Bu hafta için kayıtlı menü yok. Planı kendiliğimden oluşturmam veya değiştirmem.';

  @override
  String get assistantGuidePlanHeading => 'Kayıtlı menüdeki öğünler:';

  @override
  String assistantGuideShopping(int manual, int generated) {
    return 'Plandan gelmeyen $manual ürün durur. Plan kaynaklı $generated satır, liste yenilenirken güncellenebilir. Ben listeyi silmem.';
  }

  @override
  String get assistantGuideShoppingEmpty =>
      'Kayıtlı alışveriş listen boş. Haftalık menüden liste oluşturduğunda elle eklediğin ürünler durur.';

  @override
  String assistantGuideShoppingManual(String names) {
    return 'Plandan gelmeyenler: $names.';
  }

  @override
  String get assistantGuideDisclaimer =>
      'Bu bilgi genel bilgilendirme amaçlıdır; kişisel sağlık durumun için bir sağlık profesyoneline danışmalısın.';

  @override
  String get assistantGuideBoundary =>
      'Bu soruyu kayıtlı bilgiler ve güvenli genel çerçeve dışında yanıtlayamıyorum.';

  @override
  String get assistantGuideTips => 'Uygulanabilecek genel adımlar:';

  @override
  String get assistantGuideNone => 'yok';

  @override
  String get assistantSafetyEmergency =>
      'Bu belirtiler acil olabilir. Şiddetli göğüs ağrısı, nefes darlığı, bayılma, ani güçsüzlük, durmayan kanama veya ciddi alerji tepkisi varsa gecikmeden acil sağlık hizmetine başvur. Teşhis koyamam.';

  @override
  String get assistantPremiumRequired =>
      'Beslenme asistanı Premium üyelik gerektirir.';

  @override
  String get assistantDataHeading => 'Kayıtlı verin:';

  @override
  String get assistantFoodTagVegetable => 'Sebze';

  @override
  String get assistantFoodTagFruit => 'Meyve';

  @override
  String get assistantFoodTagWholeGrain => 'Tam tahıl';

  @override
  String get assistantFoodTagProcessed => 'İşlenmiş';
}
