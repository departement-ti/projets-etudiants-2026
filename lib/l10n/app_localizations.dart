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
  /// **'Reported by'**
  String get reportedBy;

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
