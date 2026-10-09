// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Diet Program';

  @override
  String get navHome => 'Today';

  @override
  String get navDiary => 'Diary';

  @override
  String get navPlans => 'Plans';

  @override
  String get navProgress => 'Progress';

  @override
  String get navProfile => 'Profile';

  @override
  String get featureDashboard => 'Today';

  @override
  String get featureNutrition => 'Nutrition Plan';

  @override
  String get featureDiary => 'Food Diary';

  @override
  String get featureFoodSearch => 'Search Food';

  @override
  String get featureRecipes => 'Recipes';

  @override
  String get featureMealPlans => 'Meal Plan';

  @override
  String get featureShoppingList => 'Shopping List';

  @override
  String get featureWater => 'Water';

  @override
  String get featureWeight => 'Weight';

  @override
  String get featureMeasurements => 'Body Measurements';

  @override
  String get featureProgress => 'Progress';

  @override
  String get featureFasting => 'Intermittent Fasting';

  @override
  String get featureActivity => 'Activity';

  @override
  String get featureNotifications => 'Notifications';

  @override
  String get featureAiCoach => 'Nutrition Assistant';

  @override
  String get featureBarcode => 'Scan Barcode';

  @override
  String get featureProfile => 'Profile';

  @override
  String get featurePremium => 'Premium';

  @override
  String get featureSettings => 'Settings';

  @override
  String get featurePersonalInfo => 'Personal info';

  @override
  String get personalInfoSaved => 'Your details were saved.';

  @override
  String get personalInfoEmptyTitle => 'No profile yet';

  @override
  String get personalInfoEmptyMessage =>
      'Your goals and preferences live here. They fill in after you finish onboarding.';

  @override
  String get personalInfoBasics => 'Basics';

  @override
  String get personalInfoPreferences => 'Nutrition preferences';

  @override
  String get personalInfoTargetsTitle => 'Daily targets';

  @override
  String get personalInfoTargetsHint =>
      'Calorie and macro targets come from your profile; the Nutrition Plan does not store them separately.';

  @override
  String get personalInfoCurrentWeightHint =>
      'Current weight is updated from Weight Tracking.';

  @override
  String get personalInfoOpenWeight => 'Go to weight tracking';

  @override
  String get personalInfoRecalculate => 'Recalculate targets';

  @override
  String get personalInfoTargetsUpdated =>
      'Your calorie and macro targets were updated.';

  @override
  String get personalInfoPlanUpdated =>
      'Your meal plan was updated with your new preferences.';

  @override
  String get personalInfoName => 'Name';

  @override
  String get personalInfoAge => 'Age';

  @override
  String get personalInfoHeight => 'Height';

  @override
  String get personalInfoTargetWeight => 'Target weight';

  @override
  String get personalInfoWaterGoal => 'Daily water goal';

  @override
  String get onboardingHeadline => 'A nutrition plan made for you';

  @override
  String get onboardingSubtitle =>
      'Start with a plan built around your goals, lifestyle and taste.';

  @override
  String get signInTitle => 'Sign in to your account';

  @override
  String get signInSubtitle =>
      'Your progress is stored securely across all your devices.';

  @override
  String dashboardGreeting(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'morning': 'Good morning',
      'afternoon': 'Good afternoon',
      'evening': 'Good evening',
      'other': 'Hello',
    });
    return '$_temp0 👋';
  }

  @override
  String dashboardGreetingNamed(String period, String name) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'morning': 'Good morning',
      'afternoon': 'Good afternoon',
      'evening': 'Good evening',
      'other': 'Hello',
    });
    return '$_temp0, $name 👋';
  }

  @override
  String dashboardMotivation(String index) {
    String _temp0 = intl.Intl.selectLogic(index, {
      '0': 'Small steps make a big difference.',
      '1': 'Try filling half your plate with vegetables today.',
      '2': 'Keep your water bottle close and sip before you\'re thirsty.',
      '3': 'Consistency beats perfection.',
      '4': 'A protein-rich breakfast starts the day in balance.',
      '5': 'Eat slowly; fullness takes about 20 minutes to kick in.',
      'other': 'Compete with yesterday\'s you, not with others.',
    });
    return '$_temp0';
  }

  @override
  String get dashboardCaloriesTitle => 'Daily calories';

  @override
  String dashboardKcalOfTarget(String consumed, String target) {
    return '$consumed / $target kcal';
  }

  @override
  String get dashboardKcalLeft => 'kcal left';

  @override
  String get dashboardKcalOver => 'kcal over';

  @override
  String get dashboardEaten => 'Eaten';

  @override
  String get dashboardTarget => 'Target';

  @override
  String get dashboardRemaining => 'Remaining';

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
    return 'P $protein g · C $carbs g · F $fat g';
  }

  @override
  String get dashboardQuickActions => 'Quick add';

  @override
  String get quickAddFood => 'Add food';

  @override
  String get quickAddPhoto => 'Photo';

  @override
  String get quickAddBarcode => 'Scan barcode';

  @override
  String get quickAddVoice => 'Voice';

  @override
  String get dashboardMealsTitle => 'Today\'s meals';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snacks';

  @override
  String get mealEmpty => 'Nothing added yet';

  @override
  String mealAddFoodTo(String meal) {
    return 'Add food to $meal';
  }

  @override
  String mealMoreItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count more items',
      one: '+1 more item',
    );
    return '$_temp0';
  }

  @override
  String get actionSeeAll => 'See all';

  @override
  String get actionUndo => 'Undo';

  @override
  String get dashboardWaterTitle => 'Water';

  @override
  String waterGlassesProgress(int count, int goal) {
    return '$count / $goal glasses';
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
    return 'Added $ml ml of water';
  }

  @override
  String get waterGoalReached => 'You reached your daily water goal!';

  @override
  String get dashboardActivityTitle => 'Activity';

  @override
  String get activitySteps => 'Steps';

  @override
  String get activityActiveKcal => 'Active calories';

  @override
  String get activityExercise => 'Exercise';

  @override
  String minutesValue(String value) {
    return '$value min';
  }

  @override
  String stepsGoal(String goal) {
    return 'Goal $goal';
  }

  @override
  String get dashboardScoreTitle => 'Daily nutrition score';

  @override
  String get scoreOutOf => '/ 100';

  @override
  String get scoreBandStarting => 'Just getting started';

  @override
  String get scoreBandFair => 'Room to improve';

  @override
  String get scoreBandGood => 'Doing well';

  @override
  String get scoreBandGreat => 'Doing great';

  @override
  String get scoreFactorCalories => 'Closeness to calorie target';

  @override
  String get scoreFactorProtein => 'Protein target';

  @override
  String get scoreFactorFiber => 'Fiber';

  @override
  String get scoreFactorWater => 'Water';

  @override
  String get scoreFactorProduce => 'Vegetables & fruit';

  @override
  String get scoreFactorProcessed => 'Processed food share';

  @override
  String get scoreFactorMealRhythm => 'Meal regularity';

  @override
  String get scoreTipCalories =>
      'Add a balanced meal to get closer to your target.';

  @override
  String get scoreTipProtein =>
      'Try adding a protein source to your next meal.';

  @override
  String get scoreTipFiber =>
      'Whole grains, legumes and vegetables boost your fiber.';

  @override
  String get scoreTipWater => 'Now is a good time for a glass of water.';

  @override
  String get scoreTipProduce => 'Try adding a serving of vegetables or fruit.';

  @override
  String get scoreTipProcessed => 'Choose whole foods over packaged snacks.';

  @override
  String get scoreTipMealRhythm =>
      'Logging meals regularly makes balance easier.';

  @override
  String scorePoints(String points, int max) {
    return '$points / $max';
  }

  @override
  String get scoreDetails => 'How is the score calculated?';

  @override
  String get scoreDisclaimerShort =>
      'A general habit indicator, not a medical diagnosis.';

  @override
  String get scoreDisclaimerLong =>
      'The nutrition score is a general indicator based on closeness to your calorie target, protein, fiber, water, vegetable and fruit intake, processed food share, macro balance and meal regularity. It is not a scientific medical assessment or diagnosis. Consult your doctor or dietitian for decisions about your health.';

  @override
  String get dashboardPlanTitle => 'Today\'s plan';

  @override
  String get planLogged => 'Logged';

  @override
  String get planEmpty => 'No meals planned for today.';

  @override
  String get planCreate => 'Create a plan';

  @override
  String get planTodayTitle => 'My plan for today';

  @override
  String planDayTotal(String kcal, String target) {
    return '$kcal / $target kcal';
  }

  @override
  String get planApproxNote =>
      'Nutrition values are approximate and vary with recipe and portion.';

  @override
  String planPortion(String factor) {
    return '$factor servings';
  }

  @override
  String get planSwapMeal => 'Swap';

  @override
  String get planLogMeal => 'Log meal';

  @override
  String planMealLogged(String meal) {
    return '$meal logged';
  }

  @override
  String planMealSwapped(String meal, String title) {
    return 'New $meal suggestion: $title';
  }

  @override
  String get planRegenerate => 'New plan';

  @override
  String get planAssistantName => 'Plan assistant';

  @override
  String get planChangeTitle => 'Change this plan';

  @override
  String get planChangeSubtitle =>
      'Something you don\'t like? Tell me and I\'ll suggest alternatives.';

  @override
  String get planChangeHint => 'e.g. I don\'t like chicken';

  @override
  String get planChangeSend => 'Send';

  @override
  String get planSuggestionDislike => 'I don\'t like chicken';

  @override
  String get planSuggestionSwapDinner => 'Change dinner';

  @override
  String get planSuggestionNoEggBreakfast => 'No eggs at breakfast';

  @override
  String get planSuggestionFish => 'I want fish for dinner';

  @override
  String get planSuggestionWholePlan => 'Change this plan';

  @override
  String planReplyExcluded(String ingredients) {
    return 'I swapped these meals for alternatives without $ingredients:';
  }

  @override
  String planReplyChangeLine(String meal, String from, String to) {
    return '$meal: $from → $to';
  }

  @override
  String planReplyAlreadyAbsent(String ingredients) {
    return 'Your plan already has no $ingredients.';
  }

  @override
  String planReplyRemembered(String ingredients) {
    return 'I won\'t suggest $ingredients in future plans.';
  }

  @override
  String planReplyNoAlternative(String meal) {
    return 'I couldn\'t find another $meal option that fits your preferences.';
  }

  @override
  String planReplyDiet(String diet) {
    return 'I updated your plan ($diet):';
  }

  @override
  String planReplyDietUnchanged(String diet) {
    return 'Your plan already fits ($diet).';
  }

  @override
  String planReplyPreferred(String ingredients) {
    return 'As requested, I added a meal with $ingredients:';
  }

  @override
  String planReplyAlreadyPresent(String ingredients, String meals) {
    return 'Your plan already includes $ingredients: $meals.';
  }

  @override
  String planReplyPreferredNone(String ingredients) {
    return 'I couldn\'t find a meal with $ingredients that fits your preferences.';
  }

  @override
  String get planReplySwapped => 'Here are new suggestions:';

  @override
  String get planReplyRegenerated => 'I made you a new plan for the day.';

  @override
  String get planReplyNotUnderstood =>
      'I didn\'t quite get that. Try \"I don\'t like chicken\", \"Change dinner\" or \"No eggs at breakfast\".';

  @override
  String get planIngredientChicken => 'chicken';

  @override
  String get planIngredientRedMeat => 'red meat';

  @override
  String get planIngredientFish => 'fish';

  @override
  String get planIngredientShellfish => 'shellfish';

  @override
  String get planIngredientEgg => 'eggs';

  @override
  String get planIngredientMilk => 'milk';

  @override
  String get planIngredientCheese => 'cheese';

  @override
  String get planIngredientYogurt => 'yogurt';

  @override
  String get planIngredientLegumes => 'legumes';

  @override
  String get planIngredientGluten => 'gluten';

  @override
  String get planIngredientOats => 'oats';

  @override
  String get planIngredientNuts => 'nuts';

  @override
  String get planIngredientPeanut => 'peanuts';

  @override
  String get planIngredientSesame => 'sesame';

  @override
  String get planIngredientSoy => 'soy';

  @override
  String get planIngredientEggplant => 'eggplant';

  @override
  String get planIngredientMushroom => 'mushrooms';

  @override
  String get featurePhotoLog => 'Add with Photo';

  @override
  String get featureVoiceLog => 'Add with Voice';

  @override
  String get actionGetStarted => 'Get started';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionContinueAsGuest => 'Continue as guest';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionSignUp => 'Create account';

  @override
  String get actionForgotPassword => 'Forgot password?';

  @override
  String get actionSignInWithGoogle => 'Continue with Google';

  @override
  String get actionSignInWithApple => 'Continue with Apple';

  @override
  String get actionHaveAccount => 'Already have an account? Sign in';

  @override
  String get actionNeedAccount => 'New here? Create an account';

  @override
  String get actionDeleteAccount => 'Delete account';

  @override
  String get signInEmailLabel => 'Email';

  @override
  String get signInPasswordLabel => 'Password';

  @override
  String get signInNameLabel => 'Name (optional)';

  @override
  String get signInOrDivider => 'or';

  @override
  String get signInGuestAccount => 'Guest account';

  @override
  String get passwordResetSent =>
      'If an account exists for this email, a reset link will be sent.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountMessage =>
      'Your account, cloud data, and personal records on this device will be deleted. This cannot be undone.';

  @override
  String get authInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authEmailInUse => 'An account with this email already exists.';

  @override
  String get authWeakPassword =>
      'Please choose a stronger password (at least 6 characters).';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authCancelled => 'Sign-in was cancelled.';

  @override
  String get authRequiresRecentLogin =>
      'You need a recent sign-in to delete your account. Sign out, sign in again, and try once more.';

  @override
  String get errorServiceUnavailable =>
      'This sign-in method is not configured yet.';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionRemove => 'Remove';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String comingSoonMessage(String feature) {
    return 'The $feature section is being prepared.';
  }

  @override
  String get emptyStateTitle => 'Nothing here yet';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'Please check your internet connection.';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get splashTagline => 'Eat balanced, feel better';

  @override
  String get onboardingWelcomeTitle => 'Welcome';

  @override
  String get onboardingWelcomeBody =>
      'Answer a few quick questions and we\'ll build calorie and nutrient targets just for you. It only takes a couple of minutes.';

  @override
  String get onboardingBenefitPlanTitle => 'A plan made for you';

  @override
  String get onboardingBenefitPlanBody =>
      'Daily calorie and macro targets calculated with scientific formulas for your goal, body and lifestyle.';

  @override
  String get onboardingBenefitTrackingTitle => 'Effortless tracking';

  @override
  String get onboardingBenefitTrackingBody =>
      'Log meals, water and weight in seconds and follow your progress with clear charts.';

  @override
  String get onboardingBenefitHabitsTitle => 'Lasting habits';

  @override
  String get onboardingBenefitHabitsBody =>
      'No crash diets. Sustainable results at a healthy pace, with foods you enjoy.';

  @override
  String get onboardingSkipIntro => 'Skip';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Start my plan';

  @override
  String onboardingStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String onboardingProgressSemantics(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingOptional => 'Optional';

  @override
  String get qNameTitle => 'What should we call you?';

  @override
  String get qNameSubtitle => 'You can leave this empty and continue.';

  @override
  String get qNameHint => 'Your name';

  @override
  String get qGoalTitle => 'What\'s your main goal?';

  @override
  String get qGoalSubtitle => 'We\'ll shape your plan around it.';

  @override
  String get goalLoseWeight => 'Lose weight';

  @override
  String get goalLoseWeightDesc => 'With a healthy, controlled calorie deficit';

  @override
  String get goalMaintainWeight => 'Maintain weight';

  @override
  String get goalMaintainWeightDesc => 'Stay balanced at your current weight';

  @override
  String get goalGainWeight => 'Gain weight';

  @override
  String get goalGainWeightDesc => 'Gradually and healthily';

  @override
  String get goalBuildMuscle => 'Build muscle';

  @override
  String get goalBuildMuscleDesc => 'High protein, modest calorie surplus';

  @override
  String get goalEatHealthier => 'Eat healthier';

  @override
  String get goalEatHealthierDesc => 'Focused on quality, variety and balance';

  @override
  String get qGenderTitle => 'What\'s your sex?';

  @override
  String get qGenderSubtitle => 'Used to calculate your basal metabolic rate.';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get genderUnspecified => 'Prefer not to say';

  @override
  String get genderUnspecifiedDesc => 'The average of both values is used';

  @override
  String get qAgeTitle => 'How old are you?';

  @override
  String get qAgeSubtitle => 'Age affects your daily energy needs.';

  @override
  String get unitYears => 'years';

  @override
  String get qHeightTitle => 'How tall are you?';

  @override
  String get qHeightSubtitle => 'Enter in centimetres.';

  @override
  String get unitCm => 'cm';

  @override
  String get qWeightTitle => 'What\'s your current weight?';

  @override
  String get qWeightSubtitle =>
      'A morning reading before breakfast is most accurate.';

  @override
  String get unitKg => 'kg';

  @override
  String get qTargetWeightTitle => 'What\'s your target weight?';

  @override
  String get qTargetWeightSubtitle => 'A realistic target keeps you motivated.';

  @override
  String targetWeightCurrent(String weight) {
    return 'Current weight: $weight kg';
  }

  @override
  String targetWeightDiff(String diff) {
    return 'Difference: $diff kg';
  }

  @override
  String targetWeightHealthyMin(String weight) {
    return 'Healthy minimum for your height: $weight kg';
  }

  @override
  String inputRangeHint(String min, String max, String unit) {
    return '$min–$max $unit';
  }

  @override
  String get qActivityTitle => 'How active are you day to day?';

  @override
  String get qActivitySubtitle =>
      'Think about your job and general daily movement.';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activitySedentaryDesc => 'Desk job, very little walking';

  @override
  String get activityLight => 'Lightly active';

  @override
  String get activityLightDesc => 'Light movement, some walking';

  @override
  String get activityModerate => 'Moderately active';

  @override
  String get activityModerateDesc => 'On your feet or moving regularly';

  @override
  String get activityActive => 'Very active';

  @override
  String get activityActiveDesc => 'Physical job or lots of daily movement';

  @override
  String get activityVeryActive => 'Extremely active';

  @override
  String get activityVeryActiveDesc =>
      'Heavy physical work or twice-daily training';

  @override
  String get qExerciseTitle => 'How often do you exercise?';

  @override
  String get qExerciseSubtitle =>
      'Planned exercise such as walking, gym, running or swimming.';

  @override
  String get exerciseNone => 'Never or rarely';

  @override
  String get exerciseOneToTwo => '1–2 days a week';

  @override
  String get exerciseThreeToFour => '3–4 days a week';

  @override
  String get exerciseFiveToSix => '5–6 days a week';

  @override
  String get exerciseDaily => 'Every day';

  @override
  String get qDietTitle => 'What\'s your eating style?';

  @override
  String get qDietSubtitle => 'Our suggestions will respect it.';

  @override
  String get dietOmnivore => 'I eat everything';

  @override
  String get dietOmnivoreDesc => 'Meat, fish, dairy and plant foods';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegetarianDesc => 'No meat or fish; eggs and dairy are fine';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietVeganDesc => 'No animal products';

  @override
  String get dietPescatarian => 'Pescatarian';

  @override
  String get dietPescatarianDesc => 'No meat; fish and seafood are fine';

  @override
  String get qAllergiesTitle => 'Any allergies or intolerances?';

  @override
  String get qAllergiesSubtitle =>
      'Select all that apply. We\'ll leave them out of suggestions.';

  @override
  String get allergyNone => 'None';

  @override
  String get allergenGluten => 'Gluten';

  @override
  String get allergenLactose => 'Lactose';

  @override
  String get allergenMilk => 'Milk protein';

  @override
  String get allergenEgg => 'Egg';

  @override
  String get allergenPeanut => 'Peanut';

  @override
  String get allergenTreeNuts => 'Tree nuts';

  @override
  String get allergenSoy => 'Soy';

  @override
  String get allergenFish => 'Fish';

  @override
  String get allergenShellfish => 'Shellfish';

  @override
  String get allergenSesame => 'Sesame';

  @override
  String get allergyOtherHint => 'Add another allergy';

  @override
  String get qDislikedTitle => 'Any foods you dislike?';

  @override
  String get qDislikedSubtitle =>
      'Pick or type your own. You can leave this empty.';

  @override
  String get dislikedHint => 'e.g. okra';

  @override
  String get foodOnion => 'Onion';

  @override
  String get foodGarlic => 'Garlic';

  @override
  String get foodMushroom => 'Mushroom';

  @override
  String get foodEggplant => 'Eggplant';

  @override
  String get foodOffal => 'Offal';

  @override
  String get foodSeafood => 'Seafood';

  @override
  String get foodOlive => 'Olives';

  @override
  String get foodSpicy => 'Spicy food';

  @override
  String get foodBroccoli => 'Broccoli';

  @override
  String get foodLegumes => 'Legumes';

  @override
  String get foodCoriander => 'Coriander';

  @override
  String get foodCelery => 'Celery';

  @override
  String get qMealsTitle => 'How many meals a day do you prefer?';

  @override
  String get qMealsSubtitle => 'Your calorie target will be split across them.';

  @override
  String mealsCount(int count) {
    return '$count meals';
  }

  @override
  String get meals2Desc => 'Two filling main meals';

  @override
  String get meals3Desc => 'Breakfast, lunch and dinner';

  @override
  String get meals4Desc => '3 main meals + 1 snack';

  @override
  String get meals5Desc => '3 main meals + 2 snacks';

  @override
  String get qBreakfastTitle => 'What are your breakfast habits?';

  @override
  String get qBreakfastSubtitle => 'We\'ll arrange your meals accordingly.';

  @override
  String get breakfastAlways => 'I have breakfast every day';

  @override
  String get breakfastSometimes => 'Sometimes';

  @override
  String get breakfastNever => 'I usually skip breakfast';

  @override
  String get qWaterTitle => 'Your daily water goal?';

  @override
  String get qWaterSubtitle =>
      'We suggested an amount based on your weight and activity; adjust it as you like.';

  @override
  String waterLiters(String liters) {
    return '$liters L';
  }

  @override
  String waterRecommended(String liters) {
    return 'Recommended: $liters L';
  }

  @override
  String get waterUseRecommended => 'Use recommendation';

  @override
  String waterGlasses(int count) {
    return 'About $count glasses';
  }

  @override
  String get qFastingTitle => 'Would you like to try intermittent fasting?';

  @override
  String get qFastingSubtitle =>
      'Completely optional; you can change it anytime.';

  @override
  String get fastingNone => 'No thanks';

  @override
  String get fastingNoneDesc => 'I\'ll keep my usual meal pattern';

  @override
  String fastingWindow(int fast, int eat) {
    return '$fast:$eat';
  }

  @override
  String fastingWindowDesc(int fast, int eat) {
    return '$fast h fasting, $eat h eating window';
  }

  @override
  String get fastingCautionNote =>
      'If you are pregnant, breastfeeding, have diabetes, a history of eating disorders or take regular medication, talk to your doctor before starting intermittent fasting.';

  @override
  String get qTargetDateTitle => 'When would you like to reach your goal?';

  @override
  String get qTargetDateSubtitle => 'A safe pace means lasting results.';

  @override
  String get targetDateRecommended => 'Recommended safe pace';

  @override
  String targetDateRecommendedDesc(String date) {
    return 'Estimated $date';
  }

  @override
  String get targetDateCustom => 'I\'ll choose my own date';

  @override
  String get targetDateCustomPick => 'Pick from calendar';

  @override
  String targetDateTooSoon(String required, String max) {
    return 'This date requires $required kg per week. The safe limit is $max kg, so your plan will follow a safe pace.';
  }

  @override
  String get errorSelectOption => 'Choose an option to continue.';

  @override
  String get errorValueRequired => 'Please enter a value.';

  @override
  String errorOutOfRange(String min, String max) {
    return 'Enter a value between $min and $max.';
  }

  @override
  String get errorTargetBelowCurrent =>
      'To lose weight, your target must be below your current weight.';

  @override
  String get errorTargetAboveCurrent =>
      'For this goal, your target must be above your current weight.';

  @override
  String errorTargetBelowHealthy(String min) {
    return 'This is below the healthy range for your height. It should be at least $min kg.';
  }

  @override
  String get errorTargetDatePast => 'The target date must be after today.';

  @override
  String get summaryTitle => 'Your plan is ready';

  @override
  String summaryTitleNamed(String name) {
    return '$name, your plan is ready';
  }

  @override
  String get summarySubtitle =>
      'Here are the daily targets we calculated from your answers:';

  @override
  String get summaryDailyTarget => 'Recommended daily calories';

  @override
  String get summaryKcalPerDay => 'kcal / day';

  @override
  String summaryMaintenance(String kcal) {
    return 'Estimated daily need: $kcal kcal';
  }

  @override
  String summaryDeficit(String kcal) {
    return '$kcal kcal deficit';
  }

  @override
  String summarySurplus(String kcal) {
    return '$kcal kcal surplus';
  }

  @override
  String get summaryBalanced => 'Energy balance';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String gramsValue(String value) {
    return '$value g';
  }

  @override
  String get summaryWater => 'Water goal';

  @override
  String get summaryGoalDuration => 'Estimated time to goal';

  @override
  String summaryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '~$count weeks',
      one: '~1 week',
    );
    return '$_temp0';
  }

  @override
  String summaryGoalDate(String date) {
    return 'Estimated $date';
  }

  @override
  String summaryWeeklyRate(String kg) {
    return 'About $kg kg per week';
  }

  @override
  String get summaryNoDurationMaintain =>
      'Your goal is to maintain your weight; there\'s no end date.';

  @override
  String get summaryNoDurationSlow =>
      'Because of the safe calorie floor, weight change will be very slow. Moving more each day will speed things up.';

  @override
  String summaryMetrics(String bmr, String bmi) {
    return 'Basal metabolism $bmr kcal · BMI $bmi';
  }

  @override
  String get summaryFormulaNote =>
      'Calculated with the Mifflin-St Jeor equation and an activity factor.';

  @override
  String get noticeTitle => 'Things to keep in mind';

  @override
  String get noticeMinor =>
      'You are under 18. Calorie restriction isn\'t recommended while growing, so your target was limited. Please talk to a doctor or dietitian.';

  @override
  String get noticeSenior =>
      'At 65 and over, enough protein matters for preserving muscle. Planning with a professional is recommended.';

  @override
  String get noticeUnderweight =>
      'Your BMI is below the healthy range. Losing weight isn\'t recommended; please consult a healthcare professional.';

  @override
  String get noticeSevereObesity =>
      'Your BMI is high. Following a doctor or dietitian is the safest way to progress.';

  @override
  String get noticePaceAdjusted =>
      'The pace needed for your chosen date is above the safe limit, so your plan was adjusted to a healthier pace.';

  @override
  String get noticeCalorieFloor =>
      'Your calorie target was set so it never drops below a safe minimum.';

  @override
  String get noticeFasting =>
      'Intermittent fasting needs extra care for your profile. Talk to your doctor before starting.';

  @override
  String get disclaimerTitle => 'Please note';

  @override
  String get disclaimerBody =>
      'This app provides general information and does not replace advice from a doctor or dietitian. If you are pregnant, breastfeeding, have a chronic condition (diabetes, kidney, heart disease, etc.), a history of eating disorders or take regular medication, create your nutrition plan together with a healthcare professional.';

  @override
  String get foodAddTitle => 'Add food';

  @override
  String get foodSearchHint => 'Search foods, dishes or products...';

  @override
  String get foodClearSearch => 'Clear search';

  @override
  String get foodTabRecent => 'Recent';

  @override
  String get foodTabFavorites => 'Favorites';

  @override
  String get foodTabMine => 'My foods';

  @override
  String get foodRecentEmpty =>
      'Foods you log will show up here so you can add them again with one tap.';

  @override
  String get foodFavoritesEmpty =>
      'Tap the heart on a food\'s details to add it to your favorites.';

  @override
  String get foodMineEmpty => 'Create your own foods and recipes.';

  @override
  String get foodDatabaseUnavailable =>
      'The food database is unavailable right now.';

  @override
  String get foodDatabaseUnavailableHint =>
      'You can still use recents, favorites and foods you created. Try again when you\'re back online, or add a custom food.';

  @override
  String get foodAttributionOff =>
      'Packaged product data from Open Food Facts contributors (ODbL).';

  @override
  String get foodAttributionOffLink => 'Open Food Facts';

  @override
  String get foodAttributionOffLicense =>
      'Open Food Facts data is used under the ODbL.';

  @override
  String get foodCategoryFruit => 'Fruit';

  @override
  String get foodCategoryVegetable => 'Vegetables';

  @override
  String get foodCategoryProtein => 'Protein';

  @override
  String get foodCategoryDairy => 'Dairy';

  @override
  String get foodCategoryGrain => 'Grains';

  @override
  String get foodCategoryBeverage => 'Drinks';

  @override
  String foodNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get foodNoResultsHint =>
      'Try a different spelling or create your own food.';

  @override
  String get foodCreateCustom => 'Create food';

  @override
  String get foodCreateRecipe => 'Create recipe';

  @override
  String foodSampleDataNotice(String source) {
    return 'Sample data: Nutrition values are rounded from $source records and may differ by product or recipe.';
  }

  @override
  String get foodSampleBadge => 'Sample data';

  @override
  String get foodCustomBadge => 'My food';

  @override
  String get foodRecipeBadge => 'Recipe';

  @override
  String foodQuickAdd(String food) {
    return 'Add $food';
  }

  @override
  String foodAddedTo(String food, String meal) {
    return '$food added to $meal';
  }

  @override
  String get foodMeal => 'Meal';

  @override
  String get foodAmount => 'Amount';

  @override
  String get foodUnit => 'Unit';

  @override
  String get foodNutrition => 'Nutrition facts';

  @override
  String foodPer100(String unit, String kcal) {
    return '$kcal kcal per 100 $unit';
  }

  @override
  String foodAddToMeal(String meal) {
    return 'Add to $meal';
  }

  @override
  String get foodFavoriteAdd => 'Add to favorites';

  @override
  String get foodFavoriteRemove => 'Remove from favorites';

  @override
  String get foodIngredients => 'Ingredients';

  @override
  String foodSource(String source) {
    return 'Source: $source';
  }

  @override
  String get foodNotFound => 'Food not found.';

  @override
  String get foodInvalidAmount => 'Enter a valid amount.';

  @override
  String get foodDelete => 'Delete';

  @override
  String foodDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get nutrientCalories => 'Calories';

  @override
  String get nutrientFiber => 'Fiber';

  @override
  String get nutrientSugar => 'Sugar';

  @override
  String get nutrientSaturatedFat => 'Saturated fat';

  @override
  String get nutrientSodium => 'Sodium';

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
      other: 'pieces',
      one: 'piece',
    );
    return '$_temp0';
  }

  @override
  String unitSlice(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'slices',
      one: 'slice',
    );
    return '$_temp0';
  }

  @override
  String unitServing(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'servings',
      one: 'serving',
    );
    return '$_temp0';
  }

  @override
  String unitBowl(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bowls',
      one: 'bowl',
    );
    return '$_temp0';
  }

  @override
  String unitGlass(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'glasses',
      one: 'glass',
    );
    return '$_temp0';
  }

  @override
  String unitTablespoon(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tbsp',
    );
    return '$_temp0';
  }

  @override
  String unitTeaspoon(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tsp',
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
  String get customFoodTitle => 'Create food';

  @override
  String get customFoodName => 'Name';

  @override
  String get customFoodNameHint => 'e.g. Homemade granola';

  @override
  String get customFoodBrand => 'Brand (optional)';

  @override
  String get customFoodBarcode => 'Barcode';

  @override
  String get customFoodPortion => 'Serving';

  @override
  String get customFoodPortionAmount => 'Serving size';

  @override
  String get customFoodPortionUnit => 'Serving type';

  @override
  String get customFoodValuesTitle => 'Nutrition per serving';

  @override
  String get customFoodValuesHint =>
      'Enter values from the product label or another reliable source.';

  @override
  String get customFoodCalories => 'Calories (kcal)';

  @override
  String get customFoodProtein => 'Protein (g)';

  @override
  String get customFoodCarbs => 'Carbohydrates (g)';

  @override
  String get customFoodFat => 'Fat (g)';

  @override
  String get customFoodFiber => 'Fiber (g, optional)';

  @override
  String get customFoodSugar => 'Sugar (g, optional)';

  @override
  String get customFoodSodium => 'Sodium (mg, optional)';

  @override
  String customFoodSaved(String name) {
    return '$name saved';
  }

  @override
  String customFoodEnergyMismatch(String kcal) {
    return 'Energy calculated from macros is about $kcal kcal, which doesn\'t match the calories you entered. Please double-check.';
  }

  @override
  String get errorPositiveNumber => 'Enter a value greater than 0.';

  @override
  String get errorNonNegativeNumber => 'Enter a valid value.';

  @override
  String get recipeBuilderTitle => 'Create recipe';

  @override
  String get recipeName => 'Recipe name';

  @override
  String get recipeNameHint => 'e.g. Menemen';

  @override
  String get recipeServings => 'Number of servings';

  @override
  String get recipeAddIngredient => 'Add ingredient';

  @override
  String get recipeNoIngredients =>
      'No ingredients yet. Nutrition is calculated automatically from the ingredients.';

  @override
  String get recipeTotal => 'Whole recipe';

  @override
  String get recipePerServing => '1 serving';

  @override
  String recipeTotalWeight(String value) {
    return 'Total weight: $value g';
  }

  @override
  String get recipeWeightNote =>
      'Values are calculated from ingredient amounts before cooking.';

  @override
  String get recipeNeedsIngredient => 'Add at least one ingredient.';

  @override
  String recipeSaved(String name) {
    return '$name recipe saved';
  }

  @override
  String get foodPickerTitle => 'Choose ingredient';

  @override
  String get barcodeManualTitle => 'Search by barcode number';

  @override
  String get barcodeManualHint => 'Barcode number';

  @override
  String get barcodeCameraUnavailable =>
      'Camera scanning is not available on this device. You can type the product\'s barcode number.';

  @override
  String get barcodeSearch => 'Find product';

  @override
  String get barcodeNotFound =>
      'No product with this barcode was found in the Open Food Facts catalog.';

  @override
  String barcodeIncompleteCatalog(String barcode) {
    return 'Barcode $barcode is in the Open Food Facts catalog, but the product name or nutrition data is missing. You can create a custom food.';
  }

  @override
  String barcodeDemoHint(String codes) {
    return 'Sample data barcodes: $codes';
  }

  @override
  String get barcodeAlignHint => 'Align the barcode inside the frame';

  @override
  String get barcodeEnterManually => 'Enter barcode manually';

  @override
  String get barcodeScanAgain => 'Scan again';

  @override
  String get barcodeSearching => 'Looking up product';

  @override
  String get barcodeCameraPermissionTitle => 'Camera permission required';

  @override
  String get barcodeCameraPermissionMessage =>
      'Camera access is needed to scan barcodes. You can enable it in Settings or type the barcode instead.';

  @override
  String get barcodeOpenSettings => 'Open settings';

  @override
  String get barcodeScanAreaLabel => 'Barcode scan area';

  @override
  String get errorPermission =>
      'This action needs your permission. You can enable it in your device settings.';

  @override
  String progressRange(String range) {
    String _temp0 = intl.Intl.selectLogic(range, {
      'week': '7 days',
      'month': '30 days',
      'quarter': '90 days',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get progressAddWeight => 'Add weight';

  @override
  String get progressAddMeasurement => 'Add measurements';

  @override
  String get progressAddPhoto => 'Add photo';

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
    return '$value%';
  }

  @override
  String get progressGoalTitle => 'Weight goal';

  @override
  String get progressStartWeight => 'Start';

  @override
  String get progressCurrentWeight => 'Current';

  @override
  String get progressTargetWeight => 'Target';

  @override
  String get progressLostWeight => 'Lost';

  @override
  String get progressGainedWeight => 'Gained';

  @override
  String get progressRemainingWeight => 'To go';

  @override
  String progressGoalPercent(String percent) {
    return '$percent% of your goal completed';
  }

  @override
  String get progressGoalReached =>
      'You reached your target weight, congratulations!';

  @override
  String get progressNoTarget =>
      'No target weight set. You can add one in your profile.';

  @override
  String get progressNoWeightTitle => 'No weight entries yet';

  @override
  String get progressNoWeightMessage =>
      'Add your first weight to start tracking your progress.';

  @override
  String get progressChartTitle => 'Weight chart';

  @override
  String get progressChartNeedsMore =>
      'The chart needs at least two weight entries in this period.';

  @override
  String progressChartTarget(String value) {
    return 'Target $value';
  }

  @override
  String progressChartSemantics(
    String from,
    String to,
    int count,
    String min,
    String max,
  ) {
    return 'Weight chart: $count entries from $from to $to, lowest $min, highest $max';
  }

  @override
  String get progressWeightHistory => 'Weight entries';

  @override
  String get progressEntryDeleted => 'Entry deleted';

  @override
  String get progressWeeklyTitle => 'Weekly average';

  @override
  String get progressWeeklyWeight => 'Average weight';

  @override
  String get progressWeeklyCalories => 'Average calories';

  @override
  String get progressWeeklyScore => 'Average score';

  @override
  String progressWeeklyVsLast(String change) {
    return '$change kg vs last week';
  }

  @override
  String progressWeeklyKcal(String value) {
    return '$value kcal/day';
  }

  @override
  String get progressNoValue => '—';

  @override
  String get progressWaistTitle => 'Waist';

  @override
  String get progressMeasurementsTitle => 'Body measurements';

  @override
  String get progressNoMeasurements =>
      'No measurements yet. Track your waist, hips and more to see changes the scale doesn\'t show.';

  @override
  String progressLastMeasured(String date) {
    return 'Last measured: $date';
  }

  @override
  String progressSinceStart(String change) {
    return '$change since start';
  }

  @override
  String get measureWaist => 'Waist';

  @override
  String get measureHip => 'Hips';

  @override
  String get measureChest => 'Chest';

  @override
  String get measureNeck => 'Neck';

  @override
  String get measureArm => 'Arm';

  @override
  String get measureThigh => 'Thigh';

  @override
  String get measureBodyFat => 'Body fat';

  @override
  String get progressPhotosTitle => 'Progress photos';

  @override
  String get progressPhotosEmpty =>
      'Taking regular photos in the same light and pose is one of the best ways to see change.';

  @override
  String get progressPhotoCamera => 'Take photo';

  @override
  String get progressPhotoGallery => 'Choose from gallery';

  @override
  String get progressPhotoFirst => 'First';

  @override
  String get progressPhotoLatest => 'Latest';

  @override
  String get progressPhotoAdded => 'Photo added';

  @override
  String get progressPhotoDelete => 'Delete photo';

  @override
  String get progressPhotoDeleteConfirm => 'Permanently delete this photo?';

  @override
  String get progressPhotoDeleted => 'Photo deleted';

  @override
  String get progressPhotoUnavailable => 'Couldn\'t load photo';

  @override
  String get actionDelete => 'Delete';

  @override
  String get progressAdherenceTitle => 'Goal adherence';

  @override
  String get progressAdherenceCalories => 'Calorie adherence';

  @override
  String get progressAdherenceProtein => 'Protein adherence';

  @override
  String get progressAdherenceWater => 'Water adherence';

  @override
  String progressAdherenceDays(int hit, int total) {
    return '$hit / $total days';
  }

  @override
  String get progressAdherenceNoData => 'No entries in this period';

  @override
  String get progressAdherenceNote =>
      'Calculated from completed days with entries; today is not included. Calories: within ±10% of target, protein: at least 90% of target, water: daily water goal.';

  @override
  String get progressScoreTitle => 'Daily score history';

  @override
  String progressScoreAverage(String value) {
    return 'Average $value';
  }

  @override
  String get progressScoreEmpty => 'No entries to score in this period.';

  @override
  String get progressToday => 'Today';

  @override
  String get progressNotLogged => 'No entries';

  @override
  String progressDaySummary(String kcal, String protein, String water) {
    return '$kcal kcal · $protein g protein · $water L water';
  }

  @override
  String get progressWeightSheetTitle => 'Add weight';

  @override
  String get progressWeightField => 'Weight';

  @override
  String get progressDateField => 'Date';

  @override
  String progressWeightSaved(String value) {
    return '$value kg saved';
  }

  @override
  String get progressMeasurementSheetTitle => 'Add measurements';

  @override
  String get progressMeasurementHint =>
      'Fill in the ones you want to track; empty fields aren\'t saved. Measure at the same spot each time.';

  @override
  String get progressMeasurementNeedsValue => 'Enter at least one measurement.';

  @override
  String get progressMeasurementSaved => 'Measurements saved';

  @override
  String get errorPurchase =>
      'The purchase couldn\'t be completed. You weren\'t charged; please try again.';

  @override
  String get errorPurchaseUnavailable =>
      'Purchases are not available right now.';

  @override
  String get errorPremiumRequired => 'This feature is for Premium members.';

  @override
  String get appFeatureCalorieTracking => 'Calorie tracking';

  @override
  String get appFeatureWeightTracking => 'Weight tracking';

  @override
  String get appFeatureWaterTracking => 'Water tracking';

  @override
  String get appFeatureFoodLogging => 'Food logging';

  @override
  String get appFeatureBasicProgress => 'Basic progress';

  @override
  String get appFeaturePersonalMealPlan => 'Personal meal plan';

  @override
  String get appFeaturePersonalMealPlanDesc =>
      'A daily plan built around your goal and taste.';

  @override
  String get appFeatureAiCoach => 'AI nutrition coach';

  @override
  String get appFeatureAiCoachDesc => 'Instant answers tailored to you.';

  @override
  String get appFeaturePhotoFoodAnalysis => 'Photo food analysis';

  @override
  String get appFeaturePhotoFoodAnalysisDesc =>
      'Snap your plate and get its calories.';

  @override
  String get appFeatureAdvancedAnalytics => 'Advanced analytics';

  @override
  String get appFeatureAdvancedAnalyticsDesc =>
      'See how well you hit calorie, protein and water targets.';

  @override
  String get appFeatureAdvancedRecipes => 'Advanced recipes';

  @override
  String get appFeatureAdvancedRecipesDesc =>
      'An exclusive recipe collection for your goal.';

  @override
  String get appFeatureAutoShoppingList => 'Automatic shopping list';

  @override
  String get appFeatureAutoShoppingListDesc =>
      'Every ingredient in your plan, in one list.';

  @override
  String get appFeatureAdvancedGoals => 'Advanced goals';

  @override
  String get appFeatureAdvancedGoalsDesc => 'Customize macro and meal targets.';

  @override
  String get appFeatureAdvancedReports => 'Advanced reports';

  @override
  String get appFeatureAdvancedReportsDesc =>
      'Nutrition score history and detailed reports.';

  @override
  String get appFeatureAdFree => 'Ad-free experience';

  @override
  String get appFeatureAdFreeDesc => 'Stay focused without any ads.';

  @override
  String get appFeatureFasting => 'Intermittent fasting';

  @override
  String get appFeatureFastingDesc => 'Fasting plans like 16:8 with a timer.';

  @override
  String get appFeaturePeriodicReports => 'Weekly and monthly reports';

  @override
  String get appFeaturePeriodicReportsDesc =>
      'Weekly averages and period comparisons.';

  @override
  String premiumLockedTitle(String feature) {
    return '$feature is a Premium feature';
  }

  @override
  String get premiumUnlockAction => 'Go Premium';

  @override
  String get premiumProfileSubtitle => 'Unlock every feature';

  @override
  String get paywallTitle => 'Reach your goal faster with Premium';

  @override
  String get paywallSubtitle =>
      'Your personal plan, AI coach and advanced reports in one subscription.';

  @override
  String get paywallPeriodWeekly => 'Weekly';

  @override
  String get paywallPeriodMonthly => 'Monthly';

  @override
  String get paywallPeriodAnnual => 'Yearly';

  @override
  String get paywallPeriodLifetime => 'Lifetime';

  @override
  String paywallSavings(int percent) {
    return 'Save $percent%';
  }

  @override
  String paywallPerMonth(String price) {
    return '$price / month';
  }

  @override
  String get paywallSubscribe => 'Subscribe';

  @override
  String paywallStartTrial(int days) {
    return 'Try $days days free';
  }

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallLegal =>
      'Your subscription renews automatically unless cancelled at least 24 hours before the end of the period. You can cancel anytime in your store account settings.';

  @override
  String paywallTrialLegal(int days, String price) {
    return 'After the $days-day free trial you\'ll be charged $price. Cancel at least 24 hours before the trial ends and you won\'t be charged.';
  }

  @override
  String get paywallPurchaseSuccess => 'Welcome to Premium!';

  @override
  String get paywallRestored => 'Your Premium membership was restored.';

  @override
  String get paywallNothingToRestore => 'No purchases found to restore.';

  @override
  String get paywallActiveTitle => 'Premium is active';

  @override
  String paywallTrialUntil(String date) {
    return 'Free trial until $date';
  }

  @override
  String paywallRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String paywallActiveUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsResetFakeSubscription => 'Reset test subscription';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicyUnavailable =>
      'Privacy Policy is unavailable right now.';

  @override
  String get scoreFactorMacroBalance => 'Macro balance';

  @override
  String get scoreTipMacroBalance =>
      'Try to split protein, carbs and fat close to your targets.';

  @override
  String get diaryToday => 'Today';

  @override
  String get diaryYesterday => 'Yesterday';

  @override
  String get diaryTomorrow => 'Tomorrow';

  @override
  String get diaryPreviousDay => 'Previous day';

  @override
  String get diaryNextDay => 'Next day';

  @override
  String get diaryPickDate => 'Pick a date';

  @override
  String diaryCaloriesLeft(String kcal) {
    return '$kcal kcal left';
  }

  @override
  String diaryCaloriesOver(String kcal) {
    return '$kcal kcal over your target';
  }

  @override
  String diaryCaloriesOfTarget(String target) {
    return '/ $target kcal';
  }

  @override
  String diaryMealEmptyHint(String meal) {
    String _temp0 = intl.Intl.selectLogic(meal, {
      'breakfast': 'Let\'s start planning your breakfast 🌱',
      'lunch': 'How about adding your lunch?',
      'dinner': 'Your dinner is still empty.',
      'snack': 'Add your snacks for the day here.',
      'other': 'No food added yet.',
    });
    return '$_temp0';
  }

  @override
  String get diaryExpand => 'Expand';

  @override
  String get diaryCollapse => 'Collapse';

  @override
  String get diaryEntryMenu => 'Food options';

  @override
  String get diaryEntryEdit => 'Edit';

  @override
  String get diaryEntryCopy => 'Copy';

  @override
  String get diaryEntryMove => 'Move to another meal';

  @override
  String get diaryEditTitle => 'Edit entry';

  @override
  String get diaryEditAmount => 'Amount';

  @override
  String get diaryEditDecrease => 'Decrease';

  @override
  String get diaryEditIncrease => 'Increase';

  @override
  String diaryEntryUpdated(String food) {
    return '$food updated';
  }

  @override
  String diaryEntryCopied(String food, String date) {
    return '$food copied to $date';
  }

  @override
  String diaryEntryMoved(String food, String meal) {
    return '$food moved to $meal';
  }

  @override
  String diaryFavoriteAdded(String food) {
    return '$food added to favorites';
  }

  @override
  String diaryFavoriteRemoved(String food) {
    return '$food removed from favorites';
  }

  @override
  String diaryEntryDeleted(String food) {
    return '$food deleted';
  }

  @override
  String get diaryDeleteTitle => 'Delete food';

  @override
  String get diaryDeleteMessage =>
      'Are you sure you want to delete this food from your diary?';

  @override
  String get diaryMoveTitle => 'Move to which meal?';

  @override
  String get diaryCopyTitle => 'Copy to where?';

  @override
  String get diaryCopyToday => 'Copy to today';

  @override
  String get diaryCopyTomorrow => 'Copy to tomorrow';

  @override
  String get diaryWaterTitle => 'Water';

  @override
  String diaryWaterOfGoal(String value, String goal) {
    return '$value / $goal ml';
  }

  @override
  String diaryWaterRemove(int ml) {
    return 'Remove $ml ml';
  }

  @override
  String diaryMlValue(int ml) {
    return '$ml ml';
  }

  @override
  String diaryWaterRemoved(int ml) {
    return '$ml ml water removed';
  }

  @override
  String diaryScoreTitle(String when) {
    String _temp0 = intl.Intl.selectLogic(when, {
      'past': 'Day\'s Nutrition Score',
      'future': 'Planned Nutrition Score',
      'other': 'Today\'s Nutrition Score',
    });
    return '$_temp0';
  }

  @override
  String get diaryScoreDisclaimer =>
      'This score is an estimated indicator that helps you track general eating habits.';

  @override
  String diaryScoreStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'met': 'on target',
      'partial': 'can improve',
      'other': 'missing',
    });
    return '$_temp0';
  }

  @override
  String get diaryQuickAddTitle => 'What would you like to add?';

  @override
  String get diaryAddWater => 'Add water';

  @override
  String get diaryAddWeight => 'Add weight';

  @override
  String get diaryAddActivity => 'Add activity';

  @override
  String diaryEmptyDayTitle(String when) {
    String _temp0 = intl.Intl.selectLogic(when, {
      'past': 'No entries for this day.',
      'future': 'You can plan this day ahead.',
      'other': 'You haven\'t added a meal today yet.',
    });
    return '$_temp0';
  }

  @override
  String get diaryEmptyDayMessage =>
      'As you add meals, your calories, macros and nutrition score update here.';

  @override
  String get diaryPastDayNote =>
      'You\'re viewing a past day; changes are saved to this day.';

  @override
  String get diaryFutureDayNote =>
      'A future date is selected; meals you add are saved as a plan for this day.';

  @override
  String get diaryActivityTitleToday => 'Today\'s activity';

  @override
  String get diaryWeightTitle => 'Weight';

  @override
  String get diaryWeightEmpty => 'No weight entry for this day.';

  @override
  String diaryWeightValue(String value) {
    return '$value kg';
  }

  @override
  String get activityConnectTitle => 'Connect health data';

  @override
  String get activityConnectMessage =>
      'When Apple Health or Health Connect is connected, steps, distance and active calories stay in this device\'s journal and are not written to Firebase. If you ask the assistant about activity or your day, that summary is sent with the question.';

  @override
  String get activityConnectAction => 'Connect';

  @override
  String get activityConnectGranted => 'Health data connected.';

  @override
  String get activityConnectUnavailable =>
      'Health data connection isn\'t available on this device yet.';

  @override
  String get healthDataTitle => 'Health data';

  @override
  String get healthConnectName => 'Health Connect';

  @override
  String get healthAppleName => 'Apple Health';

  @override
  String get healthStatusLinked => 'Connected';

  @override
  String get healthStatusNotLinked => 'Not connected';

  @override
  String get healthUnavailableBody =>
      'This feature isn\'t available on this device.';

  @override
  String get healthPermissionDenied =>
      'Health data isn\'t connected. You can try again from Settings.';

  @override
  String get healthPrivacyNote =>
      'Steps, distance and active calories stay on this device and are not written to Firebase. If you ask the assistant about activity or your day, that summary is sent with the question.';

  @override
  String get healthConnectAction => 'Connect health data';

  @override
  String get healthValueUnavailable => '—';

  @override
  String get activityDistance => 'Distance';

  @override
  String activityDistanceKm(String value) {
    return '$value km';
  }

  @override
  String activityDistanceMeters(String value) {
    return '$value m';
  }

  @override
  String get progressActivityTitle => 'Movement';

  @override
  String get progressActivityToday => 'Steps today';

  @override
  String get progressActivityWeek => 'Steps, last 7 days';

  @override
  String get weightNoteField => 'Note (optional)';

  @override
  String get weightNoteHint => 'e.g. Morning, before breakfast';

  @override
  String get weightAdd => 'Add weight';

  @override
  String get weightAddFirst => 'Add my first weight';

  @override
  String get weightEmptyTitle => 'You haven\'t logged your weight yet.';

  @override
  String get weightEmptyMessage =>
      'As you log your weight regularly, your progress, chart and remaining weight show up here.';

  @override
  String get weightJourneyTitle => 'Your weight journey';

  @override
  String get weightStatRemaining => 'To goal';

  @override
  String get weightStatPercent => 'Change since start';

  @override
  String get weightStatLast => 'Last entry';

  @override
  String get weightStatWeekly => 'Weekly average';

  @override
  String weightPerWeek(String value) {
    return '$value kg/week';
  }

  @override
  String weightRange(String range) {
    String _temp0 = intl.Intl.selectLogic(range, {
      'week': '7 days',
      'month': '30 days',
      'quarter': '3 months',
      'other': 'All',
    });
    return '$_temp0';
  }

  @override
  String get weightHistoryTitle => 'History';

  @override
  String get weightHistoryEmpty => 'Your weight entries are listed here.';

  @override
  String weightDeltaPrevious(String change) {
    return '$change kg vs previous';
  }

  @override
  String get targetSuggestionTitle => 'You can update your targets';

  @override
  String targetSuggestionBody(String current, String suggested) {
    return 'Based on your current details, we suggest $suggested kcal per day instead of $current.';
  }

  @override
  String targetSuggestionBodyNew(String suggested) {
    return 'Based on your profile, your daily target is $suggested kcal.';
  }

  @override
  String get targetSuggestionLimited =>
      'Changes are applied gradually: at most 200 kcal at a time.';

  @override
  String get targetSuggestionNote =>
      'This is a general estimate; talk to a professional if you have a health condition.';

  @override
  String get targetSuggestionLater => 'Not now';

  @override
  String get targetSuggestionApply => 'Update target';

  @override
  String get targetSuggestionApplied =>
      'Your daily target was updated. You can refresh your plan for the new target.';

  @override
  String get measureEmptyTitle => 'You haven\'t added body measurements yet.';

  @override
  String get measureEmptyMessage =>
      'Add waist, hip, chest, neck, arm and thigh measurements to track changes beyond the scale.';

  @override
  String get measureAddFirst => 'Add my first measurement';

  @override
  String get measureSeeProgress =>
      'See weight and measurements together in Progress';

  @override
  String get measureSummaryTitle => 'Summary';

  @override
  String get measureStart => 'Start';

  @override
  String get measureLatest => 'Latest';

  @override
  String get measureChange => 'Change';

  @override
  String get measureChartTitle => 'Measurement chart';

  @override
  String measureChartSemantics(String field, String min, String max) {
    return '$field chart; lowest $min, highest $max.';
  }

  @override
  String get measureHistoryTitle => 'Measurement history';

  @override
  String get nutritionPlanTitle => 'My nutrition plan';

  @override
  String nutritionPlanGoal(String goal) {
    return 'Goal: $goal';
  }

  @override
  String get nutritionPlanDailyTarget => 'Daily calorie target';

  @override
  String get nutritionPlanEditGoals => 'Edit goals';

  @override
  String get nutritionPlanPreviousWeek => 'Previous week';

  @override
  String get nutritionPlanNextWeek => 'Next week';

  @override
  String nutritionPlanWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String nutritionPlanEatingWindow(String start, String end) {
    return 'Your eating window is $start–$end; meal times follow it.';
  }

  @override
  String get nutritionPlanToday => 'Today\'s meals';

  @override
  String get nutritionPlanCreate => 'Create new plan';

  @override
  String get nutritionPlanCreated => 'Your new plan is ready.';

  @override
  String get nutritionPlanFromProfile =>
      'Calorie and macro targets come from your profile.';

  @override
  String get nutritionPlanMealsPerDay => 'Meals per day';

  @override
  String get nutritionPlanDietType => 'Diet type';

  @override
  String get nutritionPlanDisliked => 'Foods you dislike';

  @override
  String get nutritionPlanDislikedHint => 'e.g. Broccoli';

  @override
  String get nutritionPlanGenerate => 'Create plan';

  @override
  String get nutritionPlanLogToday => 'Add to today\'s diary';

  @override
  String get nutritionPlanSwap => 'Swap this meal';

  @override
  String get nutritionPlanOpenRecipe => 'View recipe';

  @override
  String get nutritionPlanAlreadyLogged =>
      'This meal is already in today\'s diary.';

  @override
  String nutritionPlanAlternativesTitle(String meal) {
    return 'Alternatives for $meal';
  }

  @override
  String get nutritionPlanAlternativesSubtitle =>
      'Suggestions matching your calorie target, diet, allergies and dislikes.';

  @override
  String servingsCount(String value) {
    return '$value servings';
  }

  @override
  String get recipeCategoryAll => 'All';

  @override
  String get recipeCategoryBreakfast => 'Breakfast';

  @override
  String get recipeCategoryLunch => 'Lunch';

  @override
  String get recipeCategoryDinner => 'Dinner';

  @override
  String get recipeCategorySnack => 'Snack';

  @override
  String get recipeCategoryDessert => 'Dessert';

  @override
  String get recipeCategoryDrink => 'Drink';

  @override
  String get recipeCategoryHighProtein => 'High protein';

  @override
  String get recipeCategoryLowCalorie => 'Low calorie';

  @override
  String get recipeFavorites => 'Favorites';

  @override
  String get recipeFavorite => 'Favorite';

  @override
  String get recipeAddFavorite => 'Add to favorites';

  @override
  String get recipeRemoveFavorite => 'Remove from favorites';

  @override
  String get recipeFavoritesEmptyTitle =>
      'You don\'t have favorite recipes yet.';

  @override
  String get recipeFavoritesEmptyMessage =>
      'Tap the heart on recipes you like to collect them here.';

  @override
  String get recipeSearchHint => 'Search recipes or ingredients';

  @override
  String get recipeNoResults => 'No recipes match your search.';

  @override
  String get recipeClearFilters => 'Clear filters';

  @override
  String get recipeDemoNutrition =>
      'Nutrition is calculated from sample USDA data. This is demo data.';

  @override
  String get recipeVegetarian => 'Vegetarian';

  @override
  String get recipeSalad => 'Salad';

  @override
  String get recipeSoup => 'Soup';

  @override
  String get recipePractical => 'Quick meals';

  @override
  String get recipeRecentTitle => 'Recently viewed';

  @override
  String get recipeRecommendedTitle => 'For you';

  @override
  String get recipeCalorieAny => 'Calories';

  @override
  String recipeCalorieMax(int kcal) {
    return '≤ $kcal kcal';
  }

  @override
  String get recipeSelectedServings => 'Selected servings';

  @override
  String get recipeLoadMore => 'Show more';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get recipeCreate => 'Create recipe';

  @override
  String get recipeLogToday => 'Add to today\'s diary';

  @override
  String get recipeAddToPlan => 'Add to nutrition plan';

  @override
  String get recipePickDay => 'Day';

  @override
  String get recipePickMeal => 'Meal';

  @override
  String get recipeServingsLabel => 'Servings';

  @override
  String get recipeLessServings => 'Fewer servings';

  @override
  String get recipeMoreServings => 'More servings';

  @override
  String recipeLogged(String name, String meal) {
    return '$name added to $meal';
  }

  @override
  String recipeAddedToPlan(String day, String meal) {
    return 'Added to plan: $day, $meal';
  }

  @override
  String get recipeOpenPlan => 'Open plan';

  @override
  String get recipeDeleteTitle => 'Delete recipe?';

  @override
  String recipeDeleteMessage(String name) {
    return '$name will be permanently deleted.';
  }

  @override
  String get recipeDeleted => 'Recipe deleted.';

  @override
  String get recipeNotFound => 'Recipe not found.';

  @override
  String get recipeMine => 'My recipe';

  @override
  String get recipeNutritionPerServing => 'Nutrition per serving';

  @override
  String get recipeIngredients => 'Ingredients';

  @override
  String get recipeNoIngredientList => 'No ingredient list added.';

  @override
  String get recipeSteps => 'Instructions';

  @override
  String get recipeNoSteps => 'No instructions added.';

  @override
  String get recipeDescription => 'Short description (optional)';

  @override
  String get recipeCategories => 'Category';

  @override
  String get recipeComputedCategoriesNote =>
      '\"High protein\" and \"Low calorie\" are set automatically from nutrition values.';

  @override
  String get recipeNeedsCategory => 'Pick at least one category.';

  @override
  String get recipePrepMinutes => 'Prep';

  @override
  String get recipeCookMinutes => 'Cook';

  @override
  String get unitMinutes => 'min';

  @override
  String get recipeIngredientsHint =>
      'One ingredient per line, e.g.\n2 pcs eggs\n150 g cottage cheese';

  @override
  String get recipeStepsHint =>
      'One step per line, e.g.\nWhisk the eggs.\nCook in a pan.';

  @override
  String get fastingEmptyTitle => 'You haven\'t planned a fast today.';

  @override
  String get fastingEmptyMessage =>
      'Pick a protocol above to begin. Your meal times and reminders will follow your eating window.';

  @override
  String get fastingProtocolTitle => 'Protocol';

  @override
  String get fastingProtocolLocked =>
      'Finish the current fast to change the protocol.';

  @override
  String get fastingPhaseFasting => 'Fasting';

  @override
  String get fastingPhaseEating => 'Eating window';

  @override
  String get fastingChangeWindow => 'Change eating window time';

  @override
  String get fastingEatingStartPicker => 'Eating window start';

  @override
  String fastingRemaining(String time) {
    return '$time left to goal';
  }

  @override
  String fastingEatingRemaining(String time) {
    return '$time until your eating window closes';
  }

  @override
  String get fastingTargetReached =>
      'You reached your target. End the fast whenever you\'re ready.';

  @override
  String fastingEndsAt(String time) {
    return 'Target end: $time';
  }

  @override
  String fastingEatingEndsAt(String time) {
    return 'Window closes: $time';
  }

  @override
  String fastingTimerSemantics(String phase, String time) {
    return '$phase: $time';
  }

  @override
  String get fastingPaused => 'Paused';

  @override
  String get fastingStart => 'Start fast';

  @override
  String get fastingPause => 'Pause';

  @override
  String get fastingResume => 'Resume';

  @override
  String get fastingFinish => 'End';

  @override
  String get fastingStarted =>
      'Fast started. Remember to drink plenty of water.';

  @override
  String fastingFinishedCompleted(String duration) {
    return 'Well done! $duration fast completed.';
  }

  @override
  String fastingFinishedEarly(String duration) {
    return 'Fast ended after $duration. Feeling well always comes first.';
  }

  @override
  String fastingHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get fastingWindowMealsTitle => 'Meals in your eating window';

  @override
  String get fastingHistoryTitle => 'Fasting history';

  @override
  String get fastingHistoryEmpty => 'Fasts you finish are listed here.';

  @override
  String get fastingStatCompleted => 'Completed';

  @override
  String get fastingStatAverage => 'Average duration';

  @override
  String get fastingLast7Days => 'Last 7 days';

  @override
  String get fastingCompleted => 'Completed';

  @override
  String get fastingEndedEarly => 'Ended early';

  @override
  String get fastingSessionDeleted => 'Fast deleted.';

  @override
  String get fastingDisclaimer =>
      'Intermittent fasting is not medical advice. If you are pregnant, breastfeeding, have diabetes, a history of eating disorders, take regular medication or have a chronic condition, talk to your doctor before starting. Stop fasting if you feel dizzy or weak.';

  @override
  String get notificationsMaster => 'Notifications';

  @override
  String get notificationsMasterOff =>
      'When on, reminders are sent at the times you choose.';

  @override
  String notificationsScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders scheduled',
      one: '1 reminder scheduled',
      zero: 'No reminders scheduled',
    );
    return '$_temp0';
  }

  @override
  String get notificationsPermissionDenied =>
      'Notification permission wasn\'t granted. You can allow it in device settings.';

  @override
  String get notificationsOpenSettings => 'Open settings';

  @override
  String get notificationsFastingNeedsProtocol =>
      'Pick a protocol in Intermittent Fasting to get fasting reminders.';

  @override
  String get reminderGroupMeal => 'Meals';

  @override
  String get reminderGroupWater => 'Water';

  @override
  String get reminderGroupGoal => 'Goals';

  @override
  String get reminderGroupFasting => 'Fasting';

  @override
  String get reminderGroupMotivation => 'Motivation';

  @override
  String get reminderGroupPlan => 'Plan';

  @override
  String get reminderBreakfast => 'Breakfast';

  @override
  String get reminderLunch => 'Lunch';

  @override
  String get reminderSnack => 'Snack';

  @override
  String get reminderDinner => 'Dinner';

  @override
  String get reminderWater => 'Drink water';

  @override
  String get reminderDailyGoal => 'Daily goal summary';

  @override
  String get reminderWeighIn => 'Weigh-in';

  @override
  String get reminderFastingStart => 'Fast starts';

  @override
  String get reminderEatingStart => 'Eating window opens';

  @override
  String get reminderEatingEnd => 'Eating window closes';

  @override
  String get reminderFastingEnd => 'Fast ends';

  @override
  String get reminderMotivation => 'Daily motivation';

  @override
  String get reminderPlan => 'Plan reminders';

  @override
  String get reminderPlanHint =>
      'Sent at the meal time, with the name from your weekly plan.';

  @override
  String get reminderWaterBalanced =>
      'Spread across your waking hours, based on your water goal.';

  @override
  String get reminderChangeTime => 'Change time';

  @override
  String reminderWaterEvery(String hours, String start, String end) {
    return 'Every $hours h, $start–$end';
  }

  @override
  String reminderEveryHours(String hours) {
    return 'Every $hours h';
  }

  @override
  String reminderWeeklyMonday(String time) {
    return 'Every Monday $time';
  }

  @override
  String get reminderFastingEndHint =>
      'When your current fast reaches its target';

  @override
  String get reminderOutsideWindow =>
      'Not sent because it\'s outside your eating window';

  @override
  String get reminderBreakfastTitle => '🍳 Breakfast time';

  @override
  String get reminderLunchTitle => '🍽️ Lunch time';

  @override
  String get reminderSnackTitle => '🍎 Snack time';

  @override
  String get reminderDinnerTitle => '🌙 Dinner time';

  @override
  String get reminderBreakfastBody => 'Start the day well.';

  @override
  String get reminderLunchBody => 'Don\'t forget the meal in today\'s plan.';

  @override
  String get reminderSnackBody => 'Don\'t skip your snack.';

  @override
  String get reminderDinnerBody => 'Take a look at today\'s plan.';

  @override
  String get reminderMealBody =>
      'Don\'t forget to log today\'s meal in your plan.';

  @override
  String reminderPlanMealTitle(String meal, String recipe) {
    return '$meal: $recipe';
  }

  @override
  String get reminderWaterTitle => '💧 Time for water';

  @override
  String get reminderWaterBody => 'Drink a glass toward your daily water goal.';

  @override
  String get reminderDailyGoalTitle => 'How did today go?';

  @override
  String get reminderDailyGoalBody =>
      'See how close you are to your calorie and protein goals.';

  @override
  String get reminderWeighInTitle => 'Weekly weigh-in';

  @override
  String get reminderWeighInBody => 'Weigh yourself in the morning and log it.';

  @override
  String get reminderFastingStartTitle => '⏱️ Fasting started';

  @override
  String get reminderFastingStartBody =>
      'Your eating window has closed; you can start your fast.';

  @override
  String get reminderEatingStartTitle => '🍽️ Your eating window started';

  @override
  String get reminderEatingStartBody => 'Start with the meal in your plan.';

  @override
  String get reminderEatingEndTitle => 'Your eating window is closing';

  @override
  String reminderEatingEndBody(int minutes) {
    return '$minutes minutes until your window closes.';
  }

  @override
  String get reminderFastingEndTitle => '🎉 Your fast is complete';

  @override
  String get reminderFastingEndBody => 'End your fast whenever you\'re ready.';

  @override
  String get reminderMotivationTitle => 'Small steps, big change';

  @override
  String get reminderMotivationBody =>
      'Pick one thing you can do for your goal today.';

  @override
  String get assistantEmptyTitle =>
      'Ask me anything about what you\'ve eaten today.';

  @override
  String get assistantEmptyMessage =>
      'I answer using your profile, diary, plan, weight log and fasting info.';

  @override
  String get assistantHint => 'Type a question…';

  @override
  String get assistantThinking => 'Preparing an answer';

  @override
  String get assistantClear => 'Clear chat';

  @override
  String get assistantError =>
      'I couldn\'t answer right now. Please try again in a moment.';

  @override
  String get assistantDisclaimer =>
      'Suggestions only; not a medical diagnosis or treatment.';

  @override
  String get assistantQuickRemaining =>
      'How many calories do I have left today?';

  @override
  String get assistantQuickProtein => 'Did I reach my protein goal?';

  @override
  String get assistantQuickDinner => 'What can I eat for dinner?';

  @override
  String get assistantQuickSwap => 'Can I swap a meal in my plan?';

  @override
  String get assistantQuickOver => 'I ate too many calories today';

  @override
  String assistantRemainingCalories(
    String consumed,
    String target,
    String remaining,
  ) {
    return 'You\'ve had $consumed kcal today. Your goal is $target kcal, so you have $remaining kcal left.';
  }

  @override
  String assistantOverCaloriesInfo(
    String consumed,
    String target,
    String over,
  ) {
    return 'You\'ve had $consumed kcal today; your goal is $target kcal. You\'re $over kcal over — it\'s just one day, that\'s okay.';
  }

  @override
  String assistantProteinReached(String consumed, String target) {
    return 'Yes! You\'ve had $consumed g of protein today; your goal is $target g. Great job.';
  }

  @override
  String assistantProteinRemaining(
    String consumed,
    String target,
    String remaining,
  ) {
    return 'Not yet: $consumed / $target g protein. $remaining g to go. Choose protein sources that fit your profile from recipes.';
  }

  @override
  String assistantSuggestionIntro(String meal, String remaining) {
    return 'You have about $remaining kcal for $meal. These could fit:';
  }

  @override
  String assistantSuggestionLight(String meal, String remaining) {
    return '$remaining kcal left for $meal; here\'s a light but filling option:';
  }

  @override
  String assistantSuggestionOver(String meal) {
    return 'You\'ve reached today\'s goal, but don\'t skip $meal. A light, veggie- and protein-based option works well:';
  }

  @override
  String assistantSuggestionFromPlan(String title, String kcal) {
    return 'In your plan: $title ($kcal kcal)';
  }

  @override
  String get assistantSuggestionNone =>
      'I couldn\'t find a suggestion matching your preferences. Take a look at recipes.';

  @override
  String get assistantSwapGeneral =>
      'Sure. Tap a meal in your Nutrition Plan and choose “Swap this meal” to see alternatives that fit your goal, diet and allergies.';

  @override
  String assistantSwapMeal(String meal, String title) {
    return 'Yes. Today\'s $meal is $title. Tap it in your Nutrition Plan and choose “Swap this meal” to pick a similar-calorie alternative.';
  }

  @override
  String assistantOverTarget(String over) {
    return 'You\'re about $over kcal over today\'s goal. It\'s one day and won\'t undo your progress. No need to punish yourself or skip meals; keep drinking water, choose a balanced next meal and continue your plan tomorrow.';
  }

  @override
  String get assistantOverTargetNotReally =>
      'Based on your log you haven\'t gone over today\'s goal. It can feel that way sometimes; you\'re on a balanced track.';

  @override
  String assistantWaterReached(String amount) {
    return 'You\'ve drunk $amount of water today and reached your goal.';
  }

  @override
  String assistantWaterRemaining(String amount, String goal, String left) {
    return 'You\'ve drunk $amount of water today; your goal is $goal. $left to go.';
  }

  @override
  String get assistantWeightEmpty =>
      'You don\'t have any weight entries yet. Add your first one in Weight Tracking.';

  @override
  String assistantWeightProgress(String start, String current, String change) {
    return 'Start: $start, now: $current ($change).';
  }

  @override
  String assistantWeightTarget(String target, String left) {
    return 'Your target is $target; $left to go.';
  }

  @override
  String assistantWaist(String value) {
    return 'Latest waist measurement: $value.';
  }

  @override
  String get assistantWeightNote =>
      'About 0.25–1 kg per week is considered sustainable; daily fluctuations are normal.';

  @override
  String get assistantFastingNone =>
      'You haven\'t chosen a fasting protocol yet. You can plan one in Intermittent Fasting.';

  @override
  String assistantFastingActive(String time) {
    return 'You\'re fasting. Time left to your goal: $time.';
  }

  @override
  String assistantFastingEating(String time) {
    return 'You\'re in your eating window. It closes in $time.';
  }

  @override
  String get assistantSafetyMedical =>
      'This needs a medical evaluation; I can\'t diagnose or advise on medication or treatment. Please talk to your doctor or a dietitian. I\'m happy to keep helping with general nutrition questions.';

  @override
  String get assistantSafetyEatingDisorder =>
      'Thank you for sharing this. If your relationship with food feels hard, you\'re not alone; I\'d encourage you to reach out to a doctor, psychologist or dietitian. If you feel unsafe, call your local emergency number right away.';

  @override
  String get assistantSafetyRestriction =>
      'Very low calories, skipping meals or losing weight very fast can harm your health, so I won\'t recommend it. A balanced plan that fits your goal works better long term. A dietitian can help with a personal program.';

  @override
  String get assistantHelp =>
      'You can ask about: calories left, your protein goal, a suggestion for a meal, swapping a planned meal, water, weight progress or your fast.';

  @override
  String get assistantNotConfigured =>
      'The nutrition assistant is not configured right now.';

  @override
  String get assistantOffline =>
      'No internet connection. Your previous chat is still here; a new answer needs a connection.';

  @override
  String get assistantTimeout => 'The answer timed out. You can try again.';

  @override
  String get assistantRateLimited =>
      'Too many requests. Try again in a moment.';

  @override
  String get assistantInvalidResponse =>
      'The assistant reply could not be read. You can try again.';

  @override
  String get assistantEmptyResponse =>
      'The assistant returned an empty reply. You can try again.';

  @override
  String get assistantMalformed =>
      'The assistant reply was malformed. You can try again.';

  @override
  String get assistantUnavailable =>
      'The nutrition assistant is unavailable right now.';

  @override
  String get assistantMessageTooLong =>
      'That message is too long. Ask a shorter question.';

  @override
  String get assistantRetry => 'Try again';

  @override
  String get assistantPrivacyTitle => 'About the assistant';

  @override
  String get assistantPrivacyBody =>
      'The nutrition assistant is for suggestions. It does not diagnose, recommend medication or treatment, or replace your doctor or dietitian. Chat history stays on this device and is not sent to Firebase. When you ask a question, only the limited context needed for an answer may be sent to a configured server endpoint; the provider key is not stored in the app. Steps, distance and active calories are not written to Firebase; they are included in the request only if you ask about activity or your day. The assistant does not change your diary, plan, water log or calorie target by itself.';

  @override
  String get assistantRecordsLabel => 'Your log';

  @override
  String get assistantCommentaryLabel => 'Note';

  @override
  String get assistantMissingInfo => 'I can\'t access that information.';

  @override
  String get assistantAllergyBlocked =>
      'I can\'t show a suggestion that conflicts with your allergy. You can look at recipes for a safe alternative.';

  @override
  String assistantConsumedOnly(String consumed) {
    return 'You\'ve had $consumed kcal today. A calorie target isn\'t saved.';
  }

  @override
  String assistantMacroLine(String name, String consumed, String target) {
    return '$name: $consumed / $target g';
  }

  @override
  String assistantWaterOnly(String amount) {
    return 'You\'ve drunk $amount of water today. A water target isn\'t saved.';
  }

  @override
  String assistantActivitySteps(int steps) {
    return 'You\'ve taken $steps steps today.';
  }

  @override
  String assistantActivityDistance(String km) {
    return 'Distance: $km km.';
  }

  @override
  String assistantActivityCalories(String kcal) {
    return 'Active calories: $kcal kcal.';
  }

  @override
  String assistantActivityWorkouts(int count) {
    return 'Workouts: $count.';
  }

  @override
  String get assistantPlanEmpty => 'I can\'t see a saved plan for today.';

  @override
  String get assistantRecipeHeading => 'Matching recipes from your catalog:';

  @override
  String assistantRecipeLine(String title, String kcal, String protein) {
    return '$title ($kcal kcal, $protein g protein)';
  }

  @override
  String get assistantQuickToday => 'How am I eating today?';

  @override
  String get assistantQuickProteinBoost => 'How can I increase my protein?';

  @override
  String get assistantQuickWaterGoal => 'Did I reach my water goal?';

  @override
  String get assistantQuickPlanReview => 'Review today\'s plan';

  @override
  String get assistantQuickRecipe => 'Suggest a recipe that fits me';

  @override
  String get assistantQuickDinnerLose =>
      'Suggest a dinner that fits my weight-loss goal.';

  @override
  String get assistantQuickProteinMeal => 'Suggest a high-protein meal.';

  @override
  String get targetChangeTitle =>
      'Would you like to recalculate your daily target based on your new weight?';

  @override
  String get targetChangeCurrentWeight => 'Current weight';

  @override
  String get targetChangeNewWeight => 'New weight';

  @override
  String get targetChangeCurrentCalories => 'Current daily target';

  @override
  String get targetChangeNewCalories => 'New suggested target';

  @override
  String get targetChangeUseNew => 'Use new target';

  @override
  String get targetChangeKeepCurrent => 'Keep current target';

  @override
  String get targetChangeSafety =>
      'Very low calorie targets are limited for your safety. This is an estimate, not medical or dietitian advice.';

  @override
  String targetChangeMacros(String protein, String carbs, String fat) {
    return 'Suggested macros: $protein g protein, $carbs g carbs, $fat g fat.';
  }

  @override
  String get sleepHoursTitle => 'Sleep hours';

  @override
  String get sleepHoursHint =>
      'Water reminders are not sent during these hours.';

  @override
  String get sleepStart => 'Sleep starts';

  @override
  String get sleepEnd => 'Sleep ends';

  @override
  String get notificationsPermissionHint =>
      'We\'ll ask for notification permission when you turn reminders on.';

  @override
  String get waterTodayTitle => 'Today';

  @override
  String get waterHistoryTitle => 'Past days';

  @override
  String get waterEmptyHistory => 'No water logged on other days yet.';

  @override
  String waterRemoveAmount(int amount) {
    return 'Remove $amount ml';
  }

  @override
  String get shoppingMyList => 'My shopping list';

  @override
  String get shoppingAddItem => 'Add item';

  @override
  String get shoppingItemName => 'Item';

  @override
  String get shoppingQuantity => 'Amount';

  @override
  String get shoppingUnit => 'Unit';

  @override
  String get shoppingGenerateWeek => 'Create this week\'s shopping list';

  @override
  String shoppingGenerated(int count) {
    return '$count items added from your plan.';
  }

  @override
  String get shoppingEmptyTitle => 'Your list is empty';

  @override
  String get shoppingEmptyMessage =>
      'Add items yourself or create a list from this week\'s meal plan.';

  @override
  String get shoppingCompleted => 'Completed';

  @override
  String get shoppingClearCompleted => 'Clear completed';

  @override
  String get shoppingFromRecipe => 'From recipe';

  @override
  String get shoppingFromPlan => 'From meal plan';

  @override
  String get shoppingCategoryProduce => 'Vegetables & fruit';

  @override
  String get shoppingCategoryMeat => 'Meat & poultry';

  @override
  String get shoppingCategoryDairy => 'Dairy';

  @override
  String get shoppingCategoryGrains => 'Grains & legumes';

  @override
  String get shoppingCategoryBreakfast => 'Breakfast';

  @override
  String get shoppingCategoryOther => 'Other';

  @override
  String get recipeAddToShopping => 'Add ingredients to shopping list';

  @override
  String get recipeAddedToShopping =>
      'Ingredients were added to your shopping list.';

  @override
  String get photoLogPick => 'Take or choose a photo';

  @override
  String get photoLogCamera => 'Camera';

  @override
  String get photoLogGallery => 'Gallery';

  @override
  String get photoLogAnalyzing => 'Analyzing the photo…';

  @override
  String get photoLogUploading => 'Preparing the photo…';

  @override
  String get photoLogMatching => 'Matching foods…';

  @override
  String get photoLogResults => 'Detected foods';

  @override
  String get photoLogEstimateBadge => 'Candidate';

  @override
  String get photoLogAddToDiary => 'Add to diary';

  @override
  String get photoLogAdded => 'Foods were added to your diary.';

  @override
  String get photoLogDisclaimer =>
      'Results are candidates. Nutrition is calculated from the food record after you confirm. The photo is not saved.';

  @override
  String get photoLogName => 'Food name';

  @override
  String get photoLogAmount => 'Amount';

  @override
  String get photoLogPortion => 'Portion';

  @override
  String get photoLogMeal => 'Meal';

  @override
  String get voiceLogHint =>
      'For example: I ate two eggs, fifty grams of cheese and two slices of bread.';

  @override
  String get voiceLogSimulate => 'Use sample phrase';

  @override
  String get voiceLogParse => 'Break down';

  @override
  String get voiceLogResults => 'Parsed results';

  @override
  String get voiceLogEmpty => 'No foods found. Edit the text and try again.';

  @override
  String get voiceLogDisclaimer =>
      'Speech is turned into text and split into food candidates. Nutrition is calculated after you confirm. The recording is not saved.';

  @override
  String get voiceLogListening => 'Listening…';

  @override
  String get voiceLogStop => 'Stop';

  @override
  String get voiceLogMic => 'Speak';

  @override
  String get voiceLogMicSemantics => 'Speak foods into the microphone';

  @override
  String get voiceLogTranscript => 'Transcript';

  @override
  String get photoLogNoMatch => 'No match found';

  @override
  String get photoLogSearchAgain => 'Search again';

  @override
  String get photoLogManualSearch => 'Search manually';

  @override
  String get photoLogCreateCustom => 'Create custom food';

  @override
  String get photoLogRemove => 'Remove food';

  @override
  String get photoLogAddFood => 'Add food';

  @override
  String get photoLogChangeFood => 'Change food';

  @override
  String get photoLogChooseMatch => 'Choose a match';

  @override
  String get photoLogAmbiguousQuantity => 'Choose an amount';

  @override
  String get photoLogSelectMeal => 'Choose a meal';

  @override
  String get photoLogAllergyWarning =>
      'This food matches an allergy in your profile. This is not a safety check.';

  @override
  String get photoLogDislikeWarning => 'This food is in your disliked foods.';

  @override
  String get photoLogDietWarning =>
      'This food may conflict with your diet preference.';

  @override
  String get photoLogAcknowledge =>
      'I saw the warning and still want to add it';

  @override
  String get photoLogCalculated => 'Nutrition from the food record';

  @override
  String photoLogAssumption(String quantity, String unit, String grams) {
    return '$quantity $unit ≈ $grams g. You can change the amount.';
  }

  @override
  String photoLogConfidence(String percent) {
    return 'Confidence $percent%';
  }

  @override
  String get photoLogCameraSemantics => 'Take a photo with the camera';

  @override
  String get photoLogGallerySemantics => 'Choose a photo from the gallery';

  @override
  String get photoLogManualGrams => 'Enter grams';

  @override
  String get voiceUnitTea => 'teaspoon';

  @override
  String get voiceUnitSpoon => 'spoon';

  @override
  String get voiceUnitPlate => 'plate';

  @override
  String get voiceUnitDessert => 'dessert spoon';

  @override
  String get captureErrorNotConfigured =>
      'Photo food recognition is not configured right now.';

  @override
  String get captureErrorTimeout => 'The request timed out. Please try again.';

  @override
  String get captureErrorOffline =>
      'No internet connection. Photo and voice recognition are unavailable.';

  @override
  String get captureErrorRateLimited =>
      'Too many requests. Try again in a moment.';

  @override
  String get captureErrorInvalid =>
      'The response could not be read. Please try again.';

  @override
  String get captureErrorEmpty => 'No foods were found.';

  @override
  String get captureErrorMalformed =>
      'The response was malformed. Please try again.';

  @override
  String get captureErrorUnavailable => 'The service is unavailable right now.';

  @override
  String get captureErrorImageTooLarge =>
      'The photo is too large. Try a smaller image.';

  @override
  String get captureErrorUnsupportedImage =>
      'This image format is not supported.';

  @override
  String get captureErrorSpeechUnavailable =>
      'Speech recognition is unavailable on this device. You can type instead.';

  @override
  String get captureErrorTranscription => 'Speech could not be transcribed.';

  @override
  String get captureErrorAmbiguous =>
      'The food or amount is ambiguous and was not saved.';

  @override
  String get captureErrorNotFound =>
      'No matching food. It is not saved until you search or create one.';

  @override
  String get captureErrorConfirmation =>
      'Confirmation is required before saving.';

  @override
  String get captureErrorDuplicate => 'This addition was already processed.';

  @override
  String get captureErrorAllergy =>
      'The food was not saved because the allergy warning was not confirmed.';

  @override
  String get confirmNewPlanTitle => 'Replace your nutrition plan?';

  @override
  String get confirmNewPlanMessage =>
      'Your remaining meals this week will be regenerated. Previous meals won\'t be kept.';

  @override
  String get confirmRegeneratePlanTitle => 'Regenerate today\'s plan?';

  @override
  String get confirmRegeneratePlanMessage =>
      'All of today\'s planned meals will be replaced.';

  @override
  String get confirmFastingTitle => 'Change fasting plan?';

  @override
  String get confirmFastingMessage =>
      'Your eating window and fasting reminders will follow the new protocol.';

  @override
  String get waterAdd100 => '+100 ml';

  @override
  String get waterAdd250 => '+250 ml';

  @override
  String get waterAdd500 => '+500 ml';

  @override
  String get weeklyPlanTitle => '7-day plan';

  @override
  String get confirmRegenerateWeekTitle => 'Regenerate the 7-day plan?';

  @override
  String get confirmRegenerateWeekMessage =>
      'This week\'s meals will be rebuilt from your profile calorie and macro targets. The current plan stays until you confirm.';

  @override
  String get planChangeRecipe => 'Change this recipe';

  @override
  String get macroFiber => 'Fiber';
}
