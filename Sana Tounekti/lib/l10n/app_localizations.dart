import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @termsNconditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsNconditions;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @myRelatives.
  ///
  /// In en, this message translates to:
  /// **'My Relatives'**
  String get myRelatives;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourProfile;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dob;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @nic.
  ///
  /// In en, this message translates to:
  /// **'NIC'**
  String get nic;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfo;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @mobileNo.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNo;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get save;

  /// No description provided for @profileText1.
  ///
  /// In en, this message translates to:
  /// **'In here you can edit your profile settings.'**
  String get profileText1;

  /// No description provided for @profileText2.
  ///
  /// In en, this message translates to:
  /// **'If you forget your password relax and try to remember your password.'**
  String get profileText2;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @dashText1.
  ///
  /// In en, this message translates to:
  /// **'Your medication reminders\n will be displayed here.'**
  String get dashText1;

  /// No description provided for @dashText2.
  ///
  /// In en, this message translates to:
  /// **'You have no medication reminders.'**
  String get dashText2;

  /// No description provided for @medicationText1.
  ///
  /// In en, this message translates to:
  /// **'Your medications\n will be displayed here.'**
  String get medicationText1;

  /// No description provided for @medicationText2.
  ///
  /// In en, this message translates to:
  /// **'You have no medications.'**
  String get medicationText2;

  /// No description provided for @buttonText.
  ///
  /// In en, this message translates to:
  /// **'Add a Medication'**
  String get buttonText;

  /// No description provided for @dashText3.
  ///
  /// In en, this message translates to:
  /// **'Your medication alarms\n will be displayed here'**
  String get dashText3;

  /// No description provided for @presImg.
  ///
  /// In en, this message translates to:
  /// **'Prescription Image'**
  String get presImg;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby Pharmacies & Hospitals'**
  String get nearby;

  /// No description provided for @bmi.
  ///
  /// In en, this message translates to:
  /// **'Check your BMI'**
  String get bmi;

  /// No description provided for @upalarm.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Alarms'**
  String get upalarm;

  /// No description provided for @stepsToday.
  ///
  /// In en, this message translates to:
  /// **'Steps today'**
  String get stepsToday;

  /// No description provided for @stepEncouragement0.
  ///
  /// In en, this message translates to:
  /// **'Let\'s take a walk today! 🚶'**
  String get stepEncouragement0;

  /// No description provided for @stepEncouragement500.
  ///
  /// In en, this message translates to:
  /// **'Good start! Keep moving 💪'**
  String get stepEncouragement500;

  /// No description provided for @stepEncouragement2000.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing great! Keep going 🔥'**
  String get stepEncouragement2000;

  /// No description provided for @stepEncouragement5000.
  ///
  /// In en, this message translates to:
  /// **'Halfway to goal! Amazing! 🎯'**
  String get stepEncouragement5000;

  /// No description provided for @stepEncouragement8000.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Fantastic effort! ⭐'**
  String get stepEncouragement8000;

  /// No description provided for @stepEncouragement10000.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! You\'re incredible! 🏆'**
  String get stepEncouragement10000;

  /// No description provided for @stepPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Activity permission needed to count steps. Please enable it in Settings.'**
  String get stepPermissionDenied;

  /// No description provided for @alarmSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get alarmSkip;

  /// No description provided for @alarmSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get alarmSnooze;

  /// No description provided for @chatWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hello! 🌅 I\'m Rafiq, your smart assistant. How are you today? I\'m always here for you.'**
  String get chatWelcome;

  /// No description provided for @chatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get chatPlaceholder;

  /// No description provided for @chatQuickMeds.
  ///
  /// In en, this message translates to:
  /// **'💊 My medications'**
  String get chatQuickMeds;

  /// No description provided for @chatQuickMedsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Did I take all my medications today?'**
  String get chatQuickMedsPrompt;

  /// No description provided for @chatQuickExercise.
  ///
  /// In en, this message translates to:
  /// **'🧠 Exercise'**
  String get chatQuickExercise;

  /// No description provided for @chatQuickExercisePrompt.
  ///
  /// In en, this message translates to:
  /// **'Give me a simple brain exercise'**
  String get chatQuickExercisePrompt;

  /// No description provided for @chatQuickTired.
  ///
  /// In en, this message translates to:
  /// **'😌 Tired'**
  String get chatQuickTired;

  /// No description provided for @chatQuickTiredPrompt.
  ///
  /// In en, this message translates to:
  /// **'I feel tired today, what do you recommend?'**
  String get chatQuickTiredPrompt;

  /// No description provided for @chatQuickStory.
  ///
  /// In en, this message translates to:
  /// **'📖 Story'**
  String get chatQuickStory;

  /// No description provided for @chatQuickStoryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tell me a short happy story'**
  String get chatQuickStoryPrompt;

  /// No description provided for @chatFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get chatFontSize;

  /// No description provided for @alarmTake.
  ///
  /// In en, this message translates to:
  /// **'Take Medication'**
  String get alarmTake;

  /// No description provided for @emgcall.
  ///
  /// In en, this message translates to:
  /// **'Emergency Calls'**
  String get emgcall;

  /// No description provided for @photoHeading.
  ///
  /// In en, this message translates to:
  /// **'Save a photo of your prescription'**
  String get photoHeading;

  /// No description provided for @photoText1.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of your prescription'**
  String get photoText1;

  /// No description provided for @photoBtn1.
  ///
  /// In en, this message translates to:
  /// **'Add a Photo'**
  String get photoBtn1;

  /// No description provided for @photoBtn2.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get photoBtn2;

  /// No description provided for @photoBtn3.
  ///
  /// In en, this message translates to:
  /// **'Browse Gallery'**
  String get photoBtn3;

  /// No description provided for @photoBtn4.
  ///
  /// In en, this message translates to:
  /// **'Use Camera'**
  String get photoBtn4;

  /// No description provided for @photoText2.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get photoText2;

  /// No description provided for @nIS.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get nIS;

  /// No description provided for @pSAI.
  ///
  /// In en, this message translates to:
  /// **'Please select an image first'**
  String get pSAI;

  /// No description provided for @pIAS.
  ///
  /// In en, this message translates to:
  /// **'Prescription image uploaded successfully'**
  String get pIAS;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @dUpload.
  ///
  /// In en, this message translates to:
  /// **'Done uploading'**
  String get dUpload;

  /// No description provided for @bmiCal.
  ///
  /// In en, this message translates to:
  /// **'BMI Calculator'**
  String get bmiCal;

  /// No description provided for @bmiText.
  ///
  /// In en, this message translates to:
  /// **'Body Mass Index(BMI) is a metric of body fat percentage commonly used to estimate risk levels of potential health problems.'**
  String get bmiText;

  /// No description provided for @bmiform1.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get bmiform1;

  /// No description provided for @bmiform2.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get bmiform2;

  /// No description provided for @bmiButton.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get bmiButton;

  /// No description provided for @bmiText1.
  ///
  /// In en, this message translates to:
  /// **'Your BMI Value is: '**
  String get bmiText1;

  /// No description provided for @bmiText2.
  ///
  /// In en, this message translates to:
  /// **'You\'re Underweight!'**
  String get bmiText2;

  /// No description provided for @bmiText3.
  ///
  /// In en, this message translates to:
  /// **'You\'re Healthy!'**
  String get bmiText3;

  /// No description provided for @bmiText4.
  ///
  /// In en, this message translates to:
  /// **'You\'re Overweight!'**
  String get bmiText4;

  /// No description provided for @bmiText5.
  ///
  /// In en, this message translates to:
  /// **'Ideal weight: '**
  String get bmiText5;

  /// No description provided for @bmiText6.
  ///
  /// In en, this message translates to:
  /// **'Please enter your weight'**
  String get bmiText6;

  /// No description provided for @bmiText7.
  ///
  /// In en, this message translates to:
  /// **'Please enter your height'**
  String get bmiText7;

  /// No description provided for @ssa.
  ///
  /// In en, this message translates to:
  /// **'SAMU (Ambulance)'**
  String get ssa;

  /// No description provided for @as.
  ///
  /// In en, this message translates to:
  /// **'Police Secours'**
  String get as;

  /// No description provided for @pi.
  ///
  /// In en, this message translates to:
  /// **'Protection Civile (Firefighters)'**
  String get pi;

  /// No description provided for @fi.
  ///
  /// In en, this message translates to:
  /// **'Garde Nationale'**
  String get fi;

  /// No description provided for @gv.
  ///
  /// In en, this message translates to:
  /// **'Information Center'**
  String get gv;

  /// No description provided for @eps.
  ///
  /// In en, this message translates to:
  /// **'Sea Rescue'**
  String get eps;

  /// No description provided for @ctL.
  ///
  /// In en, this message translates to:
  /// **'Cannot launch'**
  String get ctL;

  /// No description provided for @ddUsage.
  ///
  /// In en, this message translates to:
  /// **'Daily Dosage Usage'**
  String get ddUsage;

  /// No description provided for @wdUsage.
  ///
  /// In en, this message translates to:
  /// **'Weekly Dosage Usage'**
  String get wdUsage;

  /// No description provided for @addMed.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMed;

  /// No description provided for @medName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medName;

  /// No description provided for @vitaminC.
  ///
  /// In en, this message translates to:
  /// **'Vitamin C'**
  String get vitaminC;

  /// No description provided for @cat.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get cat;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength '**
  String get strength;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @stVal.
  ///
  /// In en, this message translates to:
  /// **'Strength Value'**
  String get stVal;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get optional;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @capsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get capsule;

  /// No description provided for @tablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get tablet;

  /// No description provided for @liquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid'**
  String get liquid;

  /// No description provided for @topical.
  ///
  /// In en, this message translates to:
  /// **'Topical'**
  String get topical;

  /// No description provided for @cream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get cream;

  /// No description provided for @drops.
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get drops;

  /// No description provided for @foam.
  ///
  /// In en, this message translates to:
  /// **'Foam'**
  String get foam;

  /// No description provided for @gel.
  ///
  /// In en, this message translates to:
  /// **'Gel'**
  String get gel;

  /// No description provided for @herbal.
  ///
  /// In en, this message translates to:
  /// **'Herbal'**
  String get herbal;

  /// No description provided for @inhaler.
  ///
  /// In en, this message translates to:
  /// **'Inhaler'**
  String get inhaler;

  /// No description provided for @injection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get injection;

  /// No description provided for @lotion.
  ///
  /// In en, this message translates to:
  /// **'Lotion'**
  String get lotion;

  /// No description provided for @nasalSpray.
  ///
  /// In en, this message translates to:
  /// **'Nasal Spray'**
  String get nasalSpray;

  /// No description provided for @ointment.
  ///
  /// In en, this message translates to:
  /// **'Ointment'**
  String get ointment;

  /// No description provided for @patch.
  ///
  /// In en, this message translates to:
  /// **'Patch'**
  String get patch;

  /// No description provided for @powder.
  ///
  /// In en, this message translates to:
  /// **'Powder'**
  String get powder;

  /// No description provided for @spray.
  ///
  /// In en, this message translates to:
  /// **'Spray'**
  String get spray;

  /// No description provided for @suppository.
  ///
  /// In en, this message translates to:
  /// **'Suppository'**
  String get suppository;

  /// No description provided for @dpi.
  ///
  /// In en, this message translates to:
  /// **'Dosage Per Intake'**
  String get dpi;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @apc.
  ///
  /// In en, this message translates to:
  /// **'Available Pill Count '**
  String get apc;

  /// No description provided for @tpc.
  ///
  /// In en, this message translates to:
  /// **'Total Pill Count'**
  String get tpc;

  /// No description provided for @medNote.
  ///
  /// In en, this message translates to:
  /// **'Medication Note '**
  String get medNote;

  /// No description provided for @ufi.
  ///
  /// In en, this message translates to:
  /// **'Using for illness'**
  String get ufi;

  /// No description provided for @medTimes.
  ///
  /// In en, this message translates to:
  /// **'Medication Times'**
  String get medTimes;

  /// No description provided for @tpd.
  ///
  /// In en, this message translates to:
  /// **'time(s) per day'**
  String get tpd;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get addTime;

  /// No description provided for @whenWYTT.
  ///
  /// In en, this message translates to:
  /// **'When will you take this?'**
  String get whenWYTT;

  /// No description provided for @medFreq.
  ///
  /// In en, this message translates to:
  /// **'Medication Frequency'**
  String get medFreq;

  /// No description provided for @sDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get sDate;

  /// No description provided for @eDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get eDate;

  /// No description provided for @aRI.
  ///
  /// In en, this message translates to:
  /// **'At Regular Intervals'**
  String get aRI;

  /// No description provided for @oSDW.
  ///
  /// In en, this message translates to:
  /// **'On Specific Days of the Week'**
  String get oSDW;

  /// No description provided for @cTI.
  ///
  /// In en, this message translates to:
  /// **'Choose the Interval'**
  String get cTI;

  /// No description provided for @freq.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get freq;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @loc.
  ///
  /// In en, this message translates to:
  /// **'Enable Location Services'**
  String get loc;

  /// No description provided for @locSe.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services to use this app.'**
  String get locSe;

  /// No description provided for @locD.
  ///
  /// In en, this message translates to:
  /// **'User denied permissions to access the device location.'**
  String get locD;

  /// No description provided for @eD.
  ///
  /// In en, this message translates to:
  /// **'Every Day'**
  String get eD;

  /// No description provided for @e2D.
  ///
  /// In en, this message translates to:
  /// **'Every 2 Days'**
  String get e2D;

  /// No description provided for @e3D.
  ///
  /// In en, this message translates to:
  /// **'Every 3 Days'**
  String get e3D;

  /// No description provided for @e4D.
  ///
  /// In en, this message translates to:
  /// **'Every 4 Days'**
  String get e4D;

  /// No description provided for @e5D.
  ///
  /// In en, this message translates to:
  /// **'Every 5 Days'**
  String get e5D;

  /// No description provided for @e6D.
  ///
  /// In en, this message translates to:
  /// **'Every 6 Days'**
  String get e6D;

  /// No description provided for @eW.
  ///
  /// In en, this message translates to:
  /// **'Every Week (7 Days)'**
  String get eW;

  /// No description provided for @e2W.
  ///
  /// In en, this message translates to:
  /// **'Every 2 Weeks (14 Days)'**
  String get e2W;

  /// No description provided for @e3W.
  ///
  /// In en, this message translates to:
  /// **'Every 3 Weeks (21 Days)'**
  String get e3W;

  /// No description provided for @eM.
  ///
  /// In en, this message translates to:
  /// **'Every Month (30 Days)'**
  String get eM;

  /// No description provided for @e2M.
  ///
  /// In en, this message translates to:
  /// **'Every 2 Months (60 Days)'**
  String get e2M;

  /// No description provided for @e3M.
  ///
  /// In en, this message translates to:
  /// **'Every 3 Months (90 Days)'**
  String get e3M;

  /// No description provided for @sTD.
  ///
  /// In en, this message translates to:
  /// **'Select the Days'**
  String get sTD;

  /// No description provided for @su.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get su;

  /// No description provided for @m.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get m;

  /// No description provided for @t.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get t;

  /// No description provided for @w.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get w;

  /// No description provided for @th.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get th;

  /// No description provided for @f.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get f;

  /// No description provided for @s.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get s;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @medDetails.
  ///
  /// In en, this message translates to:
  /// **'MEDICATION DETAILS'**
  String get medDetails;

  /// No description provided for @medIntake.
  ///
  /// In en, this message translates to:
  /// **'MEDICATION INTAKE'**
  String get medIntake;

  /// No description provided for @medFreQ.
  ///
  /// In en, this message translates to:
  /// **'MEDICATION FREQUENCY'**
  String get medFreQ;

  /// No description provided for @freQ.
  ///
  /// In en, this message translates to:
  /// **'FREQUENCY'**
  String get freQ;

  /// No description provided for @sInt.
  ///
  /// In en, this message translates to:
  /// **'Select Interval'**
  String get sInt;

  /// No description provided for @sDays.
  ///
  /// In en, this message translates to:
  /// **'Select Day(s)'**
  String get sDays;

  /// No description provided for @sMedFreq.
  ///
  /// In en, this message translates to:
  /// **'Select Medication Frequency'**
  String get sMedFreq;

  /// No description provided for @aOneMedTime.
  ///
  /// In en, this message translates to:
  /// **'Add at least one medication time'**
  String get aOneMedTime;

  /// No description provided for @mAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication added successfully'**
  String get mAddedSuccess;

  /// No description provided for @pstMedName.
  ///
  /// In en, this message translates to:
  /// **'Please select medication name'**
  String get pstMedName;

  /// No description provided for @pstMedCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select medication category'**
  String get pstMedCategory;

  /// No description provided for @pstStrType.
  ///
  /// In en, this message translates to:
  /// **'Please select strength type'**
  String get pstStrType;

  /// No description provided for @pstStrVal.
  ///
  /// In en, this message translates to:
  /// **'Please enter strength value'**
  String get pstStrVal;

  /// No description provided for @apcGd.
  ///
  /// In en, this message translates to:
  /// **'Available pill count should be greater than the dosage'**
  String get apcGd;

  /// No description provided for @sMedSDate.
  ///
  /// In en, this message translates to:
  /// **'Select medication starting date'**
  String get sMedSDate;

  /// No description provided for @t12H.
  ///
  /// In en, this message translates to:
  /// **'Times in 12 Hour: '**
  String get t12H;

  /// No description provided for @eDMBAFu.
  ///
  /// In en, this message translates to:
  /// **'Ending date must be a future date'**
  String get eDMBAFu;

  /// No description provided for @st24H.
  ///
  /// In en, this message translates to:
  /// **'Selected time in 24-hour format: '**
  String get st24H;

  /// No description provided for @nTS.
  ///
  /// In en, this message translates to:
  /// **'No time selected'**
  String get nTS;

  /// No description provided for @maxMedTPD.
  ///
  /// In en, this message translates to:
  /// **'Maximum medication times per day is 24'**
  String get maxMedTPD;

  /// No description provided for @bSD.
  ///
  /// In en, this message translates to:
  /// **'Bottom sheet data: '**
  String get bSD;

  /// No description provided for @aLDT.
  ///
  /// In en, this message translates to:
  /// **'Added log dates and times'**
  String get aLDT;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @brainGames.
  ///
  /// In en, this message translates to:
  /// **'Brain Games'**
  String get brainGames;

  /// No description provided for @brainHealth.
  ///
  /// In en, this message translates to:
  /// **'Brain Health'**
  String get brainHealth;

  /// No description provided for @brainGamesDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep your mind sharp with cognitive exercises'**
  String get brainGamesDesc;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Role'**
  String get chooseRole;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select how you will use this app'**
  String get selectRole;

  /// No description provided for @elderly.
  ///
  /// In en, this message translates to:
  /// **'Elderly Person'**
  String get elderly;

  /// No description provided for @caregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get caregiver;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @elderlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Simple interaction, exercises, medication reminders, SOS'**
  String get elderlyDesc;

  /// No description provided for @caregiverDesc.
  ///
  /// In en, this message translates to:
  /// **'Full management, alerts, status reports, care planning'**
  String get caregiverDesc;

  /// No description provided for @doctorDesc.
  ///
  /// In en, this message translates to:
  /// **'View patient data, trend analysis, treatment validation'**
  String get doctorDesc;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @setupProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get setupProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// No description provided for @patientsToFollow.
  ///
  /// In en, this message translates to:
  /// **'Patients to follow (comma separated emails)'**
  String get patientsToFollow;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Medical License Number'**
  String get licenseNumber;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @patientManagement.
  ///
  /// In en, this message translates to:
  /// **'Patient Management'**
  String get patientManagement;

  /// No description provided for @noPatients.
  ///
  /// In en, this message translates to:
  /// **'No patients yet'**
  String get noPatients;

  /// No description provided for @patientsAppear.
  ///
  /// In en, this message translates to:
  /// **'Patients will appear here when they connect with you'**
  String get patientsAppear;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @currentMedications.
  ///
  /// In en, this message translates to:
  /// **'Current Medications'**
  String get currentMedications;

  /// No description provided for @adherenceRate.
  ///
  /// In en, this message translates to:
  /// **'Adherence Rate'**
  String get adherenceRate;

  /// No description provided for @lastCheckin.
  ///
  /// In en, this message translates to:
  /// **'Last Check-in'**
  String get lastCheckin;

  /// No description provided for @writeRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Write Recommendation'**
  String get writeRecommendation;

  /// No description provided for @sendRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Send Recommendation'**
  String get sendRecommendation;

  /// No description provided for @hiddenObjectGame.
  ///
  /// In en, this message translates to:
  /// **'Hidden Object Game'**
  String get hiddenObjectGame;

  /// No description provided for @hiddenObjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide objects and use hints to find them'**
  String get hiddenObjectDesc;

  /// No description provided for @selectObject.
  ///
  /// In en, this message translates to:
  /// **'Select an object to hide'**
  String get selectObject;

  /// No description provided for @selectRoom.
  ///
  /// In en, this message translates to:
  /// **'Where will you hide it?'**
  String get selectRoom;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startGame;

  /// No description provided for @preparationTime.
  ///
  /// In en, this message translates to:
  /// **'Preparation Time'**
  String get preparationTime;

  /// No description provided for @goHide.
  ///
  /// In en, this message translates to:
  /// **'Go hide the object now!'**
  String get goHide;

  /// No description provided for @readyBtn.
  ///
  /// In en, this message translates to:
  /// **'I\'m done hiding!'**
  String get readyBtn;

  /// No description provided for @searchTime.
  ///
  /// In en, this message translates to:
  /// **'Search Time'**
  String get searchTime;

  /// No description provided for @lookFor.
  ///
  /// In en, this message translates to:
  /// **'Look for:'**
  String get lookFor;

  /// No description provided for @inRoom.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inRoom;

  /// No description provided for @getHint.
  ///
  /// In en, this message translates to:
  /// **'Get a Hint'**
  String get getHint;

  /// No description provided for @foundBtn.
  ///
  /// In en, this message translates to:
  /// **'I found it!'**
  String get foundBtn;

  /// No description provided for @hintLabel.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hintLabel;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takePhoto;

  /// No description provided for @congrats.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You found the object!'**
  String get congrats;

  /// No description provided for @takePhotoToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the found object to confirm'**
  String get takePhotoToConfirm;

  /// No description provided for @photoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get photoConfirm;

  /// No description provided for @skipPhoto.
  ///
  /// In en, this message translates to:
  /// **'Skip Photo'**
  String get skipPhoto;

  /// No description provided for @preparationLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparation Time'**
  String get preparationLabel;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Time'**
  String get searchLabel;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// No description provided for @hintsUsed.
  ///
  /// In en, this message translates to:
  /// **'Hints Used'**
  String get hintsUsed;

  /// No description provided for @objectLabel.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get objectLabel;

  /// No description provided for @roomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomLabel;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @backToGames.
  ///
  /// In en, this message translates to:
  /// **'Back to Games'**
  String get backToGames;

  /// No description provided for @excellentPerf.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get excellentPerf;

  /// No description provided for @wellDonePerf.
  ///
  /// In en, this message translates to:
  /// **'Well Done!'**
  String get wellDonePerf;

  /// No description provided for @notBadPerf.
  ///
  /// In en, this message translates to:
  /// **'Not Bad!'**
  String get notBadPerf;

  /// No description provided for @toImprovePerf.
  ///
  /// In en, this message translates to:
  /// **'To Improve'**
  String get toImprovePerf;

  /// No description provided for @gameComplete.
  ///
  /// In en, this message translates to:
  /// **'Game Complete!'**
  String get gameComplete;

  /// No description provided for @goodForMemory.
  ///
  /// In en, this message translates to:
  /// **'This is great for memory!'**
  String get goodForMemory;

  /// No description provided for @objectCafe.
  ///
  /// In en, this message translates to:
  /// **'Café'**
  String get objectCafe;

  /// No description provided for @objectTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get objectTable;

  /// No description provided for @objectShelf.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get objectShelf;

  /// No description provided for @objectDrawer.
  ///
  /// In en, this message translates to:
  /// **'Drawer'**
  String get objectDrawer;

  /// No description provided for @objectNightstand.
  ///
  /// In en, this message translates to:
  /// **'Nightstand'**
  String get objectNightstand;

  /// No description provided for @objectSofa.
  ///
  /// In en, this message translates to:
  /// **'Sofa'**
  String get objectSofa;

  /// No description provided for @objectBathroom.
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get objectBathroom;

  /// No description provided for @objectBed.
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get objectBed;

  /// No description provided for @objectKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get objectKitchen;

  /// No description provided for @objectEntrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance'**
  String get objectEntrance;

  /// No description provided for @objectHooks.
  ///
  /// In en, this message translates to:
  /// **'Hooks'**
  String get objectHooks;

  /// No description provided for @objectFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get objectFloor;

  /// No description provided for @objectCounter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get objectCounter;

  /// No description provided for @myLinks.
  ///
  /// In en, this message translates to:
  /// **'My Links'**
  String get myLinks;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Assistant Members'**
  String get familyMembers;

  /// No description provided for @myDoctors.
  ///
  /// In en, this message translates to:
  /// **'My Doctors'**
  String get myDoctors;

  /// No description provided for @noFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'No assistants linked'**
  String get noFamilyMembers;

  /// No description provided for @noDoctors.
  ///
  /// In en, this message translates to:
  /// **'No doctors linked'**
  String get noDoctors;

  /// No description provided for @inviteFamily.
  ///
  /// In en, this message translates to:
  /// **'Invite Assistant'**
  String get inviteFamily;

  /// No description provided for @doctorRequests.
  ///
  /// In en, this message translates to:
  /// **'Doctor Requests'**
  String get doctorRequests;

  /// No description provided for @noDoctorRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending doctor requests'**
  String get noDoctorRequests;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @linked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get linked;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @enterDoctorEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter doctor\'s email'**
  String get enterDoctorEmail;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully'**
  String get requestSent;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request'**
  String get requestFailed;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get errorOccurred;

  /// No description provided for @inviteByEmail.
  ///
  /// In en, this message translates to:
  /// **'Invite by Email'**
  String get inviteByEmail;

  /// No description provided for @orEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Or enter email address'**
  String get orEnterEmail;

  /// No description provided for @sendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitation;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent!'**
  String get invitationSent;

  /// No description provided for @invitationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invitation'**
  String get invitationFailed;

  /// No description provided for @selectFamilyRole.
  ///
  /// In en, this message translates to:
  /// **'Select Family Role'**
  String get selectFamilyRole;

  /// No description provided for @spouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get spouse;

  /// No description provided for @child.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get child;

  /// No description provided for @sibling.
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get sibling;

  /// No description provided for @myPatients.
  ///
  /// In en, this message translates to:
  /// **'My Patients'**
  String get myPatients;

  /// No description provided for @noPatientsYet.
  ///
  /// In en, this message translates to:
  /// **'No patients yet'**
  String get noPatientsYet;

  /// No description provided for @patientsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Patients will appear here when they send you requests'**
  String get patientsAppearHere;

  /// No description provided for @patientRequests.
  ///
  /// In en, this message translates to:
  /// **'Patient Requests'**
  String get patientRequests;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get noRequests;

  /// No description provided for @linkNewPatient.
  ///
  /// In en, this message translates to:
  /// **'Link New Patient'**
  String get linkNewPatient;

  /// No description provided for @searchPatient.
  ///
  /// In en, this message translates to:
  /// **'Search patient'**
  String get searchPatient;

  /// No description provided for @enterPatientEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter patient\'s email'**
  String get enterPatientEmail;

  /// No description provided for @sendPatientRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendPatientRequest;

  /// No description provided for @prescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptions;

  /// No description provided for @myPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'My Prescriptions'**
  String get myPrescriptions;

  /// No description provided for @noPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'No prescriptions yet'**
  String get noPrescriptions;

  /// No description provided for @prescriptionsAppear.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions from your doctor will appear here'**
  String get prescriptionsAppear;

  /// No description provided for @createPrescription.
  ///
  /// In en, this message translates to:
  /// **'Create Prescription'**
  String get createPrescription;

  /// No description provided for @prescriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Prescription Details'**
  String get prescriptionDetails;

  /// No description provided for @medication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medication;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @createPrescriptionBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Prescription'**
  String get createPrescriptionBtn;

  /// No description provided for @prescriptionCreated.
  ///
  /// In en, this message translates to:
  /// **'Prescription created successfully!'**
  String get prescriptionCreated;

  /// No description provided for @medicalReports.
  ///
  /// In en, this message translates to:
  /// **'Medical Reports'**
  String get medicalReports;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReports;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No medical reports yet'**
  String get noReports;

  /// No description provided for @reportsAppear.
  ///
  /// In en, this message translates to:
  /// **'Medical reports from your doctor will appear here'**
  String get reportsAppear;

  /// No description provided for @createReport.
  ///
  /// In en, this message translates to:
  /// **'Create Report'**
  String get createReport;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Report Details'**
  String get reportDetails;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Title'**
  String get reportTitle;

  /// No description provided for @reportContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get reportContent;

  /// No description provided for @reportDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportDate;

  /// No description provided for @createReportBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Report'**
  String get createReportBtn;

  /// No description provided for @reportCreated.
  ///
  /// In en, this message translates to:
  /// **'Report created successfully!'**
  String get reportCreated;

  /// No description provided for @selectPatient.
  ///
  /// In en, this message translates to:
  /// **'Select Patient'**
  String get selectPatient;

  /// No description provided for @writePrescription.
  ///
  /// In en, this message translates to:
  /// **'Write Prescription'**
  String get writePrescription;

  /// No description provided for @writeReport.
  ///
  /// In en, this message translates to:
  /// **'Write Report'**
  String get writeReport;

  /// No description provided for @viewPrescription.
  ///
  /// In en, this message translates to:
  /// **'View Prescription'**
  String get viewPrescription;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get viewReport;

  /// No description provided for @prescribedBy.
  ///
  /// In en, this message translates to:
  /// **'Prescribed by'**
  String get prescribedBy;

  /// No description provided for @reportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by: {name}'**
  String reportedBy(Object name);

  /// No description provided for @doctorSpace.
  ///
  /// In en, this message translates to:
  /// **'Doctor Space'**
  String get doctorSpace;

  /// No description provided for @familySpace.
  ///
  /// In en, this message translates to:
  /// **'Assistant Space'**
  String get familySpace;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @prescriptionsNav.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptionsNav;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @addPatient.
  ///
  /// In en, this message translates to:
  /// **'Add Patient'**
  String get addPatient;

  /// No description provided for @linkPatient.
  ///
  /// In en, this message translates to:
  /// **'Link Patient'**
  String get linkPatient;

  /// No description provided for @noLinkedPatients.
  ///
  /// In en, this message translates to:
  /// **'No linked patients'**
  String get noLinkedPatients;

  /// No description provided for @linkToDoctor.
  ///
  /// In en, this message translates to:
  /// **'Link to Doctor'**
  String get linkToDoctor;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @noPatientLinked.
  ///
  /// In en, this message translates to:
  /// **'No linked patient. Add patients first.'**
  String get noPatientLinked;

  /// No description provided for @selectPatientForPrescription.
  ///
  /// In en, this message translates to:
  /// **'Select a patient'**
  String get selectPatientForPrescription;

  /// No description provided for @choosePatientForPrescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the patient for this prescription'**
  String get choosePatientForPrescription;

  /// No description provided for @selectPatientForReport.
  ///
  /// In en, this message translates to:
  /// **'Select a patient'**
  String get selectPatientForReport;

  /// No description provided for @choosePatientForReport.
  ///
  /// In en, this message translates to:
  /// **'Choose the patient for this report'**
  String get choosePatientForReport;

  /// No description provided for @newPrescription.
  ///
  /// In en, this message translates to:
  /// **'New Prescription'**
  String get newPrescription;

  /// No description provided for @newReport.
  ///
  /// In en, this message translates to:
  /// **'New Report'**
  String get newReport;

  /// No description provided for @viewMedications.
  ///
  /// In en, this message translates to:
  /// **'View Medications'**
  String get viewMedications;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get createdOn;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// No description provided for @addAtLeastOneMedication.
  ///
  /// In en, this message translates to:
  /// **'Add at least one medication'**
  String get addAtLeastOneMedication;

  /// No description provided for @prescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Prescription Title'**
  String get prescriptionTitle;

  /// No description provided for @treatmentDuration.
  ///
  /// In en, this message translates to:
  /// **'Treatment Duration'**
  String get treatmentDuration;

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get specialInstructions;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get enterTitle;

  /// No description provided for @treatmentDurationHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: 30 days'**
  String get treatmentDurationHint;

  /// No description provided for @instructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Special instructions for the patient...'**
  String get instructionsHint;

  /// No description provided for @shortSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Short summary of the report...'**
  String get shortSummaryHint;

  /// No description provided for @detailedContent.
  ///
  /// In en, this message translates to:
  /// **'Detailed Content'**
  String get detailedContent;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Medical report details...'**
  String get reportDetailsHint;

  /// No description provided for @notesForPatient.
  ///
  /// In en, this message translates to:
  /// **'Notes for the Patient'**
  String get notesForPatient;

  /// No description provided for @patientNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Instructions or advice for the patient...'**
  String get patientNotesHint;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @clickToAccept.
  ///
  /// In en, this message translates to:
  /// **'Click to accept'**
  String get clickToAccept;

  /// No description provided for @waitingForConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get waitingForConfirmation;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @medicationsCount.
  ///
  /// In en, this message translates to:
  /// **'medication(s)'**
  String get medicationsCount;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequests;

  /// No description provided for @noActivePrescriptions.
  ///
  /// In en, this message translates to:
  /// **'No active prescriptions'**
  String get noActivePrescriptions;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @doctorNotes.
  ///
  /// In en, this message translates to:
  /// **'Doctor\'s notes'**
  String get doctorNotes;

  /// No description provided for @gameMemoryMatch.
  ///
  /// In en, this message translates to:
  /// **'Memory Match'**
  String get gameMemoryMatch;

  /// No description provided for @gameMemoryMatchDesc.
  ///
  /// In en, this message translates to:
  /// **'Match pairs of cards to improve memory'**
  String get gameMemoryMatchDesc;

  /// No description provided for @gameMathChallenge.
  ///
  /// In en, this message translates to:
  /// **'Math Challenge'**
  String get gameMathChallenge;

  /// No description provided for @gameMathChallengeDesc.
  ///
  /// In en, this message translates to:
  /// **'Solve math problems to keep your mind sharp'**
  String get gameMathChallengeDesc;

  /// No description provided for @gameReactionTest.
  ///
  /// In en, this message translates to:
  /// **'Reaction Test'**
  String get gameReactionTest;

  /// No description provided for @gameReactionTestDesc.
  ///
  /// In en, this message translates to:
  /// **'Test your reflexes and response time'**
  String get gameReactionTestDesc;

  /// No description provided for @gameColorMatch.
  ///
  /// In en, this message translates to:
  /// **'Color Match'**
  String get gameColorMatch;

  /// No description provided for @gameColorMatchDesc.
  ///
  /// In en, this message translates to:
  /// **'Say the color of the text, not the word'**
  String get gameColorMatchDesc;

  /// No description provided for @gameWordScramble.
  ///
  /// In en, this message translates to:
  /// **'Word Scramble'**
  String get gameWordScramble;

  /// No description provided for @gameWordScrambleDesc.
  ///
  /// In en, this message translates to:
  /// **'Unscramble letters to form words'**
  String get gameWordScrambleDesc;

  /// No description provided for @gameSequenceMemory.
  ///
  /// In en, this message translates to:
  /// **'Sequence Memory'**
  String get gameSequenceMemory;

  /// No description provided for @gameSequenceMemoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Remember and repeat sequences'**
  String get gameSequenceMemoryDesc;

  /// No description provided for @gameTicTacToe.
  ///
  /// In en, this message translates to:
  /// **'Tic Tac Toe'**
  String get gameTicTacToe;

  /// No description provided for @gameTicTacToeDesc.
  ///
  /// In en, this message translates to:
  /// **'Play against AI in this classic game'**
  String get gameTicTacToeDesc;

  /// No description provided for @gameHiddenObject.
  ///
  /// In en, this message translates to:
  /// **'Hidden Object'**
  String get gameHiddenObject;

  /// No description provided for @gameHiddenObjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide objects and use hints to find them'**
  String get gameHiddenObjectDesc;

  /// No description provided for @gamePlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get gamePlayAgain;

  /// No description provided for @gameBack.
  ///
  /// In en, this message translates to:
  /// **'Back to Games'**
  String get gameBack;

  /// No description provided for @gameCongratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get gameCongratulations;

  /// No description provided for @gameYouWon.
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get gameYouWon;

  /// No description provided for @gameMoves.
  ///
  /// In en, this message translates to:
  /// **'moves'**
  String get gameMoves;

  /// No description provided for @gameScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get gameScore;

  /// No description provided for @gameLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get gameLevel;

  /// No description provided for @gameTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get gameTime;

  /// No description provided for @gameTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up!'**
  String get gameTimeUp;

  /// No description provided for @gameTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get gameTryAgain;

  /// No description provided for @gameCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get gameCorrect;

  /// No description provided for @gameWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong!'**
  String get gameWrong;

  /// No description provided for @gameNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next Level'**
  String get gameNextLevel;

  /// No description provided for @gameGameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameGameOver;

  /// No description provided for @gameTapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to Start'**
  String get gameTapToStart;

  /// No description provided for @gameGetReady.
  ///
  /// In en, this message translates to:
  /// **'Get Ready!'**
  String get gameGetReady;

  /// No description provided for @gameYourScore.
  ///
  /// In en, this message translates to:
  /// **'Your Score'**
  String get gameYourScore;

  /// No description provided for @gamePerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect!'**
  String get gamePerfect;

  /// No description provided for @gameGood.
  ///
  /// In en, this message translates to:
  /// **'Good!'**
  String get gameGood;

  /// No description provided for @gameExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get gameExcellent;

  /// No description provided for @gameKeepTrying.
  ///
  /// In en, this message translates to:
  /// **'Keep Trying!'**
  String get gameKeepTrying;

  /// No description provided for @gameMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get gameMatch;

  /// No description provided for @gameMismatch.
  ///
  /// In en, this message translates to:
  /// **'Mismatch'**
  String get gameMismatch;

  /// No description provided for @gameSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get gameSelect;

  /// No description provided for @gameClickToReveal.
  ///
  /// In en, this message translates to:
  /// **'Click to reveal'**
  String get gameClickToReveal;

  /// No description provided for @gameLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get gameLocked;

  /// No description provided for @gameWon.
  ///
  /// In en, this message translates to:
  /// **'You Won!'**
  String get gameWon;

  /// No description provided for @gameDraw.
  ///
  /// In en, this message translates to:
  /// **'It\'s a Draw!'**
  String get gameDraw;

  /// No description provided for @gameYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn! Tap the numbers'**
  String get gameYourTurn;

  /// No description provided for @gameAiTurn.
  ///
  /// In en, this message translates to:
  /// **'AI\'s Turn'**
  String get gameAiTurn;

  /// No description provided for @gameX.
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get gameX;

  /// No description provided for @gameO.
  ///
  /// In en, this message translates to:
  /// **'O'**
  String get gameO;

  /// No description provided for @gameStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get gameStart;

  /// No description provided for @gameRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get gameRestart;

  /// No description provided for @gameEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get gameEasy;

  /// No description provided for @gameMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get gameMedium;

  /// No description provided for @gameHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get gameHard;

  /// No description provided for @gameSelectDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Select Difficulty'**
  String get gameSelectDifficulty;

  /// No description provided for @gameQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question #'**
  String get gameQuestionNumber;

  /// No description provided for @gameYes.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get gameYes;

  /// No description provided for @gameNo.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get gameNo;

  /// No description provided for @gameSayTheColor.
  ///
  /// In en, this message translates to:
  /// **'Say the COLOR, not the word!'**
  String get gameSayTheColor;

  /// No description provided for @gameIsTheColor.
  ///
  /// In en, this message translates to:
  /// **'Is the color'**
  String get gameIsTheColor;

  /// No description provided for @gameTapToTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Tap to try again'**
  String get gameTapToTryAgain;

  /// No description provided for @gameTooEarly.
  ///
  /// In en, this message translates to:
  /// **'Too early! Wait for green.'**
  String get gameTooEarly;

  /// No description provided for @gameLastTime.
  ///
  /// In en, this message translates to:
  /// **'Last:'**
  String get gameLastTime;

  /// No description provided for @gameAverageTime.
  ///
  /// In en, this message translates to:
  /// **'Average:'**
  String get gameAverageTime;

  /// No description provided for @gameAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts:'**
  String get gameAttempts;

  /// No description provided for @gameMs.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get gameMs;

  /// No description provided for @gameWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get gameWord;

  /// No description provided for @gameSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get gameSubmit;

  /// No description provided for @gameWatchSequence.
  ///
  /// In en, this message translates to:
  /// **'Watch the sequence:'**
  String get gameWatchSequence;

  /// No description provided for @gameYourInput.
  ///
  /// In en, this message translates to:
  /// **'Your input:'**
  String get gameYourInput;

  /// No description provided for @gameYou.
  ///
  /// In en, this message translates to:
  /// **'You (X)'**
  String get gameYou;

  /// No description provided for @gameAi.
  ///
  /// In en, this message translates to:
  /// **'AI (O)'**
  String get gameAi;

  /// No description provided for @gameWait.
  ///
  /// In en, this message translates to:
  /// **'Wait...'**
  String get gameWait;

  /// No description provided for @dailyAssistant.
  ///
  /// In en, this message translates to:
  /// **'Daily Assistant'**
  String get dailyAssistant;

  /// No description provided for @playGame.
  ///
  /// In en, this message translates to:
  /// **'Play Game'**
  String get playGame;

  /// No description provided for @healthTip.
  ///
  /// In en, this message translates to:
  /// **'Health Tip'**
  String get healthTip;

  /// No description provided for @aiTip.
  ///
  /// In en, this message translates to:
  /// **'AI Tip'**
  String get aiTip;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @aiTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get aiTyping;

  /// No description provided for @aiRecommendsGame.
  ///
  /// In en, this message translates to:
  /// **'I recommend you play this game today!'**
  String get aiRecommendsGame;

  /// No description provided for @tapToPlay.
  ///
  /// In en, this message translates to:
  /// **'Tap to start playing'**
  String get tapToPlay;

  /// No description provided for @healthTip1.
  ///
  /// In en, this message translates to:
  /// **'Remember to drink at least 8 glasses of water today! Staying hydrated is essential for your health.'**
  String get healthTip1;

  /// No description provided for @healthTip2.
  ///
  /// In en, this message translates to:
  /// **'A 15-minute walk can improve your mood and energy levels. Try to take a short walk today!'**
  String get healthTip2;

  /// No description provided for @healthTip3.
  ///
  /// In en, this message translates to:
  /// **'Good sleep is important! Try to get 7-8 hours of sleep tonight.'**
  String get healthTip3;

  /// No description provided for @healthTip4.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to take your medications on time. Your health depends on it!'**
  String get healthTip4;

  /// No description provided for @healthTip5.
  ///
  /// In en, this message translates to:
  /// **'Social connections are important. Try calling a friend or family member today!'**
  String get healthTip5;

  /// No description provided for @healthTip6.
  ///
  /// In en, this message translates to:
  /// **'Mental exercise is just as important as physical exercise. Play some brain games today!'**
  String get healthTip6;

  /// No description provided for @motivation1.
  ///
  /// In en, this message translates to:
  /// **'Every day is a new opportunity to learn and grow. You\'re doing great!'**
  String get motivation1;

  /// No description provided for @motivation2.
  ///
  /// In en, this message translates to:
  /// **'Your dedication to your health inspires others. Keep it up!'**
  String get motivation2;

  /// No description provided for @motivation3.
  ///
  /// In en, this message translates to:
  /// **'Small steps lead to big changes. You\'re on the right track!'**
  String get motivation3;

  /// No description provided for @motivation4.
  ///
  /// In en, this message translates to:
  /// **'Taking care of yourself is the best thing you can do today.'**
  String get motivation4;

  /// No description provided for @motivation5.
  ///
  /// In en, this message translates to:
  /// **'Believe in yourself! You have the power to make each day amazing.'**
  String get motivation5;

  /// No description provided for @aiHealthTipResponse.
  ///
  /// In en, this message translates to:
  /// **'Here are some health tips for you:\n• Stay hydrated\n• Exercise daily\n• Get enough sleep\n• Take medications on time\nWould you like more specific advice?'**
  String get aiHealthTipResponse;

  /// No description provided for @aiMedicationReminder.
  ///
  /// In en, this message translates to:
  /// **'Remember to take your medications on time! Your health is important. Set reminders if you need help remembering.'**
  String get aiMedicationReminder;

  /// No description provided for @aiGreetingResponse.
  ///
  /// In en, this message translates to:
  /// **'Hello! How are you feeling today? I\'m here to help you stay healthy and active. What would you like to do?'**
  String get aiGreetingResponse;

  /// No description provided for @aiThanksResponse.
  ///
  /// In en, this message translates to:
  /// **'You\'re welcome! Remember, taking care of your health is a journey. I\'m always here to help!'**
  String get aiThanksResponse;

  /// No description provided for @aiGeneralResponse.
  ///
  /// In en, this message translates to:
  /// **'I understand. Let me help you with that. Here are some things you can do:\n• Play brain games to stay sharp\n• Check your medications\n• Get health tips\n• Exercise your mind and body'**
  String get aiGeneralResponse;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @nextBtn.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextBtn;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onbTitle1.
  ///
  /// In en, this message translates to:
  /// **'Never miss\na medication again!'**
  String get onbTitle1;

  /// No description provided for @onbDesc1.
  ///
  /// In en, this message translates to:
  /// **'Smart reminders for every dose. Never miss a dose, even on the go.'**
  String get onbDesc1;

  /// No description provided for @onbTitle2.
  ///
  /// In en, this message translates to:
  /// **'Your loved ones\nconnected in one click'**
  String get onbTitle2;

  /// No description provided for @onbDesc2.
  ///
  /// In en, this message translates to:
  /// **'Share your schedule with family and doctors. Stay surrounded wherever you are.'**
  String get onbDesc2;

  /// No description provided for @onbTitle3.
  ///
  /// In en, this message translates to:
  /// **'Nearby pharmacies\nand hospitals'**
  String get onbTitle3;

  /// No description provided for @onbDesc3.
  ///
  /// In en, this message translates to:
  /// **'Easily find the nearest health services. Emergencies, pharmacies, everything at your fingertips.'**
  String get onbDesc3;

  /// No description provided for @onbTitle4.
  ///
  /// In en, this message translates to:
  /// **'Track your health\ndaily'**
  String get onbTitle4;

  /// No description provided for @onbDesc4.
  ///
  /// In en, this message translates to:
  /// **'Statistics, BMI, brain games. Take control of your well-being with ease.'**
  String get onbDesc4;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @loginWithFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Login with Fingerprint'**
  String get loginWithFingerprint;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @emailFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailFieldLabel;

  /// No description provided for @emailFieldHint.
  ///
  /// In en, this message translates to:
  /// **'name@email.com'**
  String get emailFieldHint;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @passwordFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldLabel;

  /// No description provided for @passwordFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signInBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInBtn;

  /// No description provided for @noSavedAccount.
  ///
  /// In en, this message translates to:
  /// **'No saved account. Please sign in first.'**
  String get noSavedAccount;

  /// No description provided for @noAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No account found. Please sign up first.'**
  String get noAccountFound;

  /// No description provided for @biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed.'**
  String get biometricFailed;

  /// No description provided for @noSavedPassword.
  ///
  /// In en, this message translates to:
  /// **'No saved password.'**
  String get noSavedPassword;

  /// No description provided for @accountNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get accountNotFoundTitle;

  /// No description provided for @createNewAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email. Create a new account?'**
  String get createNewAccountPrompt;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @signUpDialogBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpDialogBtn;

  /// No description provided for @errEmailAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Email already used. Go to login page.'**
  String get errEmailAlreadyUsed;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errWrongPassword;

  /// No description provided for @errUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email.'**
  String get errUserNotFound;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'User disabled.'**
  String get errUserDisabled;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests to log into this account.'**
  String get errTooManyRequests;

  /// No description provided for @errServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error, please try again later.'**
  String get errServerError;

  /// No description provided for @errNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error.'**
  String get errNetworkError;

  /// No description provided for @errSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get errSignInFailed;

  /// No description provided for @letsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s\nGet Started'**
  String get letsGetStarted;

  /// No description provided for @nameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameFieldLabel;

  /// No description provided for @nameFieldHint.
  ///
  /// In en, this message translates to:
  /// **'FirstName LastName'**
  String get nameFieldHint;

  /// No description provided for @enterValidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name'**
  String get enterValidName;

  /// No description provided for @selectRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectRoleHint;

  /// No description provided for @patientRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Elderly Person (Patient)'**
  String get patientRoleLabel;

  /// No description provided for @assistantRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistantRoleLabel;

  /// No description provided for @doctorRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorRoleLabel;

  /// No description provided for @doctorHome.
  ///
  /// In en, this message translates to:
  /// **'Doctor Dashboard'**
  String get doctorHome;

  /// No description provided for @selectRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectRoleTitle;

  /// No description provided for @patientRole.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientRole;

  /// No description provided for @assistantRole.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistantRole;

  /// No description provided for @doctorRole.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorRole;

  /// No description provided for @confirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmBtn;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreatedSuccess;

  /// No description provided for @signUpBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpBtn;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLink;

  /// No description provided for @errSignUpEmailUsed.
  ///
  /// In en, this message translates to:
  /// **'Email already used. Go to Sign In page.'**
  String get errSignUpEmailUsed;

  /// No description provided for @errOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Operation is not allowed.'**
  String get errOperationNotAllowed;

  /// No description provided for @errSignUpInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address is invalid.'**
  String get errSignUpInvalidEmail;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get errWeakPassword;

  /// No description provided for @errSignUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Account creation failed. Please try again.'**
  String get errSignUpFailed;

  /// No description provided for @errAccountExists.
  ///
  /// In en, this message translates to:
  /// **'Account already exists. Please sign in.'**
  String get errAccountExists;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address associated with your account'**
  String get resetPasswordDesc;

  /// No description provided for @resetPasswordBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordBtn;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent! Check your email.'**
  String get resetLinkSent;

  /// No description provided for @errResetUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email.'**
  String get errResetUserNotFound;

  /// No description provided for @errResetWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a strong password'**
  String get errResetWeakPassword;

  /// No description provided for @errResetInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid action code. Please try again'**
  String get errResetInvalidCode;

  /// No description provided for @errResetExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Action code is expired.'**
  String get errResetExpiredCode;

  /// No description provided for @errResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Error while resetting password.'**
  String get errResetFailed;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'We have sent you an email on'**
  String get verifyEmailDesc;

  /// No description provided for @verifyWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification...'**
  String get verifyWaiting;

  /// No description provided for @verifyResendBtn.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get verifyResendBtn;

  /// No description provided for @verifyEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully.'**
  String get verifyEmailSuccess;

  /// No description provided for @verifyLinkResent.
  ///
  /// In en, this message translates to:
  /// **'Verification link resent! Check your email.'**
  String get verifyLinkResent;

  /// No description provided for @errVerifyTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again'**
  String get errVerifyTooManyRequests;

  /// No description provided for @errVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get errVerifyFailed;

  /// No description provided for @selectBirthday.
  ///
  /// In en, this message translates to:
  /// **'Select your birthday'**
  String get selectBirthday;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get selectGender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @nicHint.
  ///
  /// In en, this message translates to:
  /// **'123456789V'**
  String get nicHint;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'No, Street, City'**
  String get addressHint;

  /// No description provided for @mobileHint.
  ///
  /// In en, this message translates to:
  /// **'07XXXXXXXX'**
  String get mobileHint;

  /// No description provided for @dataUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your data updated successfully'**
  String get dataUpdatedSuccess;

  /// No description provided for @mciAssessment.
  ///
  /// In en, this message translates to:
  /// **'MCI Assessment'**
  String get mciAssessment;

  /// No description provided for @yourAge.
  ///
  /// In en, this message translates to:
  /// **'Your Age'**
  String get yourAge;

  /// No description provided for @howOldAreYou.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get howOldAreYou;

  /// No description provided for @sleepQuality.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality'**
  String get sleepQuality;

  /// No description provided for @memoryIssues.
  ///
  /// In en, this message translates to:
  /// **'Memory Issues'**
  String get memoryIssues;

  /// No description provided for @forgetfulness.
  ///
  /// In en, this message translates to:
  /// **'Forgetfulness'**
  String get forgetfulness;

  /// No description provided for @reactionTime.
  ///
  /// In en, this message translates to:
  /// **'Reaction Time'**
  String get reactionTime;

  /// No description provided for @educationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education Level'**
  String get educationLevel;

  /// No description provided for @dailyActivity.
  ///
  /// In en, this message translates to:
  /// **'Daily Activity'**
  String get dailyActivity;

  /// No description provided for @backBtn.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backBtn;

  /// No description provided for @getResults.
  ///
  /// In en, this message translates to:
  /// **'Get Results'**
  String get getResults;

  /// No description provided for @retakeAssessment.
  ///
  /// In en, this message translates to:
  /// **'Retake Assessment'**
  String get retakeAssessment;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @rarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get rarely;

  /// No description provided for @sometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get sometimes;

  /// No description provided for @frequent.
  ///
  /// In en, this message translates to:
  /// **'Frequent'**
  String get frequent;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @secondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get secondary;

  /// No description provided for @higher.
  ///
  /// In en, this message translates to:
  /// **'Higher'**
  String get higher;

  /// No description provided for @normalReactionInfo.
  ///
  /// In en, this message translates to:
  /// **'Normal reaction time for elderly: 0.5-1.5 seconds'**
  String get normalReactionInfo;

  /// No description provided for @cognitiveExercises.
  ///
  /// In en, this message translates to:
  /// **'Cognitive Exercises'**
  String get cognitiveExercises;

  /// No description provided for @dailyBrainTraining.
  ///
  /// In en, this message translates to:
  /// **'Daily Brain Training'**
  String get dailyBrainTraining;

  /// No description provided for @chooseExercise.
  ///
  /// In en, this message translates to:
  /// **'Choose an exercise to train your brain'**
  String get chooseExercise;

  /// No description provided for @memoryTest.
  ///
  /// In en, this message translates to:
  /// **'Memory Test'**
  String get memoryTest;

  /// No description provided for @reactionSpeed.
  ///
  /// In en, this message translates to:
  /// **'Reaction Speed'**
  String get reactionSpeed;

  /// No description provided for @mathChallenge.
  ///
  /// In en, this message translates to:
  /// **'Math Challenge'**
  String get mathChallenge;

  /// No description provided for @attentionTest.
  ///
  /// In en, this message translates to:
  /// **'Attention Test'**
  String get attentionTest;

  /// No description provided for @memorizeWords.
  ///
  /// In en, this message translates to:
  /// **'Memorize these words'**
  String get memorizeWords;

  /// No description provided for @imReady.
  ///
  /// In en, this message translates to:
  /// **'I\'m Ready'**
  String get imReady;

  /// No description provided for @wasWordInList.
  ///
  /// In en, this message translates to:
  /// **'Was this word in the list?'**
  String get wasWordInList;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @tapWhenGreen.
  ///
  /// In en, this message translates to:
  /// **'Tap when the screen turns green!'**
  String get tapWhenGreen;

  /// No description provided for @startBtn.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startBtn;

  /// No description provided for @tapNow.
  ///
  /// In en, this message translates to:
  /// **'TAP NOW!'**
  String get tapNow;

  /// No description provided for @wait.
  ///
  /// In en, this message translates to:
  /// **'Wait...'**
  String get wait;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get excellent;

  /// No description provided for @goodJob.
  ///
  /// In en, this message translates to:
  /// **'Good job!'**
  String get goodJob;

  /// No description provided for @keepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing!'**
  String get keepPracticing;

  /// No description provided for @scoreOutOf10.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} / 10'**
  String scoreOutOf10(Object score);

  /// No description provided for @correctAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct: {count}'**
  String correctAnswers(Object count);

  /// No description provided for @backToExercises.
  ///
  /// In en, this message translates to:
  /// **'Back to Exercises'**
  String get backToExercises;

  /// No description provided for @progressTab.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTab;

  /// No description provided for @cognitiveTab.
  ///
  /// In en, this message translates to:
  /// **'Cognitive'**
  String get cognitiveTab;

  /// No description provided for @brainHealthTab.
  ///
  /// In en, this message translates to:
  /// **'Brain Health'**
  String get brainHealthTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @weeklyPerformance.
  ///
  /// In en, this message translates to:
  /// **'Weekly Performance'**
  String get weeklyPerformance;

  /// No description provided for @latestScores.
  ///
  /// In en, this message translates to:
  /// **'Latest Scores'**
  String get latestScores;

  /// No description provided for @noTestScoresYet.
  ///
  /// In en, this message translates to:
  /// **'No test scores yet. Complete some cognitive exercises!'**
  String get noTestScoresYet;

  /// No description provided for @brainHealthScoreEvolution.
  ///
  /// In en, this message translates to:
  /// **'Brain Health Score Evolution'**
  String get brainHealthScoreEvolution;

  /// No description provided for @takeAssessmentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Take an MCI assessment to track your brain health over time.'**
  String get takeAssessmentPrompt;

  /// No description provided for @mciAssessments.
  ///
  /// In en, this message translates to:
  /// **'MCI Assessments'**
  String get mciAssessments;

  /// No description provided for @noAssessmentHistory.
  ///
  /// In en, this message translates to:
  /// **'No assessment history yet.'**
  String get noAssessmentHistory;

  /// No description provided for @riskLabel.
  ///
  /// In en, this message translates to:
  /// **'Risk: {riskLevel}'**
  String riskLabel(String riskLevel);

  /// No description provided for @nutritionScreen.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionScreen;

  /// No description provided for @healthProfile.
  ///
  /// In en, this message translates to:
  /// **'Health Profile'**
  String get healthProfile;

  /// No description provided for @personalizeMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Help us personalize your meal plan'**
  String get personalizeMealPlan;

  /// No description provided for @diabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get diabetes;

  /// No description provided for @doYouHaveDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Do you have diabetes?'**
  String get doYouHaveDiabetes;

  /// No description provided for @hypertension.
  ///
  /// In en, this message translates to:
  /// **'Hypertension'**
  String get hypertension;

  /// No description provided for @highBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'High blood pressure?'**
  String get highBloodPressure;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @getMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Get Meal Plan'**
  String get getMealPlan;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @todaysMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meal Plan'**
  String get todaysMealPlan;

  /// No description provided for @totalCalories.
  ///
  /// In en, this message translates to:
  /// **'Total: {calories} kcal'**
  String totalCalories(Object calories);

  /// No description provided for @keyNutrients.
  ///
  /// In en, this message translates to:
  /// **'Key Nutrients'**
  String get keyNutrients;

  /// No description provided for @dailyActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Activities'**
  String get dailyActivitiesTitle;

  /// No description provided for @hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydration;

  /// No description provided for @glassesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / 8 glasses'**
  String glassesCount(Object count);

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @exercisesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String exercisesCount(Object count);

  /// No description provided for @walking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get walking;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @routines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routines;

  /// No description provided for @morningRoutine.
  ///
  /// In en, this message translates to:
  /// **'Morning routine'**
  String get morningRoutine;

  /// No description provided for @eveningRoutine.
  ///
  /// In en, this message translates to:
  /// **'Evening routine'**
  String get eveningRoutine;

  /// No description provided for @socialInteraction.
  ///
  /// In en, this message translates to:
  /// **'Social Interaction'**
  String get socialInteraction;

  /// No description provided for @contactFamilyToday.
  ///
  /// In en, this message translates to:
  /// **'Contact with family/friends today'**
  String get contactFamilyToday;

  /// No description provided for @saveActivities.
  ///
  /// In en, this message translates to:
  /// **'Save Activities'**
  String get saveActivities;

  /// No description provided for @activitiesSaved.
  ///
  /// In en, this message translates to:
  /// **'Activities saved successfully'**
  String get activitiesSaved;

  /// No description provided for @incidentHistory.
  ///
  /// In en, this message translates to:
  /// **'Incident History'**
  String get incidentHistory;

  /// No description provided for @noIncidents.
  ///
  /// In en, this message translates to:
  /// **'No incidents reported'**
  String get noIncidents;

  /// No description provided for @fall.
  ///
  /// In en, this message translates to:
  /// **'Fall'**
  String get fall;

  /// No description provided for @medicationMiss.
  ///
  /// In en, this message translates to:
  /// **'Missed Medication'**
  String get medicationMiss;

  /// No description provided for @abnormalBehavior.
  ///
  /// In en, this message translates to:
  /// **'Abnormal Behavior'**
  String get abnormalBehavior;

  /// No description provided for @painDiscomfort.
  ///
  /// In en, this message translates to:
  /// **'Pain / Discomfort'**
  String get painDiscomfort;

  /// No description provided for @mobilityIssue.
  ///
  /// In en, this message translates to:
  /// **'Mobility Issue'**
  String get mobilityIssue;

  /// No description provided for @sleepDisorder.
  ///
  /// In en, this message translates to:
  /// **'Sleep Disorder'**
  String get sleepDisorder;

  /// No description provided for @careRefusal.
  ///
  /// In en, this message translates to:
  /// **'Care Refusal'**
  String get careRefusal;

  /// No description provided for @otherIncident.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherIncident;

  /// No description provided for @reportIncident.
  ///
  /// In en, this message translates to:
  /// **'Report an Incident'**
  String get reportIncident;

  /// No description provided for @incidentType.
  ///
  /// In en, this message translates to:
  /// **'Incident Type'**
  String get incidentType;

  /// No description provided for @selectType.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get selectType;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @mild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get mild;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @severe.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severe;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date and Time'**
  String get dateTime;

  /// No description provided for @reportIncidentBtn.
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get reportIncidentBtn;

  /// No description provided for @incidentReportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Incident reported successfully'**
  String get incidentReportedSuccess;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get fillAllFields;

  /// No description provided for @personConcerned.
  ///
  /// In en, this message translates to:
  /// **'Person Concerned'**
  String get personConcerned;

  /// No description provided for @brainHealthDashboard.
  ///
  /// In en, this message translates to:
  /// **'Brain Health'**
  String get brainHealthDashboard;

  /// No description provided for @startBrainAssessment.
  ///
  /// In en, this message translates to:
  /// **'Start Brain Assessment'**
  String get startBrainAssessment;

  /// No description provided for @assessmentDescription.
  ///
  /// In en, this message translates to:
  /// **'Take a quick assessment to evaluate your brain health'**
  String get assessmentDescription;

  /// No description provided for @beginBtn.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get beginBtn;

  /// No description provided for @todaysSummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Summary'**
  String get todaysSummary;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @cognitiveProgress.
  ///
  /// In en, this message translates to:
  /// **'Cognitive Progress'**
  String get cognitiveProgress;

  /// No description provided for @brainRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get brainRecommendations;

  /// No description provided for @doctorSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor Space'**
  String get doctorSpaceTitle;

  /// No description provided for @assistantSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant Space'**
  String get assistantSpaceTitle;

  /// No description provided for @homeNav.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNav;

  /// No description provided for @patientsNav.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsNav;

  /// No description provided for @settingsNav.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsNav;

  /// No description provided for @assistantHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant Home'**
  String get assistantHomeTitle;

  /// No description provided for @noPatientsLinked.
  ///
  /// In en, this message translates to:
  /// **'No patients linked'**
  String get noPatientsLinked;

  /// No description provided for @goToPatientsToLink.
  ///
  /// In en, this message translates to:
  /// **'Go to Patients to link a patient'**
  String get goToPatientsToLink;

  /// No description provided for @addMedicationShort.
  ///
  /// In en, this message translates to:
  /// **'Add\nMedication'**
  String get addMedicationShort;

  /// No description provided for @reportIncidentShort.
  ///
  /// In en, this message translates to:
  /// **'Report\nIncident'**
  String get reportIncidentShort;

  /// No description provided for @dailyActivitiesShort.
  ///
  /// In en, this message translates to:
  /// **'Daily\nActivities'**
  String get dailyActivitiesShort;

  /// No description provided for @recentIncidents.
  ///
  /// In en, this message translates to:
  /// **'Recent Incidents'**
  String get recentIncidents;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @todaysActivities.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activities'**
  String get todaysActivities;

  /// No description provided for @detailsArrow.
  ///
  /// In en, this message translates to:
  /// **'Details →'**
  String get detailsArrow;

  /// No description provided for @doctorHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor Home'**
  String get doctorHomeTitle;

  /// No description provided for @goToPatientsSection.
  ///
  /// In en, this message translates to:
  /// **'Go to Patients to link patients'**
  String get goToPatientsSection;

  /// No description provided for @createPrescriptionShort.
  ///
  /// In en, this message translates to:
  /// **'Create\nPrescription'**
  String get createPrescriptionShort;

  /// No description provided for @addRecommendationShort.
  ///
  /// In en, this message translates to:
  /// **'Add\nRecommendation'**
  String get addRecommendationShort;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String hoursAgo(Object hours);

  /// No description provided for @addRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Add Recommendation'**
  String get addRecommendation;

  /// No description provided for @recommendationHint.
  ///
  /// In en, this message translates to:
  /// **'Medical recommendation...'**
  String get recommendationHint;

  /// No description provided for @sendBtn.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendBtn;

  /// No description provided for @recommendationSent.
  ///
  /// In en, this message translates to:
  /// **'Recommendation sent successfully'**
  String get recommendationSent;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSettings;

  /// No description provided for @manageReminders.
  ///
  /// In en, this message translates to:
  /// **'Manage reminders'**
  String get manageReminders;

  /// No description provided for @alertHistory.
  ///
  /// In en, this message translates to:
  /// **'Alert History'**
  String get alertHistory;

  /// No description provided for @managePatients.
  ///
  /// In en, this message translates to:
  /// **'Manage Patients'**
  String get managePatients;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountSecurity;

  /// No description provided for @passwordLogin.
  ///
  /// In en, this message translates to:
  /// **'Password, login'**
  String get passwordLogin;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSection;

  /// No description provided for @faqSupport.
  ///
  /// In en, this message translates to:
  /// **'FAQ and support'**
  String get faqSupport;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// No description provided for @logoutBtn.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutBtn;

  /// No description provided for @chatbotTitle.
  ///
  /// In en, this message translates to:
  /// **'Rafiq'**
  String get chatbotTitle;

  /// No description provided for @mciRisk.
  ///
  /// In en, this message translates to:
  /// **'MCI Risk'**
  String get mciRisk;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @notificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Now you can edit your notification settings in here'**
  String get notificationSubtitle;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In here you can edit your profile settings.'**
  String get profileEditSubtitle;

  /// No description provided for @profilePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'If you forget your password relax and try to remember your password.'**
  String get profilePasswordHint;

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @monLabel.
  ///
  /// In en, this message translates to:
  /// **'MON'**
  String get monLabel;

  /// No description provided for @tueLabel.
  ///
  /// In en, this message translates to:
  /// **'TUE'**
  String get tueLabel;

  /// No description provided for @wedLabel.
  ///
  /// In en, this message translates to:
  /// **'WED'**
  String get wedLabel;

  /// No description provided for @thuLabel.
  ///
  /// In en, this message translates to:
  /// **'THU'**
  String get thuLabel;

  /// No description provided for @friLabel.
  ///
  /// In en, this message translates to:
  /// **'FRI'**
  String get friLabel;

  /// No description provided for @satLabel.
  ///
  /// In en, this message translates to:
  /// **'SAT'**
  String get satLabel;

  /// No description provided for @sunLabel.
  ///
  /// In en, this message translates to:
  /// **'SUN'**
  String get sunLabel;

  /// No description provided for @encouragementTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you know?'**
  String get encouragementTitle;

  /// No description provided for @encouragementMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! How are you?'**
  String get encouragementMessage;

  /// No description provided for @encouragementPlay.
  ///
  /// In en, this message translates to:
  /// **'Play Now'**
  String get encouragementPlay;

  /// No description provided for @encouragementChat.
  ///
  /// In en, this message translates to:
  /// **'Chat Now'**
  String get encouragementChat;

  /// No description provided for @encouragementLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get encouragementLater;

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS Emergency'**
  String get sosTitle;

  /// No description provided for @sosCalling.
  ///
  /// In en, this message translates to:
  /// **'Auto-calling emergency services in:'**
  String get sosCalling;

  /// No description provided for @sosCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get sosCancel;

  /// No description provided for @sosCallNow.
  ///
  /// In en, this message translates to:
  /// **'CALL NOW'**
  String get sosCallNow;

  /// No description provided for @scoreExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get scoreExcellent;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get needsAttention;

  /// No description provided for @autonomyScore.
  ///
  /// In en, this message translates to:
  /// **'Autonomy Score'**
  String get autonomyScore;

  /// No description provided for @noScoreCalculated.
  ///
  /// In en, this message translates to:
  /// **'No score calculated'**
  String get noScoreCalculated;

  /// No description provided for @calculateNow.
  ///
  /// In en, this message translates to:
  /// **'Calculate now'**
  String get calculateNow;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealSnack;

  /// No description provided for @yearsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} years'**
  String yearsLabel(Object count);

  /// No description provided for @secLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} sec'**
  String secLabel(Object count);

  /// No description provided for @outOf10.
  ///
  /// In en, this message translates to:
  /// **'{value}/10'**
  String outOf10(Object value);

  /// No description provided for @howIsSleep.
  ///
  /// In en, this message translates to:
  /// **'How would you rate your sleep?'**
  String get howIsSleep;

  /// No description provided for @troubleRemembering.
  ///
  /// In en, this message translates to:
  /// **'Do you have trouble remembering things?'**
  String get troubleRemembering;

  /// No description provided for @forgetDailyTasks.
  ///
  /// In en, this message translates to:
  /// **'How often do you forget daily tasks?'**
  String get forgetDailyTasks;

  /// No description provided for @reactionSeconds.
  ///
  /// In en, this message translates to:
  /// **'Approximate reaction time (seconds)'**
  String get reactionSeconds;

  /// No description provided for @highestEducation.
  ///
  /// In en, this message translates to:
  /// **'Your highest education level'**
  String get highestEducation;

  /// No description provided for @howActiveDaily.
  ///
  /// In en, this message translates to:
  /// **'How active are you daily? (0-10)'**
  String get howActiveDaily;

  /// No description provided for @questionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionLabel;

  /// No description provided for @questionFormat.
  ///
  /// In en, this message translates to:
  /// **'Question {current}/{total}'**
  String questionFormat(Object current, Object total);

  /// No description provided for @doesColorMatch.
  ///
  /// In en, this message translates to:
  /// **'Does the word match the color?'**
  String get doesColorMatch;

  /// No description provided for @wordFormat.
  ///
  /// In en, this message translates to:
  /// **'Word {current}/{total}'**
  String wordFormat(Object current, Object total);

  /// No description provided for @typeUnscrambled.
  ///
  /// In en, this message translates to:
  /// **'Type the unscrambled word'**
  String get typeUnscrambled;

  /// No description provided for @watchSequence.
  ///
  /// In en, this message translates to:
  /// **'Watch the sequence:'**
  String get watchSequence;

  /// No description provided for @yourInput.
  ///
  /// In en, this message translates to:
  /// **'Your input:'**
  String get yourInput;

  /// No description provided for @youX.
  ///
  /// In en, this message translates to:
  /// **'You (X)'**
  String get youX;

  /// No description provided for @aiO.
  ///
  /// In en, this message translates to:
  /// **'AI (O)'**
  String get aiO;

  /// No description provided for @aiWins.
  ///
  /// In en, this message translates to:
  /// **'AI Wins!'**
  String get aiWins;

  /// No description provided for @patternMemory.
  ///
  /// In en, this message translates to:
  /// **'Pattern Memory'**
  String get patternMemory;

  /// No description provided for @patternMemoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Repeat the color sequence to train memory'**
  String get patternMemoryDesc;

  /// No description provided for @roundReached.
  ///
  /// In en, this message translates to:
  /// **'Round reached: {round}'**
  String roundReached(Object round);

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best: {score}'**
  String bestScore(Object score);

  /// No description provided for @roundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String roundLabel(Object round);

  /// No description provided for @watch.
  ///
  /// In en, this message translates to:
  /// **'Watch...'**
  String get watch;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your Turn!'**
  String get yourTurn;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready'**
  String get getReady;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak:'**
  String get streak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak: {count}'**
  String bestStreak(Object count);

  /// No description provided for @correctBonus.
  ///
  /// In en, this message translates to:
  /// **'Correct! +{points}'**
  String correctBonus(Object points);

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong!'**
  String get wrong;

  /// No description provided for @tapColorMatch.
  ///
  /// In en, this message translates to:
  /// **'Tap the color that matches:\n\"{color}\"'**
  String tapColorMatch(Object color);

  /// No description provided for @lastLabel.
  ///
  /// In en, this message translates to:
  /// **'Last: {time}ms'**
  String lastLabel(Object time);

  /// No description provided for @averageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average: {time}ms'**
  String averageLabel(Object time);

  /// No description provided for @attemptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attempts: {count}'**
  String attemptsLabel(Object count);

  /// No description provided for @tooEarly.
  ///
  /// In en, this message translates to:
  /// **'Too early! Wait for green.'**
  String get tooEarly;

  /// No description provided for @mathFormat.
  ///
  /// In en, this message translates to:
  /// **'{a} {op} {b} = ?'**
  String mathFormat(Object a, Object b, Object op);

  /// No description provided for @memoryWords.
  ///
  /// In en, this message translates to:
  /// **'Memory Words'**
  String get memoryWords;

  /// No description provided for @wordsRemember.
  ///
  /// In en, this message translates to:
  /// **'Remember a list of words and identify them later'**
  String get wordsRemember;

  /// No description provided for @tapFast.
  ///
  /// In en, this message translates to:
  /// **'Tap as fast as possible when the screen changes color'**
  String get tapFast;

  /// No description provided for @solveMath.
  ///
  /// In en, this message translates to:
  /// **'Solve simple math problems quickly'**
  String get solveMath;

  /// No description provided for @findPatterns.
  ///
  /// In en, this message translates to:
  /// **'Find matching patterns and colors'**
  String get findPatterns;

  /// No description provided for @satisfactory.
  ///
  /// In en, this message translates to:
  /// **'Satisfactory'**
  String get satisfactory;

  /// No description provided for @selectObjectAndRoom.
  ///
  /// In en, this message translates to:
  /// **'Select an object and a room'**
  String get selectObjectAndRoom;

  /// No description provided for @objectKeys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get objectKeys;

  /// No description provided for @objectGlasses.
  ///
  /// In en, this message translates to:
  /// **'Glasses'**
  String get objectGlasses;

  /// No description provided for @objectPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get objectPhone;

  /// No description provided for @objectBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get objectBook;

  /// No description provided for @objectRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get objectRemote;

  /// No description provided for @objectWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get objectWatch;

  /// No description provided for @objectPen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get objectPen;

  /// No description provided for @objectWaterBottle.
  ///
  /// In en, this message translates to:
  /// **'Water Bottle'**
  String get objectWaterBottle;

  /// No description provided for @objectWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get objectWallet;

  /// No description provided for @objectTissues.
  ///
  /// In en, this message translates to:
  /// **'Tissues'**
  String get objectTissues;

  /// No description provided for @objectCap.
  ///
  /// In en, this message translates to:
  /// **'Cap'**
  String get objectCap;

  /// No description provided for @objectBag.
  ///
  /// In en, this message translates to:
  /// **'Bag'**
  String get objectBag;

  /// No description provided for @roomLiving.
  ///
  /// In en, this message translates to:
  /// **'Living Room'**
  String get roomLiving;

  /// No description provided for @roomKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get roomKitchen;

  /// No description provided for @roomBedroom.
  ///
  /// In en, this message translates to:
  /// **'Bedroom'**
  String get roomBedroom;

  /// No description provided for @roomBathroom.
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get roomBathroom;

  /// No description provided for @roomEntrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance'**
  String get roomEntrance;

  /// No description provided for @roomOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get roomOffice;

  /// No description provided for @scoreGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get scoreGood;

  /// No description provided for @scoreFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get scoreFair;

  /// No description provided for @severityMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get severityMild;

  /// No description provided for @severityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severityModerate;

  /// No description provided for @severitySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severitySevere;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCritical;

  /// No description provided for @severityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get severityUnknown;

  /// No description provided for @needsPractice.
  ///
  /// In en, this message translates to:
  /// **'Needs Practice'**
  String get needsPractice;

  /// No description provided for @unknownTest.
  ///
  /// In en, this message translates to:
  /// **'Unknown Test'**
  String get unknownTest;

  /// No description provided for @myDocuments.
  ///
  /// In en, this message translates to:
  /// **'My Documents'**
  String get myDocuments;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health & Wellness'**
  String get health;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety & Family'**
  String get safety;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @talkback.
  ///
  /// In en, this message translates to:
  /// **'Talkback'**
  String get talkback;

  /// No description provided for @talkbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Read screen content aloud'**
  String get talkbackDesc;

  /// No description provided for @talkbackEnabled.
  ///
  /// In en, this message translates to:
  /// **'Talkback enabled'**
  String get talkbackEnabled;

  /// No description provided for @talkbackDisabled.
  ///
  /// In en, this message translates to:
  /// **'Talkback disabled'**
  String get talkbackDisabled;

  /// No description provided for @talkbackAlarmBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s time to take your medication: {medName}. Please press Take, Skip, or Snooze.'**
  String talkbackAlarmBody(Object medName);

  /// No description provided for @talkbackAlarmTake.
  ///
  /// In en, this message translates to:
  /// **'Take the medication'**
  String get talkbackAlarmTake;

  /// No description provided for @talkbackAlarmSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this medication'**
  String get talkbackAlarmSkip;

  /// No description provided for @talkbackAlarmSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze for 10 minutes'**
  String get talkbackAlarmSnooze;

  /// No description provided for @myRecommendations.
  ///
  /// In en, this message translates to:
  /// **'My Recommendations'**
  String get myRecommendations;

  /// No description provided for @noRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get noRecommendations;

  /// No description provided for @medicalRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Medical Recommendations'**
  String get medicalRecommendations;

  /// No description provided for @recommendationFromDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor\'s Recommendation'**
  String get recommendationFromDoctor;

  /// No description provided for @doctorWillSendRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Your doctor will send you recommendations here.'**
  String get doctorWillSendRecommendations;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
